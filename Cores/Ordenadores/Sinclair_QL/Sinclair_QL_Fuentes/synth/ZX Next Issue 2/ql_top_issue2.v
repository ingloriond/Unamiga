//
// Sinclair QL for the ZX Spectrum Next - Issue 2
//
// Copyright (c) 2020 Victor Trucco  
//
// original MiST Port
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
      input  wire clock_50_i,

      //SRAM (AS7C34096)
      output reg [18:0] ram_addr_o,
      inout  wire [15:0] ram_data_io,
      output reg ram_oe_n_o,
      output reg ram_we_n_o,
      output reg [3:0] ram_ce_n_o,

     // PS2
      inout wire ps2_clk_io,
      inout wire ps2_data_io,
      inout wire ps2_pin6_io,
      inout wire ps2_pin2_io,
                            
      // SD Card
      output wire sd_cs0_n_o,
      output wire sd_cs1_n_o,
      output wire sd_sclk_o,
      output wire sd_mosi_o,
      input  wire sd_miso_i,

      // Flash
      output wire flash_cs_n_o,
      output wire flash_sclk_o,
      output wire flash_mosi_o,
      input  wire flash_miso_i,
      output wire flash_wp_o,
      output wire flash_hold_o,

      // Joystick
      input  wire joyp1_i,
      input  wire joyp2_i,
      input  wire joyp3_i,
      input  wire joyp4_i,
      input  wire joyp6_i,
      output wire joyp7_o,
      input  wire joyp9_i,
      output wire joysel_o,

      // Audio
      output wire audioext_l_o,
      output wire audioext_r_o,
      output wire audioint_o,

      // K7
      output wire ear_port_i,
      input  wire mic_port_o,

      // Buttons
      input  wire btn_divmmc_n_i,
      input  wire btn_multiface_n_i,
      input  wire btn_reset_n_i,

      // Matrix keyboard
      output wire [7:0] keyb_row_o,
      input  wire [6:0] keyb_col_i,

      // Bus
      inout  wire bus_rst_n_io,
      output wire bus_clk35_o,
      output wire [15:0] bus_addr_o,
      inout  wire [7:0] bus_data_io,
      inout  wire bus_int_n_io,
      input  wire bus_nmi_n_i,
      input  wire bus_ramcs_i,
      input  wire bus_romcs_i,
      input  wire bus_wait_n_i,
      output wire bus_halt_n_o,
      output wire bus_iorq_n_o,
      output wire bus_m1_n_o,
      output wire bus_mreq_n_o,
      output wire bus_rd_n_o,
      output wire bus_wr_n_o,
      output wire bus_rfsh_n_o,
      input  wire bus_busreq_n_i,
      output wire bus_busack_n_o,
      input  wire bus_iorqula_n_i,

      // VGA
      output wire [2:0] rgb_r_o,
      output wire [2:0] rgb_g_o,
      output wire [2:0] rgb_b_o,
      output wire hsync_o,
      output wire vsync_o,
      output wire csync_o,

      // HDMI
      output wire [3:0] hdmi_p_o,
      output wire [3:0] hdmi_n_o,

      // I2C (RTC and HDMI)
      inout  wire i2c_scl_io,
      inout  wire i2c_sda_io,

      // ESP
      inout  wire esp_gpio0_io,
      inout  wire esp_gpio2_io,
      input  wire esp_rx_i,
      output wire esp_tx_o,

      // PI GPIO
      inout  wire [27:0] accel_io,

      // Vacant pins
      inout  wire extras_io
	  
 
);

// -------------------------------------------------------------------------
// -------------------------- clock generation -----------------------------
// -------------------------------------------------------------------------

wire pll_locked, clk11, clk84, clk21, clk21_p;

BUFG  BUFG_inst21 (.I (clk21_p), .O (clk21));

pll pll
(
	.CLK_IN1   ( clock_50_i ),
	.CLK_OUT1  ( clk21_p ),            
	.CLK_OUT2  ( clk84 ),  	  
	.CLK_OUT3  ( clk11 ),    
	.LOCKED    ( pll_locked )
);					

//reg clk10 = 1'b0; // 10.5 MHz QL pixel clock
//reg clk5 = 1'b0;  // 5.25 MHz CPU clock
//reg clk2 = 1'b0;  // 2.625 MHz bus clock

reg [2:0] clock_div = 0;	
always @(posedge clk21)
begin

	clock_div = clock_div + 3'd1;	
	
//	clk10 <= clock_div[0];
//	clk5 <= 	clock_div[1];
//	clk2 <= 	clock_div[2];

end

wire clk10, clk5, clk2;
BUFG  BUFG_inst0 (.I (clock_div[0]), .O (clk10));
BUFG  BUFG_inst1 (.I (clock_div[1]), .O (clk5));
BUFG  BUFG_inst2 (.I (clock_div[2]), .O (clk2));


/*	
always @(posedge clk21)
	clk10 <= !clk10;

always @(posedge clk10)
	clk5 <= !clk5;

always @(posedge clk5)
	clk2 <= !clk2;
*/

wire ps2_kbd_clk, ps2_kbd_data;
wire ps2_mouse_clk, ps2_mouse_data;

// generate ps2_clock
wire ps2_clock = ps2_clk_div[6];  // ~20khz
reg [6:0] ps2_clk_div;
always @(posedge clk2)
	ps2_clk_div <= ps2_clk_div + 7'd1;

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

wire [7:0] js0, js1;

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
// ---------------- interface to the external ram ------------------------
// -------------------------------------------------------------------------



// CPU and data_io share the same bus cycle. Thus the CPU cannot run while
// (ROM) data is being downloaded which wouldn't make any sense, anyway
// during ROM download data_io writes the ram. Otherwise the CPU
wire [24:0] sys_addr = dio_download ? dio_addr  : { 6'b000000, cpu_addr[19:1]};
wire [1:0]  sys_ds   = dio_download ? 2'b11     : ~cpu_ds;
wire [15:0] sys_dout = dio_download ? dio_data  : cpu_dout;
wire        sys_wr   = dio_download ? dio_write : (cpu_wr && cpu_ram);
wire        sys_oe   = dio_download ? 1'b0      : (cpu_rd && cpu_mem);

// microdrive emulation and video share the video cycle time slot
wire [24:0] video_cycle_addr = mdv_read ? mdv_addr : {6'd0, video_addr};
wire        video_cycle_rd   = mdv_read ? 1'b1     : video_rd;

// video and CPU/data_io time share the sdram bus
wire [24:0] sdram_addr = video_cycle ? video_cycle_addr : sys_addr;
wire        sdram_wr   = video_cycle ? 1'b0             : sys_wr;
wire        sdram_oe   = video_cycle ? video_cycle_rd   : sys_oe;
wire [1:0]  sdram_ds   = video_cycle ? 2'b11            : sys_ds;
wire [15:0] sdram_din  = sys_dout;

wire [15:0] sdram_dout;
reg  [15:0] ram_dout;

/*
- wr as vezes pula o 0x800. nao é problema no CE,nem float, logo so pode ser no WR
- mesmo colocando dio_addr e dio_write direto nos pinos, o endereço 0x800 é pulado 
*/


always @(negedge clk2)  //negedge clk2 
begin
	ram_addr_o <= sdram_addr[18:0];
	ram_dout   <= sdram_din; 
	ram_we_n_o <= ~(sdram_wr);	
	
	//OE e CE ficam melhor se "contraldos" 
	ram_oe_n_o <= ~sdram_oe; //funciona melhor aqui
	ram_ce_n_o <= { 2'b11, ~sdram_ds[1], ~sdram_ds[0] }; //funciona melhor aqui

	// ativos direto não ficam bons
	//ram_oe_n_o <= 1'b0; 
	//ram_ce_n_o <= 4'b1100;
end

assign sdram_dout = ram_data_io;
assign ram_data_io = (ram_we_n_o) ? 16'hZZZZ : ram_dout;


// ---------------------------------------------------------------------------------
// ------------------------------------- data io -----------------------------------
// ---------------------------------------------------------------------------------

reg dio_download;
reg [4:0] dio_index;
reg [24:0] dio_addr;
reg [15:0] dio_data;
reg dio_write;

/*
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
   */                
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
wire vga_csync = !(!video_hs ^ video_vs);
wire vga_hsync, vga_vsync;

// TV SCART has csync on hsync pin and "high" on vsync pin
assign vsync_o = tv15khz?1'b1:video_vs;
assign hsync_o = tv15khz?vga_csync:video_hs;
assign csync_o = vga_csync;

// tv15hkz has half the pixel rate		  
wire osd_clk = tv15khz?clk10:clk21;

/*
BUFGMUX_1 mux1 
(
	.I0(clk10),
	.I1(clk21),
	.S (tv15khz),
	.O (osd_clk)
);
*/

wire [4:0] vga_r_s, vga_g_s, vga_b_s;

/*
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
*/
// ---------------------------------------------------------------------------------
// -------------------------------------- reset ------------------------------------
// ---------------------------------------------------------------------------------

//assign btn_reset_n_i = 1'bZ;

wire rom_download = dio_download && (dio_index == 0);
reg [11:0] reset_cnt;
wire reset = (reset_cnt != 0);
always @(posedge clk2) begin
	if( status[0] || !host_reset_n || !pll_locked || rom_download || !btn_reset_n_i)
		reset_cnt <= 12'hfff -1;
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
assign audioext_l_o = audio;
assign audioext_r_o = audio;

wire [7:0] keys_s;

zx8302 #(.BASE_ADDR(25'h0CF000)) zx8302 (
	.reset        ( reset        ),
	.init         ( !pll_locked  ),
	.clk11        ( clk11  		  ),
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
	
	.ps2_clk   ( ps2_pin6_io  ), // ps2_mouse_clk  ),
	.ps2_data  ( ps2_pin2_io ) //ps2_mouse_data )
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
        .clr_berr       ( ),//1'b0           ),
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



// CPU and Video share the bus
reg video_cycle = 1'b0;
wire cpu_cycle = !video_cycle;

always @(posedge clk2, posedge reset)
begin
	if (reset)
		video_cycle <= 1'b0;
	else
	begin
		video_cycle <= !video_cycle;
		
		if (dio_download)video_cycle <=  0; //during the dowload all the cycle goes to the IO 
	end
		
end


//assign vga_r_o = vga_r_osd[7:5];		
//assign vga_g_o = vga_g_osd[7:5];		
//assign vga_b_o = vga_b_osd[7:5];	


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
			.clk(clk84), 
			.reset_n( btn_divmmc_n_i ), 
			
			.vga_hsync(video_hs), 
			.vga_vsync(video_vs), 
			.osd_window(osd_window), 
			.osd_pixel(osd_pixel), 
			
			.ps2k_clk_in( ps2_clk_io ), 
			.ps2k_dat_in( ps2_data_io ),
			
			.spi_miso( sd_miso_i ), 
			.spi_mosi( sd_mosi_o ), 
			.spi_clk( sd_sclk_o ), 
			.spi_cs( sd_cs0_n_o ), 
			
			.dipswitches(status), 
			.size(rom_size), 
			.index(dio_index),
			.joy_pins({7'b0000000}), 
			
			.host_divert_sdcard(host_divert_sdcard), 
			.host_divert_keyboard(host_divert_keyboard), 
			.host_reset_n(host_reset_n), 
			.host_reset_loader(host_reset_loader),
			
			.host_bootdata(bootdata), 
			.host_bootdata_req(bootdata_req), 
			.host_bootdata_ack(bootdata_ack)
	);
	
	OSD_Overlay osd_overlay 
	(
			.clk(clk84),
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
		
/*
 debounce #(16) debounce
 (
    .clk_i     (clk2),
    .button_i  (btn_n_i[2]),
    .result_o  (clk_test)
);
	*/
	reg [31:0] bytesloaded;
	reg [31:0] data;
	
	
	reg [31:0] dump_data;

	reg [3:0] boot_state;
	wire clk_test;

	always@( posedge clk2 )
	begin
		if (host_reset_loader == 1'b1) 
		begin
			bootdata_ack <= 1'b0;
			boot_state <= 4'b0000;

			bytesloaded <= 32'h00000000;
			
			dio_download <= 1'b0;
			dio_addr <= (dio_index) ? 25'h0CF000 : 25'd0;
			dio_write <= 1'b0;

		end 
		else
		begin

			case (boot_state)
			
				4'b0000: //ack
					if (bootdata_req == 1'b1) 
						begin					
								
								boot_state <= 4'b0001; 
								dio_download <= 1'b1;
						end 
					else 
						begin
						//	dio_download <= 1'b0;
							bootdata_ack <= 1'b0;
							
							if (bytesloaded >= rom_size && rom_size > 0) boot_state <= 4'b1111; //end
						end
						
				4'b0001: //read 1. word
						begin
								bootdata_ack <= 1'b1;
								data <= bootdata; //save a copy
								dio_data <= bootdata[31:16];
								dio_write <= 1'b0;
								
								if (bytesloaded < rom_size) 
									boot_state <= 4'b0010; //still more bytes to transfer
								else
									boot_state <= 4'b1111; //end
									
									
									
							 if (dio_addr == 25'b000000000?0000001000000000? ) dump_data <= bootdata; //0x800
								
						end
								
						
						
				4'b0010: //write 1. word
					begin	
					   bootdata_ack <= 1'b0;
						dio_write <= 1'b1;
						bytesloaded <= bytesloaded + 2;
						
						boot_state <= 4'b0101; //<= 4'b0011;
					end
					
				4'b0011: //wait state
					begin
						boot_state <= 4'b0100;
					end
					
				4'b0100: //wait state
					begin
						boot_state <= 4'b0101;
					end
					
				4'b0101: //wait state
					begin
						boot_state <= 4'b0110;
						dio_write <= 1'b0;
					end
					
				4'b0110: //clear the write signal
					begin
						dio_addr <= dio_addr + 25'd1;
						dio_data <= data[15:0]; //prepare the 2. word (from the copy)
						boot_state <= 4'b0111;
					end
					
				4'b0111: //write 2. word
					begin
						dio_write <= 1'b1;
						bytesloaded <= bytesloaded + 2;
						boot_state <= 	4'b1010; //4'b1000;
					end
					
				4'b1000: //wait state
					begin
						boot_state <= 4'b1001;
					end	
					
				4'b1001: //wait state
					begin
						boot_state <= 4'b1010;
					end	
					
				4'b1010: //wait state
					begin
						boot_state <= 4'b1011;
						dio_write <= 1'b0;
					end
					
				4'b1011: //clear the write signal and loop
					begin
						dio_addr <= dio_addr + 25'd1;
						boot_state <= 4'b0000;
					end
					
				4'b1111: //END
					begin
						dio_download <= 1'b0;
						bootdata_ack <= 1'b0;
					end	
					
			endcase;
		end
	end
	
		
//-----------------------------------------------------------
// 
// DEBUG
//		


debug_info #(100,100) debug_info (
        .clk_i    ( osd_clk   ),
		  
        .r_i      ( vga_r_osd[7:5]   ),
        .g_i      ( vga_g_osd[7:5]   ), 
        .b_i      ( vga_b_osd[7:5]   ),
        .hSync_i  ( video_hs ), 
        .vSync_i  ( video_vs ),
		  
        .r_o      ( rgb_r_o   ),
        .g_o      ( rgb_g_o   ),
        .b_o      ( rgb_b_o   ), 
		  
		  .dbg1_s   ( dump_data[31:24] ),
        .dbg2_s   ( dump_data[23:16] ),
        .dbg3_s   ( dump_data[15:8]  ),
        .dbg4_s   ( dump_data[7:0]   ),
		  
        .dbg5_s   ( {3'b000,bootdata_req, 3'b000,bootdata_ack} ),
        .dbg6_s   ( dio_addr[23:16] ),
        .dbg7_s   ( dio_addr[15:8]  ),
        .dbg8_s   ( dio_addr[7:0]   ),
		  
        .dbg9_s   ( {3'b000,dio_download, 3'b000,dio_write}),
        .dbg10_s  ( {4'b0000, boot_state} ),
        .dbg11_s  ( dio_data[15:8]  ),
        .dbg12_s  ( dio_data[7:0]   )
);		

   
	
	//--------------------------------------------------------
	//-- Unused outputs
	//--------------------------------------------------------

	
	 // TODO: add support for HDMI output
   OBUFDS OBUFDS_c0  ( .O  ( hdmi_p_o[0]), .OB  ( hdmi_n_o[0]), .I (1'b1));
   OBUFDS OBUFDS_c1  ( .O  ( hdmi_p_o[1]), .OB  ( hdmi_n_o[1]), .I (1'b1));
   OBUFDS OBUFDS_c2  ( .O  ( hdmi_p_o[2]), .OB  ( hdmi_n_o[2]), .I (1'b1));
   OBUFDS OBUFDS_clk ( .O  ( hdmi_p_o[3]), .OB  ( hdmi_n_o[3]), .I (1'b1));
   
   // -- Interal audio (speaker, not fitted)
    assign audioint_o     = 1'b0;

    //-- Spectrum Next Bus
    assign bus_addr_o     = 16'hFFFF;
    assign bus_busack_n_o = 1'b1;
    assign bus_clk35_o    = 1'b1;
    assign bus_data_io    = 8'hFF;
    assign bus_halt_n_o   = 1'b1;
    assign bus_iorq_n_o   = 1'b1;
    assign bus_m1_n_o     = 1'b1;
    assign bus_mreq_n_o   = 1'b1;
    assign bus_rd_n_o     = 1'b1;
    assign bus_rfsh_n_o   = 1'b1;
    assign bus_rst_n_io   = 1'b1;
    assign bus_wr_n_o     = 1'b1;

    //-- ESP 8266 module
    assign esp_gpio0_io   = 1'bZ;
    assign esp_gpio2_io   = 1'bZ;
    assign esp_tx_o = 1'b1;
	 
    //-- Addtional flash pins; used at IO2 and IO3 in Quad SPI Mode
    assign flash_hold_o   = 1'b1;
    assign flash_wp_o     = 1'b1;
	 
	 assign flash_cs_n_o  = 1'b1;
    assign flash_sclk_o  = 1'b1;
    assign flash_mosi_o  = 1'b1;

    assign ear_port_i = 1'b1;
    assign keyb_row_o = 8'hFF;
		
	 assign i2c_scl_io = 1'bZ;
    assign i2c_sda_io = 1'bZ;

    //-- Pin 7 on the joystick connecter. 
    assign joyp7_o    = 1'b1;

    //-- Controls a mux to select between two joystick ports
    assign joysel_o   = 1'b0;

    //-- Keyboard row
    assign keyb_row_o = 8'hFF;

    //-- Mic Port (output, as it connects to the mic input on cassette deck)
    assign mic_port_o = 1'b0;

	 //-- CS2 is for internal SD socket
    assign sd_cs1_n_o = 1'b1;
	 
    // PI GPIO
    assign accel_io = 28'bZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;

    // Vacant pins
    assign extras_io = 1'b1;

		
endmodule
