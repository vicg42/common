//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//
// r' = contrast*(r - 128) + 128 + brightness
// g' = contrast*(g - 128) + 128 + brightness
// b' = contrast*(b - 128) + 128 + brightness
//-----------------------------------------------------------------------
module brightness #(
    parameter PIXEL_WIDTH = 8
)(
    input [15:0] contrast_i,
    input [15:0] brightness_i,

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

    input [15:0] dbg_i,
    output reg [15:0] dbg_o = 0,

    input clk
);

//(Q5.6) unsigned fixed point. 64(0x40) is 1.000
localparam  COE_WIDTH = 11;
localparam  COE_FRACTION_WIDTH = 6;

localparam ZERO_FILL = (COE_WIDTH - PIXEL_WIDTH);
localparam OVERFLOW_BIT = COE_FRACTION_WIDTH + PIXEL_WIDTH;
localparam [(COE_WIDTH*2)+1:0] ROUND_ADDER = (1 << (COE_FRACTION_WIDTH - 1)); //0.5

reg [3:0] sr_de_i = 0;
reg [3:0] sr_hs_i = 0;
reg [3:0] sr_vs_i = 0;

reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2):0] br_sum = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2):0] sr_br_sum = 0;

reg [(COE_WIDTH*2)-1:0] mcoe_x128 = 0;
reg [(COE_WIDTH*2)-1:0] r_m = 0;
reg [(COE_WIDTH*2)-1:0] g_m = 0;
reg [(COE_WIDTH*2)-1:0] b_m = 0;

reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2):0] r_m_sum = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2):0] g_m_sum = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2):0] b_m_sum = 0;

reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+1:0] r_m_sum2 = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+1:0] g_m_sum2 = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+1:0] b_m_sum2 = 0;

reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+2:0] r_round = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+2:0] g_round = 0;
reg signed [(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)+2:0] b_round = 0;

wire [COE_WIDTH-1:0] di [0:2];
reg [PIXEL_WIDTH-1:0] do_ [0:2];
wire [COE_WIDTH-1:0] contrast;
wire [7:0] brightness;

reg [15:0] sr_dbg_i [0:3];

genvar k;
generate
    for (k=0; k<3; k=k+1) begin : ch
        assign di[k] = {{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*k +: PIXEL_WIDTH]};
        assign do_o[PIXEL_WIDTH*k +: PIXEL_WIDTH] = do_[k];
    end
endgenerate
assign contrast = contrast_i[0 +: COE_WIDTH];
assign brightness = brightness_i[0 +: 8];

always @ (posedge clk) begin
    //stage0
    if (PIXEL_WIDTH == 8) begin
    br_sum <= $signed({1'b0,8'd128, {COE_FRACTION_WIDTH{1'b0}}}) + $signed({brightness, {COE_FRACTION_WIDTH{1'b0}}});
    mcoe_x128 <= {contrast, 7'd0}; //contrast * 128
    end else begin
    br_sum <= $signed({1'b0,10'd512, {COE_FRACTION_WIDTH{1'b0}}}) + $signed({brightness,2'd0, {COE_FRACTION_WIDTH{1'b0}}});
    mcoe_x128 <= {contrast, 9'd0}; //contrast * 512
    end
    r_m <= contrast * di[0];
    g_m <= contrast * di[1];
    b_m <= contrast * di[2];

    sr_de_i[0] <= de_i;
    sr_hs_i[0] <= hs_i;
    sr_vs_i[0] <= vs_i;
    sr_dbg_i[0] <= dbg_i;

    //stage1
    r_m_sum <= $signed({1'b0, r_m[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)-1:0]}) - $signed({1'b0, mcoe_x128[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)-1:0]});
    g_m_sum <= $signed({1'b0, g_m[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)-1:0]}) - $signed({1'b0, mcoe_x128[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)-1:0]});
    b_m_sum <= $signed({1'b0, b_m[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)-1:0]}) - $signed({1'b0, mcoe_x128[(COE_FRACTION_WIDTH + PIXEL_WIDTH + 2)-1:0]});

    sr_br_sum <= br_sum;

    sr_de_i[1] <= sr_de_i[0];
    sr_hs_i[1] <= sr_hs_i[0];
    sr_vs_i[1] <= sr_vs_i[0];
    sr_dbg_i[1] <= sr_dbg_i[0];

    //stage2
    r_m_sum2 <= r_m_sum + sr_br_sum;
    g_m_sum2 <= g_m_sum + sr_br_sum;
    b_m_sum2 <= b_m_sum + sr_br_sum;

    sr_de_i[2] <= sr_de_i[1];
    sr_hs_i[2] <= sr_hs_i[1];
    sr_vs_i[2] <= sr_vs_i[1];
    sr_dbg_i[2] <= sr_dbg_i[1];

    //stage3
    r_round <= r_m_sum2 + $signed(ROUND_ADDER);
    g_round <= g_m_sum2 + $signed(ROUND_ADDER);
    b_round <= b_m_sum2 + $signed(ROUND_ADDER);

    sr_de_i[3] <= sr_de_i[2];
    sr_hs_i[3] <= sr_hs_i[2];
    sr_vs_i[3] <= sr_vs_i[2];
    sr_dbg_i[3] <= sr_dbg_i[2];

    //stage4
    if (r_round[OVERFLOW_BIT+3])                    do_[0] <= {PIXEL_WIDTH{1'b0}};
    else if (|r_round[OVERFLOW_BIT+2:OVERFLOW_BIT]) do_[0] <= {PIXEL_WIDTH{1'b1}};
    else                                            do_[0] <= r_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (g_round[OVERFLOW_BIT+3])                    do_[1] <= {PIXEL_WIDTH{1'b0}};
    else if (|g_round[OVERFLOW_BIT+2:OVERFLOW_BIT]) do_[1] <= {PIXEL_WIDTH{1'b1}};
    else                                            do_[1] <= g_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];

    if (b_round[OVERFLOW_BIT+3])                    do_[2] <= {PIXEL_WIDTH{1'b0}};
    else if (|b_round[OVERFLOW_BIT+2:OVERFLOW_BIT]) do_[2] <= {PIXEL_WIDTH{1'b1}};
    else                                            do_[2] <= b_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];
    de_o <= sr_de_i[3];
    hs_o <= sr_hs_i[3];
    vs_o <= sr_vs_i[3];
    dbg_o <= sr_dbg_i[3];

end


endmodule
