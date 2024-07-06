library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.ConvolutionPackage.ALL;

entity Conv is
    generic (
        KERNEL_WIDTH : integer := 3;  -- Width of the convolution kernel
        KERNEL_HEIGHT : integer := 3;  -- Height of the convolution kernel
        DATA_WIDTH : integer := 16   -- Data width (8 to 32 bits)
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        ready       : in  std_logic;
        data_out_buffer : in std_logic_vector(KERNEL_WIDTH*DATA_WIDTH-1 downto 0);
        kernel      : in  kernel_array_2d(0 to KERNEL_HEIGHT-1, 0 to KERNEL_WIDTH-1);
        stride      : in  integer;
        data_out    : out std_logic_vector(DATA_WIDTH*2-1 downto 0)  -- Wider output to handle intermediate sum
    );
end Conv;

architecture Behavioral of Conv is

    signal window : kernel_array_2d(0 to KERNEL_HEIGHT-1, 0 to KERNEL_WIDTH-1);
    signal products : product_array(0 to KERNEL_HEIGHT*KERNEL_WIDTH-1) := (others => (others => '0'));

    -- Signals for the adder tree, using a 2D array
    signal sum_stages : sum_vector(0 to MAX_STAGES)(0 to KERNEL_HEIGHT*KERNEL_WIDTH-1);

    signal result : unsigned(DATA_WIDTH*2-1 downto 0);
    signal ready_strided : std_logic := '0';
    signal ready_counter : integer := 0;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                window <= (others => (others => (others => '0')));
                result <= (others => '0');
                data_out <= (others => '0');
                ready_counter <= 0;
                ready_strided <= '0';
            else
                if ready = '1' then
                    -- Implementing the stride
                    ready_counter <= ready_counter + 1;
                    if ready_counter = stride then
                        ready_counter <= 0;
                        ready_strided <= '1';
                    else
                        ready_strided <= '0';
                    end if;

                    if ready_strided = '1' then
                        -- Pipeline Stage 1: Update window and calculate products
                        for i in 0 to KERNEL_HEIGHT-1 loop
                            for j in 0 to KERNEL_WIDTH-2 loop
                                window(i)(j) <= window(i)(j+1);
                            end loop;
                            window(i)(KERNEL_WIDTH-1) <= data_out_buffer(DATA_WIDTH*(i+1)-1 downto DATA_WIDTH*i);
                        end loop;

                        -- Compute the partial products in parallel
                        for i in 0 to KERNEL_HEIGHT-1 loop
                            for j in 0 to KERNEL_WIDTH-1 loop
                                products(i*KERNEL_WIDTH+j) <= unsigned(window(i, j)) * unsigned(kernel(i, j));
                            end loop;
                        end loop;

                        -- Initialize the adder tree with the products
                        sum_stages(0) <= products;

                        -- Generate the adder tree
                        for stage in 1 to MAX_STAGES loop
                            for i in 0 to ((KERNEL_HEIGHT*KERNEL_WIDTH-1)/(2**stage)) loop
                                if (2*i+1) < KERNEL_HEIGHT*KERNEL_WIDTH then
                                    sum_stages(stage)(i) <= sum_stages(stage-1)(2*i) + sum_stages(stage-1)(2*i+1);
                                else
                                    sum_stages(stage)(i) <= sum_stages(stage-1)(2*i);
                                end if;
                            end loop;
                        end loop;

                        -- Assign the output
                        result <= sum_stages(MAX_STAGES)(0);
                        data_out <= std_logic_vector(result);

                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
