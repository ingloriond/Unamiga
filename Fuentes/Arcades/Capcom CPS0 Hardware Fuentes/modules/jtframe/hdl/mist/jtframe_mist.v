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
    Date: 7-3-2019 */

`timescale 1ns/1ps

module jtframe_mist(
    input   [1:0]   CLOCK_27,
    output          clk_rgb,
    output          clk_rom,
    input           cen12,
    input           pxl_cen,
    // interface with microcontroller
    output  [31:0]  status,
    // Base video
    input   [1:0]   osd_rotate,
    input   [3:0]   game_r,
    input   [3:0]   game_g,
    input   [3:0]   game_b,
    input           LHBL,
    input           LVBL,
    input           hs,
    input           vs,
    // VGA
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
    // SPI interface to arm io controller
    output          SPI_DO,
    input           SPI_DI,
    input           SPI_SCK,
    input           SPI_SS2,
    input           SPI_SS3,
    input           SPI_SS4,
    input           CONF_DATA0,
    // ROM
    output [21:0]   ioctl_addr,
    output [ 7:0]   ioctl_data,
    output          ioctl_wr,
    input  [21:0]   prog_addr,
    input  [ 7:0]   prog_data,
    input  [ 1:0]   prog_mask,
    input           prog_we,
    output          downloading,
    // ROM access from game
    input           sdram_sync,
    input           sdram_req,
    input  [21:0]   sdram_addr,
    output [31:0]   data_read,
    output          loop_rst,
    input           autorefresh,
//////////// board
    output            rst,      // synchronous reset
    output            rst_n,    // asynchronous reset
    output            game_rst,
    // reset forcing signals:
    input             dip_flip, // A change in dip_flip implies a reset
    input             rst_req,
    // Sound
    input   [15:0]    snd,
    output            AUDIO_L,
    output            AUDIO_R,
    // VGA
    input             en_mixing,
    // joystick
    output     [9:0]  game_joystick1,
    output     [9:0]  game_joystick2,
    output     [1:0]  game_coin,
    output     [1:0]  game_start,
    output            game_pause,
    output            game_service,
    // Debug
    output     [3:0]  gfx_en
);

parameter SIGNED_SND=1'b0;
parameter THREE_BUTTONS=1'b0;
parameter GAME_INPUTS_ACTIVE_HIGH=1'b0;
parameter CONF_STR = "";
parameter CONF_STR_LEN = 0;
parameter CLK_SPEED = 12;

wire locked, clk_vga;

wire   [5:0]   board_r, board_g, board_b;
wire           board_hsync, board_vsync;

// control
wire [31:0]   joystick1, joystick2;
wire          ps2_kbd_clk, ps2_kbd_data;

assign AUDIO_R = AUDIO_L;

jtgng_mist_base #(.CONF_STR(CONF_STR), .CONF_STR_LEN(CONF_STR_LEN),
    .CLK_SPEED( CLK_SPEED )
) u_base(
    .rst            ( rst           ),
    .locked         ( locked        ),
    .clk_rgb        ( clk_rgb       ),
    .clk_vga        ( clk_vga       ),
    .clk_rom        ( clk_rom       ),
    .SDRAM_CLK      ( SDRAM_CLK     ),
    .cen12          ( cen12         ),
    .sdram_sync     ( sdram_sync    ),
    .sdram_req      ( sdram_req     ),
    // Base video
    .osd_rotate     ( osd_rotate    ),
    .game_r         ( game_r        ),
    .game_g         ( game_g        ),
    .game_b         ( game_b        ),
    .board_r        ( board_r       ),
    .board_g        ( board_g       ),
    .board_b        ( board_b       ),
    .board_hsync    ( board_hsync   ),
    .board_vsync    ( board_vsync   ),
    .hs             ( hs            ),
    .vs             ( vs            ),
    // VGA
    .CLOCK_27       ( CLOCK_27      ),
    .VGA_R          ( VGA_R         ),
    .VGA_G          ( VGA_G         ),
    .VGA_B          ( VGA_B         ),
    .VGA_HS         ( VGA_HS        ),
    .VGA_VS         ( VGA_VS        ),
    // SDRAM interface
    .SDRAM_DQ       ( SDRAM_DQ      ),
    .SDRAM_A        ( SDRAM_A       ),
    .SDRAM_DQML     ( SDRAM_DQML    ),
    .SDRAM_DQMH     ( SDRAM_DQMH    ),
    .SDRAM_nWE      ( SDRAM_nWE     ),
    .SDRAM_nCAS     ( SDRAM_nCAS    ),
    .SDRAM_nRAS     ( SDRAM_nRAS    ),
    .SDRAM_nCS      ( SDRAM_nCS     ),
    .SDRAM_BA       ( SDRAM_BA      ),
    .SDRAM_CKE      ( SDRAM_CKE     ),
    // SPI interface to arm io controller
    .SPI_DO         ( SPI_DO        ),
    .SPI_DI         ( SPI_DI        ),
    .SPI_SCK        ( SPI_SCK       ),
    .SPI_SS2        ( SPI_SS2       ),
    .SPI_SS3        ( SPI_SS3       ),
    .SPI_SS4        ( SPI_SS4       ),
    .CONF_DATA0     ( CONF_DATA0    ),
    // control
    .status         ( status        ),
    .joystick1      ( joystick1     ),
    .joystick2      ( joystick2     ),
    .ps2_kbd_clk    ( ps2_kbd_clk   ),
    .ps2_kbd_data   ( ps2_kbd_data  ),
    // ROM
    .ioctl_addr     ( ioctl_addr    ),
    .ioctl_data     ( ioctl_data    ),
    .ioctl_wr       ( ioctl_wr      ),
    .prog_addr      ( prog_addr     ),
    .prog_data      ( prog_data     ),
    .prog_mask      ( prog_mask     ),
    .prog_we        ( prog_we       ),
    .downloading    ( downloading   ),
    .loop_rst       ( loop_rst      ),
    .sdram_addr     ( sdram_addr    ),
    .data_read      ( data_read     )
);

jtgng_board #(.SIGNED_SND(SIGNED_SND),.THREE_BUTTONS(THREE_BUTTONS),
    .GAME_INPUTS_ACTIVE_HIGH(GAME_INPUTS_ACTIVE_HIGH)
) u_board(
    .rst            ( rst             ),
    .rst_n          ( rst_n           ),
    .game_rst       ( game_rst        ),
    .dip_flip       ( dip_flip        ),
    .rst_req        ( rst_req         ),
    .downloading    ( downloading     ),
    .loop_rst       ( loop_rst        ),

    .clk_rgb        ( clk_rgb         ),
    .clk_dac        ( clk_rgb         ),
    // audio
    .snd            ( snd             ),
    .snd_pwm        ( AUDIO_L         ),
    // VGA
    .pxl_cen        ( pxl_cen         ),
    .clk_vga        ( clk_vga         ),
    .en_mixing      ( en_mixing       ),
    .game_r         ( game_r          ),
    .game_g         ( game_g          ),
    .game_b         ( game_b          ),
    .LHBL           ( LHBL            ),
    .LVBL           ( LVBL            ),
    .vga_r          ( board_r         ),
    .vga_g          ( board_g         ),
    .vga_b          ( board_b         ),
    .vga_hsync      ( board_hsync     ),
    .vga_vsync      ( board_vsync     ),
    // joystick
    .ps2_kbd_clk    ( ps2_kbd_clk     ),
    .ps2_kbd_data   ( ps2_kbd_data    ),
    .board_joystick1( joystick1[9:0]  ),
    .board_joystick2( joystick2[9:0]  ),
`ifndef SIM_INPUTS
    .game_joystick1 ( game_joystick1  ),
    .game_joystick2 ( game_joystick2  ),
    .game_coin      ( game_coin       ),
    .game_start     ( game_start      ),
`endif
    .game_pause     ( game_pause      ),
    .game_service   ( game_service    ),
    // Debug
    .gfx_en         ( gfx_en          )
);

endmodule // jtframe