--=============================================================================--
-- Black Widow logic. Everything from here should be implementation-agnostic.
--===========================================================================--

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

library ieee;
   use ieee.std_logic_1164.all;
   use IEEE.STD_LOGIC_ARITH.ALL;
   use IEEE.STD_LOGIC_UNSIGNED.ALL;
   use ieee.numeric_std.all;
	
use work.pkg_bwidow.all;

entity bwidow is
  port(
		reset_h   : in    std_logic;
		clk			: in    std_logic; --12 MHz
		pause_h   : in    std_logic;
		analog_sound_out    : out std_logic_vector(7 downto 0);
		analog_x_out    : out std_logic_vector(9 downto 0);
		analog_y_out    : out std_logic_vector(9 downto 0);
		analog_z_out    : out std_logic_vector(7 downto 0);
		BEAM_ENA          : out   std_logic;
		rgb_out    : out std_logic_vector(2 downto 0);
		--buttons				 : in std_logic_vector(14 downto 0);
		SW_B4				 : in std_logic_vector(7 downto 0);
		SW_D4				 : in std_logic_vector(7 downto 0);
		dn_addr           : in 	std_logic_vector(15 downto 0);
		dn_data         	 : in 	std_logic_vector(7 downto 0);
		dn_wr				 : in 	std_logic	;
		input_0        : in  std_logic_vector( 7 downto 0);
		--input_1        : in  std_logic_vector( 7 downto 0);
		--input_2        : in  std_logic_vector( 7 downto 0);
		input_3        : in  std_logic_vector( 7 downto 0);
		input_4        : in  std_logic_vector( 7 downto 0);

		dbg				 : out std_logic_vector(15 downto 0);
		
		-- HISCORE
		hs_address   : in  std_logic_vector(15 downto 0);
		hs_data_out  : out std_logic_vector(7 downto 0);
		hs_data_in   : in  std_logic_vector(7 downto 0);
		hs_write     : in  std_logic
		
	);
end bwidow;

architecture Behaviour of bwidow is
	signal c_addr			: std_logic_vector(23 downto 0);
	signal c_din			: std_logic_vector(7 downto 0);
	signal c_dout			: std_logic_vector(7 downto 0);
	signal c_rw_l			: std_logic;
	signal c_irq_l			: std_logic;
	signal avg_dout		: std_logic_vector(7 downto 0);
	signal pgmrom_dout	: std_logic_vector(7 downto 0);
	signal pgmram_dout	: std_logic_vector(7 downto 0);
	signal pgmrom_addr	: std_logic_vector(15 downto 0);
	signal pgmram_addr	: std_logic_vector(10 downto 0);
	signal avgmem_addr	: std_logic_vector(15 downto 0);
	signal earom_dout		: std_logic_vector(7 downto 0);
	signal pokeya_dout	: std_logic_vector(7 downto 0);
	signal pokeyb_dout	: std_logic_vector(7 downto 0);
	signal pokeya_cs_l	: std_logic;
	signal pokeyb_cs_l	: std_logic;
	signal pgmram_cs_l	: std_logic;
	signal avgmem_cs_l	: std_logic;
	signal earom_write_l	: std_logic;
	signal earom_con_l	: std_logic;
	signal pokeya_audio	: std_logic_vector(7 downto 0);
	signal pokeyb_audio	: std_logic_vector(7 downto 0);
	signal latchin_a		: std_logic_vector(7 downto 0);
	signal latchin_b		: std_logic_vector(7 downto 0);
	signal latchin_c		: std_logic_vector(7 downto 0);
	signal latchout		: std_logic_vector(7 downto 0) := (others => '0');
	signal cnt_3khz		: std_logic_vector(8 downto 0);
	signal ena_1_5M		: std_logic;
	signal reset_l			: std_logic;
	signal avg_rst			: std_logic;
	signal avg_go			: std_logic;
	signal avg_halted		: std_logic;
	signal avg_dbg			: std_logic_vector(15 downto 0);
	signal clkdiv			: std_logic_vector(2 downto 0);
	signal irqctr			: std_logic_vector(3 downto 0);
	signal intack_l		: std_logic;
	signal service_btnst	: std_logic;
begin
	pokeya: pokey port map (
		ADDR      => c_addr(3 downto 0),
		DIN       => c_dout,
		DOUT      => pokeya_dout,
		DOUT_OE_L => open,
		RW_L      => c_rw_l,
		CS        => '1',
		CS_L      => pokeya_cs_l,
		AUDIO_OUT => pokeya_audio,
		PIN       => SW_D4, -- dip free play?
		ENA       => ena_1_5M,
		CLK       => clk
	);

	pokeyb: pokey port map (
		ADDR      => c_addr(3 downto 0),
		DIN       => c_dout,
		DOUT      => pokeyb_dout,
		DOUT_OE_L => open,
		RW_L      => c_rw_l,
		CS        => '1',
		CS_L      => pokeyb_cs_l,
		AUDIO_OUT => pokeyb_audio,
		PIN       => SW_B4,
		ENA       => ena_1_5M,
		CLK       => clk
	);

	cpu: T65 port map (
		Mode    => "00",
		Res_n   => reset_l,
		Enable  => ena_1_5M,
		Clk     => clk,
		Rdy     => not pause_h,
		Abort_n => '1',
		IRQ_n   => c_irq_l,
		NMI_n   => '1',
		SO_n    => '1',
		R_W_n   => c_rw_l,
		Sync    => open,
		EF      => open,
		MF      => open,
		XF      => open,
		ML_n    => open,
		VP_n    => open,
		VDA     => open,
		VPA     => open,
		A       => c_addr,
		DI      => c_din,
		DO      => c_dout
	);
	
	mypgmrom: pgmrom port map (
		addr		=> pgmrom_addr(14 downto 0),
		data		=> pgmrom_dout,
		clk		=> clk,
		dn_addr =>dn_addr,
		dn_data =>dn_data,
		dn_wr =>dn_wr
	);
	
	mypgmram: entity work.dpram2k port map (
		addr_a		=> pgmram_addr,
		data_in_a	=> c_dout,
		data_out_a	=> pgmram_dout,
--		ena 	 		=> ena_1_5M, --doesn't work due to pipelining
		ena_a			=> '1',
		cs_l_a		=> pgmram_cs_l, -- no enable on Altera, hopefully this works
		rw_l_a 		=> c_rw_l,
		clk_a			=> clk,
		
		addr_b		=> hs_address(10 downto 0),
		data_in_b	=> hs_data_in,
		data_out_b	=> hs_data_out,
		ena_b			=> '1',
		we_b			=> hs_write,
		clk_b			=> clk
	);
	
	myearom: earom port map (
		reset_l	=> reset_l,
		clk		=> clk,
		data_in	=> c_dout,
		data_out => earom_dout,
		addr		=> c_addr(5 downto 0),
--		we_l		=> c_wr_l,
		write_l	=> earom_write_l,
		con_l		=> earom_con_l
	);

	myavg: avg port map (
		clk => clk,
		clken => ena_1_5M,
		cpu_data_in => avg_dout,
		cpu_data_out => c_dout,
		cpu_addr => avgmem_addr(13 downto 0),
		cpu_cs_l => avgmem_cs_l,
		cpu_rw_l => c_rw_l,
		vgrst => avg_rst,
		vggo => avg_go,
		halted => avg_halted,
		xout => analog_x_out,
		yout => analog_y_out,
		zout => analog_z_out,
		rgbout => rgb_out,
		dbg => avg_dbg,
		dn_addr =>dn_addr,
		dn_data =>dn_data,
		dn_wr =>dn_wr
		
	);

	-- Memory decoding: CPU read
	c_din <= latchin_a	when c_addr(15 downto 11)="10001" else
				latchin_b	when c_addr(15 downto 11)="10000" else
				latchin_c	when c_addr(15 downto 11)="01111" else
				earom_dout	when c_addr(15 downto 11)="01110" else
				pokeyb_dout	when c_addr(15 downto 11)="01101" else
				pokeya_dout	when c_addr(15 downto 11)="01100" else
				avg_dout		when c_addr(15 downto 12)="0101" else
				avg_dout		when c_addr(15 downto 12)="0100" else
				avg_dout		when c_addr(15 downto 12)="0011" else
				avg_dout		when c_addr(15 downto 11)="00101" else
				avg_dout		when c_addr(15 downto 11)="00100" else
				pgmram_dout	when c_addr(15 downto 11)="00000" else
				pgmrom_dout	when c_addr(15)='1' else
				"00000000";

	-- Memory decoding: CPU writes
	pokeya_cs_l <= '0' when c_addr(15 downto 11)="01100" else '1';
	pokeyb_cs_l <= '0' when c_addr(15 downto 11)="01101" else '1';
	pgmram_cs_l <= '0' when c_addr(15 downto 11)="00000" else '1';
	avgmem_cs_l <= '0' when c_addr(15 downto 12)="0101" else
						'0' when c_addr(15 downto 12)="0100" else
						'0' when c_addr(15 downto 12)="0011" else
						'0' when c_addr(15 downto 11)="00101" else
						'0' when c_addr(15 downto 11)="00100" else '1';
	earom_write_l <= '0' when c_addr(15 downto 6)="1000100101" else '1';
	earom_con_l <= '0' when c_addr(15 downto 6)="1000100100" else '1';
	intack_l <= '0' when c_addr(15 downto 6)="1000100011" else '1';
	avg_go <= '1' when c_addr(15 downto 6)="1000100001" else '0';
	avg_rst <= '1' when c_addr(15 downto 6)="1000100010" else '0';
	
	process(clk) begin
		if clk'EVENT and clk='1' then
			if c_addr(15 downto 12)="1000100000" and c_rw_l='0' then
				latchout <= c_dout;
			end if;
		end if;
	end process;

--	dbg(15)<=clk;
--	dbg(14)<=ena_1_5M;
--	dbg(13)<=cnt_3khz(8);
--	dbg(12)<=intack_l;
--	dbg(11 downto 0)<=avg_dbg(15 downto 4);
--	dbg<=c_addr(15 downto 0);
--	dbg(7 downto 0)<=c_addr(7 downto 0);
--	dbg(15 downto 8)<=pgmram_dout;
	dbg<=avg_dbg;
	
	analog_sound_out<=(("0"&pokeya_audio(7 downto 1))+("0"&pokeyb_audio(7 downto 1)));
	
	-- Memory decoding: offsets in address map
	pgmrom_addr<=c_addr(15 downto 0);
--	avgmem_addr<=c_addr(15 downto 0)-x"002000"; 
	avgmem_addr<= c_addr(15 downto 0)-"10000000000000"; -- broken
	pgmram_addr(10)<=c_addr(10) xor latchout(2); --handle banksel
	pgmram_addr(9 downto 0)<=c_addr(9 downto 0);
	
	--Misc stuff
	reset_l <= not reset_h;

	--Latches
	----buttons(14 downto 0): SELFTEST, SA, COINAUX COINL COINR START2 START1 FD FU FL FR MU MD ML MR
	--latchin_c(7)<=cnt_3khz(8);
	--latchin_c(6)<=avg_halted;
	--latchin_c(5)<='1';--buttons(14); -- self test?
	----latchin_c(4)<=buttons(14); -- self test? handled below
	--latchin_c(3)<='1'; --nc
	--latchin_c(2 downto 0)<=buttons(12 downto 10);
	--latchin_b(7 downto 4)<="0000"; --option2-0, spare
	--latchin_b(3 downto 0)<=buttons(3 downto 0);
	--latchin_a(7)<='0'; --cabinet1
	--latchin_a(6 downto 5)<=buttons(9 downto 8);
	--latchin_a(4)<='0'; --spare
	--latchin_a(3 downto 0)<=buttons(7 downto 4);
	
	latchin_c(7)<=cnt_3khz(8);
	latchin_c(6)<=avg_halted;
	latchin_c(5 downto 0)<=input_0(5 downto 0);
	latchin_b(7 downto 0)<=input_3(7 downto 0);
	latchin_a(7 downto 0)<=input_4(7 downto 0);
		

	c_irq_l<=not(irqctr(3) and irqctr(2)); --triggers irq 250 times per second.

	--Clock divider to generate the 1.5MHz enable signal. Also handles the 3KHz counter and 250Hz interrupt.
	process(clk) begin
		if clk'EVENT and clk='1' then
			clkdiv<=clkdiv+"001";
			if (clkdiv="000") then
				ena_1_5M<='1';
				cnt_3khz<=cnt_3khz+"000000001";
				if cnt_3KHz="000000000" and intack_l='1' and c_irq_l='1' then
					irqctr<=irqctr+"0001";
				end if;
			else
				ena_1_5M<='0';
			end if;
			if intack_l='0' then
				irqctr<="0000";
			end if;
		end if;
	end process;

	--Handle service switch
--	process(clk) begin
--		if clk'EVENT and clk='1' then
--			if reset_h='1' then
--				latchin_c(4)<='1';
--			elsif (service_btnst='1' and buttons(13)='0') then
--				latchin_c(4)<=not latchin_c(4);
--			end if;
--			service_btnst<=buttons(13);
--		end if;
--	end process;
	
	
	  BEAM_ENA <= ena_1_5m;

end Behaviour;

