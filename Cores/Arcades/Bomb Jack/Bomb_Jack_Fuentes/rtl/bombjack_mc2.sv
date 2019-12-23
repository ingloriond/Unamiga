//============================================================================
//
//  Multicore 2 Top by Victor Trucco
//
//============================================================================
//
//  Unamiga Top modified by delgrom 22/12/2019
//
//============================================================================

`default_nettype none

module bombjack_mc2 
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
//	output wire	sd_mosi_o			= 1'b0,
//	input wire	sd_miso_i,

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

assign stm_rst_o			= 1'bz;
//assign sram_we_n_o		= 1'b1;
//assign sram_oe_n_o		= 1'b1;
//assign sd_cs_n_o			= 1'bz;
//assign sd_sclk_o			= 1'bz;
//assign sd_mosi_o			= 1'bz;
//
//assign sram_we_n_o		= 1'b1;
//assign sram_oe_n_o		= 1'b1;
	
localparam CONF_STR = {
	"P,BombJack.dat"}; //;", //15
//	"O34,Scanlines,None,25%,50%,75%;", //31
//	"O5,Blend,Off,On;", //16
//	"T6,Reset;", //9
//	"V,v1.00." //8
//};

localparam STRLEN = 14; //15 + 31 + 16 + 9 + 8;

//assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
//assign 		SDRAM_CLK = clock_48;
assign 		SDRAM_CKE = 1;

wire clock_48, clock_12, clock_6, clock_4, pll_locked;
pll pll(
	.inclk0(clock_50_i),
	.c0(clock_48),
	.c1(clock_12),
	.c2(clock_6),
	.c3(clock_4),
	.c4(SDRAM_CLK),
	.locked(pll_locked)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD = v_scandoublerD; // delgrom 1'b0 vga, 1'b1 15khz ;
wire        ypbpr;
wire  [7:0] audio;
wire 			hs, vs;
wire 			hb, vb;
wire 			blankn = ~(hb | vb);
wire [3:0] 	r, g, b;
wire 			key_strobe;
wire 			key_pressed;
wire  [7:0] key_code;
wire [15:0] rom_addr;
wire [15:0] rom_do;
wire [12:0] bg_addr;
wire [31:0] bg_do;

//wire        rom_rd;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;


// OSD
reg power_on_reset = 0;
	 
data_io #(.STRLEN( STRLEN )) data_io(
	.clk_sys       ( clock_48      ),
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
wire [24:0] bg_ioctl_addr = ioctl_addr - 16'he000;
	
reg port1_req, port2_req;
sdram sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_48      ),

	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'hffff : {1'b0, rom_addr[15:1]} ),
	.cpu1_q        ( rom_do ),
	.cpu2_addr     ( 16'hffff ),
	.cpu2_q        ( ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {bg_ioctl_addr[12:0], bg_ioctl_addr[14]} ), // merge sprite roms to 32-bit wide words
	.port2_ds      ( {bg_ioctl_addr[13], ~bg_ioctl_addr[13]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( ioctl_downl ? 14'h3fff : {1'b0, bg_addr} ),
	.sp_q          ( bg_do )
);

// ROM download controller
always @(posedge clock_48) begin
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
wire hard_reset = ~pll_locked;
reg rom_loaded = 0;

always @(posedge clock_48) 
begin

	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	
	// reset <= ~btn_n_i[4] | ~rom_loaded | status[6];
    reset <= ~btn_n_i[4] | ~rom_loaded | status[6] | w_reset; // delgrom reset with ESC key
end

bombjack_top bombjack_top(
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
	.O_HBLANK(hb),
	.O_VBLANK(vb),	
	.p1_sw({"000",m_fire,m_down,m_up,m_left,m_right}),
	.p2_sw({"000",m_fire,m_down,m_up,m_left,m_right}),
	.s_sys({"1111",btn_two_players,btn_one_player,1'b1,btn_coin}),
	.cpu_rom_addr(rom_addr),
	.cpu_rom_data(rom_addr[0] ? rom_do[15:8] : rom_do[7:0]),
	.bg_rom_addr(bg_addr),
	.bg_rom_data(bg_do),
	.s_audio(audio),
	.RESETn(~reset),
	.clk_4M_en(clock_4),
	.clk_6M_en(clock_6),
	.clk_12M(clock_12),
	.clk_48M(clock_48)
	);
	
wire [5:0] vga_r_s;	
wire [5:0] vga_g_s;	
wire [5:0] vga_b_s;	
	
assign VGA_R = vga_r_s[5:1];
assign VGA_G = vga_g_s[5:1];
assign VGA_B = vga_b_s[5:1];	
	
mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clock_48         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS2          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r ),//blankn ? r : 0   ),
	.G              ( g ),//blankn ? g : 0   ),
	.B              ( b ),//blankn ? b : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( vga_r_s            ),
	.VGA_G          ( vga_g_s            ),
	.VGA_B          ( vga_b_s            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	///	.ce_divider(1),
	.rotate         ( {1'b1,status[2]} ),
	//delgrom ----- scanlines and blend -------
   //.blend         ( status[5] ),
	.blend         ( scandoublerD ? 1'b0 : v_blend ), 
	//.scandoubler_disable( 0 ),
	.scandoubler_disable(scandoublerD  ),
	//	.scanlines      ( status[4:3]      ),
	.scanlines(scandoublerD ? 2'b00 : scanlines_s),	
	// ------------------------------------------
	.ypbpr          ( ypbpr            )
	);
/*	
user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clock_48       ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (),//CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);
*/
dac #(.C_bits(16))dac(
	.clk_i(clock_48),
	.res_n_i(1),
	.dac_i({audio,audio}),
	.dac_o(AUDIO_L)
	);
	
//											
// wire m_up     = JoyPCFRLDU[0] | ~joy1_s[0] | ~joy2_s[0];
// wire m_down   = JoyPCFRLDU[1] | ~joy1_s[1] | ~joy2_s[1];
// wire m_left   = JoyPCFRLDU[2] | ~joy1_s[2] | ~joy2_s[2];
// wire m_right  = JoyPCFRLDU[3] | ~joy1_s[3] | ~joy2_s[3];
// wire m_fire   = JoyPCFRLDU[4] | ~joy1_s[4] | ~joy1_s[5] | ~joy1_s[6] | ~joy2_s[4] | ~joy2_s[5] | ~joy2_s[6];

// wire btn_one_player = ~btn_n_i[1];
// wire btn_two_players = ~btn_n_i[2];
// wire btn_coin  = ~btn_n_i[3];


//
wire m_up     = JoyPCFRLDU[0] | ~joy1_up_i;
wire m_down   = JoyPCFRLDU[1] | ~joy1_down_i;
wire m_left   = JoyPCFRLDU[2] | ~joy1_left_i;
wire m_right  = JoyPCFRLDU[3] | ~joy1_right_i;
wire m_fire   = JoyPCFRLDU[4] | ~joy1_p6_i | ~joy1_p9_i;

wire btn_one_player  =  JoyPCFRLDU[5];
wire btn_two_players =  JoyPCFRLDU[6];
wire btn_coin  		=  JoyPCFRLDU[7];



wire kbd_intr;
wire [7:0] JoyPCFRLDU;
wire [7:0] kbd_scancode;
wire [7:0] keys_s;

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
  .clk         	( clock_48 ),
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


/*
//--- Joystick read with sega 6 button support----------------------
	


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
	//---------------------------
*/

		reg [15:0] power_on_s	= 16'b1111111111111111;
		reg [7:0] osd_s = 8'b11111111;
		
		//--start the microcontroller OSD menu after the power on
		always @(posedge clock_48) 
		begin
		
				if (hard_reset == 1)
					power_on_s = 16'b1111111111111111;
				else if (power_on_s != 0)
				begin
					power_on_s = power_on_s - 1;
					power_on_reset = 1;
					osd_s = 8'b00111111;
				end 
				else
					power_on_reset = 0;
					
				
				if (ioctl_downl == 1 && osd_s == 8'b00111111)
					osd_s = 8'b11111111;
			
		end 
		
		
		
	// delgrom -- ---------------------  scanlines
	
	wire changeScanlines; 
	wire [1:0] scanlines_s;
	
	always @(negedge changeScanlines)
	begin
			scanlines_s = scanlines_s + 1'b1;
	end		

	// delgrom -- ---------------------  reset
	wire w_reset;

	// delgrom -- --------------------- scandoubler
	wire changeScandoubler;
	reg v_scandoublerD =1'b0;  // delgrom 1'b1 starts at 15khz, 1'b0 starts in vga 31khz


	// change between 15khz and 31khz
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
		
		
		

endmodule
