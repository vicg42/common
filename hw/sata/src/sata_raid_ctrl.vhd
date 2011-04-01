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
    i_usr_status.glob_busy<='0';
    i_usr_status.glob_drdy<='0';
    i_usr_status.glob_err<='0';
    i_usr_status.glob_usr<=(others=>'0');
    for i in 0 to C_SATA_COUNT_MAX-1 loop
      i_usr_status.ch_usr(i)<=(others=>'0');
      i_usr_status.ch_busy(i)<='0';
      i_usr_status.ch_drdy(i)<='0';
      i_usr_status.ch_err(i)<='0';
      i_usr_status.SError(i)<=(others=>'0');
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then

    i_usr_status.glob_busy<=OR_reduce(i_usr_status.ch_busy);
    i_usr_status.glob_drdy<=AND_reduce(i_usr_status.ch_drdy(G_HDD_COUNT-1 downto 0));
    i_usr_status.glob_err<=OR_reduce(i_usr_status.ch_err);
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




--//------------------------------------------
--//Прием/обработка командного пакета
--//------------------------------------------




p_out_usr_cxd_rd<=not p_in_usr_cxbuf_empty;

p_out_sh_cxd<=p_in_usr_cxd;
p_out_sh_cxd_sof_n<=not p_in_usr_cxbuf_empty;
p_out_sh_cxd_eof_n<=not p_in_usr_cxbuf_empty;
p_out_sh_cxd_src_rdy_n<=not p_in_usr_cxbuf_empty;

p_out_sh_mask<=p_in_usr_ctrl(7 downto 0);


--END MAIN
end behavioral;
