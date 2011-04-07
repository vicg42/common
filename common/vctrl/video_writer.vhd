-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.06
-- Module Name : video_writer
--
-- Назначение/Описание :
--  Запись строк видеоканалов в видеобуфера ОЗУ
--  В результате в разных облостях ОЗУ формируется кадры для
--  соответствующего видео канала
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
use work.memory_ctrl_pkg.all;
use work.dsn_video_ctrl_pkg.all;


entity video_writer is
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
p_in_cfg_load         : in    std_logic;                   --//Загрузка параметров записи
p_in_cfg_mem_trn_len  : in    std_logic_vector(7 downto 0);--//Размер одиночной транзакции MEM_WR
p_in_cfg_prm_vch      : in    TWriterVCHParams;            --//Параметры записи видео каналов
p_in_cfg_set_idle_vch : in    std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);

p_in_vfr_buf          : in    TVfrBufs;                    --//Номер буфера где будет формироваться текущий кадр

--//Статусы
p_out_vfr_rdy         : out   std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);--//Кадр готов для соответствующего видеоканала
p_out_vrow_mrk        : out   TVMrks;                      --//Маркер строки

--//--------------------------
--//Upstream Port (Связь с буфером видеопакетов)
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
p_out_memarb_req      : out   std_logic;                    --//Запрос к арбитру ОЗУ на выполнение транзакции
p_in_memarb_en        : in    std_logic;                    --//Разрешение арбитра

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
end video_writer;

architecture behavioral of video_writer is

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

type fsm_state is
(
S_IDLE,
S_PKT_HEADER_READ,
S_MEM_CTRL_SEL_BANK,
S_MEM_CALC_REMAIN_SIZE,
S_MEM_TRN_LEN_CALC,
S_MEM_SET_ADR,
S_MEM_WAIT_RQ_EN,
S_MEM_SET_ADR_DONE,
S_MEM_TRN,
S_MEM_TRN_END,
S_EXIT
);
signal fsm_state_cs: fsm_state;

signal i_cfg_prm_vch               : TWriterVCHParams;

signal i_vfr_mem_adr               : std_logic_vector(G_MEM_BANK_MSB_BIT downto 0);
type TWFrXYParam is record
pix : std_logic_vector(G_MEM_VROW_LSB_BIT downto 0);
row : std_logic_vector(G_MEM_VFRAME_LSB_BIT-G_MEM_VROW_LSB_BIT downto 0);
end record;
signal i_vfr_zone_skip             : TWFrXYParam;
signal i_vfr_zone_active           : TWFrXYParam;
signal i_vfr_subsampling           : std_logic_vector(1 downto 0);--//необходим для режима прореживания
signal i_vfr_actzone_row_cnt       : std_logic_vector(1 downto 0);--//необходим для режима прореживания
signal i_vfr_row_mrk               : TVMrks;
signal tmp_vfr_row_mrk_low         : std_logic_vector(15 downto 0);

signal i_vpkt_cnt                  : std_logic_vector(15 downto 0);
signal i_vpkt_header_rd            : std_logic;
signal i_vpkt_payload_rd           : std_logic;
signal i_vpkt_total_len2dw         : std_logic_vector(i_vpkt_cnt'high downto 0);
signal i_vpkt_data_len             : std_logic_vector(i_vpkt_cnt'high downto 0);
signal i_vpkt_data_readed          : std_logic_vector(i_vpkt_cnt'high downto 0);
signal i_vpkt_data_remain          : std_logic_vector(i_vpkt_cnt'high downto 0);

signal i_vfr_pix_count             : std_logic_vector(15 downto 0);
signal i_vfr_row_count             : std_logic_vector(15 downto 0);
Type TVfrNum is array (0 to C_DSN_VCTRL_VCH_COUNT-1) of std_logic_vector(3 downto 0);
signal i_vfr_num                   : TVfrNum;
signal i_vfr_row                   : std_logic_vector(15 downto 0);
signal i_vch_num                   : std_logic_vector(3 downto 0);
signal i_vfr_vld                   : std_logic;
signal i_vfr_row_en                : std_logic;
signal i_vfr_actzone_row           : std_logic;
signal i_vfr_actzone_row_en        : std_logic;
Type TRowCntVCH is array (0 to C_DSN_VCTRL_VCH_MAX_COUNT-1) of std_logic_vector(1 downto 0);
signal i_vfr_actzone_row_cnts       : TRowCntVCH;--//необходим для режима прореживания
signal i_vfr_pix_en                : std_logic;
signal i_vfr_actzone_pix           : std_logic;
signal i_vfr_actzone_pix_en        : std_logic;
signal i_vfr_actzone_pix_cnt       : std_logic_vector(1 downto 0);--//необходим для режима прореживания
signal i_vfr_rdy                   : std_logic_vector(p_out_vfr_rdy'range);
signal i_vfr_zone_active_pix_end   : std_logic_vector(i_vpkt_cnt'range);
signal i_vfr_zone_active_row_end   : std_logic_vector(i_vfr_row'range);

signal i_memtrn_zone_skip_pix_start: std_logic_vector(i_vfr_zone_active.pix'high downto 0);
signal i_mem_din_out               : std_logic_vector(p_in_upp_data'range);
signal i_mem_trn_len_cnt           : std_logic_vector(i_vpkt_cnt'high downto 0);
signal i_mem_adr_update            : std_logic;
signal i_mem_bank1h_out            : std_logic_vector(pwr((G_MEM_BANK_MSB_BIT-G_MEM_BANK_LSB_BIT+1), 2)-1 downto 0);
signal i_mem_adr_out               : std_logic_vector(G_MEM_BANK_LSB_BIT-1 downto 0);
signal i_mem_ce_out                : std_logic;
signal i_mem_arb_req               : std_logic;

signal upp_buf_pfull               : std_logic;
signal upp_data_rd_out             : std_logic;
signal upp_hd_data_rd_out          : std_logic;
signal upp_pldvld_data_rd_out      : std_logic;

signal i_upp_data_save             : std_logic_vector(23 downto 0);
signal i_upp_data                  : std_logic_vector(31 downto 0);

signal tst_dcount                  : std_logic_vector(31 downto 0);
signal tst_dbg_dcount              : std_logic;

--signal tst_fsmstate                : std_logic_vector(3 downto 0);
--signal tst_fsmstate_dly            : std_logic_vector(3 downto 0);
--signal tst_dbg_pictire            : std_logic;


--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    tst_fsmstate_dly<=(others=>'0');
--    p_out_tst(0)<='0';
--  elsif p_in_clk'event and p_in_clk='1' then
--    tst_fsmstate_dly<=tst_fsmstate;
--    p_out_tst(0)<=OR_reduce(tst_fsmstate_dly);
--  end if;
--end process;
--p_out_tst(31 downto 1)<=(others=>'0');

--tst_fsmstate<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsmstate'length) when fsm_state_cs=S_PKT_HEADER_READ else
--              CONV_STD_LOGIC_VECTOR(16#02#,tst_fsmstate'length) when fsm_state_cs=S_MEM_CTRL_SEL_BANK else
--              CONV_STD_LOGIC_VECTOR(16#03#,tst_fsmstate'length) when fsm_state_cs=S_MEM_CALC_REMAIN_SIZE else
--              CONV_STD_LOGIC_VECTOR(16#04#,tst_fsmstate'length) when fsm_state_cs=S_MEM_TRN_LEN_CALC else
--              CONV_STD_LOGIC_VECTOR(16#05#,tst_fsmstate'length) when fsm_state_cs=S_MEM_SET_ADR else
--              CONV_STD_LOGIC_VECTOR(16#06#,tst_fsmstate'length) when fsm_state_cs=S_MEM_WAIT_RQ_EN else
--              CONV_STD_LOGIC_VECTOR(16#07#,tst_fsmstate'length) when fsm_state_cs=S_MEM_SET_ADR_DONE else
--              CONV_STD_LOGIC_VECTOR(16#08#,tst_fsmstate'length) when fsm_state_cs=S_MEM_TRN else
--              CONV_STD_LOGIC_VECTOR(16#09#,tst_fsmstate'length) when fsm_state_cs=S_MEM_TRN_END else
--              CONV_STD_LOGIC_VECTOR(16#0A#,tst_fsmstate'length) when fsm_state_cs=S_EXIT else
--              CONV_STD_LOGIC_VECTOR(16#00#,tst_fsmstate'length); --//fsm_state_cs=S_IDLE else

p_out_tst(31 downto 0)<=(others=>'0');


process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_dcount<=CONV_STD_LOGIC_VECTOR(1, tst_dcount'length);
  elsif p_in_clk'event and p_in_clk='1' then
    if tst_dbg_dcount='1' then
      if fsm_state_cs = S_MEM_CTRL_SEL_BANK then
        tst_dcount<=CONV_STD_LOGIC_VECTOR(1, tst_dcount'length);

      elsif i_vpkt_payload_rd='1' and i_vfr_vld='1' and p_in_upp_buf_empty='0' and p_in_mem_wpf='0' then
        tst_dcount<=tst_dcount + 1;
      end if;
    end if;
  end if;
end process;
tst_dbg_dcount<=p_in_tst(C_DSN_VCTRL_REG_TST0_DBG_DCOUNT_BIT);
i_upp_data<=p_in_upp_data when tst_dbg_dcount='0' else tst_dcount;

----//для отладки обработки видео.
----//Запрещение записи любого кадра в VFRBUF
--tst_dbg_pictire<=p_in_tst(C_DSN_VCTRL_REG_TST0_DBG_PICTURE_BIT);


--//----------------------------------------------
--//Статусы
--//----------------------------------------------
p_out_vfr_rdy<=i_vfr_rdy;--//Прерывание: кадр записан в ОЗУ
p_out_vrow_mrk<=i_vfr_row_mrk;--//Маркер строки видеокадра


--//----------------------------------------------
--//Связь с буфером видео пакетов
--//Вычитка пакета видео информации
--//----------------------------------------------
p_out_upp_data_rd<=upp_data_rd_out;

upp_data_rd_out<=upp_hd_data_rd_out or upp_pldvld_data_rd_out or
                 (i_vpkt_payload_rd and not i_vfr_vld and not p_in_upp_buf_empty);
upp_hd_data_rd_out    <=(i_vpkt_header_rd  and not p_in_upp_buf_empty);
upp_pldvld_data_rd_out<=(i_vpkt_payload_rd and     i_vfr_vld and not p_in_upp_buf_empty and not p_in_mem_wpf);


--//----------------------------------------------
--//Связь с контроллером памяти
--//Запись видеоинформации в ОЗУ
--//----------------------------------------------
p_out_memarb_req<=i_mem_arb_req; --//Запрос на выполнение транзакции записи к арбитру модуля DSN_VCTRL.VHD

p_out_mem_clk  <=p_in_clk;

p_out_mem_adr<=EXT(i_mem_adr_out(i_mem_adr_out'high downto 2), p_out_mem_adr'length);
p_out_mem_bank1h<=EXT(i_mem_bank1h_out, p_out_mem_bank1h'length);

p_out_mem_be  <=(others=>'1');
p_out_mem_rd  <='0';
p_out_mem_cw  <='1';

p_out_mem_din <= i_mem_din_out;

--//Выходной буфер для сигналов memory_cntr.vhd
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_mem_din_out  <=(others=>'0');

    i_mem_adr_out<=(others=>'0');

    p_out_mem_ce   <='0';
    p_out_mem_wr   <='0';
    p_out_mem_term <='0';

    i_upp_data_save<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

--    i_mem_din_out(7 downto 0)  <=p_in_upp_data(15 downto 8); --//Byte0
--    i_mem_din_out(15 downto 8) <=p_in_upp_data(7 downto 0);  --//Byte1
--    i_mem_din_out(23 downto 16)<=p_in_upp_data(31 downto 24);--//Byte2
--    i_mem_din_out(31 downto 24)<=p_in_upp_data(23 downto 16);--//Byte3

    --//Данные записи в ОЗУ
    if i_vfr_subsampling="00" then
    --//Прореживаня НЕТ
        i_mem_din_out <=i_upp_data;--p_in_upp_data;

    elsif i_vfr_subsampling="01" then
    --//Прореживание ЕСТЬ: берем каждый 2-ой пиксель

        --//Для случая 1Pix=8bit
        if i_vfr_actzone_pix_cnt(0)='1' then
        --//Запись DWORD в ОЗУ
          i_mem_din_out(31 downto 24)<= i_upp_data(31 downto 24);--p_in_upp_data(31 downto 24);
          i_mem_din_out(23 downto 16)<= i_upp_data(15 downto 8);--p_in_upp_data(15 downto 8);
          i_mem_din_out(15 downto 8) <= i_upp_data_save(15 downto 8);
          i_mem_din_out(7 downto 0)  <= i_upp_data_save(7 downto 0);
        else
        --//Собираем DWORD для записи в ОЗУ
          i_upp_data_save(15 downto 8)<= i_upp_data(31 downto 24);--p_in_upp_data(31 downto 24);
          i_upp_data_save(7 downto 0) <= i_upp_data(15 downto 8);--p_in_upp_data(15 downto 8);
        end if;

    elsif i_vfr_subsampling="10" then
    --//Прореживание ЕСТЬ: берем каждый 4-ый пиксель

        --//Для случая 1Pix=8bit
        if i_vfr_actzone_pix_cnt(1 downto 0)="11" then
        --//Запись DWORD в ОЗУ
          i_mem_din_out(31 downto 24)<= i_upp_data(31 downto 24);--p_in_upp_data(31 downto 24);
          i_mem_din_out(23 downto 16)<= i_upp_data_save(23 downto 16);
          i_mem_din_out(15 downto 8) <= i_upp_data_save(15 downto 8);
          i_mem_din_out(7 downto 0)  <= i_upp_data_save(7 downto 0);

        --//Собираем DWORD для записи в ОЗУ:
        elsif i_vfr_actzone_pix_cnt(1 downto 0)="10" then
          i_upp_data_save(23 downto 16) <= i_upp_data(31 downto 24);--p_in_upp_data(31 downto 24);
        elsif i_vfr_actzone_pix_cnt(1 downto 0)="01" then
          i_upp_data_save(15 downto 8) <= i_upp_data(31 downto 24);--p_in_upp_data(31 downto 24);
        else
          i_upp_data_save(7 downto 0) <= i_upp_data(31 downto 24);--p_in_upp_data(31 downto 24);
        end if;
    end if;

    i_mem_adr_out<=i_vfr_mem_adr(i_mem_adr_out'high downto 0);

    p_out_mem_ce <=i_mem_ce_out;
    p_out_mem_wr <=i_vpkt_payload_rd and i_vfr_vld and not p_in_upp_buf_empty and not p_in_mem_wpf;

    --//add now
    if i_vpkt_payload_rd='1' and i_vfr_vld='1' and p_in_upp_buf_empty='0' and p_in_mem_wpf='0' and
    (i_vpkt_data_readed = EXT(i_vfr_zone_active_pix_end, i_vpkt_cnt'length) or i_vpkt_cnt = (i_vpkt_cnt'range => '0')) then
      p_out_mem_term <='1';
    else
      p_out_mem_term <='0';
    end if;

  end if;
end process;


--//Разрешение записи видеокадра в ОЗУ
i_vfr_vld<=i_vfr_row_en and i_vfr_pix_en;

----//Без режима прореживания
--i_vfr_row_en<=i_vfr_actzone_row;
--i_vfr_pix_en<=i_vfr_actzone_pix;
--i_vfr_actzone_pix_cnt<=(others=>'0');
--gen_subs_off : for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
--begin
--i_vfr_actzone_row_cnts(i)<=(others=>'0');
--end generate gen_subs_off;


--//C режимом прореживания
--i_vfr_row_en<=i_vfr_actzone_row and i_vfr_actzone_row_en and not tst_dbg_pictire;
i_vfr_row_en<=i_vfr_actzone_row and i_vfr_actzone_row_en;
i_vfr_pix_en<=i_vfr_actzone_pix and i_vfr_actzone_pix_en;

--//Разрешение пиксел/строк в зависимости от режима прореживания
--//x00 - нет прореживания
--//x01 - берем каждый 4-ый пиксель и каждую 4-ю строку
--//x02 - берем каждый 2-ый пиксель и каждую 2-ю строку
i_vfr_actzone_pix_en<='1' when i_vfr_subsampling="00" else
                      '1' when i_vfr_subsampling="01" and i_vfr_actzone_pix_cnt(0)='1' else
                      '1' when i_vfr_subsampling="10" and i_vfr_actzone_pix_cnt(1 downto 0)="11" else
                      '0';

i_vfr_actzone_row_en<='1' when i_vfr_subsampling="00" else
                      '1' when i_vfr_subsampling="01" and i_vfr_actzone_row_cnt(0)='1' else
                      '1' when i_vfr_subsampling="10" and i_vfr_actzone_row_cnt(1 downto 0)="11" else
                      '0';

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to C_DSN_VCTRL_VCH_MAX_COUNT-1 loop
      i_vfr_actzone_row_cnts(i)<=(others=>'0');
    end loop;
    i_vfr_actzone_pix_cnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

      --//Счетчик прореживания по строкам
      for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
          if p_in_cfg_set_idle_vch(i)='1' or i_vfr_rdy(i)='1' then
          --//Сигнал p_in_cfg_set_idle_vch(i) нужно назначать только при отключеном видеопотоке,
          --//(отключение видео потока через фильтр пакетов в модуле dsn_switch.vhd)
            i_vfr_actzone_row_cnts(i)<=(others=>'0');

          elsif fsm_state_cs=S_EXIT and i_vfr_actzone_row='1' then
          --//Находимся в активной зоне по строкам
            i_vfr_actzone_row_cnts(i)<=i_vfr_actzone_row_cnts(i)+1;
          end if;
      end loop; --//for

      --//Счетчик прореживания по пикселям
      if fsm_state_cs=S_EXIT then
        i_vfr_actzone_pix_cnt<=(others=>'0');

      elsif fsm_state_cs=S_MEM_TRN then
        if upp_data_rd_out='1' then
          if i_vfr_actzone_pix='1'then
            i_vfr_actzone_pix_cnt<=i_vfr_actzone_pix_cnt+1;
          end if;
        end if;
      end if;

  end if;
end process;



--//----------------------------------------------
--//Автомат записи видео информации
--//----------------------------------------------
i_vfr_zone_active_row_end<=EXT(i_vfr_zone_skip.row, i_vfr_zone_active_row_end'length) + EXT(i_vfr_zone_active.row, i_vfr_zone_active_row_end'length);
i_vfr_zone_active_pix_end<=EXT(i_vfr_zone_skip.pix, i_vfr_zone_active_pix_end'length) + EXT(i_vfr_zone_active.pix, i_vfr_zone_active_pix_end'length);

process(p_in_rst,p_in_clk)
  variable var_update_addr : std_logic_vector(i_vpkt_cnt'length+1 downto 0);
  variable var_dlen        : std_logic_vector(i_vpkt_cnt'length-1 downto 0);
  variable var_temp        : std_logic;
  variable var_vfr_rdy     : std_logic_vector(p_out_vfr_rdy'range);
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;

    var_update_addr:=(others=>'0');
    i_vpkt_cnt<=(others=>'0');
    i_vpkt_header_rd<='0';
    i_vpkt_payload_rd<='0';
    i_vpkt_total_len2dw<=(others=>'0');
    i_vpkt_data_len<=(others=>'0');
    i_vpkt_data_readed<=(others=>'0');
    i_vpkt_data_remain<=(others=>'0');

    i_vch_num<=(others=>'0');
    for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
      i_cfg_prm_vch(i).mem_adr<=(others=>'0');
      i_cfg_prm_vch(i).fr_size.skip.pix<=(others=>'0');
      i_cfg_prm_vch(i).fr_size.skip.row<=(others=>'0');
      i_cfg_prm_vch(i).fr_size.activ.pix<=(others=>'0');
      i_cfg_prm_vch(i).fr_size.activ.row<=(others=>'0');
      i_cfg_prm_vch(i).fr_subsampling<=(others=>'0');

      i_vfr_num(i)<=(others=>'0');
      i_vfr_row_mrk(i)<=(others=>'0');
    end loop;

    i_vfr_row<=(others=>'0');
    i_vfr_mem_adr<=(others=>'0');
    i_vfr_zone_skip.pix<=(others=>'0');
    i_vfr_zone_skip.row<=(others=>'0');
    i_vfr_zone_active.pix<=(others=>'0');
    i_vfr_zone_active.row<=(others=>'0');
    i_vfr_subsampling<=(others=>'0');
    i_vfr_actzone_row_cnt<=(others=>'0');

    i_vfr_pix_count<=(others=>'0');
    i_vfr_row_count<=(others=>'0');
    tmp_vfr_row_mrk_low<=(others=>'0');
    i_vfr_rdy<=(others=>'0');
    i_vfr_actzone_row<='0';
    i_vfr_actzone_pix<='0';
    i_memtrn_zone_skip_pix_start<=(others=>'0');

    i_mem_adr_update<='0';
    i_mem_bank1h_out<=(others=>'0');
    i_mem_ce_out<='0';
    i_mem_trn_len_cnt<=(others=>'0');
    i_mem_arb_req<='0';

    var_dlen:=(others=>'0');
    var_temp:='0';

    upp_buf_pfull<='0';

  elsif p_in_clk'event and p_in_clk='1' then
  --  if clk_en='1' then
    var_temp:='0';
    var_vfr_rdy:=(others=>'0');

    upp_buf_pfull<=p_in_upp_buf_pfull;

    case fsm_state_cs is

      --//------------------------------------
      --//Исходное состояние
      --//------------------------------------
      when S_IDLE =>

        --//Загрузка праметров Видео канала
        if p_in_cfg_load='1' then
          for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
            i_cfg_prm_vch(i).mem_adr<=p_in_cfg_prm_vch(i).mem_adr;
            i_cfg_prm_vch(i).fr_size.skip<=p_in_cfg_prm_vch(i).fr_size.skip;
            i_cfg_prm_vch(i).fr_size.activ<=p_in_cfg_prm_vch(i).fr_size.activ;
            i_cfg_prm_vch(i).fr_subsampling<=p_in_cfg_prm_vch(i).fr_subsampling;
          end loop;

        end if;

        --//Ждем когда появятся данные в буфере
        if upp_buf_pfull='1' then --//if p_in_upp_buf_empty='0' and upp_buf_pfull='1' then
        --//Ждем когда в входном буфере накопится нужное кол-во данных (0x40 DWORD)

          i_vpkt_header_rd<='1';
          --//Загружаем в счетчик размер Заголовка пакета видео данных (в DWORD)
          i_vpkt_cnt<=CONV_STD_LOGIC_VECTOR(C_VIDEO_PKT_HEADER_SIZE-1, i_vpkt_cnt'length);

          fsm_state_cs <= S_PKT_HEADER_READ;
        end if;

      --//------------------------------------
      --//Чтение и анализ заголовка пакета видеоданных
      --//------------------------------------
      when S_PKT_HEADER_READ =>

        if upp_data_rd_out='1' then

          if i_vpkt_cnt=(i_vpkt_cnt'range =>'0') then
          --//----------------------------------------
          --//----- Прочитал весь заголовок ----------
          --//----------------------------------------

            i_vpkt_header_rd<='0';
            --//Расчет кол-ва данных видеоинформации (Размер пакета без учета размера заголовка (Header))
            var_dlen:=i_vpkt_total_len2dw - CONV_STD_LOGIC_VECTOR(C_VIDEO_PKT_HEADER_SIZE, i_vpkt_cnt'length);
            i_vpkt_data_len<=var_dlen;

            --//Установка параметров для текущего кадра видеоканала:
            for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
              if i_vch_num=i then

                --//сохраняем маркер текущей строки кадра :
                i_vfr_row_mrk(i)(31 downto 16)<=p_in_upp_data(15 downto 0);--//(старшая часть)
                i_vfr_row_mrk(i)(15 downto 0)<=tmp_vfr_row_mrk_low;        --//(младшая часть)

                --//параметры текущего видеоканала:
                i_vfr_zone_skip.pix<=i_cfg_prm_vch(i).fr_size.skip.pix(i_vfr_zone_skip.pix'high downto 0);
                i_vfr_zone_skip.row<=i_cfg_prm_vch(i).fr_size.skip.row(i_vfr_zone_skip.row'high downto 0);
                i_vfr_zone_active.pix<=i_cfg_prm_vch(i).fr_size.activ.pix(i_vfr_zone_active.pix'high downto 0);
                i_vfr_zone_active.row<=i_cfg_prm_vch(i).fr_size.activ.row(i_vfr_zone_active.row'high downto 0);
                i_vfr_subsampling<=i_cfg_prm_vch(i).fr_subsampling;
                i_vfr_actzone_row_cnt<=i_vfr_actzone_row_cnts(i);

                --//адрес ОЗУ:
                i_vfr_mem_adr(G_MEM_BANK_MSB_BIT downto G_MEM_BANK_LSB_BIT)<=i_cfg_prm_vch(i).mem_adr(G_MEM_BANK_MSB_BIT downto G_MEM_BANK_LSB_BIT);--(G_MEM_BANK_MSB_BIT-G_MEM_BANK_LSB_BIT downto 0);
                i_vfr_mem_adr(G_MEM_VFRAME_MSB_BIT downto G_MEM_VFRAME_LSB_BIT)<=p_in_vfr_buf(i);
              end if;
            end loop;

            --//адрес ОЗУ:
            i_vfr_mem_adr(G_MEM_VCH_MSB_BIT downto G_MEM_VCH_LSB_BIT)<=i_vch_num(G_MEM_VCH_MSB_BIT-G_MEM_VCH_LSB_BIT downto 0);
            i_vfr_mem_adr(G_MEM_VROW_MSB_BIT downto G_MEM_VROW_LSB_BIT)<=i_vfr_row((G_MEM_VROW_MSB_BIT-G_MEM_VROW_LSB_BIT)+0 downto 0);
            i_vfr_mem_adr(G_MEM_VROW_LSB_BIT-1 downto 0)<=(others=>'0');


            i_memtrn_zone_skip_pix_start<=(others=>'0');
            i_vpkt_data_readed<=(others=>'0');

            fsm_state_cs <= S_MEM_CTRL_SEL_BANK;
          else
          --//-------------------------
          --//Чтение заголовка:
          --//-------------------------
            --//Header DWORD-0:
            if i_vpkt_cnt=CONV_STD_LOGIC_VECTOR(C_VIDEO_PKT_HEADER_SIZE-1, i_vpkt_cnt'length) then

              --//Определяем полный размер принятого пакета (BYTE)
              var_dlen:=p_in_upp_data(15 downto 0)+2; --//+2 т.к. поле длинны в пакете не учитывает размер самого поля длинны

              --//Преобразуем полный размер принятого пакета в (DWORD)
              i_vpkt_total_len2dw<="00"&var_dlen(15 downto 2);--//

              if p_in_upp_data(19 downto 16)="0001" then
              --//Тип пакета - Видео Данные

                --//Сохраняем номер текущего видео канала:
                i_vch_num<=p_in_upp_data(23 downto 20);
              else
                --//Видимо принял заполнение нулями(Padding) кадра Ethernet
                --//Перевожу автомат в исходное состояние
                i_vpkt_header_rd<='0';
                fsm_state_cs <= S_IDLE;
              end if;

            --//Header DWORD-1:
            elsif i_vpkt_cnt=CONV_STD_LOGIC_VECTOR(C_VIDEO_PKT_HEADER_SIZE-2, i_vpkt_cnt'length) then

              for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
                if i_vch_num=i then
                  if i_vfr_num(i)/=p_in_upp_data(3 downto 0) then
                    --//Обнаружил начало нового кадра!!!!!!!!!
                    i_cfg_prm_vch(i)<=p_in_cfg_prm_vch(i);  --//Перезагрузка параметров канала
                  end if;

                  --//Сохраняем номер текущего кадра:
                  i_vfr_num(i)<= p_in_upp_data(3 downto 0);

                 end if;
              end loop;

              --//Сохраняем размер кадра:  кол-во пикселей
              i_vfr_pix_count<=p_in_upp_data(31 downto 16);

            --//Header DWORD-2:
            elsif i_vpkt_cnt=CONV_STD_LOGIC_VECTOR(C_VIDEO_PKT_HEADER_SIZE-3, i_vpkt_cnt'length) then

              --//Сохраняем размер кадра: кол-во строк
              i_vfr_row_count <= p_in_upp_data(15 downto 0);

              --//Сохраняем номер текущей строки:
              i_vfr_row <= p_in_upp_data(31 downto 16);

            --//Header DWORD-3:
            elsif i_vpkt_cnt=CONV_STD_LOGIC_VECTOR(C_VIDEO_PKT_HEADER_SIZE-4, i_vpkt_cnt'length) then

              --//Сохраняем маркер строки (младшая часть)
              tmp_vfr_row_mrk_low(15 downto 0)<=p_in_upp_data(31 downto 16);

            end if;

            i_vpkt_cnt<=i_vpkt_cnt-1;

          end if;

        end if;

      --//------------------------------------
      --//Назначаем банк ОЗУ
      --//------------------------------------
      when S_MEM_CTRL_SEL_BANK =>

        for j in 0 to i_mem_bank1h_out'high loop
          if i_vfr_mem_adr(G_MEM_BANK_MSB_BIT downto G_MEM_BANK_LSB_BIT)= j then
            i_mem_bank1h_out(j)<='1';
          else
            i_mem_bank1h_out(j)<='0';
          end if;
        end loop;--//for

        --//Ищем активную зону кадра по строкам:
        if i_vfr_row >= i_vfr_zone_skip.row and
           i_vfr_row < i_vfr_zone_active_row_end then
            --//Находимся в актиной зоне кадра
            i_vfr_actzone_row<='1';
        else
          --//Выход за пределы актиной зоны кадра
          i_vfr_actzone_row<='0';
        end if;

        i_vfr_zone_active.pix<=i_vfr_zone_active.pix-1;

        if i_vfr_zone_skip.pix /= (i_vfr_zone_skip.pix'range =>'0') then
          i_memtrn_zone_skip_pix_start<=i_vfr_zone_skip.pix-1;
        end if;

        fsm_state_cs <= S_MEM_CALC_REMAIN_SIZE;

      --//------------------------------------
      --//Расчитываем сколько данных осталось прочитать из FIFO видеопакетов
      --//------------------------------------
      when S_MEM_CALC_REMAIN_SIZE =>

        i_vpkt_data_remain <= EXT(i_vpkt_data_len, i_vpkt_cnt'length) - EXT(i_vpkt_data_readed, i_vpkt_cnt'length);
        fsm_state_cs <= S_MEM_TRN_LEN_CALC;

      --//------------------------------------
      --//Назначаем размер текущей MEM_TRN (запись в ОЗУ)
      --//------------------------------------
      when S_MEM_TRN_LEN_CALC =>

        if i_vpkt_data_remain >= EXT(p_in_cfg_mem_trn_len, i_vpkt_cnt'length) then
          i_vpkt_cnt <= EXT(p_in_cfg_mem_trn_len, i_vpkt_cnt'length);
        else
          i_vpkt_cnt <= i_vpkt_data_remain;
        end if;

        fsm_state_cs <= S_MEM_SET_ADR;

      --//------------------------------------
      --//Назначаем адрес ОЗУ
      --//------------------------------------
      when S_MEM_SET_ADR =>

        --//Проверяем попадает ли в теркущую MEM_TRN активная зона кадра по пикселам
        if i_vpkt_data_readed <= EXT(i_vfr_zone_active_pix_end, i_vpkt_cnt'length) then
          if (i_vpkt_data_readed + i_vpkt_cnt) > (EXT(i_vfr_zone_skip.pix, i_vpkt_cnt'length)) then
            var_temp:='1';
          end if;
        end if;

        if i_vfr_row_en='1' and var_temp='1' then
        --//Есть разрешение на запись данных текущей строки видеокадра

          if p_in_mem_wpf='0' and upp_buf_pfull='1' then --//if p_in_mem_wpf='0' then
          --//Ждем когда в TXBUF контроллера памяти появится свободное место (p_in_mem_wpf)
          --//+ когда в входном буфере накопится нужное кол-во данных (upp_buf_pfull)

            i_mem_arb_req<='1';--//Запрашиваем разрешение у арбитра на выполнение транзакции записи
            fsm_state_cs <= S_MEM_WAIT_RQ_EN;

          end if;
        else
        --//Запись строки в ОЗУ не ведется, но она должна быть полностью
        --//вычетана из FIFO видеопакетов
          fsm_state_cs <= S_MEM_SET_ADR_DONE;
        end if;

      --//------------------------------------
      --//Ждем разрешения от арбитра
      --//------------------------------------
      when S_MEM_WAIT_RQ_EN =>

        if p_in_memarb_en='1' then
        --//Получено разрешение от арбитра, переходим к выполнению MEM_TRN
          i_mem_ce_out<='1';
          fsm_state_cs <= S_MEM_SET_ADR_DONE;
        end if;

      --//------------------------------------
      --//Подготовка MEM_TRN
      --//------------------------------------
      when S_MEM_SET_ADR_DONE =>

        i_vpkt_cnt<=i_vpkt_cnt-1;
        i_vpkt_payload_rd<='1';
        i_mem_ce_out<='0';

        --//add now
        if i_vfr_row_en='1' then
            --//Ищем активную зону кадра по пикселям:
            if i_vpkt_data_readed >= EXT(i_vfr_zone_skip.pix, i_vpkt_cnt'length) and
               i_vpkt_data_readed <= EXT(i_vfr_zone_active_pix_end, i_vpkt_cnt'length) then
                --//Находимся в активной зоне кадра
                i_vfr_actzone_pix<='1';
            else
                --//Выход за пределы актиной зоны кадра
                i_vfr_actzone_pix<='0';
            end if;
        end if;

        i_mem_trn_len_cnt<=(others=>'0');
        fsm_state_cs <= S_MEM_TRN;

      --//----------------------------------------------
      --//Выполнение MEM_TRN (запись в ОЗУ)
      --//----------------------------------------------
      when S_MEM_TRN =>

        if upp_data_rd_out='1' then
          i_vpkt_data_readed<=i_vpkt_data_readed+1;--//Считаем сколько данных (DWORD) было вычитано из входного буфера

          --//Ищем активную зону кадра по пикселям:
          if i_vpkt_data_readed >= EXT(i_memtrn_zone_skip_pix_start, i_vpkt_cnt'length) and
             i_vpkt_data_readed < EXT(i_vfr_zone_active_pix_end, i_vpkt_cnt'length) then
              --//Находимся в активной зоне кадра
              i_vfr_actzone_pix<='1';
          else
              --//Выход за пределы актиной зоны кадра
              i_vfr_actzone_pix<='0';
          end if;

          --//Счетчик действительных данных(в DWORD) текущей MEM_TRN
          if i_vfr_pix_en='1' then
            i_mem_trn_len_cnt<=i_mem_trn_len_cnt+1;
            i_mem_adr_update<='1';
          end if;

          --//Счетчик данных(в DWORD) текущей MEM_TRN
          if i_vpkt_cnt=(i_vpkt_cnt'range => '0') then
            i_vpkt_payload_rd<='0';
            fsm_state_cs <= S_MEM_TRN_END;
          else
            i_vpkt_cnt<=i_vpkt_cnt-1;
          end if;
        end if;

      --//----------------------------------------------
      --//Анализ завершения вычетки данных из FIFO видео пакетв
      --//----------------------------------------------
      when S_MEM_TRN_END =>

        --//Вычисляем значение для обнавления адреса ОЗУ
        var_update_addr(1 downto 0) :=(others=>'0');--//Если i_vpkt_total_len2dw в DWORD
        var_update_addr(i_mem_trn_len_cnt'length+1 downto 2):=i_mem_trn_len_cnt;

        --//Вычисляем адрес ОЗУ для следующей MEM_TRN
        if i_vfr_row_en='1' and i_mem_adr_update='1' then
          i_vfr_mem_adr(G_MEM_VROW_LSB_BIT downto 0)<=i_vfr_mem_adr(G_MEM_VROW_LSB_BIT downto 0) + EXT(var_update_addr, G_MEM_VROW_LSB_BIT+1);
        end if;

        i_mem_adr_update<='0';
        i_mem_arb_req<='0';

        if i_vpkt_data_len=i_vpkt_data_readed then
        --//Вычитал весь видеопакет из FIFO видеопакетов
        --//Преходим к чтению следующего видеопакета

          if i_vfr_row=(i_vfr_row_count - 1) then
          --//Обработал последнюю строку кадра.
          --//Выдаем прерывание:
            for i in 0 to C_DSN_VCTRL_VCH_COUNT-1 loop
              if i_vch_num=i then
                var_vfr_rdy(i):='1';
              end if;
            end loop;
          end if;

          fsm_state_cs <= S_EXIT;
        else
        --//Продолжаем чтение данных видеопакета
          fsm_state_cs <= S_MEM_CALC_REMAIN_SIZE;
        end if;

      --//----------------------------------------------
      --//Подготовка к чтению следующего видеопакета
      --//----------------------------------------------
      when S_EXIT =>

        i_vpkt_data_readed<=(others=>'0');
        fsm_state_cs <= S_IDLE;

    end case;

    i_vfr_rdy<=var_vfr_rdy;
  end if;
end process;


--END MAIN
end behavioral;

