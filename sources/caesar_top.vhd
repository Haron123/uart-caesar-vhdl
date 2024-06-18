----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.05.2024 13:24:20
-- Design Name: 
-- Module Name: caesar_top - Behavioral
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
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

----------------------------------------------------------------------------------
-- toplevel entity
entity caesar_top is
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
end caesar_top;

architecture rtl of caesar_top is

----------------------------------------------------------------------------------
-- components declaration

-- datapath
component datapath
    generic
    (
        offset : positive := 3
    );
    port
    (
        din_uart    : in std_logic_vector(7 downto 0);
        din_BRAM    : in std_logic_vector(7 downto 0);
        sel         : in std_logic;
        dout        : out std_logic_vector(7 downto 0)
    );
end component;

-- uart
component uart
    generic (
        baud                : positive;
        clock_frequency     : positive
    );
    port (  
        clock               :   in  std_logic;
        reset               :   in  std_logic;    
        data_stream_in      :   in  std_logic_vector(7 downto 0);
        data_stream_in_stb  :   in  std_logic;
        data_stream_in_ack  :   out std_logic;
        data_stream_out     :   out std_logic_vector(7 downto 0);
        data_stream_out_stb :   out std_logic;
        tx                  :   out std_logic;
        rx                  :   in  std_logic
    );
end component;

-- fsm
component fsm
    port(
        -- global input ports
        clk        : in std_logic;
        rstn       : in std_logic;
        button_dp  : in std_logic;
        button_tx  : in std_logic;
        
        -- data processing enable port
        dp_en : out std_logic;

        -- bram ports
        bram_wra   : out std_logic;
        bram_rdb   : out std_logic;
        bram_addra : out std_logic_vector(8 downto 0);
        bram_addrb : out std_logic_vector(8 downto 0);    

        -- uart ports
        uart_data_stream_in_stb   : out std_logic;
        uart_data_stream_in_ack   : in std_logic;
        uart_data_stream_out_stb  : in std_logic
        );
end component;

-- bram
component bram
generic (
    DATA    : integer := 32;
    ADDR    : integer := 12
);
port (
    -- Port A
    clka   : in std_logic;
    wea    : in std_logic;
    addra  : in std_logic_vector(ADDR-1 downto 0);
    dina   : in std_logic_vector(DATA-1 downto 0);
    douta  : out std_logic_vector(DATA-1 downto 0);

    -- Port B
    clkb   : in std_logic;
    web    : in std_logic;
    addrb  : in std_logic_vector(ADDR-1 downto 0);
    dinb   : in std_logic_vector(DATA-1 downto 0);
    doutb  : out std_logic_vector(DATA-1 downto 0)
);
end component;

-- datapath
-- todo

----------------------------------------------------------------------------------
-- signal/constant declaration
constant ADDR : integer := 9;
constant DATA : integer := 8;

constant BAUD : integer := 115200;
constant CLOCK_FREQUENCY : integer := 12_000_000;

-- Für UART --
signal data_stream_out_s : std_logic_vector(7 downto 0) := (others => '0');
signal data_stream_out_stb_s : std_logic := '0';

signal data_stream_in_s : std_logic_vector(7 downto 0) := (others => '0');
signal data_stream_in_ack_s : std_logic := '0';
signal data_stream_in_stb_s : std_logic := '0';

signal rst_s : std_logic;

-- Für BRAM --
signal addra_s, addrb_s : std_logic_vector(ADDR-1 downto 0) := (others => '0');

signal dina_s, douta_s : std_logic_vector(DATA-1 downto 0) := (others => '0');
signal dinb_s, doutb_s : std_logic_vector(DATA-1 downto 0) := (others => '0');

signal wea_s, web_s : std_logic := '0';

-- Für FSM --
signal dp_en_s : std_logic := '0';

signal useless : std_logic := '0';
signal useless_vec : std_logic_vector(8 downto 0);

begin
----------------------------------------------------------------------------------
-- default assignments
rst_s <= not rstn;
useless <= '0';
useless_vec <= "000000000";

led5 <= '1';
led1 <= button_dp;
led2 <= button_tx;
led3 <= not rstn;

PMOD5 <= uart_rx;
PMOD6 <= uart_tx;

----------------------------------------------------------------------------------
-- instantiate components

DPS: datapath
generic map
(
    offset => 3
)
port map
(
    din_uart => data_stream_out_s,
    din_BRAM => doutb_s,
    sel => dp_en_s,
    dout => dina_s
);

UARTS: uart
generic map
(
    baud                => BAUD,
    clock_frequency     => CLOCK_FREQUENCY
)
port map
(  
    clock               => clk,
    reset               => rst_s,    
    data_stream_in      => doutb_s,
    data_stream_in_stb  => data_stream_in_stb_s,
    data_stream_in_ack  => data_stream_in_ack_s,
    data_stream_out     => data_stream_out_s,
    data_stream_out_stb => data_stream_out_stb_s,
    tx                  => uart_tx,
    rx                  => uart_rx
);

BRAMS : bram
generic map
(
    DATA    => DATA,
    ADDR    => ADDR
)
port map
(
    -- Port A
    clka   => clk,
    wea    => wea_s,
    addra  => addra_s,
    dina   => dina_s,
    douta  => douta_s,

    -- Port B
    clkb   => clk,
    web    => web_s,
    addrb  => addrb_s,
    dinb   => dinb_s,
    doutb  => doutb_s
);

FSMS : fsm
port map
(
    clk => clk,
    rstn => rstn,
    button_dp => button_dp,
    button_tx => button_tx,

    dp_en => dp_en_s,

    bram_wra => wea_s,
    bram_rdb => web_s,
    bram_addra => addra_s,
    bram_addrb => addrb_s,

    uart_data_stream_in_stb => data_stream_in_stb_s,
    uart_data_stream_in_ack => data_stream_in_ack_s,
    uart_data_stream_out_stb => data_stream_out_stb_s
);

end rtl;
