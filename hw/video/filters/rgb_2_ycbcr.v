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
(* multstyle = "dsp" *) module rgb_2_ycbcr #(
    parameter COE_WIDTH = 13, //(Q3.10) unsigned fixed point. 1024(0x400) is 1.000
                                //example:
                                //CI_A10 =  16'd1024 =  1.000*1024
                                //CI_A11 = -16'd352  = -0.343*1024
                                //CI_A12 = -16'd728  = -0.711*1024
    parameter COE_FRACTION_WIDTH = 10,
    parameter PIXEL_WIDTH = 8
)(
    input [15:0] CI_A00,
    input [15:0] CI_A01,
    input [15:0] CI_A02,

    input [15:0] CI_A10,
    input [15:0] CI_A11,
    input [15:0] CI_A12,

    input [15:0] CI_A20,
    input [15:0] CI_A21,
    input [15:0] CI_A22,

    input [15:0] CI_C0 ,
    input [15:0] CI_C1 ,
    input [15:0] CI_C2 ,

    //input data
    input [PIXEL_WIDTH-1:0] r_i,
    input [PIXEL_WIDTH-1:0] g_i,
    input [PIXEL_WIDTH-1:0] b_i,
    input de_i,
    input vs_i,
    input hs_i,

    input [PIXEL_WIDTH-1:0] bypass_di,

    //output data
    output reg [PIXEL_WIDTH-1:0] y_o  = 0,
    output reg [PIXEL_WIDTH-1:0] cb_o = 0,
    output reg [PIXEL_WIDTH-1:0] cr_o = 0,
    output reg de_o = 1'b0,
    output reg vs_o = 1'b0,
    output reg hs_o = 1'b0,

    output reg [PIXEL_WIDTH-1:0] bypass_do,

    //system
    input clk
);

localparam ZERO_FILL = (COE_WIDTH - PIXEL_WIDTH);
localparam OVERFLOW_BIT = COE_FRACTION_WIDTH + PIXEL_WIDTH;
localparam [(COE_WIDTH*2)+3:0] ROUND_ADDER = (1 << (COE_FRACTION_WIDTH - 1)); //0.5

reg signed [(COE_WIDTH*2)-1:0] m_00 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_01 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_02 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_10 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_11 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_12 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_20 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_21 = 0;
reg signed [(COE_WIDTH*2)-1:0] m_22 = 0;

reg signed [(COE_WIDTH*2):0] s_00 = 0;
reg signed [(COE_WIDTH*2):0] s_10 = 0;
reg signed [(COE_WIDTH*2):0] s_20 = 0;
reg signed [(COE_WIDTH*2):0] sr_m_02 = 0;
reg signed [(COE_WIDTH*2):0] sr_m_12 = 0;
reg signed [(COE_WIDTH*2):0] sr_m_22 = 0;

reg signed [(COE_WIDTH*2)+1:0] s_01 = 0;
reg signed [(COE_WIDTH*2)+1:0] s_11 = 0;
reg signed [(COE_WIDTH*2)+1:0] s_21 = 0;

reg signed [(COE_WIDTH*2)+2:0] s_02 = 0;
reg signed [(COE_WIDTH*2)+2:0] s_12 = 0;
reg signed [(COE_WIDTH*2)+2:0] s_22 = 0;

reg signed [(COE_WIDTH*2)+3:0] y_round = 0;
reg signed [(COE_WIDTH*2)+3:0] cb_round = 0;
reg signed [(COE_WIDTH*2)+3:0] cr_round = 0;

wire [COE_WIDTH-1:0] r;
wire [COE_WIDTH-1:0] g;
wire [COE_WIDTH-1:0] b;
assign r = {{ZERO_FILL{1'b0}}, r_i[(PIXEL_WIDTH*0) +: PIXEL_WIDTH]};
assign g = {{ZERO_FILL{1'b0}}, g_i[(PIXEL_WIDTH*0) +: PIXEL_WIDTH]};
assign b = {{ZERO_FILL{1'b0}}, b_i[(PIXEL_WIDTH*0) +: PIXEL_WIDTH]};

wire [COE_WIDTH-1:0] coe00;
wire [COE_WIDTH-1:0] coe01;
wire [COE_WIDTH-1:0] coe02;
wire [COE_WIDTH-1:0] coe10;
wire [COE_WIDTH-1:0] coe11;
wire [COE_WIDTH-1:0] coe12;
wire [COE_WIDTH-1:0] coe20;
wire [COE_WIDTH-1:0] coe21;
wire [COE_WIDTH-1:0] coe22;
wire [(COE_WIDTH*2)+1:0] coe0 ;
wire [(COE_WIDTH*2)+1:0] coe1 ;
wire [(COE_WIDTH*2)+1:0] coe2 ;

assign coe00 = CI_A00[0 +: COE_WIDTH];
assign coe01 = CI_A01[0 +: COE_WIDTH];
assign coe02 = CI_A02[0 +: COE_WIDTH];
assign coe10 = CI_A10[0 +: COE_WIDTH];
assign coe11 = CI_A11[0 +: COE_WIDTH];
assign coe12 = CI_A12[0 +: COE_WIDTH];
assign coe20 = CI_A20[0 +: COE_WIDTH];
assign coe21 = CI_A21[0 +: COE_WIDTH];
assign coe22 = CI_A22[0 +: COE_WIDTH];
assign coe0 = {CI_C0[0 +: PIXEL_WIDTH], {COE_FRACTION_WIDTH{1'b0}}};
assign coe1 = {CI_C1[0 +: PIXEL_WIDTH], {COE_FRACTION_WIDTH{1'b0}}};
assign coe2 = {CI_C2[0 +: PIXEL_WIDTH], {COE_FRACTION_WIDTH{1'b0}}};

reg [0:4] sr_de_i = 0;
reg [0:4] sr_hs_i = 0;
reg [0:4] sr_vs_i = 0;
reg [PIXEL_WIDTH-1:0] sr_bypass_di [0:4];

always @(posedge clk) begin
    //----- stage0
    //Y :  (CI_A00 * R), (CI_A01 * G), (CI_A02 * B)
    m_00 <= $signed(coe00) * $signed(r);
    m_01 <= $signed(coe01) * $signed(g);
    m_02 <= $signed(coe02) * $signed(b);

    //Cb:  (CI_A10 * R), (CI_A11 * G), (CI_A12 * B)
    m_10 <= $signed(coe10) * $signed(r);
    m_11 <= $signed(coe11) * $signed(g);
    m_12 <= $signed(coe12) * $signed(b);

    //Cr:  (CI_A20 * R), (CI_A21 * G), (CI_A22 * B)
    m_20 <= $signed(coe20) * $signed(r);
    m_21 <= $signed(coe21) * $signed(g);
    m_22 <= $signed(coe22) * $signed(b);

    sr_de_i[0] <= de_i;
    sr_hs_i[0] <= hs_i;
    sr_vs_i[0] <= vs_i;

    sr_bypass_di[0] <= bypass_di;

    //----- stage1
    //Y :  (CI_A00 * R) + (CI_A01 * G)
    s_00 <= {m_00[(COE_WIDTH*2)-1], m_00[(COE_WIDTH*2)-1:0]} + {m_01[(COE_WIDTH*2)-1],m_01[(COE_WIDTH*2)-1:0]};
    sr_m_02 <= {m_02[(COE_WIDTH*2)-1], m_02[(COE_WIDTH*2)-1:0]};

    //Cb:  (CI_A10 * R) + (CI_A11 * G)
    s_10 <= {m_10[(COE_WIDTH*2)-1], m_10[(COE_WIDTH*2)-1:0]} + {m_11[(COE_WIDTH*2)-1],m_11[(COE_WIDTH*2)-1:0]};
    sr_m_12 <= {m_12[(COE_WIDTH*2)-1], m_12[(COE_WIDTH*2)-1:0]};

    //Cr:  (CI_A20 * R) + (CI_A21 * G)
    s_20 <= {m_20[(COE_WIDTH*2)-1], m_20[(COE_WIDTH*2)-1]} + {m_21[(COE_WIDTH*2)-1],m_11[(COE_WIDTH*2)-1]};
    sr_m_22 <= {m_22[(COE_WIDTH*2)-1], m_22[(COE_WIDTH*2)-1:0]};

    sr_de_i[1] <= sr_de_i[0];
    sr_hs_i[1] <= sr_hs_i[0];
    sr_vs_i[1] <= sr_vs_i[0];

    sr_bypass_di[1] <= sr_bypass_di[0];

    //----- stage2
    //Y :  (CI_A00 * R) + (CI_A01 * G) + (CI_A02 * B)
    s_01 <= {s_00[(COE_WIDTH*2):0], s_00[(COE_WIDTH*2):0]} + {sr_m_02[(COE_WIDTH*2):0],sr_m_02[(COE_WIDTH*2):0]};

    //Cb:  (CI_A10 * R) + (CI_A11 * G) + (CI_A12 * B)
    s_11 <= {s_10[(COE_WIDTH*2):0], s_10[(COE_WIDTH*2):0]} + {sr_m_12[(COE_WIDTH*2):0],sr_m_12[(COE_WIDTH*2):0]};

    //Cr:  (CI_A20 * R) + (CI_A21 * G) + (CI_A22 * B)
    s_21 <= {s_20[(COE_WIDTH*2):0], s_20[(COE_WIDTH*2):0]} + {sr_m_22[(COE_WIDTH*2):0],sr_m_22[(COE_WIDTH*2):0]};

    sr_de_i[2] <= sr_de_i[1];
    sr_hs_i[2] <= sr_hs_i[1];
    sr_vs_i[2] <= sr_vs_i[1];

    sr_bypass_di[2] <= sr_bypass_di[1];

    //----- stage3
    s_02  <= {s_01[(COE_WIDTH*2)+1],s_01[(COE_WIDTH*2)+1:0]} + $signed(coe0);
    s_12  <= {s_11[(COE_WIDTH*2)+1],s_11[(COE_WIDTH*2)+1:0]} + $signed(coe1);
    s_22  <= {s_21[(COE_WIDTH*2)+1],s_21[(COE_WIDTH*2)+1:0]} + $signed(coe2);

    sr_de_i[3] <= sr_de_i[2];
    sr_hs_i[3] <= sr_hs_i[2];
    sr_vs_i[3] <= sr_vs_i[2];

    sr_bypass_di[3] <= sr_bypass_di[2];

    //----- stage4
    y_round  <= s_02 + $signed(ROUND_ADDER);
    cb_round <= s_12 + $signed(ROUND_ADDER);
    cr_round <= s_22 + $signed(ROUND_ADDER);

    sr_de_i[4] <= sr_de_i[3];
    sr_hs_i[4] <= sr_hs_i[3];
    sr_vs_i[4] <= sr_vs_i[3];

    sr_bypass_di[4] <= sr_bypass_di[3];

    //----- stage5
    if (y_round[OVERFLOW_BIT+2])                    y_o <= {PIXEL_WIDTH{1'b0}};
    else if (|y_round[OVERFLOW_BIT+1:OVERFLOW_BIT]) y_o <= {PIXEL_WIDTH{1'b1}};
    else                                            y_o <= y_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (cb_round[OVERFLOW_BIT+2])                    cb_o <= {PIXEL_WIDTH{1'b0}};
    else if (|cb_round[OVERFLOW_BIT+1:OVERFLOW_BIT]) cb_o <= {PIXEL_WIDTH{1'b1}};
    else                                             cb_o <= cb_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (cr_round[OVERFLOW_BIT+2])                    cr_o <= {PIXEL_WIDTH{1'b0}};
    else if (|cr_round[OVERFLOW_BIT+1:OVERFLOW_BIT]) cr_o <= {PIXEL_WIDTH{1'b1}};
    else                                             cr_o <= cr_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    de_o <= sr_de_i[4];
    hs_o <= sr_hs_i[4];
    vs_o <= sr_vs_i[4];

    bypass_do <= sr_bypass_di[4];

end


endmodule
