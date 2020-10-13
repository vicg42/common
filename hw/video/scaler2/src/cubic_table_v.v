`timescale 1ns / 1ps
module cubic_table(
    input clk,
    input [9:0] dx,
    output reg [9:0] f0,
    output reg [9:0] f1,
    output reg [9:0] f2,
    output reg [9:0] f3
);

(* ROM_STYLE="DISTRIBUTED" *) reg [9:0] cubic_table_0[1023:0];
(* ROM_STYLE="DISTRIBUTED" *) reg [9:0] cubic_table_1[1023:0];
(* ROM_STYLE="DISTRIBUTED" *) reg [9:0] cubic_table_2[1023:0];
(* ROM_STYLE="DISTRIBUTED" *) reg [9:0] cubic_table_3[1023:0];

initial $readmemb("cubic_table_0.txt", cubic_table_0);
initial $readmemb("cubic_table_1.txt", cubic_table_1);
initial $readmemb("cubic_table_2.txt", cubic_table_2);
initial $readmemb("cubic_table_3.txt", cubic_table_3);

always @(posedge clk) begin
    f0 <= cubic_table_0[dx];
    f1 <= cubic_table_1[dx];
    f2 <= cubic_table_2[dx];
    f3 <= cubic_table_3[dx];
end

endmodule
