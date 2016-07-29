-------------------------------------------------------------------------
--Engineer    : Golovachenko Victor
--
--Create Date : 23.07.2015 11:21:07
--Module Name : pcie_tx_rq.vhd
--
--Description : DMA: Host <- FPGA (MemWR + MemRD request)
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.pcie_pkg.all;

entity pcie_tx_rq is
generic (
G_DATA_WIDTH : integer := 64
);
port(
--AXI-S Requester Request Interface
p_out_axi_rq_tdata  : out std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_axi_rq_tkeep  : out std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_out_axi_rq_tlast  : out std_logic;
p_out_axi_rq_tvalid : out std_logic;
p_out_axi_rq_tuser  : out std_logic_vector(59 downto 0);
p_in_axi_rq_tready  : in  std_logic;

--Tag availability and Flow control Information
p_in_pcie_rq_tag          : in  std_logic_vector(5 downto 0);
p_in_pcie_rq_tag_vld      : in  std_logic;
p_in_pcie_tfc_nph_av      : in  std_logic_vector(1 downto 0);
p_in_pcie_tfc_npd_av      : in  std_logic_vector(1 downto 0);
p_in_pcie_tfc_np_pl_empty : in  std_logic;
p_in_pcie_rq_seq_num      : in  std_logic_vector(3 downto 0);
p_in_pcie_rq_seq_num_vld  : in  std_logic;

p_in_pcie_prm     : in  TPCIE_cfgprm;

p_in_completer_id : in  std_logic_vector(15 downto 0);

--usr app
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
p_in_dma_mrd_rxdwcount : in  std_logic_vector(31 downto 0);

--DBG
p_out_tst : out std_logic_vector(279 downto 0);

--system
p_in_clk   : in  std_logic;
p_in_rst_n : in  std_logic
);
end entity pcie_tx_rq;

architecture behavioral of pcie_tx_rq is

type TFsmTxRq_state is (
S_TXRQ_IDLE  ,

S_TXRQ_MWR_C0,--calc
S_TXRQ_MWR_C1,
S_TXRQ_MWR_D0,--data first
S_TXRQ_MWR_D1,--data first
S_TXRQ_MWR_DN,--data n

S_TXRQ_MRD_C0,
S_TXRQ_MRD_N,
S_TXRQ_MRD_N1,
S_TXRQ_CPLD_WAIT
);
signal i_fsm_txrq        : TFsmTxRq_state;

signal i_axi_rq_tdata    : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
signal i_axi_rq_tkeep    : std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
signal i_axi_rq_tlast    : std_logic;
signal i_axi_rq_tvalid   : std_logic;
signal i_axi_rq_tuser    : std_logic_vector(7 downto 0);

signal sr_usr_rxbuf_do      : std_logic_vector((32 * 4) - 1 downto 0);
signal i_urxbuf_rd          : std_logic;

signal i_dma_init           : std_logic;

signal i_mem_adr_byte       : unsigned(31 downto 0);

signal i_mem_tx_dw          : unsigned(31 downto 0);
signal i_mem_tx_byte        : unsigned(31 downto 0);
signal i_mem_tx_byte_remain : unsigned(31 downto 0);

signal i_mem_tpl_byte       : unsigned(10 downto 0);
signal i_mem_tpl_dw         : unsigned(10 downto 0);
signal i_mem_tpl_len        : unsigned(10 downto 0);
signal i_mem_tpl_cnt        : unsigned(10 downto 0);
signal i_mem_tpl_tag        : unsigned( 7 downto 0);--marker of send tpl
signal i_mem_tpl_last       : std_logic;
signal i_mem_tpl_dw_rem     : unsigned(10 downto 0);

signal i_mem_tpl_max_byte   : unsigned(10 downto 0);
signal i_mwr_work           : std_logic;
signal i_mwr_done           : std_logic;
signal i_mrd_done           : std_logic;

signal tst_fsm              : unsigned(3 downto 0);



begin --architecture behavioral of pcie_tx_rq

p_out_dma_mrd_done <= i_mrd_done;
p_out_dma_mwr_done <= i_mwr_done;

i_urxbuf_rd <= (p_in_axi_rq_tready and not p_in_urxbuf_empty);
p_out_urxbuf_rd <= i_urxbuf_rd and i_mwr_work;
p_out_urxbuf_last <= i_urxbuf_rd when i_mwr_work = '1'
                                        and i_mem_tpl_last = '1'
                                          and (i_mem_tpl_cnt = (i_mem_tpl_len - 1)) else '0';

--AXI-S Requester Request Interface
p_out_axi_rq_tdata  <= i_axi_rq_tdata ;
p_out_axi_rq_tkeep  <= i_axi_rq_tkeep ;
p_out_axi_rq_tvalid <= i_axi_rq_tvalid;
p_out_axi_rq_tlast  <= i_axi_rq_tlast ;
p_out_axi_rq_tuser(7 downto 0) <= i_axi_rq_tuser;
p_out_axi_rq_tuser(p_out_axi_rq_tuser'high downto 8) <= (others => '0');



--DMA initialization
init : process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0') then
    i_dma_init <= '0';

  else
    if (p_in_dma_init = '1') then
        i_dma_init <= '1';
    else
        if (i_fsm_txrq = S_TXRQ_MWR_C0) or (i_fsm_txrq = S_TXRQ_MRD_C0) then
          i_dma_init <= '0';
        end if;
    end if;
  end if;
end if;
end process;--init


i_mem_tpl_dw <= RESIZE(i_mem_tpl_byte(i_mem_tpl_byte'high downto 2), i_mem_tpl_dw'length)
                  + (TO_UNSIGNED(0, i_mem_tpl_dw'length - 2)
                      & OR_reduce(i_mem_tpl_byte(log2(32 / 8) - 1 downto 0)));

--Tx State Machine
fsm : process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0') then

    i_fsm_txrq <= S_TXRQ_IDLE;

    i_axi_rq_tdata  <= (others => '0');
    i_axi_rq_tkeep  <= (others => '0');
    i_axi_rq_tlast  <= '0';
    i_axi_rq_tvalid <= '0';
    i_axi_rq_tuser  <= (others => '0');

    sr_usr_rxbuf_do <= (others => '0');

    i_mem_adr_byte <= (others => '0');

    i_mem_tx_byte <= (others => '0');
    i_mem_tx_byte_remain <= (others => '0');

    i_mem_tpl_byte <= (others => '0');
    i_mem_tpl_dw_rem <= (others => '0');
    i_mem_tpl_len <= (others => '0');
    i_mem_tpl_cnt <= (others => '0');
    i_mem_tpl_tag <= (others => '0');
    i_mem_tpl_last <= '0';

    i_mem_tpl_max_byte <= (others => '0');
    i_mwr_work <= '0';
    i_mwr_done <= '0';
    i_mrd_done <= '0';

  else

    case i_fsm_txrq is
        --#######################################################################
        --
        --#######################################################################
        when S_TXRQ_IDLE =>

          if (p_in_axi_rq_tready = '1') then

            i_axi_rq_tlast  <= '0';
            i_axi_rq_tvalid <= '0';

            i_mwr_work <= '0';
            i_mem_tpl_last <= '0';

            if (p_in_dma_mwr_en = '1' and i_mwr_done = '0' and p_in_pcie_prm.master_en(0) = '1') then

                if (i_dma_init = '1') then

                  --max 1024 because pcie_core support max value 1024 (max_payload)
                  case p_in_pcie_prm.max_payload is
--                  when C_PCIE_MAX_PAYLOAD_4096_BYTE => i_mem_tpl_max_byte <= TO_UNSIGNED(4096, i_mem_tpl_max_byte'length);
--                  when C_PCIE_MAX_PAYLOAD_2048_BYTE => i_mem_tpl_max_byte <= TO_UNSIGNED(2048, i_mem_tpl_max_byte'length);
                  when C_PCIE_MAX_PAYLOAD_1024_BYTE => i_mem_tpl_max_byte <= TO_UNSIGNED(1024, i_mem_tpl_max_byte'length);
                  when C_PCIE_MAX_PAYLOAD_512_BYTE  => i_mem_tpl_max_byte <= TO_UNSIGNED(512 , i_mem_tpl_max_byte'length);
                  when C_PCIE_MAX_PAYLOAD_256_BYTE  => i_mem_tpl_max_byte <= TO_UNSIGNED(256 , i_mem_tpl_max_byte'length);
                  when C_PCIE_MAX_PAYLOAD_128_BYTE  => i_mem_tpl_max_byte <= TO_UNSIGNED(128 , i_mem_tpl_max_byte'length);
                  when others => null;
                  end case;

                  i_mem_adr_byte <= UNSIGNED(p_in_dma_prm.addr);
                  i_mem_tx_byte_remain <= UNSIGNED(p_in_dma_prm.len);

                else
                  i_mem_tx_byte_remain <= UNSIGNED(p_in_dma_prm.len) - i_mem_tx_byte;
                end if;

                i_fsm_txrq <= S_TXRQ_MWR_C0;

            elsif (p_in_dma_mrd_en = '1' and i_mrd_done = '0' and p_in_pcie_prm.master_en(0) = '1') then
                if (i_dma_init = '1') then

                  case p_in_pcie_prm.max_rd_req is
--                  when C_PCIE_MAX_RD_REQ_4096_BYTE => i_mem_tpl_max_byte <= TO_UNSIGNED(4096, i_mem_tpl_max_byte'length);
--                  when C_PCIE_MAX_RD_REQ_2048_BYTE => i_mem_tpl_max_byte <= TO_UNSIGNED(2048, i_mem_tpl_max_byte'length);
                  when C_PCIE_MAX_RD_REQ_1024_BYTE => i_mem_tpl_max_byte <= TO_UNSIGNED(1024, i_mem_tpl_max_byte'length);
                  when C_PCIE_MAX_RD_REQ_512_BYTE  => i_mem_tpl_max_byte <= TO_UNSIGNED(512, i_mem_tpl_max_byte'length);
                  when C_PCIE_MAX_RD_REQ_256_BYTE  => i_mem_tpl_max_byte <= TO_UNSIGNED(256, i_mem_tpl_max_byte'length);
                  when C_PCIE_MAX_RD_REQ_128_BYTE  => i_mem_tpl_max_byte <= TO_UNSIGNED(128, i_mem_tpl_max_byte'length);
                  when others => null;
                  end case;

                  i_mem_adr_byte <= UNSIGNED(p_in_dma_prm.addr);
                  i_mem_tx_byte_remain <= UNSIGNED(p_in_dma_prm.len);

                else
                  i_mem_tx_byte_remain <= UNSIGNED(p_in_dma_prm.len) - i_mem_tx_byte;
                end if;

                i_fsm_txrq <= S_TXRQ_MRD_C0;

            else

                if (i_dma_init = '1') then
                  i_mwr_done <= '0';
                  i_mrd_done <= '0';
                end if;

            end if;

          end if;

        --#######################################################################
        --MWr , +data (PC<-FPGA) FPGA is PCIe master
        --#######################################################################
        when S_TXRQ_MWR_C0 =>

            if (i_mem_tx_byte_remain > RESIZE(i_mem_tpl_max_byte, i_mem_tx_byte_remain'length) ) then
                i_mem_tpl_last <= '0';
                i_mem_tpl_byte <= i_mem_tpl_max_byte;

                i_mem_tpl_len <= RESIZE(i_mem_tpl_max_byte(i_mem_tpl_len'high downto log2(G_DATA_WIDTH / 8)), i_mem_tpl_len'length);
            else
                i_mem_tpl_last <= '1';
                i_mem_tpl_byte <= i_mem_tx_byte_remain(i_mem_tpl_byte'range);

                i_mem_tpl_len <= RESIZE(i_mem_tx_byte_remain(i_mem_tpl_len'high downto log2(G_DATA_WIDTH / 8)), i_mem_tpl_len'length)
                                + (TO_UNSIGNED(0, i_mem_tpl_len'length - 2)
                                    & OR_reduce(i_mem_tx_byte_remain(log2(G_DATA_WIDTH / 8) - 1 downto 0)));
            end if;

            i_fsm_txrq <= S_TXRQ_MWR_C1;
          --end S_TXRQ_MWR_C0


        when S_TXRQ_MWR_C1 =>

            i_mem_tpl_dw_rem <= (i_mem_tpl_len(i_mem_tpl_len'high - (log2(G_DATA_WIDTH / 8) - 2) downto 0)
                                 & TO_UNSIGNED(0, (log2(G_DATA_WIDTH / 8) - 2))) - i_mem_tpl_dw;

            i_fsm_txrq <= S_TXRQ_MWR_D0;
        --end S_TXRQ_MWR_C1


        when S_TXRQ_MWR_D0 =>

            if (i_urxbuf_rd = '1') then

                i_axi_rq_tkeep <= "11";

                i_axi_rq_tvalid <= '1';

                --First DW BE, Last DW BE - only for address divided 32 byte
                --1st DW Byte Enable (first_be)
                if (i_mem_tpl_dw = TO_UNSIGNED(16#01#, i_mem_tpl_dw'length))then
                case (i_mem_tpl_byte(1 downto 0)) is
                when "00" => i_axi_rq_tuser(3 downto 0) <= "1111";
                when "01" => i_axi_rq_tuser(3 downto 0) <= "0001";
                when "10" => i_axi_rq_tuser(3 downto 0) <= "0011";
                when "11" => i_axi_rq_tuser(3 downto 0) <= "0111";
                when others => null;
                end case;
                else
                i_axi_rq_tuser(3 downto 0) <= "1111";
                end if;

                --Last DW Byte Enable (last_be)
                if (i_mem_tpl_dw = TO_UNSIGNED(16#01#, i_mem_tpl_dw'length)) then
                i_axi_rq_tuser(7 downto 4) <= "0000";
                else
                case (i_mem_tpl_byte(1 downto 0)) is
                when "00" => i_axi_rq_tuser(7 downto 4) <= "1111";
                when "01" => i_axi_rq_tuser(7 downto 4) <= "0001";
                when "10" => i_axi_rq_tuser(7 downto 4) <= "0011";
                when "11" => i_axi_rq_tuser(7 downto 4) <= "0111";
                when others => null;
                end case;
                end if;

--                i_axi_rq_tuser(10 downto 8) <= (others => '0');--addr_offset; Used only in addres-alogen mode
--                i_axi_rq_tuser(11) <= '0';--Discontinue;

                i_axi_rq_tdata((32 * 2) - 1 downto (32 * 0)) <= std_logic_vector(RESIZE(i_mem_adr_byte(31 downto 2), (32 * 2) - 2)) & "00";

                i_fsm_txrq <= S_TXRQ_MWR_D1;

            end if;

        when S_TXRQ_MWR_D1 =>

            if (i_urxbuf_rd = '1') then

                i_axi_rq_tdata((32 * 0) + 10 downto (32 * 0) +  0) <= std_logic_vector(i_mem_tpl_dw(10 downto 0)); --DW count
                i_axi_rq_tdata((32 * 0) + 14 downto (32 * 0) + 11) <= C_PCIE3_PKT_TYPE_MEM_WR_D; --Req Type
                i_axi_rq_tdata((32 * 0) + 15) <= '0'; --Poisoned Request
                i_axi_rq_tdata((32 * 0) + 31 downto (32 * 0) + 16) <= (others => '0'); --Req ID

                i_axi_rq_tdata((32 * 1) +  7 downto (32 * 1) +  0) <= std_logic_vector(i_mem_tpl_tag(7 downto 0)); --Tag
                i_axi_rq_tdata((32 * 1) + 23 downto (32 * 1) +  8) <= p_in_completer_id; --Completer ID
                i_axi_rq_tdata((32 * 1) + 24) <= '0'; --Requester ID Enable
                i_axi_rq_tdata((32 * 1) + 27 downto (32 * 1) + 25) <= (others => '0');--Transaction Class (TC)
                i_axi_rq_tdata((32 * 1) + 28) <= '0'; --Attr (No Snoop)
                i_axi_rq_tdata((32 * 1) + 29) <= '0'; --Attr (Relaxed Ordering)
                i_axi_rq_tdata((32 * 1) + 30) <= '0'; --Attr (ID-Based Ordering)
                i_axi_rq_tdata((32 * 1) + 31) <= '0'; --Force ECRC

                i_mem_adr_byte <= i_mem_adr_byte + RESIZE(i_mem_tpl_byte, i_mem_adr_byte'length);

                i_mwr_work <= '1';

                i_fsm_txrq <= S_TXRQ_MWR_DN;

            end if;
        --end S_TXRQ_MWR_D1

        when S_TXRQ_MWR_DN =>

            if (i_urxbuf_rd = '1') then

                i_axi_rq_tvalid <= '1';

                i_axi_rq_tdata <= p_in_urxbuf_do;

                --Counter send data (current transaction)
                if (i_mem_tpl_cnt = (i_mem_tpl_len - 1)) then

                    i_mwr_work <= '0';

                    i_mem_tpl_tag <= i_mem_tpl_tag + 1;

                    i_mem_tpl_cnt <= (others => '0');

                    case (i_mem_tpl_dw_rem(1 downto 0)) is
                    when "01" => i_axi_rq_tkeep <= "01";--i_mem_tpl_dw_rem = 1
                    when "00" => i_axi_rq_tkeep <= "11";--i_mem_tpl_dw_rem = 0
                    when others => null;
                    end case;

                    i_axi_rq_tlast <= '1';

                    if (i_mem_tpl_last = '1') then
                      i_mem_tx_byte <= (others => '0');
                      i_mwr_done <= '1';

                    else
                      i_mem_tx_byte <= i_mem_tx_byte + RESIZE(i_mem_tpl_byte, i_mem_tx_byte'length);

                    end if;

                    i_fsm_txrq <= S_TXRQ_IDLE;

                else --if i_mem_tpl_cnt /= (i_mem_tpl_len - 1) then

                    i_mem_tpl_cnt <= i_mem_tpl_cnt + 1;

                    i_fsm_txrq <= S_TXRQ_MWR_DN;

                end if;

            elsif (p_in_urxbuf_empty = '1' and p_in_axi_rq_tready = '1') then

              i_axi_rq_tvalid <= '0';

            end if;
        --end S_TXRQ_MWR_DN
        --END: MWr , +data



        --#######################################################################
        --MRd, no data  (PC<-FPGA)
        --#######################################################################
        when S_TXRQ_MRD_C0 =>

          if (i_mem_tx_byte_remain > RESIZE(i_mem_tpl_max_byte, i_mem_tx_byte_remain'length)) then
              i_mem_tpl_last <= '0';
              i_mem_tpl_byte <= i_mem_tpl_max_byte;
          else
              i_mem_tpl_last <= '1';
              i_mem_tpl_byte <= i_mem_tx_byte_remain(i_mem_tpl_byte'range);
          end if;

          i_fsm_txrq <= S_TXRQ_MRD_N;
        --end S_TXRQ_MRD_C0 :

        when S_TXRQ_MRD_N =>

            if (p_in_axi_rq_tready = '1') then

                i_axi_rq_tkeep <= "11";

                i_axi_rq_tvalid <= '1';

                --First DW BE, Last DW BE - only for address divided 32 byte
                --1st DW Byte Enable (first_be)
                if (i_mem_tpl_dw = TO_UNSIGNED(16#01#, i_mem_tpl_dw'length)) then
                case (i_mem_tpl_byte(1 downto 0)) is
                when "00" => i_axi_rq_tuser(3 downto 0) <= "1111";
                when "01" => i_axi_rq_tuser(3 downto 0) <= "0001";
                when "10" => i_axi_rq_tuser(3 downto 0) <= "0011";
                when "11" => i_axi_rq_tuser(3 downto 0) <= "0111";
                when others => null;
                end case;
                else
                i_axi_rq_tuser(3 downto 0) <= "1111";
                end if;

                --Last DW Byte Enable (last_be)
                if (i_mem_tpl_dw = TO_UNSIGNED(16#01#, i_mem_tpl_dw'length)) then
                i_axi_rq_tuser(7 downto 4) <= "0000";
                else
                case (i_mem_tpl_byte(1 downto 0)) is
                when "00" => i_axi_rq_tuser(7 downto 4) <= "1111";
                when "01" => i_axi_rq_tuser(7 downto 4) <= "0001";
                when "10" => i_axi_rq_tuser(7 downto 4) <= "0011";
                when "11" => i_axi_rq_tuser(7 downto 4) <= "0111";
                when others => null;
                end case;
                end if;

--                i_axi_rq_tuser(10 downto 8) <= (others => '0');--addr_offset; ################  ????????????????  ##################
--                i_axi_rq_tuser(11) <= '0';--Discontinue;

                i_axi_rq_tdata((32 * 2) - 1 downto (32 * 0)) <= std_logic_vector(RESIZE(i_mem_adr_byte(31 downto 2), (32 * 2) - 2)) & "00";

                i_fsm_txrq <= S_TXRQ_MRD_N1;

            end if;

        when S_TXRQ_MRD_N1 =>

            if (p_in_axi_rq_tready = '1') then

                i_axi_rq_tdata((32 * 0) + 10 downto (32 * 0) +  0) <= std_logic_vector(i_mem_tpl_dw(10 downto 0)); --DW count
                i_axi_rq_tdata((32 * 0) + 14 downto (32 * 0) + 11) <= C_PCIE3_PKT_TYPE_MEM_RD_ND; --Req Type
                i_axi_rq_tdata((32 * 0) + 15) <= '0'; --Poisoned Request
                i_axi_rq_tdata((32 * 0) + 31 downto (32 * 0) + 16) <= (others => '0'); --Req ID

                i_axi_rq_tdata((32 * 1) +  7 downto (32 * 1) +  0) <= std_logic_vector(i_mem_tpl_tag(7 downto 0)); --Tag
                i_axi_rq_tdata((32 * 1) + 23 downto (32 * 1) +  8) <= p_in_completer_id; --Completer ID
                i_axi_rq_tdata((32 * 1) + 24) <= '0'; --Requester ID Enable
                i_axi_rq_tdata((32 * 1) + 27 downto (32 * 1) + 25) <= (others => '0');--Transaction Class (TC)
                i_axi_rq_tdata((32 * 1) + 28) <= '0'; --Attr (No Snoop)
                i_axi_rq_tdata((32 * 1) + 29) <= '0'; --Attr (Relaxed Ordering)
                i_axi_rq_tdata((32 * 1) + 30) <= '0'; --Attr (ID-Based Ordering)
                i_axi_rq_tdata((32 * 1) + 31) <= '0'; --Force ECRC

                i_axi_rq_tlast <= '1';

                i_mem_adr_byte <= i_mem_adr_byte + RESIZE(i_mem_tpl_byte, i_mem_adr_byte'length);

                i_mem_tpl_tag <= i_mem_tpl_tag + 1;

                if (i_mem_tpl_last = '1') then
                  i_mem_tx_byte <= (others => '0');
                  i_mrd_done <= '1';
                  i_fsm_txrq <= S_TXRQ_IDLE;
                else
                  i_mem_tx_byte <= i_mem_tx_byte + RESIZE(i_mem_tpl_byte, i_mem_tx_byte'length);
                  i_fsm_txrq <= S_TXRQ_CPLD_WAIT;
                end if;

            end if;
        --end S_TXRQ_MRD_N

        when S_TXRQ_CPLD_WAIT =>

          if (p_in_axi_rq_tready = '1') then

              i_axi_rq_tlast  <= '0';
              i_axi_rq_tvalid <= '0';

              i_mwr_work <= '0';
              i_mem_tpl_last <= '0';

              if (i_mem_tx_dw = UNSIGNED(p_in_dma_mrd_rxdwcount)) then
                i_fsm_txrq <= S_TXRQ_IDLE;
              end if;

          end if;

    end case; --case i_fsm_txrq is
  end if;--p_in_rst_n
end if;--p_in_clk
end process; --fsm

i_mem_tx_dw <= RESIZE(i_mem_tx_byte(i_mem_tx_byte'high downto log2(32 / 8)), i_mem_tx_dw'length)
                + (TO_UNSIGNED(0, i_mem_tx_dw'length - 2)
                    & OR_reduce(i_mem_tx_byte(log2(32 / 8) - 1 downto 0)));


--#######################################################################
--DBG
--#######################################################################
tst_fsm <= TO_UNSIGNED(8, tst_fsm'length) when i_fsm_txrq = S_TXRQ_CPLD_WAIT else
           TO_UNSIGNED(7, tst_fsm'length) when i_fsm_txrq = S_TXRQ_MRD_N     else
           TO_UNSIGNED(6, tst_fsm'length) when i_fsm_txrq = S_TXRQ_MRD_C0    else
           TO_UNSIGNED(4, tst_fsm'length) when i_fsm_txrq = S_TXRQ_MWR_DN    else
           TO_UNSIGNED(3, tst_fsm'length) when i_fsm_txrq = S_TXRQ_MWR_D0    else
           TO_UNSIGNED(2, tst_fsm'length) when i_fsm_txrq = S_TXRQ_MWR_C1    else
           TO_UNSIGNED(1, tst_fsm'length) when i_fsm_txrq = S_TXRQ_MWR_C0    else
           TO_UNSIGNED(0, tst_fsm'length);-- when i_fsm_txrq = S_TXRQ_IDLE else

p_out_tst(3 downto 0) <= std_logic_vector(tst_fsm);
p_out_tst(7 downto 4) <= (others => '0');

p_out_tst(8) <= i_axi_rq_tvalid;
p_out_tst(9) <= i_axi_rq_tlast;
p_out_tst(10) <= p_in_axi_rq_tready;
p_out_tst(266 downto 11)  <= std_logic_vector(RESIZE(UNSIGNED(i_axi_rq_tdata), 256));
p_out_tst(274 downto 267) <= std_logic_vector(RESIZE(UNSIGNED(i_axi_rq_tkeep), 8));
p_out_tst(279 downto 275) <= (others => '0');

end architecture behavioral;


