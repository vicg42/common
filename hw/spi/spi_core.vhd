-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 18.06.2014 13:55:15
-- Module Name : spi_core
--
-- Назначение/Описание :
--   Adr Reg = p_in_adr & p_in_dir;
--   TxD (FPGA -> DEV)  --shift MSB first
--   RxD (FPGA <- DEV)  --recieve MSB first
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.spi_pkg.all;
use work.vicg_common_pkg.all;
use work.reduce_pack.all;

entity spi_core is
generic(
G_AWIDTH : integer := 16;
G_DWIDTH : integer := 16
);
port(
p_in_adr    : in   std_logic_vector(G_AWIDTH - 1 downto 0);
p_in_data   : in   std_logic_vector(G_DWIDTH - 1 downto 0); --FPGA -> DEV
p_out_data  : out  std_logic_vector(G_DWIDTH - 1 downto 0); --FPGA <- DEV
p_in_dir    : in   std_logic;
p_in_start  : in   std_logic;

p_out_busy  : out  std_logic;

p_out_physpi : out TSPI_pinout;
p_in_physpi  : in  TSPI_pinin;

p_out_tst    : out std_logic_vector(31 downto 0);
p_in_tst     : in  std_logic_vector(31 downto 0);

p_in_clk_en : in   std_logic;
p_in_clk    : in   std_logic;
p_in_rst    : in   std_logic
);
end;

architecture behavior of spi_core is

type TFsm_spi is (
S_IDLE,
S_IDLE2,
S_TX_ADR,
S_TX_D,
S_RX_D,
S_DONE,
S_DONE2
);

signal i_fsm_core_cs : TFsm_spi;

signal i_busy       : std_logic := '0';
signal i_sck        : std_logic := '0';
signal i_ss_n       : std_logic := '0';
signal i_rxd        : std_logic_vector(max2(G_AWIDTH, G_DWIDTH) - 1 downto 0) := (others=>'0');
signal sr_reg       : std_logic_vector(max2(G_AWIDTH, G_DWIDTH) - 1 downto 0) := (others=>'0');
signal i_bitcnt     : unsigned(log2(sr_reg'length) - 1 downto 0) := (others=>'0');

signal tst_fsmstate,tst_fsmstate_dly : std_logic_vector(2 downto 0) := (others => '0');
signal i_sck_out : std_logic;
signal i_mosi_out : std_logic := '0';
signal tst_mosi    : std_logic;
signal tst_sck_out : std_logic;

--MAIN
begin

p_out_tst(0) <= '1' when i_fsm_core_cs = S_RX_D else '0';
p_out_tst(1) <= OR_reduce(tst_fsmstate_dly) or tst_mosi or tst_sck_out;

p_out_busy <= i_busy;
p_out_data <= i_rxd;

--p_out_physpi.sck <= i_sck when i_fsm_core_cs = S_TX_ADR
--                               or i_fsm_core_cs = S_TX_D
--                                or i_fsm_core_cs = S_RX_D else '0';
--p_out_physpi.ss_n <= i_ss_n;
--p_out_physpi.mosi <= sr_reg(G_AWIDTH - 1) when i_fsm_core_cs = S_TX_ADR else
--                      sr_reg(G_DWIDTH - 1) when i_fsm_core_cs = S_TX_D else
--                      'Z';

p_out_physpi.ss_n <= i_ss_n;
p_out_physpi.mosi <= i_mosi_out when i_fsm_core_cs = S_TX_ADR or i_fsm_core_cs = S_TX_D else 'Z';
p_out_physpi.sck <= i_sck_out;

i_sck_out <= i_sck when i_fsm_core_cs = S_TX_ADR
                          or i_fsm_core_cs = S_TX_D
                            or i_fsm_core_cs = S_RX_D else '0';

--txd: MSB
i_mosi_out <= sr_reg(G_AWIDTH - 1) when i_fsm_core_cs = S_TX_ADR else
              sr_reg(G_DWIDTH - 1) when i_fsm_core_cs = S_TX_D else
              '0';
--txd: LSB
--i_mosi_out <= sr_reg(0);

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_clk_en = '1' and i_busy = '1' then
      i_sck <= not i_sck;
    end if;
  end if;
end process;

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      i_fsm_core_cs <= S_IDLE;
      i_bitcnt <= (others => '0');
      sr_reg <= (others => '0');
      i_busy <= '0';
      i_ss_n <= '1';
      i_rxd <= (others => '0');

    else

        case i_fsm_core_cs is

          when S_IDLE =>

            if p_in_clk_en = '1' then
              if p_in_start = '1' then
                i_busy <= '1';
                i_ss_n <= '0';
                i_fsm_core_cs <= S_IDLE2;
              else
                i_ss_n <= '1';
                i_busy <= '0';
              end if;
            end if;

          when S_IDLE2 =>

            if p_in_clk_en = '1' and i_sck = '1' then
                sr_reg <= std_logic_vector(RESIZE(UNSIGNED(p_in_adr), sr_reg'length));
                i_ss_n <= '0';
                i_fsm_core_cs <= S_TX_ADR;
            end if;

          when S_TX_ADR =>

            if p_in_clk_en = '1' and i_sck = '1' then
              if i_bitcnt = TO_UNSIGNED(G_AWIDTH - 1, i_bitcnt'length) then
                sr_reg <= p_in_data;
                i_bitcnt <= (others => '0');
                if p_in_dir = C_SPI_WRITE then
                  i_fsm_core_cs <= S_TX_D;
                else
                  i_fsm_core_cs <= S_RX_D;
                end if;
              else
--                sr_reg <= '0' & sr_reg(sr_reg'length - 1 downto 1); --txd: LSB first
                sr_reg <= sr_reg(sr_reg'length - 2 downto 0) & '0'; --txd: MSB first
                i_bitcnt <= i_bitcnt + 1;
              end if;
            end if;

          when S_TX_D =>

            if p_in_clk_en = '1' and i_sck = '1' then
              if i_bitcnt = TO_UNSIGNED(G_DWIDTH - 1, i_bitcnt'length) then
                i_bitcnt <= (others => '0');
                i_fsm_core_cs <= S_DONE;
              else
--                sr_reg <= '0' & sr_reg(sr_reg'length - 1 downto 1); --txd: LSB first
                sr_reg <= sr_reg(sr_reg'length - 2 downto 0) & '0'; --txd: MSB first
                i_bitcnt <= i_bitcnt + 1;
              end if;
            end if;

          when S_RX_D =>

            if p_in_clk_en = '1' and i_sck = '1' then
              if i_bitcnt = TO_UNSIGNED(G_DWIDTH - 1, i_bitcnt'length) then
                i_bitcnt <= (others => '0');
                i_fsm_core_cs <= S_DONE;
              else
                i_bitcnt <= i_bitcnt + 1;
              end if;

--              sr_reg <= p_in_physpi.miso & sr_reg(sr_reg'length - 1 downto 0); --rxd: LSB first
              sr_reg <= sr_reg(sr_reg'length - 2 downto 0) & p_in_physpi.miso; --rxd: MSB first
            end if;

          when S_DONE =>

            if p_in_clk_en = '1' and i_sck = '1' then
                i_rxd <= sr_reg;
                i_fsm_core_cs <= S_DONE2;
            end if;

          when S_DONE2 =>

            if p_in_clk_en = '1' and i_sck = '1' then
              i_ss_n <= '1';
              if i_bitcnt = TO_UNSIGNED(2 - 1, i_bitcnt'length) then
                i_busy <= '0';
                i_bitcnt <= (others => '0');
                i_fsm_core_cs <= S_IDLE;
              else
                i_bitcnt <= i_bitcnt + 1;
              end if;
            end if;

        end case;

    end if;
  end if;
end process;


process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    tst_fsmstate_dly <= tst_fsmstate;
    tst_mosi    <= i_mosi_out;
    tst_sck_out <= i_sck_out;
  end if;
end process;


tst_fsmstate <= std_logic_vector(TO_UNSIGNED(16#06#,tst_fsmstate'length)) when i_fsm_core_cs = S_DONE2  else
                std_logic_vector(TO_UNSIGNED(16#05#,tst_fsmstate'length)) when i_fsm_core_cs = S_DONE   else
                std_logic_vector(TO_UNSIGNED(16#04#,tst_fsmstate'length)) when i_fsm_core_cs = S_RX_D   else
                std_logic_vector(TO_UNSIGNED(16#03#,tst_fsmstate'length)) when i_fsm_core_cs = S_TX_D   else
                std_logic_vector(TO_UNSIGNED(16#02#,tst_fsmstate'length)) when i_fsm_core_cs = S_TX_ADR else
                std_logic_vector(TO_UNSIGNED(16#01#,tst_fsmstate'length)) when i_fsm_core_cs = S_IDLE2  else
                std_logic_vector(TO_UNSIGNED(16#00#,tst_fsmstate'length)); --i_fsm_core_cs = S_IDLE      else


--END MAIN
end architecture;
