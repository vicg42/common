-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.02.2013 17:55:29
-- Module Name : vproc_main
--
-- Назначение/Описание :
-- Проект изделия Вереск-М(Р)
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
use work.prj_def.all;
use work.eth_phypin_pkg.all;
use work.eth_pkg.all;
use work.dsn_eth_pkg.all;
use work.clocks_pkg.all;
use work.cfgdev_pkg.all;

entity vproc_main is
generic(
G_SIM      : string:="OFF"
);
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_led         : out   std_logic_vector(7 downto 0);
pin_in_btn_N        : in    std_logic;

----------------------------------------------------
----Memory banks
----------------------------------------------------
--pin_out_phymem      : out   TMEMCTRL_phy_outs;
--pin_inout_phymem    : inout TMEMCTRL_phy_inouts;

--------------------------------------------------
--ETH
--------------------------------------------------
pin_out_ethphy    : out   TEthPhyPinOUT;
pin_in_ethphy     : in    TEthPhyPinIN;
pin_inout_ethphy_mdio : inout std_logic;
pin_out_ethphy_mdc    : out   std_logic;
pin_out_ethphy_rst    : out   std_logic;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefClkPinIN
);
end entity;

architecture struct of vproc_main is

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--//мигание сведодиода
p_out_test_done: out   std_logic;--//сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

component clocks
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clkopt: in    std_logic_vector(3 downto 0);
p_in_clk   : in    TRefClkPinIN
);
end component;

signal i_sys_rst_cnt                    : std_logic_vector(5 downto 0):=(others=>'0');
signal i_sys_rst                        : std_logic;
signal i_usr_rst                        : std_logic;
signal i_mnl_rst                        : std_logic;

signal i_usrclk_rst                     : std_logic;
signal g_usrclk                         : std_logic_vector(7 downto 0);
signal g_usr_highclk                    : std_logic;

signal i_cfg_rst                        : std_logic;
signal i_cfg_rdy                        : std_logic;
signal i_cfg_dadr                       : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_radr                       : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_radr_ld                    : std_logic;
signal i_cfg_radr_fifo                  : std_logic;
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_txd                        : std_logic_vector(15 downto 0);
signal i_cfg_rxd                        : std_logic_vector(15 downto 0);
Type TCfgRxD is array (0 to C_CFGDEV_COUNT-1) of std_logic_vector(i_cfg_rxd'range);
signal i_cfg_rxd_dev                    : TCfgRxD;
signal i_cfg_done                       : std_logic;
signal i_cfg_wr_dev                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_rd_dev                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_done_dev                   : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_tst_out                    : std_logic_vector(31 downto 0);

component eth_bram_prm
port(
p_out_cfg_adr      : out  std_logic_vector(7 downto 0);
p_out_cfg_adr_ld   : out  std_logic;
p_out_cfg_adr_fifo : out  std_logic;

p_out_cfg_txdata   : out  std_logic_vector(15 downto 0);
p_out_cfg_wr       : out  std_logic;

p_in_clk  : in  std_logic;
p_in_rst  : in  std_logic
);
end component;

component eth_gt_clkbuf is
port(
p_in_ethphy : in    TEthPhyPinIN;
p_out_clk   : out   std_logic_vector(1 downto 0)
);
end component;

signal i_eth_prm_rst                   : std_logic;
signal i_eth_prm_radr                  : std_logic_vector(7 downto 0);
signal i_eth_prm_radr_ld               : std_logic;
signal i_eth_prm_radr_fifo             : std_logic;
signal i_eth_prm_wr                    : std_logic;
signal i_eth_prm_txd                   : std_logic_vector(15 downto 0);

signal i_eth_gt_txp                    : std_logic_vector(1 downto 0);
signal i_eth_gt_txn                    : std_logic_vector(1 downto 0);
signal i_eth_gt_rxn                    : std_logic_vector(1 downto 0);
signal i_eth_gt_rxp                    : std_logic_vector(1 downto 0);
signal i_eth_gt_refclk125_in           : std_logic_vector(1 downto 0);

signal i_eth_out                       : TEthOUTs;
signal i_eth_in                        : TEthINs;
signal i_ethphy_out                    : TEthPhyOUT;
signal i_ethphy_in                     : TEthPhyIN;
signal dbg_eth_out                     : TEthDBG;
signal i_eth_tst_out                   : std_logic_vector(31 downto 0);

signal i_eth_txpkt_dcnt                : std_logic_vector(15 downto 0);
signal i_eth_txpkt_d                   : std_logic_vector(31 downto 0);
signal i_eth_txpkt_wr                  : std_logic;
signal i_eth_txpkt_len                 : std_logic_vector(15 downto 0);
signal i_eth_txpkt_dlycnt              : std_logic_vector(31 downto 0);
signal i_eth_txpkt_work                : std_logic;
signal i_eth_txbuf_err                 : std_logic;


--signal i_vctrl_rst                      : std_logic;
--signal hclk_hrddone_vctrl_cnt           : std_logic_vector(2 downto 0);
--signal hclk_hrddone_vctrl               : std_logic;
--signal i_vctrl_vbufin_rdy               : std_logic;
--signal i_vctrl_vbufin_dout              : std_logic_vector(31 downto 0);
--signal i_vctrl_vbufin_rd                : std_logic;
--signal i_vctrl_vbufin_empty             : std_logic;
--signal i_vctrl_vbufin_pfull             : std_logic;
--signal i_vctrl_vbufin_full              : std_logic;
--signal i_vctrl_vbufout_din              : std_logic_vector(31 downto 0);
--signal i_vctrl_vbufout_wd               : std_logic;
--signal i_vctrl_vbufout_empty            : std_logic;
--signal i_vctrl_vbufout_full             : std_logic;
--
--signal i_vctrl_hrd_start                : std_logic;
--signal i_vctrl_hrd_done                 : std_logic;
--signal sr_vctrl_hrd_done                : std_logic_vector(1 downto 0);
--signal g_vctrl_swt_bufclk               : std_logic;
--signal i_vctrl_hirq                     : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
--signal i_vctrl_hrdy                     : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
--signal i_vctrl_hirq_out                 : std_logic_vector(C_VCTRL_VCH_COUNT_MAX-1 downto 0);
--signal i_vctrl_hrdy_out                 : std_logic_vector(C_VCTRL_VCH_COUNT_MAX-1 downto 0);
--signal i_vctrl_hfrmrk                   : std_logic_vector(31 downto 0);
--signal i_vctrl_vrd_done                 : std_logic;
--signal i_vctrl_tst_out                  : std_logic_vector(31 downto 0);
--signal i_vctrl_vrdprms                  : TReaderVCHParams;
--signal i_vctrl_vfrdy                    : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
--signal i_vctrl_vrowmrk                  : TVMrks;
--signal i_vctrlwr_memin                  : TMemIN;
--signal i_vctrlwr_memout                 : TMemOUT;
--signal i_vctrlrd_memin                  : TMemIN;
--signal i_vctrlrd_memout                 : TMemOUT;
--
--signal i_trc_busy                       : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0):=(others=>'0');
--signal i_trc_vbufs                      : TVfrBufs;
--
--signal i_memctrl_rst                    : std_logic;
--signal i_memctrl_locked                 : std_logic_vector(7 downto 0);
--signal i_memctrl_ready                  : std_logic;
--
--signal i_memin_ch                       : TMemINCh;
--signal i_memout_ch                      : TMemOUTCh;
--signal i_memin_bank                     : TMemINBank;
--signal i_memout_bank                    : TMemOUTBank;
--
--signal i_arb_mem_rst                    : std_logic;
--signal i_arb_memin                      : TMemIN;
--signal i_arb_memout                     : TMemOUT;
--signal i_arb_mem_tst_out                : std_logic_vector(31 downto 0);
--
--signal i_mem_ctrl_status                : TMEMCTRL_status;
--signal i_mem_ctrl_sysin                 : TMEMCTRL_sysin;
--signal i_mem_ctrl_sysout                : TMEMCTRL_sysout;


attribute keep : string;
attribute keep of i_ethphy_out : signal is "true";

signal i_test01_led     : std_logic;
signal tst_reg_adr_cnt  : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
Type TCfg_tstreg is array (0 to 3) of std_logic_vector(i_cfg_rxd'range);
signal tst_reg          : TCfg_tstreg;


--//MAIN
begin


--***********************************************************
--//RESET модулей
--***********************************************************
process(i_ethphy_out)
begin
  if rising_edge(i_ethphy_out.clk) then
    if i_sys_rst_cnt(i_sys_rst_cnt'high) = '0' then
      i_sys_rst_cnt <= i_sys_rst_cnt + 1;
    end if;
  end if;
end process;

i_sys_rst <= i_sys_rst_cnt(i_sys_rst_cnt'high - 1);-- or i_eth_gt_refclk125_in(1);

gen_ml505 : if strcmp(C_PCFG_BOARD,"ML505") generate
i_usr_rst <= pin_in_btn_N;
end generate gen_ml505;

gen_htgv6 : if strcmp(C_PCFG_BOARD,"HTGV6") generate
i_usr_rst <= not pin_in_btn_N;
end generate gen_htgv6;

i_mnl_rst <= i_sys_rst or i_usr_rst;


--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_usrclk_rst,
p_out_gclk => g_usrclk,

p_in_clkopt=> (others=>'0'),
p_in_clk   => pin_in_refclk
);

g_usr_highclk <= g_usrclk(1);
--g_usr_highclk<=i_mem_ctrl_sysout.clk;
--i_mem_ctrl_sysin.ref_clk<=g_usrclk(0);
--i_mem_ctrl_sysin.clk<=g_usrclk(1);


--***********************************************************
--Модуль конфигурирования устр-в
--***********************************************************
m_cfg : cfgdev_host
generic map(
G_DBG => "ON",
G_HOST_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
--Связь с Хостом
-------------------------------
p_out_host_rxrdy     => open,
p_out_host_rxd       => i_eth_in(0).txbuf.dout,
p_in_host_rd         => i_eth_out(0).txbuf.rd,

p_out_host_txrdy     => open,
p_in_host_txd        => i_eth_out(0).rxbuf.din,
p_in_host_wr         => i_eth_out(0).rxbuf.wr,

p_out_host_irq       => open,
p_in_host_clk        => i_ethphy_out.clk,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       => i_cfg_dadr,
p_out_cfg_radr       => i_cfg_radr,
p_out_cfg_radr_ld    => i_cfg_radr_ld,
p_out_cfg_radr_fifo  => i_cfg_radr_fifo,
p_out_cfg_wr         => i_cfg_wr,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => '1',
p_in_cfg_rxrdy       => '1',

p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => g_usr_highclk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => i_cfg_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_mnl_rst
);

i_eth_in(0).rxbuf.empty <= i_cfg_tst_out(28);-- <= i_rxbuf_empty;--//HOST->FPGA
i_eth_in(0).rxbuf.full  <= i_cfg_tst_out(29);-- <= i_rxbuf_full ;
i_eth_in(0).txbuf.empty <= i_cfg_tst_out(30);-- <= i_txbuf_empty;--//HOST<-FPGA
i_eth_in(0).txbuf.full  <= i_cfg_tst_out(31);-- <= i_txbuf_full ;

--//Распределяем управление от блока конфигурирования(cfgdev.vhd):
i_cfg_rxd<=i_cfg_rxd_dev(0) when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(0, 4)   else
           (others=>'0');

gen_cfg_dev : for i in 0 to C_CFGDEV_COUNT-1 generate
i_cfg_wr_dev(i)   <=i_cfg_wr   when i_cfg_dadr=i else '0';
i_cfg_rd_dev(i)   <=i_cfg_rd   when i_cfg_dadr=i else '0';
i_cfg_done_dev(i) <=i_cfg_done when i_cfg_dadr=i else '0';
end generate gen_cfg_dev;



--//Счетчик адреса регистров
process(i_mnl_rst, g_usr_highclk)
begin
  if i_mnl_rst = '1' then
    tst_reg_adr_cnt <= (others=>'0');
  elsif rising_edge(g_usr_highclk) then
    if i_cfg_radr_ld = '1' then
      tst_reg_adr_cnt <= i_cfg_radr;
    else
      if i_cfg_radr_fifo = '0' and (i_cfg_wr_dev(0) = '1' or i_cfg_rd_dev(0) = '1') then
        tst_reg_adr_cnt <= tst_reg_adr_cnt + 1;
      end if;
    end if;
  end if;
end process;

--//Запись регистров
process(i_mnl_rst, g_usr_highclk)
begin
  if i_mnl_rst = '1' then
    for i in 0 to 3 loop
      tst_reg(i) <= (others=>'0');
    end loop;
  elsif rising_edge(g_usr_highclk) then
    if i_cfg_wr_dev(0) = '1' then
      if tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(0, tst_reg_adr_cnt'length) then
          tst_reg(0) <= i_cfg_txd;
      elsif tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(1, tst_reg_adr_cnt'length) then
          tst_reg(1) <= i_cfg_txd;
      elsif tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(2, tst_reg_adr_cnt'length) then
          tst_reg(2) <= i_cfg_txd;
      elsif tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(3, tst_reg_adr_cnt'length) then
          tst_reg(3) <= i_cfg_txd;
      end if;
    end if;
  end if;
end process;

--//Чтение регистров
process(i_mnl_rst, g_usr_highclk)
begin
  if i_mnl_rst = '1' then
    i_cfg_rxd_dev(0) <= (others=>'0');
  elsif rising_edge(g_usr_highclk) then
    if i_cfg_rd_dev(0) = '1' then
      if tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(0, tst_reg_adr_cnt'length) then
         i_cfg_rxd_dev(0) <= tst_reg(0);
      elsif tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(1, tst_reg_adr_cnt'length) then
         i_cfg_rxd_dev(0) <= tst_reg(1);
      elsif tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(2, tst_reg_adr_cnt'length) then
         i_cfg_rxd_dev(0) <= tst_reg(2);
      elsif tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(3, tst_reg_adr_cnt'length) then
         i_cfg_rxd_dev(0) <= tst_reg(3);
      end if;
    end if;
  end if;
end process;


--***********************************************************
--Проект Ethernet - dsn_eth.vhd
--***********************************************************
ibuf_eth_gt_refclk : eth_gt_clkbuf
port map(
p_in_ethphy => pin_in_ethphy,
p_out_clk   => i_eth_gt_refclk125_in
);

pin_out_ethphy.sgmii.txp <= i_ethphy_out.pin.sgmii.txp;
pin_out_ethphy.sgmii.txn <= i_ethphy_out.pin.sgmii.txn;
i_ethphy_in.pin.sgmii.rxp <= pin_in_ethphy.sgmii.rxp;
i_ethphy_in.pin.sgmii.rxn <= pin_in_ethphy.sgmii.rxn;

i_ethphy_in.clk <= i_eth_gt_refclk125_in(0);

pin_out_ethphy_rst <= not i_ethphy_out.rst;
pin_inout_ethphy_mdio <= i_ethphy_out.mdio when i_ethphy_out.mdio_t = '1' else 'Z';
pin_out_ethphy_mdc <= i_ethphy_out.mdc;
i_ethphy_in.mdio <= pin_inout_ethphy_mdio;

i_eth_prm_rst <= not i_ethphy_out.rdy or i_mnl_rst;

--Параметры настройки для dsn_eth.vhd
m_eth_prm : eth_bram_prm
port map(
p_out_cfg_adr      => i_eth_prm_radr,
p_out_cfg_adr_ld   => i_eth_prm_radr_ld,
p_out_cfg_adr_fifo => i_eth_prm_radr_fifo,

p_out_cfg_txdata   => i_eth_prm_txd,
p_out_cfg_wr       => i_eth_prm_wr,

p_in_clk  => i_ethphy_out.clk,
p_in_rst  => i_eth_prm_rst
);

m_eth : dsn_eth
generic map(
G_ETH.gtch_count_max  => C_PCFG_ETH_GTCH_COUNT_MAX,
G_ETH.usrbuf_dwidth   => 32,
G_ETH.phy_dwidth      => 8,--C_PCFG_ETH_PHY_DWIDTH,
G_ETH.phy_select      => 0,--C_PCFG_ETH_PHY_SEL,
G_ETH.mac_length_swap => 0,--1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
G_MODULE_USE => C_PCFG_ETH_USE,
G_DBG        => C_PCFG_ETH_DBG,
G_SIM        => G_SIM
)
port map(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_clk      => i_ethphy_out.clk,

p_in_cfg_adr      => i_eth_prm_radr(7 downto 0),
p_in_cfg_adr_ld   => i_eth_prm_radr_ld,
p_in_cfg_adr_fifo => i_eth_prm_radr_fifo,

p_in_cfg_txdata   => i_eth_prm_txd,
p_in_cfg_wd       => i_eth_prm_wr,

p_out_cfg_rxdata  => open,
p_in_cfg_rd       => '0',

p_in_cfg_done     => '0',
p_in_cfg_rst      => i_sys_rst,

-------------------------------
--Связь с UsrBuf
-------------------------------
p_out_eth         => i_eth_out,
p_in_eth          => i_eth_in,

-------------------------------
--ETH
-------------------------------
p_out_ethphy      => i_ethphy_out,
p_in_ethphy       => i_ethphy_in,

-------------------------------
--Технологический
-------------------------------
p_out_dbg         => dbg_eth_out,
p_in_tst          => i_eth_tst_out,
p_out_tst         => open,

-------------------------------
--System
-------------------------------
p_in_rst          => i_mnl_rst
);



--m_eth_txbuf : host_ethg_txudp
--port map(
--din     => i_eth_txpkt_d,
--wr_en   => i_eth_txpkt_wr,
--wr_clk  => i_ethphy_out.clk,
----din     => i_eth_out(0).rxbuf.din,
----wr_en   => i_eth_out(0).rxbuf.wr,
----wr_clk  => i_ethphy_out.clk,
--
--dout    => i_eth_in(0).txbuf.dout(31 downto 0),
--rd_en   => i_eth_out(0).txbuf.rd,
--rd_clk  => i_ethphy_out.clk,
--
--empty   => i_eth_in(0).txbuf.empty,
--full    => open,
--prog_full => i_eth_in(0).txbuf.full,
--
--rst     => i_sys_rst
--);
--i_eth_in(0).rxbuf.full<=i_eth_in(0).txbuf.full;
--
--process(i_mnl_rst,i_ethphy_out)
--begin
--  if i_mnl_rst='1' then
--    i_eth_txpkt_work <= '0';
--    i_eth_txbuf_err <= '0';
--  elsif i_ethphy_out.clk'event and i_ethphy_out.clk='1' then
--    if dbg_eth_out.app(0).mac_rx(1)='1' then
--      i_eth_txpkt_work <= '1';
--    end if;
--    if i_eth_in(0).txbuf.full='1' then
--      i_eth_txbuf_err <= '1';
--    end if;
--  end if;
--end process;
--
----1.625 fps = 74125
----3.75  fps = 36500
----7.5   fps = 15250
----15    fps = 7125
----30    fps = 3000
----60    fps = 1000
--i_eth_txpkt_dlycnt <= CONV_STD_LOGIC_VECTOR(3000 , i_eth_txpkt_dlycnt'length);
--
--m_tst_gen : eth_tst_gen
--generic map(
--G_DBG => C_PCFG_ETH_DBG,
--G_SIM => G_SIM
--)
--port map(
----------------------------------------
----Управление
----------------------------------------
--p_in_pkt_dly     => i_eth_txpkt_dlycnt,
--p_in_work        => i_eth_txpkt_work,
--
----------------------------------------
----Связь с пользовательским TXBUF
----------------------------------------
--p_out_txbuf_din  => i_eth_txpkt_d,
--p_out_txbuf_wr   => i_eth_txpkt_wr,
--p_in_txbuf_full  => i_eth_in(0).txbuf.full,
--
----------------------------------------------------
----Технологические сигналы
----------------------------------------------------
--p_in_tst         => (others=>'0'),
--p_out_tst        => i_eth_tstgen_tst_out,
--
----------------------------------------
----SYSTEM
----------------------------------------
--p_in_clk         => i_ethphy_out.clk,
--p_in_rst         => i_mnl_rst
--);


----***********************************************************
----Проект модуля видео контролера - dsn_video_ctrl.vhd
----***********************************************************
--i_vctrl_hirq_out<=EXT(i_vctrl_hirq, i_vctrl_hirq_out'length);
--i_vctrl_hrdy_out<=EXT(i_vctrl_hrdy, i_vctrl_hrdy_out'length);
--
--m_vctrl : dsn_video_ctrl
--generic map(
--G_ROTATE => "OFF",
--G_ROTATE_BUF_COUNT => 16,
--G_SIMPLE => "ON",
--G_SIM    => G_SIM,
--
--G_MEM_AWIDTH => C_HREG_MEM_ADR_LAST_BIT,
--G_MEM_DWIDTH => C_HDEV_DWIDTH
--)
--port map(
---------------------------------
---- Конфигурирование модуля dsn_video_ctrl.vhd (host_clk domain)
---------------------------------
--p_in_host_clk        => g_host_clk,
--
--p_in_cfg_adr         => i_cfg_radr(7 downto 0),
--p_in_cfg_adr_ld      => i_cfg_radr_ld,
--p_in_cfg_adr_fifo    => i_cfg_radr_fifo,
--
--p_in_cfg_txdata      => i_cfg_txd,
--p_in_cfg_wd          => i_cfg_wr_dev(C_CFGDEV_VCTRL),
--
--p_out_cfg_rxdata     => i_cfg_rxd_dev(C_CFGDEV_VCTRL),
--p_in_cfg_rd          => i_cfg_rd_dev(C_CFGDEV_VCTRL),
--
--p_in_cfg_done        => i_cfg_done_dev(C_CFGDEV_VCTRL),
--
---------------------------------
---- Связь с ХОСТ
---------------------------------
--p_in_vctrl_hrdchsel  => i_host_vchsel,
--p_in_vctrl_hrdstart  => i_vctrl_hrd_start,
--p_in_vctrl_hrddone   => i_vctrl_hrd_done,
--p_out_vctrl_hirq     => i_vctrl_hirq,
--p_out_vctrl_hdrdy    => i_vctrl_hrdy,
--p_out_vctrl_hfrmrk   => open,
--
---------------------------------
---- STATUS модуля dsn_video_ctrl.vhd
---------------------------------
--p_out_vctrl_modrdy   => open,
--p_out_vctrl_moderr   => open,
--p_out_vctrl_rd_done  => i_vctrl_vrd_done,
--
--p_out_vctrl_vrdprm   => i_vctrl_vrdprms,
--p_out_vctrl_vfrrdy   => i_vctrl_vfrdy,
--p_out_vctrl_vrowmrk  => i_vctrl_vrowmrk,
--
---------------------------------
---- Связь с модулем слежения
---------------------------------
--p_in_trc_busy        => i_trc_busy,
--p_out_trc_vbuf       => i_trc_vbufs,
--
---------------------------------
---- Связь с буферами модуля dsn_switch.vhd
---------------------------------
--p_out_vbuf_clk       => g_vctrl_swt_bufclk,
--
--p_in_vbufin_rdy      => i_vctrl_vbufin_rdy,
--p_in_vbufin_dout     => i_vctrl_vbufin_dout,
--p_out_vbufin_dout_rd => i_vctrl_vbufin_rd,
--p_in_vbufin_empty    => i_vctrl_vbufin_empty,
--p_in_vbufin_full     => i_vctrl_vbufin_full,
--p_in_vbufin_pfull    => i_vctrl_vbufin_pfull,
--
--p_out_vbufout_din    => i_vctrl_vbufout_din,
--p_out_vbufout_din_wd => i_vctrl_vbufout_wd,
--p_in_vbufout_empty   => i_vctrl_vbufout_empty,
--p_in_vbufout_full    => i_vctrl_vbufout_full,
--
-----------------------------------
---- Связь с mem_ctrl.vhd
-----------------------------------
----//CH WRITE
--p_out_memwr          => i_vctrlwr_memin,
--p_in_memwr           => i_vctrlwr_memout,
----//CH READ
--p_out_memrd          => i_vctrlrd_memin,
--p_in_memrd           => i_vctrlrd_memout,
--
---------------------------------
----Технологический
---------------------------------
--p_out_tst            => i_vctrl_tst_out,
--
---------------------------------
----System
---------------------------------
--p_in_clk => g_usr_highclk,
--p_in_rst => i_vctrl_rst
--);
--
--
--
--
----//Подключаем устройства к арбитру ОЗУ
--i_memin_ch(0) <= i_host_memin;
--i_host_memout <= i_memout_ch(0);
--
--i_memin_ch(1)    <= i_vctrlwr_memin;
--i_vctrlwr_memout <= i_memout_ch(1);
--
--i_memin_ch(2)    <= i_vctrlrd_memin;
--i_vctrlrd_memout <= i_memout_ch(2);
--
----//Арбитр контроллера памяти
--m_mem_arb : mem_arb
--generic map(
--G_CH_COUNT   => 3,--selval(10#04#,10#03#, strcmp(C_PCFG_HDD_USE,"ON")),
--G_MEM_AWIDTH => C_AXI_AWIDTH, --C_HREG_MEM_ADR_LAST_BIT,
--G_MEM_DWIDTH => C_HDEV_DWIDTH
--)
--port map(
---------------------------------
----Связь с пользователями ОЗУ
---------------------------------
--p_in_memch  => i_memin_ch,
--p_out_memch => i_memout_ch,
--
---------------------------------
----Связь с mem_ctrl.vhd
---------------------------------
--p_out_mem   => i_arb_memin,
--p_in_mem    => i_arb_memout,
--
---------------------------------
----Технологический
---------------------------------
--p_in_tst    => (others=>'0'),
--p_out_tst   => i_arb_mem_tst_out,
--
---------------------------------
----System
---------------------------------
--p_in_clk    => g_usr_highclk,
--p_in_rst    => i_arb_mem_rst
--);
--
----//Подключаем арбитра ОЗУ к соотв банку
--i_memin_bank(0)<=i_arb_memin;
--i_arb_memout   <=i_memout_bank(0);
--
----//Core Memory controller
--m_mem_ctrl : mem_ctrl
--generic map(
--G_SIM => G_SIM
--)
--port map(
--------------------------------------
----User Post
--------------------------------------
--p_in_mem   => i_memin_bank,
--p_out_mem  => i_memout_bank,
--
--------------------------------------
----Memory physical interface
--------------------------------------
--p_out_phymem    => pin_out_phymem,
--p_inout_phymem  => pin_inout_phymem,
--
--------------------------------------
----Memory status
--------------------------------------
--p_out_status    => i_mem_ctrl_status,
--
--------------------------------------
----System
--------------------------------------
--p_out_sys       => i_mem_ctrl_sysout,
--p_in_sys        => i_mem_ctrl_sysin
--);



--//#########################################
--//DBG
--//#########################################
pin_out_led(0)<='0';
pin_out_led(1)<=OR_reduce(dbg_eth_out.app(0).mac_rx) or OR_reduce(dbg_eth_out.app(0).mac_tx) or i_cfg_tst_out(0);
pin_out_led(2)<='0';
pin_out_led(3)<=dbg_eth_out.app(0).mac_rx(1);--i_dhcp_done

pin_out_led(4)<=i_eth_txbuf_err;
pin_out_led(5)<=not i_ethphy_out.rdy;--read bad ID from ETHPHY
pin_out_led(6)<=i_ethphy_out.link;
pin_out_led(7)<=i_test01_led;


m_gt_03_test: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#,
G_CLK_T05us   =>10#75#
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => i_ethphy_out.clk,
p_in_rst       => i_mnl_rst
);



end architecture;
