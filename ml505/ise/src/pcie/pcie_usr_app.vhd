-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.01
-- Module Name : pcie_usr_app.vhd
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
use work.vicg_common_pkg.all;
use work.prj_def.all;
use work.prj_cfg.all;

entity pcie_usr_app is
generic(
G_DBG : string :="OFF"
);
port(
-------------------------------------------------------
--Связь с Пользовательским проектом
-------------------------------------------------------
p_out_hclk      : out   std_logic;                                      --//Тактовый сигнал для пользовательского проекта
p_out_gctrl     : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);--//Вывод регистра C_HREG_CTRL

--Управление внешними устройствами
p_out_dev_ctrl  : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);--//Вывод регистра C_HREG_DEV_CTRL
p_out_dev_din   : out   std_logic_vector(C_HDEV_DWIDTH-1 downto 0);--//DEV<-HOST
p_in_dev_dout   : in    std_logic_vector(C_HDEV_DWIDTH-1 downto 0);--//DEV->HOST
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
p_out_rxbuf_dout               : out   std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
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
p_in_cfg_msi_enable            : in    std_logic;                   --//(0/1 - Legacy Interrupt/MSI) Тип прерывания
p_in_cfg_cap_max_lnk_width     : in    std_logic_vector(5 downto 0);--//Запрашиваемое кол-во link линий у системы
p_in_cfg_neg_max_lnk_width     : in    std_logic_vector(5 downto 0);--//Разрешонное кол-во link линий системой
p_in_cfg_cap_max_payload_size  : in    std_logic_vector(2 downto 0);--//Запрашиваемый max_payload_size пакета у системы
p_in_cfg_prg_max_payload_size  : in    std_logic_vector(2 downto 0);--//Разрешонный max_payload_size пакета системой
p_in_cfg_prg_max_rd_req_size   : in    std_logic_vector(2 downto 0);--//Max read request size for the device when acting as the Requester
p_in_cfg_phant_func_en         : in    std_logic;                   --//
p_in_cfg_no_snoop_en           : in    std_logic;                   --//
p_in_cfg_ext_tag_en            : in    std_logic;                   --//

--//Тестирование
p_in_rx_engine_tst      : in    std_logic_vector(1 downto 0);
p_in_throttle_tst       : in    std_logic_vector(1 downto 0);
p_in_mrd_pkt_len_tst    : in    std_logic_vector(31 downto 0);
p_in_rx_engine_tst2     : in    std_logic_vector(9 downto 0);

p_in_clk                : in    std_logic;
p_in_rst_n              : in    std_logic
);
end pcie_usr_app;

architecture behavioral of pcie_usr_app is

component bram_dma_params
port(
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
signal i_mrd_rcv_size_ok           : std_logic;

signal i_max_payload_size          : std_logic_vector(2 downto 0);
signal i_max_rd_req_size           : std_logic_vector(2 downto 0);

signal i_reg_rd                    : std_logic;
signal vrsk_reg_bar                : std_logic;
signal vrsk_reg_adr                : std_logic_vector(6 downto 0); --//Адреса регистров проекта VERESK-M

signal v_reg_firmware              : std_logic_vector(C_HREG_FRMWARE_LAST_BIT downto 0);
signal v_reg_ctrl                  : std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);
signal v_reg_dev_ctrl              : std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
signal v_reg_mem_adr               : std_logic_vector(C_HREG_MEM_ADR_LAST_BIT downto 0);
signal v_reg_mem_ctrl              : std_logic_vector(C_HREG_MEM_CTRL_LAST_BIT downto 0);
signal v_reg_irq                   : std_logic_vector(C_HREG_IRQ_LAST_WBIT downto 0);
signal v_reg_pcie                  : std_logic_vector(C_HREG_PCIE_LAST_BIT downto C_HREG_PCIE_NEG_MAX_PAYLOAD_L_BIT);
signal v_reg_tst0                  : std_logic_vector(31 downto 0);
signal v_reg_tst1                  : std_logic_vector(31 downto 0);
signal v_reg_time                  : std_logic_vector(31 downto 0);

signal i_hdev_adr                  : std_logic_vector(C_HREG_DEV_CTRL_ADR_M_BIT - C_HREG_DEV_CTRL_ADR_L_BIT downto 0);
signal i_irq_num                   : std_logic_vector(C_HREG_IRQ_NUM_M_WBIT - C_HREG_IRQ_NUM_L_WBIT downto 0);
signal i_dmabuf_num                : std_logic_vector(C_HREG_DEV_CTRL_DMABUF_M_BIT - C_HREG_DEV_CTRL_DMABUF_L_BIT downto 0);
signal i_dmabuf_count              : std_logic_vector(C_HREG_DEV_CTRL_DMABUF_COUNT_M_BIT - C_HREG_DEV_CTRL_DMABUF_COUNT_L_BIT downto 0);
signal i_usr_grst                  : std_logic;

signal i_dma_start                 : std_logic;--//Регистр DEV_CTRL(DMA_START) - передний фронт
signal sr_dma_start                : std_logic;
signal i_dmatrn_len                : std_logic_vector(31 downto 0);--//Размер транзакции в Byte
signal i_dmatrn_adr                : std_logic_vector(31 downto 0);
signal i_dmatrn_init               : std_logic;
signal i_dmatrn_init_sw            : std_logic;
signal i_dmatrn_init_hw            : std_logic;
signal i_dmatrn_start_sw           : std_logic;
signal i_dmatrn_start_hw           : std_logic;
signal i_dmatrn_work               : std_logic;
signal i_dmatrn_mrd_done_tmp       : std_logic;
signal i_dmatrn_mrd_done           : std_logic;
signal i_dmatrn_mwr_done_tmp       : std_logic;
signal i_dmatrn_mwr_done           : std_logic;
signal sr_dmatrn_mrd_done          : std_logic;
signal sr_dmatrn_mwr_done          : std_logic;
signal i_dmatrn_mem_done           : std_logic_vector(1 downto 0);
signal i_dma_work                  : std_logic;
signal i_dma_mrd_done              : std_logic;
signal i_dma_mwr_done              : std_logic;
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

signal i_dmabuf_num_cnt            : std_logic_vector(i_dmabuf_num'range);
signal i_dmabuf_done_cnt           : std_logic_vector(i_dmabuf_count'range);

signal sr_memtrn_done              : std_logic_vector(0 to 2);
signal i_memtrn_done               : std_logic;

signal i_irq_clr                   : std_logic;
signal i_irq_en                    : std_logic_vector(C_HIRQ_COUNT - 1 downto 0);
signal i_irq_set                   : std_logic_vector(C_HIRQ_COUNT - 1 downto 0);
Type TSRIrqSet is array (0 to C_HIRQ_COUNT-1) of std_logic_vector(0 to 2);
signal sr_irq_set                  : TSRIrqSet;

signal i_rddone_vctrl              : std_logic;
signal i_time_set                  : std_logic;
signal sr_rxbuf_rd_last            : std_logic;

signal i_dev_drdy                  : std_logic;
signal i_dev_drdy_out              : std_logic;

signal i_mem_adr_en                : std_logic;
signal i_mem_adr                   : std_logic_vector(31 downto 0):=(others=>'0');
--signal i_tst_rd                    : std_logic;

signal sr_txbuf_din                : std_logic_vector(31 downto 0);
signal i_txbuf_din                 : std_logic_vector(63 downto 0);
signal i_txbuf_wr                  : std_logic;
signal i_txbuf_wr_sel              : std_logic;

--MAIN
begin


p_out_hclk <= p_in_clk;

p_out_dmatrn_init <= i_dmatrn_init or i_usr_grst;

--//Управление DMATRN_WR (PC<-FPGA) (MEMORY WRITE)
p_out_mwr_en            <=i_dmatrn_work and     v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT);--//TRN: PC<-FPGA
p_out_mwr_addr_up       <=CONV_STD_LOGIC_VECTOR(10#00#, p_out_mwr_addr_up'length);
p_out_mwr_addr          <=i_dmatrn_adr(31 downto 2)&"00";                    --//Адрес системной памяти ХОСТА
p_out_mwr_len           <=EXT(i_mwr_payload_dw_result, p_out_mwr_len'length);--//Len(DW) для последнего пакета
p_out_mwr_count         <=EXT(i_mwr_count_result, p_out_mwr_count'length);   --//Кол-во пакетов
p_out_mwr_tlp_tc        <=CONV_STD_LOGIC_VECTOR(10#00#, p_out_mwr_tlp_tc'length);
p_out_mwr_64b           <='0';--//1/0 - 64b/32b
p_out_mwr_phant_func_en1<='0';--//p_in_cfg_phant_func_en
p_out_mwr_relaxed_order <='0';--v_reg_pcie(C_HREG_PCIE_DMA_RELEX_ORDER_WBIT);
p_out_mwr_nosnoop       <='0';--v_reg_pcie(C_HREG_PCIE_DMA_NOSNOOP_WBIT);
p_out_mwr_tag           <=CONV_STD_LOGIC_VECTOR(16#00#, p_out_mwr_tag'length);
p_out_mwr_fbe           <=i_mwr_fbe;
p_out_mwr_lbe           <=i_mwr_lbe;

--//Управление DMATRN_RD (PC->FPGA) (MEMORY READ)
p_out_mrd_en          <=i_dmatrn_work and not v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT);--//TRN: PC->FPGA
p_out_mrd_addr_up       <=CONV_STD_LOGIC_VECTOR(10#00#, p_out_mrd_addr_up'length);
p_out_mrd_addr          <=i_dmatrn_adr(31 downto 2)&"00";                    --//Адрес системной памяти ХОСТА
p_out_mrd_len           <=EXT(i_mrd_payload_dw_result, p_out_mrd_len'length);--//Len(DW) для последнего пакета
p_out_mrd_count         <=EXT(i_mrd_count_result, p_out_mrd_count'length);   --//Кол-во пакетов
p_out_mrd_tlp_tc        <=CONV_STD_LOGIC_VECTOR(10#00#, p_out_mrd_tlp_tc'length);
p_out_mrd_64b           <='0';--//1/0 - 64b/32b
p_out_mrd_phant_func_en1<='0';--//p_in_cfg_phant_func_en
p_out_mrd_relaxed_order <='0';--v_reg_pcie(C_HREG_PCIE_DMA_RELEX_ORDER_WBIT);
p_out_mrd_nosnoop       <='0';--v_reg_pcie(C_HREG_PCIE_DMA_NOSNOOP_WBIT);
p_out_mrd_tag           <=CONV_STD_LOGIC_VECTOR(16#00#, p_out_mrd_tag'length);
p_out_mrd_fbe           <=i_mrd_fbe;
p_out_mrd_lbe           <=i_mrd_lbe;


p_out_cpl_streaming     <=v_reg_pcie(C_HREG_PCIE_CPL_STREAMING_BIT);--//1/0 - рапрещено/разрешено
p_out_rd_metering       <=v_reg_pcie(C_HREG_PCIE_METRING_BIT);      --//0/1 - запрещено/разрешено
p_out_trn_rnp_ok_n      <='0';
p_out_usr_max_payload_size <=i_max_payload_size;
p_out_usr_max_rd_req_size  <=i_max_rd_req_size;


--//--------------------------------------------------------------
--//Memory Write Request:
--//--------------------------------------------------------------
--//max_payload_size: 000b = 128  byte max payload size
--//                  001b = 256  byte max payload size
--//                  010b = 512  byte max payload size
--//                  011b = 1024 byte max payload size
--//                  100b = 2048 byte max payload size
--//                  101b = 4096 byte max payload size
--//--------------------------------------------------------------
--//Вычисляем размер payload для последнего пакета(в DWORD)
--//--------------------------------------------------------------
i_max_payload_size<=v_reg_pcie(C_HREG_PCIE_NEG_MAX_PAYLOAD_M_BIT downto C_HREG_PCIE_NEG_MAX_PAYLOAD_L_BIT);

--//Выделяем кол-во байт одного пакета TPL из общего размера данных(i_dmatrn_len) установленых Хостом
--//В зависимости от значения (p_in_cfg_prg_max_payload_size) CFG региста PCI устройства
--i_mwr_payload_byte_mux(11 downto 0)<=(    i_dmatrn_len(11 downto 0)) when i_max_payload_size="101" else
i_mwr_payload_byte_mux(11 downto 0)<=('0' & i_dmatrn_len(10 downto 0)) when i_max_payload_size="100" else
                                     ("00" & i_dmatrn_len(9 downto 0))  when i_max_payload_size="011" else
                                     ("000" & i_dmatrn_len(8 downto 0))  when i_max_payload_size="010" else
                                     ("0000" & i_dmatrn_len(7 downto 0))  when i_max_payload_size="001" else
                                     ("00000" & i_dmatrn_len(6 downto 0));--  when i_max_payload_size="000" else

i_mwr_payload_byte_mux_ziro <='1' when i_mwr_payload_byte_mux=CONV_STD_LOGIC_VECTOR(16#00#,12) else '0';

--//Вычисляем сколько DWORD должен содержать один пакет
i_mwr_payload_dw_lsb(10 downto 0)<=('0'&i_mwr_payload_byte_mux(11 downto 2)) + ('0'&CONV_STD_LOGIC_VECTOR(16#00#, 9)&(i_dmatrn_len(1) or i_dmatrn_len(0)));

--i_mwr_payload_dw_lsb_ziro <='1' when (i_mwr_payload_dw_lsb(9 downto 0)="0000000000" and i_max_payload_size="101") or
i_mwr_payload_dw_lsb_ziro <='1' when (i_mwr_payload_dw_lsb(8 downto 0)="000000000" and i_max_payload_size="100") or
                                     (i_mwr_payload_dw_lsb(7 downto 0)="00000000" and i_max_payload_size="011") or
                                     (i_mwr_payload_dw_lsb(6 downto 0)="0000000" and i_max_payload_size="010") or
                                     (i_mwr_payload_dw_lsb(5 downto 0)="000000" and i_max_payload_size="001") or
                                     (i_mwr_payload_dw_lsb(4 downto 0)="00000" and i_max_payload_size="000") else '0';

--//Выделяем бит переноса в зависимости от i_max_payload_size
--i_mwr_payload_dw_carry <= i_mwr_payload_dw_lsb(10) when i_max_payload_size="101" else
i_mwr_payload_dw_carry <= i_mwr_payload_dw_lsb(9)  when i_max_payload_size="100" else
                          i_mwr_payload_dw_lsb(8)  when i_max_payload_size="011" else
                          i_mwr_payload_dw_lsb(7)  when i_max_payload_size="010" else
                          i_mwr_payload_dw_lsb(6)  when i_max_payload_size="001" else
                          i_mwr_payload_dw_lsb(5);

i_mwr_payload_dw_msb<='1' when i_mwr_count_ziro='0' and i_mwr_payload_dw_lsb_ziro='1' else i_mwr_payload_dw_carry;

--//Результат вычислений:
--i_mwr_payload_dw_result(10 downto 0)<=(     i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(9 downto 0)) when i_max_payload_size="101" else
i_mwr_payload_dw_result(10 downto 0)<=('0' & i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(8 downto 0)) when i_max_payload_size="100" else
                                      ("00" & i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(7 downto 0)) when i_max_payload_size="011" else
                                      ("000" & i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(6 downto 0)) when i_max_payload_size="010" else
                                      ("0000" & i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(5 downto 0)) when i_max_payload_size="001" else
                                      ("00000" & i_mwr_payload_dw_msb & i_mwr_payload_dw_lsb(4 downto 0));


--//--------------------------------------------------------------------------------------------
--//Вычисляем кол-во пакетов, необходимое для передачи/чтения всего запрошеного размера данных
--//--------------------------------------------------------------------------------------------
--Выделяем кол-во пакетов TPL из общего размера данных(i_dmatrn_len) установленых Хостом
--В зависимости от значения (i_max_payload_size) CFG региста PCI устройства
--i_mwr_count_mux(24 downto 0)<=("00000" & i_dmatrn_len(31 downto 12)) when i_max_payload_size="101" else
i_mwr_count_mux(24 downto 0)<=("0000" & i_dmatrn_len(31 downto 11)) when i_max_payload_size="100" else
                              ("000" & i_dmatrn_len(31 downto 10)) when i_max_payload_size="011" else
                              ("00" & i_dmatrn_len(31 downto 9))  when i_max_payload_size="010" else
                              ('0' & i_dmatrn_len(31 downto 8))  when i_max_payload_size="001" else
                              (     i_dmatrn_len(31 downto 7));--  when i_max_payload_size="000" else

i_mwr_count_ziro<='1' when i_mwr_count_mux=CONV_STD_LOGIC_VECTOR(16#00#,32) else '0';

--Результат вычислений:
i_mwr_count_result(25 downto 0)<=('0'&i_mwr_count_mux) + ('0'& CONV_STD_LOGIC_VECTOR(16#00#, 24)& not i_mwr_payload_byte_mux_ziro);

--//--------------------------------------------------------------------------------------------
--//Вычисляем значения для ByteEnable для последнего пакета данных:
--//--------------------------------------------------------------------------------------------
i_mwr_fbe<="1111" when i_mwr_payload_dw_lsb(10 downto 0)>CONV_STD_LOGIC_VECTOR(16#01#,11) else
           "1111" when i_dmatrn_len(1 downto 0)="00" else
           "0001" when i_dmatrn_len(1 downto 0)="01" else
           "0011" when i_dmatrn_len(1 downto 0)="10" else
           "0111";

--Byte enable last DWORD (TPL payload)
i_mwr_lbe<="0000" when i_mwr_payload_dw_lsb(10 downto 0)=CONV_STD_LOGIC_VECTOR(16#01#,11) else
           "1111" when i_dmatrn_len(1 downto 0)="00" else
           "0001" when i_dmatrn_len(1 downto 0)="01" else
           "0011" when i_dmatrn_len(1 downto 0)="10" else
           "0111";



--//--------------------------------------------------------------
--//Memory Read Request:
--//--------------------------------------------------------------
--//max_rd_req_size : 000b = 128  byte max payload size
--//                  001b = 256  byte max payload size
--//                  010b = 512  byte max payload size
--//                  011b = 1024 byte max payload size
--//                  100b = 2048 byte max payload size
--//                  101b = 4096 byte max payload size
--//--------------------------------------------------------------
--//Вычисляем размер payload для последнего пакета(в DWORD)
--//--------------------------------------------------------------
i_max_rd_req_size<=v_reg_pcie(C_HREG_PCIE_NEG_MAX_RD_REQ_M_BIT downto C_HREG_PCIE_NEG_MAX_RD_REQ_L_BIT);

--Выделяем кол-во байт одного пакета TPL из общего размера данных(i_dmatrn_len) установленых Хостом
--В зависимости от значения (i_max_rd_req_size) CFG региста PCI устройства
--i_mwr_payload_byte_mux(11 downto 0)<=(    i_dmatrn_len(11 downto 0)) when i_max_rd_req_size="101" else
i_mrd_payload_byte_mux(11 downto 0)<=('0' & i_dmatrn_len(10 downto 0)) when i_max_rd_req_size="100" else
                                     ("00" & i_dmatrn_len(9 downto 0))  when i_max_rd_req_size="011" else
                                     ("000" & i_dmatrn_len(8 downto 0))  when i_max_rd_req_size="010" else
                                     ("0000" & i_dmatrn_len(7 downto 0))  when i_max_rd_req_size="001" else
                                     ("00000" & i_dmatrn_len(6 downto 0));--  when i_max_rd_req_size="000" else

i_mrd_payload_byte_mux_ziro <='1' when i_mrd_payload_byte_mux=CONV_STD_LOGIC_VECTOR(16#00#,12) else '0';

--Вычисляем сколько DWORD должен содержать один пакет
i_mrd_payload_dw_lsb(10 downto 0)<=('0'&i_mrd_payload_byte_mux(11 downto 2)) + ('0'&CONV_STD_LOGIC_VECTOR(16#00#, 9)&(i_dmatrn_len(1) or i_dmatrn_len(0)));

--i_mrd_payload_dw_lsb_ziro <='1' when (i_mrd_payload_dw_lsb(9 downto 0)="0000000000" and i_max_rd_req_size="101") or
i_mrd_payload_dw_lsb_ziro <='1' when (i_mrd_payload_dw_lsb(8 downto 0)="000000000" and i_max_rd_req_size="100") or
                                     (i_mrd_payload_dw_lsb(7 downto 0)="00000000" and i_max_rd_req_size="011") or
                                     (i_mrd_payload_dw_lsb(6 downto 0)="0000000" and i_max_rd_req_size="010") or
                                     (i_mrd_payload_dw_lsb(5 downto 0)="000000" and i_max_rd_req_size="001") or
                                     (i_mrd_payload_dw_lsb(4 downto 0)="00000" and i_max_rd_req_size="000") else '0';

--Выделяем бит переноса в зависимости от i_max_rd_req_size
--i_mrd_payload_dw_carry <= i_mrd_payload_dw_lsb(10) when i_max_rd_req_size="101" else
i_mrd_payload_dw_carry <= i_mrd_payload_dw_lsb(9)  when i_max_rd_req_size="100" else
                          i_mrd_payload_dw_lsb(8)  when i_max_rd_req_size="011" else
                          i_mrd_payload_dw_lsb(7)  when i_max_rd_req_size="010" else
                          i_mrd_payload_dw_lsb(6)  when i_max_rd_req_size="001" else
                          i_mrd_payload_dw_lsb(5);

i_mrd_payload_dw_msb<='1' when i_mrd_count_ziro='0' and i_mrd_payload_dw_lsb_ziro='1' else i_mrd_payload_dw_carry;

--Результат вычислений:
--i_mrd_payload_dw_result(10 downto 0)<=(     i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(9 downto 0)) when i_max_rd_req_size="101" else
i_mrd_payload_dw_result(10 downto 0)<=('0' & i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(8 downto 0)) when i_max_rd_req_size="100" else
                                      ("00" & i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(7 downto 0)) when i_max_rd_req_size="011" else
                                      ("000" & i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(6 downto 0)) when i_max_rd_req_size="010" else
                                      ("0000" & i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(5 downto 0)) when i_max_rd_req_size="001" else
                                      ("00000" & i_mrd_payload_dw_msb & i_mrd_payload_dw_lsb(4 downto 0));


--//--------------------------------------------------------------------------------------------
--//Вычисляем кол-во пакетов, необходимое для передачи/чтения всего запрошеного размера данных
--//--------------------------------------------------------------------------------------------
--Выделяем кол-во пакетов TPL из общего размера данных(i_dmatrn_len) установленых Хостом
--В зависимости от значения (i_max_rd_req_size) CFG региста PCI устройства
--i_mrd_count_mux(24 downto 0)<=("00000" & i_dmatrn_len(31 downto 12)) when i_max_rd_req_size="101" else
i_mrd_count_mux(24 downto 0)<=("0000" & i_dmatrn_len(31 downto 11)) when i_max_rd_req_size="100" else
                              ("000" & i_dmatrn_len(31 downto 10)) when i_max_rd_req_size="011" else
                              ("00" & i_dmatrn_len(31 downto 9))  when i_max_rd_req_size="010" else
                              ('0' & i_dmatrn_len(31 downto 8))  when i_max_rd_req_size="001" else
                              (     i_dmatrn_len(31 downto 7));--  when i_max_rd_req_size="000" else

i_mrd_count_ziro<='1' when i_mrd_count_mux=CONV_STD_LOGIC_VECTOR(16#00#,32) else '0';

--Результат вычислений:
i_mrd_count_result(25 downto 0)<=('0'&i_mrd_count_mux) + ('0'& CONV_STD_LOGIC_VECTOR(16#00#, 24)& not i_mrd_payload_byte_mux_ziro);

--//--------------------------------------------------------------------------------------------
--//Вычисляем значения для ByteEnable для последнего пакета данных:
--//--------------------------------------------------------------------------------------------
i_mrd_fbe<="1111" when i_mrd_payload_dw_lsb(10 downto 0)>CONV_STD_LOGIC_VECTOR(16#01#,11) else
           "1111" when i_dmatrn_len(1 downto 0)="00" else
           "0001" when i_dmatrn_len(1 downto 0)="01" else
           "0011" when i_dmatrn_len(1 downto 0)="10" else
           "0111";

--Byte enable last DWORD (TPL payload)
i_mrd_lbe<="0000" when i_mrd_payload_dw_lsb(10 downto 0)=CONV_STD_LOGIC_VECTOR(16#01#,11) else
           "1111" when i_dmatrn_len(1 downto 0)="00" else
           "0001" when i_dmatrn_len(1 downto 0)="01" else
           "0011" when i_dmatrn_len(1 downto 0)="10" else
           "0111";


--//--------------------------------------------------------------------------------------------
--//Запись/Чтение пользовательских регистров:
--//--------------------------------------------------------------------------------------------
--Декодируем BAR для регистров управления контроллером памяти и регистров проекта VERESK-M
vrsk_reg_bar <= p_in_reg_adr(7);--x80 - Register Space: Veresk-M
vrsk_reg_adr(6 downto 0) <= p_in_reg_adr(6 downto 0);

--Распределяем биты пользовательских регистров:
i_dmabuf_num   <= v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMABUF_M_BIT downto C_HREG_DEV_CTRL_DMABUF_L_BIT);
i_dmabuf_count <= v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMABUF_COUNT_M_BIT downto C_HREG_DEV_CTRL_DMABUF_COUNT_L_BIT);
i_hdev_adr     <= v_reg_dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT);

i_irq_num      <= v_reg_irq(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT);

v_reg_firmware<=CONV_STD_LOGIC_VECTOR(C_FPGA_FIRMWARE_VERSION, v_reg_firmware'length);

--Запись:
process(p_in_rst_n,p_in_clk)
  variable dma_start : std_logic;
  variable irq_clr : std_logic;
  variable dev_drdy : std_logic;
  variable dmaprm_wr : std_logic;
  variable dma_irq_clr : std_logic;
  variable rddone_vctrl_edge : std_logic;
  variable time_set : std_logic;
  variable usr_grst : std_logic;
begin
  if p_in_rst_n='0' then
    v_reg_ctrl<=(others=>'0');
    v_reg_dev_ctrl<=(others=>'0');
    v_reg_pcie<=(others=>'0');
    v_reg_mem_adr<=(others=>'0');
    v_reg_irq<=(others=>'0');
    v_reg_tst0<=(others=>'0');
    v_reg_tst1<=(others=>'0');
    v_reg_time<=(others=>'0');

      dma_start:='0';
    i_dma_start<='0';
    sr_dma_start<='0';
      dma_irq_clr:='0';
    i_dma_irq_clr<='0';

      dev_drdy:='0';
    i_dev_drdy<='0';
      irq_clr:='0';
    i_irq_clr<='0';
    i_irq_en<=(others=>'0');

    i_host_dmaprm_din<=(others=>'0');
    i_host_dmaprm_wr<=(others=>'0');
      dmaprm_wr:='0';
      rddone_vctrl_edge:='0';
    i_rddone_vctrl<='0';
      time_set:='0';
    i_time_set<='0';
      usr_grst:='0';
    i_usr_grst<='0';

  elsif p_in_clk'event and p_in_clk='1' then

      dmaprm_wr:='0';
      dev_drdy:='0';
      dma_start:='0';
      irq_clr:='0';
      rddone_vctrl_edge:='0';
      time_set:='0';
      dma_irq_clr:='0';
      usr_grst:='0';

    if p_in_reg_wr='1' then
      if vrsk_reg_bar='1' then
      ----------------------------------------------
      --Register Space: Проект Veresk-M
      ----------------------------------------------
        if    vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_CTRL, 5)  then v_reg_ctrl<=p_in_reg_din(v_reg_ctrl'high downto 0);
            usr_grst:=p_in_reg_din(C_HREG_CTRL_RST_ALL_BIT);
            rddone_vctrl_edge:=p_in_reg_din(C_HREG_CTRL_RDDONE_VCTRL_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DMAPRM_ADR, 5) then i_host_dmaprm_din<=p_in_reg_din;
        --в байтах
            dmaprm_wr:='1';

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DMAPRM_LEN, 5) then i_host_dmaprm_din<=p_in_reg_din;
        --в байтах
            dmaprm_wr:='1';

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_CTRL, 5) then v_reg_dev_ctrl<=p_in_reg_din(v_reg_dev_ctrl'high downto 0);
            dma_start:=p_in_reg_din(C_HREG_DEV_CTRL_DMA_START_BIT);
            dev_drdy:=p_in_reg_din(C_HREG_DEV_CTRL_DRDY_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_PCIE, 5) then
            v_reg_pcie<=p_in_reg_din(v_reg_pcie'high downto C_HREG_PCIE_NEG_MAX_PAYLOAD_L_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_MEM_ADR, 5) then v_reg_mem_adr<=p_in_reg_din(v_reg_mem_adr'high downto 0);
        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_MEM_CTRL, 5) then v_reg_mem_ctrl<=p_in_reg_din(v_reg_mem_ctrl'high downto 0);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_IRQ, 5) then v_reg_irq<=p_in_reg_din(v_reg_irq'high downto 0);
            irq_clr:=p_in_reg_din(C_HREG_IRQ_CLR_WBIT);

            for i in 0 to C_HIRQ_COUNT-1 loop
              if p_in_reg_din(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT) = i then
                if p_in_reg_din(C_HREG_IRQ_EN_WBIT)='1' then
                  i_irq_en(i)<='1';
                elsif p_in_reg_din(C_HREG_IRQ_DIS_WBIT)='1' then
                  i_irq_en(i)<='0';
                end if;
              end if;
            end loop;

            --Сброс флагов окончания TRN_DMA WR/RD
            if p_in_reg_din(C_HREG_IRQ_NUM_M_WBIT downto C_HREG_IRQ_NUM_L_WBIT) = CONV_STD_LOGIC_VECTOR(C_HIRQ_PCIE_DMA, (C_HREG_IRQ_NUM_M_WBIT - C_HREG_IRQ_NUM_L_WBIT+1))then
              dma_irq_clr:=p_in_reg_din(C_HREG_IRQ_CLR_WBIT);
            end if;

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST0, 5) then v_reg_tst0<=p_in_reg_din;
        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST1, 5) then v_reg_tst1<=p_in_reg_din;

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TIME, 5) then v_reg_time<=p_in_reg_din;
          time_set:='1';

        end if;

      end if;
    end if;

    i_host_dmaprm_wr(0)<=dmaprm_wr;
    i_dev_drdy<=dev_drdy;
    i_dma_start<=dma_start;
    i_irq_clr<=irq_clr;
    i_rddone_vctrl<=rddone_vctrl_edge;
    i_time_set<=time_set;
    i_usr_grst<=usr_grst;
    i_dma_irq_clr<=dma_irq_clr;

    sr_dma_start<=i_dma_start;

  end if;
end process;

--Чтение:
process(p_in_rst_n,p_in_clk)
  variable txd : std_logic_vector(p_out_reg_dout'range);
begin
  if p_in_rst_n='0' then
    txd:=(others => '0');
    p_out_reg_dout<=(others=>'0');
    i_reg_rd<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    txd := (others => '0');

    i_reg_rd<=p_in_reg_rd;

    if i_reg_rd='1' then
      if vrsk_reg_bar='1' then
      ----------------------------------------------
      --Register Space: Проект Veresk-M
      ----------------------------------------------
        if    vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_FIRMWARE, 5) then
            txd:=EXT(v_reg_firmware, txd'length); --tst_rd:='1';

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_CTRL, 5) then
            txd(C_HREG_CTRL_RST_ALL_BIT):=v_reg_ctrl(C_HREG_CTRL_RST_ALL_BIT);
            txd(C_HREG_CTRL_RST_MEM_BIT):=v_reg_ctrl(C_HREG_CTRL_RST_MEM_BIT);
            txd(C_HREG_CTRL_RST_ETH_BIT):=v_reg_ctrl(C_HREG_CTRL_RST_ETH_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DMAPRM_ADR, 5) then
            txd:=EXT(i_host_dmaprm_dout, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DMAPRM_LEN, 5) then
            txd:=EXT(i_host_dmaprm_dout, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_CTRL, 5) then
            txd(C_HREG_DEV_CTRL_DMA_DIR_BIT)                                                 := v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT);
            txd(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT)                  := i_hdev_adr;
            txd(C_HREG_DEV_CTRL_DMABUF_M_BIT downto C_HREG_DEV_CTRL_DMABUF_L_BIT)            := i_dmabuf_num;
            txd(C_HREG_DEV_CTRL_DMABUF_COUNT_M_BIT downto C_HREG_DEV_CTRL_DMABUF_COUNT_L_BIT):= i_dmabuf_count;
            txd(C_HREG_DEV_CTRL_VCH_M_BIT downto C_HREG_DEV_CTRL_VCH_L_BIT) := v_reg_dev_ctrl(C_HREG_DEV_CTRL_VCH_M_BIT downto C_HREG_DEV_CTRL_VCH_L_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_PCIE, 5) then
            txd(C_HREG_PCIE_REQ_LINK_M_RBIT downto C_HREG_PCIE_REQ_LINK_L_RBIT)              :=p_in_cfg_cap_max_lnk_width(5 downto 0);
            txd(C_HREG_PCIE_NEG_LINK_M_RBIT downto C_HREG_PCIE_NEG_LINK_L_RBIT)              :=p_in_cfg_neg_max_lnk_width(5 downto 0);
            txd(C_HREG_PCIE_REQ_MAX_PAYLOAD_M_RBIT downto C_HREG_PCIE_REQ_MAX_PAYLOAD_L_RBIT):=p_in_cfg_cap_max_payload_size(2 downto 0);
            txd(C_HREG_PCIE_NEG_MAX_PAYLOAD_M_BIT downto C_HREG_PCIE_NEG_MAX_PAYLOAD_L_BIT)  :=p_in_cfg_prg_max_payload_size(2 downto 0);
            txd(C_HREG_PCIE_NEG_MAX_RD_REQ_M_BIT downto C_HREG_PCIE_NEG_MAX_RD_REQ_L_BIT)    :=p_in_cfg_prg_max_rd_req_size(2 downto 0);
            txd(C_HREG_PCIE_PHANT_FUNC_RBIT)     :=p_in_cfg_phant_func_en;
            txd(C_HREG_PCIE_TAG_EXT_EN_RBIT)     :=p_in_cfg_ext_tag_en;
            txd(C_HREG_PCIE_NOSNOOP_RBIT)        :=p_in_cfg_no_snoop_en;
            txd(C_HREG_PCIE_CPL_STREAMING_BIT)   :=v_reg_pcie(C_HREG_PCIE_CPL_STREAMING_BIT);
            txd(C_HREG_PCIE_METRING_BIT)         :=v_reg_pcie(C_HREG_PCIE_METRING_BIT);
            txd(C_HREG_PCIE_SPEED_TESTING_BIT)   :=v_reg_pcie(C_HREG_PCIE_SPEED_TESTING_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_MEM_ADR, 5) then
            txd:=EXT(v_reg_mem_adr, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_MEM_CTRL, 5) then
            txd:=EXT(v_reg_mem_ctrl, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_IRQ, 5) then
            for i in C_HREG_IRQ_STATUS_L_RBIT to C_HREG_IRQ_STATUS_M_RBIT loop
              txd(i):=p_in_irq_status(i-C_HREG_IRQ_STATUS_L_RBIT);
            end loop;

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_STATUS, 5) then
            txd(C_HREG_DEV_STATUS_INT_ACT_BIT)        :=OR_reduce(p_in_irq_status(C_HIRQ_COUNT-1 downto 0));
            txd(C_HREG_DEV_STATUS_PCIE_DMAWR_DONE_BIT):=i_dma_mwr_done;
            txd(C_HREG_DEV_STATUS_PCIE_DMARD_DONE_BIT):=i_dma_mrd_done;
            txd(C_HREG_DEV_STATUS_PCIE_ERR_BIT)       :=p_in_mrd_rcv_err;
            txd(C_HREG_DEV_STATUS_DMA_BUSY_BIT)       :=i_dma_work;
            txd(C_HREG_DEV_STATUS_LAST_BIT downto C_HREG_DEV_STATUS_CFG_RDY_BIT):=p_in_dev_status(C_HREG_DEV_STATUS_LAST_BIT downto C_HREG_DEV_STATUS_CFG_RDY_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_DATA, 5) then txd:=EXT(p_in_dev_dout, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_VCTRL_FRMRK, 5) then txd:=p_in_dev_opt(C_HDEV_OPTIN_VCTRL_FRMRK_M_BIT downto C_HDEV_OPTIN_VCTRL_FRMRK_L_BIT);
        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_VCTRL_FRERR, 5) then
          txd(C_HDEV_OPTIN_VCTRL_FRSKIP_M_BIT - C_HDEV_OPTIN_VCTRL_FRSKIP_L_BIT downto 0):=p_in_dev_opt(C_HDEV_OPTIN_VCTRL_FRSKIP_M_BIT downto C_HDEV_OPTIN_VCTRL_FRSKIP_L_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TIME, 5) then txd:=p_in_dev_opt(C_HDEV_OPTIN_TIME_M_BIT downto C_HDEV_OPTIN_TIME_L_BIT);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST0, 5) then
          txd:=EXT(v_reg_tst0, txd'length);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST1, 5) then
          txd(0):=p_in_tst(72);--i_eth_module_gt_plllkdet;
          txd(1):=p_in_tst(73);--lclk_dcm_lock;
          txd(2):=p_in_tst(74);--i_hdd_gt_plldet;
          txd(3):=p_in_tst(75);--i_hdd_dcm_lock;
          txd(4):=p_in_tst(76);--i_memctrl_dcm_lock;
          txd(5):=p_in_tst(77);--AND_reduce(i_host_mem_trained(C_PCFG_MEMCTRL_BANK_COUNT downto 0));
          txd(31 downto 6):=p_in_tst(103 downto 78);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST2, 5) then
          txd(30 downto 0):=v_reg_tst1(30 downto 0);
          txd(31):=p_in_tst(127);

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_FUNC, 5) then
          txd(C_HREG_FUNC_MEM_BIT):='1';
          txd(C_HREG_FUNC_TMR_BIT):='1';
          txd(C_HREG_FUNC_VCTRL_BIT):='1';
          txd(C_HREG_FUNC_ETH_BIT):=strcmp2(C_PCFG_ETH_USE, "ON");
--          txd(C_HREG_FUNC_HDD_BIT):=strcmp2(C_PCFG_HDD_USE, "ON");
          txd(C_HREG_FUNC_VRESEK21_BIT):=strcmp2(C_PCFG_BOARD, "VERESK21");

        elsif vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_FUNCPRM, 5) then

          txd(C_HREG_FUNCPRM_MEMBANK_SIZE_M_BIT downto C_HREG_FUNCPRM_MEMBANK_SIZE_L_BIT):=CONV_STD_LOGIC_VECTOR(C_PCFG_MEMCTRL_BANK_SIZE, C_HREG_FUNCPRM_MEMBANK_SIZE_M_BIT - C_HREG_FUNCPRM_MEMBANK_SIZE_L_BIT +1);

          txd(C_HREG_FUNCPRM_VCTRL_VCH_COUNT_M_BIT downto C_HREG_FUNCPRM_VCTRL_VCH_COUNT_L_BIT):=CONV_STD_LOGIC_VECTOR(C_VCTRL_VCH_COUNT, C_HREG_FUNCPRM_VCTRL_VCH_COUNT_M_BIT - C_HREG_FUNCPRM_VCTRL_VCH_COUNT_L_BIT +1);
          txd(C_HREG_FUNCPRM_VCTRL_MIR_BIT)   :='1';
--          txd(C_HREG_FUNCPRM_VCTRL_ZOOM_BIT)  :=strcmp2(C_PCFG_VCTRL_SIMPLE, "OFF");
--          txd(C_HREG_FUNCPRM_VCTRL_BAYER_BIT) :=strcmp2(C_PCFG_VCTRL_SIMPLE, "OFF");
--          txd(C_HREG_FUNCPRM_VCTRL_PCOLOR_BIT):=strcmp2(C_PCFG_VCTRL_SIMPLE, "OFF");
--          txd(C_HREG_FUNCPRM_VCTRL_GAMMA_BIT) :=strcmp2(C_PCFG_VCTRL_SIMPLE, "OFF");

        end if;

      end if;

      p_out_reg_dout<=txd;

    end if;--if i_reg_rd='1' then
--    i_tst_rd<=tst_rd;
  end if;
end process;



--//--------------------------------------------------------------------------------------------
--//Управление DMA транзакцией (режим Master)
--//--------------------------------------------------------------------------------------------
--Инициализация DMATRN
i_dmatrn_init<=i_dmatrn_init_sw or i_dmatrn_init_hw;

--Стробы выполнения DMATRN_WR/RD
i_dmatrn_mrd_done<=(not v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT) and AND_reduce(i_dmatrn_mem_done)) or i_dmatrn_mrd_done_tmp;--TRN: PC->FPGA
i_dmatrn_mwr_done<=(    v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT) and AND_reduce(i_dmatrn_mem_done)) or i_dmatrn_mwr_done_tmp;--TRN: PC<-FPGA

process(p_in_rst_n,i_usr_grst,p_in_clk)
begin
  if p_in_rst_n='0' or i_usr_grst='1' then
    i_mrd_rcv_size_ok <='0';
    i_dmatrn_mem_done<=(others=>'0');
    sr_memtrn_done<=(others=>'0');
    i_memtrn_done<='0';
    i_dmatrn_mrd_done_tmp<='0';
    i_dmatrn_mwr_done_tmp<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    --Анализ размера принятых данных DMATRN_RD
    if i_dmatrn_init='1' then
      i_mrd_rcv_size_ok <='0';
    else
      if p_in_mrd_rcv_size(31 downto 0)/=(p_in_mrd_rcv_size'range => '0') then
        if ("00"&i_dmatrn_len(31 downto 2))=p_in_mrd_rcv_size(31 downto 0) then
          i_mrd_rcv_size_ok <= '1';
        end if;
      end if;
    end if ;

    --DMATRN_WR/RD завершена
    if i_hdev_adr/=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_hdev_adr'length) or v_reg_pcie(C_HREG_PCIE_SPEED_TESTING_BIT)='1' then
      i_dmatrn_mrd_done_tmp<=i_mrd_rcv_size_ok and p_in_txbuf_wr_last;
      i_dmatrn_mwr_done_tmp<=p_in_mwr_done and sr_rxbuf_rd_last;
      i_dmatrn_mem_done<=(others=>'0');

    else
      i_dmatrn_mrd_done_tmp<='0';
      i_dmatrn_mwr_done_tmp<='0';

      if AND_reduce(i_dmatrn_mem_done)='1' or i_dma_start='1' then
        i_dmatrn_mem_done<=(others=>'0');
      else
        --Core PCIExpress отработало DMATRN
        if ((i_mrd_rcv_size_ok='1' and p_in_txbuf_wr_last ='1') and v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT)='0') or
           ((p_in_mwr_done='1' and sr_rxbuf_rd_last ='1') and v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT)='1') then
          i_dmatrn_mem_done(0)<='1';
        end if;

        --Принял ответ от контроллера pcie2mem_ctrl.vhd
        if i_memtrn_done='1' then
          i_dmatrn_mem_done(1)<='1';
        end if;
      end if;
    end if;

    sr_memtrn_done<=p_in_dev_opt(C_HDEV_OPTIN_MEMTRN_DONE_BIT) & sr_memtrn_done(0 to 1);
    i_memtrn_done<=sr_memtrn_done(1) and not sr_memtrn_done(2);

  end if;
end process;


process(p_in_rst_n,i_usr_grst,p_in_clk)
begin
  if p_in_rst_n='0' or i_usr_grst='1' then

    i_dmatrn_init_sw<='0';
    i_dmatrn_start_sw<='0';

    i_dmatrn_init_hw<='0';
    i_dmatrn_start_hw<='0';

    sr_dmatrn_mrd_done<='0';
    sr_dmatrn_mwr_done<='0';

    i_dmatrn_work<='0';
    i_dma_work<='0';
    i_dma_mrd_done<='0';
    i_dma_mwr_done<='0';

    i_dmatrn_adr<=(others=>'0');
    i_dmatrn_len<=(others=>'0');

    i_dmabuf_num_cnt<=(others=>'0');
    i_dmabuf_done_cnt<=(others=>'0');

    sr_rxbuf_rd_last<='0';

    i_hw_dmaprm_cnt<=(others=>'0');
    i_hw_dmaprm_rd<=(others=>'0');
    i_hw_dmaprm_rd_done<='0';
    sr_hw_dmaprm_rd_done<='0';

    sr_hw_dmaprm_cnt<=(others=>'0');
    sr_hw_dmaprm_rd<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    sr_rxbuf_rd_last<=p_in_rxbuf_rd_last;

    ---------------------------------------------
    --Инициализация и запуск DMATRN
    ---------------------------------------------
    --DMA: первый запуск транзакции (Software start)
    i_dmatrn_init_sw  <=not i_dma_work and sr_hw_dmaprm_rd_done;
    i_dmatrn_start_sw <=i_dmatrn_init_sw;

    --DMA: все последующие запуски транзакции (Hardware start)
    i_dmatrn_init_hw  <=i_dma_work and sr_hw_dmaprm_rd_done;
    i_dmatrn_start_hw <=i_dmatrn_init_hw;

    ---------------------------------------------
    --Отработка буфера DMA
    ---------------------------------------------
    if i_dmatrn_start_sw='1' or i_dmatrn_start_hw='1' then
      i_dmatrn_work<='1';
    elsif i_dmatrn_mrd_done='1' or i_dmatrn_mwr_done='1' then
      i_dmatrn_work<='0';
    end if;
    sr_dmatrn_mwr_done<=i_dmatrn_mwr_done;
    sr_dmatrn_mrd_done<=i_dmatrn_mrd_done;

    ---------------------------------------------
    --Отработка установленого кол-ва буферов DMA
    ---------------------------------------------
    if i_dmatrn_start_sw='1' then
      i_dma_work<='1';
    elsif (i_dmabuf_count=i_dmabuf_done_cnt and (i_dmatrn_mrd_done='1' or i_dmatrn_mwr_done='1')) or i_dma_irq_clr='1' then
      i_dma_work<='0';
    end if;

    --DMATRN: MEMORY READ(PC->FPGA) завершена (Отработано заказаное кол-во буферов)
    if i_dma_start='1' or i_dma_irq_clr='1' then
      i_dma_mrd_done <='0';
    elsif i_dmabuf_count=i_dmabuf_done_cnt and i_dmatrn_mrd_done='1' then
      i_dma_mrd_done <='1';
    end if;

    --DMATRN: MEMORY WRITE(PC<-FPGA) завершена (Отработано заказаное кол-во буферов)
    if i_dma_start='1' or i_dma_irq_clr='1' then
      i_dma_mwr_done <='0';
    elsif i_dmabuf_count=i_dmabuf_done_cnt and i_dmatrn_mwr_done='1' then
      i_dma_mwr_done <='1';
    end if;

    ---------------------------------------------
    --Чтение параметров DMATRN
    ---------------------------------------------
    if i_dma_start='1' or (i_dma_work='1' and (sr_dmatrn_mwr_done='1' or sr_dmatrn_mrd_done='1')) then
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

    --Загрузка параметров DMA
    if sr_hw_dmaprm_rd(0)='1' then
      if sr_hw_dmaprm_cnt="00" then
        i_dmatrn_adr<=i_hw_dmaprm_dout;--Адрес в байтах
      elsif sr_hw_dmaprm_cnt="01" then
        i_dmatrn_len<=i_hw_dmaprm_dout;--Размер в байтах
      end if;
    end if;

    --Подсчет кол-ва тработаных буферов +
    --загрузка индекса стартового буфера
    if i_dma_start='1' then
      i_dmabuf_num_cnt<=i_dmabuf_num;   --Загружаем индекс стартового буфера
      i_dmabuf_done_cnt<=(others=>'0'); --Очищаем счетчик отработаных буферов

    elsif (i_dmatrn_mwr_done='1' or i_dmatrn_mrd_done='1') then
      i_dmabuf_num_cnt<=i_dmabuf_num_cnt+1;
      i_dmabuf_done_cnt<=i_dmabuf_done_cnt+1;
    end if;

  end if;
end process;


--BRAM параметров DMATRN: Адрес буфера в памяти PC; Размер буфера
i_host_dmaprm_adr(9 downto 8)<="01" when vrsk_reg_bar='1' and vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DMAPRM_LEN, 5) else "00";
i_host_dmaprm_adr(7 downto 0)<=EXT(i_dmabuf_num, 8);

i_hw_dmaprm_adr(9 downto 8)<=i_hw_dmaprm_cnt;
i_hw_dmaprm_adr(7 downto 0)<=EXT(i_dmabuf_num_cnt, 8);

m_bram_dmaprms : bram_dma_params
port map
(
addra => i_host_dmaprm_adr,
dina  => i_host_dmaprm_din,
douta => i_host_dmaprm_dout,
ena   => '1',
wea   => i_host_dmaprm_wr,
clka  => p_in_clk,


addrb => i_hw_dmaprm_adr,
dinb  => (others=>'0'),
doutb => i_hw_dmaprm_dout,
enb   => i_hw_dmaprm_rd(0),
web   => "0",              --Только чтение
clkb  => p_in_clk
);


--//-------------------------------------------------------
--//Связь с модулем управления прерываниями
--//-------------------------------------------------------
p_out_irq_clr<=i_irq_clr;
p_out_irq_num<=EXT(i_irq_num, p_out_irq_num'length);
p_out_irq_set<=EXT(i_irq_set, p_out_irq_set'length);

--от DMA(WR/RD)
i_irq_set(C_HIRQ_PCIE_DMA)<=i_irq_en(C_HIRQ_PCIE_DMA) and ((i_dma_mrd_done and sr_dmatrn_mrd_done) or
                                                           (i_dma_mwr_done and sr_dmatrn_mwr_done));
--от пользовательских устройств
gen_irq: for i in C_HIRQ_PCIE_DMA+1 to C_HIRQ_COUNT - 1 generate

--Выделяю передний фронт
process(i_irq_en(i),i_usr_grst,p_in_clk)
begin
  if i_irq_en(i)='0' or i_usr_grst='1' then
      sr_irq_set(i)<=(others=>'0');
      i_irq_set(i)<='0';
  elsif p_in_clk'event and p_in_clk='1' then
      sr_irq_set(i)<=p_in_dev_irq(i)& sr_irq_set(i)(0 to 1);
      i_irq_set(i)<=sr_irq_set(i)(1) and not sr_irq_set(i)(2);
  end if;
end process;

end generate gen_irq;


--//-------------------------------------------------------------------
--//Сигналы для модулей TX/RX PCI-Express
--//-------------------------------------------------------------------
p_out_rxbuf_dout <=p_in_dev_dout;
p_out_txbuf_full <=p_in_dev_opt(C_HDEV_OPTIN_TXFIFO_PFULL_BIT) when i_hdev_adr/=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_hdev_adr'length) else
                   p_in_dev_opt(C_HDEV_OPTIN_TXFIFO_PFULL_BIT) and not v_reg_pcie(C_HREG_PCIE_SPEED_TESTING_BIT);
p_out_rxbuf_empty<=p_in_dev_opt(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT) when i_hdev_adr/=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_hdev_adr'length) else
                   p_in_dev_opt(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT) and not v_reg_pcie(C_HREG_PCIE_SPEED_TESTING_BIT);


--//-------------------------------------------------------------------
--//Связь с внешним устройствам
--//-------------------------------------------------------------------
--Выбор доступа к внешним устройствам. Через DMA транзакцию или через регистр C_HREG_DEV_DATA
p_out_dev_wr  <= i_txbuf_wr     when v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT)='1' else
                 p_in_reg_wr    when vrsk_reg_bar='1' and vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_DATA, 5) else '0';

p_out_dev_rd  <= p_in_rxbuf_rd  when v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT)='1' else
                 i_reg_rd       when vrsk_reg_bar='1' and vrsk_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_DATA, 5) else '0';

p_out_dev_din <= i_txbuf_din when v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT)='1' else EXT(p_in_reg_din, p_out_dev_din'length);


i_txbuf_din <= p_in_txbuf_din & sr_txbuf_din;
i_txbuf_wr <= (i_txbuf_wr_sel and p_in_txbuf_wr) or (i_mrd_rcv_size_ok and p_in_txbuf_wr_last);
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    if i_dma_start='1' then
      i_txbuf_wr_sel <= '0';
    else
      if p_in_txbuf_wr = '1' then
        i_txbuf_wr_sel <= not i_txbuf_wr_sel;
      end if;

      sr_txbuf_din <= p_in_txbuf_din;

    end if;
  end if;
end process;


--Вывод регистра управления устройствами
p_out_dev_ctrl(C_HREG_DEV_CTRL_DRDY_BIT)<=i_dmatrn_mrd_done when v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT)='1' and i_dmabuf_count=i_dmabuf_done_cnt else i_dev_drdy;
p_out_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT)<=sr_dma_start when i_hdev_adr/=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_hdev_adr'length) else i_dmatrn_init and not v_reg_pcie(C_HREG_PCIE_SPEED_TESTING_BIT);
p_out_dev_ctrl(C_HREG_DEV_CTRL_LAST_BIT downto C_HREG_DEV_CTRL_DMA_START_BIT+1)<=v_reg_dev_ctrl(C_HREG_DEV_CTRL_LAST_BIT downto C_HREG_DEV_CTRL_DMA_START_BIT+1);


--Вывод регистра глобального управления
p_out_gctrl(C_HREG_CTRL_RST_ALL_BIT)<=v_reg_ctrl(C_HREG_CTRL_RST_ALL_BIT);
p_out_gctrl(C_HREG_CTRL_RST_MEM_BIT)<=v_reg_ctrl(C_HREG_CTRL_RST_MEM_BIT);
p_out_gctrl(C_HREG_CTRL_RST_ETH_BIT)<=v_reg_ctrl(C_HREG_CTRL_RST_ETH_BIT);
p_out_gctrl(C_HREG_CTRL_RDDONE_VCTRL_BIT)<=i_rddone_vctrl;
p_out_gctrl(C_HREG_CTRL_LAST_BIT downto C_HREG_CTRL_RDDONE_VCTRL_BIT + 1)<=v_reg_ctrl(C_HREG_CTRL_LAST_BIT downto C_HREG_CTRL_RDDONE_VCTRL_BIT + 1);


--Доп. информация для управления умаройствами
i_mem_adr_en<=p_in_rxbuf_rd or p_in_txbuf_wr when i_hdev_adr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_hdev_adr'length) else '0';
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    if i_dma_start='1' then
      i_mem_adr<=EXT(v_reg_mem_adr(v_reg_mem_adr'high downto 2), i_mem_adr'length); --Cnt DW
    else
      if i_mem_adr_en='1' then
        i_mem_adr<=i_mem_adr + 1;
      end if;
    end if;
  end if;
end process;

p_out_dev_opt(C_HDEV_OPTOUT_MEM_ADR_M_BIT downto C_HDEV_OPTOUT_MEM_ADR_L_BIT)<=i_mem_adr(29 downto 0)&"00"; --Cnt BYTE
p_out_dev_opt(C_HDEV_OPTOUT_MEM_RQLEN_M_BIT downto C_HDEV_OPTOUT_MEM_RQLEN_L_BIT)<=i_dmatrn_len(C_HDEV_OPTOUT_MEM_RQLEN_M_BIT - C_HDEV_OPTOUT_MEM_RQLEN_L_BIT downto 0);
p_out_dev_opt(C_HDEV_OPTOUT_MEM_TRNWR_LEN_M_BIT downto C_HDEV_OPTOUT_MEM_TRNWR_LEN_L_BIT)<=v_reg_mem_ctrl(C_HREG_MEM_CTRL_TRNWR_M_BIT downto C_HREG_MEM_CTRL_TRNWR_L_BIT);
p_out_dev_opt(C_HDEV_OPTOUT_MEM_TRNRD_LEN_M_BIT downto C_HDEV_OPTOUT_MEM_TRNRD_LEN_L_BIT)<=v_reg_mem_ctrl(C_HREG_MEM_CTRL_TRNRD_M_BIT downto C_HREG_MEM_CTRL_TRNRD_L_BIT);
p_out_dev_opt(C_HDEV_OPTOUT_TIME_M_BIT downto C_HDEV_OPTOUT_TIME_L_BIT)<=v_reg_time;
p_out_dev_opt(C_HDEV_OPTOUT_TIME_SET_BIT)<=i_time_set;


--//-------------------------------------------------------------------
--//DBG
--//-------------------------------------------------------------------
p_out_tst(31 downto 0)  <=v_reg_tst0;
--p_out_tst(63 downto 32) <=v_reg_tst1;
p_out_tst(47 downto 32) <=EXT(p_in_rx_engine_tst2, 16);--p_in_mrd_pkt_len_tst(15 downto 0);
--p_out_tst(39 downto 32) <=i_dmabuf_num_cnt;
--p_out_tst(47 downto 40) <=i_dmabuf_done_cnt;
p_out_tst(55 downto 48) <=i_dmabuf_count;
p_out_tst(57 downto 56) <=i_dmatrn_mem_done;
p_out_tst(61 downto 58) <=i_hdev_adr;
p_out_tst(62)           <=p_in_mrd_rcv_err;
p_out_tst(63)           <=vrsk_reg_bar and (p_in_reg_wr or i_reg_rd);
p_out_tst(95 downto 64) <=p_in_mrd_rcv_size;
p_out_tst(96)           <=i_irq_clr;
p_out_tst(100 downto 97)<=i_irq_num(3 downto 0);
p_out_tst(108 downto 101)<=p_in_irq_status(7 downto 0);
p_out_tst(116 downto 109)<=EXT(i_irq_set(7 downto 0), 8);
p_out_tst(117)           <=i_dma_mwr_done and sr_dmatrn_mwr_done;
p_out_tst(118)           <=i_dma_mrd_done and sr_dmatrn_mrd_done;
p_out_tst(119)           <=i_dmatrn_mwr_done;
p_out_tst(120)           <=p_in_throttle_tst(0); --//mrd_work_throttle
p_out_tst(121)           <=i_mrd_rcv_size_ok;
p_out_tst(122)           <=i_dmatrn_mrd_done;
p_out_tst(123)           <=i_dmatrn_init;
p_out_tst(124)           <=i_dma_start;
p_out_tst(125)           <=i_txbuf_wr or p_in_rxbuf_rd;
p_out_tst(126)           <=p_in_rxbuf_rd_last;
p_out_tst(127)           <=p_in_txbuf_wr_last;




--END MAIN
end behavioral;


