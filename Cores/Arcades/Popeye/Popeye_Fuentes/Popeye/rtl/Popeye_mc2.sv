//============================================================================
//
//  Multicore 2 Top by Victor Trucco
//
//============================================================================
//
//  Unamiga2 Top modified by Delgrom 02/01/2020
//
//============================================================================

`default_nettype none

module Popeye_mc2(
// Clocks
	input wire	clock_50_i,

	// Buttons
	//input wire [4:1]	btn_n_i,

	// SRAMs (AS7C34096)
//	output wire	[18:0]sram_addr_o  = 18'b0000000000000000000,
//	inout wire	[7:0]sram_data_io	= 8'bzzzzzzzz,
//	output wire	sram_we_n_o		= 1'b1,
//	output wire	sram_oe_n_o		= 1'b1,
		
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
	input         SPI_SS2//,
	//output		  SPI_nWAIT

);

`include "rtl/build_id.v" 

localparam CONF_STR = {
	"P,Popeye.dat;", //13
	"O34,Scanlines,Off,25%,50%,75%;", //30
	"O5,Blend,Off,On;", // 16
	"O7,Service,Off,On;",// 18   Beep on REV4 ROM, not needed
	"T0,Reset;", // 9
	"V,v1.0." // 7
};

localparam STRLEN = 13 + 30 + 16 + 18 + 9 + 7;

assign stm_rst_o = 1'bz;
	//assign sram_we_n_o		= 1'b1;
	//assign sram_oe_n_o		= 1'b1;
	//assign SPI_nWAIT		= 1'b1;
		
//assign LED = ~ioctl_downl;
assign SDRAM_CLK = sdram_clk;
assign SDRAM_CKE = 1;
assign AUDIO_R = AUDIO_L;

wire sys_clk, sdram_clk, clk_80;
wire pll_locked;
pll_mist pll(
	.inclk0(clock_50_i),
	.c0(sdram_clk),//80
	.c1(sys_clk),//40
	.c2(clk_80),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD = v_scandoublerD; // delgrom 1'b0 vga, 1'b1 15khz ;
wire        ypbpr;
wire [15:0] audio;
wire        hs, vs, cs;
wire        blankn;
wire  [2:0] g, r;
wire  [1:0] b;
wire [14:0] rom_addr;
wire [15:0] rom_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io #(.STRLEN( STRLEN )) data_io(
	.clk_sys       ( sys_clk      ),
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
	.clk           ( clk_80 ), //sdram_clk       ),

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

	// port2 for gfx
	.port2_req     ( ),
	.port2_ack     ( ),
	.port2_a       ( ),
	.port2_ds      ( ),
	.port2_we      ( ),
	.port2_d       ( ),
	.port2_q       ( ),

	.gfx_addr      ( ),
	.gfx_q         ( )
);

always @(posedge sdram_clk) begin
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
always @(posedge sys_clk) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	//reset <= status[0] | ~btn_n_i[4] | ~rom_loaded;
	reset <= status[0] | ~rom_loaded;
end

popeye popeye(
	.clock_40(sys_clk),
	.reset(reset),
	.tv15Khz_mode(scandoublerD),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_csync(cs),
	.video_blankn(blankn),
	.video_hs(hs),
	.video_vs(vs),
	.audio_out(audio),
	.coin(btn_coin),
	.start1(btn_one_player),
	.start2(btn_two_players),
	.right1(m_right),
	.left1(m_left),
	.up1(m_up),
	.down1(m_down),
	.fire1(m_fire),
	.right2(m_right),
	.left2(m_left),
	.up2(m_up),
	.down2(m_down),
	.fire2(m_fire),
	.sw1("0000"),
	.sw2("01000101"),
	//.service(1'b0),//status[7]),
	.service(status[7]),
	.cpu_rom_addr(rom_addr),
	.cpu_rom_do(rom_addr[0] ? rom_do[15:8] : rom_do[7:0])
	);

wire vs_out;
wire hs_out;
assign VGA_VS = scandoublerD | vs_out;
assign VGA_HS = scandoublerD ? cs : hs_out;

wire [5:0] vga_r_s;	
wire [5:0] vga_g_s;	
wire [5:0] vga_b_s;	


mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( sys_clk          ),
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
	.VGA_VS         ( vs_out           ),
	.VGA_HS         ( hs_out           ),
	.ce_divider     ( 1'b1             ),
	.blend          ( status[5]            ),
	.rotate         ( {1'b1, status[2]}   ),
	//.scandoubler_disable(1),//scandoublerD  ),
	.scandoubler_disable( scandoublerD  ),
	//.scanlines      ( "00"),//status[3:4]        ),
	.scanlines      ( status[4:3]      ),
	.no_csync       ( 1'b1             ),
	.ypbpr          ( ypbpr            )
	);

assign VGA_R = vga_r_s[5:1];
assign VGA_G = vga_g_s[5:1];
assign VGA_B = vga_b_s[5:1];

dac #(
	.C_bits(16))
dac_l(
	.clk_i(sys_clk),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

/* wire m_up     = JoyPCFRLDU[0] | ~joy1_s[0] | ~joy2_s[0];
wire m_down   = JoyPCFRLDU[1] | ~joy1_s[1] | ~joy2_s[1];
wire m_left   = JoyPCFRLDU[2] | ~joy1_s[2] | ~joy2_s[2];
wire m_right  = JoyPCFRLDU[3] | ~joy1_s[3] | ~joy2_s[3];
wire m_fire   = JoyPCFRLDU[4] | ~joy1_s[4] | ~joy2_s[4];
wire m_bomb   = JoyPCFRLDU[8] | ~joy1_s[5] | ~joy2_s[5];

wire btn_one_player = 	~btn_n_i[1] | JoyPCFRLDU[5];
wire btn_two_players = 	~btn_n_i[2] | JoyPCFRLDU[6];
wire btn_coin  = 			~btn_n_i[3] | JoyPCFRLDU[7]; */

wire m_up     = JoyPCFRLDU[0] | ~joy1_up_i | ~joy2_up_i;
wire m_down   = JoyPCFRLDU[1] | ~joy1_down_i | ~joy2_down_i;
wire m_left   = JoyPCFRLDU[2] | ~joy1_left_i | ~joy2_left_i;
wire m_right  = JoyPCFRLDU[3] | ~joy1_right_i | ~joy2_right_i;
wire m_fire   = JoyPCFRLDU[4] | ~joy1_p6_i | ~joy2_p6_i | JoyPCFRLDU[8] | ~joy1_p9_i | ~joy2_p9_i;

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
  .clk       ( sys_clk ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

//translate scancode to joystick
kbd_joystick k_joystick
(
  .clk         	( sys_clk ),
  .kbdint      	( kbd_intr ),
  .kbdscancode 	( kbd_scancode ), 
  .JoyPCFRLDU     ( JoyPCFRLDU ),
  .osd_o		      ( keys_s ),
  // delgrom
  .changeScandoubler    ( changeScandoubler)
);

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
	
		reg [15:0] power_on_s	= 16'b1111111111111111;
		reg [7:0] osd_s = 8'b11111111;
		
		wire hard_reset = ~pll_locked;
		
		//--start the microcontroller OSD menu after the power on
		always @(posedge sys_clk) 
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
		
	// delgrom Cambiar entre 15khz y 31khz
	wire changeScandoubler;
	reg v_scandoublerD =1'b1;  // delgrom 1'b1 inicia a 15khz, 1'b0 inicia a  vga


	always @(posedge changeScandoubler) 
	begin
		v_scandoublerD <= ~v_scandoublerD;
	end		
		
		

endmodule 
