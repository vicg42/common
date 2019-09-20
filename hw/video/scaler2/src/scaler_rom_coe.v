//-----------------------------------------------------------------------
//
// Engineer    : Golovachenko Victor
//
//------------------------------------------------------------------------
`timescale 1ns / 1ps

`include "user_pkg.v"

module scaler_rom_coe #(
    parameter COE_DEPTH = 32,
    parameter COE_WIDTH = 10
)(
    input [(`CLOG2(COE_DEPTH)) - 1:0] addr,

    output reg [COE_WIDTH-1:0] rom0_do,
    output reg [COE_WIDTH-1:0] rom1_do,
    output reg [COE_WIDTH-1:0] rom2_do,
    output reg [COE_WIDTH-1:0] rom3_do,

    input clk
);

(* ROM_STYLE="DISTRIBUTED" *) reg [COE_WIDTH-1:0] rom_0[0:COE_DEPTH-1];
(* ROM_STYLE="DISTRIBUTED" *) reg [COE_WIDTH-1:0] rom_1[0:COE_DEPTH-1];
(* ROM_STYLE="DISTRIBUTED" *) reg [COE_WIDTH-1:0] rom_2[0:COE_DEPTH-1];
(* ROM_STYLE="DISTRIBUTED" *) reg [COE_WIDTH-1:0] rom_3[0:COE_DEPTH-1];

initial $readmemb("../src/cubic_table_0.txt", rom_0);
initial $readmemb("../src/cubic_table_1.txt", rom_1);
initial $readmemb("../src/cubic_table_2.txt", rom_2);
initial $readmemb("../src/cubic_table_3.txt", rom_3);

always @(posedge clk) begin
    rom0_do <= rom_0[addr];
    rom1_do <= rom_1[addr];
    rom2_do <= rom_2[addr];
    rom3_do <= rom_3[addr];
end

endmodule
