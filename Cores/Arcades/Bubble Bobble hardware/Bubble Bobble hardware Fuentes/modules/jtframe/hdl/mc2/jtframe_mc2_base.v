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
    Date: 27-10-2017 */

`timescale 1ns/1ps

module jtframe_mc2_base #(parameter
    CONF_STR        = "CORE",
    CONF_STR_LEN    = 4,
    SIGNED_SND      = 1'b0,
    COLORW          = 4
) (
    input           rst,
    input           clk_sys,
    input           clk_rom,
    input           clk_40,
    input           clk_vga,
    input           SDRAM_CLK,      // SDRAM Clock
    output          osd_shown,
    output  [6:0]   core_mod,
    // Base video
    input   [1:0]   osd_rotate,
    input [COLORW-1:0] game_r,
    input [COLORW-1:0] game_g,
    input [COLORW-1:0] game_b,
    input           LHBL,
    input           LVBL,
    input           hs,
    input           vs, 
    input           pxl_cen,
    // Scan-doubler video
    input   [5:0]   scan2x_r,
    input   [5:0]   scan2x_g,
    input   [5:0]   scan2x_b,
    input           scan2x_hs,
    input           scan2x_vs,
    output          scan2x_enb, // scan doubler enable bar = scan doubler disable.
    input           scan2x_clk,
    // Final video: VGA+OSD or base+OSD depending on configuration
    output  [5:0]   VIDEO_R,
    output  [5:0]   VIDEO_G,
    output  [5:0]   VIDEO_B,
    output          VIDEO_HS,
    output          VIDEO_VS,
    // SPI interface to arm io controller
    inout           SPI_DO,
    input           SPI_DI,
    input           SPI_SCK,
    input           SPI_SS2,
    input           SPI_SS3,
    input           SPI_SS4,
    input           CONF_DATA0,
    // control
    output [31:0]   status,
    output [31:0]   joystick1,
    output [31:0]   joystick2,
    output [31:0]   joystick3,
    output [31:0]   joystick4,
    output [15:0]   joystick_analog_0,
    output [15:0]   joystick_analog_1,
    output          ps2_kbd_clk,
    output          ps2_kbd_data,
    // Sound
    input           clk_dac,
    input   [15:0]  snd_left,
    input   [15:0]  snd_right,
    output          snd_pwm_left,
    output          snd_pwm_right,
    // ROM load from SPI
    output [24:0]   ioctl_addr,
    output [ 7:0]   ioctl_data,
    output          ioctl_wr,
    output          downloading,
     
    //Multicore 2
    input       pll_locked,
    input [7:0] keys_i,
    input [1:0] key_osd_rotate,
    input       video_direct,
    input wire  joy1_up_i,
    input wire  joy1_down_i,
    input wire  joy1_left_i,
    input wire  joy1_right_i,
    input wire  joy1_p6_i,
    input wire  joy1_p9_i,
    input wire  joy2_up_i,
    input wire  joy2_down_i,
    input wire  joy2_left_i,
    input wire  joy2_right_i,
    input wire  joy2_p6_i,
    input wire  joy2_p9_i,
    output wire joyX_p7_o
);

wire        ypbpr;
wire [7:0]  ioctl_index;
wire        ioctl_download;

assign downloading = ioctl_download;

`ifndef SIMULATION
    `ifndef NOSOUND

    function [19:0] snd_padded;
        input [15:0] snd;
        reg   [15:0] snd_in;
        begin
            snd_in = {snd[15]^SIGNED_SND, snd[14:0]};
            snd_padded = { 1'b0, snd_in, 3'd0 };
        end
    endfunction

    hifi_1bit_dac u_dac_left
    (
      .reset    ( rst                  ),
      .clk      ( clk_dac              ),
      .clk_ena  ( 1'b1                 ),
      .pcm_in   ( snd_padded(snd_left) ),
      .dac_out  ( snd_pwm_left         )
    );

        `ifdef STEREO_GAME
        hifi_1bit_dac u_dac_right
        (
          .reset    ( rst                  ),
          .clk      ( clk_dac              ),
          .clk_ena  ( 1'b1                 ),
          .pcm_in   ( snd_padded(snd_right)),
          .dac_out  ( snd_pwm_right        )
        );
        `else
        assign snd_pwm_right = snd_pwm_left;
        `endif
    `endif
`else // Simulation:
assign snd_pwm_left = 1'b0;
assign snd_pwm_right = 1'b0;
`endif

`ifndef JTFRAME_MIST_DIRECT
`define JTFRAME_MIST_DIRECT 1'b1
`endif

`ifndef SIMULATION
/*user_io #(.STRLEN(CONF_STR_LEN), .ROM_DIRECT_UPLOAD(`JTFRAME_MIST_DIRECT)) u_userio(
    .rst            ( rst       ),
    .clk_sys        ( clk_sys   ),
    .conf_str       ( CONF_STR  ),
    .SPI_CLK        ( SPI_SCK   ),
    .SPI_SS_IO      ( CONF_DATA0),
    .SPI_MISO       ( SPI_DO    ),
    .SPI_MOSI       ( SPI_DI    ),
    .joystick_0     ( joystick2 ),
    .joystick_1     ( joystick1 ),
    .joystick_3     ( joystick3 ),
    .joystick_4     ( joystick4 ),
    // Analog joysticks
    .joystick_analog_0  ( joystick_analog_0 ),
    .joystick_analog_1  ( joystick_analog_1 ),
    
    .status         ( status    ),
    .ypbpr          ( ypbpr     ),
    .scandoubler_disable ( scan2x_enb ),
    // keyboard
    .ps2_kbd_clk    ( ps2_kbd_clk  ),
    .ps2_kbd_data   ( ps2_kbd_data ),
    // Core variant
    .core_mod       ( core_mod  ),
    // unused ports:
    .serial_strobe  ( 1'b0      ),
    .serial_data    ( 8'd0      ),
    .sd_lba         ( 32'd0     ),
    .sd_rd          ( 1'b0      ),
    .sd_wr          ( 1'b0      ),
    .sd_conf        ( 1'b0      ),
    .sd_sdhc        ( 1'b0      ),
    .sd_din         ( 8'd0      )
);*/
`else
assign joystick1 = 32'd0;
assign joystick2 = 32'd0;
assign joystick3 = 32'd0;
assign joystick4 = 32'd0;
assign status    = 32'd0;
assign ps2_kbd_data = 1'b0;
assign ps2_kbd_clk  = 1'b0;
`ifndef SCANDOUBLER_DISABLE
    `define SCANDOUBLER_DISABLE 1'b1
    initial $display("INFO: Use -d SCANDOUBLER_DISABLE=0 if you want video output.");
`endif
initial $display("INFO:SCANDOUBLER_DISABLE=%d",`SCANDOUBLER_DISABLE);
assign scan2x_enb = `SCANDOUBLER_DISABLE;
assign ypbpr = 1'b0;
`endif

data_io  #(.STRLEN(CONF_STR_LEN)) u_datain (
    .SPI_SCK            ( SPI_SCK           ),
    .SPI_SS2            ( SPI_SS2           ),
    .SPI_DI             ( SPI_DI            ),
    .SPI_DO             ( SPI_DO            ),

    .data_in            ( pump_s & keys_i    ),
    .conf_str           ( CONF_STR          ),
    .status             ( status            ),
    .core_mod           ( core_mod          ),

    .clk_sys            ( clk_rom           ),
    .clkref_n           ( 1'b0              ), // this is not a clock.
    .ioctl_download     ( ioctl_download    ),
    .ioctl_addr         ( ioctl_addr        ),
    .ioctl_dout         ( ioctl_data        ),
    .ioctl_wr           ( ioctl_wr          ),
    .ioctl_index        ( ioctl_index       ) 
);

// OSD will only get simulated if SIMULATE_OSD is defined
`ifndef SIMULATE_OSD
`ifndef SCANDOUBLER_DISABLE
`ifdef SIMULATION
`define BYPASS_OSD
`endif
`endif
`endif

`ifdef SIMINFO
initial begin
    $display("INFO: use -d SIMULATE_OSD to simulate the MiST OSD")
end
`endif


`ifndef BYPASS_OSD
// include the on screen display
wire [5:0] osd_r_o;
wire [5:0] osd_g_o;
wire [5:0] osd_b_o;
wire       HSync = ~hs;
wire       VSync = ~vs;
wire       HSync_osd, VSync_osd;
wire       CSync_osd = ~(HSync_osd ^ VSync_osd);

function [5:0] extend_color;
    input [COLORW-1:0] a;
    case( COLORW )
        3: extend_color = { a, a[2:0] };
        4: extend_color = { a, a[3:2] };
        5: extend_color = { a, a[4] };
        6: extend_color = a;
        7: extend_color = a[6:1];
        8: extend_color = a[7:2];
    endcase
endfunction

wire [5:0] game_r6 = extend_color( {vga_col_s[7:5],1'b0} );
wire [5:0] game_g6 = extend_color( {vga_col_s[4:2],1'b0} );
wire [5:0] game_b6 = extend_color( {vga_col_s[1:0],2'b00} );

wire [7:0]vga_col_s;
wire vga_hs_s,vga_vs_s;
assign scan2x_enb = 1'b0; // 0 is scandoubler disable
framebuffer #(256,224,8) framebuffer
(
        .clk_sys    ( clk_sys ),
        .clk_i      ( pxl_cen ),
        .RGB_i      ({game_r[3:1],game_g[3:1],game_b[3:2]}),
        .hblank_i   ( ~LHBL ),
        .vblank_i   ( ~LVBL ),
        
        .rotate_i   ( status[2:1] ), 

        .clk_vga_i  ( (status[1]) ? clk_40 : clk_vga ), //800x600 or 640x480
        .RGB_o      ( vga_col_s ),
        .hsync_o    ( vga_hs_s ),
        .vsync_o    ( vga_vs_s ),
        .blank_o    (  ),

        .odd_line_o (  )
);

wire scandoubler_disable = status[5] ^ video_direct;

osd #(0,0,6'b01_11_01) osd (
   .clk_sys    ( (~scandoubler_disable) ? (status[1]) ? clk_40 : clk_vga : clk_sys ),

   // spi for OSD
   .SPI_DI     ( SPI_DI       ),
   .SPI_SCK    ( SPI_SCK      ),
   .SPI_SS3    ( SPI_SS2      ),

   .rotate     ( key_osd_rotate   ),

   .R_in       ( (~scandoubler_disable) ? game_r6  : {game_r, game_r[3:2]} ),
   .G_in       ( (~scandoubler_disable) ? game_g6  : {game_g, game_g[3:2]} ),
   .B_in       ( (~scandoubler_disable) ? game_b6  : {game_b, game_b[3:2]} ),
   .HSync      ( (~scandoubler_disable) ? vga_hs_s : ~hs ), //HSync        ),
   .VSync      ( (~scandoubler_disable) ? vga_vs_s : ~vs ), //VSync        ),

   .R_out      ( osd_r_o      ),
   .G_out      ( osd_g_o      ),
   .B_out      ( osd_b_o      ),
   .HSync_out  ( HSync_osd    ),
   .VSync_out  ( VSync_osd    ),

   .osd_shown  ( osd_shown    )
);

scanlines scanlines
(
    .clk_sys   ( (~scandoubler_disable) ? (status[1]) ? clk_40 : clk_vga : clk_sys),

    .scanlines ( status[4:3]) ,
    .ce_x2     ( 1'b1 ),

    .r_in     ( osd_r_o      ),
    .g_in     ( osd_g_o      ),
    .b_in     ( osd_b_o      ),
    .hs_in    ( HSync_osd    ),
    .vs_in    ( VSync_osd    ),

    .r_out ( r_out ),
    .g_out ( g_out ),
    .b_out ( b_out )
);

wire [5:0] r_out;
wire [5:0] g_out;
wire [5:0] b_out;

assign VIDEO_R  = r_out;
assign VIDEO_G  = g_out;
assign VIDEO_B  = b_out;
// a minimig vga->scart cable expects a composite sync signal on the VIDEO_HS output.
// and VCC on VIDEO_VS (to switch into rgb mode)
assign VIDEO_HS = HSync_osd;
assign VIDEO_VS = VSync_osd;
`else
assign VIDEO_R  = game_r;// { game_r, game_r[3:2] };
assign VIDEO_G  = game_g;// { game_g, game_g[3:2] };
assign VIDEO_B  = game_b;// { game_b, game_b[3:2] };
assign VIDEO_HS = hs;
assign VIDEO_VS = vs;
`endif

wire [7:0] pump_s;
PumpSignal PumpSignal (clk_sys, ~pll_locked, downloading, pump_s);


//--- Joystick read with sega 6 button support----------------------
    

    reg clk_sega_s;

    parameter CLK_SPEED = 25000;
    localparam TIMECLK = (9 * (CLK_SPEED/1000)); // calculate ~9us from the master clock
    reg [9:0] delay;

    always@(posedge clk_vga)
    begin
    delay <= delay - 10'd1;

    if (delay == 10'd0) 
        begin
            clk_sega_s <= ~clk_sega_s;
            delay <= TIMECLK; 
        end
    end

    assign joystick1[6:0] = { ~joy1_s[6:4], ~joy1_s[0], ~joy1_s[1], ~joy1_s[2], ~joy1_s[3] };
    assign joystick2[6:0] = { ~joy2_s[6:4], ~joy2_s[0], ~joy2_s[1], ~joy2_s[2], ~joy2_s[3] };

    reg [11:0]joy1_s;   
    reg [11:0]joy2_s; 
    reg joyP7_s;

    reg [7:0]state_v = 8'd0;
    reg j1_sixbutton_v = 1'b0;
    reg j2_sixbutton_v = 1'b0;
    
    reg clk_sega_old;
    always @(posedge clk_vga) 
    begin
        
            clk_sega_old <= clk_sega_s;

            if (clk_sega_s & ~clk_sega_old)
            begin

                state_v <= state_v + 1;

                
                case (state_v)          //-- joy_s format MXYZ SACB RLDU
                    8'd0:  
                        joyP7_s <=  1'b0;
                        
                    8'd1:
                        joyP7_s <=  1'b1;

                    8'd2:
                        begin
                            joy1_s[3:0] <= {joy1_right_i, joy1_left_i, joy1_down_i, joy1_up_i}; //-- R, L, D, U
                            joy2_s[3:0] <= {joy2_right_i, joy2_left_i, joy2_down_i, joy2_up_i}; //-- R, L, D, U
                            joy1_s[5:4] <= {joy1_p9_i, joy1_p6_i}; //-- C, B
                            joy2_s[5:4] <= {joy2_p9_i, joy2_p6_i}; //-- C, B                    
                            joyP7_s <= 1'b0;
                            j1_sixbutton_v <= 1'b0; //-- Assume it's not a six-button controller
                            j2_sixbutton_v <= 1'b0; //-- Assume it's not a six-button controller
                        end
                        
                    8'd3:
                        begin
                            if (joy1_right_i == 1'b0 && joy1_left_i == 1'b0) // it's a megadrive controller
                                    joy1_s[7:6] <= { joy1_p9_i , joy1_p6_i }; //-- Start, A
                            else
                                    joy1_s[7:4] <= { 1'b1, 1'b1, joy1_p9_i, joy1_p6_i }; //-- read A/B as master System
                                
                            if (joy2_right_i == 1'b0 && joy2_left_i == 1'b0) // it's a megadrive controller
                                    joy2_s[7:6] <= { joy2_p9_i , joy2_p6_i }; //-- Start, A
                            else
                                    joy2_s[7:4] <= { 1'b1, 1'b1, joy2_p9_i, joy2_p6_i }; //-- read A/B as master System

                                
                            joyP7_s <= 1'b1;
                        end
                        
                    8'd4:  
                        joyP7_s <= 1'b0;

                    8'd5:
                        begin
                            if (joy1_right_i == 1'b0 && joy1_left_i == 1'b0 && joy1_down_i == 1'b0 && joy1_up_i == 1'b0 )
                                j1_sixbutton_v <= 1'b1; // --it's a six button
                            
                            
                            if (joy2_right_i == 1'b0 && joy2_left_i == 1'b0 && joy2_down_i == 1'b0 && joy2_up_i == 1'b0 )
                                j2_sixbutton_v <= 1'b1; // --it's a six button
                            
                            
                            joyP7_s <= 1'b1;
                        end
                        
                    8'd6:
                        begin
                            if (j1_sixbutton_v == 1'b1)
                                joy1_s[11:8] <= { joy1_right_i, joy1_left_i, joy1_down_i, joy1_up_i }; //-- Mode, X, Y e Z
                            
                            
                            if (j2_sixbutton_v == 1'b1)
                                joy2_s[11:8] <= { joy2_right_i, joy2_left_i, joy2_down_i, joy2_up_i }; //-- Mode, X, Y e Z
                            
                            
                            joyP7_s <= 1'b0;
                        end 
                        
                    default:
                        joyP7_s <= 1'b1;
                        
                endcase
            end

    end
    
    assign joyX_p7_o = joyP7_s;
    //---------------------------

endmodule