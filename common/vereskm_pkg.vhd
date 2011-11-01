-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : vereskm_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.memory_ctrl_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.dsn_video_ctrl_pkg.all;
use work.sata_glob_pkg.all;
use work.dsn_hdd_pkg.all;
use work.sata_testgen_pkg.all;


package vereskm_pkg is


component dsn_track_nik
generic(
G_SIM                : string:="OFF";
G_MODULE_USE         : string:="ON";

G_MEM_BANK_MSB_BIT   : integer:=29;
G_MEM_BANK_LSB_BIT   : integer:=28;

G_MEM_VCH_MSB_BIT    : integer:=25;
G_MEM_VCH_LSB_BIT    : integer:=24;
G_MEM_VFRAME_LSB_BIT : integer:=23;
G_MEM_VFRAME_MSB_BIT : integer:=23;
G_MEM_VROW_MSB_BIT   : integer:=22;
G_MEM_VROW_LSB_BIT   : integer:=12
);
port
(
-------------------------------
-- Управление от Хоста
-------------------------------
p_in_host_clk        : in   std_logic;

p_in_cfg_adr         : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld      : in   std_logic;
p_in_cfg_adr_fifo    : in   std_logic;

p_in_cfg_txdata      : in   std_logic_vector(15 downto 0);
p_in_cfg_wd          : in   std_logic;

p_out_cfg_rxdata     : out  std_logic_vector(15 downto 0);
p_in_cfg_rd          : in   std_logic;

p_in_cfg_done        : in   std_logic;

-------------------------------
-- Связь с ХОСТ
-------------------------------
p_out_trc_hirq       : out   std_logic;
p_out_trc_hdrdy      : out   std_logic;
p_out_trc_hfrmrk     : out   std_logic_vector(31 downto 0);
p_in_trc_hrddone     : in    std_logic;

p_out_trc_bufo_dout  : out   std_logic_vector(31 downto 0);
p_in_trc_bufo_rd     : in    std_logic;
p_out_trc_bufo_empty : out   std_logic;

p_out_trc_busy       : out   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);

-------------------------------
-- Связь с VCTRL
-------------------------------
p_in_vctrl_vrdprms   : in    TReaderVCHParams;
p_in_vctrl_vfrrdy    : in    std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
p_in_vctrl_vbuf      : in    TVfrBufs;
p_in_vctrl_vrowmrk   : in    TVMrks;

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_memarb_req     : out   std_logic;
p_in_memarb_en       : in    std_logic;

p_out_mem_bank1h     : out   std_logic_vector(15 downto 0);
p_out_mem_ce         : out   std_logic;
p_out_mem_cw         : out   std_logic;
p_out_mem_rd         : out   std_logic;
p_out_mem_wr         : out   std_logic;
p_out_mem_term       : out   std_logic;
p_out_mem_adr        : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be         : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din        : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout        : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf          : in    std_logic;
p_in_mem_wpf         : in    std_logic;
p_in_mem_re          : in    std_logic;
p_in_mem_rpe         : in    std_logic;

p_out_mem_clk        : out   std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;

component dsn_track
generic(
G_SIM                : string:="OFF";
G_MODULE_USE         : string:="ON";

G_MEM_BANK_MSB_BIT   : integer:=29;
G_MEM_BANK_LSB_BIT   : integer:=28;

G_MEM_VCH_MSB_BIT    : integer:=25;
G_MEM_VCH_LSB_BIT    : integer:=24;
G_MEM_VFRAME_LSB_BIT : integer:=23;
G_MEM_VFRAME_MSB_BIT : integer:=23;
G_MEM_VROW_MSB_BIT   : integer:=22;
G_MEM_VROW_LSB_BIT   : integer:=12
);
port
(
-------------------------------
-- Управление от Хоста
-------------------------------
p_in_host_clk        : in   std_logic;

p_in_cfg_adr         : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld      : in   std_logic;
p_in_cfg_adr_fifo    : in   std_logic;

p_in_cfg_txdata      : in   std_logic_vector(15 downto 0);
p_in_cfg_wd          : in   std_logic;

p_out_cfg_rxdata     : out  std_logic_vector(15 downto 0);
p_in_cfg_rd          : in   std_logic;

p_in_cfg_done        : in   std_logic;

-------------------------------
-- Связь с ХОСТ
-------------------------------
p_out_trc_hirq       : out   std_logic;
p_out_trc_hdrdy      : out   std_logic;
p_out_trc_hfrmrk     : out   std_logic_vector(31 downto 0);
p_in_trc_hrddone     : in    std_logic;

p_out_trc_bufo_dout  : out   std_logic_vector(31 downto 0);
p_in_trc_bufo_rd     : in    std_logic;
p_out_trc_bufo_empty : out   std_logic;

p_out_trc_busy       : out   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);

-------------------------------
-- Связь с VCTRL
-------------------------------
p_in_vctrl_vrdprms   : in    TReaderVCHParams;
p_in_vctrl_vfrrdy    : in    std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
p_in_vctrl_vbuf      : in    TVfrBufs;
p_in_vctrl_vrowmrk   : in    TVMrks;

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_memarb_req     : out   std_logic;
p_in_memarb_en       : in    std_logic;

p_out_mem_bank1h     : out   std_logic_vector(15 downto 0);
p_out_mem_ce         : out   std_logic;
p_out_mem_cw         : out   std_logic;
p_out_mem_rd         : out   std_logic;
p_out_mem_wr         : out   std_logic;
p_out_mem_term       : out   std_logic;
p_out_mem_adr        : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be         : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din        : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout        : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf          : in    std_logic;
p_in_mem_wpf         : in    std_logic;
p_in_mem_re          : in    std_logic;
p_in_mem_rpe         : in    std_logic;

p_out_mem_clk        : out   std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;

component dsn_hdd_rambuf is
generic
(
G_MODULE_USE           : string:="ON";
G_RAMBUF_SIZE          : integer:=23;
G_DBGCS                : string:="OFF";
G_SIM                  : string:="OFF"
);
port
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         : in    THDDRBufCfg;
p_out_rbuf_status     : out   THDDRBufStatus;

--//--------------------------
--//Связь с буфером видеоданных
--//--------------------------
p_in_vbuf_dout        : in    std_logic_vector(31 downto 0);
p_out_vbuf_rd         : out   std_logic;
p_in_vbuf_empty       : in    std_logic;
p_in_vbuf_full        : in    std_logic;
p_in_vbuf_pfull       : in    std_logic;
p_in_vbuf_wrcnt       : in    std_logic_vector(3 downto 0);

--//--------------------------
--//Связь с модулем HDD
--//--------------------------
p_out_hdd_txd         : out   std_logic_vector(31 downto 0);
p_out_hdd_txd_wr      : out   std_logic;
p_in_hdd_txbuf_pfull  : in    std_logic;
p_in_hdd_txbuf_full   : in    std_logic;
p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          : in    std_logic_vector(31 downto 0);
p_out_hdd_rxd_rd      : out   std_logic;
p_in_hdd_rxbuf_empty  : in    std_logic;
p_in_hdd_rxbuf_pempty : in    std_logic;

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_memarb_req      : out   std_logic;
p_in_memarb_en        : in    std_logic;

p_out_mem_bank1h      : out   std_logic_vector(15 downto 0);
p_out_mem_ce          : out   std_logic;
p_out_mem_cw          : out   std_logic;
p_out_mem_rd          : out   std_logic;
p_out_mem_wr          : out   std_logic;
p_out_mem_term        : out   std_logic;
p_out_mem_adr         : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be          : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din         : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout         : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf           : in    std_logic;
p_in_mem_wpf          : in    std_logic;
p_in_mem_re           : in    std_logic;
p_in_mem_rpe          : in    std_logic;

p_out_mem_clk         : out   std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);
p_out_dbgcs           : out   TSH_ila;

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

component dsn_host
generic
(
G_DBG      : string:="OFF";
G_SIM_HOST : string:="OFF";
G_SIM_PCIE : std_logic:='0'
);
port
(
--------------------------------------------------
-- Связь с хостом по Local bus
--------------------------------------------------
lad                 : inout std_logic_vector(31 downto 0);
lbe_l               : in    std_logic_vector(32/8-1 downto 0);
lads_l              : in    std_logic;
lwrite              : in    std_logic;
lblast_l            : in    std_logic;
lbterm_l            : inout std_logic;
lready_l            : inout std_logic;
fholda              : in    std_logic;
finto_l             : out   std_logic;
lclk                : in    std_logic;

--//-----------------------------
--// PCI-Express
--//-----------------------------
p_out_pciexp_txp    : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_out_pciexp_txn    : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxp     : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxn     : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);

p_in_pciexp_gt_clkin   : in    std_logic;
p_out_pciexp_gt_clkout : out   std_logic;

--//-----------------------------------------------------
--//Пользовательский порт
--//-----------------------------------------------------
p_in_usr_tst        : in    std_logic_vector(127 downto 0);
p_out_usr_tst       : out   std_logic_vector(127 downto 0);

p_out_hclk          : out   std_logic;
p_out_gctrl         : out   std_logic_vector(31 downto 0);

p_out_dev_ctrl      : out   std_logic_vector(31 downto 0);
p_out_dev_din       : out   std_logic_vector(31 downto 0);
p_in_dev_dout       : in    std_logic_vector(31 downto 0);
p_out_dev_wd        : out   std_logic;
p_out_dev_rd        : out   std_logic;
p_in_dev_flag       : in    std_logic_vector(7 downto 0);
p_in_dev_status     : in    std_logic_vector(31 downto 0);
p_in_dev_irq        : in    std_logic_vector(31 downto 0);
p_in_dev_option     : in    std_logic_vector(127 downto 0);

p_out_mem_bank1h    : out   std_logic_vector(15 downto 0);
p_out_mem_ce        : out   std_logic;
p_out_mem_cw        : out   std_logic;
p_out_mem_rd        : out   std_logic;
p_out_mem_wr        : out   std_logic;
p_out_mem_term      : out   std_logic;
p_out_mem_adr       : out   std_logic_vector(31 downto 0);
p_out_mem_be        : out   std_logic_vector(32/8 - 1 downto 0);
p_out_mem_din       : out   std_logic_vector(31 downto 0);
p_in_mem_dout       : in    std_logic_vector(31 downto 0);

p_in_mem_wf         : in    std_logic;
p_in_mem_wpf        : in    std_logic;
p_in_mem_re         : in    std_logic;
p_in_mem_rpe        : in    std_logic;

--------------------------------------------------
--// Технологический
--------------------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(171 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_out_module_rdy    : out   std_logic;
p_in_rst_n          : in    std_logic
);
end component;

component dsn_timer
port
(
-------------------------------
-- Конфигурирование модуля dsn_timer.vhd (host_clk domain)
-------------------------------
p_in_host_clk         : in   std_logic;

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld       : in   std_logic;
p_in_cfg_adr_fifo     : in   std_logic;

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);
p_in_cfg_wd           : in   std_logic;

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);
p_in_cfg_rd           : in   std_logic;

p_in_cfg_done         : in   std_logic;

-------------------------------
-- STATUS модуля dsn_timer.vhd
-------------------------------
p_in_tmr_clk          : in   std_logic;
p_out_tmr_rdy         : out  std_logic;
p_out_tmr_error       : out  std_logic;

p_out_tmr_irq         : out  std_logic_vector(C_DSN_TMR_COUNT_TMR-1 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst            : in    std_logic
);
end component;

component dsn_switch
port
(
-------------------------------
-- Конфигурирование модуля DSN_SWITCH.VHD (host_clk domain)
-------------------------------
p_in_cfg_clk              : in   std_logic;

p_in_cfg_adr              : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld           : in   std_logic;
p_in_cfg_adr_fifo         : in   std_logic;

p_in_cfg_txdata           : in   std_logic_vector(15 downto 0);
p_in_cfg_wd               : in   std_logic;

p_out_cfg_rxdata          : out  std_logic_vector(15 downto 0);
p_in_cfg_rd               : in   std_logic;

p_in_cfg_done             : in   std_logic;

-------------------------------
-- Связь с Хостом (host_clk domain)
-------------------------------
p_in_host_clk             : in   std_logic;

-- Связь Хост <-> ETH(dsn_eth.vhd)
p_out_host_eth_rxd_irq    : out  std_logic;
p_out_host_eth_rxd_rdy    : out  std_logic;
p_out_host_eth_rxd        : out  std_logic_vector(31 downto 0);
p_in_host_eth_rd          : in   std_logic;

p_out_host_eth_txbuf_rdy  : out  std_logic;
p_in_host_eth_txd         : in   std_logic_vector(31 downto 0);
p_in_host_eth_wr          : in   std_logic;

-- Связь Хост <-> VideoBUF
p_out_host_vbuf_dout      : out  std_logic_vector(31 downto 0);
p_in_host_vbuf_rd         : in   std_logic;
p_out_host_vbuf_empty     : out  std_logic;

-------------------------------
-- Связь с Накопителем(dsn_hdd.vhd)
-------------------------------
p_in_hdd_tstgen           : in   THDDTstGen;
p_in_hdd_vbuf_rdclk       : in   std_logic;

p_in_hdd_vbuf_dout        : out  std_logic_vector(31 downto 0);
p_in_hdd_vbuf_rd          : in   std_logic;
p_out_hdd_vbuf_empty      : out  std_logic;
p_out_hdd_vbuf_full       : out  std_logic;
p_out_hdd_vbuf_pfull      : out  std_logic;
p_out_hdd_vbuf_wrcnt      : out  std_logic_vector(3 downto 0);

-------------------------------
-- Связь с EthG(Оптика)(dsn_optic.vhd) (ethg_clk domain)
-------------------------------
p_in_eth_clk              : in   std_logic;

p_in_eth_rxd_sof          : in   std_logic;
p_in_eth_rxd_eof          : in   std_logic;
p_in_eth_rxbuf_din        : in   std_logic_vector(31 downto 0);
p_in_eth_rxbuf_wr         : in   std_logic;
p_out_eth_rxbuf_empty     : out  std_logic;
p_out_eth_rxbuf_full      : out  std_logic;

--p_out_eth_txd_rdy         : out  std_logic;
p_out_eth_txbuf_dout      : out  std_logic_vector(31 downto 0);
p_in_eth_txbuf_rd         : in   std_logic;
p_out_eth_txbuf_empty     : out  std_logic;
p_out_eth_txbuf_full      : out  std_logic;

-------------------------------
-- Связь с Модулем Видео контроллера(dsn_video_ctrl.vhd) (trc_clk domain)
-------------------------------
p_in_vctrl_clk            : in   std_logic;

p_out_vctrl_vbufin_rdy    : out  std_logic;
p_out_vctrl_vbufin_dout   : out  std_logic_vector(31 downto 0);
p_in_vctrl_vbufin_rd      : in   std_logic;
p_out_vctrl_vbufin_empty  : out  std_logic;
p_out_vctrl_vbufin_full   : out  std_logic;
p_out_vctrl_vbufin_pfull  : out  std_logic;

p_in_vctrl_vbufout_din    : in   std_logic_vector(31 downto 0);
p_in_vctrl_vbufout_wr     : in   std_logic;
p_out_vctrl_vbufout_empty : out  std_logic;
p_out_vctrl_vbufout_full  : out  std_logic;

-------------------------------
-- Связь с Модулем Тестирования(dsn_testing.vhd)
-------------------------------
p_out_dsntst_bufclk       : out  std_logic;

p_in_dsntst_txd_rdy       : in   std_logic;
p_in_dsntst_txbuf_din     : in   std_logic_vector(31 downto 0);
p_in_dsntst_txbuf_wr      : in   std_logic;
p_out_dsntst_txbuf_empty  : out  std_logic;
p_out_dsntst_txbuf_full   : out  std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst                  : in    std_logic_vector(31 downto 0);
p_out_tst                 : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst     : in    std_logic
);
end component;

component dsn_video_ctrl
generic(
G_SIMPLE : string:="OFF";
G_SIM    : string:="OFF"
);
port
(
-------------------------------
-- Конфигурирование модуля dsn_video_ctrl.vhd (host_clk domain)
-------------------------------
p_in_host_clk         : in   std_logic;

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld       : in   std_logic;
p_in_cfg_adr_fifo     : in   std_logic;

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);
p_in_cfg_wd           : in   std_logic;

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);
p_in_cfg_rd           : in   std_logic;

p_in_cfg_done         : in   std_logic;

-------------------------------
-- Связь с ХОСТ
-------------------------------
p_in_vctrl_hrdchsel   : in    std_logic_vector(3 downto 0);
p_in_vctrl_hrdstart   : in    std_logic;
p_in_vctrl_hrddone    : in    std_logic;
p_out_vctrl_hirq      : out   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
p_out_vctrl_hdrdy     : out   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
p_out_vctrl_hfrmrk    : out   std_logic_vector(31 downto 0);

-------------------------------
-- STATUS модуля dsn_video_ctrl.vhd
-------------------------------
p_out_vctrl_modrdy    : out   std_logic;
p_out_vctrl_moderr    : out   std_logic;
p_out_vctrl_rd_done   : out   std_logic;

p_out_vctrl_vrdprm    : out   TReaderVCHParams;
p_out_vctrl_vfrrdy    : out   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
p_out_vctrl_vrowmrk   : out   TVMrks;

--//--------------------------
--//Связь с модулем слежения
--//--------------------------
p_in_trc_busy         : in    std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
p_out_trc_vbuf        : out   TVfrBufs;

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_vbuf_clk        : out   std_logic;

p_in_vbufin_rdy       : in    std_logic;
p_in_vbufin_dout      : in    std_logic_vector(31 downto 0);
p_out_vbufin_dout_rd  : out   std_logic;
p_in_vbufin_empty     : in    std_logic;
p_in_vbufin_full      : in    std_logic;
p_in_vbufin_pfull     : in    std_logic;

p_out_vbufout_din     : out   std_logic_vector(31 downto 0);
p_out_vbufout_din_wd  : out   std_logic;
p_in_vbufout_empty    : in    std_logic;
p_in_vbufout_full     : in    std_logic;

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
--//CH WRITE
p_out_memarb_wrreq    : out   std_logic;
p_in_memarb_wren      : in    std_logic;

p_out_memwr_bank1h    : out   std_logic_vector(15 downto 0);
p_out_memwr_ce        : out   std_logic;
p_out_memwr_cw        : out   std_logic;
p_out_memwr_rd        : out   std_logic;
p_out_memwr_wr        : out   std_logic;
p_out_memwr_term      : out   std_logic;
p_out_memwr_adr       : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_memwr_be        : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_memwr_din       : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_memwr_dout       : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_memwr_wf         : in    std_logic;
p_in_memwr_wpf        : in    std_logic;
p_in_memwr_re         : in    std_logic;
p_in_memwr_rpe        : in    std_logic;

--//CH READ
p_out_memarb_rdreq    : out   std_logic;
p_in_memarb_rden      : in    std_logic;

p_out_memrd_bank1h    : out   std_logic_vector(15 downto 0);
p_out_memrd_ce        : out   std_logic;
p_out_memrd_cw        : out   std_logic;
p_out_memrd_rd        : out   std_logic;
p_out_memrd_wr        : out   std_logic;
p_out_memrd_term      : out   std_logic;
p_out_memrd_adr       : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_memrd_be        : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_memrd_din       : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_memrd_dout       : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_memrd_wf         : in    std_logic;
p_in_memrd_wpf        : in    std_logic;
p_in_memrd_re         : in    std_logic;
p_in_memrd_rpe        : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

component vtester_v01
generic
(
G_SIM        : string:="OFF"
);
port
(
-------------------------------
-- Управление от Хоста
-------------------------------
p_in_host_clk         : in   std_logic;

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld       : in   std_logic;
p_in_cfg_adr_fifo     : in   std_logic;

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);
p_in_cfg_wd           : in   std_logic;

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);
p_in_cfg_rd           : in   std_logic;

p_in_cfg_done         : in   std_logic;

-------------------------------
-- STATUS модуля dsn_testing.VHD
-------------------------------
p_out_module_rdy      : out  std_logic;
p_out_module_error    : out  std_logic;

-------------------------------
--Связь с выходным буфером
-------------------------------
p_out_dst_dout_rdy   : out   std_logic;
p_out_dst_dout       : out   std_logic_vector(31 downto 0);
p_out_dst_dout_wd    : out   std_logic;
p_in_dst_rdy         : in    std_logic;
--p_in_dst_clk         : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_tmrclk  : in    std_logic;

p_in_clk     : in    std_logic;
p_in_rst     : in    std_logic
);
end component;



end vereskm_pkg;


package body vereskm_pkg is

end vereskm_pkg;






