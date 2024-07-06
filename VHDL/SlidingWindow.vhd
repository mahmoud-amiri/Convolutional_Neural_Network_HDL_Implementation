library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SlidingWindow is
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
end SlidingWindow;

architecture Behavioral of SlidingWindow is
    signal window : kernel_array_2d(0 to KERNEL_HEIGHT-1, 0 to KERNEL_WIDTH-1);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                window <= (others => (others => (others => '0')));
            else
                for i in 0 to KERNEL_HEIGHT-1 loop
                    for j in 0 to KERNEL_WIDTH-2 loop
                        window(i)(j) <= window(i)(j+1);
                    end loop;
                    window(i)(KERNEL_WIDTH-1) <= data_in(DATA_WIDTH*(i+1)-1 downto DATA_WIDTH*i);
                end loop;
            end if;
        end if;
    end process;

    window_out <= window;

end Behavioral;
