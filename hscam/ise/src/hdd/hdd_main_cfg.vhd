-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.10.2011 15:15:44
-- Module Name : prj_cfg
--
-- Description : ���������������� ������ HDD ��� ������� HSCAM
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package prj_cfg is

--//������ ����������
constant C_PCFG_HSCAM_HDD_VERSION      : integer:=16#05#; --������� ������ ����������� HDD ��� ������� HSCAM

--//��� ������������ �����
constant C_PCFG_BOARD                  : string:="HSCAM";

--//���������������� �������:
constant C_PCFG_VINBUF_ONE             : string:="ON";--ON/OFF - ���� �� ���������� ��� VCTRL � HDD/ ��� VCTRL � HDD ��������� ��. ����� ������

--//cfg VCTRL
constant C_PCFG_VCTRL_USE              : string:="ON";
constant C_PCFG_VCTRL_DBGCS            : string:="OFF";
constant C_PCFG_FRPIX                  : integer:=1280;
constant C_PCFG_FRROW                  : integer:=1024;

--//cfg Memory Controller
constant C_PCFG_MEMOPT                 : string:="OFF";--//ON - ������ ���� ������������ mem_mux_v3.vhd
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --//max 2
constant C_PCFG_MEMBANK_1              : integer:=1;
constant C_PCFG_MEMBANK_0              : integer:=0;
constant C_PCFG_MEMPHY_SET             : integer:=0;--0 - (MEMBANK0<->MCB5; MEMBANK1<->MCB1)
                                                    --1 - (MEMBANK0<->MCB1; MEMBANK1<->MCB5)

--//cfg HDD
constant C_PCFG_HDD_USE                : string:="ON";
constant C_PCFG_HDD_DBG                : string:="OFF";
constant C_PCFG_HDD_DBGCS              : string:="ON";
constant C_PCFG_HDD_SH_DBGCS           : string:="OFF";
constant C_PCFG_HDD_RAID_DBGCS         : string:="ON";
constant C_PCFG_HDD_COUNT              : integer:=4;
constant C_PCFG_HDD_RAMBUF_SIZE        : integer:=27;--128MB : ������������ ��� 2 � ������� G_HDD_RAMBUF_SIZE
constant C_PCFG_HDD_GT_DBUS            : integer:=32;--��������� ���� ������ GT (RocketIO)
constant C_PCFG_HDD_FPGA_TYPE          : integer:=3; --0/1/2/3 - "V5_GTP"/"V5_GTX"/"V6_GTX"/"S6_GTPA"
constant C_PCFG_HDD_SH_MAIN_NUM        : integer:=0; --���������� ������ GT ������ �� �������� ����� ����� ������� ��� ������������ sata_dcm.vhd
constant C_PCFG_HDD_SATA_GEN_DEFAULT   : integer:=0; --0/1 - SATAI/II
constant C_PCFG_HDD_RAID_DWIDTH        : integer:=128;

end prj_cfg;
