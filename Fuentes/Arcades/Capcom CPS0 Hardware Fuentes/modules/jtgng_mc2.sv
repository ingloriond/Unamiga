/*  This file is part of JT_GNG.
    JT_GNG program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT_GNG program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT_GNG.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 22-2-2019 
	 
	 
	 Multicore 2 top by Victor Trucco
	 
	 */

`timescale 1ns/1ps

`default_nettype none

// This is the top level
// It will instantiate the appropriate game core according
// to the macro inside the QSF file
// the config string for the microcontroller is inside the same QSF

module `MC2TOP(

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
	output wire	[12:0]sdram_ad_o,
	inout wire	[15:0]sdram_da_io,
	output wire	[1:0]sdram_ba_o,
	output wire	[1:0]sdram_dqm_o,
	output wire	sdram_ras_o,
	output wire	sdram_cas_o,
	output wire	sdram_cke_o,
	output wire	sdram_clk_o,
	output wire	sdram_cs_o,
	output wire	sdram_we_o,

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
	output wire	[4:0]vga_r_o,
	output wire	[4:0]vga_g_o,
	output wire	[4:0]vga_b_o,
	output wire	vga_hsync_n_o,
	output wire	vga_vsync_n_o,

		// HDMI
	output wire	[7:0]tmds_o			= 8'b00000000,

		//STM32
	input wire	stm_tx_i,
	output wire	stm_rx_o,
	output wire	stm_rst_o			= 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
		
	inout wire	stm_b8_io,
	inout wire	stm_b9_io,
	inout wire	stm_b12_io,
	inout wire	stm_b13_io,
	inout wire	stm_b14_io,
	inout wire	stm_b15_io
	
    `ifdef SIMULATION
    ,output         sim_pxl_cen,
    output          sim_pxl_clk,
    output          sim_vs,
    output          sim_hs
    `endif
);

assign stm_rst_o = 1'bz;

localparam CLK_SPEED=48;



localparam CONF_STR = { `ROMDAT };
localparam CONF_STR_LEN = `ROMLEN;



wire          rst, rst_n, clk_sys, clk_rom;
wire          cen12, cen6, cen3, cen1p5;
wire [31:0]   status, joystick1, joystick2;
wire [21:0]   sdram_addr;
wire [31:0]   data_read;
wire          loop_rst;
wire          downloading;
wire [21:0]   ioctl_addr;
wire [ 7:0]   ioctl_data;
wire          ioctl_wr;

wire rst_req = ~btn_n_i[4];

wire sdram_req;

wire [21:0]   prog_addr;
wire [ 7:0]   prog_data;
wire [ 1:0]   prog_mask;
wire          prog_we;

wire [3:0] red;
wire [3:0] green;
wire [3:0] blue;

wire LHBL, LHBL_dly, LVBL, LVBL_dly, hs, vs;
wire [15:0] snd;

wire [9:0] game_joy1, game_joy2;
wire [1:0] game_coin, game_start;
wire game_rst;
wire [3:0] gfx_en;
// SDRAM
wire data_rdy, sdram_ack;
wire refresh_en;


// PLL's
// 24 MHz or 12 MHz base clock
wire clk_vga_in, clk_vga, pll_locked;
jtgng_pll0 u_pll_game (
    .inclk0 ( clock_50_i ),
    .c1     ( clk_rom     ), // 48 MHz
    .c2     ( sdram_clk_o   ),
   // .c3     ( clk_vga_in  ),
	 .c3     ( clk_vga    ), // 25
    .locked ( pll_locked  )
);

// assign SDRAM_CLK = clk_rom;
assign clk_sys   = clk_rom;

//jtgng_pll1 u_pll_vga (
//    .inclk0 ( clk_vga_in ),
//    .c0     ( clk_vga    ) // 25
//);

wire [7:0] dipsw_a, dipsw_b;
wire [1:0] dip_fxlevel;
wire       enable_fm, enable_psg;
wire       dip_pause, dip_flip, dip_test;

`ifdef SIMULATION
assign sim_pxl_clk = clk_sys;
assign sim_pxl_cen = cen6;
assign sim_vs = ~LVBL_dly;
assign sim_hs = ~LHBL_dly;
`endif


jtframe_mc2 #( .CONF_STR(CONF_STR),.CONF_STR_LEN(CONF_STR_LEN),
    .SIGNED_SND(1'b1), .THREE_BUTTONS(1'b1))
u_frame(
    .clk_sys        ( clk_sys        ),
    .clk_rom        ( clk_rom        ),
    .clk_vga        ( clk_vga        ),
    .pll_locked     ( pll_locked     ),
    .status         ( status         ),
    // Base video
    .game_r         ( red            ),
    .game_g         ( green          ),
    .game_b         ( blue           ),
    .LHBL           ( LHBL_dly       ),
    .LVBL           ( LVBL_dly       ),
    .hs             ( hs             ),
    .vs             ( vs             ),
    .pxl_cen        ( cen6           ),
    .pxl2_cen       ( cen12          ),
    // MiST VGA pins
    .VGA_R          ( vga_r_o        ),
    .VGA_G          ( vga_g_o        ),
    .VGA_B          ( vga_b_o        ),
    .VGA_HS         ( vga_hsync_n_o  ),
    .VGA_VS         ( vga_vsync_n_o  ),
	 
    // SDRAM interface
    .SDRAM_CLK      ( sdram_clk_o    ),
    .SDRAM_DQ       ( sdram_da_io    ),
    .SDRAM_A        ( sdram_ad_o     ),
    .SDRAM_DQML     ( sdram_dqm_o[0] ),
    .SDRAM_DQMH     ( sdram_dqm_o[1] ),
    .SDRAM_nWE      ( sdram_we_o     ),
    .SDRAM_nCAS     ( sdram_cas_o    ),
    .SDRAM_nRAS     ( sdram_ras_o    ),
    .SDRAM_nCS      ( sdram_cs_o     ),
    .SDRAM_BA       ( sdram_ba_o     ),
    .SDRAM_CKE      ( sdram_cke_o    ),
	
    // SPI interface to arm io controller
    .SPI_DO         ( stm_b14_io      ),
    .SPI_DI         ( stm_b15_io      ),
    .SPI_SCK        ( stm_b13_io      ),
    .SPI_SS2        ( stm_b12_io      ),
	 
    // ROM
    .ioctl_addr     ( ioctl_addr     ),
    .ioctl_data     ( ioctl_data     ),
    .ioctl_wr       ( ioctl_wr       ),
    .prog_addr      ( prog_addr      ),
    .prog_data      ( prog_data      ),
    .prog_mask      ( prog_mask      ),
    .prog_we        ( prog_we        ),
    .downloading    ( downloading    ),
	 
    // ROM access from game
    .loop_rst       ( loop_rst       ),
    .sdram_addr     ( sdram_addr     ),
    .sdram_req      ( sdram_req      ),
    .sdram_ack      ( sdram_ack      ),
    .data_read      ( data_read      ),
    .data_rdy       ( data_rdy       ),
    .refresh_en     ( refresh_en     ),
	 
//////////// board
    .rst            ( rst            ), //outputs
    .rst_n          ( rst_n          ), // unused
    .game_rst       ( game_rst       ),
    .game_rst_n     (                ),
    // reset forcing signals:
    .rst_req        ( rst_req        ),
    // Sound
    .snd            ( snd            ),
    .AUDIO_L        ( dac_l_o        ),
    .AUDIO_R        ( dac_r_o        ),
	 
    // joystick (output to game)
    .game_joystick1 ( game_joy1      ), // output
    .game_joystick2 ( game_joy2      ), // output
    .game_coin      ( game_coin      ), // output
    .game_start     ( game_start     ), // output
    .game_service   (                ), // unused
    .LED            (                ),
	 
    // DIP and OSD settings
    .enable_fm      ( enable_fm      ),
    .enable_psg     ( enable_psg     ),
    .dip_test       ( dip_test       ),
    .dip_pause      ( dip_pause      ),
    .dip_flip       ( dip_flip       ),
    .dip_fxlevel    ( dip_fxlevel    ),
	 
    // Debug
    .gfx_en         ( gfx_en         ),
	 
	 //keyboard
	 .ps2_kbd_clk	  ( ps2_clk_io     ),
    .ps2_kbd_data	  ( ps2_data_io    ),
	 
	 //joysticks (connected to the FPGA)
	// .fpga_joystick1 ( ~{ 1'b1, 1'b1, 1'b1, 1'b1,  1'b1, 1'b1, btn_n_i[3], btn_n_i[2], btn_n_i[1], 1'b1, joy1_p9_i, joy1_p6_i, joy1_up_i, joy1_down_i, joy1_left_i, joy1_right_i })	 
	
	//-- joy_s format MXYZ SACB RLDU
	 .fpga_joystick1 ( ~{ 1'b1, 1'b1, 1'b1, 1'b1,  1'b1, 1'b1, btn_n_i[3], btn_n_i[2], btn_n_i[1] && joy1_s[7], joy1_s[6], joy1_s[5], joy1_s[4], joy1_s[0], joy1_s[1], joy1_s[2], joy1_s[3] })	 
);

	


`ifdef SIMULATION
`ifdef TESTINPUTS
    test_inputs u_test_inputs(
        .loop_rst       ( loop_rst       ),
        .LVBL           ( LVBL           ),
        .game_joystick1 ( game_joy1[6:0] ),
        .button_1p      ( game_start[0]  ),
        .coin_left      ( game_coin[0]   )
    );
    assign game_start[1] = 1'b1;
    assign game_coin[1]  = 1'b1;
    assign game_joystick2 = ~10'd0;
    assign game_joystick1[9:7] = 3'b111;
    assign sim_vs = vs;
    assign sim_hs = hs;
`endif
`endif

`GAMETOP #(.CLK_SPEED(CLK_SPEED))
u_game(
    .rst         ( game_rst       ),
    .clk         ( clk_sys        ),
    .cen12       ( cen12          ),
    .cen6        ( cen6           ),
    .cen3        ( cen3           ),
    .cen1p5      ( cen1p5         ),
    .red         ( red            ),
    .green       ( green          ),
    .blue        ( blue           ),
    .LHBL        ( LHBL           ),
    .LVBL        ( LVBL           ),
    .LHBL_dly    ( LHBL_dly       ),
    .LVBL_dly    ( LVBL_dly       ),
    .HS          ( hs             ),
    .VS          ( vs             ),

    .start_button( game_start     ), // input
    .coin_input  ( game_coin      ), // input
    .joystick1   ( game_joy1[6:0] ), // inputs
    .joystick2   ( game_joy2[6:0] ), // inputs

    // Sound control
    .enable_fm   ( enable_fm      ),
    .enable_psg  ( enable_psg     ),
	 
    // PROM programming
    .ioctl_addr  ( ioctl_addr     ),
    .ioctl_data  ( ioctl_data     ),
    .ioctl_wr    ( ioctl_wr       ),
    .prog_addr   ( prog_addr      ),
    .prog_data   ( prog_data      ),
    .prog_mask   ( prog_mask      ),
    .prog_we     ( prog_we        ),

    // ROM load
    .downloading ( downloading    ),
    .loop_rst    ( loop_rst       ),
    .sdram_req   ( sdram_req      ),
    .sdram_addr  ( sdram_addr     ),
    .data_read   ( data_read      ),
    .sdram_ack   ( sdram_ack      ),
    .data_rdy    ( data_rdy       ),
    .refresh_en  ( refresh_en     ),

    // DIP switches
    .status      ( status         ),
    .dip_pause   ( dip_pause      ),
    .dip_flip    ( dip_flip       ),
    .dip_test    ( dip_test       ),
    .dip_fxlevel ( dip_fxlevel    ),  

    // sound
    .snd         ( snd            ),
    .sample      (                ),
    // Debug
    .gfx_en      ( gfx_en         )
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