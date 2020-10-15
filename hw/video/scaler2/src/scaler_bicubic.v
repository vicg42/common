//-----------------------------------------------------------------------
// author : Viktor Golovachenko
//-----------------------------------------------------------------------
module scaler #(
    parameter LINE_IN_SIZE_MAX = 1024,
    parameter SCALE_STEP = 4096,
    parameter PIXEL_WIDTH = 12,
    parameter SPARSE_OUT = 2, // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
    parameter COE_WIDTH = 10
)(
    input [15:0] reg_h_scale_step,
    input [15:0] reg_v_scale_step,
    input [15:0] reg_v_scale_inline_size,

    input [PIXEL_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    output [PIXEL_WIDTH-1:0] do_o,
    output de_o,
    output hs_o,
    output vs_o,

    input clk
);

reg sr_hs_i = 0;
reg sr_vs_i = 0;
reg hs_s = 1'b0;
reg vs_s = 1'b0;
reg de_s = 1'b0;
reg [PIXEL_WIDTH-1:0] di_s = 0;
always @(posedge clk) begin
    sr_hs_i <= hs_i;
    sr_vs_i <= vs_i;
    hs_s <= sr_hs_i & !hs_i;
    vs_s <= !sr_vs_i & vs_i;
    de_s <= de_i;
    di_s <= di_i;
end

reg [15:0] h_scale_step = 0;
reg [15:0] v_scale_step = 0;
reg [15:0] inline_size = 0;
always @(posedge clk) begin
    if (vs_s) begin
        h_scale_step <= reg_h_scale_step;
        v_scale_step <= reg_v_scale_step;
        inline_size  <= reg_v_scale_inline_size;
    end
end

wire [PIXEL_WIDTH-1: 0] scaler_h_do_o;
wire scaler_h_de_o;
wire scaler_h_hs_o;
wire scaler_h_vs_o;
scaler_h #(
    .PIXEL_STEP(SCALE_STEP),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .COE_WIDTH(COE_WIDTH)
) scaler_cubic_h_m (
    .scale_step(h_scale_step),

    .di_i(di_s),//(di_i),//
    .de_i(de_s),//(de_i),//
    .hs_i(hs_s),//(hs_i),//
    .vs_i(vs_s),//(vs_i),//

    .do_o(scaler_h_do_o),
    .de_o(scaler_h_de_o),
    .hs_o(scaler_h_hs_o),
    .vs_o(scaler_h_vs_o),

    .clk(clk)
);

scaler_v #(
    .LINE_IN_SIZE_MAX(LINE_IN_SIZE_MAX),
    .LINE_STEP(SCALE_STEP),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .SPARSE_OUT(SPARSE_OUT),
    .COE_WIDTH(COE_WIDTH)
) scaler_cubic_v_m (
    .line_in_size(inline_size),
    .scale_step(v_scale_step),

    .di_i(scaler_h_do_o),
    .de_i(scaler_h_de_o),
    .hs_i(scaler_h_hs_o),
    .vs_i(scaler_h_vs_o),

    .do_o(do_o),
    .de_o(de_o),
    .hs_o(hs_o),
    .vs_o(vs_o),

    .clk(clk)
);

reg [15:0] dbg_cntx_o = 0;
always @(posedge clk) begin
    if (scaler_h_de_o) begin
        dbg_cntx_o <= dbg_cntx_o + 1;
    end
end

endmodule
