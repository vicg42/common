-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 29.08.2012 10:12:36
-- Module Name : pcie_main.vhd
--
-- Description : Связь между Контроллер Endpoint PCI-Express и ядром PCI-Express V6.
--               PCI-experss core AXI bus contert to TRN bus
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
use work.prj_def.all;
use work.prj_cfg.all;

entity pcie_main is
generic(
G_PCIE_LINK_WIDTH : integer:=8;
G_PCIE_RST_SEL    : integer:=1;
G_DBG : string :="OFF"  --В боевом проекте обязательно должно быть "OFF" - отладка с ChipScoupe
);
port(
--------------------------------------------------------
--USR Port
--------------------------------------------------------
p_out_hclk           : out   std_logic;
p_out_gctrl          : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--Управление внешними устройствами
p_out_dev_ctrl       : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din        : out   std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_in_dev_dout        : in    std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_out_dev_wr         : out   std_logic;
p_out_dev_rd         : out   std_logic;
p_in_dev_status      : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq         : in    std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
p_in_dev_opt         : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
p_out_dev_opt        : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

p_out_usr_tst        : out   std_logic_vector(127 downto 0);
p_in_usr_tst         : in    std_logic_vector(127 downto 0);

--------------------------------------------------------
--Технологический
--------------------------------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(255 downto 0);

---------------------------------------------------------
--System Port
---------------------------------------------------------
p_in_fast_simulation : in    std_logic;

p_out_pciexp_txp     : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_out_pciexp_txn     : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxp      : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxn      : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);

p_in_pciexp_rst      : in    std_logic;

p_out_module_rdy     : out   std_logic;
p_in_gtp_refclkin    : in    std_logic;
p_out_gtp_refclkout  : out   std_logic
);
end pcie_main;

architecture behavioral of pcie_main is

constant CI_PCIEXP_TRN_DBUS       : integer:= 128;--64;--
constant CI_PCIEXP_TRN_REMBUS_NEW : integer:= 2  ;--1 ;--
constant CI_PCIEXP_TRN_BUFAV_BUS  : integer:= 6  ;
constant CI_PCIEXP_BARHIT_BUS     : integer:= 7  ;
constant CI_PCIEXP_FC_HDR_BUS     : integer:= 8  ;
constant CI_PCIEXP_FCDAT_BUS      : integer:= 12 ;
constant CI_PCIEXP_CFG_DBUS       : integer:= 32 ;
constant CI_PCIEXP_CFG_ABUS       : integer:= 10 ;
constant CI_PCIEXP_CFG_CPLHDR_BUS : integer:= 48 ;
constant CI_PCIEXP_CFG_BUSNUM_BUS : integer:= 8  ;
constant CI_PCIEXP_CFG_DEVNUM_BUS : integer:= 5  ;
constant CI_PCIEXP_CFG_FUNNUM_BUS : integer:= 3  ;
constant CI_PCIEXP_CFG_CAP_BUS    : integer:= 16 ;

signal in_pkt_reg : std_logic;
signal is_sof     : std_logic_vector(4 downto 0);
signal is_eof     : std_logic_vector(4 downto 0);

component core_pciexp_ep_blk_plus_axi
generic(
PL_FAST_TRAIN  : boolean;
BAR0           : bit_vector := X"FFFFFF00";
BAR1           : bit_vector := X"FFFFFF01"
);
port(
---------------------------------------------------------
-- 1. PCI Express (pci_exp) Interface
---------------------------------------------------------

-- Tx
pci_exp_txp                               : out std_logic_vector((G_PCIE_LINK_WIDTH - 1) downto 0);
pci_exp_txn                               : out std_logic_vector((G_PCIE_LINK_WIDTH - 1) downto 0);

-- Rx
pci_exp_rxp                               : in std_logic_vector((G_PCIE_LINK_WIDTH - 1) downto 0);
pci_exp_rxn                               : in std_logic_vector((G_PCIE_LINK_WIDTH - 1) downto 0);

---------------------------------------------------------
-- 2. Transaction (TRN) Interface
---------------------------------------------------------

-- Common
user_clk_out                              : out std_logic;
user_reset_out                            : out std_logic;
user_lnk_up                               : out std_logic;

-- Tx
tx_buf_av                                 : out std_logic_vector(5 downto 0);
tx_err_drop                               : out std_logic;
--tx_cfg_req                                : out std_logic;
s_axis_tx_tready                          : out std_logic;
s_axis_tx_tdata                           : in std_logic_vector(CI_PCIEXP_TRN_DBUS-1 downto 0);
s_axis_tx_tkeep                           : in std_logic_vector(CI_PCIEXP_TRN_DBUS/8 -1 downto 0);
s_axis_tx_tuser                           : in std_logic_vector(3 downto 0);
s_axis_tx_tlast                           : in std_logic;
s_axis_tx_tvalid                          : in std_logic;

--tx_cfg_gnt                                : in std_logic;

-- Rx
m_axis_rx_tdata                           : out std_logic_vector(CI_PCIEXP_TRN_DBUS-1 downto 0);
m_axis_rx_tkeep                           : out std_logic_vector(CI_PCIEXP_TRN_DBUS/8 -1 downto 0);
m_axis_rx_tlast                           : out std_logic;
m_axis_rx_tvalid                          : out std_logic;
m_axis_rx_tuser                           : out std_logic_vector(21 downto 0);
m_axis_rx_tready                          : in std_logic;
rx_np_ok                                  : in std_logic;

-- Flow Control
fc_cpld                                   : out std_logic_vector(11 downto 0);
fc_cplh                                   : out std_logic_vector(7 downto 0);
fc_npd                                    : out std_logic_vector(11 downto 0);
fc_nph                                    : out std_logic_vector(7 downto 0);
fc_pd                                     : out std_logic_vector(11 downto 0);
fc_ph                                     : out std_logic_vector(7 downto 0);
fc_sel                                    : in std_logic_vector(2 downto 0);

---------------------------------------------------------
-- 3. Configuration (CFG) Interface
---------------------------------------------------------

cfg_do                                    : out std_logic_vector(31 downto 0);
cfg_rd_wr_done                            : out std_logic;
cfg_di                                    : in std_logic_vector(31 downto 0);
cfg_byte_en                               : in std_logic_vector(3 downto 0);
cfg_dwaddr                                : in std_logic_vector(9 downto 0);
cfg_wr_en                                 : in std_logic;
cfg_rd_en                                 : in std_logic;

cfg_err_cor                               : in std_logic;
cfg_err_ur                                : in std_logic;
cfg_err_ecrc                              : in std_logic;
cfg_err_cpl_timeout                       : in std_logic;
cfg_err_cpl_abort                         : in std_logic;
cfg_err_cpl_unexpect                      : in std_logic;
cfg_err_posted                            : in std_logic;
cfg_err_locked                            : in std_logic;
cfg_err_tlp_cpl_header                    : in std_logic_vector(47 downto 0);
cfg_err_cpl_rdy                           : out std_logic;
cfg_interrupt                             : in std_logic;
cfg_interrupt_rdy                         : out std_logic;
cfg_interrupt_assert                      : in std_logic;
cfg_interrupt_di                          : in std_logic_vector(7 downto 0);
cfg_interrupt_do                          : out std_logic_vector(7 downto 0);
cfg_interrupt_mmenable                    : out std_logic_vector(2 downto 0);
cfg_interrupt_msienable                   : out std_logic;
cfg_interrupt_msixenable                  : out std_logic;
cfg_interrupt_msixfm                      : out std_logic;
cfg_turnoff_ok                            : in std_logic;
cfg_to_turnoff                            : out std_logic;
cfg_trn_pending                           : in std_logic;
cfg_pm_wake                               : in std_logic;
cfg_bus_number                            : out std_logic_vector(7 downto 0);
cfg_device_number                         : out std_logic_vector(4 downto 0);
cfg_function_number                       : out std_logic_vector(2 downto 0);
cfg_status                                : out std_logic_vector(15 downto 0);
cfg_command                               : out std_logic_vector(15 downto 0);
cfg_dstatus                               : out std_logic_vector(15 downto 0);
cfg_dcommand                              : out std_logic_vector(15 downto 0);
cfg_lstatus                               : out std_logic_vector(15 downto 0);
cfg_lcommand                              : out std_logic_vector(15 downto 0);
cfg_dcommand2                             : out std_logic_vector(15 downto 0);
cfg_pcie_link_state                       : out std_logic_vector(2 downto 0);
cfg_dsn                                   : in std_logic_vector(63 downto 0);
cfg_pmcsr_pme_en                          : out std_logic;
cfg_pmcsr_pme_status                      : out std_logic;
cfg_pmcsr_powerstate                      : out std_logic_vector(1 downto 0);

---------------------------------------------------------
-- 4. Physical Layer Control and Status (PL) Interface
---------------------------------------------------------

pl_initial_link_width                     : out std_logic_vector(2 downto 0);
pl_lane_reversal_mode                     : out std_logic_vector(1 downto 0);
pl_link_gen2_capable                      : out std_logic;
pl_link_partner_gen2_supported            : out std_logic;
pl_link_upcfg_capable                     : out std_logic;
pl_ltssm_state                            : out std_logic_vector(5 downto 0);
pl_received_hot_rst                       : out std_logic;
pl_sel_link_rate                          : out std_logic;
pl_sel_link_width                         : out std_logic_vector(1 downto 0);
pl_directed_link_auton                    : in std_logic;
pl_directed_link_change                   : in std_logic_vector(1 downto 0);
pl_directed_link_speed                    : in std_logic;
pl_directed_link_width                    : in std_logic_vector(1 downto 0);
pl_upstream_prefer_deemph                 : in std_logic;

---------------------------------------------------------
-- 5. System  (SYS) Interface
---------------------------------------------------------

sys_clk                                   : in std_logic;
sys_reset                                 : in std_logic
);
end component;

component pcie_ctrl
generic(
G_PCIEXP_TRN_DBUS : integer:=64;
G_DBG : string :="OFF"
);
port(
--------------------------------------
--USR Port
--------------------------------------
p_out_hclk                : out   std_logic;
p_out_gctrl               : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--Управление внешними устройствами
p_out_dev_ctrl            : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din             : out   std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_in_dev_dout             : in    std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_out_dev_wr              : out   std_logic;
p_out_dev_rd              : out   std_logic;
p_in_dev_status           : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq              : in    std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
p_in_dev_opt              : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
p_out_dev_opt             : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

p_out_tst                 : out   std_logic_vector(127 downto 0);
p_in_tst                  : in    std_logic_vector(127 downto 0);

--------------------------------------
--Tx
--------------------------------------
trn_td_o                  : out   std_logic_vector(G_PCIEXP_TRN_DBUS-1 downto 0)  ;
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
trn_rd_i                  : in    std_logic_vector(G_PCIEXP_TRN_DBUS-1 downto 0)  ;
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
end component;

component pcie_reset
port(
pciexp_refclk_i : in    std_logic;
trn_lnk_up_n_i  : in    std_logic;
sys_reset_n_o   : out   std_logic;
module_rdy_o    : out   std_logic
);
end component;

signal from_ctrl_rst_n                : std_logic;

signal refclkout                      : std_logic;

signal sys_reset,sys_reset_n                       : std_logic;
signal trn_clk                        : std_logic;-- //synthesis attribute max_fanout of trn_clk is "100000"
signal trn_reset,trn_reset_n                       : std_logic;
signal trn_lnk_up,trn_lnk_up_n                     : std_logic;

signal s_axis_tx_tready               : std_logic;
signal s_axis_tx_tdata                : std_logic_vector(CI_PCIEXP_TRN_DBUS-1 downto 0);
signal s_axis_tx_tkeep                : std_logic_vector(CI_PCIEXP_TRN_DBUS/8 -1 downto 0);
signal s_axis_tx_tuser                : std_logic_vector(3 downto 0);
signal s_axis_tx_tlast                : std_logic;
signal s_axis_tx_tvalid               : std_logic;

signal m_axis_rx_tdata                : std_logic_vector(CI_PCIEXP_TRN_DBUS-1 downto 0);
signal m_axis_rx_tkeep                : std_logic_vector(CI_PCIEXP_TRN_DBUS/8 -1 downto 0);
signal m_axis_rx_tlast                : std_logic;
signal m_axis_rx_tvalid               : std_logic;
signal m_axis_rx_tuser                : std_logic_vector(21 downto 0);
signal m_axis_rx_tready               : std_logic;

signal trn_tsof_n                     : std_logic;
signal trn_teof_n                     : std_logic;
signal trn_tsrc_rdy_n                 : std_logic;
signal trn_tdst_rdy_n                 : std_logic;
signal trn_tsrc_dsc_n                 : std_logic;
signal trn_terrfwd_n                  : std_logic;
--signal trn_tdst_dsc_n                 : std_logic;--in rev 1.7. dont
signal trn_td                         : std_logic_vector(CI_PCIEXP_TRN_DBUS-1 downto 0);
signal trn_trem_n_core                : std_logic_vector(CI_PCIEXP_TRN_REMBUS_NEW-1 downto 0);
signal trn_trem_n                     : std_logic_vector(3 downto 0);
signal trn_tbuf_av                    : std_logic_vector(CI_PCIEXP_TRN_BUFAV_BUS-1 downto 0);

signal trn_rsof_n                     : std_logic;
signal trn_reof_n                     : std_logic;
signal trn_rsrc_rdy_n                 : std_logic;
signal trn_rsrc_dsc_n                 : std_logic;
signal trn_rdst_rdy_n                 : std_logic;
signal trn_rerrfwd_n                  : std_logic;
signal trn_rnp_ok,trn_rnp_ok_n                   : std_logic;
signal trn_rd                         : std_logic_vector(CI_PCIEXP_TRN_DBUS-1 downto 0);
signal trn_rrem_n_core                : std_logic_vector(CI_PCIEXP_TRN_REMBUS_NEW-1 downto 0);
signal trn_rrem_n                     : std_logic_vector(3 downto 0);
signal trn_rbar_hit_n                 : std_logic_vector(CI_PCIEXP_BARHIT_BUS-1 downto 0);
--signal trn_rfc_nph_av                 : std_logic_vector(CI_PCIEXP_FC_HDR_BUS-1 downto 0);
--signal trn_rfc_npd_av                 : std_logic_vector(CI_PCIEXP_FCDAT_BUS-1 downto 0);
--signal trn_rfc_ph_av                  : std_logic_vector(CI_PCIEXP_FC_HDR_BUS-1 downto 0);
--signal trn_rfc_pd_av                  : std_logic_vector(CI_PCIEXP_FCDAT_BUS-1 downto 0);
signal trn_rcpl_streaming_n           : std_logic;

signal cfg_do                         : std_logic_vector(CI_PCIEXP_CFG_DBUS-1 downto 0);
signal cfg_di                         : std_logic_vector(CI_PCIEXP_CFG_DBUS-1 downto 0);
signal cfg_dwaddr                     : std_logic_vector(CI_PCIEXP_CFG_ABUS-1 downto 0);
signal cfg_byte_en,cfg_byte_en_n                   : std_logic_vector(CI_PCIEXP_CFG_DBUS/8-1 downto 0);
signal cfg_wr_en,cfg_wr_en_n                       : std_logic;
signal cfg_rd_en,cfg_rd_en_n                       : std_logic;
signal cfg_rd_wr_done,cfg_rd_wr_done_n             : std_logic;

signal cfg_err_tlp_cpl_header                      : std_logic_vector(CI_PCIEXP_CFG_CPLHDR_BUS-1 downto 0);--47 downto 0);
signal cfg_err_cor,cfg_err_cor_n                   : std_logic;
signal cfg_err_ur,cfg_err_ur_n                     : std_logic;
signal cfg_err_cpl_rdy,cfg_err_cpl_rdy_n           : std_logic;
signal cfg_err_ecrc,cfg_err_ecrc_n                 : std_logic;
signal cfg_err_cpl_timeout,cfg_err_cpl_timeout_n   : std_logic;
signal cfg_err_cpl_abort,cfg_err_cpl_abort_n       : std_logic;
signal cfg_err_cpl_unexpect,cfg_err_cpl_unexpect_n : std_logic;
signal cfg_err_posted,cfg_err_posted_n             : std_logic;
signal cfg_err_locked,cfg_err_locked_n             : std_logic;

signal cfg_interrupt,cfg_interrupt_n               : std_logic;
signal cfg_interrupt_rdy,cfg_interrupt_rdy_n       : std_logic;
signal cfg_interrupt_assert,cfg_interrupt_assert_n : std_logic;
signal cfg_interrupt_di               : std_logic_vector(7 downto 0);
signal cfg_interrupt_do               : std_logic_vector(7 downto 0);
signal cfg_interrupt_mmenable         : std_logic_vector(2 downto 0);
signal cfg_interrupt_msienable        : std_logic;

signal cfg_turnoff_ok,cfg_turnoff_ok_n             : std_logic;
signal cfg_to_turnoff,cfg_to_turnoff_n             : std_logic;
signal cfg_pm_wake,cfg_pm_wake_n                   : std_logic;
signal cfg_trn_pending,cfg_trn_pending_n           : std_logic;
signal cfg_dsn                        : std_logic_vector(63 downto 0);

signal cfg_pcie_link_state,cfg_pcie_link_state_n   : std_logic_vector(2 downto 0);
signal cfg_bus_number                 : std_logic_vector(CI_PCIEXP_CFG_BUSNUM_BUS-1 downto 0);
signal cfg_device_number              : std_logic_vector(CI_PCIEXP_CFG_DEVNUM_BUS-1 downto 0);
signal cfg_function_number            : std_logic_vector(CI_PCIEXP_CFG_FUNNUM_BUS-1 downto 0);
signal cfg_status                     : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS-1 downto 0);
signal cfg_command                    : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS-1 downto 0);
signal cfg_dstatus                    : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS-1 downto 0);
signal cfg_dcommand                   : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS-1 downto 0);
signal cfg_lstatus                    : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS-1 downto 0);
signal cfg_lcommand                   : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS-1 downto 0);

signal user_trn_tbuf_av               : std_logic_vector(5 downto 0);--(15 downto 0);

--New Signal
signal trn_tcfg_req,trn_tcfg_req_n                 : std_logic;
signal trn_terr_drop,trn_terr_drop_n               : std_logic;

signal trn_tcfg_gnt,trn_tcfg_gnt_n                 : std_logic;
signal trn_tstr_n                     : std_logic;

signal trn_fc_cpld                    : std_logic_vector(11 downto 0);
signal trn_fc_cplh                    : std_logic_vector(7 downto 0);
signal trn_fc_npd                     : std_logic_vector(11 downto 0);
signal trn_fc_nph                     : std_logic_vector(7 downto 0);
signal trn_fc_pd                      : std_logic_vector(11 downto 0);
signal trn_fc_ph                      : std_logic_vector(7 downto 0);
signal trn_fc_sel                     : std_logic_vector(2 downto 0);

signal cfg_interrupt_msixenable       : std_logic;
signal cfg_interrupt_msixfm           : std_logic;

signal cfg_dcommand2                  : std_logic_vector(15 downto 0);

signal cfg_pmcsr_pme_en               : std_logic;
signal cfg_pmcsr_pme_status           : std_logic;
signal cfg_pmcsr_powerstate           : std_logic_vector(1 downto 0);
signal pl_initial_link_width          : std_logic_vector(2 downto 0);
signal pl_lane_reversal_mode          : std_logic_vector(1 downto 0);
signal pl_link_gen2_capable           : std_logic;
signal pl_link_partner_gen2_supported : std_logic;
signal pl_link_upcfg_capable          : std_logic;
signal pl_ltssm_state                 : std_logic_vector(5 downto 0);
signal pl_received_hot_rst            : std_logic;
signal pl_sel_link_rate               : std_logic;
signal pl_sel_link_width              : std_logic_vector(1 downto 0);
signal pl_directed_link_auton         : std_logic;
signal pl_directed_link_change        : std_logic_vector(1 downto 0);
signal pl_directed_link_speed         : std_logic;
signal pl_directed_link_width         : std_logic_vector(1 downto 0);
signal pl_upstream_prefer_deemph      : std_logic;


--MAIN
begin


--#############################################
--DBG
--#############################################
p_out_tst(0)<=cfg_interrupt_n;
p_out_tst(1)<=cfg_interrupt_rdy_n;
p_out_tst(2)<=cfg_interrupt_assert_n;
p_out_tst(3)<=cfg_interrupt_msienable;--cfg_command(10);
p_out_tst(4)<=trn_tsof_n;
p_out_tst(5)<=trn_teof_n;
p_out_tst(6)<=trn_tsrc_rdy_n;
p_out_tst(7)<=trn_tdst_rdy_n;
p_out_tst(8)<=trn_tsrc_dsc_n;
p_out_tst(9)<=trn_rsof_n;
p_out_tst(10)<=trn_reof_n;
p_out_tst(11)<=trn_rsrc_rdy_n;
p_out_tst(12)<=trn_rsrc_dsc_n;
p_out_tst(13)<=trn_rdst_rdy_n;
p_out_tst(14)<=trn_rbar_hit_n(0);
p_out_tst(15)<=trn_rbar_hit_n(1);
p_out_tst(16)<=cfg_command(2);--cfg_bus_mstr_enable
p_out_tst(18 downto 17)<=EXT(trn_rrem_n, 18-17+1);
p_out_tst(146 downto 19)<=trn_rd(63 downto 0) & trn_rd(127 downto 64);
--p_out_tst(146 downto 19)<=trn_rd(127 downto 0);
p_out_tst(162 downto 147)<=EXT(trn_rrem_n, 162-147+1);--(others=>'0');
p_out_tst(168 downto 163)<=trn_tbuf_av;
p_out_tst(170 downto 169)<=EXT(trn_trem_n_core, 170-169+1);
p_out_tst(171)<=s_axis_tx_tready;
p_out_tst(172)<=s_axis_tx_tlast ;
p_out_tst(173)<=s_axis_tx_tvalid;
p_out_tst(181 downto 174)<=s_axis_tx_tkeep(7 downto 0);
p_out_tst(185 downto 182)<=s_axis_tx_tuser(3 downto 0);
p_out_tst(186)<=m_axis_rx_tready;
p_out_tst(187)<=m_axis_rx_tvalid;
p_out_tst(188)<=m_axis_rx_tlast;
p_out_tst(196 downto 189)<=m_axis_rx_tkeep(7 downto 0);
p_out_tst(200 downto 197)<=m_axis_rx_tuser(3 downto 0);
p_out_tst(215 downto 201)<=(others=>'0');
p_out_tst(231 downto 216)<=(others=>'0');
p_out_tst(249 downto 248)<=(others=>'0');
p_out_tst(255 downto 250)<=(others=>'0');


--#############################################
--Модуль ядра PCI-Express
--#############################################
m_core : core_pciexp_ep_blk_plus_axi
generic map(
PL_FAST_TRAIN => FALSE,
BAR0          => X"FFFFFF00", --Memory: Size 256 byte, --bit_vector
BAR1          => X"FFFFFF01"  --IO    : Size 256 byte, --bit_vector
)
port map(
--------------------------------------
--PCI Express Fabric Interface
--------------------------------------
pci_exp_txp             => p_out_pciexp_txp,
pci_exp_txn             => p_out_pciexp_txn,
pci_exp_rxp             => p_in_pciexp_rxp,
pci_exp_rxn             => p_in_pciexp_rxn,

--------------------------------------
--Tx
--------------------------------------
s_axis_tx_tready        => s_axis_tx_tready   ,--: out std_logic;
s_axis_tx_tdata         => s_axis_tx_tdata    ,--: in std_logic_vector(CI_PCIEXP_TRN_DBUS-1 downto 0);
s_axis_tx_tkeep         => s_axis_tx_tkeep    ,--: in std_logic_vector(7 downto 0);
s_axis_tx_tuser         => s_axis_tx_tuser    ,--: in std_logic_vector(3 downto 0);
s_axis_tx_tlast         => s_axis_tx_tlast    ,--: in std_logic;
s_axis_tx_tvalid        => s_axis_tx_tvalid   ,--: in std_logic;

--------------------------------------
--Rx
--------------------------------------
m_axis_rx_tdata         => m_axis_rx_tdata    ,--: out std_logic_vector(CI_PCIEXP_TRN_DBUS-1 downto 0);
m_axis_rx_tkeep         => m_axis_rx_tkeep    ,--: out std_logic_vector(7 downto 0);
m_axis_rx_tlast         => m_axis_rx_tlast    ,--: out std_logic;
m_axis_rx_tvalid        => m_axis_rx_tvalid   ,--: out std_logic;
m_axis_rx_tuser         => m_axis_rx_tuser    ,--: out std_logic_vector(21 downto 0);
m_axis_rx_tready        => m_axis_rx_tready   ,--: in std_logic;

--------------------------------------
--System Port
--------------------------------------
user_clk_out                   => trn_clk                       ,--: out std_logic;
user_reset_out                 => trn_reset                     ,--: out std_logic;
user_lnk_up                    => trn_lnk_up                    ,--: out std_logic;
                                                                 --
sys_clk                        => p_in_gtp_refclkin             ,--: in std_logic;
sys_reset                      => sys_reset                     ,--: in std_logic;

--------------------------------------
--CFG Interface
--------------------------------------
cfg_do                         => cfg_do                        ,--: out std_logic_vector(31 downto 0);
cfg_rd_wr_done                 => cfg_rd_wr_done                ,--: out std_logic;
cfg_di                         => cfg_di                        ,--: in std_logic_vector(31 downto 0);
cfg_byte_en                    => cfg_byte_en                   ,--: in std_logic_vector(3 downto 0);
cfg_dwaddr                     => cfg_dwaddr                    ,--: in std_logic_vector(9 downto 0);
cfg_wr_en                      => cfg_wr_en                     ,--: in std_logic;
cfg_rd_en                      => cfg_rd_en                     ,--: in std_logic;

cfg_err_cor                    => cfg_err_cor                   ,--: in std_logic;
cfg_err_ur                     => cfg_err_ur                    ,--: in std_logic;
cfg_err_ecrc                   => cfg_err_ecrc                  ,--: in std_logic;
cfg_err_cpl_timeout            => cfg_err_cpl_timeout           ,--: in std_logic;
cfg_err_cpl_abort              => cfg_err_cpl_abort             ,--: in std_logic;
cfg_err_cpl_unexpect           => cfg_err_cpl_unexpect          ,--: in std_logic;
cfg_err_posted                 => cfg_err_posted                ,--: in std_logic;
cfg_err_locked                 => cfg_err_locked                ,--: in std_logic;
cfg_err_tlp_cpl_header         => cfg_err_tlp_cpl_header        ,--: in std_logic_vector(47 downto 0);
cfg_err_cpl_rdy                => cfg_err_cpl_rdy               ,--: out std_logic;
cfg_interrupt                  => cfg_interrupt                 ,--: in std_logic;
cfg_interrupt_rdy              => cfg_interrupt_rdy             ,--: out std_logic;
cfg_interrupt_assert           => cfg_interrupt_assert          ,--: in std_logic;
cfg_interrupt_di               => cfg_interrupt_di              ,--: in std_logic_vector(7 downto 0);
cfg_interrupt_do               => cfg_interrupt_do              ,--: out std_logic_vector(7 downto 0);
cfg_interrupt_mmenable         => cfg_interrupt_mmenable        ,--: out std_logic_vector(2 downto 0);
cfg_interrupt_msienable        => cfg_interrupt_msienable       ,--: out std_logic;
cfg_interrupt_msixenable       => cfg_interrupt_msixenable      ,--: out std_logic;
cfg_interrupt_msixfm           => cfg_interrupt_msixfm          ,--: out std_logic;
cfg_turnoff_ok                 => cfg_turnoff_ok                ,--: in std_logic;
cfg_to_turnoff                 => cfg_to_turnoff                ,--: out std_logic;
cfg_trn_pending                => cfg_trn_pending               ,--: in std_logic;
cfg_pm_wake                    => cfg_pm_wake                   ,--: in std_logic;
cfg_bus_number                 => cfg_bus_number                ,--: out std_logic_vector(7 downto 0);
cfg_device_number              => cfg_device_number             ,--: out std_logic_vector(4 downto 0);
cfg_function_number            => cfg_function_number           ,--: out std_logic_vector(2 downto 0);
cfg_status                     => cfg_status                    ,--: out std_logic_vector(15 downto 0);
cfg_command                    => cfg_command                   ,--: out std_logic_vector(15 downto 0);
cfg_dstatus                    => cfg_dstatus                   ,--: out std_logic_vector(15 downto 0);
cfg_dcommand                   => cfg_dcommand                  ,--: out std_logic_vector(15 downto 0);
cfg_lstatus                    => cfg_lstatus                   ,--: out std_logic_vector(15 downto 0);
cfg_lcommand                   => cfg_lcommand                  ,--: out std_logic_vector(15 downto 0);
cfg_dcommand2                  => cfg_dcommand2                 ,--: out std_logic_vector(15 downto 0);
cfg_pcie_link_state            => cfg_pcie_link_state           ,--: out std_logic_vector(2 downto 0);
cfg_dsn                        => cfg_dsn                       ,--: in std_logic_vector(63 downto 0);
cfg_pmcsr_pme_en               => cfg_pmcsr_pme_en              ,--: out std_logic;
cfg_pmcsr_pme_status           => cfg_pmcsr_pme_status          ,--: out std_logic;
cfg_pmcsr_powerstate           => cfg_pmcsr_powerstate          ,--: out std_logic_vector(1 downto 0);

--------------------------------------
--New Signal
--------------------------------------
pl_initial_link_width          => pl_initial_link_width         ,--: out std_logic_vector(2 downto 0);
pl_lane_reversal_mode          => pl_lane_reversal_mode         ,--: out std_logic_vector(1 downto 0);
pl_link_gen2_capable           => pl_link_gen2_capable          ,--: out std_logic;
pl_link_partner_gen2_supported => pl_link_partner_gen2_supported,--: out std_logic;
pl_link_upcfg_capable          => pl_link_upcfg_capable         ,--: out std_logic;
pl_ltssm_state                 => pl_ltssm_state                ,--: out std_logic_vector(5 downto 0);
pl_received_hot_rst            => pl_received_hot_rst           ,--: out std_logic;
pl_sel_link_rate               => pl_sel_link_rate              ,--: out std_logic;
pl_sel_link_width              => pl_sel_link_width             ,--: out std_logic_vector(1 downto 0);
pl_directed_link_auton         => pl_directed_link_auton        ,--: in std_logic;
pl_directed_link_change        => pl_directed_link_change       ,--: in std_logic_vector(1 downto 0);
pl_directed_link_speed         => pl_directed_link_speed        ,--: in std_logic;
pl_directed_link_width         => pl_directed_link_width        ,--: in std_logic_vector(1 downto 0);
pl_upstream_prefer_deemph      => pl_upstream_prefer_deemph     ,--: in std_logic;

-- Flow Control
fc_cpld                        => trn_fc_cpld                   ,--: out std_logic_vector(11 downto 0);
fc_cplh                        => trn_fc_cplh                   ,--: out std_logic_vector(7 downto 0);
fc_npd                         => trn_fc_npd                    ,--: out std_logic_vector(11 downto 0);
fc_nph                         => trn_fc_nph                    ,--: out std_logic_vector(7 downto 0);
fc_pd                          => trn_fc_pd                     ,--: out std_logic_vector(11 downto 0);
fc_ph                          => trn_fc_ph                     ,--: out std_logic_vector(7 downto 0);
fc_sel                         => trn_fc_sel                    ,--: in std_logic_vector(2 downto 0);

tx_buf_av                      => trn_tbuf_av                   ,--: out std_logic_vector(5 downto 0);
tx_err_drop                    => trn_terr_drop                 ,--: out std_logic;
--tx_cfg_req                     => trn_tcfg_req                  ,--: out std_logic;
--tx_cfg_gnt                     => trn_tcfg_gnt                  ,--: in std_logic;
rx_np_ok                       => trn_rnp_ok                     --: in std_logic
);


--#############################################
--Модуль приложения PCI-Express(упраление ядром PCI-Express+ упр. пользовательским портом)
--#############################################
m_ctrl : pcie_ctrl
generic map(
G_PCIEXP_TRN_DBUS => CI_PCIEXP_TRN_DBUS,
G_DBG => G_DBG
)
port map(
--------------------------------------
--USR port
--------------------------------------
p_out_hclk                => p_out_hclk,
p_out_gctrl               => p_out_gctrl,

--Управление внешними устройствами
p_out_dev_ctrl            => p_out_dev_ctrl,
p_out_dev_din             => p_out_dev_din,
p_in_dev_dout             => p_in_dev_dout,
p_out_dev_wr              => p_out_dev_wr,
p_out_dev_rd              => p_out_dev_rd,
p_in_dev_status           => p_in_dev_status,
p_in_dev_irq              => p_in_dev_irq,
p_in_dev_opt              => p_in_dev_opt,
p_out_dev_opt             => p_out_dev_opt,

p_out_tst                 => p_out_usr_tst,
p_in_tst                  => p_in_usr_tst,

--------------------------------------
--Tx
--------------------------------------
trn_td_o                  => trn_td,
trn_trem_n_o              => trn_trem_n,
trn_tsof_n_o              => trn_tsof_n,
trn_teof_n_o              => trn_teof_n,
trn_tsrc_rdy_n_o          => trn_tsrc_rdy_n,
trn_tdst_rdy_n_i          => trn_tdst_rdy_n,
trn_tsrc_dsc_n_o          => trn_tsrc_dsc_n,
trn_tdst_dsc_n_i          => '1',--trn_tdst_dsc_n,
trn_terrfwd_n_o           => trn_terrfwd_n,
trn_tbuf_av_i             => user_trn_tbuf_av,

--------------------------------------
--Rx
--------------------------------------
trn_rd_i                  => trn_rd,
trn_rrem_n_i              => trn_rrem_n,
trn_rsof_n_i              => trn_rsof_n,
trn_reof_n_i              => trn_reof_n,
trn_rsrc_rdy_n_i          => trn_rsrc_rdy_n,
trn_rsrc_dsc_n_i          => trn_rsrc_dsc_n,
trn_rdst_rdy_n_o          => trn_rdst_rdy_n,
trn_rerrfwd_n_i           => trn_rerrfwd_n,
trn_rnp_ok_n_o            => trn_rnp_ok_n,

trn_rbar_hit_n_i          => trn_rbar_hit_n,
trn_rfc_nph_av_i          => (others=>'0'),--trn_rfc_nph_av,
trn_rfc_npd_av_i          => (others=>'0'),--trn_rfc_npd_av,
trn_rfc_ph_av_i           => (others=>'0'),--trn_rfc_ph_av,
trn_rfc_pd_av_i           => (others=>'0'),--trn_rfc_pd_av,
trn_rcpl_streaming_n_o    => trn_rcpl_streaming_n,

--------------------------------------
--CFG Interface
--------------------------------------
cfg_turnoff_ok_n_o        => cfg_turnoff_ok_n,
cfg_to_turnoff_n_i        => cfg_to_turnoff_n,

cfg_interrupt_n_o         => cfg_interrupt_n,
cfg_interrupt_rdy_n_i     => cfg_interrupt_rdy_n,
cfg_interrupt_assert_n_o  => cfg_interrupt_assert_n,
cfg_interrupt_di_o        => cfg_interrupt_di,
cfg_interrupt_do_i        => cfg_interrupt_do,
cfg_interrupt_msienable_i => cfg_interrupt_msienable,
cfg_interrupt_mmenable_i  => cfg_interrupt_mmenable,

cfg_do_i                  => cfg_do,
cfg_di_o                  => cfg_di,
cfg_dwaddr_o              => cfg_dwaddr,
cfg_byte_en_n_o           => cfg_byte_en_n,
cfg_wr_en_n_o             => cfg_wr_en_n,
cfg_rd_en_n_o             => cfg_rd_en_n,
cfg_rd_wr_done_n_i        => cfg_rd_wr_done_n,

cfg_err_tlp_cpl_header_o  => cfg_err_tlp_cpl_header,
cfg_err_ecrc_n_o          => cfg_err_ecrc_n,
cfg_err_ur_n_o            => cfg_err_ur_n,
cfg_err_cpl_timeout_n_o   => cfg_err_cpl_timeout_n,
cfg_err_cpl_unexpect_n_o  => cfg_err_cpl_unexpect_n,
cfg_err_cpl_abort_n_o     => cfg_err_cpl_abort_n,
cfg_err_posted_n_o        => cfg_err_posted_n,
cfg_err_cor_n_o           => cfg_err_cor_n,
cfg_err_locked_n_o        => cfg_err_locked_n,
cfg_err_cpl_rdy_n_i       => cfg_err_cpl_rdy_n,

cfg_pm_wake_n_o           => cfg_pm_wake_n,
cfg_trn_pending_n_o       => cfg_trn_pending_n,
cfg_dsn_o                 => cfg_dsn,
cfg_pcie_link_state_n_i   => cfg_pcie_link_state_n,
cfg_bus_number_i          => cfg_bus_number,
cfg_device_number_i       => cfg_device_number,
cfg_function_number_i     => cfg_function_number,
cfg_status_i              => cfg_status,
cfg_command_i             => cfg_command,
cfg_dstatus_i             => cfg_dstatus,
cfg_dcommand_i            => cfg_dcommand,
cfg_lstatus_i             => cfg_lstatus,
cfg_lcommand_i            => cfg_lcommand,

--------------------------------------
--System Port
--------------------------------------
trn_lnk_up_n_i            => trn_lnk_up_n,
trn_clk_i                 => trn_clk,
trn_reset_n_i             => trn_reset_n
);

user_trn_tbuf_av<=(others=>'1') when trn_tbuf_av/=(trn_tbuf_av'range =>'0') else (others=>'0');
p_out_gtp_refclkout<=refclkout;

gen_ext_rst : if G_PCIE_RST_SEL=1 generate
p_out_module_rdy<=not trn_lnk_up_n;
sys_reset_n<=p_in_pciexp_rst;
end generate gen_ext_rst;

gen_intr_rst : if G_PCIE_RST_SEL=0 generate
sys_reset_n<=from_ctrl_rst_n;

m_reset : pcie_reset
port map
(
pciexp_refclk_i    => refclkout,
trn_lnk_up_n_i     => trn_lnk_up_n,
sys_reset_n_o      => from_ctrl_rst_n,
module_rdy_o       => p_out_module_rdy
);

end generate gen_intr_rst;


trn_fc_sel                <= "000";
trn_tcfg_gnt_n            <= '0';
trn_tstr_n                <= trn_rcpl_streaming_n;

pl_directed_link_change   <= "00";
pl_directed_link_width    <= "00";
pl_directed_link_speed    <= '0';
pl_directed_link_auton    <= '0';
pl_upstream_prefer_deemph <= '0';

--------------------------------------
--convert to axi
--------------------------------------
sys_reset <=not sys_reset_n;

trn_lnk_up_n<=not trn_lnk_up;
trn_reset_n <=not trn_reset;

trn_rnp_ok <=not trn_rnp_ok_n;
trn_tcfg_gnt <=not trn_tcfg_gnt_n;

gen_cfg_byte_en : for i in 0 to cfg_byte_en_n'length -1 generate
cfg_byte_en(i) <=not cfg_byte_en_n(i);
end generate gen_cfg_byte_en;
cfg_wr_en <=not cfg_wr_en_n;
cfg_rd_en <=not cfg_rd_en_n;

cfg_rd_wr_done_n   <=not cfg_rd_wr_done;
cfg_to_turnoff_n   <=not cfg_to_turnoff;
cfg_err_cpl_rdy_n  <=not cfg_err_cpl_rdy;

cfg_pcie_link_state_n<=  cfg_pcie_link_state;

cfg_turnoff_ok  <=not cfg_turnoff_ok_n;
cfg_pm_wake     <=not cfg_pm_wake_n;
cfg_trn_pending <=not cfg_trn_pending_n;

cfg_err_locked      <=not cfg_err_locked_n;
cfg_err_posted      <=not cfg_err_posted_n;
cfg_err_cpl_unexpect<=not cfg_err_cpl_unexpect_n;
cfg_err_cpl_abort   <=not cfg_err_cpl_abort_n;
cfg_err_cpl_timeout <=not cfg_err_cpl_timeout_n;
cfg_err_ecrc        <=not cfg_err_ecrc_n;
cfg_err_ur          <=not cfg_err_ur_n;
cfg_err_cor         <=not cfg_err_cor_n;

cfg_interrupt       <=not cfg_interrupt_n;
cfg_interrupt_rdy_n <=not cfg_interrupt_rdy;
cfg_interrupt_assert<=not cfg_interrupt_assert_n;

--Tx
trn_tcfg_req_n  <=not trn_tcfg_req;
trn_terr_drop_n <=not trn_terr_drop;

trn_tdst_rdy_n    <=not s_axis_tx_tready;
s_axis_tx_tlast   <=not trn_teof_n;
s_axis_tx_tvalid  <=not trn_tsrc_rdy_n;
s_axis_tx_tuser(3)<=not trn_tsrc_dsc_n;
s_axis_tx_tuser(2)<=not trn_tstr_n;
s_axis_tx_tuser(1)<=not trn_terrfwd_n;
s_axis_tx_tuser(0)<='0';

s_axis_tx_tkeep <= CONV_STD_LOGIC_VECTOR(16#0FFF#, s_axis_tx_tkeep'length)
                    when trn_teof_n = '0' and trn_trem_n = CONV_STD_LOGIC_VECTOR(16#01#, trn_trem_n'length) else
                      CONV_STD_LOGIC_VECTOR(16#00FF#, s_axis_tx_tkeep'length)
                        when trn_teof_n = '0' and trn_trem_n = CONV_STD_LOGIC_VECTOR(16#02#, trn_trem_n'length) else
                          CONV_STD_LOGIC_VECTOR(16#000F#, s_axis_tx_tkeep'length)
                            when trn_teof_n = '0' and trn_trem_n = CONV_STD_LOGIC_VECTOR(16#03#, trn_trem_n'length) else
                              CONV_STD_LOGIC_VECTOR(16#FFFF#, s_axis_tx_tkeep'length);

--Rx
m_axis_rx_tready <=not trn_rdst_rdy_n;

gen_trn_rbar_hit : for i in 0 to trn_rbar_hit_n'length -1 generate
trn_rbar_hit_n(i) <=not m_axis_rx_tuser(2+i);
end generate gen_trn_rbar_hit;

trn_rsof_n     <=not is_sof(4);
trn_reof_n     <=not is_eof(4);
trn_rsrc_rdy_n <=not m_axis_rx_tvalid;
trn_rerrfwd_n  <=not m_axis_rx_tuser(1);
trn_rsrc_dsc_n <='1';

trn_rrem_n <= CONV_STD_LOGIC_VECTOR(16#01#, trn_rrem_n'length) when m_axis_rx_tvalid = '1' and is_eof = "11011" else
              CONV_STD_LOGIC_VECTOR(16#02#, trn_rrem_n'length) when m_axis_rx_tvalid = '1' and is_eof = "10111" else
              CONV_STD_LOGIC_VECTOR(16#03#, trn_rrem_n'length) when m_axis_rx_tvalid = '1' and is_eof = "10011" else
              CONV_STD_LOGIC_VECTOR(16#00#, trn_rrem_n'length) when m_axis_rx_tvalid = '1' and is_eof = "11111" else

              CONV_STD_LOGIC_VECTOR(16#00#, trn_rrem_n'length) when m_axis_rx_tvalid = '1' and is_sof = "10000" else
              CONV_STD_LOGIC_VECTOR(16#02#, trn_rrem_n'length) when m_axis_rx_tvalid = '1' and is_sof = "11000" else
              CONV_STD_LOGIC_VECTOR(16#00#, trn_rrem_n'length);

gen_trn_d : for i in 0 to CI_PCIEXP_TRN_DBUS/32 - 1 generate
trn_rd((trn_rd'length - 32*i) - 1 downto (trn_rd'length - 32*(i+1))) <= m_axis_rx_tdata(32*(i+1) - 1 downto 32*i);
s_axis_tx_tdata(32*(i+1) - 1 downto 32*i) <= trn_td((trn_td'length - 32*i) - 1 downto (trn_td'length - 32*(i+1)));
end generate gen_trn_d;

is_sof(4 downto 0)<=m_axis_rx_tuser(14 downto 10);
is_eof(4 downto 0)<=m_axis_rx_tuser(21 downto 17);

--END MAIN
end behavioral;

