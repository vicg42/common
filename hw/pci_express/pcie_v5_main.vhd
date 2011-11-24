-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.01.2011 9:54:18
-- Module Name : pcie_main.vhd
--
-- Description : Связь между Контроллер Endpoint PCI-Express и ядром PCI-Express.
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
G_PCIE_LINK_WIDTH : integer:=1;
G_PCIE_RST_SEL    : integer:=1;
G_DBG : string :="OFF"
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

constant GI_PCI_EXP_TRN_DATA_WIDTH       : integer:= 64;
constant GI_PCI_EXP_TRN_REM_WIDTH        : integer:= 8;
constant GI_PCI_EXP_TRN_BUF_AV_WIDTH     : integer:= 4;
constant GI_PCI_EXP_BAR_HIT_WIDTH        : integer:= 7;
constant GI_PCI_EXP_FC_HDR_WIDTH         : integer:= 8;
constant GI_PCI_EXP_FC_DATA_WIDTH        : integer:= 12;
constant GI_PCI_EXP_CFG_DATA_WIDTH       : integer:= 32;
constant GI_PCI_EXP_CFG_ADDR_WIDTH       : integer:= 10;
constant GI_PCI_EXP_CFG_CPLHDR_WIDTH     : integer:= 48;
constant GI_PCI_EXP_CFG_BUSNUM_WIDTH     : integer:= 8;
constant GI_PCI_EXP_CFG_DEVNUM_WIDTH     : integer:= 5;
constant GI_PCI_EXP_CFG_FUNNUM_WIDTH     : integer:= 3;
constant GI_PCI_EXP_CFG_CAP_WIDTH        : integer:= 16;


component core_pciexp_ep_blk_plus
--generic(
--PCI_EXP_LINK_WIDTH : integer    := 1;
--BAR0               : bit_vector := X"FFFFFF00";
--BAR1               : bit_vector := X"FFFFFF01"
--);
port(
--------------------------------------
--PCI Express Fabric Interface
--------------------------------------
pci_exp_txp                : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
pci_exp_txn                : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
pci_exp_rxp                : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
pci_exp_rxn                : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);

--------------------------------------
--Tx
--------------------------------------
trn_td                     : in    std_logic_vector(GI_PCI_EXP_TRN_DATA_WIDTH-1 downto 0);
trn_trem_n                 : in    std_logic_vector(GI_PCI_EXP_TRN_REM_WIDTH-1 downto 0);
trn_tsof_n                 : in    std_logic;
trn_teof_n                 : in    std_logic;
trn_tsrc_rdy_n             : in    std_logic;
trn_tdst_rdy_n             : out   std_logic;
trn_tdst_dsc_n             : out   std_logic;
trn_tsrc_dsc_n             : in    std_logic;
trn_terrfwd_n              : in    std_logic;
trn_tbuf_av                : out   std_logic_vector(GI_PCI_EXP_TRN_BUF_AV_WIDTH-1 downto 0);

--------------------------------------
--Rx
--------------------------------------
trn_rd                     : out   std_logic_vector(GI_PCI_EXP_TRN_DATA_WIDTH-1 downto 0);
trn_rrem_n                 : out   std_logic_vector(GI_PCI_EXP_TRN_REM_WIDTH-1 downto 0);
trn_rsof_n                 : out   std_logic;
trn_reof_n                 : out   std_logic;
trn_rsrc_rdy_n             : out   std_logic;
trn_rsrc_dsc_n             : out   std_logic;
trn_rdst_rdy_n             : in    std_logic;
trn_rerrfwd_n              : out   std_logic;
trn_rnp_ok_n               : in    std_logic;
trn_rbar_hit_n             : out   std_logic_vector(GI_PCI_EXP_BAR_HIT_WIDTH-1 downto 0);
trn_rfc_nph_av             : out   std_logic_vector(GI_PCI_EXP_FC_HDR_WIDTH-1 downto 0);
trn_rfc_npd_av             : out   std_logic_vector(GI_PCI_EXP_FC_DATA_WIDTH-1 downto 0);
trn_rfc_ph_av              : out   std_logic_vector(GI_PCI_EXP_FC_HDR_WIDTH-1 downto 0);
trn_rfc_pd_av              : out   std_logic_vector(GI_PCI_EXP_FC_DATA_WIDTH-1 downto 0);
trn_rcpl_streaming_n       : in    std_logic;

--------------------------------------
--CFG Interface
--------------------------------------
cfg_do                     : out   std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH-1 downto 0);
cfg_rd_wr_done_n           : out   std_logic;
cfg_di                     : in    std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH-1 downto 0);
cfg_byte_en_n              : in    std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH/8-1 downto 0);
cfg_dwaddr                 : in    std_logic_vector(GI_PCI_EXP_CFG_ADDR_WIDTH-1 downto 0);
cfg_wr_en_n                : in    std_logic;
cfg_rd_en_n                : in    std_logic;
cfg_err_cor_n              : in    std_logic;
cfg_err_ur_n               : in    std_logic;
cfg_err_ecrc_n             : in    std_logic;
cfg_err_cpl_timeout_n      : in    std_logic;
cfg_err_cpl_abort_n        : in    std_logic;
cfg_err_cpl_unexpect_n     : in    std_logic;
cfg_err_posted_n           : in    std_logic;
cfg_err_tlp_cpl_header     : in    std_logic_vector(GI_PCI_EXP_CFG_CPLHDR_WIDTH-1 downto 0);

cfg_err_cpl_rdy_n          : out   std_logic;
cfg_err_locked_n           : in    std_logic;
cfg_interrupt_n            : in    std_logic;
cfg_interrupt_rdy_n        : out   std_logic;
cfg_interrupt_assert_n     : in    std_logic;
cfg_interrupt_di           : in    std_logic_vector(7 downto 0);
cfg_interrupt_do           : out   std_logic_vector(7 downto 0);
cfg_interrupt_mmenable     : out   std_logic_vector(2 downto 0);
cfg_interrupt_msienable    : out   std_logic;
cfg_to_turnoff_n           : out   std_logic;
cfg_pm_wake_n              : in    std_logic;
cfg_pcie_link_state_n      : out   std_logic_vector(2 downto 0);
cfg_trn_pending_n          : in    std_logic;
cfg_bus_number             : out   std_logic_vector(GI_PCI_EXP_CFG_BUSNUM_WIDTH-1 downto 0);
cfg_device_number          : out   std_logic_vector(GI_PCI_EXP_CFG_DEVNUM_WIDTH-1 downto 0);
cfg_function_number        : out   std_logic_vector(GI_PCI_EXP_CFG_FUNNUM_WIDTH-1 downto 0);
cfg_dsn                    : in    std_logic_vector(63 downto 0);
cfg_status                 : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
cfg_command                : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
cfg_dstatus                : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
cfg_dcommand               : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
cfg_lstatus                : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
cfg_lcommand               : out   std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
fast_train_simulation_only : in    std_logic;

--------------------------------------
--System Port
--------------------------------------
trn_clk                    : out   std_logic;
trn_reset_n                : out   std_logic;
trn_lnk_up_n               : out   std_logic;

sys_clk                    : in    std_logic;
refclkout                  : out   std_logic;
sys_reset_n                : in    std_logic
);
end component;

component pcie_ctrl
generic(
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
end component;

component pcie_reset
port(
pciexp_refclk_i : in    std_logic;
trn_lnk_up_n_i  : in    std_logic;
sys_reset_n_o   : out   std_logic;
module_rdy_o    : out   std_logic
);
end component;

signal from_ctrl_rst_n            : std_logic;

signal refclkout                  : std_logic;

signal sys_reset_n                : std_logic;
signal trn_clk                    : std_logic;
signal trn_reset_n                : std_logic;
signal trn_lnk_up_n               : std_logic;

signal trn_tsof_n                 : std_logic;
signal trn_teof_n                 : std_logic;
signal trn_tsrc_rdy_n             : std_logic;
signal trn_tdst_rdy_n             : std_logic;
signal trn_tsrc_dsc_n             : std_logic;
signal trn_terrfwd_n              : std_logic;
signal trn_tdst_dsc_n             : std_logic;
signal trn_td                     : std_logic_vector(GI_PCI_EXP_TRN_DATA_WIDTH-1 downto 0);
signal trn_trem_n                 : std_logic_vector(GI_PCI_EXP_TRN_REM_WIDTH-1 downto 0);
signal trn_tbuf_av                : std_logic_vector(GI_PCI_EXP_TRN_BUF_AV_WIDTH-1 downto 0);

signal trn_rsof_n                 : std_logic;
signal trn_reof_n                 : std_logic;
signal trn_rsrc_rdy_n             : std_logic;
signal trn_rsrc_dsc_n             : std_logic;
signal trn_rdst_rdy_n             : std_logic;
signal trn_rerrfwd_n              : std_logic;
signal trn_rnp_ok_n               : std_logic;
signal trn_rd                     : std_logic_vector(GI_PCI_EXP_TRN_DATA_WIDTH-1 downto 0);
signal trn_rrem_n                 : std_logic_vector(GI_PCI_EXP_TRN_REM_WIDTH-1 downto 0);
signal trn_rbar_hit_n             : std_logic_vector(GI_PCI_EXP_BAR_HIT_WIDTH-1 downto 0);
signal trn_rfc_nph_av             : std_logic_vector(GI_PCI_EXP_FC_HDR_WIDTH-1 downto 0);
signal trn_rfc_npd_av             : std_logic_vector(GI_PCI_EXP_FC_DATA_WIDTH-1 downto 0);
signal trn_rfc_ph_av              : std_logic_vector(GI_PCI_EXP_FC_HDR_WIDTH-1 downto 0);
signal trn_rfc_pd_av              : std_logic_vector(GI_PCI_EXP_FC_DATA_WIDTH-1 downto 0);
signal trn_rcpl_streaming_n       : std_logic;

signal cfg_do                     : std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH-1 downto 0);
signal cfg_di                     : std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH-1 downto 0);
signal cfg_dwaddr                 : std_logic_vector(GI_PCI_EXP_CFG_ADDR_WIDTH-1 downto 0);
signal cfg_byte_en_n              : std_logic_vector(GI_PCI_EXP_CFG_DATA_WIDTH/8-1 downto 0);
signal cfg_wr_en_n                : std_logic;
signal cfg_rd_en_n                : std_logic;
signal cfg_rd_wr_done_n           : std_logic;

signal cfg_err_tlp_cpl_header     : std_logic_vector(GI_PCI_EXP_CFG_CPLHDR_WIDTH-1 downto 0);
signal cfg_err_cor_n              : std_logic;
signal cfg_err_ur_n               : std_logic;
signal cfg_err_cpl_rdy_n          : std_logic;
signal cfg_err_ecrc_n             : std_logic;
signal cfg_err_cpl_timeout_n      : std_logic;
signal cfg_err_cpl_abort_n        : std_logic;
signal cfg_err_cpl_unexpect_n     : std_logic;
signal cfg_err_posted_n           : std_logic;
signal cfg_err_locked_n           : std_logic;

signal cfg_interrupt_n            : std_logic;
signal cfg_interrupt_rdy_n        : std_logic;
signal cfg_interrupt_assert_n     : std_logic;
signal cfg_interrupt_di           : std_logic_vector(7 downto 0);
signal cfg_interrupt_do           : std_logic_vector(7 downto 0);
signal cfg_interrupt_mmenable     : std_logic_vector(2 downto 0);
signal cfg_interrupt_msienable    : std_logic;

signal cfg_turnoff_ok_n           : std_logic;
signal cfg_to_turnoff_n           : std_logic;
signal cfg_pm_wake_n              : std_logic;
signal cfg_trn_pending_n          : std_logic;
signal cfg_dsn                    : std_logic_vector(63 downto 0);

signal cfg_pcie_link_state_n      : std_logic_vector(2 downto 0);
signal cfg_bus_number             : std_logic_vector(GI_PCI_EXP_CFG_BUSNUM_WIDTH-1 downto 0);
signal cfg_device_number          : std_logic_vector(GI_PCI_EXP_CFG_DEVNUM_WIDTH-1 downto 0);
signal cfg_function_number        : std_logic_vector(GI_PCI_EXP_CFG_FUNNUM_WIDTH-1 downto 0);
signal cfg_status                 : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
signal cfg_command                : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
signal cfg_dstatus                : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
signal cfg_dcommand               : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
signal cfg_lstatus                : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);
signal cfg_lcommand               : std_logic_vector(GI_PCI_EXP_CFG_CAP_WIDTH-1 downto 0);

signal user_trn_tbuf_av           : std_logic_vector(5 downto 0);--(15 downto 0);



--//MAIN
begin

--//#############################################
--//DBG
--//#############################################
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
p_out_tst(16)<=cfg_command(2);--//cfg_bus_mstr_enable
p_out_tst(19 downto 17)<=cfg_interrupt_mmenable(2 downto 0);
p_out_tst(20)<=cfg_status(3);--//Interrupt Status
p_out_tst(21)<=trn_rcpl_streaming_n;
p_out_tst(22)<=trn_rnp_ok_n;
p_out_tst(31 downto 23)<=(others=>'0');
p_out_tst(95 downto 32)<=trn_td;
p_out_tst(159 downto 96)<=trn_rd;
p_out_tst(160)<=trn_rrem_n(0);
p_out_tst(199 downto 161)<=(others=>'0');
p_out_tst(215 downto 200)<=(others=>'0');
p_out_tst(231 downto 216)<=(others=>'0');
p_out_tst(248)           <='0';
p_out_tst(255 downto 249)<=(others=>'0');


--//#############################################
--//Модуль ядра PCI-Express
--//#############################################
m_core : core_pciexp_ep_blk_plus
--generic map(
--PCI_EXP_LINK_WIDTH => G_PCIE_LINK_WIDTH,
--BAR0               => X"FFFFFF00", --Memory: Size 256 byte, --bit_vector
--BAR1               => X"FFFFFF01"  --IO    : Size 256 byte, --bit_vector
--)
port map(
--------------------------------------
--PCI Express Fabric Interface
--------------------------------------
pci_exp_txp                => p_out_pciexp_txp,
pci_exp_txn                => p_out_pciexp_txn,
pci_exp_rxp                => p_in_pciexp_rxp,
pci_exp_rxn                => p_in_pciexp_rxn,

--------------------------------------
--Tx
--------------------------------------
trn_td                     => trn_td,
trn_trem_n                 => trn_trem_n,
trn_tsof_n                 => trn_tsof_n,
trn_teof_n                 => trn_teof_n,
trn_tsrc_rdy_n             => trn_tsrc_rdy_n,
trn_tdst_rdy_n             => trn_tdst_rdy_n,
trn_tdst_dsc_n             => trn_tdst_dsc_n,
trn_tsrc_dsc_n             => trn_tsrc_dsc_n,
trn_terrfwd_n              => trn_terrfwd_n,
trn_tbuf_av                => trn_tbuf_av,

--------------------------------------
--Rx
--------------------------------------
trn_rd                     => trn_rd,
trn_rrem_n                 => trn_rrem_n,
trn_rsof_n                 => trn_rsof_n,
trn_reof_n                 => trn_reof_n,
trn_rsrc_rdy_n             => trn_rsrc_rdy_n,
trn_rsrc_dsc_n             => trn_rsrc_dsc_n,
trn_rdst_rdy_n             => trn_rdst_rdy_n,
trn_rerrfwd_n              => trn_rerrfwd_n,
trn_rnp_ok_n               => trn_rnp_ok_n,
trn_rbar_hit_n             => trn_rbar_hit_n,
trn_rfc_nph_av             => trn_rfc_nph_av,
trn_rfc_npd_av             => trn_rfc_npd_av,
trn_rfc_ph_av              => trn_rfc_ph_av,
trn_rfc_pd_av              => trn_rfc_pd_av,
trn_rcpl_streaming_n       => trn_rcpl_streaming_n,

--------------------------------------
--CFG Interface
--------------------------------------
cfg_do                     => cfg_do,
cfg_rd_wr_done_n           => cfg_rd_wr_done_n,
cfg_di                     => cfg_di,
cfg_byte_en_n              => cfg_byte_en_n,
cfg_dwaddr                 => cfg_dwaddr,
cfg_wr_en_n                => cfg_wr_en_n,
cfg_rd_en_n                => cfg_rd_en_n,
cfg_err_cor_n              => cfg_err_cor_n,
cfg_err_ur_n               => cfg_err_ur_n,
cfg_err_ecrc_n             => cfg_err_ecrc_n,
cfg_err_cpl_timeout_n      => cfg_err_cpl_timeout_n,
cfg_err_cpl_abort_n        => cfg_err_cpl_abort_n,
cfg_err_cpl_unexpect_n     => cfg_err_cpl_unexpect_n,
cfg_err_posted_n           => cfg_err_posted_n,
cfg_err_tlp_cpl_header     => cfg_err_tlp_cpl_header,

cfg_err_cpl_rdy_n          => cfg_err_cpl_rdy_n,
cfg_err_locked_n           => cfg_err_locked_n,
cfg_interrupt_n            => cfg_interrupt_n,
cfg_interrupt_rdy_n        => cfg_interrupt_rdy_n,
cfg_interrupt_assert_n     => cfg_interrupt_assert_n,
cfg_interrupt_di           => cfg_interrupt_di,
cfg_interrupt_do           => cfg_interrupt_do,
cfg_interrupt_mmenable     => cfg_interrupt_mmenable,
cfg_interrupt_msienable    => cfg_interrupt_msienable,
cfg_to_turnoff_n           => cfg_to_turnoff_n,
cfg_pm_wake_n              => cfg_pm_wake_n,
cfg_pcie_link_state_n      => cfg_pcie_link_state_n,
cfg_trn_pending_n          => cfg_trn_pending_n,
cfg_bus_number             => cfg_bus_number,
cfg_device_number          => cfg_device_number,
cfg_function_number        => cfg_function_number,
cfg_dsn                    => cfg_dsn,
cfg_status                 => cfg_status,
cfg_command                => cfg_command,
cfg_dstatus                => cfg_dstatus,
cfg_dcommand               => cfg_dcommand,
cfg_lstatus                => cfg_lstatus,
cfg_lcommand               => cfg_lcommand,
fast_train_simulation_only => p_in_fast_simulation,

--------------------------------------
--System Port
--------------------------------------
trn_clk                    => trn_clk,
trn_reset_n                => trn_reset_n,
trn_lnk_up_n               => trn_lnk_up_n,

sys_clk                    => p_in_gtp_refclkin,
refclkout                  => refclkout,
sys_reset_n                => sys_reset_n
);


--//#############################################
--//Модуль приложения PCI-Express(упраление ядром PCI-Express+ упр. пользовательским портом)
--//#############################################
m_ctrl : pcie_ctrl
generic map(
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
trn_tdst_dsc_n_i          => trn_tdst_dsc_n,
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
trn_rfc_nph_av_i          => trn_rfc_nph_av,
trn_rfc_npd_av_i          => trn_rfc_npd_av,
trn_rfc_ph_av_i           => trn_rfc_ph_av,
trn_rfc_pd_av_i           => trn_rfc_pd_av,
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

user_trn_tbuf_av<=EXT(trn_tbuf_av, 6);
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


--END MAIN
end behavioral;

