`timescale 1ns / 1ps

module scaler_rom_coe #(
    parameter COE_WIDTH = 10
)(
    input [9:0] addr,

    output reg [COE_WIDTH-1:0] coe0,
    output reg [COE_WIDTH-1:0] coe1,
    output reg [COE_WIDTH-1:0] coe2,
    output reg [COE_WIDTH-1:0] coe3,

    input clk
);

(* ROM_STYLE="DISTRIBUTED" *) reg [COE_WIDTH-1:0] rom_0[1023:0];
(* ROM_STYLE="DISTRIBUTED" *) reg [COE_WIDTH-1:0] rom_1[1023:0];
(* ROM_STYLE="DISTRIBUTED" *) reg [COE_WIDTH-1:0] rom_2[1023:0];
(* ROM_STYLE="DISTRIBUTED" *) reg [COE_WIDTH-1:0] rom_3[1023:0];

initial $readmemb("../src/cubic_table_0.txt", rom_0);
initial $readmemb("../src/cubic_table_1.txt", rom_1);
initial $readmemb("../src/cubic_table_2.txt", rom_2);
initial $readmemb("../src/cubic_table_3.txt", rom_3);

always @(posedge clk) begin
    coe0 <= rom_0[addr];
    coe1 <= rom_1[addr];
    coe2 <= rom_2[addr];
    coe3 <= rom_3[addr];
end

endmodule
