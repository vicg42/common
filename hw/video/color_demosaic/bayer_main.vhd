-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.10.2014 10:28:44
-- Module Name : bayer_main
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.reduce_pack.all;
use work.vfilter_core_pkg.all;

entity bayer_main is
generic(
G_BRAM_AWIDTH : integer := 12;
G_SIM : string:="OFF"
);
port(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass    : in    std_logic;                    --0/1 - Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать
p_in_cfg_colorfst  : in    std_logic_vector(1 downto 0); --Первый пиксель 0/1/2 - R/G/B
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);--Кол-во пиксел/4 т.к p_in_upp_data=32bit
p_in_cfg_row_count : in    std_logic_vector(15 downto 0);--Кол-во строк
p_in_cfg_init      : in    std_logic;                    --Инициализация. Сброс счетчика адреса BRAM

----------------------------
--Upstream Port (входные данные)
----------------------------
p_in_upp_data      : in    std_logic_vector(7 downto 0);
p_in_upp_wr        : in    std_logic;
p_in_upp_eof       : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;

----------------------------
--Downstream Port (результат)
----------------------------
p_out_dwnp_data    : out   std_logic_vector(7 downto 0);
p_out_dwnp_wr      : out   std_logic;
p_out_dwnp_eof     : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk           : in    std_logic;
p_in_rst           : in    std_logic
);
end entity bayer_main;

architecture behavioral of bayer_main is

component vfilter_core is
generic(
G_BRAM_AWIDTH : integer := 12;
G_SIM : string:="OFF"
);
port(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);
p_in_cfg_init      : in    std_logic;

----------------------------
--Upstream Port (входные данные)
----------------------------
p_in_upp_data      : in    std_logic_vector(7 downto 0);
p_in_upp_wr        : in    std_logic;
p_in_upp_eof       : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;

----------------------------
--Downstream Port (результат)
----------------------------
p_out_matrix       : out   TMatrix;
p_out_dwnp_wr      : out   std_logic;
p_out_dwnp_eof     : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk           : in    std_logic;
p_in_rst           : in    std_logic
);
end component vfilter_core;

signal i_matrix            : TMatrix;
signal i_matrix_wr         : std_logic;
signal i_dwnp_eof          : std_logic;




begin --architecture behavioral

p_out_dwnp_data <= std_logic_vector(i_matrix(1)(1));
p_out_dwnp_wr <= i_matrix_wr;
p_out_dwnp_eof <= i_dwnp_eof;


m_core : vfilter_core
generic map(
G_BRAM_AWIDTH => G_BRAM_AWIDTH,
G_SIM => G_SIM
)
port map(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_pix_count => p_in_cfg_pix_count,
p_in_cfg_init      => p_in_cfg_init,

----------------------------
--Upstream Port (входные данные)
----------------------------
p_in_upp_data      => p_in_upp_data  ,
p_in_upp_wr        => p_in_upp_wr    ,
p_in_upp_eof       => p_in_upp_eof   ,
p_out_upp_rdy_n    => p_out_upp_rdy_n,

----------------------------
--Downstream Port (результат)
----------------------------
p_out_matrix       => i_matrix  ,
p_out_dwnp_wr      => i_matrix_wr ,
p_out_dwnp_eof     => i_dwnp_eof,
p_in_dwnp_rdy_n    => p_in_dwnp_rdy_n,

-------------------------------
--Технологический
-------------------------------
p_in_tst           => (others => '0'),
p_out_tst          => open,

-------------------------------
--System
-------------------------------
p_in_clk           => p_in_clk,
p_in_rst           => p_in_rst
);

----##################################
----Calc
----##################################
--process(p_in_clk)
--begin
--  if rising_edge(p_in_clk) then
--    if i_matrix_wr = '1' then
--
--    end if;
--  end if;
--end process


--##################################
--DBG
--##################################
p_out_tst(0) <= OR_reduce(std_logic_vector(i_matrix(0)(0)))
or OR_reduce(std_logic_vector(i_matrix(0)(1)))
or OR_reduce(std_logic_vector(i_matrix(0)(2)))
or OR_reduce(std_logic_vector(i_matrix(1)(0)))
or OR_reduce(std_logic_vector(i_matrix(1)(1)))
or OR_reduce(std_logic_vector(i_matrix(1)(2)))
or OR_reduce(std_logic_vector(i_matrix(2)(0)))
or OR_reduce(std_logic_vector(i_matrix(2)(1)))
or OR_reduce(std_logic_vector(i_matrix(2)(2)));
p_out_tst(31 downto 1) <= (others=>'0');

end architecture behavioral;



