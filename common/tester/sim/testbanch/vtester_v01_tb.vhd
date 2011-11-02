-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2008 18:38
-- Module Name : vtester_v01_tb
--
-- Назначение/Описание :
--    Проверка работы
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;

use work.vicg_common_pkg.all;
use work.prj_def.all;

library std;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

entity vtester_v01_tb is
end vtester_v01_tb;

architecture behavior of vtester_v01_tb is

constant i_clk_period      : TIME := 6.6 ns; --150MHz
constant i_dst_clk_period  : TIME := 3.3 ns; --

component vtester_v01
generic
(
G_T05us      : integer:=10#1000#; -- кол-во периодов частоты порта p_in_clk
                                 -- укладывающиес_ в 1/2 периода 1us
G_SIM        : string:="OFF"
);
port
(
-------------------------------
-- Управление от Хоста
-------------------------------
p_in_host_clk         : in   std_logic;

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);  --//
p_in_cfg_adr_ld       : in   std_logic;                     --//
p_in_cfg_adr_fifo     : in   std_logic;                     --//

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0); --//
p_in_cfg_wd           : in   std_logic;                     --//

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0); --//
p_in_cfg_rd           : in   std_logic;                     --//

p_in_cfg_done         : in   std_logic;                     --//

-------------------------------
-- STATUS модуля vtester_v01.VHD
-------------------------------
p_out_module_rdy      : out  std_logic;
p_out_module_error    : out  std_logic;

-------------------------------
--Связь с приемником данных
-------------------------------
p_out_dst_dout_rdy   : out   std_logic;
p_out_dst_dout       : out   std_logic_vector(31 downto 0); --//
p_out_dst_dout_wd    : out   std_logic;                     --//
p_in_dst_rdy_n       : in    std_logic;                     --//
p_in_dst_clk         : in    std_logic;                     --//

-------------------------------
--Технологический
-------------------------------
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk     : in    std_logic;  --//
p_in_rst     : in    std_logic
);
end component;

signal p_in_dst_clk                   : std_logic := '0';
signal p_in_clk                       : std_logic := '0';
signal p_in_rst                       : std_logic := '0';

signal p_in_cfg_adr                   : std_logic_vector(7 downto 0);  --//
signal p_in_cfg_adr_ld                : std_logic;                     --//
signal p_in_cfg_txdata                : std_logic_vector(15 downto 0); --//
signal p_in_cfg_wd                    : std_logic;                     --//


signal mnl_reg_pix                    : std_logic_vector(15 downto 0); --//
signal mnl_reg_row                    : std_logic_vector(15 downto 0); --//

signal mnl_reg_row_dly                : std_logic_vector(15 downto 0); --//
signal mnl_reg_fr_dly                 : std_logic_vector(15 downto 0); --//

signal mnl_reg_ctrl_l_start           : std_logic_vector(15 downto 0); --//
signal mnl_reg_ctrl_l_stop            : std_logic_vector(15 downto 0); --//
signal mnl_reg_ctrl_m                 : std_logic_vector(15 downto 0); --//

signal mnl_cfg_adr                    : std_logic_vector(7 downto 0);  --//
signal mnl_cfg_adr_ld                 : std_logic;                     --//
signal mnl_cfg_txdata                 : std_logic_vector(15 downto 0); --//
signal mnl_cfg_wd                     : std_logic;                     --//


--Main
begin


m_vtester: vtester_v01
generic map
(
G_T05us =>10#5#,
G_SIM   =>"ON"
)
port map
(
-------------------------------
-- Управление от Хоста
-------------------------------
p_in_host_clk         => p_in_clk,
p_in_cfg_adr          => p_in_cfg_adr,
p_in_cfg_adr_ld       => p_in_cfg_adr_ld,
p_in_cfg_adr_fifo     => '0',

p_in_cfg_txdata       => p_in_cfg_txdata,
p_in_cfg_wd           => p_in_cfg_wd,

p_out_cfg_rxdata      => open,
p_in_cfg_rd           => '0',

p_in_cfg_done         => '0',

-------------------------------
-- STATUS модуля vtester_v01.VHD
-------------------------------
p_out_module_rdy      => open,
p_out_module_error    => open,

-------------------------------
--Связь с приемником данных
-------------------------------
p_out_dst_dout_rdy   => open,
p_out_dst_dout       => open,
p_out_dst_dout_wd    => open,
p_in_dst_rdy_n       => '0',
p_in_dst_clk         => p_in_dst_clk,

-------------------------------
--Технологический
-------------------------------
p_out_tst            => open,

-------------------------------
--System
-------------------------------
p_in_clk     => p_in_clk,
p_in_rst     => p_in_rst
);


clk_in_generator : process
begin
  p_in_clk<='0';
  wait for i_clk_period/2;
  p_in_clk<='1';
  wait for i_clk_period/2;
end process;

dst_clk_in_generator : process
begin
  p_in_dst_clk<='0';
  wait for i_dst_clk_period/2;
  p_in_dst_clk<='1';
  wait for i_dst_clk_period/2;
end process;

p_in_rst<='1','0' after 1 us;


--//----------------------------------------------------------
--//Настройка тестирования
--//----------------------------------------------------------
mnl_reg_pix <=CONV_STD_LOGIC_VECTOR(10#04#, mnl_reg_pix'length);
mnl_reg_row <=CONV_STD_LOGIC_VECTOR(10#04#, mnl_reg_row'length);

mnl_reg_row_dly <=CONV_STD_LOGIC_VECTOR(10#02#, mnl_reg_row_dly'length);
mnl_reg_fr_dly  <=CONV_STD_LOGIC_VECTOR(10#01#, mnl_reg_fr_dly'length);

mnl_reg_ctrl_l_start(C_TSTING_REG_CTRL_MODE_M_BIT downto C_TSTING_REG_CTRL_MODE_L_BIT)<=CONV_STD_LOGIC_VECTOR(C_TSTING_MODE_SEND_TXD_STREAM, (C_TSTING_REG_CTRL_MODE_M_BIT-C_TSTING_REG_CTRL_MODE_L_BIT+1));
mnl_reg_ctrl_l_start(C_TSTING_REG_CTRL_START_BIT)<='1';
mnl_reg_ctrl_l_start(C_TSTING_REG_CTRL_FRTXD_2DW_CNT_BIT)<='0';
mnl_reg_ctrl_l_start(C_TSTING_REG_CTRL_FRAME_GRAY_BIT)<='0';
mnl_reg_ctrl_l_start(C_TSTING_REG_CTRL_FRAME_SET_MNL_BIT)<='0';
mnl_reg_ctrl_l_start(C_TSTING_REG_CTRL_FRAME_CH_AUTO_BIT)<='0';
mnl_reg_ctrl_l_start(C_TSTING_REG_CTRL_FRAME_CH_LSB_BIT)<='0';
mnl_reg_ctrl_l_start(C_TSTING_REG_CTRL_FRAME_CH_MSB_BIT)<='0';
mnl_reg_ctrl_l_start(C_TSTING_REG_CTRL_FRAME_DIAGONAL_BIT)<='0';
mnl_reg_ctrl_l_start(C_TSTING_REG_CTRL_FRAME_TSTDATA_2_BIT)<='0';
mnl_reg_ctrl_l_start(15 downto C_TSTING_REG_CTRL_FRAME_TSTDATA_2_BIT+1)<=(others=>'0');


mnl_reg_ctrl_l_stop(C_TSTING_REG_CTRL_MODE_M_BIT downto C_TSTING_REG_CTRL_MODE_L_BIT)<=CONV_STD_LOGIC_VECTOR(C_TSTING_MODE_SEND_TXD_STREAM, (C_TSTING_REG_CTRL_MODE_M_BIT-C_TSTING_REG_CTRL_MODE_L_BIT+1));
mnl_reg_ctrl_l_stop(C_TSTING_REG_CTRL_START_BIT)<='0';
mnl_reg_ctrl_l_stop(15 downto C_TSTING_REG_CTRL_START_BIT+1)<=(others=>'0');

mnl_reg_ctrl_m<=(others=>'0');


mnl_cfg_adr    <=CONV_STD_LOGIC_VECTOR(16#FF#, mnl_cfg_adr'length),
                 CONV_STD_LOGIC_VECTOR(C_TSTING_REG_PIX, mnl_cfg_adr'length) after 2.00 us,

                 CONV_STD_LOGIC_VECTOR(C_TSTING_REG_ROW_SEND_TIME_DLY, mnl_cfg_adr'length) after 2.500 us,

                 CONV_STD_LOGIC_VECTOR(C_TSTING_REG_CTRL_L, mnl_cfg_adr'length) after 3.3 us,

                 CONV_STD_LOGIC_VECTOR(C_TSTING_REG_CTRL_L, mnl_cfg_adr'length) after 8 us;


mnl_cfg_adr_ld <='0',
                 '1' after 2.000 us, '0' after 2.105 us,
                 '1' after 2.500 us, '0' after 2.505 us,
                 '1' after 3.300 us, '0' after 3.305 us,
                 '1' after 8.000 us, '0' after 8.107 us;

mnl_cfg_txdata <=CONV_STD_LOGIC_VECTOR(10#00#, mnl_cfg_txdata'length),
                 mnl_reg_pix after 2.0 us,
                 mnl_reg_row after 2.31 us,

                 mnl_reg_row_dly  after 2.7 us,
                 mnl_reg_fr_dly after 2.8 us,

                 mnl_reg_ctrl_l_start after 3.5 us,

                 mnl_reg_ctrl_l_stop after 8 us;

mnl_cfg_wd     <='0',
                 '1' after 2.300 us, '0' after 2.301 us,
                 '1' after 2.325 us, '0' after 2.327 us,

                 '1' after 2.700 us, '0' after 2.703 us,
                 '1' after 2.925 us, '0' after 2.929 us,

                 '1' after 3.500 us, '0' after 3.505 us,

                 '1' after 8.300 us, '0' after 8.307 us;


process(p_in_rst,p_in_clk)
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
begin
  if p_in_rst='1' then
    p_in_cfg_adr<=(others=>'0');
    p_in_cfg_adr_ld<='0';

    p_in_cfg_txdata<=(others=>'0');
    p_in_cfg_wd<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    p_in_cfg_adr<=mnl_cfg_adr;
    p_in_cfg_adr_ld<=mnl_cfg_adr_ld;

    p_in_cfg_txdata<=mnl_cfg_txdata;
    p_in_cfg_wd<=mnl_cfg_wd;
  end if;
end process;


--
--process(p_in_rst,p_in_clk)
--  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
--begin
--  if p_in_rst='1' then
--    tst_dwnp_count<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--
----    if p_out_dwnp_wd='1' then
----        tst_dwnp_count<=tst_dwnp_count+1;
----
----        write(GUI_line, string'("Result 2DW ("));
----        hwrite(GUI_line, tst_dwnp_count);
----        write(GUI_line, string'(") : 0x"));
----        hwrite(GUI_line, p_out_dwnp_data);
----        writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim
----
----    end if;
--
--    if i_fifo_result_rd='1' then
--        tst_dwnp_count<=tst_dwnp_count+1;
--
--        write(GUI_line, string'("Result 2DW ("));
--        hwrite(GUI_line, tst_dwnp_count);
--        write(GUI_line, string'(") : 0x"));
--        hwrite(GUI_line, i_fifo_result_dout);
--        writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim
--
--    end if;
--
--  end if;
--end process;

--End Main
end;
