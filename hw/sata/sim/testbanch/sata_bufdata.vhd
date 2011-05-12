-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.03.2011 9:26:27
-- Module Name : sata_databuf
--
-- Description :
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

use ieee.std_logic_textio.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_pkg.all;
use work.sata_sim_lite_pkg.all;


entity sata_sim_dbuf is
port
(
----------------------------
--
----------------------------
p_in_data    : in    std_logic_vector(31 downto 0);
p_in_wr      : in    std_logic;
p_in_wclk    : in    std_logic;

p_out_data   : out   std_logic_vector(31 downto 0);
p_in_rd      : in    std_logic;
p_in_rclk    : in    std_logic;

p_out_status : out   TSimDBufStatus;
p_in_ctrl    : in    TSimDBufCtrl;

p_out_simbuf : out   TSimBufData;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst     : in    std_logic_vector(31 downto 0);
p_out_tst    : out   std_logic_vector(31 downto 0);

----------------------------
--System
----------------------------
p_in_rst                    : in    std_logic
);
end sata_sim_dbuf;

architecture behavior of sata_sim_dbuf is

constant C_CLK_PERIOD_TXBUF       : TIME := 6.6*2 ns;
constant C_CLK_PERIOD_RXBUF       : TIME := 6.6*2 ns;

signal i_dbuf                     : TSimBufData;
signal i_dbuf_rcnt                : integer;
signal i_dbuf_wcnt                : integer;

signal i_rxbuf_clk                : std_logic;
signal i_rxbuf_dout               : std_logic_vector(31 downto 0);
signal i_rxbuf_dout_rd            : std_logic;
signal i_rxbuf_done_rd            : std_logic;
signal i_rxbuf_wen                : std_logic;
signal i_rxbuf_pfull              : std_logic;
signal i_rxbuf_empty              : std_logic;

signal i_txbuf_clk                : std_logic;
signal i_txbuf_din                : std_logic_vector(31 downto 0);
signal i_txbuf_din_wd             : std_logic;
signal i_txbuf_ren                : std_logic;
signal i_txbuf_empty              : std_logic;

type TCntValue is array (0 to 3) of integer;
constant C_VALUE1                 : TCntValue :=(2,3,6,2);
constant C_VALUE2                 : TCntValue :=(3,4,2,7);
signal i_cntval                   : std_logic_vector(1 downto 0);

signal i_rdcnt                    : integer;
signal i_wdcnt                    : integer;


--MAIN
begin

p_out_tst<=(others=>'0');


m_rxbuf : sata_rxfifo
port map
(
din        => p_in_data,
wr_en      => p_in_wr,
wr_clk     => p_in_wclk,

dout       => i_rxbuf_dout,
rd_en      => i_rxbuf_dout_rd,
rd_clk     => i_rxbuf_clk,

wr_data_count => open,

full        => open,
prog_full   => i_rxbuf_pfull,
empty       => i_rxbuf_empty,

rst        => p_in_rst
);

m_txbuf : sata_txfifo
port map
(
din        => i_txbuf_din,
wr_en      => i_txbuf_din_wd,
wr_clk     => i_txbuf_clk,

dout       => p_out_data,
rd_en      => p_in_rd,
rd_clk     => p_in_rclk,

full        => open,--i_txbuf_full,
prog_full   => open,--i_txbuf_pfull,
empty       => i_txbuf_empty,
almost_empty=> open, --i_txbuf_aempty,

rst        => p_in_rst
);

gen_rxbuf_clk : process
begin
  i_rxbuf_clk<='0';
  wait for C_CLK_PERIOD_RXBUF/2;
  i_rxbuf_clk<='1';
  wait for C_CLK_PERIOD_RXBUF/2;
end process;

gen_txbuf_clk : process
begin
  i_txbuf_clk<='0';
  wait for C_CLK_PERIOD_TXBUF/2;
  i_txbuf_clk<='1';
  wait for C_CLK_PERIOD_TXBUF/2;
end process;

p_out_status.rx.full<=i_rxbuf_pfull;
p_out_status.rx.empty<=i_rxbuf_empty;
p_out_status.rx.done<=i_rxbuf_done_rd;
p_out_status.rx.en<=i_rxbuf_wen;

p_out_status.tx.full<='0';--i_txbuf_pfull;
p_out_status.tx.empty<='0';--i_txbuf_empty;
p_out_status.tx.done<='0';
p_out_status.tx.en<=i_txbuf_ren;

p_out_simbuf<=i_dbuf;

--//Чтение данных из RxFIFO и запись в i_dbuf
lwrite:process
  variable idx: integer:=0;
  variable empty:std_logic:='1';
begin
  i_rxbuf_done_rd<='0';
  i_rxbuf_dout_rd<='0';
  i_dbuf_rcnt<=0;
  idx:=0;
  empty:='1';

  while true loop

    --//Ждем сигнала начала чтения RxFIFO
    wait until p_in_ctrl.wstart='1';
      i_rxbuf_done_rd<='0';
      i_rxbuf_dout_rd<='0';
      idx:=0;
      wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
      i_dbuf_rcnt<=p_in_ctrl.trnsize-1;

      wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
      i_dbuf_rcnt<=p_in_ctrl.trnsize-1;

      --//Чтение данных из RxFIFO
      while i_dbuf_rcnt/=0 loop
        empty:='1';
        while empty='1' loop
          wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
            empty:=i_rxbuf_empty;
        end loop;

--        wait for 0.2 us;

        wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
        i_rxbuf_dout_rd<='1';
        wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
        i_rxbuf_dout_rd<='0';

        wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
        i_dbuf(idx)<=i_rxbuf_dout;
        idx:=idx+1;
        i_dbuf_rcnt<=i_dbuf_rcnt-1;

      end loop;

      i_dbuf_rcnt<=0;
      --//Сигнализация о завершении вычетки всех данных транзакци
      wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
      i_rxbuf_done_rd<='1';


  end loop;

end process lwrite;

--//Разрешение записи данных в RxFIFO
lwen:process
--  variable i_rdcnt:integer:=0;
  variable dbuf_cnt:integer:=0;
begin
  i_rxbuf_wen<='0';
  i_rdcnt<=0;

  i_cntval<=(others=>'0');

  while true loop

    wait until p_in_ctrl.wstart='1';

      i_rxbuf_wen<='1';
      i_rdcnt<=0;

      wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
      dbuf_cnt:=i_dbuf_rcnt;
      wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
      dbuf_cnt:=i_dbuf_rcnt;

      while dbuf_cnt>20 loop

        --//Задержка перед отправкой примитива HOLD
        ldly1:while i_rdcnt/=C_VALUE1(CONV_INTEGER(i_cntval)) loop
            wait until i_rxbuf_dout_rd = '1' or i_rxbuf_empty='1';--//Жду одно из событий
              exit ldly1 when i_rxbuf_empty='1';--//Выход из цикла

            wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
            i_rdcnt<=i_rdcnt + 1;
        end loop ldly1;


        if i_rxbuf_empty='1' then
        --//В буфере нет данных. Разрешаю ХОСТУ передовать данные
            i_rdcnt<=0;--//
            wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
            i_rxbuf_wen<='1';
            i_rdcnt<=0;
            dbuf_cnt:=i_dbuf_rcnt;
            i_cntval<=i_cntval + 1;

        else
        --//В буфере есть данные. Сигнализируем ХОСТУ об перекращении передачи данных - Отправляем комаду HOLD
            i_rdcnt<=0;--//
            wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
            if i_rxbuf_empty='0' then
              i_rxbuf_wen<='0';--//Запрещаю ХОСТУ передовать данные. Отправка примитива HOLD
              i_rdcnt<=0;--//

              ldly2:while i_rdcnt/=C_VALUE2(CONV_INTEGER(i_cntval)) loop
                  wait until i_rxbuf_dout_rd = '1' or i_rxbuf_empty='1';--//Жду одно из событий
                    exit ldly2 when i_rxbuf_empty='1';

                  wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
                  i_rdcnt<=i_rdcnt + 1;
              end loop ldly2;

              i_rdcnt<=0;
              wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
              i_rxbuf_wen<='1';--//Разрешаю ХОСТУ передовать данные
              dbuf_cnt:=i_dbuf_rcnt;
              i_rdcnt<=0;
              i_cntval<=i_cntval + 1;
            end if;
        end if;

      end loop;

      wait until i_rxbuf_clk'event and i_rxbuf_clk = '1';
      i_rxbuf_wen<='1';--//Разрешаю ХОСТУ передовать данные

      wait until p_in_ctrl.wdone_clr='1';
      i_rxbuf_wen<='0';

  end loop;

end process lwen;




--//Запись данных в TxFIFO и чтение из i_dbuf
lread:process
  variable idx: integer:=0;

begin
  i_txbuf_din_wd<='0';
  i_txbuf_din<=(others=>'0');
  i_txbuf_ren<='0';
  i_dbuf_wcnt<=0;
  i_wdcnt<=0;
  idx:=0;

  while true loop

    --//Ждем сигнала начала чтения TxFIFO
    wait until p_in_ctrl.rstart='1';

      idx:=0;
      wait until i_txbuf_clk'event and i_txbuf_clk = '1';
      i_dbuf_wcnt<=p_in_ctrl.trnsize-1;

      wait until i_txbuf_clk'event and i_txbuf_clk = '1';
      i_dbuf_wcnt<=p_in_ctrl.trnsize-1;

      --//Запись данных в TxFIFO
      while i_dbuf_wcnt/=0 loop

        wait until i_txbuf_clk'event and i_txbuf_clk = '1';
        i_txbuf_din<=i_dbuf(idx);

        wait until i_txbuf_clk'event and i_txbuf_clk = '1';
        i_txbuf_din_wd<='1';
        wait until i_txbuf_clk'event and i_txbuf_clk = '1';
        i_txbuf_din_wd<='0';

        if i_dbuf_wcnt>20 then

          wait until i_txbuf_clk'event and i_txbuf_clk = '1';
          i_wdcnt<=i_wdcnt + 1;
          i_dbuf_wcnt<=i_dbuf_wcnt-1;
          idx:=idx+1;

          while i_wdcnt/=10 loop
              wait until i_txbuf_clk'event and i_txbuf_clk = '1';
              i_txbuf_din<=i_dbuf(idx);

              wait until i_txbuf_clk'event and i_txbuf_clk = '1';
              i_txbuf_din_wd<='1';
              wait until i_txbuf_clk'event and i_txbuf_clk = '1';
              i_txbuf_din_wd<='0';

              i_wdcnt<=i_wdcnt + 1;
              i_dbuf_wcnt<=i_dbuf_wcnt-1;
              idx:=idx+1;
          end loop;

          wait until i_txbuf_clk'event and i_txbuf_clk = '1';
            i_txbuf_ren<='1';--//Разрешаю хосту чтение буфера
            i_wdcnt<=0;

          wait until i_txbuf_empty='1';
            i_txbuf_ren<='0';--//Запрешаю хосту чтение буфера

        else

          wait until i_txbuf_clk'event and i_txbuf_clk = '1';
          i_dbuf_wcnt<=i_dbuf_wcnt-1;
          idx:=idx+1;
        end if;

      end loop;

      i_dbuf_wcnt<=0;
      --//Сигнализация о завершении вычетки всех данных транзакци
      wait until i_txbuf_clk'event and i_txbuf_clk = '1';
      i_txbuf_ren<='1';

      wait until p_in_ctrl.wdone_clr='1';
      i_txbuf_ren<='0';

  end loop;

end process lread;






--End MAIN
end;


