library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.ConvolutionPackage.ALL;

entity ConvolutionWrapper is
    generic (
        KERNEL_WIDTH : integer := 3;  -- Width of the convolution kernel
        KERNEL_HEIGHT : integer := 3;  -- Height of the convolution kernel
        KERNEL_DEPTH : integer := 3;  -- Depth of the convolution kernel
        DATA_WIDTH : integer := 16   -- Data width (8 to 32 bits)
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        eol        : in  std_logic;
        we         : in  std_logic;
        ready      : in  std_logic;
        wr_addr    : in  std_logic_vector(13 downto 0);
        data_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        kernel     : in  kernel_array_3d(0 to KERNEL_DEPTH-1, 0 to KERNEL_HEIGHT-1, 0 to KERNEL_WIDTH-1);
        data_out   : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end ConvolutionWrapper;

architecture Behavioral of ConvolutionWrapper is

    component LineBuffer is
        generic (
            NUM_LINES : integer := 3;
            DATA_WIDTH : integer := 16
        );
        port (
            clk        : in  std_logic;
            eol        : in  std_logic;
            we         : in  std_logic;
            ready      : in  std_logic;
            wr_addr    : in  std_logic_vector(13 downto 0);
            data_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            data_out   : out std_logic_vector(NUM_LINES*DATA_WIDTH-1 downto 0)
        );
    end component;

    component conv is
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
            data_out    : out std_logic_vector(DATA_WIDTH*2-1 downto 0)  -- Wider output to handle intermediate sum
        );
    end component;

    signal buffer_select : std_logic := '0'; -- Ping-pong buffer selector
    signal data_out_buffer0, data_out_buffer1 : std_logic_vector(KERNEL_WIDTH*DATA_WIDTH-1 downto 0);
    signal line_counter : integer := 0; -- Line counter for toggling buffer_select
    signal conv_outputs : array (0 to KERNEL_DEPTH-1) of std_logic_vector(DATA_WIDTH*2-1 downto 0); -- Outputs from each conv instance
    signal result : unsigned(DATA_WIDTH*2-1 downto 0);

    signal we_buff0, we_buff1: std_logic;
begin

    -- Ping-pong buffer control
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                line_counter <= 0;
                buffer_select <= '0';
            else
                if eol = '1' then
                    line_counter <= line_counter + 1;
                    if line_counter = KERNEL_HEIGHT-1 then
                        line_counter <= 0;
                        buffer_select <= not buffer_select;
                    end if;
                end if;
            end if;
        end if;
    end process;

    we_buff0 <= we and (not buffer_select);
    we_buff1 <= we and buffer_select;

    -- Instantiating the LineBuffer components
    buffer0: LineBuffer
        generic map (
            NUM_LINES => KERNEL_HEIGHT,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk        => clk,
            eol        => eol,
            we         => we_buff0,
            ready      => ready,
            wr_addr    => wr_addr,
            data_in    => data_in,
            data_out   => data_out_buffer0
        );

    buffer1: LineBuffer
        generic map (
            NUM_LINES => KERNEL_HEIGHT,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk        => clk,
            eol        => eol,
            we         => we_buff1,
            ready      => ready,
            wr_addr    => wr_addr,
            data_in    => data_in,
            data_out   => data_out_buffer1
        );

    -- Instantiating the conv components
    gen_convs: for i in 0 to KERNEL_DEPTH-1 generate
        conv_inst: conv
            generic map (
                KERNEL_WIDTH => KERNEL_WIDTH,
                KERNEL_HEIGHT => KERNEL_HEIGHT,
                DATA_WIDTH => DATA_WIDTH
            )
            port map (
                clk             => clk,
                reset           => reset,
                ready           => ready,
                data_out_buffer => data_out_buffer1, -- Assuming data_out_buffer1 as the input buffer
                kernel          => kernel(i),
                data_out        => conv_outputs(i)
            );
    end generate;

    -- Summing the outputs of all conv instances
    process(conv_outputs)
    begin
        result <= (others => '0');
        for i in 0 to KERNEL_DEPTH-1 loop
            result <= result + unsigned(conv_outputs(i));
        end loop;
        data_out <= std_logic_vector(result(DATA_WIDTH+13 downto 14)); -- Adjust for fractional part
    end process;

end Behavioral;
