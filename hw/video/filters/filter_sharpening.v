module filter_sharpening #(
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

localparam PIPELINE = 3;

reg [15:0] sum_p56 = 0;
reg [8:0]  sum_p28 = 0;

reg [7:0]  sr_p4 = 0;

reg [15:0] sum_p456 = 0;
reg [8:0]  sr_sum_p28 = 0;

reg [15:0]  sum_p45628 = 0;

reg [PIPELINE-1:0] sr_dv = 0;
reg [PIPELINE-1:0] sr_hs = 0;
reg [PIPELINE-1:0] sr_vs = 0;
reg [WIDTH-1:0]    sr_do [PIPELINE-1:0];


// p1 p2 p3
// p4 p5 p6
// p7 p8 p9

//sharpening operator
//  0   -1   0
//  -1   5  -1
//  0   -1   0

wire [15:0] mp5;
assign mp5[15:0] = p5[7:0] * 8'd5;

always @(posedge clk) begin
    //pipeline 0
    if (dv) begin
        sum_p56[15:0] <= mp5[15:0] - {8'b0, p6[7:0]};
        sum_p28[8:0] <= {1'b0, p2[7:0]} + {1'b0, p8[7:0]};

        sr_p4 <= p4;

        sr_do[0] <= dou;
    end

    sr_dv[0] <= dv;
    sr_hs[0] <= hs;
    sr_vs[0] <= vs;

    //pipeline 1
    sum_p456[15:0] <= sum_p56[15:0] - {8'b0, sr_p4[7:0]};
    sr_sum_p28 <= sum_p28[8:0];

    sr_dv[1] <= sr_dv[0];
    sr_hs[1] <= sr_hs[0];
    sr_vs[1] <= sr_vs[0];
    sr_do[1] <= sr_do[0];

    //pipeline 2
    sum_p45628 <= sum_p456[15:0] - {7'b0, sr_sum_p28};

    sr_dv[2] <= sr_dv[1];
    sr_hs[2] <= sr_hs[1];
    sr_vs[2] <= sr_vs[1];
    sr_do[2] <= sr_do[1];

    //stage out (clamping)
    if (sum_p45628[15]) begin //result < 0
        dout <= {8{1'b0}};
    end else if (sum_p45628[8]) begin //overflow
        dout = {8{1'b1}};
    end else begin
        dout <= sum_p45628[7:0];
    end
    dv_out <= sr_dv[2];
    hs_out <= sr_hs[2];
    vs_out <= sr_vs[2];

end

//localparam PIPELINE = 4;
//
//reg [9:0] sum_p46 = 0;
//reg [9:0] sum_p28 = 0;
//
//reg [8:0] sum_p39 = 0;
//reg [8:0] sum_p17 = 0;
//
//
//reg [9:0]  sum_p1739 = 0;
//reg [10:0]  sum_p2846 = 0;
//
//reg [15:0] sum_p456 = 0;
//reg [8:0]  sr_sum_p28 = 0;
//
//reg [15:0]  sum_p45628 = 0;
//
//reg [15:0] mp5 = 0;
//reg [15:0] sr_mp5 = 0;
//
//reg [15:0] sum_p17395 = 0;
//reg [10:0] sr_sum_p2846 = 0;
//
//reg [15:0] sum_p173952846 = 0;
//
//reg [PIPELINE-1:0] sr_dv = 0;
//reg [PIPELINE-1:0] sr_hs = 0;
//reg [PIPELINE-1:0] sr_vs = 0;
//reg [WIDTH-1:0]    sr_do [PIPELINE-1:0];
//
//
//// p1 p2 p3
//// p4 p5 p6
//// p7 p8 p9
//
////sharpening operator
////  1   -2   1
////  -2   5  -2
////  1   -2   1
//always @(posedge clk) begin
//    //pipeline 0
//    if (dv) begin
//        mp5[15:0] = p5[7:0] * 8'd5;
//
//        sum_p46[9:0] <= {1'b0, p4[7:0], 1'b0} + {1'b0, p6[7:0], 1'b0};
//        sum_p28[9:0] <= {1'b0, p2[7:0], 1'b0} + {1'b0, p8[7:0], 1'b0};
//
//        sum_p39[8:0] <= {1'b0, p3[7:0]} + {1'b0, p9[7:0]};
//        sum_p17[8:0] <= {1'b0, p1[7:0]} + {1'b0, p7[7:0]};
//
//        sr_do[0] <= dou;
//    end
//
//    sr_dv[0] <= dv;
//    sr_hs[0] <= hs;
//    sr_vs[0] <= vs;
//
//    //pipeline 1
//    sum_p2846[10:0] <= {1'b0, sum_p28[9:0]} + {1'b0, sum_p46[9:0]};
//    sum_p1739[9:0]  <= {1'b0, sum_p17[8:0]} + {1'b0, sum_p39[8:0]};
//    sr_mp5 <= mp5;
//
//    sr_dv[1] <= sr_dv[0];
//    sr_hs[1] <= sr_hs[0];
//    sr_vs[1] <= sr_vs[0];
//    sr_do[1] <= sr_do[0];
//
//    //pipeline 2
//    sr_sum_p2846 <= sum_p2846;
//    sum_p17395 <= mp5[15:0] + {6'b0, sum_p1739[9:0]};
//
//    sr_dv[2] <= sr_dv[1];
//    sr_hs[2] <= sr_hs[1];
//    sr_vs[2] <= sr_vs[1];
//    sr_do[2] <= sr_do[1];
//
//    //pipeline 3
//    sum_p173952846 <= sum_p17395 - {5'b0, sr_sum_p2846[10:0]};
//
//    sr_dv[3] <= sr_dv[2];
//    sr_hs[3] <= sr_hs[2];
//    sr_vs[3] <= sr_vs[2];
//    sr_do[3] <= sr_do[2];
//
//    //stage out (clamping)
//    if (sum_p173952846[15]) begin //result < 0
//        dout <= {8{1'b0}};
//    end else if (sum_p173952846[8]) begin //overflow
//        dout = {8{1'b1}};
//    end else begin
//        dout <= sum_p173952846[7:0];
//    end
//
//    dv_out <= sr_dv[3];
//    hs_out <= sr_hs[3];
//    vs_out <= sr_vs[3];
//
//end


endmodule
