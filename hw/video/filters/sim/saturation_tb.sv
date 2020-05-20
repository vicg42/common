//-----------------------------------------------------------------------
//
// author    : Golovachenko Victor
//
//------------------------------------------------------------------------
`timescale 1ns / 1ps

module saturation_tb # (
    parameter COE_MULT = 64,
    parameter PIXEL_WIDTH = 8
)();

//***********************************
//System clock gen
//***********************************
localparam CLK_PERIOD = 8; //8 - 126MHz; 16 - 62.5MHz
reg clk = 1'b1;
always #(CLK_PERIOD/2) clk = ~clk;


int r,g,b;

int saturation;
real saturation_real;

real ycoe0_real,ycoe1_real,ycoe2_real;
int ycoe0,ycoe1,ycoe2;

int c0;
initial begin : sim_main
    //y = (ycoe0*r) + (ycoe1*g) + (ycoe2*b)
    ycoe0_real = 0.299;
    ycoe1_real = 0.587;
    ycoe2_real = 0.144;

    ycoe0 = ycoe0_real * COE_MULT;
    ycoe1 = ycoe1_real * COE_MULT;
    ycoe2 = ycoe2_real * COE_MULT;

    for (c0=0; c0<3; c0++) begin
        @(posedge clk);
        // $urandom_range( int unsigned maxval, int unsigned minval = 0 );
        r = 255;//$urandom_range(255, 128); //140 - c0;//
        g = 255;//$urandom_range(255, 128); //140 - c0;//
        b = 255;//$urandom_range(255, 128); //140 - c0;//
        saturation_real = 1.0;
        saturation = saturation_real * COE_MULT;
        $display("x[%03d]: r=%03d; g=%03d; b=%03d; saturation=%1.3f; ycoe[0]=%1.3f; ycoe[1]=%1.3f; ycoe[2]=%1.3f; y=%f", c0, r,g,b
                                        , saturation_real
                                        ,ycoe0_real, ycoe1_real, ycoe2_real
                                        ,((ycoe0_real*r) + (ycoe1_real*g) + (ycoe2_real*b)) );
        #50;
    end

    $stop;

end : sim_main

saturation #(
    .PIXEL_WIDTH (PIXEL_WIDTH)
) saturation_m (
    .saturation_i(saturation[15:0]),
    .ycoe0_i(ycoe0[15:0]),
    .ycoe1_i(ycoe1[15:0]),
    .ycoe2_i(ycoe2[15:0]),

    .di_i  ({b[PIXEL_WIDTH-1:0],g[PIXEL_WIDTH-1:0],r[PIXEL_WIDTH-1:0]}),
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
