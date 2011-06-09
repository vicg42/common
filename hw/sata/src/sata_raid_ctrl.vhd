-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 18:27:17
-- Module Name : sata_raid_ctrl
--
-- Назначение :
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
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_raid_pkg.all;

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

signal i_err_rambuf                : std_logic;
signal i_usr_status                : TUsrStatus;
signal sr_dev_busy                 : std_logic;

signal sr_dev_err                  : std_logic_vector(0 to 1);
type TShDetect is record
cmddone : std_logic;
err     : std_logic;
end record;
signal i_sh_det                    : TShDetect;
signal sr_sh_cmddone               : std_logic_vector(0 to 1);

signal i_cmdpkt                    : TUsrCmdPkt;
signal i_cmdpkt_cnt                : std_logic_vector(3 downto 0);--//счетчик данных принимаемого командного пакета
signal i_cmdpkt_get_done           : std_logic;                   --//Прием cmd пакета завершен

signal i_dmacfg_start              : std_logic;

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

signal i_lba_cnt                   : std_logic_vector(i_cmdpkt.lba'range);
signal i_lba_end                   : std_logic_vector(i_cmdpkt.lba'range);

signal i_trn_dcount_byte           : std_logic_vector(i_cmdpkt.scount'length + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);
signal i_trn_dcount_dw             : std_logic_vector(i_trn_dcount_byte'range);

signal i_sh_hddcnt_ld              : std_logic_vector(p_in_sh_num'range);
signal i_sh_hddcnt                 : std_logic_vector(p_in_sh_num'range);
signal i_sh_trn_en                 : std_logic;
signal i_sh_trn_den                : std_logic;
signal i_sh_txd_wr                 : std_logic;
signal i_sh_rxd_rd                 : std_logic;
signal i_raid_atrncnt              : std_logic_vector(i_trn_dcount_dw'range);
signal i_raid_atrn_done            : std_logic;
signal sr_raid_atrn_done           : std_logic_vector(0 to 2);
signal i_raid_atrn_next            : std_logic;
--signal i_raid_trn_done             : std_logic;

signal i_dwr_start                 : std_logic_vector(G_HDD_COUNT-1 downto 0);

signal i_tst                       : std_logic_vector(G_HDD_COUNT-1 downto 0);



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

p_out_tst(0)<=OR_reduce(i_tst) or p_in_usr_ctrl(C_USR_GCTRL_RESERV_BIT);
p_out_tst(31 downto 1)<=(others=>'0');
end generate gen_dbg_on;



--//------------------------------------------
--//Инициализация
--//------------------------------------------
i_err_rambuf<=p_in_usr_ctrl(C_USR_GCTRL_RAMBUF_ERR_BIT);--//Только для режима HW


--//----------------------------------
--//Формирую отчеты
--//----------------------------------
p_out_usr_status<=i_usr_status;

i_usr_status.dmacfg.sw_mode<=i_usrmode.sw;
i_usr_status.dmacfg.hw_mode<=i_usrmode.hw;
i_usr_status.dmacfg.tst_mode<='0';
i_usr_status.dmacfg.start<=i_dmacfg_start;--i_sh_cmd_start;


i_usr_status.dmacfg.wr_start<=OR_reduce(i_dwr_start);
i_usr_status.dmacfg.raid.used<=p_in_raid.used;
i_usr_status.dmacfg.raid.hddcount<=p_in_raid.hddcount;
i_usr_status.dmacfg.scount<=i_cmdpkt.scount;
i_usr_status.dmacfg.error<=i_usr_status.dev_err;


--//кол-во HDD подключенных к FPGA
i_usr_status.hdd_count<=CONV_STD_LOGIC_VECTOR(G_HDD_COUNT, i_usr_status.hdd_count'length);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_usr_status.dev_busy<='1';
    i_usr_status.dev_rdy<='0';
    i_usr_status.dev_err<='0';
--    i_usr_status.usr<=(others=>'0');
    i_usr_status.lba_bp<=(others=>'0');
    for i in 0 to G_HDD_COUNT-1 loop
--      i_usr_status.ch_usr(i)<=(others=>'0');
      i_usr_status.ch_busy(i)<='1';
      i_usr_status.ch_drdy(i)<='0';
      i_usr_status.ch_err(i)<='0';
      i_usr_status.SError(i)<=(others=>'0');
    end loop;

    i_dwr_start<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    i_usr_status.dev_busy<=OR_reduce(i_usr_status.ch_busy(G_HDD_COUNT-1 downto 0));
    i_usr_status.dev_rdy<=AND_reduce(i_usr_status.ch_drdy(G_HDD_COUNT-1 downto 0));
    i_usr_status.dev_err<=OR_reduce(i_usr_status.ch_err(G_HDD_COUNT-1 downto 0)) or i_err_rambuf;
    i_usr_status.lba_bp<=i_lba_cnt;
--    i_usr_status.usr<=(others=>'0');

    for i in 0 to G_HDD_COUNT-1 loop
      i_usr_status.ch_busy(i)<=p_in_sh_status(i).Usr(C_AUSER_BUSY_BIT);
      i_usr_status.ch_drdy(i)<=p_in_sh_status(i).ATAStatus(C_ATA_STATUS_DRDY_BIT);

      i_usr_status.ch_err(i)<=p_in_sh_status(i).ATAStatus(C_ATA_STATUS_ERR_BIT) or
                              p_in_sh_status(i).SError(C_ASERR_I_ERR_BIT) or
                              p_in_sh_status(i).SError(C_ASERR_C_ERR_BIT) or
                              p_in_sh_status(i).SError(C_ASERR_P_ERR_BIT);

--      i_usr_status.ch_usr(i)<=(others=>'0');
      i_usr_status.SError(i)<=p_in_sh_status(i).SError;

      i_dwr_start(i)<=p_in_sh_status(i).Usr(C_AUSER_DWR_START_BIT);

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
    sr_dev_busy<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    sr_dev_err<=i_usr_status.dev_err & sr_dev_err(0 to 0);

    sr_dev_busy<=i_usr_status.dev_busy;
    i_sh_det.cmddone<=(i_usrmode.sw and p_in_usr_ctrl(C_USR_GCTRL_ATADONE_ACK_BIT)) or
                      (sr_dev_busy and not i_usr_status.dev_busy);

    i_sh_det.err<=sr_dev_err(0) and not sr_dev_err(1);

    sr_sh_cmddone<=i_sh_det.cmddone & sr_sh_cmddone(0 to 0);
  end if;
end process;

--i_buf_padd<=i_usr_status.dev_busy


gen_sh_pout : for i in 0 to C_HDD_COUNT_MAX-1 generate
p_out_sh_tst(i)<=(others=>'0'); --//технологические входы модулей sata_host
p_out_sh_ctrl(i)<=p_in_usr_ctrl;--//передача глобального управления модулям sata_host
end generate gen_sh_pout;




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
      if i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_USRAPP_CMDPKT_SIZE_WORD-1, i_cmdpkt_cnt'length) then
        i_cmdpkt_cnt<=(others=>'0');
      else
        i_cmdpkt_cnt<=i_cmdpkt_cnt + 1;
      end if;

      if i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_USRAPP_CMDPKT_SIZE_WORD-1, i_cmdpkt_cnt'length) then
        i_cmdpkt_get_done<='1';
      end if;
    else
      i_cmdpkt_get_done<='0';
    end if;

  end if;
end process;

--//Прием командного пакета
process(p_in_rst,p_in_clk)
  variable raidcmd: std_logic_vector(C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT downto 0);
  variable dmacfg_start: std_logic;
begin
  if p_in_rst='1' then
    i_cmdpkt.ctrl<=(others=>'0');
    i_cmdpkt.feature<=(others=>'0');
    i_cmdpkt.lba<=(others=>'0');
    i_cmdpkt.scount<=(others=>'0');
    i_cmdpkt.command<=(others=>'0');
    i_cmdpkt.control<=(others=>'0');
    i_cmdpkt.device<=(others=>'0');

    i_usrmode.stop<='0';
    i_usrmode.sw<='0';
    i_usrmode.hw<='0';
    i_usrmode.lbaend<='0';

      dmacfg_start:='0';
    i_dmacfg_start<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    dmacfg_start:='0';

    if p_in_usr_cxd_wr='1' then
      if    i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_ALREG_USRCTRL, i_cmdpkt_cnt'length)      then i_cmdpkt.ctrl<=p_in_usr_cxd;

          raidcmd:=p_in_usr_cxd(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT);

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

      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_ALREG_FEATURE, i_cmdpkt_cnt'length)      then i_cmdpkt.feature<=p_in_usr_cxd;
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_LOW, i_cmdpkt_cnt'length)      then i_cmdpkt.lba(8*(0+1)-1 downto 8*0)<=p_in_usr_cxd( 7 downto 0);
                                                                                               i_cmdpkt.lba(8*(1+1)-1 downto 8*1)<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_MID, i_cmdpkt_cnt'length)      then i_cmdpkt.lba(8*(2+1)-1 downto 8*2)<=p_in_usr_cxd( 7 downto 0);
                                                                                               i_cmdpkt.lba(8*(3+1)-1 downto 8*3)<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_HIGH, i_cmdpkt_cnt'length)     then i_cmdpkt.lba(8*(4+1)-1 downto 8*4)<=p_in_usr_cxd( 7 downto 0);
                                                                                               i_cmdpkt.lba(8*(5+1)-1 downto 8*5)<=p_in_usr_cxd(15 downto 8);

      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_ALREG_SECTOR_COUNT, i_cmdpkt_cnt'length) then i_cmdpkt.scount<=p_in_usr_cxd;
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_ALREG_DEVICE, i_cmdpkt_cnt'length)       then i_cmdpkt.device<=p_in_usr_cxd(7 downto 0);
                                                                                               i_cmdpkt.control<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdpkt_cnt=CONV_STD_LOGIC_VECTOR(C_ALREG_COMMAND, i_cmdpkt_cnt'length)      then i_cmdpkt.command<=p_in_usr_cxd(7 downto 0);

        --//Разрешаем использование RAMBUF только для пречисленых ниже команд:
        if  p_in_usr_cxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_IDENTIFY_DEV, i_cmdpkt.command'length) or
            p_in_usr_cxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_SECTORS_EXT, i_cmdpkt.command'length) or
            p_in_usr_cxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_SECTORS_EXT, i_cmdpkt.command'length) or
            p_in_usr_cxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, i_cmdpkt.command'length) or
            p_in_usr_cxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_DMA_EXT, i_cmdpkt.command'length)  or
            i_cmdpkt.ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT)=CONV_STD_LOGIC_VECTOR(C_SATACMD_FPDMA_W, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1) or
            i_cmdpkt.ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT)=CONV_STD_LOGIC_VECTOR(C_SATACMD_FPDMA_R, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1) then

              dmacfg_start:='1';
        end if;

      end if;
    end if;

    i_dmacfg_start<=dmacfg_start;
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
    elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_USRAPP_CMDPKT_SIZE_WORD, i_sh_cmdcnt'length) then
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

    if i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_USRAPP_CMDPKT_SIZE_WORD, i_sh_cmdcnt'length) then
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
      if    i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_USRCTRL, i_sh_cmdcnt'length)     then i_sh_cxdout<=i_cmdpkt.ctrl;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_FEATURE, i_sh_cmdcnt'length)     then i_sh_cxdout<=i_cmdpkt.feature;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_LOW, i_sh_cmdcnt'length)     then i_sh_cxdout(7 downto 0) <=i_lba_cnt(8*(0+1)-1 downto 8*0);--lba_low
                                                                                            i_sh_cxdout(15 downto 8)<=i_lba_cnt(8*(3+1)-1 downto 8*3);--lba_low(exp)
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_MID, i_sh_cmdcnt'length)     then i_sh_cxdout(7 downto 0) <=i_lba_cnt(8*(1+1)-1 downto 8*1);--lba_mid
                                                                                            i_sh_cxdout(15 downto 8)<=i_lba_cnt(8*(4+1)-1 downto 8*4);--lba_mid(exp)
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_HIGH, i_sh_cmdcnt'length)    then i_sh_cxdout(7 downto 0) <=i_lba_cnt(8*(2+1)-1 downto 8*2);--lba_high
                                                                                            i_sh_cxdout(15 downto 8)<=i_lba_cnt(8*(5+1)-1 downto 8*5);--lba_high(exp)
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_SECTOR_COUNT, i_sh_cmdcnt'length)then i_sh_cxdout<=i_cmdpkt.scount;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_DEVICE, i_sh_cmdcnt'length)      then i_sh_cxdout(7 downto 0)<=i_cmdpkt.device;
                                                                                            i_sh_cxdout(15 downto 8)<=i_cmdpkt.control;

      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_COMMAND, i_sh_cmdcnt'length)     then i_sh_cxdout(7 downto 0)<=i_cmdpkt.command;
                                                                                            i_sh_cxdout(15 downto 8)<=(others=>'0');
      end if;
    end if;

  end if;
end process;


p_out_sh_mask<=i_cmdpkt.ctrl(G_HDD_COUNT+C_CMDPKT_SATA_CS_L_BIT-1 downto C_CMDPKT_SATA_CS_L_BIT);

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

  elsif p_in_clk'event and p_in_clk='1' then
    --//Работа в HW режиме
    if (i_usrmode.stop='1' and i_cmdpkt_get_done='1') or i_sh_det.err='1' or (i_lba_cnt>=i_lba_end and sr_sh_cmddone(0)='1') then
      i_usrmode.hw_work<='0';
    elsif i_usrmode.hw='1' and i_cmdpkt_get_done='1' then
      i_usrmode.hw_work<='1';
    end if;

  end if;
end process;

--//Cчетчик адреса LBA
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_lba_cnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if (i_usrmode.sw='1' or i_usrmode.hw='1') and i_cmdpkt_get_done='1' then
      i_lba_cnt<=i_cmdpkt.lba;

    elsif i_sh_det.cmddone='1' then
      i_lba_cnt<=i_lba_cnt + EXT(i_cmdpkt.scount, i_lba_cnt'length);
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
p_out_sh_txd<=p_in_usr_txd;
p_out_sh_txd_wr <=i_sh_txd_wr;

i_sh_txd_wr<=i_sh_trn_en and not p_in_usr_txbuf_empty and not p_in_sh_txbuf_full when p_in_raid.used='1' else
             not p_in_usr_txbuf_empty and not p_in_sh_txbuf_full;

p_out_usr_txd_rd<=i_sh_txd_wr;


--//чтение из RxBUF sata_host
p_out_usr_rxd<=p_in_sh_rxd;
--p_out_usr_rxd_wr<=i_sh_rxd_rd;--//sata_rxfifo - FIRST WORD

--//sata_rxfifo - SATANDART FIFO (Добавляем задержку т.к.
--//данные на выходе появляюся после отработки 1clk сигнала rd)
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    p_out_usr_rxd_wr<=i_sh_rxd_rd;
  end if;
end process;

i_sh_rxd_rd<=i_sh_trn_en and not p_in_usr_rxbuf_full and not p_in_sh_rxbuf_empty when p_in_raid.used='1' else
             not p_in_usr_rxbuf_full and not p_in_sh_rxbuf_empty;

p_out_sh_rxd_rd<=i_sh_rxd_rd;



--//Формируем сигнал разрешения пермещения данных
i_sh_trn_den<=i_sh_txd_wr or i_sh_rxd_rd;

i_trn_dcount_byte<=i_cmdpkt.scount&CONV_STD_LOGIC_VECTOR(0, log2(CI_SECTOR_SIZE_BYTE));
i_trn_dcount_dw<=("00"&i_trn_dcount_byte(i_trn_dcount_byte'high downto 2));

process(p_in_rst,p_in_clk)
  variable raid_atrn_done: std_logic;
begin
  if p_in_rst='1' then
    raid_atrn_done:='0';

    i_sh_trn_en<='0';
    i_raid_atrn_done<='0';
    sr_raid_atrn_done<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    raid_atrn_done:='0';

    if i_sh_det.cmddone='1' or i_sh_det.err='1' then
    --//
      i_sh_trn_en<='0';

--    elsif p_in_raid.used='0' and i_sh_cmd_start='1' then
--    --//Режим работы с одним HDD
--      i_sh_trn_en<='1';

    elsif p_in_raid.used='1' then
    --//Режим работы с RAID
        if (i_sh_cmd_start='1' or i_raid_atrn_next='1') then
          i_sh_trn_en<='1';
        else
          if i_sh_trn_en='1' and i_sh_trn_den='1' and i_raid_atrncnt=i_trn_dcount_dw then
            i_sh_trn_en<='0';
            raid_atrn_done:='1';--//Выполнена транзакия для одного HDD (атомарная операция)
          end if;
        end if;
    end if;

    i_raid_atrn_done<=raid_atrn_done;
    sr_raid_atrn_done<=i_raid_atrn_done & sr_raid_atrn_done(0 to 1);

  end if;
end process;

--//Счетчик данных атомарной транзакции RAID
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_raid_atrncnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if i_sh_trn_en='0' then
      i_raid_atrncnt<=(others=>'0');

    elsif p_in_raid.used='1' and i_sh_trn_den='1' then
       i_raid_atrncnt<=i_raid_atrncnt+1;
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
    elsif sr_raid_atrn_done(2)='1' then
      i_sh_hddcnt<=i_sh_hddcnt+1;
    end if;
  end if;
end process;


process(p_in_rst,p_in_clk)
  variable raid_atrn_next: std_logic;
  variable raid_trn_tx_done: std_logic;
begin
  if p_in_rst='1' then
    raid_atrn_next:='0';
    raid_trn_tx_done:='0';

    i_raid_atrn_next<='0';
--    i_raid_trn_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    raid_atrn_next:='0';
--    raid_trn_tx_done:='0';

    --//Сигнал начать следующую атормарную транзакцию RAID
    if sr_raid_atrn_done(2)='1' and i_sh_hddcnt/=p_in_raid.hddcount then
      raid_atrn_next:='1';
    end if;

    --//Тразакция перемещения данных выполнена (только для RAID)
    if sr_raid_atrn_done(2)='1' and i_sh_hddcnt=p_in_raid.hddcount then
      raid_trn_tx_done:='1';
    end if;

    i_raid_atrn_next<=raid_atrn_next;
--    i_raid_trn_done<=raid_trn_tx_done;

  end if;
end process;




--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
p_out_dbgcs.clk   <='0';--p_in_clk;
p_out_dbgcs.trig0 <=(others=>'0');--EXT(i_dbgcs_trig00, p_out_dbgcs_ila.trig0'length);
p_out_dbgcs.data  <=(others=>'0');--;--EXT(i_dbgcs_data, p_out_dbgcs_ila.data'length);
--
--process(p_in_clk)
--begin
--if p_in_clk'event and p_in_clk='1' then
--i_dbgcs_trig00(18 downto 0)<=(others=>'0');
--i_dbgcs_trig00(41 downto 19)<=(others=>'0');
--
--i_dbgcs_data(18 downto 0)<=(others=>'0');
--i_dbgcs_data(122 downto 19)<=(others=>'0');
--
--end if;
--end process;



--END MAIN
end behavioral;


