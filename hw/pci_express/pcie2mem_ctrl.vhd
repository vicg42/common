-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 04.11.2011 10:16:11
-- Module Name : pcie2mem_ctrl.vhd
--
-- Description :
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
use work.mem_wr_pkg.all;
use work.pcie_pkg.all;

entity pcie2mem_ctrl is
generic(
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32;
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28;
G_DBG            : string :="OFF"  --//В боевом проекте обязательно должно быть "OFF" - отладка с ChipScoupe
);
port(
-------------------------------------------------------
--Связь с mem_ctrl
-------------------------------------------------------
p_out_memarb_req  : out   std_logic;                    --//Запрос к арбитру ОЗУ на выполнение транзакции
p_in_memarb_en    : in    std_logic;                    --//Разрешение арбитра

p_out_mem_bank1h  : out   std_logic_vector(3 downto 0);
p_out_mem_ce      : out   std_logic;
p_out_mem_cw      : out   std_logic;
p_out_mem_rd      : out   std_logic;
p_out_mem_wr      : out   std_logic;
p_out_mem_term    : out   std_logic;
p_out_mem_adr     : out   std_logic_vector(G_MEM_AWIDTH - 1 downto 0);
p_out_mem_be      : out   std_logic_vector(G_MEM_DWIDTH / 8 - 1 downto 0);
p_out_mem_din     : out   std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_in_mem_dout     : in    std_logic_vector(G_MEM_DWIDTH - 1 downto 0);

p_in_mem_wf       : in    std_logic;
p_in_mem_wpf      : in    std_logic;
p_in_mem_re       : in    std_logic;
p_in_mem_rpe      : in    std_logic;

p_out_mem_clk     : out   std_logic;

-------------------------------------------------------
--Управление
-------------------------------------------------------
p_in_ctrl         : in    TPce2Mem_Ctrl;
p_out_status      : out   TPce2Mem_Status;

p_in_txd          : in    std_logic_vector(31 downto 0);
p_in_txd_wr       : in    std_logic;
p_out_txbuf_full  : out   std_logic;

p_out_rxd         : out   std_logic_vector(31 downto 0);
p_in_rxd_rd       : in    std_logic;
p_out_rxbuf_empty : out   std_logic;

p_in_hclk         : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end pcie2mem_ctrl;

architecture behavioral of pcie2mem_ctrl is

component pcie2mem_fifo
port(
din         : in std_logic_vector(31 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(31 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
prog_full   : out std_logic;
empty       : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component;


signal i_txbuf_dout                    : std_logic_vector(31 downto 0);
signal i_txbuf_dout_rd                 : std_logic;
signal i_txbuf_full                    : std_logic;
signal i_txbuf_empty                   : std_logic;
signal i_rxbuf_din                     : std_logic_vector(31 downto 0);
signal i_rxbuf_din_wr                  : std_logic;
signal i_rxbuf_full                    : std_logic;
signal i_rxbuf_empty                   : std_logic;

signal i_mem_adr                       : std_logic_vector(31 downto 0);--//(BYTE)
signal i_mem_lenreq                    : std_logic_vector(15 downto 0);--//Размер запрашиваемых данных (DWORD)
signal i_mem_lentrn                    : std_logic_vector(15 downto 0);--//Размер одиночной транзакции
signal i_mem_dir                       : std_logic;
signal i_mem_start                     : std_logic;
signal i_mem_done                      : std_logic;

signal h_mem_lentrn                    : std_logic_vector(15 downto 0);
signal h_mem_start_wcnt                : std_logic_vector(2 downto 0);
signal h_mem_start_w                   : std_logic;
signal sr_mem_start                    : std_logic_vector(0 to 2);
signal i_mem_done_out                  : std_logic;

signal tst_mem_ctrl_out                : std_logic_vector(31 downto 0);

--MAIN
begin


--//--------------------------------------------------
--//Согласующие буфера
--//--------------------------------------------------
--//RAM<-PCIE
m_txbuf : pcie2mem_fifo
port map(
din         => p_in_txd,
wr_en       => p_in_txd_wr,
wr_clk      => p_in_hclk,

dout        => i_txbuf_dout,
rd_en       => i_txbuf_dout_rd,
rd_clk      => p_in_clk,

full        => open,
almost_full => open,
prog_full   => i_txbuf_full,
empty       => i_txbuf_empty,

--clk         => p_in_clk,
rst         => p_in_rst
);

--//RAM->PCIE
m_rxbuf : pcie2mem_fifo
port map(
din         => i_rxbuf_din,
wr_en       => i_rxbuf_din_wr,
wr_clk      => p_in_clk,

dout        => p_out_rxd,
rd_en       => p_in_rxd_rd,
rd_clk      => p_in_hclk,

full        => open,
almost_full => i_rxbuf_full,
prog_full   => open,
empty       => i_rxbuf_empty,

--clk         => p_in_clk,
rst         => p_in_rst
);

p_out_rxbuf_empty<=i_rxbuf_empty;
p_out_txbuf_full<=i_txbuf_full;

--//--------------------------------------------------
--//Контроллер записи/чтения ОЗУ
--//--------------------------------------------------
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
p_in_cfg_mem_trn_len => i_mem_lentrn,
p_in_cfg_mem_dlen_rq => i_mem_lenreq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_start,
p_out_cfg_mem_done   => i_mem_done,

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout  => i_txbuf_dout,
p_out_usr_txbuf_rd   => i_txbuf_dout_rd,
p_in_usr_txbuf_empty => i_txbuf_empty,

p_out_usr_rxbuf_din  => i_rxbuf_din,
p_out_usr_rxbuf_wd   => i_rxbuf_din_wr,
p_in_usr_rxbuf_full  => i_rxbuf_full,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_memarb_req     => p_out_memarb_req,
p_in_memarb_en       => p_in_memarb_en,

p_out_mem_bank1h     => p_out_mem_bank1h,
p_out_mem_ce         => p_out_mem_ce,
p_out_mem_cw         => p_out_mem_cw,
p_out_mem_rd         => p_out_mem_rd,
p_out_mem_wr         => p_out_mem_wr,
p_out_mem_term       => p_out_mem_term,
p_out_mem_adr        => p_out_mem_adr,
p_out_mem_be         => p_out_mem_be,
p_out_mem_din        => p_out_mem_din,
p_in_mem_dout        => p_in_mem_dout,

p_in_mem_wf          => p_in_mem_wf,
p_in_mem_wpf         => p_in_mem_wpf,
p_in_mem_re          => p_in_mem_re,
p_in_mem_rpe         => p_in_mem_rpe,

p_out_mem_clk        => p_out_mem_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => tst_mem_ctrl_out,

-------------------------------
--System
-------------------------------
p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);


--//----------------------------------------------
--//Инициализация
--//----------------------------------------------
process(p_in_hclk)
begin
  if p_in_hclk'event and p_in_hclk='1' then
    if p_in_ctrl.dir=C_MEMWR_WRITE then
    h_mem_lentrn <= EXT(p_in_ctrl.trnwr_len, h_mem_lentrn'length);
    else
    h_mem_lentrn <= EXT(p_in_ctrl.trnrd_len, h_mem_lentrn'length);
    end if;
  end if;
end process;

--//Растягиваем импульс
process(p_in_rst,p_in_hclk)
begin
  if p_in_rst='1' then
    h_mem_start_wcnt<=(others=>'0');
    h_mem_start_w<='0';

  elsif p_in_hclk'event and p_in_hclk='1' then

    if p_in_ctrl.start='1' then
      h_mem_start_w<='1';
    elsif h_mem_start_wcnt(2)='1' then
      h_mem_start_w<='0';
    end if;

    if h_mem_start_w='0' then
      h_mem_start_wcnt<=(others=>'0');
    else
      h_mem_start_wcnt<=h_mem_start_wcnt+1;
    end if;
  end if;
end process;

--//Пересинхронизация на частоту mem_ctrl
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_mem_adr <= p_in_ctrl.adr;
    i_mem_lenreq <= p_in_ctrl.req_len(p_in_ctrl.req_len'high downto 2);
    i_mem_lentrn <= h_mem_lentrn;
    i_mem_dir <= p_in_ctrl.dir;

    sr_mem_start<=h_mem_start_w & sr_mem_start(0 to 1);
    i_mem_start<=sr_mem_start(1) and not sr_mem_start(2);

    if i_mem_start='1' then
      i_mem_done_out<='0';
    elsif i_mem_done='1' then
      i_mem_done_out<='1';
    end if;
  end if;
end process;


p_out_status.done<=i_mem_done_out;


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(0)<=i_mem_start;
p_out_tst(1)<=i_mem_done;
p_out_tst(5 downto 2)<=tst_mem_ctrl_out(5 downto 2);--m_mem_wr/tst_fsm_cs;
p_out_tst(6)<=i_rxbuf_empty;
p_out_tst(7)<=i_rxbuf_full;
p_out_tst(8)<=i_txbuf_empty;
p_out_tst(9)<=i_txbuf_full;
p_out_tst(25 downto 10)<=i_mem_lenreq;
p_out_tst(31 downto 26)<=tst_mem_ctrl_out(21 downto 16);--m_mem_wr/i_mem_trn_len;



--END MAIN
end behavioral;


