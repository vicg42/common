-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 29.08.2012 10:12:36
-- Module Name : pcie_main.vhd
--
-- Description : core PCI-Express (from core_gen) + manage of core
--               (PCI-experss core AXI bus contert to TRN bus)
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.prj_def.all;
use work.prj_cfg.all;
use work.vicg_common_pkg.all;

entity pcie_main is
generic(
G_PCIE_LINK_WIDTH : integer := 1;
G_PCIE_RST_SEL    : integer := 1;
G_DBG : string := "OFF"
);
port(
--------------------------------------------------------
--USR Port
--------------------------------------------------------
p_out_hclk           : out   std_logic;
p_out_gctrl          : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

p_out_dev_ctrl       : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din        : out   std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_in_dev_dout        : in    std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_out_dev_wr         : out   std_logic;
p_out_dev_rd         : out   std_logic;
p_in_dev_status      : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq         : in    std_logic_vector(C_HIRQ_COUNT_MAX - 1 downto 0);
p_in_dev_opt         : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
p_out_dev_opt        : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

--------------------------------------------------------
--DBG
--------------------------------------------------------
p_out_usr_tst        : out   std_logic_vector(127 downto 0);
p_in_usr_tst         : in    std_logic_vector(127 downto 0);
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(255 downto 0);

---------------------------------------------------------
--System Port
---------------------------------------------------------
p_in_fast_simulation : in    std_logic;

p_out_pciexp_txp     : out   std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
p_out_pciexp_txn     : out   std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
p_in_pciexp_rxp      : in    std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
p_in_pciexp_rxn      : in    std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);

p_in_pciexp_rst      : in    std_logic;--Active level - 0!!!

p_out_module_rdy     : out   std_logic;
p_in_gtp_refclkin    : in    std_logic;
p_out_gtp_refclkout  : out   std_logic
);
end entity pcie_main;

architecture behavioral of pcie_main is

constant CI_PCIEXP_TRN_DBUS       : integer :=  128;--
constant CI_PCIEXP_TRN_REMBUS_NEW : integer :=  2  ;--
constant CI_PCIEXP_TRN_BUFAV_BUS  : integer :=  6  ;
constant CI_PCIEXP_BARHIT_BUS     : integer :=  7  ;
constant CI_PCIEXP_FC_HDR_BUS     : integer :=  8  ;
constant CI_PCIEXP_FCDAT_BUS      : integer :=  12 ;
constant CI_PCIEXP_CFG_DBUS       : integer :=  32 ;
constant CI_PCIEXP_CFG_ABUS       : integer :=  10 ;
constant CI_PCIEXP_CFG_CPLHDR_BUS : integer :=  48 ;
constant CI_PCIEXP_CFG_BUSNUM_BUS : integer :=  8  ;
constant CI_PCIEXP_CFG_DEVNUM_BUS : integer :=  5  ;
constant CI_PCIEXP_CFG_FUNNUM_BUS : integer :=  3  ;
constant CI_PCIEXP_CFG_CAP_BUS    : integer :=  16 ;

signal is_sof     : std_logic_vector(4 downto 0);
signal is_eof     : std_logic_vector(4 downto 0);

constant TCQ : time := 1 ps;

function get_userClk2 ( DIV2 : string; UC_FREQ : integer) return integer is
begin
  if (DIV2 = "TRUE") then
    if (UC_FREQ = 4) then
      return 3;
    elsif (UC_FREQ = 3) then
      return 2;
    else
      return UC_FREQ;
    end if;
  else
    return UC_FREQ;
  end if;
end get_userClk2;

-- purpose: Determine Link Speed Configuration for GT
function get_gt_lnk_spd_cfg ( constant simulation : string) return integer is
begin
  if (simulation = "TRUE") then
    return 2;
  else
    return 3;
  end if;
end get_gt_lnk_spd_cfg;

--constant C_DATA_WIDTH     : integer range 64 to 128 := 64;

constant CI_PCIE_EXT_CLK        : string  := "TRUE";
constant CI_PCIE_PL_FAST_TRAIN  : string  := "FALSE";
constant CI_PCIE_USERCLK_FREQ   : integer := selval(3, 4, G_PCIE_LINK_WIDTH = 4);--G_PCIE_LINK_WIDTH = 4/8 - CI_PCIE_USERCLK_FREQ = 3/4
constant CI_PCIE_USERCLK2_DIV2  : string  := "TRUE";
constant CI_PCIE_USERCLK2_FREQ  : integer := get_userClk2(CI_PCIE_USERCLK2_DIV2,CI_PCIE_USERCLK_FREQ);
constant CI_PCIE_LNK_SPD        : integer := get_gt_lnk_spd_cfg(CI_PCIE_PL_FAST_TRAIN);


component core_pciexp_ep_blk_plus_axi_pipe_clock
generic (
PCIE_ASYNC_EN                : string  :=   "FALSE";     -- PCIe async enable
PCIE_TXBUF_EN                : string  :=   "FALSE";     -- PCIe TX buffer enable for Gen1/Gen2 only
PCIE_LANE                    : integer :=   G_PCIE_LINK_WIDTH;           -- PCIe number of lanes
PCIE_LINK_SPEED              : integer :=   3;           -- PCIe link speed
PCIE_REFCLK_FREQ             : integer :=   2;           -- PCIe reference clock frequency
PCIE_USERCLK1_FREQ           : integer :=   3;           -- PCIe user clock 1 frequency
PCIE_USERCLK2_FREQ           : integer :=   3;           -- PCIe user clock 2 frequency
PCIE_DEBUG_MODE              : integer :=   0            -- PCIe Debug Mode
);
port  (

------------ Input -------------------------------------
CLK_CLK                        : in std_logic;
CLK_TXOUTCLK                   : in std_logic;
CLK_RXOUTCLK_IN                : in std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
CLK_RST_N                      : in std_logic;
CLK_PCLK_SEL                   : in std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
CLK_GEN3                       : in std_logic;

------------ Output ------------------------------------
CLK_PCLK                       : out std_logic;
CLK_RXUSRCLK                   : out std_logic;
CLK_RXOUTCLK_OUT               : out std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
CLK_DCLK                       : out std_logic;
CLK_USERCLK1                   : out std_logic;
CLK_USERCLK2                   : out std_logic;
CLK_OOBCLK                     : out std_logic;
CLK_MMCM_LOCK                  : out std_logic);
end component;

component core_pciexp_ep_blk_plus_axi
generic (
PL_FAST_TRAIN   : string := "FALSE";
PCIE_EXT_CLK    : string := "FALSE";
UPSTREAM_FACING : string := "TRUE";
BAR0           : bit_vector := X"FFFFFF00";
BAR1           : bit_vector := X"FFFFFF01"
);
port (
-------------------------------------------------------------------------------------------------------------------
-- 1. PCI Express (pci_exp) Interface                                                                            --
-------------------------------------------------------------------------------------------------------------------
pci_exp_txp                                : out std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
pci_exp_txn                                : out std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
pci_exp_rxp                                : in std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
pci_exp_rxn                                : in std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);

-------------------------------------------------------------------------------------------------------------------
-- 2. Clocking Interface                                                                                         --
-------------------------------------------------------------------------------------------------------------------
PIPE_PCLK_IN                               : in std_logic;
PIPE_RXUSRCLK_IN                           : in std_logic;
PIPE_RXOUTCLK_IN                           : in std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
PIPE_DCLK_IN                               : in std_logic;
PIPE_USERCLK1_IN                           : in std_logic;
PIPE_USERCLK2_IN                           : in std_logic;
PIPE_OOBCLK_IN                             : in std_logic;
PIPE_MMCM_LOCK_IN                          : in std_logic;

PIPE_TXOUTCLK_OUT                          : out std_logic;
PIPE_RXOUTCLK_OUT                          : out std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
PIPE_PCLK_SEL_OUT                          : out std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
PIPE_GEN3_OUT                              : out std_logic;

-------------------------------------------------------------------------------------------------------------------
-- 3. AXI-S Interface                                                                                            --
-------------------------------------------------------------------------------------------------------------------
-- Common
user_clk_out                               : out std_logic;
user_reset_out                             : out std_logic;
user_lnk_up                                : out std_logic;

-- TX
tx_buf_av                                  : out std_logic_vector(5 downto 0);
tx_cfg_req                                 : out std_logic;
tx_err_drop                                : out std_logic;
s_axis_tx_tready                           : out std_logic;
s_axis_tx_tdata                            : in std_logic_vector(CI_PCIEXP_TRN_DBUS - 1 downto 0);
s_axis_tx_tkeep                            : in std_logic_vector((CI_PCIEXP_TRN_DBUS / 8) - 1 downto 0);
s_axis_tx_tlast                            : in std_logic;
s_axis_tx_tvalid                           : in std_logic;
s_axis_tx_tuser                            : in std_logic_vector(3 downto 0);
tx_cfg_gnt                                 : in std_logic;

-- RX
m_axis_rx_tdata                            : out std_logic_vector(CI_PCIEXP_TRN_DBUS - 1 downto 0);
m_axis_rx_tkeep                            : out std_logic_vector((CI_PCIEXP_TRN_DBUS / 8) - 1 downto 0);
m_axis_rx_tlast                            : out std_logic;
m_axis_rx_tvalid                           : out std_logic;
m_axis_rx_tready                           : in std_logic;
m_axis_rx_tuser                            : out std_logic_vector(21 downto 0);
rx_np_ok                                   : in std_logic;
rx_np_req                                  : in std_logic;

-- Flow Control
fc_cpld                                    : out std_logic_vector(11 downto 0);
fc_cplh                                    : out std_logic_vector(7 downto 0);
fc_npd                                     : out std_logic_vector(11 downto 0);
fc_nph                                     : out std_logic_vector(7 downto 0);
fc_pd                                      : out std_logic_vector(11 downto 0);
fc_ph                                      : out std_logic_vector(7 downto 0);
fc_sel                                     : in std_logic_vector(2 downto 0);

-------------------------------------------------------------------------------------------------------------------
-- 4. Configuration (CFG) Interface                                                                              --
-------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------
-- EP and RP                                                      --
---------------------------------------------------------------------
cfg_mgmt_do                                : out std_logic_vector (31 downto 0);
cfg_mgmt_rd_wr_done                        : out std_logic;

cfg_status                                 : out std_logic_vector(15 downto 0);
cfg_command                                : out std_logic_vector(15 downto 0);
cfg_dstatus                                : out std_logic_vector(15 downto 0);
cfg_dcommand                               : out std_logic_vector(15 downto 0);
cfg_lstatus                                : out std_logic_vector(15 downto 0);
cfg_lcommand                               : out std_logic_vector(15 downto 0);
cfg_dcommand2                              : out std_logic_vector(15 downto 0);
cfg_pcie_link_state                        : out std_logic_vector(2 downto 0);

cfg_pmcsr_pme_en                           : out std_logic;
cfg_pmcsr_powerstate                       : out std_logic_vector(1 downto 0);
cfg_pmcsr_pme_status                       : out std_logic;
cfg_received_func_lvl_rst                  : out std_logic;

-- Management Interface
cfg_mgmt_di                                : in std_logic_vector (31 downto 0);
cfg_mgmt_byte_en                           : in std_logic_vector (3 downto 0);
cfg_mgmt_dwaddr                            : in std_logic_vector (9 downto 0);
cfg_mgmt_wr_en                             : in std_logic;
cfg_mgmt_rd_en                             : in std_logic;
cfg_mgmt_wr_readonly                       : in std_logic;

-- Error Reporting Interface
cfg_err_ecrc                               : in std_logic;
cfg_err_ur                                 : in std_logic;
cfg_err_cpl_timeout                        : in std_logic;
cfg_err_cpl_unexpect                       : in std_logic;
cfg_err_cpl_abort                          : in std_logic;
cfg_err_posted                             : in std_logic;
cfg_err_cor                                : in std_logic;
cfg_err_atomic_egress_blocked              : in std_logic;
cfg_err_internal_cor                       : in std_logic;
cfg_err_malformed                          : in std_logic;
cfg_err_mc_blocked                         : in std_logic;
cfg_err_poisoned                           : in std_logic;
cfg_err_norecovery                         : in std_logic;
cfg_err_tlp_cpl_header                     : in std_logic_vector(47 downto 0);
cfg_err_cpl_rdy                            : out std_logic;
cfg_err_locked                             : in std_logic;
cfg_err_acs                                : in std_logic;
cfg_err_internal_uncor                     : in std_logic;
cfg_trn_pending                            : in std_logic;
cfg_pm_halt_aspm_l0s                       : in std_logic;
cfg_pm_halt_aspm_l1                        : in std_logic;
cfg_pm_force_state_en                      : in std_logic;
cfg_pm_force_state                         : std_logic_vector(1 downto 0);
cfg_dsn                                    : std_logic_vector(63 downto 0);

---------------------------------------------------------------------
-- EP Only                                                        --
---------------------------------------------------------------------
cfg_interrupt                              : in std_logic;
cfg_interrupt_rdy                          : out std_logic;
cfg_interrupt_assert                       : in std_logic;
cfg_interrupt_di                           : in std_logic_vector(7 downto 0);
cfg_interrupt_do                           : out std_logic_vector(7 downto 0);
cfg_interrupt_mmenable                     : out std_logic_vector(2 downto 0);
cfg_interrupt_msienable                    : out std_logic;
cfg_interrupt_msixenable                   : out std_logic;
cfg_interrupt_msixfm                       : out std_logic;
cfg_interrupt_stat                         : in std_logic;
cfg_pciecap_interrupt_msgnum               : in std_logic_vector(4 downto 0);
cfg_to_turnoff                             : out std_logic;
cfg_turnoff_ok                             : in std_logic;
cfg_bus_number                             : out std_logic_vector(7 downto 0);
cfg_device_number                          : out std_logic_vector(4 downto 0);
cfg_function_number                        : out std_logic_vector(2 downto 0);
cfg_pm_wake                                : in std_logic;

---------------------------------------------------------------------
-- RP Only                                                        --
---------------------------------------------------------------------
cfg_pm_send_pme_to                         : in std_logic;
cfg_ds_bus_number                          : in std_logic_vector(7 downto 0);
cfg_ds_device_number                       : in std_logic_vector(4 downto 0);
cfg_ds_function_number                     : in std_logic_vector(2 downto 0);

cfg_mgmt_wr_rw1c_as_rw                     : in std_logic;
cfg_msg_received                           : out std_logic;
cfg_msg_data                               : out std_logic_vector(15 downto 0);

cfg_bridge_serr_en                         : out std_logic;
cfg_slot_control_electromech_il_ctl_pulse  : out std_logic;
cfg_root_control_syserr_corr_err_en        : out std_logic;
cfg_root_control_syserr_non_fatal_err_en   : out std_logic;
cfg_root_control_syserr_fatal_err_en       : out std_logic;
cfg_root_control_pme_int_en                : out std_logic;
cfg_aer_rooterr_corr_err_reporting_en      : out std_logic;
cfg_aer_rooterr_non_fatal_err_reporting_en : out std_logic;
cfg_aer_rooterr_fatal_err_reporting_en     : out std_logic;
cfg_aer_rooterr_corr_err_received          : out std_logic;
cfg_aer_rooterr_non_fatal_err_received     : out std_logic;
cfg_aer_rooterr_fatal_err_received         : out std_logic;

cfg_msg_received_err_cor                   : out std_logic;
cfg_msg_received_err_non_fatal             : out std_logic;
cfg_msg_received_err_fatal                 : out std_logic;
cfg_msg_received_pm_as_nak                 : out std_logic;
cfg_msg_received_pm_pme                    : out std_logic;
cfg_msg_received_pme_to_ack                : out std_logic;
cfg_msg_received_assert_int_a              : out std_logic;
cfg_msg_received_assert_int_b              : out std_logic;
cfg_msg_received_assert_int_c              : out std_logic;
cfg_msg_received_assert_int_d              : out std_logic;
cfg_msg_received_deassert_int_a            : out std_logic;
cfg_msg_received_deassert_int_b            : out std_logic;
cfg_msg_received_deassert_int_c            : out std_logic;
cfg_msg_received_deassert_int_d            : out std_logic;
cfg_msg_received_setslotpowerlimit         : out std_logic;

-------------------------------------------------------------------------------------------------------------------
-- 5. Physical Layer Control and Status (PL) Interface                                                           --
-------------------------------------------------------------------------------------------------------------------
pl_directed_link_change                    : in std_logic_vector(1 downto 0);
pl_directed_link_width                     : in std_logic_vector(1 downto 0);
pl_directed_link_speed                     : in std_logic;
pl_directed_link_auton                     : in std_logic;
pl_upstream_prefer_deemph                  : in std_logic;

pl_sel_lnk_rate                            : out std_logic;
pl_sel_lnk_width                           : out std_logic_vector(1 downto 0);
pl_ltssm_state                             : out std_logic_vector(5 downto 0);
pl_lane_reversal_mode                      : out std_logic_vector(1 downto 0);

pl_phy_lnk_up                              : out std_logic;
pl_tx_pm_state                             : out std_logic_vector(2 downto 0);
pl_rx_pm_state                             : out std_logic_vector(1 downto 0);

pl_link_upcfg_cap                          : out std_logic;
pl_link_gen2_cap                           : out std_logic;
pl_link_partner_gen2_supported             : out std_logic;
pl_initial_link_width                      : out std_logic_vector(2 downto 0);

pl_directed_change_done                    : out std_logic;

---------------------------------------------------------------------
-- EP Only                                                        --
---------------------------------------------------------------------
pl_received_hot_rst                        : out std_logic;
---------------------------------------------------------------------
-- RP Only                                                        --
---------------------------------------------------------------------
pl_transmit_hot_rst                        : in std_logic;
pl_downstream_deemph_source                : in std_logic;
-------------------------------------------------------------------------------------------------------------------
-- 6. AER interface                                                                                              --
-------------------------------------------------------------------------------------------------------------------
cfg_err_aer_headerlog                      : in std_logic_vector(127 downto 0);
cfg_aer_interrupt_msgnum                   : in std_logic_vector(4 downto 0);
cfg_err_aer_headerlog_set                  : out std_logic;
cfg_aer_ecrc_check_en                      : out std_logic;
cfg_aer_ecrc_gen_en                        : out std_logic;
-------------------------------------------------------------------------------------------------------------------
-- 7. VC interface                                                                                               --
-------------------------------------------------------------------------------------------------------------------
cfg_vc_tcvc_map                            : out std_logic_vector(6 downto 0);

-------------------------------------------------------------------------------------------------------------------
-- 8. System(SYS) Interface                                                                                      --
-------------------------------------------------------------------------------------------------------------------
PIPE_MMCM_RST_N                            : in std_logic;   --     // Async      | Async
sys_clk                                    : in std_logic;
sys_rst_n                                  : in std_logic);
end component;

component pcie_ctrl
generic(
G_PCIEXP_TRN_DBUS : integer := 64;
G_DBG : string :="OFF"
);
port(
--------------------------------------
--USR Port
--------------------------------------
p_out_hclk                : out   std_logic;
p_out_gctrl               : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

p_out_dev_ctrl            : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din             : out   std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_in_dev_dout             : in    std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_out_dev_wr              : out   std_logic;
p_out_dev_rd              : out   std_logic;
p_in_dev_status           : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq              : in    std_logic_vector(C_HIRQ_COUNT_MAX - 1 downto 0);
p_in_dev_opt              : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
p_out_dev_opt             : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

p_out_tst                 : out   std_logic_vector(127 downto 0);
p_in_tst                  : in    std_logic_vector(127 downto 0);

--------------------------------------
--Tx
--------------------------------------
trn_td_o                  : out   std_logic_vector(G_PCIEXP_TRN_DBUS - 1 downto 0)  ;
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
trn_rd_i                  : in    std_logic_vector(G_PCIEXP_TRN_DBUS - 1 downto 0)  ;
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

signal in_pkt_reg : std_logic;

signal from_ctrl_rst_n                : std_logic;

signal refclkout                      : std_logic;

signal user_reset                     : std_logic;
signal user_lnk_up                    : std_logic;
signal trn_clk                        : std_logic;-- //synthesis attribute max_fanout of trn_clk is "100000"
signal trn_reset,trn_reset_n          : std_logic;
signal trn_lnk_up,trn_lnk_up_n        : std_logic;

signal s_axis_tx_tready               : std_logic;
signal s_axis_tx_tdata                : std_logic_vector(CI_PCIEXP_TRN_DBUS - 1 downto 0);
signal s_axis_tx_tkeep                : std_logic_vector((CI_PCIEXP_TRN_DBUS / 8) - 1 downto 0);
signal s_axis_tx_tuser                : std_logic_vector(3 downto 0);
signal s_axis_tx_tlast                : std_logic;
signal s_axis_tx_tvalid               : std_logic;

signal m_axis_rx_tdata                : std_logic_vector(CI_PCIEXP_TRN_DBUS - 1 downto 0);
signal m_axis_rx_tkeep                : std_logic_vector((CI_PCIEXP_TRN_DBUS / 8) - 1 downto 0);
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
signal trn_td                         : std_logic_vector(CI_PCIEXP_TRN_DBUS - 1 downto 0);
signal trn_trem_n_core                : std_logic_vector(CI_PCIEXP_TRN_REMBUS_NEW - 1 downto 0);
signal trn_trem_n                     : std_logic_vector(3 downto 0);
signal trn_tbuf_av                    : std_logic_vector(CI_PCIEXP_TRN_BUFAV_BUS - 1 downto 0);

signal trn_rsof_n                     : std_logic;
signal trn_reof_n                     : std_logic;
signal trn_rsrc_rdy_n                 : std_logic;
signal trn_rsrc_dsc_n                 : std_logic;
signal trn_rdst_rdy_n                 : std_logic;
signal trn_rerrfwd_n                  : std_logic;
signal trn_rnp_ok,trn_rnp_ok_n                   : std_logic;
signal trn_rd                         : std_logic_vector(CI_PCIEXP_TRN_DBUS - 1 downto 0);
signal trn_rrem_n_core                : std_logic_vector(CI_PCIEXP_TRN_REMBUS_NEW - 1 downto 0);
signal trn_rrem_n                     : std_logic_vector(3 downto 0);
signal trn_rbar_hit_n                 : std_logic_vector(CI_PCIEXP_BARHIT_BUS - 1 downto 0);
--signal trn_rfc_nph_av                 : std_logic_vector(CI_PCIEXP_FC_HDR_BUS - 1 downto 0);
--signal trn_rfc_npd_av                 : std_logic_vector(CI_PCIEXP_FCDAT_BUS - 1 downto 0);
--signal trn_rfc_ph_av                  : std_logic_vector(CI_PCIEXP_FC_HDR_BUS - 1 downto 0);
--signal trn_rfc_pd_av                  : std_logic_vector(CI_PCIEXP_FCDAT_BUS - 1 downto 0);
signal trn_rcpl_streaming_n           : std_logic;

signal cfg_do                         : std_logic_vector(CI_PCIEXP_CFG_DBUS - 1 downto 0);
signal cfg_di                         : std_logic_vector(CI_PCIEXP_CFG_DBUS - 1 downto 0);
signal cfg_dwaddr                     : std_logic_vector(CI_PCIEXP_CFG_ABUS - 1 downto 0);
signal cfg_byte_en,cfg_byte_en_n                   : std_logic_vector(CI_PCIEXP_CFG_DBUS/8 - 1 downto 0);
signal cfg_wr_en,cfg_wr_en_n                       : std_logic;
signal cfg_rd_en,cfg_rd_en_n                       : std_logic;
signal cfg_rd_wr_done,cfg_rd_wr_done_n             : std_logic;

signal cfg_err_tlp_cpl_header                      : std_logic_vector(CI_PCIEXP_CFG_CPLHDR_BUS - 1 downto 0);--47 downto 0);
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
signal cfg_interrupt_di                            : std_logic_vector(7 downto 0);
signal cfg_interrupt_do                            : std_logic_vector(7 downto 0);
signal cfg_interrupt_mmenable                      : std_logic_vector(2 downto 0);
signal cfg_interrupt_msienable                     : std_logic;

signal cfg_turnoff_ok,cfg_turnoff_ok_n             : std_logic;
signal cfg_to_turnoff,cfg_to_turnoff_n             : std_logic;
signal cfg_pm_wake,cfg_pm_wake_n                   : std_logic;
signal cfg_trn_pending,cfg_trn_pending_n           : std_logic;
signal cfg_dsn                                     : std_logic_vector(63 downto 0);

signal cfg_pcie_link_state,cfg_pcie_link_state_n   : std_logic_vector(2 downto 0);
signal cfg_bus_number                 : std_logic_vector(CI_PCIEXP_CFG_BUSNUM_BUS - 1 downto 0);
signal cfg_device_number              : std_logic_vector(CI_PCIEXP_CFG_DEVNUM_BUS - 1 downto 0);
signal cfg_function_number            : std_logic_vector(CI_PCIEXP_CFG_FUNNUM_BUS - 1 downto 0);
signal cfg_status                     : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS - 1 downto 0);
signal cfg_command                    : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS - 1 downto 0);
signal cfg_dstatus                    : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS - 1 downto 0);
signal cfg_dcommand                   : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS - 1 downto 0);
signal cfg_lstatus                    : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS - 1 downto 0);
signal cfg_lcommand                   : std_logic_vector(CI_PCIEXP_CFG_CAP_BUS - 1 downto 0);

signal user_trn_tbuf_av               : std_logic_vector(5 downto 0);--(15 downto 0);

--New Signal
signal trn_tcfg_req,trn_tcfg_req_n    : std_logic;
signal trn_terr_drop,trn_terr_drop_n  : std_logic;

signal trn_tcfg_gnt,trn_tcfg_gnt_n    : std_logic;
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

-- Wires used for external clocking connectivity
signal PIPE_PCLK_IN                   : std_logic;
signal PIPE_RXUSRCLK_IN               : std_logic;
signal PIPE_RXOUTCLK_IN               : std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
signal PIPE_DCLK_IN                   : std_logic;
signal PIPE_USERCLK1_IN               : std_logic;
signal PIPE_USERCLK2_IN               : std_logic;
signal PIPE_OOBCLK_IN                 : std_logic;
signal PIPE_MMCM_LOCK_IN              : std_logic;

signal PIPE_TXOUTCLK_OUT              : std_logic;
signal PIPE_RXOUTCLK_OUT              : std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
signal PIPE_PCLK_SEL_OUT              : std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
signal PIPE_GEN3_OUT                  : std_logic;
signal PIPE_MMCM_RST_N                : std_logic := '1';


signal tst_s_axis_tx_tready           : std_logic;
signal tst_s_axis_tx_tlast            : std_logic;
signal tst_s_axis_tx_tvalid           : std_logic;
signal tst_s_axis_tx_tkeep            : std_logic_vector(7 downto 0);
signal tst_s_axis_tx_tuser            : std_logic_vector(3 downto 0);
signal tst_m_axis_rx_tready           : std_logic;
signal tst_m_axis_rx_tvalid           : std_logic;
signal tst_m_axis_rx_tlast            : std_logic;
signal tst_m_axis_rx_tkeep            : std_logic_vector(7 downto 0);
signal tst_m_axis_rx_tuser            : std_logic_vector(3 downto 0);

signal tst_trn_tsof_n                 : std_logic;
signal tst_trn_teof_n                 : std_logic;
signal tst_trn_tsrc_rdy_n             : std_logic;
signal tst_trn_tdst_rdy_n             : std_logic;
signal tst_trn_tsrc_dsc_n             : std_logic;
signal tst_trn_trem_n                 : std_logic_vector(0 downto 0);

signal tst_trn_rsof_n                 : std_logic;
signal tst_trn_reof_n                 : std_logic;
signal tst_trn_rsrc_rdy_n             : std_logic;
signal tst_trn_rdst_rdy_n             : std_logic;

signal tst_trn_rrem_n                 : std_logic_vector(0 downto 0);
signal tst_trn_rd                     : std_logic_vector(63 downto 0);

signal tst_cfg_interrupt_n            : std_logic;
signal tst_cfg_interrupt_rdy_n        : std_logic;
signal tst_cfg_interrupt_assert_n     : std_logic;
signal tst_trn_rbar_hit_n             : std_logic_vector(1 downto 0);


begin --architecture behavioral

--#############################################
--DBG
--#############################################
p_out_tst(0) <= tst_cfg_interrupt_n;
p_out_tst(1) <= tst_cfg_interrupt_rdy_n;
p_out_tst(2) <= tst_cfg_interrupt_assert_n;
p_out_tst(3) <= cfg_interrupt_msienable;
p_out_tst(4) <= tst_trn_tsof_n;
p_out_tst(5) <= tst_trn_teof_n;
p_out_tst(6) <= tst_trn_tsrc_rdy_n;
p_out_tst(7) <= tst_trn_tdst_rdy_n;
p_out_tst(8) <= tst_trn_tsrc_dsc_n;
p_out_tst(9) <= tst_trn_rsof_n;
p_out_tst(10) <= tst_trn_reof_n;
p_out_tst(11) <= tst_trn_rsrc_rdy_n;
p_out_tst(12) <= '0';--tst_trn_rsrc_dsc_n;
p_out_tst(13) <= tst_trn_rdst_rdy_n;
p_out_tst(14) <= tst_trn_rbar_hit_n(0);
p_out_tst(15) <= tst_trn_rbar_hit_n(1);
p_out_tst(16) <= cfg_command(2);--cfg_bus_mstr_enable
p_out_tst(18 downto 17) <= std_logic_vector(RESIZE(UNSIGNED(trn_rrem_n_core), 18 - 17 + 1));
p_out_tst(146 downto 19) <= std_logic_vector(RESIZE(UNSIGNED(tst_trn_rd), 128));
--p_out_tst(146 downto 19) <= trn_rd(127 downto 0);
p_out_tst(162 downto 147) <= std_logic_vector(RESIZE(UNSIGNED(tst_trn_rrem_n), 162 - 147 + 1));
p_out_tst(168 downto 163) <= trn_tbuf_av;
p_out_tst(170 downto 169) <= std_logic_vector(RESIZE(UNSIGNED(tst_trn_trem_n), 170 - 169 + 1));
p_out_tst(171) <= tst_s_axis_tx_tready;--s_axis_tx_tready;
p_out_tst(172) <= tst_s_axis_tx_tlast ;--s_axis_tx_tlast ;
p_out_tst(173) <= tst_s_axis_tx_tvalid;--s_axis_tx_tvalid;
p_out_tst(181 downto 174) <= tst_s_axis_tx_tkeep(7 downto 0);--s_axis_tx_tkeep(7 downto 0);
p_out_tst(185 downto 182) <= tst_s_axis_tx_tuser(3 downto 0);--s_axis_tx_tuser(3 downto 0);
p_out_tst(186) <= tst_m_axis_rx_tready;--m_axis_rx_tready;
p_out_tst(187) <= tst_m_axis_rx_tvalid;--m_axis_rx_tvalid;
p_out_tst(188) <= tst_m_axis_rx_tlast; --m_axis_rx_tlast;
p_out_tst(196 downto 189) <= tst_m_axis_rx_tkeep(7 downto 0);--m_axis_rx_tkeep(7 downto 0);
p_out_tst(200 downto 197) <= tst_m_axis_rx_tuser(3 downto 0);--m_axis_rx_tuser(3 downto 0);
p_out_tst(215 downto 201) <= (others => '0');
p_out_tst(231 downto 216) <= (others => '0');
p_out_tst(249 downto 248) <= (others => '0');
p_out_tst(255 downto 250) <= (others => '0');

process(trn_clk)
begin
if rising_edge(trn_clk) then
tst_s_axis_tx_tready            <= s_axis_tx_tready;
tst_s_axis_tx_tlast             <= s_axis_tx_tlast ;
tst_s_axis_tx_tvalid            <= s_axis_tx_tvalid;
tst_s_axis_tx_tkeep(7 downto 0) <= s_axis_tx_tkeep(7 downto 0);
tst_s_axis_tx_tuser(3 downto 0) <= s_axis_tx_tuser(3 downto 0);
tst_m_axis_rx_tready            <= m_axis_rx_tready;
tst_m_axis_rx_tvalid            <= m_axis_rx_tvalid;
tst_m_axis_rx_tlast             <= m_axis_rx_tlast;
tst_m_axis_rx_tkeep(7 downto 0) <= m_axis_rx_tkeep(7 downto 0);
tst_m_axis_rx_tuser(3 downto 0) <= m_axis_rx_tuser(3 downto 0);

tst_trn_tsof_n     <= trn_tsof_n;
tst_trn_teof_n     <= trn_teof_n;
tst_trn_tsrc_rdy_n <= trn_tsrc_rdy_n;
tst_trn_tdst_rdy_n <= trn_tdst_rdy_n;
tst_trn_tsrc_dsc_n <= trn_tsrc_dsc_n;
tst_trn_trem_n(0) <= trn_trem_n(0);

tst_trn_rsof_n      <= trn_rsof_n;
tst_trn_reof_n      <= trn_reof_n;
tst_trn_rsrc_rdy_n  <= trn_rsrc_rdy_n;
tst_trn_rdst_rdy_n  <= trn_rdst_rdy_n;

tst_trn_rrem_n(0)   <= trn_rrem_n(0);
tst_trn_rd          <= trn_rd(63 downto 0);

tst_cfg_interrupt_n        <= cfg_interrupt_n;
tst_cfg_interrupt_rdy_n    <= cfg_interrupt_rdy_n;
tst_cfg_interrupt_assert_n <= cfg_interrupt_assert_n;

tst_trn_rbar_hit_n <= trn_rbar_hit_n(1 downto 0);

end if;
end process;

--#############################################
--Core PCI-Express
--#############################################
ext_clk: if (CI_PCIE_EXT_CLK = "TRUE") generate
pipe_clock_i : core_pciexp_ep_blk_plus_axi_pipe_clock
generic map(
PCIE_ASYNC_EN                  => "FALSE",                    -- PCIe async enable
PCIE_TXBUF_EN                  => "FALSE",                    -- PCIe TX buffer enable for Gen1/Gen2 only
PCIE_LANE                      => C_PCGF_PCIE_LINK_WIDTH,     -- PCIe number of lanes
PCIE_LINK_SPEED                => CI_PCIE_LNK_SPD ,           -- PCIe link speed
PCIE_REFCLK_FREQ               => 0,                          -- PCIe reference clock frequency
PCIE_USERCLK1_FREQ             => (CI_PCIE_USERCLK_FREQ + 1), -- PCIe user clock 1 frequency
PCIE_USERCLK2_FREQ             => (CI_PCIE_USERCLK2_FREQ + 1),-- PCIe user clock 2 frequency
PCIE_DEBUG_MODE                => 0                           -- PCIe Debug Mode
)
port map(
------------ Input -------------------------------------
CLK_CLK                        => p_in_gtp_refclkin,
CLK_TXOUTCLK                   => PIPE_TXOUTCLK_OUT,       -- Reference clock from lane 0
CLK_RXOUTCLK_IN                => PIPE_RXOUTCLK_OUT,
-- CLK_RST_N                      => '1',
CLK_RST_N                      => PIPE_MMCM_RST_N,
CLK_PCLK_SEL                   => PIPE_PCLK_SEL_OUT,
CLK_GEN3                       => PIPE_GEN3_OUT,

------------ Output ------------------------------------
CLK_PCLK                       => PIPE_PCLK_IN,
CLK_RXUSRCLK                   => PIPE_RXUSRCLK_IN,
CLK_RXOUTCLK_OUT               => PIPE_RXOUTCLK_IN,
CLK_DCLK                       => PIPE_DCLK_IN,
CLK_USERCLK1                   => PIPE_USERCLK1_IN,
CLK_USERCLK2                   => PIPE_USERCLK2_IN,
CLK_OOBCLK                     => PIPE_OOBCLK_IN,
CLK_MMCM_LOCK                  => PIPE_MMCM_LOCK_IN
);
end generate ext_clk;

gen_int_clk: if (CI_PCIE_EXT_CLK = "FALSE") generate
PIPE_PCLK_IN        <= '0';
PIPE_RXUSRCLK_IN    <= '0';
PIPE_RXOUTCLK_IN    <= (others => '0');
PIPE_DCLK_IN        <= '0';
PIPE_USERCLK1_IN    <= '0';
PIPE_USERCLK2_IN    <= '0';
PIPE_OOBCLK_IN      <= '0';
PIPE_MMCM_LOCK_IN   <= '0';
end generate;--gen_int_clk

m_core : core_pciexp_ep_blk_plus_axi
generic map(
PL_FAST_TRAIN => CI_PCIE_PL_FAST_TRAIN,
PCIE_EXT_CLK  => CI_PCIE_EXT_CLK,
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
s_axis_tx_tdata         => s_axis_tx_tdata    ,--: in std_logic_vector(CI_PCIEXP_TRN_DBUS - 1 downto 0);
s_axis_tx_tkeep         => s_axis_tx_tkeep    ,--: in std_logic_vector(7 downto 0);
s_axis_tx_tuser         => s_axis_tx_tuser    ,--: in std_logic_vector(3 downto 0);
s_axis_tx_tlast         => s_axis_tx_tlast    ,--: in std_logic;
s_axis_tx_tvalid        => s_axis_tx_tvalid   ,--: in std_logic;

--------------------------------------
--Rx
--------------------------------------
m_axis_rx_tdata         => m_axis_rx_tdata    ,--: out std_logic_vector(CI_PCIEXP_TRN_DBUS - 1 downto 0);
m_axis_rx_tkeep         => m_axis_rx_tkeep    ,--: out std_logic_vector(7 downto 0);
m_axis_rx_tlast         => m_axis_rx_tlast    ,--: out std_logic;
m_axis_rx_tvalid        => m_axis_rx_tvalid   ,--: out std_logic;
m_axis_rx_tuser         => m_axis_rx_tuser    ,--: out std_logic_vector(21 downto 0);
m_axis_rx_tready        => m_axis_rx_tready   ,--: in std_logic;

--------------------------------------
--System Port
--------------------------------------
user_clk_out                   => trn_clk ,
user_reset_out                 => user_reset,
user_lnk_up                    => user_lnk_up,

sys_clk                        => p_in_gtp_refclkin,
--sys_reset                      => sys_reset,--: in std_logic;

--------------------------------------
--CFG Interface
--------------------------------------
cfg_mgmt_do                    => cfg_do                        ,--: out std_logic_vector (31 downto 0);
cfg_mgmt_rd_wr_done            => cfg_rd_wr_done                ,--: out std_logic;
cfg_mgmt_di                    => cfg_di                        ,--: in std_logic_vector (31 downto 0);
cfg_mgmt_byte_en               => cfg_byte_en                   ,--: in std_logic_vector (3 downto 0);
cfg_mgmt_dwaddr                => cfg_dwaddr                    ,--: in std_logic_vector (9 downto 0);
cfg_mgmt_wr_en                 => cfg_wr_en                     ,--: in std_logic;
cfg_mgmt_rd_en                 => cfg_rd_en                     ,--: in std_logic;

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
--
--------------------------------------
pl_initial_link_width          => pl_initial_link_width         ,--: out std_logic_vector(2 downto 0);
pl_lane_reversal_mode          => pl_lane_reversal_mode         ,--: out std_logic_vector(1 downto 0);
--pl_link_gen2_capable           => pl_link_gen2_capable          ,--: out std_logic;
pl_link_partner_gen2_supported => pl_link_partner_gen2_supported,--: out std_logic;
--pl_link_upcfg_capable          => pl_link_upcfg_capable         ,--: out std_logic;
pl_ltssm_state                 => pl_ltssm_state                ,--: out std_logic_vector(5 downto 0);
pl_received_hot_rst            => pl_received_hot_rst           ,--: out std_logic;
--pl_sel_link_rate               => pl_sel_link_rate              ,--: out std_logic;
--pl_sel_link_width              => pl_sel_link_width             ,--: out std_logic_vector(1 downto 0);
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
tx_cfg_req                     => trn_tcfg_req                  ,--: out std_logic;
tx_cfg_gnt                     => trn_tcfg_gnt                  ,--: in std_logic;
rx_np_ok                       => trn_rnp_ok                    ,--: in std_logic


--------------------------------------
--New Signal
--------------------------------------
PIPE_PCLK_IN                               => PIPE_PCLK_IN,
PIPE_RXUSRCLK_IN                           => PIPE_RXUSRCLK_IN,
PIPE_RXOUTCLK_IN                           => PIPE_RXOUTCLK_IN,
PIPE_DCLK_IN                               => PIPE_DCLK_IN,
PIPE_USERCLK1_IN                           => PIPE_USERCLK1_IN,
PIPE_USERCLK2_IN                           => PIPE_USERCLK2_IN,
PIPE_OOBCLK_IN                             => PIPE_OOBCLK_IN,
PIPE_MMCM_LOCK_IN                          => PIPE_MMCM_LOCK_IN,
PIPE_TXOUTCLK_OUT                          => PIPE_TXOUTCLK_OUT,
PIPE_RXOUTCLK_OUT                          => PIPE_RXOUTCLK_OUT,
PIPE_PCLK_SEL_OUT                          => PIPE_PCLK_SEL_OUT,
PIPE_GEN3_OUT                              => PIPE_GEN3_OUT,

rx_np_req                                  => '1',--: in std_logic;

cfg_mgmt_wr_readonly                       => '0',--: in std_logic;
cfg_received_func_lvl_rst                  => open,--: out std_logic;

cfg_err_atomic_egress_blocked              => '0',--: in std_logic;
cfg_err_internal_cor                       => '0',--: in std_logic;
cfg_err_malformed                          => '0',--: in std_logic;
cfg_err_mc_blocked                         => '0',--: in std_logic;
cfg_err_poisoned                           => '0',--: in std_logic;
cfg_err_norecovery                         => '0',--: in std_logic;
cfg_err_acs                                => '0',--: in std_logic;
cfg_err_internal_uncor                     => '0',--: in std_logic;


cfg_pm_halt_aspm_l0s                       => '0',--: in std_logic;
cfg_pm_halt_aspm_l1                        => '0',--: in std_logic;
cfg_pm_force_state_en                      => '0',--: in std_logic;
cfg_pm_force_state                         => "00",--: std_logic_vector(1 downto 0);

cfg_interrupt_stat                         => '0',--: in std_logic;
cfg_pciecap_interrupt_msgnum               => "00000",--: in std_logic_vector(4 downto 0);

cfg_pm_send_pme_to                         => '0' ,--: in std_logic;
cfg_ds_bus_number                          => x"00" ,--: in std_logic_vector(7 downto 0);
cfg_ds_device_number                       => "00000" ,--: in std_logic_vector(4 downto 0);
cfg_ds_function_number                     => "000" ,--: in std_logic_vector(2 downto 0);

cfg_mgmt_wr_rw1c_as_rw                     => '0' ,--: in std_logic;
cfg_msg_received                           => open,--: out std_logic;
cfg_msg_data                               => open,--: out std_logic_vector(15 downto 0);

cfg_bridge_serr_en                         => open,--: out std_logic;
cfg_slot_control_electromech_il_ctl_pulse  => open,--: out std_logic;
cfg_root_control_syserr_corr_err_en        => open,--: out std_logic;
cfg_root_control_syserr_non_fatal_err_en   => open,--: out std_logic;
cfg_root_control_syserr_fatal_err_en       => open,--: out std_logic;
cfg_root_control_pme_int_en                => open,--: out std_logic;
cfg_aer_rooterr_corr_err_reporting_en      => open,--: out std_logic;
cfg_aer_rooterr_non_fatal_err_reporting_en => open,--: out std_logic;
cfg_aer_rooterr_fatal_err_reporting_en     => open,--: out std_logic;
cfg_aer_rooterr_corr_err_received          => open,--: out std_logic;
cfg_aer_rooterr_non_fatal_err_received     => open,--: out std_logic;
cfg_aer_rooterr_fatal_err_received         => open,--: out std_logic;

cfg_msg_received_err_cor                   => open,--: out std_logic;
cfg_msg_received_err_non_fatal             => open,--: out std_logic;
cfg_msg_received_err_fatal                 => open,--: out std_logic;
cfg_msg_received_pm_as_nak                 => open,--: out std_logic;
cfg_msg_received_pm_pme                    => open,--: out std_logic;
cfg_msg_received_pme_to_ack                => open,--: out std_logic;
cfg_msg_received_assert_int_a              => open,--: out std_logic;
cfg_msg_received_assert_int_b              => open,--: out std_logic;
cfg_msg_received_assert_int_c              => open,--: out std_logic;
cfg_msg_received_assert_int_d              => open,--: out std_logic;
cfg_msg_received_deassert_int_a            => open,--: out std_logic;
cfg_msg_received_deassert_int_b            => open,--: out std_logic;
cfg_msg_received_deassert_int_c            => open,--: out std_logic;
cfg_msg_received_deassert_int_d            => open,--: out std_logic;
cfg_msg_received_setslotpowerlimit         => open,--: out std_logic;

pl_sel_lnk_rate                            => open,--: out std_logic;
pl_sel_lnk_width                           => open,--: out std_logic_vector(1 downto 0);

pl_phy_lnk_up                              => open,--: out std_logic;
pl_tx_pm_state                             => open,--: out std_logic_vector(2 downto 0);
pl_rx_pm_state                             => open,--: out std_logic_vector(1 downto 0);

pl_directed_change_done                    => open,--: out std_logic;

pl_transmit_hot_rst                        => '0',--: in std_logic;
pl_downstream_deemph_source                => '0',--: in std_logic;
-------------------------------------------------------------------------------------------------------------------
-- 6. AER interface                                                                                              --
-------------------------------------------------------------------------------------------------------------------
cfg_err_aer_headerlog                      => (others => '0'),--: in std_logic_vector(127 downto 0);
cfg_aer_interrupt_msgnum                   => "00000",--: in std_logic_vector(4 downto 0);
cfg_err_aer_headerlog_set                  => open,--: out std_logic;
cfg_aer_ecrc_check_en                      => open,--: out std_logic;
cfg_aer_ecrc_gen_en                        => open,--: out std_logic;
-------------------------------------------------------------------------------------------------------------------
-- 7. VC interface                                                                                               --
-------------------------------------------------------------------------------------------------------------------
cfg_vc_tcvc_map                            => open,--: out std_logic_vector(6 downto 0);


PIPE_MMCM_RST_N                            => PIPE_MMCM_RST_N,--: in std_logic;   --     // Async      | Async

sys_rst_n                                  => p_in_pciexp_rst --: in std_logic
);


--#############################################
--
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

--CTRL user devices
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
trn_rfc_nph_av_i          => (others => '0'),--trn_rfc_nph_av,
trn_rfc_npd_av_i          => (others => '0'),--trn_rfc_npd_av,
trn_rfc_ph_av_i           => (others => '0'),--trn_rfc_ph_av,
trn_rfc_pd_av_i           => (others => '0'),--trn_rfc_pd_av,
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


process(trn_clk)
begin
  if rising_edge(trn_clk) then
   if (user_reset = '1') then
     trn_reset  <= '1' after TCQ;
     trn_lnk_up <= '0' after TCQ;
   else
     trn_reset  <= user_reset after TCQ;
     trn_lnk_up <= user_lnk_up after TCQ;
   end if;
  end if;
end process;

p_out_gtp_refclkout <= '0';
user_trn_tbuf_av <= (others => '1') when trn_tbuf_av /= (trn_tbuf_av'range => '0') else (others => '0');

trn_fc_sel                <= "000";
trn_tstr_n                <= trn_rcpl_streaming_n;

pl_directed_link_change   <= "00";
pl_directed_link_width    <= "00";
pl_directed_link_speed    <= '0';
pl_directed_link_auton    <= '0';
pl_upstream_prefer_deemph <= '1';

--------------------------------------
--convert to axi
--------------------------------------
trn_reset_n <= not trn_reset;
trn_lnk_up_n <= not trn_lnk_up;

trn_rnp_ok <= not trn_rnp_ok_n;
trn_tcfg_gnt <= not trn_tcfg_gnt_n;

gen_cfg_byte_en : for i in 0 to cfg_byte_en_n'length - 1 generate
cfg_byte_en(i) <= not cfg_byte_en_n(i);
end generate gen_cfg_byte_en;
cfg_wr_en        <= not cfg_wr_en_n;
cfg_rd_en        <= not cfg_rd_en_n;
cfg_rd_wr_done_n <= not cfg_rd_wr_done;

cfg_to_turnoff_n   <= not cfg_to_turnoff;
cfg_err_cpl_rdy_n  <= not cfg_err_cpl_rdy;

cfg_pcie_link_state_n <= cfg_pcie_link_state;

cfg_turnoff_ok  <= not cfg_turnoff_ok_n;
cfg_pm_wake     <= not cfg_pm_wake_n;
cfg_trn_pending <= not cfg_trn_pending_n;

cfg_err_locked       <= not cfg_err_locked_n;
cfg_err_posted       <= not cfg_err_posted_n;
cfg_err_cpl_unexpect <= not cfg_err_cpl_unexpect_n;
cfg_err_cpl_abort    <= not cfg_err_cpl_abort_n;
cfg_err_cpl_timeout  <= not cfg_err_cpl_timeout_n;
cfg_err_ecrc         <= not cfg_err_ecrc_n;
cfg_err_ur           <= not cfg_err_ur_n;
cfg_err_cor          <= not cfg_err_cor_n;

cfg_interrupt        <= not cfg_interrupt_n;
cfg_interrupt_rdy_n  <= not cfg_interrupt_rdy;
cfg_interrupt_assert <= not cfg_interrupt_assert_n;

--Tx
trn_tcfg_req_n     <= not trn_tcfg_req;
trn_terr_drop_n    <= not trn_terr_drop;

trn_tdst_rdy_n    <=not s_axis_tx_tready;
s_axis_tx_tlast   <=not trn_teof_n;
s_axis_tx_tvalid  <=not trn_tsrc_rdy_n;
s_axis_tx_tuser(3)<=not trn_tsrc_dsc_n;
s_axis_tx_tuser(2)<=not trn_tstr_n;
s_axis_tx_tuser(1)<=not trn_terrfwd_n;
s_axis_tx_tuser(0)<='0';

s_axis_tx_tkeep <= std_logic_vector(TO_UNSIGNED(16#0FFF#, s_axis_tx_tkeep'length))
                    when trn_teof_n = '0' and UNSIGNED(trn_trem_n) = TO_UNSIGNED(16#01#, trn_trem_n'length) else
                      std_logic_vector(TO_UNSIGNED(16#00FF#, s_axis_tx_tkeep'length))
                        when trn_teof_n = '0' and UNSIGNED(trn_trem_n) = TO_UNSIGNED(16#02#, trn_trem_n'length) else
                          std_logic_vector(TO_UNSIGNED(16#000F#, s_axis_tx_tkeep'length))
                            when trn_teof_n = '0' and UNSIGNED(trn_trem_n) = TO_UNSIGNED(16#03#, trn_trem_n'length) else
                              std_logic_vector(TO_UNSIGNED(16#FFFF#, s_axis_tx_tkeep'length));

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

trn_rrem_n <= std_logic_vector(TO_UNSIGNED(16#01#, trn_rrem_n'length)) when m_axis_rx_tvalid = '1' and is_eof = "11011" else
              std_logic_vector(TO_UNSIGNED(16#02#, trn_rrem_n'length)) when m_axis_rx_tvalid = '1' and is_eof = "10111" else
              std_logic_vector(TO_UNSIGNED(16#03#, trn_rrem_n'length)) when m_axis_rx_tvalid = '1' and is_eof = "10011" else
              std_logic_vector(TO_UNSIGNED(16#00#, trn_rrem_n'length)) when m_axis_rx_tvalid = '1' and is_eof = "11111" else

              std_logic_vector(TO_UNSIGNED(16#00#, trn_rrem_n'length)) when m_axis_rx_tvalid = '1' and is_sof = "10000" else
              std_logic_vector(TO_UNSIGNED(16#02#, trn_rrem_n'length)) when m_axis_rx_tvalid = '1' and is_sof = "11000" else
              std_logic_vector(TO_UNSIGNED(16#00#, trn_rrem_n'length));

gen_trn_d : for i in 0 to CI_PCIEXP_TRN_DBUS/32 - 1 generate
trn_rd((trn_rd'length - 32*i) - 1 downto (trn_rd'length - 32*(i+1))) <= m_axis_rx_tdata(32*(i+1) - 1 downto 32*i);
s_axis_tx_tdata(32*(i+1) - 1 downto 32*i) <= trn_td((trn_td'length - 32*i) - 1 downto (trn_td'length - 32*(i+1)));
end generate gen_trn_d;

is_sof(4 downto 0)<=m_axis_rx_tuser(14 downto 10);
is_eof(4 downto 0)<=m_axis_rx_tuser(21 downto 17);


end architecture behavioral;
