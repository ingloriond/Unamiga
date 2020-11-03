`timescale 1ns / 1ps

module dut(
    input RSTn,
    input clk12,
    input flipn,
    output [7:0] HPOS,
    output [7:0] DVPOS,
    output       VBLK,
    output       E,
    output       Q
);

`include "dut.inc"

endmodule