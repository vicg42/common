-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02/04/2010
-- Module Name : video_pkt_filter
--
-- Назначение/Описание :
--
--        Структура правила маршрутизации(Маска):
--        3..0 - тип пакета
--        7..4 - подтип пакета
--        Ведем фильтрацию пакетов только по не нулевым маскам, если
--        маска совпала с соответстующими полями видео пакета, то такой пакет пропускаем,
--        иначе выбрасываем.
--        Знанечие Маски=0 - запретить прохождение пакета
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
use work.prj_def.all;

library unisim;
use unisim.vcomponents.all;

entity video_pkt_filter is
generic(
G_DWIDTH : integer := 32;
G_FRR_COUNT : integer := 3
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_frr        : in    TEthFRR;

--------------------------------------
--Upstream Port
--------------------------------------
p_in_upp_data   : in    std_logic_vector(G_DWIDTH - 1 downto 0);
p_in_upp_wr     : in    std_logic;
p_in_upp_eof    : in    std_logic;
p_in_upp_sof    : in    std_logic;

--------------------------------------
--Downstream Port
--------------------------------------
p_out_dwnp_data : out   std_logic_vector(G_DWIDTH - 1 downto 0):=(others=>'0');
p_out_dwnp_wr   : out   std_logic:='0';
p_out_dwnp_eof  : out   std_logic:='0';
p_out_dwnp_sof  : out   std_logic:='0';

-------------------------------
--Технологический
-------------------------------
p_in_tst        : in    std_logic_vector(31 downto 0);
p_out_tst       : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk        : in    std_logic;
p_in_rst        : in    std_logic
);
end video_pkt_filter;

architecture behavioral of video_pkt_filter is

signal sr_upp_data   : std_logic_vector(G_DWIDTH - 1 downto 0):=(others=>'0');
signal sr_upp_sof    : std_logic:='0';
signal sr_upp_wr     : std_logic:='0';
signal sr_upp_eof    : std_logic:='0';

signal i_pkt_type    : std_logic_vector(3 downto 0);
signal i_pkt_subtype : std_logic_vector(3 downto 0);
signal i_pkt_en      : std_logic;


--MAIN
begin

------------------------------------
--Технологические сигналы
------------------------------------
p_out_tst(31 downto 0)<=(others=>'0');



--Линия задержки
process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    sr_upp_eof <= p_in_upp_eof;
    sr_upp_sof <= p_in_upp_sof;
    sr_upp_wr  <= p_in_upp_wr;

    if p_in_upp_wr='1' then
      sr_upp_data <= p_in_upp_data;
    end if;

    p_out_dwnp_sof  <= sr_upp_sof and i_pkt_en;
    p_out_dwnp_eof  <= sr_upp_eof and i_pkt_en;
    p_out_dwnp_wr   <= sr_upp_wr  and i_pkt_en;
    p_out_dwnp_data <= sr_upp_data;

  end if;
end process;

--Разрешение пропуска пакета
i_pkt_type(3 downto 0) <= p_in_upp_data(19 downto 16);
i_pkt_subtype(3 downto 0) <= p_in_upp_data(23 downto 20);

process(p_in_rst,p_in_clk)
variable pkt_valid : std_logic;
begin
  if p_in_rst='1' then
    i_pkt_en <= '0';
      pkt_valid := '0';

  elsif rising_edge(p_in_clk) then

      pkt_valid := '0';

    if p_in_upp_sof = '1' and p_in_upp_wr = '1' then

        --Ищем правило машрутизации для текущего пакета
        for i in 0 to G_FRR_COUNT - 1 loop
          if p_in_frr(i) /= (p_in_frr(i)'range => '0') then
            if p_in_frr(i) = (i_pkt_subtype & i_pkt_type) then
              pkt_valid := '1';
            end if;
          end if;
        end loop;

      i_pkt_en <= pkt_valid;

    elsif sr_upp_eof = '1' then
      i_pkt_en <= '0';
    end if;

  end if;
end process;


--END MAIN
end behavioral;
