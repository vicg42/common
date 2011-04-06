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
use work.memory_ctrl_pkg.all;
use work.sata_pkg.all;
--use work.eth_pkg.all;

entity dsn_switch is
port
(
-------------------------------
-- Конфигурирование модуля DSN_SWITCH.VHD (host_clk domain)
-------------------------------
p_in_cfg_clk          : in   std_logic;                      --//

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);   --//
p_in_cfg_adr_ld       : in   std_logic;                      --//
p_in_cfg_adr_fifo     : in   std_logic;                      --//

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);  --//
p_in_cfg_wd           : in   std_logic;                      --//

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);  --//
p_in_cfg_rd           : in   std_logic;                      --//

p_in_cfg_done         : in   std_logic;                      --//

-------------------------------
-- Связь с Хостом (host_clk domain)
-------------------------------
p_in_host_clk             : in   std_logic;                      --//

-- Связь Хост <-> Накопитель(dsn_hdd.vhd)
p_out_host_hdd_cmddone_set_irq : out  std_logic;                           --//
p_out_host_hdd_rxbuf_rdy  : out  std_logic;                                --//
p_out_host_hdd_rxdata     : out  std_logic_vector(C_FHOST_DBUS-1 downto 0);--//
p_in_host_hdd_rd          : in   std_logic;                                --//

p_out_host_hdd_cmdbuf_rdy : out  std_logic;                                --//

p_out_host_hdd_txbuf_rdy  : out  std_logic;                                --//
p_in_host_hdd_txdata      : in   std_logic_vector(C_FHOST_DBUS-1 downto 0);--//
p_in_host_hdd_wd          : in   std_logic;                                --//

-- Связь Хост <-> Опритка(dsn_optic.vhd)
p_out_host_ethg_rx_set_irq: out  std_logic;
p_out_host_ethg_rxbuf_rdy : out  std_logic;                                --//
p_out_host_ethg_rxdata    : out  std_logic_vector(C_FHOST_DBUS-1 downto 0);--//
p_in_host_ethg_rd         : in   std_logic;                                --//

p_out_host_ethg_txbuf_rdy : out  std_logic;                                --//
p_in_host_ethg_txdata     : in   std_logic_vector(C_FHOST_DBUS-1 downto 0);--//
p_in_host_ethg_wd         : in   std_logic;                                --//
p_in_host_ethg_txdata_rdy : in   std_logic;                                --//

-- Связь Хост <-> VideoBUF
p_out_host_vbuf_dout      : out  std_logic_vector(C_FHOST_DBUS-1 downto 0);--//
p_in_host_vbuf_rd         : in   std_logic;                                --//
p_out_host_vbuf_empty     : out  std_logic;                                --//

-------------------------------
-- Связь с Накопителем(dsn_hdd.vhd)
-------------------------------
p_in_hdd_bufrst           : in   std_logic;                     --//
p_in_hdd_bufclk           : in   std_logic;                      --//
p_in_hdd_status_module    : in   std_logic_vector(15 downto 0);  --//

p_in_hdd_cmdbuf_empty     : in   std_logic;                      --//

p_out_hdd_txdata          : out  std_logic_vector(31 downto 0);  --//
p_out_hdd_txdata_wd       : out  std_logic;                      --//
p_in_hdd_txbuf_empty      : in   std_logic;                      --//
p_in_hdd_txbuf_full       : in   std_logic;                      --//

p_in_hdd_rxdata           : in   std_logic_vector(31 downto 0);  --//
p_out_hdd_rxdata_rd       : out  std_logic;                      --//
p_in_hdd_rxbuf_empty      : in   std_logic;                      --//
p_in_hdd_rxbuf_full       : in   std_logic;                      --//

p_out_hdd_txstream           : out  std_logic_vector(31 downto 0); --//
p_in_hdd_txstream_rd         : in   std_logic;                     --//
p_in_hdd_txstream_rd_clk     : in   std_logic;                     --//
p_out_hdd_txstream_buf_empty : out  std_logic;                     --//
p_out_hdd_txstream_buf_full  : out  std_logic;                     --//
p_out_hdd_txstream_buf_pfull : out  std_logic;                     --//

-------------------------------
-- Связь с EthG(Оптика)(dsn_optic.vhd) (ethg_clk domain)
-------------------------------
p_in_ethg_clk                : in   std_logic;                     --//

p_in_ethg_rxdata_rdy         : in   std_logic;                     --//
p_in_ethg_rxdata_sof         : in   std_logic;                     --//
p_in_ethg_rxbuf_din          : in   std_logic_vector(31 downto 0); --//
p_in_ethg_rxbuf_wd           : in   std_logic;                     --//
p_out_ethg_rxbuf_empty       : out  std_logic;                     --//
p_out_ethg_rxbuf_full        : out  std_logic;                     --//

p_out_ethg_txdata_rdy        : out  std_logic;
p_out_ethg_txbuf_dout        : out  std_logic_vector(31 downto 0); --//
p_in_ethg_txbuf_rd           : in   std_logic;                     --//
p_out_ethg_txbuf_empty       : out  std_logic;                     --//
p_out_ethg_txbuf_full        : out  std_logic;                     --//
p_out_ethg_txbuf_empty_almost: out  std_logic;                     --//

-------------------------------
-- Связь с Модулем Видео контроллера(dsn_video_ctrl.vhd) (trc_clk domain)
-------------------------------
p_in_vctrl_clk               : in   std_logic;                      --//

p_out_vbufin_rdy             : out  std_logic;                      --//
p_out_vbufin_dout            : out  std_logic_vector(31 downto 0);  --//
p_in_vbufin_rd               : in   std_logic;                      --//
p_out_vbufin_empty           : out  std_logic;                      --//
p_out_vbufin_full            : out  std_logic;                      --//
p_out_vbufin_pfull           : out  std_logic;                      --//

p_in_vbufout_din             : in   std_logic_vector(31 downto 0);  --//
p_in_vbufout_wd              : in   std_logic;                      --//
p_out_vbufout_empty          : out  std_logic;                      --//
p_out_vbufout_full           : out  std_logic;                      --//

-------------------------------
-- Связь с Модулем Тестирования(dsn_testing.vhd)
-------------------------------
p_out_dsntst_bufclk          : out  std_logic;                      --//

p_in_dsntst_txdata_rdy       : in   std_logic;                      --//
p_in_dsntst_txdata_dout      : in   std_logic_vector(31 downto 0);  --//
p_in_dsntst_txdata_wd        : in   std_logic;                      --//
p_out_dsntst_txbuf_empty     : out  std_logic;                      --//
p_out_dsntst_txbuf_full      : out  std_logic;                      --//

-------------------------------
--Технологический
-------------------------------
p_out_tst    : out   std_logic_vector(31 downto 0);  --//

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
din         : IN  std_logic_vector(31 downto 0);--(C_FHOST_DBUS-1 downto 0);
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
din         : IN  std_logic_vector(31 downto 0);--(C_FHOST_DBUS-1 downto 0);
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

dout        : OUT std_logic_vector(31 downto 0);--(C_FHOST_DBUS-1 downto 0);
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

component eth_rx_pkt_filter
generic(
G_FMASK_COUNT     : integer := 3
);
port
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_fmask               : in    TEthFmask;

--//------------------------------------
--//Upstream Port
--//------------------------------------
p_in_upp_data            : in    std_logic_vector(31 downto 0);
p_in_upp_wr              : in    std_logic;
p_in_upp_rdy             : in    std_logic;
p_in_upp_sof             : in    std_logic;

--//------------------------------------
--//Downstream Port
--//------------------------------------
p_out_dwnp_data          : out   std_logic_vector(31 downto 0);
p_out_dwnp_wr            : out   std_logic;
p_out_dwnp_rdy           : out   std_logic;
p_out_dwnp_sof           : out   std_logic;

-------------------------------
--Технологический
-------------------------------
p_out_tst                : out   std_logic_vector(31 downto 0);

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk                 : in    std_logic;
p_in_rst                 : in    std_logic
);
end component;

signal i_cfg_adr_cnt                          : std_logic_vector(7 downto 0);

signal h_reg_ctrl                             : std_logic_vector(C_DSN_SWT_REG_CTRL_LAST_BIT downto 0);
signal h_reg_tst0                             : std_logic_vector(C_DSN_SWT_REG_TST0_LAST_BIT downto 0);
signal h_reg_ethg_host_fmask                  : TEthFmask;
signal h_reg_ethg_hdd_fmask                   : TEthFmask;
signal h_reg_ethg_vctrl_fmask                 : TEthFmask;

signal b_rst_ethg_bufs                        : std_logic;
signal b_rst_vctrl_bufs                       : std_logic;
signal b_ethtxbuf_loopback                    : std_logic;
signal b_tstdsn_to_ethtxbuf                   : std_logic;
signal b_ethtxbuf_to_vctrlbufin               : std_logic;
signal b_ethtxbuf_to_hddbuf                   : std_logic;

signal syn_ethg_rxdata                        : std_logic_vector(31 downto 0);
signal syn_ethg_rxdata_wd                     : std_logic;
signal syn_ethg_rxdata_rdy                    : std_logic;
signal syn_ethg_rxdata_sof                    : std_logic;
signal syn_ethg_host_fmask                    : TEthFmask;
signal syn_ethg_hdd_fmask                     : TEthFmask;
signal syn_ethg_vctrl_fmask                   : TEthFmask;

signal hclk_hdd_cmddone_irq                   : std_logic;
signal i_hdd_cmd_busy_dly                     : std_logic_vector(1 downto 0);
signal hddclk_hdd_cmd_busy_edge_width         : std_logic;
signal hddclk_hdd_cmd_busy_edge_width_cnt     : std_logic_vector(2 downto 0);

signal i_ethg_hdd_fltr_dout                   : std_logic_vector(31 downto 0);
signal i_ethg_hdd_fltr_dout_vld               : std_logic;
signal i_ethg_hddbuf                          : std_logic_vector(31 downto 0);
signal i_ethg_hddbuf_wd                       : std_logic;
signal i_ethg_hddbuf_empty                    : std_logic;
signal i_ethg_hddbuf_full                     : std_logic;
signal i_ethg_hddbuf_pfull                    : std_logic;
--signal i_ethg_hddbuf_aempty                   : std_logic;
--signal i_ethg_hddbuf_pempty                   : std_logic;

signal hclk_host_ethtxdata_rdy_width          : std_logic;
signal hclk_host_ethtxdata_rdy_width_cnt      : std_logic_vector(2 downto 0);
signal ethclk_host_ethtxdata_rdy_width_dly    : std_logic_vector(1 downto 0);
signal ethclk_host_ethtxdata_rdy              : std_logic;
signal ethclk_host_ethtxdata_rdy_out          : std_logic;
signal i_host_ethtxdata_rdy                   : std_logic;
signal i_host_ethtxbuf_dout                   : std_logic_vector(31 downto 0);
signal i_host_ethtxbuf_din                    : std_logic_vector(C_FHOST_DBUS-1 downto 0);
signal i_host_ethtxbuf_wd                     : std_logic;
signal i_host_ethtxbuf_rd                     : std_logic;
signal i_host_ethtxbuf_empty                  : std_logic;
signal i_host_ethtxbuf_full                   : std_logic;
signal i_host_ethtxbuf_aempty                 : std_logic;

signal i_host_ethrxbuf_din                    : std_logic_vector(31 downto 0);
signal i_host_ethrxbuf_din_wd                 : std_logic;
signal i_host_ethrxbuf_dout                   : std_logic_vector(C_FHOST_DBUS-1 downto 0);
--signal i_host_ethrxbuf_dout_swap            : std_logic_vector(C_FHOST_DBUS-1 downto 0);
signal i_host_ethrxbuf_empty                  : std_logic;
signal i_host_ethrxbuf_rdy                    : std_logic;
signal i_host_ethrxbuf_rdy_dly                : std_logic_vector(2 downto 0);
signal i_host_ethrxbuf_full                   : std_logic;
signal i_host_ethrx_fltr_dout                 : std_logic_vector(31 downto 0);
signal i_host_ethrx_fltr_dout_vld             : std_logic;
signal i_host_ethrx_fltr_dout_rdy             : std_logic;
--signal i_host_ethrx_fltr_dout_sof            : std_logic;

signal hclk_host_ethrxbuf_rdy                 : std_logic;
signal ethclk_host_ethrxbuf_rdy_width         : std_logic;
signal ethclk_host_ethrxbuf_rdy_width_cnt     : std_logic_vector(2 downto 0);

signal i_ethg_vctrl_fltr_dout                 : std_logic_vector(31 downto 0);
signal i_ethg_vctrl_fltr_dout_vld             : std_logic;
signal i_ethg_vbufin_din                      : std_logic_vector(31 downto 0);
signal i_ethg_vbufin_din_wd                   : std_logic;
signal i_ethg_vbufin_empty                    : std_logic;
signal i_ethg_vbufin_full                     : std_logic;
signal i_ethg_vbufin_pfull                    : std_logic;

signal i_host_vbuf_empty                      : std_logic;


--signal tst_ethg_vctrl_out                     : std_logic_vector(31 downto 0);
--signal tst_rst_vctrl_bufs                     : std_logic;


--MAIN
begin

--process(p_in_vctrl_clk)
--begin
--  if p_in_vctrl_clk'event and p_in_vctrl_clk='1' then
----    p_out_tst(0)<=i_host_vbuf_almost_full;
--    tst_rst_vctrl_bufs<=b_rst_vctrl_bufs;
--  end if;
--end process;

p_out_tst(0)<='0';--tst_rst_vctrl_bufs;
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
      h_reg_ethg_host_fmask(2*i)  <=(others=>'0');
      h_reg_ethg_host_fmask(2*i+1)<=(others=>'0');
    end loop;

    for i in 0 to C_DSN_SWT_ETHG_HDD_FMASK_COUNT-1 loop
      h_reg_ethg_hdd_fmask(2*i)  <=(others=>'0');
      h_reg_ethg_hdd_fmask(2*i+1)<=(others=>'0');
    end loop;

    for i in 0 to C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT-1 loop
      h_reg_ethg_vctrl_fmask(2*i)  <=(others=>'0');
      h_reg_ethg_vctrl_fmask(2*i+1)<=(others=>'0');
    end loop;

  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_CTRL_L, i_cfg_adr_cnt'length) then h_reg_ctrl<=p_in_cfg_txdata(h_reg_ctrl'high downto 0);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_TST0, i_cfg_adr_cnt'length)   then h_reg_tst0<=p_in_cfg_txdata(h_reg_tst0'high downto 0);

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_HOST/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Заполняем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_HOST_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              h_reg_ethg_host_fmask(2*i)  <=p_in_cfg_txdata(7 downto 0);
              h_reg_ethg_host_fmask(2*i+1)<=p_in_cfg_txdata(15 downto 8);
            end if;
          end loop;

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_HDD/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Заполняем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_HDD_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              h_reg_ethg_hdd_fmask(2*i)  <=p_in_cfg_txdata(7 downto 0);
              h_reg_ethg_hdd_fmask(2*i+1)<=p_in_cfg_txdata(15 downto 8);
            end if;
          end loop;

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_VCTRL/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Заполняем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              h_reg_ethg_vctrl_fmask(2*i)  <=p_in_cfg_txdata(7 downto 0);
              h_reg_ethg_vctrl_fmask(2*i+1)<=p_in_cfg_txdata(15 downto 8);
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
              p_out_cfg_rxdata(7 downto 0) <=h_reg_ethg_host_fmask(2*i);
              p_out_cfg_rxdata(15 downto 8)<=h_reg_ethg_host_fmask(2*i+1);
            end if;
          end loop;

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_HDD/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Читаем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_HDD_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              p_out_cfg_rxdata(7 downto 0) <=h_reg_ethg_hdd_fmask(2*i);
              p_out_cfg_rxdata(15 downto 8)<=h_reg_ethg_hdd_fmask(2*i+1);
            end if;
          end loop;

        elsif i_cfg_adr_cnt(7 downto log2(C_DSN_SWT_FMASK_MAX_COUNT))=CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_FMASK_ETHG_VCTRL/C_DSN_SWT_FMASK_MAX_COUNT, (7-log2(C_DSN_SWT_FMASK_MAX_COUNT)+1)) then
        --//Читаем маски фильтрации пакетов
          for i in 0 to C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT-1 loop
            if i_cfg_adr_cnt(log2(C_DSN_SWT_FMASK_MAX_COUNT)-1 downto 0)=i then
              p_out_cfg_rxdata(7 downto 0) <=h_reg_ethg_vctrl_fmask(2*i);
              p_out_cfg_rxdata(15 downto 8)<=h_reg_ethg_vctrl_fmask(2*i+1);
            end if;
          end loop;

        end if;
    end if;
  end if;
end process;



b_rst_ethg_bufs  <=p_in_rst or h_reg_ctrl(C_DSN_SWT_REG_CTRL_RST_ETH_BUFS_BIT);
b_rst_vctrl_bufs <=p_in_rst or h_reg_ctrl(C_DSN_SWT_REG_CTRL_RST_VCTRL_BUFS_BIT);

b_ethtxbuf_loopback  <=h_reg_ctrl(C_DSN_SWT_REG_CTRL_ETHTXD_LOOPBACK_BIT);

b_tstdsn_to_ethtxbuf      <=h_reg_ctrl(C_DSN_SWT_REG_CTRL_TSTDSN_TO_ETHTX_BIT);
b_ethtxbuf_to_vctrlbufin  <=h_reg_ctrl(C_DSN_SWT_REG_CTRL_TSTDSN_TO_VCTRL_BUFIN_BIT);
b_ethtxbuf_to_hddbuf      <=h_reg_ctrl(C_DSN_SWT_REG_CTRL_TSTDSN_TO_HDDBUF_BIT);


--//########################################################################
--//Обмен Хост <-> Накопитель (dsn_hdd.vhd)
--//########################################################################
p_out_host_hdd_cmdbuf_rdy <=p_in_hdd_cmdbuf_empty;

--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Хост -> HDD_TXFIFO.(запись данных в накопитель)
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
p_out_hdd_txdata         <=p_in_host_hdd_txdata(31 downto 0);
p_out_hdd_txdata_wd      <=p_in_host_hdd_wd;

--//Сигнал Хосту: TxBUF готов принимать данные
p_out_host_hdd_txbuf_rdy <=p_in_hdd_txbuf_empty;

--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Хост <- HDD_RXFIFO.(чтение данных из накопителя)
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
p_out_hdd_rxdata_rd      <=p_in_host_hdd_rd;

p_out_host_hdd_rxdata    <=p_in_hdd_rxdata;

--//Сигнал Хосту: в RxBUF есть новые данные от накопителя + строб для установки прерывания
p_out_host_hdd_rxbuf_rdy<=not p_in_hdd_rxbuf_empty;
p_out_host_hdd_cmddone_set_irq<=hclk_hdd_cmddone_irq;

--//Формируем сигнал прерывания от накопителя (задний фронт бита C_STATUS_MODULE_BUSY_BIT)
--//Выделяем задний фронт сигнала BUSY накопителя
process(p_in_rst,p_in_hdd_bufclk)
begin
  if p_in_rst='1' then
    i_hdd_cmd_busy_dly<=(others=>'0');
  elsif p_in_hdd_bufclk'event and p_in_hdd_bufclk='1' then
    i_hdd_cmd_busy_dly(0)<=p_in_hdd_status_module(C_STATUS_MODULE_BUSY_BIT);
    i_hdd_cmd_busy_dly(1)<=i_hdd_cmd_busy_dly(0);
  end if;
end process;

--//Растягиваем сформированый импульс
process(p_in_rst,p_in_hdd_bufclk)
begin
  if p_in_rst='1' then
    hddclk_hdd_cmd_busy_edge_width<='0';
    hddclk_hdd_cmd_busy_edge_width_cnt<=(others=>'0');

  elsif p_in_hdd_bufclk'event and p_in_hdd_bufclk='1' then

    if i_hdd_cmd_busy_dly(0)='0' and i_hdd_cmd_busy_dly(1)='1' then
    --//Обноружил задний фронт сигнала C_STATUS_MODULE_BUSY_BIT
      hddclk_hdd_cmd_busy_edge_width<='1';
    elsif hddclk_hdd_cmd_busy_edge_width_cnt(2)='1' then--="100" then
      hddclk_hdd_cmd_busy_edge_width<='0';
    end if;

    if hddclk_hdd_cmd_busy_edge_width='0' then
      hddclk_hdd_cmd_busy_edge_width_cnt<=(others=>'0');
    else
      hddclk_hdd_cmd_busy_edge_width_cnt<=hddclk_hdd_cmd_busy_edge_width_cnt+1;
    end if;

  end if;
end process;

--//Пересинхронизация ипульса прерывания от накопителя
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    hclk_hdd_cmddone_irq<='0';
  elsif p_in_host_clk'event and p_in_host_clk='1' then
    hclk_hdd_cmddone_irq<=hddclk_hdd_cmd_busy_edge_width;
  end if;
end process;



--//########################################################################
--//Зарветвление сигнала записи данных rxdata от модуля dsn_ethg.vhd
--//########################################################################

--//Синхронизируем управление ветвлением данных с началом прининятого пакета Ethernet
process(p_in_rst,p_in_ethg_clk)
begin
  if p_in_rst='1' then

    for i in 0 to C_DSN_SWT_FMASK_MAX_COUNT-1 loop
      syn_ethg_host_fmask(2*i)  <=(others=>'0');
      syn_ethg_host_fmask(2*i+1)<=(others=>'0');
    end loop;

    for i in 0 to C_DSN_SWT_FMASK_MAX_COUNT-1 loop
      syn_ethg_hdd_fmask(2*i)  <=(others=>'0');
      syn_ethg_hdd_fmask(2*i+1)<=(others=>'0');
    end loop;

    for i in 0 to C_DSN_SWT_FMASK_MAX_COUNT-1 loop
      syn_ethg_vctrl_fmask(2*i)  <=(others=>'0');
      syn_ethg_vctrl_fmask(2*i+1)<=(others=>'0');
    end loop;

    syn_ethg_rxdata<=(others=>'0');
    syn_ethg_rxdata_rdy<='0';
    syn_ethg_rxdata_sof<='0';
    syn_ethg_rxdata_wd<='0';

  elsif p_in_ethg_clk'event and p_in_ethg_clk='1' then

    if p_in_ethg_rxdata_sof='1' then

      for i in 0 to C_DSN_SWT_ETHG_HOST_FMASK_COUNT-1 loop
        syn_ethg_host_fmask(2*i)  <= h_reg_ethg_host_fmask(2*i);
        syn_ethg_host_fmask(2*i+1)<= h_reg_ethg_host_fmask(2*i+1);
      end loop;

      for i in 0 to C_DSN_SWT_ETHG_HDD_FMASK_COUNT-1 loop
        syn_ethg_hdd_fmask(2*i)  <= h_reg_ethg_hdd_fmask(2*i);
        syn_ethg_hdd_fmask(2*i+1)<= h_reg_ethg_hdd_fmask(2*i+1);
      end loop;

      for i in 0 to C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT-1 loop
        syn_ethg_vctrl_fmask(2*i)  <= h_reg_ethg_vctrl_fmask(2*i);
        syn_ethg_vctrl_fmask(2*i+1)<= h_reg_ethg_vctrl_fmask(2*i+1);
      end loop;

    end if;

    syn_ethg_rxdata<=p_in_ethg_rxbuf_din;
    syn_ethg_rxdata_rdy<=p_in_ethg_rxdata_rdy;
    syn_ethg_rxdata_sof<=p_in_ethg_rxdata_sof;
    syn_ethg_rxdata_wd<=p_in_ethg_rxbuf_wd;

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
i_host_ethtxbuf_din <=p_in_host_ethg_txdata     when b_tstdsn_to_ethtxbuf='0' else p_in_dsntst_txdata_dout(31 downto 0);
i_host_ethtxbuf_wd  <=p_in_host_ethg_wd         when b_tstdsn_to_ethtxbuf='0' else p_in_dsntst_txdata_wd;
i_host_ethtxdata_rdy<=p_in_host_ethg_txdata_rdy when b_tstdsn_to_ethtxbuf='0' else p_in_dsntst_txdata_rdy;

--//Сигнал хосту EthG TxBUF - готов принять данные
p_out_host_ethg_txbuf_rdy<=i_host_ethtxbuf_empty and not b_tstdsn_to_ethtxbuf;

--//----------------------------------
--//Буфер TXDATA для модуля dsn_ethg.vhd
--//----------------------------------
m_host_ethg_txfifo : host_ethg_txfifo
port map
(
din     => i_host_ethtxbuf_din,
wr_en   => i_host_ethtxbuf_wd,
wr_clk  => p_in_host_clk,

dout    => i_host_ethtxbuf_dout,
rd_en   => i_host_ethtxbuf_rd,
rd_clk  => p_in_ethg_clk,

empty   => i_host_ethtxbuf_empty,
full    => i_host_ethtxbuf_full,
almost_empty=> i_host_ethtxbuf_aempty,
--almost_full => i_host_ethtxbuf_empty_full,

rst     => b_rst_ethg_bufs
);

--//----------------------------------
--//Связь с модулем dsn_ethg.vhd
--//----------------------------------
--//Чтение данных из буфера m_host_ethg_txfifo.
--//если LoopBack, то переписываем данные в буфер Хост->EthG RxBUF
--//иначе модуль dsn_ethg.vhd вычитывает данные.
--i_host_ethtxbuf_rd<=p_in_ethg_txbuf_rd when b_ethtxbuf_loopback='0' else not i_host_ethtxbuf_empty;
i_host_ethtxbuf_rd<=p_in_ethg_txbuf_rd    when b_ethtxbuf_loopback='0' and (b_ethtxbuf_to_vctrlbufin='0' and b_ethtxbuf_to_hddbuf='0') else
                not i_host_ethtxbuf_empty when b_ethtxbuf_loopback='1' and (b_ethtxbuf_to_vctrlbufin='0' and b_ethtxbuf_to_hddbuf='0') else
                not i_host_ethtxbuf_empty when b_ethtxbuf_loopback='0' and (b_ethtxbuf_to_vctrlbufin='1' or  b_ethtxbuf_to_hddbuf='1') else
                '0';

p_out_ethg_txbuf_dout <=i_host_ethtxbuf_dout;
p_out_ethg_txbuf_empty<=i_host_ethtxbuf_empty;
p_out_ethg_txbuf_full <=i_host_ethtxbuf_full;
p_out_ethg_txbuf_empty_almost<=i_host_ethtxbuf_aempty;

--//Растягиваем импульс готовности данных для dsn_ethg.vhd
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    hclk_host_ethtxdata_rdy_width_cnt<=(others=>'0');
    hclk_host_ethtxdata_rdy_width<='0';
  elsif p_in_host_clk'event and p_in_host_clk='1' then
    if i_host_ethtxdata_rdy='1' then
      hclk_host_ethtxdata_rdy_width<='1';
    elsif hclk_host_ethtxdata_rdy_width_cnt(2)='1' then--="010" then
      hclk_host_ethtxdata_rdy_width<='0';
    end if;

    if hclk_host_ethtxdata_rdy_width='0' then
      hclk_host_ethtxdata_rdy_width_cnt<=(others=>'0');
    else
      hclk_host_ethtxdata_rdy_width_cnt<=hclk_host_ethtxdata_rdy_width_cnt+1;
    end if;
  end if;
end process;

--//Пересинхронизация ипульса импульс готовности данных для dsn_ethg.vhd
--//+ выделение фронта
process(p_in_rst,p_in_ethg_clk)
begin
  if p_in_rst='1' then
    ethclk_host_ethtxdata_rdy_width_dly<=(others=>'0');
    ethclk_host_ethtxdata_rdy<='0';
  elsif p_in_ethg_clk'event and p_in_ethg_clk='1' then
    ethclk_host_ethtxdata_rdy_width_dly(0)<=hclk_host_ethtxdata_rdy_width;
    ethclk_host_ethtxdata_rdy_width_dly(1)<=ethclk_host_ethtxdata_rdy_width_dly(0);
    --//Фронт
    ethclk_host_ethtxdata_rdy<=ethclk_host_ethtxdata_rdy_width_dly(0) and not ethclk_host_ethtxdata_rdy_width_dly(1);
  end if;
end process;

--//Сигнал модулю dsn_ethg.vhd - есть данные для передачи по EthG
ethclk_host_ethtxdata_rdy_out <= ethclk_host_ethtxdata_rdy and
                             not i_host_ethtxbuf_empty and
                             not b_ethtxbuf_loopback and
                             not (b_ethtxbuf_to_vctrlbufin or b_ethtxbuf_to_hddbuf);

p_out_ethg_txdata_rdy<=ethclk_host_ethtxdata_rdy_out;


--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Хост <- ETHG_RXFIFO.(чтение данных из Gigabit Ethernet)
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//----------------------------------
--//Связь с модулем dsn_ethg.vhd
--//----------------------------------

--//Фильтер пакетов от модуля dsn_ethg.vhd
m_host_eth_pkt_fltr: eth_rx_pkt_filter
generic map(
G_FMASK_COUNT   => C_DSN_SWT_ETHG_HOST_FMASK_COUNT
)
port map
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_fmask        => syn_ethg_host_fmask,

--//------------------------------------
--//Upstream Port
--//------------------------------------
p_in_upp_data     => syn_ethg_rxdata,
p_in_upp_wr       => syn_ethg_rxdata_wd,
p_in_upp_rdy      => syn_ethg_rxdata_rdy,
p_in_upp_sof      => syn_ethg_rxdata_sof,

--//------------------------------------
--//Downstream Port
--//------------------------------------
p_out_dwnp_data   => i_host_ethrx_fltr_dout,
p_out_dwnp_wr     => i_host_ethrx_fltr_dout_vld,
p_out_dwnp_rdy    => i_host_ethrx_fltr_dout_rdy,
p_out_dwnp_sof    => open,

-------------------------------
--Технологический
-------------------------------
p_out_tst        => open,

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk          => p_in_ethg_clk,
p_in_rst          => b_rst_ethg_bufs
);

--//Выбор источника данных для буфера m_host_ethg_rxfifo
i_host_ethrxbuf_din   <=i_host_ethrx_fltr_dout     when b_ethtxbuf_loopback='0' else     i_host_ethtxbuf_dout;
i_host_ethrxbuf_din_wd<=i_host_ethrx_fltr_dout_vld when b_ethtxbuf_loopback='0' else not i_host_ethtxbuf_empty;
i_host_ethrxbuf_rdy   <=i_host_ethrx_fltr_dout_rdy when b_ethtxbuf_loopback='0' else     ethclk_host_ethtxdata_rdy;

--//----------------------------------
--//Буфер RXDATA для модуля dsn_ethg.vhd
--//----------------------------------
m_host_ethg_rxfifo : host_ethg_rxfifo
port map
(
din     => i_host_ethrxbuf_din,
wr_en   => i_host_ethrxbuf_din_wd,
wr_clk  => p_in_ethg_clk,

dout    => i_host_ethrxbuf_dout,
rd_en   => p_in_host_ethg_rd,
rd_clk  => p_in_host_clk,

empty   => i_host_ethrxbuf_empty,
full    => i_host_ethrxbuf_full,

rst     => b_rst_ethg_bufs
);

p_out_ethg_rxbuf_empty<=i_host_ethrxbuf_empty;
p_out_ethg_rxbuf_full <=i_host_ethrxbuf_full;


--//----------------------------------
--//Связь с модулем хоста dsn_host.vhd
--//----------------------------------
--i_host_ethrxbuf_dout_swap(31 downto 0) <=i_host_ethrxbuf_dout(31 downto 0);
--i_host_ethrxbuf_dout_swap(16*1-1 downto 16*0)<=i_host_ethrxbuf_dout(16*2-1 downto 16*1);
--i_host_ethrxbuf_dout_swap(16*2-1 downto 16*1)<=i_host_ethrxbuf_dout(16*1-1 downto 16*0);
--
--p_out_host_ethg_rxdata<=i_host_ethrxbuf_dout  when b_ethtxbuf_loopback='1' else
--                        i_host_ethrxbuf_dout_swap;
p_out_host_ethg_rxdata<=i_host_ethrxbuf_dout;

--//Сигнал Хосту: в RxBUF есть новые данные от Gigabit Ethernet
p_out_host_ethg_rxbuf_rdy<=not i_host_ethrxbuf_empty;


--//Растягиваем импульс готовности данных от модуля dsn_ethg.vhd
process(p_in_rst,p_in_ethg_clk)
begin
  if p_in_rst='1' then
    i_host_ethrxbuf_rdy_dly<=(others=>'0');
    ethclk_host_ethrxbuf_rdy_width_cnt<=(others=>'0');
    ethclk_host_ethrxbuf_rdy_width<='0';
  elsif p_in_ethg_clk'event and p_in_ethg_clk='1' then
    i_host_ethrxbuf_rdy_dly(0)<=i_host_ethrxbuf_rdy;
    i_host_ethrxbuf_rdy_dly(1)<=i_host_ethrxbuf_rdy_dly(0);
    i_host_ethrxbuf_rdy_dly(2)<=i_host_ethrxbuf_rdy_dly(1);

    if i_host_ethrxbuf_rdy_dly(2)='1' then
      ethclk_host_ethrxbuf_rdy_width<='1';
    elsif ethclk_host_ethrxbuf_rdy_width_cnt(2)='1' then--="010" then
      ethclk_host_ethrxbuf_rdy_width<='0';
    end if;

    if ethclk_host_ethrxbuf_rdy_width='0' then
      ethclk_host_ethrxbuf_rdy_width_cnt<=(others=>'0');
    else
      ethclk_host_ethrxbuf_rdy_width_cnt<=ethclk_host_ethrxbuf_rdy_width_cnt+1;
    end if;
  end if;
end process;

--//Пересинхронизация строба готовности данных HOST_ETHG_RXBUF (установка прерывания)
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    hclk_host_ethrxbuf_rdy<='0';
  elsif p_in_host_clk'event and p_in_host_clk='1' then
    hclk_host_ethrxbuf_rdy<=ethclk_host_ethrxbuf_rdy_width;
  end if;
end process;

p_out_host_ethg_rx_set_irq<=hclk_host_ethrxbuf_rdy;



--//#############################################################################
--//Связь EthG->HDD(накопитель) (dsn_hdd.vhd)
--//#############################################################################
--//Фильтер пакетов от модуля dsn_ethg.vhd
m_eth_hdd_pkt_fltr: eth_rx_pkt_filter
generic map(
G_FMASK_COUNT   => C_DSN_SWT_ETHG_HDD_FMASK_COUNT
)
port map
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_fmask        => syn_ethg_hdd_fmask,

--//------------------------------------
--//Upstream Port
--//------------------------------------
p_in_upp_data     => syn_ethg_rxdata,
p_in_upp_wr       => syn_ethg_rxdata_wd,
p_in_upp_rdy      => syn_ethg_rxdata_rdy,
p_in_upp_sof      => syn_ethg_rxdata_sof,

--//------------------------------------
--//Downstream Port
--//------------------------------------
p_out_dwnp_data   => i_ethg_hdd_fltr_dout,
p_out_dwnp_wr     => i_ethg_hdd_fltr_dout_vld,
p_out_dwnp_rdy    => open,
p_out_dwnp_sof    => open,

-------------------------------
--Технологический
-------------------------------
p_out_tst        => open,

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk          => p_in_ethg_clk,
p_in_rst          => p_in_hdd_bufrst
);

--//Выбор данных для модуля dsn_hdd.vhd
i_ethg_hddbuf    <=i_ethg_hdd_fltr_dout     when b_ethtxbuf_to_hddbuf='0' else i_host_ethtxbuf_dout;
i_ethg_hddbuf_wd <=i_ethg_hdd_fltr_dout_vld when b_ethtxbuf_to_hddbuf='0' else i_host_ethtxbuf_rd;


m_ethg_hdd : ethg_vctrl_rxfifo
port map
(
din         => i_ethg_hddbuf,
wr_en       => i_ethg_hddbuf_wd,
wr_clk      => p_in_ethg_clk,

dout        => p_out_hdd_txstream,
rd_en       => p_in_hdd_txstream_rd,
rd_clk      => p_in_hdd_txstream_rd_clk,

empty       => i_ethg_hddbuf_empty,
full        => i_ethg_hddbuf_full,
prog_full   => i_ethg_hddbuf_pfull,
--almost_empty=> open,
--prog_empty  => open,

rst         => p_in_hdd_bufrst
);

p_out_hdd_txstream_buf_empty<=i_ethg_hddbuf_empty;
p_out_hdd_txstream_buf_full <=i_ethg_hddbuf_full;
p_out_hdd_txstream_buf_pfull<=i_ethg_hddbuf_pfull;


--//#############################################################################
--//Связь EthG->VIDEO_CTRL(модуль видеоконтроллера) (dsn_video_ctrl.vhd)
--//#############################################################################
--//----------------------------------
--//Связь с модулем Ethernet dsn_ethg.vhd
--//----------------------------------
--//Фильтер пакетов от модуля dsn_ethg.vhd
m_eth_vbufin_pkt_fltr: eth_rx_pkt_filter
generic map(
G_FMASK_COUNT   => C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT
)
port map
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_fmask        => syn_ethg_vctrl_fmask,

--//------------------------------------
--//Upstream Port
--//------------------------------------
p_in_upp_data     => syn_ethg_rxdata,
p_in_upp_wr       => syn_ethg_rxdata_wd,
p_in_upp_rdy      => syn_ethg_rxdata_rdy,
p_in_upp_sof      => syn_ethg_rxdata_sof,

--//------------------------------------
--//Downstream Port
--//------------------------------------
p_out_dwnp_data   => i_ethg_vctrl_fltr_dout,
p_out_dwnp_wr     => i_ethg_vctrl_fltr_dout_vld,
p_out_dwnp_rdy    => open,
p_out_dwnp_sof    => open,

-------------------------------
--Технологический
-------------------------------
p_out_tst        => open,--tst_ethg_vctrl_out,

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk          => p_in_ethg_clk,
p_in_rst          => b_rst_vctrl_bufs
);

--//Выбор источника данных для буфера m_ethg_vctrl_rxfifo модуля dsn_video_ctrl.vhd
p_out_vbufin_rdy    <='0';
i_ethg_vbufin_din   <=i_ethg_vctrl_fltr_dout      when b_ethtxbuf_to_vctrlbufin='0' else i_host_ethtxbuf_dout;
i_ethg_vbufin_din_wd<=i_ethg_vctrl_fltr_dout_vld  when b_ethtxbuf_to_vctrlbufin='0' else i_host_ethtxbuf_rd;

--//----------------------------------
--//Буфер данных для модуля dsn_video_ctrl.vhd
--//----------------------------------
m_ethg_vctrl_rxfifo : ethg_vctrl_rxfifo
port map
(
din         => i_ethg_vbufin_din,
wr_en       => i_ethg_vbufin_din_wd,
wr_clk      => p_in_ethg_clk,

dout        => p_out_vbufin_dout,
rd_en       => p_in_vbufin_rd,
rd_clk      => p_in_vctrl_clk,

empty       => i_ethg_vbufin_empty,
full        => i_ethg_vbufin_full,
prog_full   => i_ethg_vbufin_pfull,
--almost_empty=> open,
--prog_empty  => open,

rst         => b_rst_vctrl_bufs
);

p_out_vbufin_empty<=i_ethg_vbufin_empty;
p_out_vbufin_full<=i_ethg_vbufin_full;
p_out_vbufin_pfull<=i_ethg_vbufin_pfull;


--//----------------------------------
--//Связь с модулем в dsn_host.vhd
--//----------------------------------
p_out_host_vbuf_empty <=i_host_vbuf_empty;

m_host_vbuf : host_vbuf
port map
(
din         => p_in_vbufout_din,
wr_en       => p_in_vbufout_wd,
wr_clk      => p_in_vctrl_clk,

dout        => p_out_host_vbuf_dout,
rd_en       => p_in_host_vbuf_rd,
rd_clk      => p_in_host_clk,

empty       => i_host_vbuf_empty,
full        => open,
--almost_full => open,
prog_full   => p_out_vbufout_full,
--almost_empty=> open,

rst         => b_rst_vctrl_bufs
);

p_out_vbufout_empty <=i_host_vbuf_empty;




--//#############################################################################
--//Связь с Модулем Тестирования(dsn_testing.vhd)
--//#############################################################################
p_out_dsntst_bufclk <=p_in_host_clk;

p_out_dsntst_txbuf_empty <=i_host_ethtxbuf_empty or not b_tstdsn_to_ethtxbuf;
p_out_dsntst_txbuf_full  <='1';



--END MAIN
end behavioral;
