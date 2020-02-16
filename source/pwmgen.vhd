--PWM-signal generator


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


--ToDo: deadtime?

entity pwmgen is
	generic (
		width: integer :=4
   );
    Port ( inval : in  STD_LOGIC_VECTOR (width-1 downto 0);
           output : out  STD_LOGIC;
           clk : in  STD_LOGIC;
           reset : in  STD_LOGIC);
end pwmgen;

architecture Behavioral of pwmgen is
signal val_int: STD_LOGIC_VECTOR(width-1 downto 0);
signal count: STD_LOGIC_VECTOR(width-1 downto 0);
begin
pwm: process(clk, reset)
begin
	if reset='1' then
		output<='0';
		count<=(others => '0');
	elsif rising_edge(clk) then
		count<=count+"1";
		if count<val_int then
			output<='1';
		else
			output<='0';
		end if;
		if count=(width downto 0 => '0') then
			val_int<=inval;
		end if;
	end if;
end process;
end Behavioral;

