//============================================================================
//
//  Multicore 2 Top by Victor Trucco
//
//============================================================================

`default_nettype none

module SuperZaxxon_MC2(
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
	input wire	ear_i,
	output wire	mic_o					= 1'b0,

		// VGA
	output  [4:0] VGA_R,
	output  [4:0] VGA_G,
	output  [4:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

		// HDMI
	output wire	[7:0]tmds_o			= 8'b00000000,

		//STM32
	input wire	stm_tx_i,
	output wire	stm_rx_o,
	output wire	stm_rst_o			= 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
		
	inout wire	stm_b8_io, 
	inout wire	stm_b9_io,

	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2
);

`include "rtl/build_id.v" 

localparam CONF_STR = {
	"P,Super Zaxxon.dat;",
	"S,DAT,Alternative ROM...;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Flip,Off,On;",
	"O8,Sound,Off,On;",
	"O9A,Lives,3,5,4,Free ships;",
	"OBC,Extra ship,40k,20k,30k,10k;",
	"T0,Reset;",
	"V,v2.0.",`BUILD_DATE
};
assign sram_we_n_o	= 1'b1;
assign sram_oe_n_o	= 1'b1;
assign stm_rst_o		= 1'bz;

wire          rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire           blend = status[5];
wire           flip  = status[6];
wire        service  = status[7];
wire           sound = status[8];
wire [1:0]     ships = ~status[10:9];
wire [1:0] extraship = status[12:11];

wire [7:0]       sw1 = {1'b0, sound, ships, 2'b11, extraship }; // cocktail(1) / sound(1) / ships(2) / N.U.(2) /  extra ship (2)

assign SDRAM_CLK = clk_sd;
assign SDRAM_CKE = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_sd;
wire pll_locked;
pll_mist pll(
	.inclk0(clock_50_i),
	.c0(clk_sd),//36
	.c1(clk_sys),//24
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        key_pressed;
wire        key_strobe;
wire  [7:0] key_code;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
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
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);
*/
wire [15:0] audio_l;
wire        hs, vs, cs, hb, vb;
wire        blankn;
wire  [2:0] g, r;
wire  [1:0] b;
wire [14:0] rom_addr;
wire [15:0] rom_do;
wire [13:0] gfx_addr;
wire [15:0] gfx_do;
wire [19:0] wave_addr;
wire [15:0] wave_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

// ROM structure
// 00000-06FFF CPU ROM   28k  u27-u28-u29-u29-u29
// 07000-0EFFF Tiledata  32k  u91-u90-u93-u92
// 0F000-0F7FF char1      2k  u68
// 0F800-0FFFF char2      2k  u69
// 10000-05FFF bg        24k  u113-u112-u111
// 16000-1BFFF spr       24k  u77-u78-u79
// 1C000-1C0FF          256b  u76
// 1C100-1C1FF          256b  u98


data_io #(
	.STRLEN(($size(CONF_STR)>>3)))
data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	
	.data_in	    ( osd_s & keys_s ),
	.conf_str		( CONF_STR 		),
	.status			( status 		),
	
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [24:0] gfx_ioctl_addr = ioctl_addr - 16'h7000;

reg port1_req, port2_req;
sdram #(36) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sd       ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {2'b00, rom_addr[14:1]}),
	.cpu1_q        ( rom_do ),
	.snd_addr      ( wave_addr[19:1] + 16'he100 ),
	.snd_q         ( wave_do ),

	// port2 for gfx
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {gfx_ioctl_addr[23:15], gfx_ioctl_addr[13:0]} ),
	.port2_ds      ( {gfx_ioctl_addr[14], ~gfx_ioctl_addr[14]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.gfx_addr      ( gfx_addr ),
	.gfx_q         ( gfx_do )
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
always @(posedge clk_sd) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | ~btn_n_i[4] | ~rom_loaded;
end

wire dl_wr = ioctl_wr && ioctl_addr < 17'h1c200;

zaxxon zaxxon(
	.clock_24(clk_sys),
	.reset(reset),
	
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_blankn(blankn),
	.video_hs(hs),
	.video_vs(vs),
	.video_csync(cs),

	.audio_out_l(audio_l),

	.coin1(btn_coin),
	.coin2(m_coin2),
	.start2(btn_two_players),
	.start1(btn_one_player),
	.left(m_left),
	.right(m_right),
	.up(m_up),
	.down(m_down),
	.fire(m_fireA),

	.sw1_input(sw1), // cocktail(1) / sound(1) / ships(2) / N.U.(2) /  extra ship (2)
	.sw2_input(8'h33), // coin b(4) / coin a(4)  -- "3" => 1c_1c

	.flip_screen(flip),

	.cpu_rom_addr ( rom_addr  ),
	.cpu_rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.map_addr     ( gfx_addr  ),
	.map_do       ( gfx_do    ),
	.wave_addr    ( wave_addr ),
	.wave_data    ( wave_do   ),

	.dl_addr      ( ioctl_addr[16:0] ),
	.dl_data      ( ioctl_dout ),
	.dl_wr        ( dl_wr )
);

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
	.B              ( blankn ? {b,b[1]} : 0 ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( vga_r_s          ),
	.VGA_G          ( vga_g_s          ),
	.VGA_B          ( vga_b_s          ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b1             ),
	.blend          ( blend            ),
	.rotate         ( {flip, rotate}   ),
	.scandoubler_disable(scandoublerD  ),
	.scanlines      ( scanlines        ),
	.osd_enable 	 ( osd_enable )
	
	);

assign VGA_R = vga_r_s[5:1];
assign VGA_G = vga_g_s[5:1];
assign VGA_B = vga_b_s[5:1];

dac #(
	.C_bits(16))
dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_l),
	.dac_o(AUDIO_L)
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
reg [3:0] clk_kbd;

always @(posedge clk_sys)
begin
    clk_kbd <= clk_kbd + 1'd1;
end

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_fireG;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_fire2G;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

wire m_right4, m_left4, m_down4, m_up4, m_right3, m_left3, m_down3, m_up3;

wire btn_one_player = 	~btn_n_i[1] | m_one_player;
wire btn_two_players = 	~btn_n_i[2] | m_two_players;
wire btn_coin  = 		~btn_n_i[3] | m_coin1;

wire kbd_intr;
wire [7:0] kbd_scancode;
wire [7:0] keys_s;

//get scancode from keyboard
io_ps2_keyboard keyboard 
 (
  .clk       ( clk_kbd[1] ),
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
  .clk         	( clk_kbd[1] ),
  .kbdint      	( kbd_intr ),
  .kbdscancode 	( kbd_scancode ), 
  
	.joystick_0 	({ joy1_p9_i, joy1_p6_i, joy1_up_i, joy1_down_i, joy1_left_i, joy1_right_i }),
	.joystick_1		({ joy2_p9_i, joy2_p6_i, joy2_up_i, joy2_down_i, joy2_left_i, joy2_right_i }),
		  
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
	.osd_o		   ( keys_s ),
	.osd_enable 	( osd_enable ),
	
	//-- sega joystick
	.sega_clk  		( hs ),
	.sega_strobe	( joyX_p7_o )
		
		
);

endmodule 
