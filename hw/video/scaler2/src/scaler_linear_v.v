module scaler_v #(
//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
    parameter VENDOR_RAM_STYLE="MLAB",
    parameter LINE_IN_SIZE_MAX = 1024,
    parameter LINE_STEP = 4096,
    parameter PIXEL_WIDTH = 12,
    parameter SPARSE_OUT = 2, // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
    parameter COE_WIDTH = 10
)(
    //unsigned fixed point. LINE_STEP is 1.000 scale
    input [15:0] scale_step,
    input [15:0] line_in_size,

    input [PIXEL_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    output reg [PIXEL_WIDTH-1:0] do_o = 0,
    output reg de_o = 0,
    output reg hs_o = 0,
    output reg vs_o = 0,

    input clk
);

localparam BUF0_NUM = 1'b0;
localparam BUF1_NUM = 1'b1;
localparam BUF2_NUM = 1'b1;

reg [23:0] cnt_i = 0; // input pixels coordinate counter
reg [23:0] cnt_o = 0; // output pixels coordinate counter

reg buf_wsel = 1'b0;
reg [15:0] buf_wcnt = 0;
reg [15:0] buf_rcnt = 0;
always @(posedge clk) begin
    if (de_i) begin
        buf_wcnt <= buf_wcnt + 1'b1;
        if (hs_i) begin
            cnt_i <= cnt_i + LINE_STEP;
            buf_wcnt <= 0;
            if (buf_wsel == BUF2_NUM) begin
                buf_wsel <= 0;
            end else begin
                buf_wsel <= ~buf_wsel;
            end
        end
        if (vs_i) begin
            buf_wsel <= 0;
            cnt_i <= 0;
        end
    end
end

// Store input line
reg [PIXEL_WIDTH-1:0] sr_di_i = 0;
(* RAM_STYLE=VENDOR_RAM_STYLE *) reg [PIXEL_WIDTH-1:0] buf0[LINE_IN_SIZE_MAX-1:0];
(* RAM_STYLE=VENDOR_RAM_STYLE *) reg [PIXEL_WIDTH-1:0] buf1[LINE_IN_SIZE_MAX-1:0];
(* RAM_STYLE=VENDOR_RAM_STYLE *) reg [PIXEL_WIDTH-1:0] buf2[LINE_IN_SIZE_MAX-1:0];
always @(posedge clk) begin
    if (de_i) begin
        sr_di_i <= di_i;
        if (buf_wsel == BUF0_NUM) buf0[buf_wcnt] <= sr_di_i;
        if (buf_wsel == BUF1_NUM) buf1[buf_wcnt] <= sr_di_i;
        if (buf_wsel == BUF2_NUM) buf2[buf_wcnt] <= sr_di_i;
    end
end

// Control FSM
`ifdef SIM_FSM
    enum int unsigned {
        IDLE,
        PRM_CYCLE,
        LINE_GEN
    } fsm_cs = IDLE;
`else
    localparam IDLE = 0;
    localparam PRM_CYCLE = 1;
    localparam LINE_GEN = 2;
    reg [1:0] fsm_cs = IDLE;
`endif

reg [$clog2(LINE_STEP/2)-1:0] dy = 0;
reg [3:0] cnt_sparse = 0;
reg de_o_early = 0;
always @(posedge clk) begin
    de_o_early <= 0;
    case (fsm_cs)
        IDLE: begin
            if (cnt_i > cnt_o) begin
                dy <= cnt_o[1 +: $clog2(LINE_STEP/2)];
                fsm_cs <= PRM_CYCLE;
            end
        end
        PRM_CYCLE: begin
            buf_rcnt <= 0;
            cnt_sparse <= 0;
            fsm_cs <= LINE_GEN;
        end
        LINE_GEN: begin
            cnt_sparse <= cnt_sparse + 1'b1;
            if (cnt_sparse == SPARSE_OUT) begin
                cnt_sparse <= 0;
                de_o_early <= 1;
                buf_rcnt <= buf_rcnt + 1'b1;
                if (buf_rcnt == line_in_size) begin
                    cnt_o <= cnt_o + scale_step;
                    fsm_cs <= IDLE;
                end
            end
        end
        default: fsm_cs <= IDLE; // fsm recovery
    endcase

    if (de_i && vs_i) begin
        cnt_o <= LINE_STEP;
    end
end

// Memory read
reg [PIXEL_WIDTH-1:0] buf_do [1:0];
always @(posedge clk) begin
    buf_do[0] <= buf0[buf_rcnt];
    buf_do[1] <= buf1[buf_rcnt];
end

reg [PIXEL_WIDTH-1:0] line [1:0];
always @(posedge clk) begin
    if (buf_wsel == BUF0_NUM) begin
        line[1] <= buf_do[1];
        line[0] <= buf_do[0];
    end
    if (buf_wsel == BUF1_NUM) begin
        line[1] <= buf_do[0];
        line[0] <= buf_do[1];
    end
    if (cnt_i < (1*LINE_STEP)) begin
        line[1] <= 0; // boundary effect elimination
    end
end

localparam MULT_WIDTH = COE_WIDTH + PIXEL_WIDTH;
localparam OVERFLOW_BIT = COE_WIDTH + PIXEL_WIDTH - 1;
localparam [MULT_WIDTH:0] MAX_OUTPUT = (1 << (PIXEL_WIDTH + COE_WIDTH)) - 1;
localparam [MULT_WIDTH:0] ROUND_ADDER = (1 << (COE_WIDTH - 2));

wire [COE_WIDTH-1:0] coe [1:0];
linear_table #(
    .VENDOR_RAM_STYLE(VENDOR_RAM_STYLE),
    .STEP(LINE_STEP),
    .COE_WIDTH(COE_WIDTH)
) coe_table_m (
    .coe0(coe[0]),
    .coe1(coe[1]),

    .dx(dy),
    .clk(clk)
);

(* mult_style = "block" *) reg [MULT_WIDTH-1:0] mult [1:0];
reg signed [MULT_WIDTH+2-1:0] sum;
always @(posedge clk) begin
    mult[0] <= coe[0] * line[0];
    mult[1] <= coe[1] * line[1];

    sum <= mult[0] + mult[1] + ROUND_ADDER;

    do_o <= sum[COE_WIDTH-1 +: PIXEL_WIDTH];
    if (sum[OVERFLOW_BIT]) do_o <= MAX_OUTPUT;
    if (sum < 0) do_o <= 0;
end

// Align output strobes
reg [2:0] sr_de_o_early = 0;
reg hs_o_early = 0;
reg [2:0] sr_hs_o_early = 0;
reg vs_o_early = 0;
reg [2:0] sr_vs_o_early = 0;
always @(posedge clk) begin
    sr_de_o_early[0] <= de_o_early;
    sr_de_o_early[1] <= sr_de_o_early[0];
    sr_de_o_early[2] <= sr_de_o_early[1];
    de_o <= sr_de_o_early[2];

    hs_o_early <= (buf_rcnt == 0);
    sr_hs_o_early[0] <= hs_o_early;
    sr_hs_o_early[1] <= sr_hs_o_early[0];
    sr_hs_o_early[2] <= sr_hs_o_early[1];
    hs_o <= sr_hs_o_early[2] & sr_de_o_early[2];

    vs_o_early <= (cnt_o == LINE_STEP) && (buf_rcnt == 0);
    sr_vs_o_early[0] <= vs_o_early;
    sr_vs_o_early[1] <= sr_vs_o_early[0];
    sr_vs_o_early[2] <= sr_vs_o_early[1];
    vs_o <= sr_vs_o_early[2] & sr_de_o_early[2];
end

endmodule
