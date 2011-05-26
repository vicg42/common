-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : dsn_video_ctrl
--
-- Назначение/Описание :
--  Формирование/Запись/Чтение кадров видеоканалов
--
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - add 17.01.2011 16:00:49
--            изменил управление счетчиками i_vbuf_wr, а также теперь работаю с 4-мя видеобуферами для каждого канала
--            добавил регистр i_vbuf_rd - для модуля video_reader.vhd
--            добавил регистр i_vbuf_trc - для модуля dsn_track_nik.vhd
--            добавил входной порт p_in_trc_busy : in   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);--
-- Revision 0.03 - add 24.01.2011 16:48:50
--            поправил управление счетчиками i_vbuf_wr, добавил анализ условия
--            elsif p_in_trc_busy(i)='0' and i_vrd_hold_dly(i)='1' then
-- Revision 0.04 - add 03.02.2011 12:31:43
--            Доработал механизм выдачи ХОСТу статистики видеоканала:
--            маркер времени  +
--            кол-во кадров пропущеных в течении времени чтения видеоданных
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
use work.memory_ctrl_pkg.all;
use work.dsn_video_ctrl_pkg.all;

entity dsn_video_ctrl is
generic(
G_SIM : string:="OFF"
);
port
(
-------------------------------
-- Конфигурирование модуля dsn_video_ctrl.vhd (host_clk domain)
-------------------------------
p_in_host_clk         : in   std_logic;                      --//

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);   --//
p_in_cfg_adr_ld       : in   std_logic;                      --//
p_in_cfg_adr_fifo     : in   std_logic;                      --//

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);  --//
p_in_cfg_wd           : in   std_logic;                      --//

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);  --//
p_in_cfg_rd           : in   std_logic;                      --//

p_in_cfg_done         : in   std_logic;                      --//

-------------------------------
-- Связь с ХОСТ
-------------------------------
p_in_vctrl_hrdchsel   : in    std_logic_vector(3 downto 0);   --//Номер видео канала который будет читать ХОСТ
p_in_vctrl_hrdstart   : in    std_logic;                      --//Начало чтенения видеоканала
p_in_vctrl_hrddone    : in    std_logic;                      --//Подтверждение вычетки данных видеоканала
p_out_vctrl_hirq      : out   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);--//Готовность кадра соответствующего видеоканала
p_out_vctrl_hdrdy     : out   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);--//Прерываение соответствующего видеоканала(Кадр готов)
p_out_vctrl_hfrmrk    : out   std_logic_vector(31 downto 0);  --//

-------------------------------
-- STATUS модуля dsn_video_ctrl.vhd
-------------------------------
p_out_vctrl_modrdy    : out   std_logic;                      --//
p_out_vctrl_moderr    : out   std_logic;                      --//
p_out_vctrl_rd_done   : out   std_logic;                      --//

p_out_vctrl_vrdprm    : out   TReaderVCHParams;               --//Параметры видеоканалов
p_out_vctrl_vfrrdy    : out   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);--//Кадра готов для соответствующего видеоканала
p_out_vctrl_vrowmrk   : out   TVMrks;                         --//Маркер времени принятой строки

--//--------------------------
--//Связь с модулем слежения
--//--------------------------
p_in_trc_busy         : in    std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);--Захват бидеобуфера модулем слежения
p_out_trc_vbuf        : out   TVfrBufs;                       --//Номера видео буферов с готовыми кадрами

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_vbuf_clk        : out   std_logic;                      --//

p_in_vbufin_rdy       : in    std_logic;                      --//Связь в буфером входной видеоинформации
p_in_vbufin_dout      : in    std_logic_vector(31 downto 0);  --//
p_out_vbufin_dout_rd  : out   std_logic;                      --//
p_in_vbufin_empty     : in    std_logic;                      --//
p_in_vbufin_full      : in    std_logic;                      --//
p_in_vbufin_pfull     : in    std_logic;                      --//

p_out_vbufout_din     : out   std_logic_vector(31 downto 0);  --//Связь с буферов видео данных для ХОСТА
p_out_vbufout_din_wd  : out   std_logic;                      --//
p_in_vbufout_empty    : in    std_logic;                      --//
p_in_vbufout_full     : in    std_logic;                      --//

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
--//CH WRITE
p_out_memarb_wrreq    : out   std_logic;
p_in_memarb_wren      : in    std_logic;

p_out_memwr_bank1h    : out   std_logic_vector(15 downto 0);
p_out_memwr_ce        : out   std_logic;
p_out_memwr_cw        : out   std_logic;
p_out_memwr_rd        : out   std_logic;
p_out_memwr_wr        : out   std_logic;
p_out_memwr_term      : out   std_logic;
p_out_memwr_adr       : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_memwr_be        : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_memwr_din       : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_memwr_dout       : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_memwr_wf         : in    std_logic;
p_in_memwr_wpf        : in    std_logic;
p_in_memwr_re         : in    std_logic;
p_in_memwr_rpe        : in    std_logic;

--//CH READ
p_out_memarb_rdreq    : out   std_logic;
p_in_memarb_rden      : in    std_logic;

p_out_memrd_bank1h    : out   std_logic_vector(15 downto 0);
p_out_memrd_ce        : out   std_logic;
p_out_memrd_cw        : out   std_logic;
p_out_memrd_rd        : out   std_logic;
p_out_memrd_wr        : out   std_logic;
p_out_memrd_term      : out   std_logic;
p_out_memrd_adr       : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_memrd_be        : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_memrd_din       : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_memrd_dout       : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_memrd_wf         : in    std_logic;
p_in_memrd_wpf        : in    std_logic;
p_in_memrd_re         : in    std_logic;
p_in_memrd_rpe        : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end dsn_video_ctrl;

architecture behavioral of dsn_video_ctrl is


constant C_MEM_BANK_MSB_BIT   : integer:=pwr((C_DSN_VCTRL_REG_MEM_ADR_BANK_MSB_BIT-C_DSN_VCTRL_REG_MEM_ADR_BANK_LSB_BIT+1), 2)-1;


component video_writer
generic(
G_MEM_BANK_MSB_BIT   : integer:=29;
G_MEM_BANK_LSB_BIT   : integer:=28;

G_MEM_VCH_MSB_BIT    : integer:=25;
G_MEM_VCH_LSB_BIT    : integer:=24;
G_MEM_VFRAME_LSB_BIT : integer:=23;
G_MEM_VFRAME_MSB_BIT : integer:=23;
G_MEM_VROW_MSB_BIT   : integer:=22;
G_MEM_VROW_LSB_BIT   : integer:=12
);
port
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_load         : in    std_logic;
p_in_cfg_mem_trn_len  : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch      : in    TWriterVCHParams;
p_in_cfg_set_idle_vch : in    std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);

p_in_vfr_buf          : in    TVfrBufs;

--//Статусы
p_out_vfr_rdy         : out   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
p_out_vrow_mrk        : out   TVMrks;--

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data         : in    std_logic_vector(31 downto 0);
p_out_upp_data_rd     : out   std_logic;
p_in_upp_data_rdy     : in    std_logic;
p_in_upp_buf_empty    : in    std_logic;
p_in_upp_buf_full     : in    std_logic;
p_in_upp_buf_pfull    : in    std_logic;

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_memarb_req      : out   std_logic;
p_in_memarb_en        : in    std_logic;

p_out_mem_bank1h      : out   std_logic_vector(15 downto 0);
p_out_mem_ce          : out   std_logic;
p_out_mem_cw          : out   std_logic;
p_out_mem_rd          : out   std_logic;
p_out_mem_wr          : out   std_logic;
p_out_mem_term        : out   std_logic;
p_out_mem_adr         : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be          : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din         : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout         : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf           : in    std_logic;
p_in_mem_wpf          : in    std_logic;
p_in_mem_re           : in    std_logic;
p_in_mem_rpe          : in    std_logic;

p_out_mem_clk         : out   std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

component video_reader
generic(
G_MEM_BANK_MSB_BIT   : integer:=29;
G_MEM_BANK_LSB_BIT   : integer:=28;

G_MEM_VCH_MSB_BIT    : integer:=25;
G_MEM_VCH_LSB_BIT    : integer:=24;
G_MEM_VFRAME_LSB_BIT : integer:=23;
G_MEM_VFRAME_MSB_BIT : integer:=23;
G_MEM_VROW_MSB_BIT   : integer:=22;
G_MEM_VROW_LSB_BIT   : integer:=12
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
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_memarb_req     : out   std_logic;
p_in_memarb_en       : in    std_logic;

p_out_mem_bank1h     : out   std_logic_vector(15 downto 0);
p_out_mem_ce         : out   std_logic;
p_out_mem_cw         : out   std_logic;
p_out_mem_rd         : out   std_logic;
p_out_mem_wr         : out   std_logic;
p_out_mem_term       : out   std_logic;
p_out_mem_adr        : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be         : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din        : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout        : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf          : in    std_logic;
p_in_mem_wpf         : in    std_logic;
p_in_mem_re          : in    std_logic;
p_in_mem_rpe         : in    std_logic;

p_out_mem_clk        : out   std_logic;

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
G_SIM        : string :="OFF"
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

signal i_cfg_adr_cnt                     : std_logic_vector(7 downto 0);

signal h_reg_ctrl                        : std_logic_vector(C_DSN_VCTRL_REG_CTRL_LAST_BIT downto 0);
signal h_reg_tst0                        : std_logic_vector(C_DSN_VCTRL_REG_TST0_LAST_BIT downto 0);
signal h_reg_prm_data                    : std_logic_vector(31 downto 0);
signal h_ramcoe_num                      : std_logic_vector(C_DSN_VCTRL_REG_CTRL_RAMCOE_NUM_MSB_BIT-C_DSN_VCTRL_REG_CTRL_RAMCOE_NUM_LSB_BIT downto 0);

signal h_vprm_set                        : std_logic;
signal vclk_vprm_set                     : std_logic;
signal vclk_vprm_set_dly                 : std_logic_vector(1 downto 0);

signal h_set_idle_vch                    : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal vclk_set_idle_vch                 : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);

signal i_vprm                            : TVctrlParam;
signal i_wrprm_vch                       : TWriterVCHParams;
signal i_rdprm_vch                       : TReaderVCHParams;
signal i_trcprm_vch                      : TReaderVCHParams;

signal i_vtrc_hold                       : std_logic_vector(p_in_trc_busy'range);

type TArrayCntWidth is array (0 to C_DSN_VCTRL_VCH_MAX_COUNT-1) of std_logic_vector(3 downto 0);
signal i_vrd_irq_width_cnt               : TArrayCntWidth;
signal i_vrd_irq_width                   : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal i_vrd_irq                         : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal i_vrd_hold                        : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal tmp_vrd_hold                      : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal i_vrd_hold_dly                    : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal i_vrd_frmrk                       : TVMrks;
signal i_vrd_frmrk_out                   : std_logic_vector(31 downto 0);

signal i_vbuf_wr                         : TVfrBufs;
signal i_vbuf_rd                         : TVfrBufs;
signal i_vbuf_trc                        : TVfrBufs;

signal i_vwrite_vfr_rdy_out_dly          : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal i_vwrite_vfr_rdy_out              : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal i_vwrite_vrow_mrk                 : TVMrks;

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


signal tst_vwriter_out                   : std_logic_vector(31 downto 0);
signal tst_vreader_out                   : std_logic_vector(31 downto 0);
signal tst_ctrl                          : std_logic_vector(31 downto 0);

type TVfrSkipTst is array (0 to 3) of std_logic_vector(3 downto 0);
signal tst_vfrskip_rd                    : TVfrSkipTst;
signal tst_vfrskip_rd_out                : std_logic_vector(3 downto 0);
signal tst_vfrskip_rd_err                : std_logic_vector(3 downto 0);

--signal tst_vbufout_wd_cnt                : std_logic_vector(15 downto 0);
--signal tst_vbufout_din_wd                : std_logic;

signal tst_dbg_sobel                     : std_logic;
signal tst_dbg_pictire                   : std_logic;
signal tst_dbg_rd_hold                   : std_logic;
signal tst_dbg_trc_hold                  : std_logic;

--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(0)<=OR_reduce(tst_vfrskip_rd_err);-- or OR_reduce(tst_vbufout_wd_cnt); tst_vwriter_out(0) or

p_out_tst(4 downto 1)  <=tst_vwriter_out(4 downto 1);
p_out_tst(8 downto 5)  <=tst_vreader_out(3 downto 0);
p_out_tst(15 downto 9) <=(others=>'0');
p_out_tst(19 downto 16)<=tst_vfrskip_rd_out;--(others=>'0');
p_out_tst(31 downto 20)<=(others=>'0');

--p_out_vbufout_din_wd<=tst_vbufout_din_wd;
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    tst_vbufout_wd_cnt<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--    if i_vreader_rd_done='1' then
--      tst_vbufout_wd_cnt<=(others=>'0');
--    elsif tst_vbufout_din_wd='1' then
--      tst_vbufout_wd_cnt<=tst_vbufout_wd_cnt + 1;
--    end if;
--  end if;
--end process;


--//--------------------------------------------------
--//Конфигурирование модуля
--//--------------------------------------------------
--//Счетчик адреса регистров
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    i_cfg_adr_cnt<=(others=>'0');
  elsif p_in_host_clk'event and p_in_host_clk='1' then
    if p_in_cfg_adr_ld='1' then
      i_cfg_adr_cnt<=p_in_cfg_adr;
    else
      if p_in_cfg_adr_fifo='0' and (p_in_cfg_wd='1' or p_in_cfg_rd='1') then
        i_cfg_adr_cnt<=i_cfg_adr_cnt+1;
      end if;
    end if;
  end if;
end process;

--//Запись регистров
h_ramcoe_num<=h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_NUM_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_RAMCOE_NUM_LSB_BIT);

process(p_in_rst,p_in_host_clk)
  variable var_vch      : std_logic_vector(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT downto 0);
  variable var_vprm     : std_logic_vector(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT downto 0);
  variable var_vprm_set : std_logic;
  variable var_set_idle_vch: std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
begin
  if p_in_rst='1' then
    h_reg_ctrl<=(others=>'0');
    h_reg_tst0<=(others=>'0');
    h_reg_prm_data<=(others=>'0');
    var_vprm_set:='0';
    h_vprm_set<='0';

    var_vch :=(others=>'0');
    var_vprm:=(others=>'0');

    for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
        i_vprm.ch(i).mem_addr_wr<=(others=>'0');
        i_vprm.ch(i).mem_addr_rd<=(others=>'0');
        i_vprm.ch(i).fr_size.skip.pix<=(others=>'0');
        i_vprm.ch(i).fr_size.skip.row<=(others=>'0');
        i_vprm.ch(i).fr_size.activ.pix<=(others=>'0');
        i_vprm.ch(i).fr_size.activ.row<=(others=>'0');
        i_vprm.ch(i).fr_subsampling<=(others=>'0');
        i_vprm.ch(i).fr_mirror.pix<='0';
        i_vprm.ch(i).fr_mirror.row<='0';
        i_vprm.ch(i).fr_color_fst<=(others=>'0');
        i_vprm.ch(i).fr_pcolor    <='0';
        i_vprm.ch(i).fr_zoom      <=(others=>'0');
        i_vprm.ch(i).fr_zoom_type <='0';
        i_vprm.ch(i).fr_color     <='0';
    end loop;
    i_vprm.mem_wd_trn_len<=(others=>'0');
    i_vprm.mem_rd_trn_len<=(others=>'0');

    var_set_idle_vch:=(others=>'0');
    h_set_idle_vch<=(others=>'0');

  elsif p_in_host_clk'event and p_in_host_clk='1' then
    var_vprm_set:='0';
    var_set_idle_vch:=(others=>'0');

    if p_in_cfg_wd='1' then
      if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_CTRL_L, i_cfg_adr_cnt'length) then h_reg_ctrl<=p_in_cfg_txdata(h_reg_ctrl'high downto 0);
          var_vch :=p_in_cfg_txdata(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT);
          var_vprm:=p_in_cfg_txdata(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT);

            for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
              if i=var_vch then
                var_set_idle_vch(i) :=p_in_cfg_txdata(C_DSN_VCTRL_REG_CTRL_SET_IDLE_BIT);
              end if;
            end loop;

          if p_in_cfg_txdata(C_DSN_VCTRL_REG_CTRL_SET_BIT)='1' and
             p_in_cfg_txdata(C_DSN_VCTRL_REG_CTRL_RAMCOE_ADDR_BIT)='0' and p_in_cfg_txdata(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='0' then
            var_vprm_set:='1';

            for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
              if i=var_vch then
                --//Ищем индекс папаметра
                if var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_WR, var_vprm'length) then
                  i_vprm.ch(i).mem_addr_wr<=h_reg_prm_data(31 downto 0);

                elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_RD, var_vprm'length) then
                  i_vprm.ch(i).mem_addr_rd<=h_reg_prm_data(31 downto 0);

                elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_SKIP, var_vprm'length) then
                  i_vprm.ch(i).fr_size.skip.pix<=h_reg_prm_data(15 downto 0);
                  i_vprm.ch(i).fr_size.skip.row<=h_reg_prm_data(31 downto 16);

                elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_ACTIVE, var_vprm'length) then
                  i_vprm.ch(i).fr_size.activ.pix<=h_reg_prm_data(15 downto 0);
                  i_vprm.ch(i).fr_size.activ.row<=h_reg_prm_data(31 downto 16);

                elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_OPTIONS, var_vprm'length) then
                  i_vprm.ch(i).fr_subsampling<=h_reg_prm_data(3 downto 2);
                  i_vprm.ch(i).fr_mirror.pix<=h_reg_prm_data(4);
                  i_vprm.ch(i).fr_mirror.row<=h_reg_prm_data(5);
                  i_vprm.ch(i).fr_color_fst <=h_reg_prm_data(7 downto 6);
                  i_vprm.ch(i).fr_pcolor    <=h_reg_prm_data(8);
                  i_vprm.ch(i).fr_zoom      <=h_reg_prm_data(12 downto 9);
                  i_vprm.ch(i).fr_zoom_type <=h_reg_prm_data(13);
                  i_vprm.ch(i).fr_color     <=h_reg_prm_data(14);

                end if;
              end if;
            end loop;

          end if;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_TST0, i_cfg_adr_cnt'length) then h_reg_tst0<=p_in_cfg_txdata(h_reg_tst0'high downto 0);

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) then h_reg_prm_data(15 downto 0)  <=p_in_cfg_txdata;
      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_MSB, i_cfg_adr_cnt'length) then h_reg_prm_data(31 downto 16) <=p_in_cfg_txdata;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_MEM_TRN_LEN, i_cfg_adr_cnt'length) then
          var_vprm_set:='1';
          i_vprm.mem_wd_trn_len(7 downto 0)<=p_in_cfg_txdata(7 downto 0);
          i_vprm.mem_rd_trn_len(7 downto 0)<=p_in_cfg_txdata(15 downto 8);

      end if;
    end if;

    h_set_idle_vch<=var_set_idle_vch;
    h_vprm_set<=var_vprm_set;

  end if;
end process;

--//Чтение регистров
process(p_in_rst,p_in_host_clk)
  variable var_vch  : std_logic_vector(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT downto 0);
  variable var_vprm : std_logic_vector(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT downto 0);
begin
  if p_in_rst='1' then
    p_out_cfg_rxdata<=(others=>'0');

  elsif p_in_host_clk'event and p_in_host_clk='1' then

    if p_in_cfg_rd='1' then
      if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_CTRL_L, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=EXT(h_reg_ctrl, 16);

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_TST0, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=EXT(h_reg_tst0, 16);

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) then
          var_vch :=h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT);
          var_vprm:=h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT);

          if h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_ADDR_BIT)='0' and h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='0' then
              for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
                if i=var_vch then
                  --//Ищем индекс папаметра
                  if var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_WR, var_vprm'length) then
                    p_out_cfg_rxdata<=i_vprm.ch(i).mem_addr_wr(15 downto 0);

                  elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_RD, var_vprm'length) then
                    p_out_cfg_rxdata<=i_vprm.ch(i).mem_addr_rd(15 downto 0);

                  elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_SKIP, var_vprm'length) then
                    p_out_cfg_rxdata<=i_vprm.ch(i).fr_size.skip.pix(15 downto 0);

                  elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_ACTIVE, var_vprm'length) then
                    p_out_cfg_rxdata<=i_vprm.ch(i).fr_size.activ.pix(15 downto 0);

                  elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_OPTIONS, var_vprm'length) then
                    p_out_cfg_rxdata(3 downto 2) <=i_vprm.ch(i).fr_subsampling;
                    p_out_cfg_rxdata(4)          <=i_vprm.ch(i).fr_mirror.pix;
                    p_out_cfg_rxdata(5)          <=i_vprm.ch(i).fr_mirror.row;
                    p_out_cfg_rxdata(7 downto 6) <=i_vprm.ch(i).fr_color_fst;
                    p_out_cfg_rxdata(8)          <=i_vprm.ch(i).fr_pcolor;
                    p_out_cfg_rxdata(12 downto 9)<=i_vprm.ch(i).fr_zoom;
                    p_out_cfg_rxdata(13)         <=i_vprm.ch(i).fr_zoom_type;
                    p_out_cfg_rxdata(14)         <=i_vprm.ch(i).fr_color;
                    p_out_cfg_rxdata(15)         <='0';--(others=>'0');

                  end if;
                end if;
              end loop;

           elsif h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' then
           --//Чтение BRAM коэфициентов
                if i_vscale_coe_ram_en='1' then
                  p_out_cfg_rxdata<=i_vscale_coe_dout(15 downto 0);
                elsif i_vpcolor_coe_ramnum(2)='1' then
                  p_out_cfg_rxdata<=i_vpcolor_coe_dout(15 downto 0);
                elsif i_vgamma_coe_ramnum(2)='1' then
                  p_out_cfg_rxdata<=i_vgamma_coe_dout(15 downto 0);
                end if;
           end if;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_MSB, i_cfg_adr_cnt'length) then
          var_vch :=h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT);
          var_vprm:=h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT);

          if h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_ADDR_BIT)='0' and h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='0' then
              for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
                if i=var_vch then
                  --//Ищем индекс папаметра
                  if var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_WR, var_vprm'length) then
                    p_out_cfg_rxdata<=i_vprm.ch(i).mem_addr_wr(31 downto 16);

                  elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_RD, var_vprm'length) then
                    p_out_cfg_rxdata<=i_vprm.ch(i).mem_addr_rd(31 downto 16);

                  elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_SKIP, var_vprm'length) then
                    p_out_cfg_rxdata<=i_vprm.ch(i).fr_size.skip.row(15 downto 0);

                  elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_ACTIVE, var_vprm'length) then
                    p_out_cfg_rxdata<=i_vprm.ch(i).fr_size.activ.row(15 downto 0);

                  elsif var_vprm=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_OPTIONS, var_vprm'length) then
                    p_out_cfg_rxdata(15 downto 0)<=(others=>'0');

                  end if;
                end if;
              end loop;

           end if;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_MEM_TRN_LEN, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata(7 downto 0)<=i_vprm.mem_wd_trn_len(7 downto 0);
          p_out_cfg_rxdata(15 downto 8)<=i_vprm.mem_rd_trn_len(7 downto 0);
      end if;
    end if;

  end if;
end process;


tst_ctrl<=EXT(h_reg_tst0, tst_ctrl'length);
tst_dbg_pictire<=tst_ctrl(C_DSN_VCTRL_REG_TST0_DBG_PICTURE_BIT);
tst_dbg_sobel<=tst_ctrl(C_DSN_VCTRL_REG_TST0_DBG_SOBEL_BIT);

tst_dbg_rd_hold<=tst_ctrl(C_DSN_VCTRL_REG_TST0_DBG_RDHOLD_BIT);
tst_dbg_trc_hold<=tst_ctrl(C_DSN_VCTRL_REG_TST0_DBG_TRCHOLD_BIT);

--//Пересинхронизация
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    vclk_vprm_set_dly<=(others=>'0');
    vclk_vprm_set<='0';
    vclk_set_idle_vch<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    vclk_vprm_set_dly(0)<=h_vprm_set;
    vclk_vprm_set_dly(1)<=vclk_vprm_set_dly(0);
    vclk_vprm_set<=vclk_vprm_set_dly(0) and not vclk_vprm_set_dly(1);
    vclk_set_idle_vch<=h_set_idle_vch;
  end if;
end process;


--//Готовим параметры для модуля записи
gen_vwrprm : for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 generate
begin
i_wrprm_vch(i).mem_adr       <=i_vprm.ch(i).mem_addr_wr;
i_wrprm_vch(i).fr_size       <=i_vprm.ch(i).fr_size;
i_wrprm_vch(i).fr_subsampling<=i_vprm.ch(i).fr_subsampling;
end generate gen_vwrprm;

--//Готовим параметры для модуля чтения
gen_vrdprm : for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 generate
begin
i_rdprm_vch(i).mem_adr        <=i_vprm.ch(i).mem_addr_rd;--i_vprm.ch(i).mem_addr_wr;--
i_rdprm_vch(i).fr_size        <=i_vprm.ch(i).fr_size;
i_rdprm_vch(i).fr_subsampling <=i_vprm.ch(i).fr_subsampling;
i_rdprm_vch(i).fr_mirror      <=i_vprm.ch(i).fr_mirror;
i_rdprm_vch(i).fr_pcolor      <=i_vprm.ch(i).fr_pcolor;
i_rdprm_vch(i).fr_zoom        <=i_vprm.ch(i).fr_zoom;
i_rdprm_vch(i).fr_zoom_type   <=i_vprm.ch(i).fr_zoom_type;
i_rdprm_vch(i).fr_color       <=i_vprm.ch(i).fr_color;
i_rdprm_vch(i).fr_color_fst   <=i_vprm.ch(i).fr_color_fst;
end generate gen_vrdprm;


p_out_vbuf_clk     <= p_in_clk;


--//--------------------------
--//Связь с модулем слежения
--//--------------------------
--//Готовим параметры видео каналов для модуля слежения
gen_trcprm : for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 generate
begin
i_trcprm_vch(i).mem_adr        <=i_vprm.ch(i).mem_addr_wr;
i_trcprm_vch(i).fr_size        <=i_vprm.ch(i).fr_size;
i_trcprm_vch(i).fr_subsampling <=i_vprm.ch(i).fr_subsampling;
i_trcprm_vch(i).fr_mirror      <=i_vprm.ch(i).fr_mirror;
i_trcprm_vch(i).fr_pcolor      <=i_vprm.ch(i).fr_pcolor;
i_trcprm_vch(i).fr_zoom        <=i_vprm.ch(i).fr_zoom;
i_trcprm_vch(i).fr_zoom_type   <=i_vprm.ch(i).fr_zoom_type;
i_trcprm_vch(i).fr_color       <=i_vprm.ch(i).fr_color;
i_trcprm_vch(i).fr_color_fst   <=i_vprm.ch(i).fr_color_fst;
end generate gen_trcprm;

p_out_vctrl_vrdprm <= i_trcprm_vch;
p_out_vctrl_vfrrdy <= i_vwrite_vfr_rdy_out(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
p_out_vctrl_vrowmrk <= i_vwrite_vrow_mrk;

p_out_trc_vbuf <= i_vbuf_trc;

--//--------------------------------------------------
--//Статусы модуля
--//--------------------------------------------------
p_out_vctrl_modrdy <= not p_in_rst;
p_out_vctrl_moderr <= '0';
p_out_vctrl_hirq <= i_vrd_irq_width(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
p_out_vctrl_hdrdy <= i_vrd_hold(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
p_out_vctrl_hfrmrk <= i_vrd_frmrk_out;

p_out_vctrl_rd_done <= i_vreader_rd_done;

--//Растягиваем импульcы генерации прерываний чтения видеоканалов
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to C_DSN_VCTRL_VCH_MAX_COUNT-1 loop
      i_vrd_irq_width_cnt(i)<=(others=>'0');
    end loop;
    i_vrd_irq_width<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
        if i_vrd_irq(i)='1' then
          i_vrd_irq_width(i)<='1';
        elsif i_vrd_irq_width_cnt(i)(3)='1' then
          i_vrd_irq_width(i)<='0';
        end if;

        if i_vrd_irq_width(i)='0' then
          i_vrd_irq_width_cnt(i)<=(others=>'0');
        else
          i_vrd_irq_width_cnt(i)<=i_vrd_irq_width_cnt(i)+1;
        end if;
    end loop;
  end if;
end process;


--//--------------------------------------------------
--//Управление видео буферами
--//--------------------------------------------------
--//Запись Видео

--//Варианты захвата видеобуфера:
--//x, 0, 0, 0, x, 0, 0, x, 0, x
--//1, x, 1, 1, x, x, 1, 1, x, 1
--//2, 2, x, 2, 2, x, x, x, 2, 2
--//3, 3, 3, x, 3, 3, x, 3, x, x

--//где 0,1,2,3 - индексы свободных видеобуферов соответствующего видеоканала
--//    x - видеобуфер захваченый модулем чтения видео(video_reader.vhd) или слежения

gen_vhold : for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 generate
begin
i_vtrc_hold(i)<=p_in_trc_busy(i) or tst_dbg_trc_hold;
tmp_vrd_hold(i)<=i_vrd_hold(i) or tst_dbg_rd_hold;
end generate gen_vhold;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    for i in 0 to C_DSN_VCTRL_VCH_MAX_COUNT-1 loop
      i_vbuf_wr(i)<=(others=>'0');
    end loop;
    i_vwrite_vfr_rdy_out_dly<=(others=>'0');
    i_vrd_hold_dly<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    i_vwrite_vfr_rdy_out_dly<=i_vwrite_vfr_rdy_out;
    i_vrd_hold_dly<=tmp_vrd_hold;

    for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop

        --//Назначаем видеобуфер для записи видео
        if i_vwrite_vfr_rdy_out_dly(i)='1' then
          if tst_dbg_pictire='1' then
            i_vbuf_wr(i)<=(others=>'0');
          else

            --//Если Модуль слежения заватил видеобуфер - ДА +
            --//     Модуль Чтения Видео заватил видеобуфер - ДА, то ...
            if i_vtrc_hold(i)='1' and i_vrd_hold_dly(i)='1' then
                --//--------------
                if    i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_rd(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length);

                elsif i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_rd(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length);

                elsif i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_rd(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length);

                elsif i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_rd(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length);

                --//--------------
                elsif ((i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_rd(i)'length)) or
                       (i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_rd(i)'length))) then

                       if    i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length);
                       elsif i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length);
                       else
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length);
                       end if;

                --//
                elsif ((i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_rd(i)'length)) or
                       (i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_rd(i)'length))) then

                       if    i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length);
                       elsif i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length);
                       else
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length);
                       end if;

                --//
                elsif ((i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_rd(i)'length)) or
                       (i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_rd(i)'length))) then

                       if    i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length);
                       elsif i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length);
                       else
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length);
                       end if;

                --//--------------
                elsif ((i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_rd(i)'length)) or
                       (i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_rd(i)'length))) then

                       if    i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length);
                       elsif i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length);
                       else
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length);
                       end if;

                --//
                elsif ((i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_rd(i)'length)) or
                       (i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_rd(i)'length))) then

                       if    i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length);
                       elsif i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length);
                       else
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length);
                       end if;

                --//
                elsif ((i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_rd(i)'length)) or
                       (i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_trc(i)'length) and i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_rd(i)'length))) then

                       if    i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length);
                       elsif i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length) then
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length);
                       else
                          i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length);
                       end if;
                end if;

            --//Если Модуль Слежения заватил видеобуфер - ДА +
            --//     Модуль Чтения Видео заватил видеобуфер - НЕТ, то ...
            elsif i_vtrc_hold(i)='1' and i_vrd_hold_dly(i)='0' then
                if    i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_trc(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length);

                elsif i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_trc(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length);

                elsif i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_trc(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length);

                elsif i_vbuf_trc(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_trc(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length);

                else
                  i_vbuf_wr(i)<=i_vbuf_wr(i)+1;
                end if;

            --//Если Модуль Слежения заватил видеобуфер - НЕТ +
            --//     Модуль Чтения Видео заватил видеобуфер - ДА, то ...
            elsif i_vtrc_hold(i)='0' and i_vrd_hold_dly(i)='1' then
                if    i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_rd(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length);

                elsif i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_rd(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length);

                elsif i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_rd(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(1, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(3, i_vbuf_wr(i)'length);

                elsif i_vbuf_rd(i)=CONV_STD_LOGIC_VECTOR(3, i_vbuf_rd(i)'length) and
                      i_vbuf_wr(i)=CONV_STD_LOGIC_VECTOR(2, i_vbuf_wr(i)'length) then
                  i_vbuf_wr(i)<=CONV_STD_LOGIC_VECTOR(0, i_vbuf_wr(i)'length);

                else
                  i_vbuf_wr(i)<=i_vbuf_wr(i)+1;
                end if;

            --//Если Модуль Слежения заватил видеобуфер - НЕТ +
            --//     Модуль Чтения Видео заватил видеобуфер - НЕТ, то ...
            elsif i_vtrc_hold(i)='0' and i_vrd_hold_dly(i)='0' then
              i_vbuf_wr(i)<=i_vbuf_wr(i)+1;

            end if;
          end if;
        end if;

    end loop;--//for

  end if;
end process;

--//Чтение Видео
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to C_DSN_VCTRL_VCH_MAX_COUNT-1 loop
      i_vrd_frmrk(i)<=(others=>'0');
      i_vbuf_rd(i)<=(others=>'0');
      tst_vfrskip_rd(i)<=(others=>'0');
      tst_vfrskip_rd_err(i)<='0';
    end loop;
    i_vrd_hold<=(others=>'0');
    i_vrd_irq<=(others=>'0');
    i_vrd_frmrk_out<=(others=>'0');
    tst_vfrskip_rd_out<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop

        --//Выдаем номер видеобуфера модулю чтение видео video_reader.vhd
        if i_vwrite_vfr_rdy_out(i)='1' then
            if tst_dbg_pictire='1' then
              i_vbuf_rd(i)<=CONV_STD_LOGIC_VECTOR(1, i_vbuf_rd(i)'length);
            elsif i_vrd_hold(i)='0' then
              i_vbuf_rd(i)<=i_vbuf_wr(i);
            end if;
        end if;

        --//Захват видеобуфера для Чтения ХОСТОМ
        if i_vwrite_vfr_rdy_out(i)='1' then
          i_vrd_hold(i)<='1';
        elsif (i_vreader_vch_num_out=i and i_vreader_rd_done='1') or vclk_set_idle_vch(i)='1' then
          i_vrd_hold(i)<='0';
        end if;

        --//Прерываение - Можно вычитывать кадр
        i_vrd_irq(i)<=i_vwrite_vfr_rdy_out(i) and not i_vrd_hold(i);


        --//Защелкиваем маркер текущего кадра для выдачи ХОСТУ
        if i_vwrite_vfr_rdy_out(i)='1' then
          i_vrd_frmrk(i)<=i_vwrite_vrow_mrk(i);
        end if;

        --//Подсчет пропущеных кадров в течении чтения данных ХОСТОМ
        if i_vrd_hold(i)='1' then
          if i_vwrite_vfr_rdy_out(i)='1' then
            if tst_vfrskip_rd(i)=(tst_vfrskip_rd(i)'range =>'1') then
              tst_vfrskip_rd(i)<=(others=>'1');
            else
              tst_vfrskip_rd(i)<=tst_vfrskip_rd(i)+1;
            end if;
          end if;
        else
          tst_vfrskip_rd(i)<=(others=>'0');
        end if;
        tst_vfrskip_rd_err(i)<=OR_reduce(tst_vfrskip_rd(i));

        --//add 03.02.2011 12:31:43
        --//Выдаем ХОСТУ статистику текущего видеоканала:
        if i_vreader_vch_num_out=i then
          tst_vfrskip_rd_out<=tst_vfrskip_rd(i);--//Кол-во пропущеных кадров
          i_vrd_frmrk_out<=i_vrd_frmrk(i);      --//Маркер времени
        end if;

    end loop;--//for

  end if;
end process;

--//Модуль Слежения
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to C_DSN_VCTRL_VCH_MAX_COUNT-1 loop
      i_vbuf_trc(i)<=(others=>'0');
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then

    for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
        --//Выдаем модулю слежения номер видеобуфера доступного для чтения
        if i_vwrite_vfr_rdy_out(i)='1' then
            if tst_dbg_pictire='1' then
              i_vbuf_trc(i)<=CONV_STD_LOGIC_VECTOR(1, i_vbuf_trc(i)'length);
            elsif i_vtrc_hold(i)='0' then
              i_vbuf_trc(i)<=i_vbuf_wr(i);
            end if;
        end if;

    end loop;--//for

  end if;
end process;



-------------------------------
-- Запись видео информации в ОЗУ
-------------------------------
m_video_writer : video_writer
generic map(
G_MEM_BANK_MSB_BIT   => C_DSN_VCTRL_REG_MEM_ADR_BANK_MSB_BIT,
G_MEM_BANK_LSB_BIT   => C_DSN_VCTRL_REG_MEM_ADR_BANK_LSB_BIT,

G_MEM_VCH_MSB_BIT    => C_DSN_VCTRL_MEM_VCH_MSB_BIT,
G_MEM_VCH_LSB_BIT    => C_DSN_VCTRL_MEM_VCH_LSB_BIT,
G_MEM_VFRAME_LSB_BIT => C_DSN_VCTRL_MEM_VFRAME_LSB_BIT,
G_MEM_VFRAME_MSB_BIT => C_DSN_VCTRL_MEM_VFRAME_MSB_BIT,
G_MEM_VROW_MSB_BIT   => C_DSN_VCTRL_MEM_VLINE_MSB_BIT,
G_MEM_VROW_LSB_BIT   => C_DSN_VCTRL_MEM_VLINE_LSB_BIT
)
port map
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_load         => vclk_vprm_set,
p_in_cfg_mem_trn_len  => i_vprm.mem_wd_trn_len,
p_in_cfg_prm_vch      => i_wrprm_vch,
p_in_cfg_set_idle_vch => vclk_set_idle_vch,

p_in_vfr_buf          => i_vbuf_wr,

--//Статусы
p_out_vfr_rdy         => i_vwrite_vfr_rdy_out,
p_out_vrow_mrk        => i_vwrite_vrow_mrk,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data         => p_in_vbufin_dout,
p_out_upp_data_rd     => p_out_vbufin_dout_rd,
p_in_upp_data_rdy     => p_in_vbufin_rdy,
p_in_upp_buf_empty    => p_in_vbufin_empty,
p_in_upp_buf_full     => p_in_vbufin_full,
p_in_upp_buf_pfull    => p_in_vbufin_pfull,

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_mem_clk         => open,

p_out_memarb_req      => p_out_memarb_wrreq,
p_in_memarb_en        => p_in_memarb_wren,

p_out_mem_bank1h      => p_out_memwr_bank1h,
p_out_mem_ce          => p_out_memwr_ce,
p_out_mem_cw          => p_out_memwr_cw,
p_out_mem_rd          => p_out_memwr_rd,
p_out_mem_wr          => p_out_memwr_wr,
p_out_mem_term        => p_out_memwr_term,
p_out_mem_adr         => p_out_memwr_adr,
p_out_mem_be          => p_out_memwr_be,
p_out_mem_din         => p_out_memwr_din,
p_in_mem_dout         => "00000000000000000000000000000000",

p_in_mem_wf           => p_in_memwr_wf,
p_in_mem_wpf          => p_in_memwr_wpf,
p_in_mem_re           => p_in_memwr_re,
p_in_mem_rpe          => p_in_memwr_rpe,

-------------------------------
--Технологический
-------------------------------
p_in_tst              => "00000000000000000000000000000000",
p_out_tst             => tst_vwriter_out,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => p_in_rst
);


--//-----------------------------
--//Модуль чтение видео информации из ОЗУ
--//-----------------------------
m_video_reader : video_reader
generic map(
G_MEM_BANK_MSB_BIT   => C_DSN_VCTRL_REG_MEM_ADR_BANK_MSB_BIT,
G_MEM_BANK_LSB_BIT   => C_DSN_VCTRL_REG_MEM_ADR_BANK_LSB_BIT,

G_MEM_VCH_MSB_BIT    => C_DSN_VCTRL_MEM_VCH_MSB_BIT,
G_MEM_VCH_LSB_BIT    => C_DSN_VCTRL_MEM_VCH_LSB_BIT,
G_MEM_VFRAME_LSB_BIT => C_DSN_VCTRL_MEM_VFRAME_LSB_BIT,
G_MEM_VFRAME_MSB_BIT => C_DSN_VCTRL_MEM_VFRAME_MSB_BIT,
G_MEM_VROW_MSB_BIT   => C_DSN_VCTRL_MEM_VLINE_MSB_BIT,
G_MEM_VROW_LSB_BIT   => C_DSN_VCTRL_MEM_VLINE_LSB_BIT
)
port map
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len  => i_vprm.mem_rd_trn_len,
p_in_cfg_prm_vch      => i_rdprm_vch,

p_in_hrd_chsel        => p_in_vctrl_hrdchsel,
p_in_hrd_start        => p_in_vctrl_hrdstart,
p_in_hrd_done         => p_in_vctrl_hrddone,

p_in_vfr_buf          => i_vbuf_rd,
p_in_vfr_nrow         => i_vreader_rq_next_line,

--//Статусы
p_out_vch_fr_new      => i_vreader_fr_new,
p_out_vch_rd_done     => i_vreader_rd_done,
p_out_vch             => i_vreader_vch_num_out,
p_out_vch_color_fst   => i_vreader_color_fst_out,
p_out_vch_color       => i_vreader_color_out,
p_out_vch_pcolor      => i_vreader_pcolor_out,
p_out_vch_active_pix  => i_vreader_active_pix_out,
p_out_vch_active_row  => i_vreader_active_row_out,
p_out_vch_zoom        => i_vreader_zoom_out,
p_out_vch_zoom_type   => i_vreader_zoom_type_out,
p_out_vch_mirx        => i_vreader_mirx_out,

--//--------------------------
--//Upstream Port
--//--------------------------
p_out_upp_data        => i_vreader_dout,
p_out_upp_data_wd     => i_vreader_dout_en,
p_in_upp_buf_empty    => '0',
p_in_upp_buf_full     => i_vmir_rdy_n,

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_mem_clk         => open,

p_out_memarb_req      => p_out_memarb_rdreq,
p_in_memarb_en        => p_in_memarb_rden,

p_out_mem_bank1h      => p_out_memrd_bank1h,
p_out_mem_ce          => p_out_memrd_ce,
p_out_mem_cw          => p_out_memrd_cw,
p_out_mem_rd          => p_out_memrd_rd,
p_out_mem_wr          => p_out_memrd_wr,
p_out_mem_term        => p_out_memrd_term,
p_out_mem_adr         => p_out_memrd_adr,
p_out_mem_be          => p_out_memrd_be,
p_out_mem_din         => p_out_memrd_din,
p_in_mem_dout         => p_in_memrd_dout,

p_in_mem_wf           => p_in_memrd_wf,
p_in_mem_wpf          => p_in_memrd_wpf,
p_in_mem_re           => p_in_memrd_re,
p_in_mem_rpe          => p_in_memrd_rpe,

-------------------------------
--Технологический
-------------------------------
p_in_tst              => tst_ctrl(31 downto 0),--"00000000000000000000000000000000",
p_out_tst             => tst_vreader_out,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => p_in_rst
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
p_in_cfg_bypass     => i_vcoldemasc_bypass,
p_in_cfg_colorfst   => i_vreader_color_fst_out,
p_in_cfg_pix_count  => i_vreader_active_pix_out,
p_in_cfg_row_count  => i_vreader_active_row_out,
p_in_cfg_init       => i_vreader_fr_new,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data       => i_vmir_dout,
p_in_upp_wd         => i_vmir_dout_en,
p_out_upp_rdy_n     => i_vcoldemasc_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data     => i_vcoldemasc_dout,
p_out_dwnp_wd       => i_vcoldemasc_dout_en,
p_in_dwnp_rdy_n     => i_vscale_rdy_n,

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
--//Модуль масштабирования изображения
--//-----------------------------
--//Доступ к BRAM коэфициентов
i_vscale_coe_adr   <=p_in_cfg_txdata(i_vscale_coe_adr'high downto 0);
i_vscale_coe_adr_ld<=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) and
                                      h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_ADDR_BIT)='1' and
                                      h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_SET_BIT)='1' and
                                      i_vscale_coe_ram_en='1' else '0';

i_vscale_coe_din<=p_in_cfg_txdata;
i_vscale_coe_wr <=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) and
                                   h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                   h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_SET_BIT)='1' and
                                   i_vscale_coe_ram_en='1' else '0';

i_vscale_coe_rd <=p_in_cfg_rd or p_in_cfg_adr_ld when p_in_cfg_adr=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) and
                                                      h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                                      h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_SET_BIT)='0' and
                                                      i_vscale_coe_ram_en='1' else '0';

i_vscale_coe_ram_en<='1' when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_CTRL_RAMCOE_SCALE_NUM, h_ramcoe_num'length) else '0';

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
p_in_cfg_pix_count  => i_vscale_pix_count,
p_in_cfg_row_count  => i_vscale_row_count,
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
i_vpcolor_coe_adr_ld<=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) and
                                       h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_ADDR_BIT)='1' and
                                       h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_SET_BIT)='1' and
                                       i_vpcolor_coe_ramnum(2)='1' else '0';

i_vpcolor_coe_din<=p_in_cfg_txdata(15 downto 0);
i_vpcolor_coe_wr <=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) and
                                    h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                    h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_SET_BIT)='1' and
                                    i_vpcolor_coe_ramnum(2)='1' else '0';

i_vpcolor_coe_rd <=p_in_cfg_rd or p_in_cfg_adr_ld when p_in_cfg_adr=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) and
                                                       h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                                       h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_SET_BIT)='0' and
                                                       i_vpcolor_coe_ramnum(2)='1' else '0';

i_vpcolor_coe_ramnum<="100" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_CTRL_RAMCOE_P_COLR_NUM, h_ramcoe_num'length) else
                      "101" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_CTRL_RAMCOE_P_COLG_NUM, h_ramcoe_num'length) else
                      "110" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_CTRL_RAMCOE_P_COLB_NUM, h_ramcoe_num'length) else
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
p_in_dwnp_rdy_n     => i_vgamma_rdy_n,

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
--//Модуль Gamma коррекции.
--//-----------------------------
i_vgamma_color<=i_vreader_color_out or i_vreader_pcolor_out;

--//Доступ к BRAM коэфициентов
i_vgamma_coe_adr   <=p_in_cfg_txdata(i_vgamma_coe_adr'high downto 0);
i_vgamma_coe_adr_ld<=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) and
                                      h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_ADDR_BIT)='1' and
                                      h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_SET_BIT)='1' and
                                      i_vgamma_coe_ramnum(2)='1' else '0';

i_vgamma_coe_din<=p_in_cfg_txdata(15 downto 0);
i_vgamma_coe_wr <=p_in_cfg_wd when i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) and
                                   h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                   h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_SET_BIT)='1' and
                                   i_vgamma_coe_ramnum(2)='1' else '0';

i_vgamma_coe_rd <=p_in_cfg_rd or p_in_cfg_adr_ld when p_in_cfg_adr=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_PRM_DATA_LSB, i_cfg_adr_cnt'length) and
                                                      h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT)='1' and
                                                      h_reg_ctrl(C_DSN_VCTRL_REG_CTRL_SET_BIT)='0' and
                                                      i_vgamma_coe_ramnum(2)='1' else '0';

i_vgamma_coe_ramnum<="100" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_GRAY_NUM, h_ramcoe_num'length) else
                     "101" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_COLR_NUM, h_ramcoe_num'length) else
                     "110" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_COLG_NUM, h_ramcoe_num'length) else
                     "111" when h_ramcoe_num=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_COLB_NUM, h_ramcoe_num'length) else
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
p_out_dwnp_data     => p_out_vbufout_din,
p_out_dwnp_wd       => p_out_vbufout_din_wd,--tst_vbufout_din_wd,--
p_in_dwnp_rdy_n     => p_in_vbufout_full,

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


--END MAIN
end behavioral;

