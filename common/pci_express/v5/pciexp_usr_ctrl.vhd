-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.01
-- Module Name : pciexp_usr_ctrl.vhd
--
-- Description : Модуль пользовательского управления
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

entity pciexp_usr_ctrl is
generic(
G_DBG : string :="OFF"  --//В боевом проекте обязательно должно быть "OFF" - отладка с ChipScoupe
);
port(
--//-----------------------------------------------------
--//Связь с Пользовательским проектом
--//-----------------------------------------------------
p_out_hclk                 : out   std_logic;                    --//Тактовый сигнал для пользовательского проекта
p_out_gctrl                : out   std_logic_vector(31 downto 0);--//Вывод регистра C_HREG_GCTRL

--//Управление внешними устройствами
p_out_dev_ctrl             : out   std_logic_vector(31 downto 0);--//Вывод регистра C_HREG_DEV_CTRL
p_out_dev_din              : out   std_logic_vector(31 downto 0);--//Данные для уст-ва
p_in_dev_dout              : in    std_logic_vector(31 downto 0);--//Данные от уст-ва
p_out_dev_wd               : out   std_logic;                    --//запись
p_out_dev_rd               : out   std_logic;                    --//чтение
p_in_dev_flag              : in    std_logic_vector(7 downto 0); --//
p_in_dev_status            : in    std_logic_vector(31 downto 0);--//Статусы уст-в
p_in_dev_irq               : in    std_logic_vector(31 downto 0);--//Запросы на отпрвку перерывания от устройств
p_in_dev_option            : in    std_logic_vector(127 downto 0);

p_out_mem_bank1h           : out   std_logic_vector(15 downto 0);--//номер банка
p_out_mem_adr              : out   std_logic_vector(34 downto 0);--//адрес ОЗУ
p_out_mem_ce               : out   std_logic;                    --//Установка операции
p_out_mem_cw               : out   std_logic;                    --//Тип операции
p_out_mem_rd               : out   std_logic;                    --//Чтение
p_out_mem_wr               : out   std_logic;                    --//Запись
p_out_mem_term             : out   std_logic;                    --//Остановка операции
p_out_mem_be               : out   std_logic_vector(7 downto 0); --//Byte Enable
p_out_mem_din              : out   std_logic_vector(31 downto 0);
p_in_mem_dout              : in    std_logic_vector(31 downto 0);

p_in_mem_wf                : in    std_logic;--//статусы буферов ввода/вывода
p_in_mem_wpf               : in    std_logic;
p_in_mem_re                : in    std_logic;
p_in_mem_rpe               : in    std_logic;

--//Тестовые сигналы
p_out_usr_tst              : out   std_logic_vector(127 downto 0);
p_in_usr_tst               : in    std_logic_vector(127 downto 0);

--//Технологические сигналы
p_in_tst_cur_mwr_pkt_count : in    std_logic_vector(15 downto 0);
p_in_tst_cur_mrd_pkt_count : in    std_logic_vector(15 downto 0);
p_in_tst_rdy_del_inv       : in    std_logic;
p_in_tst_irq_ctrl          : in    std_logic_vector(4 downto 0);
p_out_tst_irq_ctrl_out     : out   std_logic_vector(3 downto 0);


--------------------------------------
--//Связь с m_RX_ENGINE/m_TX_ENGINE
--------------------------------------
--//Запись/Чтение пользовательских данных (Режим Master)
--p_in_usr_txbuf_din_be          : in    std_logic_vector(3 downto 0);
p_in_mst_usr_txbuf_din         : in    std_logic_vector(31 downto 0);
p_in_mst_usr_txbuf_wd          : in    std_logic;
p_in_mst_usr_txbuf_wd_last     : in    std_logic;
p_out_mst_usr_txbuf_full       : out   std_logic;

--p_in_mst_tx_data_be            : in    std_logic_vector(3 downto 0);
p_out_mst_usr_rxbuf_dout       : out   std_logic_vector(31 downto 0);
p_in_mst_usr_rxbuf_rd          : in    std_logic;
p_in_mst_usr_rxbuf_rd_last     : in    std_logic;
p_in_mst_usr_rxbuf_rd_start    : in    std_logic;
p_out_mst_usr_rxbuf_empty      : out   std_logic;

--//Запись/Чтение пользовательских данных(Режим Target)
p_in_trg_addr                  : in    std_logic_vector(7 downto 0);
p_out_trg_dout                 : out   std_logic_vector(31 downto 0);
p_in_trg_din                   : in    std_logic_vector(31 downto 0);
p_in_trg_wr                    : in    std_logic;
p_in_trg_rd                    : in    std_logic;


--//Сигналы инициализации транзакций DMA
p_out_trn_dma_rst              : out   std_logic;
p_out_trn_dma_init             : out   std_logic;--//Установка в исходное состояние модулей TX/RX ENGENE

--//Связь с контроллером прерываний
p_out_irq_clr                  : out   std_logic;
p_out_irq_num                  : out   std_logic_vector(15 downto 0);
p_out_irq_set                  : out   std_logic_vector(15 downto 0);
p_in_irq_status                : in    std_logic_vector(15 downto 0);

--//Сигналы управления работой ядра PCI-Express
p_out_trn_rnp_ok_n             : out   std_logic;
p_out_cpl_streaming            : out   std_logic;
p_out_rd_metering              : out   std_logic;

--//Сигналы управления транзакцией MEMORY WRITE (PC<-FPGA)
p_out_mwr_work                 : out   std_logic;                    --
p_in_mwr_done                  : in    std_logic;                    --
p_out_mwr_addr_up              : out   std_logic_vector(7 downto 0); --
p_out_mwr_addr                 : out   std_logic_vector(31 downto 0);--
p_out_mwr_len                  : out   std_logic_vector(31 downto 0);--Кол-во DWORD для payload оного пакета MWr (Размер не должен превышать занчения PCI-EXPRESS/Device Control Register/[7:5]-Max Payload Size)
p_out_mwr_count                : out   std_logic_vector(31 downto 0);--Кол-во пакетов MWr необходимое для передачи полного объема данных установленых ХОСТом (рег. C_HREG_DMAPRM_LEN)
p_out_mwr_tlp_tc               : out   std_logic_vector(2 downto 0); --
p_out_mwr_64b                  : out   std_logic;                    --
p_out_mwr_phant_func_en1       : out   std_logic;                    --
p_out_mwr_relaxed_order        : out   std_logic;                    --
p_out_mwr_nosnoop              : out   std_logic;                    --
p_out_mwr_tag                  : out   std_logic_vector(7 downto 0); --
p_out_mwr_lbe                  : out   std_logic_vector(3 downto 0); --
p_out_mwr_fbe                  : out   std_logic_vector(3 downto 0); --

--//Сигналы управления транзакцией MEMORY READ (PC->FPGA)
p_out_mrd_work                 : out   std_logic;                    --
p_out_mrd_addr_up              : out   std_logic_vector(7 downto 0); --
p_out_mrd_addr                 : out   std_logic_vector(31 downto 0);--
p_out_mrd_len                  : out   std_logic_vector(31 downto 0);--
p_out_mrd_count                : out   std_logic_vector(31 downto 0);--
p_out_mrd_tlp_tc               : out   std_logic_vector(2 downto 0); --
p_out_mrd_64b                  : out   std_logic;                    --
p_out_mrd_phant_func_en1       : out   std_logic;                    --
p_out_mrd_relaxed_order        : out   std_logic;                    --
p_out_mrd_nosnoop              : out   std_logic;                    --
p_out_mrd_tag                  : out   std_logic_vector(7 downto 0); --
p_out_mrd_lbe                  : out   std_logic_vector(3 downto 0); --
p_out_mrd_fbe                  : out   std_logic_vector(3 downto 0); --


p_in_cpld_total_size           : in    std_logic_vector(31 downto 0);

p_in_cpld_malformed            : in    std_logic;
p_in_cfg_irq_disable           : in    std_logic;
p_in_cfg_msi_enable            : in    std_logic;                   --//(0/1 - Legacy Interrupt/MSI)Тип рабочего прерывания для CORE PCIEXPRESS который установил Root Complex
p_in_cfg_cap_max_lnk_width     : in    std_logic_vector(5 downto 0);--//Запрашиваемое кол-во link линий у системы
p_in_cfg_neg_max_lnk_width     : in    std_logic_vector(5 downto 0);--//Разрешонное кол-во link линий системой
p_in_cfg_cap_max_payload_size  : in    std_logic_vector(2 downto 0);--//Запрашиваемый max_payload_size пакета у системы
p_in_cfg_prg_max_payload_size  : in    std_logic_vector(2 downto 0);--//Разрешонный max_payload_size пакета системой
p_in_cfg_prg_max_rd_req_size   : in    std_logic_vector(2 downto 0);--//Max read request size for the device when acting as the Requester
p_in_cfg_phant_func_en         : in    std_logic;                   --//
p_in_cfg_no_snoop_en           : in    std_logic;                   --//
p_in_cfg_ext_tag_en            : in    std_logic;                   --//


p_out_usr_prg_max_payload_size : out   std_logic_vector(2 downto 0);--//Разрешонный max_payload_size пакета системой
p_out_usr_prg_max_rd_req_size  : out   std_logic_vector(2 downto 0);--//Max read request size for the device when acting as the Requester

p_in_clk                : in    std_logic;
p_in_rst_n              : in    std_logic
);
end pciexp_usr_ctrl;

architecture behavioral of pciexp_usr_ctrl is

component bram_dma_params
port
(
addra : in   std_logic_vector(9 downto 0);
dina  : in   std_logic_vector(31 downto 0);
douta : out  std_logic_vector(31 downto 0);
ena   : in   std_logic;
wea   : in   std_logic_vector(0 downto 0);
clka  : in   std_logic;


addrb : in   std_logic_vector(9 downto 0);
dinb  : in   std_logic_vector(31 downto 0);
doutb : out  std_logic_vector(31 downto 0);
enb   : in   std_logic;
web   : in   std_logic_vector(0 downto 0);
clkb  : in   std_logic
);
end component;

signal i_cpld_done                 : std_logic;

signal i_mwr_payload_dw_result     : std_logic_vector(10 downto 0);
signal i_mwr_payload_dw_lsb        : std_logic_vector(10 downto 0);
signal i_mwr_payload_dw_msb        : std_logic;
signal i_mwr_payload_dw_lsb_ziro   : std_logic;
signal i_mwr_payload_byte_mux      : std_logic_vector(11 downto 0);
signal i_mwr_payload_byte_mux_ziro : std_logic;
signal i_mwr_payload_dw_carry      : std_logic;
signal i_mwr_count_result          : std_logic_vector(25 downto 0);
signal i_mwr_count_mux             : std_logic_vector(24 downto 0);
signal i_mwr_count_ziro            : std_logic;
signal i_mwr_fbe                   : std_logic_vector(3 downto 0);
signal i_mwr_lbe                   : std_logic_vector(3 downto 0);

signal i_mrd_payload_dw_result     : std_logic_vector(10 downto 0);
signal i_mrd_payload_dw_lsb        : std_logic_vector(10 downto 0);
signal i_mrd_payload_dw_msb        : std_logic;
signal i_mrd_payload_dw_lsb_ziro   : std_logic;
signal i_mrd_payload_byte_mux      : std_logic_vector(11 downto 0);
signal i_mrd_payload_byte_mux_ziro : std_logic;
signal i_mrd_payload_dw_carry      : std_logic;
signal i_mrd_count_result          : std_logic_vector(25 downto 0);
signal i_mrd_count_mux             : std_logic_vector(24 downto 0);
signal i_mrd_count_ziro            : std_logic;
signal i_mrd_fbe                   : std_logic_vector(3 downto 0);
signal i_mrd_lbe                   : std_logic_vector(3 downto 0);

signal i_cfg_prg_max_payload_size  : std_logic_vector(2 downto 0);
signal i_cfg_prg_max_rd_req_size   : std_logic_vector(2 downto 0);

signal i_trg_rd                    : std_logic;

signal v_reg_fpga_firmware         : std_logic_vector(C_HREG_FRMWARE_LAST_BIT downto 0);
signal v_reg_gctrl                 : std_logic_vector(C_HREG_GCTRL_LAST_BIT downto 0);
signal v_reg_dev_ctrl              : std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
signal v_reg_mem_adr               : std_logic_vector(C_HREG_MEM_ADR_LAST_BIT downto 0);
signal v_reg_irq_ctrl              : std_logic_vector(C_HREG_IRQ_LAST_WBIT downto 0);
signal v_reg_pcie_ctrl             : std_logic_vector(C_HREG_PCIE_CTRL_LAST_BIT downto 0);
signal v_reg_tst0                  : std_logic_vector(31 downto 0);
signal v_reg_tst1                  : std_logic_vector(31 downto 0);
signal v_reg_tst2                  : std_logic_vector(31 downto 0);

signal b_trn_start                 : std_logic;
signal b_trn_dir                   : std_logic;
signal b_dev_adr                   : std_logic_vector(C_HREG_DEV_CTRL_ADR_M_BIT - C_HREG_DEV_CTRL_ADR_L_BIT downto 0);
signal b_irq_num                   : std_logic_vector(C_HREG_IRQ_NUM_M_WBIT - C_HREG_IRQ_NUM_L_WBIT downto 0);
signal b_dmabuf_num                : std_logic_vector(C_HREG_DEV_CTRL_DMABUF_NUM_M_BIT - C_HREG_DEV_CTRL_DMABUF_NUM_L_BIT downto 0);
signal b_dmabuf_count              : std_logic_vector(C_HREG_DEV_CTRL_DMABUF_COUNT_M_BIT - C_HREG_DEV_CTRL_DMABUF_COUNT_L_BIT downto 0);

--signal i_trn_rst_sw                : std_logic;
signal i_trn_start_sw              : std_logic;
signal i_trn_dma_len               : std_logic_vector(31 downto 0);--//Размер транзакции в Byte
signal i_trn_dma_adr               : std_logic_vector(31 downto 0);
signal i_trn_mwr_work              : std_logic;
signal i_trn_mrd_work              : std_logic;

signal i_dma_init                  : std_logic;
signal i_dma_init_sw               : std_logic;
signal i_dma_start_sw              : std_logic;
signal i_dma_init_hw               : std_logic;
signal i_dma_start_hw              : std_logic;
signal i_dma_work                  : std_logic;
signal i_dma_worktotal             : std_logic;
signal i_dma_mrd_donetotal         : std_logic;
signal i_dma_mwr_donetotal         : std_logic;
signal i_dma_mrd_done              : std_logic;
signal sr_dma_mrd_done             : std_logic;
signal i_dma_mwr_done              : std_logic;
signal sr_dma_mwr_done             : std_logic;
signal i_dma_irq_clr               : std_logic;

signal i_host_dmaprm_adr           : std_logic_vector(9 downto 0);
signal i_host_dmaprm_din           : std_logic_vector(31 downto 0);
signal i_host_dmaprm_dout          : std_logic_vector(31 downto 0);
signal i_host_dmaprm_wr            : std_logic_vector(0 downto 0);

signal i_hw_dmaprm_cnt             : std_logic_vector(1 downto 0);
signal i_hw_dmaprm_adr             : std_logic_vector(9 downto 0);
signal i_hw_dmaprm_dout            : std_logic_vector(31 downto 0);
signal i_hw_dmaprm_rd              : std_logic_vector(0 downto 0);
signal i_hw_dmaprm_rd_done         : std_logic;
signal sr_hw_dmaprm_cnt            : std_logic_vector(1 downto 0);
signal sr_hw_dmaprm_rd             : std_logic_vector(0 downto 0);
signal sr_hw_dmaprm_rd_done        : std_logic;

signal i_dmabuf_num_cnt            : std_logic_vector(b_dmabuf_num'range);
signal i_dmabuf_done_cnt           : std_logic_vector(b_dmabuf_count'range);

signal i_irq_clr                   : std_logic;
signal i_irq_en                    : std_logic_vector(15 downto 0);
signal i_irq_set                   : std_logic_vector(C_HIRQ_COUNT - 1 downto 0);
signal i_irq_set_edge              : std_logic_vector(15 downto 0);
Type TSRIrqSet is array (0 to C_HIRQ_COUNT-1) of std_logic_vector(0 to 1);
signal sr_irq_set                  : TSRIrqSet;

signal vrsk_reg_bar                : std_logic;
signal vrsk_reg_adr                : std_logic_vector(6 downto 0); --//Адреса регистров проекта VERESK-M

signal i_hrddone_vctrl             : std_logic;
signal i_hrddone_trcnik            : std_logic;
signal sr_mst_usr_rxbuf_rd_last    : std_logic;

signal i_dev_txd_rdy               : std_logic;
signal i_dev_txd_rdy_out           : std_logic;
signal i_dev_wd_reg                : std_logic;
signal i_dev_rd_reg                : std_logic;
signal i_dev_wd                    : std_logic;
signal i_dev_rd                    : std_logic;
signal i_dev_din                   : std_logic_vector(31 downto 0);

signal i_mem_ctrl_select           : std_logic;
signal i_mem_adr_offset            : std_logic_vector(C_HREG_MEM_ADR_BANK_L_BIT-1 downto 0);
signal i_mem_bank1h_out            : std_logic_vector(pwr((C_HREG_MEM_ADR_BANK_M_BIT-C_HREG_MEM_ADR_BANK_L_BIT+1), 2)-1 downto 0);

signal i_mem_mwr_term              : std_logic;
signal i_mem_mrd_term              : std_logic;
signal i_mem_cw                    : std_logic;
signal i_mem_ce                    : std_logic;
signal i_mem_term                  : std_logic;
signal i_mem_rd                    : std_logic;
signal i_mem_wr                    : std_logic;
signal i_mem_adr                   : std_logic_vector(34 downto 0);
signal i_mem_bank1h                : std_logic_vector(15 downto 0);
signal i_mem_din                   : std_logic_vector(31 downto 0);
signal i_mem_dout                  : std_logic_vector(31 downto 0);
signal i_mem_be                    : std_logic_vector(7 downto 0);
signal i_mem_wpf                   : std_logic;
signal i_mem_re                    : std_logic;

signal i_tst_rd                    : std_logic;

--MAIN
begin


p_out_hclk <=p_in_clk;

p_out_trn_dma_rst  <='0';--i_trn_rst_sw;
p_out_trn_dma_init <=i_dma_init;

--//Сигналы управления транзакцией MEMORY WRITE (PC<-FPGA)
p_out_mwr_work          <=i_trn_mwr_work;
p_out_mwr_addr_up       <=CONV_STD_LOGIC_VECTOR(10#00#, p_out_mwr_addr_up'length);
p_out_mwr_addr          <=i_trn_dma_adr(31 downto 2)&"00";--Адрес системной памяти ХОСТА (i_trn_dma_addr_out);
p_out_mwr_len           <=EXT(i_mwr_payload_dw_result, p_out_mwr_len'length);--//Размер одного пакета (полезной нагрузки)
p_out_mwr_count         <=EXT(i_mwr_count_result, p_out_mwr_count'length);   --//Кол-во пакетов
p_out_mwr_tlp_tc        <=CONV_STD_LOGIC_VECTOR(10#00#, p_out_mwr_tlp_tc'length);
p_out_mwr_64b           <='0';--//1/0 - 64b/32b
p_out_mwr_phant_func_en1<='0';
p_out_mwr_relaxed_order <=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_DMA_WD_RELEX_ORDER_BIT);
p_out_mwr_nosnoop       <=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_DMA_WD_NOSNOOP_BIT);
p_out_mwr_tag           <=CONV_STD_LOGIC_VECTOR(16#00#, p_out_mwr_tag'length);
p_out_mwr_fbe           <=i_mwr_fbe;
p_out_mwr_lbe           <=i_mwr_lbe;


--//Сигналы управления транзакцией MEMORY READ (PC->FPGA)
p_out_mrd_work          <=i_trn_mrd_work;
p_out_mrd_addr_up       <=CONV_STD_LOGIC_VECTOR(10#00#, p_out_mrd_addr_up'length);
p_out_mrd_addr          <=i_trn_dma_adr(31 downto 2)&"00";--Адрес системной памяти ХОСТА (i_trn_dma_addr_out);
p_out_mrd_len           <=EXT(i_mrd_payload_dw_result, p_out_mrd_len'length);--//Размер одного пакета (полезной нагрузки)
p_out_mrd_count         <=EXT(i_mrd_count_result, p_out_mrd_count'length);   --//Кол-во пакетов
p_out_mrd_tlp_tc        <=CONV_STD_LOGIC_VECTOR(10#00#, p_out_mrd_tlp_tc'length);
p_out_mrd_64b           <='0';--//1/0 - 64b/32b
p_out_mrd_phant_func_en1<='0';
p_out_mrd_relaxed_order <=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_DMA_RD_RELEX_ORDER_BIT);
p_out_mrd_nosnoop       <=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_DMA_RD_NOSNOOP_BIT);
p_out_mrd_tag           <=CONV_STD_LOGIC_VECTOR(16#00#, p_out_mrd_tag'length);
p_out_mrd_fbe           <=i_mrd_fbe;
p_out_mrd_lbe           <=i_mrd_lbe;


p_out_cpl_streaming     <=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_CPL_STREAMING_BIT);--//1/0 - рапрещено/разрешено
p_out_rd_metering       <=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_METRING_BIT);      --//0/1 - запрещено/разрешено
p_out_trn_rnp_ok_n      <=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_TRN_RNP_OK_BIT);   --//сигнализация ядру. '0'/'1' - user_app - готов/не готов принимать non-posted транзакции
                                                                              --//Если '1', то ядро может принимать только posetd и completion транзакции

--//-------------------------------------------------------
--//Связь с модулем управления прерываниями
--//-------------------------------------------------------
p_out_irq_clr <=i_irq_clr;

p_out_irq_num(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT)<=b_irq_num;
p_out_irq_num(15 downto C_HREG_IRQ_NUM_M_WBIT+1)<=(others=>'0');

--//Сигнализация модулю управления прерываниями - Установить прерывание:
--//от TRN DMA (WR/RD)
p_out_irq_set<=EXT(i_irq_set, p_out_irq_set'length);

i_irq_set(C_HIRQ_PCIE_DMA)<=i_irq_en(C_HIRQ_PCIE_DMA) and ((i_dma_mrd_donetotal and sr_dma_mrd_done) or
                                                               (i_dma_mwr_donetotal and sr_dma_mwr_done));

--//от пользовательских устройств
gen_irq_ch: for i in C_HIRQ_PCIE_DMA+1 to C_HIRQ_COUNT - 1 generate

i_irq_set(i)<=i_irq_en(i) and i_irq_set_edge(i);

--//Выделяю передний фронт из сигнала установки прерывания от соотв. источника
process(p_in_rst_n,p_in_clk)
begin
  if p_in_rst_n='0' then
      sr_irq_set(i)<=(others=>'0');
      i_irq_set_edge(i)<='0';
  elsif p_in_clk'event and p_in_clk='1' then
      sr_irq_set(i)<=p_in_dev_irq(i)& sr_irq_set(i)(0 to 0);
      i_irq_set_edge(i)<=not sr_irq_set(i)(1) and sr_irq_set(i)(0);
  end if;
end process;

end generate gen_irq_ch;



p_out_usr_prg_max_payload_size <=i_cfg_prg_max_payload_size;
p_out_usr_prg_max_rd_req_size  <=i_cfg_prg_max_rd_req_size;

--//--------------------------------------------------------------
--//Memory Write Request:
--//--------------------------------------------------------------
--//p_in_cfg_prg_max_payload_size: 000b = 128  byte max payload size
--//                               001b = 256  byte max payload size
--//                               010b = 512  byte max payload size
--//                               011b = 1024 byte max payload size
--//                               100b = 2048 byte max payload size
--//                               101b = 4096 byte max payload size
--//--------------------------------------------------------------
--//Вычисляем размер payload для последнего пакета(в DWORD)
--//--------------------------------------------------------------
i_cfg_prg_max_payload_size<=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_NEG_MAX_PAYLOAD_M_BIT downto C_HREG_PCIE_CTRL_NEG_MAX_PAYLOAD_L_BIT);

--//Выделяем кол-во байт одного пакета TPL из общего размера данных(i_trn_dma_len) установленых Хостом
--//В зависимости от значения (p_in_cfg_prg_max_payload_size) CFG региста PCI устройства
--i_mwr_payload_byte_mux(11 downto 0)<=(    i_trn_dma_len(11 downto 0)) when i_cfg_prg_max_payload_size="101" else
i_mwr_payload_byte_mux(11 downto 0)<=('0' & i_trn_dma_len(10 downto 0)) when i_cfg_prg_max_payload_size="100" else
                                     ("00" & i_trn_dma_len(9 downto 0))  when i_cfg_prg_max_payload_size="011" else
                                     ("000" & i_trn_dma_len(8 downto 0))  when i_cfg_prg_max_payload_size="010" else
                                     ("0000" & i_trn_dma_len(7 downto 0))  when i_cfg_prg_max_payload_size="001" else
                                     ("00000" & i_trn_dma_len(6 downto 0));--  when i_cfg_prg_max_payload_size="000" else

i_mwr_payload_byte_mux_ziro <='1' when i_mwr_payload_byte_mux=CONV_STD_LOGIC_VECTOR(16#00#,12) else '0';

--//Вычисляем сколько DWORD должен содержать один пакет
i_mwr_payload_dw_lsb(10 downto 0)<=('0'&i_mwr_payload_byte_mux(11 downto 2)) + ('0'&CONV_STD_LOGIC_VECTOR(16#00#, 9)&(i_trn_dma_len(1) or i_trn_dma_len(0)));

--i_mwr_payload_dw_lsb_ziro <='1' when (i_mwr_payload_dw_lsb(9 downto 0)="0000000000" and i_cfg_prg_max_payload_size="101") or
i_mwr_payload_dw_lsb_ziro <='1' when (i_mwr_payload_dw_lsb(8 downto 0)="000000000" and i_cfg_prg_max_payload_size="100") or
                                     (i_mwr_payload_dw_lsb(7 downto 0)="00000000" and i_cfg_prg_max_payload_size="011") or
                                     (i_mwr_payload_dw_lsb(6 downto 0)="0000000" and i_cfg_prg_max_payload_size="010") or
                                     (i_mwr_payload_dw_lsb(5 downto 0)="000000" and i_cfg_prg_max_payload_size="001") or
                                     (i_mwr_payload_dw_lsb(4 downto 0)="00000" and i_cfg_prg_max_payload_size="000") else '0';

--//Выделяем бит переноса в зависимости от i_cfg_prg_max_payload_size
--i_mwr_payload_dw_carry <= i_mwr_payload_dw_lsb(10) when i_cfg_prg_max_payload_size="101" else
i_mwr_payload_dw_carry <= i_mwr_payload_dw_lsb(9)  when i_cfg_prg_max_payload_size="100" else
                          i_mwr_payload_dw_lsb(8)  when i_cfg_prg_max_payload_size="011" else
                          i_mwr_payload_dw_lsb(7)  when i_cfg_prg_max_payload_size="010" else
                          i_mwr_payload_dw_lsb(6)  when i_cfg_prg_max_payload_size="001" else
                          i_mwr_payload_dw_lsb(5);

i_mwr_payload_dw_msb<='1' when i_mwr_count_ziro='0' and i_mwr_payload_dw_lsb_ziro='1' else i_mwr_payload_dw_carry;

--//Результат вычислений:
--i_mwr_payload_dw_result(10 downto 0)<=(     i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(9 downto 0)) when i_cfg_prg_max_payload_size="101" else
i_mwr_payload_dw_result(10 downto 0)<=('0' & i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(8 downto 0)) when i_cfg_prg_max_payload_size="100" else
                                      ("00" & i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(7 downto 0)) when i_cfg_prg_max_payload_size="011" else
                                      ("000" & i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(6 downto 0)) when i_cfg_prg_max_payload_size="010" else
                                      ("0000" & i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(5 downto 0)) when i_cfg_prg_max_payload_size="001" else
                                      ("00000" & i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(4 downto 0));


--//--------------------------------------------------------------------------------------------
--//Вычисляем кол-во пакетов, необходимое для передачи/чтения всего запрошеного размера данных
--//--------------------------------------------------------------------------------------------
--//Выделяем кол-во пакетов TPL из общего размера данных(i_trn_dma_len) установленых Хостом
--//В зависимости от значения (i_cfg_prg_max_payload_size) CFG региста PCI устройства
--i_mwr_count_mux(24 downto 0)<=("00000" & i_trn_dma_len(31 downto 12)) when i_cfg_prg_max_payload_size="101" else
i_mwr_count_mux(24 downto 0)<=("0000" & i_trn_dma_len(31 downto 11)) when i_cfg_prg_max_payload_size="100" else
                              ("000" & i_trn_dma_len(31 downto 10)) when i_cfg_prg_max_payload_size="011" else
                              ("00" & i_trn_dma_len(31 downto 9))  when i_cfg_prg_max_payload_size="010" else
                              ('0' & i_trn_dma_len(31 downto 8))  when i_cfg_prg_max_payload_size="001" else
                              (     i_trn_dma_len(31 downto 7));--  when i_cfg_prg_max_payload_size="000" else

i_mwr_count_ziro<='1' when i_mwr_count_mux=CONV_STD_LOGIC_VECTOR(16#00#,32) else '0';

--//Результат вычислений:
i_mwr_count_result(25 downto 0)<=('0'&i_mwr_count_mux) + ('0'& CONV_STD_LOGIC_VECTOR(16#00#, 24)& not i_mwr_payload_byte_mux_ziro);

--//--------------------------------------------------------------------------------------------
--//Вычисляем значения для ByteEnable для последнего пакета данных:
--//--------------------------------------------------------------------------------------------
i_mwr_fbe<="1111" when i_mwr_payload_dw_lsb(10 downto 0)>CONV_STD_LOGIC_VECTOR(16#01#,11) else
           "1111" when i_trn_dma_len(1 downto 0)="00" else
           "0001" when i_trn_dma_len(1 downto 0)="01" else
           "0011" when i_trn_dma_len(1 downto 0)="10" else
           "0111";

--//Byte enable last DWORD (TPL payload)
i_mwr_lbe<="0000" when i_mwr_payload_dw_lsb(10 downto 0)=CONV_STD_LOGIC_VECTOR(16#01#,11) else
           "1111" when i_trn_dma_len(1 downto 0)="00" else
           "0001" when i_trn_dma_len(1 downto 0)="01" else
           "0011" when i_trn_dma_len(1 downto 0)="10" else
           "0111";



--//--------------------------------------------------------------
--//Memory Read Request:
--//--------------------------------------------------------------
--//p_in_cfg_prg_max_rd_req_size : 000b = 128  byte max payload size
--//                               001b = 256  byte max payload size
--//                               010b = 512  byte max payload size
--//                               011b = 1024 byte max payload size
--//                               100b = 2048 byte max payload size
--//                               101b = 4096 byte max payload size
--//--------------------------------------------------------------
--//Вычисляем размер payload для последнего пакета(в DWORD)
--//--------------------------------------------------------------
i_cfg_prg_max_rd_req_size<=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_NEG_MAX_RD_REQ_M_BIT downto C_HREG_PCIE_CTRL_NEG_MAX_RD_REQ_L_BIT);

--//Выделяем кол-во байт одного пакета TPL из общего размера данных(i_trn_dma_len) установленых Хостом
--//В зависимости от значения (i_cfg_prg_max_rd_req_size) CFG региста PCI устройства
--i_mwr_payload_byte_mux(11 downto 0)<=(    i_trn_dma_len(11 downto 0)) when i_cfg_prg_max_rd_req_size="101" else
i_mrd_payload_byte_mux(11 downto 0)<=('0' & i_trn_dma_len(10 downto 0)) when i_cfg_prg_max_rd_req_size="100" else
                                     ("00" & i_trn_dma_len(9 downto 0))  when i_cfg_prg_max_rd_req_size="011" else
                                     ("000" & i_trn_dma_len(8 downto 0))  when i_cfg_prg_max_rd_req_size="010" else
                                     ("0000" & i_trn_dma_len(7 downto 0))  when i_cfg_prg_max_rd_req_size="001" else
                                     ("00000" & i_trn_dma_len(6 downto 0));--  when i_cfg_prg_max_rd_req_size="000" else

i_mrd_payload_byte_mux_ziro <='1' when i_mrd_payload_byte_mux=CONV_STD_LOGIC_VECTOR(16#00#,12) else '0';

--//Вычисляем сколько DWORD должен содержать один пакет
i_mrd_payload_dw_lsb(10 downto 0)<=('0'&i_mrd_payload_byte_mux(11 downto 2)) + ('0'&CONV_STD_LOGIC_VECTOR(16#00#, 9)&(i_trn_dma_len(1) or i_trn_dma_len(0)));

--i_mrd_payload_dw_lsb_ziro <='1' when (i_mrd_payload_dw_lsb(9 downto 0)="0000000000" and i_cfg_prg_max_rd_req_size="101") or
i_mrd_payload_dw_lsb_ziro <='1' when (i_mrd_payload_dw_lsb(8 downto 0)="000000000" and i_cfg_prg_max_rd_req_size="100") or
                                     (i_mrd_payload_dw_lsb(7 downto 0)="00000000" and i_cfg_prg_max_rd_req_size="011") or
                                     (i_mrd_payload_dw_lsb(6 downto 0)="0000000" and i_cfg_prg_max_rd_req_size="010") or
                                     (i_mrd_payload_dw_lsb(5 downto 0)="000000" and i_cfg_prg_max_rd_req_size="001") or
                                     (i_mrd_payload_dw_lsb(4 downto 0)="00000" and i_cfg_prg_max_rd_req_size="000") else '0';

--//Выделяем бит переноса в зависимости от i_cfg_prg_max_rd_req_size
--i_mrd_payload_dw_carry <= i_mrd_payload_dw_lsb(10) when i_cfg_prg_max_rd_req_size="101" else
i_mrd_payload_dw_carry <= i_mrd_payload_dw_lsb(9)  when i_cfg_prg_max_rd_req_size="100" else
                          i_mrd_payload_dw_lsb(8)  when i_cfg_prg_max_rd_req_size="011" else
                          i_mrd_payload_dw_lsb(7)  when i_cfg_prg_max_rd_req_size="010" else
                          i_mrd_payload_dw_lsb(6)  when i_cfg_prg_max_rd_req_size="001" else
                          i_mrd_payload_dw_lsb(5);

i_mrd_payload_dw_msb<='1' when i_mrd_count_ziro='0' and i_mrd_payload_dw_lsb_ziro='1' else i_mrd_payload_dw_carry;

--//Результат вычислений:
--i_mrd_payload_dw_result(10 downto 0)<=(     i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(9 downto 0)) when i_cfg_prg_max_rd_req_size="101" else
i_mrd_payload_dw_result(10 downto 0)<=('0' & i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(8 downto 0)) when i_cfg_prg_max_rd_req_size="100" else
                                      ("00" & i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(7 downto 0)) when i_cfg_prg_max_rd_req_size="011" else
                                      ("000" & i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(6 downto 0)) when i_cfg_prg_max_rd_req_size="010" else
                                      ("0000" & i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(5 downto 0)) when i_cfg_prg_max_rd_req_size="001" else
                                      ("00000" & i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(4 downto 0));


--//--------------------------------------------------------------------------------------------
--//Вычисляем кол-во пакетов, необходимое для передачи/чтения всего запрошеного размера данных
--//--------------------------------------------------------------------------------------------
--//Выделяем кол-во пакетов TPL из общего размера данных(i_trn_dma_len) установленых Хостом
--//В зависимости от значения (i_cfg_prg_max_rd_req_size) CFG региста PCI устройства
--i_mrd_count_mux(24 downto 0)<=("00000" & i_trn_dma_len(31 downto 12)) when i_cfg_prg_max_rd_req_size="101" else
i_mrd_count_mux(24 downto 0)<=("0000" & i_trn_dma_len(31 downto 11)) when i_cfg_prg_max_rd_req_size="100" else
                              ("000" & i_trn_dma_len(31 downto 10)) when i_cfg_prg_max_rd_req_size="011" else
                              ("00" & i_trn_dma_len(31 downto 9))  when i_cfg_prg_max_rd_req_size="010" else
                              ('0' & i_trn_dma_len(31 downto 8))  when i_cfg_prg_max_rd_req_size="001" else
                              (     i_trn_dma_len(31 downto 7));--  when i_cfg_prg_max_rd_req_size="000" else

i_mrd_count_ziro<='1' when i_mrd_count_mux=CONV_STD_LOGIC_VECTOR(16#00#,32) else '0';

--//Результат вычислений:
i_mrd_count_result(25 downto 0)<=('0'&i_mrd_count_mux) + ('0'& CONV_STD_LOGIC_VECTOR(16#00#, 24)& not i_mrd_payload_byte_mux_ziro);

--//--------------------------------------------------------------------------------------------
--//Вычисляем значения для ByteEnable для последнего пакета данных:
--//--------------------------------------------------------------------------------------------
i_mrd_fbe<="1111" when i_mrd_payload_dw_lsb(10 downto 0)>CONV_STD_LOGIC_VECTOR(16#01#,11) else
           "1111" when i_trn_dma_len(1 downto 0)="00" else
           "0001" when i_trn_dma_len(1 downto 0)="01" else
           "0011" when i_trn_dma_len(1 downto 0)="10" else
           "0111";

--//Byte enable last DWORD (TPL payload)
i_mrd_lbe<="0000" when i_mrd_payload_dw_lsb(10 downto 0)=CONV_STD_LOGIC_VECTOR(16#01#,11) else
           "1111" when i_trn_dma_len(1 downto 0)="00" else
           "0001" when i_trn_dma_len(1 downto 0)="01" else
           "0011" when i_trn_dma_len(1 downto 0)="10" else
           "0111";



--//--------------------------------------------------------------------------------------------
--//Распределяем биты пользовательских регистровов:
--//--------------------------------------------------------------------------------------------
b_trn_start    <= v_reg_dev_ctrl(C_HREG_DEV_CTRL_TRN_START_BIT);
b_trn_dir      <= v_reg_dev_ctrl(C_HREG_DEV_CTRL_TRN_DIR_BIT);--//1/0 DMA-запись/чтение (DMA-запись: PC<-FPGA, DMA-чтение: PC->FPGA)
b_dmabuf_num   <= v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMABUF_NUM_M_BIT downto C_HREG_DEV_CTRL_DMABUF_NUM_L_BIT);
b_dmabuf_count <= v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMABUF_COUNT_M_BIT downto C_HREG_DEV_CTRL_DMABUF_COUNT_L_BIT);
b_dev_adr      <= v_reg_dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT);

b_irq_num      <= v_reg_irq_ctrl(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT);

v_reg_fpga_firmware<=CONV_STD_LOGIC_VECTOR(C_FPGA_FIRMWARE_VERSION, v_reg_fpga_firmware'length);



--//--------------------------------------------------------------------------------------------
--//Запись/Чтение пользовательских регистров:
--//--------------------------------------------------------------------------------------------
--//Декодируем BAR для регистров управления контроллером памяти и регистров проекта VERESK-M
vrsk_reg_bar <= p_in_trg_addr(7);--//x80 - Register Space: Veresk-M
vrsk_reg_adr(6 downto 0) <= p_in_trg_addr(6 downto 0);

--//Запись:
process(p_in_rst_n,p_in_clk)
  variable trn_start_edge  : std_logic;
  variable int_clr_edge    : std_logic;
--  variable trn_rst_edge    : std_logic;
  variable dev_txd_rdy_edge: std_logic;
  variable dmaprm_wr     : std_logic;
  variable dma_irq_clr: std_logic;
  variable hrddone_vctrl_edge: std_logic;
  variable hrddone_trcnik_edge: std_logic;
begin
  if p_in_rst_n='0' then
    v_reg_gctrl<=(others=>'0');
    v_reg_dev_ctrl<=(others=>'0');
    v_reg_pcie_ctrl<=(others=>'0');
    v_reg_mem_adr<=(others=>'0');
    v_reg_irq_ctrl<=(others=>'0');
    v_reg_tst0<=(others=>'0');
    v_reg_tst1<=(others=>'0');
    v_reg_tst2<=(others=>'0');

      dev_txd_rdy_edge:='0';
      trn_start_edge:='0';
      int_clr_edge:='0';
--      trn_rst_edge:='0';

      dma_irq_clr :='0';
    i_dma_irq_clr <='0';

    i_dev_txd_rdy  <='0';
    i_trn_start_sw <='0';
    i_irq_clr<='0';
    i_irq_en<=(others=>'0');
--    i_trn_rst_sw<='0';

    i_host_dmaprm_din<=(others=>'0');
    i_host_dmaprm_wr<=(others=>'0');
      dmaprm_wr:='0';
      hrddone_vctrl_edge:='0';
    i_hrddone_vctrl<='0';
      hrddone_trcnik_edge:='0';
    i_hrddone_trcnik<='0';

  elsif p_in_clk'event and p_in_clk='1' then

      dmaprm_wr:='0';
      dev_txd_rdy_edge:='0';
      trn_start_edge:='0';
      int_clr_edge:='0';
--      trn_rst_edge:='0';
      hrddone_vctrl_edge:='0';
      hrddone_trcnik_edge:='0';
      dma_irq_clr:='0';

    if p_in_trg_wr='1' then
      if vrsk_reg_bar='1' then
      --//--------------------------------------------
      --//Register Space: Проект Veresk-M
      --//--------------------------------------------
        if    vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_GCTRL, 5)  then v_reg_gctrl<=p_in_trg_din(v_reg_gctrl'high downto 0);
            hrddone_vctrl_edge:=p_in_trg_din(C_HREG_GCTRL_RDDONE_VCTRL_BIT);
            hrddone_trcnik_edge:=p_in_trg_din(C_HREG_GCTRL_RDDONE_TRCNIK_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DMAPRM_ADR, 5)then i_host_dmaprm_din<=p_in_trg_din;
        --//в байтах
            dmaprm_wr:='1';

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DMAPRM_LEN, 5)then i_host_dmaprm_din<=p_in_trg_din;
        --//в байтах
            dmaprm_wr:='1';

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_CTRL, 5)    then v_reg_dev_ctrl<=p_in_trg_din(v_reg_dev_ctrl'high downto 0);
--            trn_rst_edge:=p_in_trg_din(C_HREG_DEV_CTRL_TRN_RST_BIT);
            trn_start_edge:=p_in_trg_din(C_HREG_DEV_CTRL_TRN_START_BIT);
            dev_txd_rdy_edge:=p_in_trg_din(C_HREG_DEV_CTRL_DRDY_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_PCIE_CTRL, 5) then v_reg_pcie_ctrl<=p_in_trg_din(v_reg_pcie_ctrl'high downto 0);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_MEM_ADR, 5) then v_reg_mem_adr<=p_in_trg_din(v_reg_mem_adr'high downto 0);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_IRQ_CTRL, 5) then v_reg_irq_ctrl<=p_in_trg_din(v_reg_irq_ctrl'high downto 0);
            int_clr_edge :=p_in_trg_din(C_HREG_IRQ_CLR_WBIT);

            for i in 0 to 15 loop
              if p_in_trg_din(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT) = i then
                if p_in_trg_din(C_HREG_IRQ_EN_WBIT)='1' then
                  i_irq_en(i)<='1';
                elsif p_in_trg_din(C_HREG_IRQ_DIS_WBIT)='1' then
                  i_irq_en(i)<='0';
                end if;
              end if;
            end loop;

            --//Сброс флагов окончания TRN_DMA WR/RD
            if p_in_trg_din(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT) = CONV_STD_LOGIC_VECTOR(C_HIRQ_PCIE_DMA, (C_HREG_IRQ_NUM_M_WBIT - C_HREG_IRQ_NUM_L_WBIT+1))then
              dma_irq_clr:=p_in_trg_din(C_HREG_IRQ_CLR_WBIT);
            end if;

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST0, 5) then v_reg_tst0<=p_in_trg_din;
        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST1, 5) then v_reg_tst1<=p_in_trg_din;
--        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST2, 5) then v_reg_tst2<=p_in_trg_din;

        end if;

      end if;
    end if;

    i_host_dmaprm_wr(0)<=dmaprm_wr;
    i_dev_txd_rdy<=dev_txd_rdy_edge;
    i_trn_start_sw<=trn_start_edge;
    i_irq_clr<=int_clr_edge;
--    i_trn_rst_sw<=trn_rst_edge;
    i_hrddone_vctrl<=hrddone_vctrl_edge;
    i_hrddone_trcnik<=hrddone_trcnik_edge;

    i_dma_irq_clr<=dma_irq_clr;

  end if;
end process;

--//Чтение:
process(p_in_rst_n,p_in_clk)
  variable txd : std_logic_vector(p_out_trg_dout'range);
  variable tst_rd: std_logic;
begin
  if p_in_rst_n='0' then
    txd:=(others => '0');tst_rd:='0';i_tst_rd<='0';
    p_out_trg_dout<=(others=>'0');
    i_trg_rd<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    txd := (others => '0');tst_rd:='0';

    i_trg_rd<=p_in_trg_rd;

    if i_trg_rd='1' then
      if vrsk_reg_bar='1' then
      --//--------------------------------------------
      --//Register Space: Проект Veresk-M
      --//--------------------------------------------
        if    vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_FIRMWARE, 5) then
            txd:=EXT(v_reg_fpga_firmware, txd'length); tst_rd:='1';

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_GCTRL, 5) then

            txd(C_HREG_GCTRL_RST_ALL_BIT):=v_reg_gctrl(C_HREG_GCTRL_RST_ALL_BIT);
            txd(C_HREG_GCTRL_RST_MEM_BIT):=v_reg_gctrl(C_HREG_GCTRL_RST_MEM_BIT);
            txd(C_HREG_GCTRL_RST_ETH_BIT):=v_reg_gctrl(C_HREG_GCTRL_RST_ETH_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DMAPRM_ADR, 5) then
            txd:=EXT(i_host_dmaprm_dout, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DMAPRM_LEN, 5) then
            txd:=EXT(i_host_dmaprm_dout, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_CTRL, 5) then
            txd(C_HREG_DEV_CTRL_TRN_DIR_BIT) := b_trn_dir;
            txd(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT):= b_dev_adr;
            txd(C_HREG_DEV_CTRL_DMABUF_NUM_M_BIT downto C_HREG_DEV_CTRL_DMABUF_NUM_L_BIT) := b_dmabuf_num;
            txd(C_HREG_DEV_CTRL_DMABUF_COUNT_M_BIT downto C_HREG_DEV_CTRL_DMABUF_COUNT_L_BIT) := b_dmabuf_count;
            txd(C_HREG_DEV_CTRL_VCH_M_BIT downto C_HREG_DEV_CTRL_VCH_L_BIT) := v_reg_dev_ctrl(C_HREG_DEV_CTRL_VCH_M_BIT downto C_HREG_DEV_CTRL_VCH_L_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_PCIE_CTRL, 5) then
            txd(C_HREG_PCIE_CTRL_REQ_LINK_M_BIT downto C_HREG_PCIE_CTRL_REQ_LINK_L_BIT)              :=p_in_cfg_cap_max_lnk_width(5 downto 0);
            txd(C_HREG_PCIE_CTRL_NEG_LINK_M_BIT downto C_HREG_PCIE_CTRL_NEG_LINK_L_BIT)              :=p_in_cfg_neg_max_lnk_width(5 downto 0);
            txd(C_HREG_PCIE_CTRL_REQ_MAX_PAYLOAD_M_BIT downto C_HREG_PCIE_CTRL_REQ_MAX_PAYLOAD_L_BIT):=p_in_cfg_cap_max_payload_size(2 downto 0);
            txd(C_HREG_PCIE_CTRL_NEG_MAX_PAYLOAD_M_BIT downto C_HREG_PCIE_CTRL_NEG_MAX_PAYLOAD_L_BIT):=p_in_cfg_prg_max_payload_size(2 downto 0);
            txd(C_HREG_PCIE_CTRL_NEG_MAX_RD_REQ_M_BIT downto C_HREG_PCIE_CTRL_NEG_MAX_RD_REQ_L_BIT)  :=p_in_cfg_prg_max_rd_req_size(2 downto 0);
            txd(C_HREG_PCIE_CTRL_MSI_EN_BIT)            :=p_in_cfg_msi_enable;
            txd(C_HREG_PCIE_CTRL_PHANT_FUNC_BIT)        :=p_in_cfg_phant_func_en;
            txd(C_HREG_PCIE_CTRL_NOSNOOP_BIT)           :=p_in_cfg_no_snoop_en;
            txd(C_HREG_PCIE_CTRL_CPLD_MALFORMED_BIT)    :=p_in_cpld_malformed;
            txd(C_HREG_PCIE_CTRL_TAG_EXT_EN_BIT)        :=p_in_cfg_ext_tag_en;

            txd(C_HREG_PCIE_CTRL_CPL_STREAMING_BIT)     :=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_CPL_STREAMING_BIT);
            txd(C_HREG_PCIE_CTRL_METRING_BIT)           :=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_METRING_BIT);
            txd(C_HREG_PCIE_CTRL_TRN_RNP_OK_BIT)        :=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_TRN_RNP_OK_BIT);
            txd(C_HREG_PCIE_CTRL_DMA_RD_RELEX_ORDER_BIT):=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_DMA_RD_RELEX_ORDER_BIT);
            txd(C_HREG_PCIE_CTRL_DMA_WD_RELEX_ORDER_BIT):=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_DMA_WD_RELEX_ORDER_BIT);
            txd(C_HREG_PCIE_CTRL_DMA_WD_NOSNOOP_BIT)    :=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_DMA_WD_NOSNOOP_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_MEM_ADR, 5) then
            txd:=EXT(v_reg_mem_adr, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_IRQ_CTRL, 5) then
            for i in C_HREG_IRQ_STATUS_L_RBIT to C_HREG_IRQ_STATUS_M_RBIT loop
              txd(i):=p_in_irq_status(i-C_HREG_IRQ_STATUS_L_RBIT);
            end loop;

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_STATUS, 5) then
            txd(C_HREG_DEV_STATUS_INT_ACT_BIT)           :=OR_reduce(p_in_irq_status(C_HIRQ_COUNT-1 downto 0));
            txd(C_HREG_DEV_STATUS_PCIE_ERR_BIT)          :=p_in_cpld_malformed;
            txd(C_HREG_DEV_STATUS_PCIE_DMAWR_DONE_BIT)   :=i_dma_mwr_donetotal;
            txd(C_HREG_DEV_STATUS_PCIE_DMARD_DONE_BIT)   :=i_dma_mrd_donetotal;
            txd(C_HREG_DEV_STATUS_DMA_BUSY_BIT)          :=i_dma_worktotal;
            txd(C_HREG_DEV_STATUS_LAST_BIT downto C_HREG_DEV_STATUS_CFG_RDY_BIT):=p_in_dev_status(C_HREG_DEV_STATUS_LAST_BIT downto C_HREG_DEV_STATUS_CFG_RDY_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_DATA, 5) then txd:=EXT(p_in_dev_dout, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_VCTRL_FRMRK, 5) then txd:=p_in_dev_option(31 downto 0);
        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_VCTRL_FRERR, 5) then
          txd(7 downto 0):=p_in_usr_tst(71 downto 64);--//Тестирование счетчик пропущеных кадров читаемого канала

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TRCNIK_DSIZE, 5) then txd:=p_in_dev_option(95 downto 64);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST0, 5) then
          txd:=EXT(v_reg_tst0, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST1, 5) then
          txd(0):=p_in_usr_tst(72);--i_eth_module_gt_plllkdet;
          txd(1):=p_in_usr_tst(73);--lclk_dcm_lock;
          txd(2):=p_in_usr_tst(74);--i_hdd_gt_plldet;
          txd(3):=p_in_usr_tst(75);--i_hdd_dcm_lock;
          txd(4):=p_in_usr_tst(76);--i_memctrl_dcm_lock;
          txd(5):=p_in_usr_tst(77);--AND_reduce(i_host_mem_trained(C_MEMCTRL_BANK_COUNT downto 0));
          txd(31 downto 6):=p_in_usr_tst(103 downto 78);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST2, 5) then

          txd(31):=p_in_usr_tst(127);-- or p_in_tst_irq_ctrl(0);

        end if;

      end if;

      p_out_trg_dout<=txd;

    end if;--//if i_trg_rd='1' then

    i_tst_rd<=tst_rd;

  end if;
end process;



--//--------------------------------------------------------------------------------------------
--//Управление DMA транзакцией (режим Master)
--//--------------------------------------------------------------------------------------------
--//Запуск DMA транзакции MWr или MRd
i_trn_mwr_work<=    b_trn_dir and i_dma_work;
i_trn_mrd_work<=not b_trn_dir and i_dma_work;

i_dma_init<=i_dma_init_sw or i_dma_init_hw;

--//Стробы выполнения соотв. операции DMA
i_dma_mrd_done <=i_cpld_done   and p_in_mst_usr_txbuf_wd_last; --//TRN: PC->FPGA
i_dma_mwr_done <=p_in_mwr_done and sr_mst_usr_rxbuf_rd_last;   --//TRN: PC<-FPGA

process(p_in_rst_n,p_in_clk)
begin
  if p_in_rst_n='0' then

    i_dma_init_sw<='0';
    i_dma_start_sw<='0';

    i_dma_init_hw<='0';
    i_dma_start_hw<='0';

    sr_dma_mrd_done<='0';
    sr_dma_mwr_done<='0';

    i_dma_work<='0';
    i_dma_worktotal<='0';
    i_dma_mrd_donetotal<='0';
    i_dma_mwr_donetotal<='0';

    i_trn_dma_adr<=(others=>'0');
    i_trn_dma_len<=(others=>'0');

    i_dmabuf_num_cnt<=(others=>'0');
    i_dmabuf_done_cnt<=(others=>'0');

    sr_mst_usr_rxbuf_rd_last<='0';

    i_hw_dmaprm_cnt<=(others=>'0');
    i_hw_dmaprm_rd<=(others=>'0');
    i_hw_dmaprm_rd_done<='0';
    sr_hw_dmaprm_rd_done<='0';

    sr_hw_dmaprm_cnt<=(others=>'0');
    sr_hw_dmaprm_rd<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    sr_mst_usr_rxbuf_rd_last<=p_in_mst_usr_rxbuf_rd_last;

    --//Software start DMA
    i_dma_init_sw  <=not i_dma_worktotal and sr_hw_dmaprm_rd_done;
    i_dma_start_sw <=i_dma_init_sw;

    --//Hardware start DMA
    i_dma_init_hw  <=i_dma_worktotal and sr_hw_dmaprm_rd_done;
    i_dma_start_hw <=i_dma_init_hw;

    --//Отработка DMA для одного буфера
    if i_dma_start_sw='1' or i_dma_start_hw='1' then
      i_dma_work<='1';
    elsif i_dma_mrd_done='1' or i_dma_mwr_done='1' then --or i_trn_rst_sw='1' then
      i_dma_work<='0';
    end if;

    --//Отработка DMA для установленого кол-ва буферов
    if i_dma_start_sw='1' then
      i_dma_worktotal<='1';
    elsif (b_dmabuf_count=i_dmabuf_done_cnt and (i_dma_mrd_done='1' or i_dma_mwr_done='1')) or
         i_dma_irq_clr='1' then --or i_trn_rst_sw='1' then
      i_dma_worktotal<='0';
    end if;

    --//Формирование сигнала DMA транзакция MEMORY READ(PC->FPGA) завершена (Отработано заказаное кол-во буферов)
    if i_trn_start_sw='1' or i_dma_irq_clr='1' then --or i_trn_rst_sw='1' then
      i_dma_mrd_donetotal <='0';
    elsif b_dmabuf_count=i_dmabuf_done_cnt and i_dma_mrd_done='1' then
      i_dma_mrd_donetotal <='1';
    end if;
    sr_dma_mrd_done<=i_dma_mrd_done;

    --//Формирование сигнала DMA транзакция MEMORY WRITE(PC<-FPGA) завершена (Отработано заказаное кол-во буферов)
    if i_trn_start_sw='1' or i_dma_irq_clr='1' then --or i_trn_rst_sw='1' then
      i_dma_mwr_donetotal <='0';
    elsif b_dmabuf_count=i_dmabuf_done_cnt and i_dma_mwr_done='1' then
      i_dma_mwr_donetotal <='1';
    end if;
    sr_dma_mwr_done<=i_dma_mwr_done;


    --//Подсчет кол-ва тработаных буферов +
    --//загрузка индекса стартового буфера
    if i_trn_start_sw='1' then --or i_trn_rst_sw='1' then
      i_dmabuf_num_cnt<=b_dmabuf_num;   --//Загружаем индекс стартового буфера
      i_dmabuf_done_cnt<=(others=>'0'); --//Очищаем счетчик отработаных буферов

    elsif (i_dma_mwr_done='1' or i_dma_mrd_done='1') then
      i_dmabuf_num_cnt<=i_dmabuf_num_cnt+1;
      i_dmabuf_done_cnt<=i_dmabuf_done_cnt+1;
    end if;

    --//Чтение параметров DMA транзакции из BRAM
    if i_trn_start_sw='1' or
       (i_dma_worktotal='1' and (sr_dma_mwr_done='1' or sr_dma_mrd_done='1')) then
       i_hw_dmaprm_rd(0)<='1';
    elsif i_hw_dmaprm_cnt="01" then
       i_hw_dmaprm_rd(0)<='0';
       i_hw_dmaprm_rd_done<='1';
    else
      i_hw_dmaprm_rd_done<='0';
    end if;

    if i_hw_dmaprm_rd(0)='1' then
      i_hw_dmaprm_cnt<=i_hw_dmaprm_cnt+1;
    else
      i_hw_dmaprm_cnt<=(others=>'0');
    end if;

    sr_hw_dmaprm_cnt<=i_hw_dmaprm_cnt;
    sr_hw_dmaprm_rd<=i_hw_dmaprm_rd;
    sr_hw_dmaprm_rd_done<=i_hw_dmaprm_rd_done;

    --//Загрузка параметров для текущего DMA буфера
    if sr_hw_dmaprm_rd(0)='1' then
      if sr_hw_dmaprm_cnt="00" then
        i_trn_dma_adr<=i_hw_dmaprm_dout;--//Адрес в байтах
      elsif sr_hw_dmaprm_cnt="01" then
        i_trn_dma_len<=i_hw_dmaprm_dout;--//Размер в байтах
      end if;
    end if;

  end if;
end process;


--//BRAM для параметров буферов драйвера PCI-Express: Адрес буфера в памяти PC; Размер буфера
i_host_dmaprm_adr(9 downto 8)<="01" when vrsk_reg_bar='1' and vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DMAPRM_LEN, 5) else "00";
i_host_dmaprm_adr(7 downto 0)<=EXT(b_dmabuf_num, 8);

i_hw_dmaprm_adr(9 downto 8)<=i_hw_dmaprm_cnt;
i_hw_dmaprm_adr(7 downto 0)<=EXT(i_dmabuf_num_cnt, 8);

m_bram_dma_params_i : bram_dma_params
port map
(
addra => i_host_dmaprm_adr,
dina  => i_host_dmaprm_din,
douta => i_host_dmaprm_dout,
ena   => '1',
wea   => i_host_dmaprm_wr,
clka  => p_in_clk,


addrb => i_hw_dmaprm_adr,
dinb  => "00000000000000000000000000000000",
doutb => i_hw_dmaprm_dout,
enb   => i_hw_dmaprm_rd(0),
web   => "0",                --// Только чтение
clkb  => p_in_clk
);

--//Анализ размера принятых данных запроса MRd
process(p_in_rst_n,p_in_clk)
begin
  if p_in_rst_n='0' then
    i_cpld_done <='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if i_dma_init='1' then --or i_trn_rst_sw='1' then
      i_cpld_done <='0';
    else
      if p_in_cpld_total_size(31 downto 0)/=(p_in_cpld_total_size'range => '0') then
        if ("00"&i_trn_dma_len(31 downto 2))=p_in_cpld_total_size(31 downto 0) then
          i_cpld_done <= '1';
        end if;
      end if;
    end if ;
  end if;
end process;




--//--------------------------------------------------------------------------------------------
--//
--//--------------------------------------------------------------------------------------------
--//Установка номера банка и адреса ОЗУ для контроллера памяти (memory_ctrl.vhd)
gen_mem_bank : for i in 0 to i_mem_bank1h_out'high generate
begin
i_mem_bank1h_out(i)<='1' when v_reg_mem_adr(C_HREG_MEM_ADR_BANK_M_BIT downto C_HREG_MEM_ADR_BANK_L_BIT)= i else '0';
end generate gen_mem_bank;

process(p_in_rst_n,p_in_clk)
begin
  if p_in_rst_n='0' then
    i_mem_adr_offset<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_trn_start_sw='1' then
      i_mem_adr_offset(i_mem_adr_offset'high-2 downto 0)<=v_reg_mem_adr(i_mem_adr_offset'high downto 2);
    else
      if i_mem_ctrl_select='1' and p_in_mst_usr_rxbuf_rd='1' then
        i_mem_adr_offset<=i_mem_adr_offset+1;
      end if;
    end if;
  end if;
end process;

i_mem_ctrl_select <='1' when b_dev_adr =CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, b_dev_adr'length) else '0';

--//Доступа к внешним устройствам через регистр C_HREG_DEV_DATA
i_dev_wd_reg <= p_in_trg_wr when vrsk_reg_bar='1' and vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_DATA, 5) else '0';
i_dev_rd_reg <= i_trg_rd when vrsk_reg_bar='1' and vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_DATA, 5) else '0';

--//Выбор доступа к внешним устройствам. Через DMA транзакцию или через регистр C_HREG_DEV_DATA
i_dev_wd  <= p_in_mst_usr_txbuf_wd  when b_trn_start='1' and i_mem_ctrl_select='0' else i_dev_wd_reg;
i_dev_rd  <= p_in_mst_usr_rxbuf_rd  when b_trn_start='1' and i_mem_ctrl_select='0' else i_dev_rd_reg;
i_dev_din <= p_in_mst_usr_txbuf_din when b_trn_start='1' and i_mem_ctrl_select='0' else p_in_trg_din;

process(p_in_rst_n,p_in_clk)
begin
  if p_in_rst_n='0' then
    i_dev_txd_rdy_out<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if i_mem_ctrl_select='0' then
      if b_trn_start='1' then
        i_dev_txd_rdy_out<=i_mem_mwr_term;
      else
        i_dev_txd_rdy_out<=i_dev_txd_rdy;
      end if;
    else
      i_dev_txd_rdy_out<='0';
    end if;
  end if;
end process;


i_mem_mwr_term<=i_dma_mrd_done when b_dmabuf_count=i_dmabuf_done_cnt else '0';
i_mem_mrd_term<=sr_mst_usr_rxbuf_rd_last;

i_mem_bank1h  <= EXT(i_mem_bank1h_out, i_mem_bank1h'length);
i_mem_adr     <= EXT(i_mem_adr_offset, i_mem_adr'length);
i_mem_be      <=(others=>'1');

i_mem_ce      <= i_mem_ctrl_select and ((p_in_mst_usr_rxbuf_rd_start and b_trn_dir) or (i_dma_init_sw and not b_trn_dir));
i_mem_cw      <= i_mem_ctrl_select and not b_trn_dir;

i_mem_term    <= i_mem_ctrl_select and (i_mem_mwr_term or i_mem_mrd_term);
i_mem_rd      <= i_mem_ctrl_select and p_in_mst_usr_rxbuf_rd;
i_mem_wr      <= i_mem_ctrl_select and p_in_mst_usr_txbuf_wd;

i_mem_wpf  <= p_in_mem_wpf  when i_mem_ctrl_select='1' else p_in_dev_flag(C_DEV_FLAG_TXFIFO_PFULL_BIT);
i_mem_re   <= p_in_mem_re   when i_mem_ctrl_select='1' else p_in_dev_flag(C_DEV_FLAG_RXFIFO_EMPTY_BIT);

i_mem_dout <= p_in_mem_dout when i_mem_ctrl_select='1' else p_in_dev_dout;

--//-------------------------------------------------------------------
--//Сигналы для модулей TX/RX PCI-Express
--//-------------------------------------------------------------------
i_mem_din  <= p_in_mst_usr_txbuf_din;

p_out_mst_usr_rxbuf_dout <=i_mem_dout;
p_out_mst_usr_txbuf_full <=i_mem_wpf;
p_out_mst_usr_rxbuf_empty<=i_mem_re;


--//-------------------------------------------------------------------
--//Связь с внешними модулями (вне молуля хоста)
--//-------------------------------------------------------------------
--//Вывод регистра глобального управления
p_out_gctrl(C_HREG_GCTRL_RST_ALL_BIT)<=v_reg_gctrl(C_HREG_GCTRL_RST_ALL_BIT);
p_out_gctrl(C_HREG_GCTRL_RST_MEM_BIT)<=v_reg_gctrl(C_HREG_GCTRL_RST_MEM_BIT);
p_out_gctrl(C_HREG_GCTRL_RST_ETH_BIT)<=v_reg_gctrl(C_HREG_GCTRL_RST_ETH_BIT);
p_out_gctrl(C_HREG_GCTRL_RDDONE_VCTRL_BIT)<=i_hrddone_vctrl;
p_out_gctrl(C_HREG_GCTRL_RDDONE_TRCNIK_BIT)<=i_hrddone_trcnik;
--p_out_gctrl(p_out_gctrl'high downto C_HREG_GCTRL_LAST_BIT)<=(others=>'0');


--//Вывод регистра управления устройствами
p_out_dev_ctrl(C_HREG_DEV_CTRL_TRN_START_BIT)<=i_trn_start_sw;
p_out_dev_ctrl(C_HREG_DEV_CTRL_DRDY_BIT)<=i_dev_txd_rdy_out;
p_out_dev_ctrl(C_HREG_DEV_CTRL_LAST_BIT downto C_HREG_DEV_CTRL_DRDY_BIT+1)<=v_reg_dev_ctrl(C_HREG_DEV_CTRL_LAST_BIT downto C_HREG_DEV_CTRL_DRDY_BIT+1);
p_out_dev_ctrl(p_out_dev_ctrl'high downto C_HREG_DEV_CTRL_LAST_BIT+1)<=(others=>'0');

--p_out_dev_ctrl(C_HREG_DEV_CTRL_TRN_START_BIT)<=i_trn_start_sw;
--p_out_dev_ctrl(C_HREG_DEV_CTRL_DRDY_BIT-1 downto C_HREG_DEV_CTRL_TRN_START_BIT+1)<=v_reg_dev_ctrl(C_HREG_DEV_CTRL_DRDY_BIT-1 downto C_HREG_DEV_CTRL_TRN_START_BIT+1);
--p_out_dev_ctrl(C_HREG_DEV_CTRL_DRDY_BIT)<=i_dev_txd_rdy_out;
--p_out_dev_ctrl(C_HREG_DEV_CTRL_LAST_BIT downto C_HREG_DEV_CTRL_DRDY_BIT+1)<=v_reg_dev_ctrl(C_HREG_DEV_CTRL_LAST_BIT downto C_HREG_DEV_CTRL_DRDY_BIT+1);
--p_out_dev_ctrl(p_out_dev_ctrl'high downto C_HREG_DEV_CTRL_LAST_BIT+1)<=(others=>'0');


--//Чтение/Запись данных во внешние модули
p_out_dev_wd  <= i_dev_wd;
p_out_dev_rd  <= i_dev_rd;
p_out_dev_din <= i_dev_din;


--//Чтение/Запись данных контроллера памяти (memory_ctrl.vhd)
p_out_mem_bank1h  <= i_mem_bank1h;
p_out_mem_adr     <= i_mem_adr;
p_out_mem_be      <= i_mem_be;
p_out_mem_cw      <= i_mem_cw;
p_out_mem_term    <= i_mem_term;
p_out_mem_ce      <= i_mem_ce;
p_out_mem_rd      <= i_mem_rd;
p_out_mem_wr      <= i_mem_wr;
p_out_mem_din     <= i_mem_din;


--//-------------------------------------------------------------------
--//Тестовый вывод сигналов/Пользовательские данные
--//-------------------------------------------------------------------
p_out_usr_tst(31 downto 0)  <=v_reg_tst0;
p_out_usr_tst(63 downto 32) <=v_reg_tst1;
p_out_usr_tst(95 downto 64) <=i_trn_dma_len;
p_out_usr_tst(96)           <=i_irq_clr;--//Clr IRQ
p_out_usr_tst(100 downto 97)<=b_irq_num(3 downto 0);--Номер для гашения IRQ
p_out_usr_tst(108 downto 101)<=p_in_irq_status(7 downto 0);--//Status IRQx
p_out_usr_tst(116 downto 109)<=i_irq_set(7 downto 0);--//Set    IRQx
p_out_usr_tst(117)           <=i_dma_mwr_donetotal and sr_dma_mwr_done;
p_out_usr_tst(118)           <=i_dma_mrd_donetotal and sr_dma_mrd_done;
p_out_usr_tst(119)           <=v_reg_pcie_ctrl(C_HREG_PCIE_CTRL_MSI_EN_BIT);
p_out_usr_tst(120)           <=p_in_cfg_msi_enable;
p_out_usr_tst(121)           <=p_in_cfg_irq_disable;
p_out_usr_tst(122)           <='0';--i_trn_rst_sw;
p_out_usr_tst(123)           <=i_tst_rd;
p_out_usr_tst(125 downto 124)<=(others=>'0');
p_out_usr_tst(126)<='0';
p_out_usr_tst(127)<='0';


--//-------------------------------------------------------------------
--//Технологические сигналы
--//-------------------------------------------------------------------




--END MAIN
end behavioral;


