/*
 *  Wishbone Compatible PS2 core
 *  Copyright (C) 2010  Donna Polehn <dpolehn@verizon.net>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

module ps2 (
    // Wishbone slave interface
    input         wb_clk_i,  // Clock Input
    input         wb_rst_i,  // Reset Input
    input  [15:0] wb_dat_i,  // Command to send to mouse
    output [15:0] wb_dat_o,  // Received data
    input         wb_cyc_i,  // Cycle
    input         wb_stb_i,  // Strobe
    input  [ 2:1] wb_adr_i,  // Wishbone address lines
    input  [ 1:0] wb_sel_i,  // Wishbone Select lines
    input         wb_we_i,   // Write enable
    output        wb_ack_o,  // Normal bus termination
    output        wb_tgk_o,  // Interrupt request
    output        wb_tgm_o,  // Interrupt request

    input ps2_kbd_clk_,  // PS2 Keyboard Clock, Bidirectional
    inout ps2_kbd_dat_,  // PS2 Keyboard Data, Bidirectional
    inout ps2_mse_clk_,  // PS2 Mouse Clock, Bidirectional
    inout ps2_mse_dat_   // PS2 Mouse Data, Bidirectional
  );

  // --------------------------------------------------------------------
  // --------------------------------------------------------------------
  // This section is a simple WB interface
  // --------------------------------------------------------------------
  // --------------------------------------------------------------------
  wire   [7:0] dat_i;
  wire   [2:0] wb_ps2_addr;
  wire         wb_ack_i;
  wire         write_i;
  wire         read_i;

  // --------------------------------------------------------------------
  // --------------------------------------------------------------------
  // This section is a simple front end for the PS2 Mouse, it is NOT 100% 
  // 8042 compliant but is hopefully close enough to work for most apps.
  // There are two variants in common use, the AT style and the PS2 style 
  // Interface, this is an implementation of the PS2 style which seems to be
  // The most common. Reference: http://www.computer-engineering.org/ps2keyboard/
  //
  //  |7|6|5|4|3|2|1|0|  PS2 Status Register
  //   | | | | | | | `-- PS_IBF  - Input  Buffer Full-- 0: Empty, No unread input at port, 1: Data available for host to read
  //   | | | | | | `---- PS_OBF  - Output Buffer Full-- 0: Output Buffer Empty, 1: data in buffer being processed
  //   | | | | | `------ PS_SYS  - System flag-- POST read this to determine if power-on reset, 0: in reset, 1: BAT code received - System has already beed initialized
  //   | | | | `-------- PS_A2   - Address line A2-- Used internally by kbd controller, 0: A2 = 0 - Port 0x60 was last written to, 1: A2 = 1 - Port 0x64 was last written to 
  //   | | | `---------- PS_INH  - Inhibit flag-- Indicates if kbd communication is inhibited; 0: Keyboard Clock = 0 - Keyboard is inhibited , 1: Keyboard Clock = 1 - Keyboard is not inhibited 
  //   | | `------------ PS_MOBF - Mouse Output Buffer Full; 0: Output buffer empty, 1: Output buffer full
  //   | `-------------- PS_TO   - General Timout-- Indicates timeout during command write or response. (Same as TxTO + RxTO.) 
  //   `---------------- RX_PERR - Parity Error-- Indicates communication error with keyboard (possibly noisy/loose connection) 
  //
  //  |7|6|5|4|3|2|1|0|  PS2 Control Byte
  //   | | | | | | | `-- PS_INT  - Input Buffer Full Interrupt-- When set, IRQ 1 is generated when data is available in the input buffer. 
  //   | | | | | | `---- PS_INT2 - Mouse Input Buffer Full Interrupt - When set, IRQ 12 is generated when mouse data is available. 
  //   | | | | | `------ PS_SYSF - System Flag-- Used to manually set/clear SYS flag in Status register. 
  //   | | | | `--------         - No assignment
  //   | | | `---------- PS_EN   - Disable keyboard-- Disables/enables keyboard interface
  //   | | `------------ PS_EN2  - Disable Mouse-- Disables/enables mouse interface
  //   | `-------------- PS_XLAT - Translate Scan Codes - Enables/disables translation to set 1 scan codes
  //   `----------------         - No assignment
  //
  // --------------------------------------------------------------------


  // --------------------------------------------------------------------
  // Status Register and Wires 
  // --------------------------------------------------------------------
  wire    PS_IBF;
  wire    PS_OBF;
  wire    PS_SYS;
  wire    PS_A2;
  wire    PS_INH;
  wire    PS_MOBF;
  wire    PS_TO;
  wire    RX_PERR;
  wire [7:0]  PS_STAT;

  // --------------------------------------------------------------------
  // Control Register and Wires
  // --------------------------------------------------------------------
  reg  [7:0]  PS_CNTL;        // Control Register
  wire        PS_INT;
  wire        PS_INT2;

  wire        DAT_SEL;
  wire        DAT_wr;
  wire        DAT_rd;

  wire        CMD_SEL;
  wire        CMD_wr;
  wire        CMD_rdc;
  wire        CMD_wrc;
  wire    CMD_mwr;
  wire    CMD_tst;
  wire    CMD_mit;

  wire [7:0]  dat_o;
  wire [7:0]  d_dat_o;
  wire [7:0]  r_dat_o;
  wire [7:0]  t_dat_o;
  wire [7:0]  i_dat_o;
  wire [7:0]  p_dat_o;
  wire [7:0]  ps_tst_o;
  wire [7:0]  ps_mit_o;

  wire     cmd_msnd;

  wire    IBF;

  reg  cnt_r_flag;              // Read Control lines flag
  reg  cnt_w_flag;              // Write to Control lines flag
  reg  cmd_w_msnd;              // Signal to send to mouse flag
  reg cmd_r_test;              // Signal to send test flag
  reg cmd_r_mint;              // Signal to send test flag

  reg   MSE_INT;            // Mouse Receive interrupt signal
  wire  PS_READ;

  wire [7:0]  MSE_dat_o;        // Receive Register
  wire [7:0]  MSE_dat_i;
  wire        MSE_RDY;        // Signal data received
  wire        MSE_DONE;        // Signal command finished sending
  wire        MSE_TOER;             // Indicates a Transmit error occured
  wire        MSE_OVER;             // Indicates buffer over run error
  wire        MSE_SEND;

  wire       KBD_INT;
  wire [7:0] KBD_dat_o;
  wire     KBD_Txdone;
  wire     KBD_Rxdone;

  // Unused output
  wire released;

  // WD Timer
  reg [12:0] WD_timer_clk_r;
  reg WD_timer_clk;
  reg [5:0] WD_timer_r;
  reg  NEW_BATCH;
  wire BATCH_SEL;

/*
 * We comment this out as they are never read
 *
  wire        PS_SYSF = PS_CNTL[2];  // 0: Power-on value - Tells POST to perform power-on tests/initialization. 1: BAT code received - Tells POST to perform "warm boot" tests/initiailization.
  wire        PS_EN   = PS_CNTL[4];  // 0: Enable - Keyboard interface enabled. 1: Disable - All keyboard communication is disabled.
  wire        PS_EN2  = PS_CNTL[5];  // 0: Enable - Auxillary PS/2 device interface enabled 1: Disable - Auxillary PS/2 device interface disabled
  wire        PS_XLAT = PS_CNTL[6];  // 0: Translation disabled - Data appears at input buffer exactly as read from keyboard 1: Translation enabled - Scan codes translated to set 1 before put in input buffer
*/
`define     default_cntl  8'b0100_0111

  // --------------------------------------------------------------------
  // Behaviour for Command Register 
  // The PS2 has this funky command byte structure:
  //
  // - If you write 0x60 to 0x64 port and they next byte you write to port 0x60
  // is stored as the command byte (nice and confusing).
  //
  // - If you write 0x20 to port 0x64, the next byte you read from port
  // 0x60 is the command byte read back.
  //
  // - If you read from 0x64, you get the status
  //
  // - if you read 0x60, that is either mouse or keyboard data, depending
  // on the last command sent
  //
  // - if you write data to 0x60, either mouse or keyboard data is transmitted
  // to either the mouse or keyboard depending on the last command.
  //
  // Right now, we do not allow sending data to the keyboard, that maybe
  // will change later on.
  // 
  // --------------------------------------------------------------------
  // Controller Commands:
  //           ,------------------------ - Currently Supported Command 
  //           |
  // 0x20      X Read control lines      - Next byte read from 0x60 is control line info
  // 0x60      X Write to control lines  - Next byte writen to 0x60 is control line info
  // 0x90-0x9F _ Write to output port    - Writes command's lower nibble to lower nibble of output port 
  // 0xA1      _ Get version number      - Returns firmware version number. 
  // 0xA4      _ Get password            - Returns 0xFA if password exists; otherwise, 0xF1. 
  // 0xA5      _ Set password            - Set the new password by sending a null-terminated string of scan codes as this command's parameter. 
  // 0xA6      _ Check password          - Compares keyboard input with current password. 
  // 0xA7      _ Disable mouse interface - PS/2 mode only.  Similar to "Disable keyboard interface" (0xAD) command. 
  // 0xA8      _ Enable mouse interface  - PS/2 mode only.  Similar to "Enable keyboard interface" (0xAE) command. 
  // 0xA9      X Mouse interface test    - Returns 0x00 if okay, 0x01 if Clock line stuck low, 0x02 if clock line stuck high, 0x03 if data line stuck low, and 0x04 if data line stuck high. 
  // 0xAA      X Controller self-test    - Returns 0x55 if okay. 
  // 0xAB      _ Keyboard interface test - Returns 0x00 if okay, 0x01 if Clock line stuck low, 0x02 if clock line stuck high, 0x03 if data line stuck low, and 0x04 if data line stuck high. 
  // 0xAD      _ Disable keybrd interface- Sets bit 4 of command byte and disables all communication with keyboard. 
  // 0xAE      _ Enable keybrd interface - Clears bit 4 of command byte and re-enables communication with keyboard. 
  // 0xAF      _ Get version
  // 0xC0      _ Read input port         - Returns values on input port (see Input Port definition.)
  // 0xC1      _ Copy input port LSn     - PS/2 mode only. Copy input port's low nibble to Status register (see Input Port definition) 
  // 0xC2      _ Copy input port MSn     - PS/2 mode only. Copy input port's high nibble to Status register (see Input Port definition.) 
  // 0xD0      _ Read output port        - Returns values on output port (see Output Port definition.)  
  // 0xD1      _ Write output port       - Write parameter to output port (see Output Port definition.) 
  // 0xD2      _ Write keyboard buffer   - Parameter written to input buffer as if received from keyboard. 
  // 0xD3      _ Write mouse buffer      - Parameter written to input buffer as if received from mouse. 
  // 0xD4      X Write mouse Device      - Sends parameter to the auxillary PS/2 device. 
  // 0xE0      _ Read test port          - Returns values on test port (see Test Port definition.) 
  // 0xF0-0xFF _ Pulse output port       - Pulses command's lower nibble onto lower nibble of output port (see Output Port definition.) 
  // --------------------------------------------------------------------
`define PS2_CMD_A9    8'hA9    // Mouse Interface test
`define PS2_CMD_AA    8'hAA    // Controller self test
`define PS2_CMD_D4    8'hD4    // Write to mouse
`define PS2_CNT_RD    8'h20    // Read command byte
`define PS2_CNT_WR    8'h60    // Write control byte

`define PS2_DAT_REG    3'b000    // 0x60 - RW Transmit / Receive register
`define PS2_BATCH_REG  3'b010    // 0x62 - RD - New BATCH (BATCH-3 bytes from mouse)
`define PS2_CMD_REG    3'b100    // 0x64 - RW - Status / command register

  // --------------------------------------------------------------------
  // Command Behavior
  // --------------------------------------------------------------------
  // --------------------------------------------------------------------
  // Behavior of Control Register
  // --------------------------------------------------------------------
  always @(posedge wb_clk_i) begin    // Synchrounous
    if(wb_rst_i) begin
    PS_CNTL     <= `default_cntl;   // Set initial default value
    cnt_r_flag  <= 1'b0;        // Reset the flag
    cnt_w_flag  <= 1'b0;        // Reset the flag
    cmd_w_msnd  <= 1'b0;        // Reset the flag
    cmd_r_test  <= 1'b0;        // Reset the flag
    cmd_r_mint  <= 1'b0;        // Reset the flag
    end
    else
    if(CMD_rdc) begin
      cnt_r_flag <= 1'b1;    // signal next read from 0x60 is control info
    end
    else
    if(CMD_wrc) begin
      cnt_w_flag <= 1'b1;        // signal next write to  0x60 is control info
      cmd_w_msnd <= 1'b0;        // Reset the flag
    end
    else
    if(CMD_mwr) begin
      cmd_w_msnd <= 1'b1;    // signal next write to  0x60 is mouse info
    end
    else
    if(CMD_tst) begin
      cmd_r_test <= 1'b1;    // signal next read from 0x60 is test info
    end
    else
    if(CMD_mit) begin
      cmd_r_mint <= 1'b1;    // signal next read from 0x60 is test info
    end
    else
    if(DAT_rd) begin
      if(cnt_r_flag) cnt_r_flag <= 1'b0;    // Reset the flag
      if(cmd_r_test) cmd_r_test <= 1'b0;    // Reset the flag
      if(cmd_r_mint) cmd_r_mint <= 1'b0;    // Reset the flag
    end
    else
    if(DAT_wr) begin
      if(cnt_w_flag) begin
        PS_CNTL    <= dat_i;        // User requested to write control info
        cnt_w_flag  <= 1'b0;        // Reset the flag
      end
    end

    if(cmd_w_msnd && MSE_DONE) cmd_w_msnd <= 1'b0;    // Reset the flag
  end  // Synchrounous always

  // --------------------------------------------------------------------
  // Mouse Transceiver Section
  // --------------------------------------------------------------------

  // --------------------------------------------------------------------
  // Mouse Receive Interrupt behavior
  // --------------------------------------------------------------------
  always @(posedge wb_clk_i or posedge wb_rst_i) begin  // Synchrounous
    if(wb_rst_i) MSE_INT <= 1'b0;                     // Default value
    else begin
        if(MSE_RDY) MSE_INT <= 1'b1;      // Latch interrupt
        if(PS_READ) MSE_INT <= 1'b0;      // Clear interrupt
    end
  end  // Synchrounous always

  // --------------------------------------------------------------------
  // Instantiate the PS2 UART for MOUSE
  // --------------------------------------------------------------------
  ps2_mouse_nofifo mouse_nofifo (
    .clk     (wb_clk_i),
    .reset   (wb_rst_i),
    .ps2_clk (ps2_mse_clk_),
    .ps2_dat (ps2_mse_dat_),

    .writedata (MSE_dat_i),       // data to send
    .write     (MSE_SEND),        // signal to send it
    .command_was_sent (MSE_DONE), // Done sending

    .readdata (MSE_dat_o), // data read
    .irq      (MSE_RDY),   // signal data has arrived and is ready to be read

    .error_sending_command (MSE_TOER),  // Time out error
    .buffer_overrun_error  (MSE_OVER)    // Buffer over run error
  );

  // --------------------------------------------------------------------
  // Keyboard Receiver Section
  // --------------------------------------------------------------------

  // --------------------------------------------------------------------
  // Instantiate the PS2 UART for KEYBOARD
  // --------------------------------------------------------------------
  ps2_keyb #(
    .TIMER_60USEC_VALUE_PP (750),
    .TIMER_60USEC_BITS_PP  (10),
    .TIMER_5USEC_VALUE_PP  (60),
    .TIMER_5USEC_BITS_PP   (6)
    ) keyb (
    .clk   (wb_clk_i),
    .reset (wb_rst_i),

    .rx_shifting_done (KBD_Rxdone), // done receivign
    .tx_shifting_done (KBD_Txdone), // done transmiting

    .scancode         (KBD_dat_o), // scancode
    .rx_output_strobe (KBD_INT),   // Signals a key presseed
    .released         (released),

    .ps2_clk_  (ps2_kbd_clk_), // PS2 PAD signals
    .ps2_data_ (ps2_kbd_dat_)
  );

  // Combinatorial logic
  assign dat_i    =  wb_sel_i[0] ? wb_dat_i[7:0]  : wb_dat_i[15:8]; // 8 to 16 bit WB
  assign wb_dat_o =  wb_sel_i[0] ? {8'h00, dat_o} : {dat_o, 8'h00}; // 8 to 16 bit WB
  assign wb_ps2_addr = {wb_adr_i,   wb_sel_i[1]};  // Compute Address
  assign wb_ack_i =  wb_stb_i &  wb_cyc_i;    // Immediate ack
  assign wb_ack_o    =  wb_ack_i;
  assign write_i =  wb_ack_i &  wb_we_i;    // WISHBONE write access, Singal to send
  assign read_i =  wb_ack_i & ~wb_we_i;    // WISHBONE write access, Singal to send
  assign wb_tgm_o    =  MSE_INT & PS_INT2;      // Mouse Receive interupts ocurred
  assign wb_tgk_o    =  KBD_INT & PS_INT;      // Keyboard Receive interupts ocurred

  assign PS_IBF = IBF;          // 0: Empty, No unread input at port,  1: Full, New input can be read from port 0x60
  assign PS_OBF = KBD_Txdone;      // 0: Ok to write to port 0x60  1: Full, Don't write to port 0x60
  assign PS_SYS = 1'b1;          // 1: Always 1 cuz this is fpga so will always be initialized
  assign PS_A2 = 1'b0;          // 0: A2 = 0 - Port 0x60 was last written to, 1: A2 = 1 - Port 0x64 was last written to
  assign PS_INH = 1'b1;          // 0: Keyboard Clock = 0 - Keyboard is inhibited , 1: Keyboard Clock = 1 - Keyboard is not inhibited
  assign PS_MOBF = MSE_DONE;        // 0: Buffer empty - Okay to write to auxillary device's output buffer, 1: Output buffer full - Don't write to port auxillary device's output buffer
  assign PS_TO = MSE_TOER;        // 0: No Error - Keyboard received and responded to last command, 1: Timeout Error - See TxTO and RxTO for more information.
  assign RX_PERR = MSE_OVER;        // 0: No Error - Odd parity received and proper command response recieved, 1: Parity Error - Even parity received or 0xFE received as command response.
  assign PS_STAT = {RX_PERR, PS_TO, PS_MOBF, PS_INH, PS_A2, PS_SYS, PS_OBF, PS_IBF};    // Status Register
  assign PS_INT = PS_CNTL[0];  // 0: IBF Interrupt Disabled, 1: IBF Interrupt Enabled - Keyboard driver at software int 0x09 handles input.
  assign PS_INT2 = PS_CNTL[1];  // 0: Auxillary IBF Interrupt Disabled, 1: Auxillary IBF Interrupt Enabled

  assign DAT_SEL = (wb_ps2_addr == `PS2_DAT_REG);
  assign BATCH_SEL = (wb_ps2_addr == `PS2_BATCH_REG);
  assign DAT_wr = DAT_SEL && write_i;
  assign DAT_rd = DAT_SEL && read_i;

  assign CMD_SEL = (wb_ps2_addr == `PS2_CMD_REG);
  assign CMD_wr = CMD_SEL && write_i;
  assign CMD_rdc = CMD_wr  && (dat_i == `PS2_CNT_RD);  // Request to read control info
  assign CMD_wrc = CMD_wr  && (dat_i == `PS2_CNT_WR);  // Request to write control info
  assign CMD_mwr = CMD_wr  && (dat_i == `PS2_CMD_D4);  // Signal to transmit data to mouse
  assign CMD_tst = CMD_wr  && (dat_i == `PS2_CMD_AA);  // User requested self test
  assign CMD_mit = CMD_wr  && (dat_i == `PS2_CMD_A9);  // User mouse interface test

  assign dat_o = d_dat_o;  // Select register
//  assign d_dat_o = DAT_SEL    ? r_dat_o   : PS_STAT;  // Select register
  assign d_dat_o = BATCH_SEL ? {7'b1010000, NEW_BATCH} :( DAT_SEL ? r_dat_o : PS_STAT);  // Select register
  assign r_dat_o = cnt_r_flag ? PS_CNTL   : t_dat_o;  // return control or data
  assign t_dat_o = cmd_r_test ? ps_tst_o  : i_dat_o;  // return control or data
  assign i_dat_o = cmd_r_mint ? ps_mit_o  : p_dat_o;  // return control or data
  assign p_dat_o = MSE_INT    ? MSE_dat_o : KBD_dat_o;  // defer to mouse
  assign ps_tst_o = 8'h55;                // Controller self test
  assign ps_mit_o = 8'h00;                // Controller self test
  assign cmd_msnd = cmd_w_msnd && DAT_wr;  // OK to write to mouse
  assign IBF = MSE_INT || KBD_INT || cnt_r_flag || cmd_r_test || cmd_r_mint;
  assign PS_READ = DAT_rd && !(cnt_r_flag || cmd_r_test || cmd_r_mint);
  assign MSE_dat_i = dat_i;    // Transmit register
  assign MSE_SEND = cmd_msnd;  // Signal to transmit data


  // WD_timer_clk - 10kHz (Interval ~ 0.1ms)-----------------
  always @(posedge wb_clk_i) begin // 25MHz 
    if(wb_rst_i) // reset is active HI
		begin
			WD_timer_clk_r <= 13'h8fc;
			WD_timer_clk <= 1'b1;
		end
    else if(WD_timer_clk_r == 12'h000)
		begin 
			WD_timer_clk_r <= 13'h8fc;
			WD_timer_clk <= 1'b1;       
		end
	 else
		begin  
			WD_timer_clk_r <= WD_timer_clk_r - 13'h001;
			WD_timer_clk <= 1'b0;
		end
  end
  //---------------------------------------------------------------
  always @(posedge WD_timer_clk) begin // 10kHz 
  if(wb_tgm_o) // reset is active HI MOUSE IRQ
		begin
			WD_timer_r <= 6'h0; //reset not immediately (at once)
		end
  else if(WD_timer_r != 6'h3e) 
		WD_timer_r = WD_timer_r + 6'd1; 
  end
  
  // Interrupt request Hi - Copy WD_REG_value 0-8ms [8 bit reg]----
  always @(posedge wb_tgm_o) begin 
	NEW_BATCH = WD_timer_r[5];  // 1- New batch
  end 


endmodule

