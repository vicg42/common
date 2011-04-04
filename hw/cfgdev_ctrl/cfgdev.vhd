-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : cfgdev
--
-- Назначение/Описание :
--  Запись/Чтение регистров устройств
--
--//Структура пакета :
--0/ (15..8)-AdrDev, 7-W/R,6-FIFO(1/0 - Инкр. Адреса запрещен/разрешен)(5..4)-Reserv,(3..0)-idx_pkt
--1/ (15..8)-DataLen,(7..0)-AdresReg,
--2/ (31 downto 0) -Data0
--3/ (31 downto 0) -Data1
--n/ (31 downto 0) -DataN
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

use work.cfgdev_pkg.all;

entity cfgdev is
port
(
-------------------------------
--Связь с Хостом
-------------------------------
p_in_host_clk         : in   std_logic;                      --//

p_out_module_rdy      : out  std_logic;                      --//
p_out_module_error    : out  std_logic;                      --//

p_out_host_rxbuf_rdy  : out  std_logic;                      --//
p_out_host_rxdata     : out  std_logic_vector(31 downto 0);  --//
p_in_host_rd          : in   std_logic;                      --//

p_out_host_txbuf_rdy  : out  std_logic;                      --//
p_in_host_txdata      : in   std_logic_vector(31 downto 0);  --//
p_in_host_wd          : in   std_logic;                      --//
p_in_host_txdata_rdy  : in   std_logic;                      --//

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_dev_adr         : out  std_logic_vector(7 downto 0);  --//
p_out_cfg_adr         : out  std_logic_vector(7 downto 0);  --//
p_out_cfg_adr_ld      : out  std_logic;                     --//
p_out_cfg_adr_fifo    : out  std_logic;                     --//
p_out_cfg_wd          : out  std_logic;                     --//
p_out_cfg_rd          : out  std_logic;                     --//
p_out_cfg_txdata      : out  std_logic_vector(15 downto 0); --//
p_in_cfg_rxdata       : in   std_logic_vector(15 downto 0); --//

p_out_cfg_rx_set_irq  : out  std_logic;                     --//
p_out_cfg_done        : out  std_logic;                     --//
p_in_cfg_clk          : in   std_logic;                     --//

-------------------------------
--Технологический
-------------------------------
p_out_tst                  : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst     : in    std_logic
);
end cfgdev;

architecture behavioral of cfgdev is

type fsm_state is
(
S_IDLE,
S_READ_HEADERDATA,
S_LD_DLEN,
S_COUNT_DATA
);
signal fsm_state_cs: fsm_state;

signal i_host_txdata                    : std_logic_vector(31 downto 0);  --//
signal i_host_rxdata                    : std_logic_vector(31 downto 0);  --//

signal i_dev_adr                        : std_logic_vector(7 downto 0);
signal i_dev_wr                         : std_logic;
signal i_reg_adr                        : std_logic_vector(7 downto 0);
signal i_reg_adr_ld                     : std_logic;
signal i_reg_adr_fifo                   : std_logic;
signal i_cfg_done                       : std_logic;

signal i_cntlen                         : std_logic_vector(7 downto 0);
signal i_cntlen_dload                   : std_logic_vector(7 downto 0);

signal i_module_busy                    : std_logic;
signal i_txbuf_rd                       : std_logic;
signal i_txbuf_dout_tmp                 : std_logic_vector(31 downto 0);
signal i_txbuf_dout                     : std_logic_vector(15 downto 0);
signal i_txbuf_dout_delay               : std_logic_vector(15 downto 0);
signal i_txbuf_empty                    : std_logic;

signal i_rxbuf_din                      : std_logic_vector(31 downto 0);--(15 downto 0);--
signal i_rxbuf_wd                       : std_logic;
signal i_rxbuf_empty                    : std_logic;

signal i_pkt_data_wd                    : std_logic;
signal i_pkt_data_wd_delay1             : std_logic;
signal i_pkt_data_wd_delay2             : std_logic;
signal i_pkt_data_rd                    : std_logic;
signal i_pkt_data_rd_delay1             : std_logic;
signal i_pkt_header_rd                  : std_logic;
signal i_pkt_header_rd_delay1           : std_logic;
signal i_pkt_header_wd                  : std_logic;

signal i_pkt_data_wr_done               : std_logic;

signal i_host_txdata_rdy                : std_logic;
signal i_host_txdata_rdy_del            : std_logic;
signal i_start                          : std_logic;

signal i_host_rxbuf_rdy                 : std_logic;
signal i_host_rxbuf_rdy_dly0            : std_logic;
signal i_host_rxbuf_rdy_dly1            : std_logic;
signal i_host_rxbuf_rdy_edge            : std_logic;


--signal tst_fsm_state_cs                 : std_logic_vector(1 downto 0);
--signal tst_fsm_state_cs_dly             : std_logic_vector(1 downto 0);

--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');
--process(p_in_rst,p_in_cfg_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(0)<='0';
--
--    tst_fsm_state_cs_dly<=(others=>'0');
--
--  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
--
--    tst_fsm_state_cs_dly<=tst_fsm_state_cs;
--
--    p_out_tst(0)<=OR_reduce(tst_fsm_state_cs_dly);
--
--  end if;
--end process;
--p_out_tst(31 downto 1)<=(others=>'0');
--
--tst_fsm_state_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fsm_state_cs'length) when fsm_state_cs=S_READ_HEADERDATA else
--                  CONV_STD_LOGIC_VECTOR(16#02#, tst_fsm_state_cs'length) when fsm_state_cs=S_LD_DLEN else
--                  CONV_STD_LOGIC_VECTOR(16#03#, tst_fsm_state_cs'length) when fsm_state_cs=S_COUNT_DATA else
--                  CONV_STD_LOGIC_VECTOR(16#00#, tst_fsm_state_cs'length); --//when fsm_state_cs=S_TRC_IDLE else





p_out_module_rdy<=not p_in_rst;
p_out_module_error<='0';

p_out_cfg_rx_set_irq<=i_host_rxbuf_rdy_edge;

p_out_dev_adr     <= i_dev_adr;
p_out_cfg_adr     <= i_reg_adr;
p_out_cfg_adr_ld  <= i_reg_adr_ld;
p_out_cfg_adr_fifo<= i_reg_adr_fifo;
p_out_cfg_wd      <= i_pkt_data_rd_delay1;

process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    i_pkt_data_rd_delay1<='0';
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    i_pkt_data_rd_delay1<=i_pkt_data_rd;
  end if;
end process;

p_out_cfg_rd     <=i_pkt_data_wd_delay1;

p_out_cfg_done<=i_cfg_done;
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    i_cfg_done<='0';
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    i_cfg_done<=i_pkt_data_wr_done;
  end if;
end process;


p_out_cfg_txdata<=i_txbuf_dout;

p_out_host_txbuf_rdy<=not i_module_busy;
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    i_module_busy<='0';
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if i_cfg_done='1' then
      i_module_busy<='0';
    elsif i_pkt_header_rd='1' then
      i_module_busy<='1';
    end if;
  end if;
end process;

process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    i_host_txdata_rdy<='0';
    i_host_txdata_rdy_del<='0';
    i_start<='0';
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    i_host_txdata_rdy<=p_in_host_txdata_rdy;
    i_host_txdata_rdy_del<=i_host_txdata_rdy;

    if i_host_txdata_rdy_del='0' and i_host_txdata_rdy='1' then
      i_start<='1';
    elsif fsm_state_cs = S_READ_HEADERDATA then
      i_start<='0';
    end if;
  end if;
end process;

--//Автомат управления
fsm:process(p_in_rst,p_in_cfg_clk)
begin

if p_in_rst='1' then

  fsm_state_cs <= S_IDLE;

  i_pkt_header_rd<='0';
  i_pkt_data_rd<='0';
  i_pkt_data_wd<='0';
  i_pkt_data_wr_done<='0';

elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
--  if clk_en='1' then

  case fsm_state_cs is

    when S_IDLE =>

      i_pkt_data_wr_done<='0';

      if i_txbuf_empty='0' and i_start='1' then --p_in_host_txdata_rdy='1' then
        fsm_state_cs <= S_READ_HEADERDATA;
        i_pkt_header_rd<='1';
      else
        fsm_state_cs <= S_IDLE;
      end if;

    when S_READ_HEADERDATA =>

--      if i_cntlen(1 downto 0)=CONV_STD_LOGIC_VECTOR(16#01#, 2)  then
      if i_cntlen(1 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGPKT_HEADER_DW_COUNT-1, 2)  then
          fsm_state_cs <= S_LD_DLEN;
          i_pkt_header_rd<='0';
      else
        fsm_state_cs <= S_READ_HEADERDATA;
      end if;

    when S_LD_DLEN =>

      if i_txbuf_dout(15 downto 8)=CONV_STD_LOGIC_VECTOR(16#00#, 8)  then
        fsm_state_cs <= S_IDLE;
      else
        fsm_state_cs <= S_COUNT_DATA;
        if i_dev_wr=C_CFGPKT_ACT_WD then
          i_pkt_data_rd<='1';
        else
          i_pkt_data_wd<='1';
        end if;
      end if;

    when S_COUNT_DATA =>

      if i_cntlen=CONV_STD_LOGIC_VECTOR(16#01#, 8)  then
        i_pkt_data_rd<='0';
        i_pkt_data_wd<='0';
        i_pkt_data_wr_done<='1';
        fsm_state_cs <= S_IDLE;
      else
        fsm_state_cs <= S_COUNT_DATA;
      end if;

  end case;
--  end if;
end if;
end process fsm;

--//Счетчик чтения/записи данных tx/rx буферов
i_cntlen_dload<=i_txbuf_dout(15 downto 8) when fsm_state_cs=S_LD_DLEN else CONV_STD_LOGIC_VECTOR(C_CFGPKT_HEADER_DW_COUNT, i_cntlen_dload'length);
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    i_cntlen<=(others=>'0');
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if fsm_state_cs=S_IDLE or fsm_state_cs=S_LD_DLEN then
        i_cntlen<=i_cntlen_dload;
    else
      if fsm_state_cs=S_READ_HEADERDATA or fsm_state_cs=S_COUNT_DATA then
        i_cntlen<=i_cntlen-1;
      end if;
    end if;
  end if;
end process;

--//Сохроняем заначения заготолка пакета принятого от Хоста
--//i_dev_adr    - Адреса устройства к которому будемт производиться обращение
--//i_dev_wr     - тип производимого действия с устр-вом (0/1 - запись/чтение)
--//i_reg_adr    - Адрес регистра от которого будет производиться запись/чтение
--//i_reg_adr_ld - Сигнал загрузки Адрес регистра
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    i_dev_adr<=(others=>'0');
    i_dev_wr<='0';
    i_reg_adr<=(others=>'0');
    i_reg_adr_ld<='0';
    i_reg_adr_fifo<='0';
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
--    if  fsm_state_cs=S_READ_HEADERDATA and i_cntlen(1 downto 0)=CONV_STD_LOGIC_VECTOR(16#01#, 2) then
    if  fsm_state_cs=S_READ_HEADERDATA and i_cntlen(1 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGPKT_HEADER_DW_COUNT-1, 2) then
      i_dev_adr     <=i_txbuf_dout(C_CFGPKT_NUMDEV_MSB_BIT downto C_CFGPKT_NUMDEV_LSB_BIT);
      i_dev_wr      <=i_txbuf_dout(C_CFGPKT_WR_BIT);
      i_reg_adr_fifo<=i_txbuf_dout(C_CFGPKT_FIFO_BIT);

    elsif fsm_state_cs=S_LD_DLEN then
      i_reg_adr<=i_txbuf_dout(C_CFGPKT_NUMREG_MSB_BIT downto C_CFGPKT_NUMREG_LSB_BIT);
      i_reg_adr_ld<='1';
    else
      i_reg_adr_ld<='0';
    end if;
  end if;
end process;

--//------------------------------------------------
--//Согласующий буфер Хост->Уст-во
--//------------------------------------------------
i_host_txdata(31 downto 0)<=p_in_host_txdata(31 downto 0);

m_txfifo : cfgdev_txfifo
port map
(
din     => i_host_txdata,
wr_en   => p_in_host_wd,
wr_clk  => p_in_host_clk,

dout    => i_txbuf_dout_tmp(31 downto 0),--i_txbuf_dout(15 downto 0),--
rd_en   => i_txbuf_rd,
rd_clk  => p_in_cfg_clk,

empty   => i_txbuf_empty,
full    => open,

--  clk     => p_in_cfg_clk,
rst     => p_in_rst
);

i_txbuf_dout(15 downto 0)<=i_txbuf_dout_tmp(15 downto 0);

i_txbuf_rd<=i_pkt_header_rd or i_pkt_data_rd;

--//------------------------------------------------
--//Согласующий буфер Уст-во->Хост
--//------------------------------------------------
p_out_host_rxdata(31 downto 0)<=i_host_rxdata(31 downto 0);

m_rxfifo : cfgdev_rxfifo
port map
(
din     => i_rxbuf_din,
wr_en   => i_rxbuf_wd,
wr_clk  => p_in_cfg_clk,

dout    => i_host_rxdata,
rd_en   => p_in_host_rd,
rd_clk  => p_in_host_clk,

empty   => i_rxbuf_empty,
full    => open,

--  clk     => p_in_cfg_clk,
rst     => p_in_rst
);

--  p_out_host_rxdata(31 downto 16) <=(others=>'0');

p_out_host_rxbuf_rdy<=i_host_rxbuf_rdy;
i_host_rxbuf_rdy<=not i_rxbuf_empty when fsm_state_cs=S_IDLE and i_dev_wr=C_CFGPKT_ACT_RD else '0';

--//Задержки необходимые для формирования сигнала установки прерывания
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    i_host_rxbuf_rdy_dly0<='0';
    i_host_rxbuf_rdy_dly1<='0';
    i_host_rxbuf_rdy_edge<='0';
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    i_host_rxbuf_rdy_dly0<=i_host_rxbuf_rdy;
    i_host_rxbuf_rdy_dly1<=i_host_rxbuf_rdy_dly0;
    i_host_rxbuf_rdy_edge<=i_host_rxbuf_rdy_dly0 and not i_host_rxbuf_rdy_dly1;
  end if;
end process;


--//Задержки необходимые для формирования сигналов запсии в rxbuf
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    i_txbuf_dout_delay<=(others=>'0');

    i_pkt_header_wd<='0';
    i_pkt_header_rd_delay1<='0';

    i_pkt_data_wd_delay1<='0';
    i_pkt_data_wd_delay2<='0';
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    i_txbuf_dout_delay<=i_txbuf_dout;

    i_pkt_header_rd_delay1<=i_pkt_header_rd;
    i_pkt_header_wd<=i_pkt_header_rd_delay1;

    i_pkt_data_wd_delay1<=i_pkt_data_wd;
    i_pkt_data_wd_delay2<=i_pkt_data_wd_delay1;
  end if;
end process;

--//Формируем пакет для хоста
--//1.Записываем заголовок пакета
--//2.Записываем прочитаные данные
i_rxbuf_wd<=(i_pkt_header_wd or i_pkt_data_wd_delay2) and i_dev_wr;
i_rxbuf_din(15 downto 0)<=i_txbuf_dout_delay when i_pkt_header_wd='1' and i_dev_wr=C_CFGPKT_ACT_RD else p_in_cfg_rxdata;
i_rxbuf_din(31 downto 16)<=(others=>'0');




--END MAIN
end behavioral;
