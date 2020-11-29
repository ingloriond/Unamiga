/*  This file is part of JTBUBL.
    JTBUBL program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTBUBL program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTBUBL.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 1-06-2020 */

module jtbubl_main(
    input               rst,
    input               clk24,
    input               cen12,
    input               cen6,
    input               cen4,

    // game selection
    input               tokio,
    // Cabinet inputs
    input      [ 1:0]   start_button,
    input      [ 1:0]   coin_input,
    input      [ 5:0]   joystick1,
    input      [ 5:0]   joystick2,

    // Video interface
    output reg          vram_cs,
    output reg          pal_cs,
    output reg          black_n,
    output reg          flip,
    output     [12:0]   cpu_addr,
    output     [ 7:0]   cpu_dout,
    output              cpu_rnw,
    input      [ 7:0]   vram_dout,
    input      [ 7:0]   pal_dout,
    input               LVBL,

    // Sound interface
    input      [ 7:0]   main_latch,
    output reg [ 7:0]   snd_latch,
    output reg          snd_stb,
    input               snd_flag,
    input               main_stb,
    output              main_flag,
    output reg          snd_rstn, // active high

    // Main CPU ROM interface
    output     [17:0]   main_rom_addr,
    output reg          main_rom_cs,
    input               main_rom_ok,
    input      [ 7:0]   main_rom_data,

    // Sub CPU ROM interface
    output     [14:0]   sub_rom_addr,
    output reg          sub_rom_cs,
    input               sub_rom_ok,
    input      [ 7:0]   sub_rom_data,

    // MCU ROM interface
    output     [11:0]   mcu_rom_addr,
    output              mcu_rom_cs,
    input               mcu_rom_ok,
    input      [ 7:0]   mcu_rom_data,

    // DIP switches
    input               dip_pause,
    input      [ 7:0]   dipsw_a,
    input      [ 7:0]   dipsw_b
);

reg  [ 7:0] main_din, sub_din;
wire [ 7:0] ram2main, ram2sub, main_dout, sub_dout,
            rammcu2main, rammcu2mcu,
            p1_in,
            p1_out, p2_out, p3_out, p4_out;
reg  [ 7:0] p3_in, rammcu_din;
reg  [ 7:0] cab_dout;
reg         h1;
wire [11:0] mcu_bus;
wire [15:0] main_addr, sub_addr, mcu_addr;
wire        main_mreq_n, main_iorq_n, main_rdn, main_wrn, main_rfsh_n;
wire        sub_mreq_n,  sub_iorq_n,  sub_rd_n,  sub_wrn;
reg         rammcu_we, rammcu_cs;
reg         main_work_cs, mcram_cs, // shared memories
            tres_cs,  // watchdog reset
            main2sub_nmi,
            misc_cs, sound_cs,
            cabinet_cs, flip_cs;
reg         sub_work_cs;
wire        mcram_we, sub_int_n, main_int_n,
            mcu_vma;
reg  [ 2:0] bank;
reg         main_rst_n, sub_rst_n, mcu_rst;
reg  [ 7:0] wdog_cnt, int_vector;
reg         last_VBL;

reg  [ 7:0] work_din;
reg  [12:0] work_addr;
reg         work_we;
wire [ 7:0] work_dout;

reg  [ 7:0] comm_din, comm2main, comm2mcu;
reg  [ 9:0] comm_addr;
reg         comm_we;
wire [ 7:0] comm_dout;

wire        lrom_wait_n, srom_wait_n;
reg         lwaitn, swaitn;
wire        main_halt_n;
reg         main_wait_n, sub_wait_n;
reg         lde, sde; // original signal names: lde = main drives, sde = sub drives
wire        VBL_gated;

assign      VBL_gated    = ~LVBL & dip_pause;
assign      main_rom_addr = main_addr[15] ?
                        { { {1'b0, bank}+4'b10} , main_addr[13:0] } : // banked
                        { 3'd0, main_addr[14:0] }; // not banked
assign      sub_rom_addr = sub_addr[14:0];
assign      mcram_we     = mcram_cs && !main_wrn;
assign      cpu_addr     = main_addr[12:0];
assign      cpu_dout     = main_dout;
assign      cpu_rnw      = main_wrn;
assign      p1_in[7:4]   = 4'hf;
assign      p1_in[3:2]   = ~coin_input;
assign      p1_in[1:0]   = 2'b11;
assign      mcu_bus      = { p2_out[3:0], p4_out };

// Watchdog and main CPU reset
always @(posedge clk24, posedge rst) begin
    if( rst ) begin
        main_rst_n <= 0;
        wdog_cnt   <= 8'd0;
    end else begin
        last_VBL  <= VBL_gated;
        if( tres_cs )
            wdog_cnt <= 8'd0;
        else if( !VBL_gated && last_VBL ) wdog_cnt <= wdog_cnt + 8'd1;
        //main_rst_n <= ~wdog_cnt[7];
        main_rst_n <= 1;
    end
end

// Main CPU address decoder
always @(*) begin
    main_rom_cs    = !main_mreq_n && (!main_addr[15] || main_addr[15:14]==2'b10); // 0000-7FFF and 8000-BFFF
    vram_cs        = !main_mreq_n && main_addr[15:13]==3'b110; // C000-DCFF
    main_work_cs   = !main_mreq_n && main_addr[15:13]==3'b111 && main_addr[12:11]!=2'b11; //E000-F7FF
    pal_cs         = !main_mreq_n && main_addr[15: 9]==7'b1111_100; // F800-F9FF
    if( tokio ) begin
        sound_cs    = !main_mreq_n && main_addr[15: 8]==8'hFC && !main_addr[7];
        misc_cs     = !main_mreq_n && main_addr[15: 8]==8'hFA &&  main_addr[7] && !main_wrn;
        flip_cs     = !main_mreq_n && main_addr[15: 8]==8'hFB && !main_addr[7] && !main_wrn;
        main2sub_nmi= !main_mreq_n && main_addr[15: 8]==8'hFB &&  main_addr[7] && !main_wrn;
        tres_cs     = !main_mreq_n && main_addr[15: 8]==8'hFA && !main_addr[7]; // watchdog
        mcram_cs    = !main_mreq_n && main_addr[15: 9]==7'b1111_111; // FE
        cabinet_cs  = !main_mreq_n && main_addr[15: 7]==9'b1111_1010_0 && main_wrn;
    end else begin // Bubble Bobble
        sound_cs    = !main_mreq_n && main_addr[15: 8]==8'hFA && !main_addr[7];
        misc_cs     = !main_mreq_n && main_addr[15: 8]==8'hFB && main_addr[7:6]==2'b01 && !main_wrn;
        flip_cs     = 0; // misc_cs used instead
        main2sub_nmi= !main_mreq_n && main_addr[15: 8]==8'hFB && main_addr[7:6]==2'b00 && !main_wrn;
        tres_cs     = !main_mreq_n && main_addr[15: 8]==8'hFA && main_addr[7];
        mcram_cs    = !main_mreq_n && main_addr[15:10]==6'b1111_11; // FC
    end
end

// Main CPU input mux
always @(posedge clk24) begin
    main_din <=
        main_rom_cs ? main_rom_data : (
        vram_cs     ? vram_dout     : (
        pal_cs      ? pal_dout      : (
        main_work_cs? work_dout     : (
        mcram_cs    ? (tokio ? 8'hbf : comm2main ) : (
        !main_iorq_n? int_vector    : (
        sound_cs    ? (
            main_addr[0] ? { 6'h3f, main_flag, snd_flag } : main_latch ) :(
        cabinet_cs  ? cab_dout
        : 8'hff )))))));
end

// Main CPU miscellaneous control bits
always @(posedge clk24 ) begin
    if( !main_rst_n ) begin
        bank      <= 3'd0;
        sub_rst_n <= 0;
        mcu_rst   <= 1;
        black_n   <= 0;
        flip      <= 0;
    end else begin
        if(misc_cs) begin
            bank      <= tokio ? cpu_dout[2:0] : (cpu_dout[2:0]^3'b100);
            black_n   <= cpu_dout[6];
            if(!tokio) begin
                sub_rst_n <= cpu_dout[4];
                mcu_rst   <= ~cpu_dout[5];
            end else begin
                sub_rst_n <= 1;
                mcu_rst   <= 1;
            end
        end
        if( tokio ? flip_cs : misc_cs )
            flip <= cpu_dout[7];
    end
end

// Communication with sound CPU
always @(posedge clk24 ) begin
    if( !main_rst_n ) begin
        snd_latch <= 8'd0;
        snd_rstn  <= 1;     // Sound CPU starts up
        snd_stb   <= 0;
    end else if(sound_cs) begin
        snd_stb <= !main_wrn && cpu_addr[1:0]==2'b00;
        if( !main_wrn )
            case( cpu_addr[1:0] )
                2'b00: snd_latch <= main_dout;
                2'b11: snd_rstn  <= ~main_dout[0];
            endcase
    end else snd_stb <= 0;
end

jtframe_ff u_flag(
    .clk    ( clk24                  ),
    .rst    ( main_rst_n             ),
    .cen    ( 1'b1                   ),
    .din    ( 1'b0                   ),
    .q      (                        ),
    .qn     ( main_flag              ),
    .set    ( sound_cs && !main_rdn  ),
    .clr    ( 1'b0                   ),
    .sigedge( main_stb               )
);

// Sub CPU address decoder
always @(*) begin
    sub_rom_cs     = !sub_mreq_n && !sub_addr[15];
    if(tokio)
        sub_work_cs    = !sub_mreq_n &&  sub_addr[15:13]==3'b100;
    else // Bubble Bobble
        sub_work_cs    = !sub_mreq_n &&  sub_addr[15:13]==3'b111;
end

// Sub CPU input mux
always @(posedge clk24) begin
    sub_din <= sub_rom_cs  ? sub_rom_data : (
               sub_work_cs ? work_dout : 8'hff );
end

always @(*) begin
    work_din = lde ? main_dout : sub_dout;
    work_we  = lde ? ~main_wrn : ~sub_wrn;
    work_addr= lde ? main_addr[12:0] : sub_addr[12:0];
end

// Time shared
jtframe_ram #(.aw(13)) u_work(
    .clk    ( clk24           ),
    .cen    ( 1'b1            ),
    .data   ( work_din        ),
    .addr   ( work_addr       ),
    .we     ( work_we         ),
    .q      ( work_dout       )
);

/////////////////////////////////////////
// Main CPU

// H1 is used on the original PCB to divide access to the
// video memory
// When H1 is high, the main CPU is forced to wait before
// accessing the VRAM

always @(posedge clk24, posedge rst) begin
    if( rst )
        h1 <= 0;
    else if(cen6) h1<=~h1;
end

always @(*) begin
    lwaitn = ~( sde & main_work_cs );
    swaitn = ~( lde & sub_work_cs  );
    main_wait_n = lwaitn & lrom_wait_n & ~(vram_cs&h1);
    sub_wait_n  = swaitn & srom_wait_n;
end

always @(posedge clk24, negedge main_rst_n) begin
    if( !main_rst_n )
        lde <= 0;
    else begin
        lde <= main_work_cs;
    end
end

always @(posedge clk24, negedge sub_rst_n) begin
    if( !sub_rst_n )
        sde <= 0;
    else begin
        if( !sub_work_cs )
            sde <= 0;
        else if( !main_work_cs ) sde <= 1;
    end
end

jtframe_z80 u_maincpu(
    .rst_n    ( main_rst_n     ),
    .clk      ( clk24          ),
    .cen      ( cen6           ),
    .wait_n   ( main_wait_n    ),
    .int_n    ( main_int_n     ),
    .nmi_n    ( 1'b1           ),
    .busrq_n  ( 1'b1           ),
    .m1_n     (                ),
    .mreq_n   ( main_mreq_n    ),
    .iorq_n   ( main_iorq_n    ),
    .rd_n     ( main_rdn       ),
    .wr_n     ( main_wrn       ),
    .rfsh_n   ( main_rfsh_n    ),
    .halt_n   ( main_halt_n    ),
    .busak_n  (                ),
    .A        ( main_addr      ),
    .din      ( main_din       ),
    .dout     ( main_dout      )
);

jtframe_rom_wait u_mainwait(
    .rst_n    ( main_rst_n      ),
    .clk      ( clk24           ),
    .cen_in   (                 ),
    .cen_out  (                 ),
    .gate     ( lrom_wait_n     ),
    // manage access to ROM data from SDRAM
    .rom_cs   ( main_rom_cs     ),
    .rom_ok   ( main_rom_ok     )
);

/////////////////////////////////////////
// Sub CPU

jtframe_z80 u_subcpu(
    .rst_n    ( sub_rst_n      ),
    .clk      ( clk24          ),
    .cen      ( cen6           ),
    .wait_n   ( sub_wait_n     ),
    .int_n    ( sub_int_n      ),
    .nmi_n    ( ~main2sub_nmi  ),
    .busrq_n  ( 1'b1           ),
    .m1_n     (                ),
    .mreq_n   ( sub_mreq_n     ),
    .iorq_n   ( sub_iorq_n     ),
    .rd_n     ( sub_rd_n       ),
    .wr_n     ( sub_wrn        ),
    .rfsh_n   (                ),
    .halt_n   (                ),
    .busak_n  (                ),
    .A        ( sub_addr       ),
    .din      ( sub_din        ),
    .dout     ( sub_dout       )
);

jtframe_rom_wait u_subwait(
    .rst_n    ( sub_rst_n       ),
    .clk      ( clk24           ),
    .cen_in   (                 ),
    .cen_out  (                 ),
    .gate     ( srom_wait_n     ),
    // manage access to ROM data from SDRAM
    .rom_cs   ( sub_rom_cs      ),
    .rom_ok   ( sub_rom_ok      )
);

jtframe_ff u_subint(
    .rst    ( ~sub_rst_n    ),
    .clk    ( clk24         ),
    .cen    ( 1'b1          ),
    .din    ( 1'b1          ),
    .q      (               ),
    .qn     ( sub_int_n     ),
    .set    ( 1'b0          ),
    .clr    ( ~sub_iorq_n   ),
    .sigedge( VBL_gated     )
);

/////////////////////////////////////////
// MCU

jtframe_ff u_mcu2main (
    .clk    ( clk24          ),
    .rst    ( tokio ? ~main_rst_n : mcu_rst ),
    .cen    ( 1'b1           ),
    .din    ( 1'b1           ),
    .q      (                ),
    .qn     ( main_int_n     ),
    .set    ( 1'b0           ),
    .clr    ( ~main_iorq_n   ),
    // This is a jumper on the schematics
    // it can come from P1[6] or from VBL
    .sigedge( tokio ? VBL_gated : p1_out[6] )
);

always @(posedge clk24) begin
    if( cen12 ) begin
        if(cen6) begin
            comm_addr <= main_addr[9:0];
            comm_we   <= mcram_we;
            comm_din  <= main_dout;
            comm2mcu  <= comm_dout;
        end else begin
            comm_addr <= mcu_bus[9:0];
            comm_we   <= rammcu_we;
            comm_din  <= rammcu_din;
            comm2main <= comm_dout;
        end
    end
end

// Time shared
jtframe_ram #(.aw(10)) u_comm(
    .clk    ( clk24            ),
    .cen    ( 1'b1             ),
    .data   ( comm_din         ),
    .addr   ( comm_addr        ),
    .we     ( comm_we          ),
    .q      ( comm_dout        )
);

// Bubble Bobble handles the input ports via the MCU
always @(posedge clk24) begin
    if( rammcu_cs )
        p3_in <= comm2mcu;
    else begin
        case( mcu_bus[1:0] )
            2'd0: p3_in <= dipsw_a;
            2'd1: p3_in <= dipsw_b;
            2'd2: p3_in <= {1'b1, start_button[0], joystick1[4], joystick1[5], joystick1[3:2], joystick1[0], joystick1[1] };
            2'd3: p3_in <= {1'b1, start_button[1], joystick2[4], joystick2[5], joystick2[3:2], joystick2[0], joystick2[1] };
        endcase // mcu_bus[1:0]
    end
end

// This is used for Tokio
always @(posedge clk24) begin
    case( main_addr[2:0] )
        3'd3: cab_dout <= dipsw_a;
        3'd4: cab_dout <= dipsw_b;
        3'd5: cab_dout <= {2'b11, 2'b11 /* MCU related */, coin_input, 2'b11 };
        3'd6: cab_dout <= {1'b1, start_button[0], joystick1[4], joystick1[5], joystick1[3:2], joystick1[0], joystick1[1] };
        3'd7: cab_dout <= {1'b1, start_button[1], joystick2[4], joystick2[5], joystick2[3:2], joystick2[0], joystick2[1] };
        default: cab_dout <= 8'hff;
    endcase
end

reg [3:0] clrcnt;
reg       last_sub_int_n;
reg       mcuirq;

wire      cen_mcu = cen4;

always @(posedge clk24) begin
    if( mcu_rst ) begin
        clrcnt <= 4'd0;
        last_sub_int_n <= 1;
        mcuirq <= 0;
    end else if(cen_mcu) begin
        last_sub_int_n <= sub_int_n;
        if( last_sub_int_n && !sub_int_n ) begin
            clrcnt <= 4'd0;
            mcuirq <= 1;
        end else if(mcuirq) begin
            clrcnt<=clrcnt+4'd1;
            if(&clrcnt) mcuirq<=0;
        end
    end
end

wire rammcu_clk = p2_out[4];
reg  last_rammcu_clk;
wire mcu_posedge = !last_rammcu_clk && rammcu_clk;

always @(posedge clk24) begin
    if( mcu_rst ) begin
        rammcu_cs       <= 0;
        rammcu_we       <= 0;
        last_rammcu_clk <= 1;
        rammcu_din      <= 8'd0;
        int_vector      <= 8'h2e;
    end else if(cen_mcu) begin
        last_rammcu_clk <= rammcu_clk;
        if( mcu_posedge ) begin
            if( mcu_bus[11:10]==2'b11 ) begin
                rammcu_cs  <= 1;
                rammcu_we  <= !p1_out[7];
                rammcu_din <= p3_out;
                if( mcu_bus[9:0]==10'd0 ) int_vector <= p3_out;
            end else begin
                rammcu_cs <= 0;
                rammcu_we <= 0;
            end
        end else begin
            //rammcu_cs <= 0;
            rammcu_we <= 0;
        end
    end
end

jtframe_6801mcu #(.MAXPORT(7)) u_mcu (
    .rst        ( mcu_rst       ),
    //.rst( rst ), // for quick sims
    .clk        ( clk24         ),
    .cen        ( cen_mcu       ),  // this should be cen4, but let's start easy
    .wrn        (               ),
    .vma        ( mcu_vma       ),
    .addr       ( mcu_addr      ),
    .dout       (               ),
    .halt       ( 1'b0          ),
    .halted     (               ),
    .irq        ( mcuirq        ), // relies on sub CPU to clear it
    .nmi        ( 1'b0          ),
    // Ports
    .p1_in      ( p1_in         ),
    .p1_out     ( p1_out        ),
    .p2_in      ( 8'hff         ), // feed back p2_out for sims
    .p2_out     ( p2_out        ),
    .p3_in      ( p3_in         ),
    .p3_out     ( p3_out        ),
    .p4_in      ( 8'hff         ), // feed back p4_out for sims
    .p4_out     ( p4_out        ),
    // external RAM
    .ext_cs     ( 1'b0          ),
    .ext_dout   (               ),
    // ROM interface
    .rom_addr   ( mcu_rom_addr  ),
    .rom_data   ( mcu_rom_data  ),
    .rom_cs     ( mcu_rom_cs    ),
    .rom_ok     ( mcu_rom_ok    )
);

endmodule