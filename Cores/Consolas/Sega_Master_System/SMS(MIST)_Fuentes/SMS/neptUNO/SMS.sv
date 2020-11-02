//============================================================================
//  SMS replica
//
//  Port to MiST
//  Szombathelyi György
//
//  Based on the MiSTer top-level
//  Copyright (C) 2017,2018 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================
//============================================================================
//
//  Multicore 2+ Top by Victor Trucco
//
//============================================================================
//
//============================================================================
//
//  neptUNO adapted by Delgrom
//
//============================================================================
`default_nettype none


module SMS
(
 // Clocks
    input wire  clock_50_i,

    // Buttons
    //input wire [4:1]    btn_n_i,
    
    // SRAM (IS61WV102416BLL-10TLI)
    output wire [19:0]sram_addr_o  = 20'b00000000000000000000,
    inout wire  [15:0]sram_data_io   = 8'bzzzzzzzzbzzzzzzzz,
    output wire sram_we_n_o     = 1'b1,
    output wire sram_oe_n_o     = 1'b1,
    output wire sram_ub_n_o     = 1'b1,
	 output wire sram_lb_n_o     = 1'b1,
        
    // SDRAM (W9825G6KH-6)
    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQMH,
    output        SDRAM_DQML,
    output        SDRAM_CKE,
    output        SDRAM_nCS,
    output        SDRAM_nWE,
    output        SDRAM_nRAS,
    output        SDRAM_nCAS,
    output        SDRAM_CLK,

    // PS2
    inout wire  ps2_clk_io        = 1'bz,
    inout wire  ps2_data_io       = 1'bz,
    inout wire  ps2_mouse_clk_io  = 1'bz,
    inout wire  ps2_mouse_data_io = 1'bz,

    // SD Card
    output wire sd_cs_n_o         = 1'bZ,
    output wire sd_sclk_o         = 1'bZ,
    output wire sd_mosi_o         = 1'bZ,
    input wire  sd_miso_i,

    // Joysticks
    output wire joy_clock_o       = 1'b1,
    output wire joy_load_o        = 1'b1,
    input  wire joy_data_i,
    output wire joy_p7_o          = 1'b1,

    // Audio
    output      AUDIO_L,
    output      AUDIO_R,
    input wire  ear_i,
    //output wire mic_o             = 1'b0,

    // VGA
    output  [4:0] VGA_R,
    output  [4:0] VGA_G,
    output  [4:0] VGA_B,
    output        VGA_HS,
    output        VGA_VS,

    //STM32
    input wire  stm_tx_i,
    output wire stm_rx_o,
    output wire stm_rst_o           = 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
   
    input         SPI_SCK,
    output        SPI_DO,
    input         SPI_DI,
    input         SPI_SS2,
    //output wire   SPI_nWAIT        = 1'b1, // '0' to hold the microcontroller data streaming

    //inout [31:0] GPIO,

    output LED                    = 1'b1 // '0' is LED on
);



//---------------------------------------------------------
//-- MC2+ defaults
//---------------------------------------------------------
//assign GPIO = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
assign stm_rst_o    = 1'bZ;
assign stm_rx_o = 1'bZ;

//no SRAM for this core
assign sram_we_n_o  = 1'b1;
assign sram_oe_n_o  = 1'b1;

//all the SD reading goes thru the microcontroller for this core
assign sd_cs_n_o = 1'bZ;
assign sd_sclk_o = 1'bZ;
assign sd_mosi_o = 1'bZ;

wire joy1_up_i, joy1_down_i, joy1_left_i, joy1_right_i, joy1_p6_i, joy1_p9_i;
wire joy2_up_i, joy2_down_i, joy2_left_i, joy2_right_i, joy2_p6_i, joy2_p9_i;

//joystick_serial  joystick_serial 
//(
//    .clk_i           ( clk_sys ),
//    .joy_data_i      ( joy_data_i ),
//    .joy_clk_o       ( joy_clock_o ),
//    .joy_load_o      ( joy_load_o ),
//
//    .joy1_up_o       ( joy1_up_i ),
//    .joy1_down_o     ( joy1_down_i ),
//    .joy1_left_o     ( joy1_left_i ),
//    .joy1_right_o    ( joy1_right_i ),
//    .joy1_fire1_o    ( joy1_p6_i ),
//    .joy1_fire2_o    ( joy1_p9_i ),
//
//    .joy2_up_o       ( joy2_up_i ),
//    .joy2_down_o     ( joy2_down_i ),
//    .joy2_left_o     ( joy2_left_i ),
//    .joy2_right_o    ( joy2_right_i ),
//    .joy2_fire1_o    ( joy2_p6_i ),
//    .joy2_fire2_o    ( joy2_p9_i )
//);

joydecoder joystick_serial  (
    .clk          ( clk_sys ), 	
    .joy_data     ( joy_data_i ),
    .joy_clk      ( joy_clock_o ),
    .joy_load     ( joy_load_o ),
	 .clock_locked ( locked ),

    .joy1up       ( joy1_up_i ),
    .joy1down     ( joy1_down_i ),
    .joy1left     ( joy1_left_i ),
    .joy1right    ( joy1_right_i ),
    .joy1fire1    ( joy1_p6_i ),
    .joy1fire2    ( joy1_p9_i ),

    .joy2up       ( joy2_up_i ),
    .joy2down     ( joy2_down_i ),
    .joy2left     ( joy2_left_i ),
    .joy2right    ( joy2_right_i ),
    .joy2fire1    ( joy2_p6_i ),
    .joy2fire2    ( joy2_p9_i )
); 



//-----------------------------------------------------------------

assign LED  = ~ioctl_download & ~bk_ena;

`define USE_SP64

`ifdef USE_SP64
localparam MAX_SPPL = 63;
localparam SP64     = 1'b1;
`else
localparam MAX_SPPL = 7;
localparam SP64     = 1'b0;
`endif

`include "build_id.v"
parameter CONF_STR = {
    "P,SMS.ini;",				 
    "S,BIN/SMS/GG/SG,Load ROM;",
    //"S,SAV,Mount;",
    //"T7,Write Save RAM;",
    "O34,Scanlines,None,25%,50%,75%;",
    "OG,Scandoubler,On,Off;",
    "O2,TV System,NTSC,PAL;",
`ifdef USE_SP64
    "O8,Sprites per line,Std(8),All(64);",
`endif
    "OC,FM sound,Enable,Disable;",
    "OA,Region,US/UE,Japan;",
    "O1,Swap joysticks,No,Yes;",
    //"O5,BIOS,Enable,Disable;",
    "OF,Lock mappers,No,Yes;",
    "T0,Reset;",
    "V,v1.0.",`BUILD_DATE
};


reg [7:0] pump_s = 8'b11111111;
PumpSignal PumpSignal (clk_sys, ~locked, ioctl_download, pump_s);							   
////////////////////   CLOCKS   ///////////////////

wire locked;
wire clk_sys;

pll pll
(
    .inclk0(clock_50_i),
    .c0(clk_sys),
    .c1(SDRAM_CLK),
    .locked(locked)
);

//assign SDRAM_CLK = clk_sys;

//////////////////   MiST I/O   ///////////////////
wire [15:0] joy_0;
wire [15:0] joy_1;
wire  [1:0] buttons;
wire [31:0] status;
wire        ypbpr;
wire        no_csync;
wire        scandoubler_disable;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wait;
reg  [7:0]  buffer[15:0];

reg  [31:0] sd_lba;
reg         sd_rd = 0;
reg         sd_wr = 0;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire [31:0] img_size;
/*
user_io #(.STRLEN($size(CONF_STR)>>3)) user_io
(
        .clk_sys(clk_sys),
        .clk_sd(clk_sys),
        .SPI_SS_IO(CONF_DATA0),
        .SPI_CLK(SPI_SCK),
        .SPI_MOSI(SPI_DI),
        .SPI_MISO(SPI_DO),

        .conf_str(CONF_STR),

        .status(status),
        .scandoubler_disable(scandoubler_disable),
        .ypbpr(ypbpr),
        .no_csync(no_csync),
        .buttons(buttons),
        .joystick_0(joy_0),
        .joystick_1(joy_1),

        .sd_conf(0),
        .sd_sdhc(1),
        .sd_lba(sd_lba),
        .sd_rd(sd_rd),
        .sd_wr(sd_wr),
        .sd_ack(sd_ack),
        .sd_buff_addr(sd_buff_addr),
        .sd_dout(sd_buff_dout),
        .sd_din(sd_buff_din),
        .sd_dout_strobe(sd_buff_wr),
        .img_mounted(img_mounted),
        .img_size(img_size)
);
*/
data_io_sms #(.STRLEN($size(CONF_STR)>>3)) data_io
(
    .clk_sys(clk_sys),
    .SPI_SCK(SPI_SCK),
    .SPI_DI(SPI_DI),
    .SPI_SS2(SPI_SS2),
    .SPI_DO(SPI_DO),

    .conf_str(CONF_STR),
    //.data_in        ( keys_s ),
	.data_in        ( pump_s & keys_s ),
    .config_buffer_o (buffer),
    .status(status),

    .clkref_n(ioctl_wait),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),
    .ioctl_download(ioctl_download),
    .ioctl_index(ioctl_index)
);

wire [21:0] ram_addr;
wire  [7:0] ram_dout;
wire        ram_rd;

sdram ram
(
    .SDRAM_DQ   (SDRAM_DQ),
    .SDRAM_A    (SDRAM_A),
    .SDRAM_DQML (SDRAM_DQML),
    .SDRAM_DQMH (SDRAM_DQMH),
    .SDRAM_BA   (SDRAM_BA),
    .SDRAM_nCS  (SDRAM_nCS),
    .SDRAM_nWE  (SDRAM_nWE),
    .SDRAM_nRAS (SDRAM_nRAS),
    .SDRAM_nCAS (SDRAM_nCAS),
    .SDRAM_CKE  (SDRAM_CKE),

    .init(~locked),
    .clk(clk_sys),
    .clkref(ce_cpu_p),

    .waddr(ioctl_addr),
    .din(ioctl_dout),
    .we(rom_wr),
    .we_ack(sd_wrack),

    .raddr((ram_addr[21:0] & cart_mask) + (romhdr ? 10'd512 : 0)),
    .dout(ram_dout),
    .rd(ram_rd),
    .rd_rdy()
);

reg  rom_wr = 0;
wire sd_wrack;
reg  [21:0] cart_mask;
reg  reset, reset_gg;

reg [19:0] power_on_s   = 20'b11111111111111111111;

//GG roms need a longer reset ?
always @(posedge ce_cpu_p) 
begin

        if (ioctl_download == 1'b1)
        begin
            power_on_s = 20'b11111111111111111111;
            reset_gg = 1;
        end
        else if (power_on_s != 0)
        begin
            power_on_s = power_on_s - 1;
        end 
        else
            reset_gg = 0;
end 


always @(posedge clk_sys) begin
    reg old_download, old_reset;

    //reset <= status[0] | ~btn_n_i[4] | ioctl_download | bk_reset | reset_gg;
	 reset <= status[0] | ioctl_download | bk_reset | reset_gg;

    old_download <= ioctl_download;
    old_reset <= reset;

    if(~old_download && ioctl_download) begin
        cart_mask <= 0;
        ioctl_wait <= 0;
    end else begin
        if(ioctl_wr) begin
            ioctl_wait <= 1;
            rom_wr <= ~rom_wr;
            cart_mask <= cart_mask | ioctl_addr[21:0];
        end else if(ioctl_wait && (rom_wr == sd_wrack)) begin
            ioctl_wait <= 0;
        end
    end
end

wire [15:0] audioL, audioR;

wire [7:0] joy1_s;// = {1'b1, m_fireB, m_fireA, m_up, m_down, m_left, m_righ};
wire [7:0] joy2_s;// = {1'b1, joy2_p9_i, joy2_p6_i, joy2_up_i, joy2_down_i, joy2_left_i, joy2_right_i};

wire [7:0] joya = ~joy1_s;
wire [7:0] joyb = ~joy2_s;

wire       romhdr = ioctl_addr[9:0] == 10'h1FF; // has 512 byte header
wire       gg =  (buffer[9] == 8'h47 || buffer[9] == 8'h67) ? 1 : 0; //gg extension ioctl_index[7:6] == 2'd2;

wire [12:0] ram_a;
wire        ram_we;
wire  [7:0] ram_d;
wire  [7:0] ram_q;

wire [14:0] nvram_a;
wire        nvram_we;
wire  [7:0] nvram_d;
wire  [7:0] nvram_q;

system #(MAX_SPPL, "../") system
(
    .clk_sys(clk_sys),
    .ce_cpu(ce_cpu_p),
//  .ce_cpu_p(ce_cpu_p),
//  .ce_cpu_n(ce_cpu_n),
    .ce_vdp(ce_vdp),
    .ce_pix(ce_pix),
    .ce_sp(ce_sp),
    .pal(pal),
    .gg(gg),
    .region(status[10]),
    .bios_en(~status[5]),

    .RESET_n(~reset),

    .rom_rd(ram_rd),
    .rom_a(ram_addr),
    .rom_do(ram_dout),

    .j1_up(joya[3]),
    .j1_down(joya[2]),
    .j1_left(joya[1]),
    .j1_right(joya[0]),
    .j1_tl(joya[4]),
    .j1_tr(joya[5]),
    .j2_up(joyb[3]),
    .j2_down(joyb[2]),
    .j2_left(joyb[1]),
    .j2_right(joyb[0]),
    .j2_tl(joyb[4]),
    .j2_tr(joyb[5]),
    //.pause(joya[6]&joyb[6]),
	.pause(~m_fireH&~m_fire2H),
    .x(x),
    .y(y),
    .color(color),
    .mask_column(mask_column),
    .smode_M1(smode_M1),
    .smode_M2(smode_M2),    
    .smode_M3(smode_M3),    
    .mapper_lock(status[15]),
    .fm_ena(~status[12]),  
    .audioL(audioL),
    .audioR(audioR),

    .sp64(status[8] & SP64),

    .ram_a(ram_a),
    .ram_we(ram_we),
    .ram_d(ram_d),
    .ram_q(ram_q),

    .nvram_a(nvram_a),
    .nvram_we(nvram_we),
    .nvram_d(nvram_d),
    .nvram_q(nvram_q)
);

spram #(.widthad_a(13)) ram_inst
(
    .clock     (clk_sys),
    .address   (ram_a),
    .wren      (ram_we),
    .data      (ram_d),
    .q         (ram_q)
);

wire [8:0] x;
wire [8:0] y;
wire [11:0] color;
wire mask_column;
wire HSync, VSync, HBlank, VBlank;
wire smode_M1, smode_M2, smode_M3;
wire pal = status[2];

video video
(
    .clk(clk_sys),
    .ce_pix(ce_pix),
    .pal(pal),
    .gg(gg),
    .border(~gg),
    .mask_column(mask_column),
    .x(x),
    .y(y),
   .smode_M1(smode_M1),
    .smode_M3(smode_M3),
    
    .hsync(HSync),
    .vsync(VSync),
    .hblank(HBlank),
    .vblank(VBlank)
);

reg ce_cpu_p;
reg ce_cpu_n;
reg ce_vdp;
reg ce_pix;
reg ce_sp;
always @(negedge clk_sys) begin
    reg [4:0] clkd;

    ce_sp <= clkd[0];
    ce_vdp <= 0;//div5
    ce_pix <= 0;//div10
    ce_cpu_p <= 0;//div15
    ce_cpu_n <= 0;//div15
    clkd <= clkd + 1'd1;
    if (clkd==29) begin
        clkd <= 0;
        ce_vdp <= 1;
        ce_pix <= 1;
    end else if (clkd==24) begin
        ce_vdp <= 1;
        ce_cpu_p <= 1;
    end else if (clkd==19) begin
        ce_vdp <= 1;
        ce_pix <= 1;
    end else if (clkd==17) begin
        ce_cpu_n <= 1;
    end else if (clkd==14) begin
        ce_vdp <= 1;
    end else if (clkd==9) begin
        ce_cpu_p <= 1;
        ce_vdp <= 1;
        ce_pix <= 1;
    end else if (clkd==4) begin
        ce_vdp <= 1;
    end else if (clkd==2) begin
        ce_cpu_n <= 1;
    end
end

//////////////////   VIDEO   //////////////////
wire  [3:0] VGA_R_O = HBlank | VBlank ? 4'h0 : color[3:0];
wire  [3:0] VGA_G_O = HBlank | VBlank ? 4'h0 : color[7:4];
wire  [3:0] VGA_B_O = HBlank | VBlank ? 4'h0 : color[11:8];

assign scandoubler_disable = ~status[16] ^ direct_video;

mist_video #(.SD_HCNT_WIDTH(10), .COLOR_DEPTH(4)) mist_video
(
    .clk_sys(clk_sys),
    .scanlines(status[4:3]),
    .scandoubler_disable(scandoubler_disable),
    .rotate(2'b00),
    .SPI_DI(SPI_DI),
    .SPI_SCK(SPI_SCK),
    .SPI_SS3(SPI_SS2),
    .HSync(~HSync),
    .VSync(~VSync),
    .R(VGA_R_O),
    .G(VGA_G_O),
    .B(VGA_B_O),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .osd_enable(osd_enable)
);

//////////////////   AUDIO   //////////////////

dac #(16) dacl
(
    .clk_i(clk_sys),
    .res_n_i(~reset),
    .dac_i({~audioL[15], audioL[14:0]}),
    .dac_o(AUDIO_L)
);

dac #(16) dacr
(
    .clk_i(clk_sys),
    .res_n_i(~reset),
    .dac_i({~audioR[15], audioR[14:0]}),
    .dac_o(AUDIO_R)
);

/////////////////////////  STATE SAVE/LOAD  /////////////////////////////
// 8k auxilary RAM - 32k doesn't fit
dpram #(.widthad_a(13)) nvram_inst
(
    .clock_a     (clk_sys),
    .address_a   (nvram_a[12:0]),
    .wren_a      (nvram_we),
    .data_a      (nvram_d),
    .q_a         (nvram_q),
    .clock_b     (clk_sys),
    .address_b   ({sd_lba[3:0],sd_buff_addr}),
    .wren_b      (sd_buff_wr & sd_ack),
    .data_b      (sd_buff_dout),
    .q_b         (sd_buff_din)
);

reg  bk_ena     = 0;
reg  bk_load    = 0;
wire bk_save    = status[7];
reg  bk_reset   = 0;

always @(posedge clk_sys) begin
    reg  old_load = 0, old_save = 0, old_ack, old_mounted = 0, old_download = 0;
    reg  bk_state = 0;

    bk_reset <= 0;

    old_download <= ioctl_download;
    if (~old_download & ioctl_download) bk_ena <= 0;

    old_mounted <= img_mounted;
    if(~old_mounted && img_mounted && img_size) begin
        bk_ena <= 1;
        bk_load <= 1;
    end

    old_load <= bk_load;
    old_save <= bk_save;
    old_ack  <= sd_ack;

    if(~old_ack & sd_ack) {sd_rd, sd_wr} <= 0;

    if(!bk_state) begin
        if(bk_ena & ((~old_load & bk_load) | (~old_save & bk_save))) begin
            bk_state <= 1;
            sd_lba <= 0;
            sd_rd <=  bk_load;
            sd_wr <= ~bk_load;
        end
    end else begin
        if(old_ack & ~sd_ack) begin
            if(&sd_lba[3:0]) begin
                if (bk_load) bk_reset <= 1;
                bk_load <= 0;
                bk_state <= 0;
            end else begin
                sd_lba <= sd_lba + 1'd1;
                sd_rd  <=  bk_load;
                sd_wr  <= ~bk_load;
            end
        end
    end
end


//-----------------------

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_fireG, m_fireH, m_fireI;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_fire2G, m_fire2H, m_fire2I;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

wire kbd_intr,osd_enable, direct_video;
wire [7:0] kbd_scancode;
wire [7:0] keys_s;

//get scancode from keyboard
io_ps2_keyboard keyboard 
 (
  .clk       ( ce_cpu_p ),
  .kbd_clk   ( ps2_clk_io ),
  .kbd_dat   ( ps2_data_io ),
  .interrupt ( kbd_intr ),
  .scancode  ( kbd_scancode )
);

wire [8:0]controls_s;
reg joy1_up_q   ; reg joy1_up_0;
reg joy1_down_q ; reg joy1_down_0;
reg joy1_left_q ; reg joy1_left_0;
reg joy1_right_q; reg joy1_right_0;
reg joy1_p6_q   ; reg joy1_p6_0;
reg joy1_p9_q   ; reg joy1_p9_0;

reg joy2_up_q   ; reg joy2_up_0;
reg joy2_down_q ; reg joy2_down_0;
reg joy2_left_q ; reg joy2_left_0;
reg joy2_right_q; reg joy2_right_0;
reg joy2_p6_q   ; reg joy2_p6_0;
reg joy2_p9_q   ; reg joy2_p9_0;
/*
always @(posedge clk_sys) 
   begin
         joy1_up_0    <= joy1_up_i;
         joy1_down_0  <= joy1_down_i;
         joy1_left_0  <= joy1_left_i;
         joy1_right_0 <= joy1_right_i;
         joy1_p6_0    <= joy1_p6_i;
         joy1_p9_0    <= joy1_p9_i;
      
         joy2_up_0    <= joy2_up_i;
         joy2_down_0  <= joy2_down_i;
         joy2_left_0  <= joy2_left_i;
         joy2_right_0 <= joy2_right_i;
         joy2_p6_0    <= joy2_p6_i;
         joy2_p9_0    <= joy2_p9_i;
   end 
   
always @(posedge clk_sys) 
   begin
         joy1_up_q    <= joy1_up_0;
         joy1_down_q  <= joy1_down_0;
         joy1_left_q  <= joy1_left_0;
         joy1_right_q <= joy1_right_0;
         joy1_p6_q    <= joy1_p6_0;
         joy1_p9_q    <= joy1_p9_0;

         joy2_up_q    <= joy2_up_0;
         joy2_down_q  <= joy2_down_0;
         joy2_left_q  <= joy2_left_0;
         joy2_right_q <= joy2_right_0;
         joy2_p6_q    <= joy2_p6_0;
         joy2_p9_q    <= joy2_p9_0;
     
end

always @(posedge clk_sys) 
   begin
         joy1_up_r    <= joy1_up_q;
         joy1_down_r  <= joy1_down_q;
         joy1_left_r  <= joy1_left_q;
         joy1_right_r <= joy1_right_q;
         joy1_p6_r    <= joy1_p6_q;
         joy1_p9_r    <= joy1_p9_q;

         joy2_up_r    <= joy2_up_q;
         joy2_down_r  <= joy2_down_q;
         joy2_left_r  <= joy2_left_q;
         joy2_right_r <= joy2_right_q;
         joy2_p6_r    <= joy2_p6_q;
         joy2_p9_r    <= joy2_p9_q;
     
end
*/

wire hsync2, hsync3;

always @(posedge clk_sys) 
begin
        hsync2    <= HSync;
end

always @(posedge clk_sys) 
begin			
			hsync3    <= hsync2;
end		
//translate scancode to joystick
kbd_joystick_sms #( .OSD_CMD ( 3'b011 )) k_joystick 
(
   .clk          ( ce_cpu_p ),
   .kbdint       ( kbd_intr ),
   .kbdscancode  ( kbd_scancode ), 
   .direct_video ( direct_video ),
  

   .joystick_0     ({ joy1_p9_i, joy1_p6_i, joy1_up_i, joy1_down_i, joy1_left_i, joy1_right_i }),
   .joystick_1     ({ joy2_p9_i, joy2_p6_i, joy2_up_i, joy2_down_i, joy2_left_i, joy2_right_i }),	 
          
   //-- joystick_0 and joystick_1 should be swapped
   .joyswap        ( status[1] ),
        
   //-- player1 and player2 should get both joystick_0 and joystick_1
   .oneplayer      ( 0 ),

   //-- tilt, coin4-1, start4-1
   .controls    ( ),
        
   //-- fire12-1, up, down, left, right

   .player1     ( {m_fireI,  m_fireH,  m_fireG,  m_fireF,   m_fireE, joy1_s }),
   .player2     ( {m_fire2I, m_fire2H, m_fire2G, m_fire2F, m_fire2E, joy2_s }),
        
   //-- keys to the OSD
   .osd_o       ( keys_s ),
   .osd_enable  ( osd_enable ),
    
   //-- sega joystick
   .sega_clk       (hsync3),  //HSync),  
	.sega_strobe    ( joy_p7_o )            
		
		
);

endmodule
