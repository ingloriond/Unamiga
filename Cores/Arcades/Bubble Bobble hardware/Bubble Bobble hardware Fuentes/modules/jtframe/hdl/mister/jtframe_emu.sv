//============================================================================
//  JTFRAME by Jose Tejada Gomez. Twitter: @topapate
//
//  Port to MiSTer
//  Thanks to Sorgelig for his continuous support
//  Original repository: http://github.com/jotego/jt_gng
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

`timescale 1ns/1ps

module emu
(
    //Master input clock
    input         CLK_50M,

    //Async reset from top-level module.
    //Can be used as initial reset.
    input         RESET,

    //Must be passed to hps_io module
    inout  [45:0] HPS_BUS,

    //Base video clock. Usually equals to CLK_SYS.
    output        VGA_CLK,

    //Multiple resolutions are supported using different VGA_CE rates.
    //Must be based on CLK_VIDEO
    output        VGA_CE,

    output  [7:0] VGA_R,
    output  [7:0] VGA_G,
    output  [7:0] VGA_B,
    output        VGA_HS,
    output        VGA_VS,
    output        VGA_DE,    // = ~(VBlank | HBlank)
    output        VGA_F1,

    //Base video clock. Usually equals to CLK_SYS.
    output        HDMI_CLK,

    //Multiple resolutions are supported using different HDMI_CE rates.
    //Must be based on CLK_VIDEO
    output        HDMI_CE,

    output  [7:0] HDMI_R,
    output  [7:0] HDMI_G,
    output  [7:0] HDMI_B,
    output        HDMI_HS,
    output        HDMI_VS,
    output        HDMI_DE,   // = ~(VBlank | HBlank)
    output  [1:0] HDMI_SL,   // scanlines fx

    //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
    output  [7:0] HDMI_ARX,
    output  [7:0] HDMI_ARY,

    output        LED_USER,  // 1 - ON, 0 - OFF.

    // b[1]: 0 - LED status is system status OR'd with b[0]
    //       1 - LED status is controled solely by b[0]
    // hint: supply 2'b00 to let the system control the LED.
    output  [1:0] LED_POWER,
    output  [1:0] LED_DISK,

    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,
    output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned

    //SDRAM interface with lower latency
    output        SDRAM_CLK,
    output        SDRAM_CKE,
    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE,

    // Open-drain User port.
    // 0 - D+/RX
    // 1 - D-/TX
    // 2..6 - USR2..USR6
    // Set USER_OUT to 1 to read from USER_IN.
    input   [6:0] USER_IN,
    output  [6:0] USER_OUT
    `ifdef SIMULATION
    ,output         sim_pxl_cen,
    output          sim_pxl_clk,
    output          sim_vb,
    output          sim_hb
    `endif
);

// Config string
`include "build_id.v"
`define SEPARATOR "-;",

`ifdef SIMULATION
localparam CONF_STR="JTGNG;;";
`else
localparam CONF_STR = {
    `CORENAME,";;",
    "OOR,CRT H adjust,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "OSV,CRT V adjust,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
    // Common MiSTer options
    `ifndef JTFRAME_OSD_NOLOAD
    "F,rom;",
    `endif
    "H0OB,Aspect Ratio,Original,Wide;",
    `ifdef VERTICAL_SCREEN
        `ifdef JTFRAME_OSD_FLIP
        "O1,Flip screen,Off,On;",
        `endif
    "O2,Rotate screen,Yes,No;",
    `endif
    "O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",

    `ifndef NOSOUND
        // sound OSD options are ommitted for compilations without sound
        `ifdef JT12
        "O8,PSG,On,Off;",
        "O9,FM ,On,Off;",
        "O67,FX volume, high, very high, very low, low;",
        `else
            `ifdef JTFRAME_ADPCM
            "O8,ADPCM,On,Off;",
            `endif
            `ifdef JT51
            "O9,FM ,On,Off;",
            `endif
        `endif
    `endif
    `ifdef JTFRAME_OSD_TEST
    "OA,Test mode,Off,On;",
    `endif
    `SEPARATOR    
    `ifdef JTFRAME_MRA_DIP
    "DIP;",
    `endif
    `ifdef CORE_OSD
    `CORE_OSD
    `endif
    `SEPARATOR
    "R0,Reset;",
    `ifndef JTFRAME_OSD_NOCREDITS
    "OC,Credits,Off,On;",
    `endif
    `ifdef CORE_KEYMAP
    `CORE_KEYMAP
    `endif
    "V,v",`BUILD_DATE," jotego;"
};
`endif

`undef SEPARATOR

`ifndef JTFRAME_INTERLACED
assign VGA_F1=1'b0;
`else
wire   field;
assign VGA_F1=field;
`endif
assign USER_OUT = '1;

wire [3:0] hoffset, voffset;

////////////////////   CLOCKS   ///////////////////

wire clk_sys, clk_rom, clk96, clk96sh, clk48, clk48sh, clk24, clk6;
wire pxl2_cen, pxl_cen;
wire pll_locked;
reg  pll_rst = 1'b0;

// Resets the PLL if it looses lock
always @(posedge clk_sys or posedge RESET) begin : pll_controller
    reg last_locked;
    reg [7:0] rst_cnt;

    if( RESET ) begin
        pll_rst <= 1'b0;
        rst_cnt <= 8'hd0;
    end else begin
        last_locked <= pll_locked;
        if( last_locked && !pll_locked ) begin
            rst_cnt <= 8'hff; // keep reset high for 256 cycles
            pll_rst <= 1'b1;
        end else begin
            if( rst_cnt != 8'h00 )
                rst_cnt <= rst_cnt - 8'h1;
            else
                pll_rst <= 1'b0;
        end
    end
end

pll pll(
    .refclk     ( CLK_50M    ),
    .rst        ( pll_rst    ),
    .locked     ( pll_locked ),
    .outclk_0   ( clk48      ),
    .outclk_1   ( clk48sh    ),
    .outclk_2   ( clk24      ),
    .outclk_3   ( clk6       ),
    .outclk_4   ( clk96      ),
    .outclk_5   ( clk96sh    )
);


`ifndef JTFRAME_CLK96
assign clk_sys   = clk48;
assign clk_rom   = clk48;
assign SDRAM_CLK = clk48sh;
`else
assign clk_sys   = clk96; // clk48 can be used but video mixer may fail for some modes
assign clk_rom   = clk96;
assign SDRAM_CLK = clk96sh;
`endif

///////////////////////////////////////////////////

wire [31:0] status;
wire [ 1:0] buttons;

wire [ 1:0] dip_fxlevel;
wire        enable_fm, enable_psg;
wire        dip_pause, dip_flip, dip_test;
wire [31:0] dipsw;

wire        ioctl_rom_wr;
wire [24:0] ioctl_addr;
wire [ 7:0] ioctl_data;

wire [ 9:0] game_joy1, game_joy2, game_joy3, game_joy4;
wire [ 3:0] game_coin, game_start;
wire [ 3:0] gfx_en;
wire [15:0] joystick_analog_0, joystick_analog_1;

wire        downloading, game_rst, rst, rst_n, dwnld_busy;
wire        rst_req   = RESET | status[0] | buttons[1];

assign LED_DISK  = 2'b0;
assign LED_POWER = 2'b0;

// SDRAM
wire         loop_rst;
wire         sdram_req;
wire [31:0]  data_read;
wire [21:0]  sdram_addr;
wire         data_rdy;
wire         sdram_ack;
wire         refresh_en;

wire [ 1:0]   sdram_wrmask, sdram_bank;
wire          sdram_rnw;
wire [15:0]   data_write;

`ifndef JTFRAME_WRITEBACK
assign sdram_wrmask = 2'b11;
assign sdram_rnw    = 1'b1;
assign data_write   = 16'h00;
`endif

wire         prog_we, prog_rd;
wire [21:0]  prog_addr;
wire [ 7:0]  prog_data;
wire [ 1:0]  prog_mask, prog_bank;

`ifndef COLORW
`define COLORW 4
`endif
localparam COLORW=`COLORW;

wire [COLORW-1:0] game_r, game_g, game_b;
wire              LHBL, LVBL;
wire              hs, vs, sample;

`ifndef SIGNED_SND
assign AUDIO_S = 1'b1; // Assume signed by default
`else
assign AUDIO_S = `SIGNED_SND;
`endif

`ifndef BUTTONS
`define BUTTONS 2
`endif

localparam BUTTONS=`BUTTONS;


jtframe_mister #(
    .CONF_STR      ( CONF_STR       ),
    .BUTTONS       ( BUTTONS        ),
    .COLORW        ( COLORW         )
    `ifdef VIDEO_WIDTH
    ,.VIDEO_WIDTH   ( `VIDEO_WIDTH   )
    `endif
    `ifdef VIDEO_HEIGHT
    ,.VIDEO_HEIGHT  ( `VIDEO_HEIGHT  )
    `endif
)
u_frame(
    .clk_sys        ( clk_sys        ),
    .clk_rom        ( clk_rom        ),
    .clk_vga        ( clk_sys        ),
    .pll_locked     ( pll_locked     ),
    // interface with microcontroller
    .status         ( status         ),
    .HPS_BUS        ( HPS_BUS        ),
    .buttons        ( buttons        ),
    // Base video
    .game_r         ( game_r         ),
    .game_g         ( game_g         ),
    .game_b         ( game_b         ),
    .LHBL           ( LHBL           ),
    .LVBL           ( LVBL           ),
    .hs             ( hs             ),
    .vs             ( vs             ),
    .pxl_cen        ( pxl_cen        ),
    .pxl2_cen       ( pxl2_cen       ),
    // SDRAM interface
    .SDRAM_CLK      ( SDRAM_CLK      ),
    .SDRAM_DQ       ( SDRAM_DQ       ),
    .SDRAM_A        ( SDRAM_A        ),
    .SDRAM_DQML     ( SDRAM_DQML     ),
    .SDRAM_DQMH     ( SDRAM_DQMH     ),
    .SDRAM_nWE      ( SDRAM_nWE      ),
    .SDRAM_nCAS     ( SDRAM_nCAS     ),
    .SDRAM_nRAS     ( SDRAM_nRAS     ),
    .SDRAM_nCS      ( SDRAM_nCS      ),
    .SDRAM_BA       ( SDRAM_BA       ),
    .SDRAM_CKE      ( SDRAM_CKE      ),
    // ROM load
    .ioctl_addr     ( ioctl_addr     ),
    .ioctl_data     ( ioctl_data     ),
    .ioctl_rom_wr   ( ioctl_rom_wr   ),
    .prog_addr      ( prog_addr      ),
    .prog_data      ( prog_data      ),
    .prog_mask      ( prog_mask      ),
    .prog_we        ( prog_we        ),
    .prog_rd        ( prog_rd        ),
    .prog_bank      ( prog_bank      ),
    .downloading    ( downloading    ),
    .dwnld_busy     ( dwnld_busy     ),
    // ROM access from game
    .loop_rst       ( loop_rst       ),
    .sdram_addr     ( sdram_addr     ),
    .sdram_bank     ( sdram_bank     ),
    .sdram_req      ( sdram_req      ),
    .sdram_ack      ( sdram_ack      ),
    .data_read      ( data_read      ),
    .data_rdy       ( data_rdy       ),
    .refresh_en     ( refresh_en     ),
    // write support
    .sdram_wrmask   ( sdram_wrmask   ),
    .sdram_rnw      ( sdram_rnw      ),
    .data_write     ( data_write     ),
//////////// board
    .rst            ( rst            ),
    .rst_n          ( rst_n          ), // unused
    .game_rst       ( game_rst       ),
    .game_rst_n     (                ),
    // reset forcing signals:
    .rst_req        ( rst_req        ),
    // joystick
    .game_joystick1 ( game_joy1      ),
    .game_joystick2 ( game_joy2      ),
    .game_joystick3 ( game_joy3      ),
    .game_joystick4 ( game_joy4      ),
    .game_coin      ( game_coin      ),
    .game_start     ( game_start     ),
    .game_service   (                ), // unused
    .joystick_analog_0( joystick_analog_0 ),
    .joystick_analog_1( joystick_analog_1 ),
    .LED            ( LED_USER       ),
    // DIP and OSD settings
    .enable_fm      ( enable_fm      ),
    .enable_psg     ( enable_psg     ),
    .dip_test       ( dip_test       ),
    .dip_pause      ( dip_pause      ),
    .dip_flip       ( dip_flip       ),
    .dip_fxlevel    ( dip_fxlevel    ),
    .dipsw          ( dipsw          ),
    // screen
    .rotate         (                ),
    // HDMI
    .hdmi_r         ( HDMI_R         ),
    .hdmi_g         ( HDMI_G         ),
    .hdmi_b         ( HDMI_B         ),
    .hdmi_hs        ( HDMI_HS        ),
    .hdmi_vs        ( HDMI_VS        ),
    .hdmi_clk       ( HDMI_CLK       ),
    .hdmi_cen       ( HDMI_CE        ),
    .hdmi_de        ( HDMI_DE        ),
    .hdmi_sl        ( HDMI_SL        ),
    .hdmi_arx       ( HDMI_ARX       ),
    .hdmi_ary       ( HDMI_ARY       ),
    // scan doubler output to VGA pins
    .scan2x_r       ( VGA_R          ),
    .scan2x_g       ( VGA_G          ),
    .scan2x_b       ( VGA_B          ),
    .scan2x_hs      ( VGA_HS         ),
    .scan2x_vs      ( VGA_VS         ),
    .scan2x_clk     ( VGA_CLK        ),
    .scan2x_cen     ( VGA_CE         ),
    .scan2x_de      ( VGA_DE         ),
    // Debug
    .gfx_en         ( gfx_en         )
);

`ifdef SIMULATION
assign sim_hb = ~LHBL;
assign sim_vb = ~LVBL;
assign sim_pxl_clk = clk_sys;
assign sim_pxl_cen = pxl_cen;
`endif

///////////////////////////////////////////////////////////////////

`ifdef SIMULATION
assign sim_pxl_clk = clk_sys;
assign sim_pxl_cen = pxl_cen;
`endif

`GAMETOP u_game
(
    .rst          ( game_rst         ),
    // clock inputs
    // By default clk is 48MHz, but JTFRAME_CLK96 overrides it to 96MHz
    .clk          ( clk_rom          ),
    `ifdef JTFRAME_CLK96
    .clk48        ( clk48            ),
    `endif
    `ifdef JTFRAME_CLK24
    .clk24        ( clk24            ),
    `endif
    `ifdef JTFRAME_CLK6
    .clk6         ( clk6             ),
    `endif
    .pxl2_cen     ( pxl2_cen         ),
    .pxl_cen      ( pxl_cen          ),

    .red          ( game_r           ),
    .green        ( game_g           ),
    .blue         ( game_b           ),
    .LHBL_dly     ( LHBL             ), // Final timing
    .LVBL_dly     ( LVBL             ),
    .HS           ( hs               ),
    .VS           ( vs               ),
`ifdef JTFRAME_INTERLACED
    .field        ( field            ),
`endif

    .start_button ( game_start       ),
    .coin_input   ( game_coin        ),
    .joystick1    ( game_joy1[BUTTONS+3:0]   ),
    .joystick2    ( game_joy2[BUTTONS+3:0]   ),
    `ifdef JTFRAME_4PLAYERS
    .joystick3    ( game_joy3[BUTTONS+3:0]   ),
    .joystick4    ( game_joy4[BUTTONS+3:0]   ),
    `endif
    `ifdef JTFRAME_ANALOG
    .joystick_analog_0( joystick_analog_0   ),
    .joystick_analog_1( joystick_analog_1   ),
    `endif
    // Sound control
    .enable_fm    ( enable_fm        ),
    .enable_psg   ( enable_psg       ),
    // PROM programming
    .ioctl_addr   ( ioctl_addr       ),
    .ioctl_data   ( ioctl_data       ),
    .ioctl_wr     ( ioctl_rom_wr     ),
    .prog_addr    ( prog_addr        ),
    .prog_data    ( prog_data        ),
    .prog_mask    ( prog_mask        ),
    .prog_we      ( prog_we          ),
    .prog_rd      ( prog_rd          ),
    `ifdef JTFRAME_SDRAM_BANKS
    .prog_bank    ( prog_bank        ),
    .sdram_bank   ( sdram_bank       ),
    `endif
    // ROM load
    .downloading  ( downloading      ),
    .dwnld_busy   ( dwnld_busy       ),
    .loop_rst     ( loop_rst         ),
    .sdram_req    ( sdram_req        ),
    .sdram_addr   ( sdram_addr       ),
    .data_read    ( data_read        ),
    .sdram_ack    ( sdram_ack        ),
    .data_rdy     ( data_rdy         ),
    .refresh_en   ( refresh_en       ),
    `ifdef JTFRAME_WRITEBACK
    .sdram_wrmask ( sdram_wrmask     ),
    .sdram_rnw    ( sdram_rnw        ),
    .data_write   ( data_write       ),
    `endif

    // DIP switches
    .status       ( status           ),
    .dip_pause    ( dip_pause        ),
    .dip_flip     ( dip_flip         ),
    .dip_test     ( dip_test         ),
    .dip_fxlevel  ( dip_fxlevel      ),
    `ifdef JTFRAME_MRA_DIP
    .dipsw        ( dipsw            ),
    `endif

    `ifdef STEREO_GAME
    .snd_left     ( AUDIO_L          ),
    .snd_right    ( AUDIO_R          ),
    `else
    .snd          ( AUDIO_L          ),
    `endif
    .gfx_en       ( gfx_en           ),

    // unconnected
    .sample       ( sample           )
);

`ifndef STEREO_GAME
    assign AUDIO_R = AUDIO_L;
`endif

`ifndef JTFRAME_SDRAM_BANKS
assign sdram_bank = 2'b0;
assign prog_bank  = 2'b0;
`endif

`ifdef SIMULATION
integer fsnd;
initial begin
    fsnd=$fopen("sound.raw","wb");
end
always @(posedge sample) begin
    $fwrite(fsnd,"%u", {AUDIO_L, AUDIO_R});
end
`endif


endmodule
