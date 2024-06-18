-- ----------------------------------------------------------------
-- @name:   BRAM_template.vhd
-- @Copyright (c) 2015, CETIC All rights reserved.
--
-- @info:
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--    * Redistributions of source code must retain the above copyright
--     notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of the copyright holder nor the names of its
--      contributors may be used to endorse or promote products derived
--      from this software without specific prior written permission.
--
-- @disclaimer:
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity bram is
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
end bram;

architecture rtl of bram is
    -- Shared memory
    type mem_type is array ( (2**ADDR)-1 downto 0 ) of std_logic_vector(DATA-1 downto 0);
    shared variable mem : mem_type := (others => (others => '0'));
    signal mem_0, mem_1, mem_2, mem_3, mem_4, mem_5, mem_256, mem_257, mem_258, mem_259, mem_260, mem_261 : std_logic_vector(DATA-1 downto 0);
begin

process(clka)
begin
    mem_0 <= mem(0);
    mem_1 <= mem(1);
    mem_2 <= mem(2);
    mem_3 <= mem(3);
    mem_4 <= mem(4);
    mem_5 <= mem(5);
    mem_256 <= mem(256);
    mem_257 <= mem(257);
    mem_258 <= mem(258);
    mem_259 <= mem(259);
    mem_260 <= mem(260);
    mem_261 <= mem(261);
end process;

-- Port A
process(clka)
begin
    
    if(clka'event and clka='1') then
        if(wea='1') then
            mem(to_integer(unsigned(addra))) := dina;
 --           report "Bram write-a " & integer'image(to_integer(unsigned(dina))) & " at " & integer'image(to_integer(unsigned(addra)));
        end if;
        douta <= mem(to_integer(unsigned(addra)));
    end if;
end process;

-- Port B
process(clkb)
begin
    if(clkb'event and clkb='1') then
        if(web='1') then
            mem(to_integer(unsigned(addrb))) := dinb;
 --           report "Bram write-b " & integer'image(to_integer(unsigned(dinb))) & " at " & integer'image(to_integer(unsigned(addrb)));
        end if;
        doutb <= mem(to_integer(unsigned(addrb)));
    end if;
end process;

end rtl;