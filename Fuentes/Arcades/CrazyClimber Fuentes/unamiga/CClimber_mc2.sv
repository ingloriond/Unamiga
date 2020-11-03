module CClimber_mc2 (

// Clocks
	input wire	clock_50_i,

	// Buttons
	input wire [4:1]	btn_n_i,

	// PS2
	inout wire	ps2_clk_io			= 1'bz,
	inout wire	ps2_data_io			= 1'bz,
	inout wire	ps2_mouse_clk_io  = 1'bz,
	inout wire	ps2_mouse_data_io = 1'bz,

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
	output wire	joyX_p7_o,

	// Audio
	output        AUDIO_L,
	output        AUDIO_R,
	input wire	ear_i,
	output wire	mic_o					= 1'b0,

		// VGA
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS//,
);


assign AUDIO_R = AUDIO_L;
//assign stm_rst_o = 1'b0;

wire clock_24, clock_12, clock_6;
pll pll(
	.inclk0(clock_50_i),
	.c0(clock_24),//48.784
	.c1(clock_12),//12.196
	.c2(clock_6)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD = v_scandoublerD; // delgrom 1'b0 vga, 1'b1 15khz 
wire        ypbpr;
wire [10:0] ps2_key;
wire [15:0] audio;
wire hs, vs;
wire hb, vb;
wire blankn = ~(hb | vb);
wire [2:0] r, g;
wire [1:0] b;


crazy_climber crazy_climber (
	.clock_12(clock_12),	
	// delgrom conecto el wire de reset
	.reset(w_reset),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hblank(hb),
	.video_vblank(vb),
	.video_hs(hs),
	.video_vs(vs),
	.audio_out(audio),
	.start2(btn_two_players),
	.start1(btn_one_player),
	.coin1(btn_coin),

	.r_right1(m_right1),//right Arrow
	.r_left1(m_left1),//left Arrow
	.r_down1(m_down1),//down Arrow
	.r_up1(m_up1),//up Arrow
	.l_right1(m_right2),//D
	.l_left1(m_left2),//A
	.l_down1(m_down2),//S
	.l_up1(m_up2),////W
  
	.r_right2(m_right1),//right Arrow
	.r_left2(m_left1),//left Arrow
	.r_down2(m_down1),//down Arrow
	.r_up2(m_up1),//up Arrow
	.l_right2(m_right2),//D
	.l_left2(m_left2),//A
	.l_down2(m_down2),//S
	.l_up2(m_up2)////W
	);

video_mixer video_mixer(
	.clk_sys(clock_24),
	.ce_pix(clock_6),
	.ce_pix_actual(clock_6),
	.R(blankn ? {r} : "000"),
	.G(blankn ? {g} : "000"),
	.B(blankn ? {b,1'b0} : "000"),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(vga_r_s),
	.VGA_G(vga_g_s),
	.VGA_B(vga_b_s),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoublerD(scandoublerD),
	.scanlines(scandoublerD ? 2'b00 : scanlines_s),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
	);

	wire [5:0]vga_r_s;
	wire [5:0]vga_g_s;
	wire [5:0]vga_b_s;
	assign VGA_R = vga_r_s[5:1];
	assign VGA_G = vga_g_s[5:1];
	assign VGA_B = vga_b_s[5:1];

dac #(
	.MSBI(15),
	.INV(1'b1))
dac(
	.CLK(clock_24),
	.RESET(0),
	.DACin(audio),
	.DACout(AUDIO_L)
	);

// delgrom Pongo los joystick como en multicore1 ---------------	
wire m_up1     = joyBCPPFRLDU[0] | ~joy1_up_i;
wire m_down1   = joyBCPPFRLDU[1] | ~joy1_down_i;
wire m_left1   = joyBCPPFRLDU[2] | ~joy1_left_i;
wire m_right1  = joyBCPPFRLDU[3] | ~joy1_right_i;


wire m_up2     = ~joy2_up_i;
wire m_down2   = ~joy2_down_i;
wire m_left2   = ~joy2_left_i;
wire m_right2  = ~joy2_right_i;


wire m_fire   = ~joy1_p6_i | ~joy2_p6_i;

wire btn_one_player 	=  joyBCPPFRLDU[5];
wire btn_two_players =  joyBCPPFRLDU[6];
wire btn_coin  		=  joyBCPPFRLDU[7];
// delgrom Fin joysticks ---------------------------



	//---------------------------------
	//-- scanlines
	
	//wire btn_scan_s;
	wire changeScanlines; // delgrom
	wire [1:0] scanlines_s;
	
	debounce # ( .counter_size_g (10))
	btnscl
	(
		.clk_i		( clock_6 ),
		.button_i	( btn_n_i[1] | btn_n_i[2] ),
		.result_o	( btn_scan_s )
	);
 
 	//always @(negedge btn_scan_s) 
	always @(negedge changeScanlines) // delgrom
	begin
			scanlines_s = scanlines_s + 1'b1;
	end
	
	//---------------------------------
	//-- PS/2 Keyboard
	
wire kbd_intr;
wire [12:0] joyBCPPFRLDU;
wire [7:0] kbd_scancode;

//get scancode from keyboard
io_ps2_keyboard keyboard 
 (
  .clk       ( clock_24 ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

//translate scancode to joystick
kbd_joystick k_joystick
(
  .clk         	(  clock_24 ),
  .kbdint      	(  kbd_intr ),
  .kbdscancode 	(  kbd_scancode ), 
  .joyBCPPFRLDU   ( joyBCPPFRLDU ),
  // delgrom
  .changeScandoubler    ( changeScandoubler),
  // delgrom
  .changeScanlines    ( changeScanlines),
  // delgrom
  .reset          (w_reset)    
);  

// delgrom reset
wire w_reset;

// delgrom
wire changeScandoubler;
reg v_scandoublerD =1'b1;  // delgrom 1'b1 inicia a 15khz, 1'b0 inicia a  vga


// delgrom Cambiar entre 15khz y 31khz
always @(posedge changeScandoubler) 
begin
		v_scandoublerD <= ~v_scandoublerD;
end
	
endmodule
