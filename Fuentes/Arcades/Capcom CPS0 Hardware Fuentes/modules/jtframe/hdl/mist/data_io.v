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

module data_io #(parameter aw=22)(
    // io controller spi interface
    input         sck,
    input         ss,
    input         sdi,

    output reg [4:0]  index,     // menu index used to upload the file

    // external ram interface
    input               rst,
    input               clk_sdram,
    output reg          downloading_sdram,   // signal indicating an active download
    output reg [aw-1:0] ioctl_addr,
    output reg [ 7:0]   ioctl_data,
    output reg          ioctl_wr
);

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
            cmd <= {sbuf, sdi};

        // prepare/end transmission
        if((cmd == UIO_FILE_TX) && (cnt == 15)) begin
            // prepare
            if(sdi) begin
                // addr <= 25'd0;
                downloading_reg <= 1'b1;
            end else
                downloading_reg <= 1'b0;
        end

        // command 0x54: UIO_FILE_TX
        if((cmd == UIO_FILE_TX_DAT) && (cnt == 15)) begin
            data <= {sbuf, sdi};
            rclk <= 1'b1;
        end

      // expose file (menu) index
      if((cmd == UIO_FILE_INDEX) && (cnt == 15))
            index <= {sbuf[3:0], sdi};
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
