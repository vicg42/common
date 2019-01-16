//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 22.05.2018 12:25:06
// Module Name : binning_2x2
//
// Description :
//
//------------------------------------------------------------------------

module binning_2x2 #(
    parameter DE_SPARSE = 1, //0 - no empty cycles
                             //1 - one empty cycle per pixel
                             //3 - 3 empty cycle per pixel
                             //etc...
    parameter LINE_SIZE_MAX = 1024,
    parameter PIXEL_WIDTH = 8
)(
    input bypass,

    //input resolution X * Y
    input [PIXEL_WIDTH-1:0] di_i,
    input                   de_i,
    input                   hs_i,
    input                   vs_i,

    //input resolution X/2 * Y/2
    output reg [PIXEL_WIDTH-1:0] do_o,
    output reg                   de_o,
    output reg                   hs_o,
    output reg                   vs_o,

    input clk,
    input rst
);

// -------------------------------------------------------------------------
localparam PIPELINE = (DE_SPARSE == 0) ? 8 :
                      (DE_SPARSE == 1) ? 16 :
                      (DE_SPARSE == 3) ? 32 : 64;

//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
(* RAM_STYLE = "BLOCK" *) reg [PIXEL_WIDTH-1:0] buf0 [LINE_SIZE_MAX-1:0];
reg [PIXEL_WIDTH-1:0] buf0_do;

reg [$clog2(LINE_SIZE_MAX)-1:0] buf_wptr = 0;
wire buf_wptr_clr;
wire buf_wptr_en;

reg [PIXEL_WIDTH:0] sr_di_i [0:1];

reg [0:(PIPELINE)] sr_de_i = 0;
reg [0:3] sr_hs_i = {4{1'b1}};
reg [0:3] sr_vs_i = 0;

reg line_out_en;

reg [PIXEL_WIDTH-1:0] x [0:3];

wire en;
wire vs_opt;
wire dv_opt;
assign vs_opt = vs_i | sr_vs_i[3];
assign dv_opt = hs_i & (~sr_hs_i[1]);

assign buf_wptr_clr = (!sr_hs_i[2] & sr_hs_i[1] & sr_de_i[PIPELINE-1]) | !vs_opt;
assign buf_wptr_en = (de_i | (dv_opt & sr_de_i[PIPELINE-1]));

always @(posedge clk) begin : buf_line0
    if (buf_wptr_en) begin
        buf0[buf_wptr] <= di_i;
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
        x[3] <= sr_di_i[0];
        x[2] <= x[3];

        x[1] <= buf0_do;
        x[0] <= x[1];

    end
end

reg hs = 1'b0;
reg vs = 1'b0;

wire [8:0] en_opt;
genvar a;
generate
    if (DE_SPARSE == 0) begin
        for (a=0; a <= (PIPELINE); a=a+1) begin
            assign en_opt[a] = sr_de_i[a];
        end
    end else if (DE_SPARSE == 1) begin
        for (a=2; a <= (PIPELINE); a=a+2) begin
            assign en_opt[a/2-1] = sr_de_i[a-1];
        end
    end else if (DE_SPARSE == 3) begin
        for (a=4; a <= (PIPELINE); a=a+4) begin
            assign en_opt[a/4-1] = sr_de_i[a-1];
        end
    end
endgenerate

assign en = (de_i | (|en_opt[7:0]));

always @(posedge clk) begin
    sr_de_i <= {de_i, sr_de_i[0:(PIPELINE-1)]};
    if (en) begin
        sr_hs_i <= {hs_i, sr_hs_i[0:2]};
        sr_vs_i <= {vs_i, sr_vs_i[0:2]};

        hs <= (line_out_en & !sr_hs_i[1]);
        vs <= sr_vs_i[1];
    end
end

always @(posedge clk) begin
    if (!vs_opt) begin
        line_out_en <= 1'b0;
    end else if (buf_wptr_clr) begin
        line_out_en <= ~line_out_en;
    end
end

reg [PIXEL_WIDTH:0] sumx12 = 0;
reg [PIXEL_WIDTH:0] sumx34 = 0;

reg [PIXEL_WIDTH+1:0] sumx1234 = 0;

reg [PIXEL_WIDTH-1:0] sumx1234_div4;

reg [0:0] sr_de = 0;
reg [0:3] sr_hs = 0;
reg [0:3] sr_vs = 0;

reg de_sel = 1'b0;
reg sr_de_sel = 1'b0;
reg [PIXEL_WIDTH-1:0] do_ = 0;
reg [PIXEL_WIDTH-1:0] do_o_ = 0;
reg                   de_o_ = 0;
reg                   hs_o_ = 0;
reg                   vs_o_ = 0;

//Line1:  X[2] X[3]
//Line0:  X[0] X[1]
always @(posedge clk) begin
    if (en) begin
        //----------------------------
        //pipeline 0
        //----------------------------
        sumx12 <= {1'b0, x[0]} + {1'b0, x[1]};
        sumx34 <= {1'b0, x[2]} + {1'b0, x[3]};

        sr_hs[0] <= hs;
        sr_vs[0] <= vs;

        //----------------------------
        //pipeline 1
        //----------------------------
        sumx1234 <= {1'b0, sumx12} + {1'b0, sumx34};

        sr_hs[1] <= sr_hs[0];
        sr_vs[1] <= sr_vs[0];

        //----------------------------
        //pipeline 2
        //----------------------------
        sumx1234_div4 <= sumx1234[PIXEL_WIDTH+1:2]; //(x[0] + x[1] + x[2] + x[3])/4

        if (sr_hs[1]) begin
            de_sel <= ~de_sel;
        end else begin
            de_sel <= 1'b0;
        end

        sr_hs[2] <= sr_hs[1];
        sr_vs[2] <= sr_vs[1];

        //----------------------------
        //pipeline 3
        //----------------------------
        sr_de_sel <= de_sel;
        if (de_sel) begin
        do_ <= sumx1234_div4;
        end
        sr_de[0] <= (sr_de_sel & sr_hs[2]);
        sr_hs[3] <= sr_hs[2];
        sr_vs[3] <= sr_vs[2];

        //----------------------------
        //pipeline 4
        //----------------------------
        do_o_ <= do_;
        de_o_ <= sr_de[0];
        hs_o_ <= sr_hs[3];
        vs_o_ <= sr_vs[3];
    end

    do_o <= do_o_;
    de_o <= de_o_ & en;
    hs_o <= ~hs_o_;
    vs_o <= vs_o_;
end


endmodule
