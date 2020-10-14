//-----------------------------------------------------------------------
// author : Viktor Golovachenko
//-----------------------------------------------------------------------
`timescale 1ns / 1ps
module bilinear_table #(
    parameter STEP = 4096,
    parameter COE_WIDTH = 10
)(
    output reg [COE_WIDTH-1:0] coe0,
    output reg [COE_WIDTH-1:0] coe1,

    input [$clog2(STEP/2)-1:0] dx,
    input clk
);

(* ROM_STYLE="DISTRIBUTED" *) reg [COE_WIDTH-1:0] coe_table_0[(STEP/2)-1:0];
(* ROM_STYLE="DISTRIBUTED" *) reg [COE_WIDTH-1:0] coe_table_1[(STEP/2)-1:0];

initial $readmemb("bilinear_table_0.txt", coe_table_0);
initial $readmemb("bilinear_table_1.txt", coe_table_1);

always @(posedge clk) begin
    coe0 <= coe_table_0[dx];
    coe1 <= coe_table_1[dx];
end

endmodule
