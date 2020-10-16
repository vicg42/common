module scaler_h #(
//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
    parameter VENDOR_RAM_STYLE="MLAB",
    parameter PIXEL_STEP = 4096,
    parameter PIXEL_WIDTH = 12,
    parameter COE_WIDTH = 10
)(
    //unsigned fixed point. PIXEL_STEP is 1.000 scale
    input [15:0] scale_step,

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

wire [COE_WIDTH-1:0] coe [1:0];
reg [PIXEL_WIDTH-1:0] sr_di_i[1:0];
reg [PIXEL_WIDTH-1:0] pix [1:0];

reg [23:0] cnt_i = 0; // input pixels coordinate counter
reg [23:0] cnt_o = 0; // output pixels coordinate counter

reg sof = 0;
reg sol = 0;

reg new_pix = 0;
reg [1:0] sr_new_pix = 0;
reg new_line = 0;
reg [1:0] sr_new_line = 0;
reg new_fr = 0;
reg [1:0] sr_new_fr = 0;

// reg [PIXEL_WIDTH-1:0] di = 0;
// reg de = 1'b0;
// reg hs = 1'b0;
// reg vs = 1'b0;
// reg sr_hs_i = 1'b0;
// always @(posedge clk) begin
//     sr_hs_i <= hs_i;
//     hs <= sr_hs_i & !hs_i;
//     vs <= vs_i;
//     de <= de_i;
//     di <= di_i;
// end

always @(posedge clk) begin
    if (de_i) begin
        sr_di_i[0] <= di_i;
        sr_di_i[1] <= sr_di_i[0];
    end
end

always @(posedge clk) begin
    new_pix <= 0;
    new_line <= 0;
    new_fr <= 0;

    // if (hs_i) sol <= 1;
    // if (vs_i) sof <= 1;
    if (de_i) begin
        cnt_i <= cnt_i + PIXEL_STEP;
        if (hs_i) sol <= 1;
        if (vs_i) sof <= 1;
    end

    if (cnt_i >= cnt_o) begin
        new_pix <= 1;
        pix[0] <= sr_di_i[0];
        pix[1] <= sr_di_i[1];
        // pix[1] <= (cnt_i <= (PIXEL_STEP)) ? 1'b0 : sr_di_i[1]; // boundary check, needed only for step<1.0 (upsize)
        cnt_o <= cnt_o + scale_step;
        if (sol) begin
            sol <= 0;
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

localparam MULT_WIDTH = COE_WIDTH + PIXEL_WIDTH;
localparam OVERFLOW_BIT = COE_WIDTH + PIXEL_WIDTH - 1;
localparam [MULT_WIDTH:0] MAX_OUTPUT = (1 << (PIXEL_WIDTH + COE_WIDTH)) - 1;
localparam [MULT_WIDTH:0] ROUND_ADDER = (1 << (COE_WIDTH - 2));
wire [$clog2(PIXEL_STEP/2)-1:0] dx;
assign dx = cnt_o[1 +: $clog2(PIXEL_STEP/2)];
linear_table #(
    .VENDOR_RAM_STYLE(VENDOR_RAM_STYLE),
    .STEP(PIXEL_STEP),
    .COE_WIDTH(COE_WIDTH)
) coe_table_m (
    .coe0(coe[0]),
    .coe1(coe[1]),

    .dx(dx),
    .clk(clk)
);

(* mult_style = "block" *) reg [MULT_WIDTH-1:0] mult [1:0];
reg signed [MULT_WIDTH+2-1:0] sum;
always @(posedge clk) begin
    mult[0] <= coe[0] * pix[0];
    mult[1] <= coe[1] * pix[1];

    sum <= mult[0] + mult[1] + ROUND_ADDER;
    if (sr_new_pix[1]) begin
        do_o <= sum[COE_WIDTH-1 +: PIXEL_WIDTH];
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
