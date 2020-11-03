//============================================================================
//  Midway SatansHollow/Tron/DominoMan/Wacko/Kozmik Krooz'r/Two Tigers
//  arcade top-level for MiST
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
//============================================================================
//
//  Multicore 2 Top by Victor Trucco
//
//============================================================================
//============================================================================
//
//  Unamiga Top adapted by Delgrom 09/04/2020
//
//============================================================================

`default_nettype none

module MCR2_MC2(
	// Clocks
	input wire	clock_50_i,

	// Buttons
	//input wire [4:1]	btn_n_i,

	// SRAMs (AS7C34096)
	output wire	[18:0]sram_addr_o  = 18'b0000000000000000000,
	inout wire	[7:0]sram_data_io	= 8'bzzzzzzzz,
	output wire	sram_we_n_o		= 1'b1,
	output wire	sram_oe_n_o		= 1'b1,
		
	// SDRAM	(H57V256)
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQMH,
	output        SDRAM_DQML,
	output        SDRAM_CKE,
	output        SDRAM_nCS,
	output        SDRAM_nWE,
	output        SDRAM_nRAS,
	output        SDRAM_nCAS,
	output        SDRAM_CLK,

	// PS2
	inout wire	ps2_clk_io			= 1'bz,
	inout wire	ps2_data_io			= 1'bz,
	inout wire	ps2_mouse_clk_io  = 1'bz,
	inout wire	ps2_mouse_data_io = 1'bz,

	// SD Card
	output wire	sd_cs_n_o			= 1'b1,
	output wire	sd_sclk_o			= 1'b0,
	output wire	sd_mosi_o			= 1'b0,
	input wire	sd_miso_i,

	// Joysticks
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
	output wire	joyX_p7_o			= 1'b1,

	// Audio
	output        AUDIO_L,
	output        AUDIO_R,
	input wire	ear_i,
	output wire	mic_o					= 1'b0,

		// VGA
	output  [4:0] VGA_R,
	output  [4:0] VGA_G,
	output  [4:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

		// HDMI
	//output wire	[7:0]tmds_o			= 8'b00000000,

		//STM32
	input wire	stm_tx_i,
	output wire	stm_rx_o,
	output wire	stm_rst_o			= 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
		
	//inout wire	stm_b8_io, 
	//inout wire	stm_b9_io,

	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2
);

`include "rtl/build_id.v" 

`define CORE_NAME "SHOLLOW"
wire [6:0] core_mod;

localparam CONF_STR = {
   "P,CORE_NAME.dat;",
	"S,DAT,Alternative ROM...;",
	"O34,Scanlines,Off,25%,50%,75%;",		
	"O5,Blend,Off,On;",
	"O6,Swap Joysticks,Off,On;",
	"O4,Spinner speed,Low,High;",
	"O7,Service,Off,On;",
	"OF,Start RGB 15KHZ,Off,On;",		
	"T0,Reset;",
	"V,v2.0.",`BUILD_DATE
};

wire       rotate  = status[2];
wire       blend   = status[5];
wire       joyswap = status[6];
wire       service = status[7];
wire       spinspd = status[4];

reg        oneplayer;
reg  [1:0] orientation; //left/right / portrait/landscape
reg  [7:0] input_0;
reg  [7:0] input_1;
reg  [7:0] input_2;
reg  [7:0] input_3;
reg  [7:0] input_4;

always @(*) begin
	input_0 = 8'hFF;
	input_1 = 8'hFF;
	input_2 = 8'hFF;
	input_3 = 8'hFF;
	input_4 = 8'hFF;
	oneplayer = 1'b1;
	orientation = 2'b10;

	case (core_mod)
	7'h0: // SHOLLOW
	begin
		orientation = 2'b11;
		input_0 = ~{ service, 1'b0, m_tilt, 1'b0, m_two_players, m_one_player, m_coin2, m_coin1 };
		input_1 = ~{ m_fire2A, m_fire2B, m_right2, m_left2, m_fireA, m_fireB, m_right, m_left };
		input_2 = 8'hFF;
		input_3 = ~{ 8'b00000010 };
	end
	7'h1: // TRON
	begin
		orientation = 2'b11;
		oneplayer = 1'b0;
		input_0 = ~{ service, 1'b0, m_tilt, m_fireA, m_two_players, m_one_player, m_coin2, m_coin1 };
		input_1 = ~{ 1'b0, spin_angle2 };
		input_2 = ~{ m_down, m_up, m_right, m_left, m_down, m_up, m_right, m_left };
		input_3 = ~{ m_fireA, 4'b0000,/*allow cont*/status[8], 2'b10 };
		input_4 = ~{ 1'b0, spin_angle2 };
	end
	7'h2: // TWOTIGER
	begin
		oneplayer = 1'b0;
		input_0 = ~{ service, 1'b0, m_tilt, m_three_players, m_two_players, m_one_player, m_coin2, m_coin1 };
		input_1 = ~{ 1'b0, spin_angle1 };
		input_2 = ~{ 4'b0000, m_fire2B, m_fire2A, m_fireB, m_fireA };
		input_3 = 8'hFF;
		input_4 = ~{ 1'b0, spin_angle2 };
	end
	7'h3: // WACKO
	begin
		input_0 = ~{ service, 1'b0, m_tilt, 1'b0, m_two_players, m_one_player, m_coin2, m_coin1 };
		input_1 = x_pos[10:3];
		input_2 = y_pos[10:3];
		input_3 = ~{ 8'b01000000 };
		input_4 = ~{ m_up2, m_down2, m_left2, m_right2, m_up, m_down, m_left, m_right };
	end
	7'h4: // KROOZR
	begin
		input_0 = ~{ service, 1'b0, m_tilt, m_fireA | mouse_btns[0], m_two_players, m_one_player, m_coin2, m_coin1 };
		input_1 = ~{ (m_fireB | mouse_btns[1]), spin_angle1[6], 3'b111, spin_angle1[5:3] };
		input_2 = { x_pos_kroozr[9], x_pos_kroozr[9], x_pos_kroozr[7:2] };
		input_3 = ~{ 8'b01000000 };
		input_4 = { y_pos_kroozr[9], y_pos_kroozr[9], y_pos_kroozr[7:2] };
	end
	7'h5: // DOMINO
	begin
		input_0 = ~{ service, 1'b0, m_tilt, m_fireA, m_two_players, m_one_player, m_coin2, m_coin1 };
		input_1 = ~{ 4'b0000, m_down, m_up, m_right, m_left };
		input_2 = ~{ 3'b000, m_fire2A, m_down2, m_up2, m_right2, m_left2 };
		input_3 = ~{ 6'b010000,/*skin*/status[9], /*music*/status[8] };
	end
	default: ;
	endcase
end

//assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_sys;
assign SDRAM_CKE = 1;

assign sram_we_n_o	= 1'b1;
assign sram_oe_n_o	= 1'b1;
assign stm_rst_o		= 1'bz;

wire clk_sys;
wire pll_locked;
pll_mist pll(
	.inclk0(clock_50_i),
	.areset(0),
	.c0(clk_sys),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD = (cnt_changeScandoubler)? v_scandoublerD : status[15]; // delgrom 1'b0 vga, 1'b1 15khz ;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire signed [8:0] mouse_x;
wire signed [8:0] mouse_y;
wire        mouse_strobe;
reg   [7:0] mouse_flags;

/*
user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_sys        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
	.core_mod       (core_mod       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.mouse_x        (mouse_x        ),
	.mouse_y        (mouse_y        ),
	.mouse_strobe   (mouse_strobe   ),
	.mouse_flags    (mouse_flags    ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);
*/

wire [15:0] rom_addr;
wire [15:0] rom_do;
wire [13:0] snd_addr;
wire [15:0] snd_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

/* ROM structure
00000 - 0BFFF  48k CPU1
0C000 - 0FFFF  16k CPU2
10000 - 13FFF  16k GFX1
14000 - 1BFFF  32k GFX2
*/

data_io #(
	.STRLEN(($size(CONF_STR)>>3)))
data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	
	.data_in			( osd_s & keys_s ),
	.conf_str		( CONF_STR 		),
	.status			( status 		),
	.core_mod      ( core_mod     ),
	
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

reg port1_req, port2_req;
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sys      ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 15'h7fff : rom_addr[15:1] ),
	.cpu1_q        ( rom_do ),

	// port2 for sound board
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] - 16'h6000 ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.snd_addr      ( ioctl_downl ? 15'h7fff : {2'b00, snd_addr[13:1]} ),
	.snd_q         ( snd_do )
);

always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	//reset <= status[0] | ~btn_n_i[4] | ioctl_downl | ~rom_loaded;
	reset <= status[0] | ioctl_downl | ~rom_loaded;
end

wire [15:0] audio_l, audio_r;
wire        hs, vs, cs;
wire        blankn;
wire  [2:0] g, r, b;

satans_hollow satans_hollow(
	.clock_40(clk_sys),
	.reset(reset),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_blankn(blankn),
	.video_hs(hs),
	.video_vs(vs),
	.video_csync(cs),
	.tv15Khz_mode(scandoublerD),
	.separate_audio(1'b1),
	.audio_out_l(audio_l),
	.audio_out_r(audio_r),

	.input_0      ( input_0         ),
	.input_1      ( input_1         ),
	.input_2      ( input_2         ),
	.input_3      ( input_3         ),
	.input_4      ( input_4         ),

	.cpu_rom_addr ( rom_addr        ),
	.cpu_rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.snd_rom_addr ( snd_addr        ),
	.snd_rom_do   ( snd_addr[0] ? snd_do[15:8] : snd_do[7:0] ),

	.dl_addr      ( ioctl_addr[16:0]),
	.dl_wr        ( ioctl_wr        ),
	.dl_data      ( ioctl_dout      )
);

wire vs_out;
wire hs_out;
assign VGA_HS = (~no_csync & scandoublerD & ~ypbpr)? cs : hs_out;
assign VGA_VS = (~no_csync & scandoublerD & ~ypbpr)? 1'b1 : vs_out;

wire [5:0] vga_r_s;	
wire [5:0] vga_g_s;	
wire [5:0] vga_b_s;	

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS2          ),
	.SPI_DI         ( SPI_DI           ),
	
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	
	.VGA_R          ( vga_r_s          ),
	.VGA_G          ( vga_g_s          ),
	.VGA_B          ( vga_b_s          ),
	.VGA_VS         ( vs_out           ),
	.VGA_HS         ( hs_out           ),
	
	.rotate         ( { orientation[1], rotate } ),
	.ce_divider     ( 1'b1             ),
	.blend          ( blend            ),
	//.scandoubler_disable( 1'b1         ),
	.scandoubler_disable( scandoublerD ),		
	.no_csync       ( 1'b1             ),
	//.scanlines      (                  ),
	.scanlines      ( status[4:3] ),	
	.osd_enable 	 ( osd_enable )
	);
	
assign VGA_R = vga_r_s[5:1];
assign VGA_G = vga_g_s[5:1];
assign VGA_B = vga_b_s[5:1];
	

dac #(
	.C_bits(16))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_l),
	.dac_o(AUDIO_L)
	);

dac #(
	.C_bits(16))
dac_r(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_r),
	.dac_o(AUDIO_R)
	);	
	
ps2mouse ps2mouse
(
  .clk 		( clk_sys ),          //bus clock
  .reset		( reset ),            //reset
  .ps2mdat	( ps2_mouse_data_io ),   //mouse PS/2 data
  .ps2mclk	( ps2_mouse_clk_io ),    //mouse PS/2 clk
  
  .mou_emu 	( 6'd0 ),
  .sof 		( 0 ),
  
  .zcount 	(  ),  //mouse Z counter
  .ycount 	( mouse_y ),  //mouse Y counter
  .xcount 	( mouse_x ),  //mouse X counter
  
  .mleft		( mouse_flags[0] ),  //left mouse button output
  .mthird	( ),               	//third(middle) mouse button output
  .mright	( mouse_flags[1] ),  //right mouse button output
  
  .mouse_data_out (mouse_strobe) //mouse has data to present
);


// Mouse controls for Wacko
reg signed [10:0] x_pos;
reg signed [10:0] y_pos;

always @(posedge clk_sys) begin
	if (mouse_strobe) begin
		if (rotate) begin
			x_pos <= x_pos - mouse_y;
			y_pos <= y_pos + mouse_x;
		end else begin
			x_pos <= x_pos + mouse_x;
			y_pos <= y_pos + mouse_y;
		end
	end
end

// Controls for Kozmik Krooz'r
reg  signed [9:0] x_pos_kroozr;
reg  signed [9:0] y_pos_kroozr;
wire signed [8:0] move_x = rotate ? -mouse_y : mouse_x;
wire signed [8:0] move_y = rotate ?  mouse_x : mouse_y;
wire signed [9:0] x_pos_new = x_pos_kroozr - move_x;
wire signed [9:0] y_pos_new = y_pos_kroozr + move_y;
reg  [1:0] mouse_btns;

always @(posedge clk_sys) begin
	if (mouse_strobe) begin
		mouse_btns <= mouse_flags[1:0];
		if (!((move_x[8] & ~x_pos_kroozr[9] &  x_pos_new[9]) || (~move_x[8] &  x_pos_kroozr[9] & ~x_pos_new[9]))) x_pos_kroozr <= x_pos_new;
		if (!((move_y[8] &  y_pos_kroozr[9] & ~y_pos_new[9]) || (~move_y[8] & ~y_pos_kroozr[9] &  y_pos_new[9]))) y_pos_kroozr <= y_pos_new;
	end
end

// Spinners for Tron, Two Tigers, Krooz'r
wire [6:0] spin_angle1;
spinner spinner1 (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(spinspd),
	.btn_left(m_left | m_up),
	.btn_right(m_right | m_down),
	.ctc_zc_to_2(vs),
	.spin_angle(spin_angle1)
);

wire [6:0] spin_angle2;
spinner spinner2 (
	.clock_40(clk_sys),
	.reset(reset),
	.btn_acc(spinspd),
	.btn_left(m_left2 | m_up2 | (core_mod == 7'h1 && m_fireB)), // fireB for Tron
	.btn_right(m_right2 | m_down2 | (core_mod == 7'h1 && m_fireC)), // fireC for Tron
	.ctc_zc_to_2(vs),
	.spin_angle(spin_angle2)
);

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
					
				
				if (ioctl_downl == 1 && osd_s == 8'b00111111)
					osd_s = 8'b11111111;
			
		end 

//-----------------------

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_fireG;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_fire2G;
wire m_tilt, btn_coin, m_coin2, m_coin3, m_coin4, btn_one_player, btn_two_player, m_three_players, m_four_players;

wire m_right4, m_left4, m_down4, m_up4, m_right3, m_left3, m_down3, m_up3;

//wire m_one_player  = ~btn_n_i[1] | btn_one_player;
//wire m_two_players = ~btn_n_i[2] | btn_two_player;
//wire m_coin1  		 = ~btn_n_i[3] | btn_coin;

wire m_one_player  = btn_one_player;
wire m_two_players = btn_two_player;
wire m_coin1  	   = btn_coin;

wire kbd_intr;
wire [7:0] kbd_scancode;
wire [7:0] keys_s;

//get scancode from keyboard
io_ps2_keyboard keyboard 
 (
  .clk       ( clk_sys ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

wire [15:0]joy1_s;
wire [15:0]joy2_s;
wire [8:0]controls_s;
wire osd_enable;

//translate scancode to joystick
kbd_joystick_atari #( .OSD_CMD	( 3'b011 )) k_joystick
(
  .clk         	( clk_sys ),
  .kbdint      	( kbd_intr ),
  .kbdscancode 	( kbd_scancode ), 
  
	.joystick_0 	({ joy1_p9_i, joy1_p6_i, joy1_up_i, joy1_down_i, joy1_left_i, joy1_right_i }),
	.joystick_1		({ joy2_p9_i, joy2_p6_i, joy2_up_i, joy2_down_i, joy2_left_i, joy2_right_i }),
		  
	//-- joystick_0 and joystick_1 should be swapped
	.joyswap 		( joyswap ),
		
	//-- player1 and player2 should get both joystick_0 and joystick_1
	.oneplayer		( oneplayer ),

	//-- tilt, coin4-1, start4-1
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, btn_coin, m_four_players, m_three_players, btn_two_player, btn_one_player} ),
		
	//-- fire12-1, up, down, left, right

	.player1     ( {m_fireG,  m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2G, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
		
	//-- keys to the OSD
	.osd_o		   ( keys_s ),
	.osd_enable 	( osd_enable ),
	
	//-- sega joystick
	//.sega_clk  		( hs ),
	//.sega_strobe	( joyX_p7_o )
	.fn_pulse	( fn_pulse)	
		
);
	
	// -- ------------------------ delgrom Cambiar entre 15khz y 31khz

	wire [7:0] fn_pulse;
	reg v_scandoublerD =1'b0;  // delgrom 1'b1 inicia a 15khz, 1'b0 inicia a  vga
	reg cnt_changeScandoubler = 1'b0;

	always @(posedge fn_pulse[0]) 
	begin		
		v_scandoublerD <= ~scandoublerD; //v_scandoublerD;
		cnt_changeScandoubler = 1'b1;
	end

endmodule 