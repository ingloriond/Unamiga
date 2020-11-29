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
    Date: 02-5-2020 */

// Produces the right signals for jtframe_sdram to get the ROM data
// A prom_we signal is used for the second half of the ROM byte stream
// For system simulation, it is useful sometimes to be able to load the
// PROM data quickly at the beginning of the simulation. If the PROM
// modules are isolated, this can be done manually typing the path to
// each rom file in the jtframe_prom instantiation. However, sometimes
// the hierarchy will not allow it or the code may get messy.
// jtframe_dwnld can load PROMs only during simulation when the
// macro JTFRAME_DWNLD_PROM_ONLY is defined.

module jtframe_dwnld(
    input                clk,
    input                downloading,
    input      [24:0]    ioctl_addr,
    input      [ 7:0]    ioctl_data,
    input                ioctl_wr,
    output reg [21:0]    prog_addr,
    output reg [ 7:0]    prog_data,
    output reg [ 1:0]    prog_mask, // active low
    output reg           prog_we,
    output reg           prom_we,
    input                sdram_ack
);

parameter        SIMFILE   = "rom.bin";
parameter [24:0] PROM_START= ~25'd0;
localparam       PROM_EN   = PROM_START!=~25'd0;

wire             is_prom   = PROM_EN && ioctl_addr>=PROM_START;

`ifdef LOADROM
`undef JTFRAME_DWNLD_PROM_ONLY
`endif

`ifndef JTFRAME_DWNLD_PROM_ONLY
/////////////////////////////////////////////////
// Normal operation

always @(posedge clk) begin
    if ( ioctl_wr && downloading ) begin
        if( is_prom ) begin
            prog_addr <= ioctl_addr[21:0];
            prom_we   <= 1;
            prog_we   <= 0;
        end else begin
            prog_addr <= ioctl_addr[22:1];
            prom_we   <= 0;
            prog_we   <= 1;
        end
        prog_data <= ioctl_data;
        prog_mask <= ioctl_addr[0] ? 2'b10 : 2'b01;            
    end
    else begin
        if(!downloading || sdram_ack) prog_we  <= 0;
        if(!downloading) prom_we <= 0;
    end
end

`else
////////////////////////////////////////////////////////
// Load only PROMs directly from file in simulation

parameter [31:0] GAME_ROM_LEN = `GAME_ROM_LEN;

integer          f, readcnt, dumpcnt;
reg       [ 7:0] mem[0:`GAME_ROM_LEN];

initial begin
    dumpcnt = PROM_START;
    if( SIMFILE != "" && PROM_EN ) begin
        f=$fopen(SIMFILE,"rb");
        if( f != 0 ) begin
            readcnt=$fread( mem, f );
            $display("INFO: PROM download: %6X bytes loaded from file (%m)", readcnt, SIMFILE);
            $fclose(f);
            if( dumpcnt >= readcnt ) begin
                $display("WARNING: PROM_START is set beyond the end of the file");
            end else begin
                $display("INFO: fast PROM download from %X to %X", dumpcnt, GAME_ROM_LEN);
            end
        end else begin
            $display("WARNING: %m cannot open %s", SIMFILE);
            dumpcnt = GAME_ROM_LEN; // stop the download process
        end
    end else begin
        $display("INFO: PROM download skipped because PROM_START was not defined.");
    end
end

always @(posedge clk) begin
    if( dumpcnt < GAME_ROM_LEN ) begin
        prom_we   <= 1;
        prog_we   <= 0;
        prog_mask <= 2'b11;
        prog_data <= mem[dumpcnt];
        prog_addr <= dumpcnt[21:0];
        dumpcnt   <= dumpcnt+1;
    end else begin
        prom_we <= 0;
    end
end

`endif

endmodule
