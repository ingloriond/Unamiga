module rgb_mist (
   // pixel clock
   input  pclk,

	// enable/disable scanlines
   //input scanlines,
	input white_noise,
	
	// output to VGA screen
   output reg	hs,
   output reg 	vs,
   output [5:0] r,
   output [5:0] g,
   output [5:0] b
   //output reg blank

);


//______________________________________________________________________________
//
// Video 
//




reg  [9:0] hc;
reg  [8:0] vc;
reg  [9:0] vvc;

reg [22:0] rnd_reg;
wire [5:0] rnd_c = {rnd_reg[0],rnd_reg[1],rnd_reg[2],rnd_reg[2],rnd_reg[2],rnd_reg[2]};

wire [22:0] rnd;
lfsr random(rnd);

always @(negedge pclk) begin
	if(hc == 639) begin
		hc <= 0;
		if(vc == 311) begin 
			vc <= 0;
			vvc <= vvc + 9'd6;
		end else begin
			vc <= vc + 1'd1;
		end
	end else begin
		hc <= hc + 1'd1;
	end
	
	rnd_reg <= rnd;
end

reg  HBlank;
reg  HSync;
reg  VBlank;
reg  VSync;
//wire viden  = !HBlank && !VBlank;
//assign viden = 1'd0;   // to eliminate the white noise 

assign viden = white_noise ? !HBlank && !VBlank : 1'd0;   // to eliminate the white noise 

always @(posedge pclk) begin
	if (hc == 310) HBlank <= 1;
		else if (hc == 420) HBlank <= 0;

	if (hc == 336) HSync <= 1;
		else if (hc == 368) HSync <= 0;

	if(vc == 308) VSync <= 1;
		else if (vc == 0) VSync <= 0;

	if(vc == 306) VBlank <= 1;
		else if (vc == 2) VBlank <= 0;
end

reg  [7:0] cos_out;
wire [5:0] cos_g = cos_out[7:3]+6'd32;
cos cos(vvc + {vc, 2'b00}, cos_out);

wire [5:0] comp_v = (cos_g >= rnd_c) ? cos_g - rnd_c : 6'd0;
wire [5:0] R_in = !viden ? 6'd0 : comp_v;
wire [5:0] G_in = !viden ? 6'd0 : comp_v;
wire [5:0] B_in = !viden ? 6'd0 : comp_v;

//wire [5:0] R_out, G_out, B_out;
assign r =  R_in;
assign g =  G_in;
assign b =  B_in;
assign hs = HSync;
assign vs = VSync;


endmodule