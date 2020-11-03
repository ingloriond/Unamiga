`timescale 1ns / 1ps

module sprom(
	 input wire clock,
    input wire [widthad_a-1 : 0] Address,
    output reg [width_a-1 : 0] q
    );

parameter widthad_a = 10;
parameter width_a = 8;
parameter init_file = "";

(* ramstyle = "no_rw_check" *) reg [width_a-1:0] rom [0:2**widthad_a-1];

initial begin
	$readmemh(init_file,rom);
end

always@(posedge clock)
		q<=rom[Address];
endmodule
