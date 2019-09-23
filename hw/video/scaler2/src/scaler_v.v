module scaler_v #(
    parameter SPARSE_OUTPUT = 2, // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
//    parameter TABLE_INPUT_WIDTH = 10,
    parameter COE_WIDTH = 10,
    parameter LINE_SIZE_MAX = 12,
    parameter LINE_STEP = 4096,
    parameter DATA_WIDTH = 8
)(
    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    input [15:0] scale_step,
    input [15:0] scale_line_size,

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
//localparam COE_WIDTH = 10;
//localparam [9:0] TABLE_INPUT_WIDTH_MASK = (10'h3FF << (10 - TABLE_INPUT_WIDTH)) & 10'h3FF;

localparam MUL_WIDTH = COE_WIDTH + DATA_WIDTH;
localparam OVERFLOW_BIT = COE_WIDTH + DATA_WIDTH - 1;
localparam [MUL_WIDTH:0] MAX_OUTPUT = (1 << (DATA_WIDTH+COE_WIDTH)) - 1;
localparam [MUL_WIDTH:0] ROUND_ADDER = (1 << (COE_WIDTH-2)); //0.5

reg [23:0] cnt_line_i = 0; // input pixels coordinate counter
reg [23:0] cnt_line_o = 0; // output pixels coordinate counter

wire [COE_WIDTH-1:0] coe [0:3];
reg [DATA_WIDTH-1:0] pix [0:3];
reg [MUL_WIDTH-1:0] mult [0:3];
`ifdef INITAL
    initial
    begin
        integer i, d;
        for (i=0; i<4; i=i+1) begin
            pix[i] = 0;
            mult[i] = 0;
        end
    end
`endif
//(* mult_style = "block" *)

reg signed [MUL_WIDTH+2-1:0] sum;

`ifdef SIM_FSM
    enum int unsigned {
        IDLE,
        CALC_F_PARAMS_CYCLE,
        DBUF_RD
    } fsm_cs = IDLE;
`else
    localparam IDLE = 0;
    localparam CALC_F_PARAMS_CYCLE = 1;
    localparam DBUF_RD = 2;
    reg [3:0] fsm_cs = IDLE;
`endif


reg [3:0] sparse_cntr = 0;


// Store buffers
reg [DATA_WIDTH-1:0] d_in_d = 0;
reg [DATA_WIDTH-1:0] dbuf[0:4][LINE_SIZE_MAX-1:0];
`ifdef INITAL
    initial
    begin
        integer i, d;
        for (i=0; i<5; i=i+1) begin
            for (d=0; d<LINE_SIZE_MAX; d=d+1) begin
                dbuf[i][d] = 0;
            end
        end
    end
`endif
//(* RAM_STYLE="BLOCK" *) reg [DATA_WIDTH-1:0] buf_a[LINE_SIZE_MAX-1:0];
//(* RAM_STYLE="BLOCK" *) reg [DATA_WIDTH-1:0] buf_b[LINE_SIZE_MAX-1:0];
//(* RAM_STYLE="BLOCK" *) reg [DATA_WIDTH-1:0] buf_c[LINE_SIZE_MAX-1:0];
//(* RAM_STYLE="BLOCK" *) reg [DATA_WIDTH-1:0] buf_d[LINE_SIZE_MAX-1:0];
//(* RAM_STYLE="BLOCK" *) reg [DATA_WIDTH-1:0] buf_e[LINE_SIZE_MAX-1:0];

localparam BUF_A_NUM = 0;
localparam BUF_B_NUM = 1;
localparam BUF_C_NUM = 2;
localparam BUF_D_NUM = 3;
localparam BUF_E_NUM = 4;

reg [2:0] dbuf_num = 0;
reg [15:0] dbuf_wrcnt = 0;
reg [15:0] dbuf_rdcnt = 0;
reg [9:0] coe_idx = 0;

reg [DATA_WIDTH-1:0] dbuf_do [0:4];
//reg [DATA_WIDTH-1:0] buf_a_do;
//reg [DATA_WIDTH-1:0] buf_b_do;
//reg [DATA_WIDTH-1:0] buf_c_do;
//reg [DATA_WIDTH-1:0] buf_d_do;
//reg [DATA_WIDTH-1:0] buf_e_do;

reg o_de = 0;
reg [3:0] sr_o_de = 0;
reg o_hs = 0;
reg [3:0] sr_o_hs = 0;
reg [3:0] sr_o_vs = 0;
reg hs_out_early = 0;
reg hs_out_early_d = 0;
reg hs_out_early_dd = 0;
reg hs_out_early_ddd = 0;
reg vs_out_early = 0;
reg vs_out_early_d = 0;
reg vs_out_early_dd = 0;
reg vs_out_early_ddd = 0;

reg [DATA_WIDTH-1:0] sr_di_i [0:0];
reg [0:0] sr_de_i = 0;
reg [0:0] sr_hs_i = 0;
reg [1:0] sr_vs_i = 0;

reg [DATA_WIDTH-1:0] i_di = 0;
reg i_de = 1'b0;
reg i_hs_edge = 1'b0;
reg i_vs_edge = 1'b0;

always @(posedge clk) begin
    sr_di_i[0] <= di_i;
    i_di <= sr_di_i[0];

    sr_de_i[0] <= de_i;
    i_de <= sr_de_i[0];

    sr_hs_i[0] <= hs_i;
    i_hs_edge <= !sr_hs_i[0] && hs_i && !sr_vs_i[0]; //rissing edge of HS

    sr_vs_i[0] <= vs_i;
    i_vs_edge <= sr_vs_i[0] && !vs_i; //falling edge of VS
end

// Store input line process
always @(posedge clk) begin
    if (i_vs_edge) begin
        dbuf_num <= 0;
        cnt_line_i <= 0;
    end else if (i_de) begin
        d_in_d <= i_di;
        if (dbuf_num == BUF_A_NUM) dbuf[0][dbuf_wrcnt] <= i_di;
        if (dbuf_num == BUF_B_NUM) dbuf[1][dbuf_wrcnt] <= i_di;
        if (dbuf_num == BUF_C_NUM) dbuf[2][dbuf_wrcnt] <= i_di;
        if (dbuf_num == BUF_D_NUM) dbuf[3][dbuf_wrcnt] <= i_di;
        if (dbuf_num == BUF_E_NUM) dbuf[4][dbuf_wrcnt] <= i_di;
        dbuf_wrcnt <= dbuf_wrcnt + 1'b1;

        if (i_hs_edge) begin
            cnt_line_i <= cnt_line_i + LINE_STEP;
            dbuf_wrcnt <= 0;
            if (dbuf_num == 4) begin
                dbuf_num <= 0;
            end else begin
                dbuf_num <= dbuf_num + 1'b1;
            end
        end
    end else begin
        if (i_hs_edge && !vs_i) begin
            cnt_line_i <= cnt_line_i + LINE_STEP;
            dbuf_wrcnt <= 0;
            if (dbuf_num == 4) begin
                dbuf_num <= 0;
            end else begin
                dbuf_num <= dbuf_num + 1'b1;
            end
        end
    end
end


// Control FSM
always @(posedge clk) begin
    o_de <= 0;
    o_hs <= 1;

    if (i_vs_edge) begin
        cnt_line_o <= LINE_STEP*3;//*2;
        dbuf_rdcnt <= 0;
        sparse_cntr <= 0;
        fsm_cs <= IDLE;
    end else begin
        case (fsm_cs)
            IDLE: begin
                if (cnt_line_i > cnt_line_o) begin
                    coe_idx <= cnt_line_o[7 +: 5];//[2 +: 10];
                    fsm_cs <= CALC_F_PARAMS_CYCLE;
                end
            end
            CALC_F_PARAMS_CYCLE: begin
                fsm_cs <= DBUF_RD;
                dbuf_rdcnt <= 0;
                sparse_cntr <= 0;
            end
            DBUF_RD: begin
                sparse_cntr <= sparse_cntr + 1'b1;
                o_hs <= 0;
                if (sparse_cntr == SPARSE_OUTPUT) begin
                    sparse_cntr <= 0;
                    o_de <= 1;
                    dbuf_rdcnt <= dbuf_rdcnt + 1'b1;
                    if (dbuf_rdcnt == (scale_line_size - 1)) begin
                        cnt_line_o <= cnt_line_o + scale_step;
                        fsm_cs <= IDLE;
                    end
                end
            end
            default: fsm_cs <= IDLE; // fsm_cs recovery
        endcase
    end
end


scaler_rom_coe # (
    .COE_WIDTH (COE_WIDTH)
) rom_coe (
    .addr (coe_idx),// & TABLE_INPUT_WIDTH_MASK),

    .rom0_do(coe[0]),
    .rom1_do(coe[1]),
    .rom2_do(coe[2]),
    .rom3_do(coe[3]),

    .clk(clk)
);


// Memory read
always @(posedge clk) begin
//    dbuf_do[0] <= dbuf[0][dbuf_rdcnt];
//    dbuf_do[1] <= dbuf[1][dbuf_rdcnt];
//    dbuf_do[2] <= dbuf[2][dbuf_rdcnt];
//    dbuf_do[3] <= dbuf[3][dbuf_rdcnt];
//    dbuf_do[4] <= dbuf[4][dbuf_rdcnt];

    if (dbuf_num == BUF_A_NUM) begin
        pix[3] <= dbuf[1][dbuf_rdcnt];
        pix[2] <= dbuf[2][dbuf_rdcnt];
        pix[1] <= dbuf[3][dbuf_rdcnt];
        pix[0] <= dbuf[4][dbuf_rdcnt];
    end
    if (dbuf_num == BUF_B_NUM) begin
        pix[3] <= dbuf[2][dbuf_rdcnt];
        pix[2] <= dbuf[3][dbuf_rdcnt];
        pix[1] <= dbuf[4][dbuf_rdcnt];
        pix[0] <= dbuf[0][dbuf_rdcnt];
    end
    if (dbuf_num == BUF_C_NUM) begin
        pix[3] <= dbuf[3][dbuf_rdcnt];
        pix[2] <= dbuf[4][dbuf_rdcnt];
        pix[1] <= dbuf[0][dbuf_rdcnt];
        pix[0] <= dbuf[1][dbuf_rdcnt];
    end
    if (dbuf_num == BUF_D_NUM) begin
        pix[3] <= dbuf[4][dbuf_rdcnt];
        pix[2] <= dbuf[0][dbuf_rdcnt];
        pix[1] <= dbuf[1][dbuf_rdcnt];
        pix[0] <= dbuf[2][dbuf_rdcnt];
    end
    if (dbuf_num == BUF_E_NUM) begin
        pix[3] <= dbuf[0][dbuf_rdcnt];
        pix[2] <= dbuf[1][dbuf_rdcnt];
        pix[1] <= dbuf[2][dbuf_rdcnt];
        pix[0] <= dbuf[3][dbuf_rdcnt];
    end
//    if (cnt_line_i < (4*LINE_STEP)) pix[3] <= 0; // boundary effect elimination

end



// Calculate output
always @(posedge clk) begin
//    if (dbuf_num == BUF_A_NUM) begin
//        pix[3] <= dbuf_do[1];//buf_b_do;//
//        pix[2] <= dbuf_do[2];//buf_c_do;//
//        pix[1] <= dbuf_do[3];//buf_d_do;//
//        pix[0] <= dbuf_do[4];//buf_e_do;//
//    end
//    if (dbuf_num == BUF_B_NUM) begin
//        pix[3] <= dbuf_do[2];//buf_c_do;//
//        pix[2] <= dbuf_do[3];//buf_d_do;//
//        pix[1] <= dbuf_do[4];//buf_e_do;//
//        pix[0] <= dbuf_do[0];//buf_a_do;//
//    end
//    if (dbuf_num == BUF_C_NUM) begin
//        pix[3] <= dbuf_do[3];//buf_d_do;//
//        pix[2] <= dbuf_do[4];//buf_e_do;//
//        pix[1] <= dbuf_do[0];//buf_a_do;//
//        pix[0] <= dbuf_do[1];//buf_b_do;//
//    end
//    if (dbuf_num == BUF_D_NUM) begin
//        pix[3] <= dbuf_do[4];//buf_e_do;//
//        pix[2] <= dbuf_do[0];//buf_a_do;//
//        pix[1] <= dbuf_do[1];//buf_b_do;//
//        pix[0] <= dbuf_do[2];//buf_c_do;//
//    end
//    if (dbuf_num == BUF_E_NUM) begin
//        pix[3] <= dbuf_do[0];//buf_a_do;//
//        pix[2] <= dbuf_do[1];//buf_b_do;//
//        pix[1] <= dbuf_do[2];//buf_c_do;//
//        pix[0] <= dbuf_do[3];//buf_d_do;//
//    end
//    if (cnt_line_i < (4*LINE_STEP)) pix[3] <= 0; // boundary effect elimination

    //stage 0
    mult[0] <= coe[0] * pix[0];
    mult[1] <= coe[1] * pix[1];
    mult[2] <= coe[2] * pix[2];
    mult[3] <= coe[3] * pix[3];

    sr_o_de[0] <= o_de;
    sr_o_hs[0] <= o_hs;
    sr_o_vs[0] <= sr_vs_i;

    //stage 1
    sum <= mult[1] + mult[2] - mult[0] - mult[3] + ROUND_ADDER;

    sr_o_de[1] <= sr_o_de[0];
    sr_o_hs[1] <= sr_o_hs[0];
    sr_o_vs[1] <= sr_o_vs[0];

    //stage 2
    do_o <= sum[COE_WIDTH-1 +: DATA_WIDTH];
    if (sum[OVERFLOW_BIT]) do_o <= MAX_OUTPUT;
    if (sum < 0) do_o <= 0;

    de_o <= sr_o_de[1];
    hs_o <= sr_o_hs[1];
    vs_o <= sr_o_vs[1];
end


//// Align output strobes
//always @(posedge clk) begin
//    hs_out_early <= dbuf_rdcnt == 0;
//    hs_out_early_d <= hs_out_early;
//    hs_out_early_dd <= hs_out_early_d;
//    hs_out_early_ddd <= hs_out_early_dd;
//    hs_o <= hs_out_early_ddd & sr_de[1];//hs_out_early_ddd & dv_out_early_ddd;
//
//    vs_out_early <= (cnt_line_o == LINE_STEP*2) && (dbuf_rdcnt == 0);
//    vs_out_early_d <= vs_out_early;
//    vs_out_early_dd <= vs_out_early_d;
//    vs_out_early_ddd <= vs_out_early_dd;
//    vs_o <= vs_out_early_ddd & sr_o_de[1];//vs_out_early_ddd & dv_out_early_ddd;
//end

endmodule
