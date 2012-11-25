-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2012 14:08:21
-- Module Name : prom_ld
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
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prom_phypin_pkg.all;

entity prom_ld is
port(
p_in_tmr_en      : in    std_logic;
p_in_tmr_stb     : in    std_logic;

-------------------------------
--Связь с HOST
-------------------------------
p_out_host_rxrdy : out   std_logic;                      --//1 - rdy to used
p_out_host_rxd   : out   std_logic_vector(31 downto 0);  --//cfgdev -> host
p_in_host_rd     : in    std_logic;                      --//

p_out_txbuf_full : out   std_logic;
p_out_host_txrdy : out   std_logic;                      --//1 - rdy to used
p_in_host_txd    : in    std_logic_vector(31 downto 0);  --//cfgdev <- host
p_in_host_wr     : in    std_logic;                      --//

p_in_host_clk    : in    std_logic;

p_out_hirq       : out   std_logic;                      --//прерывание
p_out_herr       : out   std_logic;

-------------------------------
--PHY
-------------------------------
p_in_phy         : in    TPromPhyIN;
p_out_phy        : out   TPromPhyOUT;
p_inout_phy      : inout TPromPhyINOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end prom_ld;

architecture behavioral of prom_ld is

--component prog_flash
--port (
--p_out_usr_rd     : out  std_logic;
--p_in_usr_txd     : in   std_logic_vector(31 downto 0);
--p_in_usr_txrdy_n : in   std_logic;
--
--p_out_phy_adr    : out  std_logic_vector(23 downto 0);
--p_in_phy_d       : in   std_logic_vector(15 downto 0);
--p_out_phy_d      : out  std_logic_vector(15 downto 0);
--p_out_phy_dio_t  : out  std_logic;
--p_out_phy_oe_n   : out  std_logic;
--p_out_phy_we_n   : out  std_logic;
--p_out_phy_cs_n   : out  std_logic;
--p_in_phy_wait    : in   std_logic;
--
--p_out_rdy        : out  std_logic;
--p_out_status     : out  std_logic_vector(3 downto 0);
--
--p_out_tst        : out  std_logic_vector(31 downto 0);
--p_in_tst         : in   std_logic_vector(31 downto 0);
--
--p_in_clk         : in   std_logic;
--p_in_rst         : in   std_logic
--);
--end component;

component prog_flash
port(
p_out_usr_rd     : out  std_logic;
p_in_usr_txd     : in   std_logic_vector(31 downto 0);
p_in_usr_txrdy_n : in   std_logic;

p_out_phy_adr    : out  std_logic_vector(23 downto 0);
p_in_phy_d       : in   std_logic_vector(15 downto 0);
p_out_phy_d      : out  std_logic_vector(15 downto 0);
p_out_phy_dio_t  : out  std_logic;
p_out_phy_oe_n   : out  std_logic;
p_out_phy_we_n   : out  std_logic;
p_out_phy_cs_n   : out  std_logic;
p_in_phy_wait    : in   std_logic;

p_out_rdy        : out  std_logic;
p_out_status     : out  std_logic_vector(3 downto 0);

p_out_tst        : out  std_logic_vector(31 downto 0);
p_in_tst         : in   std_logic_vector(31 downto 0);

p_in_clk         : in   std_logic;
p_in_rst         : in   std_logic
);
end component;

component prom_buf
port (
din    : in  std_logic_vector(31 downto 0);
wr_en  : in  std_logic;
wr_clk : in  std_logic;

dout   : out std_logic_vector(31 downto 0);
rd_en  : in  std_logic;
rd_clk : in  std_logic;

full   : out std_logic;
empty  : out std_logic;

rst    : in  std_logic
);
end component;

signal i_tmr_en         : std_logic;
signal sr_core_start    : std_logic_vector(0 to 2);

signal i_txbuf_do       : std_logic_vector(31 downto 0);
signal i_txbuf_rd       : std_logic;
signal i_txbuf_empty    : std_logic;
signal i_txbuf_empty_tmp: std_logic;
signal i_txbuf_empty_en : std_logic;

signal i_phy_di         : std_logic_vector(15 downto 0);
signal i_phy_do         : std_logic_vector(15 downto 0);
signal i_phy_dt         : std_logic;

signal i_core_rdy       : std_logic;
signal i_core_status    : std_logic_vector(3 downto 0);

signal i_tst_out        : std_logic_vector(31 downto 0);


--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0) <= i_tst_out;


--//----------------------------------
--//
--//----------------------------------
p_out_hirq <= i_core_status(3);
p_out_herr <= OR_reduce(i_core_status(2 downto 0));

p_out_host_rxrdy <= '0';
p_out_host_txrdy <= i_txbuf_empty;

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_tmr_en <= p_in_tmr_en;
    sr_core_start <= p_in_tmr_stb & sr_core_start(0 to 1);

    if i_txbuf_empty_tmp = '1' then
      i_txbuf_empty_en <= '0';
    elsif i_tmr_en = '1' and sr_core_start(1) = '1' and sr_core_start(2) = '0' then
      i_txbuf_empty_en <= '1';
    end if;
  end if;
end process;

i_txbuf_empty<=not (not i_txbuf_empty_tmp and i_txbuf_empty_en) when i_tmr_en = '1' else i_txbuf_empty_tmp;

m_txbuf : prom_buf
port map(
din    => p_in_host_txd,
wr_en  => p_in_host_wr,
wr_clk => p_in_host_clk,

dout   => i_txbuf_do,
rd_en  => i_txbuf_rd,
rd_clk => p_in_clk,

full   => p_out_txbuf_full,
empty  => i_txbuf_empty_tmp,

rst    => p_in_rst
);


--mmm : prog_flash
--port map(
--p_out_usr_rd     => open,
--p_in_usr_txd     => (others=>'0'),
--p_in_usr_txrdy_n => '0',
--
--p_out_phy_adr    => open,
--p_in_phy_d       => (others=>'0'),
--p_out_phy_d      => open,
--p_out_phy_dio_t  => open,
--p_out_phy_oe_n   => open,
--p_out_phy_we_n   => open,
--p_out_phy_cs_n   => open,
--p_in_phy_wait    => '0',
--
--p_out_rdy        => open,
--p_out_status     => open,
--
--p_out_tst        => open,
--p_in_tst         => (others=>'0'),
--
--p_in_clk         => p_in_clk,
--p_in_rst         => p_in_rst
--);


m_core : prog_flash
port map(
p_out_usr_rd     => i_txbuf_rd,
p_in_usr_txd     => i_txbuf_do,
p_in_usr_txrdy_n => i_txbuf_empty,

p_out_phy_adr    => p_out_phy.a,
p_in_phy_d       => i_phy_di,
p_out_phy_d      => i_phy_do,
p_out_phy_dio_t  => i_phy_dt,
p_out_phy_oe_n   => p_out_phy.oe_n,
p_out_phy_we_n   => p_out_phy.we_n,
p_out_phy_cs_n   => p_out_phy.cs_n,
p_in_phy_wait    => p_in_phy.wt,

p_out_rdy        => i_core_rdy,
p_out_status     => i_core_status,

p_out_tst        => i_tst_out,
p_in_tst         => (others=>'0'),

p_in_clk         => p_in_clk,
p_in_rst         => p_in_rst
);

p_inout_phy.d <= i_phy_do when i_phy_dt = '1' else (others => 'Z');
i_phy_di <= p_inout_phy.d;



--END MAIN
end behavioral;

