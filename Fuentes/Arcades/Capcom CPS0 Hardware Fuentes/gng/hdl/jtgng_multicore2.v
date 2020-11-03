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
    Date: 27-10-2017 
	
	 Multicore 2 top by Victor Trucco - 2019
*/

`default_nettype none

module jtgng_mc2
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
);

assign stm_rst_o = 1'bz;
assign sram_oe_n_o = 1'b0;
assign sram_addr_o = sdram_addr[18:0];
assign sram_we_n_o = 

parameter CLK_SPEED=12;//48;
/*
localparam CONF_STR = {
    //   000000000111111111122222222223
    //   123456789012345678901234567890
        "JTGNG;;", // 7
        "O1,Pause,OFF,ON;", // 16
        "F,rom;", // 6
        "O23,Difficulty,easy,normal,hard,very hard;", // 42
        "O4,Test mode,OFF,ON;", // 20
        "O7,PSG ,ON,OFF;", // 15
        "O8,FM  ,ON,OFF;", // 15
        "O9A,Lives,3,4,5,6;", // 18
        "OB,Screen filter,ON,OFF;", // 24
        "TF,Reset;", // 9
        "V,http://patreon.com/topapate;" // 30
};
localparam CONF_STR_LEN = 7+16+6+42+20+15+15+18+24+9+30;
*/


localparam CONF_STR = { "P,gng.dat" };
localparam CONF_STR_LEN = 9;


wire          rst, clk_rgb, clk_vga, clk_rom;
wire          cen12, cen6, cen3, cen1p5;
wire [31:0]   status, joystick1, joystick2;
wire          ps2_kbd_clk, ps2_kbd_data;
wire [ 5:0]   board_r, board_g, board_b;
wire          board_hsync, board_vsync, hs, vs;
wire [21:0]   sdram_addr;
wire [15:0]   data_read;
wire          loop_rst, autorefresh, H0;
wire          downloading;
wire [21:0]   ioctl_addr;
wire [ 7:0]   ioctl_data;
wire          coin_cnt = 1'b0; // To do: check if GnG provided this output

wire          game_pause;
wire          rst_req   = !btn_n_i[1]; //status[32'hf];
wire [1:0]    dip_level = ~status[3:2];
wire [1:0]    dip_lives = ~status[10:9];
wire [1:0]    dip_bonus = 2'b11;
wire          dip_pause = 1'b1; //!(status[1] | game_pause); // DIPs are active low
wire          dip_test  = 1'b1; //~status[4];
wire          enable_psg= 1'b1; //~status[7]
wire			  enable_fm = 1'b1; //~status[8];


wire LHBL, LVBL;
wire signed [15:0] snd;

wire [5:0] game_joystick1, game_joystick2;
wire [1:0] game_coin, game_start;
wire game_rst;

//assign LED = ~downloading | coin_cnt | rst;

reg  [21:0]   prog_addr;
reg  [ 7:0]   prog_data;
reg  [ 1:0]   prog_mask;
reg           prog_we = 1'b0;
wire          ioctl_wr;

wire  [ 4:0]   vga_r_s;
wire  [ 4:0]   vga_g_s;
wire  [ 4:0]   vga_b_s;

assign vga_r_o = vga_r_s;
assign vga_g_o = vga_g_s;
assign vga_b_o = vga_b_s;

always @(posedge clk_rom) begin
    if ( ioctl_wr ) begin
        prog_addr <= { 1'b0, ioctl_addr[21:1] };
        prog_data <= ioctl_data;
        prog_mask <= { ioctl_addr[0], ~ioctl_addr[0] };
        prog_we   <= 1'b1;
    end
    else prog_we <= 1'b0;
end

wire [3:0] red, green, blue;
wire sdram_req, sdram_sync;

jtframe_mc2 #( .CONF_STR(CONF_STR), .CONF_STR_LEN(CONF_STR_LEN),
    .CLK_SPEED(CLK_SPEED),
    .SIGNED_SND(1'b1), .THREE_BUTTONS(1'b0))
u_frame(
    .CLOCK_27       ( clock_50_i     ),
    .clk_rgb        ( clk_rgb        ), //output
    .clk_rom        ( clk_rom        ), //output
    .cen12          ( cen12          ), //input
    .pxl_cen        ( cen6           ), //input
    .status         ( status         ),
    // Base video
    .osd_rotate     ( 2'b0           ),
    .game_r         ( red            ),
    .game_g         ( green          ),
    .game_b         ( blue           ),
    .LHBL           ( LHBL           ),
    .LVBL           ( LVBL           ),
    .hs             ( hs             ),
    .vs             ( vs             ),
	 
    // VGA
    .en_mixing      ( ~status['hb]   ),
    .VGA_R          ( vga_r_s        ),
    .VGA_G          ( vga_g_s        ),
    .VGA_B          ( vga_b_s        ),
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
	 
	  //SRAM interface
	 .SRAM_DATA		  ( sram_data_io	 ),
	 
    // SPI interface to arm io controller
    .SPI_DO         ( stm_b14_io     ),
    .SPI_DI         ( stm_b15_io     ),
    .SPI_SCK        ( stm_b13_io     ),
    .SPI_SS2        (                ),
    .SPI_SS3        ( stm_b12_io     ),
    .SPI_SS4        (                ),
    .CONF_DATA0     (                ),

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
    .loop_rst       ( loop_rst       ), //output
    .sdram_addr     ( sdram_addr     ), //input
    .sdram_sync     ( sdram_sync     ),
    .sdram_req      ( sdram_req      ),
    .data_read      ( data_read      ), //output
	 
//////////// board
    .rst            ( rst            ), //output
    .game_rst       ( game_rst       ), //output
	 
    // reset forcing signals:
    .dip_flip       ( 1'b0           ),
    .rst_req        ( rst_req        ),
	 
    // Sound
    .snd            ( snd            ),
    .AUDIO_L        ( dac_l_o	       ),
    .AUDIO_R        ( dac_r_o 	    ),
	 
    // joystick
    .game_joystick1 ( game_joystick1 ), //output
    .game_joystick2 ( game_joystick2 ), //output
    .game_coin      ( game_coin      ), //output
    .game_start     ( game_start     ), //output
    .game_pause     ( game_pause     ) //output
);

jtgng_game #(.CLK_SPEED(CLK_SPEED)) game(
    .rst         ( game_rst      ), //input
    .clk         ( clk_rgb       ), //input
	 .cen12       ( cen12         ), //output
    .cen6        ( cen6          ), //output
    .cen3        ( cen3          ), //output
    .cen1p5      ( cen1p5        ), //output
    .red         ( red           ),
    .green       ( green         ),
    .blue        ( blue          ),
    .LHBL        ( LHBL          ),
    .LVBL        ( LVBL          ),
    .HS          ( hs            ),
    .VS          ( vs            ),

    .start_button( game_start     ),
    .coin_input  ( game_coin      ),
    .joystick1   ( game_joystick1 ),
    .joystick2   ( game_joystick2 ),

    // ROM interface
    .downloading ( downloading   ),
    .loop_rst    ( loop_rst      ), //input
    .sdram_sync  ( sdram_sync    ),
    .sdram_req   ( sdram_req     ),
    .sdram_addr  ( sdram_addr    ), //output
    .data_read   ( data_read     ), //input
	 
    // DEBUG
    .enable_char ( 1'b1          ),
    .enable_scr  ( 1'b1          ),
    .enable_obj  ( 1'b1          ),
	 
    // DIP switches
    .dip_pause      ( dip_pause  ),
    .dip_lives      ( dip_lives  ),
    .dip_level      ( dip_level  ),
    .dip_bonus      ( dip_bonus  ),
    .dip_game_mode  ( dip_test   ),
    .dip_upright    ( 1'b1       ),
    .dip_attract_snd( 1'b1       ), // 0 for sound
	 
    // sound
    .enable_psg  ( enable_psg    ),
    .enable_fm   ( enable_fm     ),
    .ym_snd      ( snd           ),
    .sample      (               )
);

endmodule // jtgng_mist