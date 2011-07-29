-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 18:27:17
-- Module Name : sata_raid_ctrl
--
-- Назначение : Управление модулями sata_host.vhd
--
-- ВАЖНО: Использование RAMBUF возможно не для всех АТА команд, более подробно см.
--        коментарий --//Разрешаем использование RAMBUF только для пречисленых ниже команд:
--
-- Revision:
-- Revision 0.01 - File Created
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_unit_pkg.all;

entity sata_raid_ctrl is
generic
(
G_HDD_COUNT : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_DBGCS     : string :="OFF";
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port
(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_usr_status        : out   TUsrStatus;

--//cmdpkt
p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_in_usr_cxd_wr         : in    std_logic;

--//txfifo
p_in_usr_txd            : in    std_logic_vector(31 downto 0);
p_out_usr_txd_rd        : out   std_logic;
p_in_usr_txbuf_empty    : in    std_logic;

--//rxfifo
p_out_usr_rxd           : out   std_logic_vector(31 downto 0);
p_out_usr_rxd_wr        : out   std_logic;
p_in_usr_rxbuf_full     : in    std_logic;

--------------------------------------------------
--Связь с модулям sata_raid_decoder.vhd
--------------------------------------------------
p_in_sh_status          : in    TALStatus_SHCountMax;
p_out_sh_ctrl           : out   TALCtrl_SHCountMax;

p_in_raid               : in    TRaid;
p_in_sh_num             : in    std_logic_vector(2 downto 0);
p_out_sh_mask           : out   std_logic_vector(G_HDD_COUNT-1 downto 0);

p_out_sh_cxd            : out   std_logic_vector(15 downto 0);
p_out_sh_cxd_sof_n      : out   std_logic;
p_out_sh_cxd_eof_n      : out   std_logic;
p_out_sh_cxd_src_rdy_n  : out   std_logic;

p_out_sh_hdd            : out   std_logic_vector(2 downto 0);

p_out_sh_txd            : out   std_logic_vector(31 downto 0);
p_out_sh_txd_wr         : out   std_logic;
p_in_sh_txbuf_full      : in    std_logic;

p_in_sh_rxd             : in    std_logic_vector(31 downto 0);
p_out_sh_rxd_rd         : out   std_logic;
p_in_sh_rxbuf_empty     : in    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);
p_out_dbgcs             : out   TSH_ila;

p_in_sh_tst             : in    TBus32_SHCountMax;
p_out_sh_tst            : out   TBus32_SHCountMax;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end sata_raid_ctrl;

architecture behavioral of sata_raid_ctrl is

constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));

signal i_err_clr                   : std_logic;
signal i_err_rambuf                : std_logic;
signal i_usr_status                : TUsrStatus;

signal sr_dev_bsy                  : std_logic_vector(0 to 1);

signal sr_dev_err                  : std_logic_vector(0 to 1);
type TShDetect is record
cmddone : std_logic;
err     : std_logic;
end record;
signal i_sh_det                    : TShDetect;
signal sr_sh_cmddone               : std_logic_vector(0 to 1);

signal i_cmdpkt                    : THDDPkt;
signal i_cmdpkt_cnt                : std_logic_vector(3 downto 0);--//счетчик данных принимаемого командного пакета
signal i_cmdpkt_get_done           : std_logic;                   --//Прием cmd пакета завершен

signal i_dmacfg_start              : std_logic;

signal i_sh_padding                : std_logic;
signal i_sh_padding_en             : std_logic;

signal i_sh_cmd_start              : std_logic;
signal i_sh_cmdcnt                 : std_logic_vector(i_cmdpkt_cnt'range);
signal i_sh_cmdcnt_en              : std_logic;
signal i_sh_cxdout                 : std_logic_vector(p_in_usr_cxd'range);
signal i_sh_cxd_sof                : std_logic;
signal i_sh_cxd_eof                : std_logic;
signal i_sh_cxd_src_rdy            : std_logic;

type TUserMode is record
sw       : std_logic;
hw       : std_logic;
hw_work  : std_logic;
lbaend   : std_logic;
stop     : std_logic;
end record;
signal i_usrmode                   : TUserMode;

signal i_lba_random                : std_logic_vector(31 downto 0);
signal i_lba_cnt                   : std_logic_vector(i_cmdpkt.lba'range);
signal i_lba_inc                   : std_logic_vector(i_cmdpkt.scount'range);--//Значение наращивания LBA
signal i_lba_end                   : std_logic_vector(i_cmdpkt.lba'range);

signal i_sh_trn_byte_count         : std_logic_vector(i_cmdpkt.scount'length + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);
signal i_sh_trn_dw_count           : std_logic_vector(i_sh_trn_byte_count'range);
signal i_sh_hddcnt_ld              : std_logic_vector(p_in_sh_num'range);
signal i_sh_hddcnt                 : std_logic_vector(p_in_sh_num'range);
signal i_sh_trn_en                 : std_logic;
signal i_sh_trn_den                : std_logic;
signal i_sh_txd_wr                 : std_logic;
signal i_sh_rxd_rd                 : std_logic;

signal i_raid_cl_cntdw             : std_logic_vector(i_sh_trn_dw_count'range);
signal sr_raid_cl_done             : std_logic_vector(0 to 2);
signal i_raid_cl_next              : std_logic;

signal i_usr_txbuf_empty           : std_logic;
signal i_usr_rxbuf_full            : std_logic;
signal i_testing_cmd               : std_logic_vector(i_cmdpkt.command'range);--//защелкиваем АТА команду для опреденения направления тестирования
signal i_testing_data              : std_logic_vector(31 downto 0);           --//тестовые данные

signal i_dwr_start                 : std_logic_vector(G_HDD_COUNT-1 downto 0);

signal i_tst                       : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_tst_cnt                   : std_logic_vector(15 downto 0):=(others=>'0');
signal i_tst_sr_ch_bsy             : std_logic_vector(G_HDD_COUNT-1 downto 0):=(others=>'0');
signal i_tst_ch_bsy_done           : std_logic_vector(G_HDD_COUNT-1 downto 0):=(others=>'0');
signal i_tst_bsy                   : std_logic_vector(G_HDD_COUNT-1 downto 0):=(others=>'0');
signal sr_tst_bsy                  : std_logic_vector(0 to 1):=(others=>'0');
signal tst_cmddone                 : std_logic:='0';


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
--p_out_tst(31 downto 0)<=(others=>'0');
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to G_HDD_COUNT-1 loop
    i_tst(i)<='0';
    end loop;
  elsif p_in_clk'event and p_in_clk='1' then
    for i in 0 to G_HDD_COUNT-1 loop
    i_tst(i)<=OR_reduce(p_in_sh_tst(i)(2 downto 0));
    end loop;
  end if;
end process ltstout;

p_out_tst(0)<=OR_reduce(i_tst);
p_out_tst(31 downto 1)<=(others=>'0');
end generate gen_dbg_on;



--//------------------------------------------
--//Инициализация
--//------------------------------------------
i_err_clr<=p_in_usr_ctrl(C_USR_GCTRL_CLR_ERR_BIT);
i_err_rambuf<=p_in_usr_ctrl(C_USR_GCTRL_RAMBUF_ERR_BIT);--//Только для режима HW

gen_sh_pout : for i in 0 to C_HDD_COUNT_MAX-1 generate
p_out_sh_tst(i)<=(others=>'0'); --//технологические входы модулей sata_host
p_out_sh_ctrl(i)<=p_in_usr_ctrl;--//передача глобального управления модулям sata_host
end generate gen_sh_pout;


--//----------------------------------
--//Формирую отчеты
--//----------------------------------
p_out_usr_status<=i_usr_status;

--//RAMBUF:
i_usr_status.dmacfg.tstgen.con2rambuf<=p_in_usr_ctrl(C_USR_GCTRL_TST_GEN2RAMBUF_BIT);
i_usr_status.dmacfg.tstgen.dout<=i_testing_data;
i_usr_status.dmacfg.tst_mode<=p_in_usr_ctrl(C_USR_GCTRL_TST_ON_BIT);
i_usr_status.dmacfg.sw_mode<=i_usrmode.sw;
i_usr_status.dmacfg.hw_mode<=i_usrmode.hw_work;
i_usr_status.dmacfg.start<=i_dmacfg_start;

process(p_in_rst,p_in_clk)
  variable dmacfg_start: std_logic;
begin
  if p_in_rst='1' then
      dmacfg_start:='0';
    i_dmacfg_start<='0';
  elsif p_in_clk'event and p_in_clk='1' then

    dmacfg_start:='0';

    --//Разрешаем использование RAMBUF только для пречисленых ниже команд:
    if i_cmdpkt_get_done='1' then
      if  i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_IDENTIFY_DEV, i_cmdpkt.command'length) or
          i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_SECTORS_EXT, i_cmdpkt.command'length) or
          i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_SECTORS_EXT, i_cmdpkt.command'length) or
          i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, i_cmdpkt.command'length) or
          i_cmdpkt.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_DMA_EXT, i_cmdpkt.command'length)  then
--          i_cmdpkt.ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT)=CONV_STD_LOGIC_VECTOR(C_SATACMD_FPDMA_W, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1) or
--          i_cmdpkt.ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT)=CONV_STD_LOGIC_VECTOR(C_SATACMD_FPDMA_R, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1) then

            dmacfg_start:='1';
      end if;
    end if;

    i_dmacfg_start<=dmacfg_start;
  end if;
end process;

i_usr_status.dmacfg.wr_start<=OR_reduce(i_dwr_start);
i_usr_status.dmacfg.raid.used<=p_in_raid.used;
i_usr_status.dmacfg.raid.hddcount<=p_in_raid.hddcount;
i_usr_status.dmacfg.scount<=i_cmdpkt.scount;
i_usr_status.dmacfg.error<=i_usr_status.dev_err;


--//кол-во HDD подключенных к FPGA
i_usr_status.hdd_count<=CONV_STD_LOGIC_VECTOR(G_HDD_COUNT, i_usr_status.hdd_count'length);

--//Точка останова:
i_usr_status.lba_bp<=i_lba_cnt;

--//Статусы накопителя:
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_usr_status.dev_bsy<='0';
    i_usr_status.dev_rdy<='0';
    i_usr_status.dev_err<='0';
    i_usr_status.dev_ipf<='0';
--    i_usr_status.usr<=(others=>'0');
--    i_usr_status.lba_bp<=(others=>'0');
    for i in 0 to G_HDD_COUNT-1 loop
      i_usr_status.ch_bsy(i)<='0';
      i_usr_status.ch_rdy(i)<='0';
      i_usr_status.ch_err(i)<='0';
      i_usr_status.ch_ipf(i)<='0';
      i_usr_status.ch_ataerror(i)<=(others=>'0');
      i_usr_status.ch_atastatus(i)<=(others=>'0');
      i_usr_status.ch_serror(i)<=(others=>'0');
      i_usr_status.ch_sstatus(i)<=(others=>'0');
--      i_usr_status.ch_usr(i)<=(others=>'0');
    end loop;

    i_dwr_start<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    --//Глобальные статусы:
    i_usr_status.dev_bsy<=OR_reduce(i_usr_status.ch_bsy(G_HDD_COUNT-1 downto 0)) or i_usrmode.hw_work;
    i_usr_status.dev_err<=OR_reduce(i_usr_status.ch_err(G_HDD_COUNT-1 downto 0)) or i_err_rambuf;
    i_usr_status.dev_rdy<=AND_reduce(i_usr_status.ch_rdy(G_HDD_COUNT-1 downto 0));
    i_usr_status.dev_ipf<=AND_reduce(i_usr_status.ch_ipf(G_HDD_COUNT-1 downto 0));
--    i_usr_status.lba_bp<=i_lba_cnt;
--    i_usr_status.usr<=(others=>'0');

    --//Статусы изпользуемых каналов:
    for i in 0 to G_HDD_COUNT-1 loop
      i_dwr_start(i)        <=p_in_sh_status(i).usr(C_AUSR_DWR_START_BIT);
      i_usr_status.ch_bsy(i)<=p_in_sh_status(i).usr(C_AUSR_BSY_BIT);
      i_usr_status.ch_err(i)<=p_in_sh_status(i).usr(C_AUSR_ERR_BIT);
      i_usr_status.ch_rdy(i)<=p_in_sh_status(i).sstatus(C_ASSTAT_IPM_BIT_L);
      i_usr_status.ch_ipf(i)<=p_in_sh_status(i).ipf;--//IPF - (Interrupt pending flag) или по простому прерывание

      i_usr_status.ch_ataerror(i) <=p_in_sh_status(i).ataerror;
      i_usr_status.ch_atastatus(i)<=p_in_sh_status(i).atastatus;
      i_usr_status.ch_serror(i)   <=p_in_sh_status(i).serror;
      i_usr_status.ch_sstatus(i)  <=p_in_sh_status(i).sstatus;
--      i_usr_status.ch_usr(i)<=(others=>'0');
    end loop;

  end if;
end process;


--//Формирую стробы
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_dev_err<=(others=>'0');
    i_sh_det.cmddone<='0';
    i_sh_det.err<='0';

    sr_sh_cmddone<=(others=>'0');
    sr_dev_bsy<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    sr_dev_err<=i_usr_status.dev_err & sr_dev_err(0 to 0);

    sr_dev_bsy<=OR_reduce(i_usr_status.ch_bsy(G_HDD_COUNT-1 downto 0)) & sr_dev_bsy(0 to 0);

    i_sh_det.cmddone<=sr_dev_bsy(1) and not sr_dev_bsy(0);

    i_sh_det.err<=sr_dev_err(0) and not sr_dev_err(1);

    sr_sh_cmddone<=i_sh_det.cmddone & sr_sh_cmddone(0 to 0);

  end if;
end process;


--//Режим HW: если необходимо, то выполняем формирование недостающих данных для после приема команды STOP
i_sh_padding<=i_sh_padding_en and sr_dev_bsy(0) and not i_usrmode.hw_work;





--//------------------------------------------
--//Прием/обработка командного пакета
--//------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_cmdpkt_cnt<=(others=>'0');
    i_cmdpkt_get_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_usr_cxd_wr='1' then
      if i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DCOUNT-1, i_cmdpkt_cnt'length) then
        i_cmdpkt_cnt<=(others=>'0');
      else
        i_cmdpkt_cnt<=i_cmdpkt_cnt + 1;
      end if;

      if i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DCOUNT-1, i_cmdpkt_cnt'length) then
        i_cmdpkt_get_done<='1';
      end if;
    else
      i_cmdpkt_get_done<='0';
    end if;

  end if;
end process;

--//Прием командного пакета
process(p_in_rst,p_in_clk)
  variable raidcmd: std_logic_vector(C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT downto 0);
begin
  if p_in_rst='1' then
    i_cmdpkt.ctrl<=(others=>'0');
    i_cmdpkt.feature<=(others=>'0');
    i_cmdpkt.lba<=(others=>'0');
    i_cmdpkt.scount<=(others=>'0');
    i_cmdpkt.command<=(others=>'0');
    i_cmdpkt.control<=(others=>'0');
    i_cmdpkt.device<=(others=>'0');
--    i_cmdpkt.raid_cl<=(others=>'0');

    i_usrmode.stop<='0';
    i_usrmode.sw<='0';
    i_usrmode.hw<='0';
    i_usrmode.lbaend<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_usr_cxd_wr='1' then
      if    i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_USRCTRL, i_cmdpkt_cnt'length) then i_cmdpkt.ctrl<=p_in_usr_cxd;

          raidcmd:=p_in_usr_cxd(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT);

          if    raidcmd=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_STOP, raidcmd'length) then
            i_usrmode.stop<='1';
            i_usrmode.sw<='0';
            i_usrmode.hw<='0';
            i_usrmode.lbaend<='0';

          elsif raidcmd=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, raidcmd'length) then
            i_usrmode.stop<='0';
            i_usrmode.sw<='1';
            i_usrmode.hw<='0';
            i_usrmode.lbaend<='0';

          elsif raidcmd=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_HW, raidcmd'length) then
            i_usrmode.stop<='0';
            i_usrmode.sw<='0';
            i_usrmode.hw<='1';
            i_usrmode.lbaend<='0';

          elsif raidcmd=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_LBAEND, raidcmd'length) then
            i_usrmode.stop<='0';
            i_usrmode.sw<='0';
            i_usrmode.hw<='0';
            i_usrmode.lbaend<='1';

          end if;

      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_FEATURE, i_cmdpkt_cnt'length)      then i_cmdpkt.feature<=p_in_usr_cxd;
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_LOW, i_cmdpkt_cnt'length)      then i_cmdpkt.lba(8*(0+1)-1 downto 8*0)<=p_in_usr_cxd( 7 downto 0);
                                                                                                i_cmdpkt.lba(8*(1+1)-1 downto 8*1)<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_MID, i_cmdpkt_cnt'length)      then i_cmdpkt.lba(8*(2+1)-1 downto 8*2)<=p_in_usr_cxd( 7 downto 0);
                                                                                                i_cmdpkt.lba(8*(3+1)-1 downto 8*3)<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_HIGH, i_cmdpkt_cnt'length)     then i_cmdpkt.lba(8*(4+1)-1 downto 8*4)<=p_in_usr_cxd( 7 downto 0);
                                                                                                i_cmdpkt.lba(8*(5+1)-1 downto 8*5)<=p_in_usr_cxd(15 downto 8);

      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_SECTOR_COUNT, i_cmdpkt_cnt'length) then i_cmdpkt.scount<=p_in_usr_cxd;
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DEVICE, i_cmdpkt_cnt'length)       then i_cmdpkt.device<=p_in_usr_cxd(7 downto 0);
                                                                                                i_cmdpkt.control<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_COMMAND, i_cmdpkt_cnt'length)      then i_cmdpkt.command<=p_in_usr_cxd(7 downto 0);
--      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_RAID_CL, i_cmdpkt_cnt'length)      then i_cmdpkt.raid_cl<=p_in_usr_cxd;

      end if;
    end if; --//if p_in_usr_cxd_wr='1' then

  end if;
end process;

--//Отправка командного пакета в модуль sata_host.vhd
i_sh_cmd_start<=(i_cmdpkt_get_done and not i_usrmode.hw_work and not i_usrmode.lbaend) or
                (sr_sh_cmddone(1) and i_usrmode.hw_work);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_sh_cmdcnt<=(others=>'0');
    i_sh_cmdcnt_en<='0';

    i_sh_cxd_sof<='0';
    i_sh_cxd_eof<='0';
    i_sh_cxd_src_rdy<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    if i_sh_cmd_start='1' then
      i_sh_cmdcnt_en<='1';
    elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DCOUNT, i_sh_cmdcnt'length) then
      i_sh_cmdcnt_en<='0';
    end if;

    if i_sh_cmdcnt_en='0' then
      i_sh_cmdcnt<=(others=>'0');
    else
      i_sh_cmdcnt<=i_sh_cmdcnt + 1;
    end if;

    if i_sh_cmdcnt_en='1' and i_sh_cmdcnt=(i_sh_cmdcnt'range=>'0') then
      i_sh_cxd_sof<='1';
    else
      i_sh_cxd_sof<='0';
    end if;

    if i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DCOUNT, i_sh_cmdcnt'length) then
      i_sh_cxd_eof<='1';
    else
      i_sh_cxd_eof<='0';
    end if;

    i_sh_cxd_src_rdy<=i_sh_cmdcnt_en;

  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_sh_cxdout<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if i_sh_cmdcnt_en='1' then
      if    i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_USRCTRL, i_sh_cmdcnt'length)      then i_sh_cxdout<=i_cmdpkt.ctrl;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_FEATURE, i_sh_cmdcnt'length)      then i_sh_cxdout<=i_cmdpkt.feature;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_LOW, i_sh_cmdcnt'length)      then i_sh_cxdout( 7 downto 0)<=i_lba_cnt(8*(0+1)-1 downto 8*0);--lba_low
                                                                                              i_sh_cxdout(15 downto 8)<=i_lba_cnt(8*(3+1)-1 downto 8*3);--lba_low(exp)
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_MID, i_sh_cmdcnt'length)      then i_sh_cxdout( 7 downto 0)<=i_lba_cnt(8*(1+1)-1 downto 8*1);--lba_mid
                                                                                              i_sh_cxdout(15 downto 8)<=i_lba_cnt(8*(4+1)-1 downto 8*4);--lba_mid(exp)
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_LBA_HIGH, i_sh_cmdcnt'length)     then i_sh_cxdout( 7 downto 0)<=i_lba_cnt(8*(2+1)-1 downto 8*2);--lba_high
                                                                                              i_sh_cxdout(15 downto 8)<=i_lba_cnt(8*(5+1)-1 downto 8*5);--lba_high(exp)
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_SECTOR_COUNT, i_sh_cmdcnt'length) then i_sh_cxdout<=i_cmdpkt.scount;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_DEVICE, i_sh_cmdcnt'length)       then i_sh_cxdout( 7 downto 0)<=i_cmdpkt.device;
                                                                                              i_sh_cxdout(15 downto 8)<=i_cmdpkt.control;

      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_COMMAND, i_sh_cmdcnt'length)      then i_sh_cxdout( 7 downto 0)<=i_cmdpkt.command;
                                                                                              i_sh_cxdout(15 downto 8)<=(others=>'0');
--      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_HDDPKT_RAID_CL, i_sh_cmdcnt'length)      then i_sh_cxdout<=i_cmdpkt.raid_cl;
      end if;
    end if;

  end if;
end process;


p_out_sh_mask<=i_cmdpkt.ctrl(G_HDD_COUNT+C_HDDPKT_SATA_CS_L_BIT-1 downto C_HDDPKT_SATA_CS_L_BIT);

p_out_sh_cxd<=i_sh_cxdout;
p_out_sh_cxd_sof_n<=not i_sh_cxd_sof;
p_out_sh_cxd_eof_n<=not i_sh_cxd_eof;
p_out_sh_cxd_src_rdy_n<=not i_sh_cxd_src_rdy;




--//------------------------------------------
--//Декодирование режима работы
--//------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_usrmode.hw_work<='0';
    i_sh_padding_en<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    --//Работа в HW режиме
    if (i_usrmode.stop='1' and i_cmdpkt_get_done='1') or i_sh_det.err='1' or (i_lba_cnt>=i_lba_end and sr_sh_cmddone(0)='1') then
      i_usrmode.hw_work<='0';
    elsif i_usrmode.hw='1' and i_cmdpkt_get_done='1' then
      i_usrmode.hw_work<='1';
    end if;

    if i_cmdpkt_get_done='1' then
      if i_usrmode.stop='1' and i_cmdpkt.ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT)=CONV_STD_LOGIC_VECTOR(C_SATACMD_NULL, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1) then
        i_sh_padding_en<='1';
      else
        i_sh_padding_en<='0';
      end if;
    end if;

  end if;
end process;

--//Cчетчик адреса LBA
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_lba_cnt<=(others=>'0');
    i_lba_inc<=(others=>'0');
    i_lba_random<=srambler32_0(CONV_STD_LOGIC_VECTOR(16#1864#, 16));
  elsif p_in_clk'event and p_in_clk='1' then

    if (i_usrmode.sw='1' or i_usrmode.hw='1') and i_cmdpkt_get_done='1' then
    --//Загрузка счетчика LBA + значения наращивания
      i_lba_cnt<=i_cmdpkt.lba;
      i_lba_inc<=i_cmdpkt.scount;

    elsif i_sh_det.cmddone='1' then
    --//LBA update
      if p_in_usr_ctrl(C_USR_GCTRL_TST_RANDOM_BIT)='0' then
        i_lba_cnt<=i_lba_cnt + EXT(i_lba_inc, i_lba_cnt'length);
      else
        if i_lba_cnt>i_lba_end then
          i_lba_cnt(31 downto 0)<=i_lba_random(31 downto 0);
          i_lba_cnt(31+7 downto 0+7)<=(others=>'0');
        else
          i_lba_cnt(31+7 downto 0+7)<=i_lba_random(31 downto 0);
        end if;
      end if;
    end if;

    if p_in_usr_ctrl(C_USR_GCTRL_TST_RANDOM_BIT)='1' then
      i_lba_random(31 downto 0)<=srambler32_0(i_lba_random(31 downto 16));
    end if;
  end if;
end process;

--//Set LBA End
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_lba_end<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if i_usrmode.lbaend='1' and i_cmdpkt_get_done='1' then
      i_lba_end<=i_cmdpkt.lba;
    end if;

  end if;
end process;



--//-----------------------------
--//Запись/Чтение буферов модулей sata_host
--//-----------------------------
p_out_sh_hdd<=i_sh_hddcnt;

--//запись в TxBUF sata_host
p_out_sh_txd<=p_in_usr_txd when p_in_usr_ctrl(C_USR_GCTRL_TST_ON_BIT)='0' or p_in_usr_ctrl(C_USR_GCTRL_TST_GEN2RAMBUF_BIT)='1' else i_testing_data;
p_out_sh_txd_wr<=i_sh_txd_wr;

i_usr_txbuf_empty<=p_in_usr_txbuf_empty when p_in_usr_ctrl(C_USR_GCTRL_TST_ON_BIT)='0' or p_in_usr_ctrl(C_USR_GCTRL_TST_GEN2RAMBUF_BIT)='1' else not i_usr_status.dev_bsy;

i_sh_txd_wr<=(i_sh_padding or not i_usr_txbuf_empty) and not p_in_sh_txbuf_full when p_in_raid.used='0' else --//Работа с одним HDD
             (i_sh_padding or not i_usr_txbuf_empty) and not p_in_sh_txbuf_full and i_sh_trn_en;             --//Работа с RAID

p_out_usr_txd_rd<=i_sh_txd_wr when p_in_usr_ctrl(C_USR_GCTRL_TST_ON_BIT)='0' or p_in_usr_ctrl(C_USR_GCTRL_TST_GEN2RAMBUF_BIT)='1' else '0';


--//чтение из RxBUF sata_host
p_out_usr_rxd<=p_in_sh_rxd;
--p_out_usr_rxd_wr<=i_sh_rxd_rd;--//sata_rxfifo - FWFT(First-Word-Fall-Through) FIFO

--//sata_rxfifo - SATANDART FIFO (Добавляем задержку т.к.
--//данные на выходе появляюся после отработки 1clk сигнала rd)
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    if p_in_usr_ctrl(C_USR_GCTRL_TST_ON_BIT)='0' or p_in_usr_ctrl(C_USR_GCTRL_TST_GEN2RAMBUF_BIT)='1' then
      p_out_usr_rxd_wr<=i_sh_rxd_rd;
    else
      p_out_usr_rxd_wr<='0';
    end if;
  end if;
end process;

i_usr_rxbuf_full<=p_in_usr_rxbuf_full when p_in_usr_ctrl(C_USR_GCTRL_TST_ON_BIT)='0' or p_in_usr_ctrl(C_USR_GCTRL_TST_GEN2RAMBUF_BIT)='1' else '0';

i_sh_rxd_rd<=(i_sh_padding or not i_usr_rxbuf_full) and not p_in_sh_rxbuf_empty  when p_in_raid.used='0' else --//Работа с одним HDD
             (i_sh_padding or not i_usr_rxbuf_full) and not p_in_sh_rxbuf_empty and i_sh_trn_en;              --//Работа с RAID

p_out_sh_rxd_rd<=i_sh_rxd_rd;



--//Формируем сигнал разрешения пермещения данных
i_sh_trn_den<=i_sh_txd_wr or i_sh_rxd_rd;

i_sh_trn_byte_count<=i_cmdpkt.scount&CONV_STD_LOGIC_VECTOR(0, log2(CI_SECTOR_SIZE_BYTE));
i_sh_trn_dw_count<=("00"&i_sh_trn_byte_count(i_sh_trn_byte_count'high downto 2));

process(p_in_rst,p_in_clk)
  variable raid_cl_done: std_logic;
begin
  if p_in_rst='1' then
    raid_cl_done:='0';

    i_sh_trn_en<='0';
    sr_raid_cl_done<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    raid_cl_done:='0';

    if i_sh_det.cmddone='1' or i_err_clr='1' then
    --//
      i_sh_trn_en<='0';

    elsif p_in_raid.used='1' then
    --//Режим работы с RAID
        if (i_sh_cmd_start='1' or i_raid_cl_next='1') then
          i_sh_trn_en<='1';
        else
          if i_sh_trn_en='1' and i_sh_trn_den='1' and i_raid_cl_cntdw=(i_sh_trn_dw_count - 1) then
          --//Завершена отработка одно кластера RAID
            i_sh_trn_en<='0';
            raid_cl_done:='1';
          end if;
        end if;
    end if;

    sr_raid_cl_done<=raid_cl_done & sr_raid_cl_done(0 to 1);

  end if;
end process;

--//Счетчик одного кластера данных RAID
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_raid_cl_cntdw<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if i_sh_trn_en='0' then
      i_raid_cl_cntdw<=(others=>'0');

    elsif p_in_raid.used='1' and i_sh_trn_den='1' then
       i_raid_cl_cntdw<=i_raid_cl_cntdw+1;
    end if;
  end if;
end process;


--//Счетчик hdd RAID
gen_sh_bufadr_ld : for i in 0 to i_sh_hddcnt'high generate
--//Если работаем с одним HDD: загружаем номер соотв. HDD
--//Если работаем с      RAID: загружаем 0 (т.е. всегда начинаем с sata_host=0)
i_sh_hddcnt_ld(i)<=p_in_sh_num(i) and not p_in_raid.used;
end generate gen_sh_bufadr_ld;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_sh_hddcnt<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_sh_cmd_start='1' then
      i_sh_hddcnt<=i_sh_hddcnt_ld;
    elsif sr_raid_cl_done(2)='1' then
      i_sh_hddcnt<=i_sh_hddcnt+1;
    end if;
  end if;
end process;

--//Сигнал запуска следующего кластера RAID
process(p_in_rst,p_in_clk)
  variable raid_cl_next: std_logic;
begin
  if p_in_rst='1' then
      raid_cl_next:='0';
    i_raid_cl_next<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    raid_cl_next:='0';

    if i_sh_hddcnt/=p_in_raid.hddcount then
      raid_cl_next:=sr_raid_cl_done(2);
    end if;

    i_raid_cl_next<=raid_cl_next;

  end if;
end process;



--//-----------------------------------
--//TST_GENERATOR
--//-----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_testing_cmd<=(others=>'0');
    i_testing_data<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    if (i_usrmode.sw='1' or i_usrmode.hw='1') and i_cmdpkt_get_done='1' then
    --//защелкиваем АТА команду для опреденения направления тестирования
      i_testing_cmd<=i_cmdpkt.command;
    end if;

    if p_in_usr_ctrl(C_USR_GCTRL_TST_ON_BIT)='0' then
      i_testing_data<=(others=>'0');
    else
      if i_sh_txd_wr='1' and
        (i_testing_cmd=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_SECTORS_EXT, i_testing_cmd'length) or
         i_testing_cmd=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, i_testing_cmd'length) ) then
      --//Генерация тестовых данных, только для перечисленых выше команд!!!
        i_testing_data<=i_testing_data + 1;
      end if;
    end if;

  end if;
end process;





--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_dbgcs.clk   <=p_in_clk;
p_out_dbgcs.trig0 <=(others=>'0');
p_out_dbgcs.data  <=(others=>'0');
end generate gen_dbgcs_off;


gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate

p_out_dbgcs.clk   <=p_in_clk;
process(p_in_clk)
begin
if p_in_clk'event and p_in_clk='1' then

p_out_dbgcs.trig0(0)<=i_sh_det.cmddone;
p_out_dbgcs.trig0(1)<=i_sh_trn_en;
p_out_dbgcs.trig0(2)<=i_sh_txd_wr;
p_out_dbgcs.trig0(3)<=i_sh_rxd_rd;
p_out_dbgcs.trig0(4)<=p_in_usr_txbuf_empty;
p_out_dbgcs.trig0(5)<=p_in_sh_rxbuf_empty;
p_out_dbgcs.trig0(6)<=p_in_sh_txbuf_full;
p_out_dbgcs.trig0(7)<=OR_reduce(i_tst_cnt(3 downto 0));
p_out_dbgcs.trig0(8)<=i_tst_ch_bsy_done(0);
p_out_dbgcs.trig0(9)<=i_tst_ch_bsy_done(1);
p_out_dbgcs.trig0(11 downto 10)<=(others=>'0');
p_out_dbgcs.trig0(14 downto 12)<=i_sh_hddcnt(2 downto 0);
p_out_dbgcs.trig0(15)          <=sr_raid_cl_done(2);
p_out_dbgcs.trig0(16)          <=i_sh_cxd_sof;
p_out_dbgcs.trig0(17)          <=OR_reduce(i_tst_cnt(7 downto 4));
p_out_dbgcs.trig0(18)<=tst_cmddone and i_tst_bsy(1) and not i_tst_bsy(0);
p_out_dbgcs.trig0(19)<='0';--зарезервировано для tmr_timeout
p_out_dbgcs.trig0(24 downto 20)<=(others=>'0');--зарезервировано для i_fsm_llayer(4 downto 0);--sh0
p_out_dbgcs.trig0(29 downto 25)<=(others=>'0');--зарезервировано для i_fsm_tlayer(4 downto 0);
p_out_dbgcs.trig0(34 downto 30)<=(others=>'0');--зарезервировано для i_fsm_llayer(4 downto 0);--sh1
p_out_dbgcs.trig0(39 downto 35)<=(others=>'0');--зарезервировано для i_fsm_tlayer(4 downto 0);
p_out_dbgcs.trig0(40)<='0';--рарезервировано
p_out_dbgcs.trig0(41)<='0';

p_out_dbgcs.data(0)<=i_sh_det.cmddone;
p_out_dbgcs.data(1)<=i_sh_trn_en;
p_out_dbgcs.data(2)<=i_sh_txd_wr;
p_out_dbgcs.data(3)<=i_sh_rxd_rd;
p_out_dbgcs.data(4)<=p_in_usr_txbuf_empty;
p_out_dbgcs.data(5)<=p_in_sh_rxbuf_empty;
p_out_dbgcs.data(6)<=p_in_sh_txbuf_full;
p_out_dbgcs.data(7)<=sr_raid_cl_done(2);
p_out_dbgcs.data(8)<=i_usr_status.ch_bsy(0);
p_out_dbgcs.data(9)<=i_usr_status.ch_bsy(1);
p_out_dbgcs.data(10)<=i_sh_hddcnt(0);
p_out_dbgcs.data(11)<=i_sh_hddcnt(1);
p_out_dbgcs.data(27 downto 12)<=i_usr_status.ch_atastatus(1)&i_usr_status.ch_atastatus(0);--i_tst_cnt(15 downto 0);
p_out_dbgcs.data(28)<=i_tst_bsy(1);--i_sh_cxd_src_rdy;
p_out_dbgcs.data(29)<='0';--//зарезервировано
p_out_dbgcs.data(122 downto 30)<=(others=>'0');--//зарезервировано

if p_in_usr_cxd_wr='1' then
  i_tst_cnt<=(others=>'0');
else
  if i_sh_txd_wr='1' or i_sh_rxd_rd='1' then
    i_tst_cnt<=i_tst_cnt + 1;
  end if;
end if;

for i in 0 to G_HDD_COUNT-1 loop
i_tst_sr_ch_bsy(i)<=i_usr_status.ch_bsy(i);
i_tst_ch_bsy_done(i)<=not i_usr_status.ch_bsy(i) and i_tst_sr_ch_bsy(i);

i_tst_bsy(i)<=i_usr_status.ch_atastatus(i)(C_ATA_STATUS_BUSY_BIT) or i_usr_status.ch_atastatus(i)(C_ATA_STATUS_DRQ_BIT);
end loop;

sr_tst_bsy<=OR_reduce(i_tst_bsy(G_HDD_COUNT-1 downto 0)) & sr_tst_bsy(0 to 0);
tst_cmddone<=sr_tst_bsy(1) and not sr_tst_bsy(0);

end if;
end process;

end generate gen_dbgcs_on;


--END MAIN
end behavioral;


