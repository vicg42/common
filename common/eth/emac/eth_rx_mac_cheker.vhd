-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 15/04/2010
-- Module Name : eth_rx_mac_cheker
--
-- Назначение/Описание :
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

use work.eth_pkg.all;
use work.prj_def.all;

library unisim;
use unisim.vcomponents.all;

entity eth_rx_mac_cheker is
port
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
p_in_usr_ctrl          : in  std_logic_vector(15 downto 0);
p_in_usr_pattern       : in  TEthUsrPattern;
p_in_usr_pattern_size  : in  std_logic_vector(15 downto 0); -- Input data

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
end eth_rx_mac_cheker;

architecture arch1 of eth_rx_mac_cheker is


--constant i_pkt_marker_byte: std_logic_vector(4 downto 0):=CONV_STD_LOGIC_VECTOR(C_PKT_MARKER, 5);

----6 stage shift register type and signals
--type   sr6by8 is array (0 to 5) of std_logic_vector(7 downto 0);
--signal data_sr_content : sr6by8;  -- holds contents of data sr
--
----7 stage shift register type and signals
--type   sr7by1 is array (0 to 6) of std_logic;
--signal eof_sr_content   : sr7by1;  -- holds contents of end of frame sr
--signal sof_sr_content   : sr7by1;  -- holds contents of start of frame sr
--signal rdy_sr_content   : sr7by1;
--

--Signal declarations
signal enable                    : std_logic;

signal pkt_valid                 : std_logic;

signal i_pattern_size            : std_logic_vector(C_PKT_MARKER_PATTERN_SIZE-1 downto 0);

--6 stage shift register type and signals
type   sr7by8 is array (0 to 6) of std_logic_vector(7 downto 0);
signal upp_data_sr_in            : sr7by8;  -- holds contents of data sr
signal upp_data_sr_out           : std_logic_vector(7 downto 0);

signal upp_sof_sr_in             : std_logic;
signal upp_sof_sr_out            : std_logic;
signal upp_sof_sr_out_tmp        : std_logic;
signal upp_sof_sr_out_2tmp       : std_logic;

signal upp_eof_sr_in             : std_logic;
signal upp_eof_sr_out            : std_logic;
signal upp_eof_sr_out_tmp        : std_logic;
signal upp_eof_sr_out_2tmp       : std_logic;

signal upp_src_rdy_sr_in         : std_logic;
signal upp_src_rdy_sr_out        : std_logic;
signal upp_src_rdy_sr_out_tmp    : std_logic;
signal upp_src_rdy_sr_out_2tmp   : std_logic;


signal i_mac_cheker_disable      : std_logic;


-- Small delay for simulation purposes.
constant dly : time := 1 ps;


--//MAIN
begin  -- arch1

i_mac_cheker_disable <=p_in_usr_ctrl(C_DSN_ETHG_REG_MAC_RX_CHECK_MAC_DIS_BIT);


i_pattern_size<=p_in_usr_pattern_size(C_PKT_MARKER_PATTERN_SIZE_MSB_BIT downto C_PKT_MARKER_PATTERN_SIZE_LSB_BIT);

enable <= not(p_in_dwnp_dst_rdy_n);

p_out_upp_dst_rdy_n <= p_in_dwnp_dst_rdy_n;

----------------------------------------------------------------------------
--Формирование p_out_dwnp_data
--
----------------------------------------------------------------------------
process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if enable='1' then
      upp_data_sr_in<=p_in_upp_data & upp_data_sr_in(0 to 5);
    end if;
  end if;
end process;


process(p_in_rst,p_in_clk)
 variable tmp_check : std_logic_vector(5 downto 0):=(others=>'0');
begin
  if p_in_rst='1' then
    pkt_valid<='0';

  elsif rising_edge(p_in_clk) then
    tmp_check:=(others=>'0');

    if enable='1' and upp_sof_sr_out='1' then
      for i in 0 to 5 loop
        if upp_data_sr_in(6-i)=p_in_usr_pattern(C_USR_PATTERN_MAC_SRC_LSB_BIT+i) then
          tmp_check(i):='1';
        end if;
      end loop;

      if tmp_check="111111" or i_mac_cheker_disable='1' then
        pkt_valid<='1';
      else
        pkt_valid<='0';
      end if;

    end if;
  end if;
end process;

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if enable = '1' then
      upp_data_sr_out<=upp_data_sr_in(CONV_INTEGER(i_pattern_size));
      p_out_dwnp_data<=upp_data_sr_out;
    end if;
  end if;
end process;


----------------------------------------------------------------------------
--Формирование p_out_dwnp_sof_n
--
----------------------------------------------------------------------------
--//Программируемая задержка
upp_sof_sr_in<=not p_in_upp_sof_n;

m_upp_sof_sr : SRL16E
generic map (
INIT => X"0000"
)
port map (
A0 => i_pattern_size(0),
A1 => i_pattern_size(1),
A2 => i_pattern_size(2),
A3 => i_pattern_size(3),

D   => upp_sof_sr_in,
Q   => upp_sof_sr_out,
CE  => enable,
CLK => p_in_clk
);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    upp_sof_sr_out_tmp<='0';
  elsif rising_edge(p_in_clk) then
    if enable = '1' then
      upp_sof_sr_out_tmp<=upp_sof_sr_out;
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    upp_sof_sr_out_2tmp<='0';
  elsif rising_edge(p_in_clk) then
    if enable = '1' and pkt_valid='1' then
      upp_sof_sr_out_2tmp<=upp_sof_sr_out_tmp;
    end if;
  end if;
end process;

p_out_dwnp_sof_n<=not upp_sof_sr_out_2tmp;

----------------------------------------------------------------------------
--Формирование p_out_dwnp_eof_n
--
----------------------------------------------------------------------------
--//Программируемая задержка
upp_eof_sr_in<=not p_in_upp_eof_n;

m_upp_eof_sr : SRL16E
generic map (
INIT => X"0000"
)
port map (
A0 => i_pattern_size(0),
A1 => i_pattern_size(1),
A2 => i_pattern_size(2),
A3 => i_pattern_size(3),

D   => upp_eof_sr_in,
Q   => upp_eof_sr_out,
CE  => enable,
CLK => p_in_clk
);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    upp_eof_sr_out_tmp<='0';
  elsif rising_edge(p_in_clk) then
    if enable = '1' then
      upp_eof_sr_out_tmp<=upp_eof_sr_out;
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    upp_eof_sr_out_2tmp<='0';
  elsif rising_edge(p_in_clk) then
    if enable = '1' and pkt_valid='1' then
      upp_eof_sr_out_2tmp<=upp_eof_sr_out_tmp;
    end if;
  end if;
end process;

p_out_dwnp_eof_n<=not upp_eof_sr_out_2tmp;
----------------------------------------------------------------------------
--Формирование p_out_dwnp_src_rdy_n
--
----------------------------------------------------------------------------
--//Отрезаем первые 2 byte (т.к. размер маркера пакета = 2 байта
--//(это следует из того что шина пользовательских данных =1бит)
upp_src_rdy_sr_in<=not p_in_upp_src_rdy_n;

--//Программируемая задержка
m_upp_src_rdy_sr : SRL16E
generic map (
INIT => X"0000"
)
port map (
A0 => i_pattern_size(0),
A1 => i_pattern_size(1),
A2 => i_pattern_size(2),
A3 => i_pattern_size(3),

D   => upp_src_rdy_sr_in,
Q   => upp_src_rdy_sr_out,
CE  => enable,
CLK => p_in_clk
);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    upp_src_rdy_sr_out_tmp<='0';
  elsif rising_edge(p_in_clk) then
    if enable = '1' then
      upp_src_rdy_sr_out_tmp<=upp_src_rdy_sr_out;
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    upp_src_rdy_sr_out_2tmp<='0';
  elsif rising_edge(p_in_clk) then
    if enable = '1' and pkt_valid='1' then
      upp_src_rdy_sr_out_2tmp<=upp_src_rdy_sr_out_tmp;
    end if;
  end if;
end process;

p_out_dwnp_src_rdy_n<=not upp_src_rdy_sr_out_2tmp;



--//END MAIN
end arch1;  --arch1


