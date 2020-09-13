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
    Date: 22-2-2019 */

`timescale 1ns/1ps

// This is the MiST top level
// It will instantiate the appropriate game core according
// to the macro GAMETOP
// It will get the config string for the microcontroller
// from the include file conf_str.v

module `CORETOP(
    input           CLOCK_50,
    output  [5:0]   VGA_R,
    output  [5:0]   VGA_G,
    output  [5:0]   VGA_B,
    output          VGA_HS,
    output          VGA_VS,
    // SDRAM interface
    inout  [15:0]   SDRAM_DQ,       // SDRAM Data bus 16 Bits
    output [12:0]   SDRAM_A,        // SDRAM Address bus 13 Bits
    output          SDRAM_DQML,     // SDRAM Low-byte Data Mask
    output          SDRAM_DQMH,     // SDRAM High-byte Data Mask
    output          SDRAM_nWE,      // SDRAM Write Enable
    output          SDRAM_nCAS,     // SDRAM Column Address Strobe
    output          SDRAM_nRAS,     // SDRAM Row Address Strobe
    output          SDRAM_nCS,      // SDRAM Chip Select
    output [1:0]    SDRAM_BA,       // SDRAM Bank Address
    output          SDRAM_CLK,      // SDRAM Clock
    output          SDRAM_CKE,      // SDRAM Clock Enable
	// SPI interface to SD
	output wire         SD_CS_N,
	output wire         SD_CLK,
	output wire         SD_MOSI,
	input  wire         SD_MISO,
    // sound
    output          AUDIO_L,
    output          AUDIO_R,
    // user LED
    output          LED,
	 input wire		[1:0] BTN,	
   // keyboard
    input wire        PS2_CLK,
    input wire        PS2_DATA,
   // joystick
   input       [  5:0] JOYA,         // joystick port A
   input       [  5:0] JOYB          // joystick port B
);

localparam CLK_SPEED=48;

wire          rst, rst_n, clk_sys, clk_rom;
wire [31:0]   status, joystick1, joystick2;
wire [21:0]   sdram_addr;
wire [31:0]   data_read;
wire          loop_rst;
wire          downloading, dwnld_busy;
wire [21:0]   ioctl_addr;
wire [ 7:0]   ioctl_data;
wire          ioctl_wr;

wire rst_req   = status[0];
wire join_joys = status[32'he];

wire sdram_req;

wire [21:0]   prog_addr;
wire [ 7:0]   prog_data;
wire [ 1:0]   prog_mask;
wire          prog_we, prog_rd;

`ifndef COLORW
`define COLORW 4
`endif
localparam COLORW=`COLORW;

wire [COLORW-1:0] red;
wire [COLORW-1:0] green;
wire [COLORW-1:0] blue;

wire LHBL_dly, LVBL_dly, hs, vs;
wire [15:0] snd_left, snd_right;

`ifndef STEREO_GAME
assign snd_right = snd_left;
`endif

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
jtframe_pll0 u_pll_game (
    .inclk0 ( CLOCK_50 ),
    .c1     ( clk_rom     ), // 48 MHz
    .c2     ( SDRAM_CLK   ),
    .c3     ( clk_vga_in  ),
    .locked ( pll_locked  )
);

// assign SDRAM_CLK = clk_rom;
assign clk_sys   = clk_rom;

jtframe_pll1 u_pll_vga (
    .inclk0 ( clk_vga_in ),
    .c0     ( clk_vga    ) // 25
);

wire [7:0] dipsw_a, dipsw_b;
wire [1:0] dip_fxlevel;
wire       enable_fm, enable_psg;
wire       dip_pause, dip_flip, dip_test;
wire       pxl_cen, pxl2_cen;

`ifdef SIMULATION
assign sim_pxl_clk = clk_sys;
assign sim_pxl_cen = pxl_cen;
assign sim_vs = ~LVBL_dly;
assign sim_hs = ~LHBL_dly;
`endif

`ifndef SIGNED_SND
`define SIGNED_SND 1'b1
`endif

`ifndef THREE_BUTTONS
`define THREE_BUTTONS 1'b1
`endif

localparam CONF_STR="JTGNG;;";

jtframe_unamiga #( 
    .CONF_STR     ( CONF_STR       ),
    .SIGNED_SND   ( `SIGNED_SND    ),
    .THREE_BUTTONS( `THREE_BUTTONS ),
    .COLORW       ( COLORW         )
    `ifdef VIDEO_WIDTH
    ,.VIDEO_WIDTH   ( `VIDEO_WIDTH   )
    `endif
    `ifdef VIDEO_HEIGHT
    ,.VIDEO_HEIGHT  ( `VIDEO_HEIGHT  )
    `endif
)
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
    .pxl_cen        ( pxl_cen        ),
    .pxl2_cen       ( pxl2_cen       ),
     // MiST VGA pins
    .VGA_R          ( VGA_R          ),
    .VGA_G          ( VGA_G          ),
    .VGA_B          ( VGA_B          ),
    .VGA_HS         ( VGA_HS         ),
    .VGA_VS         ( VGA_VS         ),
    // SDRAM interface
    .SDRAM_CLK      ( SDRAM_CLK      ),
    .SDRAM_DQ       ( SDRAM_DQ       ),
    .SDRAM_A        ( SDRAM_A        ),
    .SDRAM_DQML     ( SDRAM_DQML     ),
    .SDRAM_DQMH     ( SDRAM_DQMH     ),
    .SDRAM_nWE      ( SDRAM_nWE      ),
    .SDRAM_nCAS     ( SDRAM_nCAS     ),
    .SDRAM_nRAS     ( SDRAM_nRAS     ),
    .SDRAM_nCS      ( SDRAM_nCS      ),
    .SDRAM_BA       ( SDRAM_BA       ),
    .SDRAM_CKE      ( SDRAM_CKE      ),
    // SPI interface to zpu io controller
    .SD_CS_N        ( SD_CS_N        ),
    .SD_CLK         ( SD_CLK         ),
    .SD_MOSI        ( SD_MOSI        ),
    .SD_MISO        ( SD_MISO        ),
    // ROM
    .ioctl_addr     ( ioctl_addr     ),
    .ioctl_data     ( ioctl_data     ),
    .ioctl_wr       ( ioctl_wr       ),
    .prog_addr      ( prog_addr      ),
    .prog_data      ( prog_data      ),
    .prog_mask      ( prog_mask      ),
    .prog_we        ( prog_we        ),
    .prog_rd        ( prog_rd        ),
    .downloading    ( downloading    ),
    .dwnld_busy     ( dwnld_busy     ),
    // ROM access from game
    .loop_rst       ( loop_rst       ),
    .sdram_addr     ( sdram_addr     ),
    .sdram_req      ( sdram_req      ),
    .sdram_ack      ( sdram_ack      ),
    .data_read      ( data_read      ),
    .data_rdy       ( data_rdy       ),
    .refresh_en     ( refresh_en     ),
//////////// board
    .rst            ( rst            ),
    .rst_n          ( rst_n          ), // unused
    .game_rst       ( game_rst       ),
    .game_rst_n     (                ),
    // reset forcing signals:
    .rst_req        ( rst_req        ),
    // Sound
    .snd_left       ( snd_left       ),
    .snd_right      ( snd_right      ),
    .AUDIO_L        ( AUDIO_L        ),
    .AUDIO_R        ( AUDIO_R        ),
    // joystick
    .game_joystick1 ( game_joy1      ),
    .game_joystick2 ( game_joy2      ),
    .game_coin      ( game_coin      ),
    .game_start     ( game_start     ),
    .game_service   (                ), // unused
    .LED            ( LED            ),
	.BTN            ( BTN            ),	
	 //Keyboard y Joy (Entradas)
    .PS2_CLK        ( PS2_CLK       ),
    .PS2_DATA       ( PS2_DATA      ),
	.JOYA           ( JOYA          ),
    .JOYB           ( JOYB          ),
    // DIP and OSD settings
    .enable_fm      ( enable_fm      ),
    .enable_psg     ( enable_psg     ),
    .dip_test       ( dip_test       ),
    .dip_pause      ( dip_pause      ),
    .dip_flip       ( dip_flip       ),
    .dip_fxlevel    ( dip_fxlevel    ),
    // Debug
    .gfx_en         ( gfx_en         ),
    // Unused
    .game_pause     (                ),
    .hdmi_arx       (                ),
    .hdmi_ary       (                ),
    .vertical_n     (                )	
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

wire sample;

`GAMETOP
u_game(
    .rst         ( game_rst       ),
    .clk         ( clk_sys        ),
    .pxl2_cen    ( pxl2_cen       ),
    .pxl_cen     ( pxl_cen        ),
    .red         ( red            ),
    .green       ( green          ),
    .blue        ( blue           ),
    .LHBL_dly    ( LHBL_dly       ),
    .LVBL_dly    ( LVBL_dly       ),
    .HS          ( hs             ),
    .VS          ( vs             ),

    .start_button( game_start     ),
    .coin_input  ( game_coin      ),
    .joystick1   ( game_joy1[6:0] ),
    .joystick2   ( game_joy2[6:0] ),

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
    .prog_rd     ( prog_rd        ),

    // ROM load
    .downloading ( downloading    ),
    .dwnld_busy  ( dwnld_busy     ),
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
    `ifndef STEREO_GAME
    .snd         ( snd_left       ),
    `else
    .snd_left    ( snd_left       ),
    .snd_right   ( snd_right      ),
    `endif
    .sample      ( sample         ),
    // Debug
    .gfx_en      ( gfx_en         )
);

`ifdef SIMULATION
integer fsnd;
initial begin
    fsnd=$fopen("sound.raw","wb");
end
always @(posedge sample) begin
    $fwrite(fsnd,"%u", {snd_left, snd_right});
end
`endif

endmodule