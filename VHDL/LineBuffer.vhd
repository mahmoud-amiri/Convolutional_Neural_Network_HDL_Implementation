library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity LineBuffer is
    generic (
        NUM_LINES : integer := 4;  -- Number of BRAM blocks (lines)
        DATA_WIDTH : integer := 16  -- Data width (8 to 32 bits)
    );
    port (
        clk        : in  std_logic;
        eol        : in  std_logic; 
        we         : in  std_logic;
        ready      : in  std_logic;
        wr_addr    : in  std_logic_vector(13 downto 0);  -- 14-bit address for 16K depth
        data_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- 16-bit data width
        data_out   : out std_logic_vector(NUM_LINES*DATA_WIDTH-1 downto 0)
    );
end LineBuffer;
architecture Behavioral of LineBuffer is

    component blk_mem_gen_0
        port (
            clka    : in  std_logic;
            wea     : in  std_logic_vector(0 downto 0);
            addra   : in  std_logic_vector(13 downto 0);
            dina    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            douta   : out std_logic_vector(DATA_WIDTH-1 downto 0);
            clkb    : in  std_logic;
            web     : in  std_logic_vector(0 downto 0);
            addrb   : in  std_logic_vector(13 downto 0);
            dinb    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            doutb   : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;

    signal we_int : std_logic_vector(NUM_LINES-1 downto 0);
    signal addr_split : std_logic_vector(13 downto 0);
    signal data_in_split : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal data_out_split : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal current_line : integer range 0 to NUM_LINES-1 := 0;
    signal read_addr : std_logic_vector(13 downto 0) := (others => '0');
    signal combined_data_out : std_logic_vector(NUM_LINES*DATA_WIDTH-1 downto 0);

begin

    -- Process to handle switching of current line buffer based on eol signal
    process(clk)
    begin
        if rising_edge(clk) then
            if eol = '1' then
                if current_line = NUM_LINES-1 then
                    current_line <= 0;
                else
                    current_line <= current_line + 1;
                end if;
            end if;
        end if;
    end process;

    -- Process to handle read address update based on sol and ready signals
    process(clk)
    begin
        if rising_edge(clk) then
            if eol = '1' then
                read_addr <= (others => '0');
            elsif ready = '1' then
                read_addr <= std_logic_vector(unsigned(read_addr) + 1);
            end if;
        end if;
    end process;

    -- Generate instances of blk_mem_gen_0 for each NUM_LINES
    gen_bram: for i in 0 to NUM_LINES-1 generate
    begin

        -- Write enable signals for each BRAM block
        we_int(i) <= '1' when (we = '1' and current_line = i) else '0';

        -- Slice the address and data signals
        addr_split <= wr_addr;
        data_in_split <= data_in;

        -- Instantiate the Xilinx Block Memory Generator IP
        U: blk_mem_gen_0
            port map (
                clka    => clk,
                wea     => we_int(i downto i),
                addra   => addr_split,
                dina    => data_in_split,
                douta   => open,
                clkb    => clk,
                web     => "0",
                addrb   => read_addr,
                dinb    => (others => '0'),
                doutb   => data_out_split
            );

        -- Combine the output data signals from each BRAM block
        combined_data_out(DATA_WIDTH*(i+1)-1 downto DATA_WIDTH*i) <= data_out_split;

    end generate gen_bram;

    data_out <= combined_data_out;

end Behavioral;
