`include "../fpga_regs.v"

module scaler #(
    parameter WIDTH = 12,
    parameter SPARSE_OUTPUT = 1, // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
    parameter TABLE_INPUT_WIDTH = 10
)(
    // control interface
    input           reg_clk,
    input [7:0]     reg_wr_addr,
    input [23:0]    reg_wr_data,
    input           reg_wr_en,

    // Video clock
    input clk,

    // Video input
    input [WIDTH-1:0] d_in,
    input dv_in,
    input hs_in,
    input vs_in,
    
    // Video output
    output [WIDTH-1:0] d_out,
    output dv_out,
    output hs_out,
    output vs_out
);
// -------------------------------------------------------------------------
reg [15:0] reg_horisontal_scale_step = 4096*1.0;
reg [15:0] reg_vertical_scale_step = 4096*0.5;
reg [15:0] reg_vertical_scale_line_size = 800;
reg [15:0] horisontal_scale_step;
reg [15:0] vertical_scale_step;
reg [15:0] vertical_scale_line_size = 800;
always @(posedge reg_clk) begin
    if (reg_wr_en && (reg_wr_addr == `FPGA_REG_HORISONTAL_SCALE)) reg_horisontal_scale_step <= reg_wr_data;
    if (reg_wr_en && (reg_wr_addr == `FPGA_REG_VERTICAL_SCALE)) reg_vertical_scale_step <= reg_wr_data;
    if (reg_wr_en && (reg_wr_addr == `FPGA_REG_SCALER_LINE_SIZE)) reg_vertical_scale_line_size <= reg_wr_data;
end


always @(posedge clk) begin
    if (dv_in & vs_in) begin
        horisontal_scale_step <= reg_horisontal_scale_step;
        vertical_scale_step <= reg_vertical_scale_step;
        vertical_scale_line_size <= reg_vertical_scale_line_size;
    end
end


wire [WIDTH-1:0] hs_d_out;
wire hs_dv_out;
wire hs_hs_out;
wire hs_vs_out;

scaler_horisontal #(
    .WIDTH(WIDTH),
    .TABLE_INPUT_WIDTH(TABLE_INPUT_WIDTH)
) scaler_horisontal(
    .clk                     (clk),

    .horisontal_scale_step   (horisontal_scale_step),

    .d_in                    (d_in),
    .dv_in                   (dv_in),
    .hs_in                   (hs_in),
    .vs_in                   (vs_in),
    
    .d_out                   (hs_d_out),
    .dv_out                  (hs_dv_out),
    .hs_out                  (hs_hs_out),
    .vs_out                  (hs_vs_out)
);

scaler_vertical #(
    .WIDTH(WIDTH),
    .SPARSE_OUTPUT(SPARSE_OUTPUT),
    .TABLE_INPUT_WIDTH(TABLE_INPUT_WIDTH)
) scaler_vertical(
    .clk                   (clk),

    .vertical_scale_step   (vertical_scale_step),
    .vertical_scale_line_size (vertical_scale_line_size),

    .d_in                  (hs_d_out),
    .dv_in                 (hs_dv_out),
    .hs_in                 (hs_hs_out),
    .vs_in                 (hs_vs_out),
    
    .d_out                 (d_out),
    .dv_out                (dv_out),
    .hs_out                (hs_out),
    .vs_out                (vs_out)
);

endmodule
