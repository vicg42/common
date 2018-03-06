-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 07.07.2015 10:29:01
-- Module Name : pcie_unit_pkg
--
-- Description :
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.prj_def.all;
use work.pcie_pkg.all;

package pcie_unit_pkg is

component pio_to_ctrl
port (
clk        : in  std_logic;
rst_n      : in  std_logic;

req_compl  : in  std_logic;
compl_done : in  std_logic;

cfg_power_state_change_interrupt : in  std_logic;
cfg_power_state_change_ack       : out std_logic
);
end component pio_to_ctrl;

component pcie_rx
generic(
G_DATA_WIDTH : integer := 64
);
port (
-- Completer Request Interface
p_in_axi_cq_tdata    : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_in_axi_cq_tlast    : in  std_logic;
p_in_axi_cq_tvalid   : in  std_logic;
p_in_axi_cq_tuser    : in  std_logic_vector(84 downto 0);
p_in_axi_cq_tkeep    : in  std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_out_axi_cq_tready  : out std_logic;

p_in_pcie_cq_np_req_count : in  std_logic_vector(5 downto 0);
p_out_pcie_cq_np_req      : out std_logic;

-- Requester Completion Interface
p_in_axi_rc_tdata    : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_in_axi_rc_tlast    : in  std_logic;
p_in_axi_rc_tvalid   : in  std_logic;
p_in_axi_rc_tkeep    : in  std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_in_axi_rc_tuser    : in  std_logic_vector(74 downto 0);
p_out_axi_rc_tready  : out std_logic;

--RX Message Interface
p_in_cfg_msg_received      : in  std_logic;
p_in_cfg_msg_received_type : in  std_logic_vector(4 downto 0);
p_in_cfg_msg_data          : in  std_logic_vector(7 downto 0);

--completion
p_out_req_compl    : out std_logic := '0';
p_out_req_compl_ur : out std_logic := '0';
p_in_compl_done    : in  std_logic;

p_out_req_prm      : out TPCIE_reqprm;

--DMA
p_in_dma_init      : in  std_logic;
p_in_dma_prm       : in  TPCIE_dmaprm;
p_in_dma_mrd_en    : in  std_logic;
p_out_dma_mrd_done : out std_logic;
p_out_dma_mrd_rxdwcount : out std_logic_vector(31 downto 0);

--usr app
p_out_ureg_di  : out std_logic_vector(31 downto 0);
p_out_ureg_wrbe: out std_logic_vector(3 downto 0);
p_out_ureg_wr  : out std_logic;
p_out_ureg_rd  : out std_logic;

--p_out_utxbuf_be   : out  std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_out_utxbuf_di   : out  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_utxbuf_wr   : out  std_logic;
p_out_utxbuf_last : out  std_logic;
p_in_utxbuf_full  : in   std_logic;

--DBG
p_out_tst : out std_logic_vector(63 downto 0);

--system
p_in_clk   : in  std_logic;
p_in_rst_n : in  std_logic
);
end component pcie_rx;


component pcie_tx
generic (
G_TXRQ_ENABLE_CLIENT_TAG : natural := 0;
G_DATA_WIDTH : integer := 64
);
port (
--AXI-S Completer Competion Interface
p_out_axi_cc_tdata  : out std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_axi_cc_tkeep  : out std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_out_axi_cc_tlast  : out std_logic;
p_out_axi_cc_tvalid : out std_logic;
p_out_axi_cc_tuser  : out std_logic_vector(32 downto 0);
p_in_axi_cc_tready  : in  std_logic;

--AXI-S Requester Request Interface
p_out_axi_rq_tdata  : out std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_axi_rq_tkeep  : out std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_out_axi_rq_tlast  : out std_logic;
p_out_axi_rq_tvalid : out std_logic;
p_out_axi_rq_tuser  : out std_logic_vector(59 downto 0);
p_in_axi_rq_tready  : in  std_logic;

--TX Message Interface
p_in_cfg_msg_transmit_done  : in  std_logic;
p_out_cfg_msg_transmit      : out std_logic;
p_out_cfg_msg_transmit_type : out std_logic_vector(2 downto 0);
p_out_cfg_msg_transmit_data : out std_logic_vector(31 downto 0);

--Tag availability and Flow control Information
p_in_pcie_rq_tag          : in  std_logic_vector(5 downto 0);
p_in_pcie_rq_tag_vld      : in  std_logic;
p_in_pcie_rq_seq_num      : in  std_logic_vector(3 downto 0);
p_in_pcie_rq_seq_num_vld  : in  std_logic;
p_in_pcie_tfc_nph_av      : in  std_logic_vector(1 downto 0);
p_in_pcie_tfc_npd_av      : in  std_logic_vector(1 downto 0);
p_in_pcie_tfc_np_pl_empty : in  std_logic;

--Cfg Flow Control Information
p_in_cfg_fc_ph   : in  std_logic_vector(7 downto 0);
p_in_cfg_fc_nph  : in  std_logic_vector(7 downto 0);
p_in_cfg_fc_cplh : in  std_logic_vector(7 downto 0);
p_in_cfg_fc_pd   : in  std_logic_vector(11 downto 0);
p_in_cfg_fc_npd  : in  std_logic_vector(11 downto 0);
p_in_cfg_fc_cpld : in  std_logic_vector(11 downto 0);
p_out_cfg_fc_sel : out std_logic_vector(2 downto 0);

--Completion
p_in_req_compl    : in  std_logic;
p_in_req_compl_ur : in  std_logic;
p_out_compl_done  : out std_logic;

p_in_req_prm      : in TPCIE_reqprm;

p_in_pcie_prm    : in  TPCIE_cfgprm;

p_in_completer_id : in  std_logic_vector(15 downto 0);

--usr app
--usr app
p_in_ureg_do      : in  std_logic_vector(31 downto 0);

p_in_urxbuf_empty : in  std_logic;
p_in_urxbuf_do    : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_urxbuf_rd   : out std_logic;
p_out_urxbuf_last : out std_logic;

--DMA
p_in_dma_init      : in  std_logic;
p_in_dma_prm       : in  TPCIE_dmaprm;
p_in_dma_mwr_en    : in  std_logic;
p_out_dma_mwr_done : out std_logic;
p_in_dma_mrd_en    : in  std_logic;
p_out_dma_mrd_done : out std_logic;
p_in_dma_mrd_rxdwcount : in std_logic_vector(31 downto 0);

--DBG
p_out_tst : out std_logic_vector((280 * 2) - 1 downto (280 * 0));

--system
p_in_clk   : in  std_logic;
p_in_rst_n : in  std_logic
);
end component pcie_tx;


component pcie_irq
port(
-----------------------------
--Usr Ctrl
-----------------------------
p_in_irq_clr  : in   std_logic;
p_in_irq_set  : in   std_logic;
p_out_irq_ack : out  std_logic;

-----------------------------
--PCIE Port
-----------------------------
p_in_cfg_msi_fail : in   std_logic;
p_in_cfg_msi      : in   std_logic;
p_in_cfg_irq_rdy  : in   std_logic;
p_out_cfg_irq_pad : out  std_logic;
p_out_cfg_irq_int : out  std_logic;
p_out_cfg_irq_err : out  std_logic;

-----------------------------
--SYSTEM
-----------------------------
p_in_clk   : in   std_logic;
p_in_rst_n : in   std_logic
);
end component pcie_irq;


component pcie_usr_app
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
p_in_dma_mrd_rcv_size : in    std_logic_vector(31 downto 0);
p_in_dma_mrd_rcv_err  : in    std_logic;
p_in_dma_mrd_done     : in    std_logic;

--IRQ
p_out_irq_clr : out   std_logic;
p_out_irq_set : out   std_logic;
p_in_irq_ack  : in    std_logic;

--System
p_in_clk   : in    std_logic;
p_in_rst_n : in    std_logic
);
end component pcie_usr_app;


--component dbgcs_ila_pcie is
--port (
--clk : in std_logic;
--probe0 : in std_logic_vector(48 downto 0)
--);
--end component dbgcs_ila_pcie;

end package pcie_unit_pkg;

