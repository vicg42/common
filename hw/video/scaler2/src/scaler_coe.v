`timescale 1ns / 1ps

module scaler_coe(
    input [9:0] idx,

    output reg [9:0] f0,
    output reg [9:0] f1,
    output reg [9:0] f2,
    output reg [9:0] f3,

    input clk
);

(* ROM_STYLE="DISTRIBUTED" *) reg [9:0] scaler_coe_0[1023:0];
(* ROM_STYLE="DISTRIBUTED" *) reg [9:0] scaler_coe_1[1023:0];
(* ROM_STYLE="DISTRIBUTED" *) reg [9:0] scaler_coe_2[1023:0];
(* ROM_STYLE="DISTRIBUTED" *) reg [9:0] scaler_coe_3[1023:0];

initial $readmemb("../src/cubic_table_0.txt", scaler_coe_0);
initial $readmemb("../src/cubic_table_1.txt", scaler_coe_1);
initial $readmemb("../src/cubic_table_2.txt", scaler_coe_2);
initial $readmemb("../src/cubic_table_3.txt", scaler_coe_3);

always @(posedge clk) begin
    f0 <= scaler_coe_0[idx];
    f1 <= scaler_coe_1[idx];
    f2 <= scaler_coe_2[idx];
    f3 <= scaler_coe_3[idx];
end

endmodule
