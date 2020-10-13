module scaler_v #(
    parameter LINE_STEP = 4096,
    parameter PIXEL_WIDTH = 12,
    parameter SPARSE_OUTPUT = 2, // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
    parameter TABLE_INPUT_WIDTH = 10
)(
    input clk,

    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    input [15:0] vertical_scale_step,
    input [15:0] vertical_scale_line_size,

    input [PIXEL_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    output reg [PIXEL_WIDTH-1:0] do_o = 0,
    output reg de_o = 0,
    output reg hs_o = 0,
    output reg vs_o = 0
);
// -------------------------------------------------------------------------
localparam MAX_LINE_SIZE = 1024;

reg [23:0] cnt_i = 0; // input pixels coordinate counter
reg [23:0] cnt_o = 0; // output pixels coordinate counter

// Store buffers
reg [PIXEL_WIDTH-1:0] sr_di_i = 0;
(* RAM_STYLE="BLOCK" *) reg [PIXEL_WIDTH-1:0] buf0[MAX_LINE_SIZE-1:0];
(* RAM_STYLE="BLOCK" *) reg [PIXEL_WIDTH-1:0] buf1[MAX_LINE_SIZE-1:0];
(* RAM_STYLE="BLOCK" *) reg [PIXEL_WIDTH-1:0] buf2[MAX_LINE_SIZE-1:0];
(* RAM_STYLE="BLOCK" *) reg [PIXEL_WIDTH-1:0] buf3[MAX_LINE_SIZE-1:0];
(* RAM_STYLE="BLOCK" *) reg [PIXEL_WIDTH-1:0] buf4[MAX_LINE_SIZE-1:0];

reg [2:0] buf_wsel = 0;
localparam BUF0_NUM = 0;
localparam BUF1_NUM = 1;
localparam BUF2_NUM = 2;
localparam BUF3_NUM = 3;
localparam BUF4_NUM = 4;

reg [15:0] buf_wcnt = 0;
reg [15:0] buf_rcnt = 0;
reg [9:0] delta_y = 0;

// Store input line process
always @(posedge clk) begin
    if (de_i) begin
        sr_di_i <= di_i;
        if (buf_wsel == BUF0_NUM) buf0[buf_wcnt] <= sr_di_i;
        if (buf_wsel == BUF1_NUM) buf1[buf_wcnt] <= sr_di_i;
        if (buf_wsel == BUF2_NUM) buf2[buf_wcnt] <= sr_di_i;
        if (buf_wsel == BUF3_NUM) buf3[buf_wcnt] <= sr_di_i;
        if (buf_wsel == BUF4_NUM) buf4[buf_wcnt] <= sr_di_i;
        buf_wcnt <= buf_wcnt + 1'b1;
        if (hs_i) begin
            cnt_i <= cnt_i + LINE_STEP;
            buf_wcnt <= 0;
            if (buf_wsel == 4) begin
                buf_wsel <= 0;
            end else begin
                buf_wsel <= buf_wsel + 1'b1;
            end
        end
        if (vs_i) begin
            buf_wsel <= 0;
            cnt_i <= 0;
        end
    end
end


// Control FSM
localparam IDLE = 0;
localparam CALC_F_PARAMS_CYCLE = 1;
localparam LINE_GENERATE = 2;
reg [3:0] state = IDLE;
reg [3:0] cnt_sparse = 0;
reg dv_out_early = 0;

always @(posedge clk) begin
    dv_out_early <= 0;
    case (state)
        IDLE: begin
            if (cnt_i > cnt_o) begin
                delta_y <= cnt_o[2 +: 10];
                state <= CALC_F_PARAMS_CYCLE;
            end
        end
        CALC_F_PARAMS_CYCLE: begin
            state <= LINE_GENERATE;
            buf_rcnt <= 0;
            cnt_sparse <= 0;
        end
        LINE_GENERATE: begin
            cnt_sparse <= cnt_sparse + 1'b1;
            if (cnt_sparse == SPARSE_OUTPUT) begin
                cnt_sparse <= 0;
                dv_out_early <= 1;
                buf_rcnt <= buf_rcnt + 1'b1;
                if (buf_rcnt == vertical_scale_line_size) begin
                    cnt_o <= cnt_o + vertical_scale_step;
                    state <= IDLE;
                end
            end
        end
        default: state <= IDLE; // fsm recovery
    endcase
    if (de_i && vs_i) begin
        cnt_o <= LINE_STEP*2;
    end
end


// Cubic interpolation coeffs calculation
localparam COEFF_WIDTH = 10;
wire [COEFF_WIDTH-1:0] coe [3:0];

localparam [9:0] TABLE_INPUT_WIDTH_MASK = (10'h3FF << (10 - TABLE_INPUT_WIDTH)) & 10'h3FF;
cubic_table cubic_table(
    .f0(coe[0]),
    .f1(coe[1]),
    .f2(coe[2]),
    .f3(coe[3]),

    .dx(delta_y & TABLE_INPUT_WIDTH_MASK),
    .clk(clk)
);


// Memory read
reg [PIXEL_WIDTH-1:0] buf0_do;
reg [PIXEL_WIDTH-1:0] buf1_do;
reg [PIXEL_WIDTH-1:0] buf2_do;
reg [PIXEL_WIDTH-1:0] buf3_do;
reg [PIXEL_WIDTH-1:0] buf4_do;
always @(posedge clk) begin
    buf0_do <= buf0[buf_rcnt];
    buf1_do <= buf1[buf_rcnt];
    buf2_do <= buf2[buf_rcnt];
    buf3_do <= buf3[buf_rcnt];
    buf4_do <= buf4[buf_rcnt];
end


localparam MUL_WIDTH = COEFF_WIDTH + PIXEL_WIDTH;
localparam OVERFLOW_BIT = COEFF_WIDTH + PIXEL_WIDTH - 1;
localparam [MUL_WIDTH:0] MAX_OUTPUT = (1 << (PIXEL_WIDTH+COEFF_WIDTH)) - 1;
localparam [MUL_WIDTH:0] ROUND_ADDER = (1 << (COEFF_WIDTH-2));

reg [PIXEL_WIDTH-1:0] m [3:0];

(* mult_style = "block" *) reg [MUL_WIDTH-1:0] mult [3:0];
reg signed [MUL_WIDTH+2-1:0] sum;

// Calculate output
always @(posedge clk) begin
    if (buf_wsel == BUF0_NUM) begin
        m[3] <= buf1_do;
        m[2] <= buf2_do;
        m[1] <= buf3_do;
        m[0] <= buf4_do;
    end
    if (buf_wsel == BUF1_NUM) begin
        m[3] <= buf2_do;
        m[2] <= buf3_do;
        m[1] <= buf4_do;
        m[0] <= buf0_do;
    end
    if (buf_wsel == BUF2_NUM) begin
        m[3] <= buf3_do;
        m[2] <= buf4_do;
        m[1] <= buf0_do;
        m[0] <= buf1_do;
    end
    if (buf_wsel == BUF3_NUM) begin
        m[3] <= buf4_do;
        m[2] <= buf0_do;
        m[1] <= buf1_do;
        m[0] <= buf2_do;
    end
    if (buf_wsel == BUF4_NUM) begin
        m[3] <= buf0_do;
        m[2] <= buf1_do;
        m[1] <= buf2_do;
        m[0] <= buf3_do;
    end
    if (cnt_i < (4*LINE_STEP)) m[3] <= 0; // boundary effect elimination

    mult[0] <= coe[0] * m[0];
    mult[1] <= coe[1] * m[1];
    mult[2] <= coe[2] * m[2];
    mult[3] <= coe[3] * m[3];

    sum <= mult[1] + mult[2] - mult[0] - mult[3] + ROUND_ADDER;

    do_o <= sum[COEFF_WIDTH-1 +: PIXEL_WIDTH];
    if (sum[OVERFLOW_BIT]) do_o <= MAX_OUTPUT;
    if (sum < 0) do_o <= 0;
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
    de_o <= dv_out_early_ddd;

    hs_out_early <= buf_rcnt == 0;
    hs_out_early_d <= hs_out_early;
    hs_out_early_dd <= hs_out_early_d;
    hs_out_early_ddd <= hs_out_early_dd;
    hs_o <= hs_out_early_ddd & dv_out_early_ddd;

    vs_out_early <= (cnt_o == LINE_STEP*2) && (buf_rcnt == 0);
    vs_out_early_d <= vs_out_early;
    vs_out_early_dd <= vs_out_early_d;
    vs_out_early_ddd <= vs_out_early_dd;
    vs_o <= vs_out_early_ddd & dv_out_early_ddd;
end

endmodule
