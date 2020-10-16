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

localparam MULT_WIDTH = COE_WIDTH + PIXEL_WIDTH;
localparam OVERFLOW_BIT = COE_WIDTH + PIXEL_WIDTH - 1;
localparam [MULT_WIDTH:0] MAX_OUTPUT = (1 << (PIXEL_WIDTH + COE_WIDTH)) - 1;
localparam [MULT_WIDTH:0] ROUND_ADDER = (1 << (COE_WIDTH - 2));

reg [PIXEL_WIDTH-1:0] buf_do [1:0];
reg [PIXEL_WIDTH-1:0] sr0_buf_do [1:0];
reg [PIXEL_WIDTH-1:0] line [1:0];
wire [COE_WIDTH-1:0] coe [1:0];
reg [MULT_WIDTH-1:0] mult [1:0];
reg signed [MULT_WIDTH+2-1:0] sum;

reg [4:0] sr_de_i = 0;
reg [4:0] sr_hs_i = 0;
reg [4:0] sr_vs_i = 0;

//Input line buf
reg [15:0] buf_wcnt = 0;
(* RAM_STYLE=VENDOR_RAM_STYLE *) reg [PIXEL_WIDTH-1:0] buf0[LINE_IN_SIZE_MAX-1:0];
always @(posedge clk) begin
    if (hs_i) begin
        buf_wcnt <= 0;
    end else if (!hs_i) begin
        if (de_i) begin
            buf_wcnt <= buf_wcnt + 1'b1;
        end
    end
end
always @(posedge clk) begin
    if (de_i) begin
        buf0[buf_wcnt] <= di_i;
    end
end

//Read scale coef
wire hs_falling_edge;
wire hs_rising_edge;
reg [23:0] cnt_i = 0; // input pixels coordinate counter
reg [23:0] cnt_o = 0; // output pixels coordinate counter
reg [$clog2(LINE_STEP/2)-1:0] dy = 0;
assign hs_falling_edge = !hs_i & sr_hs_i[0];
assign hs_rising_edge = hs_i & !sr_hs_i[0];
always @(posedge clk) begin
    if (!vs_i) begin
        cnt_i <= 0;
    end else begin
        if (hs_falling_edge) begin
            cnt_i <= cnt_i + LINE_STEP;
        end

        if (hs_rising_edge) begin
            cnt_o <= cnt_o + scale_step;
        end
    end

    if (cnt_i > cnt_o) begin
        dy <= cnt_o[1 +: $clog2(LINE_STEP/2)];
    end
end

linear_table #(
    .VENDOR_RAM_STYLE(VENDOR_RAM_STYLE),
    .STEP(LINE_STEP),
    .COE_WIDTH(COE_WIDTH)
) coe_table_m (
    .coe0(coe[0]),
    .coe1(coe[1]),

    .dx_en(1'b1),
    .dx(dy),
    .clk(clk)
);

// Align
always @(posedge clk) begin
    //stage 0
    buf_do[0] <= (cnt_o > 0) ? buf0[buf_wcnt] : 0;
    buf_do[1] <= di_i;
    sr_de_i[0] <= de_i;
    sr_hs_i[0] <= hs_i;
    sr_vs_i[0] <= vs_i;

    //stage 1
    sr0_buf_do[0] <= buf_do[0];
    sr0_buf_do[1] <= buf_do[1];
    sr_de_i[1] <= sr_de_i[0];
    sr_hs_i[1] <= sr_hs_i[0];
    sr_vs_i[1] <= sr_vs_i[0];

    //stage 2
    line[0] <= sr0_buf_do[0];
    line[1] <= sr0_buf_do[1];
    sr_de_i[2] <= sr_de_i[1];
    sr_hs_i[2] <= sr_hs_i[1];
    sr_vs_i[2] <= sr_vs_i[1];
end

//calc
always @(posedge clk) begin
    //stage 3
    mult[0] <= coe[0] * line[0];
    mult[1] <= coe[1] * line[1];
    sr_de_i[3] <= sr_de_i[2];
    sr_hs_i[3] <= sr_hs_i[2];
    sr_vs_i[3] <= sr_vs_i[2];

    //stage 4
    sum <= mult[0] + mult[1] + ROUND_ADDER;
    sr_de_i[4] <= sr_de_i[3];
    sr_hs_i[4] <= sr_hs_i[3];
    sr_vs_i[4] <= sr_vs_i[3];

    //stage 5
    do_o <= sum[COE_WIDTH-1 +: PIXEL_WIDTH];
    if (sum[OVERFLOW_BIT]) do_o <= MAX_OUTPUT;
    if (sum < 0) do_o <= 0;
    de_o <= sr_de_i[4];
    hs_o <= sr_hs_i[4];
    vs_o <= sr_vs_i[4];
end

endmodule
