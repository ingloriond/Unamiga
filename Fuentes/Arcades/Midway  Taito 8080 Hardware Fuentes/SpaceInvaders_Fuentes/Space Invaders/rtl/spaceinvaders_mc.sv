//============================================================================
//
//  Multicore Top by Victor Trucco - 2020
//
//============================================================================

`default_nettype none

module spaceinvaders_mc(
	// Clocks
	input wire	clock_50_i,

	// Buttons
	input wire [4:1]	btn_n_i,

	// SRAMs (AS7C34096)
	output wire	[18:0]sram_addr_o  = 18'b0000000000000000000,
	inout wire	[7:0]sram_data_io	= 8'bzzzzzzzz,
	output wire	sram_we_n_o		= 1'b1,
	output wire	sram_oe_n_o		= 1'b1,
	output wire	[1:0]	sram_ce_n_o = 2'b11,
		
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
	output wire	joy1_p7_o			= 1'b1,
	output wire	joy2_p7_o			= 1'b1,

	// Audio
	output        AUDIO_L,
	output        AUDIO_R,
	input wire	ear_i,
	output wire	mic_o					= 1'b0,

		// VGA
	output  [2:0] VGA_R,
	output  [2:0] VGA_G,
	output  [2:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	
	output wire [7:0]	leds_n_o	= 8'd0
	
);

//assign LED = 1;
assign AUDIO_R = AUDIO_L;
assign joy2_p7_o = joy1_p7_o;

assign sram_we_n_o		= 1'b1;
assign sram_oe_n_o		= 1'b1;
assign sram_ce_n_o		= 2'b11;

wire clk_sys;
wire pll_locked;
pll pll
(
	.inclk0(clock_50_i),
	.areset(),
	.c0(clk_sys)
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
	.Rst_n(~(status[0] | status[6] | ~btn_n_i[4])),
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
	.HSync(HSync),
	.VSync(VSync)
	);
		
spaceinvaders_memory spaceinvaders_memory (
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
	  
spaceinvaders_overlay spaceinvaders_overlay (
	.Video(Video),
	.Overlay(~status[5]),
	.CLK(clk_sys),
	.Rst_n_s(Rst_n_s),
	.HSync(HSync),
	.VSync(VSync),
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
	.scandoubler_disable(scandoublerD),
	.ce_divider(1),
	.scanlines(status[4:3]),
	
	.patrons        ( patrons ),	
	.PATRON_ADJ_X   ( -100 ),
	.PATRON_ADJ_Y   ( -700 ), 
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

wire btn_one_player = 	~btn_n_i[1] | m_one_player;
wire btn_two_players = 	~btn_n_i[2] | m_two_players;
wire btn_coin  = 			~btn_n_i[3] | m_coin1;

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

//translate scancode to joystick
kbd_joystick #( .OSD_CMD	( 3'b011 )) k_joystick
(
  .clk         	( clk_sys ),
  .kbdint      	( kbd_intr ),
  .kbdscancode 	( kbd_scancode ), 
  
	.joystick_0 	({ joy1_p6_i, joy1_p9_i, joy1_up_i, joy1_down_i, joy1_left_i, joy1_right_i }),
	.joystick_1		({ joy2_p6_i, joy2_p9_i, joy2_up_i, joy2_down_i, joy2_left_i, joy2_right_i }),
		  
	//-- joystick_0 and joystick_1 should be swapped
	.joyswap 		( 0 ),
		
	//-- player1 and player2 should get both joystick_0 and joystick_1
	.oneplayer		( 1 ),

	//-- tilt, coin4-1, start4-1
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
		
	//-- fire12-1, up, down, left, right

	.player1     ( {m_fireG,  m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2G, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
		
	//-- keys to the OSD
	.osd_o		   ( ),
	.osd_enable 	( 0 ),
	
	//-- sega joystick
	.sega_clk  		( hs ),
	.sega_strobe	( joy1_p7_o )
		
		
);

	reg patrons = 0;
	wire btn_patrons_s;
	
	debounce #(.counter_size(9)) debounce 
  (
    .clk_i     ( clk_sys ),
    .button_i  ( m_fireG ),
    .result_o  ( btn_patrons_s )    
	);
	
	always @(posedge btn_patrons_s)
	begin
			patrons <= ~patrons;
	end 
	



endmodule