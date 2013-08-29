-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.11.2012 13:43:05
-- Module Name : edev
--
-- ����������/�������� :
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

entity edev is
generic(
G_HOST_DWIDTH : integer:=32;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
p_in_tmr_en       : in   std_logic;
p_in_tmr_stb      : in   std_logic;

-------------------------------
--HOST
-------------------------------
--host -> dev
p_in_htxbuf_di       : in   std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_htxbuf_wr       : in   std_logic;
p_out_htxbuf_full    : out  std_logic;
p_out_htxbuf_empty   : out  std_logic;

--host <- dev
p_out_hrxbuf_do      : out  std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_hrxbuf_rd       : in   std_logic;
p_out_hrxbuf_full    : out  std_logic;
p_out_hrxbuf_empty   : out  std_logic;

p_out_hirq           : out  std_logic;
p_out_herr           : out  std_logic;

p_in_hclk            : in   std_logic;

--------------------------------------
--PHY (half-duplex)
--------------------------------------
p_in_phy_rx       : in   std_logic;
p_out_phy_tx      : out  std_logic;
p_out_phy_dir     : out  std_logic;

------------------------------------
--��������������� �������
------------------------------------
p_in_tst          : in   std_logic_vector(31 downto 0);
p_out_tst         : out  std_logic_vector(31 downto 0);

--------------------------------------
--System
--------------------------------------
p_in_bitclk       : in   std_logic; -- 1/0  = bitclk 1MHz/ bitclk 250kHz
p_in_clk          : in   std_logic;
p_in_rst          : in   std_logic
);
end edev;

architecture behavioral of edev is

--MAIN
begin


p_out_htxbuf_full <= '0';
p_out_htxbuf_empty <= '1';
p_out_hrxbuf_do <= (others=>'0');

p_out_hrxbuf_full <= '0';
p_out_hrxbuf_empty <= '1';

p_out_hirq <= '0';
p_out_herr <= '0';

p_out_phy_tx <= '0';
p_out_phy_dir <= '0';

p_out_tst <= (others=>'0');


--END MAIN
end behavioral;
