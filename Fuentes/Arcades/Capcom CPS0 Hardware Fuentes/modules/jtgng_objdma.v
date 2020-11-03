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
    Date: 11-1-2019 */

module jtgng_objdma(
    input              rst,
    input              clk,
    input              cen6,    //  6 MHz
    // screen
    input              LVBL,
    input              pause,
    output  reg [ 3:0] avatar_idx,
    // shared bus
    output  reg [ 8:0] AB,
    input       [ 7:0] DB,
    input              OKOUT,
    output  reg        bus_req,  // Request bus
    input              bus_ack,  // bus acknowledge
    output  reg        blen,     // bus line counter enable
    // output data
    input       [8:0]  pre_scan,
    output  reg [7:0]  ram_dout
);

reg [1:0] bus_state;

localparam ST_IDLE=2'd0, ST_WAIT=2'd1,ST_BUSY=2'd2;
localparam MEM_PREBUF=1'd0,MEM_BUF=1'd1;

// Ghosts'n Goblins copy only 'h180 objects as per schematics
// 1943 copy more, but it is not clear what the limit is.
// There is enough time during the vertical blank to copy the whole
// buffer at 6MHz, so the GnG limitation may have been set to
// give more time to the main CPU.
// It takes 170us to copy the whole ('h1FF) buffer

parameter OBJMAX=9'h180;
parameter AVATAR_MAX=4'd8; // ignore if avatars are not used

reg mem_sel;

always @(posedge clk, posedge rst)
    if( rst ) begin
        blen      <= 1'b0;
        bus_state <= ST_IDLE;
    end else if(cen6) begin
        case( bus_state )
            ST_IDLE: if( OKOUT ) begin
                    bus_req   <= 1'b1;
                    bus_state <= ST_WAIT;
                end
                else begin
                    bus_req <= 1'b0;
                    blen    <= 1'b0;
                end
            ST_WAIT: if( bus_ack && mem_sel == MEM_PREBUF && !LVBL ) begin
                blen      <= 1'b1;
                bus_state <= ST_BUSY;
            end
            ST_BUSY: if( AB==OBJMAX ) begin
                bus_req <= 1'b0;
                blen    <= 1'b0;
                bus_state <= ST_IDLE;
            end
            default: bus_state <= ST_IDLE;
        endcase
    end

reg ABslow;
always @(posedge clk) if(cen6) begin
    if( !blen )
        {AB, ABslow} <= 10'd0;
    else begin
        {AB, ABslow} <= {AB, ABslow} + 1'b1;
    end
end

always @(posedge clk, posedge rst)
    if(rst)
        mem_sel <= MEM_PREBUF;
    else if(cen6) begin
        mem_sel <= ~mem_sel;
    end


wire [9:0]  wr_addr = mem_sel==MEM_PREBUF ? {1'b0, AB } : 10'd0;
wire        ram_we  = mem_sel==MEM_PREBUF ? blen : 1'b0;

`ifndef OBJTEST
wire [7:0]  ram_din = mem_sel==MEM_PREBUF ? DB : 8'd0;
`else 
wire [7:0] ram_din;
jtgng_ram #(.aw(9),.simfile("objtest.bin"),.cen_rd(0)) u_testram(
    .clk        ( clk       ),
    .cen        ( 1'b1      ),
    .addr       ( AB        ),
    .data       ( 9'd0      ),
    .we         ( 1'b0      ),
    .q          ( ram_din   )
);
`endif

wire [7:0] buf_data;

jtgng_dual_ram #(.aw(10)) u_objram (
    .clk        ( clk               ),
    .clk_en     ( cen6              ),
    .data       ( ram_din           ),
    .rd_addr    ( {1'b0, pre_scan } ),
    .wr_addr    ( wr_addr           ),
    .we         ( ram_we            ),
    .q          ( buf_data          )
);

`ifdef AVATARS
// Avatar counter is used in both MiST and MiSTer

wire [ 7:0] avatar_id;
reg  [ 7:0] avatar_data;
reg  [ 9:0] avatar_cnt = 0;
wire [ 9:0] avatar_next = avatar_cnt+10'd1;
localparam CNTMAX = 10'd2*10'd60;

// Each avatar is made of 9 sprites, which are ordered one after the other in memory
// the sprite ID is calculated by combining the current Avatar on display and the
// position inside the object buffer, which is virtual during avatar display

// multiples avatar_idx by 9 = x8+1
// wire [7:0] avatar_idx9 = { 1'd0, avatar_idx, 3'd0 } + {4'd0, avatar_idx};
// 
// always @(posedge clk)
//     avatar_id <= pre_scan[5:2] > 4'd8 ? 8'h63 :
//         ( {4'd0, pre_scan[5:2]} + avatar_idx9 );

wire [3:0] id_next =avatar_idx + 4'd1;
reg lastLVBL;
always @(posedge clk, posedge rst) 
    if( rst ) begin
        avatar_idx <= 4'd0;
        avatar_cnt <= 10'd0;
    end else begin
        lastLVBL <= LVBL;
        if( !LVBL && lastLVBL ) begin
            `ifndef SIMULATION
            if(avatar_next==CNTMAX) begin
                avatar_cnt <= 10'd0;
                avatar_idx <= id_next==AVATAR_MAX ? 4'd0 : id_next;
            end else begin
                avatar_cnt<= avatar_next;
            end
            `else 
            avatar_idx <= id_next;
            `endif
        end
    end

`ifdef MISTER
    // Avatar data output is always defined for MiSTer
    `define AVATAR_DATA
`endif

`ifdef AVATAR_DATA
jtgng_ram #(.aw(8), .synfile("avatar_obj.hex"),.cen_rd(1))u_avatars(
    .clk    ( clk           ),
    .cen    ( pause         ),  // tiny power saving when not in pause
    .data   ( 8'd0          ),
    .addr   ( {avatar_idx, pre_scan[5:2] } ),
    .we     ( 1'b0          ),
    .q      ( avatar_id     )
);

reg [7:0] avatar_y, avatar_x;


always @(posedge clk) begin
    if(pre_scan[8:6]==3'd0) begin
        case( pre_scan[5:2] )
            4'd0,4'd1,4'd2: avatar_y <= 8'h70;
            4'd3,4'd4,4'd5: avatar_y <= 8'h70 + 8'h10;
            4'd6,4'd7,4'd8: avatar_y <= 8'h70 + 8'h20;
            default: avatar_y <= 8'hf8;
        endcase
        case( pre_scan[5:2] )
            4'd0,4'd3,4'd6: avatar_x <= 8'h08;
            4'd1,4'd4,4'd7: avatar_x <= 8'h08 + 8'h10;
            4'd2,4'd5,4'd8: avatar_x <= 8'h08 + 8'h20;
            default: avatar_x <= 8'hf8;
        endcase
    end
    else begin
        avatar_y <= 8'hf8;
        avatar_x <= 8'hf8;
    end
end

always @(*) begin
    case( pre_scan[1:0] )
        2'd0: avatar_data = pre_scan[8:6]==3'd0 ? avatar_id : 8'hff;
        2'd1: avatar_data = 8'd0;
        2'd2: avatar_data = avatar_y;
        2'd3: avatar_data = avatar_x;
    endcase
    ram_dout = pause ? avatar_data : buf_data;
end

`else 
always @(*) begin
    ram_dout   = buf_data;
end
`endif
`else
always @(*) begin
    avatar_idx = 4'd0;
    ram_dout   = buf_data;
end
`endif

endmodule // load