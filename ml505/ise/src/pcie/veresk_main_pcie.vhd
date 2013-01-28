-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.08.2012 17:23:40
-- Module Name : veresk_main_pcie
--
-- Назначение/Описание :
-- Проект изделия Вереск-М(Р)
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
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
--use work.veresk_pkg.all;
use work.cfgdev_pkg.all;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;
--use work.eth_phypin_pkg.all;
--use work.eth_pkg.all;
--use work.dsn_eth_pkg.all;
--use work.dsn_video_ctrl_pkg.all;
use work.pcie_pkg.all;
use work.clocks_pkg.all;

entity veresk_main_pcie is
generic(
G_SIM_HOST : string:="OFF";
G_SIM_PCIE : std_logic:='0';
G_DBG_PCIE : string:="OFF";
G_SIM      : string:="OFF"
);
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_led         : out   std_logic_vector(7 downto 0);
--pin_out_TP          : out   std_logic_vector(7 downto 5);

--------------------------------------------------
--Memory banks
--------------------------------------------------
pin_out_phymem      : out   TMEMCTRL_phy_outs;
pin_inout_phymem    : inout TMEMCTRL_phy_inouts;

----------------------------------------------------
----Ethernet
----------------------------------------------------
--pin_out_sfp_tx_dis  : out   std_logic;--SFP - TX DISABLE
--pin_in_sfp_sd       : in    std_logic;--SFP - SD signal detect
--
--pin_out_ethphy      : out   TEthPhyPinOUT;
--pin_in_ethphy       : in    TEthPhyPinIN;
--pin_inout_ethphy_mdio  : inout std_logic;
--pin_out_ethphy_mdc     : out   std_logic;
--pin_out_ethphy_rst     : out   std_logic;

--------------------------------------------------
--PCI-EXPRESS
--------------------------------------------------
pin_out_pciexp_txp  : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_out_pciexp_txn  : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxp   : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxn   : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_clk_p : in    std_logic;
pin_in_pciexp_clk_n : in    std_logic;
pin_in_pciexp_rstn  : in    std_logic;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefClkPinIN
);
end entity;

architecture struct of veresk_main_pcie is

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--//мигание сведодиода
p_out_test_done: out   std_logic;--//сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

component clocks
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clkopt: in    std_logic_vector(3 downto 0);
p_in_clk   : in    TRefClkPinIN
);
end component;

component dsn_host
generic(
G_PCIE_LINK_WIDTH : integer:=1;
G_PCIE_RST_SEL    : integer:=1;
G_DBG      : string:="OFF";
G_SIM_HOST : string:="OFF";
G_SIM_PCIE : std_logic:='0'
);
port(
-------------------------------
--PCI-Express
-------------------------------
p_out_pciexp_txp  : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_out_pciexp_txn  : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxp   : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxn   : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);

p_in_pciexp_gt_clkin   : in    std_logic;
p_out_pciexp_gt_clkout : out   std_logic;

-------------------------------
--Пользовательский порт
-------------------------------
p_out_hclk        : out   std_logic;
p_out_gctrl       : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--Управление внешними устройствами
p_out_dev_ctrl    : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din     : out   std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_in_dev_dout     : in    std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_out_dev_wr      : out   std_logic;
p_out_dev_rd      : out   std_logic;
p_in_dev_status   : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq      : in    std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
p_in_dev_opt      : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
p_out_dev_opt     : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

p_out_usr_tst     : out   std_logic_vector(127 downto 0);
p_in_usr_tst      : in    std_logic_vector(127 downto 0);

-------------------------------
--Технологический
-------------------------------
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(255 downto 0);

-------------------------------
--System
-------------------------------
p_out_module_rdy  : out   std_logic;
p_in_rst_n        : in    std_logic
);
end component;

component pcie2mem_ctrl
generic(
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32;
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28;
G_DBG            : string :="OFF"
);
port(
-------------------------------
--Управление
-------------------------------
p_in_ctrl         : in    TPce2Mem_Ctrl;
p_out_status      : out   TPce2Mem_Status;

p_in_txd          : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_in_txd_wr       : in    std_logic;
p_out_txbuf_full  : out   std_logic;

p_out_rxd         : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_in_rxd_rd       : in    std_logic;
p_out_rxbuf_empty : out   std_logic;

p_in_hclk         : in    std_logic;

-------------------------------
--Связь с mem_ctrl
-------------------------------
p_out_mem         : out   TMemIN;
p_in_mem          : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end component;

signal g_pll_clkin                      : std_logic;
signal g_pll_mem_clk                    : std_logic;
--signal g_pll_tmr_clk                    : std_logic;
signal i_usrclk_rst                     : std_logic;
signal g_usrclk                         : std_logic_vector(7 downto 0);
signal g_usr_highclk                    : std_logic;
signal g_refclkopt                      : std_logic_vector(3 downto 0);
signal i_pciexp_gt_refclk               : std_logic;
signal g_pciexp_gt_refclkout            : std_logic;
--signal i_usrclk5_div                    : std_logic_vector(6 downto 0):=(others=>'0');

signal i_host_rdy                       : std_logic;
signal i_host_rst_n                     : std_logic;
signal g_host_clk                       : std_logic;
signal i_host_gctrl                     : std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);
signal i_host_dev_ctrl                  : std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
signal i_host_dev_txd                   : std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
signal i_host_dev_rxd                   : std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
signal i_host_dev_wr                    : std_logic;
signal i_host_dev_rd                    : std_logic;
signal i_host_dev_status                : std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
signal i_host_dev_irq                   : std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
signal i_host_dev_opt_in                : std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
signal i_host_dev_opt_out               : std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

signal i_host_devadr                    : std_logic_vector(C_HREG_DEV_CTRL_ADR_M_BIT-C_HREG_DEV_CTRL_ADR_L_BIT downto 0);
--signal i_host_vchsel                    : std_logic_vector(3 downto 0);

Type THostDCtrl is array (0 to C_HDEV_COUNT-1) of std_logic;
Type THostDWR is array (0 to C_HDEV_COUNT-1) of std_logic_vector(i_host_dev_txd'range);
signal i_host_wr                        : THostDCtrl;
signal i_host_rd                        : THostDCtrl;
signal i_host_txd                       : THostDWR;
signal i_host_rxd                       : THostDWR;
signal i_host_rxrdy                     : THostDCtrl;
signal i_host_txrdy                     : THostDCtrl;
signal i_host_rxbuf_empty               : THostDCtrl;
signal i_host_txbuf_full                : THostDCtrl;
signal i_host_irq                       : std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
--signal i_host_txd_rdy                   : THostDCtrl;
signal i_host_rxerr                    : THostDCtrl;

signal i_host_rst_all                   : std_logic;
--signal i_host_rst_eth                   : std_logic;
--signal i_host_rst_mem                   : std_logic;
--signal i_host_rddone_vctrl              : std_logic;
--signal i_host_rst_pult                  : std_logic;
--signal i_host_rst_edev                  : std_logic;
--signal i_host_rst_vizir                 : std_logic;
--signal i_host_rst_bup                   : std_logic;

--Type THDevWidthCnt is array (0 to C_HDEV_COUNT-1) of std_logic_vector(2 downto 0);
--signal i_hdev_dma_start                 : std_logic_vector(C_HDEV_COUNT-1 downto 0);
--signal hclk_hdev_dma_start              : std_logic_vector(C_HDEV_COUNT-1 downto 0);
--signal hclk_hdev_dma_start_cnt          : THDevWidthCnt;

signal i_host_tst_in                    : std_logic_vector(127 downto 0);
signal i_host_tst_out                   : std_logic_vector(127 downto 0);
signal i_host_tst2_out                  : std_logic_vector(255 downto 0);

signal i_cfg_rst                        : std_logic;
signal i_cfg_rdy                        : std_logic;
signal i_cfg_dadr                       : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_radr                       : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_radr_ld                    : std_logic;
signal i_cfg_radr_fifo                  : std_logic;
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_txd                        : std_logic_vector(15 downto 0);
signal i_cfg_rxd                        : std_logic_vector(15 downto 0);
Type TCfgRxD is array (0 to C_CFGDEV_COUNT-1) of std_logic_vector(i_cfg_rxd'range);
signal i_cfg_rxd_dev                    : TCfgRxD;
signal i_cfg_done                       : std_logic;
signal i_cfg_wr_dev                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_rd_dev                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_done_dev                   : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_tst_out                    : std_logic_vector(31 downto 0);

--signal i_swt_rst                        : std_logic;
--signal i_swt_tst_out,i_swt_tst_in       : std_logic_vector(31 downto 0);
--signal i_eth_gt_refclk125               : std_logic_vector(1 downto 0);
--signal i_eth_rst                        : std_logic;
--signal i_eth_out                        : TEthOUTs;
--signal i_eth_in                         : TEthINs;
--signal i_ethphy_out                     : TEthPhyOUT;
--signal i_ethphy_in                      : TEthPhyIN;
----signal i_eth_tst_out                    : std_logic_vector(31 downto 0);
--signal dbg_eth_out                      : TEthDBG;

--signal i_tmr_rst                        : std_logic;
--signal i_tmr_clk                        : std_logic;
--signal i_tmr_hirq                       : std_logic_vector(C_TMR_COUNT-1 downto 0);
--signal i_tmr_en                         : std_logic_vector(C_TMR_COUNT-1 downto 0);

--signal i_vctrl_rst                      : std_logic;
--signal hclk_hrddone_vctrl_cnt           : std_logic_vector(2 downto 0);
--signal hclk_hrddone_vctrl               : std_logic;
--signal i_vctrl_vbufin_rdy               : std_logic;
--signal i_vctrl_vbufin_dout              : std_logic_vector(31 downto 0);
--signal i_vctrl_vbufin_rd                : std_logic;
--signal i_vctrl_vbufin_empty             : std_logic;
--signal i_vctrl_vbufin_pfull             : std_logic;
--signal i_vctrl_vbufin_full              : std_logic;
--signal i_vctrl_vbufout_din              : std_logic_vector(31 downto 0);
--signal i_vctrl_vbufout_wd               : std_logic;
--signal i_vctrl_vbufout_empty            : std_logic;
--signal i_vctrl_vbufout_full             : std_logic;

--signal i_vctrl_hrd_start                : std_logic;
--signal i_vctrl_hrd_done                 : std_logic;
--signal sr_vctrl_hrd_done                : std_logic_vector(1 downto 0);
--signal g_vctrl_swt_bufclk               : std_logic;
--signal i_vctrl_hirq                     : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
--signal i_vctrl_hrdy                     : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
--signal i_vctrl_hirq_out                 : std_logic_vector(C_VCTRL_VCH_COUNT_MAX-1 downto 0);
--signal i_vctrl_hrdy_out                 : std_logic_vector(C_VCTRL_VCH_COUNT_MAX-1 downto 0);
--signal i_vctrl_hfrmrk                   : std_logic_vector(31 downto 0);
--signal i_vctrl_vrd_done                 : std_logic;
--signal i_vctrl_tst_out                  : std_logic_vector(31 downto 0);
--signal i_vctrl_vrdprms                  : TReaderVCHParams;
--signal i_vctrl_vfrdy                    : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
--signal i_vctrl_vrowmrk                  : TVMrks;
--signal i_vctrlwr_memin                  : TMemIN;
--signal i_vctrlwr_memout                 : TMemOUT;
--signal i_vctrlrd_memin                  : TMemIN;
--signal i_vctrlrd_memout                 : TMemOUT;

--signal i_trc_busy                       : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0):=(others=>'0');
--signal i_trc_vbufs                      : TVfrBufs;

signal i_host_mem_rst                   : std_logic;
signal i_host_mem_ctrl                  : TPce2Mem_Ctrl;
signal i_host_mem_status                : TPce2Mem_Status;
signal i_host_memin                     : TMemIN;
signal i_host_memout                    : TMemOUT;
signal i_host_mem_tst_out               : std_logic_vector(31 downto 0);

--signal i_memctrl_rst                    : std_logic;
--signal i_memctrl_locked                 : std_logic_vector(7 downto 0);
--signal i_memctrl_ready                  : std_logic;

--signal i_memin_ch                       : TMemINCh;
--signal i_memout_ch                      : TMemOUTCh;
signal i_memin_bank                     : TMemINBank;
signal i_memout_bank                    : TMemOUTBank;

----signal i_arb_mem_rst                    : std_logic;
--signal i_arb_memin                      : TMemIN;
--signal i_arb_memout                     : TMemOUT;
--signal i_arb_mem_tst_out                : std_logic_vector(31 downto 0);

signal i_mem_ctrl_status                : TMEMCTRL_status;
signal i_mem_ctrl_sysin                 : TMEMCTRL_sysin;
signal i_mem_ctrl_sysout                : TMEMCTRL_sysout;

--signal i_sync_out                       : std_logic_vector(0 downto 0);
--
--signal i_clk1MHz_en                     : std_logic;
--signal i_pult_rst                       : std_logic;
--signal i_edev_rst                       : std_logic;
--signal i_bup_rst                        : std_logic;
--signal i_vizir_rst                      : std_logic;
--signal i_vizir_bitclk                   : std_logic;

attribute keep : string;
attribute keep of g_host_clk : signal is "true";
attribute keep of g_usr_highclk : signal is "true";
attribute keep of g_usrclk : signal is "true";
--attribute keep of i_ethphy_out : signal is "true";

signal i_test01_led     : std_logic;
signal tst_clr          : std_logic;
signal tst_edev_out     : std_logic_vector(31 downto 0);


component dbgcs_iconx1
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;


component dbgcs_sata_raid_b
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(255 downto 0); --(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(49 DOWNTO 0)
    );
end component;

signal i_dbgcs_pcie            : std_logic_vector(35 downto 0);
signal i_pcie_dbgcs_data       : std_logic_vector(255 downto 0);
signal i_pcie_dbgcs_trig       : std_logic_vector(49 downto 0);

signal tst_cfg_interrupt_n         : std_logic;
signal tst_cfg_interrupt_rdy_n     : std_logic;
signal tst_cfg_interrupt_assert_n  : std_logic;
signal tst_cfg_interrupt_msienable : std_logic;

signal tst_trn_tsof_n          : std_logic;
signal tst_trn_teof_n          : std_logic;
signal tst_trn_tsrc_rdy_n      : std_logic;
signal tst_trn_tdst_rdy_n      : std_logic;
signal tst_trn_tsrc_dsc_n      : std_logic;

signal tst_trn_rsof_n          : std_logic;
signal tst_trn_reof_n          : std_logic;
signal tst_trn_rsrc_rdy_n      : std_logic;
signal tst_trn_rsrc_dsc_n      : std_logic;
signal tst_trn_rdst_rdy_n      : std_logic;

signal tst_trn_rbar_hit_n      : std_logic_vector(1 downto 0);
signal tst_cfg_bus_mstr_enable : std_logic;
signal tst_trn_rrem_n          : std_logic_vector(1 downto 0);
signal tst_trn_trem_n          : std_logic_vector(1 downto 0);
signal tst_trn_td              : std_logic_vector(63 downto 0);
signal tst_trn_rd              : std_logic_vector(127 downto 0);
signal tst_trn_rrem_n_old      : std_logic_vector(15 downto 0);
signal tst_trn_tbuf_av         : std_logic_vector(4 downto 0);

signal tst_reg_wr              : std_logic;
signal tst_buf_wr              : std_logic;
signal tst_rxbuf_rd_last       : std_logic;
signal tst_txbuf_wr_last       : std_logic;
signal tst_rx_engine_tst2      : std_logic_vector(9 downto 0);
signal tst_reg_val             : std_logic_vector(31 downto 0);
signal tst_dma_rxd             : std_logic_vector(31 downto 0);
signal tst_dmatrn_init         : std_logic;
signal tst_dma_start           : std_logic;
signal tst_rx_trn_dw_sel       : std_logic_vector(1 downto 0);
signal tst_usr_txbuf_full_i    : std_logic;
signal tst_usr_rxbuf_empty_i   : std_logic;
signal tst_host_dev_wr         : std_logic;
signal tst_host_dev_rd         : std_logic;
signal tst_irq_clr_det         : std_logic;
signal tst_irq_clr_cnt         : std_logic_vector(1 downto 0);
signal tst_fw_rd               : std_logic;

--//MAIN
begin


--***********************************************************
--//RESET модулей
--***********************************************************
i_host_rst_n <=pin_in_pciexp_rstn;

--i_tmr_rst    <=not i_host_rst_n or i_host_rst_all;
i_cfg_rst    <=not i_host_rst_n or i_host_rst_all;
--i_eth_rst    <=not i_host_rst_n or i_host_rst_all or i_host_rst_eth or i_usrclk_rst;
--i_vctrl_rst  <=not OR_reduce(i_mem_ctrl_status.rdy);
--i_swt_rst    <=not i_host_rst_n or i_host_rst_all;
i_host_mem_rst<=not OR_reduce(i_mem_ctrl_status.rdy);
i_mem_ctrl_sysin.rst<=not i_host_rst_n or i_host_rst_all;
--i_arb_mem_rst<=not OR_reduce(i_mem_ctrl_status.rdy);



--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_usrclk_rst,
p_out_gclk => g_usrclk,

p_in_clkopt=> g_refclkopt,
p_in_clk   => pin_in_refclk
);

g_refclkopt(0)<=g_host_clk;
--g_refclkopt(1)<=i_ethphy_out.clk;

g_usr_highclk<=i_mem_ctrl_sysout.clk;
--i_tmr_clk<=g_usrclk(2);
i_mem_ctrl_sysin.ref_clk<=g_usrclk(0);
i_mem_ctrl_sysin.clk<=g_usrclk(1);

i_pciexp_gt_refclk <= g_usrclk(3);
--i_ethphy_in.clk<=g_usrclk(4);


--***********************************************************
--Модуль конфигурирования устр-в
--***********************************************************
m_cfg : cfgdev_host
generic map(
G_DBG => "OFF",
G_HOST_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
--Связь с Хостом
-------------------------------
p_out_host_rxrdy     => i_host_rxrdy(C_HDEV_CFG_DBUF),
p_out_host_rxd       => i_host_rxd(C_HDEV_CFG_DBUF),
p_in_host_rd         => i_host_rd(C_HDEV_CFG_DBUF),

p_out_host_txrdy     => i_host_txrdy(C_HDEV_CFG_DBUF),
p_in_host_txd        => i_host_txd(C_HDEV_CFG_DBUF),
p_in_host_wr         => i_host_wr(C_HDEV_CFG_DBUF),

p_out_host_irq       => i_host_irq(C_HIRQ_CFG_RX),
p_in_host_clk        => g_host_clk,

-------------------------------
--
-------------------------------
p_out_module_rdy     => i_cfg_rdy,
p_out_module_error   => open,

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       => i_cfg_dadr,
p_out_cfg_radr       => i_cfg_radr,
p_out_cfg_radr_ld    => i_cfg_radr_ld,
p_out_cfg_radr_fifo  => i_cfg_radr_fifo,
p_out_cfg_wr         => i_cfg_wr,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => '1',
p_in_cfg_rxrdy       => '1',

p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => g_host_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => i_cfg_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_cfg_rst
);

--//Распределяем управление от блока конфигурирования(cfgdev.vhd):
i_cfg_rxd<=(others=>'0');

gen_cfg_dev : for i in 0 to C_CFGDEV_COUNT-1 generate
i_cfg_wr_dev(i)   <=i_cfg_wr   when i_cfg_dadr=i else '0';
i_cfg_rd_dev(i)   <=i_cfg_rd   when i_cfg_dadr=i else '0';
i_cfg_done_dev(i) <=i_cfg_done when i_cfg_dadr=i else '0';
end generate gen_cfg_dev;

--***********************************************************
--Проект модуля хоста - dsn_host.vhd
--***********************************************************
m_host : dsn_host
generic map(
G_PCIE_LINK_WIDTH => C_PCGF_PCIE_LINK_WIDTH,
G_PCIE_RST_SEL    => C_PCGF_PCIE_RST_SEL,
G_DBG      => G_DBG_PCIE,
G_SIM_HOST => G_SIM_HOST,
G_SIM_PCIE => G_SIM_PCIE
)
port map(
-------------------------------
--PCI-Express
-------------------------------
p_out_pciexp_txp   => pin_out_pciexp_txp,
p_out_pciexp_txn   => pin_out_pciexp_txn,
p_in_pciexp_rxp    => pin_in_pciexp_rxp,
p_in_pciexp_rxn    => pin_in_pciexp_rxn,

p_in_pciexp_gt_clkin   => i_pciexp_gt_refclk,
p_out_pciexp_gt_clkout => g_pciexp_gt_refclkout,

-------------------------------
--Пользовательский порт
-------------------------------
p_out_hclk         => g_host_clk,
p_out_gctrl        => i_host_gctrl,

p_out_dev_ctrl     => i_host_dev_ctrl,
p_out_dev_din      => i_host_dev_txd,
p_in_dev_dout      => i_host_dev_rxd,
p_out_dev_wr       => i_host_dev_wr,
p_out_dev_rd       => i_host_dev_rd,
p_in_dev_status    => i_host_dev_status,
p_in_dev_irq       => i_host_dev_irq,
p_in_dev_opt       => i_host_dev_opt_in,
p_out_dev_opt      => i_host_dev_opt_out,

-------------------------------
--Технологический
-------------------------------
p_in_usr_tst       => i_host_tst_in,
p_out_usr_tst      => i_host_tst_out,
p_in_tst           => (others=>'0'),
p_out_tst          => i_host_tst2_out,

-------------------------------
--System
-------------------------------
p_out_module_rdy   => i_host_rdy,
p_in_rst_n         => i_host_rst_n
);

i_host_tst_in(63 downto 0)<=(others=>'0');
i_host_tst_in(71 downto 64)<=(others=>'0');
i_host_tst_in(72)<= OR_reduce(tst_trn_rrem_n) or
                    OR_reduce(tst_trn_trem_n);-- or


i_host_tst_in(73)<= OR_reduce(tst_trn_rd(63 downto 0));



i_host_tst_in(74)<= tst_reg_wr              or
                    tst_buf_wr              or
                    tst_rxbuf_rd_last       or
                    tst_txbuf_wr_last       or
                    OR_reduce(tst_rx_engine_tst2) or
                    tst_dma_start           or tst_fw_rd or

                    OR_reduce(tst_rx_trn_dw_sel) or
                    tst_usr_txbuf_full_i    or
                    tst_host_dev_wr or
                    tst_usr_rxbuf_empty_i or OR_reduce(tst_irq_clr_cnt) or
                    tst_host_dev_rd or

                    tst_cfg_interrupt_n         or
                    tst_cfg_interrupt_rdy_n     or
                    tst_cfg_interrupt_assert_n;

i_host_tst_in(75)<= tst_trn_tdst_rdy_n or
                    tst_trn_rsof_n          or
                    tst_trn_reof_n          ;--or

--                    tst_trn_tsof_n          or
--                    tst_trn_teof_n          or
--                    tst_trn_tsrc_rdy_n      or
--
--                    tst_trn_tsrc_dsc_n;--     or

i_host_tst_in(76)<= OR_reduce(tst_trn_tbuf_av) or
                    OR_reduce(tst_dma_rxd);

i_host_tst_in(126 downto 77)<=(others=>'0');
i_host_tst_in(127)<=tst_trn_rsrc_rdy_n      or
                    tst_trn_rdst_rdy_n;-- or


--//Статусы устройств
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RDY_BIT)    <=i_cfg_rdy;
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RXRDY_BIT)  <=i_host_rxrdy(C_HDEV_CFG_DBUF);
i_host_dev_status(C_HREG_DEV_STATUS_CFG_TXRDY_BIT)  <=i_host_txrdy(C_HDEV_CFG_DBUF);

i_host_dev_status(C_HREG_DEV_STATUS_ETH_RDY_BIT)    <='1';
i_host_dev_status(C_HREG_DEV_STATUS_ETH_LINK_BIT)   <='0';

i_host_dev_status(C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT)<=OR_reduce(i_mem_ctrl_status.rdy);


--//Запись/Чтение данных устройств хоста
gen_dev_dbuf : for i in 0 to i_host_wr'length-1 generate
i_host_wr(i) <=i_host_dev_wr when i_host_devadr=CONV_STD_LOGIC_VECTOR(i, i_host_devadr'length) else '0';
i_host_rd(i) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(i, i_host_devadr'length) else '0';
i_host_txd(i)<=i_host_dev_txd;
--i_host_txd_rdy(i) <= i_host_dev_ctrl(C_HREG_DEV_CTRL_DRDY_BIT) when i_host_devadr=CONV_STD_LOGIC_VECTOR(i, i_host_devadr'length) else '0';
end generate gen_dev_dbuf;

i_host_dev_rxd<=i_host_rxd(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                (others=>'0');


--//Флаги (Host<-dev)
i_host_dev_opt_in(C_HDEV_OPTIN_TXFIFO_PFULL_BIT)<=i_host_txbuf_full(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                                                  '0';

i_host_dev_opt_in(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT)<=i_host_rxbuf_empty(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                                                  '0';

i_host_dev_opt_in(C_HDEV_OPTIN_MEMTRN_DONE_BIT)<=i_host_mem_status.done;
i_host_dev_opt_in(C_HDEV_OPTIN_VCTRL_FRMRK_M_BIT downto C_HDEV_OPTIN_VCTRL_FRMRK_L_BIT)<=(others=>'0');
i_host_dev_opt_in(C_HDEV_OPTIN_VCTRL_FRSKIP_M_BIT downto C_HDEV_OPTIN_VCTRL_FRSKIP_L_BIT)<=(others=>'0');


--//Прерывания
i_host_dev_irq(C_HIRQ_CFG_RX)<=i_host_irq(C_HIRQ_CFG_RX);

--//Обработка управляющих сигналов Хоста
i_host_mem_ctrl.dir       <=not i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT);
i_host_mem_ctrl.start     <=i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else '0';
i_host_mem_ctrl.adr       <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_ADR_M_BIT downto C_HDEV_OPTOUT_MEM_ADR_L_BIT);
i_host_mem_ctrl.req_len   <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_RQLEN_M_BIT downto C_HDEV_OPTOUT_MEM_RQLEN_L_BIT);
i_host_mem_ctrl.trnwr_len <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_TRNWR_LEN_M_BIT downto C_HDEV_OPTOUT_MEM_TRNWR_LEN_L_BIT);
i_host_mem_ctrl.trnrd_len <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_TRNRD_LEN_M_BIT downto C_HDEV_OPTOUT_MEM_TRNRD_LEN_L_BIT);

i_host_rst_all<=i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
--i_host_rst_eth<=i_host_gctrl(C_HREG_CTRL_RST_ETH_BIT);
--i_host_rst_mem<=i_host_gctrl(C_HREG_CTRL_RST_MEM_BIT);
--i_host_rddone_vctrl<=i_host_gctrl(C_HREG_CTRL_RDDONE_VCTRL_BIT);


i_host_devadr<=i_host_dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT);
--i_host_vchsel<=EXT(i_host_dev_ctrl(C_HREG_DEV_CTRL_VCH_M_BIT downto C_HREG_DEV_CTRL_VCH_L_BIT), i_host_vchsel'length);

--process(i_host_rst_n, g_host_clk)
--begin
--  if i_host_rst_n='0' then
--    for i in 0 to C_HDEV_COUNT-1 loop
--      i_hdev_dma_start(i)<='0';
--      hclk_hdev_dma_start(i)<='0';
--      hclk_hdev_dma_start_cnt(i)<=(others=>'0');
--    end loop;
--
--    hclk_hrddone_vctrl<='0';
--    hclk_hrddone_vctrl_cnt<=(others=>'0');
--
--  elsif g_host_clk'event and g_host_clk='1' then
--
--    for i in 0 to C_HDEV_COUNT-1 loop
--      --//импульс начала DMA транзакции
--      if i_host_devadr=i then
--        if i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT)='1' then
--          i_hdev_dma_start(i)<='1';
--        else
--          i_hdev_dma_start(i)<='0';
--        end if;
--      end if;
--    end loop;--//for
--
--    --//Расширитель импульсов:
--    for i in 0 to C_HDEV_COUNT-1 loop
--      --//Растягиваем импульс начала DMA транзакции
--      if i_hdev_dma_start(i)='1' then
--        hclk_hdev_dma_start(i)<='1';
--      elsif hclk_hdev_dma_start_cnt(i)="100" then
--        hclk_hdev_dma_start(i)<='0';
--      end if;
--
--      if hclk_hdev_dma_start(i)='0' then
--        hclk_hdev_dma_start_cnt(i)<=(others=>'0');
--      else
--        hclk_hdev_dma_start_cnt(i)<=hclk_hdev_dma_start_cnt(i)+1;
--      end if;
--    end loop;
--
--    --//Растягиваем импульс i_host_rddone_vctrl
--    if i_host_rddone_vctrl='1' then
--      hclk_hrddone_vctrl<='1';
--    elsif hclk_hrddone_vctrl_cnt="100" then
--      hclk_hrddone_vctrl<='0';
--    end if;
--
--    if hclk_hrddone_vctrl='0' then
--      hclk_hrddone_vctrl_cnt<=(others=>'0');
--    else
--      hclk_hrddone_vctrl_cnt<=hclk_hrddone_vctrl_cnt+1;
--    end if;
--  end if;
--end process;
--
----//Пересинхронизация управляющих сигналов Хоста
--process(i_host_rst_n, g_usr_highclk)
--begin
--  if i_host_rst_n='0' then
--    i_vctrl_hrd_start<='0';
--
--    i_vctrl_hrd_done<='0';
--    sr_vctrl_hrd_done<=(others=>'0');
--
--  elsif g_usr_highclk'event and g_usr_highclk='1' then
--    i_vctrl_hrd_start<=hclk_hdev_dma_start(C_HDEV_VCH_DBUF);
--
--    sr_vctrl_hrd_done(0)<=hclk_hrddone_vctrl;
--    sr_vctrl_hrd_done(1)<=sr_vctrl_hrd_done(0);
--    i_vctrl_hrd_done<=sr_vctrl_hrd_done(0) and not sr_vctrl_hrd_done(1);
--
--  end if;
--end process;


--***********************************************************
--Модуль Контроллера памяти
--***********************************************************
--Связь модуля dsn_host c ОЗУ
m_host2mem : pcie2mem_ctrl
generic map(
G_MEM_AWIDTH     => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH     => C_HDEV_DWIDTH,
G_MEM_BANK_M_BIT => C_HREG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT => C_HREG_MEM_ADR_BANK_L_BIT,
G_DBG            => G_SIM
)
port map(
-------------------------------
--Управление
-------------------------------
p_in_ctrl         => i_host_mem_ctrl,
p_out_status      => i_host_mem_status,

p_in_txd          => i_host_txd(C_HDEV_MEM_DBUF),
p_in_txd_wr       => i_host_wr(C_HDEV_MEM_DBUF),
p_out_txbuf_full  => i_host_txbuf_full(C_HDEV_MEM_DBUF),

p_out_rxd         => i_host_rxd(C_HDEV_MEM_DBUF),
p_in_rxd_rd       => i_host_rd(C_HDEV_MEM_DBUF),
p_out_rxbuf_empty => i_host_rxbuf_empty(C_HDEV_MEM_DBUF),

p_in_hclk         => g_host_clk,

-------------------------------
--Связь с mem_ctrl
-------------------------------
p_out_mem         => i_host_memin,
p_in_mem          => i_host_memout,

-------------------------------
--Технологический
-------------------------------
p_in_tst          => (others=>'0'),
p_out_tst         => i_host_mem_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk         => g_usr_highclk,
p_in_rst         => i_host_mem_rst
);

--//Подключаем арбитра ОЗУ к соотв банку
i_memin_bank(0)<=i_host_memin;
i_host_memout   <=i_memout_bank(0);

----//Подключаем устройства к арбитру ОЗУ
--i_memin_ch(0) <= i_host_memin;
--i_host_memout <= i_memout_ch(0);
--
----//Арбитр контроллера памяти
--m_mem_arb : mem_arb
--generic map(
--G_CH_COUNT   => 1,--selval(10#04#,10#03#, strcmp(C_PCFG_HDD_USE,"ON")),
--G_MEM_AWIDTH => C_AXI_AWIDTH, --C_HREG_MEM_ADR_LAST_BIT,
--G_MEM_DWIDTH => C_HDEV_DWIDTH
--)
--port map(
---------------------------------
----Связь с пользователями ОЗУ
---------------------------------
--p_in_memch  => i_memin_ch,
--p_out_memch => i_memout_ch,
--
---------------------------------
----Связь с mem_ctrl.vhd
---------------------------------
--p_out_mem   => i_arb_memin,
--p_in_mem    => i_arb_memout,
--
---------------------------------
----Технологический
---------------------------------
--p_in_tst    => (others=>'0'),
--p_out_tst   => i_arb_mem_tst_out,
--
---------------------------------
----System
---------------------------------
--p_in_clk    => g_usr_highclk,
--p_in_rst    => i_arb_mem_rst
--);
--
----//Подключаем арбитра ОЗУ к соотв банку
--i_memin_bank(0)<=i_arb_memin;
--i_arb_memout   <=i_memout_bank(0);

--//Core Memory controller
m_mem_ctrl : mem_ctrl
generic map(
G_SIM => G_SIM
)
port map(
------------------------------------
--User Post
------------------------------------
p_in_mem   => i_memin_bank,
p_out_mem  => i_memout_bank,

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem    => pin_out_phymem,
p_inout_phymem  => pin_inout_phymem,

------------------------------------
--Memory status
------------------------------------
p_out_status    => i_mem_ctrl_status,

------------------------------------
--System
------------------------------------
p_out_sys       => i_mem_ctrl_sysout,
p_in_sys        => i_mem_ctrl_sysin
);



--//#########################################
--//DBG
--//#########################################
pin_out_led(0)<=i_test01_led;
pin_out_led(1)<='0';
pin_out_led(2)<='0';
pin_out_led(3)<='0';
pin_out_led(4)<='0';
pin_out_led(5)<='0';
pin_out_led(6)<='0';
pin_out_led(7)<='0';


m_gt_03_test: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#,
G_CLK_T05us   =>10#75#
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_host_clk,
p_in_rst       => i_cfg_rst
);



process(g_host_clk)
begin
if g_host_clk'event and g_host_clk='1' then

tst_cfg_interrupt_n              <=i_host_tst2_out(0)             ;--p_out_tst(0)             <=cfg_interrupt_n;
tst_cfg_interrupt_rdy_n          <=i_host_tst2_out(1)             ;--p_out_tst(1)             <=cfg_interrupt_rdy_n;
tst_cfg_interrupt_assert_n       <=i_host_tst2_out(2)             ;--p_out_tst(2)             <=cfg_interrupt_assert_n;

tst_trn_tsof_n                   <=i_host_tst2_out(4)             ;--p_out_tst(4)             <=trn_tsof_n;
tst_trn_teof_n                   <=i_host_tst2_out(5)             ;--p_out_tst(5)             <=trn_teof_n;
tst_trn_tsrc_rdy_n               <=i_host_tst2_out(6)             ;--p_out_tst(6)             <=trn_tsrc_rdy_n;
tst_trn_tdst_rdy_n               <=i_host_tst2_out(7)             ;--p_out_tst(7)             <=trn_tdst_rdy_n;
tst_trn_tsrc_dsc_n               <=i_host_tst2_out(8)             ;--p_out_tst(8)             <=trn_tsrc_dsc_n;

tst_trn_rsof_n                   <=i_host_tst2_out(9)             ;--p_out_tst(9)             <=trn_rsof_n;
tst_trn_reof_n                   <=i_host_tst2_out(10)            ;--p_out_tst(10)            <=trn_reof_n;
tst_trn_rsrc_rdy_n               <=i_host_tst2_out(11)            ;--p_out_tst(11)            <=trn_rsrc_rdy_n;
tst_trn_rsrc_dsc_n               <=i_host_tst2_out(12)            ;--p_out_tst(12)            <=trn_rsrc_dsc_n;
tst_trn_rdst_rdy_n               <=i_host_tst2_out(13)            ;--p_out_tst(13)            <=trn_rdst_rdy_n;

tst_trn_rrem_n(0)                <=i_host_tst2_out(17)            ;--p_out_tst(17)            <=trn_rrem_n(0);
tst_trn_rrem_n(1)                <=i_host_tst2_out(18)            ;--p_out_tst(18)            <=trn_rrem_n(1);
tst_trn_rd                       <=i_host_tst2_out(146 downto 19) ;--p_out_tst(146 downto 83) <=trn_rd(127 downto 64);
tst_trn_tbuf_av                  <=i_host_tst2_out(167 downto 163);--p_out_tst(167 downto 163)<=trn_tbuf_av;
tst_trn_trem_n                   <=i_host_tst2_out(170 downto 169);--<=trn_trem_n;


tst_reg_wr                       <=i_host_tst_out(63)            ;--p_out_tst(63)            <=vrsk_reg_bar and (p_in_reg_wr or i_reg_rd);
tst_buf_wr                       <=i_host_tst_out(125)           ;--p_out_tst(125)           <=p_in_txbuf_wr or p_in_rxbuf_rd;
tst_rxbuf_rd_last                <=i_host_tst_out(126)           ;--p_out_tst(126)           <=p_in_rxbuf_rd_last;
tst_txbuf_wr_last                <=i_host_tst_out(127)           ;--p_out_tst(127)           <=p_in_txbuf_wr_last;
tst_rx_engine_tst2               <=i_host_tst_out(41 downto 32)  ;--p_out_tst(47 downto 32)  <=EXT(p_in_rx_engine_tst2, 16);--p_in_mrd_pkt_len_tst(15 downto 0);
tst_rx_trn_dw_sel                <=i_host_tst_out(41 downto 40)  ;--p_out_tst(47 downto 32)  <=EXT(p_in_rx_engine_tst2, 16);--p_in_mrd_pkt_len_tst(15 downto 0);
tst_usr_txbuf_full_i             <=i_host_dev_opt_in(C_HDEV_OPTIN_TXFIFO_PFULL_BIT);
tst_usr_rxbuf_empty_i            <=i_host_dev_opt_in(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT);

tst_host_dev_rd                  <=i_host_dev_rd;
tst_host_dev_wr                  <=i_host_dev_wr;
tst_reg_val                      <=i_host_dev_txd;
tst_dma_rxd                      <=i_host_dev_rxd;

tst_dmatrn_init                  <=i_host_tst_out(123)           ;--p_out_tst(123)           <=i_dmatrn_init;
tst_dma_start                    <=i_host_tst_out(124)           ;--p_out_tst(124)           <=i_dma_start;

tst_fw_rd <= i_host_tst_out(120);--p_out_tst(120)           <=p_in_throttle_tst(0) or i_tst_rd; --//mrd_work_throttle

if i_host_tst_out(96)='1' then
  tst_irq_clr_cnt<=tst_irq_clr_cnt + 1;
end if;

end if;
end process;


end architecture;


--m_dbgcs_icon : dbgcs_iconx1
--port map(
--CONTROL0 => i_dbgcs_pcie
--);
--
--m_dbgcs_pcie : dbgcs_sata_raid_b
--port map(
--CONTROL => i_dbgcs_pcie,
--CLK     => g_host_clk,
--DATA    => i_pcie_dbgcs_data(255 downto 0),
--TRIG0   => i_pcie_dbgcs_trig(49 downto 0)
--);
--
----TRIG
--i_pcie_dbgcs_trig(0)             <=i_host_tst2_out(4)             ;--p_out_tst(4)             <=trn_tsof_n;
--i_pcie_dbgcs_trig(1)             <=i_host_tst2_out(5)             ;--p_out_tst(5)             <=trn_teof_n;
--i_pcie_dbgcs_trig(2)             <=i_host_tst2_out(6)             ;--p_out_tst(6)             <=trn_tsrc_rdy_n;
--i_pcie_dbgcs_trig(3)             <=i_host_tst2_out(7)             ;--p_out_tst(7)             <=trn_tdst_rdy_n;
--
--i_pcie_dbgcs_trig(4)             <=i_host_tst2_out(9)             ;--p_out_tst(9)             <=trn_rsof_n;
--i_pcie_dbgcs_trig(5)             <=i_host_tst2_out(10)            ;--p_out_tst(10)            <=trn_reof_n;
--i_pcie_dbgcs_trig(6)             <=i_host_tst2_out(11)            ;--p_out_tst(11)            <=trn_rsrc_rdy_n;
--i_pcie_dbgcs_trig(7)             <=i_host_tst2_out(12)            ;--p_out_tst(12)            <=trn_rsrc_dsc_n;
--
--i_pcie_dbgcs_trig(8)             <=i_host_tst_out(63)             ;--p_out_tst(63)            <=vrsk_reg_bar and (p_in_reg_wr or i_reg_rd);
--i_pcie_dbgcs_trig(9)             <=i_host_tst_out(125)            ;--p_out_tst(125)           <=p_in_txbuf_wr or p_in_rxbuf_rd;
--
--i_pcie_dbgcs_trig(10)            <=i_host_tst_out(123)           ;--p_out_tst(123)           <=i_dmatrn_init;
--i_pcie_dbgcs_trig(11)            <=i_host_tst_out(124)           ;--p_out_tst(124)           <=i_dma_start;
--
--
----DATA
--i_pcie_dbgcs_data(0)             <=i_host_tst2_out(0)             ;--p_out_tst(0)             <=cfg_interrupt_n;
--i_pcie_dbgcs_data(1)             <=i_host_tst2_out(1)             ;--p_out_tst(1)             <=cfg_interrupt_rdy_n;
--i_pcie_dbgcs_data(2)             <=i_host_tst2_out(2)             ;--p_out_tst(2)             <=cfg_interrupt_assert_n;
--i_pcie_dbgcs_data(3)             <=i_host_tst2_out(3)             ;--p_out_tst(3)             <=cfg_interrupt_msienable;--cfg_command(10);
--i_pcie_dbgcs_data(4)             <=i_host_tst2_out(4)             ;--p_out_tst(4)             <=trn_tsof_n;
--i_pcie_dbgcs_data(5)             <=i_host_tst2_out(5)             ;--p_out_tst(5)             <=trn_teof_n;
--i_pcie_dbgcs_data(6)             <=i_host_tst2_out(6)             ;--p_out_tst(6)             <=trn_tsrc_rdy_n;
--i_pcie_dbgcs_data(7)             <=i_host_tst2_out(7)             ;--p_out_tst(7)             <=trn_tdst_rdy_n;
--i_pcie_dbgcs_data(8)             <=i_host_tst2_out(8)             ;--p_out_tst(8)             <=trn_tsrc_dsc_n;
--i_pcie_dbgcs_data(9)             <=i_host_tst2_out(9)             ;--p_out_tst(9)             <=trn_rsof_n;
--i_pcie_dbgcs_data(10)            <=i_host_tst2_out(10)            ;--p_out_tst(10)            <=trn_reof_n;
--i_pcie_dbgcs_data(11)            <=i_host_tst2_out(11)            ;--p_out_tst(11)            <=trn_rsrc_rdy_n;
--i_pcie_dbgcs_data(12)            <=i_host_tst2_out(12)            ;--p_out_tst(12)            <=trn_rsrc_dsc_n;
--i_pcie_dbgcs_data(13)            <=i_host_tst2_out(13)            ;--p_out_tst(13)            <=trn_rdst_rdy_n;
--i_pcie_dbgcs_data(14)            <=i_host_tst2_out(14)            ;--p_out_tst(14)            <=trn_rbar_hit_n(0);
--i_pcie_dbgcs_data(15)            <=i_host_tst2_out(15)            ;--p_out_tst(15)            <=trn_rbar_hit_n(1);
--i_pcie_dbgcs_data(16)            <=i_host_tst2_out(16)            ;--p_out_tst(16)            <=cfg_command(2);--//cfg_bus_mstr_enable
--i_pcie_dbgcs_data(17)            <=i_host_tst2_out(17)            ;--p_out_tst(17)            <=trn_rrem_n(0);
--i_pcie_dbgcs_data(18)            <=i_host_tst2_out(18)            ;--p_out_tst(18)            <=trn_rrem_n(1);
--i_pcie_dbgcs_data(82 downto 19)  <=i_host_tst2_out(82 downto 19)  ;--p_out_tst(82 downto 19)  <=trn_td(127 downto 64);
--i_pcie_dbgcs_data(146 downto 83) <=i_host_tst2_out(146 downto 83) ;--p_out_tst(146 downto 83) <=trn_rd(127 downto 64);
--i_pcie_dbgcs_data(162 downto 147)<=i_host_tst2_out(162 downto 147);--p_out_tst(162 downto 147)<=trn_rrem_n_old;--(others=>'0');
--i_pcie_dbgcs_data(167 downto 163)<=i_host_tst2_out(167 downto 163);--p_out_tst(167 downto 163)<=trn_tbuf_av;
--
--
--i_pcie_dbgcs_data(168)           <=i_host_tst_out(63)            ;--p_out_tst(63)            <=vrsk_reg_bar and (p_in_reg_wr or i_reg_rd);
--i_pcie_dbgcs_data(169)           <=i_host_tst_out(125)           ;--p_out_tst(125)           <=p_in_txbuf_wr or p_in_rxbuf_rd;
--i_pcie_dbgcs_data(170)           <=i_host_tst_out(126)           ;--p_out_tst(126)           <=p_in_rxbuf_rd_last;
--i_pcie_dbgcs_data(171)           <=i_host_tst_out(127)           ;--p_out_tst(127)           <=p_in_txbuf_wr_last;
--i_pcie_dbgcs_data(181 downto 172)<=i_host_tst_out(41 downto 32)  ;--p_out_tst(47 downto 32)  <=EXT(p_in_rx_engine_tst2, 16);--p_in_mrd_pkt_len_tst(15 downto 0);
--i_pcie_dbgcs_data(213 downto 182)<=i_host_tst_out(31 downto 0)   ;--p_out_tst(31 downto 0)   <=v_reg_tst0;
----i_pcie_dbgcs_data(208 downto 177)<=i_host_dev_txd;
--i_pcie_dbgcs_data(245 downto 214)<=i_host_dev_rxd;
--
--i_pcie_dbgcs_data(246)           <=i_host_tst_out(123)           ;--p_out_tst(123)           <=i_dmatrn_init;
--i_pcie_dbgcs_data(247)           <=i_host_tst_out(124)           ;--p_out_tst(124)           <=i_dma_start;
--
----p_out_tst(31 downto 0)  <=v_reg_tst0;
------p_out_tst(63 downto 32) <=v_reg_tst1;
----p_out_tst(47 downto 32) <=EXT(p_in_rx_engine_tst2, 16);--p_in_mrd_pkt_len_tst(15 downto 0);
------p_out_tst(39 downto 32) <=i_dmabuf_num_cnt;
------p_out_tst(47 downto 40) <=i_dmabuf_done_cnt;
----p_out_tst(55 downto 48) <=i_dmabuf_count;
----p_out_tst(57 downto 56) <=i_dmatrn_mem_done;
----p_out_tst(61 downto 58) <=i_hdev_adr;
----p_out_tst(62)           <=p_in_mrd_rcv_err;
----p_out_tst(63)           <=vrsk_reg_bar and (p_in_reg_wr or i_reg_rd);
----p_out_tst(95 downto 64) <=p_in_mrd_rcv_size;
----p_out_tst(96)           <=i_irq_clr;
----p_out_tst(100 downto 97)<=i_irq_num(3 downto 0);
----p_out_tst(108 downto 101)<=p_in_irq_status(7 downto 0);
----p_out_tst(116 downto 109)<=EXT(i_irq_set(7 downto 0), 8);
----p_out_tst(117)           <=i_dma_mwr_done and sr_dmatrn_mwr_done;
----p_out_tst(118)           <=i_dma_mrd_done and sr_dmatrn_mrd_done;
----p_out_tst(119)           <=i_dmatrn_mwr_done;
----p_out_tst(120)           <=p_in_throttle_tst(0); --//mrd_work_throttle
----p_out_tst(121)           <=i_mrd_rcv_size_ok;
----p_out_tst(122)           <=i_dmatrn_mrd_done;
----p_out_tst(123)           <=i_dmatrn_init;
----p_out_tst(124)           <=i_dma_start;
----p_out_tst(125)           <=p_in_txbuf_wr or p_in_rxbuf_rd;
----p_out_tst(126)           <=p_in_rxbuf_rd_last;
----p_out_tst(127)           <=p_in_txbuf_wr_last;

