module test;

// input signals
reg  signed [15:0] ch0[0:15];
reg  signed [ 9:0] ch1[0:15];
reg  signed [ 4:0] ch2[0:15];
reg  signed [ 7:0] ch3[0:15];
wire signed [15:0] mixed;

wire [7:0] gain0 = 8'h10;
wire [7:0] gain1 = 8'h04;
wire [7:0] gain2 = 8'h04;
wire [7:0] gain3 = 8'h04;

reg     clk;
integer cnt=0, result;

wire signed [15:0] ch0in = ch0[cnt[3:0]];
wire signed [ 9:0] ch1in = ch1[cnt[3:0]];
wire signed [ 4:0] ch2in = ch2[cnt[3:0]];
wire signed [ 7:0] ch3in = ch3[cnt[3:0]];

initial begin
    $readmemh( "ch0.hex", ch0 );
    $readmemh( "ch1.hex", ch1 );
    $readmemh( "ch2.hex", ch2 );
    $readmemh( "ch3.hex", ch3 );
end

initial begin
    clk = 0;
    forever #20 clk = ~clk;
end

reg signed [23:0] r0,r1,r2,r3;
reg signed [31:0] rsum;

always @(*) begin
    r0 = ch0in*{1'b0,gain0};
    r1 = ({ch1in,6'd0}* {1'b0,gain1});
    r2 = ({ch2in,11'd0}*{1'b0,gain2});
    r3 = ({ch3in,8'd0}* {1'b0,gain3});
    rsum = (r0+r1+r2+r3)>>>4;
    result = rsum;
    if( rsum> 32767 ) result = 32767;
    if( rsum<-32768 ) result = 32768;
end

always @(posedge clk) begin
    cnt <= cnt+1;
    if( cnt>18 ) #100 $finish;
end

`define SIMULATION

jtframe_mixer #(.W0(16),.W1(10),.W2(5),.W3(8),.WOUT(16)) UUT(
    .clk    ( clk       ),
    .cen    ( 1'b1      ),
    // input signals
    .ch0    ( ch0in     ),
    .ch1    ( ch1in     ),
    .ch2    ( ch2in     ),
    .ch3    ( ch3in     ),
    // gain for each channel in 4.4 fixed point format
    .gain0  ( gain0     ),
    .gain1  ( gain1     ),
    .gain2  ( gain2     ),
    .gain3  ( gain3     ),
    .mixed  ( mixed     )
);

initial begin
    $shm_open("test.shm");
    $shm_probe(test,"AS");
end

endmodule