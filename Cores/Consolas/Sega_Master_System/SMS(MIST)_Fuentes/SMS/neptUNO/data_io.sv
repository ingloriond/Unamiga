//
// data_io.v
//
// data_io for the MiST board
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
///////////////////////////////////////////////////////////////////////

module data_io_sms # ( parameter STRLEN =   0 )
(
    input             clk_sys,
    input             SPI_SCK,
    input             SPI_SS2,
    input             SPI_SS4,
    input             SPI_DI,
    output            SPI_DO,
    
    input      [ 7:0] data_in,
    input      [(8*STRLEN)-1:0] conf_str,
    output reg [31:0] status,
    output reg [ 7:0] config_buffer_o[15:0],  // 15 bytes for general use
    output reg [ 6:0] core_mod, // core variant, sent before the config string is requested

    input             clkref_n, // assert ioctl_wr one cycle after clkref stobe (negative active)

    // ARM -> FPGA download
    output reg        ioctl_download = 0, // signal indicating an active download
    output reg  [7:0] ioctl_index,        // menu index used to upload the file ([7:6] - extension index, [5:0] - menu index)
    output reg        ioctl_wr,           // strobe indicating ioctl_dout valid
    output reg [24:0] ioctl_addr,
    output reg  [7:0] ioctl_dout,
    output reg [23:0] ioctl_fileext,      // file extension
    output reg [31:0] ioctl_filesize      // file size
);

parameter START_ADDR = 25'd0;
parameter ROM_DIRECT_UPLOAD = 0;

///////////////////////////////   DOWNLOADING   ///////////////////////////////

reg  [7:0] data_w;
reg  [7:0] data_w2  = 0;
reg        rclk   = 0;
reg        rclk2  = 0;
reg        addr_reset = 0;
reg        downloading_reg = 0;
reg  [7:0] index_reg = 0;

reg        sdo_s;

assign SPI_DO = sdo_s;

localparam DIO_FILE_TX      = 8'h53;
localparam DIO_FILE_TX_DAT  = 8'h54;
localparam DIO_FILE_INDEX   = 8'h55;
localparam DIO_FILE_INFO    = 8'h56;

reg [ 7:0] ACK = 8'd75; // letter K - 0x4b
reg [10:0] byte_cnt;   // counts bytes
reg [ 7:0] cmd;
reg [ 3:0] cnt;
    
// SPI MODE 0 : incoming data on Rising, outgoing on Falling
always@(negedge SPI_SCK, posedge SPI_SS2) 
begin
    
    //each time the SS goes down, we will receive a command from the SPI master
    if (SPI_SS2) // not selected
    begin
        sdo_s    <= 1'bZ;
        byte_cnt <= 11'd0;
    end
    else
    begin

        if (cmd == 8'h10 ) //command 0x10 - send the data to the microcontroller
            sdo_s <= data_in[~cnt[2:0]];

        else if (cmd == 8'h00 ) //command 0x00 - ACK
            sdo_s <= ACK[~cnt[2:0]];

        //  else if (cmd == 8'h61 ) //command 0x61 - echo the pumped data
        //      sdo_s <= sram_data_s[~cnt[2:0]];            


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
always@(posedge SPI_SCK, posedge SPI_SS2) begin : SPI_RECEIVER
    reg  [6:0] sbuf;
    reg [ 4:0] cnf_byte;
    reg  [5:0] bytecnt;
    reg [24:0] addr;

    if(SPI_SS2) begin
        bytecnt <= 0;
        cnt <= 0;
        cnf_byte <= 4'd15;
    end else begin
        // don't shift in last bit. It is evaluated directly
        // when writing to ram
        if(cnt != 15) sbuf <= { sbuf[5:0], SPI_DI};

        // count 0-7 8-15 8-15 ...
        if(cnt != 15) cnt <= cnt + 1'd1;
            else cnt <= 8;

         // finished command byte
        if(cnt == 7) 
        begin 
            cmd <= {sbuf, SPI_DI};
        
        
                // command 0x61: start the data streaming
                if(sbuf[6:0] == 7'b0110000 && SPI_DI == 1'b1)
                begin
                    downloading_reg <= 1;
                    ioctl_download  <= 1;
                end
                
                // command 0x62: end the data streaming
                if(sbuf[6:0] == 7'b0110001 && SPI_DI == 1'b0)
                begin
                    downloading_reg <= 0;
                    ioctl_download  <= 0;
                end
        end

        if(cnt == 15) 
        begin 
        
                // command 0x15: stores the status word (menu selections)
                if (cmd == 8'h15)
                begin
                    case (cnf_byte) 
                                        
                        4'd15: status[31:24] <={sbuf, SPI_DI};
                        4'd14: status[23:16] <={sbuf, SPI_DI};
                        4'd13: status[15:8]  <={sbuf, SPI_DI};
                        4'd12: status[7:0]   <={sbuf, SPI_DI};
                        
                        4'd11: core_mod <= {sbuf[5:0], SPI_DI};
                    endcase
                    
                    cnf_byte <= cnf_byte - 1'd1;

                end
        
            // command 0x60: stores a configuration byte
                if (cmd == 8'h60)
                begin
                        config_buffer_o[cnf_byte] <= {sbuf, SPI_DI};
                        cnf_byte <= cnf_byte - 1'd1;
                        
                        addr_reset <= ~addr_reset;
                end
                        
                // command 0x61: Data Pump 8 bits
                if (cmd == 8'h61) 
                begin
                    data_w <= {sbuf, SPI_DI};
                    rclk <= ~rclk;       
                end
        end
        
        // expose file (menu) index
        if((cmd == DIO_FILE_INDEX) && (cnt == 15)) index_reg <= {sbuf, SPI_DI};
 /*       
        // prepare/end transmission
        if((cmd == DIO_FILE_TX) && (cnt == 15)) begin
            // prepare
            if(SPI_DI) begin
                addr_reset <= ~addr_reset;
                downloading_reg <= 1;
            end else begin
                downloading_reg <= 0;
            end
        end

        // command 0x54: UIO_FILE_TX
        if((cmd == DIO_FILE_TX_DAT) && (cnt == 15)) begin
            data_w <= {sbuf, SPI_DI};
            rclk <= ~rclk;
        end

        

        // receiving FAT directory entry (mist-firmware/fat.h - DIRENTRY)
        if((cmd == DIO_FILE_INFO) && (cnt == 15)) begin
            bytecnt <= bytecnt + 1'd1;
            case (bytecnt)
                8'h08: ioctl_fileext[23:16]  <= {sbuf, SPI_DI};
                8'h09: ioctl_fileext[15: 8]  <= {sbuf, SPI_DI};
                8'h0A: ioctl_fileext[ 7: 0]  <= {sbuf, SPI_DI};
                8'h1C: ioctl_filesize[ 7: 0] <= {sbuf, SPI_DI};
                8'h1D: ioctl_filesize[15: 8] <= {sbuf, SPI_DI};
                8'h1E: ioctl_filesize[23:16] <= {sbuf, SPI_DI};
                8'h1F: ioctl_filesize[31:24] <= {sbuf, SPI_DI};
            endcase
        end
 */
    end
end


always@(posedge clk_sys) begin : DATA_OUT
    // synchronisers
    reg rclkD, rclkD2;
    reg rclk2D, rclk2D2;
    reg addr_resetD, addr_resetD2;

    reg wr_int, wr_int_direct;
    reg [24:0] addr;
    reg [31:0] filepos;

    // bring flags from spi clock domain into core clock domain
    { rclkD, rclkD2 } <= { rclk, rclkD };
    { rclk2D ,rclk2D2 } <= { rclk2, rclk2D };
    { addr_resetD, addr_resetD2 } <= { addr_reset, addr_resetD };

    ioctl_wr <= 0;

    if (!downloading_reg) begin
   //     ioctl_download <= 0;
        wr_int <= 0;
        wr_int_direct <= 0;
    end

    if (~clkref_n) begin
        wr_int <= 0;
        wr_int_direct <= 0;
        if (wr_int || wr_int_direct) begin
            ioctl_dout <= wr_int ? data_w : data_w2;
            ioctl_wr <= 1;
            addr <= addr + 1'd1;
            ioctl_addr <= addr;
        end
    end

    // detect transfer start from the SPI receiver
    if(addr_resetD ^ addr_resetD2) begin
        addr <= START_ADDR;
        filepos <= 0;
        ioctl_index <= index_reg;
  //      ioctl_download <= 1;
    end

    // detect new byte from the SPI receiver
    if (rclkD ^ rclkD2)   wr_int <= 1;
    if (rclk2D ^ rclk2D2 && filepos != ioctl_filesize) begin
        filepos <= filepos + 1'd1;
        wr_int_direct <= 1;
    end
end

endmodule