//-----------------------------------------------------------------------
// author : Viktor Golovachenko
//-----------------------------------------------------------------------
`timescale 1ns / 1ps
module linear_table #(
//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
    parameter VENDOR_RAM_STYLE="MLAB",
    parameter STEP = 4096,
    parameter COE_WIDTH = 10
)(
    output reg [COE_WIDTH-1:0] coe0,
    output reg [COE_WIDTH-1:0] coe1,

    input dx_en,
    input [$clog2(STEP/2)-1:0] dx,
    input clk
);

(* ROM_STYLE=VENDOR_RAM_STYLE *) reg [COE_WIDTH-1:0] coe_table_0[(STEP/2)-1:0];
(* ROM_STYLE=VENDOR_RAM_STYLE *) reg [COE_WIDTH-1:0] coe_table_1[(STEP/2)-1:0];

initial $readmemb("linear_table_0.txt", coe_table_0);
initial $readmemb("linear_table_1.txt", coe_table_1);

always @(posedge clk) begin
    if (dx_en) begin
        coe0 <= coe_table_0[dx];
    end
end

always @(posedge clk) begin
    if (dx_en) begin
        coe1 <= coe_table_1[dx];
    end
end

endmodule
