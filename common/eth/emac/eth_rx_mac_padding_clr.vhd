-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 15/04/2010
-- Module Name : eth_rx_mac_padding_clr
--
-- Ќазначение/ќписание : ћодуль транслирует данные из Upstream Port в Downstream Port +
--                       обрезает выходной поток данных в зависимости от установок на порту p_in_usr_pattern_size
--                       p_in_usr_pattern_size=0 - bypass
--                       p_in_usr_pattern_size/=0 - кол-во байт которые нужно удалить из входного потока (Upstream Port)
--                                                  (1 бай удалени€ синхронизирован sof)
--
--                       ”дал€емые данные:это могут быть адреса MAC dst/src или чтото другое
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.eth_pkg.all;
use work.prj_def.all;

library unisim;
use unisim.vcomponents.all;

entity eth_rx_mac_padding_clr is
port
(
--//--------------------------
--//ѕользовательское управление
--//--------------------------
p_in_usr_ctrl          : in  std_logic_vector(15 downto 0);

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data          : in  std_logic_vector(7 downto 0); -- Input data
p_in_upp_sof_n         : in  std_logic; -- Input start of frame
p_in_upp_eof_n         : in  std_logic; -- Input end of frame
p_in_upp_src_rdy_n     : in  std_logic; -- Input source ready
p_out_upp_dst_rdy_n    : out std_logic;  -- Output destination ready

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data        : out std_logic_vector(7 downto 0); -- Modified output data
p_out_dwnp_sof_n       : out std_logic; -- Output start of frame
p_out_dwnp_eof_n       : out std_logic; -- Output end of frame
p_out_dwnp_src_rdy_n   : out std_logic; -- Output source ready
p_in_dwnp_dst_rdy_n    : in  std_logic;  -- Input destination ready

--//--------------------------
--//System
--//--------------------------
p_in_clk               : in  std_logic; -- Input CLK from TRIMAC Reciever
p_in_rst               : in  std_logic -- Synchronous reset signal
);

end eth_rx_mac_padding_clr;

architecture arch1 of eth_rx_mac_padding_clr is

--Signal declarations
signal enable                    : std_logic;

type fsm_state is
(
  S_IDLE,
  S_MAC_ADR,
  S_LENGTH,
  S_DATA,
  S_EOF
);
signal fsm_state_cs: fsm_state;


-- Small delay for simulation purposes.
constant dly : time := 1 ps;

signal i_cntbyte                  : std_logic_vector(15 downto 0);
signal i_len_msb                  : std_logic;
signal i_eof                      : std_logic;

signal dwnp_data_out              : std_logic_vector(7 downto 0);
signal dwnp_sof_out               : std_logic;
signal dwnp_eof_out               : std_logic;
signal dwnp_eof_usr_out           : std_logic;
signal dwnp_src_rdy_usr_out       : std_logic;
signal dwnp_src_rdy_out           : std_logic;


signal i_mac_padding_clr_disable  : std_logic;
signal i_byte_swap                : std_logic;

--//MAIN
begin  -- arch1

i_mac_padding_clr_disable <=p_in_usr_ctrl(C_DSN_ETHG_REG_MAC_RX_PADDING_CLR_DIS_BIT);

i_byte_swap <=p_in_usr_ctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT);


enable <= not(p_in_dwnp_dst_rdy_n);

p_out_upp_dst_rdy_n <= p_in_dwnp_dst_rdy_n;

p_out_dwnp_data        <= dwnp_data_out;
p_out_dwnp_sof_n       <= not dwnp_sof_out;
p_out_dwnp_eof_n       <= not dwnp_eof_out     when i_mac_padding_clr_disable='1' else not dwnp_eof_usr_out;
p_out_dwnp_src_rdy_n   <= not dwnp_src_rdy_out when i_mac_padding_clr_disable='1' else not (dwnp_src_rdy_out and dwnp_src_rdy_usr_out);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst = '1' then
    dwnp_data_out    <= (others=>'0');
    dwnp_sof_out     <= '0';
    dwnp_eof_out     <= '0';
    dwnp_eof_usr_out <= '0';
    dwnp_src_rdy_usr_out <= '0';
    dwnp_src_rdy_out <= '0';
  elsif rising_edge(p_in_clk) then
    if enable = '1' then
      dwnp_data_out  <= p_in_upp_data;
      dwnp_sof_out   <= not p_in_upp_sof_n;
      dwnp_eof_out   <= not p_in_upp_eof_n;
      dwnp_eof_usr_out   <= i_eof;
      dwnp_src_rdy_out <= not p_in_upp_src_rdy_n;
      if p_in_upp_sof_n='0' then
        dwnp_src_rdy_usr_out <= '1';
      elsif dwnp_eof_usr_out='1' then
        dwnp_src_rdy_usr_out <= '0';
      end if;
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst = '1' then
    fsm_state_cs<=S_IDLE;
    i_len_msb<='0';
    i_cntbyte<=(others=>'0');
    i_eof<='0';
  elsif rising_edge(p_in_clk) then
    if enable = '1' then

      case fsm_state_cs is

        when S_IDLE =>
          if p_in_upp_sof_n = '0' then
            i_cntbyte<=CONV_STD_LOGIC_VECTOR(10, 16);
            fsm_state_cs<=S_MAC_ADR;
          end if;

        when S_MAC_ADR =>
          if i_cntbyte=CONV_STD_LOGIC_VECTOR(0, 16) then
            fsm_state_cs<=S_LENGTH;
          else
            i_cntbyte<=i_cntbyte-1;
          end if;

        when S_LENGTH =>
          if i_len_msb='1' then
            fsm_state_cs<=S_DATA;
            i_len_msb<='0';
            if i_byte_swap='1' then
              i_cntbyte(7 downto 0)<=p_in_upp_data;
            else
              i_cntbyte(15 downto 8)<=p_in_upp_data;
            end if;
          else
            i_len_msb<='1';
            if i_byte_swap='1' then
              i_cntbyte(15 downto 8)<=p_in_upp_data;
            else
              i_cntbyte(7 downto 0)<=p_in_upp_data;
            end if;
          end if;

        when S_DATA =>
          i_cntbyte<=i_cntbyte-1;

          if i_cntbyte=CONV_STD_LOGIC_VECTOR(2, 16) then
            fsm_state_cs<=S_EOF;
            i_eof<='1';
          end if;

        when S_EOF =>
          i_eof<='0';
          fsm_state_cs<=S_IDLE;

      end case;
    end if;
  end if;
end process;




--//END MAIN
end arch1;  --arch1


