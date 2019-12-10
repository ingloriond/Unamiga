//============================================================================
//  Amstrad CPC 6128
// 
//  Port to MiST/MiSTer.
//  Copyright (C) 2018 Sorgelig
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
//
//============================================================================
//
//  Multicore 2 Top by Victor Trucco
//
//============================================================================



module Amstrad
(
   // Clocks
	input wire	clock_50_i,

	// Buttons
	input wire [4:1]	btn_n_i,

	// SRAMs (AS7C34096)
	output wire	[18:0]sram_addr_o  = 18'b0000000000000000000,
	inout wire	[7:0]sram_data_io	= 8'bzzzzzzzz,
	output wire	sram_we_n_o		= 1'b1,
	output wire	sram_oe_n_o		= 1'b1,
		
	// SDRAM	(H57V256)
	output wire	[12:0]sdram_ad_o,
	inout wire	[15:0]sdram_da_io,
	output wire	[1:0]sdram_ba_o,
	output wire	[1:0]sdram_dqm_o,
	output wire	sdram_ras_o,
	output wire	sdram_cas_o,
	output wire	sdram_cke_o,
	output wire	sdram_clk_o,
	output wire	sdram_cs_o,
	output wire	sdram_we_o,

	// PS2
	inout wire	ps2_clk_io			= 1'bz,
	inout wire	ps2_data_io			= 1'bz,
	inout wire	ps2_mouse_clk_io  = 1'bz,
	inout wire	ps2_mouse_data_io = 1'bz,

	// SD Card
	output wire	sd_cs_n_o			= 1'b1,
	output wire	sd_sclk_o			= 1'b0,
	output wire	sd_mosi_o			= 1'b0,
	input wire	sd_miso_i,

	// Joysticks
	input wire	joy1_up_i,
	input wire	joy1_down_i,
	input wire	joy1_left_i,
	input wire	joy1_right_i,
	input wire	joy1_p6_i,
	input wire	joy1_p9_i,
	input wire	joy2_up_i,
	input wire	joy2_down_i,
	input wire	joy2_left_i,
	input wire	joy2_right_i,
	input wire	joy2_p6_i,
	input wire	joy2_p9_i,
	output wire	joyX_p7_o			= 1'b1,

	// Audio
	output wire	dac_l_o				= 1'b0,
	output wire	dac_r_o				= 1'b0,
	input wire	ear_i,
	output wire	mic_o					= 1'b0,

		// VGA
	output wire	[4:0]vga_r_o,
	output wire	[4:0]vga_g_o,
	output wire	[4:0]vga_b_o,
	output wire	vga_hsync_n_o,
	output wire	vga_vsync_n_o,

		// HDMI
	output wire	[7:0]tmds_o			= 8'b00000000,

		//STM32
	input wire	stm_tx_i,
	output wire	stm_rx_o,
	output wire	stm_rst_o			= 1'bz, // '0' to hold the microcontroller reset line, to free the SD card
		
	inout wire	stm_b8_io, 
	inout wire	stm_b9_io,
	inout wire	stm_b12_io, //SPI_SS3
	inout wire	stm_b13_io, //SPI_SCK
	inout wire	stm_b14_io, //SPI_DO
	input wire	stm_b15_io  //SPI_DI
	


);

//////////////////////////////////////////////////////////////////////////

assign stm_rst_o			= 1'bz;
//assign LED = ~mf2_en & ~ioctl_download & ~tape_motor;

localparam CONF_STR2 = {
	"AMSTRAD;;",
	"S0,DSK,Mount Disk A:;",
	"S1,DSK,Mount Disk B:;",
	"F,E??,Load expansion;",
	"F,CDT,Load;",
	"OK,Tape sound,Disabled,Enabled;",
	"O9A,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"OBD,Display,Color(GA),Color(ASIC),Green,Amber,Cyan,White;",
	"O2,CRTC,Type 1,Type 0;",
	"OI,Joysticks swap,No,Yes;",
	"OJ,Mouse,Enabled,Disabled;",
	"OEF,Multiface 2,Enabled,Hidden,Disabled;",
	"O6,CPU timings,Original,Fast;",
	"OGH,FDC,Original,Fast,Disabled;",
	"O5,Distributor,Amstrad,Schneider;",
	"O4,Model,CPC 6128,CPC 664;",
	"T0,Reset & apply model;"
};
                           
localparam CONF_STR = { "P,amstrad.dat" };
localparam STRLEN = 13;

//////////////////////////////////////////////////////////////////////////

wire clk_sys;
wire locked;

pll pll
(
	.inclk0(clock_50_i),
	.c0(clk_sys),
	.c1(sdram_clk_o),
	.locked(locked)
);

reg ce_4n;
reg ce_4p, ce_ref, ce_u765;
reg ce_boot;
reg ce_16;
reg clk_image = 0;

always @(negedge clk_sys) begin
	reg [3:0] div = 0;

	div     <= div + 1'd1;

	ce_4n   <= (div == 8);
	ce_4p   <= !div;
	ce_ref  <= !div;
	ce_boot <= !div;

	ce_u765 <= !div[2:0]; //8 MHz
	ce_16   <= !div[1:0]; //16 MHz
	
	clk_image <= div[1];
end

//////////////////////////////////////////////////////////////////////////

wire [31:0] sd_lba;
wire  [1:0] sd_rd;
wire  [1:0] sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire  [1:0] img_mounted;
wire [63:0] img_size;
wire        img_readonly;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_download;
wire  [7:0] ioctl_index;
wire [31:0] ioctl_file_ext;
reg  [7:0] 	buffer[15:0];

wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire  [1:0] buttons;
wire  [6:0] joy1;
wire  [6:0] joy2;
wire [31:0] status;

wire        scandoubler_disable = 1'b0;
wire        forced_scandoubler = ~scandoubler_disable;
wire        ypbpr;

//assign img_mounted = {1'b0,~btn_n_i[3]};
		
mist_io #(.STRLEN(STRLEN)) mist_io
(
	.clk_sys(clk_sys),

	.SPI_SCK(stm_b13_io),
	.CONF_DATA0(stm_b8_io),//CONF_DATA0),
	.SPI_SS2(stm_b12_io),
	.SPI_DI(stm_b15_io),
	.SPI_DO(stm_b14_io),

	.img_mounted(img_mounted),
	.img_size(img_size),
	.sd_conf(0),
	.sd_sdhc(1),
	
//	.sd_lba(sd_lba),
//	.sd_rd(sd_rd),
//	.sd_wr(sd_wr),
//	.sd_ack(sd_ack),
//	.sd_buff_addr(sd_buff_addr),
//	.sd_buff_dout(sd_buff_dout),
//	.sd_buff_din(sd_buff_din),
//	.sd_buff_wr(sd_buff_wr),

	.ps2_key(),//ps2_key),
	.ps2_mouse(ps2_mouse),

	.joystick_0(joy1),
	.joystick_1(joy2),

	.buttons(buttons),
	.status(status),
	.scandoubler_disable(),//scandoubler_disable),
	.ypbpr(ypbpr),

	.conf_str		( CONF_STR ),
	.data_in			( osd_s & keys_s ),
	.menu_in			( menu_in ),
	.config_buffer_o ( buffer ),

	.ioctl_ce(ce_boot),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_file_ext(ioctl_file_ext)
);

reg [15:0] power_on_s 	= 16'b1111111111111111;
reg power_on_reset;
reg [7:0] osd_s;
reg menu_in = 1'b0;

//start the microcontroller OSD menu after the power on
always @(posedge clk_sys or posedge hard_reset)
begin
		if (hard_reset) 
			begin
				menu_in = 1'b0;
				power_on_s = 16'b1111111111111111;
			end 
		else 
			begin 
			if ( power_on_s != 16'd0 ) 
				begin
					power_on_s = power_on_s - 16'd1;
					power_on_reset = 1'b1;
					osd_s = 8'b00111111;
				end
			else
				begin
					power_on_reset = 1'b0;
				end 
				
			if (ioctl_download && osd_s == 8'b00111111)
			begin 
				menu_in = 1'b1;
				osd_s = 8'b11111111;		
			end 
		end
end


wire        rom_download  = ioctl_download && (ioctl_index == 8'd0);
wire        dsk_download  = ioctl_download && (ioctl_index == 8'd1);
wire        ext_download  = ioctl_download && (ioctl_index == 8'd3);
wire        tape_download = ioctl_download && (ioctl_index == 8'd4);

reg         boot_wr = 0;
reg  [22:0] boot_a;
reg   [1:0] boot_bank;
reg   [7:0] boot_dout;

reg  [22:0] tape_addr;
reg         tape_wr = 0;
reg         tape_ack;

wire        rom_mask = ram_a[22] & (~rom_map[map_addr] | &{map_addr,status[15]});
reg         rom_map[256] = '{default:0};
reg   [7:0] map_addr;
always @(posedge clk_sys) map_addr <= ram_a[21:14];

reg [8:0] page = 0;
always @(posedge clk_sys) begin
	reg combo = 0;
	reg old_download;
	reg old_wr;
	reg old_tape_ack;

	old_wr <= ioctl_wr;
	if((rom_download | ext_download) & old_wr & ~ioctl_wr) begin
		if(boot_a[22]) rom_map[boot_a[21:14]] <= 1;
		if(combo && &boot_a[13:0]) begin
			combo <= 0;
			page  <= 9'h1FF;
		end
	end

	old_download <= ioctl_download;
	if(~old_download & ioctl_download & ext_download) begin
		page <= 9'h1EE; // some unused page for malformed file extension
		combo <= 0;
		if(ioctl_file_ext[15:8] >= "0" && ioctl_file_ext[15:8] <= "9") page[7:4] <= ioctl_file_ext[11:8];
		if(ioctl_file_ext[15:8] >= "A" && ioctl_file_ext[15:8] <= "F") page[7:4] <= ioctl_file_ext[11:8]+4'd9;
		if(ioctl_file_ext[7:0]  >= "0" && ioctl_file_ext[7:0]  <= "9") page[3:0] <= ioctl_file_ext[3:0];
		if(ioctl_file_ext[7:0]  >= "A" && ioctl_file_ext[7:0]  <= "F") page[3:0] <= ioctl_file_ext[3:0] +4'd9;
		if(ioctl_file_ext[15:0] == "ZZ") page <= 0;
		if(ioctl_file_ext[15:0] == "Z0") begin page <= 0; combo <= 1; end
	end

	old_tape_ack <= tape_ack;
	if(tape_download) begin
		if(old_tape_ack ^ tape_ack) tape_wr <= 0;
		if(~old_wr & ioctl_wr) tape_wr <= 1'b1;
	end
end

always_comb begin
	boot_wr = (rom_download | ext_download) & ioctl_wr;
	boot_dout = ioctl_dout;

	boot_a[13:0] = ioctl_addr[13:0];
	boot_a[22:14] = '1;
	boot_bank = 0;
	tape_addr = tape_play_addr;

	if (tape_download) begin
		tape_addr = ioctl_addr[22:0];
	end
	else if(ext_download) begin
		boot_a[22]    = page[8];
		boot_a[21:14] = page[7:0] + ioctl_addr[21:14];
		boot_bank     = { 1'b0, model };
	end
	else begin
		case(ioctl_addr[24:14])
				0,4: boot_a[22:14] = 9'h000;
				1,5: boot_a[22:14] = 9'h100;
				2,6: boot_a[22:14] = 9'h107;
				3,7: boot_a[22:14] = 9'h1ff; //MF2
		  default: boot_wr = 0;
		endcase

		case(ioctl_addr[24:14])
			 0,1,2,3: boot_bank = 0;
			 4,5,6,7: boot_bank = 1;
			 default: boot_bank = 0;
		endcase
	end
end

//////////////////////////////////////////////////////////////////////////

wire dsk_wr;
wire [18:0] dsk_addr_s;
wire [7:0] disk_data_s;

assign sram_addr_o  = (dsk_download) ? ioctl_addr[18:0] : dsk_addr_s;
assign sram_data_io = (dsk_download) ? ioctl_dout 	: 8'bzzzzzzzz;
assign disk_data_s  = sram_data_io;
assign sram_oe_n_o  = 1'b0; 
assign sram_we_n_o  = ~(dsk_download & ioctl_wr);



image_controller image_controller1
(
    
		.clk_i			( clk_image ),
		.reset_i			( reset ),
 	 
		.sd_lba			( sd_lba ), 
		.sd_rd			( sd_rd ),
		.sd_wr			( sd_wr ),

		.sd_ack			( sd_ack ),
		.sd_buff_addr	( sd_buff_addr ), 
		.sd_buff_dout	( sd_buff_dout ), 
		.sd_buff_din	( sd_buff_din ),
		.sd_buff_wr		( sd_buff_wr ),
		
		.sram_addr_o  	( dsk_addr_s ),
		.sram_data_i   ( disk_data_s )
);


//////////////////////////////////////////////////////////////////////////

wire        mem_wr;
wire        mem_rd;
wire [22:0] ram_a;
wire  [7:0] ram_dout;

wire [15:0] vram_dout;
wire [14:0] vram_addr;

//assign SDRAM_CLK = clk_sys;

sdram sdram
(
	 .SDRAM_DQ       ( sdram_da_io    ),
    .SDRAM_A        ( sdram_ad_o     ),
    .SDRAM_DQML     ( sdram_dqm_o[0] ),
    .SDRAM_DQMH     ( sdram_dqm_o[1] ),
    .SDRAM_nWE      ( sdram_we_o     ),
    .SDRAM_nCAS     ( sdram_cas_o    ),
    .SDRAM_nRAS     ( sdram_ras_o    ),
    .SDRAM_nCS      ( sdram_cs_o     ),
    .SDRAM_BA       ( sdram_ba_o     ),
    .SDRAM_CKE      ( sdram_cke_o    ),

	.init(~locked),
	.clk(clk_sys),
	.clkref(ce_ref),

	.oe  (reset ? 1'b0      : mem_rd & ~mf2_ram_en & ~rom_mask),
	.we  (reset ? boot_wr   : mem_wr & ~mf2_ram_en & ~mf2_rom_en),
	.addr(reset ? boot_a    : mf2_rom_en ? { 9'h1ff, cpu_addr[13:0] }: ram_a),
	.bank(reset ? boot_bank : { 1'b0, model } ),
	.din (reset ? boot_dout : cpu_dout),
	.dout(ram_dout),

	.vram_addr({2'b10,vram_addr,1'b0}),
	.vram_dout(vram_dout),

	.tape_addr(tape_addr),
	.tape_din(boot_dout),
	.tape_dout(tape_dout),
	.tape_wr(tape_wr),
	.tape_rd(tape_rd),
	.tape_ack(tape_ack)
);

reg model = 0;
reg reset, hard_reset;

always @(posedge clk_sys) begin
	if(reset) model <= status[4];
//	reset <= status[0] | buttons[1] | rom_download | ext_download;
	reset <= (~btn_n_i[1]) | rom_download | ext_download;
	
	hard_reset <= ~(btn_n_i[1] | btn_n_i[2]);
	
end

////////////////////// CDT playback ///////////////////////////////

wire        tape_read;
wire        tape_data_req;
reg         tape_data_ack;
reg         tape_reset;
reg         tape_rd;
reg   [7:0] tape_dout;
reg  [22:0] tape_play_addr;
reg  [22:0] tape_last_addr;

always @(posedge clk_sys) begin
    reg old_tape_ack;

    if (reset) begin
        tape_play_addr <= 0;
        tape_last_addr <= 0;
        tape_rd <= 0;
        tape_reset <= 1;
    end else begin
        old_tape_ack <= tape_ack;
        tape_reset <= 0;
        if (tape_download) begin
            tape_play_addr <= 0;
            tape_last_addr <= tape_addr;
            tape_reset <= 1;
        end
        if (!ioctl_download && tape_rd && tape_ack ^ old_tape_ack) begin
            tape_data_ack <= tape_data_req;
            tape_rd <= 0;
            tape_play_addr <= tape_play_addr + 1'd1;
        end else if (!ioctl_download && tape_play_addr <= tape_last_addr && !tape_rd && (tape_data_req ^ tape_data_ack)) begin
            tape_rd <= 1;
        end
    end
end

tzxplayer tzxplayer
(
    .clk(clk_sys),
    .ce(1),
    .restart_tape(tape_reset),
    .host_tap_in(tape_dout),
    .tzx_req(tape_data_req),
    .tzx_ack(tape_data_ack),
    .cass_read(tape_read),
    .cass_motor(tape_motor)
);

//////////////////////////////////////////////////////////////////////////

wire [3:0] fdc_sel = {cpu_addr[10],cpu_addr[8],cpu_addr[7],cpu_addr[0]};

wire [7:0] fdc_dout = (u765_sel & io_rd) ? u765_dout : 8'hFF;

reg motor = 0;
always @(posedge clk_sys) begin
	reg old_wr;
	
	old_wr <= io_wr;
	if(~old_wr && io_wr && !fdc_sel[3:1]) begin
		motor <= cpu_dout[0];
	end
	
	if(img_mounted) motor <= 0;
end

wire [7:0] u765_dout;
wire       u765_sel = (fdc_sel[3:1] == 'b010) & ~status[17];

reg  [1:0] u765_ready = 0;
always @(posedge clk_sys) if(img_mounted[0]) u765_ready[0] <= |img_size;
always @(posedge clk_sys) if(img_mounted[1]) u765_ready[1] <= 1'b0; //|img_size;

u765 u765
(
	.reset(~btn_n_i[1]),

	.clk_sys(clk_sys),
	.ce(ce_u765),

	.fast(status[16]),

	.a0(fdc_sel[0]),
	.ready(u765_ready),
	.motor({ motor, motor }),
	.available(2'b11),
	.nRD(~(u765_sel & io_rd)),
	.nWR(~(u765_sel & io_wr)),
	.din(cpu_dout),
	.dout(u765_dout),
	
	.img_mounted(img_mounted),	// (in) signaling that new image has been mounted
	.img_size(img_size[31:0]),	// (in) size of image in bytes
	.img_wp(0), 					// (in) write protect. latched at img_mounted
	
	.sd_lba(sd_lba),					// (out)
	.sd_rd(sd_rd),						// (out)
	.sd_wr(sd_wr),						// (out)
	.sd_ack(sd_ack),					// (in )
	.sd_buff_addr(sd_buff_addr),	// (in )
	.sd_buff_dout(sd_buff_dout),	// (in )
	.sd_buff_din(sd_buff_din),		// (out)
	.sd_buff_wr(sd_buff_wr)			// (in)
);

/////////////////////////////////////////////////////////////////////////
///////////////////////////// Multiface Two /////////////////////////////
/////////////////////////////////////////////////////////////////////////

wire  [7:0] mf2_dout = (mf2_ram_en & mem_rd) ? mf2_ram_out : 8'hFF;

reg         mf2_en = 0;
reg         mf2_hidden = 0;
reg   [7:0] mf2_ram[8192];
wire        mf2_ram_en = mf2_en & cpu_addr[15:13] == 3'b001;
wire        mf2_rom_en = mf2_en & cpu_addr[15:13] == 3'b000;
reg   [4:0] mf2_pen_index;
reg   [3:0] mf2_crtc_register;
wire [12:0] mf2_store_addr;
reg  [12:0] mf2_ram_a;
reg         mf2_ram_we;
reg   [7:0] mf2_ram_in, mf2_ram_out;

always_comb begin
	casex({ cpu_addr[15:8], cpu_dout[7:6] })
		{ 8'h7f, 2'b00 }: mf2_store_addr = 13'h1fcf;  // pen index
		{ 8'h7f, 2'b01 }: mf2_store_addr = mf2_pen_index[4] ? 13'h1fdf : { 9'h1f9, mf2_pen_index[3:0] }; // border/pen color
		{ 8'h7f, 2'b10 }: mf2_store_addr = 13'h1fef; // screen mode
		{ 8'h7f, 2'b11 }: mf2_store_addr = 13'h1fff; // banking
		{ 8'hbc, 2'bXX }: mf2_store_addr = 13'h1cff; // CRTC register select
		{ 8'hbd, 2'bXX }: mf2_store_addr = { 9'h1db, mf2_crtc_register[3:0] }; // CRTC register value
		{ 8'hf7, 2'bXX }: mf2_store_addr = 13'h17ff; //8255
		{ 8'hdf, 2'bXX }: mf2_store_addr = 13'h1aac; //upper rom
		default: mf2_store_addr = 0;
	endcase
end

always @(posedge clk_sys) begin
	if (mf2_ram_we) begin
		mf2_ram[mf2_ram_a] <= mf2_ram_in;
		mf2_ram_out <= mf2_ram_in;
	end else
		mf2_ram_out <= mf2_ram[mf2_ram_a];
end

always @(posedge clk_sys) begin
	reg old_key_nmi, old_m1, old_io_wr;

	old_key_nmi <= key_nmi;
	old_m1 <= m1;
	old_io_wr <= io_wr;

	if (reset) begin
		mf2_en <= 0;
		mf2_hidden <= |status[15:14];
		NMI <= 0;
	end

	if(~old_key_nmi & key_nmi & ~mf2_en & ~status[15]) NMI <= 1;
	if (NMI & ~old_m1 & m1 & (cpu_addr == 'h66)) begin
		mf2_en <= 1;
		mf2_hidden <= 0;
		NMI <= 0;
	end
	if (mf2_en & ~old_m1 & m1 & cpu_addr == 'h65) begin
		mf2_hidden <= 1;
	end

	if (~old_io_wr & io_wr & cpu_addr[15:2] == 14'b11111110111010) begin //fee8/feea
		mf2_en <= ~cpu_addr[1] & ~mf2_hidden;
	end else if (~old_io_wr & io_wr & |mf2_store_addr[12:0]) begin //store hw register in MF2 RAM
		if (cpu_addr[15:8] == 8'h7f & cpu_dout[7:6] == 2'b00) mf2_pen_index <= cpu_dout[4:0];
		if (cpu_addr[15:8] == 8'hbc) mf2_crtc_register <= cpu_dout[3:0];
		mf2_ram_a <= mf2_store_addr;
		mf2_ram_in <= cpu_dout;
		mf2_ram_we <= 1;
	end else if (mem_wr & mf2_ram_en) begin //normal MF2 RAM write
		mf2_ram_a <= ram_a[12:0];
		mf2_ram_in <= cpu_dout;
		mf2_ram_we <= 1;
	end else begin //MF2 RAM read
		mf2_ram_a <= ram_a[12:0];
		mf2_ram_we <=0;
	end

end


/////////////////////////  KEYBOARD  /////////////////////////////////

wire ps2_int;
reg [7:0] ps2_scan;
wire [7:0] keys_s;

 io_ps2_keyboard io_ps2_keyboard
 (
		.clk			( clk_sys     ), 
		.kbd_clk		( ps2_clk_io  ), 
		.kbd_dat		( ps2_data_io ), 
		
		.interrupt	( ps2_int     ),
		.scanCode	( ps2_scan    )
	);
	
Keyboard Keyboard
(
  .Clk          ( clk_sys     ), 
  .KbdInt       ( ps2_int     ),
  .KbdScanCode  ( ps2_scan    ),
  .Keyboarddata ( ps2_key     ),
  .osd_o			 ( keys_s      )
);


/////////////////////////  MOUSE  ////////////////////////////////////

wire mouse_rd = io_rd & ~status[19];

wire [7:0] kmouse_dout;
kempston_mouse kmouse
(
	.clk_sys(clk_sys),
	.reset(reset),
	.ps2_mouse(ps2_mouse),
	.addr({cpu_addr[0], ~cpu_addr[4] & ~cpu_addr[10] & mouse_rd, cpu_addr[8]}),
	.dout(kmouse_dout)
);

wire [7:0] smouse_dout;
symbiface_mouse smouse
(
	.clk_sys(clk_sys),
	.reset(reset),
	.ps2_mouse(ps2_mouse),
	.sel((cpu_addr == 16'hFD10) & mouse_rd),
	.dout(smouse_dout)
);

wire [7:0] mmouse_dout;
multiplay_mouse mmouse
(
	.clk_sys(clk_sys),
	.reset(reset),
	.ps2_mouse(ps2_mouse),
	.sel((cpu_addr[15:4] == 12'hF99) & ~cpu_addr[3] & mouse_rd),
	.addr(cpu_addr[2:0]),
	.dout(mmouse_dout)
);

/////////////////////////////////////////////////////////////////////////

wire [15:0] cpu_addr;
wire  [7:0] cpu_dout;
wire        m1, key_nmi, NMI;
wire        io_wr, io_rd;
wire        ce_pix_fs;
wire        field;
wire  [9:0] Fn;
wire        tape_rec;

Amstrad_motherboard motherboard
(
	.reset(reset),
	.clk(clk_sys),
	.ce_4p(ce_4p),
	.ce_4n(ce_4n),
	.ce_16(ce_16),

	.ps2_key(ps2_key),
	.Fn(Fn),

	.no_wait(status[6]),
	.ppi_jumpers({2'b11, ~status[5], 1'b1}), //distributor name
	.crtc_type(1'b1),//~status[2]),
 	.resync(1),

	.joy1(status[18] ? joy2 : joy1),
	.joy2(status[18] ? joy1 : joy2),

	.tape_in(tape_play),
	.tape_out(tape_rec),
	.tape_motor(tape_motor),

	.audio_l(audio_l),
	.audio_r(audio_r),

	.pal(3'b000),//|status[13:11]),
	.ce_pix_fs(ce_pix_fs),
	.hblank(hbl),
	.vblank(vbl),
	.hsync(hs),
	.vsync(vs),
	.red(r),
	.green(g),
	.blue(b),
	.field(field),

	.vram_din(vram_dout),
	.vram_addr(vram_addr),

	.ram64k(model),
	.mem_rd(mem_rd),
	.mem_wr(mem_wr),
	.mem_addr(ram_a),
	.cpu_addr(cpu_addr),
	.cpu_dout(cpu_dout),
	.cpu_din(ram_dout & mf2_dout & fdc_dout & kmouse_dout & smouse_dout & mmouse_dout),
	.io_wr(io_wr),
	.io_rd(io_rd),
	.m1(m1),
	.nmi(NMI),

	.key_nmi(key_nmi)
);

//////////////////////////////////////////////////////////////////////

wire ce_pix = hq2x ? ce_pix_fs : ce_16;

wire [7:0] b, g, r;
wire       hs, vs, hbl, vbl;

color_mix color_mix
(
	.clk_vid(clk_sys),
	.ce_pix(ce_pix),
	.mix(3'b000),//status[13:11]),

	.HSync_in(hs),
	.VSync_in(vs),
	.HBlank_in(hbl),
	.VBlank_in(vbl),
	.B_in(b),
	.G_in(g),
	.R_in(r),

	.HSync_out(HSync),
	.VSync_out(VSync),
	.HBlank_out(HBlank),
	.VBlank_out(VBlank),
	.B_out(B),
	.G_out(G),
	.R_out(R)
);

wire [7:0] B, G, R;
wire       HSync, VSync, HBlank, VBlank;

wire [1:0] scale = 2'b00; // 00=off 01 = hq2x, 10 = 25%scanlines, 11 = 50% scanlines
wire       hq2x = (scale == 1);

reg [2:0] interlace;
always @(posedge clk_sys) begin
	reg old_vs;
	
	old_vs <= vs;
	if(~old_vs & vs) interlace <= {interlace[1:0], field};
end

video_mixer #(800) video_mixer
(
	.clk_sys			(clk_sys),
	.ce_pix			(ce_pix),
	.hq2x				(hq2x),
	.R					(R),
	.G					(G),
	.B					(B),
	.HSync			(HSync),
	.VSync			(VSync),
	.HBlank			(HBlank),
	.VBlank			(VBlank),
	.VGA_DE			(VGA_DE),


	.ce_pix_out(),

	.scanlines({scale==3, scale==2}),
	.scandoubler(1'b1),//(scale || forced_scandoubler) && !interlace),
	.mono(0),

	.VGA_R(MR),
	.VGA_G(MG),
	.VGA_B(MB),
	.VGA_VS(MVS),
	.VGA_HS(MHS)
);

wire       VGA_DE;
wire [7:0] MB, MG, MR;
wire       MHS, MVS;
wire [5:0] osd_R, osd_G, osd_B;



osd osd1
(
	
	.pclk				(clk_sys),

	.sck				(stm_b13_io),
	.ss				(stm_b12_io),
	.sdi				(stm_b15_io),

	.red_in			((VGA_DE ? MR[7:3] : 5'd0)),
	.green_in		((VGA_DE ? MG[7:3] : 5'd0)),
	.blue_in			((VGA_DE ? MB[7:3] : 5'd0)),
	.hs_in			((forced_scandoubler) ? ~MHS : ~(MVS ^ MHS)),
	.vs_in			((forced_scandoubler) ? ~MVS : 1'b1),
	
	.red_out			(vga_r_o),
	.green_out		(vga_g_o),
	.blue_out		(vga_b_o),
	.hs_out			(vga_hsync_n_o),
	.vs_out			(vga_vsync_n_o)
	
	

);


//assign vga_r_o = r[7:3];
//assign vga_g_o = g[7:3];
//assign vga_b_o = b[7:3];
//assign vga_hsync_n_o = hs;
//assign vga_vsync_n_o = vs;
//


//////////////////////////////////////////////////////////////////////

wire [7:0] audio_l, audio_r;
wire       tape_sound = 1'b1; //status[20];

sigma_delta_dac #(7) dac_l
(
	.CLK(clk_sys & ce_16),
	.RESET(reset),
	.DACin(audio_l - audio_l[7:2] + (tape_sound ? {tape_rec, tape_play, 4'd0} : 0)),
	.DACout(dac_l_o)
);

sigma_delta_dac #(7) dac_r
(
	.CLK(clk_sys & ce_16),
	.RESET(reset),
	.DACin(audio_r - audio_r[7:2] + (tape_sound ? {tape_rec, tape_play, 4'd0} : 0)),
	.DACout(dac_r_o)
);

//////////////////////////////////////////////////////////////////////

wire tape_motor;
//assign UART_TX = tape_motor;
wire tape_play = tape_read;// ^ UART_RX;

/////////////////////////////////////////////////////////////////////

endmodule
