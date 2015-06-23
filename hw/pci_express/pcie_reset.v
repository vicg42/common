//-------------------------------------------------------------------------
//-- Engineer    : Korg Alex
//--
//-- Create Date : 09/18/2009
//-- Module Name : pcie_reset.v
//--
//-- Description : Котроллер сброса ядра PCI-Express.
//--
//-------------------------------------------------------------------------
`timescale 1ns / 1ps

//Состояния автомата управления
`define C_ST_RST_0    3'b000     //3'h00      //
`define C_ST_RST_1    3'b001     //3'h01      //
`define C_ST_RST_2    3'b010     //3'h02      //
`define C_ST_RST_3    3'b011     //3'h03      //
`define C_ST_RST_4    3'b100     //3'h04      //
`define C_ST_RST_5    3'b101     //3'h05      //

module pcie_reset
(
  pciexp_refclk_i,
  trn_lnk_up_n_i,
  module_rdy_o,
  sys_reset_n_o
);

input         pciexp_refclk_i;
input         trn_lnk_up_n_i;
output        sys_reset_n_o;
output        module_rdy_o;


//------------------------------------------------------------
reg [31:0] cnt_t         = 0;
//reg [8:0]  cnt_25ms      = 0;
reg        sys_reset_n_o = 1'b0;
reg [2:0]  stateRst   = 0;
reg        module_rdy_o = 1'b0;

//parameter C_ST_RST_0    = 0;
//parameter C_ST_RST_1    = 1;
//parameter C_ST_RST_2    = 2;
//parameter C_ST_RST_3    = 3;
//parameter C_ST_RST_4    = 4;
//parameter C_ST_RST_5    = 5;

//--------------------------------------------------------------
always @(posedge pciexp_refclk_i)
  case(stateRst)
    `C_ST_RST_0:
    begin
      module_rdy_o  <= 1'b0;
      if(trn_lnk_up_n_i)
      begin
        sys_reset_n_o <= 1'b1;
        stateRst      <= `C_ST_RST_1;
      end
      else
      begin
        sys_reset_n_o <= 1'b0;
      end
    end

    `C_ST_RST_1:
    begin
        sys_reset_n_o <= 1'b1;

        if(!trn_lnk_up_n_i)
          stateRst <= `C_ST_RST_2;
    end

    `C_ST_RST_2:
    begin
      if(cnt_t == 300000000)
      begin
        sys_reset_n_o <= 1'b0;
        stateRst      <= `C_ST_RST_3;
        cnt_t         <= 0;
      end
      else
      begin
        cnt_t        <= cnt_t + 1;
        sys_reset_n_o <= 1'b1;
      end
    end

    `C_ST_RST_3:
    begin
      if(cnt_t == 200000)
      begin
        sys_reset_n_o <= 1'b1;
        stateRst      <= `C_ST_RST_4;
        cnt_t         <= 0;
      end
      else
      begin
        cnt_t         <= cnt_t + 1;
        sys_reset_n_o <= 1'b0;
      end
    end

    `C_ST_RST_4:
    begin
        sys_reset_n_o <= 1'b1;

        if(!trn_lnk_up_n_i)
          stateRst <= `C_ST_RST_5;
    end

    `C_ST_RST_5:
    begin
        sys_reset_n_o <= 1'b1;
        module_rdy_o <= 1'b1;

        if(trn_lnk_up_n_i)
        begin
          module_rdy_o <= 1'b0;
          stateRst <= `C_ST_RST_1;
        end
    end
  endcase

endmodule







