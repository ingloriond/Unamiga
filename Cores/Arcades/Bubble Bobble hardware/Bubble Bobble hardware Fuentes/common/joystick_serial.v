
module joystick_serial 
(
    input  wire clk_i,      //clock aqui nao pode ser muito alto. 25mhz funciona, 48 mhz nao
    input  wire joy_data_i,
    output wire joy_clk_o,  
    output wire joy_load_o, 

    output wire joy1_up_o,
    output wire joy1_down_o,
    output wire joy1_left_o,
    output wire joy1_right_o,
    output wire joy1_fire1_o,
    output wire joy1_fire2_o,

    output wire joy2_up_o,
    output wire joy2_down_o,
    output wire joy2_left_o,
    output wire joy2_right_o,
    output wire joy2_fire1_o,
    output wire joy2_fire2_o
);

reg [11:0] joy1  = 12'hFFF;
reg [11:0] joy2  = 12'hFFF;   
reg joy_renew = 1'b1;
reg [4:0]joy_count = 5'd0;

assign joy_clk_o    = clk_i;
assign joy_load_o   = joy_renew;

assign joy1_up_o    = joy1[0];     
assign joy1_down_o  = joy1[1];
assign joy1_left_o  = joy1[2];
assign joy1_right_o = joy1[3];
assign joy1_fire1_o = joy1[4];
assign joy1_fire2_o = joy1[5];
assign joy2_up_o    = joy2[0];   
assign joy2_down_o  = joy2[1];
assign joy2_left_o  = joy2[2];
assign joy2_right_o = joy2[3];
assign joy2_fire1_o = joy2[4];
assign joy2_fire2_o = joy2[5];

always @(posedge clk_i) 
begin 

    if (joy_count == 5'd0) 
      begin
       joy_renew <= 1'b0;
      end 
    else 
      begin
       joy_renew <= 1'b1;
      end

    if (joy_count == 5'd17) 
      begin
         joy_count <= 5'd0;
      end
    else 
      begin
         joy_count <= joy_count + 1'd1;
      end   

    case (joy_count)
        5'd16 : joy1[0]  <= joy_data_i;   //  1p up
        5'd15 : joy1[4]  <= joy_data_i;   //  1p fire1
        5'd14 : joy1[1]  <= joy_data_i;   //  1p down
        5'd13 : joy1[2]  <= joy_data_i;   //  1p left
        5'd12 : joy1[3]  <= joy_data_i;   //  1p right
        5'd11 : joy1[5]  <= joy_data_i;   //  1p fire2

        5'd8  : joy2[0]  <= joy_data_i;   //  2p up
        5'd7  : joy2[4]  <= joy_data_i;   //  2p fire1
        5'd6  : joy2[1]  <= joy_data_i;   //  2p down
        5'd5  : joy2[2]  <= joy_data_i;   //  2p left
        5'd4  : joy2[3]  <= joy_data_i;   //  2p right
        5'd3  : joy2[5]  <= joy_data_i;   //  2p fire2
    endcase 

end
endmodule