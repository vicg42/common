//-----------------------------------------------------------------------
//
// author    : Golovachenko Victor
//
//------------------------------------------------------------------------
`timescale 1ns / 1ps

module brightness_tb # (
    parameter COE_WIDTH = 9,
    parameter PIXEL_WIDTH = 8
)();

//***********************************
//System clock gen
//***********************************
localparam CLK_PERIOD = 8; //8 - 126MHz; 16 - 62.5MHz
reg clk = 1'b1;
always #(CLK_PERIOD/2) clk = ~clk;

int y;
int coe;

initial begin : sim_main

    y = 128;
    coe = -28;

    #2000

    $stop;

end : sim_main

// wire coe_i [COE_WIDTH-1:0];
// assign coe_i[COE_WIDTH-1:0] = coe[COE_WIDTH-1:0];

brightness #(
    .COE_WIDTH(COE_WIDTH),
    .PIXEL_WIDTH (PIXEL_WIDTH)
) brightness_m (
    .coe_i(coe[15:0]),

    .y_i  (y[PIXEL_WIDTH-1:0]),
    .cb_i (0),
    .cr_i (0),
    .de_i (1'b0),
    .hs_i (1'b0),
    .vs_i (1'b0),

    .y_o (),
    .cb_o(),
    .cr_o(),
    .de_o(),
    .hs_o(),
    .vs_o(),

    .clk(clk),
    .rst()
);

endmodule
