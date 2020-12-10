
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


--The program ROM.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.pkg_bwidow.all;

entity pgmrom is
    Port ( addr : in  STD_LOGIC_VECTOR (14 downto 0);
           data : out  STD_LOGIC_VECTOR (7 downto 0);
           clk_25 : in  STD_LOGIC;
           clk : in  STD_LOGIC;
			  
				dn_addr           : in 	std_logic_vector(15 downto 0);
				dn_data         	 : in 	std_logic_vector(7 downto 0);
				dn_wr				 : in 	std_logic	

			  );
end pgmrom;

architecture Behavioral of pgmrom is
	signal dataa: 		std_logic_vector(7 downto 0);
	signal datab: 		std_logic_vector(7 downto 0);
	signal datac: 		std_logic_vector(7 downto 0);
	signal datad: 		std_logic_vector(7 downto 0);
	signal datae: 		std_logic_vector(7 downto 0);
	signal dataf: 		std_logic_vector(7 downto 0);
--	signal datag: 		std_logic_vector(7 downto 0);

   signal rom_a_cs: std_logic;
   signal rom_b_cs: std_logic;
   signal rom_c_cs: std_logic;
   signal rom_d_cs: std_logic;
   signal rom_e_cs: std_logic;
   signal rom_f_cs: std_logic;
begin

--136017-101.d1	4096	0			0000 000000000000
--136017-102.ef1	4096	4096		0001 000000000000
--136017-103.h1	4096	8192		0010 000000000000
--136017-104.j1	4096	12288		0011 000000000000
--136017-105.kl1	4096	16384		0100 000000000000
--136017-106.m1	4096	20480		0101 000000000000

rom_a_cs <= '1' when dn_addr(15 downto 12) = "0000"     else '0';
rom_b_cs <= '1' when dn_addr(15 downto 12) = "0001"     else '0';
rom_c_cs <= '1' when dn_addr(15 downto 12) = "0010"     else '0';
rom_d_cs <= '1' when dn_addr(15 downto 12) = "0011"     else '0';
rom_e_cs <= '1' when dn_addr(15 downto 12) = "0100"     else '0';
rom_f_cs <= '1' when dn_addr(15 downto 12) = "0101"     else '0';

roma : work.dpram generic map (12,8)
port map
(
	clock_a   => Clk_25,
	wren_a    => dn_wr and rom_a_cs,
	address_a => dn_addr(11 downto 0),
	data_a    => dn_data,

	clock_b   => clk,
	address_b => addr(11 downto 0),
	q_b       => dataa
);	  
romb : work.dpram generic map (12,8)
port map
(
	clock_a   => Clk_25,
	wren_a    => dn_wr and rom_b_cs,
	address_a => dn_addr(11 downto 0),
	data_a    => dn_data,

	clock_b   => clk,
	address_b => addr(11 downto 0),
	q_b       => datab
);	  
romc : work.dpram generic map (12,8)
port map
(
	clock_a   => Clk_25,
	wren_a    => dn_wr and rom_c_cs,
	address_a => dn_addr(11 downto 0),
	data_a    => dn_data,

	clock_b   => clk,
	address_b => addr(11 downto 0),
	q_b       => datac
);	  
romd : work.dpram generic map (12,8)
port map
(
	clock_a   => Clk_25,
	wren_a    => dn_wr and rom_d_cs,
	address_a => dn_addr(11 downto 0),
	data_a    => dn_data,

	clock_b   => clk,
	address_b => addr(11 downto 0),
	q_b       => datad
);	  
rome : work.dpram generic map (12,8)
port map
(
	clock_a   => Clk_25,
	wren_a    => dn_wr and rom_e_cs,
	address_a => dn_addr(11 downto 0),
	data_a    => dn_data,

	clock_b   => clk,
	address_b => addr(11 downto 0),
	q_b       => datae
);	  
romf : work.dpram generic map (12,8)
port map
(
	clock_a   => Clk_25,
	wren_a    => dn_wr and rom_f_cs,
	address_a => dn_addr(11 downto 0),
	data_a    => dn_data,

	clock_b   => clk,
	address_b => addr(11 downto 0),
	q_b       => dataf
);	  


--	roma: entity work.rom_pgma port map (
--		clock 	=> clk,
--		address 	=> addr(11 downto 0),
--		q 			=> dataa
--	);
--	romb: entity work.rom_pgmb port map (
--		clock 	=> clk,
--		address 	=> addr(11 downto 0),
--		q 			=> datab
--	);
--	romc: entity work.rom_pgmc port map (
--		clock 	=> clk,
--		address 	=> addr(11 downto 0),
--		q 			=> datac
--	);
--	romd: entity work.rom_pgmd port map (
--		clock 	=> clk,
--		address 	=> addr(11 downto 0),
--		q 			=> datad
--	);
--	rome: entity work.rom_pgme port map (
--		clock 	=> clk,
--		address 	=> addr(11 downto 0),
--		q 			=> datae
--	);
--	romf: entity work.rom_pgmf port map (
--		clock 	=> clk,
--		address 	=> addr(11 downto 0),
--		q 			=> dataf
--	);

	data <=	dataa when addr(14 downto 12)="001" else 
				datab when addr(14 downto 12)="010" else 
				datac when addr(14 downto 12)="011" else 
				datad when addr(14 downto 12)="100" else 
				datae when addr(14 downto 12)="101" else 
				dataf when addr(14 downto 12)="110" else 
				dataf when addr(14 downto 12)="111" --last rom is mirrored once
				else "00000000";
end Behavioral;

