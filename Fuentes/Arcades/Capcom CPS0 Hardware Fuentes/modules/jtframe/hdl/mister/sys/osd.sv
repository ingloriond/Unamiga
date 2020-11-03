// A simple OSD implementation. Can be hooked up between a cores
// VGA output and the physical VGA pins

// The OSD has two possible modes
//      information display
//      OSD Menu
//      The information display can be configured in run time
//      for specific coordinates and area
//      OSD menu location is determined at compile time

module osd(
    input         clk_sys,

    input         io_osd,
    input         io_strobe,
    input  [15:0] io_din,

    input  [1:0]  rotate, //[0] - rot [1] - left or right

    input         clk_video,
    input  [23:0] din,
    output [23:0] dout,
    input         de_in,
    output reg    de_out,
    output reg    osd_status
);

wire [1:0] rot = 2'b00; // rotation is not ready yet

parameter [11:0] OSD_X_OFFSET = 12'd0;
parameter [11:0] OSD_Y_OFFSET = 12'd0;
parameter [ 2:0] OSD_COLOR    = 3'b111;

localparam OSD_WIDTH    = 12'd256; //256
localparam OSD_HEIGHT   = 12'd64;

// wire [11:0] osd_width  = OSD_WIDTH;
// wire [11:0] osd_height = OSD_HEIGHT;

reg [11:0] osd_width, osd_height;

always @(posedge clk_sys) begin
    osd_width  <= rot[0] ? 12'd128 : 12'd256;
    osd_height <= rot[0] ? 12'd96 : 12'd64;
end

reg        osd_enable;
(* ramstyle = "no_rw_check" *) reg  [7:0] osd_buffer[4096];

`ifdef SIMULATION
integer cnt;
initial begin : clear_mem
    $display("OSD memory cleared");
    for( cnt=0; cnt<4096; cnt=cnt+1 ) osd_buffer[cnt]=8'h00;
end
`endif

reg        info = 0;
reg  [8:0] infoh;
reg  [8:0] infow;
reg [11:0] infox;
reg [21:0] infoy;
reg [21:0] hrheight;

//////////// SPI RX
reg        highres = 0;
always@(posedge clk_sys) begin : SPIRX
    reg [11:0] bcnt;
    reg  [7:0] cmd;
    reg        has_cmd;
    reg        old_strobe;

    hrheight <= info ? infoh : (osd_height<<highres);

    old_strobe <= io_strobe;

    if(~io_osd) begin
        bcnt <= 0;
        has_cmd <= 0;
        cmd <= 0;
        if(cmd[7:4] == 4) osd_enable <= cmd[0];
    end else begin
        if(~old_strobe & io_strobe) begin
            if(!has_cmd) begin
                // Grab the command code first
                // Once the command is set, you need to
                // set io_osd down again before sending a new
                // command
                has_cmd <= 1;
                cmd <= io_din[7:0];
                // command 0x40: OSDCMDENABLE, OSDCMDDISABLE
                // 0x4? set display coordinates
                // 0x41 enable OSD
                // 0x42 enable INFO display
                if(io_din[7:4] == 4) begin
                    if(!io_din[0]) {osd_status,highres} <= 0;
                    else {osd_status,info} <= {~io_din[2],io_din[2]};
                    bcnt <= 0;
                end
                // command 0x20: OSDCMDWRITE
                // 0x2? set video memory command
                // 0x24 enable high resolution
                if(io_din[7:4] == 2) begin
                    if(io_din[3]) highres <= 1;
                    bcnt <= {io_din[3:0], 8'h00};
                end
            end else begin
                // with the command code previously acquired
                // get extra pieces of information
                // command 0x40: OSDCMDENABLE, OSDCMDDISABLE
                if(cmd[7:4] == 4) begin
                    if(bcnt == 0) infox <= io_din[11:0];
                    if(bcnt == 1) infoy <= io_din[11:0];
                    if(bcnt == 2) infow <= {io_din[5:0], 3'b000};
                    if(bcnt == 3) infoh <= {io_din[5:0], 3'b000};
                end

                // command 0x20: OSDCMDWRITE
                // fill OSD video memory
                if(cmd[7:4] == 2) osd_buffer[bcnt] <= io_din[7:0];

                bcnt <= bcnt + 1'd1;
            end
        end
    end
end

// CE_CTRL
(* direct_enable *) reg ce_pix;
integer pxcnt = 0;
always @(negedge clk_video) begin : CE_CTRL
    integer pixsz, pixcnt;
    reg deD;

    pxcnt <= pxcnt + 1;
    deD <= de_in;

    pixcnt <= pixcnt + 1;
    if(pixcnt == pixsz) pixcnt <= 0;
    ce_pix <= !pixcnt;

    if(~deD && de_in) pxcnt <= 0;

    if(deD && ~de_in) begin
        pixsz  <= (((pxcnt+1'b1) >> 9) > 1) ? (((pxcnt+1'b1) >> 9) - 1) : 0;
        pixcnt <= 0;
    end
end

reg [ 2:0] osd_de;
reg        osd_pixel;
reg [21:0] next_v_cnt;

reg v_cnt_below320, v_cnt_below640, v_cnt_below960;

reg [21:0] v_cnt;
reg [21:0] v_osd_start_320, v_osd_start_640, v_osd_start_960, v_osd_start_other;

reg [11:0] osd_buffer_addr;
reg [10:0] back_buffer_addr;

`ifndef OSD_NOBCK
reg  [7:0] back_buffer[8*256];
wire [7:0] back_byte = back_buffer[ back_buffer_addr ];
reg        back_pixel;
`else 
wire       back_pixel = 1'b1;
`endif

// pipeline the comparisons a bit
always @(posedge clk_video) if(ce_pix) begin
    v_cnt_below320 <= next_v_cnt < 320;
    v_cnt_below640 <= next_v_cnt < 640;
    v_cnt_below960 <= next_v_cnt < 960;
    v_osd_start_320   <= ((next_v_cnt-hrheight)>>1) + OSD_Y_OFFSET;
    v_osd_start_640   <= ((next_v_cnt-(hrheight<<1))>>1) + OSD_Y_OFFSET;
    v_osd_start_960   <= ((next_v_cnt-(hrheight + (hrheight<<1)))>>1) + OSD_Y_OFFSET;
    v_osd_start_other <= ((next_v_cnt-(hrheight<<2))>>1) + OSD_Y_OFFSET;
end

always @(posedge clk_video) begin : GEOMETRY
    reg        deD;
    reg  [1:0] osd_div;
    reg  [1:0] multiscan;
    reg  [7:0] osd_byte; 
    reg [23:0] h_cnt;
    reg [21:0] dsp_width;
    reg [21:0] osd_vcnt;
    reg [21:0] h_osd_start;
    reg [21:0] v_osd_start;
    reg [21:0] osd_hcnt;
    reg        osd_de1,osd_de2;
    reg  [1:0] osd_en;
    reg  [2:0] osd_idx;
    `ifndef OSD_NOBCK
    reg  [2:0] back_idx;
    `endif

    if(ce_pix) begin

        deD <= de_in;
        if(~&h_cnt) h_cnt <= h_cnt + 1'd1;

        if(~&osd_hcnt) osd_hcnt <= osd_hcnt + 1'd1;
        if (h_cnt == h_osd_start) begin
            osd_de[0] <= osd_en[1] && hrheight && (osd_vcnt < hrheight);
            osd_hcnt <= 0;
        end
        if (osd_hcnt+1 == (info ? infow : osd_width)) osd_de[0] <= 0;

        // falling edge of de
        if(!de_in && deD) dsp_width <= h_cnt[21:0];

        // rising edge of de
        if(de_in && !deD) begin
            h_cnt <= 0;
            v_cnt <= next_v_cnt;
            next_v_cnt <= next_v_cnt+1'd1; 
            h_osd_start <= info ? infox : (((dsp_width - osd_width)>>1) + OSD_X_OFFSET - 2'd2);

            if(h_cnt > {dsp_width, 2'b00}) begin
                v_cnt <= 0;
                next_v_cnt <= 'd1;

                osd_en <= (osd_en << 1) | osd_enable;
                if(~osd_enable) osd_en <= 0;

                if(v_cnt_below320) begin
                    multiscan <= 0;
                    v_osd_start <= info ? infoy : v_osd_start_320;
                end
                else if(v_cnt_below640) begin
                    multiscan <= 1;
                    v_osd_start <= info ? (infoy<<1) : v_osd_start_640;
                end
                else if(v_cnt_below960) begin
                    multiscan <= 2;
                    v_osd_start <= info ? (infoy + (infoy << 1)) : v_osd_start_960;
                end
                else begin
                    multiscan <= 3;
                    v_osd_start <= info ? (infoy<<2) : v_osd_start_other;
                end
            end

            osd_div <= osd_div + 1'd1;
            if(osd_div == multiscan) begin
                osd_div <= 0;
                if(~&osd_vcnt) osd_vcnt <= osd_vcnt + 1'd1;
            end
            if(v_osd_start == next_v_cnt) {osd_div, osd_vcnt} <= 0;
        end

        // pixels
        osd_buffer_addr <= rot[0] ?
                    ({ osd_hcnt[7:4], osd_vcnt[7:0] } ^ { {4{~rot[1]}}, {8{rot[1]}} }) :
                    // no rotation
                    {osd_vcnt[6:3], osd_hcnt[7:0]};
        osd_byte  <= osd_buffer[osd_buffer_addr];
        osd_idx   <= rot[0] ?
                    ( osd_hcnt[2:0] ^ {3{~rot[1]}} )
                    // no rotation
                    : osd_vcnt[2:0];
        osd_pixel <= osd_byte[ osd_idx ];
        `ifndef OSD_NOBCK
        back_buffer_addr <= rot[0] ?
                    ({ osd_hcnt[6:4], osd_vcnt[7:0] } ^ { {3{~rot[1]}}, {8{rot[1]}} }) :
                    // no rotation
                    {osd_vcnt[6:4], osd_hcnt[7:0]};
        back_idx   <= rot[0]  ? 
                    (osd_hcnt[4:2] ^{3{~rot[1]}}) :
                    // no rotation:
                    osd_vcnt[3:1];
        back_pixel <= info ? 1'b0 : back_byte[ back_idx ]; // do not use background for the info box
        `endif

        osd_de[2:1] <= osd_de[1:0];

    end
end

reg [23:0] rdout;
assign dout = rdout;

reg [23:0] osd_rdout, normal_rdout;
reg osd_mux;
reg de_dly;

always @(posedge clk_video) begin
    normal_rdout <= din;
    osd_rdout <= {{ {1{osd_pixel}}, {2{OSD_COLOR[2]&~back_pixel}}, din[23:19]},// 23:16
                  { {1{osd_pixel}}, {2{OSD_COLOR[1]&~back_pixel}}, din[15:11]},// 15:8
                  { {1{osd_pixel}}, {2{OSD_COLOR[0]&~back_pixel}}, din[7:3]}}; //  7:0
    osd_mux <= ~osd_de[2];
    rdout  <= osd_mux ? normal_rdout : osd_rdout;
    de_dly <= de_in;
    de_out <= de_dly;
end

initial begin
`ifdef SIMULATION
$readmemh("back_buffer.hex",back_buffer);
`else
back_buffer = '{ 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC0, 8'hF0, 8'hF8, 8'hFC, 8'hFC, 8'hFC, 
8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 
8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hFC, 8'hF0, 8'hF0, 8'hF0, 8'hC0, 8'hC0, 8'hC0, 8'hC0, 
8'hC0, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h80, 8'hC0, 8'hF0, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 
8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hFC, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF9, 
8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 
8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 
8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 
8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 
8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hC8, 8'hC0, 
8'hC0, 8'h80, 8'h80, 8'h80, 8'h80, 8'h80, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h80, 
8'hE0, 8'hF8, 8'hFE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'h3F, 8'h0F, 8'h07, 8'h01, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h01, 
8'h01, 8'h01, 8'h01, 8'h05, 8'h07, 8'h07, 8'h37, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'hBF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 
8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h7F, 8'h3F, 
8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 
8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h3F, 8'h0F, 
8'h03, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC0, 8'hF0, 8'hFC, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 
8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 
8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hF0, 8'hF0, 8'hF0, 8'hC0, 8'hC0, 8'hC0, 8'hC0, 8'h40, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h80, 8'hC0, 8'hC0, 8'hF0, 8'hFC, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h7F, 
8'h1F, 8'h0F, 8'h03, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h80, 8'hE0, 8'hF8, 8'hFC, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h7F, 8'h1F, 8'h07, 8'h01, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h3F, 8'h7F, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hF9, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 
8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hF8, 8'hFC, 8'hFC, 8'hFC, 
8'hFC, 8'hFC, 8'hFE, 8'hFE, 8'hFE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h7F, 8'h3F, 8'h1F, 8'h07, 8'h01, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h80, 
8'hE0, 8'hF8, 8'hFE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h3F, 8'h0F, 8'h03, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h01, 8'h03, 8'h03, 8'h07, 8'h0F, 8'h0F, 8'h1F, 8'h1F, 
8'h3F, 8'h3F, 8'h7F, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h7F, 8'h7F, 8'h3F, 
8'h3F, 8'h1F, 8'h1F, 8'h0F, 8'h0F, 8'h07, 8'h03, 8'h03, 8'h01, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC0, 8'hF0, 8'hFC, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
8'hFF, 8'h7F, 8'h1F, 8'h0F, 8'h03, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h01, 8'h01, 8'h03, 8'h03, 8'h03, 8'h07, 8'h07, 8'h07, 8'h0F, 8'h0F, 8'h0F, 8'h0F, 
8'h0F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 
8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 
8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h0F, 8'h0F, 8'h0F, 8'h0F, 8'h0F, 8'h0F, 
8'h07, 8'h07, 8'h07, 8'h07, 8'h03, 8'h03, 8'h03, 8'h01, 8'h01, 8'h01, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h07, 
8'h07, 8'h07, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 
8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h1F, 8'h07, 
8'h01, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 
8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00 };
`endif
end

endmodule