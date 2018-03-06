-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 09.07.2015 13:42:09
-- Module Name : pcie_usr_app.vhd
--
-- Description : pci-express user application
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.pcie_pkg.all;
use work.prj_def.all;
use work.prj_cfg.all;

entity pcie_usr_app is
generic(
G_SIM : string := "OFF";
G_DBG : string := "OFF"
);
port(
-------------------------------------------------------
--USR Port
-------------------------------------------------------
p_out_hclk      : out   std_logic;
p_out_gctrl     : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);--global ctrl

--CTRL user devices
p_out_dev_ctrl  : out   TDevCtrl;
p_out_dev_di    : out   std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);--DEV<-HOST
p_in_dev_do     : in    std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);--DEV->HOST
p_out_dev_wr    : out   std_logic;
p_out_dev_rd    : out   std_logic;
p_in_dev_status : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto C_HREG_DEV_STATUS_FST_BIT);
p_in_dev_irq    : in    std_logic_vector((C_HIRQ_COUNT - 1) downto C_HIRQ_FST_BIT);
p_in_dev_opt    : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto C_HDEV_OPTIN_FST_BIT);
p_out_dev_opt   : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto C_HDEV_OPTOUT_FST_BIT);

--DBG
p_out_tst       : out   std_logic_vector(127 downto 0);
p_in_tst        : in    std_logic_vector(127 downto 0);

--------------------------------------
--PCIE_Rx/Tx  Port
--------------------------------------
p_in_pcie_prm  : in  TPCIE_cfgprm;

--Target mode
p_in_reg_adr   : in  std_logic_vector(7 downto 0);
p_out_reg_do   : out std_logic_vector(31 downto 0);
p_in_reg_di    : in  std_logic_vector(31 downto 0);
p_in_reg_wr    : in  std_logic;
p_in_reg_rd    : in  std_logic;

--Master mode
--(PC->FPGA)
--p_in_txbuf_dbe   : in    std_logic_vector(3 downto 0);
p_in_txbuf_di    : in    std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_in_txbuf_wr    : in    std_logic;
p_in_txbuf_last  : in    std_logic;
p_out_txbuf_full : out   std_logic;

--(PC<-FPGA)
--p_in_rxbuf_dbe    : in    std_logic_vector(3 downto 0);
p_out_rxbuf_do    : out   std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_in_rxbuf_rd     : in    std_logic;
p_in_rxbuf_last   : in    std_logic;
p_out_rxbuf_empty : out   std_logic;

--DMATRN
p_out_dmatrn_init  : out   std_logic;
p_out_dma_prm      : out   TPCIE_dmaprm;

--DMA MEMWR (PC<-FPGA)
p_out_dma_mwr_en   : out   std_logic;
p_in_dma_mwr_done  : in    std_logic;

--DMA MEMRD (PC->FPGA)
p_out_dma_mrd_en      : out   std_logic;
p_in_dma_mrd_done     : in    std_logic;
p_in_dma_mrd_rcv_size : in    std_logic_vector(31 downto 0);
p_in_dma_mrd_rcv_err  : in    std_logic;

--IRQ
p_out_irq_clr : out   std_logic;
p_out_irq_set : out   std_logic;
p_in_irq_ack  : in    std_logic;

--System
p_in_clk   : in    std_logic;
p_in_rst_n : in    std_logic
);
end entity pcie_usr_app;

architecture behavioral of pcie_usr_app is

component bram_dma_params
port(
addra : in   std_logic_vector(11 downto 0);
dina  : in   std_logic_vector(31 downto 0);
douta : out  std_logic_vector(31 downto 0);
ena   : in   std_logic;
wea   : in   std_logic_vector(0 downto 0);
clka  : in   std_logic;

addrb : in   std_logic_vector(11 downto 0);
dinb  : in   std_logic_vector(31 downto 0);
doutb : out  std_logic_vector(31 downto 0);
enb   : in   std_logic;
web   : in   std_logic_vector(0 downto 0);
clkb  : in   std_logic
);
end component;

type TUsrReg is record
firmware : std_logic_vector(C_HREG_FRMWARE_LAST_BIT downto 0);
ctrl     : std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);
dev_ctrl : std_logic_vector(C_HREG_DMA_CTRL_LAST_BIT downto 0);
mem_adr  : std_logic_vector(C_HREG_MEM_ADR_LAST_BIT downto 0);
mem_ctrl : std_logic_vector(C_HREG_MEM_CTRL_LAST_BIT downto 0);
irq      : std_logic_vector(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT);
pcie     : std_logic_vector(C_HREG_PCIE_EN_TESTD_GEN_BIT downto C_HREG_PCIE_SPEED_TESTING_BIT);
tst0     : std_logic_vector(31 downto 0);
tst1     : std_logic_vector(31 downto 0);

fg_ctrl  : std_logic_vector(C_FG_REG_CTRL_LAST_BIT downto 0);
fg_data  : std_logic_vector(31 downto 0);
end record;


signal i_reg_rd           : std_logic;
signal i_reg_bar          : std_logic;
signal i_reg_adr          : unsigned(4 downto 0);
signal i_reg              : TUsrReg;

signal i_dev_reg          : TDevRegCtrl;
signal i_cfg_dadr         : unsigned((C_HREG_CFG_CTRL_ADR_M_BIT - C_HREG_CFG_CTRL_ADR_L_BIT) downto 0);
signal i_cfg_dreg         : unsigned((C_HREG_CFG_CTRL_REG_M_BIT - C_HREG_CFG_CTRL_REG_L_BIT) downto 0);
signal i_tmr_num          : unsigned((C_TMR_REG_CTRL_NUM_M_WBIT - C_TMR_REG_CTRL_NUM_L_WBIT) downto 0);

signal i_fg_rddone                 : std_logic;

signal i_hdev_adr                  : std_logic_vector(C_HREG_DMA_CTRL_ADR_M_BIT
                                                       - C_HREG_DMA_CTRL_ADR_L_BIT downto 0);

signal i_dmabuf_num                : std_logic_vector(C_HREG_DMA_CTRL_DMABUF_M_BIT
                                                       - C_HREG_DMA_CTRL_DMABUF_L_BIT downto 0);

signal i_dmabuf_count              : std_logic_vector(C_HREG_DMA_CTRL_DMABUF_COUNT_M_BIT
                                                      - C_HREG_DMA_CTRL_DMABUF_COUNT_L_BIT downto 0);
signal i_usr_grst                  : std_logic;

signal i_dma_ctrl                  : std_logic_vector(C_HREG_DMA_CTRL_LAST_BIT downto C_HREG_DMA_CTRL_DRDY_BIT);
signal i_dma_start                 : std_logic;--DEV_CTRL(DMA_START) - rising_edge
signal sr_dma_start                : std_logic;
signal i_dmaprm                    : TPCIE_dmaprm;
signal i_dmatrn_init               : std_logic;
signal i_dmatrn_start              : std_logic;
signal i_dmatrn_work               : std_logic;
signal i_dmatrn_done               : std_logic;
signal i_dmatrn_mrd_done           : std_logic;
signal i_dmatrn_mwr_done           : std_logic;
signal sr_mrd_done                 : std_logic;
signal i_mrd_done                  : std_logic;
signal sr_mwr_done                 : std_logic;
signal i_mwr_done                  : std_logic;
signal sr_dmatrn_done              : std_logic;
signal i_dmatrn_mem_done           : std_logic_vector(1 downto 0);
signal i_dma_work                  : std_logic;
signal sr_dma_work                 : std_logic;
signal i_dma_irq                   : std_logic;

signal i_host_dmaprm_adr           : std_logic_vector(11 downto 0);
signal i_host_dmaprm_di            : std_logic_vector(31 downto 0);
signal i_host_dmaprm_do            : std_logic_vector(31 downto 0);
signal i_host_dmaprm_wr            : std_logic_vector(0 downto 0);

signal i_hw_dmaprm_cnt             : unsigned(1 downto 0);
signal i_hw_dmaprm_adr             : std_logic_vector(11 downto 0);
signal i_hw_dmaprm_do              : std_logic_vector(31 downto 0);
signal i_hw_dmaprm_rd              : std_logic_vector(0 downto 0);
signal sr_hw_dmaprm_cnt            : std_logic_vector(1 downto 0);
signal sr_hw_dmaprm_rd             : std_logic_vector(0 downto 0);

signal i_dmabuf_num_cnt            : unsigned(i_dmabuf_num'range);
signal i_dmabuf_done_cnt           : unsigned(i_dmabuf_count'range);

signal sr_memtrn_done              : std_logic_vector(0 to 2);
signal i_memtrn_done               : std_logic;

signal i_mrd_rcv_size_ok           : std_logic;
signal i_mrd_rcv_last_dw           : std_logic;

signal i_irq_status_clr            : std_logic;
signal i_irq_clr                   : std_logic;
signal i_irq_en                    : std_logic_vector(C_HIRQ_COUNT - 1 downto 0);
signal i_irq_set                   : std_logic_vector(C_HIRQ_COUNT - 1 downto 0);
signal i_irq_dev                   : std_logic_vector(C_HIRQ_COUNT - 1 downto 0);
Type TSRIrqSet is array (0 to C_HIRQ_COUNT - 1) of std_logic_vector(0 to 2);
signal sr_irq_set                  : TSRIrqSet;
signal i_irq_status                : std_logic_vector(C_HIRQ_COUNT - 1 downto 0) := (others => '0');
signal i_irq_req                   : std_logic_vector(C_HIRQ_COUNT - 1 downto 0) := (others => '0');

signal i_dev_drdy                  : std_logic;

signal i_mem_adr_cnt               : unsigned(31 - log2(C_HDEV_DWIDTH / 8) downto 0) := (others => '0');

constant CI_TESTDATA_WIDTH : integer := 32;
signal tst_mem_dcnt,tst_mem_dcnt_swap : unsigned(C_HDEV_DWIDTH - 1 downto 0);



begin --architecture behavioral


p_out_hclk <= p_in_clk;

p_out_dmatrn_init <= i_dmatrn_init;

--MEMORY WRITE - DMATRN_WR (PC<-FPGA)
p_out_dma_mwr_en  <= i_dmatrn_work and i_reg.dev_ctrl(C_HREG_DMA_CTRL_DMA_DIR_BIT);

--MEMORY READ - DMATRN_RD (PC->FPGA)
p_out_dma_mrd_en  <= i_dmatrn_work and not i_reg.dev_ctrl(C_HREG_DMA_CTRL_DMA_DIR_BIT);

p_out_dma_prm <= i_dmaprm;

--p_out_rd_metering       <= '1';


----------------------------------------------------------------------------------------------
--User registor:
----------------------------------------------------------------------------------------------
i_dmabuf_num   <= i_reg.dev_ctrl(C_HREG_DMA_CTRL_DMABUF_M_BIT downto C_HREG_DMA_CTRL_DMABUF_L_BIT);
i_dmabuf_count <= i_reg.dev_ctrl(C_HREG_DMA_CTRL_DMABUF_COUNT_M_BIT downto C_HREG_DMA_CTRL_DMABUF_COUNT_L_BIT);
i_hdev_adr     <= i_reg.dev_ctrl(C_HREG_DMA_CTRL_ADR_M_BIT downto C_HREG_DMA_CTRL_ADR_L_BIT);

i_reg.firmware <= std_logic_vector(TO_UNSIGNED(C_FPGA_FIRMWARE_VERSION, i_reg.firmware'length));

--BAR detector
i_reg_bar <= p_in_reg_adr(7);--x80 - Register Space
i_reg_adr <= UNSIGNED(p_in_reg_adr(6 downto 2));

--Reg Write:
wr : process(p_in_clk)
  variable dma_start : std_logic;
  variable irq_clr,irq_status_clr : std_logic;
  variable dev_drdy : std_logic;
  variable dmaprm_wr : std_logic;
  variable usr_grst : std_logic;
  variable fg_rddone_edge : std_logic;
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0') then
    i_reg.ctrl <= (others => '0');
    i_reg.dev_ctrl <= (others => '0');
    i_reg.pcie <= (others => '0');
    i_reg.mem_adr <= (others => '0');
    i_reg.mem_ctrl <= std_logic_vector(TO_UNSIGNED(16#4040#, i_reg.mem_ctrl'length));
    i_reg.irq <= (others => '0');
    i_reg.tst0 <= (others => '0');
    i_reg.tst1 <= (others => '1');
    i_reg.fg_ctrl <= (others => '0');
    i_reg.fg_data <= (others => '0');

      dma_start := '0';
    i_dma_start <= '0';
    sr_dma_start <= '0';

      dev_drdy := '0';
    i_dev_drdy <= '0';
      irq_clr := '0';   irq_status_clr := '0';
    i_irq_clr <= '0'; i_irq_status_clr <= '0';
    i_irq_en <= (others => '0');

    i_host_dmaprm_di <= (others => '0');
    i_host_dmaprm_wr <= (others => '0');
      dmaprm_wr := '0';

      usr_grst := '0';
    i_usr_grst <= '0';

      fg_rddone_edge := '0';
    i_fg_rddone <= '0';

    i_cfg_dadr <= (others => '0');
    i_cfg_dreg <= (others => '0');
    i_tmr_num <= (others => '0');

    for i in 0 to (i_dev_reg.eth'length - 1) loop
    for y in 0 to (i_dev_reg.eth(0).mac.dst'length - 1) loop
    i_dev_reg.eth(i).mac.dst(y) <= (others => '0');
    i_dev_reg.eth(i).mac.src(y) <= (others => '0');
    end loop;
    end loop;

    i_dev_reg.swt.ctrl <= (others => '0');
    i_dev_reg.swt.dbg <= (others => '0');
    for i in 0 to (i_dev_reg.swt.frr.eth2h'length - 1) loop
    i_dev_reg.swt.frr.eth2h(i) <= (others => '0');
    end loop;
    for i in 0 to (i_dev_reg.swt.frr.eth2fg'length - 1) loop
    i_dev_reg.swt.frr.eth2fg(i) <= (others => '0');
    end loop;

    for i in 0 to (i_dev_reg.tmr.en'length - 1) loop
    i_dev_reg.tmr.en(i) <= '0';
    i_dev_reg.tmr.data(i) <= (others => '0');
    end loop;

    i_dev_reg.fg.dbg <= (others => '0');
    for i in 0 to (i_dev_reg.fg.prm.ch'length - 1) loop
    i_dev_reg.fg.idle(i) <= '0';
    i_dev_reg.fg.prm.ch(i).fr.act.pixcount <= (others => '0');
    i_dev_reg.fg.prm.ch(i).fr.act.rowcount <= (others => '0');
    i_dev_reg.fg.prm.ch(i).fr.skp.pixcount <= (others => '0');
    i_dev_reg.fg.prm.ch(i).fr.skp.rowcount <= (others => '0');
    i_dev_reg.fg.prm.ch(i).mirror.pix <= '0';
    i_dev_reg.fg.prm.ch(i).mirror.row <= '0';
    i_dev_reg.fg.prm.ch(i).steprd <= (others => '0');
    end loop;
    i_dev_reg.fg.prm.memwr_trnlen <= (others => '0');
    i_dev_reg.fg.prm.memrd_trnlen <= (others => '0');

  else

      dmaprm_wr := '0';
      dev_drdy := '0';
      dma_start := '0';
      irq_clr := '0'; irq_status_clr := '0';
      fg_rddone_edge := '0';

      usr_grst := '0';

    if (p_in_reg_wr = '1') then
      if (i_reg_bar = '1') then
      ----------------------------------------------
      --Register Space:
      ----------------------------------------------
        if (i_reg_adr = TO_UNSIGNED(C_HREG_CTRL, i_reg_adr'length))  then
          i_reg.ctrl <= p_in_reg_di(i_reg.ctrl'high downto 0);
            usr_grst := p_in_reg_di(C_HREG_CTRL_RST_ALL_BIT);
            fg_rddone_edge := p_in_reg_di(C_HREG_CTRL_FG_RDDONE_BIT);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_DMAPRM_ADR, i_reg_adr'length)) then --Adress(Byte)
          i_host_dmaprm_di <= p_in_reg_di;
            dmaprm_wr := '1';

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_DMAPRM_LEN, i_reg_adr'length)) then --Size(Byte)
          i_host_dmaprm_di <= p_in_reg_di;
            dmaprm_wr := '1';

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_DMA_CTRL, i_reg_adr'length)) then
          i_reg.dev_ctrl <= p_in_reg_di(i_reg.dev_ctrl'high downto 0);
            dma_start := p_in_reg_di(C_HREG_DMA_CTRL_DMA_START_BIT);
            dev_drdy := p_in_reg_di(C_HREG_DMA_CTRL_DRDY_BIT);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_PCIE, i_reg_adr'length)) then
            i_reg.pcie <= p_in_reg_di(C_HREG_PCIE_EN_TESTD_GEN_BIT downto C_HREG_PCIE_SPEED_TESTING_BIT);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_MEM_ADR, i_reg_adr'length)) then
          i_reg.mem_adr <= p_in_reg_di(i_reg.mem_adr'high downto 0);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_MEM_CTRL, i_reg_adr'length)) then
          i_reg.mem_ctrl <= p_in_reg_di(i_reg.mem_ctrl'high downto 0);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_IRQ, i_reg_adr'length)) then
          i_reg.irq <= p_in_reg_di(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT);
            irq_clr := p_in_reg_di(C_HREG_IRQ_CLR_WBIT);
            irq_status_clr := p_in_reg_di(C_HREG_IRQ_STATUS_CLR_WBIT);

            for i in 0 to (C_HIRQ_COUNT - 1) loop
              if (UNSIGNED(p_in_reg_di(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT)) = i) then
                if (p_in_reg_di(C_HREG_IRQ_STATUS_CLR_WBIT) = '0' and p_in_reg_di(C_HREG_IRQ_CLR_WBIT) = '0') then
                  i_irq_en(i) <= p_in_reg_di(C_HREG_IRQ_EN_WBIT);
                end if;
              end if;
            end loop;

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_TST0, i_reg_adr'length)) then i_reg.tst0 <= p_in_reg_di;
        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_TST1, i_reg_adr'length)) then i_reg.tst1 <= p_in_reg_di;



        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_CFG_CTRL, i_reg_adr'length)) then
            i_cfg_dadr <= UNSIGNED(p_in_reg_di(C_HREG_CFG_CTRL_ADR_M_BIT downto C_HREG_CFG_CTRL_ADR_L_BIT));
            i_cfg_dreg <= UNSIGNED(p_in_reg_di(C_HREG_CFG_CTRL_REG_M_BIT downto C_HREG_CFG_CTRL_REG_L_BIT));

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_CFG_DATA, i_reg_adr'length)) then

            --####################
            --######   FG   ######
            --####################
            if (i_cfg_dadr = TO_UNSIGNED(C_CFGDEV_FG, i_cfg_dadr'length)) then

                if (i_cfg_dreg = TO_UNSIGNED(C_FG_REG_DATA, i_cfg_dreg'length)) then
                    i_reg.fg_data <= p_in_reg_di;

                elsif (i_cfg_dreg = TO_UNSIGNED(C_FG_REG_DBG, i_cfg_dreg'length)) then
                    i_dev_reg.fg.dbg <= p_in_reg_di(i_dev_reg.fg.dbg'range);

                elsif (i_cfg_dreg = TO_UNSIGNED(C_FG_REG_MEM_CTRL, i_cfg_dreg'length)) then
                    i_dev_reg.fg.prm.memwr_trnlen <= p_in_reg_di(C_HREG_MEM_CTRL_TRNWR_M_BIT downto C_HREG_MEM_CTRL_TRNWR_L_BIT);
                    i_dev_reg.fg.prm.memrd_trnlen <= p_in_reg_di(C_HREG_MEM_CTRL_TRNRD_M_BIT downto C_HREG_MEM_CTRL_TRNRD_L_BIT);

                elsif (i_cfg_dreg = TO_UNSIGNED(C_FG_REG_CTRL, i_cfg_dreg'length)) then

                    i_reg.fg_ctrl <= p_in_reg_di(i_reg.fg_ctrl'range);

                    for ch in 0 to (C_FG_VCH_COUNT - 1) loop
                      if (ch = UNSIGNED(p_in_reg_di(C_FG_REG_CTRL_VCH_M_BIT downto C_FG_REG_CTRL_VCH_L_BIT))) then
                        i_dev_reg.fg.idle(ch) <= p_in_reg_di(C_FG_REG_CTRL_SET_IDLE_BIT);
                      end if;
                    end loop;

                    if (p_in_reg_di(C_FG_REG_CTRL_DIR_BIT) = C_FG_REG_CTRL_DIR_WR) then

                        for ch in 0 to (C_FG_VCH_COUNT - 1) loop
                          if (ch = UNSIGNED(p_in_reg_di(C_FG_REG_CTRL_VCH_M_BIT downto C_FG_REG_CTRL_VCH_L_BIT))) then

                            if (UNSIGNED(p_in_reg_di(C_FG_REG_CTRL_PRM_M_BIT downto C_FG_REG_CTRL_PRM_L_BIT))
                                  = TO_UNSIGNED(C_FG_PRM_ZONE_ACTIVE, (C_FG_REG_CTRL_PRM_M_BIT - C_FG_REG_CTRL_PRM_L_BIT)) ) then

                              i_dev_reg.fg.prm.ch(ch).fr.act.pixcount <= UNSIGNED(i_reg.fg_data(C_FG_PIX_M downto C_FG_PIX_L));
                              i_dev_reg.fg.prm.ch(ch).fr.act.rowcount <= UNSIGNED(i_reg.fg_data(C_FG_ROW_M downto C_FG_ROW_L));

                            elsif (UNSIGNED(p_in_reg_di(C_FG_REG_CTRL_PRM_M_BIT downto C_FG_REG_CTRL_PRM_L_BIT))
                                  = TO_UNSIGNED(C_FG_PRM_ZONE_SKIP, (C_FG_REG_CTRL_PRM_M_BIT - C_FG_REG_CTRL_PRM_L_BIT)) ) then

                              i_dev_reg.fg.prm.ch(ch).fr.skp.pixcount <= UNSIGNED(i_reg.fg_data(C_FG_PIX_M downto C_FG_PIX_L));
                              i_dev_reg.fg.prm.ch(ch).fr.skp.rowcount <= UNSIGNED(i_reg.fg_data(C_FG_ROW_M downto C_FG_ROW_L));

                            elsif (UNSIGNED(p_in_reg_di(C_FG_REG_CTRL_PRM_M_BIT downto C_FG_REG_CTRL_PRM_L_BIT))
                                  = TO_UNSIGNED(C_FG_PRM_OPTIONS, (C_FG_REG_CTRL_PRM_M_BIT - C_FG_REG_CTRL_PRM_L_BIT)) ) then

                              i_dev_reg.fg.prm.ch(ch).mirror.pix <= i_reg.fg_data(C_FG_PRM_OPTIONS_MIRX_BIT);
                              i_dev_reg.fg.prm.ch(ch).mirror.row <= i_reg.fg_data(C_FG_PRM_OPTIONS_MIRY_BIT);

                            elsif (UNSIGNED(p_in_reg_di(C_FG_REG_CTRL_PRM_M_BIT downto C_FG_REG_CTRL_PRM_L_BIT))
                                  = TO_UNSIGNED(C_FG_PRM_STEP_RD_LINE, (C_FG_REG_CTRL_PRM_M_BIT - C_FG_REG_CTRL_PRM_L_BIT)) ) then

                              i_dev_reg.fg.prm.ch(ch).steprd <= UNSIGNED(i_reg.fg_data(i_dev_reg.fg.prm.ch(ch).steprd'range));

                            end if;
                          end if;
                        end loop;

                    end if;
                end if;--fg reg


            --####################
            --######   ETH  ######
            --####################
            elsif (i_cfg_dadr = TO_UNSIGNED(C_CFGDEV_ETH, i_cfg_dadr'length)) then

                if (i_cfg_dreg = TO_UNSIGNED(C_ETH_REG_MAC_PATRN0, i_cfg_dreg'length)) then
                    i_dev_reg.eth(0).mac.dst(0) <= p_in_reg_di((8 * 1) - 1 downto (8 * 0));
                    i_dev_reg.eth(0).mac.dst(1) <= p_in_reg_di((8 * 2) - 1 downto (8 * 1));
                    i_dev_reg.eth(0).mac.dst(2) <= p_in_reg_di((8 * 3) - 1 downto (8 * 2));
                    i_dev_reg.eth(0).mac.dst(3) <= p_in_reg_di((8 * 4) - 1 downto (8 * 3));

                elsif (i_cfg_dreg = TO_UNSIGNED(C_ETH_REG_MAC_PATRN1, i_cfg_dreg'length)) then
                    i_dev_reg.eth(0).mac.dst(4) <= p_in_reg_di((8 * 1) - 1 downto (8 * 0));
                    i_dev_reg.eth(0).mac.dst(5) <= p_in_reg_di((8 * 2) - 1 downto (8 * 1));
                    i_dev_reg.eth(0).mac.src(0) <= p_in_reg_di((8 * 3) - 1 downto (8 * 2));
                    i_dev_reg.eth(0).mac.src(1) <= p_in_reg_di((8 * 4) - 1 downto (8 * 3));

                elsif (i_cfg_dreg = TO_UNSIGNED(C_ETH_REG_MAC_PATRN2, i_cfg_dreg'length)) then
                    i_dev_reg.eth(0).mac.src(2) <= p_in_reg_di((8 * 1) - 1 downto (8 * 0));
                    i_dev_reg.eth(0).mac.src(3) <= p_in_reg_di((8 * 2) - 1 downto (8 * 1));
                    i_dev_reg.eth(0).mac.src(4) <= p_in_reg_di((8 * 3) - 1 downto (8 * 2));
                    i_dev_reg.eth(0).mac.src(5) <= p_in_reg_di((8 * 4) - 1 downto (8 * 3));

                end if;--eth reg


            --####################
            --######   SWT  ######
            --####################
            elsif (i_cfg_dadr = TO_UNSIGNED(C_CFGDEV_SWT, i_cfg_dadr'length)) then

                if (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_CTRL, i_cfg_dreg'length)) then
                    i_dev_reg.swt.ctrl <= p_in_reg_di(i_dev_reg.swt.ctrl'range);

                elsif (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_DBG, i_cfg_dreg'length)) then
                    i_dev_reg.swt.dbg <= p_in_reg_di(i_dev_reg.swt.dbg'range);

                --filter pkt: ETH<->HOST
                elsif (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_ETH2HOST_FRR0, i_cfg_dreg'length)) then
                    i_dev_reg.swt.frr.eth2h(0) <= p_in_reg_di((8 * 1) - 1 downto (8 * 0));
                    i_dev_reg.swt.frr.eth2h(1) <= p_in_reg_di((8 * 2) - 1 downto (8 * 1));
                    i_dev_reg.swt.frr.eth2h(2) <= p_in_reg_di((8 * 3) - 1 downto (8 * 2));
                    i_dev_reg.swt.frr.eth2h(3) <= p_in_reg_di((8 * 4) - 1 downto (8 * 3));

                elsif (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_ETH2HOST_FRR1, i_cfg_dreg'length)) then
                    i_dev_reg.swt.frr.eth2h(4) <= p_in_reg_di((8 * 1) - 1 downto (8 * 0));
                    i_dev_reg.swt.frr.eth2h(5) <= p_in_reg_di((8 * 2) - 1 downto (8 * 1));
                    i_dev_reg.swt.frr.eth2h(6) <= p_in_reg_di((8 * 3) - 1 downto (8 * 2));
                    i_dev_reg.swt.frr.eth2h(7) <= p_in_reg_di((8 * 4) - 1 downto (8 * 3));

                --filter pkt: ETH->FG
                elsif (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_ETH2FG_FRR0, i_cfg_dreg'length)) then
                    i_dev_reg.swt.frr.eth2fg(0) <= p_in_reg_di((8 * 1) - 1 downto (8 * 0));
                    i_dev_reg.swt.frr.eth2fg(1) <= p_in_reg_di((8 * 2) - 1 downto (8 * 1));
                    i_dev_reg.swt.frr.eth2fg(2) <= p_in_reg_di((8 * 3) - 1 downto (8 * 2));
                    i_dev_reg.swt.frr.eth2fg(3) <= p_in_reg_di((8 * 4) - 1 downto (8 * 3));

                elsif (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_ETH2FG_FRR1, i_cfg_dreg'length)) then
                    i_dev_reg.swt.frr.eth2fg(4) <= p_in_reg_di((8 * 1) - 1 downto (8 * 0));
                    i_dev_reg.swt.frr.eth2fg(5) <= p_in_reg_di((8 * 2) - 1 downto (8 * 1));
                    i_dev_reg.swt.frr.eth2fg(6) <= p_in_reg_di((8 * 3) - 1 downto (8 * 2));
                    i_dev_reg.swt.frr.eth2fg(7) <= p_in_reg_di((8 * 4) - 1 downto (8 * 3));

                end if;--swt reg

            --####################
            --######   TMR  ######
            --####################
            elsif (i_cfg_dadr = TO_UNSIGNED(C_CFGDEV_TMR, i_cfg_dadr'length)) then

                if (i_cfg_dreg = TO_UNSIGNED(C_TMR_REG_CTRL, i_cfg_dreg'length)) then

                    i_tmr_num <= UNSIGNED(p_in_reg_di(C_TMR_REG_CTRL_NUM_M_WBIT downto C_TMR_REG_CTRL_NUM_L_WBIT));

                    for i in 0 to (C_TMR_COUNT - 1) loop
                      if (i = UNSIGNED(p_in_reg_di(C_TMR_REG_CTRL_NUM_M_WBIT downto C_TMR_REG_CTRL_NUM_L_WBIT))) then
                        i_dev_reg.tmr.en(i) <= p_in_reg_di(C_TMR_REG_CTRL_EN_WBIT);
                      end if;
                    end loop;

                elsif (i_cfg_dreg = TO_UNSIGNED(C_TMR_REG_CMP, i_cfg_dreg'length)) then
                    for i in 0 to (C_TMR_COUNT - 1) loop
                      if (i = i_tmr_num) then
                        i_dev_reg.tmr.data(i) <= UNSIGNED(p_in_reg_di);
                      end if;
                    end loop;

                end if;--tmr reg
            end if;--cfg_dadr

        end if; --adr
      end if; --bar
    end if; --wr

    i_host_dmaprm_wr(0) <= dmaprm_wr;
    i_dev_drdy <= dev_drdy;
    i_dma_start <= dma_start;
    i_irq_clr <= irq_clr; i_irq_status_clr <= irq_status_clr;
    i_fg_rddone <= fg_rddone_edge;
    i_usr_grst <= usr_grst;

    sr_dma_start <= i_dma_start;

  end if; --rst
end if; --clk
end process;--Reg Write

--Reg Read:
rd : process(p_in_clk)
  variable txd : std_logic_vector(p_out_reg_do'range);
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0') then
    txd := (others => '0');
    p_out_reg_do <= (others => '0');
    i_reg_rd <= '0';

  else

    txd := (others => '0');

    i_reg_rd <= p_in_reg_rd;

    if (i_reg_rd = '1') then
      if (i_reg_bar = '1') then
      ----------------------------------------------
      --Register Space:
      ----------------------------------------------
        if (i_reg_adr = TO_UNSIGNED(C_HREG_FIRMWARE, i_reg_adr'length)) then
            txd := std_logic_vector(RESIZE(UNSIGNED(i_reg.firmware), txd'length));

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_CTRL, i_reg_adr'length)) then
            txd := std_logic_vector(RESIZE(UNSIGNED(i_reg.ctrl), txd'length));

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_DMAPRM_ADR, i_reg_adr'length)) then
            txd := std_logic_vector(RESIZE(UNSIGNED(i_host_dmaprm_do), txd'length));

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_DMAPRM_LEN, i_reg_adr'length)) then
            txd := std_logic_vector(RESIZE(UNSIGNED(i_host_dmaprm_do), txd'length));

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_DMA_CTRL, i_reg_adr'length)) then
            txd(C_HREG_DMA_CTRL_LAST_BIT downto C_HREG_DMA_CTRL_DMA_DIR_BIT)
                := i_reg.dev_ctrl(C_HREG_DMA_CTRL_LAST_BIT downto C_HREG_DMA_CTRL_DMA_DIR_BIT);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_PCIE, i_reg_adr'length)) then
            txd(C_HREG_PCIE_NEG_LINK_M_RBIT downto C_HREG_PCIE_NEG_LINK_L_RBIT)
                := p_in_pcie_prm.link_width(5 downto 0);

            txd(C_HREG_PCIE_NEG_MAX_PAYLOAD_M_RBIT downto C_HREG_PCIE_NEG_MAX_PAYLOAD_L_RBIT)
                := p_in_pcie_prm.max_payload(2 downto 0);

            txd(C_HREG_PCIE_NEG_MAX_RD_REQ_M_RBIT downto C_HREG_PCIE_NEG_MAX_RD_REQ_L_RBIT)
                := p_in_pcie_prm.max_rd_req(2 downto 0);

            txd(C_HREG_PCIE_MASTER_EN_RBIT) := p_in_pcie_prm.master_en(0);

            txd(C_HREG_PCIE_SPEED_TESTING_BIT) := i_reg.pcie(C_HREG_PCIE_SPEED_TESTING_BIT);
            txd(C_HREG_PCIE_EN_TESTD_GEN_BIT) := i_reg.pcie(C_HREG_PCIE_EN_TESTD_GEN_BIT);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_MEM_ADR, i_reg_adr'length)) then
            txd := std_logic_vector(RESIZE(UNSIGNED(i_reg.mem_adr), txd'length));

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_MEM_CTRL, i_reg_adr'length)) then
            txd := std_logic_vector(RESIZE(UNSIGNED(i_reg.mem_ctrl), txd'length));

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_IRQ, i_reg_adr'length)) then
            for i in 0 to (C_HIRQ_COUNT - 1) loop
              txd(i) := i_irq_status(i);
            end loop;

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_DEV_STATUS, i_reg_adr'length)) then
            txd(C_HREG_DEV_STATUS_DMA_BUSY_BIT) := i_dma_work;
            txd(C_HREG_DEV_STATUS_LAST_BIT downto (C_HREG_DEV_STATUS_DMA_BUSY_BIT + 1)) := p_in_dev_status;

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_FG_FRMRK, i_reg_adr'length)) then
          txd := p_in_dev_opt(C_HDEV_OPTIN_FG_FRMRK_M_BIT downto C_HDEV_OPTIN_FG_FRMRK_L_BIT);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_ETH_HEADER, i_reg_adr'length)) then
          txd := p_in_dev_opt(C_HDEV_OPTIN_ETH_HEADER_M_BIT downto C_HDEV_OPTIN_ETH_HEADER_L_BIT);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_TST0, i_reg_adr'length)) then
          txd := std_logic_vector(RESIZE(UNSIGNED(i_reg.tst0), txd'length));

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_TST1, i_reg_adr'length)) then
          txd(31 downto 0) := i_reg.tst1(31 downto 0);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_TST2, i_reg_adr'length)) then
          txd := p_in_tst(63 downto 32);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_FUNC, i_reg_adr'length)) then
          txd(C_HREG_FUNC_MEM_BIT) := '1';
          txd(C_HREG_FUNC_TMR_BIT) := '1';
          txd(C_HREG_FUNC_FG_BIT) := '1'; --Frame Grabber
          txd(C_HREG_FUNC_ETH_BIT) := '1';

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_FUNCPRM, i_reg_adr'length)) then

          txd(C_HREG_FUNCPRM_MEMBANK_SIZE_M_BIT downto C_HREG_FUNCPRM_MEMBANK_SIZE_L_BIT)
              := std_logic_vector(TO_UNSIGNED(C_PCFG_MEMCTRL_BANK_SIZE
                  , C_HREG_FUNCPRM_MEMBANK_SIZE_M_BIT - C_HREG_FUNCPRM_MEMBANK_SIZE_L_BIT + 1));

          txd(C_HREG_FUNCPRM_FG_VCH_COUNT_M_BIT downto C_HREG_FUNCPRM_FG_VCH_COUNT_L_BIT)
              := std_logic_vector(TO_UNSIGNED(C_PCFG_FG_VCH_COUNT
                 , C_HREG_FUNCPRM_FG_VCH_COUNT_M_BIT - C_HREG_FUNCPRM_FG_VCH_COUNT_L_BIT + 1));

          txd(C_HREG_FUNCPRM_FG_REV_BIT) := '0';

          if ((C_HDEV_DWIDTH / 32) = 8) then --BUS 256bit
            txd(C_HREG_FUNCPRM_FG_ALIGN_M_BIT
                downto C_HREG_FUNCPRM_FG_ALIGN_L_BIT) := std_logic_vector(TO_UNSIGNED(3, C_HREG_FUNCPRM_FG_ALIGN_M_BIT
                                                                                            - C_HREG_FUNCPRM_FG_ALIGN_L_BIT + 1));

          elsif ((C_HDEV_DWIDTH / 32) = 4) then --BUS 128bit
            txd(C_HREG_FUNCPRM_FG_ALIGN_M_BIT
                downto C_HREG_FUNCPRM_FG_ALIGN_L_BIT) := std_logic_vector(TO_UNSIGNED(2, C_HREG_FUNCPRM_FG_ALIGN_M_BIT
                                                                                            - C_HREG_FUNCPRM_FG_ALIGN_L_BIT + 1));

          elsif ((C_HDEV_DWIDTH / 32) = 2) then --BUS 64bit
            txd(C_HREG_FUNCPRM_FG_ALIGN_M_BIT
                downto C_HREG_FUNCPRM_FG_ALIGN_L_BIT) := std_logic_vector(TO_UNSIGNED(1, C_HREG_FUNCPRM_FG_ALIGN_M_BIT
                                                                                            - C_HREG_FUNCPRM_FG_ALIGN_L_BIT + 1));

          else  --BUS 32bit
            txd(C_HREG_FUNCPRM_FG_ALIGN_M_BIT downto C_HREG_FUNCPRM_FG_ALIGN_L_BIT) := (others => '0');
          end if;


        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_CFG_CTRL, i_reg_adr'length)) then
            txd(C_HREG_CFG_CTRL_ADR_M_BIT downto C_HREG_CFG_CTRL_ADR_L_BIT) := std_logic_vector(i_cfg_dadr);
            txd(C_HREG_CFG_CTRL_REG_M_BIT downto C_HREG_CFG_CTRL_REG_L_BIT) := std_logic_vector(i_cfg_dreg);

        elsif (i_reg_adr = TO_UNSIGNED(C_HREG_CFG_DATA, i_reg_adr'length)) then

            --####################
            --######   SWT  ######
            --####################
            if (i_cfg_dadr = TO_UNSIGNED(C_CFGDEV_SWT, i_cfg_dadr'length)) then

                if (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_CTRL, i_cfg_dreg'length)) then
                    txd(i_dev_reg.swt.ctrl'range) := i_dev_reg.swt.ctrl;

                elsif (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_DBG, i_cfg_dreg'length)) then
                    txd(i_dev_reg.swt.dbg'range) := i_dev_reg.swt.dbg;

                --filter pkt: ETH<->HOST
                elsif (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_ETH2HOST_FRR0, i_cfg_dreg'length)) then
                    txd((8 * 1) - 1 downto (8 * 0)) := i_dev_reg.swt.frr.eth2h(0);
                    txd((8 * 2) - 1 downto (8 * 1)) := i_dev_reg.swt.frr.eth2h(1);
                    txd((8 * 3) - 1 downto (8 * 2)) := i_dev_reg.swt.frr.eth2h(2);
                    txd((8 * 4) - 1 downto (8 * 3)) := i_dev_reg.swt.frr.eth2h(3);

                elsif (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_ETH2HOST_FRR1, i_cfg_dreg'length)) then
                    txd((8 * 1) - 1 downto (8 * 0)) := i_dev_reg.swt.frr.eth2h(4);
                    txd((8 * 2) - 1 downto (8 * 1)) := i_dev_reg.swt.frr.eth2h(5);
                    txd((8 * 3) - 1 downto (8 * 2)) := i_dev_reg.swt.frr.eth2h(6);
                    txd((8 * 4) - 1 downto (8 * 3)) := i_dev_reg.swt.frr.eth2h(7);

                --filter pkt: ETH->FG
                elsif (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_ETH2FG_FRR0, i_cfg_dreg'length)) then
                    txd((8 * 1) - 1 downto (8 * 0)) := i_dev_reg.swt.frr.eth2fg(0);
                    txd((8 * 2) - 1 downto (8 * 1)) := i_dev_reg.swt.frr.eth2fg(1);
                    txd((8 * 3) - 1 downto (8 * 2)) := i_dev_reg.swt.frr.eth2fg(2);
                    txd((8 * 4) - 1 downto (8 * 3)) := i_dev_reg.swt.frr.eth2fg(3);

                elsif (i_cfg_dreg = TO_UNSIGNED(C_SWT_REG_ETH2FG_FRR1, i_cfg_dreg'length)) then
                    txd((8 * 1) - 1 downto (8 * 0)) := i_dev_reg.swt.frr.eth2fg(4);
                    txd((8 * 2) - 1 downto (8 * 1)) := i_dev_reg.swt.frr.eth2fg(5);
                    txd((8 * 3) - 1 downto (8 * 2)) := i_dev_reg.swt.frr.eth2fg(6);
                    txd((8 * 4) - 1 downto (8 * 3)) := i_dev_reg.swt.frr.eth2fg(7);

                end if;--swt reg


            --####################
            --######   FG   ######
            --####################
            elsif (i_cfg_dadr = TO_UNSIGNED(C_CFGDEV_FG, i_cfg_dadr'length)) then

                if (i_cfg_dreg = TO_UNSIGNED(C_FG_REG_CTRL, i_cfg_dreg'length)) then
                    txd(i_reg.fg_ctrl'range) := i_reg.fg_ctrl;

                elsif (i_cfg_dreg = TO_UNSIGNED(C_FG_REG_DBG, i_cfg_dreg'length)) then
                  txd(i_dev_reg.fg.dbg'range) := i_dev_reg.fg.dbg;

                elsif (i_cfg_dreg = TO_UNSIGNED(C_FG_REG_DATA, i_cfg_dreg'length)) then

                    for ch in 0 to (C_FG_VCH_COUNT - 1) loop
                      if (ch = UNSIGNED(i_reg.fg_ctrl(C_FG_REG_CTRL_VCH_M_BIT downto C_FG_REG_CTRL_VCH_L_BIT))) then

                        if (UNSIGNED(i_reg.fg_ctrl(C_FG_REG_CTRL_PRM_M_BIT downto C_FG_REG_CTRL_PRM_L_BIT))
                            = TO_UNSIGNED(C_FG_PRM_ZONE_ACTIVE, (C_FG_REG_CTRL_PRM_M_BIT - C_FG_REG_CTRL_PRM_L_BIT))) then

                          txd(C_FG_PIX_M downto C_FG_PIX_L) := std_logic_vector(i_dev_reg.fg.prm.ch(ch).fr.act.pixcount);
                          txd(C_FG_ROW_M downto C_FG_ROW_L) := std_logic_vector(i_dev_reg.fg.prm.ch(ch).fr.act.rowcount);

                        elsif (UNSIGNED(i_reg.fg_ctrl(C_FG_REG_CTRL_PRM_M_BIT downto C_FG_REG_CTRL_PRM_L_BIT))
                            = TO_UNSIGNED(C_FG_PRM_ZONE_SKIP, (C_FG_REG_CTRL_PRM_M_BIT - C_FG_REG_CTRL_PRM_L_BIT))) then

                          txd(C_FG_PIX_M downto C_FG_PIX_L) := std_logic_vector(i_dev_reg.fg.prm.ch(ch).fr.skp.pixcount);
                          txd(C_FG_ROW_M downto C_FG_ROW_L) := std_logic_vector(i_dev_reg.fg.prm.ch(ch).fr.skp.rowcount);

                        elsif (UNSIGNED(i_reg.fg_ctrl(C_FG_REG_CTRL_PRM_M_BIT downto C_FG_REG_CTRL_PRM_L_BIT))
                            = TO_UNSIGNED(C_FG_PRM_OPTIONS, (C_FG_REG_CTRL_PRM_M_BIT - C_FG_REG_CTRL_PRM_L_BIT))) then

                          txd(C_FG_PRM_OPTIONS_MIRX_BIT) := i_dev_reg.fg.prm.ch(ch).mirror.pix;
                          txd(C_FG_PRM_OPTIONS_MIRY_BIT) := i_dev_reg.fg.prm.ch(ch).mirror.row;

                        elsif (UNSIGNED(i_reg.fg_ctrl(C_FG_REG_CTRL_PRM_M_BIT downto C_FG_REG_CTRL_PRM_L_BIT))
                            = TO_UNSIGNED(C_FG_PRM_STEP_RD_LINE, (C_FG_REG_CTRL_PRM_M_BIT - C_FG_REG_CTRL_PRM_L_BIT))) then

                          txd(i_dev_reg.fg.prm.ch(ch).steprd'range) := std_logic_vector(i_dev_reg.fg.prm.ch(ch).steprd);

                        end if;
                      end if;
                    end loop;

                elsif (i_cfg_dreg = TO_UNSIGNED(C_FG_REG_MEM_CTRL, i_cfg_dreg'length)) then
                    txd(C_HREG_MEM_CTRL_TRNWR_M_BIT downto C_HREG_MEM_CTRL_TRNWR_L_BIT) := i_dev_reg.fg.prm.memwr_trnlen;
                    txd(C_HREG_MEM_CTRL_TRNRD_M_BIT downto C_HREG_MEM_CTRL_TRNRD_L_BIT) := i_dev_reg.fg.prm.memrd_trnlen;

                end if;--fg reg


            --####################
            --######   ETH  ######
            --####################
            elsif (i_cfg_dadr = TO_UNSIGNED(C_CFGDEV_ETH, i_cfg_dadr'length)) then

                if (i_cfg_dreg = TO_UNSIGNED(C_ETH_REG_MAC_PATRN0, i_cfg_dreg'length)) then
                    txd((8 * 1) - 1 downto (8 * 0)) := i_dev_reg.eth(0).mac.dst(0);
                    txd((8 * 2) - 1 downto (8 * 1)) := i_dev_reg.eth(0).mac.dst(1);
                    txd((8 * 3) - 1 downto (8 * 2)) := i_dev_reg.eth(0).mac.dst(2);
                    txd((8 * 4) - 1 downto (8 * 3)) := i_dev_reg.eth(0).mac.dst(3);

                elsif (i_cfg_dreg = TO_UNSIGNED(C_ETH_REG_MAC_PATRN1, i_cfg_dreg'length)) then
                    txd((8 * 1) - 1 downto (8 * 0)) := i_dev_reg.eth(0).mac.dst(4);
                    txd((8 * 2) - 1 downto (8 * 1)) := i_dev_reg.eth(0).mac.dst(5);
                    txd((8 * 3) - 1 downto (8 * 2)) := i_dev_reg.eth(0).mac.src(0);
                    txd((8 * 4) - 1 downto (8 * 3)) := i_dev_reg.eth(0).mac.src(1);

                elsif (i_cfg_dreg = TO_UNSIGNED(C_ETH_REG_MAC_PATRN2, i_cfg_dreg'length)) then
                    txd((8 * 1) - 1 downto (8 * 0)) := i_dev_reg.eth(0).mac.src(2);
                    txd((8 * 2) - 1 downto (8 * 1)) := i_dev_reg.eth(0).mac.src(3);
                    txd((8 * 3) - 1 downto (8 * 2)) := i_dev_reg.eth(0).mac.src(4);
                    txd((8 * 4) - 1 downto (8 * 3)) := i_dev_reg.eth(0).mac.src(5);

                end if;--eth reg


            --####################
            --######   TMR  ######
            --####################
            elsif (i_cfg_dadr = TO_UNSIGNED(C_CFGDEV_TMR, i_cfg_dadr'length)) then

                if (i_cfg_dreg = TO_UNSIGNED(C_TMR_REG_CTRL, i_cfg_dreg'length)) then
                    txd(i_dev_reg.tmr.en'range) := i_dev_reg.tmr.en; --status of tmr (on/off)

                elsif (i_cfg_dreg = TO_UNSIGNED(C_TMR_REG_CMP, i_cfg_dreg'length)) then
                  for i in 0 to (C_TMR_COUNT - 1) loop
                    if (i = i_tmr_num) then
                      txd := std_logic_vector(i_dev_reg.tmr.data(i));
                    end if;
                  end loop;

                end if;--tmr reg
            end if;--cfg_dadr

        end if; --adr
      end if; --bar

      p_out_reg_do <= txd;

    end if;--rd
  end if; --rst
end if;--clk
end process;--Reg Read


----------------------------------------------------------------------------------------------
--Master mode. DMA ctrl
----------------------------------------------------------------------------------------------
--TRN DONE: PC->FPGA
i_dmatrn_mrd_done <= i_mrd_done
                      when UNSIGNED(i_hdev_adr) /= TO_UNSIGNED(C_HDEV_MEM, i_hdev_adr'length)
                            or i_reg.pcie(C_HREG_PCIE_SPEED_TESTING_BIT) = '1'
                        else (not i_reg.dev_ctrl(C_HREG_DMA_CTRL_DMA_DIR_BIT)
                              and AND_reduce(i_dmatrn_mem_done));
--TRN DONE: PC<-FPGA
i_dmatrn_mwr_done <= i_mwr_done
                      when UNSIGNED(i_hdev_adr) /= TO_UNSIGNED(C_HDEV_MEM, i_hdev_adr'length)
                            or i_reg.pcie(C_HREG_PCIE_SPEED_TESTING_BIT) = '1'
                        else ( i_reg.dev_ctrl(C_HREG_DMA_CTRL_DMA_DIR_BIT)
                              and AND_reduce(i_dmatrn_mem_done));

i_dmatrn_done <= i_dmatrn_mwr_done or i_dmatrn_mrd_done;

dma_end : process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0' or i_usr_grst = '1') then
    i_mrd_rcv_size_ok <= '0';
    i_dmatrn_mem_done <= (others => '0');
    sr_memtrn_done <= (others => '0');
    i_memtrn_done <= '0';

    sr_mrd_done <= '0';
    i_mrd_done <= '0';

    sr_mwr_done <= '0';
    i_mwr_done <= '0';

  else

    --Check size recieve data (DMATRN_RD)
    if (i_dmatrn_init = '1') then
      i_mrd_rcv_size_ok <= '0';
    else
      if (p_in_dma_mrd_rcv_size(31 downto 0) /= (p_in_dma_mrd_rcv_size'range => '0')) then
        if (("00" & i_dmaprm.len(31 downto 2)) = p_in_dma_mrd_rcv_size(31 downto 0)) then
          i_mrd_rcv_size_ok <= '1';
        end if;
      end if;
    end if ;

--    i_mrd_done <= i_mrd_rcv_size_ok and p_in_txbuf_last;

    sr_mrd_done <= p_in_dma_mrd_done;
    i_mrd_done <= p_in_dma_mrd_done and not sr_mrd_done;


    sr_mwr_done <= p_in_dma_mwr_done;
    i_mwr_done <= p_in_dma_mwr_done and not sr_mwr_done;

    --DMATRN <-> MEM_CTRL
    if (UNSIGNED(i_hdev_adr) = TO_UNSIGNED(C_HDEV_MEM, i_hdev_adr'length)
      and i_reg.pcie(C_HREG_PCIE_SPEED_TESTING_BIT) /= '1') then

      if (AND_reduce(i_dmatrn_mem_done) = '1' or i_dma_start = '1') then
        i_dmatrn_mem_done <= (others => '0');
      else
        --Core PCIExpress - DMATRN done
        if (i_mwr_done = '1' or i_mrd_done = '1') then
          i_dmatrn_mem_done(0) <=  '1';
        end if;

        --ACK from pcie2mem_ctrl.vhd
        if (i_memtrn_done = '1') then
          i_dmatrn_mem_done(1) <= '1';
        end if;
      end if;
    end if;

    sr_memtrn_done <= p_in_dev_opt(C_HDEV_OPTIN_MEM_DONE_BIT) & sr_memtrn_done(0 to 1);
    i_memtrn_done <= sr_memtrn_done(1) and not sr_memtrn_done(2);

  end if;
end if;--p_in_rst_n,
end process;--dma_end


dma : process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0' or i_usr_grst = '1') then

    i_dmatrn_init <= '0';
    i_dmatrn_start <= '0';
    i_dmatrn_work <= '0';
    sr_dmatrn_done <= '0';

    i_dma_work <= '0';
    sr_dma_work <= '0';
    i_dma_irq <= '0';

    i_dmaprm.addr <= (others => '0');
    i_dmaprm.len <= (others => '0');

    i_dmabuf_num_cnt <= (others => '0');
    i_dmabuf_done_cnt <= (others => '0');

    i_hw_dmaprm_cnt <= (others => '0');
    i_hw_dmaprm_rd <= (others => '0');

    sr_hw_dmaprm_cnt <= (others => '0');
    sr_hw_dmaprm_rd <=( others => '0');

  else

    ---------------------------------------------
    --DMATRN initialization and start
    ---------------------------------------------
    i_dmatrn_start <= i_dmatrn_init;

    ---------------------------------------------
    --One buffer DMA - done
    ---------------------------------------------
    if (i_dmatrn_start = '1') then
      i_dmatrn_work <= '1';
    elsif (i_dmatrn_done = '1') then
      i_dmatrn_work <= '0';
    end if;
    sr_dmatrn_done <= i_dmatrn_done;

    ---------------------------------------------
    --All set buffers DMA - done
    ---------------------------------------------
    if (i_dmatrn_start = '1') then
      i_dma_work <= '1';
    elsif ( (UNSIGNED(i_dmabuf_count) = i_dmabuf_done_cnt and i_dmatrn_done = '1')
        or ((UNSIGNED(i_reg.irq(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT))
              = TO_UNSIGNED(C_HIRQ_PCIE_DMA,(C_HREG_IRQ_NUM_M_WBIT - C_HREG_IRQ_NUM_L_WBIT + 1))) and i_irq_status_clr = '1') ) then
      i_dma_work <= '0';
    end if;

    sr_dma_work <= i_dma_work;
    i_dma_irq <= sr_dma_work and not i_dma_work;

    ---------------------------------------------
    --Read DMATRN param
    ---------------------------------------------
    if (i_dma_start = '1' or (i_dma_work = '1' and sr_dmatrn_done = '1')) then
       i_hw_dmaprm_rd(0) <= '1';
    elsif (i_hw_dmaprm_cnt = "01") then
       i_hw_dmaprm_rd(0) <= '0';
    end if;

    if (i_hw_dmaprm_rd(0) = '1') then
      i_hw_dmaprm_cnt <= i_hw_dmaprm_cnt + 1;
    else
      i_hw_dmaprm_cnt <= (others => '0');
    end if;

    sr_hw_dmaprm_cnt <= std_logic_vector(i_hw_dmaprm_cnt);
    sr_hw_dmaprm_rd <= i_hw_dmaprm_rd;

    --Load DMATRN param for use PCI-Express core
    if (sr_hw_dmaprm_rd(0) = '1') then
      if (sr_hw_dmaprm_cnt = "00") then
        i_dmaprm.len <= i_hw_dmaprm_do; --Size (Byte)
        i_dmatrn_init <= '0';

      elsif (sr_hw_dmaprm_cnt = "01") then
        i_dmaprm.addr <= i_hw_dmaprm_do; --Adress(Byte)
        i_dmatrn_init <= '1';

      end if;
    else
      i_dmatrn_init <= '0';
    end if;

    --Counting DMA buffer donr +
    --Load index start buffer
    if (i_dma_start = '1') then
      i_dmabuf_num_cnt <= UNSIGNED(i_dmabuf_num); --Index start buffer
      i_dmabuf_done_cnt <= (others => '0');

    elsif (i_dmatrn_done = '1') then
      i_dmabuf_num_cnt <= i_dmabuf_num_cnt + 1;
      i_dmabuf_done_cnt <= i_dmabuf_done_cnt + 1;
    end if;

  end if;
end if;--p_in_rst_n,
end process;--dma


--BRAM for DMATRN param: Adress buf + Size buf(Byte)
i_host_dmaprm_adr(i_dmabuf_num'length + 1 downto i_dmabuf_num'length) <= "00" when i_reg_bar = '1'
                                       and i_reg_adr = TO_UNSIGNED(C_HREG_DMAPRM_LEN, 5) else "01";
i_host_dmaprm_adr(i_dmabuf_num'range) <= std_logic_vector(RESIZE(UNSIGNED(i_dmabuf_num), i_dmabuf_num'length));

i_hw_dmaprm_adr(i_dmabuf_num'length + 1 downto i_dmabuf_num'length) <= std_logic_vector(i_hw_dmaprm_cnt);
i_hw_dmaprm_adr(i_dmabuf_num'range) <= std_logic_vector(RESIZE(i_dmabuf_num_cnt, i_dmabuf_num'length));

m_bram_dmaprms : bram_dma_params
port map
(
addra => i_host_dmaprm_adr,
dina  => i_host_dmaprm_di,
douta => i_host_dmaprm_do,
ena   => '1',
wea   => i_host_dmaprm_wr,
clka  => p_in_clk,


addrb => i_hw_dmaprm_adr,
dinb  => (others => '0'),
doutb => i_hw_dmaprm_do,
enb   => i_hw_dmaprm_rd(0),
web   => "0",              --Only read
clkb  => p_in_clk
);


---------------------------------------------------------
--IRQ
---------------------------------------------------------
p_out_irq_clr <= i_irq_clr;
p_out_irq_set <= OR_reduce(i_irq_req);

i_irq_dev(C_HIRQ_PCIE_DMA) <= i_dma_irq;
i_irq_dev(i_irq_dev'high downto C_HIRQ_PCIE_DMA + 1) <= p_in_dev_irq(C_HIRQ_COUNT - 1 downto C_HIRQ_PCIE_DMA + 1);

--user devices
gen_irq: for i in 0 to (C_HIRQ_COUNT - 1) generate
--Detect rising edge
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (i_irq_en(i) = '0' or i_usr_grst = '1') then
    sr_irq_set(i) <= (others => '0');
    i_irq_set(i) <= '0';
  else
    sr_irq_set(i) <= i_irq_dev(i) & sr_irq_set(i)(0 to 1);
    i_irq_set(i) <= sr_irq_set(i)(1) and not sr_irq_set(i)(2);
  end if;
end if;
end process;

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (i_irq_status_clr = '1' and (UNSIGNED(i_reg.irq(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT)) = i) )then
    i_irq_status(i) <= '0';
    i_irq_req(i) <= '0';

  elsif (i_irq_set(i) = '1') then
    i_irq_req(i) <= '1';

  elsif (i_irq_req(i) = '1' and p_in_irq_ack = '1') then
    i_irq_status(i) <= '1';

  end if;
end if;
end process;

end generate gen_irq;


---------------------------------------------------------------------
--User devices CTRL
---------------------------------------------------------------------
--gen_sim_on : if strcmp(G_SIM, "ON") generate
--begin
--p_out_rxbuf_do <= std_logic_vector(tst_mem_dcnt_swap);
----p_out_rxbuf_do <= p_in_dev_do
----                      when UNSIGNED(i_hdev_adr) /= TO_UNSIGNED(C_HDEV_MEM, i_hdev_adr'length) else std_logic_vector(tst_mem_dcnt_swap);
--end generate gen_sim_on;
--Generator test data (counter)
process(p_in_rst_n, i_usr_grst, p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0' or i_usr_grst = '1') then
    for i in 0 to (tst_mem_dcnt'length / CI_TESTDATA_WIDTH) - 1 loop
    tst_mem_dcnt(CI_TESTDATA_WIDTH * (i + 1) - 1 downto CI_TESTDATA_WIDTH * i) <= TO_UNSIGNED(i, CI_TESTDATA_WIDTH);
    end loop;
  else
    if (p_in_rxbuf_rd = '1' and UNSIGNED(i_hdev_adr) = TO_UNSIGNED(C_HDEV_MEM, i_hdev_adr'length)) then
      for i in 0 to (tst_mem_dcnt'length / CI_TESTDATA_WIDTH) - 1 loop
      tst_mem_dcnt(CI_TESTDATA_WIDTH * (i + 1) - 1 downto CI_TESTDATA_WIDTH * i) <= tst_mem_dcnt(CI_TESTDATA_WIDTH * (i + 1) - 1 downto CI_TESTDATA_WIDTH * i)
                                                 + TO_UNSIGNED((tst_mem_dcnt'length / CI_TESTDATA_WIDTH), CI_TESTDATA_WIDTH);
      end loop;
    end if;
  end if;
end if;
end process;
--gen_swap : for i in 0 to (tst_mem_dcnt'length / CI_TESTDATA_WIDTH) - 1 generate
--tst_mem_dcnt_swap(CI_TESTDATA_WIDTH * (((tst_mem_dcnt'length / CI_TESTDATA_WIDTH - 1) - i) + 1) - 1
--                     downto CI_TESTDATA_WIDTH * ((tst_mem_dcnt'length / CI_TESTDATA_WIDTH - 1) - i)) <= tst_mem_dcnt(CI_TESTDATA_WIDTH * (i + 1) - 1 downto CI_TESTDATA_WIDTH * i);
--end generate gen_swap;
tst_mem_dcnt_swap <= tst_mem_dcnt;


--gen_sim_off : if strcmp(G_SIM, "OFF") generate begin
p_out_rxbuf_do <= p_in_dev_do when i_reg.pcie(C_HREG_PCIE_EN_TESTD_GEN_BIT) = '0' else std_logic_vector(tst_mem_dcnt_swap);
--end generate gen_sim_off;

p_out_txbuf_full <= p_in_dev_opt(C_HDEV_OPTIN_TXFIFO_FULL_BIT) and not i_reg.pcie(C_HREG_PCIE_SPEED_TESTING_BIT);
p_out_rxbuf_empty <= p_in_dev_opt(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT) and not i_reg.pcie(C_HREG_PCIE_SPEED_TESTING_BIT);

p_out_dev_wr <= p_in_txbuf_wr;
p_out_dev_rd <= p_in_rxbuf_rd;
p_out_dev_di <= p_in_txbuf_di;

--user device ctrl
i_dma_ctrl(C_HREG_DMA_CTRL_DRDY_BIT) <= i_mrd_done or i_dev_drdy;

i_dma_ctrl(C_HREG_DMA_CTRL_DMA_START_BIT) <= sr_dma_start
                                      when UNSIGNED(i_hdev_adr) /= TO_UNSIGNED(C_HDEV_MEM
                                                                              , i_hdev_adr'length) else
                                        i_dmatrn_init and not i_reg.pcie(C_HREG_PCIE_SPEED_TESTING_BIT);

i_dma_ctrl(C_HREG_DMA_CTRL_LAST_BIT
              downto C_HREG_DMA_CTRL_DMA_START_BIT + 1) <= i_reg.dev_ctrl(C_HREG_DMA_CTRL_LAST_BIT
                                                                          downto C_HREG_DMA_CTRL_DMA_START_BIT + 1);

p_out_dev_ctrl.dma <= i_dma_ctrl;
p_out_dev_ctrl.reg <= i_dev_reg;

p_out_gctrl(C_HREG_CTRL_FG_RDDONE_BIT - 1 downto 0) <= i_reg.ctrl(C_HREG_CTRL_FG_RDDONE_BIT - 1 downto 0);
p_out_gctrl(C_HREG_CTRL_FG_RDDONE_BIT) <= i_fg_rddone;


--MEM_CTRL
process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if (i_dma_start = '1') then
      i_mem_adr_cnt <= RESIZE(UNSIGNED(i_reg.mem_adr(i_reg.mem_adr'high downto log2(C_HDEV_DWIDTH / 8))), i_mem_adr_cnt'length);
    else
      if (UNSIGNED(i_hdev_adr) = TO_UNSIGNED(C_HDEV_MEM, i_hdev_adr'length)
        and (p_in_rxbuf_rd = '1' or p_in_txbuf_wr = '1') ) then

        i_mem_adr_cnt <= i_mem_adr_cnt + 1;

      end if;
    end if;
  end if;
end process;

p_out_dev_opt(C_HDEV_OPTOUT_MEM_ADR_M_BIT downto C_HDEV_OPTOUT_MEM_ADR_L_BIT)
  <= std_logic_vector(i_mem_adr_cnt) & i_reg.mem_adr(log2(C_HDEV_DWIDTH / 8) - 1 downto 0); --Cnt BYTE

p_out_dev_opt(C_HDEV_OPTOUT_MEM_RQLEN_M_BIT downto C_HDEV_OPTOUT_MEM_RQLEN_L_BIT)
  <= i_dmaprm.len(C_HDEV_OPTOUT_MEM_RQLEN_M_BIT - C_HDEV_OPTOUT_MEM_RQLEN_L_BIT downto 0);

p_out_dev_opt(C_HDEV_OPTOUT_MEM_TRNWR_LEN_M_BIT downto C_HDEV_OPTOUT_MEM_TRNWR_LEN_L_BIT)
  <= i_reg.mem_ctrl(C_HREG_MEM_CTRL_TRNWR_M_BIT downto C_HREG_MEM_CTRL_TRNWR_L_BIT);

p_out_dev_opt(C_HDEV_OPTOUT_MEM_TRNRD_LEN_M_BIT downto C_HDEV_OPTOUT_MEM_TRNRD_LEN_L_BIT)
  <= i_reg.mem_ctrl(C_HREG_MEM_CTRL_TRNRD_M_BIT downto C_HREG_MEM_CTRL_TRNRD_L_BIT);



---------------------------------------------------------------------
--DBG
---------------------------------------------------------------------
p_out_tst(31 downto 0)    <= i_reg.tst0;
p_out_tst(47 downto 32)   <= std_logic_vector(RESIZE(UNSIGNED(i_reg.tst1(7 downto 0)), 16));
p_out_tst(55 downto 48)   <= i_dmabuf_count(7 downto 0);
p_out_tst(57 downto 56)   <= i_dmatrn_mem_done;
p_out_tst(61 downto 58)   <= i_hdev_adr;
p_out_tst(62)             <= i_reg.dev_ctrl(C_HREG_DMA_CTRL_DMA_DIR_BIT);
p_out_tst(63)             <= i_reg_bar and (p_in_reg_wr or i_reg_rd);
p_out_tst(64)             <= i_memtrn_done;
p_out_tst(72 downto 65)   <= std_logic_vector(i_dmabuf_num_cnt(7 downto 0));
p_out_tst(73)             <= i_dmatrn_done;
p_out_tst(74)             <= i_dmatrn_init;
p_out_tst(95 downto 75)   <= (others => '0');
p_out_tst(96)             <= i_irq_status_clr;
p_out_tst(100 downto 97)  <= std_logic_vector(RESIZE(UNSIGNED(i_reg.irq(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT)), 4));
p_out_tst(108 downto 101) <= std_logic_vector(RESIZE(UNSIGNED(i_irq_status), 8));
p_out_tst(116 downto 109) <= std_logic_vector(RESIZE(UNSIGNED(i_irq_set(C_HIRQ_COUNT - 1 downto 0)), 8));
p_out_tst(120 downto 117) <= i_reg.dev_ctrl(C_HREG_DMA_CTRL_ADR_M_BIT downto C_HREG_DMA_CTRL_ADR_L_BIT); --(22..19)
p_out_tst(121)            <= p_in_tst(0); --axi_rc_err_detect
p_out_tst(122)            <= i_reg.pcie(C_HREG_PCIE_SPEED_TESTING_BIT);
p_out_tst(123)            <= p_in_txbuf_wr;
p_out_tst(124)            <= p_in_rxbuf_rd;
p_out_tst(125)            <= p_in_txbuf_wr or p_in_rxbuf_rd;
p_out_tst(126)            <= i_dma_work;
p_out_tst(127)            <= '0';--rezerv



end architecture behavioral;

