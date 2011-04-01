-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 14:54:34
-- Module Name : sata_raid
--
-- Назначение :
--
-- Revision:
-- Revision 0.01 - File Created
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;

entity sata_raid is
generic
(
G_HDD_COUNT : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port
(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           : in    std_logic_vector(31 downto 0);
p_out_usr_status        : out   TUsrStatus;

--//Связь с CMDFIFO
p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_out_usr_cxd_rd        : out   std_logic;
p_in_usr_cxbuf_empty    : in    std_logic;

--//Связь с TxFIFO
p_in_usr_txd            : in    std_logic_vector(31 downto 0);
p_out_usr_txd_rd        : out   std_logic;
p_in_usr_txbuf_empty    : in    std_logic;

--//Связь с RxFIFO
p_out_usr_rxd           : out   std_logic_vector(31 downto 0);
p_out_usr_rxd_wr        : out   std_logic;

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_in_uap_status         : in    TALStatus_SataCountMax;
p_out_uap_ctrl          : out   TALCtrl_SataCountMax;

p_out_uap_cxd           : out   TBus16_SataCountMax;
p_out_uap_cxd_sof_n     : out   std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
p_out_uap_cxd_eof_n     : out   std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
p_out_uap_cxd_src_rdy_n : out   std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);

p_out_uap_txd           : out   TBus32_SataCountMax;
p_out_uap_txd_wr        : out   std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);

p_in_uap_rxd            : in    TBus32_SataCountMax;
p_out_uap_rxd_rd        : out   std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);

p_in_uap_txbuf_status   : in    TTxBufStatus_SataCountMax;
p_in_uap_rxbuf_status   : in    TRxBufStatus_SataCountMax;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

p_in_sh_tst             : in    TBus32_SataCountMax;
p_out_sh_tst            : out   TBus32_SataCountMax;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end sata_raid;

architecture behavioral of sata_raid is

signal i_sh_cxd                    : std_logic_vector(15 downto 0);
signal i_sh_cxd_sof_n              : std_logic;
signal i_sh_cxd_eof_n              : std_logic;
signal i_sh_cxd_src_rdy_n          : std_logic;
signal i_sh_cxd_mask               : std_logic_vector(7 downto 0);

signal i_sh_tx_dst_adr             : std_logic_vector(2 downto 0);
signal i_sh_txd                    : std_logic_vector(31 downto 0);
signal i_sh_txd_wr                 : std_logic;

signal i_sh_rx_src_adr             : std_logic_vector(2 downto 0);
signal i_sh_rxd                    : std_logic_vector(31 downto 0);
signal i_sh_rxd_rd                 : std_logic;
signal i_sh_rxbuf_empty            : std_logic;


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
--ltstout:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    tst_fms_cs_dly<=(others=>'0');
--    p_out_tst(31 downto 1)<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    tst_fms_cs_dly<=tst_fms_cs;
--    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
--  end if;
--end process ltstout;
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_on;


--//модуль управления
m_ctrl : sata_raid_ctrl
generic map
(
G_HDD_COUNT => G_HDD_COUNT,
G_DBG       => G_DBG,
G_SIM       => G_SIM
)
port map
(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           => p_in_usr_ctrl,
p_out_usr_status        => p_out_usr_status,

--//Связь с CMDFIFO
p_in_usr_cxd            => p_in_usr_cxd,
p_out_usr_cxd_rd        => p_out_usr_cxd_rd,
p_in_usr_cxbuf_empty    => p_in_usr_cxbuf_empty,

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_in_sh_status          => p_in_uap_status,
p_out_sh_ctrl           => p_out_uap_ctrl,

p_out_sh_cxd            => i_sh_cxd,
p_out_sh_cxd_sof_n      => i_sh_cxd_sof_n,
p_out_sh_cxd_eof_n      => i_sh_cxd_eof_n,
p_out_sh_cxd_src_rdy_n  => i_sh_cxd_src_rdy_n,
p_out_sh_mask           => i_sh_cxd_mask,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => p_in_tst,
p_out_tst               => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);


m_dmux : sata_raid_dmux
generic map
(
G_HDD_COUNT => G_HDD_COUNT,
G_DBG       => G_DBG,
G_SIM       => G_SIM
)
port map
(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
--//Связь с TxFIFO
p_in_usr_txd            => p_in_usr_txd,
p_out_usr_txd_rd        => p_out_usr_txd_rd,
p_in_usr_txbuf_empty    => p_in_usr_txbuf_empty,

--//Связь с RxFIFO
p_out_usr_rxd           => p_out_usr_rxd,
p_out_usr_rxd_wr        => p_out_usr_rxd_wr,

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_out_sh_tx_dst_adr     => i_sh_tx_dst_adr,
p_out_sh_txd            => i_sh_txd,
p_out_sh_txd_wr         => i_sh_txd_wr,

p_out_sh_rx_src_adr     => i_sh_rx_src_adr,
p_in_sh_rxd             => i_sh_rxd,
p_out_sh_rxd_rd         => i_sh_rxd_rd,
p_in_sh_rxbuf_empty     => i_sh_rxbuf_empty,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => p_in_tst,
p_out_tst               => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);



gen_shcount : for i in 0 to C_SATA_COUNT_MAX-1 generate
p_out_sh_tst(i)<=(others=>'0');

--//передача командного пакета
p_out_uap_cxd_sof_n(i)<=i_sh_cxd_sof_n when i_sh_cxd_mask(i)='1' else '1';
p_out_uap_cxd_eof_n(i)<=i_sh_cxd_eof_n when i_sh_cxd_mask(i)='1' else '1';
p_out_uap_cxd_src_rdy_n(i)<=i_sh_cxd_src_rdy_n when i_sh_cxd_mask(i)='1' else '1';
p_out_uap_cxd(i)<=i_sh_cxd;


--//Чтение из RXFIFO
p_out_uap_rxd_rd(i)<=i_sh_rxd_rd when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(i, i_sh_rx_src_adr'length) else '0';

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_uap_txd(i)<=(others=>'0');
    p_out_uap_txd_wr(i)<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    p_out_uap_txd(i)<=i_sh_txd;
    if i_sh_tx_dst_adr=CONV_STD_LOGIC_VECTOR(i, i_sh_tx_dst_adr'length) then
      p_out_uap_txd_wr(i)<=i_sh_txd_wr;
    else
      p_out_uap_txd_wr(i)<='0';
    end if;
  end if;
end process;

end generate gen_shcount;

--//Выбор источника сигнала Empty (соотв. канала SATA) для формирования сигнала пермещения данных Host<-TransportLayer
--//Варианты:
gen_rx_shcount0 : if (G_HDD_COUNT-1)=0  generate
i_sh_rxbuf_empty<=p_in_uap_rxbuf_status(0).empty;
i_sh_rxd<=p_in_uap_rxd(0);
end generate gen_rx_shcount0;

gen_rx_shcount1 : if (G_HDD_COUNT-1)=1  generate
i_sh_rxbuf_empty<=p_in_uap_rxbuf_status(0).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(1).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else '1';

i_sh_rxd<=p_in_uap_rxd(0) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(1) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else (others=>'0');
end generate gen_rx_shcount1;

gen_rx_shcount2 : if (G_HDD_COUNT-1)=2  generate
i_sh_rxbuf_empty<=p_in_uap_rxbuf_status(0).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(1).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(2).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else '1';

i_sh_rxd<=p_in_uap_rxd(0) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(1) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(2) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else (others=>'0');
end generate gen_rx_shcount2;

gen_rx_shcount3 : if (G_HDD_COUNT-1)=3  generate
i_sh_rxbuf_empty<=p_in_uap_rxbuf_status(0).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(1).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(2).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(3).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#03#, i_sh_rx_src_adr'length) else '1';

i_sh_rxd<=p_in_uap_rxd(0) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(1) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(2) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(3) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#03#, i_sh_rx_src_adr'length) else (others=>'0');
end generate gen_rx_shcount3;

gen_rx_shcount4 : if (G_HDD_COUNT-1)=4  generate
i_sh_rxbuf_empty<=p_in_uap_rxbuf_status(0).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(1).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(2).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(3).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#03#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(4).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#04#, i_sh_rx_src_adr'length) else '1';

i_sh_rxd<=p_in_uap_rxd(0) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(1) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(2) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(3) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#03#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(4) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#04#, i_sh_rx_src_adr'length) else (others=>'0');
end generate gen_rx_shcount4;

gen_rx_shcount5 : if (G_HDD_COUNT-1)=5  generate
i_sh_rxbuf_empty<=p_in_uap_rxbuf_status(0).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(1).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(2).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(3).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#03#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(4).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#04#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(5).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#05#, i_sh_rx_src_adr'length) else '1';

i_sh_rxd<=p_in_uap_rxd(0) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(1) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(2) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(3) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#03#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(4) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#04#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(5) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#05#, i_sh_rx_src_adr'length);-- else (others=>'0');
end generate gen_rx_shcount5;

gen_rx_shcount6 : if (G_HDD_COUNT-1)=6  generate
i_sh_rxbuf_empty<=p_in_uap_rxbuf_status(0).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(1).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(2).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(3).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#03#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(4).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#04#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(5).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#05#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(6).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#06#, i_sh_rx_src_adr'length) else '1';

i_sh_rxd<=p_in_uap_rxd(0) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(1) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(2) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(3) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#03#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(4) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#04#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(5) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#05#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(6) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#06#, i_sh_rx_src_adr'length);-- else (others=>'0');
end generate gen_rx_shcount6;

gen_rx_shcount7 : if (G_HDD_COUNT-1)=7  generate
i_sh_rxbuf_empty<=p_in_uap_rxbuf_status(0).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(1).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(2).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(3).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#03#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(4).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#04#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(5).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#05#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(6).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#06#, i_sh_rx_src_adr'length) else
                  p_in_uap_rxbuf_status(7).empty when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#07#, i_sh_rx_src_adr'length) else '1';

i_sh_rxd<=p_in_uap_rxd(0) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#00#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(1) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#01#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(2) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#02#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(3) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#03#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(4) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#04#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(5) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#05#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(6) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#06#, i_sh_rx_src_adr'length) else
          p_in_uap_rxd(7) when i_sh_rx_src_adr=CONV_STD_LOGIC_VECTOR(10#07#, i_sh_rx_src_adr'length);-- else (others=>'0');
end generate gen_rx_shcount7;

--END MAIN
end behavioral;
