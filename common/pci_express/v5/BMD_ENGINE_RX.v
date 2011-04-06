//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 11/11/2009
//-- Module Name : BMD_ENGINE_RX.v
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
`define STATE_RX_CPLD_WT1       4'b1011 //4'h0B //10'b1000000000
`define STATE_RX_MEM_RD32_WT1   4'b1110 //4'h0B //10'b1000000000
//`define STATE_RX_MEM_WR32_QWN   4'b1100 //4'h0C //10'b1000000000


module BMD_ENGINE_RX
(
  //Recieve Port:
  //режим Target
  trg_addr_o,       // [7:0]
  trg_rx_data_o,       // Rcv Data
  trg_rx_data_wd_o,    // Write Enable
  trg_rx_data_rd_o,    // Read Enable

  //режим Master
//  mst_rx_addr_o,
  mst_rx_data_o,       // Rcv Data
  mst_rx_data_be_o,    // Byte Enable
  mst_rx_data_wd_o,    // Write Enable
  mst_rx_data_wd_last_o,
  usr_buf_full_i,

//  wr_busy_i,        // Memory Write Busy

  tst_rx_engine_state_o,


  //LocalLink Rx (Receive local link interface from PCIe core)
  trn_rd,          //in[31:0] : Receive DATA
  trn_rrem_n,
  trn_rsof_n,      //in  : Receive (SOF): the start of a packet.
  trn_reof_n,      //in  : Receive (EOF): the end of a packet.
  trn_rsrc_rdy_n,  //in  : Receive Source Ready: Indicates the core is presenting valid data on trn_rd
  trn_rsrc_dsc_n,  //in  : Receive Source Discontinue: Indicates the core is aborting the current packet.(Not supported; signal is tied high.)
  trn_rdst_rdy_n_o,//out : Receive Destination Ready: Indicates the User Application is ready to accept data on trn_rd
  trn_rbar_hit_n,  //in[6:0] :Receive BAR Hit: Active low. Indicates BAR(s) targeted by
                   //the current receive transaction.
                   //trn_rbar_hit_n[0] => BAR0
                   //trn_rbar_hit_n[1] => BAR1
                   //trn_rbar_hit_n[2] => BAR2
                   //trn_rbar_hit_n[3] => BAR3
                   //trn_rbar_hit_n[4] => BAR4
                   //trn_rbar_hit_n[5] => BAR5
                   //trn_rbar_hit_n[6] => Expansion ROM Address.(Not supported (disabled). Signal is tied high.)

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
  cpld_found_o,     //Кол-во принятых пакетов CplDATA
  cpld_total_size_o,//Total Payload Size (CplDATA)(DWORD)//Размер данных всех принятых пакетов CplDATA
  cpld_malformed_o, //Похо сформированный пакет


  //Completion no Data
  cpl_ur_found_o,
  cpl_ur_tag_o,

  clk,
  rst_n
);

//------------------------------------
// Port Declarations
//------------------------------------
  output [7:0]       trg_addr_o;
  output [31:0]      trg_rx_data_o;
  output             trg_rx_data_wd_o;
  output             trg_rx_data_rd_o;

  output [31:0]      mst_rx_data_o;
  output [7:0]       mst_rx_data_be_o;
  output             mst_rx_data_wd_o;
  output             mst_rx_data_wd_last_o;
  input              usr_buf_full_i;

//  input              wr_busy_i;

  output [3:0]       tst_rx_engine_state_o;

  input              clk;
  input              rst_n;

  input [63:0]       trn_rd;
  input [7:0]        trn_rrem_n;
  input              trn_rsof_n;
  input              trn_reof_n;
  input              trn_rsrc_rdy_n;
  input              trn_rsrc_dsc_n;
  output             trn_rdst_rdy_n_o;
  input [6:0]        trn_rbar_hit_n;

  output             req_compl_o;
  input              compl_done_i;

  output [29:0]      req_addr_o;
  output [6:0]       req_fmt_type_o;
  output [2:0]       req_tc_o;
  output             req_td_o;
  output             req_ep_o;
  output [1:0]       req_attr_o;
  output [9:0]       req_len_o;
  output [15:0]      req_rid_o;
  output [7:0]       req_tag_o;
  output [7:0]       req_be_o;
  output             req_expansion_rom_o;

  input              trn_dma_init_i;

  output [7:0]       cpl_ur_found_o;
  output [7:0]       cpl_ur_tag_o;

  output [31:0]      cpld_found_o;
  output [31:0]      cpld_total_size_o;
  output             cpld_malformed_o;

//---------------------------------------------
// Local registers/wire
//---------------------------------------------
  // Local wire
  wire               bar_expansion_rom;

  wire               mst_rx_data_wd_o;
  wire               mst_rx_data_wd_last_o;

  // Local Registers
  wire[3:0]          tst_rx_engine_state_o;

  reg [3:0]          fsm_state;

  reg                trn_rdst_rdy_n;

  reg                req_compl_o;
  reg                req_expansion_rom_o;

  reg [6:0]          req_fmt_type_o;
  reg [2:0]          req_tc_o;
  reg                req_td_o;
  reg                req_ep_o;
  reg [1:0]          req_attr_o;
  reg [9:0]          req_len_o;
  reg [15:0]         req_rid_o;
  reg [7:0]          req_tag_o;
  reg [7:0]          req_be_o;

  reg [29:0]         req_addr_o;

  reg [31:0]         trg_rx_data;
  reg                trg_rx_data_wd_o;
  reg                trg_rx_data_rd_o;

  reg [31:0]         mst_rx_data;
  reg [7:0]          mst_rx_data_be;


  reg [7:0]          cpl_ur_found_o;
  reg [7:0]          cpl_ur_tag_o;

  reg [31:0]         cpld_found_o;
  reg [31:0]         cpld_total_size_o;
  reg                cpld_malformed_o;

  reg [9:0]          cpld_tlp_size_count;
  reg [9:0]          cpld_tlp_size_saved;

  reg                cpld_tpl_work;
  reg                trn_rdw_sel;
  reg                trn_rdw_sel_delay;
  reg                cpld_last_data;

  assign tst_rx_engine_state_o = fsm_state;

  assign  bar_expansion_rom =!trn_rbar_hit_n[6];

  assign trg_addr_o = {{req_addr_o[5:0]},{2'b0}};


  assign trg_rx_data_o = {{trg_rx_data[07:00]},
                          {trg_rx_data[15:08]},
                          {trg_rx_data[23:16]},
                          {trg_rx_data[31:24]}};

  assign mst_rx_data_o = {{mst_rx_data[07:00]},
                          {mst_rx_data[15:08]},
                          {mst_rx_data[23:16]},
                          {mst_rx_data[31:24]}};

  assign mst_rx_data_be_o = mst_rx_data_be;

  assign mst_rx_data_wd_o = cpld_tpl_work && (trn_rdw_sel || trn_rdw_sel_delay);

  assign mst_rx_data_wd_last_o = cpld_last_data;

//  assign trn_rdst_rdy_n_o = (cpld_tpl_work && (!usr_buf_full_i) && trn_rdw_sel) || trn_rdst_rdy_n;
  assign trn_rdst_rdy_n_o = (cpld_tpl_work && (!usr_buf_full_i) && trn_rdw_sel) || (cpld_tpl_work && usr_buf_full_i) || trn_rdst_rdy_n;

  always @ ( posedge clk or negedge rst_n )
  begin
    if (!rst_n )
    begin
      trn_rdw_sel_delay <= 1'b0;
    end
    else
    begin
      if (cpld_tpl_work)
        trn_rdw_sel_delay <= trn_rdw_sel;
      else
        trn_rdw_sel_delay <= 1'b0;
    end
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
      req_tc_o    <= 2'b0;
      req_td_o    <= 1'b0;
      req_ep_o    <= 1'b0;
      req_attr_o  <= 2'b0;
      req_len_o   <= 10'b0;
      req_rid_o   <= 16'b0;
      req_tag_o   <= 8'b0;
      req_be_o    <= 8'b0;
      req_addr_o  <= 30'b0;

      trg_rx_data      <= 32'b0;
      trg_rx_data_wd_o <= 1'b0;
      trg_rx_data_rd_o <= 1'b0;

      mst_rx_data      <= 32'b0;
      mst_rx_data_be   <= 8'b0;

      cpl_ur_found_o   <= 8'b0;
      cpl_ur_tag_o     <= 8'b0;

      cpld_found_o     <= 32'b0;
      cpld_total_size_o<= 32'b0;
      cpld_malformed_o <= 1'b0;

      cpld_tlp_size_count <= 10'b0;
      cpld_tlp_size_saved <= 10'b0;

      cpld_tpl_work   <= 1'b0;
      trn_rdw_sel     <= 1'b0;
      cpld_last_data  <= 1'b0;

    end
    else
    begin

      req_compl_o    <= 1'b0;

      if (trn_dma_init_i)
      begin
      //Инициализация перед началом DMA транзакции
//        fsm_state <= `STATE_RX_RST;

        cpl_ur_found_o <= 8'b0;
        cpl_ur_tag_o   <= 8'b0;

        cpld_total_size_o <= 32'b0;
        cpld_found_o      <= 32'b0;
        cpld_malformed_o  <= 1'b0;

        cpld_tlp_size_count <= 10'b0;
        cpld_tlp_size_saved <= 10'b0;

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
                begin
                  fsm_state <= `STATE_RX_MEM_WR32_QW1;
                end
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
                  cpl_ur_found_o <= cpl_ur_found_o + 1'b1;

                  fsm_state <= `STATE_RX_CPL_QW1;
                end
                else
                  fsm_state <= `STATE_RX_RST;

              end //С_FMT_TYPE_CPL_3DW_ND


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
                  cpld_tlp_size_saved<= trn_rd[41:32]; //Length of data payload in DW
                  cpld_tlp_size_count<= 10'b0;
                  cpld_found_o <= cpld_found_o + 1'b1;

                  cpld_tpl_work <= 1'b1;

                  fsm_state <= `STATE_RX_CPLD_QW1;
//                end
//                else
//                begin
//                  fsm_state <= `STATE_RX_RST;
//                end

              end //С_FMT_TYPE_CPLD_3DW_WD


              default :
              begin
                fsm_state <= `STATE_RX_RST;
              end

            endcase
          end
          else
          begin
            fsm_state <= `STATE_RX_RST;
          end
        end




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
            req_addr_o       <= trn_rd[63:34];//ADDR[31:2]

            trg_rx_data      <= trn_rd[31:00];
            trg_rx_data_wd_o <= 1'b1;

            req_compl_o    <= 1'b1;//Выставляем модулю Передачи запрос на отправку пакета Cpl
            trn_rdst_rdy_n <= 1'b1;

            fsm_state <= `STATE_RX_IOWR32_WT;

          end
          else
          if (!trn_rsrc_dsc_n)
          begin
            //Надо управлять сигналом ERROR cfg_err_cpl_abort_n_o
            fsm_state <= `STATE_RX_RST;
          end
          else
            fsm_state <= `STATE_RX_IOWR32_QW1;
        end

        //-----------------------------------------------------------------------
        //Обработчик пакета:- IOWr - 3DW, w/data
        //Прием Заголовка: Конец
        //Note: Ждем пока модуль Передачи завершит отправку пакета Cpl
        //-----------------------------------------------------------------------
        `STATE_RX_IOWR32_WT:
        begin

          trg_rx_data_wd_o <= 1'b0;

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
        end
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
//            req_compl_o    <= 1'b1;//Выставляем модулю Передачи запрос на отправку пакета CplD
            trn_rdst_rdy_n <= 1'b1;

            if (!bar_expansion_rom)
            begin
              trg_rx_data_rd_o<= 1'b1;
            end

            fsm_state <= `STATE_RX_MEM_RD32_WT1;

          end
          else
          if (!trn_rsrc_dsc_n)
          begin
            fsm_state <= `STATE_RX_RST;
          end
          else
            fsm_state <= `STATE_RX_MEM_RD32_QW1;
        end

        //-----------------------------------------------------------------------
        //Обработчик пакета:- MRd - 3DW, no data
        //Note:Ждем завершения передачи данных хосту(пакет CPLD)
        //-----------------------------------------------------------------------
        `STATE_RX_MEM_RD32_WT1:
        begin

          trg_rx_data_rd_o<= 1'b0;
          req_compl_o    <= 1'b1;//Выставляем модулю Передачи запрос на отправку пакета CplD
          fsm_state <= `STATE_RX_MEM_RD32_WT;
        end

        `STATE_RX_MEM_RD32_WT:
        begin

          trg_rx_data_rd_o<= 1'b0;
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
        end
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
            req_addr_o       <= trn_rd[63:34];//ADDR[31:2]
            trg_rx_data      <= trn_rd[31:00];
            trg_rx_data_wd_o <= 1'b1;

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
          begin
            fsm_state <= `STATE_RX_RST;
          end
          else
            fsm_state <= `STATE_RX_MEM_WR32_QW1;

        end

//        //-----------------------------------------------------------------------
//        //Обработчик пакета:- MWd - 3DW, w/ data
//        //Прием данных:
//        //-----------------------------------------------------------------------
//        `STATE_RX_MEM_WR32_QWN :
//        begin
//
//          if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n) && trn_rsrc_dsc_n)
//          begin
//            if (trn_rdst_rdy_n==1'b1)
//            begin
//              trn_rdst_rdy_n <= 1'b0;
//              trg_rx_data <= trn_rd[63:32];
//            end
//            else
//            begin
//              trn_rdst_rdy_n  <=1'b1;
//              trg_rx_data <= trn_rd[31:0];
//            end
//
//            if (!trn_reof_n)
//            begin
//              if ((trn_rdst_rdy_n) && (trn_rrem_n!=8'h00))
//                trg_rx_data_wd_o <= 1'b0;
//            end
//            else
//              trg_rx_data_wd_o <= 1'b1;
//
//            if (trg_rx_data_wd_o==1'b1)
//              req_mwr_len_dw <= req_mwr_len_dw - 1'h1;
//
//            //trn_rrem_n=8'h0F - trn_rd[63:32]
//            //trn_rrem_n=8'h00 - trn_rd[63:0]
//            if ((!trn_reof_n) && (!trn_rdst_rdy_n))
//            begin
//              fsm_state <= `STATE_RX_MEM_WR32_WT;
//            end
//
//          end
//          else
//          if (!trn_rsrc_dsc_n)
//          begin
//            trg_rx_data_wd_o <= 1'b0;
//            fsm_state <= `STATE_RX_RST;
//          end
//          else
//          begin
//            trg_rx_data_wd_o <= 1'b0;
//            fsm_state <= `STATE_RX_MEM_WR32_QWN;
//          end
//
//        end

        //-----------------------------------------------------------------------
        //Обработчик пакета:- MWd - 3DW, w/ data
        //Завершение
        //-----------------------------------------------------------------------
        `STATE_RX_MEM_WR32_WT:
        begin

          trg_rx_data_wd_o <= 1'b0;
          trn_rdst_rdy_n   <= 1'b0;

          fsm_state <= `STATE_RX_RST;

        end
        //END:Обработчик пакета:MWd - 3DW, w/ data



        /////////////////////////////////////////////////////////////////////////////////////
        //-----------------------------------------------------------------------
        //Обработчик пакета:- Completion (Cpl) - 3DW, no data
        //Прием Заголовка: DWORD3
        //-----------------------------------------------------------------------
        `STATE_RX_CPL_QW1 :
        begin
          if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && (!trn_rdst_rdy_n) && trn_rsrc_dsc_n)
          begin
            cpl_ur_tag_o <= trn_rd[47:40];
            fsm_state <= `STATE_RX_RST;
          end
          else
          if (!trn_rsrc_dsc_n)
          begin
            fsm_state <= `STATE_RX_RST;
          end
          else
            fsm_state <= `STATE_RX_CPL_QW1;
        end

        //-----------------------------------------------------------------------
        //Обработчик пакета:- Completion W/Data (CplD) - 3DW, w/ data
        //Прием Заголовка: DWORD3 + 1stDATA
        //Note:Ответ на зарос MRd(FPGA) чтениня данных из памяти ХОСТа
        //-----------------------------------------------------------------------
        `STATE_RX_CPLD_QW1 :
        begin

          if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && trn_rsrc_dsc_n && (!usr_buf_full_i))
          begin
            //Обнаружил конец кадра (EOF)
            if (trn_rrem_n == 8'h00)
            begin
              cpld_tlp_size_count <= cpld_tlp_size_count + 1'b1;//Подсчет кол-ва принятых DW в текущем пакете

              mst_rx_data <= trn_rd[31:0];
              trn_rdw_sel <= 1'b1;
            end

            cpld_last_data <= 1'b1;
            fsm_state <= `STATE_RX_CPLD_WT0;

          end
          else
          if (!trn_rsrc_dsc_n)
          begin
            //Ядро прервало передачу данных
            cpld_last_data <= 1'b1;
            fsm_state <= `STATE_RX_CPLD_WT0;

          end
          else
          if ((!trn_rsrc_rdy_n) && (!usr_buf_full_i))
          begin
            cpld_tlp_size_count <= cpld_tlp_size_count + 1'b1;//Подсчет кол-ва принятых DW в текущем пакете

            mst_rx_data <= trn_rd[31:0];
            trn_rdw_sel <= 1'b1;

            fsm_state <= `STATE_RX_CPLD_QWN;
          end
          else
          begin
            fsm_state <= `STATE_RX_CPLD_QW1;
          end

        end

        //-----------------------------------------------------------------------
        //Обработчик пакета:- Completion W/Data (CplD) - 3DW, w/ data
        //Прием Заголовка: NDATA
        //Note:Ответ на зарос MRd(FPGA) чтениня данных из памяти ХОСТа
        //-----------------------------------------------------------------------
        `STATE_RX_CPLD_QWN :
        begin

          if ((!trn_reof_n) && (!trn_rsrc_rdy_n) && trn_rsrc_dsc_n && (!usr_buf_full_i))
          begin
            //Обнаружил конец кадра (EOF)
            if (trn_rrem_n == 8'h00)
            begin
              cpld_tlp_size_count <= cpld_tlp_size_count + 1'b1;//Подсчет кол-ва принятых DW в текущем пакете

              if (trn_rdw_sel)
              begin

                mst_rx_data <= trn_rd[63:32];
                trn_rdw_sel <= 1'b0;

                fsm_state <= `STATE_RX_CPLD_QWN;
              end
              else
              begin
                mst_rx_data <= trn_rd[31:0];
                trn_rdw_sel <= 1'b1;
                cpld_last_data <= 1'b1;
                fsm_state <= `STATE_RX_CPLD_WT0;
              end

            end
            else
            if (trn_rrem_n == 8'h0F)
            begin
              cpld_tlp_size_count <= cpld_tlp_size_count + 1'b1;//Подсчет кол-ва принятых DW в текущем пакете

              mst_rx_data <= trn_rd[63:32];
              trn_rdw_sel <= 1'b0;
              cpld_last_data <= 1'b1;

              fsm_state <= `STATE_RX_CPLD_WT0;
            end
            else
            begin
              cpld_last_data <= 1'b1;
              fsm_state <= `STATE_RX_CPLD_WT0;
            end

          end
          else
          if (!trn_rsrc_dsc_n)
          begin
            //Ядро прервало передачу данных
            trn_rdw_sel <= 1'b0;
            cpld_last_data <= 1'b1;
            fsm_state <= `STATE_RX_CPLD_WT0;

          end
          else
          if ((!trn_rsrc_rdy_n) && (!usr_buf_full_i))
          begin
            cpld_tlp_size_count <= cpld_tlp_size_count + 1'b1;//Подсчет кол-ва принятых DW в текущем пакете

            if (trn_rdw_sel)
            begin
              trn_rdw_sel <= 1'b0;
              mst_rx_data <= trn_rd[63:32];
            end
            else
            begin
              trn_rdw_sel <= 1'b1;
              mst_rx_data <= trn_rd[31:0];
            end

            fsm_state <= `STATE_RX_CPLD_QWN;

          end
          else
          begin
            trn_rdw_sel <= 1'b0;
            fsm_state <= `STATE_RX_CPLD_QWN;
          end

        end

        //-----------------------------------------------------------------------
        //Обработчик пакета:- Completion W/Data (CplD) - 3DW
        //Завершение
        //-----------------------------------------------------------------------
        `STATE_RX_CPLD_WT0:
        begin

          trn_rdw_sel     <= 1'b0;
          cpld_tpl_work   <= 1'b0;
          cpld_last_data <= 1'b0;

          if (cpld_tlp_size_count!=cpld_tlp_size_saved)
          begin
            cpld_malformed_o <= 1'b1;
          end

          fsm_state <= `STATE_RX_CPLD_WT1;

        end

        //-----------------------------------------------------------------------
        //Обработчик пакета:- Completion W/Data (CplD) - 3DW
        //Завершение
        //-----------------------------------------------------------------------
       `STATE_RX_CPLD_WT1:
       begin

         trn_rdw_sel <= 1'b0;

         fsm_state <= `STATE_RX_RST;

       end
       //END:Обработчик пакета:MWd - 3DW, w/ data

      endcase //case (fsm_state)
    end
  end //always @ ( posedge clk or negedge rst_n )


endmodule // STATE_RX_ENGINE


