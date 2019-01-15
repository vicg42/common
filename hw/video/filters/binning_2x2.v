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
//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
(* RAM_STYLE = "BLOCK" *) reg [PIXEL_WIDTH-1:0] buf0 [LINE_SIZE_MAX-1:0];
reg [PIXEL_WIDTH-1:0] buf0_do;

reg [$clog2(LINE_SIZE_MAX)-1:0] buf_wptr = 0;
wire buf_wptr_clr;
wire buf_wptr_en;

reg [PIXEL_WIDTH-1:0] sr_di_i [0:1];

reg [0:3] sr_de_i;
reg [0:3] sr_hs_i;
reg [0:3] sr_vs_i = 0;

wire dv_opt;

reg line_out_en;

reg [PIXEL_WIDTH-1:0] x [0:3];

assign buf_wptr_clr = ((!sr_hs_i[2] && sr_hs_i[1]) || !(vs_i || sr_vs_i[3]));
assign buf_wptr_en = (de_i || dv_opt);

assign dv_opt = (hs_i & (~sr_hs_i[1]));

always @(posedge clk) begin : buf_line0
    if (buf_wptr_en) begin
        buf0[buf_wptr] <= di_i;
    end
    buf0_do <= buf0[buf_wptr];
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

reg de = 1'b0;
reg hs = 1'b0;
reg vs = 1'b0;

always @(posedge clk) begin
    sr_de_i <= {de_i, sr_de_i[0:2]};
    sr_hs_i <= {hs_i, sr_hs_i[0:2]};
    sr_vs_i <= {vs_i, sr_vs_i[0:2]};

    de <=  (line_out_en & (!sr_hs_i[2]) & sr_de_i[2]);
    hs <= ~(line_out_en & (!sr_hs_i[2]));
    vs <= sr_vs_i[2];
end


always @(posedge clk) begin
    if (!(vs_i || sr_vs_i[3])) begin
        line_out_en <= 1'b0;
    end else if (buf_wptr_clr) begin
        line_out_en <= ~line_out_en;
    end
end



reg [PIXEL_WIDTH:0] sumx12 = 0;
reg [PIXEL_WIDTH:0] sumx34 = 0;

reg [PIXEL_WIDTH+1:0] sumx1234 = 0;

reg [PIXEL_WIDTH-1:0] sumx1234_div4;

reg [0:3] sr_de = 0;
reg [0:3] sr_hs = 0;
reg [0:3] sr_vs = 0;

reg de_sel = 1'b0;
reg sr_de_sel = 1'b0;
reg [PIXEL_WIDTH-1:0] do_ = 0;

//Line1:  X[2] X[3]
//Line0:  X[0] X[1]
always @(posedge clk) begin
        //----------------------------
        //pipeline 0
        //----------------------------
        sumx12 <= {1'b0, x[0]} + {1'b0, x[1]};
        sumx34 <= {1'b0, x[2]} + {1'b0, x[3]};

        sr_de[0] <= de;
        sr_hs[0] <= hs;
        sr_vs[0] <= vs;

        //----------------------------
        //pipeline 1
        //----------------------------
        sumx1234 <= {1'b0, sumx12} + {1'b0, sumx34};

        sr_de[1] <= sr_de[0];
        sr_hs[1] <= sr_hs[0];
        sr_vs[1] <= sr_vs[0];

        //----------------------------
        //pipeline 2
        //----------------------------
        sumx1234_div4 <= sumx1234[PIXEL_WIDTH+1:2]; //(x[0] + x[1] + x[2] + x[3])/4

        if (sr_de[1]) begin
            de_sel <= ~de_sel;
        end else begin
            de_sel <= 1'b0;
        end

        sr_de[2] <= sr_de[1];
        sr_hs[2] <= sr_hs[1];
        sr_vs[2] <= sr_vs[1];

        //----------------------------
        //pipeline 3
        //----------------------------
        sr_de_sel <= de_sel;
        if (de_sel) begin
        do_ <= sumx1234_div4;
        end
        sr_de[3] <= sr_de_sel;
        sr_hs[3] <= sr_hs[2];
        sr_vs[3] <= sr_vs[2];


        //----------------------------
        //pipeline 4
        //----------------------------
        do_o <= do_;
        de_o <= sr_de[3];
        hs_o <= sr_hs[3];
        vs_o <= sr_vs[3];

//        //----------------------------
//        //pipeline 3
//        //----------------------------
//        sr_de_sel <= de_sel;
//        if (de_sel) begin
//        do_ <= sumx1234_div4;
//        end
//        do_o <= do_;
//        de_o <= (sr_de_sel & ~sr_hs[2]);
//        hs_o <= sr_hs[2];
//        vs_o <= sr_vs[2];

end

endmodule
