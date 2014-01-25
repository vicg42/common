-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.06.2012 10:17:58
-- Module Name : dsn_video_ctrl_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.prj_def.all;

package dsn_video_ctrl_pkg is

type TFrXYMirror is record
pix : std_logic;
row : std_logic;
end record;

--координаты
type TFrXY is record
pix : std_logic_vector(15 downto 0);
row : std_logic_vector(15 downto 0);
end record;

--skip -- начало активной зоны кадра
--activ - размер активной зоны кадра
type TFrXYParam is record
skip  : TFrXY;
activ : TFrXY;
end record;
Type TFrXYParams is array (0 to C_VCTRL_VCH_COUNT - 1) of TFrXYParam;

--Параметры Видеоканала
type TVctrlChParam is record
mem_addr_wr    : std_logic_vector(31 downto 0);--Базовый Адрес где будет формироваться кадр
mem_addr_rd    : std_logic_vector(31 downto 0);--Базовый Адрес откуда будет вычитываться кадр
fr_size        : TFrXYParam;
fr_mirror      : TFrXYMirror;
step_rd        : std_logic_vector(15 downto 0);
end record;
type TVctrlChParams is array (0 to C_VCTRL_VCH_COUNT - 1) of TVctrlChParam;

--Параметры VCTRL
type TVctrlParam is record
mem_wd_trn_len  : std_logic_vector(7 downto 0);
mem_rd_trn_len  : std_logic_vector(7 downto 0);
ch              : TVctrlChParams;
end record;

--Параметры модуля записи
type TWriterVCHParam is record
mem_adr        : std_logic_vector(31 downto 0);
fr_size        : TFrXYParam;
end record;
Type TWriterVCHParams is array (0 to C_VCTRL_VCH_COUNT - 1) of TWriterVCHParam;

--Параметры модуля чтения
type TReaderVCHParam is record
mem_adr        : std_logic_vector(31 downto 0);
fr_size        : TFrXYParam;
fr_mirror      : TFrXYMirror;
step_rd        : std_logic_vector(15 downto 0);
end record;
Type TReaderVCHParams is array (0 to C_VCTRL_VCH_COUNT - 1) of TReaderVCHParam;


Type TVfrBufs is array (0 to C_VCTRL_VCH_COUNT - 1)
  of std_logic_vector(C_VCTRL_MEM_VFR_M_BIT - C_VCTRL_MEM_VFR_L_BIT downto 0);

Type TVMrks is array (0 to C_VCTRL_VCH_COUNT - 1) of std_logic_vector(31 downto 0);

end dsn_video_ctrl_pkg;

package body dsn_video_ctrl_pkg is

end dsn_video_ctrl_pkg;

