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
use work.dsn_video_ctrl_pkg.all;
use work.mem_wr_pkg.all;

entity video_writer is
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
p_in_cfg_load         : in    std_logic;                   --//Загрузка параметров записи
p_in_cfg_mem_trn_len  : in    std_logic_vector(7 downto 0);--//Размер одиночной транзакции MEM_WR
p_in_cfg_prm_vch      : in    TWriterVCHParams;            --//Параметры записи видео каналов
p_in_cfg_set_idle_vch : in    std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);

p_in_vfr_buf          : in    TVfrBufs;                    --//Номер буфера где будет формироваться текущий кадр

--//Статусы
p_out_vfr_rdy         : out   std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);--//Кадр готов для соответствующего видеоканала
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
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             : out   TMemIN;
p_in_mem              : in    TMemOUT;

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

type fsm_state is (
S_IDLE,
S_PKT_HEADER_READ,
S_MEM_START,
S_MEM_WR
);
signal fsm_state_cs: fsm_state;

signal i_vpkt_cnt                  : std_logic_vector(3 downto 0);
signal i_vpkt_header_rd            : std_logic;
signal i_vpkt_payload_rd           : std_logic;

signal i_vfr_row_mrk               : TVMrks;
signal i_vfr_row_mrk_l             : std_logic_vector(15 downto 0);
signal i_vfr_pix_count             : std_logic_vector(15 downto 0);
signal i_vfr_row_count             : std_logic_vector(15 downto 0);
Type TVfrNum is array (0 to C_VCTRL_VCH_COUNT-1) of std_logic_vector(3 downto 0);
signal i_vfr_num                   : TVfrNum;
signal i_vfr_row                   : std_logic_vector(15 downto 0);
signal i_vch_num                   : std_logic_vector(3 downto 0);
signal i_vfr_rdy                   : std_logic_vector(p_out_vfr_rdy'range);

signal i_mem_ptr                   : std_logic_vector(31 downto 0);
signal i_mem_wrbase                : std_logic_vector(31 downto 0);
signal i_mem_adr                   : std_logic_vector(31 downto 0);
signal i_mem_trn_len               : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq               : std_logic_vector(15 downto 0);
signal i_mem_start                 : std_logic;
signal i_mem_dir                   : std_logic;
signal i_mem_done                  : std_logic;

signal i_upp_data_rd               : std_logic;
signal i_upp_buf_pfull             : std_logic;
signal i_upp_hd_data_rd_out        : std_logic;

--signal tst_dbg_pictire             : std_logic;
--signal tst_fsmstate                : std_logic_vector(3 downto 0);


--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');

--tst_fsmstate<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsmstate'length) when fsm_state_cs=S_PKT_HEADER_READ else
--              CONV_STD_LOGIC_VECTOR(16#02#,tst_fsmstate'length) when fsm_state_cs=S_MEM_START       else
--              CONV_STD_LOGIC_VECTOR(16#03#,tst_fsmstate'length) when fsm_state_cs=S_MEM_WR          else
--              CONV_STD_LOGIC_VECTOR(16#00#,tst_fsmstate'length); --//fsm_state_cs=S_IDLE              else

--tst_dbg_pictire<=p_in_tst(C_VCTRL_REG_TST0_DBG_PICTURE_BIT);


--//----------------------------------------------
--//Статусы
--//----------------------------------------------
p_out_vfr_rdy<=i_vfr_rdy;--//Прерывание: кадр записан в ОЗУ
p_out_vrow_mrk<=i_vfr_row_mrk;--//Маркер строки видеокадра


--//----------------------------------------------
--//Связь с буфером видео пакетов
--//Вычитка пакета видео информации
--//----------------------------------------------
p_out_upp_data_rd<=i_upp_hd_data_rd_out or (i_vpkt_payload_rd and i_upp_data_rd);

i_upp_hd_data_rd_out <=(i_vpkt_header_rd  and not p_in_upp_buf_empty);


--//----------------------------------------------
--//Автомат записи видео информации
--//----------------------------------------------
process(p_in_rst,p_in_clk)
  variable vfr_rdy : std_logic_vector(p_out_vfr_rdy'range);
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;

    i_vpkt_cnt<=(others=>'0');
    i_vpkt_header_rd<='0';
    i_vpkt_payload_rd<='0';

    i_vch_num<=(others=>'0');
    for i in 0 to C_VCTRL_VCH_COUNT-1 loop
      i_vfr_num(i)<=(others=>'0');
      i_vfr_row_mrk(i)<=(others=>'0');
    end loop;

    i_vfr_row<=(others=>'0');
    i_vfr_pix_count<=(others=>'0');
    i_vfr_row_count<=(others=>'0');
    i_vfr_row_mrk_l<=(others=>'0');
    i_vfr_rdy<=(others=>'0');

    i_upp_buf_pfull<='0';

    vfr_rdy:=(others=>'0');

    i_mem_ptr<=(others=>'0');
    i_mem_wrbase<=(others=>'0');
    i_mem_adr<=(others=>'0');
    i_mem_dlen_rq<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_dir<='0';
    i_mem_start<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    vfr_rdy:=(others=>'0');

    i_upp_buf_pfull<=p_in_upp_buf_pfull;

    case fsm_state_cs is

      --//------------------------------------
      --//Исходное состояние
      --//------------------------------------
      when S_IDLE =>

        --//Загрузка праметров Видео канала
        if p_in_cfg_load='1' then
          for i in 0 to C_VCTRL_VCH_COUNT-1 loop
            i_mem_wrbase<=p_in_cfg_prm_vch(i).mem_adr;
          end loop;
        end if;

        --//Ждем когда появятся данные в буфере
        if i_upp_buf_pfull='1' then --//if p_in_upp_buf_pfull='1' then
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

        if i_upp_hd_data_rd_out='1' then

          if i_vpkt_cnt=(i_vpkt_cnt'range =>'0') then
          --//----------------------------------------
          --//----- Прочитал весь заголовок ----------
          --//----------------------------------------

            i_vpkt_header_rd<='0';

            --//Установка параметров для текущего кадра видеоканала:
            for i in 0 to C_VCTRL_VCH_COUNT-1 loop
              if i_vch_num=i then

                --//сохраняем маркер текущей строки кадра :
                i_vfr_row_mrk(i)(31 downto 16)<=p_in_upp_data(15 downto 0);--//(старшая часть)
                i_vfr_row_mrk(i)(15 downto 0)<=i_vfr_row_mrk_l;            --//(младшая часть)

                --//адрес ОЗУ:
                i_mem_ptr(G_MEM_VFR_M_BIT downto G_MEM_VFR_L_BIT)<=p_in_vfr_buf(i);
              end if;
            end loop;

            --//адрес ОЗУ:
            i_mem_ptr(G_MEM_VCH_M_BIT downto G_MEM_VCH_L_BIT)<=i_vch_num(G_MEM_VCH_M_BIT-G_MEM_VCH_L_BIT downto 0);
            i_mem_ptr(G_MEM_VLINE_M_BIT downto G_MEM_VLINE_L_BIT)<=i_vfr_row((G_MEM_VLINE_M_BIT-G_MEM_VLINE_L_BIT)+0 downto 0);
            i_mem_ptr(G_MEM_VLINE_L_BIT-1 downto 0)<=(others=>'0');--//Pix

            fsm_state_cs <= S_MEM_START;
          else
          --//-------------------------
          --//Чтение заголовка:
          --//-------------------------
            --//Header DWORD-0:
            if i_vpkt_cnt=CONV_STD_LOGIC_VECTOR(C_VIDEO_PKT_HEADER_SIZE-1, i_vpkt_cnt'length) then

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

              for i in 0 to C_VCTRL_VCH_COUNT-1 loop
                if i_vch_num=i then
                  if i_vfr_num(i)/=p_in_upp_data(3 downto 0) then
                    --//Обнаружил начало нового кадра!!!!!!!!!
                    --//Перезагрузка параметров канала
                    i_mem_wrbase<=p_in_cfg_prm_vch(i).mem_adr;
                  end if;

                  --//Сохраняем номер текущего кадра:
                  i_vfr_num(i)<= p_in_upp_data(3 downto 0);

                 end if;
              end loop;

              --//Сохраняем размер кадра: кол-во пикселей
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
              i_vfr_row_mrk_l(15 downto 0)<=p_in_upp_data(31 downto 16);

            end if;

            i_vpkt_cnt<=i_vpkt_cnt-1;

          end if;

        end if;


      --//------------------------------------
      --//Запускаем операцию записи ОЗУ
      --//------------------------------------
      when S_MEM_START =>

        i_vpkt_payload_rd<='1';
        i_mem_dlen_rq<="00"&i_vfr_pix_count(i_vfr_pix_count'high downto 2); --//DW
        i_mem_trn_len<=EXT(p_in_cfg_mem_trn_len, i_mem_trn_len'length);
        i_mem_adr<=i_mem_wrbase + i_mem_ptr;
        i_mem_dir<=C_MEMWR_WRITE;
        i_mem_start<='1';
        fsm_state_cs <= S_MEM_WR;

      --//----------------------------------------------
      --//Запись данных
      --//----------------------------------------------
      when S_MEM_WR =>

        i_mem_start<='0';

        if i_mem_done='1' then
        --//Операция выполнена
          i_vpkt_payload_rd<='0';

          if i_vfr_row=(i_vfr_row_count - 1) then
          --//Обработал последнюю строку кадра.
          --//Выдаем прерывание:
            for i in 0 to C_VCTRL_VCH_COUNT-1 loop
              if i_vch_num=i then
                vfr_rdy(i):='1';
              end if;
            end loop;
          end if;

          fsm_state_cs <= S_IDLE;
        end if;

    end case;

    i_vfr_rdy<=vfr_rdy;
  end if;
end process;


m_mem_wr : mem_wr
generic map(
G_MEM_BANK_M_BIT => G_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => G_MEM_BANK_L_BIT,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map(
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
p_in_usr_txbuf_dout  => p_in_upp_data,
p_out_usr_txbuf_rd   => i_upp_data_rd,
p_in_usr_txbuf_empty => p_in_upp_buf_empty,

p_out_usr_rxbuf_din  => open,
p_out_usr_rxbuf_wd   => open,
p_in_usr_rxbuf_full  => '0',

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

--END MAIN
end behavioral;

