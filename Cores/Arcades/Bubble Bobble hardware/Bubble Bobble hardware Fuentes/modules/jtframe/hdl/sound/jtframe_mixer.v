/* This file is part of JTFRAME.

 
    JTFRAME program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTFRAME program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTFRAME.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 20-12-2019
    
*/

// Generic mixer: improves on the jt12_mixer in JT12 repository

// Usage:
// Specify width of input signals and desired outputs
// Select gain for each signal

module jtframe_mixer #(parameter W0=16,W1=16,W2=16,W3=16,WOUT=16)(
    input                    clk,
    input                    cen,
    // input signals
    input  signed [W0-1:0]   ch0,
    input  signed [W1-1:0]   ch1,
    input  signed [W2-1:0]   ch2,
    input  signed [W3-1:0]   ch3,
    // gain for each channel in 4.4 fixed point format
    input  [7:0]             gain0,
    input  [7:0]             gain1,
    input  [7:0]             gain2,
    input  [7:0]             gain3,
    output     signed [WOUT-1:0] mixed
);

localparam WM = 16;
localparam WA = WM+8; // width for the amplification
localparam WS = WA+3; // width for the sum
localparam signed [WM+3:0] MAXPOS = {  5'b0, {WM-1{1'b1}}};
localparam signed [WM+3:0] MAXNEG = { ~5'b0, {WM-1{1'b0}}};


`ifdef SIMULATION
initial begin
    if( WOUT<W0 || WOUT<W1 || WOUT<W2 || WOUT<W3 ) begin
        $display("ERROR: %m parameter WOUT must be larger or equal than any other w parameter");
        $finish;
    end
    if( W0>WM || W1 > WM || W2>WM || W3>WM || WOUT>WM ) begin
        $display("ERROR: %m parameters cannot be larger than %d bits",WM);
        $finish;
    end
end
`endif

wire signed [WM+7:0] ch0_pre, ch1_pre, ch2_pre, ch3_pre;
wire signed [WM+3:0] pre_sum;
reg  signed [WM-1:0] ch0_amp, ch1_amp, ch2_amp, ch3_amp, sum;

// rescale to WM
wire signed [WM-1:0] scaled0 = { ch0, {WM-W0{1'b0}} };
wire signed [WM-1:0] scaled1 = { ch1, {WM-W1{1'b0}} };
wire signed [WM-1:0] scaled2 = { ch2, {WM-W2{1'b0}} };
wire signed [WM-1:0] scaled3 = { ch3, {WM-W3{1'b0}} };

wire signed [8:0]
    g0 = {1'b0, gain0},
    g1 = {1'b0, gain1},
    g2 = {1'b0, gain2},
    g3 = {1'b0, gain3};

assign ch0_pre = g0 * scaled0;
assign ch1_pre = g1 * scaled1;
assign ch2_pre = g2 * scaled2;
assign ch3_pre = g3 * scaled3;
assign pre_sum = (ch0_pre + ch1_pre + ch2_pre + ch3_pre)>>>4;
assign mixed   = sum[WM-1:WM-WOUT];

// Apply gain
always @(posedge clk) if(cen) begin
    ch0_amp <= ch0_pre[WM+7:8];
    ch1_amp <= ch1_pre[WM+7:8];
    ch2_amp <= ch2_pre[WM+7:8];
    ch3_amp <= ch3_pre[WM+7:8];

    sum     <= pre_sum > MAXPOS ? MAXPOS[WM-1:0] : (
               pre_sum < MAXNEG ? MAXNEG[WM-1:0] :pre_sum[WM-1:0] );
end

endmodule // jtframe_mixer

module jtframe_limamp #(parameter WIN=16,WOUT=16)(
    input                    clk,
    input                    cen,
    // input signals
    input signed [WIN-1:0]   sndin,
    // gain for each channel in 4.4 fixed point format
    input  [7:0]             gain,
    output signed [WOUT-1:0] sndout
);

jtframe_mixer #(.W0(WIN),.WOUT(WOUT)) u_amp(
    .clk    ( clk       ),
    .cen    ( cen       ),
    .ch0    ( sndin     ),
    .ch1    ( 16'd0     ),
    .ch2    ( 16'd0     ),
    .ch3    ( 16'd0     ),
    .gain0  ( gain      ),
    .gain1  ( 8'h0      ),
    .gain2  ( 8'h0      ),
    .gain3  ( 8'h0      ),
    .mixed  ( sndout    )
);

endmodule