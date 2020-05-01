`timescale 1ns / 1ps

module test;

reg  RSTn;
reg  clk12;
wire flipn = 1'b0;
wire [7:0] HPOS;
wire [7:0] DVPOS;
wire       VBLK;

initial begin
    RSTn = 1'b0;
    #50 RSTn = 1'b1;
    #90_000_000 $finish;
end

initial begin
    clk12 = 1'b0;
    forever #41.667 clk12 = ~clk12;
end

dut UUT(
    .RSTn   ( RSTn  ),
    .clk12  ( clk12 ),
    .flipn  ( flipn ),
    .HPOS   ( HPOS  ),
    .DVPOS  ( DVPOS ),
    .VBLK   ( VBLK  ),
    .E      ( E     ),
    .Q      ( Q     )
);

initial begin
    $dumpfile("test.lxt");
    $dumpvars;
    $dumpon;
end

endmodule