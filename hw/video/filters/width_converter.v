//------------------------------------------------------------------
// author : Victor Golovachenko
//------------------------------------------------------------------
`include "fpga_regs.v"

module width_converter #(
    parameter LINE_SIZE_MAX = 1024,
    parameter CH_NUM = 0,
    parameter DI_WIDTH = 8,
    parameter DO_WIDTH = 8
)(
    // input baypass,

    input [15:0] ram_addr,
    input [15:0] ram_wdata,
    output reg [15:0] ram_rdata = 0,
    input        ram_wr,
    input        ram_clk,

    input [DI_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    output [DO_WIDTH-1:0] do_o,
    output de_o,
    output hs_o,
    output vs_o,

    input clk,
    input rst
);

// -------------------------------------------------------------------------
//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
(* ramstyle = "MLAB" *) reg [15:0] ram [LINE_SIZE_MAX-1:0];

initial $readmemh("width_converter_ram_default.txt", ram);

wire ramA_wr;
wire [9:0] ramA_addr;
assign ramA_wr = (ram_addr[`FPGA_REG_INDIR_CTL_CH_H_BIT:`FPGA_REG_INDIR_CTL_CH_L_BIT] == CH_NUM[1:0]) ? ram_wr : 1'b0;
assign ramA_addr[9:0] = ram_addr[`FPGA_REG_INDIR_CTL_ADR_RAM_H_BIT:`FPGA_REG_INDIR_CTL_ADR_RAM_L_BIT];
always @ (posedge ram_clk) begin
    // Port A
    if (ramA_wr) begin
        ram[ramA_addr] <= ram_wdata;
        ram_rdata <= ram_wdata;
    end else begin
        ram_rdata <= ram[ramA_addr];
    end
end

wire ramB_wr;
reg [15:0] ramB_do;
wire [9:0] ramB_addr;
assign ramB_wr = 1'b0;
assign ramB_addr[9:0] = (DI_WIDTH == 10) ? di_i[9:0] : {2'd0, di_i[7:0]};
always @ (posedge clk) begin
    // Port B
    if (ramB_wr) begin
        ram[ramB_addr] <= 0;
        ramB_do <= 0;
    end else begin
        ramB_do <= ram[ramB_addr];
    end
end

reg de_ = 1'b0;
reg hs_ = 1'b0;
reg vs_ = 1'b0;
always @ (posedge clk) begin
    de_ <= de_i;
    hs_ <= hs_i;
    vs_ <= vs_i;
end

// assign do_o = (!baypass) ? ramB_do[DO_WIDTH-1:0] : di_i[DO_WIDTH-1:0];
// assign de_o = (!baypass) ? de_ : de_i;
// assign hs_o = (!baypass) ? hs_ : hs_i;
// assign vs_o = (!baypass) ? vs_ : vs_i;

assign do_o = ramB_do[DO_WIDTH-1:0];
assign de_o = de_;
assign hs_o = hs_;
assign vs_o = vs_;

endmodule
