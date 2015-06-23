-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 16.07.2011 12:22:36
-- Module Name : cfgdev_host
--
-- Назначение/Описание :
--  CfgPkt: (описание полей Header см. cfgdev_pkt.vhd)
--  PKT DLEN (byte) - первые 16bit
--  Header[]-16bit
--  Data[]-16bit
--
--  Протокол обмена:
--  Write:  SW -> FPGA
--   1. SW (CfgPkt(Header + data)) -> FPGA
--   2. SW <- FPGA (CfgPkt(Header)) Заголовок аналогичен заголовку запроса
--
--  Read :  SW <- FPGA
--   1. SW (CfgPkt(Header) -> FPGA
--   2. SW  <- FPGA (CfgPkt(Header + Data) Заголовок аналогичен заголовку запроса
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
use work.vicg_common_pkg.all;
use work.cfgdev_pkg.all;

entity cfgdev_host is
generic(
G_DBG : string:="OFF";
G_HOST_DWIDTH : integer:=32
);
port(
-------------------------------
--HOST
-------------------------------
--host -> dev
p_in_htxbuf_di       : in   std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_htxbuf_wr       : in   std_logic;
p_out_htxbuf_full    : out  std_logic;
p_out_htxbuf_empty   : out  std_logic;

--host <- dev
p_out_hrxbuf_do      : out  std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_hrxbuf_rd       : in   std_logic;
p_out_hrxbuf_full    : out  std_logic;
p_out_hrxbuf_empty   : out  std_logic;

p_out_hirq           : out  std_logic;
p_out_herr           : out  std_logic;

p_in_hclk            : in   std_logic;

-------------------------------
--Связь с HOST
-------------------------------
p_out_host_rxrdy     : out  std_logic;                      --1 - rdy to used
p_out_hrxbuf_do       : out  std_logic_vector(G_HOST_DWIDTH-1 downto 0);  --cfgdev -> host
p_in_hrxbuf_rd         : in   std_logic;                      --

p_out_host_txrdy     : out  std_logic;                      --1 - rdy to used
p_in_htxbuf_di        : in   std_logic_vector(G_HOST_DWIDTH-1 downto 0);  --cfgdev <- host
p_in_htxbuf_wr         : in   std_logic;

p_out_host_irq       : out  std_logic;                      --прерывание
p_in_host_clk        : in   std_logic;

-------------------------------
--
-------------------------------
p_out_module_rdy     : out    std_logic;
p_out_module_error   : out    std_logic;

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       : out    std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0); --Адрес модуля
p_out_cfg_radr       : out    std_logic_vector(C_CFGPKT_RADR_M_BIT - C_CFGPKT_RADR_L_BIT downto 0); --Адрес стартового регистра
p_out_cfg_radr_ld    : out    std_logic;                    --Загрузка адреса регистра
p_out_cfg_radr_fifo  : out    std_logic;                    --Тип адресации:1-FIFO(инкрементация адреса запрещена/0-Register(инкрементация адреса разрешена)
p_out_cfg_wr         : out    std_logic;                    --Строб записи
p_out_cfg_rd         : out    std_logic;                    --Строб чтения
p_out_cfg_txdata     : out    std_logic_vector(15 downto 0);--
p_in_cfg_rxdata      : in     std_logic_vector(15 downto 0);--
p_in_cfg_txrdy       : in     std_logic;                    --1 - rdy to used
p_in_cfg_rxrdy       : in     std_logic;                    --1 - rdy to used
p_out_cfg_done       : out    std_logic;                    --операция завершена
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
end entity cfgdev_host;

architecture behavioral of cfgdev_host is

constant CI_CFGPKT_H_ETHLEN_IDX : integer:=0;
constant CI_CFGPKT_H_CTRL_IDX : integer:=1;
constant CI_CFGPKT_H_RADR_IDX : integer:=2;
constant CI_CFGPKT_H_DLEN_IDX : integer:=3;

constant CI_CFGPKT_HEADER_DCOUNT : integer:=C_CFGPKT_HEADER_DCOUNT + 1;

component cfgdev_buf
generic(
G_DWIDTH : integer:=32
);
port(
din         : in  std_logic_vector(G_DWIDTH - 1 downto 0);
wr_en       : in  std_logic;
wr_clk      : in  std_logic;

dout        : out std_logic_vector(G_DWIDTH - 1 downto 0);
rd_en       : in  std_logic;
rd_clk      : in  std_logic;

empty       : out std_logic;
full        : out std_logic;
prog_full   : out std_logic;

rst         : in  std_logic
);
end component cfgdev_buf;


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

signal i_dv_din                         : std_logic_vector(G_HOST_DWIDTH-1 downto 0);
signal i_dv_din_r                       : std_logic_vector(i_dv_din'range);
signal i_dv_dout                        : std_logic_vector(i_dv_din'range);
signal i_dv_rd                          : std_logic;
signal i_dv_wr                          : std_logic;
signal i_dv_txrdy                       : std_logic;
signal i_dv_rxrdy                       : std_logic;

constant CI_CFG_DBYTE_SIZE              : integer:=i_dv_din'length/p_out_cfg_txdata'length;
signal i_cfg_dbyte                      : integer range 0 to CI_CFG_DBYTE_SIZE - 1;
signal i_cfg_rgadr_ld                   : std_logic;
signal i_cfg_d                          : std_logic_vector(p_out_cfg_txdata'range);
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_done                       : std_logic;

type TDevCfg_PktHeader is array (0 to CI_CFGPKT_HEADER_DCOUNT - 1) of std_logic_vector(15 downto 0);--(i_cfg_d'range);
signal i_pkt_dheader                    : TDevCfg_PktHeader;
signal i_pkt_field_data                 : std_logic;--Структура пакета: поле данных
signal i_pkt_cntd                       : std_logic_vector(C_CFGPKT_DLEN_M_BIT-C_CFGPKT_DLEN_L_BIT downto 0);
signal i_pkt_txack                      : std_logic;

signal i_rxbuf_empty                    : std_logic;
signal i_rxbuf_full                     : std_logic;
signal i_txbuf_empty                    : std_logic;
signal i_txbuf_full                     : std_logic;

signal i_irq_out                        : std_logic;
signal i_irq_width                      : std_logic;
signal i_irq_width_cnt                  : std_logic_vector(3 downto 0);

signal tst_fsm_cs                       : std_logic_vector(3 downto 0):=(others=>'0');
signal tst_fsm_cs_dly                   : std_logic_vector(tst_fsm_cs'range):=(others=>'0');
signal tst_rxbuf_empty                  : std_logic:='0';
signal tst_rst0                         : std_logic:='0';
signal tst_rst1                         : std_logic:='0';
signal tst_rstup,tst_rstdown            : std_logic:='0';
signal tst_host_rd                      : std_logic:='0';
signal tst_txbuf_empty                  : std_logic;


begin --architecture behavioral

------------------------------------
--Технологические сигналы
------------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0) <= (others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
process(p_in_cfg_clk)
begin
  if rising_edge(p_in_cfg_clk) then

    tst_rst0 <= p_in_rst;
    tst_rst1 <= tst_rst0;
    tst_rstup <= tst_rst0 and not tst_rst1;
    tst_rstdown <= not tst_rst0 and tst_rst1;
    tst_fsm_cs_dly <= tst_fsm_cs;
    tst_rxbuf_empty <= i_rxbuf_empty;
    tst_txbuf_empty <= i_txbuf_empty;
    p_out_tst(0) <= OR_reduce(tst_fsm_cs_dly) or i_cfg_done or tst_rxbuf_empty or tst_rstup or tst_rstdown or tst_txbuf_empty;

  end if;
end process;
p_out_tst(5 downto 1) <= (others=>'0');
p_out_tst(9 downto 6) <= tst_fsm_cs;
p_out_tst(10) <= i_rxbuf_empty;
p_out_tst(11) <= i_dv_rd;
p_out_tst(12) <= i_dv_wr;
p_out_tst(13) <= '0';
p_out_tst(14) <= '0';
p_out_tst(15) <= '0';
p_out_tst(16) <= i_pkt_field_data;
p_out_tst(17) <= '0';
p_out_tst(19 downto 18) <= CONV_STD_LOGIC_VECTOR(i_cfg_dbyte, 2);
p_out_tst(27 downto 20) <= i_pkt_cntd(7 downto 0);
p_out_tst(28) <= i_rxbuf_empty;--HOST->FPGA
p_out_tst(29) <= i_rxbuf_full ;
p_out_tst(30) <= i_txbuf_empty;--HOST<-FPGA
p_out_tst(31) <= i_txbuf_full ;

tst_fsm_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fsm_cs'length) when fsm_state_cs = S_DEV_WAIT_RXRDY else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fsm_cs'length) when fsm_state_cs = S_DEV_RXD        else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fsm_cs'length) when fsm_state_cs = S_DEV_WAIT_TXRDY else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fsm_cs'length) when fsm_state_cs = S_DEV_TXD        else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fsm_cs'length) when fsm_state_cs = S_PKTH_RXCHK     else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fsm_cs'length) when fsm_state_cs = S_PKTH_TXCHK     else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fsm_cs'length) when fsm_state_cs = S_CFG_WAIT_TXRDY else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fsm_cs'length) when fsm_state_cs = S_CFG_TXD        else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fsm_cs'length) when fsm_state_cs = S_CFG_WAIT_RXRDY else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fsm_cs'length);
--            CONV_STD_LOGIC_VECTOR(16#00#, tst_fsm_cs'length) when fsm_state_cs = S_CFG_RXD       else

end generate gen_dbg_on;



--------------------------------------------------
--Статусы
--------------------------------------------------
p_out_module_rdy <= not p_in_rst;
p_out_module_error <='0';


--------------------------------------------------
--Связь с HOST
--------------------------------------------------
p_out_host_rxrdy <= not i_txbuf_empty;

p_out_host_txrdy <= i_rxbuf_empty;

p_out_host_irq <= i_irq_out;

--Растягиваем импульcы перывания
process(p_in_rst,p_in_cfg_clk)
begin
  if p_in_rst = '1' then
    i_irq_width <= '0';
    i_irq_width_cnt <= (others=>'0');
  elsif rising_edge(p_in_cfg_clk) then

      if i_cfg_done = '1' and i_pkt_dheader(CI_CFGPKT_H_CTRL_IDX)(C_CFGPKT_WR_BIT) = C_CFGPKT_RD then
      --Генерация прерывания/READ
        i_irq_width <= '1';
      elsif i_irq_width_cnt(3) = '1' then
        i_irq_width <= '0';
      end if;

      if i_irq_width = '0' then
        i_irq_width_cnt <= (others=>'0');
      else
        i_irq_width_cnt <= i_irq_width_cnt+1;
      end if;

  end if;
end process;

--пересинхронизация
process(p_in_rst,p_in_host_clk)
begin
  if rising_edge(p_in_host_clk) then
    i_irq_out <= i_irq_width;
  end if;
end process;


--------------------------------------------------
--Развязка частот(p_in_host_clk/p_in_cfg_clk), через согласующие буфера
--------------------------------------------------
--HOST -> FPGA
p_out_htxbuf_full <= i_rxbuf_full;
p_out_htxbuf_empty <= i_rxbuf_empty;

i_dv_rxrdy <= not i_rxbuf_empty;--Готовность RxBUF

m_rxbuf : cfgdev_buf
generic map(
G_DWIDTH => G_HOST_DWIDTH
)
port map(
din         => p_in_htxbuf_di,
wr_en       => p_in_htxbuf_wr,
wr_clk      => p_in_host_clk,

dout        => i_dv_din,
rd_en       => i_dv_rd,
rd_clk      => p_in_cfg_clk,

empty       => i_rxbuf_empty,
full        => open,
prog_full   => i_rxbuf_full,

rst         => p_in_rst
);

--HOST <- FPGA
p_out_hrxbuf_full <= i_txbuf_full;
p_out_hrxbuf_empty <= i_txbuf_empty;

i_dv_txrdy <= not i_txbuf_full;--Готовность TxBUF

m_txbuf : cfgdev_buf
generic map(
G_DWIDTH => G_HOST_DWIDTH
)
port map(
din         => i_dv_dout,
wr_en       => i_dv_wr,
wr_clk      => p_in_cfg_clk,

dout        => p_out_hrxbuf_do,
rd_en       => p_in_hrxbuf_rd,
rd_clk      => p_in_host_clk,

empty       => i_txbuf_empty,
full        => open,
prog_full   => i_txbuf_full,

rst         => p_in_rst
);


--------------------------------------------------
--Связь с модулями FPGA
--------------------------------------------------
p_out_cfg_dadr      <= i_pkt_dheader(CI_CFGPKT_H_CTRL_IDX)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT);
p_out_cfg_radr_fifo <= i_pkt_dheader(CI_CFGPKT_H_CTRL_IDX)(C_CFGPKT_FIFO_BIT);
p_out_cfg_radr      <= i_pkt_dheader(CI_CFGPKT_H_RADR_IDX)(C_CFGPKT_RADR_M_BIT downto C_CFGPKT_RADR_L_BIT);
p_out_cfg_radr_ld   <= i_cfg_rgadr_ld;
p_out_cfg_rd        <= i_cfg_rd;
p_out_cfg_wr        <= i_cfg_wr;
p_out_cfg_txdata    <= i_cfg_d;

p_out_cfg_done      <= i_cfg_done;--Операция завершена



--------------------------------------------------
--Автомат управления
--------------------------------------------------
process(p_in_rst,p_in_cfg_clk)
  variable pkt_type : std_logic;
  variable pkt_dlen : std_logic_vector(i_pkt_cntd'range);
begin

if p_in_rst = '1' then

  fsm_state_cs <= S_DEV_WAIT_RXRDY;

  i_dv_rd <= '0';
  i_dv_wr <= '0';
  i_dv_dout <= (others=>'0');
  i_dv_din_r <= (others=>'0');

  i_cfg_rgadr_ld <= '0';
  i_cfg_d <= (others=>'0');
  i_cfg_wr <= '0';
  i_cfg_rd <= '0';
  i_cfg_done <= '0';

    pkt_type := '0';
    pkt_dlen := (others=>'0');
  i_pkt_cntd <= (others=>'0');
  i_pkt_field_data <= '0';
  for i in 0 to CI_CFGPKT_HEADER_DCOUNT - 1 loop
  i_pkt_dheader(i) <= (others=>'0');
  end loop;
  i_pkt_txack <= '0';

elsif rising_edge(p_in_cfg_clk) then
--  if p_in_clken = '1' then

  case fsm_state_cs is

    --################################
    --Прием данных
    --################################
    ----------------------------------
    --Ждем когда в уст-ве связи с SW появятся данные
    ----------------------------------
    when S_DEV_WAIT_RXRDY =>

      i_cfg_rgadr_ld <= '0';
      i_cfg_done <= '0';
      i_dv_wr <= '0';

      if i_dv_rxrdy = '1' then
        i_dv_rd <='1';
        i_dv_din_r <= i_dv_din;

        fsm_state_cs <= S_DEV_RXD;
      end if;

    ----------------------------------
    --Прием данных из уст-ва связи с SW
    ----------------------------------
    when S_DEV_RXD =>

      i_cfg_rgadr_ld <= '0';
      i_dv_rd <= '0';

      if i_pkt_field_data = '1' then
          --переходим к записи занных в модуль FPGA
          for i in 0 to CI_CFG_DBYTE_SIZE - 1 loop
            if i_cfg_dbyte = i then
              i_cfg_d <= i_dv_din_r(i_cfg_d'length*(i+1)-1 downto i_cfg_d'length*i);
            end if;
          end loop;

          fsm_state_cs <= S_CFG_WAIT_TXRDY;

      else
        --Собираем данные USR_PKT/HEADER
        for i in 0 to CI_CFG_DBYTE_SIZE - 1 loop
          if i_cfg_dbyte = i then
            for y in 0 to CI_CFGPKT_HEADER_DCOUNT - 1 loop
              if i_pkt_cntd(2 downto 0) = y then
                i_pkt_dheader(y) <= i_dv_din_r(i_pkt_dheader(y)'length*(i+1)-1 downto i_pkt_dheader(y)'length*i);
              end if;
            end loop;
          end if;
        end loop;

        fsm_state_cs <= S_PKTH_RXCHK;

      end if;


    ----------------------------------
    --Проверка завершения приема USR_PKT/HEADER
    ----------------------------------
    when S_PKTH_RXCHK =>

      if i_pkt_cntd(1 downto 0) = CONV_STD_LOGIC_VECTOR(CI_CFGPKT_HEADER_DCOUNT - 1, 2) then

          i_cfg_rgadr_ld <= '1';

            pkt_type := i_pkt_dheader(CI_CFGPKT_H_CTRL_IDX)(C_CFGPKT_WR_BIT);
            pkt_dlen := i_pkt_dheader(CI_CFGPKT_H_DLEN_IDX)(C_CFGPKT_DLEN_M_BIT downto C_CFGPKT_DLEN_L_BIT) - 1;

          if pkt_type = C_CFGPKT_WR then

              i_pkt_cntd <= pkt_dlen;
              i_pkt_field_data <= '1';

              if i_cfg_dbyte = CI_CFG_DBYTE_SIZE - 1 then
                i_cfg_dbyte <= 0;
                fsm_state_cs <= S_DEV_WAIT_RXRDY;
              else
                i_cfg_dbyte <= i_cfg_dbyte + 1;
                fsm_state_cs <= S_DEV_RXD;
              end if;

          else
              i_pkt_dheader(CI_CFGPKT_H_ETHLEN_IDX) <= CONV_STD_LOGIC_VECTOR(C_CFGPKT_HEADER_DCOUNT * 2, i_pkt_dheader(CI_CFGPKT_H_ETHLEN_IDX)'length) +
                                                       (i_pkt_dheader(CI_CFGPKT_H_DLEN_IDX)(C_CFGPKT_DLEN_M_BIT - 1 downto C_CFGPKT_DLEN_L_BIT) & '0');
              i_pkt_cntd <= (others=>'0');
              i_cfg_dbyte <= 0;
              fsm_state_cs <= S_PKTH_TXCHK;
          end if;

      else

        if i_cfg_dbyte = CI_CFG_DBYTE_SIZE - 1 then
          i_cfg_dbyte <= 0;
          fsm_state_cs <= S_DEV_WAIT_RXRDY;
        else
          i_cfg_dbyte <= i_cfg_dbyte + 1;
          fsm_state_cs <= S_DEV_RXD;

        end if;

        i_pkt_cntd <= i_pkt_cntd + 1;

      end if;


    ----------------------------------
    --Запись данных в FPGA модуля
    ----------------------------------
    when S_CFG_WAIT_TXRDY =>

      if p_in_cfg_txrdy = '1' then
        i_cfg_wr <= '1';
        fsm_state_cs <= S_CFG_TXD;
      end if;

    when S_CFG_TXD =>

      i_cfg_wr<='0';

      if i_pkt_cntd = (i_pkt_cntd'range => '0') then
        i_pkt_field_data <= '0';
        i_cfg_done <= '1';

        --перехжу к отправке txask
        i_pkt_dheader(CI_CFGPKT_H_ETHLEN_IDX) <= CONV_STD_LOGIC_VECTOR(C_CFGPKT_HEADER_DCOUNT * 2, i_pkt_dheader(CI_CFGPKT_H_ETHLEN_IDX)'length);
        i_cfg_dbyte <= 0;
        i_pkt_txack <= '1';
        fsm_state_cs <= S_PKTH_TXCHK;

      else
        i_pkt_cntd <= i_pkt_cntd - 1;

        if i_cfg_dbyte = CI_CFG_DBYTE_SIZE - 1 then
          i_cfg_dbyte <= 0;
          fsm_state_cs <= S_DEV_WAIT_RXRDY;
        else
          i_cfg_dbyte <= i_cfg_dbyte + 1;
          fsm_state_cs <= S_DEV_RXD;
        end if;

      end if;




    --################################
    --Передача данных
    --################################
    ----------------------------------
    --Проверка завершения прередачи USR_PKT/HEADER
    ----------------------------------
    when S_PKTH_TXCHK =>

      i_cfg_rgadr_ld <= '0';
      i_dv_wr <= '0';

      if i_pkt_cntd(2 downto 0) = CONV_STD_LOGIC_VECTOR(CI_CFGPKT_HEADER_DCOUNT, 3) then

        if i_pkt_txack = '0' then
        --SW <- FPGA (txask) - Заголовок отправлен, переходим к чтению данных из модуля FPGA
        i_pkt_cntd <= i_pkt_dheader(CI_CFGPKT_H_DLEN_IDX)(C_CFGPKT_DLEN_M_BIT downto C_CFGPKT_DLEN_L_BIT);
        i_pkt_field_data <= '1';
        fsm_state_cs <= S_CFG_WAIT_RXRDY;
        else
        --SW <- FPGA (txask)
        i_pkt_cntd <= (others=>'0');
        i_pkt_field_data <= '0';
        i_pkt_txack <= '0';
        fsm_state_cs <= S_DEV_WAIT_RXRDY;
        end if;
      else
        i_pkt_cntd <= i_pkt_cntd + 1;
        fsm_state_cs <= S_DEV_WAIT_TXRDY;
      end if;

      for i in 0 to CI_CFGPKT_HEADER_DCOUNT - 1 loop
        if i_pkt_cntd(1 downto 0) = i then
          i_cfg_d <= i_pkt_dheader(i);
        end if;
      end loop;

    ----------------------------------
    --Ждем когда уст-во связи с SW будет доступно для записи
    ----------------------------------
    when S_DEV_WAIT_TXRDY =>

      if i_dv_txrdy = '1' then

        for i in 0 to CI_CFG_DBYTE_SIZE - 1 loop
          if i_cfg_dbyte = i then
            i_dv_dout(i_cfg_d'length*(i+1)-1 downto i_cfg_d'length*i) <= i_cfg_d;
          end if;
        end loop;

        if i_cfg_dbyte = CI_CFG_DBYTE_SIZE - 1 then
          i_cfg_dbyte <= 0;
--          i_dv_wr <= '1';
          fsm_state_cs <= S_DEV_TXD;
        else

          i_cfg_dbyte <= i_cfg_dbyte + 1;

          if i_pkt_field_data = '1' then
            fsm_state_cs <= S_CFG_WAIT_RXRDY;
          else
            fsm_state_cs <= S_PKTH_TXCHK;
          end if;

        end if;

      end if;--if i_dv_txrdy = '1' then

    ----------------------------------
    --Передача данных в уст-во связи с SW
    ----------------------------------
    when S_DEV_TXD =>

      i_dv_wr <= '1';

      if i_pkt_field_data = '1' then

        if i_pkt_cntd = (i_pkt_cntd'range => '0') then
          i_cfg_done <= '1';
          i_pkt_field_data <= '0';
          fsm_state_cs <= S_DEV_WAIT_RXRDY;

        else
          fsm_state_cs <= S_CFG_WAIT_RXRDY;
        end if;

      else
        fsm_state_cs <= S_PKTH_TXCHK;
      end if;


    ----------------------------------
    --Чтение данных из FPGA модуля
    ----------------------------------
    when S_CFG_WAIT_RXRDY =>

      i_dv_wr <= '0';

      if i_pkt_cntd = (i_pkt_cntd'range => '0') then

        fsm_state_cs <= S_DEV_WAIT_TXRDY;

      else
        if p_in_cfg_rxrdy = '1' then
          i_cfg_rd <= '1';
          fsm_state_cs <= S_CFG_RXD;
        end if;

      end if;

    when S_CFG_RXD =>

      i_cfg_rd <= '0';

      if i_cfg_rd = '0' then
        i_cfg_d <= p_in_cfg_rxdata;
        i_pkt_cntd <= i_pkt_cntd - 1;
        fsm_state_cs <= S_DEV_WAIT_TXRDY;
      end if;

  end case;
--  end if;--if p_in_clken = '1' then
end if;
end process;


end architecture behavioral;
