-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11.11.2011 14:41:31
-- Module Name : pcie_ctrl.vhd
--
-- Description : CTRL core PCI-Express
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pcie_unit_pkg.all;
use work.prj_def.all;
use work.prj_cfg.all;

entity pcie_ctrl is
generic(
G_PCIEXP_TRN_DBUS : integer:=64;
G_DBG : string :="OFF"
);
port(
--------------------------------------
--USR Port
--------------------------------------
p_out_hclk                 : out   std_logic;
p_out_gctrl                : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--CTRL user devices
p_out_dev_ctrl             : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din              : out   std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_in_dev_dout              : in    std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_out_dev_wr               : out   std_logic;
p_out_dev_rd               : out   std_logic;
p_in_dev_status            : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq               : in    std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
p_in_dev_opt               : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
p_out_dev_opt              : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

--DBG
p_out_tst                  : out   std_logic_vector(127 downto 0);
p_in_tst                   : in    std_logic_vector(127 downto 0);

--------------------------------------
--Tx
--------------------------------------
trn_td_o                  : out   std_logic_vector(G_PCIEXP_TRN_DBUS-1 downto 0);
trn_trem_n_o              : out   std_logic_vector(3 downto 0);
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
trn_rd_i                  : in    std_logic_vector(G_PCIEXP_TRN_DBUS-1 downto 0);
trn_rrem_n_i              : in    std_logic_vector(3 downto 0);
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
end entity pcie_ctrl;

architecture struct of pcie_ctrl is

component pcie_rx
port(
usr_reg_adr_o       : out std_logic_vector(7 downto 0);
usr_reg_din_o       : out std_logic_vector(31 downto 0);
usr_reg_wr_o        : out std_logic;
usr_reg_rd_o        : out std_logic;

--usr_txbuf_dbe_o     : out  std_logic_vector(7 downto 0);
usr_txbuf_din_o     : out std_logic_vector(31 downto 0);
usr_txbuf_wr_o      : out std_logic;
usr_txbuf_wr_last_o : out std_logic;
usr_txbuf_full_i    : in  std_logic;

trn_rd              : in  std_logic_vector(G_PCIEXP_TRN_DBUS-1 downto 0);
trn_rrem_n          : in  std_logic_vector(3 downto 0);
trn_rsof_n          : in  std_logic;
trn_reof_n          : in  std_logic;
trn_rsrc_rdy_n      : in  std_logic;
trn_rsrc_dsc_n      : in  std_logic;
trn_rdst_rdy_n_o    : out std_logic;
trn_rbar_hit_n      : in  std_logic_vector(6 downto 0);

req_compl_o         : out std_logic;
compl_done_i        : in  std_logic;

req_addr_o          : out std_logic_vector(29 downto 0);
req_pkt_type_o      : out std_logic_vector(6 downto 0);
req_tc_o            : out std_logic_vector(2 downto 0);
req_td_o            : out std_logic;
req_ep_o            : out std_logic;
req_attr_o          : out std_logic_vector(1 downto 0);
req_len_o           : out std_logic_vector(9 downto 0);
req_rid_o           : out std_logic_vector(15 downto 0);
req_tag_o           : out std_logic_vector(7 downto 0);
req_be_o            : out std_logic_vector(7 downto 0);
req_exprom_o        : out std_logic;

dma_init_i          : in  std_logic;

cpld_total_size_o   : out std_logic_vector(31 downto 0);
cpld_malformed_o    : out std_logic;

tst_o               : out std_logic_vector(31 downto 0);
tst_i               : in  std_logic_vector(31 downto 0);

clk                 : in  std_logic;
rst_n               : in  std_logic
);
end component;

component pcie_tx
generic(
G_USR_DBUS : integer:=64
);
port(
usr_reg_dout_i       : in  std_logic_vector(31 downto 0);

--usr_rxbuf_dbe        : out std_logic_vector(3 downto 0);
usr_rxbuf_dout_i     : in  std_logic_vector(G_USR_DBUS-1 downto 0);
usr_rxbuf_rd_o       : out std_logic;
usr_rxbuf_rd_last_o  : out std_logic;
usr_rxbuf_empty_i    : in  std_logic;

trn_td               : out std_logic_vector(G_PCIEXP_TRN_DBUS-1 downto 0);
trn_trem_n           : out std_logic_vector(3 downto 0);
trn_tsof_n           : out std_logic;
trn_teof_n           : out std_logic;
trn_tsrc_rdy_n_o     : out std_logic;
trn_tsrc_dsc_n       : out std_logic;
trn_tdst_rdy_n       : in  std_logic;
trn_tdst_dsc_n       : in  std_logic;
trn_tbuf_av          : in  std_logic_vector(5 downto 0);

req_compl_i          : in  std_logic;
compl_done_o         : out std_logic;

req_addr_i           : in  std_logic_vector(29 downto 0);
req_pkt_type_i       : in  std_logic_vector(6 downto 0);
req_tc_i             : in  std_logic_vector(2 downto 0);
req_td_i             : in  std_logic;
req_ep_i             : in  std_logic;
req_attr_i           : in  std_logic_vector(1 downto 0);
req_len_i            : in  std_logic_vector(9 downto 0);
req_rid_i            : in  std_logic_vector(15 downto 0);
req_tag_i            : in  std_logic_vector(7 downto 0);
req_be_i             : in  std_logic_vector(7 downto 0);
req_exprom_i         : in  std_logic;

dma_init_i           : in  std_logic;

mwr_en_i             : in  std_logic;
mwr_len_i            : in  std_logic_vector(31 downto 0);
mwr_lbe_i            : in  std_logic_vector(3 downto 0);
mwr_fbe_i            : in  std_logic_vector(3 downto 0);
mwr_addr_i           : in  std_logic_vector(31 downto 0);
mwr_count_i          : in  std_logic_vector(31 downto 0);
mwr_done_o           : out std_logic;
mwr_tlp_tc_i         : in  std_logic_vector(2 downto 0);
mwr_64b_en_i         : in  std_logic;
mwr_phant_func_en1_i : in  std_logic;
mwr_addr_up_i        : in  std_logic_vector(7 downto 0);
mwr_relaxed_order_i  : in  std_logic;
mwr_nosnoop_i        : in  std_logic;

mrd_en_i             : in  std_logic;
mrd_len_i            : in  std_logic_vector(31 downto 0);
mrd_lbe_i            : in  std_logic_vector(3 downto 0);
mrd_fbe_i            : in  std_logic_vector(3 downto 0);
mrd_addr_i           : in  std_logic_vector(31 downto 0);
mrd_count_i          : in  std_logic_vector(31 downto 0);
mrd_tlp_tc_i         : in  std_logic_vector(2 downto 0);
mrd_64b_en_i         : in  std_logic;
mrd_phant_func_en1_i : in  std_logic;
mrd_addr_up_i        : in  std_logic_vector(7 downto 0);
mrd_relaxed_order_i  : in  std_logic;
mrd_nosnoop_i        : in  std_logic;
mrd_pkt_len_o        : out std_logic_vector(31 downto 0);
mrd_pkt_count_o      : out std_logic_vector(15 downto 0);

completer_id_i       : in  std_logic_vector(15 downto 0);
tag_ext_en_i         : in  std_logic;
master_en_i          : in  std_logic;
max_payload_size_i   : in  std_logic_vector(2 downto 0);
max_rd_req_size_i    : in  std_logic_vector(2 downto 0);

--DBG
tst_o                : out std_logic_vector(31 downto 0);
tst_i                : in  std_logic_vector(31 downto 0);

clk                  : in  std_logic;
rst_n                : in  std_logic
);
end component;

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

signal i_usr_rxbuf_dout           : std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
signal i_usr_rxbuf_rd             : std_logic;
signal i_usr_rxbuf_rd_last        : std_logic;
signal i_usr_rxbuf_empty          : std_logic;

--signal i_usr_max_payload_size     : std_logic_vector(2 downto 0);
--signal i_usr_max_rd_req_size      : std_logic_vector(2 downto 0);

signal i_req_compl                : std_logic;
signal i_compl_done               : std_logic;

signal i_req_addr                 : std_logic_vector(29 downto 0);
signal i_req_pkt_type             : std_logic_vector(6 downto 0);
signal i_req_tc                   : std_logic_vector(2 downto 0);
signal i_req_td                   : std_logic;
signal i_req_ep                   : std_logic;
signal i_req_attr                 : std_logic_vector(1 downto 0);
signal i_req_len                  : std_logic_vector(9 downto 0);
signal i_req_rid                  : std_logic_vector(15 downto 0);
signal i_req_tag                  : std_logic_vector(7 downto 0);
signal i_req_be                   : std_logic_vector(7 downto 0);
signal i_req_exprom               : std_logic;

signal i_dmatrn_init              : std_logic;

signal i_mwr_en                   : std_logic;
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
signal i_mwr_lbe                  : std_logic_vector(3 downto 0);
signal i_mwr_fbe                  : std_logic_vector(3 downto 0);

signal i_mrd_en                   : std_logic;
signal i_mrd_addr                 : std_logic_vector(31 downto 0);
signal i_mrd_len                  : std_logic_vector(31 downto 0);
signal i_mrd_count                : std_logic_vector(31 downto 0);
signal i_mrd_tlp_tc               : std_logic_vector(2 downto 0);
signal i_mrd_64b_en               : std_logic;
signal i_mrd_phant_func_en1       : std_logic;
signal i_mrd_addr_up              : std_logic_vector(7 downto 0);
signal i_mrd_relaxed_order        : std_logic;
signal i_mrd_nosnoop              : std_logic;
signal i_mrd_lbe                  : std_logic_vector(3 downto 0);
signal i_mrd_fbe                  : std_logic_vector(3 downto 0);
signal i_mrd_rcv_size             : std_logic_vector(31 downto 0);
signal i_mrd_rcv_err              : std_logic;
signal i_mrd_en_throttle          : std_logic;
signal i_mrd_pkt_count            : std_logic_vector(15 downto 0);
signal i_mrd_pkt_len              : std_logic_vector(31 downto 0);

signal i_rd_metering              : std_logic;

signal i_irq_clr                  : std_logic;
signal i_irq_num                  : std_logic_vector(4 downto 0);
signal i_irq_set                  : std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
signal i_irq_status               : std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);

signal i_cfg_msi_enable           : std_logic;
signal i_cfg_completer_id         : std_logic_vector(15 downto 0);
signal i_cfg_neg_max_lnk_width    : std_logic_vector(5 downto 0);
signal i_cfg_rcb                  : std_logic;
signal i_cfg_prg_max_payload_size : std_logic_vector(2 downto 0);
signal i_cfg_prg_max_rd_req_size  : std_logic_vector(2 downto 0);
signal i_cfg_ext_tag_en           : std_logic;
signal i_cfg_phant_func_en        : std_logic;
--signal i_cfg_no_snoop_en          : std_logic;
signal i_cfg_bus_master_en        : std_logic;
signal i_cfg_intrrupt_disable     : std_logic;


--signal i_rx_engine_tst_out        : std_logic_vector(31 downto 0);
--signal i_rd_throttle_tst_out      : std_logic_vector(1 downto 0);
--signal tst_pcie_tx_out            : std_logic_vector(31 downto 0);
--signal tmp_cfg_msi_enable         : std_logic;


begin --architecture struct


----------------------------------------
--Input signal
----------------------------------------
trn_rnp_ok_n_o <= '0';
trn_rcpl_streaming_n_o <= '1';

cfg_pm_wake_n_o        <='1';
trn_terrfwd_n_o        <='1';
cfg_trn_pending_n_o    <='1';

cfg_err_locked_n_o     <='1';
cfg_err_ecrc_n_o       <='1';
cfg_err_ur_n_o         <='1';
cfg_err_cpl_timeout_n_o<='1';
cfg_err_cpl_unexpect_n_o<='1';
cfg_err_cor_n_o        <='1';
cfg_err_posted_n_o     <='1';
cfg_err_cpl_abort_n_o  <='1';--Configuration Error Completion Aborted: The
                             --user can assert this signal to report that a completion
                             --was aborted.
cfg_err_tlp_cpl_header_o <=(others => '0'); --Configuration Error TLP Completion Header:
                                          --Accepts the header information from the user when
                                          --an error is signaled. This information is required so
                                          --that the core can issue a correct completion, if
                                          --required.
                                          --The following information should be extracted from
                                          --the received error TLP and presented in the format
                                          --below:
                                          --[47:41]     Lower Address
                                          --[40:29]     Byte Count
                                          --[28:26]     TC
                                          --[25:24]     Attr
                                          --[23:8]      Requester ID
                                          --[7:0]       Tag

cfg_dsn_o <= std_logic_vector(TO_UNSIGNED(16#123#, cfg_dsn_o'length));


----------------------------------------
--
----------------------------------------
i_rst_n <= trn_reset_n_i and not trn_lnk_up_n_i;


i_cfg_completer_id <= cfg_bus_number_i & cfg_device_number_i & cfg_function_number_i;

--Link Status register in the PCI Express Capabilities Structure
i_cfg_neg_max_lnk_width <= cfg_lstatus_i(9 downto 4);--Negotiated Link Width

--Link Control register in the PCI Express Capabilities Structure
i_cfg_rcb <= cfg_lcommand_i(3);--Read Completion Boundary.(RCB) 0=64B or 1=128B

--Device Control register in the PCI Express Capabilities Structure
i_cfg_prg_max_payload_size <= cfg_dcommand_i(7 downto 5);
i_cfg_prg_max_rd_req_size <= cfg_dcommand_i(14 downto 12);
i_cfg_ext_tag_en    <= cfg_dcommand_i(8);
i_cfg_phant_func_en <= cfg_dcommand_i(9);
--i_cfg_no_snoop_en   <= cfg_dcommand_i(11);

--Command register in the PCI Configuration Space Header
i_cfg_bus_master_en <= cfg_command_i(2);
i_cfg_intrrupt_disable <= cfg_command_i(10);

i_cfg_msi_enable <= cfg_interrupt_msienable_i;


--###########################################
--Usr Application :
--###########################################
m_usr_app : pcie_usr_app
generic map(
G_DBG => G_DBG
)
port map(
p_out_hclk      => p_out_hclk,
p_out_gctrl     => p_out_gctrl,

--CTRL user devices
p_out_dev_ctrl  => p_out_dev_ctrl,
p_out_dev_din   => p_out_dev_din,
p_in_dev_dout   => p_in_dev_dout,
p_out_dev_wr    => p_out_dev_wr,
p_out_dev_rd    => p_out_dev_rd,
p_in_dev_status => p_in_dev_status,
p_in_dev_irq    => p_in_dev_irq,
p_in_dev_opt    => p_in_dev_opt,
p_out_dev_opt   => p_out_dev_opt,

--DBG
p_out_tst       => p_out_tst,
p_in_tst        => p_in_tst,

------------------------------
--PCIE_Rx/Tx  Port
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

p_out_mwr_en                  => i_mwr_en,
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
p_out_mwr_lbe                 => i_mwr_lbe,
p_out_mwr_fbe                 => i_mwr_fbe,

p_out_mrd_en                  => i_mrd_en,
p_out_mrd_addr_up             => i_mrd_addr_up,
p_out_mrd_addr                => i_mrd_addr,
p_out_mrd_len                 => i_mrd_len,
p_out_mrd_count               => i_mrd_count,
p_out_mrd_tlp_tc              => i_mrd_tlp_tc,
p_out_mrd_64b                 => i_mrd_64b_en,
p_out_mrd_phant_func_en1      => i_mrd_phant_func_en1,
p_out_mrd_relaxed_order       => i_mrd_relaxed_order,
p_out_mrd_nosnoop             => i_mrd_nosnoop,
p_out_mrd_lbe                 => i_mrd_lbe,
p_out_mrd_fbe                 => i_mrd_fbe,
p_in_mrd_rcv_size             => i_mrd_rcv_size,
p_in_mrd_rcv_err              => i_mrd_rcv_err,

p_out_irq_clr                 => i_irq_clr,
p_out_irq_num                 => i_irq_num,
p_out_irq_set                 => i_irq_set,
p_in_irq_status               => i_irq_status,

p_out_rd_metering             => i_rd_metering,
--p_out_usr_max_payload_size    => i_usr_max_payload_size,
--p_out_usr_max_rd_req_size     => i_usr_max_rd_req_size,

p_in_cfg_neg_max_lnk_width    => i_cfg_neg_max_lnk_width,
p_in_cfg_prg_max_payload_size => i_cfg_prg_max_payload_size,
p_in_cfg_prg_max_rd_req_size  => i_cfg_prg_max_rd_req_size,

p_in_rx_engine_tst            => "00",--tst_pcie_tx_out(1 downto 0),
p_in_rx_engine_tst2           => "0000000000",--i_rx_engine_tst_out(9 downto 0),
p_in_throttle_tst             => "00",--i_rd_throttle_tst_out,
p_in_mrd_pkt_len_tst          => i_mrd_pkt_len,

p_in_clk                      => trn_clk_i,
p_in_rst_n                    => i_rst_n
);


--###########################################
--CTRL core PCI-Express
--###########################################
m_rx : pcie_rx
port map(
--Target mode
usr_reg_adr_o       => i_usr_reg_adr,
usr_reg_din_o       => i_usr_reg_din,
usr_reg_wr_o        => i_usr_reg_wr,
usr_reg_rd_o        => i_usr_reg_rd,

--Master mode
usr_txbuf_din_o     => i_usr_txbuf_din,
usr_txbuf_wr_o      => i_usr_txbuf_wr,
usr_txbuf_wr_last_o => i_usr_txbuf_wr_last,
usr_txbuf_full_i    => i_usr_txbuf_full,
--usr_txbuf_dbe_o   => open,

--LocalLink Rx (core PCI-Express)
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
req_pkt_type_o      => i_req_pkt_type,
req_tc_o            => i_req_tc,
req_td_o            => i_req_td,
req_ep_o            => i_req_ep,
req_attr_o          => i_req_attr,
req_len_o           => i_req_len,
req_rid_o           => i_req_rid,
req_tag_o           => i_req_tag,
req_be_o            => i_req_be,
req_exprom_o        => i_req_exprom,

--Completion with Data
cpld_total_size_o   => i_mrd_rcv_size,
cpld_malformed_o    => i_mrd_rcv_err,

--Initiator reset
dma_init_i          => i_dmatrn_init,

--DBG
tst_o               => open,--i_rx_engine_tst_out,
tst_i               => (others => '0'),

clk                 => trn_clk_i,
rst_n               => i_rst_n
);


m_tx : pcie_tx
generic map(
G_USR_DBUS => C_HDEV_DWIDTH
)
port map(
--Target mode
usr_reg_dout_i       => i_usr_reg_dout,

--Master mode
usr_rxbuf_dout_i     => i_usr_rxbuf_dout,
usr_rxbuf_rd_o       => i_usr_rxbuf_rd,
usr_rxbuf_rd_last_o  => i_usr_rxbuf_rd_last,
usr_rxbuf_empty_i    => i_usr_rxbuf_empty,

--LocalLink Tx (core PCI-Express)
trn_td               => trn_td_o,              -- O [63/31:0]
trn_trem_n           => trn_trem_n_o,          -- O [7:0]
trn_tsof_n           => trn_tsof_n_o,          -- O
trn_teof_n           => trn_teof_n_o,          -- O
trn_tsrc_dsc_n       => trn_tsrc_dsc_n_o,      -- O
trn_tsrc_rdy_n_o     => trn_tsrc_rdy_n_o,      -- O
trn_tdst_dsc_n       => trn_tdst_dsc_n_i,      -- I
trn_tdst_rdy_n       => trn_tdst_rdy_n_i,      -- I
trn_tbuf_av          => trn_tbuf_av_i,         -- I [5:0]

--Handshake with Rx egine
req_compl_i          => i_req_compl,           -- I
compl_done_o         => i_compl_done,          -- 0

req_addr_i           => i_req_addr,            -- I [29:0]
req_pkt_type_i       => i_req_pkt_type,        --
req_tc_i             => i_req_tc,              -- I [2:0]
req_td_i             => i_req_td,              -- I
req_ep_i             => i_req_ep,              -- I
req_attr_i           => i_req_attr,            -- I [1:0]
req_len_i            => i_req_len,             -- I [9:0]
req_rid_i            => i_req_rid,             -- I [15:0]
req_tag_i            => i_req_tag,             -- I [7:0]
req_be_i             => i_req_be,              -- I [7:0]
req_exprom_i         => i_req_exprom,          -- I

--Initiator Controls
dma_init_i           => i_dmatrn_init,         -- I

--Write Initiator
mwr_en_i             => i_mwr_en,              -- I
mwr_done_o           => i_mwr_done,            -- O
mwr_addr_up_i        => i_mwr_addr_up,         -- I [7:0]
mwr_addr_i           => i_mwr_addr,            -- I [31:0]
mwr_len_i            => i_mwr_len,             -- I [31:0]
mwr_count_i          => i_mwr_count,           -- I [31:0]
mwr_tlp_tc_i         => i_mwr_tlp_tc,          -- I [2:0]
mwr_64b_en_i         => i_mwr_64b_en,          -- I
mwr_phant_func_en1_i => i_cfg_phant_func_en,   -- I --i_mwr_phant_func_en1,
mwr_lbe_i            => i_mwr_lbe,             -- I [3:0]
mwr_fbe_i            => i_mwr_fbe,             -- I [3:0]
mwr_relaxed_order_i  => i_mwr_relaxed_order,   -- I
mwr_nosnoop_i        => i_mwr_nosnoop,         -- I

--Read Initiator
mrd_en_i             => i_mrd_en_throttle,     -- I
mrd_addr_up_i        => i_mrd_addr_up,         -- I [7:0]
mrd_addr_i           => i_mrd_addr,            -- I [31:0]
mrd_len_i            => i_mrd_len,             -- I [31:0]
mrd_count_i          => i_mrd_count,           -- I [31:0]
mrd_tlp_tc_i         => i_mrd_tlp_tc,          -- I [2:0]
mrd_64b_en_i         => i_mrd_64b_en,          -- I
mrd_phant_func_en1_i => i_cfg_phant_func_en,   -- I --i_mrd_phant_func_en1,
mrd_lbe_i            => i_mrd_lbe,             -- I [3:0]
mrd_fbe_i            => i_mrd_fbe,             -- I [3:0]
mrd_relaxed_order_i  => i_mrd_relaxed_order,   -- I
mrd_nosnoop_i        => i_mrd_nosnoop,         -- I
mrd_pkt_len_o        => i_mrd_pkt_len,         -- O[31:0]
mrd_pkt_count_o      => i_mrd_pkt_count,       -- O[15:0]

completer_id_i       => i_cfg_completer_id,    -- I [15:0]
tag_ext_en_i         => i_cfg_ext_tag_en,      -- I
master_en_i          => i_cfg_bus_master_en,   -- I
max_payload_size_i   => i_cfg_prg_max_payload_size, -- I [2:0]  i_usr_max_payload_size,--
max_rd_req_size_i    => i_cfg_prg_max_rd_req_size,  -- I [2:0]  i_usr_max_rd_req_size, --

--DBG
tst_o                => open,--tst_pcie_tx_out,
tst_i                => (others => '0'),

clk                  => trn_clk_i,
rst_n                => i_rst_n
);


------------------------------------
--Read Transmit Throttle Unit :
------------------------------------
m_mrd_throttle : pcie_mrd_throttle
port map(
init_rst_i          => i_dmatrn_init,       -- I

mrd_work_i          => i_mrd_en,            -- I
mrd_len_i           => i_mrd_pkt_len,       -- I [31:0]
mrd_pkt_count_i     => i_mrd_pkt_count,     -- I [15:0]

cpld_data_size_i    => i_mrd_rcv_size,      -- I [31:0]
cpld_malformed_i    => i_mrd_rcv_err,       -- I
cpld_data_err_i     => '0',                 -- I

cfg_rd_comp_bound_i => i_cfg_rcb,           -- I
rd_metering_i       => i_rd_metering,       -- I

mrd_work_o          => i_mrd_en_throttle,   -- O

clk                 =>  trn_clk_i ,
rst_n               =>  i_rst_n
);


------------------------------------
--Interrupt Controller
------------------------------------
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

p_in_tst               => (others => '0'),
p_out_tst              => open,

p_in_clk               => trn_clk_i,
p_in_rst_n             => i_rst_n
);


------------------------------------
--Configuration Controller
------------------------------------
m_cfg : pcie_cfg
port map(
cfg_bus_master_en   => i_cfg_bus_master_en, -- I

cfg_do              => cfg_do_i,
cfg_di              => cfg_di_o,
cfg_dwaddr          => cfg_dwaddr_o,
cfg_byte_en_n       => cfg_byte_en_n_o,
cfg_wr_en_n         => cfg_wr_en_n_o,
cfg_rd_en_n         => cfg_rd_en_n_o,
cfg_rd_wr_done_n    => cfg_rd_wr_done_n_i,

cfg_cap_max_lnk_width    => open, -- O [5:0]
cfg_cap_max_payload_size => open, -- O [2:0]
cfg_msi_enable           => open, --tmp_cfg_msi_enable, -- O

rst_n               => i_rst_n,
clk                 => trn_clk_i
);


------------------------------------
--Turn-off Control Unit
------------------------------------
m_off_on : pcie_off_on
port map(
req_compl_i        => i_req_compl,       -- I
compl_done_i       => i_compl_done,      -- I

cfg_to_turnoff_n_i => cfg_to_turnoff_n_i,-- I
cfg_turnoff_ok_n_o => cfg_turnoff_ok_n_o,-- O

rst_n => i_rst_n,
clk   => trn_clk_i
);


end architecture struct;


