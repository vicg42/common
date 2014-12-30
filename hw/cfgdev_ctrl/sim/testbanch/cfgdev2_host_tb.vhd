-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.07.2011 11:49:04
-- Module Name : cfgdev_host_tb
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.reduce_pack.all;
use work.cfgdev_pkg.all;


entity cfgdev_host_tb is
generic(
C_TSTREG_COUNT_MAX : integer := 10;

C_TSTWR_FSTADR : integer := 1;--first adr
C_TSTWR_DCOUNT : integer := 5;
C_TSTWR_FIFO   : std_logic := '1'; --0/1 - OFF/ON

C_TSTRD_FSTADR : integer := 2;--first adr
C_TSTRD_DCOUNT : integer := 5;
C_TSTRD_FIFO   : std_logic := '1';

C_HOST_DWIDTH : integer := 32;
C_CFG_DWIDTH  : integer := 16
);
port(
p_out_tst : out std_logic_vector(31 downto 0)
);
end entity cfgdev_host_tb;

architecture behavior of cfgdev_host_tb is

constant CI_OPT : integer := 0;--1 - for eth pkt

constant C_HOSTCLK_PERIOD : TIME := 30 ns;
constant C_CFGCLK_PERIOD  : TIME := 6 ns;

component cfgdev_buf
generic(
G_DWIDTH : integer := 32
);
port(
din         : in  std_logic_vector(G_DWIDTH - 1 downto 0);
wr_en       : in  std_logic;
wr_clk      : in  std_logic;

dout        : out std_logic_vector(G_DWIDTH - 1 downto 0);
rd_en       : in  std_logic;
rd_clk      : in  std_logic;

empty       : out std_logic;
full        : out std_logic;
prog_full   : out std_logic;

rst         : in  std_logic
);
end component cfgdev_buf;

--for m_devcfg : cfgdev_host use entity work.cfgdev_host(behav1);
for m_devcfg : cfgdev_host use entity work.cfgdev_host(behav1);

-- Small delay for simulation purposes.
constant dly : time := 1 ps;--50 ns;

signal p_in_cfgclk      : std_logic;
signal p_in_rst         : std_logic;

signal i_cfg_dev        : std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_adr        : std_logic_vector(C_CFG_DWIDTH - 1 downto 0);
signal i_cfg_ald        : std_logic;
signal i_cfg_fifo       : std_logic;
signal i_cfg_wr         : std_logic;
signal i_cfg_rd         : std_logic;
signal i_cfg_txd        : std_logic_vector(C_CFG_DWIDTH - 1 downto 0);
signal i_cfg_rxd        : std_logic_vector(C_CFG_DWIDTH - 1 downto 0);
signal i_cfg_done       : std_logic;
signal i_cfg_txbuf_full : std_logic;
signal i_cfg_txbuf_empty: std_logic;
signal i_cfg_rxbuf_full : std_logic;
signal i_cfg_rxbuf_empty: std_logic;

signal i_cfg_acnt       : unsigned(i_cfg_adr'range);
type TUsrRegs is array (0 to C_TSTREG_COUNT_MAX - 1) of unsigned(i_cfg_rxd'range);
signal i_reg            : TUsrRegs;

type TFifo_tst is  record
di    : std_logic_vector(i_cfg_rxd'range);
wr    : std_logic;
do    : std_logic_vector(i_cfg_rxd'range);
rd    : std_logic;
full  : std_logic;
empty : std_logic;
end record;

signal i_fifo           : TFifo_tst;

constant CI_USRD_COUNT_MAX : integer := 6;
constant CI_CFGPKT_HEADER_DCOUNT : integer := C_CFGPKTH_DCOUNT + CI_OPT;

type TUsrPkt is array (0 to CI_CFGPKT_HEADER_DCOUNT + CI_USRD_COUNT_MAX - 1)
                                              of unsigned(i_cfg_txd'range);
type TUsrPkts is array (0 to 10) of TUsrPkt;
signal i_pkts           : TUsrPkts;

signal i_host_clk       : std_logic;
signal i_host_rxd       : std_logic_vector(256 downto 0);
signal i_host_rd        : std_logic;
signal i_hrxbuf_empty   : std_logic;
signal i_host_txd       : unsigned(256 downto 0);
signal i_host_wr        : std_logic;

signal test             : std_logic_vector(31 downto 0);


begin --architecture behavior

gen_host_clk : process
begin
  i_host_clk <= '0';
  wait for C_HOSTCLK_PERIOD / 2;
  i_host_clk <= '1';
  wait for C_HOSTCLK_PERIOD / 2;
end process;

gen_clk_usr : process
begin
  p_in_cfgclk <= '0';
  wait for C_CFGCLK_PERIOD / 2;
  p_in_cfgclk <= '1';
  wait for C_CFGCLK_PERIOD / 2;
end process;

p_in_rst <= '1', '0' after 1 us;

p_out_tst <= test;

m_devcfg : cfgdev_host
generic map(
G_DBG => "OFF",
G_HOST_DWIDTH => C_HOST_DWIDTH,
G_CFG_DWIDTH => C_CFG_DWIDTH
)
port map (
-------------------------------
--HOST
-------------------------------
p_out_hrxbuf_do      => i_host_rxd(C_HOST_DWIDTH - 1 downto 0),
p_in_hrxbuf_rd       => i_host_rd   ,
p_out_hrxbuf_full    => open,
p_out_hrxbuf_empty   => i_hrxbuf_empty,

p_in_htxbuf_di       => std_logic_vector(i_host_txd(C_HOST_DWIDTH - 1 downto 0)),
p_in_htxbuf_wr       => i_host_wr  ,
p_out_htxbuf_full    => open,
p_out_htxbuf_empty   => open,

p_out_hirq           => open,
p_in_hclk            => i_host_clk,

-------------------------------
--CFG
-------------------------------
p_out_cfg_dadr       => i_cfg_dev,
p_out_cfg_radr       => i_cfg_adr,
p_out_cfg_radr_ld    => i_cfg_ald,
p_out_cfg_radr_fifo  => i_cfg_fifo,
p_out_cfg_wr         => i_cfg_wr,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_txbuf_full  => i_cfg_txbuf_full ,
p_in_cfg_txbuf_empty => i_cfg_txbuf_empty,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_rxbuf_full  => i_cfg_rxbuf_full ,
p_in_cfg_rxbuf_empty => i_cfg_rxbuf_empty,
p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => p_in_cfgclk,

-------------------------------
--DBG
-------------------------------
p_in_tst             => "00000000000000000000000000000000",
p_out_tst            => open,

-------------------------------
--System
-------------------------------
p_in_rst             => p_in_rst
);

i_host_rd <= not i_hrxbuf_empty;

i_cfg_txbuf_full  <= i_fifo.full and i_cfg_fifo;
i_cfg_txbuf_empty <= i_fifo.empty and i_cfg_fifo;

i_cfg_rxbuf_full  <= i_cfg_txbuf_full ;
i_cfg_rxbuf_empty <= i_cfg_txbuf_empty;


i_fifo.wr <= i_cfg_wr and i_cfg_fifo;
i_fifo.rd <= i_cfg_rd and i_cfg_fifo;

i_fifo.di <= i_cfg_txd;

m_fifo : cfgdev_buf
generic map(
G_DWIDTH => C_CFG_DWIDTH
)
port map(
din         => i_fifo.di,
wr_en       => i_fifo.wr,
wr_clk      => p_in_cfgclk,

dout        => i_fifo.do,
rd_en       => i_fifo.rd,
rd_clk      => p_in_cfgclk,

empty       => i_fifo.empty,
full        => open,
prog_full   => i_fifo.full,

rst         => p_in_rst
);

--Register adress
process(p_in_rst,p_in_cfgclk)
begin
if p_in_rst='1' then
  i_cfg_acnt <= (others => '0');
elsif p_in_cfgclk'event and p_in_cfgclk='1' then
  if i_cfg_ald = '1' then
    i_cfg_acnt <= UNSIGNED(i_cfg_adr);
  else
    if i_cfg_fifo = '0' and (i_cfg_wr = '1' or i_cfg_rd = '1') then
      i_cfg_acnt <= i_cfg_acnt + 1;
    end if;
  end if;
end if;
end process;

--write to reg
process(p_in_rst,p_in_cfgclk)
begin
if p_in_rst='1' then
  for i in 0 to i_reg'length - 1 loop
    i_reg(i) <= (others => '0');
  end loop;
elsif p_in_cfgclk'event and p_in_cfgclk='1' then
  if i_cfg_wr = '1' and i_cfg_fifo = '0' then
    for i in 0 to i_reg'length - 1 loop
      if i_cfg_acnt = i then
        i_reg(i) <= UNSIGNED(i_cfg_txd(i_reg(i)'high downto 0));
      end if;
    end loop;
  end if;
end if;
end process;

--read from reg
process(i_reg, i_cfg_acnt, i_cfg_rxd)
begin
if i_cfg_fifo = '0' then
for i in 0 to i_reg'length - 1 loop
  if i_cfg_acnt = i then
    i_cfg_rxd <= std_logic_vector(i_reg(i));
  end if;
end loop;
else
i_cfg_rxd <= i_fifo.do;
end if;
end process;



process
begin
-------------------
--INIT
-------------------
for i in 0 to i_pkts'length-1 loop
  for x in 0 to i_pkts(i)'length-1 loop
    i_pkts(i)(x) <= (others => '0');
  end loop;
end loop;

i_host_wr <= '0';
i_host_txd <= (others => '0'); test <= (others => '0');

--Pkt0
i_pkts(0)(0 + CI_OPT)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT) <= TO_UNSIGNED(16#0A#, C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT + 1);
i_pkts(0)(0 + CI_OPT)(C_CFGPKT_WR_BIT) <= C_CFGPKT_WR;
i_pkts(0)(0 + CI_OPT)(C_CFGPKT_FIFO_BIT) <= C_TSTWR_FIFO;

i_pkts(0)(1 + CI_OPT) <= TO_UNSIGNED(C_TSTWR_FSTADR, i_pkts(0)(1)'length);--Start Adr
i_pkts(0)(2 + CI_OPT) <= TO_UNSIGNED(C_TSTWR_DCOUNT, i_pkts(0)(2)'length);--Len
if CI_OPT = 1 then
i_pkts(0)(0) <= TO_UNSIGNED((CI_CFGPKT_HEADER_DCOUNT + C_TSTWR_DCOUNT) * 2, i_pkts(0)(0)'length);
end if;

i_pkts(0)(3 + CI_OPT) <= TO_UNSIGNED(16#1011#, i_pkts(0)(0)'length);
i_pkts(0)(4 + CI_OPT) <= TO_UNSIGNED(16#2012#, i_pkts(0)(0)'length);
i_pkts(0)(5 + CI_OPT) <= TO_UNSIGNED(16#3013#, i_pkts(0)(0)'length);
i_pkts(0)(6 + CI_OPT) <= TO_UNSIGNED(16#4014#, i_pkts(0)(0)'length);
i_pkts(0)(7 + CI_OPT) <= TO_UNSIGNED(16#5015#, i_pkts(0)(0)'length);
i_pkts(0)(8 + CI_OPT) <= TO_UNSIGNED(16#6016#, i_pkts(0)(0)'length);

--Pkt1
i_pkts(1)(0 + CI_OPT)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT) <= TO_UNSIGNED(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT + 1);
i_pkts(1)(0 + CI_OPT)(C_CFGPKT_WR_BIT) <= C_CFGPKT_RD;
i_pkts(1)(0 + CI_OPT)(C_CFGPKT_FIFO_BIT) <= C_TSTRD_FIFO;

i_pkts(1)(1 + CI_OPT) <= TO_UNSIGNED(C_TSTRD_FSTADR, i_pkts(0)(1)'length);--Start Adr
i_pkts(1)(2 + CI_OPT) <= TO_UNSIGNED(C_TSTRD_DCOUNT, i_pkts(0)(2)'length);--Len
if CI_OPT = 1 then
i_pkts(1)(0) <= TO_UNSIGNED((CI_CFGPKT_HEADER_DCOUNT) * 2, i_pkts(1)(0)'length);
end if;

i_pkts(1)(3 + CI_OPT) <= TO_UNSIGNED(16#01#, i_pkts(0)(0)'length);
i_pkts(1)(4 + CI_OPT) <= TO_UNSIGNED(16#02#, i_pkts(0)(0)'length);
i_pkts(1)(5 + CI_OPT) <= TO_UNSIGNED(16#03#, i_pkts(0)(0)'length);
i_pkts(1)(6 + CI_OPT) <= TO_UNSIGNED(16#04#, i_pkts(0)(0)'length);
i_pkts(1)(7 + CI_OPT) <= TO_UNSIGNED(16#04#, i_pkts(0)(0)'length);

--Pkt2
i_pkts(2)(0 + CI_OPT)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT) <= TO_UNSIGNED(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT + 1);
i_pkts(2)(0 + CI_OPT)(C_CFGPKT_WR_BIT) <= C_CFGPKT_RD;
i_pkts(2)(0 + CI_OPT)(C_CFGPKT_FIFO_BIT) <= '0';

i_pkts(2)(1 + CI_OPT) <= TO_UNSIGNED(16#02#, i_pkts(0)(1)'length);--Start Adr
i_pkts(2)(2 + CI_OPT) <= TO_UNSIGNED(10#02#, i_pkts(0)(2)'length);--Len
if CI_OPT = 1 then
i_pkts(2)(0) <= TO_UNSIGNED((CI_CFGPKT_HEADER_DCOUNT) * 2, i_pkts(2)(0)'length);
end if;

i_pkts(2)(3 + CI_OPT) <= TO_UNSIGNED(16#01#, i_pkts(0)(0)'length);
i_pkts(2)(4 + CI_OPT) <= TO_UNSIGNED(16#02#, i_pkts(0)(0)'length);
i_pkts(2)(5 + CI_OPT) <= TO_UNSIGNED(16#03#, i_pkts(0)(0)'length);
i_pkts(2)(6 + CI_OPT) <= TO_UNSIGNED(16#04#, i_pkts(0)(0)'length);
i_pkts(2)(7 + CI_OPT) <= TO_UNSIGNED(16#04#, i_pkts(0)(0)'length);


--Pkt3
i_pkts(3)(0 + CI_OPT)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT) <= TO_UNSIGNED(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT + 1);
i_pkts(3)(0 + CI_OPT)(C_CFGPKT_WR_BIT) <= C_CFGPKT_WR;
i_pkts(3)(0 + CI_OPT)(C_CFGPKT_FIFO_BIT) <= '0';

i_pkts(3)(1 + CI_OPT) <= TO_UNSIGNED(16#01#, i_pkts(0)(1)'length);--Start Adr
i_pkts(3)(2 + CI_OPT) <= TO_UNSIGNED(10#02#, i_pkts(0)(2)'length);--Len
if CI_OPT = 1 then
i_pkts(3)(0) <= TO_UNSIGNED((CI_CFGPKT_HEADER_DCOUNT + 2) * 2, i_pkts(3)(0)'length);
end if;

i_pkts(3)(3 + CI_OPT) <= TO_UNSIGNED(16#1021#, i_pkts(0)(0)'length);
i_pkts(3)(4 + CI_OPT) <= TO_UNSIGNED(16#2022#, i_pkts(0)(0)'length);
i_pkts(3)(5 + CI_OPT) <= TO_UNSIGNED(16#3023#, i_pkts(0)(0)'length);
i_pkts(3)(6 + CI_OPT) <= TO_UNSIGNED(16#4024#, i_pkts(0)(0)'length);
i_pkts(3)(7 + CI_OPT) <= TO_UNSIGNED(16#5025#, i_pkts(0)(0)'length);


--Pkt4
i_pkts(4)(0 + CI_OPT)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT) <= TO_UNSIGNED(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT + 1);
i_pkts(4)(0 + CI_OPT)(C_CFGPKT_WR_BIT) <= C_CFGPKT_WR;
i_pkts(4)(0 + CI_OPT)(C_CFGPKT_FIFO_BIT) <= '0';

i_pkts(4)(1 + CI_OPT) <= TO_UNSIGNED(16#02#, i_pkts(0)(1)'length);--Start Adr
i_pkts(4)(2 + CI_OPT) <= TO_UNSIGNED(10#03#, i_pkts(0)(2)'length);--Len
if CI_OPT = 1 then
i_pkts(4)(0) <= TO_UNSIGNED((CI_CFGPKT_HEADER_DCOUNT + 3) * 2, i_pkts(4)(0)'length);
end if;

i_pkts(4)(3 + CI_OPT) <= TO_UNSIGNED(16#1031#, i_pkts(0)(0)'length);
i_pkts(4)(4 + CI_OPT) <= TO_UNSIGNED(16#2032#, i_pkts(0)(0)'length);
i_pkts(4)(5 + CI_OPT) <= TO_UNSIGNED(16#3033#, i_pkts(0)(0)'length);
i_pkts(4)(6 + CI_OPT) <= TO_UNSIGNED(16#4034#, i_pkts(0)(0)'length);
i_pkts(4)(7 + CI_OPT) <= TO_UNSIGNED(16#5035#, i_pkts(0)(0)'length);


-------------------
--WORK
-------------------
wait until p_in_rst='0';
wait for 1 us;


--####################################
--C_HOST_DWIDTH < C_CFG_DWIDTH
--####################################
if C_HOST_DWIDTH < C_CFG_DWIDTH then
--PKT(Write)
for i in 0 to CI_CFGPKT_HEADER_DCOUNT - 1 loop
for x in 0 to (C_CFG_DWIDTH / C_HOST_DWIDTH) - 1  loop
wait until rising_edge(i_host_clk);
i_host_txd(C_HOST_DWIDTH - 1 downto 0) <= i_pkts(0)(i)((C_HOST_DWIDTH * (x + 1)) - 1 downto (C_HOST_DWIDTH * x));
i_host_wr <= '1';
end loop;
end loop;
--DATA
for i in 0 to C_TSTWR_DCOUNT - 1 loop
for x in 0 to (C_CFG_DWIDTH / C_HOST_DWIDTH) - 1  loop
wait until rising_edge(i_host_clk);
i_host_txd(C_HOST_DWIDTH - 1 downto 0) <= i_pkts(0)(CI_CFGPKT_HEADER_DCOUNT + i)((C_HOST_DWIDTH * (x + 1)) - 1 downto (C_HOST_DWIDTH * x));
i_host_wr <= '1';
end loop;
end loop;
wait until rising_edge(i_host_clk);
i_host_wr <= '0';


wait until rising_edge(p_in_cfgclk) and i_cfg_done = '1';
wait for 1 us;--500 ns;--


--PKT(Read)
for i in 0 to CI_CFGPKT_HEADER_DCOUNT - 1 loop
for x in 0 to (C_CFG_DWIDTH / C_HOST_DWIDTH) - 1  loop
wait until rising_edge(i_host_clk);
i_host_txd(C_HOST_DWIDTH - 1 downto 0) <= i_pkts(1)(i)((C_HOST_DWIDTH * (x + 1)) - 1 downto (C_HOST_DWIDTH * x));
i_host_wr <= '1';
end loop;
end loop;
wait until rising_edge(i_host_clk);
i_host_wr <= '0';



else
--####################################
--C_HOST_DWIDTH >= C_CFG_DWIDTH
--####################################
--PKT(Write)
for i in 0 to (CI_CFGPKT_HEADER_DCOUNT + C_TSTWR_DCOUNT) - 1 loop
wait until rising_edge(i_host_clk);
i_host_txd((C_CFG_DWIDTH * ((i mod ((C_HOST_DWIDTH / C_CFG_DWIDTH))) + 1)) - 1
              downto (C_CFG_DWIDTH * (i mod ((C_HOST_DWIDTH / C_CFG_DWIDTH))))) <= i_pkts(0)(i)(C_CFG_DWIDTH - 1 downto 0);

if ((i mod (C_HOST_DWIDTH / C_CFG_DWIDTH)) = ((C_HOST_DWIDTH / C_CFG_DWIDTH) - 1))
      or (i = (CI_CFGPKT_HEADER_DCOUNT + C_TSTWR_DCOUNT) - 1) then
i_host_wr <= '1';
else
i_host_wr <= '0';
end if;
end loop;
wait until rising_edge(i_host_clk);
i_host_wr <= '0';


wait until rising_edge(p_in_cfgclk) and i_cfg_done = '1';
wait for 1 us;

--PKT(Write)
for i in 0 to (CI_CFGPKT_HEADER_DCOUNT) - 1 loop
wait until rising_edge(i_host_clk);
i_host_txd((C_CFG_DWIDTH * ((i mod ((C_HOST_DWIDTH / C_CFG_DWIDTH))) + 1)) - 1
              downto (C_CFG_DWIDTH * (i mod ((C_HOST_DWIDTH / C_CFG_DWIDTH))))) <= i_pkts(1)(i)(C_CFG_DWIDTH - 1 downto 0);

if ((i mod (C_HOST_DWIDTH / C_CFG_DWIDTH)) = ((C_HOST_DWIDTH / C_CFG_DWIDTH) - 1))
      or (i = (CI_CFGPKT_HEADER_DCOUNT) - 1) then
i_host_wr <= '1';
else
i_host_wr <= '0';
end if;
end loop;
wait until rising_edge(i_host_clk);
i_host_wr <= '0';

end if; --C_HOST_DWIDTH < C_CFG_DWIDTH


wait;

end process;


end architecture behavior;
