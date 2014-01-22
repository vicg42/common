-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2013 11:12:57
-- Module Name : dsn_switch
--
-- Назначение/Описание :
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_def.all;

entity dsn_switch is
generic(
G_VBUF_IWIDTH : integer := 80;
G_VBUF_OWIDTH : integer := 32
);
port(
-------------------------------
-- Конфигурирование модуля DSN_SWITCH.VHD (host_clk domain)
-------------------------------
p_in_cfg_clk              : in   std_logic;

p_in_cfg_adr              : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld           : in   std_logic;
p_in_cfg_adr_fifo         : in   std_logic;

p_in_cfg_txdata           : in   std_logic_vector(15 downto 0);
p_in_cfg_wd               : in   std_logic;

p_out_cfg_rxdata          : out  std_logic_vector(15 downto 0);
p_in_cfg_rd               : in   std_logic;

p_in_cfg_done             : in   std_logic;

-------------------------------
--Связь с ImageSensor
-------------------------------
p_in_vd                   : in   std_logic_vector(G_VBUF_IWIDTH - 1 downto 0);
p_in_vs                   : in   std_logic;
p_in_hs                   : in   std_logic;
p_in_vclk                 : in   std_logic;
p_in_vclk_en              : in   std_logic;
p_in_ext_syn              : in   std_logic;--Внешняя синхронизация

p_in_convert_clk          : in   std_logic;--частота конвертирования данных 80bit -> 32bit

-------------------------------
--VBUFI
-------------------------------
p_in_vbufi_rdclk          : in   std_logic;
p_out_vbufi_do            : out  std_logic_vector(G_VBUF_OWIDTH - 1 downto 0);
p_in_vbufi_rd             : in   std_logic;
p_out_vbufi_empty         : out  std_logic;
p_out_vbufi_full          : out  std_logic;
p_out_vbufi_pfull         : out  std_logic;

-------------------------------
--VBUFI2
-------------------------------
p_in_vbufi2_rdclk         : in   std_logic;
p_out_vbufi2_do           : out  std_logic_vector(G_VBUF_OWIDTH - 1 downto 0);
p_in_vbufi2_rd            : in   std_logic;
p_out_vbufi2_empty        : out  std_logic;
p_out_vbufi2_full         : out  std_logic;
p_out_vbufi2_pfull        : out  std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst                  : in    std_logic_vector(31 downto 0);
p_out_tst                 : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst     : in    std_logic
);
end dsn_switch;

architecture behavioral of dsn_switch is

component vin
generic(
G_VBUF_IWIDTH : integer:=80;
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1'
);
port(
--Вх. видеопоток
p_in_vd            : in   std_logic_vector(G_VBUF_IWIDTH - 1 downto 0);
p_in_vs            : in   std_logic;
p_in_hs            : in   std_logic;
p_in_vclk          : in   std_logic;
p_in_vclk_en       : in   std_logic;
p_in_ext_syn       : in   std_logic;--Внешняя синхронизация

--Вых. видеопоток
p_out_vbufi_d      : out  std_logic_vector(G_VBUF_OWIDTH - 1 downto 0);
p_in_vbufi_rd      : in   std_logic;
p_out_vbufi_empty  : out  std_logic;
p_out_vbufi_full   : out  std_logic;
p_in_vbufi_wrclk   : in   std_logic;
p_in_vbufi_rdclk   : in   std_logic;

--Технологический
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

--System
p_in_rst           : in   std_logic
);
end component;

signal i_cfg_adr_cnt                 : std_logic_vector(7 downto 0);

signal h_reg_ctrl                    : std_logic_vector(C_SWT_REG_CTRL_LAST_BIT downto 0);
signal h_reg_eth_vctrl_frr           : TEthFRR;

signal b_rst_vctrl_bufs              : std_logic;
signal i_en_video                    : std_logic;

signal i_vctrl_vbufout_empty         : std_logic;



--MAIN
begin


------------------------------------
--Технологические сигналы
------------------------------------
p_out_tst(0) <= b_rst_vctrl_bufs;
p_out_tst(1) <= i_en_video;
p_out_tst(31 downto 2) <= (others=>'0');


----------------------------------------------------
--Запись/чтение регистров
----------------------------------------------------
--Счетчик адреса регистров
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_rst = '1' then
    i_cfg_adr_cnt <= (others=>'0');
  else
    if p_in_cfg_adr_ld = '1' then
      i_cfg_adr_cnt <= p_in_cfg_adr;
    else
      if p_in_cfg_adr_fifo = '0' and (p_in_cfg_wd = '1' or p_in_cfg_rd = '1') then
        i_cfg_adr_cnt <= i_cfg_adr_cnt + 1;
      end if;
    end if;
  end if;
end if;--p_in_rst,
end process;

--Запись регистров
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_rst = '1' then
    h_reg_ctrl <= (others=>'0');

    for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_VCTRL_FRR_COUNT) - 1 loop
      h_reg_eth_vctrl_frr(2 * i) <= (others=>'0');
      h_reg_eth_vctrl_frr((2 * i) + 1) <= (others=>'0');
    end loop;

  else
    if p_in_cfg_wd = '1' then
        if i_cfg_adr_cnt = CONV_STD_LOGIC_VECTOR(C_SWT_REG_CTRL, i_cfg_adr_cnt'length) then
          h_reg_ctrl <= p_in_cfg_txdata(h_reg_ctrl'high downto 0);

        elsif i_cfg_adr_cnt(i_cfg_adr_cnt'high downto log2(C_SWT_FRR_COUNT_MAX)) =
          CONV_STD_LOGIC_VECTOR(C_SWT_REG_FRR_ETHG_VCTRL/C_SWT_FRR_COUNT_MAX
                                  ,(i_cfg_adr_cnt'high - log2(C_SWT_FRR_COUNT_MAX) + 1)) then
        --Маски фильтрации пакетов: ETH->VCTRL
          for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_VCTRL_FRR_COUNT) - 1 loop
            if i_cfg_adr_cnt(log2(C_SWT_FRR_COUNT_MAX) - 1 downto 0) = i then
              h_reg_eth_vctrl_frr(2 * i)  <= p_in_cfg_txdata(7 downto 0);
              h_reg_eth_vctrl_frr((2 * i) + 1) <= p_in_cfg_txdata(15 downto 8);
            end if;
          end loop;

        end if;
    end if;
  end if;
end if;--p_in_rst,
end process;

--Чтение регистров
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_rst = '1' then
    p_out_cfg_rxdata <= (others=>'0');
  else
    if p_in_cfg_rd = '1' then
        if i_cfg_adr_cnt = CONV_STD_LOGIC_VECTOR(C_SWT_REG_CTRL, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata <= EXT(h_reg_ctrl, p_out_cfg_rxdata'length);

        elsif i_cfg_adr_cnt(i_cfg_adr_cnt'high downto log2(C_SWT_FRR_COUNT_MAX)) =
          CONV_STD_LOGIC_VECTOR(C_SWT_REG_FRR_ETHG_VCTRL/C_SWT_FRR_COUNT_MAX
                                  ,(i_cfg_adr_cnt'high - log2(C_SWT_FRR_COUNT_MAX) + 1)) then
        --Маски фильтрации пакетов: ETH->VCTRL
          for i in 0 to C_SWT_GET_FMASK_REG_COUNT(C_SWT_ETH_VCTRL_FRR_COUNT) - 1 loop
            if i_cfg_adr_cnt(log2(C_SWT_FRR_COUNT_MAX) - 1 downto 0) = i then
              p_out_cfg_rxdata(7 downto 0) <= h_reg_eth_vctrl_frr(2 * i)  ;
              p_out_cfg_rxdata(15 downto 8) <= h_reg_eth_vctrl_frr((2 * i) + 1);
            end if;
          end loop;

        end if;
    end if;
  end if;
end if;--p_in_rst,
end process;


b_rst_vctrl_bufs <= p_in_rst or h_reg_ctrl(C_SWT_REG_CTRL_RST_VCTRL_BUFS_BIT);

process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_rst = '1' then
    i_en_video <= '0';
  else
    if h_reg_eth_vctrl_frr(0) /= (h_reg_eth_vctrl_frr(0)'range => '0') then
      i_en_video <= '1';
    else
      i_en_video <= '0';
    end if;
  end if;
end if;--p_in_rst,
end process;


--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--ImageSensor -> PCIE
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
m_vbufi : vin
generic map(
G_VBUF_IWIDTH => G_VBUF_IWIDTH,
G_VBUF_OWIDTH => G_VBUF_OWIDTH,
G_VSYN_ACTIVE => '1'
)
port map(
--Вх. видеопоток
p_in_vd            => p_in_vd,
p_in_vs            => p_in_vs,
p_in_hs            => p_in_hs,
p_in_vclk          => p_in_vclk,
p_in_vclk_en       => p_in_vclk_en,
p_in_ext_syn       => i_en_video, -- разрешение записи в вх. буфер (подсинхривается сигналом p_in_vs)

--Вых. видеопоток
p_out_vbufi_d      => p_out_vbufi_do,
p_in_vbufi_rd      => p_in_vbufi_rd,
p_out_vbufi_empty  => p_out_vbufi_empty,
p_out_vbufi_full   => p_out_vbufi_full,
p_in_vbufi_wrclk   => p_in_convert_clk,
p_in_vbufi_rdclk   => p_in_vbufi_rdclk,

--Технологический
p_in_tst           => (others => '0'),
p_out_tst          => open,

--System
p_in_rst           => b_rst_vctrl_bufs
);

p_out_vbufi_pfull <= '0';

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--ImageSensor -> VOUT
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
m_vbufi2 : vin
generic map(
G_VBUF_IWIDTH => G_VBUF_IWIDTH,
G_VBUF_OWIDTH => G_VBUF_OWIDTH,
G_VSYN_ACTIVE => '1'
)
port map(
--Вх. видеопоток
p_in_vd            => p_in_vd,
p_in_vs            => p_in_vs,
p_in_hs            => p_in_hs,
p_in_vclk          => p_in_vclk,
p_in_vclk_en       => p_in_vclk_en,
p_in_ext_syn       => i_en_video, -- разрешение записи в вх. буфер (подсинхривается сигналом p_in_vs)

--Вых. видеопоток
p_out_vbufi_d      => p_out_vbufi2_do,
p_in_vbufi_rd      => p_in_vbufi2_rd,
p_out_vbufi_empty  => p_out_vbufi2_empty,
p_out_vbufi_full   => p_out_vbufi2_full,
p_in_vbufi_wrclk   => p_in_convert_clk,
p_in_vbufi_rdclk   => p_in_vbufi2_rdclk,

--Технологический
p_in_tst           => (others => '0'),
p_out_tst          => open,

--System
p_in_rst           => b_rst_vctrl_bufs
);

p_out_vbufi2_pfull <= '0';

--END MAIN
end behavioral;
