//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//
// y = (ycoe0*r) + (ycoe1*g) + (ycoe2*b)
//
// r' = y + (r - y)*saturation
// g' = y + (g - y)*saturation
// b' = y + (b - y)*saturation
//-----------------------------------------------------------------------
module saturation #(
    parameter PIXEL_WIDTH = 8
)(
    input [15:0] saturation_i,
    input [15:0] ycoe0_i,
    input [15:0] ycoe1_i,
    input [15:0] ycoe2_i,

    //R [PIXEL_WIDTH*0 +: PIXEL_WIDTH]
    //G [PIXEL_WIDTH*1 +: PIXEL_WIDTH]
    //B [PIXEL_WIDTH*2 +: PIXEL_WIDTH]
    input [(PIXEL_WIDTH*3)-1:0] di_i,
    input                       de_i,
    input                       hs_i,
    input                       vs_i,

    output [(PIXEL_WIDTH*3)-1:0] do_o,
    output reg                   de_o = 0,
    output reg                   hs_o = 0,
    output reg                   vs_o = 0,

    input clk
);

//(Q3.6) unsigned fixed point. 64(0x40) is 1.000
localparam  COE_WIDTH = 9;
localparam  COE_FRACTION_WIDTH = 6;

localparam ZERO_FILL = (COE_WIDTH - PIXEL_WIDTH);
localparam OVERFLOW_BIT = COE_FRACTION_WIDTH + PIXEL_WIDTH;
localparam ROUND_ADDER = (1 << (COE_FRACTION_WIDTH - 1)); //0.5

reg [7:0] sr_de_i = 0;
reg [7:0] sr_hs_i = 0;
reg [7:0] sr_vs_i = 0;

reg [COE_WIDTH-1:0] sr0_di [2:0];
reg [COE_WIDTH-1:0] sr1_di [2:0];
reg [COE_WIDTH-1:0] sr2_di [2:0];
reg [COE_WIDTH-1:0] sr3_di [2:0];
reg [COE_WIDTH-1:0] sr4_di [2:0];

reg [(COE_WIDTH*2)-1:0] yr_m = 0;
reg [(COE_WIDTH*2)-1:0] yg_m = 0;
reg [(COE_WIDTH*2)-1:0] yb_m = 0;

reg [(COE_FRACTION_WIDTH + PIXEL_WIDTH):0] yrg_m = 0;
reg [(COE_FRACTION_WIDTH + PIXEL_WIDTH)+1:0] y = 0;
reg [(COE_FRACTION_WIDTH + PIXEL_WIDTH)+2:0] y_round = 0;
reg [PIXEL_WIDTH-1:0] y_o = 0;

reg [(COE_WIDTH*2)-1:0] r_m = 0;
reg [(COE_WIDTH*2)-1:0] g_m = 0;
reg [(COE_WIDTH*2)-1:0] b_m = 0;

reg [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+1:0] r_sum0 = 0;
reg [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+1:0] g_sum0 = 0;
reg [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+1:0] b_sum0 = 0;

reg [(COE_WIDTH*2)-1:0] r_ym = 0;
reg [(COE_WIDTH*2)-1:0] g_ym = 0;
reg [(COE_WIDTH*2)-1:0] b_ym = 0;

reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+2:0] r_sum1 = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+2:0] g_sum1 = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+2:0] b_sum1 = 0;

reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+3:0] r_round = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+3:0] g_round = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+3:0] b_round = 0;

wire [COE_WIDTH-1:0] di [2:0];
reg [PIXEL_WIDTH-1:0] do_ [2:0];
wire [COE_WIDTH-1:0] saturation;
wire [COE_WIDTH-1:0] ycoe0;
wire [COE_WIDTH-1:0] ycoe1;
wire [COE_WIDTH-1:0] ycoe2;

genvar k;
generate
    for (k=0; k<3; k=k+1) begin : ch
        assign di[k] = {{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*k +: PIXEL_WIDTH]};
        assign do_o[PIXEL_WIDTH*k +: PIXEL_WIDTH] = do_[k];
    end
endgenerate
assign saturation = saturation_i[0 +: COE_WIDTH];
assign ycoe0 = ycoe0_i[0 +: COE_WIDTH];
assign ycoe1 = ycoe1_i[0 +: COE_WIDTH];
assign ycoe2 = ycoe2_i[0 +: COE_WIDTH];

always @ (posedge clk) begin
    //stage0
    //y = (ycoe0*r) + (ycoe1*g) + (ycoe2*b)
    yr_m <= ycoe0 * di[0];
    yg_m <= ycoe1 * di[1];
    yb_m <= ycoe2 * di[2];

    {sr0_di[2], sr0_di[1], sr0_di[0]} <= {di[2], di[1], di[0]};

    sr_de_i[0] <= de_i;
    sr_hs_i[0] <= hs_i;
    sr_vs_i[0] <= vs_i;

    //stage1
    yrg_m <= {1'b0, yr_m[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]} + {1'b0, yg_m[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]};

    {sr1_di[2], sr1_di[1], sr1_di[0]} <= {sr0_di[2], sr0_di[1], sr0_di[0]};

    sr_de_i[1] <= sr_de_i[0];
    sr_hs_i[1] <= sr_hs_i[0];
    sr_vs_i[1] <= sr_vs_i[0];

    //stage2
    //y = (0.299*r) + (0.587*g) + (0.114*b)
    y <= {1'b0, yrg_m} + {2'b00, yb_m[(COE_FRACTION_WIDTH + PIXEL_WIDTH)-1:0]};

    {sr2_di[2], sr2_di[1], sr2_di[0]} <= {sr1_di[2], sr1_di[1], sr1_di[0]};

    sr_de_i[2] <= sr_de_i[1];
    sr_hs_i[2] <= sr_hs_i[1];
    sr_vs_i[2] <= sr_vs_i[1];

    //stage3
    y_round <= {1'b0, y} + ROUND_ADDER;

    {sr3_di[2], sr3_di[1], sr3_di[0]} <= {sr2_di[2], sr2_di[1], sr2_di[0]};

    sr_de_i[3] <= sr_de_i[2];
    sr_hs_i[3] <= sr_hs_i[2];
    sr_vs_i[3] <= sr_vs_i[2];

    //stage4
    if (y_round[OVERFLOW_BIT]) y_o <= {PIXEL_WIDTH{1'b1}};
    else                       y_o <= y_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    r_m <= saturation * sr3_di[0];
    g_m <= saturation * sr3_di[1];
    b_m <= saturation * sr3_di[2];

    {sr4_di[2], sr4_di[1], sr4_di[0]} <= {sr3_di[2], sr3_di[1], sr3_di[0]};

    sr_de_i[4] <= sr_de_i[3];
    sr_hs_i[4] <= sr_hs_i[3];
    sr_vs_i[4] <= sr_vs_i[3];

    //stage5
    r_sum0 <= y_o + r_m[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2):0];
    g_sum0 <= y_o + g_m[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2):0];
    b_sum0 <= y_o + b_m[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2):0];

    r_ym <= y_o * sr4_di[0];
    g_ym <= y_o * sr4_di[1];
    b_ym <= y_o * sr4_di[2];

    sr_de_i[5] <= sr_de_i[4];
    sr_hs_i[5] <= sr_hs_i[4];
    sr_vs_i[5] <= sr_vs_i[4];

    //stage6
    r_sum1 <= $signed({1'b0, r_sum0}) - $signed({1'b0,r_ym[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+1:0]});
    g_sum1 <= $signed({1'b0, g_sum0}) - $signed({1'b0,g_ym[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+1:0]});
    b_sum1 <= $signed({1'b0, b_sum0}) - $signed({1'b0,b_ym[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+1:0]});

    sr_de_i[6] <= sr_de_i[5];
    sr_hs_i[6] <= sr_hs_i[5];
    sr_vs_i[6] <= sr_vs_i[5];

    //stage7
    r_round <= r_sum1 + $signed(ROUND_ADDER);
    g_round <= g_sum1 + $signed(ROUND_ADDER);
    b_round <= b_sum1 + $signed(ROUND_ADDER);

    sr_de_i[7] <= sr_de_i[6];
    sr_hs_i[7] <= sr_hs_i[6];
    sr_vs_i[7] <= sr_vs_i[6];

    //stage8
    if (r_round[OVERFLOW_BIT+3])                    do_[0] <= {PIXEL_WIDTH{1'b0}};
    else if (|r_round[OVERFLOW_BIT+2:OVERFLOW_BIT]) do_[0] <= {PIXEL_WIDTH{1'b1}};
    else                                            do_[0] <= r_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (g_round[OVERFLOW_BIT+3])                    do_[1] <= {PIXEL_WIDTH{1'b0}};
    else if (|g_round[OVERFLOW_BIT+2:OVERFLOW_BIT]) do_[1] <= {PIXEL_WIDTH{1'b1}};
    else                                            do_[1] <= g_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (b_round[OVERFLOW_BIT+3])                    do_[2] <= {PIXEL_WIDTH{1'b0}};
    else if (|b_round[OVERFLOW_BIT+2:OVERFLOW_BIT]) do_[2] <= {PIXEL_WIDTH{1'b1}};
    else                                            do_[2] <= b_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];
    de_o <= sr_de_i[7];
    hs_o <= sr_hs_i[7];
    vs_o <= sr_vs_i[7];

end


endmodule
