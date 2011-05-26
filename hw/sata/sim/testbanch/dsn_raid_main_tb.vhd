-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 19:15:18
-- Module Name : dsn_raid_main_tb
--
-- Description : Моделирование работы модуля dsn_raid_main.vhd
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

use ieee.std_logic_textio.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_sim_pkg.all;
use work.sata_sim_lite_pkg.all;

entity dsn_raid_main_tb is
generic
(
G_HDD_COUNT     : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_GT_DBUS       : integer:=16;
G_DBG           : string :="ON";
G_SIM           : string :="ON"
);
end dsn_raid_main_tb;

architecture behavior of dsn_raid_main_tb is

constant C_SATACLK_PERIOD : TIME := 6.6 ns; --150MHz
constant C_USRCLK_PERIOD  : TIME := 6.6*8 ns;

signal i_sata_clk                 : std_logic;
signal p_in_clk                   : std_logic;
signal p_in_rst                   : std_logic;

signal i_sata_txn                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_txp                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_rxn                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_rxp                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_refclk              : std_logic_vector((C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);

signal p_in_usr_ctrl              : std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);

signal i_usr_status               : TUsrStatus;

signal i_usr_cxdin                : std_logic_vector(15 downto 0);
signal i_usr_cxd_wr               : std_logic;

signal i_usr_txdin                : std_logic_vector(31 downto 0);
signal i_usr_txdout               : std_logic_vector(31 downto 0);
signal i_usr_txd_wr               : std_logic;
signal i_usr_txd_rd               : std_logic;
signal i_usr_txbuf_full           : std_logic;
signal i_usr_txbuf_empty          : std_logic;
signal i_usr_rxdin                : std_logic_vector(31 downto 0);
signal i_usr_rxdout               : std_logic_vector(31 downto 0);
signal i_usr_rxd_wr               : std_logic;
signal i_usr_rxd_rd               : std_logic;
signal i_usr_rxbuf_full           : std_logic;
signal i_usr_rxbuf_empty          : std_logic;


signal i_sim_gtp_txdata           : TBus32_SHCountMax;
signal i_sim_gtp_txcharisk        : TBus04_SHCountMax;
signal i_sim_gtp_txcomstart       : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sim_gtp_rxdata           : TBus32_SHCountMax;
signal i_sim_gtp_rxcharisk        : TBus04_SHCountMax;
signal i_sim_gtp_rxstatus         : TBus03_SHCountMax;
signal i_sim_gtp_rxelecidle       : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sim_gtp_rxdisperr        : TBus04_SHCountMax;
signal i_sim_gtp_rxnotintable     : TBus04_SHCountMax;
signal i_sim_gtp_rxbyteisaligned  : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sim_gtp_rst              : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sim_gtp_clk              : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);



signal i_loopback                 : std_logic;
signal sr_cmdbusy                 : std_logic_vector(0 to 1);
signal i_cmddone_det_clr          : std_logic:='0';
signal i_cmddone_det              : std_logic:='0';
signal i_cmd_data                 : TUsrAppCmdPkt;
signal i_cmd_wrstart              : std_logic:='0';
signal i_cmd_wrdone               : std_logic:='0';
signal i_txdata_select            : std_logic:='0';
signal i_txdata                   : TSimBufData;
signal i_txdata_wrstart           : std_logic:='0';
signal i_txdata_wrdone            : std_logic:='0';
signal i_rxdata                   : TSimBufData;
signal i_rxdata_rdstart           : std_logic:='0';
signal i_rxdata_rddone            : std_logic:='0';
signal i_tstdata_dwsize           : integer:=0;

type TSataDevStatusSataCount is array (0 to C_HDD_COUNT_MAX-1) of TSataDevStatus;
signal i_satadev_status           : TSataDevStatusSataCount;
signal i_satadev_ctrl             : TSataDevCtrl;



--Main
begin



m_txbuf : sata_txfifo
port map
(
din        => i_usr_txdin,
wr_en      => i_usr_txd_wr,
wr_clk     => p_in_clk,

dout       => i_usr_txdout,
rd_en      => i_usr_txd_rd,
rd_clk     => p_in_clk,

full        => i_usr_txbuf_full,--
prog_full   => open,
--almost_full => i_txbuf_afull,
empty       => i_usr_txbuf_empty,
almost_empty=> open,

rst        => p_in_rst
);

m_rxbuf : sata_rxfifo
port map
(
din        => i_usr_rxdin,
wr_en      => i_usr_rxd_wr,
wr_clk     => p_in_clk,

dout       => i_usr_rxdout,
rd_en      => i_usr_rxd_rd,
rd_clk     => p_in_clk,

full        => open,
prog_full   => i_usr_rxbuf_full,
--almost_full => open,
empty       => i_usr_rxbuf_empty,
--almost_empty=> open,

rst        => p_in_rst
);


gen_sata_drv : for i in 0 to (C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 generate
i_sata_rxn<=(others=>'0');
i_sata_rxp<=(others=>'1');
i_sata_refclk(i)<=i_sata_clk;
end generate gen_sata_drv;


m_raid : dsn_raid_main
generic map
(
G_HDD_COUNT       => G_HDD_COUNT,
G_GT_DBUS         => G_GT_DBUS,
G_DBG             => G_DBG,
G_SIM             => G_SIM
)
port map
(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              => i_sata_txn,
p_out_sata_txp              => i_sata_txp,
p_in_sata_rxn               => i_sata_rxn,
p_in_sata_rxp               => i_sata_rxp,

p_in_sata_refclk            => i_sata_refclk,

--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl               => p_in_usr_ctrl,
p_out_usr_status            => i_usr_status,

--//cmdpkt
p_in_usr_cxd                => i_usr_cxdin,
p_in_usr_cxd_wr             => i_usr_cxd_wr,

--//txfifo
p_in_usr_txd                => i_usr_txdout,
p_out_usr_txd_rd            => i_usr_txd_rd,
p_in_usr_txbuf_empty        => i_usr_txbuf_empty,

--//rxfifo
p_out_usr_rxd               => i_usr_rxdin,
p_out_usr_rxd_wr            => i_usr_rxd_wr,
p_in_usr_rxbuf_full         => i_usr_rxbuf_full,

--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gtp_txdata        => i_sim_gtp_rxdata,
p_out_sim_gtp_txcharisk     => i_sim_gtp_rxcharisk,
p_out_sim_gtp_txcomstart    => i_sim_gtp_txcomstart,
p_in_sim_gtp_rxdata         => i_sim_gtp_txdata,
p_in_sim_gtp_rxcharisk      => i_sim_gtp_txcharisk,
p_in_sim_gtp_rxstatus       => i_sim_gtp_rxstatus,
p_in_sim_gtp_rxelecidle     => i_sim_gtp_rxelecidle,
p_in_sim_gtp_rxdisperr      => i_sim_gtp_rxdisperr,
p_in_sim_gtp_rxnotintable   => i_sim_gtp_rxnotintable,
p_in_sim_gtp_rxbyteisaligned=> i_sim_gtp_rxbyteisaligned,
p_out_gtp_sim_rst           => i_sim_gtp_rst,
p_out_gtp_sim_clk           => i_sim_gtp_clk,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => "00000000000000000000000000000000",
p_out_tst               => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);


gen_satad : for i in 0 to G_HDD_COUNT-1 generate

m_sata_dev : sata_dev_model
generic map
(
G_DBG_LLAYER => "OFF",
G_GT_DBUS    => G_GT_DBUS
)
port map
(
----------------------------
--
----------------------------
p_out_gtp_txdata            => i_sim_gtp_txdata(i),
p_out_gtp_txcharisk         => i_sim_gtp_txcharisk(i),

p_in_gtp_txcomstart         => i_sim_gtp_txcomstart(i),

p_in_gtp_rxdata             => i_sim_gtp_rxdata(i),
p_in_gtp_rxcharisk          => i_sim_gtp_rxcharisk(i),

p_out_gtp_rxstatus          => i_sim_gtp_rxstatus(i),
p_out_gtp_rxelecidle        => i_sim_gtp_rxelecidle(i),
p_out_gtp_rxdisperr         => i_sim_gtp_rxdisperr(i),
p_out_gtp_rxnotintable      => i_sim_gtp_rxnotintable(i),
p_out_gtp_rxbyteisaligned   => i_sim_gtp_rxbyteisaligned(i),

p_in_ctrl                   => i_satadev_ctrl,
p_out_status                => i_satadev_status(i),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                   => "00000000000000000000000000000000",
p_out_tst                  => open,

----------------------------
--System
----------------------------
p_in_clk                   => i_sim_gtp_clk(i),
p_in_rst                   => i_sim_gtp_rst(i)
);

end generate gen_satad;


gen_clk_sata : process
begin
  i_sata_clk<='0';
  wait for C_SATACLK_PERIOD/2;
  i_sata_clk<='1';
  wait for C_SATACLK_PERIOD/2;
end process;

gen_clk_usr : process
begin
  p_in_clk<='0';
  wait for C_USRCLK_PERIOD/2;
  p_in_clk<='1';
  wait for C_USRCLK_PERIOD/2;
end process;

p_in_rst<='1','0' after 1 us;



--//########################################
--//Main Ctrl
--//########################################

p_in_usr_ctrl<=(others=>'0');


--//Логика работы автомата управления
lmain_ctrl:process

type TSimCfgCmdPkts is array (0 to 64) of TSimCfgCmdPkt;
variable cfgCmdPkt : TSimCfgCmdPkts;
variable cmd_write : std_logic:='0';
variable cmd_read  : std_logic:='0';
variable cmddone_det: std_logic:='0';


variable string_value : std_logic_vector(3 downto 0);
variable GUI_line  : LINE;--Строка для вывода в ModelSim

begin

  --//---------------------------------------------------
  --/Инициализация
  --//---------------------------------------------------
  i_cmd_wrstart<='0';
  i_txdata_wrstart<='0';
  i_rxdata_rdstart<='0';
  i_tstdata_dwsize<=0;
  i_loopback<='0';
  i_cmddone_det_clr<='0';

  for i in 0 to i_cmd_data'high loop
  i_cmd_data(i)<=(others=>'0');
  end loop;

  for i in 0 to cfgCmdPkt'high loop
  cfgCmdPkt(i).usr_ctrl:=(others=>'0');
  cfgCmdPkt(i).command:=C_ATA_CMD_READ_SECTORS_EXT;
  cfgCmdPkt(i).scount:=1;
  cfgCmdPkt(i).lba:=(others=>'0');
  cfgCmdPkt(i).loopback:='0';
  cfgCmdPkt(i).device:=(others=>'0');
  cfgCmdPkt(i).control:=(others=>'0');
  end loop;

  i_txdata_select<='1'; --//0/1 - Счетчик/Random DATA

  --//Инициализируем команды которые будут отправлятся:
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(0).command:=C_ATA_CMD_WRITE_DMA_EXT;--;C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(0).scount:=2;--//Кол-во секторов
  cfgCmdPkt(0).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);--//LBA
  cfgCmdPkt(0).loopback:='1';

  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(1).command:=C_ATA_CMD_READ_DMA_EXT;--C_ATA_CMD_WRITE_DMA_EXT;--;
  cfgCmdPkt(1).scount:=8;
  cfgCmdPkt(1).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(1).loopback:='1';

  cfgCmdPkt(2).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(2).command:=C_ATA_CMD_WRITE_SECTORS_EXT;
  cfgCmdPkt(2).scount:=3;
  cfgCmdPkt(2).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(2).loopback:='1';

  cfgCmdPkt(3).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(3).command:=C_ATA_CMD_READ_SECTORS_EXT;--C_ATA_CMD_WRITE_SECTORS_EXT;--
  cfgCmdPkt(3).scount:=3;
  cfgCmdPkt(3).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(3).loopback:='1';

  cfgCmdPkt(4).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(4).command:=C_ATA_CMD_WRITE_DMA_EXT;
  cfgCmdPkt(4).scount:=1;
  cfgCmdPkt(4).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(4).loopback:='0';

  cfgCmdPkt(5).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(5).command:=C_ATA_CMD_READ_DMA_EXT;
  cfgCmdPkt(5).scount:=1;
  cfgCmdPkt(5).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(5).loopback:='0';

  cfgCmdPkt(6).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(6).command:=C_ATA_CMD_WRITE_SECTORS_EXT;
  cfgCmdPkt(6).scount:=1;
  cfgCmdPkt(6).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(6).loopback:='0';

  cfgCmdPkt(7).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(7).command:=C_ATA_CMD_READ_SECTORS_EXT;
  cfgCmdPkt(7).scount:=1;
  cfgCmdPkt(7).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(7).loopback:='0';

  cfgCmdPkt(8).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(8).command:=C_ATA_CMD_WRITE_DMA_EXT;--;
  cfgCmdPkt(8).scount:=3;
  cfgCmdPkt(8).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(8).loopback:='0';

  cfgCmdPkt(9).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(9).command:=C_ATA_CMD_READ_DMA_EXT;
  cfgCmdPkt(9).scount:=2;
  cfgCmdPkt(9).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(9).loopback:='0';

  cfgCmdPkt(10).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(10).command:=C_ATA_CMD_WRITE_SECTORS_EXT;
  cfgCmdPkt(10).scount:=4;
  cfgCmdPkt(10).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(10).loopback:='0';

  cfgCmdPkt(11).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(11).command:=C_ATA_CMD_READ_SECTORS_EXT;
  cfgCmdPkt(11).scount:=3;
  cfgCmdPkt(11).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(11).loopback:='0';




  --//---------------------------------------------------
  --//Отработка команд командного пакета
  --//---------------------------------------------------
  ltrn_count : for idx in 0 to C_SIM_COUNT-1 loop

  i_loopback<=cfgCmdPkt(idx).loopback;

  --//Ждем разрешения загрузки командного пакета
  cmddone_det:='0';
  while cmddone_det='0' loop
      wait until p_in_clk'event and p_in_clk='1';
        cmddone_det:=i_cmddone_det;
  end loop;
  --//Сброс флага i_cmddone_det
  wait until p_in_clk'event and p_in_clk='1';
  i_cmddone_det_clr<='1';
  wait until p_in_clk'event and p_in_clk='1';
  i_cmddone_det_clr<='0';

  write(GUI_line,string'("NEW ATA COMMAND 1."));writeline(output, GUI_line);

  --//Заполняем CmdPkt
  i_cmd_data(0)<=cfgCmdPkt(idx).usr_ctrl; --//UsrCTRL
  i_cmd_data(1)<=CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
  i_cmd_data(2)<=cfgCmdPkt(idx).lba(31 downto 24) & cfgCmdPkt(idx).lba(7 downto 0);
  i_cmd_data(3)<=cfgCmdPkt(idx).lba(39 downto 32) & cfgCmdPkt(idx).lba(15 downto 8);
  i_cmd_data(4)<=cfgCmdPkt(idx).lba(47 downto 40) & cfgCmdPkt(idx).lba(23 downto 16);
  i_cmd_data(5)<=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).scount, 16);--//SectorCount
  i_cmd_data(6)<=cfgCmdPkt(idx).control & cfgCmdPkt(idx).device;--//Control + Device
  i_cmd_data(7)<=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).command, 8);--//Reserv + ATA Commad

  i_tstdata_dwsize<=cfgCmdPkt(idx).scount * C_SIM_SECTOR_SIZE_DWORD;--//Назначаем размер данных в DWORD


  --//Запускаем автомат записи командного пакета
  wait until p_in_clk'event and p_in_clk='1';
  i_cmd_wrstart<='1';
  wait until p_in_clk'event and p_in_clk='1';
  i_cmd_wrstart<='0';


  --//Ждем отправки подтверждения записи командного пакета
  wait until i_cmd_wrdone='1';


  if cfgCmdPkt(idx).command=C_ATA_CMD_WRITE_SECTORS_EXT or cfgCmdPkt(idx).command=C_ATA_CMD_WRITE_DMA_EXT then
  --//Запускаем автомат записи данных
    wait until p_in_clk'event and p_in_clk='1';
    i_txdata_wrstart<='1';
    cmd_write:='1';

    wait until p_in_clk'event and p_in_clk='1';
    i_txdata_wrstart<='0';

    --//Ждем когда запишем все данные в TxBUF
    wait until i_txdata_wrdone='1';
  end if;

  if cfgCmdPkt(idx).command=C_ATA_CMD_READ_SECTORS_EXT or cfgCmdPkt(idx).command=C_ATA_CMD_READ_DMA_EXT then
  --//Запускаем автомат чтния данных
    wait until p_in_clk'event and p_in_clk='1';
    i_rxdata_rdstart<='1';
    cmd_read:='1';

    wait until p_in_clk'event and p_in_clk='1';
    i_rxdata_rdstart<='0';

    --//Ждем когда прочитаем все данные из RxBUF
    wait until i_rxdata_rddone='1';
  end if;


  if i_loopback='0' then
    write(GUI_line,string'("LOOPBACK DATA: disable")); writeline(output, GUI_line);
    cmd_write:='0';
    cmd_read:='0';

  else

    if cmd_write='1' and cmd_read='1' then
      write(GUI_line,string'("COMPARE DATA: i_txdata,i_rxdata")); writeline(output, GUI_line);
      for i in 0 to i_tstdata_dwsize-1 loop

          write(GUI_line,string'(" i_txdata/i_rxdata("));write(GUI_line,i);write(GUI_line,string'("): 0x"));
          --write(GUI_line,CONV_INTEGER(i_txdata(i)));
          for y in 1 to 8 loop
          string_value:=i_txdata(i)((32-(4*(y-1)))-1 downto (32-(4*y)));
          write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
          end loop;
          write(GUI_line,string'("/0x"));
          --write(GUI_line,CONV_INTEGER(i_rxdata(i)));
          for y in 1 to 8 loop
          string_value:=i_rxdata(i)((32-(4*(y-1)))-1 downto (32-(4*y)));
          write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
          end loop;
          writeline(output, GUI_line);

        if i_txdata(i)/=i_rxdata(i) then
          --//Завершаем модеоирование.
          write(GUI_line,string'("COMPARE DATA:ERROR - i_txdata("));write(GUI_line,i);write(GUI_line,string'(")/= "));
          write(GUI_line,string'("i_rxdata("));write(GUI_line,i);write(GUI_line,string'(")"));
          writeline(output, GUI_line);
          p_SIM_STOP("Simulation of STOP: COMPARE DATA:ERROR i_rxdata/=i_rxdata");
        end if;
      end loop;

      cmd_write:='0';
      cmd_read:='0';
      write(GUI_line,string'("COMPARE DATA: i_txdata/i_rxdata - OK.")); writeline(output, GUI_line);
    end if;
  end if;

  end loop ltrn_count;


  wait for 2 us;

  --//Завершаем модеоирование.
  p_SIM_STOP("Simulation of SIMPLE complete");


  wait;
end process lmain_ctrl;


--//Выделяем задний фронт из сигнала BUSY модуля m_sata_host.
--//Для детектированя завершения АТА команды
lcmddone:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_cmdbusy<=(others=>'1');
    i_cmddone_det<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    sr_cmdbusy<=i_usr_status.dev_busy & sr_cmdbusy(0 to 0);

    if i_cmddone_det_clr='1' then
      i_cmddone_det<='0';
    elsif sr_cmdbusy(1)='1' and sr_cmdbusy(0)='0' then
      i_cmddone_det<='1';
    end if;

  end if;
end process lcmddone;




process
variable GUI_line : LINE;--Строка для вывода в ModelSim
begin

  i_satadev_ctrl.atacmd_done<='0';

  wait until i_cmddone_det_clr='1';

  wait until i_sim_gtp_clk(0)'event and i_sim_gtp_clk(0) = '1';
  i_satadev_ctrl.atacmd_done<='1';
  wait until i_sim_gtp_clk(0)'event and i_sim_gtp_clk(0) = '1';
  i_satadev_ctrl.atacmd_done<='0';

end process;

i_satadev_ctrl.loopback<=i_loopback;
i_satadev_ctrl.link_establish<=i_usr_status.dev_rdy;
i_satadev_ctrl.dbuf_wuse<='1';--//1/0 - использовать модель sata_bufdata.vhd/ не использовать
i_satadev_ctrl.dbuf_ruse<='1';




--//########################################
--//Запись данных в CmdBUF
--//########################################
ltxcmd:process
variable GUI_line : LINE;--Строка для вывода в ModelSim
begin

  ltxcmdloop:while true loop

      i_usr_cxdin<=(others=>'0');
      i_usr_cxd_wr<='0';
      i_cmd_wrdone<='0';

      wait until i_cmd_wrstart = '1';--//Ждем разрешения записи данных

      p_CMDPKT_WRITE(p_in_clk,
                    i_cmd_data,
                    i_usr_cxdin, i_usr_cxd_wr);

      wait until p_in_clk'event and p_in_clk='1';
        i_cmd_wrdone<='1';
      wait until p_in_clk'event and p_in_clk='1';
        i_cmd_wrdone<='0';

  end loop ltxcmdloop;

  wait;
end process ltxcmd;




--//########################################
--//Запись данных в TxBUF
--//########################################
ltxd:process
variable dcnt      : integer;
variable srcambler : std_logic_vector(31 downto 0):=(others=>'0');
variable GUI_line  : LINE;--Строка для вывода в ModelSim
begin

  i_usr_txdin<=(others=>'0');
  i_usr_txd_wr<='0';
  i_txdata_wrdone<='0';

  --//Инициализация генератора рандомных данных
  srcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#1032#, 16));

  ltxdloop:while true loop

      wait until i_txdata_wrstart = '1';--//Ждем разрешения записи данных

      --//Инициализация
      for i in 0 to i_txdata'high loop
      i_txdata(i)<=(others=>'0');
      end loop;

      --//Генератор тестовых данных
      for i in 0 to i_txdata'high loop
        if i_txdata_select='0' then
          i_txdata(i)<=CONV_STD_LOGIC_VECTOR(i+1, i_txdata(i)'length);--счетчик
        else
          i_txdata(i)<=srcambler;--//Random Data
        end if;
        srcambler:=srambler32_0(srcambler(31 downto 16));--//Инкрементация скремблера
      end loop;

      dcnt:=0;
      --//Запись данных в TxBuf(m_txbuf)
      lbufd_wr:while dcnt/=i_tstdata_dwsize loop

          if i_usr_txbuf_full='0' then

              wait until p_in_clk'event and p_in_clk='1';
                i_usr_txdin<=i_txdata(dcnt);
                i_usr_txd_wr<='1';

              wait until p_in_clk'event and p_in_clk='1';
                i_usr_txd_wr<='0';

                dcnt:=dcnt + 1;
          else
              wait until p_in_clk'event and p_in_clk='1';
                i_usr_txd_wr<='0';
          end if;

       end loop lbufd_wr;

      wait until p_in_clk'event and p_in_clk='1';
        i_txdata_wrdone<='1';
      wait until p_in_clk'event and p_in_clk='1';
        i_txdata_wrdone<='0';

  end loop ltxdloop;

  wait;
end process ltxd;


--//########################################
--//Чтение данных из RxBUF
--//########################################
lrxd:process
variable dcnt : integer:=0;
variable GUI_line  : LINE;--Строка для вывода в ModelSim
begin

  i_usr_rxd_rd<='0';
  i_rxdata_rddone<='0';

  lrxdloop:while true loop

      wait until i_rxdata_rdstart = '1';--//Ждем разрешения чтения данных

      --//Инициализация
      for i in 0 to i_txdata'high loop
      i_rxdata(i)<=(others=>'0');
      end loop;

      dcnt:=0;
      --//Чтение данных из RxBuf(m_rxbuf)
      lbufd_rd:while dcnt/=i_tstdata_dwsize loop

          if i_usr_rxbuf_empty='0' then

              wait until p_in_clk'event and p_in_clk='1';
                  i_usr_rxd_rd<='1';
              wait until p_in_clk'event and p_in_clk='1';
                  i_usr_rxd_rd<='0';

              wait until p_in_clk'event and p_in_clk='1';
                  i_rxdata(dcnt)<=i_usr_rxdout;
                  dcnt:=dcnt + 1;
          else
              wait until p_in_clk'event and p_in_clk='1';
                  i_usr_rxd_rd<='0';
          end if;

       end loop lbufd_rd;

      wait until p_in_clk'event and p_in_clk='1';
        i_rxdata_rddone<='1';
      wait until p_in_clk'event and p_in_clk='1';
        i_rxdata_rddone<='0';

  end loop lrxdloop;

  wait;
end process lrxd;

--End Main
end;



