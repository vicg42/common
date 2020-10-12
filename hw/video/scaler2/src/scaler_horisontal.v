module scaler_h #(
    parameter PIX_WIDTH = 12,
    parameter TABLE_INPUT_WIDTH = 10
)(
    input clk,

    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    input [15:0] scale_step_h,

    input [PIX_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    output reg [PIX_WIDTH-1:0] do_o = 0,
    output reg de_o = 0,
    output reg hs_o = 0,
    output reg vs_o = 0
);
// -------------------------------------------------------------------------

reg [PIX_WIDTH-1:0] sr_di_i[3:0];

reg [PIX_WIDTH-1:0] m0 = 0;
reg [PIX_WIDTH-1:0] m1 = 0;
reg [PIX_WIDTH-1:0] m2 = 0;
reg [PIX_WIDTH-1:0] m3 = 0;

localparam [15:0] PIXEL_STEP = 4096;

reg [23:0] cnt_i = 0;              // input pixels coordinate counter
reg [23:0] cnt_o = 0;             // output pixels coordinate counter

reg new_pix = 0;
reg [1:0] sr_new_pix = 0;
reg line_start = 0;
reg new_line = 0;
reg [1:0] sr_new_line = 0;
reg sof = 0;
reg new_fr = 0;
reg [1:0] sr_new_fr = 0;

always @(posedge clk) begin
    if (de_i) begin
        sr_di_i[0] <= di_i;
        sr_di_i[1] <= sr_di_i[0];
        sr_di_i[2] <= sr_di_i[1];
        sr_di_i[3] <= sr_di_i[2];
        cnt_i <= cnt_i + PIXEL_STEP;
        if (hs_i) line_start <= 1;
        if (vs_i) sof <= 1;
    end
    new_pix <= 0;
    new_line <= 0;
    new_fr <= 0;
    if (cnt_i > cnt_o) begin
        new_pix <= 1;
        m0 <= sr_di_i[0];
        m1 <= sr_di_i[1];
        m2 <= sr_di_i[2];
        m3 <= (cnt_i <= (PIXEL_STEP*2)) ? 1'b0 : sr_di_i[3]; // boundary check, needed only for step<1.0 (upsize)
        cnt_o <= cnt_o + scale_step_h;
        if (line_start) begin
            line_start <= 0;
            new_line <= 1;
        end
        if (sof) begin
            sof <= 0;
            new_fr <= 1;
        end
    end
    if (de_i && hs_i) begin
        cnt_i <= 0;
        cnt_o <= PIXEL_STEP;
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
    .dx(cnt_o[2 +: 10] & TABLE_INPUT_WIDTH_MASK),
    .f0(f0),
    .f1(f1),
    .f2(f2),
    .f3(f3)
);

localparam MUL_WIDTH = COEFF_WIDTH + PIX_WIDTH;
localparam OVERFLOW_BIT = COEFF_WIDTH + PIX_WIDTH - 1;
localparam [MUL_WIDTH:0] MAX_OUTPUT = (1 << (PIX_WIDTH+COEFF_WIDTH)) - 1;
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
    if (sr_new_pix[1]) begin
        do_o <= sum[COEFF_WIDTH-1 +: PIX_WIDTH];
        if (sum[OVERFLOW_BIT]) do_o <= MAX_OUTPUT;
        if (sum < 0) do_o <= 0;
    end

    // Align sync pulses
    sr_new_pix[0] <= new_pix;
    sr_new_pix[1] <= sr_new_pix[0];
    de_o <= sr_new_pix[1];

    sr_new_line[0] <= new_line;
    sr_new_line[1] <= sr_new_line[0];
    hs_o <= sr_new_line[1];

    sr_new_fr[0] <= new_fr;
    sr_new_fr[1] <= sr_new_fr[0];
    vs_o <= sr_new_fr[1];
end

endmodule
