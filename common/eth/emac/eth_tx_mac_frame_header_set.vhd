-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13/04/2010
-- Module Name : eth_tx_mac_frame_header_set
--
-- Назначение/Описание : Модуль транслирует данные из Upstream Port в Downstream Port +
--                       впечатывает(вставляет) пользовательские данные
--                       p_in_usr_pattern в выходной поток данных p_out_dwnp_data
--
--                       Это могут быть адреса MAC dst/src или чтото другое
--                       Размер вставки передается в маркере пакета (Байт данных
--                       синхронный со стробом p_in_upp_sof_n)
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.eth_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity eth_tx_mac_frame_header_set is
generic(
G_PKT_MARKER      :       integer := 4
);
port
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
p_in_usr_pattern       : in  TEthUsrPattern;

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

end eth_tx_mac_frame_header_set;

architecture arch1 of eth_tx_mac_frame_header_set is


constant i_pkt_marker_byte: std_logic_vector(4 downto 0):=CONV_STD_LOGIC_VECTOR(G_PKT_MARKER, 5);

--type   srxby1 is array (0 to C_PKT_MARKER) of std_logic;
--signal upp_sof_sr                : srxby1;  -- holds contents of start of frame sr

--Signal declarations
signal enable                    : std_logic;

signal usr_pattern               : std_logic;
signal i_pattern_cnt_en          : std_logic;
signal i_pattern_cnt             : std_logic_vector(C_PKT_MARKER_PATTERN_SIZE-1 downto 0);
signal i_pattern_size            : std_logic_vector(C_PKT_MARKER_PATTERN_SIZE-1 downto 0);
signal i_pattern_size_cmp        : std_logic_vector(C_PKT_MARKER_PATTERN_SIZE-1 downto 0);

signal upp_sof_sr_in             : std_logic;
signal upp_sof_sr_out            : std_logic;

signal upp_eof_sr_in             : std_logic;
signal upp_eof_sr_out            : std_logic;
signal upp_eof_sr_n_tmp          : std_logic;

signal upp_dst_rdy_disable       : std_logic;

signal upp_data_sr_tmp           : std_logic_vector(7 downto 0);
signal upp_data_sr               : std_logic_vector(7 downto 0);

signal dwnp_frame_en             : std_logic;


-- Small delay for simulation purposes.
constant dly : time := 1 ps;


--//MAIN
begin  -- arch1



enable <= not(p_in_dwnp_dst_rdy_n);

p_out_upp_dst_rdy_n <= p_in_dwnp_dst_rdy_n or upp_dst_rdy_disable;

----------------------------------------------------------------------------
--Формируем задержку чтения данных с Upstream Port
--
----------------------------------------------------------------------------
--//Сигнал задержки чтения
process(p_in_rst,p_in_clk)
begin
  if p_in_rst = '1' then
    upp_dst_rdy_disable<='0';
  elsif rising_edge(p_in_clk) then
    if enable = '1' then
      if p_in_upp_eof_n='0' then
        upp_dst_rdy_disable<='1';
      elsif upp_eof_sr_n_tmp='0' then
        upp_dst_rdy_disable<='0';
      end if;
    end if;
  end if;
end process;

----------------------------------------------------------------------------
--Формирование p_out_dwnp_data
--
----------------------------------------------------------------------------
--//Программируемая задержка
gen_data : for i in 0 to 7 generate
  m_upp_data_sr : SRL16E
  generic map (
  INIT => X"0000"
  )
  port map (
  A0 => i_pattern_size(0),
  A1 => i_pattern_size(1),
  A2 => i_pattern_size(2),
  A3 => i_pattern_size(3),

  D   => p_in_upp_data(i),
  Q   => upp_data_sr(i),
  CE  => enable,
  CLK => p_in_clk
  );
end generate gen_data;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    upp_data_sr_tmp <= (others=>'0');
  elsif rising_edge(p_in_clk) then
    if enable = '1' then
      upp_data_sr_tmp <= upp_data_sr;
    end if;
  end if;
end process;

p_out_dwnp_data <= upp_data_sr_tmp when i_pattern_cnt_en='0' else p_in_usr_pattern(CONV_INTEGER(i_pattern_cnt));

----------------------------------------------------------------------------
--Формирование p_out_dwnp_sof_n
--
----------------------------------------------------------------------------
upp_sof_sr_in <= not p_in_upp_sof_n and not upp_dst_rdy_disable;

m_upp_sof_sr : SRL16E
generic map (
INIT => X"0000"
)
port map (
A0 => i_pkt_marker_byte(0),
A1 => i_pkt_marker_byte(1),
A2 => i_pkt_marker_byte(2),
A3 => i_pkt_marker_byte(3),

D   => upp_sof_sr_in,
Q   => upp_sof_sr_out,
CE  => enable,
CLK => p_in_clk
);

process(p_in_rst,p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if enable = '1' then
      p_out_dwnp_sof_n<=not upp_sof_sr_out;
    end if;
  end if;
end process;

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
  if rising_edge(p_in_clk) then
    if enable = '1' then
      upp_eof_sr_n_tmp<=not upp_eof_sr_out;
    end if;
  end if;
end process;

p_out_dwnp_eof_n<=upp_eof_sr_n_tmp;

----------------------------------------------------------------------------
--Формирование p_out_dwnp_src_rdy_n
--
----------------------------------------------------------------------------
--upp_src_rdy_sr_in<=not p_in_upp_src_rdy_n;
--
--m_upp_src_rdy_sr : SRL16E
--generic map (
--INIT => X"0000"
--)
--port map (
--A0 => i_pkt_marker_byte(0),
--A1 => i_pkt_marker_byte(1),
--A2 => i_pkt_marker_byte(2),
--A3 => i_pkt_marker_byte(3),
--
--D   => upp_src_rdy_sr_in,
--Q   => upp_src_rdy_sr_out,
--CE  => enable,
--CLK => p_in_clk
--);

--//
process(p_in_rst,p_in_clk)
begin
 if p_in_rst = '1' then
    dwnp_frame_en<='0';
 elsif rising_edge(p_in_clk) then
   if enable = '1' then
      if upp_sof_sr_out = '1' then
        dwnp_frame_en<='1';
      elsif upp_eof_sr_n_tmp='0' then
        dwnp_frame_en<='0';
      end if;
   end if;
 end if;
end process;

--process(p_in_rst,p_in_clk)
--begin
--  if rising_edge(p_in_clk) then
--    upp_src_rdy_sr_out_tmp<=upp_src_rdy_sr_out;
--  end if;
--end process;

p_out_dwnp_src_rdy_n <=not (dwnp_frame_en);-- and upp_src_rdy_sr_out_tmp);

----------------------------------------------------------------------------
--Анализ маркера пакета и принятие соотв. действия
--
----------------------------------------------------------------------------
i_pattern_size_cmp<=i_pattern_size-1;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst = '1' then
    usr_pattern<='0';
    i_pattern_cnt_en<='0';
    i_pattern_size<=(others=>'0');
  elsif rising_edge(p_in_clk) then
    if enable = '1' then
      if upp_sof_sr_in='1' then
        --//Анализируем маркер пакеда данных
        i_pattern_size<=p_in_upp_data(C_PKT_MARKER_PATTERN_SIZE_MSB_BIT downto C_PKT_MARKER_PATTERN_SIZE_LSB_BIT);

        if p_in_upp_data(C_PKT_MARKER_PATTERN_SIZE_MSB_BIT downto C_PKT_MARKER_PATTERN_SIZE_LSB_BIT)=CONV_STD_LOGIC_VECTOR(0, C_PKT_MARKER_PATTERN_SIZE) then
          usr_pattern<='0';
        else
          usr_pattern<='1';
        end if;

      elsif i_pattern_cnt=i_pattern_size then
        usr_pattern<='0';
      end if;

      if usr_pattern='1' and upp_sof_sr_out='1' then
        i_pattern_cnt_en<='1';
      elsif i_pattern_cnt=i_pattern_size_cmp then
        i_pattern_cnt_en<='0';
      end if;
    end if;
  end if;
end process;

--//Счетчик вставляемых польз. данных
process(p_in_rst,p_in_clk)
begin
  if p_in_rst = '1' then
    i_pattern_cnt<=(others=>'0');
  elsif rising_edge(p_in_clk) then
    if enable = '1' then
      if i_pattern_cnt_en='0' then
        i_pattern_cnt<=(others=>'0');
      else
        i_pattern_cnt<=i_pattern_cnt+1;
      end if;
    end if;
  end if;
end process;


--//END MAIN
end arch1;  --arch1


