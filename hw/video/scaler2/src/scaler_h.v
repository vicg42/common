module scaler_h #(
    parameter TABLE_INPUT_WIDTH = 10,
    parameter PIXEL_STEP = 4096,
    parameter DATA_WIDTH = 8
)(
    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    input [15:0] scale_step,

    input [DATA_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    output reg [DATA_WIDTH-1:0] do_o = 0,
    output reg de_o = 0,
    output reg hs_o = 0,
    output reg vs_o = 0,

    input clk,
    input rst
);
// -------------------------------------------------------------------------
localparam COEFF_WIDTH = 10;
localparam [9:0] TABLE_INPUT_WIDTH_MASK = (10'h3FF << (10 - TABLE_INPUT_WIDTH)) & 10'h3FF;

localparam MUL_WIDTH = COEFF_WIDTH + DATA_WIDTH;
localparam OVERFLOW_BIT = COEFF_WIDTH + DATA_WIDTH - 1;
localparam [MUL_WIDTH:0] MAX_OUTPUT = (1 << (DATA_WIDTH+COEFF_WIDTH)) - 1;
localparam [MUL_WIDTH:0] ROUND_ADDER = (1 << (COEFF_WIDTH-2));


reg [DATA_WIDTH-1:0] sr_di_i [0:3];

wire [COEFF_WIDTH-1:0] coe [0:3];
reg [DATA_WIDTH-1:0] pix [0:3];
(* mult_style = "block" *) reg [MUL_WIDTH-1:0] mult [0:3];

reg [23:0] cnt_pix_i = 0;             // input pixels coordinate counter
reg [23:0] cnt_pix_o = PIXEL_STEP;             // output pixels coordinate counter

reg new_pix = 0;
reg [1:0] sr_new_pix = 0;
reg [1:0] sr_new_line = 0;
reg [1:0] sr_new_fr = 0;

reg signed [MUL_WIDTH+2-1:0] sum;

always @(posedge clk) begin
    if (rst) begin
        new_pix <= 0;

        cnt_pix_i <= 0;
        cnt_pix_o <= 0;

        sr_di_i[0] <= 0;
        sr_di_i[1] <= 0;
        sr_di_i[2] <= 0;
        sr_di_i[3] <= 0;

    end else begin
        new_pix <= 0;

        if (hs_i || vs_i) begin
            cnt_pix_i <= 0;
            cnt_pix_o <= PIXEL_STEP;

        end else begin
            if (de_i && !hs_i && !vs_i) begin
                sr_di_i[0] <= di_i;
                sr_di_i[1] <= sr_di_i[0];
                sr_di_i[2] <= sr_di_i[1];
                sr_di_i[3] <= sr_di_i[2];

                cnt_pix_i <= cnt_pix_i + PIXEL_STEP;
            end

            if (cnt_pix_i > cnt_pix_o) begin
                new_pix <= 1;

                pix[0] <= sr_di_i[0];
                pix[1] <= sr_di_i[1];
                pix[2] <= sr_di_i[2];
                pix[3] <= sr_di_i[3]; //(cnt_pix_i <= (PIXEL_STEP*2))? 1'b0 : sr_di_i[3]; // boundary check, needed only for step<1.0 (upsize)

                cnt_pix_o <= cnt_pix_o + scale_step;
            end
        end
    end
end

wire [9:0] coe_idx;
assign coe_idx = cnt_pix_o[2 +: 10];

scaler_coe scaler_coe(
    .idx(coe_idx & TABLE_INPUT_WIDTH_MASK),

    .f0(coe[0]),
    .f1(coe[1]),
    .f2(coe[2]),
    .f3(coe[3]),

    .clk(clk)
);


always @(posedge clk) begin
    //stage 0
    mult[0] <= coe[0] * pix[0];
    mult[1] <= coe[1] * pix[1];
    mult[2] <= coe[2] * pix[2];
    mult[3] <= coe[3] * pix[3];

    sr_new_pix[0] <= new_pix;
    sr_new_line[0] <= hs_i;
    sr_new_fr[0] <= vs_i;

    //stage 1
    sum <= mult[1] + mult[2] - mult[0] - mult[3] + ROUND_ADDER;

    sr_new_pix[1] <= sr_new_pix[0];
    sr_new_line[1] <= sr_new_line[0];
    sr_new_fr[1] <= sr_new_fr[0];

    //stage 2
    if (sr_new_pix[1]) begin
        do_o <= sum[COEFF_WIDTH-1 +: DATA_WIDTH];
        if (sum[OVERFLOW_BIT]) do_o <= MAX_OUTPUT;
        if (sum < 0) do_o <= 0;
    end
    de_o <= sr_new_pix[1];
    hs_o <= sr_new_line[1];
    vs_o <= sr_new_fr[1];
end


reg [15:0] dbg_cnt_pix_o = 0;
always @(posedge clk) begin
    if (new_pix) begin
        dbg_cnt_pix_o <= dbg_cnt_pix_o + 1;
    end
end


endmodule
