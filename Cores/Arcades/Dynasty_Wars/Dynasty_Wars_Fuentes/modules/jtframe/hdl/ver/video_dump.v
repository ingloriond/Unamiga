////////////////////////////////////////////////////////////////////
// video output dump
// this is a binary bile with 32 bits per pixel. First 8 bits are the alpha, and set to 0xFF
// The rest are RGB in 8-bit format
// There is no dump while blanking. The inputs pxl_hb and pxl_vb are high during blanking
// The linux tool "convert" can process the raw stream and separate it into individual frames
// automatically

`timescale 1ns/1ps

module video_dump(
    input        pxl_clk,
    input        pxl_cen,
    input        pxl_hb,
    input        pxl_vb,
    input [ 3:0] red,
    input [ 3:0] green,
    input [ 3:0] blue,
    input [31:0] frame_cnt
    //input        downloading
);


`ifdef DUMP_VIDEO
integer fvideo;
initial begin
    fvideo = $fopen("video.raw","wb");
end

wire [31:0] video_dump = { 8'hff, {2{blue}}, {2{green}}, {2{red}} };

// Define VIDEO_START with the first frame number for which
// video will be dumped. If undefined, it will start from frame 0
`ifndef VIDEO_START
`define VIDEO_START 0
`endif

always @(posedge pxl_clk) if(pxl_cen && frame_cnt>=`VIDEO_START ) begin
    if( !pxl_hb && !pxl_vb ) $fwrite(fvideo,"%u", video_dump);
end

`endif

endmodule