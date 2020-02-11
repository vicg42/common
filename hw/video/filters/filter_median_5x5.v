//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//------------------------------------------------------------------------

module filter_median_5x5 #(
    parameter LINE_SIZE_MAX = 1024,
    parameter PIXEL_WIDTH = 12
)(
    input bypass,

    //input resolution X * Y
    input [PIXEL_WIDTH-1:0] di_i,
    input                   de_i,
    input                   hs_i,
    input                   vs_i,

    //output resolution (X - 4) * (Y - 4)
    output [PIXEL_WIDTH-1:0] do_o, //
    output                   de_o, //
    output                   hs_o, //
    output                   vs_o, //

    output [PIXEL_WIDTH-1:0] bypass_o, //

    input clk,
    input rst
);

function [PIXEL_WIDTH*2-1:0] Sort2;
    input [PIXEL_WIDTH-1:0] x1;
    input [PIXEL_WIDTH-1:0] x2;
    if (x1 > x2)
        Sort2 = {x2, x1};
    else
        Sort2 = {x1, x2};
endfunction


localparam KERNEL_SIZE = 25;

wire [(PIXEL_WIDTH*KERNEL_SIZE)-1:0] xi;
wire [(PIXEL_WIDTH*KERNEL_SIZE)-1:0] xo;

reg [PIXEL_WIDTH-1:0] s00 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s01 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s02 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s03 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s04 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s05 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s06 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s07 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s08 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s09 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s10 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s11 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s12 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s13 [(KERNEL_SIZE)-1:0];
reg [PIXEL_WIDTH-1:0] s14 [(KERNEL_SIZE)-1:0];

wire de;
wire hs;
wire vs;
reg [0:14] sr_de = 0;
reg [0:14] sr_hs = 0;
reg [0:14] sr_vs = 0;
reg [PIXEL_WIDTH-1:0] sr_bypass_data [0:14];

filter_core_5x5 #(
    .DE_I_PERIOD(0),
    .LINE_SIZE_MAX (LINE_SIZE_MAX),
    .DATA_WIDTH (PIXEL_WIDTH)
) filter_core_5x5 (
    .bypass(1'b0),

    .di_i(di_i),
    .de_i(de_i),
    .hs_i(hs_i),
    .vs_i(vs_i),

    //output resolution (X - 4) * (Y - 4)
    //pixel pattern:
    //line[0]: x00 x01 x02 x03 x04
    //line[1]: x05 x06 x07 x08 x09
    //line[2]: x10 x11 x12 x13 x14
    //line[3]: x15 x16 x17 x18 x19
    //line[4]: x20 x21 x22 x23 x24
    .x00(xi[(PIXEL_WIDTH*( 0)) +: PIXEL_WIDTH]),
    .x01(xi[(PIXEL_WIDTH*( 1)) +: PIXEL_WIDTH]),
    .x02(xi[(PIXEL_WIDTH*( 2)) +: PIXEL_WIDTH]),
    .x03(xi[(PIXEL_WIDTH*( 3)) +: PIXEL_WIDTH]),
    .x04(xi[(PIXEL_WIDTH*( 4)) +: PIXEL_WIDTH]),
    .x05(xi[(PIXEL_WIDTH*( 5)) +: PIXEL_WIDTH]),
    .x06(xi[(PIXEL_WIDTH*( 6)) +: PIXEL_WIDTH]),
    .x07(xi[(PIXEL_WIDTH*( 7)) +: PIXEL_WIDTH]),
    .x08(xi[(PIXEL_WIDTH*( 8)) +: PIXEL_WIDTH]),
    .x09(xi[(PIXEL_WIDTH*( 9)) +: PIXEL_WIDTH]),
    .x10(xi[(PIXEL_WIDTH*(10)) +: PIXEL_WIDTH]),
    .x11(xi[(PIXEL_WIDTH*(11)) +: PIXEL_WIDTH]),
    .x12(xi[(PIXEL_WIDTH*(12)) +: PIXEL_WIDTH]),
    .x13(xi[(PIXEL_WIDTH*(13)) +: PIXEL_WIDTH]),
    .x14(xi[(PIXEL_WIDTH*(14)) +: PIXEL_WIDTH]),
    .x15(xi[(PIXEL_WIDTH*(15)) +: PIXEL_WIDTH]),
    .x16(xi[(PIXEL_WIDTH*(16)) +: PIXEL_WIDTH]),
    .x17(xi[(PIXEL_WIDTH*(17)) +: PIXEL_WIDTH]),
    .x18(xi[(PIXEL_WIDTH*(18)) +: PIXEL_WIDTH]),
    .x19(xi[(PIXEL_WIDTH*(19)) +: PIXEL_WIDTH]),
    .x20(xi[(PIXEL_WIDTH*(20)) +: PIXEL_WIDTH]),
    .x21(xi[(PIXEL_WIDTH*(21)) +: PIXEL_WIDTH]),
    .x22(xi[(PIXEL_WIDTH*(22)) +: PIXEL_WIDTH]),
    .x23(xi[(PIXEL_WIDTH*(23)) +: PIXEL_WIDTH]),
    .x24(xi[(PIXEL_WIDTH*(24)) +: PIXEL_WIDTH]),

    .de_o(de),
    .hs_o(hs),
    .vs_o(vs),

    .clk (clk),
    .rst (rst)
);

// -------------------------------------------------------------------------
// pixel buffer, making following pixel pattern:
// -------------------------------------------------------------------------
// x00 x01 x02 x03 x04
// x05 x06 x07 x08 x09
// x10 x11 x12 x13 x14
// x15 x16 x17 x18 x19
// x20 x21 x22 x23 x24

always @(posedge clk) begin
    //stage0
    {s00[( 0)], s00[( 1)]} <= Sort2(xi[(PIXEL_WIDTH*( 0)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*( 1)) +: PIXEL_WIDTH]);
    {s00[( 2)], s00[( 3)]} <= Sort2(xi[(PIXEL_WIDTH*( 2)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*( 3)) +: PIXEL_WIDTH]);
    {s00[( 4)], s00[( 5)]} <= Sort2(xi[(PIXEL_WIDTH*( 4)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*( 5)) +: PIXEL_WIDTH]);
    {s00[( 6)], s00[( 7)]} <= Sort2(xi[(PIXEL_WIDTH*( 6)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*( 7)) +: PIXEL_WIDTH]);
    {s00[( 8)], s00[( 9)]} <= Sort2(xi[(PIXEL_WIDTH*( 8)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*( 9)) +: PIXEL_WIDTH]);
    {s00[(10)], s00[(11)]} <= Sort2(xi[(PIXEL_WIDTH*(10)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*(11)) +: PIXEL_WIDTH]);
    {s00[(12)], s00[(13)]} <= Sort2(xi[(PIXEL_WIDTH*(12)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*(13)) +: PIXEL_WIDTH]);
    {s00[(14)], s00[(15)]} <= Sort2(xi[(PIXEL_WIDTH*(14)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*(15)) +: PIXEL_WIDTH]);
    {s00[(16)], s00[(17)]} <= Sort2(xi[(PIXEL_WIDTH*(16)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*(17)) +: PIXEL_WIDTH]);
    {s00[(18)], s00[(19)]} <= Sort2(xi[(PIXEL_WIDTH*(18)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*(19)) +: PIXEL_WIDTH]);
    {s00[(20)], s00[(21)]} <= Sort2(xi[(PIXEL_WIDTH*(20)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*(21)) +: PIXEL_WIDTH]);
    {s00[(22)], s00[(23)]} <= Sort2(xi[(PIXEL_WIDTH*(22)) +: PIXEL_WIDTH], xi[(PIXEL_WIDTH*(23)) +: PIXEL_WIDTH]);
                s00[(24)] <= xi[(PIXEL_WIDTH*(24)) +: PIXEL_WIDTH];

    sr_bypass_data[0] <= xi[(PIXEL_WIDTH*(12)) +: PIXEL_WIDTH];
    sr_de[0] <= de;
    sr_hs[0] <= hs;
    sr_vs[0] <= vs;

    //stage1
    {s01[( 0)], s01[( 2)]} <= Sort2(s00[( 0)], s00[( 2)]);
    {s01[( 1)], s01[( 3)]} <= Sort2(s00[( 1)], s00[( 3)]);
    {s01[( 4)], s01[( 6)]} <= Sort2(s00[( 4)], s00[( 6)]);
    {s01[( 5)], s01[( 7)]} <= Sort2(s00[( 5)], s00[( 7)]);
    {s01[( 8)], s01[(10)]} <= Sort2(s00[( 8)], s00[(10)]);
    {s01[( 9)], s01[(11)]} <= Sort2(s00[( 9)], s00[(11)]);
    {s01[(12)], s01[(14)]} <= Sort2(s00[(12)], s00[(14)]);
    {s01[(13)], s01[(15)]} <= Sort2(s00[(13)], s00[(15)]);
    {s01[(16)], s01[(18)]} <= Sort2(s00[(16)], s00[(18)]);
    {s01[(17)], s01[(19)]} <= Sort2(s00[(17)], s00[(19)]);
    {s01[(20)], s01[(22)]} <= Sort2(s00[(20)], s00[(22)]);
    {s01[(21)], s01[(23)]} <= Sort2(s00[(21)], s00[(23)]);
                s01[(24)] <= s00[(24)];

    sr_bypass_data[1] <= sr_bypass_data[0];
    sr_de[1] <= sr_de[0];
    sr_hs[1] <= sr_hs[0];
    sr_vs[1] <= sr_vs[0];

    //stage2
                s02[( 0)] <= s01[( 0)];
    {s02[( 1)], s02[( 2)]} <= Sort2(s01[( 1)], s01[( 2)]);
                s02[( 3)] <= s01[( 3)];
                s02[( 4)] <= s01[( 4)];
    {s02[( 5)], s02[( 6)]} <= Sort2(s01[( 5)], s01[( 6)]);
                s02[( 7)] <= s01[( 7)];
                s02[( 8)] <= s01[( 8)];
    {s02[( 9)], s02[(10)]} <= Sort2(s01[( 9)], s01[(10)]);
                s02[(11)] <= s01[(11)];
                s02[(12)] <= s01[(12)];
    {s02[(13)], s02[(14)]} <= Sort2(s01[(13)], s01[(14)]);
                s02[(15)] <= s01[(15)];
                s02[(16)] <= s01[(16)];
    {s02[(17)], s02[(18)]} <= Sort2(s01[(17)], s01[(18)]);
                s02[(19)] <= s01[(19)];
                s02[(20)] <= s01[(20)];
    {s02[(21)], s02[(22)]} <= Sort2(s01[(21)], s01[(22)]);
                s02[(23)] <= s01[(23)];
                s02[(24)] <= s01[(24)];

    sr_bypass_data[2] <= sr_bypass_data[1];
    sr_de[2] <= sr_de[1];
    sr_hs[2] <= sr_hs[1];
    sr_vs[2] <= sr_vs[1];

    //stage3
    {s03[( 0)], s03[( 4)]} <= Sort2(s02[( 0)], s02[( 4)]);
    {s03[( 1)], s03[( 5)]} <= Sort2(s02[( 1)], s02[( 5)]);
    {s03[( 2)], s03[( 6)]} <= Sort2(s02[( 2)], s02[( 6)]);
    {s03[( 3)], s03[( 7)]} <= Sort2(s02[( 3)], s02[( 7)]);
    {s03[( 8)], s03[(12)]} <= Sort2(s02[( 8)], s02[(12)]);
    {s03[( 9)], s03[(13)]} <= Sort2(s02[( 9)], s02[(13)]);
    {s03[(10)], s03[(14)]} <= Sort2(s02[(10)], s02[(14)]);
    {s03[(11)], s03[(15)]} <= Sort2(s02[(11)], s02[(15)]);
    {s03[(16)], s03[(20)]} <= Sort2(s02[(16)], s02[(20)]);
    {s03[(17)], s03[(21)]} <= Sort2(s02[(17)], s02[(21)]);
    {s03[(18)], s03[(22)]} <= Sort2(s02[(18)], s02[(22)]);
    {s03[(19)], s03[(23)]} <= Sort2(s02[(19)], s02[(23)]);
                s03[(24)] <= s02[(24)];

    sr_bypass_data[3] <= sr_bypass_data[2];
    sr_de[3] <= sr_de[2];
    sr_hs[3] <= sr_hs[2];
    sr_vs[3] <= sr_vs[2];

    //stage4
                s04[( 0)] <= s03[( 0)];
                s04[( 1)] <= s03[( 1)];
    {s04[( 2)], s04[( 4)]} <= Sort2(s03[( 2)], s03[( 4)]);
    {s04[( 3)], s04[( 5)]} <= Sort2(s03[( 3)], s03[( 5)]);
                s04[( 6)] <= s03[( 6)];
                s04[( 7)] <= s03[( 7)];
                s04[( 8)] <= s03[( 8)];
                s04[( 9)] <= s03[( 9)];
    {s04[(10)], s04[(12)]} <= Sort2(s03[(10)], s03[(12)]);
    {s04[(11)], s04[(13)]} <= Sort2(s03[(11)], s03[(13)]);
                s04[(14)] <= s03[(14)];
                s04[(15)] <= s03[(15)];
                s04[(16)] <= s03[(16)];
                s04[(17)] <= s03[(17)];
    {s04[(18)], s04[(20)]} <= Sort2(s03[(18)], s03[(20)]);
    {s04[(19)], s04[(21)]} <= Sort2(s03[(19)], s03[(21)]);
                s04[(22)] <= s03[(22)];
                s04[(23)] <= s03[(23)];
                s04[(24)] <= s03[(24)];

    sr_bypass_data[4] <= sr_bypass_data[3];
    sr_de[4] <= sr_de[3];
    sr_hs[4] <= sr_hs[3];
    sr_vs[4] <= sr_vs[3];

    //stage5
                s05[( 0)] <= s04[( 0)];
    {s05[( 1)], s05[( 2)]} <= Sort2(s04[( 1)], s04[( 2)]);
    {s05[( 3)], s05[( 4)]} <= Sort2(s04[( 3)], s04[( 4)]);
    {s05[( 5)], s05[( 6)]} <= Sort2(s04[( 5)], s04[( 6)]);
                s05[( 7)] <= s04[( 7)];
                s05[( 8)] <= s04[( 8)];
    {s05[( 9)], s05[(10)]} <= Sort2(s04[( 9)], s04[(10)]);
    {s05[(11)], s05[(12)]} <= Sort2(s04[(11)], s04[(12)]);
    {s05[(13)], s05[(14)]} <= Sort2(s04[(13)], s04[(14)]);
                s05[(15)] <= s04[(15)];
                s05[(16)] <= s04[(16)];
    {s05[(17)], s05[(18)]} <= Sort2(s04[(17)], s04[(18)]);
    {s05[(19)], s05[(20)]} <= Sort2(s04[(19)], s04[(20)]);
    {s05[(21)], s05[(22)]} <= Sort2(s04[(21)], s04[(22)]);
                s05[(23)] <= s04[(23)];
                s05[(24)] <= s04[(24)];

    sr_bypass_data[5] <= sr_bypass_data[4];
    sr_de[5] <= sr_de[4];
    sr_hs[5] <= sr_hs[4];
    sr_vs[5] <= sr_vs[4];

    //stage6
    {s06[( 0)], s06[( 8)]} <= Sort2(s05[( 0)], s05[( 8)]);
    {s06[( 1)], s06[( 9)]} <= Sort2(s05[( 1)], s05[( 9)]);
    {s06[( 2)], s06[(10)]} <= Sort2(s05[( 2)], s05[(10)]);
    {s06[( 3)], s06[(11)]} <= Sort2(s05[( 3)], s05[(11)]);
    {s06[( 4)], s06[(12)]} <= Sort2(s05[( 4)], s05[(12)]);
    {s06[( 5)], s06[(13)]} <= Sort2(s05[( 5)], s05[(13)]);
    {s06[( 6)], s06[(14)]} <= Sort2(s05[( 6)], s05[(14)]);
    {s06[( 7)], s06[(15)]} <= Sort2(s05[( 7)], s05[(15)]);
    {s06[(16)], s06[(24)]} <= Sort2(s05[(16)], s05[(24)]);
                s06[(17)] <= s05[(17)];
                s06[(18)] <= s05[(18)];
                s06[(19)] <= s05[(19)];
                s06[(20)] <= s05[(20)];
                s06[(21)] <= s05[(21)];
                s06[(22)] <= s05[(22)];
                s06[(23)] <= s05[(23)];

    sr_bypass_data[6] <= sr_bypass_data[5];
    sr_de[6] <= sr_de[5];
    sr_hs[6] <= sr_hs[5];
    sr_vs[6] <= sr_vs[5];

    //stage7
                s07[(0)] <= s06[(0)];
                s07[(1)] <= s06[(1)];
                s07[(2)] <= s06[(2)];
                s07[(3)] <= s06[(3)];
    {s07[(4)], s07[( 8)]} <= Sort2(s06[(4)], s06[( 8)]);
    {s07[(5)], s07[( 9)]} <= Sort2(s06[(5)], s06[( 9)]);
    {s07[(6)], s07[(10)]} <= Sort2(s06[(6)], s06[(10)]);
    {s07[(7)], s07[(11)]} <= Sort2(s06[(7)], s06[(11)]);
                s07[(12)] <= s06[(12)];
                s07[(13)] <= s06[(13)];
                s07[(14)] <= s06[(14)];
                s07[(15)] <= s06[(15)];
                s07[(16)] <= s06[(16)];
                s07[(17)] <= s06[(17)];
                s07[(18)] <= s06[(18)];
                s07[(19)] <= s06[(19)];
    {s07[(20)], s07[(24)]} <= Sort2(s06[(20)], s06[(24)]);
                s07[(21)] <= s06[(21)];
                s07[(22)] <= s06[(22)];
                s07[(23)] <= s06[(23)];

    sr_bypass_data[7] <= sr_bypass_data[6];
    sr_de[7] <= sr_de[6];
    sr_hs[7] <= sr_hs[6];
    sr_vs[7] <= sr_vs[6];

    //stage8
                s08[(0)] <= s07[(0)];
                s08[(1)] <= s07[(1)];
    {s08[( 2)], s08[( 4)]} <= Sort2(s07[( 2)], s07[( 4)]);
    {s08[( 3)], s08[( 5)]} <= Sort2(s07[( 3)], s07[( 5)]);
    {s08[( 6)], s08[( 8)]} <= Sort2(s07[( 6)], s07[( 8)]);
    {s08[( 7)], s08[( 9)]} <= Sort2(s07[( 7)], s07[( 9)]);
    {s08[(10)], s08[(12)]} <= Sort2(s07[(10)], s07[(12)]);
    {s08[(11)], s08[(13)]} <= Sort2(s07[(11)], s07[(13)]);
                s08[(14)] <= s07[(14)];
                s08[(15)] <= s07[(15)];

                s08[(16)] <= s07[(16)];
                s08[(17)] <= s07[(17)];
    {s08[(18)], s08[(20)]} <= Sort2(s07[(18)], s07[(20)]);
    {s08[(19)], s08[(21)]} <= Sort2(s07[(19)], s07[(21)]);
    {s08[(22)], s08[(24)]} <= Sort2(s07[(22)], s07[(24)]);
                s08[(23)] <= s07[(23)];

    sr_bypass_data[8] <= sr_bypass_data[7];
    sr_de[8] <= sr_de[7];
    sr_hs[8] <= sr_hs[7];
    sr_vs[8] <= sr_vs[7];

    //stage9
                s09[(0)] <= s08[(0)];
    {s09[( 1)], s09[( 2)]} <= Sort2(s08[( 1)], s08[( 2)]);
    {s09[( 3)], s09[( 4)]} <= Sort2(s08[( 3)], s08[( 4)]);
    {s09[( 5)], s09[( 6)]} <= Sort2(s08[( 5)], s08[( 6)]);
    {s09[( 7)], s09[( 8)]} <= Sort2(s08[( 7)], s08[( 8)]);
    {s09[( 9)], s09[(10)]} <= Sort2(s08[( 9)], s08[(10)]);
    {s09[(11)], s09[(12)]} <= Sort2(s08[(11)], s08[(12)]);
    {s09[(13)], s09[(14)]} <= Sort2(s08[(13)], s08[(14)]);
                s09[(15)] <= s08[(15)];
                s09[(16)] <= s08[(16)];
    {s09[(17)], s09[(18)]} <= Sort2(s08[(17)], s08[(18)]);
    {s09[(19)], s09[(20)]} <= Sort2(s08[(19)], s08[(20)]);
    {s09[(21)], s09[(22)]} <= Sort2(s08[(21)], s08[(22)]);
    {s09[(23)], s09[(24)]} <= Sort2(s08[(23)], s08[(24)]);

    sr_bypass_data[9] <= sr_bypass_data[8];
    sr_de[9] <= sr_de[8];
    sr_hs[9] <= sr_hs[8];
    sr_vs[9] <= sr_vs[8];

    //stage10
    {s10[(0)], s10[(16)]} <= Sort2(s09[(0)], s09[(16)]);
    {s10[(1)], s10[(17)]} <= Sort2(s09[(1)], s09[(17)]);
    {s10[(2)], s10[(18)]} <= Sort2(s09[(2)], s09[(18)]);
    {s10[(3)], s10[(19)]} <= Sort2(s09[(3)], s09[(19)]);
    {s10[(4)], s10[(20)]} <= Sort2(s09[(4)], s09[(20)]);
    {s10[(5)], s10[(21)]} <= Sort2(s09[(5)], s09[(21)]);
    {s10[(6)], s10[(22)]} <= Sort2(s09[(6)], s09[(22)]);
    {s10[(7)], s10[(23)]} <= Sort2(s09[(7)], s09[(23)]);
    {s10[(8)], s10[(24)]} <= Sort2(s09[(8)], s09[(24)]);
                s10[( 9)] <= s09[( 9)];
                s10[(10)] <= s09[(10)];
                s10[(11)] <= s09[(11)];
                s10[(12)] <= s09[(12)];
                s10[(13)] <= s09[(13)];
                s10[(14)] <= s09[(14)];
                s10[(15)] <= s09[(15)];

    sr_bypass_data[10] <= sr_bypass_data[9];
    sr_de[10] <= sr_de[9];
    sr_hs[10] <= sr_hs[9];
    sr_vs[10] <= sr_vs[9];

    //stage11
                s11[(0)] <= s10[(0)];
                s11[(1)] <= s10[(1)];
                s11[(2)] <= s10[(2)];
                s11[(3)] <= s10[(3)];
                s11[(4)] <= s10[(4)];
                s11[(5)] <= s10[(5)];
                s11[(6)] <= s10[(6)];
                s11[(7)] <= s10[(7)];
    {s11[( 8)], s11[(16)]} <= Sort2(s10[( 8)], s10[(16)]);
    {s11[( 9)], s11[(17)]} <= Sort2(s10[( 9)], s10[(17)]);
    {s11[(10)], s11[(18)]} <= Sort2(s10[(10)], s10[(18)]);
    {s11[(11)], s11[(19)]} <= Sort2(s10[(11)], s10[(19)]);
    {s11[(12)], s11[(20)]} <= Sort2(s10[(12)], s10[(20)]);
    {s11[(13)], s11[(21)]} <= Sort2(s10[(13)], s10[(21)]);
    {s11[(14)], s11[(22)]} <= Sort2(s10[(14)], s10[(22)]);
    {s11[(15)], s11[(23)]} <= Sort2(s10[(15)], s10[(23)]);
                s11[(24)] <= s10[(24)];

    sr_bypass_data[11] <= sr_bypass_data[10];
    sr_de[11] <= sr_de[10];
    sr_hs[11] <= sr_hs[10];
    sr_vs[11] <= sr_vs[10];

    //stage12
                s12[(0)] <= s11[(0)];
                s12[(1)] <= s11[(1)];
                s12[(2)] <= s11[(2)];
                s12[(3)] <= s11[(3)];
    {s12[( 4)], s12[( 8)]} <= Sort2(s11[( 4)], s11[( 8)]);
    {s12[( 5)], s12[( 9)]} <= Sort2(s11[( 5)], s11[( 9)]);
    {s12[( 6)], s12[(10)]} <= Sort2(s11[( 6)], s11[(10)]);
    {s12[( 7)], s12[(11)]} <= Sort2(s11[( 7)], s11[(11)]);
    {s12[(12)], s12[(16)]} <= Sort2(s11[(12)], s11[(16)]);
    {s12[(13)], s12[(17)]} <= Sort2(s11[(13)], s11[(17)]);
    {s12[(14)], s12[(18)]} <= Sort2(s11[(14)], s11[(18)]);
    {s12[(15)], s12[(19)]} <= Sort2(s11[(15)], s11[(19)]);
    {s12[(20)], s12[(24)]} <= Sort2(s11[(20)], s11[(24)]);
                s12[(21)] <= s11[(21)];
                s12[(22)] <= s11[(22)];
                s12[(23)] <= s11[(23)];

    sr_bypass_data[12] <= sr_bypass_data[11];
    sr_de[12] <= sr_de[11];
    sr_hs[12] <= sr_hs[11];
    sr_vs[12] <= sr_vs[11];

    //stage13
                s13[(0)] <= s12[(0)];
                s13[(1)] <= s12[(1)];
    {s13[( 2)], s13[( 4)]} <= Sort2(s12[( 2)], s12[( 4)]);
    {s13[( 3)], s13[( 5)]} <= Sort2(s12[( 3)], s12[( 5)]);
    {s13[( 6)], s13[( 8)]} <= Sort2(s12[( 6)], s12[( 8)]);
    {s13[( 7)], s13[( 9)]} <= Sort2(s12[( 7)], s12[( 9)]);
    {s13[(10)], s13[(12)]} <= Sort2(s12[(10)], s12[(12)]);
    {s13[(11)], s13[(13)]} <= Sort2(s12[(11)], s12[(13)]);
    {s13[(14)], s13[(16)]} <= Sort2(s12[(14)], s12[(16)]);
    {s13[(15)], s13[(17)]} <= Sort2(s12[(15)], s12[(17)]);
    {s13[(18)], s13[(20)]} <= Sort2(s12[(18)], s12[(20)]);
    {s13[(19)], s13[(21)]} <= Sort2(s12[(19)], s12[(21)]);
    {s13[(22)], s13[(24)]} <= Sort2(s12[(22)], s12[(24)]);
                s13[(23)] <= s12[(23)];

    sr_bypass_data[13] <= sr_bypass_data[12];
    sr_de[13] <= sr_de[12];
    sr_hs[13] <= sr_hs[12];
    sr_vs[13] <= sr_vs[12];

    //stage14
                s14[(0)] <= s13[(0)];
    {s14[( 1)], s14[( 2)]} <= Sort2(s13[( 1)], s13[( 2)]);
    {s14[( 3)], s14[( 4)]} <= Sort2(s13[( 3)], s13[( 4)]);
    {s14[( 5)], s14[( 6)]} <= Sort2(s13[( 5)], s13[( 6)]);
    {s14[( 7)], s14[( 8)]} <= Sort2(s13[( 7)], s13[( 8)]);
    {s14[( 9)], s14[(10)]} <= Sort2(s13[( 9)], s13[(10)]);
    {s14[(11)], s14[(12)]} <= Sort2(s13[(11)], s13[(12)]);
    {s14[(13)], s14[(14)]} <= Sort2(s13[(13)], s13[(14)]);
    {s14[(15)], s14[(16)]} <= Sort2(s13[(15)], s13[(16)]);
    {s14[(17)], s14[(18)]} <= Sort2(s13[(17)], s13[(18)]);
    {s14[(19)], s14[(20)]} <= Sort2(s13[(19)], s13[(20)]);
    {s14[(21)], s14[(22)]} <= Sort2(s13[(21)], s13[(22)]);
    {s14[(23)], s14[(24)]} <= Sort2(s13[(23)], s13[(24)]);

    sr_bypass_data[14] <= sr_bypass_data[13];
    sr_de[14] <= sr_de[13];
    sr_hs[14] <= sr_hs[13];
    sr_vs[14] <= sr_vs[13];
end

genvar k;
generate
    for (k=0; k<KERNEL_SIZE; k=k+1) begin
        assign xo[(k*PIXEL_WIDTH) +: PIXEL_WIDTH] = s14[k];
    end
endgenerate

assign do_o = s14[(12)];
assign de_o = sr_de[14];
assign hs_o = sr_hs[14];
assign vs_o = sr_vs[14];
assign bypass_o = sr_bypass_data[14];

endmodule


