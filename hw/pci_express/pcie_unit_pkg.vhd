-------------------------------------------------------------------------
-- Company     : Linkos
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
use work.prj_def.all;
use work.prj_cfg.all;


package pcie_unit_pkg is

component pcie_usr_app
generic(
G_DBG : string :="OFF"
);
port(
-------------------------------------------------------
--Связь с Пользовательским проектом
-------------------------------------------------------
p_out_hclk      : out   std_logic;
p_out_gctrl     : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--Управление внешними устройствами
p_out_dev_ctrl  : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din   : out   std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_in_dev_dout   : in    std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_out_dev_wr    : out   std_logic;
p_out_dev_rd    : out   std_logic;
p_in_dev_status : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq    : in    std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
p_in_dev_opt    : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
p_out_dev_opt   : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

--Технологический порт
p_out_tst       : out   std_logic_vector(127 downto 0);
p_in_tst        : in    std_logic_vector(127 downto 0);


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
p_out_mwr_en                   : out   std_logic;
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
p_out_mrd_en                   : out   std_logic;
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
p_out_irq_num                  : out   std_logic_vector(4 downto 0);
p_out_irq_set                  : out   std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
p_in_irq_status                : in    std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);

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
p_in_irq_num           : in   std_logic_vector(4 downto 0);
p_in_irq_set           : in   std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
p_out_irq_status       : out  std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);

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






