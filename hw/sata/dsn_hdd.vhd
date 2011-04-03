-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : dsn_hdd
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
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

use work.prj_def.all;
use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;

entity dsn_hdd is
generic
(
G_MODULE_USE           : string:="ON";
G_HDD_COUNT            : integer:=1;
G_DBG                  : string:="OFF";
G_SIM                  : string:="OFF"
);
port
(
-------------------------------
-- Конфигурирование модуля DSN_HDD.VHD (p_in_cfg_clk domain)
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
p_in_cfg_rst              : in   std_logic;

-------------------------------
-- STATUS модуля DSN_HDD.VHD
-------------------------------
p_out_hdd_rdy             : out  std_logic;                      --//
p_out_hdd_error           : out  std_logic;                      --//
p_out_hdd_busy            : out  std_logic;                      --//

-------------------------------
-- Связь с Источниками/Приемниками данных накопителя
-------------------------------
p_in_hdd_txd              : in   std_logic_vector(31 downto 0);  --//
p_in_hdd_txd_wr           : in   std_logic;                      --//
p_out_hdd_txbuf_full      : out  std_logic;                      --//

p_out_hdd_rxd             : out  std_logic_vector(31 downto 0);  --//
p_in_hdd_rxd_rd           : in   std_logic;                      --//
p_out_hdd_rxbuf_empty     : out  std_logic;                      --//

--------------------------------------------------
--SATA Driver
--------------------------------------------------
p_out_sata_txn            : out   std_logic_vector(1 downto 0);
p_out_sata_txp            : out   std_logic_vector(1 downto 0);
p_in_sata_rxn             : in    std_logic_vector(1 downto 0);
p_in_sata_rxp             : in    std_logic_vector(1 downto 0);

p_in_sata_refclk          : in    std_logic;

---------------------------------------------------------------------------
--Технологический порт
---------------------------------------------------------------------------
p_in_tst                 : in    std_logic_vector(31 downto 0);
p_out_tst                : in    std_logic_vector(31 downto 0);

--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gtp_txdata        : out   TBus32_SHCountMax;
p_out_sim_gtp_txcharisk     : out   TBus04_SHCountMax;
p_in_sim_gtp_rxdata         : in    TBus32_SHCountMax;
p_in_sim_gtp_rxcharisk      : in    TBus04_SHCountMax;
p_in_sim_gtp_rxstatus       : in    TBus03_SHCountMax;
p_in_sim_gtp_rxelecidle     : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gtp_rxdisperr      : in    TBus04_SHCountMax;
p_in_sim_gtp_rxnotintable   : in    TBus04_SHCountMax;
p_in_sim_gtp_rxbyteisaligned: in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gtp_sim_rst           : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gtp_sim_clk           : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_rst              : in    std_logic
);
end dsn_hdd;

architecture behavioral of dsn_hdd is

component mclk_gtp_wrap
port
(
p_out_sata_txn            : out   std_logic_vector(1 downto 0);
p_out_sata_txp            : out   std_logic_vector(1 downto 0);
p_in_sata_rxn             : in    std_logic_vector(1 downto 0);
p_in_sata_rxp             : in    std_logic_vector(1 downto 0);
clkin  : in    std_logic;
clkout : out   std_logic
);
end component;


signal i_cfg_adr_cnt                    : std_logic_vector(7 downto 0);

signal h_reg_ctrl_l                     : std_logic_vector(C_DSN_HDD_REG_CTRLL_LAST_BIT downto 0);
signal h_reg_tst0                       : std_logic_vector(C_DSN_HDD_REG_TST0_LAST_BIT downto 0);
signal h_reg_tst1                       : std_logic_vector(C_DSN_HDD_REG_TST1_LAST_BIT downto 0);

signal h_reg_rambuf_adr                 : std_logic_vector(31 downto 0);
--signal h_reg_rambuf_size                : std_logic_vector(31 downto 0);
--signal h_reg_rambuf_level               : std_logic_vector(15 downto 0);
--signal h_reg_rambuf_fifo_size           : std_logic_vector(15 downto 0);
signal h_reg_rambuf_ctrl                : std_logic_vector(15 downto 0);
--signal h_reg_satah_status               : std_logic_vector(15 downto 0);

signal i_sh_ctrl                        : std_logic_vector(31 downto 0);
signal i_sh_status                      : TUsrStatus;

signal i_sh_cmd_wr                      : std_logic;

signal i_sh_sim_gtp_txdata              : TBus32_SHCountMax;
signal i_sh_sim_gtp_txcharisk           : TBus04_SHCountMax;
signal i_sh_sim_gtp_rxdata              : TBus32_SHCountMax;
signal i_sh_sim_gtp_rxcharisk           : TBus04_SHCountMax;
signal i_sh_sim_gtp_rxstatus            : TBus03_SHCountMax;
signal i_sh_sim_gtp_rxelecidle          : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sh_sim_gtp_rxdisperr           : TBus04_SHCountMax;
signal i_sh_sim_gtp_rxnotintable        : TBus04_SHCountMax;
signal i_sh_sim_gtp_rxbyteisaligned     : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sh_sim_gtp_sim_rst             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sh_sim_gtp_sim_clk             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

signal tst_hdd_out                      : std_logic_vector(31 downto 0);



--MAIN
begin

--//--------------------------------------------------
--//Конфигурирование модуля DSN_HDD.VHD
--//--------------------------------------------------
--//Счетчик адреса регистров
process(p_in_cfg_rst,p_in_cfg_clk)
begin
  if p_in_cfg_rst='1' then
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
process(p_in_cfg_rst,p_in_cfg_clk)
begin
  if p_in_cfg_rst='1' then
    h_reg_ctrl_l<=(others=>'0');
    h_reg_tst0<=(others=>'0');
    h_reg_tst1<=(others=>'0');

    h_reg_rambuf_adr<=(others=>'0');
    h_reg_rambuf_ctrl<=(others=>'0');

  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then

    if p_in_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_CTRL_L, i_cfg_adr_cnt'length) then h_reg_ctrl_l<=p_in_cfg_txdata(h_reg_ctrl_l'high downto 0);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_TST0, i_cfg_adr_cnt'length)   then h_reg_tst0<=p_in_cfg_txdata(h_reg_tst0'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_TST1, i_cfg_adr_cnt'length)   then h_reg_tst1<=p_in_cfg_txdata(h_reg_tst1'high downto 0);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_ADR_L, i_cfg_adr_cnt'length) then h_reg_rambuf_adr(15 downto 0)<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_ADR_M, i_cfg_adr_cnt'length) then h_reg_rambuf_adr(31 downto 16)<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_CTRL, i_cfg_adr_cnt'length) then h_reg_rambuf_ctrl<=p_in_cfg_txdata;

        end if;
    end if;

  end if;
end process;

--//Чтение регистров
process(p_in_cfg_rst,p_in_cfg_clk)
begin
  if p_in_cfg_rst='1' then
    p_out_cfg_rxdata<=(others=>'0');
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_rd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_CTRL_L, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=EXT(h_reg_ctrl_l, p_out_cfg_rxdata'length);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_TST0, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=EXT(h_reg_tst0, p_out_cfg_rxdata'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_TST1, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=EXT(h_reg_tst1, p_out_cfg_rxdata'length);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_ADR_L, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=h_reg_rambuf_adr(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_ADR_M, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=h_reg_rambuf_adr(31 downto 16);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_CTRL, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=h_reg_rambuf_ctrl;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS, i_cfg_adr_cnt'length)           then p_out_cfg_rxdata(15 downto 0)<=EXT(i_sh_status.ch_err, 8)&EXT(i_sh_status.ch_drdy, 8);--h_reg_satah_status(15 downto 0);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS_SATA0_L, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata(15 downto 0)<=i_sh_status.SError(0)(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS_SATA0_M, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata(15 downto 0)<=i_sh_status.SError(0)(31 downto 16);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS_SATA1_L, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata(15 downto 0)<=i_sh_status.SError(1)(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS_SATA1_M, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata(15 downto 0)<=i_sh_status.SError(1)(31 downto 16);

--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_LBA_BPOINT_LSB, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata(15 downto 0)<=i_satadsn_status_lba_break_point(15 downto 0);
--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_LBA_BPOINT_MID, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata(15 downto 0)<=i_satadsn_status_lba_break_point(31 downto 16);
--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_LBA_BPOINT_MSB, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata(15 downto 0)<=i_satadsn_status_lba_break_point(47 downto 32);

        end if;
    end if;
  end if;
end process;

i_sh_ctrl<=EXT(h_reg_ctrl_l, i_sh_ctrl'length);

i_cfg_bufrst<=h_reg_ctrl_l(C_DSN_HDD_REG_CTRLL_BUFRST_BIT);--//Сброс всех буферов --//add 2010.08.18
i_cfg_buf_ovflow_disable_det<=h_reg_ctrl_l(C_DSN_HDD_REG_CTRLL_OVERFLOW_DET_BIT);--//add 2010.10.03


--//add 2010.10.03
--//Настройка/Управление RAM буфером
p_out_cfg_hdd_ramadr(15 downto 0)<=h_reg_rambuf_adr(15 downto 0);
p_out_cfg_hdd_ramadr(31 downto 16)<=h_reg_rambuf_adr(31 downto 16);
p_out_cfg_hdd_rambuf(C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_MSB_BIT downto C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_LSB_BIT)<=h_reg_rambuf_ctrl(C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_MSB_BIT downto C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_LSB_BIT);
p_out_cfg_hdd_rambuf(C_DSN_HDD_REG_RBUF_CTRL_RESERV_8BIT)<=h_reg_rambuf_ctrl(C_DSN_HDD_REG_RBUF_CTRL_RESERV_8BIT);
p_out_cfg_hdd_rambuf(C_DSN_HDD_REG_RBUF_CTRL_RESERV_9BIT)<=h_reg_rambuf_ctrl(C_DSN_HDD_REG_RBUF_CTRL_RESERV_9BIT);
p_out_cfg_hdd_rambuf(C_DSN_HDD_REG_RBUF_CTRL_RESERV_10BIT)<=h_reg_rambuf_ctrl(C_DSN_HDD_REG_RBUF_CTRL_RESERV_10BIT);
p_out_cfg_hdd_rambuf(C_DSN_HDD_REG_RBUF_CTRL_TEST_BIT)<=h_reg_rambuf_ctrl(C_DSN_HDD_REG_RBUF_CTRL_TEST_BIT);
p_out_cfg_hdd_rambuf(C_DSN_HDD_REG_RBUF_CTRL_STOP_BIT)<=h_reg_rambuf_ctrl(C_DSN_HDD_REG_RBUF_CTRL_STOP_BIT);
p_out_cfg_hdd_rambuf(C_DSN_HDD_REG_RBUF_CTRL_START_BIT)<=i_satadsn_status_module(C_STATUS_MODULE_STREAM_ON_BIT);
p_out_cfg_hdd_rambuf(C_DSN_HDD_REG_RBUF_CTRL_RST_BIT)<=i_cfg_bufrst;
p_out_cfg_hdd_rambuf(C_DSN_HDD_REG_RBUF_CTRL_STOPSYN_BIT)<=i_hw_stopsyn;
p_out_cfg_hdd_rambuf(31 downto C_DSN_HDD_REG_RBUF_CTRL_STOPSYN_BIT+1)<=(others=>'0');



gen_use_on : if strcmp(G_MODULE_USE,"ON") generate
begin

m_txfifo : hdd_txfifo
port map
(
din         => p_in_hdd_txd,
wr_en       => p_in_hdd_txd_wr,
--wr_clk      => ,

dout        => i_hdd_txd,
rd_en       => i_hdd_txd_rd,
--rd_clk      => ,

full        => open,
prog_full   => p_out_hdd_txbuf_full,
--almost_full => open,
empty       i_hdd_txbuf_empty,
--almost_empty=> open,

clk         => p_in_cfg_clk,
rst         => p_in_rst
);

p_out_hdd_txbuf_empty<=i_hdd_txbuf_empty;

m_rxfifo : hdd_rxfifo
port map
(
din         => i_hdd_rxd,
wr_en       => i_hdd_rxd_wr,
--wr_clk      => ,

dout        => p_out_hdd_rxd,
rd_en       => p_out_hdd_rxd_rd,
--rd_clk      => ,

full        => p_out_hdd_rxbuf_full,
--prog_full   => i_hdd_rxbuf_full,
almost_full => i_hdd_rxbuf_full,
empty       => p_out_hdd_rxbuf_empty,
--almost_empty=> open,

clk         => p_in_cfg_clk,
rst         => p_in_rst
);

--i_hdd_cmd<=p_in_cfg_txdata;
i_sh_cmd_wr <=p_in_cfg_wd  when p_in_cfg_adr_fifo='1' and i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_CMDFIFO, i_cfg_adr_cnt'length) else '0';
--i_hdd_cmd_rdy<=p_in_cfg_done when p_in_cfg_adr_fifo='1' and i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_CMDFIFO, i_cfg_adr_cnt'length) else '0';

--h_reg_satah_status(7 downto 0)<=EXT(i_sh_status.ch_drdy, 8);
--h_reg_satah_status(15 downto 8)<=EXT(i_sh_status.ch_err, 8);

p_out_hdd_rdy  <=i_sh_status.glob_drdy;
p_out_hdd_error<=i_sh_status.glob_err;
p_out_hdd_busy <=i_sh_status.glob_busy;

i_sata_gt_refclk(0)<=p_in_sata_refclk;

--//SATA
m_dsn_raid : dsn_raid_main
generic map
(
G_HDD_COUNT => G_HDD_COUNT,
G_GTP_DBUS  => 16,
G_DBG       => G_DBG,
G_SIM       => G_SIM
)
port map
(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              => pin_out_sata_txn,
p_out_sata_txp              => pin_out_sata_txp,
p_in_sata_rxn               => pin_in_sata_rxn,
p_in_sata_rxp               => pin_in_sata_rxp,

p_in_sata_refclk            => i_sata_gt_refclk,

--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl               => i_sh_ctrl,
p_out_usr_status            => i_sh_status,

--//cmdpkt
p_in_usr_cxd                => p_in_cfg_txdata,
p_in_usr_cxd_wr             => i_hdd_cmd_wr,

--//txfifo
p_in_usr_txd                => i_hdd_txd,
p_out_usr_txd_rd            => i_hdd_txd_rd,
p_in_usr_txbuf_empty        => i_hdd_txbuf_empty,

--//rxfifo
p_out_usr_rxd               => i_hdd_rxd,
p_out_usr_rxd_wr            => i_hdd_rxd_wr,
p_in_usr_rxbuf_full         => i_hdd_rxbuf_full,

--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gtp_txdata        => i_sh_sim_gtp_txdata,
p_out_sim_gtp_txcharisk     => i_sh_sim_gtp_txcharisk,
p_in_sim_gtp_rxdata         => i_sh_sim_gtp_rxdata,
p_in_sim_gtp_rxcharisk      => i_sh_sim_gtp_rxcharisk,
p_in_sim_gtp_rxstatus       => i_sh_sim_gtp_rxstatus,
p_in_sim_gtp_rxelecidle     => i_sh_sim_gtp_rxelecidle,
p_in_sim_gtp_rxdisperr      => i_sh_sim_gtp_rxdisperr,
p_in_sim_gtp_rxnotintable   => i_sh_sim_gtp_rxnotintable,
p_in_sim_gtp_rxbyteisaligned=> i_sh_sim_gtp_rxbyteisaligned,
p_out_gtp_sim_rst           => i_sh_sim_gtp_sim_rst,
p_out_gtp_sim_clk           => i_sh_sim_gtp_sim_clk,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                    => "00000000000000000000000000000000",--tst_hdd_in,
p_out_tst                   => p_out_tst,--tst_hdd_out,
--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_cfg_clk,
p_in_rst                => p_in_rst
);


--gen_satah: for i in 0 to C_HDD_COUNT_MAX-1 generate
--i_sh_sim_gtp_txdata(i)<=(others=>'0');
--i_sh_sim_gtp_txcharisk(i)<=(others=>'0');
--i_sh_sim_gtp_rxstatus(i)<=(others=>'0');
--i_sh_sim_gtp_rxelecidle(i)<='0';
--i_sh_sim_gtp_rxdisperr(i)<=(others=>'0');
--i_sh_sim_gtp_rxnotintable(i)<=(others=>'0');
--i_sh_sim_gtp_rxbyteisaligned(i)<='0';
--end generate gen_satah;

p_out_sim_gtp_txdata        <= i_sh_sim_gtp_txdata;
p_out_sim_gtp_txcharisk     <= i_sh_sim_gtp_txcharisk;
i_sh_sim_gtp_rxdata         <= p_in_sim_gtp_rxdata;
i_sh_sim_gtp_rxcharisk      <= p_in_sim_gtp_rxcharisk;
i_sh_sim_gtp_rxstatus       <= p_in_sim_gtp_rxstatus;
i_sh_sim_gtp_rxelecidle     <= p_in_sim_gtp_rxelecidle;
i_sh_sim_gtp_rxdisperr      <= p_in_sim_gtp_rxdisperr;
i_sh_sim_gtp_rxnotintable   <= p_in_sim_gtp_rxnotintable;
i_sh_sim_gtp_rxbyteisaligned<= p_in_sim_gtp_rxbyteisaligned;
p_out_gtp_sim_rst           <= i_sh_sim_gtp_sim_rst;
p_out_gtp_sim_clk           <= i_sh_sim_gtp_sim_clk;


end generate gen_use_on;


--END MAIN
end behavioral;
