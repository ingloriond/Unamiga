`timescale 1ns/1ps

/* verilator lint_off STMTDLY */

module mister_test;

wire [31:0] frame_cnt;
wire VGA_HS, VGA_VS;
wire led;

wire            downloading;
wire    [21:0]  ioctl_addr;
wire    [ 7:0]  ioctl_data;
wire cen12, cen6, cen3, cen1p5, clk, clk27, rst;
wire [21:0]  sdram_addr;
wire [15:0]  data_read;
wire SPI_SCK, SPI_DO, SPI_DI, SPI_SS2, CONF_DATA0;

wire [15:0] SDRAM_DQ;
wire [12:0] SDRAM_A;
wire [ 1:0] SDRAM_BA;
wire SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE,  SDRAM_nCAS,
     SDRAM_nRAS, SDRAM_nCS,  SDRAM_CLK,  SDRAM_CKE;

wire [5:0] VGA_R, VGA_G, VGA_B;

`ifdef CLK24
    parameter CLK_SPEED=24;
`else
    parameter CLK_SPEED=12;
`endif

mist_dump u_dump(
    .VGA_VS     ( VGA_VS    ),
    .led        ( led       ),
    .frame_cnt  ( frame_cnt )
);

test_harness #(.sdram_instance(0),.GAME_ROMNAME(`GAME_ROM_PATH),
    .TX_LEN(887808), .CLK_SPEED(CLK_SPEED) ) u_harness(
    .rst         ( rst           ),
    .clk         ( clk           ),
    .clk27       ( clk27         ),
    .cen12       ( cen12         ),
    .cen6        ( cen6          ),
    .cen3        ( cen3          ),
    .cen1p5      ( cen1p5        ),
    .downloading ( downloading   ),
    .ioctl_addr  ( ioctl_addr    ),
    .ioctl_data  ( ioctl_data    ),
    .SPI_SCK     ( SPI_SCK       ),
    .SPI_SS2     ( SPI_SS2       ),
    .SPI_DI      ( SPI_DI        ),
    .SPI_DO      ( SPI_DO        ),
    .CONF_DATA0  ( CONF_DATA0    ),
    // Video dumping. VGA_ signals are equal to game signals in simulation.
    .HS          ( VGA_HS    ),
    .VS          ( VGA_VS    ),
    .red         ( VGA_R[3:0]),
    .green       ( VGA_G[3:0]),
    .blue        ( VGA_B[3:0]),
    .frame_cnt   ( frame_cnt ),
    // SDRAM
    .SDRAM_DQ    ( SDRAM_DQ  ),
    .SDRAM_A     ( SDRAM_A   ),
    .SDRAM_DQML  ( SDRAM_DQML),
    .SDRAM_DQMH  ( SDRAM_DQMH),
    .SDRAM_nWE   ( SDRAM_nWE ),
    .SDRAM_nCAS  ( SDRAM_nCAS),
    .SDRAM_nRAS  ( SDRAM_nRAS),
    .SDRAM_nCS   ( SDRAM_nCS ),
    .SDRAM_BA    ( SDRAM_BA  ),
    .SDRAM_CLK   ( SDRAM_CLK ),
    .SDRAM_CKE   ( SDRAM_CKE ),
    // unused
    .H0          ( 1'bz      ),
    .autorefresh ( 1'bz      ),
    .sdram_addr  ( 22'bz     ),
    .data_read   (),
    .loop_rst    (),
    .ioctl_wr    ()
);

`ifdef SIM_UART
wire UART_RX, UART_TX;
assign UART_RX = UART_TX; // make a loop!
`endif

`SYSTOP #(.CLK_SPEED(CLK_SPEED)) UUT(
    .CLOCK_27   ( { 1'b0, clk27 }),
    .VGA_R      ( VGA_R     ),
    .VGA_G      ( VGA_G     ),
    .VGA_B      ( VGA_B     ),
    .VGA_HS     ( VGA_HS    ),
    .VGA_VS     ( VGA_VS    ),
    // SDRAM interface
    .SDRAM_DQ   ( SDRAM_DQ  ),
    .SDRAM_A    ( SDRAM_A   ),
    .SDRAM_DQML ( SDRAM_DQML),
    .SDRAM_DQMH ( SDRAM_DQMH),
    .SDRAM_nWE  ( SDRAM_nWE ),
    .SDRAM_nCAS ( SDRAM_nCAS),
    .SDRAM_nRAS ( SDRAM_nRAS),
    .SDRAM_nCS  ( SDRAM_nCS ),
    .SDRAM_BA   ( SDRAM_BA  ),
    .SDRAM_CLK  ( SDRAM_CLK ),
    .SDRAM_CKE  ( SDRAM_CKE ),
    `ifdef SIM_UART
    .UART_RX    ( UART_RX   ),
    .UART_TX    ( UART_TX   ),
    `endif    
    // SPI interface to arm io controller
    .SPI_DO     ( SPI_DO    ),
    .SPI_DI     ( SPI_DI    ),
    .SPI_SCK    ( SPI_SCK   ),
    .SPI_SS2    ( SPI_SS2   ),
    .SPI_SS3    ( 1'b0      ),
    .SPI_SS4    ( 1'b0      ),
    .CONF_DATA0 ( CONF_DATA0),
    // sound
    .AUDIO_L    ( AUDIO_L   ),
    .AUDIO_R    ( AUDIO_R   ),
    // unused
    .LED        ( led       )
);



    input         CLK_50M,
    input         RESET,
    inout  [44:0] HPS_BUS,
    output        VGA_CLK,
    output        VGA_CE,
    output  [7:0] VGA_R,
    output  [7:0] VGA_G,
    output  [7:0] VGA_B,
    output        VGA_HS,
    output        VGA_VS,
    output        VGA_DE,
    output        HDMI_CLK,
    output        HDMI_CE,
    output  [7:0] HDMI_R,
    output  [7:0] HDMI_G,
    output  [7:0] HDMI_B,
    output        HDMI_HS,
    output        HDMI_VS,
    output        HDMI_DE,
    output  [1:0] HDMI_SL,
    output  [7:0] HDMI_ARX,
    output  [7:0] HDMI_ARY,
    output        LED_USER,
    output  [1:0] LED_POWER,
    output  [1:0] LED_DISK,
    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,
    output        AUDIO_S,
    output        SDRAM_CLK,
    output        SDRAM_CKE,
    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE,


endmodule