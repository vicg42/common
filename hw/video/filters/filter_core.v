module filter_core #(
    parameter WIDTH = 12,
    parameter SPARSE_OUTPUT = 2
)(
    input rst,
    input clk,

    input [15:0] pix_count,
    input [15:0] line_count,
    input bypass,

    input [WIDTH-1:0] d_in,
    input dv_in,
    input hs_in,
    input vs_in,

    output reg [WIDTH-1:0] d_out,
    output reg [WIDTH-1:0] x1 = 0,
    output reg [WIDTH-1:0] x2 = 0,
    output reg [WIDTH-1:0] x3 = 0,
    output reg [WIDTH-1:0] x4 = 0,
    output reg [WIDTH-1:0] x5 = 0,
    output reg [WIDTH-1:0] x6 = 0,
    output reg [WIDTH-1:0] x7 = 0,
    output reg [WIDTH-1:0] x8 = 0,
    output reg [WIDTH-1:0] x9 = 0,

    output reg dv_out = 0,
    output reg hs_out = 0,
    output reg vs_out = 0
);

// -------------------------------------------------------------------------
// pixel buffer, making following pixel pattern:
// -------------------------------------------------------------------------
// x1 x2 x3
// x4 x5 x6
// x7 x8 x9

integer i;
localparam LINE_SIZE_MAX = 1024;

(* RAM_STYLE="BLOCK" *) reg [WIDTH-1:0] line_bufa [LINE_SIZE_MAX-1:0];
(* RAM_STYLE="BLOCK" *) reg [WIDTH-1:0] line_bufb [LINE_SIZE_MAX-1:0];
reg [WIDTH-1:0] line_bufa_out = 0;
reg [WIDTH-1:0] line_bufb_out = 0;

reg [9:0] line_buf_wptr = 0;

reg [WIDTH-1:0] sr_d_in [0:2];

reg [WIDTH-1:0] sr_line_bufa_out = 0;

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < LINE_SIZE_MAX-1; i = i + 1) begin
            line_bufa[i] <= 0;
            line_bufb[i] <= 0;
        end

        for (i = 0; i < 3; i = i + 1) begin
            sr_d_in[i] <= 0;
        end

    end begin
        if (vs_in) begin
            line_buf_wptr <= 0;
        end

        if (dv_in) begin

            line_buf_wptr <= line_buf_wptr + 1'b1;

            line_bufa[line_buf_wptr] <= sr_d_in[0];
            line_bufb[line_buf_wptr] <= line_bufa_out;
            line_bufa_out <= line_bufa[line_buf_wptr];
            line_bufb_out <= line_bufb[line_buf_wptr];

            sr_d_in[0] <= d_in;
            sr_d_in[1] <= sr_d_in[0];
            sr_d_in[2] <= sr_d_in[1];

            x9 <= sr_d_in[2];
            x8 <= x9;
            x7 <= x8;

            sr_line_bufa_out <= line_bufa_out;
            x6 <= sr_line_bufa_out;
            x5 <= x6;
            x4 <= x5;

            x3 <= line_bufb_out;
            x2 <= x3;
            x1 <= x2;

            if (hs_in) begin
                line_buf_wptr <= 0;
            end
        end
    end
end

localparam PIPELINE_VIDOE_SYNC = 4;
reg [PIPELINE_VIDOE_SYNC-1:0] sr_hs = 0;

localparam BYPASS_DELAY = 4;
reg [WIDTH-1:0] bypass_delay [BYPASS_DELAY:2];

reg vs_in_d = 0;
reg vs_in_dd = 0;

always @(posedge clk) begin
    if (rst) begin
        for (i = 2; i < BYPASS_DELAY; i = i + 1) begin
            bypass_delay[i] <= 0;
        end

    end begin
        if (!bypass) begin
            if (dv_in) begin
                bypass_delay[2] <= line_bufa_out;
                for (i = 2; i < BYPASS_DELAY; i = i + 1) begin
                    bypass_delay[i + 1] <= bypass_delay[i];
                end

                {hs_out, sr_hs} <= {sr_hs, hs_in};

                d_out <= bypass_delay[BYPASS_DELAY - 1];

                // vs_out 1 line delay
                if (hs_in) begin
                    vs_in_d <= vs_in;
                    vs_in_dd <= vs_in_d;
                end
                vs_out <= vs_in_dd & sr_hs[PIPELINE_VIDOE_SYNC-1];
            end
        end else begin
            d_out  <= d_in;
            hs_out <= hs_in;
            hs_out <= hs_in;
            vs_out <= vs_in;
        end
        dv_out <= dv_in;
    end
end

endmodule
