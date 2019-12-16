//============================================================================
//  Arcade: Frogger
//
//  Port to MiSTer
//  Copyright (C) 2017 Sorgelig
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
//
//	Multicore  top by Victor Trucco
//
//============================================================================


`default_nettype none

module Frogger_mc
(

	// Clocks
	input wire	clock_50_i,

	// Buttons
	input wire [4:1]	btn_n_i,

	// SRAMs (AS7C34096)
	output wire	[18:0]sram_addr_o  = 18'b0000000000000000000,
	inout wire	[7:0]sram_data_io	= 8'bzzzzzzzz,
	output wire	sram_we_n_o		= 1'b1,
	output wire	sram_oe_n_o		= 1'b1,

	// PS2
	inout wire	ps2_clk_io			= 1'bz,
	inout wire	ps2_data_io			= 1'bz,
	inout wire	ps2_mouse_clk_io  = 1'bz,
	inout wire	ps2_mouse_data_io = 1'bz,

	// SD Card
	output wire	sd_cs_n_o			= 1'b1,
	output wire	sd_sclk_o			= 1'b0,
	output wire	sd_mosi_o			= 1'b0,
	input wire	sd_miso_i,

	// Joysticks
	input wire	joy1_up_i,
	input wire	joy1_down_i,
	input wire	joy1_left_i,
	input wire	joy1_right_i,
	input wire	joy1_p6_i,
	input wire	joy1_p9_i,
	input wire	joy2_up_i,
	input wire	joy2_down_i,
	input wire	joy2_left_i,
	input wire	joy2_right_i,
	input wire	joy2_p6_i,
	input wire	joy2_p9_i,
	output wire	joyX_p7_o			= 1'b1,

	// Audio
	output wire	dac_l_o				= 1'b0,
	output wire	dac_r_o				= 1'b0,
	input wire	ear_i,
	output wire	mic_o					= 1'b0,

		// VGA
	output wire	[2:0]vga_r_o,
	output wire	[2:0]vga_g_o,
	output wire	[2:0]vga_b_o,
	output wire	vga_hsync_n_o,
	output wire	vga_vsync_n_o 



);


assign dac_r_o = dac_l_o;

wire clk_sys;
wire pll_locked;
pll pll(
	.inclk0(clock_50_i),
	.areset(0),
	.c0(clk_sys),
	.locked(pll_locked)
	);

reg ce_6p, ce_6n, ce_12, ce_1p79;
always @(negedge clk_sys) begin
reg [1:0] div = 0;
reg [3:0] div179 = 0;
	div <= div + 1'd1;
	ce_12 <= div[0];
	ce_6p <= div[0] & ~div[1];
	ce_6n <= div[0] &  div[1];	
   ce_1p79 <= 0;
   div179 <= div179 - 1'd1;
   if(!div179) begin
		div179 <= 13;
		ce_1p79 <= 1;
   end
end

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [10:0] ps2_key;
wire  [9:0] audio;
wire 			hs, vs;
wire 			blankn = ~(hb | vb);
wire 			hb, vb;
wire  [3:0] r,b,g;

scramble_top scramble(
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
   .O_HBLANK(hb),
   .O_VBLANK(vb),
	.O_AUDIO(audio),
	.button_in(~{btn_two_players, m_fire, btn_coin, btn_one_player, m_right, m_left, m_down, m_up}),
	.RESET(~btn_n_i[4]),
	.clk(clk_sys),
	.ena_12(ce_12),
	.ena_6(ce_6p),
	.ena_6b(ce_6n),
	.ena_1_79(ce_1p79)
	);

mist_video #(.COLOR_DEPTH(4)) mist_video(
	.clk_sys(clk_sys),

	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? b : 0),
	.HSync(~hs),
	.VSync(~vs),
	.VGA_R(vga_r_s),
	.VGA_G(vga_g_s),
	.VGA_B(vga_b_s),
	.VGA_VS(vga_vsync_n_o),
	.VGA_HS(vga_hsync_n_o),
	.rotate({1'b1,status[2]}),
	.scandoubler_disable(scandoublerD),
	.scanlines(status[4:3]),
	.ypbpr(1'b0)
	);

	wire [5:0]vga_r_s;
	wire [5:0]vga_g_s;
	wire [5:0]vga_b_s;
	assign vga_r_o = vga_r_s[5:3];
	assign vga_g_o = vga_g_s[5:3];
	assign vga_b_o = vga_b_s[5:3];


dac dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(dac_l_o)
	);


wire m_up     = joyBCPPFRLDU[0] | ~joy1_up_i;
wire m_down   = joyBCPPFRLDU[1] | ~joy1_down_i;
wire m_left   = joyBCPPFRLDU[2] | ~joy1_left_i;
wire m_right  = joyBCPPFRLDU[3] | ~joy1_right_i;

wire m_fire   = joyBCPPFRLDU[4] | ~joy1_p6_i;
wire m_bomb   = joyBCPPFRLDU[8] | ~joy1_p9_i;

wire btn_one_player 	=  joyBCPPFRLDU[5] | ~btn_n_i[1];
wire btn_two_players =  joyBCPPFRLDU[6] | ~btn_n_i[2];
wire btn_coin  		=  joyBCPPFRLDU[7] | ~btn_n_i[3];

//---------------------------------
	//-- scanlines
	
	wire btn_scan_s;
	wire [1:0] scanlines_s;
	
	debounce # ( .counter_size_g (10))
	btnscl
	(
		.clk_i		( clk_sys ),
		.button_i	( btn_n_i[1] | btn_n_i[2] ),
		.result_o	( btn_scan_s )
	);
 
 	always @(negedge btn_scan_s) 
	begin
			scanlines_s = scanlines_s + 1'b1;
	end
	
	//---------------------------------
	//-- PS/2 Keyboard
	
	wire kbd_intr;
wire [12:0] joyBCPPFRLDU;
wire [7:0] kbd_scancode;

//get scancode from keyboard
io_ps2_keyboard keyboard 
 (
  .clk       ( clk_sys ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

//translate scancode to joystick
kbd_joystick k_joystick
(
  .clk         	(  clk_sys ),
  .kbdint      	(  kbd_intr ),
  .kbdscancode 	(  kbd_scancode ), 
  .joyBCPPFRLDU   ( joyBCPPFRLDU )
);





endmodule
