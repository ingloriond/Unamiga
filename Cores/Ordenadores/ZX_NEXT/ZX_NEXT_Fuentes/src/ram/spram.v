-- Single Port Async Read/Write RAM
-- from https://riptutorial.com/verilog/example/19612/single-port-async-read-write-ram

module ram_single_port_ar_aw #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WITDH = 3
)(
  input                       we,    // write enable
  input                       oe,    // output enable
  input  [(ADDR_WITDH-1):0]   waddr, // write address
  input  [(DATA_WIDTH-1):0]   wdata, // write data
  input                       raddr, // read adddress
  output [(DATA_WIDTH-1):0]   rdata  // read data
);

  reg [(DATA_WIDTH-1):0]      ram [0:2**ADDR_WITDH-1];
  reg [(DATA_WIDTH-1):0]      data_out;

  assign rdata = (oe && !we) ? data_out : {DATA_WIDTH{1'bz}};

  always @*
  begin : mem_write
    if (we) begin
      ram[waddr] = wdata;
    end
  end

  always @* // if anything below changes (i.e. we, oe, raddr), execute this    
  begin : mem_read
    if (!we && oe) begin
      data_out = ram[raddr];
    end
  end

endmodule