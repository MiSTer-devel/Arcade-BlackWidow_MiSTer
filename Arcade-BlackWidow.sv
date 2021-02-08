//============================================================================
//  Arcade: Black Widow
//
//  Port to MiSTer
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	// Use framebuffer from DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of 16 bytes.
	`ifdef USE_FB
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
	`endif
	
	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,    // 1 - signed audio samples, 0 - unsigned

	`ifdef USE_DDRAM
	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,
	`endif
	
	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
);

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

wire [1:0] ar = status[15:14];

assign VIDEO_ARX =  (!ar) ? ( 8'd4) : (ar - 1'd1);
assign VIDEO_ARY =  (!ar) ? ( 8'd3) : 12'd0;

//assign {FB_PAL_CLK, FB_FORCE_BLANK, FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;

`include "build_id.v" 
localparam CONF_STR = {
	"A.BWIDOW;;",
	"-;",
	"H0OEF,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
//	"O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",  
	"-;",
	//"O7,Test,Off,On;",
	"DIP;",
	"-;",
	"R0,Reset;",
	"J1,Fire Right,Fire Left,Fire Down,Fire Up,Start 1,Start 2,Coin;",
	"jn,A,B,X,Y,Start,Select,R;",
	"V,v2.00.",`BUILD_DATE
};


//wire [7:0] sw_d4 = {2'b00, 2'b00,1'b0,3'b000}; // coins
//wire [7:0] sw_b4 = { status[9:8],status[11:10],status[14:13],status[16:15]};
//wire [7:0] sw_b4 = {status[16:15],status[14:13],status[11:10], status[9:8]};

/*
-------------------------------------------------------------------------------
Settings of 8-Toggle Switch on Black Widow CPU PCB (at D4)
 8   7   6   5   4   3   2   1   Option
-------------------------------------------------------------------------------
Off Off                          1 coin/1 credit <
On  On                           1 coin/2 credits
On  Off                          2 coins/1 credit
Off On                           Free play

        Off Off                  Right coin mechanism x 1 <
        On  Off                  Right coin mechanism x 4
        Off On                   Right coin mechanism x 5
        On  On                   Right coin mechanism x 6

                Off              Left coin mechanism x 1 <
                On               Left coin mechanism x 2

                    Off Off Off  No bonus coins (0)* <
                    Off On  On   No bonus coins (6)
                    On  On  On   No bonus coins (7)

                    On  Off Off  For every 2 coins inserted,
                                 logic adds 1 more coin (1)
                    Off On  Off  For every 4 coins inserted,
                                 logic adds 1 more coin (2)
                    On  On  Off  For every 4 coins inserted,
                                 logic adds 2 more coins (3)
                    Off Off On   For every 5 coins inserted,
                                 logic adds 1 more coin (4)
                    On  Off On   For every 3 coins inserted,
                                 logic adds 1 more coin (5)

-------------------------------------------------------------------------------

* The numbers in parentheses will appear on the BONUS ADDER line in the
  Operator Information Display (Figure 2-1) for these settings.
< Manufacturer's recommended setting


                Table 1-3  Switch Settings for Special Options

-------------------------------------------------------------------------------
Settings of 4-Toggle Switch on Black Widow CPU PCB (at P10/11)
 4   3   2   1                   Option
-------------------------------------------------------------------------------
            On                   Credits counted on one coin counter
            Off                  Credits counted on two separate coin counters
-------------------------------------------------------------------------------


          Table 1-4  Switch Settings for Bonus and Difficulty Options

-------------------------------------------------------------------------------
Settings of 8-Toggle Switch on Black Widow CPU PCB (at B4)
 8   7   6   5   4   3   2   1   Option
-------------------------------------------------------------------------------
Off Off                          Maximum start at level 13
On  Off                          Maximum start at level 21 <
Off On                           Maximum start at level 37
On  On                           Maximum start at level 53

        Off Off                  3 spiders per game <
        On  Off                  4 spiders per game
        Off On                   5 spiders per game
        On  On                   6 spiders per game

                Off Off          Easy game play
                On  Off          Medium game play <
                Off On           Hard game play
                On  On           Demonstration mode

                        Off Off  Bonus spider every 20,000 points <
                        On  Off  Bonus spider every 30,000 points
                        Off On   Bonus spider every 40,000 points
                        On  On   No bonus

*/

////////////////////   CLOCKS   ///////////////////

wire clk_6, clk_12,clk_25, clk_50;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_50),	
	.outclk_1(clk_25),	
	.outclk_2(clk_12),	
	.outclk_3(clk_6),	
	.locked(pll_locked)
);


///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire [21:0] gamma_bus;
wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_index;

wire [15:0] joy_0, joy_1;
wire [15:0] joy = joy_0 | joy_1;
wire        rom_download = ioctl_download && !ioctl_index;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_12),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.status_menumask(direct_video),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),

	.joystick_0(joy_0),
	.joystick_1(joy_1)
);

reg mod_bwidow     = 0;
reg mod_gravitar   = 0;
reg mod_lunarbat   = 0;
reg mod_spacduel   = 0;

always @(posedge clk_12) begin
	reg [7:0] mod = 0;
	
	if (ioctl_wr & (ioctl_index==1)) mod <= ioctl_dout;
	mod_bwidow     <= ( mod == 0 );
	mod_gravitar   <= ( mod == 1 );
	mod_lunarbat   <= ( mod == 2 );
	mod_spacduel   <= ( mod == 3 );
end

// load the DIPS
reg [7:0] sw[8];
always @(posedge clk_12) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;


wire m_up     =  joy_0[3];
wire m_down   =  joy_0[2];
wire m_left   =  joy_0[1];
wire m_right  =  joy_0[0];

wire m_fire_up     = joy_0[6] | joy_1[3];
wire m_fire_down   = joy_0[7] | joy_1[2];
wire m_fire_left   = joy_0[5] | joy_1[1];
wire m_fire_right  = joy_0[4] | joy_1[0];

wire m_start1 = joy[8];
wire m_start2 = joy[9];
wire m_coin   = joy[10];
wire m_coin2   = 0;


//buttons(14 downto 0): SELFTEST, SA, COINAUX COINL COINR START2 START1 FD FU FL FR MU MD ML MR

//wire [14:0] BUTTONS = {status[7],1'b0,~(btn_coin_1|m_coin|btn_coin_2),1'b1,1'b1,~(btn_two_players|btn_start_2) ,~(btn_one_player|btn_start_1) & ~joy[7],m_down,m_up,m_left,m_right,m_up_2,m_down_2,m_left_2,m_right_2};
//wire [14:0] BUTTONS = {btn_test,~status[7],
//                       ~(btn_coin_1|m_coin),~btn_coin_2,1'b0,
//							  ~(btn_two_players|btn_start_2) ,~(btn_one_player|btn_start_1) ,
//							  ~m_fire_down,~m_fire_up,~m_fire_left,~m_fire_right,
//							  ~m_up,~m_down,~m_left,~m_right};

reg [7:0] input_0;
reg [7:0] input_1;
reg [7:0] input_2;
reg [7:0] input_3;
reg [7:0] input_4;
reg clk3k;

// Game specific sound board/DIP/input settings
always @(*) begin

	//orientation = 2'b00;
	input_0 = 8'hff;
	input_1 = sw[0];
	input_2 = sw[1];
	input_3 = 8'hff;
	input_4 = 8'hff;

	if (mod_bwidow) begin
		//input_0 = ~{ clk3k, 1'b1, sw[2][0], sw[2][1], 2'b0, m_coin, m_coin2 };
		input_0 = ~{ 1'b0, 1'b1, sw[2][0], sw[2][1], 2'b0, m_coin, m_coin2 };
		input_3 = ~{ 4'b0, m_up, m_down, m_left, m_right };
		input_4 = ~{ 1'b0, m_start2, m_start1, 1'b0, m_fire_up, m_fire_down, m_fire_left, m_fire_right };
	end
	else if (mod_gravitar) begin
		//input_0 = ~{ clk3k, 1'b1, sw[2][0], sw[2][1], 2'b0, m_coin, m_coin2 };
		input_0 = ~{ 1'b0, 1'b1, sw[2][0], sw[2][1], 2'b0, m_coin, m_coin2 };
		input_3 = ~{ 3'b0, m_fire_left, m_left, m_right, m_fire_right, m_fire_down };
		input_4 = ~{ 1'b0, m_start2, m_start1, 5'b0 };
	end
	else if (mod_lunarbat) begin
		input_0 = ~{ 1'b0, 1'b1, sw[2][0], sw[2][1], 2'b0, m_coin, m_coin2 };
		input_1 = 8'hff;
		input_2 = 8'hff;
		//input_3 = ~{ 1'b0, m_start2, m_start1, m_fire_left, m_fire_down, m_fire_right, m_right, m_left };
		input_3 = { 1'b0, m_start2, m_start1, m_fire_left, m_fire_down, m_fire_right, m_right, m_left };
		input_4 = 8'hff;
		
	end
	else if (mod_spacduel) begin
		//input_0 = ~{ service, 1'b0, m_tilt, m_fire_a, m_start2, m_start1, 1'b0, m_coin1 };
		//input_1 = ~{ 1'b0, spin_tron[7:1] };
		//input_2 = ~{ m_down, m_up, m_right, m_left, m_down, m_up, m_right, m_left };
		//input_3[7] = ~{ m_fire_a };
		//input_4 = ~{ 1'b0, spin_tron[7:1] };
	end
end

wire hblank, vblank;
wire hs, vs;
wire [3:0] r,g,b;


reg ce_pix;
always @(posedge clk_50) begin
       ce_pix <= !ce_pix;
end

arcade_video #(640,12) arcade_video
(
        .*,

        .clk_video(clk_50),

        .RGB_in({r,g,b}),
        .HBlank(hblank),
        .VBlank(vblank),
        .HSync(~hs),
        .VSync(~vs),

        .forced_scandoubler(0),
        .fx(0)
);

wire reset = (RESET | status[0] |  buttons[1] | rom_download);
wire [7:0] audio;
assign AUDIO_L = {audio, audio};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;
wire vgade;

BWIDOW_TOP BWIDOW_TOP
(

	//.BUTTON(BUTTONS),
	//.SELF_TEST_SWITCH_L(~status[7]), 
	
	.AUDIO_OUT(audio),
	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	//.dn_wr(ioctl_wr),
	//.dn_wr(ioctl_wr && !ioctl_index)	,
	.dn_wr(ioctl_wr & rom_download),
	
	.VIDEO_R_OUT(r),
	.VIDEO_G_OUT(g),
	.VIDEO_B_OUT(b),
	.HSYNC_OUT(hs),
	.VSYNC_OUT(vs),
	.VGA_DE(vgade),
	.VID_HBLANK(hblank),
	.VID_VBLANK(vblank),
	
	.input_0(input_0),
	//.input_1(input_1),
	//.input_2(input_2),
	.input_3(input_3),
	.input_4(input_4),

	//.SW_B4(sw_b4),
	//.SW_D4(sw_d4),
	
	.SW_B4(input_2),
	.SW_D4(input_1),

	.RESET_L (~reset),	
	.clk_6(clk_6),
	.clk_12(clk_12),
	.clk_25(clk_25),
	.clk_50(clk_50)
);

endmodule
