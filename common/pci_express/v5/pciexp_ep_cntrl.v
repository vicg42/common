//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 11/11/2009
//-- Module Name : pciexp_ep_cntrl.v
//--
//-- Description : Контроллер Endpoint PCI-Express.
//--
//-- Revision:
//-- Revision 0.01 - File Created
//--
//-------------------------------------------------------------------------
`timescale 1ns/1ns
`include "../../../common/veresk_m/pci_express/define/def_pciexpress.v"

module pciexp_ep_cntrl
(
//-----------------------------------------------------
//Связь с Пользовательским проектом
//-----------------------------------------------------
    p_out_host_clk_out,

    p_out_usr_tst,
    p_in_usr_tst,

    p_out_glob_ctrl,
    p_out_dev_ctrl,
    p_out_dev_din,
    p_in_dev_dout,
    p_out_dev_wd,
    p_out_dev_rd,
    p_in_dev_fifoflag,
    p_in_dev_status,
    p_in_dev_irq,
    p_in_dev_option,

    p_out_mem_ctl_reg,
    p_out_mem_mode_reg,
    p_in_mem_locked,
    p_in_mem_trained,

    p_out_mem_bank1h,
    p_out_mem_adr,
    p_out_mem_ce,
    p_out_mem_cw,
    p_out_mem_rd,
    p_out_mem_wr,
    p_out_mem_be,
    p_out_mem_term,
    p_out_mem_din,
    p_in_mem_dout,

    p_in_mem_wf,
    p_in_mem_wpf,
    p_in_mem_re,
    p_in_mem_rpe,

    init_rst_o,

//-----------------------------------------------------
//Связь с ядром PCI-Express
//-----------------------------------------------------
//
// Host ( CFG ) Interface
//
    cfg_turnoff_ok_n_o,
    cfg_to_turnoff_n_i,

    cfg_interrupt_n_o,
    cfg_interrupt_rdy_n_i,
    cfg_interrupt_assert_n_o,
    cfg_interrupt_di_o,
    cfg_interrupt_do_i,
    cfg_interrupt_msienable_i,
    cfg_interrupt_mmenable_i,

    cfg_do_i,
    cfg_di_o,
    cfg_dwaddr_o,
    cfg_byte_en_n_o,
    cfg_wr_en_n_o,
    cfg_rd_en_n_o,
    cfg_rd_wr_done_n_i,

    cfg_err_tlp_cpl_header_o,
    cfg_err_ecrc_n_o,
    cfg_err_ur_n_o,
    cfg_err_cpl_timeout_n_o,
    cfg_err_cpl_unexpect_n_o,
    cfg_err_cpl_abort_n_o,
    cfg_err_posted_n_o,
    cfg_err_cor_n_o,

    cfg_pm_wake_n_o,
    cfg_trn_pending_n_o,
    cfg_dsn_o,
    cfg_pcie_link_state_n_i,
    cfg_bus_number_i,
    cfg_device_number_i,
    cfg_function_number_i,
    cfg_status_i,
    cfg_command_i,
    cfg_dstatus_i,
    cfg_dcommand_i,
    cfg_lstatus_i,
    cfg_lcommand_i,

//
// Tx Local-Link
//
    trn_td_o,
    trn_trem_n_o,
    trn_tsof_n_o,
    trn_teof_n_o,
    trn_tsrc_rdy_n_o,
    trn_tdst_rdy_n_i,
    trn_tsrc_dsc_n_o,
    trn_tdst_dsc_n_i,
    trn_terrfwd_n_o,
    trn_tbuf_av_i,

//
// Rx Local-Link
//
    trn_rd_i,
    trn_rrem_n_i,
    trn_rsof_n_i,
    trn_reof_n_i,
    trn_rsrc_rdy_n_i,
    trn_rsrc_dsc_n_i,
    trn_rdst_rdy_n_o,
    trn_rerrfwd_n_i,
    trn_rnp_ok_n_o,

    trn_rbar_hit_n_i,
    trn_rfc_nph_av_i,
    trn_rfc_npd_av_i,
    trn_rfc_ph_av_i,
    trn_rfc_pd_av_i,
//    trn_rfc_cplh_av_i,
//    trn_rfc_cpld_av_i,
    trn_rcpl_streaming_n_o,

//
// Transaction ( TRN ) Interface
//
    trn_lnk_up_n_i,
    trn_reset_n_i,
    trn_clk_i
);

//parameter G_DBG="OFF";

//------------------------------------
// Port Declarations
//------------------------------------
//Пользовательский порт
output            p_out_host_clk_out;

output [127:0]    p_out_usr_tst;
input  [127:0]    p_in_usr_tst;

output [31:0]     p_out_glob_ctrl;
output [31:0]     p_out_dev_ctrl;
output [31:0]     p_out_dev_din;
input  [31:0]     p_in_dev_dout;
output            p_out_dev_wd;
output            p_out_dev_rd;
input  [7:0]      p_in_dev_fifoflag;
input  [31:0]     p_in_dev_status;
input  [31:0]     p_in_dev_irq;
input  [127:0]    p_in_dev_option;

output [0:0]      p_out_mem_ctl_reg;
output [511:0]    p_out_mem_mode_reg;
input  [7:0]      p_in_mem_locked;
input  [15:0]     p_in_mem_trained;

output [15:0]     p_out_mem_bank1h;
output [34:0]     p_out_mem_adr;
output            p_out_mem_ce;
output            p_out_mem_cw;
output            p_out_mem_rd;
output            p_out_mem_wr;
output [7:0]      p_out_mem_be;
output            p_out_mem_term;
output [31:0]     p_out_mem_din;
input  [31:0]     p_in_mem_dout;

input             p_in_mem_wf;
input             p_in_mem_wpf;
input             p_in_mem_re;
input             p_in_mem_rpe;


output            init_rst_o;


// LocalLink Tx
output [63:0]     trn_td_o;
output [7:0]      trn_trem_n_o;
output            trn_tsof_n_o;
output            trn_teof_n_o;
output            trn_tsrc_rdy_n_o;
input             trn_tdst_rdy_n_i;
output            trn_tsrc_dsc_n_o;
input             trn_tdst_dsc_n_i;
output            trn_terrfwd_n_o;
input  [5:0]      trn_tbuf_av_i;

// LocalLink Rx
input  [63:0]     trn_rd_i;
input  [7:0]      trn_rrem_n_i;
input             trn_rsof_n_i;
input             trn_reof_n_i;
input             trn_rsrc_rdy_n_i;
input             trn_rsrc_dsc_n_i;
output            trn_rdst_rdy_n_o;
input             trn_rerrfwd_n_i;
output            trn_rnp_ok_n_o;

input  [6:0]      trn_rbar_hit_n_i;
input  [7:0]      trn_rfc_nph_av_i;
input  [11:0]     trn_rfc_npd_av_i;
input  [7:0]      trn_rfc_ph_av_i;
input  [11:0]     trn_rfc_pd_av_i;
//input   [(`PCI_EXP_TRN_FC_HDR_WIDTH - 1):0]       trn_rfc_cplh_av_i;
//input   [(`PCI_EXP_TRN_FC_DATA_WIDTH - 1):0]      trn_rfc_cpld_av_i;
output            trn_rcpl_streaming_n_o;

// Transaction ( TRN ) Interface
input             trn_lnk_up_n_i;
input             trn_reset_n_i;
input             trn_clk_i;

// Host ( CFG ) Interface
output            cfg_turnoff_ok_n_o;
input             cfg_to_turnoff_n_i;

output            cfg_interrupt_n_o;
input             cfg_interrupt_rdy_n_i;
output            cfg_interrupt_assert_n_o;
output [7:0]      cfg_interrupt_di_o;
input  [7:0]      cfg_interrupt_do_i;
input             cfg_interrupt_msienable_i;
input  [2:0]      cfg_interrupt_mmenable_i;

input  [31:0]     cfg_do_i;
output [31:0]     cfg_di_o;
output [9:0]      cfg_dwaddr_o;
output [3:0]      cfg_byte_en_n_o;
output            cfg_wr_en_n_o;
output            cfg_rd_en_n_o;
input             cfg_rd_wr_done_n_i;

output [47:0]     cfg_err_tlp_cpl_header_o;
output            cfg_err_ecrc_n_o;
output            cfg_err_ur_n_o;
output            cfg_err_cpl_timeout_n_o;
output            cfg_err_cpl_unexpect_n_o;
output            cfg_err_cpl_abort_n_o;
output            cfg_err_posted_n_o;
output            cfg_err_cor_n_o;

output            cfg_pm_wake_n_o;
output            cfg_trn_pending_n_o;
output [63:0]     cfg_dsn_o;
input  [2:0]      cfg_pcie_link_state_n_i;
input  [7:0]      cfg_bus_number_i;
input  [4:0]      cfg_device_number_i;
input  [2:0]      cfg_function_number_i;
input  [15:0]     cfg_status_i;
input  [15:0]     cfg_command_i;
input  [15:0]     cfg_dstatus_i;
input  [15:0]     cfg_dcommand_i;
input  [15:0]     cfg_lstatus_i;
input  [15:0]     cfg_lcommand_i;


//------------------------------------
// Local wires
//------------------------------------
wire [15:0]       tst_cur_mwr_pkt_count;
wire              tst_rdy_del_inv;

wire [4:0]        tst_irq_ctrl;
wire [3:0]        tst_irq_ctrl_out;

//wire [127:0]      out_usr_tst;
//wire [127:0]      in_usr_tst;
//wire [3:0]        tst_tx_engine_state;
//wire [3:0]        tst_rx_engine_state;
//wire [7:0]        tst_expansion_rom_count;

wire [7:0]        trg_addr;
wire [31:0]       trg_din;
wire [31:0]       trg_dout;
wire              trg_wr;
wire              trg_rd;

//wire [3:0]        mst_rx_data_be;
wire [31:0]       usr_txbuf_din;
wire              usr_txbuf_wd;
wire              usr_txbuf_wd_last;
wire              usr_txbuf_full;

wire [31:0]       usr_rxbuf_dout;
wire              usr_rxbuf_rd;
wire              usr_rxbuf_rd_last;
wire              usr_rxbuf_rd_start;
wire              usr_rxbuf_empty;

//wire              mst_tx_mem_start;

wire              req_compl;
wire              compl_done;

wire  [29:0]      req_addr;
wire  [6:0]       req_fmt_type;
wire  [2:0]       req_tc;
wire              req_td;
wire              req_ep;
wire  [1:0]       req_attr;
wire  [9:0]       req_len;
wire  [15:0]      req_rid;
wire  [7:0]       req_tag;
wire  [7:0]       req_be;
wire              req_expansion_rom;

wire              trn_dma_rst;
wire              trn_dma_init;

wire              i_interrupt_clr;
wire  [15:0]      i_interrupt_src_adr;
wire  [15:0]      i_interrupt_src_set;
wire  [15:0]      i_interrupt_src_act;

wire              mwr_work;
wire              mwr_done;
//wire              mwr_int_en;
wire  [31:0]      mwr_addr;
wire  [31:0]      mwr_len;
wire  [31:0]      mwr_count;
wire  [2:0]       mwr_tlp_tc;
wire              mwr_64b_en;
wire              mwr_phant_func_en1;
wire  [7:0]       mwr_addr_up;
wire              mwr_relaxed_order;
wire              mwr_nosnoop;
wire  [7:0]       mwr_tag;
wire  [3:0]       mwr_lbe;
wire  [3:0]       mwr_fbe;

wire              mrd_work;
//wire              mrd_done;
//wire              mrd_int_en;
wire  [31:0]      mrd_addr;
wire  [31:0]      mrd_len;
wire  [31:0]      mrd_count;
wire  [2:0]       mrd_tlp_tc;
wire              mrd_64b_en;
wire              mrd_phant_func_en1;
wire  [7:0]       mrd_addr_up;
wire              mrd_relaxed_order;
wire              mrd_nosnoop;
wire  [7:0]       mrd_tag;
wire  [3:0]       mrd_lbe;
wire  [3:0]       mrd_fbe;

wire  [31:0]      cpld_found;
wire  [31:0]      cpld_total_size;
wire              cpld_malformed;

wire              mrd_work_from_rd_throttle;
wire [15:0]       mrd_pkt_count;

wire              cpl_streaming;
wire              rd_metering;
wire              trn_rnp_ok_n;

wire              cfg_msi_enable;
wire              cfg_msi_enable_tmp;

wire [5:0]        cfg_cap_max_lnk_width;
wire [2:0]        cfg_cap_max_payload_size;


wire [63:0]       cfg_dsn_sw;


wire [2:0]        usr_prg_max_payload_size;
wire [2:0]        usr_prg_max_rd_req_size;

//
// Programmable I/O Module
//
wire [15:0]  cfg_completer_id        = {cfg_bus_number_i,
                                        cfg_device_number_i,
                                        cfg_function_number_i};

//Value stored in Link Status register in the PCI Express Capabilities Structure
wire  [5:0] cfg_neg_max_lnk_width    = cfg_lstatus_i[9:4]; //Negotiated Link Width

//Value stored in Link Control register in the PCI Express Capabilities Structure
wire        cfg_rd_comp_bound        = cfg_lcommand_i[3];  //Read Completion Boundary.(RCB)
                                                           //Programmed RCB = 0=64B or 1=128B

//Value stored in Device Control register in the PCI Express Capabilities Structure
wire  [2:0] cfg_prg_max_payload_size = cfg_dcommand_i[7:5];   //the max TLP data payload size for the device
                                                              //000b = 128  byte max payload size
                                                              //001b = 256  byte max payload size
                                                              //010b = 512  byte max payload size
                                                              //011b = 1024 byte max payload size
                                                              //100b = 2048 byte max payload size
                                                              //101b = 4096 byte max payload size

wire  [2:0] cfg_prg_max_rd_req_size  = cfg_dcommand_i[14:12]; //Max read request size for the device when acting as the Requester
                                                              //000b = 128 byte max read request size
                                                              //001b = 256 byte max read request size
                                                              //010b = 512 byte max read request size
                                                              //011b = 1KB max read request size
                                                              //100b = 2KB max read request size
                                                              //101b = 4KB max read request size

wire        cfg_ext_tag_en           = cfg_dcommand_i[8];     //1/0 -an 8-bit/5-bit Tag field as a requester  (подробно см. пункт PCI Express Capability Register Set в Addison Wesley - PCI Express System Architecture.chm)
wire        cfg_phant_func_en        = cfg_dcommand_i[9];     //1/0 -Phantom Functions Enable (подробно см. пункт PCI Express Capability Register Set в Addison Wesley - PCI Express System Architecture.chm)
wire        cfg_no_snoop_en          = cfg_dcommand_i[11];    //1/0 -Enable No Snoop (подробно см. пункт PCI Express Capability Register Set в Addison Wesley - PCI Express System Architecture.chm)

//Value stored in the Command register in the PCI Configuration Space Header
//NOTE:
//The User Application must monitor the Bus Master Enable bit and refrain from
//transmitting requests while this bit is not set. This requirement applies only to
//requests; completions can be transmitted regardless of this bit.
wire        cfg_bus_mstr_enable      = cfg_command_i[2];

//Interrupt Disable
wire        cfg_intrrupt_disable     = cfg_command_i[10];


wire        bmd_reset_n = trn_reset_n_i & ~trn_lnk_up_n_i;


//
// Core input tie-offs
//
//Сигнализация ядру о следующих ошибках:
assign cfg_err_ecrc_n_o       = 1'b1;//ECRC Error Report: The user can assert this signal
                                     //to report an ECRC error (end-to-end CRC).

assign cfg_err_ur_n_o         = 1'b1;//Configuration Error Unsupported Request: The
                                     //user can assert this signal to report that an
                                     //unsupported request was received.

assign cfg_err_cpl_timeout_n_o= 1'b1;//Configuration Error Completion Timeout: The
                                     //user can assert this signal to report a completion
                                     //timed out.
                                     //Note: The user should assert this signal only if the
                                     //device power state is D0. Asserting this signal in
                                     //non-D0 device power states might result in an
                                     //incorrect operation on the PCIe link.

assign cfg_err_cpl_unexpect_n_o= 1'b1;//Configuration Error Completion Unexpected: The
                                      //user can assert this signal to report that an
                                      //unexpected completion was received. (не предсказуемое)

assign cfg_err_cpl_abort_n_o  = 1'b1;//Configuration Error Completion Aborted: The
                                     //user can assert this signal to report that a completion
                                     //was aborted.

assign cfg_err_posted_n_o     = 1'b0;//Configuration Error Posted: This signal is used to
                                     //further qualify any of the cfg_err_* input signals.
                                     //When this input is asserted concurrently with one of
                                     //the other signals, it indicates that the transaction
                                     //which caused the error was a posted transaction.

assign cfg_err_cor_n_o        = 1'b1;//Configuration Error Correctable Error: The user
                                     //can assert this signal to report that a correctable
                                     //error was detected.

assign cfg_err_tlp_cpl_header_o = 0; //Configuration Error TLP Completion Header:
                                     //Accepts the header information from the user when
                                     //an error is signaled. This information is required so
                                     //that the core can issue a correct completion, if
                                     //required.
                                     //The following information should be extracted from
                                     //the received error TLP and presented in the format
                                     //below:
                                     //[47:41]     Lower Address
                                     //[40:29]     Byte Count
                                     //[28:26]     TC
                                     //[25:24]     Attr
                                     //[23:8]      Requester ID
                                     //[7:0]       Tag

assign cfg_pm_wake_n_o        = 1'b1;
assign trn_terrfwd_n_o        = 1'b1; //The trn_terrfwd_n signal does not exist. см pcie_blk_plus_ug341.pdf
assign cfg_trn_pending_n_o    = 1'b1; //If asserted, sets the Transactions Pending bit in the Device Status Register.
                                      //Note: The user is required to assert this input if the
                                      //User Application has not received a completion to an upstream request.

                                      //When set to one, indicates that this function has issued non-posted request
                                      //packets which have not yet been completed (either by the receipt of
                                      //a corresponding Completion, or by the Completion Timeout mechanism).
                                      //A function reports this bit cleared only when all outstanding
                                      //non-posted requests have completed or have been terminated by the Completion Timeout mechanism.


assign cfg_dsn_sw = `C_PCIEXP_DEVICE_SERIAL_NUMBER;
assign cfg_dsn_o  = {{cfg_dsn_sw[07:00]},
                     {cfg_dsn_sw[15:08]},
                     {cfg_dsn_sw[23:16]},
                     {cfg_dsn_sw[31:24]},
                     {cfg_dsn_sw[39:32]},
                     {cfg_dsn_sw[47:40]},
                     {cfg_dsn_sw[55:48]},
                     {cfg_dsn_sw[63:56]}};


assign  init_rst_o     = trn_dma_rst;
assign  trn_rnp_ok_n_o = trn_rnp_ok_n;

//`ifdef PCIEBLK
//assign  trn_rcpl_streaming_n_o = ~cpl_streaming;
//`endif
assign  trn_rcpl_streaming_n_o = cpl_streaming;

////add 2010.11.25
//assign cfg_msi_enable = cfg_interrupt_msienable_i;
`ifndef PCIEBLK
assign  cfg_msi_enable = cfg_interrupt_msienable_i;
`else
assign  cfg_msi_enable = cfg_msi_enable_tmp;
`endif
//----------------


//-------------------------------------------
// Контроллер Usr Application :
//-------------------------------------------
//pciexp_usr_ctrl #(G_DBG) m_USR_CTRL
pciexp_usr_ctrl m_USR_CTRL
(
  .p_in_tst_irq_ctrl(tst_irq_ctrl),
  .p_out_tst_irq_ctrl_out(tst_irq_ctrl_out),
  .p_in_tst_cur_mwr_pkt_count(tst_cur_mwr_pkt_count),
//  .p_in_tst_cur_mwr_len_count(tst_cur_mwr_len_count),
  .p_in_tst_cur_mrd_pkt_count(mrd_pkt_count),
  .p_in_tst_rdy_del_inv(tst_rdy_del_inv),

  .p_out_host_clk_out(p_out_host_clk_out),

  .p_out_usr_tst(p_out_usr_tst),//(out_usr_tst),
  .p_in_usr_tst(p_in_usr_tst),

  .p_out_glob_ctrl(p_out_glob_ctrl),

  .p_out_dev_ctrl(p_out_dev_ctrl),
  .p_out_dev_din(p_out_dev_din),
  .p_in_dev_dout(p_in_dev_dout),
  .p_out_dev_wd(p_out_dev_wd),
  .p_out_dev_rd(p_out_dev_rd),
  .p_in_dev_fifoflag(p_in_dev_fifoflag),
  .p_in_dev_status(p_in_dev_status),
  .p_in_dev_irq(p_in_dev_irq),
  .p_in_dev_option(p_in_dev_option),

  .p_out_mem_ctl_reg(p_out_mem_ctl_reg),
  .p_out_mem_mode_reg(p_out_mem_mode_reg),
  .p_in_mem_locked(p_in_mem_locked),
  .p_in_mem_trained(p_in_mem_trained),

  .p_out_mem_bank1h(p_out_mem_bank1h),
  .p_out_mem_adr(p_out_mem_adr),
  .p_out_mem_ce(p_out_mem_ce),
  .p_out_mem_cw(p_out_mem_cw),
  .p_out_mem_rd(p_out_mem_rd),
  .p_out_mem_wr(p_out_mem_wr),
  .p_out_mem_be(p_out_mem_be),
  .p_out_mem_term(p_out_mem_term),
  .p_out_mem_din(p_out_mem_din),
  .p_in_mem_dout(p_in_mem_dout),

  .p_in_mem_wf(p_in_mem_wf),
  .p_in_mem_wpf(p_in_mem_wpf),
  .p_in_mem_re(p_in_mem_re),
  .p_in_mem_rpe(p_in_mem_rpe),

//--------------------------------------
//--//Связь с m_RX_ENGINE/m_TX_ENGINE
//--------------------------------------
//  .p_in_mst_tx_mem_start(mst_tx_mem_start),
//  .p_in_mst_tx_mem_term(mst_tx_mem_term),

//  .p_in_usr_txbuf_din_be(),
  .p_in_mst_usr_txbuf_din(usr_txbuf_din),
  .p_in_mst_usr_txbuf_wd(usr_txbuf_wd),
  .p_in_mst_usr_txbuf_wd_last(usr_txbuf_wd_last),
  .p_out_mst_usr_txbuf_full(usr_txbuf_full),

//  .p_in_usr_tx_data_be(),
  .p_out_mst_usr_rxbuf_dout(usr_rxbuf_dout),
  .p_in_mst_usr_rxbuf_rd(usr_rxbuf_rd),
  .p_in_mst_usr_rxbuf_rd_last(usr_rxbuf_rd_last),
  .p_in_mst_usr_rxbuf_rd_start(usr_rxbuf_rd_start),
  .p_out_mst_usr_rxbuf_empty(usr_rxbuf_empty),

//  .p_in_trg_be(req_be[3:0]),
  .p_in_trg_addr(trg_addr),//({{req_addr},{2'b0}}),
  .p_in_trg_wr(trg_wr),
  .p_in_trg_rd(trg_rd),
  .p_out_trg_dout(trg_dout),
  .p_in_trg_din(trg_din),

  .p_out_trn_dma_rst(trn_dma_rst),                  // O
  .p_out_trn_dma_init(trn_dma_init),                // O

  .p_out_irq_clr(i_interrupt_clr),
  .p_out_irq_src_adr(i_interrupt_src_adr),
  .p_out_irq_src_set(i_interrupt_src_set),
  .p_in_irq_src_act(i_interrupt_src_act),

  .p_out_mwr_work(mwr_work),                        // O
  .p_in_mwr_done(mwr_done),                         // I
  .p_out_mwr_addr_up(mwr_addr_up),                  // O [7:0]
  .p_out_mwr_addr(mwr_addr),                        // O [31:0]
  .p_out_mwr_len(mwr_len),                          // O [31:0]
  .p_out_mwr_count(mwr_count),                      // O [31:0]
  .p_out_mwr_tlp_tc(mwr_tlp_tc),                    // O [2:0]
  .p_out_mwr_64b(mwr_64b_en),                       // O
  .p_out_mwr_phant_func_en1(mwr_phant_func_en1),    // O
  .p_out_mwr_relaxed_order(mwr_relaxed_order),      // O
  .p_out_mwr_nosnoop(mwr_nosnoop),                  // O
  .p_out_mwr_tag(mwr_tag),
  .p_out_mwr_lbe(mwr_lbe),
  .p_out_mwr_fbe(mwr_fbe),

  .p_out_mrd_work(mrd_work),                        // O
  .p_out_mrd_addr_up(mrd_addr_up),                  // O [7:0]
  .p_out_mrd_addr(mrd_addr),                        // O [31:0]
  .p_out_mrd_len(mrd_len),                          // O [31:0]
  .p_out_mrd_count(mrd_count),                      // O [31:0]
  .p_out_mrd_tlp_tc(mrd_tlp_tc),                    // O [2:0]
  .p_out_mrd_64b(mrd_64b_en),                       // O
  .p_out_mrd_phant_func_en1(mrd_phant_func_en1),    // O
  .p_out_mrd_relaxed_order(mrd_relaxed_order),      // O
  .p_out_mrd_nosnoop(mrd_nosnoop),                  // O
  .p_out_mrd_tag(mrd_tag),
  .p_out_mrd_lbe(mrd_lbe),
  .p_out_mrd_fbe(mrd_fbe),

  .p_in_cpld_total_size(cpld_total_size),            // I [31:0]
  .p_out_cpl_streaming(cpl_streaming),//(trn_rcpl_streaming_n_o),      // O
  .p_out_rd_metering(rd_metering),                   // O
  .p_out_trn_rnp_ok_n(trn_rnp_ok_n),                 // O

  .p_in_cfg_intrrupt_disable(cfg_intrrupt_disable),
  .p_in_cpld_malformed(cpld_malformed),
  .p_in_cfg_msi_enable(cfg_msi_enable),
  .p_in_cfg_cap_max_lnk_width(cfg_cap_max_lnk_width), // I [5:0]
  .p_in_cfg_neg_max_lnk_width(cfg_neg_max_lnk_width), // I [5:0]

  .p_in_cfg_cap_max_payload_size(cfg_cap_max_payload_size), // I [2:0]
  .p_in_cfg_prg_max_payload_size(cfg_prg_max_payload_size), // I [2:0]
  .p_in_cfg_prg_max_rd_req_size(cfg_prg_max_rd_req_size),   // I [2:0]
  .p_in_cfg_phant_func_en(cfg_phant_func_en),
  .p_in_cfg_no_snoop_en(cfg_no_snoop_en),

  .p_out_usr_prg_max_payload_size(usr_prg_max_payload_size),
  .p_out_usr_prg_max_rd_req_size(usr_prg_max_rd_req_size),

  .p_in_clk(trn_clk_i),                               // I
  .p_in_rst_n(bmd_reset_n)                            // I
);

//-------------------------------------------
// Local-Link Receive Controller :
//-------------------------------------------
BMD_ENGINE_RX m_RX_ENGINE
(
    //Port Recieve Data
    .trg_addr_o(trg_addr),
    .trg_rx_data_o(trg_din),
    .trg_rx_data_wd_o(trg_wr),
    .trg_rx_data_rd_o(trg_rd),

//    .mst_rx_addr_o(mst_rx_addr),
    .mst_rx_data_be_o(),//mst_rx_data_be
    .mst_rx_data_o(usr_txbuf_din),
    .mst_rx_data_wd_o(usr_txbuf_wd),
    .mst_rx_data_wd_last_o(usr_txbuf_wd_last),
    .usr_buf_full_i(usr_txbuf_full),

    .tst_rx_engine_state_o(),//tst_rx_engine_state

    //Связь с LocalLink Rx ядра PCI-EXPRESS
    .trn_rd(trn_rd_i),                                 // I [63/31:0]
`ifdef BMD_64
    .trn_rrem_n(trn_rrem_n_i),                         // I [7:0]
`endif // BMD_64
    .trn_rsof_n(trn_rsof_n_i),                         // I
    .trn_reof_n(trn_reof_n_i),                         // I
    .trn_rsrc_rdy_n(trn_rsrc_rdy_n_i),                 // I
    .trn_rsrc_dsc_n(trn_rsrc_dsc_n_i),                 // I
    .trn_rdst_rdy_n_o(trn_rdst_rdy_n_o),               // O
    .trn_rbar_hit_n(trn_rbar_hit_n_i),                 // I [6:0]

    //Handshake with Tx engine
    .req_compl_o(req_compl),                           // O Запрос к TX_ENGINE на пердачу пакета ответа (CplD)
    .compl_done_i(compl_done),                         // I Подтверждение от TX_ENGINE пердача пакета (CplD) - завершена

                                                       // Параметры для формирования пакета ответа (CplD)
    .req_addr_o(req_addr),                             // O [29:0]
    .req_fmt_type_o(req_fmt_type),
    .req_tc_o(req_tc),                                 // O [2:0]
    .req_td_o(req_td),                                 // O
    .req_ep_o(req_ep),                                 // O
    .req_attr_o(req_attr),                             // O [1:0]
    .req_len_o(req_len),                               // O [9:0]
    .req_rid_o(req_rid),                               // O [15:0]
    .req_tag_o(req_tag),                               // O [7:0]
    .req_be_o(req_be),                                 // O [7:0]
    .req_expansion_rom_o(req_expansion_rom),           // O

    //Completion no Data
    .cpl_ur_found_o(),//(cpl_ur_found),                // O [7:0]
    .cpl_ur_tag_o(),//(cpl_ur_tag),                    // O [7:0]

    //Completion with Data
    .cpld_found_o(cpld_found),                         // O [31:0]
    .cpld_total_size_o(cpld_total_size),               // O [31:0]
    .cpld_malformed_o(cpld_malformed),                 // O

    //Initiator reset
    .trn_dma_init_i(trn_dma_init | trn_dma_rst),       // I

    .clk( trn_clk_i ),                                 // I
    .rst_n( bmd_reset_n )                              // I
);


//-------------------------------------------
// Local-Link Transmit Controller
//-------------------------------------------
BMD_ENGINE_TX m_TX_ENGINE
(
    //Transfer Data Port:
    //Режим Target
    .trg_tx_data_i(trg_dout),

    //Режим Master
//    .mst_tx_addr_o(mst_tx_addr),
//    .mst_tx_data_be_o(mst_tx_data_be),
    .mst_tx_data_rd_start_o(usr_rxbuf_rd_start),
    .mst_tx_data_i(usr_rxbuf_dout),
    .mst_tx_data_rd_o(usr_rxbuf_rd),
    .mst_tx_data_rd_last_o(usr_rxbuf_rd_last),
    .usr_buf_empty_i(usr_rxbuf_empty),

    .tst_tx_engine_state_o(),//tst_tx_engine_state
    .tst_cur_mwr_pkt_count_o(tst_cur_mwr_pkt_count),
//    .tst_cur_mwr_len_count_o(tst_cur_mwr_len_count),
    .tst_rdy_del_inv_o(tst_rdy_del_inv),

    //Связь с LocalLink Tx ядра PCI-EXPRESS
    .trn_td(trn_td_o),                                 // O [63/31:0]
`ifdef BMD_64
    .trn_trem_n(trn_trem_n_o),                         // O [7:0]
`endif // BMD_64
    .trn_tsof_n(trn_tsof_n_o),                         // O
    .trn_teof_n(trn_teof_n_o),                         // O
    .trn_tsrc_dsc_n(trn_tsrc_dsc_n_o),                 // O
    .trn_tsrc_rdy_n_o(trn_tsrc_rdy_n_o),               // O
    .trn_tdst_dsc_n(trn_tdst_dsc_n_i),                 // I
    .trn_tdst_rdy_n(trn_tdst_rdy_n_i),                 // I
    .trn_tbuf_av(trn_tbuf_av_i),                       // I [5:0]

    // Handshake with Rx engine
    .req_compl_i(req_compl),                           // I
    .compl_done_o(compl_done),                         // 0

    .req_addr_i(req_addr),                             // I [29:0]
    .req_fmt_type_i(req_fmt_type),
    .req_tc_i(req_tc),                                 // I [2:0]
    .req_td_i(req_td),                                 // I
    .req_ep_i(req_ep),                                 // I
    .req_attr_i(req_attr),                             // I [1:0]
    .req_len_i(req_len),                               // I [9:0]
    .req_rid_i(req_rid),                               // I [15:0]
    .req_tag_i(req_tag),                               // I [7:0]
    .req_be_i(req_be),                                 // I [7:0]
    .req_expansion_rom_i(req_expansion_rom),           // I

    // Write Initiator
    .mwr_work_i(mwr_work),                             // I
    .mwr_done_o(mwr_done),                             // O
    .mwr_addr_up_i(mwr_addr_up),                       // I [7:0]
    .mwr_addr_i(mwr_addr),                             // I [31:0]
    .mwr_len_i(mwr_len),                               // I [31:0]
    .mwr_count_i(mwr_count),                           // I [31:0]
    .mwr_tlp_tc_i(mwr_tlp_tc),                         // I [2:0]
    .mwr_64b_en_i(mwr_64b_en),                         // I
    .mwr_phant_func_en1_i(mwr_phant_func_en1),         // I
    .mwr_lbe_i(mwr_lbe),                               // I [3:0]
    .mwr_fbe_i(mwr_fbe),                               // I [3:0]
    .mwr_tag_i(mwr_tag),                               // I [7:0]
    .mwr_relaxed_order_i(mwr_relaxed_order),           // I
    .mwr_nosnoop_i(mwr_nosnoop),                       // I

    // Read Initiator
    .mrd_work_i(mrd_work_from_rd_throttle),            // I
    .mrd_addr_up_i(mrd_addr_up),                       // I [7:0]
    .mrd_addr_i(mrd_addr),                             // I [31:0]
    .mrd_len_i(mrd_len),                               // I [31:0]
    .mrd_count_i(mrd_count),                           // I [31:0]
    .mrd_tlp_tc_i(mrd_tlp_tc),                         // I [2:0]
    .mrd_64b_en_i(mrd_64b_en),                         // I
    .mrd_phant_func_en1_i(mrd_phant_func_en1),         // I
    .mrd_lbe_i(mrd_lbe),                               // I [3:0]
    .mrd_fbe_i(mrd_fbe),                               // I [3:0]
    .mrd_tag_i(mrd_tag),                               // I [7:0]
    .mrd_relaxed_order_i(mrd_relaxed_order),           // I
    .mrd_nosnoop_i(mrd_nosnoop),                       // I

    .mrd_pkt_count_o(mrd_pkt_count),                   // O[15:0]

    .completer_id_i(cfg_completer_id),                  // I [15:0]
    .cfg_ext_tag_en_i(cfg_ext_tag_en),                  // I
    .cfg_bus_mstr_enable_i(cfg_bus_mstr_enable),        // I
    .cfg_prg_max_payload_size_i(usr_prg_max_payload_size),//(cfg_prg_max_payload_size), // I [2:0]
    .cfg_prg_max_rd_req_size_i(usr_prg_max_rd_req_size),//(cfg_prg_max_rd_req_size),   // I [2:0]
    .cfg_rd_comp_bound_i(cfg_rd_comp_bound),

    // Initiator Controls
    .trn_dma_init_i(trn_dma_init | trn_dma_rst),         // I

    .clk( trn_clk_i ),                                   // I
    .rst_n( bmd_reset_n )                                // I
);

//
// Read Transmit Throttle Unit :
//
BMD_RD_THROTTLE m_RD_THROTTLE
(
    .init_rst_i(trn_dma_init | trn_dma_rst),    // I

    .mrd_work_i(mrd_work),                      // I
    .mrd_len_i(mrd_len),                        // I
    .mrd_pkt_count_i(mrd_pkt_count),            // I [15:0] - сигнал от модуля TX_ENGINE (Кол-во переданых запросов Чтения (пакетов MRr))

    .cpld_found_i(cpld_found),                  // I [31:0] - сигнал от модуля RX_ENGINE (Кол-во принятых пакетов CplDATA)
    .cpld_data_size_i(cpld_total_size),         // I [31:0] - сигнал от модуля RX_ENGINE (Размер данных всех принятых пакетов CplDATA)
    .cpld_malformed_i(cpld_malformed),//(1'b0),// // I - Значение payload size указаное в заголовке пакета не совпало с подсчитаным значение
    .cpld_data_err_i(1'b0),//(cpld_data_err),   // I

    .cpld_data_size_hwm(),//(cpld_data_size_hwm),// O [31:0]
    .cur_rd_count_hwm(),//(cur_rd_count_hwm),    // O [15:0]

    .cfg_rd_comp_bound_i(cfg_rd_comp_bound),     // I //Read Completion Boundary.(RCB = 0=64Byte or 1=128Byte)
    .rd_metering_i(rd_metering),                 // I

    .mrd_work_o(mrd_work_from_rd_throttle),      // O

    .clk( trn_clk_i ),                           // I
    .rst_n( bmd_reset_n )                        // I
);


//
// Interrupt Controller
//
BMD_INTR_CTRL m_INT_CTRL
(
    .p_in_irq_clr(i_interrupt_clr),
    .p_in_irq_src_adr(i_interrupt_src_adr),
    .p_in_irq_src_set(i_interrupt_src_set),
    .p_out_irq_src_act(i_interrupt_src_act),

    .p_in_init_rst(trn_dma_rst),                              // I

    .p_in_cfg_msi_enable(cfg_msi_enable),                     // I
    .p_in_cfg_interrupt_rdy_n( cfg_interrupt_rdy_n_i ),       // I
    .p_out_cfg_interrupt_di(cfg_interrupt_di_o),              // O[7:0]
    .p_out_cfg_interrupt_assert_n( cfg_interrupt_assert_n_o), // 0
    .p_out_cfg_interrupt_n( cfg_interrupt_n_o ),              // O

    .p_in_tst_ctrl(tst_irq_ctrl_out),
    .p_out_tst(tst_irq_ctrl),

    .p_in_clk( trn_clk_i ),                                   // I
    .p_in_rst_n( bmd_reset_n )                                // I
);


//
// Configuration Controller
//
BMD_CFG_CTRL m_CFG_CTRL
(
    .cfg_bus_mstr_enable( cfg_bus_mstr_enable ), // I

    .cfg_do(cfg_do_i),
    .cfg_di(cfg_di_o),
    .cfg_dwaddr(cfg_dwaddr_o),
    .cfg_byte_en_n(cfg_byte_en_n_o),
    .cfg_wr_en_n(cfg_wr_en_n_o),
    .cfg_rd_en_n(cfg_rd_en_n_o),
    .cfg_rd_wr_done_n(cfg_rd_wr_done_n_i),

    .cfg_cap_max_lnk_width(cfg_cap_max_lnk_width),       // O [5:0]
    .cfg_cap_max_payload_size(cfg_cap_max_payload_size), // O [2:0]
    .cfg_msi_enable(cfg_msi_enable_tmp),                 // O

    .rst_n( bmd_reset_n ),                         // I
    .clk( trn_clk_i )                              // I
);

//
// Turn-off Control Unit
//
BMD_TO_CTRL m_TO_CTRL
(
    .req_compl_i( req_compl ),                     // I
    .compl_done_i( compl_done ),                   // I

    .cfg_to_turnoff_n_i( cfg_to_turnoff_n_i ),     // I
    .cfg_turnoff_ok_n_o( cfg_turnoff_ok_n_o ),     // O

    .rst_n( bmd_reset_n ),                         // I
    .clk( trn_clk_i )                              // I
);


endmodule


