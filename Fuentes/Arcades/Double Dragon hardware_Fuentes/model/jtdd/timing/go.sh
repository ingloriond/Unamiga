#!/bin/bash
JTFRAME=../../../modules/jtframe
JT74=$JTFRAME/hdl/jt74.v

$JTFRAME/cc/pcb2ver ../jtdd.net --lib $JT74 --wires --ports dut.v > dut.inc || exit 1

iverilog test.v dut.v $JT74 -o sim -s test && sim -lxt