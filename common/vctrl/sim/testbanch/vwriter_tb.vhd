-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 22.07.2012 11:10:51
-- Module Name : vwriter_tb
--
-- Назначение/Описание :
--    Проверка работы
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
use work.mem_glob_pkg.all;
use work.mem_wr_pkg.all;
use work.dsn_video_ctrl_pkg.all;

library std;
use std.textio.all;

entity vwriter_tb is
generic(
G_SIM : string:="ON"
);
port(
p_out_mem : out TMemIN
);
end vwriter_tb;

architecture behavior of vwriter_tb is

constant i_clk_period : TIME := 6.6 ns; --150MHz

component host_vbuf
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END component;

component video_writer
generic(
G_DBGCS           : string :="OFF";
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
end component;

signal p_in_rst                   : std_logic;
signal p_in_clk                   : std_logic;

signal i_cfg_load                 : std_logic;
signal i_cfg_mem_trn_len          : std_logic_vector(7 downto 0);
signal i_cfg_prm_vch              : TWriterVCHParams;
signal i_cfg_set_idle_vch         : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_vfr_buf                  : TVfrBufs;
signal i_upp_data                 : std_logic_vector(31 downto 0);
signal i_upp_data_rd              : std_logic;
signal i_upp_buf_empty            : std_logic;
signal i_upp_buf_pfull            : std_logic;
signal i_out_mem                  : TMemIN;
signal i_in_mem                   : TMemOUT;

signal i_dcnt                     : std_logic_vector(15 downto 0);
signal i_data                     : std_logic_vector(31 downto 0);
signal i_data_wr                  : std_logic;


--Main
begin


clk_in_generator : process
begin
  p_in_clk<='0';
  wait for i_clk_period/2;
  p_in_clk<='1';
  wait for i_clk_period/2;
end process;

p_in_rst<='1','0' after 1 us;


m_vwr : video_writer
generic map(
G_DBGCS           => "ON",
G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,

G_MEM_VCH_M_BIT   => C_VCTRL_MEM_VCH_M_BIT,
G_MEM_VCH_L_BIT   => C_VCTRL_MEM_VCH_L_BIT,
G_MEM_VFR_M_BIT   => C_VCTRL_MEM_VFR_M_BIT,
G_MEM_VFR_L_BIT   => C_VCTRL_MEM_VFR_L_BIT,
G_MEM_VLINE_M_BIT => C_VCTRL_MEM_VLINE_M_BIT,
G_MEM_VLINE_L_BIT => C_VCTRL_MEM_VLINE_L_BIT,

G_MEM_AWIDTH      => 32, --G_MEM_AWIDTH,
G_MEM_DWIDTH      => 32 --G_MEM_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_load         => i_cfg_load         ,
p_in_cfg_mem_trn_len  => i_cfg_mem_trn_len  ,
p_in_cfg_prm_vch      => i_cfg_prm_vch      ,
p_in_cfg_set_idle_vch => (others=>'0'),--i_cfg_set_idle_vch ,

p_in_vfr_buf          => i_vfr_buf          ,

--//Статусы
p_out_vfr_rdy         => open,
p_out_vrow_mrk        => open,

--//--------------------------
--//Upstream Port (Связь с буфером видеопакетов)
--//--------------------------
p_in_upp_data         => i_upp_data  ,
p_out_upp_data_rd     => i_upp_data_rd,
p_in_upp_data_rdy     => '0',
p_in_upp_buf_empty    => i_upp_buf_empty,
p_in_upp_buf_full     => '0',
p_in_upp_buf_pfull    => i_upp_buf_pfull,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             => p_out_mem,--: out   TMemIN;
p_in_mem              => i_in_mem ,--: in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              => (others=>'0'),
p_out_tst             => open,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => p_in_rst
);


i_cfg_mem_trn_len<=CONV_STD_LOGIC_VECTOR(16#40#, i_cfg_mem_trn_len'length);
i_cfg_prm_vch(0).mem_adr<=(others=>'0');
i_vfr_buf(0)<=(others=>'0');

i_in_mem.req_en  <='1';
i_in_mem.data    <=(others=>'0');

i_in_mem.buf_wpf <='0';
i_in_mem.buf_re  <='0';


process
  variable dcnt : std_logic_vector(15 downto 0);--integer;
begin
  dcnt:=(others=>'0');
  i_data<=(others=>'0');
  i_data_wr<='0';
  i_dcnt<=(others=>'0');
  i_upp_buf_pfull<='0';
--  i_upp_buf_empty<='1';
  i_cfg_load<='0';
--  i_upp_data<=(others=>'0');

  wait for 2 us;

  i_upp_buf_pfull<='1';

  wait until p_in_clk'event and p_in_clk='1';

  i_data(15 downto  0)<=CONV_STD_LOGIC_VECTOR(16, 16);
  i_data(19 downto 16)<=CONV_STD_LOGIC_VECTOR(1, 4);
  i_data(23 downto 20)<=CONV_STD_LOGIC_VECTOR(1, 4);
  i_data(27 downto 24)<=CONV_STD_LOGIC_VECTOR(1, 4);
  i_data(31 downto 28)<=(others=>'0');
  i_data_wr<='1';

  while dcnt/=CONV_STD_LOGIC_VECTOR(4+1, 16) loop
    wait until p_in_clk'event and p_in_clk='1';
        i_data<=i_data + 1;
        dcnt:=dcnt + 1;
  end loop;

  i_data_wr<='0';
  dcnt:=(others=>'0');
  wait for 1 us;



  wait until p_in_clk'event and p_in_clk='1';

  i_data(15 downto  0)<=CONV_STD_LOGIC_VECTOR(34, 16);
  i_data(31 downto 16)<=CONV_STD_LOGIC_VECTOR(0, 4) & CONV_STD_LOGIC_VECTOR(3, 4) & CONV_STD_LOGIC_VECTOR(2, 4) & CONV_STD_LOGIC_VECTOR(1, 4);
  i_data_wr<='1';

  wait until p_in_clk'event and p_in_clk='1';

  i_data(15 downto  0)<=CONV_STD_LOGIC_VECTOR(0, 16);
  i_data(31 downto 16)<=CONV_STD_LOGIC_VECTOR(15, 16);--pix count
  i_data_wr<='1';

  wait until p_in_clk'event and p_in_clk='1';

  i_data(15 downto  0)<=CONV_STD_LOGIC_VECTOR(16, 16);
  i_data(31 downto 16)<=CONV_STD_LOGIC_VECTOR(3, 16);
  i_data_wr<='1';

  wait until p_in_clk'event and p_in_clk='1';

  i_data(15 downto  0)<=CONV_STD_LOGIC_VECTOR(16, 16);
  i_data(31 downto 16)<=CONV_STD_LOGIC_VECTOR(4, 16);
  i_data_wr<='1';

  wait until p_in_clk'event and p_in_clk='1';

  i_data(15 downto  0)<=CONV_STD_LOGIC_VECTOR(16, 16);
  i_data(31 downto 16)<=CONV_STD_LOGIC_VECTOR(5, 16);
  i_data_wr<='1';

  while dcnt/=CONV_STD_LOGIC_VECTOR(4+1, 16) loop
    wait until p_in_clk'event and p_in_clk='1';
        i_data<=i_data + 1;
        dcnt:=dcnt + 1;
  end loop;

  i_data_wr<='0';

  wait;
end process;


m_buf : host_vbuf
port map(
rst => p_in_rst,
wr_clk => p_in_clk,
rd_clk => p_in_clk,
din => i_data,
wr_en => i_data_wr,
rd_en => i_upp_data_rd,
dout => i_upp_data,
full => open,
empty => i_upp_buf_empty,
prog_full => open
);


--End Main
end;
