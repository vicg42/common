//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 22.05.2018 11:58:37
// Module Name : filter_debayer_hq1
//
// Description :
//
//------------------------------------------------------------------------
module filter_debayer_hq1 #(
    parameter DE_I_PERIOD = 0,
    parameter LINE_SIZE_MAX = 1024,
    parameter DATA_WIDTH = 8
)(
    //
    //mode = 0 - bayer pattern {BGGR}: B G
    //                                 G R
    //
    //mode = 1 - bayer pattern {RGGB}: R G
    //                                 G B
    //
    //mode = 2 - bayer pattern {GBRG}: G B
    //                                 R G
    //
    //mode = 3 - bayer pattern {GRBG}: G R
    //                                 B G
    input [2:0] mode  ,
    input       bypass,

    //input resolution X * Y
    input [DATA_WIDTH-1:0] di_i,
    input                   de_i,
    input                   hs_i,
    input                   vs_i,

    //output resolution (X - 4) * (Y - 4)
    //R do_o[DATA_WIDTH*0 +: DATA_WIDTH]
    //G do_o[DATA_WIDTH*1 +: DATA_WIDTH]
    //B do_o[DATA_WIDTH*2 +: DATA_WIDTH]
    output reg [DATA_WIDTH*3-1:0] do_o,
    output reg                     de_o,
    output reg                     hs_o,
    output reg                     vs_o,

    input clk,
    input rst
);
// -------------------------------------------------------------------------
wire [DATA_WIDTH-1:0] p1;
wire [DATA_WIDTH-1:0] p2;
wire [DATA_WIDTH-1:0] p3;
wire [DATA_WIDTH-1:0] p4;
wire [DATA_WIDTH-1:0] p5;
wire [DATA_WIDTH-1:0] p6;
wire [DATA_WIDTH-1:0] p7;
wire [DATA_WIDTH-1:0] p8;
wire [DATA_WIDTH-1:0] p9;
wire [DATA_WIDTH-1:0] pA;
wire [DATA_WIDTH-1:0] pB;
wire [DATA_WIDTH-1:0] pC;
wire [DATA_WIDTH-1:0] pD;
wire [DATA_WIDTH-1:0] pE;
wire [DATA_WIDTH-1:0] pF;
wire [DATA_WIDTH-1:0] pG;
wire [DATA_WIDTH-1:0] pH;
wire [DATA_WIDTH-1:0] pI;
wire [DATA_WIDTH-1:0] pJ;
wire [DATA_WIDTH-1:0] pK;
wire [DATA_WIDTH-1:0] pL;
wire [DATA_WIDTH-1:0] pM;
wire [DATA_WIDTH-1:0] pN;
wire [DATA_WIDTH-1:0] pO;
wire [DATA_WIDTH-1:0] pP;

wire de;
wire hs;
wire vs;
reg [0:1] sr_de = 0;
reg [0:1] sr_hs = 0;
reg [0:1] sr_vs = 0;
reg [DATA_WIDTH-1:0] sr_do [0:1];

filter_core_5x5 #(
    .DE_I_PERIOD (DE_I_PERIOD),
    .LINE_SIZE_MAX (LINE_SIZE_MAX),
    .DATA_WIDTH (DATA_WIDTH)
) filter_core (
    .bypass(bypass),

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
    .x9 (p9), //can be use like bypass
    .xA (pA),
    .xB (pB),
    .xC (pC),
    .xD (pD),
    .xE (pE),
    .xF (pF),
    .xG (pG),
    .xH (pH),
    .xI (pI),
    .xJ (pJ),
    .xK (pK),
    .xL (pL),
    .xM (pM),
    .xN (pN),
    .xO (pO),
    .xP (pP),

    .de_o(de),
    .hs_o(hs),
    .vs_o(vs),

    .clk (clk),
    .rst (rst)
);


reg [DATA_WIDTH:0]  sum_p13 = 0;
reg [DATA_WIDTH:0]  sum_p79 = 0;

reg [DATA_WIDTH:0]  sum_p28 = 0;
reg [DATA_WIDTH:0]  sum_p46 = 0;

reg [DATA_WIDTH+1:0]  sum_p1379 = 0;
reg [DATA_WIDTH+1:0]  sum_p2846 = 0;

reg [DATA_WIDTH:0]  sr_sum_p28 = 0;
reg [DATA_WIDTH:0]  sr_sum_p46 = 0;

reg [DATA_WIDTH-1:0] sr_p5 [0:1];

reg [DATA_WIDTH-1:0] tst_out;
reg                   test_out_syn = 0;

reg [1:0] sel = 0;


//line[0]: x1 x2 x3 x4 x5
//line[1]: x6 x7 x8 x9 xA
//line[2]: xB xC xD xE xF
//line[3]: xG xH xI xJ xK
//line[4]: xL xM xN xO xP
always @(posedge clk) begin
//    if (de) begin

//TODO: implement filter

//        //----------------------------
//        //pipeline 0
//        //----------------------------
//        //X 0 X
//        //0 0 0
//        //0 0 0
//        sum_p13 <= {1'b0, p1} + {1'b0, p3};
//
//        //0 0 0
//        //0 0 0
//        //X 0 X
//        sum_p79 <= {1'b0, p7} + {1'b0, p9};
//
//        //0 X 0
//        //0 0 0
//        //0 X 0
//        sum_p28 <= {1'b0, p2} + {1'b0, p8};
//
//        //0 0 0
//        //X 0 X
//        //0 0 0
//        sum_p46 <= {1'b0, p4} + {1'b0, p6};
//
//        //0 0 0
//        //0 X 0
//        //0 0 0
//        sr_p5[0] <= p5;
//
//        sr_de[0] <= de;
//        sr_hs[0] <= hs;
//        sr_vs[0] <= vs;
//        sr_do[0] <= p9;
//
//
//        //----------------------------
//        //pipeline 1
//        //----------------------------
//        //X 0 X
//        //0 0 0
//        //X 0 X
//        sum_p1379 <= {1'b0, sum_p13} + {1'b0, sum_p79};
//
//        //0 X 0
//        //X 0 X
//        //0 X 0
//        sum_p2846 <= {1'b0, sum_p28} + {1'b0, sum_p46};
//
//        //0 X 0
//        //0 0 0
//        //0 X 0
//        sr_sum_p28 <= sum_p28;
//
//        //0 0 0
//        //X 0 X
//        //0 0 0
//        sr_sum_p46 <= sum_p46;
//
//        //0 0 0
//        //0 X 0
//        //0 0 0
//        sr_p5[1] <= sr_p5[0];
//
//        sr_de[1] <= sr_de[0];
//        sr_hs[1] <= sr_hs[0];
//        sr_vs[1] <= sr_vs[0];
//        sr_do[1] <= sr_do[0];
//
//
//        //----------------------------
//        //pipeline 2
//        //----------------------------
//        if (bypass) begin
//            //R
//            do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_do[1];
//            //G
//            do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_do[1];
//            //B
//            do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_do[1];
//
//        end else begin
//            case (sel)
//                2'b00 : begin
//                            //----------------------------- [B G B]G B
//                            //bayer pattern {BGGR}:         [G R G]R G
//                            //----------------------------- [B G B]G B
//                            //                               G R G R G
//                            if (mode == 2'd0) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_p5[1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
//
//                            //----------------------------- [R G R]G R
//                            //bayer pattern {RGGB}:         [G B G]B G
//                            //----------------------------- [R G R]G R
//                            //                               G B G B G
//                            end else if (mode == 2'd1) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_p5[1];
//
//                            //----------------------------- [G B G]B G
//                            //bayer pattern {GBRG}:         [R G R]G R
//                            //----------------------------- [G B G]B G
//                            //                               R G R G R
//                            end else if (mode == 2'd2) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
//
//                            //----------------------------- [G R G]R G
//                            //bayer pattern {GRBG}:         [B G B]G B
//                            //----------------------------- [G R G]R G
//                            //                               B G B G B
//                            end else begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
//                            end
//                        end
//
//                2'b01 : begin
//                            //----------------------------- B[G B G]B
//                            //bayer pattern {BGGR}:         G[R G R]G
//                            //----------------------------- B[G B G]B
//                            //                              G R G R G
//                            if (mode == 2'd0) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
//
//                            //----------------------------- R[G R G]R
//                            //bayer pattern {RGGB}:         G[B G B]G
//                            //----------------------------- R[G R G]R
//                            //                              G B G B G
//                            end else if (mode == 2'd1) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
//
//                            //----------------------------- G[B G B]G
//                            //bayer pattern {GBRG}:         R[G R G]R
//                            //----------------------------- G[B G B]G
//                            //                              R G R G R
//                            end else if (mode == 2'd2) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_p5[1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
//
//                            //----------------------------- G[R G R]G
//                            //bayer pattern {GRBG}:         B[G B G]B
//                            //----------------------------- G[R G R]G
//                            //                              B G B G B
//                            end else begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_p5[1];
//                            end
//                        end
//
//                2'b10 : begin
//                            //-----------------------------  B G B G B
//                            //bayer pattern {BGGR}:         [G R G]R G
//                            //----------------------------- [B G B]G B
//                            //                              [G R G]R G
//                            if (mode == 2'd0) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
//
//                            //-----------------------------  R G R G R
//                            //bayer pattern {RGGB}:         [G B G]B G
//                            //----------------------------- [R G R]G R
//                            //                              [G B G]B G
//                            end else if (mode == 2'd1) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
//
//                            //-----------------------------  G B G B G
//                            //bayer pattern {GBRG}:         [R G R]G R
//                            //----------------------------- [G B G]B G
//                            //                              [R G R]G R
//                            end else if (mode == 2'd2) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_p5[1];
//
//                            //-----------------------------  G R G R G
//                            //bayer pattern {GRBG}:         [B G B]G B
//                            //----------------------------- [G R G]R G
//                            //                              [B G B]G B
//                            end else begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_p5[1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
//                            end
//                        end
//
//                2'b11 : begin
//                            //----------------------------- B G B G B
//                            //bayer pattern {BGGR}:         G[R G R]G
//                            //----------------------------- B[G B G]B
//                            //                              G[R G R]G
//                            if (mode == 2'd0) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_p5[1];
//
//                            //----------------------------- R G R G R
//                            //bayer pattern {RGGB}:         G[B G B]G
//                            //----------------------------- R[G R G]R
//                            //                              G[B G B]G
//                            end else if (mode == 2'd1) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_p5[1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
//
//                            //----------------------------- G B G B G
//                            //bayer pattern {GBRG}:         R[G R G]R
//                            //----------------------------- G[B G B]G
//                            //                              R[G R G]R
//                            end else if (mode == 2'd2) begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
//
//                            //----------------------------- G R G R G
//                            //bayer pattern {GRBG}:         B[G B G]B
//                            //----------------------------- G[R G R]G
//                            //                              B[G B G]B
//                            end else begin
//                                //R
//                                do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
//                                //G
//                                do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
//                                //B
//                                do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
//                            end
//                        end
//            endcase
//        end
        de_o <= 1'b0;//sr_de[1];
        hs_o <= 1'b0;//sr_hs[1];
        vs_o <= 1'b0;//sr_vs[1];

        tst_out  <= 0; //sr_p5[1];

//    end
end


always @(posedge clk) begin
    if (!vs) begin
        sel <= 0;

    end else begin
        if (!sr_hs[1] && sr_hs[0]) begin
            sel[1] <= ~sel[1];
        end

        if (sr_hs[1]) begin
            sel[0] <= 1'b0;
        end else begin
            if (sr_de[1]) begin
                sel[0] <= ~sel[0];
            end
        end
    end
end


endmodule
