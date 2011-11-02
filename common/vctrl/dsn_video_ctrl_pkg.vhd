-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.06
-- Module Name : dsn_video_ctrl_pkg
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
use work.prj_cfg.all;
use work.prj_def.all;

package dsn_video_ctrl_pkg is

type TFrXYMirror is record
pix : std_logic;
row : std_logic;
end record;

--//координаты
type TFrXY is record
pix : std_logic_vector(15 downto 0);
row : std_logic_vector(15 downto 0);
end record;

--//skip -- начало зоны
--//activ - размер зоны
type TFrXYParam is record
skip  : TFrXY;
activ : TFrXY;
end record;
Type TFrXYParams is array (0 to C_VCTRL_VCH_COUNT-1) of TFrXYParam;

--//Параметры Видеоканала
type TVctrlChParam is record
mem_addr_wr    : std_logic_vector(31 downto 0);--//Базовый Адрес где будет формироваться кадр
mem_addr_rd    : std_logic_vector(31 downto 0);--//Базовый Адрес откуда будет вычитываться кадр
fr_size        : TFrXYParam;
fr_mirror      : TFrXYMirror;
fr_color_fst   : std_logic_vector(1 downto 0);
fr_pcolor      : std_logic;
fr_zoom        : std_logic_vector(3 downto 0);
fr_zoom_type   : std_logic;
fr_color       : std_logic;
end record;
type TVctrlChParams is array (0 to C_VCTRL_VCH_COUNT-1) of TVctrlChParam;

--//Параметры VCTRL
type TVctrlParam is record
mem_wd_trn_len  : std_logic_vector(7 downto 0);
mem_rd_trn_len  : std_logic_vector(7 downto 0);
ch              : TVctrlChParams;
end record;

--//Параметры модуля записи
type TWriterVCHParam is record
mem_adr        : std_logic_vector(31 downto 0);
fr_size        : TFrXYParam;
end record;
Type TWriterVCHParams is array (0 to C_VCTRL_VCH_COUNT-1) of TWriterVCHParam;

--//Параметры модуля чтения
type TReaderVCHParam is record
mem_adr        : std_logic_vector(31 downto 0);
fr_size        : TFrXYParam;
fr_mirror      : TFrXYMirror;
fr_color_fst   : std_logic_vector(1 downto 0);
fr_pcolor      : std_logic;
fr_zoom        : std_logic_vector(3 downto 0);
fr_zoom_type   : std_logic;
fr_color       : std_logic;
end record;
Type TReaderVCHParams is array (0 to C_VCTRL_VCH_COUNT-1) of TReaderVCHParam;


Type TVfrBufs is array (0 to C_VCTRL_VCH_COUNT_MAX-1) of std_logic_vector(C_VCTRL_MEM_VFR_M_BIT-C_VCTRL_MEM_VFR_L_BIT downto 0);

Type TVMrks is array (0 to C_VCTRL_VCH_COUNT_MAX-1) of std_logic_vector(31 downto 0);

end dsn_video_ctrl_pkg;


package body dsn_video_ctrl_pkg is

end dsn_video_ctrl_pkg;

