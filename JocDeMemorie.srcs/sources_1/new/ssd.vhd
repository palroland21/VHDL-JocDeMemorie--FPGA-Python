----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/06/2025 04:57:37 PM
-- Design Name: 
-- Module Name: ssd - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ssd is 
 Port ( input: in std_logic_vector(3 downto 0);
        output: out std_logic_vector(6 downto 0) 
       );
end ssd;

architecture Behavioral of ssd is

begin

 process(input)
  variable v : std_logic_vector(6 downto 0);
 begin
  case input is
    when "0000" => v := "0000001"; -- 0
    when "0001" => v := "1001111"; -- 1
    when "0010" => v := "0010010"; -- 2
    when "0011" => v := "0000110"; -- 3
    when "0100" => v := "1001100"; -- 4
    when "0101" => v := "0100100"; -- 5
    when "0110" => v := "0100000"; -- 6
    when "0111" => v := "0001111"; -- 7
    when "1000" => v := "0000000"; -- 8
    when "1001" => v := "0000100"; -- 9
    when "1010" => v := "0001000"; -- A
    when "1011" => v := "1100000"; -- b
    when "1100" => v := "0110001"; -- C
    when "1101" => v := "1000010"; -- d
    when "1110" => v := "0110000"; -- E
    when others => v := "0111000"; -- F
   end case;
 output <= v;
 end process;
end Behavioral;
