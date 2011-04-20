-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 15/04/2010
-- Module Name : eth_rx_mac_frame_header_clr
--
-- Назначение/Описание : Модуль транслирует данные из Upstream Port в Downstream Port +
--                       обрезает выходной поток данных в зависимости от установок на порту p_in_usr_pattern_size
--                       p_in_usr_pattern_size=0 - bypass
--                       p_in_usr_pattern_size/=0 - кол-во байт которые нужно удалить из входного потока (Upstream Port)
--                                                  (1 бай удаления синхронизирован sof)
--
--                       Удаляемые данные:это могут быть адреса MAC dst/src или чтото другое
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

entity eth_rx_mac_frame_header_clr is
port
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
--p_in_usr_pattern       : in  TEthUsrPattern;
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

end eth_rx_mac_frame_header_clr;

architecture arch1 of eth_rx_mac_frame_header_clr is


--constant i_pkt_marker_byte: std_logic_vector(4 downto 0):=CONV_STD_LOGIC_VECTOR(C_PKT_MARKER, 5);

--Signal declarations
signal enable                    : std_logic;

signal bypass                    : std_logic;
signal usr_pattern               : std_logic;
signal i_pattern_cnt             : std_logic_vector(C_PKT_MARKER_PATTERN_SIZE-1 downto 0);
signal i_pattern_size            : std_logic_vector(C_PKT_MARKER_PATTERN_SIZE-1 downto 0);
signal i_pattern_size_cmp        : std_logic_vector(C_PKT_MARKER_PATTERN_SIZE-1 downto 0);

signal upp_sof_sr_in             : std_logic;
signal upp_sof_sr_out            : std_logic;

signal upp_eof_sr_in             : std_logic;
signal upp_eof_sr_out            : std_logic;

signal upp_src_rdy_sr_in         : std_logic;
signal upp_src_rdy_sr_out        : std_logic;
signal upp_src_rdy_sr_out_clr    : std_logic;

signal upp_data_sr               : std_logic_vector(7 downto 0);

signal dwnp_src_rdy_n_tmp        : std_logic;


-- Small delay for simulation purposes.
constant dly : time := 1 ps;


--//MAIN
begin  -- arch1



enable <= not(p_in_dwnp_dst_rdy_n);

p_out_upp_dst_rdy_n <= p_in_dwnp_dst_rdy_n;

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
  A1 => i_pattern_size(0),
  A2 => i_pattern_size(0),
  A3 => i_pattern_size(0),

  D   => p_in_upp_data(i),
  Q   => upp_data_sr(i),
  CE  => enable,
  CLK => p_in_clk
  );
end generate gen_data;

p_out_dwnp_data <= upp_data_sr;

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

p_out_dwnp_sof_n<=not upp_sof_sr_out;

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
A0 => '0',
A1 => '0',
A2 => '0',
A3 => '0',

D   => upp_eof_sr_in,
Q   => upp_eof_sr_out,
CE  => enable,
CLK => p_in_clk
);

p_out_dwnp_eof_n<=not upp_eof_sr_out;

----------------------------------------------------------------------------
--Формирование p_out_dwnp_src_rdy_n
--
----------------------------------------------------------------------------
--//Отрезаем первые 2 byte (т.к. размер маркера пакета = 2 байта
--//(это следует из того что шина пользовательских данных =1бит)
upp_src_rdy_sr_in<=not p_in_upp_src_rdy_n;

m_upp_src_rdy_sr_clr : SRL16E
generic map (
INIT => X"0000"
)
port map (
A0 => '0',
A1 => '0',
A2 => '0',
A3 => '0',

D   => upp_src_rdy_sr_in,
Q   => upp_src_rdy_sr_out_clr,
CE  => enable,
CLK => p_in_clk
);

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

dwnp_src_rdy_n_tmp <=not (upp_src_rdy_sr_out_clr) when bypass='1' else
                     not (upp_src_rdy_sr_out_clr and upp_src_rdy_sr_out);
p_out_dwnp_src_rdy_n <=dwnp_src_rdy_n_tmp;


----------------------------------------------------------------------------
--Анализ кол-ва удаляемых данных (обрезаемых) данных из потока p_in_upp_data
--
----------------------------------------------------------------------------
i_pattern_size_cmp<=i_pattern_size-1;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst = '1' then
    usr_pattern<='0';
    bypass<='0';
    i_pattern_size<=(others=>'0');
  elsif rising_edge(p_in_clk) then
    if enable = '1' then
      if p_in_upp_sof_n = '0' then
        --//Обновляем значение (Сколько данных нужно обрезать)
        i_pattern_size<=p_in_usr_pattern_size(C_PKT_MARKER_PATTERN_SIZE_MSB_BIT downto C_PKT_MARKER_PATTERN_SIZE_LSB_BIT);

        if p_in_usr_pattern_size(C_PKT_MARKER_PATTERN_SIZE_MSB_BIT downto C_PKT_MARKER_PATTERN_SIZE_LSB_BIT)=CONV_STD_LOGIC_VECTOR(0, C_PKT_MARKER_PATTERN_SIZE) then
          bypass<='1';
          usr_pattern<='0';
        else
          bypass<='0';
          usr_pattern<='1';
        end if;
      elsif i_pattern_cnt=i_pattern_size_cmp then
        usr_pattern<='0';
      end if;

    end if;
  end if;
end process;

--//Счетчик обрезаемых данных
process(p_in_rst,p_in_clk)
begin
  if p_in_rst = '1' then
    i_pattern_cnt<=(others=>'0');
  elsif rising_edge(p_in_clk) then
    if enable = '1' then
      if usr_pattern='0' then
        i_pattern_cnt<=(others=>'0');
      else
        i_pattern_cnt<=i_pattern_cnt+1;
      end if;
    end if;
  end if;
end process;


--//END MAIN
end arch1;  --arch1


