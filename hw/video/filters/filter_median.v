module filter_median #(
    parameter DE_I_PERIOD = 0,
    parameter LINE_SIZE_MAX = 1024,
    parameter DATA_WIDTH = 8
)(
    input bypass,

    //input resolution X * Y
    input [DATA_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    //output resolution (X - 2) * (Y - 2): for filter_core_3x3
    output [DATA_WIDTH-1:0] do_o,
    output de_o,
    output hs_o,
    output vs_o,

    input clk,
    input rst
);
// -------------------------------------------------------------------------
function [DATA_WIDTH*2-1:0] Sort2;
    input [DATA_WIDTH-1:0] x1;
    input [DATA_WIDTH-1:0] x2;
    if (x1 < x2)
        Sort2 = {x2, x1};
    else
        Sort2 = {x1, x2};
endfunction
//function [(DATA_WIDTH*2)-1:0] Sort2( input [DATA_WIDTH-1:0] x1,
//                                     input [DATA_WIDTH-1:0] x2);
//    begin
////    wire [(DATA_WIDTH*2)-1:0] data;
////        if (x1 > x2) begin
////            assign data =  {x1, x2}
////        end else begin
////            assign data =  {x2, x1}
////        end
////
////        return data;
////        assign data = (x1 >= x2) ? {x1, x2} : {x2, x1};
//        return ((x1 >= x2) ? {x1, x2} : {x2, x1})
//    end
//endfunction

wire de;
wire hs;
wire vs;

wire [DATA_WIDTH-1:0] p1;
wire [DATA_WIDTH-1:0] p2;
wire [DATA_WIDTH-1:0] p3;
wire [DATA_WIDTH-1:0] p4;
wire [DATA_WIDTH-1:0] p5;
wire [DATA_WIDTH-1:0] p6;
wire [DATA_WIDTH-1:0] p7;
wire [DATA_WIDTH-1:0] p8;
wire [DATA_WIDTH-1:0] p9;

filter_core_3x3 #(
    .DE_I_PERIOD (DE_I_PERIOD),
    .LINE_SIZE_MAX (LINE_SIZE_MAX),
    .DATA_WIDTH (DATA_WIDTH)
) filter_core (
    .bypass (bypass),

    .di_i(di_i),
    .de_i(de_i),
    .hs_i(hs_i),
    .vs_i(vs_i),

    .x1 (p1),
    .x2 (p2),
    .x3 (p3),
    .x4 (p4),
    .x5 (p5),
    .x6 (p6),
    .x7 (p7),
    .x8 (p8),
    .x9 (p9),

    .de_o(de),
    .hs_o(hs),
    .vs_o(vs),

    .clk (clk),
    .rst (rst)
);

localparam PIPELINE = 9;

reg [PIPELINE-1:0] sr_de = 0;
reg [PIPELINE-1:0] sr_hs = 0;
reg [PIPELINE-1:0] sr_vs = 0;


reg [DATA_WIDTH-1:0] a1 = 0;
reg [DATA_WIDTH-1:0] a2 = 0;
reg [DATA_WIDTH-1:0] a3 = 0;
reg [DATA_WIDTH-1:0] a4 = 0;
reg [DATA_WIDTH-1:0] a5 = 0;
reg [DATA_WIDTH-1:0] a6 = 0;
reg [DATA_WIDTH-1:0] a7 = 0;
reg [DATA_WIDTH-1:0] a8 = 0;
reg [DATA_WIDTH-1:0] a9 = 0;

reg [DATA_WIDTH-1:0] b1 = 0;
reg [DATA_WIDTH-1:0] b2 = 0;
reg [DATA_WIDTH-1:0] b3 = 0;
reg [DATA_WIDTH-1:0] b4 = 0;
reg [DATA_WIDTH-1:0] b5 = 0;
reg [DATA_WIDTH-1:0] b6 = 0;
reg [DATA_WIDTH-1:0] b7 = 0;
reg [DATA_WIDTH-1:0] b8 = 0;
reg [DATA_WIDTH-1:0] b9 = 0;

reg [DATA_WIDTH-1:0] c1 = 0;
reg [DATA_WIDTH-1:0] c2 = 0;
reg [DATA_WIDTH-1:0] c3 = 0;
reg [DATA_WIDTH-1:0] c4 = 0;
reg [DATA_WIDTH-1:0] c5 = 0;
reg [DATA_WIDTH-1:0] c6 = 0;
reg [DATA_WIDTH-1:0] c7 = 0;
reg [DATA_WIDTH-1:0] c8 = 0;
reg [DATA_WIDTH-1:0] c9 = 0;

reg [DATA_WIDTH-1:0] d1 = 0;
reg [DATA_WIDTH-1:0] d2 = 0;
reg [DATA_WIDTH-1:0] d3 = 0;
reg [DATA_WIDTH-1:0] d4 = 0;
reg [DATA_WIDTH-1:0] d5 = 0;
reg [DATA_WIDTH-1:0] d6 = 0;
reg [DATA_WIDTH-1:0] d7 = 0;
reg [DATA_WIDTH-1:0] d8 = 0;
reg [DATA_WIDTH-1:0] d9 = 0;

reg [DATA_WIDTH-1:0] e2 = 0;
reg [DATA_WIDTH-1:0] e3 = 0;
reg [DATA_WIDTH-1:0] e4 = 0;
reg [DATA_WIDTH-1:0] e5 = 0;
reg [DATA_WIDTH-1:0] e6 = 0;
reg [DATA_WIDTH-1:0] e7 = 0;
reg [DATA_WIDTH-1:0] e8 = 0;

reg [DATA_WIDTH-1:0] f3 = 0;
reg [DATA_WIDTH-1:0] f4 = 0;
reg [DATA_WIDTH-1:0] f5 = 0;
reg [DATA_WIDTH-1:0] f7 = 0;

reg [DATA_WIDTH-1:0] g4 = 0;
reg [DATA_WIDTH-1:0] g5 = 0;
reg [DATA_WIDTH-1:0] g6 = 0;

reg [DATA_WIDTH-1:0] h4 = 0;
reg [DATA_WIDTH-1:0] h5 = 0;
reg [DATA_WIDTH-1:0] h6 = 0;

reg [DATA_WIDTH-1:0] median = 0;
reg [DATA_WIDTH-1:0] i4 = 0;

// p1 p2 p3
// p4 p5 p6
// p7 p8 p9
always @(posedge clk) begin
    // stage a
    {a1, a2} <= Sort2(p1, p2);
    a3 <= p3;
    {a4, a5} <= Sort2(p4, p5);
    a6 <= p6;
    {a7, a8} <= Sort2(p7, p8);
    a9 <= p9;
    sr_de[0] <= de;
    sr_hs[0] <= hs;
    sr_vs[0] <= vs;

    // stage b
    b1 <= a1;
    {b2, b3} <= Sort2(a2, a3);
    b4 <= a4;
    {b5, b6} <= Sort2(a5, a6);
    b7 <= a7;
    {b8, b9} <= Sort2(a8, a9);
    sr_de[1] <= sr_de[0];
    sr_hs[1] <= sr_hs[0];
    sr_vs[1] <= sr_vs[0];

    // stage c
    {c1, c2} <= Sort2(b1, b2);
    c3 <= b3;
    {c4, c5} <= Sort2(b4, b5);
    c6 <= b6;
    {c7, c8} <= Sort2(b7, b8);
    c9 <= b9;
    sr_de[2] <= sr_de[1];
    sr_hs[2] <= sr_hs[1];
    sr_vs[2] <= sr_vs[1];

    // stage d
    {d1, d2} <= Sort2(c1, c4);
    d3 <= c7;
    {d4, d5} <= Sort2(c2, c5);
    d6 <= c8;
    d7 <= c3;
    {d8, d9} <= Sort2(c6, c9);
    sr_de[3] <= sr_de[2];
    sr_hs[3] <= sr_hs[2];
    sr_vs[3] <= sr_vs[2];

    // stage e
    {e2, e3} <= Sort2(d2, d3);
    e4 <= d4;
    {e5, e6} <= Sort2(d5, d6);
    {e7, e8} <= Sort2(d7, d8);
    sr_de[4] <= sr_de[3];
    sr_hs[4] <= sr_hs[3];
    sr_vs[4] <= sr_vs[3];

    // stage f
    f3 <= e3;
    {f4, f5} <= Sort2(e4, e5);
    f7 <= e7;
    sr_de[5] <= sr_de[4];
    sr_hs[5] <= sr_hs[4];
    sr_vs[5] <= sr_vs[4];

    // stage g
    {g4, g5} <= Sort2(f3, f5);
    g6 <= f7;
    sr_de[6] <= sr_de[5];
    sr_hs[6] <= sr_hs[5];
    sr_vs[6] <= sr_vs[5];

    // stage h
    h4 <= g4;
    {h5, h6} <= Sort2(g5, g6);
    sr_de[7] <= sr_de[6];
    sr_hs[7] <= sr_hs[6];
    sr_vs[7] <= sr_vs[6];

    // stage i
    {i4, median} <= Sort2(h4, h5);
    sr_de[8] <= sr_de[7];
    sr_hs[8] <= sr_hs[7];
    sr_vs[8] <= sr_vs[7];
end

assign do_o = median;
assign de_o = sr_de[8];
assign hs_o = sr_hs[8];
assign vs_o = sr_vs[8];

endmodule



//    //----------------------------
//    //pipeline 0
//    //----------------------------
//    if (p1 >= p2) begin
//        s00_m <= p1;
//        s00_l <= p2;
//    end else begin
//        s00_m <= p2;
//        s00_l <= p1;
//    end
//
//    s01 <= p3;
//
//    if (p4 >= p5) begin
//        s02_m <= p4;
//        s02_l <= p5;
//    end else begin
//        s02_m <= p5;
//        s02_l <= p4;
//    end
//
//    s03 <= p6;
//
//    if (p7 >= p8) begin
//        s04_m <= p7;
//        s04_l <= p8;
//    end else begin
//        s04_m <= p8;
//        s04_l <= p7;
//    end
//
//    s05 <= p9;
//
//    //----------------------------
//    //pipeline 1
//    //----------------------------
//    s10 <= s00_m;
//
//    if (s00_l >= s01) begin
//        s11_m <= s00_l;
//        s11_l <= s01;
//    end else begin
//        s11_m <= s01;
//        s11_l <= s00_l;
//    end
//
//    s12 <= s02_m;
//
//    if (s02_l >= s03) begin
//        s13_m <= s02_l;
//        s13_l <= s03;
//    end else begin
//        s13_m <= s03;
//        s13_l <= s02_l;
//    end
//
//    s14 <= s04_m;
//
//    if (s15_l >= s05) begin
//        s15_m <= s04_l;
//        s15_l <= s05;
//    end else begin
//        s15_m <= s05;
//        s15_l <= s04_l;
//    end
//
//    //----------------------------
//    //pipeline 2
//    //----------------------------
//    if (s10 >= s11_m) begin
//        s20_m <= s10;
//        s20_l <= s11_m;
//    end else begin
//        s20_m <= s11_m;
//        s20_l <= s10;
//    end
//
//    s21 <= s11_l;
//
//    if (s12 >= s13_m) begin
//        s22_m <= s12;
//        s22_l <= s13_m;
//    end else begin
//        s22_m <= s13_m;
//        s22_l <= s12;
//    end
//
//    s23 <= s13_l;
//
//    if (s14 >= s15_m) begin
//        s24_m <= s14;
//        s24_l <= s15_m;
//    end else begin
//        s24_m <= s05;
//        s24_l <= s14;
//    end
//
//    s25 <= s15_l;
//
//    //----------------------------
//    //pipeline 3
//    //----------------------------
//    if (s20_m >= s22_m) begin
//        s30_l <= s22_m;
//    end else begin
//        s30_l <= s20_m;
//    end
//
//    s31 <= s24_m;
//
//    if (s20_l >= s22_l) begin
//        s32_m <= s20_l;
//        s32_l <= s22_l;
//    end else begin
//        s32_m <= s22_l;
//        s32_l <= s20_l;
//    end
//
//    s33 <= s24_l;
//
//    s34 <= s23;
//
//    if (s23 >= s25) begin
//        s35_m <= s23;
//    end else begin
//        s35_m <= s25;
//    end
//
//    //----------------------------
//    //pipeline 4
//    //----------------------------
//    if (s30_l >= s31) begin
//        s40_l <= s31;
//    end else begin
//        s40_l <= s30_l;
//    end
//
//    s41 <= s32_m;
//
//    if (s32_l >= s33) begin
//        s42_m <= s32_l;
//        s42_l <= s33;
//    end else begin
//        s42_m <= s33;
//        s42_l <= s32_l;
//    end
//
//    if (s34 >= s35_m) begin
//        s43_m <= s34;
//    end else begin
//        s43_m <= s35_m;
//    end
//
//    //----------------------------
//    //pipeline 5
//    //----------------------------
//    s50 <= s40_l;
//
//    if (s41 >= s42_m) begin
//        s51_l <= s42_m;
//    end else begin
//        s51_l <= s41;
//    end
//
//    s52 <= s40_l;
//
//    //----------------------------
//    //pipeline 6
//    //----------------------------
//    if (s50 >= s51_l) begin
//        s60_m <= s50;
//        s60_l <= s51_l;
//    end else begin
//        s60_m <= s51_l;
//        s60_l <= s50;
//    end
//
//    s61 <= s52;
//
//    //----------------------------
//    //pipeline 7
//    //----------------------------
//    s70 <= s60_m;
//
//    if (s60_l >= s51_l) begin
//        s71_m <= s60_m;
//    end else begin
//        s71_m <= s51_l;
//    end
//
//    //----------------------------
//    //pipeline 8
//    //----------------------------
//    if (s70 >= s71_m) begin
//        s71_l <= s71_m;
//    end else begin
//        s71_l <= s70;
//    end
