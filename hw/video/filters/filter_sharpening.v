module filter_sharpening #(
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
    output reg [DATA_WIDTH-1:0] do_o = 0,
    output reg de_o = 0,
    output reg hs_o = 0,
    output reg vs_o = 0,

    input clk,
    input rst
);
// -------------------------------------------------------------------------
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

localparam PIPELINE = 3;

reg [15:0] mp5 = 0;
reg [8:0]  sum_p46 = 0;
reg [8:0]  sum_p28 = 0;

reg [15:0] sum_p456 = 0;
reg [8:0]  sr_sum_p28 = 0;

reg [15:0]  sum_p45628 = 0;

reg [PIPELINE-1:0] sr_de = 0;
reg [PIPELINE-1:0] sr_hs = 0;
reg [PIPELINE-1:0] sr_vs = 0;
reg [DATA_WIDTH-1:0]    sr_do [PIPELINE-1:0];


// p1 p2 p3
// p4 p5 p6
// p7 p8 p9

//sharpening operator
//  0   -1   0
//  -1   5  -1
//  0   -1   0
always @(posedge clk) begin
    //pipeline 0
    mp5[15:0] <= p5[7:0] * 8'd5;
    sum_p46[8:0] <= {1'b0, p4[7:0]} + {1'b0, p6[7:0]};
    sum_p28[8:0] <= {1'b0, p2[7:0]} + {1'b0, p8[7:0]};

    sr_de[0] <= de;
    sr_hs[0] <= hs;
    sr_vs[0] <= vs;

    //pipeline 1
    sum_p456[15:0] <= mp5[15:0] - {7'b0, sum_p46[8:0]};
    sr_sum_p28 <= sum_p28[8:0];

    sr_de[1] <= sr_de[0];
    sr_hs[1] <= sr_hs[0];
    sr_vs[1] <= sr_vs[0];
    sr_do[1] <= sr_do[0];

    //pipeline 2
    sum_p45628 <= sum_p456[15:0] - {7'b0, sr_sum_p28};

    sr_de[2] <= sr_de[1];
    sr_hs[2] <= sr_hs[1];
    sr_vs[2] <= sr_vs[1];
    sr_do[2] <= sr_do[1];

    //stage out (clamping)
    if (sum_p45628[15]) begin //result < 0
        do_o <= {8{1'b0}};
    end else if (sum_p45628[8]) begin //overflow
        do_o = {8{1'b1}};
    end else begin
        do_o <= sum_p45628[7:0];
    end
    de_o <= sr_de[2];
    hs_o <= sr_hs[2];
    vs_o <= sr_vs[2];
end


endmodule
