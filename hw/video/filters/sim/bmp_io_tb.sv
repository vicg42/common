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

module bmp_io_tb;

BMP_IO image_real;
BMP_IO image_gray;
BMP_IO image_color;

int pixel;
int idx;
int x;
int y;
int w;
int h;
int bc;
int bcnt;
int Green;
int Red;
int Blue;
int White;
int pixcnt;

initial begin : sim_main

    pixel = 0;
    bc = 0;
    bcnt = 0;
    x = 0;
    y = 0;
    w = 0;
    h = 0;
    idx = 0;

    //Read input image
    image_real = new();
    image_real.fread_bmp("test-13.bmp");
    w = image_real.get_x();
    h = image_real.get_y();
    bc = image_real.get_ColortBitCount();
    $display("read frame: %d x %d; BItCount %d", w, h, bc);

    //Create output image gray
    w = 256;
    h = 256;
    bc = 8;
    image_gray = new();
    image_gray.set_pixel_array(w*h*(bc/8));
    for (y = 0; y < h; y++) begin
        for (x = 0; x < w; x++) begin
            image_gray.set_pixel(idx, x[0 +: 8]);
            idx++;
        end
    end
    image_gray.fwrite_bmp("bmp_io_test_out_gray0.bmp", bc, w, h);

    //Create output image color
    w = 256;
    h = 256;
    bc = 24;
    Green = 32'h0000FF;
    Red = 32'h00FF00;
    Blue = 32'hFF0000;
    White = 32'hFFFFFF;
    image_color = new();
    image_color.set_pixel_array(w*h*(bc/8));
    for (y = 0; y < h; y++) begin
        pixcnt = 0;
        for (x = 0; x < w; x++) begin
            if (pixcnt[5:4] == 0) begin
                pixel = Red;
            end else if (pixcnt[5:4] == 1) begin
                pixel = Green;
            end else if (pixcnt[5:4] == 2) begin
                pixel = Blue;
            end else if (pixcnt[5:4] == 3) begin
                pixel = White;
            end
            pixcnt++;

            for (bcnt = 0; bcnt < (bc/8); bcnt++) begin
                image_color.set_pixel(idx, pixel[(bcnt*8) +: 8]);
                idx++;
            end
        end
    end

    image_color.fwrite_bmp("bmp_io_test_out_color0.bmp", bc, w, h);

    $stop;

end : sim_main

endmodule : bmp_io_tb
