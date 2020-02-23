//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//
// |r |   |coe[0]| = r
// |g | * |coe[1]| = g
// |b |   |coe[2]| = b
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

    output reg [(PIXEL_WIDTH*3)-1:0] do_o,
    output reg                       de_o,
    output reg                       hs_o,
    output reg                       vs_o,

    input clk,
    input rst
);

localparam ZERO_FILL = (16 - PIXEL_WIDTH);
localparam OVERFLOW_BIT = COE_FRACTION_WIDTH + PIXEL_WIDTH;
localparam [31:0] ROUND_ADDER = (1 << (COE_FRACTION_WIDTH - 1)); //0.5
reg [31:0] mr = 0, mg = 0, mb = 0;
reg [31:0] mr_round = 0, mg_round = 0, mb_round = 0;
reg [1:0] sr_de_i = 0;
reg [1:0] sr_hs_i = 0;
reg [1:0] sr_vs_i = 0;
always @ (posedge clk) begin
    //
    mr <= coe_i[(0*COE_WIDTH) +: 16] * {{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH]};
    mg <= coe_i[(1*COE_WIDTH) +: 16] * {{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*1 +: PIXEL_WIDTH]};
    mb <= coe_i[(2*COE_WIDTH) +: 16] * {{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*2 +: PIXEL_WIDTH]};
    sr_de_i[0] <= de_i;
    sr_hs_i[0] <= hs_i;
    sr_vs_i[0] <= vs_i;

    //
    mr_round <= mr + ROUND_ADDER;
    mg_round <= mg + ROUND_ADDER;
    mb_round <= mb + ROUND_ADDER;
    sr_de_i[1] <= sr_de_i[0];
    sr_hs_i[1] <= sr_hs_i[0];
    sr_vs_i[1] <= sr_vs_i[0];

    //
    do_o[PIXEL_WIDTH*0 +: PIXEL_WIDTH] = (|mr_round[31:OVERFLOW_BIT]) ? {PIXEL_WIDTH{1'b1}} : mr_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];
    do_o[PIXEL_WIDTH*1 +: PIXEL_WIDTH] = (|mg_round[31:OVERFLOW_BIT]) ? {PIXEL_WIDTH{1'b1}} : mg_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];
    do_o[PIXEL_WIDTH*2 +: PIXEL_WIDTH] = (|mb_round[31:OVERFLOW_BIT]) ? {PIXEL_WIDTH{1'b1}} : mb_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];
    de_o <= sr_de_i[1];
    hs_o <= sr_hs_i[1];
    vs_o <= sr_vs_i[1];
end


`ifdef SIM_DBG
wire [COE_WIDTH-1:0] coe [COE_COUNT-1:0];
genvar k0;
generate
    for (k0=0; k0<COE_COUNT; k0=k0+1) begin
        assign coe[k0] = coe_i[(k0*COE_WIDTH) +: COE_WIDTH];
    end
endgenerate

wire [PIXEL_WIDTH-1:0] di [COE_COUNT-1:0];
genvar k1;
generate
    for (k1=0; k1<COE_COUNT; k1=k1+1) begin
        assign di[k1] = di_i[(k1*PIXEL_WIDTH) +: PIXEL_WIDTH];
    end
endgenerate

wire [PIXEL_WIDTH-1:0] do [COE_COUNT-1:0];
genvar k2;
generate
    for (k2=0; k2<COE_COUNT; k2=k2+1) begin
        assign do[k2] = do_o[(k2*PIXEL_WIDTH) +: PIXEL_WIDTH];
    end
endgenerate
`endif

endmodule
