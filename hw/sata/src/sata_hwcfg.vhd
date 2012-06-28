-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.06.2012 8:28:35
-- Module Name : sata_hwcfg
--
-- Description : Аппаратное управление режимами записи/чтения HDD
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
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_raid_pkg.all;

entity sata_hwcfg is
generic(
G_HDD_COUNT : integer:=1;
G_DBGCS     : string :="OFF";
G_SIM : string:="OFF"
);
port(
p_in_cmd        : in    std_logic_vector(2 downto 0);
p_in_hdd_lba_bp : in    std_logic_vector(47 downto 0);
p_in_hdd_err    : in    std_logic;
p_in_hdd_done   : in    std_logic;

p_out_sh_cxd    : out   std_logic_vector(15 downto 0);
p_out_sh_cxd_wr : out   std_logic;
p_out_sh_cxd_en : out   std_logic;
p_out_test_on   : out   std_logic;
p_out_clr       : out   std_logic;
p_out_clr_done_dis   : out   std_logic;

p_out_dbgcs     : out   TSH_ila;

p_in_clk        : in    std_logic;
p_in_rst        : in    std_logic
);
end sata_hwcfg;

architecture behavioral of sata_hwcfg is

constant CI_SLBA_DEFAULT   : integer:=16#00000000#;--Start LBA
constant CI_ELBA_DEFAULT   : integer:=16#1DC00000#;--End LBA  (SizeHDD*1GB)/512=(238*C_1GB)/512;
constant CI_SCOUNT_DEFAULT : integer:=selval(1,1024, strcmp(G_SIM,"ON"));

constant CI_HDD_WR    : integer:=1;
constant CI_HDD_RD    : integer:=2;
constant CI_HDD_STOP  : integer:=3;
constant CI_HDD_TEST  : integer:=4;
constant CI_HDD_CLR   : integer:=5;

type TPktHWR is array (0 to C_HDDPKT_DCOUNT-1) of std_logic_vector(p_out_sh_cxd'range);
type TSrCmd is array (0 to 1) of std_logic_vector(p_in_cmd'range);

type THW_commad is record
wr   : std_logic;
test : std_logic;
clr: std_logic;
end record;

type TSH_cfg is record
dcnt: std_logic_vector(3 downto 0);
en  : std_logic;
wr  : std_logic;
d   : std_logic_vector(p_out_sh_cxd'range);
end record;

signal i_pkt_hdd         : TPktHWR;

signal i_cmd             : THW_commad;
signal i_sh_cfg          : TSH_cfg;

signal sr_hdd_done       : std_logic_vector(0 to 1);
signal i_hdd_done        : std_logic;
signal i_hdd_err         : std_logic;

signal sr_cmd            : TSrCmd;

type TCfgFSM_state is (
S_IDLE,
S_HDD_ELBA,
S_HDD_CMD,
S_HDD_DONE,
S_HDD_DLY0,
S_HDD_DLY1,
S_HDD_DLY2,
S_HDD_DLY3
);
signal fsm_hwcfg         : TCfgFSM_state;

signal i_hdd_msk         : std_logic_vector(C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT downto 0);
signal i_raid_cmd        : std_logic_vector(C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT downto 0);
signal i_sata_cmd        : std_logic_vector(C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT downto 0);
signal i_ata_cmd         : std_logic_vector(7 downto 0);
signal i_clr_done_dis    : std_logic;
signal i_lba             : std_logic_vector(47 downto 0);
signal i_lba_bp          : std_logic_vector(47 downto 0);

signal tst_fsm_hwcfg     : std_logic_vector(3 downto 0);
signal tst_cmd_new       : std_logic;

--//MAIN
begin


-----------------------------------
--Инициализация
-----------------------------------

i_pkt_hdd(0)(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT)<=i_hdd_msk;
i_pkt_hdd(0)(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT)<=i_raid_cmd;
i_pkt_hdd(0)(C_HDDPKT_RAIDCMD_M_BIT+1)<='0';
i_pkt_hdd(0)(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT)<=i_sata_cmd;
i_pkt_hdd(0)(C_HDDPKT_SATACMD_M_BIT+1)<='0';
i_pkt_hdd(1)<=(others=>'0');
i_pkt_hdd(2)<=i_lba(16*(0+1)-1 downto 16*0);
i_pkt_hdd(3)<=i_lba(16*(1+1)-1 downto 16*1);
i_pkt_hdd(4)<=i_lba(16*(2+1)-1 downto 16*2);
i_pkt_hdd(5)<=CONV_STD_LOGIC_VECTOR(CI_SCOUNT_DEFAULT, i_pkt_hdd(5)'length);
i_pkt_hdd(6)<=CONV_STD_LOGIC_VECTOR(16#40#, i_pkt_hdd(6)'length);
i_pkt_hdd(7)<=EXT(i_ata_cmd, i_pkt_hdd(7)'length);
i_pkt_hdd(8)<=CONV_STD_LOGIC_VECTOR(16#01#, i_pkt_hdd(8)'length);


-----------------------------------
--Управление
-----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to sr_cmd'length-1 loop
    sr_cmd(i)<=(others=>'0');
    end loop;

    sr_hdd_done<=(others=>'0');
    i_hdd_done<='0';
    i_hdd_err<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    sr_cmd<=p_in_cmd & sr_cmd(0 to 0);

    sr_hdd_done<=p_in_hdd_done & sr_hdd_done(0 to 0);
    i_hdd_done<=sr_hdd_done(0) and not sr_hdd_done(1);
    i_hdd_err<=p_in_hdd_err;

  end if;
end process;


process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_hwcfg<=S_IDLE;

    i_sh_cfg.dcnt<=(others=>'0');
    i_sh_cfg.en<='0';
    i_sh_cfg.wr<='0';
    i_sh_cfg.d<=(others=>'0');

    i_cmd.wr<='0';
    i_cmd.test<='0';
    i_cmd.clr<='0';

    i_hdd_msk<=(others=>'0');
    i_raid_cmd<=(others=>'0');
    i_sata_cmd<=(others=>'0');
    i_lba<=(others=>'0');
    i_lba_bp<=CONV_STD_LOGIC_VECTOR(CI_ELBA_DEFAULT, i_lba_bp'length);
    i_ata_cmd<=(others=>'0');
    i_clr_done_dis<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_hwcfg is

      --------------------------------
      --Анализ принятой команды
      --------------------------------
      when S_IDLE =>

        i_hdd_msk<=(others=>'0');
        i_raid_cmd<=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_LBAEND, i_raid_cmd'length);
        i_sata_cmd<=CONV_STD_LOGIC_VECTOR(C_SATACMD_NULL, i_sata_cmd'length);
        i_ata_cmd<=(others=>'0');
        i_clr_done_dis<='0';

        if sr_cmd(0)/=sr_cmd(1) then
            if    sr_cmd(0)=CONV_STD_LOGIC_VECTOR(CI_HDD_WR, sr_cmd(0)'length) then
              i_lba<=CONV_STD_LOGIC_VECTOR(CI_ELBA_DEFAULT, i_lba'length);
              i_cmd.wr<='1';
              i_sh_cfg.en<='1';
              fsm_hwcfg<= S_HDD_ELBA;

            elsif sr_cmd(0)=CONV_STD_LOGIC_VECTOR(CI_HDD_RD, sr_cmd(0)'length) then
              i_lba<=i_lba_bp;
              i_cmd.wr<='0';
              i_sh_cfg.en<='1';
              fsm_hwcfg<= S_HDD_ELBA;

            elsif sr_cmd(0)=CONV_STD_LOGIC_VECTOR(CI_HDD_TEST, sr_cmd(0)'length) then
              i_lba<=CONV_STD_LOGIC_VECTOR(CI_ELBA_DEFAULT, i_lba'length);
              i_cmd.test<='1';
              i_cmd.wr<='1';
              i_sh_cfg.en<='1';
              fsm_hwcfg<= S_HDD_ELBA;

            elsif sr_cmd(0)=CONV_STD_LOGIC_VECTOR(CI_HDD_CLR, sr_cmd(0)'length) then
              i_cmd.clr<='1';
              i_sh_cfg.en<='0';
            end if;
        else
          i_cmd.wr<='0';
          i_cmd.clr<='0';
          i_sh_cfg.en<='0';
        end if;

      --------------------------------
      --Установка конечного адреса LBA
      --------------------------------
      when S_HDD_ELBA =>

        for i in 0 to i_pkt_hdd'length-1 loop
          if i_sh_cfg.dcnt=i then
            i_sh_cfg.d<=i_pkt_hdd(i);
          end if;
        end loop;

        if i_sh_cfg.dcnt=CONV_STD_LOGIC_VECTOR(i_pkt_hdd'length-1, i_sh_cfg.dcnt'length) then
          i_sh_cfg.dcnt<=(others=>'0');
          fsm_hwcfg<= S_HDD_DLY0;
        else
          i_sh_cfg.wr<='1';
          i_sh_cfg.dcnt<=i_sh_cfg.dcnt + 1;
        end if;

      when S_HDD_DLY0 =>

        i_sh_cfg.wr<='0';
        fsm_hwcfg<= S_HDD_DLY1;

      --------------------------------
      --Установка АТА команды
      --------------------------------
      when S_HDD_DLY1 =>

        for i in 0 to G_HDD_COUNT-1 loop
        i_hdd_msk(i)<='1';
        end loop;
        i_raid_cmd<=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_HW, i_raid_cmd'length);
        i_sata_cmd<=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, i_sata_cmd'length);
        i_lba<=CONV_STD_LOGIC_VECTOR(CI_SLBA_DEFAULT, i_lba'length);

        if i_cmd.wr='1' then
        i_ata_cmd<=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, i_ata_cmd'length);
        else
        i_ata_cmd<=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_DMA_EXT, i_ata_cmd'length);
        end if;

        if i_sh_cfg.dcnt(0)='1' then
          i_sh_cfg.dcnt<=(others=>'0');
          i_sh_cfg.en<='1';
          fsm_hwcfg<= S_HDD_CMD;
        else
          i_sh_cfg.en<='0';
          i_sh_cfg.dcnt<=i_sh_cfg.dcnt + 1;
        end if;

      when S_HDD_CMD =>

        for i in 0 to i_pkt_hdd'length-1 loop
          if i_sh_cfg.dcnt=i then
            i_sh_cfg.d<=i_pkt_hdd(i);
          end if;
        end loop;

        if i_sh_cfg.dcnt=CONV_STD_LOGIC_VECTOR(i_pkt_hdd'length-1, i_sh_cfg.dcnt'length) then
          i_sh_cfg.dcnt<=(others=>'0');
          fsm_hwcfg<= S_HDD_DLY2;
        else
          i_sh_cfg.wr<='1';
          i_sh_cfg.dcnt<=i_sh_cfg.dcnt + 1;
        end if;

      when S_HDD_DLY2 =>
        i_sh_cfg.wr<='0';
        fsm_hwcfg<= S_HDD_DLY3;

      when S_HDD_DLY3 =>
        i_sh_cfg.en<='0';
        fsm_hwcfg<= S_HDD_DONE;

      --------------------------------
      --Анализ завершения работы
      --------------------------------
      when S_HDD_DONE =>

        if i_hdd_done='1' or i_hdd_err='1' then
          if i_hdd_err='0' then
            i_clr_done_dis<='1';
            i_cmd.clr<='1';
          end if;
          i_lba_bp<=p_in_hdd_lba_bp;
          i_cmd.test<='0';
          fsm_hwcfg<= S_IDLE;

        elsif sr_cmd(0)/=sr_cmd(1) then
          if sr_cmd(0)=CONV_STD_LOGIC_VECTOR(CI_HDD_STOP, sr_cmd(0)'length) then
            i_hdd_msk<=(others=>'0');
            i_raid_cmd<=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_STOP, i_raid_cmd'length);
            i_sata_cmd<=CONV_STD_LOGIC_VECTOR(C_SATACMD_NULL, i_sata_cmd'length);
            i_sh_cfg.en<='1';
            fsm_hwcfg<= S_HDD_CMD;
          end if;
        end if;

    end case;

  end if;
end process;

p_out_clr_done_dis<=i_clr_done_dis;
p_out_clr<=i_cmd.clr;
p_out_test_on<=i_cmd.test;
p_out_sh_cxd <=i_sh_cfg.d;
p_out_sh_cxd_wr<=i_sh_cfg.wr;
p_out_sh_cxd_en<=i_sh_cfg.en;



gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_dbgcs.clk   <=p_in_clk;
p_out_dbgcs.trig0 <=(others=>'0');
p_out_dbgcs.data  <=(others=>'0');
end generate gen_dbgcs_off;


gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_cmd_new<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if sr_cmd(0)/=sr_cmd(1) then
      tst_cmd_new<='1';
    else
      tst_cmd_new<='0';
    end if;
  end if;
end process;

tst_fsm_hwcfg<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fsm_hwcfg'length) when fsm_hwcfg=S_HDD_ELBA  else
               CONV_STD_LOGIC_VECTOR(16#02#, tst_fsm_hwcfg'length) when fsm_hwcfg=S_HDD_CMD   else
               CONV_STD_LOGIC_VECTOR(16#03#, tst_fsm_hwcfg'length) when fsm_hwcfg=S_HDD_DONE  else
               CONV_STD_LOGIC_VECTOR(16#04#, tst_fsm_hwcfg'length) when fsm_hwcfg=S_HDD_DLY0  else
               CONV_STD_LOGIC_VECTOR(16#05#, tst_fsm_hwcfg'length) when fsm_hwcfg=S_HDD_DLY1  else
               CONV_STD_LOGIC_VECTOR(16#06#, tst_fsm_hwcfg'length) when fsm_hwcfg=S_HDD_DLY2  else
               CONV_STD_LOGIC_VECTOR(16#07#, tst_fsm_hwcfg'length) when fsm_hwcfg=S_HDD_DLY3  else
               CONV_STD_LOGIC_VECTOR(16#00#, tst_fsm_hwcfg'length) ; --//when fsm_hwcfg=S_IDLE else

p_out_dbgcs.clk<=p_in_clk;

p_out_dbgcs.trig0(3 downto 0)<=tst_fsm_hwcfg;
p_out_dbgcs.trig0(4)<=tst_cmd_new;
p_out_dbgcs.trig0(5)<=i_hdd_done;
p_out_dbgcs.trig0(6)<=i_hdd_err;
p_out_dbgcs.trig0(7)<='0';--зарезервировано
p_out_dbgcs.trig0(8)<='0';--зарезервировано
p_out_dbgcs.trig0(9)<='0';--зарезервировано
p_out_dbgcs.trig0(63 downto 10)<=(others=>'0');

p_out_dbgcs.data(3 downto 0)<=tst_fsm_hwcfg;
p_out_dbgcs.data(4)<=tst_cmd_new;
p_out_dbgcs.data(5)<=i_cmd.clr;
p_out_dbgcs.data(6)<=i_cmd.test;
p_out_dbgcs.data(7)<=i_sh_cfg.wr;
p_out_dbgcs.data(23 downto 8)<=i_sh_cfg.d;
p_out_dbgcs.data(24)<=i_sh_cfg.en;
p_out_dbgcs.data(27 downto 25)<=sr_cmd(0);
p_out_dbgcs.data(31 downto 28)<=(others=>'0');
p_out_dbgcs.data(47 downto 32)<=(others=>'0');--зарезервировано
p_out_dbgcs.data(48)<='0';--зарезервировано
p_out_dbgcs.data(49)<='0';--зарезервировано
p_out_dbgcs.data(50)<='0';--зарезервировано
p_out_dbgcs.data(180 downto 51)<=(others=>'0');

end generate gen_dbgcs_on;

--//END MAIN
end behavioral;
