/*  This file is part of JTCPS1.
    JTCPS1 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTCPS1 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTCPS1.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 30-1-2020 */

`timescale 1ns/1ps

module jtcps1_prom_we(
    input                clk,
    input                downloading,
    input      [24:0]    ioctl_addr,    // max 32 MB
    input      [ 7:0]    ioctl_data,
    input                ioctl_wr,
    output reg [21:0]    prog_addr,
    output reg [ 7:0]    prog_data,
    output reg [ 1:0]    prog_mask, // active low
    output reg [ 1:0]    prog_bank,
    output reg           prog_we,
    input                sdram_ack,
    output reg           cfg_we
);

parameter        REGSIZE=24; // This is defined at _game level
parameter [21:0] CPU_OFFSET=22'h0;
parameter [21:0] SND_OFFSET=22'h0;
parameter [21:0] OKI_OFFSET=22'h0;
parameter [21:0] GFX_OFFSET=22'h0;
parameter [ 5:0] CFG_BYTE  =6'd39; // location of the byte with encoder information

// The start position header has 16 bytes, from which 6 are actually used and
// 10 are reserved
localparam START_BYTES  = 6;
localparam START_HEADER = 16;
localparam STARTW=8*START_BYTES;
localparam FULL_HEADER = 25'd64;

(*keep*) reg  [STARTW-1:0] starts;
(*keep*) wire       [15:0] snd_start, oki_start, gfx_start;

assign snd_start = starts[15: 0];
assign oki_start = starts[31:16];
assign gfx_start = starts[47:32];

wire [24:0] bulk_addr = ioctl_addr - FULL_HEADER; // the header is excluded
wire [24:0] cpu_addr  = bulk_addr ; // the header is excluded
wire [24:0] snd_addr  = bulk_addr - { snd_start, 10'd0 };
wire [24:0] oki_addr  = bulk_addr - { oki_start, 10'd0 };
wire [24:0] gfx_addr  = bulk_addr - { gfx_start, 10'd0 };

wire is_cps = ioctl_addr > 7 && ioctl_addr < (REGSIZE+START_HEADER);
wire is_cpu = bulk_addr[24:10] < snd_start;
wire is_snd = bulk_addr[24:10] < oki_start && bulk_addr[24:10]>=snd_start;
wire is_oki = bulk_addr[24:10] < gfx_start && bulk_addr[24:10]>=oki_start;
wire is_gfx = bulk_addr[24:10] >=gfx_start;

reg       decrypt, pang3, pang3_bit;
reg [7:0] pang3_decrypt;

// The decryption is literally copied from MAME, it is up to
// the synthesizer to optimize the code. And it will.
always @(*) begin
    pang3 = is_cpu && cpu_addr[19] && decrypt  && (cpu_addr[0]^pang3_bit);
    pang3_decrypt =
        (((((((ioctl_data[0] ? 8'h04 : 8'h00)  ^
              (ioctl_data[1] ? 8'h21 : 8'h00)) ^
              (ioctl_data[2] ? 8'h01 : 8'h00)) ^
              (ioctl_data[3] ? 8'h00 : 8'h50)) ^
              (ioctl_data[4] ? 8'h40 : 8'h00)) ^
              (ioctl_data[5] ? 8'h06 : 8'h00)) ^
              (ioctl_data[6] ? 8'h08 : 8'h00)) ^
              (ioctl_data[7] ? 8'h00 : 8'h88);
    /*pang3_decrypt = 8'd0;
    if ( ioctl_data[0] ) pang3_decrypt = pang3_decrypt ^ 8'h04;
    if ( ioctl_data[1] ) pang3_decrypt = pang3_decrypt ^ 8'h21;
    if ( ioctl_data[2] ) pang3_decrypt = pang3_decrypt ^ 8'h01;
    if (~ioctl_data[3] ) pang3_decrypt = pang3_decrypt ^ 8'h50;
    if ( ioctl_data[4] ) pang3_decrypt = pang3_decrypt ^ 8'h40;
    if ( ioctl_data[5] ) pang3_decrypt = pang3_decrypt ^ 8'h06;
    if ( ioctl_data[6] ) pang3_decrypt = pang3_decrypt ^ 8'h08;
    if (~ioctl_data[7] ) pang3_decrypt = pang3_decrypt ^ 8'h88;*/
end

always @(posedge clk) begin
    if ( ioctl_wr && downloading ) begin
        prog_data <= pang3 ?
            pang3_decrypt : ioctl_data;
        prog_mask <= !ioctl_addr[0] ? 2'b10 : 2'b01;            
        prog_addr <= is_cpu ? bulk_addr[22:1] + CPU_OFFSET : (
                     is_snd ?  snd_addr[22:1] + SND_OFFSET : (
                     is_oki ?  oki_addr[22:1] + OKI_OFFSET : gfx_addr[22:1] + GFX_OFFSET ));
        prog_bank <= is_cpu ? 2'b01 : ( is_gfx ? 2'b10 : 2'b00 );
        if( ioctl_addr < START_BYTES ) begin
            starts  <= { ioctl_data, starts[STARTW-1:8] };
            cfg_we  <= 1'b0;
            prog_we <= 1'b0;
        end else begin
            if( is_cps ) begin
                cfg_we    <= 1'b1;
                prog_we   <= 1'b0;
                if( ioctl_addr[5:0] == CFG_BYTE ) {decrypt, pang3_bit} <= ioctl_data[7:6];
            end else begin
                cfg_we    <= 1'b0;
                prog_we   <= 1'b1;
            end
        end
    end
    else begin
        if(!downloading || sdram_ack) prog_we  <= 1'b0;
        if( !downloading ) decrypt <= 0;
        cfg_we   <= 1'b0;
    end
end

endmodule