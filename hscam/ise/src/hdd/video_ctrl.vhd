-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2012 12:31:12
-- Module Name : video_ctrl
--
-- Назначение/Описание :
--  Запись/Чтение кадров видеоканалов
--
--
-- Revision:
-- Revision 0.01 - File Created
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

entity video_ctrl is
generic(
G_SIM    : string:="OFF";
G_MEM_BANK_M_BIT : integer:=32;
G_MEM_BANK_L_BIT : integer:=31;
G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
port(
-------------------------------
--Параметры Видеокадра
-------------------------------
p_in_vfr_prm          : in    TFrXY;
p_in_mem_trn_len      : in    std_logic_vector(15 downto 0);
p_in_vwr_off          : in    std_logic;
p_in_vrd_off          : in    std_logic;

----------------------------
--Связь с вх/вых видеобуферами
----------------------------
--Вх
p_in_vbufi_s          : in    TVSync;
p_in_vbufi_d          : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_vbufi_rd        : out   std_logic;
p_in_vbufi_empty      : in    std_logic;
--Вых
p_in_vbufo_s          : in    TVSync;
p_out_vbufo_d         : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_vbufo_wr        : out   std_logic;
p_in_vbufo_full       : in    std_logic;

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;

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
end video_ctrl;

architecture behavioral of video_ctrl is

component video_writer
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
p_in_cfg_mem_trn_len  : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch      : in    TWriterVCHParams;
p_in_vfr_buf          : in    TVfrBufs;
p_in_vch_off          : in    std_logic;
--//Статусы
p_out_vfr_rdy         : out   std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);

----------------------------
--Связь с входным буфером видео
----------------------------
p_in_vbufi_s          : in    TVSync;
p_in_vbufi_d          : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_vbufi_rd        : out   std_logic;
p_in_vbufi_empty      : in    std_logic;

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
end component;

component video_reader
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
p_in_hrd_start       : in    std_logic;
p_in_vfr_buf         : in    TVfrBufs;
p_in_vch_off         : in    std_logic;
--//Статусы
p_out_vch_rd_done    : out   std_logic;

----------------------------
--Связь с выходным буфером видео
----------------------------
p_in_vbufo_s         : in    TVSync;
p_out_vbufo_d        : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_vbufo_wr       : out   std_logic;
p_in_vbufo_full      : in    std_logic;

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
end component;

signal i_mem_wr_trn_len                  : std_logic_vector(7 downto 0);
signal i_mem_rd_trn_len                  : std_logic_vector(7 downto 0);
signal i_wrprm_vch                       : TWriterVCHParams;
signal i_rdprm_vch                       : TReaderVCHParams;

signal i_vwr_fr_rdy                      : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_vrd_fr_rddone                   : std_logic;
signal i_vrd_hold                        : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_vrd_off                         : std_logic;
signal i_vbuf_wr                         : TVfrBufs;
signal i_vbuf_rd                         : TVfrBufs;
signal tst_vwr_out                       : std_logic_vector(31 downto 0);
signal tst_vrd_out                       : std_logic_vector(31 downto 0);



--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(4 downto 0)  <=tst_vwr_out(4 downto 0);
p_out_tst(9 downto 5)  <=tst_vrd_out(4 downto 0);
p_out_tst(11 downto 10)<=i_vbuf_wr(0);
p_out_tst(13 downto 12)<=i_vbuf_rd(0);
p_out_tst(14)          <=i_vwr_fr_rdy(0);
p_out_tst(15)          <='0';
p_out_tst(21 downto 16)<=tst_vwr_out(21 downto 16);--i_mem_trn_len;
p_out_tst(22)          <=i_vrd_fr_rddone;
p_out_tst(23)          <='0';
p_out_tst(27 downto 24)<=tst_vwr_out(11 downto 8);
p_out_tst(31 downto 28)<=tst_vrd_out(11 downto 8);



--//--------------------------------------------------
--//Конфигурирование модуля
--//--------------------------------------------------
i_mem_wr_trn_len<=p_in_mem_trn_len( 7 downto 0);
i_mem_rd_trn_len<=p_in_mem_trn_len(15 downto 8);

--Готовим параметры для модуля записи
gen_vwrprm : for i in 0 to C_VCTRL_VCH_COUNT-1 generate
i_wrprm_vch(i).fr_size <=p_in_vfr_prm;
end generate gen_vwrprm;

--Готовим параметры для модуля чтения
gen_vrdprm : for i in 0 to C_VCTRL_VCH_COUNT-1 generate
i_rdprm_vch(i).fr_size <=p_in_vfr_prm;
end generate gen_vrdprm;

--//--------------------------------------------------
--//Управление видео буферами
--//--------------------------------------------------
--Варианты захвата видеобуфера:
--x, 0, 0, 0
--1, x, 1, 1
--2, 2, x, 2
--3, 3, 3, x

--где 0,1,2,3 - индексы свободных видеобуферов
--    x - видеобуфер захваченый модулем чтения (video_reader.vhd)

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    for i in 0 to C_VCTRL_VCH_COUNT_MAX-1 loop
      i_vbuf_wr(i)<=(others=>'0');
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then

    for i in 0 to C_VCTRL_VCH_COUNT-1 loop

        --Назначаем видеобуфер для записи видео
        if i_vwr_fr_rdy(i)='1' then
            --Если модуль чтения заватил видеобуфер, то ...
            if i_vrd_hold(i)='1' then
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

            else
              i_vbuf_wr(i)<=i_vbuf_wr(i)+1;
            end if;
        end if;

    end loop;

  end if;
end process;

--чтение видео
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to C_VCTRL_VCH_COUNT_MAX-1 loop
      i_vbuf_rd(i)<=(others=>'0');
    end loop;
    i_vrd_hold<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    for i in 0 to C_VCTRL_VCH_COUNT-1 loop

        --Выдаем номер видеобуфера модулю чтения (video_reader.vhd)
        if i_vwr_fr_rdy(i)='1' then
            if i_vrd_hold(i)='0' then
              i_vbuf_rd(i)<=i_vbuf_wr(i);
            end if;
        end if;

        --Захват видеобуфера для чтения кадра
        if i_vwr_fr_rdy(i)='1' then
          i_vrd_hold(i)<='1';
        elsif i_vrd_fr_rddone='1' then
          i_vrd_hold(i)<='0';
        end if;

    end loop;

  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_vrd_off<='1';
  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_vrd_off='1' then
      i_vrd_off<='1';
    else
      if (p_in_vbufi_s.v='1' and p_in_vbufi_s.h='1') and
         (p_in_vbufo_s.v='1' and p_in_vbufo_s.h='1') then
          i_vrd_off<='0';
      end if;
    end if;
  end if;
end process;


--//--------------------------------------------------
--// Запись видео в ОЗУ
--//--------------------------------------------------
m_vwriter : video_writer
generic map(
G_MEM_BANK_M_BIT  => G_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT  => G_MEM_BANK_L_BIT,

G_MEM_VCH_M_BIT   => C_VCTRL_MEM_VCH_M_BIT,
G_MEM_VCH_L_BIT   => C_VCTRL_MEM_VCH_L_BIT,
G_MEM_VFR_M_BIT   => C_VCTRL_MEM_VFR_M_BIT,
G_MEM_VFR_L_BIT   => C_VCTRL_MEM_VFR_L_BIT,
G_MEM_VLINE_M_BIT => C_VCTRL_MEM_VLINE_M_BIT,
G_MEM_VLINE_L_BIT => C_VCTRL_MEM_VLINE_L_BIT,

G_MEM_AWIDTH      => G_MEM_AWIDTH,
G_MEM_DWIDTH      => G_MEM_DWIDTH
)
port map(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len  => i_mem_wr_trn_len,
p_in_cfg_prm_vch      => i_wrprm_vch,
p_in_vch_off          => p_in_vwr_off,
p_in_vfr_buf          => i_vbuf_wr,

--//Статусы
p_out_vfr_rdy         => i_vwr_fr_rdy,

----------------------------
--Связь с входным буфером видео
----------------------------
p_in_vbufi_s          => p_in_vbufi_s,
p_in_vbufi_d          => p_in_vbufi_d,
p_out_vbufi_rd        => p_out_vbufi_rd,
p_in_vbufi_empty      => p_in_vbufi_empty,

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             => p_out_memwr,
p_in_mem              => p_in_memwr,

-------------------------------
--Технологический
-------------------------------
p_in_tst              => (others=>'0'),
p_out_tst             => tst_vwr_out,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => p_in_rst
);


--//--------------------------------------------------
--//Чтение видео из ОЗУ
--//--------------------------------------------------
m_vreader : video_reader
generic map(
G_MEM_BANK_M_BIT  => G_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT  => G_MEM_BANK_L_BIT,

G_MEM_VCH_M_BIT   => C_VCTRL_MEM_VCH_M_BIT,
G_MEM_VCH_L_BIT   => C_VCTRL_MEM_VCH_L_BIT,
G_MEM_VFR_M_BIT   => C_VCTRL_MEM_VFR_M_BIT,
G_MEM_VFR_L_BIT   => C_VCTRL_MEM_VFR_L_BIT,
G_MEM_VLINE_M_BIT => C_VCTRL_MEM_VLINE_M_BIT,
G_MEM_VLINE_L_BIT => C_VCTRL_MEM_VLINE_L_BIT,

G_MEM_AWIDTH      => G_MEM_AWIDTH,
G_MEM_DWIDTH      => G_MEM_DWIDTH
)
port map(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len  => i_mem_rd_trn_len,
p_in_cfg_prm_vch      => i_rdprm_vch,
p_in_hrd_start        => i_vwr_fr_rdy(0),
p_in_vfr_buf          => i_vbuf_rd,
p_in_vch_off          => i_vrd_off,--p_in_vrd_off,
--//Статусы
p_out_vch_rd_done     => i_vrd_fr_rddone,

----------------------------
--Связь с выходным буфером видео
----------------------------
p_in_vbufo_s          => p_in_vbufo_s,
p_out_vbufo_d         => p_out_vbufo_d,
p_out_vbufo_wr        => p_out_vbufo_wr,
p_in_vbufo_full       => p_in_vbufo_full,

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             => p_out_memrd,
p_in_mem              => p_in_memrd,

-------------------------------
--Технологический
-------------------------------
p_in_tst              => (others=>'0'),
p_out_tst             => tst_vrd_out,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => p_in_rst
);



--END MAIN
end behavioral;

