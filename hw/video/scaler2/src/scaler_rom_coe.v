//-----------------------------------------------------------------------
//
// Engineer    : Golovachenko Victor
//
//------------------------------------------------------------------------
`timescale 1ns / 1ps

module scaler_rom_coe #(
    parameter COE_ROM_DEPTH = 32,
    parameter POINT_COUNT = 4,
    parameter COE_WIDTH = 10
)(
    input [($clog2(COE_ROM_DEPTH)) - 1:0] portA_adr,
    output reg [(POINT_COUNT*COE_WIDTH)-1:0] portA_do,

    input [($clog2(COE_ROM_DEPTH)) - 1:0] portB_adr,
    output reg [(POINT_COUNT*COE_WIDTH)-1:0] portB_do,

    input clk
);

(* ROM_STYLE="BLOCK" *) reg [COE_WIDTH-1:0] rom_0[COE_ROM_DEPTH-1:0];
(* ROM_STYLE="BLOCK" *) reg [COE_WIDTH-1:0] rom_1[COE_ROM_DEPTH-1:0];
(* ROM_STYLE="BLOCK" *) reg [COE_WIDTH-1:0] rom_2[COE_ROM_DEPTH-1:0];
(* ROM_STYLE="BLOCK" *) reg [COE_WIDTH-1:0] rom_3[COE_ROM_DEPTH-1:0];

initial $readmemb("../src/cubic_table_0.txt", rom_0);
initial $readmemb("../src/cubic_table_1.txt", rom_1);
initial $readmemb("../src/cubic_table_2.txt", rom_2);
initial $readmemb("../src/cubic_table_3.txt", rom_3);

always @(posedge clk) begin
    portA_do[COE_WIDTH*0 +: COE_WIDTH] <= rom_0[portA_adr];
    portA_do[COE_WIDTH*1 +: COE_WIDTH] <= rom_1[portA_adr];
    portA_do[COE_WIDTH*2 +: COE_WIDTH] <= rom_2[portA_adr];
    portA_do[COE_WIDTH*3 +: COE_WIDTH] <= rom_3[portA_adr];

    portB_do[COE_WIDTH*0 +: COE_WIDTH] <= rom_0[portB_adr];
    portB_do[COE_WIDTH*1 +: COE_WIDTH] <= rom_1[portB_adr];
    portB_do[COE_WIDTH*2 +: COE_WIDTH] <= rom_2[portB_adr];
    portB_do[COE_WIDTH*3 +: COE_WIDTH] <= rom_3[portB_adr];
end



//parameter [255:1] PARAM_ARRAY [2 : 0] = {"../src/cubic_table_0.txt", "../src/cubic_table_1.txt", "../src/cubic_table_2.txt"};

//parameter string ROM_COE_INIT [4] = '{"../src/cubic_table_0.txt",
//                                      "../src/cubic_table_1.txt",
//                                      "../src/cubic_table_2.txt",
//                                      "../src/cubic_table_3.txt"
//                                      };
//
//genvar i;
//generate
//    for (i=0; i<POINT_COUNT; i=i+1)  begin
//        scaler_rom2_coe # (
//            .INIT(ROM_COE_INIT[i]),
//            .COE_WIDTH (COE_WIDTH)
//        ) rom_coe (
//            .addr(coe_adr),
//            .do_o(portB_do[COE_WIDTH*i +: COE_WIDTH]),
//            .clk(clk)
//        );
//    end
//endgenerate


endmodule
