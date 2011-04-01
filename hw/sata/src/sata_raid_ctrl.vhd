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

use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;

entity sata_raid_ctrl is
generic
(
G_HDD_COUNT : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port
(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           : in    std_logic_vector(31 downto 0);
p_out_usr_status        : out   TUsrStatus;

p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_out_usr_cxd_rd        : out   std_logic;
p_in_usr_cxbuf_empty    : in    std_logic;

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_in_sh_status          : in    TALStatus_SataCountMax;
p_out_sh_ctrl           : out   TALCtrl_SataCountMax;

p_out_sh_cxd            : out   std_logic_vector(15 downto 0);
p_out_sh_cxd_sof_n      : out   std_logic;
p_out_sh_cxd_eof_n      : out   std_logic;
p_out_sh_cxd_src_rdy_n  : out   std_logic;
p_out_sh_mask           : out   std_logic_vector(7 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end sata_raid_ctrl;

architecture behavioral of sata_raid_ctrl is

signal i_usr_status                : TUsrStatus;

signal sr_glob_busy                : std_logic_vector(0 to 1);
signal sr_glob_err                 : std_logic_vector(0 to 1);
type TShDetect is record
cmddone : std_logic;
err     : std_logic;
end record;
signal i_sh_det                    : TShDetect;

signal i_cmdfifo_rd                : std_logic;
signal i_cmdfifo_dcnt              : std_logic_vector(3 downto 0);
signal i_cmdfifo_rd_done           : std_logic;
signal i_cmdpkt                    : TUsrCmdPkt;

signal i_sh_mask                   : std_logic_vector(C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT downto 0);
signal i_sh_cmd_start              : std_logic;
signal i_sh_cmdcnt                 : std_logic_vector(3 downto 0);
signal i_sh_cmdcnt_en              : std_logic;
signal i_sh_cxdout                 : std_logic_vector(15 downto 0);
signal i_sh_cxd_sof                : std_logic;
signal i_sh_cxd_eof                : std_logic;
signal i_sh_cxd_src_rdy            : std_logic;

type TUserMode is record
sw       : std_logic;
sw_work  : std_logic;
hw       : std_logic;
hw_work  : std_logic;
tst      : std_logic;
tst_work : std_logic;
stop     : std_logic;
end record;
signal i_usrmode                   : TUserMode;

signal i_lba_cnt                   : std_logic_vector(47 downto 0);




--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
--ltstout:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    tst_fms_cs_dly<=(others=>'0');
--    p_out_tst(31 downto 1)<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    tst_fms_cs_dly<=tst_fms_cs;
--    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
--  end if;
--end process ltstout;
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_on;



--//----------------------------------
--//Формирую отчеты
--//----------------------------------
p_out_usr_status<=i_usr_status;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_usr_status.glob_busy<='1';
    i_usr_status.glob_drdy<='0';
    i_usr_status.glob_err<='0';
    i_usr_status.glob_usr<=(others=>'0');
    for i in 0 to C_SATA_COUNT_MAX-1 loop
      i_usr_status.ch_usr(i)<=(others=>'0');
      i_usr_status.ch_busy(i)<='1';
      i_usr_status.ch_drdy(i)<='0';
      i_usr_status.ch_err(i)<='0';
      i_usr_status.SError(i)<=(others=>'0');
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then

    i_usr_status.glob_busy<=OR_reduce(i_usr_status.ch_busy(G_HDD_COUNT-1 downto 0));
    i_usr_status.glob_drdy<=AND_reduce(i_usr_status.ch_drdy(G_HDD_COUNT-1 downto 0));
    i_usr_status.glob_err<=OR_reduce(i_usr_status.ch_err(G_HDD_COUNT-1 downto 0));
--    i_usr_status.glob_usr<=(others=>'0');

    for i in 0 to G_HDD_COUNT-1 loop
      i_usr_status.ch_busy(i)<=p_in_sh_status(i).Usr(C_AUSER_BUSY_BIT);
      i_usr_status.ch_drdy(i)<=p_in_sh_status(i).ATAStatus(C_REG_ATA_STATUS_DRDY_BIT);

      i_usr_status.ch_err(i)<=p_in_sh_status(i).ATAStatus(C_REG_ATA_STATUS_ERR_BIT) or
                              p_in_sh_status(i).SError(C_ASERR_I_ERR_BIT) or
                              p_in_sh_status(i).SError(C_ASERR_C_ERR_BIT) or
                              p_in_sh_status(i).SError(C_ASERR_P_ERR_BIT);

--      i_usr_status.ch_usr(i)<=(others=>'0');
      i_usr_status.SError(i)<=p_in_sh_status(i).SError;
    end loop;

  end if;
end process;


--//Формирую стробы
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_glob_busy<=(others=>'0');
    sr_glob_err<=(others=>'0');
    i_sh_det.cmddone<='0';
    i_sh_det.err<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    sr_glob_busy<=OR_reduce(i_usr_status.ch_busy) & sr_glob_busy(0 to 0);
    sr_glob_err<=OR_reduce(i_usr_status.ch_err) & sr_glob_err(0 to 0);

    i_sh_det.cmddone<=not sr_glob_busy(0) and sr_glob_busy(1);
    i_sh_det.err<=sr_glob_err(0) and not sr_glob_err(1);
  end if;
end process;





--//------------------------------------------
--//Прием/обработка командного пакета
--//------------------------------------------
i_cmdfifo_rd<=not p_in_usr_cxbuf_empty;-- and not i_cmdfifo_rd_dis;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_cmdfifo_dcnt<=(others=>'0');
    i_cmdfifo_rd_done<='0';
--    i_cmdfifo_rd_dis<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    if i_cmdfifo_rd='1' then
      if i_cmdfifo_dcnt=CONV_STD_LOGIC_VECTOR(C_USRAPP_CMDPKT_SIZE_WORD-1, i_cmdfifo_dcnt'length) then
        i_cmdfifo_dcnt<=(others=>'0');
      else
        i_cmdfifo_dcnt<=i_cmdfifo_dcnt + 1;
      end if;

      if i_cmdfifo_dcnt=CONV_STD_LOGIC_VECTOR(C_USRAPP_CMDPKT_SIZE_WORD-1, i_cmdfifo_dcnt'length) then
        i_cmdfifo_rd_done<='1';
--        i_cmdfifo_rd_dis<='1';
      end if;
    else
      i_cmdfifo_rd_done<='0';
    end if;

  end if;
end process;

--//Чтение командного пакета
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_cmdpkt.ctrl<=(others=>'0');
    i_cmdpkt.feature<=(others=>'0');
    i_cmdpkt.lba<=(others=>'0');
    i_cmdpkt.scount<=(others=>'0');
    i_cmdpkt.command<=(others=>'0');
    i_cmdpkt.control<=(others=>'0');
    i_cmdpkt.device<=(others=>'0');
    i_cmdpkt.reserv<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if i_cmdfifo_rd='1' then
      if    i_cmdfifo_dcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_USRCTRL, i_cmdfifo_dcnt'length)      then i_cmdpkt.ctrl<=p_in_usr_cxd;
      elsif i_cmdfifo_dcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_FEATURE, i_cmdfifo_dcnt'length)      then i_cmdpkt.feature<=p_in_usr_cxd;
      elsif i_cmdfifo_dcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_LOW, i_cmdfifo_dcnt'length)      then i_cmdpkt.lba(8*(0+1)-1 downto 8*0)<=p_in_usr_cxd(7 downto 0);
                                                                                                   i_cmdpkt.lba(8*(3+1)-1 downto 8*3)<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdfifo_dcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_MID, i_cmdfifo_dcnt'length)      then i_cmdpkt.lba(8*(1+1)-1 downto 8*1)<=p_in_usr_cxd(7 downto 0);
                                                                                                   i_cmdpkt.lba(8*(4+1)-1 downto 8*4)<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdfifo_dcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_HIGH, i_cmdfifo_dcnt'length)     then i_cmdpkt.lba(8*(2+1)-1 downto 8*2)<=p_in_usr_cxd(7 downto 0);
                                                                                                   i_cmdpkt.lba(8*(5+1)-1 downto 8*5)<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdfifo_dcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_SECTOR_COUNT, i_cmdfifo_dcnt'length) then i_cmdpkt.scount<=p_in_usr_cxd;
      elsif i_cmdfifo_dcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_COMMAND, i_cmdfifo_dcnt'length)      then i_cmdpkt.command<=p_in_usr_cxd(7 downto 0);
                                                                                                   i_cmdpkt.control<=p_in_usr_cxd(15 downto 8);
      elsif i_cmdfifo_dcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_DEVICE, i_cmdfifo_dcnt'length)       then i_cmdpkt.device<=p_in_usr_cxd(7 downto 0);
                                                                                                   i_cmdpkt.reserv<=p_in_usr_cxd(15 downto 8);
      end if;
    end if;

  end if;
end process;

--//Отправка команды в модуль sata_host.vhd
i_sh_cmd_start<=i_cmdfifo_rd_done;

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
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_LOW, i_sh_cmdcnt'length)     then i_sh_cxdout(7 downto 0) <=i_lba_cnt(8*(0+1)-1 downto 8*0);
                                                                                            i_sh_cxdout(15 downto 8)<=i_lba_cnt(8*(3+1)-1 downto 8*3);
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_MID, i_sh_cmdcnt'length)     then i_sh_cxdout(7 downto 0) <=i_lba_cnt(8*(1+1)-1 downto 8*1);
                                                                                            i_sh_cxdout(15 downto 8)<=i_lba_cnt(8*(4+1)-1 downto 8*4);
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_HIGH, i_sh_cmdcnt'length)    then i_sh_cxdout(7 downto 0) <=i_lba_cnt(8*(2+1)-1 downto 8*2);
                                                                                            i_sh_cxdout(15 downto 8)<=i_lba_cnt(8*(5+1)-1 downto 8*5);
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_SECTOR_COUNT, i_sh_cmdcnt'length)then i_sh_cxdout<=i_cmdpkt.scount;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_COMMAND, i_sh_cmdcnt'length)     then i_sh_cxdout(7 downto 0)<=i_cmdpkt.command;
                                                                                            i_sh_cxdout(15 downto 8)<=i_cmdpkt.control;
      elsif i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_DEVICE, i_sh_cmdcnt'length)      then i_sh_cxdout(7 downto 0)<=i_cmdpkt.device;
                                                                                            i_sh_cxdout(15 downto 8)<=i_cmdpkt.reserv;
      end if;
    end if;

  end if;
end process;


p_out_usr_cxd_rd<=i_cmdfifo_rd;

p_out_sh_cxd<=i_sh_cxdout;
p_out_sh_cxd_sof_n<=not i_sh_cxd_sof;
p_out_sh_cxd_eof_n<=not i_sh_cxd_eof;
p_out_sh_cxd_src_rdy_n<=not i_sh_cxd_src_rdy;


p_out_sh_mask<=i_sh_mask;




i_sh_mask<=i_cmdpkt.ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT);

--//Флаги соотв. режижимов
i_usrmode.sw<=i_cmdpkt.ctrl(C_CMDPKT_USRMODE_SW_BIT);
i_usrmode.hw<=i_cmdpkt.ctrl(C_CMDPKT_USRMODE_HW_BIT);
i_usrmode.tst<=i_cmdpkt.ctrl(C_CMDPKT_USRMODE_TST_BIT);
i_usrmode.stop<=not(i_cmdpkt.ctrl(C_CMDPKT_USRMODE_SW_BIT) or i_cmdpkt.ctrl(C_CMDPKT_USRMODE_HW_BIT) or i_cmdpkt.ctrl(C_CMDPKT_USRMODE_TST_BIT));

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    i_usrmode.sw_work<='0';
    i_usrmode.hw_work<='0';
    i_usrmode.tst_work<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    --//Работа в SW режиме
    if i_sh_det.cmddone='1' or i_sh_det.err='1' then
      i_usrmode.sw_work<='0';
    elsif i_usrmode.sw='1' and i_cmdfifo_rd_done='1' then
      i_usrmode.sw_work<='1';
    end if;

--    --//Работа в HW режиме
--    if i_hw_mode_stop='1' or i_all_mode_stop_err='1' then
--      i_hw_mode_work<='0';
--    elsif i_usrmode.hw='1' and i_cmdfifo_rd_done='1' then
--      i_hw_mode_work<='1';
--    end if;

--    --//Работа в режиме Тестирования
--    if i_hw_mode_stop='1' or i_sw_mode_stop='1' or i_all_mode_stop_err='1' then
--      i_test_mode_work<='0';
--      i_test_mode_wr<='0';
--    elsif i_usrmode.tst='1' and i_cmdfifo_rd_done='1' then
--      i_test_mode_work<='1';
--      i_test_mode_wr<=i_flag_test_wr;
--    end if;
  end if;
end process;



--//Cчетчик адреса LBA
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_lba_cnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if (i_usrmode.sw='1' and i_cmdfifo_rd_done='1') then-- or i_hw_mode_start='1' then
      i_lba_cnt<=i_cmdpkt.lba;

    elsif i_sh_det.cmddone='1' then
      --//После каждого аппаратного запуска
      i_lba_cnt<=i_lba_cnt + EXT(i_cmdpkt.scount, i_lba_cnt'length);
    end if;

  end if;
end process;





----//Варианты RAID
--gen_raidon_0 : if (G_HDD_COUNT-1)=0  generate
--i_raid_on<='0';
--end generate gen_raidon_0;
--
--gen_raidon_1 : if (G_HDD_COUNT-1)=1  generate
--i_raid_on<='1' when i_sh_mask=CONV_STD_LOGIC_VECTOR(16#03#, i_sh_mask'length) else '0';
--end generate gen_raidon_1;
--
--gen_raidon_2 : if (G_HDD_COUNT-1)=2  generate
--i_raid_on<='1' when i_sh_mask=CONV_STD_LOGIC_VECTOR(16#03#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#07#, i_sh_mask'length) else '0';
--end generate gen_raidon_2;
--
--gen_raidon_3 : if (G_HDD_COUNT-1)=3  generate
--i_raid_on<='1' when i_sh_mask=CONV_STD_LOGIC_VECTOR(16#03#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#07#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#0F#, i_sh_mask'length) else '0';
--end generate gen_raidon_3;
--
--gen_raidon_4 : if (G_HDD_COUNT-1)=4  generate
--i_raid_on<='1' when i_sh_mask=CONV_STD_LOGIC_VECTOR(16#03#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#07#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#0F#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#1F#, i_sh_mask'length) else '0';
--end generate gen_raidon_4;
--
--gen_raidon_5 : if (G_HDD_COUNT-1)=5  generate
--i_raid_on<='1' when i_sh_mask=CONV_STD_LOGIC_VECTOR(16#03#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#07#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#0F#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#1F#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#3F#, i_sh_mask'length) else '0';
--end generate gen_raidon_5;
--
--gen_raidon_6 : if (G_HDD_COUNT-1)=6  generate
--i_raid_on<='1' when i_sh_mask=CONV_STD_LOGIC_VECTOR(16#03#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#07#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#0F#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#1F#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#3F#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#7F#, i_sh_mask'length) else '0';
--end generate gen_raidon_6;
--
--gen_raidon_7 : if (G_HDD_COUNT-1)=7  generate
--i_raid_on<='1' when i_sh_mask=CONV_STD_LOGIC_VECTOR(16#03#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#07#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#0F#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#1F#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#3F#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#7F#, i_sh_mask'length) or
--                    i_sh_mask=CONV_STD_LOGIC_VECTOR(16#FF#, i_sh_mask'length) else '0';
--end generate gen_raidon_7;

--END MAIN
end behavioral;



--i_sh_cxdout<=i_cmdpkt.feature                                                when i_sh_cmdcnt_en='1' and i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_FEATURE, i_sh_cmdcnt'length) else
--              i_lba_cnt(8*(3+1)-1 downto 8*3)&i_lba_cnt(8*(0+1)-1 downto 8*0) when i_sh_cmdcnt_en='1' and i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_LOW, i_sh_cmdcnt'length) else
--              i_lba_cnt(8*(4+1)-1 downto 8*4)&i_lba_cnt(8*(1+1)-1 downto 8*1) when i_sh_cmdcnt_en='1' and i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_MID, i_sh_cmdcnt'length) else
--              i_lba_cnt(8*(5+1)-1 downto 8*5)&i_lba_cnt(8*(2+1)-1 downto 8*2) when i_sh_cmdcnt_en='1' and i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_HIGH, i_sh_cmdcnt'length) else
--              i_cmdpkt.scount                                                 when i_sh_cmdcnt_en='1' and i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_SECTOR_COUNT, i_sh_cmdcnt'length) else
--              i_cmdpkt.control & i_cmdpkt.command                             when i_sh_cmdcnt_en='1' and i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_COMMAND, i_sh_cmdcnt'length) else
--              i_cmdpkt.reserv & i_cmdpkt.device                               when i_sh_cmdcnt_en='1' and i_sh_cmdcnt=CONV_STD_LOGIC_VECTOR(C_ALREG_DEVICE, i_sh_cmdcnt'length) else
--              i_cmdpkt.ctrl;