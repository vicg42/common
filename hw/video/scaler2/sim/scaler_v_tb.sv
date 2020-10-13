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

logic dv_in;
logic [11:0] d_in;
logic hs_in;
logic vs_in;

logic [11:0] d_out;
logic dv_out;
logic hs_out;
logic vs_out;

// initial begin
//     $dumpfile("icarus/scaler_v_tb.v.fst");
//     $dumpvars;
//     $dumpvars(0, scaler_v.line_buffer_a[0]);
//     $dumpvars(0, scaler_v.line_buffer_b[0]);
//     $dumpvars(0, scaler_v.line_buffer_c[0]);
//     $dumpvars(0, scaler_v.line_buffer_d[0]);
//     $dumpvars(0, scaler_v.line_buffer_e[0]);

//     #3_000_000;

//     $display("\007");
//     $finish;
// end

localparam VIDEO_PIXEL_PERIOD = 6;
localparam VIDEO_LINE_PERIOD = 756;
localparam VIDEO_FRAME_PERIOD = 288;
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
    // d_in = y_cntr*100; // vertical gradient
    d_in = x_cntr;//*10; // horisontal gradient
end

// localparam LINE_STEP = 4096;
// localparam real VERTICAL_SCALE = 0.5;
logic [15:0] scale_step_v = V_SCALE*LINE_STEP;
logic [15:0] vertical_scale_line_size = 1100;

scaler_v #(
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .SPARSE_OUTPUT(1)
) scaler_v_m (
    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    .scale_step_v(scale_step_v),
    .vertical_scale_line_size(vertical_scale_line_size),

    .di_i(d_in ),
    .de_i(dv_in),
    .hs_i(hs_in),
    .vs_i(vs_in),

    .do_o(d_out  ),
    .de_o(dv_out ),
    .hs_o(hs_out ),
    .vs_o(vs_out ),

    .clk(clk)
);

endmodule
