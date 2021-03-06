-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.07.2014 13:41:22
-- Module Name : prj_cfg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.vicg_common_pkg.all;

package prj_cfg is

constant C_PCFG_SIM : string := "OFF";

--cfg Memory Controller
constant C_PCGF_MEMCTRL_DWIDTH      : integer := 32;
constant C_PCFG_MEMCTRL_BANK_COUNT  : integer := 1;
constant C_PCFG_MEMARB_CH_COUNT     : integer := 1;

--cfg TESTING
constant C_PCFG_MEMADR_START     : integer := 0;--(BYTE)
constant C_PCFG_MEMTEST_SIZE     : integer := 128 * C_1MB;--(BYTE) ����������� ����� ������
constant C_PCFG_MEMWR_BURST      : integer := 32;--(BYTE)
constant C_PCFG_MEMWR_TRLEN      : integer := 2;
constant C_PCFG_MEMRD_BURST      : integer := 32;--(BYTE)
constant C_PCFG_MEMRD_TRLEN      : integer := 2;

constant C_PCFG_HDEV_DWIDTH      : integer := 32;--(bit) ���� ������
constant C_PCFG_TEST_TYPE_CNT    : integer := 32;--Counter /8bit/16bit/32bit
constant C_PCFG_TEST_TYPE_RANDOM : std_logic := '1';

end package prj_cfg;

