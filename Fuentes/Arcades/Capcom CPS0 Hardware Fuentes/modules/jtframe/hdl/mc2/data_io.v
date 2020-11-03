//
// data_io.v
//
// io controller writable ram for the MiST board
// http://code.google.com/p/mist-board/
//
// ZX Spectrum adapted version
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

`default_nettype none

module data_io (
    // io controller spi interface
    input         sck,
    input         ss,
    input         sdi,
    output reg    sdo,
	 
    output reg [4:0]  index,     // menu index used to upload the file
	 
 	//external data in to the microcontroller
	input  [7:0] data_in,
	input [(8*STRLEN)-1:0] conf_str,

    // external ram interface
    input               rst,
    input               clk_sdram,
    output reg          downloading_sdram,   // signal indicating an active download
    output reg [aw-1:0] ioctl_addr,
    output reg [ 7:0]   ioctl_data,
    output reg          ioctl_wr
);

parameter STRLEN			=	0;
parameter aw=22;

// *********************************************************************************
// spi client
// *********************************************************************************

// this core supports only the display related OSD commands
// of the minimig
reg [6:0]      sbuf;
reg [7:0]      cmd;
reg [4:0]      cnt=5'd0;
reg rclk=1'b0;
reg [7:0]       data;

localparam UIO_FILE_TX      = 8'h53;
localparam UIO_FILE_TX_DAT  = 8'h54;
localparam UIO_FILE_INDEX   = 8'h55;

reg downloading_reg = 1'b0;

reg  [7:0]  byte_cnt;   // counts bytes
reg [7:0]	ACK = 8'd75; // letter K - 0x4b

// SPI MODE 0 : incoming data on Rising, outgoing on Falling
	always@(negedge sck, posedge ss) 
	begin
	
		
				//each time the SS goes down, we will receive a command from the SPI master
				if (ss) // not selected
					begin
						sdo <= 1'bZ;
						byte_cnt <= 7'd0;
					end
				else
					begin
							
							if (cmd == 8'h10 ) //command 0x10 - send the data to the microcontroller
								sdo <= data_in[~cnt[2:0]];
								
							else if (cmd == 8'h00 ) //command 0x00 - ACK
								sdo <= ACK[~cnt[2:0]];
							
							else if (cmd == 8'h61 ) //command 0x61 - echo the pumped data
								sdo <= data[~cnt[2:0]];			
					
					
							else if(cmd == 8'h14) //command 0x14 - reading config string
								begin
								
									if (STRLEN == 0) //if we dont have a str, just send the first byte as 00
										sdo <= 1'b0;
									else if(byte_cnt < STRLEN + 1 ) // returning a byte from string
										sdo <= conf_str[{STRLEN - byte_cnt,~cnt[2:0]}];
									else
										sdo <= 1'b0;
										
								end	
						
				
							if((cnt[2:0] == 7)&&(byte_cnt != 8'd255)) 
								byte_cnt <= byte_cnt + 8'd1;
							
					end
	end
	
// data_io has its own SPI interface to the io controller
always@(posedge sck, posedge ss) begin
    if(ss == 1'b1) begin
        cnt <= 5'd0;
    end
    else begin
        rclk <= 1'b0;

        // don't shift in last bit. It is evaluated directly
        // when writing to ram
        if(cnt != 15)
            sbuf <= { sbuf[5:0], sdi};

        // count 0-7 8-15 8-15 ...
        if(cnt < 15)
            cnt <= cnt + 4'd1;
        else
            cnt <= 4'd8;

        // finished command byte
        if(cnt == 7)
		  begin
            cmd <= {sbuf, sdi};
				
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
				
		  if(cnt == 15)
		  begin
				// command 0x60: stores a configuration byte
				//if (cmd == 8'h60)
				//begin
				//		config_buffer_o[cnf_byte] <= {sbuf[6:0], sdi};
				//		cnf_byte <= cnf_byte - 1'd1;
				//		
				//		sram_addr_s =  { aw {1'b1} }; // same as (others=>'1')
				//	
				//			 
				//end
				
				// command 0x61: Data Pump
				if (cmd == 8'h61) 
				begin
					data <= {sbuf, sdi};
					rclk <= 1'b1;
				end
		 
		  end

    end
end

reg rclkD, rclkD2;
reg sync_aux;

always@(posedge clk_sdram or posedge rst)
    if( rst ) begin
        ioctl_addr <= {aw{1'b1}};
        ioctl_wr   <= 1'b0;
        ioctl_data <= 8'h0;
    end else begin
        { downloading_sdram, sync_aux } <= { sync_aux, downloading_reg };
        if ({ downloading_sdram, sync_aux } == 2'b01) begin
            ioctl_addr <= ~{aw{1'b0}};
            ioctl_wr   <= 1'b0;
        end

        // bring rclk from spi clock domain into sdram clock domain
        rclkD <= rclk;
        rclkD2 <= rclkD;

        if( rclkD && !rclkD2 ) begin
            ioctl_data <= data;
            ioctl_addr <= ioctl_addr + 1'd1;
        end
        ioctl_wr <= rclkD && !rclkD2;
    end

endmodule
