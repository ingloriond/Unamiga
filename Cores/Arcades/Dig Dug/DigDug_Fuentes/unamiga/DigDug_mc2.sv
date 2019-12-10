//============================================================================
//
// Multicore 2 top by Victor Trucco
//
//============================================================================
// Unamiga delgrom 04/11/2019
//============================================================================


`default_nettype none

module DigDug
(
   // Clocks
	input wire	clock_50_i,

	// Buttons
	input wire [4:1]	btn_n_i,

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
//	input wire	ear_i,
//	output wire	mic_o					= 1'b0,

		// VGA
	output  [4:0] VGA_R,
	output  [4:0] VGA_G,
	output  [4:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

		// HDMI
//	output wire	[7:0]tmds_o			= 8'b00000000,

		//STM32
	input wire	stm_tx_i,
	output wire	stm_rx_o,
	output wire	stm_rst_o			= 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
		
//	inout wire	stm_b8_io, 
//	inout wire	stm_b9_io,

	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2
);

assign	stm_rst_o = 1'bz;


localparam CONF2_STR = {
	"DIGDUG;;",
	"O2,Rotate Controls,Off,On;",
	"O89,Difficulty,Medium,Hardest,Easy,Hard;",
	"OAB,Life,3,5,1,2;",
	"OCE,Bonus Life,M3,M4,M5,M6,M7,Nothing,M1,M2;",
	"OF,Allow Continue,No,Yes;",
	"OG,Demo Sound,Off,On;",
	"OH,Service Mode,Off,On;",
	"O34,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"T6,Reset;",
	"V,v1.00."
};

localparam CONF_STR = {	"P,DigDug.dat"};
localparam STRLEN = 12;

assign 		AUDIO_R = AUDIO_L;

wire clock_48, pll_locked;
pll pll(
	.inclk0(clock_50_i),
	.c0(clock_48),
	.c1(SDRAM_CLK),
	.locked (pll_locked)
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
wire [3:0] 	r, g, b;
wire 			key_strobe;
wire 			key_pressed;
wire  [7:0] key_code;
wire  [7:0] ioctl_index;
wire        ioctl_downl;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire [13:0] rom_addr;
wire [15:0] rom_do;

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clock_48) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
//	reset <= ~btn_n_i[4] | ~rom_loaded;
	reset <= ~btn_n_i[4] | pump_active_s; 
end

wire  [7:0] oPIX;
assign POUT = {oPIX[7:6],2'b00,oPIX[5:3],1'b0,oPIX[2:0],1'b0};
wire			PCLK;
wire  [8:0] HPOS,VPOS;
wire [11:0] POUT;
hvgen hvgen(
	.HPOS(HPOS),
	.VPOS(VPOS),
	.PCLK(PCLK),
	.iRGB(POUT),
	.oRGB({b,g,r}),
	.HBLK(hb),
	.VBLK(vb),
	.HSYN(hs),
	.VSYN(vs)
);


wire  [1:0] COIA = 2'b00;			// 1coin/1credit
wire  [2:0] COIB = 3'b001;			// 1coin/1credit
wire			CABI = 1'b1;
wire  		FRZE = 1'b1;

wire	[1:0] DIFC = status[9:8]+2'h2;
wire  [1:0] LIFE = status[11:10]+2'h2;
wire  [2:0] EXMD = status[14:12]+3'h3;
wire			CONT = ~status[15];
wire			DSND = ~status[16];
wire     SERVICE = status[17];

FPGA_DIGDUG GameCore( 
	 .RESET(reset),	
	.MCLK(clock_48),
	.rom_addr(rom_addr),
	.rom_do(rom_do),
	.INP0({SERVICE, 1'b0, 1'b0, btn_coin, btn_two_players, btn_one_player, m_fire2, m_fire1 }),
	.INP1({m_left2, m_down2, m_right2, m_up2, m_left1, m_down1, m_right1, m_up1}),
	.DSW0({LIFE,EXMD,COIB}),
	.DSW1({COIA,FRZE,DSND,CONT,CABI,DIFC}),
	.PH(HPOS),
	.PV(VPOS),
	.PCLK(PCLK),
	.POUT(oPIX),
	.SOUT(audio)
);

wire [5:0] vga_r_s;
wire [5:0] vga_g_s;
wire [5:0] vga_b_s;

assign VGA_R = vga_r_s[5:1];
assign VGA_G = vga_g_s[5:1];
assign VGA_B = vga_b_s[5:1];

	
mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clock_48         ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( vga_r_s          ),
	.VGA_G          ( vga_g_s          ),
	.VGA_B          ( vga_b_s          ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),	
	// .scandoubler_disable( scandoublerD ),
	// .scanlines      ( status[4:3]      ),	
    // delgrom scanlines and scandoubler
	.scanlines(scandoublerD ? 2'b00 : v_scanlines),
    .scandoubler_disable(v_scandoublerD),	
	//	
	.ypbpr          ( ypbpr            )
	);

dac #(.C_bits(16))dac(
	.clk_i(clock_48),
	.res_n_i(1),
	.dac_i({audio,audio}),
	.dac_o(AUDIO_L)
	);


// delgrom direct joystick buttons assignation
wire m_up1     = ~joy1_up_i | joyBCPPFRLDU[0];
wire m_down1   = ~joy1_down_i | joyBCPPFRLDU[1];
wire m_left1   = ~joy1_left_i | joyBCPPFRLDU[2];
wire m_right1  = ~joy1_right_i | joyBCPPFRLDU[3];
wire m_fire1   = ~joy1_p6_i | ~joy1_p9_i | joyBCPPFRLDU[4];

wire m_up2     = ~joy2_up_i;
wire m_down2   = ~joy2_down_i;
wire m_left2   = ~joy2_left_i;
wire m_right2  = ~joy2_right_i;
wire m_fire2   = ~joy2_p6_i | ~joy2_p9_i;

reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;

wire btn_coin   		 =  joyBCPPFRLDU[7];
wire btn_one_player   =  joyBCPPFRLDU[5];
wire btn_two_players  =  joyBCPPFRLDU[6];

// ----------------------------------------------------------

wire [7:0] osd_s;
wire pump_active_s;
wire [18:0] sram_addr_s;
wire [7:0] sram_data_s;
wire sram_we_n_s;
reg power_on_reset;
//wire hard_reset = ~btn_n_i[4] & ~btn_n_i[3]; // delgrom comento
wire hard_reset = w_reset; //delgrom

reg [15:0] power_on_s = 16'hffff;

	data_pump 	#(			.STRLEN 			( 12 )		)
	data_pump 	
		(
			.pclk        ( clock_48 ),

			//-- spi for OSD
			.sdi         ( SPI_DI  ),
			.sck         ( SPI_SCK ),
			.ss          ( SPI_SS2 ),
			.sdo         ( SPI_DO  ),

			.data_in		 ( osd_s ),
			.conf_str	 ( CONF_STR ),
						
			.pump_active_o		 ( pump_active_s ),
			.sram_a_o			 ( sram_addr_s ),
			.sram_d_o			 ( sram_data_s ),
			.sram_we_n_o		 ( sram_we_n_s ),
			.config_buffer_o	 ( )		
		);

		assign sram_addr_o   = pump_active_s ? sram_addr_s : { 2'b00000 , rom_addr };
		assign sram_data_io  = pump_active_s ? sram_data_s :  8'bZZZZZZZZ;
		assign rom_do[7:0]  	= sram_data_io;
		assign sram_oe_n_o   = 1'b0;
		assign sram_we_n_o   = sram_we_n_s;


		//--start the microcontroller OSD menu after the power on
		always @(posedge(clock_48))
		begin
				if (hard_reset == 1'b1)
					power_on_s <= 16'hffff;
				else if (power_on_s != 16'h0000)
					begin
						power_on_s <= power_on_s - 1;
						power_on_reset <= 1'b1;
						osd_s <= 8'b00111111;
					end
					else
						power_on_reset <= 1'b0;

				
				if (pump_active_s == 1'b1 && osd_s == 8'b00111111)
					osd_s <= 8'b11111111;
				
				
			end



wire kbd_intr;
wire [8:0] joyBCPPFRLDU;
wire [7:0] kbd_scancode;

//get scancode from keyboard
io_ps2_keyboard keyboard 
 (
  .clk       ( clock_48 ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

//translate scancode to joystick
kbd_joystick k_joystick
(
  .clk         	(  clock_48 ),
  .kbdint      	(  kbd_intr ),
  .kbdscancode 	(  kbd_scancode ), 
  .joyBCPPFRLDU   ( joyBCPPFRLDU ),
  // delgrom Teclas scandbl, scanlines, reset
  .changeScandoubler    ( changeScandoubler),
  .changeScanlines    ( changeScanlines),
  .reset          (w_reset)  
);


// delgrom Change between 15khz and 31khz
wire changeScandoubler;
reg v_scandoublerD =1'b1;  // delgrom 1'b1 starts 15khz, 1'b0 starts vga

always @(posedge changeScandoubler) 
begin
		v_scandoublerD <= ~v_scandoublerD;
end

// delgrom rotatory scanlines (off, 25%, 50%, 75%)
wire changeScanlines;
reg [1:0] v_scanlines =  2'b00;

always @(posedge changeScanlines) 
begin
		v_scanlines <= v_scanlines + 1'b1;
end

// delgrom reset
wire w_reset;




endmodule