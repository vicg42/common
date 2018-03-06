module filter_edge_det_sobel #(
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
function [10:0] max (
    input [10:0] x1,
    input [10:0] x2
);
    begin
        if (x1 > x2) begin
            max = x1;
        end else begin
            max = x2;
        end
    end
endfunction

function [10:0] min (
    input [10:0] x1,
    input [10:0] x2
);
    begin
        if (x1 < x2) begin
            min = {1'b0,x1[10:1]};
        end else begin
            min = {1'b0,x2[10:1]};
        end
    end
endfunction

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

localparam PIPELINE = 4;

reg [9:0]  sum_p23 = 0;
reg [9:0]  sum_p89 = 0;
reg [9:0]  sum_p47 = 0;
reg [9:0]  sum_p69 = 0;

reg [7:0]  sr_p7 = 0;
reg [7:0]  sr_p3 = 0;
reg [7:0]  sr_p1 = 0;

reg [10:0] sum_p123 = 0;
reg [10:0] sum_p789 = 0;
reg [10:0] sum_p147 = 0;
reg [10:0] sum_p369 = 0;

reg signed [11:0] gx = 0;
reg signed [11:0] gy = 0;

reg [12:0] gm = 0;

reg [10:0] gx_clamp = 0;
reg [10:0] gy_clamp = 0;

reg [PIPELINE-1:0] sr_dv = 0;
reg [PIPELINE-1:0] sr_hs = 0;
reg [PIPELINE-1:0] sr_vs = 0;
reg [WIDTH-1:0]    sr_do [PIPELINE-1:0];


wire [10:0] gx_mod;
wire [10:0] gy_mod;
assign gx_mod = (gx[11]) ? (~gx[10:0] + 1'b1) : gx[10:0];
assign gy_mod = (gy[11]) ? (~gy[10:0] + 1'b1) : gy[10:0];

// p1 p2 p3
// p4 p5 p6
// p7 p8 p9

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
    //pipeline 0
    if (dv) begin
        sum_p23[9:0] <= {p2[7:0], 1'd0} + {1'd0, p3[7:0]};
        sum_p89[9:0] <= {p8[7:0], 1'd0} + {1'd0, p9[7:0]};

        sum_p47[9:0] <= {p4[7:0], 1'd0} + {1'd0, p7[7:0]};
        sum_p69[9:0] <= {p6[7:0], 1'd0} + {1'd0, p9[7:0]};

        sr_p1 <= p1;
        sr_p3 <= p3;
        sr_p7 <= p7;

        sr_do[0] <= dou;
    end

    sr_dv[0] <= dv;
    sr_hs[0] <= hs;
    sr_vs[0] <= vs;

    //pipeline 1
    sum_p123[10:0] <= {2'd0, sr_p1} + {sum_p23[9:0]};
    sum_p789[10:0] <= {2'd0, sr_p7} + {sum_p89[9:0]};

    sum_p147[10:0] <= {2'd0, sr_p1} + {sum_p47[9:0]};
    sum_p369[10:0] <= {2'd0, sr_p3} + {sum_p69[9:0]};

    sr_dv[1] <= sr_dv[0];
    sr_hs[1] <= sr_hs[0];
    sr_vs[1] <= sr_vs[0];
    sr_do[1] <= sr_do[0];

    //pipeline 2
//    if (sum_p123 > sum_p789) begin
//        gx[10:0] <= sum_p123 - sum_p789;
//    end else begin
//        gx[10:0] <= sum_p789 - sum_p123;
//    end
//
//    if (sum_p147 > sum_p369) begin
//        gy[10:0] <= sum_p147 - sum_p369;
//    end else begin
//        gy[10:0] <= sum_p369 - sum_p147;
//    end
    gx <= $signed(sum_p123) - $signed(sum_p789);
    gy <= $signed(sum_p147) - $signed(sum_p369);

    sr_dv[2] <= sr_dv[1];
    sr_hs[2] <= sr_hs[1];
    sr_vs[2] <= sr_vs[1];
    sr_do[2] <= sr_do[1];

    //pipeline 3
    gx_clamp[10:0] <= max(gx[10:0], gy[10:0]);
    gy_clamp[10:0] <= min(gx[10:0], gy[10:0]);
//    gm <= gx[10:0] + gy[10:0];
    gm <= max(gx_mod[10:0], gy_mod[10:0]) + min(gx_mod[10:0], gy_mod[10:0]);

    sr_dv[3] <= sr_dv[2];
    sr_hs[3] <= sr_hs[2];
    sr_vs[3] <= sr_vs[2];
    sr_do[3] <= sr_do[2];

    //stagme out
    dout <= (gm > 255) ? 255 : gm[7:0];
    dv_out <= sr_dv[3];
    hs_out <= sr_hs[3];
    vs_out <= sr_vs[3];

end



endmodule
