//
// data_io.v
//
// io controller writable ram for the MiST board
// https://github.com/mist-devel
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

module data_io # (
parameter STRLEN		=	0
)
(
	// io controller spi interface
	input         sck,
	input         ss,
	input         sdi,
	output        sdo,
	
	input   [7:0]           data_in,
	input [(8*STRLEN)-1:0] conf_str,
	output reg [31:0] status,
	
	output        downloading,   // signal indicating an active download
   output reg [4:0]  index,     // menu index used to upload the file
	 
	// external ram interface
	input 			   clk,
	output reg        wr,
	output reg [24:0] addr,
	output reg [15:0] data
);

// *********************************************************************************
// spi client
// *********************************************************************************

// this core supports only the display related OSD commands
// of the minimig
reg [14:0]     sbuf;
reg [7:0]      cmd;
reg [4:0]      cnt;
reg rclk;
reg sdo_s;

assign sdo = sdo_s;

reg [24:0] laddr;
reg [15:0] ldata;

reg [7:0]	ACK = 8'd75; // letter K - 0x4b
reg  [10:0]  byte_cnt;   // counts bytes

localparam UIO_FILE_TX_start = 8'h60;
localparam UIO_FILE_TX_end   = 8'h62;
localparam UIO_FILE_TX_DAT  = 8'h61;
localparam UIO_FILE_INDEX   = 8'h55;

assign downloading = downloading_reg;
reg downloading_reg = 1'b0;


	// SPI MODE 0 : incoming data on Rising, outgoing on Falling
	always@(negedge sck, posedge ss) 
	begin
	
		
				//each time the SS goes down, we will receive a command from the SPI master
				if (ss) // not selected
					begin
						sdo_s <= 1'bZ;
						byte_cnt <= 11'd0;
					end
				else
					begin
							
							if (cmd == 8'h10 ) //command 0x10 - send the data to the microcontroller
								sdo_s <= data_in[~cnt[2:0]];
								
							else if (cmd == 8'h00 ) //command 0x00 - ACK
								sdo_s <= ACK[~cnt[2:0]];
							
						//	else if (cmd == 8'h61 ) //command 0x61 - echo the pumped data
						//		sdo_s <= sram_data_s[~cnt[2:0]];			
					
					
							else if(cmd == 8'h14) //command 0x14 - reading config string
								begin
								
									if(byte_cnt < STRLEN + 1 ) // returning a byte from string
										sdo_s <= conf_str[{STRLEN - byte_cnt,~cnt[2:0]}];
									else
										sdo_s <= 1'b0;
										
								end	
						
				
							if(cnt[2:0] == 7) 
								byte_cnt <= byte_cnt + 8'd1;
							
					end
	end
	
	
// data_io has its own SPI interface to the io controller
always@(posedge sck, posedge ss) 
begin
	reg  [4:0] cnf_byte;
	
	if(ss == 1'b1)
	begin
		cnt <= 5'd0;
		cnf_byte <= 4'd15;
	end
	else begin
		rclk <= 1'b0;

		// don't shift in last bit. It is evaluated directly
		// when writing to ram
		if(cnt != 23)
			sbuf <= { sbuf[13:0], sdi};
	 
		// count 0-7 8-15 16-23 8-15 16-23 ... 
		if(cnt < 23) 	cnt <= cnt + 4'd1;
		else				cnt <= 4'd8;

		// finished command byte
      if(cnt == 7)
			begin
					cmd <= {sbuf[6:0], sdi};

					// command 0x60: start the data streaming
					if(sbuf[6:0] == 7'b0110000 && sdi == 1'b0)
					begin

							// download rom to address 0, microdrive image to 16MB+
							if(index == 5'd0) laddr <= 25'h0 - 25'd1;
							else              laddr <= 25'h800000 - 25'd1;
							
					end
					
					// command 0x61: start the data streaming
					if(sbuf[6:0] == 7'b0110000 && sdi == 1'b1)
					begin
							downloading_reg <= 1'b1; 
					end
					
					// command 0x62: end the data streaming
					if(sbuf[6:0] == 7'b0110001 && sdi == 1'b0)
					begin
							downloading_reg <= 1'b0; 
					end
			end
		
		// command 0x15: stores the status word (menu selections)
		if (cmd == 8'h15 && (cnt == 15 || cnt == 23))
		begin
			case (cnf_byte)			
				4'd15: status[31:24] <= {sbuf, sdi};
				4'd14: status[23:16] <= {sbuf, sdi};
				4'd13: status[15:8]  <= {sbuf, sdi};
				4'd12: status[7:0]   <= {sbuf, sdi};
			endcase
			
			cnf_byte <= cnf_byte - 1'd1;

		end
				
		
		//  UIO_FILE_TX_DAT
		if((cmd == UIO_FILE_TX_DAT) && (cnt == 23)) begin
			ldata <= {sbuf, sdi};
			laddr <= laddr + 1;
			rclk <= 1'b1;
		end
		
      // expose file (menu) index
      if((cmd == UIO_FILE_INDEX) && (cnt == 15))
			index <= {sbuf[3:0], sdi};
	end
end

reg rclkD, rclkD2;
always@(posedge clk) begin
	// bring all signals from spi clock domain into local clock domain
	rclkD <= rclk;
	rclkD2 <= rclkD;
	wr <= 1'b0;
	
	if(rclkD && !rclkD2) begin //detect the rising edge of the rclk signal
		addr <= laddr;
		data <= ldata;
		wr <= 1'b1;
	end
end

endmodule
