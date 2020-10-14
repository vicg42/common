//-----------------------------------------------------------------------
// author : Viktor Golovachenko
//-----------------------------------------------------------------------
`timescale 1ns / 1ps
`include "bmp_io.sv"

module scaler_v_tb #(
    parameter READ_IMG_FILE = "_bayer_lighthouse.bmp",//"img_600x600_8bit.bmp", //"24x24_8bit_test1.bmp",
    parameter DE_I_PERIOD = 0, //0 - no empty cycles
                             //2 - 1 empty cycle per pixel
                             //4 - 3 empty cycle per pixel
                             //etc...
    parameter SPARSE_OUT = 0, // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
    parameter LINE_IN_SIZE_MAX = 1024,
    parameter READ_IMG_WIDTH = 255,
    parameter LINE_STEP = 4096,
    parameter PIXEL_WIDTH = 8,
    parameter SCALE_COE = 2.00, //scale down: SCALE_COE > 1.0; scale up: SCALE_COE < 1.0
    parameter COE_WIDTH = 10
);

reg clk = 1;
always #0.5 clk = ~clk;
task tick;
    begin
        @(posedge clk);#0;
    end
endtask

initial begin
    forever begin
        #100000;
        $display("%d us", $time/1000);
    end
end

logic [PIXEL_WIDTH-1:0] di_i;
logic de_i;
logic hs_i;
logic vs_i;

logic [PIXEL_WIDTH-1:0] do_o;
logic de_o;
logic hs_o;
logic vs_o;

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

localparam FRAME_COUNT = 2;
int fr;

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
//                di_i = image_real.get_pixel(x, y);
                di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH] = x+1;//y+
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

reg sr_hs_i = 0;
reg sr_vs_i = 0;
reg hs_s = 1'b0;
reg vs_s = 1'b0;
reg de_s = 1'b0;
reg [PIXEL_WIDTH-1:0] di_s = 0;
always @(posedge clk) begin
    sr_hs_i <= hs_i;
    sr_vs_i <= vs_i;
    hs_s <= sr_hs_i & !hs_i;
    vs_s <= !sr_vs_i & vs_i;
    de_s <= de_i;
    di_s <= di_i;
end

logic [15:0] line_in_size = READ_IMG_WIDTH;
logic [15:0] v_scale_step = SCALE_COE*LINE_STEP;
scaler_v #(
    .LINE_IN_SIZE_MAX(LINE_IN_SIZE_MAX),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .SPARSE_OUT(SPARSE_OUT)
) scaler_v_m (
    .line_in_size(line_in_size),
    .scale_step(v_scale_step),

    .di_i(di_s),
    .de_i(de_s),
    .hs_i(hs_s),
    .vs_i(vs_s),

    .do_o(do_o),
    .de_o(de_o),
    .hs_o(hs_o),
    .vs_o(vs_o),

    .clk(clk)
);

reg [15:0] dbg_cntx_i_tmp = 0;
reg [15:0] dbg_cntx_i = 0;
reg [15:0] dbg_cnty_i = 0;
always @(posedge clk) begin
    if (hs_i) begin
        dbg_cntx_i_tmp <= 0;
    end else if (de_i) begin
        dbg_cntx_i_tmp <= dbg_cntx_i_tmp + 1;
    end
    dbg_cntx_i <= dbg_cntx_i_tmp;

    if (hs_s && vs_s) begin
        dbg_cnty_i <= 0;
    end else if (hs_s) begin
        dbg_cnty_i <= dbg_cnty_i + 1;
    end
end

reg [15:0] dbg_cntx_o = 0;
reg [15:0] dbg_cnty_o = 0;
always @(posedge clk) begin
    if (hs_o && de_o) begin
        dbg_cntx_o <= 0;
    end else if (de_o) begin
        dbg_cntx_o <= dbg_cntx_o + 1;
    end

    if (hs_o && vs_o) begin
        dbg_cnty_o <= 0;
    end else if (hs_o) begin
        dbg_cnty_o <= dbg_cnty_o + 1;
    end
end

endmodule
