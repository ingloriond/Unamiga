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
    Date: 20-2-2019 */

`timescale 1ns/1ps

module jtframe_rom #(parameter
    // Default values correspond to G&G
    SND_OFFSET  = 22'h0A000,
    CHAR_OFFSET = 22'h0E000,
    SCR1_OFFSET = 22'h10000,
    SCR2_OFFSET = 22'h08000, // upper byte of each tile
    OBJ_OFFSET  = 22'h20000,
    // Address width
    MAIN_AW     = 17,
    SND_AW      = 15,
    CHAR_AW     = 13,
    SCR1_AW     = 15,
    SCR2_AW     = 15,
    OBJ_AW      = 15,
    // Data width, only byte multiples
    MAIN_DW     = 8,
    SND_DW      = 8,
    CHAR_DW     = 16,
    SCR1_DW     = 32,
    SCR2_DW     = 32,
    OBJ_DW      = 16
)(
    input               rst_n,
    input               clk,
    input               LHBL,
    input               LVBL,

    input               main_cs,
    input               snd_cs,
    
    output              main_ok,
    output              snd_ok,
    output              char_ok,

    input  [MAIN_AW-1:0]  main_addr,
    input  [ SND_AW-1:0]  snd_addr,
    input  [CHAR_AW-1:0]  char_addr,
    input  [SCR1_AW-1:0]  scr1_addr,
    input  [SCR2_AW-1:0]  scr2_addr,
    input  [ OBJ_AW-1:0]  obj_addr,

    output [MAIN_DW-1:0]  main_dout,
    output [ SND_DW-1:0]   snd_dout,
    output [CHAR_DW-1:0]  char_dout,
    output [SCR1_DW-1:0]  scr1_dout,
    output [SCR2_DW-1:0]  scr2_dout,
    output [ OBJ_DW-1:0]   obj_dout,
    output  reg         ready,

    // SDRAM controller interface
    input               data_rdy,
    input               sdram_ack,
    input               downloading,
    input               loop_rst,
    output  reg         sdram_req,
    output  reg         refresh_en,
    output  reg [21:0]  sdram_addr,
    input       [31:0]  data_read
);

reg [3:0] ready_cnt;
reg [3:0] rd_state_last;
wire main_req, snd_req, char_req, scr1_req, scr2_req, obj_req;

localparam MAIN=0, SND=1, CHAR=2, SCR1=3, OBJ=4, SCR2=5;

reg [5:0] data_sel;
wire [MAIN_AW-1:0] main_addr_req;
wire [ SND_AW-1:0]  snd_addr_req;
wire [CHAR_AW-1:0] char_addr_req;
wire [SCR1_AW-1:0] scr1_addr_req;
wire [SCR2_AW-1:0] scr2_addr_req;
wire [ OBJ_AW-1:0] obj_addr_req;

wire scr1_ok, scr2_ok, obj_ok;

always @(posedge clk)
    refresh_en <= &{ main_ok&main_cs, snd_ok&snd_cs, char_ok, scr1_ok, scr2_ok, obj_ok };

jtframe_romrq #(.AW(MAIN_AW),.DW(MAIN_DW),.INVERT_A0(1)) u_main(
    .rst_n    ( rst_n           ),
    .clk      ( clk             ),
    .addr     ( main_addr       ),
    .addr_ok  ( main_cs         ),
    .addr_req ( main_addr_req   ),
    .din      ( data_read       ),
    .din_ok   ( data_rdy        ),
    .dout     ( main_dout       ),
    .req      ( main_req        ),
    .data_ok  ( main_ok         ),
    .we       ( data_sel[MAIN]  )
);


jtframe_romrq #(.AW(SND_AW),.DW(SND_DW),.INVERT_A0(1)) u_snd(
    .rst_n    ( rst_n           ),
    .clk      ( clk             ),
    .addr     ( snd_addr        ),
    .addr_ok  ( snd_cs          ),
    .addr_req ( snd_addr_req    ),
    .din      ( data_read       ),
    .din_ok   ( data_rdy        ),
    .dout     ( snd_dout        ),
    .req      ( snd_req         ),
    .data_ok  ( snd_ok          ),
    .we       ( data_sel[SND]   )
);

jtframe_romrq #(.AW(CHAR_AW),.DW(CHAR_DW)) u_char(
    .rst_n    ( rst_n           ),
    .clk      ( clk             ),
    .addr     ( char_addr       ),
    .addr_ok  ( LVBL            ),
    .addr_req ( char_addr_req   ),
    .din      ( data_read       ),
    .din_ok   ( data_rdy        ),
    .dout     ( char_dout       ),
    .req      ( char_req        ),
    .data_ok  ( char_ok         ),
    .we       ( data_sel[CHAR]  )
);

jtframe_romrq #(.AW(SCR1_AW),.DW(SCR1_DW)) u_scr1(
    .rst_n    ( rst_n           ),
    .clk      ( clk             ),
    .addr     ( scr1_addr       ),
    .addr_ok  ( LVBL            ),
    .addr_req ( scr1_addr_req   ),
    .din      ( data_read       ),
    .din_ok   ( data_rdy        ),
    .dout     ( scr1_dout       ),
    .req      ( scr1_req        ),
    .data_ok  ( scr1_ok         ),
    .we       ( data_sel[SCR1]  )
);

jtframe_romrq #(.AW(SCR2_AW),.DW(SCR1_DW)) u_scr2(
    .rst_n    ( rst_n           ),
    .clk      ( clk             ),
    .addr     ( scr2_addr       ),
    .addr_ok  ( LVBL            ),
    .addr_req ( scr2_addr_req   ),
    .din      ( data_read       ),
    .din_ok   ( data_rdy        ),
    .dout     ( scr2_dout       ),
    .req      ( scr2_req        ),
    .data_ok  ( scr2_ok         ),
    .we       ( data_sel[SCR2]  )
);

jtframe_romrq #(.AW(OBJ_AW),.DW(OBJ_DW)) u_obj(
    .rst_n    ( rst_n           ),
    .clk      ( clk             ),
    .addr     ( obj_addr        ),
    .addr_ok  ( 1'b1            ),
    .addr_req ( obj_addr_req    ),
    .din      ( data_read       ),
    .din_ok   ( data_rdy        ),
    .dout     ( obj_dout        ),
    .req      ( obj_req         ),
    .data_ok  ( obj_ok          ),
    .we       ( data_sel[OBJ]   )
);

`ifdef SIMULATION
real busy_cnt=0, total_cnt=0;
always @(posedge clk) begin
    total_cnt <= total_cnt + 1;
    if( |data_sel ) busy_cnt <= busy_cnt+1;
end
always @(posedge LVBL) begin
    $display("INFO: frame ROM stats: %.0f %%", 100.0*busy_cnt/total_cnt);
end
`endif

reg [5:0] valid_req;
always @(*) begin
    valid_req[MAIN] = main_req & ~data_sel[MAIN];
    valid_req[ SND] = snd_req  & ~data_sel[ SND];
    valid_req[SCR1] = scr1_req & ~data_sel[SCR1];
    valid_req[SCR2] = scr2_req & ~data_sel[SCR2];
    valid_req[CHAR] = char_req & ~data_sel[CHAR];
    valid_req[ OBJ] = obj_req  & ~data_sel[ OBJ];
end

always @(posedge clk)
if( loop_rst || downloading ) begin
    sdram_addr <=  'd0;
    ready_cnt <=  4'd0;
    ready     <=  1'b0;
    sdram_req <=  1'b0;
    data_sel  <=   'd0;
end else begin
    {ready, ready_cnt}  <= {ready_cnt, 1'b1};
    if( sdram_ack ) sdram_req <= 1'b0;
    // accept a new request
    if( |data_sel==1'b0 || data_rdy ) begin
        sdram_req <= |valid_req;
        data_sel <= 'd0;
        case( 1'b1 )
            valid_req[OBJ]: begin
                sdram_addr <= OBJ_OFFSET + { {22-OBJ_AW{1'b0}}, obj_addr_req };
                data_sel[OBJ] <= 1'b1;
            end
            valid_req[SCR1]: begin
                sdram_addr <= SCR1_OFFSET + { {22-SCR1_AW{1'b0}}, scr1_addr_req };
                data_sel[SCR1] <= 1'b1;
            end
            valid_req[SCR2]: begin
                sdram_addr <= SCR2_OFFSET + { {22-SCR2_AW{1'b0}}, scr2_addr_req };
                data_sel[SCR2] <= 1'b1;
            end
            valid_req[CHAR]: begin
                sdram_addr <= CHAR_OFFSET + { {22-CHAR_AW{1'b0}}, char_addr_req };
                data_sel[CHAR] <= 1'b1;
            end
            valid_req[MAIN]: begin
                sdram_addr <= { {22-MAIN_AW+1{1'b0}}, main_addr_req[MAIN_AW-1:1] };
                data_sel[MAIN] <= 1'b1;
            end
            valid_req[SND]: begin
                sdram_addr <= SND_OFFSET + { {22-SND_AW+1{1'b0}}, snd_addr_req[SND_AW-1:1] };
                data_sel[SND] <= 1'b1;
            end
        endcase
    end
end

endmodule