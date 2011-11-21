-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11.11.2011 14:41:31
-- Module Name : pcie_ctrl.vhd
--
-- Description : Управление ядром PCI-Express.
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.prj_cfg.all;
use work.pcie_unit_pkg.all;

entity pcie_ctrl is
generic(
G_DBG : string :="OFF"
);
port(
--------------------------------------
--USR Port
--------------------------------------
p_out_hclk                : out   std_logic;

p_out_tst                 : out   std_logic_vector(127 downto 0);
p_in_tst                  : in    std_logic_vector(127 downto 0);

p_out_gctrl               : out   std_logic_vector(31 downto 0);
p_out_dev_ctrl            : out   std_logic_vector(31 downto 0);
p_out_dev_din             : out   std_logic_vector(31 downto 0);
p_in_dev_dout             : in    std_logic_vector(31 downto 0);
p_out_dev_wr              : out   std_logic;
p_out_dev_rd              : out   std_logic;
p_in_dev_status           : in    std_logic_vector(31 downto 0);
p_in_dev_irq              : in    std_logic_vector(31 downto 0);
p_in_dev_opt              : in    std_logic_vector(127 downto 0);
p_out_dev_opt             : out   std_logic_vector(127 downto 0);

--------------------------------------
--Tx
--------------------------------------
trn_td_o                  : out   std_logic_vector(63 downto 0);
trn_trem_n_o              : out   std_logic_vector(7 downto 0);
trn_tsof_n_o              : out   std_logic;
trn_teof_n_o              : out   std_logic;
trn_tsrc_rdy_n_o          : out   std_logic;
trn_tdst_rdy_n_i          : in    std_logic;
trn_tsrc_dsc_n_o          : out   std_logic;
trn_tdst_dsc_n_i          : in    std_logic;
trn_terrfwd_n_o           : out   std_logic;
trn_tbuf_av_i             : in    std_logic_vector(5 downto 0);

--------------------------------------
--Rx
--------------------------------------
trn_rd_i                  : in    std_logic_vector(63 downto 0);
trn_rrem_n_i              : in    std_logic_vector(7 downto 0);
trn_rsof_n_i              : in    std_logic;
trn_reof_n_i              : in    std_logic;
trn_rsrc_rdy_n_i          : in    std_logic;
trn_rsrc_dsc_n_i          : in    std_logic;
trn_rdst_rdy_n_o          : out   std_logic;
trn_rerrfwd_n_i           : in    std_logic;
trn_rnp_ok_n_o            : out   std_logic;

trn_rbar_hit_n_i          : in    std_logic_vector(6 downto 0);
trn_rfc_nph_av_i          : in    std_logic_vector(7 downto 0);
trn_rfc_npd_av_i          : in    std_logic_vector(11 downto 0);
trn_rfc_ph_av_i           : in    std_logic_vector(7 downto 0);
trn_rfc_pd_av_i           : in    std_logic_vector(11 downto 0);
trn_rcpl_streaming_n_o    : out   std_logic;

--------------------------------------
--CFG Interface
--------------------------------------
cfg_turnoff_ok_n_o        : out   std_logic;
cfg_to_turnoff_n_i        : in    std_logic;

cfg_interrupt_n_o         : out   std_logic;
cfg_interrupt_rdy_n_i     : in    std_logic;
cfg_interrupt_assert_n_o  : out   std_logic;
cfg_interrupt_di_o        : out   std_logic_vector(7 downto 0);
cfg_interrupt_do_i        : in    std_logic_vector(7 downto 0);
cfg_interrupt_msienable_i : in    std_logic;
cfg_interrupt_mmenable_i  : in    std_logic_vector(2 downto 0);

cfg_do_i                  : in    std_logic_vector(31 downto 0);
cfg_di_o                  : out   std_logic_vector(31 downto 0);
cfg_dwaddr_o              : out   std_logic_vector(9 downto 0);
cfg_byte_en_n_o           : out   std_logic_vector(3 downto 0);
cfg_wr_en_n_o             : out   std_logic;
cfg_rd_en_n_o             : out   std_logic;
cfg_rd_wr_done_n_i        : in    std_logic;

cfg_err_tlp_cpl_header_o  : out   std_logic_vector(47 downto 0);
cfg_err_ecrc_n_o          : out   std_logic;
cfg_err_ur_n_o            : out   std_logic;
cfg_err_cpl_timeout_n_o   : out   std_logic;
cfg_err_cpl_unexpect_n_o  : out   std_logic;
cfg_err_cpl_abort_n_o     : out   std_logic;
cfg_err_posted_n_o        : out   std_logic;
cfg_err_cor_n_o           : out   std_logic;
cfg_err_locked_n_o        : out   std_logic;
cfg_err_cpl_rdy_n_i       : in    std_logic;

cfg_pm_wake_n_o           : out   std_logic;
cfg_trn_pending_n_o       : out   std_logic;
cfg_dsn_o                 : out   std_logic_vector(63 downto 0);
cfg_pcie_link_state_n_i   : in    std_logic_vector(2 downto 0);
cfg_bus_number_i          : in    std_logic_vector(7 downto 0);
cfg_device_number_i       : in    std_logic_vector(4 downto 0);
cfg_function_number_i     : in    std_logic_vector(2 downto 0);
cfg_status_i              : in    std_logic_vector(15 downto 0);
cfg_command_i             : in    std_logic_vector(15 downto 0);
cfg_dstatus_i             : in    std_logic_vector(15 downto 0);
cfg_dcommand_i            : in    std_logic_vector(15 downto 0);
cfg_lstatus_i             : in    std_logic_vector(15 downto 0);
cfg_lcommand_i            : in    std_logic_vector(15 downto 0);

--------------------------------------
--System Port
--------------------------------------
trn_lnk_up_n_i            : in    std_logic;
trn_clk_i                 : in    std_logic;
trn_reset_n_i             : in    std_logic
);
end pcie_ctrl;

architecture behavioral of pcie_ctrl is

signal i_rst_n                    : std_logic;

signal i_usr_reg_adr              : std_logic_vector(7 downto 0);
signal i_usr_reg_din              : std_logic_vector(31 downto 0);
signal i_usr_reg_dout             : std_logic_vector(31 downto 0);
signal i_usr_reg_wr               : std_logic;
signal i_usr_reg_rd               : std_logic;

signal i_usr_txbuf_din            : std_logic_vector(31 downto 0);
signal i_usr_txbuf_wr             : std_logic;
signal i_usr_txbuf_wr_last        : std_logic;
signal i_usr_txbuf_full           : std_logic;

signal i_usr_rxbuf_dout           : std_logic_vector(31 downto 0);
signal i_usr_rxbuf_rd             : std_logic;
signal i_usr_rxbuf_rd_last        : std_logic;
signal i_usr_rxbuf_empty          : std_logic;

signal i_usr_max_payload_size     : std_logic_vector(2 downto 0);
signal i_usr_max_rd_req_size      : std_logic_vector(2 downto 0);

signal i_req_compl                : std_logic;
signal i_compl_done               : std_logic;

signal i_req_addr                 : std_logic_vector(29 downto 0);
signal i_req_fmt_type             : std_logic_vector(6 downto 0);
signal i_req_tc                   : std_logic_vector(2 downto 0);
signal i_req_td                   : std_logic;
signal i_req_ep                   : std_logic;
signal i_req_attr                 : std_logic_vector(1 downto 0);
signal i_req_len                  : std_logic_vector(9 downto 0);
signal i_req_rid                  : std_logic_vector(15 downto 0);
signal i_req_tag                  : std_logic_vector(7 downto 0);
signal i_req_be                   : std_logic_vector(7 downto 0);
signal i_req_expansion_rom        : std_logic;

signal i_dmatrn_init              : std_logic;

signal i_mwr_work                 : std_logic;
signal i_mwr_done                 : std_logic;
signal i_mwr_addr                 : std_logic_vector(31 downto 0);
signal i_mwr_len                  : std_logic_vector(31 downto 0);
signal i_mwr_count                : std_logic_vector(31 downto 0);
signal i_mwr_tlp_tc               : std_logic_vector(2 downto 0);
signal i_mwr_64b_en               : std_logic;
signal i_mwr_phant_func_en1       : std_logic;
signal i_mwr_addr_up              : std_logic_vector(7 downto 0);
signal i_mwr_relaxed_order        : std_logic;
signal i_mwr_nosnoop              : std_logic;
signal i_mwr_tag                  : std_logic_vector(7 downto 0);
signal i_mwr_lbe                  : std_logic_vector(3 downto 0);
signal i_mwr_fbe                  : std_logic_vector(3 downto 0);

signal i_mrd_work                 : std_logic;
signal i_mrd_addr                 : std_logic_vector(31 downto 0);
signal i_mrd_len                  : std_logic_vector(31 downto 0);
signal i_mrd_count                : std_logic_vector(31 downto 0);
signal i_mrd_tlp_tc               : std_logic_vector(2 downto 0);
signal i_mrd_64b_en               : std_logic;
signal i_mrd_phant_func_en1       : std_logic;
signal i_mrd_addr_up              : std_logic_vector(7 downto 0);
signal i_mrd_relaxed_order        : std_logic;
signal i_mrd_nosnoop              : std_logic;
signal i_mrd_tag                  : std_logic_vector(7 downto 0);
signal i_mrd_lbe                  : std_logic_vector(3 downto 0);
signal i_mrd_fbe                  : std_logic_vector(3 downto 0);
signal i_mrd_rcv_size             : std_logic_vector(31 downto 0);
signal i_mrd_rcv_err              : std_logic;
signal i_mrd_work_throttle        : std_logic;
signal i_mrd_pkt_count            : std_logic_vector(15 downto 0);
signal i_mrd_pkt_len              : std_logic_vector(31 downto 0);

signal i_cpl_streaming            : std_logic;
signal i_rd_metering              : std_logic;
signal i_trn_rnp_ok_n             : std_logic;

signal i_irq_ctrl_rst             : std_logic;
signal i_irq_clr                  : std_logic;
signal i_irq_num                  : std_logic_vector(15 downto 0);
signal i_irq_set                  : std_logic_vector(15 downto 0);
signal i_irq_status               : std_logic_vector(15 downto 0);

signal i_cfg_msi_enable           : std_logic;
signal i_cfg_cap_max_lnk_width    : std_logic_vector(5 downto 0);
signal i_cfg_cap_max_payload_size : std_logic_vector(2 downto 0);
signal i_cfg_completer_id         : std_logic_vector(15 downto 0);
signal i_cfg_neg_max_lnk_width    : std_logic_vector(5 downto 0);
signal i_cfg_rcb                  : std_logic;
signal i_cfg_prg_max_payload_size : std_logic_vector(2 downto 0);
signal i_cfg_prg_max_rd_req_size  : std_logic_vector(2 downto 0);
signal i_cfg_ext_tag_en           : std_logic;
signal i_cfg_phant_func_en        : std_logic;
signal i_cfg_no_snoop_en          : std_logic;
signal i_cfg_bus_mstr_enable      : std_logic;
signal i_cfg_intrrupt_disable     : std_logic;


signal i_rx_engine_tst_out        : std_logic_vector(1 downto 0);
signal i_rx_engine_tst2_out       : std_logic_vector(9 downto 0);
signal i_rd_throttle_tst_out      : std_logic_vector(1 downto 0);
signal i_pice_irq_tst_in          : std_logic_vector(31 downto 0);
signal i_pice_irq_tst_out         : std_logic_vector(31 downto 0);


--//MAIN
begin


--//--------------------------------------
--//Технологические
--//--------------------------------------
i_rd_throttle_tst_out(0) <= i_mrd_work_throttle;
i_rd_throttle_tst_out(1) <='0';


--//--------------------------------------
--//Выходные сигналы
--//--------------------------------------
trn_rnp_ok_n_o <= '0';--i_trn_rnp_ok_n;
trn_rcpl_streaming_n_o <= i_cpl_streaming;

cfg_pm_wake_n_o        <='1';
trn_terrfwd_n_o        <='1';
cfg_trn_pending_n_o    <='1';

cfg_err_locked_n_o     <='1';
cfg_err_ecrc_n_o       <='1';
cfg_err_ur_n_o         <='1';
cfg_err_cpl_timeout_n_o<='1';
cfg_err_cpl_unexpect_n_o<='1';
cfg_err_cor_n_o        <='1';
cfg_err_posted_n_o     <='0';
cfg_err_cpl_abort_n_o  <='1';--//Configuration Error Completion Aborted: The
                             --//user can assert this signal to report that a completion
                             --//was aborted.
cfg_err_tlp_cpl_header_o <=(others=>'0'); --//Configuration Error TLP Completion Header:
                                          --//Accepts the header information from the user when
                                          --//an error is signaled. This information is required so
                                          --//that the core can issue a correct completion, if
                                          --//required.
                                          --//The following information should be extracted from
                                          --//the received error TLP and presented in the format
                                          --//below:
                                          --//[47:41]     Lower Address
                                          --//[40:29]     Byte Count
                                          --//[28:26]     TC
                                          --//[25:24]     Attr
                                          --//[23:8]      Requester ID
                                          --//[7:0]       Tag

cfg_dsn_o <=CONV_STD_LOGIC_VECTOR(16#123#, cfg_dsn_o'length);


--//--------------------------------------
--//
--//--------------------------------------
i_rst_n <= trn_reset_n_i and not trn_lnk_up_n_i;


i_cfg_completer_id <= cfg_bus_number_i & cfg_device_number_i & cfg_function_number_i;

--//Link Status register in the PCI Express Capabilities Structure
i_cfg_neg_max_lnk_width <= cfg_lstatus_i(9 downto 4);--//Negotiated Link Width

--//Link Control register in the PCI Express Capabilities Structure
i_cfg_rcb <= cfg_lcommand_i(3);--//Read Completion Boundary.(RCB) 0=64B or 1=128B

--//Device Control register in the PCI Express Capabilities Structure
i_cfg_prg_max_payload_size <= cfg_dcommand_i(7 downto 5);
i_cfg_prg_max_rd_req_size <= cfg_dcommand_i(14 downto 12);
i_cfg_ext_tag_en    <= cfg_dcommand_i(8);
i_cfg_phant_func_en <= cfg_dcommand_i(9);
i_cfg_no_snoop_en   <= cfg_dcommand_i(11);

--//Command register in the PCI Configuration Space Header
i_cfg_bus_mstr_enable <= cfg_command_i(2);
i_cfg_intrrupt_disable <= cfg_command_i(10);

i_cfg_msi_enable <= cfg_interrupt_msienable_i;


--//###########################################
--//Usr Application :
--//###########################################
m_usr_app : pcie_usr_app
generic map(
G_DBG => G_DBG
)
port map(
p_out_hclk                    => p_out_hclk,

p_out_gctrl                   => p_out_gctrl,
p_out_dev_ctrl                => p_out_dev_ctrl,
p_out_dev_din                 => p_out_dev_din,
p_in_dev_dout                 => p_in_dev_dout,
p_out_dev_wr                  => p_out_dev_wr,
p_out_dev_rd                  => p_out_dev_rd,
p_in_dev_status               => p_in_dev_status,
p_in_dev_irq                  => p_in_dev_irq,
p_in_dev_opt                  => p_in_dev_opt,
p_out_dev_opt                 => p_out_dev_opt,

p_out_tst                     => p_out_tst,
p_in_tst                      => p_in_tst,

------------------------------
--Связь с m_pcie_rx/tx
------------------------------
p_in_txbuf_din                => i_usr_txbuf_din,
p_in_txbuf_wr                 => i_usr_txbuf_wr,
p_in_txbuf_wr_last            => i_usr_txbuf_wr_last,
p_out_txbuf_full              => i_usr_txbuf_full,

p_out_rxbuf_dout              => i_usr_rxbuf_dout,
p_in_rxbuf_rd                 => i_usr_rxbuf_rd,
p_in_rxbuf_rd_last            => i_usr_rxbuf_rd_last,
p_out_rxbuf_empty             => i_usr_rxbuf_empty,

p_in_reg_adr                  => i_usr_reg_adr,
p_in_reg_wr                   => i_usr_reg_wr,
p_in_reg_rd                   => i_usr_reg_rd,
p_out_reg_dout                => i_usr_reg_dout,
p_in_reg_din                  => i_usr_reg_din,

p_out_dmatrn_init             => i_dmatrn_init,

p_out_mwr_work                => i_mwr_work,
p_in_mwr_done                 => i_mwr_done,
p_out_mwr_addr_up             => i_mwr_addr_up,
p_out_mwr_addr                => i_mwr_addr,
p_out_mwr_len                 => i_mwr_len,
p_out_mwr_count               => i_mwr_count,
p_out_mwr_tlp_tc              => i_mwr_tlp_tc,
p_out_mwr_64b                 => i_mwr_64b_en,
p_out_mwr_phant_func_en1      => i_mwr_phant_func_en1,
p_out_mwr_relaxed_order       => i_mwr_relaxed_order,
p_out_mwr_nosnoop             => i_mwr_nosnoop,
p_out_mwr_tag                 => i_mwr_tag,
p_out_mwr_lbe                 => i_mwr_lbe,
p_out_mwr_fbe                 => i_mwr_fbe,

p_out_mrd_work                => i_mrd_work,
p_out_mrd_addr_up             => i_mrd_addr_up,
p_out_mrd_addr                => i_mrd_addr,
p_out_mrd_len                 => i_mrd_len,
p_out_mrd_count               => i_mrd_count,
p_out_mrd_tlp_tc              => i_mrd_tlp_tc,
p_out_mrd_64b                 => i_mrd_64b_en,
p_out_mrd_phant_func_en1      => i_mrd_phant_func_en1,
p_out_mrd_relaxed_order       => i_mrd_relaxed_order,
p_out_mrd_nosnoop             => i_mrd_nosnoop,
p_out_mrd_tag                 => i_mrd_tag,
p_out_mrd_lbe                 => i_mrd_lbe,
p_out_mrd_fbe                 => i_mrd_fbe,
p_in_mrd_rcv_size             => i_mrd_rcv_size,
p_in_mrd_rcv_err              => i_mrd_rcv_err,

p_out_irq_clr                 => i_irq_clr,
p_out_irq_num                 => i_irq_num,
p_out_irq_set                 => i_irq_set,
p_in_irq_status               => i_irq_status,

p_out_cpl_streaming           => i_cpl_streaming,
p_out_rd_metering             => i_rd_metering,
p_out_trn_rnp_ok_n            => i_trn_rnp_ok_n,
p_out_usr_max_payload_size    => i_usr_max_payload_size,
p_out_usr_max_rd_req_size     => i_usr_max_rd_req_size,

p_in_cfg_irq_disable          => i_cfg_intrrupt_disable,
p_in_cfg_msi_enable           => i_cfg_msi_enable,
p_in_cfg_cap_max_lnk_width    => i_cfg_cap_max_lnk_width,
p_in_cfg_neg_max_lnk_width    => i_cfg_neg_max_lnk_width,
p_in_cfg_cap_max_payload_size => i_cfg_cap_max_payload_size,
p_in_cfg_prg_max_payload_size => i_cfg_prg_max_payload_size,
p_in_cfg_prg_max_rd_req_size  => i_cfg_prg_max_rd_req_size,
p_in_cfg_phant_func_en        => i_cfg_phant_func_en,
p_in_cfg_no_snoop_en          => i_cfg_no_snoop_en,
p_in_cfg_ext_tag_en           => i_cfg_ext_tag_en,

p_in_rx_engine_tst            => i_rx_engine_tst_out,
p_in_rx_engine_tst2           => i_rx_engine_tst2_out,
p_in_throttle_tst             => i_rd_throttle_tst_out,
p_in_mrd_pkt_len_tst          => i_mrd_pkt_len,

p_in_clk                      => trn_clk_i,
p_in_rst_n                    => i_rst_n
);


--//###########################################
--//Управление ядром PCI-Express
--//###########################################
--//----------------------------------
--//Rx/Tx Ctrl
--//----------------------------------
m_rx : pcie_rx
port map(
tst_o               => i_rx_engine_tst_out,
tst2_o              => i_rx_engine_tst2_out,

--режим Target
usr_reg_adr_o       => i_usr_reg_adr,
usr_reg_din_o       => i_usr_reg_din,
usr_reg_wr_o        => i_usr_reg_wr,
usr_reg_rd_o        => i_usr_reg_rd,

--режим Master
usr_txbuf_din_o     => i_usr_txbuf_din,
usr_txbuf_wr_o      => i_usr_txbuf_wr,
usr_txbuf_wr_last_o => i_usr_txbuf_wr_last,
usr_txbuf_full_i    => i_usr_txbuf_full,
--usr_txbuf_dbe_o   => open,

--Связь с LocalLink Rx ядра PCI-EXPRESS
trn_rd              => trn_rd_i,
trn_rrem_n          => trn_rrem_n_i,
trn_rsof_n          => trn_rsof_n_i,
trn_reof_n          => trn_reof_n_i,
trn_rsrc_rdy_n      => trn_rsrc_rdy_n_i,
trn_rsrc_dsc_n      => trn_rsrc_dsc_n_i,
trn_rdst_rdy_n_o    => trn_rdst_rdy_n_o,
trn_rbar_hit_n      => trn_rbar_hit_n_i,

--Handshake with Tx engine
req_compl_o         => i_req_compl,
compl_done_i        => i_compl_done,

req_addr_o          => i_req_addr,
req_fmt_type_o      => i_req_fmt_type,
req_tc_o            => i_req_tc,
req_td_o            => i_req_td,
req_ep_o            => i_req_ep,
req_attr_o          => i_req_attr,
req_len_o           => i_req_len,
req_rid_o           => i_req_rid,
req_tag_o           => i_req_tag,
req_be_o            => i_req_be,
req_expansion_rom_o => i_req_expansion_rom,

--Completion with Data
cpld_total_size_o   => i_mrd_rcv_size,
cpld_malformed_o    => i_mrd_rcv_err,

--Initiator reset
trn_dma_init_i      => i_dmatrn_init,

clk                 => trn_clk_i,
rst_n               => i_rst_n
);


m_tx : pcie_tx
port map(
--Режим Target
usr_reg_dout_i       => i_usr_reg_dout,

--Режим Master
usr_rxbuf_dout_i     => i_usr_rxbuf_dout,
usr_rxbuf_rd_o       => i_usr_rxbuf_rd,
usr_rxbuf_rd_fst_o   => open,
usr_rxbuf_rd_last_o  => i_usr_rxbuf_rd_last,
usr_rxbuf_empty_i    => i_usr_rxbuf_empty,

--Связь с LocalLink Tx ядра PCI-EXPRESS
trn_td               => trn_td_o,              --// O [63/31:0]
trn_trem_n           => trn_trem_n_o,          --// O [7:0]
trn_tsof_n           => trn_tsof_n_o,          --// O
trn_teof_n           => trn_teof_n_o,          --// O
trn_tsrc_dsc_n       => trn_tsrc_dsc_n_o,      --// O
trn_tsrc_rdy_n_o     => trn_tsrc_rdy_n_o,      --// O
trn_tdst_dsc_n       => trn_tdst_dsc_n_i,      --// I
trn_tdst_rdy_n       => trn_tdst_rdy_n_i,      --// I
trn_tbuf_av          => trn_tbuf_av_i,         --// I [5:0]

--Handshake with Rx egine
req_compl_i          => i_req_compl,           --// I
compl_done_o         => i_compl_done,          --// 0

req_addr_i           => i_req_addr,            --// I [29:0]
req_fmt_type_i       => i_req_fmt_type,        --
req_tc_i             => i_req_tc,              --// I [2:0]
req_td_i             => i_req_td,              --// I
req_ep_i             => i_req_ep,              --// I
req_attr_i           => i_req_attr,            --// I [1:0]
req_len_i            => i_req_len,             --// I [9:0]
req_rid_i            => i_req_rid,             --// I [15:0]
req_tag_i            => i_req_tag,             --// I [7:0]
req_be_i             => i_req_be,              --// I [7:0]
req_expansion_rom_i  => i_req_expansion_rom,   --// I

--Initiator Controls
trn_dma_init_i       => i_dmatrn_init,         --// I

--Write Initiator
mwr_work_i           => i_mwr_work,            --// I
mwr_done_o           => i_mwr_done,            --// O
mwr_addr_up_i        => i_mwr_addr_up,         --// I [7:0]
mwr_addr_i           => i_mwr_addr,            --// I [31:0]
mwr_len_i            => i_mwr_len,             --// I [31:0]
mwr_count_i          => i_mwr_count,           --// I [31:0]
mwr_tlp_tc_i         => i_mwr_tlp_tc,          --// I [2:0]
mwr_64b_en_i         => i_mwr_64b_en,          --// I
mwr_phant_func_en1_i => i_mwr_phant_func_en1,  --// I
mwr_lbe_i            => i_mwr_lbe,             --// I [3:0]
mwr_fbe_i            => i_mwr_fbe,             --// I [3:0]
mwr_tag_i            => i_mwr_tag,             --// I [7:0]
mwr_relaxed_order_i  => i_mwr_relaxed_order,   --// I
mwr_nosnoop_i        => i_mwr_nosnoop,         --// I

--Read Initiator
mrd_work_i           => i_mrd_work_throttle,   --// I
mrd_addr_up_i        => i_mrd_addr_up,         --// I [7:0]
mrd_addr_i           => i_mrd_addr,            --// I [31:0]
mrd_len_i            => i_mrd_len,             --// I [31:0]
mrd_count_i          => i_mrd_count,           --// I [31:0]
mrd_tlp_tc_i         => i_mrd_tlp_tc,          --// I [2:0]
mrd_64b_en_i         => i_mrd_64b_en,          --// I
mrd_phant_func_en1_i => i_mrd_phant_func_en1,  --// I
mrd_lbe_i            => i_mrd_lbe,             --// I [3:0]
mrd_fbe_i            => i_mrd_fbe,             --// I [3:0]
mrd_tag_i            => i_mrd_tag,             --// I [7:0]
mrd_relaxed_order_i  => i_mrd_relaxed_order,   --// I
mrd_nosnoop_i        => i_mrd_nosnoop,         --// I
mrd_pkt_len_o        => i_mrd_pkt_len,         --// O[31:0]
mrd_pkt_count_o      => i_mrd_pkt_count,       --// O[15:0]

completer_id_i       => i_cfg_completer_id,    --// I [15:0]
tag_ext_en_i         => i_cfg_ext_tag_en,      --// I
mstr_enable_i        => i_cfg_bus_mstr_enable, --// I
max_payload_size_i   => i_usr_max_payload_size,--i_cfg_prg_max_payload_size, // I [2:0]
max_rd_req_size_i    => i_usr_max_rd_req_size, --i_cfg_prg_max_rd_req_size,  // I [2:0]

clk                  => trn_clk_i,
rst_n                => i_rst_n
);


--//----------------------------------
--//Read Transmit Throttle Unit :
--//----------------------------------
m_mrd_throttle : pcie_mrd_throttle
port map(
init_rst_i          => i_dmatrn_init,       --// I

mrd_work_i          => i_mrd_work,          --// I
mrd_len_i           => i_mrd_pkt_len,       --//(mrd_len,                        // I [31:0]
mrd_pkt_count_i     => i_mrd_pkt_count,     --// I [15:0] - сигнал от модуля TX_ENGINE (Кол-во переданых запросов Чтения (пакетов MRr))

--cpld_found_i(cpld_found,                  --// I [31:0] - сигнал от модуля RX_ENGINE (Кол-во принятых пакетов CplDATA)
cpld_data_size_i    => i_mrd_rcv_size,      --// I [31:0] - сигнал от модуля RX_ENGINE (Размер данных всех принятых пакетов CplDATA)
cpld_malformed_i    => i_mrd_rcv_err,       --// I - Значение payload size указаное в заголовке пакета не совпало с подсчитаным значение
cpld_data_err_i     => '0',                 --// I

cfg_rd_comp_bound_i => i_cfg_rcb,           --// I //Read Completion Boundary.(RCB = 0=64Byte or 1=128Byte)
rd_metering_i       => i_rd_metering,       --// I

mrd_work_o          => i_mrd_work_throttle, --// O

clk                 =>  trn_clk_i ,
rst_n               =>  i_rst_n
);


--//----------------------------------
--//Interrupt Controller
--//----------------------------------
i_irq_ctrl_rst <= not i_rst_n;

m_irq : pcie_irq
port map(
p_in_irq_clr           => i_irq_clr,
p_in_irq_num           => i_irq_num,
p_in_irq_set           => i_irq_set,
p_out_irq_status       => i_irq_status,

p_in_cfg_irq_dis       => i_cfg_intrrupt_disable,
p_in_cfg_msi           => i_cfg_msi_enable,
p_in_cfg_irq_rdy_n     => cfg_interrupt_rdy_n_i ,
p_out_cfg_irq_assert_n => cfg_interrupt_assert_n_o,
p_out_cfg_irq_n        => cfg_interrupt_n_o,
p_out_cfg_irq_di       => cfg_interrupt_di_o,

p_in_tst               => (others=>'0'),--i_pice_irq_tst_in,--
p_out_tst              => open, --i_pcie_irq_tst_out,

p_in_clk               => trn_clk_i,
p_in_rst               => i_irq_ctrl_rst --i_rst_n
);


--//----------------------------------
--//Configuration Controller
--//----------------------------------
m_cfg : pcie_cfg
port map(
cfg_bus_mstr_enable => i_cfg_bus_mstr_enable, --// I

cfg_do              =>cfg_do_i,
cfg_di              =>cfg_di_o,
cfg_dwaddr          =>cfg_dwaddr_o,
cfg_byte_en_n       =>cfg_byte_en_n_o,
cfg_wr_en_n         =>cfg_wr_en_n_o,
cfg_rd_en_n         =>cfg_rd_en_n_o,
cfg_rd_wr_done_n    =>cfg_rd_wr_done_n_i,

cfg_cap_max_lnk_width    => i_cfg_cap_max_lnk_width,    --// O [5:0]
cfg_cap_max_payload_size => i_cfg_cap_max_payload_size, --// O [2:0]
cfg_msi_enable           => open, --i_cfg_msi_enable_tmp,  // O

rst_n               => i_rst_n,
clk                 => trn_clk_i
);


--//----------------------------------
--//Turn-off Control Unit
--//----------------------------------
m_off_on : pcie_off_on
port map(
req_compl_i        => i_req_compl,       --// I
compl_done_i       => i_compl_done,      --// I

cfg_to_turnoff_n_i => cfg_to_turnoff_n_i,-- // I
cfg_turnoff_ok_n_o => cfg_turnoff_ok_n_o,-- // O

rst_n => i_rst_n,
clk   => trn_clk_i
);


--END MAIN
end behavioral;


