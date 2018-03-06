-------------------------------------------------------------------------
--Engineer    : Golovachenko Victor
--
--Create Date : 08.07.2015 13:35:52
--Module Name : pcie_tx_cc.vhd
--
--Description : Host <- UsrReg
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.pcie_pkg.all;

entity pcie_tx_cc is
generic (
G_DATA_WIDTH : integer := 64
);
port(
--AXI-S Completer Competion Interface
p_out_axi_cc_tdata  : out std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_axi_cc_tkeep  : out std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_out_axi_cc_tlast  : out std_logic;
p_out_axi_cc_tvalid : out std_logic;
p_out_axi_cc_tuser  : out std_logic_vector(32 downto 0);
p_in_axi_cc_tready  : in  std_logic;

--TX Message Interface
p_in_cfg_msg_transmit_done  : in  std_logic;
p_out_cfg_msg_transmit      : out std_logic;
p_out_cfg_msg_transmit_type : out std_logic_vector(2 downto 0);
p_out_cfg_msg_transmit_data : out std_logic_vector(31 downto 0);

--Tag availability and Flow control Information
p_in_pcie_rq_tag          : in  std_logic_vector(5 downto 0);
p_in_pcie_rq_tag_vld      : in  std_logic;
p_in_pcie_tfc_nph_av      : in  std_logic_vector(1 downto 0);
p_in_pcie_tfc_npd_av      : in  std_logic_vector(1 downto 0);
p_in_pcie_tfc_np_pl_empty : in  std_logic;
p_in_pcie_rq_seq_num      : in  std_logic_vector(3 downto 0);
p_in_pcie_rq_seq_num_vld  : in  std_logic;

--Completion
p_in_req_compl    : in  std_logic;
p_in_req_compl_ur : in  std_logic;
p_out_compl_done  : out std_logic;
p_in_dma_tlp_work : in  std_logic;

p_in_req_prm      : in TPCIE_reqprm;

p_in_completer_id : in  std_logic_vector(15 downto 0);

--usr app
p_in_ureg_do : in  std_logic_vector(31 downto 0);

--DBG
p_out_tst : out std_logic_vector(279 downto 0);

--system
p_in_clk   : in  std_logic;
p_in_rst_n : in  std_logic
);
end entity pcie_tx_cc;

architecture behavioral of pcie_tx_cc is

type TFsmTx_state is (
S_TXCC_IDLE,
S_TXCC_DONE,
S_TXCC_DONE2
);
signal i_fsm_txcc       : TFsmTx_state;

signal i_axi_cc_tdata   : std_logic_vector(127 downto 0);
signal i_axi_cc_tkeep   : std_logic_vector(3 downto 0);
signal i_axi_cc_tlast   : std_logic;
signal i_axi_cc_tvalid  : std_logic;

signal i_compl_done     : std_logic;

type TReq is record
pkt  : std_logic_vector(3 downto 0);
tc   : std_logic_vector(2 downto 0);
attr : std_logic_vector(2 downto 0);
len  : std_logic_vector(10 downto 0);
rid  : std_logic_vector(15 downto 0);
tag  : std_logic_vector(7 downto 0);
addr : std_logic_vector(12 downto 0);
at   : std_logic_vector(1 downto 0);
end record;

signal i_req            : TReq;

signal i_req_be         : std_logic_vector(7 downto 0);

signal i_lower_addr     : std_logic_vector(6 downto 0);

signal sr_req_compl     : std_logic_vector(0 to 1);

signal tst_fsm_tx       : std_logic;



begin --architecture behavioral of pcie_tx_cc

p_out_compl_done <= i_compl_done;

--AXI-S Completer Competion Interface
p_out_axi_cc_tdata  <= std_logic_vector(RESIZE(UNSIGNED(i_axi_cc_tdata), p_out_axi_cc_tdata'length));
p_out_axi_cc_tkeep  <= std_logic_vector(RESIZE(UNSIGNED(i_axi_cc_tkeep), p_out_axi_cc_tkeep'length));
p_out_axi_cc_tlast  <= i_axi_cc_tlast ;
p_out_axi_cc_tvalid <= i_axi_cc_tvalid;
p_out_axi_cc_tuser  <= (others => '0');

--TX Message Interface
p_out_cfg_msg_transmit      <= '0';
p_out_cfg_msg_transmit_type <= (others => '0');
p_out_cfg_msg_transmit_data <= (others => '0');

--p_out_cfg_fc_sel <= (others => '0');

i_req.attr <= p_in_req_prm.desc(3)(30 downto 28);
i_req.tc   <= p_in_req_prm.desc(3)(27 downto 25);
i_req.tag  <= p_in_req_prm.desc(3)( 7 downto  0);
i_req.rid  <= p_in_req_prm.desc(2)(31 downto 16);
i_req.pkt  <= p_in_req_prm.desc(2)(14 downto 11);
i_req.len  <= p_in_req_prm.desc(2)(10 downto  0);
i_req.addr <= p_in_req_prm.desc(0)(12 downto  2) & "00";
i_req.at   <= p_in_req_prm.desc(0)( 1 downto  0);

i_req_be  <= p_in_req_prm.last_be & p_in_req_prm.first_be;

--Calculate lower address based on  byte enable
process (i_req_be, i_req.addr)
begin
  case (i_req_be(3 downto 0)) is
    when "0000" =>
      i_lower_addr <= (i_req.addr(6 downto 2) & "00");
    when "0001" | "0011" | "0101" | "0111" | "1001" | "1011" | "1101" | "1111" =>
      i_lower_addr <= (i_req.addr(6 downto 2) & "00");
    when "0010" | "0110" | "1010" | "1110" =>
      i_lower_addr <= (i_req.addr(6 downto 2) & "01");
    when "0100" | "1100" =>
      i_lower_addr <= (i_req.addr(6 downto 2) & "10");
    when "1000" =>
      i_lower_addr <= (i_req.addr(6 downto 2) & "11");
    when others =>
      i_lower_addr <= (i_req.addr(6 downto 2) & "00");
  end case;
end process;


process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0') then
    sr_req_compl <= (others => '0');
  else
    sr_req_compl <= p_in_req_compl & sr_req_compl(0 to 0);
  end if;
end if;
end process;


--Tx State Machine
fsm : process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0') then

    i_fsm_txcc <= S_TXCC_IDLE;

    i_axi_cc_tdata  <= (others => '0');
    i_axi_cc_tkeep  <= (others => '0');
    i_axi_cc_tlast  <= '0';
    i_axi_cc_tvalid <= '0';

    i_compl_done <= '0';

  else

    case i_fsm_txcc is

        --#######################################################################
        --
        --#######################################################################
        when S_TXCC_IDLE =>

        if (p_in_dma_tlp_work = '0') then

          if (sr_req_compl(sr_req_compl'high) = '1' and p_in_axi_cc_tready = '1') then

            i_axi_cc_tlast  <= '1';

            i_axi_cc_tvalid <= '1';

            if (   (i_req.pkt = C_PCIE3_PKT_TYPE_MEM_RD_ND)
                or (i_req.pkt = C_PCIE3_PKT_TYPE_MEM_LK_RD_ND)
                or (i_req.pkt = C_PCIE3_PKT_TYPE_IO_RD_ND) ) then

              i_axi_cc_tdata((32 * 4) - 1 downto (32 * 3)) <= p_in_ureg_do;
              i_axi_cc_tkeep <= "1111";

            else

              i_axi_cc_tkeep <= "0111";

            end if;

            i_axi_cc_tdata((32 * 2) + 31)                      <= '0';       -- Force ECRC
            i_axi_cc_tdata((32 * 2) + 30 downto (32 * 2) + 28) <= std_logic_vector(RESIZE(UNSIGNED(i_req.attr), 3));
            i_axi_cc_tdata((32 * 2) + 27 downto (32 * 2) + 25) <= i_req.tc;  --
            i_axi_cc_tdata((32 * 2) + 24)                      <= '0';       --Completer ID to control selection of Client Supplied Bus number
            i_axi_cc_tdata((32 * 2) + 23 downto (32 * 2) + 16) <= p_in_completer_id(15 downto 8); --Completer Bus number - selected if Compl ID = 1
            i_axi_cc_tdata((32 * 2) + 15 downto (32 * 2) +  8) <= p_in_completer_id(7 downto 0);  --Compl Dev / Func no - sel if Compl ID = 1
            i_axi_cc_tdata((32 * 2) +  7 downto (32 * 2) +  0) <= i_req.tag; --Matching Request Tag

            i_axi_cc_tdata((32 * 1) + 31 downto (32 * 1) + 16) <= i_req.rid; --Requester ID - 16 bits
            i_axi_cc_tdata((32 * 1) + 15)                      <= '0';       --Rsvd
            i_axi_cc_tdata((32 * 1) + 14)                      <= '0';       --Posioned completion
            i_axi_cc_tdata((32 * 1) + 13 downto (32 * 1) + 11) <= C_PCIE_COMPL_STATUS_SC; --Completion Status: SuccessFull completion

            if ( (i_req.pkt = C_PCIE3_PKT_TYPE_IO_RD_ND) or
                ((i_req.pkt = C_PCIE3_PKT_TYPE_MEM_RD_ND) and (i_req.len = (i_req.len'range => '0'))) ) then

              i_axi_cc_tdata((32 * 1) + 10 downto (32 * 1) + 0) <= std_logic_vector(TO_UNSIGNED(1, 11)); --DWord Count

            elsif (i_req.pkt = C_PCIE3_PKT_TYPE_IO_WR_D) then
              i_axi_cc_tdata((32 * 1) + 10 downto (32 * 1) + 0) <= (others => '0'); --DWord Count

            else
              i_axi_cc_tdata((32 * 1) + 10 downto (32 * 1) + 0) <= i_req.len; --DWord Count

            end if;

            i_axi_cc_tdata((32 * 0) + 31 downto (32 * 0) + 30) <= (others => '0');        --Rsvd
            i_axi_cc_tdata((32 * 0) + 29)                      <= '0';                    --Locked Read Completion
            i_axi_cc_tdata((32 * 0) + 28 downto (32 * 0) + 16) <= std_logic_vector(TO_UNSIGNED(4, 13)); --Byte Count
            i_axi_cc_tdata((32 * 0) + 15 downto (32 * 0) + 10) <= (others => '0');        --Rsvd
            i_axi_cc_tdata((32 * 0) +  9 downto (32 * 0) +  8) <= i_req.at;               --Adress Type - 2 bits
            i_axi_cc_tdata((32 * 0) +  7)                      <= '0';                    --Rsvd

            if ((i_req.pkt = C_PCIE3_PKT_TYPE_MEM_RD_ND) or (i_req.pkt = C_PCIE3_PKT_TYPE_MEM_LK_RD_ND)) then
              i_axi_cc_tdata((32 * 0) +  6 downto (32 * 0) +  0) <= i_lower_addr;
            else
              i_axi_cc_tdata((32 * 0) +  6 downto (32 * 0) +  0) <= (others => '0');
            end if;

            i_compl_done <= '1';
            i_fsm_txcc <= S_TXCC_DONE;

          end if;

        end if; --if (p_in_dma_tlp_work = '0') then

        when S_TXCC_DONE =>

          if (p_in_axi_cc_tready = '1') then

            i_axi_cc_tlast  <= '0';
            i_axi_cc_tvalid <= '0';

            i_fsm_txcc <= S_TXCC_DONE2;

          end if;

        when S_TXCC_DONE2 =>

          if (sr_req_compl(sr_req_compl'high) = '0') then
            i_compl_done <= '0';
            i_fsm_txcc <= S_TXCC_IDLE;
          end if;

    end case; --case i_fsm_txcc is
  end if;--p_in_rst_n
end if;--p_in_clk
end process; --fsm


--#######################################################################
--DBG
--#######################################################################
--tst_fsm_tx <= '1' when i_fsm_txcc = S_TXCC_CPL  else '0';

p_out_tst(0) <= '0';--tst_fsm_tx;
p_out_tst(3 downto 1) <= (others => '0');
p_out_tst(7 downto 4) <= (others => '0');

p_out_tst(8) <= i_axi_cc_tvalid;
p_out_tst(9) <= i_axi_cc_tlast;
p_out_tst(10) <= p_in_axi_cc_tready;
p_out_tst(266 downto 11)  <= std_logic_vector(RESIZE(UNSIGNED(i_axi_cc_tdata), 256));
p_out_tst(274 downto 267) <= std_logic_vector(RESIZE(UNSIGNED(i_axi_cc_tkeep), 8));
p_out_tst(279 downto 275) <= (others => '0');

end architecture behavioral;


