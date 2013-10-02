-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.05.2011 16:39:38
-- Module Name : dsn_eth
--
-- Назначение/Описание :
--  Прием/передача данных по Eth
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

library work;
use work.vicg_common_pkg.all;
use work.prj_def.all;
use work.eth_pkg.all;
use work.eth_unit_pkg.all;

entity dsn_eth is
generic(
G_MODULE_USE : string:="ON";
G_ETH        : TEthGeneric;
G_DBG        : string:="OFF";
G_SIM        : string:="OFF"
);
port(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_clk      : in   std_logic;

p_in_cfg_adr      : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld   : in   std_logic;
p_in_cfg_adr_fifo : in   std_logic;

p_in_cfg_txdata   : in   std_logic_vector(15 downto 0);
p_in_cfg_wd       : in   std_logic;

p_out_cfg_rxdata  : out  std_logic_vector(15 downto 0);
p_in_cfg_rd       : in   std_logic;

p_in_cfg_done     : in   std_logic;
p_in_cfg_rst      : in   std_logic;

-------------------------------
--Связь с UsrBuf
-------------------------------
p_out_eth         : out   TEthOUTs;
p_in_eth          : in    TEthINs;

-------------------------------
--ETH
-------------------------------
p_out_ethphy      : out   TEthPhyOUT;
p_in_ethphy       : in    TEthPhyIN;

-------------------------------
--Технологический
-------------------------------
p_out_dbg         : out   TEthDBG;
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst          : in    std_logic
);
end dsn_eth;

architecture behavioral of dsn_eth is

signal i_cfg_adr_cnt         : std_logic_vector(7 downto 0);

--signal h_reg_ctrl            : std_logic_vector(15 downto 0);
signal h_reg_ethcfg          : TEthCfg;
signal i_ethcfg              : TEthCfgs;

signal i_ethphy_out          : TEthPhyOUT;
signal i_ethphy_in           : TEthPhyIN;

signal i_eth_main_tst_out    : std_logic_vector(31 downto 0);
signal i_dbg_out             : TEthDBG;


--MAIN
begin


----------------------------------------------------
--Запись/чтение регистров
----------------------------------------------------
--Счетчик адреса регистров
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_cfg_rst = '1' then
    i_cfg_adr_cnt <= (others=>'0');
  else
    if p_in_cfg_adr_ld = '1' then
      i_cfg_adr_cnt <= p_in_cfg_adr;
    else
      if p_in_cfg_adr_fifo='0' and (p_in_cfg_wd = '1' or p_in_cfg_rd = '1') then
        i_cfg_adr_cnt <= i_cfg_adr_cnt + 1;
      end if;
    end if;
  end if;
end if;
end process;

--Запись регистров
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_cfg_rst = '1' then
--    h_reg_ctrl <= (others=>'0');
--    h_reg_ethcfg.usrctrl <= (others=>'0');
--    h_reg_ethcfg.mac.lentype <= (others=>'0');
    for i in 0 to h_reg_ethcfg.mac.dst'high loop
    h_reg_ethcfg.mac.dst(i) <= (others=>'0');
    h_reg_ethcfg.mac.src(i) <= (others=>'0');
    end loop;

  else
    if p_in_cfg_wd = '1' then
        if i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN0, i_cfg_adr_cnt'length) then
          h_reg_ethcfg.mac.dst(0) <= p_in_cfg_txdata(7 downto 0);
          h_reg_ethcfg.mac.dst(1) <= p_in_cfg_txdata(15 downto 8);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN1, i_cfg_adr_cnt'length) then
          h_reg_ethcfg.mac.dst(2) <= p_in_cfg_txdata(7 downto 0);
          h_reg_ethcfg.mac.dst(3) <= p_in_cfg_txdata(15 downto 8);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN2, i_cfg_adr_cnt'length) then
          h_reg_ethcfg.mac.dst(4) <= p_in_cfg_txdata(7 downto 0);
          h_reg_ethcfg.mac.dst(5) <= p_in_cfg_txdata(15 downto 8);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN3, i_cfg_adr_cnt'length) then
          h_reg_ethcfg.mac.src(0) <= p_in_cfg_txdata(7 downto 0);
          h_reg_ethcfg.mac.src(1) <= p_in_cfg_txdata(15 downto 8);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN4, i_cfg_adr_cnt'length) then
          h_reg_ethcfg.mac.src(2) <= p_in_cfg_txdata(7 downto 0);
          h_reg_ethcfg.mac.src(3) <= p_in_cfg_txdata(15 downto 8);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN5, i_cfg_adr_cnt'length) then
          h_reg_ethcfg.mac.src(4) <= p_in_cfg_txdata(7 downto 0);
          h_reg_ethcfg.mac.src(5) <= p_in_cfg_txdata(15 downto 8);

--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN6, i_cfg_adr_cnt'length) then
--            h_reg_ethcfg.mac.lentype <= p_in_cfg_txdata(15 downto 0);

        end if;
    end if;
  end if;
end if;
end process;

--Чтение регистров
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_cfg_rst = '1' then
    p_out_cfg_rxdata <= (others=>'0');
  else
    if p_in_cfg_rd = '1' then
        if i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN0, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata(7 downto 0)  <= h_reg_ethcfg.mac.dst(0);
          p_out_cfg_rxdata(15 downto 8) <= h_reg_ethcfg.mac.dst(1);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN1, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata(7 downto 0)  <= h_reg_ethcfg.mac.dst(2);
          p_out_cfg_rxdata(15 downto 8) <= h_reg_ethcfg.mac.dst(3);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN2, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata(7 downto 0)  <= h_reg_ethcfg.mac.dst(4);
          p_out_cfg_rxdata(15 downto 8) <= h_reg_ethcfg.mac.dst(5);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN3, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata(7 downto 0)  <= h_reg_ethcfg.mac.src(0);
          p_out_cfg_rxdata(15 downto 8) <= h_reg_ethcfg.mac.src(1);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN4, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata(7 downto 0)  <= h_reg_ethcfg.mac.src(2);
          p_out_cfg_rxdata(15 downto 8) <= h_reg_ethcfg.mac.src(3);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN5, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata(7 downto 0)  <= h_reg_ethcfg.mac.src(4);
          p_out_cfg_rxdata(15 downto 8) <= h_reg_ethcfg.mac.src(5);

--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN6, i_cfg_adr_cnt'length) then
--            p_out_cfg_rxdata(15 downto 0) <= h_reg_ethcfg.mac.lentype;

        end if;
    end if;
  end if;
end if;
end process;



----------------------------------------------------
--
----------------------------------------------------
gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0) <= (others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst, i_ethphy_out.clk)
begin
  if p_in_rst = '1' then
    p_out_tst <= (others=>'0');
  elsif rising_edge(i_ethphy_out.clk) then
    p_out_tst(0) <= i_eth_main_tst_out(0);
  end if;
end process ltstout;

p_out_dbg <= i_dbg_out;

end generate gen_dbg_on;


gen_cfg_eth : for i in 0 to G_ETH.ch_count - 1 generate
process(i_ethphy_out.clk)
begin
  if rising_edge(i_ethphy_out.clk) then
    i_ethcfg(i) <= h_reg_ethcfg;
  end if;
end process;
end generate gen_cfg_eth;


--Ethernet
m_main : eth_main
generic map(
G_ETH => G_ETH,
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--------------------------------------
--USR
--------------------------------------
--настройка
p_in_ethcfg  => i_ethcfg,
--Связь с UsrBUF
p_out_eth    => p_out_eth,
p_in_eth     => p_in_eth,

--------------------------------------
--Eth Driver
--------------------------------------
p_out_phy    => i_ethphy_out,
p_in_phy     => i_ethphy_in,

--------------------------------------
--Технологические сигналы
--------------------------------------
p_out_dbg    => i_dbg_out,
p_in_tst     => p_in_tst,
p_out_tst    => i_eth_main_tst_out,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_rst     => p_in_rst
);

p_out_ethphy <= i_ethphy_out;
i_ethphy_in <= p_in_ethphy;

end generate gen_use_on;



----------------------------------------------------
--
----------------------------------------------------
gen_use_off : if strcmp(G_MODULE_USE,"OFF") generate

p_out_tst <= (others=>'0');

gen_ch : for i in 0 to G_ETH.ch_count - 1 generate
p_out_eth(i).rxbuf_di <= (others=>'0');
p_out_eth(i).rxbuf_wr <= '0';
p_out_eth(i).rxsof <= '0';
p_out_eth(i).rxeof <= '0';

p_out_eth(i).txbuf_rd <= '0';

end generate gen_ch;

p_out_ethphy.rdy <= '0';
p_out_ethphy.link <= '0';
p_out_ethphy.opt <= (others=>'0');

p_out_ethphy.clk <= p_in_cfg_clk;

end generate gen_use_off;

--END MAIN
end behavioral;
