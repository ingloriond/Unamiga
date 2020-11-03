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
    Date: 2-7-2019 */

// commando: Main CPU

`timescale 1ns/1ps

module jtgunsmoke_main(
    input              rst,
    input              clk,
    input              cen6,   // 6MHz
    input              cen3    /* synthesis direct_enable = 1 */,   // 3MHz
    output             cpu_cen,
    // Timing
    output  reg        flip,
    input   [8:0]      V,
    input              LHBL,
    input              LVBL,
    // Sound
    output  reg        sres_b, // sound reset
    output  reg  [7:0] snd_latch,
    // Characters
    input        [7:0] char_dout,
    output       [7:0] cpu_dout,
    output  reg        char_cs,
    input              char_busy,
    // scroll
    output  reg [7:0]  scrposv,
    output  reg [1:0]  scrposh_cs,
    output  reg        CHON,
    output  reg        SCRON,
    output  reg        OBJON,
    // cabinet I/O
    input   [6:0]      joystick1,
    input   [6:0]      joystick2,
    input   [1:0]      start_button,
    input   [1:0]      coin_input,
    // BUS sharing
    output  [12:0]     cpu_AB,
    output  [ 7:0]     ram_dout,
    input   [12:0]     obj_AB,
    output             rd_n,
    output             wr_n,
    output  reg        OKOUT,
    input              bus_req,  // Request bus
    output             bus_ack,  // bus acknowledge
    input              blcnten,  // bus line counter enable
    output  reg [ 2:0] obj_bank,
    // ROM access
    output  reg        rom_cs,
    output  reg [16:0] rom_addr,
    input       [ 7:0] rom_data,
    input              rom_ok,
    // DIP switches
    input              dip_pause,
    input    [7:0]     dipsw_a,
    input    [7:0]     dipsw_b
);

wire [15:0] A;
wire t80_rst_n;
reg in_cs, ram_cs, bank_cs, scrposv_cs, gfxen_cs, snd_latch_cs;

wire mreq_n, rfsh_n, busak_n;
assign cpu_cen = cen3;
assign bus_ack = ~busak_n;

always @(*) begin
    rom_cs        = 1'b0;
    ram_cs        = 1'b0;
    snd_latch_cs  = 1'b0;
    bank_cs       = 1'b0;
    in_cs         = 1'b0;
    char_cs       = 1'b0;
    scrposh_cs    = 2'b0;
    scrposv_cs    = 1'b0;
    gfxen_cs      = 1'b0;
    OKOUT         = 1'b0;
    if( rfsh_n && !mreq_n ) casez(A[15:13])
        3'b0??: rom_cs = 1'b1;
        3'b10?: rom_cs = 1'b1; // bank
        3'b110: // CXXX, DXXX
            case(A[12:11])
                2'b00: // C0
                    in_cs = 1'b1;
                2'b01: // C8
                    if( !A[3] && !wr_n) case(A[2:0])
                        3'b000: snd_latch_cs = 1'b1;
                        3'b100: bank_cs      = 1'b1;  // ROM bank & screen flip
                        3'b110: OKOUT        = 1'b1;
                        default:;
                    endcase
                2'b10: // D0
                    char_cs = 1'b1; // D0CS
                2'b11: // D8
                    if( !A[3] && !wr_n) case(A[2:0])
                        3'b000: scrposh_cs = 2'b01; 
                        3'b001: scrposh_cs = 2'b10; 
                        3'b010: scrposv_cs = 1'b1;
                        3'b110: gfxen_cs   = 1'b1;
								default:;
                    endcase
            endcase
        3'b111: ram_cs = 1'b1;
    endcase
end

// special registers
reg [1:0] bank;
always @(posedge clk, posedge rst)
    if( rst ) begin
        bank      <= 2'd0;
        scrposv   <= 8'd0;
        CHON      <= 1'b0;
        flip      <= 1'b0;
        sres_b    <= 1'b1;
        obj_bank  <= 3'd0;
        {OBJON, SCRON } <= 2'b00;
        snd_latch <= 8'd0;
    end
    else if(cpu_cen) begin
        if( bank_cs  && !wr_n ) begin
            CHON     <=  cpu_dout[7];
            flip     <=  cpu_dout[6];
            sres_b   <= ~cpu_dout[5]; // inverted through NPN
            bank     <=  cpu_dout[3:2];
            `ifdef SIMULATION
            $display("Bank changed to %d", cpu_dout[3:2]);
            `endif
            // bits 0, 1 are coin counters.
        end
        if( snd_latch_cs && !wr_n ) snd_latch <= cpu_dout;
        if( scrposv_cs ) scrposv <= cpu_dout;
        if( gfxen_cs ) begin
            {OBJON, SCRON } <= cpu_dout[5:4];
            obj_bank        <= cpu_dout[2:0];
        end
    end

jt12_rst u_rst(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .rst_n  ( t80_rst_n )
);

reg [7:0] cabinet_input;

always @(*)
    case( A[2:0] )
        3'd0: cabinet_input = { coin_input, // COINS
                     2'b11, // undocumented. D5 & D4 what are those?
                     ~LVBL, // This was like this on 1943, just leaving it the same for now
                     1'b1,
                     start_button }; // START
        3'd1: cabinet_input = { 1'b1, joystick1 };
        3'd2: cabinet_input = { 1'b1, joystick2 };
        3'd3: cabinet_input = dipsw_a;
        3'd4: cabinet_input = dipsw_b;
        default: cabinet_input = 8'hff;
    endcase


// RAM, 16kB
wire cpu_ram_we = ram_cs && !wr_n;
assign cpu_AB = A[12:0];

wire [12:0] RAM_addr = blcnten ? obj_AB : cpu_AB;
wire RAM_we   = blcnten ? 1'b0 : cpu_ram_we;

jtgng_ram #(.aw(13),.cen_rd(0)) RAM(
    .clk        ( clk       ),
    .cen        ( cpu_cen   ),
    .addr       ( RAM_addr  ),
    .data       ( cpu_dout  ),
    .we         ( RAM_we    ),
    .q          ( ram_dout  )
);

// Data bus input
reg [7:0] cpu_din;
wire iorq_n, m1_n;
wire irq_ack = !iorq_n && !m1_n;

always @(*)
    case( {ram_cs, char_cs, rom_cs, in_cs} )
        4'b10_00: cpu_din = ram_dout;
        4'b01_00: cpu_din = char_dout;
        4'b00_10: cpu_din = rom_data;
        4'b00_01: cpu_din = cabinet_input;
        default:  cpu_din = 8'hff;
    endcase

// ROM ADDRESS: 32kB + 4 banks of 16kB
always @(*) begin
    rom_addr[13: 0] = A[13:0];
    rom_addr[16:14] = !A[15] ? { 2'b0, A[14] } : ( 3'b010 + { 1'b0, bank});
end

///////////////////////////////////////////////////////////////////
// interrupt generation. 1943 Schematics page 5/9, parts 12J and 14K
reg int_n, int_rqb, int_rqb_last;
wire int_middle = V[7:5]!=3'd3;
wire int_rqb_negedge = !int_rqb && int_rqb_last;

always @(posedge clk, posedge rst)
    if(rst) begin
        int_n <= 1'b1;
    end else if(cpu_cen) begin
        int_rqb_last <= int_rqb;
        int_rqb <= LVBL && int_middle;
        if( irq_ack )
            int_n <= 1'b1;
        else
            if ( int_rqb_negedge ) int_n <= 1'b0;
    end

/////////////////////////////////////////////////////////////////
// wait_n generation
wire wait_n;

jtframe_z80wait #(1) u_wait(
    .rst_n      ( t80_rst_n ),
    .clk        ( clk       ),
    .cpu_cen    ( cpu_cen   ),
    // manage access to shared memory
    .dev_busy   ( char_busy ),
    // manage access to ROM data from SDRAM
    .rom_cs     ( rom_cs    ),
    .rom_ok     ( rom_ok    ),

    .wait_n     ( wait_n    )
);

///////////////////////////////////////////////////////////////////


`ifdef SIMULATION
`define Z80_ALT_CPU
`endif

//`ifdef NCVERILOG
//`undef Z80_ALT_CPU
//`endif

`ifdef VERILATOR_LINT
`define Z80_ALT_CPU
`endif

`ifndef Z80_ALT_CPU
// This CPU is used for synthesis
wire [211:0] z80_regs;
`ifdef SIMULATION
wire reg_IFF2;
wire reg_IFF1;
wire [1:0]  reg_IM;    // 4
wire [15:0] reg_IY;
wire [15:0] reg_HL_;
wire [15:0] reg_DE_;
wire [15:0] reg_BC_;
wire [15:0] reg_IX;
wire [15:0] reg_HL;
wire [15:0] reg_DE;
wire [15:0] reg_BC;
wire [15:0] reg_PC;
wire [15:0] reg_SP; // 164
wire [7:0]  reg_R;
wire [7:0]  reg_I;
wire [7:0]  reg_F_;
wire [7:0]  reg_A_;
wire [7:0]  reg_F;
wire [7:0]  reg_A;
assign {
    reg_IFF2, reg_IFF1, reg_IM, reg_IY, reg_HL_, reg_DE_, reg_BC_,
    reg_IX, reg_HL, reg_DE, reg_BC, reg_PC, reg_SP, reg_R, reg_I,
    reg_F_, reg_A_, reg_F, reg_A } = z80_regs;
`endif
T80s u_cpu(
    .RESET_n    ( t80_rst_n   ),
    .CLK        ( clk         ),
    .CEN        ( cpu_cen     ),
    .WAIT_n     ( wait_n      ),
    .INT_n      ( int_n       ),
    .RD_n       ( rd_n        ),
    .WR_n       ( wr_n        ),
    .A          ( A           ),
    .DI         ( cpu_din     ),
    .DO         ( cpu_dout    ),
    .IORQ_n     ( iorq_n      ),
    .M1_n       ( m1_n        ),
    .MREQ_n     ( mreq_n      ),
    .NMI_n      ( 1'b1        ),
    .BUSRQ_n    ( ~bus_req    ),
    .BUSAK_n    ( busak_n     ),
    .RFSH_n     ( rfsh_n      ),
    .out0       ( 1'b0        )
);
`else
// This CPU is used for simulation
tv80s #(.Mode(0)) u_cpu (
    .reset_n( t80_rst_n  ),
    .clk    ( clk        ),
    .cen    ( cpu_cen    ),
    .wait_n ( wait_n     ),
    .int_n  ( int_n      ),
    .nmi_n  ( 1'b1       ),
    .busrq_n( ~bus_req   ),
    .rd_n   ( rd_n       ),
    .wr_n   ( wr_n       ),
    .A      ( A          ),
    .di     ( cpu_din    ),
    .dout   ( cpu_dout   ),
    .iorq_n ( iorq_n     ),
    .m1_n   ( m1_n       ),
    .mreq_n ( mreq_n     ),
    .rfsh_n ( rfsh_n     ),
    .busak_n( busak_n    ),
    // unused
    .halt_n ()
);
`endif
endmodule // jtgng_main