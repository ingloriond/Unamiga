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

`default_nettype none

module Centipede_mc2
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
		
	// SDRAM	(H57V256)
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQMH,
	output        SDRAM_DQML,
	output        SDRAM_CKE,
	output        SDRAM_nCS,
	output        SDRAM_nWE,
	output        SDRAM_nRAS,
	output        SDRAM_nCAS,
	output        SDRAM_CLK,

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
	output        AUDIO_L,
	output        AUDIO_R,
	input wire	ear_i,
	output wire	mic_o					= 1'b0,

		// VGA
	output  [4:0] VGA_R,
	output  [4:0] VGA_G,
	output  [4:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

		// HDMI
	output wire	[7:0]tmds_o			= 8'b00000000,

		//STM32
	input wire	stm_tx_i,
	output wire	stm_rx_o,
	output wire	stm_rst_o			= 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
		
	inout wire	stm_b8_io, 
	inout wire	stm_b9_io,

	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2
);

assign	stm_rst_o = 1'bz;


localparam CONF_STR = {
	"Centipede;;",
	"O1,Test,Off,On;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"T7,Reset;",
	"V,v1.40."
};

assign stm_rst_o = 0;
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
wire        scandoublerD;
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
 	.reset(~btn_n_i[4]),
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
	.SPI_SCK(SPI_SCK),
	//.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
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
	.scandoubler_disable(scandoublerD),
	.scanlines(status[4:3]),
	.ypbpr(ypbpr)
	);
/*
user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_24         ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);
	*/
dac #(
	.C_bits(15))
dac (
	.clk_i(clk_24),
	.res_n_i(1),
	.dac_i({2{2'b0,audio,audio}}),
	.dac_o(AUDIO_L)
	);

wire m_up     =  joy1_s[0] & ~joyBCPPFRLDU[0];
wire m_down   =  joy1_s[1] & ~joyBCPPFRLDU[1]; 
wire m_left   =  joy1_s[2] & ~joyBCPPFRLDU[2]; 
wire m_right  =  joy1_s[3] & ~joyBCPPFRLDU[3];

wire m_start1 = ~btn_one_player;
wire m_start2 = 1'b1;
wire m_fire1  = joy1_s[4] & ~joyBCPPFRLDU[4];
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



wire btn_coin   		 = ~btn_n_i[3] | joyBCPPFRLDU[7];
wire btn_one_player   = ~btn_n_i[1] | joyBCPPFRLDU[5];
wire btn_two_players  = ~btn_n_i[2] | joyBCPPFRLDU[6];


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
  .joyBCPPFRLDU   ( joyBCPPFRLDU )
);


//--- Joystick read with sega 6 button support----------------------
	


	reg [11:0]joy1_s; 	
	reg [11:0]joy2_s; 
	reg joyP7_s;

	reg [7:0]state_v = 8'd0;
	reg j1_sixbutton_v = 1'b0;
	reg j2_sixbutton_v = 1'b0;
	
	always @(negedge hs) 
	begin
		

			state_v <= state_v + 1;

			
			case (state_v)			//-- joy_s format MXYZ SACB RLDU
				8'd0:  
					joyP7_s <=  1'b0;
					
				8'd1:
					joyP7_s <=  1'b1;

				8'd2:
					begin
						joy1_s[3:0] <= {joy1_right_i, joy1_left_i, joy1_down_i, joy1_up_i}; //-- R, L, D, U
						joy2_s[3:0] <= {joy2_right_i, joy2_left_i, joy2_down_i, joy2_up_i}; //-- R, L, D, U
						joy1_s[5:4] <= {joy1_p9_i, joy1_p6_i}; //-- C, B
						joy2_s[5:4] <= {joy2_p9_i, joy2_p6_i}; //-- C, B					
						joyP7_s <= 1'b0;
						j1_sixbutton_v <= 1'b0; //-- Assume it's not a six-button controller
						j2_sixbutton_v <= 1'b0; //-- Assume it's not a six-button controller
					end
					
				8'd3:
					begin
						if (joy1_right_i == 1'b0 && joy1_left_i == 1'b0) // it's a megadrive controller
								joy1_s[7:6] <= { joy1_p9_i , joy1_p6_i }; //-- Start, A
						else
								joy1_s[7:4] <= { 1'b1, 1'b1, joy1_p9_i, joy1_p6_i }; //-- read A/B as master System
							
						if (joy2_right_i == 1'b0 && joy2_left_i == 1'b0) // it's a megadrive controller
								joy2_s[7:6] <= { joy2_p9_i , joy2_p6_i }; //-- Start, A
						else
								joy2_s[7:4] <= { 1'b1, 1'b1, joy2_p9_i, joy2_p6_i }; //-- read A/B as master System

							
						joyP7_s <= 1'b1;
					end
					
				8'd4:  
					joyP7_s <= 1'b0;

				8'd5:
					begin
						if (joy1_right_i == 1'b0 && joy1_left_i == 1'b0 && joy1_down_i == 1'b0 && joy1_up_i == 1'b0 )
							j1_sixbutton_v <= 1'b1; // --it's a six button
						
						
						if (joy2_right_i == 1'b0 && joy2_left_i == 1'b0 && joy2_down_i == 1'b0 && joy2_up_i == 1'b0 )
							j2_sixbutton_v <= 1'b1; // --it's a six button
						
						
						joyP7_s <= 1'b1;
					end
					
				8'd6:
					begin
						if (j1_sixbutton_v == 1'b1)
							joy1_s[11:8] <= { joy1_right_i, joy1_left_i, joy1_down_i, joy1_up_i }; //-- Mode, X, Y e Z
						
						
						if (j2_sixbutton_v == 1'b1)
							joy2_s[11:8] <= { joy2_right_i, joy2_left_i, joy2_down_i, joy2_up_i }; //-- Mode, X, Y e Z
						
						
						joyP7_s <= 1'b0;
					end 
					
				default:
					joyP7_s <= 1'b1;
					
			endcase

	end
	
	assign joyX_p7_o = joyP7_s;
	//---------------------------

	

endmodule
