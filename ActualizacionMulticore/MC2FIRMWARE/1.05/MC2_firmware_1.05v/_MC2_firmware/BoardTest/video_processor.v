`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:31:14 10/18/2012 
// Design Name: 
// Module Name:    dummy_ula 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module background (
    input wire clk,
    output reg [5:0] r,
    output reg [5:0] g,
    output reg [5:0] b,
    output wire [9:0] hc,
    output wire [9:0] vc,
    output wire hsync,
    output wire vsync,
    output wire blank    
    );

    sync_generator sincronismos (
    .clk(clk),   
    .hsync_n(hsync),
    .vsync_n(vsync),
    .hc(hc),
    .vc(vc),
    .blank(blank)
    );
	 
	 assign blank = blank;
    
    always @* begin
      if (blank == 1'b1) begin
        {r,g,b} = 18'b000000_000000_000000;
      end
      else begin
        if (vc >= 10'd160*0 && vc < 10'd160*1) begin
          if (hc >= 10'd128*0 && hc < 10'd128*1)
            {r,g,b} = 18'b100000_000000_000000;
          else if (hc >= 10'd128*1 && hc < 10'd128*2)
            {r,g,b} = 18'b010000_000000_000000;
          else if (hc >= 10'd128*2 && hc < 10'd128*3)
            {r,g,b} = 18'b001000_000000_000000;
          else if (hc >= 10'd128*3 && hc < 10'd128*4)
            {r,g,b} = 18'b000100_000000_000000;
          else 
            {r,g,b} = 18'b000010_000000_000000;

        end
        else if (vc >= 10'd160*1 && vc < 10'd160*2) begin
          if (hc >= 10'd128*0 && hc < 10'd128*1)
            {r,g,b} = 18'b000000_100000_000000;
          else if (hc >= 10'd128*1 && hc < 10'd128*2)
            {r,g,b} = 18'b000000_010000_000000;
          else if (hc >= 10'd128*2 && hc < 10'd128*3)
            {r,g,b} = 18'b000000_001000_000000;
          else 
            {r,g,b} = 18'b000000_000100_000000;


        end
        else begin
          if (hc >= 10'd128*0 && hc < 10'd128*1)
            {r,g,b} = 18'b000000_000000_100000;
          else if (hc >= 10'd128*1 && hc < 10'd128*2)
            {r,g,b} = 18'b000000_000000_010000;
          else if (hc >= 10'd128*2 && hc < 10'd128*3)
            {r,g,b} = 18'b000000_000000_001000;
          else if (hc >= 10'd128*3 && hc < 10'd128*4)
            {r,g,b} = 18'b000000_000000_000100;
          else 
            {r,g,b} = 18'b000000_000000_000010;

        end
      end
    end        
endmodule

module window_on_background (
    input wire clk,
    input wire [9:0] addr,
    input wire [7:0] data,
    input wire we,
    input wire hidetextwindow,
    output reg [5:0] r,
    output reg [5:0] g,
    output reg [5:0] b,
    output wire hsync,
    output wire vsync,
    output wire blank
    );
   
    parameter
      BEGINX = 8 * 4 *2,          // X = 5  posicion horizontal esquina arriba izquierda
      BEGINY = 8 * 6 *2,          // Y = 6  posicion vertical esquina arriba izquierda
      ENDX = BEGINX + 8 * 32 *2,  // 32 columnas de texto por linea
      ENDY = BEGINY + 8 * 16 *2;  // 16 lineas de texto

    wire [5:0] rb,gb,bb;
    wire [9:0] hc,vc;
   
    background bg (
    .clk(clk),
    .r(rb),
    .g(gb),
    .b(bb),
    .hc(hc),
    .vc(vc),
    .hsync(hsync),
    .vsync(vsync),
    .blank(blank)
    );
    
    reg [7:0] charrom[0:2047];
    initial begin
      $readmemh ("CP437.hex", charrom);
    end
    
    wire in_text_window = (hc >= BEGINX && hc < ENDX && vc >= BEGINY && vc < ENDY);
    wire showing_text_window = (~hidetextwindow && hc >= (BEGINX+10'd8) && hc < (ENDX+10'd8) && vc >= BEGINY && vc < ENDY);
    
    reg [8:0] chc = 9'h00;
    reg [8:0] cvc = 9'h00;
    reg [7:0] shiftreg;
    reg [7:0] character;
    wire [7:0] dout;
    reg [9:0] charaddr = 10'd0;

   screenfb buffer_pantalla (
      .clk(clk),
      .addr_read(charaddr),
      .addr_write(addr),
      .we(we),
      .din(data),
      .dout(dout)
   );
	
	reg clk2 = 0;
	always @(posedge clk) 
	begin
		clk2 = ~clk2;
	end
	

   always @(posedge clk2) begin
      // H and C counters for text window
      if (hc == (BEGINX-10'd1) || hc == (BEGINX-10'd1)+1) begin  // empezamos a contar 8 pixeles antes, para tener ya el shiftreg cargado cuando comencemos de verdad
         chc <= 9'd0;
         if (vc == BEGINY || vc == BEGINY +1)
            cvc <= 9'd0;
         else
            cvc <= cvc + 9'd1;
      end
      else begin
         chc <= chc + 9'd1;
      end

      // char generator
      if (in_text_window) begin
         if (chc[2:0] == 3'b010) begin
            charaddr <= {cvc[8:4],5'b00000} + {2'b00,chc[7:3]};
         end
         if (chc[2:0] == 3'b100) begin         
            character <= dout; // lee el caracter siguiente
         end
         if (chc[2:0] == 3'b111) begin
            shiftreg <= charrom[{character,cvc[3:1]}];
         end
      end
      if (showing_text_window && chc[2:0] != 3'b111) begin
         shiftreg <= {shiftreg[6:0],1'b0};
      end
    end
    
    always @* begin
      {r,g,b} = {rb,gb,bb};
      if (showing_text_window)  // ventana de 32x16 caracteres de 8x8
         {r,g,b} = {18{shiftreg[7]}};  // texto blanco sobre fondo negro
    end
endmodule

module screenfb (
   input wire clk,
   input wire [9:0] addr_read,
   input wire [9:0] addr_write,
   input wire we,
   input wire [7:0] din,
   output reg [7:0] dout
   );
   
   reg [7:0] screenrom[0:511];  // ventana de 32 x 16 caracteres
   initial begin
     $readmemh ("texto_inicial.hex", screenrom);
   end
    
   always @(posedge clk) begin
      dout <= screenrom[addr_read];
      if (we)
         screenrom[addr_write] <= din;
   end
endmodule

module teletype (
   input wire clk,
   input wire mode,
   input wire [7:0] chr,
   input wire we,
   output reg busy,
   input wire hidetextwindow,
   output wire [5:0] r,
   output wire [5:0] g,
   output wire [5:0] b,
   output wire hsync,
   output wire vsync,
   output wire blank
   );

   reg [9:0] addr = 10'd0;
   reg [7:0] data = 8'h00, dscreen = 8'h00;
   reg wescreen = 1'b0;
   initial busy = 1'b0;
    
   window_on_background screen (
    .clk(clk),
    .addr(addr),
    .data(dscreen),
    .we(wescreen),
    .hidetextwindow(hidetextwindow),
    .r(r),
    .g(g),
    .b(b),
    .hsync(hsync),
    .vsync(vsync),
    .blank(blank)
    );
    
   parameter
      IDLE = 4'd0,
      PCOMMAND = 4'd1,
      ATR = 4'd3,
      ATC = 4'd4,
      CLS = 4'd5,
      PUTCHAR = 4'd6      
      ;
      
   parameter
      AT = 8'd22,
      CR = 8'd13,
      HOME = 8'd12
      ;
            
   reg [2:0] estado = IDLE;
   reg [4:0] row = 5'd0;
    
   always @(posedge clk) begin
      case (estado)
         IDLE,ATR,ATC: 
            begin
               if (we) begin
                  data <= chr;
                  if (estado == ATR) begin
                     row <= chr[4:0];
                     estado <= ATC;
                  end
                  else if (estado == ATC) begin
                     addr <= {row,chr[4:0]};
                     estado <= IDLE;
                  end
                  else begin
                     busy <= 1'b1;
                     estado <= PCOMMAND;
                  end                  
               end
            end
         PCOMMAND:
            begin
               if (data == AT) begin
                  busy <= 1'b0;
                  estado <= ATR;               
               end
               else if (data == HOME) begin
                  addr <= 10'd0;
                  wescreen <= 1'b1;
                  dscreen <= 8'h20;
                  estado <= CLS;
               end
               else if (data == CR) begin
                  addr <= {(addr[8:5] + 4'd1),5'b0000};
                  busy <= 1'b0;
                  estado <= IDLE;
               end
               else begin
                  dscreen <= data;
                  wescreen <= 1'b1;
                  estado <= PUTCHAR;
               end
            end
         CLS:
            begin
               if (addr == 10'd544) begin
                  busy <= 1'b0;
                  estado <= IDLE;
                  wescreen <= 1'b0;
                  addr <= 10'd0;
               end
               else
                  addr <= addr + 10'd1;
            end
         PUTCHAR:
            begin
               wescreen <= 1'b0;
               busy <= 1'b0;
               addr <= addr + 10'd1;
               estado <= IDLE;
            end
      endcase
   end
endmodule 

module Nibble2Ascii(nibble, ascii);

	parameter LO = 1'b0, HI = 1'b1;

	output [7:0] ascii;
	input  [3:0] nibble;

	wire IsDecimal;

	assign IsDecimal = ((nibble < 4'd10)? HI : LO);

	assign ascii[7:4] = ((IsDecimal == HI)? 4'b0011:4'b0100);
	assign ascii[3:0] = nibble - ((IsDecimal == HI)? 4'd0:4'd9);

endmodule
   

module updater (
   input wire clk,
   input wire mode,
   //--------------------------
   input wire vga,
   input wire [11:0] joystick1,   // MXYZ SA UDLR BC 
   input wire [11:0] joystick2,   // MXYZ SA UDLR BC 
   input wire sdtest_progress,
   input wire sdtest_result,
   input wire flashtest_progress,
   input wire flashtest_result,
   input wire sdramtest_progress,
   input wire sdramtest_result,
	
	input wire sramtest_progress,
   input wire sramtest_result,
	
   input wire snes1_mode,
   input wire snes2_mode,
	
   input wire [15:0] flash_vendor_id,
   input wire [2:0] mousebutton,
   input wire [7:0] mX,
   input wire [7:0] mY,
   input wire hidetextwindow,
   //--------------------------
   output wire [5:0] r,
   output wire [5:0] g,
   output wire [5:0] b,
   output wire hsync,
   output wire vsync,
   output wire blank
   );
      
   reg [7:0] chr = 8'd0;
   reg we = 1'b0;
   wire busy;
	
	wire [7:0] mouse_x_d1;
   wire [7:0] mouse_x_d2;

	wire [7:0] mouse_y_d1;
   wire [7:0] mouse_y_d2;
   
	Nibble2Ascii mx1 (mX[7:4], mouse_x_d1);
	Nibble2Ascii mx2 (mX[3:0], mouse_x_d2);
	
	Nibble2Ascii my1 (mY[7:4], mouse_y_d1);
	Nibble2Ascii my2 (mY[3:0], mouse_y_d2);

   teletype teletipo (
     .clk(clk),
     .mode(mode),
     .chr(chr),
     .we(we),
     .busy(busy),
     .hidetextwindow(hidetextwindow),
     .r(r),
     .g(g),
     .b(b),
     .hsync(hsync),
     .vsync(vsync),
     .blank(blank)
     );
   
   reg [7:0] stringlist[0:2047];
   integer i;
   initial begin
      for (i=0;i<2048;i=i+1) begin
         stringlist[i] = 8'hFF;
      end
      stringlist[0] = 8'hFF; //8'd22;  // ADDRVGA
      stringlist[1] = 8'd3;
      stringlist[2] = 8'd10;
      stringlist[3] = 8'hFF;
      stringlist[4] = 8'hFF;
      stringlist[5] = 8'hFF;
      stringlist[6] = 8'hFF;
      stringlist[7] = 8'hFF;
      
      stringlist[8] = 8'd22;  // ADDRNTSC
      stringlist[9] = 8'd3;
      stringlist[10] = 8'd10;
      stringlist[11] = 8'hFF;
      stringlist[12] = 8'hFF;
      stringlist[13] = 8'hFF;
      stringlist[14] = 8'hFF;
      stringlist[15] = 8'hFF;

      stringlist[16] = 8'd22;  // ADDRPAL
      stringlist[17] = 8'd3;
      stringlist[18] = 8'd10;
      stringlist[19] = 8'hFF;
      stringlist[20] = 8'hFF;
      stringlist[21] = 8'hFF;
      stringlist[22] = 8'hFF;
      stringlist[23] = 8'hFF;
      
      stringlist[32] = "O";  // ADDROK
      stringlist[33] = "K";
      stringlist[34] = " ";
      stringlist[35] = " ";
      stringlist[36] = " ";
      stringlist[37] = 8'hFF;
      
      stringlist[38] = "E";  // ADDRERROR
      stringlist[39] = "R";
      stringlist[40] = "R";
      stringlist[41] = "O";
      stringlist[42] = "R";
      stringlist[43] = 8'hFF;
      
      stringlist[44] = "w";  // ADDRWAIT
      stringlist[45] = "a";
      stringlist[46] = "i";
      stringlist[47] = "t";
      stringlist[48] = " ";
      stringlist[49] = 8'hFF;
      
      stringlist[50] = 8'd22;  // ADDRATJOY1 line 1
      stringlist[51] = 8'd3;
      stringlist[52] = 8'd18;
      stringlist[53] = "U";
      stringlist[54] = "D";
      stringlist[55] = "L";
      stringlist[56] = "R";
      stringlist[57] = "A";
      stringlist[58] = "B";
      stringlist[59] = "C";
		stringlist[60] = " ";
		stringlist[61] = " ";
		stringlist[62] = " ";
		stringlist[63] = " ";
		stringlist[64] = " ";
		stringlist[65] = 8'hFF;
      stringlist[66] = 8'hFF;
		
		stringlist[67] = 8'd22;  // ADDRATJOY1 line 2
      stringlist[68] = 8'd4;
      stringlist[69] = 8'd18;
      stringlist[70] = "X";
      stringlist[71] = "Y";
      stringlist[72] = "Z";
      stringlist[73] = 8'hFF;
      stringlist[74] = "S";
      stringlist[75] = "M";
      stringlist[76] = 8'hFF;
      stringlist[77] = 8'hFF;
      stringlist[78] = 8'hFF;

      stringlist[79] = 8'd22;  // ADDRATMOUSE
      stringlist[80] = 8'd10;  //row
      stringlist[81] = 8'd18;  //col
      stringlist[82] = " ";
      stringlist[83] = " ";
      stringlist[84] = " ";
      stringlist[85] = " ";
      stringlist[86] = " ";
      stringlist[87] = " ";
      stringlist[88] = " ";
      stringlist[89] = " ";
      stringlist[90] = " ";
      stringlist[91] = " ";
      stringlist[92] = 8'hFF;

      stringlist[93] = 8'd22;  // ADDRATSD
      stringlist[94] = 8'd9;
      stringlist[95] = 8'd18;
      stringlist[96] = 8'hFF;

      stringlist[97] = 8'd22;  // ADDRATFLASH
      stringlist[98] = 8'd9;
      stringlist[99] = 8'd18;
      stringlist[100] = 8'hFF;
      
      stringlist[101] = "O";  // ADDROKFLASH
      stringlist[102] = "K";
      stringlist[103] = "-";
      stringlist[104] = " ";
      stringlist[105] = " ";
      stringlist[106] = 8'hFF;
      
      stringlist[107] = 8'd22;  // ADDRATSDRAM
      stringlist[108] = 8'd8;
      stringlist[109] = 8'd18;
      stringlist[110] = 8'hFF;
		
		stringlist[111] = 8'd22;  // ADDRATSRAM
      stringlist[112] = 8'd7;
      stringlist[113] = 8'd18;
      stringlist[114] = 8'hFF;
		
	   stringlist[115] = 8'd22;  // ADDRATJOY2 line 1
      stringlist[116] = 8'd5;
      stringlist[117] = 8'd18;
      stringlist[118] = "U";
      stringlist[119] = "D";
      stringlist[120] = "L";
      stringlist[121] = "R";
      stringlist[122] = "A";
      stringlist[123] = "B";
      stringlist[124] = "C";
		stringlist[125] = " ";
		stringlist[126] = " ";
		stringlist[127] = " ";
		stringlist[128] = " ";
		stringlist[129] = " ";
      stringlist[130] = 8'hFF;
      stringlist[131] = 8'hFF;
		
		stringlist[132] = 8'd22;  // ADDRATJOY2 line 2
      stringlist[133] = 8'd6;
      stringlist[134] = 8'd18;
      stringlist[135] = "X";
      stringlist[136] = "Y";
      stringlist[137] = "Z";
      stringlist[138] = 8'hFF;
      stringlist[139] = "S";
      stringlist[140] = "M";
      stringlist[141] = 8'hFF;
      stringlist[142] = 8'hFF;
      stringlist[143] = 8'hFF;
		
		
   end
   
   reg [10:0] addrstr = 11'd0;

   parameter
      ADDRVGA = 11'd0,
      ADDRNTSC = 11'd8,
      ADDRPAL = 11'd16,
      ADDROK = 11'd32,
      ADDRERROR = 11'd38,
      ADDRINPROGRESS = 11'd44,
      ADDRJOYSTATEJ1_L1 = 11'd50,
      ADDRJOYSTATEJ1_L2 = 11'd67,
      ADDRMOUSE = 11'd79,
      ADDRATSD = 11'd93,
      ADDRATFLASH = 11'd97,
      ADDROKFLASH = 11'd101,
      ADDRATSDRAM = 11'd107,
		ADDRATSRAM = 11'd111,
	   ADDRJOYSTATEJ2_L1 = 11'd115,
      ADDRJOYSTATEJ2_L2 = 11'd132
      ;

   parameter
      PUTVIDEO = 5'd0,
      PUTJOYTEST1_L1 = 5'd5,
      PUTJOYTEST1_L2 = 5'd6,
      PUTJOYTEST2_L1 = 5'd18,
      PUTJOYTEST2_L2 = 5'd19,
      PUTEARTEST = 5'd7,
      PUTSDTEST = 5'd8,
      PUTSDTEST1 = 5'd9,
      PUTFLASHTEST = 5'd10,
      PUTFLASHTEST1 = 5'd11,
      PUTMOUSETEST = 5'd13,
      PUTSDRAMTEST = 5'd14,
      PUTSDRAMTEST1 = 5'd15,
		
		PUTSRAMTEST = 5'd16,
      PUTSRAMTEST1 = 5'd17,
		
      SENDCHAR = 5'd28,
      SENDCHAR1 = 5'd29,
      SENDSTR = 5'd30,
      SENDSTR1 = 5'd31
      ;
   
   reg [4:0] estado = PUTJOYTEST1_L1, 
             retorno_de_sendchar = PUTJOYTEST1_L1, 
             retorno_de_sendstr = PUTJOYTEST1_L1;
      
   always @(posedge clk) begin
      case (estado)
         PUTVIDEO:
            begin
               if (vga == 1'b1)
                  addrstr <= ADDRVGA;
               else if (mode == 1'b0)
                  addrstr <= ADDRPAL;
               else
                  addrstr <= ADDRNTSC;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTJOYTEST1_L1;
            end
            
         PUTJOYTEST1_L1:
            begin										// MXYZ SA UDLR BC 
               stringlist[ADDRJOYSTATEJ1_L1+3]  <= (joystick1[5] == 1'b1)? "U" : " ";
               stringlist[ADDRJOYSTATEJ1_L1+4]  <= (joystick1[4] == 1'b1)? "D" : " ";
               stringlist[ADDRJOYSTATEJ1_L1+5]  <= (joystick1[3] == 1'b1)? "L" : " ";
               stringlist[ADDRJOYSTATEJ1_L1+6]  <= (joystick1[2] == 1'b1)? "R" : " ";
               stringlist[ADDRJOYSTATEJ1_L1+7]  <= (joystick1[6] == 1'b1)? "A" : " ";
               stringlist[ADDRJOYSTATEJ1_L1+8]  <= (joystick1[1] == 1'b1)? "B" : " ";
					stringlist[ADDRJOYSTATEJ1_L1+9]  <= (joystick1[0] == 1'b1)? "C" : " ";

					stringlist[ADDRJOYSTATEJ1_L1+11]  <= (snes1_mode == 1'b1)? "S" : " ";
					stringlist[ADDRJOYSTATEJ1_L1+12]  <= (snes1_mode == 1'b1)? "N" : " ";
					stringlist[ADDRJOYSTATEJ1_L1+13]  <= (snes1_mode == 1'b1)? "E" : " ";
					stringlist[ADDRJOYSTATEJ1_L1+14]  <= (snes1_mode == 1'b1)? "S" : " ";

					addrstr <= ADDRJOYSTATEJ1_L1;
               estado <= SENDSTR;
               retorno_de_sendstr <=  PUTJOYTEST1_L2;
            end
        
         PUTJOYTEST1_L2:
           begin										// MXYZ SA UDLR BC 
              stringlist[ADDRJOYSTATEJ1_L2+3]  <= (joystick1[10] == 1'b1)? "X" : " ";
              stringlist[ADDRJOYSTATEJ1_L2+4]  <= (joystick1[9] == 1'b1)? "Y" : " ";
              stringlist[ADDRJOYSTATEJ1_L2+5]  <= (joystick1[8] == 1'b1)? "Z" : " ";
              //stringlist[ADDRJOYSTATE2+6]  <= (joystick2[2] == 1'b1)? "R" : " ";
				  stringlist[ADDRJOYSTATEJ1_L2+6]  <=  " ";
              stringlist[ADDRJOYSTATEJ1_L2+7]  <= (joystick1[7] == 1'b1)? "S" : " ";
              stringlist[ADDRJOYSTATEJ1_L2+8]  <= (joystick1[11] == 1'b1)? "M" : " ";
				  //stringlist[ADDRJOYSTATE2+9]  <= (joystick2[0] == 1'b1)? "C" : " ";
              addrstr <= ADDRJOYSTATEJ1_L2;
              estado <= SENDSTR;
              retorno_de_sendstr <= PUTJOYTEST2_L1;
           end
			  
		   PUTJOYTEST2_L1:
            begin										// MXYZ SA UDLR BC 
               stringlist[ADDRJOYSTATEJ2_L1+3]  <= (joystick2[5] == 1'b1)? "U" : " ";
               stringlist[ADDRJOYSTATEJ2_L1+4]  <= (joystick2[4] == 1'b1)? "D" : " ";
               stringlist[ADDRJOYSTATEJ2_L1+5]  <= (joystick2[3] == 1'b1)? "L" : " ";
               stringlist[ADDRJOYSTATEJ2_L1+6]  <= (joystick2[2] == 1'b1)? "R" : " ";
               stringlist[ADDRJOYSTATEJ2_L1+7]  <= (joystick2[6] == 1'b1)? "A" : " ";
               stringlist[ADDRJOYSTATEJ2_L1+8]  <= (joystick2[1] == 1'b1)? "B" : " ";
					stringlist[ADDRJOYSTATEJ2_L1+9]  <= (joystick2[0] == 1'b1)? "C" : " ";
					
					stringlist[ADDRJOYSTATEJ2_L1+11]  <= (snes2_mode == 1'b1)? "S" : " ";
					stringlist[ADDRJOYSTATEJ2_L1+12]  <= (snes2_mode == 1'b1)? "N" : " ";
					stringlist[ADDRJOYSTATEJ2_L1+13]  <= (snes2_mode == 1'b1)? "E" : " ";
					stringlist[ADDRJOYSTATEJ2_L1+14]  <= (snes2_mode == 1'b1)? "S" : " ";
					
					addrstr <= ADDRJOYSTATEJ2_L1;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTJOYTEST2_L2;
            end
        
         PUTJOYTEST2_L2:
           begin										// MXYZ SA UDLR BC 
              stringlist[ADDRJOYSTATEJ2_L2+3]  <= (joystick2[10] == 1'b1)? "X" : " ";
              stringlist[ADDRJOYSTATEJ2_L2+4]  <= (joystick2[9] == 1'b1)? "Y" : " ";
              stringlist[ADDRJOYSTATEJ2_L2+5]  <= (joystick2[8] == 1'b1)? "Z" : " ";
              //stringlist[ADDRJOYSTATE2+6]  <= (joystick2[2] == 1'b1)? "R" : " ";
				  stringlist[ADDRJOYSTATEJ2_L2+6]  <=  " ";
              stringlist[ADDRJOYSTATEJ2_L2+7]  <= (joystick2[7] == 1'b1)? "S" : " ";
              stringlist[ADDRJOYSTATEJ2_L2+8]  <= (joystick2[11] == 1'b1)? "M" : " ";
				  //stringlist[ADDRJOYSTATE2+9]  <= (joystick2[0] == 1'b1)? "C" : " ";
              addrstr <= ADDRJOYSTATEJ2_L2;
              estado <= SENDSTR;
              retorno_de_sendstr <= PUTSDTEST;
           end

         PUTSDTEST:
            begin
               addrstr <= ADDRATSD;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTSDTEST1;
            end
         PUTSDTEST1:
            begin
               if (sdtest_progress == 1'b1)
                  addrstr <= ADDRINPROGRESS;
               else if (sdtest_result == 1'b1)
                  addrstr <= ADDROK;
               else
                  addrstr <= ADDRERROR;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTMOUSETEST;
            end
    
            
         PUTMOUSETEST:
            begin
               stringlist[ADDRMOUSE+9] <= (mousebutton[0]==1'b1)? "L" : " ";
               stringlist[ADDRMOUSE+10] <= (mousebutton[2]==1'b1)? "M" : " ";
               stringlist[ADDRMOUSE+11] <= (mousebutton[1]==1'b1)? "R" : " ";
					
               stringlist[ADDRMOUSE+3] <= mouse_x_d1;
               stringlist[ADDRMOUSE+4] <= mouse_x_d2;

               stringlist[ADDRMOUSE+6] <= mouse_y_d1;
               stringlist[ADDRMOUSE+7] <= mouse_y_d2;

               addrstr <= ADDRMOUSE;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTSRAMTEST;
            end
				
			PUTSRAMTEST:
            begin
               addrstr <= ADDRATSRAM;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTSRAMTEST1;
            end
         PUTSRAMTEST1:
            begin
               if (sramtest_progress == 1'b1)
                  addrstr <= ADDRINPROGRESS;
               else if (sramtest_result == 1'b1)
                  addrstr <= ADDROK;
               else
                  addrstr <= ADDRERROR;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTSDRAMTEST;
            end
               
         PUTSDRAMTEST:
            begin
               addrstr <= ADDRATSDRAM;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTSDRAMTEST1;
            end
         PUTSDRAMTEST1:
            begin
               if (sdramtest_progress == 1'b1)
                  addrstr <= ADDRINPROGRESS;
               else if (sdramtest_result == 1'b1)
                  addrstr <= ADDROK;
               else
                  addrstr <= ADDRERROR;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTJOYTEST1_L1;
            end
            
         SENDSTR:
            begin
               chr <= stringlist[addrstr];
               addrstr <= addrstr + 11'd1;
               estado <= SENDSTR1;
            end
         SENDSTR1:
            begin
               if (chr == 8'hFF)
                  estado <= retorno_de_sendstr;
               else begin
                  estado <= SENDCHAR;
                  retorno_de_sendchar <= SENDSTR;
               end
            end
         
         SENDCHAR:
            begin
               if (busy == 1'b0) begin
                  we <= 1'b1;
                  estado <= SENDCHAR1;
               end
            end
         SENDCHAR1:
            begin
               we <= 1'b0;
               estado <= retorno_de_sendchar;
            end
      endcase
   end
endmodule

