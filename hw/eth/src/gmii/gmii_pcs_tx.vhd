-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 22.05.2012 11:55:44
-- Module Name : gmii_pcs_tx
--
-- Назначение/Описание :
--
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.gmii_pkg.all;

entity gmii_pcs_tx is
generic(
G_GT_DBUS : integer:=8;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--GMII
--------------------------------------
p_in_txd            : in    std_logic_vector(7 downto 0);
p_in_tx_en          : in    std_logic;
p_in_tx_er          : in    std_logic;
p_in_tx_col         : out   std_logic;

--------------------------------------
--
--------------------------------------
p_in_txcfg          : in    std_logic_vector(15 downto 0);
p_in_xmit           : in    std_logic_vector(3 downto 0);

--------------------------------------
--RocketIO Transmiter
--------------------------------------
p_out_gt_txdata     : out   std_logic_vector(31 downto 0);
p_out_gt_txcharisk  : out   std_logic_vector(3 downto 0);

p_out_gt_txreset    : out   std_logic;
p_in_gt_txbufstatus : in    std_logic_vector(1 downto 0);

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end gmii_pcs_tx;

architecture behavioral of gmii_pcs_tx is

signal i_tmr_rst                  : std_logic_vector(1 downto 0);
signal i_tmr_rst_en               : std_logic;

signal i_gt_txreset               : std_logic;

signal i_byte_cnt                 : std_logic;
signal i_txd                      : std_logic_vector(7 downto 0);
signal i_txdtype                  : std_logic;


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_on;



--//-------------------------------------
--//Контроль переполнения буфера передатчика GT
--//-------------------------------------
tmr_rst:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_rst<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_tmr_rst_en='1' then
      i_tmr_rst<=i_tmr_rst+1;
    else
      i_tmr_rst<=(others=>'0');
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_rst_en<='0';
    i_gt_txreset<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    if i_tmr_rst_en='0' then
      i_gt_txreset<='0';
      if p_in_gt_txbufstatus(1)='1' then
      --gtp_txbufstatus(1)-'1'-буфер или переполнен или опусташен
      --формирую сброс
        i_tmr_rst_en<='1';
      end if;
    else
      i_gt_txreset<='1';
      if i_tmr_rst=CONV_STD_LOGIC_VECTOR(16#02#, i_tmr_rst'length) then
        i_tmr_rst_en<='0';
      end if;
    end if;
  end if;
end process;

p_out_gt_txreset<=i_gt_txreset;

--//#########################################
--//Synchronization - Автомат управления
--//Реализует управление согласно спецификации
--//(см. пп 36.2.5.2.6 IEEE_Std_802.3-2005_section3.pdf)
--//#########################################
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_byte_cnt<='0';
    i_txd<=C_PDAT_I1(7 downto 0);
    i_txdtype<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    i_byte_cnt<=not i_byte_cnt;

    if i_byte_cnt='0' then
      i_txd<=C_PDAT_I1(7 downto 0);
      i_txdtype<='1';
    else
      i_txd<=C_PDAT_I1(15 downto 8);
      i_txdtype<='0';
    end if;

  end if;
end process;

p_out_gt_txdata(7  downto  0)<=i_txd;
p_out_gt_txdata(31 downto  8)<=(others=>'0');
p_out_gt_txcharisk(0)<=i_txdtype;
p_out_gt_txcharisk(3 downto 1)<=(others=>'0');


--END MAIN
end behavioral;

