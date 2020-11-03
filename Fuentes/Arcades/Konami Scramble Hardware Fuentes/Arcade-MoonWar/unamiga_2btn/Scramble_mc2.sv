//============================================================================
//  Arcade: Moon War
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
//	Multicore 2 top by Victor Trucco
//
//============================================================================
//
//	unamiga top modified by delgrom 26/12/2019
//
//============================================================================

`default_nettype none

module Scramble_mc2
(

// Clocks
	input wire	clock_50_i,

	// Buttons
	input wire [4:1]	btn_n_i,

	// SRAMs (AS7C34096)
	// output wire	[18:0]sram_addr_o  = 18'b0000000000000000000,
	// inout wire	[7:0]sram_data_io	= 8'bzzzzzzzz,
	// output wire	sram_we_n_o		= 1'b1,
	// output wire	sram_oe_n_o		= 1'b1,
		
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
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS//,

		// HDMI
	// output wire	[7:0]tmds_o			= 8'b00000000,

	// STM32
	// input wire	stm_tx_i,
	// output wire	stm_rx_o,
	// output wire	stm_rst_o			= 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
		
	// inout wire	stm_b8_io, 
	// inout wire	stm_b9_io,

	// input         SPI_SCK,
	// output        SPI_DO,
	// input         SPI_DI,
	// input         SPI_SS2


);

//`include "rtl\build_id.v"

/* localparam CONF_STR = {
	"Moon War;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
}; */

assign AUDIO_R = AUDIO_L;

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
wire        scandoublerD = v_scandoublerD; // delgrom 1'b0 vga, 1'b1 15khz 
wire        ypbpr;
wire [10:0] ps2_key;
wire [9:0] audio;
wire hs, vs;
wire blankn = ~(hb | vb);
wire hb, vb;
wire [3:0] r,b,g;

scramble_top scramble(
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
   .O_HBLANK(hb),
   .O_VBLANK(vb),
	.O_AUDIO(audio),
	.ip_dip_switch({1'b1,2'b00,1'b0,1'b0}),//coin, coin, cabinet, Lives, Lives
	.ip_1p(~{btn_one_player, m_fire14, m_fire13, m_fire12, m_fire11, m_left1, m_right1}),
	.ip_2p(~{btn_two_players, m_fire14, m_fire13, m_fire12, m_fire11, m_left1, m_right1}),
   //.ip_2p(~{btn_two_players, m_fire24, m_fire23, m_fire22, m_fire21, m_left2, m_right2}),
   .ip_service(1'b1),
   .ip_coin1(~btn_coin),
   .ip_coin2(1'b1),
	// delgrom conecto el wire de reset
	//.RESET(~btn_n_i[4]),	
	.RESET(w_reset),
	.clk(clk_sys),
	.ena_12(ce_12),
	.ena_6(ce_6p),
	.ena_6b(ce_6n),
	.ena_1_79(ce_1p79)
	);

mist_video #(.COLOR_DEPTH(4),.SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys(clk_sys),
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? b : 0),
	.HSync(~hs),
	.VSync(~vs),
	.VGA_R(vga_r_s),
	.VGA_G(vga_g_s),
	.VGA_B(vga_b_s),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.rotate({1'b1,status[2]}),
	.ce_divider(1'b1),	
	.scandoubler_disable(scandoublerD),
	// delgrom scanlines
	//.scanlines(2'b00),
	.scanlines(scanlines_s),
	.ypbpr(ypbpr)
	);
	
	wire [5:0]vga_r_s;
	wire [5:0]vga_g_s;
	wire [5:0]vga_b_s;
	assign VGA_R = vga_r_s[5:1];
	assign VGA_G = vga_g_s[5:1];
	assign VGA_B = vga_b_s[5:1];

dac #(10)dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

wire m_left1   = joyBCPPFRLDU[2] | ~joy1_left_i;
wire m_right1  = joyBCPPFRLDU[3] | ~joy1_right_i;

wire m_fire11   = joyBCPPFRLDU[4] | ~joy1_p6_i;
wire m_fire12   = joyBCPPFRLDU[8] | ~joy1_p9_i;
wire m_fire13   = joyBCPPFRLDU[0] | ~joy1_up_i;
wire m_fire14   = joyBCPPFRLDU[1] | ~joy1_down_i;


wire btn_one_player 	=  joyBCPPFRLDU[5];
wire btn_two_players =  joyBCPPFRLDU[6];
wire btn_coin  		=  joyBCPPFRLDU[7];

//---------------------------------
	//-- scanlines
	
	wire btn_scan_s;
	wire changeScanlines; // delgrom
	wire [1:0] scanlines_s;
	
	debounce # ( .counter_size_g (10))
	btnscl
	(
		.clk_i		( clk_sys ),
		.button_i	( btn_n_i[1] | btn_n_i[2] ),
		.result_o	( btn_scan_s )
	);
 
 	//always @(negedge btn_scan_s) 
	always @(negedge changeScanlines) // delgrom	
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
  .joyBCPPFRLDU   ( joyBCPPFRLDU ),
  // delgrom
  .changeScandoubler    ( changeScandoubler),
  .changeScanlines    ( changeScanlines),
  .reset          (w_reset)    
);


// delgrom reset
wire w_reset;

// delgrom
wire changeScandoubler;
reg v_scandoublerD =1'b1;  // delgrom 1'b1 inicia a 15khz, 1'b0 inicia a  vga


// delgrom Cambiar entre 15khz y 31khz
always @(posedge changeScandoubler) 
begin
		v_scandoublerD <= ~v_scandoublerD;
end
	
	
//--- Joystick read with sega 6 button support----------------------
	
/*

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
*/
endmodule 