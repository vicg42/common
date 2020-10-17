//-----------------------------------------------------------------------
// author : Viktor Golovachenko
//-----------------------------------------------------------------------
`timescale 1ns / 1ps
`include "bmp_io.sv"

module scaler_bilinear_tb #(
    parameter READ_IMG_FILE = "_24x24_8bit_diagonal1.bmp",//"img_600x600_8bit.bmp", //"_bayer_lighthouse.bmp",//"24x24_8bit_test1.bmp",
    parameter WRITE_IMG_FILE = "scaler_belinear_result.bmp",
    parameter DE_I_PERIOD = 0, //0 - no empty cycles
                             //2 - 1 empty cycle per pixel
                             //4 - 3 empty cycle per pixel
                             //etc...
    parameter SPARSE_OUT = 0, // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
    parameter LINE_IN_SIZE_MAX = 1024,
    parameter V_SCALE_INLINE_WIDTH = 17,
    parameter SCALE_STEP = 128,
    parameter PIXEL_WIDTH = 8,
    parameter SCALE_COE = 1.40, //scale down: SCALE_COE > 1.0; scale up: SCALE_COE < 1.0
    parameter COE_WIDTH = 8
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

wire [PIXEL_WIDTH-1:0] do_o_tmp;
wire de_o_tmp;
wire hs_o_tmp;
wire vs_o_tmp;

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
                di_i = image_real.get_pixel(x, y);
                // di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH] = x+1;
                // di_i[0 +: 4] = x+1;//y+
                // di_i[4 +: 4] = y;//
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
            #10; //delay between line
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

reg [15:0] dbg_cntx_i = 0;
reg [15:0] dbg_cntx_tmp = 0;
reg [15:0] dbg_cnty_i = 0;
always @(posedge clk) begin
    if (hs_i) begin
        dbg_cntx_tmp <= 0;
    end else if (de_i) begin
        dbg_cntx_tmp <= dbg_cntx_tmp + 1;
    end
    dbg_cntx_i <= dbg_cntx_tmp;

    if (hs_s && vs_s) begin
        dbg_cnty_i <= 0;
    end else if (hs_s) begin
        dbg_cnty_i <= dbg_cnty_i + 1;
    end
end

logic [15:0] h_scale_step = SCALE_COE*SCALE_STEP;
logic [15:0] v_scale_step = SCALE_COE*SCALE_STEP;
logic [15:0] v_scale_inline_size = V_SCALE_INLINE_WIDTH-1;
scaler #(
    .LINE_IN_SIZE_MAX(LINE_IN_SIZE_MAX),
    .SCALE_STEP(SCALE_STEP),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .SPARSE_OUT(SPARSE_OUT),
    .COE_WIDTH(COE_WIDTH)
) scaler_belinear_m (
    .reg_h_scale_step(h_scale_step),
    .reg_v_scale_step(v_scale_step),
    .reg_v_scale_inline_size(v_scale_inline_size),

    .di_i(di_i),//
    .de_i(de_i),//
    .hs_i(hs_i),//
    .vs_i(vs_i),//

    .do_o(do_o),
    .de_o(de_o),
    .hs_o(hs_o),
    .vs_o(vs_o),

    .clk(clk)
);

reg sr_hs_o = 0;
reg sr_vs_o = 0;
reg hs_ms = 1'b0;
reg vs_ms = 1'b0;
reg de_ms = 1'b0;
reg [PIXEL_WIDTH-1:0] do_ms = 0;
always @(posedge clk) begin
    sr_hs_o <= hs_o;
    sr_vs_o <= vs_o;
    hs_ms <= sr_hs_o & !hs_o;
    vs_ms <= !sr_vs_o & vs_o;
    de_ms <= de_o;
    do_ms <= do_o;
end

monitor # (
    .DATA_WIDTH(8),
    .WRITE_IMG_FILE(WRITE_IMG_FILE)
) monitor_m (
    .di_i(do_ms),
    .de_i(de_ms),
    .hs_i(hs_ms),
    .vs_i(vs_ms),
    .clk(clk)
);

endmodule : scaler_bilinear_tb
