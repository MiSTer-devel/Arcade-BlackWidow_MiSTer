-- Test package: noise generator


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

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity noisegen is
    Port ( noise : out  STD_LOGIC_VECTOR (9 downto 0);
           clock : in  STD_LOGIC;
           reset : in  STD_LOGIC);
end noisegen;

architecture Behavioral of noisegen is
signal shiftreg: STD_LOGIC_VECTOR(18 downto 0);
begin
noisegen: process(clock, reset)
begin
	if reset='1' then
		noise<="0000000000";
		shiftreg<="1010101010101010101";
	elsif rising_edge(clock) then
		shiftreg(18 downto 1)<=shiftreg(17 downto 0);
		shiftreg(0)<=shiftreg(18) xor shiftreg(17) xor shiftreg(16) xor shiftreg(13) xor '1';
		noise<=shiftreg(9 downto 0);
	end if;
end process;
end Behavioral;

