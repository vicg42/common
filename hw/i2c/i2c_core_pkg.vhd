-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 23.11.2011 17:11:04
-- Module Name : veresk_pkg
--
-- Description :
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package i2c_core_pkg is

constant C_I2C_CORE_CMD_NULL     : integer:=16#00#;
constant C_I2C_CORE_CMD_START_WR : integer:=16#01#;
constant C_I2C_CORE_CMD_START_RD : integer:=16#02#;
constant C_I2C_CORE_CMD_RESTART  : integer:=16#03#;
constant C_I2C_CORE_CMD_STOP     : integer:=16#04#;
constant C_I2C_CORE_CMD_WR       : integer:=16#05#;
constant C_I2C_CORE_CMD_RD       : integer:=16#06#;


end package i2c_core_pkg;







