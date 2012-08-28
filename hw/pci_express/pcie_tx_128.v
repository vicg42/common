//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 25.08.2012 17:22:12
//-- Module Name : pcie_tx.v
//--
//-- Description : PCI core data bus 128bit
//--
//-- Revision:
//-- Revision 0.01 - File Created
//--
//-------------------------------------------------------------------------
`timescale 1ns/1ns
`include "../../../common/lib/hw/pci_express/pcie_def.v"

//Состояния автомата управления
`define STATE_TX_IDLE       4'h0 //8'b00000001 //
`define STATE_TX_CPLD_WT1   4'h1 //8'b00000010 //
`define STATE_TX_MWR_QW1    4'h2 //8'b00000100 //
`define STATE_TX_MWR_QWN    4'h3 //8'b00001000 //
`define STATE_TX_MRD_QW1    4'h4 //8'b00010000 //
//`define STATE_TX_CPLD_WT0   4'h5 //8'b00100000 //
//`define STATE_TX_MRD_QW0    4'h6 //8'b01000000 //
//`define STATE_TX_MWR_QW0    4'h7 //8'b10000000 //


module pcie_tx(
//usr app
input  [31:0]      usr_reg_dout_i,

//output [3:0]       usr_rxbuf_dbe;
input  [31:0]      usr_rxbuf_dout_i,
output             usr_rxbuf_rd_o,
output             usr_rxbuf_rd_last_o,
input              usr_rxbuf_empty_i,

//pci_core <- usr_app
output reg [127:0] trn_td,
output reg [3:0]   trn_trem_n,
output reg         trn_tsof_n,
output reg         trn_teof_n,
output             trn_tsrc_rdy_n_o, //usr_app - rdy
output             trn_tsrc_dsc_n,
input              trn_tdst_rdy_n,   //pci_core - rdy
input              trn_tdst_dsc_n,
input  [5:0]       trn_tbuf_av,

//Handshake with Rx engine
input              req_compl_i,
output reg         compl_done_o,

input  [29:0]      req_addr_i,
input  [6:0]       req_pkt_type_i,
input  [2:0]       req_tc_i,
input              req_td_i,
input              req_ep_i,
input  [1:0]       req_attr_i,
input  [9:0]       req_len_i,
input  [15:0]      req_rid_i,
input  [7:0]       req_tag_i,
input  [7:0]       req_be_i,
input              req_exprom_i,

//dma trn
input              dma_init_i,

input              mwr_en_i,
input  [31:0]      mwr_len_i,
input  [7:0]       mwr_tag_i,
input  [3:0]       mwr_lbe_i,
input  [3:0]       mwr_fbe_i,
input  [31:0]      mwr_addr_i,
input  [31:0]      mwr_count_i,
output reg         mwr_done_o,
input  [2:0]       mwr_tlp_tc_i,
input              mwr_64b_en_i,
input              mwr_phant_func_en1_i,
input  [7:0]       mwr_addr_up_i,
input              mwr_relaxed_order_i,
input              mwr_nosnoop_i,

input              mrd_en_i,
input  [31:0]      mrd_len_i,
input  [7:0]       mrd_tag_i,
input  [3:0]       mrd_lbe_i,
input  [3:0]       mrd_fbe_i,
input  [31:0]      mrd_addr_i,
input  [31:0]      mrd_count_i,
input  [2:0]       mrd_tlp_tc_i,
input              mrd_64b_en_i,
input              mrd_phant_func_en1_i,
input  [7:0]       mrd_addr_up_i,
input              mrd_relaxed_order_i,
input              mrd_nosnoop_i,
output [31:0]      mrd_pkt_len_o,
output reg [15:0]  mrd_pkt_count_o, //Кол-во отправленых пакетов MRr

input  [15:0]      completer_id_i,
input              tag_ext_en_i,
input              master_en_i,
input  [2:0]       max_payload_size_i,
input  [2:0]       max_rd_req_size_i,

//Технологический
output [31:0]      tst_o,
input  [31:0]      tst_i,

//System
input              clk,
input              rst_n
);

//---------------------------------------------
// Local registers/wire
//---------------------------------------------
reg          trn_tsrc_rdy_n;

reg [11:0]   byte_count;
reg [6:0]    lower_addr;

reg [3:0]    fsm_state;

reg          sr_req_compl;

reg [7:0]    mwr_addr_up_req;
reg [31:0]   mwr_addr_req;
reg [3:0]    mwr_fbe;
reg [3:0]    mwr_lbe;
reg [3:0]    mwr_fbe_req;
reg [3:0]    mwr_lbe_req;
reg [31:0]   pmwr_addr;        //Указатель адреса записи данных в память хоста
reg [31:0]   tmwr_addr;
reg [15:0]   mwr_pkt_count_req;//Кол-во пакетов MWr которые необходимо отправить PC
reg [15:0]   mwr_pkt_count;    //Кол-во отправленых пакетов MWr
reg [12:0]   mwr_len_byte;     //Размер одного пакета MWr в байт (учавствует в вычислении pmwr_addr)
reg [10:0]   mwr_len_dw_req;
reg [10:0]   mwr_len_dw;       //Сколько DW осталось отправить в текущем пакете.

reg [7:0]    mrd_addr_up_req;
reg [31:0]   mrd_addr_req;
reg          mrd_done;
reg [3:0]    mrd_fbe;
reg [3:0]    mrd_lbe;
reg [3:0]    mrd_fbe_req;
reg [3:0]    mrd_lbe_req;
reg [31:0]   pmrd_addr;        //Указатель адреса чтения данных памяти PC
reg [31:0]   tmrd_addr;
reg [15:0]   mrd_pkt_count_req;//Кол-во пакетов MRd которые необходимо отправить PC
reg [15:0]   mrd_pkt_count;    //Кол-во отправлены пакетов MRr (запрос чтения)
reg [12:0]   mrd_len_byte;     //Размер одного пакета MRd в байт (учавствует в вычислении pmrd_addr)
reg [10:0]   mrd_len_dw_req;
reg [10:0]   mrd_len_dw;

reg          mwr_work;
reg [1:0]    trn_dw_sel;

assign trn_tsrc_dsc_n = 1'b1;

assign mrd_pkt_len_o = {21'b0, mrd_len_dw};

assign usr_rxbuf_rd_o = (!trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE] && !usr_rxbuf_empty_i) && mwr_work;

assign usr_rxbuf_rd_last_o = usr_rxbuf_rd_o && (mwr_len_dw == 11'h1);

assign trn_tsrc_rdy_n_o = trn_tsrc_rdy_n || (trn_dw_sel != 0) || (usr_rxbuf_empty_i && mwr_work);

always @ ( posedge clk or negedge rst_n )
begin
  if (!rst_n )
    sr_req_compl <= 1'b0;
  else
    sr_req_compl <= req_compl_i;
end

//Calculate byte count based on byte enable
always @ (req_be_i)
begin
  casex (req_be_i[3:0])
    4'b1xx1 : byte_count = 12'h004;
    4'b01x1 : byte_count = 12'h003;
    4'b1x10 : byte_count = 12'h003;
    4'b0011 : byte_count = 12'h002;
    4'b0110 : byte_count = 12'h002;
    4'b1100 : byte_count = 12'h002;
    4'b0001 : byte_count = 12'h001;
    4'b0010 : byte_count = 12'h001;
    4'b0100 : byte_count = 12'h001;
    4'b1000 : byte_count = 12'h001;
    4'b0000 : byte_count = 12'h001;
  endcase
end

//Calculate lower address based on  byte enable
always @ (req_be_i or req_addr_i)
begin
  casex (req_be_i[3:0])
    4'b0000 : lower_addr = {req_addr_i[4:0], 2'b00};
    4'bxxx1 : lower_addr = {req_addr_i[4:0], 2'b00};
    4'bxx10 : lower_addr = {req_addr_i[4:0], 2'b01};
    4'bx100 : lower_addr = {req_addr_i[4:0], 2'b10};
    4'b1000 : lower_addr = {req_addr_i[4:0], 2'b11};
  endcase
end

//Tx State Machine
always @ ( posedge clk or negedge rst_n )
begin
  if (!rst_n )
  begin
      trn_tsof_n     <= 1'b1;
      trn_teof_n     <= 1'b1;
      trn_tsrc_rdy_n <= 1'b1;
      trn_td         <= 0;
      trn_trem_n     <= 0;

      mwr_addr_up_req   <= 0;
      mwr_addr_req      <= 0;
      mwr_done_o        <= 1'b0;
      mwr_pkt_count_req <= 0;
      mwr_pkt_count     <= 0;
      mwr_len_byte      <= 0;
      mwr_len_dw_req    <= 0;
      mwr_len_dw        <= 0;
      pmwr_addr         <= 0;
      mwr_fbe_req       <= 0;
      mwr_lbe_req       <= 0;
      mwr_fbe           <= 0;
      mwr_lbe           <= 0;

      mrd_addr_up_req   <= 0;
      mrd_addr_req      <= 0;
      mrd_done          <= 1'b0;
      mrd_pkt_count_req <= 0;
      mrd_pkt_count     <= 0;
      mrd_len_byte      <= 0;
      pmrd_addr         <= 0;
      mrd_len_dw_req    <= 0;
      mrd_len_dw        <= 0;
      mrd_fbe_req       <= 0;
      mrd_lbe_req       <= 0;
      mrd_fbe           <= 0;
      mrd_lbe           <= 0;
      mrd_pkt_count_o   <= 16'b1;

      compl_done_o <= 1'b0;
      trn_dw_sel <= 0;
      mwr_work <= 1'b0;

      fsm_state <= `STATE_TX_IDLE;
  end
  else
    begin
        if (dma_init_i) //Инициализация перед началом DMA транзакции
        begin
            mwr_addr_up_req   <= mwr_addr_up_i;
            mwr_addr_req      <= mwr_addr_i;
            mwr_done_o        <= 1'b0;
            mwr_pkt_count_req <= mwr_count_i[15:0];
            mwr_pkt_count     <= 0;
            mwr_len_byte      <= 0;
            mwr_len_dw_req    <= mwr_len_i[10:0];
            mwr_len_dw        <= 0;
            pmwr_addr         <= 0;
            mwr_fbe_req       <= mwr_fbe_i;
            mwr_lbe_req       <= mwr_lbe_i;
            mwr_fbe           <= 0;
            mwr_lbe           <= 0;

            mrd_addr_up_req   <= mrd_addr_up_i;
            mrd_addr_req      <= mrd_addr_i;
            mrd_done          <= 1'b0;
            mrd_pkt_count_req <= mrd_count_i[15:0];
            mrd_pkt_count     <= 0;
            mrd_len_byte      <= 0;
            pmrd_addr         <= 0;
            mrd_len_dw_req    <= mrd_len_i[10:0];
            mrd_fbe_req       <= mrd_fbe_i;
            mrd_lbe_req       <= mrd_lbe_i;
            mrd_fbe           <= 0;
            mrd_lbe           <= 0;
            mrd_pkt_count_o   <= 16'b1;

            if ((mrd_count_i - 1'b1) == 16'b0)
              mrd_len_dw[10:0] <= mrd_len_i[10:0];
            else
            begin
              if      (max_rd_req_size_i == `C_MAX_READ_REQ_SIZE_1024_BYTE) mrd_len_dw <= 11'h100;
              else if (max_rd_req_size_i == `C_MAX_READ_REQ_SIZE_512_BYTE)  mrd_len_dw <= 11'h80;
              else if (max_rd_req_size_i == `C_MAX_READ_REQ_SIZE_256_BYTE)  mrd_len_dw <= 11'h40;
              else                                                          mrd_len_dw <= 11'h20;
            end

            mwr_work <= 1'b0;
            trn_dw_sel <= 0;
        end

        case (fsm_state)
            //#######################################################################
            //
            //#######################################################################
            `STATE_TX_IDLE :
            begin
                //-----------------------------------------------------
                //CplD - 3DW, +data;  Cpl - 3DW
                //-----------------------------------------------------
                if ((!trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_COMPLETION_QUEUE]) &&
                    sr_req_compl && !compl_done_o)
                begin
                    trn_tsof_n     <= 1'b0;
                    trn_teof_n     <= 1'b0;
                    trn_tsrc_rdy_n <= 1'b0;
                    trn_trem_n     <= ((req_pkt_type_i == `C_FMT_TYPE_IORD_3DW_ND) ||
                                       (req_pkt_type_i == `C_FMT_TYPE_MRD_3DW_ND)) ? 0 : 4'h01;

                    trn_td <= {{1'b0},         //Reserved
                               {((req_pkt_type_i == `C_FMT_TYPE_IORD_3DW_ND) ||
                                 (req_pkt_type_i == `C_FMT_TYPE_MRD_3DW_ND)) ? `C_FMT_TYPE_CPLD_3DW_WD : `C_FMT_TYPE_CPL_3DW_ND},
                               {1'b0},         //Reserved
                                req_tc_i,      //TC (Traffic Class)
                               {4'b0},         //Reserved
                                req_td_i,      //TD (TLP Digest Field present)
                                req_ep_i,      //EP (Poisend Data)
                                req_attr_i,    //Attr (Attributes)
                               {2'b0},         //Reserved
                                req_len_i,     //Length data payload (DW)
                                completer_id_i,
                               {3'b0},         //CS (Completion Status Code)
                               {1'b0},         //BCM (Byte Count Modified)
                               byte_count,
                               req_rid_i,
                               req_tag_i,
                               {1'b0},          //Reserved
                               lower_addr,
                               {req_exprom_i ? 32'b0 : {usr_reg_dout_i[07:00],
                                                        usr_reg_dout_i[15:08],
                                                        usr_reg_dout_i[23:16],
                                                        usr_reg_dout_i[31:24]}}
                               };

                    compl_done_o <= 1'b1;
                    fsm_state <= `STATE_TX_CPLD_WT1;
//                    trn_tsof_n     <= 1'b0;
//                    trn_teof_n     <= 1'b1;
//                    trn_tsrc_rdy_n <= 1'b0;
//                    trn_trem_n     <= 0;
//
//                    trn_td <= {{1'b0},         //Reserved
//                               {((req_pkt_type_i == `C_FMT_TYPE_IORD_3DW_ND) ||
//                                 (req_pkt_type_i == `C_FMT_TYPE_MRD_3DW_ND)) ? `C_FMT_TYPE_CPLD_3DW_WD : `C_FMT_TYPE_CPL_3DW_ND},
//                               {1'b0},         //Reserved
//                                req_tc_i,      //TC (Traffic Class)
//                               {4'b0},         //Reserved
//                                req_td_i,      //TD (TLP Digest Field present)
//                                req_ep_i,      //EP (Poisend Data)
//                                req_attr_i,    //Attr (Attributes)
//                               {2'b0},         //Reserved
//                                req_len_i,     //Length data payload (DW)
//                                completer_id_i,
//                               {3'b0},         //CS (Completion Status Code)
//                               {1'b0},         //BCM (Byte Count Modified)
//                               byte_count
//                               };
//
//                    compl_done_o <= 1'b0;
//                    fsm_state <= `STATE_TX_CPLD_WT0;
                end
                else
                  //-----------------------------------------------------
                  //MWr - 3DW, +data (PC<-FPGA) FPGA is PCIe master
                  //-----------------------------------------------------
                  if ((!trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE] && !usr_rxbuf_empty_i) &&
                      !sr_req_compl && !compl_done_o &&
                      mwr_en_i && !mwr_done_o && master_en_i)
                  begin
                      if (mwr_pkt_count == (mwr_pkt_count_req - 1'b1))
                      begin
                        mwr_len_dw[10:0] <= mwr_len_dw_req[10:0];
                        mwr_fbe <= mwr_fbe_req;
                        mwr_lbe <= mwr_lbe_req;
                      end
                      else
                        begin
                          mwr_fbe <=4'hF;
                          mwr_lbe <=4'hF;

                          if      (max_payload_size_i == `C_MAX_PAYLOAD_SIZE_1024_BYTE) mwr_len_dw <= 11'h100;
                          else if (max_payload_size_i == `C_MAX_PAYLOAD_SIZE_512_BYTE)  mwr_len_dw <= 11'h80;
                          else if (max_payload_size_i == `C_MAX_PAYLOAD_SIZE_256_BYTE)  mwr_len_dw <= 11'h40;
                          else                                                          mwr_len_dw <= 11'h20;
                        end

                      if      (max_payload_size_i == `C_MAX_PAYLOAD_SIZE_1024_BYTE) mwr_len_byte <= 13'h400;//4 * mwr_len_dw;
                      else if (max_payload_size_i == `C_MAX_PAYLOAD_SIZE_512_BYTE)  mwr_len_byte <= 13'h200;//4 * mwr_len_dw
                      else if (max_payload_size_i == `C_MAX_PAYLOAD_SIZE_256_BYTE)  mwr_len_byte <= 13'h100;//4 * mwr_len_dw
                      else                                                          mwr_len_byte <= 13'h80; //4 * mwr_len_dw

                      trn_tsof_n     <= 1'b1;
                      trn_teof_n     <= 1'b1;
                      trn_tsrc_rdy_n <= 1'b1;
                      trn_trem_n     <= 0;
                      mwr_work <= 1'b1;
                      fsm_state <= `STATE_TX_MWR_QW1;
//                      trn_tsof_n     <= 1'b1;
//                      trn_teof_n     <= 1'b1;
//                      trn_tsrc_rdy_n <= 1'b1;
//                      trn_trem_n     <= 0;
//                      fsm_state <= `STATE_TX_MWR_QW0;
                  end
                  else
                    //-----------------------------------------------------
                    //MRd - 3DW, no data (PC<-FPGA) FPGA is PCIe master
                    //-----------------------------------------------------
                    if ((!trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_NON_POSTED_QUEUE]) &&
                        !sr_req_compl && !compl_done_o &&
                        mrd_en_i && !mrd_done && master_en_i)
                    begin
                        if (mrd_pkt_count == (mrd_pkt_count_req - 1'b1))
                        begin
                          mrd_len_dw[10:0] <= mrd_len_dw_req[10:0];
                          mrd_fbe <= mrd_fbe_req;
                          mrd_lbe <= mrd_lbe_req;
                        end
                        else
                          begin
                            mrd_fbe <= 4'hF;
                            mrd_lbe <= 4'hF;

                            if      (max_rd_req_size_i == `C_MAX_READ_REQ_SIZE_1024_BYTE) mrd_len_dw <= 11'h100;
                            else if (max_rd_req_size_i == `C_MAX_READ_REQ_SIZE_512_BYTE)  mrd_len_dw <= 11'h80;
                            else if (max_rd_req_size_i == `C_MAX_READ_REQ_SIZE_256_BYTE)  mrd_len_dw <= 11'h40;
                            else                                                          mrd_len_dw <= 11'h20;
                          end

                        if      (max_rd_req_size_i == `C_MAX_READ_REQ_SIZE_1024_BYTE) mrd_len_byte <= 13'h400;//4 * mrd_len_dw;
                        else if (max_rd_req_size_i == `C_MAX_READ_REQ_SIZE_512_BYTE)  mrd_len_byte <= 13'h200;//4 * mrd_len_dw
                        else if (max_rd_req_size_i == `C_MAX_READ_REQ_SIZE_256_BYTE)  mrd_len_byte <= 13'h100;//4 * mrd_len_dw
                        else                                                          mrd_len_byte <= 13'h80; //4 * mrd_len_dw

                        trn_tsof_n     <= 1'b1;
                        trn_teof_n     <= 1'b1;
                        trn_tsrc_rdy_n <= 1'b1;
                        trn_trem_n     <= 0;
                        fsm_state <= `STATE_TX_MRD_QW1;
//                        trn_tsof_n     <= 1'b1;
//                        trn_teof_n     <= 1'b1;
//                        trn_tsrc_rdy_n <= 1'b1;
//                        trn_trem_n     <= 0;
//                        fsm_state <= `STATE_TX_MRD_QW0;
                    end
                    else
                      begin
                        if(!trn_tdst_rdy_n)
                        begin
                            trn_tsof_n     <= 1'b1;
                            trn_teof_n     <= 1'b1;
                            trn_tsrc_rdy_n <= 1'b1;
                            trn_trem_n     <= 0;
                        end
                        compl_done_o <= 1'b0;
                        fsm_state <= `STATE_TX_IDLE;
                      end
            end //`STATE_TX_IDLE :


            //#######################################################################
            //CplD - 3DW, +data;  Cpl - 3DW (PC<-FPGA)
            //#######################################################################
//            `STATE_TX_CPLD_WT0 :
//            begin
//                if (!trn_tdst_rdy_n && trn_tdst_dsc_n)
//                begin
//                    trn_tsof_n     <= 1'b1;
//                    trn_teof_n     <= 1'b0;
//                    trn_tsrc_rdy_n <= 1'b0;
//                    trn_trem_n     <= ((req_pkt_type_i == `C_FMT_TYPE_IORD_3DW_ND) ||
//                                       (req_pkt_type_i == `C_FMT_TYPE_MRD_3DW_ND)) ? 0 : 4'h1;
//
//                    trn_td <= {req_rid_i,
//                               req_tag_i,
//                               {1'b0},          //Reserved
//                               lower_addr,
//                               {req_exprom_i ? 32'b0 : {usr_reg_dout_i[07:00],
//                                                        usr_reg_dout_i[15:08],
//                                                        usr_reg_dout_i[23:16],
//                                                        usr_reg_dout_i[31:24]}}
//                               };
//
//                    compl_done_o <= 1'b1;
//                    fsm_state <= `STATE_TX_CPLD_WT1;
//                end
//                else
//                  if (!trn_tdst_dsc_n) //Ядро прерывало передачу данных
//                    fsm_state <= `STATE_TX_CPLD_WT1;
//                  else
//                    fsm_state <= `STATE_TX_CPLD_WT0;
//            end

            `STATE_TX_CPLD_WT1 :
            begin
                if (!trn_tdst_rdy_n || !trn_tdst_dsc_n)
                begin
                    trn_tsof_n     <= 1'b1;
                    trn_teof_n     <= 1'b1;
                    trn_tsrc_rdy_n <= 1'b1;

                    fsm_state <= `STATE_TX_IDLE;
                end
                else
                  fsm_state <= `STATE_TX_CPLD_WT1;
            end
            //END: CplD - 3DW, +data;  Cpl - 3DW


            //#######################################################################
            //MWr - 3DW, +data (PC<-FPGA) FPGA is PCIe master
            //#######################################################################
//            `STATE_TX_MWR_QW0 :
//            begin
//                if (!trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE] && !usr_rxbuf_empty_i)
//                begin
//                    trn_tsof_n     <= 1'b0;
//                    trn_teof_n     <= 1'b1;
//                    trn_tsrc_rdy_n <= 1'b0;
//                    trn_trem_n     <= 0;
//
//                    trn_td <= {{1'b0},          //Reserved
//                               {mwr_64b_en_i ? `C_FMT_TYPE_MWR_4DW_WD : `C_FMT_TYPE_MWR_3DW_WD},
//                               {1'b0},          //Reserved
//                               mwr_tlp_tc_i,    //TC (Traffic Class)
//                               {4'b0},          //Reserved
//                               1'b0,            //TD (TLP Digest Field present)
//                               1'b0,            //EP (Poisend Data)
//                               {mwr_relaxed_order_i, mwr_nosnoop_i}, //Attr (Attributes)
//                               {2'b0},          //Reserved
//                               mwr_len_dw[9:0], //Length data payload (DW)
//                               {completer_id_i[15:3], mwr_phant_func_en1_i, 2'b00},
//                               {tag_ext_en_i ? mwr_pkt_count[7:0] : {3'b0, mwr_pkt_count[4:0]}},
//                               {mwr_lbe, mwr_fbe}
//                               };
//
//                    mwr_work <= 1'b1;
//                    fsm_state <= `STATE_TX_MWR_QW1;
//                end
//                else
//                  if (!trn_tdst_dsc_n) //Ядро прерывало передачу данных
//                  begin
//                      mwr_work <= 1'b0;
//                      fsm_state <= `STATE_TX_IDLE;
//                  end
//                  else
//                    fsm_state <= `STATE_TX_MWR_QW0;
//            end //`STATE_TX_MWR_QW0 :

            `STATE_TX_MWR_QW1 :
            begin
                if (!trn_tdst_rdy_n && trn_tdst_dsc_n && !usr_rxbuf_empty_i && trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE])
                begin
                    if (mwr_pkt_count == 0)
                      tmwr_addr = mwr_addr_req;
                    else
                      tmwr_addr = pmwr_addr + mwr_len_byte;

                    trn_tsof_n     <= 1'b0;
                    //trn_teof_n     <= 1'b1;
                    //trn_tsrc_rdy_n <= 1'b0;
                    trn_trem_n     <= 0;

                    trn_td <= {{1'b0},          //Reserved
                               {mwr_64b_en_i ? `C_FMT_TYPE_MWR_4DW_WD : `C_FMT_TYPE_MWR_3DW_WD},
                               {1'b0},          //Reserved
                               mwr_tlp_tc_i,    //TC (Traffic Class)
                               {4'b0},          //Reserved
                               1'b0,            //TD (TLP Digest Field present)
                               1'b0,            //EP (Poisend Data)
                               {mwr_relaxed_order_i, mwr_nosnoop_i}, //Attr (Attributes)
                               {2'b0},          //Reserved
                               mwr_len_dw[9:0], //Length data payload (DW)
                               {completer_id_i[15:3], mwr_phant_func_en1_i, 2'b00},
                               {tag_ext_en_i ? mwr_pkt_count[7:0] : {3'b0, mwr_pkt_count[4:0]}},
                               {mwr_lbe, mwr_fbe},

                               {mwr_64b_en_i ? {{24'b0}, mrd_addr_up_req} : {tmwr_addr[31:2], {2'b00}} }, //Начальный адрес записи в память хоста
                               {mwr_64b_en_i ? {tmrd_addr[31:2], {2'b0}}  : {usr_rxbuf_dout_i[07:00],
                                                                             usr_rxbuf_dout_i[15:08],
                                                                             usr_rxbuf_dout_i[23:16],
                                                                             usr_rxbuf_dout_i[31:24]}}
                               };
//                    trn_tsof_n     <= 1'b1;
//                    //trn_teof_n     <= 1'b1;
//                    //trn_tsrc_rdy_n <= 1'b0;
//                    trn_trem_n     <= 0;
//
//                    trn_td <= {{mwr_64b_en_i ? {{24'b0}, mrd_addr_up_req} : {tmwr_addr[31:2], {2'b00}} }, //Начальный адрес записи в память хоста
//                               {mwr_64b_en_i ? {tmrd_addr[31:2], {2'b0}}  : {usr_rxbuf_dout_i[07:00],
//                                                                             usr_rxbuf_dout_i[15:08],
//                                                                             usr_rxbuf_dout_i[23:16],
//                                                                             usr_rxbuf_dout_i[31:24]}}
//                               };

                    pmwr_addr<= tmwr_addr;

                    //Счетчик DW(payload) в текущем пакете MWr
                    if (mwr_len_dw == 11'h1)
                    begin
                        trn_teof_n <= 1'b0;
                        trn_tsrc_rdy_n <= 1'b0;
                        trn_dw_sel <= 0;

                        mwr_work <= 1'b0;

                        //Счетчик отправленых пакетов MWr
                        if (mwr_pkt_count == (mwr_pkt_count_req - 1'b1))
                        begin
                          mwr_done_o <= 1'b1; //Транзакция завершена
                          mwr_pkt_count <= 0;
                        end
                        else
                          mwr_pkt_count <= mwr_pkt_count + 1'b1;

                        fsm_state <= `STATE_TX_IDLE;
                    end
                    else
                      begin
                          trn_teof_n <= 1'b1;
                          trn_tsrc_rdy_n <= 1'b0;
                          trn_dw_sel <= 0;

                          mwr_work <= 1'b1;
                          mwr_len_dw <= mwr_len_dw - 1'h1;

                          fsm_state <= `STATE_TX_MWR_QWN;
                      end
                end
                else
                  if (!trn_tdst_dsc_n) //Ядро прерывало передачу данных
                  begin
//                      trn_teof_n <= 1'b0;
                      trn_dw_sel <= 0;
                      mwr_work <= 1'b0;
                      fsm_state <= `STATE_TX_IDLE;
//                      trn_teof_n <= 1'b0;
//                      trn_dw_sel <= 0;
//                      mwr_work <= 1'b0;
//                      fsm_state <= `STATE_TX_IDLE;
                  end
                  else
                    fsm_state <= `STATE_TX_MWR_QW1;
            end //`STATE_TX_MWR_QW1 :

            `STATE_TX_MWR_QWN :
            begin
                if (!trn_tdst_rdy_n && trn_tdst_dsc_n && !usr_rxbuf_empty_i && trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE])
                begin
                    if (trn_dw_sel == 2'h1)
                    begin
                      trn_trem_n <= 4'h0;
                      trn_td[31:0] <= {usr_rxbuf_dout_i[ 7: 0],
                                       usr_rxbuf_dout_i[15: 8],
                                       usr_rxbuf_dout_i[23:16],
                                       usr_rxbuf_dout_i[31:24]};
                    end
                    else
                      if (trn_dw_sel == 2'h2)
                      begin
                        trn_trem_n <= 4'h1;
                        trn_td[63:32] <= {usr_rxbuf_dout_i[ 7: 0],
                                          usr_rxbuf_dout_i[15: 8],
                                          usr_rxbuf_dout_i[23:16],
                                          usr_rxbuf_dout_i[31:24]};
                      end
                      else
                        if (trn_dw_sel == 2'h3)
                        begin
                          trn_trem_n <= 4'h2;
                          trn_td[31+64 : 0+64] <= {usr_rxbuf_dout_i[ 7: 0],
                                                   usr_rxbuf_dout_i[15: 8],
                                                   usr_rxbuf_dout_i[23:16],
                                                   usr_rxbuf_dout_i[31:24]};
                        end
                        else
                          if (trn_dw_sel == 4'h0)
                          begin
                            trn_trem_n <= 2'h3;
                            trn_td[63+64 : 32+64] <= {usr_rxbuf_dout_i[ 7: 0],
                                                      usr_rxbuf_dout_i[15: 8],
                                                      usr_rxbuf_dout_i[23:16],
                                                      usr_rxbuf_dout_i[31:24]};
                          end
//                    if (trn_dw_sel == 1'h1)
//                    begin
//                      trn_trem_n <= 4'h0;
//                      trn_td[31:0] <= {usr_rxbuf_dout_i[ 7: 0],
//                                       usr_rxbuf_dout_i[15: 8],
//                                       usr_rxbuf_dout_i[23:16],
//                                       usr_rxbuf_dout_i[31:24]};
//                    end
//                    else
//                      if (trn_dw_sel == 1'h0)
//                      begin
//                        trn_trem_n <= 4'h1;
//                        trn_td[63:32] <= {usr_rxbuf_dout_i[ 7: 0],
//                                          usr_rxbuf_dout_i[15: 8],
//                                          usr_rxbuf_dout_i[23:16],
//                                          usr_rxbuf_dout_i[31:24]};
//                      end

                    //Счетчик DW(payload) в текущем пакете MWr
                    if (mwr_len_dw == 11'h1)
                    begin
                        trn_tsof_n     <= 1'b1;
                        trn_teof_n     <= 1'b0;
                        trn_tsrc_rdy_n <= 1'b0;

                        trn_dw_sel <= 0;
                        mwr_work <= 1'b0;

                        //Счетчик отправленых пакетов MWr
                        if (mwr_pkt_count == (mwr_pkt_count_req - 1'b1))
                        begin
                          mwr_pkt_count <= 0;
                          mwr_done_o <= 1'b1; //Транзакция завершена
                        end
                        else
                          mwr_pkt_count <= mwr_pkt_count + 1'b1;

                        fsm_state <= `STATE_TX_IDLE;
                    end
                    else
                      begin
                          trn_tsof_n     <= 1'b1;
                          trn_teof_n     <= 1'b1;
                          trn_tsrc_rdy_n <= 1'b0;

                          trn_dw_sel <= trn_dw_sel - 1'b1;
                          mwr_len_dw <= mwr_len_dw - 1'h1;

                          fsm_state <= `STATE_TX_MWR_QWN;
                      end
                end
                else
                  if (!trn_tdst_dsc_n) //Ядро прерывало передачу данных
                  begin
                      trn_tsof_n <= 1'b1;
                      trn_teof_n <= 1'b0;
                      trn_dw_sel <= 0;
                      mwr_work <= 1'b0;

                      fsm_state <= `STATE_TX_IDLE;
                  end
                  else
                    fsm_state <= `STATE_TX_MWR_QWN;

            end //`STATE_TX_MWR_QWN :
            //END: MWr - 3DW, +data


            //#######################################################################
            //MRd - 3DW, no data  (PC<-FPGA) (запрос записи в память PC)
            //#######################################################################
//            `STATE_TX_MRD_QW0 :
//            begin
//                if (!trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_NON_POSTED_QUEUE])
//                begin
//                    trn_tsof_n     <= 1'b0;
//                    trn_teof_n     <= 1'b1;
//                    trn_tsrc_rdy_n <= 1'b0;
//                    trn_trem_n     <= 0;
//
//                    trn_td <= {{1'b0},          //Reserved
//                               {mrd_64b_en_i ? `C_FMT_TYPE_MRD_4DW_ND : `C_FMT_TYPE_MRD_3DW_ND},
//                               {1'b0},          //Reserved
//                               mrd_tlp_tc_i,    //TC (Traffic Class)
//                               {4'b0},          //Reserved
//                               1'b0,            //TD (TLP Digest Field present)
//                               1'b0,            //EP (Poisend Data)
//                               {mrd_relaxed_order_i, mrd_nosnoop_i}, //Attr (Attributes)
//                               {2'b0},          //Reserved
//                               mrd_len_dw[9:0], //Length data payload (DW)
//                               {completer_id_i[15:3], mrd_phant_func_en1_i, 2'b00},
//                               {tag_ext_en_i ? mrd_pkt_count[7:0] : {3'b0, mrd_pkt_count[4:0]}},
//                               {mrd_lbe, mrd_fbe}
//                               };
//
//                    fsm_state <= `STATE_TX_MRD_QW1;
//                end
//                else
//                  if (!trn_tdst_dsc_n) //Ядро прерывало передачу данных
//                    fsm_state <= `STATE_TX_IDLE;
//                  else
//                    fsm_state <= `STATE_TX_MRD_QW0;
//            end //`STATE_TX_MRD_QW0 :

            `STATE_TX_MRD_QW1 :
            begin
                if (!trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_NON_POSTED_QUEUE])
                begin
                    if (mrd_pkt_count == 0)
                      tmrd_addr = mrd_addr_req;
                    else
                      tmrd_addr = pmrd_addr + mrd_len_byte;

                    pmrd_addr <= tmrd_addr;

                    trn_tsof_n     <= 1'b0;
                    trn_teof_n     <= 1'b0;
                    trn_tsrc_rdy_n <= 1'b0;
                    trn_trem_n     <= mrd_64b_en_i ? 0 : 4'h1;

                    trn_td <= {{1'b0},          //Reserved
                               {mrd_64b_en_i ? `C_FMT_TYPE_MRD_4DW_ND : `C_FMT_TYPE_MRD_3DW_ND},
                               {1'b0},          //Reserved
                               mrd_tlp_tc_i,    //TC (Traffic Class)
                               {4'b0},          //Reserved
                               1'b0,            //TD (TLP Digest Field present)
                               1'b0,            //EP (Poisend Data)
                               {mrd_relaxed_order_i, mrd_nosnoop_i}, //Attr (Attributes)
                               {2'b0},          //Reserved
                               mrd_len_dw[9:0], //Length data payload (DW)
                               {completer_id_i[15:3], mrd_phant_func_en1_i, 2'b00},
                               {tag_ext_en_i ? mrd_pkt_count[7:0] : {3'b0, mrd_pkt_count[4:0]}},
                               {mrd_lbe, mrd_fbe},

                               {mrd_64b_en_i ? {{24'b0}, mrd_addr_up_req, tmrd_addr[31:2], {2'b0}} :
                                               {tmrd_addr[31:2], {2'b00}, {32'b0}} }
                               };
//                    trn_tsof_n     <= 1'b1;
//                    trn_teof_n     <= 1'b0;
//                    trn_tsrc_rdy_n <= 1'b0;
//                    trn_trem_n     <= mrd_64b_en_i ? 0 : 4'h1;
//
//                    trn_td <= {{mrd_64b_en_i ? {{24'b0}, mrd_addr_up_req, tmrd_addr[31:2], {2'b0}} :
//                                               {tmrd_addr[31:2], {2'b00}, {32'b0}} }
//                               };

                    //Счетчик отправленых пакетов MRd
                    if (mrd_pkt_count == (mrd_pkt_count_req - 1'b1))
                    begin
                        mrd_done <= 1'b1; //Транзакция завершена (запрет генерации запросов MRd)
                        mrd_pkt_count <= 0;
                        mrd_pkt_count_o <= 0;
                    end
                    else
                      begin
                          mrd_pkt_count <= mrd_pkt_count + 1'b1;
                          mrd_pkt_count_o <= mrd_pkt_count_o + 1'b1;
                      end

                    fsm_state <= `STATE_TX_IDLE;
                end
                else
                  if (!trn_tdst_dsc_n) //Ядро прерывало передачу данных
                  begin
//                    trn_teof_n     <= 1'b0;
                    fsm_state <= `STATE_TX_IDLE;
//                    trn_teof_n     <= 1'b0;
//                    fsm_state <= `STATE_TX_IDLE;
                  end
                  else
                    fsm_state <= `STATE_TX_MRD_QW1;
            end //`STATE_TX_MRD_QW1 :
            //END: MRd - 3DW, no data

        endcase //case (fsm_state)
    end
end //always @


endmodule
