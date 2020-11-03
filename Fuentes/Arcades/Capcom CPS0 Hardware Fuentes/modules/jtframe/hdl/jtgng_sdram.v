/*  This file is part of JT_GNG.
    JT_GNG program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT_GNG program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT_GNG.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 7-1-2018 */

// Each read takes 8 clock cycles
// clk should be 8*clk_slow

module jtgng_sdram(
    input               rst,
    input               clk, // same as game core
    // Game interface
    output              loop_rst,
    input               read_req,    // read strobe
    output reg  [31:0]  data_read,
    input       [21:0]  sdram_addr,
    output reg          data_rdy,    // output data is valid
    output reg          sdram_ack,
    input               refresh_en,    // enable refresh to happen automatically
    // ROM-load interface
    input               downloading,
    input               prog_we,    // strobe
    input       [21:0]  prog_addr,
    input       [ 7:0]  prog_data,
    input       [ 1:0]  prog_mask,
    // SDRAM interface
    inout       [15:0]  SDRAM_DQ,       // SDRAM Data bus 16 Bits
    output reg  [12:0]  SDRAM_A,        // SDRAM Address bus 13 Bits
    output reg          SDRAM_DQML,     // SDRAM Low-byte Data Mask
    output reg          SDRAM_DQMH,     // SDRAM High-byte Data Mask
    output              SDRAM_nWE,      // SDRAM Write Enable
    output              SDRAM_nCAS,     // SDRAM Column Address Strobe
    output              SDRAM_nRAS,     // SDRAM Row Address Strobe
    output              SDRAM_nCS,      // SDRAM Chip Select
    output      [ 1:0]  SDRAM_BA,       // SDRAM Bank Address
    output              SDRAM_CKE       // SDRAM Clock Enable
);

localparam  CMD_LOAD_MODE   = 4'b0000, // 0
            CMD_AUTOREFRESH = 4'b0001, // 1
            CMD_PRECHARGE   = 4'b0010, // 2
            CMD_ACTIVATE    = 4'b0011, // 3
            CMD_WRITE       = 4'b0100, // 4
            CMD_READ        = 4'b0101, // 5
            CMD_STOP        = 4'b0110, // 6
            CMD_NOP         = 4'b0111, // 7
            CMD_INHIBIT     = 4'b1000; // 8

assign SDRAM_BA   = 2'b0;
assign SDRAM_CKE  = 1'b1;

reg SDRAM_WRITE;
reg [7:0] write_data;
assign SDRAM_DQ =  SDRAM_WRITE ? {write_data, write_data} : 16'hzzzz;

reg [8:0] col_addr;

reg [3:0] SDRAM_CMD,
    init_cmd; // this is used to reduce the mux depth to SDRAM_CMD
assign {SDRAM_nCS, SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE } = SDRAM_CMD;

reg [13:0] wait_cnt;
reg [ 2:0] cnt_state;
reg [ 2:0] init_state;
reg       initialize;

reg write_cycle=1'b0, read_cycle=1'b0;

assign loop_rst = initialize;

reg downloading_last;

// Uses downloading_last instead of downloading to alleviate
// top level timing

reg set_burst, burst_done, burst_mode;
reg writeon;
//wire refresh_ok = !read_req;
reg refresh_ok;

always @(posedge clk or posedge rst)
    if(rst) begin
        set_burst  <= 1'b0;
    end else begin
        writeon <= downloading && prog_we;
        downloading_last <= downloading;
        if( downloading != downloading_last) begin
            set_burst <= 1'b1;
            burst_mode <= ~downloading;
        end
        if( burst_done ) set_burst <= 1'b0;
    end

reg autorefresh_cycle;
reg [1:0] refresh_sr;

always @(posedge clk)
    if( rst ) begin
        // initialization of SDRAM
        SDRAM_WRITE<= 1'b0;
        SDRAM_CMD <= CMD_NOP;
        init_cmd  <= CMD_NOP;
        wait_cnt   <= 14'd5000; // wait for 100us
        initialize <= 1'b1;
        init_state <= 3'd0;
        // Main loop
        burst_done <= 1'b0;
        cnt_state  <= 2'd0; //Starts after the precharge
        data_rdy   <= 1'b0;
        sdram_ack  <= 1'b0;
        refresh_sr <=  'd0;
        refresh_ok <= 1'b0;
    end else if( initialize ) begin
        if( |wait_cnt ) begin
            wait_cnt <= wait_cnt-14'd1;
            init_cmd  <= CMD_NOP;
            SDRAM_CMD <= init_cmd;
        end else begin
            if(!init_state[2]) init_state <= init_state+3'd1;
            case(init_state)
                3'd0: begin
                    init_cmd  <= CMD_PRECHARGE;
                    SDRAM_A[10]<= 1'b1; // all banks
                    wait_cnt   <= 14'd2;
                end
                3'd1: begin
                    init_cmd <= CMD_AUTOREFRESH;
                    wait_cnt  <= 14'd11;
                end
                3'd2: begin
                    init_cmd <= CMD_LOAD_MODE;
                    SDRAM_A   <= 13'b00_1_00_010_0_001; // CAS Latency = 2, burst = 2
                    `ifdef SIMULATION
                    `ifndef LOADROM
                        // Start directly with burst mode on simulation
                        // if the ROM load process is not being simulated
                        SDRAM_A   <= 12'b00_1_00_010_0_001; // CAS Latency = 2
                    `endif
                    `endif
                    wait_cnt  <= 14'd3;
                end
                3'd3: begin
                    init_cmd  <= CMD_PRECHARGE;
                    SDRAM_A[10]<= 1'b1; // all banks
                    wait_cnt   <= 14'd2;
                end
                3'd4: begin
                    initialize <= 1'b0;
                    cnt_state  <=  'd0;
                end
                default: begin
                    SDRAM_CMD  <= init_cmd;
                    initialize <= 1'b0;
                end
            endcase
        end
    end else  begin // regular operation
        if( cnt_state!=3'd0 ||
            (!downloading && (read_req || refresh_ok) ) || /* when not downloading */
            writeon   /* when downloading */) begin
            if( cnt_state==3'd4 || (autorefresh_cycle&&cnt_state==3'd3) )
                cnt_state <= 3'd0; // Autorefresh needs only 60ns
            else
                cnt_state <= cnt_state + 3'd1;
        end
        case( cnt_state )
        default: begin // wait
            SDRAM_CMD <= CMD_NOP;
        end
        3'd0: begin // activate or refresh
            write_data        <= prog_data;
            write_cycle       <= 1'b0;
            read_cycle        <= 1'b0;
            autorefresh_cycle <= 1'b0;
            burst_done        <= 1'b0;
            //if( read_cycle) begin
            //    data_read[15: 0] <= data_read[31:16];
            //    data_read[31:16] <= SDRAM_DQ;
            //    data_rdy         <= 1'b1;
            //end
            //else
            data_rdy <= 1'b0;
            {SDRAM_DQMH, SDRAM_DQML } <= downloading_last ? 2'b11 : 2'b00;
            if( set_burst ) begin
                SDRAM_CMD <= CMD_LOAD_MODE;
                // Burst mode can be 0 = 1 word. Used for ROM downloading
                // or 1 = 2 words, used for normal operation
                SDRAM_A   <= {12'b00_1_00_010_0_00, burst_mode}; // CAS Latency = 2
                burst_done <= 1'b1;
                cnt_state  <= 2'd3; // give one NOP cycle after changing the mode
            end else begin
                SDRAM_CMD <= CMD_NOP;
                if( writeon ) begin
                    SDRAM_CMD <= CMD_ACTIVATE;
                    { SDRAM_A, col_addr } <= prog_addr[21:0];
                    autorefresh_cycle <= 1'b0;
                    write_cycle       <= 1'b1;
                    {SDRAM_DQMH, SDRAM_DQML } <= prog_mask;
                end
                else if( (read_req || refresh_ok) && !downloading ) begin
                    SDRAM_CMD <=
                        refresh_ok ? CMD_AUTOREFRESH : CMD_ACTIVATE;
                    { SDRAM_A, col_addr } <= sdram_addr;
                    autorefresh_cycle <= refresh_ok;
                    read_cycle        <= ~refresh_ok;
                    sdram_ack         <= ~refresh_ok;
                    write_cycle       <= 1'b0;
                    refresh_sr        <= 'd0;
                    refresh_ok        <= 1'b0;
                end
                else begin
                    if( !downloading && refresh_en )
                        { refresh_ok, refresh_sr } <=  { refresh_sr, 1'b1 };
                    else begin // no autorefresh during downloading
                        refresh_sr <= 'd0;
                        refresh_ok <= 1'b0;
                    end
                end
            end
        end
        3'd1: begin // set read/write
            sdram_ack     <= 1'b0;
            SDRAM_A[12:9] <= 4'b0010; // auto precharge;
            SDRAM_A[ 8:0] <= col_addr;
            SDRAM_WRITE <= write_cycle;
            SDRAM_CMD   <= write_cycle ? CMD_WRITE :
                autorefresh_cycle ? CMD_NOP : CMD_READ;
            data_rdy    <= 1'b0;
        end
        3'd3: begin
            if( read_cycle) begin
                data_read[31:16] <= SDRAM_DQ;
            end
            SDRAM_CMD <= CMD_NOP;
        end
        3'd4: begin
            if( read_cycle) begin
                data_read[15: 0] <= data_read[31:16];
                data_read[31:16] <= SDRAM_DQ;
                data_rdy         <= 1'b1;
            end
            SDRAM_CMD <= CMD_NOP;
        end
        endcase
    end
endmodule // jtgng_sdram