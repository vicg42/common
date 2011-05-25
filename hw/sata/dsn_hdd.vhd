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

library work;
use work.prj_def.all;
use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.dsn_hdd_pkg.all;

entity dsn_hdd is
generic
(
G_MODULE_USE : string:="ON";
G_HDD_COUNT  : integer:=1;
G_DBG        : string:="OFF";
--G_DBGCS      : string:="OFF";
G_SIM        : string:="OFF"
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
p_out_hdd_irq             : out  std_logic;                      --//
p_out_hdd_done            : out  std_logic;                      --//

-------------------------------
-- Связь с Источниками/Приемниками данных накопителя
-------------------------------
p_out_rbuf_cfg            : out  THDDRBufCfg;  --//
p_in_rbuf_status          : in   THDDRBufStatus;--//Модуль находится в исходном состоянии + p_in_vbuf_empty and p_in_dwnp_buf_empty

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
p_out_sata_refclkout      : out   std_logic;
p_out_sata_gt_plldet      : out   std_logic;
p_out_sata_dcm_lock       : out   std_logic;

---------------------------------------------------------------------------
--Технологический порт
---------------------------------------------------------------------------
p_in_tst                 : in    std_logic_vector(31 downto 0);
p_out_tst                : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gtp_txdata        : out   TBus32_SHCountMax;
p_out_sim_gtp_txcharisk     : out   TBus04_SHCountMax;
p_out_sim_gtp_txcomstart    : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gtp_rxdata         : in    TBus32_SHCountMax;
p_in_sim_gtp_rxcharisk      : in    TBus04_SHCountMax;
p_in_sim_gtp_rxstatus       : in    TBus03_SHCountMax;
p_in_sim_gtp_rxelecidle     : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gtp_rxdisperr      : in    TBus04_SHCountMax;
p_in_sim_gtp_rxnotintable   : in    TBus04_SHCountMax;
p_in_sim_gtp_rxbyteisaligned: in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gtp_sim_rst           : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gtp_sim_clk           : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_out_dbgled                : out   THDDLed_SHCountMax;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end dsn_hdd;

architecture behavioral of dsn_hdd is

component mclk_gtp_wrap
generic(
G_SIM     : string:="OFF"
);
port
(
p_out_txn : out   std_logic_vector(1 downto 0);
p_out_txp : out   std_logic_vector(1 downto 0);
p_in_rxn  : in    std_logic_vector(1 downto 0);
p_in_rxp  : in    std_logic_vector(1 downto 0);
clkin     : in    std_logic;
clkout    : out   std_logic
);
end component;


signal i_cfg_adr_cnt                    : std_logic_vector(7 downto 0);

signal h_reg_ctrl_l                     : std_logic_vector(C_DSN_HDD_REG_CTRLL_LAST_BIT downto 0);
signal h_reg_tst0                       : std_logic_vector(C_DSN_HDD_REG_TST0_LAST_BIT downto 0);
signal h_reg_rambuf_adr                 : std_logic_vector(31 downto 0);
signal h_reg_rambuf_ctrl                : std_logic_vector(15 downto 0);

signal i_buf_rst                        : std_logic;

signal i_sata_gt_refclk                 : std_logic_vector(0 downto 0);
signal i_sh_ctrl                        : std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
signal i_sh_status                      : TUsrStatus;

signal sr_sh_busy                       : std_logic_vector(0 to 1);
signal i_sh_busy                        : std_logic;
signal i_sh_done                        : std_logic;
signal i_sh_ata_done                    : std_logic;
signal i_sh_irq_en                      : std_logic;
signal i_sh_irq_width                   : std_logic;
signal i_sh_irq_width_cnt               : std_logic_vector(3 downto 0);

type THDDBufChk_state is
(
S_IDLE,
S_CHEK_BUF,
S_CHEK_BUF_DONE
);
signal fsm_state_cs                     : THDDBufChk_state;

signal i_sh_cxd                         : std_logic_vector(15 downto 0);
signal i_sh_cxd_wr                      : std_logic;
signal i_sh_cxd_rd                      : std_logic;
signal i_sh_cxbuf_empty                 : std_logic;
signal i_sh_txd                         : std_logic_vector(31 downto 0);
signal i_sh_txd_rd                      : std_logic;
signal i_sh_txbuf_empty                 : std_logic;
signal i_sh_rxd                         : std_logic_vector(31 downto 0);
signal i_sh_rxd_wr                      : std_logic;
signal i_sh_rxbuf_full                  : std_logic;

signal i_sh_rxbuf_empty                 : std_logic;
signal sr_sh_rxbuf_empty                : std_logic_vector(0 downto 0);

signal i_sh_sim_gtp_txdata              : TBus32_SHCountMax;
signal i_sh_sim_gtp_txcharisk           : TBus04_SHCountMax;
signal i_sh_sim_gtp_txcomstart          : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
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

    h_reg_rambuf_adr<=(others=>'0');
    h_reg_rambuf_ctrl<=(others=>'0');

  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then

    if p_in_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_CTRL_L, i_cfg_adr_cnt'length) then h_reg_ctrl_l<=p_in_cfg_txdata(h_reg_ctrl_l'high downto 0);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_TST0, i_cfg_adr_cnt'length)   then h_reg_tst0<=p_in_cfg_txdata(h_reg_tst0'high downto 0);

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

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_TST0, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata(7 downto 0)<=h_reg_tst0;
                                                                                                   p_out_cfg_rxdata(8)<='0';
                                                                                                   p_out_cfg_rxdata(15 downto 9)<=(others=>'0');

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_ADR_L, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=h_reg_rambuf_adr(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_ADR_M, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=h_reg_rambuf_adr(31 downto 16);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_CTRL, i_cfg_adr_cnt'length)  then p_out_cfg_rxdata<=h_reg_rambuf_ctrl;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS_L, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(15 downto 0)<="000000000" & i_sh_status.dev_busy & i_sh_status.dev_err & i_sh_status.dev_rdy & i_sh_status.hdd_count(3 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS_M, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(15 downto 0)<=EXT(i_sh_status.ch_err, 8)&EXT(i_sh_status.ch_drdy, 8);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS_SATA0_L, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(15 downto 0)<=i_sh_status.SError(0)(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS_SATA0_M, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(15 downto 0)<=i_sh_status.SError(0)(31 downto 16);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS_SATA1_L, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(15 downto 0)<=i_sh_status.SError(1)(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_STATUS_SATA1_M, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(15 downto 0)<=i_sh_status.SError(1)(31 downto 16);

        end if;
    end if;
  end if;
end process;


i_sh_ctrl(C_USR_GCTRL_CLR_ERR_BIT)<=h_reg_ctrl_l(C_DSN_HDD_REG_CTRLL_CLR_ERR_BIT);
i_sh_ctrl(C_USR_GCTRL_CLR_BUF_BIT)<=h_reg_ctrl_l(C_DSN_HDD_REG_CTRLL_CLR_BUF_BIT);
i_sh_ctrl(C_USR_GCTRL_ATADONE_ACK_BIT)<=i_sh_ata_done;
i_sh_ctrl(C_USR_GCTRL_RESERV_BIT)<=h_reg_tst0(0);

--i_cfg_buf_ovflow_disable_det<=h_reg_ctrl_l(C_DSN_HDD_REG_CTRLL_OVERFLOW_DET_BIT);--//add 2010.10.03

--//Настройка/Управление RAM буфером
p_out_rbuf_cfg.mem_trn<=EXT(h_reg_rambuf_ctrl(C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_MSB_BIT downto C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_LSB_BIT), p_out_rbuf_cfg.mem_trn'length);
p_out_rbuf_cfg.mem_adr<=h_reg_rambuf_adr;
p_out_rbuf_cfg.dmacfg <=i_sh_status.dmacfg;
p_out_rbuf_cfg.bufrst <=h_reg_ctrl_l(C_DSN_HDD_REG_CTRLL_CLR_BUF_BIT);


--//Статусы модуля
p_out_hdd_rdy  <=i_sh_status.dev_rdy;
p_out_hdd_error<=i_sh_status.dev_err;
p_out_hdd_busy <=i_sh_busy;
p_out_hdd_irq  <=i_sh_irq_width;
p_out_hdd_done <=i_sh_done;


--//Запись командного пакета
i_sh_cxd_wr <=p_in_cfg_wd  when p_in_cfg_adr_fifo='1' and i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_CMDFIFO, i_cfg_adr_cnt'length) else '0';


--//############################
--//USE - ON (использовать в проекте)
--//############################
gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
--    tst_fms_cs_dly<=(others=>'0');
    p_out_tst<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

--    tst_fms_cs_dly<=tst_fms_cs;
    p_out_tst(0)<=tst_hdd_out(0);
    p_out_tst(1)<=tst_hdd_out(1);--//i_sata_module_rst(0);
  end if;
end process ltstout;

end generate gen_dbg_on;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_state_cs<= S_IDLE;
    i_sh_ata_done<='0';
    i_sh_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    if i_sh_ctrl(C_USR_GCTRL_CLR_ERR_BIT)='1' then
      fsm_state_cs<= S_IDLE;
      i_sh_ata_done<='0';
      i_sh_done<='0';

    else
        case fsm_state_cs is

          when S_IDLE =>

            if i_sh_cxd_wr='1' then
            --//Сброс флага выполнения предыдущей команды
              i_sh_done<='0';
            end if;

            if sr_sh_busy(0)='0' and sr_sh_busy(1)='1' then
            --//Ловим задний фронт сигнала АТА BUSY
              fsm_state_cs<= S_CHEK_BUF;
            end if;

          when S_CHEK_BUF =>
            --//Ждем пока из буферов уйдут все данные
            if sr_sh_rxbuf_empty(0)='1' and i_sh_txbuf_empty='1' then
              i_sh_ata_done<='1';--//Подтверждение завершения АТА команды
              i_sh_done<='1';

              fsm_state_cs<= S_CHEK_BUF_DONE;
            end if;

          when S_CHEK_BUF_DONE =>
            i_sh_ata_done<='0';
            fsm_state_cs<= S_IDLE;
        end case;

    end if;
  end if;
end process;


process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_sh_rxbuf_empty<=(others=>'1');

    sr_sh_busy<=(others=>'1');
    i_sh_busy<='1';

    i_sh_irq_en<='0';
    i_sh_irq_width<='0';
    i_sh_irq_width_cnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    sr_sh_rxbuf_empty(0)<=i_sh_rxbuf_empty;

    if i_sh_ctrl(C_USR_GCTRL_CLR_ERR_BIT)='1' then
      sr_sh_busy<=(others=>'0');
      i_sh_busy<='0';

      i_sh_irq_en<='0';
      i_sh_irq_width<='0';
      i_sh_irq_width_cnt<=(others=>'0');

    else
        --//Формируем сигнал BUSY
        sr_sh_busy<=i_sh_status.dev_busy & sr_sh_busy(0 to 0);

        if sr_sh_busy(0)='1' and sr_sh_busy(1)='0' then
          i_sh_busy<='1';
        elsif i_sh_ata_done='1' then
          i_sh_busy<='0';
        end if;


        --//Растягиваем импульcы генерации прерывания
        if i_sh_irq_en='0' and i_sh_ata_done='1' then
          i_sh_irq_en<='1';

        elsif i_sh_irq_en='1' then
          if i_sh_ata_done='1' then
            i_sh_irq_width<='1';
          elsif i_sh_irq_width_cnt(3)='1' then
            i_sh_irq_width<='0';
          end if;
        end if;

        if i_sh_irq_width='0' then
          i_sh_irq_width_cnt<=(others=>'0');
        else
          i_sh_irq_width_cnt<=i_sh_irq_width_cnt+1;
        end if;

    end if;
  end if;
end process;

m_cmdfifo : hdd_cmdfifo
port map
(
din         => p_in_cfg_txdata,
wr_en       => i_sh_cxd_wr,
wr_clk      => p_in_cfg_clk,

dout        => i_sh_cxd,
rd_en       => i_sh_cxd_rd,
rd_clk      => p_in_clk,

full        => open,
empty       => i_sh_cxbuf_empty,

--clk         => p_in_clk,
rst         => i_buf_rst
);

i_sh_cxd_rd<=not i_sh_cxbuf_empty;

m_txfifo : hdd_txfifo
port map
(
din         => p_in_hdd_txd,
wr_en       => p_in_hdd_txd_wr,
--wr_clk      => ,

dout        => i_sh_txd,
rd_en       => i_sh_txd_rd,
--rd_clk      => ,

full        => open,
almost_full => p_out_hdd_txbuf_full,
empty       => i_sh_txbuf_empty,
prog_full   => open,

clk         => p_in_clk,
rst         => i_buf_rst
);

m_rxfifo : hdd_rxfifo
port map
(
din         => i_sh_rxd,
wr_en       => i_sh_rxd_wr,
--wr_clk      => ,

dout        => p_out_hdd_rxd,
rd_en       => p_in_hdd_rxd_rd,
--rd_clk      => ,

full        => open,
almost_full => i_sh_rxbuf_full,
empty       => i_sh_rxbuf_empty,

clk         => p_in_clk,
rst         => i_buf_rst
);

i_buf_rst<=p_in_rst or i_sh_ctrl(C_USR_GCTRL_CLR_BUF_BIT);
p_out_hdd_rxbuf_empty<=i_sh_rxbuf_empty;


i_sata_gt_refclk(0)<=p_in_sata_refclk;

--//SATA
m_dsn_sata : dsn_raid_main
generic map
(
G_HDD_COUNT => G_HDD_COUNT,
G_GT_DBUS   => 16,
G_DBG       => G_DBG,
--G_DBGCS     => G_DBGCS,
G_SIM       => G_SIM
)
port map
(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              => p_out_sata_txn,
p_out_sata_txp              => p_out_sata_txp,
p_in_sata_rxn               => p_in_sata_rxn,
p_in_sata_rxp               => p_in_sata_rxp,

p_in_sata_refclk            => i_sata_gt_refclk,
p_out_sata_refclkout        => p_out_sata_refclkout,
p_out_sata_gt_plldet        => p_out_sata_gt_plldet,
p_out_sata_dcm_lock         => p_out_sata_dcm_lock,

--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl               => i_sh_ctrl,
p_out_usr_status            => i_sh_status,

--//cmdpkt
p_in_usr_cxd                => i_sh_cxd,
p_in_usr_cxd_wr             => i_sh_cxd_rd,

--//txfifo
p_in_usr_txd                => i_sh_txd,
p_out_usr_txd_rd            => i_sh_txd_rd,
p_in_usr_txbuf_empty        => i_sh_txbuf_empty,

--//rxfifo
p_out_usr_rxd               => i_sh_rxd,
p_out_usr_rxd_wr            => i_sh_rxd_wr,
p_in_usr_rxbuf_full         => i_sh_rxbuf_full,

--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gtp_txdata        => i_sh_sim_gtp_txdata,
p_out_sim_gtp_txcharisk     => i_sh_sim_gtp_txcharisk,
p_out_sim_gtp_txcomstart    => i_sh_sim_gtp_txcomstart,
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
p_out_tst                   => tst_hdd_out,
--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
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

gen_dbgled: for i in 0 to C_HDD_COUNT_MAX-1 generate
--p_out_dbgled(i).link<=i_sh_status.SError(i)(C_ASERR_DET_L_BIT);--//Уст-во обнаружено
p_out_dbgled(i).link<=i_sh_status.SError(i)(C_ASERR_DET_M_BIT);--//Уст-во обнаружено + соединение установлено
p_out_dbgled(i).rdy<=i_sh_status.ch_drdy(i);
p_out_dbgled(i).err<=i_sh_status.ch_err(i);
p_out_dbgled(i).spd<=i_sh_status.SError(i)(C_ASERR_SPD_L_BIT+1 downto C_ASERR_SPD_L_BIT);--//Скорость соединения 1/2/3 - SATA-I/II/III
end generate gen_dbgled;

p_out_sim_gtp_txdata        <= i_sh_sim_gtp_txdata;
p_out_sim_gtp_txcharisk     <= i_sh_sim_gtp_txcharisk;
p_out_sim_gtp_txcomstart    <= i_sh_sim_gtp_txcomstart;
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




--//############################
--//USE - OFF (выбросить из проекта)
--//############################
gen_use_off : if strcmp(G_MODULE_USE,"OFF") generate

p_out_tst<=(others=>'0');
tst_hdd_out<=(others=>'0');

m_sata_gt : mclk_gtp_wrap
generic map(
G_SIM => G_SIM
)
port map
(
p_out_txn => p_out_sata_txn,
p_out_txp => p_out_sata_txp,
p_in_rxn  => p_in_sata_rxn,
p_in_rxp  => p_in_sata_rxp,
clkin     => p_in_sata_refclk,
clkout    => i_sata_gt_refclk(0)
);

p_out_sata_refclkout<=i_sata_gt_refclk(0);
p_out_sata_gt_plldet<='1';
p_out_sata_dcm_lock<='1';

gen_satah: for i in 0 to C_HDD_COUNT_MAX-1 generate
p_out_sim_gtp_txdata(i)    <=(others=>'0');
p_out_sim_gtp_txcharisk(i) <=(others=>'0');
p_out_sim_gtp_txcomstart(i)<='0';
p_out_gtp_sim_rst(i)       <='0';
p_out_gtp_sim_clk(i)       <='0';

i_sh_status.ch_busy(i)<='0';
i_sh_status.ch_drdy(i)<='0';
i_sh_status.ch_err(i)<='0';
i_sh_status.SError(i)<=(others=>'0');
i_sh_status.ch_usr(i)<=(others=>'0');

p_out_dbgled(i).link<='0';
p_out_dbgled(i).rdy<='0';
p_out_dbgled(i).err<='0';

end generate gen_satah;

i_sh_status.dev_busy<='0';
i_sh_status.dev_rdy <='0';
i_sh_status.dev_err <='0';
i_sh_status.usr <=(others=>'0');

p_out_hdd_txbuf_full<=i_sh_cxd_wr;

process(p_in_rst,i_sata_gt_refclk(0))
begin
  if p_in_rst='1' then
    i_sh_rxd<=(others=>'0');

  elsif i_sata_gt_refclk(0)'event and i_sata_gt_refclk(0)='1' then
    i_sh_rxd<=EXT(p_in_cfg_txdata, i_sh_rxd'length);
  end if;
end process;

p_out_hdd_rxd <=i_sh_rxd;
p_out_hdd_rxbuf_empty<=i_sh_cxd_wr;

p_out_hdd_txbuf_full<=i_sh_cxd_wr;

i_sh_ata_done<='0';
i_sh_done<='0';


end generate gen_use_off;

--END MAIN
end behavioral;
