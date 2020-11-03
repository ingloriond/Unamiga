module SonSon_unamiga(
	// Clocks
	input wire	clock_50_i,

	// Buttons
	//input wire [4:1]	btn_n_i,

	// SRAMs (AS7C34096)
	// output wire	[18:0]sram_addr_o  = 18'b0000000000000000000,
	// inout wire	[7:0]sram_data_io	= 8'bzzzzzzzz,
	// output wire	sram_we_n_o		= 1'b1,
	// output wire	sram_oe_n_o		= 1'b1,
		
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
	//input wire	ear_i,
	//output wire	mic_o					= 1'b0,

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

localparam CONF_STR = {      
	//"SONSON;;",
	"P,sonson.dat;",
	"S,DAT,Alternative ROM...;",		
	//"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"O6,Freeze,Off,On;",
	//"O7,Flip,Off,On;",
	"O8,Test,Off,On;",
	"O9,Start RGB 15KHZ,Off,On;",	
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire       rotate    = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend     = status[5];
wire       freeze   = status[6];
wire       flip   = status[7];
wire       test   = status[8];

//assign sram_we_n_o		= 1'b1;
//assign sram_oe_n_o		= 1'b1;
assign stm_rst_o			= 1'bz;

//assign LED = ~ioctl_downl;
assign SDRAM_CKE = 1; 
//assign SDRAM_CLK = clk_sd;
wire clk_sys, clk_sd;
wire pll_locked;

pll pll(
	.inclk0(clock_50_i),
	.areset(0),
	.c0(clk_sys),//24
	.c1(SDRAM_CLK),
	.c2(clk_sd),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD = (cnt_changeScandoubler)? v_scandoublerD : status[9]; // delgrom 1'b0 vga, 1'b1 15khz ;;;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

// user_io #(
	// .STRLEN(($size(CONF_STR)>>3)))
// user_io(
	// .clk_sys        (clk_sys        ),
	// .conf_str       (CONF_STR       ),
	// .SPI_CLK        (SPI_SCK        ),
	// .SPI_SS_IO      (CONF_DATA0     ),
	// .SPI_MISO       (SPI_DO         ),
	// .SPI_MOSI       (SPI_DI         ),
	// .buttons        (buttons        ),
	// .switches       (switches       ),
	// .scandoubler_disable (scandoublerD	  ),
	// .ypbpr          (ypbpr          ),
	// .no_csync       (no_csync       ),
	// .key_strobe     (key_strobe     ),
	// .key_pressed    (key_pressed    ),
	// .key_code       (key_code       ),
	// .joystick_0     (joystick_0     ),
	// .joystick_1     (joystick_1     ),
	// .status         (status         )
	// );

wire [15:0] cpu_rom_addr;	
wire [15:0] rom_do;

wire [12:0] snd_rom_addr;
wire [15:0] snd_do;

wire [13:1] tile_rom_addr;
wire [15:0] tile_do;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io #(
	.STRLEN(($size(CONF_STR)>>3)))
data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	// delgrom unamiga
	.SPI_DO        ( SPI_DO       ),	
	.data_in		( osd_s & keys_s ),
	.conf_str		( CONF_STR ),
	.status			( status ),
	//
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
	.clk           ( clk_sd      ),

	// port1 used for main CPU + tiledata
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {1'b0, cpu_rom_addr[15:1]} ),
	.cpu1_q        ( rom_do ),
	.tile_addr     ( ioctl_downl ? 16'hffff : {1'b1, 2'b00, tile_rom_addr} ),
	.tile_q        ( tile_do ),

	// port2 for sound CPU
	.port2_req     ( port2_req    ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),
	.snd_addr      ( snd_rom_addr[12:1] ),
	.snd_q         ( snd_do )
);

// ROM download controller
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

// reset signal generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	reg [15:0] reset_count;
	ioctl_downlD <= ioctl_downl;

	if (status[0] | buttons[1] | ~rom_loaded) reset_count <= 16'hffff;		
	else if (reset_count != 0) reset_count <= reset_count - 1'd1;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= reset_count != 16'h0000;

end

wire  [9:0] snd_l, snd_r;
wire        hs, vs, hb, vb;
reg         blankn;
wire  [3:0] g,b,r;
reg         clk_vid_en; // 6 MHz

always @(posedge clk_sys) begin
  reg [1:0] count;
  count <= count + 1'd1;

  clk_vid_en <= 0;
  if (count == 0) clk_vid_en <= 1;

  if (clk_vid_en) blankn <= ~(hb | vb);
end

target_top target_top(
	.clk_sys(clk_sys),
	.clk_vid_en(clk_vid_en),
	.reset_in(reset),
  .snd_l(snd_l),
  .snd_r(snd_r),
	.vid_hs(hs),
	.vid_vs(vs),
	.vid_hb(hb),
	.vid_vb(vb),
	.vid_r(r),
	.vid_g(g),
	.vid_b(b),
	//.inputs_p1(~{2'b00,m_down,m_up,m_right,m_left,1'b0,m_fireA}),
	//.inputs_p2(~{2'b00,m_down2,m_up2,m_right2,m_left2,1'b0,m_fire2A}),
	.inputs_p1(~{2'b00,m_down,m_up,m_right,m_left,1'b0,m_fireA | m_fireB}),
	.inputs_p2(~{2'b00,m_down2,m_up2,m_right2,m_left2,1'b0,m_fire2A | m_fire2B}),	
	.inputs_sys(~{2'b00,m_coin2,m_coin1,2'b00,m_two_players,m_one_player}),
	.inputs_dip1(~{flip,test,6'b011111}),
	.inputs_dip2(~{freeze,7'b1111111}),
	.cpu_rom_addr(cpu_rom_addr),
	.cpu_rom_do(cpu_rom_addr[0] ? rom_do[15:8] : rom_do[7:0]),
	.snd_rom_addr(snd_rom_addr),
	.snd_rom_do(snd_rom_addr[0] ? snd_do[15:8] : snd_do[7:0]),
	.tile_rom_addr(tile_rom_addr),
	.tile_rom_do(tile_do)
  );

wire [5:0] vga_r_s;	
wire [5:0] vga_g_s;	
wire [5:0] vga_b_s;

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS2          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? b : 0   ),
	.HSync          ( ~hs              ),
	.VSync          ( ~vs              ),
	.VGA_R          ( vga_r_s          ),
	.VGA_G          ( vga_g_s          ),
	.VGA_B          ( vga_b_s          ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( { 1'b1, rotate } ),
	.ce_divider     ( 1'b1             ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
//	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         ),
// .patrons        ( status[8]      ),		
//	.PATRON_ADJ_X   ( -400 ),
//	.PATRON_ADJ_Y   ( -500 ), 
//	.PATRON_DOUBLE_WIDTH ( 1 ),
//	.PATRON_DOUBLE_HEIGHT ( 1 ),
//	.PATRON_SCROLL  ( 1 ),	
	.osd_enable 	 ( osd_enable )

	);

assign VGA_R = vga_r_s[5:1];
assign VGA_G = vga_g_s[5:1];
assign VGA_B = vga_b_s[5:1];


dac #(
	.C_bits(10))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(snd_l),
	.dac_o(AUDIO_L)
	);

dac #(
	.C_bits(10))
dac_r(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(snd_r),
	.dac_o(AUDIO_R)
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



wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

// arcade_inputs inputs (
	// .clk         ( clk_sys     ),
	// .key_strobe  ( key_strobe  ),
	// .key_pressed ( key_pressed ),
	// .key_code    ( key_code    ),
	// .joystick_0  ( joystick_0  ),
	// .joystick_1  ( joystick_1  ),
	// .rotate      ( rotate      ),
	// .orientation ( 2'b10       ),
	// .joyswap     ( 1'b0        ),
	// .oneplayer   ( 1'b1        ),
	// .controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	// .player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	// .player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
// );

wire btn_one_player = 	m_one_player;
wire btn_two_players = 	m_two_players;
wire btn_coin  = 			m_coin1;


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
//kbd_joystick #( .OSD_CMD	( 3'b011 )) k_joystick
kbd_joystick_atari #( .OSD_CMD	( 3'b011 )) k_joystick
(
  .clk         	( clk_sys ),
  .kbdint      	( kbd_intr ),
  .kbdscancode 	( kbd_scancode ), 
  
	.joystick_0 	({ joy1_p6_i, joy1_p9_i, joy1_up_i, joy1_down_i, joy1_left_i, joy1_right_i }),
	.joystick_1		({ joy2_p6_i, joy2_p9_i, joy2_up_i, joy2_down_i, joy2_left_i, joy2_right_i }),
		  
	//-- joystick_0 and joystick_1 should be swapped
	.joyswap 		( 0 ),
		
	//-- player1 and player2 should get both joystick_0 and joystick_1
	.oneplayer		( 0 ),

	//-- tilt, coin4-1, start4-1
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
		
	//-- fire12-1, up, down, left, right

	.player1     ( {m_fireG,  m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2G, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
		
	//-- keys to the OSD
	.osd_o		   ( keys_s ),
	.osd_enable 	( osd_enable ),
	
	//-- sega joystick
	//.sega_clk  		( hs ),
	//.sega_strobe	( joyX_p7_o )
	// -- Change scandoubler
	.changeScandoubler		( changeScandoubler )		
);

	// -- ------------------------ delgrom Cambiar entre 15khz y 31khz

	wire changeScandoubler;
	reg v_scandoublerD =1'b0;  // delgrom 1'b1 inicia a 15khz, 1'b0 inicia a  vga
	reg cnt_changeScandoubler = 1'b0;

	always @(posedge changeScandoubler) 
	begin
		v_scandoublerD <= ~v_scandoublerD;
		cnt_changeScandoubler = 1'b1;
	end
	


endmodule 