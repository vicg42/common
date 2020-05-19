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
real coe_real;

int c0;
initial begin : sim_main

    for (c0=0; c0<30; c0++) begin
        @(posedge clk);
        // $urandom_range( int unsigned maxval, int unsigned minval = 0 );
        y = $urandom_range(255, 128); //140 - c0;//
        coe_real = 0.7;
        coe = coe_real * 64;
        $display("x[%03d]: y=%d; coe=%f; result=%f", c0, y, coe_real, (coe_real*(y - 128) + 128) );
        #50;
    end

    $stop;

end : sim_main

// wire coe_i [COE_WIDTH-1:0];
// assign coe_i[COE_WIDTH-1:0] = coe[COE_WIDTH-1:0];

brightness #(
    .COE_WIDTH(9),
    .COE_FRACTION_WIDTH(6),
    .PIXEL_WIDTH (PIXEL_WIDTH)
) brightness_m (
    .contrast_i(coe[15:0]),
    .brightness_i(16'd0),

    .di_i  ({y[PIXEL_WIDTH-1:0],y[PIXEL_WIDTH-1:0],y[PIXEL_WIDTH-1:0]}),
    .de_i (1'b0),
    .hs_i (1'b0),
    .vs_i (1'b0),

    .do_o (),
    .de_o(),
    .hs_o(),
    .vs_o(),

    .clk(clk)
);

endmodule
