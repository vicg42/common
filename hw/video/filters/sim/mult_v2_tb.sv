//-----------------------------------------------------------------------
//
// author    : Golovachenko Victor
//
//------------------------------------------------------------------------
`timescale 1ns / 1ps

`include "bmp_io.sv"

module mult_v2_tb # (
    parameter READ_IMG_FILE = "img_600x600_8bit_noise.bmp", //"24x24_8bit_test1.bmp",
    parameter WRITE_IMG_FILE = "mult_v2_tb",

    parameter DE_I_PERIOD = 2, //0 - no empty cycles
                             //2 - 1 empty cycle per pixel
                             //4 - 3 empty cycle per pixel
                             //etc...
    parameter LINE_SIZE_MAX = 4096,
    parameter COE_WIDTH = 16,
    parameter COE_COUNT = 9,
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

int   di [2:0];
logic de_i;
logic hs_i;
logic vs_i;

localparam FRAME_COUNT = 2;
int fr;


logic [(PIXEL_WIDTH*3)-1:0] do_o;
logic de_o;
logic hs_o;
logic vs_o;

wire [(PIXEL_WIDTH*3)-1:0] s0_do;
wire s0_de;
wire s0_hs;
wire s0_vs;

//***********************************
//System clock gen
//***********************************
localparam CLK_PERIOD = 8; //8 - 126MHz; 16 - 62.5MHz
reg clk = 1'b1;
always #(CLK_PERIOD/2) clk = ~clk;

int c0,c1;
int coe [COE_COUNT-1:0];
real r_num [COE_COUNT-1:0];
integer r_num_int;
real r_num_frac;

initial begin : sim_main
    for (c0=0;c0<COE_COUNT;c0++) begin
        coe[c0] = 0;
    end

    for (c0=0;c0<3;c0++) begin
        di[c0] = 0;
    end

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
    // di = 0;
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
                // r_num[0] = -1.00;
                // r_num[1] = -1.00;
                // r_num[2] = 1.00;
                for (c0=0;c0<3;c0++) begin
                    //ganerate random real numbers
                    for (c1=0;c1<3;c1++) begin
                        r_num_int = $random;
                        r_num_frac = ($urandom%1000)/10000.0;
                        r_num[(3*c0) + c1] = $signed(r_num_int[3:0]) + r_num_frac;
                        coe[(3*c0) + c1] = r_num[(3*c0) + c1] * 1024;
                        $display("coe[%02d]: %04.5f; %d(dec); %x(hex)", (3*c0) + c1
                                                                        , r_num[(3*c0) + c1]
                                                                        , coe[(3*c0) + c1][13:0]
                                                                        , coe[(3*c0) + c1][13:0]);
                    end

                    di[c0] = $urandom_range(255,0);//46;//255;//
                    $display("x[%05d]:di_i[%02d]: %d(dec); %x(hex)", x, c0, di[c0], di[c0]);
                    $display("x[%05d]:do[%02d]: %f", x, c0, ((di[c0]*r_num[(3*c0)+0]) +
                                                            (di[c0]*r_num[(3*c0)+1]) +
                                                            (di[c0]*r_num[(3*c0)+2])) );
                end
                $display("\n");

//                di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH] = x;
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

logic [(COE_WIDTH*COE_COUNT)-1:0] coe_i;
genvar k0;
generate
    for (k0=0; k0<COE_COUNT; k0=k0+1) begin
        assign coe_i[(k0*COE_WIDTH) +: COE_WIDTH] = coe[k0][COE_WIDTH-1:0];
    end
endgenerate

logic [(PIXEL_WIDTH*3)-1:0] di_i;
genvar k1;
generate
    for (k1=0; k1<3; k1++) begin
        assign di_i[(k1*PIXEL_WIDTH) +: PIXEL_WIDTH] = di[k1][PIXEL_WIDTH-1:0];
    end
endgenerate

mult_v2 #(
    .COE_WIDTH(COE_WIDTH), //(Q4.10) signed fixed point. 1024(0x400) is 1.000
    .COE_COUNT(COE_COUNT),
    .PIXEL_WIDTH (PIXEL_WIDTH)
) mult (
    .coe_i(coe_i),

    .di_i(di_i),
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


// monitor # (
//     .DATA_WIDTH (PIXEL_WIDTH),
//     .WRITE_IMG_FILE(WRITE_IMG_FILE)
// ) monitor (
//     .di_i(do_o),
//     .de_i(de_o),
//     .hs_i(hs_o),
//     .vs_i(vs_o),
//     .clk (clk)
// );

endmodule
