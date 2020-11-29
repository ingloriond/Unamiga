/*  This file is part of JT_FRAME.
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
    Date: 25-9-2019 */

// Simple scan doubler
// CRT-like output:
//  -simple blending of neighbouring pixels
//  -50% scan lines

module jtframe_scan2x #(parameter COLORW=4, HLEN=512)(
    input       rst_n,
    input       clk,
    input       pxl_cen,
    input       pxl2_cen,
    input       [COLORW*3-1:0]    base_pxl,
    input       HS,
    input [1:0] sl_mode,  // scanline enable

    output  reg [COLORW*3-1:0]    x2_pxl,
    output  reg x2_HS
);

localparam AW=HLEN<=512 ? 9:10;
localparam DW=COLORW*3;

reg  [DW-1:0] preout;
reg  [AW-1:0] wraddr, rdaddr, hscnt0, hscnt1;
reg           oddline, scanline;
reg           last_HS, last_HS_base;
reg           waitHS, line;

wire          HS_posedge     =  HS && !last_HS;
wire          HSbase_posedge =  HS && !last_HS_base;
wire          HS_negedge     = !HS &&  last_HS;
wire [DW-1:0] next;
wire [DW-1:0] dim2, dim4;

function [COLORW-1:0] ave;
    input [COLORW-1:0] a;
    input [COLORW-1:0] b;
    ave = ({1'b0,a}+{1'b0,b})>>1;
endfunction

function [DW-1:0] blend;
    input [DW-1:0] a;
    input [DW-1:0] b;
    blend = {
        ave(a[COLORW*3-1:COLORW*2],b[COLORW*3-1:COLORW*2]),
        ave(a[COLORW*2-1:COLORW],b[COLORW*2-1:COLORW]),
        ave(a[COLORW-1:0],b[COLORW-1:0]) };
endfunction

always @(posedge clk) if(pxl_cen)  last_HS_base <= HS;
always @(posedge clk) if(pxl2_cen) last_HS <= HS;

always@(posedge clk or negedge rst_n)
    if( !rst_n )
        waitHS  <= 1'b1;
    else begin
        if(HS_posedge ) waitHS  <= 1'b0;
    end

`ifdef JTFRAME_CLK96
localparam CLKSTEPS=8;
localparam [CLKSTEPS-1:0] BLEND_ST = 8'b10;
`else
localparam CLKSTEPS=4;
localparam [CLKSTEPS-1:0] BLEND_ST = 2;
`endif

localparam [CLKSTEPS-1:0] PURE_ST  = 0;
reg alt_pxl; // this is needed in case pxl2_cen and pxl_cen are not aligned.
reg [CLKSTEPS-1:0] mixst;

always@(posedge clk or negedge rst_n) begin
    if( !rst_n ) begin
        preout <= {DW{1'b0}};
    end else begin
        `ifndef JTFRAME_SCAN2X_NOBLEND
            // mixing can only be done if clk is at least 4x pxl2_cen
            mixst <= { mixst[1:0],pxl2_cen};
            if(mixst==BLEND_ST)
                preout <= blend( rdaddr=={AW{1'b0}} ? {DW{1'b0}} : preout,
                                 next);
            else if( mixst==PURE_ST )
                preout <= next;
        `else
            preout <= next;
        `endif
    end
end

assign dim2 = blend( {DW{1'b0}}, preout);
assign dim4 = blend( {DW{1'b0}}, dim2 );

// scan lines are black
always @(posedge clk) begin
    if( scanline ) begin
        case( sl_mode )
            2'd0: x2_pxl <= preout;
            2'd1: x2_pxl <= dim2;
            2'd2: x2_pxl <= dim4;
            2'd3: x2_pxl <= {DW{1'b0}};
        endcase
    end else x2_pxl <= preout;
end

always@(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        wraddr  <= {AW{1'b0}};
        rdaddr  <= {AW{1'b0}};
        oddline <= 1'b0;
        alt_pxl <= 1'b0;
    end else if(pxl2_cen) begin
        if( !waitHS ) begin
            rdaddr   <= rdaddr != hscnt1 ? rdaddr+1 : {AW{1'b0}};
            alt_pxl <= ~alt_pxl;
            if( alt_pxl ) begin
                if( HSbase_posedge ) oddline <= ~oddline;
                wraddr <= HSbase_posedge ? {AW{1'b0}} : (wraddr+1);
            end
        end
    end

always @(posedge clk or negedge rst_n) begin
    if( !rst_n ) begin
        x2_HS    <= 0;
        scanline <= 0;
        line     <= 0;
        hscnt1   <= {AW{1'b1}};
        hscnt0   <= {AW{1'b1}};
    end else if(pxl2_cen) begin
        if( HS_posedge ) hscnt1 <= wraddr;
        if( HS_negedge ) begin
            hscnt0 <= wraddr=={AW{1'b0}} ? {AW{1'b1}} : wraddr;
            line   <= ~line;
        end
        if( rdaddr == hscnt0 ) x2_HS <= 0;
        if( rdaddr == hscnt1 ) begin
            x2_HS    <= 1;
            if(!x2_HS) scanline <= ~scanline;
        end
    end
end

jtframe_dual_ram #(.dw(DW),.aw(AW+1)) u_buffer(
    .clk0   ( clk            ),
    .clk1   ( clk            ),
    // Port 0: read
    .data0  ( {DW{1'b0}}     ),
    .addr0  ( {line, rdaddr} ),
    .we0    ( 1'b0           ),
    .q0     ( next           ),
    // Port 1: write
    .data1  ( base_pxl       ),
    .addr1  ( {~line, wraddr}),
    .we1    ( pxl_cen        ),
    .q1     (                )
);

endmodule // jtframe_scan2x
