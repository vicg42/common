//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//------------------------------------------------------------------------

`timescale 1ns / 1ps

module timing_gen_tb # (
        parameter PIXEL_WIDTH = 8
) (
    output [PIXEL_WIDTH-1:0] do_o,
    output                   de_o,
    output                   hs_o,
    output                   vs_o
);


//***********************************
//System clock gen
//***********************************
logic clk = 1'b0;
always #(8/2) clk = ~clk;

timing_gen #(
    .PIXEL_WIDTH(PIXEL_WIDTH)
) timing_gen (
    .pix_count(50),
    .line_count(8),
    .hs_count(330),
    .vs_count(100),

    .do_o(do_o),
    .de_o(de_o),
    .hs_o(hs_o),
    .vs_o(vs_o),

    .clk(clk)
);

endmodule
