//
// data_io.v
//
// io controller writable ram for the MiST board
// http://code.google.com/p/mist-board/
//
// Copyright (c) 2014 Till Harbaum <till@harbaum.org>
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

module data_io (
	// io controller spi interface
	input             sck,
	input             ss,
	input             sdi,

	output            downloading,   // signal indicating an active download
	output [24:0]     size,          // number of bytes in input buffer
	output reg [4:0]  index,         // menu index used to upload the file
	 
	// external ram interface
	input 			   clk,
	output reg        wr,
	output reg [24:0] a,
	output [7:0]      d
);

assign d = data;

parameter START_ADDR = 25'h0;

assign size = addr;

// *********************************************************************************
// spi client
// *********************************************************************************

reg [6:0]      sbuf;
reg [7:0]      cmd;
reg [7:0]      data;
reg [4:0]      cnt;

reg [24:0]     addr;
reg rclk;

localparam UIO_FILE_TX      = 8'h53;
localparam UIO_FILE_TX_DAT  = 8'h54;
localparam UIO_FILE_INDEX   = 8'h55;

assign downloading = downloading_reg;
reg downloading_reg = 1'b0;

// data_io has its own SPI interface to the io controller
always@(posedge sck, posedge ss) begin
	if(ss == 1'b1)
		cnt <= 5'd0;
	else begin
		rclk <= 1'b0;

		// don't shift in last bit. It is evaluated directly
		// when writing to ram
		if(cnt != 15)
			sbuf <= { sbuf[5:0], sdi};

		// increase target address after write
		if(rclk)
			addr <= addr + 25'd1;
	 
		// count 0-7 8-15 8-15 ... 
		if(cnt < 15) 	cnt <= cnt + 4'd1;
		else				cnt <= 4'd8;

		// finished command byte
      if(cnt == 7)
			cmd <= {sbuf, sdi};

		// prepare/end transmission
		if((cmd == UIO_FILE_TX) && (cnt == 15)) begin
			// prepare
			if(sdi) begin
				addr <= START_ADDR;
				downloading_reg <= 1'b1; 
			end else
				downloading_reg <= 1'b0; 
		end
		
		// command 0x54: UIO_FILE_TX
		if((cmd == UIO_FILE_TX_DAT) && (cnt == 15)) begin
			data <= {sbuf, sdi};
			rclk <= 1'b1;
			a <= addr;
		end

		// expose file (menu) index
		if((cmd == UIO_FILE_INDEX) && (cnt == 15))
			index <= {sbuf[3:0], sdi};
	end
end

reg rclkD, rclkD2;
always@(posedge clk) begin
	// bring rclk from spi clock domain into core clock domain
	rclkD <= rclk;
	rclkD2 <= rclkD;
	wr <= 1'b0;
	
	if(rclkD && !rclkD2) 
		wr <= 1'b1;
end

endmodule