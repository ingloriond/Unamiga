//============================================================================
//
//  Multicore 2 Top by Victor Trucco
//
//============================================================================
//  unamiga Top modified by delgrom
//
//============================================================================
`default_nettype none

module Tetris_ua
(
	// Clocks
	input wire	clock_50_i,

   // SRAM
   output wire [18:0]sram_addr_o  = 21'b000000000000000000000,
   inout wire  [7:0]sram_data_io   = 8'bzzzzzzzz,
   output wire sram_we_n_o     = 1'b1,
   output wire sram_oe_n_o     = 1'b1,
		
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
	//output wire	mic_o					= 1'b0,

	// VGA
	output  [4:0] VGA_R,
	output  [4:0] VGA_G,
	output  [4:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

	//STM32
	input wire		stm_tx_i,
	output wire	stm_rx_o,
	//output wire	stm_rst_o			= 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,
	 
    output LED                    = 1'b1, // '0' is LED on	 
	 
	// SONIDO I2S
	output		  SCLK,
	output		  LRCLK,
	output		  MCLK,
	output	  	  SDIN	   
);

`include "rtl/build_id.v" 

localparam CONF_STR = {
	"P,Tetris.dat;", //13
   "S,DAT,Alternative ROM...;", //25	
	"O2,Service,Off,On;", //18,
	"O34,Scanlines,Off,25%,50%,75%;", //30
	"O5,Blend,Off,On;", //16
	"O7,Scandoubler,On,Off;", // 22
	"T0,Reset;", //9
	"V,v1.0." //7
};


assign LED = ~ioctl_downl;
//assign	stm_rst_o			= 1'bz;
//assign SDRAM_CLK = clk_sd;
assign SDRAM_CKE = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_sd;
wire pll_locked;
pll_mist pll(
	.inclk0(clock_50_i),
	.areset(0),
	.c0(clk_sd),//3xclk_sys
	.c1(clk_sys),//14.318,
	.c3(SDRAM_CLK),
	.locked(pll_locked)
	);
	
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        ypbpr;
wire [15:0] audio;
wire        hs, vs, hb, vb;
wire        blankn = ~(hb | vb);
wire  [2:0] g, r;
wire  [1:0] b;
wire [15:0] rom_addr;
wire [15:0] rom_do;
wire [15:0] gfx_addr;
wire [15:0] gfx_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

    

data_io #(.STRLEN(($size(CONF_STR)>>3))) data_io(
	.clk_sys       ( clk_sd      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	
	.data_in		 	( osd_s & keys_s ),
	.conf_str		( CONF_STR ),
	.status			( status ),
	
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
	.clk           ( clk_sd       ),
	.clkref        ( PCLK         ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {2'b0, rom_addr[15:1]}),
	.cpu1_q        ( rom_do ),

	// port2 for gfx
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] - 16'h8000 ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.gfx_addr      ( gfx_addr[15:1] ),
	.gfx_q         ( gfx_do )
);

always @(posedge clk_sd) begin
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
	reset <= status[0] | ~rom_loaded;
end


//wire [10:0] INP = ~{status[2],1'b1, (JoyPCFRLDU[5] | JoyPCFRLDU[6] | JoyPCFRLDU[7]), m_left2, m_right2, m_down2, m_fire2, m_left1, m_right1, m_down1, m_fire1};

wire [10:0] INP = ~{status[2],1'b1, (btn_coin), m_left2, m_right2, m_down2, m_fire2A | m_fire2B | m_fire2C | btn_two_players | m_fire2H, m_left, m_right, m_down, m_fireA | m_fireB | m_fireC | btn_one_player | m_fireH};

FPGA_ATetris FPGA_ATetris(
	.MCLK(clk_sys),		// 14.318MHz
	.RESET(reset),
	
	.INP(INP),		// Negative Logic

	.HPOS(HPOS),
	.VPOS(VPOS),
	.PCLK(PCLK),
	.PCLK_EN(PCLK_EN),
	.POUT(POUT),
	
	.AOUT(audio),
	
	.PRAD(rom_addr),
	.PRDT(rom_addr[0] ? rom_do[15:8] : rom_do[7:0]),

	.CRAD(gfx_addr),
	.CRDT(gfx_do)
);

wire			PCLK;
wire			PCLK_EN;
wire  [8:0] HPOS,VPOS;
wire  [7:0] POUT;
hvgen hvgen(
	.MCLK(clk_sys),
	.PCLK_EN(PCLK_EN),
	.HPOS(HPOS),
	.VPOS(VPOS),
	.iRGB(POUT),
	.oRGB({r,g,b}),
	.HBLK(hb),
	.VBLK(vb),
	.HSYN(hs),
	.VSYN(vs)
	);
	
	
wire direct_video_s = ~status[7] ^ direct_video;	
	
mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS2          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b,b[0]} : 0 ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
   .rotate     ( {2'b00} ),	
	.ce_divider     ( 1'b1             ),
	.blend          ( status[5]        ),
	.scandoubler_disable(direct_video_s  ),
	.scanlines      ( status[4:3]      ),
   .osd_enable     ( osd_enable )	
	);
	
	
dac #(
	.C_bits(16))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

// i2s audio
i2s_audio_out i2s_audio_out
(
	.reset       (reset),
	.clk         (clock_50_i), //CLOCK_50 o clk_50
	.sample_rate (1'b0        ), //1=96Khz
	.left_in     (audio << 1),
	.right_in    (audio << 1),
	.i2s_bclk    (SCLK        ),
	.i2s_lrclk   (LRCLK       ),
	.i2s_data    (SDIN        )
   );	
assign MCLK = clock_50_i; //CLOCK_50 o clk_50

// ////////////

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_fireG, m_fireH;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_fire2G, m_fire2H;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

wire m_right4, m_left4, m_down4, m_up4, m_right3, m_left3, m_down3, m_up3;


wire btn_one_player  = m_one_player;
wire btn_two_players = m_two_players;
wire btn_coin        = m_coin1 | m_coin2 | m_fireG | m_fire2G | (m_fireH & m_fireC);

wire kbd_intr;
wire [7:0] kbd_scancode;
wire [7:0] keys_s;

//wire       key_pressed;
//wire [7:0] key_code;
//wire       key_strobe;
//
//wire kbd_intr;
//wire [7:0] JoyPCFRLDU;
//wire [7:0] kbd_scancode;
//wire [7:0] keys_s;

//get scancode from keyboard
io_ps2_keyboard keyboard 
 (
  .clk       ( clk_sys ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

//translate scancode to joystick
//kbd_joystick k_joystick
//(
//  .clk         	( clk_sys ),
//  .kbdint      	( kbd_intr ),
//  .kbdscancode 	( kbd_scancode ), 
//  .JoyPCFRLDU     ( JoyPCFRLDU ),
//  .osd_o		      ( keys_s ),
//  // delgrom
//  .changeScandoubler    ( changeScandoubler)
//);

wire [15:0]joy1_s;
wire [15:0]joy2_s;
wire [8:0]controls_s;
wire osd_enable;
wire direct_video;
wire [1:0]osd_rotate;



kbd_joystick_ua #( .OSD_CMD    ( 3'b011 )) k_joystick
(
    .clk          ( clk_sys ),
    .kbdint       ( kbd_intr ),
    .kbdscancode  ( kbd_scancode ), 

    .joystick_0   ({ joy1_p9_i, joy1_p6_i, joy1_up_i, joy1_down_i, joy1_left_i, joy1_right_i }),
    .joystick_1   ({ joy2_p9_i, joy2_p6_i, joy2_up_i, joy2_down_i, joy2_left_i, joy2_right_i }),
      
    //-- joystick_0 and joystick_1 should be swapped
    .joyswap      ( 0 ),

    //-- player1 and player2 should get both joystick_0 and joystick_1
    .oneplayer    ( 0 ),

    //-- tilt, coin4-1, start4-1
    .controls     ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),

    //-- fire12-1, up, down, left, right

    .player1      ( {m_fireH,  m_fireG,  m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
    .player2      ( {m_fire2H, m_fire2G, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),

    .direct_video ( direct_video ),
    .osd_rotate   ( osd_rotate ),

    //-- keys to the OSD
    .osd_o        ( keys_s ),
    .osd_enable   ( osd_enable ),

    //-- sega joystick
    .sega_clk     ( hs ),		
    .sega_strobe  ( joyX_p7_o )      
);


	//---------------------------
	wire hard_reset = ~pll_locked;

		reg [15:0] power_on_s	= 16'b1111111111111111;
		reg [7:0] osd_s = 8'b11111111;
		
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

endmodule 
