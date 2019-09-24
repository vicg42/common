//-----------------------------------------------------------------------
//
// Engineer    : Golovachenko Victor
//
//------------------------------------------------------------------------
`timescale 1ns / 1ps

`include "bmp_io.sv"

module scaler_v_tb # (
//    parameter READ_IMG_FILE = "img_600x600_8bit.bmp",
    parameter READ_IMG_FILE = "_25_25_8bit_deltapulse_v4_vs.bmp",
    parameter WRITE_IMG_FILE = "scaler_v_tb",

    parameter STEP = 4096,
    parameter real SCALE_FACTOR = 0.5,
    parameter SCALE_LINE_SIZE = 50-1,
    // (4.12) unsigned fixed point. 4096 is 1.000 scale

    parameter DE_I_PERIOD = 4, //0 - no empty cycles
                             //2 - 1 empty cycle per pixel
                             //4 - 3 empty cycle per pixel
                             //etc...
    parameter LINE_SIZE_MAX = 53,
    parameter COE_WIDTH = 10,
    parameter PIXEL_WIDTH = 8
)();

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

logic rst;

int   di_i;
logic de_i;
logic hs_i;
logic vs_i;

localparam FRAME_COUNT = 2;
int fr;

logic [PIXEL_WIDTH-1:0] scaler_h_do_o;
logic scaler_h_de_o;
logic scaler_h_hs_o;
logic scaler_h_vs_o;

logic [PIXEL_WIDTH-1:0] do_o;
logic de_o;
logic hs_o;
logic vs_o;

wire [PIXEL_WIDTH-1:0] s0_do;
wire s0_de;
wire s0_hs;
wire s0_vs;

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
    vs_i = 1'b1;

    image_real = new();
    image_real.fread_bmp(READ_IMG_FILE);
    w = image_real.get_x();
    h = image_real.get_y();
    bc = image_real.get_ColortBitCount();
    $display("read frame: %d x %d; BItCount %d", w, h, bc);

    rst = 0;
    @(posedge clk);
    rst = 1;
    @(posedge clk);
    rst = 0;
    fr = 0;
    di_i = 0;
    de_i = 0;
    hs_i = 1'b1;
    vs_i = 1'b1;
    #500;
    #500;
    for (fr = 0; fr < FRAME_COUNT; fr++) begin
        for (y = 0; y < h; y++) begin
            for (x = 0; x < w; x++) begin
                @(posedge clk);
                di_i = image_real.get_pixel(x, y); //di_i + 1;//
//                di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH] = x;
                //for color image:
                //di_i[0  +: 8] - B
                //di_i[8  +: 8] - G
                //di_i[16 +: 8] - R
                if (DE_I_PERIOD == 0) begin
                    de_i = 1'b1;
                    hs_i = 1'b0;
                    vs_i = 1'b0;
                end else if (DE_I_PERIOD == 2) begin
                    de_i = 1'b0;
                    hs_i = 1'b0;
                    vs_i = 1'b0;
                    @(posedge clk);
                    de_i = 1'b1;
                end else if (DE_I_PERIOD == 4) begin
                    de_i = 1'b0;
                    hs_i = 1'b0;
                    vs_i = 1'b0;
                    @(posedge clk);
                    de_i = 1'b0;
                    hs_i = 1'b0;
                    vs_i = 1'b0;
                    @(posedge clk);
                    de_i = 1'b0;
                    hs_i = 1'b0;
                    vs_i = 1'b0;
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
                vs_i = 1'b1;
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

logic [15:0] dbg_cnt_i = 0;
always @(posedge clk) begin
    if (hs_i) begin
        dbg_cnt_i <= 0;
    end else if (de_i) begin
        dbg_cnt_i <= dbg_cnt_i + 1;
    end
end


// (4.12) unsigned fixed point. 4096 is 1.000 scale
logic [15:0] scale_step = SCALE_FACTOR * STEP;

scaler_v #(
    .SPARSE_OUTPUT(0), // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
    .COE_WIDTH(COE_WIDTH),
    .LINE_SIZE_MAX(LINE_SIZE_MAX),
    .LINE_STEP (STEP),
    .DATA_WIDTH (PIXEL_WIDTH)
) scaler_v (
    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    .scale_step(scale_step),
    .scale_line_size(SCALE_LINE_SIZE),

    .di_i(di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH]),
    .de_i(de_i),
    .hs_i(hs_i),
    .vs_i(vs_i),

    .do_o(do_o),
    .de_o(de_o),
    .hs_o(hs_o),
    .vs_o(vs_o),

    .clk(clk),
    .rst(rst)
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

logic [15:0] dbg_cnt_o = 0;
always @(posedge clk) begin
    if (hs_o) begin
        dbg_cnt_o <= 0;
    end else if (de_o) begin
        dbg_cnt_o <= dbg_cnt_o + 1;
    end
end



endmodule
