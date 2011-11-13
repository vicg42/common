-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 04.11.2011 10:48:05
-- Module Name : pcie_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.vicg_common_pkg.all;

package pcie_pkg is

type TPce2Mem_Ctrl is record
dir       : std_logic;
start     : std_logic;
adr       : std_logic_vector(31 downto 0);--//адрес в BYTE
req_len   : std_logic_vector(17 downto 0);--//значение в BYTE. max 128KB
trnwr_len : std_logic_vector(7 downto 0); --//значение в DWORD
trnrd_len : std_logic_vector(7 downto 0); --//значение в DWORD
end record;

type TPce2Mem_Status is record
done    : std_logic;
end record;



end pcie_pkg;


package body pcie_pkg is

end pcie_pkg;






