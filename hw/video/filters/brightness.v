//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//
// |r |   |coe[0]| = r'
//-----------------------------------------------------------------------
module brightness #(
    parameter PIXEL_WIDTH = 8
)(
    input [15:0] coe_i,

    input [(PIXEL_WIDTH)-1:0] y_i ,
    input [(PIXEL_WIDTH)-1:0] cb_i,
    input [(PIXEL_WIDTH)-1:0] cr_i,
    input                     de_i,
    input                     hs_i,
    input                     vs_i,

    output reg [(PIXEL_WIDTH)-1:0] y_o  = 0,
    output reg [(PIXEL_WIDTH)-1:0] cb_o = 0,
    output reg [(PIXEL_WIDTH)-1:0] cr_o = 0,
    output reg                     de_o = 0,
    output reg                     hs_o = 0,
    output reg                     vs_o = 0,

    input clk,
    input rst
);

reg [(PIXEL_WIDTH+4):0] sum = 0;
reg [(PIXEL_WIDTH)-1:0] sr_cb_i = 0;
reg [(PIXEL_WIDTH)-1:0] sr_cr_i = 0;
reg sr_de_i = 1'b0;
reg sr_hs_i = 1'b0;
reg sr_vs_i = 1'b0;

wire [(PIXEL_WIDTH+1)-1:0] coe;
assign coe = coe_i[(PIXEL_WIDTH+1)-1:0];

always @ (posedge clk) begin
    //stage0
    sum <= $signed({4'd0, y_i}) + $signed(coe);
    sr_cb_i <= cb_i;
    sr_cr_i <= cr_i;
    sr_de_i <= de_i;
    sr_hs_i <= hs_i;
    sr_vs_i <= vs_i;

    //stage1
    if (sum[(PIXEL_WIDTH+4)]) begin
        y_o <= 0;
    end else if (sum[(PIXEL_WIDTH)]) begin
        y_o <= {PIXEL_WIDTH{1'b1}};
    end else begin
        y_o <= sum[(PIXEL_WIDTH)-1:0];
    end
    cb_o <= sr_de_i;
    cr_o <= sr_de_i;
    hs_o <= sr_hs_i;
    vs_o <= sr_vs_i;

    //stage2
end


endmodule
