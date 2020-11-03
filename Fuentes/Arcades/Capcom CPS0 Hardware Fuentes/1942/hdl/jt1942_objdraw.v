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
    Date: 21-1-2019 */

`timescale 1ns/1ps

module jt1942_objdraw(
    input              rst,
    input              clk,     //
    input              cen6,    //  6 MHz
    // screen
    input              flip,
    input       [7:0]  V,
    input       [8:0]  H,
    input       [3:0]  pxlcnt,
    // per-line sprite data
    input       [7:0]  objbuf_data0,
    input       [7:0]  objbuf_data1,
    input       [7:0]  objbuf_data2,
    input       [7:0]  objbuf_data3,
    // SDRAM interface
    output      [14:0] obj_addr,
    input       [15:0] objrom_data,
    // Palette PROM
    input   [7:0]      prog_addr,
    input              prom_pal_we,
    input   [3:0]      prog_din,
    // pixel data
    output reg  [8:0]  posx,
    output reg  [3:0]  new_pxl
);

reg [3:0] CD; // colour data
reg [7:0] V2C;
wire [7:0] VF = {8{flip}} ^V;
reg VINZONE;

reg [1:0] vlen;
reg VINcmp, VINlen, Veq, Vlt; // Vgt;

// signal aliases
wire [7:0] next_AD    = objbuf_data0;
wire [1:0] next_vlen  = objbuf_data1[7:6];
wire       next_ADext = objbuf_data1[5];
wire       next_hover = objbuf_data1[4];
wire [3:0] next_CD    = objbuf_data1[3:0];
wire [7:0] next_y     = objbuf_data2;
wire [7:0] next_x     = objbuf_data3;

wire [7:0] LVBETA = next_y + V2C;
wire [7:0] VBETA = ~LVBETA;

always @(*) begin
    // comparison side of VINZONE
    // Vgt = VBETA  > ~next_y;
    Veq = VBETA == ~next_y;
    Vlt = VBETA  < ~next_y;
    VINcmp = /*ADext ? Vgt :*/ (Veq|Vlt);
    case( next_vlen )
        2'b00: VINlen = &LVBETA[7:4]; // 16 lines
        2'b01: VINlen = &LVBETA[7:5]; // 32 lines
        2'b10: VINlen = &LVBETA[7:6]; // 64 lines
        2'b11: VINlen = 1'b1;
    endcase // vlen
    //VINZONE = ~(VINcmp & VINlen);
    VINZONE = ~(VINcmp & VINlen);
end

reg [14:0] pre_addr;
reg VINZONE2, VINZONE3;
reg [8:0] objx, posx1, posx2;
reg [3:0] CD2;

localparam [3:0] DATAREAD = 4'd7; //6,8,9,10,11,12,16

always @(posedge clk) if(cen6) begin
    case( pxlcnt )
        4'd0: V2C <= ~VF + { {7{~flip}}, 1'b1 }; // V 2's complement
        4'd7: begin
            `ifdef VULGUS
            pre_addr[14:10] <= { 1'b0, next_AD[7:4]};
            `else // 1942
            pre_addr[14:10] <= {next_AD[7], next_ADext, next_AD[6:4]};
            `endif
            case( next_vlen )
                2'd0: pre_addr[9:6] <= next_AD[3:0]; // 16
                2'd1: pre_addr[9:6] <= { next_AD[3:1], ~LVBETA[4] }; // 32
                2'd2: pre_addr[9:6] <= { next_AD[3:2], ~LVBETA[5], ~LVBETA[4] }; // 64
                2'd3: pre_addr[9:6] <= ~LVBETA[7:4];
            endcase
            pre_addr[4:1] <= ~LVBETA[3:0];
            VINZONE2 <= VINZONE;
            objx <= { next_hover, next_x };
            CD2   <= next_CD;
        end
    endcase
end

assign obj_addr[14:6] = pre_addr[14:6];
assign obj_addr[ 4:1] = pre_addr[ 4:1];
//assign { obj_addr[5], obj_addr[0] } = {~pxlcnt[3], pxlcnt[2]};
assign { obj_addr[5], obj_addr[0] } = { pxlcnt[3]^~pxlcnt[2], ~pxlcnt[2]}-2'b1;

// ROM data depacking

reg  [3:0] z,y,x,w;
reg  [3:0] obj_wxyz;
wire [7:0] pal_addr = { CD, obj_wxyz};


always @(posedge clk) if(cen6) begin
    if( pxlcnt == 4'b1011 ) begin //
        CD       <= CD2;
        VINZONE3 <= VINZONE2;
        posx1<=objx;
    end else begin
        posx1 <= posx1 + 9'b1;
    end
    if( pxlcnt[1:0] == 2'b11 )
        {z,y,x,w} <= objrom_data;
    else begin
        z <= z << 1;
        y <= y << 1;
        x <= x << 1;
        w <= w << 1;
	end
end

always @(*) begin
`ifdef VULGUS
    obj_wxyz = {y[3],z[3],w[3],x[3]};
`else
    obj_wxyz = {w[3],x[3],y[3],z[3]};
`endif
end

wire [3:0] prom_dout;
reg VINZONE4;

always @(posedge clk ) if(cen6) begin
    posx2 <= posx1;
    VINZONE4 <= VINZONE3;
    if( !VINZONE4 ) begin
        new_pxl <= prom_dout;
        posx    <= posx2;
    end else begin
        new_pxl <= 4'hf;
        posx    <= 9'h100;
    end
end

jtgng_prom #(.aw(8),.dw(4),
    .simfile("../../../rom/1942/sb-8.k3")
) u_prom_k3(
    .clk    ( clk            ),
    .cen    ( cen6           ),
    .data   ( prog_din       ),
    .rd_addr( pal_addr       ),
    .wr_addr( prog_addr      ),
    .we     ( prom_pal_we     ),
    .q      ( prom_dout      )
);


endmodule // jtgng_objdraw