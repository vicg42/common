-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.06
-- Module Name : video_reader
--
-- Назначение/Описание :
--  Чтение кадра видеоканала из ОЗУ
--
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
use work.mem_wr_pkg.all;
use work.dsn_video_ctrl_pkg.all;


entity video_reader is
generic(
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
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch     : in    TReaderVCHParams;

p_in_hrd_chsel       : in    std_logic_vector(3 downto 0);--//Хост: номер видеоканала выбраного для чтения
p_in_hrd_start       : in    std_logic;                   --//Хост: Запуск чтения кадра
p_in_hrd_done        : in    std_logic;                   --//Хост: Подтверждение вычитки кадра

p_in_vfr_buf         : in    TVfrBufs;                    --//Номер видеобувера с готовым кадром для соответствующего видеоканала
p_in_vfr_nrow        : in    std_logic;                   --//Разрешение чтения следующей строки

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
end video_reader;

architecture behavioral of video_reader is

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

component vbuf_rotate
port(
din         : IN  std_logic_vector(31 downto 0);
wr_en       : IN  std_logic;
--wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(31 downto 0);
rd_en       : IN  std_logic;
--rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;
almost_full : OUT std_logic;

clk         : IN  std_logic;
rst         : IN  std_logic
);
end component;

type TFrRotate is record
l : std_logic;--left
r : std_logic;--right
end record;

type fsm_do_state is (
S_DO_IDLE,
S_DO_WORK,
S_DO_NEXT
);
signal fsm_do_cs : fsm_do_state;

type fsm_state is (
S_IDLE,
S_LD_PRMS,
S_ROT_INIT,
S_ROT_ROW_FINED0,
S_ROT_MEM_SET_ADR,
S_ROT_MEM_START,
S_ROT_MEM_RD,
S_ROT_PIX_CHK,
S_ROT_ROW_CHK,
S_ROW_FINED0,
S_ROW_FINED1,
S_MEM_SET_ADR,
S_MEM_START,
S_MEM_RD,
S_ROW_NXT,
S_WAIT_HOST_ACK
);
signal fsm_state_cs: fsm_state;

signal i_mem_ptr                     : std_logic_vector(31 downto 0);
signal i_mem_rdbase                  : std_logic_vector(31 downto 0);
signal i_mem_adr                     : std_logic_vector(31 downto 0);
signal i_mem_trn_len                 : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq                 : std_logic_vector(15 downto 0);
signal i_mem_start                   : std_logic;
signal i_mem_dir                     : std_logic;
signal i_mem_done                    : std_logic;

signal i_vch_num                     : std_logic_vector(p_in_hrd_chsel'high downto 0);
signal i_vfr_zoom                    : std_logic_vector(3 downto 0);
signal i_vfr_zoom_type               : std_logic;
signal i_vfr_pcolor                  : std_logic;
signal i_vfr_color                   : std_logic;
signal i_vfr_color_fst               : std_logic_vector(1 downto 0);
signal i_vfr_mirror                  : TFrXYMirror;
signal i_vfr_row_cnt                 : std_logic_vector(15 downto 0);--(G_MEM_VFR_L_BIT-G_MEM_VLINE_L_BIT downto 0);
signal i_vfr_pix_cntdw               : std_logic_vector(15 downto 0);
signal i_vfr_pix_cntbyte             : std_logic_vector(1 downto 0);
signal i_vfr_size                    : TFrXYParam;
signal i_vfr_done                    : std_logic;
signal i_vfr_new                     : std_logic;
signal i_vfr_buf                     : std_logic_vector(C_VCTRL_MEM_VFR_M_BIT-C_VCTRL_MEM_VFR_L_BIT downto 0);
signal i_vfr_rotate                  : TFrRotate;

signal i_memd                        : std_logic_vector(p_out_upp_data'range);
signal i_memd_en                     : std_logic;
type TVRowDout is array (7 downto 0) of std_logic_vector(p_out_upp_data'range);
signal i_vrow_buf_din                : TVRowDout;
signal i_vrow_buf_dout               : TVRowDout;
signal i_vrow_buf_wr                 : std_logic_vector(i_vrow_buf_dout'length-1 downto 0);
signal i_vrow_buf_rd                 : std_logic_vector(i_vrow_buf_dout'length-1 downto 0);
signal i_vrow_buf_empty              : std_logic_vector(i_vrow_buf_dout'length-1 downto 0);
signal i_vrow_buf_full               : std_logic_vector(i_vrow_buf_dout'length-1 downto 0);
signal i_vrow_buf_full_all           : std_logic;
signal i_vrow_buf_num                : std_logic_vector(3 downto 0);
type TDWByte is array (i_memd'length/8-1 downto 0) of std_logic_vector(7 downto 0);
type TSrDW is array (i_vrow_buf_dout'length-1 downto 0) of TDWByte;
signal sr_memd                       : TSrDW;
signal sr_memd_en                    : std_logic_vector(i_vrow_buf_dout'length-1 downto 0);
signal i_memd_count                  : std_logic_vector(3 downto 0);
signal i_memd_out_en                 : std_logic_vector(i_vrow_buf_dout'length-1 downto 0);
signal i_memd_out                    : std_logic_vector(p_out_upp_data'range);
signal i_cntpix_out                  : std_logic_vector(15 downto 0);
signal i_cntrow_out                  : std_logic_vector(15 downto 0);

--signal tst_dbg_rdTBUF                : std_logic;
--signal tst_dbg_rdEBUF                : std_logic;
--signal tst_fsmstate                  : std_logic_vector(3 downto 0);
--signal tst_fsmstate_dly              : std_logic_vector(3 downto 0);
--signal tst_mem_ctrl_ch_wr_out        : std_logic_vector(31 downto 0);
signal tst_dbg_rotleft               : std_logic;
signal tst_dbg_rotright              : std_logic;


--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(0)<='0';
--    tst_fsmstate_dly<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    tst_fsmstate_dly<=tst_fsmstate;
--    p_out_tst(0) <=OR_reduce(tst_fsmstate_dly);-- or tst_mem_ctrl_ch_wr_out(0);--i_upp_data_wd;
--
--  end if;
--end process;
--p_out_tst(31 downto 1)<=(others=>'0');
--
--tst_fsmstate<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsmstate'length) when fsm_state_cs=S_LD_PRMS else
--              CONV_STD_LOGIC_VECTOR(16#02#,tst_fsmstate'length) when fsm_state_cs=S_ROW_FINED0 else
--              CONV_STD_LOGIC_VECTOR(16#03#,tst_fsmstate'length) when fsm_state_cs=S_ROW_FINED1 else
--              CONV_STD_LOGIC_VECTOR(16#04#,tst_fsmstate'length) when fsm_state_cs=S_MEM_SET_ADR else
--              CONV_STD_LOGIC_VECTOR(16#05#,tst_fsmstate'length) when fsm_state_cs=S_MEM_START else
--              CONV_STD_LOGIC_VECTOR(16#06#,tst_fsmstate'length) when fsm_state_cs=S_MEM_RD else
--              CONV_STD_LOGIC_VECTOR(16#07#,tst_fsmstate'length) when fsm_state_cs=S_ROW_NXT else
--              CONV_STD_LOGIC_VECTOR(16#08#,tst_fsmstate'length) when fsm_state_cs=S_WAIT_HOST_ACK else
--              CONV_STD_LOGIC_VECTOR(16#00#,tst_fsmstate'length); --//fsm_state_cs=S_IDLE else
--
tst_dbg_rotleft<=p_in_tst(C_VCTRL_REG_TST0_DBG_ROTLEFT_BIT);
tst_dbg_rotright<=p_in_tst(C_VCTRL_REG_TST0_DBG_ROTRIGHT_BIT);


--//----------------------------------------------
--//Статусы
--//----------------------------------------------
p_out_vch_rd_done<=i_vfr_done;
p_out_vch_fr_new<=i_vfr_new;

--параметры чтения текущего кадра
p_out_vch <= i_vch_num;

p_out_vch_color_fst <=i_vfr_color_fst;
p_out_vch_color     <=i_vfr_color;
p_out_vch_pcolor    <=i_vfr_pcolor;
p_out_vch_active_pix<=i_vfr_size.activ.pix;--i_mem_dlen_rq;
p_out_vch_active_row<=EXT(i_vfr_size.activ.row, p_out_vch_active_row'length);
p_out_vch_zoom      <=i_vfr_zoom;
p_out_vch_zoom_type <=i_vfr_zoom_type;
p_out_vch_mirx      <=i_vfr_mirror.pix;



--//----------------------------------------------
--//Автомат Чтения видео кадра
--//----------------------------------------------
--Логика работы автомата
process(p_in_rst,p_in_clk)
  variable vfr_active_row_end : std_logic_vector(i_vfr_row_cnt'range);
  variable vfr_pix_cntdw : std_logic_vector(i_vfr_pix_cntdw'range);
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;

    i_mem_rdbase<=(others=>'0');
    i_mem_ptr<=(others=>'0');
    i_mem_adr<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_dlen_rq<=(others=>'0');
    i_mem_dir<='0';
    i_mem_start<='0';

    i_vfr_buf<=(others=>'0');
    i_vfr_pcolor<='0';
    i_vfr_color<='0';
    i_vfr_color_fst<=(others=>'0');
    i_vfr_mirror.pix<='0';
    i_vfr_mirror.row<='0';
    i_vfr_row_cnt<=(others=>'0');
    i_vfr_pix_cntdw<=(others=>'0');
      vfr_pix_cntdw:=(others=>'0');
    i_vfr_pix_cntbyte<=(others=>'0');
    i_vfr_size.skip.row<=(others=>'0');
    i_vfr_size.activ.row<=(others=>'0');
      vfr_active_row_end:=(others=>'0');
    i_vfr_size.skip.pix<=(others=>'0');
    i_vfr_size.activ.pix<=(others=>'0');
    i_vfr_zoom<=(others=>'0');
    i_vfr_zoom_type<='0';
    i_vfr_rotate.l<='0';
    i_vfr_rotate.r<='0';

    i_vfr_done<='0';
    i_vch_num<=(others=>'0');
    i_vfr_new<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    vfr_pix_cntdw:=(others=>'0');

    case fsm_state_cs is

      --------------------------------------
      --Исходное состояние
      --------------------------------------
      when S_IDLE =>

        i_vfr_done<='0';

        --Загрузка праметров Видео канала
        if p_in_hrd_start='1' then
          i_mem_trn_len<=EXT(p_in_cfg_mem_trn_len, i_mem_trn_len'length);
          i_vch_num<=p_in_hrd_chsel;

          fsm_state_cs <= S_LD_PRMS;
        end if;

      --------------------------------------
      --Загрузка параметров
      --------------------------------------
      when S_LD_PRMS =>

        --Загрузка праметров Видео канала
        for i in 0 to C_VCTRL_VCH_COUNT-1 loop
          if i_vch_num=i then
            i_vfr_buf<=p_in_vfr_buf(i);
            i_mem_rdbase<=p_in_cfg_prm_vch(i).mem_adr;

            i_vfr_rotate.l<=tst_dbg_rotleft;
            i_vfr_rotate.r<=tst_dbg_rotright;

            i_vfr_pcolor<=p_in_cfg_prm_vch(i).fr_pcolor;
            i_vfr_color<=p_in_cfg_prm_vch(i).fr_color;
            i_vfr_color_fst<=p_in_cfg_prm_vch(i).fr_color_fst;

            i_vfr_zoom<=p_in_cfg_prm_vch(i).fr_zoom;
            i_vfr_zoom_type<=p_in_cfg_prm_vch(i).fr_zoom_type;

            i_vfr_mirror.pix<=p_in_cfg_prm_vch(i).fr_mirror.pix;
            i_vfr_mirror.row<=p_in_cfg_prm_vch(i).fr_mirror.row;

            i_vfr_size.activ.pix<=p_in_cfg_prm_vch(i).fr_size.activ.pix;
            i_vfr_size.skip.pix<=p_in_cfg_prm_vch(i).fr_size.skip.pix;
            i_vfr_size.activ.row<=p_in_cfg_prm_vch(i).fr_size.activ.row;
            i_vfr_size.skip.row<=p_in_cfg_prm_vch(i).fr_size.skip.row;
          end if;
        end loop;

        i_mem_ptr<=(others=>'0');
        i_vfr_new<='1';

        fsm_state_cs <= S_ROT_INIT;--S_ROW_FINED0;

      --------------------------------------
      --
      --------------------------------------
      when S_ROT_INIT =>

        i_vfr_new<='0';

        if i_vfr_rotate.l='0' and i_vfr_rotate.r='0' then

            i_mem_dlen_rq<=i_vfr_size.activ.pix;
            if i_vfr_mirror.row='0' then
              i_vfr_row_cnt<=i_vfr_size.skip.row;
            else
              i_vfr_row_cnt<=i_vfr_size.skip.row + i_vfr_size.activ.row;
            end if;
            fsm_state_cs <= S_ROW_FINED0;

        else

            i_mem_dlen_rq<=CONV_STD_LOGIC_VECTOR(i_vrow_buf_dout'length/(i_memd'length/8), i_mem_dlen_rq'length);--значение в DW=4pix
            if i_vfr_mirror.row='0' then
              i_vfr_pix_cntdw<=i_vfr_size.skip.pix + i_vfr_size.activ.pix;
              i_vfr_pix_cntbyte<=CONV_STD_LOGIC_VECTOR(i_memd'length/8-1, i_vfr_pix_cntbyte'length);
            else
              i_vfr_pix_cntdw<=i_vfr_size.skip.pix;
              i_vfr_pix_cntbyte<=(others=>'0');
            end if;

            i_vfr_row_cnt<=i_vfr_size.skip.row;

            fsm_state_cs <= S_ROT_ROW_FINED0;
        end if;


------------------  ROTATE=1 ----------------------------
      --------------------------------------
      --
      --------------------------------------
      when S_ROT_ROW_FINED0 =>

        i_vfr_new<='0';
        fsm_state_cs <= S_ROT_MEM_SET_ADR;

      --------------------------------------
      --Запускаем операцию чтения ОЗУ
      --------------------------------------
      when S_ROT_MEM_SET_ADR =>

        if i_vfr_mirror.row='0' then
          vfr_pix_cntdw:=i_vfr_pix_cntdw - 1;
        else
          vfr_pix_cntdw:=vfr_pix_cntdw;
        end if;

        i_mem_ptr(i_mem_ptr'high downto G_MEM_VCH_M_BIT+1)<=(others=>'0');
        i_mem_ptr(G_MEM_VCH_M_BIT downto G_MEM_VCH_L_BIT)<=i_vch_num(G_MEM_VCH_M_BIT-G_MEM_VCH_L_BIT downto 0);
        i_mem_ptr(G_MEM_VFR_M_BIT downto G_MEM_VFR_L_BIT)<=i_vfr_buf;
        i_mem_ptr(G_MEM_VLINE_M_BIT downto G_MEM_VLINE_L_BIT)<=vfr_pix_cntdw(G_MEM_VLINE_M_BIT-G_MEM_VLINE_L_BIT-2 downto 0)&i_vfr_pix_cntbyte;
        i_mem_ptr(G_MEM_VLINE_L_BIT-1 downto 0)<=i_vfr_row_cnt(G_MEM_VLINE_L_BIT-1 downto 0);

        fsm_state_cs <= S_ROT_MEM_START;

      --------------------------------------
      --Запускаем операцию чтения ОЗУ
      --------------------------------------
      when S_ROT_MEM_START =>

        i_mem_adr<=i_mem_rdbase + i_mem_ptr;
        i_mem_dir<=C_MEMWR_READ;

        if i_vrow_buf_full_all='0' then
          i_mem_start<='1';
          fsm_state_cs <= S_ROT_MEM_RD;
        end if;

      ------------------------------------------------
      --Чтение данных
      ------------------------------------------------
      when S_ROT_MEM_RD =>

        i_mem_start<='0';

        if i_mem_done='1' then
        --Операция выполнена
          if i_vfr_mirror.row='0' then
            if i_vfr_pix_cntbyte=CONV_STD_LOGIC_VECTOR(0, i_vfr_pix_cntbyte'length) then
              i_vfr_pix_cntbyte<=CONV_STD_LOGIC_VECTOR(i_memd'length/8-1, i_vfr_pix_cntbyte'length);
              i_vfr_pix_cntdw<=i_vfr_pix_cntdw - i_mem_dlen_rq;
              fsm_state_cs <= S_ROT_PIX_CHK;
            else
              i_vfr_pix_cntbyte<=i_vfr_pix_cntbyte - 1;
              fsm_state_cs <= S_ROT_MEM_SET_ADR;
            end if;
          else
            if i_vfr_pix_cntbyte=CONV_STD_LOGIC_VECTOR(i_memd'length/8-1, i_vfr_pix_cntbyte'length) then
              i_vfr_pix_cntbyte<=CONV_STD_LOGIC_VECTOR(0, i_vfr_pix_cntbyte'length);
              i_vfr_pix_cntdw<=i_vfr_pix_cntdw + i_mem_dlen_rq;
              fsm_state_cs <= S_ROT_PIX_CHK;
            else
              i_vfr_pix_cntbyte<=i_vfr_pix_cntbyte + 1;
              fsm_state_cs <= S_ROT_MEM_SET_ADR;
            end if;
          end if;
        end if;

      ------------------------------------------------
      --Проверка вычетки всех Pix
      ------------------------------------------------
      when S_ROT_PIX_CHK =>

        if (i_vfr_mirror.row='0' and i_vfr_pix_cntdw=i_vfr_size.skip.pix) or
           (i_vfr_mirror.row='1' and i_vfr_pix_cntdw=(i_vfr_size.skip.pix + i_vfr_size.activ.pix)) then
          i_vfr_row_cnt<=i_vfr_row_cnt + (i_mem_dlen_rq(i_mem_dlen_rq'length-1-2 downto 0)&"00");
          fsm_state_cs <= S_ROT_ROW_CHK;
        else
          fsm_state_cs <= S_ROT_MEM_SET_ADR;
        end if;

      ------------------------------------------------
      --Проверка вычетки всех Row
      ------------------------------------------------
      when S_ROT_ROW_CHK =>

        if i_vfr_row_cnt>=(i_vfr_size.skip.row + i_vfr_size.activ.row) then
            fsm_state_cs <= S_WAIT_HOST_ACK;
        else
          if i_vfr_mirror.row='0' then
            i_vfr_pix_cntdw<=i_vfr_size.skip.pix + i_vfr_size.activ.pix;
            i_vfr_pix_cntbyte<=CONV_STD_LOGIC_VECTOR(i_memd'length/8-1, i_vfr_pix_cntbyte'length);
          else
            i_vfr_pix_cntdw<=i_vfr_size.skip.pix;
            i_vfr_pix_cntbyte<=(others=>'0');
          end if;
          fsm_state_cs <= S_ROT_ROW_FINED0;
        end if;

------------------  ROTATE=1 ----------------------------


------------------  ROTATE=0 ----------------------------

      --------------------------------------
      --
      --------------------------------------
      when S_ROW_FINED0 =>

        i_vfr_new<='0';

        if i_vfr_mirror.row='1' then
          --Отзеркаливание по Y - РАЗРЕШЕНО
          --Инициализируем счетчик строк
          i_vfr_row_cnt<=i_vfr_row_cnt-1;
        end if;

        vfr_active_row_end:=i_vfr_size.activ.row - 1;

        fsm_state_cs <= S_ROW_FINED1;

      --------------------------------------
      --Ищем строку видео кадра
      --------------------------------------
      when S_ROW_FINED1 =>

        fsm_state_cs <= S_MEM_SET_ADR;

      --------------------------------------
      --Запускаем операцию чтения ОЗУ
      --------------------------------------
      when S_MEM_SET_ADR =>

        i_mem_ptr(i_mem_ptr'high downto G_MEM_VCH_M_BIT+1)<=(others=>'0');
        i_mem_ptr(G_MEM_VCH_M_BIT downto G_MEM_VCH_L_BIT)<=i_vch_num(G_MEM_VCH_M_BIT-G_MEM_VCH_L_BIT downto 0);
        i_mem_ptr(G_MEM_VFR_M_BIT downto G_MEM_VFR_L_BIT)<=i_vfr_buf;
        i_mem_ptr(G_MEM_VLINE_M_BIT downto G_MEM_VLINE_L_BIT)<=i_vfr_row_cnt(G_MEM_VLINE_M_BIT-G_MEM_VLINE_L_BIT downto 0);
        i_mem_ptr(G_MEM_VLINE_L_BIT-1 downto 0)<=i_vfr_size.skip.pix(G_MEM_VLINE_L_BIT-1-2 downto 0)&"00";--т.к. значение i_vfr_size.skip.pix в DW

        fsm_state_cs <= S_MEM_START;

      --------------------------------------
      --Запускаем операцию чтения ОЗУ
      --------------------------------------
      when S_MEM_START =>

        i_mem_adr<=i_mem_rdbase + i_mem_ptr;
        i_mem_dir<=C_MEMWR_READ;
        i_mem_start<='1';
        fsm_state_cs <= S_MEM_RD;

      ------------------------------------------------
      --Чтение данных
      ------------------------------------------------
      when S_MEM_RD =>

        i_mem_start<='0';

        if i_mem_done='1' then
        --//Операция выполнена
          fsm_state_cs <= S_ROW_NXT;
        end if;

      ------------------------------------------------
      --Ждем запроса на чтение следующей строки
      ------------------------------------------------
      when S_ROW_NXT =>

        if p_in_vfr_nrow='1' then

          if (i_vfr_mirror.row='0' and i_vfr_row_cnt=(i_vfr_size.skip.row + vfr_active_row_end)) or
             (i_vfr_mirror.row='1' and i_vfr_row_cnt=i_vfr_size.skip.row) then
              fsm_state_cs <= S_WAIT_HOST_ACK;
          else

            if i_vfr_mirror.row='1' then
              i_vfr_row_cnt<=i_vfr_row_cnt-1;
            else
              i_vfr_row_cnt<=i_vfr_row_cnt+1;
            end if;

            fsm_state_cs <= S_ROW_FINED1;
          end if;

        end if;
------------------  ROTATE=0 ----------------------------

      ------------------------------------------------
      --Ждем ответ от ХОСТА - данные принял
      ------------------------------------------------
      when S_WAIT_HOST_ACK =>

        if p_in_hrd_done='1' then
          i_vfr_done<='1';
          fsm_state_cs <= S_IDLE;
        end if;

    end case;
  end if;
end process;


--//------------------------------------------------------
--//Модуль записи/чтения данных ОЗУ (mem_ctrl.vhd)
--//------------------------------------------------------
m_mem_wr : mem_wr
generic map(
G_MEM_BANK_M_BIT => G_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => G_MEM_BANK_L_BIT,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_adr     => i_mem_adr,
p_in_cfg_mem_trn_len => i_mem_trn_len,
p_in_cfg_mem_dlen_rq => i_mem_dlen_rq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_start,
p_out_cfg_mem_done   => i_mem_done,

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout  => "00000000000000000000000000000000",
p_out_usr_txbuf_rd   => open,
p_in_usr_txbuf_empty => '0',

p_out_usr_rxbuf_din  => i_memd,
p_out_usr_rxbuf_wd   => i_memd_en,
p_in_usr_rxbuf_full  => i_vrow_buf_full_all,--p_in_upp_buf_full, --

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_mem,
p_in_mem             => p_in_mem,

-------------------------------
--System
-------------------------------
p_in_tst             => p_in_tst,
p_out_tst            => open,--tst_mem_ctrl_ch_wr_out,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);


--//------------------------------------------------------
--//Формирование/Контроль выходных данных
--//------------------------------------------------------
--Формирование данных для записи в выходной буфер
process(p_in_rst,p_in_clk)
  variable en_tmp : std_logic_vector(i_vrow_buf_dout'length-1 downto 0);
begin
  if p_in_rst='1' then
    for i in 0 to i_vrow_buf_dout'length-1 loop
      for x in 0 to i_memd'length/8-1 loop
        sr_memd(i)(x)<=(others=>'0');
      end loop;
    end loop;
      en_tmp:=(others=>'0');
    sr_memd_en<=(others=>'0');
    i_memd_count<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    en_tmp:=(others=>'0');

    if i_vfr_new='1' then
      i_memd_count<=(others=>'0');

    elsif i_memd_en='1' then

      if i_vfr_rotate.l='0' and i_vfr_rotate.r='0' then
        for i in 0 to i_memd'length/8-1 loop
          sr_memd(0)(i)<=i_memd(8*(i+1)-1 downto 8*i);
        end loop;
        i_memd_count<=(others=>'0');
        en_tmp(0):='1';
      else

        for i in 0 to i_vrow_buf_dout'length/(i_memd'length/8)-1 loop
          if i_memd_count=i then
            for x in 0 to i_memd'length/8-1 loop
              sr_memd(i_memd'length/8*i+x)<=i_memd(8*(x+1)-1 downto 8*x) & sr_memd(i_memd'length/8*i+x)(i_memd'length/8-1 downto 1);
            end loop;
          end if;
        end loop;

        if i_memd_count=CONV_STD_LOGIC_VECTOR(1, i_memd_count'length) then
          i_memd_count<=(others=>'0');
        else
          i_memd_count<=i_memd_count + 1;
        end if;

        if i_vfr_pix_cntbyte=CONV_STD_LOGIC_VECTOR(i_memd'length/8-1, i_vfr_pix_cntbyte'length) then
          en_tmp:=(others=>'1');
        end if;
      end if;
    end if;
    sr_memd_en<=en_tmp;
  end if;
end process;


--Буфера выходных данных
gen_buf : for i in 0 to i_vrow_buf_dout'length-1 generate
gen_dbyte : for x in 0 to i_memd'length/8-1 generate
i_vrow_buf_din(i)(8*(x+1)-1 downto 8*x)<=sr_memd(i)(x);
end generate gen_dbyte;
i_vrow_buf_wr(i)<=sr_memd_en(i);

i_vrow_buf_rd(i)<=not i_vrow_buf_empty(i) and not p_in_upp_buf_full when fsm_do_cs=S_DO_WORK and i_vrow_buf_num=i else '0';

m_vbuf_rotate : vbuf_rotate
port map(
din         => i_vrow_buf_din(i),
wr_en       => i_vrow_buf_wr(i),
--wr_clk      : IN  std_logic;

dout        => i_vrow_buf_dout(i),
rd_en       => i_vrow_buf_rd(i),
--rd_clk      : IN  std_logic;

empty       => i_vrow_buf_empty(i),
full        => open,
almost_full => open, --i_vrow_buf_full(i),
prog_full   => i_vrow_buf_full(i),

clk        => p_in_clk,
rst        => p_in_rst
);

end generate gen_buf;

i_vrow_buf_full_all<=OR_reduce(i_vrow_buf_full);

--Контроль выдачи выходных данных
process(p_in_rst,p_in_clk)
  variable update_cntpix : std_logic;
begin
  if p_in_rst='1' then
    fsm_do_cs <= S_DO_IDLE;
    i_vrow_buf_num<=(others=>'0');
    i_memd_out<=(others=>'0');
    i_memd_out_en<=(others=>'0');
    i_cntpix_out<=(others=>'0');
    i_cntrow_out<=(others=>'0');
      update_cntpix:='0';

  elsif p_in_clk'event and p_in_clk='1' then
      update_cntpix:='0';

    case fsm_do_cs is

      --------------------------------------
      --Исходное состояние
      --------------------------------------
      when S_DO_IDLE =>

        if i_vfr_new='1' then
          i_cntpix_out<=(others=>'0');
          i_cntrow_out<=(others=>'0');
          i_vrow_buf_num<=(others=>'0');
          fsm_do_cs <= S_DO_WORK;
        end if;

      --------------------------------------
      --Выдача данных в порт Upstream Port
      --------------------------------------
      when S_DO_WORK =>

        if i_vfr_rotate.l='0' and i_vfr_rotate.r='0' then
          i_vrow_buf_num<=(others=>'0');
          if i_vfr_done='1' then
            fsm_do_cs <= S_DO_IDLE;
          else
            if i_vrow_buf_rd(0)='1' then
              i_memd_out<=i_vrow_buf_dout(0);
            end if;
          end if;

        else

            for i in 0 to i_vrow_buf_dout'length-1 loop
              if i_vrow_buf_num=i then
                if i_vrow_buf_rd(i)='1' then
                  update_cntpix:='1';
                  i_memd_out<=i_vrow_buf_dout(i);
                end if;
              end if;
            end loop;

            if update_cntpix='1' then
              if i_cntpix_out=i_vfr_size.activ.pix-1 then
                if i_vrow_buf_num=CONV_STD_LOGIC_VECTOR(i_vrow_buf_dout'length-1, i_vrow_buf_num'length) then
                  i_vrow_buf_num<=(others=>'0');
                else
                  i_vrow_buf_num<=i_vrow_buf_num + 1;
                end if;
                i_cntpix_out<=(others=>'0');
                fsm_do_cs <= S_DO_NEXT;
              else
                i_cntpix_out<=i_cntpix_out + 1;
              end if;
            end if;

        end if;

      --------------------------------------
      --Ждем разрешения на выдачу следующей строки
      --------------------------------------
      when S_DO_NEXT =>

        if p_in_vfr_nrow='1' then
          if i_cntrow_out=i_vfr_size.activ.row-1 then
            i_cntrow_out<=(others=>'0');
            fsm_do_cs <= S_DO_IDLE;
          else
            i_cntrow_out<=i_cntrow_out + 1;
            fsm_do_cs <= S_DO_WORK;
          end if;
        end if;

      end case;

      i_memd_out_en<=i_vrow_buf_rd;
  end if;
end process;


p_out_upp_data<=i_memd_out;
p_out_upp_data_wd<=OR_reduce(i_memd_out_en);


--END MAIN
end behavioral;

