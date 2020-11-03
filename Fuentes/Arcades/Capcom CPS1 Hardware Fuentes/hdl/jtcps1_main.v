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
    Date: 13-1-2020 */
`timescale 1ns/1ps

module jtcps1_main(
    input              rst,
    input              clk,
    input              cen10,
    input              cen10b,
    output             cpu_cen,
    // Timing
    input   [8:0]      V,
    input              LVBL,
    input              LHBL,
    // PPU
    output reg         ppu1_cs,
    output reg         ppu2_cs,
    output reg         ppu_rstn,
    input   [15:0]     mmr_dout,
    // Sound
    output  reg  [7:0] snd_latch0,
    output  reg  [7:0] snd_latch1,
    output             UDSWn,
    output             LDSWn,
    // cabinet I/O
    input              charger,
    input   [9:0]      joystick1,
    input   [9:0]      joystick2,
    input   [1:0]      start_button,
    input   [1:0]      coin_input,
    input              service,
    input              tilt,
    // BUS sharing
    input              busreq,
    output             busack,
    output             RnW,
    // For RAM/ROM:
    output      [17:1] addr,
    output      [15:0] cpu_dout,
    // RAM access
    output             ram_cs,
    output             vram_cs,
    input       [15:0] ram_data,
    input              ram_ok,
    // ROM access
    output reg         rom_cs,
    output reg  [21:1] rom_addr,
    input       [15:0] rom_data,
    input              rom_ok,
    // DIP switches
    input              dip_pause,
    input              dip_test,
    input    [7:0]     dipsw_a,
    input    [7:0]     dipsw_b,
    input    [7:0]     dipsw_c
);

wire [23:1] A;
wire        BERRn = 1'b1;

//`ifdef SIMULATION
(*keep*) wire [24:0] A_full = {A,1'b0};
//`endif

(*keep*) wire        BRn, BGACKn, BGn;
(*keep*) wire        ASn;
reg         dbus_cs, io_cs, joy_cs, 
            sys_cs, olatch_cs, snd1_cs, snd0_cs, dial_cs;
reg         pre_ram_cs, pre_vram_cs, reg_ram_cs, reg_vram_cs;
reg         dsn_dly;
reg         one_wait;

assign cpu_cen   = cen10;
// As RAM and VRAM share contiguous spaces in the SDRAM
// it is important to prevent overlapping
assign addr      = ram_cs ? {2'b0, A[15:1] } : A[17:1];

// high during DMA transfer
wire UDSn, LDSn;
assign UDSWn = RnW | UDSn;
assign LDSWn = RnW | LDSn;

// ram_cs and vram_cs signals go down before DSWn signals
// that causes a false read request to the SDRAM. In order
// to avoid that a little bit of logic is needed:
assign ram_cs  = dsn_dly ? reg_ram_cs  : pre_ram_cs;
assign vram_cs = dsn_dly ? reg_vram_cs : pre_vram_cs;

always @(posedge clk) if(cen10) begin
    reg_ram_cs  <= pre_ram_cs;
    reg_vram_cs <= pre_vram_cs;
    dsn_dly     <= &{UDSWn,LDSWn}; // low if any DSWn was low
end

// PAL BUF1 16H
// buf0 = A[23:16]==1001_0000 = 8'h90
// buf1 = A[23:16]==1001_0001 = 8'h91
// buf2 = A[23:16]==1001_0010 = 8'h92

(*keep*) reg [23:0] last_fail;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rom_cs      <= 1'b0;
        pre_ram_cs  <= 1'b0;
        pre_vram_cs <= 1'b0;
        dbus_cs     <= 1'b0;
        io_cs       <= 1'b0;
        joy_cs      <= 1'b0;
        sys_cs      <= 1'b0;
        olatch_cs   <= 1'b0;
        snd1_cs     <= 1'b0;
        snd0_cs     <= 1'b0;
        ppu1_cs     <= 1'b0;
        ppu2_cs     <= 1'b0;
        one_wait    <= 1'b0;
        dial_cs     <= 1'b0;
        rom_addr    <= 21'd0;
    end else begin
        if( !ASn && BGACKn ) begin // PAL PRG1 12H
            rom_addr    <= A[21:1];
            one_wait    <= A[23] | ~A[22];
            dbus_cs     <= ~|A[23:18]; // all must be zero
            pre_ram_cs  <= &A[23:18];
            pre_vram_cs <= A[23:18] == 6'b1001_00 && A[17:16]!=2'b11;
            io_cs       <= A[23:20] == 4'b1000;
            rom_cs      <= A[23:22] == 2'b00;
            if( io_cs ) begin // PAL IOA1 (16P8B @ 12F)
                ppu1_cs  <= A[8:6] == 3'b100; // 'h10x
                ppu2_cs  <= A[8:6] == 3'b101 /* 'h14x */ || A[8:6] == 3'b111; /* 'h1Cx */
                dial_cs  <= A[8:5] == 4'b0_010;    // 0x800040/50
                if( RnW ) begin
                    joy_cs  <= A[8:3] == 6'b0_0000_0; // 0x800000
                    sys_cs  <= A[8:3] == 6'b0_0001_1; // 0x800018
                end else begin // outputs
                    olatch_cs <= !UDSWn && A[8:3]==6'b00_0110;
                    snd1_cs   <= !LDSWn && A[8:3]==6'b11_0001;
                    snd0_cs   <= !LDSWn && A[8:3]==6'b11_0000;
                end
            end
        end else begin
            rom_addr    <= last_fail[20:0]; // this is a trick so the compiler
                // won't get rid of last_fail, as I need to see it in signal tap
            rom_cs      <= 1'b0;
            pre_ram_cs  <= 1'b0;
            pre_vram_cs <= 1'b0;
            dbus_cs     <= 1'b0;
            io_cs       <= 1'b0;
            joy_cs      <= 1'b0;
            sys_cs      <= 1'b0;
            olatch_cs   <= 1'b0;
            snd1_cs     <= 1'b0;
            snd0_cs     <= 1'b0;
            ppu1_cs     <= 1'b0;
            ppu2_cs     <= 1'b0;
            one_wait    <= 1'b0;
            dial_cs     <= 1'b0;
        end
    end
end

/*
`ifdef SIMULATION
always @(posedge one_wait) begin
    $display("one_wait went high at %t",$time());
    #1000 $finish;
end
`endif
*/
// special registers
always @(posedge clk) begin
    if( rst ) begin
        ppu_rstn   <= 1'b0;
        snd_latch0 <= 8'd0;
        snd_latch1 <= 8'd0;
    end
    else if(cpu_cen) begin
        if( olatch_cs ) begin
            // coin counters and lockers should go in here too
            ppu_rstn <= ~cpu_dout[15];
        end
        if( snd0_cs ) snd_latch0 <= cpu_dout[7:0];
        if( snd1_cs ) snd_latch1 <= cpu_dout[7:0];
    end
end

// incremental encoder counter
wire [7:0] dial_dout;
wire       dial_rst  = dial_cs && !RnW && ~A[4];
wire       xn_y      = A[3];
wire       x_rst     = dial_rst & ~xn_y;
wire       y_rst     = dial_rst &  xn_y;
wire [1:0] x_in, y_in;
reg  [1:0] dial_pulse, last_LHBL;

// The dial update ryhtm is set to once every four lines
always @(posedge clk) begin
    last_LHBL <= LHBL;
    if( LHBL && !last_LHBL ) dial_pulse <= dial_pulse+2'd1;
end

jt4701 u_dial(
    .clk        ( clk       ),
    .rst        ( rst       ),
    .x_in       ( x_in      ),
    .y_in       ( y_in      ),
    .rightn     ( 1'b1      ),
    .leftn      ( 1'b1      ),
    .middlen    ( 1'b1      ),
    .x_rst      ( x_rst     ),
    .y_rst      ( y_rst     ),
    .csn        ( ~dial_cs  ),        // chip select
    .uln        ( ~A[1]     ),        // byte selection
    .xn_y       ( xn_y      ),        // select x or y for reading
    .cfn        (           ),        // counter flag
    .sfn        (           ),        // switch flag
    .dout       ( dial_dout )
);

jt4701_dialemu u_dial1p(
    .clk        ( clk           ),
    .rst        ( rst           ),
    .pulse      ( dial_pulse[1] ),
    .inc        ( ~joystick1[5] ),
    .dec        ( ~joystick1[6] ),
    .dial       ( x_in          )
);

jt4701_dialemu u_dial2p(
    .clk        ( clk           ),
    .rst        ( rst           ),
    .pulse      ( dial_pulse[1] ),
    .inc        ( ~joystick2[5] ),
    .dec        ( ~joystick2[6] ),
    .dial       ( y_in          )
);

reg [15:0] sys_data;

always @(posedge clk) begin
    if( joy_cs ) sys_data <= { joystick2[7:0], joystick1[7:0] };
    else if(sys_cs) begin
        case( A[2:1] )
            2'b00: sys_data <= 
            charger ? // Support for SFZ charger version
              { joystick2[9], joystick1[9], start_button,
               1'b1, service, joystick2[8], joystick1[8], 8'hff }
            // Regular CPS1 arcade:
            : { tilt, 1'b1 /* alternative test dip */, start_button,
                1'b1, service, coin_input, 8'hff };
            2'b01: sys_data <= { dipsw_a, 8'hff };
            2'b10: sys_data <= { dipsw_b, 8'hff };
            2'b11: sys_data <= { dipsw_c, 8'hff };
        endcase
    end
    else if( dial_cs && A[4] && RnW ) begin
            sys_data <= { 8'hff, dial_dout };
    end
    else sys_data <= 16'hffff;
end

// Data bus input
reg  [15:0] cpu_din;
reg         rom_ok2;

always @(posedge clk) begin
    if(rst) begin
        cpu_din <= 16'hffff;
        rom_ok2 <= 1'b0;
    end else begin
        rom_ok2 <= rom_ok;
        case( { dial_cs | joy_cs | sys_cs, ram_cs | vram_cs, rom_cs, ppu2_cs } )
            4'b10_00: cpu_din <= sys_data;
            4'b01_00: cpu_din <= ram_data;
            4'b00_10: cpu_din <= rom_data;
            4'b00_01: cpu_din <= mmr_dout;
            default:  cpu_din <= 16'hffff;
        endcase
    end
end

// DTACKn generation
wire       inta_n;
reg [2:0]  wait_cycles;
(*keep*) wire       bus_cs =   |{ rom_cs, pre_ram_cs, pre_vram_cs };
(*keep*) wire       bus_busy = |{ rom_cs & ~rom_ok2, (pre_ram_cs|pre_vram_cs) & ~ram_ok };
//                          wait_cycles[0] };
reg        DTACKn;
reg        last_LVBL;
(*keep*) reg [23:0] fail_cnt;

always @(posedge clk, posedge rst) begin : dtack_gen
    reg       last_ASn;
    if( rst ) begin
        DTACKn      <= 1'b1;
        wait_cycles <= 3'b111;
        fail_cnt    <= 24'd0;
        last_fail   <= 24'd0;
    end else /*if(cen10b)*/ begin
        last_ASn <= ASn;
        if( (!ASn && last_ASn) || ASn ) begin // for falling edge of ASn
            DTACKn <= 1'b1; 
            wait_cycles <= 3'b111;
        end else if( !ASn  ) begin
            // The original hardware always waits for 250ns
            // on each bus access, except if one_wait signal is
            // set low. Then it waits on a secondary input, which
            // seems to be tied high on the schematics.
            if( cen10 ) begin
                wait_cycles[2] <= 1'b0;
                wait_cycles[1] <= wait_cycles[2];
            end
            if( !wait_cycles[1] ) wait_cycles[0] <= ~one_wait;
            if( bus_cs ) begin
                // we avoid accumulating delay by counting it
                // and skipping wait cycles when necessary
                // the resolution of this compensation is 20.8ns
                // or one system clock
                // At any given time, fail_cnt contains the accumulated
                // delay. Worst values seen in simulation are about 125ns
                // which get resolved to zero within the next 2.8us
                // The origin of the delay is the SDRAM multiplexing
                // it would be possible to reduce the ammount of multiplexing
                // by moving the CPU RAM (not the VRAM) to a BRAM block inside
                // the FPGA, but many FPGA models don't have the resources
                // and average delay is below 3ns, so it doesn't need improvement.
                // Average delay can be displayed in simulation by defining the
                // macro REPORT_DELAY
                if( !wait_cycles[0] && bus_busy ) fail_cnt<=fail_cnt+1;
                if (!bus_busy && (!wait_cycles[0] || (fail_cnt!=0&&wait_cycles==3'b001) ) ) begin
                    DTACKn <= 1'b0;
                    if( wait_cycles[0] ) fail_cnt<=fail_cnt-1; // one bus cycle recovered
                end
            end
            else DTACKn <= 1'b0;
        end
        if( !LVBL && last_LVBL ) begin
            fail_cnt <= 24'd0;
            last_fail <= fail_cnt;
        end
    end
end 

`ifdef REPORT_DELAY
// Note that the data for the first frame may be wrong because
// of SDRAM initialization
real dly_cnt, ticks;
always @(posedge clk) begin
    if( !LVBL && last_LVBL ) begin
        ticks <= 0;
        dly_cnt <= 0;
        if( ticks ) $display("INFO: average CPU delay = %.2f ticks",dly_cnt/ticks);
    end else begin
        dly_cnt <= dly_cnt+fail_cnt;
        ticks <= ticks+1;
    end
end
`endif

// interrupt generation
reg        int1, // VBLANK
           int2; // ??
(*keep*) wire [2:0] FC;
assign inta_n = ~&{ FC[2], FC[1], FC[0], ~ASn }; // interrupt ack.

always @(posedge clk, posedge rst) begin : int_gen
    reg last_V256;
    if( rst ) begin
        int1 <= 1'b1;
        int2 <= 1'b1;
    end else begin
        last_LVBL <= LVBL;
        last_V256 <= V[8];

        if( !inta_n ) begin
            int1 <= 1'b1;
            int2 <= 1'b1;
        end
        else begin
            //if( V[8] && !last_V256 ) int2 <= 1'b0;
            if( !LVBL && last_LVBL ) int1 <= 1'b0;
        end
    end
end

assign busack = ~BGACKn;

jtframe_68kdma #(.BW(1)) u_arbitration(
    .clk        (  clk          ),
    .cen        ( cen10b        ),
    .rst        (  rst          ),
    .cpu_BRn    (  BRn          ),
    .cpu_BGACKn (  BGACKn       ),
    .cpu_BGn    (  BGn          ),
    .cpu_ASn    (  ASn          ),
    .cpu_DTACKn (  DTACKn       ),
    .dev_br     (  busreq       )
);

fx68k u_cpu(
    .clk        ( clk         ),
    .extReset   ( rst         ),
    .pwrUp      ( rst         ),
    .enPhi1     ( cen10       ),
    .enPhi2     ( cen10b      ),

    // Buses
    .eab        ( A           ),
    .iEdb       ( cpu_din     ),
    .oEdb       ( cpu_dout    ),


    .eRWn       ( RnW         ),
    .LDSn       ( LDSn        ),
    .UDSn       ( UDSn        ),
    .ASn        ( ASn         ),
    .VPAn       ( inta_n      ),
    .FC0        ( FC[0]       ),
    .FC1        ( FC[1]       ),
    .FC2        ( FC[2]       ),

    .BERRn      ( BERRn       ),
    // Bus arbitrion
    .HALTn      ( dip_pause   ),
    .BRn        ( BRn         ),
    .BGACKn     ( BGACKn      ),
    .BGn        ( BGn         ),

    .DTACKn     ( DTACKn      ),
    .IPL0n      ( 1'b1        ),
    .IPL1n      ( int1        ), // VBLANK
    .IPL2n      ( int2        ),

    // Unused
    .oRESETn    (             ),
    .oHALTEDn   (             ),
    .VMAn       (             ),
    .E          (             )
);

`ifdef SIMULATION
integer fdebug;

initial begin
    fdebug=$fopen("debug.log","w");
end

always @(posedge rom_cs) begin
    $fdisplay(fdebug,"%X",A_full);
end
`endif

endmodule