`timescale 1ns / 1ps
module scaler_v_tb #(
    parameter READ_IMG_FILE = "img_600x600_8bit.bmp", //"24x24_8bit_test1.bmp",
    parameter DE_I_PERIOD = 0, //0 - no empty cycles
                             //2 - 1 empty cycle per pixel
                             //4 - 3 empty cycle per pixel
                             //etc...
    parameter V_SCALE = 1.00,
    parameter PIXEL_WIDTH = 8,
    parameter LINE_STEP = 4096,
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

initial begin
//     $dumpfile("icarus/scaler_v_tb.v.fst");
    $dumpvars;
    $dumpvars(0, scaler_v_m.buf0[0]);
    $dumpvars(0, scaler_v_m.buf1[0]);
    $dumpvars(0, scaler_v_m.buf2[0]);
    $dumpvars(0, scaler_v_m.buf3[0]);
    $dumpvars(0, scaler_v_m.buf4[0]);

    #3_000_000;

    $display("\007");
    $finish;
end

localparam VIDEO_PIXEL_PERIOD = 6;
localparam VIDEO_LINE_PERIOD = 756;
localparam VIDEO_FRAME_PERIOD = 288;
logic [7:0] pix_cntr = 0;
logic [10:0] x_cntr = 0;
logic [10:0] y_cntr = VIDEO_FRAME_PERIOD - 2;

always @(posedge clk) begin
    de_i <= 0;
    hs_i <= 0;
    vs_i <= 0;
    pix_cntr <= pix_cntr + 1'b1;
    if (pix_cntr == (VIDEO_PIXEL_PERIOD - 1)) begin
        pix_cntr <= 0;
        de_i <= 1;
        x_cntr <= x_cntr + 1'b1;
        if (x_cntr == (VIDEO_LINE_PERIOD - 1)) begin
            x_cntr <= 0;
            hs_i <= 1;
            y_cntr <= y_cntr + 1'b1;
            if (y_cntr == (VIDEO_FRAME_PERIOD - 1)) begin
                y_cntr <= 0;
                vs_i <= 1;
            end
        end
    end
end

localparam BLACK = 12'h0;
localparam WHITE = 12'hFFF;

always @(posedge clk) begin
    // di_i = y_cntr*100; // vertical gradient
    di_i = x_cntr;//*10; // horisontal gradient
end


logic [15:0] v_scale_line_size = 1100;
logic [15:0] v_scale_step = V_SCALE*LINE_STEP;
scaler_v #(
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .SPARSE_OUTPUT(1)
) scaler_v_m (
    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    .v_scale_step(v_scale_step),
    .v_scale_line_size(v_scale_line_size),

    .di_i(di_i),
    .de_i(de_i),
    .hs_i(hs_i),
    .vs_i(vs_i),

    .do_o(do_o),
    .de_o(de_o),
    .hs_o(hs_o),
    .vs_o(vs_o),

    .clk(clk)
);

endmodule
