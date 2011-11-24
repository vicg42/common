-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.09
-- Module Name : mem_arb
--
-- Назначение/Описание :
--  Арбитр достпупа к ОЗУ
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
use work.mem_glob_pkg.all;
use work.mem_wr_pkg.all;

entity mem_arb is
generic(
G_CH_COUNT   : integer:=4;
G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
port(
-------------------------------
--Связь с пользователями ОЗУ
-------------------------------
p_in_memch  : in   TMemINCh;
p_out_memch : out  TMemOUTCh;

-------------------------------
--Связь с mem_ctrl.vhd
-------------------------------
p_out_mem   : out   TMemIN;
p_in_mem    : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst    : in    std_logic_vector(31 downto 0);
p_out_tst   : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk    : in    std_logic;
p_in_rst    : in    std_logic
);
end mem_arb;

architecture behavioral of mem_arb is

type fsm_state is (
S_CHK_RQ_CH0,
S_CHK_DLY_CH0,

S_CHK_RQ_CH1,
S_CHK_DLY_CH1,

S_CHK_RQ_CH2,
S_CHK_DLY_CH2,

S_CHK_RQ_CH3,
S_CHK_DLY_CH3,

S_CHK_RQ_CH4,
S_CHK_DLY_CH4
);
signal fsm_state_cs: fsm_state;

signal i_mem_req      : std_logic_vector(C_MEMCH_COUNT_MAX-1 downto 0);-- запрос на захват ОЗУ
signal i_mem_req_en   : std_logic_vector(C_MEMCH_COUNT_MAX-1 downto 0);-- разрешение захвата ОЗУ
signal i_mem_ce       : std_logic_vector(C_MEMCH_COUNT_MAX-1 downto 0);
signal i_mem_cw       : std_logic_vector(C_MEMCH_COUNT_MAX-1 downto 0);
signal i_mem_rd       : std_logic_vector(C_MEMCH_COUNT_MAX-1 downto 0);
signal i_mem_wr       : std_logic_vector(C_MEMCH_COUNT_MAX-1 downto 0);
signal i_mem_term     : std_logic_vector(C_MEMCH_COUNT_MAX-1 downto 0);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');



--//--------------------------------------------------
--//Связь с пользовательским каналами (CHxx)
--//--------------------------------------------------
gen_ch : for i in 0 to G_CH_COUNT-1 generate
i_mem_req (i)<=p_in_memch(i).req;
i_mem_cw  (i)<=p_in_memch(i).cw and i_mem_req_en(i);
i_mem_ce  (i)<=p_in_memch(i).ce;
i_mem_wr  (i)<=p_in_memch(i).wr;
i_mem_rd  (i)<=p_in_memch(i).rd;
i_mem_term(i)<=p_in_memch(i).term;

p_out_memch(i).req_en <=i_mem_req_en(i);
p_out_memch(i).data   <=p_in_mem.data;
p_out_memch(i).buf_wpf<=p_in_mem.buf_wpf;
p_out_memch(i).buf_re <=p_in_mem.buf_re;

end generate gen_ch;

gen_ch_nomax : if G_CH_COUNT/=C_MEMCH_COUNT_MAX-1 generate
  gen_ch_remain : for i in G_CH_COUNT to C_MEMCH_COUNT_MAX-1 generate
  i_mem_req(i)<='0';
  end generate gen_ch_remain;
end generate gen_ch_nomax;



--//--------------------------------------------------
--//Связь с контроллером памяти mem_ctrl.vhd
--//--------------------------------------------------
p_out_mem.clk <=p_in_clk;
p_out_mem.cw  <=OR_reduce(i_mem_cw(G_CH_COUNT-1 downto 0));
p_out_mem.ce  <=OR_reduce(i_mem_ce(G_CH_COUNT-1 downto 0));
p_out_mem.wr  <=OR_reduce(i_mem_wr(G_CH_COUNT-1 downto 0));
p_out_mem.rd  <=OR_reduce(i_mem_rd(G_CH_COUNT-1 downto 0));
p_out_mem.term<=OR_reduce(i_mem_term(G_CH_COUNT-1 downto 0));
p_out_mem.dbe <=(others=>'1');

gen_chcount_1 : if G_CH_COUNT=1 generate

p_out_mem.bank<=p_in_memch(0).bank;
p_out_mem.adr <=p_in_memch(0).adr;
p_out_mem.data<=p_in_memch(0).data;

end generate gen_chcount_1;

gen_chcount_2 : if G_CH_COUNT=2 generate

p_out_mem.bank<=p_in_memch(1).bank when i_mem_req_en(1)='1' else
                p_in_memch(0).bank;

p_out_mem.adr<=p_in_memch(1).adr when i_mem_req_en(1)='1' else
               p_in_memch(0).adr;

p_out_mem.data<=p_in_memch(1).data when i_mem_req_en(1)='1' else
                p_in_memch(0).data;

end generate gen_chcount_2;

gen_chcount_3 : if G_CH_COUNT=3 generate

p_out_mem.bank<=p_in_memch(2).bank when i_mem_req_en(2)='1' else
                p_in_memch(1).bank when i_mem_req_en(1)='1' else
                p_in_memch(0).bank;

p_out_mem.adr<=p_in_memch(2).adr when i_mem_req_en(2)='1' else
               p_in_memch(1).adr when i_mem_req_en(1)='1' else
               p_in_memch(0).adr;

p_out_mem.data<=p_in_memch(2).data when i_mem_req_en(2)='1' else
                p_in_memch(1).data when i_mem_req_en(1)='1' else
                p_in_memch(0).data;

end generate gen_chcount_3;

gen_chcount_4 : if G_CH_COUNT=4 generate

p_out_mem.bank<=p_in_memch(3).bank when i_mem_req_en(3)='1' else
                p_in_memch(2).bank when i_mem_req_en(2)='1' else
                p_in_memch(1).bank when i_mem_req_en(1)='1' else
                p_in_memch(0).bank;

p_out_mem.adr<=p_in_memch(3).adr when i_mem_req_en(3)='1' else
               p_in_memch(2).adr when i_mem_req_en(2)='1' else
               p_in_memch(1).adr when i_mem_req_en(1)='1' else
               p_in_memch(0).adr;

p_out_mem.data<=p_in_memch(3).data when i_mem_req_en(3)='1' else
                p_in_memch(2).data when i_mem_req_en(2)='1' else
                p_in_memch(1).data when i_mem_req_en(1)='1' else
                p_in_memch(0).data;

end generate gen_chcount_4;

gen_chcount_5 : if G_CH_COUNT=5 generate

p_out_mem.bank<=p_in_memch(4).bank when i_mem_req_en(4)='1' else
                p_in_memch(3).bank when i_mem_req_en(3)='1' else
                p_in_memch(2).bank when i_mem_req_en(2)='1' else
                p_in_memch(1).bank when i_mem_req_en(1)='1' else
                p_in_memch(0).bank;

p_out_mem.adr<=p_in_memch(4).adr when i_mem_req_en(4)='1' else
               p_in_memch(3).adr when i_mem_req_en(3)='1' else
               p_in_memch(2).adr when i_mem_req_en(2)='1' else
               p_in_memch(1).adr when i_mem_req_en(1)='1' else
               p_in_memch(0).adr;

p_out_mem.data<=p_in_memch(4).data when i_mem_req_en(4)='1' else
                p_in_memch(3).data when i_mem_req_en(3)='1' else
                p_in_memch(2).data when i_mem_req_en(2)='1' else
                p_in_memch(1).data when i_mem_req_en(1)='1' else
                p_in_memch(0).data;

end generate gen_chcount_5;


--//--------------------------------
--//Автомат управления захватом ОЗУ
--//--------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_mem_req_en<=(others=>'0');
    fsm_state_cs <= S_CHK_RQ_CH0;

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_state_cs is
      --//------------------------------------
      --//Проверка запроса от CH0
      --//------------------------------------
      when S_CHK_RQ_CH0 =>
          if i_mem_req(0)='1' then
            i_mem_req_en(0)<='1';--//Разрешаем занять ОЗУ
          else
            i_mem_req_en(0)<='0';
            fsm_state_cs <= S_CHK_DLY_CH0;
          end if;

      when S_CHK_DLY_CH0 =>

        i_mem_req_en<=(others=>'0');
        fsm_state_cs <= S_CHK_RQ_CH1;

      --//------------------------------------
      --//Проверка запроса от CH1
      --//------------------------------------
      when S_CHK_RQ_CH1 =>

          if i_mem_req(1)='1' then
            i_mem_req_en(1)<='1';--//Разрешаем занять ОЗУ
          else
            i_mem_req_en(1)<='0';
            fsm_state_cs <= S_CHK_DLY_CH1;
          end if;

      when S_CHK_DLY_CH1 =>

        i_mem_req_en<=(others=>'0');
        fsm_state_cs <= S_CHK_RQ_CH2;

      --//------------------------------------
      --//Проверка запроса от CH2
      --//------------------------------------
      when S_CHK_RQ_CH2 =>
          if i_mem_req(2)='1' then
            i_mem_req_en(2)<='1';--//Разрешаем занять ОЗУ
          else
            i_mem_req_en(2)<='0';
            fsm_state_cs <= S_CHK_DLY_CH2;
          end if;

      when S_CHK_DLY_CH2 =>

        i_mem_req_en<=(others=>'0');
        fsm_state_cs <= S_CHK_RQ_CH3;

      --//------------------------------------
      --//Проверка запроса от CH3
      --//------------------------------------
      when S_CHK_RQ_CH3 =>
          if i_mem_req(3)='1' then
            i_mem_req_en(3)<='1';--//Разрешаем занять ОЗУ
          else
            i_mem_req_en(3)<='0';
            fsm_state_cs <= S_CHK_DLY_CH3;
          end if;

      when S_CHK_DLY_CH3 =>

        i_mem_req_en<=(others=>'0');
        fsm_state_cs <= S_CHK_RQ_CH4;

      --//------------------------------------
      --//Проверка запроса от CH4
      --//------------------------------------
      when S_CHK_RQ_CH4 =>
          if i_mem_req(4)='1' then
            i_mem_req_en(4)<='1';--//Разрешаем занять ОЗУ
          else
            i_mem_req_en(4)<='0';
            fsm_state_cs <= S_CHK_DLY_CH4;
          end if;

      when S_CHK_DLY_CH4 =>

        i_mem_req_en<=(others=>'0');
        fsm_state_cs <= S_CHK_RQ_CH0;

    end case;
  end if;
end process;

--END MAIN
end behavioral;

