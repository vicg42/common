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
generic(
G_USR_DBUS : integer:=32
);
port(
--usr app
usr_reg_dout_i         : in   std_logic_vector(31 downto 0);

--usr_rxbuf_dbe          : out  std_logic_vector(3 downto 0);
usr_rxbuf_dout_i       : in   std_logic_vector(G_USR_DBUS - 1 downto 0);
usr_rxbuf_rd_o         : out  std_logic;
usr_rxbuf_rd_last_o    : out  std_logic;
usr_rxbuf_empty_i      : in   std_logic;

--pci_core <- usr_app
trn_td                 : out  std_logic_vector(63 downto 0);
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
mrd_pkt_count_o        : out  std_logic_vector(15 downto 0);-- ол-во отправленых пакетов MRr

completer_id_i         : in   std_logic_vector(15 downto 0);
tag_ext_en_i           : in   std_logic;
master_en_i            : in   std_logic;
max_payload_size_i     : in   std_logic_vector(2 downto 0);
max_rd_req_size_i      : in   std_logic_vector(2 downto 0);

--“ехнологический
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
S_TX_MRD_QW1 ,
S_TX_CPLD_WT0,
S_TX_MRD_QW0 ,
S_TX_MWR_QW0,
S_TX_MWR_QW00,
S_TX_MRD_QW00
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
signal i_mwr_adr_cnt        : std_logic_vector(31 downto 0);
signal i_mwr_tx             : std_logic_vector(31 downto 0);
signal i_mwr_remain         : std_logic_vector(31 downto 0);
signal i_mwr_remain_byte    : std_logic_vector(31 downto 0);
signal i_mwr_len_rq         : std_logic_vector(31 downto 0);
signal i_mwr_len_rq_byte    : std_logic_vector(31 downto 0);
signal i_mwr_tpl_max        : std_logic_vector(12 downto 0);--i_mwr_tpl - memory wr transaction payload
signal i_mwr_tpl_max_byte   : std_logic_vector(12 downto 0);
signal i_mwr_tpl_cnt        : std_logic_vector(12 downto 0);
signal i_mwr_tpl_byte       : std_logic_vector(12 downto 0);
signal i_mwr_tpl_dw_tmp     : std_logic_vector(12 downto 0);
signal i_mwr_tpl_dw         : std_logic_vector(12 downto 0);
signal i_mwr_tpl_tag        : std_logic_vector(7 downto 0);

signal mrd_done             : std_logic;
signal i_mrd_adr_cnt        : std_logic_vector(31 downto 0);
signal i_mrd_tx             : std_logic_vector(31 downto 0);
signal i_mrd_remain         : std_logic_vector(31 downto 0);
signal i_mrd_remain_byte    : std_logic_vector(31 downto 0);
signal i_mrd_len_rq         : std_logic_vector(31 downto 0);
signal i_mrd_len_rq_byte    : std_logic_vector(31 downto 0);
signal i_mrd_tpl_max        : std_logic_vector(12 downto 0);--i_mrd_tpl - memory rd transaction payload
signal i_mrd_tpl_max_byte   : std_logic_vector(12 downto 0);
signal i_mrd_tpl_cnt        : std_logic_vector(12 downto 0);
signal i_mrd_tpl_byte       : std_logic_vector(12 downto 0);
signal i_mrd_tpl_dw_tmp     : std_logic_vector(12 downto 0);
signal i_mrd_tpl_dw         : std_logic_vector(12 downto 0);
signal i_mrd_tpl_tag        : std_logic_vector(15 downto 0);

signal mwr_work             : std_logic;
signal trn_dw_sel           : std_logic_vector(trn_td'length/64-1 downto 0);
signal usr_rxbuf_rd         : std_logic;
signal i_dma_init           : std_logic;
signal i_dma_init_clr       : std_logic;
signal i_compl_done         : std_logic;
signal usr_rxbuf_dout_swap  : std_logic_vector(usr_rxbuf_dout_i'range);
signal sr_trn_td            : std_logic_vector(trn_td'range);

--//MAIN
begin

tst_o(0) <= OR_reduce(sr_trn_td);
process(clk)
begin
  if clk'event and clk='1' then
    sr_trn_td <= i_trn_td;
  end if;
end process;

--//--------------------------------------
--//
--//--------------------------------------
mrd_pkt_count_o <= i_mrd_tpl_tag + 1;
mrd_pkt_len_o <= EXT(i_mrd_tpl_max, mrd_pkt_len_o'length) when i_dma_init='1' else
                 EXT(i_mrd_tpl_dw, mrd_pkt_len_o'length);

usr_rxbuf_rd <= (not trn_tdst_rdy_n and trn_tdst_dsc_n and not usr_rxbuf_empty_i);
usr_rxbuf_rd_o <= usr_rxbuf_rd and mwr_work;
usr_rxbuf_rd_last_o <= usr_rxbuf_rd and mwr_work when (i_mwr_tx = i_mwr_len_rq - 1) else '0';

trn_tsrc_dsc_n <= '1';
trn_tsrc_rdy_n_o <= i_trn_tsrc_rdy_n or OR_reduce(trn_dw_sel) or (usr_rxbuf_empty_i and mwr_work);
trn_tsof_n <= i_trn_tsof_n;
trn_teof_n <= i_trn_teof_n;
trn_trem_n <= EXT(i_trn_trem_n, trn_trem_n'length);
trn_td <= i_trn_td;

mwr_done_o <= mwr_done;
compl_done_o <= i_compl_done;

gen_swap : for i in 0 to usr_rxbuf_dout_i'length/8 - 1 generate
usr_rxbuf_dout_swap(8*(((usr_rxbuf_dout_i'length/8 - 1) - i) + 1) - 1 downto
                    8*((usr_rxbuf_dout_i'length/8 - 1) - i)) <= usr_rxbuf_dout_i(8*(i + 1) - 1 downto 8*i);
end generate gen_swap;

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
    i_mwr_len_rq_byte <= (others=>'0');

    mrd_done <= '0';
    i_mrd_len_rq_byte <= (others=>'0');

  elsif clk'event and clk='1' then

    sr_req_compl <= req_compl_i;

    if i_dma_init_clr='1' then
      i_dma_init <= '0';
    elsif dma_init_i='1' then
     i_dma_init <= '1';
    end if;

    if dma_init_i='1' then --»нициализаци€ перед началом DMA транзакции
        mwr_done <= '0';
        i_mwr_len_rq_byte <= mwr_len_i;

        case max_payload_size_i is
        when C_PCIE_MAX_PAYLOAD_4096_BYTE => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(4096, i_mwr_tpl_max_byte'length);
        when C_PCIE_MAX_PAYLOAD_2048_BYTE => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(2048, i_mwr_tpl_max_byte'length);
        when C_PCIE_MAX_PAYLOAD_1024_BYTE => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(1024, i_mwr_tpl_max_byte'length);
        when C_PCIE_MAX_PAYLOAD_512_BYTE  => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(512, i_mwr_tpl_max_byte'length);
        when C_PCIE_MAX_PAYLOAD_256_BYTE  => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(256, i_mwr_tpl_max_byte'length);
        when others => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(128, i_mwr_tpl_max_byte'length);
        end case;

        mrd_done <= '0';
        i_mrd_len_rq_byte <= mrd_len_i;

        case max_rd_req_size_i is
        when C_PCIE_MAX_RD_REQ_4096_BYTE => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(4096, i_mrd_tpl_max_byte'length);
        when C_PCIE_MAX_RD_REQ_2048_BYTE => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(2048, i_mrd_tpl_max_byte'length);
        when C_PCIE_MAX_RD_REQ_1024_BYTE => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(1024, i_mrd_tpl_max_byte'length);
        when C_PCIE_MAX_RD_REQ_512_BYTE  => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(512, i_mrd_tpl_max_byte'length);
        when C_PCIE_MAX_RD_REQ_256_BYTE  => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(256, i_mrd_tpl_max_byte'length);
        when others => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(128, i_mrd_tpl_max_byte'length);
        end case;

    elsif ((fsm_state = S_TX_MWR_QW1) or (fsm_state = S_TX_MWR_QWN)) and
          usr_rxbuf_rd='1' and mwr_work='1' and
          (i_mwr_tx = i_mwr_len_rq - 1) then
          mwr_done <= '1'; --“ранзакци€ завершена

    elsif fsm_state = S_TX_MRD_QW1 and
          trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' and
          (i_mrd_tx = i_mrd_len_rq) then
          mrd_done <= '1'; --“ранзакци€ завершена
    end if;
  end if;
end process;

i_mwr_len_rq <= (CONV_STD_LOGIC_VECTOR(0, log2(G_USR_DBUS/8)) &
                 i_mwr_len_rq_byte(i_mwr_len_rq_byte'high downto log2(G_USR_DBUS/8)))
                + OR_reduce(i_mwr_len_rq_byte(log2(G_USR_DBUS/8) - 1 downto 0));

i_mwr_tpl_max <= (CONV_STD_LOGIC_VECTOR(0, log2(G_USR_DBUS/8)) &
                 i_mwr_tpl_max_byte(i_mwr_tpl_max_byte'high downto log2(G_USR_DBUS/8)))
                + OR_reduce(i_mwr_tpl_max_byte(log2(G_USR_DBUS/8) - 1 downto 0));

i_mwr_tpl_dw_tmp <= (CONV_STD_LOGIC_VECTOR(0, log2(32/8)) &
                 i_mwr_tpl_byte(i_mwr_tpl_byte'high downto log2(32/8)))
                + OR_reduce(i_mwr_tpl_byte(log2(32/8) - 1 downto 0));

i_mwr_tpl_dw <= i_mwr_tpl_dw_tmp;

i_mwr_remain_byte <= i_mwr_remain(i_mwr_remain'high - log2(G_USR_DBUS/8) downto 0)
                     & CONV_STD_LOGIC_VECTOR(0, log2(G_USR_DBUS/8));


i_mrd_len_rq <= (CONV_STD_LOGIC_VECTOR(0, log2(32/8)) &
                 i_mrd_len_rq_byte(i_mrd_len_rq_byte'high downto log2(32/8)))
                + OR_reduce(i_mrd_len_rq_byte(log2(32/8) - 1 downto 0));

i_mrd_tpl_max <= (CONV_STD_LOGIC_VECTOR(0, log2(32/8)) &
                 i_mrd_tpl_max_byte(i_mrd_tpl_max_byte'high downto log2(32/8)))
                + OR_reduce(i_mrd_tpl_max_byte(log2(32/8) - 1 downto 0));

i_mrd_tpl_dw_tmp <= (CONV_STD_LOGIC_VECTOR(0, log2(32/8)) &
                 i_mrd_tpl_byte(i_mrd_tpl_byte'high downto log2(32/8)))
                + OR_reduce(i_mrd_tpl_byte(log2(32/8) - 1 downto 0));

i_mrd_tpl_dw <= i_mrd_tpl_dw_tmp;

i_mrd_remain_byte <= i_mrd_remain(i_mrd_remain'high - log2(32/8) downto 0)
                     & CONV_STD_LOGIC_VECTOR(0, log2(32/8));

--Tx State Machine
process(rst_n, clk)
begin
  if rst_n = '0' then

    fsm_state <= S_TX_IDLE;

    i_trn_tsof_n <= '1';
    i_trn_teof_n <= '1';
    i_trn_tsrc_rdy_n <= '1';
    i_trn_td <= (others=>'0');
    i_trn_trem_n <= (others=>'0');

    i_mwr_adr_cnt <= (others=>'0');
    i_mwr_tpl_tag <= (others=>'0');
    i_mwr_tx <= (others=>'0');
    i_mwr_remain <= (others=>'0');

    i_mrd_adr_cnt <= (others=>'0');
    i_mrd_tpl_tag <= (others=>'0');
    i_mrd_tx <= (others=>'0');
    i_mrd_remain <= (others=>'0');

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

--                i_trn_tsof_n <= '0';
--                i_trn_teof_n <= '0';
--                i_trn_tsrc_rdy_n <= '0';
--                if (req_pkt_type_i = C_PCIE_PKT_TYPE_IORD_3DW_ND) or (req_pkt_type_i = C_PCIE_PKT_TYPE_MRD_3DW_ND) then
--                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#00#, i_trn_trem_n'length);
--                else
--                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);
--                end if;
--
--                i_trn_td(127) <= '0';
--
--                if (req_pkt_type_i = C_PCIE_PKT_TYPE_IORD_3DW_ND) or (req_pkt_type_i = C_PCIE_PKT_TYPE_MRD_3DW_ND) then
--                  i_trn_td(126 downto 120) <= C_PCIE_PKT_TYPE_CPLD_3DW_WD;
--                else
--                  i_trn_td(126 downto 120) <= C_PCIE_PKT_TYPE_CPL_3DW_ND;
--                end if;
--
--                i_trn_td(119 downto 32) <= ('0' &
--                           req_tc_i &
--                           "0000" &
--                           req_td_i &
--                           req_ep_i &
--                           req_attr_i &
--                           "00" &
--                           req_len_i &
--                           completer_id_i &
--                           "000" &
--                           '0' &
--                           byte_count &
--                           req_rid_i &
--                           req_tag_i &
--                           '0' &
--                           lower_addr);
--
--                if req_exprom_i='1' then
--                  i_trn_td(31 downto 0) <= (others=>'0');
--                else
--                  i_trn_td(31 downto 0) <= usr_reg_dout_i( 7 downto  0) &
--                                           usr_reg_dout_i(15 downto  8) &
--                                           usr_reg_dout_i(23 downto 16) &
--                                           usr_reg_dout_i(31 downto 24);
--                end if;
--
--                i_compl_done <= '1';
--                fsm_state <= S_TX_CPLD_WT1;
                i_trn_tsof_n <= '0';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= (others=>'0');

                i_trn_td(63) <= '0';

                if (req_pkt_type_i = C_PCIE_PKT_TYPE_IORD_3DW_ND) or (req_pkt_type_i = C_PCIE_PKT_TYPE_MRD_3DW_ND) then
                i_trn_td(62 downto 56) <= C_PCIE_PKT_TYPE_CPLD_3DW_WD;
                else
                i_trn_td(62 downto 56) <= C_PCIE_PKT_TYPE_CPL_3DW_ND;
                end if;
                i_trn_td(55 downto 0) <= ('0' &
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
                         byte_count);

                fsm_state <= S_TX_CPLD_WT0;

            -------------------------------------------------------
            --MWr - 3DW, +data (PC<-FPGA) FPGA is PCIe master
            -------------------------------------------------------
            elsif usr_rxbuf_rd='1' and trn_tbuf_av(C_PCIE_BUF_POSTED_QUEUE)='1' and
                sr_req_compl='0' and i_compl_done='0' and
                mwr_en_i='1' and mwr_done='0' and master_en_i='1' then

                if i_dma_init='1' then
                  i_mwr_adr_cnt <= mwr_addr_i;
                  i_mwr_tpl_tag <= (others=>'0');
                  i_mwr_tx <= (others=>'0');
                  i_mwr_remain <= EXT(i_mwr_len_rq, i_mwr_remain'length);
                else
                  i_mwr_remain <= EXT(i_mwr_len_rq, i_mwr_remain'length) - EXT(i_mwr_tx, i_mwr_remain'length);
                end if;
                i_dma_init_clr<='1';

--                i_trn_tsof_n <= '1';
--                i_trn_teof_n <= '1';
--                i_trn_tsrc_rdy_n <= '1';
--                i_trn_trem_n <= (others=>'0');
--                mwr_work <= '1';
--                fsm_state <= S_TX_MWR_QW1;
                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '1';
                i_trn_trem_n <= (others=>'0');
                fsm_state <= S_TX_MWR_QW00;

            -------------------------------------------------------
            --MRd - 3DW, no data (PC<-FPGA) FPGA is PCIe master
            -------------------------------------------------------
            elsif trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' and trn_tbuf_av(C_PCIE_BUF_NON_POSTED_QUEUE)='1' and
                sr_req_compl='0' and i_compl_done='0' and
                mrd_en_i='1' and mrd_done='0' and master_en_i='1' then

                if i_dma_init='1' then
                  i_mrd_adr_cnt <= mrd_addr_i;
                  i_mrd_tpl_tag <= (others=>'0');
                  i_mrd_tx <= (others=>'0');
                  i_mrd_remain <= EXT(i_mrd_len_rq, i_mrd_remain'length);
                else
                  i_mwr_remain <= EXT(i_mrd_len_rq, i_mrd_remain'length) - EXT(i_mrd_tx, i_mrd_remain'length);
                end if;
                i_dma_init_clr<='1';

--                i_trn_tsof_n <= '1';
--                i_trn_teof_n <= '1';
--                i_trn_tsrc_rdy_n <= '1';
--                i_trn_trem_n <= (others=>'0');
--                fsm_state <= S_TX_MRD_QW1;
                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '1';
                i_trn_trem_n <= (others=>'0');
                fsm_state <= S_TX_MRD_QW00;

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
        when S_TX_CPLD_WT0 =>

            if trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' then

                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '0';
                i_trn_tsrc_rdy_n <= '0';
                if (req_pkt_type_i = C_PCIE_PKT_TYPE_IORD_3DW_ND) or (req_pkt_type_i = C_PCIE_PKT_TYPE_MRD_3DW_ND) then
                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#00#, i_trn_trem_n'length);
                else
                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);
                end if;

                i_trn_td(63 downto 32) <= (req_rid_i &
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
            else
              if trn_tdst_dsc_n='0' then --ядро прерывало передачу данных
                fsm_state <= S_TX_CPLD_WT1;
              end if;
            end if;
        --end S_TX_CPLD_WT0 :

        when S_TX_CPLD_WT1 =>

            if trn_tdst_rdy_n='0' or trn_tdst_dsc_n='0' then
                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '1';
                fsm_state <= S_TX_IDLE;
            end if;
        --END: CplD - 3DW, +data;  Cpl - 3DW


        when S_TX_MWR_QW00 =>

          i_dma_init_clr<='0';
          if i_mwr_remain <= EXT(i_mwr_tpl_max, i_mwr_remain'length) then
              i_mwr_tpl_cnt <= i_mwr_remain(i_mwr_tpl_cnt'range) - 1;
              i_mwr_tpl_byte <= i_mwr_remain_byte(i_mwr_tpl_byte'range);
          else
              i_mwr_tpl_cnt <= i_mwr_tpl_max - 1;
              i_mwr_tpl_byte <= i_mwr_tpl_max_byte;
          end if;

          fsm_state <= S_TX_MWR_QW0;
        --end S_TX_MWR_QW00 :

--        --#######################################################################
--        --MWr - 3DW, +data (PC<-FPGA) FPGA is PCIe master
--        --#######################################################################
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
--                           i_mwr_tpl_dw(9 downto 0) &
--                           completer_id_i(15 downto 3) & mwr_phant_func_en1_i & "00");
--
--                if tag_ext_en_i='1' then
--                i_trn_td(15 downto 8) <= i_mwr_tpl_tag(7 downto 0);
--                else
--                i_trn_td(15 downto 8) <= EXT(i_mwr_tpl_tag(4 downto 0), 8);
--                end if;
--
--                if i_mwr_tpl_cnt = (i_mwr_tpl_cnt'range => '0') then
--                i_trn_td(7 downto 4) <= CONV_STD_LOGIC_VECTOR(16#0#, 4);--Last DW Byte Enable
--                i_trn_td(3 downto 0) <= CONV_STD_LOGIC_VECTOR(16#F#, 4);--1st DW Byte Enable
--                else
--                i_trn_td(7 downto 4) <= CONV_STD_LOGIC_VECTOR(16#F#, 4);--Last DW Byte Enable
--                i_trn_td(3 downto 0) <= CONV_STD_LOGIC_VECTOR(16#F#, 4);--1st DW Byte Enable
--                end if;
--
--                mwr_work <= '1';
--
--                fsm_state <= S_TX_MWR_QW1;
--            else
--              if trn_tdst_dsc_n='0' then --ядро прерывало передачу данных
--                  mwr_work <= '0';
--                  fsm_state <= S_TX_IDLE;
--              end if;
--            end if;
--        --end S_TX_MWR_QW0 :
--
--        when S_TX_MWR_QW1 =>
--
--            i_dma_init_clr<='0';
--            if usr_rxbuf_rd='1' and mwr_work='1' then
--
----                i_trn_tsof_n <= '0';
----                --i_trn_teof_n <= '1';
----                --i_trn_tsrc_rdy_n <= '0';
----                i_trn_trem_n <= (others=>'0');
----
----                i_trn_td(127 downto 80) <= ('0' &
----                           C_PCIE_PKT_TYPE_MWR_3DW_WD &
----                           '0' &
----                           mwr_tlp_tc_i &
----                           "0000" &
----                           '0' &
----                           '0' &
----                           mwr_relaxed_order_i & mwr_nosnoop_i &
----                           "00" &
----                           mwr_len_dw(9 downto 0) &
----                           completer_id_i(15 downto 3) & mwr_phant_func_en1_i & "00");
----
----                if tag_ext_en_i='1' then
----                i_trn_td(79 downto 72) <= i_mwr_tpl_tag(7 downto 0);
----                else
----                i_trn_td(79 downto 72) <= EXT(i_mwr_tpl_tag(4 downto 0), 8);
----                end if;
----
----                i_trn_td(71 downto 0) <= (mwr_lbe & mwr_fbe &
----                           i_mwr_adr_cnt(31 downto 2) & "00" &
----                           usr_rxbuf_dout_swap);
--                i_trn_tsof_n <= '1';
--                --i_trn_teof_n <= '1';
--                i_trn_tsrc_rdy_n <= '0';
--                i_trn_trem_n <= (others=>'0');
--
--                i_trn_td(63 downto 32) <= (i_mwr_adr_cnt(31 downto 2) & "00");
--                i_trn_td(31 downto 0)  <= usr_rxbuf_dout_swap;
--
--                --индетификатор пакета
--                i_mwr_tpl_tag <= i_mwr_tpl_tag + 1;
--
--                --—четчик адреса (byte)
--                i_mwr_adr_cnt <= i_mwr_adr_cnt + EXT(i_mwr_tpl_byte, i_mwr_adr_cnt'length);
--
--                --—четчик отправленых данных (Total)
--                i_mwr_tx <= i_mwr_tx + 1;
--
--                --—четчик отправленых данных (текущей транзакции)
--                if i_mwr_tpl_cnt = (i_mwr_tpl_cnt'range => '0') then
--
--                    i_trn_teof_n <= '0';
--                    trn_dw_sel <= (others=>'0');
--
--                    mwr_work <= '0';
--
--                    fsm_state <= S_TX_IDLE;
--                else
--                    i_trn_teof_n <= '1';
--                    trn_dw_sel <= (others=>'0');
--
--                    i_mwr_tpl_cnt <= i_mwr_tpl_cnt - 1;
--
--                    fsm_state <= S_TX_MWR_QWN;
--                end if;
--
--            else
--              if trn_tdst_dsc_n='0' then --ядро прерывало передачу данных
------                  i_trn_teof_n <= '0';
----                  trn_dw_sel <= (others=>'0');
----                  mwr_work <= '0';
----                  fsm_state <= S_TX_IDLE;
--                  i_trn_teof_n <= '0';
--                  trn_dw_sel <= (others=>'0');
--                  mwr_work <= '0';
--                  fsm_state <= S_TX_IDLE;
--              end if;
--            end if;
--        --end S_TX_MWR_QW1 :
--
--        when S_TX_MWR_QWN =>
--
--            if usr_rxbuf_rd='1' and mwr_work='1' then
----                if    trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#01#, trn_dw_sel'length) then
----                  i_trn_td(31 downto 0) <= usr_rxbuf_dout_swap;
----                elsif trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#02#, trn_dw_sel'length) then
----                  i_trn_td(63 downto 32) <= usr_rxbuf_dout_swap;
----                elsif trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#03#, trn_dw_sel'length) then
----                  i_trn_td(31+64 downto 0+64) <= usr_rxbuf_dout_swap;
----                elsif trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#00#, trn_dw_sel'length) then
----                  i_trn_td(63+64 downto 32+64) <= usr_rxbuf_dout_swap;
----                end if;
--
--                if trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#01#, trn_dw_sel'length) then
--                  i_trn_td(31 downto  0) <= usr_rxbuf_dout_swap;
--                else
--                  i_trn_td(63 downto 32) <= usr_rxbuf_dout_swap;
--                end if;
--
--                i_trn_tsof_n <= '1';
--                i_trn_tsrc_rdy_n <= '0';
--
--                i_trn_trem_n <= trn_dw_sel - 1;
--
--                --—четчик отправленых данных (Total)
--                i_mwr_tx <= i_mwr_tx + 1;
--
--                --—четчик отправленых данных (текущей транзакции)
--                if i_mwr_tpl_cnt = (i_mwr_tpl_cnt'range => '0') then
--
--                    i_trn_teof_n <= '0';
--
--                    trn_dw_sel <= (others=>'0');
--                    mwr_work <= '0';
--
--                    fsm_state <= S_TX_IDLE;
--
--                else
--                    i_trn_teof_n <= '1';
--
--                    trn_dw_sel <= trn_dw_sel - 1;
--                    i_mwr_tpl_cnt <= i_mwr_tpl_cnt - 1;
--
--                    fsm_state <= S_TX_MWR_QWN;
--                end if;
--
--            else
--              if trn_tdst_dsc_n='0' then --ядро прерывало передачу данных
--                  i_trn_tsof_n <= '1';
--                  i_trn_teof_n <= '0';
--                  trn_dw_sel <= (others=>'0');
--                  mwr_work <= '0';
--
--                  fsm_state <= S_TX_IDLE;
--              end if;
--            end if;
--        --end S_TX_MWR_QWN :
--        --END: MWr - 3DW, +data


        --#######################################################################
        --MWr - 4DW, +data (PC<-FPGA) FPGA is PCIe master
        --#######################################################################
        when S_TX_MWR_QW0 =>

            i_dma_init_clr<='0';
            if usr_rxbuf_rd='1' then

                i_trn_tsof_n <= '0';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= (others=>'0');

                i_trn_td(63 downto 16) <= ('0' &
                           C_PCIE_PKT_TYPE_MWR_4DW_WD &
                           '0' &
                           mwr_tlp_tc_i &
                           "0000" &
                           '0' &
                           '0' &
                           mwr_relaxed_order_i & mwr_nosnoop_i &
                           "00" &
                           i_mwr_tpl_dw(9 downto 0) &
                           completer_id_i(15 downto 3) & mwr_phant_func_en1_i & "00");

                if tag_ext_en_i='1' then
                i_trn_td(15 downto 8) <= i_mwr_tpl_tag(7 downto 0);
                else
                i_trn_td(15 downto 8) <= EXT(i_mwr_tpl_tag(4 downto 0), 8);
                end if;

                if i_mwr_tpl_cnt = (i_mwr_tpl_cnt'range => '0') then
                i_trn_td(7 downto 4) <= CONV_STD_LOGIC_VECTOR(16#0#, 4);--Last DW Byte Enable
                i_trn_td(3 downto 0) <= CONV_STD_LOGIC_VECTOR(16#F#, 4);--1st DW Byte Enable
                else
                i_trn_td(7 downto 4) <= CONV_STD_LOGIC_VECTOR(16#F#, 4);--Last DW Byte Enable
                i_trn_td(3 downto 0) <= CONV_STD_LOGIC_VECTOR(16#F#, 4);--1st DW Byte Enable
                end if;

                fsm_state <= S_TX_MWR_QW1;
            else
              if trn_tdst_dsc_n='0' then --ядро прерывало передачу данных
                  mwr_work <= '0';
                  fsm_state <= S_TX_IDLE;
              end if;
            end if;
        --end S_TX_MWR_QW0 :

        when S_TX_MWR_QW1 =>

            i_dma_init_clr<='0';
            if usr_rxbuf_rd='1' then

--                i_trn_tsof_n <= '0';
--                --i_trn_teof_n <= '1';
--                --i_trn_tsrc_rdy_n <= '0';
--                i_trn_trem_n <= (others=>'0');
--
--                i_trn_td(127 downto 80) <= ('0' &
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
--                i_trn_td(79 downto 72) <= i_mwr_tpl_tag(7 downto 0);
--                else
--                i_trn_td(79 downto 72) <= EXT(i_mwr_tpl_tag(4 downto 0), 8);
--                end if;
--
--                i_trn_td(71 downto 0) <= (mwr_lbe & mwr_fbe &
--                           i_mwr_adr_cnt(31 downto 2) & "00" &
--                           usr_rxbuf_dout_swap);
                i_trn_tsof_n <= '1';
                --i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= (others=>'0');

                i_trn_td(63 downto 32) <= (others=>'0');
                i_trn_td(31 downto 0)  <= (i_mwr_adr_cnt(31 downto 2) & "00");

                --индетификатор пакета
                i_mwr_tpl_tag <= i_mwr_tpl_tag + 1;

                --—четчик адреса (byte)
                i_mwr_adr_cnt <= i_mwr_adr_cnt + EXT(i_mwr_tpl_byte, i_mwr_adr_cnt'length);

                mwr_work <= '1';

                fsm_state <= S_TX_MWR_QWN;

            else
              if trn_tdst_dsc_n='0' then --ядро прерывало передачу данных
----                  i_trn_teof_n <= '0';
--                  trn_dw_sel <= (others=>'0');
--                  mwr_work <= '0';
--                  fsm_state <= S_TX_IDLE;
                  i_trn_teof_n <= '0';
                  trn_dw_sel <= (others=>'0');
                  mwr_work <= '0';
                  fsm_state <= S_TX_IDLE;
              end if;
            end if;
        --end S_TX_MWR_QW1 :

        when S_TX_MWR_QWN =>

            if usr_rxbuf_rd='1' and mwr_work='1' then
--                if    trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#01#, trn_dw_sel'length) then
--                  i_trn_td(31 downto 0) <= usr_rxbuf_dout_swap;
--                elsif trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#02#, trn_dw_sel'length) then
--                  i_trn_td(63 downto 32) <= usr_rxbuf_dout_swap;
--                elsif trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#03#, trn_dw_sel'length) then
--                  i_trn_td(31+64 downto 0+64) <= usr_rxbuf_dout_swap;
--                elsif trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#00#, trn_dw_sel'length) then
--                  i_trn_td(63+64 downto 32+64) <= usr_rxbuf_dout_swap;
--                end if;

                i_trn_td(63 downto 0) <= usr_rxbuf_dout_swap;

                i_trn_tsof_n <= '1';
                i_trn_tsrc_rdy_n <= '0';

                i_trn_trem_n <= (others=>'0');

                --—четчик отправленых данных (Total)
                i_mwr_tx <= i_mwr_tx + 1;

                --—четчик отправленых данных (текущей транзакции)
                if i_mwr_tpl_cnt = (i_mwr_tpl_cnt'range => '0') then

                    i_trn_teof_n <= '0';

                    trn_dw_sel <= (others=>'0');
                    mwr_work <= '0';

                    fsm_state <= S_TX_IDLE;

                else
                    i_trn_teof_n <= '1';

                    trn_dw_sel <= (others=>'0');
                    i_mwr_tpl_cnt <= i_mwr_tpl_cnt - 1;

                    fsm_state <= S_TX_MWR_QWN;
                end if;

            else
              if trn_tdst_dsc_n='0' then --ядро прерывало передачу данных
                  i_trn_tsof_n <= '1';
                  i_trn_teof_n <= '0';
                  trn_dw_sel <= (others=>'0');
                  mwr_work <= '0';

                  fsm_state <= S_TX_IDLE;
              end if;
            end if;
        --end S_TX_MWR_QWN :
        --END: MWr - 4DW, +data

        --#######################################################################
        --MRd - 3DW, no data  (PC<-FPGA) (запрос записи в пам€ть PC)
        --#######################################################################
        when S_TX_MRD_QW00 =>
          i_dma_init_clr<='0';
          if i_mrd_remain <= EXT(i_mrd_tpl_max, i_mrd_remain'length) then
              i_mrd_tpl_cnt <= i_mrd_remain(i_mrd_tpl_cnt'range);
              i_mrd_tpl_byte <= i_mrd_remain_byte(i_mrd_tpl_byte'range);
          else
              i_mrd_tpl_cnt <= i_mrd_tpl_max;
              i_mrd_tpl_byte <= i_mrd_tpl_max_byte;
          end if;

          fsm_state <= S_TX_MRD_QW0;
        --end S_TX_MWR_QW00 :

        when S_TX_MRD_QW0 =>

            i_dma_init_clr<='0';
            if trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' then

                i_trn_tsof_n <= '0';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= (others=>'0');

                i_trn_td(63 downto 16) <= ('0' &
                           C_PCIE_PKT_TYPE_MRD_3DW_ND &
                           '0' &
                           mrd_tlp_tc_i &
                           "0000" &
                           '0' &
                           '0' &
                           mrd_relaxed_order_i & mrd_nosnoop_i &
                           "00" &
                           i_mrd_tpl_dw(9 downto 0) &
                           completer_id_i(15 downto 3) & mrd_phant_func_en1_i & "00");

                if tag_ext_en_i='1' then
                i_trn_td(15 downto 8) <= i_mrd_tpl_tag(7 downto 0);
                else
                i_trn_td(15 downto 8) <= EXT(i_mrd_tpl_tag(4 downto 0), 8);
                end if;

                if i_mrd_tpl_cnt = CONV_STD_LOGIC_VECTOR(1, i_mrd_tpl_cnt'length) then
                i_trn_td(7 downto 4) <= CONV_STD_LOGIC_VECTOR(16#0#, 4);--Last DW Byte Enable
                i_trn_td(3 downto 0) <= CONV_STD_LOGIC_VECTOR(16#F#, 4);--1st DW Byte Enable
                else
                i_trn_td(7 downto 4) <= CONV_STD_LOGIC_VECTOR(16#F#, 4);--Last DW Byte Enable
                i_trn_td(3 downto 0) <= CONV_STD_LOGIC_VECTOR(16#F#, 4);--1st DW Byte Enable
                end if;

                --—четчик запрошенных данных (Total)
                i_mrd_tx <= i_mrd_tx + EXT(i_mrd_tpl_cnt, i_mrd_tx'length);

                fsm_state <= S_TX_MRD_QW1;
            else
              if trn_tdst_dsc_n='0' then --ядро прерывало передачу данных
                fsm_state <= S_TX_IDLE;
              end if;
            end if;
        --end S_TX_MRD_QW0 :

        when S_TX_MRD_QW1 =>

            i_dma_init_clr<='0';
            if trn_tdst_rdy_n='0' and trn_tdst_dsc_n='1' then

--                i_trn_tsof_n <= '0';
--                i_trn_teof_n <= '0';
--                i_trn_tsrc_rdy_n <= '0';
--                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);
--
--                i_trn_td(127 downto 80) <= ('0' &
--                           C_PCIE_PKT_TYPE_MRD_3DW_ND &
--                           '0' &
--                           mrd_tlp_tc_i &
--                           "0000" &
--                           '0' &
--                           '0' &
--                           mrd_relaxed_order_i & mrd_nosnoop_i &
--                           "00" &
--                           i_mrd_tpl_dw(9 downto 0) &
--                           completer_id_i(15 downto 3) & mrd_phant_func_en1_i & "00");
--
--                if tag_ext_en_i='1' then
--                i_trn_td(79 downto 72) <= mrd_pkt_count(7 downto 0);
--                else
--                i_trn_td(79 downto 72) <= EXT(mrd_pkt_count(4 downto 0), 8);
--                end if;
--
--                i_trn_td(71 downto 0) <= (mrd_lbe & mrd_fbe &
--                           pmrd_addr(31 downto 2) & "00" &
--                           CONV_STD_LOGIC_VECTOR(16#00#, 32));

                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '0';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);

                i_trn_td(63 downto 32) <= (i_mrd_adr_cnt(31 downto 2) & "00");
                i_trn_td(31 downto 0) <= (others=>'0');

                --индетификатор пакета
                if i_mrd_tx = i_mrd_len_rq then
                i_mrd_tpl_tag <= (others=>'0');
                else
                i_mrd_tpl_tag <= i_mrd_tpl_tag + 1;
                end if;

                --—четчик адреса (byte)
                i_mrd_adr_cnt <= i_mrd_adr_cnt + EXT(i_mrd_tpl_byte, i_mrd_adr_cnt'length);

                fsm_state <= S_TX_IDLE;
            else
              if trn_tdst_dsc_n='0' then --ядро прерывало передачу данных
----                i_trn_teof_n <= '0';
--                fsm_state <= S_TX_IDLE;
                i_trn_teof_n <= '0';
                fsm_state <= S_TX_IDLE;
              end if;
            end if;
        --end S_TX_MRD_QW1 :
        --END: MRd - 3DW, no data

    end case; --case fsm_state is
  end if;
end process;


--END MAIN
end behavioral;

