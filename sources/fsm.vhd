----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.05.2024 13:32:56
-- Design Name: 
-- Module Name: fsm - Behavioral
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------------------
-- entity
entity fsm is
    port (  
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
    
end fsm;

architecture rtl of fsm is

----------------------------------------------------------------------------------
-- define global types
type fsm_t is (IDLE, RECEIVE, CAESAR, TRANSMIT);

function state_to_integer(state: fsm_t) return integer is
begin 
    case state is
        when IDLE       => return 0;
        when RECEIVE    => return 1;
        when CAESAR     => return 2;
        when TRANSMIT   => return 3;
        when others     => return -1;
    end case;
end function;

----------------------------------------------------------------------------------
-- define signals

-- State
signal state_cs, state_ns : fsm_t;
signal state_num : integer;

-- DSP Port
signal dp_en_s : std_logic;

-- BRAM
signal bram_wra_s : std_logic;

-- UART
signal data_stream_in_stb_s : std_logic;

-- POINTER
signal write_addr_cs, write_addr_ns : std_logic_vector(7 downto 0);
signal read_addr_cs, read_addr_ns : std_logic_vector(7 downto 0);
signal area_flaga_s, area_flagb_s : std_logic;
signal caesar_addr_cs, caesar_addr_ns : std_logic_vector(7 downto 0);

signal caesar_delay_cs, caesar_delay_ns : std_logic_vector(1 downto 0);

begin
----------------------------------------------------------------------------------
-- default IO assignments
-- DSP Port
state_num <= state_to_integer(state_cs);
dp_en <= dp_en_s;

-- BRAM
bram_wra <= bram_wra_s;
bram_rdb <= '0';

with dp_en_s select
bram_addra <= (area_flaga_s & write_addr_cs) when '1',
              (area_flaga_s & caesar_addr_cs) when '0',
              (others => 'U') when others;

bram_addrb <= area_flagb_s & caesar_addr_cs when ((area_flagb_s = '0') and (dp_en_s = '0')) 
                  else area_flagb_s & read_addr_cs;

-- UART
uart_data_stream_in_stb <= data_stream_in_stb_s;

----------------------------------------------------------------------------------
-- sync process
sync: process(clk)
begin
    if rising_edge(clk) then
        if rstn = '0' then
            state_cs <= IDLE;
    
            -- BRAM
            write_addr_cs <= (others => '0');
            read_addr_cs <= (others => '0');
            caesar_addr_cs <= (others => '0');
            caesar_delay_cs <= (others => '0');
        else
            state_cs <= state_ns;
    
            -- BRAM
            write_addr_cs <= write_addr_ns;
            read_addr_cs <= read_addr_ns;
            caesar_addr_cs <= caesar_addr_ns;
            caesar_delay_cs <= caesar_delay_ns;
        end if;
    end if;
end process sync;

----------------------------------------------------------------------------------
-- combinatorial process (fsm)
comb: process(button_dp, button_tx, uart_data_stream_in_ack, uart_data_stream_out_stb, bram_wra_s,
              read_addr_cs, write_addr_cs, data_stream_in_stb_s, state_cs, caesar_addr_cs, dp_en_s, area_flaga_s, area_flagb_s, caesar_delay_cs)
    -- Inputs
    variable button_dp_v : std_logic;
    variable button_tx_v : std_logic;

    -- State
    variable state_v : fsm_t;

    -- DSP Port
    variable dp_en_v : std_logic;

    -- BRAM
    variable bram_wra_v : std_logic;
    variable write_addr_v, read_addr_v : std_logic_vector(7 downto 0); 
    variable caesar_addr_v : std_logic_vector(7 downto 0);
    variable area_flaga_v, area_flagb_v : std_logic;

    -- UART
    variable data_stream_in_ack_v : std_logic;
    variable data_stream_in_stb_v : std_logic;

    variable caesar_delay_v : std_logic_vector(1 downto 0);

begin
    button_dp_v := button_dp;
    button_tx_v := button_tx;

    state_v := state_cs;

    -- BRAM
    write_addr_v := write_addr_cs;
    read_addr_v := read_addr_cs;
    caesar_addr_v := caesar_addr_cs;
    caesar_delay_v := caesar_delay_cs;

    data_stream_in_ack_v := uart_data_stream_in_ack;

    dp_en_v := '1';
    bram_wra_v := '0';
    area_flaga_v := '0';
    area_flagb_v := '0';
    data_stream_in_stb_v := '0';

    case state_v is
        when IDLE =>
            -- Default Values
            bram_wra_v := '0';
            area_flaga_v := '0';
            area_flagb_v := '0';
            dp_en_v := '1';
            data_stream_in_stb_v := '0';

            -- Trigger for CAESAR
            if button_dp = '1' then 
                -- This is to avoid activating write enable while it would be invalid
                if caesar_addr_v = write_addr_v then
                    state_v := IDLE;
                else
                    area_flaga_v := '1'; -- Write into the Higher memory area
                    dp_en_v := '0';      -- Read from RAM 
                    bram_wra_v := '1';   -- Start Writing
                    state_v := CAESAR;
                end if;

            -- Trigger for RECEIVE
            elsif uart_data_stream_out_stb = '1' then
                bram_wra_v := '1';   -- Start Writing into Lower memory area
                dp_en_v := '1';      -- Read from UART
                state_v := RECEIVE;

            -- Trigger for TRANSMIT
            elsif button_tx = '1' then
                area_flagb_v := '1'; -- Read from Encrypted memory Area
                dp_en_v := '0';      -- Take data from RAM      
                state_v := TRANSMIT;
            end if;

        when RECEIVE =>
            -- Receive and Write data, then increment pointer
            write_addr_v := std_logic_vector(unsigned(write_addr_v) + 1);
            state_v := IDLE;
            
        when CAESAR =>
            if caesar_addr_v = write_addr_v then -- If we encrypted all received data, we stop
                bram_wra_v := '0';
                state_v := IDLE;
            else
                if caesar_delay_v = "10" then -- Wait for 2 Clock cycles so the RAM has enough time
                    area_flaga_v := '1'; -- Write into the Higher memory area
                    dp_en_v := '0';      -- Read from RAM 
                    bram_wra_v := '1';   -- Start Writing
                    caesar_addr_v := std_logic_vector(unsigned(caesar_addr_v) + 1);
                    caesar_delay_v := "00";
                else
                    area_flaga_v := '1'; -- Write into the Higher memory area
                    dp_en_v := '0';      -- Read from RAM 
                    bram_wra_v := '1';   -- Start Writing
                    caesar_delay_v := std_logic_vector(unsigned(caesar_delay_v) + 1);
                end if;
            end if;
        when TRANSMIT =>
            if read_addr_v = caesar_addr_v then
                data_stream_in_stb_v := '0';
                state_v := IDLE;
            else
                if data_stream_in_ack_v = '1' then
                    read_addr_v := std_logic_vector(unsigned(read_addr_v) + 1);
                else
                    data_stream_in_stb_v := '1';
                    area_flagb_v := '1'; -- Read from Encrypted memory Area
                    dp_en_v := '0';      -- Take data from RAM 
                end if;
            end if;
    end case;

    state_ns <= state_v;

    -- DSP Port
    dp_en_s <= dp_en_v;

    -- BRAM
    bram_wra_s <= bram_wra_v;
    write_addr_ns <= write_addr_v;
    read_addr_ns <= read_addr_v;
    caesar_addr_ns <= caesar_addr_v;
    area_flaga_s <= area_flaga_v;
    area_flagb_s <= area_flagb_v;
    caesar_delay_ns <= caesar_delay_v;

    -- UART
    data_stream_in_stb_s <= data_stream_in_stb_v;

end process comb;

end rtl;