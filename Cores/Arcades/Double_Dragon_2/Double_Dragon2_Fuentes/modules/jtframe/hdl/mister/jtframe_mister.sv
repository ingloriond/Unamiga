/*  This file is part of JTFRAME.
    JTFRAME program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTFRAME program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTFRAME.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 7-3-2019 */

`timescale 1ns/1ps

module jtframe_mister #(parameter
    BUTTONS                 = 2,
    GAME_INPUTS_ACTIVE_LOW  =1'b1,
    CONF_STR                = "",
    COLORW                  = 4,
    VIDEO_WIDTH             = 384,
    VIDEO_HEIGHT            = 224
)(
    input           clk_sys,
    input           clk_rom,
    input           clk_vga,
    input           pll_locked,
    // interface with microcontroller
    output [31:0]   status,
    inout  [45:0]   HPS_BUS,
    output [ 1:0]   buttons,
    // Base video
    input [COLORW-1:0] game_r,
    input [COLORW-1:0] game_g,
    input [COLORW-1:0] game_b,
    input           LHBL,
    input           LVBL,
    input           hs,
    input           vs,
    input           pxl_cen,
    input           pxl2_cen,
    // SDRAM interface
    inout  [15:0]   SDRAM_DQ,       // SDRAM Data bus 16 Bits
    output [12:0]   SDRAM_A,        // SDRAM Address bus 13 Bits
    output          SDRAM_DQML,     // SDRAM Low-byte Data Mask
    output          SDRAM_DQMH,     // SDRAM High-byte Data Mask
    output          SDRAM_nWE,      // SDRAM Write Enable
    output          SDRAM_nCAS,     // SDRAM Column Address Strobe
    output          SDRAM_nRAS,     // SDRAM Row Address Strobe
    output          SDRAM_nCS,      // SDRAM Chip Select
    output [ 1:0]   SDRAM_BA,       // SDRAM Bank Address
    input           SDRAM_CLK,      // SDRAM Clock
    output          SDRAM_CKE,      // SDRAM Clock Enable
    // ROM load
    output [22:0]   ioctl_addr,
    output [ 7:0]   ioctl_data,
    output          ioctl_rom_wr,
    input  [21:0]   prog_addr,
    input  [ 7:0]   prog_data,
    input  [ 1:0]   prog_mask,
    input           prog_we,
    input           prog_rd,
    output          downloading,
    input           dwnld_busy,
    // ROM access from game
    input           sdram_req,
    output          sdram_ack,
    input  [21:0]   sdram_addr,
    output [31:0]   data_read,
    output          data_rdy,
    output          loop_rst,
    input           refresh_en,
    // Write back to SDRAM
    input  [ 1:0]   sdram_wrmask,
    input           sdram_rnw,
    input  [15:0]   data_write,
//////////// board
    output          rst,      // synchronous reset
    output          rst_n,    // asynchronous reset
    output          game_rst,
    output          game_rst_n,
    // reset forcing signals:
    input           rst_req,
    // joystick
    output  [ 9:0]  game_joystick1,
    output  [ 9:0]  game_joystick2,
    output  [ 9:0]  game_joystick3,
    output  [ 9:0]  game_joystick4,
    output  [ 3:0]  game_coin,
    output  [ 3:0]  game_start,
    output          game_service,
    // DIP and OSD settings
    output  [ 7:0]  hdmi_arx,
    output  [ 7:0]  hdmi_ary,
    output  [ 1:0]  rotate,

    output          enable_fm,
    output          enable_psg,

    output          dip_test,
    // scan doubler
    output reg [7:0]  scan2x_r,
    output reg [7:0]  scan2x_g,
    output reg [7:0]  scan2x_b,
    output reg        scan2x_hs,
    output reg        scan2x_vs,
    output reg        scan2x_clk,
    output reg        scan2x_cen,
    output reg        scan2x_de,
    // HDMI outputs
    output            hdmi_cen,
    output    [ 7:0]  hdmi_r,
    output    [ 7:0]  hdmi_g,
    output    [ 7:0]  hdmi_b,
    output            hdmi_hs,
    output            hdmi_vs,
    output            hdmi_clk,
    output            hdmi_de,   // = ~(VBlank | HBlank)
    output    [ 1:0]  hdmi_sl,   // scanlines fx   
    // non standard:
    output            dip_pause,
    output            dip_flip,     // A change in dip_flip implies a reset
    output    [ 1:0]  dip_fxlevel,
    output    [31:0]  dipsw,
    //DB15 
    output            JOY_CLK,
    output            JOY_LOAD,
    input             JOY_DATA,
    output            USER_OSD,
    // Debug
    output            LED,
    output   [3:0]    gfx_en
);

wire [15:0] joydb15_1,joydb15_2;

assign LED  = downloading | dwnld_busy;
assign USER_OSD = joydb15_1[10] & joydb15_1[6];

// control
joy_db15 joy_db15
(
  .clk       ( clk_sys   ), //48MHz
  .JOY_CLK   ( JOY_CLK   ),
  .JOY_DATA  ( JOY_DATA  ),
  .JOY_LOAD  ( JOY_LOAD  ),
  .joystick1 ( joydb15_1 ),
  .joystick2 ( joydb15_2 )    
);

wire [15:0]   joystick_USB_1, joystick_USB_2, joystick_USB_3, joystick_USB_4;
wire [15:0]   joystick1 = |status[31:30] ? {BUTTONS<6 ? joydb15_1[9] : 1'b0,joydb15_1[11],joydb15_1[10],joydb15_1[3+BUTTONS:0]} : joystick_USB_1;
wire [15:0]   joystick2 =  status[31]    ? {BUTTONS<6 ? joydb15_2[9] : 1'b0,joydb15_2[11],joydb15_2[10],joydb15_2[3+BUTTONS:0]} : status[30] ? joystick_USB_1 : joystick_USB_2;
wire [15:0]   joystick3 =  status[31]    ? joystick_USB_1 : status[30] ? joystick_USB_2 : joystick_USB_3;
wire [15:0]   joystick4 =  status[31]    ? joystick_USB_2 : status[30] ? joystick_USB_3 : joystick_USB_4;
wire          ps2_kbd_clk, ps2_kbd_data;
wire [2:0]    hpsio_nc; // top 3 bits of ioctl_addr are ignored
wire          force_scan2x, direct_video;

wire [7:0]    pre_scan2x_r;
wire [7:0]    pre_scan2x_g;
wire [7:0]    pre_scan2x_b;
wire          pre_scan2x_hs;
wire          pre_scan2x_vs;
wire          pre_scan2x_clk;
wire          pre_scan2x_cen;
wire          pre_scan2x_de;

// This slows down synthesis on MiSTer a lot
// if pre_scan signals come from a 25MHz clock domain
always @(*) begin
    if( force_scan2x ) begin
        scan2x_r    = pre_scan2x_r;
        scan2x_g    = pre_scan2x_g;
        scan2x_b    = pre_scan2x_b;
        scan2x_hs   = pre_scan2x_hs;
        scan2x_vs   = pre_scan2x_vs;
        scan2x_clk  = pre_scan2x_clk;
        scan2x_cen  = pre_scan2x_cen;
        scan2x_de   = pre_scan2x_de;
    end else begin
        scan2x_r    = {2{game_r}}>>(COLORW*2-8);
        scan2x_g    = {2{game_g}}>>(COLORW*2-8);
        scan2x_b    = {2{game_b}}>>(COLORW*2-8);
        scan2x_hs   = hs;
        scan2x_vs   = vs;
        scan2x_clk  = clk_sys;
        scan2x_cen  = pxl_cen;
        scan2x_de   = LVBL & LHBL; 
    end
end

wire [21:0] gamma_bus;

wire [ 7:0] ioctl_index;
wire        ioctl_wr;

`ifndef JTFRAME_MRA_DIP
// DIP switches through regular OSD options
assign ioctl_rom_wr = ioctl_wr;
assign dipsw        = status;
`else
// Dip switches through MRA file
// Support for 32 bits only for now.
reg  [ 7:0] dsw[4];
assign dipsw        = {dsw[3],dsw[2],dsw[1],dsw[0]};
assign ioctl_rom_wr = (ioctl_wr && ioctl_index==8'd0);

always @(posedge clk_sys) begin
    if (ioctl_wr && (ioctl_index==8'd254) && !ioctl_addr[21:2]) dsw[ioctl_addr[1:0]] <= ioctl_data;
end
`endif

hps_io #(.STRLEN($size(CONF_STR)/8),.PS2DIV(32)) u_hps_io
(
    .clk_sys         ( clk_sys        ),
    .HPS_BUS         ( HPS_BUS        ),
    .conf_str        ( CONF_STR       ),

    .buttons         ( buttons        ),
    .status          ( status         ),
    .status_menumask ( direct_video   ),
    .gamma_bus       ( gamma_bus      ),
    .direct_video    ( direct_video   ),
    .forced_scandoubler(force_scan2x  ),

    .ioctl_download  ( downloading    ),
    .ioctl_wr        ( ioctl_wr       ),
    .ioctl_addr      ( ioctl_addr     ),
    .ioctl_dout      ( ioctl_data     ),
    .ioctl_index     ( ioctl_index    ),

    .joy_raw         ( joydb15_1[5:0] ),   
    .joystick_0      ( joystick_USB_1 ),
    .joystick_1      ( joystick_USB_2 ),
    .joystick_2      ( joystick_USB_3 ),
    .joystick_3      ( joystick_USB_4 ),
    .ps2_kbd_clk_out ( ps2_kbd_clk    ),
    .ps2_kbd_data_out( ps2_kbd_data   )
    //.ps2_key       ( ps2_key       )
);

jtframe_board #(
    .BUTTONS               ( BUTTONS              ),
    .GAME_INPUTS_ACTIVE_LOW(GAME_INPUTS_ACTIVE_LOW),
    .COLORW                ( COLORW               ),
    .VIDEO_WIDTH           ( VIDEO_WIDTH          ),
    .VIDEO_HEIGHT          ( VIDEO_HEIGHT         )
) u_board(
    .rst            ( rst             ),
    .rst_n          ( rst_n           ),
    .game_rst       ( game_rst        ),
    .game_rst_n     ( game_rst_n      ),
    .rst_req        ( rst_req         ),
    .downloading    ( dwnld_busy      ),

    .clk_sys        ( clk_sys         ),
    .clk_rom        ( clk_rom         ),
    .clk_vga        ( clk_vga         ),
    // joystick
    .ps2_kbd_clk    ( ps2_kbd_clk     ),
    .ps2_kbd_data   ( ps2_kbd_data    ),
    .board_joystick1( joystick1       ),
    .board_joystick2( joystick2       ),
    .board_joystick3( joystick3       ),
    .board_joystick4( joystick4       ),    
    .game_joystick1 ( game_joystick1  ),
    .game_joystick2 ( game_joystick2  ),
    .game_joystick3 ( game_joystick3  ),
    .game_joystick4 ( game_joystick4  ),
    .game_coin      ( game_coin       ),
    .game_start     ( game_start      ),
    .game_service   ( game_service    ),
    // DIP and OSD settings
    .status         ( status          ),
    .enable_fm      ( enable_fm       ),
    .enable_psg     ( enable_psg      ),
    .dip_test       ( dip_test        ),
    .dip_pause      ( dip_pause       ),
    .dip_flip       ( dip_flip        ),
    .dip_fxlevel    ( dip_fxlevel     ),
    // screen
    .gamma_bus      ( gamma_bus       ),
    .direct_video   ( direct_video    ),
    .hdmi_r         ( hdmi_r          ),
    .hdmi_g         ( hdmi_g          ),
    .hdmi_b         ( hdmi_b          ),
    .hdmi_hs        ( hdmi_hs         ),
    .hdmi_vs        ( hdmi_vs         ),
    .hdmi_clk       ( hdmi_clk        ),
    .hdmi_cen       ( hdmi_cen        ),
    .hdmi_de        ( hdmi_de         ),
    .hdmi_sl        ( hdmi_sl         ),
    .hdmi_arx       ( hdmi_arx        ),
    .hdmi_ary       ( hdmi_ary        ),
    .rotate         ( rotate          ),
    // Scan doubler output
    .scan2x_r       ( pre_scan2x_r    ),
    .scan2x_g       ( pre_scan2x_g    ),
    .scan2x_b       ( pre_scan2x_b    ),
    .scan2x_hs      ( pre_scan2x_hs   ),
    .scan2x_vs      ( pre_scan2x_vs   ),
    .scan2x_clk     ( pre_scan2x_clk  ),
    .scan2x_cen     ( pre_scan2x_cen  ),
    .scan2x_de      ( pre_scan2x_de   ),
    .scan2x_enb     ( ~force_scan2x   ),
    // SDRAM interface
    .SDRAM_DQ       ( SDRAM_DQ        ),
    .SDRAM_A        ( SDRAM_A         ),
    .SDRAM_DQML     ( SDRAM_DQML      ),
    .SDRAM_DQMH     ( SDRAM_DQMH      ),
    .SDRAM_nWE      ( SDRAM_nWE       ),
    .SDRAM_nCAS     ( SDRAM_nCAS      ),
    .SDRAM_nRAS     ( SDRAM_nRAS      ),
    .SDRAM_nCS      ( SDRAM_nCS       ),
    .SDRAM_BA       ( SDRAM_BA        ),
    .SDRAM_CKE      ( SDRAM_CKE       ),
    // SDRAM controller
    .loop_rst       ( loop_rst        ),
    .sdram_addr     ( sdram_addr      ),
    .sdram_req      ( sdram_req       ),
    .sdram_ack      ( sdram_ack       ),
    .data_read      ( data_read       ),
    .data_rdy       ( data_rdy        ),
    .refresh_en     ( refresh_en      ),
    .prog_addr      ( prog_addr       ),
    .prog_data      ( prog_data       ),
    .prog_mask      ( prog_mask       ),
    .prog_we        ( prog_we         ),
    .prog_rd        ( prog_rd         ),
    // write back support
    .sdram_wrmask   ( sdram_wrmask    ),
    .sdram_rnw      ( sdram_rnw       ),
    .data_write     ( data_write      ),
    // Base video
    .osd_rotate     ( rotate          ),
    .game_r         ( game_r          ),
    .game_g         ( game_g          ),
    .game_b         ( game_b          ),
    .LHBL           ( LHBL            ),
    .LVBL           ( LVBL            ),
    .hs             ( hs              ),
    .vs             ( vs              ), 
    .pxl_cen        ( pxl_cen         ),
    .pxl2_cen       ( pxl2_cen        ),
    // Debug
    .gfx_en         ( gfx_en          )
);

endmodule
