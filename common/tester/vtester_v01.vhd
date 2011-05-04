-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.07
-- Module Name : vtester_v01
--
-- Назначение/Описание :
--  Запись/Чтение регистров устройств
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

--library unisim;
--use unisim.vcomponents.all;
use work.vicg_common_pkg.all;
use work.prj_def.all;

entity vtester_v01 is
generic
(
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
p_in_dst_rdy         : in    std_logic;                     --//
--p_in_dst_clk         : in    std_logic;                     --//

-------------------------------
--Технологический
-------------------------------
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_tmrclk  : in    std_logic;  --//

p_in_clk     : in    std_logic;  --//
p_in_rst     : in    std_logic
);
end vtester_v01;

architecture behavioral of vtester_v01 is


signal i_cfg_adr_cnt                     : std_logic_vector(7 downto 0);

signal h_reg_ctrl                        : std_logic_vector(31 downto 0);
--signal h_reg_tst0                        : std_logic_vector(15 downto 0);
signal h_reg_t05us                       : std_logic_vector(7 downto 0);
signal h_reg_pix                         : std_logic_vector(15 downto 0);
signal h_reg_row                         : std_logic_vector(15 downto 0);
signal h_reg_row_dly_send                : std_logic_vector(15 downto 0);
signal h_reg_fr_dly_send                 : std_logic_vector(15 downto 0);

constant C_Tms                           : integer:=selval(10#1000#,10#2#, strcmp(G_SIM,"OFF"));
signal i_1us                             : std_logic;
signal i_cnt_05us                        : std_logic_vector(7 downto 0);
signal i_cnt_us                          : std_logic_vector(10 downto 0);
signal i_cnt_ms                          : std_logic_vector(7 downto 0);

signal i_send_data_mode                  : std_logic_vector(C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT-C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT downto 0);
constant C_DSN_TSTING_REG_CTRL_MODE_SIZE : integer:=C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT-C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT+1;

signal i_frame_ch_auto_bit               : std_logic;
--signal i_frame_gray_bit                  : std_logic;
--signal i_frame_set_mnl_bit               : std_logic;
signal i_frame_move                      : std_logic_vector(6 downto 0);
signal i_frtxd_2dw_cnt_bit               : std_logic;
signal i_fr_diagonal_bit                 : std_logic;
signal i_tst_data_sel_bit                : std_logic;

signal i_run_work_bit                    : std_logic;
signal i_run_work_bit_delay              : std_logic_vector(1 downto 0);

signal i_module_work                     : std_logic;
signal i_module_work_start               : std_logic;
signal i_module_work_stop                : std_logic;
signal i_module_work_stop_sync           : std_logic;
signal i_module_work_done                : std_logic;

type fsm_state is
(
  S_IDLE,
  S_WAIT_SYNC,
  S_VPKT_SEND_DLY,
  S_VPKT_HEADER,
  S_VPKT_PAYLOAD,
  S_VPKT_DONE,
  S_EXIT_CHECK
);
signal fsm_state_cs: fsm_state;

signal v_reg_pix                         : std_logic_vector(15 downto 0);
signal v_reg_row                         : std_logic_vector(15 downto 0);

signal i_pkt_header_cnt                  : std_logic_vector(3 downto 0);
signal i_pix_cnt                         : std_logic_vector(15 downto 0);
signal i_row_cnt                         : std_logic_vector(15 downto 0);
signal i_row_send_timer_dly              : std_logic_vector(15 downto 0);
signal i_pkt_send                        : std_logic;
signal i_vfr_send                        : std_logic;
signal i_vfr_pix                         : std_logic_vector(15 downto 0);
signal i_vfr_row                         : std_logic_vector(15 downto 0);
signal i_pkt_done                        : std_logic;

signal i_pkt_start                       : std_logic;
signal i_pkt_start_err                   : std_logic;
signal i_pkt_start_width_dly             : std_logic_vector(1 downto 0);

signal tmrclk_pkt_start                  : std_logic;
signal tmrclk_pkt_start_width            : std_logic;
signal tmrclk_pkt_start_width_cnt        : std_logic_vector(4 downto 0);
signal tmrclk_module_work                : std_logic;

signal i_frame_idx                       : std_logic_vector(3 downto 0);
signal i_frame_count                     : std_logic_vector(6 downto 0);
signal i_video_ch                        : std_logic_vector(3 downto 0);
signal v_frame_ch                        : std_logic_vector(1 downto 0);
signal i_frame_ch_mnl                    : std_logic_vector(1 downto 0);

signal i_pixdata_cnt                     : std_logic_vector(31 downto 0);

signal i_pkt_len                         : std_logic_vector(15 downto 0);
signal i_pkt_len_2DW                     : std_logic_vector(15 downto 0);
signal i_pkt_len_2DW_tmp                 : std_logic_vector(15 downto 0);

signal i_move_incr                       : std_logic_vector(3 downto 0);

signal tmp_color_gray                    : std_logic_vector(31 downto 0);
signal tmp2_color_gray                   : std_logic_vector(31 downto 0);
signal i_color_gray                      : std_logic_vector(31 downto 0);

signal i_dst_rdy                         : std_logic;
signal i_dst_rdy_sync                    : std_logic;

signal i_txdata_dout                     : std_logic_vector(31 downto 0);
signal i_txdata_dout_out                 : std_logic_vector(31 downto 0);
signal i_txdata_wd_out                   : std_logic;
--signal i_txdata_rdy_out                  : std_logic;

signal tst_pkt_start                 : std_logic;


--MAIN
begin


p_out_module_rdy    <= not i_module_work;
p_out_module_error  <= i_pkt_start_err;--'1' when i_txbuf_full_cnt/=CONV_STD_LOGIC_VECTOR(0, 16) else '0';

p_out_tst(0)<=tst_pkt_start;--//
p_out_tst(1)<=i_vfr_send;--//
p_out_tst(2)<=i_pkt_send;
p_out_tst(3)<='0';
p_out_tst(4)<=i_1us;
p_out_tst(31 downto 5)<=(others=>'0');

--//--------------------------------------------------
--//Конфигурирование модуля vtester_v01.vhd
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
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    h_reg_ctrl<=(others=>'0');
--    h_reg_tst0<=(others=>'0');
    h_reg_t05us<=(others=>'0');

    h_reg_pix<=(others=>'0');
    h_reg_row<=(others=>'0');

    h_reg_row_dly_send<=(others=>'0');
    h_reg_fr_dly_send<=(others=>'0');

  elsif p_in_host_clk'event and p_in_host_clk='1' then
    if p_in_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_CTRL_L, i_cfg_adr_cnt'length) then h_reg_ctrl(15 downto 0) <=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_CTRL_M, i_cfg_adr_cnt'length) then h_reg_ctrl(31 downto 16)<=p_in_cfg_txdata;

--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_TST0, i_cfg_adr_cnt'length)   then h_reg_tst0<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_T05_US, i_cfg_adr_cnt'length)   then h_reg_t05us<=p_in_cfg_txdata(h_reg_t05us'high downto 0);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_PIX, i_cfg_adr_cnt'length)            then h_reg_pix<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_ROW, i_cfg_adr_cnt'length)            then h_reg_row<=p_in_cfg_txdata;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_ROW_SEND_TIME_DLY, i_cfg_adr_cnt'length) then h_reg_row_dly_send<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_FR_SEND_TIME_DLY, i_cfg_adr_cnt'length)  then h_reg_fr_dly_send<=p_in_cfg_txdata;

        end if;
    end if;
  end if;
end process;

--//Чтение регистров
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    p_out_cfg_rxdata<=(others=>'0');
  elsif p_in_host_clk'event and p_in_host_clk='1' then
    if p_in_cfg_rd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_CTRL_L, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=h_reg_ctrl(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_CTRL_M, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=h_reg_ctrl(31 downto 16);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_TST0, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata(0)<=i_vfr_send or i_pkt_start_err or i_pkt_send;--h_reg_tst0;
                                                                                                      p_out_cfg_rxdata(p_out_cfg_rxdata'high downto 1)<=(others=>'0');
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_T05_US, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=EXT(h_reg_t05us, p_out_cfg_rxdata'length);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_PIX, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_pix;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_ROW, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_row;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_ROW_SEND_TIME_DLY, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=h_reg_row_dly_send;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_FR_SEND_TIME_DLY, i_cfg_adr_cnt'length)  then p_out_cfg_rxdata<=h_reg_fr_dly_send;

        end if;
    end if;
  end if;
end process;





--//Распределяем биты управления
i_send_data_mode        <=h_reg_ctrl(C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT downto C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT);
i_run_work_bit          <=h_reg_ctrl(C_DSN_TSTING_REG_CTRL_START_BIT);
i_frame_ch_mnl          <=h_reg_ctrl(C_DSN_TSTING_REG_CTRL_FRAME_CH_MSB_BIT downto C_DSN_TSTING_REG_CTRL_FRAME_CH_LSB_BIT);
i_frame_ch_auto_bit     <=h_reg_ctrl(C_DSN_TSTING_REG_CTRL_FRAME_CH_AUTO_BIT);
--i_frame_gray_bit        <=h_reg_ctrl(C_DSN_TSTING_REG_CTRL_FRAME_GRAY_BIT);
--i_frame_set_mnl_bit     <=h_reg_ctrl(C_DSN_TSTING_REG_CTRL_FRAME_SET_MNL_BIT);
i_frame_move(6 downto 0)<=h_reg_ctrl(C_DSN_TSTING_REG_CTRLM_FRAME_MOVE_MSB_BIT+16  downto C_DSN_TSTING_REG_CTRLM_FRAME_MOVE_LSB_BIT+16);

i_fr_diagonal_bit      <=h_reg_ctrl(C_DSN_TSTING_REG_CTRL_FRAME_DIAGONAL_BIT);
i_frtxd_2dw_cnt_bit    <=h_reg_ctrl(C_DSN_TSTING_REG_CTRL_FRTXD_2DW_CNT_BIT);
i_tst_data_sel_bit     <=h_reg_ctrl(C_DSN_TSTING_REG_CTRL_FRAME_TSTDATA_2_BIT);



--//Выделяем фронты из сигнала i_run_work_bit
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_run_work_bit_delay<=(others=>'0');
    i_module_work_start<='0';
    i_module_work_stop<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    i_run_work_bit_delay(0)<=i_run_work_bit;
    i_run_work_bit_delay(1)<=i_run_work_bit_delay(0);

    i_module_work_start<=   i_run_work_bit_delay(0) and not i_run_work_bit_delay(1);
    i_module_work_stop<=not i_run_work_bit_delay(0) and     i_run_work_bit_delay(1);
  end if;
end process;

--//Остановка генерации пакетов в режиме STREAM
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_module_work_stop_sync<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if i_module_work_stop='1' and i_send_data_mode=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_MODE_SEND_TXD_STREAM, i_send_data_mode'length) then
      i_module_work_stop_sync<='1';
    elsif i_module_work_done='1' then
      i_module_work_stop_sync<='0';
    end if;
  end if;
end process;

--//
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_pkt_start_err<='0';
  elsif p_in_clk'event and p_in_clk='1' then

    if i_vfr_send='1' and i_pkt_start='1' then
      i_pkt_start_err<='1';
    else
      i_pkt_start_err<='0';
    end if;
  end if;
end process;


--//Автомат формирования тестовых пакетов
fsm:process(p_in_rst,p_in_clk)
begin

if p_in_rst='1' then

  fsm_state_cs <= S_IDLE;

  v_reg_pix<=(others=>'0');
  v_reg_row<=(others=>'0');

  i_dst_rdy_sync<='0';

  i_module_work<='0';
  i_module_work_done<='0';

  i_pkt_header_cnt<=(others=>'0');
  i_pix_cnt<=(others=>'0');
  i_row_cnt<=(others=>'0');
  i_row_send_timer_dly<=(others=>'0');
  i_pkt_send<='0';
  i_pkt_done<='0';
  i_vfr_send<='0';

  i_pixdata_cnt<=(others=>'0');
  i_frame_idx<=(others=>'0');
  i_frame_count<=(others=>'0');
  i_move_incr<=(others=>'0');
  v_frame_ch<=(others=>'0');

elsif p_in_clk'event and p_in_clk='1' then
--  if clk_en='1' then

  i_dst_rdy_sync<=i_dst_rdy;

  case fsm_state_cs is

    when S_IDLE =>

      i_module_work_done<='0';
      i_pkt_header_cnt<=(others=>'0');
      i_pix_cnt<=(others=>'0');
      i_row_cnt<=(others=>'0');
      i_row_send_timer_dly<=(others=>'0');
      i_pkt_send<='0';
      i_pkt_done<='0';
      i_vfr_send<='0';

      i_pixdata_cnt<=(others=>'0');
      i_frame_idx<=(others=>'0');
      i_frame_count<=(others=>'0');
      i_move_incr<=(others=>'0');
      v_frame_ch<=(others=>'0');

      --//Ждем сигнала запуска от ХОСТА
      if i_module_work_start='1' then
        i_module_work<='1';
        i_frame_idx<=i_frame_idx+1;
        v_frame_ch<=i_frame_ch_mnl;
        v_reg_pix<=h_reg_pix;
        v_reg_row<=h_reg_row;

        i_vfr_send<='1';
        i_pkt_send<='1';
        fsm_state_cs <= S_VPKT_HEADER;
      end if;

    --//-------------------------------------
    --//Ждем сигнала отправки следующего пакета
    --//-------------------------------------
    when S_WAIT_SYNC =>

      if i_pkt_start='1' then
        fsm_state_cs <= S_VPKT_SEND_DLY;
      end if;

    --//-------------------------------------
    --//Задержка отправки между пакетами
    --//-------------------------------------
    when S_VPKT_SEND_DLY =>

      if i_row_send_timer_dly=h_reg_row_dly_send then
        i_row_send_timer_dly<=(others=>'0');
        i_vfr_send<='1';
        i_pkt_send<='1';
        fsm_state_cs <= S_VPKT_HEADER;
      else
        i_row_send_timer_dly<=i_row_send_timer_dly+1;
      end if;

    --//-------------------------------------
    --//Пердача заголовка пакета
    --//-------------------------------------
    when S_VPKT_HEADER =>

      if i_pkt_header_cnt=CONV_STD_LOGIC_VECTOR(C_VIDEO_PKT_HEADER_SIZE-1, i_pkt_header_cnt'length) then
        i_pkt_header_cnt<=(others=>'0');
        fsm_state_cs <= S_VPKT_PAYLOAD;
      else
        i_pkt_header_cnt<=i_pkt_header_cnt+1;
      end if;

    --//-------------------------------------
    --//Пердача данных payload (Тестовый Видео кадр)
    --//-------------------------------------
    when S_VPKT_PAYLOAD =>

      if i_pix_cnt(15 downto 0)=(v_reg_pix-1) then
        i_pix_cnt<=(others=>'0');
        i_pkt_done<='1';
        fsm_state_cs <= S_VPKT_DONE;
      else
        i_pix_cnt<=i_pix_cnt+1;
      end if;

--      if i_frame_gray_bit='1' then
--        i_pixdata_cnt<=i_pixdata_cnt + ("00000000"&"0000"& (i_tst_data_sel_bit) & (not i_tst_data_sel_bit) & "00");--//8/4
      i_pixdata_cnt<=i_pixdata_cnt + ("00000000"&"0000"& (i_tst_data_sel_bit and not i_frtxd_2dw_cnt_bit) & (not i_tst_data_sel_bit and not i_frtxd_2dw_cnt_bit) & '0' & i_frtxd_2dw_cnt_bit);--//8/4/1

    --//-------------------------------------
    --//Проверка конца кадра
    --//-------------------------------------
    when S_VPKT_DONE =>

      i_pkt_done<='0';

      if i_dst_rdy_sync='1' then
      --//Приемник готов к приему следующего пакета
        i_pkt_send<='0';
        i_pixdata_cnt<=(others=>'0');

        if i_row_cnt(15 downto 0)=(v_reg_row-1) then
          i_row_cnt<=(others=>'0');
          i_vfr_send<='0';
          fsm_state_cs <= S_EXIT_CHECK; --//Передал весь кадр
        else
          --//
          i_row_cnt<=i_row_cnt+1;
          fsm_state_cs <= S_VPKT_SEND_DLY; --//Переход к передаче следующей строки
        end if;
      end if;

    --//-------------------------------------
    --//Проверка остановки работы модуля
    --//-------------------------------------
    when S_EXIT_CHECK =>

      v_reg_pix<=h_reg_pix;--//Обновление параметров тестового кадра
      v_reg_row<=h_reg_row;

      i_frame_idx<=i_frame_idx+1;
      i_frame_count<=i_frame_count+1;
      v_frame_ch<=i_frame_ch_mnl;

      if i_frame_move(6 downto 0)="0000000" then
        i_move_incr<=(others=>'0');
      elsif i_frame_count(6 downto 0)=i_frame_move(6 downto 0) then
        i_frame_count<=(others=>'0');
        i_move_incr<=i_move_incr+1;
      end if;

      if (i_module_work_stop_sync='1' or i_send_data_mode=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_MODE_SEND_TXD_SINGL, i_send_data_mode'length)) then
        i_module_work_done<='1';
        i_module_work<='0';
        fsm_state_cs <= S_IDLE;
      else
        fsm_state_cs <= S_WAIT_SYNC;
      end if;

  end case;
--  end if;
end if;
end process fsm;


tmp2_color_gray(7 downto 0)  <=i_pixdata_cnt(7 downto 0);
tmp2_color_gray(15 downto 8) <=i_pixdata_cnt(7 downto 0) + ("000000"& i_tst_data_sel_bit & not i_tst_data_sel_bit);     --//2/1
tmp2_color_gray(23 downto 16)<=i_pixdata_cnt(7 downto 0) + ("00000" & i_tst_data_sel_bit & not i_tst_data_sel_bit &'0'); --//4/2;
tmp2_color_gray(31 downto 24)<=i_pixdata_cnt(7 downto 0) + ("00000" & i_tst_data_sel_bit & '1' & not i_tst_data_sel_bit); --//6/3;

tmp_color_gray(7 downto 0)  <=i_row_cnt(7 downto 0)+tmp2_color_gray(7 downto 0)   when i_fr_diagonal_bit='1' else tmp2_color_gray(7 downto 0);
tmp_color_gray(15 downto 8) <=i_row_cnt(7 downto 0)+tmp2_color_gray(15 downto 8)  when i_fr_diagonal_bit='1' else tmp2_color_gray(15 downto 8);
tmp_color_gray(23 downto 16)<=i_row_cnt(7 downto 0)+tmp2_color_gray(23 downto 16) when i_fr_diagonal_bit='1' else tmp2_color_gray(23 downto 16);
tmp_color_gray(31 downto 24)<=i_row_cnt(7 downto 0)+tmp2_color_gray(31 downto 24) when i_fr_diagonal_bit='1' else tmp2_color_gray(31 downto 24);

i_color_gray(7 downto 0)  <=tmp_color_gray(7 downto 0)   + (i_move_incr(3 downto 0)&"0000");
i_color_gray(15 downto 8) <=tmp_color_gray(15 downto 8)  + (i_move_incr(3 downto 0)&"0000");
i_color_gray(23 downto 16)<=tmp_color_gray(23 downto 16) + (i_move_incr(3 downto 0)&"0000");
i_color_gray(31 downto 24)<=tmp_color_gray(31 downto 24) + (i_move_incr(3 downto 0)&"0000");


--i_txdata_dout(31 downto 24)<="00000000" when i_frame_gray_bit='0' else i_color_gray(31 downto 24);
--i_txdata_dout(23 downto 0) <=i_color_gray(23 downto 0);
i_txdata_dout(31 downto 24)<=i_color_gray(31 downto 24);
i_txdata_dout(23 downto 0) <=i_color_gray(23 downto 0);

--//Размер в 2DW
i_pkt_len_2DW<=v_reg_pix(15 downto 0)+CONV_STD_LOGIC_VECTOR(C_VIDEO_PKT_HEADER_SIZE, 16);
--//Размер в BYTE
i_pkt_len_2DW_tmp<=i_pkt_len_2DW(13 downto 0)&"00";
i_pkt_len<=i_pkt_len_2DW_tmp-2;--//Вычетаю 2 байта т.к. Поле длиины (Len) в расчет не берется!!!

i_video_ch<="00"&v_frame_ch when i_frame_ch_auto_bit='0' else i_frame_idx;


i_vfr_pix<=v_reg_pix(13 downto 0)&"00";
i_vfr_row<=v_reg_row;

--//Выходной буфер
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_txdata_dout_out <=(others=>'0');
    i_txdata_wd_out   <='0';
  elsif p_in_clk'event and p_in_clk='1' then

    if fsm_state_cs=S_VPKT_HEADER then
      if    i_pkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#00#, i_pkt_header_cnt'length) then i_txdata_dout_out<=CONV_STD_LOGIC_VECTOR(16#A1#,8)&EXT(i_video_ch,4)&CONV_STD_LOGIC_VECTOR(16#01#,4)&i_pkt_len(15 downto 0);
      elsif i_pkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#01#, i_pkt_header_cnt'length) then i_txdata_dout_out<=EXT(i_vfr_pix,16)&EXT(i_frame_idx,16);
      elsif i_pkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#02#, i_pkt_header_cnt'length) then i_txdata_dout_out<=i_row_cnt&EXT(i_vfr_row,16);
      elsif i_pkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#03#, i_pkt_header_cnt'length) then i_txdata_dout_out<=CONV_STD_LOGIC_VECTOR(16#DDCC#,16)&CONV_STD_LOGIC_VECTOR(16#BBAA#,16);
      else                                                                               i_txdata_dout_out<=CONV_STD_LOGIC_VECTOR(16#1010#,16)&CONV_STD_LOGIC_VECTOR(16#FFEE#,16);
      end if;
      i_txdata_wd_out <='1';

    elsif fsm_state_cs=S_VPKT_PAYLOAD then

      if i_frtxd_2dw_cnt_bit='0' then
        i_txdata_dout_out<=i_txdata_dout;
      else
        i_txdata_dout_out<=i_pixdata_cnt;
      end if;

      i_txdata_wd_out <='1';
    else
      i_txdata_wd_out <='0';
    end if;

  end if;
end process;


i_dst_rdy<=p_in_dst_rdy;

p_out_dst_dout   <=i_txdata_dout_out;
p_out_dst_dout_wd<=i_txdata_wd_out;
p_out_dst_dout_rdy<=i_pkt_done;





--//------------------------------------------
--//Таймер отправки тестовых пакетов (p_in_tmrclk)
--//------------------------------------------
process(p_in_rst,p_in_tmrclk)
  variable a, b: std_logic;
  variable var_pkt_start: std_logic;
begin
  if p_in_rst='1' then
    i_cnt_05us<=(others=>'0');
    i_cnt_us<=(others=>'0');
    i_cnt_ms<=(others=>'0');
    a:='0';
    i_1us<='0';
    var_pkt_start:='0';
    tmrclk_pkt_start<='0';
    tmrclk_pkt_start_width<='0';
    tmrclk_pkt_start_width_cnt<=(others=>'0');

    tmrclk_module_work<='0';

    b:='0';
    tst_pkt_start<='0';
  elsif p_in_tmrclk'event and p_in_tmrclk='1' then
    var_pkt_start:='0';

    tmrclk_module_work<=i_module_work;

    if tmrclk_module_work='1' then
      if i_cnt_05us=h_reg_t05us then --CONV_STD_LOGIC_VECTOR(G_T05us-1, i_cnt_05us'length) then
        i_cnt_05us<=(others=>'0');
        a:= not a;
        i_1us<=a;
        if i_1us='1' then
          if i_cnt_us=CONV_STD_LOGIC_VECTOR((C_Tms-1), i_cnt_us'length) then
            i_cnt_us<=(others=>'0');

            if i_cnt_ms=h_reg_fr_dly_send(i_cnt_ms'high downto 0) then
              var_pkt_start:='1';
              i_cnt_ms<=(others=>'0');
            else
              i_cnt_ms<=i_cnt_ms+1;
            end if;
          else
            i_cnt_us<=i_cnt_us+1;
          end if;

        end if;
      else
        i_cnt_05us<=i_cnt_05us+1;
      end if;

    else
        i_cnt_05us<=(others=>'0');
        i_cnt_us<=(others=>'0');
        i_cnt_ms<=(others=>'0');
        a:='0';
        i_1us<='0';
        b:='0';
    end if;

    tmrclk_pkt_start<=var_pkt_start;
    if tmrclk_pkt_start='1' then
      b:= not b;
      tst_pkt_start<=b;
    end if;

    --//Растягиваем импульс для прерсинхронизации
    if tmrclk_pkt_start='1' then
      tmrclk_pkt_start_width<='1';
    elsif tmrclk_pkt_start_width_cnt(4)='1' then
      tmrclk_pkt_start_width<='0';
    end if;

    if tmrclk_pkt_start_width='0' then
      tmrclk_pkt_start_width_cnt<=(others=>'0');
    else
      tmrclk_pkt_start_width_cnt<=tmrclk_pkt_start_width_cnt+1;
    end if;
  end if;
end process;

--//Пересинхронизация + выделение фронта
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_pkt_start_width_dly<=(others=>'0');
    i_pkt_start<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    i_pkt_start_width_dly(0)<=tmrclk_pkt_start_width;
    i_pkt_start_width_dly(1)<=i_pkt_start_width_dly(0);

    i_pkt_start<=i_pkt_start_width_dly(0) and not i_pkt_start_width_dly(1);
  end if;

end process;

--END MAIN
end behavioral;

