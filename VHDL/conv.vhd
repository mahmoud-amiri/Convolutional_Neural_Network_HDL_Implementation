library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity conv is
    generic (
        KERNEL_SIZE : integer := 3;  -- Size of the convolution kernel
        DATA_WIDTH : integer := 16   -- Data width (8 to 32 bits)
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        eol         : in  std_logic;
        ready       : in  std_logic;
        data_out_buffer1 : in std_logic_vector(KERNEL_SIZE*DATA_WIDTH-1 downto 0);
        kernel      : in  array (0 to KERNEL_SIZE-1, 0 to KERNEL_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out    : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end conv;

architecture Behavioral of conv is

    signal window : array (0 to KERNEL_SIZE-1, 0 to KERNEL_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type product_array is array (0 to KERNEL_SIZE*KERNEL_SIZE-1) of unsigned(DATA_WIDTH*2-1 downto 0);
    signal products : product_array;

    -- Maximum number of stages needed for the adder tree
    constant MAX_STAGES : integer := integer(ceil(log2(real(KERNEL_SIZE*KERNEL_SIZE))));
    -- Signals for the adder tree, using a 2D array
    type sum_vector is array (natural range <>) of product_array(0 to KERNEL_SIZE*KERNEL_SIZE-1);
    signal sum_stages : sum_vector(0 to MAX_STAGES);

    signal result : unsigned(DATA_WIDTH*2-1 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                window <= (others => (others => '0'));
                result <= (others => '0');
                data_out <= (others => '0');
            else
                if ready = '1' then
                    -- Pipeline Stage 1: Update window and calculate products
                    window(0)(0) <= window(0)(1);
                    window(0)(1) <= window(0)(2);
                    window(0)(2) <= data_out_buffer1(DATA_WIDTH*1-1 downto DATA_WIDTH*0);

                    window(1)(0) <= window(1)(1);
                    window(1)(1) <= window(1)(2);
                    window(1)(2) <= data_out_buffer1(DATA_WIDTH*2-1 downto DATA_WIDTH*1);

                    window(2)(0) <= window(2)(1);
                    window(2)(1) <= window(2)(2);
                    window(2)(2) <= data_out_buffer1(DATA_WIDTH*3-1 downto DATA_WIDTH*2);

                    -- Compute the partial products in parallel
                    for i in 0 to KERNEL_SIZE-1 loop
                        for j in 0 to KERNEL_SIZE-1 loop
                            products(i*KERNEL_SIZE+j) <= unsigned(window(i, j)) * unsigned(kernel(i, j));
                        end loop;
                    end loop;

                    -- Initialize the adder tree with the products
                    sum_stages(0) <= products;

                    -- Generate the adder tree
                    for stage in 1 to MAX_STAGES loop
                        for i in 0 to ((KERNEL_SIZE*KERNEL_SIZE-1)/(2**stage)) loop
                            if (2*i+1) < KERNEL_SIZE*KERNEL_SIZE then
                                sum_stages(stage)(i) <= sum_stages(stage-1)(2*i) + sum_stages(stage-1)(2*i+1);
                            else
                                sum_stages(stage)(i) <= sum_stages(stage-1)(2*i);
                            end if;
                        end loop;
                    end loop;

                    -- Assign the output
                    result <= sum_stages(MAX_STAGES)(0);
                    data_out <= std_logic_vector(result(DATA_WIDTH+13 downto 14)); -- Adjust for fractional part

                end if;
            end if;
        end if;
    end process;

end Behavioral;
