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



entity dpram2k is
	Port ( addr_a : in  STD_LOGIC_VECTOR (10 downto 0);
		data_in_a : in  STD_LOGIC_VECTOR (7 downto 0);
		data_out_a : out  STD_LOGIC_VECTOR (7 downto 0);
		rw_l_a : in  STD_LOGIC;
		cs_l_a : in  STD_LOGIC;
		ena_a : in  STD_LOGIC;
		clk_a : in  STD_LOGIC;

		addr_b : in  STD_LOGIC_VECTOR (10 downto 0);
		data_in_b : in  STD_LOGIC_VECTOR (7 downto 0);
		data_out_b : out  STD_LOGIC_VECTOR (7 downto 0);
		we_b : in  STD_LOGIC;
		ena_b : in  STD_LOGIC;
		clk_b : in  STD_LOGIC
);
end dpram2k;

architecture Behavioral of dpram2k is
	signal we_a:		STD_LOGIC;
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
myram: entity work.dpram generic map (11,8) port map(
	wren_a		=> we_a,
	enable_a		=> ena_a,
	clock_a		=> clk_a,
	address_a	=> addr_a,
	data_a		=> data_in_a,
	q_a			=> data_out_a,
	
	wren_b		=> we_b,
	enable_b		=> ena_b,
	clock_b		=> clk_b,
	address_b	=> addr_b,
	data_b		=> data_in_b,
	q_b			=> data_out_b
);

	we_a <= (not cs_l_a) and (not rw_l_a) and ena_a;
end Behavioral;

