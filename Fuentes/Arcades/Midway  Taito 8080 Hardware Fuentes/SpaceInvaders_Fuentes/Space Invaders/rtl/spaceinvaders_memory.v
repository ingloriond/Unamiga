
module spaceinvaders_memory(
input	wire			Clock,
input	wire			RW_n,
input	wire	[15:0]Addr,
input	wire	[15:0]Ram_Addr,
output wire	 [7:0]Ram_out,
input	wire	 [7:0]Ram_in,
output reg	 [7:0]Rom_out
);

wire [7:0]rom_data_0;
wire [7:0]rom_data_1;
wire [7:0]rom_data_2;
wire [7:0]rom_data_3;



sprom #(
	.init_file("./roms/invaders_h.mem"),
	.widthad_a(11),
	.width_a(8))
u_rom_h (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_0)
	);

sprom #(
	.init_file("./roms/invaders_g.mem"),
	.widthad_a(11),
	.width_a(8))
u_rom_g (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_1)
	);
	
sprom #(
	.init_file("./roms/invaders_f.mem"),
	.widthad_a(11),
	.width_a(8))
u_rom_f (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_2)
	);
	
sprom #(
	.init_file("./roms/invaders_e.mem"),
	.widthad_a(11),
	.width_a(8))
u_rom_e (
	.clock(Clock),
	.Address(Addr[10:0]),
	.q(rom_data_3)
	);

	
always @(Addr, rom_data_0, rom_data_1, rom_data_2, rom_data_3) begin
	Rom_out = 8'b00000000;
		case (Addr[13:11])
			3'b000 : Rom_out = rom_data_0;
			3'b001 : Rom_out = rom_data_1;
			3'b010 : Rom_out = rom_data_2;
			3'b011 : Rom_out = rom_data_3;
			default : Rom_out = 8'b00000000;
		endcase
end
		
spram #(
	.addr_width_g(13),
	.data_width_g(8)) 
u_ram0(
	.address(Ram_Addr[12:0]),
	.clken(1'b1),
	.clock(Clock),
	.data(Ram_in),
	.wren(~RW_n),
	.q(Ram_out)
	);
endmodule 