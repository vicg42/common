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
--//trc_nik_core.vhd порт p_in_ctrl Bit Map:
constant CNIK_TRCCORE_CTRL_START_BIT                : integer:=0;--//Начать работу
constant CNIK_TRCCORE_CTRL_FR_NEW_BIT               : integer:=1;--//Новый кадр
constant CNIK_TRCCORE_CTRL_MEMWD_DONE_BIT           : integer:=2;--//Запись в ОЗУ завершена
constant CNIK_TRCCORE_CTRL_LAST_BIT                 : integer:=CNIK_TRCCORE_CTRL_MEMWD_DONE_BIT;

--//trc_nik_core.vhd порт p_out_satatus Bit Map:
constant CNIK_TRCCORE_STAT_NXT_ROW_BIT              : integer:=0;
constant CNIK_TRCCORE_STAT_IDLE_BIT                 : integer:=1;
constant CNIK_TRCCORE_STAT_HBUF_SKIP_BIT            : integer:=2;
constant CNIK_TRCCORE_STAT_HBUF_DRDY_BIT            : integer:=3;
constant CNIK_TRCCORE_STAT_LAST_BIT                 : integer:=CNIK_TRCCORE_STAT_HBUF_DRDY_BIT;



--//Размеры элементарного блока (ЭБ)
--//Значения должны быть кратны 2
constant CNIK_EBKT_LENX                             : integer:=4; --//по оси X (пикселы)
constant CNIK_EBKT_LENY                             : integer:=4; --//по оси Y (строки)=кол-ву буферов для строк

--//Кол-во ЭБ записываемых в выходной буфер.
constant CNIK_EBOUT_COUNT                           : integer:=16; --//Разрешенные значения: 4, 8, 16

constant CNIK_HPKT_COUNT                            : integer:=CNIK_EBOUT_COUNT/4; --//Размер Заголовка выходного пакета в DW



--//----------------------------------------
--//Типы данных, структуры
--//----------------------------------------
Type TTrcNikHPkt is array (0 to 3) of std_logic_vector(31 downto 0);

type TTrcNikEBO is record
cnt  : std_logic_vector(7 downto 0);
end record;
Type TTrcNikEBOs is array (0 to 15) of TTrcNikEBO;

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
Type TTrcNikIPs is array (0 to C_DSN_TRCNIK_IP_COUNT-1) of TTrcNikIP;

type TTrcNikParam is record
mem_arbuf : std_logic_vector(31 downto 0);
ip  : TTrcNikIPs;
opt : std_logic_vector(15 downto 0);
end record;
Type TTrcNikParams is array (0 to C_DSN_TRCNIK_CH_COUNT-1) of TTrcNikParam;

type TGTrcNikParam is record
mem_wd_trnlen   : std_logic_vector(7 downto 0);
mem_rd_trnlen   : std_logic_vector(7 downto 0);
ch              : TTrcNikParams;
end record;

end dsn_track_nik_pkg;


package body dsn_track_nik_pkg is

end dsn_track_nik_pkg;

