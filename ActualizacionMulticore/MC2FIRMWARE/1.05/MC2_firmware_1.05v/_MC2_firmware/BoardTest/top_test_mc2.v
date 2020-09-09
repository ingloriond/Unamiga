`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   01:24:02 08/15/2016 
// Design Name: 
// Module Name:   tld_test_prod_v4 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module top_test_mc2 (
  // Clocks
   input clk100,
   input clk100n,
	input clk25,
	input pll_locked,

	// SRAMs (AS7C34096)
	output wire	[18:0]sram_addr_o  = 18'b0000000000000000000,
	inout wire	[7:0]sram_data_io	= 8'bzzzzzzzz,
	output wire	sram_we_n_o		= 1'b1,
	output wire	sram_oe_n_o		= 1'b1,
		
	// SDRAM	(H57V256)
	output wire [12:0] SDRAM_A,
	output wire [1:0] SDRAM_BA,
	inout  wire [15:0] SDRAM_DQ,
	output wire       SDRAM_DQMH,
	output wire       SDRAM_DQML,
	output wire       SDRAM_CKE,
	output wire       SDRAM_nCS,
	output wire       SDRAM_nWE,
	output wire       SDRAM_nRAS,
	output wire       SDRAM_nCAS,
	output wire       SDRAM_CLK,

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
	inout wire	joy1_up_i,
	inout wire	joy1_down_i,
	input wire	joy1_left_i,
	input wire	joy1_right_i,
	input wire	joy1_p6_i,
	input wire	joy1_p9_i,
	inout wire	joy2_up_i,
	inout wire	joy2_down_i,
	input wire	joy2_left_i,
	input wire	joy2_right_i,
	input wire	joy2_p6_i,
	input wire	joy2_p9_i,
	output wire	joyX_p7_o			= 1'b1,

	// Audio
	output        AUDIO_L,
	output        AUDIO_R,

		// VGA
	output  [4:0] VGA_R,
	output  [4:0] VGA_G,
	output  [4:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_BLANK,
	
	output wire	stm_rst_o			= 1'bz // '0' to hold the microcontroller reset line, to free the SD card
		
  );

  
  reg [1:0] divclk = 0;
  
  always @(posedge clk25)
  begin
		divclk = divclk + 1;
  end
  
  wire clk7 = divclk[1];

  wire [5:0] r_to_vga, g_to_vga, b_to_vga;
  wire hsync_to_vga, vsync_to_vga, blank_to_vga;

  wire sdtest_init, sdtest_progress, sdtest_result;
  wire flashtest_init, flashtest_progress, flashtest_result;
  wire sdramtest_init, sdramtest_progress, sdramtest_result;
  wire sramtest_init, sramtest_progress, sramtest_result;
  wire hidetextwindow;

  wire [2:0] mousebutton;  // M R L
  wire mousetest_init;

  wire [15:0] flash_vendor_id;

  // wire joy_load_n;
   wire joy1up;
   wire joy1down;
   wire joy1left;
   wire joy1right;
   wire joy1fire1;
   wire joy1fire2;
//   wire joy1fire3;
   wire joy1start;
   wire joy2up;
   wire joy2down;
   wire joy2left;
   wire joy2right;
   wire joy2fire1;
   wire joy2fire2;
//   wire joy2fire3;
   wire joy2start;
	
	//assign joyP7_o = 1'b1;
	
	wire [11:0] joy1_o;
	wire [11:0] joy2_o;
	
	wire [11:0] snes_joy1_s;
	wire [11:0] snes_joy2_s;
	wire [11:0] sega_joy1_s;
	wire [11:0] sega_joy2_s;
	
	assign joy1_o = snes1_mode ? snes_joy1_s : sega_joy1_s;
	assign joy2_o = snes2_mode ? snes_joy2_s : sega_joy2_s;
 


	wire latch_snes1, clk_snes1, snes1_idle;
	wire latch_snes2, clk_snes2, snes2_idle;

	assign joy1_down_i = ( ~snes1_idle && snes1_mode ) ? latch_snes1 : 1'bZ;
	assign joy1_up_i   = ( ~snes1_idle && snes1_mode ) ? clk_snes1   : 1'bZ; 

	assign joy2_down_i = ( ~snes2_idle && snes2_mode ) ? latch_snes2 : 1'bZ;
	assign joy2_up_i   = ( ~snes2_idle && snes2_mode ) ? clk_snes2   : 1'bZ; 
	
	
joystick_snes #(.CLOCK(7)) snes1
(
				.clk_50 (clk7),
				.start(snes1_mode), // 1 to start the reading
				
				.data_in_snes (joy1_left_i) ,// pin 3 IN
				.latch_snes (latch_snes1),  // pin2 OUT
				.clk_snes (clk_snes1) ,     // pin1 OUT
				
				.finish (), //one positive pulse when finish
				.idle (snes1_idle), // positive when IDLE
				.buttons_snes(snes_joy1_s),
			
				
);

joystick_snes #(.CLOCK(7)) snes2
(
				.clk_50 (clk7),
				.start(snes2_mode), // 1 to start the reading
				
				.data_in_snes (joy2_left_i) ,// pin 3 IN
				.latch_snes (latch_snes2),  // pin2 OUT
				.clk_snes (clk_snes2) ,     // pin1 OUT
				
				.finish (), //one positive pulse when finish
				.idle (snes2_idle), // positive when IDLE
				.buttons_snes(snes_joy2_s),
			
				
);

// Llamamos a la maquina de estados para leer los 6 botones del mando de Megadrive
// Formato joy1_o [11:0] =  MXYZ SACB RLDU		
  sega_joystick joy (
	 .joy1_up_i		(joy1_up_i),
    .joy1_down_i	(joy1_down_i),
	 .joy1_left_i	(joy1_left_i),
	 .joy1_right_i	(joy1_right_i),
	 .joy1_p6_i		(joy1_p6_i),
	 .joy1_p9_i		(joy1_p9_i),
	 .joy2_up_i		(joy2_up_i),
    .joy2_down_i	(joy2_down_i),
	 .joy2_left_i	(joy2_left_i),
	 .joy2_right_i	(joy2_right_i),
	 .joy2_p6_i		(joy2_p6_i),
	 .joy2_p9_i		(joy2_p9_i),
	 .vga_hsync_n_s(VGA_HS),
	 .joyX_p7_o		(joyX_p7_o),
	 .joy1_o			(sega_joy1_s),
	 .joy2_o			(sega_joy2_s)
 );
 
 
	wire snes1_mode, snes2_mode;
	
  switch_mode teclas (
    .clk(clk7),
    .clkps2(ps2_clk_io),
    .dataps2(ps2_data_io),
    .sdtest(sdtest_init),
    .flashtest(flashtest_init),
    .mousetest(mousetest_init),
    .sdramtest(sdramtest_init),
    .sramtest(sramtest_init),
	 .snes1_mode(snes1_mode),
	 .snes2_mode(snes2_mode),
	 
    //.serialtest(),
    .hidetextwindow(hidetextwindow)
  );

  sdtest test_slot_sd (
    .clk(clk7),
    .rst(sdtest_init),
    .spi_clk(sd_sclk_o),
    .spi_di(sd_mosi_o),
    .spi_do(sd_miso_i),
    .spi_cs(sd_cs_n_o),
    .test_in_progress(sdtest_progress),
    .test_result(sdtest_result)
  );


  wire [7:0] mouse_x;
  wire [7:0] mouse_y;
  
  mousetest test_raton (
    .clk(clk7),
    .rst(mousetest_init),
    .ps2clk(ps2_mouse_clk_io),
    .ps2data(ps2_mouse_data_io),
    .botones(mousebutton),
	 .mX(mouse_x),
	 .mY(mouse_y)
  );


  sdramtest #(.FREQCLKSDRAM(100), .CL(2)) test_sdram (
    .clk(clk100),
    .clksdram(clk100n),
    .rst(sdramtest_init),
    .pll_locked(pll_locked),
    .test_in_progress(sdramtest_progress),
    .test_result(sdramtest_result),
    .sdram_clk(SDRAM_CLK),       // se�ales validas en flanco de suida de CK
    .sdram_cke(SDRAM_CKE),
    .sdram_dqmh_n(SDRAM_DQMH),    // mascara para byte alto o bajo
    .sdram_dqml_n(SDRAM_DQML),    // durante operaciones de escritura
    .sdram_addr(SDRAM_A), // pag.14. row=[12:0], col=[8:0]. A10=1 significa precharge all.
    .sdram_ba(SDRAM_BA),   // banco al que se accede
    .sdram_cs_n(SDRAM_nCS),
    .sdram_we_n(SDRAM_nWE),
    .sdram_ras_n(SDRAM_nRAS),
    .sdram_cas_n(SDRAM_nCAS),
    .sdram_dq(SDRAM_DQ)   
  );
  
   sramtest test_sram 
	(
		.clk(clk7),
		.rst(sramtest_init),
		.test_in_progress(sramtest_progress),
		.test_result(sramtest_result),
		
		.sram_addr (sram_addr_o), 
		.sram_oe_n (sram_oe_n_o),
		.sram_we_n (sram_we_n_o),
		.sram_data (sram_data_io)
  );

  updater mensajes (
    .clk(clk25),
    //.joystick1(~{joy1start,joy1up,joy1down,joy1left,joy1right,joy1fire1,joy1fire2}),  
    //.joystick2(~{joy2start,joy2up,joy2down,joy2left,joy2right,joy2fire1,joy2fire2}),

	 // joystick1 format -- MXYZ SA UDLR BC       joy1_o [11:0] -- MXYZ SACB RLDU	 
	 .joystick1(~{joy1_o[11], joy1_o[10],joy1_o[9],joy1_o[8],joy1_o[7],joy1_o[6],joy1_o[0],joy1_o[1],joy1_o[2],joy1_o[3],joy1_o[4],joy1_o[5]}),
	 // joystick2 format -- MXYZ SA UDLR BC       joy2_o [11:0] -- MXYZ SACB RLDU 
	 .joystick2(~{joy2_o[11], joy2_o[10],joy2_o[9],joy2_o[8],joy2_o[7],joy2_o[6],joy2_o[0],joy2_o[1],joy2_o[2],joy2_o[3],joy2_o[4],joy2_o[5]}),  

    .sdtest_progress(sdtest_progress),
    .sdtest_result(sdtest_result),
    
	 .sdramtest_progress(sdramtest_progress),
    .sdramtest_result(sdramtest_result),
	 
	 .sramtest_progress(sramtest_progress),
    .sramtest_result(sramtest_result),
	 
	 .snes1_mode(snes1_mode),
	 .snes2_mode(snes2_mode),
	 
    .mousebutton(mousebutton),
    .hidetextwindow(hidetextwindow),
    
    .r(r_to_vga),
    .g(g_to_vga),
    .b(b_to_vga),
    .hsync(hsync_to_vga),
    .vsync(vsync_to_vga),
    .blank(blank_to_vga),
	 
	 .mX(mouse_x),
	 .mY(mouse_y)
    );
	 
  
  assign VGA_R = r_to_vga[5:1];
  assign VGA_G = g_to_vga[5:1];
  assign VGA_B = b_to_vga[5:1];
  
  assign VGA_HS = hsync_to_vga;
  assign VGA_VS = vsync_to_vga;
  
  assign VGA_BLANK = blank_to_vga;


  audio_test audio (
    .clk(clk7),
    .left(AUDIO_L),
    .right(AUDIO_R)
    //.led1(testled1),
    //.led2(testled2)
  );

  
 
  
  
endmodule
