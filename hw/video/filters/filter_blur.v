module filter_blur #(
    parameter WIDTH = 8,
    parameter SPARSE_OUTPUT = 2
)(
    input clk,
    input rst,

    input [15:0] pix_count,
    input [15:0] line_count,
    input bypass,

    input [WIDTH-1:0] d_in,
    input dv_in,
    input hs_in,
    input vs_in,

    output reg [WIDTH-1:0] dout = 0,
    output reg dv_out = 0,
    output reg hs_out = 0,
    output reg vs_out = 0
);
// -------------------------------------------------------------------------
wire dv;
wire hs;
wire vs;

wire [WIDTH-1:0] p1;
wire [WIDTH-1:0] p2;
wire [WIDTH-1:0] p3;
wire [WIDTH-1:0] p4;
wire [WIDTH-1:0] p5;
wire [WIDTH-1:0] p6;
wire [WIDTH-1:0] p7;
wire [WIDTH-1:0] p8;
wire [WIDTH-1:0] p9;

wire [WIDTH-1:0] dou;

filter_core #(
//    .SPARSE_OUTPUT (SPARSE_OUTPUT),
    .WIDTH (WIDTH)
) filter_core (
    .rst (rst),
    .clk (clk),

//    .pix_count (pix_count ),
//    .line_count(line_count),
    .bypass    (bypass),

    .d_in (d_in ),
    .dv_in(dv_in),
    .hs_in(hs_in),
    .vs_in(vs_in),

    .x1 (p1),
    .x2 (p2),
    .x3 (p3),
    .x4 (p4),
    .x5 (p5),
    .x6 (p6),
    .x7 (p7),
    .x8 (p8),
    .x9 (p9),

    .d_out(dou),
    .dv_out(dv),
    .hs_out(hs),
    .vs_out(vs)
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

reg [PIPELINE-1:0] sr_dv = 0;
reg [PIPELINE-1:0] sr_hs = 0;
reg [PIPELINE-1:0] sr_vs = 0;
reg [WIDTH-1:0]    sr_do [PIPELINE-1:0];

// p1 p2 p3
// p4 p5 p6
// p7 p8 p9

//Gaus:
//        |1 2 1|   | 0.0625  0.125  0.0625 |
// 1/16 * |2 4 2| = | 0.125   0.25   0.0125 |
//        |1 2 1|   | 0.0625  0.125  0.0625 |
always @(posedge clk) begin
    //pipeline 0
    if (dv) begin
        sum_p98 <= {5'd0, p9[7:0]}       + {4'd0, p8[7:0], 1'd0};
        sum_p65 <= {5'd0, p6[7:0], 1'd0} + {3'd0, p5[7:0], 2'd0};
        sum_p32 <= {5'd0, p3[7:0]}       + {4'd0, p2[7:0], 1'd0};

        sr_p7 <= p7;
        sr_p4 <= p4;
        sr_p1 <= p1;

        sr_do[0] <= dou;
    end

    sr_dv[0] <= dv;
    sr_hs[0] <= hs;
    sr_vs[0] <= vs;

    //pipeline 1
    sum_p987 <= {sum_p98} + {5'd0, sr_p7};
    sum_p654 <= {sum_p65} + {4'd0, sr_p4, 1'd0};
    sum_p321 <= {sum_p32} + {5'd0, sr_p1};

    sr_dv[1] <= sr_dv[0];
    sr_hs[1] <= sr_hs[0];
    sr_vs[1] <= sr_vs[0];
    sr_do[1] <= sr_do[0];

    //pipeline 2
    sum_p987654 <= sum_p987 + sum_p654;
    sr_sum_p321 <= sum_p321;

    sr_dv[2] <= sr_dv[1];
    sr_hs[2] <= sr_hs[1];
    sr_vs[2] <= sr_vs[1];
    sr_do[2] <= sr_do[1];

    //pipeline 3
    sum_p987654321 <= sum_p987654 + sr_sum_p321;

    sr_dv[3] <= sr_dv[2];
    sr_hs[3] <= sr_hs[2];
    sr_vs[3] <= sr_vs[2];
    sr_do[3] <= sr_do[2];

    //stage out
    dout <= bypass ? sr_do[3] : sum_p987654321[11:4];
    dv_out <= sr_dv[3];
    hs_out <= sr_hs[3];
    vs_out <= sr_vs[3];

end


endmodule
