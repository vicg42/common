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
    image_real.fread_bmp("_25x25_8bit.bmp");
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
            if ((y==12) && (x==12)) pixel = 255;

//            else if ((y==11) && (x==12)) pixel = 192;
//            else if ((y==13) && (x==12)) pixel = 192;
            else if ((y==12) && (x==13)) pixel = 192;
            else if ((y==12) && (x==11)) pixel = 192;

//            else if ((y==10) && (x==12)) pixel = 100;
//            else if ((y==14) && (x==12)) pixel = 100;
            else if ((y==12) && (x==10)) pixel = 100;
            else if ((y==12) && (x==14)) pixel = 100;

//            else if ((y==13) && (x==11)) pixel = 100;
//            else if ((y==13) && (x==13)) pixel = 100;
//            else if ((y==11) && (x==11)) pixel = 100;
//            else if ((y==11) && (x==13)) pixel = 100;

//            else if ( (y==9) && (x==12)) pixel = 32;
//            else if ((y==15) && (x==12)) pixel = 32;
            else if ((y==12) && (x==9) ) pixel = 32;
            else if ((y==12) && (x==15)) pixel = 32;
//
//            else if ((y==14) && (x==11)) pixel = 32;
//            else if ((y==14) && (x==13)) pixel = 32;
//            else if ((y==13) && (x==14)) pixel = 32;
//            else if ((y==13) && (x==10)) pixel = 32;
//
//            else if ((y==10) && (x==11)) pixel = 32;
//            else if ((y==10) && (x==13)) pixel = 32;
//            else if ((y==11) && (x==14)) pixel = 32;
//            else if ((y==11) && (x==10)) pixel = 32;

            else if ((y==12) && (x==0) ) pixel = 50;
            else if ((y==12) && (x==1) ) pixel = 60;
            else if ((y==12) && (x==2) ) pixel = 70;
            else if ((y==12) && (x==3) ) pixel = 80;

//            else if ((y==12) && (x==23) ) pixel = 128;
            else if ((y==12) && (x==24) ) pixel = 120;
            else if ((y==12) && (x==23) ) pixel = 110;
            else if ((y==12) && (x==22) ) pixel = 100;
            else if ((y==12) && (x==21) ) pixel = 90;
//
//            else if ((y==1) && (x==12) ) pixel = 64;
//            else if ((y==23) && (x==12) ) pixel = 128;




            else if ((y==0) && (x==12)) pixel = 250;

            else if ((y==0) && (x==13)) pixel = 190;
            else if ((y==0) && (x==11)) pixel = 190;

            else if ((y==0) && (x==10)) pixel = 90;
            else if ((y==0) && (x==14)) pixel = 90;

            else if ((y==0) && (x==9) ) pixel = 30;
            else if ((y==0) && (x==15)) pixel = 30;

            else if ((y==0) && (x==0) ) pixel = 40;
            else if ((y==0) && (x==1) ) pixel = 50;
            else if ((y==0) && (x==2) ) pixel = 60;
            else if ((y==0) && (x==3) ) pixel = 70;

            else if ((y==0) && (x==24) ) pixel = 110;
            else if ((y==0) && (x==23) ) pixel = 100;
            else if ((y==0) && (x==22) ) pixel = 90;
            else if ((y==0) && (x==21) ) pixel = 80;



            else if ((y==1) && (x==12)) pixel = 240;

            else if ((y==1) && (x==13)) pixel = 180;
            else if ((y==1) && (x==11)) pixel = 190;

            else if ((y==1) && (x==10)) pixel = 80;
            else if ((y==1) && (x==14)) pixel = 80;

            else if ((y==1) && (x==9) ) pixel = 20;
            else if ((y==1) && (x==15)) pixel = 20;

            else if ((y==1) && (x==0) ) pixel = 45;
            else if ((y==1) && (x==1) ) pixel = 55;
            else if ((y==1) && (x==2) ) pixel = 65;
            else if ((y==1) && (x==3) ) pixel = 75;

            else if ((y==1) && (x==24) ) pixel = 115;
            else if ((y==1) && (x==23) ) pixel = 105;
            else if ((y==1) && (x==22) ) pixel = 95;
            else if ((y==1) && (x==21) ) pixel = 85;


            else if ((y==2) && (x==12)) pixel = 245;

            else if ((y==2) && (x==13)) pixel = 185;
            else if ((y==2) && (x==11)) pixel = 195;

            else if ((y==2) && (x==10)) pixel = 85;
            else if ((y==2) && (x==14)) pixel = 85;

            else if ((y==2) && (x==9) ) pixel = 25;
            else if ((y==2) && (x==15)) pixel = 25;

            else if ((y==2) && (x==0) ) pixel = 35;
            else if ((y==2) && (x==1) ) pixel = 45;
            else if ((y==2) && (x==2) ) pixel = 55;
            else if ((y==2) && (x==3) ) pixel = 65;

            else if ((y==2) && (x==24) ) pixel = 125;
            else if ((y==2) && (x==23) ) pixel = 115;
            else if ((y==2) && (x==22) ) pixel = 105;
            else if ((y==2) && (x==21) ) pixel = 95;


            else if ((y==3) && (x==12)) pixel = 235;

            else if ((y==3) && (x==13)) pixel = 175;
            else if ((y==3) && (x==11)) pixel = 185;

            else if ((y==3) && (x==10)) pixel = 75;
            else if ((y==3) && (x==14)) pixel = 75;

            else if ((y==3) && (x==9) ) pixel = 15;
            else if ((y==3) && (x==15)) pixel = 15;

            else if ((y==3) && (x==0) ) pixel = 25;
            else if ((y==3) && (x==1) ) pixel = 35;
            else if ((y==3) && (x==2) ) pixel = 45;
            else if ((y==3) && (x==3) ) pixel = 55;

            else if ((y==3) && (x==24) ) pixel = 95;
            else if ((y==3) && (x==23) ) pixel = 85;
            else if ((y==3) && (x==22) ) pixel = 75;
            else if ((y==3) && (x==21) ) pixel = 65;


            else if ((y==4) && (x==12)) pixel = 215;

            else if ((y==4) && (x==13)) pixel = 155;
            else if ((y==4) && (x==11)) pixel = 145;

            else if ((y==4) && (x==10)) pixel = 45;
            else if ((y==4) && (x==14)) pixel = 45;

            else if ((y==4) && (x==9) ) pixel = 10;
            else if ((y==4) && (x==15)) pixel = 10;

            else if ((y==4) && (x==0) ) pixel = 15;
            else if ((y==4) && (x==1) ) pixel = 25;
            else if ((y==4) && (x==2) ) pixel = 35;
            else if ((y==4) && (x==3) ) pixel = 45;

            else if ((y==4) && (x==24) ) pixel = 85;
            else if ((y==4) && (x==23) ) pixel = 75;
            else if ((y==4) && (x==22) ) pixel = 65;
            else if ((y==4) && (x==21) ) pixel = 55;

            else pixel = 0;
            image_real.get_pixel(x, y);
            for (bcnt = 0; bcnt < (bc/8); bcnt++) begin
                image_new.set_pixel(idx, pixel[(bcnt*8) +: 8]);
                idx++;
            end
        end
    end

    image_new.fwrite_bmp("_25_25_8bit_deltapulse_v5_vs_5.bmp", bc, w, h);

    $stop;

end : sim_main




endmodule : bmp_io_tb
