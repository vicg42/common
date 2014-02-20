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
use ieee.std_logic_misc.all;

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

constant CI_VBUFI_DO_WIDTH : integer := 32;

component ethg_vctrl_rxfifo
port(
din         : IN  std_logic_vector(G_ETH_DWIDTH - 1 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(CI_VBUFI_DO_WIDTH - 1 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component;

component vbufi
port(
din         : IN  std_logic_vector(G_VBUFI_OWIDTH - 1 downto 0);
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

signal i_eth_txbuf_di                : std_logic_vector(p_in_eth_htxbuf_di'range);
signal i_eth_txbuf_full              : std_logic;
signal i_eth_txbuf_empty             : std_logic;

signal i_eth_rxbuf_do                : std_logic_vector(p_out_eth_hrxbuf_do'range);
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
signal i_vbufi_rdclk                 : std_logic;
signal i_vbufi_empty                 : std_logic;
signal i_vbufi_full                  : std_logic;
signal i_vbufi_pfull                 : std_logic;
signal i_vbufi_do                    : std_logic_vector(CI_VBUFI_DO_WIDTH - 1 downto 0);
signal i_vbufi_rd                    : std_logic;
signal i_vbufi_rd_en                 : std_logic;
signal i_vbufi_rd_skip               : std_logic;

signal hclk_tmr_en,i_tmr_en          : std_logic;
signal hclk_eth_tx_start             : std_logic;
signal sr_eth_tx_start               : std_logic_vector(0 to 2):=(others=>'0');
signal i_eth_txbuf_empty_en          : std_logic;

signal i_bus_dwcnt                   : std_logic_vector(selval(log2(G_HOST_DWIDTH / 32)
                                                                , 1, G_HOST_DWIDTH > 32) - 1 downto 0);
signal i_vpkt_cnt                    : std_logic_vector(15 downto 0);
signal i_vpkt_size_byte              : std_logic_vector(15 downto 0);
signal i_vpkt_size                   : std_logic_vector(15 downto 0);
signal i_vbufi2_di                   : std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
signal i_vbufi2_wr                   : std_logic;
signal i_vbufi2_full                 : std_logic;
signal i_vctrl_frr_en                : std_logic_vector(C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_VCTRL_FRR_COUNT) - 1 downto 0);

type TFsm is (
S_IDLE,
S_VBUF2_WR,
S_SKIP
);
signal fsm_state_cs                  : TFsm;

signal tst_vbufi_empty               : std_logic;

signal i_eth_hrxbuf_do_tmp           : std_logic_vector(127 downto 0);
signal tst_txbuf_di                  : std_logic_vector(127 downto 0);
signal tst_rxbuf_do                  : std_logic_vector(127 downto 0);
signal tst_rxbuf_do_rd               : std_logic;
signal tst_eth_txbuf_empty           : std_logic;
signal tst_eth_rxbuf_empty           : std_logic;

--MAIN
begin

------------------------------------
--Технологические сигналы
------------------------------------
p_out_tst(0) <= b_rst_vctrl_bufs;
p_out_tst(1) <= tst_vbufi_empty;
p_out_tst(2) <= OR_reduce(tst_txbuf_di) or OR_reduce(tst_rxbuf_do) or tst_rxbuf_do_rd or tst_eth_txbuf_empty or tst_eth_rxbuf_empty;
p_out_tst(31 downto 3) <= (others=>'0');

process(p_in_hclk)
begin
  if rising_edge(p_in_hclk) then
  tst_txbuf_di <= p_in_eth_htxbuf_di;
  tst_rxbuf_do <= i_eth_hrxbuf_do_tmp;
  tst_rxbuf_do_rd <= p_in_eth_hrxbuf_rd;
  tst_eth_txbuf_empty <= i_eth_txbuf_empty;
  tst_eth_rxbuf_empty <= i_eth_rxbuf_empty;

  end if;
end process;


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

gen_ethtx_swap_d : for i in 0 to (p_in_eth_htxbuf_di'length / G_ETH_DWIDTH) - 1 generate
i_eth_txbuf_di((i_eth_txbuf_di'length - (G_ETH_DWIDTH * i)) - 1 downto
                              (i_eth_txbuf_di'length - (G_ETH_DWIDTH * (i + 1)) ))
                          <= p_in_eth_htxbuf_di((G_ETH_DWIDTH * (i + 1)) - 1 downto (G_ETH_DWIDTH * i));
end generate;-- gen_ethtx_swap_d;

m_eth_txbuf : host_ethg_txfifo
port map(
din     => i_eth_txbuf_di,
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

dout    => i_eth_rxbuf_do,
rd_en   => p_in_eth_hrxbuf_rd,
rd_clk  => p_in_hclk,

empty   => i_eth_rxbuf_empty,
full    => open,
prog_full => i_eth_rxbuf_full,

rst     => b_rst_eth_bufs
);

gen_ethrx_swap_d : for i in 0 to (p_out_eth_hrxbuf_do'length / G_ETH_DWIDTH) - 1 generate
i_eth_hrxbuf_do_tmp((p_out_eth_hrxbuf_do'length - (G_ETH_DWIDTH * i)) - 1 downto
                              (p_out_eth_hrxbuf_do'length - (G_ETH_DWIDTH * (i + 1)) ))
                          <= i_eth_rxbuf_do((G_ETH_DWIDTH * (i + 1)) - 1 downto (G_ETH_DWIDTH * i));
end generate;-- gen_ethrx_swap_d;
p_out_eth_hrxbuf_do <= i_eth_hrxbuf_do_tmp;
p_out_eth_hrxbuf_empty <= i_eth_rxbuf_empty;
p_out_eth_hrxbuf_full <= i_eth_rxbuf_full;

p_out_eth(0).rxbuf_empty <= i_eth_rxbuf_empty;
p_out_eth(0).rxbuf_full <= '0';

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

dout        => i_vbufi_do,
rd_en       => i_vbufi_rd,
rd_clk      => i_vbufi_rdclk,

empty       => i_vbufi_empty,
full        => i_vbufi_full,
prog_full   => i_vbufi_pfull,

rst         => b_rst_vctrl_bufs
);

gen_host_bus0 : if G_HOST_DWIDTH = 32 generate

p_out_vbufi_do <= i_vbufi_do;
i_vbufi_rd <= p_in_vbufi_rd;
i_vbufi_rdclk <= p_in_vbufi_rdclk;

p_out_vbufi_empty <= i_vbufi_empty;
p_out_vbufi_full <= i_vbufi_full;
p_out_vbufi_pfull <= i_vbufi_pfull;

end generate gen_host_bus0;


gen_host_bus1 : if G_HOST_DWIDTH > 32 generate

i_vbufi_rdclk <= p_in_tst(0);

i_vbufi_rd <= (not i_vbufi_empty and i_vbufi_rd_en) or i_vbufi_rd_skip;

gen_vctrl_frr_en : for i in 0 to (i_vctrl_frr_en'length - 1) generate
i_vctrl_frr_en(i) <= '1' when syn_eth_vctrl_frr(i) /= (syn_eth_vctrl_frr(i)'range => '0') else '0';
end generate; --gen_vctrl_frr_en

i_vpkt_size <= EXT(i_vpkt_size_byte(i_vpkt_size_byte'high downto log2(CI_VBUFI_DO_WIDTH / 8))
                                                                      , i_vpkt_size'length)
                 + OR_reduce(i_vpkt_size_byte(log2(CI_VBUFI_DO_WIDTH / 8) - 1 downto 0));

--Размножаю первый DWORD видеопакета для того чтоб выровнять данные с шиной mem_ctrl
--mem_ctrl: bus 32b:   H0 H1 H2 H3 H4 D0 D1 D3 ...

--mem_ctrl: bus 64b:   H0 H2 H4 D1 D3 ...
--                     H0 H1 H3 D0 D2 ...

--mem_ctrl: bus 128b:  H0 H4 D3 D7 ...
--                     H0 H3 D2 D6 ...
--                     H0 H4 D1 D5 ...
--                     H0 H1 D0 D4 ...

--mem_ctrl: bus 256b:  H4 D7 D15 ...
--                     H3 D6 D14 ...
--                     H4 D5 D13 ...
--                     H1 D4 D12 ...
--                     H0 D3 D11 ...
--                     H0 D2 D10 ...
--                     H0 D1 D9 ...
--                     H0 D0 D8 ...

process(i_vbufi_rdclk)
begin
if rising_edge(i_vbufi_rdclk) then
  if p_in_rst = '1' then

    fsm_state_cs <= S_IDLE;
    i_bus_dwcnt <= (others=>'0');
    i_vpkt_cnt  <= (others=>'0');
    i_vpkt_size_byte <= (others=>'0');
    i_vbufi_rd_skip <= '0';
    i_vbufi2_wr <= '0';
    i_vbufi2_di <= (others=>'0'); tst_vbufi_empty <= '0';

  else  tst_vbufi_empty <= i_vbufi_empty;

    case fsm_state_cs is

      --------------------------------------
      --
      --------------------------------------
      when S_IDLE =>

        i_vbufi2_wr <= '0';

        if i_vbufi_empty = '0' and OR_reduce(i_vctrl_frr_en) = '1' then

            if i_vbufi_do(15 downto 0) /= CONV_STD_LOGIC_VECTOR(0, 16) then

                --кол-во байт пакета + кол-во байт поля length
                i_vpkt_size_byte <= i_vbufi_do(15 downto 0) + 2;

                if CI_VBUFI_DO_WIDTH = 256 then
                i_bus_dwcnt <= CONV_STD_LOGIC_VECTOR(4, i_bus_dwcnt'length);
                else
                i_bus_dwcnt <= CONV_STD_LOGIC_VECTOR((i_vbufi2_di'length
                                                        / i_vbufi_do'length) - 1, i_bus_dwcnt'length);
                end if;
                for i in 0 to ((i_vbufi2_di'length / i_vbufi_do'length) - 1) loop
                  i_vbufi2_di((i_vbufi_do'length * (i + 1)) - 1
                                  downto (i_vbufi_do'length * i)) <= i_vbufi_do;
                end loop;

                i_vbufi_rd_en <= '1';
                fsm_state_cs <= S_VBUF2_WR;

            else

              i_vbufi_rd_skip <= '1';
              fsm_state_cs <= S_SKIP;

            end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_VBUF2_WR =>

        if i_vbufi_empty = '0' then

            for i in 0 to ((i_vbufi2_di'length / i_vbufi_do'length) - 1) loop
              if i_bus_dwcnt = i then
                i_vbufi2_di((i_vbufi_do'length * (i + 1)) - 1
                                downto (i_vbufi_do'length * i)) <= i_vbufi_do;
              end if;
            end loop;

            i_bus_dwcnt <= i_bus_dwcnt + 1;

            if i_vpkt_cnt = (i_vpkt_size - 1) then
              i_vpkt_cnt <= (others=>'0');
              i_vbufi_rd_en <= '0';
              i_vbufi2_wr <= '1';
              fsm_state_cs <= S_IDLE;
            else
              i_vpkt_cnt <= i_vpkt_cnt + 1;
              i_vbufi2_wr <= AND_reduce(i_bus_dwcnt);
            end if;

        else

          i_vbufi2_wr <= '0';

        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SKIP =>

        i_vbufi_rd_skip <= '0';
        fsm_state_cs <= S_IDLE;

    end case;

  end if;
end if;
end process;


m_vbufi2 : vbufi
port map(
din         => i_vbufi2_di,
wr_en       => i_vbufi2_wr,
wr_clk      => i_vbufi_rdclk,

dout        => p_out_vbufi_do,
rd_en       => p_in_vbufi_rd,
rd_clk      => p_in_vbufi_rdclk,

empty       => p_out_vbufi_empty,
full        => i_vbufi2_full,
prog_full   => p_out_vbufi_pfull,

rst         => b_rst_vctrl_bufs
);

p_out_vbufi_full <= i_vbufi2_full;

end generate gen_host_bus1;

--END MAIN
end behavioral;
