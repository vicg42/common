//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//-----------------------------------------------------------------------

`timescale 1ns / 1ps

`include "bmp_io.sv"

module filter_median_5x5_tb #(
    parameter READ_IMG_FILE = "img_600x600_8bit_noise.bmp", //"_bayer_lighthouse.bmp", //..
    parameter WRITE_IMG_FILE = "filter_median_5x5_tb",

    parameter DE_I_PERIOD = 0, //0 - no empty cycles
                             //2 - 1 empty cycle per pixel
                             //4 - 3 empty cycle per pixel
                             //etc...
    parameter LINE_SIZE_MAX = 4096,
    parameter PIXEL_WIDTH = 8
);


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

logic [PIXEL_WIDTH-1:0] bypass_o;

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



filter_median_5x5 #(
    .LINE_SIZE_MAX(LINE_SIZE_MAX),
    .PIXEL_WIDTH(PIXEL_WIDTH)
) filter_median (
    .bypass(1'b0),

    //input resolution X * Y
    .di_i(di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH]),
    .de_i(de_i),
    .hs_i(hs_i),
    .vs_i(vs_i),

    //output resolution (X - 4) * (Y - 4)
    .do_o(do_o),
    .de_o(de_o),
    .hs_o(hs_o),
    .vs_o(vs_o),

    .bypass_o(bypass_o),

    .clk(clk),
    .rst(1'b0)
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

