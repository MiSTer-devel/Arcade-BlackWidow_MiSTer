-- Implementation of a filter to boost the high frequencies of the signals
-- to the deflection amps.

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


entity filter is
	generic (
		mul: integer :=6;
		pole: integer := 63842);
    Port ( input : in  STD_LOGIC_VECTOR (9 downto 0);
           output : out  STD_LOGIC_VECTOR (9 downto 0);
			  reset: in STD_LOGIC;
           clk : in  STD_LOGIC);
end filter;

--Filter constants etc aquired from http://www-users.cs.york.ac.uk/~fisher/mkfilter
--1sd order Bessel hipass filter at 50KHz (when input clock is 12MHz) with 16.16 fixed point values.

architecture Behavioral of filter is

--constant mul0: STD_LOGIC_VECTOR(31 downto 0) := "00000000000000001111111010101001"; --5KHz
--constant mul0: STD_LOGIC_VECTOR(31 downto 0) := "00000000000000001111101010110001"; --20KHz
--constant mul0: STD_LOGIC_VECTOR(31 downto 0) := "00000000000000001111001011101111"; --50KHz
--constant mul0: STD_LOGIC_VECTOR(31 downto 0) := "00000000000000001101101010100101"; --150KHz
signal xv0: STD_LOGIC_VECTOR(31 downto 0);
signal xv1: STD_LOGIC_VECTOR(31 downto 0);
signal yv0: STD_LOGIC_VECTOR(31 downto 0);
signal yvmul0: STD_LOGIC_VECTOR(63 downto 0);
signal outval: STD_LOGIC_VECTOR(31 downto 0);
begin
filter: process(clk, reset)
begin
	if reset='1' then
		xv0<=(others=>'0');
		yv0<=(others=>'0');
	elsif rising_edge(clk) then
		xv0<=xv1;
		yv0<=(xv1-xv0)+yvmul0(47 downto 16);
		if (outval(26)='0') then
			output<=outval(25 downto 16);
		else
			if (outval(31)='1') then
				output<="0000000000";
			else
				output<="1111111111";
			end if;
		end if;
	end if;
end process;
yvmul0<=conv_std_logic_vector(pole,64)*sxt(yv0,64);
outval<=(yv0*conv_std_logic_vector(mul, 32))+xv1;
xv1<="000000"&input&"0000000000000000";
end Behavioral;

