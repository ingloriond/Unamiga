//============================================================================
//
//  Unamiga2 Top by Delgrom 15/01/2020
//
//============================================================================
module Ninjakun_unamiga (
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
		
	// inout wire	stm_b8_io, 
	// inout wire	stm_b9_io,

	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2//,
	// output		  SPI_nWAIT

);
`include "rtl\build_id.v" 

localparam CONF_STR = {
	"P,Ninjakun.dat;", //15
	//"O2,Rotate Controls,Off,On;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;", //45
	"O5,Blend,Off,On;", //16
	"O8,Difficulty,Normal,Hard;", //26
	"O9A,Lives,4,3,2,5;", //18
	"OB,1st Extra,30000,40000;", //25
	"OCD,2nd Extra (Every),50000,70000,90000,None;", //45
	"OF,Allow Continue,No,Yes;", //25
	"OG,Free Play,No,Yes;", //20
	"OH,Endless(If Free Play),No,Yes;", //32
	"OE,Demo Sound,Off,On;", //21
	"OI,Name Letters,8,3;", //20
	"T0,Reset;", //9
	"V,v1.00." //8
};

localparam STRLEN = 15 + 45 + 16 + 26 + 18 + 25 + 45 + 25 + 20 + 32 + 21 + 20 + 9 + 8;


//assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;

assign stm_rst_o = 1'bz;
// assign sram_we_n_o	= 1'b1;
// assign sram_oe_n_o	= 1'b1;
// assign SPI_nWAIT = 1'b1;
//assign SDRAM_nCS = 1'b1;
//assign SDRAM_nWE = 1'b1;

//assign 		SDRAM_CLK = CLOCK_48;
assign 		SDRAM_CKE = 1;

//wire CLOCK_48, pll_locked;
//pll_mist pll(
//	.inclk0(clock_50_i),
//	.c0(CLOCK_48),
//	.locked(pll_locked)
//	);

wire CLOCK_48, pll_locked;
pll_mist pll(
    .inclk0(clock_50_i),
    .c0(SDRAM_CLK),
    .c1(CLOCK_48),
    .locked(pll_locked)
    );	
		
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD = v_scandoublerD; // delgrom 1'b0 vga, 1'b1 15khz ;;
wire        ypbpr;
wire [15:0] audio;
wire        hs, vs;
wire [3:0] 	r, g, b;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

/*
ROM Structure (same as the original)
fg gfx 32k ninja-6.7n ninja-7.7p ninja-8.7s ninja-9.7t
bg gfx 32k ninja-10.2c ninja-11.2d ninja-12.4c ninja-13.4d
cpu1   32k ninja-1.7a ninja-2.7b ninja-3.7d ninja-4.7e 
cpu2   32k ninja-5.7h ninja-2.7b ninja-3.7d ninja-4.7e
*/

// data_io data_io(
	// .clk_sys       ( CLOCK_48     ),
	// .SPI_SCK       ( SPI_SCK      ),
	// .SPI_SS2       ( SPI_SS2      ),
	// .SPI_DI        ( SPI_DI       ),
	// .ioctl_download( ioctl_downl  ),
	// .ioctl_index   ( ioctl_index  ),
	// .ioctl_wr      ( ioctl_wr     ),
	// .ioctl_addr    ( ioctl_addr   ),
	// .ioctl_dout    ( ioctl_dout   )
// );

//data_io #(.STRLEN( STRLEN )) data_io(
data_io #(.STRLEN(($size(CONF_STR)>>3))     ) data_io(
	.clk_sys       ( CLOCK_48     ),
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




wire [24:0] cpu_ioctl_addr = ioctl_addr - 17'h10000;
reg         port1_req, port2_req;

wire [14:0] cpu1_rom_addr, cpu2_rom_addr;
wire [15:0] cpu1_rom_do, cpu2_rom_do;
wire [12:0] sp_rom_addr;
wire [31:0] sp_rom_do;
wire        sp_rdy;
wire [12:0] fg_rom_addr;
wire [31:0] fg_rom_do;
wire [12:0] bg_rom_addr;
wire [31:0] bg_rom_do;

sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( CLOCK_48     ),

	// port1 used for main + aux CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( cpu_ioctl_addr[23:1] ),
	.port1_ds      ( {cpu_ioctl_addr[0], ~cpu_ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {1'b0, cpu1_rom_addr[14:1]} ),
	.cpu1_q        ( cpu1_rom_do ),
	.cpu2_addr     ( ioctl_downl ? 16'hffff : {1'b1, cpu2_rom_addr[14:1]} ),
	.cpu2_q        ( cpu2_rom_do ),

	// port2 for graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {ioctl_addr[23:15], ioctl_addr[14], ioctl_addr[12:0]} ),
	.port2_ds      ( {ioctl_addr[13], ~ioctl_addr[13]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.fg_addr       ( ioctl_downl ? 15'h7fff : {1'b0, fg_rom_addr} ),
	.fg_q          ( fg_rom_do ),
	.sp_addr       ( ioctl_downl ? 15'h7fff : {1'b0, sp_rom_addr} ),
	.sp_q          ( sp_rom_do ),
	.sp_rdy        ( sp_rdy ),
	.bg_addr       ( ioctl_downl ? 15'h7fff : {1'b1, bg_rom_addr} ),
	.bg_q          ( bg_rom_do )
);

// ROM download controller
always @(posedge CLOCK_48) begin
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
always @(posedge CLOCK_48) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	//reset <= status[0] | buttons[1] | ~rom_loaded;
	//reset <= status[0] | ~btn_n_i[4] | ~rom_loaded;  -- mc2
	reset <= status[0] | ~rom_loaded;
end

wire        PCLK_EN;
wire  [8:0] HPOS,VPOS;
wire [11:0] POUT;

ninjakun_top ninjakun_top(
	.RESET(reset),
	.MCLK(CLOCK_48),
	.CTR1(~{2'b11, btn_one_player, 1'b0, m_fire, m_bomb, m_right, m_left }),
	.CTR2(~{~btn_coin, 1'b1, btn_two_players, 1'b0, m_fire, m_bomb, m_right, m_left }),
	.DSW1({~status[8], ~status[14], ~status[13:12], ~status[11], ~status[10:9], 1'b0}),
	.DSW2({~status[17], ~status[16], 1'b0, ~status[15], ~status[18], 3'b111}),
	.PH(HPOS),
	.PV(VPOS),
	.PCLK_EN(PCLK_EN),
	.POUT(oPIX),
	.SNDOUT(audio),
	.CPU1ADDR(cpu1_rom_addr),
	.CPU1DT(cpu1_rom_addr[0] ? cpu1_rom_do[15:8] : cpu1_rom_do[7:0]),
	.CPU2ADDR(cpu2_rom_addr),
	.CPU2DT(cpu2_rom_addr[0] ? cpu2_rom_do[15:8] : cpu2_rom_do[7:0]),
	.sp_rom_addr(sp_rom_addr),
	.sp_rom_data(sp_rom_do),
	.sp_rdy(sp_rdy),
	.fg_rom_addr(fg_rom_addr),
	.fg_rom_data(fg_rom_do),
	.bg_rom_addr(bg_rom_addr),
	.bg_rom_data(bg_rom_do)
);

wire  [7:0] oPIX;
assign		POUT = {{oPIX[7:6],oPIX[1:0]},{oPIX[5:4],oPIX[1:0]},{oPIX[3:2],oPIX[1:0]}};

hvgen hvgen(
	.CLK(CLOCK_48),
	.PCLK_EN(PCLK_EN),
	.HPOS(HPOS),
	.VPOS(VPOS),
	.iRGB(POUT),
	.oRGB({b,g,r}),
	.HSYN(hs),
	.VSYN(vs)
);

wire vs_out;
wire hs_out;
assign VGA_VS = scandoublerD | vs_out;
assign VGA_HS = scandoublerD ? ~(hs_out^vs_out) : hs_out;

wire [5:0] vga_r_s;	
wire [5:0] vga_g_s;	
wire [5:0] vga_b_s;	

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(11)) mist_video(
	.clk_sys        ( CLOCK_48         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS2          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( b                ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( vga_r_s          ),
	.VGA_G          ( vga_g_s          ),
	.VGA_B          ( vga_b_s          ),
	.VGA_VS         ( vs_out           ),
	.VGA_HS         ( hs_out           ),
	.rotate         ( {1'b1,status[2]} ),
	.ce_divider		  ( 1'b1             ),
	.blend          ( status[5]        ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
	);

assign VGA_R = vga_r_s[5:1];
assign VGA_G = vga_g_s[5:1];
assign VGA_B = vga_b_s[5:1];

//user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
//	.clk_sys        (CLOCK_48       ),
//	.conf_str       (CONF_STR       ),
//	.SPI_CLK        (SPI_SCK        ),
//	.SPI_SS_IO      (CONF_DATA0     ),
//	.SPI_MISO       (SPI_DO         ),
//	.SPI_MOSI       (SPI_DI         ),
//	.buttons        (buttons        ),
//	.switches       (switches       ),
//	.scandoubler_disable (scandoublerD	  ),
//	.ypbpr          (ypbpr          ),
//	.key_strobe     (key_strobe     ),
//	.key_pressed    (key_pressed    ),
//	.key_code       (key_code       ),
//	.joystick_0     (joystick_0     ),
//	.joystick_1     (joystick_1     ),
//	.status         (status         )
//	);

dac #(.C_bits(16))dac(
	.clk_i(CLOCK_48),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);
// ---------- mist
//											Rotated														Normal
//wire m_up     = ~status[2] ? btn_left | joystick_0[1] | joystick_1[1] : btn_up | joystick_0[3] | joystick_1[3];
//wire m_down   = ~status[2] ? btn_right | joystick_0[0] | joystick_1[0] : btn_down | joystick_0[2] | joystick_1[2];
/* wire m_left   = status[2] ? btn_down | joystick_0[2] | joystick_1[2] : btn_left | joystick_0[1] | joystick_1[1];
wire m_right  = status[2] ? btn_up | joystick_0[3] | joystick_1[3] : btn_right | joystick_0[0] | joystick_1[0];
wire m_fire   = btn_fire1 | joystick_0[4] | joystick_1[4];
wire m_bomb   = btn_fire2 | joystick_0[5] | joystick_1[5];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
//reg btn_fire3 = 0;
reg btn_coin  = 0;

always @(posedge CLOCK_48) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up         	<= key_pressed; // up
			'h72: btn_down        	<= key_pressed; // down
			'h6B: btn_left      		<= key_pressed; // left
			'h74: btn_right       	<= key_pressed; // right
			'h76: btn_coin				<= key_pressed; // ESC
			'h05: btn_one_player   	<= key_pressed; // F1
			'h06: btn_two_players  	<= key_pressed; // F2
//			'h14: btn_fire3 			<= key_pressed; // ctrl
			'h11: btn_fire2 			<= key_pressed; // alt
			'h29: btn_fire1   		<= key_pressed; // Space
		endcase
	end
end */

// --------------------- mc2

/* wire m_up     = JoyPCFRLDU[0] | ~joy1_s[0] | ~joy2_s[0];
wire m_down   = JoyPCFRLDU[1] | ~joy1_s[1] | ~joy2_s[1];
wire m_left   = JoyPCFRLDU[2] | ~joy1_s[2] | ~joy2_s[2];
wire m_right  = JoyPCFRLDU[3] | ~joy1_s[3] | ~joy2_s[3];
wire m_fire   = JoyPCFRLDU[4] | ~joy1_s[4] | ~joy2_s[4];
wire m_bomb   = JoyPCFRLDU[8] | ~joy1_s[5] | ~joy2_s[5];

wire btn_one_player = 	~btn_n_i[1] | JoyPCFRLDU[5];
wire btn_two_players = 	~btn_n_i[2] | JoyPCFRLDU[6];
wire btn_coin  = 			~btn_n_i[3] | JoyPCFRLDU[7]; */




// --------------------- unamiga
//wire m_up     = JoyPCFRLDU[0] | ~joy1_up_i | ~joy2_up_i;
//wire m_down   = JoyPCFRLDU[1] | ~joy1_down_i | ~joy2_down_i;
wire m_left   = JoyPCFRLDU[2] | ~joy1_left_i | ~joy2_left_i;
wire m_right  = JoyPCFRLDU[3] | ~joy1_right_i | ~joy2_right_i;
wire m_fire   = JoyPCFRLDU[4] | ~joy1_p6_i |  ~joy2_p6_i;
wire m_bomb   = JoyPCFRLDU[8] | ~joy1_p9_i | ~joy2_p9_i;


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
  .clk       ( CLOCK_48 ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

//translate scancode to joystick
kbd_joystick k_joystick
(
  .clk         	( CLOCK_48 ),
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
		always @(posedge CLOCK_48) 
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
	reg v_scandoublerD =1'b0;  // delgrom 1'b1 inicia a 15khz, 1'b0 inicia a  vga


	always @(posedge changeScandoubler) 
	begin
		v_scandoublerD <= ~v_scandoublerD;
	end		
		

endmodule
