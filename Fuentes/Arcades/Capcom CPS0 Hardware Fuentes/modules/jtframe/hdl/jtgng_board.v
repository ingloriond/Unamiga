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
    Date: 8-2-2019 */

module jtgng_board(
    output  reg       rst,      // use as synchrnous reset
    output  reg       rst_n,    // use as asynchronous reset
    output  reg       game_rst,
    // reset forcing signals:
    input             dip_flip, // A change in dip_flip implies a reset
    input             downloading,
    input             loop_rst,
    input             rst_req,

    input             clk_dac,
    input             clk_rgb,
    input             clk_vga,
    input             pxl_cen,
    input   [15:0]    snd,
    output            snd_pwm,
	 
    // VGA
    input             en_mixing,
    input   [3:0]     game_r,
    input   [3:0]     game_g,
    input   [3:0]     game_b,
    input             LHBL,
    input             LVBL,
	 
    output  [5:0]     vga_r,
    output  [5:0]     vga_g,
    output  [5:0]     vga_b,
    output            vga_hsync,
    output            vga_vsync,
	 
    // keyboard
    input             ps2_kbd_clk,
    input             ps2_kbd_data,
    // joystick
    input      [9:0]  board_joystick1,
    input      [9:0]  board_joystick2,
    output reg [9:0]  game_joystick1,
    output reg [9:0]  game_joystick2,
    output reg [1:0]  game_coin,
    output reg [1:0]  game_start,
    output reg        game_pause,
    output reg        game_service,
    // GFX enable
    output reg [3:0]  gfx_en
);


parameter SIGNED_SND=1'b0;
parameter THREE_BUTTONS=0;
parameter GAME_INPUTS_ACTIVE_HIGH=1'b0;

wire invert_inputs = GAME_INPUTS_ACTIVE_HIGH;
wire key_reset, key_pause;
reg [7:0] rst_cnt=8'd0;

always @(posedge clk_rgb)
    if( rst_cnt != ~8'b0 ) begin
        rst <= 1'b1;
        rst_cnt <= rst_cnt + 8'd1;
    end else rst <= 1'b0;

// rst_n is meant to be used as an asynchronous reset
// for the clk_rgb domain
reg pre_rst_n;
always @(posedge clk_rgb)
    if( rst | downloading | loop_rst ) begin
        pre_rst_n <= 1'b0;
        rst_n <= 1'b0;
    end else begin
        pre_rst_n <= 1'b1;
        rst_n <= pre_rst_n;
    end

reg soft_rst;
reg last_dip_flip;
reg [7:0] game_rst_cnt=8'd0;
always @(negedge clk_rgb) begin
    last_dip_flip <= dip_flip;
    if( downloading | rst | rst_req | (last_dip_flip!=dip_flip) | soft_rst ) begin
        game_rst_cnt <= 8'd0;
        game_rst     <= 1'b1;
    end
    if( game_rst_cnt != ~8'b0 ) begin
        game_rst <= 1'b1;
        game_rst_cnt <= game_rst_cnt + 8'd1;
    end else game_rst <= 1'b0;
end

`ifndef SIMULATION
`ifndef NOSOUND
// hybrid_pwm_sd u_dac
// (
//     .clk    ( clk_dac   ),
//     .n_reset( ~rst      ),
//     .din    ( {snd[15]^SIGNED_SND, snd[14:0]}  ),
//     .dout   ( snd_pwm   )
// );

wire [15:0] snd_in = {snd[15]^SIGNED_SND, snd[14:0]};
wire [19:0] snd_padded = { 1'b0, snd_in, 3'd0 };


hifi_1bit_dac u_dac
(
  .reset    ( rst        ),
  .clk      ( clk_dac    ),
  .clk_ena  ( 1'b1       ),
  .pcm_in   ( snd_padded ),
  .dac_out  ( snd_pwm    )
);
`endif
`endif

`ifdef SIMULATION
assign snd_pwm = 1'b0;
`endif


// convert 5-bit colour to 6-bit colour
assign vga_r[0] = vga_r[5];
assign vga_g[0] = vga_g[5];
assign vga_b[0] = vga_b[5];

// Do not simulate the scan doubler unless explicitly asked for it:
`ifndef SIM_SCANDOUBLER
`ifdef SIMULATION
`define NOSCANDOUBLER
`endif
`endif

`ifndef NOSCANDOUBLER
jtgng_vga u_scandoubler (
    .clk_rgb    ( clk_rgb       ), // 24 MHz
    .cen6       ( pxl_cen       ), //  6 MHz
    .clk_vga    ( clk_vga       ), // 25 MHz
    .rst        ( rst           ),
    .red        ( game_r        ),
    .green      ( game_g        ),
    .blue       ( game_b        ),
    .LHBL       ( LHBL          ),
    .LVBL       ( LVBL          ),
    .en_mixing  ( en_mixing     ),
    .vga_red    ( vga_r[5:1]    ),
    .vga_green  ( vga_g[5:1]    ),
    .vga_blue   ( vga_b[5:1]    ),
    .vga_hsync  ( vga_hsync     ),
    .vga_vsync  ( vga_vsync     )
);
`else
assign vga_r[5:1] = 4'd0;
assign vga_g[5:1] = 4'd0;
assign vga_b[5:1] = 4'd0;
assign vga_hsync  = 1'b0;
assign vga_vsync  = 1'b0;
`endif

wire [9:0] key_joy1, key_joy2;
wire [1:0] key_start, key_coin;
wire [3:0] key_gfx;
wire       key_service;

`ifndef SIMULATION
jtgng_keyboard u_keyboard(
    .clk         ( clk_rgb       ),
    .rst         ( rst           ),
    // ps2 interface
    .ps2_clk     ( ps2_kbd_clk   ),
    .ps2_data    ( ps2_kbd_data  ),
    // decoded keys
    .key_joy1    ( key_joy1      ),
    .key_joy2    ( key_joy2      ),
    .key_start   ( key_start     ),
    .key_coin    ( key_coin      ),
    .key_reset   ( key_reset     ),
    .key_pause   ( key_pause     ),
    .key_service ( key_service   ),
    .key_gfx     ( key_gfx       )
);
`else
assign key_joy2  = 6'h0;
assign key_joy1  = 6'h0;
assign key_start = 2'd0;
assign key_coin  = 2'd0;
assign key_reset = 1'b0;
assign key_pause = 1'b0;
`endif

reg [9:0] joy1_sync, joy2_sync;

always @(posedge clk_rgb) begin
    joy1_sync <= ~board_joystick1;
    joy2_sync <= ~board_joystick2;
end

localparam PAUSE_BIT = 8+THREE_BUTTONS;
localparam START_BIT = 7+THREE_BUTTONS;
localparam COIN_BIT  = 6+THREE_BUTTONS;

reg last_pause, last_joypause_b, last_reset, last_service;
reg [3:0] last_gfx;
wire joy_pause_b = joy1_sync[PAUSE_BIT] & joy2_sync[PAUSE_BIT];

integer cnt;

always @(posedge clk_rgb)
    if(rst ) begin
        game_pause   <= 1'b0;
        game_service <= 1'b1 ^ invert_inputs;
        soft_rst     <= 1'b0;
        gfx_en       <= 4'hf;
    end else begin
        last_pause   <= key_pause;
        last_service <= key_service;
        last_reset   <= key_reset;
        last_joypause_b <= joy_pause_b; // joy is active low!
        last_gfx     <= key_gfx;

        // joystick, coin, start and service inputs are inverted
        // as indicated in the instance parameter
        game_joystick1 <= {10{invert_inputs}} ^ (joy1_sync & ~key_joy1);
        game_joystick2 <= {10{invert_inputs}} ^ (joy2_sync & ~key_joy2);
        
        game_coin      <= {2{invert_inputs}} ^ 
            ({joy2_sync[COIN_BIT],joy1_sync[COIN_BIT]} & ~key_coin);
        
        game_start     <= {2{invert_inputs}} ^ 
            ({joy2_sync[START_BIT],joy1_sync[START_BIT]} & ~key_start);
        
        soft_rst <= key_reset && !last_reset;

        for(cnt=0; cnt<4; cnt=cnt+1)
            if( key_gfx[cnt] && !last_gfx[cnt] ) gfx_en[cnt] <= ~gfx_en[cnt];
        // state variables:
        if( (key_pause && !last_pause) || (!joy_pause_b && last_joypause_b) )
            game_pause   <= ~game_pause;
        if(key_service && !last_service)  game_service <= ~game_service;
    end


endmodule // jtgng_board