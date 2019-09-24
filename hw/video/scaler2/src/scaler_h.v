//-----------------------------------------------------------------------
//
// Engineer    : Golovachenko Victor
//
//------------------------------------------------------------------------
`timescale 1ns / 1ps

`include "user_pkg.v"

module scaler_h #(
//    parameter TABLE_INPUT_WIDTH = 10,
    parameter COE_WIDTH = 10,
    parameter PIXEL_STEP = 4096,
    parameter DATA_WIDTH = 8
)(
    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    input [15:0] scale_step,

    input [DATA_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    output reg [15:0] pix_count_o = 0,
    output reg [DATA_WIDTH-1:0] do_o = 0,
    output reg de_o = 0,
    output reg hs_o = 0,
    output reg vs_o = 0,

    input clk,
    input rst
);
// -------------------------------------------------------------------------
//localparam COE_WIDTH = TABLE_INPUT_WIDTH;
//localparam [9:0] TABLE_INPUT_WIDTH_MASK = (10'h3FF << (10 - TABLE_INPUT_WIDTH)) & 10'h3FF;

localparam MUL_WIDTH = COE_WIDTH + DATA_WIDTH;
localparam OVERFLOW_BIT = COE_WIDTH + DATA_WIDTH - 1;
localparam [MUL_WIDTH:0] MAX_OUTPUT = (1 << (DATA_WIDTH+COE_WIDTH)) - 1;
localparam [MUL_WIDTH:0] ROUND_ADDER = (1 << (COE_WIDTH-2)); //0.5

reg [23:0] cnt_pix_i = 0; // input pixels coordinate counter
reg [23:0] cnt_pix_o = PIXEL_STEP; // output pixels coordinate counter

wire [COE_WIDTH-1:0] coe [0:3];
reg [DATA_WIDTH-1:0] pix [0:3];
reg [MUL_WIDTH-1:0] mult [0:3];
//(* mult_style = "block" *)

reg signed [MUL_WIDTH+2-1:0] sum;

reg [DATA_WIDTH-1:0] sr_di_i [0:3];
initial
begin
   sr_di_i[0] = 0;
   sr_di_i[1] = 0;
   sr_di_i[2] = 0;
   sr_di_i[3] = 0;
end
reg [3:0] sr_hs_i = 0;
reg [3:0] sr_vs_i = 0;

reg new_de = 0;
reg [1:0] sr_de = 0;
reg [1:0] sr_hs = 0;
reg [1:0] sr_vs = 0;

reg bondary = 0;
reg [1:0] sr_bondary = 0;

wire hs;
wire vs;
assign hs = hs_i && sr_hs_i[3];
assign vs = vs_i && sr_vs_i[3];

always @(posedge clk) begin
    sr_hs_i[0] <= hs_i;
    sr_hs_i[1] <= sr_hs_i[0];
    sr_hs_i[2] <= sr_hs_i[1];
    sr_hs_i[3] <= sr_hs_i[2];

    sr_vs_i[0] <= vs_i;
    sr_vs_i[1] <= sr_vs_i[0];
    sr_vs_i[2] <= sr_vs_i[1];
    sr_vs_i[3] <= sr_vs_i[2];
end

always @(posedge clk) begin
    if (rst) begin
        new_de <= 0;
        cnt_pix_i <= 0;
        cnt_pix_o <= 0;//PIXEL_STEP;

    end else begin
        new_de <= 0;

        if (hs || vs) begin
            cnt_pix_i <= 0;
            cnt_pix_o <= PIXEL_STEP*0;//PIXEL_STEP*2;//
            bondary <= 1;
            sr_di_i[0] <= 0; pix[0] <= 0;
            sr_di_i[1] <= 0; pix[1] <= 0;
            sr_di_i[2] <= 0; pix[2] <= 0;
            sr_di_i[3] <= 0; pix[3] <= 0;

        end else begin
            if (de_i && !hs && !vs) begin
                sr_di_i[0] <= di_i      ;
                sr_di_i[1] <= sr_di_i[0];
                sr_di_i[2] <= sr_di_i[1];
                sr_di_i[3] <= sr_di_i[2];
                cnt_pix_i <= cnt_pix_i + PIXEL_STEP;
            end

            if (new_de) begin
                bondary <= 0;
            end

            if (cnt_pix_i > cnt_pix_o) begin
                new_de <= 1;

                pix[0] <= di_i      ;//sr_di_i[0];
                pix[1] <= sr_di_i[0];//sr_di_i[1];
                pix[2] <= sr_di_i[1];//sr_di_i[2];
                pix[3] <= sr_di_i[2];//sr_di_i[3];
//                pix[3] <= (cnt_pix_i <= (PIXEL_STEP*2)) ? 0 : sr_di_i[3]; // boundary check, needed only for step<1.0 (upsize)

                cnt_pix_o <= cnt_pix_o + scale_step;
            end
        end
    end
end

wire [9:0] coe_idx;
assign coe_idx = cnt_pix_o[7 +: 5];

scaler_rom_coe # (
    .COE_WIDTH (COE_WIDTH)
) rom_coe (
    .addr(coe_idx),

    .rom0_do(coe[0]),
    .rom1_do(coe[1]),
    .rom2_do(coe[2]),
    .rom3_do(coe[3]),

    .clk(clk)
);

always @(posedge clk) begin
    //stage 0
    mult[0] <= coe[0] * pix[0];
    mult[1] <= coe[1] * pix[1];
    mult[2] <= coe[2] * pix[2];
    mult[3] <= coe[3] * pix[3];

    sr_de[0] <= new_de;
    sr_hs[0] <= hs;
    sr_vs[0] <= vs;
    sr_bondary[0] <= bondary;

    //stage 1
    sum <= mult[1] + mult[2] - mult[0] - mult[3] + ROUND_ADDER;

    sr_de[1] <= sr_de[0];
    sr_hs[1] <= sr_hs[0];
    sr_vs[1] <= sr_vs[0];
    sr_bondary[1] <= sr_bondary[0];

    //stage 2
    if (sr_de[1]) begin
        if (sum < 0) begin
            do_o <= 0;
        end else if (sum[OVERFLOW_BIT]) begin
            do_o <= MAX_OUTPUT;
        end else begin
            do_o <= sum[COE_WIDTH-1 +: DATA_WIDTH];
        end
    end
    de_o <= sr_de[1] && !sr_bondary[1];
    hs_o <= sr_hs[1];
    vs_o <= sr_vs[1];
end


reg [15:0] pix_cnt_o = 0;
always @(posedge clk) begin
    if (!hs_o && sr_hs[1]) begin
        pix_count_o <= pix_cnt_o;
        pix_cnt_o <= 0;
    end else if (de_o) begin
        pix_cnt_o <= pix_cnt_o + 1;
    end
end


endmodule
