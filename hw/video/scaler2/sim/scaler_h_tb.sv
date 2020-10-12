`timescale 1ns / 1ps
module scaler_h_tb;

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


logic dv_in;
logic [11:0] d_in;
logic hs_in;
logic vs_in;

logic [11:0] d_out;
logic dv_out;
logic hs_out;
logic vs_out;

initial begin
    $dumpfile("icarus/scaler_h_tb.v.fst");
    $dumpvars;
    #10000;
    $display("\007");
end

//localparam VIDEO_PIXEL_PERIOD = 10;
//localparam VIDEO_LINE_PERIOD = 128;
//localparam VIDEO_FRAME_PERIOD = 128;

localparam VIDEO_PIXEL_PERIOD = 4;
localparam VIDEO_LINE_PERIOD = 24;
localparam VIDEO_FRAME_PERIOD = 128;
logic [7:0] pix_cntr = 0;
logic [10:0] x_cntr = 0;
logic [10:0] y_cntr = VIDEO_FRAME_PERIOD - 2;

always @(posedge clk) begin
    dv_in <= 0;
    hs_in <= 0;
    vs_in <= 0;
    pix_cntr <= pix_cntr + 1'b1;
    if (pix_cntr == (VIDEO_PIXEL_PERIOD - 1)) begin
        pix_cntr <= 0;
        dv_in <= 1;
        x_cntr <= x_cntr + 1'b1;
        if (x_cntr == (VIDEO_LINE_PERIOD - 1)) begin
            x_cntr <= 0;
            hs_in <= 1;
            y_cntr <= y_cntr + 1'b1;
            if (y_cntr == (VIDEO_FRAME_PERIOD - 1)) begin
                y_cntr <= 0;
                vs_in <= 1;
            end
        end
    end
end

localparam BLACK = 12'h0;
localparam WHITE = 12'hFFF;

always @* begin
    d_in = x_cntr*100; // horisontal gradient
    // d_in = x_cntr == 50? WHITE: BLACK; // vertical line
    // d_in = x_cntr[6]? BLACK: WHITE; // vertical stripes
    // d_in = x_cntr == y_cntr? WHITE: BLACK; // diagonal line
end


localparam PIXEL_STEP = 4096;
localparam real H_SCALE = 1.666666666666666;
logic [15:0] scale_step_h = H_SCALE*PIXEL_STEP;


scaler_h scaler_h (
    .scale_step_h(scale_step_h),

    .di_i(d_in ),
    .de_i(dv_in),
    .hs_i(hs_in),
    .vs_i(vs_in),

    .do_o(d_out ),
    .de_o(dv_out),
    .hs_o(hs_out),
    .vs_o(vs_out),

    .clk(clk)
);


reg [15:0] dbg_cnt_i = 0;
always @(posedge clk) begin
    if (hs_in && dv_in) begin
        dbg_cnt_i <= 0;
    end else if (dv_in) begin
        dbg_cnt_i <= dbg_cnt_i + 1;
    end
end

reg [15:0] dbg_cnt_o = 0;
always @(posedge clk) begin
    if (hs_out && dv_out) begin
        dbg_cnt_o <= 0;
    end else if (dv_out) begin
        dbg_cnt_o <= dbg_cnt_o + 1;
    end
end


endmodule
