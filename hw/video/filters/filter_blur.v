//-----------------------------------------------------------------------
//
// Engineer    : Golovachenko Victor
//
//------------------------------------------------------------------------
module filter_blur #(
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

localparam PIPELINE = 4;

reg [7:0]  sr_p7 = 0;
reg [7:0]  sr_p4 = 0;
reg [7:0]  sr_p1 = 0;

reg [11:0]  sum_p98 = 0;
reg [11:0]  sum_p65 = 0;
reg [11:0]  sum_p32 = 0;

reg [11:0]  sum_p987 = 0;
reg [11:0]  sum_p654 = 0;
reg [11:0]  sum_p321 = 0;

reg [11:0] sum_p987654 = 0;
reg [11:0] sr_sum_p321 = 0;

reg [11:0] sum_p987654321 = 0;

reg [DATA_WIDTH-1:0] sr_do [PIPELINE-1:0];
reg [PIPELINE-1:0] sr_de = 0;
reg [PIPELINE-1:0] sr_hs = 0;
reg [PIPELINE-1:0] sr_vs = 0;

// p1 p2 p3
// p4 p5 p6
// p7 p8 p9

//Gaus:
//        |1 2 1|   | 0.0625  0.125  0.0625 |
// 1/16 * |2 4 2| = | 0.125   0.25   0.0125 |
//        |1 2 1|   | 0.0625  0.125  0.0625 |
always @(posedge clk) begin
    //pipeline 0
    sum_p98 <= {5'd0, p9[7:0]}       + {4'd0, p8[7:0], 1'd0};
    sum_p65 <= {5'd0, p6[7:0], 1'd0} + {3'd0, p5[7:0], 2'd0};
    sum_p32 <= {5'd0, p3[7:0]}       + {4'd0, p2[7:0], 1'd0};

    sr_p7 <= p7;
    sr_p4 <= p4;
    sr_p1 <= p1;

    sr_do[0] <= p9;
    sr_de[0] <= de;
    sr_hs[0] <= hs;
    sr_vs[0] <= vs;

    //pipeline 1
    sum_p987 <= {sum_p98} + {5'd0, sr_p7};
    sum_p654 <= {sum_p65} + {4'd0, sr_p4, 1'd0};
    sum_p321 <= {sum_p32} + {5'd0, sr_p1};

    sr_do[1] <= sr_do[0];
    sr_de[1] <= sr_de[0];
    sr_hs[1] <= sr_hs[0];
    sr_vs[1] <= sr_vs[0];

    //pipeline 2
    sum_p987654 <= sum_p987 + sum_p654;
    sr_sum_p321 <= sum_p321;

    sr_do[2] <= sr_do[1];
    sr_de[2] <= sr_de[1];
    sr_hs[2] <= sr_hs[1];
    sr_vs[2] <= sr_vs[1];

    //pipeline 3
    sum_p987654321 <= sum_p987654 + sr_sum_p321;

    sr_do[3] <= sr_do[2];
    sr_de[3] <= sr_de[2];
    sr_hs[3] <= sr_hs[2];
    sr_vs[3] <= sr_vs[2];

    //stage out
    do_o <= (bypass) ? sr_do[3] : sum_p987654321[11:4];//
    de_o <= sr_de[3];
    hs_o <= sr_hs[3];
    vs_o <= sr_vs[3];

end


endmodule
