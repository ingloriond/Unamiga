//
// sdram.v
//
// apple II version of the sdram controller implementation for the
// MiST board
// http://code.google.com/p/mist-board/
// 
// Copyright (c) 2015 Till Harbaum <till@harbaum.org> 
// 
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version. 
// 
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//

module sdram (

	// interface to the MT48LC16M16 chip
	inout  reg [15:0]	sd_data,    // 16 bit bidirectional data bus
	output reg [12:0]	sd_addr,    // 13 bit multiplexed address bus
	output reg [1:0] 	sd_dqm,     // two byte masks
	output reg [1:0] 	sd_ba,      // two banks
	output 				sd_cs,      // a single chip select
	output 				sd_we,      // write enable
	output 				sd_ras,     // row address select
	output 				sd_cas,     // columns address select

	// cpu/chipset interface
	input 		 		init,			// init signal after FPGA config to initialize RAM
	input 		 		clk,			// sdram is accessed at up to 128MHz
	input					clkref,		// reference clock to sync to
	
	input [7:0]  		din,			// data input from chipset/cpu
	output [15:0]      dout,			// data output to chipset/cpu
	input aux,
	input [24:0]   	addr,       // 25 bit byte address
	input 		 		we          // cpu/chipset requests write
);

// no burst configured
localparam RASCAS_DELAY   = 3'd2;   // tRCD=20ns -> 3 cycles@128MHz
localparam BURST_LENGTH   = 3'b000; // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
localparam CAS_LATENCY    = 3'd3;   // 2/3 allowed
localparam OP_MODE        = 2'b00;  // only 00 (standard operation) allowed
localparam NO_WRITE_BURST = 1'b1;   // 0= write burst enabled, 1=only single access write

localparam MODE = { 3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH}; 


// ---------------------------------------------------------------------
// ------------------------ cycle state machine ------------------------
// ---------------------------------------------------------------------

localparam STATE_IDLE      = 3'd0;   // first state in cycle
localparam STATE_CMD_START = 3'd0;   // state in which a new command can be started
localparam STATE_CMD_CONT  = STATE_CMD_START  + RASCAS_DELAY; // 4 command can be continued
localparam STATE_READ      = STATE_CMD_CONT + CAS_LATENCY + 4'd1;   // 
localparam STATE_LAST      = 3'd7;   // last state in cycle

assign dout = sd_data;

reg [3:0] q /* synthesis noprune */;
always @(posedge clk) begin
	// 112Mhz counter synchronous to 14 Mhz clock
   // force counter to pass state 5->6 exactly after the rising edge of clkref
	// since clkref is two clocks early
   if(((q == 13) && ( clkref == 0)) ||
		((q ==  0) && ( clkref == 1)) ||
      ((q != 13) && (q != 0))) begin
			if( q != 13)
				q <= q + 4'd1;
			else
				q <= 4'd0;
		end
end

// ---------------------------------------------------------------------
// --------------------------- startup/reset ---------------------------
// ---------------------------------------------------------------------

// wait 1ms (32 8Mhz cycles) after FPGA config is done before going
// into normal operation. Initialize the ram in the last 16 reset cycles (cycles 15-0)
reg [4:0] reset;
always @(posedge clk) begin
	if(init)	reset <= 5'h1f;
	else if((q == STATE_LAST) && (reset != 0))
		reset <= reset - 5'd1;
end

// ---------------------------------------------------------------------
// ------------------ generate ram control signals ---------------------
// ---------------------------------------------------------------------

// all possible commands
localparam CMD_INHIBIT         = 4'b1111;
localparam CMD_NOP             = 4'b0111;
localparam CMD_ACTIVE          = 4'b0011;
localparam CMD_READ            = 4'b0101;
localparam CMD_WRITE           = 4'b0100;
localparam CMD_BURST_TERMINATE = 4'b0110;
localparam CMD_PRECHARGE       = 4'b0010;
localparam CMD_AUTO_REFRESH    = 4'b0001;
localparam CMD_LOAD_MODE       = 4'b0000;

reg [3:0] sd_cmd;   // current command sent to sd ram

// drive control signals according to current command
assign sd_cs  = sd_cmd[3];
assign sd_ras = sd_cmd[2];
assign sd_cas = sd_cmd[1];
assign sd_we  = sd_cmd[0];


always @(posedge clk) begin
	sd_cmd <= CMD_INHIBIT;  // default: idle
	sd_data <= 16'bZ;
	
	if(reset != 0) begin
		// initialization takes place at the end of the reset phase
		if(q == STATE_CMD_START) begin

			if(reset == 13) begin
				sd_cmd <= CMD_PRECHARGE;
				sd_addr[10] <= 1'b1;      // precharge all banks
			end
				
			if(reset == 2) begin
				sd_cmd <= CMD_LOAD_MODE;
				sd_addr <= MODE;
			end
			
		end
	end else begin
		// normal operation
		
		// -------------------  cpu/chipset read/write ----------------------
		
		// RAS phase
		if(q == STATE_CMD_START) begin
			sd_cmd <= CMD_ACTIVE;
			sd_addr <= addr[21:9];
			sd_ba <= addr[23:22];
				
			// always return both bytes in a read. Only the correct byte
			// is being stored during read. On write only one of the two
			// bytes is enabled
			if(!we) sd_dqm <= 2'b00;
			else    sd_dqm <= { ~aux, aux };
		end
				
		// CAS phase 
		if(q == STATE_CMD_CONT) begin
			sd_cmd <= we?CMD_WRITE:CMD_READ;
			if (we) sd_data <= {din, din};
			sd_addr <= { 4'b0010, addr[8:0] };  // auto precharge
		end

		// always add a refresh cycle
		if(q == 8)
			sd_cmd <= CMD_AUTO_REFRESH;
	end
end

endmodule
