/*  This file is part of JTFRAME.
    JTFRAME program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTFRAME program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTFRAME.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 2-5-2020 */


// Generic video timing generator
// By default vertical blanking and sync toggle with horizontal blanking and sync
// but some games make these signals toggle in the middle of the vertical ones
// See Side Arms for an example
// By default, H/V counters end with the blanking signal, for some games it
// may be useful to define the end count differently
// Depending on how the graphic hardware is designed, H/V count start and end values
// can be important, as well as when signals toggle (like in a 8-multiple of H)
// but these limitations can be trade off for different ones if the design is changed
// A default VS pulse of three lines and HS pulse of 4.5us will fit the TV standard
// but some games use different values
// See the parameter definition below to alter the needed parameters when
// instantiating the module

module jtframe_vtimer(
    input               clk,
    input               pxl_cen,
    output  reg [8:0]   vdump,
    output  reg [8:0]   vrender,
    output  reg [8:0]   vrender1,
    output  reg [8:0]   H,
    output  reg         Hinit,
    output  reg         Vinit,
    output  reg         LHBL,
    output  reg         LVBL,
    output  reg         HS,
    output  reg         VS
);

reg LVBL2, LVBL1;

`ifdef SIMULATION
initial begin
    Hinit    = 0;
    Vinit    = 0;
    LHBL     = 0;
    LVBL     = 1;
    LVBL1    = 1;
    LVBL2    = 1;
    HS       = 0;
    VS       = 0;
    H        = 0;
    vrender1 = 0;
    vrender  = 0;
    vdump    = 0;
end
`endif

// Default values suit Contra arcade
parameter [8:0] V_START  = 9'd0,
                VB_START = 9'd239,
                VB_END   = 9'd255,
                VCNT_END = VB_END,
                VS_START = 9'd244,
                VS_END   = (VS_START+9'd3),
                HB_END   = 9'd395,
                HB_START = HB_END-9'd116,
                HCNT_END = HB_END,
                HS_START = 9'd330,
                HS_END   = HS_START+9'd27, // Default 4.5us for a 6MHz clock
                H_VB     = HB_START,
                H_VS     = HS_START,
                H_VNEXT  = HB_END,
                HINIT    = HCNT_END;

// H counter
always @(posedge clk) if(pxl_cen) begin
    Hinit <= H == HINIT;
    H     <= H == HCNT_END ? 9'd0 : (H+9'd1);
end

always @(posedge clk) if(pxl_cen) begin
    if( H == H_VNEXT ) begin
        Vinit    <= vdump==VB_END;
        vrender1 <= vrender1==VCNT_END ? V_START : vrender1 + 9'd1;
        vrender  <= vrender1;
        vdump    <= vrender;
    end

    if( H == HB_START ) begin
        LHBL <= 0;
    end else if( H == HB_END ) LHBL <= 1;
    if( H == H_VB ) begin
        { LVBL, LVBL1 } <= { LVBL1, LVBL2 };
        case( vrender1 )
            VB_START: LVBL2 <= 0;
            VB_END:   LVBL2 <= 1;
            default:;
        endcase // vdump
    end

    if (H==HS_START) begin
        HS <= 1;
    end
    if( H==H_VS ) begin
        if (vdump==VS_START) VS <= 1;
        if (vdump==VS_END  ) VS <= 0;
    end

    if (H==HS_END) HS <= 0;
end

`ifdef SIMULATION_VTIMER
reg LVBL_Last, LHBL_last, VS_last, HS_last;

wire new_line  = LHBL_last && !LHBL;
wire new_frame = LVBL_Last && !LVBL;
wire new_HS = HS && !HS_last;
wire new_VS = VS && !VS_last;

integer vbcnt=0, vcnt=0, hcnt=0, hbcnt=0, vs0, vs1, hs0, hs1;
integer framecnt=0;

always @(posedge clk) if(pxl_cen) begin
    LHBL_last <= LHBL;
    HS_last   <= HS;
    VS_last   <= VS;
    if( new_HS ) hs1 <= hbcnt;
    if( new_VS ) vs1 <= vbcnt;
    if( new_line ) begin
        LVBL_Last <= LVBL;
        if( new_frame ) begin
            if( framecnt>0 ) begin
                $display("VB count = %3d (sync at %2d)", vbcnt, vs1 );
                $display("vdump  total = %3d (%.2f Hz)", vcnt, 6e6/(hcnt*vcnt) );
                $display("HB count = %3d (sync at %2d)", hbcnt, hs1 );
                $display("H  total = %3d (%.2f Hz)", hcnt, 6e6/hcnt );
                $display("-------------" );
            end
            vbcnt <= 1;
            vcnt  <= 1;
            framecnt <= framecnt+1;
        end else begin
            vcnt <= vcnt+1;
            if( !LVBL ) vbcnt <= vbcnt+1;
        end
        hbcnt <= 1;
        hcnt  <= 1;
    end else begin
        hcnt <= hcnt+1;
        if( !LHBL ) hbcnt <= hbcnt+1;
    end
end
`endif

endmodule
