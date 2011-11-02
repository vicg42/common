-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.07.2011 11:49:04
-- Module Name : cfgdev_ftdi
--
-- Назначение/Описание :
--  Реализация протокола записи/чтения данных модулей FPGA через микросхему FTDI (USB)
--
--  CfgPkt: (описание полей Header см. cfgdev_pkt.vhd)
--  Header[]-16bit
--  Data[]-16bit
--
--  Протокол обмена:
--  Write:  SW -> FPGA
--   1. Управляющая программа формирует CfgPkt и передает его в FPGA
--
--  Read :  SW <- FPGA
--   1. Управляющая программа формирует запрос чтения CfgPkt(header) и передает его в FPGA
--   2. На запрос FPGA передает CfgPkt с прочитаными данными. Заголовок аналогичен заголовку запроса чтения.
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

entity cfgdev_ftdi is
port(
-------------------------------
--Связь с FTDI
-------------------------------
p_inout_ftdi_d       : inout  std_logic_vector(7 downto 0); --//
p_out_ftdi_rd_n      : out    std_logic;                    --//
p_out_ftdi_wr_n      : out    std_logic;                    --//
p_in_ftdi_txe_n      : in     std_logic;                    --//
p_in_ftdi_rxf_n      : in     std_logic;                    --//
p_in_ftdi_pwren_n    : in     std_logic;                    --//

-------------------------------
--
-------------------------------
p_out_module_rdy     : out    std_logic;                    --//
p_out_module_error   : out    std_logic;                    --//

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       : out    std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0); --//Адрес модуля
p_out_cfg_radr       : out    std_logic_vector(C_CFGPKT_RADR_M_BIT - C_CFGPKT_RADR_L_BIT downto 0); --//Адрес стартового регистра
p_out_cfg_radr_ld    : out    std_logic;                    --//Загрузка адреса регистра
p_out_cfg_radr_fifo  : out    std_logic;                    --//Тип адресации:1-FIFO(инкрементация адреса запрещена/0-Register(инкрементация адреса разрешена)
p_out_cfg_wr         : out    std_logic;                    --//Строб записи
p_out_cfg_rd         : out    std_logic;                    --//Строб чтения
p_out_cfg_txdata     : out    std_logic_vector(15 downto 0);--//
p_in_cfg_rxdata      : in     std_logic_vector(15 downto 0);--//
p_in_cfg_txrdy       : in     std_logic;                    --//1 - rdy to used
p_in_cfg_rxrdy       : in     std_logic;                    --//1 - rdy to used
p_out_cfg_done       : out    std_logic;                    --//операция завершена
--p_in_cfg_irq         : in     std_logic;

p_in_cfg_clk         : in     std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst             : in     std_logic_vector(31 downto 0);
p_out_tst            : out    std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst             : in     std_logic
);
end cfgdev_ftdi;

architecture behavioral of cfgdev_ftdi is

type fsm_state is (
S_DEV_WAIT_RXRDY,
S_DEV_RXD,
S_DEV_WAIT_TXRDY,
S_DEV_TXD,
S_PKTH_RXCHK,
S_PKTH_TXCHK,
S_CFG_WAIT_TXRDY,
S_CFG_TXD,
S_CFG_WAIT_RXRDY,
S_CFG_RXD
);
signal fsm_state_cs                     : fsm_state;

signal i_dv_tmr_en                      : std_logic;
signal i_dv_tmr                         : std_logic_vector(6 downto 0);

signal i_dv_rdy                         : std_logic;
signal i_dv_oe                          : std_logic;
signal i_dv_din                         : std_logic_vector(p_inout_ftdi_d'range);
signal i_dv_dout                        : std_logic_vector(p_inout_ftdi_d'range);
signal i_dv_rd                          : std_logic;
signal i_dv_wr                          : std_logic;
signal i_dv_txrdy                       : std_logic;
signal i_dv_rxrdy                       : std_logic;

constant CI_CFG_DBYTE_SIZE              : integer:=p_out_cfg_txdata'length/p_inout_ftdi_d'length;
signal i_cfg_dbyte                      : integer range 0 to CI_CFG_DBYTE_SIZE-1;
signal i_cfg_rgadr_ld                   : std_logic;
signal i_cfg_d                          : std_logic_vector(p_out_cfg_txdata'range);
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_done                       : std_logic;

type TDevCfg_PktHeader is array (0 to C_CFGPKT_HEADER_DCOUNT-1) of std_logic_vector(i_cfg_d'range);
signal i_pkt_dheader                    : TDevCfg_PktHeader;
signal i_pkt_field_data                 : std_logic;--//Структура пакета: поле данных
signal i_pkt_cntd                       : std_logic_vector(C_CFGPKT_DLEN_M_BIT-C_CFGPKT_DLEN_L_BIT downto 0);

signal tst_fsm_cs                       : std_logic_vector(3 downto 0);



--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
--p_out_tst(31 downto 0)<=(others=>'0');
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    p_out_tst(5 downto 0)<=(others=>'0');

  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then

    p_out_tst(0)<=OR_reduce(tst_fsm_cs);
    p_out_tst(4 downto 1)<=tst_fsm_cs;
    p_out_tst(5)<='0';
  end if;
end process;
p_out_tst(9 downto 6)<=tst_fsm_cs;
p_out_tst(31 downto 10)<=(others=>'0');

tst_fsm_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fsm_cs'length) when fsm_state_cs=S_DEV_WAIT_RXRDY else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fsm_cs'length) when fsm_state_cs=S_DEV_RXD        else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fsm_cs'length) when fsm_state_cs=S_DEV_WAIT_TXRDY else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fsm_cs'length) when fsm_state_cs=S_DEV_TXD        else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fsm_cs'length) when fsm_state_cs=S_PKTH_RXCHK     else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fsm_cs'length) when fsm_state_cs=S_PKTH_TXCHK     else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fsm_cs'length) when fsm_state_cs=S_CFG_WAIT_TXRDY else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fsm_cs'length) when fsm_state_cs=S_CFG_TXD        else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fsm_cs'length) when fsm_state_cs=S_CFG_WAIT_RXRDY else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fsm_cs'length);--when fsm_state_cs=S_CFG_RXD       else




--------------------------------------------------
--Статусы
--------------------------------------------------
p_out_module_rdy<=not p_in_rst;
p_out_module_error<='0';


--------------------------------------------------
--Связь с FTDI
--------------------------------------------------
p_inout_ftdi_d<=i_dv_dout when i_dv_oe='1' else (others=> 'Z');
i_dv_din<=p_inout_ftdi_d;

p_out_ftdi_rd_n<=i_dv_rd;
p_out_ftdi_wr_n<=i_dv_wr;

process(p_in_cfg_clk)
begin
  if p_in_cfg_clk'event and p_in_cfg_clk='1' then
    i_dv_txrdy<=not p_in_ftdi_txe_n;
    i_dv_rxrdy<=not p_in_ftdi_rxf_n;
    i_dv_rdy<=not p_in_ftdi_pwren_n;
  end if;
end process;


--------------------------------------------------
--Связь с модулями FPGA
--------------------------------------------------
p_out_cfg_dadr     <=i_pkt_dheader(0)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT);
p_out_cfg_radr_fifo<=i_pkt_dheader(0)(C_CFGPKT_FIFO_BIT);
p_out_cfg_radr     <=i_pkt_dheader(1)(C_CFGPKT_RADR_M_BIT downto C_CFGPKT_RADR_L_BIT);
p_out_cfg_radr_ld  <=i_cfg_rgadr_ld;
p_out_cfg_rd       <=i_cfg_rd;
p_out_cfg_wr       <=i_cfg_wr;
p_out_cfg_txdata   <=i_cfg_d;

p_out_cfg_done     <=i_cfg_done;--//Операция завершена


--------------------------------------------------
--//Timer
--------------------------------------------------
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst='1' then
    i_dv_tmr<=(others=>'0');

  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then

    if i_dv_tmr_en='0' then
      i_dv_tmr<=(others=>'0');
    else
      i_dv_tmr<=i_dv_tmr + 1;
    end if;

  end if;
end process;


--------------------------------------------------
--//Автомат управления
--------------------------------------------------
process(p_in_rst,p_in_cfg_clk)
  variable pkt_type : std_logic;
  variable pkt_dlen : std_logic_vector(i_pkt_cntd'range);
begin

if p_in_rst='1' then

  fsm_state_cs <= S_DEV_WAIT_RXRDY;

  i_dv_tmr_en<='0';

  i_dv_oe<='0';
  i_dv_rd<='1';
  i_dv_wr<='1';
  i_dv_dout<=(others=>'0');

  i_cfg_dbyte<=0;
  i_cfg_rgadr_ld<='0';
  i_cfg_d<=(others=>'0');
  i_cfg_wr<='0';
  i_cfg_rd<='0';
  i_cfg_done<='0';

    pkt_type:='0';
    pkt_dlen :=(others=>'0');
  i_pkt_cntd<=(others=>'0');
  i_pkt_field_data<='0';
  for i in 0 to C_CFGPKT_HEADER_DCOUNT-1 loop
  i_pkt_dheader(i)<=(others=>'0');
  end loop;

elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
--  if p_in_clken='1' then

  case fsm_state_cs is

    --//################################
    --//Прием данных
    --//################################
    --//--------------------------------
    --//Ждем когда в уст-ве связи с SW появятся данные
    --//--------------------------------
    when S_DEV_WAIT_RXRDY =>

      i_cfg_rgadr_ld<='0';
      i_cfg_done<='0';

      if i_dv_rxrdy='1' then
        i_dv_rd<='0';
        i_dv_tmr_en<='1';
        fsm_state_cs <= S_DEV_RXD;
      end if;

    --//--------------------------------
    --//Прием данных из уст-ва связи с SW
    --//--------------------------------
    when S_DEV_RXD =>

      if i_dv_tmr=CONV_STD_LOGIC_VECTOR(16, i_dv_tmr'length) then
        i_dv_rd<='1';
        i_dv_tmr_en<='0';

        if i_cfg_dbyte=CI_CFG_DBYTE_SIZE-1 then
          i_cfg_dbyte<=0;

          if i_pkt_field_data='1' then
              --//переходим к записи занных в модуль FPGA
              fsm_state_cs <= S_CFG_WAIT_TXRDY;

          else
            --//Собираем данные USR_PKT/HEADER
            for i in 0 to C_CFGPKT_HEADER_DCOUNT-1 loop
              if i_pkt_cntd(1 downto 0)=i then
                i_pkt_dheader(i)<=i_cfg_d;
              end if;
            end loop;
            fsm_state_cs <= S_PKTH_RXCHK;

          end if;

        else
          i_cfg_dbyte<=i_cfg_dbyte + 1;
          fsm_state_cs <= S_DEV_WAIT_RXRDY;
        end if;

      elsif i_dv_tmr=CONV_STD_LOGIC_VECTOR(10, i_dv_tmr'length) then
        i_dv_rd<='1';

      elsif i_dv_tmr=CONV_STD_LOGIC_VECTOR(8, i_dv_tmr'length) then
        for i in 0 to CI_CFG_DBYTE_SIZE-1 loop
          if i_cfg_dbyte=i then
            i_cfg_d(i_dv_din'length*(i+1)-1 downto i_dv_din'length*i)<=i_dv_din(7 downto 0);
          end if;
        end loop;

      end if;


    --//--------------------------------
    --//Проверка завершения приема USR_PKT/HEADER
    --//--------------------------------
    when S_PKTH_RXCHK =>

      if i_pkt_cntd(1 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGPKT_HEADER_DCOUNT-1, 2) then

          i_cfg_rgadr_ld<='1';

            pkt_type:=i_pkt_dheader(0)(C_CFGPKT_WR_BIT);
            pkt_dlen:=i_pkt_dheader(2)(C_CFGPKT_DLEN_M_BIT downto C_CFGPKT_DLEN_L_BIT)-1;

          if pkt_type=C_CFGPKT_WR then
            i_pkt_cntd<=pkt_dlen;
            i_pkt_field_data<='1';
            fsm_state_cs <= S_DEV_WAIT_RXRDY;

          else

            i_pkt_cntd<=(others=>'0');
            fsm_state_cs <= S_PKTH_TXCHK;
          end if;

      else

        i_pkt_cntd<=i_pkt_cntd + 1;
        fsm_state_cs <= S_DEV_WAIT_RXRDY;

      end if;


    --//--------------------------------
    --//Запись данных в FPGA модуля
    --//--------------------------------
    when S_CFG_WAIT_TXRDY =>

      if p_in_cfg_txrdy='1' then
        i_cfg_wr<='1';
        fsm_state_cs <= S_CFG_TXD;
      end if;

    when S_CFG_TXD =>

      i_cfg_wr<='0';

      if i_pkt_cntd=(i_pkt_cntd'range => '0') then
        i_pkt_field_data<='0';
        i_cfg_done<='1';
      else
        i_pkt_cntd<=i_pkt_cntd - 1;
      end if;

      fsm_state_cs <= S_DEV_WAIT_RXRDY;




    --//################################
    --//Передача данных
    --//################################
    --//--------------------------------
    --//Проверка завершения прередачи USR_PKT/HEADER
    --//--------------------------------
    when S_PKTH_TXCHK =>

      i_cfg_rgadr_ld<='0';

      if i_pkt_cntd(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGPKT_HEADER_DCOUNT, 3) then
      --//Заголовок отправлен, переходим к чтению данных из модуля FPGA
        i_pkt_cntd<=pkt_dlen;
        i_pkt_field_data<='1';
        fsm_state_cs <= S_CFG_WAIT_RXRDY;
      else
        i_pkt_cntd<=i_pkt_cntd + 1;
        fsm_state_cs <= S_DEV_WAIT_TXRDY;
      end if;

      for i in 0 to C_CFGPKT_HEADER_DCOUNT-1 loop
        if i_pkt_cntd(1 downto 0)=i then
          i_cfg_d<=i_pkt_dheader(i);
        end if;
      end loop;

    --//--------------------------------
    --//Ждем когда уст-во связи с SW будет доступно для записи
    --//--------------------------------
    when S_DEV_WAIT_TXRDY =>

      if i_dv_txrdy='1' then
        i_dv_wr<='1';
        i_dv_tmr_en<='1';
--        i_dv_oe<='1';

        for i in 0 to CI_CFG_DBYTE_SIZE-1 loop
          if i_cfg_dbyte=i then
            i_dv_dout<=i_cfg_d(i_dv_dout'length*(i+1)-1 downto i_dv_dout'length*i);
          end if;
        end loop;

        fsm_state_cs <= S_DEV_TXD;
      end if;

    --//--------------------------------
    --//Передача данных в уст-во связи с SW
    --//--------------------------------
    when S_DEV_TXD =>

      if i_dv_tmr=CONV_STD_LOGIC_VECTOR(16, i_dv_tmr'length) then
        i_dv_wr<='1';
        i_dv_tmr_en<='0';
        i_dv_oe<='0';

        if i_cfg_dbyte=CI_CFG_DBYTE_SIZE-1 then
          i_cfg_dbyte<=0;

          if i_pkt_field_data='1' then

            if i_pkt_cntd=(i_pkt_cntd'range => '0') then
              i_cfg_done<='1';
              i_pkt_field_data<='0';
              fsm_state_cs <= S_DEV_WAIT_RXRDY;

            else
              i_pkt_cntd<=i_pkt_cntd - 1;
              fsm_state_cs <= S_CFG_WAIT_RXRDY;
            end if;

          else
            fsm_state_cs <= S_PKTH_TXCHK;
          end if;

        else
          i_cfg_dbyte<=i_cfg_dbyte + 1;
          fsm_state_cs <= S_DEV_WAIT_TXRDY;
        end if;

      elsif i_dv_tmr=CONV_STD_LOGIC_VECTOR(10, i_dv_tmr'length) then
        i_dv_wr<='0';

      elsif i_dv_tmr=CONV_STD_LOGIC_VECTOR(8, i_dv_tmr'length) then
--        for i in 0 to CI_CFG_DBYTE_SIZE-1 loop
--          if i_cfg_dbyte=i then
--            i_dv_dout<=i_cfg_d(i_dv_dout'length*(i+1)-1 downto i_dv_dout'length*i);
--          end if;
--        end loop;
        i_dv_oe<='1';

      end if;


    --//--------------------------------
    --//Чтение данных из FPGA модуля
    --//--------------------------------
    when S_CFG_WAIT_RXRDY =>

      if p_in_cfg_rxrdy='1' then
        i_cfg_rd<='1';
        fsm_state_cs <= S_CFG_RXD;
      end if;

    when S_CFG_RXD =>

      i_cfg_rd<='0';

      if i_cfg_rd='0' then
        i_cfg_d<=p_in_cfg_rxdata;
        fsm_state_cs <= S_DEV_WAIT_TXRDY;
      end if;

  end case;
--  end if;--//if p_in_clken='1' then
end if;
end process;



--END MAIN
end behavioral;
