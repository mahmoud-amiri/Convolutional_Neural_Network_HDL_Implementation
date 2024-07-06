library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ProductCalculation is
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
end ProductCalculation;

architecture Behavioral of ProductCalculation is
    signal products : product_array(0 to KERNEL_HEIGHT*KERNEL_WIDTH-1);
begin
    process(kernel, window)
    begin
        for i in 0 to KERNEL_HEIGHT-1 loop
            for j in 0 to KERNEL_WIDTH-1 loop
                products(i*KERNEL_WIDTH+j) <= unsigned(window(i, j)) * unsigned(kernel(i, j));
            end loop;
        end loop;
    end process;

    products_out <= products;

end Behavioral;
