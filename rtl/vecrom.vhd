--Vector rom. Warning: roma is smaller and mirrored once.

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

use work.pkg_bwidow.all;

entity vecrom is
    Port ( addr : in  STD_LOGIC_VECTOR (13 downto 0);
           data : out  STD_LOGIC_VECTOR (7 downto 0);
			  clk_25 : in  STD_LOGIC;
           clk : in  STD_LOGIC;
			  dn_addr           : in 	std_logic_vector(15 downto 0);
			  dn_data         	 : in 	std_logic_vector(7 downto 0);
			  dn_wr				 : in 	std_logic			  
			  );
end vecrom;

architecture Behavioral of vecrom is
	signal dataa: 		std_logic_vector(7 downto 0);
	signal datab: 		std_logic_vector(7 downto 0);
	signal datac: 		std_logic_vector(7 downto 0);
	signal datad: 		std_logic_vector(7 downto 0);
	
	signal rom_va_cs: std_logic;
   signal rom_vb_cs: std_logic;
   signal rom_vc_cs: std_logic;
   signal rom_vd_cs: std_logic;

begin

--136017-107.l7	2048	24576		0110 000000000000
--blank				2048	26624		0110 100000000000
--136017-108.mn7	4096	28672		0111 000000000000
--136017-109.np7	4096	32768		1000 000000000000
--136017-110.r7	4096	36864		1001 000000000000


rom_va_cs <= '1' when dn_addr(15 downto 12) = "0110"     else '0';
rom_vb_cs <= '1' when dn_addr(15 downto 12) = "0111"     else '0';
rom_vc_cs <= '1' when dn_addr(15 downto 12) = "1000"     else '0';
rom_vd_cs <= '1' when dn_addr(15 downto 12) = "1001"     else '0';

roma : work.dpram generic map (12,8)
port map
(
	clock_a   => Clk_25,
	wren_a    => dn_wr and rom_va_cs,
	--address_a => dn_addr(10 downto 0),
	address_a => dn_addr(11 downto 0),
	data_a    => dn_data,

	clock_b   => clk,
	--address_b => addr(10 downto 0),
	address_b => addr(11 downto 0),
	q_b       => dataa
);	  
romb : work.dpram generic map (12,8)
port map
(
	clock_a   => Clk_25,
	wren_a    => dn_wr and rom_vb_cs,
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
	wren_a    => dn_wr and rom_vc_cs,
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
	wren_a    => dn_wr and rom_vd_cs,
	address_a => dn_addr(11 downto 0),
	data_a    => dn_data,

	clock_b   => clk,
	address_b => addr(11 downto 0),
	q_b       => datad
);	  

--	roma: entity work.rom_veca port map (
--		clock 	=> clk,
--		address 	=> addr(10 downto 0),
--		q 			=> dataa
--	);
--	romb: entity work.rom_vecb port map (
--		clock 	=> clk,
--		address 	=> addr(11 downto 0),
--		q 			=> datab
--	);
--	romc: entity work.rom_vecc port map (
--		clock 	=> clk,
--		address 	=> addr(11 downto 0),
--		q 			=> datac
--	);
--	romd: entity work.rom_vecd port map (
--		clock 	=> clk,
--		address 	=> addr(11 downto 0),
--		q 			=> datad
--	);

--Watch the weird inversion of romd and romb!
	data <=	dataa	when addr(13 downto 12)="00" else  --Mirrors once.
				datab when addr(13 downto 12)="01" else 
				datac when addr(13 downto 12)="10" else 
				datad when addr(13 downto 12)="11"
				else "00000000";
end Behavioral;

