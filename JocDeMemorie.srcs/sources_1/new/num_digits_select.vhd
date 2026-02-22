----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/12/2025 02:42:35 PM
-- Design Name: 
-- Module Name: num_digits_select - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity num_digits_select is
  Port ( nivel: in std_logic_vector(3 downto 0);
         num_digits: out std_logic_vector(7 downto 0)
      );
end num_digits_select;

architecture Behavioral of num_digits_select is

begin

 process(nivel)
 begin
    case nivel is
      when "0000" => num_digits <= std_logic_vector(to_unsigned(4, num_digits'length));
      when "0001" => num_digits <= std_logic_vector(to_unsigned(4, num_digits'length)); 
      when "0010" => num_digits <= std_logic_vector(to_unsigned(4, num_digits'length)); 
      when "0011" => num_digits <= std_logic_vector(to_unsigned(5, num_digits'length)); 
      when "0100" => num_digits <= std_logic_vector(to_unsigned(6, num_digits'length)); 
      when "0101" => num_digits <= std_logic_vector(to_unsigned(7, num_digits'length)); 
      when "0110" => num_digits <= std_logic_vector(to_unsigned(7, num_digits'length)); 
      when "0111" => num_digits <= std_logic_vector(to_unsigned(8, num_digits'length)); 
      when "1000" => num_digits <= std_logic_vector(to_unsigned(9, num_digits'length)); 
      when "1001" => num_digits <= std_logic_vector(to_unsigned(10, num_digits'length)); 
      when "1010" => num_digits <= std_logic_vector(to_unsigned(8, num_digits'length)); 
      when "1011" => num_digits <= std_logic_vector(to_unsigned(8, num_digits'length)); 
      when "1100" => num_digits <= std_logic_vector(to_unsigned(9, num_digits'length)); 
      when "1101" => num_digits <= std_logic_vector(to_unsigned(10, num_digits'length)); 
      when "1110" => num_digits <= std_logic_vector(to_unsigned(12, num_digits'length)); 
      when others => num_digits <= std_logic_vector(to_unsigned(13, num_digits'length));
    end case;
 end process;

end Behavioral;
