----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/11/2025 06:28:58 PM
-- Design Name: 
-- Module Name: kypd_controlller - Behavioral
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

entity kypd_controller is
  generic(
    CLK_FREQ: integer := 100_000_000; -- pe placa 100_000_000
    DEBOUNCE_MS: integer := 20
  );
  port (
    clk: in std_logic;
    rst: in std_logic;
    rows: in std_logic_vector(3 downto 0); -- liniile de pe kypd 
    cols: out std_logic_vector(3 downto 0); -- coloanela unde a fost activata btn
    key_valid: out std_logic;                -- cand a fost detectate o tasta
    key_code: out std_logic_vector(3 downto 0) -- cod 0-15 (col*4 + row)
  );
end kypd_controller;

architecture Behavioral of kypd_controller is

 signal col_selectata: integer range 0 to 3 := 0;
 signal cols_intern: std_logic_vector(3 downto 0) := (others => '1');
 signal rows_intern: std_logic_vector(3 downto 0) := (others => '1');
 
 signal scan_tick_cnt: integer := 0;   -- contor pt generarea unui tac de scanare
 signal scan_tick: std_logic := '0';   -- impuls ce zice sa mergem la coloana urmatoare
 constant SCAN_PERIOD: integer := CLK_FREQ / 1000;  -- perioada 1 ms intre schimbarile coloanei
 
 -- debounce
 constant DEBOUNCE_TICKS: integer := integer((CLK_FREQ / 1000) * DEBOUNCE_MS); -- nr de cicluri necesare pt debounce 
 signal db_cnt: integer := 0;                   -- contor intern pt masurarea timpului 
 signal stable_key_pressed: std_logic := '0';   -- indica daca o tasta e mentinuta stabil
 signal stable_code: std_logic_vector(3 downto 0) := (others => '0');  -- codul de tasta apasat
 
 
 signal detected_row: integer range 0 to 3 := 0;
 signal detected_col: integer range 0 to 3 := 0;
 signal row_pressed: std_logic := '0';

begin
 -- LOGICA TOTALA: Coloanele se plimba automat pana cand se activeaza vreo linie pe coloana!
 
 
 -- La orice schimbare de col_selectata pune toate coloanele pe '1' si coloana selectata pe '0' (o activeaza)
 process(col_selectata)  
 begin
  cols_intern <= (others => '1');
  cols_intern(col_selectata) <= '0';   -- activare
 end process;
 cols <= cols_intern;
 
 
 -- Creare o scanare de 1 ms pe clock
 process(clk, rst)
 begin
  if rst = '1' then
    scan_tick_cnt <= 0;
    scan_tick <= '0';
  elsif rising_edge(clk) then
    if scan_tick_cnt >= SCAN_PERIOD then
       scan_tick_cnt <= 0;
       scan_tick <= '1';       -- emite impuls de tic de 1ms
    else
       scan_tick_cnt <= scan_tick_cnt + 1;
       scan_tick <= '0';
    end if;
  end if;
 end process;
 
 
 
 -- Selectam urmatoarea coloana la fiecare tic
 -- Nu schimbam coloana daca avem o tasta apasata pe coloana curenta
 process(clk)
 begin
  if rst = '1' then
    col_selectata <= 0;
  elsif rising_edge(clk) then
    if scan_tick = '1' then
      -- Verificam daca pe liniile curente e ceva apasat (0 activ)
      -- Daca rows_intern e "1111", inseamna ca nu e nimic apasat, deci putem muta coloana
      if rows_intern = "1111" then 
          if col_selectata = 3 then
             col_selectata <= 0;
          else
             col_selectata <= col_selectata + 1;
          end if;
      end if;
      -- Daca rows_intern NU e "1111" => e o linie activa pe aceasta coloana,
      -- deci ramanem pe coloana asta ca sa facem debounce
    end if;
  end if;    
 end process;
 
 
 -- Intrarile rows, dau la rows_intern
 process(clk)
 begin
  if rising_edge(clk) then
    rows_intern <= rows;
  end if;
 end process;
 
 
 -- Determina daca este vreo tasta apasata
 process(clk, rst)
 begin
  if rst = '1' then
   row_pressed <= '0';
   detected_row <= 0;
   detected_col <= 0;
  elsif rising_edge(clk) then
    if scan_tick = '1' then
      row_pressed <= '0'; -- pornesc mereu cu presupunerea ca NU este niciun row_pressed
      for i in 0 to 3 loop
        if rows_intern(i) = '0' then -- => ca tasta de pe randul i, coloana curenta e apasata
           row_pressed <= '1';
           detected_row <= i;
           detected_col <= col_selectata;
        end if;
      end loop;
    end if;
  end if;  
 end process;
 
 
 -- Dobounce logic
 process(clk, rst)
 begin
  if rst = '1' then
    db_cnt <= 0;
    stable_key_pressed <= '0';
    stable_code <= (others => '0');
    key_valid <= '0';
  elsif rising_edge(clk) then
    if row_pressed = '1' then
        stable_code <= std_logic_vector(to_unsigned(detected_col*4 + detected_row, 4));
        if db_cnt < DEBOUNCE_TICKS then    
          db_cnt <= db_cnt + 1;
          key_valid <= '0';
        else
          stable_key_pressed <= '1'; 
          key_valid <= '1';
        end if;
    else   
       db_cnt <= 0;
       stable_key_pressed <= '0';
       key_valid <= '0';
   end if;       
  end if;
 end process;
 
 key_code <= stable_code;
 
end Behavioral;
