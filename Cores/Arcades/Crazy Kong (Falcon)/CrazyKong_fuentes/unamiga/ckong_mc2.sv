`default_nettype none

module ckong_mc2
(

// Clocks
	input wire	clock_50_i,

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
	output wire	joyX_p7_o			= 1'b1,

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
	output        VGA_VS

);

assign AUDIO_R = AUDIO_L;

wire clock_12, clock_24;
pll pll(
	.inclk0(clock_50_i),
	.c0(clock_12),
	.c1(clock_24)
	);


wire [31:0] status;
wire        scandoublerD = v_scandoublerD; // delgrom 1'b0 vga, 1'b1 15khz 
wire        ypbpr;
wire [10:0] ps2_key;
wire [15:0] audio;
wire hs, vs;
wire blankn;
wire [2:0] 	r, g;
wire [1:0] 	b;

ckong ckong(
	.clock_12(clock_12),
	//.reset(~btn_n_i[4]),
	.reset(w_reset), // delgrom reset por teclado
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hs(hs),
	.video_vs(vs),
	.blankn(blankn),
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
	.up2(m_up)
	);
	
mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(9)) mist_video(
	.clk_sys(clock_24),	
	.R(blankn ? r : 0),
	.G(blankn ? g : 0),
	.B(blankn ? {b,b[1]} : 0),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(vga_r_s),
	.VGA_G(vga_g_s),
	.VGA_B(vga_b_s),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.ce_divider(1'b0), 
	.rotate({1'b1,status[2]}),
	//.scanlines(scandoublerD ? 2'b00 : scanlines_s),
	//.scandoubler_disable(scandoublerD),
    // delgrom scanlines, y scandoubler
	.scanlines(scandoublerD ? 2'b00 : v_scanlines),
    .scandoubler_disable(v_scandoublerD),	
	//
	.ypbpr(ypbpr)
	);

	wire [5:0]vga_r_s;
	wire [5:0]vga_g_s;
	wire [5:0]vga_b_s;
	assign VGA_R = vga_r_s[5:1];
	assign VGA_G = vga_g_s[5:1];
	assign VGA_B = vga_b_s[5:1];

dac #(
	.C_bits(15))
dac(
	.clk_i(clock_24),
	.res_n_i(1),
	.dac_i({~audio[15],audio[14:0]}),
	.dac_o(AUDIO_L)
	);
	

// delgrom Asignacion directa a joystick ---------------	
wire m_up     = joyBCPPFRLDU[0] | ~joy1_up_i;
wire m_down   = joyBCPPFRLDU[1] | ~joy1_down_i;
wire m_left   = joyBCPPFRLDU[2] | ~joy1_left_i;
wire m_right  = joyBCPPFRLDU[3] | ~joy1_right_i;

wire m_fire   = joyBCPPFRLDU[4] | | joyBCPPFRLDU[8] | ~joy1_p6_i;

wire btn_one_player 	=  joyBCPPFRLDU[5];
wire btn_two_players =  joyBCPPFRLDU[6];
wire btn_coin  		=  joyBCPPFRLDU[7];
// delgrom Fin joysticks ---------------------------	
	
	

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
  // delgrom Teclas scandbl, scanlines, reset
  .changeScandoubler    ( changeScandoubler),
  .changeScanlines    ( changeScanlines),
  .reset          (w_reset)  
);


// delgrom Cambiar entre 15khz y 31khz
wire changeScandoubler;
reg v_scandoublerD =1'b0;  // delgrom 1'b1 inicia a 15khz, 1'b0 inicia a  vga

always @(posedge changeScandoubler) 
begin
		v_scandoublerD <= ~v_scandoublerD;
end

// delgrom scanlines rotatorias (off, 25%, 50%, 75%)
wire changeScanlines;
reg [1:0] v_scanlines =  2'b00;

always @(posedge changeScanlines) 
begin
		v_scanlines <= v_scanlines + 1'b1;
end

// delgrom reset
wire w_reset;

endmodule 
