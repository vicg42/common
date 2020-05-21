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

reg signed [25:0] m_00 = 0;
reg signed [25:0] m_01 = 0;
reg signed [25:0] m_02 = 0, sr_m_02 = 0;
reg signed [26:0] s_00 = 0;
reg signed [27:0] s_01 = 0;
reg signed [28:0] s_02 = 0;
reg signed  [8:0] s_03 = 0;
reg signed  [9:0] res0 = 0;

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

always @(posedge clk) begin
    //Y
    //((CI_A00 * R) + (CI_A01 * G) + (CI_A02 * B)) + CI_C0
    m_00  <= ($signed(CI_A00) * $signed({{5{1'b0}}, r_i}));
    m_01  <= ($signed(CI_A01) * $signed({{5{1'b0}}, g_i}));
    m_02  <= ($signed(CI_A02) * $signed({{5{1'b0}}, b_i}));
    s_00 <= m_00 + m_01;     sr_m_02 <= m_02;
    s_01 <= s_00 + sr_m_02;
    s_02 <= s_01 + $signed(CI_ROUND_ADDER);
    //Clamping
    s_03 <= {s_02[28], s_02[CI_COEF_WIDTH +: CI_WIDTH]}; //[28] - signed

    res0  <= s_03 + $signed(CI_C0);
    //Clamping
    y_o <= (res0[9:8] == 2'd1) ? 8'd255 : //overfolw
           (res0[9:8] == 2'd3) ? 8'd0   : //value < 0
                                 res0[7:0];


    //Cb
    //((CI_A10 * R) + (CI_A11 * G) + (CI_A12 * B)) + CI_C1
    m_10  <= ($signed(CI_A10) * $signed({{5{1'b0}}, r_i}));
    m_11  <= ($signed(CI_A11) * $signed({{5{1'b0}}, g_i}));
    m_12  <= ($signed(CI_A12) * $signed({{5{1'b0}}, b_i}));
    s_10 <= m_10 + m_11;     sr_m_12 <= m_12;
    s_11 <= s_10 + sr_m_12;
    s_12 <= s_11 + $signed(CI_ROUND_ADDER);
    //Clamping
    s_13 <= {s_12[28], s_12[CI_COEF_WIDTH +: CI_WIDTH]}; //[28] - signed

    res1  <= s_13 + $signed(CI_C1);
    //Clamping
    cb_o <= (res1[9:8] == 2'd1) ? 8'd255 : //overfolw
            (res1[9:8] == 2'd3) ? 8'd0   : //value < 0
                                  res1[7:0];


    //Cr
    //((CI_A20 * R) + (CI_A21 * G) + (CI_A22 * B)) + CI_C2
    m_20  <= ($signed(CI_A20) * $signed({{5{1'b0}}, r_i}));
    m_21  <= ($signed(CI_A21) * $signed({{5{1'b0}}, g_i}));
    m_22  <= ($signed(CI_A22) * $signed({{5{1'b0}}, b_i}));
    s_20 <= m_20 + m_21;     sr_m_22 <= m_22;
    s_21 <= s_20 + sr_m_22;
    s_22 <= s_21 + $signed(CI_ROUND_ADDER);
    //Clamping
    s_23 <= {s_22[28], s_22[CI_COEF_WIDTH +: CI_WIDTH]}; //[28] - signed

    res2  <= s_23 + $signed(CI_C2);
    //Clamping
    cr_o <= (res2[9:8] == 2'd1) ? 8'd255 : //overfolw
            (res2[9:8] == 2'd3) ? 8'd0   : //value < 0
                                  res2[7:0];

end


// -------------------------------------------------------------------------
reg [0:6] sr_de_i = 0;
reg [0:6] sr_hs_i = 0;
reg [0:6] sr_vs_i = 0;

always @(posedge clk) begin
    sr_de_i <= {de_i, sr_de_i[0:5]};
    sr_hs_i <= {hs_i, sr_hs_i[0:5]};
    sr_vs_i <= {vs_i, sr_vs_i[0:5]};
end

assign de_o = sr_de_i[6];
assign hs_o = sr_hs_i[6];
assign vs_o = sr_vs_i[6];


endmodule
