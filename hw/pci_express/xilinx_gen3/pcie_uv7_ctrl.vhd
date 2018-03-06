-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 07.07.2015 10:45:04
-- Module Name : pcie_ctrl.vhd
--
-- Description : CTRL core PCI-Express
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.pcie_unit_pkg.all;
use work.pcie_pkg.all;
use work.prj_def.all;
use work.prj_cfg.all;

entity pcie_ctrl is
generic(
G_SIM : string := "OFF";
G_DBGCS : string := "OFF";
G_DATA_WIDTH : integer := 64
);
port(
--------------------------------------
--USR Port
--------------------------------------
p_out_hclk      : out   std_logic;
p_out_gctrl     : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--CTRL user devices
p_out_dev_ctrl  : out   TDevCtrl;
p_out_dev_di    : out   std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_in_dev_do     : in    std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
p_out_dev_wr    : out   std_logic;
p_out_dev_rd    : out   std_logic;
p_in_dev_status : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto C_HREG_DEV_STATUS_FST_BIT);
p_in_dev_irq    : in    std_logic_vector((C_HIRQ_COUNT - 1) downto C_HIRQ_FST_BIT);
p_in_dev_opt    : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto C_HDEV_OPTIN_FST_BIT);
p_out_dev_opt   : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto C_HDEV_OPTOUT_FST_BIT);

--DBG
p_out_dbg       : out   TPCIE_dbg;
p_out_tst       : out   std_logic_vector(127 downto 0);
p_in_tst        : in    std_logic_vector(127 downto 0);

------------------------------------
--AXI Interface
------------------------------------
p_out_axi_rq_tlast   : out  std_logic                                  ;
p_out_axi_rq_tdata   : out  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_axi_rq_tuser   : out  std_logic_vector(59 downto 0)              ;
p_out_axi_rq_tkeep   : out  std_logic_vector((G_DATA_WIDTH / 32) - 1  downto 0);
p_in_axi_rq_tready   : in   std_logic_vector(3 downto 0)               ;
p_out_axi_rq_tvalid  : out  std_logic                                  ;

p_in_axi_rc_tdata    : in   std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_in_axi_rc_tuser    : in   std_logic_vector(74 downto 0)              ;
p_in_axi_rc_tlast    : in   std_logic                                  ;
p_in_axi_rc_tkeep    : in   std_logic_vector((G_DATA_WIDTH / 32) - 1  downto 0);
p_in_axi_rc_tvalid   : in   std_logic                                  ;
p_out_axi_rc_tready  : out  std_logic_vector(21 downto 0)              ;

p_in_axi_cq_tdata    : in   std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_in_axi_cq_tuser    : in   std_logic_vector(84 downto 0)              ;
p_in_axi_cq_tlast    : in   std_logic                                  ;
p_in_axi_cq_tkeep    : in   std_logic_vector((G_DATA_WIDTH / 32) - 1  downto 0);
p_in_axi_cq_tvalid   : in   std_logic                                  ;
p_out_axi_cq_tready  : out  std_logic_vector(21 downto 0)              ;

p_out_axi_cc_tdata   : out  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_axi_cc_tuser   : out  std_logic_vector(32 downto 0)              ;
p_out_axi_cc_tlast   : out  std_logic                                  ;
p_out_axi_cc_tkeep   : out  std_logic_vector((G_DATA_WIDTH / 32) - 1  downto 0);
p_out_axi_cc_tvalid  : out  std_logic                                  ;
p_in_axi_cc_tready   : in   std_logic_vector(3 downto 0)               ;

p_in_pcie_tfc_nph_av : in   std_logic_vector(1 downto 0)                ;
p_in_pcie_tfc_npd_av : in   std_logic_vector(1 downto 0)                ;

------------------------------------
--Configuration (CFG) Interface
------------------------------------
p_in_pcie_rq_seq_num      : in   std_logic_vector(3 downto 0);
p_in_pcie_rq_seq_num_vld  : in   std_logic                   ;
p_in_pcie_rq_tag          : in   std_logic_vector(5 downto 0);
p_in_pcie_rq_tag_vld      : in   std_logic                   ;
p_out_pcie_cq_np_req      : out  std_logic                   ;
p_in_pcie_cq_np_req_count : in   std_logic_vector(5 downto 0);
p_in_pcie_tfc_np_pl_empty : in   std_logic                   ;
--p_in_pcie_rq_tag_av       : in   std_logic_vector(1 downto 0);

------------------------------------
--Management Interface
------------------------------------
p_in_cfg_msg_received         : in  std_logic;
p_in_cfg_msg_received_data    : in  std_logic_vector(7 downto 0);
p_in_cfg_msg_received_type    : in  std_logic_vector(4 downto 0);
p_out_cfg_msg_transmit        : out std_logic;
p_out_cfg_msg_transmit_type   : out std_logic_vector(2 downto 0);
p_out_cfg_msg_transmit_data   : out std_logic_vector(31 downto 0);
p_in_cfg_msg_transmit_done    : in  std_logic;

------------------------------------
-- EP and RP
------------------------------------
p_in_cfg_phy_link_status  : in   std_logic_vector(1 downto 0);
p_in_cfg_negotiated_width : in   std_logic_vector(3 downto 0); -- valid when cfg_phy_link_status[1:0] == 11b
p_in_cfg_current_speed    : in   std_logic_vector(2 downto 0);
p_in_cfg_max_payload      : in   std_logic_vector(2 downto 0);
p_in_cfg_max_read_req     : in   std_logic_vector(2 downto 0);
p_in_cfg_function_status  : in   std_logic_vector(7 downto 0);
p_in_cfg_rcb_status       : in   std_logic_vector(1 downto 0);

-- Error Reporting Interface
p_in_cfg_err_cor_out      : in   std_logic;
p_in_cfg_err_nonfatal_out : in   std_logic;
p_in_cfg_err_fatal_out    : in   std_logic;

p_in_cfg_fc_ph            : in   std_logic_vector( 7 downto 0);
p_in_cfg_fc_pd            : in   std_logic_vector(11 downto 0);
p_in_cfg_fc_nph           : in   std_logic_vector( 7 downto 0);
p_in_cfg_fc_npd           : in   std_logic_vector(11 downto 0);
p_in_cfg_fc_cplh          : in   std_logic_vector( 7 downto 0);
p_in_cfg_fc_cpld          : in   std_logic_vector(11 downto 0);
p_out_cfg_fc_sel          : out  std_logic_vector( 2 downto 0);

p_out_cfg_dsn                         : out  std_logic_vector(63 downto 0);
p_out_cfg_power_state_change_ack      : out  std_logic;
p_in_cfg_power_state_change_interrupt : in   std_logic;
p_out_cfg_err_cor_in                  : out  std_logic;
p_out_cfg_err_uncor_in                : out  std_logic;

p_in_cfg_flr_in_process       : in   std_logic_vector(3 downto 0);
p_out_cfg_flr_done            : out  std_logic_vector(3 downto 0);
p_in_cfg_vf_flr_in_process    : in   std_logic_vector(7 downto 0);
p_out_cfg_vf_flr_done         : out  std_logic_vector(7 downto 0);

p_out_cfg_ds_port_number      : out  std_logic_vector(7 downto 0);
p_out_cfg_ds_bus_number       : out  std_logic_vector(7 downto 0);
p_out_cfg_ds_device_number    : out  std_logic_vector(4 downto 0);
p_out_cfg_ds_function_number  : out  std_logic_vector(2 downto 0);

------------------------------------
-- EP Only
------------------------------------
-- Interrupt Interface Signals
p_out_cfg_interrupt_int                 : out  std_logic_vector(3 downto 0) ;
p_out_cfg_interrupt_pending             : out  std_logic_vector(3 downto 0) ;
p_in_cfg_interrupt_sent                 : in   std_logic                    ;

p_in_cfg_interrupt_msi_enable           : in   std_logic_vector(1 downto 0) ;
p_in_cfg_interrupt_msi_vf_enable        : in   std_logic_vector(5 downto 0) ;
p_in_cfg_interrupt_msi_mmenable         : in   std_logic_vector(5 downto 0) ;
p_in_cfg_interrupt_msi_mask_update      : in   std_logic                    ;
p_in_cfg_interrupt_msi_data             : in   std_logic_vector(31 downto 0);
p_out_cfg_interrupt_msi_select          : out  std_logic_vector( 3 downto 0);
p_out_cfg_interrupt_msi_int             : out  std_logic_vector(31 downto 0);
p_out_cfg_interrupt_msi_pending_status  : out  std_logic_vector(31 downto 0);
p_in_cfg_interrupt_msi_sent             : in   std_logic                    ;
p_in_cfg_interrupt_msi_fail             : in   std_logic                    ;
p_out_cfg_interrupt_msi_attr            : out  std_logic_vector(2 downto 0) ;
p_out_cfg_interrupt_msi_tph_present     : out  std_logic                    ;
p_out_cfg_interrupt_msi_tph_type        : out  std_logic_vector(1 downto 0) ;
p_out_cfg_interrupt_msi_tph_st_tag      : out  std_logic_vector(8 downto 0) ;
p_out_cfg_interrupt_msi_function_number : out  std_logic_vector(3 downto 0) ;
p_out_cfg_interrupt_msi_pending_status_data_enable  : out  std_logic;
p_out_cfg_interrupt_msi_pending_status_function_num : out  std_logic_vector(3 downto 0);

p_in_cfg_interrupt_msix_enable          : in  std_logic;
p_in_cfg_interrupt_msix_sent            : in  std_logic;
p_in_cfg_interrupt_msix_fail            : in  std_logic;
p_out_cfg_interrupt_msix_int            : out std_logic;
p_out_cfg_interrupt_msix_address        : out std_logic_vector(63 downto 0);
p_out_cfg_interrupt_msix_data           : out std_logic_vector(31 downto 0);

-- EP only
p_in_cfg_hot_reset_in   : in   std_logic;

-- RP only
p_out_cfg_hot_reset_out : out  std_logic;

p_in_user_clk    : in   std_logic;
p_in_user_reset  : in   std_logic;
p_in_user_lnk_up : in   std_logic
);
end entity pcie_ctrl;

architecture struct of pcie_ctrl is

signal i_pcie_prm              : TPCIE_cfgprm;

type TSR_flr_bus2 is array (0 to 1) of std_logic_vector(1 downto 0);
type TSR_flr_bus6 is array (0 to 1) of std_logic_vector(5 downto 0);
signal sr_cfg_flr_done         : TSR_flr_bus2;
signal sr_cfg_vf_flr_done      : TSR_flr_bus6;

signal i_trn_clk               : std_logic;
signal i_req_completion        : std_logic;
signal i_completion_done       : std_logic;
signal i_rst_n                 : std_logic;
signal i_pio_rst_n             : std_logic;

signal i_req_compl             : std_logic;
signal i_req_compl_ur          : std_logic;
signal i_compl_done            : std_logic;

signal i_req_prm               : TPCIE_reqprm;

signal i_ureg_di               : std_logic_vector(31 downto 0);
signal i_ureg_do               : std_logic_vector(31 downto 0);
signal i_ureg_wrbe             : std_logic_vector(3 downto 0);
signal i_ureg_wr               : std_logic;
signal i_ureg_rd               : std_logic;

signal i_d2h_buf_empty         : std_logic;
--signal i_d2h_buf_dbe            : std_logic_vector();
signal i_d2h_buf_d             : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
signal i_d2h_buf_rd            : std_logic;
signal i_d2h_buf_last          : std_logic;

signal i_h2d_buf_full          : std_logic;
--signal i_h2d_buf_dbe           : std_logic_vector();
signal i_h2d_buf_d             : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
signal i_h2d_buf_wr            : std_logic;
signal i_h2d_buf_last          : std_logic;

signal i_dma_init              : std_logic;
signal i_dma_prm               : TPCIE_dmaprm;
signal i_dma_mwr_en            : std_logic;
signal i_dma_mwr_done          : std_logic;
signal i_dma_mrd_en            : std_logic;
signal i_dma_mrd_done          : std_logic;
signal i_dma_mrd_rxdwcount     : std_logic_vector(31 downto 0);

signal i_axi_cq_tready         : std_logic;
signal i_axi_rc_tready         : std_logic;

signal i_interrupt_done        : std_logic;

signal i_pcie_irq_sent         : std_logic;
signal i_pcie_irq_pad          : std_logic;
signal i_pcie_irq_int          : std_logic;
signal i_pcie_irq_err          : std_logic;

signal i_uapp_irq_clr          : std_logic;
signal i_uapp_irq_set          : std_logic;
signal i_uapp_irq_ack          : std_logic;

signal tst_uapp_in             : std_logic_vector(127 downto 0);
signal tst_uapp_out            : std_logic_vector(127 downto 0);
signal tst_rx_out              : std_logic_vector(63 downto 0);
signal tst_tx_out              : std_logic_vector((280 * 2) - 1 downto (280 * 0));
signal i_dbg_probe             : std_logic_vector(269 downto 0);
signal tst_timeout_cnt         : unsigned(15 downto 0);
signal tst_timeout             : std_logic;

signal tst_axi_rq_tdata  : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
signal tst_axi_rq_tkeep  : std_logic_vector((G_DATA_WIDTH / 32) - 1  downto 0);
signal tst_axi_rq_tuser  : std_logic_vector(59 downto 0);
signal tst_axi_rq_tlast  : std_logic;
signal tst_axi_rq_tvalid : std_logic;
signal tst_axi_rq_tready : std_logic;

signal tst_axi_cc_tdata  : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
signal tst_axi_cc_tuser  : std_logic_vector(32 downto 0)              ;
signal tst_axi_cc_tlast  : std_logic                                  ;
signal tst_axi_cc_tkeep  : std_logic_vector((G_DATA_WIDTH / 32) - 1  downto 0);
signal tst_axi_cc_tvalid : std_logic                                  ;
signal tst_axi_cc_tready : std_logic_vector(3 downto 0)               ;

signal tst_dma_timeout_cnt         : unsigned(12 downto 0);
signal tst_dma_timeout             : std_logic;

--attribute keep : string;
--attribute keep of i_trn_clk : signal is "true";



begin --architecture struct of pcie_ctrl


i_trn_clk <= p_in_user_clk;

i_rst_n <= not p_in_user_reset;

i_pio_rst_n <= p_in_user_lnk_up and i_rst_n;

----------------------------------------
--Function level reset (FLR)
----------------------------------------
process(i_trn_clk, p_in_user_reset)
begin
if p_in_user_reset = '1' then
  for i in 0 to sr_cfg_flr_done'length - 1 loop
  sr_cfg_flr_done(i) <= (others => '0');
  end loop;

  for i in 0 to sr_cfg_vf_flr_done'length - 1 loop
  sr_cfg_vf_flr_done(i) <= (others => '0');
  end loop;

elsif rising_edge(i_trn_clk) then
  sr_cfg_flr_done <= p_in_cfg_flr_in_process(1 downto 0) & sr_cfg_flr_done(0 to 0);
  sr_cfg_vf_flr_done <= p_in_cfg_vf_flr_in_process(5 downto 0) & sr_cfg_vf_flr_done(0 to 0);

end if;
end process;

--detect rising edge of p_in_cfg_flr_in_process
p_out_cfg_flr_done(0) <= not sr_cfg_flr_done(1)(0) and sr_cfg_flr_done(0)(0);
p_out_cfg_flr_done(1) <= not sr_cfg_flr_done(1)(1) and sr_cfg_flr_done(0)(1);
p_out_cfg_flr_done(p_out_cfg_flr_done'high downto 2) <= (others => '0');

--detect rising edge of p_in_cfg_vf_flr_in_process
p_out_cfg_vf_flr_done(0) <= not sr_cfg_vf_flr_done(1)(0) and sr_cfg_vf_flr_done(0)(0);
p_out_cfg_vf_flr_done(1) <= not sr_cfg_vf_flr_done(1)(1) and sr_cfg_vf_flr_done(0)(1);
p_out_cfg_vf_flr_done(2) <= not sr_cfg_vf_flr_done(1)(2) and sr_cfg_vf_flr_done(0)(2);
p_out_cfg_vf_flr_done(3) <= not sr_cfg_vf_flr_done(1)(3) and sr_cfg_vf_flr_done(0)(3);
p_out_cfg_vf_flr_done(4) <= not sr_cfg_vf_flr_done(1)(4) and sr_cfg_vf_flr_done(0)(4);
p_out_cfg_vf_flr_done(5) <= not sr_cfg_vf_flr_done(1)(5) and sr_cfg_vf_flr_done(0)(5);
p_out_cfg_vf_flr_done(p_out_cfg_vf_flr_done'high downto 6) <= (others => '0');


----------------------------------------
--
----------------------------------------
p_out_cfg_ds_port_number     <= std_logic_vector(TO_UNSIGNED(16#00#, p_out_cfg_ds_port_number'length));
p_out_cfg_ds_bus_number      <= std_logic_vector(TO_UNSIGNED(16#00#, p_out_cfg_ds_bus_number'length));
p_out_cfg_ds_device_number   <= std_logic_vector(TO_UNSIGNED(16#00#, p_out_cfg_ds_device_number'length));
p_out_cfg_ds_function_number <= std_logic_vector(TO_UNSIGNED(16#00#, p_out_cfg_ds_function_number'length));

p_out_cfg_dsn <= std_logic_vector(TO_UNSIGNED(C_PCFG_FIRMWARE_VERSION, p_out_cfg_dsn'length));

p_out_cfg_err_cor_in   <= '0';
p_out_cfg_err_uncor_in <= '0';

-- RP only
p_out_cfg_hot_reset_out <= '0';


i_pcie_prm.link_width <= std_logic_vector(RESIZE(UNSIGNED(p_in_cfg_negotiated_width), i_pcie_prm.link_width'length));
i_pcie_prm.max_payload <= std_logic_vector(RESIZE(UNSIGNED(p_in_cfg_max_payload), i_pcie_prm.max_payload'length));
i_pcie_prm.max_rd_req <= std_logic_vector(RESIZE(UNSIGNED(p_in_cfg_max_read_req), i_pcie_prm.max_rd_req'length));
i_pcie_prm.master_en(0) <= p_in_cfg_function_status(2);


--######################################
--
--######################################
m_usr_app : pcie_usr_app
generic map(
G_SIM => G_SIM,
G_DBG => "OFF"
)
port map (
----------------------------------------
--USR Port
----------------------------------------
p_out_hclk      => p_out_hclk ,
p_out_gctrl     => p_out_gctrl,

--CTRL user devices
p_out_dev_ctrl  => p_out_dev_ctrl ,
p_out_dev_di   => p_out_dev_di  ,
p_in_dev_do     => p_in_dev_do  ,
p_out_dev_wr    => p_out_dev_wr   ,
p_out_dev_rd    => p_out_dev_rd   ,
p_in_dev_status => p_in_dev_status,
p_in_dev_irq    => p_in_dev_irq   ,
p_in_dev_opt    => p_in_dev_opt   ,
p_out_dev_opt   => p_out_dev_opt  ,

--DBG
p_out_tst       => tst_uapp_out,
p_in_tst        => tst_uapp_in ,

--------------------------------------
--PCIE_Rx/Tx  Port
--------------------------------------
p_in_pcie_prm => i_pcie_prm,

--Target mode
p_in_reg_adr   => i_req_prm.desc(0)(7 downto 0),
p_out_reg_do   => i_ureg_do(31 downto 0),
p_in_reg_di    => i_ureg_di(31 downto 0),
p_in_reg_wr    => i_ureg_wr,
p_in_reg_rd    => i_ureg_rd,

--Master mode
--(PC->FPGA)
--p_in_txbuf_dbe   =>
p_in_txbuf_di    => i_h2d_buf_d   ,
p_in_txbuf_wr    => i_h2d_buf_wr  ,
p_in_txbuf_last  => i_h2d_buf_last,
p_out_txbuf_full => i_h2d_buf_full,


--(PC<-FPGA)
--p_in_rxbuf_dbe    =>
p_out_rxbuf_do    => i_d2h_buf_d   ,
p_in_rxbuf_rd     => i_d2h_buf_rd   ,
p_in_rxbuf_last   => i_d2h_buf_last ,
p_out_rxbuf_empty => i_d2h_buf_empty,

--DMATRN
p_out_dmatrn_init => i_dma_init,
p_out_dma_prm     => i_dma_prm ,

--DMA MEMWR (PC<-FPGA)
p_out_dma_mwr_en   => i_dma_mwr_en  ,
p_in_dma_mwr_done  => i_dma_mwr_done,

--DMA MEMRD (PC->FPGA)
p_out_dma_mrd_en      => i_dma_mrd_en,
p_in_dma_mrd_rcv_size => (others => '0'),
p_in_dma_mrd_rcv_err  => '0',
p_in_dma_mrd_done     => i_dma_mrd_done,

--IRQ
p_out_irq_clr      => i_uapp_irq_clr,
p_out_irq_set      => i_uapp_irq_set,
p_in_irq_ack       => i_uapp_irq_ack,

--System
p_in_clk   => i_trn_clk,
p_in_rst_n => i_rst_n
);

p_out_tst(126 downto 0) <= tst_uapp_out(126 downto 0);
p_out_tst(127) <= i_pcie_irq_err;
tst_uapp_in(0) <= tst_rx_out(32 + 10);--axi_rc_err_detect;



--######################################
--
--######################################
gen_cq_trdy : for i in 0 to p_out_axi_cq_tready'length - 1 generate begin
p_out_axi_cq_tready(i) <= i_axi_cq_tready;
end generate gen_cq_trdy;

gen_rc_trdy : for i in 0 to p_out_axi_rc_tready'length - 1 generate begin
p_out_axi_rc_tready(i) <= i_axi_rc_tready;
end generate gen_rc_trdy;

m_rx : pcie_rx
generic map (
G_DATA_WIDTH => G_DATA_WIDTH
)
port map (
--Completer Request Interface
p_in_axi_cq_tdata   => p_in_axi_cq_tdata ,
p_in_axi_cq_tlast   => p_in_axi_cq_tlast ,
p_in_axi_cq_tvalid  => p_in_axi_cq_tvalid,
p_in_axi_cq_tuser   => p_in_axi_cq_tuser ,
p_in_axi_cq_tkeep   => p_in_axi_cq_tkeep ,
p_out_axi_cq_tready => i_axi_cq_tready   ,

p_in_pcie_cq_np_req_count => p_in_pcie_cq_np_req_count,
p_out_pcie_cq_np_req      => p_out_pcie_cq_np_req     ,

--Requester Completion Interface
p_in_axi_rc_tdata    => p_in_axi_rc_tdata ,
p_in_axi_rc_tlast    => p_in_axi_rc_tlast ,
p_in_axi_rc_tvalid   => p_in_axi_rc_tvalid,
p_in_axi_rc_tkeep    => p_in_axi_rc_tkeep ,
p_in_axi_rc_tuser    => p_in_axi_rc_tuser ,
p_out_axi_rc_tready  => i_axi_rc_tready   ,

--RX Message Interface
p_in_cfg_msg_received      => p_in_cfg_msg_received     ,
p_in_cfg_msg_received_type => p_in_cfg_msg_received_type,
p_in_cfg_msg_data          => p_in_cfg_msg_received_data,

--Completion
p_out_req_compl    => i_req_compl   ,
p_out_req_compl_ur => i_req_compl_ur,
p_in_compl_done    => i_compl_done  ,

p_out_req_prm      => i_req_prm,

--DMA
p_in_dma_init      => i_dma_init    ,
p_in_dma_prm       => i_dma_prm     ,
p_in_dma_mrd_en    => i_dma_mrd_en  ,
p_out_dma_mrd_done => i_dma_mrd_done,
p_out_dma_mrd_rxdwcount => i_dma_mrd_rxdwcount,

--usr app
p_out_ureg_di  => i_ureg_di  ,
p_out_ureg_wrbe=> i_ureg_wrbe,
p_out_ureg_wr  => i_ureg_wr  ,
p_out_ureg_rd  => i_ureg_rd  ,

--p_out_utxbuf_be   => i_h2d_buf_dbe
p_out_utxbuf_di   => i_h2d_buf_d  ,
p_out_utxbuf_wr   => i_h2d_buf_wr  ,
p_out_utxbuf_last => i_h2d_buf_last,
p_in_utxbuf_full  => i_h2d_buf_full,

--DBG
p_out_tst => tst_rx_out,

--system
p_in_clk   => i_trn_clk,
p_in_rst_n => i_rst_n
);



--######################################
--
--######################################
p_out_axi_rq_tdata  <= tst_axi_rq_tdata ;
p_out_axi_rq_tkeep  <= tst_axi_rq_tkeep ;
p_out_axi_rq_tlast  <= tst_axi_rq_tlast ;
p_out_axi_rq_tvalid <= tst_axi_rq_tvalid;
p_out_axi_rq_tuser  <= tst_axi_rq_tuser ;
tst_axi_rq_tready  <= p_in_axi_rq_tready(0);

p_out_axi_cc_tdata  <= tst_axi_cc_tdata    ;
p_out_axi_cc_tkeep  <= tst_axi_cc_tkeep    ;
p_out_axi_cc_tlast  <= tst_axi_cc_tlast    ;
p_out_axi_cc_tvalid <= tst_axi_cc_tvalid   ;
p_out_axi_cc_tuser  <= tst_axi_cc_tuser    ;
tst_axi_cc_tready  <= p_in_axi_cc_tready;

m_tx : pcie_tx
generic map (
G_TXRQ_ENABLE_CLIENT_TAG => 0,
G_DATA_WIDTH => G_DATA_WIDTH
)
port map(
--AXI-S Completer Competion Interface
p_out_axi_cc_tdata  => tst_axi_cc_tdata    ,--p_out_axi_cc_tdata   ,
p_out_axi_cc_tkeep  => tst_axi_cc_tkeep    ,--p_out_axi_cc_tkeep   ,
p_out_axi_cc_tlast  => tst_axi_cc_tlast    ,--p_out_axi_cc_tlast   ,
p_out_axi_cc_tvalid => tst_axi_cc_tvalid   ,--p_out_axi_cc_tvalid  ,
p_out_axi_cc_tuser  => tst_axi_cc_tuser    ,--p_out_axi_cc_tuser   ,
p_in_axi_cc_tready  => tst_axi_cc_tready(0),--p_in_axi_cc_tready(0),

--AXI-S Requester Request Interface
p_out_axi_rq_tdata  => tst_axi_rq_tdata   ,--p_out_axi_rq_tdata   ,
p_out_axi_rq_tkeep  => tst_axi_rq_tkeep   ,--p_out_axi_rq_tkeep   ,
p_out_axi_rq_tlast  => tst_axi_rq_tlast   ,--p_out_axi_rq_tlast   ,
p_out_axi_rq_tvalid => tst_axi_rq_tvalid  ,--p_out_axi_rq_tvalid  ,
p_out_axi_rq_tuser  => tst_axi_rq_tuser   ,--p_out_axi_rq_tuser ,
p_in_axi_rq_tready  => tst_axi_rq_tready  ,--p_in_axi_rq_tready(0),

--TX Message Interface
p_in_cfg_msg_transmit_done  => p_in_cfg_msg_transmit_done ,
p_out_cfg_msg_transmit      => p_out_cfg_msg_transmit     ,
p_out_cfg_msg_transmit_type => p_out_cfg_msg_transmit_type,
p_out_cfg_msg_transmit_data => p_out_cfg_msg_transmit_data,

--Tag availability and Flow control Information
p_in_pcie_rq_tag          => p_in_pcie_rq_tag         ,
p_in_pcie_rq_tag_vld      => p_in_pcie_rq_tag_vld     ,
p_in_pcie_rq_seq_num      => p_in_pcie_rq_seq_num     ,
p_in_pcie_rq_seq_num_vld  => p_in_pcie_rq_seq_num_vld ,
p_in_pcie_tfc_nph_av      => p_in_pcie_tfc_nph_av     ,
p_in_pcie_tfc_npd_av      => p_in_pcie_tfc_npd_av     ,
p_in_pcie_tfc_np_pl_empty => p_in_pcie_tfc_np_pl_empty,

--Cfg Flow Control Information
p_in_cfg_fc_ph   => p_in_cfg_fc_ph  ,
p_in_cfg_fc_nph  => p_in_cfg_fc_nph ,
p_in_cfg_fc_cplh => p_in_cfg_fc_cplh,
p_in_cfg_fc_pd   => p_in_cfg_fc_pd  ,
p_in_cfg_fc_npd  => p_in_cfg_fc_npd ,
p_in_cfg_fc_cpld => p_in_cfg_fc_cpld,
p_out_cfg_fc_sel => p_out_cfg_fc_sel,

--Completion
p_in_req_compl    => i_req_compl   ,
p_in_req_compl_ur => i_req_compl_ur,
p_out_compl_done  => i_compl_done  ,

p_in_req_prm  => i_req_prm,

p_in_pcie_prm => i_pcie_prm,

p_in_completer_id => (others => '0'),

--usr app
p_in_ureg_do => i_ureg_do,

p_in_urxbuf_empty => i_d2h_buf_empty,
p_in_urxbuf_do    => i_d2h_buf_d    ,
p_out_urxbuf_rd   => i_d2h_buf_rd   ,
p_out_urxbuf_last => i_d2h_buf_last ,

--DMA
p_in_dma_init      => i_dma_init    ,
p_in_dma_prm       => i_dma_prm     ,
p_in_dma_mwr_en    => i_dma_mwr_en  ,
p_out_dma_mwr_done => i_dma_mwr_done,
p_in_dma_mrd_en    => i_dma_mrd_en  ,
p_out_dma_mrd_done => open,--i_dma_mrd_done,
p_in_dma_mrd_rxdwcount => i_dma_mrd_rxdwcount,

--DBG
p_out_tst => tst_tx_out,

--system
p_in_clk   => i_trn_clk,
p_in_rst_n => i_rst_n
); --pcie_tx



--######################################
--
--######################################
m_irq : pcie_irq
port map (
-----------------------------
--Usr Ctrl
-----------------------------
p_in_irq_clr  => i_uapp_irq_clr,
p_in_irq_set  => i_uapp_irq_set,
p_out_irq_ack => i_uapp_irq_ack,

-----------------------------
--PCIE Port
-----------------------------
p_in_cfg_msi_fail => p_in_cfg_interrupt_msi_fail,
p_in_cfg_msi      => p_in_cfg_interrupt_msi_enable(0),
p_in_cfg_irq_rdy  => i_pcie_irq_sent,
p_out_cfg_irq_pad => i_pcie_irq_pad,
p_out_cfg_irq_int => i_pcie_irq_int,
p_out_cfg_irq_err => i_pcie_irq_err,

-----------------------------
--SYSTEM
-----------------------------
p_in_clk => i_trn_clk,
p_in_rst_n => i_rst_n
);

i_pcie_irq_sent <= p_in_cfg_interrupt_sent when p_in_cfg_interrupt_msi_enable(0) = '0' else
                   p_in_cfg_interrupt_msi_sent;

--Legacy Intterrupt
--bit(0) - PCI_EXPRESS_LEGACY_INTA
--bit(1) - PCI_EXPRESS_LEGACY_INTB
--bit(2) - PCI_EXPRESS_LEGACY_INTC
--bit(3) - PCI_EXPRESS_LEGACY_INTD
p_out_cfg_interrupt_int(0) <= i_pcie_irq_int and not p_in_cfg_interrupt_msi_enable(0);
p_out_cfg_interrupt_int(p_out_cfg_interrupt_int'high downto 1) <= (others => '0');

--bit(0) - Function 0
--bit(1) - Function 1
p_out_cfg_interrupt_pending(0) <= i_pcie_irq_pad and not p_in_cfg_interrupt_msi_enable(0);
p_out_cfg_interrupt_pending(p_out_cfg_interrupt_pending'high downto 1) <= (others => '0');


--MSI Intterrupt
p_out_cfg_interrupt_msi_select <= (others => '0'); --Value 0000b-0001b correspond to PF0-1

p_out_cfg_interrupt_msi_int(0) <= i_pcie_irq_int and p_in_cfg_interrupt_msi_enable(0);
p_out_cfg_interrupt_msi_int(31 downto 1) <= (others => '0');

p_out_cfg_interrupt_msi_pending_status(0) <= i_pcie_irq_pad and p_in_cfg_interrupt_msi_enable(0);
p_out_cfg_interrupt_msi_pending_status(31 downto 1) <= (others => '0');

p_out_cfg_interrupt_msi_attr            <= (others => '0');
p_out_cfg_interrupt_msi_tph_present     <= '0';
p_out_cfg_interrupt_msi_tph_type        <= (others => '0');
p_out_cfg_interrupt_msi_tph_st_tag      <= (others => '0');
p_out_cfg_interrupt_msi_function_number <= (others => '0');
p_out_cfg_interrupt_msi_pending_status_data_enable  <= '0';
p_out_cfg_interrupt_msi_pending_status_function_num <= (others => '0');

p_out_cfg_interrupt_msix_int            <= '0';
p_out_cfg_interrupt_msix_address        <= (others => '0');
p_out_cfg_interrupt_msix_data           <= (others => '0');


--######################################
--
--######################################
i_req_completion <= i_req_compl or i_req_compl_ur;
i_completion_done <= i_compl_done;-- or i_interrupt_done;

m_pio_to_ctrl : pio_to_ctrl
port map(
clk       => i_trn_clk,
rst_n     => i_pio_rst_n,

req_compl  => i_req_completion,
compl_done => i_completion_done,

cfg_power_state_change_interrupt => p_in_cfg_power_state_change_interrupt,
cfg_power_state_change_ack       => p_out_cfg_power_state_change_ack
);



--#############################################
--DBG
--#############################################
p_out_dbg.dev_num    <= tst_uapp_out(120 downto 117);-- i_reg.dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT); --(22..19)
p_out_dbg.dma_dir    <= tst_uapp_out(62)            ;-- i_reg.dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT);
p_out_dbg.dma_bufnum <= tst_uapp_out(72 downto 65)  ;-- <= i_dmabuf_num_cnt;
p_out_dbg.dma_done   <= tst_uapp_out(73)            ;-- <= i_dmatrn_done;
p_out_dbg.dma_init   <= tst_uapp_out(74)            ;-- <= i_dmatrn_init;
p_out_dbg.dma_work   <= tst_uapp_out(126)           ; --i_dma_work

--PCIE<-FPGA (DMA_WR/RD)
p_out_dbg.axi_rq_tready <= tst_axi_rq_tready;
p_out_dbg.axi_rq_tvalid <= tst_axi_rq_tvalid;
p_out_dbg.axi_rq_tlast  <= tst_axi_rq_tlast;
p_out_dbg.axi_rq_tkeep(3 downto 0) <= tst_axi_rq_tkeep(3 downto 0);

p_out_dbg.axi_rq_tdata(0) <= tst_axi_rq_tdata((32 * 1) - 1 downto (32 * 0));
p_out_dbg.axi_rq_tdata(1) <= tst_axi_rq_tdata((32 * 2) - 1 downto (32 * 1));
p_out_dbg.axi_rq_tdata(2) <= tst_axi_rq_tdata((32 * 3) - 1 downto (32 * 2));
--p_out_dbg.axi_rq_tuser  <= tst_axi_rq_tuser(7 downto 0);

--PCIE->FPGA (USR_WR/RD)
p_out_dbg.axi_cq_tready <= i_axi_cq_tready   ;
p_out_dbg.axi_cq_tvalid <= p_in_axi_cq_tvalid;
p_out_dbg.axi_cq_tlast  <= p_in_axi_cq_tlast ;

--PCIE->FPGA (DMA_RD(CPL))
p_out_dbg.axi_rc_err_detect <= tst_rx_out(32 + 10);--i_err_detect;
p_out_dbg.axi_rc_fsm <= tst_rx_out((32 + 2) downto (32 + 0));
p_out_dbg.axi_rc_tready <= i_axi_rc_tready   ;
p_out_dbg.axi_rc_tvalid <= p_in_axi_rc_tvalid;
p_out_dbg.axi_rc_tlast  <= p_in_axi_rc_tlast ;
p_out_dbg.axi_rc_tkeep(3 downto 0) <= p_in_axi_rc_tkeep(3 downto 0);
p_out_dbg.axi_rc_tdata(0) <= p_in_axi_rc_tdata((32 * 1) - 1 downto (32 * 0));
p_out_dbg.axi_rc_tdata(1) <= p_in_axi_rc_tdata((32 * 2) - 1 downto (32 * 1));
p_out_dbg.axi_rc_tdata(2) <= p_in_axi_rc_tdata((32 * 3) - 1 downto (32 * 2));
p_out_dbg.axi_rc_sof(0) <= p_in_axi_rc_tuser(32);
p_out_dbg.axi_rc_sof(1) <= p_in_axi_rc_tuser(33);
p_out_dbg.axi_rc_discon <= p_in_axi_rc_tuser(42);

--PCIE<-FPGA (USR_RD(CPL))
p_out_dbg.axi_cc_tready <= tst_axi_cc_tready(0);
p_out_dbg.axi_cc_tvalid <= tst_axi_cc_tvalid   ;
p_out_dbg.axi_cc_tlast  <= tst_axi_cc_tlast    ;
p_out_dbg.axi_cc_tkeep(3 downto 0) <= tst_axi_cc_tkeep(3 downto 0);

p_out_dbg.req_compl <= i_req_compl;
p_out_dbg.compl_done <= i_compl_done;

p_out_dbg.d2h_buf_rd    <= i_d2h_buf_rd;
p_out_dbg.d2h_buf_empty <= i_d2h_buf_empty;

p_out_dbg.h2d_buf_wr <= i_h2d_buf_wr;
p_out_dbg.h2d_buf_full <= i_h2d_buf_full;

p_out_dbg.irq_int <= i_pcie_irq_int;
p_out_dbg.irq_pending <= i_pcie_irq_pad;
p_out_dbg.irq_sent <= i_pcie_irq_sent;

p_out_dbg.test_speed <= tst_uapp_out(122);--   <= i_reg.pcie(C_HREG_PCIE_SPEED_TESTING_BIT);

p_out_dbg.dma_mrd_rxdwcount <= i_dma_mrd_rxdwcount;
p_out_dbg.axi_rc_err <= tst_rx_out((32 + 9) downto (32 + 3));

--p_out_dbg.irq_set <= tst_uapp_out(111 downto 109);--tst_uapp_out(116 downto 109) <= std_logic_vector(RESIZE(UNSIGNED(i_irq_set(C_HIRQ_COUNT - 1 downto 0)), 8));

--p_out_dbg.dma_bufadr <= i_dma_prm.addr;
--p_out_dbg.dma_bufsize<= i_dma_prm.len;

--p_out_dbg.cfg_fc_ph   <= p_in_cfg_fc_ph       ;--: in   std_logic_vector( 7 downto 0);
--p_out_dbg.cfg_fc_pd   <= p_in_cfg_fc_pd       ;--: in   std_logic_vector(11 downto 0);
--p_out_dbg.cfg_fc_nph  <= p_in_cfg_fc_nph      ;--: in   std_logic_vector( 7 downto 0);
--p_out_dbg.cfg_fc_npd  <= p_in_cfg_fc_npd      ;--: in   std_logic_vector(11 downto 0);
--p_out_dbg.cfg_fc_cplh <= p_in_cfg_fc_cplh     ;--: in   std_logic_vector( 7 downto 0);
--p_out_dbg.cfg_fc_cpld <= p_in_cfg_fc_cpld     ;--: in   std_logic_vector(11 downto 0);
--
--p_out_dbg.tfc_nph_av  <= p_in_pcie_tfc_nph_av ;--: in   std_logic_vector(1 downto 0);
--p_out_dbg.tfc_npd_av  <= p_in_pcie_tfc_npd_av ;--: in   std_logic_vector(1 downto 0);

end architecture struct;


