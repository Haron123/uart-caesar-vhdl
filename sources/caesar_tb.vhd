----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.06.2024 13:32:41
-- Design Name: 
-- Module Name: caesar_tb - Behavioral
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

----------------------------------------------------------------------------------
-- libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.env.finish;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

----------------------------------------------------------------------------------
-- entity
entity caesar_tb is
--  Port ( );
end caesar_tb;

architecture Behavioral of caesar_tb is

----------------------------------------------------------------------------------
-- components declaration
component caesar_top
    Port (  clk          : in STD_LOGIC;
            rstn         : in STD_LOGIC;
            uart_rx      : in STD_LOGIC;
            button_dp    : in STD_LOGIC;
            button_tx    : in STD_LOGIC;

            uart_tx      : out STD_LOGIC;
            --LED : out STD_LOGIC_VECTOR (7 downto 0)
            led1         : out std_logic;
            led2         : out std_logic;
            led3         : out std_logic;
            led4         : out std_logic;
            led5         : out std_logic;
            PMOD5        : out std_logic;
            PMOD6        : out std_logic
           );
end component;

----------------------------------------------------------------------------------
-- type declaration
type UART_DATA_t is array (0 to 15) of std_logic_vector(7 downto 0); 
----------------------------------------------------------------------------------
-- signal declaration
signal clk : std_logic := '0';
signal rstn : std_logic;
signal rx, tx : std_logic;
signal button_dp, button_tx : std_logic;
--signal LED : std_logic_vector(7 downto 0);
----------------------------------------------------------------------------------
-- constant declaration
constant PERIOD : time := 10 ns;
constant OFFSET : time := 1 ns;
----------------------------------------------------------------------------------
-- UART specification
 signal UART_DATA : UART_DATA_t := (x"01", x"02", x"04", x"08", x"11", x"22", x"44", x"88", x"FF", x"00", x"00",x"00",x"00",x"00",x"00",x"00");
constant UART_BAUD : integer := 115200;
constant FREQUENCY : integer := 100_000_000;
signal UART_DELAY : time:= (FREQUENCY / UART_BAUD) * PERIOD;
signal c_data : std_logic_vector(7 downto 0);
begin

----------------------------------------------------------------------------------
-- instantiation
i_caesar : caesar_top
    Port map( clk => clk,
           rstn => rstn,
           uart_rx => rx, 
           button_dp => button_dp,
           button_tx => button_tx,

           uart_tx => tx
           --LED => LED
           );
 

----------------------------------------------------------------------------------
-- clock/reset generation
clk <= not clk after PERIOD/2;
rstn <= '0', '1' after 3*PERIOD+OFFSET;


----------------------------------------------------------------------------------
-- testbench process
process
variable rx_data_v : std_logic_vector(7 downto 0);
begin
  -- reset state
  button_dp <= '0';
  button_tx <= '0';
  rx <= '0';
  wait for 5*PERIOD;

----------------------------------------------------------------------------------
-- 1. write data to UART
  for i in 0 to 2 loop
  rx_data_v := UART_DATA(i);

   rx <= '0';
   wait for UART_DELAY;
   for j in 0 to 7 loop
    rx <= rx_data_v(j);
    wait for UART_DELAY;
   end loop;
  
   rx <= '1';
   wait for UART_DELAY;
  end loop;

----------------------------------------------------------------------------------
-- 2. Apply Caesar Coding
  button_dp <= '1';
  wait for 5*PERIOD;
  button_dp <= '0';
  wait for 1000*PERIOD;

----------------------------------------------------------------------------------
-- 3. Write back UART -> PC
  button_tx <= '1';
  wait for 5*PERIOD;
  button_tx <= '0';
  wait for 100000*PERIOD;
  finish;
  wait;
  
end process;

end Behavioral;
