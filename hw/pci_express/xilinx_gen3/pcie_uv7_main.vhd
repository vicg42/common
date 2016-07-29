-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.07.2015 10:07:56
-- Module Name : pcie_main.vhd
--
-- Description :
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.pcie_pkg.all;
use work.prj_def.all;
use work.prj_cfg.all;
use work.vicg_common_pkg.all;

entity pcie_main is
generic (
G_SIM : string := "OFF";
G_DBGCS : string := "OFF"
);
port (
--------------------------------------------------------
--USR Port
--------------------------------------------------------
p_out_hclk           : out   std_logic ;
p_out_gctrl          : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

p_out_dev_ctrl       : out   TDevCtrl;
p_out_dev_di         : out   std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_in_dev_do          : in    std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_out_dev_wr         : out   std_logic;
p_out_dev_rd         : out   std_logic;
p_in_dev_status      : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto C_HREG_DEV_STATUS_FST_BIT);
p_in_dev_irq         : in    std_logic_vector((C_HIRQ_COUNT - 1) downto C_HIRQ_FST_BIT);
p_in_dev_opt         : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto C_HDEV_OPTIN_FST_BIT);
p_out_dev_opt        : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto C_HDEV_OPTOUT_FST_BIT);

--------------------------------------------------------
--DBG
--------------------------------------------------------
p_out_usr_tst        : out   std_logic_vector(127 downto 0);
p_in_usr_tst         : in    std_logic_vector(127 downto 0);
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(255 downto 0);
p_out_dbg            : out   TPCIE_dbg;

---------------------------------------------------------
--System Port
---------------------------------------------------------
p_in_pcie_phy        : in    TPCIE_pinin;
p_out_pcie_phy       : out   TPCIE_pinout;
p_out_pcie_rst_n     : out   std_logic
);
end entity pcie_main;

architecture behavioral of pcie_main is

constant CI_DATA_WIDTH                     : integer := C_PCFG_PCIE_DWIDTH;

--constant CI_AXISTEN_IF_WIDTH               : std_logic_vector(1 downto 0) := "00";
--constant CI_AXISTEN_IF_RQ_ALIGNMENT_MODE   : string := "FALSE";
--constant CI_AXISTEN_IF_CC_ALIGNMENT_MODE   : string := "FALSE";
--constant CI_AXISTEN_IF_CQ_ALIGNMENT_MODE   : string := "FALSE";
--constant CI_AXISTEN_IF_RC_ALIGNMENT_MODE   : string := "FALSE";
--constant CI_AXISTEN_IF_ENABLE_CLIENT_TAG   : integer := 0;
--constant CI_AXISTEN_IF_RQ_PARITY_CHECK     : integer := 0;
--constant CI_AXISTEN_IF_CC_PARITY_CHECK     : integer := 0;
--constant CI_AXISTEN_IF_MC_RX_STRADDLE      : integer := 0;
--constant CI_AXISTEN_IF_ENABLE_RX_MSG_INTFC : integer := 0;
--constant CI_AXISTEN_IF_ENABLE_MSG_ROUTE    : std_logic_vector(17 downto 0) := std_logic_vector(TO_UNSIGNED(16#2FFFF#, 18));


component pcie3_core
PORT (
pci_exp_txn : OUT STD_LOGIC_VECTOR(C_PCFG_PCIE_LINK_WIDTH - 1 DOWNTO 0);
pci_exp_txp : OUT STD_LOGIC_VECTOR(C_PCFG_PCIE_LINK_WIDTH - 1 DOWNTO 0);
pci_exp_rxn : IN STD_LOGIC_VECTOR(C_PCFG_PCIE_LINK_WIDTH - 1 DOWNTO 0);
pci_exp_rxp : IN STD_LOGIC_VECTOR(C_PCFG_PCIE_LINK_WIDTH - 1 DOWNTO 0);
user_clk : OUT STD_LOGIC;
user_reset : OUT STD_LOGIC;
user_lnk_up : OUT STD_LOGIC;
s_axis_rq_tdata : IN STD_LOGIC_VECTOR(CI_DATA_WIDTH - 1 DOWNTO 0);
s_axis_rq_tkeep : IN STD_LOGIC_VECTOR((CI_DATA_WIDTH / 32) - 1 DOWNTO 0);
s_axis_rq_tlast : IN STD_LOGIC;
s_axis_rq_tready : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
s_axis_rq_tuser : IN STD_LOGIC_VECTOR(59 DOWNTO 0);
s_axis_rq_tvalid : IN STD_LOGIC;
m_axis_rc_tdata : OUT STD_LOGIC_VECTOR(CI_DATA_WIDTH - 1 DOWNTO 0);
m_axis_rc_tkeep : OUT STD_LOGIC_VECTOR((CI_DATA_WIDTH / 32) - 1 DOWNTO 0);
m_axis_rc_tlast : OUT STD_LOGIC;
m_axis_rc_tready : IN STD_LOGIC;
m_axis_rc_tuser : OUT STD_LOGIC_VECTOR(74 DOWNTO 0);
m_axis_rc_tvalid : OUT STD_LOGIC;
m_axis_cq_tdata : OUT STD_LOGIC_VECTOR(CI_DATA_WIDTH - 1 DOWNTO 0);
m_axis_cq_tkeep : OUT STD_LOGIC_VECTOR((CI_DATA_WIDTH / 32) - 1 DOWNTO 0);
m_axis_cq_tlast : OUT STD_LOGIC;
m_axis_cq_tready : IN STD_LOGIC;
m_axis_cq_tuser : OUT STD_LOGIC_VECTOR(84 DOWNTO 0);
m_axis_cq_tvalid : OUT STD_LOGIC;
s_axis_cc_tdata : IN STD_LOGIC_VECTOR(CI_DATA_WIDTH - 1 DOWNTO 0);
s_axis_cc_tkeep : IN STD_LOGIC_VECTOR((CI_DATA_WIDTH / 32) - 1 DOWNTO 0);
s_axis_cc_tlast : IN STD_LOGIC;
s_axis_cc_tready : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
s_axis_cc_tuser : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
s_axis_cc_tvalid : IN STD_LOGIC;
pcie_rq_seq_num : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
pcie_rq_seq_num_vld : OUT STD_LOGIC;
pcie_rq_tag : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
pcie_rq_tag_av : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
pcie_rq_tag_vld : OUT STD_LOGIC;
pcie_tfc_nph_av : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
pcie_tfc_npd_av : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
pcie_cq_np_req : IN STD_LOGIC;
pcie_cq_np_req_count : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
cfg_phy_link_down : OUT STD_LOGIC;
cfg_phy_link_status : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
cfg_negotiated_width : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_current_speed : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_max_payload : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_max_read_req : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_function_status : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
cfg_function_power_state : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_vf_status : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
cfg_vf_power_state : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
cfg_link_power_state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
cfg_mgmt_addr : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
cfg_mgmt_write : IN STD_LOGIC;
cfg_mgmt_write_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_mgmt_byte_enable : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_mgmt_read : IN STD_LOGIC;
cfg_mgmt_read_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_mgmt_read_write_done : OUT STD_LOGIC;
cfg_mgmt_type1_cfg_reg_access : IN STD_LOGIC;
cfg_err_cor_out : OUT STD_LOGIC;
cfg_err_nonfatal_out : OUT STD_LOGIC;
cfg_err_fatal_out : OUT STD_LOGIC;
cfg_local_error : OUT STD_LOGIC;
cfg_ltr_enable : OUT STD_LOGIC;
cfg_ltssm_state : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
cfg_rcb_status : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_dpa_substate_change : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_obff_enable : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
cfg_pl_status_change : OUT STD_LOGIC;
cfg_tph_requester_enable : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_tph_st_mode : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_vf_tph_requester_enable : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_vf_tph_st_mode : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
cfg_msg_received : OUT STD_LOGIC;
cfg_msg_received_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_msg_received_type : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
cfg_msg_transmit : IN STD_LOGIC;
cfg_msg_transmit_type : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_msg_transmit_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_msg_transmit_done : OUT STD_LOGIC;
cfg_fc_ph : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_fc_pd : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_fc_nph : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_fc_npd : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_fc_cplh : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_fc_cpld : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_fc_sel : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_per_func_status_control : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_per_func_status_data : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
cfg_per_function_number : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_per_function_output_request : IN STD_LOGIC;
cfg_per_function_update_done : OUT STD_LOGIC;
cfg_dsn : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
cfg_power_state_change_ack : IN STD_LOGIC;
cfg_power_state_change_interrupt : OUT STD_LOGIC;
cfg_err_cor_in : IN STD_LOGIC;
cfg_err_uncor_in : IN STD_LOGIC;
cfg_flr_in_process : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_flr_done : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_vf_flr_in_process : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_vf_flr_done : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_link_training_enable : IN STD_LOGIC;
cfg_ext_read_received : OUT STD_LOGIC;
cfg_ext_write_received : OUT STD_LOGIC;
cfg_ext_register_number : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
cfg_ext_function_number : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_ext_write_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_ext_write_byte_enable : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_ext_read_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_ext_read_data_valid : IN STD_LOGIC;
cfg_interrupt_int : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_interrupt_pending : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_interrupt_sent : OUT STD_LOGIC;
cfg_interrupt_msi_enable : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_interrupt_msi_vf_enable : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_interrupt_msi_mmenable : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_interrupt_msi_mask_update : OUT STD_LOGIC;
cfg_interrupt_msi_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_interrupt_msi_select : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_interrupt_msi_int : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_interrupt_msi_pending_status : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_interrupt_msi_pending_status_data_enable : IN STD_LOGIC;
cfg_interrupt_msi_pending_status_function_num : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_interrupt_msi_sent : OUT STD_LOGIC;
cfg_interrupt_msi_fail : OUT STD_LOGIC;
cfg_interrupt_msi_attr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_interrupt_msi_tph_present : IN STD_LOGIC;
cfg_interrupt_msi_tph_type : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
cfg_interrupt_msi_tph_st_tag : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
cfg_interrupt_msi_function_number : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_hot_reset_out : OUT STD_LOGIC;
cfg_config_space_enable : IN STD_LOGIC;
cfg_req_pm_transition_l23_ready : IN STD_LOGIC;
cfg_hot_reset_in : IN STD_LOGIC;
cfg_ds_port_number : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_ds_bus_number : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_ds_device_number : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
cfg_ds_function_number : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_subsys_vend_id : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
sys_clk : IN STD_LOGIC;
sys_clk_gt : IN STD_LOGIC;
sys_reset : IN STD_LOGIC;

----Tandem
--mcap_design_switch : OUT STD_LOGIC;
--startup_cfgclk : OUT STD_LOGIC;
--startup_cfgmclk : OUT STD_LOGIC;
--startup_di : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--startup_eos : OUT STD_LOGIC;
--startup_preq : OUT STD_LOGIC;
--startup_do : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--startup_dts : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--startup_fcsbo : IN STD_LOGIC;
--startup_fcsbts : IN STD_LOGIC;
--startup_gsr : IN STD_LOGIC;
--startup_gts : IN STD_LOGIC;
--startup_keyclearb : IN STD_LOGIC;
--startup_pack : IN STD_LOGIC;
--startup_usrcclko : IN STD_LOGIC;
--startup_usrcclkts : IN STD_LOGIC;
--startup_usrdoneo : IN STD_LOGIC;
--startup_usrdonets : IN STD_LOGIC;
--cap_req : OUT STD_LOGIC;
--cap_gnt : IN STD_LOGIC;
--cap_rel : IN STD_LOGIC;

pcie_perstn1_in : IN STD_LOGIC;
pcie_perstn0_out : OUT STD_LOGIC;
pcie_perstn1_out : OUT STD_LOGIC;

--for PCIEx4 (GEN3); PCIEx2 (GEN3)
int_qpll1lock_out      : OUT STD_LOGIC_VECTOR(selval(1, 0, (CI_DATA_WIDTH = 256)) DOWNTO 0);
int_qpll1outrefclk_out : OUT STD_LOGIC_VECTOR(selval(1, 0, (CI_DATA_WIDTH = 256)) DOWNTO 0);
int_qpll1outclk_out    : OUT STD_LOGIC_VECTOR(selval(1, 0, (CI_DATA_WIDTH = 256)) DOWNTO 0)

----for PCIEx8 (GEN3)
--int_qpll1lock_out      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--int_qpll1outrefclk_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--int_qpll1outclk_out    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)

----for PCIEx4 (GEN3); PCIEx2 (GEN3)
--int_qpll1lock_out      : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
--int_qpll1outrefclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
--int_qpll1outclk_out    : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
);
END component pcie3_core;


component pcie_ctrl
generic(
G_SIM : string := "OFF";
G_DBGCS : string := "OFF";
G_DATA_WIDTH : integer := 64
);
port (
--------------------------------------
--USR Port
--------------------------------------
p_out_hclk      : out   std_logic;
p_out_gctrl     : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--CTRL user devices
p_out_dev_ctrl  : out   TDevCtrl;
p_out_dev_di    : out   std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_in_dev_do   : in    std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_out_dev_wr    : out   std_logic;
p_out_dev_rd    : out   std_logic;
p_in_dev_status : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto C_HREG_DEV_STATUS_FST_BIT);
p_in_dev_irq    : in    std_logic_vector((C_HIRQ_COUNT - 1) downto C_HIRQ_FST_BIT);
p_in_dev_opt    : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto C_HDEV_OPTIN_FST_BIT);
p_out_dev_opt   : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto C_HDEV_OPTOUT_FST_BIT);

--DBG
p_out_dbg       : out   TPCIE_dbg;
p_out_tst       : out   std_logic_vector(127 downto 0);
p_in_tst        : in    std_logic_vector(127 downto 0);

------------------------------------
--AXI Interface
------------------------------------
p_out_axi_rq_tlast  : out  std_logic                                  ;
p_out_axi_rq_tdata  : out  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_axi_rq_tuser  : out  std_logic_vector(59 downto 0)              ;
p_out_axi_rq_tkeep  : out  std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_in_axi_rq_tready  : in   std_logic_vector(3 downto 0)               ;
p_out_axi_rq_tvalid : out  std_logic                                  ;

p_in_axi_rc_tdata   : in   std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_in_axi_rc_tuser   : in   std_logic_vector(74 downto 0)              ;
p_in_axi_rc_tlast   : in   std_logic                                  ;
p_in_axi_rc_tkeep   : in   std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_in_axi_rc_tvalid  : in   std_logic                                  ;
p_out_axi_rc_tready : out  std_logic_vector(21 downto 0)              ;

p_in_axi_cq_tdata   : in   std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_in_axi_cq_tuser   : in   std_logic_vector(84 downto 0)              ;
p_in_axi_cq_tlast   : in   std_logic                                  ;
p_in_axi_cq_tkeep   : in   std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_in_axi_cq_tvalid  : in   std_logic                                  ;
p_out_axi_cq_tready : out  std_logic_vector(21 downto 0)              ;

p_out_axi_cc_tdata  : out  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_axi_cc_tuser  : out  std_logic_vector(32 downto 0)              ;
p_out_axi_cc_tlast  : out  std_logic                                  ;
p_out_axi_cc_tkeep  : out  std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_out_axi_cc_tvalid : out  std_logic                                  ;
p_in_axi_cc_tready  : in   std_logic_vector(3 downto 0)               ;

p_in_pcie_tfc_nph_av  : in   std_logic_vector(1 downto 0)                ;
p_in_pcie_tfc_npd_av  : in   std_logic_vector(1 downto 0)                ;

------------------------------------
--Configuration (CFG) Interface
------------------------------------
p_in_pcie_rq_seq_num      : in   std_logic_vector(3 downto 0);
p_in_pcie_rq_seq_num_vld  : in   std_logic                   ;
p_in_pcie_rq_tag          : in   std_logic_vector(5 downto 0);
p_in_pcie_rq_tag_vld      : in   std_logic                   ;
p_out_pcie_cq_np_req      : out  std_logic                   ;
p_in_pcie_cq_np_req_count : in   std_logic_vector(5 downto 0);
p_in_pcie_tfc_np_pl_empty : in   std_logic                   ;
--p_in_pcie_rq_tag_av       : in   std_logic_vector(1 downto 0);

------------------------------------
--Management Interface
------------------------------------
p_in_cfg_msg_received         : in  std_logic;
p_in_cfg_msg_received_data    : in  std_logic_vector(7 downto 0);
p_in_cfg_msg_received_type    : in  std_logic_vector(4 downto 0);
p_out_cfg_msg_transmit        : out std_logic;
p_out_cfg_msg_transmit_type   : out std_logic_vector(2 downto 0);
p_out_cfg_msg_transmit_data   : out std_logic_vector(31 downto 0);
p_in_cfg_msg_transmit_done    : in  std_logic;

------------------------------------
-- EP and RP
------------------------------------
p_in_cfg_phy_link_status  : in   std_logic_vector(1 downto 0);
p_in_cfg_negotiated_width : in   std_logic_vector(3 downto 0);
p_in_cfg_current_speed    : in   std_logic_vector(2 downto 0);
p_in_cfg_max_payload      : in   std_logic_vector(2 downto 0);
p_in_cfg_max_read_req     : in   std_logic_vector(2 downto 0);
p_in_cfg_function_status  : in   std_logic_vector(7 downto 0);
p_in_cfg_rcb_status       : in   std_logic_vector(1 downto 0);

-- Error Reporting Interface
p_in_cfg_err_cor_out      : in   std_logic;
p_in_cfg_err_nonfatal_out : in   std_logic;
p_in_cfg_err_fatal_out    : in   std_logic;

p_in_cfg_fc_ph            : in   std_logic_vector( 7 downto 0);
p_in_cfg_fc_pd            : in   std_logic_vector(11 downto 0);
p_in_cfg_fc_nph           : in   std_logic_vector( 7 downto 0);
p_in_cfg_fc_npd           : in   std_logic_vector(11 downto 0);
p_in_cfg_fc_cplh          : in   std_logic_vector( 7 downto 0);
p_in_cfg_fc_cpld          : in   std_logic_vector(11 downto 0);
p_out_cfg_fc_sel          : out  std_logic_vector( 2 downto 0);

p_out_cfg_dsn                         : out  std_logic_vector(63 downto 0);
p_out_cfg_power_state_change_ack      : out  std_logic;
p_in_cfg_power_state_change_interrupt : in   std_logic;
p_out_cfg_err_cor_in                  : out  std_logic;
p_out_cfg_err_uncor_in                : out  std_logic;

p_in_cfg_flr_in_process       : in   std_logic_vector(3 downto 0);
p_out_cfg_flr_done            : out  std_logic_vector(3 downto 0);
p_in_cfg_vf_flr_in_process    : in   std_logic_vector(7 downto 0);
p_out_cfg_vf_flr_done         : out  std_logic_vector(7 downto 0);

p_out_cfg_ds_port_number      : out  std_logic_vector(7 downto 0);
p_out_cfg_ds_bus_number       : out  std_logic_vector(7 downto 0);
p_out_cfg_ds_device_number    : out  std_logic_vector(4 downto 0);
p_out_cfg_ds_function_number  : out  std_logic_vector(2 downto 0);

------------------------------------
-- EP Only
------------------------------------
-- Interrupt Interface Signals
p_out_cfg_interrupt_int                 : out  std_logic_vector(3 downto 0) ;
p_out_cfg_interrupt_pending             : out  std_logic_vector(3 downto 0) ;
p_in_cfg_interrupt_sent                 : in   std_logic                    ;

p_in_cfg_interrupt_msi_enable           : in   std_logic_vector(1 downto 0) ;
p_in_cfg_interrupt_msi_vf_enable        : in   std_logic_vector(5 downto 0) ;
p_in_cfg_interrupt_msi_mmenable         : in   std_logic_vector(5 downto 0) ;
p_in_cfg_interrupt_msi_mask_update      : in   std_logic                    ;
p_in_cfg_interrupt_msi_data             : in   std_logic_vector(31 downto 0);
p_out_cfg_interrupt_msi_select          : out  std_logic_vector( 3 downto 0);
p_out_cfg_interrupt_msi_int             : out  std_logic_vector(31 downto 0);
p_out_cfg_interrupt_msi_pending_status  : out  std_logic_vector(31 downto 0);
p_in_cfg_interrupt_msi_sent             : in   std_logic                    ;
p_in_cfg_interrupt_msi_fail             : in   std_logic                    ;
p_out_cfg_interrupt_msi_attr            : out  std_logic_vector(2 downto 0) ;
p_out_cfg_interrupt_msi_tph_present     : out  std_logic                    ;
p_out_cfg_interrupt_msi_tph_type        : out  std_logic_vector(1 downto 0) ;
p_out_cfg_interrupt_msi_tph_st_tag      : out  std_logic_vector(8 downto 0) ;
p_out_cfg_interrupt_msi_function_number : out  std_logic_vector(3 downto 0) ;
p_out_cfg_interrupt_msi_pending_status_data_enable  : out  std_logic;
p_out_cfg_interrupt_msi_pending_status_function_num : out  std_logic_vector(3 downto 0);

p_in_cfg_interrupt_msix_enable          : in  std_logic;
p_in_cfg_interrupt_msix_sent            : in  std_logic;
p_in_cfg_interrupt_msix_fail            : in  std_logic;
p_out_cfg_interrupt_msix_int            : out std_logic;
p_out_cfg_interrupt_msix_address        : out std_logic_vector(63 downto 0);
p_out_cfg_interrupt_msix_data           : out std_logic_vector(31 downto 0);

-- EP only
p_in_cfg_hot_reset_in   : in   std_logic;

-- RP only
p_out_cfg_hot_reset_out : out  std_logic;

p_in_user_clk           : in   std_logic;
p_in_user_reset         : in   std_logic;
p_in_user_lnk_up        : in   std_logic
);
end component pcie_ctrl;



signal i_pciecore_hot_reset_out : std_logic;

signal i_sys_rst_n        : std_logic;
signal i_sys_clk          : std_logic;
signal i_sys_clk_gt       : std_logic;

signal i_user_clk         : std_logic;
signal i_user_reset       : std_logic;
signal i_user_lnk_up      : std_logic;

signal i_axi_rq_tlast     : std_logic                                   ;
signal i_axi_rq_tdata     : std_logic_vector(CI_DATA_WIDTH - 1 downto 0);
signal i_axi_rq_tuser     : std_logic_vector(59 downto 0)               ;
signal i_axi_rq_tkeep     : std_logic_vector((CI_DATA_WIDTH / 32) - 1 downto 0);
signal i_axi_rq_tready    : std_logic_vector(3 downto 0)                ;
signal i_axi_rq_tvalid    : std_logic                                   ;

signal i_axi_rc_tdata     : std_logic_vector(CI_DATA_WIDTH - 1 downto 0);
signal i_axi_rc_tuser     : std_logic_vector(74 downto 0)               ;
signal i_axi_rc_tlast     : std_logic                                   ;
signal i_axi_rc_tkeep     : std_logic_vector((CI_DATA_WIDTH / 32) - 1 downto 0);
signal i_axi_rc_tvalid    : std_logic                                   ;
signal i_axi_rc_tready    : std_logic_vector(21 downto 0)               ;

signal i_axi_cq_tdata     : std_logic_vector(CI_DATA_WIDTH - 1 downto 0);
signal i_axi_cq_tuser     : std_logic_vector(84 downto 0)               ;
signal i_axi_cq_tlast     : std_logic                                   ;
signal i_axi_cq_tkeep     : std_logic_vector((CI_DATA_WIDTH / 32) - 1 downto 0);
signal i_axi_cq_tvalid    : std_logic                                   ;
signal i_axi_cq_tready    : std_logic_vector(21 downto 0)               ;

signal i_axi_cc_tdata     : std_logic_vector(CI_DATA_WIDTH - 1 downto 0);
signal i_axi_cc_tuser     : std_logic_vector(32 downto 0)               ;
signal i_axi_cc_tlast     : std_logic                                   ;
signal i_axi_cc_tkeep     : std_logic_vector((CI_DATA_WIDTH / 32) - 1 downto 0);
signal i_axi_cc_tvalid    : std_logic                                   ;
signal i_axi_cc_tready    : std_logic_vector(3 downto 0)                ;

signal i_cfg_ds_port_number     : std_logic_vector(7 downto 0);
signal i_cfg_ds_bus_number      : std_logic_vector(7 downto 0);
signal i_cfg_ds_device_number   : std_logic_vector(4 downto 0);
signal i_cfg_ds_function_number : std_logic_vector(2 downto 0);
signal i_cfg_subsys_vend_id     : std_logic_vector(15 downto 0);

signal i_cfg_fc_ph              : std_logic_vector(7 downto 0);
signal i_cfg_fc_pd              : std_logic_vector(11 downto 0);
signal i_cfg_fc_nph             : std_logic_vector(7 downto 0);
signal i_cfg_fc_npd             : std_logic_vector(11 downto 0);
signal i_cfg_fc_cplh            : std_logic_vector(7 downto 0);
signal i_cfg_fc_cpld            : std_logic_vector(11 downto 0);
signal i_cfg_fc_sel             : std_logic_vector(2 downto 0);

signal i_pcie_rq_seq_num        : std_logic_vector(3 downto 0);
signal i_pcie_rq_seq_num_vld    : std_logic;
signal i_pcie_rq_tag            : std_logic_vector(5 downto 0);
--signal i_pcie_rq_tag_av         : std_logic_vector(1 downto 0);
signal i_pcie_rq_tag_vld        : std_logic;
signal i_pcie_tfc_nph_av        : std_logic_vector(1 downto 0);
signal i_pcie_tfc_npd_av        : std_logic_vector(1 downto 0);
signal i_pcie_cq_np_req         : std_logic;
signal i_pcie_cq_np_req_count   : std_logic_vector(5 downto 0);

signal i_cfg_err_cor_out        : std_logic;
signal i_cfg_err_nonfatal_out   : std_logic;
signal i_cfg_err_fatal_out      : std_logic;
signal i_cfg_obff_enable        : std_logic_vector(1 downto 0);

signal i_cfg_err_cor_in         : std_logic;
signal i_cfg_err_uncor_in       : std_logic;

signal i_cfg_dsn                          : std_logic_vector(63 downto 0) ;
signal i_cfg_power_state_change_ack       : std_logic;
signal i_cfg_power_state_change_interrupt : std_logic;

signal i_cfg_interrupt_int                : std_logic_vector(3 downto 0);
signal i_cfg_interrupt_pending            : std_logic_vector(3 downto 0);
signal i_cfg_interrupt_sent               : std_logic;
signal i_cfg_interrupt_msi_enable         : std_logic_vector(3 downto 0);
signal i_cfg_interrupt_msi_vf_enable      : std_logic_vector(7 downto 0);
signal i_cfg_interrupt_msi_mmenable       : std_logic_vector(11 downto 0);
signal i_cfg_interrupt_msi_mask_update    : std_logic;
signal i_cfg_interrupt_msi_data           : std_logic_vector(31 downto 0);
signal i_cfg_interrupt_msi_select         : std_logic_vector(3 downto 0);
signal i_cfg_interrupt_msi_int            : std_logic_vector(31 downto 0);
signal i_cfg_interrupt_msi_pending_status             : std_logic_vector(31 downto 0);
signal i_cfg_interrupt_msi_pending_status_data_enable : std_logic;
signal i_cfg_interrupt_msi_pending_status_function_num: std_logic_vector(3 downto 0);
signal i_cfg_interrupt_msi_sent           : std_logic;
signal i_cfg_interrupt_msi_fail           : std_logic;
signal i_cfg_interrupt_msi_attr           : std_logic_vector(2 downto 0);
signal i_cfg_interrupt_msi_tph_present    : std_logic;
signal i_cfg_interrupt_msi_tph_type       : std_logic_vector(1 downto 0);
signal i_cfg_interrupt_msi_tph_st_tag     : std_logic_vector(8 downto 0);
signal i_cfg_interrupt_msi_function_number: std_logic_vector(3 downto 0);

signal i_cfg_hot_reset_out                : std_logic;
--signal i_cfg_config_space_enable          : std_logic;
--signal i_cfg_req_pm_transition_l23_ready  : std_logic;
signal i_cfg_hot_reset_in                 : std_logic;

--signal i_cfg_phy_link_down                : std_logic;
signal i_cfg_phy_link_status              : std_logic_vector(1 downto 0);
signal i_cfg_negotiated_width             : std_logic_vector(3 downto 0) := (others => '0');
signal i_cfg_current_speed                : std_logic_vector(2 downto 0);
signal i_cfg_max_payload                  : std_logic_vector(2 downto 0) := (others => '0');
signal i_cfg_max_read_req                 : std_logic_vector(2 downto 0) := (others => '0');
signal i_cfg_function_status              : std_logic_vector(15 downto 0):= (others => '0');
signal i_cfg_rcb_status                   : std_logic_vector(3 downto 0);
--signal i_cfg_function_power_state         : std_logic_vector(11 downto 0);
--signal i_cfg_vf_status                    : std_logic_vector(15 downto 0);
--signal i_cfg_vf_power_state               : std_logic_vector(23 downto 0);
--signal i_cfg_link_power_state             : std_logic_vector(1 downto 0);

signal i_cfg_msg_received                 : std_logic                    := '0';
signal i_cfg_msg_received_data            : std_logic_vector(7 downto 0) := (others => '0');
signal i_cfg_msg_received_type            : std_logic_vector(4 downto 0) := (others => '0');
signal i_cfg_msg_transmit                 : std_logic                    := '0';
signal i_cfg_msg_transmit_type            : std_logic_vector(2 downto 0) := (others => '0');
signal i_cfg_msg_transmit_data            : std_logic_vector(31 downto 0):= (others => '0');
signal i_cfg_msg_transmit_done            : std_logic                    := '0';

signal i_cfg_flr_in_process               : std_logic_vector(3 downto 0) := (others => '0');
signal i_cfg_flr_done                     : std_logic_vector(3 downto 0) := (others => '0');
signal i_cfg_vf_flr_in_process            : std_logic_vector(7 downto 0) := (others => '0');
signal i_cfg_vf_flr_done                  : std_logic_vector(7 downto 0) := (others => '0');

--signal i_cfg_link_training_enable         : std_logic;


begin --architecture behavioral

m_refclk_ibuf : IBUFDS_GTE3
port map (
I     => p_in_pcie_phy.clk_p,
IB    => p_in_pcie_phy.clk_n,
ODIV2 => i_sys_clk,
CEB   => '0',
O     => i_sys_clk_gt
);

m_sys_rst_ibuf : IBUF port map(I => p_in_pcie_phy.rst_n, O => i_sys_rst_n);

i_cfg_subsys_vend_id <= std_logic_vector(TO_UNSIGNED(0, i_cfg_subsys_vend_id'length));

m_core : pcie3_core
port map(
pci_exp_txn => p_out_pcie_phy.txn,--: OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
pci_exp_txp => p_out_pcie_phy.txp,--: OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
pci_exp_rxn => p_in_pcie_phy.rxn ,--: IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
pci_exp_rxp => p_in_pcie_phy.rxp ,--: IN  STD_LOGIC_VECTOR(0 DOWNTO 0);

user_clk         => i_user_clk   ,--: OUT STD_LOGIC;
user_reset       => i_user_reset ,--: OUT STD_LOGIC;
user_lnk_up      => i_user_lnk_up,--: OUT STD_LOGIC;

s_axis_rq_tdata  => i_axi_rq_tdata ,--: IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
s_axis_rq_tkeep  => i_axi_rq_tkeep ,--: IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
s_axis_rq_tlast  => i_axi_rq_tlast ,--: IN  STD_LOGIC;
s_axis_rq_tready => i_axi_rq_tready,--: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
s_axis_rq_tuser  => i_axi_rq_tuser ,--: IN  STD_LOGIC_VECTOR(59 DOWNTO 0);
s_axis_rq_tvalid => i_axi_rq_tvalid,--: IN  STD_LOGIC;

m_axis_rc_tdata  => i_axi_rc_tdata    ,--: OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
m_axis_rc_tkeep  => i_axi_rc_tkeep    ,--: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
m_axis_rc_tlast  => i_axi_rc_tlast    ,--: OUT STD_LOGIC;
m_axis_rc_tready => i_axi_rc_tready(0),--: IN  STD_LOGIC;
m_axis_rc_tuser  => i_axi_rc_tuser    ,--: OUT STD_LOGIC_VECTOR(74 DOWNTO 0);
m_axis_rc_tvalid => i_axi_rc_tvalid   ,--: OUT STD_LOGIC;

m_axis_cq_tdata  => i_axi_cq_tdata    ,--: OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
m_axis_cq_tkeep  => i_axi_cq_tkeep    ,--: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
m_axis_cq_tlast  => i_axi_cq_tlast    ,--: OUT STD_LOGIC;
m_axis_cq_tready => i_axi_cq_tready(0),--: IN  STD_LOGIC;
m_axis_cq_tuser  => i_axi_cq_tuser    ,--: OUT STD_LOGIC_VECTOR(84 DOWNTO 0);
m_axis_cq_tvalid => i_axi_cq_tvalid   ,--: OUT STD_LOGIC;

s_axis_cc_tdata  => i_axi_cc_tdata ,--: IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
s_axis_cc_tkeep  => i_axi_cc_tkeep ,--: IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
s_axis_cc_tlast  => i_axi_cc_tlast ,--: IN  STD_LOGIC;
s_axis_cc_tready => i_axi_cc_tready,--: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
s_axis_cc_tuser  => i_axi_cc_tuser ,--: IN  STD_LOGIC_VECTOR(32 DOWNTO 0);
s_axis_cc_tvalid => i_axi_cc_tvalid,--: IN  STD_LOGIC;

pcie_rq_seq_num      => i_pcie_rq_seq_num     ,--: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
pcie_rq_seq_num_vld  => i_pcie_rq_seq_num_vld ,--: OUT STD_LOGIC;
pcie_rq_tag          => i_pcie_rq_tag         ,--: OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
pcie_rq_tag_av       => open                  ,--: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
pcie_rq_tag_vld      => i_pcie_rq_tag_vld     ,--: OUT STD_LOGIC;
pcie_tfc_nph_av      => i_pcie_tfc_nph_av     ,--: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
pcie_tfc_npd_av      => i_pcie_tfc_npd_av     ,--: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
pcie_cq_np_req       => i_pcie_cq_np_req      ,--: IN  STD_LOGIC;
pcie_cq_np_req_count => i_pcie_cq_np_req_count,--: OUT STD_LOGIC_VECTOR(5 DOWNTO 0);

cfg_phy_link_down        => open                      ,--: OUT STD_LOGIC;
cfg_phy_link_status      => i_cfg_phy_link_status     ,--: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
cfg_negotiated_width     => i_cfg_negotiated_width    ,--: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_current_speed        => i_cfg_current_speed       ,--: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_max_payload          => i_cfg_max_payload         ,--: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_max_read_req         => i_cfg_max_read_req        ,--: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_function_status      => i_cfg_function_status     ,--: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
cfg_function_power_state => open                      ,--: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_vf_status            => open                      ,--: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
cfg_vf_power_state       => open                      ,--: OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
cfg_link_power_state     => open                      ,--: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

cfg_mgmt_addr                 => (others => '0'),--: IN  STD_LOGIC_VECTOR(18 DOWNTO 0);
cfg_mgmt_write                => '0',            --: IN  STD_LOGIC;
cfg_mgmt_write_data           => (others => '0'),--: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_mgmt_byte_enable          => (others => '0'),--: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_mgmt_read                 => '0',            --: IN  STD_LOGIC;
cfg_mgmt_read_data            => open,           --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_mgmt_read_write_done      => open,           --: OUT STD_LOGIC;
cfg_mgmt_type1_cfg_reg_access => '0',            --: IN  STD_LOGIC;

cfg_err_cor_out             => i_cfg_err_cor_out     ,--: OUT STD_LOGIC;
cfg_err_nonfatal_out        => i_cfg_err_nonfatal_out,--: OUT STD_LOGIC;
cfg_err_fatal_out           => i_cfg_err_fatal_out   ,--: OUT STD_LOGIC;
cfg_local_error             => open                  ,--: OUT STD_LOGIC;
cfg_ltr_enable              => open                  ,--: OUT STD_LOGIC;
cfg_ltssm_state             => open                  ,--: OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
cfg_rcb_status              => i_cfg_rcb_status      ,--: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_dpa_substate_change     => open                  ,--: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_obff_enable             => i_cfg_obff_enable     ,--: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
cfg_pl_status_change        => open                  ,--: OUT STD_LOGIC;
cfg_tph_requester_enable    => open                  ,--: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_tph_st_mode             => open                  ,--: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_vf_tph_requester_enable => open                  ,--: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_vf_tph_st_mode          => open                  ,--: OUT STD_LOGIC_VECTOR(23 DOWNTO 0);

cfg_msg_received      => i_cfg_msg_received      ,--: OUT STD_LOGIC;
cfg_msg_received_data => i_cfg_msg_received_data ,--: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_msg_received_type => i_cfg_msg_received_type ,--: OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
cfg_msg_transmit      => i_cfg_msg_transmit      ,--: IN  STD_LOGIC;
cfg_msg_transmit_type => i_cfg_msg_transmit_type ,--: IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_msg_transmit_data => i_cfg_msg_transmit_data ,--: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_msg_transmit_done => i_cfg_msg_transmit_done ,--: OUT STD_LOGIC;

cfg_fc_ph   => i_cfg_fc_ph  ,--: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_fc_pd   => i_cfg_fc_pd  ,--: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_fc_nph  => i_cfg_fc_nph ,--: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_fc_npd  => i_cfg_fc_npd ,--: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_fc_cplh => i_cfg_fc_cplh,--: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_fc_cpld => i_cfg_fc_cpld,--: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_fc_sel  => i_cfg_fc_sel ,--: IN  STD_LOGIC_VECTOR(2 DOWNTO 0);

cfg_per_func_status_control      => (others => '0'),--: IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_per_func_status_data         => open           ,--: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
cfg_per_function_number          => (others => '0'),--: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_per_function_output_request  => '0'            ,--: IN  STD_LOGIC;
cfg_per_function_update_done     => open           ,--: OUT STD_LOGIC;

cfg_dsn                          => i_cfg_dsn                          ,--: IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
cfg_power_state_change_ack       => i_cfg_power_state_change_ack       ,--: IN  STD_LOGIC;
cfg_power_state_change_interrupt => i_cfg_power_state_change_interrupt ,--: OUT STD_LOGIC;
cfg_err_cor_in                   => i_cfg_err_cor_in                   ,--: IN  STD_LOGIC;
cfg_err_uncor_in                 => i_cfg_err_uncor_in                 ,--: IN  STD_LOGIC;
cfg_flr_in_process               => i_cfg_flr_in_process     ,--: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_flr_done                     => i_cfg_flr_done           ,--: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_vf_flr_in_process            => i_cfg_vf_flr_in_process  ,--: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_vf_flr_done                  => i_cfg_vf_flr_done        ,--: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_link_training_enable         => '1', --Always enable LTSSM to bring up the Link
cfg_ext_read_received            => open                               ,--: OUT STD_LOGIC;
cfg_ext_write_received           => open                               ,--: OUT STD_LOGIC;
cfg_ext_register_number          => open                               ,--: OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
cfg_ext_function_number          => open                               ,--: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_ext_write_data               => open                               ,--: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_ext_write_byte_enable        => open                               ,--: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_ext_read_data                => (others => '0')                    ,--: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_ext_read_data_valid          => '0'                                ,--: IN  STD_LOGIC;

cfg_interrupt_int                => i_cfg_interrupt_int                ,--: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_interrupt_pending            => i_cfg_interrupt_pending            ,--: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_interrupt_sent               => i_cfg_interrupt_sent               ,--: OUT STD_LOGIC;
cfg_interrupt_msi_enable         => i_cfg_interrupt_msi_enable         ,--: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_interrupt_msi_vf_enable      => i_cfg_interrupt_msi_vf_enable      ,--: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_interrupt_msi_mmenable       => i_cfg_interrupt_msi_mmenable       ,--: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
cfg_interrupt_msi_mask_update    => i_cfg_interrupt_msi_mask_update    ,--: OUT STD_LOGIC;
cfg_interrupt_msi_data           => i_cfg_interrupt_msi_data           ,--: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_interrupt_msi_select         => i_cfg_interrupt_msi_select         ,--: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_interrupt_msi_int            => i_cfg_interrupt_msi_int            ,--: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_interrupt_msi_pending_status              => i_cfg_interrupt_msi_pending_status             ,--: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
cfg_interrupt_msi_pending_status_data_enable  => i_cfg_interrupt_msi_pending_status_data_enable ,--: IN  STD_LOGIC;
cfg_interrupt_msi_pending_status_function_num => i_cfg_interrupt_msi_pending_status_function_num,--: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
cfg_interrupt_msi_sent            => i_cfg_interrupt_msi_sent           ,--: OUT STD_LOGIC;
cfg_interrupt_msi_fail            => i_cfg_interrupt_msi_fail           ,--: OUT STD_LOGIC;
cfg_interrupt_msi_attr            => i_cfg_interrupt_msi_attr           ,--: IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_interrupt_msi_tph_present     => i_cfg_interrupt_msi_tph_present    ,--: IN  STD_LOGIC;
cfg_interrupt_msi_tph_type        => i_cfg_interrupt_msi_tph_type       ,--: IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
cfg_interrupt_msi_tph_st_tag      => i_cfg_interrupt_msi_tph_st_tag     ,--: IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
cfg_interrupt_msi_function_number => i_cfg_interrupt_msi_function_number,--: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);

cfg_hot_reset_out               => i_cfg_hot_reset_out              ,--: OUT STD_LOGIC;
cfg_config_space_enable         => '1'                              ,--: IN  STD_LOGIC;
cfg_req_pm_transition_l23_ready => '0'                              ,--: IN  STD_LOGIC;
cfg_hot_reset_in                => i_cfg_hot_reset_in               ,--: IN  STD_LOGIC; --For RP mode only

cfg_ds_port_number     => i_cfg_ds_port_number    ,--: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_ds_bus_number      => i_cfg_ds_bus_number     ,--: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
cfg_ds_device_number   => i_cfg_ds_device_number  ,--: IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
cfg_ds_function_number => i_cfg_ds_function_number,--: IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
cfg_subsys_vend_id     => i_cfg_subsys_vend_id    ,--: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);

pcie_perstn1_in  => '0' ,--: IN  STD_LOGIC;
pcie_perstn0_out => open,--: OUT STD_LOGIC;
pcie_perstn1_out => open,--: OUT STD_LOGIC

int_qpll1lock_out => open, --: OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
int_qpll1outrefclk_out => open, --: OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
int_qpll1outclk_out => open, --: OUT STD_LOGIC_VECTOR(0 DOWNTO 0)


----Tandem
--mcap_design_switch => open,
--cap_req => open,
--cap_gnt => '1',
--cap_rel => '0',
--------------------------------------------------------------------------------------------------------------------//
---- PCIe Fast Config: Startup Interface - Can only be used in Tandem Mode                                          //
--------------------------------------------------------------------------------------------------------------------//
--startup_cfgclk    => open,     -- 1-bit output: Configuration main clock output
--startup_cfgmclk   => open,     -- 1-bit output: Configuration internal oscillator clock output
--startup_di        => open,
--startup_eos       => open,     -- 1-bit output: Active high output signal indicating the End Of Startup.
--startup_preq      => open,     -- 1-bit output: PROGRAM request to fabric output
--startup_do        => "0000",
--startup_dts       => "0000",
--startup_fcsbo     => '0',
--startup_fcsbts    => '0',
--startup_gsr       => '0',      -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
--startup_gts       => '0',      -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
--startup_keyclearb => '1',      -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
--startup_pack      => '0',      -- 1-bit input: PROGRAM acknowledge input
--startup_usrcclko  => '0',      -- 1-bit input: User CCLK input
--startup_usrcclkts => '1',      -- 1-bit input: User CCLK 3-state enable input
--startup_usrdoneo  => '0',      -- 1-bit input: User DONE pin output control
--startup_usrdonets => '1',      -- 1-bit input: User DONE 3-state enable output

sys_clk    => i_sys_clk      ,--: IN  STD_LOGIC;
sys_clk_gt => i_sys_clk_gt   ,--: IN  STD_LOGIC;
sys_reset  => i_sys_rst_n --: IN  STD_LOGIC; (Cold reset + Warm reset)
);


m_ctrl : pcie_ctrl
generic map(
G_SIM => G_SIM,
G_DBGCS => G_DBGCS,
G_DATA_WIDTH => CI_DATA_WIDTH
)
port map(
--------------------------------------
--USR Port
--------------------------------------
p_out_hclk      => p_out_hclk ,
p_out_gctrl     => p_out_gctrl,

--CTRL user devices
p_out_dev_ctrl  => p_out_dev_ctrl ,
p_out_dev_di    => p_out_dev_di  ,
p_in_dev_do   => p_in_dev_do  ,
p_out_dev_wr    => p_out_dev_wr   ,
p_out_dev_rd    => p_out_dev_rd   ,
p_in_dev_status => p_in_dev_status,
p_in_dev_irq    => p_in_dev_irq   ,
p_in_dev_opt    => p_in_dev_opt   ,
p_out_dev_opt   => p_out_dev_opt  ,

--DBG
p_out_dbg       => p_out_dbg,
p_out_tst       => p_out_usr_tst,
p_in_tst        => p_in_usr_tst ,

------------------------------------
--AXI Interface
------------------------------------
p_out_axi_rq_tlast  => i_axi_rq_tlast ,--: out  std_logic                                   ;
p_out_axi_rq_tdata  => i_axi_rq_tdata ,--: out  std_logic_vector(G_DATA_WIDTH - 1 downto 0) ;
p_out_axi_rq_tuser  => i_axi_rq_tuser ,--: out  std_logic_vector(59 downto 0)               ;
p_out_axi_rq_tkeep  => i_axi_rq_tkeep ,--: out  std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0)   ;
p_in_axi_rq_tready  => i_axi_rq_tready,--: in   std_logic_vector(3 downto 0)                ;
p_out_axi_rq_tvalid => i_axi_rq_tvalid,--: out  std_logic                                   ;

p_in_axi_rc_tdata   => i_axi_rc_tdata ,--: in   std_logic_vector(G_DATA_WIDTH - 1 downto 0) ;
p_in_axi_rc_tuser   => i_axi_rc_tuser ,--: in   std_logic_vector(74 downto 0)               ;
p_in_axi_rc_tlast   => i_axi_rc_tlast ,--: in   std_logic                                   ;
p_in_axi_rc_tkeep   => i_axi_rc_tkeep ,--: in   std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0)   ;
p_in_axi_rc_tvalid  => i_axi_rc_tvalid,--: in   std_logic                                   ;
p_out_axi_rc_tready => i_axi_rc_tready,--: out  std_logic_vector(21 downto 0)               ;

p_in_axi_cq_tdata   => i_axi_cq_tdata ,--: in   std_logic_vector(G_DATA_WIDTH - 1 downto 0) ;
p_in_axi_cq_tuser   => i_axi_cq_tuser ,--: in   std_logic_vector(84 downto 0)               ;
p_in_axi_cq_tlast   => i_axi_cq_tlast ,--: in   std_logic                                   ;
p_in_axi_cq_tkeep   => i_axi_cq_tkeep ,--: in   std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0)   ;
p_in_axi_cq_tvalid  => i_axi_cq_tvalid,--: in   std_logic                                   ;
p_out_axi_cq_tready => i_axi_cq_tready,--: out  std_logic_vector(21 downto 0)               ;

p_out_axi_cc_tdata  => i_axi_cc_tdata ,--: out  std_logic_vector(G_DATA_WIDTH - 1 downto 0) ;
p_out_axi_cc_tuser  => i_axi_cc_tuser ,--: out  std_logic_vector(32 downto 0)               ;
p_out_axi_cc_tlast  => i_axi_cc_tlast ,--: out  std_logic                                   ;
p_out_axi_cc_tkeep  => i_axi_cc_tkeep ,--: out  std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0)   ;
p_out_axi_cc_tvalid => i_axi_cc_tvalid,--: out  std_logic                                   ;
p_in_axi_cc_tready  => i_axi_cc_tready,--: in   std_logic_vector(3 downto 0)                ;

p_in_pcie_tfc_nph_av  => i_pcie_tfc_nph_av,--: in   std_logic_vector(1 downto 0)                ;
p_in_pcie_tfc_npd_av  => i_pcie_tfc_npd_av,--: in   std_logic_vector(1 downto 0)                ;

------------------------------------
--Configuration (CFG) Interface
------------------------------------
p_in_pcie_rq_seq_num      => i_pcie_rq_seq_num     ,
p_in_pcie_rq_seq_num_vld  => i_pcie_rq_seq_num_vld ,
p_in_pcie_rq_tag          => i_pcie_rq_tag         ,
p_in_pcie_rq_tag_vld      => i_pcie_rq_tag_vld     ,
p_out_pcie_cq_np_req      => i_pcie_cq_np_req      ,
p_in_pcie_cq_np_req_count => i_pcie_cq_np_req_count,
p_in_pcie_tfc_np_pl_empty => '0'                   ,
--p_in_pcie_rq_tag_av       => i_pcie_rq_tag_av      ,

------------------------------------
--Management Interface
------------------------------------
p_in_cfg_msg_received       => i_cfg_msg_received     ,
p_in_cfg_msg_received_data  => i_cfg_msg_received_data,
p_in_cfg_msg_received_type  => i_cfg_msg_received_type,
p_out_cfg_msg_transmit      => i_cfg_msg_transmit     ,
p_out_cfg_msg_transmit_type => i_cfg_msg_transmit_type,
p_out_cfg_msg_transmit_data => i_cfg_msg_transmit_data,
p_in_cfg_msg_transmit_done  => i_cfg_msg_transmit_done,

------------------------------------
-- EP and RP
------------------------------------
p_in_cfg_phy_link_status  => i_cfg_phy_link_status ,
p_in_cfg_negotiated_width => i_cfg_negotiated_width,
p_in_cfg_current_speed    => i_cfg_current_speed   ,
p_in_cfg_max_payload      => i_cfg_max_payload     ,
p_in_cfg_max_read_req     => i_cfg_max_read_req    ,
p_in_cfg_function_status  => i_cfg_function_status(7 downto 0),
p_in_cfg_rcb_status       => i_cfg_rcb_status(1 downto 0),

-- Error Reporting Interface
p_in_cfg_err_cor_out      => i_cfg_err_cor_out       ,
p_in_cfg_err_nonfatal_out => i_cfg_err_nonfatal_out  ,
p_in_cfg_err_fatal_out    => i_cfg_err_fatal_out     ,

p_in_cfg_fc_ph     => i_cfg_fc_ph  ,
p_in_cfg_fc_pd     => i_cfg_fc_pd  ,
p_in_cfg_fc_nph    => i_cfg_fc_nph ,
p_in_cfg_fc_npd    => i_cfg_fc_npd ,
p_in_cfg_fc_cplh   => i_cfg_fc_cplh,
p_in_cfg_fc_cpld   => i_cfg_fc_cpld,
p_out_cfg_fc_sel   => i_cfg_fc_sel ,

p_out_cfg_dsn                         => i_cfg_dsn                         ,
p_out_cfg_power_state_change_ack      => i_cfg_power_state_change_ack      ,
p_in_cfg_power_state_change_interrupt => i_cfg_power_state_change_interrupt,
p_out_cfg_err_cor_in                  => i_cfg_err_cor_in                  ,
p_out_cfg_err_uncor_in                => i_cfg_err_uncor_in                ,

p_in_cfg_flr_in_process       => i_cfg_flr_in_process    ,
p_out_cfg_flr_done            => i_cfg_flr_done          ,
p_in_cfg_vf_flr_in_process    => i_cfg_vf_flr_in_process ,
p_out_cfg_vf_flr_done         => i_cfg_vf_flr_done       ,

p_out_cfg_ds_port_number      => i_cfg_ds_port_number    ,
p_out_cfg_ds_bus_number       => i_cfg_ds_bus_number     ,
p_out_cfg_ds_device_number    => i_cfg_ds_device_number  ,
p_out_cfg_ds_function_number  => i_cfg_ds_function_number,

------------------------------------
-- EP Only
------------------------------------
-- Interrupt Interface Signals
p_out_cfg_interrupt_int                 => i_cfg_interrupt_int                 ,
p_out_cfg_interrupt_pending             => i_cfg_interrupt_pending             ,
p_in_cfg_interrupt_sent                 => i_cfg_interrupt_sent                ,

p_in_cfg_interrupt_msi_enable           => i_cfg_interrupt_msi_enable(1 downto 0)   ,--: in   std_logic_vector(1 downto 0) ;
p_in_cfg_interrupt_msi_vf_enable        => i_cfg_interrupt_msi_vf_enable(5 downto 0),--: in   std_logic_vector(5 downto 0) ;
p_in_cfg_interrupt_msi_mmenable         => i_cfg_interrupt_msi_mmenable(5 downto 0) ,--: in   std_logic_vector(5 downto 0) ;
p_in_cfg_interrupt_msi_mask_update      => i_cfg_interrupt_msi_mask_update     ,
p_in_cfg_interrupt_msi_data             => i_cfg_interrupt_msi_data            ,
p_out_cfg_interrupt_msi_select          => i_cfg_interrupt_msi_select          ,
p_out_cfg_interrupt_msi_int             => i_cfg_interrupt_msi_int             ,
p_out_cfg_interrupt_msi_pending_status  => i_cfg_interrupt_msi_pending_status  ,
p_in_cfg_interrupt_msi_sent             => i_cfg_interrupt_msi_sent            ,
p_in_cfg_interrupt_msi_fail             => i_cfg_interrupt_msi_fail            ,
p_out_cfg_interrupt_msi_attr            => i_cfg_interrupt_msi_attr            ,
p_out_cfg_interrupt_msi_tph_present     => i_cfg_interrupt_msi_tph_present     ,
p_out_cfg_interrupt_msi_tph_type        => i_cfg_interrupt_msi_tph_type        ,
p_out_cfg_interrupt_msi_tph_st_tag      => i_cfg_interrupt_msi_tph_st_tag      ,
p_out_cfg_interrupt_msi_function_number => i_cfg_interrupt_msi_function_number ,
p_out_cfg_interrupt_msi_pending_status_data_enable  => i_cfg_interrupt_msi_pending_status_data_enable ,
p_out_cfg_interrupt_msi_pending_status_function_num => i_cfg_interrupt_msi_pending_status_function_num,

p_in_cfg_interrupt_msix_enable          => '0',--: in  std_logic;
p_in_cfg_interrupt_msix_sent            => '0',--: in  std_logic;
p_in_cfg_interrupt_msix_fail            => '0',--: in  std_logic;
p_out_cfg_interrupt_msix_int            => open,--: out std_logic;
p_out_cfg_interrupt_msix_address        => open,--: out std_logic_vector(63 downto 0);
p_out_cfg_interrupt_msix_data           => open,--: out std_logic_vector(31 downto 0);

-- EP only
p_in_cfg_hot_reset_in   => i_cfg_hot_reset_out,

-- RP only
p_out_cfg_hot_reset_out => i_cfg_hot_reset_in,

p_in_user_clk    => i_user_clk   ,
p_in_user_reset  => i_user_reset ,
p_in_user_lnk_up => i_user_lnk_up
);

p_out_pcie_rst_n <= i_sys_rst_n;



--#############################################
--DBG
--#############################################
p_out_tst(0) <= i_user_lnk_up;
p_out_tst(p_out_tst'high downto 1) <= (others => '0');


end architecture behavioral;
