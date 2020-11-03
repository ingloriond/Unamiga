wire [8:0] _HN;
wire [7:0] _VN;
wire [7:0] _VPOS;
wire GND;
wire Net__U10_Pad2_;
wire Net__U10_Pad3_;
wire Net__U10_Pad5_;
wire Net__U10_Pad6_;
wire Net__U11_Pad3_;
wire Net__U12_Pad10_;
wire Net__U12_Pad12_;
wire Net__U12_Pad13_;
wire Net__U12_Pad14_;
wire Net__U12_Pad4_;
wire Net__U12_Pad6_;
wire Net__U13_Pad1_;
wire Net__U13_Pad3_;
wire Net__U1_Pad1_;
wire Net__U1_Pad2_;
wire Net__U31_Pad11_;
wire Net__U31_Pad12_;
wire Net__U31_Pad15_;
wire Net__U31_Pad16_;
wire Net__U31_Pad19_;
wire Net__U31_Pad2_;
wire Net__U31_Pad5_;
wire Net__U31_Pad6_;
wire Net__U31_Pad9_;
wire Net__U32_Pad8_;
wire Net__U36_Pad5_;
wire Net__U3_Pad3_;
wire Net__U3_Pad4_;
wire Net__U3_Pad5_;
wire Net__U3_Pad6_;
wire Net__U4_Pad3_;
wire Net__U4_Pad4_;
wire Net__U4_Pad5_;
wire Net__U4_Pad6_;
wire Net__U5_Pad11_;
wire Net__U5_Pad12_;
wire Net__U5_Pad15_;
wire Net__U7_Pad15_;
wire VCC;
wire _HCLK1;
wire _HCLK2;
wire _hc0;
wire _hc1;
wire _hover;
wire _tie0;
wire _tie1;
jt7404 U1(
    .in1       ( Net__U1_Pad1_            ) /* pin 1*/ ,
    .out2      ( Net__U1_Pad2_            ) /* pin 2*/ 
);

jt74112 U10(
    .clk1_b    ( _HN[8]                   ) /* pin 1*/ ,
    .k1        ( Net__U10_Pad2_           ) /* pin 2*/ ,
    .j1        ( Net__U10_Pad3_           ) /* pin 3*/ ,
    .pr1_b     ( Net__U10_Pad2_           ) /* pin 4*/ ,
    .q1        ( Net__U10_Pad5_           ) /* pin 5*/ ,
    .q1_b      ( Net__U10_Pad6_           ) /* pin 6*/ ,
    .cl1_b     ( RSTn                     ) /* pin 15*/ 
);

jt7400 U11(
    .in1       ( _HN[6]                   ) /* pin 1*/ ,
    .in2       ( _HN[8]                   ) /* pin 2*/ ,
    .out3      ( Net__U11_Pad3_           ) /* pin 3*/ 
);

jt74367 U12(
    .oe1_b     ( _tie0                    ) /* pin 1*/ ,
    .oe2_b     ( _tie0                    ) /* pin 15*/ ,
    .A         ({ Net__U12_Pad14_,
                  Net__U12_Pad12_,
                  Net__U12_Pad10_,
                  Net__U12_Pad6_,
                  Net__U12_Pad4_,
                  Net__U12_Pad12_}),
    .Y         ({ Net__U12_Pad13_,
                  _HCLK2,
                  _HN[2],
                  _HN[1],
                  _HN[0],
                  _HCLK1})
);

jt7400 U13(
    .in1       ( Net__U13_Pad1_           ) /* pin 1*/ ,
    .in2       ( Net__U11_Pad3_           ) /* pin 2*/ ,
    .out3      ( Net__U13_Pad3_           ) /* pin 3*/ 
);

jt7486 U14(
    .in1       ( _VN[0]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( _VPOS[0]                 ) /* pin 3*/ 
);

jt7486 U15(
    .in1       ( _VN[1]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( _VPOS[1]                 ) /* pin 3*/ 
);

jt7486 U16(
    .in1       ( _VN[2]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( _VPOS[2]                 ) /* pin 3*/ 
);

jt7486 U17(
    .in1       ( _VN[3]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( _VPOS[3]                 ) /* pin 3*/ 
);

jt7486 U18(
    .in1       ( _VN[4]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( _VPOS[4]                 ) /* pin 3*/ 
);

jt7486 U19(
    .in1       ( _VN[5]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( _VPOS[5]                 ) /* pin 3*/ 
);

jt74112 U2(
    .clk1_b    ( _HN[8]                   ) /* pin 1*/ ,
    .k1        ( Net__U1_Pad1_            ) /* pin 2*/ ,
    .j1        ( Net__U1_Pad1_            ) /* pin 3*/ ,
    .pr1_b     ( RSTn                     ) /* pin 4*/ ,
    .q1        ( Net__U10_Pad3_           ) /* pin 5*/ ,
    .q1_b      ( Net__U10_Pad2_           ) /* pin 6*/ ,
    .cl1_b     ( _tie1                    ) /* pin 15*/ 
);

jt7486 U20(
    .in1       ( _VN[6]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( _VPOS[6]                 ) /* pin 3*/ 
);

jt7486 U21(
    .in1       ( _VN[7]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( _VPOS[7]                 ) /* pin 3*/ 
);

jt7404 U22(
    .in1       ( _HN[7]                   ) /* pin 1*/ ,
    .out2      ( Net__U13_Pad1_           ) /* pin 2*/ 
);

jt7486 U23(
    .in1       ( _HN[0]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( HPOS[0]                  ) /* pin 3*/ 
);

jt7486 U24(
    .in1       ( _HN[1]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( HPOS[1]                  ) /* pin 3*/ 
);

jt7486 U25(
    .in1       ( _HN[2]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( HPOS[2]                  ) /* pin 3*/ 
);

jt7486 U26(
    .in1       ( _HN[3]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( HPOS[3]                  ) /* pin 3*/ 
);

jt7486 U27(
    .in1       ( _HN[4]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( HPOS[4]                  ) /* pin 3*/ 
);

jt7486 U28(
    .in1       ( _HN[5]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( HPOS[5]                  ) /* pin 3*/ 
);

jt7486 U29(
    .in1       ( _HN[6]                   ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( HPOS[6]                  ) /* pin 3*/ 
);

jt74161 U3(
    .cl_b      ( _tie1                    ) /* pin 1*/ ,
    .clk       ( clk12                    ) /* pin 2*/ ,
    .cep       ( _tie1                    ) /* pin 7*/ ,
    .ld_b      ( _tie1                    ) /* pin 9*/ ,
    .cet       ( _tie1                    ) /* pin 10*/ ,
    .ca        ( _hc0                     ) /* pin 15*/ ,
    .d         ({ Net__U3_Pad6_,
                  Net__U3_Pad5_,
                  Net__U3_Pad4_,
                  Net__U3_Pad3_}),
    .q         ({ Net__U12_Pad10_,
                  Net__U12_Pad6_,
                  Net__U12_Pad4_,
                  Net__U12_Pad12_})
);

jt7486 U30(
    .in1       ( Net__U13_Pad3_           ) /* pin 1*/ ,
    .in2       ( flipn                    ) /* pin 2*/ ,
    .out3      ( HPOS[7]                  ) /* pin 3*/ 
);

jt74273 U31(
    .cl_b      ( _tie1                    ) /* pin 1*/ ,
    .clk       ( Net__U31_Pad11_          ) /* pin 11*/ ,
    .d         ({ _VPOS[7],
                  _VPOS[6],
                  _VPOS[5],
                  _VPOS[4],
                  _VPOS[3],
                  _VPOS[2],
                  _VPOS[1],
                  _VPOS[0]}),
    .q         ({ Net__U31_Pad19_,
                  Net__U31_Pad16_,
                  Net__U31_Pad15_,
                  Net__U31_Pad12_,
                  Net__U31_Pad9_,
                  Net__U31_Pad6_,
                  Net__U31_Pad5_,
                  Net__U31_Pad2_})
);

jt7430 U32(
    .Y         ( Net__U32_Pad8_           ) /* pin 8*/ ,
    .in        ({ _tie1,
                  _tie1,
                  _tie1,
                  _VN[3],
                  _VN[4],
                  _VN[5],
                  _VN[6],
                  _VN[7]})
);

jt74273 U33(
    .cl_b      ( _tie1                    ) /* pin 1*/ ,
    .clk       ( Net__U31_Pad11_          ) /* pin 11*/ ,
    .d         ({ Net__U31_Pad19_,
                  Net__U31_Pad16_,
                  Net__U31_Pad15_,
                  Net__U31_Pad12_,
                  Net__U31_Pad9_,
                  Net__U31_Pad6_,
                  Net__U31_Pad5_,
                  Net__U31_Pad2_}),
    .q         ({ DVPOS[7],
                  DVPOS[6],
                  DVPOS[5],
                  DVPOS[4],
                  DVPOS[3],
                  DVPOS[2],
                  DVPOS[1],
                  DVPOS[0]})
);

jt7400 U34(
    .in1       ( Net__U32_Pad8_           ) /* pin 1*/ ,
    .in2       ( Net__U10_Pad6_           ) /* pin 2*/ ,
    .out3      ( VBLK                     ) /* pin 3*/ 
);

jt7404 U35(
    .in1       ( _HN[0]                   ) /* pin 1*/ ,
    .out2      ( E                        ) /* pin 2*/ 
);

jt7474 U36(
    .cl1_b     ( _tie1                    ) /* pin 1*/ ,
    .d1        ( E                        ) /* pin 2*/ ,
    .clk1      ( _HCLK1                   ) /* pin 3*/ ,
    .pr1_b     ( _tie1                    ) /* pin 4*/ ,
    .q1        ( Net__U36_Pad5_           ) /* pin 5*/ ,
    .q1_b      ( Q                        ) /* pin 6*/ 
);

jt74161 U4(
    .cl_b      ( _tie1                    ) /* pin 1*/ ,
    .clk       ( clk12                    ) /* pin 2*/ ,
    .cep       ( _hc0                     ) /* pin 7*/ ,
    .ld_b      ( _tie1                    ) /* pin 9*/ ,
    .cet       ( _hc0                     ) /* pin 10*/ ,
    .ca        ( _hc1                     ) /* pin 15*/ ,
    .d         ({ Net__U4_Pad6_,
                  Net__U4_Pad5_,
                  Net__U4_Pad4_,
                  Net__U4_Pad3_}),
    .q         ({ _HN[6],
                  _HN[5],
                  _HN[4],
                  _HN[3]})
);

jt74161 U5(
    .cl_b      ( _tie1                    ) /* pin 1*/ ,
    .clk       ( clk12                    ) /* pin 2*/ ,
    .cep       ( _hc0                     ) /* pin 7*/ ,
    .ld_b      ( _hover                   ) /* pin 9*/ ,
    .cet       ( _hc1                     ) /* pin 10*/ ,
    .ca        ( Net__U5_Pad15_           ) /* pin 15*/ ,
    .d         ({ _tie0,
                  _tie0,
                  _tie0,
                  _tie0}),
    .q         ({ Net__U5_Pad11_,
                  Net__U5_Pad12_,
                  _HN[8],
                  _HN[7]})
);

jt7400 U6(
    .in1       ( _hc1                     ) /* pin 1*/ ,
    .in2       ( _HN[8]                   ) /* pin 2*/ ,
    .out3      ( _hover                   ) /* pin 3*/ 
);

jt74161 U7(
    .cl_b      ( RSTn                     ) /* pin 1*/ ,
    .clk       ( Net__U31_Pad11_          ) /* pin 2*/ ,
    .cep       ( _tie1                    ) /* pin 7*/ ,
    .ld_b      ( Net__U1_Pad2_            ) /* pin 9*/ ,
    .cet       ( _tie1                    ) /* pin 10*/ ,
    .ca        ( Net__U7_Pad15_           ) /* pin 15*/ ,
    .d         ({ _tie1,
                  _tie0,
                  _tie0,
                  _tie0}),
    .q         ({ _VN[3],
                  _VN[2],
                  _VN[1],
                  _VN[0]})
);

jt74161 U8(
    .cl_b      ( RSTn                     ) /* pin 1*/ ,
    .clk       ( Net__U31_Pad11_          ) /* pin 2*/ ,
    .cep       ( Net__U7_Pad15_           ) /* pin 7*/ ,
    .ld_b      ( Net__U1_Pad2_            ) /* pin 9*/ ,
    .cet       ( Net__U7_Pad15_           ) /* pin 10*/ ,
    .ca        ( Net__U1_Pad1_            ) /* pin 15*/ ,
    .d         ({ Net__U10_Pad2_,
                  Net__U10_Pad2_,
                  Net__U10_Pad2_,
                  _tie0}),
    .q         ({ _VN[7],
                  _VN[6],
                  _VN[5],
                  _VN[4]})
);

jt7404 U9(
    .in1       ( _HN[8]                   ) /* pin 1*/ ,
    .out2      ( Net__U31_Pad11_          ) /* pin 2*/ 
);

rpulldown pd1(
    .x         ( _tie0                    ) /* pin 1*/ 
);

rpullup pu1(
    .x         ( _tie1                    ) /* pin 1*/ 
);

