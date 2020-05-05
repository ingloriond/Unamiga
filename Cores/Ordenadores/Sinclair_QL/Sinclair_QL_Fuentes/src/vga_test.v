`timescale 1ns / 1ps
module VGA(
input clock,
output reg [2:0 ] red, 
output reg [2:0 ] green, 
output reg [2:0 ] blue,
output reg hsync, 
output reg vsync
);
reg clock_50, clock_25;
reg [9:0] hcount = 640;
reg [9:0] vcount = 480;
reg [9:0] next_hcount = 640;
reg [9:0] next_vcount = 480;

/*
always @ (posedge clock)
begin
  clock_50 =! clock_50;
end

always @ (posedge clock_50)
begin
  clock_25 =! clock_25;
end
*/


always @(posedge clock)
begin
  if(hcount == 799)
  begin
    hcount <= 0;
    if(vcount == 524)
      vcount <= 0;
    else 
      vcount <= vcount+1'b1;
  end
  else
    hcount <= hcount+1'b1;
         
  if (vcount >= 490 && vcount < 492) 
    vsync <= 1'b0;
  else
    vsync <= 1'b1;

  if (hcount >= 656 && hcount < 752) 
    hsync <= 1'b0;
  else
    hsync <= 1'b1;
end
 
always @ (posedge clock)
begin
  if (hcount < 80 && vcount < 480)
  begin
    green <= 3'b111;
    blue  <= 3'b111;    
    red   <= 3'b111;
  end
  else if (hcount < 160  && vcount < 480)
  begin
    green <= 3'b111;
    blue  <= 3'b000;    
    red   <= 3'b111;
  end
  else if (hcount < 240  && vcount < 480)
  begin
    green <= 3'b111;
    blue  <= 3'b111;    
    red   <= 3'b000;
  end
  else if (hcount < 320  && vcount < 480)
  begin
    green <= 3'b111;
    blue  <= 3'b000;    
    red   <= 3'b000;
  end
  else if (hcount < 400  && vcount < 480)
  begin
    green <= 3'b000;
    blue  <= 3'b111;    
    red   <= 3'b111;
  end
  else if (hcount < 480  && vcount < 480)
  begin
    green <= 3'b000;
    blue  <= 3'b000;    
    red   <= 3'b111;
  end
  else if (hcount < 560  && vcount < 480)
  begin
    green <= 3'b000;
    blue  <= 3'b111;    
    red   <= 3'b000;
  end
  else if (hcount < 640  && vcount < 480)
  begin
    green <= 3'b000;
    blue  <= 3'b000;    
    red   <= 3'b000;
  end
  else 
  begin
    green <= 3'b000;
    blue  <= 3'b000;    
    red   <= 3'b000;
  end   
end
endmodule