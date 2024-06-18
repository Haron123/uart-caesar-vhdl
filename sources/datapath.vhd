library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
    generic
    (
        offset : integer := 3
    );
	port
	(
		din_uart : in std_logic_vector(7 downto 0);
		din_BRAM : in std_logic_vector(7 downto 0);
		sel : in std_logic;
		dout : out std_logic_vector(7 downto 0)
	);
end datapath;

architecture rtl of datapath is
	constant LETTERS : unsigned(7 downto 0) := to_unsigned(26, 8);
	constant UPPER_A : unsigned(7 downto 0) := to_unsigned(65, 8);
	constant LOWER_A : unsigned(7 downto 0) := to_unsigned(97, 8);
begin

    comb: process(din_uart, din_BRAM, sel)
		variable sel_v : std_logic;
        variable din_uart_v, din_BRAM_v, result_v, temp_v, input_v : std_logic_vector(7 downto 0);
    begin
        -- Get Input
        din_uart_v := din_uart;
		din_BRAM_v := din_BRAM;
		sel_v := sel;

        -- Calculate
		if sel_v = '1' then
			input_v := din_uart_v;
		else
			input_v := din_BRAM_v;
		end if;

        result_v := input_v;

		if sel_v = '0' then
        	--result_v := std_logic_vector(unsigned(result_v) + offset);
		

    	temp_v := std_logic_vector(unsigned(result_v) - UPPER_A);
        if unsigned(temp_v) < LETTERS then
    		temp_v := std_logic_vector(unsigned(temp_v) + offset);
    		if unsigned(temp_v) >= LETTERS then
    			temp_v := std_logic_vector(unsigned(temp_v) - LETTERS);
    		end if;
    		result_v := std_logic_vector(unsigned(temp_v) + UPPER_A);
        end if;

    	temp_v := std_logic_vector(unsigned(result_v) - LOWER_A);
        if unsigned(temp_v) < LETTERS then
           temp_v := std_logic_vector(unsigned(temp_v) + offset);
    		if unsigned(temp_v) >= LETTERS then
    			temp_v := std_logic_vector(unsigned(temp_v) - LETTERS);
    		end if;
    		result_v := std_logic_vector(unsigned(temp_v) + LOWER_A);
        end if;
		end if;

        -- Outputs
        dout <= result_v;
    end process comb;
    
end rtl;
