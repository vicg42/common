//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 14.06.2018 15:38:21
// Module Name : bmp_io_tb
//
// Description :
//
//------------------------------------------------------------------------
`timescale 1ns / 1ps

`include "bmp_io.sv"

module bmp_io_tb # (
);


BMP_IO image_real;
BMP_IO image_new;
BMP_IO image2_new;

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
int n2data [4096*2048];

int   di_i;
logic de_i;
logic hs_i;
logic vs_i;

localparam FRAME_COUNT = 2;
int fr;

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
    hs_i = 0;
    vs_i = 0;

    image_real = new();
    image_real.fread_bmp("img_600x600_24bit.bmp");
    w = image_real.get_x();
    h = image_real.get_y();
    bc = image_real.get_ColortBitCount();
    $display("read frame: %d x %d; BItCount %d", w, h, bc);


    image_new = new();
    image_new_size = w*h*(bc/8);
    image_new.set_pixel_array(image_new_size);
    for (y = 0; y < h; y++) begin
        for (x = 0; x < w; x++) begin
            pixel = image_real.get_pixel(x, y);
            for (bcnt = 0; bcnt < (bc/8); bcnt++) begin
                image_new.set_pixel(idx, pixel[(bcnt*8) +: 8]);
                idx++;
            end
        end
    end

    image_new.fwrite_bmp("111_nn.bmp", bc, w, h);


    $stop;

end : sim_main




endmodule : bmp_io_tb
