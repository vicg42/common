-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02/04/2010
-- Module Name : eth_tx
--
-- Назначение/Описание :
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

library work;
use work.prj_def.all;
use work.eth_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity eth_tx is
generic(
G_WR_REM_WIDTH    :       integer := 4;           -- Remainder width of read data
G_WR_DWIDTH       :       integer := 32           -- FIFO read data width,
);
port
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_usr_ctrl                   : in    std_logic_vector(15 downto 0);
p_in_usr_pattern_param          : in    std_logic_vector(15 downto 0);
p_in_usr_pattern                : in    TEthUsrPattern;

--//------------------------------------
--//Связь с пользовательским TXBUF
--//------------------------------------
p_in_usr_txdata                 : in    std_logic_vector(G_WR_DWIDTH-1 downto 0);
p_out_usr_txdata_rd             : out   std_logic;
p_in_usr_txdata_rdy             : in    std_logic;
p_in_usr_txbuf_empty            : in    std_logic;--//Должен быть соединен с портом user_TXBUF/empty_almost
p_in_usr_txbuf_empty_almost     : in    std_logic;

--//------------------------------------
--//Связь с Local link TxFIFO
--//------------------------------------
p_out_tx_ll_data                : out   std_logic_vector(7 downto 0);
p_out_tx_ll_sof_n               : out   std_logic;
p_out_tx_ll_eof_n               : out   std_logic;
p_out_tx_ll_src_rdy_n           : out   std_logic;
p_in_tx_ll_dst_rdy_n            : in    std_logic;


--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk                        : in    std_logic;
p_in_rst                        : in    std_logic
);
end eth_tx;


architecture behavioral of eth_tx is

component ll_fifo
generic (
MEM_TYPE        :       integer := 0;
BRAM_MACRO_NUM  :       integer := 1;
DRAM_DEPTH      :       integer := 16;
WR_DWIDTH       :       integer := 32;
RD_DWIDTH       :       integer := 32;
RD_REM_WIDTH    :       integer := 2;
WR_REM_WIDTH    :       integer := 2;
USE_LENGTH      :       boolean := true;
glbtm           :       time    := 1 ns
);
port
(
-- Reset
areset_in:              in std_logic;

-- clocks
write_clock_in:         in std_logic;
read_clock_in:          in std_logic;

-- Interface to downstream user application
data_out:               out std_logic_vector(0 to RD_DWIDTH-1);
rem_out:                out std_logic_vector(0 to RD_REM_WIDTH-1);
sof_out_n:              out std_logic;
eof_out_n:              out std_logic;
src_rdy_out_n:          out std_logic;
dst_rdy_in_n:           in std_logic;

-- Interface to upstream user application
data_in:                in std_logic_vector(0 to WR_DWIDTH-1);
rem_in:                 in std_logic_vector(0 to WR_REM_WIDTH-1);
sof_in_n:               in std_logic;
eof_in_n:               in std_logic;
src_rdy_in_n:           in std_logic;
dst_rdy_out_n:          out std_logic;

-- FIFO status signals
fifostatus_out:         out std_logic_vector(0 to 3);

-- Length Status
len_rdy_out:            out std_logic;
len_out:                out std_logic_vector(0 to 15);
len_err_out:            out std_logic
);
end component;


component eth_tx_mac_frame_header_set
generic(
G_PKT_MARKER      :       integer := 4
);
port
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
p_in_usr_pattern       : in  TEthUsrPattern;

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data          : in  std_logic_vector(7 downto 0);
p_in_upp_sof_n         : in  std_logic;
p_in_upp_eof_n         : in  std_logic;
p_in_upp_src_rdy_n     : in  std_logic;
p_out_upp_dst_rdy_n    : out std_logic;

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data        : out std_logic_vector(7 downto 0);
p_out_dwnp_sof_n       : out std_logic;
p_out_dwnp_eof_n       : out std_logic;
p_out_dwnp_src_rdy_n   : out std_logic;
p_in_dwnp_dst_rdy_n    : in  std_logic;

--//--------------------------
--//System
--//--------------------------
p_in_clk               : in  std_logic;
p_in_rst               : in  std_logic
);
end component;

type fsm_eth_tx is
(
  S_IDLE,
  S_SOF,
  S_RDSEND_TXD,
  S_EOF
);
signal fsm_eth_tx_cs: fsm_eth_tx;

signal i_tx_sof               : std_logic;
signal i_tx_eof               : std_logic;

signal i_tx_work              : std_logic;
signal i_tx_usrdata_en        : std_logic;
signal i_txdata_cnt           : std_logic_vector(15 downto 0);
signal i_pkt_marker_fsm       : std_logic_vector(7 downto 0);
signal i_pkt_marker           : std_logic_vector(G_WR_DWIDTH-1 downto 0);

signal i_usr_ll_data          : std_logic_vector(0 to G_WR_DWIDTH-1);
signal i_usr_ll_sof_n         : std_logic;
signal i_usr_ll_eof_n         : std_logic;
signal i_usr_ll_src_rdy_n     : std_logic;
signal i_usr_ll_dst_rdy_out_n : std_logic;
signal i_usr_ll_rem_in        : std_logic_vector(0 to G_WR_REM_WIDTH-1);

signal tmp_tx_ll_eof_n        : std_logic;
signal tmp_tx_ll_eof_del      : std_logic;
signal tmp_tx_ll_src_rdy_n    : std_logic;
signal tmp_tx_ll_src_rdy_del  : std_logic;
signal tmp_tx_ll_data         : std_logic_vector(0 to 7);
signal tmp_tx_ll_rem_out      : std_logic_vector(0 to 0);
signal tmp_tx_ll_sof_n        : std_logic;
signal tmp_tx_ll_sof_del      : std_logic;
signal tmp_tx_ll_frame        : std_logic;


signal i_tx_ll_data           : std_logic_vector(7 downto 0);
signal i_tx_ll_sof_n          : std_logic;
signal i_tx_ll_eof_n          : std_logic;
signal i_tx_ll_src_rdy_n      : std_logic;
signal i_tx_ll_dst_rdy_n      : std_logic;

signal len_out                : std_logic_vector(0 to 15);
signal len_rdy_out            : std_logic;
signal len_err_out            : std_logic;

signal t_tx_sof               : std_logic;

--MAIN
begin


p_out_usr_txdata_rd <=i_tx_usrdata_en and not p_in_usr_txbuf_empty and not i_usr_ll_dst_rdy_out_n;

--//Автомат
--//Выполняет чтение данных из пользовательского буфера данных (TXBUF)
--//Формирует кадр для записи в m_ll_txfifo - где первое DWORD является маркером пакета.
--//маркер пакета необходим для управления вставкой польз. данных (p_in_usr_txpattern) в
--//кадр передоваемых данных по Eth. Поле C_PKT_MARKER_PATTERN_SIZE в p_in_usr_txpattern_param указывает на кол-во
--//вставляемых данных(в байтах). 0-bypass
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_eth_tx_cs<=S_IDLE;

    i_tx_sof<='0';
    i_tx_eof<='0';
    t_tx_sof<='0';

    i_tx_work<='0';
    i_tx_usrdata_en<='0';
    i_txdata_cnt<=(others=>'0');
    i_pkt_marker_fsm<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_eth_tx_cs is

      when S_IDLE =>
        t_tx_sof<='0';

      --//Ждем подтверждения что данные в TXBUF есть
       if p_in_usr_txdata_rdy='1' and p_in_usr_txbuf_empty='0' then
--        if (t_tx_sof='1' or p_in_usr_txdata_rdy='1') and p_in_usr_txbuf_empty='0' then
          i_txdata_cnt<=(others=>'0');
          fsm_eth_tx_cs<=S_SOF;
        end if;

      --//
      when S_SOF =>
        if i_usr_ll_dst_rdy_out_n='0' then
          i_tx_work<='1';
          i_tx_sof<='1';
          i_pkt_marker_fsm(C_PKT_MARKER_PATTERN_SIZE_MSB_BIT downto C_PKT_MARKER_PATTERN_SIZE_LSB_BIT)<=p_in_usr_pattern_param(C_PKT_MARKER_PATTERN_SIZE_MSB_BIT downto C_PKT_MARKER_PATTERN_SIZE_LSB_BIT);
          fsm_eth_tx_cs<=S_RDSEND_TXD;

        end if;

      --//
      when S_RDSEND_TXD =>

        i_tx_sof<='0';
        i_tx_usrdata_en<='1';

        if i_usr_ll_dst_rdy_out_n='0' then

          if p_in_usr_txbuf_empty='0' then
            i_txdata_cnt<=i_txdata_cnt+1;
          end if;

          if p_in_usr_txbuf_empty_almost='1' then
--          if p_in_usr_txbuf_empty_almost='1' or i_txdata_cnt=CONV_STD_LOGIC_VECTOR(12, 16) then
            i_tx_eof<='1';
            fsm_eth_tx_cs<=S_EOF;
          else
            fsm_eth_tx_cs<=S_RDSEND_TXD;
          end if;
        end if;

      --//
      when S_EOF =>

        if i_usr_ll_dst_rdy_out_n='0' then
          i_tx_eof<='0';
          i_tx_work<='0';
          i_tx_usrdata_en<='0';

--          if p_in_usr_txbuf_empty='0' then
--            t_tx_sof<='1';
--          end if;
          fsm_eth_tx_cs<=S_IDLE;
        end if;

    end case;

  end if;
end process;

--i_usr_ll_eof_n     <=not i_tx_eof;
i_usr_ll_eof_n     <=not (i_tx_work and p_in_usr_txbuf_empty_almost and not p_in_usr_txbuf_empty);--
--i_usr_ll_eof_n     <=not (i_tx_work and (p_in_usr_txbuf_empty_almost and not p_in_usr_txbuf_empty)) and  not(i_tx_work and i_tx_eof);--
i_usr_ll_sof_n     <=not (i_tx_work and i_tx_sof);
i_usr_ll_src_rdy_n <=not (i_tx_work and not p_in_usr_txbuf_empty);

--i_usr_ll_rem_in(0) <='0';--not i_usr_ll_eof_n;--i_usr_ll_eof_n;--not i_usr_ll_eof_n;--
--i_usr_ll_rem_in(1) <='0';--not i_usr_ll_eof_n;--'0';--

gen_rem : for i in 0 to G_WR_REM_WIDTH-1 generate
i_usr_ll_rem_in(i) <='1';
end generate gen_rem;


--i_pkt_marker<=EXT(i_pkt_marker_fsm, G_WR_DWIDTH);
i_pkt_marker(7 downto 0)<=i_pkt_marker_fsm(7 downto 0);
i_pkt_marker(15 downto 8) <="11000001";
i_pkt_marker(23 downto 16)<="11000010";
i_pkt_marker(31 downto 24)<="11000100";


gen_usr_txbuf : for i in 0 to G_WR_DWIDTH-1 generate
i_usr_ll_data(i) <=p_in_usr_txdata(i) when i_tx_usrdata_en='1' else i_pkt_marker(i);
end generate gen_usr_txbuf;



--//--------------------------------
--//Буфер TxDATA - Size определяется параметром BRAM_MACRO_NUM
--//--------------------------------
m_ll_txfifo : ll_fifo
generic map(
MEM_TYPE        => 0,           -- 0 choose BRAM, 1 choose Distributed RAM
BRAM_MACRO_NUM  => 1,           -- Memory Depth(Кол-во элементов BRAM (1BRAM-4kB). For BRAM only - Allowed: 1, 2, 4, 8, 16
DRAM_DEPTH      => 16,          -- Memory Depth. For DRAM only

WR_REM_WIDTH    => G_WR_REM_WIDTH,-- Remainder width of write data
WR_DWIDTH       => G_WR_DWIDTH,   -- FIFO write data width,
                                   -- Acceptable values are 8, 16, 32, 64, 128.

RD_REM_WIDTH    => 1,           -- Remainder width of read data
RD_DWIDTH       => 8,           -- FIFO read data width,
                                   -- Acceptable values are 8, 16, 32, 64, 128.

USE_LENGTH      => false,       -- Length FIFO option
glbtm           => 1 ns         -- Global timing delay for simulation
)
port map
(
-- Reset
areset_in              => p_in_rst,

-- Interface to upstream user application
data_in                => i_usr_ll_data,
rem_in                 => i_usr_ll_rem_in,
sof_in_n               => i_usr_ll_sof_n,
eof_in_n               => i_usr_ll_eof_n,
src_rdy_in_n           => i_usr_ll_src_rdy_n,
dst_rdy_out_n          => i_usr_ll_dst_rdy_out_n,

write_clock_in         => p_in_clk,

-- Interface to downstream user application
data_out               => tmp_tx_ll_data,
rem_out                => open,--tmp_tx_ll_rem_out,
sof_out_n              => tmp_tx_ll_sof_n,
eof_out_n              => tmp_tx_ll_eof_n,
src_rdy_out_n          => tmp_tx_ll_src_rdy_n,
dst_rdy_in_n           => i_tx_ll_dst_rdy_n,

read_clock_in          => p_in_clk,

-- FIFO status signals
fifostatus_out         => open,

-- Length Status
len_rdy_out            => len_rdy_out,
len_out                => len_out,
len_err_out            => len_err_out
);

--//Линия задержки необходима для формирования сигнала i_tx_ll_src_rdy_n
--//т.к. при подаче всех нулей на порт m_ll_txfifo/rem_in на выходе
--//m_ll_txfifo/src_rdy_out_n все время висит 0, а это не правильно
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
      tmp_tx_ll_sof_del <= '0';
      tmp_tx_ll_eof_del <= '0';
      tmp_tx_ll_src_rdy_del <= '0';
      tmp_tx_ll_frame <= '0';
      for i in 0 to 7 loop
      i_tx_ll_data(i)  <='0';
      end loop;

  elsif p_in_clk'event and p_in_clk='1' then
    if i_tx_ll_dst_rdy_n='0' then
      tmp_tx_ll_sof_del <= not tmp_tx_ll_sof_n;
      tmp_tx_ll_eof_del <= not tmp_tx_ll_eof_n;

      if tmp_tx_ll_sof_n='0' then
        tmp_tx_ll_frame <= '1';
      elsif tmp_tx_ll_eof_del='1' then
        tmp_tx_ll_frame <= '0';
      end if;

      for i in 0 to 7 loop
      i_tx_ll_data(i)  <=tmp_tx_ll_data(i);
      end loop;
    end if;

    tmp_tx_ll_src_rdy_del <= not tmp_tx_ll_src_rdy_n;

  end if;
end process;

i_tx_ll_src_rdy_n  <= not (tmp_tx_ll_frame and tmp_tx_ll_src_rdy_del);
i_tx_ll_eof_n      <= not (tmp_tx_ll_frame and tmp_tx_ll_eof_del);
i_tx_ll_sof_n      <= not tmp_tx_ll_sof_del;


--//--------------------------------
--//Модуль управления вставкой данных в поток p_out_tx_ll_data
--//--------------------------------
m_tx_mac_frame_header_set : eth_tx_mac_frame_header_set
generic map (
G_PKT_MARKER => (G_WR_DWIDTH/8)
)
port map
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
p_in_usr_pattern       => p_in_usr_pattern,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data          => i_tx_ll_data,
p_in_upp_sof_n         => i_tx_ll_sof_n,
p_in_upp_eof_n         => i_tx_ll_eof_n,
p_in_upp_src_rdy_n     => i_tx_ll_src_rdy_n,
p_out_upp_dst_rdy_n    => i_tx_ll_dst_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data        => p_out_tx_ll_data,
p_out_dwnp_sof_n       => p_out_tx_ll_sof_n,
p_out_dwnp_eof_n       => p_out_tx_ll_eof_n,
p_out_dwnp_src_rdy_n   => p_out_tx_ll_src_rdy_n,
p_in_dwnp_dst_rdy_n    => p_in_tx_ll_dst_rdy_n,

--//--------------------------
--//System
--//--------------------------
p_in_clk               => p_in_clk,
p_in_rst               => p_in_rst
);

--p_out_tx_ll_data       <= i_tx_ll_data;
--p_out_tx_ll_sof_n      <= i_tx_ll_sof_n;
--p_out_tx_ll_eof_n      <= i_tx_ll_eof_n;
--p_out_tx_ll_src_rdy_n  <= i_tx_ll_src_rdy_n;
--i_tx_ll_dst_rdy_n      <= p_in_tx_ll_dst_rdy_n;

--END MAIN
end behavioral;
