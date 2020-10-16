//-----------------------------------------------------------------------
// author : Viktor Golovachenko
//-----------------------------------------------------------------------
`timescale 1ns / 1ps
module lanczos_table #(
//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
    parameter VENDOR_RAM_STYLE="MLAB",
    parameter STEP = 4096,
    parameter COE_WIDTH = 10
)(
    output reg [COE_WIDTH-1:0] coe0,
    output reg [COE_WIDTH-1:0] coe1,
    output reg [COE_WIDTH-1:0] coe2,
    output reg [COE_WIDTH-1:0] coe3,
    output reg [COE_WIDTH-1:0] coe4,
    output reg [COE_WIDTH-1:0] coe5,

    input [$clog2(STEP/4)-1:0] dx,
    input clk
);

(* ROM_STYLE=VENDOR_RAM_STYLE *) reg [COE_WIDTH-1:0] coe_table_0[(STEP/4)-1:0];
(* ROM_STYLE=VENDOR_RAM_STYLE *) reg [COE_WIDTH-1:0] coe_table_1[(STEP/4)-1:0];
(* ROM_STYLE=VENDOR_RAM_STYLE *) reg [COE_WIDTH-1:0] coe_table_2[(STEP/4)-1:0];
(* ROM_STYLE=VENDOR_RAM_STYLE *) reg [COE_WIDTH-1:0] coe_table_3[(STEP/4)-1:0];
(* ROM_STYLE=VENDOR_RAM_STYLE *) reg [COE_WIDTH-1:0] coe_table_4[(STEP/4)-1:0];
(* ROM_STYLE=VENDOR_RAM_STYLE *) reg [COE_WIDTH-1:0] coe_table_5[(STEP/4)-1:0];

initial $readmemb("lanczos_table_0.txt", coe_table_0);
initial $readmemb("lanczos_table_1.txt", coe_table_1);
initial $readmemb("lanczos_table_2.txt", coe_table_2);
initial $readmemb("lanczos_table_3.txt", coe_table_3);
initial $readmemb("lanczos_table_4.txt", coe_table_4);
initial $readmemb("lanczos_table_5.txt", coe_table_5);

always @(posedge clk) begin
    coe0 <= coe_table_0[dx];
    coe1 <= coe_table_1[dx];
    coe2 <= coe_table_2[dx];
    coe3 <= coe_table_3[dx];
    coe4 <= coe_table_4[dx];
    coe5 <= coe_table_5[dx];
end

endmodule
