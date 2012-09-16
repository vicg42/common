-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.08.2012 17:22:12
-- Module Name : pcie_tx.v
--
-- Description : PCI txd
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

library work;
use work.vicg_common_pkg.all;
use work.pcie_pkg.all;

entity pcie_tx is
--generic(
--G_PCIE_TRN_DBUS : integer:=64
--);
port(
--usr app
usr_reg_dout_i         : in   std_logic_vector(31 downto 0);

--usr_rxbuf_dbe          : out  std_logic_vector(3 downto 0);
usr_rxbuf_dout_i       : in   std_logic_vector(31 downto 0);
usr_rxbuf_rd_o         : out  std_logic;
usr_rxbuf_rd_last_o    : out  std_logic;
usr_rxbuf_empty_i      : in   std_logic;

--pci_core <- usr_app
trn_td                 : out  std_logic_vector(127 downto 0);
trn_trem_n             : out  std_logic_vector(3 downto 0);
trn_tsof_n             : out  std_logic;
trn_teof_n             : out  std_logic;
trn_tsrc_rdy_n_o       : out  std_logic;             --usr_app - rdy
trn_tsrc_dsc_n         : out  std_logic;
trn_tdst_rdy_n         : in   std_logic;             --pci_core - rdy
trn_tdst_dsc_n         : in   std_logic;
trn_tbuf_av            : in   std_logic_vector(5 downto 0);

--Handshake with Rx engine
req_compl_i            : in   std_logic;
compl_done_o           : out  std_logic;

req_addr_i             : in   std_logic_vector(29 downto 0);
req_pkt_type_i         : in   std_logic_vector(6 downto 0);
req_tc_i               : in   std_logic_vector(2 downto 0);
req_td_i               : in   std_logic;
req_ep_i               : in   std_logic;
req_attr_i             : in   std_logic_vector(1 downto 0);
req_len_i              : in   std_logic_vector(9 downto 0);
req_rid_i              : in   std_logic_vector(15 downto 0);
req_tag_i              : in   std_logic_vector(7 downto 0);
req_be_i               : in   std_logic_vector(7 downto 0);
req_exprom_i           : in   std_logic;

--dma trn
dma_init_i             : in   std_logic;

mwr_en_i               : in   std_logic;
mwr_len_i              : in   std_logic_vector(31 downto 0);
mwr_tag_i              : in   std_logic_vector(7 downto 0);
mwr_lbe_i              : in   std_logic_vector(3 downto 0);
mwr_fbe_i              : in   std_logic_vector(3 downto 0);
mwr_addr_i             : in   std_logic_vector(31 downto 0);
mwr_count_i            : in   std_logic_vector(31 downto 0);
mwr_done_o             : out  std_logic;
mwr_tlp_tc_i           : in   std_logic_vector(2 downto 0);
mwr_64b_en_i           : in   std_logic;
mwr_phant_func_en1_i   : in   std_logic;
mwr_addr_up_i          : in   std_logic_vector(7 downto 0);
mwr_relaxed_order_i    : in   std_logic;
mwr_nosnoop_i          : in   std_logic;

mrd_en_i               : in   std_logic;
mrd_len_i              : in   std_logic_vector(31 downto 0);
mrd_tag_i              : in   std_logic_vector(7 downto 0);
mrd_lbe_i              : in   std_logic_vector(3 downto 0);
mrd_fbe_i              : in   std_logic_vector(3 downto 0);
mrd_addr_i             : in   std_logic_vector(31 downto 0);
mrd_count_i            : in   std_logic_vector(31 downto 0);
mrd_tlp_tc_i           : in   std_logic_vector(2 downto 0);
mrd_64b_en_i           : in   std_logic;
mrd_phant_func_en1_i   : in   std_logic;
mrd_addr_up_i          : in   std_logic_vector(7 downto 0);
mrd_relaxed_order_i    : in   std_logic;
mrd_nosnoop_i          : in   std_logic;
mrd_pkt_len_o          : out  std_logic_vector(31 downto 0);
mrd_pkt_count_o        : out  std_logic_vector(15 downto 0);--Кол-во отправленых пакетов MRr

completer_id_i         : in   std_logic_vector(15 downto 0);
tag_ext_en_i           : in   std_logic;
master_en_i            : in   std_logic;
max_payload_size_i     : in   std_logic_vector(2 downto 0);
max_rd_req_size_i      : in   std_logic_vector(2 downto 0);

--Технологический
tst_o                  : out  std_logic_vector(31 downto 0);
tst_i                  : in   std_logic_vector(31 downto 0);

--System
clk                    : in   std_logic;
rst_n                  : in   std_logic
);
end pcie_tx;

architecture behavioral of pcie_tx is

type TFsm_state is (
S_TX_IDLE    ,
S_TX_CPLD_WT1,
S_TX_MWR_QW1 ,
S_TX_MWR_QWN ,
S_TX_MRD_QW1
--S_TX_CPLD_WT0,
--S_TX_MRD_QW0 ,
--S_TX_MWR_QW0
);
signal fsm_state            : TFsm_state;

signal i_trn_trem_n         : std_logic_vector(trn_td'length/64-1 downto 0);
signal i_trn_td             : std_logic_vector(trn_td'range);
signal i_trn_tsof_n         : std_logic;
signal i_trn_teof_n         : std_logic;
signal i_trn_tsrc_rdy_n     : std_logic;

signal byte_count           : std_logic_vector(11 downto 0);
signal lower_addr           : std_logic_vector(6 downto 0);

signal sr_req_compl         : std_logic;

signal mwr_done             : std_logic;
signal mwr_addr_req         : std_logic_vector(31 downto 0);
signal mwr_fbe              : std_logic_vector(3 downto 0);
signal mwr_lbe              : std_logic_vector(3 downto 0);
signal mwr_fbe_req          : std_logic_vector(3 downto 0);
signal mwr_lbe_req          : std_logic_vector(3 downto 0);
signal pmwr_addr            : std_logic_vector(31 downto 0); --Указатель адреса записи данных в память хоста
signal mwr_pkt_count_req    : std_logic_vector(15 downto 0); --Кол-во пакетов MWr которые необходимо отправить PC
signal mwr_pkt_count        : std_logic_vector(15 downto 0); --Кол-во отправленых пакетов MWr
signal mwr_len_byte         : std_logic_vector(12 downto 0); --Размер одного пакета MWr в байт (учавствует в вычислении pmwr_addr)
signal mwr_len_dw_req       : std_logic_vector(10 downto 0);
signal mwr_len_dw           : std_logic_vector(10 downto 0); --Сколько DW осталось отправить в текущем пакете.

signal mrd_done             : std_logic;
signal mrd_addr_req         : std_logic_vector(31 downto 0);
signal mrd_fbe              : std_logic_vector(3 downto 0);
signal mrd_lbe              : std_logic_vector(3 downto 0);
signal mrd_fbe_req          : std_logic_vector(3 downto 0);
signal mrd_lbe_req          : std_logic_vector(3 downto 0);
signal pmrd_addr            : std_logic_vector(31 downto 0); --Указатель адреса чтения данных памяти PC
signal mrd_pkt_count_req    : std_logic_vector(15 downto 0); --Кол-во пакетов MRd которые необходимо отправить PC
signal mrd_pkt_count        : std_logic_vector(15 downto 0); --Кол-во отправлены пакетов MRr (запрос чтения)
signal mrd_len_byte         : std_logic_vector(12 downto 0); --Размер одного пакета MRd в байт (учавствует в вычислении pmrd_addr)
signal mrd_len_dw_req       : std_logic_vector(10 downto 0);
signal mrd_len_dw           : std_logic_vector(10 downto 0);
signal mrd_len_dw_init      : std_logic_vector(10 downto 0);

signal mwr_work             : std_logic;
signal trn_dw_sel           : std_logic_vector(trn_td'length/64-1 downto 0);
signal usr_rxbuf_rd         : std_logic;
signal i_dma_init           : std_logic;
signal i_dma_init_clr       : std_logic;
signal i_compl_done         : std_logic;


--//MAIN
begin

--//--------------------------------------
--//
--//--------------------------------------
mrd_pkt_count_o <= mrd_pkt_count + 1;
mrd_pkt_len_o <= EXT(mrd_len_dw_init, mrd_pkt_len_o'length) when i_dma_init='1' else
                 EXT(mrd_len_dw, mrd_pkt_len_o'length);

usr_rxbuf_rd <= (not trn_tdst_rdy_n and trn_tdst_dsc_n and not usr_rxbuf_empty_i);
usr_rxbuf_rd_o <= usr_rxbuf_rd and mwr_work;
usr_rxbuf_rd_last_o <= usr_rxbuf_rd and mwr_work when mwr_len_dw = CONV_STD_LOGIC_VECTOR(16#01#, mwr_len_dw'length) else '0';

trn_tsrc_dsc_n <= '1';
trn_tsrc_rdy_n_o <= i_trn_tsrc_rdy_n or OR_reduce(trn_dw_sel) or (usr_rxbuf_empty_i and mwr_work);
trn_tsof_n <= i_trn_tsof_n;
trn_teof_n <= i_trn_teof_n;
trn_trem_n <= EXT(i_trn_trem_n, trn_trem_n'length);
trn_td <= i_trn_td;

mwr_done_o <= mwr_done;
compl_done_o <= i_compl_done;

-- Calculate byte count based on byte enable
process (req_be_i)
begin
  case req_be_i(3 downto 0) is
    when "1001" | "1011" | "1101" | "1111" =>
      byte_count <= X"004";
    when "0101" | "0111" =>
      byte_count <= X"003";
    when "1010" | "1110" =>
      byte_count <= X"003";
    when "0011" =>
      byte_count <= X"002";
    when "0110" =>
      byte_count <= X"002";
    when "1100" =>
      byte_count <= X"002";
    when "0001" =>
      byte_count <= X"001";
    when "0010" =>
      byte_count <= X"001";
    when "0100" =>
      byte_count <= X"001";
    when "1000" =>
      byte_count <= X"001";
    when "0000" =>
      byte_count <= X"001";
    when others =>
      byte_count <= X"000";
  end case;
end process;

-- Calculate lower address based on  byte enable
process (req_be_i, req_addr_i)
begin

  case req_be_i(3 downto 0) is
    when "0000" =>
      lower_addr <= (req_addr_i(4 downto 0) & "00");
    when "0001" | "0011" | "0101" | "0111" | "1001" | "1011" | "1101" | "1111" =>
      lower_addr <= (req_addr_i(4 downto 0) & "00");
    when "0010" | "0110" | "1010" | "1110" =>
      lower_addr <= (req_addr_i(4 downto 0) & "01");
    when "0100" | "1100" =>
      lower_addr <= (req_addr_i(4 downto 0) & "10");
    when "1000" =>
      lower_addr <= (req_addr_i(4 downto 0) & "11");
    when others =>
      lower_addr <= (req_addr_i(4 downto 0) & "00");
  end case;
end process;


process(rst_n, clk)
begin
  if rst_n='0' then
    sr_req_compl <= '0';
    i_dma_init <= '0';

    mwr_done <= '0';
    mwr_addr_req <= (others=>'0');
    mwr_pkt_count_req <= (others=>'0');
    mwr_len_dw_req <= (others=>'0');
    mwr_fbe_req <= (others=>'0');
    mwr_lbe_req <= (others=>'0');

    mrd_done <= '0';
    mrd_addr_req <= (others=>'0');
    mrd_pkt_count_req <= (others=>'0');
    mrd_len_dw_req <= (others=>'0');
    mrd_fbe_req <= (others=>'0');
    mrd_lbe_req <= (others=>'0');

  elsif clk'event and clk='1' then

    sr_req_compl <= req_compl_i;

    if i_dma_init_clr='1' then
      i_dma_init <= '0';
    elsif dma_init_i='1' then
     i_dma_init <= '1';
    end if;

    if dma_init_i='1' then --Инициализация перед началом DMA транзакции
        mwr_done <= '0';
        mwr_addr_req <= mwr_addr_i;
        mwr_pkt_count_req <= mwr_count_i(15 downto 0);
        mwr_len_dw_req <= mwr_len_i(10 downto 0);
        mwr_fbe_req <= mwr_fbe_i;
        mwr_lbe_req <= mwr_lbe_i;

        mrd_done <= '0';
        mrd_addr_req <= mrd_addr_i;
        mrd_pkt_count_req <= mrd_count_i(15 downto 0);
        mrd_len_dw_req <= mrd_len_i(10 downto 0);
        mrd_fbe_req <= mrd_fbe_i;
        mrd_lbe_req <= mrd_lbe_i;

        if (mrd_count_i(15 downto 0) - 1) = CONV_STD_LOGIC_VECTOR(16#00#, 16) then
          mrd_len_dw_init(10 downto 0) <= mrd_len_i(10 downto 0);
        else
          if    max_rd_req_size_i = C_PCIE_MAX_RD_REQ_1024_BYTE then mrd_len_dw_init <= CONV_STD_LOGIC_VECTOR(16#100#, mrd_len_dw_init'length);
          elsif max_rd_req_size_i = C_PCIE_MAX_RD_REQ_512_BYTE  then mrd_len_dw_init <= CONV_STD_LOGIC_VECTOR(16#080#, mrd_len_dw_init'length);
          elsif max_rd_req_size_i = C_PCIE_MAX_RD_REQ_256_BYTE  then mrd_len_dw_init <= CONV_STD_LOGIC_VECTOR(16#040#, mrd_len_dw_init'length);
          else                                                       mrd_len_dw_init <= CONV_STD_LOGIC_VECTOR(16#020#, mrd_len_dw_init'length);
          end if;
        end if;

    elsif ((fsm_state = S_TX_MWR_QW1) or (fsm_state = S_TX_MWR_QWN)) and
          usr_rxbuf_rd='1' and mwr_work='1' and
          (mwr_len_dw = CONV_STD_LOGIC_VECTOR(16#01#, mwr_len_dw'length)) and (mwr_pkt_count = (mwr_pkt_count_req - 1)) then
          mwr_done <= '1'; --Транзакция завершена

    elsif fsm_state = S_TX_MRD_QW1 and
          trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' and
          (mrd_pkt_count = (mrd_pkt_count_req - 1)) then
          mrd_done <= '1'; --Транзакция завершена
    end if;
  end if;
end process;


--Tx State Machine
process(rst_n, clk)
begin
  if rst_n='0' then

    fsm_state <= S_TX_IDLE;

    i_trn_tsof_n <= '1';
    i_trn_teof_n <= '1';
    i_trn_tsrc_rdy_n <= '1';
    i_trn_td <= (others=>'0');
    i_trn_trem_n <= (others=>'0');

    mwr_pkt_count <= (others=>'0');
    mwr_len_byte <= (others=>'0');
    mwr_len_dw <= (others=>'0');
    pmwr_addr <= (others=>'0');
    mwr_fbe <= (others=>'0');
    mwr_lbe <= (others=>'0');

    mrd_pkt_count <= (others=>'0');
    pmrd_addr <= (others=>'0');
    mrd_len_dw <= (others=>'0');
    mrd_fbe <= (others=>'0');
    mrd_lbe <= (others=>'0');

    i_compl_done <= '0';
    trn_dw_sel <= (others=>'0');
    mwr_work <= '0';
    i_dma_init_clr<='0';

  elsif clk'event and clk='1' then

    case fsm_state is
        --#######################################################################
        --
        --#######################################################################
        when S_TX_IDLE =>

            -------------------------------------------------------
            --CplD - 3DW, +data;  Cpl - 3DW
            -------------------------------------------------------
            if trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' and trn_tbuf_av(C_PCIE_BUF_COMPLETION_QUEUE)='1' and
                sr_req_compl='1' and i_compl_done='0' then

                i_trn_tsof_n <= '0';
                i_trn_teof_n <= '0';
                i_trn_tsrc_rdy_n <= '0';
                if (req_pkt_type_i = C_PCIE_PKT_TYPE_IORD_3DW_ND) or (req_pkt_type_i = C_PCIE_PKT_TYPE_MRD_3DW_ND) then
                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#00#, i_trn_trem_n'length);
                else
                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);
                end if;

                i_trn_td(127) <= '0';

                if (req_pkt_type_i = C_PCIE_PKT_TYPE_IORD_3DW_ND) or (req_pkt_type_i = C_PCIE_PKT_TYPE_MRD_3DW_ND) then
                  i_trn_td(126 downto 120) <= C_PCIE_PKT_TYPE_CPLD_3DW_WD;
                else
                  i_trn_td(126 downto 120) <= C_PCIE_PKT_TYPE_CPL_3DW_ND;
                end if;

                i_trn_td(119 downto 32) <= ('0' &
                           req_tc_i &
                           "0000" &
                           req_td_i &
                           req_ep_i &
                           req_attr_i &
                           "00" &
                           req_len_i &
                           completer_id_i &
                           "000" &
                           '0' &
                           byte_count &
                           req_rid_i &
                           req_tag_i &
                           '0' &
                           lower_addr);

                if req_exprom_i='1' then
                  i_trn_td(31 downto 0) <= (others=>'0');
                else
                  i_trn_td(31 downto 0) <= usr_reg_dout_i( 7 downto  0) &
                                           usr_reg_dout_i(15 downto  8) &
                                           usr_reg_dout_i(23 downto 16) &
                                           usr_reg_dout_i(31 downto 24);
                end if;

                i_compl_done <= '1';
                fsm_state <= S_TX_CPLD_WT1;
--                i_trn_tsof_n <= '0';
--                i_trn_teof_n <= '1';
--                i_trn_tsrc_rdy_n <= '0';
--                i_trn_trem_n <= (others=>'0');
--
--                i_trn_td(63) <= '0';
--
--                if (req_pkt_type_i = C_PCIE_PKT_TYPE_IORD_3DW_ND) or (req_pkt_type_i = C_PCIE_PKT_TYPE_MRD_3DW_ND) then
--                i_trn_td(62 downto 56) <= C_PCIE_PKT_TYPE_CPLD_3DW_WD;
--                else
--                i_trn_td(62 downto 56) <= C_PCIE_PKT_TYPE_CPL_3DW_ND;
--                end if;
--                i_trn_td(55 downto 0) <= ('0' &
--                          req_tc_i &
--                         "0000" &
--                          req_td_i &
--                          req_ep_i &
--                          req_attr_i &
--                         "00" &
--                          req_len_i &
--                          completer_id_i &
--                         "000" &
--                         '0' &
--                         byte_count);
--
--                fsm_state <= S_TX_CPLD_WT0;

            -------------------------------------------------------
            --MWr - 3DW, +data (PC<-FPGA) FPGA is PCIe master
            -------------------------------------------------------
            elsif usr_rxbuf_rd='1' and trn_tbuf_av(C_PCIE_BUF_POSTED_QUEUE)='1' and
                sr_req_compl='0' and i_compl_done='0' and
                mwr_en_i='1' and mwr_done='0' and master_en_i='1' then

                if (i_dma_init='0' and (mwr_pkt_count = (mwr_pkt_count_req - 1))) or
                   (i_dma_init='1' and ((mwr_pkt_count_req - 1)=CONV_STD_LOGIC_VECTOR(16#00#, mwr_pkt_count_req'length))) then
                  mwr_len_dw(10 downto 0) <= mwr_len_dw_req(10 downto 0);
                  mwr_fbe <= mwr_fbe_req;
                  mwr_lbe <= mwr_lbe_req;
                else
                    mwr_fbe <= CONV_STD_LOGIC_VECTOR(16#0F#, mwr_fbe'length);
                    mwr_lbe <= CONV_STD_LOGIC_VECTOR(16#0F#, mwr_fbe'length);

                    if    (max_payload_size_i = C_PCIE_MAX_PAYLOAD_1024_BYTE) then mwr_len_dw <= CONV_STD_LOGIC_VECTOR(16#100#, mwr_len_dw'length);
                    elsif (max_payload_size_i = C_PCIE_MAX_PAYLOAD_512_BYTE)  then mwr_len_dw <= CONV_STD_LOGIC_VECTOR(16#080#, mwr_len_dw'length);
                    elsif (max_payload_size_i = C_PCIE_MAX_PAYLOAD_256_BYTE)  then mwr_len_dw <= CONV_STD_LOGIC_VECTOR(16#040#, mwr_len_dw'length);
                    else                                                           mwr_len_dw <= CONV_STD_LOGIC_VECTOR(16#020#, mwr_len_dw'length);
                    end if;
                end if;

                if    (max_payload_size_i = C_PCIE_MAX_PAYLOAD_1024_BYTE) then mwr_len_byte <= CONV_STD_LOGIC_VECTOR(16#400#, mwr_len_byte'length);--4 * mwr_len_dw;
                elsif (max_payload_size_i = C_PCIE_MAX_PAYLOAD_512_BYTE)  then mwr_len_byte <= CONV_STD_LOGIC_VECTOR(16#200#, mwr_len_byte'length);--4 * mwr_len_dw
                elsif (max_payload_size_i = C_PCIE_MAX_PAYLOAD_256_BYTE)  then mwr_len_byte <= CONV_STD_LOGIC_VECTOR(16#100#, mwr_len_byte'length);--4 * mwr_len_dw
                else                                                           mwr_len_byte <= CONV_STD_LOGIC_VECTOR(16#080#, mwr_len_byte'length);--4 * mwr_len_dw
                end if;

                if i_dma_init='1' then
                  pmwr_addr <= mwr_addr_req;
                  mwr_pkt_count <= (others=>'0');
                end if;
                i_dma_init_clr<='1';

                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '1';
                i_trn_trem_n <= (others=>'0');
                mwr_work <= '1';
                fsm_state <= S_TX_MWR_QW1;
--                i_trn_tsof_n <= '1';
--                i_trn_teof_n <= '1';
--                i_trn_tsrc_rdy_n <= '1';
--                i_trn_trem_n <= (others=>'0');
--                fsm_state <= S_TX_MWR_QW0;

            -------------------------------------------------------
            --MRd - 3DW, no data (PC<-FPGA) FPGA is PCIe master
            -------------------------------------------------------
            elsif trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' and trn_tbuf_av(C_PCIE_BUF_NON_POSTED_QUEUE)='1' and
                sr_req_compl='0' and i_compl_done='0' and
                mrd_en_i='1' and mrd_done='0' and master_en_i='1' then

                if (i_dma_init='0' and (mrd_pkt_count = (mrd_pkt_count_req - 1))) or
                   (i_dma_init='1' and ((mrd_pkt_count_req - 1)=CONV_STD_LOGIC_VECTOR(16#00#, mrd_pkt_count_req'length))) then
                  mrd_len_dw(10 downto 0) <= mrd_len_dw_req(10 downto 0);
                  mrd_fbe <= mrd_fbe_req;
                  mrd_lbe <= mrd_lbe_req;
                else
                    mrd_fbe <= CONV_STD_LOGIC_VECTOR(16#0F#, mrd_fbe'length);
                    mrd_lbe <= CONV_STD_LOGIC_VECTOR(16#0F#, mrd_lbe'length);

                    if    max_rd_req_size_i = C_PCIE_MAX_RD_REQ_1024_BYTE then mrd_len_dw <= CONV_STD_LOGIC_VECTOR(16#100#, mrd_len_dw'length);
                    elsif max_rd_req_size_i = C_PCIE_MAX_RD_REQ_512_BYTE  then mrd_len_dw <= CONV_STD_LOGIC_VECTOR(16#080#, mrd_len_dw'length);
                    elsif max_rd_req_size_i = C_PCIE_MAX_RD_REQ_256_BYTE  then mrd_len_dw <= CONV_STD_LOGIC_VECTOR(16#040#, mrd_len_dw'length);
                    else                                                       mrd_len_dw <= CONV_STD_LOGIC_VECTOR(16#020#, mrd_len_dw'length);
                    end if;
                end if;

                if    max_rd_req_size_i = C_PCIE_MAX_RD_REQ_1024_BYTE then mrd_len_byte <= CONV_STD_LOGIC_VECTOR(16#400#, mrd_len_byte'length);--4 * mrd_len_dw;
                elsif max_rd_req_size_i = C_PCIE_MAX_RD_REQ_512_BYTE  then mrd_len_byte <= CONV_STD_LOGIC_VECTOR(16#200#, mrd_len_byte'length);--4 * mrd_len_dw
                elsif max_rd_req_size_i = C_PCIE_MAX_RD_REQ_256_BYTE  then mrd_len_byte <= CONV_STD_LOGIC_VECTOR(16#100#, mrd_len_byte'length);--4 * mrd_len_dw
                else                                                       mrd_len_byte <= CONV_STD_LOGIC_VECTOR(16#080#, mrd_len_byte'length);--4 * mrd_len_dw
                end if;

                if i_dma_init='1' then
                  pmrd_addr <= mrd_addr_req;
                  mrd_pkt_count <= (others=>'0');
                end if;
                i_dma_init_clr<='1';

                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '1';
                i_trn_trem_n <= (others=>'0');
                fsm_state <= S_TX_MRD_QW1;
--                i_trn_tsof_n <= '1';
--                i_trn_teof_n <= '1';
--                i_trn_tsrc_rdy_n <= '1';
--                i_trn_trem_n <= (others=>'0');
--                fsm_state <= S_TX_MRD_QW0;

            else
                if trn_tdst_rdy_n='0' then
                  i_trn_tsof_n <= '1';
                  i_trn_teof_n <= '1';
                  i_trn_tsrc_rdy_n <= '1';
                  i_trn_trem_n <= (others=>'0');
                end if;

                i_compl_done <= '0';
            end if;
        --end S_TX_IDLE :


        --#######################################################################
        --CplD - 3DW, +data;  Cpl - 3DW (PC<-FPGA)
        --#######################################################################
--        when S_TX_CPLD_WT0 =>
--
--            if trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' then
--
--                i_trn_tsof_n <= '1';
--                i_trn_teof_n <= '0';
--                i_trn_tsrc_rdy_n <= '0';
--                if (req_pkt_type_i = C_PCIE_PKT_TYPE_IORD_3DW_ND) or (req_pkt_type_i = C_PCIE_PKT_TYPE_MRD_3DW_ND) then
--                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#00#, i_trn_trem_n'length);
--                else
--                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);
--                end if;
--
--                i_trn_td(63 downto 32) <= (req_rid_i &
--                           req_tag_i &
--                           '0' &
--                           lower_addr);
--
--                if req_exprom_i='1' then
--                i_trn_td(31 downto 0) <= (others=>'0');
--                else
--                i_trn_td(31 downto 0) <= usr_reg_dout_i( 7 downto  0) &
--                                         usr_reg_dout_i(15 downto  8) &
--                                         usr_reg_dout_i(23 downto 16) &
--                                         usr_reg_dout_i(31 downto 24);
--                end if;
--
--                i_compl_done <= '1';
--                fsm_state <= S_TX_CPLD_WT1;
--            else
--              if trn_tdst_dsc_n='0' then --Ядро прерывало передачу данных
--                fsm_state <= S_TX_CPLD_WT1;
--              end if;
--            end if;
--        --end S_TX_CPLD_WT0 :

        when S_TX_CPLD_WT1 =>

            if trn_tdst_rdy_n='0' or trn_tdst_dsc_n='0' then
                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '1';
                fsm_state <= S_TX_IDLE;
            end if;
        --END: CplD - 3DW, +data;  Cpl - 3DW


        --#######################################################################
        --MWr - 3DW, +data (PC<-FPGA) FPGA is PCIe master
        --#######################################################################
--        when S_TX_MWR_QW0 =>
--
--            i_dma_init_clr<='0';
--            if usr_rxbuf_rd='1' then
--
--                i_trn_tsof_n <= '0';
--                i_trn_teof_n <= '1';
--                i_trn_tsrc_rdy_n <= '0';
--                i_trn_trem_n <= (others=>'0');
--
--                i_trn_td(63 downto 16) <= ('0' &
--                           C_PCIE_PKT_TYPE_MWR_3DW_WD &
--                           '0' &
--                           mwr_tlp_tc_i &
--                           "0000" &
--                           '0' &
--                           '0' &
--                           mwr_relaxed_order_i & mwr_nosnoop_i &
--                           "00" &
--                           mwr_len_dw(9 downto 0) &
--                           completer_id_i(15 downto 3) & mwr_phant_func_en1_i & "00");
--
--                if tag_ext_en_i='1' then
--                i_trn_td(15 downto 8) <= mwr_pkt_count(7 downto 0);
--                else
--                i_trn_td(15 downto 8) <= EXT(mwr_pkt_count(4 downto 0), 8);
--                end if;
--
--                i_trn_td(7 downto 0) <= mwr_lbe & mwr_fbe;
--
--                mwr_work <= '1';
--                fsm_state <= S_TX_MWR_QW1;
--            else
--              if trn_tdst_dsc_n='0' then --Ядро прерывало передачу данных
--                  mwr_work <= '0';
--                  fsm_state <= S_TX_IDLE;
--              end if;
--            end if;
--        --end S_TX_MWR_QW0 :

        when S_TX_MWR_QW1 =>

            i_dma_init_clr<='0';
            if usr_rxbuf_rd='1' and mwr_work='1' then

                i_trn_tsof_n <= '0';
                --i_trn_teof_n <= '1';
                --i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= (others=>'0');

                i_trn_td(127 downto 80) <= ('0' &
                           C_PCIE_PKT_TYPE_MWR_3DW_WD &
                           '0' &
                           mwr_tlp_tc_i &
                           "0000" &
                           '0' &
                           '0' &
                           mwr_relaxed_order_i & mwr_nosnoop_i &
                           "00" &
                           mwr_len_dw(9 downto 0) &
                           completer_id_i(15 downto 3) & mwr_phant_func_en1_i & "00");

                if tag_ext_en_i='1' then
                i_trn_td(79 downto 72) <= mwr_pkt_count(7 downto 0);
                else
                i_trn_td(79 downto 72) <= EXT(mwr_pkt_count(4 downto 0), 8);
                end if;

                i_trn_td(71 downto 0) <= (mwr_lbe & mwr_fbe &
                           pmwr_addr(31 downto 2) & "00" &
                           usr_rxbuf_dout_i( 7 downto  0) &
                           usr_rxbuf_dout_i(15 downto  8) &
                           usr_rxbuf_dout_i(23 downto 16) &
                           usr_rxbuf_dout_i(31 downto 24) );
--                i_trn_tsof_n <= '1';
--                --i_trn_teof_n <= '1';
--                --i_trn_tsrc_rdy_n <= '0';
--                i_trn_trem_n <= (others=>'0');
--
--                i_trn_td <= (pmwr_addr(31 downto 2) & "00" &
--                           usr_rxbuf_dout_i( 7 downto  0) &
--                           usr_rxbuf_dout_i(15 downto  8) &
--                           usr_rxbuf_dout_i(23 downto 16) &
--                           usr_rxbuf_dout_i(31 downto 24) );

                pmwr_addr <= pmwr_addr + EXT(mwr_len_byte, pmwr_addr'length);

                --Счетчик DW(payload) в текущем пакете MWr
                if mwr_len_dw = CONV_STD_LOGIC_VECTOR(16#01#, mwr_len_dw'length) then

                    i_trn_teof_n <= '0';
                    i_trn_tsrc_rdy_n <= '0';
                    trn_dw_sel <= (others=>'0');

                    mwr_work <= '0';

                    --Счетчик отправленых пакетов MWr
                    if mwr_pkt_count = (mwr_pkt_count_req - 1) then
                      mwr_pkt_count <= (others=>'0');
                    else
                      mwr_pkt_count <= mwr_pkt_count + 1;
                    end if;

                    fsm_state <= S_TX_IDLE;
                else
                    i_trn_teof_n <= '1';
                    i_trn_tsrc_rdy_n <= '0';
                    trn_dw_sel <= (others=>'0');

                    mwr_len_dw <= mwr_len_dw - 1;

                    fsm_state <= S_TX_MWR_QWN;
                end if;
            else
              if trn_tdst_dsc_n='0' then --Ядро прерывало передачу данных
--                  i_trn_teof_n <= '0';
                  trn_dw_sel <= (others=>'0');
                  mwr_work <= '0';
                  fsm_state <= S_TX_IDLE;
--                  i_trn_teof_n <= '0';
--                  trn_dw_sel <= (others=>'0');
--                  mwr_work <= '0';
--                  fsm_state <= S_TX_IDLE;
              end if;
            end if;
        --end S_TX_MWR_QW1 :

        when S_TX_MWR_QWN =>

            if usr_rxbuf_rd='1' and mwr_work='1' then
                if    trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#01#, trn_dw_sel'length) then
                  i_trn_td(31 downto 0) <= (usr_rxbuf_dout_i( 7 downto  0) &
                                          usr_rxbuf_dout_i(15 downto  8) &
                                          usr_rxbuf_dout_i(23 downto 16) &
                                          usr_rxbuf_dout_i(31 downto 24));
                elsif trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#02#, trn_dw_sel'length) then
                  i_trn_td(63 downto 32) <= (usr_rxbuf_dout_i( 7 downto  0) &
                                           usr_rxbuf_dout_i(15 downto  8) &
                                           usr_rxbuf_dout_i(23 downto 16) &
                                           usr_rxbuf_dout_i(31 downto 24));
                elsif trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#03#, trn_dw_sel'length) then
                  i_trn_td(31+64 downto 0+64) <= (usr_rxbuf_dout_i( 7 downto  0) &
                                                usr_rxbuf_dout_i(15 downto  8) &
                                                usr_rxbuf_dout_i(23 downto 16) &
                                                usr_rxbuf_dout_i(31 downto 24));
                elsif trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#00#, trn_dw_sel'length) then
                  i_trn_td(63+64 downto 32+64) <= (usr_rxbuf_dout_i( 7 downto  0) &
                                                 usr_rxbuf_dout_i(15 downto  8) &
                                                 usr_rxbuf_dout_i(23 downto 16) &
                                                 usr_rxbuf_dout_i(31 downto 24));
                end if;

--                if trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#01#, trn_dw_sel'length) then
--                  i_trn_td(31 downto  0) <= (usr_rxbuf_dout_i( 7 downto  0) &
--                                           usr_rxbuf_dout_i(15 downto  8) &
--                                           usr_rxbuf_dout_i(23 downto 16) &
--                                           usr_rxbuf_dout_i(31 downto 24));
--                else
--                  i_trn_td(63 downto 32) <= (usr_rxbuf_dout_i( 7 downto  0) &
--                                           usr_rxbuf_dout_i(15 downto  8) &
--                                           usr_rxbuf_dout_i(23 downto 16) &
--                                           usr_rxbuf_dout_i(31 downto 24));
--                end if;

                i_trn_trem_n <= trn_dw_sel - 1;

                --Счетчик DW(payload) в текущем пакете MWr
                if mwr_len_dw = CONV_STD_LOGIC_VECTOR(16#01#, mwr_len_dw'length) then

                    i_trn_tsof_n <= '1';
                    i_trn_teof_n <= '0';
                    i_trn_tsrc_rdy_n <= '0';

                    trn_dw_sel <= (others=>'0');
                    mwr_work <= '0';

                    --Счетчик отправленых пакетов MWr
                    if mwr_pkt_count = (mwr_pkt_count_req - 1) then
                      mwr_pkt_count <= (others=>'0');
                    else
                      mwr_pkt_count <= mwr_pkt_count + 1;
                    end if;

                    fsm_state <= S_TX_IDLE;

                else
                    i_trn_tsof_n <= '1';
                    i_trn_teof_n <= '1';
                    i_trn_tsrc_rdy_n <= '0';

                    trn_dw_sel <= trn_dw_sel - 1;
                    mwr_len_dw <= mwr_len_dw - 1;

                    fsm_state <= S_TX_MWR_QWN;
                end if;
            else
              if trn_tdst_dsc_n='0' then --Ядро прерывало передачу данных
                  i_trn_tsof_n <= '1';
                  i_trn_teof_n <= '0';
                  trn_dw_sel <= (others=>'0');
                  mwr_work <= '0';

                  fsm_state <= S_TX_IDLE;
              end if;
            end if;
        --end S_TX_MWR_QWN :
        --END: MWr - 3DW, +data


        --#######################################################################
        --MRd - 3DW, no data  (PC<-FPGA) (запрос записи в память PC)
        --#######################################################################
--        when S_TX_MRD_QW0 =>
--
--            i_dma_init_clr<='0';
--            if trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' then
--
--                i_trn_tsof_n <= '0';
--                i_trn_teof_n <= '1';
--                i_trn_tsrc_rdy_n <= '0';
--                i_trn_trem_n <= (others=>'0');
--
--                i_trn_td(63 downto 16) <= ('0' &
--                           C_PCIE_PKT_TYPE_MRD_3DW_ND &
--                           '0' &
--                           mrd_tlp_tc_i &
--                           "0000" &
--                           '0' &
--                           '0' &
--                           mrd_relaxed_order_i & mrd_nosnoop_i &
--                           "00" &
--                           mrd_len_dw(9 downto 0) &
--                           completer_id_i(15 downto 3) & mrd_phant_func_en1_i & "00");
--
--                if tag_ext_en_i='1' then
--                i_trn_td(15 downto 8) <= mrd_pkt_count(7 downto 0);
--                else
--                i_trn_td(15 downto 8) <= EXT(mrd_pkt_count(4 downto 0), 8);
--                end if;
--
--                i_trn_td(7 downto 0) <= mrd_lbe & mrd_fbe;
--
--                fsm_state <= S_TX_MRD_QW1;
--            else
--              if trn_tdst_dsc_n='0' then --Ядро прерывало передачу данных
--                fsm_state <= S_TX_IDLE;
--              end if;
--            end if;
--        --end S_TX_MRD_QW0 :

        when S_TX_MRD_QW1 =>

            i_dma_init_clr<='0';
            if trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' then

                i_trn_tsof_n <= '0';
                i_trn_teof_n <= '0';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);

                i_trn_td(127 downto 80) <= ('0' &
                           C_PCIE_PKT_TYPE_MRD_3DW_ND &
                           '0' &
                           mrd_tlp_tc_i &
                           "0000" &
                           '0' &
                           '0' &
                           mrd_relaxed_order_i & mrd_nosnoop_i &
                           "00" &
                           mrd_len_dw(9 downto 0) &
                           completer_id_i(15 downto 3) & mrd_phant_func_en1_i & "00");

                if tag_ext_en_i='1' then
                i_trn_td(79 downto 72) <= mrd_pkt_count(7 downto 0);
                else
                i_trn_td(79 downto 72) <= EXT(mrd_pkt_count(4 downto 0), 8);
                end if;

                i_trn_td(71 downto 0) <= (mrd_lbe & mrd_fbe &
                           pmrd_addr(31 downto 2) & "00" &
                           CONV_STD_LOGIC_VECTOR(16#00#, 32));

--                i_trn_tsof_n <= '1';
--                i_trn_teof_n <= '0';
--                i_trn_tsrc_rdy_n <= '0';
--                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);
--
--                i_trn_td <= (pmrd_addr(31 downto 2) & "00" &
--                           CONV_STD_LOGIC_VECTOR(16#00#, 32));

                pmrd_addr <= pmrd_addr + EXT(mrd_len_byte, pmrd_addr'length);

                --Счетчик отправленых пакетов MRd
                if mrd_pkt_count = (mrd_pkt_count_req - 1) then
                  mrd_pkt_count <= (others=>'0');
                else
                  mrd_pkt_count <= mrd_pkt_count + 1;
                end if;

                fsm_state <= S_TX_IDLE;
            else
              if trn_tdst_dsc_n='0' then --Ядро прерывало передачу данных
--                i_trn_teof_n <= '0';
                fsm_state <= S_TX_IDLE;
--                i_trn_teof_n <= '0';
--                fsm_state <= S_TX_IDLE;
              end if;
            end if;
        --end S_TX_MRD_QW1 :
        --END: MRd - 3DW, no data

    end case; --case fsm_state is
  end if;
end process;


--END MAIN
end behavioral;

