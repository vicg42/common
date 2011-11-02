-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.10.04
-- Module Name : dsn_track_pkg
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
use work.prj_def.all;
use work.vicg_common_pkg.all;
--use work.dsn_video_ctrl_pkg.all;

package dsn_track_nik_pkg is

--//----------------------------------------
--//Константы
--//----------------------------------------
--//Размеры элементарного блока (ЭБ)
--//Значения должны быть кратны 2
constant CNIK_EBKT_LENX                             : integer:=4; --//по оси X (пикселы)
constant CNIK_EBKT_LENY                             : integer:=4; --//по оси Y (строки)=кол-ву буферов для строк

--//Кол-во ЭБ записываемых в выходной буфер.
Type TGetEBOUT_Count is array (0 to 8) of integer;
--------------------------------------------------------------------------------
--//Кол-во интервальных порогов:                | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
--------------------------------------------------------------------------------
constant CNIK_EBOUT_COUNT : TGetEBOUT_Count:=( 0, 4,  8,  12, 16, 20, 24, 28, 32);

constant CNIK_EBOUT_COUNT_MAX                       : integer:=32; --//Разрешенные значения: 4, 8, 16
constant CNIK_HPKT_COUNT_MAX                        : integer:=8;--CNIK_EBOUT_COUNT_MAX/4; --//Размер Заголовка выходного пакета в DW



--//----------------------------------------
--//Типы данных, структуры
--//----------------------------------------
--//trc_nik_core.vhd порт p_in_ctrl Bit Map:
type TTrcNikCoreCtrl is record
start    : std_logic;
fr_new   : std_logic;
mem_done : std_logic;
end record;

--//trc_nik_core.vhd порт p_out_satatus Bit Map:
type TTrcNikCoreStatus is record
nxt_row : std_logic;
drdy    : std_logic;
idle    : std_logic;
--skip_ip : std_logic;
end record;


Type TTrcNikHPkt is array (0 to CNIK_HPKT_COUNT_MAX-1) of std_logic_vector(31 downto 0);

type TTrcNikEBO is record
cnt  : std_logic_vector(7 downto 0);
end record;
Type TTrcNikEBOs is array (0 to CNIK_EBOUT_COUNT_MAX-1) of TTrcNikEBO;

type TTrcNikDout is record
pix   : std_logic_vector(7 downto 0);
grada : std_logic_vector(7 downto 0);
grado : std_logic_vector(7 downto 0);
end record;
Type TTrcNikDouts is array (0 to CNIK_EBKT_LENY-1) of TTrcNikDout;

type TTrcNikKT is record
idx   : std_logic_vector(7 downto 0);
pix   : std_logic_vector(7 downto 0);
grada : std_logic_vector(7 downto 0);
grado : std_logic_vector(7 downto 0);
end record;

type TTrcNikIP is record
p1 : std_logic_vector(7 downto 0);
p2 : std_logic_vector(7 downto 0);
end record;
Type TTrcNikIPs is array (0 to C_TRCNIK_IP_COUNT-1) of TTrcNikIP;

type TTrcNikParam is record
mem_arbuf : std_logic_vector(31 downto 0);
opt       : std_logic_vector(15 downto 0);
ip        : TTrcNikIPs;
end record;
Type TTrcNikParams is array (0 to C_TRCNIK_VCH_COUNT-1) of TTrcNikParam;

type TGTrcNikParam is record
mem_wd_trnlen   : std_logic_vector(7 downto 0);
mem_rd_trnlen   : std_logic_vector(7 downto 0);
ch              : TTrcNikParams;
end record;




end dsn_track_nik_pkg;


package body dsn_track_nik_pkg is

end dsn_track_nik_pkg;

