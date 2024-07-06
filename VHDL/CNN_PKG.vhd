library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package CNN_PKG is
    type kernel_array_2d is array (natural range <>, natural range <>) of std_logic_vector;
    type kernel_array_3d is array (natural range <>, natural range <>, natural range <>) of std_logic_vector;

    type product_array is array (natural range <>) of unsigned;

    -- Maximum number of stages needed for the adder tree (this is an example for KERNEL_SIZE=3)
    constant MAX_STAGES : integer := 3; -- You can adjust this as per your requirements
    type sum_vector is array (natural range <>) of product_array;

end CNN_PKG;
