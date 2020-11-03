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
    Date: 24-4-2019 

    Originally based on a file from:
        Milkymist VJ SoC, Sebastien Bourdeauducq and Das Labor
*/

`timescale 1ns/1ps

module jtframe_uart(
    input            rst_n,
    input            clk,
    input            cen,
    // serial wires
    input            uart_rx,
    output reg       uart_tx, // serial signal to transmit. High when idle
    // Rx interface 
    output reg [7:0] rx_data,
    output reg       rx_done,
    output reg       rx_error,
    // Tx interface
    output reg       tx_done,
    output reg       tx_busy,
    input      [7:0] tx_data,
    input            tx_wr      // write strobe
);

/* Division of the system clock
        For a 50MHz system clock use:
            clk_div = 28, uart_div = 30 ->  57kbps, 0.01% timing error      
            clk_div = 14, uart_div = 30 -> 115kbps, 0.01% timing error
            clk_div =  7, uart_div = 30 -> 230kbps, 0.01% timing error
    */
parameter CLK_DIVIDER  = 5'd28;
parameter UART_DIVIDER = 5'd30; // number of divisions of the UART bit period

wire [4:0] clk_div  = CLK_DIVIDER;
wire [4:0] uart_div = UART_DIVIDER;

//-----------------------------------------------------------------
// zero generator... this is actually a 32-module counter
//-----------------------------------------------------------------
reg  [4:0] clk_cnt;
reg zero;

always @(posedge clk or negedge rst_n) begin : clock_divider
    if(!rst_n) begin
        clk_cnt <= clk_div - 5'b1;
        zero    <= 1'b0;
    end else if(cen) begin
        clk_cnt <= clk_cnt - 5'd1;
        zero <= clk_cnt==5'd1;
        if(zero)
            clk_cnt <= clk_div - 5'b1;  // reload the divider value
    end
end

//-----------------------------------------------------------------
// Synchronize uart_rx
//-----------------------------------------------------------------
reg uart_rx1;
reg uart_rx2;

always @(posedge clk) begin : synchronizer
    uart_rx1 <= uart_rx;
    uart_rx2 <= uart_rx1;
end

//-----------------------------------------------------------------
// UART RX Logic
//-----------------------------------------------------------------
reg rx_busy;
reg [4:0] rx_divcnt;
reg [3:0] rx_bitcnt;
reg [7:0] rx_reg;

always @(posedge clk or negedge rst_n) begin : rx_logic
    if(!rst_n) begin
        rx_done      <= 1'b0;
        rx_busy      <= 1'b0;
        rx_divcnt    <= 5'd0;
        rx_bitcnt    <= 4'd0;
        rx_data      <= 8'd0;
        rx_reg       <= 8'd0;
        rx_error     <= 1'b0;
    end else if(cen) begin
        rx_done      <= 1'b0;
        
        if(zero) begin
            if(!rx_busy) begin // look for start bit
                if(!uart_rx2) begin // start bit found
                    rx_busy    <= 1'b1;
                    rx_divcnt  <= { 1'b0, uart_div[4:1] }; // middle bit period
                    rx_bitcnt  <= 4'd0;
                    rx_reg     <= 8'h0;
                end
            end else begin
                if( !rx_divcnt ) begin // sample
                    rx_bitcnt  <= rx_bitcnt + 4'd1;
                    rx_divcnt  <= uart_div;    // start to count down from top again
                    rx_error   <= 1'b0;
                    case( rx_bitcnt )
                        4'd0: // verify startbit
                            if(uart_rx2)
                                rx_busy <= 1'b0;
                        4'd9: begin // stop bit
                            rx_busy <= 1'b0;
                            if(uart_rx2) begin // stop bit ok
                                rx_data <= rx_reg;
                                rx_done <= 1'b1;    
                            end else begin // RX error
                                rx_done  <= 1'b1;
                                rx_error <= 1'b1;
                                end
                            end
                            default: // shift data in
                                rx_reg <= {uart_rx2, rx_reg[7:1]};
                    endcase
                end
                else rx_divcnt <= rx_divcnt - 1'b1;
            end
        end
    end
end

//-----------------------------------------------------------------
// UART TX Logic
//-----------------------------------------------------------------
reg [3:0] tx_bitcnt;
reg [4:0] tx_divcnt;
reg [7:0] tx_reg;

always @(posedge clk or negedge rst_n) begin :tx_logic
    if(!rst_n) begin
        tx_done   <= 'b0;
        tx_busy   <= 'b0;
        uart_tx   <= 'b1;
        tx_divcnt <= 'b0;
        tx_reg    <= 'b0;
    end else if(cen) begin
        tx_done <= 1'b0;
        if(tx_wr) begin
            tx_reg    <= tx_data;
            tx_bitcnt <= 4'd0;
            tx_divcnt <= uart_div;
            tx_busy   <= 1'b1;
            uart_tx   <= 1'b0;
        end else if(zero && tx_busy) begin

            if( !tx_divcnt ) begin
                tx_bitcnt <= tx_bitcnt + 4'd1;
                tx_divcnt <= uart_div;    // start to count down from top again
                if( tx_bitcnt < 4'd8 ) begin
                        uart_tx <= tx_reg[0];
                        tx_reg  <= {1'b0, tx_reg[7:1]};
                        end
                else begin
                    uart_tx <= 1'b1; // 8 bits sent, now 1 or more stop bits
                    if( tx_bitcnt==4'd10 ) begin
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;
                    end
                end
            end
            else tx_divcnt  <= tx_divcnt - 1'b1;
        end
    end
end

endmodule
