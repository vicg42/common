-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 04.11.2011 10:16:11
-- Module Name : pcie2mem_ctrl.vhd
--
-- Description :
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.mem_wr_pkg.all;
use work.pcie_pkg.all;

entity pcie2mem_ctrl is
generic(
G_MEM_AWIDTH     : integer := 32;
G_MEM_DWIDTH     : integer := 32;
G_MEM_BANK_M_BIT : integer := 29;
G_MEM_BANK_L_BIT : integer := 28;
G_DBG            : string := "OFF"
);
port(
-------------------------------
--CTRL
-------------------------------
p_in_ctrl         : in    TPce2Mem_Ctrl;
p_out_status      : out   TPce2Mem_Status;

--host -> dev
p_in_htxbuf_di    : in   std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_in_htxbuf_wr    : in   std_logic;
p_out_htxbuf_full : out  std_logic;
p_out_htxbuf_empty: out  std_logic;

--host <- dev
p_out_hrxbuf_do   : out  std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_in_hrxbuf_rd    : in   std_logic;
p_out_hrxbuf_full : out  std_logic;
p_out_hrxbuf_empty: out  std_logic;

p_in_hclk         : in    std_logic;

-------------------------------
--MEM_CTRL Port
-------------------------------
p_out_mem         : out   TMemIN;
p_in_mem          : in    TMemOUT;

-------------------------------
--DBG
-------------------------------
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(63 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end entity pcie2mem_ctrl;

architecture behavioral of pcie2mem_ctrl is

component pcie2mem_fifo
port(
din         : in std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

empty       : out std_logic;
full        : out std_logic;
prog_full   : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component;

--component pcie2mem_rxfifo
--port (
--din    : in std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
--wr_en  : in std_logic;
--wr_clk : in std_logic;
--
--dout   : out std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
--rd_en  : in std_logic;
--rd_clk : in std_logic;
--
--empty     : out std_logic;
--full      : out std_logic;
--prog_full : out std_logic;
--
--wr_rst_busy : out std_logic;
--rd_rst_busy : out std_logic;
--srst        : in std_logic
--);
--end component;
--
--component pcie2mem_txfifo
--port (
--din    : in std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
--wr_en  : in std_logic;
--wr_clk : in std_logic;
--
--dout   : out std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
--rd_en  : in std_logic;
--rd_clk : in std_logic;
--
--empty     : out std_logic;
--full      : out std_logic;
--prog_full : out std_logic;
--
--wr_rst_busy : out std_logic;
--rd_rst_busy : out std_logic;
--srst        : in std_logic
--);
--end component;

signal i_txbuf_dout         : std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
signal i_txbuf_dout_rd      : std_logic;
signal i_txbuf_full         : std_logic;
signal i_txbuf_empty        : std_logic;
signal i_rxbuf_din          : std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
signal i_rxbuf_din_wr       : std_logic;
signal i_rxbuf_full         : std_logic;
signal i_rxbuf_empty        : std_logic;

signal i_req_len_byte       : unsigned(17 downto 0) := (others => '0');
signal i_mem_adr            : std_logic_vector(31 downto 0) := (others => '0');--(BYTE)
signal i_mem_lenreq         : unsigned(15 downto 0) := (others => '0');
signal i_mem_lentrn         : unsigned(15 downto 0) := (others => '0');--Размер одиночной транзакции
signal i_mem_dir            : std_logic := '0';
signal i_mem_start          : std_logic := '0';
signal i_mem_done           : std_logic;

signal h_mem_start_wcnt     : unsigned(2 downto 0) := (others => '0');
signal h_mem_start_w        : std_logic := '0';
signal sr_mem_start         : std_logic_vector(0 to 2) := (others => '0');
signal i_mem_done_out       : std_logic := '0';

signal tst_mem_ctrl_out     : std_logic_vector(31 downto 0);
signal sr_txbuf_full        : std_logic;
signal sr_rxbuf_empty       : std_logic;

signal tst_htxbuf_wr_cnt    : unsigned(15 downto 0);
signal tst_htxbuf_rd_cnt    : unsigned(15 downto 0);


begin --architecture behavioral



--RAM<-PCIE
m_txbuf : pcie2mem_fifo
port map(
din         => p_in_htxbuf_di,
wr_en       => p_in_htxbuf_wr,
wr_clk      => p_in_hclk,

dout        => i_txbuf_dout,
rd_en       => i_txbuf_dout_rd,
rd_clk      => p_in_clk,

full        => open,
--almost_full => open,
prog_full   => i_txbuf_full,
empty       => i_txbuf_empty,

--clk         => p_in_clk,
rst         => p_in_rst
);

--m_txbuf : pcie2mem_txfifo
--port map(
--din         => p_in_htxbuf_di,
--wr_en       => p_in_htxbuf_wr,
--wr_clk      => p_in_hclk,
--
--dout        => i_txbuf_dout,
--rd_en       => i_txbuf_dout_rd,
--rd_clk      => p_in_clk,
--
--full        => open,
----almost_full => open,
--prog_full   => i_txbuf_full,
--empty       => i_txbuf_empty,
--
--wr_rst_busy => open,
--rd_rst_busy => open,
--srst        => p_in_tst(0)
--);


--RAM->PCIE
m_rxbuf : pcie2mem_fifo
port map(
din         => i_rxbuf_din,
wr_en       => i_rxbuf_din_wr,
wr_clk      => p_in_clk,

dout        => p_out_hrxbuf_do,
rd_en       => p_in_hrxbuf_rd,
rd_clk      => p_in_hclk,

full        => open,
--almost_full => i_rxbuf_full,
prog_full   => i_rxbuf_full,
empty       => i_rxbuf_empty,

--clk         => p_in_clk,
rst         => p_in_rst
);

--m_rxbuf : pcie2mem_rxfifo
--port map(
--din         => i_rxbuf_din,
--wr_en       => i_rxbuf_din_wr,
--wr_clk      => p_in_clk,
--
--dout        => p_out_hrxbuf_do,
--rd_en       => p_in_hrxbuf_rd,
--rd_clk      => p_in_hclk,
--
--full        => open,
----almost_full => i_rxbuf_full,
--prog_full   => i_rxbuf_full,
--empty       => i_rxbuf_empty,
--
--wr_rst_busy => open,
--rd_rst_busy => open,
--srst        => p_in_tst(0)
--);

p_out_hrxbuf_empty <= i_rxbuf_empty;
p_out_hrxbuf_full <= i_rxbuf_full;

p_out_htxbuf_empty <= i_txbuf_empty;
p_out_htxbuf_full <= i_txbuf_full;


----------------------------------------------------
--
----------------------------------------------------
m_mem_wr : mem_wr
generic map(
G_DBG => G_DBG,
G_MEM_BANK_M_BIT => G_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => G_MEM_BANK_L_BIT,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map(
-------------------------------
--CFG
-------------------------------
p_in_cfg_mem_adr     => i_mem_adr,
p_in_cfg_mem_trn_len => std_logic_vector(i_mem_lentrn),
p_in_cfg_mem_dlen_rq => std_logic_vector(i_mem_lenreq),
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_start,
p_out_cfg_mem_done   => i_mem_done,

-------------------------------
--USR Port
-------------------------------
p_in_usr_txbuf_dout  => i_txbuf_dout,
p_out_usr_txbuf_rd   => i_txbuf_dout_rd,
p_in_usr_txbuf_empty => i_txbuf_empty,

p_out_usr_rxbuf_din  => i_rxbuf_din,
p_out_usr_rxbuf_wd   => i_rxbuf_din_wr,
p_in_usr_rxbuf_full  => i_rxbuf_full,

---------------------------------
--MEM_CTRL Port
---------------------------------
p_out_mem            => p_out_mem,
p_in_mem             => p_in_mem,

-------------------------------
--DBG
-------------------------------
p_in_tst             => (others => '0'),
p_out_tst            => tst_mem_ctrl_out,

-------------------------------
--System
-------------------------------
p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);



--Expand start srob
process(p_in_hclk)
begin
if rising_edge(p_in_hclk) then
  if p_in_rst = '1' then

    h_mem_start_wcnt <= (others => '0');
    h_mem_start_w <= '0';

  else

    if p_in_ctrl.start = '1' then
      h_mem_start_w <= '1';
    elsif h_mem_start_wcnt(2)='1' then
      h_mem_start_w <= '0';
    end if;

    if h_mem_start_w = '0' then
      h_mem_start_wcnt <= (others => '0');
    else
      h_mem_start_wcnt <= h_mem_start_wcnt + 1;
    end if;

  end if;
end if;
end process;

--Resynch to mem_ctrl clk domen
i_req_len_byte <= UNSIGNED(p_in_ctrl.req_len);

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then

    i_mem_dir <= p_in_ctrl.dir;
    i_mem_adr <= p_in_ctrl.adr;
    i_mem_lenreq <= RESIZE(i_req_len_byte(i_req_len_byte'high downto log2(G_MEM_DWIDTH / 8))
                                                                        , i_mem_lenreq'length)
                    + (TO_UNSIGNED(0, i_mem_lenreq'length - 2)
                        & OR_reduce(i_req_len_byte(log2(G_MEM_DWIDTH / 8) - 1 downto 0)));

    if i_mem_dir = C_MEMWR_WRITE then
    i_mem_lentrn <= RESIZE(UNSIGNED(p_in_ctrl.trnwr_len), i_mem_lentrn'length);
    else
    i_mem_lentrn <= RESIZE(UNSIGNED(p_in_ctrl.trnrd_len), i_mem_lentrn'length);
    end if;

    sr_mem_start <= h_mem_start_w & sr_mem_start(0 to 1);
    i_mem_start <= sr_mem_start(1) and not sr_mem_start(2);

    if i_mem_start = '1' then
      i_mem_done_out <= '0';
    elsif i_mem_done = '1' then
      i_mem_done_out <= '1';
    end if;

  end if;
end process;

p_out_status.done <= i_mem_done_out;--Resynch to mem_ctrl clk domen NOT need, it doing into host module


------------------------------------
--DBG
------------------------------------
p_out_tst(0) <= i_mem_start;
p_out_tst(1) <= i_mem_done;
p_out_tst(5 downto 2) <= tst_mem_ctrl_out(5 downto 2);--m_mem_wr/tst_fsm_cs;
p_out_tst(6) <= sr_rxbuf_empty;--i_rxbuf_empty;
p_out_tst(7) <= i_rxbuf_full;
p_out_tst(8) <= i_txbuf_empty;
p_out_tst(9) <= sr_txbuf_full;
p_out_tst(10) <= i_rxbuf_din_wr ;--RAM->PCIE
p_out_tst(11) <= i_txbuf_dout_rd;--RAM<-PCIE
p_out_tst(25 downto 12) <= (others => '0');
--p_out_tst(25 downto 10) <= std_logic_vector(i_mem_lenreq);
p_out_tst(31 downto 26) <= tst_mem_ctrl_out(21 downto 16);--m_mem_wr/i_mem_trn_len;

p_out_tst(47 downto 32) <= std_logic_vector(tst_htxbuf_wr_cnt);
p_out_tst(63 downto 48) <= std_logic_vector(tst_htxbuf_rd_cnt);

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
sr_txbuf_full <= i_txbuf_full;
sr_rxbuf_empty <= i_rxbuf_empty;
end if;
end process;



process(p_in_hclk)
begin
if rising_edge(p_in_hclk) then
  if p_in_ctrl.start = '1' then
    tst_htxbuf_wr_cnt <= (others => '0');
  elsif (p_in_htxbuf_wr = '1') then
    tst_htxbuf_wr_cnt <= tst_htxbuf_wr_cnt + 1;
  end if;
end if;
end process;

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if i_mem_start = '1' then
    tst_htxbuf_rd_cnt <= (others => '0');
  elsif (i_txbuf_dout_rd = '1') then
    tst_htxbuf_rd_cnt <= tst_htxbuf_rd_cnt + 1;
  end if;
end if;
end process;

end architecture behavioral;
