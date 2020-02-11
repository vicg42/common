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
wire [DATA_WIDTH-1:0] x00;
wire [DATA_WIDTH-1:0] x01;
wire [DATA_WIDTH-1:0] x02;
wire [DATA_WIDTH-1:0] x03;
wire [DATA_WIDTH-1:0] x04;
wire [DATA_WIDTH-1:0] x05;
wire [DATA_WIDTH-1:0] x06;
wire [DATA_WIDTH-1:0] x07;
wire [DATA_WIDTH-1:0] x08;
wire [DATA_WIDTH-1:0] x09;
wire [DATA_WIDTH-1:0] x10;
wire [DATA_WIDTH-1:0] x11;
wire [DATA_WIDTH-1:0] x12;
wire [DATA_WIDTH-1:0] x13;
wire [DATA_WIDTH-1:0] x14;
wire [DATA_WIDTH-1:0] x15;
wire [DATA_WIDTH-1:0] x16;
wire [DATA_WIDTH-1:0] x17;
wire [DATA_WIDTH-1:0] x18;
wire [DATA_WIDTH-1:0] x19;
wire [DATA_WIDTH-1:0] x20;
wire [DATA_WIDTH-1:0] x21;
wire [DATA_WIDTH-1:0] x22;
wire [DATA_WIDTH-1:0] x23;
wire [DATA_WIDTH-1:0] x24;

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

    .x00(x00),
    .x01(x01),
    .x02(x02),
    .x03(x03),
    .x04(x04),
    .x05(x05),
    .x06(x06),
    .x07(x07),
    .x08(x08), //can be use like bypass
    .x09(x09),
    .x10(x10),
    .x11(x11),
    .x12(x12),
    .x13(x13),
    .x14(x14),
    .x15(x15),
    .x16(x16),
    .x17(x17),
    .x18(x18),
    .x19(x19),
    .x20(x20),
    .x21(x21),
    .x22(x22),
    .x23(x23),
    .x24(x24),

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


//line[0]: x00 x01 x02 x03 x04
//line[1]: x05 x06 x07 x08 x09
//line[2]: x10 x11 x12 x13 x14
//line[3]: x15 x16 x17 x18 x19
//line[4]: x20 x21 x22 x23 x24
always @(posedge clk) begin
    //----------------------------
    //pipeline 0
    //----------------------------
    //X 0 X
    //0 0 0
    //0 0 0
    sum_p13 <= {1'b0, x00} + {1'b0, x02};

    //0 0 X 0 0
    //0 0 X 0 0
    //X X X X X
    //0 0 X 0 0
    //0 0 X 0 0
    u38DIN_BCDEF_ = (
                    (float) (din[y+0][x+2] * (-1))
                    + (float) (din[y+1][x+2] * ( 2))

                    + (float) (din[y+2][x+2] * ( 4))

                    + (float) (din[y+3][x+2] * ( 2))
                    + (float) (din[y+4][x+2] * (-1))

                    + (float) (din[y+2][x+0] * (-1))
                    + (float) (din[y+2][x+1] * ( 2))

                    + (float) (din[y+2][x+3] * ( 2))
                    + (float) (din[y+2][x+4] * (-1))
                ) / 8;
    if (u38DIN_BCDEF_ > 255) {
        u38DIN_BCDEF = 255;
    } else if (u38DIN_BCDEF_ < 0) {
        u38DIN_BCDEF = 0;
    } else {
        u38DIN_BCDEF = (UINT8) u38DIN_BCDEF_;
    }

       //0 0 0
       //0 0 0
       //X 0 X
       sum_p79 <= {1'b0, x06} + {1'b0, x08};

       //0 X 0
       //0 0 0
       //0 X 0
       sum_p28 <= {1'b0, x01} + {1'b0, x07};

       //0 0 0
       //X 0 X
       //0 0 0
       sum_p46 <= {1'b0, x03} + {1'b0, x05};

       //0 0 0
       //0 X 0
       //0 0 0
       sr_p5[0] <= x04;

       sr_de[0] <= de;
       sr_hs[0] <= hs;
       sr_vs[0] <= vs;
       sr_do[0] <= x08;


       //----------------------------
       //pipeline 1
       //----------------------------
       //X 0 X
       //0 0 0
       //X 0 X
       sum_p1379 <= {1'b0, sum_p13} + {1'b0, sum_p79};

       //0 X 0
       //X 0 X
       //0 X 0
       sum_p2846 <= {1'b0, sum_p28} + {1'b0, sum_p46};

       //0 X 0
       //0 0 0
       //0 X 0
       sr_sum_p28 <= sum_p28;

       //0 0 0
       //X 0 X
       //0 0 0
       sr_sum_p46 <= sum_p46;

       //0 0 0
       //0 X 0
       //0 0 0
       sr_p5[1] <= sr_p5[0];

       sr_de[1] <= sr_de[0];
       sr_hs[1] <= sr_hs[0];
       sr_vs[1] <= sr_vs[0];
       sr_do[1] <= sr_do[0];


       //----------------------------
       //pipeline 2
       //----------------------------
       if (bypass) begin
           //R
           do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_do[1];
           //G
           do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_do[1];
           //B
           do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_do[1];

       end else begin
           case (sel)
               2'b00 : begin
                           //----------------------------- [B G B]G B
                           //bayer pattern {BGGR}:         [G R G]R G
                           //----------------------------- [B G B]G B
                           //                               G R G R G
                           if (mode == 2'd0) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_p5[1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];

                           //----------------------------- [R G R]G R
                           //bayer pattern {RGGB}:         [G B G]B G
                           //----------------------------- [R G R]G R
                           //                               G B G B G
                           end else if (mode == 2'd1) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_p5[1];

                           //----------------------------- [G B G]B G
                           //bayer pattern {GBRG}:         [R G R]G R
                           //----------------------------- [G B G]B G
                           //                               R G R G R
                           end else if (mode == 2'd2) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];

                           //----------------------------- [G R G]R G
                           //bayer pattern {GRBG}:         [B G B]G B
                           //----------------------------- [G R G]R G
                           //                               B G B G B
                           end else begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
                           end
                       end

               2'b01 : begin
                           //----------------------------- B[G B G]B
                           //bayer pattern {BGGR}:         G[R G R]G
                           //----------------------------- B[G B G]B
                           //                              G R G R G
                           if (mode == 2'd0) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];

                           //----------------------------- R[G R G]R
                           //bayer pattern {RGGB}:         G[B G B]G
                           //----------------------------- R[G R G]R
                           //                              G B G B G
                           end else if (mode == 2'd1) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];

                           //----------------------------- G[B G B]G
                           //bayer pattern {GBRG}:         R[G R G]R
                           //----------------------------- G[B G B]G
                           //                              R G R G R
                           end else if (mode == 2'd2) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_p5[1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];

                           //----------------------------- G[R G R]G
                           //bayer pattern {GRBG}:         B[G B G]B
                           //----------------------------- G[R G R]G
                           //                              B G B G B
                           end else begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_p5[1];
                           end
                       end

               2'b10 : begin
                           //-----------------------------  B G B G B
                           //bayer pattern {BGGR}:         [G R G]R G
                           //----------------------------- [B G B]G B
                           //                              [G R G]R G
                           if (mode == 2'd0) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];

                           //-----------------------------  R G R G R
                           //bayer pattern {RGGB}:         [G B G]B G
                           //----------------------------- [R G R]G R
                           //                              [G B G]B G
                           end else if (mode == 2'd1) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];

                           //-----------------------------  G B G B G
                           //bayer pattern {GBRG}:         [R G R]G R
                           //----------------------------- [G B G]B G
                           //                              [R G R]G R
                           end else if (mode == 2'd2) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_p5[1];

                           //-----------------------------  G R G R G
                           //bayer pattern {GRBG}:         [B G B]G B
                           //----------------------------- [G R G]R G
                           //                              [B G B]G B
                           end else begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_p5[1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
                           end
                       end

               2'b11 : begin
                           //----------------------------- B G B G B
                           //bayer pattern {BGGR}:         G[R G R]G
                           //----------------------------- B[G B G]B
                           //                              G[R G R]G
                           if (mode == 2'd0) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_p5[1];

                           //----------------------------- R G R G R
                           //bayer pattern {RGGB}:         G[B G B]G
                           //----------------------------- R[G R G]R
                           //                              G[B G B]G
                           end else if (mode == 2'd1) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_p5[1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sum_p2846[DATA_WIDTH+1:2];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sum_p1379[DATA_WIDTH+1:2];

                           //----------------------------- G B G B G
                           //bayer pattern {GBRG}:         R[G R G]R
                           //----------------------------- G[B G B]G
                           //                              R[G R G]R
                           end else if (mode == 2'd2) begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];

                           //----------------------------- G R G R G
                           //bayer pattern {GRBG}:         B[G B G]B
                           //----------------------------- G[R G R]G
                           //                              B[G B G]B
                           end else begin
                               //R
                               do_o[DATA_WIDTH*0 +: DATA_WIDTH] <= sr_sum_p46[DATA_WIDTH:1];
                               //G
                               do_o[DATA_WIDTH*1 +: DATA_WIDTH] <= sr_p5[1];
                               //B
                               do_o[DATA_WIDTH*2 +: DATA_WIDTH] <= sr_sum_p28[DATA_WIDTH:1];
                           end
                       end
           endcase
       end
        de_o <= 1'b0;//sr_de[1];
        hs_o <= 1'b0;//sr_hs[1];
        vs_o <= 1'b0;//sr_vs[1];

        tst_out  <= 0; //sr_p5[1];

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
