// Dummy block for simulation only

module arcade_rotate_fx #(parameter WIDTH=320, HEIGHT=240, DW=8, CCW=0)
(
    input         clk_video,
    input         ce_pix,

    input[DW-1:0] RGB_in,
    input         HBlank,
    input         VBlank,
    input         HSync,
    input         VSync,

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
    
    input   [2:0] fx,
    input         forced_scandoubler,
    input         no_rotate
);

endmodule // arcade_rotate_fx