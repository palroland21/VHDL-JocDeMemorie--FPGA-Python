----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/08/2025 01:23:21 PM
-- Design Name: 
-- Module Name: random_digits_gen - Behavioral
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

entity random_digits_gen is
 generic ( MAX_DIGITS: natural := 16 );
 port ( 
     clk: in std_logic;
     start: in std_logic; -- porneste generarea
     num_digits : in std_logic_vector(7 downto 0);
     done : out std_logic; -- semnal ca s-a terminat generarea
     digits: out std_logic_vector(MAX_DIGITS*4-1 downto 0) 
       );
end random_digits_gen;

architecture Behavioral of random_digits_gen is

 signal lfsr : unsigned(15 downto 0) := x"ACE1"; -- Linear-Feedback shift register (ACE1 combinatie "perfecta" intre 1 si 0
 signal count : integer range 0 to MAX_DIGITS := 0;
 signal digits_reg : std_logic_vector(MAX_DIGITS*4-1 downto 0) := (others => '0');
 signal done_temp: std_logic := '0';
 
 function lfsr_next(s : unsigned(15 downto 0)) return unsigned is 
  variable temp: unsigned(15 downto 0);
 begin
  -- x^16 + x^14 + x^13 + x^11 + 1
  temp := s(14 downto 0) & (s(15) xor s(13) xor s(12) xor s(10));
  return temp;
 end function;
 
begin

 process(clk)
  variable num: integer;
 begin
  if rising_edge(clk) then
     -- ruleaza incontinuu chiar daca count > num_digits
     -- ca sa nu avem mereu aceleasi secvente la start
     lfsr <= lfsr_next(lfsr);
     
     done_temp <= '0';
     num := to_integer(unsigned(num_digits));
     if num < 0 then num := 0; end if;
     if num > MAX_DIGITS then num := MAX_DIGITS; end if;
     
     if start = '1' then
       if count < num then    
          -- luam ultimele 4 biti pt a extrage doar o cifra
          digits_reg(count*4 + 3 downto count*4) <= std_logic_vector(lfsr(3 downto 0));
          count <= count + 1;
          
          if count + 1 = num then
            done_temp <= '1';
            count <= 0;
          end if;
        end if;  
     else
       count <= 0;
     end if;
  end if;
 end process;

 digits <= digits_reg;
 done <= done_temp;

end Behavioral;
