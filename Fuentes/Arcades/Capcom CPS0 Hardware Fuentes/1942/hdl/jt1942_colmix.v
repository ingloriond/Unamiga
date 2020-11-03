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
    Date: 20-1-2019 */

// 1942 Colour Mixer
// Schematics page 4

`timescale 1ns/1ps

module jt1942_colmix(
    input           rst,
    input           clk,    // 24 MHz
    input           cen6 /* synthesis direct_enable = 1 */,
    // Synchronization
    //input [2:0]       H,
    // pixel input from generator modules
    input [3:0]     char_pxl,        // character color code
    input [5:0]     scr_pxl,
    input [3:0]     obj_pxl,
    // Palette PROMs E8, E9, E10
    input   [7:0]   prog_addr,
    input           prom_e8_we,
    input           prom_e9_we,
    input           prom_e10_we,
    input   [3:0]   prom_din,

    input           LVBL,
    input           LHBL,
    output  reg     LHBL_dly,
    output  reg     LVBL_dly,

    output  [3:0]   red,
    output  [3:0]   green,
    output  [3:0]   blue,
    // Debug
    input      [3:0] gfx_en
);

parameter VULGUS=1'b0;

wire [7:0] dout_rg;
wire [3:0] dout_b;

reg [7:0] pixel_mux;

wire char_blank_b = |(~char_pxl);
wire obj_blank_b  = |(~obj_pxl);
//wire obj_blank_b  = 1'b0;
reg [7:0] prom_addr;

always @(*) begin
    if( !char_blank_b || !gfx_en[0] ) begin
        // Object or scroll
        if( !obj_blank_b || !gfx_en[3])
            pixel_mux[5:0] = gfx_en[2]?(VULGUS?{2'b0, scr_pxl[3:0]}:scr_pxl) : ~6'h0; // scroll wins
        else
            pixel_mux[5:0] = {1'b0, VULGUS, obj_pxl }; // object wins
    end
    else begin // characters
        pixel_mux[5:0] = { VULGUS, 1'b0, char_pxl };
    end
    pixel_mux[7:6] = VULGUS ? scr_pxl[5:4] : { char_blank_b, obj_blank_b };
end

wire [1:0] pre_BL;

jtgng_sh #(.width(2),.stages(5)) u_hb_dly(
    .clk    ( clk      ),
    .clk_en ( cen6     ),
    .din    ( {LHBL, LVBL}     ),
    .drop   ( pre_BL   )
);

always @(posedge clk) if(cen6) begin
    {LHBL_dly, LVBL_dly} <= pre_BL;
    prom_addr <= pre_BL==2'b11 ? pixel_mux : 8'd0;
end


// palette ROM
jtgng_prom #(.aw(8),.dw(4),.simfile("../../../rom/1942/sb-5.e8")) u_red(
    .clk    ( clk         ),
    .cen    ( cen6        ),
    .data   ( prom_din    ),
    .rd_addr( prom_addr   ),
    .wr_addr( prog_addr   ),
    .we     ( prom_e8_we  ),
    .q      ( red         )
);

jtgng_prom #(.aw(8),.dw(4),.simfile("../../../rom/1942/sb-6.e9")) u_green(
    .clk    ( clk         ),
    .cen    ( cen6        ),
    .data   ( prom_din    ),
    .rd_addr( prom_addr   ),
    .wr_addr( prog_addr   ),
    .we     ( prom_e9_we  ),
    .q      ( green       )
);

jtgng_prom #(.aw(8),.dw(4),.simfile("../../../rom/1942/sb-7.e10")) u_blue(
    .clk    ( clk         ),
    .cen    ( cen6        ),
    .data   ( prom_din    ),
    .rd_addr( prom_addr   ),
    .wr_addr( prog_addr   ),
    .we     ( prom_e10_we ),
    .q      ( blue        )
);

endmodule // jtgng_colmix