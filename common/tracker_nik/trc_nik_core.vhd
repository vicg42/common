-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 20.11.2010 17:41:56
-- Module Name : trc_nik_core
--
-- Назначение/Описание :
--  Модуль реализует обсчет одной элементарной строки(ЭС) Никифорова
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Переделка заполнения выходного буфера Контурных точек.
--                 Теперь счетчики КТ будут хрониться отдельно от массива КТ
--                 Массив КТ :
--                 ЭС(0)                                                               |ЭС(1)..
--                 ЭБ(0)                           |ЭБ(1)                           |..|ЭБ(m)..
--                 ИП(0)    |ИП(1)    |..|ИП(n)    |ИП(0)    |ИП(1)    |..|ИП(n)    |..|ИП(0)..
--                 ..КТ,КТ..|..КТ,КТ..|..|..КТ,КТ..|..КТ,КТ..|..КТ,КТ..|..|..КТ,КТ..|..|..КТ,КТ..
-- Revision 1.00 - Корректировка модуля с учетом изменений реализации vsobel.vhd - Revision 3.00
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
use work.prj_def.all;
use work.dsn_video_ctrl_pkg.all;
use work.dsn_track_nik_pkg.all;

entity trc_nik_core is
generic(
G_SIM : string:="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_prm_trc         : in    TTrcNikParam;    --//Параметры слежения
p_in_prm_vch         : in    TReaderVCHParam; --//Параметры видеоканала

p_in_ctrl            : in    std_logic_vector(CNIK_TRCCORE_CTRL_LAST_BIT downto 0); --//Управление
p_out_status         : out   std_logic_vector(CNIK_TRCCORE_STAT_LAST_BIT downto 0);
p_out_hbuf_dsize     : out   std_logic_vector(15 downto 0);--//Общее кол-во данных которые нужно передать в ОЗУ (в DW)
p_out_ebout          : out   TTrcNikEBOs;                  --//Счетчики данных ЭБ

--//--------------------------
--//
--//--------------------------
p_in_mem_dout        : in    std_logic_vector(31 downto 0); --//
p_in_mem_dout_en     : in    std_logic;                     --//
p_out_mem_dout_rdy_n : out   std_logic;                     --//Модуль готов к приему данных с p_in_mem_dout

p_out_mem_din        : out   std_logic_vector(31 downto 0); --//
p_in_mem_din_en      : in    std_logic;                     --//
p_out_mem_din_rdy_n  : out   std_logic;                     --//У Модуля есть данные для выдачи в p_out_mem_din

--//--------------------------
--//Запись данных в буфер ХОСТА
--//--------------------------
p_out_hirq           : out   std_logic;                     --//

p_out_hbuf_din       : out   std_logic_vector(31 downto 0); --//
p_out_hbuf_wr        : out   std_logic;                     --//
p_in_hbuf_wrrdy_n    : in    std_logic;                     --//
p_in_hbuf_empty      : in    std_logic;                     --//Статус Буфера

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
end trc_nik_core;

architecture behavioral of trc_nik_core is

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

component vsobel_main
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
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);
p_in_cfg_row_count : in    std_logic_vector(15 downto 0);
p_in_cfg_ctrl      : in    std_logic_vector(1 downto 0);
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
p_in_dwnp_rdy_n    : in    std_logic;
p_out_dwnp_wd      : out   std_logic;
p_out_dwnp_data    : out   std_logic_vector(31 downto 0);

p_out_dwnp_grad    : out   std_logic_vector(31 downto 0);

p_out_dwnp_dxm     : out   std_logic_vector((8*4)-1 downto 0);
p_out_dwnp_dym     : out   std_logic_vector((8*4)-1 downto 0);

p_out_dwnp_dxs     : out   std_logic_vector((11*4)-1 downto 0);
p_out_dwnp_dys     : out   std_logic_vector((11*4)-1 downto 0);

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

component trc_nik_grado
generic(
G_USE_WDATIN : integer:=32;
G_SIM        : string :="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_ctrl        : in    std_logic_vector(1 downto 0);

--//--------------------------
--//Upstream Port (входные данные)
--//--------------------------
p_in_upp_dxm     : in    std_logic_vector((8*4)-1 downto 0);
p_in_upp_dym     : in    std_logic_vector((8*4)-1 downto 0);

p_in_upp_dxs     : in    std_logic_vector((11*4)-1 downto 0);
p_in_upp_dys     : in    std_logic_vector((11*4)-1 downto 0);

p_in_upp_grad    : in    std_logic_vector((8*4)-1 downto 0);
p_in_upp_data    : in    std_logic_vector((8*4)-1 downto 0);

p_in_upp_wd      : in    std_logic;
p_out_upp_rdy_n  : out   std_logic;

--//--------------------------
--//Downstream Port (результат)
--//--------------------------
p_out_dwnp_data  : out   std_logic_vector((8*4)-1 downto 0);
p_out_dwnp_grada : out   std_logic_vector((8*4)-1 downto 0);
p_out_dwnp_grado : out   std_logic_vector((8*4)-1 downto 0);

p_out_dwnp_wd    : out   std_logic;
p_in_dwnp_rdy_n  : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end component;

component trc_nik_vbuf
port (
addra : in   std_logic_vector(9 downto 0);
dina  : in   std_logic_vector(23 downto 0);
douta : out  std_logic_vector(23 downto 0);
ena   : in   std_logic;
wea   : in   std_logic_vector(0 downto 0);
clka  : in   std_logic;
rsta  : in   std_logic;

addrb : in   std_logic_vector(9 downto 0);
dinb  : in   std_logic_vector(23 downto 0);
doutb : out  std_logic_vector(23 downto 0);
enb   : in   std_logic;
web   : in   std_logic_vector(0 downto 0);
clkb  : in   std_logic;
rstb  : in   std_logic
);
end component;


signal i_vmirx_done                  : std_logic;
signal i_vmir_dout                   : std_logic_vector(31 downto 0);
signal i_vmir_dout_en                : std_logic;
--signal i_vmir_rdy_n                  : std_logic;
--signal i_vmir_din                    : std_logic_vector(31 downto 0);
--signal i_vmir_din_en                 : std_logic;

signal i_vcoldemasc_bypass           : std_logic;
signal i_vcoldemasc_rdy_n            : std_logic;
signal i_vcoldemasc_dout             : std_logic_vector(127 downto 0);
signal i_vcoldemasc_dout_en          : std_logic;

signal i_vsobel_ctrl                 : std_logic_vector(1 downto 0);
signal i_vsobel_dxs_out              : std_logic_vector((11*4)-1 downto 0);
signal i_vsobel_dys_out              : std_logic_vector((11*4)-1 downto 0);
signal i_vsobel_dxm_out              : std_logic_vector((8*4)-1 downto 0);
signal i_vsobel_dym_out              : std_logic_vector((8*4)-1 downto 0);
signal i_vsobel_grad_out             : std_logic_vector((8*4)-1 downto 0);
signal i_vsobel_dout                 : std_logic_vector((8*4)-1 downto 0);
signal i_vsobel_dout_en              : std_logic;
signal i_vsobel_rdy_n                : std_logic;

signal i_val_rdy_n                   : std_logic;
signal i_val_grada_out               : std_logic_vector((8*4)-1 downto 0);
signal i_val_pix_out                 : std_logic_vector((8*4)-1 downto 0);
signal i_val_grado_out               : std_logic_vector((8*4)-1 downto 0);
signal i_val_en_out                  : std_logic;

type fsmvbuf_state is
(
S_TRC_IDLE,
S_TRC_WVBUF,
S_TRC_IP_SET,
S_TRC_IP_CHK,
S_TRC_RVBUF,
S_TRC_DLY0,
S_TRC_DLY1,
S_TRC_EXIT_CHK,
S_TRC_EBOUT_CHK
);
signal fsmvbuf_cstate: fsmvbuf_state;

signal i_vbufrow_adr                 : std_logic_vector(15 downto 0);
--signal i_vbufrow_wd                  : std_logic;
signal i_vbufrow_rd                  : std_logic;
signal i_vbufrow_rd_dly              : std_logic;

signal i_vbufrow_adra                : std_logic_vector(9 downto 0);
Type TVBufsDA is array (0 to CNIK_EBKT_LENY-1) of std_logic_vector(23 downto 0);
signal i_vbufrow_dina                : TVBufsDA;
--signal i_vbufrow_douta               : TVBufsDA;
signal i_vbufrow_ena                 : std_logic_vector(0 to 3);

signal i_vbufrow_adrb                : std_logic_vector(9 downto 0);
Type TVBufsDB is array (0 to CNIK_EBKT_LENY-1) of std_logic_vector(23 downto 0);
signal i_vbufrow_dinb                : TVBufsDB;
signal i_vbufrow_doutb               : TVBufsDB;
signal i_vbufrow_enb                 : std_logic_vector(0 to 3);

signal i_vfr_row_cnt                 : std_logic_vector(p_in_prm_vch.fr_size.activ.row'range);

signal i_trccore_start               : std_logic;
signal i_trccore_fr_new              : std_logic;
signal i_trccore_memwd_done          : std_logic;
signal i_trccore_done                : std_logic;

signal i_nik_ktedge                  : std_logic;
signal i_nik_kt                      : TTrcNikKT;
signal i_nik_dout                    : TTrcNikDouts;
signal i_nik_dout_chk                : TTrcNikDout;
signal i_nik_ip                      : TTrcNikIP;
signal i_nik_ebout_num               : std_logic_vector(log2(CNIK_EBOUT_COUNT)-1 downto 0);
signal i_nik_ebout_num_max           : std_logic_vector(log2(CNIK_EBOUT_COUNT)-1 downto 0);
signal i_nik_ebcntx                  : std_logic_vector(log2(CNIK_EBKT_LENX)-1 downto 0);
signal i_nik_ebcnty                  : std_logic_vector(log2(CNIK_EBKT_LENY)-1 downto 0);
signal i_nik_ip_count                : std_logic_vector(C_DSN_TRCNIK_REG_OPT_DBG_IP_MSB_BIT-C_DSN_TRCNIK_REG_OPT_DBG_IP_LSB_BIT downto 0);
signal i_nik_ipcnt                   : std_logic_vector(i_nik_ip_count'range);
signal i_nik_ebkt_idx                : std_logic_vector((log2(CNIK_EBKT_LENY) + log2(CNIK_EBKT_LENX))-1 downto 0);
signal i_nik_elcnt                   : std_logic_vector(8 downto 0);
signal i_nik_elcnt_max               : std_logic_vector(8 downto 0);
signal i_nik_ebcnt                   : std_logic_vector(8 downto 0);
signal i_nik_ebcnt_max               : std_logic_vector(8 downto 0);

signal i_nik_ebout_num_dly           : std_logic_vector(i_nik_ebout_num'range);
signal i_nik_ebcntx_dly              : std_logic_vector(i_nik_ebcntx'range);
signal i_nik_ebcnty_dly              : std_logic_vector(i_nik_ebcnty'range);

signal i_nik_ebout                   : TTrcNikEBOs;
signal i_nik_ebout_cnttotal          : std_logic_vector(9 downto 0);

signal i_hbuf_drdy                   : std_logic;
signal i_hbuf_wr                     : std_logic_vector(0 to CNIK_EBOUT_COUNT-1);

signal tst_dbg_color                 : std_logic;
--signal tst_fsmvbuf_cstate            : std_logic_vector(3 downto 0);
--signal tst_fsmvbuf_cstate_dly        : std_logic_vector(tst_fsmvbuf_cstate'range);



--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    tst_fsmvbuf_cstate_dly<=(others=>'0');
--    p_out_tst(0)<='0';
--
--  elsif p_in_clk'event and p_in_clk='1' then
--    tst_fsmvbuf_cstate_dly<=tst_fsmvbuf_cstate;
--
--    p_out_tst(0) <=OR_reduce(tst_fsmvbuf_cstate_dly) or tst_timeout_cnt(8);-- or OR_reduce(i_nik_ebcnt) or OR_reduce(i_nik_elcnt) or i_nik_ktedge;
--
--  end if;
--end process;
--p_out_tst(31 downto 1)<=(others=>'0');
--
--tst_fsmvbuf_cstate<=CONV_STD_LOGIC_VECTOR(16#00#, tst_fsmvbuf_cstate'length) when fsmvbuf_cstate=S_TRC_IDLE else
--                    CONV_STD_LOGIC_VECTOR(16#01#, tst_fsmvbuf_cstate'length) when fsmvbuf_cstate=S_TRC_WVBUF else
--                    CONV_STD_LOGIC_VECTOR(16#02#, tst_fsmvbuf_cstate'length) when fsmvbuf_cstate=S_TRC_IP_SET else
--                    CONV_STD_LOGIC_VECTOR(16#03#, tst_fsmvbuf_cstate'length) when fsmvbuf_cstate=S_TRC_IP_CHK else
--                    CONV_STD_LOGIC_VECTOR(16#04#, tst_fsmvbuf_cstate'length) when fsmvbuf_cstate=S_TRC_RVBUF else
--                    CONV_STD_LOGIC_VECTOR(16#05#, tst_fsmvbuf_cstate'length) when fsmvbuf_cstate=S_TRC_DLY0 else
--                    CONV_STD_LOGIC_VECTOR(16#06#, tst_fsmvbuf_cstate'length) when fsmvbuf_cstate=S_TRC_DLY1 else
--                    CONV_STD_LOGIC_VECTOR(16#07#, tst_fsmvbuf_cstate'length) when fsmvbuf_cstate=S_TRC_EXIT_CHK else
--                    CONV_STD_LOGIC_VECTOR(16#08#, tst_fsmvbuf_cstate'length) when fsmvbuf_cstate=S_TRC_EBOUT_CHK else
--                    CONV_STD_LOGIC_VECTOR(16#FF#, tst_fsmvbuf_cstate'length);

--//-----------------------------
--//Инициализация
--//-----------------------------
tst_dbg_color<=p_in_tst(C_DSN_TRCNIK_REG_TST0_COLOR_DBG_BIT);

p_out_mem_din <=(others=>'0');
p_out_mem_din_rdy_n <='0';

p_out_hirq <='0';

i_nik_ip_count<=p_in_prm_trc.opt(C_DSN_TRCNIK_REG_OPT_DBG_IP_MSB_BIT downto C_DSN_TRCNIK_REG_OPT_DBG_IP_LSB_BIT);

--//Если кол-во ИП = 3, то
--//i_nik_ebout_num_max=12-1,  при CNIK_EBOUT_COUNT=16
--//Если кол-во ИП /= 3, то
--//i_nik_ebout_num_max=16-1,  при CNIK_EBOUT_COUNT=32
i_nik_ebout_num_max<=CONV_STD_LOGIC_VECTOR(12-1, i_nik_ebout_num_max'length) when i_nik_ip_count=CONV_STD_LOGIC_VECTOR(3, i_nik_ebout_num'length) else
                     CONV_STD_LOGIC_VECTOR(16-1, i_nik_ebout_num_max'length);

i_nik_elcnt_max<=p_in_prm_vch.fr_size.activ.row(i_nik_elcnt_max'length+2-1 downto 2);--//Кол-во элементарных строк ЭС
i_nik_ebcnt_max<=p_in_prm_vch.fr_size.activ.pix(i_nik_ebcnt_max'length-1 downto 0);  --//Кол-во элементарных блоков ЭБ в одной ЭС


i_trccore_start<=p_in_ctrl(CNIK_TRCCORE_CTRL_START_BIT);
i_trccore_fr_new<=p_in_ctrl(CNIK_TRCCORE_CTRL_FR_NEW_BIT);
i_trccore_memwd_done<=p_in_ctrl(CNIK_TRCCORE_CTRL_MEMWD_DONE_BIT);

i_vsobel_ctrl(0)<=p_in_prm_trc.opt(C_DSN_TRCNIK_REG_OPT_SOBEL_CTRL_MULT_BIT);
i_vsobel_ctrl(1)<=p_in_prm_trc.opt(C_DSN_TRCNIK_REG_OPT_SOBEL_CTRL_DIV_BIT);



--//-----------------------------
--//Статусы
--//-----------------------------
p_out_status(CNIK_TRCCORE_STAT_NXT_ROW_BIT)<=i_vmirx_done or i_trccore_done;
p_out_status(CNIK_TRCCORE_STAT_HBUF_DRDY_BIT)<=i_hbuf_drdy;
p_out_status(CNIK_TRCCORE_STAT_HBUF_SKIP_BIT)<='0';
p_out_status(CNIK_TRCCORE_STAT_IDLE_BIT)<='1' when fsmvbuf_cstate=S_TRC_IDLE else '0';

p_out_hbuf_dsize<=EXT(i_nik_ebout_cnttotal, p_out_hbuf_dsize'length);

p_out_ebout<=i_nik_ebout;



--//-----------------------------
--//Модуль отзеркаливания по Х
--//-----------------------------
m_vmirx : vmirx_main
port map (
-------------------------------
-- Управление
-------------------------------
p_in_cfg_mirx              => p_in_prm_vch.fr_mirror.pix,
p_in_cfg_pix_count         => p_in_prm_vch.fr_size.activ.pix,

p_out_cfg_mirx_done        => i_vmirx_done,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data              => p_in_mem_dout,
p_in_upp_wd                => p_in_mem_dout_en,
p_out_upp_rdy_n            => p_out_mem_dout_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data            => i_vmir_dout,
p_out_dwnp_wd              => i_vmir_dout_en,
p_in_dwnp_rdy_n            => i_vcoldemasc_rdy_n,

-------------------------------
--Технологический
-------------------------------
p_in_tst                   => "00000000000000000000000000000000",
p_out_tst                  => open,

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
i_vcoldemasc_bypass<=not p_in_prm_vch.fr_color or not tst_dbg_color;

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
p_in_cfg_colorfst  => p_in_prm_vch.fr_color_fst,
p_in_cfg_pix_count => p_in_prm_vch.fr_size.activ.pix,
p_in_cfg_row_count => p_in_prm_vch.fr_size.activ.row,
p_in_cfg_init      => i_trccore_fr_new,

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
p_in_dwnp_rdy_n    => i_vsobel_rdy_n,

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
--//Модуль Выделения контура.
--//-----------------------------
m_vsobel : vsobel_main
generic map (
G_DOUT_WIDTH => 8,
G_SIM        => G_SIM
)
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass    => '0',--i_vsobel_bypass,
p_in_cfg_pix_count => p_in_prm_vch.fr_size.activ.pix,
p_in_cfg_row_count => p_in_prm_vch.fr_size.activ.row,
p_in_cfg_ctrl      => i_vsobel_ctrl,
p_in_cfg_init      => i_trccore_fr_new,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data      => i_vcoldemasc_dout(31 downto 0),
p_in_upp_wd        => i_vcoldemasc_dout_en,
p_out_upp_rdy_n    => i_vsobel_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_in_dwnp_rdy_n    => i_val_rdy_n,
p_out_dwnp_wd      => i_vsobel_dout_en,
p_out_dwnp_data    => i_vsobel_dout,

p_out_dwnp_grad    => i_vsobel_grad_out,

p_out_dwnp_dxm     => i_vsobel_dxm_out,
p_out_dwnp_dym     => i_vsobel_dym_out,

p_out_dwnp_dxs     => i_vsobel_dxs_out,
p_out_dwnp_dys     => i_vsobel_dys_out,

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
--//Модуль вычисления направления(ориентации) градиента яркости.
--//-----------------------------
m_grado : trc_nik_grado
generic map(
G_USE_WDATIN => 8,
G_SIM        => G_SIM
)
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_ctrl        => p_in_prm_trc.opt(C_DSN_TRCNIK_REG_OPT_ANG_MSB_BIT downto C_DSN_TRCNIK_REG_OPT_ANG_LSB_BIT),

--//--------------------------
--//Upstream Port (входные данные)
--//--------------------------
p_in_upp_dxm     => i_vsobel_dxm_out,
p_in_upp_dym     => i_vsobel_dym_out,

p_in_upp_dxs     => i_vsobel_dxs_out,
p_in_upp_dys     => i_vsobel_dys_out,

p_in_upp_grad    => i_vsobel_grad_out,
p_in_upp_data    => i_vsobel_dout,

p_in_upp_wd      => i_vsobel_dout_en,
p_out_upp_rdy_n  => i_val_rdy_n,

--//--------------------------
--//Downstream Port (результат)
--//--------------------------
p_out_dwnp_data  => i_val_pix_out,
p_out_dwnp_grada => i_val_grada_out,
p_out_dwnp_grado => i_val_grado_out,

p_out_dwnp_wd    => i_val_en_out,
p_in_dwnp_rdy_n  => '0',

-------------------------------
--Технологический
-------------------------------
p_in_tst         => "00000000000000000000000000000000",
p_out_tst        => open,

-------------------------------
--System
-------------------------------
p_in_clk         => p_in_clk,
p_in_rst         => p_in_rst
);


--//-----------------------------
--//Логика работы модуля trc_nik_core.vhd
--//-----------------------------
--//Автомат операций выполняемых модулем trc_nik_core.vhd
process(p_in_rst,p_in_clk)
variable  var_nik_ip  : TTrcNikIP;
begin
  if p_in_rst='1' then
    fsmvbuf_cstate <= S_TRC_IDLE;

    i_vbufrow_adr<=(others=>'0');
--    i_vbufrow_wd<='0';
    i_vbufrow_rd<='0';

    i_hbuf_drdy<='0';

    var_nik_ip.p1:=(others=>'0');
    var_nik_ip.p2:=(others=>'0');
    i_nik_ip.p1<=(others=>'0');
    i_nik_ip.p2<=(others=>'0');

    i_nik_ebcntx<=(others=>'0');
    i_nik_ebcnty<=(others=>'0');
    i_nik_ipcnt<=(others=>'0');
    i_nik_ebout_num<=(others=>'0');

    i_nik_elcnt<=(others=>'0');
    i_trccore_done<='0';

    i_vfr_row_cnt<=(others=>'0');


  elsif p_in_clk'event and p_in_clk='1' then

      case fsmvbuf_cstate is

        --//######################################
        --//Запись одной элементарной строки(ЭС) в BRAM (1ЭС никифорова = 4 строки видеокадра)
        --//######################################
        --//------------------------------------
        --//Ждем начала работы
        --//------------------------------------
        when S_TRC_IDLE =>

          i_vbufrow_rd<='0';
          i_trccore_done<='0';

          if i_trccore_fr_new='1' then
            i_vfr_row_cnt<=(others=>'0');
            i_nik_elcnt<=(others=>'0');

          elsif i_trccore_start='1' then

            fsmvbuf_cstate <= S_TRC_WVBUF;

          end if;

        --//------------------------------------
        --//Заполняем буфера строк
        --//------------------------------------
        when S_TRC_WVBUF =>

          if i_val_en_out='1' then
            if i_vbufrow_adr=(p_in_prm_vch.fr_size.activ.pix(13 downto 0)&"00")-1 then
            --//ВАЖНО: т.к. шина выходных данных модуля vsobel_main.vhd = 8bit, а
            --//значение в p_in_prm_trc.zone.activ.pix для 32bit шины данных

              i_vbufrow_adr<=(others=>'0');
--              i_vbufrow_wd<='0';

              if i_vfr_row_cnt=p_in_prm_vch.fr_size.activ.row-1 then
                i_vfr_row_cnt<=(others=>'0');
                i_nik_ebcnty<=(others=>'0');
                fsmvbuf_cstate <= S_TRC_IP_SET;

              else
                i_vfr_row_cnt<=i_vfr_row_cnt+1;

                if i_nik_ebcnty=CONV_STD_LOGIC_VECTOR(CNIK_EBKT_LENY-1, i_nik_ebcnty'length) then
                  i_nik_ebcnty<=(others=>'0');

                  fsmvbuf_cstate <= S_TRC_IP_SET;
                else
                  i_nik_ebcnty<=i_nik_ebcnty + 1;
                end if;
              end if;

            else
              i_vbufrow_adr<=i_vbufrow_adr+1;
            end if;
          end if;



        --//######################################
        --//Чтение данных элементарной строки(ЭС) из BRAM
        --//######################################
        --//------------------------------------
        --//Установка Интервального Порога(ИП)
        --//------------------------------------
        when S_TRC_IP_SET =>

          for i in 0 to C_DSN_TRCNIK_IP_COUNT-1 loop
            if i_nik_ipcnt=i then
              i_nik_ip<=p_in_prm_trc.ip(i);
            end if;
          end loop;
          fsmvbuf_cstate <= S_TRC_IP_CHK;

        --//------------------------------------
        --//Проверка Интервального порога
        --//------------------------------------
        when S_TRC_IP_CHK =>

            if i_nik_ip.p1>i_nik_ip.p2 then --//Игнорирую обработку такого Интервального порога !!!!!!!

                if i_vbufrow_adr>=p_in_prm_vch.fr_size.activ.pix(13 downto 0)&"00" and
                   i_nik_ipcnt=(i_nik_ipcnt'range =>'0') then
                    --//Завершил обработку текущией ЭС(элементарной строки)
                    i_vbufrow_adr<=(others=>'0');
                    i_nik_ipcnt<=(others=>'0');
                    i_trccore_done<='1';
                    fsmvbuf_cstate <= S_TRC_IDLE;
                else
                    --//Счетчик ИП
                    if i_nik_ipcnt=i_nik_ip_count-1 then
                      i_nik_ipcnt<=(others=>'0');
                      i_vbufrow_adr<=i_vbufrow_adr + CNIK_EBKT_LENX;--//Переходим к следующему ЭБ
                    else
                      i_nik_ipcnt<=i_nik_ipcnt + 1;
                    end if;

                    --Счетчик ЭБ отправленых на формирование выходного пакета данных КТ
                    if i_nik_ebout_num=i_nik_ebout_num_max then
                      i_nik_ebout_num<=(others=>'0');
                      fsmvbuf_cstate <= S_TRC_DLY0;--//Отправляю данные в ОЗУ
                    else
                      i_nik_ebout_num<=i_nik_ebout_num + 1;
                      fsmvbuf_cstate <= S_TRC_IP_SET;--//Переход к следующему ИП
                    end if;
                end if;
            else
                i_vbufrow_rd<='1';
                fsmvbuf_cstate <= S_TRC_RVBUF;
            end if;

        --//------------------------------------
        --//Читаем данные элементарных блоков (ЭБ) +
        --//Формируем выходной пакет данных(реализацию см. ниже).
        --//Кол-во анализируемых ЭБ определяется константой CNIK_EBOUT_COUNT
        --//------------------------------------
        when S_TRC_RVBUF =>

            if i_nik_ebcntx=CONV_STD_LOGIC_VECTOR(CNIK_EBKT_LENX-1, i_nik_ebcntx'length) then
                i_nik_ebcntx<=(others=>'0');
                if i_nik_ebcnty=CONV_STD_LOGIC_VECTOR(CNIK_EBKT_LENY-1, i_nik_ebcnty'length) then
                    i_nik_ebcnty<=(others=>'0');
                    --//Проанализировал все элементы ЭБ
                    i_vbufrow_rd<='0';

                    --//Счетчик ИП
                    if i_nik_ipcnt=i_nik_ip_count-1 then
                      i_nik_ipcnt<=(others=>'0');
                      i_vbufrow_adr<=i_vbufrow_adr + CNIK_EBKT_LENX;--//Переходим к следующему ЭБ
                    else
                      i_nik_ipcnt<=i_nik_ipcnt + 1;
                    end if;

                    --Счетчик ЭБ отправленых на формирование выходного пакета данных КТ
                    if i_nik_ebout_num=i_nik_ebout_num_max then
                      i_nik_ebout_num<=(others=>'0');
                      fsmvbuf_cstate <= S_TRC_DLY0;--//Отправляю данные в ОЗУ
                    else
                      i_nik_ebout_num<=i_nik_ebout_num + 1;
                      fsmvbuf_cstate <= S_TRC_IP_SET;--//Переход к следующему ИП
                    end if;

                else
                  i_nik_ebcnty<=i_nik_ebcnty+1;
                end if;
            else
              i_nik_ebcntx<=i_nik_ebcntx + 1;
            end if;

        --//------------------------------------
        --//
        --//------------------------------------
        when S_TRC_DLY0 =>
          fsmvbuf_cstate <= S_TRC_DLY1;

        when S_TRC_DLY1 =>
          --//Сигнализуруем автомату модуля dsn_track_nik.vhd, что
          --//В выходном буфере есть данные
          i_hbuf_drdy<='1';
          fsmvbuf_cstate <= S_TRC_EXIT_CHK;

        --//------------------------------------
        --//Проверка завершения анализа ЭС
        --//------------------------------------
        when S_TRC_EXIT_CHK =>

          i_hbuf_drdy<='0';

          if i_vbufrow_adr=p_in_prm_vch.fr_size.activ.pix(13 downto 0)&"00" and
             i_nik_ipcnt=(i_nik_ipcnt'range =>'0') then

            --//Завершил обработку текущией ЭС
            i_vbufrow_adr<=(others=>'0');
            i_nik_ipcnt<=(others=>'0');
            i_trccore_done<='1';

            i_nik_elcnt<=i_nik_elcnt + 1;
            fsmvbuf_cstate <= S_TRC_IDLE;

          else
            --//Продолжаю обработку текущей ЭС
            fsmvbuf_cstate <= S_TRC_EBOUT_CHK;
          end if;

        --//------------------------------------
        --//Ждем подтверждения записи данных в ОЗУ
        --//------------------------------------
        when S_TRC_EBOUT_CHK =>

          if i_trccore_memwd_done='1' then
            fsmvbuf_cstate <= S_TRC_IP_SET;
          end if;

      end case;

  end if;
end process;


--//-----------------------------
--//Управление буферами строк сотавляющими
--//одну элементарную строку(ЭС) Никифорова
--//-----------------------------
i_vbufrow_adra(9 downto 0)<=i_vbufrow_adr(9 downto 0);

i_vbufrow_adrb(i_nik_ebcntx'length-1 downto 0)<=i_nik_ebcntx;
i_vbufrow_adrb(i_vbufrow_adrb'high downto i_nik_ebcntx'length)<=i_vbufrow_adr(i_vbufrow_adrb'high downto i_nik_ebcntx'length);

--//Промежуточные буфера:
gen_buf : for i in 0 to CNIK_EBKT_LENY-1 generate
begin

--//Запись элементарной строки(ЭС):
i_vbufrow_ena(i)<=i_val_en_out when i_nik_ebcnty=i else '0';
i_vbufrow_dina(i)(7 downto 0) <=i_val_pix_out(7 downto 0);--//Яркость пиксела
i_vbufrow_dina(i)(15 downto 8)<=i_val_grada_out(7 downto 0);--//Градиент яркости(амплитуда)
i_vbufrow_dina(i)(23 downto 16)<=i_val_grado_out(7 downto 0);--//Наравление(ориентация)Градиента яркости

--//Чтение элементарной строки(ЭС):
i_vbufrow_enb(i)<=i_vbufrow_rd when i_nik_ebcnty=i else '0';

m_vbufrow :trc_nik_vbuf
port map(
addra => i_vbufrow_adra,
dina  => i_vbufrow_dina(i),
douta => open,--i_vbufrow_douta(i),
ena   => i_vbufrow_ena(i),
wea   => "1",
clka  => p_in_clk,
rsta  => p_in_rst,

addrb => i_vbufrow_adrb,--i_vbufrow_adr(9 downto 0),
dinb  => "000000000000000000000000",--"0000000000000000",--"00000000000000000000000000000000",
doutb => i_vbufrow_doutb(i),
enb   => i_vbufrow_enb(i),
web   => "0",
clkb  => p_in_clk,
rstb  => p_in_rst
);

i_nik_dout(i).pix<=i_vbufrow_doutb(i)(7 downto 0);
i_nik_dout(i).grada<=i_vbufrow_doutb(i)(15 downto 8);
i_nik_dout(i).grado<=i_vbufrow_doutb(i)(23 downto 16);

end generate gen_buf;


--//----------------------------------------
--//Выделение КТ попавших в заданые ИП +
--//Формирование выходны данных:
--//-----------------------------
--//счетчик ЭБ в одной ЭС
i_nik_ebcnt<=i_vbufrow_adr(i_nik_ebcnt'length+i_nik_ebcntx'length-1 downto i_nik_ebcntx'length);

--//линии задержек
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_nik_ebcntx_dly<=(others=>'0');
    i_nik_ebcnty_dly<=(others=>'0');
    i_nik_ebout_num_dly<=(others=>'0');

    i_vbufrow_rd_dly<='0';
    i_nik_ktedge<='0';
  elsif p_in_clk'event and p_in_clk='1' then

    i_nik_ebcntx_dly<=i_nik_ebcntx;
    i_nik_ebcnty_dly<=i_nik_ebcnty;
    i_nik_ebout_num_dly<=i_nik_ebout_num;

    i_vbufrow_rd_dly<=i_vbufrow_rd;

    --//Макрируем краевые точки
    if i_nik_elcnt=(i_nik_elcnt'range =>'0') then
    --//Первая ЭС
        if i_nik_ebcnty=(i_nik_ebcnty'range =>'0') or
         (i_nik_ebcnt=(i_nik_ebcnt'range =>'0') and i_nik_ebcntx=(i_nik_ebcntx'range =>'0')) or
         (i_nik_ebcnt=i_nik_ebcnt_max-1 and i_nik_ebcntx=CONV_STD_LOGIC_VECTOR(CNIK_EBKT_LENX-1, i_nik_ebcntx'length)) then
            i_nik_ktedge<='1';
        else
            i_nik_ktedge<='0';
        end if;

    elsif i_nik_elcnt=i_nik_elcnt_max-1 then
    --//Последняя ЭС
        if i_nik_ebcnty=CONV_STD_LOGIC_VECTOR(CNIK_EBKT_LENY-1, i_nik_ebcnty'length) or
         (i_nik_ebcnt=(i_nik_ebcnt'range =>'0') and i_nik_ebcntx=(i_nik_ebcntx'range =>'0')) or
         (i_nik_ebcnt=i_nik_ebcnt_max-1 and i_nik_ebcntx=CONV_STD_LOGIC_VECTOR(CNIK_EBKT_LENX-1, i_nik_ebcntx'length)) then
            i_nik_ktedge<='1';
        else
            i_nik_ktedge<='0';
        end if;

    else
    --//Все остальные ЭС
        if (i_nik_ebcnt=(i_nik_ebcnt'range =>'0') and i_nik_ebcntx=(i_nik_ebcntx'range =>'0')) or
         (i_nik_ebcnt=i_nik_ebcnt_max-1 and i_nik_ebcntx=CONV_STD_LOGIC_VECTOR(CNIK_EBKT_LENX-1, i_nik_ebcntx'length)) then
            i_nik_ktedge<='1';
        else
            i_nik_ktedge<='0';
        end if;
    end if;

  end if;
end process;

--//Выделение КТ попавших в заданые ИП:
--//Формируем номер КТ внутри ЭБ
i_nik_ebkt_idx<=i_nik_ebcnty_dly & i_nik_ebcntx_dly;

process(p_in_rst,p_in_clk)
  variable var_hbuf_wr : std_logic_vector(0 to CNIK_EBOUT_COUNT-1);
begin
  if p_in_rst='1' then

    i_nik_kt.idx<=(others=>'0');
    i_nik_kt.pix<=(others=>'0');
    i_nik_kt.grada<=(others=>'0');
    i_nik_kt.grado<=(others=>'0');

    i_hbuf_wr<=(others=>'0');
    var_hbuf_wr:=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    var_hbuf_wr:=(others=>'0');

    if i_vbufrow_rd_dly='1' then

        --//1: Позиция КТ внутри ЭБ
        i_nik_kt.idx<=EXT(i_nik_ebkt_idx, i_nik_kt.idx'length);

        for i in 0 to CNIK_EBKT_LENY-1 loop
          if i_nik_ebcnty_dly=i then

        --//2: Реальная яркость пикселя
            i_nik_kt.pix<=i_nik_dout(i).pix;

        --//3: Анализ градиента яркости по заданым ИП исключая краевые точки
            if i_nik_ip.p1<i_nik_ip.p2 and i_nik_ktedge='0' then
                if i_nik_ip.p1=i_nik_ip.p2 then
                  if i_nik_ip.p1=i_nik_dout(i).grada then

                    --//Формируем разрешение записи данных
                    for x in 0 to CNIK_EBOUT_COUNT-1 loop
                      if i_nik_ebout_num_dly=x then
                        var_hbuf_wr(x):='1';
                      end if;
                    end loop;

                    i_nik_kt.grada<=i_nik_dout(i).grada;
                  end if;

                elsif i_nik_ip.p1 <= i_nik_dout(i).grada then
                  if i_nik_ip.p2 >= i_nik_dout(i).grada then

                    --//Формируем разрешение записи данных
                    for x in 0 to CNIK_EBOUT_COUNT-1 loop
                      if i_nik_ebout_num_dly=x then
                        var_hbuf_wr(x):='1';
                      end if;
                    end loop;

                    i_nik_kt.grada<=i_nik_dout(i).grada;
                  end if;
                end if;
            end if;

        --//4: Направление градиента яркости
          i_nik_kt.grado<=i_nik_dout(i).grado;

          end if;--//if i_nik_ebcnty_dly=i then
        end loop;--//for i in 0 to CNIK_EBKT_LENY-1 loop

    end if;

    i_hbuf_wr<=var_hbuf_wr;--//Разрешение записи в выходной буфер
  end if;
end process;

--//Запись данных в выходной буфер:
p_out_hbuf_wr<=OR_reduce(i_hbuf_wr);--i_hbuf_wr;--

p_out_hbuf_din(7 downto 0)  <=i_nik_kt.idx;
p_out_hbuf_din(15 downto 8) <=i_nik_kt.pix;
p_out_hbuf_din(23 downto 16)<=i_nik_kt.grada;
p_out_hbuf_din(31 downto 24)<=i_nik_kt.grado;

--//Счетчики данных:
--//Общее кол-во КТ записаных в быходной буфер
--//(Информация необходима для упраления записью в ОЗУ)
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_nik_ebout_cnttotal<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
      if i_hbuf_drdy='1' then
        i_nik_ebout_cnttotal<=(others=>'0');
      elsif OR_reduce(i_hbuf_wr)='1' then
        i_nik_ebout_cnttotal<=i_nik_ebout_cnttotal+1;
      end if;
  end if;
end process;

gen : for i in 0 to CNIK_EBOUT_COUNT-1 generate
begin
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_nik_ebout(i).cnt<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
      if i_hbuf_drdy='1' then
        i_nik_ebout(i).cnt<=(others=>'0');
      elsif i_hbuf_wr(i)='1' then
        i_nik_ebout(i).cnt<=i_nik_ebout(i).cnt+1;
      end if;
  end if;
end process;
end generate gen;


--END MAIN
end behavioral;

