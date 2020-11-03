module jtframe_z80wait #(parameter devcnt=2)(
    input       rst_n,
    input       clk,
    input       cpu_cen,
    // manage access to shared memory
    input  [devcnt-1:0] dev_busy,
    // manage access to ROM data from SDRAM
    input       rom_cs,
    input       rom_ok,

    output reg  wait_n
);

/////////////////////////////////////////////////////////////////
// wait_n generation
reg last_rom_cs, last_chwait;
wire rom_cs_posedge = !last_rom_cs && rom_cs;

reg rom_free, rom_clr;


always @(*) begin
    rom_clr = ~rom_free  | ( rom_ok   & rom_free);
end

wire anydev_busy = |dev_busy;
wire bad_rom = rom_cs && !rom_ok;

always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        wait_n   <= 1'b1;
        rom_free <= 1'b0;
    end else begin
        last_rom_cs <= rom_cs;

        if( anydev_busy || rom_cs_posedge || bad_rom ) begin
            if( rom_cs_posedge || bad_rom ) rom_free  <= 1'b1;
            wait_n <= 1'b0;
        end else begin
            wait_n   <=  rom_clr;
            rom_free <= !rom_clr;
        end
    end


endmodule // jtframe_z80wait