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
real r_out_real,g_out_real,b_out_real;

int saturation;
real saturation_real;

real y_real,y_real_t;
real ycoe0_real,ycoe1_real,ycoe2_real;
int ycoe0,ycoe1,ycoe2;

int c0;
initial begin : sim_main
    y_real = 0;
    r_out_real = 0;
    g_out_real = 0;
    b_out_real = 0;

    //y = (ycoe0*r) + (ycoe1*g) + (ycoe2*b)
    ycoe0_real = 0.299;
    ycoe1_real = 0.587;
    ycoe2_real = 0.144;

    ycoe0 = ycoe0_real * COE_MULT;
    ycoe1 = ycoe1_real * COE_MULT;
    ycoe2 = ycoe2_real * COE_MULT;

    for (c0=0; c0<1; c0++) begin
        @(posedge clk);
        saturation_real = 1.0;
        saturation = saturation_real * COE_MULT;

        // $urandom_range( int unsigned maxval, int unsigned minval = 0 );
        r = 255;//$urandom_range(255, 128); //140 - c0;//
        g = 255;//$urandom_range(255, 128); //140 - c0;//
        b = 255;//$urandom_range(255, 128); //140 - c0;//

        //r' = y + (r - y)*saturation
        //r' = y + r*saturation - y*saturation
        y_real_t = ((ycoe0_real*r) + (ycoe1_real*g) + (ycoe2_real*b));
        y_real = (y_real_t > 255) ? 255.0 : y_real_t;
        r_out_real = y_real + (r - y_real)*saturation_real;
        $display("(y_real * saturation_real): %1.3f*%1.3f=%1.3f", y_real, saturation_real, (y_real*saturation_real));
        $display("(r * saturation_real): %03d*%1.3f=%1.3f", r, saturation_real, (r*saturation_real));
        $display("(y_real + r*saturation_real): %1.3f + (%03d*%1.3f)=%1.3f",y_real, r, saturation_real, (y_real + r*saturation_real));
        $display("(y_real + r*saturation_real) - (y_real * saturation_real): %1.3f - %1.3f=%1.3f",(y_real + r*saturation_real), (y_real*saturation_real), r_out_real);


        g_out_real = y_real + (g - y_real)*saturation_real;
        b_out_real = y_real + (b - y_real)*saturation_real;
        $display("x[%03d]: \t r=%03d; g=%03d; b=%03d; saturation=%1.3f; ycoe[0]=%1.3f; ycoe[1]=%1.3f; ycoe[2]=%1.3f; y=%1.3f; r_out=%1.3f; g_out=%1.3f; b_out=%1.3f", c0, r,g,b
                                        , saturation_real
                                        ,ycoe0_real, ycoe1_real, ycoe2_real
                                        ,y_real
                                        ,r_out_real, g_out_real, b_out_real );
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
