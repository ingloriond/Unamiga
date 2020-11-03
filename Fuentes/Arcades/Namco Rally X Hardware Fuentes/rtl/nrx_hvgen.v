module nrx_hvgen
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt;
assign VPOS = vcnt;

always @(posedge PCLK) begin
	case (hcnt)
		297: begin HBLK <= 1; HSYN <= 0; hcnt <= hcnt+1; end
		321: begin HSYN <= 1; hcnt <= hcnt+1; end
		393: begin
			HBLK <= 0; HSYN <= 1; hcnt <= 0;
			case (vcnt)
				243: begin VBLK <= 1; vcnt <= vcnt+1; end //223 243
				232: begin VSYN <= 0; vcnt <= vcnt+1; end //232
				235: begin VSYN <= 1; vcnt <= vcnt+1; end //235
				262: begin VBLK <= 0; vcnt <= 0; end
				default: vcnt <= vcnt+1;
			endcase
		end
		default: hcnt <= hcnt+1;
	endcase
end

endmodule 