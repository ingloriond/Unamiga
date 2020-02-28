//============================================================================
//
//  Memory testes for MiSTer.
//  Copyright (C) 2017-2019 Sorgelig
//
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
//  Multicore 2 Top by Victor Trucco
//
//============================================================================

`default_nettype none

module memtest
( 
	  // clock inputs
	  input                 clock_50_i,     // 50 MHz
	  
	  // push button inputs
	  input       [    2:1] btn_n_i,          
	  input       [    8:1] dip_i,          

	  // PS2
	  inout                 PS2_DAT,      // PS2 Keyboard Data
	  inout                 PS2_CLK,      // PS2 Keyboard Clock
	  inout                 PS2_MDAT,     // PS2 Mouse Data
	  inout                 PS2_MCLK,     // PS2 Mouse Clock
	  
	  // VGA
	  output                VGA_HS,       // VGA H_SYNC
	  output                VGA_VS,       // VGA V_SYNC
	  output      [  4:0]   VGA_R,        // VGA Red[7:0], 
	  output      [  4:0]   VGA_G,        // VGA Green[7:0] 
	  output      [  4:0]   VGA_B,        // VGA Blue[7:0] 
	  
	  // SD Card
	  input                 SD_MISO,      // SD Card Data            - spi MISO
	  output                SD_CS,        // SD Card Data 3          - spi CS
	  output                SD_MOSI,      // SD Card Command Signal  - spi MOSI
	  output                SD_CLK,       // SD Card Clock           - spi CLK
	  input                 sd_sw_i,      // SD Card switch
	  
	  // SDRAM
	  inout       [ 15:0]   SDRAM_DQ,      // SDRAM Data bus 16 Bits
	  output      [ 12:0]   SDRAM_A,       // SDRAM Address bus 12 Bits
	  output                SDRAM_DQML,    // SDRAM Low-byte Data Mask
	  output                SDRAM_DQMH,    // SDRAM High-byte Data Mask
	  output                SDRAM_nWE,     // SDRAM Write Enable
	  output                SDRAM_nCAS,    // SDRAM Column Address Strobe
	  output                SDRAM_nRAS,    // SDRAM Row Address Strobe
	  output                SDRAM_nCS,     // SDRAM Chip Select
	  output      [  1:0]   SDRAM_BA,      // SDRAM Bank Address 0-1
	  output                SDRAM_CLK,     // SDRAM Clock
	  output                SDRAM_CKE,     // SDRAM Clock Enable

	  // SOUND
	  output                AUDIO_L,      // sigma-delta DAC output left
	  output                AUDIO_R,       // sigma-delta DAC output right
	  input wire	ear_i,
		output wire	mic_o				= 1'b0,
	
		// Joysticks
		input wire	joy1_up_io,
		input wire	joy1_down_io,
		input wire	joy1_left_io,
		input wire	joy1_right_io,
		input wire	joy1_p6_io,
		input wire	joy1_p7_io,
		output wire	joy1_p8_io,
		input wire	joy2_up_io,
		input wire	joy2_down_io,
		input wire	joy2_left_io,
		input wire	joy2_right_io,
		input wire	joy2_p6_io,
		input wire	joy2_p7_io,
		output wire	joy2_p8_io,

		// External Slots
		inout [15:0] slot_A_o	, 
		inout [7:0]slot_D_io		, 
		inout slot_CS1_o			, 
		inout slot_CS2_o			, 
		inout slot_CLOCK_o		, 	
		inout slot_M1_o			, 	
		inout slot_MREQ_o			, 	
		inout slot_IOREQ_o		, 	
		inout slot_RD_o			, 	
		inout slot_WR_o			, 	
		inout slot_RESET_io		, 	
		inout slot_SLOT1_o		, 	
		inout slot_SLOT2_o		, 		
		inout slot_SLOT3_o		, 
		inout slot_BUSDIR_i		, 
		inout slot_RFSH_i			, 
		inout slot_INT_i			, 
		inout slot_WAIT_i			, 
		 
		output slot_DATA_OE_o	, 	
		output slot_DATA_DIR_o	, 

		// HDMI video
		output hdmi_pclk			, 
		output hdmi_de				, 
		input hdmi_int				, 
		output hdmi_rst			,  
		 
		// HDMI audio 
		output aud_sck				, 
		output aud_ws				, 
		output aud_i2s				, 
		 
		// HDMI programming
		inout hdmi_sda				, 
		inout hdmi_scl				, 
		 
		// ESP
		output esp_rx_o			, 
		input esp_tx_i	
		
);


assign AUDIO_L = 0;
assign AUDIO_R = 0;


wire [31:0] status;
wire  [1:0] buttons;

reg  [1:0] sdram_sz = 2'b01; //0 - no memory board detected   1 - 32 MB  2 - 64 MB  3 - 128 MB

reg direct = 1'b1;



/*
reg  [10:0] ps2_key;
wire  [1:0] sdram_sz;
hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(CLK_50M),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),
	.status(status),
	.buttons(buttons),
	.sdram_sz(sdram_sz),

	.ps2_key(ps2_key),
	.ps2_kbd_led_use(0),
	.ps2_kbd_led_status(0)
);
*/

wire RESET = ~btn_n_i[1];

///////////////////////////////////////////////////////////////////
wire clk_ram, locked;

wire [1:0] pll_locked_in;
wire pll_locked;
wire pll_areset;
wire pll_scanclk;
wire pll_scandata;
wire pll_scanclkena ;
wire pll_configupdate;
wire pll_scandataout;
wire pll_scandone;
wire [7:0]pll_rom_address;
wire pll_write_rom_ena;
wire pll_write_from_rom;
wire pll_reconfig_s;
wire pll_reconfig_busy;
wire pll_reconfig_reset;
reg [1:0]pll_reconfig_state = 2'b00;
integer pll_reconfig_timeout;
wire pll_rom_q;
	

pll pll
(
	
	.inclk0(clock_50_i),
	.areset(pll_areset | RESET),
	.c0(clk_ram),
	.c1(SDRAM_CLK),
	.locked(locked),
	
	.scanclk 		( pll_scanclk ),
	.scandata 		( pll_scandata ),
	.scanclkena 	( pll_scanclkena ),
	.configupdate 	( pll_configupdate ),
	.scandataout 	( pll_scandataout ),
	.scandone 		( pll_scandone )
	
);

//assign ps2_mouse_clk_io = clk_ram;

	pll_reconfig pll_reconfig
	(
		.busy 					( pll_reconfig_busy ),
		.clock  					( clock_50_i ),
		.counter_param 		( 3'b000 ),
		.counter_type 			( 4'b0000 ),
		.data_in 				( 9'b000000000 ),
		.pll_areset 			( pll_areset ),
		.pll_areset_in  		( 0 ),
		.pll_configupdate 	( pll_configupdate),
		.pll_scanclk 			( pll_scanclk ),
		.pll_scanclkena 		( pll_scanclkena ),
		.pll_scandata 			( pll_scandata ),
		.pll_scandataout 		( pll_scandataout ),
      .pll_scandone		 	( pll_scandone ),
		.read_param			 	( 0 ),
      .reconfig 				( pll_reconfig_s ),
		.reset 					( pll_reconfig_reset ),
		.reset_rom_address 	( 0 ),
		.rom_address_out 		( pll_rom_address ),
		.rom_data_in 			( pll_rom_q ),
		.write_from_rom 		( pll_write_from_rom ),
		.write_param  			( 0 ),
      .write_rom_ena 		( pll_write_rom_ena )
	);
	

	wire q_reconfig_70, q_reconfig_80, q_reconfig_90, q_reconfig_100, q_reconfig_110, q_reconfig_120, q_reconfig_130, q_reconfig_140, q_reconfig_150, q_reconfig_160, q_reconfig_167;
	
	reconfig_70  reconfig_70  ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_70 ));
	reconfig_80  reconfig_80  ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_80 ));
	reconfig_90  reconfig_90  ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_90 ));
	reconfig_100 reconfig_100 ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_100 ));
	reconfig_110 reconfig_110 ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_110 ));
	reconfig_120 reconfig_120 ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_120 ));
	reconfig_130 reconfig_130 ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_130 ));
	reconfig_140 reconfig_140 ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_140 ));
	reconfig_150 reconfig_150 ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_150 ));
	reconfig_160 reconfig_160 ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_160 ));
	reconfig_167 reconfig_167 ( .address ( pll_rom_address ), .clock ( clock_50_i ), .rden ( pll_write_rom_ena ), .q ( q_reconfig_167 ));

always @(*) 
begin
	case(pos)
		0: begin pll_rom_q <= q_reconfig_167; end
		1: begin pll_rom_q <= q_reconfig_160; end
		2: begin pll_rom_q <= q_reconfig_150; end
		3: begin pll_rom_q <= q_reconfig_140; end
		4: begin pll_rom_q <= q_reconfig_130; end
		5: begin pll_rom_q <= q_reconfig_120; end
		6: begin pll_rom_q <= q_reconfig_110; end
		7: begin pll_rom_q <= q_reconfig_100; end
		8: begin pll_rom_q <= q_reconfig_90;  end
		9: begin pll_rom_q <= q_reconfig_80;  end
	  10: begin pll_rom_q <= q_reconfig_70;  end
	endcase
end		

	
	
reg recfg = 0;

// Phases here are empirically adjusted based on 167MHz synthesized core 
// so arn't reliable for fixed frequency cores.
wire [31:0] cfg_param[44] =
'{ //      M         K          C
	'h167, 'h00808, 'hB33332DD, 'h20302,
	'h160, 'h00808, 'h00000001, 'h20302,
	'h150, 'h20807, 'h00000001, 'h20302,
	'h140, 'h00707, 'h00000001, 'h20302,
	'h130, 'h00505, 'h66666611, 'h00202,
	'h120, 'h00707, 'h66666611, 'h00303,
	'h110, 'h20706, 'h333332DD, 'h00303,
	'h100, 'h00404, 'h00000001, 'h00202,
	 'h90, 'h00707, 'h66666666, 'h00404,
	 'h80, 'h00707, 'h66666666, 'h20504,
	 'h70, 'h00707, 'h00000001, 'h00505
};

reg   [3:0] pos  = 7;
reg  [15:0] mins = 0;
reg  [15:0] secs = 0;
reg         auto = 0;

reg  [10:0] ps2_key;

reg btn_rst, old_btn_rst;
reg btn_up, old_btn_up;
reg btn_down, old_btn_down;
reg btn_auto, old_btn_auto;



	
	
	

always @(posedge clock_50_i) begin
	reg  [7:0] state = 0;
	integer    min = 0, sec = 0;
	reg        old_stb = 0;

	pll_write_from_rom <= 0;
	pll_reconfig_s <= 0;
	pll_reconfig_reset <= 0;





	case(pll_reconfig_state)

		0: begin
				if (recfg)
				begin
					pll_write_from_rom <= 1;
					pll_reconfig_state <= 1;
				end
			end


		1: begin
				pll_reconfig_state <= 2;
			end

	
		2: begin
		
				if (pll_reconfig_busy == 0)
				begin	
					pll_reconfig_s <= 1;
					pll_reconfig_state <= 3;
					pll_reconfig_timeout <= 1000;
				end;
				
			end


		3: begin
		
				pll_reconfig_timeout <= pll_reconfig_timeout - 1;
				
				if (pll_reconfig_timeout == 1) 
				begin
					pll_reconfig_reset <= 1; // sometimes pll reconfig stuck in busy state
					pll_reconfig_state <= 0;
					recfg <= 0;
				end
				
				if (pll_reconfig_s == 0 && pll_reconfig_busy == 0)
				begin
					pll_reconfig_state <= 0;
					recfg <= 0;
				end
				
			end


	endcase
	


	if(recfg) begin
		{min, mins} <= 0;
		{sec, secs} <= 0;
	end else begin
		min <= min + 1;
		if(min == 2999999999) begin
			min <= 0;
			if(mins[3:0]<9) mins[3:0] <= mins[3:0] + 1'd1;
			else begin
				mins[3:0] <= 0;
				if(mins[7:4]<9) mins[7:4] <= mins[7:4] + 1'd1;
				else begin
					mins[7:4] <= 0;
					if(mins[11:8]<9) mins[11:8] <= mins[11:8] + 1'd1;
					else begin
						mins[11:8] <= 0;
						if(mins[15:12]<9) mins[15:12] <= mins[15:12] + 1'd1;
						else mins[15:12] <= 0;
					end
				end
			end
		end
		sec <= sec + 1;
		if(sec == 4999999) begin
			sec <= 0;
			secs <= secs + 1'd1;
		end
	end
	
	old_btn_rst <= btn_rst;
	old_btn_up <= btn_up;
	old_btn_down <= btn_down;
	old_btn_auto <= btn_auto;
		
		//(pos 0 = 167)
		
	if(old_btn_rst == 0 && btn_rst == 1) 
	begin
	//	direct <= ~direct;
	end
	
		
	if(old_btn_up == 0 && btn_up == 1 && pos > 0) 
	begin
		state <= 0;
		recfg <= 1;
		pos <= pos - 1'd1;
		auto <= 0;
	end
			
	if(old_btn_down == 0 && btn_down == 1 && pos < 10) 
	begin
		state <= 0;
		recfg <= 1;
		pos <= pos + 1'd1;
		auto <= 0;
	end
			
	if(old_btn_auto == 0 && btn_auto == 1 && auto == 1) 
	begin
	state <= 0;
		recfg <= 1;
		auto <= 0;
	end
			
	if(old_btn_auto == 0 && btn_auto == 1 && auto == 0) 
	begin
		state <= 0;
		recfg <= 1;
		pos <= 0;
		auto <= 1;
	end

	if(auto && (failcount && passcount) && !recfg && pos < 10) 
	begin
		recfg <= 1;
		pos <= pos + 1'd1;
	end
	
	if(status[0] ) 
	begin
		recfg <= 1;
		pos <= 0;
		auto <= 1;
	end
end


///////////////////////////////////////////////////////////////////
assign SDRAM_CKE = 1;

reg reset = 0;
always @(posedge clk_ram) begin
	integer timeout;

	if(timeout) timeout <= timeout - 1;
	reset <= |timeout;

	if((recfg || ~locked) && (timeout < 1000000)) timeout <= 1000000;

	if(RESET) timeout <= 100000000;
end

wire module_clk, pll_clk;

wire [31:0] passcount, failcount;
tester my_memtst
(
	.clk(clk_ram),
	.rst_n(~reset),
	.sz(sdram_sz),
	.passcount(passcount),
	.failcount(failcount),
//	.DRAM_CLK(SDRAM_CLK),
	.DRAM_DQ(SDRAM_DQ),
	.DRAM_ADDR(SDRAM_A),
	.DRAM_LDQM(SDRAM_DQML),
	.DRAM_UDQM(SDRAM_DQMH),
	.DRAM_WE_N(SDRAM_nWE),
	.DRAM_CS_N(SDRAM_nCS),
	.DRAM_RAS_N(SDRAM_nRAS),
	.DRAM_CAS_N(SDRAM_nCAS),
	.DRAM_BA_0(SDRAM_BA[0]),
	.DRAM_BA_1(SDRAM_BA[1])
);


///////////////////////////////////////////////////////////////////
wire videoclk;

vid_pll vid_pll
(
	.inclk0(clock_50_i),
	.c0(videoclk)
);

//assign CLK_VIDEO = videoclk;
//assign CE_PIXEL  = 1;

wire hs, vs;
wire [1:0] b, r, g;
vgaout showrez
(
	.clk(videoclk),
	.rez1({(direct)?4'd13:4'd1, passcount[27:0]}),
	.rez2(failcount),
	.bg(6'b000001),
	.freq(16'hF000 | cfg_param[{pos, 2'd0}][11:0]),
	.elapsed(mins),
	.mark(8'h80 >> {~auto, secs[2:0]}),
	.hs(hs),
	.vs(vs),
	//.de(VGA_DE),
	.b(b),
	.r(r),
	.g(g)
);

assign VGA_HS = ~hs;
assign VGA_VS = ~vs;

assign VGA_B  = {4{b}};
assign VGA_R  = {4{r}};
assign VGA_G  = {4{g}};

debounce # ( .counter_size (10)) debounce1 ( .clk_i   (clock_50_i),   .button_i (~btn_n_i[1]), .result_o  (btn_up)); 
debounce # ( .counter_size (10)) debounce2 ( .clk_i   (clock_50_i),   .button_i (~btn_n_i[2]), .result_o  (btn_down)); 
//debounce # ( .counter_size (10)) debounce3 ( .clk_i   (clock_50_i),   .button_i (~btn_n_i[4]), .result_o  (btn_down)); 
//debounce # ( .counter_size (10)) debounce4 ( .clk_i   (clock_50_i),   .button_i (~btn_n_i[3]), .result_o  (btn_auto)); 


endmodule
