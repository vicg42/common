//-----------------------------------------------------------------------
// author : Viktor Golovachenko
//-----------------------------------------------------------------------
`timescale 1ns / 1ps

`include "bmp_io.sv"

module rgb_2_ycbcr_tb # (
    parameter COE_WIDTH = 13,
    parameter COE_FRACTION_WIDTH = 10,
    parameter READ_IMG_FILE = "img_600x600_8bit_noise.bmp", //"24x24_8bit_test1.bmp",
    parameter WRITE_IMG_FILE = "filter_median_tb",
    parameter DE_I_PERIOD = 0, //0 - no empty cycles
                             //2 - 1 empty cycle per pixel
                             //4 - 3 empty cycle per pixel
                             //etc...
    parameter LINE_SIZE_MAX = 4096,
    parameter PIXEL_WIDTH = 8
)();

real r_out_real,g_out_real,b_out_real;

real real_rgb2ycbcr_a00 = -1.100;//0.299;//
real real_rgb2ycbcr_a01 = -1.100;//0.587;//
real real_rgb2ycbcr_a02 = -1.100;//0.114;//

real real_rgb2ycbcr_a10 = -0.169;
real real_rgb2ycbcr_a11 = -0.331;
real real_rgb2ycbcr_a12 =  0.500;

real real_rgb2ycbcr_a20 =  0.500;
real real_rgb2ycbcr_a21 = -0.419;
real real_rgb2ycbcr_a22 = -0.081;

int rgb2ycbcr_c0 = 0  ; //  0
int rgb2ycbcr_c1 = 128; //  128
int rgb2ycbcr_c2 = 128; //  128

int rgb2ycbcr_a00 = $floor(real_rgb2ycbcr_a00 * (2**COE_FRACTION_WIDTH));
int rgb2ycbcr_a01 = $floor(real_rgb2ycbcr_a01 * (2**COE_FRACTION_WIDTH));
int rgb2ycbcr_a02 = $floor(real_rgb2ycbcr_a02 * (2**COE_FRACTION_WIDTH));

int rgb2ycbcr_a10 = $floor(real_rgb2ycbcr_a10 * (2**COE_FRACTION_WIDTH));
int rgb2ycbcr_a11 = $floor(real_rgb2ycbcr_a11 * (2**COE_FRACTION_WIDTH));
int rgb2ycbcr_a12 = $floor(real_rgb2ycbcr_a12 * (2**COE_FRACTION_WIDTH));

int rgb2ycbcr_a20 = $floor(real_rgb2ycbcr_a20 * (2**COE_FRACTION_WIDTH));
int rgb2ycbcr_a21 = $floor(real_rgb2ycbcr_a21 * (2**COE_FRACTION_WIDTH));
int rgb2ycbcr_a22 = $floor(real_rgb2ycbcr_a22 * (2**COE_FRACTION_WIDTH));


BMP_IO image_real;
BMP_IO image_new;

int pixel;
int pixel32b;
int idx;
int x;
int y;
int w;
int h;
int bc;
int bcnt;
int image_new_w;
int image_new_h;
int image_new_size;
int ndata [4096*2048];

int   di_i;
logic de_i;
logic hs_i;
logic vs_i;

localparam FRAME_COUNT = 2;
int fr;

logic [PIXEL_WIDTH-1:0] do_o;
logic de_o;
logic hs_o;
logic vs_o;

wire [PIXEL_WIDTH-1:0] s0_do;
wire s0_de;
wire s0_hs;
wire s0_vs;

//***********************************
//System clock gen
//***********************************
localparam CLK_PERIOD = 8; //8 - 126MHz; 16 - 62.5MHz
reg clk = 1'b1;
always #(CLK_PERIOD/2) clk = ~clk;

initial begin : sim_main

    pixel = 0;
    pixel32b = 0;
    bc = 0;
    bcnt = 0;
    x = 0;
    y = 0;
    w = 0;
    h = 0;
    image_new_w =0;
    image_new_h =0;
    image_new_size =0;
    idx = 0;

    di_i = 0;
    de_i = 0;
    hs_i = 1'b1;
    vs_i = 0;

    image_real = new();
    image_real.fread_bmp(READ_IMG_FILE);
    w = image_real.get_x();
    h = image_real.get_y();
    bc = image_real.get_ColortBitCount();
    $display("read frame: %d x %d; BItCount %d", w, h, bc);

    $display("rgb2ycbcr_a00 = %f * %04d = %04d", real_rgb2ycbcr_a00, (2**COE_FRACTION_WIDTH), rgb2ycbcr_a00);
    $display("rgb2ycbcr_a01 = %f * %04d = %04d", real_rgb2ycbcr_a01, (2**COE_FRACTION_WIDTH), rgb2ycbcr_a01);
    $display("rgb2ycbcr_a02 = %f * %04d = %04d", real_rgb2ycbcr_a02, (2**COE_FRACTION_WIDTH), rgb2ycbcr_a02);

    $display("rgb2ycbcr_a10 = %f * %04d = %04d", real_rgb2ycbcr_a00, (2**COE_FRACTION_WIDTH), rgb2ycbcr_a00);
    $display("rgb2ycbcr_a11 = %f * %04d = %04d", real_rgb2ycbcr_a01, (2**COE_FRACTION_WIDTH), rgb2ycbcr_a01);
    $display("rgb2ycbcr_a12 = %f * %04d = %04d", real_rgb2ycbcr_a02, (2**COE_FRACTION_WIDTH), rgb2ycbcr_a02);

    $display("rgb2ycbcr_a20 = %f * %04d = %04d", real_rgb2ycbcr_a00, (2**COE_FRACTION_WIDTH), rgb2ycbcr_a00);
    $display("rgb2ycbcr_a21 = %f * %04d = %04d", real_rgb2ycbcr_a01, (2**COE_FRACTION_WIDTH), rgb2ycbcr_a01);
    $display("rgb2ycbcr_a22 = %f * %04d = %04d", real_rgb2ycbcr_a02, (2**COE_FRACTION_WIDTH), rgb2ycbcr_a02);

    $display("rgb2ycbcr_c0 = %03d", rgb2ycbcr_c0);
    $display("rgb2ycbcr_c1 = %03d", rgb2ycbcr_c1);
    $display("rgb2ycbcr_c2 = %03d", rgb2ycbcr_c2);

    @(posedge clk);
    fr = 0;
    di_i = 0;
    de_i = 0;
    hs_i = 1'b1;
    vs_i = 0;
    #500;
//    w = 16;
//    h = 16;
//    @(posedge clk);
//    vs_i = 1;
    #500;
    for (fr = 0; fr < FRAME_COUNT; fr++) begin
        for (y = 0; y < h; y++) begin
            for (x = 0; x < w; x++) begin
                @(posedge clk);
                di_i = image_real.get_pixel(x, y);
//                di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH] = x;
                //for color image:
                //di_i[0  +: 8] - B
                //di_i[8  +: 8] - G
                //di_i[16 +: 8] - R
                if (DE_I_PERIOD == 0) begin
                    de_i = 1'b1;
                    hs_i = 1'b0;
                    vs_i = 1'b1;
                end else if (DE_I_PERIOD == 2) begin
                    de_i = 1'b0;
                    hs_i = 1'b0;
                    vs_i = 1'b1;
                    @(posedge clk);
                    de_i = 1'b1;
                end else if (DE_I_PERIOD == 4) begin
                    de_i = 1'b0;
                    hs_i = 1'b0;
                    vs_i = 1'b1;
                    @(posedge clk);
                    de_i = 1'b0;
                    hs_i = 1'b0;
                    vs_i = 1'b1;
                    @(posedge clk);
                    de_i = 1'b0;
                    hs_i = 1'b0;
                    vs_i = 1'b1;
                    @(posedge clk);
                    de_i = 1'b1;
                end
                #0;
            end
            @(posedge clk);
            de_i = 1'b0;
            hs_i = 1'b1;
//            @(posedge clk);
//            @(posedge clk);
            if (y == (h-1)) begin
                vs_i = 1'b0;
            end
            #350; //delay between line
        end
        @(posedge clk);
//        if (y == h) begin
//            vs_i = 1'b0;
//        end
        #110;
    end

    $stop;

end : sim_main


rgb_2_ycbcr #(
    .COE_WIDTH(COE_WIDTH),
    .COE_FRACTION_WIDTH(COE_FRACTION_WIDTH),
    .PIXEL_WIDTH (PIXEL_WIDTH)
) rgb_2_ycbcr_m (
    .CI_A00(rgb2ycbcr_a00),
    .CI_A01(rgb2ycbcr_a01),
    .CI_A02(rgb2ycbcr_a02),

    .CI_A10(rgb2ycbcr_a10),
    .CI_A11(rgb2ycbcr_a11),
    .CI_A12(rgb2ycbcr_a12),

    .CI_A20(rgb2ycbcr_a20),
    .CI_A21(rgb2ycbcr_a21),
    .CI_A22(rgb2ycbcr_a22),

    .CI_C0 (rgb2ycbcr_c0) ,
    .CI_C1 (rgb2ycbcr_c1) ,
    .CI_C2 (rgb2ycbcr_c2) ,

    //input data
    .r_i (di_i[PIXEL_WIDTH-1:0]),//(8'd255),//
    .g_i (di_i[PIXEL_WIDTH-1:0]),//(8'd255),//
    .b_i (di_i[PIXEL_WIDTH-1:0]),//(8'd255),//
    .de_i(de_i),
    .vs_i(hs_i),
    .hs_i(vs_i),

    //output data
    .y_o (),
    .cb_o(),
    .cr_o(),
    .de_o(),
    .vs_o(),
    .hs_o(),

    .bypass_di(0),
    .bypass_do(),

    .clk(clk)
);

monitor # (
    .DATA_WIDTH (PIXEL_WIDTH),
    .WRITE_IMG_FILE(WRITE_IMG_FILE)
) monitor (
    .di_i(do_o),
    .de_i(de_o),
    .hs_i(hs_o),
    .vs_i(vs_o),
    .clk (clk)
);

endmodule
