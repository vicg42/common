//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 11/11/2009
//-- Module Name : pcie_tx.v
//--
//-- Description : Local-Link Transmit Unit.
//--               Модуль пердачи и формирования пакетов уровня TPL PCI-Express
//--
//-- Revision:
//-- Revision 0.01 - File Created
//--
//-------------------------------------------------------------------------
`timescale 1ns/1ns
`include "../../../common/veresk_m/pci_express/define/def_pciexpress.v"

//Состояния автомата управления
`define STATE_TX_RST_STATE    4'b0000 //4'h00 //9'b000000001
`define STATE_TX_CPLD_QW1     4'b0001 //4'h01 //9'b000000010
`define STATE_TX_CPLD_WIT     4'b0010 //4'h03 //9'b000001000
`define STATE_TX_MWR32_QW1    4'b0011 //4'h04 //9'b000010000
`define STATE_TX_MWR64_QW1    4'b0100 //4'h05 //9'b000100000
`define STATE_TX_MWR_QWN      4'b0101 //4'h06 //9'b001000000
`define STATE_TX_MRD_QW1      4'b0110 //4'h07 //9'b010000000
`define STATE_TX_MWR32_START  4'b0111 //4'h07 //9'b010000000
`define STATE_TX_MWR32_QW0    4'b1000 //4'h07 //9'b010000000
`define STATE_TX_MRD_QW0      4'b1001 //4'h07 //9'b010000000
//`define STATE_TX_CPLD_WIT2    4'b0111 //4'h03 //9'b000001000
//`define STATE_TX_MRD_QWN      4'b0111 //4'h08 //9'b100000000
//`define STATE_TX_CPLD_QWN     4'b0010 //4'h02 //9'b000000100

module pcie_tx(
  //Режим Target
  usr_reg_dout_i,

  //Режим Master
  usr_rxbuf_dout_i,
  usr_rxbuf_rd_o,
  usr_rxbuf_rd_fst_o,
  usr_rxbuf_rd_last_o,
  usr_rxbuf_empty_i,
//  usr_rxbuf_dbe,    // Byte Enable

  //LocalLink Tx (Transmit local link interface to PCIe core)
  trn_td,          //out[31:0]: Transmit Data
  trn_trem_n,
  trn_tsof_n,      //out: Transmit (SOF): the start of a packet.
  trn_teof_n,      //out: Transmit (EOF): the end of a packet.
  trn_tsrc_rdy_n_o,//out: Transmit Source Ready: Indicates that the User Application is presenting valid data on trn_td
  trn_tsrc_dsc_n,  //out: Transmit Source Discontinue: Can be asserted any time starting on the first cycle after SOF to EOF, inclusive.
  trn_tdst_rdy_n,  //in : Transmit Destination Ready: Indicates that the core is ready to accept data on trn_td.
  trn_tdst_dsc_n,  //in : Transmit Destination Discontinue: Active low. Indicates that the core is aborting the current packet.
                   //Asserted when the physical link is going into reset. Not supported; signal is tied high.
  trn_tbuf_av,     //in[5:0]: Transmit Buffers Available: Indicates transmit buffer availability in the core.


  //Handshake with Rx engine
  req_compl_i,         //запрос: отправить пакет CplD
  compl_done_o,        //Подтверждение: отправка пакета CplD завершена

                       //Параметры для формирования пакета ответа (CplD):
  req_addr_i,          // Address[29:0]
  req_fmt_type_i,      //
  req_tc_i,            // TC(Traffic Class)
  req_td_i,            // TD(TLP Digest Rules)
  req_ep_i,            // EP(indicates the TLP is poisoned)
  req_attr_i,          // Attribute
  req_len_i,           // Length (data payload size in DW)
  req_rid_i,           // Requestor ID
  req_tag_i,           // Tag
  req_be_i,            // Byte Enables
  req_expansion_rom_i, // expansion_rom

  // Initiator Reset
  trn_dma_init_i,

  // Write Initiator
  mwr_work_i,
  mwr_done_o,
  mwr_addr_up_i,
  mwr_addr_i,
  mwr_len_i,
  mwr_count_i,
  mwr_tlp_tc_i,
  mwr_64b_en_i,
  mwr_phant_func_en1_i,
  mwr_lbe_i,
  mwr_fbe_i,
  mwr_tag_i,
  mwr_relaxed_order_i,
  mwr_nosnoop_i,

  // Read Initiator
  mrd_work_i,
  mrd_addr_up_i,
  mrd_addr_i,
  mrd_len_i,
  mrd_count_i,
  mrd_tlp_tc_i,
  mrd_64b_en_i,
  mrd_phant_func_en1_i,
  mrd_lbe_i,
  mrd_fbe_i,
  mrd_tag_i,
  mrd_relaxed_order_i,
  mrd_nosnoop_i,
  mrd_pkt_count_o,           //Кол-во переданых пакетов MRr
  mrd_pkt_len_o,

  completer_id_i,
  tag_ext_en_i,
  mstr_enable_i,
  max_payload_size_i, // I [2:0]
  max_rd_req_size_i,  // I [2:0]

  clk,
  rst_n
);

//------------------------------------
// Port Declarations
//------------------------------------
  input  [31:0]    usr_reg_dout_i;

//  output [3:0]     usr_rxbuf_dbe;
  input  [31:0]    usr_rxbuf_dout_i;
  output           usr_rxbuf_rd_o;
  output           usr_rxbuf_rd_last_o;
  output           usr_rxbuf_rd_fst_o;
  input            usr_rxbuf_empty_i;

  input            clk;
  input            rst_n;

  output [63:0]    trn_td;
  output [7:0]     trn_trem_n;
  output           trn_tsof_n;
  output           trn_teof_n;
  output           trn_tsrc_rdy_n_o;
  output           trn_tsrc_dsc_n;
  input            trn_tdst_rdy_n;
  input            trn_tdst_dsc_n;
  input [5:0]      trn_tbuf_av;

  input            req_compl_i;
  output           compl_done_o;

  input [29:0]     req_addr_i;
  input [6:0]      req_fmt_type_i;
  input [2:0]      req_tc_i;
  input            req_td_i;
  input            req_ep_i;
  input [1:0]      req_attr_i;
  input [9:0]      req_len_i;
  input [15:0]     req_rid_i;
  input [7:0]      req_tag_i;
  input [7:0]      req_be_i;
  input            req_expansion_rom_i;

  input            trn_dma_init_i;

  input            mwr_work_i;
  input  [31:0]    mwr_len_i;
  input  [7:0]     mwr_tag_i;
  input  [3:0]     mwr_lbe_i;
  input  [3:0]     mwr_fbe_i;
  input  [31:0]    mwr_addr_i;
  input  [31:0]    mwr_count_i;
  output           mwr_done_o;
  input  [2:0]     mwr_tlp_tc_i;
  input            mwr_64b_en_i;
  input            mwr_phant_func_en1_i;
  input  [7:0]     mwr_addr_up_i;
  input            mwr_relaxed_order_i;
  input            mwr_nosnoop_i;

  input            mrd_work_i;
  input  [31:0]    mrd_len_i;
  input  [7:0]     mrd_tag_i;
  input  [3:0]     mrd_lbe_i;
  input  [3:0]     mrd_fbe_i;
  input  [31:0]    mrd_addr_i;
  input  [31:0]    mrd_count_i;
  input  [2:0]     mrd_tlp_tc_i;
  input            mrd_64b_en_i;
  input            mrd_phant_func_en1_i;
  input  [7:0]     mrd_addr_up_i;
  input            mrd_relaxed_order_i;
  input            mrd_nosnoop_i;
  output [31:0]    mrd_pkt_len_o;
  output [15:0]    mrd_pkt_count_o;

  input [15:0]     completer_id_i;
  input            tag_ext_en_i;
  input            mstr_enable_i;
  input [2:0]      max_payload_size_i;
  input [2:0]      max_rd_req_size_i;

//---------------------------------------------
// Local registers/wire
//---------------------------------------------
  // Local Registers
  wire         usr_rxbuf_rd_last_o;

  reg [31:0]   sr_usr_rxbuf_dout;
  reg          core_postedbuf_rdy_del_inv;
  reg          tmwr_addr_incr_stop;
  reg          trn_tdw_sel;
  reg          mstr_mwr_work;
  reg          usr_rxbuf_rd_fst_o;
  reg [2:0]    timer_dly;

  reg [63:0]   trn_td;
  reg [7:0]    trn_trem_n;
  reg          trn_tsof_n;
  reg          trn_teof_n;
  reg          trn_tsrc_rdy_n;
  reg          trn_tsrc_dsc_n;

  reg [11:0]   byte_count;
  reg [06:0]   lower_addr;

  reg [3:0]    fsm_state;

  reg          sr_req_compl;
  reg          compl_done_o;

  reg [7:0]    mwr_addr_up_req;
  reg [31:0]   mwr_addr_req;
  reg          mwr_done_o;
  reg [3:0]    mwr_fbe;
  reg [3:0]    mwr_lbe;
  reg [3:0]    mwr_fbe_req;
  reg [3:0]    mwr_lbe_req;
  reg [31:0]   pmwr_addr;        //Указатель адреса записи данных в память хоста
  reg [31:0]   tmwr_addr;
  reg [15:0]   mwr_pkt_count_req;//Кол-во пакетов MWr которые необходимо передать хосту
  reg [15:0]   mwr_pkt_count;    //Кол-во переданых пакетов MWr
  reg [12:0]   mwr_len_byte;     //Размер одного пакета MWr в байт (учавствует в вычислении pmwr_addr)
  reg [10:0]   mwr_len_dw_req;
  reg [10:0]   mwr_len_dw;       //Сколько DW осталось передать в текущем пакете.
                                 //По началу транзвкции Инициализируется значением mwr_len_i[9:0]

  reg [7:0]    mrd_addr_up_req;
  reg [31:0]   mrd_addr_req;
  reg          mrd_stop;
  reg [3:0]    mrd_fbe;
  reg [3:0]    mrd_lbe;
  reg [3:0]    mrd_fbe_req;
  reg [3:0]    mrd_lbe_req;
  reg [31:0]   pmrd_addr;        //Указатель адреса чтения данных  памяти хоста
  reg [31:0]   tmrd_addr;
  reg [15:0]   mrd_pkt_count_req;//Кол-во пакетов MRd которые необходимо передать хосту
  reg [15:0]   mrd_pkt_count;    //Кол-во переданых запросов Чтения (пакетов MRr)
  reg [12:0]   mrd_len_byte;     //Размер одного пакета MRd в байт (учавствует в вычислении pmrd_addr)
  reg [10:0]   mrd_len_dw_req;
  reg [10:0]   mrd_len_dw;



  // Local wires
  wire [31:0]  usr_reg_dout;
  wire [3:0]   req_be;
  reg [15:0]   mrd_pkt_count_o;

  assign mrd_pkt_len_o = {21'b0, mrd_len_dw};

  assign req_be = req_be_i[3:0];

  assign usr_reg_dout = {usr_reg_dout_i[07:00], usr_reg_dout_i[15:08], usr_reg_dout_i[23:16], usr_reg_dout_i[31:24]};

  assign usr_rxbuf_rd_o = (mstr_mwr_work) && (!usr_rxbuf_empty_i) && (!trn_tdst_rdy_n) && (trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE]) && (trn_tdst_dsc_n);

  assign usr_rxbuf_rd_last_o = usr_rxbuf_rd_o && (mwr_len_dw == 11'h1);

  assign trn_tsrc_rdy_n_o = (trn_tsrc_rdy_n) || (trn_tdw_sel) || (core_postedbuf_rdy_del_inv);


  always @ ( posedge clk or negedge rst_n )
  begin
    if (!rst_n )
    begin
      core_postedbuf_rdy_del_inv<= 1'b0;
    end
    else
    begin
      core_postedbuf_rdy_del_inv <=(mstr_mwr_work && (!trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE]));
    end
  end

  always @ ( posedge clk or negedge rst_n )
  begin
    if (!rst_n )
    begin
      sr_usr_rxbuf_dout <= 0;
    end
    else
    begin
      if (!trn_tdw_sel)
        sr_usr_rxbuf_dout <= {usr_rxbuf_dout_i[07:00], usr_rxbuf_dout_i[15:08], usr_rxbuf_dout_i[23:16], usr_rxbuf_dout_i[31:24]};
    end
  end

  /*
   * Calculate byte count based on byte enable
   */
  always @ (req_be)
  begin
    casex (req_be[3:0])
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

  /*
   * Calculate lower address based on  byte enable
   */
  always @ (req_be or req_addr_i)
  begin
    casex (req_be[3:0])
      4'b0000 : lower_addr = {req_addr_i[4:0], 2'b00};
      4'bxxx1 : lower_addr = {req_addr_i[4:0], 2'b00};
      4'bxx10 : lower_addr = {req_addr_i[4:0], 2'b01};
      4'bx100 : lower_addr = {req_addr_i[4:0], 2'b10};
      4'b1000 : lower_addr = {req_addr_i[4:0], 2'b11};
    endcase
  end

  always @ ( posedge clk or negedge rst_n )
  begin
      if (!rst_n )
      begin
        sr_req_compl <= 1'b0;
      end
      else
      begin
        sr_req_compl <= req_compl_i;
      end
  end


  /*
   *  Tx State Machine
   */
  always @ ( posedge clk or negedge rst_n )
  begin
    if (!rst_n )
    begin

      trn_tsof_n     <= 1'b1;
      trn_teof_n     <= 1'b1;
      trn_tsrc_rdy_n <= 1'b1;
      trn_tsrc_dsc_n <= 1'b1;
      trn_td         <= 64'b0;
      trn_trem_n     <= 8'b0;

      compl_done_o   <= 1'b0;

      tmwr_addr_incr_stop<= 1'b0;
      mstr_mwr_work      <= 1'b0;
      trn_tdw_sel        <= 1'b0;

      mrd_pkt_count_o   <= 16'b1;

      mwr_addr_up_req   <= 8'b0;
      mwr_addr_req      <= 32'b0;
      mwr_done_o        <= 1'b0;
      mwr_pkt_count_req <= 16'b0;
      mwr_pkt_count     <= 16'b0;
      mwr_len_byte      <= 13'b0;
      mwr_len_dw_req    <= 11'b0;
      mwr_len_dw        <= 11'b0;
      pmwr_addr         <= 32'b0;
      mwr_fbe_req       <= 4'b0;
      mwr_lbe_req       <= 4'b0;
      mwr_fbe           <= 4'b0;
      mwr_lbe           <= 4'b0;

      mrd_addr_up_req   <= 8'b0;
      mrd_addr_req      <= 32'b0;
      mrd_stop          <= 1'b0;
      mrd_pkt_count_req <= 16'b0;
      mrd_pkt_count     <= 16'b0;
      mrd_len_byte      <= 13'b0;
      pmrd_addr         <= 32'b0;
      mrd_len_dw_req    <= 11'b0;
      mrd_len_dw        <= 11'b0;
      mrd_fbe_req       <= 4'b0;
      mrd_lbe_req       <= 4'b0;
      mrd_fbe           <= 4'b0;
      mrd_lbe           <= 4'b0;

      timer_dly   <= 3'b0;
      usr_rxbuf_rd_fst_o<=1'b0;

      fsm_state   <= `STATE_TX_RST_STATE;

    end
    else
    begin
      if (trn_dma_init_i)
      begin
        //Инициализация перед началом DMA транзакции

        tmwr_addr_incr_stop<= 1'b0;
        mstr_mwr_work      <= 1'b0;
        trn_tdw_sel        <= 1'b0;

        mrd_pkt_count_o   <= 16'b1;

        mwr_addr_up_req   <= mwr_addr_up_i;
        mwr_addr_req      <= mwr_addr_i;
        mwr_done_o        <= 1'b0;
        mwr_pkt_count_req <= mwr_count_i[15:0];
        mwr_pkt_count     <= 16'b0;
        mwr_len_byte      <= 13'b0;
        mwr_len_dw_req    <= mwr_len_i[10:0];
        mwr_len_dw        <= 11'b0;
        pmwr_addr         <= 32'b0;
        mwr_fbe_req       <= mwr_fbe_i;
        mwr_lbe_req       <= mwr_lbe_i;
        mwr_fbe           <= 4'b0;
        mwr_lbe           <= 4'b0;

        mrd_addr_up_req   <= mrd_addr_up_i;
        mrd_addr_req      <= mrd_addr_i;
        mrd_stop          <= 1'b0;
        mrd_pkt_count_req <= mrd_count_i[15:0];
        mrd_pkt_count     <= 16'b0;
        mrd_len_byte      <= 13'b0;
        pmrd_addr         <= 32'b0;
        mrd_len_dw_req    <= mrd_len_i[10:0];
        mrd_len_dw        <= 11'b0;
        mrd_fbe_req       <= mrd_fbe_i;
        mrd_lbe_req       <= mrd_lbe_i;
        mrd_fbe           <= 4'b0;
        mrd_lbe           <= 4'b0;

      end

      case ( fsm_state )
        `STATE_TX_RST_STATE :
        begin

          compl_done_o <= 1'b0;

          // Ответ на запрос принятый от PC. always get highest priority
          if (sr_req_compl && !compl_done_o &&
             !trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_COMPLETION_QUEUE])
          begin
          //-----------------------------------------------------
          //Отправка пакетов: Comletion (В зависимости от req_fmt_type_i)
          //Передача Заголовка: DWORD1,DWORD2
          //Note: FPGA-Completer:/Ответ на запрос - полученый от Requester (PC)
          //-----------------------------------------------------
            trn_tsof_n     <= 1'b0;
            trn_teof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b0;

            trn_td <= { {1'b0},
                         req_fmt_type_i==(`C_FMT_TYPE_IORD_3DW_ND) ? (`C_FMT_TYPE_CPLD_3DW_WD): req_fmt_type_i==(`C_FMT_TYPE_MRD_3DW_ND) ? (`C_FMT_TYPE_CPLD_3DW_WD):(`C_FMT_TYPE_CPL_3DW_ND),
                        {1'b0},
                         req_tc_i,
                        {4'b0},
                         req_td_i,
                         req_ep_i,
                         req_attr_i,
                        {2'b0},
                         req_len_i,       //Length (data payload size in DW)
                         completer_id_i,
                        {3'b0},
                        {1'b0},
                        byte_count };
            trn_trem_n <= 8'b0;

            fsm_state <= `STATE_TX_CPLD_QW1;

          end
          else
          if (mstr_enable_i &&
              !sr_req_compl && !compl_done_o &&
              mwr_work_i && !mwr_done_o &&
             !trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE])
          begin
            //-----------------------------------------------------
            //Отправка пакета: Memory Write Request (MWr)
            //Note:
            //-----------------------------------------------------
            if (timer_dly==3'h7)
            begin
              timer_dly<=3'b0;
              fsm_state <= `STATE_TX_MWR32_START;
            end
            else
            begin
              if (timer_dly==3'h6)
                usr_rxbuf_rd_fst_o<=1'b0;
              if (timer_dly==3'h5)
                usr_rxbuf_rd_fst_o<=1'b1;

              timer_dly<=timer_dly+1;
            end

            trn_tsof_n     <= 1'b1;
            trn_teof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b1;
            trn_trem_n     <= 8'b0;

          end
          else
          if (mstr_enable_i &&
              !sr_req_compl && !compl_done_o &&
              mrd_work_i && !mrd_stop &&
              !trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_NON_POSTED_QUEUE])
          begin
          //-----------------------------------------------------
          //Отправка пакета: Memory Read Request (MRd)
          //Note:
          //-----------------------------------------------------
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

              if      (max_rd_req_size_i==`C_MAX_READ_REQ_SIZE_1024_BYTE) mrd_len_dw <= 11'h100;
              else if (max_rd_req_size_i==`C_MAX_READ_REQ_SIZE_512_BYTE)  mrd_len_dw <= 11'h80;
              else if (max_rd_req_size_i==`C_MAX_READ_REQ_SIZE_256_BYTE)  mrd_len_dw <= 11'h40;
              else                                                        mrd_len_dw <= 11'h20;
            end

            if      (max_rd_req_size_i==`C_MAX_READ_REQ_SIZE_1024_BYTE) mrd_len_byte <= 13'h400;//4 * mrd_len_dw;
            else if (max_rd_req_size_i==`C_MAX_READ_REQ_SIZE_512_BYTE)  mrd_len_byte <= 13'h200;//4 * mrd_len_dw
            else if (max_rd_req_size_i==`C_MAX_READ_REQ_SIZE_256_BYTE)  mrd_len_byte <= 13'h100;//4 * mrd_len_dw
            else                                                        mrd_len_byte <= 13'h80; //4 * mrd_len_dw

            trn_tsof_n     <= 1'b1;
            trn_teof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b1;
            trn_trem_n     <= 8'b0;

            fsm_state <= `STATE_TX_MRD_QW0;

          end
          else
          begin
            if(!trn_tdst_rdy_n)
            begin

              trn_tsof_n        <= 1'b1;
              trn_teof_n        <= 1'b1;
              trn_tsrc_rdy_n    <= 1'b1;
              trn_tsrc_dsc_n    <= 1'b1;
              trn_td            <= 64'b0;
              trn_trem_n        <= 8'b0;

            end

            fsm_state <= `STATE_TX_RST_STATE;
          end

        end //fsm_state=`STATE_TX_RST_STATE







        /////////////////////////////////////////////////////////////////////////////////////
        //-----------------------------------------------------
        //Отправка пакетов: Comletion (В зависимости от req_fmt_type_i)
        //Передача Заголовка: DWORD3 + 1stDATA
        //Note: FPGA-Completer:/Ответ на запрос - полученый от Requester (PC)
        //-----------------------------------------------------
        `STATE_TX_CPLD_QW1 :
        begin
          if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n))
          begin

            trn_tsof_n     <= 1'b1;
            trn_teof_n     <= 1'b0;
            trn_tsrc_rdy_n <= 1'b0;
            trn_td         <= { req_rid_i,
                                req_tag_i,
                                {1'b0},
                                lower_addr,
                                {req_expansion_rom_i ? 32'b0 : usr_reg_dout} //Данные для хоста
                              };
            trn_trem_n   <= 8'h00;

            compl_done_o <= 1'b1;
            fsm_state <= `STATE_TX_CPLD_WIT;

          end
          else
          if (!trn_tdst_dsc_n)
          begin
            trn_tsrc_dsc_n <= 1'b0;
            fsm_state <= `STATE_TX_CPLD_WIT;
          end
          else
            fsm_state <= `STATE_TX_CPLD_QW1;

        end //fsm_state=`STATE_TX_CPLD_QW1

        //-----------------------------------------------------
        //Отправка пакетов: Comletion (В зависимости от req_fmt_type_i)
        //Завершение
        //Note: FPGA-Completer:/Ответ на запрос - полученый от Requester (PC)
        //-----------------------------------------------------
        `STATE_TX_CPLD_WIT :
        begin
          if ( (!trn_tdst_rdy_n) || (!trn_tdst_dsc_n) )
          begin
            trn_tsof_n     <= 1'b1;
            trn_teof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b1;
            trn_tsrc_dsc_n <= 1'b1;

            fsm_state <= `STATE_TX_RST_STATE;
          end
          else
            fsm_state <= `STATE_TX_CPLD_WIT;
        end //fsm_state=`STATE_TX_CPLD_WIT
        //END:Отправка пакетов: Comletion





        /////////////////////////////////////////////////////////////////////////////////////
        //-----------------------------------------------------
        //Отправка пакета: Memory Write Request (MWr)
        //Передача Заголовка: DWORD1,DWORD2
        //Note: FPGA-Requester:/FPGA отправляет запрос на запись в память Completer (PC)
        //-----------------------------------------------------
        `STATE_TX_MWR32_START :
        begin

          if (!trn_tdst_rdy_n && trn_tdst_dsc_n && (!usr_rxbuf_empty_i) && trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE])
          begin
          //-----------------------------------------------------
          //Отправка пакета: Memory Write Request (MWr)
          //Note:
          //-----------------------------------------------------
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

              if      (max_payload_size_i==`C_MAX_PAYLOAD_SIZE_1024_BYTE) mwr_len_dw <= 11'h100;
              else if (max_payload_size_i==`C_MAX_PAYLOAD_SIZE_512_BYTE)  mwr_len_dw <= 11'h80;
              else if (max_payload_size_i==`C_MAX_PAYLOAD_SIZE_256_BYTE)  mwr_len_dw <= 11'h40;
              else                                                        mwr_len_dw <= 11'h20;
            end

            if      (max_payload_size_i==`C_MAX_PAYLOAD_SIZE_1024_BYTE) mwr_len_byte <= 13'h400;//4 * mwr_len_dw;
            else if (max_payload_size_i==`C_MAX_PAYLOAD_SIZE_512_BYTE)  mwr_len_byte <= 13'h200;//4 * mwr_len_dw
            else if (max_payload_size_i==`C_MAX_PAYLOAD_SIZE_256_BYTE)  mwr_len_byte <= 13'h100;//4 * mwr_len_dw
            else                                                        mwr_len_byte <= 13'h80; //4 * mwr_len_dw

            trn_tsof_n     <= 1'b1;
            trn_teof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b1;
            trn_trem_n     <= 8'b0;

            fsm_state <= `STATE_TX_MWR32_QW0;

          end
        end

        //-----------------------------------------------------
        //Отправка пакета: Memory Write Request (MWr)
        //Передача Заголовка: DWORD1,DWORD2
        //Note: FPGA-Requester:/FPGA отправляет запрос на запись в память Completer (PC)
        //-----------------------------------------------------
        `STATE_TX_MWR32_QW0 :
        begin
          if (!trn_tdst_rdy_n && trn_tdst_dsc_n && (!usr_rxbuf_empty_i) && trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE])
          begin
            trn_tsof_n     <= 1'b0;
            trn_teof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b0;
            trn_trem_n     <= 8'b0;

            trn_td <={ {1'b0},
                       {mwr_64b_en_i ? `C_FMT_TYPE_MWR_4DW_WD : `C_FMT_TYPE_MWR_3DW_WD},
                       {1'b0},
                       mwr_tlp_tc_i,
                       {4'b0},
                       1'b0,
                       1'b0,
                       {mwr_relaxed_order_i, mwr_nosnoop_i}, // 2'b00,
                       {2'b0},
                       mwr_len_dw[9:0],       //Length (data payload size in DW)
                       {completer_id_i[15:3], mwr_phant_func_en1_i, 2'b00},
                       tag_ext_en_i ? mwr_pkt_count[7:0] : {3'b0, mwr_pkt_count[4:0]},
                       mwr_lbe,
                       mwr_fbe };

            if (mwr_64b_en_i)
              fsm_state <= `STATE_TX_MWR64_QW1;
            else
            begin
              mstr_mwr_work <= 1'b1;
              fsm_state <= `STATE_TX_MWR32_QW1;
            end
          end
          else
          if(!trn_tdst_dsc_n)
            fsm_state <= `STATE_TX_RST_STATE;
          else
            fsm_state <= `STATE_TX_MWR32_QW0;

        end //fsm_state=`STATE_TX_MWR32_QW0

        //-----------------------------------------------------
        //Отправка пакета: Memory Write Request (MWr)
        //Передача Заголовка: DWORD3 + 1FstDATA
        //Note: FPGA-Requester:/FPGA отправляет запрос на запись в память Completer (PC)
        //-----------------------------------------------------
        `STATE_TX_MWR32_QW1 :
        begin
          //trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE])  - indicates that the core can accept at least 1 TLP
          //trn_tdst_rdy_n - Ядро готово принять пользовательские данные
          //trn_tdst_dsc_n - Ядро прерывало передачу данных
          //                 Indicates that the core is aborting the current packet.
          //                 Asserted when the physical link is going into reset

          trn_tsrc_rdy_n <= usr_rxbuf_empty_i;

          if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n) && (!usr_rxbuf_empty_i))
          begin
            trn_tsof_n <= 1'b1;
            trn_trem_n <= 8'h00;

            if (mwr_pkt_count == 0)
              tmwr_addr = mwr_addr_req;//Загружаем стартовый адрес на передаче первого пакета
            else
            begin
              if (!tmwr_addr_incr_stop)
                tmwr_addr = pmwr_addr + mwr_len_byte;
            end

            trn_td   <= {tmwr_addr[31:2], {2'b00}, //Передаем начальный адрес записи в память хоста
                         usr_rxbuf_dout_i[07:00], usr_rxbuf_dout_i[15:08], usr_rxbuf_dout_i[23:16], usr_rxbuf_dout_i[31:24]};//Передаем 1fst DW данных
            pmwr_addr<= tmwr_addr;

            if (trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE])
            begin
              if (mwr_len_dw == 11'h1)
              begin
                //Записал необходимое кол-во DW(payload) для текущего пакета:
                trn_teof_n <= 1'b0; //EOF - закрываем текущий пакет

                //Проверка кол-ва переданых пакетов
                if (mwr_pkt_count == (mwr_pkt_count_req - 1'b1))
                begin
                  //Кол-во переданых пакетов = кол-ву пакетов которые заказал хост (mwr_pkt_count_req<=mwr_count_i[15:0])
                  mwr_pkt_count <= 0;
                  mwr_done_o   <= 1'b1; //Выставляем флаг - Транзакция завершена
                end
                else //if (mwr_pkt_count > (mwr_pkt_count_req - 1'b1))
                  mwr_pkt_count <= mwr_pkt_count + 1'b1;//Подсчет кол-ва переданыех пакетов MWr

                mstr_mwr_work <= 1'b0;
                fsm_state <= `STATE_TX_RST_STATE;//Перевод автомата управления в исходное состояние
              end
              else //if (mwr_len_dw > 1'h1)
              begin
                mwr_len_dw <= mwr_len_dw - 1'h1;//Вычисляю сколько DW(payload) текущего пакета остальсь передать
                fsm_state <= `STATE_TX_MWR_QWN;
              end
            end
            else //if (trn_tbuf_av!=0)
            begin
              //Буфер для POST транзакции не готов к приему данных
              //Ждем пока буфер будет доступен
              tmwr_addr_incr_stop <= 1'b1;
              fsm_state <= `STATE_TX_MWR32_QW1;
            end
          end
          else
          if (!trn_tdst_dsc_n)
          begin
            fsm_state      <= `STATE_TX_RST_STATE;
            trn_tsrc_dsc_n <= 1'b0;
            tmwr_addr_incr_stop <= 1'b0;
            mstr_mwr_work <= 1'b0;
          end
          else
            fsm_state <= `STATE_TX_MWR32_QW1;

        end //fsm_state=`STATE_TX_MWR32_QW1

        //-----------------------------------------------------
        //Отправка пакета: Memory Write Request (MWr)
        //Передача Данных: NDATA
        //Note: FPGA-Requester:/FPGA отправляет запрос на запись в память Completer (PC)
        //-----------------------------------------------------
        `STATE_TX_MWR_QWN :
        begin
          //trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE])  - indicates that the core can accept at least 1 TLP
          //trn_tdst_rdy_n - Ядро готово принять пользовательские данные
          //trn_tdst_dsc_n - Ядро прерывало передачу данных
          //                 Indicates that the core is aborting the current packet.
          //                 Asserted when the physical link is going into reset

          tmwr_addr_incr_stop <= 1'b0;
          trn_tsrc_rdy_n <= usr_rxbuf_empty_i;

          if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n) && (!usr_rxbuf_empty_i))
          begin

            if (mwr_len_dw == 11'h1)
            begin
              if (trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE])
              begin
                //Записал необходимое кол-во DW(payload) для текущего пакета:
                trn_teof_n <= 1'b0;//EOF - Закрываем пакет
                trn_tsrc_rdy_n <= 1'b0;

                //Выдаю прочитаные данные на trn_td + назначаю маску trn_trem_n для trn_td
                //высатвлего вместе с trn_teof_n
                if (trn_tdw_sel)
                begin
                  trn_td[63:32] <= sr_usr_rxbuf_dout;
                  trn_trem_n <= 8'h00;//действительны trn_tdх[63:0]
                end
                else
                begin
                  trn_td[63:32] <= {usr_rxbuf_dout_i[07:00], usr_rxbuf_dout_i[15:08], usr_rxbuf_dout_i[23:16], usr_rxbuf_dout_i[31:24]};
                  trn_trem_n <= 8'h0F;//действительны trn_tdх[63:32]
                end

                trn_td[31:0]<= {usr_rxbuf_dout_i[07:00], usr_rxbuf_dout_i[15:08], usr_rxbuf_dout_i[23:16], usr_rxbuf_dout_i[31:24]};
                trn_tdw_sel <= 1'b0;

                //Проверка кол-ва переданых пакетов
                if (mwr_pkt_count == (mwr_pkt_count_req - 1'b1))
                begin
                  //Кол-во переданых пакетов = кол-ву пакетов которые заказал хост (mwr_pkt_count_req<=mwr_count_i[15:0])
                  mwr_pkt_count <= 0;
                  mwr_done_o   <= 1'b1; //Выставляем флаг - Транзакция завершена
                end
                else //if (mwr_pkt_count > (mwr_pkt_count_req - 1'b1))
                  mwr_pkt_count <= mwr_pkt_count + 1'b1;//Подсчет кол-ва переданыех пакетов MWr

                mstr_mwr_work <= 1'b0;
                fsm_state <= `STATE_TX_RST_STATE;
              end
              else //if (trn_tbuf_av!=0)
              //Буфер для POST транзакции не готов к приему данных
              //Ждем пока буфер будет доступен
                fsm_state <= `STATE_TX_MWR_QWN;

            end
            else //if (mwr_len_dw > 1'h1)
            begin

              trn_td <= {sr_usr_rxbuf_dout, usr_rxbuf_dout_i[07:00], usr_rxbuf_dout_i[15:08], usr_rxbuf_dout_i[23:16], usr_rxbuf_dout_i[31:24]};
              trn_trem_n <= 8'h00;

              if (trn_tbuf_av[`C_IDX_BUF_POSTED_QUEUE])
              begin
                //т.к. trn_td=[63:0]=DW+DW, а mst_tx_data=[31:0]=DW, то формиурую сигнал выбора DW
                if (!trn_tdw_sel)
                trn_tdw_sel <= 1'b1;
                else
                trn_tdw_sel <= 1'b0;

                mwr_len_dw <= mwr_len_dw - 1'h1;//Вычисляю сколько DW(payload) текущего пакета остальсь передать
              end

              fsm_state <= `STATE_TX_MWR_QWN;
            end
          end
          else
          if (!trn_tdst_dsc_n)
          begin
            mstr_mwr_work  <= 1'b0;
            trn_tsrc_dsc_n <= 1'b0;

            fsm_state <= `STATE_TX_RST_STATE;
          end
          else
            fsm_state <= `STATE_TX_MWR_QWN;

        end //fsm_state=`STATE_TX_MWR_QWN


        //-----------------------------------------------------
        //Отправка пакета: Memory Write Request (MWr) (Формиат заголовка 4DW)
        //Передача Заголовка: DWORD3,DWORD4
        //Note: FPGA-Requester:/FPGA отправляет запрос на запись в память Completer (PC)
        //-----------------------------------------------------
        `STATE_TX_MWR64_QW1 :
        begin
          if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n))
          begin
            trn_tsof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b0;

            if (mwr_pkt_count == 0)
              tmwr_addr = mwr_addr_req;
            else
              tmwr_addr = pmwr_addr + mwr_len_byte;

            trn_td    <= {{24'b0},mwr_addr_up_req,tmwr_addr[31:2],{2'b0}};
            pmwr_addr <= tmwr_addr;

            mstr_mwr_work <= 1'b1;

            fsm_state <= `STATE_TX_MWR_QWN;

          end
          else
          if (!trn_tdst_dsc_n)
          begin

            trn_tsrc_dsc_n <= 1'b0;
            fsm_state <= `STATE_TX_RST_STATE;

          end
          else
            fsm_state <= `STATE_TX_MWR64_QW1;
        end //fsm_state=`STATE_TX_MWR64_QW1
        //END:Memory Write Request (MWr)




        /////////////////////////////////////////////////////////////////////////////////////
        //-----------------------------------------------------
        //Отправка пакета: Memory Read Request (MRd)
        //Передача Заголовка: DWORD1,DWORD2
        //Note: FPGA-Requester:/FPGA отправляет запрос на запись в память Completer (PC)
        //-----------------------------------------------------
        `STATE_TX_MRD_QW0 :
        begin
          if (!trn_tdst_rdy_n && trn_tdst_dsc_n && trn_tbuf_av[`C_IDX_BUF_NON_POSTED_QUEUE])
          begin

            trn_tsof_n     <= 1'b0;
            trn_teof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b0;
            trn_trem_n     <= 8'b0;

            trn_td <={ {1'b0},
                       {mrd_64b_en_i ? `C_FMT_TYPE_MRD_4DW_ND : `C_FMT_TYPE_MRD_3DW_ND},
                       {1'b0},
                       mrd_tlp_tc_i,
                       {4'b0},
                       1'b0,
                       1'b0,
                       {mrd_relaxed_order_i, mrd_nosnoop_i},
                       {2'b0},
                       mrd_len_dw[9:0], //Length (data payload size in DW)
                       {completer_id_i[15:3], mrd_phant_func_en1_i, 2'b00},
                       tag_ext_en_i ? mrd_pkt_count[7:0] : {3'b0, mrd_pkt_count[4:0]},
                       mrd_lbe,
                       mrd_fbe };

            fsm_state <= `STATE_TX_MRD_QW1;
          end
          else
          if(!trn_tdst_dsc_n)
            fsm_state <= `STATE_TX_RST_STATE;
          else
            fsm_state <= `STATE_TX_MRD_QW0;

        end //fsm_state=`STATE_TX_MRD_QW0

        //-----------------------------------------------------
        //Отправка пакета: Memory Read Request (MRd)
        //Передача Заголовка: DWORD3
        //Note: FPGA-Requester:/FPGA отправляет запрос на запись в память Completer (PC)
        //-----------------------------------------------------
        `STATE_TX_MRD_QW1 :
        begin
          if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n))
          begin
            trn_tsof_n     <= 1'b1;
            trn_teof_n     <= 1'b0;
            trn_tsrc_rdy_n <= 1'b0;

            if (mrd_pkt_count == 0)
              tmrd_addr = mrd_addr_req;
            else
              tmrd_addr = pmrd_addr + mrd_len_byte;

            pmrd_addr <= tmrd_addr;

            if (mrd_64b_en_i)
            begin
              trn_td     <= {{24'b0},mrd_addr_up_req,tmrd_addr[31:2],{2'b0}};
              trn_trem_n <= 8'h00;
            end
            else
            begin
              trn_td     <= {tmrd_addr[31:2], {2'b00}, {32'hd0_da_d0_da}};
              trn_trem_n <= 8'h0F;
            end

            if (mrd_pkt_count == (mrd_pkt_count_req - 1'b1))
            begin
            //Кол-во переданых запросов MRd = кол-ву пакетов которые заказал хост (mrd_pkt_count_req <=mwr_count_i[15:0])
              mrd_pkt_count <= 0;
              mrd_stop      <= 1'b1;//Выстовляем флаг запрета генерации запросов MRd

              mrd_pkt_count_o <= 0;
            end
            else
            begin
              mrd_pkt_count <= mrd_pkt_count + 1'b1;//Подсчитываем кол-во переданых запросов MRd
              mrd_pkt_count_o <= mrd_pkt_count_o + 1'b1;//
            end

            fsm_state <= `STATE_TX_RST_STATE;

          end
          else
          if (!trn_tdst_dsc_n)
          begin

            fsm_state <= `STATE_TX_RST_STATE;
            trn_tsrc_dsc_n   <= 1'b0;

          end
          else
            fsm_state <= `STATE_TX_MRD_QW1;

        end //fsm_state=`STATE_TX_MRD_QW1
        //END:Memory Write Request (MWr)

      endcase //case ( fsm_state )
    end
  end //always @ ( posedge clk or negedge rst_n )


endmodule //pcie_tx.v

