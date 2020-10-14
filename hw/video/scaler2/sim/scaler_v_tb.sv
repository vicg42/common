`timescale 1ns / 1ps
`include "bmp_io.sv"

module scaler_v_tb #(
    parameter READ_IMG_FILE = "img_600x600_8bit.bmp", //"24x24_8bit_test1.bmp",
    parameter DE_I_PERIOD = 0, //0 - no empty cycles
                             //2 - 1 empty cycle per pixel
                             //4 - 3 empty cycle per pixel
                             //etc...
    parameter LINE_IN_SIZE_MAX = 1024,
    parameter LINE_OUT_SIZE = 600,
    parameter LINE_STEP = 4096,
    parameter PIXEL_WIDTH = 8,
    parameter V_SCALE = 1.00,
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
                di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH] = x+y+1;
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

logic [15:0] v_scale_line_size = LINE_OUT_SIZE;
logic [15:0] v_scale_step = V_SCALE*LINE_STEP;
scaler_v #(
    .LINE_IN_SIZE_MAX(LINE_IN_SIZE_MAX),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .SPARSE_OUTPUT(1)
) scaler_v_m (
    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    .v_scale_step(v_scale_step),
    .v_scale_line_size(v_scale_line_size),

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

reg [15:0] dbg_cnt_i = 0;
always @(posedge clk) begin
    if (hs_i) begin
        dbg_cnt_i <= 0;
    end else if (de_i) begin
        dbg_cnt_i <= dbg_cnt_i + 1;
    end
end

endmodule


// initial begin
// //     $dumpfile("icarus/scaler_v_tb.v.fst");
//     $dumpvars;
//     $dumpvars(0, scaler_v_m.buf0[0]);
//     $dumpvars(0, scaler_v_m.buf1[0]);
//     $dumpvars(0, scaler_v_m.buf2[0]);
//     $dumpvars(0, scaler_v_m.buf3[0]);
//     $dumpvars(0, scaler_v_m.buf4[0]);

//     #3_000_000;

//     $display("\007");
//     $finish;
// end

// localparam VIDEO_PIXEL_PERIOD = 6;
// localparam VIDEO_LINE_PERIOD = 756;
// localparam VIDEO_FRAME_PERIOD = 288;
// logic [7:0] pix_cntr = 0;
// logic [10:0] x_cntr = 0;
// logic [10:0] y_cntr = VIDEO_FRAME_PERIOD - 2;

// always @(posedge clk) begin
//     de_i <= 0;
//     hs_i <= 0;
//     vs_i <= 0;
//     pix_cntr <= pix_cntr + 1'b1;
//     if (pix_cntr == (VIDEO_PIXEL_PERIOD - 1)) begin
//         pix_cntr <= 0;
//         de_i <= 1;
//         x_cntr <= x_cntr + 1'b1;
//         if (x_cntr == (VIDEO_LINE_PERIOD - 1)) begin
//             x_cntr <= 0;
//             hs_i <= 1;
//             y_cntr <= y_cntr + 1'b1;
//             if (y_cntr == (VIDEO_FRAME_PERIOD - 1)) begin
//                 y_cntr <= 0;
//                 vs_i <= 1;
//             end
//         end
//     end
// end

// localparam BLACK = 12'h0;
// localparam WHITE = 12'hFFF;

// always @(posedge clk) begin
//     // di_i = y_cntr*100; // vertical gradient
//     di_i = x_cntr;//*10; // horisontal gradient
// end