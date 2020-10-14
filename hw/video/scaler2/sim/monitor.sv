//-----------------------------------------------------------------------
// author : Viktor Golovachenko
//------------------------------------------------------------------------
`timescale 1ns / 1ps
`include "bmp_io.sv"

module monitor # (
    parameter DATA_WIDTH = 8,
    parameter WRITE_IMG_FILE = "wrfile"
)(
    input [DATA_WIDTH-1:0] di_i,
    input       de_i,
    input       hs_i,
    input       vs_i,
    input       clk
);

BMP_IO img;

int data [2048*2048];
int data_size = 0;
int xcnt = 0;
int ycnt = 0;
int frcnt = 0;
string filename;
string strtmp;

initial begin

    img = new();

end

logic [$size(di_i)-1:0] di = 0;
logic de = 0;
logic hs = 0;
logic vs = 0;
logic frcnt = 0;
logic wen = 1'b0;
int   i;

always @ (posedge clk) begin
    di <= di_i;
    de <= de_i;
    hs <= hs_i;
    vs <= vs_i;

    if (vs_i) begin
        wen <= 1'b1;
    end

    if (wen) begin
        if (vs_i) begin
            //create file name
            $sformat(strtmp,"_tb_fr%02d", frcnt);
            filename = {WRITE_IMG_FILE, strtmp, ".bmp"};

            //allocated memary for video data
            img.set_pixel_array(data_size);

            //copy video data
            for (i = 0; i < data_size; i++) begin
                img.set_pixel(i, data[i]);
            end

            //write to file
            img.fwrite_bmp(filename, 8, xcnt, ycnt); //BMP file

            data_size <= 0;
            ycnt <= 0;
            frcnt++;
        end else if (hs) begin
            ycnt++;
        end

        if (hs_i) begin
            xcnt <= 0;
        end else if (de) begin
            data[data_size++] = di[0  +: 8];
            xcnt++;
        end
    end

end


endmodule : monitor
