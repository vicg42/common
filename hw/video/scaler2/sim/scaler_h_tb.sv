`timescale 1ns / 1ps
 module scaler_h_tb#(
    parameter H_SCALE = 1.33,//2.666666666666666;
    parameter PIXEL_STEP = 4096,
    parameter PIXEL_WIDTH = 8
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
    $dumpfile("icarus/scaler_h_tb.v.fst");
    $dumpvars;
    #10000;
    $display("\007");
end


localparam VIDEO_PIXEL_PERIOD = 4;
localparam VIDEO_LINE_PERIOD = 24;
localparam VIDEO_FRAME_PERIOD = 128;
logic [7:0] pix_cntr = 0;
logic [PIXEL_WIDTH-1:0] x_cntr = 0;
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
always @* begin
    di_i = x_cntr;//*100; // horisontal gradient
    // di_i = x_cntr == 50? WHITE: BLACK; // vertical line
    // di_i = x_cntr[6]? BLACK: WHITE; // vertical stripes
    // di_i = x_cntr == y_cntr? WHITE: BLACK; // diagonal line
end

logic [15:0] scale_step_h = H_SCALE*PIXEL_STEP;
scaler_h #(
    .PIXEL_STEP(PIXEL_STEP),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .TABLE_INPUT_WIDTH(10)
) scaler_h_m (
    .scale_step_h(scale_step_h),

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


reg [15:0] dbg_cnt_i = 0;
always @(posedge clk) begin
    if (hs_i && de_i) begin
        dbg_cnt_i <= 0;
    end else if (de_i) begin
        dbg_cnt_i <= dbg_cnt_i + 1;
    end
end

reg [15:0] dbg_cnt_o = 0;
always @(posedge clk) begin
    if (hs_o && de_o) begin
        dbg_cnt_o <= 0;
    end else if (de_o) begin
        dbg_cnt_o <= dbg_cnt_o + 1;
    end
end


endmodule
