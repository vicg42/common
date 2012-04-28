-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2012 13:06:52
-- Module Name : video_writer
--
-- Назначение/Описание :
--  Запись кадра в видеобуфер ОЗУ
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
use work.video_ctrl_pkg.all;
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
--Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len  : in    std_logic_vector(7 downto 0);--//Размер одиночной транзакции MEM_WR
p_in_cfg_prm_vch      : in    TWriterVCHParams;            --//Параметры записи видео каналов
p_in_vfr_buf          : in    TVfrBufs;                    --//Номер буфера где будет формироваться текущий кадр
p_in_vch_off          : in    std_logic;
--//Статусы
p_out_vfr_rdy         : out   std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);--//Кадр готов для соответствующего видеоканала

----------------------------
--Связь с входным буфером видео
----------------------------
p_in_vbufin_d         : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_vbufin_rd       : out   std_logic;
p_in_vbufin_empty     : in    std_logic;

---------------------------------
--Связь с mem_ctrl.vhd
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
S_MEM_START,
S_MEM_WR,
S_MEM_WAIT
);
signal fsm_state_cs: fsm_state;

signal i_mem_ptr                   : std_logic_vector(31 downto 0);
signal i_mem_trn_len               : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq               : std_logic_vector(15 downto 0);
signal i_mem_start                 : std_logic;
signal i_mem_dir                   : std_logic;
signal i_mem_done                  : std_logic;

signal i_vbufin_empty              : std_logic;
signal i_vfr_rdy                   : std_logic_vector(p_out_vfr_rdy'range);
signal i_vfr_rowcnt                : std_logic_vector(G_MEM_VLINE_M_BIT - G_MEM_VLINE_L_BIT downto 0);

signal i_padding                   : std_logic;
signal i_vbufin_rd_rdy_n           : std_logic;

signal tst_mem_wr_out              : std_logic_vector(31 downto 0);
--signal tst_fsmstate                : std_logic_vector(3 downto 0);


--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
--p_out_tst(31 downto 0)<=(others=>'0');
p_out_tst(4 downto 0)<=tst_mem_wr_out(4 downto 0);
p_out_tst(5)         <=i_padding;
p_out_tst(6)         <=i_vbufin_rd_rdy_n;
p_out_tst(7)         <='0';
p_out_tst(11 downto 8)<=(others=>'0');--tst_fsmstate;
p_out_tst(31 downto 12)<=(others=>'0');

--tst_fsmstate<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsmstate'length) when fsm_state_cs=S_MEM_START       else
--              CONV_STD_LOGIC_VECTOR(16#02#,tst_fsmstate'length) when fsm_state_cs=S_MEM_WR          else
--              CONV_STD_LOGIC_VECTOR(16#03#,tst_fsmstate'length) when fsm_state_cs=S_MEM_WAIT        else
--              CONV_STD_LOGIC_VECTOR(16#00#,tst_fsmstate'length); --//fsm_state_cs=S_IDLE              else


--//----------------------------------------------
--//Статусы
--//----------------------------------------------
p_out_vfr_rdy<=i_vfr_rdy;--//Прерывание: кадр записан в ОЗУ


--//----------------------------------------------
--//Автомат записи видео информации
--//----------------------------------------------
process(p_in_rst,p_in_clk)
  variable vfr_rdy : std_logic_vector(p_out_vfr_rdy'range);
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;
    i_vfr_rdy<=(others=>'0');
      vfr_rdy:=(others=>'0');
    i_vfr_rowcnt<=(others=>'0');
    i_vbufin_empty<='0';

    i_mem_ptr<=(others=>'0');
    i_mem_dlen_rq<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_dir<='0';
    i_mem_start<='0';
    i_padding<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    vfr_rdy:=(others=>'0');
    i_vbufin_empty<=p_in_vbufin_empty;

    case fsm_state_cs is

      --------------------------------------
      --Исходное состояние
      --------------------------------------
      when S_IDLE =>

        --//Ждем когда появятся данные в буфере
        i_padding<='0';
        i_vfr_rowcnt<=(others=>'0');
        if i_vbufin_empty='0' and p_in_vch_off='0' then
          fsm_state_cs <= S_MEM_START;
        end if;

      --------------------------------------
      --Запускаем операцию записи ОЗУ
      --------------------------------------
      when S_MEM_START =>

        if p_in_vch_off='1' then
          fsm_state_cs <= S_IDLE;

        else
          i_mem_ptr(i_mem_ptr'high downto G_MEM_VCH_M_BIT+1)<=(others=>'0');
          i_mem_ptr(G_MEM_VCH_M_BIT downto G_MEM_VCH_L_BIT)<=(others=>'0');
          i_mem_ptr(G_MEM_VFR_M_BIT downto G_MEM_VFR_L_BIT)<=p_in_vfr_buf(0);
          i_mem_ptr(G_MEM_VLINE_M_BIT downto G_MEM_VLINE_L_BIT)<=i_vfr_rowcnt;
          i_mem_ptr(G_MEM_VLINE_L_BIT-1 downto 0)<=(others=>'0');

          i_mem_dlen_rq<=(CONV_STD_LOGIC_VECTOR(0, log2(G_MEM_DWIDTH/8)) & p_in_cfg_prm_vch(0).fr_size.pix(p_in_cfg_prm_vch(0).fr_size.pix'high downto log2(G_MEM_DWIDTH/8)));
          i_mem_trn_len<=EXT(p_in_cfg_mem_trn_len, i_mem_trn_len'length);
          i_mem_dir<=C_MEMWR_WRITE;
          i_mem_start<='1';

          fsm_state_cs <= S_MEM_WR;
        end if;

      ------------------------------------------------
      --Запись данных
      ------------------------------------------------
      when S_MEM_WR =>

        i_mem_start<='0';
        if i_mem_done='1' then
          if i_vfr_rowcnt=p_in_cfg_prm_vch(0).fr_size.row(i_vfr_rowcnt'range)-1 then
            vfr_rdy(0):='1';
            fsm_state_cs <= S_IDLE;
          else
            i_vfr_rowcnt<=i_vfr_rowcnt + 1;
            fsm_state_cs <= S_MEM_START;
          end if;

        elsif p_in_vch_off='1' then
          i_padding<='1';
          fsm_state_cs <= S_MEM_WAIT;
        end if;

      ------------------------------------------------
      --Ждем завершения транзакции
      ------------------------------------------------
      when S_MEM_WAIT =>

        if i_mem_done='1' then
          fsm_state_cs <= S_IDLE;
        end if;

    end case;

    i_vfr_rdy<=vfr_rdy;
  end if;
end process;


--//------------------------------------------------------
--//Модуль записи/чтения данных ОЗУ (mem_ctrl.vhd)
--//------------------------------------------------------
i_vbufin_rd_rdy_n<=p_in_vbufin_empty and not i_padding;

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
p_in_cfg_mem_adr     => i_mem_ptr,
p_in_cfg_mem_trn_len => i_mem_trn_len,
p_in_cfg_mem_dlen_rq => i_mem_dlen_rq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_start,
p_out_cfg_mem_done   => i_mem_done,

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout  => p_in_vbufin_d,
p_out_usr_txbuf_rd   => p_out_vbufin_rd,
p_in_usr_txbuf_empty => i_vbufin_rd_rdy_n,

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
p_out_tst            => tst_mem_wr_out,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);

--END MAIN
end behavioral;

