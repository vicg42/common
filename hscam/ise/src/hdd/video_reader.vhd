-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2012 13:07:50
-- Module Name : video_reader
--
-- Назначение/Описание :
--  Чтение кадра из видеобуфера ОЗУ
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
use work.mem_wr_pkg.all;
use work.video_ctrl_pkg.all;

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
--Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch     : in    TReaderVCHParams;

p_in_hrd_chsel       : in    std_logic_vector(3 downto 0);--//номер видеоканала выбраного для чтения
p_in_hrd_start       : in    std_logic;                   --//Запуск чтения кадра

p_in_vfr_buf         : in    TVfrBufs;                    --//Номер видеобувера с готовым кадром для соответствующего видеоканала

--//Статусы
p_out_vch_rd_done    : out   std_logic;

----------------------------
--Связь с выходным буфером видео
----------------------------
p_out_vbufout_d      : out   std_logic_vector(31 downto 0);
p_out_vbufout_wr     : out   std_logic;
p_in_vbufout_full    : in    std_logic;

---------------------------------
--Связь с mem_ctrl.vhd
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
S_MEM_START,
S_MEM_RD
);
signal fsm_state_cs: fsm_state;

signal i_mem_ptr                     : std_logic_vector(31 downto 0);
signal i_mem_trn_len                 : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq                 : std_logic_vector(15 downto 0);
signal i_mem_start                   : std_logic;
signal i_mem_dir                     : std_logic;
signal i_mem_done                    : std_logic;

signal tst_mem_wr_out                : std_logic_vector(31 downto 0);
--signal tst_fsmstate                  : std_logic_vector(3 downto 0);

--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
--p_out_tst(31 downto 0)<=(others=>'0');
p_out_tst(4 downto 0)<=tst_mem_wr_out(4 downto 0);
p_out_tst(31 downto 5)<=(others=>'0');

--tst_fsmstate<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsmstate'length) when fsm_state_cs=S_LD_PRMS       else
--              CONV_STD_LOGIC_VECTOR(16#02#,tst_fsmstate'length) when fsm_state_cs=S_INIT          else
--              CONV_STD_LOGIC_VECTOR(16#03#,tst_fsmstate'length) when fsm_state_cs=S_MEM_START     else
--              CONV_STD_LOGIC_VECTOR(16#04#,tst_fsmstate'length) when fsm_state_cs=S_MEM_RD        else
--              CONV_STD_LOGIC_VECTOR(16#05#,tst_fsmstate'length) when fsm_state_cs=S_ROW_NXT       else
--              CONV_STD_LOGIC_VECTOR(16#06#,tst_fsmstate'length) when fsm_state_cs=S_WAIT_HOST_ACK else
--              CONV_STD_LOGIC_VECTOR(16#00#,tst_fsmstate'length); --//fsm_state_cs=S_IDLE          else


--//----------------------------------------------
--//Статусы
--//----------------------------------------------
p_out_vch_rd_done<=i_mem_done;



--//----------------------------------------------
--//Автомат Чтения видео кадра
--//----------------------------------------------
--Логика работы автомата
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;

    i_mem_ptr<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_dlen_rq<=(others=>'0');
    i_mem_dir<='0';
    i_mem_start<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_state_cs is

      --------------------------------------
      --Исходное состояние
      --------------------------------------
      when S_IDLE =>

        if p_in_hrd_start='1' then
          fsm_state_cs <= S_MEM_START;
        end if;

      --------------------------------------
      --Запускаем операцию чтения ОЗУ
      --------------------------------------
      when S_MEM_START =>

        i_mem_ptr(i_mem_ptr'high downto G_MEM_VCH_M_BIT+1)<=(others=>'0');
        i_mem_ptr(G_MEM_VCH_M_BIT downto G_MEM_VCH_L_BIT)<=p_in_hrd_chsel(1 downto 0);
        i_mem_ptr(G_MEM_VFR_M_BIT downto G_MEM_VFR_L_BIT)<=p_in_vfr_buf(0);
        i_mem_ptr(G_MEM_VLINE_M_BIT downto G_MEM_VLINE_L_BIT)<=(others=>'0');
        i_mem_ptr(G_MEM_VLINE_L_BIT-1 downto 0)<=(others=>'0');

        i_mem_dlen_rq<=p_in_cfg_prm_vch(0).fr_size.total_dw; --//DW
        i_mem_trn_len<=EXT(p_in_cfg_mem_trn_len, i_mem_trn_len'length);
        i_mem_dir<=C_MEMWR_READ;
        i_mem_start<='1';

        fsm_state_cs <= S_MEM_RD;

      ------------------------------------------------
      --Чтение данных
      ------------------------------------------------
      when S_MEM_RD =>

        i_mem_start<='0';
        if i_mem_done='1' then
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
p_in_cfg_mem_adr     => i_mem_ptr,
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

p_out_usr_rxbuf_din  => p_out_vbufout_d,
p_out_usr_rxbuf_wd   => p_out_vbufout_wr,
p_in_usr_rxbuf_full  => p_in_vbufout_full,

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

