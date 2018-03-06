-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 23.07.2015 11:20:31
-- Module Name : pcie_rx_rc.vhd
--
-- Description : DMA: Host -> FPGA (MemRd CplD)
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.pcie_pkg.all;

entity pcie_rx_rc is
generic (
G_DATA_WIDTH : integer := 64
);
port(
-- Requester Completion Interface
p_in_axi_rc_tdata   : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_in_axi_rc_tlast   : in  std_logic;
p_in_axi_rc_tvalid  : in  std_logic;
p_in_axi_rc_tkeep   : in  std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_in_axi_rc_tuser   : in  std_logic_vector(74 downto 0);
p_out_axi_rc_tready : out std_logic;

--Completion
p_in_dma_init      : in  std_logic;
p_in_dma_prm       : in  TPCIE_dmaprm;
p_in_dma_mrd_en    : in  std_logic;
p_out_dma_mrd_done : out std_logic;
p_out_dma_mrd_rxdwcount : out std_logic_vector(31 downto 0);

--usr app
--p_out_utxbuf_be   : out  std_logic_vector((G_DATA_WIDTH / 32) - 1 downto 0);
p_out_utxbuf_di   : out  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
p_out_utxbuf_wr   : out  std_logic;
p_out_utxbuf_last : out  std_logic;
p_in_utxbuf_full  : in   std_logic;

--DBG
p_out_tst : out std_logic_vector(31 downto 0);

--system
p_in_clk   : in  std_logic;
p_in_rst_n : in  std_logic
);
end entity pcie_rx_rc;

architecture behavioral of pcie_rx_rc is

type TFsmRx_state is (
S_RXRC_IDLE,
S_RXRC_DH,
S_RXRC_DN,
S_RXRC_DE,
S_RXRC_CHKE,
S_RXRC_ERR
);
signal i_fsm_rxrc         : TFsmRx_state;

signal i_sof              : std_logic_vector(1 downto 0);

signal i_dma_init         : std_logic;
signal i_dma_dw_cnt       : unsigned(31 downto 0);
signal i_dma_dw_len       : unsigned(31 downto 0);

signal i_mrd_done         : std_logic;

signal i_cpld_tlp_de      : std_logic;
signal i_cpld_tlp_work    : std_logic;
signal i_cpld_tpl_cntdw   : unsigned(10 downto 0);

signal i_axi_rc_tready    : std_logic;
--signal i_axi_data_be      : std_logic_vector((G_DATA_WIDTH / 8) - 1 downto 0);

type TByteEn is array (0 to (G_DATA_WIDTH / 8) - 1) of std_logic_vector(3 downto 0);
signal sr_axi_be          : TByteEn;
type TData is array (0 to (G_DATA_WIDTH / 32) - 1) of std_logic_vector(31 downto 0);
signal sr_axi_data        : TData;
signal i_axi_data         : TData;
signal i_utxbuf_di        : TData;
signal i_utxbuf_wr        : std_logic := '0';
signal i_err_detect       : std_logic;
signal i_err              : std_logic_vector(6 downto 0);
signal tst_fsm            : unsigned(2 downto 0);


begin --architecture behavioral of pcie_rx_rc


gen : for i in 0 to (G_DATA_WIDTH / 32) - 1 generate begin
i_axi_data(i) <= p_in_axi_rc_tdata((32 * (i + 1)) - 1 downto (32 * i));
end generate;

--process(p_in_clk)
--begin
--if rising_edge(p_in_clk) then
--i_utxbuf_di(0) <= sr_axi_data(3);
--i_utxbuf_di(1) <= i_axi_data(0);
--i_utxbuf_di(2) <= i_axi_data(1);
--i_utxbuf_di(3) <= i_axi_data(2);
--
--if (i_fsm_rxrc = S_RXRC_DE) then
--i_utxbuf_wr <= i_cpld_tlp_work and (not p_in_utxbuf_full);
--else
--i_utxbuf_wr <= i_cpld_tlp_work and (not p_in_utxbuf_full) and p_in_axi_rc_tvalid;
--end if;
--end if;
--end process;
--
--gen_utxbuf : for i in 0 to i_utxbuf_di'length - 1 generate begin
--p_out_utxbuf_di((32 * (i + 1)) - 1 downto (32 * i)) <= i_utxbuf_di(i);
--end generate gen_utxbuf;

i_utxbuf_wr <= i_cpld_tlp_work and (not p_in_utxbuf_full) and (p_in_axi_rc_tvalid or i_cpld_tlp_de);

i_utxbuf_di(0) <= sr_axi_data(3);
i_utxbuf_di(1) <= i_axi_data(0);
i_utxbuf_di(2) <= i_axi_data(1);
i_utxbuf_di(3) <= i_axi_data(2);

gen_utxbuf : for i in 0 to i_utxbuf_di'length - 1 generate begin
p_out_utxbuf_di((32 * (i + 1)) - 1 downto (32 * i)) <= i_utxbuf_di(i);
end generate gen_utxbuf;

--p_out_utxbuf_be <=
p_out_utxbuf_wr   <= i_utxbuf_wr;
p_out_utxbuf_last <= '0';

p_out_dma_mrd_done <= i_mrd_done;

p_out_dma_mrd_rxdwcount <= std_logic_vector(i_dma_dw_cnt);

p_out_axi_rc_tready <= i_axi_rc_tready and not p_in_utxbuf_full;

--i_axi_data_be <= p_in_axi_rc_tuser((G_DATA_WIDTH / 8 ) - 1 downto 0);

i_sof(0) <= p_in_axi_rc_tuser(32);
i_sof(1) <= p_in_axi_rc_tuser(33);
--i_eof_0 <= p_in_axi_rc_tuser(37 downto 34);
--i_eof_1 <= p_in_axi_rc_tuser(41 downto 38);

--i_disc <= p_in_axi_rc_tuser(42);


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
        if (i_fsm_rxrc = S_RXRC_DH) then
          i_dma_init <= '0';
        end if;
    end if;
  end if;
end if;
end process;--init


--Rx State Machine
fsm : process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0') then

    i_fsm_rxrc <= S_RXRC_IDLE;

    for i in 0 to sr_axi_data'length - 1 loop
    sr_axi_data(i) <= (others => '0');
    end loop;
    for i in 0 to sr_axi_be'length - 1 loop
    sr_axi_be(i) <= (others => '0');
    end loop;

    i_axi_rc_tready <= '0';

    i_cpld_tlp_work <= '0';
    i_cpld_tlp_de <= '0';

    i_cpld_tpl_cntdw <= (others => '0');

    i_dma_dw_cnt <= (others => '0');
    i_dma_dw_len <= (others => '0');

    i_mrd_done <= '0';

    i_err <= (others => '0');
    i_err_detect <= '0';

  else

    case i_fsm_rxrc is

        when S_RXRC_IDLE =>

            i_cpld_tlp_work <= '0';

            if (p_in_dma_mrd_en = '1' and i_mrd_done = '0' and p_in_utxbuf_full = '0') then

              i_cpld_tpl_cntdw <= (others => '0');

              if (i_dma_init = '1') then

              i_dma_dw_cnt <= (others => '0');
              i_dma_dw_len <= RESIZE(UNSIGNED(p_in_dma_prm.len(p_in_dma_prm.len'high downto log2(32 / 8)))
                                                                                        , i_dma_dw_len'length)
                              + (TO_UNSIGNED(0, i_dma_dw_len'length - 2)
                                  & OR_reduce(p_in_dma_prm.len(log2(32 / 8) - 1 downto 0)));

              end if;

              i_axi_rc_tready <= '1';
              i_fsm_rxrc <= S_RXRC_DH;

            else
              if (i_dma_init = '1') then
                i_mrd_done <= '0';
              end if;
            end if;

        --#######################################################################
        --Detect start of packet
        --#######################################################################
        when S_RXRC_DH =>

            if (i_sof(0) = '1' and i_sof(1) = '0' and p_in_axi_rc_tvalid = '1') then

                if (p_in_axi_rc_tkeep(2 downto 0) = "111") then

                    for i in 3 to sr_axi_data'length - 1 loop
                    sr_axi_data(i) <= i_axi_data(i); --user data
                    sr_axi_be(i) <= p_in_axi_rc_tuser((i * 4) + 3 downto (i * 4)); --(15...12)
                    end loop;

                    i_err(3 downto 0) <= i_axi_data(0)(15 downto 12);
                    i_err(6 downto 4) <= i_axi_data(1)(13 downto 11);

                    --Check Completion Status
                    if ((i_axi_data(1)(13 downto 11) = C_PCIE_COMPL_STATUS_SC)
                      and (i_axi_data(0)(15 downto 12) = C_PCIE3_COMPL_ERR_CODE_OK)) then

                        i_cpld_tlp_work <= '1';

                        i_cpld_tpl_cntdw <= i_cpld_tpl_cntdw + 1;

                        if (p_in_axi_rc_tlast = '1') then

                            i_axi_rc_tready <= '0';

                            i_cpld_tlp_de <= '1';
                            i_fsm_rxrc <= S_RXRC_DE;

                        else

                            i_fsm_rxrc <= S_RXRC_DN;

                        end if;

                    else
                      --Check Error Code
                        i_axi_rc_tready <= '0';

                        i_fsm_rxrc <= S_RXRC_ERR;

                    end if;

                end if;

            end if;


        --#######################################################################
        --
        --#######################################################################
        when S_RXRC_DN =>

            if (p_in_axi_rc_tvalid = '1' and p_in_utxbuf_full = '0') then

                for i in 0 to i_axi_data'length - 1 loop
                sr_axi_data(i) <= i_axi_data(i); --user data
                sr_axi_be(i) <= p_in_axi_rc_tuser((i * 4) + 3 downto (i * 4));
                end loop;

                if (p_in_axi_rc_tkeep = "1111") then
                  i_cpld_tpl_cntdw <= i_cpld_tpl_cntdw + 4;
                elsif (p_in_axi_rc_tkeep = "0111") then
                  i_cpld_tpl_cntdw <= i_cpld_tpl_cntdw + 3;
                elsif (p_in_axi_rc_tkeep = "0011") then
                  i_cpld_tpl_cntdw <= i_cpld_tpl_cntdw + 2;
                else
                  i_cpld_tpl_cntdw <= i_cpld_tpl_cntdw + 1;
                end if;

                if (p_in_axi_rc_tlast = '1') then

                    i_axi_rc_tready <= '0';

                    if (p_in_axi_rc_tkeep = "1111") then

                      i_cpld_tlp_de <= '1';
                      i_fsm_rxrc <= S_RXRC_DE;

                    else

                      i_cpld_tlp_work <= '0';
                      i_fsm_rxrc <= S_RXRC_CHKE;

                    end if;
                end if;

            end if;


        --#######################################################################
        --Check End DMA
        --#######################################################################
        when S_RXRC_DE =>

            if (p_in_utxbuf_full = '0') then

                i_cpld_tlp_work <= '0';

                if ((i_dma_dw_cnt + RESIZE(i_cpld_tpl_cntdw, i_dma_dw_cnt'length)) = i_dma_dw_len) then
                  i_mrd_done <= '1';
                end if;

                i_dma_dw_cnt <= i_dma_dw_cnt + RESIZE(i_cpld_tpl_cntdw, i_dma_dw_cnt'length);

                i_cpld_tlp_de <= '0';
                i_fsm_rxrc <= S_RXRC_IDLE;

            end if;

        when S_RXRC_CHKE =>

            i_cpld_tlp_work <= '0';

            if ((i_dma_dw_cnt + RESIZE(i_cpld_tpl_cntdw, i_dma_dw_cnt'length)) = i_dma_dw_len) then
              i_mrd_done <= '1';
            end if;

            i_dma_dw_cnt <= i_dma_dw_cnt + RESIZE(i_cpld_tpl_cntdw, i_dma_dw_cnt'length);

            i_fsm_rxrc <= S_RXRC_IDLE;


        --#######################################################################
        --Check ERR
        --#######################################################################
        when S_RXRC_ERR =>

            i_axi_rc_tready <= '1';

            i_err_detect <= '1';

            i_fsm_rxrc <= S_RXRC_IDLE;

    end case; --case i_fsm_rxrc is

  end if;--p_in_rst_n
end if;--p_in_clk
end process; --fsm



--#######################################################################
--DBG
--#######################################################################
tst_fsm <= TO_UNSIGNED(5, tst_fsm'length) when i_fsm_rxrc = S_RXRC_ERR  else
           TO_UNSIGNED(4, tst_fsm'length) when i_fsm_rxrc = S_RXRC_CHKE else
           TO_UNSIGNED(3, tst_fsm'length) when i_fsm_rxrc = S_RXRC_DE   else
           TO_UNSIGNED(2, tst_fsm'length) when i_fsm_rxrc = S_RXRC_DN   else
           TO_UNSIGNED(1, tst_fsm'length) when i_fsm_rxrc = S_RXRC_DH   else
           TO_UNSIGNED(0, tst_fsm'length);-- when i_fsm_rxrc = S_RXRC_IDLE else

p_out_tst(2 downto 0) <= std_logic_vector(tst_fsm);
p_out_tst(9 downto 3) <= i_err;
p_out_tst(10) <= i_err_detect;
p_out_tst(31 downto 11) <= (others => '0');


end architecture behavioral;
