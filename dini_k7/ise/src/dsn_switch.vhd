-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.01
-- Module Name : dsn_switch
--
-- Назначение/Описание :
--  Запись/Чтение регистров устройств
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_def.all;
use work.eth_pkg.all;
use work.prj_cfg.all;

entity dsn_switch is
generic(
G_ETH_CH_COUNT : integer:=1;
G_ETH_DWIDTH : integer:=32;
G_VBUFI_OWIDTH : integer:=32;
G_HOST_DWIDTH : integer:=32
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_clk              : in   std_logic;

p_in_cfg_adr              : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld           : in   std_logic;
p_in_cfg_adr_fifo         : in   std_logic;

p_in_cfg_txdata           : in   std_logic_vector(15 downto 0);
p_in_cfg_wd               : in   std_logic;

p_out_cfg_rxdata          : out  std_logic_vector(15 downto 0);
p_in_cfg_rd               : in   std_logic;

p_in_cfg_done             : in   std_logic;

-------------------------------
--HOST
-------------------------------
--host -> dev
p_in_eth_htxbuf_di        : in   std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_eth_htxbuf_wr        : in   std_logic;
p_out_eth_htxbuf_full     : out  std_logic;
p_out_eth_htxbuf_empty    : out  std_logic;

--host <- dev
p_out_eth_hrxbuf_do       : out  std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_eth_hrxbuf_rd        : in   std_logic;
p_out_eth_hrxbuf_full     : out  std_logic;
p_out_eth_hrxbuf_empty    : out  std_logic;

p_out_eth_hirq            : out  std_logic;

p_in_hclk                 : in   std_logic;

-------------------------------
--ETH
-------------------------------
p_in_eth_tmr_irq          : in   std_logic;
p_in_eth_tmr_en           : in   std_logic;
p_in_eth_clk              : in   std_logic;
p_in_eth                  : in   TEthOUTs;
p_out_eth                 : out  TEthINs;

-------------------------------
--VBUFI
-------------------------------
p_in_vbufi_rdclk          : in   std_logic;
p_out_vbufi_do            : out  std_logic_vector(G_VBUFI_OWIDTH - 1 downto 0);
p_in_vbufi_rd             : in   std_logic;
p_out_vbufi_empty         : out  std_logic;
p_out_vbufi_full          : out  std_logic;
p_out_vbufi_pfull         : out  std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst                  : in   std_logic_vector(31 downto 0);
p_out_tst                 : out  std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst     : in    std_logic
);
end dsn_switch;

architecture behavioral of dsn_switch is

component host_ethg_txfifo
port(
din         : IN  std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(G_ETH_DWIDTH - 1 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component;

component host_ethg_rxfifo
port(
din         : IN  std_logic_vector(G_ETH_DWIDTH - 1 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component;

component ethg_vctrl_rxfifo
port(
din         : IN  std_logic_vector(G_ETH_DWIDTH - 1 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(G_VBUFI_OWIDTH - 1 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component;

component video_pkt_filter
generic(
G_DWIDTH : integer := 32;
G_FRR_COUNT : integer := 3
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_frr        : in    TEthFRR;

--------------------------------------
--Upstream Port
--------------------------------------
p_in_upp_data   : in    std_logic_vector(G_DWIDTH - 1 downto 0);
p_in_upp_wr     : in    std_logic;
p_in_upp_eof    : in    std_logic;
p_in_upp_sof    : in    std_logic;

--------------------------------------
--Downstream Port
--------------------------------------
p_out_dwnp_data : out   std_logic_vector(G_DWIDTH - 1 downto 0);
p_out_dwnp_wr   : out   std_logic;
p_out_dwnp_eof  : out   std_logic;
p_out_dwnp_sof  : out   std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst        : in    std_logic_vector(31 downto 0);
p_out_tst       : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk        : in    std_logic;
p_in_rst        : in    std_logic
);
end component;

signal i_cfg_adr_cnt                 : std_logic_vector(7 downto 0);

signal h_reg_ctrl                    : std_logic_vector(C_SWT_REG_CTRL_LAST_BIT downto 0);
signal h_reg_eth_host_frr            : TEthFRR;
signal h_reg_eth_vctrl_frr           : TEthFRR;

signal b_rst_eth_bufs                : std_logic;
signal b_rst_vctrl_bufs              : std_logic;

signal syn_eth_rxd                   : std_logic_vector(G_ETH_DWIDTH - 1 downto 0);
signal syn_eth_rxd_wr                : std_logic;
signal syn_eth_rxd_sof               : std_logic;
signal syn_eth_rxd_eof               : std_logic;
signal syn_eth_host_frr              : TEthFRR;
signal syn_eth_vctrl_frr             : TEthFRR;

signal i_eth_txbuf_full              : std_logic;
signal i_eth_txbuf_empty             : std_logic;

signal i_eth_rxbuf_full              : std_logic;
signal i_eth_rxbuf_empty             : std_logic;
signal i_eth_rxd_rdy_dly             : std_logic_vector(2 downto 0);
signal i_eth_rxbuf_fltr_dout         : std_logic_vector(G_ETH_DWIDTH - 1 downto 0);
signal i_eth_rxbuf_fltr_den          : std_logic;
signal i_eth_rxbuf_fltr_eof          : std_logic;
signal eclk_eth_rxd_rdy_w            : std_logic;
signal eclk_eth_rxd_rdy_wcnt         : std_logic_vector(2 downto 0);
signal hclk_eth_rxd_rdy              : std_logic;

signal i_vbufi_fltr_dout             : std_logic_vector(G_ETH_DWIDTH - 1 downto 0);
signal i_vbufi_fltr_dout_swap        : std_logic_vector(G_ETH_DWIDTH - 1 downto 0);
signal i_vbufi_fltr_den              : std_logic;
signal i_vbufi_pfull                 : std_logic;
signal i_vbufi_rdclk                 : std_logic;

signal hclk_tmr_en,i_tmr_en          : std_logic;
signal hclk_eth_tx_start             : std_logic;
signal sr_eth_tx_start               : std_logic_vector(0 to 2):=(others=>'0');
signal i_eth_txbuf_empty_en          : std_logic;


--MAIN
begin

------------------------------------
--Технологические сигналы
------------------------------------
p_out_tst(0) <= b_rst_vctrl_bufs;
p_out_tst(1) <= '0';
p_out_tst(31 downto 2) <= (others=>'0');



----------------------------------------------------
--Запись/чтение регистров
----------------------------------------------------
--Счетчик адреса регистров
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_rst = '1' then
    i_cfg_adr_cnt <= (others=>'0');
  else
    if p_in_cfg_adr_ld = '1' then
      i_cfg_adr_cnt <= p_in_cfg_adr;
    else
      if p_in_cfg_adr_fifo = '0' and (p_in_cfg_wd = '1' or p_in_cfg_rd = '1') then
        i_cfg_adr_cnt <= i_cfg_adr_cnt + 1;
      end if;
    end if;
  end if;
end if;
end process;

--Запись регистров
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_rst = '1' then
    h_reg_ctrl <= (others=>'0');

    for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_HOST_FRR_COUNT) - 1 loop
      h_reg_eth_host_frr(2 * i) <= (others=>'0');
      h_reg_eth_host_frr((2 * i) + 1) <= (others=>'0');
    end loop;

    for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_VCTRL_FRR_COUNT) - 1 loop
      h_reg_eth_vctrl_frr(2 * i) <= (others=>'0');
      h_reg_eth_vctrl_frr((2 * i) + 1) <= (others=>'0');
    end loop;

  else
    if p_in_cfg_wd = '1' then
        if i_cfg_adr_cnt = CONV_STD_LOGIC_VECTOR(C_SWT_REG_CTRL, i_cfg_adr_cnt'length) then
          h_reg_ctrl <= p_in_cfg_txdata(h_reg_ctrl'high downto 0);

        elsif i_cfg_adr_cnt(i_cfg_adr_cnt'high downto log2(C_SWT_FRR_COUNT_MAX)) =
            CONV_STD_LOGIC_VECTOR(C_SWT_REG_FRR_ETHG_HOST/C_SWT_FRR_COUNT_MAX
                                    ,(i_cfg_adr_cnt'high - log2(C_SWT_FRR_COUNT_MAX) + 1)) then
        --Маски фильтрации пакетов: ETH<->HOST
          for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_HOST_FRR_COUNT) - 1 loop
            if i_cfg_adr_cnt(log2(C_SWT_FRR_COUNT_MAX) - 1 downto 0) = i then
              h_reg_eth_host_frr(2 * i)  <= p_in_cfg_txdata(7 downto 0);
              h_reg_eth_host_frr((2 * i) + 1) <= p_in_cfg_txdata(15 downto 8);
            end if;
          end loop;

        elsif i_cfg_adr_cnt(i_cfg_adr_cnt'high downto log2(C_SWT_FRR_COUNT_MAX)) =
          CONV_STD_LOGIC_VECTOR(C_SWT_REG_FRR_ETHG_VCTRL/C_SWT_FRR_COUNT_MAX
                                  ,(i_cfg_adr_cnt'high - log2(C_SWT_FRR_COUNT_MAX) + 1)) then
        --Маски фильтрации пакетов: ETH->VCTRL
          for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_VCTRL_FRR_COUNT) - 1 loop
            if i_cfg_adr_cnt(log2(C_SWT_FRR_COUNT_MAX) - 1 downto 0) = i then
              h_reg_eth_vctrl_frr(2 * i)  <= p_in_cfg_txdata(7 downto 0);
              h_reg_eth_vctrl_frr((2 * i) + 1) <= p_in_cfg_txdata(15 downto 8);
            end if;
          end loop;

        end if;
    end if;
  end if;
end if;
end process;

--Чтение регистров
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_rst = '1' then
    p_out_cfg_rxdata <= (others=>'0');
  else
    if p_in_cfg_rd = '1' then
        if i_cfg_adr_cnt = CONV_STD_LOGIC_VECTOR(C_SWT_REG_CTRL, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata <= EXT(h_reg_ctrl, p_out_cfg_rxdata'length);

        elsif i_cfg_adr_cnt(i_cfg_adr_cnt'high downto log2(C_SWT_FRR_COUNT_MAX)) =
          CONV_STD_LOGIC_VECTOR(C_SWT_REG_FRR_ETHG_HOST/C_SWT_FRR_COUNT_MAX
                                    ,(i_cfg_adr_cnt'high - log2(C_SWT_FRR_COUNT_MAX) + 1)) then
        --Маски фильтрации пакетов: ETH<->HOST
          for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_HOST_FRR_COUNT) - 1 loop
            if i_cfg_adr_cnt(log2(C_SWT_FRR_COUNT_MAX) - 1 downto 0) = i then
              p_out_cfg_rxdata(7 downto 0) <= h_reg_eth_host_frr(2 * i)  ;
              p_out_cfg_rxdata(15 downto 8) <= h_reg_eth_host_frr((2 * i) + 1);
            end if;
          end loop;

        elsif i_cfg_adr_cnt(i_cfg_adr_cnt'high downto log2(C_SWT_FRR_COUNT_MAX)) =
          CONV_STD_LOGIC_VECTOR(C_SWT_REG_FRR_ETHG_VCTRL/C_SWT_FRR_COUNT_MAX
                                  ,(i_cfg_adr_cnt'high - log2(C_SWT_FRR_COUNT_MAX) + 1)) then
        --Маски фильтрации пакетов: ETH->VCTRL
          for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_VCTRL_FRR_COUNT) - 1 loop
            if i_cfg_adr_cnt(log2(C_SWT_FRR_COUNT_MAX) - 1 downto 0) = i then
              p_out_cfg_rxdata(7 downto 0) <= h_reg_eth_vctrl_frr(2 * i)  ;
              p_out_cfg_rxdata(15 downto 8) <= h_reg_eth_vctrl_frr((2 * i) + 1);
            end if;
          end loop;

        end if;
    end if;
  end if;
end if;
end process;


b_rst_eth_bufs <= p_in_rst or h_reg_ctrl(C_SWT_REG_CTRL_RST_ETH_BUFS_BIT);
b_rst_vctrl_bufs <= p_in_rst or h_reg_ctrl(C_SWT_REG_CTRL_RST_VCTRL_BUFS_BIT);

hclk_eth_tx_start <= p_in_eth_tmr_irq;
hclk_tmr_en <= p_in_eth_tmr_en;


--Подсинхриваем маски для FltrEthPkt началом прининятого пакета Eth
process(p_in_eth_clk)
begin
if rising_edge(p_in_eth_clk) then
  if p_in_rst = '1' then

    for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_HOST_FRR_COUNT) - 1 loop
      syn_eth_host_frr(2 * i) <= (others=>'0');
      syn_eth_host_frr((2 * i) + 1) <= (others=>'0');
    end loop;

    for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_VCTRL_FRR_COUNT) - 1 loop
      syn_eth_vctrl_frr(2 * i) <= (others=>'0');
      syn_eth_vctrl_frr((2 * i) + 1) <= (others=>'0');
    end loop;

    syn_eth_rxd <= (others=>'0');
    syn_eth_rxd_wr <= '0';
    syn_eth_rxd_sof <= '0';
    syn_eth_rxd_eof <= '0';

  else

    if p_in_eth(0).rxsof = '1' then

      for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_HOST_FRR_COUNT) - 1 loop
        syn_eth_host_frr(2 * i) <= h_reg_eth_host_frr(2 * i);
        syn_eth_host_frr((2 * i) + 1) <= h_reg_eth_host_frr((2 * i) + 1);
      end loop;

      for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_VCTRL_FRR_COUNT) - 1 loop
        syn_eth_vctrl_frr(2 * i) <= h_reg_eth_vctrl_frr(2 * i);
        syn_eth_vctrl_frr((2 * i) + 1) <= h_reg_eth_vctrl_frr((2 * i) + 1);
      end loop;

    end if;

    syn_eth_rxd <= p_in_eth(0).rxbuf_di;
    syn_eth_rxd_wr <= p_in_eth(0).rxbuf_wr;
    syn_eth_rxd_sof <= p_in_eth(0).rxsof;
    syn_eth_rxd_eof <= p_in_eth(0).rxeof;

  end if;
end if;
end process;




--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--Хост -> ETHG
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
p_out_eth_htxbuf_empty <= i_eth_txbuf_empty;
p_out_eth_htxbuf_full <= i_eth_txbuf_full;

p_out_eth(0).txbuf_full <= i_eth_txbuf_full;
p_out_eth(0).txbuf_empty <= not (not i_eth_txbuf_empty and i_eth_txbuf_empty_en)
                            when i_tmr_en = '1' else i_eth_txbuf_empty;

process(p_in_eth_clk)
begin
  if rising_edge(p_in_eth_clk) then
    i_tmr_en <= hclk_tmr_en;
    sr_eth_tx_start <= hclk_eth_tx_start & sr_eth_tx_start(0 to 1);

    if i_eth_txbuf_empty = '1' then
      i_eth_txbuf_empty_en <= '0';
    elsif i_tmr_en = '1' and sr_eth_tx_start(1) = '1' and sr_eth_tx_start(2) = '0' then
      i_eth_txbuf_empty_en <= '1';
    end if;
  end if;
end process;

m_eth_txbuf : host_ethg_txfifo
port map(
din     => p_in_eth_htxbuf_di,
wr_en   => p_in_eth_htxbuf_wr,
wr_clk  => p_in_hclk,

dout    => p_out_eth(0).txbuf_do,
rd_en   => p_in_eth(0).txbuf_rd,
rd_clk  => p_in_eth_clk,

empty   => i_eth_txbuf_empty,
full    => open,
prog_full => i_eth_txbuf_full,

rst     => b_rst_eth_bufs
);


--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--Хост <- ETHG
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
m_eth2host_pkt_fltr: video_pkt_filter
generic map(
G_DWIDTH => G_ETH_DWIDTH,
G_FRR_COUNT => C_SWT_ETH_HOST_FRR_COUNT
)
port map(
--------------------------------------
--Управление
--------------------------------------
p_in_frr        => syn_eth_host_frr,

--------------------------------------
--Upstream Port
--------------------------------------
p_in_upp_data   => syn_eth_rxd,
p_in_upp_wr     => syn_eth_rxd_wr,
p_in_upp_eof    => syn_eth_rxd_eof,
p_in_upp_sof    => syn_eth_rxd_sof,

--------------------------------------
--Downstream Port
--------------------------------------
p_out_dwnp_data => i_eth_rxbuf_fltr_dout,
p_out_dwnp_wr   => i_eth_rxbuf_fltr_den,
p_out_dwnp_eof  => i_eth_rxbuf_fltr_eof,
p_out_dwnp_sof  => open,

-------------------------------
--Технологический
-------------------------------
p_in_tst        => (others=>'0'),
p_out_tst       => open,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk        => p_in_eth_clk,
p_in_rst        => b_rst_eth_bufs
);

m_eth_rxbuf : host_ethg_rxfifo
port map(
din     => i_eth_rxbuf_fltr_dout,
wr_en   => i_eth_rxbuf_fltr_den,
wr_clk  => p_in_eth_clk,

dout    => p_out_eth_hrxbuf_do,
rd_en   => p_in_eth_hrxbuf_rd,
rd_clk  => p_in_hclk,

empty   => i_eth_rxbuf_empty,
full    => open,
prog_full => i_eth_rxbuf_full,

rst     => b_rst_eth_bufs
);

p_out_eth_hrxbuf_empty <= i_eth_rxbuf_empty;
p_out_eth_hrxbuf_full <= i_eth_rxbuf_full;

p_out_eth(0).rxbuf_empty <= i_eth_rxbuf_empty;
p_out_eth(0).rxbuf_full <= i_vbufi_pfull;

--Формируем прерываение ETH_RXBUF
process(p_in_eth_clk)
begin
if rising_edge(p_in_eth_clk) then
  if p_in_rst = '1' then
    i_eth_rxd_rdy_dly <= (others=>'0');
    eclk_eth_rxd_rdy_wcnt <= (others=>'0');
    eclk_eth_rxd_rdy_w <= '0';

  else
    i_eth_rxd_rdy_dly(0) <= i_eth_rxbuf_fltr_eof;
    i_eth_rxd_rdy_dly(1) <= i_eth_rxd_rdy_dly(0);
    i_eth_rxd_rdy_dly(2) <= i_eth_rxd_rdy_dly(1);

    --Растягиваем импульс готовности данных от модуля dsn_eth.vhd
    if i_eth_rxd_rdy_dly(2) = '1' then
      eclk_eth_rxd_rdy_w <= '1';
    elsif eclk_eth_rxd_rdy_wcnt(eclk_eth_rxd_rdy_wcnt'high) = '1' then
      eclk_eth_rxd_rdy_w <= '0';
    end if;

    if eclk_eth_rxd_rdy_w = '0' then
      eclk_eth_rxd_rdy_wcnt <= (others=>'0');
    else
      eclk_eth_rxd_rdy_wcnt <= eclk_eth_rxd_rdy_wcnt + 1;
    end if;
  end if;
end if;
end process;

--Пересинхронизация на частоту p_in_hclk
process(p_in_hclk)
begin
  if rising_edge(p_in_hclk) then
    hclk_eth_rxd_rdy <= eclk_eth_rxd_rdy_w;
  end if;
end process;

p_out_eth_hirq <= hclk_eth_rxd_rdy;


--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--EthG->VIDEO_CTRL
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
m_eth2vctrl_pkt_fltr: video_pkt_filter
generic map(
G_DWIDTH => G_ETH_DWIDTH,
G_FRR_COUNT => C_SWT_ETH_VCTRL_FRR_COUNT
)
port map(
--------------------------------------
--Управление
--------------------------------------
p_in_frr        => syn_eth_vctrl_frr,

--------------------------------------
--Upstream Port
--------------------------------------
p_in_upp_data   => syn_eth_rxd,
p_in_upp_wr     => syn_eth_rxd_wr,
p_in_upp_eof    => syn_eth_rxd_eof,
p_in_upp_sof    => syn_eth_rxd_sof,

--------------------------------------
--Downstream Port
--------------------------------------
p_out_dwnp_data => i_vbufi_fltr_dout,
p_out_dwnp_wr   => i_vbufi_fltr_den,
p_out_dwnp_eof  => open,
p_out_dwnp_sof  => open,

-------------------------------
--Технологический
-------------------------------
p_in_tst        => (others=>'0'),
p_out_tst       => open,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk        => p_in_eth_clk,
p_in_rst        => b_rst_vctrl_bufs
);

gen_swap_d : for i in 0 to (i_vbufi_fltr_dout'length / 32) - 1 generate
i_vbufi_fltr_dout_swap((i_vbufi_fltr_dout_swap'length - (32 * i)) - 1 downto
                              (i_vbufi_fltr_dout_swap'length - (32 * (i + 1)) ))
                          <= i_vbufi_fltr_dout((32 * (i + 1)) - 1 downto (32 * i));
end generate;-- gen_swap_d;

m_vbufi : ethg_vctrl_rxfifo
port map(
din         => i_vbufi_fltr_dout_swap,
wr_en       => i_vbufi_fltr_den,
wr_clk      => p_in_eth_clk,

dout        => p_out_vbufi_do,
rd_en       => p_in_vbufi_rd,
rd_clk      => i_vbufi_rdclk,

empty       => p_out_vbufi_empty,
full        => p_out_vbufi_full,
prog_full   => i_vbufi_pfull,

rst         => b_rst_vctrl_bufs
);

p_out_vbufi_pfull <= i_vbufi_pfull;

gen_clk_sel0 : if strcmp(C_PCFG_BOARD,"DINIK7") generate
i_vbufi_rdclk <= p_in_tst(0);
end generate gen_clk_sel0;

gen_clk_sel1 : if (not strcmp(C_PCFG_BOARD,"DINIK7")) generate
i_vbufi_rdclk <= p_in_vbufi_rdclk;
end generate gen_clk_sel1;

--END MAIN
end behavioral;
