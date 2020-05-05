`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    03:30:06 02/14/2016 
// Design Name: 
// Module Name:    sync_generator_pal_ntsc 
// Project Name:  
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module sync_generator (
    input wire clk,   
    output reg csync_n,
    output reg hsync_n,
    output reg vsync_n,
    output wire [9:0] hc,
    output wire [9:0] vc,
    output reg blank
    );
    
    reg [9:0] h = 10'd0;
    reg [9:0] v = 10'd0;

    assign hc = h;
    assign vc = v;
    
    always @(posedge clk) begin

            if (h == 10'd799) begin
                h <= 10'd0;
                if (v == 10'd523) begin
                    v <= 10'd0;
                end
                else
                    v <= v + 10'd1;
            end
            else
                h <= h + 10'd1;
    end
    
    reg vblank, hblank;
    always @* begin
        vblank = 1'b0;
        hblank = 1'b0;
        vsync_n = 1'b1;
        hsync_n = 1'b1;

            if (v >= 10'd480 && v <= 10'd523) begin
                vblank = 1'b1;
                if (v >= 10'd491 && v <= 10'd493) begin
                    vsync_n = 1'b0;
                end
            end
            if (h >= 10'd640 && h <= 10'd799) begin
                hblank = 1'b1;
                if (h >= 10'd656 && h <= 10'd752) begin
                    hsync_n = 1'b0;
                end
            end

        blank = hblank | vblank;
        csync_n = hsync_n & vsync_n;
    end
endmodule
