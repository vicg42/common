module scaler_horisontal #(
    parameter WIDTH = 12,
    parameter TABLE_INPUT_WIDTH = 10
)(
    input clk,

    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    input [15:0] horisontal_scale_step,

    input [WIDTH-1:0] d_in,
    input dv_in,
    input hs_in,
    input vs_in,
    
    output reg [WIDTH-1:0] d_out = 0,
    output reg dv_out = 0,
    output reg hs_out = 0,
    output reg vs_out = 0
);
// -------------------------------------------------------------------------

reg [WIDTH-1:0] d_in_d0 = 0;
reg [WIDTH-1:0] d_in_d1 = 0;
reg [WIDTH-1:0] d_in_d2 = 0;
reg [WIDTH-1:0] d_in_d3 = 0;

reg [WIDTH-1:0] m0 = 0;
reg [WIDTH-1:0] m1 = 0;
reg [WIDTH-1:0] m2 = 0;
reg [WIDTH-1:0] m3 = 0;

localparam [15:0] PIXEL_STEP = 4096;

reg [23:0] input_cntr = 0;              // input pixels coordinate counter
reg [23:0] output_cntr = 0;             // output pixels coordinate counter

reg new_pixel = 0;
reg new_pixel_d = 0;
reg new_pixel_dd = 0;
reg line_start = 0;
reg new_line = 0;
reg new_line_d = 0;
reg new_line_dd = 0;
reg frame_start = 0;
reg new_frame = 0;
reg new_frame_d = 0;
reg new_frame_dd = 0;


always @(posedge clk) begin
    if (dv_in) begin
        d_in_d0 <= d_in;
        d_in_d1 <= d_in_d0;
        d_in_d2 <= d_in_d1;
        d_in_d3 <= d_in_d2;
        input_cntr <= input_cntr + PIXEL_STEP;
        if (hs_in) line_start <= 1;
        if (vs_in) frame_start <= 1;
    end
    new_pixel <= 0;
    new_line <= 0;
    new_frame <= 0;
    if (input_cntr > output_cntr) begin
        new_pixel <= 1;
        m0 <= d_in_d0;
        m1 <= d_in_d1;
        m2 <= d_in_d2;
        m3 <= (input_cntr <= (PIXEL_STEP*2))?1'b0: d_in_d3; // boundary check, needed only for step<1.0 (upsize)
        output_cntr <= output_cntr + horisontal_scale_step;
        if (line_start) begin
            line_start <= 0;
            new_line <= 1;
        end
        if (frame_start) begin
            frame_start <= 0;
            new_frame <= 1;
        end
    end
    if (dv_in && hs_in) begin
        input_cntr <= 0;
        output_cntr <= PIXEL_STEP;
    end
end

localparam COEFF_WIDTH = 10;

wire [COEFF_WIDTH-1:0] f0;
wire [COEFF_WIDTH-1:0] f1;
wire [COEFF_WIDTH-1:0] f2;
wire [COEFF_WIDTH-1:0] f3;

localparam [9:0] TABLE_INPUT_WIDTH_MASK = (10'h3FF << (10 - TABLE_INPUT_WIDTH)) & 10'h3FF;
cubic_table cubic_table(
    .clk(clk),
    .dx(output_cntr[2 +: 10] & TABLE_INPUT_WIDTH_MASK),
    .f0(f0),
    .f1(f1),
    .f2(f2),
    .f3(f3)
);

localparam MUL_WIDTH = COEFF_WIDTH + WIDTH;
localparam OVERFLOW_BIT = COEFF_WIDTH + WIDTH - 1;
localparam [MUL_WIDTH:0] MAX_OUTPUT = (1 << (WIDTH+COEFF_WIDTH)) - 1;
localparam [MUL_WIDTH:0] ROUND_ADDER = (1 << (COEFF_WIDTH-2));

(* mult_style = "block" *) reg [MUL_WIDTH-1:0] mul0;
(* mult_style = "block" *) reg [MUL_WIDTH-1:0] mul1;
(* mult_style = "block" *) reg [MUL_WIDTH-1:0] mul2;
(* mult_style = "block" *) reg [MUL_WIDTH-1:0] mul3;
reg signed [MUL_WIDTH+2-1:0] sum;

always @(posedge clk) begin
    mul0 <= f0 * m0;
    mul1 <= f1 * m1;
    mul2 <= f2 * m2;
    mul3 <= f3 * m3;

    sum <= mul1 + mul2 - mul0 - mul3 + ROUND_ADDER;
    if (new_pixel_dd) begin
        d_out <= sum[COEFF_WIDTH-1 +: WIDTH];
        if (sum[OVERFLOW_BIT]) d_out <= MAX_OUTPUT;
        if (sum < 0) d_out <= 0;
    end 

    // Align sync pulses
    new_pixel_d <= new_pixel;
    new_pixel_dd <= new_pixel_d;
    dv_out <= new_pixel_dd;

    new_line_d <= new_line;
    new_line_dd <= new_line_d;
    hs_out <= new_line_dd;

    new_frame_d <= new_frame;
    new_frame_dd <= new_frame_d;
    vs_out <= new_frame_dd;
end

endmodule
