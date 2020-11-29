/*  This file is part of JTFRAME.
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
    Date: 27-10-2017 */

// Generic dual port RAM with clock enable
// parameters:
//      dw      => Data bit width, 8 for byte-based memories
//      aw      => Address bit width, 10 for 1kB
//      simfile => binary file to load during simulation
//      simhexfile => hexadecimal file to load during simulation
//      synfile => hexadecimal file to load for synthesis

`timescale 1ns/1ps

module jtframe_dual_ram #(parameter dw=8, aw=10, 
    simfile="", simhexfile="", synfile="", dumpfile="dump.hex"
)(
    input   clk0,
    input   clk1,
    // Port 0
    input   [dw-1:0] data0,
    input   [aw-1:0] addr0,
    input   we0,
    output reg [dw-1:0] q0,
    // Port 1
    input   [dw-1:0] data1,
    input   [aw-1:0] addr1,
    input   we1,
    output reg [dw-1:0] q1
    `ifdef JTFRAME_DUAL_RAM_DUMP
    ,input dump
    `endif
);

(* ramstyle = "no_rw_check" *) reg [dw-1:0] mem[0:(2**aw)-1];

`ifdef SIMULATION
integer f, readcnt;
initial begin
    if( simfile != "" ) begin
        f=$fopen(simfile,"rb");
        if( f != 0 ) begin
            readcnt=$fread( mem, f );
            $display("INFO: Read %14s (%4d bytes) for %m",simfile, readcnt);
            $fclose(f);
        end else begin
            $display("WARNING: %m cannot open file: %s", simfile);
        end
        end
    else begin
        if( simhexfile != "" ) begin
            $readmemh(simhexfile,mem);
            $display("INFO: Read %14s (hex) for %m", simhexfile);
        end else begin
            if( synfile!= "" ) begin
                $readmemh(synfile,mem);
                $display("INFO: Read %14s (hex) for %m", synfile);
            end else
                for( readcnt=0; readcnt<2**aw; readcnt=readcnt+1 )
                    mem[readcnt] = {dw{1'b0}};
        end
    end
end
`else
// file for synthesis:
/* verilator lint_off WIDTH */
initial if(synfile!="" )$readmemh(synfile,mem);
/* verilator lint_on WIDTH */
`endif

always @(posedge clk0) begin
    q0 <= mem[addr0];
    if(we0) mem[addr0] <= data0;
end

always @(posedge clk1) begin
    q1 <= mem[addr1];
    if(we1) mem[addr1] <= data1;
end

// Content dump for simulation debugging
`ifdef JTFRAME_DUAL_RAM_DUMP
integer fdump=0, dumpcnt;

always @(posedge dump) begin
    $display("INFO: contents dumped to %s", dumpfile );
    if( fdump==0 )begin
        fdump=$fopen(dumpfile,"w");
    end
    for( dumpcnt=0; dumpcnt<2**aw; dumpcnt=dumpcnt+1 )
        $fdisplay(fdump,"%X", mem[dumpcnt]);
end
`endif

endmodule