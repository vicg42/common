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

constant C_GTCH_COUNT_MAX    : integer:=1;

----------------------------
--FIBER:
----------------------------
type TEthPhyFiberPinOUT is record
txp : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
txn : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
sfp_txdis : std_logic;
end record;
type TEthPhyFiberPinIN is record
rxp  : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
rxn  : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
sfp_sd : std_logic;
end record;

----------------------------
--Total
----------------------------
type TEthPhyPinOUT is record
fiber : TEthPhyFiberPinOUT;
end record;

type TEthPhyPinIN is record
fiber : TEthPhyFiberPinIN;
end record;

end eth_phypin_pkg;


