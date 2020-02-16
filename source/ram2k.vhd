--2K of 8bit RAM

-- Black Widow arcade hardware implemented in an FPGA
-- (C) 2012 Jeroen Domburg (jeroen AT spritesmods.com)
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



entity ram2k is
    Port ( addr : in  STD_LOGIC_VECTOR (10 downto 0);
           data_in : in  STD_LOGIC_VECTOR (7 downto 0);
           data_out : out  STD_LOGIC_VECTOR (7 downto 0);
           rw_l : in  STD_LOGIC;
           cs_l : in  STD_LOGIC;
           ena : in  STD_LOGIC;
           clk : in  STD_LOGIC);
end ram2k;

architecture Behavioral of ram2k is
	signal we:		STD_LOGIC;
begin
-- Xilinx block RAM
--	myram: RAMB16_S9 port map (
--		WE => we,
--		EN => ena,
--		CLK => clk,
--		ADDR => addr,
--		DI => data_in,
--		DO => data_out,
--		DIP => "0"
--	);

-- Altera RAM
myram: entity work.ram_2k port map(
	wren		=> we,
	clken		=> ena,
	clock		=> clk,
	address	=> addr,
	data		=> data_in,
	q			=> data_out
	);

	we <= (not cs_l) and (not rw_l) and ena;
end Behavioral;

