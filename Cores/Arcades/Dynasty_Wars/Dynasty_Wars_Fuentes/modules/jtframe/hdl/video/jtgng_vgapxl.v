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
    Date: 14-1-2019 */

module jtgng_vgapxl #(parameter COLORW=4) (
    input                     clk,
    input                     double,
    input                     en_mix,
    input  [COLORW*3-1:0]     rgb_in,
    output [(COLORW+1)*3-1:0] rgb_out
);

function [COLORW:0] ext; // extends by duplicating MSB
    input [COLORW-1:0] a;
    ext = { a, a[COLORW-1] };
endfunction

reg [COLORW-1:0] last_r, last_g, last_b;
reg [COLORW  :0] pxl_r, pxl_g, pxl_b;

assign rgb_out = { pxl_r, pxl_g, pxl_b };

wire [COLORW+1:0] mix_r = ext(last_r) + ext(rgb_in[COLORW*3-1:COLORW*2]);
wire [COLORW+1:0] mix_g = ext(last_g) + ext(rgb_in[COLORW*2-1:COLORW]);
wire [COLORW+1:0] mix_b = ext(last_b) + ext(rgb_in[COLORW-1:0]);


always @(posedge clk) begin
    {last_r, last_g, last_b} <= rgb_in;
    // pixel mixing
    if( !double || !en_mix ) begin
        pxl_r <= ext(rgb_in[COLORW*3-1:COLORW*2]);
        pxl_g <= ext(rgb_in[COLORW*2-1:COLORW]);
        pxl_b <= ext(rgb_in[COLORW-1:0]);
    end
    else begin
        pxl_r <= mix_r[COLORW+1:1];
        pxl_g <= mix_g[COLORW+1:1];
        pxl_b <= mix_b[COLORW+1:1];
    end
end

endmodule // jtgng_vgapxl