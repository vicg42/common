-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.09
-- Module Name : memory_ch_arbitr
--
-- Назначение/Описание :
--  p_in_chXX_req - запрос на захват ОЗУ
--  p_out_chXX_en - разрешение захватить ОЗУ
--
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

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_def.all;
use work.memory_ctrl_pkg.all;

entity memory_ch_arbitr is
generic(
G_CH_COUNT : integer:=4
);
port(
-------------------------------
-- Связь с CH0
-------------------------------
p_in_ch0_req     : in    std_logic;
p_out_ch0_en     : out   std_logic;

p_in_ch0_bank1h  : in    std_logic_vector(15 downto 0);
p_in_ch0_ce      : in    std_logic;
p_in_ch0_cw      : in    std_logic;
p_in_ch0_rd      : in    std_logic;
p_in_ch0_wr      : in    std_logic;
p_in_ch0_term    : in    std_logic;
p_in_ch0_adr     : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_in_ch0_be      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_in_ch0_din     : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_ch0_dout   : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_out_ch0_wf     : out   std_logic;
p_out_ch0_wpf    : out   std_logic;
p_out_ch0_re     : out   std_logic;
p_out_ch0_rpe    : out   std_logic;

-------------------------------
-- Связь с CH1
-------------------------------
p_in_ch1_req     : in    std_logic;
p_out_ch1_en     : out   std_logic;

p_in_ch1_bank1h  : in    std_logic_vector(15 downto 0);
p_in_ch1_ce      : in    std_logic;
p_in_ch1_cw      : in    std_logic;
p_in_ch1_rd      : in    std_logic;
p_in_ch1_wr      : in    std_logic;
p_in_ch1_term    : in    std_logic;
p_in_ch1_adr     : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_in_ch1_be      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_in_ch1_din     : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_ch1_dout   : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_out_ch1_wf     : out   std_logic;
p_out_ch1_wpf    : out   std_logic;
p_out_ch1_re     : out   std_logic;
p_out_ch1_rpe    : out   std_logic;

-------------------------------
-- Связь с CH2
-------------------------------
p_in_ch2_req     : in    std_logic;
p_out_ch2_en     : out   std_logic;

p_in_ch2_bank1h  : in    std_logic_vector(15 downto 0);
p_in_ch2_ce      : in    std_logic;
p_in_ch2_cw      : in    std_logic;
p_in_ch2_rd      : in    std_logic;
p_in_ch2_wr      : in    std_logic;
p_in_ch2_term    : in    std_logic;
p_in_ch2_adr     : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_in_ch2_be      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_in_ch2_din     : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_ch2_dout   : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_out_ch2_wf     : out   std_logic;
p_out_ch2_wpf    : out   std_logic;
p_out_ch2_re     : out   std_logic;
p_out_ch2_rpe    : out   std_logic;

-------------------------------
-- Связь с CH3
-------------------------------
p_in_ch3_req     : in    std_logic;
p_out_ch3_en     : out   std_logic;

p_in_ch3_bank1h  : in    std_logic_vector(15 downto 0);
p_in_ch3_ce      : in    std_logic;
p_in_ch3_cw      : in    std_logic;
p_in_ch3_rd      : in    std_logic;
p_in_ch3_wr      : in    std_logic;
p_in_ch3_term    : in    std_logic;
p_in_ch3_adr     : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_in_ch3_be      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_in_ch3_din     : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_ch3_dout   : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_out_ch3_wf     : out   std_logic;
p_out_ch3_wpf    : out   std_logic;
p_out_ch3_re     : out   std_logic;
p_out_ch3_rpe    : out   std_logic;


---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_mem_clk    : out   std_logic;

p_out_mem_bank1h : out   std_logic_vector(15 downto 0);
p_out_mem_ce     : out   std_logic;
p_out_mem_cw     : out   std_logic;
p_out_mem_rd     : out   std_logic;
p_out_mem_wr     : out   std_logic;
p_out_mem_term   : out   std_logic;
p_out_mem_adr    : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be     : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din    : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout    : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf      : in    std_logic;
p_in_mem_wpf     : in    std_logic;
p_in_mem_re      : in    std_logic;
p_in_mem_rpe     : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end memory_ch_arbitr;

architecture behavioral of memory_ch_arbitr is

constant C_MEM_BANK_MSB_BIT   : integer:=pwr((C_HREG_MEM_ADR_BANK_M_BIT-C_HREG_MEM_ADR_BANK_L_BIT+1), 2)-1;

type fsm_state is
(
S_CHK_RQ_CH0,
S_CHK_DLY_CH0,

S_CHK_RQ_CH1,
S_CHK_DLY_CH1,

S_CHK_RQ_CH2,
S_CHK_DLY_CH2,

S_CHK_RQ_CH3,
S_CHK_DLY_CH3
);
signal fsm_state_cs: fsm_state;

signal i_ch_count        : std_logic_vector(1 downto 0);

signal i_ch_req          : std_logic_vector(3 downto 0);
signal i_ch_req_en       : std_logic_vector(3 downto 0);

signal i_mem_ce_ch       : std_logic_vector(3 downto 0);
signal i_mem_cw_ch       : std_logic_vector(3 downto 0);
signal i_mem_rd_ch       : std_logic_vector(3 downto 0);
signal i_mem_wr_ch       : std_logic_vector(3 downto 0);
signal i_mem_term_ch     : std_logic_vector(3 downto 0);

signal i_mem_cw_out      : std_logic;

signal tst_mem_ce        : std_logic;
signal tst_mem_cw        : std_logic;
signal tst_mem_rd        : std_logic;
signal tst_mem_wr        : std_logic;
signal tst_mem_term      : std_logic;
signal tst_enable_ch     : std_logic_vector(3 downto 0);

--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_mem_ce<='0';
    tst_mem_cw<='0';
    tst_mem_rd<='0';
    tst_mem_wr<='0';
    tst_mem_term<='0';
    tst_enable_ch<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    tst_mem_cw  <=i_mem_cw_out;
    tst_mem_ce  <=OR_reduce(i_mem_ce_ch(G_CH_COUNT-1 downto 0));
    tst_mem_rd  <=OR_reduce(i_mem_rd_ch(G_CH_COUNT-1 downto 0));
    tst_mem_wr  <=OR_reduce(i_mem_wr_ch(G_CH_COUNT-1 downto 0));
    tst_mem_term<=OR_reduce(i_mem_term_ch(G_CH_COUNT-1 downto 0));
    tst_enable_ch<=i_ch_req_en;
  end if;
end process;
p_out_tst(0)<=tst_mem_ce or tst_mem_cw or tst_mem_rd or tst_mem_wr or tst_mem_term or OR_reduce(tst_enable_ch);
p_out_tst(31 downto 1)<=(others=>'0');



--//--------------------------------------------------
--//Связь с пользовательским каналами (CHxx)
--//--------------------------------------------------
i_mem_ce_ch(0)<=p_in_ch0_ce;
i_mem_ce_ch(1)<=p_in_ch1_ce;
i_mem_ce_ch(2)<=p_in_ch2_ce;
i_mem_ce_ch(3)<=p_in_ch3_ce;

i_mem_cw_ch(0)<=p_in_ch0_cw;
i_mem_cw_ch(1)<=p_in_ch1_cw;
i_mem_cw_ch(2)<=p_in_ch2_cw;
i_mem_cw_ch(3)<=p_in_ch3_cw;

i_mem_rd_ch(0)<=p_in_ch0_rd;
i_mem_rd_ch(1)<=p_in_ch1_rd;
i_mem_rd_ch(2)<=p_in_ch2_rd;
i_mem_rd_ch(3)<=p_in_ch3_rd;

i_mem_wr_ch(0)<=p_in_ch0_wr;
i_mem_wr_ch(1)<=p_in_ch1_wr;
i_mem_wr_ch(2)<=p_in_ch2_wr;
i_mem_wr_ch(3)<=p_in_ch3_wr;

i_mem_term_ch(0)<=p_in_ch0_term;
i_mem_term_ch(1)<=p_in_ch1_term;
i_mem_term_ch(2)<=p_in_ch2_term;
i_mem_term_ch(3)<=p_in_ch3_term;

i_ch_req(0)<=p_in_ch0_req;
i_ch_req(1)<=p_in_ch1_req;
i_ch_req(2)<=p_in_ch2_req;
i_ch_req(3)<=p_in_ch3_req;


p_out_ch0_en<=i_ch_req_en(0);
p_out_ch1_en<=i_ch_req_en(1);
p_out_ch2_en<=i_ch_req_en(2);
p_out_ch3_en<=i_ch_req_en(3);

p_out_ch0_wf  <=p_in_mem_wf;
p_out_ch0_wpf <=p_in_mem_wpf;
p_out_ch0_re  <=p_in_mem_re;
p_out_ch0_rpe <=p_in_mem_rpe;

p_out_ch1_wf  <=p_in_mem_wf;
p_out_ch1_wpf <=p_in_mem_wpf;
p_out_ch1_re  <=p_in_mem_re;
p_out_ch1_rpe <=p_in_mem_rpe;

p_out_ch2_wf  <=p_in_mem_wf;
p_out_ch2_wpf <=p_in_mem_wpf;
p_out_ch2_re  <=p_in_mem_re;
p_out_ch2_rpe <=p_in_mem_rpe;

p_out_ch3_wf  <=p_in_mem_wf;
p_out_ch3_wpf <=p_in_mem_wpf;
p_out_ch3_re  <=p_in_mem_re;
p_out_ch3_rpe <=p_in_mem_rpe;

p_out_ch0_dout <=p_in_mem_dout;
p_out_ch1_dout <=p_in_mem_dout;
p_out_ch2_dout <=p_in_mem_dout;
p_out_ch3_dout <=p_in_mem_dout;



--//--------------------------------------------------
--//Связь с контроллером памяти memory_ctrl_nch.vhd
--//--------------------------------------------------
p_out_mem_clk <=p_in_clk;

p_out_mem_cw  <=i_mem_cw_out;
p_out_mem_ce  <=OR_reduce(i_mem_ce_ch(G_CH_COUNT-1 downto 0));
p_out_mem_rd  <=OR_reduce(i_mem_rd_ch(G_CH_COUNT-1 downto 0));
p_out_mem_wr  <=OR_reduce(i_mem_wr_ch(G_CH_COUNT-1 downto 0));
p_out_mem_term<=OR_reduce(i_mem_term_ch(G_CH_COUNT-1 downto 0));
p_out_mem_be  <=(others=>'1');

gen_chcount_1 : if G_CH_COUNT=1 generate
begin
p_out_mem_bank1h(C_MEM_BANK_MSB_BIT downto 0)<=p_in_ch0_bank1h(C_MEM_BANK_MSB_BIT downto 0);
p_out_mem_adr<=p_in_ch0_adr;

p_out_mem_din<=p_in_ch0_din;

i_mem_cw_out <=i_mem_cw_ch(0);

end generate gen_chcount_1;

gen_chcount_2 : if G_CH_COUNT=2 generate
begin
p_out_mem_bank1h(C_MEM_BANK_MSB_BIT downto 0)<=p_in_ch1_bank1h(C_MEM_BANK_MSB_BIT downto 0) when i_ch_req_en(1)='1' else
                                               p_in_ch0_bank1h(C_MEM_BANK_MSB_BIT downto 0);

p_out_mem_adr<=p_in_ch1_adr when i_ch_req_en(1)='1' else
               p_in_ch0_adr;

p_out_mem_din<=p_in_ch1_din when i_ch_req_en(1)='1' else
               p_in_ch0_din;

i_mem_cw_out <=i_mem_cw_ch(1) when i_ch_req_en(1)='1' else
               i_mem_cw_ch(0);

end generate gen_chcount_2;

gen_chcount_3 : if G_CH_COUNT=3 generate
begin
p_out_mem_bank1h(C_MEM_BANK_MSB_BIT downto 0)<=p_in_ch2_bank1h(C_MEM_BANK_MSB_BIT downto 0) when i_ch_req_en(2)='1' else
                                               p_in_ch1_bank1h(C_MEM_BANK_MSB_BIT downto 0) when i_ch_req_en(1)='1' else
                                               p_in_ch0_bank1h(C_MEM_BANK_MSB_BIT downto 0);

p_out_mem_adr<=p_in_ch2_adr when i_ch_req_en(2)='1' else
               p_in_ch1_adr when i_ch_req_en(1)='1' else
               p_in_ch0_adr;

p_out_mem_din<=p_in_ch2_din when i_ch_req_en(2)='1' else
               p_in_ch1_din when i_ch_req_en(1)='1' else
               p_in_ch0_din;

i_mem_cw_out <=i_mem_cw_ch(2) when i_ch_req_en(2)='1' else
               i_mem_cw_ch(1) when i_ch_req_en(1)='1' else
               i_mem_cw_ch(0);
end generate gen_chcount_3;

gen_chcount_4 : if G_CH_COUNT=4 generate
begin
p_out_mem_bank1h(C_MEM_BANK_MSB_BIT downto 0)<=p_in_ch3_bank1h(C_MEM_BANK_MSB_BIT downto 0) when i_ch_req_en(3)='1' else
                                               p_in_ch2_bank1h(C_MEM_BANK_MSB_BIT downto 0) when i_ch_req_en(2)='1' else
                                               p_in_ch1_bank1h(C_MEM_BANK_MSB_BIT downto 0) when i_ch_req_en(1)='1' else
                                               p_in_ch0_bank1h(C_MEM_BANK_MSB_BIT downto 0);

p_out_mem_adr<=p_in_ch3_adr when i_ch_req_en(3)='1' else
               p_in_ch2_adr when i_ch_req_en(2)='1' else
               p_in_ch1_adr when i_ch_req_en(1)='1' else
               p_in_ch0_adr;

p_out_mem_din<=p_in_ch3_din when i_ch_req_en(3)='1' else
               p_in_ch2_din when i_ch_req_en(2)='1' else
               p_in_ch1_din when i_ch_req_en(1)='1' else
               p_in_ch0_din;

i_mem_cw_out <=i_mem_cw_ch(3) when i_ch_req_en(3)='1' else
               i_mem_cw_ch(2) when i_ch_req_en(2)='1' else
               i_mem_cw_ch(1) when i_ch_req_en(1)='1' else
               i_mem_cw_ch(0);
end generate gen_chcount_4;

p_out_mem_bank1h(p_out_mem_bank1h'length-1 downto C_MEM_BANK_MSB_BIT+1)<=(others=>'0');



--//--------------------------------
--//Автомат управления захватом ОЗУ
--//--------------------------------
i_ch_count<=CONV_STD_LOGIC_VECTOR(G_CH_COUNT-1, i_ch_count'length);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_ch_req_en<=(others=>'0');
    fsm_state_cs <= S_CHK_RQ_CH0;

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_state_cs is
      --//------------------------------------
      --//Проверка запроса от CH0
      --//------------------------------------
      when S_CHK_RQ_CH0 =>
          if i_ch_req(0)='1' then
              i_ch_req_en(0)<='1';--//Разрешаем занять канал
          else
              --//Нет запроса
              --//преходим к анализу следующего канала
              i_ch_req_en(0)<='0';
              fsm_state_cs <= S_CHK_DLY_CH0;
          end if;

      when S_CHK_DLY_CH0 =>

        i_ch_req_en<=(others=>'0');

        if i_ch_count=CONV_STD_LOGIC_VECTOR(10#00#, i_ch_count'length) then
          fsm_state_cs <= S_CHK_RQ_CH0;
        else
          fsm_state_cs <= S_CHK_RQ_CH1;
        end if;

      --//------------------------------------
      --//Проверка запроса от CH1
      --//------------------------------------
      when S_CHK_RQ_CH1 =>

          if i_ch_req(1)='1' then
              i_ch_req_en(1)<='1';--//Разрешаем занять канал
          else
              --//Нет запроса
              --//преходим к анализу следующего канала
              i_ch_req_en(1)<='0';
              fsm_state_cs <= S_CHK_DLY_CH1;
          end if;

      when S_CHK_DLY_CH1 =>

        i_ch_req_en<=(others=>'0');

        if i_ch_count=CONV_STD_LOGIC_VECTOR(10#01#, i_ch_count'length) then
          fsm_state_cs <= S_CHK_RQ_CH0;
        else
          fsm_state_cs <= S_CHK_RQ_CH2;
        end if;

      --//------------------------------------
      --//Проверка запроса от CH2
      --//------------------------------------
      when S_CHK_RQ_CH2 =>
          if i_ch_req(2)='1' then
              i_ch_req_en(2)<='1';--//Разрешаем занять канал
          else
              --//Нет запроса
              --//преходим к анализу следующего канала
              i_ch_req_en(2)<='0';
              fsm_state_cs <= S_CHK_DLY_CH2;
          end if;

      when S_CHK_DLY_CH2 =>

        i_ch_req_en<=(others=>'0');

        if i_ch_count=CONV_STD_LOGIC_VECTOR(10#02#, i_ch_count'length) then
          fsm_state_cs <= S_CHK_RQ_CH0;
        else
          fsm_state_cs <= S_CHK_RQ_CH3;
        end if;

      --//------------------------------------
      --//Проверка запроса от CH3
      --//------------------------------------
      when S_CHK_RQ_CH3 =>
          if i_ch_req(3)='1' then
              i_ch_req_en(3)<='1';--//Разрешаем занять канал
          else
              --//Нет запроса
              --//преходим к анализу следующего канала
              i_ch_req_en(3)<='0';
              fsm_state_cs <= S_CHK_DLY_CH3;
          end if;

      when S_CHK_DLY_CH3 =>

        i_ch_req_en<=(others=>'0');
        fsm_state_cs <= S_CHK_RQ_CH0;

--        if i_ch_count=CONV_STD_LOGIC_VECTOR(10#03#, i_ch_count'length) then
--          fsm_state_cs <= S_CHK_RQ_CH0;
--        else
--          fsm_state_cs <= S_CHK_CH4_RQ;
--        end if;

    end case;
  end if;
end process;

--END MAIN
end behavioral;

