//
// ql.v - Sinclair QL for the Multicore 2
//
// Copyright (c) 2018 Victor Trucco  
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

module ql (
   // Clocks
	input wire	clock_50_i,

	// Buttons
	input wire [4:1]	btn_n_i,

	// SRAMs (AS7C34096)
	output reg	[18:0]sram2_addr_o  = 18'b0000000000000000000,
	inout  reg	[7:0]sram2_data_io	= 8'bzzzzzzzz,
	output reg	sram2_we_n_o		= 1'b1,
	output reg	sram2_oe_n_o		= 1'b1,

	// SRAMs (AS7C34096)
	output reg	[18:0]sram3_addr_o  = 18'b0000000000000000000,
	inout  reg	[7:0]sram3_data_io	= 8'bzzzzzzzz,
	output reg	sram3_we_n_o		= 1'b1,
	output reg	sram3_oe_n_o		= 1'b1,
	
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
	inout wire	ps2_mouse_clk_io  	= 1'bz,
	inout wire	ps2_mouse_data_io 	= 1'bz,

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
	output wire	mic_o				= 1'b0,

		// VGA
	output wire	[3:0]vga_r_o,
	output wire	[3:0]vga_g_o,
	output wire	[3:0]vga_b_o,
	output wire	vga_hsync_n_o,
	output wire	vga_vsync_n_o,

		// HDMI
	output wire	[7:0]tmds_o				= 8'b00000000,

		//STM32
	input wire	stm_tx_i,
	output wire	stm_rx_o,
	output wire	stm_rst_o			= 1'bz,
		
	inout wire	stm_a15_io,
	inout wire	stm_b8_io,
	inout wire	stm_b9_io,
	input wire	stm_b12_io,
	input wire	stm_b13_io,
	output wire	stm_b14_io,
	input wire	stm_b15_io
);



// -------------------------------------------------------------------------
// ------------------------------ user_io ----------------------------------
// -------------------------------------------------------------------------

// user_io implements a connection to the io controller and receives various
// kind of user input from there (keyboard, buttons, mouse). It is also used
// by the fake SD card to exchange data with the real sd card connected to the
// io controller

// the configuration string is returned to the io controller to allow
// it to control the menu on the OSD 
/*parameter CONF_STR = {
        "QL;;",
        "F1,MDV;",
        "O2,MDV direction,normal,reverse;",
        "O3,RAM,128k,640k;",
        "O4,Video mode,PAL,NTSC;",
        "O5,Scanlines,Off,On;",
        "T6,Reset"
};

parameter CONF_STR_LEN = 4+7+32+17+23+20+8;
*/

parameter STRLEN = 8;
parameter CONF_STR = {"P,ql.rom"};

wire [15:0] status;

//reg [7:0] status = 8'b00000000;
//status[0] = reset
//status[1] = 
//status[2] = MDV direction, 0 normal, 1 reverse;",
//status[3] = RAM, 0 = 128k 1 = 640k",
//status[4] = Video mode, 0 = PAL, 1 = NTSC;",
//status[5] = Scanlines, 0 = Off, 1 = On",
//status[6] = Reset
//status[7] = 



wire tv15khz = 1'b0;
wire [1:0] buttons;

wire [7:0] js0, js1;

wire ps2_kbd_clk, ps2_kbd_data;
wire ps2_mouse_clk, ps2_mouse_data;

// generate ps2_clock
wire ps2_clock = ps2_clk_div[6];  // ~20khz
reg [6:0] ps2_clk_div;
always @(posedge clk2)
	ps2_clk_div <= ps2_clk_div + 7'd1;

	/*
// include user_io module for arm controller communication
user_io #(.STRLEN(STRLEN)) user_io ( 
      .conf_str       ( CONF_STR       ),

      .SPI_CLK        ( SPI_SCK        ),
      .SPI_SS_IO      ( CONF_DATA0     ),
      .SPI_MISO       ( SPI_DO         ),
      .SPI_MOSI       ( SPI_DI         ),

//		.scandoubler_disable ( tv15khz   ),
		.buttons        ( buttons        ),

		.joystick_0     ( js0            ),
		.joystick_1     ( js1            ),
		
      // ps2 interface
      .ps2_clk        ( ps2_clock      ),
      .ps2_kbd_clk    ( ps2_kbd_clk    ),
      .ps2_kbd_data   ( ps2_kbd_data   ),
      .ps2_mouse_clk  ( ps2_mouse_clk  ),
      .ps2_mouse_data ( ps2_mouse_data ),

      .status         ( status         ),
		
		// interface to embedded legacy sd card wrapper
		.sd_lba     	( sd_lba				),
		.sd_rd      	( sd_rd				),
		.sd_wr      	( sd_wr				),
		.sd_ack     	( sd_ack				),
		.sd_conf    	( sd_conf			),
		.sd_sdhc    	( sd_sdhc			),
		.sd_dout    	( sd_dout			),
		.sd_dout_strobe (sd_dout_strobe	),
		.sd_din     	( sd_din				),
		.sd_din_strobe ( sd_din_strobe	)
);
*/
// -------------------------------------------------------------------------
// ---------------- fake sd card for use with ql-sd ------------------------
// -------------------------------------------------------------------------

// conections between user_io (implementing the SPIU communication 
// to the io controller) and the legacy 
wire [31:0] sd_lba;
wire sd_rd;
wire sd_wr;
wire sd_ack;
wire sd_conf;
wire sd_sdhc; 
wire [7:0] sd_dout;
wire sd_dout_strobe;
wire [7:0] sd_din;
wire sd_din_strobe;

/*
sd_card sd_card (
		// connection to io controller
		.io_lba 			( sd_lba 			),
		.io_rd  			( sd_rd				),
		.io_wr  			( sd_wr				),
		.io_ack 			( sd_ack				),
		.io_conf 		( sd_conf			),
		.io_sdhc 		( sd_sdhc			),
		.io_din 			( sd_dout			),
		.io_din_strobe ( sd_dout_strobe	),
		.io_dout 		( sd_din				),
		.io_dout_strobe( sd_din_strobe	),
 
		.allow_sdhc 	( 1'b1				),   // QLSD supports SDHC

		// connection to local CPU
		.sd_cs   		( sd_cs         	),
		.sd_sck  		( sd_sck				),
		.sd_sdi  		( sd_sdi				),
		.sd_sdo  		( sd_sdo 	    	)
);
*/

wire qlsd_rd = cpu_rom && (cpu_addr[15:0] == 16'hfee4);  // only one register actually returns data
wire [7:0] qlsd_dout;
wire sd_cs, sd_sck, sd_sdi, sd_sdo;


/* NAO ESQUECER DISSO!!!!
qlromext qlromext (
		.clk				( clk21 ),//clock_50_i		),   // fastest we can offer
		.clk_bus       ( clk2            ),
		.romoel        ( !(cpu_rom && cpu_cycle) ),
		.a       		( cpu_addr[15:0]	),
		.d             ( qlsd_dout       ), //output
		.io2           ( 1'b0            ),		
		
		.sd_di         ( sd_mosi_o   ),
		.sd_clk        ( sd_sclk_o   ),
		.sd_cs1l       ( sd_cs_n_o   ),
		.sd_do        	( sd_miso_i   )
		
	
	//	.sd_do         ( sd_sdo          ),
	//	.sd_cs1l       ( sd_cs           ),
	//	.sd_clk        ( sd_sck          ),
	//	.sd_di         ( sd_sdi          ),
		

); 
	*/		
// -------------------------------------------------------------------------
// ---------------- interface to the external sdram ------------------------
// -------------------------------------------------------------------------

// SDRAM control signals
assign sdram_cke_o = 1'b1;

// CPU and data_io share the same bus cycle. Thus the CPU cannot run while
// (ROM) data is being downloaded which wouldn't make any sense, anyway
// during ROM download data_io writes the ram. Otherwise the CPU
wire [24:0] sys_addr = dio_download?dio_addr[24:0]:{ 6'b000000, cpu_addr[19:1]};
wire [1:0] sys_ds =    dio_download?2'b11:~cpu_ds;
wire [15:0] sys_dout = dio_download?dio_data:cpu_dout;
wire sys_wr =          dio_download?dio_write:(cpu_wr && cpu_ram);
wire sys_oe =          dio_download?1'b0:(cpu_rd && cpu_mem);

// microdrive emulation and video share the video cycle time slot
wire [24:0] video_cycle_addr = mdv_read?mdv_addr:{6'd0, video_addr};
wire video_cycle_rd = mdv_read?1'b1:video_rd;

// video and CPU/data_io time share the sdram bus
wire [24:0] sdram_addr = video_cycle?video_cycle_addr:sys_addr;
wire sdram_wr = video_cycle?1'b0:sys_wr;
wire sdram_oe = video_cycle?video_cycle_rd:sys_oe;
wire [1:0] sdram_ds = video_cycle?2'b11:sys_ds;
wire [15:0] sdram_din = sys_dout;

/*
wire [15:0] sdram_dout;
sdram sdram (
   // interface to the SDRAM IC
   .sd_data        ( sdram_da_io ),
   .sd_addr        ( sdram_ad_o  ),
   .sd_dqm         ( sdram_dqm_o ),
   .sd_cs          ( sdram_cs_o  ),
   .sd_ba          ( sdram_ba_o  ),
   .sd_we          ( sdram_we_o  ),
   .sd_ras         ( sdram_ras_o ),
   .sd_cas         ( sdram_cas_o ),

   // system interface
   .clk            ( clk21       ),
   .clkref         ( clk2        ),
   .init           ( !pll_locked ),

   // cpu interface
   .din            ( sdram_din   ),
   .addr           ( sdram_addr  ),
   .we             ( sdram_wr    ),
   .oe             ( sdram_oe    ),
   .ds             ( sdram_ds    ),
   .dout           ( sdram_dout  )
);
*/

/*
reg [15:0] sdram_dout;
assign sram2_addr_o  = sdram_addr[18:0];
assign sram2_we_n_o  = ~(sdram_wr && sdram_ds[1]);
assign sram2_oe_n_o	= ~(sdram_oe && sdram_ds[1]);
assign sram2_data_io = (sdram_wr && sdram_ds[1])?sdram_din[15:8] : 8'bzzzzzzzz;

assign sram3_addr_o  = sdram_addr[18:0];
assign sram3_we_n_o  = ~(sdram_wr && sdram_ds[0]);
assign sram3_oe_n_o	= ~(sdram_oe && sdram_ds[0]);
assign sram3_data_io = (sdram_wr && sdram_ds[0])?sdram_din[7:0] : 8'bzzzzzzzz;
		
//assign sdram_dout = {sram2_data_io, sram3_data_io};

always @*  
begin
			if (sdram_oe && sdram_ds[1] )
				sdram_dout[15:8] = sram2_data_io;
				
			if (sdram_oe && sdram_ds[0] )
				sdram_dout[7:0] = sram3_data_io;
				
end
*/

wire [15:0] sdram_dout;

always @(negedge clk2)  //negedge clk2 its ok for downloading
begin

	sram2_addr_o  <= sdram_addr[18:0];
	sram3_addr_o  <= sdram_addr[18:0];

	if (sdram_wr && sdram_ds[1])
		begin
			sram2_data_io <= sdram_din[15:8];
			sram2_we_n_o <= 1'b0; 
		end
		else
		begin
			sram2_data_io <= 8'bzzzzzzzz;
			sram2_we_n_o <= 1'b1;
		end

	if (sdram_wr && sdram_ds[0])
		begin
			sram3_data_io <= sdram_din[7:0];
			sram3_we_n_o <= 1'b0; 
		end
		else
		begin
			sram3_data_io <= 8'bzzzzzzzz;
			sram3_we_n_o <= 1'b1;
		end

  if (sdram_oe && sdram_ds[1]) sram2_oe_n_o <= 1'b0; else sram2_oe_n_o <= 1'b1; 
  if (sdram_oe && sdram_ds[0]) sram3_oe_n_o <= 1'b0; else sram3_oe_n_o <= 1'b1; 

end

assign sdram_dout = {sram2_data_io, sram3_data_io};

// ---------------------------------------------------------------------------------
// ------------------------------------- data io -----------------------------------
// ---------------------------------------------------------------------------------

wire dio_download;
wire [4:0] dio_index;
wire [24:0] dio_addr;
wire [15:0] dio_data;
wire dio_write;

// include ROM download helper
// this receives a byte stream from the arm io controller via spi and 
// writes it into sdram
data_io data_io (
   // io controller spi interface
   //.sck ( SPI_SCK ),
   //.ss  ( SPI_SS2 ),
   //.sdi ( SPI_DI  ),
	
	.sdi        ( stm_b15_io ),
   .sck        ( stm_b13_io ),
   .ss         ( stm_b12_io ),

   .downloading ( dio_download ),  // signal indicating an active rom download
	.index       ( dio_index ),
  
   // external ram interface
   .clk   ( cpu_cycle ),
   .wr    ( dio_write ),
   .addr  ( dio_addr  ),
   .data  ( dio_data  )
);
                   
// ---------------------------------------------------------------------------------
// -------------------------------------- video ------------------------------------
// ---------------------------------------------------------------------------------

wire [5:0] video_r, video_g, video_b;
wire video_hs, video_vs;

wire [18:0] video_addr;
wire video_rd;

// the zx8301 has only one write-only register at $18063
wire zx8301_cs = cpu_cycle && cpu_io && 
	({cpu_addr[6:5], cpu_addr[1]} == 3'b111)&& cpu_wr && !cpu_ds[0];

zx8301 zx8301 (
    .reset        ( reset       ),
 	 .clk_vga		( clk21       ),
	 .clk_video		( clk10       ),
	 .video_cycle  ( video_cycle ),

	 .ntsc         ( status[4]   ),
	 .scandoubler  ( !tv15khz    ),
	 .scanlines    ( 1'b0 ), //status[5]   ),

	 .clk_bus      ( clk2     ),
	 .cpu_cs       ( zx8301_cs     ),
	 .cpu_data     ( cpu_dout[7:0] ),

	 .mdv_men      ( mdv_men       ),
	 
	 .addr         ( video_addr    ),
	 .din          ( sdram_dout    ),
	 .rd           ( video_rd      ),
	 
	 .hs           ( video_hs      ),
	 .vs           ( video_vs      ),
	 .r            ( video_r       ),
	 .g            ( video_g       ),
	 .b            ( video_b       )
);


// csync for tv15khz
// QLs vsync is positive, QLs hsync is negative
wire vga_csync = !(!vga_hsync ^ vga_vsync);
wire vga_hsync, vga_vsync;

// TV SCART has csync on hsync pin and "high" on vsync pin
assign vga_vsync_n_o = tv15khz?1'b1:vga_vsync;
assign vga_hsync_n_o = tv15khz?vga_csync:vga_hsync;

// tv15hkz has half the pixel rate		  
wire osd_clk = tv15khz?clk10:clk21;

wire [4:0] vga_r_s, vga_g_s, vga_b_s;


// include the on screen display
osd #(	.STRLEN 			( STRLEN ),
			.OSD_COLOR 		( 3'b001 ), //RGB
			.OSD_X_OFFSET 	( 10'd18 ),
			.OSD_Y_OFFSET 	( 10'd15 )
	) 
	osd (
   .pclk       ( osd_clk     ),
			
   // spi for OSD
   .sdi        ( stm_b15_io   ),
   .sck        ( stm_b13_io   ),
   .ss         ( stm_b12_io   ),
	.sdo        ( stm_b14_io   ),

   .red_in     ( video_r[5:1] ),
   .green_in   ( video_g[5:1] ),
   .blue_in    ( video_b[5:1] ),
   .hs_in      ( video_hs     ),
   .vs_in      ( video_vs     ),

   .red_out    ( vga_r_s      ),
   .green_out  ( vga_g_s      ),
   .blue_out   ( vga_b_s      ),
   .hs_out     ( vga_hsync    ),
   .vs_out     ( vga_vsync    ),
	
	.data_in		( keys_s & osd_start_s ), //combine the start CMD and the keyboard CMD
	.conf_str	( CONF_STR		)
			
);

// ---------------------------------------------------------------------------------
// -------------------------------------- reset ------------------------------------
// ---------------------------------------------------------------------------------

wire rom_download = dio_download && (dio_index == 0);
reg [11:0] reset_cnt;
wire reset = (reset_cnt != 0);
always @(posedge clk2) begin
	if(buttons[1] || status[0] || !host_reset_n || !pll_locked || rom_download || !btn_n_i[1])
		reset_cnt <= 12'hfff;
	else if(reset_cnt != 0)
		reset_cnt <= reset_cnt - 1;
end

// ---------------------------------------------------------------------------------
// --------------------------------------- IO --------------------------------------
// ---------------------------------------------------------------------------------

wire zx8302_sel = cpu_cycle && cpu_io && !cpu_addr[6];
wire [1:0] zx8302_addr = {cpu_addr[5], cpu_addr[1]};
wire [15:0] zx8302_dout;

wire mdv_download = (dio_index == 1) && dio_download;
wire mdv_men;
wire mdv_read;
wire [24:0] mdv_addr;

wire audio;
assign dac_l_o = audio;
assign dac_r_o = audio;

zx8302 zx8302 (
	.reset        ( reset        ),
	.init         ( !pll_locked  ),
	.clk_sys      ( clock_50_i  ), //to a internal PLL
	.clk          ( clk21        ),

	.xint         ( qimi_irq     ),
	.ipl          ( cpu_ipl      ),
	.led          ( ), //LED          ),
	.audio        ( audio        ),
	
	// CPU connection
	.clk_bus      ( clk2         ),
	.cpu_sel      ( zx8302_sel   ),
	.cpu_wr       ( cpu_wr       ),
	.cpu_addr     ( zx8302_addr  ),
	.cpu_ds       ( cpu_ds       ),
	.cpu_din      ( cpu_dout     ),
   .cpu_dout     ( zx8302_dout  ),

	// joysticks 
	.js0          ( js0[4:0]     ),
	.js1          ( js1[4:0]     ),
	
	.ps2_kbd_clk  ( ps2_clk_io   ), 
	.ps2_kbd_data ( ps2_data_io  ), 
	.keys_o		  ( keys_s		  ),
	
	.vs           ( video_vs     ),

	// microdrive sdram interface
	.mdv_addr     ( mdv_addr     ),
	.mdv_din      ( sdram_dout   ),
	.mdv_read     ( mdv_read     ),
	.mdv_men      ( mdv_men      ),
	.video_cycle  ( video_cycle  ),
	
	.mdv_reverse  ( status[2]    ),

	.mdv_download ( mdv_download ),
	.mdv_dl_addr  ( dio_addr     )
);
	 
// ---------------------------------------------------------------------------------
// --------------------------- QIMI compatible mouse -------------------------------
// ---------------------------------------------------------------------------------

// qimi is at 1bfxx
wire qimi_sel = cpu_io && (cpu_addr[13:8] == 6'b111111);
wire [7:0] qimi_data;
wire qimi_irq;
	
qimi qimi(
   .reset     ( reset          ),
	.clk       ( clk2           ),

	.cpu_sel   ( qimi_sel       ),
	.cpu_addr  ( { cpu_addr[5], cpu_addr[1] } ),
	.cpu_data  ( qimi_data      ),
	.irq       ( qimi_irq       ),
	
	.ps2_clk   ( ps2_mouse_clk_io  ), // ps2_mouse_clk  ),
	.ps2_data  ( ps2_mouse_data_io ) //ps2_mouse_data )
);

// ---------------------------------------------------------------------------------
// -------------------------------------- CPU --------------------------------------
// ---------------------------------------------------------------------------------

// address decoding
wire cpu_act = cpu_rd || cpu_wr;
wire cpu_io   = cpu_act && ({cpu_addr[19:14], 2'b00} == 8'h18);   // internal IO $18000-$1bffff
wire cpu_bram = cpu_act &&(cpu_addr[19:17] == 3'b001);           	// 128k RAM at $20000
wire cpu_xram = cpu_act && status[3] && ((cpu_addr[19:18] == 2'b01) ||
							(cpu_addr[19:18] == 2'b10));      				// 512k RAM at $40000 if enabled
wire cpu_ram = cpu_bram || cpu_xram;                   				// any RAM
wire cpu_rom  = cpu_act && (cpu_addr[19:16] == 4'h0);             // 64k ROM at $0
wire cpu_mem  = cpu_ram || cpu_rom;                    				// any memory mapped to sdram

wire [15:0] io_dout = 
	qimi_sel?{qimi_data, qimi_data}:
	(!cpu_addr[6])?zx8302_dout:
	16'h0000;	

// demultiplex the various data sources
wire [15:0] cpu_din =
	qlsd_rd?{qlsd_dout, qlsd_dout}:    // qlsd maps into rom area
	cpu_mem?sdram_dout:
	cpu_io?io_dout:
	16'hffff;

wire [31:0] cpu_addr;
wire [1:0] cpu_ds;
wire [15:0] cpu_dout;
wire [1:0] cpu_ipl;
wire cpu_rw;
wire [1:0] cpu_busstate;
wire cpu_rd = (cpu_busstate == 2'b00) || (cpu_busstate == 2'b10);
wire cpu_wr = (cpu_busstate == 2'b11) && !cpu_rw;
wire cpu_idle = (cpu_busstate == 2'b01);

reg cpu_enable;
always @(negedge clk2)
	cpu_enable <= (cpu_cycle && !dio_download) || cpu_idle;

TG68KdotC_Kernel #(0,0,0,0,0,0) tg68k (
        .clk            ( clk2      ),
        .nReset         ( ~reset         ),
        .clkena_in      ( cpu_enable     ), 
        .data_in        ( cpu_din        ),
        .IPL            ( {cpu_ipl[0], cpu_ipl }),  // ipl 0 and 2 are tied together on 68008
        .IPL_autovector ( 1'b1           ),
        .berr           ( 1'b0           ),
        .clr_berr       ( 1'b0           ),
        .CPU            ( 2'b00          ),   // 00=68000
		  .addr           ( cpu_addr       ),
        .data_write     ( cpu_dout       ),
        .nUDS           ( cpu_ds[1]      ),
        .nLDS           ( cpu_ds[0]      ),
        .nWr            ( cpu_rw         ),
        .busstate       ( cpu_busstate   ), // 00-> fetch code 10->read data 11->write data 01->no memaccess
        .nResetOut      (                ),
        .FC             (                )
);

// -------------------------------------------------------------------------
// -------------------------- clock generation -----------------------------
// -------------------------------------------------------------------------
					

wire clk21;
reg clk10 = 1'b0; // 10.5 MHz QL pixel clock
reg clk5 = 1'b0;  // 5.25 MHz CPU clock
reg clk2 = 1'b0;  // 2.625 MHz bus clock

/*
always @(posedge clk21)
	clk10 <= !clk10;


always @(posedge clk10)
	clk5 <= !clk5;


always @(posedge clk5)
	clk2 <= !clk2;
*/	
	
reg [2:0] clock_div = 0;	
always @(posedge clk21)
begin

	clock_div = clock_div + 1;	
	
	clk10 <= clock_div[0];
	clk5 <= 	clock_div[1];
	clk2 <= 	clock_div[2];

end

// CPU and Video share the bus
reg video_cycle = 1'b0;
wire cpu_cycle = !video_cycle;

always @(posedge clk2)
	video_cycle <= !video_cycle;

wire pll_locked, clk_ctrl;
	
// A PLL to derive the system clock 
pll pll (
	 .inclk0( clock_50_i ),
	 .c0(  clk21         ),       // 21.000 MHz
	 .c1(  sdram_clk_o   ),       // 21.000 MHz phase shifted
	 
	 .c2( clk_ctrl       ),
	 .locked( pll_locked )
);

//-----------------------------------------------------------
// 
// start the microcontroller OSD after the power on
//

reg stm_rst_s = 1'bz;
reg power_on_reset = 1'b1;
reg [7:0] osd_start_s = 8'b11111111;
wire [7:0] keys_s;
reg [24:0] power_on_s = 25'd21000000;
wire reset_n = btn_n_i[2];

reg [1:0] edge_s = 2'b00;


always @(posedge clk21) 
begin

		if (reset_n == 1'b0) 
			begin
				power_on_s <= 25'd21000000;
				stm_rst_s <= 1'bz; // release the microcontroller reset line
				osd_start_s <= 8'b11111111;
				power_on_reset <= 1'b1;
			end
		else if (power_on_s == 25'd10) 
			osd_start_s <=  8'b00111111; // CMD 0x01 - send the ROM
		else if (power_on_s == 25'b0) 
			power_on_reset <= 1'b0;
	
		
		if (power_on_s != 25'b0)
			power_on_s <= power_on_s - 1;
		
		
		if (rom_download == 1'b1 && osd_start_s == 8'b00111111 )
			osd_start_s <= 8'b11111111;
		
		
		edge_s <= {edge_s[0], rom_download};
		
		//if (edge_s == 2'b10) 	stm_rst_s <= 1'b0; // hold the microcontroller on reset, to free the SD card

end



assign stm_rst_o = stm_rst_s;	


//assign sram2_we_n_o = 1'b1;
//assign sram2_oe_n_o = 1'b1;


//assign vga_r_o = vga_r_s;		
//assign vga_g_o = vga_g_s;		
//assign vga_b_o = vga_b_s;		

assign vga_r_o = vga_r_osd[7:4];		
assign vga_g_o = vga_g_osd[7:4];		
assign vga_b_o = vga_b_osd[7:4];	


// LOADER -----------------------------------
		
		 wire osd_window;
  wire osd_pixel;
  wire [15:0] dipswitches;
	
  wire host_reset_n;
  wire host_reset_loader;
  wire host_divert_sdcard;
  wire host_divert_keyboard;
  wire host_select;
  wire host_start;
 
  wire [31:0] bootdata;
  wire bootdata_req;
  reg bootdata_ack = 1'b0;
  
  wire [31:0] rom_size;
  
  wire [7:0] vga_r_osd;
  wire [7:0] vga_g_osd;
  wire [7:0] vga_b_osd;
  
  
	CtrlModule control 
	(
			.clk(clk_ctrl), 
			.reset_n( btn_n_i[4] ), 
			
			.vga_hsync(video_hs), 
			.vga_vsync(video_vs), 
			.osd_window(osd_window), 
			.osd_pixel(osd_pixel), 
			
			.ps2k_clk_in( ps2_clk_io ), 
			.ps2k_dat_in( ps2_data_io ),
			
			.spi_miso( sd_miso_i ), 
			.spi_mosi( sd_mosi_o ), 
			.spi_clk( sd_sclk_o ), 
			.spi_cs( sd_cs_n_o ), 
			
			.dipswitches(status), 
			.size(rom_size), 
			.joy_pins({~(btn_n_i[4] || btn_n_i[3]), ~joy1_up_i, ~joy1_down_i, ~joy1_left_i, ~joy1_right_i, ~joy1_p6_i}), 
			
			.host_divert_sdcard(host_divert_sdcard), 
			.host_divert_keyboard(host_divert_keyboard), 
			.host_reset_n(host_reset_n), 
			.host_select(host_select), 
			.host_start(host_start),
			.host_reset_loader(host_reset_loader),
			.host_bootdata(bootdata), 
			.host_bootdata_req(bootdata_req), 
			.host_bootdata_ack(bootdata_ack)
	);
	
	OSD_Overlay osd_overlay 
	(
			.clk(clk_ctrl),
			.red_in({video_r, 2'b00}),
			.green_in({video_g, 2'b00}),
			.blue_in({video_b, 2'b00}),
			.window_in(1'b1),
			.hsync_in(video_hs),
			
			.osd_window_in(osd_window),
			.osd_pixel_in(osd_pixel),
			.red_out(vga_r_osd),
			.green_out(vga_g_osd),
			.blue_out(vga_b_osd),
			.window_out(),
			.scanline_ena(status[5])
	);		
		
	reg write_fifo;
	reg read_fifo;
	wire full_fifo;
	reg skip_fifo = 1'b0;
	wire [7:0] dout_fifo;
	reg [31:0] bytesloaded;
	reg boot_state;

	always@( posedge clk_ctrl )
	begin
		if (host_reset_loader == 1'b1) begin
			bootdata_ack <= 1'b0;
			boot_state <= 1'b0;
			write_fifo <= 1'b0;
			read_fifo <= 1'b0;
			skip_fifo <= 1'b0;
			bytesloaded <= 32'h00000000;
		end else begin
			if (dout_fifo == 8'h4E) skip_fifo <= 1'b1;

			case (boot_state)
			
				1'b0:
					if (bootdata_req == 1'b1) 
					begin
					
						if (1)//full_fifo == 1'b0) 
						begin
							boot_state <= 1'b1;
							bootdata_ack <= 1'b1;
							write_fifo <= (bytesloaded < rom_size) ? 1'b1 : 1'b0;
						end 
						else 
							read_fifo <= 1'b1;
						
					end 
					else 
					begin
						bootdata_ack <= 1'b0;
					end
						
				1'b1: 
					begin
						if (1)//write_fifo == 1'b1) 
						begin
							write_fifo <= 1'b0;
							bytesloaded <= bytesloaded + 4;
						end
						boot_state <= 1'b0;
						bootdata_ack <= 1'b0;
					end
			endcase;
		end
	end
	/*
	always @(posedge clk_ctrl)	
	begin
			if (reset_n == 1'b0) 
			begin		
				boot_req <='0';
				
				romwr_req <= '0';
				romwr_a <= to_unsigned(0, addrwidth);
				bootState<=BOOT_READ_1;
			end	
			else
			begin
				case (bootState)
					when BOOT_READ_1 =>
						boot_req<='1';
						if boot_ack='1' then
							boot_req<='0';
							bootState <= BOOT_WRITE_1;
						end if;
						if host_bootdone='1' then
							boot_req<='0';
							bootState <= BOOT_DONE;
						end if;
					when BOOT_WRITE_1 =>
						if BITFLIP = '1' then
							romwr_d <=
								FL_DQ(8)
								& FL_DQ(9)
								& FL_DQ(10)
								& FL_DQ(11)
								& FL_DQ(12)
								& FL_DQ(13)
								& FL_DQ(14)
								& FL_DQ(15)
								& FL_DQ(0)
								& FL_DQ(1)
								& FL_DQ(2)
								& FL_DQ(3)
								& FL_DQ(4)
								& FL_DQ(5)
								& FL_DQ(6)
								& FL_DQ(7);
						else
							romwr_d <= FL_DQ;
						end if;
						
						romwr_req <= not romwr_req;
						bootState <= BOOT_WRITE_2;
					when BOOT_WRITE_2 =>
						if romwr_req = romwr_ack then
							romwr_a <= romwr_a + 1;
							bootState <= BOOT_READ_1;
						end if;
					when BOOT_REL =>
						if CPU_CLKRST = '1' then
							bootState <= BOOT_DONE;
						end if;
					when others => null;
				end case;	
			end
	end
		*/
		
//-----------------------------------------------------------
// 
// DEBUG
//		

/*
debug_info #(100,100) debug_info (
        .clk_i    ( osd_clk   ),
		  
        .r_i      ( vga_r_s   ),
        .g_i      ( vga_g_s   ), 
        .b_i      ( vga_b_s   ),
        .hSync_i  ( vga_hsync ), 
        .vSync_i  ( vga_vsync ),
		  
        .r_o      ( vga_r_o   ),
        .g_o      ( vga_g_o   ),
        .b_o      ( vga_b_o   ), 
		  
		  .dbg1_s   ( cpu_addr[31:24] ),
        .dbg2_s   ( cpu_addr[23:16] ),
        .dbg3_s   ( cpu_addr[15:8]  ),
        .dbg4_s   ( cpu_addr[7:0]   ),
		  
        .dbg5_s   ( {7'd0,mdv_download} ),
        .dbg6_s   ( dio_addr[23:16] ),
        .dbg7_s   ( dio_addr[15:8]  ),
        .dbg8_s   ( dio_addr[7:0]   ),
		  
        .dbg9_s   ( {7'd0,dio_write}),
        .dbg10_s  ( {3'b000, dio_index} ),
        .dbg11_s  ( dio_data[15:8]  ),
        .dbg12_s  ( dio_data[7:0]   )
);		

*/
		
endmodule
