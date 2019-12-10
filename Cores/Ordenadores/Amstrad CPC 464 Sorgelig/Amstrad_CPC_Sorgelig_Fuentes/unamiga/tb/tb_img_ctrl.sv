`timescale 1ns / 100ps

`default_nettype none

module tb;


reg reset;

reg clk_sys = 0;
reg ce_u765 = 0; 
reg [3:0] div = 0;

wire [31:0]sd_lba	;		
wire [1:0]sd_rd_s	;		
wire [1:0]sd_wr	;		
              
wire sd_ack	;		
wire [8:0]sd_buff_addr;	
wire [7:0]sd_buff_dout;	
wire [7:0]sd_buff_din	;
wire sd_buff_wr	;	
             
wire [18:0]dsk_addr_s	;
reg [7:0]disk_data_s	;

reg [1:0]img_mounted;

logic [7:0] ram1[0:511] = '{
8'h4D, 8'h56, 8'h20, 8'h2D, 8'h20, 8'h43, 8'h50, 8'h43, 8'h45, 8'h4D, 8'h55, 8'h20, 8'h2F, 8'h20, 8'h31, 8'h32, 8'h20, 8'h4D, 8'h61, 8'h79, 8'h20, 8'h39, 8'h37, 8'h20, 8'h32, 8'h30, 8'h3A, 8'h30, 8'h30, 8'h00, 8'h20, 8'h20,
8'h20, 8'h20, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h28, 8'h01, 8'h00, 8'h13, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h54, 8'h72, 8'h61, 8'h63, 8'h6B, 8'h2D, 8'h49, 8'h6E, 8'h66, 8'h6F, 8'h0D, 8'h0A, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h02, 8'h09, 8'h4E, 8'hE5, 8'h00, 8'h00, 8'hC1, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'hC2, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC3, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC4, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC5, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'hC6, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC7, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC8, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC9, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00,
8'hF0, 8'hC4, 8'h75, 8'h63, 8'hFB, 8'h44, 8'h37, 8'h04, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00

};
 
 
//This block generates a clock pulse with a 20 ns period
always
 #10 clk_sys = ~clk_sys;
 
 
always @(negedge clk_sys) begin
	div     <= div + 1'd1;

	assign ce_u765 = !div[2:0]; //8 MHz
assign disk_data_s = ram1[dsk_addr_s[8:0]];
end



	

image_controller imc_ctrl
(
		.clk_i			( clk_sys ),
		.reset_i		( reset ),
		                
		.sd_lba			( sd_lba ),
		.sd_rd			( sd_rd_s ),
		.sd_wr			( sd_wr ),
		                
		.sd_ack			( sd_ack ),
		.sd_buff_addr	( sd_buff_addr ),
		.sd_buff_dout	( sd_buff_dout ),
		.sd_buff_din	( sd_buff_din ),
		.sd_buff_wr		( sd_buff_wr ),
		                
		.sram_addr_o	( dsk_addr_s ),
		.sram_data_i	( disk_data_s )
);

reg a0 = 0;
reg nWR = 1;
reg [7:0] din;

reg  [1:0] u765_ready = 0;
always @(posedge clk_sys) if(img_mounted[0]) u765_ready[0] <= 1;
always @(posedge clk_sys) if(img_mounted[1]) u765_ready[1] <= 0;
reg current;
u765 u765
(
	.reset( reset ),

	.clk_sys(clk_sys),
	.ce(ce_u765),

	.fast(0),

	.a0(a0),
	.ready(u765_ready),
	.motor(2'b11),
	.available(2'b11),
	.nRD(~nWR),
	.nWR(nWR),
	.din(din),
	.dout(),
	
	.img_mounted(img_mounted),	// (in) signaling that new image has been mounted
	.img_size( 32'd194816 ),	// (in) size of image in bytes
	.img_wp(0), 					// (in) write protect. latched at img_mounted
	
	.sd_lba(sd_lba),					// (out)
	.sd_rd(sd_rd_s),						// (out)
	.sd_wr(sd_wr),						// (out)
	.sd_ack(sd_ack),					// (in )
	.sd_buff_addr(sd_buff_addr),	// (in )
	.sd_buff_dout(sd_buff_dout),	// (in )
	.sd_buff_din(sd_buff_din),		// (out)
	.sd_buff_wr(sd_buff_wr)			// (in)
	
);
 
 integer i;
 
//This initial block will provide values for the inputs
// of the mux so that both inputs/outputs can be displayed
initial 
begin
	$timeformat(-9, 1, " ns", 6);
	clk_sys = 1'b0; // time = 0
	a0 = 0;
	din=0;
	//sd_wr <= "00";
	//sd_rd_s <= "00";
	img_mounted <= "00";
	reset = 1;
	#100
	reset = 0;
	#100
		repeat (20) @(posedge clk_sys);
	img_mounted <= "01";
	@(posedge clk_sys);
	img_mounted <= "00";
	
	#90000; //tempo para montar logicamente a imagem
	
	
	/*
	//read_id
	nWR = 0; //active low
	a0 = 1; 
	din = 8'b00001010; // state <= COMMAND_READ_ID;
	@(negedge ce_u765);
	nWR = 1;
	@(negedge ce_u765);

	//read_id1	
	nWR = 0; //active low
	a0 = 1; 
	din = 8'b00000000; // hds 0;
	@(negedge ce_u765);
	nWR = 1;
	@(negedge ce_u765);
	*/
	
	//read track
	nWR = 0; //active low
	a0 = 1; 
	din = 8'b00000010; // state <= COMMAND_READ_TRACK;
	@(negedge ce_u765);
	nWR = 1;
	@(negedge ce_u765);
	
	
	 for (i=0; i<8; i=i+1)
        begin
			//command setup
			nWR = 0; //active low
			a0 = 1; 
			din = 8'b00000000; // state <= COMMAND_READ_TRACK;
			@(negedge ce_u765);
			nWR = 1;
			@(negedge ce_u765);
	end
	
	
	#90000

	
	 $stop; // to shut down the simulation
end //initial


	 
	 
endmodule 