-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : dsn_hdd_pkg
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
use work.sata_pkg.all;
use work.sata_raid_pkg.all;

package dsn_hdd_pkg is

type THDDLed is record
link: std_logic;--//Связь установлена
rdy : std_logic;--//Канал готов к работе
err : std_logic;--//
spd : std_logic_vector(1 downto 0);
end record;
type THDDLed_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of THDDLed;

component hdd_cmdfifo is
port
(
din         : in std_logic_vector(15 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(15 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
empty       : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component ;

component hdd_txfifo
port
(
din         : in std_logic_vector(31 downto 0);
wr_en       : in std_logic;
--wr_clk      : in std_logic;

dout        : out std_logic_vector(31 downto 0);
rd_en       : in std_logic;
--rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
empty       : out std_logic;
prog_full   : out std_logic;

clk         : in std_logic;
rst         : in std_logic
);
end component;

component hdd_rxfifo
port
(
din         : in std_logic_vector(31 downto 0);
wr_en       : in std_logic;
--wr_clk      : in std_logic;

dout        : out std_logic_vector(31 downto 0);
rd_en       : in std_logic;
--rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
empty       : out std_logic;

clk         : in std_logic;
rst         : in std_logic
);
end component;

component dsn_hdd
generic
(
G_MODULE_USE : string:="ON";
G_HDD_COUNT  : integer:=2;
G_DBG        : string:="OFF";
--G_DBGCS      : string:="OFF";
G_SIM        : string:="OFF"
);
port
(
--------------------------------------------------
-- Конфигурирование модуля DSN_HDD.VHD (p_in_cfg_clk domain)
--------------------------------------------------
p_in_cfg_clk              : in   std_logic;                      --//

p_in_cfg_adr              : in   std_logic_vector(7 downto 0);   --//
p_in_cfg_adr_ld           : in   std_logic;                      --//
p_in_cfg_adr_fifo         : in   std_logic;                      --//

p_in_cfg_txdata           : in   std_logic_vector(15 downto 0);  --//
p_in_cfg_wd               : in   std_logic;                      --//

p_out_cfg_rxdata          : out  std_logic_vector(15 downto 0);  --//
p_in_cfg_rd               : in   std_logic;                      --//

p_in_cfg_done             : in   std_logic;                      --//
p_in_cfg_rst              : in   std_logic;

--------------------------------------------------
-- STATUS модуля DSN_HDD.VHD
--------------------------------------------------
p_out_hdd_rdy             : out  std_logic;                      --//
p_out_hdd_error           : out  std_logic;                      --//
p_out_hdd_busy            : out  std_logic;                      --//
p_out_hdd_irq             : out  std_logic;                      --//
p_out_hdd_done            : out  std_logic;                      --//

--//--------------------------------------------------
-- Связь с Источниками/Приемниками данных накопителя
--------------------------------------------------
p_out_rbuf_cfg            : out  THDDRBufCfg;  --//
p_in_rbuf_status          : in   THDDRBufStatus;--//Модуль находится в исходном состоянии + p_in_vbuf_empty and p_in_dwnp_buf_empty

p_in_hdd_txd              : in   std_logic_vector(31 downto 0);  --//
p_in_hdd_txd_wr           : in   std_logic;                      --//
p_out_hdd_txbuf_full      : out  std_logic;                      --//

p_out_hdd_rxd             : out  std_logic_vector(31 downto 0);  --//
p_in_hdd_rxd_rd           : in   std_logic;                      --//
p_out_hdd_rxbuf_empty     : out  std_logic;                      --//

--------------------------------------------------
--SATA Driver
--------------------------------------------------
p_out_sata_txn            : out   std_logic_vector(1 downto 0);
p_out_sata_txp            : out   std_logic_vector(1 downto 0);
p_in_sata_rxn             : in    std_logic_vector(1 downto 0);
p_in_sata_rxp             : in    std_logic_vector(1 downto 0);

p_in_sata_refclk          : in    std_logic;
p_out_sata_refclkout      : out   std_logic;
p_out_sata_gt_plldet      : out   std_logic;
p_out_sata_dcm_lock       : out   std_logic;

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_in_tst                 : in    std_logic_vector(31 downto 0);
p_out_tst                : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gtp_txdata        : out   TBus32_SHCountMax;
p_out_sim_gtp_txcharisk     : out   TBus04_SHCountMax;
p_out_sim_gtp_txcomstart    : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gtp_rxdata         : in    TBus32_SHCountMax;
p_in_sim_gtp_rxcharisk      : in    TBus04_SHCountMax;
p_in_sim_gtp_rxstatus       : in    TBus03_SHCountMax;
p_in_sim_gtp_rxelecidle     : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gtp_rxdisperr      : in    TBus04_SHCountMax;
p_in_sim_gtp_rxnotintable   : in    TBus04_SHCountMax;
p_in_sim_gtp_rxbyteisaligned: in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gtp_sim_rst           : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gtp_sim_clk           : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_out_dbgled                : out   THDDLed_SHCountMax;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;


end dsn_hdd_pkg;


package body dsn_hdd_pkg is

end dsn_hdd_pkg;

