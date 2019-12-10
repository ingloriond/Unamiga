//-------------------------------------------------------------------------------
//--
//-- Image reader for the Amstrad FPGA
//--
//-- 2019 - Victor Trucco
//-- 
//-------------------------------------------------------------------------------



module image_controller 
(
    
	input						clk_i,
	input						reset_i,
                       
	input			[31:0]	sd_lba,
	input			[ 1:0]	sd_rd, 
	input			[ 1:0]	sd_wr, 
                                
	output reg				sd_ack,
	output reg 	[ 8:0]	sd_buff_addr,
	output reg 	[ 7:0]	sd_buff_dout,
	input			[ 7:0]	sd_buff_din,
	output reg				sd_buff_wr,
		                        
	output reg 	[18:0]	sram_addr_o,
	input			[ 7:0]	sram_data_i	

);




typedef enum
{
		IDLE,
		P0,
		P1,
		P2,
		P3,
		P4,
		P5,
		P6
} states_t;

states_t state_s ;

reg [18:0] sram_addr_s;
reg [16:0] sd_addr;

assign	sd_buff_addr = sram_addr_s[8:0];
assign	sram_addr_o = sram_addr_s; 



	always @(posedge clk_i)
	begin
		 	if (reset_i)
			begin
				
					state_s <= P0;
					sd_ack <= 1'b0;
					sd_buff_wr <= 1'b0;
			end
			else
			begin
		 

			
					case (state_s)
					
						IDLE: state_s <= IDLE;
 
						 P0:
							 begin

										if ( sd_rd[0] )
										begin

											sd_ack <= 1'b1;
											state_s <= P1;							
											
											sd_addr = (sd_lba[16:0] > 9'd256)? sd_lba[16:0] - 9'd256 : sd_lba[16:0]; // ATTENTION blocking assignment
											sram_addr_s[18:9] =  sd_addr[9:0];
											sram_addr_s[8:0] = 9'b000000000;
						
										end
							end
						
						P1:
							begin
									sd_buff_dout<= sram_data_i;
									state_s <= P2;
							end	
						
						P2:
							begin			
									sd_buff_wr <= 1'b1;
									state_s <= P3;
							end	
						
						P3:	
							begin		
									sd_buff_wr <= 1'b0;
									state_s <= P4;
							end	
						
						P4:
							begin
									sram_addr_s <= sram_addr_s + 1;
								

									if (sram_addr_s[8:0] != 9'b111111111)
										state_s <= P1;
									else
										state_s <= P5;
									
							end
								
						P5:
							begin
									sd_ack <= 1'b0;
									state_s <= P0;
							end		
						
						P6: state_s <= P6;
						  
						
							  
					endcase;
				


				
			end
	end


endmodule


