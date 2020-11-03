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
    input           clk_vga,
    input           SDRAM_CLK,      // SDRAM Clock
    output          osd_shown,
	 
	 input 			  pll_locked,

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
	 input           w_scandoubler_disable, //delgrom
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
    output          ps2_kbd_clk,
    output          ps2_kbd_data,
    // Sound
    input           clk_dac,
    input   [15:0]  snd_left,
    input   [15:0]  snd_right,
    output          snd_pwm_left,
    output          snd_pwm_right,
    // ROM load from SPI
    output [22:0]   ioctl_addr,
    output [ 7:0]   ioctl_data,
    output          ioctl_wr,
    output          downloading,
	 input 	[7:0]   keys_i,
	 
	 //MC2 joysticks
	input wire	joy1_up_i,
	input wire	joy1_down_i,
	input wire	joy1_left_i,
	input wire	joy1_right_i,
	input wire	joy1_p6_i,
	input wire	joy1_p9_i,
	input wire	joy2_up_i,
	input wire	joy2_down_i,
	input wire	joy2_left_i,
	input wire	joy2_right_i,
	input wire	joy2_p6_i,
	input wire	joy2_p9_i,
	output wire	joyX_p7_o
);

wire ypbpr;

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
/*
user_io #(.STRLEN(CONF_STR_LEN), .ROM_DIRECT_UPLOAD(`JTFRAME_MIST_DIRECT)) u_userio(
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
    .status         ( status    ),
    .ypbpr          ( ypbpr     ),
    .scandoubler_disable ( scan2x_enb ),
    // keyboard
    .ps2_kbd_clk    ( ps2_kbd_clk  ),
    .ps2_kbd_data   ( ps2_kbd_data ),
    // unused ports:
    .serial_strobe  ( 1'b0      ),
    .serial_data    ( 8'd0      ),
    .sd_lba         ( 32'd0     ),
    .sd_rd          ( 1'b0      ),
    .sd_wr          ( 1'b0      ),
    .sd_conf        ( 1'b0      ),
    .sd_sdhc        ( 1'b0      ),
    .sd_din         ( 8'd0      )
);
*/
assign scan2x_enb = (cnt_scandbldis)? w_scandoubler_disable : status[15];// delgrom


`else
assign joystick1 = 32'd0;
assign joystick2 = 32'd0;
assign status    = 32'd0;
assign ps2_kbd_data = 1'b0;
assign ps2_kbd_clk  = 1'b0;
`ifndef SCANDOUBLER_DISABLE
assign scan2x_enb   = 1'b0;
`define SCANDOUBLER_DISABLE 1'b0
initial $display("INFO: Use -d SCANDOUBLER_DISABLE=1 if you want video output.");
`endif
assign scan2x_enb = `SCANDOUBLER_DISABLE;
assign ypbpr = 1'b0;
`endif

data_io  #(.STRLEN(CONF_STR_LEN)) u_datain (
    .SPI_SCK            ( SPI_SCK      ),
    .SPI_SS2            ( SPI_SS2      ),
    .SPI_DI             ( SPI_DI       ),
    .SPI_DO             ( SPI_DO       ),
    
	 .data_in				( osd_s & keys_i ),
	 .conf_str				( CONF_STR 		),
	 .status					( status 		),
	
    .clk_sys            ( clk_rom      ),
    .ioctl_download     ( downloading  ),
    .ioctl_addr         ( ioctl_addr   ),
    .ioctl_dout         ( ioctl_data   ),
    .ioctl_wr           ( ioctl_wr     ),
    .ioctl_index        ( /* unused*/  )
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
wire       HSync = scan2x_enb ? ~hs : scan2x_hs;
wire       VSync = scan2x_enb ? ~vs : scan2x_vs;
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

wire [5:0] game_r6 = extend_color( game_r );
wire [5:0] game_g6 = extend_color( game_g );
wire [5:0] game_b6 = extend_color( game_b );


osd #(0,0,3'b001) osd (
   .clk_sys    ( scan2x_enb ? clk_sys : clk_vga ),

   // spi for OSD
   .SPI_DI     ( SPI_DI       ),
   .SPI_SCK    ( SPI_SCK      ),
   .SPI_SS3    ( SPI_SS2      ),

   .rotate     ( osd_rotate   ),

   .R_in       ( scan2x_enb ? game_r6 : scan2x_r ),
   .G_in       ( scan2x_enb ? game_g6 : scan2x_g ),
   .B_in       ( scan2x_enb ? game_b6 : scan2x_b ),
   .HSync      ( HSync        ),
   .VSync      ( VSync        ),

   .R_out      ( osd_r_o      ),
   .G_out      ( osd_g_o      ),
   .B_out      ( osd_b_o      ),
   .HSync_out  ( HSync_osd    ),
   .VSync_out  ( VSync_osd    ),

   .osd_shown  ( osd_shown    )
);

wire [5:0] Y, Pb, Pr;
wire [5:0] r, g, b;
wire [1:0] scanlines = status[4:3];
reg  [5:0] sl_r_s, sl_g_s, sl_b_s;
reg  scanline;

always @(negedge HSync) begin
	scanline <= !scanline;
end

rgb2ypbpr u_rgb2ypbpr
(
    .red   ( osd_r_o ),
    .green ( osd_g_o ),
    .blue  ( osd_b_o ),
    .y     ( Y       ),
    .pb    ( Pb      ),
    .pr    ( Pr      )
);

assign r = ypbpr ? Pr : osd_r_o;
assign g = ypbpr ? Y  : osd_g_o;
assign b = ypbpr ? Pb : osd_b_o;

assign VIDEO_R = sl_r_s;
assign VIDEO_G = sl_g_s;
assign VIDEO_B = sl_b_s;

always @(posedge clk_sys) begin
	case(scanlines)
		0: begin // no scanlines
			sl_r_s = r;
			sl_g_s = g;
			sl_b_s = b;
		end
		1: begin // reduce 25% = 1/2 + 1/4
			sl_r_s = scanline ? r : { 1'b0, r[5:1] } + { 2'b00, r[5:2] };
			sl_g_s = scanline ? g : { 1'b0, g[5:1] } + { 2'b00, g[5:2] };
			sl_b_s = scanline ? b : { 1'b0, b[5:1] } + { 2'b00, b[5:2] };
		end
		2: begin // reduce 50% = 1/2
			sl_r_s = scanline ? r : { 1'b0, r[5:1] };
			sl_g_s = scanline ? g : { 1'b0, g[5:1] };
			sl_b_s = scanline ? b : { 1'b0, b[5:1] };
		end
		3: begin // reduce 75% = 1/4
			sl_r_s = scanline ? r : { 2'b00, r[5:2] };
			sl_g_s = scanline ? g : { 2'b00, g[5:2] };
			sl_b_s = scanline ? b : { 2'b00, b[5:2] };
		end
	endcase
end
// a minimig vga->scart cable expects a composite sync signal on the VIDEO_HS output.
// and VCC on VIDEO_VS (to switch into rgb mode)
assign VIDEO_HS = (scan2x_enb | ypbpr) ? CSync_osd : HSync_osd;
assign VIDEO_VS = (scan2x_enb | ypbpr) ? 1'b1 : VSync_osd;
`else
assign VIDEO_R  = game_r;// { game_r, game_r[3:2] };
assign VIDEO_G  = game_g;// { game_g, game_g[3:2] };
assign VIDEO_B  = game_b;// { game_b, game_b[3:2] };
assign VIDEO_HS = hs;
assign VIDEO_VS = vs;
`endif

//--------- ROM DATA PUMP ----------------------------------------------------
	
		reg [15:0] power_on_s	= 16'b1111111111111111;
		reg [7:0] osd_s = 8'b11111111;
		
		wire hard_reset = ~pll_locked;
		
		//--start the microcontroller OSD menu after the power on
		always @(posedge clk_sys) 
		begin
		
				if (hard_reset == 1)
					power_on_s = 16'b1111111111111111;
				else if (power_on_s != 0)
				begin
					power_on_s = power_on_s - 1;
					osd_s = 8'b00111111;
				end 
					
				
				if (downloading == 1 && osd_s == 8'b00111111)
					osd_s = 8'b11111111;
			
		end 

//-----------------------
// delgrom iniciar a VGA o RGB según status[15]
reg cnt_scandbldis = 1'b0;

always @(posedge w_scandoubler_disable) begin
	cnt_scandbldis = 1'b1;
end




//--- Joystick read with sega 6 button support----------------------
	
	assign joystick1[6:0] = { ~joy1_s[6:4], ~joy1_s[0], ~joy1_s[1], ~joy1_s[2], ~joy1_s[3] };
	assign joystick2[6:0] = { ~joy2_s[6:4], ~joy2_s[0], ~joy2_s[1], ~joy2_s[2], ~joy2_s[3] };

	reg [11:0]joy1_s; 	
	reg [11:0]joy2_s; 
	reg joyP7_s;

	reg [7:0]state_v = 8'd0;
	reg j1_sixbutton_v = 1'b0;
	reg j2_sixbutton_v = 1'b0;
	
	always @(negedge HSync) 
	begin
		

			state_v <= state_v + 1;

			
			case (state_v)			//-- joy_s format MXYZ SACB RLDU
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
	
	assign joyX_p7_o = joyP7_s;
	//---------------------------


endmodule