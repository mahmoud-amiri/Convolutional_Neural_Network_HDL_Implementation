library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AdderTree is
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
end AdderTree;

architecture Behavioral of AdderTree is
    constant MAX_STAGES : integer := integer(ceil(log2(real(KERNEL_HEIGHT*KERNEL_WIDTH))));
    signal sum_stages : sum_vector(0 to MAX_STAGES)(0 to KERNEL_HEIGHT*KERNEL_WIDTH-1);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                sum_stages <= (others => (others => (others => '0')));
            else
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

            end if;
        end if;
    end process;

    sum_out <= sum_stages(MAX_STAGES)(0);

end Behavioral;
