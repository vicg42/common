//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 25.08.2012 17:56:21
//-- Module Name : pcie_rx.v
//--
//-- Description : PCI core data bus 128bit
//--
//-- Revision:
//-- Revision 0.01 - File Created
//--
//-------------------------------------------------------------------------
`timescale 1ns/1ns
//`include "../../../common/lib/hw/pci_express/pcie_def.v"

//Номера буферов передатчика ядра PCI-Express:
`define C_BUF_NON_POSTED_QUEUE     0
`define C_BUF_POSTED_QUEUE         1
`define C_BUF_COMPLETION_QUEUE     2
`define C_BUF_LOOK_AHEAD           3

//Константы заголовка пакета:
//(поле FMT)
`define C_FMT_MSG_4DW              2'b10   //Msg  - 4DW, no data
`define C_FMT_MSGD_4DW             2'b11   //MsgD - 4DW, w/ data

//(поле FMT + поле TYPE)
`define C_FMT_TYPE_IORD_3DW_ND     7'b00_00010 //(0x02) IORd   - 3DW, no data
`define C_FMT_TYPE_IOWR_3DW_WD     7'b10_00010 //(0x42) IOWr   - 3DW, w/data
`define C_FMT_TYPE_MWR_3DW_WD      7'b10_00000 //(0x40) MWr    - 3DW, w/data
`define C_FMT_TYPE_MWR_4DW_WD      7'b11_00000 //(0x60) MWr    - 4DW, w/data
`define C_FMT_TYPE_MRD_3DW_ND      7'b00_00000 //(0x00) MRd    - 3DW, no data
`define C_FMT_TYPE_MRD_4DW_ND      7'b01_00000 //(0x20) MRd    - 4DW, no data
`define C_FMT_TYPE_MRDLK_3DW_ND    7'b00_00001 //(0x01) MRdLk  - 3DW, no data
`define C_FMT_TYPE_MRDLK_4DW_ND    7'b01_00001 //(0x21) MRdLk  - 4DW, no data
`define C_FMT_TYPE_CPLLK_3DW_ND    7'b00_01011 //(0x0B) CplLk  - 3DW, no data
`define C_FMT_TYPE_CPLDLK_3DW_WD   7'b10_01011 //(0x4B) CplDLk - 3DW, w/ data
`define C_FMT_TYPE_CPL_3DW_ND      7'b00_01010 //(0x0A) Cpl    - 3DW, no data
`define C_FMT_TYPE_CPLD_3DW_WD     7'b10_01010 //(0x4A) CplD   - 3DW, w/ data
`define C_FMT_TYPE_CFGRD0_3DW_ND   7'b00_00100 //(0x04) CfgRd0 - 3DW, no data
`define C_FMT_TYPE_CFGWR0_3DW_WD   7'b10_00100 //(0x44) CfgwR0 - 3DW, w/ data
`define C_FMT_TYPE_CFGRD1_3DW_ND   7'b00_00101 //(0x05) CfgRd1 - 3DW, no data
`define C_FMT_TYPE_CFGWR1_3DW_WD   7'b10_00101 //(0x45) CfgwR1 - 3DW, w/ data


`define C_MAX_PAYLOAD_128_BYTE     3'b000
`define C_MAX_PAYLOAD_256_BYTE     3'b001
`define C_MAX_PAYLOAD_512_BYTE     3'b010
`define C_MAX_PAYLOAD_1024_BYTE    3'b011
`define C_MAX_PAYLOAD_2048_BYTE    3'b100
`define C_MAX_PAYLOAD_4096_BYTE    3'b101

`define C_MAX_READ_REQ_128_BYTE    3'b000
`define C_MAX_READ_REQ_256_BYTE    3'b001
`define C_MAX_READ_REQ_512_BYTE    3'b010
`define C_MAX_READ_REQ_1024_BYTE   3'b011
`define C_MAX_READ_REQ_2048_BYTE   3'b100
`define C_MAX_READ_REQ_4096_BYTE   3'b101

`define C_COMPLETION_STATUS_SC     3'b000
`define C_COMPLETION_STATUS_UR     3'b001
`define C_COMPLETION_STATUS_CRS    3'b010
`define C_COMPLETION_STATUS_CA     3'b011

//Состояния автомата управления
`define STATE_RX_IDLE       4'h0 //11'b00000000001 //
`define STATE_RX_IOWR_QW1   4'h1 //11'b00000000010 //
`define STATE_RX_IOWR_WT    4'h2 //11'b00000000100 //
`define STATE_RX_MWR_QW1    4'h3 //11'b00000001000 //
`define STATE_RX_MWR_WT     4'h4 //11'b00000010000 //
`define STATE_RX_MRD_QW1    4'h5 //11'b00000100000 //
`define STATE_RX_MRD_WT     4'h6 //11'b00001000000 //
`define STATE_RX_CPL_QW1    4'h7 //11'b00010000000 //
`define STATE_RX_CPLD_QWN   4'h8 //11'b00100000000 //
`define STATE_RX_CPLD_WT    4'h9 //11'b01000000000 //
`define STATE_RX_MRD_WT1    4'hA //11'b10000000000 //


module pcie_rx(
//usr app
output [7:0]       usr_reg_adr_o,
output [31:0]      usr_reg_din_o,
output             usr_reg_wr_o,
output             usr_reg_rd_o,

//output [7:0]       usr_txbuf_dbe_o,
output [31:0]      usr_txbuf_din_o,
output             usr_txbuf_wr_o,
output             usr_txbuf_wr_last_o,
input              usr_txbuf_full_i,

//pci_core -> usr_app
input [127:0]      trn_rd,
input [3:0]        trn_rrem_n,
input              trn_rsof_n,
input              trn_reof_n,
input              trn_rsrc_rdy_n,   //pci_core - rdy
input              trn_rsrc_dsc_n,
output             trn_rdst_rdy_n_o, //usr_app - rdy
input [6:0]        trn_rbar_hit_n,

//Handshake with Tx engine:
output reg         req_compl_o,
input              compl_done_i,

output reg [29:0]  req_addr_o,
output reg [6:0]   req_pkt_type_o,
output reg [2:0]   req_tc_o,
output reg         req_td_o,
output reg         req_ep_o,
output reg [1:0]   req_attr_o,
output reg [9:0]   req_len_o,
output reg [15:0]  req_rid_o,
output reg [7:0]   req_tag_o,
output reg [7:0]   req_be_o,
output reg         req_exprom_o,

//dma trn
input              dma_init_i,

output reg [31:0]  cpld_total_size_o,//Общее кол-во данных(DW) от всех принятых пакетов CplD (m_pcie_usr_app/p_in_mrd_rcv_size)
output reg         cpld_malformed_o, //Результат сравнение (cpld_tlp_len != cpld_tlp_cnt)

//Технологический порт
output [31:0]      tst_o,
input  [31:0]      tst_i,

//System
input              clk,
input              rst_n
);

//---------------------------------------------
// Local registers/wire
//---------------------------------------------
wire         bar_exprom;
wire         bar_usr;

reg [3:0]    fsm_state;

reg          trn_rdst_rdy_n;

reg [9:0]    cpld_tlp_cnt;
reg [9:0]    cpld_tlp_len;
reg          cpld_tlp_dlast;
reg          cpld_tlp_work;

reg [31:0]   usr_di;
reg          usr_wr;
reg          usr_rd;

reg          trn_dw_skip;
reg [1:0]    trn_dw_sel;


assign tst_o[5:0] = cpld_tlp_cnt[5:0];
assign tst_o[6] = trn_rdst_rdy_n;
assign tst_o[7] = usr_txbuf_full_i;
assign tst_o[8] = trn_dw_sel[0];
assign tst_o[9] = trn_dw_sel[1];
assign tst_o[10] = trn_dw_sel[0];
assign tst_o[11] = trn_dw_sel[1];

assign  bar_exprom =!trn_rbar_hit_n[6];
assign  bar_usr =!trn_rbar_hit_n[0] || !trn_rbar_hit_n[1];

assign usr_reg_adr_o = {{req_addr_o[5:0]},{2'b0}};

assign usr_reg_din_o = usr_txbuf_din_o;

assign usr_txbuf_din_o = {{usr_di[07:0]},
                          {usr_di[15:08]},
                          {usr_di[23:16]},
                          {usr_di[31:24]}};

assign usr_txbuf_wr_last_o = cpld_tlp_dlast;

assign usr_txbuf_wr_o = (usr_wr && cpld_tlp_work);
assign usr_reg_wr_o = (usr_wr && !cpld_tlp_work);
assign usr_reg_rd_o = usr_rd;

assign trn_rdst_rdy_n_o = trn_rdst_rdy_n || (trn_dw_sel != 0) || (usr_txbuf_full_i && cpld_tlp_work);

//Rx State Machine
always @ ( posedge clk or negedge rst_n )
begin
  if (!rst_n )
  begin
      fsm_state <= `STATE_RX_IDLE;

      trn_rdst_rdy_n <= 1'b0;

      req_compl_o <= 1'b0;
      req_exprom_o <= 1'b0;
      req_pkt_type_o <= 0;
      req_tc_o   <= 0;
      req_td_o   <= 1'b0;
      req_ep_o   <= 1'b0;
      req_attr_o <= 0;
      req_len_o  <= 0;
      req_rid_o  <= 0;
      req_tag_o  <= 0;
      req_be_o   <= 0;
      req_addr_o <= 0;

      cpld_total_size_o <= 0;
      cpld_malformed_o <= 1'b0;
      cpld_tlp_len <= 0;
      cpld_tlp_cnt <= 0;
      cpld_tlp_dlast <= 1'b0;
      cpld_tlp_work <= 1'b0;

      trn_dw_sel <= 0;
      trn_dw_skip <= 1'b0;

      usr_di <= 0;
      usr_wr <= 1'b0;
      usr_rd <= 1'b0;
  end
  else
    begin
        req_compl_o <= 1'b0;

        if (dma_init_i) //Инициализация перед началом DMA транзакции
        begin
          cpld_tlp_len <= 0;
          cpld_total_size_o <= 0;
          cpld_malformed_o <= 1'b0;
        end

        case (fsm_state)
            //#######################################################################
            //Анализ типа принятого пакета
            //#######################################################################
            `STATE_RX_IDLE :
            begin
                if (!trn_rsof_n && !trn_rsrc_rdy_n && trn_rsrc_dsc_n)
                begin
                  if (trn_rrem_n[1])
                  begin
                    case (trn_rd[62 : 56]) //поле FMT (Формат пакета) + поле TYPE (Тип пакета)
                        //-----------------------------------------------------------------------
                        //IORd - 3DW, no data (PC<-FPGA)
                        //-----------------------------------------------------------------------
                        `C_FMT_TYPE_IORD_3DW_ND :
                        begin
                          if (trn_rd[41 : 32] == 10'b1) //Length data payload (DW)
                          begin
                            req_pkt_type_o <= trn_rd[62 : 56];
                            req_tc_o       <= trn_rd[54 : 52];
                            req_td_o       <= trn_rd[47];
                            req_ep_o       <= trn_rd[46];
                            req_attr_o     <= trn_rd[45 : 44];
                            req_len_o      <= trn_rd[41 : 32]; //Length data payload (DW)
                            req_rid_o      <= trn_rd[31 : 16];
                            req_tag_o      <= trn_rd[15 :  8];
                            req_be_o       <= trn_rd[ 7 :  0];

                            fsm_state <= `STATE_RX_MRD_QW1;
                          end
                          else
                            fsm_state <= `STATE_RX_IDLE;
                        end

                        //-----------------------------------------------------------------------
                        //IOWr - 3DW, +data (PC->FPGA)
                        //-----------------------------------------------------------------------
                        `C_FMT_TYPE_IOWR_3DW_WD :
                        begin
                          if (trn_rd[41 : 32] == 10'b1) //Length data payload (DW)
                          begin
                            req_pkt_type_o <= trn_rd[62 : 56];
                            req_tc_o       <= trn_rd[54 : 52];
                            req_td_o       <= trn_rd[47];
                            req_ep_o       <= trn_rd[46];
                            req_attr_o     <= trn_rd[45 : 44];
                            req_len_o      <= trn_rd[41 : 32]; //Length data payload (DW)
                            req_rid_o      <= trn_rd[31 : 16];
                            req_tag_o      <= trn_rd[15 :  8];
                            req_be_o       <= trn_rd[ 7 :  0];

                            fsm_state <= `STATE_RX_IOWR_QW1;
                          end
                          else
                            fsm_state <= `STATE_RX_IDLE;
                        end

                        //-----------------------------------------------------------------------
                        //MWr - 3DW, +data (PC->FPGA)
                        //-----------------------------------------------------------------------
                       `C_FMT_TYPE_MWR_3DW_WD :
                        begin
                         if (trn_rd[41 : 32] == 10'b1) //Length data payload (DW)
                            fsm_state <= `STATE_RX_MWR_QW1;
                          else
                            fsm_state <= `STATE_RX_IDLE;
                        end

                        //-----------------------------------------------------------------------
                        //MRd - 3DW, no data (PC<-FPGA)
                        //-----------------------------------------------------------------------
                        `C_FMT_TYPE_MRD_3DW_ND :
                        begin
                          if (trn_rd[41 : 32] == 10'b1) //Length data payload (DW)
                          begin
                            req_pkt_type_o <= trn_rd[62 : 56];
                            req_tc_o       <= trn_rd[54 : 52];
                            req_td_o       <= trn_rd[47];
                            req_ep_o       <= trn_rd[46];
                            req_attr_o     <= trn_rd[45 : 44];
                            req_len_o      <= trn_rd[41 : 32];
                            req_rid_o      <= trn_rd[31 : 16];
                            req_tag_o      <= trn_rd[15 :  8];
                            req_be_o       <= trn_rd[ 7 :  0];

                            if (bar_exprom)
                              req_exprom_o <= 1'b1;

                            fsm_state <= `STATE_RX_MRD_QW1;
                          end
                          else
                            fsm_state <= `STATE_RX_IDLE;
                        end

                        //-----------------------------------------------------------------------
                        //Cpl - 3DW, no data
                        //-----------------------------------------------------------------------
                        `C_FMT_TYPE_CPL_3DW_ND :
                        begin
                          if (trn_rd[15 : 13] != `C_COMPLETION_STATUS_SC)
                            fsm_state <= `STATE_RX_CPL_QW1;
                          else
                            fsm_state <= `STATE_RX_IDLE;
                        end

                        //-----------------------------------------------------------------------
                        //CplD - 3DW, +data
                        //-----------------------------------------------------------------------
                        `C_FMT_TYPE_CPLD_3DW_WD :
                        begin
//                            cpld_total_size_o <= cpld_total_size_o + trn_rd[41 : 32];
//                            cpld_tlp_len <= trn_rd[41 : 32]; //Length data payload (DW)
//                            cpld_tlp_cnt <= 0;
//                            cpld_tlp_work <= 1'b1;
//                            trn_dw_sel <= 1'h1;
//                            trn_dw_skip <= 1'b1;
//                            fsm_state <= `STATE_RX_CPLD_QWN;
                            cpld_total_size_o <= cpld_total_size_o + trn_rd[41 : 32];
                            cpld_tlp_len <= trn_rd[41 : 32]; //Length data payload (DW)
                            cpld_tlp_cnt <= 0;
                            cpld_tlp_work <= 1'b1;
                            trn_dw_sel <= 2'h3;
                            trn_dw_skip <= 1'b1;
                            fsm_state <= `STATE_RX_CPLD_QWN;
                        end

                        default :
                          fsm_state <= `STATE_RX_IDLE;
                    endcase //case (trn_rd[62 : 56])
                end
                else //if (trn_rrem_n[1] == 0)
                  begin
                      case (trn_rd[62+64 : 56+64]) //поле FMT (Формат пакета) + поле TYPE (Тип пакета)
                          //-----------------------------------------------------------------------
                          //IORd - 3DW, no data (PC<-FPGA)
                          //-----------------------------------------------------------------------
                         `C_FMT_TYPE_IORD_3DW_ND :
                          begin
                            if (trn_rd[41+64 : 32+64] == 10'b1) //Length data payload (DW)
                            begin
                              req_pkt_type_o <= trn_rd[62+64 : 56+64];
                              req_tc_o       <= trn_rd[54+64 : 52+64];
                              req_td_o       <= trn_rd[47+64];
                              req_ep_o       <= trn_rd[46+64];
                              req_attr_o     <= trn_rd[45+64 : 44+64];
                              req_len_o      <= trn_rd[41+64 : 32+64]; //Length data payload (DW)
                              req_rid_o      <= trn_rd[31+64 : 16+64];
                              req_tag_o      <= trn_rd[15+64 :  8+64];
                              req_be_o       <= trn_rd[ 7+64 :  0+64];

                              req_addr_o     <= trn_rd[31+32 :  2+32];

                              trn_rdst_rdy_n <= 1'b1;

                              if (!bar_exprom)
                                if (bar_usr)
                                usr_rd <= 1'b1;
                                else
                                usr_rd <= 1'b0;

                              fsm_state <= `STATE_RX_MRD_WT1;
                            end
                            else
                              fsm_state <= `STATE_RX_IDLE;
                          end

                          //-----------------------------------------------------------------------
                          //IOWr - 3DW, +data (PC->FPGA)
                          //-----------------------------------------------------------------------
                          `C_FMT_TYPE_IOWR_3DW_WD :
                          begin
                            if (trn_rd[41+64 : 32+64] == 10'b1) //Length data payload (DW)
                            begin
                              req_pkt_type_o <= trn_rd[62+64 :56+64];
                              req_tc_o       <= trn_rd[54+64 :52+64];
                              req_td_o       <= trn_rd[47+64];
                              req_ep_o       <= trn_rd[46+64];
                              req_attr_o     <= trn_rd[45+64 :44+64];
                              req_len_o      <= trn_rd[41+64 :32+64]; //Length data payload (DW)
                              req_rid_o      <= trn_rd[31+64 :16+64];
                              req_tag_o      <= trn_rd[15+64 : 8+64];
                              req_be_o       <= trn_rd[ 7+64 : 0+64];

                              req_addr_o     <= trn_rd[31+32 : 2+32];
                              usr_di         <= trn_rd[31:0];

                              trn_rdst_rdy_n <= 1'b1;

                              if (bar_usr)
                              usr_wr <= 1'b1;
                              else
                              usr_wr <= 1'b0;

                              req_compl_o <= 1'b1;//Запрос на отправку пакета Cpl

                              fsm_state <= `STATE_RX_IOWR_WT;
                            end
                            else
                              fsm_state <= `STATE_RX_IDLE;
                          end

                          //-----------------------------------------------------------------------
                          //MRd - 3DW, no data  (PC<-FPGA)
                          //-----------------------------------------------------------------------
                          `C_FMT_TYPE_MRD_3DW_ND :
                          begin
                            if (trn_rd[41+64 : 32+64] == 10'b1) //Length data payload (DW)
                            begin
                              req_pkt_type_o <= trn_rd[62+64 : 56+64];
                              req_tc_o       <= trn_rd[54+64 : 52+64];
                              req_td_o       <= trn_rd[47+64];
                              req_ep_o       <= trn_rd[46+64];
                              req_attr_o     <= trn_rd[45+64 : 44+64];
                              req_len_o      <= trn_rd[41+64 : 32+64]; //Length data payload (DW)
                              req_rid_o      <= trn_rd[31+64 : 16+64];
                              req_tag_o      <= trn_rd[15+64 :  8+64];
                              req_be_o       <= trn_rd[ 7+64 :  0+64];

                              req_addr_o     <= trn_rd[31+32 :  2+32];

                              trn_rdst_rdy_n <= 1'b1;

                              if (bar_exprom)
                                req_exprom_o <= 1'b1;

                              if (!bar_exprom)
                                if (bar_usr)
                                usr_rd <= 1'b1;
                                else
                                usr_rd <= 1'b0;

                              fsm_state <= `STATE_RX_MRD_WT1;
                            end
                            else
                              fsm_state <= `STATE_RX_IDLE;
                          end

                          //-----------------------------------------------------------------------
                          //MWr - 3DW, +data (PC->FPGA)
                          //-----------------------------------------------------------------------
                         `C_FMT_TYPE_MWR_3DW_WD :
                          begin
                            if (trn_rd[41+64 : 32+64] == 10'b1) //Length data payload (DW)
                            begin
                              req_addr_o <= trn_rd[63 : 34];
                              usr_di <= trn_rd[31 :  0];

                              if (bar_usr)
                              usr_wr <= 1'b1;
                              else
                              usr_wr <= 1'b0;

                              fsm_state <= `STATE_RX_IDLE;
                            end
                            else
                              fsm_state <= `STATE_RX_IDLE;
                          end

                          //-----------------------------------------------------------------------
                          //Cpl - 3DW, no data
                          //-----------------------------------------------------------------------
                          `C_FMT_TYPE_CPL_3DW_ND :
                          begin
                            if (trn_rd[15+64 : 13+64] != `C_COMPLETION_STATUS_SC)
                              fsm_state <= `STATE_RX_CPL_QW1;
                            else
                              fsm_state <= `STATE_RX_IDLE;
                          end

                          //-----------------------------------------------------------------------
                          //CplD - 3DW, +data
                          //-----------------------------------------------------------------------
                          `C_FMT_TYPE_CPLD_3DW_WD :
                          begin
                              cpld_total_size_o <= cpld_total_size_o + trn_rd[41+64 : 32+64];
                              cpld_tlp_len <= trn_rd[41+64 : 32+64]; //Length data payload (DW)
                              cpld_tlp_cnt <= 10'h1;
                              cpld_tlp_work <= 1'b1;
                              trn_dw_sel <= 2'h3;
                              trn_dw_skip <= 1'b0;
                              usr_wr <= 1'b1;
                              usr_di <= trn_rd[31:0];

                              if (!trn_reof_n && (trn_rd[41+64 : 32+64] == 10'b1))
                              begin
                                cpld_tlp_dlast <= 1'b1;
                                trn_rdst_rdy_n <= 1'b1;
                                fsm_state <= `STATE_RX_CPLD_WT;
                              end
                              else
                                fsm_state <= `STATE_RX_CPLD_QWN;
                          end

                          default :
                            fsm_state <= `STATE_RX_IDLE;
                      endcase //case (trn_rd[62+64 : 56+64])
                  end //if (trn_rrem_n[1] == 0)
                end
                else
                  begin
                    usr_wr <= 1'b0;
                    fsm_state <= `STATE_RX_IDLE;
                  end //((!trn_rsof_n) && (!trn_rsrc_rdy_n) && trn_rsrc_dsc_n)
            end //`STATE_RX_IDLE :


            //#######################################################################
            //IOWr - 3DW, +data (PC->FPGA)
            //#######################################################################
            `STATE_RX_IOWR_QW1 :
            begin
                if (!trn_reof_n && !trn_rsrc_rdy_n && trn_rsrc_dsc_n)
                begin
                  req_addr_o <= trn_rd[63 : 34];
                  usr_di <= trn_rd[31 :  0];

                  if (bar_usr)
                  usr_wr <= 1'b1;
                  else
                  usr_wr <= 1'b0;

                  req_compl_o <= 1'b1;//Запрос передачи пакета Cpl
                  trn_rdst_rdy_n <= 1'b1;
                  fsm_state <= `STATE_RX_IOWR_WT;
                end
                else
                  if (!trn_rsrc_dsc_n) //Ядро прерывало прием данных
                    fsm_state <= `STATE_RX_IDLE;
                  else
                    fsm_state <= `STATE_RX_IOWR_QW1;
            end

            `STATE_RX_IOWR_WT:
            begin
                usr_wr <= 1'b0;

                if (compl_done_i) //отправка пакета Cpl завершена
                begin
                  trn_rdst_rdy_n <= 1'b0;
                  fsm_state <= `STATE_RX_IDLE;
                end
                else
                  begin
                    req_compl_o <= 1'b1;
                    trn_rdst_rdy_n <= 1'b1;
                    fsm_state <= `STATE_RX_IOWR_WT;
                  end
            end
            //END: IOWr - 3DW, +data


            //#######################################################################
            //MRd - 3DW, no data (PC<-FPGA)
            //#######################################################################
            `STATE_RX_MRD_QW1 :
            begin
                if (!trn_reof_n && !trn_rsrc_rdy_n && trn_rsrc_dsc_n)
                begin
//                  req_addr_o     <= trn_rd[63 : 34];
                  req_addr_o     <= trn_rd[63+64 : 34+64];
                  trn_rdst_rdy_n <= 1'b1;

                  if (!bar_exprom)
                    if (bar_usr)
                    usr_rd <= 1'b1;
                    else
                    usr_rd <= 1'b0;

                  fsm_state <= `STATE_RX_MRD_WT1;
                end
                else
                  if (!trn_rsrc_dsc_n) //Ядро прерывало прием данных
                    fsm_state <= `STATE_RX_IDLE;
                  else
                    fsm_state <= `STATE_RX_MRD_QW1;
            end

            `STATE_RX_MRD_WT1:
            begin
                usr_rd <= 1'b0;
                req_compl_o <= 1'b1;//Запрос передачи пакета CplD
                fsm_state <= `STATE_RX_MRD_WT;
            end

            `STATE_RX_MRD_WT:
            begin
                usr_rd <= 1'b0;

                if (compl_done_i) //отправка пакета CplD завершена
                begin
                  req_exprom_o <= 1'b0;
                  trn_rdst_rdy_n <= 1'b0;
                  fsm_state <= `STATE_RX_IDLE;
                end
                else
                  begin
                    req_compl_o    <= 1'b1;
                    trn_rdst_rdy_n <= 1'b1;
                    fsm_state <= `STATE_RX_MRD_WT;
                  end
            end
            //END: MRd - 3DW, no data


            //#######################################################################
            //MWr - 3DW, +data (PC->FPGA)
            //#######################################################################
            `STATE_RX_MWR_QW1 :
            begin
                if (!trn_reof_n && !trn_rsrc_rdy_n && trn_rsrc_dsc_n)
                begin
//                  req_addr_o <= trn_rd[63 : 34];
//                  usr_di <= trn_rd[31 :  0];
                  req_addr_o <= trn_rd[63+64 : 34+64];
                  usr_di <= trn_rd[31+64 :  0+64];

                  if (bar_usr)
                  usr_wr <= 1'b1;
                  else
                  usr_wr <= 1'b0;

                  trn_rdst_rdy_n <= 1'b1;
                  fsm_state <= `STATE_RX_MWR_WT;
                end
                else
                  if (!trn_rsrc_dsc_n) //Ядро прерывало прием данных
                    fsm_state <= `STATE_RX_IDLE;
                  else
                    fsm_state <= `STATE_RX_MWR_QW1;
            end

            `STATE_RX_MWR_WT:
            begin
                usr_wr <= 1'b0;
                trn_rdst_rdy_n <= 1'b0;
                fsm_state <= `STATE_RX_IDLE;
            end
            //END: MWr - 3DW, +data


            //#######################################################################
            //Cpl - 3DW, no data
            //#######################################################################
            `STATE_RX_CPL_QW1 :
            begin
                if (!trn_reof_n && !trn_rsrc_rdy_n && trn_rsrc_dsc_n)
                  fsm_state <= `STATE_RX_IDLE;
                else
                  if (!trn_rsrc_dsc_n) //Ядро прерывало прием данных
                    fsm_state <= `STATE_RX_IDLE;
                  else
                    fsm_state <= `STATE_RX_CPL_QW1;
            end
            //END: Cpl - 3DW, no data


            //#######################################################################
            //CplD - 3DW, +data
            //#######################################################################
            `STATE_RX_CPLD_QWN :
            begin
                if (!trn_rsrc_rdy_n && trn_rsrc_dsc_n && !usr_txbuf_full_i)
                begin
                    if (trn_dw_sel == 2'h0)
                      usr_di <= trn_rd[31:0];
                    else
                      if (trn_dw_sel == 2'h1)
                        usr_di <= trn_rd[63:32];
                      else
                        if (trn_dw_sel == 2'h2)
                          usr_di <= trn_rd[31+64 : 0+64];
                        else
                          if (trn_dw_sel == 2'h3)
                            usr_di <= trn_rd[63+64 : 32+64];

                    if (!trn_reof_n) //EOF
                    begin
                        trn_dw_sel <= trn_dw_sel - 1'b1;
                        trn_dw_skip <= 1'b0;

                        if (!trn_dw_skip)
                        begin
                          usr_wr <= 1'b1;
                          cpld_tlp_cnt <= cpld_tlp_cnt + 1'b1;
                        end
                        else
                          usr_wr <= 1'b0;

                        if (((trn_rrem_n == 4'h0) && (trn_dw_sel == 2'h0)) ||
                            ((trn_rrem_n == 4'h1) && (trn_dw_sel == 2'h1)) ||
                            ((trn_rrem_n == 4'h2) && (trn_dw_sel == 2'h2)) ||
                            ((trn_rrem_n == 4'h3) && (trn_dw_sel == 2'h3)))
                        begin
                          cpld_tlp_dlast <= 1'b1;
                          trn_rdst_rdy_n <= 1'b1;
                          fsm_state <= `STATE_RX_CPLD_WT;
                        end
                    end
                    else
                      if (trn_rsof_n)
                      begin
                          trn_dw_sel <= trn_dw_sel - 1'b1;
                          trn_dw_skip <= 1'b0;

                          if (!trn_dw_skip)
                          begin
                            usr_wr <= 1'b1;
                            cpld_tlp_cnt <= cpld_tlp_cnt + 1'b1;
                          end
                          else
                            usr_wr <= 1'b0;

                          fsm_state <= `STATE_RX_CPLD_QWN;
                      end
                      else
                        begin
                            usr_wr <= 1'b0;
                            fsm_state <= `STATE_RX_CPLD_QWN;
                        end
                end
                else
                  if (!trn_rsrc_dsc_n) //Ядро прерывало прием данных
                  begin
                      cpld_tlp_dlast <= 1'b1;
                      usr_wr <= 1'b0;
                      fsm_state <= `STATE_RX_CPLD_WT;
                  end
                  else
                    begin
                      usr_wr <= 1'b0;
                      fsm_state <= `STATE_RX_CPLD_QWN;
                    end
            end //`STATE_RX_CPLD_QWN :

            `STATE_RX_CPLD_WT:
            begin
                if (cpld_tlp_len != cpld_tlp_cnt)
                  cpld_malformed_o <= 1'b1;

                cpld_tlp_cnt <= 0;
                cpld_tlp_dlast <= 1'b0;
                cpld_tlp_work <= 1'b0;
                trn_rdst_rdy_n <= 1'b0;
                trn_dw_sel <= 0;
                usr_wr <= 1'b0;
                fsm_state <= `STATE_RX_IDLE;
            end
            //END: CplD - 3DW, +data

        endcase //case (fsm_state)
    end
end //always @


endmodule


