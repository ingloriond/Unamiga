//============================================================================
//
//  ZX Spectrum Next Top by Victor Trucco - 2020
//
//============================================================================

`default_nettype none

module LunarRescue_next(
	// Clocks
	input wire	clock_50_i,

	// Buttons
	input  wire btn_divmmc_n_i,
	input  wire btn_multiface_n_i,
	input  wire btn_reset_n_i,

	// Matrix keyboard
	output wire [7:0] keyb_row_o,
	input  wire [6:0] keyb_col_i,

	// SRAMs (AS7C34096)
	output wire	[18:0]sram_addr_o,
	inout wire	[15:0]sram_data_io,
	output wire	sram_we_n_o,
	output wire	sram_oe_n_o,
	output wire	[3:0]	sram_ce_n_o,
		
	// PS2
	inout wire	ps2_clk_io,
	inout wire	ps2_data_io,
	inout wire	ps2_mouse_clk_io,
	inout wire	ps2_mouse_data_io,

	// SD Card
	output wire	sd_cs_n_o,
	output wire sd_cs1_n_o,
	output wire	sd_sclk_o,
	output wire	sd_mosi_o,
	input wire	sd_miso_i,

	// Flash
	output wire flash_cs_n_o,
	output wire flash_sclk_o,
	output wire flash_mosi_o,
	input  wire flash_miso_i,
	output wire flash_wp_o,
	output wire flash_hold_o,

	// Joysticks
	input  wire joyp1_i,
	input  wire joyp2_i,
	input  wire joyp3_i,
	input  wire joyp4_i,
	input  wire joyp6_i,
	output wire joyp7_o,
	input  wire joyp9_i,
	output wire joysel_o,

	// Audio
	output wire       AUDIO_L,
	output wire       AUDIO_R,
	input wire	ear_port_i,
	output wire	mic_port_o,
   output wire audioint_o,
		
		// VGA
	output wire [2:0] VGA_R,
	output wire [2:0] VGA_G,
	output wire [2:0] VGA_B,
	output wire       VGA_HS,
	output wire       VGA_VS,
	output wire       csync_o,
		
	// Bus
	inout  wire bus_rst_n_io,
	output wire bus_clk35_o,
	output wire [15:0] bus_addr_o,
	inout  wire [7:0] bus_data_io,
	inout  wire bus_int_n_io,
	input  wire bus_nmi_n_i,
	input  wire bus_ramcs_i,
	input  wire bus_romcs_i,
	input  wire bus_wait_n_i,
	output wire bus_halt_n_o,
	output wire bus_iorq_n_o,
	output wire bus_m1_n_o,
	output wire bus_mreq_n_o,
	output wire bus_rd_n_o,
	output wire bus_wr_n_o,
	output wire bus_rfsh_n_o,
	input  wire bus_busreq_n_i,
	output wire bus_busack_n_o,
	input  wire bus_iorqula_n_i,

	// HDMI
	output wire [3:0] hdmi_p_o,
	output wire [3:0] hdmi_n_o,

	// I2C (RTC and HDMI)
	inout  wire i2c_scl_io,
	inout  wire i2c_sda_io,

	// ESP
	inout  wire esp_gpio0_io,
	inout  wire esp_gpio2_io,
	input  wire esp_rx_i,
	output wire esp_tx_o,

	// PI GPIO
	inout  wire [27:0] accel_io,

	// Vacant pins
	inout  wire extras_io	
	
);

	reg joysel_s = 0;
	reg [5:0] joy1_in_s;
	reg [5:0] joy2_in_s;
	
	always @(posedge clk_sys)
	begin
			joysel_s <= ~joysel_s;
			
			if (joysel_s == 0)
				joy1_in_s = {joyp9_i, joyp6_i, joyp1_i, joyp2_i, joyp3_i, joyp4_i};
			else
			   joy2_in_s = {joyp9_i, joyp6_i, joyp1_i, joyp2_i, joyp3_i, joyp4_i};
	end 
	
	assign joysel_o = joysel_s;

//assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_28;
wire pll_locked;
pll pll
(
	.CLK_IN1(clock_50_i),
	.CLK_OUT1(clk_sys),
	.CLK_OUT2(clk_28)
);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] kbjoy;
wire  [7:0] joystick_0,joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire  [7:0] audio;
wire 			hsync,vsync;
wire 			hs, vs;
wire 			r,g,b;

wire [15:0]RAB;
wire [15:0]AD;
wire [7:0]RDB;
wire [9:0]CAB;
wire [7:0]RWD;
wire [7:0]IB;
wire [5:0]SoundCtrl3;
wire [5:0]SoundCtrl5;
wire Rst_n_s;
wire RWE_n;
wire Video;
wire HSync;
wire VSync;

invaderst invaderst(
	.Rst_n(~(status[0] | status[6] |~btn_reset_n_i)),
	.Clk(clk_sys),
	.ENA(),
	.Coin(btn_coin),
	.Sel1Player(~btn_one_player),
	.Sel2Player(~btn_two_players),
	.Fire(~m_fireA),
	.MoveLeft(~m_left),
	.MoveRight(~m_right),
//	.DIP(dip),
	.RDB(RDB),
	.IB(IB),
	.RWD(RWD),
	.RAB(RAB),
	.AD(AD),
	.SoundCtrl3(SoundCtrl3),
	.SoundCtrl5(SoundCtrl5),
	.Rst_n_s(Rst_n_s),
	.RWE_n(RWE_n),
	.Video(Video),
	.CAB(CAB),
	.HSync(HSync),
	.VSync(VSync)
	);
		
LunarRescue_memory LunarRescue_memory (
	.Clock(clk_sys),
	.RW_n(RWE_n),
	.Addr(AD),
	.Ram_Addr(RAB),
	.Ram_out(RDB),
	.Ram_in(RWD),
	.Rom_out(IB)
	);
	
invaders_audio invaders_audio (
	.Clk(clk_sys),
	.S1(SoundCtrl3),
	.S2(SoundCtrl5),
	.Aud(audio)
	);		
	  
LunarRescue_Overlay LunarRescue_Overlay (
	.Video(Video),
	.Overlay(~status[5]),
	.CLK(clk_sys),
	.Rst_n_s(Rst_n_s),
	.HSync(HSync),
	.VSync(VSync),
	.CAB(CAB),
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs)
	);

wire [5:0] vga_r_s;	
wire [5:0] vga_g_s;	
wire [5:0] vga_b_s;	


mist_video #(.COLOR_DEPTH(3)) mist_video(
	.clk_sys(clk_sys),
	.SPI_SCK(1'b1),
	.SPI_SS3(1'b1),
	.SPI_DI(1'b1),
	.R({r,r,r}),
	.G({g,g,g}),
	.B({b,b,b}),
	.HSync(hs),
	.VSync(vs),
	.VGA_R          ( vga_r_s          ),
	.VGA_G          ( vga_g_s          ),
	.VGA_B          ( vga_b_s          ),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.rotate(2'b01),
	.scandoubler_disable(scandblctrl),
	.scanlines(status[4:3]),
	.ce_divider(1),
	
	.patrons        ( patrons      ),	
	.PATRON_ADJ_X   ( -100 ),
	.PATRON_ADJ_Y   ( (scandblctrl) ? -1050 : -700 ), 
	.PATRON_DOUBLE_WIDTH ( 0 ),
	.PATRON_DOUBLE_HEIGHT ( 0 ),
	.PATRON_SCROLL  ( -11'd1 ),	
	.osd_enable 	 ( osd_enable )
	
	);

	
assign VGA_R = vga_r_s[5:3];
assign VGA_G = vga_g_s[5:3];
assign VGA_B = vga_b_s[5:3];


dac dac (
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);
//-----------------------

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_fireG;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_fire2G;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

wire m_right4, m_left4, m_down4, m_up4, m_right3, m_left3, m_down3, m_up3;

wire btn_one_player = 	m_one_player;
wire btn_two_players = 	m_two_players;
wire btn_coin  = 			m_coin1;

wire kbd_intr;
wire [7:0] kbd_scancode;
wire [7:0] keys_s;
wire [7:0] osd_s;

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
wire [12:1] F_keys_s;

wire [8:0] player1_s;
wire [9:0] membrane_joy_s;
assign {m_two_players, m_one_player, m_coin1, m_fireB, m_fireA, m_up, m_down, m_left, m_right} = {player1_s | membrane_joy_s[8:0]} ;

//translate scancode to joystick
kbd_joystick #( .OSD_CMD	( 3'b011 )) k_joystick
(
  .clk         	( clk_sys ),
  .kbdint      	( kbd_intr ),
  .kbdscancode 	( kbd_scancode ), 
  
	.joystick_0 	( joy1_in_s ),
	.joystick_1		( joy2_in_s ),
		  
	//-- joystick_0 and joystick_1 should be swapped
	.joyswap 		( 0 ),
		
	//-- player1 and player2 should get both joystick_0 and joystick_1
	.oneplayer		( 1 ),

	//-- tilt, coin4-1, start4-1
//	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, player1_s[6], m_four_players, m_three_players, player1_s[8:7]} ),
		
	//-- fire12-1, up, down, left, right

	//.player1     ( {m_fireG,  m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player1     ( {m_fireG,  m_fireF, m_fireE, m_fireD, m_fireC, player1_s[5:0]} ),
	.player2     ( {m_fire2G, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
		
	//-- keys to the OSD
	.osd_o		   ( ),
	.osd_enable 	( 0 ),
	
	//-- Function keys
	.F_keys			( F_keys_s ), 
	
	//-- sega joystick
	.sega_clk  		( hs ),
	.sega_strobe	( joyp7_o )
		
		
);

	reg patrons = 0;
	wire btn_patrons_s;
	
	debounce #(.counter_size(9)) debounce 
  (
    .clk_i     ( clk_sys ),
    .button_i  ( m_fireG | membrane_joy_s[9]),
    .result_o  ( btn_patrons_s )    
	);
	
	always @(posedge btn_patrons_s)
	begin
			patrons <= ~patrons;
	end 
	
	//------------------------------------------------------------------
	//-- membrane keyboard
	//------------------------------------------------------------------

 reg btn_scandb_s = 0;
 debounce #(.counter_size(3)) debounce_nmi 
  (
    .clk_i     ( clk_sys ),
    .button_i  ( ((~btn_multiface_n_i) & membrane_joy_s[8]) | F_keys_s[2] ),
    .result_o  ( btn_scandb_s )  
	);
	
	reg scandblctrl = 0;
	always @(posedge btn_scandb_s)
	begin
			scandblctrl <= ~scandblctrl;
	end 
	
	 membrane_joystick membrane_joystick 
	 (
      .clock       		( clk_28 ),
      .reset       		( 0 ),

      .membrane_joy_o  	( membrane_joy_s ), // C, P2, P1, COIN, F2, F1, U, D, L, R
		
      .keyb_row_o   		( keyb_row_o ),   
      .i_membrane_cols  ( keyb_col_i )
	);
	


	//--------------------------------------------------------
	//-- Unused outputs
	//--------------------------------------------------------

	
	 // TODO: add support for HDMI output
   OBUFDS OBUFDS_c0  ( .O  ( hdmi_p_o[0]), .OB  ( hdmi_n_o[0]), .I (1'b1));
   OBUFDS OBUFDS_c1  ( .O  ( hdmi_p_o[1]), .OB  ( hdmi_n_o[1]), .I (1'b1));
   OBUFDS OBUFDS_c2  ( .O  ( hdmi_p_o[2]), .OB  ( hdmi_n_o[2]), .I (1'b1));
   OBUFDS OBUFDS_clk ( .O  ( hdmi_p_o[3]), .OB  ( hdmi_n_o[3]), .I (1'b1));
   
   // -- Interal audio (speaker, not fitted)
    assign audioint_o     = 1'b0;

	assign sram_we_n_o = 1'b1;
	assign sram_oe_n_o = 1'b1;
	assign sram_ce_n_o = 4'b1111;
	assign sram_addr_o = 19'd0;
	assign sram_data_io = 16'd0;

    //-- Spectrum Next Bus
    assign bus_addr_o     = 16'hFFFF;
    assign bus_busack_n_o = 1'b1;
    assign bus_clk35_o    = 1'b1;
    assign bus_data_io    = 8'hFF;
    assign bus_halt_n_o   = 1'b1;
    assign bus_iorq_n_o   = 1'b1;
    assign bus_m1_n_o     = 1'b1;
    assign bus_mreq_n_o   = 1'b1;
    assign bus_rd_n_o     = 1'b1;
    assign bus_rfsh_n_o   = 1'b1;
    assign bus_rst_n_io   = 1'b1;
    assign bus_wr_n_o     = 1'b1;

    //-- ESP 8266 module
    assign esp_gpio0_io   = 1'bZ;
    assign esp_gpio2_io   = 1'bZ;
    assign esp_tx_o = 1'b1;
	 
    //-- Addtional flash pins; used at IO2 and IO3 in Quad SPI Mode
    assign flash_hold_o   = 1'b1;
    assign flash_wp_o     = 1'b1;
	 
	 assign flash_cs_n_o  = 1'b1;
    assign flash_sclk_o  = 1'b1;
    assign flash_mosi_o  = 1'b1;

    assign ear_port_i = 1'b1;
		
	 assign i2c_scl_io = 1'bZ;
    assign i2c_sda_io = 1'bZ;

    //-- Mic Port (output, as it connects to the mic input on cassette deck)
    assign mic_port_o = 1'b0;

	 //-- CS2 is for internal SD socket
    assign sd_cs1_n_o = 1'b1;
	 
    // PI GPIO
    assign accel_io = 28'bZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;

    // Vacant pins
    assign extras_io = 1'b1;

	assign sd_cs_n_o = 1'b1;
	assign sd_cs1_n_o = 1'b1;
	assign sd_sclk_o = 1'b1;
	assign sd_mosi_o = 1'b1;

	assign csync_o = 1'b1;
	
endmodule