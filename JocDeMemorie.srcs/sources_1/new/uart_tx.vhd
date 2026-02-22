library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
  generic (
        CLK_FREQ: integer := 100_000_000; -- Frecventa ceasului (100 MHz)
        BAUD_RATE: integer := 9600        -- Viteza dorita
          );
  Port ( 
        clk: in STD_LOGIC;
        rst: in STD_LOGIC;
        tx_start: in STD_LOGIC; 
        tx_data: in STD_LOGIC_VECTOR (7 downto 0);
        tx_busy: out STD_LOGIC; 
        tx : out STD_LOGIC -- trimit unu cate unu datele sau bitul de START/STOP
          );
end uart_tx;

architecture Behavioral of uart_tx is

 constant BIT_PERIOD: integer := CLK_FREQ / BAUD_RATE;
 signal clk_cnt: integer range 0 to BIT_PERIOD := 0;
 signal bit_index: integer range 0 to 9 := 0; -- 1 start + 8 data + 1 stop
 signal tx_reg: std_logic_vector(8 downto 0) := (others => '1');
 signal state: std_logic := '0'; -- 0 IDLE, 1 TRANSMITTING

begin

 process(clk)
 begin
   if rising_edge(clk) then
     if rst = '1' then
       state <= '0';
       tx <= '1';
       tx_busy <= '0';
       clk_cnt <= 0;
       bit_index <= 0;
     else
       case state is
           when '0' => -- IDLE
             tx <= '1'; -- nu transmit
             clk_cnt <= 0;
             bit_index <= 0; -- contor care parcurge cadrul UART 
             
             if tx_start = '1' then
                 -- Incarcam datele: Stop bit (1) & Data & Start bit
                 tx_reg <= '1' & tx_data; -- Bit 8 e Stop, 7..0 sunt datele
                 state <= '1';
                 tx_busy <= '1'; -- Semnalam ca suntem ocupati
             else
                 tx_busy <= '0';
             end if;

           when '1' => -- IN TRANSMITERE
             -- Trebuie sa numaram pana la BIT_PERIOD inainte sa schimbam bitul
             if clk_cnt < BIT_PERIOD - 1 then
                 clk_cnt <= clk_cnt + 1;
             else
                 clk_cnt <= 0; -- Resetam contorul si trecem la urmatorul bit
                 
                 if bit_index = 0 then   -- trimit START (0)
                    tx <= '0'; -- START BIT
                    bit_index <= bit_index + 1;
                    
                 elsif bit_index <= 8 then    -- trimit data bit 0, 1, 2, 3...7
                    tx <= tx_reg(bit_index - 1); -- Trimitem bitii de date (LSB first - Least Significant Bit (bitul 0))
                    bit_index <= bit_index + 1;
                    
                 elsif bit_index = 9 then    -- trimit STOP (1)
                    tx <= '1'; -- STOP BIT
                    state <= '0'; -- Gata, revenim in IDLE
                    tx_busy <= '0';
                 end if;
             end if;
      end case;
     end if;            
   end if;
 end process;

end Behavioral;