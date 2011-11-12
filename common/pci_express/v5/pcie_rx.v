//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 11/11/2009
//-- Module Name : pcie_rx.v
//--
//-- Description : Local-Link Receive Unit.
//--               Модуль приема и обработки пакетов уровня TPL PCI-Express
//--
//-- Revision:
//-- Revision 0.01 - File Created
//--
//-------------------------------------------------------------------------
`timescale 1ns/1ns
`include "../../../common/veresk_m/pci_express/define/def_pciexpress.v"

//Состояния автомата управления
`define STATE_RX_RST            4'b0000 //4'h00 //10'b0000000001
`define STATE_RX_IOWR32_QW1     4'b0001 //4'h01 //10'b0000000001
`define STATE_RX_IOWR32_WT      4'b0010 //4'h02 //10'b0000000001
`define STATE_RX_MEM_WR32_QW1   4'b0011 //4'h03 //10'b0000000010
`define STATE_RX_MEM_WR32_WT    4'b0100 //4'h04 //10'b0000001000
`define STATE_RX_MEM_RD32_QW1   4'b0101 //4'h05 //10'b0000010000
`define STATE_RX_MEM_RD32_WT    4'b0110 //4'h06 //10'b0000100000
`define STATE_RX_CPL_QW1        4'b0111 //4'h07 //10'b0001000000
`define STATE_RX_CPLD_QW1       4'b1000 //4'h08 //10'b0010000000
`define STATE_RX_CPLD_QWN       4'b1001 //4'h09 //10'b0010000000
`define STATE_RX_CPLD_WT0       4'b1010 //4'h0A //10'b1000000000
`define STATE_RX_MEM_RD32_WT1   4'b1011 //4'h0B //10'b1000000000
`define STATE_RX_CPLD_WT1       4'b1100 //4'h0B //10'b1000000000


module pcie_rx(
  //режим Target
  usr_reg_adr_o,
  usr_reg_din_o,
  usr_reg_wr_o,
  usr_reg_rd_o,

  //режим Master
  usr_txbuf_din_o,
  usr_txbuf_wr_o,
  usr_txbuf_wr_last_o,
  usr_txbuf_full_i,
//  usr_txbuf_dbe_o,  // Byte Enable

  //LocalLink Rx (Receive local link interface from PCIe core)
  trn_rd,          //in[31:0] : Receive DATA
  trn_rrem_n,
  trn_rsof_n,      //in  : Receive (SOF): the start of a packet.
  trn_reof_n,      //in  : Receive (EOF): the end of a packet.
  trn_rsrc_rdy_n,  //in  : Receive Source Ready: Indicates the core is presenting valid data on trn_rd
  trn_rsrc_dsc_n,  //in  : Receive Source Discontinue: Indicates the core is aborting the current packet.(Not supported; signal is tied high.)
  trn_rdst_rdy_n_o,//out : Receive Destination Ready: Indicates the User Application is ready to accept data on trn_rd
  trn_rbar_hit_n,  //in[6:0] :Indicates BAR(s) targeted by

  //Handshake with Tx engine:
  req_compl_o,         //запрос: отправить пакет CplD
  compl_done_i,        //Подтверждение: отправка пакета CplD завершена

                       //Параметры для формирования пакета ответа (CplD):
  req_addr_o,          // Address[29:0]
  req_fmt_type_o,      //
  req_tc_o,            // TC(Traffic Class)
  req_td_o,            // TD(TLP Digest Rules)
  req_ep_o,            // EP(indicates the TLP is poisoned)
  req_attr_o,          // Attribute
  req_len_o,           // Length (1DW)
  req_rid_o,           // Requestor ID
  req_tag_o,           // Tag
  req_be_o,            // Byte Enables
  req_expansion_rom_o, // expansion_rom

  //Initiator reset
  trn_dma_init_i,

  //Completion with Data
  cpld_total_size_o,//Общее кол-во данных(DW) от всех принятых пакетов CplD
  cpld_malformed_o, //Похо сформированный пакет

  //Технологический порт
  tst_o,
  tst2_o,

  clk,
  rst_n
);

//------------------------------------
// Port Declarations
//------------------------------------
  output [1:0]   tst_o;
  output [9:0]   tst2_o;
  output [7:0]   usr_reg_adr_o;
  output [31:0]  usr_reg_din_o;
  output         usr_reg_wr_o;
  output         usr_reg_rd_o;

  output [31:0]  usr_txbuf_din_o;
  output         usr_txbuf_wr_o;
  output         usr_txbuf_wr_last_o;
  input          usr_txbuf_full_i;
//  output [7:0]   usr_txbuf_dbe_o;

  input          clk;
  input          rst_n;

  input [63:0]   trn_rd;
  input [7:0]    trn_rrem_n;
  input          trn_rsof_n;
  input          trn_reof_n;
  input          trn_rsrc_rdy_n;
  input          trn_rsrc_dsc_n;
  output         trn_rdst_rdy_n_o;
  input [6:0]    trn_rbar_hit_n;

  output         req_compl_o;
  input          compl_done_i;

  output [29:0]  req_addr_o;
  output [6:0]   req_fmt_type_o;
  output [2:0]   req_tc_o;
  output         req_td_o;
  output         req_ep_o;
  output [1:0]   req_attr_o;
  output [9:0]   req_len_o;
  output [15:0]  req_rid_o;
  output [7:0]   req_tag_o;
  output [7:0]   req_be_o;
  output         req_expansion_rom_o;

  input          trn_dma_init_i;

  output [31:0]  cpld_total_size_o;
  output         cpld_malformed_o;

//---------------------------------------------
// Local registers/wire
//---------------------------------------------
  // Local wire
  wire           bar_expansion_rom;
  wire           usr_txbuf_wr;
  wire           usr_txbuf_wr_o;
  wire           usr_txbuf_wr_last_o;

  // Local Registers
  reg [3:0]      fsm_state;

  reg            trn_rdst_rdy_n;

  reg            req_compl_o;
  reg            req_expansion_rom_o;

  reg [6:0]      req_fmt_type_o;
  reg [2:0]      req_tc_o;
  reg            req_td_o;
  reg            req_ep_o;
  reg [1:0]      req_attr_o;
  reg [9:0]      req_len_o;
  reg [15:0]     req_rid_o;
  reg [7:0]      req_tag_o;
  reg [7:0]      req_be_o;

  reg [29:0]     req_addr_o;

  reg [31:0]     trg_rxd;
  reg            usr_reg_wr_o;
  reg            usr_reg_rd_o;

  reg [31:0]     mst_rxd;
//  reg [7:0]      mst_rxd_be;

  reg [31:0]     cpld_total_size_o;
  reg            cpld_malformed_o;

  reg [9:0]      cpld_tlp_dcnt;
  reg [9:0]      cpld_tlp_len;

  reg            cpld_tpl_work;
  reg            trn_rdw_sel;
  reg            sr_trn_rdw_sel;
  reg            cpld_tpl_dlast;


  assign tst_o[0] = cpld_tpl_work;
  assign tst_o[1] = trn_rdw_sel;
  assign tst2_o[9:0] = cpld_tlp_dcnt;

  assign  bar_expansion_rom =!trn_rbar_hit_n[6];
  assign  bar_usr =!trn_rbar_hit_n[0] || !trn_rbar_hit_n[1];

  assign usr_reg_adr_o = {{req_addr_o[5:0]},{2'b0}};


  assign usr_reg_din_o = {{trg_rxd[07:00]},
                          {trg_rxd[15:08]},
                          {trg_rxd[23:16]},
                          {trg_rxd[31:24]}};

  assign usr_txbuf_din_o = {{mst_rxd[07:00]},
                            {mst_rxd[15:08]},
                            {mst_rxd[23:16]},
                            {mst_rxd[31:24]}};

//  assign usr_txbuf_dbe_o = mst_rxd_be;
  assign usr_txbuf_wr = cpld_tpl_work && (trn_rdw_sel || sr_trn_rdw_sel);
  assign usr_txbuf_wr_o = usr_txbuf_wr;

  assign usr_txbuf_wr_last_o = usr_txbuf_wr && (cpld_tpl_dlast || ((!trn_reof_n) && (!trn_rdw_sel) && (trn_rrem_n != 8'h00)));

  assign trn_rdst_rdy_n_o = (cpld_tpl_work && (trn_rdw_sel || usr_txbuf_full_i)) || trn_rdst_rdy_n;


  always @ ( posedge clk or negedge rst_n )
  begin
    if (!rst_n )
    begin
      sr_trn_rdw_sel <= 1'b0;
    end
    else
    begin
      if (cpld_tpl_work)
        sr_trn_rdw_sel <= trn_rdw_sel;
      else
        sr_trn_rdw_sel <= 1'b0;
    end
  end

  always @ ( posedge clk or negedge rst_n )
  begin
    if (!rst_n )
      cpld_tlp_dcnt <= 10'b0;
    else
    if ((!trn_rsof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n) && trn_rsrc_dsc_n)
      cpld_tlp_dcnt <= 10'b0;
    else
    if (usr_txbuf_wr)
      cpld_tlp_dcnt <= cpld_tlp_dcnt + 1'b1;//Счетчик принятых данных(DW) в пакете cpld
  end

  always @ ( posedge clk or negedge rst_n )
  begin
    if (!rst_n )
    begin

      fsm_state <= `STATE_RX_RST;

      trn_rdst_rdy_n <= 1'b0;

      req_compl_o <= 1'b0;
      req_expansion_rom_o<=1'b0;

      req_fmt_type_o <= 7'b0;
      req_tc_o   <= 2'b0;
      req_td_o   <= 1'b0;
      req_ep_o   <= 1'b0;
      req_attr_o <= 2'b0;
      req_len_o  <= 10'b0;
      req_rid_o  <= 16'b0;
      req_tag_o  <= 8'b0;
      req_be_o   <= 8'b0;
      req_addr_o <= 30'b0;

      trg_rxd <= 32'b0;
      usr_reg_wr_o <= 1'b0;
      usr_reg_rd_o <= 1'b0;

      mst_rxd <= 32'b0;
//      mst_rxd_be <= 8'b0;

      cpld_total_size_o<= 32'b0;
      cpld_malformed_o <= 1'b0;

      trn_rdw_sel    <= 1'b0;
      cpld_tpl_work  <= 1'b0;
      cpld_tlp_len <= 10'b0;
      cpld_tpl_dlast <= 1'b0;

    end
    else
    begin

      req_compl_o    <= 1'b0;

      if (trn_dma_init_i)
      begin
      //Инициализация перед началом DMA транзакции
        cpld_tlp_len <= 10'b0;
        cpld_total_size_o <= 32'b0;
        cpld_malformed_o  <= 1'b0;
      end

      case (fsm_state)

        `STATE_RX_RST :
        begin

          if ((!trn_rsof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n) && trn_rsrc_dsc_n)
          begin
            //-----------------------------------------------------------------------
            //Анализ типа принятого пакета
            //-----------------------------------------------------------------------
            case (trn_rd[62:56]) //trn_rd[62:61]-поле FMT (Формат пакета), trn_rd[60:56]-поле TYPE (Тип пакета)

              `C_FMT_TYPE_IOWR_3DW_WD :
              begin
                //-----------------------------------------------------------------------
                //Обработчик пакета:- IOWr - 3DW, w/data
                //Прием Заголовка: DWORD1,DWORD2
                //Note: Rerquester записывает данные в IO регистры FPGA
                //-----------------------------------------------------------------------
                if (trn_rd[41:32] == 10'b1)//-поле Length(Length of data payload in DW)
                begin
                  //Сохраняю заначения полей заголовка транзакции
                  req_fmt_type_o <= trn_rd[62:56];
                  req_tc_o   <= trn_rd[54:52]; //Traffic Class
                  req_td_o   <= trn_rd[47];    //TLP Digest Rules
                  req_ep_o   <= trn_rd[46];    //indicates the TLP is poisoned
                  req_attr_o <= trn_rd[45:44]; //Attributes
                  req_len_o  <= trn_rd[41:32]; //Length of data payload in DW
                  req_rid_o  <= trn_rd[31:16];
                  req_tag_o  <= trn_rd[15:08];
                  req_be_o   <= trn_rd[07:00]; //Last DW - trn_rd[07:04]; //First DW - trn_rd[03:00];

                  fsm_state <= `STATE_RX_IOWR32_QW1;
                end
                else
                  fsm_state <= `STATE_RX_RST;

              end //С_FMT_TYPE_IOWR_3DW_WD


              `C_FMT_TYPE_IORD_3DW_ND :
              begin
                //-----------------------------------------------------------------------
                //Обработчик пакета:- IORd - 3DW, no data
                //Прием Заголовка: DWORD1,DWORD2
                //Note:Requester хочет прочитать данные из регистров FPFA
                //-----------------------------------------------------------------------
                if (trn_rd[41:32] == 10'b1)//-поле Length(Length of data payload in DW)
                begin
                  //Сохраняю заначения полей заголовка запроса, для формирования пакета ответа (CplD)
                  req_fmt_type_o <= trn_rd[62:56];
                  req_tc_o   <= trn_rd[54:52]; //Traffic Class
                  req_td_o   <= trn_rd[47];    //TLP Digest Rules
                  req_ep_o   <= trn_rd[46];    //indicates the TLP is poisoned
                  req_attr_o <= trn_rd[45:44]; //Attributes
                  req_len_o  <= trn_rd[41:32]; //Length of data payload in DW
                  req_rid_o  <= trn_rd[31:16];
                  req_tag_o  <= trn_rd[15:08];
                  req_be_o   <= trn_rd[07:00]; //Last DW - trn_rd[07:04]; //First DW - trn_rd[03:00];

                  fsm_state <= `STATE_RX_MEM_RD32_QW1;
                end
                else
                  fsm_state <= `STATE_RX_RST;

              end //С_FMT_TYPE_IORD_3DW_ND


             `C_FMT_TYPE_MWR_3DW_WD :
              begin
                //-----------------------------------------------------------------------
                //Обработчик пакета:- MWd - 3DW, w/ data (ХОСТ записывает данные в FPGA)
                //Прием Заголовка: DWORD1,DWORD2
                //Note:Requester хочет записать данные в память (регистры) FPFA
                //-----------------------------------------------------------------------
                if (trn_rd[41:32] == 10'b1)//-поле Length(Length of data payload in DW)
                  fsm_state <= `STATE_RX_MEM_WR32_QW1;
                else
                  fsm_state <= `STATE_RX_RST;

              end //C_FMT_TYPE_MWR_3DW_WD


              `C_FMT_TYPE_MRD_3DW_ND :
              begin
                //-----------------------------------------------------------------------
                //Обработчик пакета:- MRd - 3DW, no data (ХОСТ хочет прочитать данные)
                //Прием Заголовка: DWORD1,DWORD2
                //Note:Requester хочет прочитать данные из памяти (регистров) FPFA
                //-----------------------------------------------------------------------
                if (trn_rd[41:32] == 10'b1)//trn_rd[41:32]-поле Length(Length of data payload in DW)
                begin
                  //Сохраняю заначения полей заголовка запроса, для формирования пакета ответа (CplD)
                  req_fmt_type_o <= trn_rd[62:56];
                  req_tc_o   <= trn_rd[54:52]; //Traffic Class
                  req_td_o   <= trn_rd[47];    //TLP Digest Rules
                  req_ep_o   <= trn_rd[46];    //indicates the TLP is poisoned
                  req_attr_o <= trn_rd[45:44]; //Attributes
                  req_len_o  <= trn_rd[41:32]; //Length of data payload in DW
                  req_rid_o  <= trn_rd[31:16];
                  req_tag_o  <= trn_rd[15:08];
                  req_be_o   <= trn_rd[07:00]; //Last DW - trn_rd[07:04]; //First DW - trn_rd[03:00];

                  if (bar_expansion_rom)
                  begin
                    req_expansion_rom_o<=1'b1;
                  end

                  fsm_state <= `STATE_RX_MEM_RD32_QW1;
                end
                else
                  fsm_state <= `STATE_RX_RST;

              end //C_FMT_TYPE_MRD_3DW_ND


              `C_FMT_TYPE_CPL_3DW_ND :
              begin
                //-----------------------------------------------------------------------
                //Обработчик пакета:- Completion (Cpl) - 3DW, no data
                //Прием Заголовка: DWORD1,DWORD2
                //Note:Ответ на посланый запрос (Когда FPGA-Master)
                //-----------------------------------------------------------------------
                if (trn_rd[15:13] != `C_COMPLETION_STATUS_SC)//trn_rd[15:13]-поле Completion Status Code, trn_rd[12]-поле BCM(Byte Count Modified)
                begin
                  fsm_state <= `STATE_RX_CPL_QW1;
                end
                else
                  fsm_state <= `STATE_RX_RST;

              end //`C_FMT_TYPE_CPL_3DW_ND


              `C_FMT_TYPE_CPLD_3DW_WD :
              begin
                //-----------------------------------------------------------------------
                //Обработчик пакета:- Completion W/Data (CplD) - 3DW, w/ data
                //Прием Заголовка: DWORD1,DWORD2
                //Note:Ответ на зарос MRd чтениня данных из памяти ХОСТа (Когда FPGA-Master)
                //-----------------------------------------------------------------------
//                if (trn_rd[15:13] == `C_COMPLETION_STATUS_SC)//trn_rd[15:13]-поле Completion Status Code
//                begin
                  cpld_total_size_o<= cpld_total_size_o + trn_rd[41:32];
                  cpld_tlp_len <= trn_rd[41:32]; //Length of data payload(DW),в текущем TPL
                  cpld_tpl_work <= 1'b1;
                  fsm_state <= `STATE_RX_CPLD_QW1;
//                end
//                else
//                  fsm_state <= `STATE_RX_RST;

              end //С_FMT_TYPE_CPLD_3DW_WD

              default :
                fsm_state <= `STATE_RX_RST;

            endcase //case (trn_rd[62:56])

          end //if ((!trn_rsof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n) && trn_rsrc_dsc_n)
          else
            fsm_state <= `STATE_RX_RST;

        end //`STATE_RX_RST :




        /////////////////////////////////////////////////////////////////////////////////////
        //-----------------------------------------------------------------------
        //Обработчик пакета:- IOWr - 3DW, w/data
        //Прием Заголовка: DWORD3
        //Note: Rerquester записывает данные в IO регистры FPGA
        //-----------------------------------------------------------------------
        `STATE_RX_IOWR32_QW1 :
        begin

          if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n) && trn_rsrc_dsc_n)
          begin
            req_addr_o <= trn_rd[63:34];//ADDR[31:2]
            trg_rxd <= trn_rd[31:00];

            if (bar_usr)
            usr_reg_wr_o <= 1'b1;
            else
            usr_reg_wr_o <= 1'b0;

            req_compl_o    <= 1'b1;//Выставляем модулю Передачи запрос на отправку пакета Cpl
            trn_rdst_rdy_n <= 1'b1;

            fsm_state <= `STATE_RX_IOWR32_WT;

          end
          else
          if (!trn_rsrc_dsc_n)
            //Надо управлять сигналом ERROR cfg_err_cpl_abort_n_o
            fsm_state <= `STATE_RX_RST;
          else
            fsm_state <= `STATE_RX_IOWR32_QW1;
        end //`STATE_RX_IOWR32_QW1 :

        //-----------------------------------------------------------------------
        //Обработчик пакета:- IOWr - 3DW, w/data
        //Прием Заголовка: Конец
        //Note: Ждем пока модуль Передачи завершит отправку пакета Cpl
        //-----------------------------------------------------------------------
        `STATE_RX_IOWR32_WT:
        begin

          usr_reg_wr_o <= 1'b0;

          //Ждем пока модуль Передачи завершит отправку пакета Cpl
          if (compl_done_i)
          begin
            trn_rdst_rdy_n <= 1'b0;
            fsm_state <= `STATE_RX_RST;
          end
          else
          begin
            req_compl_o    <= 1'b1;
            trn_rdst_rdy_n <= 1'b1;
            fsm_state <= `STATE_RX_IOWR32_WT;
          end

        end //`STATE_RX_IOWR32_WT:
        //END:Обработчик пакета:- IOWr - 3DW, w/data




        /////////////////////////////////////////////////////////////////////////////////////
        //-----------------------------------------------------------------------
        //Обработчик пакета:- MRd - 3DW, no data
        //Прием Заголовка: DWORD3
        //Note:необходимо передать запросчику пакет типа Complete c данными чтения
        //-----------------------------------------------------------------------
        `STATE_RX_MEM_RD32_QW1 :
        begin

          if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n) && trn_rsrc_dsc_n)
          begin
            req_addr_o     <= trn_rd[63:34];//ADDR[31:2]
            trn_rdst_rdy_n <= 1'b1;

            if (!bar_expansion_rom)
            begin
              if (bar_usr)
              usr_reg_rd_o<= 1'b1;
              else
              usr_reg_rd_o<= 1'b0;
            end

            fsm_state <= `STATE_RX_MEM_RD32_WT1;

          end
          else
          if (!trn_rsrc_dsc_n)
            fsm_state <= `STATE_RX_RST;
          else
            fsm_state <= `STATE_RX_MEM_RD32_QW1;

        end //`STATE_RX_MEM_RD32_QW1 :

        //-----------------------------------------------------------------------
        //Обработчик пакета:- MRd - 3DW, no data
        //Note:Ждем завершения передачи данных хосту(пакет CPLD)
        //-----------------------------------------------------------------------
        `STATE_RX_MEM_RD32_WT1:
        begin

          usr_reg_rd_o<= 1'b0;
          req_compl_o <= 1'b1;//Выставляем модулю Передачи запрос на отправку пакета CplD
          fsm_state <= `STATE_RX_MEM_RD32_WT;

        end //`STATE_RX_MEM_RD32_WT1:

        `STATE_RX_MEM_RD32_WT:
        begin

          usr_reg_rd_o<= 1'b0;
          //Ждем пока модуль Передачи завершит отправку пакета CplD
          if (compl_done_i)
          begin
            req_expansion_rom_o<=1'b0;
            trn_rdst_rdy_n <= 1'b0;

            fsm_state <= `STATE_RX_RST;
          end
          else
          begin
            req_compl_o    <= 1'b1;
            trn_rdst_rdy_n <= 1'b1;

            fsm_state <= `STATE_RX_MEM_RD32_WT;
          end

        end //`STATE_RX_MEM_RD32_WT:
        //END:Обработчик пакета:- MRd - 3DW, no data




        /////////////////////////////////////////////////////////////////////////////////////
        //-----------------------------------------------------------------------
        //Обработчик пакета:- MWd - 3DW, w/ data
        //Прием Заголовка: DWORD3 + DATA
        //-----------------------------------------------------------------------
        `STATE_RX_MEM_WR32_QW1 :
        begin

          if ((!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n) && trn_rsrc_dsc_n)
          begin
            req_addr_o <= trn_rd[63:34];//ADDR[31:2]
            trg_rxd <= trn_rd[31:00];

            if (bar_usr)
            usr_reg_wr_o <= 1'b1;
            else
            usr_reg_wr_o <= 1'b0;

            if (!trn_reof_n)
            begin
              trn_rdst_rdy_n <= 1'b1;
              fsm_state <= `STATE_RX_MEM_WR32_WT;
            end
            else
              fsm_state <= `STATE_RX_MEM_WR32_QW1;

          end
          else
          if (!trn_rsrc_dsc_n)
            fsm_state <= `STATE_RX_RST;
          else
            fsm_state <= `STATE_RX_MEM_WR32_QW1;

        end //`STATE_RX_MEM_WR32_QW1 :


        //-----------------------------------------------------------------------
        //Обработчик пакета:- MWd - 3DW, w/ data
        //Завершение
        //-----------------------------------------------------------------------
        `STATE_RX_MEM_WR32_WT:
        begin

          usr_reg_wr_o <= 1'b0;
          trn_rdst_rdy_n   <= 1'b0;

          fsm_state <= `STATE_RX_RST;

        end //`STATE_RX_MEM_WR32_WT:
        //END:Обработчик пакета:MWd - 3DW, w/ data



        /////////////////////////////////////////////////////////////////////////////////////
        //-----------------------------------------------------------------------
        //Обработчик пакета:- Completion (Cpl) - 3DW, no data
        //Прием Заголовка: DWORD3
        //-----------------------------------------------------------------------
        `STATE_RX_CPL_QW1 :
        begin

          if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n) && trn_rsrc_dsc_n)
            fsm_state <= `STATE_RX_RST;
          else
          if (!trn_rsrc_dsc_n)
            fsm_state <= `STATE_RX_RST;
          else
            fsm_state <= `STATE_RX_CPL_QW1;

        end //`STATE_RX_CPL_QW1 :

        //-----------------------------------------------------------------------
        //Обработчик пакета:- Completion W/Data (CplD) - 3DW, w/ data
        //Прием Заголовка: DWORD3 + 1stDATA
        //Note:Ответ на зарос MRd(FPGA) чтениня данных из памяти ХОСТа
        //-----------------------------------------------------------------------
        `STATE_RX_CPLD_QW1 :
        begin

          if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && trn_rsrc_dsc_n && (!usr_txbuf_full_i))
          begin
            //Обнаружил конец кадра (EOF)
            if (trn_rrem_n == 8'h00)
            begin
              mst_rxd <= trn_rd[31:0];
              trn_rdw_sel <= 1'b1;
            end
            cpld_tpl_dlast <= 1'b1;
            fsm_state <= `STATE_RX_CPLD_WT0;

          end
          else
          if (!trn_rsrc_dsc_n)
          begin
            //Ядро прервало передачу данных
            cpld_tpl_dlast <= 1'b1;
            fsm_state <= `STATE_RX_CPLD_WT0;

          end
          else
          if ((!trn_rsrc_rdy_n) && (!usr_txbuf_full_i))
          begin
            mst_rxd <= trn_rd[31:0];
            trn_rdw_sel <= 1'b1;
            fsm_state <= `STATE_RX_CPLD_QWN;
          end
          else
            fsm_state <= `STATE_RX_CPLD_QW1;

        end //`STATE_RX_CPLD_QW1 :

        //-----------------------------------------------------------------------
        //Обработчик пакета:- Completion W/Data (CplD) - 3DW, w/ data
        //Прием Заголовка: NDATA
        //Note:Ответ на зарос MRd(FPGA) чтениня данных из памяти ХОСТа
        //-----------------------------------------------------------------------
        `STATE_RX_CPLD_QWN :
        begin

          if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && trn_rsrc_dsc_n && (!usr_txbuf_full_i))
          begin
            //Обнаружил конец кадра (EOF)
            if (trn_rrem_n == 8'h00)
            begin
              if (trn_rdw_sel)
              begin
                mst_rxd <= trn_rd[63:32];
                trn_rdw_sel <= 1'b0;
                fsm_state <= `STATE_RX_CPLD_QWN;
              end
              else
              begin
                mst_rxd <= trn_rd[31:0];
                trn_rdw_sel <= 1'b1;
                cpld_tpl_dlast <= 1'b1;
                fsm_state <= `STATE_RX_CPLD_WT0;
              end

            end
            else
            if (trn_rrem_n == 8'h0F)
            begin
              mst_rxd <= trn_rd[63:32];
              trn_rdw_sel <= 1'b0;
              fsm_state <= `STATE_RX_CPLD_WT0;
            end

          end //if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && trn_rsrc_dsc_n && (!usr_txbuf_full_i))
          else
          if (!trn_rsrc_dsc_n)
          begin
            //Ядро прервало передачу данных
            trn_rdw_sel <= 1'b0;
            cpld_tpl_dlast <= 1'b1;
            fsm_state <= `STATE_RX_CPLD_WT0;

          end //if (!trn_rsrc_dsc_n)
          else
          if ((!trn_rsrc_rdy_n) && (!usr_txbuf_full_i))
          begin
            if (trn_rdw_sel)
            begin
              trn_rdw_sel <= 1'b0;
              mst_rxd <= trn_rd[63:32];
            end
            else
            begin
              trn_rdw_sel <= 1'b1;
              mst_rxd <= trn_rd[31:0];
            end
            fsm_state <= `STATE_RX_CPLD_QWN;

          end //if ((!trn_rsrc_rdy_n) && (!usr_txbuf_full_i))
          else
          begin
            if (trn_rdw_sel)
              mst_rxd <= trn_rd[63:32];
            else
              mst_rxd <= trn_rd[31:0];

            trn_rdw_sel <= 1'b0;
            fsm_state <= `STATE_RX_CPLD_QWN;
          end

        end //`STATE_RX_CPLD_QWN :

        //-----------------------------------------------------------------------
        //Обработчик пакета:- Completion W/Data (CplD) - 3DW
        //Завершение
        //-----------------------------------------------------------------------
        `STATE_RX_CPLD_WT0:
        begin

          trn_rdw_sel    <= 1'b0;
          cpld_tpl_work  <= 1'b0;
          cpld_tpl_dlast <= 1'b0;
          trn_rdst_rdy_n <= 1'b1;
          fsm_state <= `STATE_RX_CPLD_WT1;

        end //`STATE_RX_CPLD_WT0:

        `STATE_RX_CPLD_WT1:
        begin

          trn_rdst_rdy_n <= 1'b0;

          if (cpld_tlp_dcnt!=cpld_tlp_len)
            cpld_malformed_o <= 1'b1;

          fsm_state <= `STATE_RX_RST;

        end //`STATE_RX_CPLD_WT1:
       //END:Обработчик пакета:MWd - 3DW, w/ data

      endcase //case (fsm_state)
    end
  end //always @ ( posedge clk or negedge rst_n )


endmodule // STATE_RX_ENGINE


