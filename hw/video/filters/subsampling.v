//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 22.05.2018 12:25:06
// Module Name : binning
//
// Description :
//
//------------------------------------------------------------------------

module subsampling #(
     parameter LINE_SIZE_MAX = 1024,
    parameter PIXEL_WIDTH = 8
)(
    input bypass,

    input [PIXEL_WIDTH-1:0] di_i,
    input                   de_i,
    input                   hs_i,
    input                   vs_i,

    output [PIXEL_WIDTH-1:0] do_o,
    output reg               de_o = 1'b0,
    output                   hs_o,
    output reg               vs_o,

    input clk,
    input rst
);

reg [PIXEL_WIDTH-1:0] sr_di_i;
reg sr_de_i = 1'b0;
reg sr_hs_i = 1'b0;
always @(posedge clk) begin
    sr_di_i <= di_i;
    sr_de_i <= de_i;
    sr_hs_i <= hs_i;
    vs_o <= vs_i;
end

wire hs_i_rising_edge;
wire hs_i_falling_edge;
wire vs_i_rising_edge;
wire vs_i_falling_edge;

assign hs_i_rising_edge = !sr_hs_i & hs_i;
assign hs_i_falling_edge = sr_hs_i & !hs_i;

assign vs_i_rising_edge = !vs_o & vs_i;
assign vs_i_falling_edge = vs_o & !vs_i;

reg line_out_en = 1'b0;
always @(posedge clk) begin
    if (vs_i_rising_edge) begin
        line_out_en <= 1'b0;
    end else if (hs_i_rising_edge) begin
        line_out_en <= ~line_out_en;
    end
end

always @(posedge clk) begin
    if (line_out_en) begin
        if (sr_de_i) begin
            de_o <= ~de_o;
        end else begin
            de_o <= 1'b0;
        end
    end
end

assign hs_o = ~(!sr_hs_i & line_out_en);
assign do_o = sr_di_i;

endmodule
