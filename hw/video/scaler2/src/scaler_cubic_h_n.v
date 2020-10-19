module scaler_h #(
//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
    parameter VENDOR_RAM_STYLE="MLAB",
    parameter SCALE_STEP = 4096,
    parameter PIXEL_WIDTH = 12,
    parameter COE_WIDTH = 10,
    parameter COE_COUNT = 4
)(
    //unsigned fixed point. SCALE_STEP is 1.000 scale
    input [15:0] scale_step,

    output coe_adr_en,
    output [$clog2(SCALE_STEP/COE_COUNT)-1:0] coe_adr,
    input [(COE_WIDTH*COE_COUNT)-1:0] coe_i,

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

reg [23:0] cnt_i = 0; // input pixels coordinate counter
reg [23:0] cnt_o = 0; // output pixels coordinate counter

reg [PIXEL_WIDTH-1:0] sr_di_i [2:0];
reg [PIXEL_WIDTH-1:0] pix [COE_COUNT-1:0];
wire [COE_WIDTH-1:0] coe [COE_COUNT-1:0];
reg [MULT_WIDTH-1:0] mult [COE_COUNT-1:0];
reg signed [MULT_WIDTH+2-1:0] sum;

reg [4:0] sr_de_i = 0;
reg [4:0] sr_hs_i = 0;
reg [4:0] sr_vs_i = 0;

wire hs_falling_edge;
wire hs_rising_edge;
reg de_new = 1'b0;

//Input pix buf
reg [15:0] buf_wcnt = 0;
always @(posedge clk) begin
    if (de_i) begin
        sr_di_i[0] <= di_i;
        sr_di_i[1] <= sr_di_i[0];
        sr_di_i[2] <= sr_di_i[1];
    end
end

//Read scale coef
always @(posedge clk) begin
    de_new <= 1'b0;

    if (hs_i & sr_hs_i[0]) begin
        cnt_i <= 0;
        cnt_o <= SCALE_STEP;
    end else begin
        if (de_i) begin
            cnt_i <= cnt_i + SCALE_STEP;
        end

        if (cnt_i > cnt_o) begin
            cnt_o <= cnt_o + scale_step;
            de_new <= 1'b1;
            pix[0] <= di_i;
            pix[1] <= sr_di_i[0];
            pix[2] <= sr_di_i[1];
            pix[3] <= (cnt_i <= (SCALE_STEP*2)) ? 0 : sr_di_i[2];
        end
    end
end
assign coe_adr = cnt_o[2 +: $clog2(SCALE_STEP/COE_COUNT)];

assign coe_adr_en = 1'b1;
genvar i;
generate
    for (i=0; i<COE_COUNT; i=i+1) begin
        assign coe[i] = coe_i[i*COE_WIDTH +: COE_WIDTH];
    end
endgenerate

// pipeline
always @(posedge clk) begin
    //stage 0
    sr_de_i[0] <= de_i;
    sr_hs_i[0] <= hs_i;
    sr_vs_i[0] <= vs_i;

    //stage 1
    sr_de_i[1] <= sr_de_i[0];
    sr_hs_i[1] <= sr_hs_i[0];
    sr_vs_i[1] <= sr_vs_i[0];

    //stage 1
    sr_de_i[2] <= sr_de_i[1];
    sr_hs_i[2] <= sr_hs_i[1];
    sr_vs_i[2] <= sr_vs_i[1];

    //stage 1
    sr_de_i[3] <= sr_de_i[2] & de_new;
    sr_hs_i[3] <= sr_hs_i[2];
    sr_vs_i[3] <= sr_vs_i[2];
    mult[0] <= coe[0] * pix[0];
    mult[1] <= coe[1] * pix[1];
    mult[2] <= coe[2] * pix[2];
    mult[3] <= coe[3] * pix[3];

    //stage 2
    sr_de_i[4] <= sr_de_i[3];
    sr_hs_i[4] <= sr_hs_i[3];
    sr_vs_i[4] <= sr_vs_i[3];
    sum <= mult[1] + mult[2] - mult[0] - mult[3] + ROUND_ADDER;

    //stage 3
    do_o <= sum[COE_WIDTH-1 +: PIXEL_WIDTH];
    if (sum[OVERFLOW_BIT]) do_o <= MAX_OUTPUT;
    if (sum < 0) do_o <= 0;
    de_o <= sr_de_i[4];
    hs_o <= sr_hs_i[4];
    vs_o <= sr_vs_i[4];
end

endmodule
