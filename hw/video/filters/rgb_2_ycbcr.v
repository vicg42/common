//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 11.08.2016 15:39:00
// Module Name : rgb_2_ycbcr
//
// Description :
// | Y |   | A00 A01 A02 |   | R |   | C0 |
// | Cb| = | A10 A11 A12 | * | G | + | C1 |
// | Cr|   | A20 A21 A22 |   | B |   | C2 |
//-----------------------------------------------------------------------
(* multstyle = "dsp" *) module rgb_2_ycbcr(
    //Coef. 3.10 encoding
    //example:
    //CI_A10 =  13'd1024; //  1.000*1024
    //CI_A11 = -13'd352 ; // -0.343*1024
    //CI_A12 = -13'd728 ; // -0.711*1024
    input [12:0] CI_A00,
    input [12:0] CI_A01,
    input [12:0] CI_A02,

    input [12:0] CI_A10,
    input [12:0] CI_A11,
    input [12:0] CI_A12,

    input [12:0] CI_A20,
    input [12:0] CI_A21,
    input [12:0] CI_A22,

    input [12:0] CI_C0 ,
    input [12:0] CI_C1 ,
    input [12:0] CI_C2 ,

    //input data
    input [7:0] r_i,
    input [7:0] g_i,
    input [7:0] b_i,
    input de_i,
    input vs_i,
    input hs_i,

    //output data
    output reg [7:0] y_o  = 0,
    output reg [7:0] cb_o = 0,
    output reg [7:0] cr_o = 0,
    output de_o,
    output vs_o,
    output hs_o,

    //system
    input clk
);

//(Q3.10) signed fixed point. 1024(0x400) is 1.000
localparam  COE_WIDTH = 13;
localparam  COE_FRACTION_WIDTH = 10;

localparam ZERO_FILL = (COE_WIDTH - PIXEL_WIDTH);
localparam OVERFLOW_BIT = COE_FRACTION_WIDTH + PIXEL_WIDTH;
localparam ROUND_ADDER = (1 << (COE_FRACTION_WIDTH - 1)); //0.5

reg signed [(COE_WIDTH*2)-1:0] m_00 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_01 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_02 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_10 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_11 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_12 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_20 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_21 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_22 = 0;

reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH):0] s_00 = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH):0] s_10 = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH):0] s_20 = 0;

reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH)+1:0] s_01 = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH)+1:0] s_11 = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH)+1:0] s_21 = 0;

reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH)+2:0] s_02 = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH)+2:0] s_12 = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH)+2:0] s_22 = 0;

reg signed [25:0] m_10 = 0;
reg signed [25:0] m_11 = 0;
reg signed [25:0] m_12 = 0, sr_m_12 = 0;
reg signed [26:0] s_10 = 0;
reg signed [27:0] s_11 = 0;
reg signed [28:0] s_12 = 0;
reg signed  [8:0] s_13 = 0;
reg signed  [9:0] res1 = 0;

reg signed [25:0] m_20 = 0;
reg signed [25:0] m_21 = 0;
reg signed [25:0] m_22 = 0, sr_m_22 = 0;
reg signed [26:0] s_20 = 0;
reg signed [27:0] s_21 = 0;
reg signed [28:0] s_22 = 0;
reg signed  [8:0] s_23 = 0;
reg signed  [9:0] res2 = 0;

localparam CI_WIDTH = 8;
localparam CI_COEF_WIDTH = 10;
localparam CI_OVERFLOW_BIT = CI_COEF_WIDTH + CI_WIDTH;
localparam [28:0] CI_ROUND_ADDER = (1 << (CI_COEF_WIDTH - 1));


assign r = {{ZERO_FILL{1'b0}}, r_i[PIXEL_WIDTH +: PIXEL_WIDTH]};
assign g = {{ZERO_FILL{1'b0}}, g_i[PIXEL_WIDTH +: PIXEL_WIDTH]};
assign b = {{ZERO_FILL{1'b0}}, b_i[PIXEL_WIDTH +: PIXEL_WIDTH]};

assign y_o[PIXEL_WIDTH +: PIXEL_WIDTH] = y;
assign cb_o[PIXEL_WIDTH +: PIXEL_WIDTH] = cb;
assign cr_o[PIXEL_WIDTH +: PIXEL_WIDTH] = cr;

assign coe00 = CI_A00[0 +: COE_WIDTH];
assign coe01 = CI_A01[0 +: COE_WIDTH];
assign coe02 = CI_A02[0 +: COE_WIDTH];
assign coe10 = CI_A10[0 +: COE_WIDTH];
assign coe11 = CI_A11[0 +: COE_WIDTH];
assign coe12 = CI_A12[0 +: COE_WIDTH];
assign coe20 = CI_A20[0 +: COE_WIDTH];
assign coe21 = CI_A21[0 +: COE_WIDTH];
assign coe22 = CI_A22[0 +: COE_WIDTH];

assign coe0 = CI_C0[0 +: COE_WIDTH];
assign coe1 = CI_C1[0 +: COE_WIDTH];
assign coe2 = CI_C2[0 +: COE_WIDTH];

always @(posedge clk) begin
    //stage1
    //((CI_A00 * R) + (CI_A01 * G) + (CI_A02 * B)) + CI_C0
    m_00 <= $signed(coe00) * $signed(r);
    m_01 <= $signed(coe01) * $signed(g);
    m_02 <= $signed(coe02) * $signed(b);

    m_10 <= $signed(coe10) * $signed(r);
    m_11 <= $signed(coe11) * $signed(g);
    m_12 <= $signed(coe12) * $signed(b);

    m_20 <= $signed(coe20) * $signed(r);
    m_21 <= $signed(coe21) * $signed(g);
    m_22 <= $signed(coe22) * $signed(b);

    sr_de_i[0] <= de_i;
    sr_hs_i[0] <= hs_i;
    sr_vs_i[0] <= vs_i;

    //stage2
    s_00 <= (m_00[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1], m_01[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]) + (m_01[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1],m_01[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]);
    s_10 <= (m_10[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1], m_11[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]) + (m_11[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1],m_11[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]);
    s_20 <= (m_10[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1], m_11[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]) + (m_11[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1],m_11[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]);

    sr_m_02 <= m_02;
    sr_m_12 <= m_12;
    sr_m_22 <= m_22;

    sr_de_i[1] <= sr_de_i[0];
    sr_hs_i[1] <= sr_hs_i[0];
    sr_vs_i[1] <= sr_vs_i[0];

    //stage3
    s_01 <= {{1{s_00[(COE_FRACTION_WIDTH + PIXEL_WIDTH)]}}, s_00[(COE_FRACTION_WIDTH + PIXEL_WIDTH):0]} + {sr_m_02[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]};
    s_11 <= {{1{s_10[(COE_FRACTION_WIDTH + PIXEL_WIDTH)]}}, s_10[(COE_FRACTION_WIDTH + PIXEL_WIDTH):0]} + {sr_m_12[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]};
    s_21 <= {{1{s_20[(COE_FRACTION_WIDTH + PIXEL_WIDTH)]}}, s_20[(COE_FRACTION_WIDTH + PIXEL_WIDTH):0]} + {sr_m_22[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]};

    sr_de_i[2] <= sr_de_i[1];
    sr_hs_i[2] <= sr_hs_i[1];
    sr_vs_i[2] <= sr_vs_i[1];

    //stage4
    s_02  <= s_23 + $signed(coe0);
    s_12  <= s_23 + $signed(coe1);
    s_22  <= s_23 + $signed(coe2);

    sr_de_i[3] <= sr_de_i[2];
    sr_hs_i[3] <= sr_hs_i[2];
    sr_vs_i[3] <= sr_vs_i[2];

    //stage5
    s_03 <= s_01 + $signed(CI_ROUND_ADDER);
    s_13 <= s_11 + $signed(CI_ROUND_ADDER);
    s_23 <= s_21 + $signed(CI_ROUND_ADDER);

    sr_de_i[4] <= sr_de_i[3];
    sr_hs_i[4] <= sr_hs_i[3];
    sr_vs_i[4] <= sr_vs_i[3];

    //stage6
    if (s_04_round[OVERFLOW_BIT+2])                    y <= {PIXEL_WIDTH{1'b0}};
    else if (|s_04_round[OVERFLOW_BIT+1:OVERFLOW_BIT]) y <= {PIXEL_WIDTH{1'b1}};
    else                                               y <= s_04[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (s_14_round[OVERFLOW_BIT+2])                    cb <= {PIXEL_WIDTH{1'b0}};
    else if (|s_14_round[OVERFLOW_BIT+1:OVERFLOW_BIT]) cb <= {PIXEL_WIDTH{1'b1}};
    else                                               cb <= s_14[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (s_14_round[OVERFLOW_BIT+2])                    cr <= {PIXEL_WIDTH{1'b0}};
    else if (|s_14_round[OVERFLOW_BIT+1:OVERFLOW_BIT]) cr <= {PIXEL_WIDTH{1'b1}};
    else                                               cr <= s_24[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    de_o <= sr_de_i[4];
    hs_o <= sr_hs_i[4];
    vs_o <= sr_vs_i[4];

end


endmodule
