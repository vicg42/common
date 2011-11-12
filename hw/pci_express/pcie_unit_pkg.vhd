-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11.11.2011 9:49:09
-- Module Name : pcie_unit_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.vicg_common_pkg.all;

package pcie_unit_pkg is

component pcie_usr_app
generic(
G_DBG : string :="OFF"
);
port(
-------------------------------------------------------
--Связь с Пользовательским проектом
-------------------------------------------------------
p_out_hclk                 : out   std_logic;
p_out_gctrl                : out   std_logic_vector(31 downto 0);

--Управление внешними устройствами
p_out_dev_ctrl             : out   std_logic_vector(31 downto 0);
p_out_dev_din              : out   std_logic_vector(31 downto 0);
p_in_dev_dout              : in    std_logic_vector(31 downto 0);
p_out_dev_wr               : out   std_logic;
p_out_dev_rd               : out   std_logic;
p_in_dev_status            : in    std_logic_vector(31 downto 0);
p_in_dev_irq               : in    std_logic_vector(31 downto 0);
p_in_dev_opt               : in    std_logic_vector(127 downto 0);
p_out_dev_opt              : out   std_logic_vector(127 downto 0);

--Технологический порт
p_out_tst                  : out   std_logic_vector(127 downto 0);
p_in_tst                   : in    std_logic_vector(127 downto 0);


--------------------------------------
--Связь с модулями управления ядром PCI-Express
--------------------------------------
--Буфера данных Запись/Чтение (Режим Master)
--(PC->FPGA)
p_in_txbuf_din                 : in    std_logic_vector(31 downto 0);
p_in_txbuf_wr                  : in    std_logic;
p_in_txbuf_wr_last             : in    std_logic;
p_out_txbuf_full               : out   std_logic;
--p_in_txbuf_din_be              : in    std_logic_vector(3 downto 0);

--(PC<-FPGA)
p_out_rxbuf_dout               : out   std_logic_vector(31 downto 0);
p_in_rxbuf_rd                  : in    std_logic;
p_in_rxbuf_rd_last             : in    std_logic;
p_out_rxbuf_empty              : out   std_logic;
--p_in_tx_data_be                : in    std_logic_vector(3 downto 0);

--Регистры управления Запись/Чтение (Режим Target)
p_in_reg_adr                   : in    std_logic_vector(7 downto 0);
p_out_reg_dout                 : out   std_logic_vector(31 downto 0);
p_in_reg_din                   : in    std_logic_vector(31 downto 0);
p_in_reg_wr                    : in    std_logic;
p_in_reg_rd                    : in    std_logic;

--Инициализация DMATRN
p_out_dmatrn_init              : out   std_logic;

--Управление DMATRN_WR (PC<-FPGA) (MEMORY WRITE)
p_out_mwr_work                 : out   std_logic;
p_in_mwr_done                  : in    std_logic;
p_out_mwr_addr_up              : out   std_logic_vector(7 downto 0);
p_out_mwr_addr                 : out   std_logic_vector(31 downto 0);
p_out_mwr_len                  : out   std_logic_vector(31 downto 0);
p_out_mwr_count                : out   std_logic_vector(31 downto 0);
p_out_mwr_tlp_tc               : out   std_logic_vector(2 downto 0);
p_out_mwr_64b                  : out   std_logic;
p_out_mwr_phant_func_en1       : out   std_logic;
p_out_mwr_relaxed_order        : out   std_logic;
p_out_mwr_nosnoop              : out   std_logic;
p_out_mwr_tag                  : out   std_logic_vector(7 downto 0);
p_out_mwr_lbe                  : out   std_logic_vector(3 downto 0);
p_out_mwr_fbe                  : out   std_logic_vector(3 downto 0);

--Управление DMATRN_RD (PC->FPGA) (MEMORY READ)
p_out_mrd_work                 : out   std_logic;
p_out_mrd_addr_up              : out   std_logic_vector(7 downto 0);
p_out_mrd_addr                 : out   std_logic_vector(31 downto 0);
p_out_mrd_len                  : out   std_logic_vector(31 downto 0);
p_out_mrd_count                : out   std_logic_vector(31 downto 0);
p_out_mrd_tlp_tc               : out   std_logic_vector(2 downto 0);
p_out_mrd_64b                  : out   std_logic;
p_out_mrd_phant_func_en1       : out   std_logic;
p_out_mrd_relaxed_order        : out   std_logic;
p_out_mrd_nosnoop              : out   std_logic;
p_out_mrd_tag                  : out   std_logic_vector(7 downto 0);
p_out_mrd_lbe                  : out   std_logic_vector(3 downto 0);
p_out_mrd_fbe                  : out   std_logic_vector(3 downto 0);
p_in_mrd_rcv_size              : in    std_logic_vector(31 downto 0);
p_in_mrd_rcv_err               : in    std_logic;

--Связь с контроллером прерываний
p_out_irq_clr                  : out   std_logic;
p_out_irq_num                  : out   std_logic_vector(15 downto 0);
p_out_irq_set                  : out   std_logic_vector(15 downto 0);
p_in_irq_status                : in    std_logic_vector(15 downto 0);

--Сигналы управления работой ядра PCI-Express
p_out_trn_rnp_ok_n             : out   std_logic;
p_out_cpl_streaming            : out   std_logic;
p_out_rd_metering              : out   std_logic;
p_out_usr_max_payload_size     : out   std_logic_vector(2 downto 0);
p_out_usr_max_rd_req_size      : out   std_logic_vector(2 downto 0);

--Инф. ядра PCI-Express
p_in_cfg_irq_disable           : in    std_logic;
p_in_cfg_msi_enable            : in    std_logic;
p_in_cfg_cap_max_lnk_width     : in    std_logic_vector(5 downto 0);
p_in_cfg_neg_max_lnk_width     : in    std_logic_vector(5 downto 0);
p_in_cfg_cap_max_payload_size  : in    std_logic_vector(2 downto 0);
p_in_cfg_prg_max_payload_size  : in    std_logic_vector(2 downto 0);
p_in_cfg_prg_max_rd_req_size   : in    std_logic_vector(2 downto 0);
p_in_cfg_phant_func_en         : in    std_logic;
p_in_cfg_no_snoop_en           : in    std_logic;
p_in_cfg_ext_tag_en            : in    std_logic;

--//Тестирование
p_in_rx_engine_tst      : in    std_logic_vector(1 downto 0);
p_in_throttle_tst       : in    std_logic_vector(1 downto 0);
p_in_mrd_pkt_len_tst    : in    std_logic_vector(31 downto 0);
p_in_rx_engine_tst2     : in    std_logic_vector(9 downto 0);

p_in_clk                : in    std_logic;
p_in_rst_n              : in    std_logic
);
end component;

component pcie_rx
port(
usr_reg_adr_o       : out std_logic_vector(7 downto 0);
usr_reg_din_o       : out std_logic_vector(31 downto 0);
usr_reg_wr_o        : out std_logic;
usr_reg_rd_o        : out std_logic;

usr_txbuf_din_o     : out std_logic_vector(31 downto 0);
usr_txbuf_wr_o      : out std_logic;
usr_txbuf_wr_last_o : out std_logic;
usr_txbuf_full_i    : in  std_logic;
--usr_txbuf_dbe_o     : out  std_logic_vector(7 downto 0);

trn_rd              : in  std_logic_vector(63 downto 0);
trn_rrem_n          : in  std_logic_vector(7 downto 0);
trn_rsof_n          : in  std_logic;
trn_reof_n          : in  std_logic;
trn_rsrc_rdy_n      : in  std_logic;
trn_rsrc_dsc_n      : in  std_logic;
trn_rdst_rdy_n_o    : out std_logic;
trn_rbar_hit_n      : in  std_logic_vector(6 downto 0);

req_compl_o         : out std_logic;
compl_done_i        : in  std_logic;

req_addr_o          : out std_logic_vector(29 downto 0);
req_fmt_type_o      : out std_logic_vector(6 downto 0);
req_tc_o            : out std_logic_vector(2 downto 0);
req_td_o            : out std_logic;
req_ep_o            : out std_logic;
req_attr_o          : out std_logic_vector(1 downto 0);
req_len_o           : out std_logic_vector(9 downto 0);
req_rid_o           : out std_logic_vector(15 downto 0);
req_tag_o           : out std_logic_vector(7 downto 0);
req_be_o            : out std_logic_vector(7 downto 0);
req_expansion_rom_o : out std_logic;

trn_dma_init_i      : in  std_logic;

cpld_total_size_o   : out std_logic_vector(31 downto 0);
cpld_malformed_o    : out std_logic;

tst_o               : out std_logic_vector(1 downto 0);
tst2_o              : out std_logic_vector(9 downto 0);

clk                 : in  std_logic;
rst_n               : in  std_logic
);
end component;

component pcie_tx
port(
usr_reg_dout_i       : in  std_logic_vector(31 downto 0);

--usr_rxbuf_dbe        : out std_logic_vector(3 downto 0);
usr_rxbuf_dout_i     : in  std_logic_vector(31 downto 0);
usr_rxbuf_rd_o       : out std_logic;
usr_rxbuf_rd_last_o  : out std_logic;
usr_rxbuf_rd_fst_o   : out std_logic;
usr_rxbuf_empty_i    : in  std_logic;

trn_td               : out std_logic_vector(63 downto 0);
trn_trem_n           : out std_logic_vector(7 downto 0);
trn_tsof_n           : out std_logic;
trn_teof_n           : out std_logic;
trn_tsrc_rdy_n_o     : out std_logic;
trn_tsrc_dsc_n       : out std_logic;
trn_tdst_rdy_n       : in  std_logic;
trn_tdst_dsc_n       : in  std_logic;
trn_tbuf_av          : in  std_logic_vector(5 downto 0);

req_compl_i          : in  std_logic;
compl_done_o         : out std_logic;

req_addr_i           : in  std_logic_vector(29 downto 0);
req_fmt_type_i       : in  std_logic_vector(6 downto 0);
req_tc_i             : in  std_logic_vector(2 downto 0);
req_td_i             : in  std_logic;
req_ep_i             : in  std_logic;
req_attr_i           : in  std_logic_vector(1 downto 0);
req_len_i            : in  std_logic_vector(9 downto 0);
req_rid_i            : in  std_logic_vector(15 downto 0);
req_tag_i            : in  std_logic_vector(7 downto 0);
req_be_i             : in  std_logic_vector(7 downto 0);
req_expansion_rom_i  : in  std_logic;

trn_dma_init_i       : in  std_logic;

mwr_work_i           : in  std_logic;
mwr_len_i            : in  std_logic_vector(31 downto 0);
mwr_tag_i            : in  std_logic_vector(7 downto 0);
mwr_lbe_i            : in  std_logic_vector(3 downto 0);
mwr_fbe_i            : in  std_logic_vector(3 downto 0);
mwr_addr_i           : in  std_logic_vector(31 downto 0);
mwr_count_i          : in  std_logic_vector(31 downto 0);
mwr_done_o           : out std_logic;
mwr_tlp_tc_i         : in  std_logic_vector(2 downto 0);
mwr_64b_en_i         : in  std_logic;
mwr_phant_func_en1_i : in  std_logic;
mwr_addr_up_i        : in  std_logic_vector(7 downto 0);
mwr_relaxed_order_i  : in  std_logic;
mwr_nosnoop_i        : in  std_logic;

mrd_work_i           : in  std_logic;
mrd_len_i            : in  std_logic_vector(31 downto 0);
mrd_tag_i            : in  std_logic_vector(7 downto 0);
mrd_lbe_i            : in  std_logic_vector(3 downto 0);
mrd_fbe_i            : in  std_logic_vector(3 downto 0);
mrd_addr_i           : in  std_logic_vector(31 downto 0);
mrd_count_i          : in  std_logic_vector(31 downto 0);
mrd_tlp_tc_i         : in  std_logic_vector(2 downto 0);
mrd_64b_en_i         : in  std_logic;
mrd_phant_func_en1_i : in  std_logic;
mrd_addr_up_i        : in  std_logic_vector(7 downto 0);
mrd_relaxed_order_i  : in  std_logic;
mrd_nosnoop_i        : in  std_logic;
mrd_pkt_len_o        : out std_logic_vector(31 downto 0);
mrd_pkt_count_o      : out std_logic_vector(15 downto 0);

completer_id_i       : in  std_logic_vector(15 downto 0);
tag_ext_en_i         : in  std_logic;
mstr_enable_i        : in  std_logic;
max_payload_size_i   : in  std_logic_vector(2 downto 0);
max_rd_req_size_i    : in  std_logic_vector(2 downto 0);

clk                  : in  std_logic;
rst_n                : in  std_logic
);
end component;

component pcie_mrd_throttle
port(
init_rst_i          : in  std_logic;

mrd_work_i          : in  std_logic;
mrd_len_i           : in  std_logic_vector(31 downto 0);
mrd_pkt_count_i     : in  std_logic_vector(15 downto 0);

--cpld_found_i        : in  std_logic_vector(31 downto 0);
cpld_data_size_i    : in  std_logic_vector(31 downto 0);
cpld_malformed_i    : in  std_logic;
cpld_data_err_i     : in  std_logic;

cfg_rd_comp_bound_i : in  std_logic;
rd_metering_i       : in  std_logic;

mrd_work_o          : out std_logic;

clk                 : in  std_logic;
rst_n               : in  std_logic
);
end component;

component pcie_irq
port(
-----------------------------
--Usr Ctrl
-----------------------------
p_in_irq_clr           : in   std_logic;
p_in_irq_num           : in   std_logic_vector(15 downto 0);
p_in_irq_set           : in   std_logic_vector(15 downto 0);
p_out_irq_status       : out  std_logic_vector(15 downto 0);

-----------------------------
--Связь с ядром PCI-EXPRESS
-----------------------------
p_in_cfg_irq_dis       : in   std_logic;
p_in_cfg_msi           : in   std_logic;
p_in_cfg_irq_rdy_n     : in   std_logic;
p_out_cfg_irq_assert_n : out  std_logic;
p_out_cfg_irq_n        : out  std_logic;
p_out_cfg_irq_di       : out  std_logic_vector(7 downto 0);

-----------------------------
--Технологические сигналы
-----------------------------
p_in_tst               : in   std_logic_vector(31 downto 0);
p_out_tst              : out  std_logic_vector(31 downto 0);

-----------------------------
--SYSTEM
-----------------------------
p_in_clk               : in   std_logic;
p_in_rst               : in   std_logic
);
end component;

component pcie_off_on
port(
req_compl_i         : in   std_logic;
compl_done_i        : in   std_logic;

cfg_to_turnoff_n_i  : in   std_logic;
cfg_turnoff_ok_n_o  : out  std_logic;

clk                 : in   std_logic;
rst_n               : in   std_logic
);
end component;

component pcie_cfg
port(
cfg_bus_mstr_enable : in   std_logic;

cfg_dwaddr          : out  std_logic_vector(9 downto 0);
cfg_rd_en_n         : out  std_logic;
cfg_do              : in   std_logic_vector(31 downto 0);
cfg_rd_wr_done_n    : in   std_logic;

cfg_di              : out  std_logic_vector(31 downto 0);
cfg_byte_en_n       : out  std_logic_vector(3 downto 0);
cfg_wr_en_n         : out  std_logic;

cfg_cap_max_lnk_width    : out  std_logic_vector(5 downto 0);
cfg_cap_max_payload_size : out  std_logic_vector(2 downto 0);
cfg_msi_enable           : out  std_logic;

clk                 : in   std_logic;
rst_n               : in   std_logic
);
end component;


end pcie_unit_pkg;


package body pcie_unit_pkg is

end pcie_unit_pkg;






