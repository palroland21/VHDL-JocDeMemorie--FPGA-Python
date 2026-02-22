----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/06/2025 05:03:36 PM
-- Design Name: 
-- Module Name: ssd_divider - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ssd_divider is
  generic(MAX_DIGITS : natural := 16);
  Port (
    clk: in std_logic;
    start: in  std_logic;
    nivel: in std_logic_vector(3 downto 0);
    num_digits: in std_logic_vector(7 downto 0);     -- cate cifre sunt active din vector [1..MAX_DIGITS]
    digits: in std_logic_vector(MAX_DIGITS*4-1 downto 0); -- 4biti/cifra
    cat: out std_logic_vector(6 downto 0);   
    an: out std_logic_vector(7 downto 0);
    finished: out std_logic
  );
end ssd_divider;

architecture Behavioral of ssd_divider is

-- constante pentru frecventa de aparitie a numerelor din array

 constant CLK_FREQ_HZ: integer := 100_000_000; -- 100MHZ pe placa -> 100_000_000
                                             --  1MHZ in simulare -> 1_000_000
 constant BASE_PERIOD : integer := CLK_FREQ_HZ; -- 1 sec 
 constant STEP_PERIOD: integer := CLK_FREQ_HZ / 20; -- 0.05 sec
 
 signal cnt_freq: unsigned(31 downto 0) := (others => '0');
 signal an_temp: std_logic_vector(7 downto 0) := (others => '1');
 
 -- instante pentru a identifica cate tura a trecut
 type state_t is (SHOW_SEQ, HOLD);
 signal st : state_t := SHOW_SEQ;
 constant BLANK_SEQ : std_logic_vector(6 downto 0) := "1111111";
 
 
 -- semnale pentru a itera prin array-ul primit
 signal counter : unsigned(31 downto 0) := (others => '0');
 signal digit_value: std_logic_vector(3 downto 0) := (others => '0');
 signal seg_temp : std_logic_vector(6 downto 0) := (others => '1');

 signal n_curent : integer range 1 to MAX_DIGITS := 1;
 signal index : integer range 0 to MAX_DIGITS-1 := 0;

 -- pentru detectie de start, adica o noua secventa
 signal start_d : std_logic := '0';
 signal start_re : std_logic := '0';

 
 component ssd 
  Port ( input: in std_logic_vector(3 downto 0);
        output: out std_logic_vector(6 downto 0) 
       );
 end component;


begin
 
 
 -- n_temp <= num_digits 
 process(num_digits)
  variable n_temp: integer;
 begin

  n_temp := to_integer(unsigned(num_digits));
  if n_temp < 1 then
    n_curent <= 1;
  elsif n_temp > MAX_DIGITS then
    n_curent <= MAX_DIGITS;
  else
   n_curent <= n_temp;
  end if;
 end process;
  

     
 process(nivel)
    variable lvl    : integer;
    variable period : integer;
  begin
    lvl := to_integer(unsigned(nivel));
    if lvl < 1 then
      lvl := 1;
    end if;

    period := BASE_PERIOD - STEP_PERIOD * lvl;     -- 1.0s - 0.05*lvl (0.05 secunde)

    if period < (BASE_PERIOD / 2) then             -- MINIM 0.5s
      period := BASE_PERIOD / 2;
    end if;

    cnt_freq <= to_unsigned(period, cnt_freq'length); -- converteste INTEGER in UNSIGNED 
 end process;
  
  
  
  -- pt detectie de restart
  process(clk)
  begin
   if rising_edge(clk) then
     start_d <= start;
     start_re <= start and not start_d;  -- 1 tact doar pe front crescator a lui start
   end if;
  end process;
  
  
  -- rulaj o singura data a secventei primite
 process(clk)
 begin
  if rising_edge(clk) then
    if start_re = '1' then
       st <= SHOW_SEQ;
       index <= 0;
       counter <= (others => '0');
    else 
      case st is 
        when SHOW_SEQ =>
            if counter >= cnt_freq then 
                  counter <= (others => '0');
                  if index >= n_curent-1 then  -- n_current <= num_digits
                     st <= HOLD;
                  else
                     index <= index + 1;
                  end if;
            else
              counter <= counter + 1;
            end if;
              
        when HOLD =>
             counter <= counter;
             index <= index;
       end case;
    end if;
  end if;
 end process;
 
 
 digit_value <= digits(index*4 + 3 downto index*4);  -- extrag cifra curenta din vector
 
 ssd_pm: ssd port map(input => std_logic_vector(digit_value),
                      output => seg_temp
                     );
         
 with st select          
  cat <= seg_temp when SHOW_SEQ,
         seg_temp when others; -- HOLD (pastrez ultima cifra)
         
  an <= "11111110"; -- activez doar cifra 0 (cel din dreapta)
  
finished <= '1' when st = HOLD else '0';

end Behavioral;
