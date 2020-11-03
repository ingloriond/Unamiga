/*  This file is part of JT_GNG.
    JT_GNG program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT_GNG program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT_GNG.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 19-2-2019 */

// 

module jtgng_tile4(
    input              clk,
    input              rst,
    input              cen6,
    input       [4:0]  HS,
    input       [4:0]  SV,
    input       [7:0]  attr,
    input       [7:0]  id,
    input              SCxON,
    input              flip,
    // Palette PROMs
    input   [7:0]      prog_addr,
    input              prom_hi_we,
    input              prom_lo_we,
    input   [3:0]      prom_din,
    // Gfx ROM
    output reg  [16:0] scr_addr,
    input       [15:0] scrom_data,
    output      [ 5:0] scr_pxl
);

parameter SIMFILE_MSB="", SIMFILE_LSB="";
parameter AS8MASK = 1'b1;

reg  [7:0] addr_lsb;
reg  [3:0] scr_attr0;
reg        scr_hflip1;

wire scr_hflip = attr[6];
wire scr_vflip = attr[7];

// Set input for ROM reading
always @(posedge clk) if(cen6) begin
    if( HS[2:0]==3'b1 ) begin // attr/low data corresponds to this tile
            // from HS[2:0] = 1,2,3...0. because RAM output is latched
        scr_attr0 <= attr[5:2];
        scr_addr[16:1] <= {   attr[0] & AS8MASK, id, // AS
                        HS[4:3]^{2{scr_hflip}},
                        SV^{5{scr_vflip}} }; /*vert_addr*/
        scr_addr[0] <= HS[2]^attr[6]^flip;
    end
    else if(HS[2:0]==3'b101 ) scr_addr[0] <= HS[2]^scr_hflip^flip;
end

// Draw pixel on screen
reg [3:0] w,x,y,z;
reg [3:0] scr_attr1, scr_col0, scr_pal0;

// Character data delay
// clock count      stage
// -1               Assign map address
// 1                read map data
// 5                read tile rom data
// 6                assign to scr_col
// 7                read from PROM
// Total delay = 1 (+8) pixels

always @(posedge clk) if(cen6) begin
    if( HS[1:0]==2'd1 ) begin
            { z,y,x,w } <= scrom_data;
            scr_hflip1  <= scr_hflip ^ flip; // must be ready when z,y,x are.
            scr_attr1   <= scr_attr0;
        end
    else
        begin
            if( scr_hflip1 ) begin
                w <= {1'b0, w[3:1]};
                x <= {1'b0, x[3:1]};
                y <= {1'b0, y[3:1]};
                z <= {1'b0, z[3:1]};
            end
            else  begin
                w <= {w[2:0], 1'b0};
                x <= {x[2:0], 1'b0};
                y <= {y[2:0], 1'b0};
                z <= {z[2:0], 1'b0};
            end
        end
    scr_col0  <= scr_hflip1 ? { w[0], x[0], y[0], z[0] } : { w[3], x[3], y[3], z[3] };
    scr_pal0  <= scr_attr1;
end

wire [7:0] pal_addr = SCxON ? { scr_pal0, scr_col0 } : 8'hFF;

// Palette
jtgng_prom #(.aw(8),.dw(2),.simfile(SIMFILE_MSB)) u_prom_msb(
    .clk    ( clk            ),
    .cen    ( cen6           ),
    .data   ( prom_din[1:0]  ),
    .rd_addr( pal_addr       ),
    .wr_addr( prog_addr      ),
    .we     ( prom_hi_we     ),
    .q      ( scr_pxl[5:4]   )
);

jtgng_prom #(.aw(8),.dw(4),.simfile(SIMFILE_LSB)) u_prom_lsb(
    .clk    ( clk            ),
    .cen    ( cen6           ),
    .data   ( prom_din       ),
    .rd_addr( pal_addr       ),
    .wr_addr( prog_addr      ),
    .we     ( prom_lo_we     ),
    .q      ( scr_pxl[3:0]   )
);

endmodule