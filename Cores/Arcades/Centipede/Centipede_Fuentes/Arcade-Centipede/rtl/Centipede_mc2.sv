//============================================================================
//  Arcade: Centipede
//
//  Port to MiST
//  Copyright (C) 2018 Gehstock
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
//============================================================================
//
// Multicore 2 top by Victor Trucco
//
//============================================================================
//
//  04/11/2019 UnAmiga delgrom
//
//============================================================================

`default_nettype none

module Centipede_mc2
(
   // Clocks
	input wire	clock_50_i,

	// Buttons
	input wire [4:1]	btn_n_i,

	// PS2
	inout wire	ps2_clk_io			= 1'bz,
	inout wire	ps2_data_io			= 1'bz,
	inout wire	ps2_mouse_clk_io  = 1'bz,
	inout wire	ps2_mouse_data_io = 1'bz,

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
	output        AUDIO_L,
	output        AUDIO_R,
	input wire	ear_i,
	output wire	mic_o					= 1'b0,

		// VGA
	output  [4:0] VGA_R,
	output  [4:0] VGA_G,
	output  [4:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS
);

localparam CONF_STR = {
	"Centipede;;",
	"O1,Test,Off,On;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"T7,Reset;",
	"V,v1.40."
};


assign AUDIO_R = AUDIO_L;

wire clk_24, clk_12, clk_100mhz;
wire pll_locked;
pll pll(
	.inclk0(clock_50_i),
	.areset(0),
	.c0(clk_24),
	.c2(clk_12),
	.c4(clk_100mhz)
	);
	
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0, joystick_1;
wire        scandoublerD = v_scandoublerD; // delgrom 1'b0 vga, 1'b1 15khz 
wire        ypbpr;
wire [10:0] ps2_key;
wire  [6:0] audio1, audio2;
wire	[7:0] RGB;
wire 			vb, hb;
wire 			blankn = ~(hb | vb);
wire 			hs, vs;
wire  [3:0] audio;

centipede centipede(
	.clk_100mhz(clk_100mhz),
	.clk_12mhz(clk_12),
 	//.reset(~btn_n_i[4]),
	// delgrom conecto el wire de reset
 	.reset(w_reset),	
	.playerinput_i({ r_coin, c_coin, l_coin, m_test, m_cocktail, m_slam, m_start2, m_start1, m_fire2, m_fire1 }),
	.trakball_i(),
	.joystick_i({m_right , m_left, m_down, m_up, m_right , m_left, m_down, m_up}),
	.sw1_i("01010100"),
	.sw2_i("00000000"),
	.rgb_o(RGB),
	.hsync_o(hs),
	.vsync_o(vs),
	.hblank_o(hb),
	.vblank_o(vb),
	.audio_o(audio)
	);
	
wire [5:0] vga_r_s;
wire [5:0] vga_g_s;
wire [5:0] vga_b_s;

assign VGA_R = vga_r_s[5:1];
assign VGA_G = vga_g_s[5:1];
assign VGA_B = vga_b_s[5:1];

mist_video #(.COLOR_DEPTH(3)) mist_video(
	.clk_sys(clk_24),
	//.SPI_SCK(SPI_SCK),
	//.SPI_SS3(SPI_SS3),
	//.SPI_DI(SPI_DI),
	.R(blankn ? RGB[2:0] : 0),
	.G(blankn ? RGB[5:3] : 0),
	.B(blankn ? RGB[7:6] : 0),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(vga_r_s),
	.VGA_G(vga_g_s),
	.VGA_B(vga_b_s),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.rotate({1'b0,status[2]}),//(left/right,on/off)
	// delgrom scandoubler, scanlines
	//.scandoubler_disable(scandoublerD),
	//.scanlines(status[4:3]),
	.scandoubler_disable(v_scandoublerD),
	.scanlines(scandoublerD ? 2'b00 :  v_scanlines),
	.ypbpr(ypbpr)
	);

dac #(
	.C_bits(15))
dac (
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i({2{2'b0,audio,audio}}),
	.dac_o(AUDIO_L)
	);


wire m_up     =  joy1_up_i & ~joyBCPPFRLDU[0];
wire m_down   =  joy1_down_i & ~joyBCPPFRLDU[1]; 
wire m_left   =  joy1_left_i & ~joyBCPPFRLDU[2]; 
wire m_right  =  joy1_right_i & ~joyBCPPFRLDU[3];

wire m_start1 = ~btn_one_player;
wire m_start2 = 1'b1;
wire m_fire1  = joy1_p6_i & ~joyBCPPFRLDU[4];
wire m_fire2  = 1'b1;
wire c_coin   = ~btn_coin;
wire l_coin, r_coin = 1'b1;
wire m_test = ~status[1];
wire m_slam = 1'b1;//generate Noise
wire m_cocktail = 1'b1;


reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
reg btn_fire3 = 0;



wire btn_coin   		 = joyBCPPFRLDU[7];
wire btn_one_player   = joyBCPPFRLDU[5];
wire btn_two_players  = joyBCPPFRLDU[6];


wire kbd_intr;
wire [8:0] joyBCPPFRLDU;
wire [7:0] kbd_scancode;

//get scancode from keyboard
io_ps2_keyboard keyboard 
 (
  .clk       ( clk_24 ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

//translate scancode to joystick
kbd_joystick k_joystick
(
  .clk         	(  clk_24 ),
  .kbdint      	(  kbd_intr ),
  .kbdscancode 	(  kbd_scancode ), 
  .joyBCPPFRLDU   ( joyBCPPFRLDU ),
  // delgrom Teclas scandbl, scanlines, reset
  .changeScandoubler    ( changeScandoubler),
  .changeScanlines    ( changeScanlines),
  .reset          (w_reset) 
);

// delgrom Cambiar entre 15khz y 31khz
wire changeScandoubler;
reg v_scandoublerD =1'b0;  // delgrom 1'b1 inicia a 15khz, 1'b0 inicia a  vga

always @(posedge changeScandoubler) 
begin
		v_scandoublerD <= ~v_scandoublerD;
end

// delgrom scanlines rotatorias (off, 25%, 50%, 75%)
wire changeScanlines;
reg [1:0] v_scanlines =  2'b00;

always @(posedge changeScanlines) 
begin
		v_scanlines <= v_scanlines + 1'b1;
end

// delgrom reset
wire w_reset;

endmodule
