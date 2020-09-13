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
    Date: 28-1-2020 */
`timescale 1ns/1ps

module jtcps1_game(
    input           rst,
    input           clk,        // 96   MHz
    `ifdef JTFRAME_CLK96
    input           clk48,      // 48   MHz
    `endif
    output          pxl2_cen,   // 12   MHz
    output          pxl_cen,    //  6   MHz
    output   [7:0]  red,
    output   [7:0]  green,
    output   [7:0]  blue,
    output          LHBL_dly,
    output          LVBL_dly,
    output          HS,
    output          VS,
    // cabinet I/O
    input   [ 3:0]  start_button,
    input   [ 3:0]  coin_input,
    input   [ 9:0]  joystick1,
    input   [ 9:0]  joystick2,
    input   [ 9:0]  joystick3,
    input   [ 9:0]  joystick4,
    // SDRAM interface
    input           downloading,
    output          dwnld_busy,
    input           loop_rst,
    output          sdram_req,
    output  [21:0]  sdram_addr,
    input   [31:0]  data_read,
    output  [ 1:0]  sdram_wrmask,
    output  [ 1:0]  sdram_bank,
    output          sdram_rnw,
    output  [15:0]  data_write,
    input           data_rdy,
    input           sdram_ack,
    output          refresh_en,
    // ROM LOAD
    input   [24:0]  ioctl_addr,
    input   [ 7:0]  ioctl_data,
    input           ioctl_wr,
    output  [21:0]  prog_addr,
    output  [ 7:0]  prog_data,
    output  [ 1:0]  prog_mask,
    output  [ 1:0]  prog_bank,
    output          prog_we,
    output          prog_rd,
    // DIP switches
    input   [31:0]  status,     // only bits 31:16 are looked at
    input           dip_pause,
    inout           dip_flip,
    input           dip_test,
    input   [ 1:0]  dip_fxlevel, // Not a DIP on the original PCB    
    input   [31:0]  dipsw,
    // Sound output
    output  signed [15:0] snd_left,
    output  signed [15:0] snd_right,
    output          sample,
    input           enable_psg,
    input           enable_fm,
    // Debug
    input   [3:0]   gfx_en
);

localparam [21:0] SOUND_OFFSET = 22'h00_0000;
localparam [21:0] ADPCM_OFFSET = 22'h01_0000;
localparam [21:0] RAM_OFFSET   = 22'h20_0000;
localparam [21:0] VRAM_OFFSET  = 22'h30_0000;
localparam [21:0] GFX_OFFSET   = 22'h00_0000; // bank 2

// Support for 48MHz
// This is useful for faster simulation
`ifndef JTFRAME_CLK96
wire clk48 = clk;
`endif

wire        LHBL, LVBL; // internal blanking signals
wire        snd_cs, adpcm_cs, main_ram_cs, main_vram_cs, main_rom_cs,
            rom0_cs, rom1_cs,
            vram_dma_cs;
wire        HB, VB;
wire [15:0] snd_addr;
wire [17:0] adpcm_addr;
wire [ 7:0] snd_data, adpcm_data;
wire [17:1] ram_addr;
wire [21:1] main_rom_addr;
wire [21:0] main_ram_offset;
wire [15:0] main_ram_data, main_rom_data, main_dout, mmr_dout;
wire        main_rom_ok, main_ram_ok;
wire        ppu1_cs, ppu2_cs, ppu_rstn;
wire [19:0] rom1_addr, rom0_addr;
wire [31:0] rom0_data, rom1_data;
// Video RAM interface
wire [17:1] vram_dma_addr;
(*keep*) wire [15:0] vram_dma_data;
wire        vram_dma_ok, rom0_ok, rom1_ok, snd_ok, adpcm_ok;
wire [15:0] cpu_dout;
wire        cpu_speed;

wire        main_rnw, busreq, busack;
wire [ 7:0] snd_latch0, snd_latch1;
wire [ 7:0] dipsw_a, dipsw_b, dipsw_c;

wire [ 9:0] slot_cs, slot_ok, slot_wr, slot_clr, slot_active;
wire [ 8:0] hdump;
wire [ 8:0] vdump, vrender;

wire        rom0_half, rom1_half;
wire        cfg_we;
wire [21:0] gfx0_addr, gfx1_addr;

assign prog_rd    = 1'b0;
assign dwnld_busy = downloading;
assign slot_clr[8:0] = 9'd0;

assign slot_cs[0] = main_rom_cs;
assign slot_cs[1] = main_ram_cs | main_vram_cs;
assign slot_cs[2] = rom0_cs;
assign slot_cs[3] = 1'b0;
assign slot_cs[4] = 1'b0;
assign slot_cs[5] = adpcm_cs;
assign slot_cs[6] = rom1_cs;
assign slot_cs[7] = snd_cs;
assign slot_cs[8] = 1'b0;
assign slot_cs[9] = vram_dma_cs;

assign gfx0_addr = {rom0_addr, rom0_half, 1'b0 }; // OBJ
assign gfx1_addr = {rom1_addr, rom1_half, 1'b0 };

assign main_rom_ok = slot_ok[0];
assign main_ram_ok = slot_ok[1];
assign rom0_ok     = slot_ok[2];
assign adpcm_ok    = slot_ok[5];
assign rom1_ok     = slot_ok[6];
assign snd_ok      = slot_ok[7];
assign vram_dma_ok = slot_ok[9];

assign slot_wr[9:2] = 7'd0;
assign slot_wr[1]   = ~main_rnw;
assign slot_wr[0]   = 1'd0;

`ifndef SIMULATION
    assign { dipsw_c, dipsw_b, dipsw_a } = dipsw[23:0];
`else
assign { dipsw_c, dipsw_b, dipsw_a } = ~24'd0;
`endif
assign dip_flip = dipsw_c[4];  // this is correct for all games except Mega Man
    // but it does not matter for horizontal games

assign LVBL         = ~VB;
assign LHBL         = ~HB;

assign main_ram_offset = main_ram_cs ? RAM_OFFSET : VRAM_OFFSET; // selects RAM or VRAM

wire [ 1:0] dsn;
wire        cen16, cen8, cen10b, cen12;
wire        cpu_cen, cpu_cenb;
wire        charger;
wire        turbo;

`ifdef MISTER
 assign turbo = status[6];
 `else
 assign turbo = 0;
 `endif

// CPU clock enable signals come from 48MHz domain
jtframe_cen48 u_cen48(
    .clk        ( clk48         ),
    .cen16      ( cen16         ),
    .cen12      ( cen12         ),
    .cen8       ( cen8          ),
    .cen6       (               ),
    .cen4       (               ),
    .cen4_12    (               ),
    .cen3       (               ),
    .cen3q      (               ),
    .cen1p5     (               ),
    // 180 shifted signals
    .cen12b     (               ),
    .cen6b      (               ),
    .cen3b      (               ),
    .cen3qb     (               ),
    .cen1p5b    (               )
);

wire nc0, nc1;

`ifdef JTFRAME_CLK96
jtframe_cen96 u_pxl_cen(
    .clk    ( clk       ),    // 96 MHz
    .cen16  ( pxl2_cen  ),
    .cen8   ( pxl_cen   )
);
`else
assign pxl2_cen = cen16;
assign pxl_cen  = cen8;
`endif

jtcps1_cpucen u_cpucen(
    .clk        ( clk48              ),
    .cen12      ( cen12              ),
    .cpu_speed  ( cpu_speed | turbo  ),
    .cpu_cen    ( cpu_cen            ),
    .cpu_cenb   ( cpu_cenb           )
);

localparam REGSIZE=24;

jtcps1_prom_we #(
    .REGSIZE   ( REGSIZE       ),
    .CPU_OFFSET( 22'd0         ),
    .SND_OFFSET( SOUND_OFFSET  ),
    .OKI_OFFSET( ADPCM_OFFSET  ),
    .GFX_OFFSET( GFX_OFFSET    )
) u_prom_we(
    .clk            ( clk           ),
    .downloading    ( downloading   ),
    .ioctl_addr     ( ioctl_addr    ),
    .ioctl_data     ( ioctl_data    ),
    .ioctl_wr       ( ioctl_wr      ),
    .prog_addr      ( prog_addr     ),
    .prog_data      ( prog_data     ),
    .prog_mask      ( prog_mask     ),
    .prog_bank      ( prog_bank     ),
    .prog_we        ( prog_we       ),
    .sdram_ack      ( sdram_ack     ),
    .cfg_we         ( cfg_we        )
);

// Turbo speed disables DMA
wire busreq_cpu = busreq & ~turbo;
wire busack_cpu;
assign busack = busack_cpu | turbo;

`ifndef NOMAIN
jtcps1_main u_main(
    .rst        ( rst               ),
    .clk        ( clk48             ),
    .cen10      ( cpu_cen           ),
    .cen10b     ( cpu_cenb          ),
    .cpu_cen    (                   ),
    // Timing
    .V          ( vdump             ),
    .LVBL       ( LVBL              ),
    .LHBL       ( LHBL              ),
    // PPU
    .ppu1_cs    ( ppu1_cs           ),
    .ppu2_cs    ( ppu2_cs           ),
    .ppu_rstn   ( ppu_rstn          ),
    .mmr_dout   ( mmr_dout          ),
    // Sound
    .snd_latch0 ( snd_latch0        ),
    .snd_latch1 ( snd_latch1        ),
    .UDSWn      ( dsn[1]            ),
    .LDSWn      ( dsn[0]            ),
    // cabinet I/O
    // Cabinet input
    .charger     ( charger          ),
    .start_button( start_button[1:0]),
    .coin_input  ( coin_input[1:0]  ),
    .joystick1   ( joystick1        ),
    .joystick2   ( joystick2        ),
    .service     ( 1'b1             ),
    .tilt        ( 1'b1             ),
    // BUS sharing
    .busreq      ( busreq_cpu       ),
    .busack      ( busack_cpu       ),
    .RnW         ( main_rnw         ),
    // RAM/VRAM access
    .addr        ( ram_addr         ),
    .cpu_dout    ( main_dout        ),
    .ram_cs      ( main_ram_cs      ),
    .vram_cs     ( main_vram_cs     ),
    .ram_data    ( main_ram_data    ),
    .ram_ok      ( main_ram_ok      ),
    // ROM access
    .rom_cs      ( main_rom_cs      ),
    .rom_addr    ( main_rom_addr    ),
    .rom_data    ( main_rom_data    ),
    .rom_ok      ( main_rom_ok      ),
    // DIP switches
    .dip_pause   ( dip_pause        ),
    .dip_test    ( dip_test         ),
    .dipsw_a     ( dipsw_a          ),
    .dipsw_b     ( dipsw_b          ),
    .dipsw_c     ( dipsw_c          )
);
`else 
assign ram_addr = 17'd0;
assign main_ram_cs = 1'b0;
assign main_vram_cs = 1'b0;
assign main_rom_cs = 1'b0;
assign dsn = 2'b11;
assign main_rnw = 1'b1;
`endif

reg rst_video;

always @(negedge clk) begin
    rst_video <= rst;
end

jtcps1_video #(REGSIZE) u_video(
    .rst            ( rst_video     ),
    .clk            ( clk           ),
    .pxl2_cen       ( pxl2_cen      ),
    .pxl_cen        ( pxl_cen       ),

    .hdump          ( hdump         ),
    .vdump          ( vdump         ),
    .vrender        ( vrender       ),
    .gfx_en         ( gfx_en        ),
    .pause          ( ~dip_pause    ),
    .cpu_speed      ( cpu_speed     ),
    .charger        ( charger       ),

    // CPU interface
    .ppu_rstn       ( ppu_rstn      ),
    .ppu1_cs        ( ppu1_cs       ),
    .ppu2_cs        ( ppu2_cs       ),
    .addr           ( ram_addr[5:1] ),
    .dsn            ( dsn           ),      // data select, active low
    .cpu_dout       ( main_dout     ),
    .mmr_dout       ( mmr_dout      ),
    // BUS sharing
    .busreq         ( busreq        ),
    .busack         ( busack        ),

    // Video signal
    .HS             ( HS            ),
    .VS             ( VS            ),
    .HB             ( HB            ),
    .VB             ( VB            ),
    .LHBL_dly       ( LHBL_dly      ),
    .LVBL_dly       ( LVBL_dly      ),
    .red            ( red           ),
    .green          ( green         ),
    .blue           ( blue          ),

    // CPS-B Registers
    .cfg_we         ( cfg_we        ),
    .cfg_data       ( prog_data     ),

    // Extra inputs read through the C-Board
    .start_button   ( start_button  ),
    .coin_input     ( coin_input    ),
    .joystick1      ( joystick1     ),
    .joystick2      ( joystick2     ),
    .joystick3      ( joystick3     ),
    .joystick4      ( joystick4     ),

    // Video RAM interface
    .vram_dma_addr  ( vram_dma_addr ),
    .vram_dma_data  ( vram_dma_data ),
    .vram_dma_ok    ( vram_dma_ok   ),
    .vram_dma_cs    ( vram_dma_cs   ),
    .vram_dma_clr   ( slot_clr[9]   ),

    // GFX ROM interface
    .rom1_addr      ( rom1_addr     ),
    .rom1_half      ( rom1_half     ),
    .rom1_data      ( rom1_data     ),
    .rom1_cs        ( rom1_cs       ),
    .rom1_ok        ( rom1_ok       ),
    .rom0_addr      ( rom0_addr     ),
    .rom0_half      ( rom0_half     ),
    .rom0_data      ( rom0_data     ),
    .rom0_cs        ( rom0_cs       ),
    .rom0_ok        ( rom0_ok       )
);

`ifndef NOSOUND
`ifdef FAKE_LATCH
integer snd_frame_cnt=0;
reg [7:0] fake_latch = 8'hff;
assign snd_latch1 = 8'd0;
assign snd_latch0 = fake_latch;
localparam FAKE0=10;
localparam FAKE1=1000;
always @(posedge VB) begin
    snd_frame_cnt <= snd_frame_cnt+1;
    case( snd_frame_cnt )
        /* ffight
        FAKE0: fake_latch <= 8'hf0;
        FAKE0+5+2: fake_latch <= 8'hf7;
        FAKE0+5+4: fake_latch <= 8'hf2;
        FAKE0+5+6: fake_latch <= 8'h55;
        default: fake_latch <= 8'hff;
        */
        // Nemo
        //FAKE0: fake_latch <= 8'h2;
        //FAKE0+1: fake_latch <= 8'h2;
        //FAKE0+2: fake_latch <= 8'h0;
        // KOD
        FAKE0: fake_latch <= 8'h6;
        // Magic Sword
        //FAKE0: fake_latch <= 8'h1e;
        //FAKE1: fake_latch <= 8'h0;
        //FAKE1+1: fake_latch <= 8'h4;
        //FAKE1+2: fake_latch <= 8'h0;

        default: fake_latch <= 8'hff;
    endcase
end
`endif

(*keep*) reg [3:0] rst_snd;
always @(negedge clk48) begin
    rst_snd <= { rst_snd[2:0], rst };
end

jtcps1_sound u_sound(
    .rst            ( rst_snd[3]    ),
    .clk            ( clk48         ),    

    .enable_adpcm   ( enable_psg    ),
    .enable_fm      ( enable_fm     ),

    // Interface with main CPU
    .snd_latch0     ( snd_latch0    ),
    .snd_latch1     ( snd_latch1    ),
    
    // ROM
    .rom_addr       ( snd_addr      ),
    .rom_cs         ( snd_cs        ),
    .rom_data       ( snd_data      ),
    .rom_ok         ( snd_ok        ),

    // ADPCM ROM
    .adpcm_addr     ( adpcm_addr    ),
    .adpcm_cs       ( adpcm_cs      ),
    .adpcm_data     ( adpcm_data    ),
    .adpcm_ok       ( adpcm_ok      ),

    // Sound output
    .left           ( snd_left      ),
    .right          ( snd_right     ),
    .sample         ( sample        )
);
`else 
assign snd_addr   = 16'd0;
assign snd_cs     = 1'b0;
assign snd_left   = 16'd0;
assign snd_right  = 16'd0;
assign adpcm_addr = 18'd0;
assign adpcm_cs   = 1'b0;
assign sample   = 1'b0;
`endif

reg rst_sdram;

always @(negedge clk) begin
    rst_sdram <= rst;
end

assign sdram_bank = slot_active[0] ? 2'b01 :    // CPU goes in bank 1
    ( slot_active[2] | slot_active[6] ? 2'b10 : // GFX goes in bank 2
    2'b00 );                                    // Sound in bank 0

jtframe_sdram_mux #(
    // Main CPU
    .SLOT0_AW   ( 21    ),  // Max 4 Megabytes
    .SLOT1_AW   ( 17    ),  // 64 kB RAM, 192 kB VRAM

    .SLOT0_DW   ( 16    ),
    .SLOT1_DW   ( 16    ),   

    .SLOT1_TYPE ( 2     ), // R/W access
    
    // Sound
    .SLOT5_AW   ( 18    ),  // ADPCM
    .SLOT5_DW   (  8    ),

    .SLOT7_AW   ( 16    ),
    .SLOT7_DW   (  8    ),

    // VRAM read access:
    .SLOT9_AW   ( 17    ),  // OBJ VRAM
    .SLOT9_DW   ( 16    ),

    // GFX ROM
    .SLOT2_AW   ( 22    ),  // OBJ VRAM
    .SLOT6_AW   ( 22    ),  //6

    .SLOT2_DW   ( 32    ),
    .SLOT6_DW   ( 32    )
)
u_sdram_mux(
    .rst            ( rst_sdram     ),
    .clk            ( clk           ),
    .vblank         ( VB            ),

    // Main CPU
    .slot0_offset   ( 22'd0             ),
    .slot0_addr     ( main_rom_addr     ),
    .slot0_dout     ( main_rom_data     ),

    .slot1_offset   ( main_ram_offset   ),
    .slot1_addr     ( ram_addr          ),
    .slot1_dout     ( main_ram_data     ),
    .slot1_din      ( main_dout         ),
    .slot1_wrmask   ( dsn               ),

    // Sound
    .slot7_offset   ( SOUND_OFFSET      ),
    .slot7_addr     ( snd_addr          ),
    .slot7_dout     ( snd_data          ),

    .slot5_offset   ( ADPCM_OFFSET      ),
    .slot5_addr     ( adpcm_addr        ),
    .slot5_dout     ( adpcm_data        ),
    // VRAM read access only
    .slot9_offset   ( VRAM_OFFSET       ),
    .slot9_addr     ( vram_dma_addr     ),
    .slot9_dout     ( vram_dma_data     ),

    // GFX ROM
    .slot2_offset   ( GFX_OFFSET        ),
    .slot2_addr     ( gfx0_addr         ),  // objects
    .slot2_dout     ( rom0_data         ),

    .slot6_offset   ( GFX_OFFSET        ),
    .slot6_addr     ( gfx1_addr         ),  // scroll tiles
    .slot6_dout     ( rom1_data         ),

    // bus signals
    .slot_cs        ( slot_cs           ),
    .slot_ok        ( slot_ok           ),
    .slot_wr        ( slot_wr           ),
    .slot_clr       ( slot_clr          ),
    .slot_active    ( slot_active       ),

    // SDRAM controller interface
    .downloading    ( downloading       ),
    .loop_rst       ( loop_rst          ),
    .sdram_ack      ( sdram_ack         ),
    .sdram_req      ( sdram_req         ),
    .refresh_en     ( refresh_en        ),
    .sdram_addr     ( sdram_addr        ),
    .sdram_rnw      ( sdram_rnw         ),
    .sdram_wrmask   ( sdram_wrmask      ),
    .data_rdy       ( data_rdy          ),
    .data_read      ( data_read         ),   
    .data_write     ( data_write        ),

    // Unused
    .slot3_dout     (                   ),
    .slot4_dout     (                   ),
    .slot8_dout     (                   ),
    .ready          (                   ),
    .slot3_addr     (                   ),
    .slot4_addr     (                   ),
    .slot8_addr     (                   ),
    .slot3_offset   (                   ),
    .slot4_offset   (                   ),
    .slot8_offset   (                   ),
    .slot0_din      (                   ),
    .slot2_din      (                   ),
    .slot3_din      (                   ),
    .slot4_din      (                   ),
    .slot5_din      (                   ),
    .slot6_din      (                   ),
    .slot7_din      (                   ),
    .slot8_din      (                   ),
    .slot9_din      (                   )    
);

endmodule
