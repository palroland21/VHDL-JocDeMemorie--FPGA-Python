----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/11/2025 08:53:09 PM
-- Design Name: 
-- Module Name: kypd_ssd - Behavioral
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

entity kypd_ssd is
 Port ( input: in std_logic_vector(3 downto 0);
        output: out std_logic_vector(6 downto 0) 
       );
end kypd_ssd;

architecture Behavioral of kypd_ssd is

begin


--  cod  tasta
-- 0000 (0)  - 1
-- 0001 (1)  - 4
-- 0010 (2)  - 7
-- 0011 (3)  - 0
-- 0100 (4)  - 2
-- 0101 (5)  - 5
-- 0110 (6)  - 8
-- 0111 (7)  - F
-- 1000 (8)  - 3
-- 1001 (9)  - 6
-- 1010 (10) - 9
-- 1011 (11) - E
-- 1100 (12) - A
-- 1101 (13) - B
-- 1110 (14) - C
-- 1111 (15) - D

 process(input)
 begin
  case input is
    when "0000" => output <= "1001111"; -- 1
    when "0100" => output <= "0010010"; -- 2
    when "1000" => output <= "0000110"; -- 3
    when "1100" => output <= "0001000"; -- A
    when "0001" => output <= "1001100"; -- 4
    when "0101" => output <= "0100100"; -- 5
    when "1001" => output <= "0100000"; -- 6
    when "1101" => output <= "1100000"; -- B
    when "0010" => output <= "0001111"; -- 7
    when "0110" => output <= "0000000"; -- 8
    when "1010" => output <= "0000100"; -- 9
    when "1110" => output <= "0110001"; -- C
    when "0011" => output <= "0000001"; -- 0
    when "0111" => output <= "0111000"; -- F
    when "1011" => output <= "0110000"; -- E
    when "1111" => output <= "1000010"; -- D
    when others => output <= "1111111"; -- blank
  end case;
 end process;

end Behavioral;
