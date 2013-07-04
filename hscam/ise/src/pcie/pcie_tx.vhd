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
mrd_pkt_count_o        : out  std_logic_vector(15 downto 0);

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
S_TX_MWR_QWN2,
S_TX_MRD_QW1 ,
S_TX_CPLD_WT0,
S_TX_MRD_QW0 ,
S_TX_MWR_QW0 ,
S_TX_MWR_QW00,
S_TX_MRD_QW00
);
signal i_fsm_cs             : TFsm_state;

signal i_trn_trem_n         : std_logic_vector(trn_td'length/64-1 downto 0);
signal i_trn_td             : std_logic_vector(trn_td'range);
signal i_trn_tsof_n         : std_logic;
signal i_trn_teof_n         : std_logic;
signal i_trn_tsrc_rdy_n     : std_logic;

signal i_byte_count         : std_logic_vector(11 downto 0);
signal i_lower_addr         : std_logic_vector(6 downto 0);

signal sr_req_compl         : std_logic;
signal i_compl_done         : std_logic;

signal i_dma_init           : std_logic;

signal i_mem_adr_byte       : std_logic_vector(31 downto 0);
signal i_mem_tx_byte        : std_logic_vector(31 downto 0);
signal i_mem_remain_byte    : std_logic_vector(31 downto 0);
signal i_mem_tpl_cnt        : std_logic_vector(12 downto 0);
signal i_mem_tpl_byte       : std_logic_vector(12 downto 0);
signal i_mem_tpl_dw         : std_logic_vector(12 downto 0);
signal i_mem_tpl_len        : std_logic_vector(12 downto 0);
signal i_mem_tpl_tag        : std_logic_vector(15 downto 0);
signal i_mem_tpl_last       : std_logic;

signal i_mwr_done           : std_logic;
signal i_mwr_tpl_max_byte   : std_logic_vector(12 downto 0);
signal i_mwr_work           : std_logic;

signal i_mrd_done           : std_logic;
signal i_mrd_tpl_max_byte   : std_logic_vector(12 downto 0);

signal i_usr_rxbuf_rd       : std_logic;
signal i_usr_rxbuf_do_swap  : std_logic_vector(usr_rxbuf_dout_i'range);
signal i_usr_reg_do_swap    : std_logic_vector(usr_reg_dout_i'range);
signal sr_usr_rxbuf_do_swap : std_logic_vector(32*1 - 1 downto 32*0);


--MAIN
begin


----------------------------------------
--Технологические
----------------------------------------
tst_o <= (others=>'0');


----------------------------------------
--
----------------------------------------
mrd_pkt_count_o <= i_mem_tpl_tag + 1;
mrd_pkt_len_o <= EXT(i_mem_tpl_dw, mrd_pkt_len_o'length);

i_usr_rxbuf_rd <= (not trn_tdst_rdy_n and not usr_rxbuf_empty_i);
usr_rxbuf_rd_o <= i_usr_rxbuf_rd and i_mwr_work;
usr_rxbuf_rd_last_o <= i_usr_rxbuf_rd when i_mwr_work = '1'
                                        and i_mem_tpl_last = '1'
                                          and (i_mem_tpl_cnt = (i_mem_tpl_len - 1)) else '0';

trn_tsrc_dsc_n <= '1';
trn_tsrc_rdy_n_o <= i_trn_tsrc_rdy_n;
trn_tsof_n <= i_trn_tsof_n;
trn_teof_n <= i_trn_teof_n;
trn_trem_n <= EXT(i_trn_trem_n, trn_trem_n'length);
trn_td <= i_trn_td;

mwr_done_o <= i_mwr_done;
compl_done_o <= i_compl_done;

gen_swap_rxbuf : for i in 0 to usr_rxbuf_dout_i'length/8 - 1 generate
i_usr_rxbuf_do_swap((i_usr_rxbuf_do_swap'length - 8*i) - 1 downto
                    (i_usr_rxbuf_do_swap'length - 8*(i+1))) <= usr_rxbuf_dout_i(8*(i+1) - 1 downto 8*i);
end generate gen_swap_rxbuf;

gen_swap_reg : for i in 0 to usr_reg_dout_i'length/8 - 1 generate
i_usr_reg_do_swap((i_usr_reg_do_swap'length - 8*i) - 1 downto
                  (i_usr_reg_do_swap'length - 8*(i+1))) <= usr_reg_dout_i(8*(i+1) - 1 downto 8*i);
end generate gen_swap_reg;

--Calculate byte count based on byte enable
process (req_be_i)
begin
  case req_be_i(3 downto 0) is
    when "1001" | "1011" | "1101" | "1111" =>
      i_byte_count <= X"004";
    when "0101" | "0111" =>
      i_byte_count <= X"003";
    when "1010" | "1110" =>
      i_byte_count <= X"003";
    when "0011" =>
      i_byte_count <= X"002";
    when "0110" =>
      i_byte_count <= X"002";
    when "1100" =>
      i_byte_count <= X"002";
    when "0001" =>
      i_byte_count <= X"001";
    when "0010" =>
      i_byte_count <= X"001";
    when "0100" =>
      i_byte_count <= X"001";
    when "1000" =>
      i_byte_count <= X"001";
    when "0000" =>
      i_byte_count <= X"001";
    when others =>
      i_byte_count <= X"000";
  end case;
end process;

--Calculate lower address based on  byte enable
process (req_be_i, req_addr_i)
begin
  case req_be_i(3 downto 0) is
    when "0000" =>
      i_lower_addr <= (req_addr_i(4 downto 0) & "00");
    when "0001" | "0011" | "0101" | "0111" | "1001" | "1011" | "1101" | "1111" =>
      i_lower_addr <= (req_addr_i(4 downto 0) & "00");
    when "0010" | "0110" | "1010" | "1110" =>
      i_lower_addr <= (req_addr_i(4 downto 0) & "01");
    when "0100" | "1100" =>
      i_lower_addr <= (req_addr_i(4 downto 0) & "10");
    when "1000" =>
      i_lower_addr <= (req_addr_i(4 downto 0) & "11");
    when others =>
      i_lower_addr <= (req_addr_i(4 downto 0) & "00");
  end case;
end process;

--Инициализация перед началом DMA транзакции
init : process(rst_n, clk)
begin
  if rst_n = '0' then
    sr_req_compl <= '0';
    i_dma_init <= '0';

  elsif rising_edge(clk) then

    sr_req_compl <= req_compl_i;

    if dma_init_i = '1' then
        i_dma_init <= '1';
    else
        if (i_fsm_cs = S_TX_MWR_QW00) or (i_fsm_cs = S_TX_MRD_QW00) then
          i_dma_init <= '0';
        end if;
    end if;
  end if;
end process;--init


--Tx State Machine
fsm : process(rst_n, clk)
begin
  if rst_n = '0' then

    i_fsm_cs <= S_TX_IDLE;

    i_trn_tsof_n <= '1';
    i_trn_teof_n <= '1';
    i_trn_tsrc_rdy_n <= '1';
    i_trn_td <= (others=>'0');
    i_trn_trem_n <= (others=>'0');

    i_mem_adr_byte <= (others=>'0');
    i_mem_remain_byte <= (others=>'0');
    i_mem_tx_byte <= (others=>'0');
    i_mem_tpl_byte <= (others=>'0');
    i_mem_tpl_dw <= CONV_STD_LOGIC_VECTOR(128, i_mem_tpl_dw'length);
    i_mem_tpl_len <= (others=>'0');
    i_mem_tpl_tag <= (others=>'0');
    i_mem_tpl_cnt <= (others=>'0');
    i_mem_tpl_last <= '0';

    i_mrd_done <= '0';
    i_mwr_done <= '0';
    i_mwr_work <= '0';
    i_mwr_tpl_max_byte <= (others=>'0');
    i_mrd_tpl_max_byte <= (others=>'0');

    i_compl_done <= '0';

    sr_usr_rxbuf_do_swap <= (others=>'0');

  elsif rising_edge(clk) then

    case i_fsm_cs is
        --#######################################################################
        --
        --#######################################################################
        when S_TX_IDLE =>

            i_mem_tpl_last <= '0';

            -------------------------------------------------------
            --CplD - 3DW, +data;  Cpl - 3DW
            -------------------------------------------------------
            if trn_tdst_rdy_n = '0'
              and trn_tbuf_av(C_PCIE_BUF_COMPLETION_QUEUE) = '1'
                and sr_req_compl = '1' and i_compl_done = '0' then

                i_trn_tsof_n <= '0';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= (others=>'0');

                i_trn_td(63) <= '0';

                if (req_pkt_type_i = C_PCIE_PKT_TYPE_IORD_3DW_ND)
                  or (req_pkt_type_i = C_PCIE_PKT_TYPE_MRD_3DW_ND) then

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
                         i_byte_count);

                i_fsm_cs <= S_TX_CPLD_WT0;

            -------------------------------------------------------
            --MWr - 3DW, +data (PC<-FPGA) FPGA is PCIe master
            -------------------------------------------------------
            elsif i_usr_rxbuf_rd = '1' and trn_tbuf_av(C_PCIE_BUF_POSTED_QUEUE) = '1'
              and sr_req_compl = '0' and i_compl_done = '0'
                and mwr_en_i = '1' and i_mwr_done = '0' and master_en_i = '1' then

                if i_dma_init = '1' then

                  case max_payload_size_i is
                  when C_PCIE_MAX_PAYLOAD_4096_BYTE => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(4096, i_mwr_tpl_max_byte'length);
                  when C_PCIE_MAX_PAYLOAD_2048_BYTE => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(2048, i_mwr_tpl_max_byte'length);
                  when C_PCIE_MAX_PAYLOAD_1024_BYTE => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(1024, i_mwr_tpl_max_byte'length);
                  when C_PCIE_MAX_PAYLOAD_512_BYTE  => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(512, i_mwr_tpl_max_byte'length);
                  when C_PCIE_MAX_PAYLOAD_256_BYTE  => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(256, i_mwr_tpl_max_byte'length);
                  when C_PCIE_MAX_PAYLOAD_128_BYTE  => i_mwr_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(128, i_mwr_tpl_max_byte'length);
                  when others => null;
                  end case;

                  i_mem_adr_byte <= mwr_addr_i;
                  i_mem_remain_byte <= mwr_len_i;

                else
                  i_mem_remain_byte <= mwr_len_i - i_mem_tx_byte;
                end if;

                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '1';
                i_trn_trem_n <= (others=>'0');

                i_fsm_cs <= S_TX_MWR_QW00;

            -------------------------------------------------------
            --MRd - 3DW, no data (PC<-FPGA) FPGA is PCIe master
            -------------------------------------------------------
            elsif trn_tdst_rdy_n = '0'
              and trn_tbuf_av(C_PCIE_BUF_NON_POSTED_QUEUE) = '1'
                and sr_req_compl = '0' and i_compl_done = '0'
                  and mrd_en_i = '1' and i_mrd_done = '0' and master_en_i = '1' then

                if i_dma_init = '1' then

                  case max_rd_req_size_i is
                  when C_PCIE_MAX_RD_REQ_4096_BYTE => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(4096, i_mrd_tpl_max_byte'length);
                  when C_PCIE_MAX_RD_REQ_2048_BYTE => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(2048, i_mrd_tpl_max_byte'length);
                  when C_PCIE_MAX_RD_REQ_1024_BYTE => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(1024, i_mrd_tpl_max_byte'length);
                  when C_PCIE_MAX_RD_REQ_512_BYTE  => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(512, i_mrd_tpl_max_byte'length);
                  when C_PCIE_MAX_RD_REQ_256_BYTE  => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(256, i_mrd_tpl_max_byte'length);
                  when C_PCIE_MAX_RD_REQ_128_BYTE  => i_mrd_tpl_max_byte <= CONV_STD_LOGIC_VECTOR(128, i_mrd_tpl_max_byte'length);
                  when others => null;
                  end case;

                  i_mem_adr_byte <= mwr_addr_i;
                  i_mem_remain_byte <= mwr_len_i;

                else
                  i_mem_remain_byte <= mwr_len_i - i_mem_tx_byte;
                end if;

                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '1';
                i_trn_trem_n <= (others=>'0');

                i_fsm_cs <= S_TX_MRD_QW00;

            else
                if trn_tdst_rdy_n = '0' then
                  i_trn_tsof_n <= '1';
                  i_trn_teof_n <= '1';
                  i_trn_tsrc_rdy_n <= '1';
                  i_trn_trem_n <= (others=>'0');
                end if;

                if i_dma_init = '1' then
                  i_mwr_done <= '0';
                  i_mrd_done <= '0';
                end if;

                i_compl_done <= '0';
            end if;
        --end S_TX_IDLE :


        --#######################################################################
        --CplD - 3DW, +data;  Cpl - 3DW (PC<-FPGA)
        --#######################################################################
        when S_TX_CPLD_WT0 =>

            if trn_tdst_rdy_n = '0' then

                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '0';
                i_trn_tsrc_rdy_n <= '0';

                if (req_pkt_type_i = C_PCIE_PKT_TYPE_IORD_3DW_ND)
                  or (req_pkt_type_i = C_PCIE_PKT_TYPE_MRD_3DW_ND) then

                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#00#, i_trn_trem_n'length);
                else
                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);
                end if;

                i_trn_td(63 downto 32) <= (req_rid_i &
                           req_tag_i &
                           '0' &
                           i_lower_addr);

                if req_exprom_i = '1' then
                i_trn_td(31 downto 0) <= (others=>'0');
                else
                i_trn_td(31 downto 0) <= i_usr_reg_do_swap;
                end if;

                i_compl_done <= '1';
                i_fsm_cs <= S_TX_CPLD_WT1;

            end if;
        --end S_TX_CPLD_WT0 :

        when S_TX_CPLD_WT1 =>

            if trn_tdst_rdy_n = '0' then
                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '1';
                i_fsm_cs <= S_TX_IDLE;
            end if;
        --END: CplD - 3DW, +data;  Cpl - 3DW


        --#######################################################################
        --MWr , +data (PC<-FPGA) FPGA is PCIe master
        --#######################################################################
        when S_TX_MWR_QW00 =>

          if i_mem_remain_byte > EXT(i_mwr_tpl_max_byte, i_mem_remain_byte'length) then
              i_mem_tpl_last <= '0';
              i_mem_tpl_byte <= i_mwr_tpl_max_byte;
              i_mem_tpl_dw <= (CONV_STD_LOGIC_VECTOR(0, log2(32/8)) &
                              i_mwr_tpl_max_byte(i_mem_tpl_dw'high downto log2(32/8)));

              i_mem_tpl_len <= (CONV_STD_LOGIC_VECTOR(0, log2(G_USR_DBUS/8)) &
                              i_mwr_tpl_max_byte(i_mem_tpl_len'high downto log2(G_USR_DBUS/8)));
          else
              i_mem_tpl_last <= '1';
              i_mem_tpl_byte <= i_mem_remain_byte(i_mem_tpl_byte'range);
              i_mem_tpl_dw <= (CONV_STD_LOGIC_VECTOR(0, log2(32/8)) &
                              i_mem_remain_byte(i_mem_tpl_dw'high downto log2(32/8)))
                              + OR_reduce(i_mem_remain_byte(log2(32/8) - 1 downto 0));

              i_mem_tpl_len <= (CONV_STD_LOGIC_VECTOR(0, log2(G_USR_DBUS/8)) &
                              i_mem_remain_byte(i_mem_tpl_len'high downto log2(G_USR_DBUS/8)))
                              + OR_reduce(i_mem_remain_byte(log2(G_USR_DBUS/8) - 1 downto 0));
          end if;

          i_fsm_cs <= S_TX_MWR_QW0;
        --end S_TX_MWR_QW00 :

        when S_TX_MWR_QW0 =>

            if i_usr_rxbuf_rd = '1' then

                i_trn_tsof_n <= '0';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= (others=>'0');
                i_trn_teof_n <= '1';

                i_trn_td(63) <= '0';
                i_trn_td(62 downto 56) <= C_PCIE_PKT_TYPE_MWR_3DW_WD;  i_mwr_work <= '1';
                i_trn_td(55 downto 16) <= ('0' &
                           mwr_tlp_tc_i &
                           "0000" &
                           '0' &
                           '0' &
                           mwr_relaxed_order_i & mwr_nosnoop_i &
                           "00" &
                           i_mem_tpl_dw(9 downto 0) &
                           completer_id_i(15 downto 3) & mwr_phant_func_en1_i & "00");

                if tag_ext_en_i = '1' then
                i_trn_td(15 downto 8) <= i_mem_tpl_tag(7 downto 0);
                else
                i_trn_td(15 downto 8) <= EXT(i_mem_tpl_tag(4 downto 0), 8);
                end if;

                --Last DW Byte Enable
                case i_mem_tpl_byte(1 downto 0) is
                when "00" => i_trn_td(7 downto 4) <= "1111";
                when "01" => i_trn_td(7 downto 4) <= "0001";
                when "10" => i_trn_td(7 downto 4) <= "0011";
                when "11" => i_trn_td(7 downto 4) <= "0111";
                when others => null;
                end case;

                --1st DW Byte Enable
                case i_mem_adr_byte(1 downto 0) is
                when "00" => i_trn_td(3 downto 0) <= "1111";
                when "01" => i_trn_td(3 downto 0) <= "1110";
                when "10" => i_trn_td(3 downto 0) <= "1100";
                when "11" => i_trn_td(3 downto 0) <= "1000";
                when others => null;
                end case;

                i_mem_tpl_tag <= i_mem_tpl_tag + 1;

                i_fsm_cs <= S_TX_MWR_QW1;

            end if;
        --end S_TX_MWR_QW0 :

        when S_TX_MWR_QW1 =>

            if i_usr_rxbuf_rd = '1' then

                i_trn_tsof_n <= '1';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= (others=>'0');

                i_mem_adr_byte <= i_mem_adr_byte + EXT(i_mem_tpl_byte, i_mem_adr_byte'length);

                i_trn_td(32*2 - 1 downto 32*1) <= (i_mem_adr_byte(31 downto 2) & "00");
                i_trn_td(32*1 - 1 downto 32*0) <= i_usr_rxbuf_do_swap(32*2 - 1 downto 32*1);

                sr_usr_rxbuf_do_swap(32*1 - 1 downto 32*0) <= i_usr_rxbuf_do_swap(32*1 - 1 downto 32*0);

                --Счетчик отправленых данных (текущей транзакции)
                if i_mem_tpl_cnt = (i_mem_tpl_len - 1) then

                    if G_USR_DBUS = 64 then
                        i_mwr_work <= '0';

                        if i_mem_tpl_dw = CONV_STD_LOGIC_VECTOR(16#02#, i_mem_tpl_dw'length) then
                          i_fsm_cs <= S_TX_MWR_QWN2;

                        else --if i_mem_tpl_dw = CONV_STD_LOGIC_VECTOR(16#01#, i_mem_tpl_dw'length) then
                          i_mem_tpl_cnt <= (others=>'0');

                          if i_mem_tpl_last = '1' then
                            i_mem_tx_byte <= (others=>'0');
                            i_mem_tpl_tag <= (others=>'0');
                            i_mwr_done <= '1';
                          end if;

                          i_trn_teof_n <= '0';

                          i_fsm_cs <= S_TX_IDLE;
                        end if;

                    else --if G_USR_DBUS = 32 then

                        i_mem_tpl_cnt <= (others=>'0');
                        i_mwr_work <= '0';

                        if i_mem_tpl_last = '1' then
                          i_mem_tx_byte <= (others=>'0');
                          i_mem_tpl_tag <= (others=>'0');
                          i_mwr_done <= '1';
                        end if;

                        i_trn_teof_n <= '0';

                        i_fsm_cs <= S_TX_IDLE;

                    end if;

                else --if i_mem_tpl_cnt /= (i_mem_tpl_len - 1) then

                    i_mem_tpl_cnt <= i_mem_tpl_cnt + 1;

                    i_trn_teof_n <= '1';

                    i_fsm_cs <= S_TX_MWR_QWN;

                end if;

            end if;
        --end S_TX_MWR_QW1 :

        when S_TX_MWR_QWN =>

            if i_usr_rxbuf_rd = '1' then

                i_trn_tsof_n <= '1';

                if G_USR_DBUS = 64 then

                    i_trn_td(32*2 - 1 downto 32*1) <= sr_usr_rxbuf_do_swap(32*1 - 1 downto 32*0);
                    i_trn_td(32*1 - 1 downto 32*0) <= i_usr_rxbuf_do_swap(32*2 - 1 downto 32*1);
                    i_trn_trem_n <= (others=>'0');

                    sr_usr_rxbuf_do_swap(32*1 - 1 downto 32*0) <= i_usr_rxbuf_do_swap(32*1 - 1 downto 32*0);

                else --if G_USR_DBUS = 32 then

                    if i_trn_trem_n = CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length) then
                      i_trn_td(32*1 - 1 downto 32*0) <= i_usr_rxbuf_do_swap;
                    else
                      i_trn_td(32*2 - 1 downto 32*1) <= i_usr_rxbuf_do_swap;
                    end if;

                    i_trn_trem_n <= i_trn_trem_n - 1;

                end if;

                --Счетчик отправленых данных (текущей транзакции)
                if i_mem_tpl_cnt = (i_mem_tpl_len - 1) then

                    i_mwr_work <= '0';

                    i_trn_tsrc_rdy_n <= '0';

                    if G_USR_DBUS = 64 then

                        if i_mem_tpl_dw(0) = '0' then
                        --Четное кол-во usr data(DW) в текущей TPL
                          i_trn_teof_n <= '1';
                          i_fsm_cs <= S_TX_MWR_QWN2;

                        else
                        --НЕ Четное кол-во usr data(DW) в текущей TPL
                            if i_mem_tpl_last = '1' then
                              i_mem_tx_byte <= (others=>'0');
                              i_mem_tpl_tag <= (others=>'0');
                              i_mwr_done <= '1';
                            end if;

                            i_mem_tpl_cnt <= (others=>'0');

                            i_trn_teof_n <= '0';
                            i_fsm_cs <= S_TX_IDLE;

                        end if;

                    else --if G_USR_DBUS = 32 then

                        i_mem_tpl_cnt <= (others=>'0');

                        if i_mem_tpl_last = '1' then
                          i_mem_tx_byte <= (others=>'0');
                          i_mem_tpl_tag <= (others=>'0');
                          i_mwr_done <= '1';
                        else
                          i_mem_tx_byte <= i_mem_tx_byte + EXT(i_mem_tpl_byte, i_mem_tx_byte'length);
                        end if;

                        i_trn_teof_n <= '0';

                        i_fsm_cs <= S_TX_MWR_QWN2;

                    end if;

                else --if i_mem_tpl_cnt /= (i_mem_tpl_len - 1) then

                    i_mem_tpl_cnt <= i_mem_tpl_cnt + 1;

                    if G_USR_DBUS = 64 then
                      i_trn_tsrc_rdy_n <= '0';
                    else --if G_USR_DBUS = 32 then
                      i_trn_tsrc_rdy_n <= not i_trn_trem_n(0);
                    end if;

                    i_trn_teof_n <= '1';

                    i_fsm_cs <= S_TX_MWR_QWN;

                end if;

            else --if i_usr_rxbuf_rd /= '1' then

                i_trn_tsrc_rdy_n <= '1';

            end if;
        --end S_TX_MWR_QWN :

        when S_TX_MWR_QWN2 =>

            if trn_tdst_rdy_n = '0' then

              if G_USR_DBUS = 64 then

                  i_mem_tpl_cnt <= (others=>'0');

                  if i_mem_tpl_last = '1' then
                    i_mem_tx_byte <= (others=>'0');
                    i_mem_tpl_tag <= (others=>'0');
                    i_mwr_done <= '1';
                  else
                    i_mem_tx_byte <= i_mem_tx_byte + EXT(i_mem_tpl_byte, i_mem_tx_byte'length);
                  end if;

                  i_trn_td(32*2 - 1 downto 32*1) <= sr_usr_rxbuf_do_swap(32*1 - 1 downto 32*0);
                  i_trn_td(32*1 - 1 downto 32*0) <= sr_usr_rxbuf_do_swap(32*1 - 1 downto 32*0);

                  i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);
                  i_trn_teof_n <= '0';
                  i_trn_tsrc_rdy_n <= '0';

                  i_fsm_cs <= S_TX_IDLE;

              else --if G_USR_DBUS = 32 then

                  i_trn_tsof_n <= '1';
                  i_trn_teof_n <= '1';
                  i_trn_tsrc_rdy_n <= '1';
                  i_trn_trem_n <= (others=>'0');

                  i_mem_tpl_last <= '0';

                  i_fsm_cs <= S_TX_IDLE;

              end if;

            end if;
        --end S_TX_MWR_QWN2 :
        --END: MWr , +data

        --#######################################################################
        --MRd - 3DW, no data  (PC<-FPGA) (запрос записи в память PC)
        --#######################################################################
        when S_TX_MRD_QW00 =>

          if i_mem_remain_byte > EXT(i_mrd_tpl_max_byte, i_mem_remain_byte'length) then
              i_mem_tpl_last <= '0';
              i_mem_tpl_byte <= i_mrd_tpl_max_byte;
              i_mem_tpl_dw <= (CONV_STD_LOGIC_VECTOR(0, log2(32/8)) &
                              i_mrd_tpl_max_byte(i_mem_tpl_dw'high downto log2(32/8)));
          else
              i_mem_tpl_last <= '1';
              i_mem_tpl_byte <= i_mem_remain_byte(i_mem_tpl_byte'range);
              i_mem_tpl_dw <= (CONV_STD_LOGIC_VECTOR(0, log2(32/8)) &
                              i_mem_remain_byte(i_mem_tpl_dw'high downto log2(32/8)))
                              + OR_reduce(i_mem_remain_byte(log2(32/8) - 1 downto 0));
          end if;

          i_fsm_cs <= S_TX_MRD_QW0;
        --end S_TX_MRD_QW00 :

        when S_TX_MRD_QW0 =>

            if trn_tdst_rdy_n = '0' then

                i_trn_tsof_n <= '0';
                i_trn_teof_n <= '1';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= (others=>'0');

                i_trn_td(63) <= '0';
                i_trn_td(62 downto 56) <= C_PCIE_PKT_TYPE_MRD_3DW_ND;
                i_trn_td(55 downto 16) <= ('0' &
                           mrd_tlp_tc_i &
                           "0000" &
                           '0' &
                           '0' &
                           mrd_relaxed_order_i & mrd_nosnoop_i &
                           "00" &
                           i_mem_tpl_dw(9 downto 0) &
                           completer_id_i(15 downto 3) & mrd_phant_func_en1_i & "00");

                if tag_ext_en_i = '1' then
                i_trn_td(15 downto 8) <= i_mem_tpl_tag(7 downto 0);
                else
                i_trn_td(15 downto 8) <= EXT(i_mem_tpl_tag(4 downto 0), 8);
                end if;

                --Last DW Byte Enable
                case i_mem_tpl_byte(1 downto 0) is
                when "00" => i_trn_td(7 downto 4) <= "1111";
                when "01" => i_trn_td(7 downto 4) <= "0001";
                when "10" => i_trn_td(7 downto 4) <= "0011";
                when "11" => i_trn_td(7 downto 4) <= "0111";
                when others => null;
                end case;

                --1st DW Byte Enable
                case i_mem_adr_byte(1 downto 0) is
                when "00" => i_trn_td(3 downto 0) <= "1111";
                when "01" => i_trn_td(3 downto 0) <= "1110";
                when "10" => i_trn_td(3 downto 0) <= "1100";
                when "11" => i_trn_td(3 downto 0) <= "1000";
                when others => null;
                end case;

                i_mem_tx_byte <= i_mem_tx_byte + EXT(i_mem_tpl_byte, i_mem_tx_byte'length);

                i_mem_tpl_tag <= i_mem_tpl_tag + 1;

                i_fsm_cs <= S_TX_MRD_QW1;

            end if;
        --end S_TX_MRD_QW0 :

        when S_TX_MRD_QW1 =>

            if trn_tdst_rdy_n = '0' then

                i_trn_tsof_n <= '1';
                i_trn_teof_n <= '0';
                i_trn_tsrc_rdy_n <= '0';
                i_trn_trem_n <= CONV_STD_LOGIC_VECTOR(16#01#, i_trn_trem_n'length);

                i_trn_td(32*2 - 1 downto 32*1) <= (i_mem_adr_byte(31 downto 2) & "00");
                i_trn_td(32*1 - 1 downto 32*0) <= (others=>'0');

                if i_mem_tpl_last = '1' then
                  i_mem_tx_byte <= (others=>'0');
                  i_mem_tpl_tag <= (others=>'0');
                  i_mrd_done <= '1';
                end if;

                i_mem_adr_byte <= i_mem_adr_byte + EXT(i_mem_tpl_byte, i_mem_adr_byte'length);

                i_fsm_cs <= S_TX_IDLE;

            end if;
        --end S_TX_MRD_QW1 :
        --END: MRd - 3DW, no data

    end case; --case i_fsm_cs is
  end if;
end process;--fsm


--END MAIN
end behavioral;

