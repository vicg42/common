-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 08.02.2011 10:17:50
-- Module Name : vctrl_main_tb
--
-- Назначение/Описание :
--    Проверка работы
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.mem_glob_pkg.all;
use work.mem_wr_pkg.all;
use work.dsn_video_ctrl_pkg.all;

library std;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

entity vctrl_main_tb is
generic(
G_ROTATE : string:="ON";
G_ROTATE_BUF_COUNT: integer:=8; --min/max - 4/32
G_SIM : string:="ON"
);
end vctrl_main_tb;

architecture behavior of vctrl_main_tb is

constant i_clk_period : TIME := 6.6 ns; --150MHz

component video_reader
generic(
G_ROTATE          : string:="OFF";
G_ROTATE_BUF_COUNT: integer:=16; --min/max - 4/32
G_MEM_BANK_M_BIT  : integer:=29;
G_MEM_BANK_L_BIT  : integer:=28;

G_MEM_VCH_M_BIT   : integer:=25;
G_MEM_VCH_L_BIT   : integer:=24;
G_MEM_VFR_M_BIT   : integer:=23;
G_MEM_VFR_L_BIT   : integer:=23;
G_MEM_VLINE_M_BIT : integer:=22;
G_MEM_VLINE_L_BIT : integer:=12;

G_MEM_AWIDTH      : integer:=32;
G_MEM_DWIDTH      : integer:=32
);
port
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch     : in    TReaderVCHParams;

p_in_hrd_chsel       : in    std_logic_vector(3 downto 0);
p_in_hrd_start       : in    std_logic;
p_in_hrd_done        : in    std_logic;

p_in_vfr_buf         : in    TVfrBufs;
p_in_vfr_nrow        : in    std_logic;

--//Статусы
p_out_vch_fr_new     : out   std_logic;
p_out_vch_rd_done    : out   std_logic;
p_out_vch            : out   std_logic_vector(3 downto 0);
p_out_vch_color_fst  : out   std_logic_vector(1 downto 0);
p_out_vch_color      : out   std_logic;
p_out_vch_pcolor     : out   std_logic;
p_out_vch_active_pix : out   std_logic_vector(15 downto 0);
p_out_vch_active_row : out   std_logic_vector(15 downto 0);
p_out_vch_zoom       : out   std_logic_vector(3 downto 0);
p_out_vch_zoom_type  : out   std_logic;
p_out_vch_mirx       : out   std_logic;

--//--------------------------
--//Upstream Port
--//--------------------------
p_out_upp_data       : out   std_logic_vector(31 downto 0);
p_out_upp_data_wd    : out   std_logic;
p_in_upp_buf_empty   : in    std_logic;
p_in_upp_buf_full    : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            : out   TMemIN;
p_in_mem             : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;

component vmirx_main
port (
-------------------------------
-- Управление
-------------------------------
p_in_cfg_mirx       : in    std_logic;
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);

p_out_cfg_mirx_done : out   std_logic;

--//--------------------------
--//Upstream Port
--//--------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(31 downto 0);
p_in_upp_wd         : in    std_logic;
p_out_upp_rdy_n     : out   std_logic;

--//--------------------------
--//Downstream Port
--//--------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     : out   std_logic_vector(31 downto 0);
p_out_dwnp_wd       : out   std_logic;
p_in_dwnp_rdy_n     : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component vcoldemosaic_main
generic(
G_DOUT_WIDTH : integer:=32;
G_SIM        : string:="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass    : in    std_logic;
p_in_cfg_colorfst  : in    std_logic_vector(1 downto 0);
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);
p_in_cfg_row_count : in    std_logic_vector(15 downto 0);
p_in_cfg_init      : in    std_logic;

--//--------------------------
--//Upstream Port
--//--------------------------
--p_in_upp_clk       : in    std_logic;
p_in_upp_data      : in    std_logic_vector(31 downto 0);
p_in_upp_wd        : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;

--//--------------------------
--//Downstream Port
--//--------------------------
--p_in_dwnp_clk      : in    std_logic;
p_out_dwnp_data    : out   std_logic_vector(127 downto 0);
p_out_dwnp_wd      : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk           : in    std_logic;
p_in_rst           : in    std_logic
);
end component;

component vscaler_main
generic(
G_USE_COLOR : string:="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
--//Конфигурирование
p_in_cfg_color      : in    std_logic;
p_in_cfg_zoom_type  : in    std_logic;
p_in_cfg_zoom       : in    std_logic_vector(3 downto 0);
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);
p_in_cfg_row_count  : in    std_logic_vector(15 downto 0);
p_in_cfg_init       : in    std_logic;

--//Статус
p_out_cfg_zoom_done : out   std_logic;

--//Доступ к RAM коэфициентов
p_in_cfg_acoe       : in    std_logic_vector(8 downto 0);
p_in_cfg_acoe_ld    : in    std_logic;
p_in_cfg_dcoe       : in    std_logic_vector(15 downto 0);
p_out_cfg_dcoe      : out   std_logic_vector(15 downto 0);
p_in_cfg_dcoe_wr    : in    std_logic;
p_in_cfg_dcoe_rd    : in    std_logic;
p_in_cfg_coe_wrclk  : in    std_logic;

--//--------------------------
--//Upstream Port (Связь с источником данных)
--//--------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(31 downto 0);
p_in_upp_wd         : in    std_logic;
p_out_upp_rdy_n     : out   std_logic;

--//--------------------------
--//Downstream Port (Связь с приемником данных)
--//--------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     : out   std_logic_vector(31 downto 0);
p_out_dwnp_wd       : out   std_logic;
p_in_dwnp_rdy_n     : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component vpcolor_main
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass     : in    std_logic;

p_in_cfg_coeram_num : in    std_logic_vector(1 downto 0);
p_in_cfg_acoe       : in    std_logic_vector(6 downto 0);
p_in_cfg_acoe_ld    : in    std_logic;
p_in_cfg_dcoe       : in    std_logic_vector(15 downto 0);
p_out_cfg_dcoe      : out   std_logic_vector(15 downto 0);
p_in_cfg_dcoe_wr    : in    std_logic;
p_in_cfg_dcoe_rd    : in    std_logic;
p_in_cfg_coe_wrclk  : in    std_logic;

--//--------------------------
--//Upstream Port
--//--------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(31 downto 0);
p_in_upp_wd         : in    std_logic;
p_out_upp_rdy_n     : out   std_logic;

--//--------------------------
--//Downstream Port
--//--------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     : out   std_logic_vector(31 downto 0);
p_out_dwnp_wd       : out   std_logic;
p_in_dwnp_rdy_n     : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component vgamma_main
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_color      : in    std_logic;

p_in_cfg_coeram_num : in    std_logic_vector(1 downto 0);
p_in_cfg_acoe       : in    std_logic_vector(6 downto 0);
p_in_cfg_acoe_ld    : in    std_logic;
p_in_cfg_dcoe       : in    std_logic_vector(15 downto 0);
p_out_cfg_dcoe      : out   std_logic_vector(15 downto 0);
p_in_cfg_dcoe_wr    : in    std_logic;
p_in_cfg_dcoe_rd    : in    std_logic;
p_in_cfg_coe_wrclk  : in    std_logic;

--//--------------------------
--//Upstream Port
--//--------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(31 downto 0);
p_in_upp_wd         : in    std_logic;
p_out_upp_rdy_n     : out   std_logic;

--//--------------------------
--//Downstream Port
--//--------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     : out   std_logic_vector(31 downto 0);
p_out_dwnp_wd       : out   std_logic;
p_in_dwnp_rdy_n     : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component vsobel_main
generic(
G_DOUT_WIDTH : integer:=32;
G_SIM        : string:="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass    : in    std_logic;                    --//0/1 - Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);--//Кол-во пиксел/4 т.к p_in_upp_data=32bit
p_in_cfg_row_count : in    std_logic_vector(15 downto 0);--//Кол-во строк (опционально)
p_in_cfg_ctrl      : in    std_logic_vector(1 downto 0); --//бит0 - 1/0 - точная грубая апроксимация формуля (dx^2 + dy^2)^0.5
                                                         --//бит1 - 1/0 - (1 - dx,dy делятся на 2. Только для Никифорова),(0 - нет делений)
p_in_cfg_init      : in    std_logic;                    --//Инициализация. Сброс счетчика адреса BRAM

--//--------------------------
--//Upstream Port (входные данные)
--//--------------------------
--p_in_upp_clk       : in    std_logic;
p_in_upp_data      : in    std_logic_vector(31 downto 0);
p_in_upp_wd        : in    std_logic;                    --//Запись данных в модуль vsobel_main.vhd
p_out_upp_rdy_n    : out   std_logic;                    --//0 - Модуль vsobel_main.vhd готов к приему данных

--//--------------------------
--//Downstream Port (результат)
--//--------------------------
--p_in_dwnp_clk      : in    std_logic;
p_in_dwnp_rdy_n    : in    std_logic;                    --//0 - порт приемника готов к приему даннвх
p_out_dwnp_wd      : out   std_logic;                    --//Запись данных в приемник
p_out_dwnp_data    : out   std_logic_vector(31 downto 0);

p_out_dwnp_grad    : out   std_logic_vector(31 downto 0);--//Градиент яркости

p_out_dwnp_dxm     : out   std_logic_vector((8*4)-1 downto 0); --//dX - модуль
p_out_dwnp_dym     : out   std_logic_vector((8*4)-1 downto 0); --//dY - модуль

p_out_dwnp_dxs     : out   std_logic_vector((11*4)-1 downto 0);--//dX - знаковое значение(бит 10)
p_out_dwnp_dys     : out   std_logic_vector((11*4)-1 downto 0);--//dY - знаковое значение(бит 10)

-------------------------------
--Технологический
-------------------------------
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk           : in    std_logic;
p_in_rst           : in    std_logic
);
end component;





signal i_mem_arb1_read_dly_cnt          : std_logic_vector(3 downto 0);
signal i_mem_arb1_read_dly              : std_logic;

signal p_in_clk            : std_logic;
signal p_in_rst            : std_logic;


signal p_in_vctrl_hrdchsel        : std_logic_vector(3 downto 0);   --//Номер видео канала который будет читать ХОСТ
signal p_in_vctrl_hrdstart        : std_logic;                      --//Начало чтенения видеоканала
signal p_in_vctrl_hrddone         : std_logic;                      --//Подтверждение вычетки данных видеоканала

--//CH READ
signal p_out_memarb_rdreq         : std_logic;
signal p_in_memarb_rden           : std_logic;

signal p_out_memrd_bank1h         : std_logic_vector(3 downto 0);
signal p_out_memrd_ce             : std_logic;
signal p_out_memrd_cw             : std_logic;
signal p_out_memrd_rd             : std_logic;
signal p_out_memrd_wr             : std_logic;
signal p_out_memrd_term           : std_logic;
signal p_out_memrd_adr            : std_logic_vector(C_MEMWR_AWIDTH_MAX - 1 downto 0);
signal p_out_memrd_be             : std_logic_vector(C_MEMWR_DWIDTH_MAX / 8 - 1 downto 0);
signal p_out_memrd_din            : std_logic_vector(C_MEMWR_DWIDTH_MAX - 1 downto 0);
signal p_in_memrd_dout            : std_logic_vector(C_MEMWR_DWIDTH_MAX - 1 downto 0);

signal p_in_memrd_wf              : std_logic;
signal p_in_memrd_wpf             : std_logic;
signal p_in_memrd_re              : std_logic:='1';
signal p_in_memrd_rpe             : std_logic;


signal p_in_host_clk         : std_logic:='0';

signal p_in_cfg_adr          : std_logic_vector(7 downto 0):=(others=>'0');
signal p_in_cfg_adr_ld       : std_logic:='0';
signal p_in_cfg_adr_fifo     : std_logic:='0';

signal p_in_cfg_txdata       : std_logic_vector(15 downto 0):=(others=>'0');
signal p_in_cfg_wd           : std_logic:='0';

signal p_out_cfg_rxdata      : std_logic_vector(15 downto 0);  --//
signal p_in_cfg_rd           : std_logic:='0';

signal p_in_cfg_done         : std_logic:='0';


signal p_out_vbufout_din          :   std_logic_vector(31 downto 0);  --//Связь с буферов видео данных для ХОСТА
signal p_out_vbufout_din_wd       :   std_logic;                      --//
signal p_in_vbufout_empty         :   std_logic:='0';                      --//
signal p_in_vbufout_full          :   std_logic;                      --//


signal i_cfg_adr_cnt                     : std_logic_vector(7 downto 0):=(others=>'0');

signal h_reg_ctrl                        : std_logic_vector(C_VCTRL_REG_CTRL_LAST_BIT downto 0);
signal h_reg_tst0                        : std_logic_vector(C_VCTRL_REG_TST0_LAST_BIT downto 0);
signal h_ramcoe_num                      : std_logic_vector(C_VCTRL_REG_CTRL_RAMCOE_M_BIT-C_VCTRL_REG_CTRL_RAMCOE_L_BIT downto 0);

signal i_vprm                            : TVctrlParam;
signal i_rdprm_vch                       : TReaderVCHParams;

signal i_vbuf_rd                         : TVfrBufs;

signal i_vreader_fr_new                  : std_logic;
signal i_vreader_rd_done                 : std_logic;
signal i_vreader_rq_next_line            : std_logic;
signal i_vreader_vch_num_out             : std_logic_vector(3 downto 0);
signal i_vreader_color_fst_out           : std_logic_vector(1 downto 0);
signal i_vreader_color_out               : std_logic;
signal i_vreader_pcolor_out              : std_logic;
signal i_vreader_active_pix_out          : std_logic_vector(15 downto 0);
signal i_vreader_active_row_out          : std_logic_vector(15 downto 0);
signal i_vreader_zoom_out                : std_logic_vector(3 downto 0);
signal i_vreader_zoom_type_out           : std_logic;
signal i_vreader_mirx_out                : std_logic;
signal i_vreader_dout                    : std_logic_vector(31 downto 0);
signal i_vreader_dout_en                 : std_logic;

signal i_vmir_rdy_n                      : std_logic;
signal i_vmir_dout                       : std_logic_vector(31 downto 0);
signal i_vmir_dout_en                    : std_logic;

signal i_vcoldemasc_bypass               : std_logic;
signal i_vcoldemasc_rdy_n                : std_logic;
signal i_vcoldemasc_dout                 : std_logic_vector(127 downto 0);
signal i_vcoldemasc_dout_en              : std_logic;

signal i_vscale_coe_ram_en               : std_logic;
signal i_vscale_coe_adr                  : std_logic_vector(8 downto 0);
signal i_vscale_coe_adr_ld               : std_logic;
signal i_vscale_coe_din                  : std_logic_vector(15 downto 0);
signal i_vscale_coe_dout                 : std_logic_vector(15 downto 0);
signal i_vscale_coe_wr                   : std_logic;
signal i_vscale_coe_rd                   : std_logic;
signal i_vscale_rdy_n                    : std_logic;
signal i_vscale_dout                     : std_logic_vector(31 downto 0);
signal i_vscale_dout_en                  : std_logic;
signal i_vscale_pix_count                : std_logic_vector(15 downto 0);
signal i_vscale_row_count                : std_logic_vector(15 downto 0);
--signal i_vscale_tst_out                  : std_logic_vector(7 downto 0);

signal i_vpcolor_coe_ramnum              : std_logic_vector(2 downto 0);
signal i_vpcolor_coe_adr                 : std_logic_vector(6 downto 0);
signal i_vpcolor_coe_adr_ld              : std_logic;
signal i_vpcolor_coe_din                 : std_logic_vector(15 downto 0);
signal i_vpcolor_coe_dout                : std_logic_vector(15 downto 0);
signal i_vpcolor_coe_wr                  : std_logic;
signal i_vpcolor_coe_rd                  : std_logic;
signal i_vpcolor_bypass                  : std_logic;
signal i_vpcolor_rdy_n                   : std_logic;
signal i_vpcolor_dout                    : std_logic_vector(31 downto 0);
signal i_vpcolor_dout_en                 : std_logic;

signal i_vgamma_coe_ramnum               : std_logic_vector(2 downto 0);
signal i_vgamma_coe_adr                  : std_logic_vector(6 downto 0);
signal i_vgamma_coe_adr_ld               : std_logic;
signal i_vgamma_coe_din                  : std_logic_vector(15 downto 0);
signal i_vgamma_coe_dout                 : std_logic_vector(15 downto 0);
signal i_vgamma_coe_wr                   : std_logic;
signal i_vgamma_coe_rd                   : std_logic;
signal i_vgamma_color                    : std_logic;
signal i_vgamma_rdy_n                    : std_logic;
--signal i_vgamma_dout                     : std_logic_vector(31 downto 0);
--signal i_vgamma_dout_en                  : std_logic;

signal i_vsobel_cfg_bypass               : std_logic;
signal i_vsobel_cfg_ctrl                 : std_logic_vector(1 downto 0);
signal i_vsobel_rdy_n                    : std_logic;
signal i_vsobel_grad                     : std_logic_vector(31 downto 0);
signal i_vsobel_grad_en                  : std_logic;



--signal tst_vwriter_out                   : std_logic_vector(31 downto 0);
signal tst_vreader_out                   : std_logic_vector(31 downto 0);
signal tst_ctrl                          : std_logic_vector(31 downto 0);

--//Параметры VCTRL
type TVctrlParamTST is record
mem_wd_trn_len  : std_logic_vector(7 downto 0);
mem_rd_trn_len  : std_logic_vector(7 downto 0);
ch              : TVctrlChParam;
end record;

signal usrcfg                            : TVctrlParamTST;
signal usrcfg_zoom_type                  : std_logic;
signal usrcfg_zoom_size_x2               : std_logic;
signal usrcfg_zoom_size_x4               : std_logic;
signal usrcfg_zoom_up_on                 : std_logic;
signal usrcfg_zoom_dwn_on                : std_logic;

signal usrcfg_fr_count                   : std_logic_vector(7 downto 0);
signal p_in_cfg_pix_count                : std_logic_vector(15 downto 0);
signal p_in_cfg_row_count                : std_logic_vector(15 downto 0);
signal tst_data_en                       : std_logic;
signal tst_data_out                      : std_logic_vector(31 downto 0);


signal mnl_use_gen_dwnp_rdy           : std_logic;
signal tst_mnl_fr_pause               : std_logic_vector(31 downto 0);
signal tst_mnl_row_pause              : std_logic_vector(31 downto 0);

signal tst_frpuase_count              : std_logic_vector(31 downto 0);
signal tst_rowpause_count             : std_logic_vector(31 downto 0);
signal tst_vfr_count                  : std_logic_vector(usrcfg_fr_count'range);
signal tst_row_count                  : std_logic_vector(p_in_cfg_pix_count'range);
signal tst_pix_count                  : std_logic_vector(p_in_cfg_row_count'range);
signal tst_data                       : std_logic_vector(7 downto 0);
signal i_upp_frpause                  : std_logic;
signal i_upp_rowpause                 : std_logic;
signal i_upp_wd_en                    : std_logic;
signal i_upp_wd_stop                  : std_logic;
--signal i_dwnp_rdy_n                   : std_logic;

signal tst_dwnp_pix_max               : std_logic_vector(p_in_cfg_pix_count'range);
signal tst_dwnp_row_max               : std_logic_vector(p_in_cfg_row_count'range);
signal tst_dwnp_pix                   : std_logic_vector(p_in_cfg_pix_count'range);
signal tst_dwnp_row                   : std_logic_vector(p_in_cfg_row_count'range);
signal tst_dwnp_fr                    : std_logic_vector(15 downto 0);
signal tst_dwnp_dcount                : std_logic_vector(31 downto 0);
signal tst_incr                       : std_logic_vector(p_in_cfg_pix_count'range);
signal tst_fr_read_done               : std_logic;
signal sr_tst_fr_read_done            : std_logic_vector(0 to 31);


signal mnl_write_testdata           : std_logic;
signal usr_start0                   : std_logic;
signal usr_start1                   : std_logic;
signal usr_start                    : std_logic;

signal i_srambler_out                 : std_logic_vector(31 downto 0);

signal mnl_only_1_frame             : std_logic;

signal p_out_mem: TMemIN;
signal p_in_mem : TMemOUT;

--Main
begin


clk_in_generator : process
begin
  p_in_clk<='0';
  wait for i_clk_period/2;
  p_in_clk<='1';
  wait for i_clk_period/2;
end process;

p_in_rst<='1','0' after 1 us;


--//Имитация работы модуля контроллера попмяти (mem_ctrl.vhd)
p_in_mem.data<=tst_data_out;
p_in_mem.buf_wpf<='0';

--p_in_memrd_wf <='0';
--p_in_memrd_wpf<='0';
--p_in_memrd_rpe<='0';

p_in_mem.req_en<='1';

--p_in_memrd_dout<=tst_data_out;

process(p_in_rst, p_in_clk)
  variable var_mem_arb1_read: std_logic;
--  variable var_mem_arb1_dout_sim: std_logic_vector(7 downto 0);
begin
  if p_in_rst='1' then
    i_mem_arb1_read_dly_cnt<=(others=>'0');
    i_mem_arb1_read_dly<='0';
    p_in_mem.buf_re <='1';

--    var_mem_arb1_dout_sim:=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    var_mem_arb1_read:='0';

    if p_out_mem.ce='1' and p_out_mem.cw='0' then
      i_mem_arb1_read_dly<='1';
    else
      if i_mem_arb1_read_dly='1' then ---and i_upp_wd_stop='0' then
        if i_mem_arb1_read_dly_cnt="1100" then
          i_mem_arb1_read_dly_cnt<=(others=>'0');
          i_mem_arb1_read_dly<='0';
          var_mem_arb1_read:='1';
        else
          i_mem_arb1_read_dly_cnt<=i_mem_arb1_read_dly_cnt+1;
        end if;
      end if;
    end if;

--    if i_upp_wd_stop='0' then
        if var_mem_arb1_read='1' then
          p_in_mem.buf_re <='0';
        elsif p_out_mem.term='1' then
          p_in_mem.buf_re <='1';
        end if;
--    end if;

  end if;
end process;

tst_data_en<=not p_in_mem.buf_re and p_out_mem.rd;

gen_vbuf : for i in 0 to C_VCTRL_VCH_COUNT_MAX-1 generate
begin
i_vbuf_rd(i)<=(others=>'0');
end generate gen_vbuf;



gen_vrdprm : for i in 0 to C_VCTRL_VCH_COUNT-1 generate
begin
i_rdprm_vch(i).mem_adr        <=i_vprm.ch(i).mem_addr_rd;--i_vprm.ch(i).mem_addr_wr;--
i_rdprm_vch(i).fr_size        <=i_vprm.ch(i).fr_size;
i_rdprm_vch(i).fr_mirror      <=i_vprm.ch(i).fr_mirror;
i_rdprm_vch(i).fr_pcolor      <=i_vprm.ch(i).fr_pcolor;
i_rdprm_vch(i).fr_zoom        <=i_vprm.ch(i).fr_zoom;
i_rdprm_vch(i).fr_zoom_type   <=i_vprm.ch(i).fr_zoom_type;
i_rdprm_vch(i).fr_color       <=i_vprm.ch(i).fr_color;
i_rdprm_vch(i).fr_color_fst   <=i_vprm.ch(i).fr_color_fst;
end generate gen_vrdprm;



--//-----------------------------
--//Модуль чтение видео информации из ОЗУ
--//-----------------------------
m_video_reader : video_reader
generic map(
G_ROTATE          => G_ROTATE,
G_ROTATE_BUF_COUNT=> G_ROTATE_BUF_COUNT,
G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,

G_MEM_VCH_M_BIT   => C_VCTRL_MEM_VCH_M_BIT,
G_MEM_VCH_L_BIT   => C_VCTRL_MEM_VCH_L_BIT,
G_MEM_VFR_M_BIT   => C_VCTRL_MEM_VFR_M_BIT,
G_MEM_VFR_L_BIT   => C_VCTRL_MEM_VFR_L_BIT,
G_MEM_VLINE_M_BIT => C_VCTRL_MEM_VLINE_M_BIT,
G_MEM_VLINE_L_BIT => C_VCTRL_MEM_VLINE_L_BIT
)
port map
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len => i_vprm.mem_rd_trn_len,
p_in_cfg_prm_vch     => i_rdprm_vch,

p_in_hrd_chsel       => p_in_vctrl_hrdchsel,
p_in_hrd_start       => p_in_vctrl_hrdstart,
p_in_hrd_done        => p_in_vctrl_hrddone,

p_in_vfr_buf         => i_vbuf_rd,
p_in_vfr_nrow        => i_vreader_rq_next_line,

--//Статусы
p_out_vch_fr_new     => i_vreader_fr_new,
p_out_vch_rd_done    => i_vreader_rd_done,
p_out_vch            => i_vreader_vch_num_out,
p_out_vch_color_fst  => i_vreader_color_fst_out,
p_out_vch_color      => i_vreader_color_out,
p_out_vch_pcolor     => i_vreader_pcolor_out,
p_out_vch_active_pix => i_vreader_active_pix_out,
p_out_vch_active_row => i_vreader_active_row_out,
p_out_vch_zoom       => i_vreader_zoom_out,
p_out_vch_zoom_type  => i_vreader_zoom_type_out,
p_out_vch_mirx       => i_vreader_mirx_out,

--//--------------------------
--//Upstream Port
--//--------------------------
p_out_upp_data       => i_vreader_dout,
p_out_upp_data_wd    => i_vreader_dout_en,
p_in_upp_buf_empty   => '0',
p_in_upp_buf_full    => i_vmir_rdy_n,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_mem,--: out   TMemIN;
p_in_mem             => p_in_mem ,--: in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst             => tst_ctrl(31 downto 0),--"00000000000000000000000000000000",
p_out_tst            => tst_vreader_out,

-------------------------------
--System
-------------------------------
p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);



--//-----------------------------
--//Модуль отзеркаливания по Х
--//-----------------------------
m_vmirx : vmirx_main
port map (
-------------------------------
-- Управление
-------------------------------
p_in_cfg_mirx       => i_vreader_mirx_out,
p_in_cfg_pix_count  => i_vreader_active_pix_out,

p_out_cfg_mirx_done => i_vreader_rq_next_line,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data       => i_vreader_dout,
p_in_upp_wd         => i_vreader_dout_en,
p_out_upp_rdy_n     => i_vmir_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data     => i_vmir_dout,
p_out_dwnp_wd       => i_vmir_dout_en,
p_in_dwnp_rdy_n     => i_vcoldemasc_rdy_n,

-------------------------------
--Технологический
-------------------------------
p_in_tst            => "00000000000000000000000000000000",
p_out_tst           => open,

-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);



--//-----------------------------
--//Модуль интерполяции цвета
--//Конвертирование значений фильта Байера в правельный цвет RGB
--//-----------------------------
i_vcoldemasc_bypass<=not i_vreader_color_out;

m_vcoldemosaic : vcoldemosaic_main
generic map(
G_DOUT_WIDTH => 8,
G_SIM        => G_SIM
)
port map (
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass    => i_vcoldemasc_bypass,
p_in_cfg_colorfst  => i_vreader_color_fst_out,
p_in_cfg_pix_count => i_vreader_active_pix_out,
p_in_cfg_row_count => i_vreader_active_row_out,
p_in_cfg_init      => i_vreader_fr_new,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data      => i_vmir_dout,
p_in_upp_wd        => i_vmir_dout_en,
p_out_upp_rdy_n    => i_vcoldemasc_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data    => i_vcoldemasc_dout,
p_out_dwnp_wd      => i_vcoldemasc_dout_en,
p_in_dwnp_rdy_n    => i_vscale_rdy_n,

-------------------------------
--Технологический
-------------------------------
p_in_tst           => "00000000000000000000000000000000",
p_out_tst          => open,
-------------------------------
--System
-------------------------------
p_in_clk           => p_in_clk,
p_in_rst           => p_in_rst
);



--//-----------------------------
--//Модуль масштабирования изображения
--//-----------------------------
--//Доступ к BRAM коэфициентов
i_vscale_coe_adr   <=p_in_cfg_txdata(i_vscale_coe_adr'high downto 0);
i_vscale_coe_adr_ld<=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) and
                                      h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_ADR_BIT)='1' and
                                      h_reg_ctrl(C_VCTRL_REG_CTRL_SET_BIT)='1' and
                                      i_vscale_coe_ram_en='1' else '0';

i_vscale_coe_din<=p_in_cfg_txdata;
i_vscale_coe_wr <=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) and
                                   h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                   h_reg_ctrl(C_VCTRL_REG_CTRL_SET_BIT)='1' and
                                   i_vscale_coe_ram_en='1' else '0';

i_vscale_coe_rd <=p_in_cfg_rd or p_in_cfg_adr_ld when p_in_cfg_adr=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) and
                                                      h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                                      h_reg_ctrl(C_VCTRL_REG_CTRL_SET_BIT)='0' and
                                                      i_vscale_coe_ram_en='1' else '0';

i_vscale_coe_ram_en<='1' when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_VCTRL_RAMCOE_SCALE, h_ramcoe_num'length) else '0';

i_vscale_pix_count <= i_vreader_active_pix_out when i_vreader_color_out='0' else (i_vreader_active_pix_out(13 downto 0)&"00");
i_vscale_row_count <= i_vreader_active_row_out;

m_vscaler : vscaler_main
generic map(
G_USE_COLOR => "ON"
)
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_color      => i_vreader_color_out,
p_in_cfg_zoom_type  => i_vreader_zoom_type_out,
p_in_cfg_zoom       => i_vreader_zoom_out,
p_in_cfg_pix_count  => i_vscale_pix_count,--i_vreader_active_pix_out,
p_in_cfg_row_count  => i_vscale_row_count,--i_vreader_active_row_out,
p_in_cfg_init       => i_vreader_fr_new,

p_out_cfg_zoom_done => open,

p_in_cfg_acoe       => i_vscale_coe_adr,
p_in_cfg_acoe_ld    => i_vscale_coe_adr_ld,
p_in_cfg_dcoe       => i_vscale_coe_din,
p_out_cfg_dcoe      => i_vscale_coe_dout,
p_in_cfg_dcoe_wr    => i_vscale_coe_wr,
p_in_cfg_dcoe_rd    => i_vscale_coe_rd,
p_in_cfg_coe_wrclk  => p_in_host_clk,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data       => i_vcoldemasc_dout(31 downto 0),
p_in_upp_wd         => i_vcoldemasc_dout_en,
p_out_upp_rdy_n     => i_vscale_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data     => i_vscale_dout,
p_out_dwnp_wd       => i_vscale_dout_en,
p_in_dwnp_rdy_n     => i_vpcolor_rdy_n,

-------------------------------
--Технологический
-------------------------------
p_in_tst            => "00000000000000000000000000000000",
p_out_tst           => open,

-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);



--//-----------------------------
--//Модуль формирования псевдоцвета.
--//Преобразование градаций серого в RGB
--//-----------------------------
i_vpcolor_bypass<=not i_vreader_pcolor_out;

--//Доступ к BRAM коэфициентов
i_vpcolor_coe_adr   <=p_in_cfg_txdata(i_vpcolor_coe_adr'high downto 0);
i_vpcolor_coe_adr_ld<=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) and
                                       h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_ADR_BIT)='1' and
                                       h_reg_ctrl(C_VCTRL_REG_CTRL_SET_BIT)='1' and
                                       i_vpcolor_coe_ramnum(2)='1' else '0';

i_vpcolor_coe_din<=p_in_cfg_txdata(15 downto 0);
i_vpcolor_coe_wr <=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) and
                                    h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                    h_reg_ctrl(C_VCTRL_REG_CTRL_SET_BIT)='1' and
                                    i_vpcolor_coe_ramnum(2)='1' else '0';

i_vpcolor_coe_rd <=p_in_cfg_rd or p_in_cfg_adr_ld when p_in_cfg_adr=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) and
                                                       h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                                       h_reg_ctrl(C_VCTRL_REG_CTRL_SET_BIT)='0' and
                                                       i_vpcolor_coe_ramnum(2)='1' else '0';

i_vpcolor_coe_ramnum<="100" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_VCTRL_RAMCOE_PCOLR, h_ramcoe_num'length) else
                      "101" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_VCTRL_RAMCOE_PCOLG, h_ramcoe_num'length) else
                      "110" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_VCTRL_RAMCOE_PCOLB, h_ramcoe_num'length) else
                      "000";

m_vpcolor : vpcolor_main
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass     => i_vpcolor_bypass,

p_in_cfg_coeram_num => i_vpcolor_coe_ramnum(1 downto 0),
p_in_cfg_acoe       => i_vpcolor_coe_adr,
p_in_cfg_acoe_ld    => i_vpcolor_coe_adr_ld,
p_in_cfg_dcoe       => i_vpcolor_coe_din,
p_out_cfg_dcoe      => i_vpcolor_coe_dout,
p_in_cfg_dcoe_wr    => i_vpcolor_coe_wr,
p_in_cfg_dcoe_rd    => i_vpcolor_coe_rd,
p_in_cfg_coe_wrclk  => p_in_host_clk,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data       => i_vscale_dout,
p_in_upp_wd         => i_vscale_dout_en,
p_out_upp_rdy_n     => i_vpcolor_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data     => i_vpcolor_dout,
p_out_dwnp_wd       => i_vpcolor_dout_en,
p_in_dwnp_rdy_n     => i_vsobel_rdy_n,--=> i_vgamma_rdy_n,

-------------------------------
--Технологический
-------------------------------
p_in_tst            => "00000000000000000000000000000000",
p_out_tst           => open,
-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);


m_vsobel : vsobel_main
generic map(
G_DOUT_WIDTH => 8,
G_SIM        => G_SIM
)
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass    => i_vsobel_cfg_bypass,
p_in_cfg_pix_count => i_vreader_active_pix_out,
p_in_cfg_row_count => i_vreader_active_row_out,
p_in_cfg_ctrl      => i_vsobel_cfg_ctrl,
p_in_cfg_init      => i_vreader_fr_new,

--//--------------------------
--//Upstream Port
--//--------------------------
--p_in_upp_clk       : in    std_logic;
p_in_upp_data      => i_vpcolor_dout,
p_in_upp_wd        => i_vpcolor_dout_en,
p_out_upp_rdy_n    => i_vsobel_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
--p_in_dwnp_clk      : in    std_logic;
p_out_dwnp_data    => p_out_vbufout_din,
p_out_dwnp_wd      => p_out_vbufout_din_wd,--tst_vbufout_din_wd,--
p_in_dwnp_rdy_n    => p_in_vbufout_full,

p_out_dwnp_grad    => i_vsobel_grad,

p_out_dwnp_dxm     => open,
p_out_dwnp_dym     => open,

p_out_dwnp_dxs     => open,
p_out_dwnp_dys     => open,

-------------------------------
--Технологический
-------------------------------
p_in_tst           => "00000000000000000000000000000000",
p_out_tst          => open,

-------------------------------
--System
-------------------------------
p_in_clk           => p_in_clk,
p_in_rst           => p_in_rst
);


--//-----------------------------
--//Модуль Gamma коррекции.
--//-----------------------------
i_vgamma_color<=i_vreader_color_out or i_vreader_pcolor_out;

--//Доступ к BRAM коэфициентов
i_vgamma_coe_adr   <=p_in_cfg_txdata(i_vgamma_coe_adr'high downto 0);
i_vgamma_coe_adr_ld<=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) and
                                      h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_ADR_BIT)='1' and
                                      h_reg_ctrl(C_VCTRL_REG_CTRL_SET_BIT)='1' and
                                      i_vgamma_coe_ramnum(2)='1' else '0';

i_vgamma_coe_din<=p_in_cfg_txdata(15 downto 0);
i_vgamma_coe_wr <=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) and
                                   h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                   h_reg_ctrl(C_VCTRL_REG_CTRL_SET_BIT)='1' and
                                   i_vgamma_coe_ramnum(2)='1' else '0';

i_vgamma_coe_rd <=p_in_cfg_rd or p_in_cfg_adr_ld when p_in_cfg_adr=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) and
                                                      h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                                      h_reg_ctrl(C_VCTRL_REG_CTRL_SET_BIT)='0' and
                                                      i_vgamma_coe_ramnum(2)='1' else '0';

i_vgamma_coe_ramnum<="100" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_VCTRL_RAMCOE_GAMMA_GRAY, h_ramcoe_num'length) else
                     "101" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_VCTRL_RAMCOE_GAMMA_COLR, h_ramcoe_num'length) else
                     "110" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_VCTRL_RAMCOE_GAMMA_COLG, h_ramcoe_num'length) else
                     "111" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_VCTRL_RAMCOE_GAMMA_COLB, h_ramcoe_num'length) else
                     "000";


m_vgamma: vgamma_main
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_color      => i_vgamma_color,

p_in_cfg_coeram_num => i_vgamma_coe_ramnum(1 downto 0),
p_in_cfg_acoe       => i_vgamma_coe_adr,
p_in_cfg_acoe_ld    => i_vgamma_coe_adr_ld,
p_in_cfg_dcoe       => i_vgamma_coe_din,
p_out_cfg_dcoe      => i_vgamma_coe_dout,
p_in_cfg_dcoe_wr    => i_vgamma_coe_wr,
p_in_cfg_dcoe_rd    => i_vgamma_coe_rd,
p_in_cfg_coe_wrclk  => p_in_host_clk,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data       => i_vpcolor_dout,
p_in_upp_wd         => i_vpcolor_dout_en,
p_out_upp_rdy_n     => i_vgamma_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
--p_out_dwnp_data     => p_out_vbufout_din,
--p_out_dwnp_wd       => p_out_vbufout_din_wd,--tst_vbufout_din_wd,--
--p_in_dwnp_rdy_n     => p_in_vbufout_full,
p_out_dwnp_data     => open,--p_out_vbufout_din,
p_out_dwnp_wd       => open,--p_out_vbufout_din_wd,--tst_vbufout_din_wd,--
p_in_dwnp_rdy_n     => '0',--p_in_vbufout_full,
-------------------------------
--Технологический
-------------------------------
p_in_tst            => "00000000000000000000000000000000",
p_out_tst           => open,
-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);









--//----------------------------------------------------------
--//Настройка тестирования
--//----------------------------------------------------------
--tst_ctrl<=(others=>'0');
tst_ctrl(2 downto 0)<=(others=>'0');
tst_ctrl(3)<='1';--Rotate right
tst_ctrl(4)<='0';--Rotate left
tst_ctrl(31 downto 5)<=(others=>'0');

--//Конфигурируем генератор тестровых данных:
usrcfg.mem_wd_trn_len<=CONV_STD_LOGIC_VECTOR(16#80#, usrcfg.mem_wd_trn_len'length);
usrcfg.mem_rd_trn_len<=CONV_STD_LOGIC_VECTOR(16#80#, usrcfg.mem_rd_trn_len'length);

usrcfg.ch.mem_addr_wr<=CONV_STD_LOGIC_VECTOR(10#00#, usrcfg.ch.mem_addr_rd'length);
usrcfg.ch.mem_addr_rd<=CONV_STD_LOGIC_VECTOR(10#00#, usrcfg.ch.mem_addr_rd'length);
usrcfg.ch.fr_size.skip.pix <=CONV_STD_LOGIC_VECTOR(10#00#, usrcfg.ch.fr_size.skip.pix'length);
usrcfg.ch.fr_size.skip.row <=CONV_STD_LOGIC_VECTOR(10#00#, usrcfg.ch.fr_size.skip.row'length);
usrcfg.ch.fr_size.activ.pix<=CONV_STD_LOGIC_VECTOR(10#16#, usrcfg.ch.fr_size.activ.pix'length);
usrcfg.ch.fr_size.activ.row<=CONV_STD_LOGIC_VECTOR(10#16#, usrcfg.ch.fr_size.activ.row'length);
usrcfg.ch.fr_mirror.pix<='0';
usrcfg.ch.fr_mirror.row<='1';
usrcfg.ch.fr_pcolor<='0';
usrcfg.ch.fr_color<='0';
usrcfg.ch.fr_color_fst<=CONV_STD_LOGIC_VECTOR(10#00#, usrcfg.ch.fr_color_fst'length);
--//Конфигурируем работу модуля vscaler_main.vhd:
usrcfg_zoom_type<='0';--//0/1 - Инткрполяция/1 дулирование
--//Размер - Увеличение/Уменьшение
usrcfg_zoom_size_x2<='0';
usrcfg_zoom_size_x4<='0';
--//Увеличение/Уменьшение
usrcfg_zoom_up_on  <='0';
usrcfg_zoom_dwn_on <='0';

--//Настройки модуля SOBEL
i_vsobel_cfg_bypass<='1'; --//1/0 - Выкл/Вкл
i_vsobel_cfg_ctrl(0)<='0';--//бит0 - 1/0 - точная грубая апроксимация формуля (dx^2 + dy^2)^0.5
i_vsobel_cfg_ctrl(1)<='0';--//бит1 - 1/0 - (1 - dx,dy делятся на 2. Только для Никифорова),(0 - нет делений)

usrcfg_fr_count <=CONV_STD_LOGIC_VECTOR(16#01#, usrcfg_fr_count'length);     --Кол-во тестовых кодров
tst_mnl_row_pause<=CONV_STD_LOGIC_VECTOR(16#00#, tst_mnl_row_pause'length);  --//Пауза между строками
tst_mnl_fr_pause <=CONV_STD_LOGIC_VECTOR(16#00#, tst_mnl_fr_pause'length);   --//Пауза между кадрами

--// 1/0 Генерировать/НЕ Гненерировать waveform для сигнала p_in_dwnp_rdy_n
mnl_use_gen_dwnp_rdy<='0';

mnl_only_1_frame<='0';--//1- только 1 кадр, 0 - много кадров








--//----------------------------------------------------------
--//
--//----------------------------------------------------------
usrcfg.ch.fr_zoom_type<=usrcfg_zoom_type;
--0/1/2 - bypass/ZoomDown/ZoomUp
usrcfg.ch.fr_zoom(3 downto 2)<=CONV_STD_LOGIC_VECTOR(16#02#, 2) when usrcfg_zoom_up_on='1' and usrcfg_zoom_dwn_on='0' else
                               CONV_STD_LOGIC_VECTOR(16#01#, 2) when usrcfg_zoom_up_on='0' and usrcfg_zoom_dwn_on='1' else
                               CONV_STD_LOGIC_VECTOR(16#00#, 2);
--1/2   - x2/x4
usrcfg.ch.fr_zoom(1 downto 0)<=CONV_STD_LOGIC_VECTOR(16#02#, 2) when usrcfg_zoom_size_x2='0' and usrcfg_zoom_size_x4='1' else
                               CONV_STD_LOGIC_VECTOR(16#01#, 2);

p_in_cfg_pix_count<="00"&usrcfg.ch.fr_size.activ.pix(usrcfg.ch.fr_size.activ.pix'high downto 2);--CONV_STD_LOGIC_VECTOR(16#32#, p_in_cfg_pix_count'length);--
p_in_cfg_row_count<=usrcfg.ch.fr_size.activ.row;                                                --CONV_STD_LOGIC_VECTOR(16#32#, p_in_cfg_row_count'length);--

gen_vprm : for i in 0 to C_VCTRL_VCH_COUNT-1 generate
begin
i_vprm.ch(i).mem_addr_wr    <=usrcfg.ch.mem_addr_wr;
i_vprm.ch(i).mem_addr_rd    <=usrcfg.ch.mem_addr_rd;
i_vprm.ch(i).fr_size.skip.pix <="00"&usrcfg.ch.fr_size.skip.pix(usrcfg.ch.fr_size.skip.pix'high downto 2);
i_vprm.ch(i).fr_size.skip.row <=usrcfg.ch.fr_size.skip.row;
i_vprm.ch(i).fr_size.activ.pix<="00"&usrcfg.ch.fr_size.activ.pix(usrcfg.ch.fr_size.activ.pix'high downto 2);
i_vprm.ch(i).fr_size.activ.row<=usrcfg.ch.fr_size.activ.row;
i_vprm.ch(i).fr_mirror      <=usrcfg.ch.fr_mirror;
i_vprm.ch(i).fr_pcolor      <=usrcfg.ch.fr_pcolor;
i_vprm.ch(i).fr_zoom        <=usrcfg.ch.fr_zoom;
i_vprm.ch(i).fr_zoom_type   <=usrcfg.ch.fr_zoom_type;
i_vprm.ch(i).fr_color       <=usrcfg.ch.fr_color;
i_vprm.ch(i).fr_color_fst   <=usrcfg.ch.fr_color_fst;
end generate gen_vprm;

i_vprm.mem_wd_trn_len    <=usrcfg.mem_wd_trn_len;
i_vprm.mem_rd_trn_len    <=usrcfg.mem_rd_trn_len;

p_in_cfg_txdata<=(others=>'0');
p_in_cfg_wd<='0';

h_reg_ctrl<=(others=>'0');
h_reg_tst0<=(others=>'0');
h_ramcoe_num<=(others=>'0');



p_in_vctrl_hrdchsel  <=(others=>'0');
p_in_vctrl_hrdstart  <=usr_start or sr_tst_fr_read_done(30);
p_in_vctrl_hrddone   <=tst_fr_read_done when mnl_only_1_frame='0' else '0';

mnl_write_testdata<='0','1' after 2.5 us;

p_in_vbufout_full<=i_srambler_out(0)when mnl_use_gen_dwnp_rdy='1' else '0';

--//Генератор сигнала p_in_dwnp_rdy_n
process(p_in_rst,p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    if p_in_rst='1' then
      i_srambler_out<=srambler32_0(CONV_STD_LOGIC_VECTOR(16#52325032#, 16));
    else
      i_srambler_out<=srambler32_0(i_srambler_out(31 downto 16));
    end if;
  end if;
end process;

--//Генератор тестовых данных
process(p_in_rst,p_in_clk)
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
begin
  if p_in_rst='1' then

    tst_frpuase_count<=(others=>'0');
    tst_rowpause_count<=(others=>'0');
    tst_vfr_count<=(others=>'0');
    tst_row_count<=(others=>'0');
    tst_pix_count<=(others=>'0');
    tst_data<=CONV_STD_LOGIC_VECTOR(8+2, tst_data'length); --//

    tst_data_out(7 downto 0)  <=CONV_STD_LOGIC_VECTOR(16#2#, tst_data'length);
    tst_data_out(15 downto 8) <=CONV_STD_LOGIC_VECTOR(16#2#, tst_data'length)+2;
    tst_data_out(23 downto 16)<=CONV_STD_LOGIC_VECTOR(16#2#, tst_data'length)+4;
    tst_data_out(31 downto 24)<=CONV_STD_LOGIC_VECTOR(16#2#, tst_data'length)+6;

    i_upp_frpause<='0';
    i_upp_rowpause<='0';
    i_upp_wd_en<='0';
    i_upp_wd_stop<='0';

    usr_start0<='0';
    usr_start1<='0';
    usr_start<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    usr_start0<=mnl_write_testdata;
    usr_start1<=usr_start0;
    usr_start<=usr_start0 and not usr_start1;


      if i_upp_frpause='1' then
        if tst_frpuase_count=tst_mnl_fr_pause then
          tst_frpuase_count<=(others=>'0');
          i_upp_frpause<='0';
        else
          tst_frpuase_count<=tst_frpuase_count + 1;
        end if;

      elsif i_upp_rowpause='1' then
        if tst_rowpause_count=tst_mnl_row_pause then
          tst_rowpause_count<=(others=>'0');
          i_upp_rowpause<='0';
        else
          tst_rowpause_count<=tst_rowpause_count + 1;
        end if;

      else
        if tst_data_en='1' then

          if tst_pix_count=p_in_cfg_pix_count-1 then
           tst_pix_count<=(others=>'0');
              if tst_row_count=p_in_cfg_row_count-1 then
              tst_row_count<=(others=>'0');
                  if tst_vfr_count=usrcfg_fr_count-1 then
                    tst_row_count<=tst_row_count;
                    tst_pix_count<=tst_pix_count;
                    tst_vfr_count<=tst_vfr_count;
                    i_upp_wd_stop<='1';
                  else
                    tst_vfr_count<=tst_vfr_count + 1;
                    if tst_frpuase_count/=tst_mnl_fr_pause then
                      i_upp_frpause<='1';
                    end if;
                  end if;
              else
                tst_row_count<=tst_row_count+1;

                if tst_rowpause_count/=tst_mnl_row_pause then
                  i_upp_rowpause<='1';
                end if;
              end if;
          else
              tst_pix_count<=tst_pix_count+1;
          end if;--//if tst_pix_count=p_in_cfg_pix_count-1 then

          tst_data<=tst_data+8;
          tst_data_out(7 downto 0)  <=tst_data;
          tst_data_out(15 downto 8) <=tst_data+2;
          tst_data_out(23 downto 16)<=tst_data+4;
          tst_data_out(31 downto 24)<=tst_data+6;
        end if;--//if tst_data_en='0' then

      end if;--//if i_upp_wd_en='0' then

  end if;
end process;




--//Вывод результата в консоль ModelSim:
tst_dwnp_pix_max<=((usrcfg.ch.fr_size.activ.pix(14 downto 0)&'0'))  when usrcfg_zoom_up_on='1'  and usrcfg_zoom_size_x2='1' else

                  ((usrcfg.ch.fr_size.activ.pix(13 downto 0)&"00")) when usrcfg_zoom_up_on='1'  and usrcfg_zoom_size_x4='1' else

                  (('0'&usrcfg.ch.fr_size.activ.pix(15 downto 1)))  when usrcfg_zoom_dwn_on='1' and usrcfg_zoom_size_x2='1' else

                  (("00"&usrcfg.ch.fr_size.activ.pix(15 downto 2))) when usrcfg_zoom_dwn_on='1' and usrcfg_zoom_size_x4='1' else

                  (others=>'0');

tst_dwnp_row_max<=((usrcfg.ch.fr_size.activ.row(14 downto 0)&'0'))  when usrcfg_zoom_up_on='1'  and usrcfg_zoom_size_x2='1' else

                  ((usrcfg.ch.fr_size.activ.row(13 downto 0)&"00")) when usrcfg_zoom_up_on='1'  and usrcfg_zoom_size_x4='1' else

                  (('0'&usrcfg.ch.fr_size.activ.row(15 downto 1)))  when usrcfg_zoom_dwn_on='1' and usrcfg_zoom_size_x2='1' else

                  (("00"&usrcfg.ch.fr_size.activ.row(15 downto 2))) when usrcfg_zoom_dwn_on='1' and usrcfg_zoom_size_x4='1' else

                  (others=>'0');
process(p_in_rst,p_in_clk)
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
begin
  if p_in_rst='1' then
    tst_dwnp_pix<=(others=>'0');
    tst_dwnp_row<=(others=>'0');
    tst_dwnp_fr<=(others=>'0');
    tst_dwnp_dcount<=(others=>'0');
    tst_fr_read_done<='0';
    sr_tst_fr_read_done<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    sr_tst_fr_read_done<=tst_fr_read_done & sr_tst_fr_read_done(0 to 30);

    if p_out_vbufout_din_wd='1' and p_in_vbufout_full='0' then

        if tst_dwnp_pix=(tst_dwnp_pix'range=>'0') then
          write(GUI_line, string'("Result: Frame("));
          write(GUI_line, itoa(CONV_INTEGER(tst_dwnp_fr)));--//Выдаем число в DEC
          write(GUI_line, string'(")"));

          write(GUI_line, string'("Line("));
          write(GUI_line, itoa(CONV_INTEGER(tst_dwnp_row)));--//Выдаем число в DEC
          write(GUI_line, string'(") "));
        end if;

        write(GUI_line, itoa(CONV_INTEGER(p_out_vbufout_din(7 downto 0))) );--//Выдаем число в DEC
        write(GUI_line, string'(","));

        write(GUI_line, itoa(CONV_INTEGER(p_out_vbufout_din(15 downto 8))) );--//Выдаем число в DEC
        write(GUI_line, string'(","));

        write(GUI_line, itoa(CONV_INTEGER(p_out_vbufout_din(23 downto 16))) );--//Выдаем число в DEC
        write(GUI_line, string'(","));

        write(GUI_line, itoa(CONV_INTEGER(p_out_vbufout_din(31 downto 24))) );--//Выдаем число в DEC
        write(GUI_line, string'(","));

        if tst_dwnp_pix=(tst_dwnp_pix_max - EXT(tst_incr, tst_dwnp_pix'length)) then
          tst_dwnp_pix<=(others=>'0');
          writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim

          if tst_dwnp_row=(tst_dwnp_row_max - 1) then
            tst_dwnp_row<=(others=>'0');
            tst_dwnp_fr<=tst_dwnp_fr + 1;

            tst_fr_read_done<='1';
          else
            tst_dwnp_row<=tst_dwnp_row+1;
          end if;
        else
          tst_fr_read_done<='0';
          tst_dwnp_pix<=tst_dwnp_pix + EXT(tst_incr, tst_dwnp_pix'length);
        end if;

        tst_dwnp_dcount<=tst_dwnp_dcount + EXT(tst_incr, tst_dwnp_dcount'length);
    else
      tst_fr_read_done<='0';
    end if;

  end if;
end process;

tst_incr<=("00000000"&"0000"&'0'&(not usrcfg.ch.fr_color and not usrcfg.ch.fr_pcolor)&'0'&(usrcfg.ch.fr_color or usrcfg.ch.fr_pcolor));


--End Main
end;
