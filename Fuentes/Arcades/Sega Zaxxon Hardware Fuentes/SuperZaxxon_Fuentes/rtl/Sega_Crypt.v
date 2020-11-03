module Sega_Crypt
(
	input 				clk,

	input					mrom_m1,
	input     [14:0]	mrom_ad,
	output reg [7:0]	mrom_dt,
	output 	[14:0]	cpu_rom_addr,
	input   	 [7:0]	cpu_rom_do
);

reg  [15:0] madr;
wire  [7:0] mdat;

wire			f		  = mdat[7];
wire  [7:0] xorv    = { f, 1'b0, f, 1'b0, f, 3'b000 }; 
wire  [7:0] andv    = ~(8'hA8);
wire  [1:0] decidx0 = { mdat[5],  mdat[3] } ^ { f, f };
wire  [6:0] decidx  = { madr[12], madr[8], madr[4], madr[0], ~madr[15], decidx0 };
wire  [7:0] dectbl;
wire  [7:0] mdec    = ( mdat & andv ) | ( dectbl ^ xorv );

dec_315_5013 dec_315_5013(
	.clk(clk),
	.addr(decidx),
	.data(dectbl)
);

assign cpu_rom_addr = madr[14:0];
assign mdat = cpu_rom_do;

reg phase = 1'b0;
always @( negedge clk ) begin
	if ( phase ) mrom_dt <= mdec;
	else madr <= { mrom_m1, mrom_ad };
	phase <= ~phase;
end

endmodule 