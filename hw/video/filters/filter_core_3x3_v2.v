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
    parameter DE_I_PERIOD = 0, //0 - no empty cycles
                               //2 - 1 empty cycle per pixel
                               //4 - 3 empty cycle per pixel
                               //etc...
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
    output reg [DATA_WIDTH-1:0] x9 = 0, //can be use like bypass

    output de_o,
    output reg hs_o = 0,
    output reg vs_o = 0,

    input clk,
    input rst
);

// -------------------------------------------------------------------------
localparam PIPELINE = 2;

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

reg [DATA_WIDTH-1:0] x9_ = 0;

reg [0:1] sr_hs_i = 0;
reg [0:(PIPELINE-1)] sr_vs_i = 0;

reg [0:1] line_out_en = 0;

reg dv_o = 1'b0;
reg [3:0] cnte = 0;
reg [3:0] cnti = 0;

wire vs_opt;
wire dv_opt;
assign vs_opt = vs_i | sr_vs_i[PIPELINE-1];
assign dv_opt = (hs_i && dv_o);

assign buf_wptr_clr = (cnte==2);
assign buf_wptr_en = de_i | (hs_i && dv_o);


always @(posedge clk) begin
    if (vs_opt) begin
        dv_o <= 1'b0;
        cnt <= 0;
    end else if (!hs_i && sr_hs_i[0]) begin
        //detect start of line (sol)
        dv_o <= 1'b1;
    end else if (hs_i && dv_o) begin
        //after line end do optional
        if (cnte==2) begin
            dv_o <= 1'b0;
            cnte <= 0;
        end else begin
            cnte <= cnte + 1;
        end
    end

    if (cnte==2) begin
        cnti <= 0;
        hs_o <= 1'b1;
    end else if (!hs_i && de_i) begin
        if (cnti==4) begin
            hs_o <= ~((&line_out_en));
        end
        if (cnti!=4) begin
            cnti <= cnti + 1;
        end
    end
end

always @(posedge clk) begin : buf_line1
    if (buf_wptr_en) begin
        buf1[buf_wptr] <= di_i;
        buf1_do <= buf1[buf_wptr];
    end
end

always @(posedge clk) begin : buf_line0
    if (buf_wptr_en) begin
        buf0[buf_wptr] <= buf1_do;
        buf0_do <= buf0[buf_wptr];
    end
end

always @(posedge clk) begin
    if (buf_wptr_clr) begin
        buf_wptr <= 0;

    end else if (buf_wptr_en) begin
        buf_wptr <= buf_wptr + 1'b1;

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
    sr_vs_i <= {vs_i, sr_vs_i[0:(PIPELINE-1)]};
    sr_hs_i <= {hs_i, sr_hs_i[0:0]};
end

always @(posedge clk) begin
    if (!vs_opt) begin
        line_out_en <= 0;
    end else if (buf_wptr_clr) begin
        line_out_en <= {1'b1, line_out_en[0:0]};
    end
end

always @(posedge clk) begin
    if (!bypass) begin
        x9 <= x9_;
        vs_o <= sr_vs_i[(PIPELINE-1)];
    end else begin
        x9   <= di_i;
        vs_o <= vs_i;
    end
end

assign de_o = ~hs_o & buf_wptr_en;

endmodule
