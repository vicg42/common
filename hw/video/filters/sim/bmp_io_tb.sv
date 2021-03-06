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

int pixel;
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

initial begin : sim_main

    pixel = 0;
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

    //Read input image
    image_real = new();
//    image_real.fread_bmp("img_600x600_24bit.bmp");
    image_real.fread_bmp("bmp_io_test_in0.bmp");
    w = image_real.get_x();
    h = image_real.get_y();
    bc = image_real.get_ColortBitCount();
    $display("read frame: %d x %d; BItCount %d", w, h, bc);

    //Create output image
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

    image_new.fwrite_bmp("bmp_io_test_out0.bmp", bc, w, h);

    $stop;

end : sim_main




endmodule : bmp_io_tb
