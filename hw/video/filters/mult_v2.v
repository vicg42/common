//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//
// |r|   | coe[0] coe[1] coe[2] | = r'
// |g| * | coe[3] coe[4] coe[5] | = g'
// |b|   | coe[6] coe[7] coe[8] | = b'
//-----------------------------------------------------------------------
module mult_v2 #(
    parameter COE_WIDTH = 16, //(Q4.10) signed fixed point. 1024(0x400) is 1.000
    parameter COE_FRACTION_WIDTH = 10,
    parameter COE_COUNT = 9,
    parameter PIXEL_WIDTH = 8
)(
    input [(COE_WIDTH*COE_COUNT)-1:0] coe_i,

    //R [PIXEL_WIDTH*0 +: PIXEL_WIDTH]
    //G [PIXEL_WIDTH*1 +: PIXEL_WIDTH]
    //B [PIXEL_WIDTH*2 +: PIXEL_WIDTH]
    input [(PIXEL_WIDTH*3)-1:0] di_i,
    input                       de_i,
    input                       hs_i,
    input                       vs_i,

    output reg [(PIXEL_WIDTH*3)-1:0] do_o = 0,
    output reg                       de_o = 0,
    output reg                       hs_o = 0,
    output reg                       vs_o = 0,

    input clk,
    input rst
);

wire [13:0] coe [COE_COUNT-1:0];
genvar k0;
generate
    for (k0=0; k0<COE_COUNT; k0=k0+1) begin
        assign coe[k0] = coe_i[(k0*COE_WIDTH) +: 14];
    end
endgenerate

localparam ZERO_FILL = (14 - PIXEL_WIDTH);
localparam OVERFLOW_BIT = COE_FRACTION_WIDTH + PIXEL_WIDTH;
localparam [31:0] ROUND_ADDER = (1 << (COE_FRACTION_WIDTH - 1)); //0.5
reg signed [27:0] r_mr = 0, g_mr = 0, b_mr = 0;
reg signed [27:0] r_mg = 0, g_mg = 0, b_mg = 0;
reg signed [27:0] r_mb = 0, g_mb = 0, b_mb = 0;

reg signed [28:0] r_mrg = 0;
reg signed [28:0] g_mrg = 0;
reg signed [28:0] b_mrg = 0;
reg signed [27:0] sr_r_mb = 0;
reg signed [27:0] sr_g_mb = 0;
reg signed [27:0] sr_b_mb = 0;

reg signed [29:0] r_mrgb = 0;
reg signed [29:0] g_mrgb = 0;
reg signed [29:0] b_mrgb = 0;
reg signed [30:0] r_mrgb_round = 0;
reg signed [30:0] g_mrgb_round = 0;
reg signed [30:0] b_mrgb_round = 0;

reg [3:0] sr_de_i = 0;
reg [3:0] sr_hs_i = 0;
reg [3:0] sr_vs_i = 0;
always @ (posedge clk) begin
    //stage0
    r_mr <= $signed(coe[0]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH]});
    r_mg <= $signed(coe[1]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*1 +: PIXEL_WIDTH]});
    r_mb <= $signed(coe[2]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*2 +: PIXEL_WIDTH]});
    g_mr <= $signed(coe[3]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH]});
    g_mg <= $signed(coe[4]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*1 +: PIXEL_WIDTH]});
    g_mb <= $signed(coe[5]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*2 +: PIXEL_WIDTH]});
    b_mr <= $signed(coe[6]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH]});
    b_mg <= $signed(coe[7]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*1 +: PIXEL_WIDTH]});
    b_mb <= $signed(coe[8]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*2 +: PIXEL_WIDTH]});
    sr_de_i[0] <= de_i;
    sr_hs_i[0] <= hs_i;
    sr_vs_i[0] <= vs_i;

    //stage1
    r_mrg <= r_mr + r_mg; sr_r_mb <= r_mb;
    g_mrg <= g_mr + g_mg; sr_g_mb <= g_mb;
    b_mrg <= b_mr + b_mg; sr_b_mb <= b_mb;
    sr_de_i[1] <= sr_de_i[0];
    sr_hs_i[1] <= sr_hs_i[0];
    sr_vs_i[1] <= sr_vs_i[0];

    //stage2
    r_mrgb <= r_mrg + sr_r_mb;
    g_mrgb <= g_mrg + sr_g_mb;
    b_mrgb <= b_mrg + sr_b_mb;
    sr_de_i[2] <= sr_de_i[1];
    sr_hs_i[2] <= sr_hs_i[1];
    sr_vs_i[2] <= sr_vs_i[1];

    //stage3
    r_mrgb_round <= r_mrgb + $signed(ROUND_ADDER);
    g_mrgb_round <= g_mrgb + $signed(ROUND_ADDER);
    b_mrgb_round <= b_mrgb + $signed(ROUND_ADDER);
    sr_de_i[3] <= sr_de_i[2];
    sr_hs_i[3] <= sr_hs_i[2];
    sr_vs_i[3] <= sr_vs_i[2];

    //stage4
    if (|r_mrgb_round[31:OVERFLOW_BIT+2])                do_o[PIXEL_WIDTH*0 +: PIXEL_WIDTH] = {PIXEL_WIDTH{1'b0}};
    else if (|r_mrgb_round[OVERFLOW_BIT+1:OVERFLOW_BIT]) do_o[PIXEL_WIDTH*0 +: PIXEL_WIDTH] = {PIXEL_WIDTH{1'b1}};
    else                                                 do_o[PIXEL_WIDTH*0 +: PIXEL_WIDTH] = r_mrgb_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (|g_mrgb_round[31:OVERFLOW_BIT+2])                do_o[PIXEL_WIDTH*1 +: PIXEL_WIDTH] = {PIXEL_WIDTH{1'b0}};
    else if (|g_mrgb_round[OVERFLOW_BIT+1:OVERFLOW_BIT]) do_o[PIXEL_WIDTH*1 +: PIXEL_WIDTH] = {PIXEL_WIDTH{1'b1}};
    else                                                 do_o[PIXEL_WIDTH*1 +: PIXEL_WIDTH] = g_mrgb_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (|b_mrgb_round[31:OVERFLOW_BIT+2])                do_o[PIXEL_WIDTH*2 +: PIXEL_WIDTH] = {PIXEL_WIDTH{1'b0}};
    else if (|b_mrgb_round[OVERFLOW_BIT+1:OVERFLOW_BIT]) do_o[PIXEL_WIDTH*2 +: PIXEL_WIDTH] = {PIXEL_WIDTH{1'b1}};
    else                                                 do_o[PIXEL_WIDTH*2 +: PIXEL_WIDTH] = b_mrgb_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    de_o <= sr_de_i[3];
    hs_o <= sr_hs_i[3];
    vs_o <= sr_vs_i[3];

end


`ifdef SIM_DBG

wire [PIXEL_WIDTH-1:0] di [3-1:0];
genvar k1;
generate
    for (k1=0; k1<3; k1=k1+1) begin
        assign di[k1] = di_i[(k1*PIXEL_WIDTH) +: PIXEL_WIDTH];
    end
endgenerate

wire [PIXEL_WIDTH-1:0] do [3-1:0];
genvar k2;
generate
    for (k2=0; k2<3; k2=k2+1) begin
        assign do[k2] = do_o[(k2*PIXEL_WIDTH) +: PIXEL_WIDTH];
    end
endgenerate
`endif

endmodule
