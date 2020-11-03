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
    Date: 19-2-2019 */

`timescale 1ns/1ps

module jt1943_video #( parameter
    // Characters
    CHAR_PAL       = "../../../rom/1943/bm5.7f",
    CHAR_IDMSB0    = 5,
    CHAR_VFLIPEN   = 0,
    CHAR_HFLIPEN   = 0,
    CHAR_VFLIP_XOR = 1'b0,
    CHAR_HFLIP_XOR = 1'b0,
    // Scroll
    SCRPLANES      = 2,    // 1 or 2
    SCR1_PALHI     = "../../../rom/1943/bm9.6l",
    SCR1_PALLO     = "../../../rom/1943/bm10.7l",
    SCR2_PALHI     = "../../../rom/1943/bm11.12l",
    SCR2_PALLO     = "../../../rom/1943/bm12.12m",
    // From colour mixer:
    BLANK_OFFSET   = 8,
    PALETTE_RED    = "../../../rom/1943/bm1.12a",
    PALETTE_GREEN  = "../../../rom/1943/bm2.13a",
    PALETTE_BLUE   = "../../../rom/1943/bm3.14a",
    PALETTE_PRIOR  = "../../../rom/1943/bm4.12c",
    // From objects
    OBJMAX         = 10'h1FF,
    OBJMAX_LINE    = 5'd31,
    OBJ_LAYOUT     = 1, // 1 for 1943, 2 for GunSmoke
    OBJ_ROM_AW     = 17,
    OBJ_PALHI      = "../../../rom/1943/bm7.7c",
    OBJ_PALLO      = "../../../rom/1943/bm8.8c"
) (
    input               rst,
    input               clk,
    input               cen12,
    input               cen6,
    input               cen3,
    input               cpu_cen,
    input       [10:0]  cpu_AB,
    input       [ 7:0]  V,
    input       [ 8:0]  H,
    input               rd_n,
    input               wr_n,
    input               flip,
    input       [ 7:0]  cpu_dout,
    input               pause,
    // CHAR
    input               char_cs,
    input               CHON,
    output      [ 7:0]  chram_dout,
    output      [13:0]  char_addr,
    input       [15:0]  char_data,
    input               char_ok,
    output              char_wait,
    // SCROLL - ROM
    input               SC1ON,
    input               SC2ON,
    input       [ 1:0]  scr1posh_cs,
    input       [ 1:0]  scr2posh_cs,
    input       [ 7:0]  scrposv,
    output      [16:0]  scr1_addr,
    output      [14:0]  scr2_addr,
    input       [15:0]  scr1_data,
    input       [15:0]  scr2_data,
    // MAP
    output      [13:0]  map1_addr,
    output      [13:0]  map2_addr,
    input       [15:0]  map1_data,
    input       [15:0]  map2_data,
    // OBJ
    input               OBJON,
    input               HINIT,
    output      [OBJ_ROM_AW-1:0]  obj_addr,
    input       [15:0]  objrom_data,
    // shared bus
    output      [12:0]  obj_AB,
    input        [7:0]  obj_DB,
    input               OKOUT,
    output              bus_req,   // Request bus
    input               bus_ack,   // bus acknowledge
    output              blcnten,   // bus line counter enable
    // Color Mix
    input               LVBL,
    input               LVBL_obj,
    input               LHBL,
    input               LHBL_obj,
    output              LHBL_dly,
    output              LVBL_dly,
    output      [3:0]   red,
    output      [3:0]   green,
    output      [3:0]   blue,
    // PROM access
    input       [7:0]   prog_addr,
    input       [3:0]   prog_din,
    // Char
    input               prom_char_we,
        // color mixer
    input               prom_red_we,
    input               prom_green_we,
    input               prom_blue_we,
    input               prom_prior_we,
        // scroll
    input               prom_scr1hi_we,
    input               prom_scr1lo_we,
    input               prom_scr2hi_we,
    input               prom_scr2lo_we,
        // obj
    input               prom_objhi_we,
    input               prom_objlo_we,
    // Debug
    input       [3:0]   gfx_en
);

localparam SCR_OFFSET=4;

wire [3:0] char_pxl;
wire [5:0] scr1_pxl, scr2_pxl;
wire [7:0] obj_pxl;

wire [3:0] avatar_idx;

`ifdef AVATARS
wire obj_pause=pause;
`else 
wire obj_pause=1'b0;
`endif

`ifndef NOCHAR
wire [7:0] char_msg_low;
wire [7:0] char_msg_high;
wire [9:0] char_scan;
wire [4:0] char_pal;
wire [1:0] char_col;

jtgng_char #(
    .HOFFSET   ( 0),
    .ROM_AW    (14),
    .IDMSB1    ( 7),
    .IDMSB0    ( CHAR_IDMSB0 ), // 5 for 1943, 6 for GunSmoke
    .PALW      ( 5),
    .VFLIP_EN  ( CHAR_VFLIPEN   ),
    .HFLIP_EN  ( CHAR_HFLIPEN   ),   // 1943 does not have character H/V flip
    .VFLIP_XOR ( CHAR_VFLIP_XOR ),
    .HFLIP_XOR ( CHAR_HFLIP_XOR ),
    .PALETTE   ( 1              ),
    .PALETTE_SIMFILE(CHAR_PAL   )
) u_char (
    .clk        ( clk           ),
    .pxl_cen    ( cen6          ),
    .cpu_cen    ( cpu_cen       ),
    .AB         ( cpu_AB[10:0]  ),
    .V          ( V             ),
    .H          ( H[7:0]        ),
    .flip       ( flip          ),
    .din        ( cpu_dout      ),
    .dout       ( chram_dout    ),
    // Bus arbitrion
    .char_cs    ( char_cs       ),
    .wr_n       ( wr_n          ),
    .busy       ( char_wait     ),
    // Pause screen
    .pause      ( pause         ),
    .scan       ( char_scan     ),
    .msg_low    ( char_msg_low  ),
    .msg_high   ( char_msg_high ),    
    // PROM access
    .prog_addr  ( prog_addr     ),
    .prog_din   ( prog_din      ),
    .prom_we    ( prom_char_we  ),
    // ROM
    .char_addr  ( char_addr     ),
    .rom_data   ( char_data     ),
    .rom_ok     ( char_ok       ),
    // Pixel output
    .char_on    ( CHON          ),
    .char_pxl   ( char_pxl      )
);

jtgng_charmsg u_msg(
    .clk         ( clk           ),
    .cen6        ( cen6          ),
    .avatar_idx  ( avatar_idx    ),
    .scan        ( char_scan     ),
    .msg_low     ( char_msg_low  ),
    .msg_high    ( char_msg_high ) 
);
`else
assign char_wait_n = 1'b1;
assign char_pxl = 4'hf;
`endif

`ifndef NOSCR
jt1943_scroll #(
    .HOFFSET    (SCR_OFFSET),
    .SIMFILE_MSB(SCR1_PALHI),
    .SIMFILE_LSB(SCR1_PALLO))
u_scroll1 (
    .rst          ( rst           ),
    .clk          ( clk           ),
    .cen6         ( cen6          ),
    .cen3         ( cen3          ),
    .V128         ( V[7:0]        ),
    .H            ( H             ),
    .LVBL         ( LVBL          ),
    .LHBL         ( LHBL          ),
    .scrposh_cs   ( scr1posh_cs   ),
    `ifndef TESTSCR1
    .SCxON        ( SC1ON         ),
    .vpos         ( scrposv       ),
    .flip         ( flip          ),
    `else // TEST:
        .SCxON        ( 1'b1          ),
        .vpos         ( 8'd0          ),
        .flip         ( 1'b0          ),
    `endif
    .din          ( cpu_dout       ),
    .wr_n         ( wr_n           ),
    .pause        ( pause          ),
    // Palette PROMs
    .prog_addr    ( prog_addr      ),
    .prom_hi_we   ( prom_scr1hi_we ),
    .prom_lo_we   ( prom_scr1lo_we ),
    .prom_din     ( prog_din       ),

    // ROM
    .map_addr     ( map1_addr      ),
    .map_data     ( map1_data      ),
    .scr_addr     ( scr1_addr      ),
    .scrom_data   ( scr1_data      ),
    .scr_pxl      ( scr1_pxl       )
);

generate
    if( SCRPLANES==2 ) begin
        wire [1:0] scr2_nc; // not connected bits of the address

        jt1943_scroll #(
            .HOFFSET    (SCR_OFFSET),
            .SIMFILE_MSB(SCR2_PALHI),
            .SIMFILE_LSB(SCR2_PALLO),
            .AS8MASK    (1'b0      )
        ) u_scroll2 (
            .rst          ( rst           ),
            .clk          ( clk           ),
            .cen6         ( cen6          ),
            .cen3         ( cen3          ),
            .V128         ( V[7:0]        ),
            .H            ( H             ),
            .LVBL         ( LVBL          ),
            .scrposh_cs   ( scr2posh_cs   ),
            `ifndef TESTSCR2
            .SCxON        ( SC2ON         ),
            .vpos         ( scrposv       ),
            .flip         ( flip          ),
            `else // TEST
                .SCxON        ( 1'b1          ),
                .vpos         ( 8'd0          ),
                .flip         ( 1'b0          ),
            `endif
            .din          ( cpu_dout       ),
            .wr_n         ( wr_n           ),

            .pause        ( pause          ),
            // Palette PROMs
            .prog_addr    ( prog_addr      ),
            .prom_hi_we   ( prom_scr2hi_we ),
            .prom_lo_we   ( prom_scr2lo_we ),
            .prom_din     ( prog_din       ),

            // ROM
            .map_addr     ( map2_addr     ),
            .map_data     ( map2_data     ),
            .scr_addr     ( { scr2_nc, scr2_addr} ),
            .scrom_data   ( scr2_data     ),
            .scr_pxl      ( scr2_pxl      )
        );
        end else begin
            assign scr2_pxl  = ~6'h0;
            assign scr2_addr = 15'h0;
            assign map2_addr = 14'h0;
        end
endgenerate
`else
assign scr1_pxl  = 6'h31;
assign scr1_addr = 17'h0;
assign map1_addr = 14'h0;

assign scr2_pxl  = ~6'h0;
assign scr2_addr = 17'h0;
assign map2_addr = 14'h0;
`endif

`ifndef NOOBJ
jtgng_obj #(
    .OBJMAX          ( OBJMAX      ),
    .OBJMAX_LINE     ( OBJMAX_LINE ),
    .PXL_DLY         ( 8           ),

    .ROM_AW          ( OBJ_ROM_AW  ),
    .LAYOUT          ( OBJ_LAYOUT  ),
    .PALW            (  4          ),
    .PALETTE         (  1          ),
    .PALETTE1_SIMFILE( OBJ_PALHI   ),
    .PALETTE0_SIMFILE( OBJ_PALLO   ),
    .AVATAR_MAX      ( 8           ))
u_obj(
    .rst            ( rst           ),
    .clk            ( clk           ),
    .cen6           ( cen6          ),
    // screen
    .HINIT          ( HINIT         ),
    .LHBL           ( LHBL_obj      ),
    .LVBL           ( LVBL          ),
    .LVBL_obj       ( LVBL_obj      ),
    .V              ( V             ),
    .H              ( H             ),
    .flip           ( flip          ),
    // Pause screen
    .pause          ( obj_pause     ),
    .avatar_idx     ( avatar_idx    ),
    // CPU bus
    .AB             ( {obj_AB[11:5], obj_AB[1:0]} ),
    .DB             ( obj_DB        ),
    // shared bus
    .OKOUT          ( OKOUT         ),
    .bus_req        ( bus_req       ),   // Request bus
    .bus_ack        ( bus_ack       ),   // bus acknowledge
    .blen           ( blcnten       ),   // bus line counter enable
    // SDRAM interface
    .obj_addr       ( obj_addr      ),
    .objrom_data    ( objrom_data   ),
    // PROMs
    .OBJON          ( OBJON         ),
    .prog_addr      ( prog_addr     ),
    .prom_hi_we     ( prom_objhi_we ),
    .prom_lo_we     ( prom_objlo_we ),
    .prog_din       ( prog_din      ),
    // pixel output
    .obj_pxl        ( obj_pxl       )
);
assign obj_AB[ 12] = 1'b1;
assign obj_AB[4:2] = 3'b0;
`else
assign prog_addr = 'd0;
assign obj_pxl   = ~'d0;
assign bus_req   = 'b0;
assign blcnten   = 'b0;
`endif

`ifndef NOCOLMIX
jt1943_colmix #(
    .SCRPLANES     ( SCRPLANES      ),
    .BLANK_OFFSET  ( BLANK_OFFSET   ),
    .PALETTE_RED   ( PALETTE_RED    ),
    .PALETTE_GREEN ( PALETTE_GREEN  ),
    .PALETTE_BLUE  ( PALETTE_BLUE   ),
    .PALETTE_PRIOR ( PALETTE_PRIOR  )) 
u_colmix (
    .rst        ( rst           ),
    .clk        ( clk           ),
    .cen12      ( cen12         ),
    .cen6       ( cen6          ),
    .LVBL       ( LVBL          ),
    .LHBL       ( LHBL          ),
    .LHBL_dly   ( LHBL_dly      ),
    .LVBL_dly   ( LVBL_dly      ),
    // Avatars
    .pause      ( obj_pause     ),
    .avatar_idx ( avatar_idx    ),
    // pixel input from generator modules
    .char_pxl   ( char_pxl      ),        // character color code
    .scr1_pxl   ( scr1_pxl      ),
    .scr2_pxl   ( scr2_pxl      ),
    .obj_pxl    ( obj_pxl       ),
    // Palette and priority PROMs
    .prog_addr    ( prog_addr     ),
    .prom_red_we  ( prom_red_we   ),
    .prom_green_we( prom_green_we ),
    .prom_blue_we ( prom_blue_we  ),
    .prom_prior_we( prom_prior_we ),
    .prom_din     ( prog_din      ),
    // output
    .red        ( red           ),
    .green      ( green         ),
    .blue       ( blue          ),
    // debug
    .gfx_en     ( gfx_en        )
);
`else
assign  red = 4'd0;
assign blue = 4'd0;
assign green= 4'd0;
`endif

endmodule // jtgng_video