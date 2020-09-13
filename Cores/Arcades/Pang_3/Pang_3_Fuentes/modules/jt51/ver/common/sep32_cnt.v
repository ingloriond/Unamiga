/*  This file is part of JT51.

    JT51 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT51 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT51.  If not, see <http://www.gnu.org/licenses/>.
	
	Author: Jose Tejada Gomez. Twitter: @topapate
	Version: 1.1
	Date: 15- 4-2016
	*/

module sep32_cnt(
    input           clk,
    input           cen,
    input           zero,
    output reg [4:0]    cnt
    );

always @(posedge clk) begin : proc_cnt
    if(zero) begin
        cnt <= 5'b1;
    end else if(cen) begin
        cnt <= cnt + 5'b1;
    end
end

endmodule // sep32_cnt