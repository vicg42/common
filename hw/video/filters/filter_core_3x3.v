//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 27.04.2018 15:40:42
// Module Name : filter_core_3x3
//
// Description :
//
//------------------------------------------------------------------------

module filter_core_3x3 #(
    parameter LINE_SIZE_MAX = 1024,
    parameter DATA_WIDTH = 12
)(
    input bypass,

    //input resolution X * Y
    input [DATA_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    //output resolution (X - 2) * (Y - 2)
    //pixel pattern:
    //line[0]: x1 x2 x3
    //line[1]: x4 x5 x6
    //line[2]: x7 x8 x9
    output reg [DATA_WIDTH-1:0] x1 = 0,
    output reg [DATA_WIDTH-1:0] x2 = 0,
    output reg [DATA_WIDTH-1:0] x3 = 0,
    output reg [DATA_WIDTH-1:0] x4 = 0,
    output reg [DATA_WIDTH-1:0] x5 = 0,
    output reg [DATA_WIDTH-1:0] x6 = 0,
    output reg [DATA_WIDTH-1:0] x7 = 0,
    output reg [DATA_WIDTH-1:0] x8 = 0,
    output     [DATA_WIDTH-1:0] x9, //can be use like bypass

    output de_o,
    output hs_o,
    output vs_o,

    input clk,
    input rst
);

// -------------------------------------------------------------------------
//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf0 [LINE_SIZE_MAX-1:0];
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf1 [LINE_SIZE_MAX-1:0];
reg [DATA_WIDTH-1:0] buf0_do;
reg [DATA_WIDTH-1:0] buf1_do;

reg [$clog2(LINE_SIZE_MAX)-1:0] buf_wptr = 0;
wire buf_wptr_clr;
wire buf_wptr_en;

reg [DATA_WIDTH-1:0] sr_di_i [0:1];
reg [DATA_WIDTH-1:0] sr_buf1_do [0:0];

reg [0:3] sr_de_i;
reg [0:3] sr_hs_i;
reg [0:3] sr_vs_i;

wire dv_opt;

reg [0:1] line_out_en;

reg [0:4] sr_hs = {5{1'b1}};

reg [DATA_WIDTH-1:0] x9_;
reg de;
reg hs;
reg vs;

assign buf_wptr_clr = ((!sr_hs_i[3] && sr_hs_i[2]) || !vs_i);
assign buf_wptr_en = (de_i || dv_opt);

assign dv_opt = (hs_i & (~sr_hs_i[2]));

always @(posedge clk) begin : buf_line1
    if (buf_wptr_en) begin
        buf1[buf_wptr] <= di_i;
    end
    buf1_do <= buf1[buf_wptr];
end

always @(posedge clk) begin : buf_line0
    if (buf_wptr_en) begin
        buf0[buf_wptr] <= buf1_do;
    end
    buf0_do <= buf0[buf_wptr];
end

always @(posedge clk) begin
    if (buf_wptr_clr) begin
        buf_wptr <= 0;

    end else if (buf_wptr_en) begin

        buf_wptr <= buf_wptr + 1'b1;

//        buf1[buf_wptr] <= di_i;
//        buf1_do <= buf1[buf_wptr];
//
//        buf0[buf_wptr] <= buf1_do;
//        buf0_do <= buf0[buf_wptr];

        //align
        sr_di_i[0] <= di_i;
        sr_di_i[1] <= sr_di_i[0];
        x9_ <= sr_di_i[1];
        x8 <= x9_;
        x7 <= x8;

        sr_buf1_do[0] <= buf1_do;
        x6 <= sr_buf1_do[0];
        x5 <= x6;
        x4 <= x5;

        x3 <= buf0_do;
        x2 <= x3;
        x1 <= x2;

    end
end


always @(posedge clk) begin
    sr_de_i <= {de_i, sr_de_i[0:2]};
    sr_hs_i <= {hs_i, sr_hs_i[0:2]};
    sr_vs_i <= {vs_i, sr_vs_i[0:2]};

    de <=  (line_out_en[1] & (!sr_hs[3] & buf_wptr_en));
    hs <= ~(line_out_en[1] & (!sr_hs_i[3] & !sr_hs_i[1]));
    vs <= sr_vs_i[3];
end


always @(posedge clk) begin
    if (!vs_i) begin
        line_out_en <= 0;
    end else if (buf_wptr_clr) begin
        line_out_en <= {1'b1, line_out_en[0:0]};
    end
end


always @(posedge clk) begin
    if ((!sr_hs_i[1] && sr_hs_i[0]) || !vs_i) begin
        sr_hs <= {5{1'b1}};
    end else if (de_i) begin
        sr_hs <= {1'b0, sr_hs[0:3]};
    end
end


assign x9   = (bypass) ? di_i : x9_;
assign de_o = (bypass) ? de_i : de;
assign hs_o = (bypass) ? hs_i : hs;
assign vs_o = (bypass) ? vs_i : vs;


endmodule
