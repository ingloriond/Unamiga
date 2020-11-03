// Copyright (c) 2011,19 MiSTer-X

module NINJAKUN_SP
(
	input       MCLK,
	input       PCLK_EN,
	input				RESET,

	input   [8:0]	PH,
	input	  [8:0]	PV,

	output [10:0]	SPAAD,
	input   [7:0]	SPADT,

	output [12:0]	SPCAD,
	input  [31:0]	SPCDT,
	input				SPCFT,

	output  [8:0]	SPOUT
);

wire 		  WPEN;
wire [8:0] WPAD;
wire [7:0] WPIX;

reg  [7:0] POUT;
wire [3:0] OTHP = (POUT[3:0]==1) ? POUT[7:4] : POUT[3:0];

reg  [9:0] radr0=0,radr1=1;
wire [7:0] POUTi;

dpram #(8,10) ldbuf(
	MCLK, WPEN, {PV[0], WPAD}, WPIX, 8'd0,
	MCLK, (radr0==radr1), radr0, 8'd0, POUTi);

always @(posedge MCLK) begin 
	radr0 <= {~PV[0],PH};
	if (PCLK_EN) begin
		if (radr0!=radr1) POUT <= POUTi;
		radr1 <= radr0;
	end
end

NINJAKUN_SPENG eng (
	MCLK, RESET, PH, PV,
	SPAAD, SPADT,
	SPCAD, SPCDT, SPCFT,
	 WPAD,  WPIX, WPEN
);

assign SPOUT = { 5'h0, OTHP };

endmodule


module NINJAKUN_SPENG
(
	input				MCLK,
	input				RESET,

	input	 [8:0]	PH,
	input  [8:0]	PV,

	output [10:0]	SPAAD,
	input  [7:0]	SPADT,

	output reg [12:0]	SPCAD,
	input  [31:0]	SPCDT,
	input				SPCFT,

	output [8:0]	WPAD,
	output [7:0]	WPIX,
	output			WPEN
);

reg  [5:0] SPRNO;
reg  [1:0] SPRIX;
assign	  SPAAD = {SPRNO, 3'h0, SPRIX};

reg  [7:0] ATTR;
wire [3:0] PALNO = ATTR[3:0];
wire 		  FLIPH = ATTR[4];
wire 		  FLIPV = ATTR[5];
wire 		  XPOSH = ATTR[6];
wire 		  DSABL = ATTR[7];

reg  [7:0] YPOS;
reg  [7:0] NV;
wire [7:0] HV   = NV-YPOS;
wire [3:0] LV   = {4{FLIPV}}^(HV[3:0]);
wire       YHIT = (HV[7:4]==4'b1111) & (~DSABL);

reg  [7:0] XPOS;
reg  [4:0] WP;
wire [3:0] WOFS = {4{FLIPH}}^(WP[3:0]);
assign 	  WPAD = {1'b0,XPOS}-{XPOSH,8'h0}+WOFS-1'd1;
assign 	  WPEN = ~(WP[4]|(WPIX[3:0]==0));

reg  [7:0] PTNO;
reg		  CRS;

function [3:0] XOUT;
input  [2:0] N;
input [31:0] CDT;
	case(N)
	 0: XOUT = CDT[7:4];
	 1: XOUT = CDT[3:0];
	 2: XOUT = CDT[15:12];
	 3: XOUT = CDT[11:8];
	 4: XOUT = CDT[23:20];
	 5: XOUT = CDT[19:16];
	 6: XOUT = CDT[31:28];
	 7: XOUT = CDT[27:24];
	endcase
endfunction
reg [31:0] CDT0, CDT1;
assign	  WPIX = {PALNO, XOUT(WP[2:0],WP[3] ? CDT1 : CDT0)};


`define WAIT	0
`define FETCH0	1
`define FETCH1	2
`define FETCH2	3
`define FETCH3	4
`define FETCH4	5
`define DRAW	6
`define NEXT	7

reg  [2:0] STATE;
always @( posedge MCLK ) begin
	if (RESET) begin
		STATE <= `WAIT;
		SPCAD <= 13'h1fff;
	end else
	case (STATE)

	 `WAIT: begin
			WP <= 16;
			if (~PH[8]) begin
				NV <= PV+5'd17;
				SPRNO <= 0;
				SPRIX <= 2;
				STATE <= `FETCH0;
			end
		end

	 `FETCH0: begin
			YPOS  <= SPADT;
			SPRIX <= 3;
			STATE <= `FETCH1;
		end
	 `FETCH1: begin
			ATTR   = SPADT; /* ATTR must block assign */
			SPRIX <= 0;
			STATE <= YHIT ? `FETCH2 : `NEXT;
		end

	 `FETCH2: begin
			PTNO  <= SPADT;
			SPRIX <= 1;
			STATE <= `FETCH3;
		end
	 `FETCH3: begin
			XPOS  <= SPADT;
			CRS   <= 0;
			STATE <= `FETCH4;
			SPCAD <= {PTNO, LV[3], 1'b0, LV[2:0]};
		end
	 `FETCH4: begin
			if (SPCFT) begin		// Fetch CHRROM data (16pixels)
				if (~CRS) begin
					CDT0  <= SPCDT;
					CRS   <= 1;
					SPCAD <= {PTNO, LV[3], 1'b1, LV[2:0]};
				end
				else begin
					CDT1  <= SPCDT;
					WP    <= 0;
					STATE <= `DRAW;
				end
			end
		end

	 `DRAW: begin
			WP <= WP+1'd1;
			if (WP[4]) STATE <= `NEXT;
 	   end

	 `NEXT: begin
			CDT0  <= 0; CDT1 <= 0;
			SPRNO <= SPRNO+1'd1;
			SPRIX <= 2;
			STATE <= (SPRNO==63) ? `WAIT : `FETCH0;
	   end

	endcase
end

endmodule
