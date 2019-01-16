//-----------------------------------------------------------------------
//
// Engineer    : Golovachenko Victor
//
//------------------------------------------------------------------------
`timescale 1ns / 1ps

`include "bmp_io.sv"

module monitor # (
    parameter DATA_WIDTH = 8,
    parameter WRITE_IMG_FILE = "wrfile"
)(
    //parallel video interface
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

//***********************************
//DBG Parallel Video Monitor
//***********************************
logic [$size(di_i)-1:0]  sr_di_i = 0;
logic        sr_de_i  = 1'b0;
logic [1:0]  sr_hs_i  = 2'd0;
logic [1:0]  sr_vs_i  = 2'd0;
logic        result_en = 1'b0;
int        i;

always @ (posedge clk) begin
    sr_di_i <= di_i;
    sr_de_i <= de_i;
    sr_hs_i <= {sr_hs_i[0:0], hs_i};
    sr_vs_i <= {sr_vs_i[0:0], vs_i};

    if (!sr_vs_i[0] & vs_i) begin //rising edge
        result_en <= 1'b1;
    end

    if (sr_vs_i[1] & (!sr_vs_i[0])) begin //falling edge

        if (result_en) begin
            if (frcnt < 4) begin

                //create file name
                $sformat(strtmp,"_tb_edge_dbg_fr%02d", frcnt);
                filename = {WRITE_IMG_FILE, strtmp, ".bmp"};

                //allocated memary for video data
                img.set_pixel_array(data_size);

                //copy video data
                for (i = 0; i < data_size; i++) begin
                  img.set_pixel(i, data[i]);
                end

                //write to file
                img.fwrite_bmp(filename, 8, xcnt, ycnt); //BMP file

//                //create file name
//                $sformat(strtmp,"_tb_edge_dbg_fr%02d", frcnt);
//                filename = {WRITE_IMG_FILE, strtmp, ".bmp"};
//
//                //allocated memary for video data
//                img.set_pixel_array(data_size);
//
//                //copy video data
//                for (i = 0; i < data_size; i++) begin
//                  img.set_pixel(i, data[i]);
//                end
//
//                //write to file
//                img.fwrite_bmp(filename, 24, xcnt, ycnt); //BMP file
//


//                //create file name
//                $sformat(strtmp,"_tb_edge_dbg_fr%02d", frcnt);
//                filename = {WRITE_IMG_FILE, strtmp, ".raw"};
//
//                //allocated memary for video data
//                img.set_pixel_array(data_size);
//
//                //copy video data
//                for (i = 0; i < data_size; i++) begin
//                    img.set_pixel(i, data[i]);
//                end
//
//                //write to file
//                if ((data_size/ycnt/3) != xcnt) begin
//                    $display("\t Error: before write to %s", filename);
//                    $stop;
//                end
//                img.fwrite_raw(filename, 24, (data_size/ycnt), ycnt); //RAW file YCbCr444


//                //create file name
//                $sformat(strtmp,"_tb_edge_dbg_fr%02d", frcnt);
//                filename = {WRITE_IMG_FILE, strtmp, ".raw"};
//
//                //allocated memary for video data
//                img.set_pixel_array(data_size);
//
//                //copy video data
//                for (i = 0; i < data_size; i++) begin
//                    img.set_pixel(i, data[i]);
//                end
//
//                //write to file
//                if ((data_size/ycnt/3) != xcnt) begin
//                    $display("\t Error: before write to %s", filename);
//                    $stop;
//                end
//                img.fwrite_raw(filename, 16, xcnt, ycnt); //RAW file YCbCr422
            end

            frcnt++;
        end

        xcnt <= 0; ycnt <= 0; data_size <= 0;

    end else begin
        if ((sr_hs_i[0]) & (!hs_i)) begin //rising edge
            xcnt <= 0; ycnt++;
        end
        if (!sr_hs_i[0]) begin
            if (sr_de_i) begin
////BMP file
//                data[data_size++] = sr_di_i[16 +: 8];
//                data[data_size++] = sr_di_i[8  +: 8];
//                data[data_size++] = sr_di_i[0  +: 8];

                data[data_size++] = sr_di_i[0  +: 8];

////RAW file YCbCr444
//                data[data_size++] = sr_di_i[0  +: 8];
//                data[data_size++] = sr_di_i[8  +: 8];
//                data[data_size++] = sr_di_i[16 +: 8];

////RAW file YCbCr422
//                data[data_size++] = sr_di_i[0  +: 8];
//                data[data_size++] = sr_di_i[8  +: 8];

//Pixel counter
                xcnt++;
            end
        end
    end
end


endmodule : monitor
