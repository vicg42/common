//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//
// |r |   |coe[0]| = r'
// |g | * |coe[1]| = g'
// |b |   |coe[2]| = b'
//-----------------------------------------------------------------------
module mult_v1 #(
    parameter COE_WIDTH = 16, //(Q3.10) unsigned fixed point. 1024(0x400) is 1.000
    parameter COE_FRACTION_WIDTH = 10,
    parameter COE_COUNT = 3,
    parameter PIXEL_WIDTH = 8
)(
    input [(COE_WIDTH*COE_COUNT)-1:0] coe_i,

    //R [PIXEL_WIDTH*0 +: PIXEL_WIDTH]
    //G [PIXEL_WIDTH*1 +: PIXEL_WIDTH]
    //B [PIXEL_WIDTH*2 +: PIXEL_WIDTH]
    input [(PIXEL_WIDTH*3)-1:0] di_i,
    input                       de_i,
    input                       hs_i,
    input                       vs_i,

    output [(PIXEL_WIDTH*3)-1:0] do_o,
    output reg                   de_o = 0,
    output reg                   hs_o = 0,
    output reg                   vs_o = 0,

    input clk,
    input rst
);

localparam ZERO_FILL = (13 - PIXEL_WIDTH);
localparam OVERFLOW_BIT = COE_FRACTION_WIDTH + PIXEL_WIDTH;
localparam [23:0] ROUND_ADDER = (1 << (COE_FRACTION_WIDTH - 1)); //0.5
reg [23:0] mr = 0, mg = 0, mb = 0;
reg [24:0] mr_round = 0, mg_round = 0, mb_round = 0;
reg [1:0] sr_de_i = 0;
reg [1:0] sr_hs_i = 0;
reg [1:0] sr_vs_i = 0;

wire [12:0] coe [COE_COUNT-1:0];
wire [12:0] di [COE_COUNT-1:0];
reg [PIXEL_WIDTH-1:0] do_ [COE_COUNT-1:0];
genvar k;
generate
    for (k=0; k<COE_COUNT; k=k+1) begin : ch
        assign coe[k] = coe_i[(k*COE_WIDTH) +: 13];
        assign di[k] = {{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*k +: PIXEL_WIDTH]};
        assign do_o[PIXEL_WIDTH*k +: PIXEL_WIDTH] = do_[k];
    end
endgenerate

always @ (posedge clk) begin
    //stage0
    mr <= coe[0] * di[0];
    mg <= coe[1] * di[1];
    mb <= coe[2] * di[2];
    sr_de_i[0] <= de_i;
    sr_hs_i[0] <= hs_i;
    sr_vs_i[0] <= vs_i;

    //stage1
    mr_round <= mr + ROUND_ADDER;
    mg_round <= mg + ROUND_ADDER;
    mb_round <= mb + ROUND_ADDER;
    sr_de_i[1] <= sr_de_i[0];
    sr_hs_i[1] <= sr_hs_i[0];
    sr_vs_i[1] <= sr_vs_i[0];

    //stage2
    de_o <= sr_de_i[1];
    hs_o <= sr_hs_i[1];
    vs_o <= sr_vs_i[1];
end

always @ (posedge clk) begin
    if (|mr_round[20:OVERFLOW_BIT]) do_[0] <= {PIXEL_WIDTH{1'b1}};
    else                            do_[0] <= mr_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];
end

always @ (posedge clk) begin
    if (|mg_round[20:OVERFLOW_BIT]) do_[1] <= {PIXEL_WIDTH{1'b1}};
    else                            do_[1] <= mg_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];
end

always @ (posedge clk) begin
    if (|mb_round[20:OVERFLOW_BIT]) do_[2] <= {PIXEL_WIDTH{1'b1}};
    else                            do_[2] <= mb_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];
end


endmodule
