-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 20.01.2012 14:42:09
-- Module Name : hdd_main_unit_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.video_ctrl_pkg.all;
use work.dsn_hdd_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_testgen_pkg.all;
use work.mem_wr_pkg.all;

package hdd_main_unit_pkg is

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиеся в 1/2 периода 1us
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

component clock
port(
p_out_gclk400M : out std_logic;
p_out_pll_lock : out std_logic;

p_in_clk       : in  std_logic;
p_in_rst       : in  std_logic
);
end component;

component vin_cam
generic(
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1'
);
port(
--Вх. видеопоток
p_in_vd            : in   std_logic_vector(99 downto 0);
p_in_vs            : in   std_logic;
p_in_hs            : in   std_logic;
p_in_vclk          : in   std_logic;

p_out_vfr_prm      : out  TFrXY;

--Вых. видеобуфера
p_out_vbufin_d     : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vbufin_rd     : in   std_logic;
p_out_vbufin_empty : out  std_logic;
p_in_vbufin_rdclk  : in   std_logic;

--Технологический
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

--System
p_in_rst           : in   std_logic
);
end component;

component vin_hdd
generic(
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1'
);
port(
--Вх. видеопоток
p_in_vd            : in   std_logic_vector(99 downto 0);
p_in_vs            : in   std_logic;
p_in_hs            : in   std_logic;
p_in_vclk          : in   std_logic;

--Вых. видеобуфера
p_in_vbufin_rdclk  : in   std_logic;

p_out_vbufin_d     : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vbufin_rd     : in   std_logic;
p_out_vbufin_empty : out  std_logic;
p_out_vbufin_full  : out  std_logic;
p_out_vbufin_pfull : out  std_logic;
p_out_vbufin_wrcnt : out  std_logic_vector(3 downto 0);

p_in_hdd_tstgen    : in   THDDTstGen;

--Технологический
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

--System
p_in_rst           : in   std_logic
);
end component;

component vout
generic(
G_VBUF_IWIDTH : integer:=32;
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1'
);
port(
p_out_vd          : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vs           : in   std_logic;
p_in_hs           : in   std_logic;
p_in_vclk         : in   std_logic;

p_in_vbufout_d    : in   std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
p_in_vbufout_wr   : in   std_logic;
p_out_vbufout_full: out  std_logic;
p_in_vbufout_wrclk: in   std_logic;

p_in_rst          : in   std_logic
);
end component;

component video_ctrl
generic(
G_SIM    : string:="OFF";
G_MEM_BANK_M_BIT : integer:=32;
G_MEM_BANK_L_BIT : integer:=31;
G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
port(
-------------------------------
--
-------------------------------
p_in_vfr_prm          : in  TFrXY;

----------------------------
--Связь с вх/вых видеобуферами
----------------------------
--Вх
p_in_vbufin_d         : in    std_logic_vector(31 downto 0);
p_out_vbufin_rd       : out   std_logic;
p_in_vbufin_empty     : in    std_logic;
--Вых
p_out_vbufout_d       : out   std_logic_vector(31 downto 0);
p_out_vbufout_wr      : out   std_logic;
p_in_vbufout_full     : in    std_logic;

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;

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


component dsn_hdd_rambuf
generic(
G_MODULE_USE  : string:="ON";
G_RAMBUF_SIZE : integer:=23;
G_DBGCS       : string:="OFF";
G_SIM         : string:="OFF";
G_MEM_BANK_M_BIT : integer:=31;
G_MEM_BANK_L_BIT : integer:=31;
G_MEM_AWIDTH  : integer:=32;
G_MEM_DWIDTH  : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         : in    THDDRBufCfg;
p_out_rbuf_status     : out   THDDRBufStatus;

----------------------------
--Связь с буфером видеоданных
----------------------------
p_in_vbuf_dout        : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_vbuf_rd         : out   std_logic;
p_in_vbuf_empty       : in    std_logic;
p_in_vbuf_full        : in    std_logic;
p_in_vbuf_pfull       : in    std_logic;
p_in_vbuf_wrcnt       : in    std_logic_vector(3 downto 0);

----------------------------
--Связь с модулем HDD
----------------------------
p_out_hdd_txd         : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_hdd_txd_wr      : out   std_logic;
p_in_hdd_txbuf_pfull  : in    std_logic;
p_in_hdd_txbuf_full   : in    std_logic;
p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_hdd_rxd_rd      : out   std_logic;
p_in_hdd_rxbuf_empty  : in    std_logic;
p_in_hdd_rxbuf_pempty : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
--p_out_mem             : out   TMemIN;
--p_in_mem              : in    TMemOUT;
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;

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

end hdd_main_unit_pkg;
