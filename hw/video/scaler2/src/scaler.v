
module scaler #(
    parameter LINE_SIZE_MAX = 4096,
    parameter STEP_CORD_I = 4096,
    parameter POINT_COUNT = 4,
    parameter COE_ROM_DEPTH = 32,
    parameter COE_WIDTH = 10,
    parameter DATA_WIDTH = 8
)(
//    // control interface
//    input           reg_clk,
//    input [7:0]     reg_wr_addr,
//    input [23:0]    reg_wr_data,
//    input           reg_wr_en,

    input [15:0] step_cord_o,

    // Video input
    input [DATA_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    // Video output
    output [DATA_WIDTH-1:0] do_o,
    output de_o,
    output hs_o,
    output vs_o,

    input clk,
    input rst
);
//// -------------------------------------------------------------------------
//reg [15:0] reg_horisontal_scale_step = 4096*1.0;
//reg [15:0] reg_vertical_scale_step = 4096*0.5;
//reg [15:0] reg_vertical_scale_line_size = 800;
//reg [15:0] horisontal_scale_step;
//reg [15:0] vertical_scale_step;
//reg [15:0] vertical_scale_line_size = 800;
//always @(posedge reg_clk) begin
//    if (reg_wr_en && (reg_wr_addr == `FPGA_REG_HORISONTAL_SCALE)) reg_horisontal_scale_step <= reg_wr_data;
//    if (reg_wr_en && (reg_wr_addr == `FPGA_REG_VERTICAL_SCALE)) reg_vertical_scale_step <= reg_wr_data;
//    if (reg_wr_en && (reg_wr_addr == `FPGA_REG_SCALER_LINE_SIZE)) reg_vertical_scale_line_size <= reg_wr_data;
//end
//
//
//always @(posedge clk) begin
//    if (dv_in & vs_in) begin
//        horisontal_scale_step <= reg_horisontal_scale_step;
//        vertical_scale_step <= reg_vertical_scale_step;
//        vertical_scale_line_size <= reg_vertical_scale_line_size;
//    end
//end


wire [DATA_WIDTH-1:0] scaler_h_do_o;
wire scaler_h_de_o;
wire scaler_h_hs_o;
wire scaler_h_vs_o;

wire [15:0] scaler_h_pix_count_o;

wire [($clog2(COE_ROM_DEPTH))-1:0] scaler_h_coe_adr;
wire [(POINT_COUNT*COE_WIDTH)-1:0] scaler_h_coe_dat;

wire [($clog2(COE_ROM_DEPTH))-1:0] scaler_v_coe_adr;
wire [(POINT_COUNT*COE_WIDTH)-1:0] scaler_v_coe_dat;

scaler_rom_coe #(
    .POINT_COUNT(POINT_COUNT),
    .COE_ROM_DEPTH(COE_ROM_DEPTH),
    .COE_WIDTH(COE_WIDTH)
) scaler_rom_coe (
    .portA_adr(scaler_h_coe_adr),
    .portA_do (scaler_h_coe_dat),

    .portB_adr(scaler_v_coe_adr),
    .portB_do (scaler_v_coe_dat),

    .clk (clk)
);

scaler_h #(
    .STEP_CORD_I(STEP_CORD_I),
    .POINT_COUNT(POINT_COUNT),
    .COE_ROM_DEPTH(COE_ROM_DEPTH),
    .COE_WIDTH(COE_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) scaler_h(
    .step_cord_o(step_cord_o),
    .coe_adr(scaler_h_coe_adr),
    .coe_dat(scaler_h_coe_dat),

    .di_i(di_i),
    .de_i(de_i),
    .hs_i(hs_i),
    .vs_i(vs_i),

    .do_o(scaler_h_do_o),
    .de_o(scaler_h_de_o),
    .hs_o(scaler_h_hs_o),
    .vs_o(scaler_h_vs_o),

    .pix_count_o(scaler_h_pix_count_o),

    .clk (clk),
    .rst (rst)
);

scaler_v #(
    .SPARSE_OUTPUT(0), // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
    .LINE_SIZE_MAX(LINE_SIZE_MAX),
    .STEP_CORD_I(STEP_CORD_I),
    .POINT_COUNT(POINT_COUNT),
    .COE_ROM_DEPTH(COE_ROM_DEPTH),
    .COE_WIDTH(COE_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) scaler_v(
    .step_cord_o(step_cord_o),
    .scale_line_size(scaler_h_pix_count_o),

    .coe_adr(scaler_v_coe_adr),
    .coe_dat(scaler_v_coe_dat),

    .di_i(scaler_h_do_o),
    .de_i(scaler_h_de_o),
    .hs_i(scaler_h_hs_o),
    .vs_i(scaler_h_vs_o),

    .do_o(do_o),
    .de_o(de_o),
    .hs_o(hs_o),
    .vs_o(vs_o),

    .clk (clk),
    .rst (rst)
);

endmodule
