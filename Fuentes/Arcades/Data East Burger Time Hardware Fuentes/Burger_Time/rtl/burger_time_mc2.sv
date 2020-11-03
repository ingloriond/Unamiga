//============================================================================
//
//  Multicore 2 Top by Victor Trucco
//
//
//============================================================================
//
//  06/01/2019  Unamiga Top modified by Delgrom
//
//============================================================================
`default_nettype none

module burger_time_mc2
(
// Clocks
	input wire	clock_50_i,

	// Buttons
	// input wire [4:1]	btn_n_i,

	// SRAMs (AS7C34096)
//	output wire	[18:0]sram_addr_o  = 18'b0000000000000000000,
//	inout wire	[7:0]sram_data_io	= 8'bzzzzzzzz,
//	output wire	sram_we_n_o		= 1'b1,
//	output wire	sram_oe_n_o		= 1'b1,
		
	// SDRAM	(H57V256)
/* 	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQMH,
	output        SDRAM_DQML,
	output        SDRAM_CKE,
	output        SDRAM_nCS,
	output        SDRAM_nWE,
	output        SDRAM_nRAS,
	output        SDRAM_nCAS,
	output        SDRAM_CLK, */

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
	output        VGA_VS//,

		// HDMI
	// output wire	[7:0]tmds_o			= 8'b00000000,

		//STM32
	// input wire	stm_tx_i,
	// output wire	stm_rx_o,
	// output wire	stm_rst_o			= 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
		
	// inout wire	stm_b8_io, 
	// inout wire	stm_b9_io,

	// input         SPI_SCK,
	// output        SPI_DO,
	// input         SPI_DI,
	// input         SPI_SS2
);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"O34,Scanlines,Off,25%,50%,75%;", //30
	"O5,Blend,Off,On;", // 16
	"T6,Reset;", // 9
	"V,v1.10." // 8
	};

localparam STRLEN = 30 + 16 + 9 + 8;

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [9:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD = v_scandoublerD; // delgrom 1'b0 vga, 1'b1 15khz ;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;

//assign LED = 1;
//assign sram_we_n_o		= 1'b1;
//assign sram_oe_n_o		= 1'b1;
//assign stm_rst_o			= 1'bz;

wire clk_12, clk_24;
wire pll_locked;

pll pll(
	.inclk0(clock_50_i),
	.areset(0),
	.c0(clk_12),
	.c1(clk_24)
	);



burger_time burger_time(
	.clock_12(clk_12),
	//.reset(status[0] | status[6] | ~btn_n_i[4]),
	.reset(status[0] | status[6] | w_reset),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_csync(),
	.video_blankn(blankn),
	.video_hs(hs),
	.video_vs(vs),
	.audio_out(audio),  
	.start2(btn_two_players),
	.start1(btn_one_player),
	.coin1(btn_coin),
	.fire1(m_fire),
	.right1(m_right),
	.left1(m_left),
	.down1(m_down),
	.up1(m_up),
	.fire2(m_fire),
	.right2(m_right),
	.left2(m_left),
	.down2(m_down),
	.up2(m_up),
	.dbg_cpu_addr()
	);

wire [10:0] audio;

dac #(11) dac(
	.clk_i(clk_12),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

wire hs, vs;
wire [2:0] r, g;
wire [1:0] b;
wire       blankn;

wire [5:0] vga_r_s;	
wire [5:0] vga_g_s;	
wire [5:0] vga_b_s;	

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_24           ),
	// .SPI_SCK        ( SPI_SCK          ),
	// .SPI_SS3        ( SPI_SS2          ),
	// .SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b[1], b} : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( vga_r_s          ),
	.VGA_G          ( vga_g_s          ),
	.VGA_B          ( vga_b_s          ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( {2'b11} ),
	.ce_divider     ( 1'b1             ),
	// delgrom scanlines, blend with keys (not menu)
	//.blend          ( status[5]        ),
	.blend          ( v_blend          ),
	.scandoubler_disable( scandoublerD ),
	.no_csync       ( 1'b0             ),
	//.scanlines      ( status[4:3]      ),
	.scanlines      ( scanlines_s      ),
	.ypbpr          ( ypbpr            )
	);
	
assign VGA_R = vga_r_s[5:1];
assign VGA_G = vga_g_s[5:1];
assign VGA_B = vga_b_s[5:1];


/* data_io #(
	.STRLEN(STRLEN))
data_io(
	.clk_sys       ( clk_24      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	
	.data_in		 	( keys_s ),
	.conf_str		( CONF_STR ),
	.status			( status )
); */

// wire m_up     = JoyPCFRLDU[0] | ~joy1_s[0] | ~joy2_s[0];
// wire m_down   = JoyPCFRLDU[1] | ~joy1_s[1] | ~joy2_s[1];
// wire m_left   = JoyPCFRLDU[2] | ~joy1_s[2] | ~joy2_s[2];
// wire m_right  = JoyPCFRLDU[3] | ~joy1_s[3] | ~joy2_s[3];
// wire m_fire   = JoyPCFRLDU[4] | ~joy1_s[4] | ~joy2_s[4];
// wire m_bomb   = JoyPCFRLDU[8] | ~joy1_s[5] | ~joy2_s[5];

// wire btn_one_player = 	~btn_n_i[1] | JoyPCFRLDU[5];
// wire btn_two_players = 	~btn_n_i[2] | JoyPCFRLDU[6];
// wire btn_coin  = 			~btn_n_i[3] | JoyPCFRLDU[7];

// delgrom atari joystick
wire m_up     = JoyPCFRLDU[0] | ~joy1_up_i    | ~joy2_up_i;
wire m_down   = JoyPCFRLDU[1] | ~joy1_down_i  | ~joy2_down_i;
wire m_left   = JoyPCFRLDU[2] | ~joy1_left_i  | ~joy2_left_i;
wire m_right  = JoyPCFRLDU[3] | ~joy1_right_i | ~joy2_right_i;
wire m_fire   = JoyPCFRLDU[4] | ~joy1_p6_i    | ~joy2_p6_i | JoyPCFRLDU[8] | ~joy1_p9_i    | ~joy2_p9_i;
//wire m_bomb   = JoyPCFRLDU[8] | ~joy1_p9_i    | ~joy2_p9_i;

wire btn_one_player = 	JoyPCFRLDU[5];
wire btn_two_players = 	JoyPCFRLDU[6];
wire btn_coin  = 		JoyPCFRLDU[7];




wire kbd_intr;
wire [8:0] JoyPCFRLDU;
wire [7:0] kbd_scancode;
wire [7:0] keys_s;

//get scancode from keyboard
io_ps2_keyboard keyboard 
 (
  .clk       ( clk_12 ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

//translate scancode to joystick
kbd_joystick k_joystick
(
  .clk         	( clk_12 ),
  .kbdint      	( kbd_intr ),
  .kbdscancode 	( kbd_scancode ), 
  .JoyPCFRLDU     ( JoyPCFRLDU ),
  .osd_o		      ( keys_s ),
   // delgrom
  .changeScandoubler    ( changeScandoubler),
  .changeScanlines    ( changeScanlines),
  .reset          (w_reset),
  .changeBlend    ( changeBlend)
);

	//-- scanlines
	
	wire changeScanlines; // delgrom
	wire [1:0] scanlines_s;
	
	always @(negedge changeScanlines) // delgrom	
	begin
			scanlines_s = scanlines_s + 1;			
	end		

	// delgrom reset
	wire w_reset;

	// delgrom
	wire changeScandoubler;
	reg v_scandoublerD =1'b0;  // delgrom 1'b1 inicia a 15khz, 1'b0 inicia a  vga


	// delgrom Cambiar entre 15khz y 31khz
	always @(posedge changeScandoubler) 
	begin
		v_scandoublerD <= ~v_scandoublerD;
	end

	// delgrom -- ---------------------  blend
	wire changeBlend; 

	wire v_blend;
	
	always @(negedge changeBlend)
	begin
		v_blend = v_blend + 1'b1;
	end	

//--- Joystick read with sega 6 button support----------------------
/*	
	reg [11:0]joy1_s; 	
	reg [11:0]joy2_s; 
	reg joyP7_s;

	reg [7:0]state_v = 8'd0;
	reg j1_sixbutton_v = 1'b0;
	reg j2_sixbutton_v = 1'b0;
	
	always @(negedge hs) 
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
	
*/
endmodule
