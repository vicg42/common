-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 16.01.2013 13:02:42
-- Module Name : hscam_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.prj_cfg.all;
use work.prj_def.all;
use work.dsn_video_ctrl_pkg.all;
use work.pcie_pkg.all;
use work.mem_wr_pkg.all;
use work.prom_phypin_pkg.all;

package hscam_pkg is

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
p_out_pciexp_txp  : out   std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
p_out_pciexp_txn  : out   std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
p_in_pciexp_rxp   : in    std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);
p_in_pciexp_rxn   : in    std_logic_vector(G_PCIE_LINK_WIDTH - 1 downto 0);

p_in_pciexp_gt_clkin   : in    std_logic;
p_out_pciexp_gt_clkout : out   std_logic;

-------------------------------
--Пользовательский порт
-------------------------------
p_out_hclk        : out   std_logic;
p_out_gctrl       : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--Управление внешними устройствами
p_out_dev_ctrl    : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din     : out   std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_in_dev_dout     : in    std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_out_dev_wr      : out   std_logic;
p_out_dev_rd      : out   std_logic;
p_in_dev_status   : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq      : in    std_logic_vector(C_HIRQ_COUNT_MAX - 1 downto 0);
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

component dsn_timer
port(
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

p_out_tmr_irq         : out  std_logic_vector(C_TMR_COUNT - 1 downto 0);
p_out_tmr_en          : out  std_logic_vector(C_TMR_COUNT - 1 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst            : in    std_logic
);
end component;

component dsn_video_ctrl
generic(
G_USR_OPT : std_logic_vector(7 downto 0):=(others=>'0');
G_DBGCS  : string:="OFF";
G_ROTATE : string:="OFF";
G_ROTATE_BUF_COUNT: integer:=16;
G_SIMPLE : string:="OFF";
G_SIM    : string:="OFF";

G_VBUF_OWIDTH: integer:=16;
G_VSYN_ACTIVE : std_logic:='1';

G_MEM_AWIDTH : integer:=32;
G_MEMWR_DWIDTH : integer:=32;
G_MEMRD_DWIDTH : integer:=32
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_clk          : in   std_logic;

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld       : in   std_logic;
p_in_cfg_adr_fifo     : in   std_logic;

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);
p_in_cfg_wd           : in   std_logic;

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);
p_in_cfg_rd           : in   std_logic;

p_in_cfg_done         : in   std_logic;

-------------------------------
--HOST
-------------------------------
p_in_hrdchsel         : in    std_logic_vector(3 downto 0);
p_in_hrdstart         : in    std_logic;
p_in_hrddone          : in    std_logic;
p_out_hirq            : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
p_out_hdrdy           : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
p_out_hfrmrk          : out   std_logic_vector(31 downto 0);
p_out_hirq2           : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);

p_in_vbufo_rdclk      : in    std_logic;
p_out_vbufo_do        : out   std_logic_vector(G_MEMRD_DWIDTH - 1 downto 0);
p_in_vbufo_rd         : in    std_logic;
p_out_vbufo_empty     : out   std_logic;

-------------------------------
--VideoOUT
-------------------------------
p_out_vd              : out  std_logic_vector(G_VBUF_OWIDTH - 1 downto 0);
p_in_vs               : in   std_logic;
p_in_hs               : in   std_logic;
p_in_vclk             : in   std_logic;
p_in_vclk_en          : in   std_logic;

-------------------------------
--VBUFI
-------------------------------
p_in_vbufi_do         : in    std_logic_vector(G_MEMWR_DWIDTH - 1 downto 0);
p_out_vbufi_rd        : out   std_logic;
p_in_vbufi_empty      : in    std_logic;
p_in_vbufi_full       : in    std_logic;
p_in_vbufi_pfull      : in    std_logic;

---------------------------------
--MEM
---------------------------------
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;
--CH READ
p_out_memrd2          : out   TMemIN;
p_in_memrd2           : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
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

--host -> dev
p_in_htxbuf_di    : in   std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_in_htxbuf_wr    : in   std_logic;
p_out_htxbuf_full : out  std_logic;
p_out_htxbuf_empty: out  std_logic;

--host <- dev
p_out_hrxbuf_do   : out  std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_in_hrxbuf_rd    : in   std_logic;
p_out_hrxbuf_full : out  std_logic;
p_out_hrxbuf_empty: out  std_logic;

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

component dsn_switch
generic(
G_VBUF_IWIDTH : integer := 80;
G_VBUF_OWIDTH : integer := 32
);
port(
-------------------------------
--CFG
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
--Связь с ImageSensor
-------------------------------
p_in_vd                   : in   std_logic_vector(G_VBUF_IWIDTH - 1 downto 0);
p_in_vs                   : in   std_logic;
p_in_hs                   : in   std_logic;
p_in_vclk                 : in   std_logic;
p_in_vclk_en              : in   std_logic;
p_in_ext_syn              : in   std_logic;

p_in_convert_clk          : in   std_logic;

-------------------------------
--VBUFI
-------------------------------
p_in_vbufi_rdclk          : in   std_logic;
p_out_vbufi_do            : out  std_logic_vector(G_VBUF_OWIDTH - 1 downto 0);
p_in_vbufi_rd             : in   std_logic;
p_out_vbufi_empty         : out  std_logic;
p_out_vbufi_full          : out  std_logic;
p_out_vbufi_pfull         : out  std_logic;

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

component vfr_gen
generic(
G_VD_WIDTH : integer := 80;
G_VSYN_ACTIVE : std_logic := '1'
);
port(
--CFG
p_in_cfg      : in   std_logic_vector(15 downto 0);
p_in_vpix     : in   std_logic_vector(15 downto 0);
p_in_vrow     : in   std_logic_vector(15 downto 0);
p_in_syn_h    : in   std_logic_vector(15 downto 0);
p_in_syn_v    : in   std_logic_vector(15 downto 0);

--Test Video
p_out_vd      : out  std_logic_vector(G_VD_WIDTH - 1 downto 0);
p_out_vs      : out  std_logic;
p_out_hs      : out  std_logic;
p_out_vclk    : out  std_logic;
p_out_vclk_en : out  std_logic;

--Технологический
p_in_tst      : in   std_logic_vector(31 downto 0);
p_out_tst     : out  std_logic_vector(31 downto 0);

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end component;

component prom_ld
generic(
G_HOST_DWIDTH : integer:=32
);
port(
-------------------------------
--HOST
-------------------------------
--host -> dev
p_in_htxbuf_di       : in   std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_htxbuf_wr       : in   std_logic;
p_out_htxbuf_full    : out  std_logic;
p_out_htxbuf_empty   : out  std_logic;

--host <- dev
p_out_hrxbuf_do      : out  std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_hrxbuf_rd       : in   std_logic;
p_out_hrxbuf_full    : out  std_logic;
p_out_hrxbuf_empty   : out  std_logic;

p_out_hirq           : out  std_logic;
p_out_herr           : out  std_logic;

p_in_hclk            : in   std_logic;

-------------------------------
--PHY
-------------------------------
p_in_phy         : in    TPromPhyIN;
p_out_phy        : out   TPromPhyOUT;
p_inout_phy      : inout TPromPhyINOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end component;

component dsn_video_ctrl2
generic(
G_USR_OPT : std_logic_vector(7 downto 0):=(others=>'0');
G_DBGCS  : string:="OFF";
G_ROTATE : string:="OFF";
G_ROTATE_BUF_COUNT: integer:=16;
G_SIMPLE : string:="OFF";
G_SIM    : string:="OFF";

G_VBUF_OWIDTH: integer:=16;
G_VSYN_ACTIVE : std_logic:='1';

G_MEM_AWIDTH : integer:=32;
G_MEMWR_DWIDTH : integer:=32;
G_MEMRD_DWIDTH : integer:=32
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_clk          : in   std_logic;

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld       : in   std_logic;
p_in_cfg_adr_fifo     : in   std_logic;

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);
p_in_cfg_wd           : in   std_logic;

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);
p_in_cfg_rd           : in   std_logic;

p_in_cfg_done         : in   std_logic;

-------------------------------
--HOST
-------------------------------
p_in_hrdchsel         : in    std_logic_vector(3 downto 0);
p_in_hrdstart         : in    std_logic;
p_in_hrddone          : in    std_logic;
p_out_hirq            : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
p_out_hdrdy           : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
p_out_hfrmrk          : out   std_logic_vector(31 downto 0);

-------------------------------
--VideoOUT
-------------------------------
p_out_vd              : out  std_logic_vector(G_VBUF_OWIDTH - 1 downto 0);
p_in_vs               : in   std_logic;
p_in_hs               : in   std_logic;
p_in_vclk             : in   std_logic;
p_in_vclk_en          : in   std_logic;

-------------------------------
--VBUFI
-------------------------------
p_in_vbufi_do         : in    std_logic_vector(G_MEMWR_DWIDTH - 1 downto 0);
p_out_vbufi_rd        : out   std_logic;
p_in_vbufi_empty      : in    std_logic;
p_in_vbufi_full       : in    std_logic;
p_in_vbufi_pfull      : in    std_logic;

---------------------------------
--MEM
---------------------------------
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;
--CH READ
p_out_memrd2          : out   TMemIN;
p_in_memrd2           : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

end hscam_pkg;

