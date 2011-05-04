-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : dsn_timer
--
-- Назначение/Описание :
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_def.all;
--use work.vereskm_pkg.all;
--use work.memory_ctrl_pkg.all;

entity dsn_timer is
port
(
-------------------------------
-- Конфигурирование модуля dsn_timer.vhd (host_clk domain)
-------------------------------
p_in_host_clk         : in   std_logic;                      --//

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);  --//
p_in_cfg_adr_ld       : in   std_logic;                     --//
p_in_cfg_adr_fifo     : in   std_logic;                     --//

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);  --//
p_in_cfg_wd           : in   std_logic;                      --//

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);  --//
p_in_cfg_rd           : in   std_logic;                      --//

p_in_cfg_done         : in   std_logic;                      --//

-------------------------------
-- STATUS модуля dsn_timer.vhd
-------------------------------
p_in_tmr_clk          : in   std_logic;
p_out_tmr_rdy         : out  std_logic;                      --//
p_out_tmr_error       : out  std_logic;                      --//

p_out_tmr_irq         : out  std_logic_vector(C_DSN_TMR_COUNT_TMR-1 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst            : in    std_logic
);
end dsn_timer;

architecture behavioral of dsn_timer is

signal i_cfg_adr_cnt             : std_logic_vector(7 downto 0);

signal h_reg_ctrl                : std_logic_vector(C_DSN_TMR_REG_CTRL_LAST_BIT downto 0);
signal h_tmr_en                  : std_logic_vector(C_DSN_TMR_COUNT_TMR-1 downto 0);
signal s_reg_ctrl                : std_logic_vector(C_DSN_TMR_COUNT_TMR-1 downto 0);

type TTmrCntDelay  is array (0 to C_DSN_TMR_COUNT_TMR-1) of std_logic_vector (2 downto 0);
type TValCmp  is array (0 to C_DSN_TMR_COUNT_TMR-1) of std_logic_vector (31 downto 0);
signal h_reg_count               : TValCmp;
signal i_tmr_cnt                 : TValCmp;
signal i_tmr_idx                 : std_logic_vector((C_DSN_TMR_REG_CTRL_IDX_MSB_BIT - C_DSN_TMR_REG_CTRL_IDX_LSB_BIT) downto 0);
signal i_tmr_irq                 : std_logic_vector(C_DSN_TMR_COUNT_TMR-1 downto 0);
signal i_tmr_irq_width           : std_logic_vector(C_DSN_TMR_COUNT_TMR-1 downto 0);
signal i_tmr_irq_cnt_width       : TTmrCntDelay;
signal hclk_tmr_irq_width        : std_logic_vector(C_DSN_TMR_COUNT_TMR-1 downto 0);

--MAIN
begin

--//--------------------------------------------------
--//Конфигурирование модуля
--//--------------------------------------------------
--//Счетчик адреса регистров
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    i_cfg_adr_cnt<=(others=>'0');
  elsif p_in_host_clk'event and p_in_host_clk='1' then
    if p_in_cfg_adr_ld='1' then
      i_cfg_adr_cnt<=p_in_cfg_adr;
    else
      if p_in_cfg_adr_fifo='0' and (p_in_cfg_wd='1' or p_in_cfg_rd='1') then
        i_cfg_adr_cnt<=i_cfg_adr_cnt+1;
      end if;
    end if;
  end if;
end process;


--//Выделяем биты для номера таймера
i_tmr_idx<=h_reg_ctrl(C_DSN_TMR_REG_CTRL_IDX_MSB_BIT downto C_DSN_TMR_REG_CTRL_IDX_LSB_BIT);

--//Запись регистров
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    h_reg_ctrl<=(others=>'0');
    for i in 0 to C_DSN_TMR_COUNT_TMR-1 loop
      h_reg_count(i)<=(others=>'0');
    end loop;

    h_tmr_en<=(others=>'0');

  elsif p_in_host_clk'event and p_in_host_clk='1' then
    if p_in_cfg_wd='1' then
      if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TMR_REG_CTRL, i_cfg_adr_cnt'length) then
        h_reg_ctrl <=p_in_cfg_txdata(h_reg_ctrl'high downto 0);

        for i in 0 to C_DSN_TMR_COUNT_TMR-1 loop
          if p_in_cfg_txdata(C_DSN_TMR_REG_CTRL_IDX_MSB_BIT downto C_DSN_TMR_REG_CTRL_IDX_LSB_BIT) = i then
            if p_in_cfg_txdata(C_DSN_TMR_REG_CTRL_EN_BIT)='1' then
              h_tmr_en(i)<='1';
            elsif p_in_cfg_txdata(C_DSN_TMR_REG_CTRL_DIS_BIT)='1' then
              h_tmr_en(i)<='0';
            end if;
          end if;
        end loop;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TMR_REG_CMP_L, i_cfg_adr_cnt'length) then
        for i in 0 to C_DSN_TMR_COUNT_TMR-1 loop
          if i = i_tmr_idx then
            h_reg_count(i)(15 downto 0) <=p_in_cfg_txdata;
          end if;
        end loop;
      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TMR_REG_CMP_M, i_cfg_adr_cnt'length) then
      for i in 0 to C_DSN_TMR_COUNT_TMR-1 loop
        if i = i_tmr_idx then
          h_reg_count(i)(31 downto 16) <=p_in_cfg_txdata;
        end if;
      end loop;

      end if;
    end if;
  end if;
end process;

--//Чтение регистров
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    p_out_cfg_rxdata<=(others=>'0');
  elsif p_in_host_clk'event and p_in_host_clk='1' then
    if p_in_cfg_rd='1' then
      if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TMR_REG_CTRL, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata(h_tmr_en'high downto 0)<=h_tmr_en;
          p_out_cfg_rxdata(15 downto h_tmr_en'high+1)<=(others=>'0');

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TMR_REG_CMP_L, i_cfg_adr_cnt'length) then
        for i in 0 to C_DSN_TMR_COUNT_TMR-1 loop
          if i = i_tmr_idx then
            p_out_cfg_rxdata<=h_reg_count(i)(15 downto 0);
          end if;
        end loop;
      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_TMR_REG_CMP_M, i_cfg_adr_cnt'length) then
        for i in 0 to C_DSN_TMR_COUNT_TMR-1 loop
          if i = i_tmr_idx then
            p_out_cfg_rxdata<=h_reg_count(i)(31 downto 16);
          end if;
        end loop;
      end if;
    end if;
  end if;
end process;


gen_tmr : for i in 0 to C_DSN_TMR_COUNT_TMR-1 generate
begin

  process(p_in_rst,p_in_tmr_clk)
  begin
    if p_in_rst='1' then
      s_reg_ctrl(i)<='0';

      i_tmr_cnt(i)<=(others=>'0');
      i_tmr_irq(i)<='0';

    elsif p_in_tmr_clk'event and p_in_tmr_clk='1' then

      --//Пересинхронизация
      s_reg_ctrl(i)<=h_tmr_en(i);

      --Работа таймеров
      if s_reg_ctrl(i)='1' then
        if i_tmr_cnt(i)=h_reg_count(i) then
          i_tmr_cnt(i)<=(others=>'0');
        else
          i_tmr_cnt(i)<=i_tmr_cnt(i)+1;
        end if;
      else
        i_tmr_cnt(i)<=(others=>'0');
      end if;

      if i_tmr_cnt(i)=h_reg_count(i) and h_reg_count(i)/=CONV_STD_LOGIC_VECTOR(0, 32) then
        i_tmr_irq(i)<='1';
      else
        i_tmr_irq(i)<='0';
      end if;

    end if;
  end process;

  --//Растягиваем импульс установки прерывания
  process(p_in_rst,p_in_tmr_clk)
  begin
    if p_in_rst='1' then
      i_tmr_irq_cnt_width(i)<=(others=>'0');
      i_tmr_irq_width(i)<='0';
    elsif p_in_tmr_clk'event and p_in_tmr_clk='1' then
      if i_tmr_irq(i)='1' then
        i_tmr_irq_width(i)<='1';
      elsif i_tmr_irq_cnt_width(i)(2)='1' then--"010" then
        i_tmr_irq_width(i)<='0';
      end if;

      if i_tmr_irq_width(i)='0' then
        i_tmr_irq_cnt_width(i)<=(others=>'0');
      else
        i_tmr_irq_cnt_width(i)<=i_tmr_irq_cnt_width(i)+1;
      end if;
    end if;
  end process;

  --//Пересинхронизация флага отработки таймера
  process(p_in_rst,p_in_host_clk)
  begin
    if p_in_rst='1'then
      hclk_tmr_irq_width(i)<='0';
    elsif p_in_host_clk'event and p_in_host_clk='1' then
      hclk_tmr_irq_width(i)<=i_tmr_irq_width(i);
    end if;
  end process;

end generate gen_tmr;

p_out_tmr_rdy  <='0';
p_out_tmr_error<='0';

p_out_tmr_irq<=hclk_tmr_irq_width;


--END MAIN
end behavioral;


