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

`timescale 1ns/1ps

    // check_start: lowest address at which the memory check
    // comparison is performed. Useful when the dumped file to load
    // has part of it invalid

module jtframe_prom #(parameter dw=8, aw=10, simfile="", offset=0 )(
    input   clk,
    input   cen,
    input   [dw-1:0] data,
    input   [aw-1:0] rd_addr,
    input   [aw-1:0] wr_addr,
    input   we,
    output reg [dw-1:0] q
);

(* ramstyle = "no_rw_check" *) reg [dw-1:0] mem[0:(2**aw)-1];

`ifdef SIMULATION
integer f, readcnt;
`ifndef LOADROM
// load the file only when SPI load is not simulated
initial begin
    if( simfile != "" ) begin
        f=$fopen(simfile,"rb");
        if( f != 0 ) begin
            readcnt=$fseek( f, offset, 0 );
            readcnt=$fread( mem, f );
            $display("INFO: Read %14s (%4d bytes) for %m",simfile, readcnt);
            $fclose(f);
        end else begin
            $display("WARNING: %m cannot open %s", simfile);
        end
        end
    else begin
        for( readcnt=0; readcnt<(2**aw)-1; readcnt=readcnt+1 )
            mem[readcnt] = {dw{1'b0}};
        end
end
`endif
// check contents after 80ms
reg [dw-1:0] mem_check[0:(2**aw)-1];
reg check_ok=1'b1;
initial begin
    #(`MEM_CHECK_TIME);
    if( simfile != "" ) begin
        f=$fopen(simfile,"rb");
        if( f!= 0 ) begin
            readcnt = $fseek( f, offset, 0 );   // return value assigned to readcnt to avoid a warning
            readcnt = $fread( mem_check, f );
            $fclose(f);
            for( readcnt=readcnt-1;readcnt>=0; readcnt=readcnt-1) begin
                if( mem_check[readcnt] != mem[readcnt] ) begin
                    $display("ERROR: memory content check failed for file %s (%m) @ 0x%x", simfile, readcnt );
                    check_ok = 1'b0;
                    //`ifndef IVERILOG
                    //break;
                    //`else 
                        readcnt = 0; // force a break
                    //`endif
                end
            end
            if( check_ok ) $display("INFO: %m memory check succedded");
        end
        else begin
            $display("ERROR: Cannot find file %s to check memory %m", simfile );
        end
    end
end
`endif

// no clock enable for writtings to allow correct operation during SPI downloading.
always @(posedge clk) begin
    if( cen ) q <= mem[rd_addr];
    if( we ) mem[wr_addr] <= data;
end


endmodule // jtframe_ram