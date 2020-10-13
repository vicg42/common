module scaler_v #(
    parameter WIDTH = 12,
    parameter SPARSE_OUTPUT = 2, // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
    parameter TABLE_INPUT_WIDTH = 10
)(
    input clk,

    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    input [15:0] vertical_scale_step,
    input [15:0] vertical_scale_line_size,

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
localparam MAX_LINE_SIZE = 1024;

localparam [15:0] LINE_STEP = 4096;

reg [23:0] input_cntr = 0;              // input pixels coordinate counter
reg [23:0] output_cntr = 0;             // output pixels coordinate counter

// Store buffers
reg [WIDTH-1:0] d_in_d = 0;
(* RAM_STYLE="BLOCK" *) reg [WIDTH-1:0] line_buffer_a[MAX_LINE_SIZE-1:0];
(* RAM_STYLE="BLOCK" *) reg [WIDTH-1:0] line_buffer_b[MAX_LINE_SIZE-1:0];
(* RAM_STYLE="BLOCK" *) reg [WIDTH-1:0] line_buffer_c[MAX_LINE_SIZE-1:0];
(* RAM_STYLE="BLOCK" *) reg [WIDTH-1:0] line_buffer_d[MAX_LINE_SIZE-1:0];
(* RAM_STYLE="BLOCK" *) reg [WIDTH-1:0] line_buffer_e[MAX_LINE_SIZE-1:0];

reg [2:0] line_buffer_write_selector = 0;
localparam BUFFER_A_SELECT = 0;
localparam BUFFER_B_SELECT = 1;
localparam BUFFER_C_SELECT = 2;
localparam BUFFER_D_SELECT = 3;
localparam BUFFER_E_SELECT = 4;

reg [15:0] line_buffer_write_cntr = 0;
reg [15:0] line_buffer_read_cntr = 0;
reg [9:0] delta_y = 0;

// Store input line process
always @(posedge clk) begin
    if (dv_in) begin
        d_in_d <= d_in;
        if (line_buffer_write_selector == BUFFER_A_SELECT) line_buffer_a[line_buffer_write_cntr] <= d_in_d;
        if (line_buffer_write_selector == BUFFER_B_SELECT) line_buffer_b[line_buffer_write_cntr] <= d_in_d;
        if (line_buffer_write_selector == BUFFER_C_SELECT) line_buffer_c[line_buffer_write_cntr] <= d_in_d;
        if (line_buffer_write_selector == BUFFER_D_SELECT) line_buffer_d[line_buffer_write_cntr] <= d_in_d;
        if (line_buffer_write_selector == BUFFER_E_SELECT) line_buffer_e[line_buffer_write_cntr] <= d_in_d;
        line_buffer_write_cntr <= line_buffer_write_cntr + 1'b1;
        if (hs_in) begin
            input_cntr <= input_cntr + LINE_STEP;
            line_buffer_write_cntr <= 0;
            if (line_buffer_write_selector == 4) begin
                line_buffer_write_selector <= 0;
            end else begin
                line_buffer_write_selector <= line_buffer_write_selector + 1'b1;
            end
        end
        if (vs_in) begin
            line_buffer_write_selector <= 0;
            input_cntr <= 0;
        end
    end
end


// Control FSM
localparam IDLE = 0;
localparam CALC_F_PARAMS_CYCLE = 1;
localparam LINE_GENERATE = 2;
reg [3:0] state = IDLE;
reg [3:0] sparse_cntr = 0;
reg dv_out_early = 0;

always @(posedge clk) begin
    dv_out_early <= 0;
    case (state)
        IDLE: begin
            if (input_cntr > output_cntr) begin
                delta_y <= output_cntr[2 +: 10];
                state <= CALC_F_PARAMS_CYCLE;
            end
        end
        CALC_F_PARAMS_CYCLE: begin
            state <= LINE_GENERATE;
            line_buffer_read_cntr <= 0;
            sparse_cntr <= 0;
        end
        LINE_GENERATE: begin
            sparse_cntr <= sparse_cntr + 1'b1;
            if (sparse_cntr == SPARSE_OUTPUT) begin
                sparse_cntr <= 0;
                dv_out_early <= 1;
                line_buffer_read_cntr <= line_buffer_read_cntr + 1'b1;
                if (line_buffer_read_cntr == vertical_scale_line_size) begin
                    output_cntr <= output_cntr + vertical_scale_step;
                    state <= IDLE;
                end
            end
        end
        default: state <= IDLE; // fsm recovery
    endcase
    if (dv_in && vs_in) output_cntr <= LINE_STEP*2;
end


// Cubic interpolation coeffs calculation
localparam COEFF_WIDTH = 10;
wire [COEFF_WIDTH-1:0] f0;
wire [COEFF_WIDTH-1:0] f1;
wire [COEFF_WIDTH-1:0] f2;
wire [COEFF_WIDTH-1:0] f3;

localparam [9:0] TABLE_INPUT_WIDTH_MASK = (10'h3FF << (10 - TABLE_INPUT_WIDTH)) & 10'h3FF;
cubic_table cubic_table(
    .clk(clk),
    .dx(delta_y & TABLE_INPUT_WIDTH_MASK),
    .f0(f0),
    .f1(f1),
    .f2(f2),
    .f3(f3)
);


// Memory read
reg [WIDTH-1:0] line_buffer_output_a;
reg [WIDTH-1:0] line_buffer_output_b;
reg [WIDTH-1:0] line_buffer_output_c;
reg [WIDTH-1:0] line_buffer_output_d;
reg [WIDTH-1:0] line_buffer_output_e;
always @(posedge clk) begin
    line_buffer_output_a <= line_buffer_a[line_buffer_read_cntr];
    line_buffer_output_b <= line_buffer_b[line_buffer_read_cntr];
    line_buffer_output_c <= line_buffer_c[line_buffer_read_cntr];
    line_buffer_output_d <= line_buffer_d[line_buffer_read_cntr];
    line_buffer_output_e <= line_buffer_e[line_buffer_read_cntr];
end


localparam MUL_WIDTH = COEFF_WIDTH + WIDTH;
localparam OVERFLOW_BIT = COEFF_WIDTH + WIDTH - 1;
localparam [MUL_WIDTH:0] MAX_OUTPUT = (1 << (WIDTH+COEFF_WIDTH)) - 1;
localparam [MUL_WIDTH:0] ROUND_ADDER = (1 << (COEFF_WIDTH-2));

reg [WIDTH-1:0] m0 = 0;
reg [WIDTH-1:0] m1 = 0;
reg [WIDTH-1:0] m2 = 0;
reg [WIDTH-1:0] m3 = 0;

(* mult_style = "block" *) reg [MUL_WIDTH-1:0] mul0;
(* mult_style = "block" *) reg [MUL_WIDTH-1:0] mul1;
(* mult_style = "block" *) reg [MUL_WIDTH-1:0] mul2;
(* mult_style = "block" *) reg [MUL_WIDTH-1:0] mul3;
reg signed [MUL_WIDTH+2-1:0] sum;

// Calculate output
always @(posedge clk) begin
    if (line_buffer_write_selector == BUFFER_A_SELECT) begin
        m3 <= line_buffer_output_b;
        m2 <= line_buffer_output_c;
        m1 <= line_buffer_output_d;
        m0 <= line_buffer_output_e;
    end
    if (line_buffer_write_selector == BUFFER_B_SELECT) begin
        m3 <= line_buffer_output_c;
        m2 <= line_buffer_output_d;
        m1 <= line_buffer_output_e;
        m0 <= line_buffer_output_a;
    end
    if (line_buffer_write_selector == BUFFER_C_SELECT) begin
        m3 <= line_buffer_output_d;
        m2 <= line_buffer_output_e;
        m1 <= line_buffer_output_a;
        m0 <= line_buffer_output_b;
    end
    if (line_buffer_write_selector == BUFFER_D_SELECT) begin
        m3 <= line_buffer_output_e;
        m2 <= line_buffer_output_a;
        m1 <= line_buffer_output_b;
        m0 <= line_buffer_output_c;
    end
    if (line_buffer_write_selector == BUFFER_E_SELECT) begin
        m3 <= line_buffer_output_a;
        m2 <= line_buffer_output_b;
        m1 <= line_buffer_output_c;
        m0 <= line_buffer_output_d;
    end
    if (input_cntr < (4*LINE_STEP)) m3 <= 0; // boundary effect elimination

    mul0 <= f0 * m0;
    mul1 <= f1 * m1;
    mul2 <= f2 * m2;
    mul3 <= f3 * m3;

    sum <= mul1 + mul2 - mul0 - mul3 + ROUND_ADDER;

    d_out <= sum[COEFF_WIDTH-1 +: WIDTH];
    if (sum[OVERFLOW_BIT]) d_out <= MAX_OUTPUT;
    if (sum < 0) d_out <= 0;
end


// Align output strobes
reg dv_out_early_d = 0;
reg dv_out_early_dd = 0;
reg dv_out_early_ddd = 0;
reg hs_out_early = 0;
reg hs_out_early_d = 0;
reg hs_out_early_dd = 0;
reg hs_out_early_ddd = 0;
reg vs_out_early = 0;
reg vs_out_early_d = 0;
reg vs_out_early_dd = 0;
reg vs_out_early_ddd = 0;

always @(posedge clk) begin
    dv_out_early_d <= dv_out_early;
    dv_out_early_dd <= dv_out_early_d;
    dv_out_early_ddd <= dv_out_early_dd;
    dv_out <= dv_out_early_ddd;

    hs_out_early <= line_buffer_read_cntr == 0;
    hs_out_early_d <= hs_out_early;
    hs_out_early_dd <= hs_out_early_d;
    hs_out_early_ddd <= hs_out_early_dd;
    hs_out <= hs_out_early_ddd & dv_out_early_ddd;

    vs_out_early <= (output_cntr == LINE_STEP*2) && (line_buffer_read_cntr == 0);
    vs_out_early_d <= vs_out_early;
    vs_out_early_dd <= vs_out_early_d;
    vs_out_early_ddd <= vs_out_early_dd;
    vs_out <= vs_out_early_ddd & dv_out_early_ddd;
end

endmodule
