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

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_unit_pkg.all;

entity sata_raid is
generic(
G_HDD_COUNT : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_DBGCS     : string :="OFF";
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_usr_status        : out   TUsrStatus;

--//ctrl - hw start
p_out_hw_work           : out   std_logic;
p_out_hw_start          : out   std_logic;
p_in_hw_start           : in    std_logic;

--//cmdpkt
p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_in_usr_cxd_wr         : in    std_logic;

--//txfifo
p_in_usr_txd            : in    std_logic_vector(31 downto 0);
p_out_usr_txd_rd        : out   std_logic;
p_in_usr_txbuf_empty    : in    std_logic;

--//rxfifo
p_out_usr_rxd           : out   std_logic_vector(31 downto 0);
p_out_usr_rxd_wr        : out   std_logic;
p_in_usr_rxbuf_full     : in    std_logic;

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_in_sh_status          : in    TALStatus_SHCountMax;
p_out_sh_ctrl           : out   TALCtrl_SHCountMax;

p_out_sh_cxd            : out   TBus16_SHCountMax;
p_out_sh_cxd_sof_n      : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_sh_cxd_eof_n      : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_sh_cxd_src_rdy_n  : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_out_sh_txd            : out   TBus32_SHCountMax;
p_out_sh_txd_wr         : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_in_sh_rxd             : in    TBus32_SHCountMax;
p_out_sh_rxd_rd         : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_in_sh_txbuf_status    : in    TTxBufStatus_SHCountMax;
p_in_sh_rxbuf_status    : in    TRxBufStatus_SHCountMax;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);
p_out_dbgcs             : out   TSH_ila;

p_in_sh_tst             : in    TBus32_SHCountMax;
p_out_sh_tst            : out   TBus32_SHCountMax;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end sata_raid;

architecture behavioral of sata_raid is

signal i_raid_prm                  : TRaid;

signal i_sh_num                    : std_logic_vector(2 downto 0);
signal i_sh_mask                   : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_sh_padding                : std_logic;

signal i_sh_cxd                    : std_logic_vector(15 downto 0);
signal i_sh_cxd_sof_n              : std_logic;
signal i_sh_cxd_eof_n              : std_logic;
signal i_sh_cxd_src_rdy_n          : std_logic;

signal i_sh_hdd                    : std_logic_vector(2 downto 0);

signal i_sh_txd                    : std_logic_vector(31 downto 0);
signal i_sh_txd_wr                 : std_logic;
signal i_sh_txbuf_full             : std_logic;

signal i_sh_rxd                    : std_logic_vector(31 downto 0);
signal i_sh_rxd_rd                 : std_logic;
signal i_sh_rxbuf_empty            : std_logic;

signal tst_sata_raid_ctrl_out      : std_logic_vector(31 downto 0);
signal tst_sata_raid_recoder_out   : std_logic_vector(31 downto 0);


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

p_out_tst(0)<=tst_sata_raid_ctrl_out(0);
p_out_tst(1)<=tst_sata_raid_recoder_out(0);
p_out_tst(31 downto 2)<=(others=>'0');
end generate gen_dbg_on;


--//модуль управления
m_ctrl : sata_raid_ctrl
generic map(
G_HDD_COUNT => G_HDD_COUNT,
G_DBGCS     => G_DBGCS,
G_DBG       => G_DBG,
G_SIM       => G_SIM
)
port map(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           => p_in_usr_ctrl,
p_out_usr_status        => p_out_usr_status,

--//ctrl - hw start
p_out_hw_work           => p_out_hw_work,
p_out_hw_start          => p_out_hw_start,
p_in_hw_start           => p_in_hw_start,

--//cmd
p_in_usr_cxd            => p_in_usr_cxd,
p_in_usr_cxd_wr         => p_in_usr_cxd_wr,

--//txfifo
p_in_usr_txd            => p_in_usr_txd,
p_out_usr_txd_rd        => p_out_usr_txd_rd,
p_in_usr_txbuf_empty    => p_in_usr_txbuf_empty,

--//rxfifo
p_out_usr_rxd           => p_out_usr_rxd,
p_out_usr_rxd_wr        => p_out_usr_rxd_wr,
p_in_usr_rxbuf_full     => p_in_usr_rxbuf_full,

--------------------------------------------------
--Связь с модулем sata_raid_decoder.vhd
--------------------------------------------------
p_in_sh_status          => p_in_sh_status,
p_out_sh_ctrl           => p_out_sh_ctrl,

p_in_raid               => i_raid_prm,
p_in_sh_num             => i_sh_num,
p_out_sh_hdd            => i_sh_hdd,
p_out_sh_mask           => i_sh_mask,
p_out_sh_padding        => i_sh_padding,

p_out_sh_cxd            => i_sh_cxd,
p_out_sh_cxd_sof_n      => i_sh_cxd_sof_n,
p_out_sh_cxd_eof_n      => i_sh_cxd_eof_n,
p_out_sh_cxd_src_rdy_n  => i_sh_cxd_src_rdy_n,

p_out_sh_txd            => i_sh_txd,
p_out_sh_txd_wr         => i_sh_txd_wr,
p_in_sh_txbuf_full      => i_sh_txbuf_full,

p_in_sh_rxd             => i_sh_rxd,
p_out_sh_rxd_rd         => i_sh_rxd_rd,
p_in_sh_rxbuf_empty     => i_sh_rxbuf_empty,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => p_in_tst,
p_out_tst               => tst_sata_raid_ctrl_out,
p_out_dbgcs             => p_out_dbgcs,

p_in_sh_tst             => p_in_sh_tst,
p_out_sh_tst            => p_out_sh_tst,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);


m_decoder : sata_raid_decoder
generic map(
G_HDD_COUNT => G_HDD_COUNT,
G_DBG       => G_DBG,
G_SIM       => G_SIM
)
port map(
--------------------------------------------------
--Связь с модулем sata_raid_ctrl.vhd
--------------------------------------------------
p_out_raid              => i_raid_prm,
p_out_sh_num            => i_sh_num,
p_in_sh_hdd             => i_sh_hdd,
p_in_sh_mask            => i_sh_mask,
p_in_sh_padding         => i_sh_padding,

p_in_usr_cxd            => i_sh_cxd,
p_in_usr_cxd_sof_n      => i_sh_cxd_sof_n,
p_in_usr_cxd_eof_n      => i_sh_cxd_eof_n,
p_in_usr_cxd_src_rdy_n  => i_sh_cxd_src_rdy_n,

p_in_usr_txd            => i_sh_txd,
p_in_usr_txd_wr         => i_sh_txd_wr,
p_out_usr_txbuf_full    => i_sh_txbuf_full,

p_out_usr_rxd           => i_sh_rxd,
p_in_usr_rxd_rd         => i_sh_rxd_rd,
p_out_usr_rxbuf_empty   => i_sh_rxbuf_empty,


--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_out_sh_cxd            => p_out_sh_cxd,
p_out_sh_cxd_sof_n      => p_out_sh_cxd_sof_n,
p_out_sh_cxd_eof_n      => p_out_sh_cxd_eof_n,
p_out_sh_cxd_src_rdy_n  => p_out_sh_cxd_src_rdy_n,

p_out_sh_txd            => p_out_sh_txd,
p_out_sh_txd_wr         => p_out_sh_txd_wr,

p_in_sh_rxd             => p_in_sh_rxd,
p_out_sh_rxd_rd         => p_out_sh_rxd_rd,

p_in_sh_txbuf_status    => p_in_sh_txbuf_status,
p_in_sh_rxbuf_status    => p_in_sh_rxbuf_status,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => p_in_tst,
p_out_tst               => tst_sata_raid_recoder_out,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);

--END MAIN
end behavioral;
