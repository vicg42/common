module scaler_v #(
    parameter SPARSE_OUTPUT = 2, // 0 - no empty cycles, 1 - one empty cycle per pixel, etc...
    parameter LINE_SIZE_MAX = 12,
    parameter STEP_CORD_I = 4096,
    parameter POINT_COUNT = 4,
    parameter COE_ROM_DEPTH = 32,
    parameter COE_WIDTH = 10,
    parameter DATA_WIDTH = 8
)(
    // (4.12) unsigned fixed point. 4096 is 1.000 scale
    input [15:0] step_cord_o,
    input [15:0] scale_line_size,

    output reg [($clog2(COE_ROM_DEPTH))-1:0] coe_adr,
    input [(POINT_COUNT*COE_WIDTH)-1:0] coe_dat,

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
localparam MUL_WIDTH = COE_WIDTH + DATA_WIDTH;
localparam OVERFLOW_BIT = COE_WIDTH + DATA_WIDTH - 1;
localparam [MUL_WIDTH:0] MAX_OUTPUT = (1 << (DATA_WIDTH+COE_WIDTH)) - 1;
localparam [MUL_WIDTH:0] ROUND_ADDER = (1 << (COE_WIDTH-2)); //0.5


reg [23:0] cnt_cord_i = 0; // input coordinate counter
reg [23:0] cnt_cord_o = 0; // output coordinate counter

wire [COE_WIDTH-1:0] coe [0:POINT_COUNT-1];
reg [DATA_WIDTH-1:0] pix [0:POINT_COUNT-1];
reg [MUL_WIDTH-1:0] mult [0:POINT_COUNT-1];
`ifdef INITAL
    initial
    begin
        integer i, d;
        for (i=0; i<POINT_COUNT; i=i+1) begin
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
(* RAM_STYLE="BLOCK" *) reg [DATA_WIDTH-1:0] dbuf[0:POINT_COUNT][LINE_SIZE_MAX-1:0];
reg [DATA_WIDTH-1:0] dbuf_do [0:POINT_COUNT];
`ifdef INITAL
    initial
    begin
        integer i, d;
        for (i=0; i<=POINT_COUNT; i=i+1) begin
            for (d=0; d<LINE_SIZE_MAX; d=d+1) begin
                dbuf[i][d] = 0;
            end
            dbuf_do[i] = 0;
        end
    end
`endif

reg [2:0] dbuf_num = 0;
reg [15:0] dbuf_wrcnt = 0;
reg [15:0] dbuf_rdcnt = 0;

reg o_de = 0;
reg [3:0] sr_o_de = 0;
reg o_hs = 0;
reg [3:0] sr_o_hs = 0;
reg [3:0] sr_o_vs = 0;

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

//integer x;
// Store input line process
always @(posedge clk) begin
    if (i_vs_edge) begin
        dbuf_num <= 0;
        cnt_cord_i <= 0;
    end else if (i_de) begin
        dbuf_wrcnt <= dbuf_wrcnt + 1'b1;

        if (i_hs_edge) begin
            cnt_cord_i <= cnt_cord_i + STEP_CORD_I;
            dbuf_wrcnt <= 0;
            if (dbuf_num == POINT_COUNT) begin
                dbuf_num <= 0;
            end else begin
                dbuf_num <= dbuf_num + 1'b1;
            end
        end
    end else begin
        if (i_hs_edge && !vs_i) begin
            cnt_cord_i <= cnt_cord_i + STEP_CORD_I;
            dbuf_wrcnt <= 0;
            if (dbuf_num == POINT_COUNT) begin
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
        cnt_cord_o <= STEP_CORD_I*3;
        dbuf_rdcnt <= 0;
        sparse_cntr <= 0;
        fsm_cs <= IDLE;
    end else begin
        case (fsm_cs)
            IDLE: begin
                if (cnt_cord_i > cnt_cord_o) begin
                    coe_adr <= cnt_cord_o[7 +: 5];//[2 +: 10];
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
                        cnt_cord_o <= cnt_cord_o + step_cord_o;
                        fsm_cs <= IDLE;
                    end
                end
            end
            default: fsm_cs <= IDLE; // fsm_cs recovery
        endcase
    end
end


//genvar a;
//generate
//    for (a=0; a<4; a=a+1)  begin
//        scaler_rom2_coe # (
//            .INIT(ROM_COE_INIT[a]),
//            .COE_WIDTH (COE_WIDTH)
//        ) rom_coe (
//            .addr(coe_adr),
//            .do_o(coe[a]),
//            .clk(clk)
//        );
//    end
//endgenerate

//
//scaler_rom_coe # (
//    .COE_WIDTH (COE_WIDTH)
//) rom_coe (
//    .addr (coe_adr),
//
//    .rom0_do(coe[0]),
//    .rom1_do(coe[1]),
//    .rom2_do(coe[2]),
//    .rom3_do(coe[3]),
//
//    .clk(clk)
//);

assign coe[0] = coe_dat[COE_WIDTH*0 +: COE_WIDTH];
assign coe[1] = coe_dat[COE_WIDTH*1 +: COE_WIDTH];
assign coe[2] = coe_dat[COE_WIDTH*2 +: COE_WIDTH];
assign coe[3] = coe_dat[COE_WIDTH*3 +: COE_WIDTH];

//BUF
genvar x;
generate
    for (x=0; x<POINT_COUNT; x=x+1)  begin
        always @(posedge clk) begin
            if (i_de) begin
                if (dbuf_num == x) begin
                    dbuf[x][dbuf_wrcnt] <= i_di;
                end
            end

            dbuf_do[x] <= dbuf[x][dbuf_rdcnt];
        end
    end
endgenerate



// Calculate output
always @(posedge clk) begin
    case (dbuf_num)
        3'd0 : begin
            pix[3] <= dbuf_do[1];//buf_b_do;// dbuf[1][dbuf_rdcnt];//
            pix[2] <= dbuf_do[2];//buf_c_do;// dbuf[2][dbuf_rdcnt];//
            pix[1] <= dbuf_do[3];//buf_d_do;// dbuf[3][dbuf_rdcnt];//
            pix[0] <= dbuf_do[4];//buf_e_do;// dbuf[4][dbuf_rdcnt];//
        end

        3'd1 : begin
            pix[3] <= dbuf_do[2];//buf_c_do;// dbuf[2][dbuf_rdcnt];//
            pix[2] <= dbuf_do[3];//buf_d_do;// dbuf[3][dbuf_rdcnt];//
            pix[1] <= dbuf_do[4];//buf_e_do;// dbuf[4][dbuf_rdcnt];//
            pix[0] <= dbuf_do[0];//buf_a_do;// dbuf[0][dbuf_rdcnt];//
        end

        3'd2 : begin
            pix[3] <= dbuf_do[3];//buf_d_do;// dbuf[3][dbuf_rdcnt];//
            pix[2] <= dbuf_do[4];//buf_e_do;// dbuf[4][dbuf_rdcnt];//
            pix[1] <= dbuf_do[0];//buf_a_do;// dbuf[0][dbuf_rdcnt];//
            pix[0] <= dbuf_do[1];//buf_b_do;// dbuf[1][dbuf_rdcnt];//
        end

        3'd3 : begin
            pix[3] <= dbuf_do[4];//buf_e_do;// dbuf[4][dbuf_rdcnt];//
            pix[2] <= dbuf_do[0];//buf_a_do;// dbuf[0][dbuf_rdcnt];//
            pix[1] <= dbuf_do[1];//buf_b_do;// dbuf[1][dbuf_rdcnt];//
            pix[0] <= dbuf_do[2];//buf_c_do;// dbuf[2][dbuf_rdcnt];//
        end

        3'd4 : begin
            pix[3] <= dbuf_do[0];//buf_a_do;// dbuf[0][dbuf_rdcnt];//
            pix[2] <= dbuf_do[1];//buf_b_do;// dbuf[1][dbuf_rdcnt];//
            pix[1] <= dbuf_do[2];//buf_c_do;// dbuf[2][dbuf_rdcnt];//
            pix[0] <= dbuf_do[3];//buf_d_do;// dbuf[3][dbuf_rdcnt];//
        end
    endcase

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


endmodule
