-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 20.01.2012 14:42:09
-- Module Name : video_ctrl_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package video_ctrl_pkg is

--//Как поделена память ОЗУ для записи/чтение видеоинформации:
--//                                          : integer:=0; --//Пиксели видеокадра(VLINE_LSB-1...0)
constant C_VCTRL_MEM_VLINE_L_BIT              : integer:=11;--//Строки видеокадра (MSB...LSB)
constant C_VCTRL_MEM_VLINE_M_BIT              : integer:=21;
constant C_VCTRL_MEM_VFR_L_BIT                : integer:=22;--//Номер кадра (MSB...LSB) - Видеобуфера
constant C_VCTRL_MEM_VFR_M_BIT                : integer:=23;--//
constant C_VCTRL_MEM_VCH_L_BIT                : integer:=24;--//Номер видео канала (MSB...LSB)
constant C_VCTRL_MEM_VCH_M_BIT                : integer:=25;

constant C_VCTRL_VCH_COUNT     : integer:=1;
constant C_VCTRL_VCH_COUNT_MAX : integer:=1;

type TFrXY is record
pix : std_logic_vector(15 downto 0);
row : std_logic_vector(15 downto 0);
end record;

--//Параметры модуля записи
type TWriterVCHParam is record
fr_size        : TFrXY;
end record;
Type TWriterVCHParams is array (0 to C_VCTRL_VCH_COUNT-1) of TWriterVCHParam;

--//Параметры модуля чтения
type TReaderVCHParam is record
fr_size        : TFrXY;
end record;
Type TReaderVCHParams is array (0 to C_VCTRL_VCH_COUNT-1) of TReaderVCHParam;

Type TVfrBufs is array (0 to C_VCTRL_VCH_COUNT_MAX-1) of std_logic_vector(C_VCTRL_MEM_VFR_M_BIT-C_VCTRL_MEM_VFR_L_BIT downto 0);

end video_ctrl_pkg;
