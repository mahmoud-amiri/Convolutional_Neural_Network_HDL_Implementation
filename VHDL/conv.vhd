library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.ConvolutionPackage.ALL;

entity Conv is
    generic (
        KERNEL_WIDTH : integer := 3;  -- Width of the convolution kernel
        KERNEL_HEIGHT : integer := 3;  -- Height of the convolution kernel
        DATA_WIDTH : integer := 16;   -- Data width (8 to 32 bits)
        STRIDE : integer := 1         -- Stride for the convolution
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        ready       : in  std_logic;
        data_out_buffer : in std_logic_vector(KERNEL_WIDTH*DATA_WIDTH-1 downto 0);
        kernel      : in  kernel_array_2d(0 to KERNEL_HEIGHT-1, 0 to KERNEL_WIDTH-1);
        data_out    : out std_logic_vector(DATA_WIDTH*2-1 downto 0)  -- Wider output to handle intermediate sum
    );
end Conv;

architecture Behavioral of Conv is

    signal window : kernel_array_2d(0 to KERNEL_HEIGHT-1, 0 to KERNEL_WIDTH-1);
    signal products : product_array(0 to KERNEL_HEIGHT*KERNEL_WIDTH-1) := (others => (others => '0'));
    signal result : unsigned(DATA_WIDTH*2-1 downto 0);
    signal ready_strided : std_logic := '0';
    signal ready_counter : integer := 0;

    component SlidingWindow is
        generic (
            KERNEL_WIDTH : integer := 3;
            KERNEL_HEIGHT : integer := 3;
            DATA_WIDTH : integer := 16
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            data_in : in std_logic_vector(KERNEL_WIDTH*DATA_WIDTH-1 downto 0);
            window_out : out kernel_array_2d(0 to KERNEL_HEIGHT-1, 0 to KERNEL_WIDTH-1)
        );
    end component;

    component ProductCalculation is
        generic (
            KERNEL_WIDTH : integer := 3;
            KERNEL_HEIGHT : integer := 3;
            DATA_WIDTH : integer := 16
        );
        port (
            kernel : in kernel_array_2d(0 to KERNEL_HEIGHT-1, 0 to KERNEL_WIDTH-1);
            window : in kernel_array_2d(0 to KERNEL_HEIGHT-1, 0 to KERNEL_WIDTH-1);
            products_out : out product_array(0 to KERNEL_HEIGHT*KERNEL_WIDTH-1)
        );
    end component;

    component AdderTree is
        generic (
            KERNEL_WIDTH : integer := 3;
            KERNEL_HEIGHT : integer := 3;
            DATA_WIDTH : integer := 16
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            products : in product_array(0 to KERNEL_HEIGHT*KERNEL_WIDTH-1);
            sum_out : out unsigned(DATA_WIDTH*2-1 downto 0)
        );
    end component;

begin

    sliding_window_inst : SlidingWindow
        generic map (
            KERNEL_WIDTH => KERNEL_WIDTH,
            KERNEL_HEIGHT => KERNEL_HEIGHT,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk => clk,
            reset => reset,
            data_in => data_out_buffer,
            window_out => window
        );

    product_calc_inst : ProductCalculation
        generic map (
            KERNEL_WIDTH => KERNEL_WIDTH,
            KERNEL_HEIGHT => KERNEL_HEIGHT,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            kernel => kernel,
            window => window,
            products_out => products
        );

    adder_tree_inst : AdderTree
        generic map (
            KERNEL_WIDTH => KERNEL_WIDTH,
            KERNEL_HEIGHT => KERNEL_HEIGHT,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk => clk,
            reset => reset,
            products => products,
            sum_out => result
        );

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                result <= (others => '0');
                data_out <= (others => '0');
                ready_counter <= 0;
                ready_strided <= '0';
            else
                if ready = '1' then
                    -- Implementing the stride
                    ready_counter <= ready_counter + 1;
                    if ready_counter = STRIDE then
                        ready_counter <= 0;
                        ready_strided <= '1';
                    else
                        ready_strided <= '0';
                    end if;

                    if ready_strided = '1' then
                        data_out <= std_logic_vector(result);
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
