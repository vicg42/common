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
type TPCS_Tx is record
d : std_logic_vector(7 downto 0);
k : std_logic;
end record;
signal i_tx                       : TPCS_Tx;

type fsm_txd_state is (
S_TXD_IDLE   ,

S_TXD_IDLE_1 ,

S_TXD_CFG_C1B,
S_TXD_CFG_C1C,
S_TXD_CFG_C1D,

S_TXD_CFG_C2A,
S_TXD_CFG_C2B,
S_TXD_CFG_C2C,
S_TXD_CFG_C2D
);
signal fsm_txd_cs : fsm_txd_state;

signal tst_fsm_txd_cs              : std_logic_vector(4 downto 0);

--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate

p_out_tst(4 downto 0)<=(others=>'0');--tst_fsm_txd_cs;
p_out_tst(31 downto 5)<=(others=>'0');

--tst_fsm_txd_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_txd_cs'length) when fsm_txd_cs=S_TXD_IDLE_1      else
--                CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_txd_cs'length) when fsm_txd_cs=S_TXD_CFG_C1B     else
--                CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_txd_cs'length) when fsm_txd_cs=S_TXD_CFG_C1C     else
--                CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_txd_cs'length) when fsm_txd_cs=S_TXD_CFG_C1D     else
--                CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_txd_cs'length) when fsm_txd_cs=S_TXD_CFG_C2A     else
--                CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_txd_cs'length) when fsm_txd_cs=S_TXD_CFG_C2B     else
--                CONV_STD_LOGIC_VECTOR(16#07#,tst_fsm_txd_cs'length) when fsm_txd_cs=S_TXD_CFG_C2C     else
--                CONV_STD_LOGIC_VECTOR(16#08#,tst_fsm_txd_cs'length) when fsm_txd_cs=S_TXD_CFG_C2D     else
--                CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_txd_cs'length);-- when fsm_sync_cs=S_TXD_IDLE     else

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
    i_tx.d<=C_PDAT_I1(7 downto 0);
    i_tx.k<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    i_byte_cnt<=not i_byte_cnt;

    if i_byte_cnt='0' then
      i_tx.d<=C_K28_5;--C_PDAT_I2(7 downto 0);
      i_tx.k<='1';
    else
      i_tx.d<=C_D16_2;--C_D5_6;--C_PDAT_I2(15 downto 8);
      i_tx.k<='0';
    end if;

  end if;
end process;

p_out_gt_txdata(7  downto  0)<=i_tx.d;
p_out_gt_txdata(31 downto  8)<=(others=>'0');
p_out_gt_txcharisk(0)<=i_tx.k;
p_out_gt_txcharisk(3 downto 1)<=(others=>'0');

--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    fsm_txd_cs <= S_TXD_IDLE;
--
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    case fsm_txd_cs is
--      --------------------------------------
--      --
--      --------------------------------------
--      when S_TXD_IDLE =>
--
--        if p_in_xmit=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_CFG, p_in_xmit'length) then
--
--          i_tx.d<=C_K28_5;
--          i_tx.k<=C_CHAR_K;
--          fsm_txd_cs <= S_TXD_CFG_C1B;
--
--        elsif p_in_xmit=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_IDLE, p_in_xmit'length) or
--              p_in_xmit=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_DATA, p_in_xmit'length) then
--
--          i_tx.d<=C_K28_5;
--          i_tx.k<=C_CHAR_K;
--          fsm_txd_cs <= S_TXD_IDLE_1;
--
--        end if;
--
--      --------------------------------------
--      --
--      --------------------------------------
--      when S_TXD_IDLE_1 =>
--
--        i_tx.d<=C_D16_2;--C_D5_6;
--        i_tx.k<=C_CHAR_D;
--        fsm_txd_cs <= S_TXD_IDLE;
--
--      --------------------------------------
--      -- Configurtion
--      --------------------------------------
--      when S_TXD_CFG_C1B =>
--
--        i_tx.d<=C_D21_5;
--        i_tx.k<=C_CHAR_D;
--        fsm_txd_cs <= S_TXD_CFG_C1C;
--
--      when S_TXD_CFG_C1C =>
--
--        i_tx.d<=p_in_txcfg(7 downto 0);
--        i_tx.k<=C_CHAR_D;
--        fsm_txd_cs <= S_TXD_CFG_C1D;
--
--      when S_TXD_CFG_C1D =>
--
--        i_tx.d<=p_in_txcfg(15 downto 8);
--        i_tx.k<=C_CHAR_D;
--
--        if p_in_xmit=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_CFG, p_in_xmit'length) then
--          fsm_txd_cs <= S_TXD_CFG_C2A;
--        else
--          fsm_txd_cs <= S_TXD_IDLE;
--        end if;
--
--      when S_TXD_CFG_C2A =>
--
--        i_tx.d<=C_K28_5;
--        i_tx.k<=C_CHAR_K;
--        fsm_txd_cs <= S_TXD_CFG_C2B;
--
--      when S_TXD_CFG_C2B =>
--
--        i_tx.d<=C_D2_2;
--        i_tx.k<=C_CHAR_D;
--        fsm_txd_cs <= S_TXD_CFG_C1C;
--
--      when S_TXD_CFG_C2C =>
--
--        i_tx.d<=p_in_txcfg(7 downto 0);
--        i_tx.k<=C_CHAR_D;
--        fsm_txd_cs <= S_TXD_CFG_C2D;
--
--      when S_TXD_CFG_C2D =>
--
--        i_tx.d<=p_in_txcfg(15 downto 8);
--        i_tx.k<=C_CHAR_D;
--        fsm_txd_cs <= S_TXD_IDLE;
--
--    end case;
--
--  end if;
--end process;

--END MAIN
end behavioral;

