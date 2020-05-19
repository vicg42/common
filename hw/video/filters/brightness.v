//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//
// r' = contrast_coe*(r - 128) + 128 + brightness
// g' = contrast_coe*(g - 128) + 128 + brightness
// b' = contrast_coe*(b - 128) + 128 + brightness
//-----------------------------------------------------------------------
module brightness #(
    parameter COE_WIDTH = 16,
    parameter COE_FRACTION_WIDTH = 10,
    parameter PIXEL_WIDTH = 8
)(
    input [15:0] contrast_i, //(Q3.6) unsigned fixed point. 64(0x40) is 1.000
    input [15:0] brightness_i,

    //R [PIXEL_WIDTH*0 +: PIXEL_WIDTH]
    //G [PIXEL_WIDTH*1 +: PIXEL_WIDTH]
    //B [PIXEL_WIDTH*2 +: PIXEL_WIDTH]
    input [(PIXEL_WIDTH*3)-1:0] di_i,
    input                     de_i,
    input                     hs_i,
    input                     vs_i,

    output [(PIXEL_WIDTH*3)-1:0] do_o,
    output reg                     de_o = 0,
    output reg                     hs_o = 0,
    output reg                     vs_o = 0,

    input clk
);

localparam ZERO_FILL = (COE_WIDTH - PIXEL_WIDTH);
localparam OVERFLOW_BIT = COE_FRACTION_WIDTH + PIXEL_WIDTH;
reg [3:0] sr_de_i = 0;
reg [3:0] sr_hs_i = 0;
reg [3:0] sr_vs_i = 0;

wire [COE_WIDTH-1:0] di [2:0];
reg [PIXEL_WIDTH-1:0] do_ [2:0];
genvar k;
generate
    for (k=0; k<3; k=k+1) begin : ch
        assign di[k] = {{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*k +: PIXEL_WIDTH]};
        assign do_o[PIXEL_WIDTH*k +: PIXEL_WIDTH] = do_[k];
    end
endgenerate
wire [COE_WIDTH-1:0] contrast;
assign contrast = contrast_i[0 +: COE_WIDTH];
wire [COE_WIDTH-1:0] brightness;
assign brightness = {{ZERO_FILL{1'b0}}, brightness_i[0 +: COE_WIDTH]};

reg [(COE_WIDTH*2)-1:0] br_sum = 0;
reg [(COE_WIDTH*2)-1:0] sr_br_sum = 0;

reg [(COE_WIDTH*2)-1:0] mcoe_x128 = 0;
reg [(COE_WIDTH*2)-1:0] r_m = 0;
reg [(COE_WIDTH*2)-1:0] g_m = 0;
reg [(COE_WIDTH*2)-1:0] b_m = 0;

reg signed [(COE_WIDTH*2):0] r_m_sum = 0;
reg signed [(COE_WIDTH*2):0] g_m_sum = 0;
reg signed [(COE_WIDTH*2):0] b_m_sum = 0;

reg signed [(COE_WIDTH*2)+1:0] r_m_sum2 = 0;
reg signed [(COE_WIDTH*2)+1:0] g_m_sum2 = 0;
reg signed [(COE_WIDTH*2)+1:0] b_m_sum2 = 0;
localparam [(COE_WIDTH*2)+1:0] ROUND_ADDER = (1 << (COE_FRACTION_WIDTH - 1)); //0.5

reg signed [(COE_WIDTH*2)+2:0] r_m_sum_round = 0;
reg signed [(COE_WIDTH*2)+2:0] g_m_sum_round = 0;
reg signed [(COE_WIDTH*2)+2:0] b_m_sum_round = 0;

always @ (posedge clk) begin
    //stage0
    br_sum <= {128, {COE_FRACTION_WIDTH{1'b0}}} + {brightness, {COE_FRACTION_WIDTH{1'b0}}};

    mcoe_x128 <= contrast * 128; //{contrast[8:0], 7'd0};

    r_m <= contrast * di[0];
    g_m <= contrast * di[1];
    b_m <= contrast * di[2];

    sr_de_i[0] <= de_i;
    sr_hs_i[0] <= hs_i;
    sr_vs_i[0] <= vs_i;

    //stage1
    r_m_sum <= $signed({1'b0, r_m}) - $signed({1'b0, mcoe_x128});
    g_m_sum <= $signed({1'b0, r_m}) - $signed({1'b0, mcoe_x128});
    b_m_sum <= $signed({1'b0, r_m}) - $signed({1'b0, mcoe_x128});

    sr_br_sum <= br_sum;

    sr_de_i[1] <= sr_de_i[0];
    sr_hs_i[1] <= sr_hs_i[0];
    sr_vs_i[1] <= sr_vs_i[0];

    //stage2
    r_m_sum2 <= r_m_sum + $signed({1'b0,sr_br_sum});
    g_m_sum2 <= g_m_sum + $signed({1'b0,sr_br_sum});
    b_m_sum2 <= b_m_sum + $signed({1'b0,sr_br_sum});

    sr_de_i[2] <= sr_de_i[1];
    sr_hs_i[2] <= sr_hs_i[1];
    sr_vs_i[2] <= sr_vs_i[1];

    //stage3
    r_m_sum_round <= r_m_sum2 + $signed(ROUND_ADDER);
    g_m_sum_round <= g_m_sum2 + $signed(ROUND_ADDER);
    b_m_sum_round <= b_m_sum2 + $signed(ROUND_ADDER);

    sr_de_i[3] <= sr_de_i[2];
    sr_hs_i[3] <= sr_hs_i[2];
    sr_vs_i[3] <= sr_vs_i[2];

    //stage3
    if (r_m_sum_round[OVERFLOW_BIT+3])                    do_[0] <= {PIXEL_WIDTH{1'b0}};
    else if (|r_m_sum_round[OVERFLOW_BIT+2:OVERFLOW_BIT]) do_[0] <= {PIXEL_WIDTH{1'b1}};
    else                                                  do_[0] <= r_m_sum_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (g_m_sum_round[OVERFLOW_BIT+3])                    do_[1] <= {PIXEL_WIDTH{1'b0}};
    else if (|g_m_sum_round[OVERFLOW_BIT+2:OVERFLOW_BIT]) do_[1] <= {PIXEL_WIDTH{1'b1}};
    else                                                  do_[1] <= g_m_sum_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (b_m_sum_round[OVERFLOW_BIT+3])                    do_[2] <= {PIXEL_WIDTH{1'b0}};
    else if (|b_m_sum_round[OVERFLOW_BIT+2:OVERFLOW_BIT]) do_[2] <= {PIXEL_WIDTH{1'b1}};
    else                                                  do_[2] <= b_m_sum_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];
    de_o <= sr_de_i[3];
    hs_o <= sr_hs_i[3];
    vs_o <= sr_vs_i[3];

end


endmodule
