//-----------------------------------------------------------------------
//
// author    : Golovachenko Victor
//
//------------------------------------------------------------------------
`timescale 1ns / 1ps

module brightness_tb # (
    parameter TEST_SAMPLE_COUNT = 8,
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
int contrast;
real contrast_real;
real contrast_frac;
int contrast_int;

int brightness;

real r_out_real;
real g_out_real;
real b_out_real;
int r_out_int;
int g_out_int;
int b_out_int;

reg de_i = 1'b0;
wire de_o;

int c0;
initial begin : sim_main
    r_out_real = 0;
    g_out_real = 0;
    b_out_real = 0;

    brightness = 0;
    contrast_real = 0.0;
    de_i = 1'b0;

    for (c0=0; c0<TEST_SAMPLE_COUNT; c0++) begin
        @(posedge clk);
        de_i = 1'b1;

        contrast_int = $urandom_range(2, 0);//$urandom;
        contrast_frac = ($urandom%1000)/10000.0;
        contrast_real = contrast_int[1:0] + ((contrast_int[1:0] < 3) ? contrast_frac : 0.0);
        // contrast_real = 1.0;
        contrast = contrast_real * COE_MULT;

        // $urandom_range( int unsigned maxval, int unsigned minval = 0 );
        r = $urandom_range(255, 0);
        g = $urandom_range(255, 0);
        b = $urandom_range(255, 0);

        r_out_real = contrast_real*(r - 128) + 128 + brightness;
        g_out_real = contrast_real*(g - 128) + 128 + brightness;
        b_out_real = contrast_real*(b - 128) + 128 + brightness;

        r_out_int = ($rtoi(r_out_real) > 255) ? 255 : ($rtoi(r_out_real) < 0) ? 0 : $rtoi(r_out_real);
        g_out_int = ($rtoi(g_out_real) > 255) ? 255 : ($rtoi(g_out_real) < 0) ? 0 : $rtoi(g_out_real);
        b_out_int = ($rtoi(b_out_real) > 255) ? 255 : ($rtoi(b_out_real) < 0) ? 0 : $rtoi(b_out_real);

        $display("x[%03d]: ", c0, y, contrast_real, (coe_real*(y - 128) + 128) );
        $display("x[%03d]: brightness=%03d; contrast=(%1.3f, %04d(dec))", c0, brightness, saturation_real, saturation);
        $display("\t r(in)=%03d; calc out r: %1.3f(float), (%03d)(normalize)", r, r_out_real, r_out_int);
        $display("\t g(in)=%03d; calc out g: %1.3f(float), (%03d)(normalize)", g, g_out_real, g_out_int);
        $display("\t b(in)=%03d; calc out b: %1.3f(float), (%03d)(normalize)", b, b_out_real, b_out_int);
        $display("\n");

        #50;
    end

    $stop;

end : sim_main


brightness #(
    .PIXEL_WIDTH (PIXEL_WIDTH)
) brightness_m (
    .contrast_i(contrast[15:0]),
    .brightness_i(brightness[15:0]),

    .di_i ({b[PIXEL_WIDTH-1:0],g[PIXEL_WIDTH-1:0],r[PIXEL_WIDTH-1:0]}),
    .de_i (de_i),
    .hs_i (1'b0),
    .vs_i (1'b0),

    .do_o(),
    .de_o(),
    .hs_o(),
    .vs_o(),

    .clk(clk)
);

endmodule
