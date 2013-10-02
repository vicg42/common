-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.06.2012 10:18:05
-- Module Name : video_reader
--
-- Назначение/Описание :
--  Чтение кадра видеоканала из ОЗУ
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

library work;
use work.vicg_common_pkg.all;
use work.prj_def.all;
use work.mem_wr_pkg.all;
use work.dsn_video_ctrl_pkg.all;

entity video_reader is
generic(
G_USR_OPT         : std_logic_vector(3 downto 0):=(others=>'0');
G_DBGCS           : string:="OFF";
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
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch     : in    TReaderVCHParams;
p_in_cfg_set_idle_vch: in    std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);

p_in_hrd_chsel       : in    std_logic_vector(3 downto 0);--Хост: номер видеоканала выбраного для чтения
p_in_hrd_start       : in    std_logic;                   --Хост: Запуск чтения кадра
p_in_hrd_done        : in    std_logic;                   --Хост: Подтверждение вычитки кадра

p_in_vfr_buf         : in    TVfrBufs;
p_in_vfr_nrow        : in    std_logic;                   --Разрешение чтения следующей строки

--Статусы
p_out_vch_fr_new     : out   std_logic;
p_out_vch_rd_done    : out   std_logic;
p_out_vch            : out   std_logic_vector(3 downto 0);
p_out_vch_active_pix : out   std_logic_vector(15 downto 0);
p_out_vch_active_row : out   std_logic_vector(15 downto 0);
p_out_vch_mirx       : out   std_logic;

----------------------------
--Upstream Port
----------------------------
p_out_upp_data       : out   std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
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

type fsm_state is (
S_IDLE,
S_LD_PRMS,
S_SET_PRMS,
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

signal i_vch_prm                     : TReaderVCHParam;
signal i_vch_num                     : std_logic_vector(p_in_hrd_chsel'range);
signal i_vfr_mirror                  : TFrXYMirror;
signal i_vfr_row_cnt                 : std_logic_vector(G_MEM_VLINE_M_BIT - G_MEM_VLINE_L_BIT downto 0);
signal i_vfr_skip_row                : std_logic_vector(i_vfr_row_cnt'range);
signal i_vfr_active_row              : std_logic_vector(i_vfr_row_cnt'range);
signal i_vfr_done                    : std_logic;
signal i_vfr_new                     : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0):=(others=>'1');
signal i_vfr_buf                     : std_logic_vector(C_VCTRL_MEM_VFR_M_BIT - C_VCTRL_MEM_VFR_L_BIT downto 0);
signal i_vfr_skip_pix_byte           : std_logic_vector(G_MEM_VLINE_L_BIT - 1 downto 0);
signal i_vfr_active_pix_byte         : std_logic_vector(15 downto 0);

signal i_vfr_new_cur                 : std_logic;
signal i_vfr_row_cnt_sv_cur          : std_logic_vector(i_vfr_row_cnt'range);
Type TVCH_row_cnt is array (0 to C_VCTRL_VCH_COUNT - 1) of std_logic_vector(i_vfr_row_cnt'range);
signal i_vfr_row_cnt_sv              : TVCH_row_cnt;
signal i_step_count                  : std_logic_vector(15 downto 0);
signal i_step_cnt                    : std_logic_vector(15 downto 0);

signal i_gnd                         : std_logic_vector(G_MEM_DWIDTH - 1 downto 0);

signal tst_fsmstate                  : std_logic_vector(3 downto 0);
signal tst_fsmstate_out              : std_logic_vector(3 downto 0);


--MAIN
begin


------------------------------------
--Технологические сигналы
------------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_tst(31 downto 0) <= (others=>'0');
end generate gen_dbgcs_off;

gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate
p_out_tst(3  downto 0) <= tst_fsmstate_out;
p_out_tst(4)           <= i_mem_start;
p_out_tst(31 downto 5) <= (others=>'0');

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    tst_fsmstate_out <= tst_fsmstate;
  end if;
end process;

tst_fsmstate <= CONV_STD_LOGIC_VECTOR(16#01#, tst_fsmstate'length) when fsm_state_cs = S_MEM_SET_ADR   else
                CONV_STD_LOGIC_VECTOR(16#02#, tst_fsmstate'length) when fsm_state_cs = S_MEM_START     else
                CONV_STD_LOGIC_VECTOR(16#03#, tst_fsmstate'length) when fsm_state_cs = S_MEM_RD        else
                CONV_STD_LOGIC_VECTOR(16#04#, tst_fsmstate'length) when fsm_state_cs = S_ROW_NXT       else
                CONV_STD_LOGIC_VECTOR(16#05#, tst_fsmstate'length) when fsm_state_cs = S_LD_PRMS       else
                CONV_STD_LOGIC_VECTOR(16#06#, tst_fsmstate'length) when fsm_state_cs = S_SET_PRMS      else
                CONV_STD_LOGIC_VECTOR(16#00#, tst_fsmstate'length); --fsm_state_cs = S_IDLE else
end generate gen_dbgcs_on;

i_gnd <= (others=>'0');


------------------------------------------------
--Статусы
------------------------------------------------
p_out_vch_rd_done <= i_vfr_done;
p_out_vch_fr_new <= '0';

--параметры чтения текущего кадра
p_out_vch <= i_vch_num;

p_out_vch_active_pix <= i_vfr_active_pix_byte;
p_out_vch_active_row <= EXT(i_vfr_active_row, p_out_vch_active_row'length);
p_out_vch_mirx       <= i_vfr_mirror.pix;


------------------------------------------------
--Автомат Чтения видео кадра
------------------------------------------------
--Логика работы автомата
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    fsm_state_cs <= S_IDLE;

    i_mem_rdbase <= (others=>'0');
    i_mem_ptr <= (others=>'0');
    i_mem_adr <= (others=>'0');
    i_mem_trn_len <= (others=>'0');
    i_mem_dlen_rq <= (others=>'0');
    i_mem_dir <= '0';
    i_mem_start <= '0';

    i_vfr_buf <= (others=>'0');
    i_vfr_mirror.pix <= '0';
    i_vfr_mirror.row <= '0';
    i_vfr_row_cnt <= (others=>'0');
    i_vfr_active_row <= (others=>'0');
    i_vfr_skip_row <= (others=>'0');
    i_vfr_skip_pix_byte <= (others=>'0');
    i_vfr_active_pix_byte <= (others=>'0');

    i_vch_num <= (others=>'0');
    i_vfr_done <= '0';
    i_vfr_new <= (others=>'1');

    for ch in 0 to C_VCTRL_VCH_COUNT - 1 loop
    i_vfr_row_cnt_sv(ch) <= (others=>'0');
    end loop;
    i_step_count <= (others=>'0');
    i_step_cnt <= (others=>'0');
    i_vfr_new_cur <= '0';
    i_vfr_row_cnt_sv_cur <= (others=>'0');

    i_vch_prm.mem_adr <= (others=>'0');
    i_vch_prm.fr_size.skip.pix <= (others=>'0');
    i_vch_prm.fr_size.skip.row <= (others=>'0');
    i_vch_prm.fr_size.activ.pix <= (others=>'0');
    i_vch_prm.fr_size.activ.row <= (others=>'0');
    i_vch_prm.fr_mirror.pix <= '0';
    i_vch_prm.fr_mirror.row <= '0';
    i_vch_prm.step_rd <= (others=>'0');

  else

    case fsm_state_cs is

      --------------------------------------
      --Исходное состояние
      --------------------------------------
      when S_IDLE =>

        i_vfr_done <= '0';
        i_step_cnt <= (others=>'0');
        i_mem_ptr <= (others=>'0');

        if p_in_hrd_start = '1' then

          i_vch_num <= p_in_hrd_chsel;
          fsm_state_cs <= S_LD_PRMS;

        end if;

      --------------------------------------
      --Загрузка параметров
      --------------------------------------
      when S_LD_PRMS =>

        --Загрузка праметров Видео канала
        for ch in 0 to C_VCTRL_VCH_COUNT - 1 loop
          if i_vch_num = ch then
            i_vch_prm <= p_in_cfg_prm_vch(ch);
            i_vfr_buf <= p_in_vfr_buf(ch);

            if i_vfr_new(ch) = '1' then
              i_vfr_new(ch) <= '0';
            end if;

            i_vfr_new_cur <= i_vfr_new(ch);
            i_vfr_row_cnt_sv_cur <= i_vfr_row_cnt_sv(ch);
          end if;
        end loop;

        fsm_state_cs <= S_SET_PRMS;

      --------------------------------------
      --Загрузка параметров
      --------------------------------------
      when S_SET_PRMS =>

          if i_vch_prm.step_rd = (i_vch_prm.step_rd'range => '0') then
          i_step_count <= i_vch_prm.fr_size.activ.row;
          else
          i_step_count <= i_vch_prm.step_rd;
          end if;

          ----------------------------
          --Банк ОЗУ:
          ----------------------------
          i_mem_rdbase <= i_vch_prm.mem_adr;

          ----------------------------
          --Отзеркаливание:
          ----------------------------
          i_vfr_mirror.pix <= i_vch_prm.fr_mirror.pix;
          i_vfr_mirror.row <= i_vch_prm.fr_mirror.row;

          ----------------------------
          --Пиксели:
          ----------------------------
          i_vfr_active_pix_byte <= i_vch_prm
                              .fr_size.activ.pix(i_vch_prm
                                                  .fr_size.activ.pix'high - 2 downto 0) & "00";

          i_vfr_skip_pix_byte <= i_vch_prm
                              .fr_size.skip.pix(G_MEM_VLINE_L_BIT - 1 - 2 downto 0) & "00";

          ----------------------------
          --Строки:
          ----------------------------
          i_vfr_active_row <= i_vch_prm.fr_size.activ.row(i_vfr_active_row'range);
          i_vfr_skip_row <= i_vch_prm.fr_size.skip.row(i_vfr_skip_row'range);

          --Инициализируем счетчик строк
          if i_vfr_new_cur = '1' then

              if i_vch_prm.fr_mirror.row = '0' then
                i_vfr_row_cnt <= (others=>'0');
              else
                i_vfr_row_cnt <= i_vch_prm.fr_size.activ.row(i_vfr_row_cnt'range) - 1;
              end if;

          else

            i_vfr_row_cnt <= i_vfr_row_cnt_sv_cur;

          end if;

        fsm_state_cs <= S_MEM_SET_ADR;

      --------------------------------------
      --Запускаем операцию чтения ОЗУ
      --------------------------------------
      when S_MEM_SET_ADR =>

        i_mem_ptr(G_MEM_VCH_M_BIT downto G_MEM_VCH_L_BIT) <= i_vch_num(G_MEM_VCH_M_BIT
                                                                        - G_MEM_VCH_L_BIT downto 0);
        i_mem_ptr(G_MEM_VFR_M_BIT downto G_MEM_VFR_L_BIT) <= i_vfr_buf;
        i_mem_ptr(G_MEM_VLINE_M_BIT downto G_MEM_VLINE_L_BIT) <= i_vfr_skip_row + i_vfr_row_cnt;
        i_mem_ptr(G_MEM_VLINE_L_BIT - 1 downto 0) <= i_vfr_skip_pix_byte;

        fsm_state_cs <= S_MEM_START;

      --------------------------------------
      --Запускаем операцию чтения ОЗУ
      --------------------------------------
      when S_MEM_START =>

        --(Кол-во запрашиваемых данных должен быть равен размеру одной строки)
        i_mem_dlen_rq <= EXT(i_vfr_active_pix_byte(i_vfr_active_pix_byte'high downto log2(G_MEM_DWIDTH/8))
                                                                                , i_mem_dlen_rq'length)
                         + OR_reduce(i_vfr_active_pix_byte(log2(G_MEM_DWIDTH/8) - 1 downto 0));

        i_mem_trn_len <= EXT(p_in_cfg_mem_trn_len, i_mem_trn_len'length);
        i_mem_adr <= i_mem_rdbase + i_mem_ptr;
        i_mem_dir <= C_MEMWR_READ;
        i_mem_start <= '1';
        fsm_state_cs <= S_MEM_RD;

      ------------------------------------------------
      --Чтение данных
      ------------------------------------------------
      when S_MEM_RD =>

        i_mem_start <= '0';

        if i_mem_done = '1' then
        --Операция выполнена
          fsm_state_cs <= S_ROW_NXT;
        end if;

      ------------------------------------------------
      --Ждем запроса на чтение следующей строки
      ------------------------------------------------
      when S_ROW_NXT =>

        if p_in_vfr_nrow = '1' then

          if (i_vfr_mirror.row = '0' and i_vfr_row_cnt = (i_vfr_active_row - 1)) or
             (i_vfr_mirror.row = '1' and i_vfr_row_cnt = (i_vfr_row_cnt'range => '0')) then

              for ch in 0 to C_VCTRL_VCH_COUNT - 1 loop
                if i_vch_num = ch then
                  i_vfr_new(ch) <= '1';
                end if;
              end loop;

              fsm_state_cs <= S_WAIT_HOST_ACK;

          else

              if i_step_cnt = i_step_count - 1 then

                  for ch in 0 to C_VCTRL_VCH_COUNT - 1 loop
                    if i_vch_num = ch then
                      if i_vfr_mirror.row = '1' then
                        i_vfr_row_cnt_sv(ch) <= i_vfr_row_cnt - 1;
                      else
                        i_vfr_row_cnt_sv(ch) <= i_vfr_row_cnt + 1;
                      end if;
                    end if;
                  end loop;

                  fsm_state_cs <= S_IDLE;

              else
                  if i_vfr_mirror.row = '1' then
                    i_vfr_row_cnt <= i_vfr_row_cnt - 1;
                  else
                    i_vfr_row_cnt <= i_vfr_row_cnt + 1;
                  end if;

                  i_step_cnt <= i_step_cnt + 1;

                  fsm_state_cs <= S_MEM_SET_ADR;
              end if;

          end if;
        end if;

      ------------------------------------------------
      --Ждем ответ от ХОСТА - vframe принял
      ------------------------------------------------
      when S_WAIT_HOST_ACK =>

        if p_in_hrd_done = '1' then
          i_vfr_done <= '1';
          fsm_state_cs <= S_IDLE;
        end if;

    end case;
  end if;
end if;
end process;


--------------------------------------------------------
--Модуль записи/чтения данных ОЗУ (mem_ctrl.vhd)
--------------------------------------------------------
m_mem_wr : mem_wr
generic map(
G_USR_OPT        => G_USR_OPT,
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
p_in_usr_txbuf_dout  => i_gnd,
p_out_usr_txbuf_rd   => open,
p_in_usr_txbuf_empty => '0',

p_out_usr_rxbuf_din  => p_out_upp_data,
p_out_usr_rxbuf_wd   => p_out_upp_data_wd,
p_in_usr_rxbuf_full  => p_in_upp_buf_full,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_mem,
p_in_mem             => p_in_mem,

-------------------------------
--System
-------------------------------
p_in_tst             => p_in_tst,
p_out_tst            => open,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);



--END MAIN
end behavioral;


