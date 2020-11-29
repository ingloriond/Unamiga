/*  This file is part of JTFRAME.
      JTFRAME program is free software: you can redistribute it and/or modify
      it under the terms of the GNU General Public License as published by
      the Free Software Foundation, either version 3 of the License, or
      (at your option) any later version.

      JTFRAME program is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR addr PARTICULAR PURPOSE.  See the
      GNU General Public License for more details.

      You should have received a copy of the GNU General Public License
      along with JTFRAME.  If not, see <http://www.gnu.org/licenses/>.

      Author: Jose Tejada Gomez. Twitter: @topapate
      Version: 1.0
      Date: 2-6-2020

*/

// Gates the clock enable signals for two clock cycles if rom_cs 
// has risen or if the rom address has changed while rom_cs was high

// Depending on how the CPU and the rom_cs decoder logic, rom_cs might
// not toggle in between ROM address changes, so the address must be
// tracked

// if rom_cs is constantly high, rom_ok will take one clock cycle to come
// down after an address change. If the cen frequency allows for at least
// two clock cycles between two cen pulses, then checking the ROM address
// is not necessary

module jtframe_gatecen #(parameter ROMW=12)(
    input             clk,
    input             rst,
    input             cen,
    input  [ROMW-1:0] rom_addr,
    input             rom_cs,
    input             rom_ok,
    output            wait_cen
);

reg  [     1:0] last_cs;
reg  [ROMW-1:0] last_addr;
reg             waitn;
wire            new_addr = last_addr != rom_addr;

assign          wait_cen = cen & waitn;

always @(posedge clk) begin
    if( rst ) begin
        waitn     <= 1;
        last_cs   <= 0;
        last_addr <= {ROMW{1'b0}};
    end else begin
        last_cs   <= { last_cs[0] & ~new_addr, rom_cs };
        last_addr <= rom_addr;
        if( rom_cs && (!last_cs[0] || new_addr) ) waitn <= 0;
        else if( rom_ok && last_cs[1] ) waitn <= 1;
    end
end

endmodule