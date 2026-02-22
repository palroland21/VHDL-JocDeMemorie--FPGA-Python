----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/06/2025 08:38:55 PM
-- Design Name: 
-- Module Name: top_uart - Behavioral
-- Project Name: Memory Game
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_uart is
  port ( clk: in std_logic;
         rst: in std_logic;
         start: in std_logic;
         rows: in std_logic_vector(3 downto 0);
         cols: out std_logic_vector(3 downto 0);
         cat: out std_logic_vector(6 downto 0);  -- segment a...g
         an:  out std_logic_vector(7 downto 0);   -- selectia cifrei
         tx: out std_logic
         );
end top_uart;

architecture Behavioral of top_uart is

constant MAX_DIGITS: natural := 16; 

 -- cerere externa de start (buton)
 signal start_btn : std_logic := '0';
 signal start_btn_d : std_logic := '0';
 signal start_req : std_logic := '0';
 
 -- Semnale intermediare pt cat si an
 signal cat_s: std_logic_vector(6 downto 0);
 signal an_s: std_logic_vector(7 downto 0);
 
 -- START signals
 signal gen_start      : std_logic := '0';  -- start pt generator
 signal show_pulse     : std_logic := '0';  -- impuls start pt SSD
  
 -- nivel 
 signal nivel          : std_logic_vector(3 downto 0) := "0001";
 signal nivel_d        : std_logic_vector(3 downto 0) := "0001";
 signal nivel_changed  : std_logic := '0';
 
 signal num_digits: std_logic_vector(7 downto 0) := (others => '0');
 signal digits_arr: std_logic_vector(MAX_DIGITS*4-1 downto 0) := (others => '0');
 signal done_gen : std_logic := '0';
 
 -- Input USER
  type t_array is array (0 to MAX_DIGITS-1) of std_logic_vector(3 downto 0);
  signal seq_user: t_array;
  signal seq_gen: t_array;
  signal user_index: integer range 0 to MAX_DIGITS := 0;
  
  -- Semnale KYPD
  signal key_value: std_logic_vector(3 downto 0);
  signal key_valid: std_logic;
  signal fail_mode: std_logic := '0';
  
  signal show_done: std_logic;
  signal key_valid_d : std_logic := '0';
 
  type t_state is (IDLE, PRE_GEN, GEN, TRIGGER_SSD, SHOW, INPUT, CHECK, WIN, LOSE);
  signal st : t_state := IDLE;

  -- COMPONENTE
  component ssd_divider
    generic ( MAX_DIGITS : natural := 16 );
    port (
      clk        : in  std_logic;
      start      : in  std_logic;
      nivel      : in  std_logic_vector(3 downto 0);
      num_digits : in  std_logic_vector(7 downto 0);
      digits     : in  std_logic_vector(MAX_DIGITS*4-1 downto 0);
      cat        : out std_logic_vector(6 downto 0);  
      an         : out std_logic_vector(7 downto 0);
      finished   : out std_logic    
    );
  end component;
  
  -- Componenta simpla SSD pentru decodare in timpul input-ului
  component ssd is 
     Port ( input: in std_logic_vector(3 downto 0);
            output: out std_logic_vector(6 downto 0) 
           );
  end component;

  component random_digits_gen is
  generic ( MAX_DIGITS: natural := 16 );
  port ( 
     clk: in std_logic;
     start: in std_logic; 
     num_digits : in std_logic_vector(7 downto 0);
     done : out std_logic; 
     digits: out std_logic_vector(MAX_DIGITS*4-1 downto 0) 
   );
  end component;
  
  component kypd_ssd is
     Port ( input: in std_logic_vector(3 downto 0);
            output: out std_logic_vector(6 downto 0) 
           );
   end component;

  component num_digits_select is
  Port ( nivel: in std_logic_vector(3 downto 0);
         num_digits: out std_logic_vector(7 downto 0)
      );
  end component;
  
   component kypd_controller is
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      rows      : in  std_logic_vector(3 downto 0);
      cols      : out std_logic_vector(3 downto 0);
      key_valid : out std_logic;
      key_code  : out std_logic_vector(3 downto 0)
    );
  end component;

  -- UART Component
  component uart_tx is
   Port ( 
        clk: in STD_LOGIC;
        rst: in STD_LOGIC;
        tx_start: in STD_LOGIC; 
        tx_data: in STD_LOGIC_VECTOR (7 downto 0);
        tx_busy: out STD_LOGIC; 
        tx : out STD_LOGIC
          );
  end component;

  -- Semnale UART
  signal tx_start : std_logic := '0';
  signal tx_data  : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_busy  : std_logic;
  signal uart_tx_line : std_logic;
    
  -- Semnale de detectie fronturi pentru a declansa trimiterea
  signal done_gen_d : std_logic := '0';
  signal st_d : t_state := IDLE;
  
  -- FSM UART (Nivel, Win, Fail)
  type t_uart_state is (U_IDLE, U_SEND_L_HEADER, U_SEND_L_VAL, 
                        U_SEND_RES_W, U_SEND_RES_F);
  signal uart_state : t_uart_state := U_IDLE;
  
  -- SEMNALE NOI PENTRU MULTIPLEXARE SSD (INPUT MODE)
  signal mux_cnt : integer range 0 to 100000 := 0; -- divider
  signal active_anode : integer range 0 to 7 := 0; -- care anod e activ
  signal mux_digit_val : std_logic_vector(3 downto 0);
  signal mux_cat_out   : std_logic_vector(6 downto 0);
  signal an_u : std_logic_vector(7 downto 0); -- anozii calculati pt user input
    
begin

 start_btn <= start; 
 
 -- setez cate cifre sa genereze (dinamic, in functie de nivel)
  num_digits_select_by_level: num_digits_select port map (
   nivel => nivel, 
   num_digits => num_digits
   );
   
 -- Control pentru nivel
 process(clk)
 begin
  if rising_edge(clk) then
    if nivel /= nivel_d then
      nivel_changed <= '1';
    else
      nivel_changed <= '0';
    end if;
    nivel_d <= nivel;
  end if;
end process;
    
 -- Convertire din digits_arr
 -- bag in seq_gen(i) toate numerele de 4 biti pt ca e mai usor sa compar ulterior
 GEN_ARRAY: for i in 0 to MAX_DIGITS-1 generate
   seq_gen(i) <= digits_arr(i*4+3 downto i*4);  
 end generate;   
    
 -- Control pentru start   
process(clk)
begin
  if rising_edge(clk) then
     start_btn_d <= start_btn;
     start_req <= start_btn and not start_btn_d;
  end if;
end process;
    
 -- KYPD controller
 kypd_inst: kypd_controller
  port map(
    clk => clk,
    rst => rst,
    rows => rows,
    cols => cols,
    key_valid => key_valid,
    key_code  => key_value
  );
    
 --  MAIN FSM (Logica Jocului)
 process(clk)
   variable ok: std_logic := '1';
   variable decoded_val: std_logic_vector(3 downto 0);
 begin
    if rising_edge(clk) then
    
    if rst = '1' then
      -- RESET GLOBAL
      st <= IDLE;
      nivel <= "0001";
      user_index <= 0;
      fail_mode <= '0';
      gen_start <= '0';
      show_pulse <= '0';
    
      for i in 0 to MAX_DIGITS-1 loop
        seq_user(i) <= (others => '0');
      end loop;
      
    else
      -- LOGICA FSM
      
      show_pulse <= '0'; -- DEFAULT: 0, dar in TRIGGER_SSD il fortam la 1
      key_valid_d <= key_valid;
      
      case st is
        when IDLE =>
           gen_start <= '0';
           fail_mode <= '0';
           if start_req = '1' then
             user_index <= 0;
             st <= PRE_GEN; 
           end if;
        
        -- Asteptam 1 ciclu de ceas sa se stabilizeze semnalele (num_digits)
        when PRE_GEN =>
           gen_start <= '1';
           st <= GEN;

         when GEN =>
           -- Asteptam ca generatorul sa termine
           if done_gen = '1' then
             gen_start <= '0';
             st <= TRIGGER_SSD;
           end if;
           
         when TRIGGER_SSD =>
            show_pulse <= '1'; -- Tine START sus pana cand SSD-ul confirma
            
            -- show_done = 0 inseamna ca SSD-ul a primit comanda si a inceput sa ruleze (BUSY)
            if show_done = '0' then
                st <= SHOW;
                -- show_pulse va fi 0 automat in urmatoarea stare (datorita lui DEFAULT)
            end if;
   
         when SHOW =>
           user_index <= 0;
           -- Resetam array user
           for i in 0 to MAX_DIGITS-1 loop
              seq_user(i) <= (others => '0');
           end loop;
         
           -- asteptam sa se faca '1' din nou (semn ca a terminat secventa)
           if show_done = '1' then
             st <= INPUT;
           end if;  
         
         when INPUT =>
           if key_valid = '1' and key_valid_d = '0' then   
                -- Decodare TASTE (pt ca KYPD mi-a scros col*4 + row)
                case key_value is
                    when "0000" => decoded_val := "0001"; -- 1
                    when "0001" => decoded_val := "0100"; -- 4
                    when "0010" => decoded_val := "0111"; -- 7
                    when "0011" => decoded_val := "0000"; -- 0
                    when "0100" => decoded_val := "0010"; -- 2
                    when "0101" => decoded_val := "0101"; -- 5
                    when "0110" => decoded_val := "1000"; -- 8
                    when "0111" => decoded_val := "1111"; -- F
                    when "1000" => decoded_val := "0011"; -- 3
                    when "1001" => decoded_val := "0110"; -- 6
                    when "1010" => decoded_val := "1001"; -- 9
                    when "1011" => decoded_val := "1110"; -- E
                    when "1100" => decoded_val := "1010"; -- A
                    when "1101" => decoded_val := "1011"; -- B
                    when "1110" => decoded_val := "1100"; -- C
                    when "1111" => decoded_val := "1101"; -- D
                    when others => decoded_val := "0000";
                end case;

                -- Stocam valoarea
                if user_index < to_integer(unsigned(num_digits)) then
                    seq_user(user_index) <= decoded_val; 
                end if;
        
                -- Verificam daca am terminat inputul
                if user_index + 1 >= to_integer(unsigned(num_digits)) then
                     st <= CHECK;
                else
                     user_index <= user_index + 1;
                end if;
            end if;
            
         when CHECK => 
            fail_mode <= '0';
            ok := '1';
            
            -- Verificam secventa
            for i in 0 to MAX_DIGITS-1 loop
                if i < to_integer(unsigned(num_digits)) then
                    if seq_user(i) /= seq_gen(i) then
                       ok := '0';
                    end if;
                end if;    
            end loop;  
            
            if ok = '1' then
              st <= WIN;
            else
              st <= LOSE;
            end if;
            
         when WIN => 
          if start_req = '1' then
             nivel <= std_logic_vector(unsigned(nivel) + 1);
             user_index <= 0;
             gen_start <= '0';
           
             -- Mergem la PRE_GEN pentru a lasa timp sa se updateze nivelul
             st <= PRE_GEN;
          end if;
           
         when LOSE =>
            fail_mode <= '1';
 
            if start_req = '1' then
             user_index <= 0;
             fail_mode <= '0';
             st <= PRE_GEN;
            end if;            
         end case;
      end if;    
      end if;
 end process;
 
 generator: random_digits_gen
     port map (
          clk        => clk,
          start      => gen_start,
          num_digits => num_digits,
          done       => done_gen,
          digits     => digits_arr
     );
     
 ssd_driver_call: ssd_divider
     port map (
          clk        => clk,
          start      => show_pulse,
          nivel      => nivel,
          num_digits => num_digits,
          digits     => digits_arr,
          cat        => cat_s,
          an         => an_s,
          finished   => show_done
     );

 -- Instanta pentru decodarea cifrelor user-ului catre display
 ssd_mux_decoder: ssd
    port map (
        input => mux_digit_val,
        output => mux_cat_out
    );


 -- afisare input utilizator
 process(clk)
 begin
    if rising_edge(clk) then
        if mux_cnt = 10000 then 
            mux_cnt <= 0;
            if active_anode = 7 then
                active_anode <= 0;
            else
                active_anode <= active_anode + 1;
            end if;
        else
            mux_cnt <= mux_cnt + 1;
        end if;
    end if;
 end process;

 process(active_anode, seq_user, user_index, mux_cat_out)
 begin
    mux_digit_val <= seq_user(active_anode);
    an_u <= "11111111"; 
    
    if active_anode <= user_index then
         case active_anode is
            when 0 => an_u <= "11111110";
            when 1 => an_u <= "11111101";
            when 2 => an_u <= "11111011";
            when 3 => an_u <= "11110111";
            when 4 => an_u <= "11101110";
            when 5 => an_u <= "11011101";
            when 6 => an_u <= "10111011";
            when 7 => an_u <= "01110111";
            when others => an_u <= "11111111";
         end case;
    else
         an_u <= "11111111";
    end if;
 end process;


 -- SELECTOR FINAL PENTRU CAT SI AN
 process(st, fail_mode, cat_s, an_s, mux_cat_out, an_u)
 begin
    if fail_mode = '1' then
        cat <= "1111110"; 
        an  <= "00000000"; -- toate aprinse

    elsif st = INPUT then
        if active_anode = user_index then
            cat <= "1111110"; -- Afisam "-" (liniuta)
        else
            cat <= mux_cat_out; -- Altfel afisam cifra tastata anterior
        end if;
        
        an  <= an_u;
    elsif st = WIN then
        -- Tot negru
        -- cat <= "1111111"; 
        -- an  <= "11111111"; 
        
        -- 2 linii paralele pentru WIN
        cat <= "1001001";
        an  <= "00000000";
    elsif st = SHOW then
        cat <= cat_s;
        an  <= an_s;
    else
        cat <= "1111110";
        an  <= "11111110";
    end if;
 end process;

   -- ZONA UART
    tx <= uart_tx_line; 

    inst_uart: uart_tx 
    port map (
        clk => clk, 
        rst => rst,
        tx_start => tx_start, 
        tx_data => tx_data,
        tx_busy => tx_busy, 
        tx => uart_tx_line
    );

    -- process UART
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                uart_state <= U_IDLE;
                tx_start <= '0';
                done_gen_d <= '0';
            else
                done_gen_d <= done_gen;
                st_d <= st;
                
                case uart_state is
                    when U_IDLE =>  -- decide ce mesaj sa trimita
                        tx_start <= '0';
                        if done_gen = '1' and done_gen_d = '0' then
                            tx_data <= x"4C"; -- 'L'
                            tx_start <= '1';
                            uart_state <= U_SEND_L_HEADER; 
                        elsif st = WIN and st_d /= WIN then
                            tx_data <= x"57"; -- 'W'
                            tx_start <= '1';
                            uart_state <= U_SEND_RES_W;
                        elsif st = LOSE and st_d /= LOSE then
                            tx_data <= x"46"; -- 'F'
                            tx_start <= '1';
                            uart_state <= U_SEND_RES_F;
                        end if;

                    when U_SEND_L_HEADER =>
                        tx_start <= '0'; -- dezactivez pt ca vreau sa fie 1 doar cand incep trasmiterea unui caracter
                        if tx_busy = '1' then -- daca inca e in transmitere, nu fac nimic
                           null;
                        elsif tx_busy = '0' and tx_start = '0' then -- UART e liber si nu am start activ
                             if unsigned(nivel) < 10 then
                                tx_data <= std_logic_vector(unsigned(nivel) + x"30"); -- transform nivelul in caractere ASCII (0,1,..9)
                             else
                                tx_data <= std_logic_vector(unsigned(nivel) + x"37"); -- A,B,C,D,E,F
                             end if;
                             tx_start <= '1';
                             uart_state <= U_SEND_L_VAL;
                        end if;

                    when U_SEND_L_VAL =>
                        tx_start <= '0';
                        if tx_busy = '1' then -- a inceput transmisia
                           uart_state <= U_IDLE; 
                        end if;

                    when U_SEND_RES_W =>
                        tx_start <= '0';
                        if tx_busy = '1' then
                            uart_state <= U_IDLE;
                        end if;

                    when U_SEND_RES_F =>
                         tx_start <= '0';
                         if tx_busy = '1' then
                            uart_state <= U_IDLE;
                        end if;
                        
                    when others =>
                        uart_state <= U_IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;