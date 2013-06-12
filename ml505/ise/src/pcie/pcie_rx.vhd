-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.08.2012 17:56:21
-- Module Name : pcie_rx.v
--
-- Description : PCI rxd
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

entity pcie_rx is
--generic(
--G_PCIE_TRN_DBUS : integer:=64
--);
port(
--usr app
usr_reg_adr_o       : out   std_logic_vector(7 downto 0);
usr_reg_din_o       : out   std_logic_vector(31 downto 0);
usr_reg_wr_o        : out   std_logic;
usr_reg_rd_o        : out   std_logic;

--usr_txbuf_dbe_o     : out   std_logic_vector(7 downto 0);
usr_txbuf_din_o     : out   std_logic_vector(31 downto 0);
usr_txbuf_wr_o      : out   std_logic;
usr_txbuf_wr_last_o : out   std_logic;
usr_txbuf_full_i    : in    std_logic;

--pci_core -> usr_app
trn_rd              : in    std_logic_vector(63 downto 0);
trn_rrem_n          : in    std_logic_vector(3 downto 0);
trn_rsof_n          : in    std_logic;
trn_reof_n          : in    std_logic;
trn_rsrc_rdy_n      : in    std_logic;             --pci_core - rdy
trn_rsrc_dsc_n      : in    std_logic;
trn_rdst_rdy_n_o    : out   std_logic;             --usr_app - rdy
trn_rbar_hit_n      : in    std_logic_vector(6 downto 0);

--Handshake with Tx engine:
req_compl_o         : out   std_logic;
compl_done_i        : in    std_logic;

req_addr_o          : out   std_logic_vector(29 downto 0);
req_pkt_type_o      : out   std_logic_vector(6 downto 0);
req_tc_o            : out   std_logic_vector(2 downto 0);
req_td_o            : out   std_logic;
req_ep_o            : out   std_logic;
req_attr_o          : out   std_logic_vector(1 downto 0);
req_len_o           : out   std_logic_vector(9 downto 0);
req_rid_o           : out   std_logic_vector(15 downto 0);
req_tag_o           : out   std_logic_vector(7 downto 0);
req_be_o            : out   std_logic_vector(7 downto 0);
req_exprom_o        : out   std_logic;

--dma trn
dma_init_i          : in    std_logic;

cpld_total_size_o   : out   std_logic_vector(31 downto 0); --ќбщее кол-во данных(DW) от всех прин€тых пакетов CplD (m_pcie_usr_app/p_in_mrd_rcv_size)
cpld_malformed_o    : out   std_logic;                     --–езультат сравнение (i_cpld_tlp_len != i_cpld_tlp_cnt)

--“ехнологический порт
tst_o               : out   std_logic_vector(31 downto 0);
tst_i               : in    std_logic_vector(31 downto 0);

--System
clk                 : in    std_logic;
rst_n               : in    std_logic
);
end pcie_rx;

architecture behavioral of pcie_rx is

type TFsm_state is (
S_RX_IDLE    ,
S_RX_IOWR_QW1,
S_RX_IOWR_WT ,
S_RX_MWR_QW1 ,
S_RX_MWR_QW41,
S_RX_MWR_QW42,
S_RX_MWR_WT  ,
S_RX_MRD_QW1 ,
S_RX_MRD_QW41,
S_RX_MRD_QW42,
S_RX_MRD_WT  ,
S_RX_CPL_QW1 ,
S_RX_CPLD_QWN,
S_RX_CPLD_WT ,
S_RX_MRD_WT1
);
signal i_fsm_cs            : TFsm_state;

signal i_bar_exprom        : std_logic;
signal i_bar_usr           : std_logic;

signal i_cpld_total_size   : std_logic_vector(31 downto 0);
signal i_cpld_malformed    : std_logic;

signal i_req_compl         : std_logic;
signal i_req_addr          : std_logic_vector(29 downto 0);
signal i_req_pkt_type      : std_logic_vector(6 downto 0);
signal i_req_tc            : std_logic_vector(2 downto 0);
signal i_req_td            : std_logic;
signal i_req_ep            : std_logic;
signal i_req_attr          : std_logic_vector(1 downto 0);
signal i_req_len           : std_logic_vector(9 downto 0);
signal i_req_rid           : std_logic_vector(15 downto 0);
signal i_req_tag           : std_logic_vector(7 downto 0);
signal i_req_be            : std_logic_vector(7 downto 0);
signal i_req_exprom        : std_logic;

signal i_trn_rdst_rdy_n    : std_logic;

signal i_cpld_tlp_cnt      : std_logic_vector(9 downto 0);
signal i_cpld_tlp_len      : std_logic_vector(9 downto 0);
signal i_cpld_tlp_dlast    : std_logic;
signal i_cpld_tlp_work     : std_logic;

signal i_usr_di            : std_logic_vector(31 downto 0);
signal i_usr_di_swap       : std_logic_vector(31 downto 0);
signal i_usr_wr            : std_logic;
signal i_usr_rd            : std_logic;

signal i_trn_dw_skip       : std_logic;
signal i_trn_dw_sel        : std_logic_vector(trn_rd'length/64 - 1 downto 0);


--MAIN
begin


----------------------------------------
--“ехнологические
----------------------------------------
tst_o(5 downto 0) <= i_cpld_tlp_cnt(5 downto 0);
tst_o(6) <= i_trn_rdst_rdy_n;
tst_o(7) <= usr_txbuf_full_i;
tst_o(11 downto 8) <= EXT(i_trn_dw_sel, 4);


----------------------------------------
--
----------------------------------------
i_bar_exprom <= not trn_rbar_hit_n(6);
i_bar_usr <= not trn_rbar_hit_n(0) or not trn_rbar_hit_n(1);

usr_reg_adr_o <= (i_req_addr(5 downto 0) & "00");
usr_reg_din_o <= i_usr_di_swap;
usr_reg_rd_o <= i_usr_rd;
usr_reg_wr_o <= i_usr_wr and not i_cpld_tlp_work;

usr_txbuf_din_o <= i_usr_di_swap;
usr_txbuf_wr_o <= i_usr_wr and i_cpld_tlp_work;
usr_txbuf_wr_last_o <= i_cpld_tlp_dlast;

trn_rdst_rdy_n_o <= i_trn_rdst_rdy_n or OR_reduce(i_trn_dw_sel) or (usr_txbuf_full_i and i_cpld_tlp_work);

--swap BYTE
gen_swap_usr_di : for i in 0 to i_usr_di'length/8 - 1 generate
i_usr_di_swap((i_usr_di_swap'length - 8*i) - 1 downto
              (i_usr_di_swap'length - 8*(i+1))) <= i_usr_di(8*(i+1) - 1 downto 8*i);
end generate gen_swap_usr_di;

req_compl_o   <= i_req_compl;
req_exprom_o  <= i_req_exprom;
req_pkt_type_o<= i_req_pkt_type;
req_tc_o      <= i_req_tc;
req_td_o      <= i_req_td;
req_ep_o      <= i_req_ep;
req_attr_o    <= i_req_attr;
req_len_o     <= i_req_len;
req_rid_o     <= i_req_rid;
req_tag_o     <= i_req_tag;
req_be_o      <= i_req_be;
req_addr_o    <= i_req_addr;

cpld_total_size_o <= i_cpld_total_size;
cpld_malformed_o <= i_cpld_malformed;

process(rst_n, clk)
begin
  if rst_n = '0' then
    i_cpld_total_size <= (others=>'0');
    i_cpld_malformed <= '0';

  elsif rising_edge(clk) then

    if dma_init_i='1' then --»нициализаци€ перед началом DMA транзакции
      i_cpld_total_size <= (others=>'0');
      i_cpld_malformed <= '0';

    else
      if (i_fsm_cs = S_RX_CPLD_WT) then

        if  (i_cpld_tlp_len /= i_cpld_tlp_cnt) then
        i_cpld_malformed <= '1';
        end if;

        i_cpld_total_size <= i_cpld_total_size + EXT(i_cpld_tlp_len, i_cpld_total_size'length);
      end if;

    end if;
  end if;
end process;

--Rx State Machine
process(rst_n, clk)
begin
  if rst_n = '0' then

    i_fsm_cs <= S_RX_IDLE;

    i_trn_rdst_rdy_n <= '0';

    i_req_compl <= '0';
    i_req_exprom <= '0';
    i_req_pkt_type <= (others=>'0');
    i_req_tc   <= (others=>'0');
    i_req_td   <= '0';
    i_req_ep   <= '0';
    i_req_attr <= (others=>'0');
    i_req_len  <= (others=>'0');
    i_req_rid  <= (others=>'0');
    i_req_tag  <= (others=>'0');
    i_req_be   <= (others=>'0');
    i_req_addr <= (others=>'0');

    i_cpld_tlp_len <= (others=>'0');
    i_cpld_tlp_cnt <= (others=>'0');
    i_cpld_tlp_dlast <= '0';
    i_cpld_tlp_work <= '0';

    i_trn_dw_sel <= (others=>'0');
    i_trn_dw_skip <= '0';

    i_usr_di <= (others=>'0');
    i_usr_wr <= '0';
    i_usr_rd <= '0';

  elsif rising_edge(clk) then

    case i_fsm_cs is
        --#######################################################################
        --јнализ типа прин€того пакета
        --#######################################################################
        when S_RX_IDLE =>

            if trn_rsof_n = '0' and trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' then
                case trn_rd(62 downto 56) is --поле FMT (‘ормат пакета) + поле TYPE (“ип пакета)
                    -------------------------------------------------------------------------
                    --IORd - 3DW, no data (PC<-FPGA)
                    -------------------------------------------------------------------------
                    when C_PCIE_PKT_TYPE_IORD_3DW_ND =>

                      if trn_rd(41 downto 32) = CONV_STD_LOGIC_VECTOR(16#01#, 10) then --Length data payload (DW)
                        i_req_pkt_type <= trn_rd(62 downto 56);
                        i_req_tc       <= trn_rd(54 downto 52);
                        i_req_td       <= trn_rd(47);
                        i_req_ep       <= trn_rd(46);
                        i_req_attr     <= trn_rd(45 downto 44);
                        i_req_len      <= trn_rd(41 downto 32); --Length data payload (DW)
                        i_req_rid      <= trn_rd(31 downto 16);
                        i_req_tag      <= trn_rd(15 downto  8);
                        i_req_be       <= trn_rd( 7 downto  0);

                        i_fsm_cs <= S_RX_MRD_QW1;
                      end if;

                    -------------------------------------------------------------------------
                    --IOWr - 3DW, +data (PC->FPGA)
                    -------------------------------------------------------------------------
                    when C_PCIE_PKT_TYPE_IOWR_3DW_WD =>

                      if trn_rd(41 downto 32) = CONV_STD_LOGIC_VECTOR(16#01#, 10) then --Length data payload (DW)
                        i_req_pkt_type <= trn_rd(62 downto 56);
                        i_req_tc       <= trn_rd(54 downto 52);
                        i_req_td       <= trn_rd(47);
                        i_req_ep       <= trn_rd(46);
                        i_req_attr     <= trn_rd(45 downto 44);
                        i_req_len      <= trn_rd(41 downto 32); --Length data payload (DW)
                        i_req_rid      <= trn_rd(31 downto 16);
                        i_req_tag      <= trn_rd(15 downto  8);
                        i_req_be       <= trn_rd( 7 downto  0);

                        i_fsm_cs <= S_RX_IOWR_QW1;
                      end if;

                    -------------------------------------------------------------------------
                    --MWr - 3DW, +data (PC->FPGA)
                    -------------------------------------------------------------------------
                   when C_PCIE_PKT_TYPE_MWR_3DW_WD =>

                     if trn_rd(41 downto 32) = CONV_STD_LOGIC_VECTOR(16#01#, 10) then --Length data payload (DW)
                        i_fsm_cs <= S_RX_MWR_QW1;
                     end if;

                    -------------------------------------------------------------------------
                    --MWr - 4DW, +data (PC->FPGA)
                    -------------------------------------------------------------------------
                   when C_PCIE_PKT_TYPE_MWR_4DW_WD =>

                     if trn_rd(41 downto 32) = CONV_STD_LOGIC_VECTOR(16#01#, 10) then --Length data payload (DW)
                        i_fsm_cs <= S_RX_MWR_QW41;
                     end if;

                    -------------------------------------------------------------------------
                    --MRd - 3DW, no data (PC<-FPGA)
                    -------------------------------------------------------------------------
                    when C_PCIE_PKT_TYPE_MRD_3DW_ND =>

                      if trn_rd(41 downto 32) = CONV_STD_LOGIC_VECTOR(16#01#, 10) then --Length data payload (DW)
                        i_req_pkt_type <= trn_rd(62 downto 56);
                        i_req_tc       <= trn_rd(54 downto 52);
                        i_req_td       <= trn_rd(47);
                        i_req_ep       <= trn_rd(46);
                        i_req_attr     <= trn_rd(45 downto 44);
                        i_req_len      <= trn_rd(41 downto 32);
                        i_req_rid      <= trn_rd(31 downto 16);
                        i_req_tag      <= trn_rd(15 downto  8);
                        i_req_be       <= trn_rd( 7 downto  0);

                        if i_bar_exprom = '1' then
                          i_req_exprom <= '1';
                        end if;

                        i_fsm_cs <= S_RX_MRD_QW1;
                      end if;

                    -------------------------------------------------------------------------
                    --MRd - 4DW, no data (PC<-FPGA)
                    -------------------------------------------------------------------------
                    when C_PCIE_PKT_TYPE_MRD_4DW_ND =>

                      if trn_rd(41 downto 32) = CONV_STD_LOGIC_VECTOR(16#01#, 10) then --Length data payload (DW)
                        i_req_pkt_type <= trn_rd(62 downto 56);
                        i_req_tc       <= trn_rd(54 downto 52);
                        i_req_td       <= trn_rd(47);
                        i_req_ep       <= trn_rd(46);
                        i_req_attr     <= trn_rd(45 downto 44);
                        i_req_len      <= trn_rd(41 downto 32);
                        i_req_rid      <= trn_rd(31 downto 16);
                        i_req_tag      <= trn_rd(15 downto  8);
                        i_req_be       <= trn_rd( 7 downto  0);

                        if i_bar_exprom = '1' then
                          i_req_exprom <= '1';
                        end if;

                        i_fsm_cs <= S_RX_MRD_QW41;
                      end if;

                    -------------------------------------------------------------------------
                    --Cpl - 3DW, no data
                    -------------------------------------------------------------------------
                    when C_PCIE_PKT_TYPE_CPL_3DW_ND =>

                      --if trn_rd(15 downto 13) /= C_PCIE_COMPL_STATUS_SC then
                        i_fsm_cs <= S_RX_CPL_QW1;
                      --end if;

                    -------------------------------------------------------------------------
                    --CplD - 3DW, +data
                    -------------------------------------------------------------------------
                    when C_PCIE_PKT_TYPE_CPLD_3DW_WD =>

                        i_cpld_tlp_len <= trn_rd(41 downto 32); --Length data payload (DW)
                        i_cpld_tlp_cnt <= (others=>'0');
                        i_cpld_tlp_work <= '1';
                        i_trn_dw_sel <= (others=>'1');
                        i_trn_dw_skip <= '1';
                        i_fsm_cs <= S_RX_CPLD_QWN;

                     when others =>
                        i_fsm_cs <= S_RX_IDLE;

                end case; --case (trn_rd(62 downto 56))
            end if; --if trn_rsof_n = '0' and trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' then
        --end S_RX_IDLE :


        --#######################################################################
        --IOWr - 3DW, +data (PC->FPGA)
        --#######################################################################
        when S_RX_IOWR_QW1 =>

            if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' then
              i_req_addr <= trn_rd(63 downto 34);
              i_usr_di <= trn_rd(31 downto 0);

              if i_bar_usr = '1' then
                i_usr_wr <= '1';
              end if;

              i_req_compl <= '1'; --«апрос передачи пакета Cpl
              i_trn_rdst_rdy_n <= '1';
              i_fsm_cs <= S_RX_IOWR_WT;
            else
              if trn_rsrc_dsc_n = '0' then --ядро прерывало прием данных
                i_fsm_cs <= S_RX_IDLE;
              end if;
            end if;

        when S_RX_IOWR_WT =>

            i_usr_wr <= '0';
            if compl_done_i = '1' then --отправка пакета Cpl завершена
              i_req_compl <= '0';
              i_trn_rdst_rdy_n <= '0';
              i_fsm_cs <= S_RX_IDLE;
            end if;
        --END: IOWr - 3DW, +data


        --#######################################################################
        --MRd - 3DW, no data (PC<-FPGA)
        --#######################################################################
        when S_RX_MRD_QW1 =>

            if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' then
              i_req_addr <= trn_rd(63 downto 34);
              i_trn_rdst_rdy_n <= '1';

              if i_req_exprom = '0' then
                if i_bar_usr = '1' then
                  i_usr_rd <= '1';
                end if;
              end if;

              i_fsm_cs <= S_RX_MRD_WT1;
            else
              if trn_rsrc_dsc_n = '0' then --ядро прерывало прием данных
                i_req_exprom <= '0';
                i_fsm_cs <= S_RX_IDLE;
              end if;
            end if;

        when S_RX_MRD_WT1 =>

            i_usr_rd <= '0';
            i_req_compl <= '1';--«апрос передачи пакета CplD
            i_fsm_cs <= S_RX_MRD_WT;

        when S_RX_MRD_WT =>

            if compl_done_i = '1' then --отправка пакета CplD завершена
              i_req_exprom <= '0';
              i_req_compl <= '0';
              i_trn_rdst_rdy_n <= '0';
              i_fsm_cs <= S_RX_IDLE;
            end if;
        --END: MRd - 3DW, no data


        --#######################################################################
        --MRd - 4DW, no data (PC<-FPGA)
        --#######################################################################
        when S_RX_MRD_QW41 =>

            if trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' then
              i_req_addr <= trn_rd(31 downto 2);
              i_trn_rdst_rdy_n <= '1';

              if i_req_exprom = '0' then
                if i_bar_usr = '1' then
                  i_usr_rd <= '1';
                end if;
              end if;

              i_fsm_cs <= S_RX_MRD_WT1;
            else
              if trn_rsrc_dsc_n = '0' then --ядро прерывало прием данных
                i_req_exprom <= '0';
                i_fsm_cs <= S_RX_IDLE;
              end if;
            end if;

        when S_RX_MRD_QW42 =>

            i_usr_rd <= '0';

            if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' then
            i_req_compl <= '1';--«апрос передачи пакета CplD
            i_fsm_cs <= S_RX_MRD_WT;
            end if;
        --END: MRd - 4DW, no data


        --#######################################################################
        --MWr - 3DW, +data (PC->FPGA)
        --#######################################################################
        when S_RX_MWR_QW1 =>

            if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' then
              i_req_addr <= trn_rd(63 downto 34);
              i_usr_di <= trn_rd(31 downto 0);

              if i_bar_usr = '1' then
                i_usr_wr <= '1';
              end if;

              i_trn_rdst_rdy_n <= '1';
              i_fsm_cs <= S_RX_MWR_WT;
            else
              if trn_rsrc_dsc_n = '0' then --ядро прерывало прием данных
                i_fsm_cs <= S_RX_IDLE;
              end if;
            end if;

        when S_RX_MWR_WT =>
            i_usr_wr <= '0';
            i_trn_rdst_rdy_n <= '0';
            i_fsm_cs <= S_RX_IDLE;
        --END: MWr - 3DW, +data


        --#######################################################################
        --MWr - 4DW, +data (PC->FPGA)
        --#######################################################################
        when S_RX_MWR_QW41 =>

            if trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' then
              i_usr_di <= trn_rd(63 downto 32);

              i_trn_rdst_rdy_n <= '1';
              i_fsm_cs <= S_RX_MWR_WT;
            else
              if trn_rsrc_dsc_n = '0' then --ядро прерывало прием данных
                i_fsm_cs <= S_RX_IDLE;
              end if;
            end if;

        when S_RX_MWR_QW42 =>

            if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' then
              i_req_addr <= trn_rd(31 downto 2);

              if i_bar_usr = '1' then
                i_usr_wr <= '1';
              end if;

              i_trn_rdst_rdy_n <= '1';
              i_fsm_cs <= S_RX_MWR_WT;
            else
              if trn_rsrc_dsc_n = '0' then --ядро прерывало прием данных
                i_fsm_cs <= S_RX_IDLE;
              end if;
            end if;
        --END: MWr - 4DW, +data (PC->FPGA)


        --#######################################################################
        --Cpl - 3DW, no data
        --#######################################################################
        when S_RX_CPL_QW1 =>

            if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' then
              i_fsm_cs <= S_RX_IDLE;
            else
              if trn_rsrc_dsc_n = '0' then --ядро прерывало прием данных
                i_fsm_cs <= S_RX_IDLE;
              end if;
            end if;
        --END: Cpl - 3DW, no data


        --#######################################################################
        --CplD - 3DW, +data
        --#######################################################################
        when S_RX_CPLD_QWN =>

            if trn_rsrc_rdy_n = '0' and trn_rsrc_dsc_n = '1' and usr_txbuf_full_i = '0' then

                if    i_trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#00#, i_trn_dw_sel'length) then
                  i_usr_di <= trn_rd(31 downto 0);
                elsif i_trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#01#, i_trn_dw_sel'length) then
                  i_usr_di <= trn_rd(63 downto 32);
                end if;

                if trn_reof_n = '0' then --EOF
                    i_trn_dw_sel <= i_trn_dw_sel - 1;
                    i_trn_dw_skip <= '0';

                    if i_trn_dw_skip = '0' then
                      i_usr_wr <= '1';
                      i_cpld_tlp_cnt <= i_cpld_tlp_cnt + 1;
                    else
                      i_usr_wr <= '0';
                    end if;

                    if   ((trn_rrem_n = CONV_STD_LOGIC_VECTOR(16#00#,trn_rrem_n'length)) and
                        (i_trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#00#,i_trn_dw_sel'length)))
                      or
                         ((trn_rrem_n = CONV_STD_LOGIC_VECTOR(16#01#,trn_rrem_n'length)) and
                        (i_trn_dw_sel = CONV_STD_LOGIC_VECTOR(16#01#,i_trn_dw_sel'length))) then

                      i_cpld_tlp_dlast <= '1';
                      i_trn_rdst_rdy_n <= '1';
                      i_fsm_cs <= S_RX_CPLD_WT;

                    end if;
                else
                  if trn_rsof_n = '1' then
                      i_trn_dw_sel <= i_trn_dw_sel - 1;
                      i_trn_dw_skip <= '0';

                      if i_trn_dw_skip = '0' then
                        i_usr_wr <= '1';
                        i_cpld_tlp_cnt <= i_cpld_tlp_cnt + 1;
                      else
                        i_usr_wr <= '0';
                      end if;

                      i_fsm_cs <= S_RX_CPLD_QWN;
                  else
                      i_usr_wr <= '0';
                      i_fsm_cs <= S_RX_CPLD_QWN;
                  end if;
                end if;
            else
              if trn_rsrc_dsc_n = '0' then --ядро прерывало прием данных
                  i_cpld_tlp_dlast <= '1';
                  i_usr_wr <= '0';
                  i_fsm_cs <= S_RX_CPLD_WT;
              else
                  i_usr_wr <= '0';
                  i_fsm_cs <= S_RX_CPLD_QWN;
              end if;
            end if;
        --end S_RX_CPLD_QWN :

        when S_RX_CPLD_WT =>

            i_cpld_tlp_cnt <= (others=>'0');
            i_cpld_tlp_dlast <= '0';
            i_cpld_tlp_work <= '0';
            i_trn_rdst_rdy_n <= '0';
            i_trn_dw_sel <= (others=>'0');
            i_usr_wr <= '0';
            i_fsm_cs <= S_RX_IDLE;
        --END: CplD - 3DW, +data

    end case; --case i_fsm_cs is
  end if;
end process;


--END MAIN
end behavioral;
