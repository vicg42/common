module filter_edge_det_sobel #(
    parameter DE_I_PERIOD = 0,
    parameter LINE_SIZE_MAX = 1024,
    parameter DATA_WIDTH = 8
)(
    input bypass,
    input gate,
    input [15:0] threshold_h,
    input [15:0] threshold_l,

    //input resolution X * Y
    input [DATA_WIDTH-1:0] di_i,
    input                  de_i,
    input                  hs_i,
    input                  vs_i,

    //output resolution (X - 2) * (Y - 2)
    output reg [DATA_WIDTH-1:0] do_o = 0,
    output reg                  de_o = 1'b0,
    output reg                  hs_o = 1'b0,
    output reg                  vs_o = 1'b0,

    input clk,
    input rst
);

// -------------------------------------------------------------------------
wire [DATA_WIDTH-1:0] p1;
wire [DATA_WIDTH-1:0] p2;
wire [DATA_WIDTH-1:0] p3;
wire [DATA_WIDTH-1:0] p4;
wire [DATA_WIDTH-1:0] p5;
wire [DATA_WIDTH-1:0] p6;
wire [DATA_WIDTH-1:0] p7;
wire [DATA_WIDTH-1:0] p8;
wire [DATA_WIDTH-1:0] p9;

wire de;
wire hs;
wire vs;
reg [0:4] sr_de = 0;
reg [0:4] sr_hs = 0;
reg [0:4] sr_vs = 0;
reg [DATA_WIDTH-1:0] sr_do [0:4];
reg [DATA_WIDTH-1:0] sr_p5 [0:4];


filter_core_3x3 #(
    .DE_I_PERIOD (DE_I_PERIOD),
    .LINE_SIZE_MAX (LINE_SIZE_MAX),
    .DATA_WIDTH (DATA_WIDTH)
) filter_core (
    .bypass(bypass),

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
    .x9 (p9), //can be use like bypass

    .de_o(de),
    .hs_o(hs),
    .vs_o(vs),

    .clk (clk),
    .rst (rst)
);

reg [DATA_WIDTH:0]   sum_p13 = 0;
reg [DATA_WIDTH:0]   sum_p79 = 0;
reg [DATA_WIDTH:0]   sum_p17 = 0;
reg [DATA_WIDTH:0]   sum_p39 = 0;

reg [DATA_WIDTH:0]   sr_p2 = 0;
reg [DATA_WIDTH:0]   sr_p8 = 0;
reg [DATA_WIDTH:0]   sr_p4 = 0;
reg [DATA_WIDTH:0]   sr_p6 = 0;

reg [DATA_WIDTH+1:0] sum_p123 = 0;
reg [DATA_WIDTH+1:0] sum_p789 = 0;
reg [DATA_WIDTH+1:0] sum_p147 = 0;
reg [DATA_WIDTH+1:0] sum_p369 = 0;

reg [DATA_WIDTH-1:0] sum_p123_round = 0;
reg [DATA_WIDTH-1:0] sum_p789_round = 0;
reg [DATA_WIDTH-1:0] sum_p147_round = 0;
reg [DATA_WIDTH-1:0] sum_p369_round = 0;

reg [DATA_WIDTH-1:0] gx = 0;
reg [DATA_WIDTH-1:0] gy = 0;

reg [DATA_WIDTH:0] gm = 0;

// line[0]: x1 x2 x3
// line[1]: x4 x5 x6
// line[2]: x7 x8 x9

//Gx:
//  1  2  1
//  0  0  0
// -1 -2 -1

//Gy:
// 1  0 -1
// 2  0 -2
// 1  0 -1

//G = |Gx| + |Gy|
always @(posedge clk) begin
    //----------------------------
    //pipeline 0
    //----------------------------
    sum_p13 <= {1'd0, p1} + {1'd0, p3}; //P1 + P3
    sum_p79 <= {1'd0, p7} + {1'd0, p9}; //P7 + P9

    sum_p17 <= {1'd0, p1} + {1'd0, p7}; //P1 + P7
    sum_p39 <= {1'd0, p3} + {1'd0, p9}; //P3 + P9

    sr_p2 <= {p2, 1'd0};//P2*2
    sr_p8 <= {p8, 1'd0};//P8*2
    sr_p4 <= {p4, 1'd0};//P4*2
    sr_p6 <= {p6, 1'd0};//P6*2

    sr_de[0] <= de;
    sr_hs[0] <= hs;
    sr_vs[0] <= vs;
    sr_do[0] <= p9;//bypass
    sr_p5[0] <= p5;//aux

    //----------------------------
    //pipeline 1
    //----------------------------
    sum_p123 <= {1'd0, sum_p13} + {1'd0, sr_p2}; //P1 + P2*2 + P3
    sum_p789 <= {1'd0, sum_p79} + {1'd0, sr_p8}; //P7 + P8*2 + P9

    sum_p147 <= {1'd0, sum_p17} + {1'd0, sr_p4}; //P1 + P4*2 + P7
    sum_p369 <= {1'd0, sum_p39} + {1'd0, sr_p6}; //P3 + P6*2 + P9

    sr_de[1] <= sr_de[0];
    sr_hs[1] <= sr_hs[0];
    sr_vs[1] <= sr_vs[0];
    sr_do[1] <= sr_do[0];
    sr_p5[1] <= sr_p5[0];

    //----------------------------
    //pipeline 2
    //----------------------------
    sum_p123_round <= sum_p123[DATA_WIDTH+1:2]; //div4
    sum_p789_round <= sum_p789[DATA_WIDTH+1:2]; //div4

    sum_p147_round <= sum_p147[DATA_WIDTH+1:2]; //div4
    sum_p369_round <= sum_p369[DATA_WIDTH+1:2]; //div4

    sr_de[2] <= sr_de[1];
    sr_hs[2] <= sr_hs[1];
    sr_vs[2] <= sr_vs[1];
    sr_do[2] <= sr_do[1];
    sr_p5[2] <= sr_p5[1];

    //----------------------------
    //pipeline 3 (|Gx|, |Gy|)
    //----------------------------
    gx <= (sum_p123_round > sum_p789_round) ? (sum_p123_round - sum_p789_round) : (sum_p789_round - sum_p123_round);
    gy <= (sum_p147_round > sum_p369_round) ? (sum_p147_round - sum_p369_round) : (sum_p369_round - sum_p147_round);

    sr_de[3] <= sr_de[2];
    sr_hs[3] <= sr_hs[2];
    sr_vs[3] <= sr_vs[2];
    sr_do[3] <= sr_do[2];
    sr_p5[3] <= sr_p5[2];

    //----------------------------
    //pipeline 4 (G = |Gx| + |Gy|)
    //----------------------------
    gm <= {1'b0, gx} + {1'b0, gy};

    sr_de[4] <= sr_de[3];
    sr_hs[4] <= sr_hs[3];
    sr_vs[4] <= sr_vs[3];
    sr_do[4] <= sr_do[3];
    sr_p5[4] <= sr_p5[3];

    //----------------------------
    //pipeline 5 (bypass/gate)
    //----------------------------
    if (bypass) begin
        do_o <= sr_do[4];
    end else if (gate) begin
        do_o <= ((gm[DATA_WIDTH:1] >= threshold_l[DATA_WIDTH-1:0]) && (gm[DATA_WIDTH:1] <= threshold_h[DATA_WIDTH-1:0])) ? gm[DATA_WIDTH:1] : 0;
    end else begin
        do_o <= gm[DATA_WIDTH:1];
    end

    de_o <= sr_de[4];
    hs_o <= sr_hs[4];
    vs_o <= sr_vs[4];
end

endmodule
