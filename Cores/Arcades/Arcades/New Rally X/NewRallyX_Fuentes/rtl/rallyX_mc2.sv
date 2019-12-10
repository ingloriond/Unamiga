//---------------------------------------------------------------------------------
//-- FPGA New Rally-X for Spartan-3 Starter Board
//------------------------------------------------
//-- Copyright (c) 2005 MiSTer-X
//---------------------------------------------------------------------------------//
//
//  Top for Multicore 2
//  Victor Trucco
////---------------------------------------------------------------------------------//
//  19/10/2019 UnAmiga delgrom
//---------------------------------------------------------------------------------//
`default_nettype none

module rallyX_mc2 (
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
	output wire	[12:0]sdram_ad_o,
	inout wire	[15:0]sdram_da_io,
	output wire	[1:0]sdram_ba_o,
	output wire	[1:0]sdram_dqm_o,
	output wire	sdram_ras_o,
	output wire	sdram_cas_o,
	output wire	sdram_cke_o,
	output wire	sdram_clk_o,
	output wire	sdram_cs_o,
	output wire	sdram_we_o,

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
	output wire	joyX_p7_o			= 1'b0, //delgrom pongo el pin7 a cero

	// Audio
	output wire	dac_l_o				= 1'b0,
	output wire	dac_r_o				= 1'b0,
	input wire	ear_i,
	output wire	mic_o					= 1'b0,

		// VGA
	output wire	[4:0]vga_r_o,
	output wire	[4:0]vga_g_o,
	output wire	[4:0]vga_b_o,
	output wire	vga_hsync_n_o,
	output wire	vga_vsync_n_o,

		// HDMI
	//output wire	[7:0]tmds_o			= 8'b00000000,

		//STM32
	input wire	stm_tx_i,
	output wire	stm_rx_o,
	output wire	stm_rst_o			= 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
		
	inout wire	stm_b8_io, // CONF DATA0
	inout wire	stm_b9_io, //SPI SS2
	inout wire	stm_b12_io, // SPI SS3
	inout wire	stm_b13_io, // SPI SCK
	inout wire	stm_b14_io, // SPI DO
	inout wire	stm_b15_io  // SPI DI
);


//assign 		LED = 1;
assign 		dac_r_o = dac_l_o;

wire clock_24, clock_12;
pll pll(
	.inclk0(clock_50_i),
	.c0(clock_24)//24.576MHz
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD = v_scandoublerD; // delgrom 1'b0 vga, 1'b1 15khz 
wire        ypbpr;
wire  [7:0] audio;
wire 			hs, vs;
wire 			hb, vb;
wire 			blankn = ~(hb | vb);
wire [2:0] 	r, g;
wire [1:0] 	b;
wire 			key_strobe;
wire 			key_pressed;
wire  [7:0] key_code;


wire  [7:0] iDSW  = ~{ 8'b00000000 };
wire  [7:0] iCTR1 = ~{ m_coin, m_P1, m_up1, m_down1, m_right1, m_left1, m_fire1, 1'b0 };
wire  [7:0] iCTR2 = ~{ 1'b0, m_P2, m_up2, m_down2, m_right2, m_left2, m_fire2, 1'b0 };


fpga_nrx fpga_nrx
(
	// delgrom conecto el wire de reset
	.RESET( w_reset ),
	.CLK24M(clock_24),
	.hsync(hs),
	.vsync(vs),
	.hblank(hb),
	.vblank(vb),
	.r(r),
	.g(g),
	.b(b),
	.SND(audio),
	.DSW(iDSW),
	.CTR1(iCTR1),
	.CTR2(iCTR2),
	.LAMP()
);

	
video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) video
(
	.clk_sys        ( clock_24         ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b,1'b0} : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( {vga_r_o, 1'b0 } ),
	.VGA_G          ( {vga_g_o, 1'b0 } ),
	.VGA_B          ( {vga_b_o, 1'b0 } ),
	.VGA_VS         ( vga_vsync_n_o    ),
	.VGA_HS         ( vga_hsync_n_o    ),
	.scandoubler_disable( v_scandoublerD ),
	// delgrom scanlines
	.scanlines      (scandoublerD ? 2'b00 :  v_scanlines) 
	);

dac #(.C_bits(16))dac(
	.clk_i(clock_24),
	.res_n_i(1),
	.dac_i({audio,audio}),
	.dac_o(dac_l_o)
	);


// delgrom Pongo los joystick como en multicore1 ---------------	
wire m_up1     = joyBCPPFRLDU[0] | ~joy1_up_i;
wire m_down1   = joyBCPPFRLDU[1] | ~joy1_down_i;
wire m_left1   = joyBCPPFRLDU[2] | ~joy1_left_i;
wire m_right1  = joyBCPPFRLDU[3] | ~joy1_right_i;
wire m_fire1   = joyBCPPFRLDU[4] | ~joy1_p6_i;


wire m_up2     = ~joy2_up_i;
wire m_down2   = ~joy2_down_i;
wire m_left2   = ~joy2_left_i;
wire m_right2  = ~joy2_right_i;
wire m_fire2   = ~joy2_p6_i;

wire m_coin   	= joyBCPPFRLDU[7];
wire m_P1   	= joyBCPPFRLDU[5];
wire m_P2   	= joyBCPPFRLDU[6];
// delgrom Fin joysticks ---------------------------

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
//reg btn_fire2 = 0;
//reg btn_fire3 = 0;
reg btn_coin  = 0;

wire kbd_intr;
wire [8:0] joyBCPPFRLDU;
wire [7:0] kbd_scancode;

//get scancode from keyboard
io_ps2_keyboard keyboard 
 (
  .clk       ( clock_24 ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

//translate scancode to joystick
kbd_joystick k_joystick
(
  .clk         	(  clock_24 ),
  .kbdint      	(  kbd_intr ),
  .kbdscancode 	(  kbd_scancode ), 
  .joyBCPPFRLDU   ( joyBCPPFRLDU ),
  // delgrom Teclas scandbl, scanlines, reset
  .changeScandoubler    ( changeScandoubler),
  .changeScanlines    ( changeScanlines),
  .reset          (w_reset)  
);



// delgrom Cambiar entre 15khz y 31khz
wire changeScandoubler;
reg v_scandoublerD =1'b0;  // delgrom 1'b1 inicia a 15khz, 1'b0 inicia a  vga

always @(posedge changeScandoubler) 
begin
		v_scandoublerD <= ~v_scandoublerD;
end

// delgrom scanlines rotatorias (off, 25%, 50%, 75%)
wire changeScanlines;
reg [1:0] v_scanlines =  2'b00;

always @(posedge changeScanlines) 
begin
		v_scanlines <= v_scanlines + 1'b1;
end

// delgrom reset
wire w_reset;

endmodule
