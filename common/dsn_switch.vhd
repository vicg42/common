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

library unisim;
use unisim.vcomponents.all;

use work.vicg_common_pkg.all;
use work.prj_def.all;
--use work.memory_ctrl_pkg.all;


entity dsn_switch is
port
(
-------------------------------
-- Конфигурирование модуля DSN_SWITCH.VHD (host_clk domain)
-------------------------------
p_in_cfg_clk              : in   std_logic;                      --//

p_in_cfg_adr              : in   std_logic_vector(7 downto 0);   --//
p_in_cfg_adr_ld           : in   std_logic;                      --//
p_in_cfg_adr_fifo         : in   std_logic;                      --//

p_in_cfg_txdata           : in   std_logic_vector(15 downto 0);  --//
p_in_cfg_wd               : in   std_logic;                      --//

p_out_cfg_rxdata          : out  std_logic_vector(15 downto 0);  --//
p_in_cfg_rd               : in   std_logic;                      --//

p_in_cfg_done             : in   std_logic;                      --//

-------------------------------
-- Связь с Хостом (host_clk domain)
-------------------------------
p_in_host_clk             : in   std_logic;

-- Связь Хост <-> Опритка(dsn_optic.vhd)
p_out_host_eth_rxd_irq    : out  std_logic;
p_out_host_eth_rxd_rdy    : out  std_logic;
p_out_host_eth_rxd        : out  std_logic_vector(31 downto 0);
p_in_host_eth_rd          : in   std_logic;

p_out_host_eth_txbuf_rdy  : out  std_logic;
p_in_host_eth_txd         : in   std_logic_vector(31 downto 0);
p_in_host_eth_wr          : in   std_logic;
p_in_host_eth_txd_rdy     : in   std_logic;

-- Связь Хост <-> VideoBUF
p_out_host_vbuf_dout      : out  std_logic_vector(31 downto 0);
p_in_host_vbuf_rd         : in   std_logic;
p_out_host_vbuf_empty     : out  std_logic;

-------------------------------
-- Связь с Накопителем(dsn_hdd.vhd)
-------------------------------
p_in_hdd_vbuf_rst         : in   std_logic;                     --//
p_in_hdd_vbuf_rdclk       : in   std_logic;                     --//

p_in_hdd_vbuf_dout        : out  std_logic_vector(31 downto 0); --//
p_in_hdd_vbuf_rd          : in   std_logic;                     --//
p_out_hdd_vbuf_empty      : out  std_logic;                     --//
p_out_hdd_vbuf_full       : out  std_logic;                     --//
p_out_hdd_vbuf_pfull      : out  std_logic;                     --//

-------------------------------
-- Связь с EthG(Оптика)(dsn_optic.vhd) (ethg_clk domain)
-------------------------------
p_in_eth_clk              : in   std_logic;                     --//

p_in_eth_rxd_sof          : in   std_logic;                     --//
p_in_eth_rxd_eof          : in   std_logic;                     --//
p_in_eth_rxbuf_din        : in   std_logic_vector(31 downto 0); --//
p_in_eth_rxbuf_wr         : in   std_logic;                     --//
p_out_eth_rxbuf_empty     : out  std_logic;                     --//
p_out_eth_rxbuf_full      : out  std_logic;                     --//

p_out_eth_txd_rdy         : out  std_logic;
p_out_eth_txbuf_dout      : out  std_logic_vector(31 downto 0); --//
p_in_eth_txbuf_rd         : in   std_logic;                     --//
p_out_eth_txbuf_empty     : out  std_logic;                     --//
p_out_eth_txbuf_full      : out  std_logic;                     --//

-------------------------------
-- Связь с Модулем Видео контроллера(dsn_video_ctrl.vhd) (trc_clk domain)
-------------------------------
p_in_vctrl_clk            : in   std_logic;                      --//

p_out_vctrl_vbufin_rdy    : out  std_logic;                      --//
p_out_vctrl_vbufin_dout   : out  std_logic_vector(31 downto 0);  --//
p_in_vctrl_vbufin_rd      : in   std_logic;                      --//
p_out_vctrl_vbufin_empty  : out  std_logic;                      --//
p_out_vctrl_vbufin_full   : out  std_logic;                      --//
p_out_vctrl_vbufin_pfull  : out  std_logic;                      --//

p_in_vctrl_vbufout_din    : in   std_logic_vector(31 downto 0);  --//
p_in_vctrl_vbufout_wr     : in   std_logic;                      --//
p_out_vctrl_vbufout_empty : out  std_logic;                      --//
p_out_vctrl_vbufout_full  : out  std_logic;                      --//

-------------------------------
-- Связь с Модулем Тестирования(dsn_testing.vhd)
-------------------------------
p_out_dsntst_bufclk       : out  std_logic;                      --//

p_in_dsntst_txd_rdy       : in   std_logic;                      --//
p_in_dsntst_txbuf_din     : in   std_logic_vector(31 downto 0);  --//
p_in_dsntst_txbuf_wr      : in   std_logic;                      --//
p_out_dsntst_txbuf_empty  : out  std_logic;                      --//
p_out_dsntst_txbuf_full   : out  std_logic;                      --//

-------------------------------
--Технологический
-------------------------------
p_in_tst                  : in    std_logic_vector(31 downto 0);
p_out_tst                 : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst     : in    std_logic
);
end dsn_switch;

architecture behavioral of dsn_switch is

component host_vbuf
port
(
din         : IN  std_logic_vector(31 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(31 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
--almost_full : OUT std_logic;
prog_full   : OUT std_logic;
--almost_empty: OUT std_logic;

rst         : IN  std_logic
);
end component;

component host_ethg_txfifo
port
(
din         : IN  std_logic_vector(31 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(31 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
--almost_full : OUT std_logic;
almost_empty: OUT std_logic;

rst         : IN  std_logic
);
end component;

component host_ethg_rxfifo
port
(
din         : IN  std_logic_vector(31 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(31 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;

rst         : IN  std_logic
);
end component;

component ethg_vctrl_rxfifo
port
(
din         : IN  std_logic_vector(31 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(31 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
--almost_empty: OUT std_logic;
--prog_empty  : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component;

component video_pkt_filter
generic(
G_FMASK_COUNT   : integer := 3
);
port
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_fmask      : in    TEthFmask;

--//------------------------------------
--//Upstream Port
--//------------------------------------
p_in_upp_data   : in    std_logic_vector(31 downto 0);
p_in_upp_wr     : in    std_logic;
p_in_upp_eof    : in    std_logic;
p_in_upp_sof    : in    std_logic;

--//------------------------------------
--//Downstream Port
--//------------------------------------
p_out_dwnp_data : out   std_logic_vector(31 downto 0);
p_out_dwnp_wr   : out   std_logic;
p_out_dwnp_eof  : out   std_logic;
p_out_dwnp_sof  : out   std_logic;

-------------------------------
--Технологический
-------------------------------
p_out_tst       : out   std_logic_vector(31 downto 0);

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk        : in    std_logic;
p_in_rst        : in    std_logic
);
end component;

signal i_cfg_adr_cnt                          : std_logic_vector(7 downto 0);

signal h_reg_ctrl                             : std_logic_vector(C_DSN_SWT_REG_CTRL_LAST_BIT downto 0);
signal h_reg_tst0                             : std_logic_vector(C_DSN_SWT_REG_TST0_LAST_BIT downto 0);
signal h_reg_eth_host_fmask                   : TEthFmask;
signal h_reg_eth_hdd_fmask                    : TEthFmask;
signal h_reg_eth_vctrl_fmask                  : TEthFmask;

signal b_rst_eth_bufs                         : std_logic;
signal b_rst_vctrl_bufs                       : std_logic;
signal b_ethtxbuf_loopback                    : std_logic;
signal b_tstdsn_to_ethtxbuf                   : std_logic;
signal b_ethtxbuf_to_vctrlbufin               : std_logic;
signal b_ethtxbuf_to_hddbuf                   : std_logic;

signal syn_eth_rxd                            : std_logic_vector(31 downto 0);
signal syn_eth_rxd_wr                         : std_logic;
signal syn_eth_rxd_sof                        : std_logic;
signal syn_eth_rxd_eof                        : std_logic;
signal syn_eth_host_fmask                     : TEthFmask;
signal syn_eth_hdd_fmask                      : TEthFmask;
signal syn_eth_vctrl_fmask                    : TEthFmask;

signal i_hdd_vbuf_rst                         : std_logic;
signal i_hdd_vbuf_fltr_dout                   : std_logic_vector(31 downto 0);
signal i_hdd_vbuf_fltr_den                    : std_logic;
signal i_hdd_vbuf_din                         : std_logic_vector(31 downto 0);
signal i_hdd_vbuf_wr                          : std_logic;

signal hclk_eth_txd_rdy                       : std_logic;
signal hclk_eth_txd_rdy_cnt                   : std_logic_vector(2 downto 0);
signal eclk_eth_txd_rdy_dly                   : std_logic_vector(1 downto 0);
signal eclk_eth_txd_rdy                       : std_logic;
signal i_eth_txd_rdy                          : std_logic;
signal i_eth_txbuf_din                        : std_logic_vector(31 downto 0);
signal i_eth_txbuf_wr                         : std_logic;
signal i_eth_txbuf_dout                       : std_logic_vector(31 downto 0);
signal i_eth_txbuf_rd                         : std_logic;
signal i_eth_txbuf_empty                      : std_logic;

signal i_eth_rxbuf_din                        : std_logic_vector(31 downto 0);
signal i_eth_rxbuf_wr                         : std_logic;
signal i_eth_rxbuf_empty                      : std_logic;
signal i_eth_rxd_rdy                          : std_logic;
signal i_eth_rxd_rdy_dly                      : std_logic_vector(2 downto 0);
signal i_eth_rxbuf_fltr_dout                  : std_logic_vector(31 downto 0);
signal i_eth_rxbuf_fltr_den                   : std_logic;
signal i_eth_rxbuf_fltr_eof                   : std_logic;
signal eclk_eth_rxd_rdy_w                     : std_logic;
signal eclk_eth_rxd_rdy_wcnt                  : std_logic_vector(2 downto 0);
signal hclk_eth_rxd_rdy                       : std_logic;

signal i_vctrl_vbufin_fltr_dout               : std_logic_vector(31 downto 0);
signal i_vctrl_vbufin_fltr_den                : std_logic;
signal i_vctrl_vbufin_din                     : std_logic_vector(31 downto 0);
signal i_vctrl_vbufin_din_wd                  : std_logic;

signal i_vctrl_vbufout_empty                  : std_logic;



--MAIN
begin

p_out_tst(0)<='0';
p_out_tst(1)<='0';
p_out_tst(31 downto 2)<=(others=>'0');


--//--------------------------------------------------
--//Конфигурирование модуля dsn_switch.vhd
--//--------------------------------------------------
--//Счетчик адреса регистров
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    i_cfg_adr_cnt<=(others=>'0');
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_adr_ld='1' then
      i_cfg_adr_cnt<=p_in_cfg_adr;
    else
      if p_in_cfg_adr_fifo='0' and (p_in_cfg_wd='1' or p_in_cfg_rd='1') then
        i_cfg_adr_cnt<=i_cfg_adr_cnt+1;
      end if;
    end if;
  end if;
end process;

--//Запись регистров
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    h_reg_ctrl<=(others=>'0');
    h_reg_tst0<=(others=>'0');

    for i in 0 to C_DSN_SWT_ETHG_HOST_FMASK_COUNT-1 loop
      h_reg_eth_host_fmask(2*i)  <=(others=>'0');
      h_reg_eth_host_fmask(2*i+1)<=(others=>'0');
    end loop;

    for i in 0 to C_DSN_SWT_ETHG_HDD_FMASK_COUNT-1 loop
      h_reg_eth_hdd_fmask(2*i)  <=(others=>'0');
      h_reg_eth_hdd_fmask(2*i+1)<=(others=>'0');
    end loop;

    for i in 0 to C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT-1 loop
      h_reg_eth_vctrl_fmask(2*i)  <=(others=>'0');
      h_reg_eth_vctrl_fmask(2*i+1)<=(others=>'0');
    end loop;

  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_CTRL_L, i_cfg_adr_cnt'length) then h_reg_ctrl<=p_in_cfg_txdata(h_reg_ctrl'high downto 0);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_TST0, i_cfg_adr_cnt'length)   then h_reg_tst0<=p_in_cfg_txdata(h_reg_tst0'high downto 0);

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_HOST/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Заполняем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_HOST_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              h_reg_eth_host_fmask(2*i)  <=p_in_cfg_txdata(7 downto 0);
              h_reg_eth_host_fmask(2*i+1)<=p_in_cfg_txdata(15 downto 8);
            end if;
          end loop;

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_HDD/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Заполняем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_HDD_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              h_reg_eth_hdd_fmask(2*i)  <=p_in_cfg_txdata(7 downto 0);
              h_reg_eth_hdd_fmask(2*i+1)<=p_in_cfg_txdata(15 downto 8);
            end if;
          end loop;

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_VCTRL/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Заполняем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              h_reg_eth_vctrl_fmask(2*i)  <=p_in_cfg_txdata(7 downto 0);
              h_reg_eth_vctrl_fmask(2*i+1)<=p_in_cfg_txdata(15 downto 8);
            end if;
          end loop;

        end if;
    end if;
  end if;
end process;

--//Чтение регистров
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    p_out_cfg_rxdata<=(others=>'0');
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_rd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_CTRL_L, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=EXT(h_reg_ctrl, 16);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_TST0, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=EXT(h_reg_tst0, 16);

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_HOST/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Читаем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_HOST_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_host_fmask(2*i);
              p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_host_fmask(2*i+1);
            end if;
          end loop;

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_HDD/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Читаем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_HDD_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_hdd_fmask(2*i);
              p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_hdd_fmask(2*i+1);
            end if;
          end loop;

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_VCTRL/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Читаем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_vctrl_fmask(2*i);
              p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_vctrl_fmask(2*i+1);
            end if;
          end loop;

        end if;
    end if;
  end if;
end process;


b_rst_eth_bufs  <=p_in_rst or h_reg_ctrl(C_DSN_SWT_REG_CTRL_RST_ETH_BUFS_BIT);
b_rst_vctrl_bufs<=p_in_rst or h_reg_ctrl(C_DSN_SWT_REG_CTRL_RST_VCTRL_BUFS_BIT);

b_ethtxbuf_loopback<=h_reg_ctrl(C_DSN_SWT_REG_CTRL_ETHTXD_LOOPBACK_BIT);

b_tstdsn_to_ethtxbuf     <=h_reg_ctrl(C_DSN_SWT_REG_CTRL_TSTDSN_TO_ETHTX_BIT);
b_ethtxbuf_to_vctrlbufin <=h_reg_ctrl(C_DSN_SWT_REG_CTRL_TSTDSN_TO_VCTRL_BUFIN_BIT);
b_ethtxbuf_to_hddbuf     <=h_reg_ctrl(C_DSN_SWT_REG_CTRL_TSTDSN_TO_HDDBUF_BIT);



--//########################################################################
--//Разветвление сигнала записи данных rxdata от модуля dsn_ethg.vhd
--//########################################################################

--//Синхронизируем управление ветвлением данных с началом прининятого пакета Ethernet
process(p_in_rst,p_in_eth_clk)
begin
  if p_in_rst='1' then

    for i in 0 to C_DSN_SWT_ETHG_HOST_FMASK_COUNT-1 loop
      syn_eth_host_fmask(2*i)  <=(others=>'0');
      syn_eth_host_fmask(2*i+1)<=(others=>'0');
    end loop;

    for i in 0 to C_DSN_SWT_ETHG_HDD_FMASK_COUNT-1 loop
      syn_eth_hdd_fmask(2*i)  <=(others=>'0');
      syn_eth_hdd_fmask(2*i+1)<=(others=>'0');
    end loop;

    for i in 0 to C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT-1 loop
      syn_eth_vctrl_fmask(2*i)  <=(others=>'0');
      syn_eth_vctrl_fmask(2*i+1)<=(others=>'0');
    end loop;

    syn_eth_rxd<=(others=>'0');
    syn_eth_rxd_wr<='0';
    syn_eth_rxd_sof<='0';
    syn_eth_rxd_eof<='0';

  elsif p_in_eth_clk'event and p_in_eth_clk='1' then

    if p_in_eth_rxd_sof='1' then

      for i in 0 to C_DSN_SWT_ETHG_HOST_FMASK_COUNT-1 loop
        syn_eth_host_fmask(2*i)  <= h_reg_eth_host_fmask(2*i);
        syn_eth_host_fmask(2*i+1)<= h_reg_eth_host_fmask(2*i+1);
      end loop;

      for i in 0 to C_DSN_SWT_ETHG_HDD_FMASK_COUNT-1 loop
        syn_eth_hdd_fmask(2*i)  <= h_reg_eth_hdd_fmask(2*i);
        syn_eth_hdd_fmask(2*i+1)<= h_reg_eth_hdd_fmask(2*i+1);
      end loop;

      for i in 0 to C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT-1 loop
        syn_eth_vctrl_fmask(2*i)  <= h_reg_eth_vctrl_fmask(2*i);
        syn_eth_vctrl_fmask(2*i+1)<= h_reg_eth_vctrl_fmask(2*i+1);
      end loop;

    end if;

    syn_eth_rxd<=p_in_eth_rxbuf_din;
    syn_eth_rxd_wr<=p_in_eth_rxbuf_wr;
    syn_eth_rxd_sof<=p_in_eth_rxd_sof;
    syn_eth_rxd_eof<=p_in_eth_rxd_eof;

  end if;
end process;




--//########################################################################
--//Обмен Хоста <-> EthG (dsn_ethg.vhd)
--//########################################################################
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Хост -> ETHG_TXFIFO.(запись данных в Gigabit Ethernet)
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

--//----------------------------------
--//Связь с модулем хоста dsn_host.vhd
--//----------------------------------
i_eth_txbuf_din <=p_in_host_eth_txd     when b_tstdsn_to_ethtxbuf='0' else p_in_dsntst_txbuf_din(31 downto 0);
i_eth_txbuf_wr  <=p_in_host_eth_wr      when b_tstdsn_to_ethtxbuf='0' else p_in_dsntst_txbuf_wr;
i_eth_txd_rdy   <=p_in_host_eth_txd_rdy when b_tstdsn_to_ethtxbuf='0' else p_in_dsntst_txd_rdy;

--//Сигнал хосту EthG TxBUF - готов принять данные
p_out_host_eth_txbuf_rdy<=i_eth_txbuf_empty and not b_tstdsn_to_ethtxbuf;

--//----------------------------------
--//Буфер TXDATA для модуля dsn_ethg.vhd
--//----------------------------------
m_eth_txbuf : host_ethg_txfifo
port map
(
din     => i_eth_txbuf_din,
wr_en   => i_eth_txbuf_wr,
wr_clk  => p_in_host_clk,

dout    => i_eth_txbuf_dout,
rd_en   => i_eth_txbuf_rd,
rd_clk  => p_in_eth_clk,

empty   => i_eth_txbuf_empty,
full    => p_out_eth_txbuf_full,
almost_empty=> open,

rst     => b_rst_eth_bufs
);

--//----------------------------------
--//Связь с модулем dsn_ethg.vhd
--//----------------------------------
--//Чтение данных из буфера m_eth_txbuf.
i_eth_txbuf_rd<=    p_in_eth_txbuf_rd when b_ethtxbuf_loopback='0' and (b_ethtxbuf_to_vctrlbufin='0' and b_ethtxbuf_to_hddbuf='0') else
                not i_eth_txbuf_empty when b_ethtxbuf_loopback='1' and (b_ethtxbuf_to_vctrlbufin='0' and b_ethtxbuf_to_hddbuf='0') else
                not i_eth_txbuf_empty when b_ethtxbuf_loopback='0' and (b_ethtxbuf_to_vctrlbufin='1' or  b_ethtxbuf_to_hddbuf='1') else
                '0';

p_out_eth_txbuf_dout <=i_eth_txbuf_dout;
p_out_eth_txbuf_empty<=i_eth_txbuf_empty;


--//Растягиваем импульс готовности данных для dsn_ethg.vhd
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    hclk_eth_txd_rdy_cnt<=(others=>'0');
    hclk_eth_txd_rdy<='0';
  elsif p_in_host_clk'event and p_in_host_clk='1' then
    if i_eth_txd_rdy='1' then
      hclk_eth_txd_rdy<='1';
    elsif hclk_eth_txd_rdy_cnt(2)='1' then
      hclk_eth_txd_rdy<='0';
    end if;

    if hclk_eth_txd_rdy='0' then
      hclk_eth_txd_rdy_cnt<=(others=>'0');
    else
      hclk_eth_txd_rdy_cnt<=hclk_eth_txd_rdy_cnt+1;
    end if;
  end if;
end process;

--//Пересинхронизация на частоту p_in_eth_clk + выделение фронта
process(p_in_rst,p_in_eth_clk)
begin
  if p_in_rst='1' then
    eclk_eth_txd_rdy_dly<=(others=>'0');
    eclk_eth_txd_rdy<='0';
  elsif p_in_eth_clk'event and p_in_eth_clk='1' then
    eclk_eth_txd_rdy_dly(0)<=hclk_eth_txd_rdy;
    eclk_eth_txd_rdy_dly(1)<=eclk_eth_txd_rdy_dly(0);
    --//Фронт
    eclk_eth_txd_rdy<=eclk_eth_txd_rdy_dly(0) and not eclk_eth_txd_rdy_dly(1);
  end if;
end process;

--//Сигнал модулю dsn_ethg.vhd - есть данные для передачи по EthG
p_out_eth_txd_rdy<= eclk_eth_txd_rdy and
                   not i_eth_txbuf_empty and
                   not b_ethtxbuf_loopback and
                   not (b_ethtxbuf_to_vctrlbufin or b_ethtxbuf_to_hddbuf);



--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Хост <- ETHG_RXFIFO.(чтение данных из Gigabit Ethernet)
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Фильтер пакетов от модуля dsn_ethg.vhd
m_host_eth_pkt_fltr: video_pkt_filter
generic map(
G_FMASK_COUNT   => C_DSN_SWT_ETHG_HOST_FMASK_COUNT
)
port map
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_fmask      => syn_eth_host_fmask,

--//------------------------------------
--//Upstream Port
--//------------------------------------
p_in_upp_data   => syn_eth_rxd,
p_in_upp_wr     => syn_eth_rxd_wr,
p_in_upp_eof    => syn_eth_rxd_eof,
p_in_upp_sof    => syn_eth_rxd_sof,

--//------------------------------------
--//Downstream Port
--//------------------------------------
p_out_dwnp_data => i_eth_rxbuf_fltr_dout,
p_out_dwnp_wr   => i_eth_rxbuf_fltr_den,
p_out_dwnp_eof  => i_eth_rxbuf_fltr_eof,
p_out_dwnp_sof  => open,

-------------------------------
--Технологический
-------------------------------
p_out_tst       => open,

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk        => p_in_eth_clk,
p_in_rst        => b_rst_eth_bufs
);

--//Выбор источника данных для буфера m_eth_rxbuf
i_eth_rxbuf_din <=i_eth_rxbuf_fltr_dout when b_ethtxbuf_loopback='0' else     i_eth_txbuf_dout;
i_eth_rxbuf_wr  <=i_eth_rxbuf_fltr_den  when b_ethtxbuf_loopback='0' else not i_eth_txbuf_empty;
i_eth_rxd_rdy   <=i_eth_rxbuf_fltr_eof  when b_ethtxbuf_loopback='0' else     eclk_eth_txd_rdy;

--//----------------------------------
--//Буфер RXDATA для модуля dsn_ethg.vhd
--//----------------------------------
m_eth_rxbuf : host_ethg_rxfifo
port map
(
din     => i_eth_rxbuf_din,
wr_en   => i_eth_rxbuf_wr,
wr_clk  => p_in_eth_clk,

dout    => p_out_host_eth_rxd,
rd_en   => p_in_host_eth_rd,
rd_clk  => p_in_host_clk,

empty   => i_eth_rxbuf_empty,
full    => p_out_eth_rxbuf_full,

rst     => b_rst_eth_bufs
);


--//----------------------------------
--//Связь с модулем хоста dsn_host.vhd
--//----------------------------------
p_out_eth_rxbuf_empty<=i_eth_rxbuf_empty;

--//Сигнал Хосту: в RxBUF есть новые данные от Gigabit Ethernet
p_out_host_eth_rxd_rdy<=not i_eth_rxbuf_empty;

--//Формируем прерываение ETH_RXBUF
process(p_in_rst,p_in_eth_clk)
begin
  if p_in_rst='1' then
    i_eth_rxd_rdy_dly<=(others=>'0');
    eclk_eth_rxd_rdy_wcnt<=(others=>'0');
    eclk_eth_rxd_rdy_w<='0';

  elsif p_in_eth_clk'event and p_in_eth_clk='1' then
    i_eth_rxd_rdy_dly(0)<=i_eth_rxd_rdy;
    i_eth_rxd_rdy_dly(1)<=i_eth_rxd_rdy_dly(0);
    i_eth_rxd_rdy_dly(2)<=i_eth_rxd_rdy_dly(1);

    --//Растягиваем импульс готовности данных от модуля dsn_ethg.vhd
    if i_eth_rxd_rdy_dly(2)='1' then
      eclk_eth_rxd_rdy_w<='1';
    elsif eclk_eth_rxd_rdy_wcnt(2)='1' then
      eclk_eth_rxd_rdy_w<='0';
    end if;

    if eclk_eth_rxd_rdy_w='0' then
      eclk_eth_rxd_rdy_wcnt<=(others=>'0');
    else
      eclk_eth_rxd_rdy_wcnt<=eclk_eth_rxd_rdy_wcnt+1;
    end if;
  end if;
end process;

--//Пересинхронизация на частоту p_in_host_clk
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    hclk_eth_rxd_rdy<='0';
  elsif p_in_host_clk'event and p_in_host_clk='1' then
    hclk_eth_rxd_rdy<=eclk_eth_rxd_rdy_w;
  end if;
end process;

p_out_host_eth_rxd_irq<=hclk_eth_rxd_rdy;



--//#############################################################################
--//Связь EthG->HDD(накопитель) (dsn_hdd.vhd)
--//#############################################################################
--//Фильтер пакетов от модуля dsn_ethg.vhd
m_eth_hdd_pkt_fltr: video_pkt_filter
generic map(
G_FMASK_COUNT   => C_DSN_SWT_ETHG_HDD_FMASK_COUNT
)
port map
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_fmask      => syn_eth_hdd_fmask,

--//------------------------------------
--//Upstream Port
--//------------------------------------
p_in_upp_data   => syn_eth_rxd,
p_in_upp_wr     => syn_eth_rxd_wr,
p_in_upp_eof    => syn_eth_rxd_eof,
p_in_upp_sof    => syn_eth_rxd_sof,

--//------------------------------------
--//Downstream Port
--//------------------------------------
p_out_dwnp_data => i_hdd_vbuf_fltr_dout,
p_out_dwnp_wr   => i_hdd_vbuf_fltr_den,
p_out_dwnp_eof  => open,
p_out_dwnp_sof  => open,

-------------------------------
--Технологический
-------------------------------
p_out_tst       => open,

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk        => p_in_eth_clk,
p_in_rst        => i_hdd_vbuf_rst
);

--//Выбор данных для модуля dsn_hdd.vhd
i_hdd_vbuf_din<=i_hdd_vbuf_fltr_dout when b_ethtxbuf_to_hddbuf='0' else i_eth_txbuf_dout;
i_hdd_vbuf_wr <=i_hdd_vbuf_fltr_den  when b_ethtxbuf_to_hddbuf='0' else i_eth_txbuf_rd;

m_eth_hdd : ethg_vctrl_rxfifo
port map
(
din         => i_hdd_vbuf_din,
wr_en       => i_hdd_vbuf_wr,
wr_clk      => p_in_eth_clk,

dout        => p_in_hdd_vbuf_dout,
rd_en       => p_in_hdd_vbuf_rd,
rd_clk      => p_in_hdd_vbuf_rdclk,

empty       => p_out_hdd_vbuf_empty,
full        => p_out_hdd_vbuf_full,
prog_full   => p_out_hdd_vbuf_pfull,

rst         => i_hdd_vbuf_rst
);

i_hdd_vbuf_rst<=p_in_rst or p_in_hdd_vbuf_rst;


--//#############################################################################
--//Связь EthG->VIDEO_CTRL(модуль видеоконтроллера) (dsn_video_ctrl.vhd)
--//#############################################################################
--//Фильтер пакетов от модуля dsn_ethg.vhd
m_eth_vbufin_pkt_fltr: video_pkt_filter
generic map(
G_FMASK_COUNT   => C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT
)
port map
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_fmask      => syn_eth_vctrl_fmask,

--//------------------------------------
--//Upstream Port
--//------------------------------------
p_in_upp_data   => syn_eth_rxd,
p_in_upp_wr     => syn_eth_rxd_wr,
p_in_upp_eof    => syn_eth_rxd_eof,
p_in_upp_sof    => syn_eth_rxd_sof,

--//------------------------------------
--//Downstream Port
--//------------------------------------
p_out_dwnp_data => i_vctrl_vbufin_fltr_dout,
p_out_dwnp_wr   => i_vctrl_vbufin_fltr_den,
p_out_dwnp_eof  => open,
p_out_dwnp_sof  => open,

-------------------------------
--Технологический
-------------------------------
p_out_tst       => open,

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk        => p_in_eth_clk,
p_in_rst        => b_rst_vctrl_bufs
);

--//Выбор источника данных для буфера m_vctrl_vbufin модуля dsn_video_ctrl.vhd
p_out_vctrl_vbufin_rdy<='0';
i_vctrl_vbufin_din    <=i_vctrl_vbufin_fltr_dout when b_ethtxbuf_to_vctrlbufin='0' else i_eth_txbuf_dout;
i_vctrl_vbufin_din_wd <=i_vctrl_vbufin_fltr_den  when b_ethtxbuf_to_vctrlbufin='0' else i_eth_txbuf_rd;

--//----------------------------------
--//Входной буфер для модуля dsn_video_ctrl.vhd
--//----------------------------------
m_vctrl_vbufin : ethg_vctrl_rxfifo
port map
(
din         => i_vctrl_vbufin_din,
wr_en       => i_vctrl_vbufin_din_wd,
wr_clk      => p_in_eth_clk,

dout        => p_out_vctrl_vbufin_dout,
rd_en       => p_in_vctrl_vbufin_rd,
rd_clk      => p_in_vctrl_clk,

empty       => p_out_vctrl_vbufin_empty,
full        => p_out_vctrl_vbufin_full,
prog_full   => p_out_vctrl_vbufin_pfull,

rst         => b_rst_vctrl_bufs
);

--//----------------------------------
--//Выходной буфер для модуля dsn_video_ctrl.vhd
--//----------------------------------
m_vctrl_vbufout : host_vbuf
port map
(
din         => p_in_vctrl_vbufout_din,
wr_en       => p_in_vctrl_vbufout_wr,
wr_clk      => p_in_vctrl_clk,

dout        => p_out_host_vbuf_dout,
rd_en       => p_in_host_vbuf_rd,
rd_clk      => p_in_host_clk,

empty       => i_vctrl_vbufout_empty,
full        => open,
--almost_full => open,
prog_full   => p_out_vctrl_vbufout_full,
--almost_empty=> open,

rst         => b_rst_vctrl_bufs
);

p_out_vctrl_vbufout_empty <=i_vctrl_vbufout_empty;
p_out_host_vbuf_empty <=i_vctrl_vbufout_empty;



--//#############################################################################
--//Связь с Модулем Тестирования(dsn_testing.vhd)
--//#############################################################################
p_out_dsntst_bufclk <=p_in_host_clk;

p_out_dsntst_txbuf_empty <=i_eth_txbuf_empty or not b_tstdsn_to_ethtxbuf;
p_out_dsntst_txbuf_full  <='1';



--END MAIN
end behavioral;
