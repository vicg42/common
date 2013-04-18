-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 29.11.2011 11:10:24
-- Module Name : eth_phypin_pkg
--
-- Description : Назначаем пины интерфейсов
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.prj_cfg.all;

package eth_phypin_pkg is

constant C_GTCH_COUNT_MAX    : integer:=C_PCFG_ETH_GTCH_COUNT_MAX;

------------------------------
----FIBER:
------------------------------
--type TEthPhyFiberPinOUT is record
--txp : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
--txn : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
--end record;
--
--type TEthPhyFiberPinIN is record
--rxp  : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
--rxn  : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
--clk_p: std_logic;
--clk_n: std_logic;
--end record;
--
------------------------------
----GMII
------------------------------
--type TEthPhyGMIIPinOUT is record
--txd    : std_logic_vector(7 downto 0);
--tx_en  : std_logic;
--tx_er  : std_logic;
--txc    : std_logic;--//gttxclk
--end record;
--
--type TEthPhyGMIIPinIN is record
--rxd    : std_logic_vector(7 downto 0);
--rx_dv  : std_logic;
--rx_er  : std_logic;
--rxc    : std_logic;--//rxclk
----txclk  : std_logic;--//txclk
----col    : std_logic;
----crs    : std_logic;
--end record;
--
--type TEthPhyGMIIPinOUTs is array (0 to C_GTCH_COUNT_MAX-1) of TEthPhyGMIIPinOUT;
--type TEthPhyGMIIPinINs is array (0 to C_GTCH_COUNT_MAX-1) of TEthPhyGMIIPinIN;
--
------------------------------
----RGMII
------------------------------
--type TEthPhyRGMIIPinOUT is record
--txd    : std_logic_vector(3 downto 0);
--tx_ctl : std_logic;
--txc    : std_logic;--//txclk
--end record;
--
--type TEthPhyRGMIIPinIN is record
--rxd    : std_logic_vector(3 downto 0);
--rx_ctl : std_logic;
--rxc    : std_logic;--//rxclk
--end record;
--
--type TEthPhyRGMIIPinOUTs is array (0 to C_GTCH_COUNT_MAX-1) of TEthPhyRGMIIPinOUT;
--type TEthPhyRGMIIPinINs is array (0 to C_GTCH_COUNT_MAX-1) of TEthPhyRGMIIPinIN;

----------------------------
--SGMII:
----------------------------
type TEthPhySGMIIPinOUT is record
txp : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
txn : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
end record;

type TEthPhySGMIIPinIN is record
rxp  : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
rxn  : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
clk_p: std_logic;
clk_n: std_logic;
end record;


----------------------------
--Total
----------------------------
type TEthPhyPinOUT is record
--fiber : TEthPhyFiberPinOUT;
--rgmii : TEthPhyRGMIIPinOUTs;
--gmii  : TEthPhyGMIIPinOUTs;
sgmii : TEthPhySGMIIPinOUT;
end record;

type TEthPhyPinIN is record
--fiber : TEthPhyFiberPinIN;
--rgmii : TEthPhyRGMIIPinINs;
--gmii  : TEthPhyGMIIPinINs;
sgmii : TEthPhySGMIIPinIN;
end record;


end eth_phypin_pkg;


