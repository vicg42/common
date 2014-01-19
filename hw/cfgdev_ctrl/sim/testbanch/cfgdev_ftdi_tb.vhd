-------------------------------------------------------------------------(test11)
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.07.2011 11:49:04
-- Module Name : cfgdev_ftdi_tb
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
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

use work.cfgdev_pkg.all;

entity cfgdev_ftdi_tb is
port(
p_out_tst : out std_logic
);
end cfgdev_ftdi_tb;

architecture behavior of cfgdev_ftdi_tb is

constant C_SATACLK_PERIOD : TIME := 6.6 ns; --150MHz
constant C_USRCLK_PERIOD  : TIME := 10 ns;

-- Small delay for simulation purposes.
constant dly : time := 1 ps;--50 ns;

signal p_in_clk                 : std_logic;
signal p_in_rst                 : std_logic;

signal i_ftdi_d                 : std_logic_vector(7 downto 0);
signal i_ftdi_dout              : std_logic_vector(7 downto 0);
signal i_ftdi_din               : std_logic_vector(7 downto 0);
signal i_ftd_rcv                : std_logic;
signal i_ftdi_rd_n              : std_logic;
signal i_ftdi_wr_n              : std_logic;
signal i_ftdi_txe_n             : std_logic;
signal i_ftdi_rxf_n             : std_logic;
signal i_ftdi_pwren_n           : std_logic;

signal i_dev_adr                : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_adr                : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_adr_ld             : std_logic;
signal i_cfg_adr_fifo           : std_logic;
signal i_cfg_wd                 : std_logic;
signal i_cfg_rd                 : std_logic;
signal i_cfg_txd                : std_logic_vector(15 downto 0);
signal i_cfg_rxd                : std_logic_vector(15 downto 0);
signal i_cfg_done               : std_logic;

signal i_cfg_adr_cnt            : std_logic_vector(i_cfg_adr'range);
signal i_reg0                   : std_logic_vector(i_cfg_rxd'range);
signal i_reg1                   : std_logic_vector(i_cfg_rxd'range);
signal i_reg2                   : std_logic_vector(i_cfg_rxd'range);
signal i_reg3                   : std_logic_vector(i_cfg_rxd'range);
signal i_reg4                   : std_logic_vector(i_cfg_rxd'range);


type TUsrPktHeader is array (0 to C_CFGPKT_HEADER_DCOUNT-1) of std_logic_vector(15 downto 0);
type TUsrPktData is array (0 to 5) of std_logic_vector(15 downto 0);
type TUsrPkt is record
h : TUsrPktHeader;
d : TUsrPktData;
end record;

type TUsrPkts is array (0 to 7) of TUsrPkt;
signal i_pkts     : TUsrPkts;



--MAIN
begin


gen_clk_usr : process
begin
  p_in_clk<='0';
  wait for C_USRCLK_PERIOD/2;
  p_in_clk<='1';
  wait for C_USRCLK_PERIOD/2;
end process;

p_in_rst<='1','0' after 1 us;

p_out_tst<=i_cfg_done or i_ftdi_wr_n;

m_devcfg : cfgdev_ftdi
port map
(
-------------------------------
--Связь с FTDI
-------------------------------
p_inout_ftdi_d       => i_ftdi_d,
p_out_ftdi_rd_n      => i_ftdi_rd_n,
p_out_ftdi_wr_n      => i_ftdi_wr_n,
p_in_ftdi_txe_n      => i_ftdi_txe_n,
p_in_ftdi_rxf_n      => i_ftdi_rxf_n,
p_in_ftdi_pwren_n    => i_ftdi_pwren_n,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       => i_dev_adr,
p_out_cfg_radr       => i_cfg_adr,
p_out_cfg_radr_ld    => i_cfg_adr_ld,
p_out_cfg_radr_fifo  => i_cfg_adr_fifo,
p_out_cfg_wr         => i_cfg_wd,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => '1',
p_in_cfg_rxrdy       => '1',

--p_out_cfg_rx_set_irq => open,
p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => p_in_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => "00000000000000000000000000000000",
p_out_tst            => open,

-------------------------------
--System
-------------------------------
p_in_rst             => p_in_rst
);


--//Счетчик адреса регистров
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_cfg_adr_cnt<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_cfg_adr_ld='1' then
      i_cfg_adr_cnt<=i_cfg_adr;
    else
      if i_cfg_adr_fifo='0' and (i_cfg_wd='1' or i_cfg_rd='1') then
        i_cfg_adr_cnt<=i_cfg_adr_cnt+1;
      end if;
    end if;
  end if;
end process;

--//Запись регистров
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_reg0<=(others=>'0');
    i_reg1<=(others=>'0');
    i_reg2<=(others=>'0');
    i_reg3<=(others=>'0');
    i_reg4<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if i_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(0, i_cfg_adr_cnt'length) then i_reg0<=i_cfg_txd(i_reg0'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(1, i_cfg_adr_cnt'length) then i_reg1<=i_cfg_txd(i_reg1'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(2, i_cfg_adr_cnt'length) then i_reg2<=i_cfg_txd(i_reg2'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(3, i_cfg_adr_cnt'length) then i_reg3<=i_cfg_txd(i_reg3'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(4, i_cfg_adr_cnt'length) then i_reg4<=i_cfg_txd(i_reg4'high downto 0);

        end if;
    end if;

  end if;
end process;

--//Чтение регистров
process(p_in_rst,p_in_clk)
  variable rxd : std_logic_vector(i_cfg_rxd'range);
begin
  if p_in_rst='1' then
      rxd:=(others=>'0');
    i_cfg_rxd<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    rxd:=(others=>'0');

    if i_cfg_rd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(0, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg0, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(1, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg1, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(2, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg2, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(3, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg3, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(4, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg4, rxd'length);

        end if;

        i_cfg_rxd<=rxd;

    end if;--//if p_in_cfg_rd='1' then
  end if;
end process;





process
  variable ftdi_d: std_logic_vector(7 downto 0):=(others=>'0');
--  variable dlen_vec: std_logic_vector(15 downto 0):=(others=>'0');
  variable dlen_int: integer:=0;
begin

--//-----------------
--//Инициализация:
--//-----------------
i_ftdi_d<=(others=>'Z');
i_ftdi_txe_n<='0';
i_ftdi_rxf_n<='1';
i_ftdi_pwren_n<='0';

for i in 0 to i_pkts'length-1 loop

  for x in 0 to i_pkts(i).h'length-1 loop
  i_pkts(i).h(x)<=(others=>'0');
  end loop;

  for x in 0 to i_pkts(i).d'length-1 loop
  i_pkts(i).d(x)<=(others=>'0');
  end loop;
end loop;


--//Pkt0
i_pkts(0).h(0)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT+1);
i_pkts(0).h(0)(C_CFGPKT_WR_BIT)<=C_CFGPKT_WR;
i_pkts(0).h(0)(C_CFGPKT_FIFO_BIT)<='0';

i_pkts(0).h(1)<=CONV_STD_LOGIC_VECTOR(16#00#, i_pkts(0).h(1)'length);--//Start Adr
i_pkts(0).h(2)<=CONV_STD_LOGIC_VECTOR(10#05#, i_pkts(0).h(2)'length);--//Len

i_pkts(0).d(0)<=CONV_STD_LOGIC_VECTOR(16#1011#, i_pkts(0).d(0)'length);
i_pkts(0).d(1)<=CONV_STD_LOGIC_VECTOR(16#2012#, i_pkts(0).d(0)'length);
i_pkts(0).d(2)<=CONV_STD_LOGIC_VECTOR(16#3013#, i_pkts(0).d(0)'length);
i_pkts(0).d(3)<=CONV_STD_LOGIC_VECTOR(16#4014#, i_pkts(0).d(0)'length);
i_pkts(0).d(4)<=CONV_STD_LOGIC_VECTOR(16#5015#, i_pkts(0).d(0)'length);

--//Pkt1
i_pkts(1).h(0)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT+1);
i_pkts(1).h(0)(C_CFGPKT_WR_BIT)<=C_CFGPKT_RD;
i_pkts(1).h(0)(C_CFGPKT_FIFO_BIT)<='0';

i_pkts(1).h(1)<=CONV_STD_LOGIC_VECTOR(16#01#, i_pkts(0).h(1)'length);--//Start Adr
i_pkts(1).h(2)<=CONV_STD_LOGIC_VECTOR(10#03#, i_pkts(0).h(2)'length);--//Len

i_pkts(1).d(0)<=CONV_STD_LOGIC_VECTOR(16#01#, i_pkts(0).d(0)'length);
i_pkts(1).d(1)<=CONV_STD_LOGIC_VECTOR(16#02#, i_pkts(0).d(0)'length);
i_pkts(1).d(2)<=CONV_STD_LOGIC_VECTOR(16#03#, i_pkts(0).d(0)'length);
i_pkts(1).d(3)<=CONV_STD_LOGIC_VECTOR(16#04#, i_pkts(0).d(0)'length);
i_pkts(1).d(4)<=CONV_STD_LOGIC_VECTOR(16#04#, i_pkts(0).d(0)'length);

--//Pkt2
i_pkts(2).h(0)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT+1);
i_pkts(2).h(0)(C_CFGPKT_WR_BIT)<=C_CFGPKT_RD;
i_pkts(2).h(0)(C_CFGPKT_FIFO_BIT)<='0';

i_pkts(2).h(1)<=CONV_STD_LOGIC_VECTOR(16#02#, i_pkts(0).h(1)'length);--//Start Adr
i_pkts(2).h(2)<=CONV_STD_LOGIC_VECTOR(10#02#, i_pkts(0).h(2)'length);--//Len

i_pkts(2).d(0)<=CONV_STD_LOGIC_VECTOR(16#01#, i_pkts(0).d(0)'length);
i_pkts(2).d(1)<=CONV_STD_LOGIC_VECTOR(16#02#, i_pkts(0).d(0)'length);
i_pkts(2).d(2)<=CONV_STD_LOGIC_VECTOR(16#03#, i_pkts(0).d(0)'length);
i_pkts(2).d(3)<=CONV_STD_LOGIC_VECTOR(16#04#, i_pkts(0).d(0)'length);
i_pkts(2).d(4)<=CONV_STD_LOGIC_VECTOR(16#04#, i_pkts(0).d(0)'length);


--//Pkt3
i_pkts(3).h(0)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT+1);
i_pkts(3).h(0)(C_CFGPKT_WR_BIT)<=C_CFGPKT_WR;
i_pkts(3).h(0)(C_CFGPKT_FIFO_BIT)<='0';

i_pkts(3).h(1)<=CONV_STD_LOGIC_VECTOR(16#01#, i_pkts(0).h(1)'length);--//Start Adr
i_pkts(3).h(2)<=CONV_STD_LOGIC_VECTOR(10#02#, i_pkts(0).h(2)'length);--//Len

i_pkts(3).d(0)<=CONV_STD_LOGIC_VECTOR(16#1021#, i_pkts(0).d(0)'length);
i_pkts(3).d(1)<=CONV_STD_LOGIC_VECTOR(16#2022#, i_pkts(0).d(0)'length);
i_pkts(3).d(2)<=CONV_STD_LOGIC_VECTOR(16#3023#, i_pkts(0).d(0)'length);
i_pkts(3).d(3)<=CONV_STD_LOGIC_VECTOR(16#4024#, i_pkts(0).d(0)'length);
i_pkts(3).d(4)<=CONV_STD_LOGIC_VECTOR(16#5025#, i_pkts(0).d(0)'length);


--//Pkt4
i_pkts(4).h(0)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT+1);
i_pkts(4).h(0)(C_CFGPKT_WR_BIT)<=C_CFGPKT_WR;
i_pkts(4).h(0)(C_CFGPKT_FIFO_BIT)<='0';

i_pkts(4).h(1)<=CONV_STD_LOGIC_VECTOR(16#02#, i_pkts(0).h(1)'length);--//Start Adr
i_pkts(4).h(2)<=CONV_STD_LOGIC_VECTOR(10#03#, i_pkts(0).h(2)'length);--//Len

i_pkts(4).d(0)<=CONV_STD_LOGIC_VECTOR(16#1031#, i_pkts(0).d(0)'length);
i_pkts(4).d(1)<=CONV_STD_LOGIC_VECTOR(16#2032#, i_pkts(0).d(0)'length);
i_pkts(4).d(2)<=CONV_STD_LOGIC_VECTOR(16#3033#, i_pkts(0).d(0)'length);
i_pkts(4).d(3)<=CONV_STD_LOGIC_VECTOR(16#4034#, i_pkts(0).d(0)'length);
i_pkts(4).d(4)<=CONV_STD_LOGIC_VECTOR(16#5035#, i_pkts(0).d(0)'length);


--//-----------------
--//Работа:
--//-----------------
wait until p_in_rst='0';
wait for 1 us;


--//PKT(Write)
i_ftdi_rxf_n<='0';

--dlen_vec:=i_pkts(0).h(2);
dlen_int:=CONV_INTEGER(i_pkts(0).h(2));

for i in 0 to i_pkts(0).h'length-1 loop
  for a in 0 to i_cfg_txd'length/8-1 loop
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='0';
    i_ftdi_d(7 downto 0)<=i_pkts(0).h(i)(8*(a+1)-1 downto 8*a) after dly;
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='1';
  end loop;
end loop;--//for i in 0 to dlen_int-1 loop

for i in 0 to dlen_int-1 loop
  for a in 0 to i_cfg_txd'length/8-1 loop
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='0';
    i_ftdi_d(7 downto 0)<=i_pkts(0).d(i)(8*(a+1)-1 downto 8*a) after dly;
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='1';
  end loop;
end loop;--//for i in 0 to dlen_int-1 loop

i_ftdi_rxf_n<='1';
i_ftdi_d<=(others =>'Z');

--//PKT(Read)
wait for 200 ns;
i_ftdi_rxf_n<='0';

--dlen_vec:=i_pkts(1).h(2);
dlen_int:=CONV_INTEGER(i_pkts(1).h(2));

for i in 0 to i_pkts(1).h'length-1 loop
  for a in 0 to i_cfg_txd'length/8-1 loop
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='0';
    i_ftdi_d(7 downto 0)<=i_pkts(1).h(i)(8*(a+1)-1 downto 8*a) after dly;
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='1';
  end loop;
end loop;--//for i in 0 to dlen_int-1 loop

i_ftdi_rxf_n<='1';
i_ftdi_d<=(others =>'Z');

--//PKT(Read)
wait for 200 ns;
i_ftdi_rxf_n<='0';

--dlen_vec:=i_pkts(1).h(2);
dlen_int:=CONV_INTEGER(i_pkts(2).h(2));

for i in 0 to i_pkts(2).h'length-1 loop
  for a in 0 to i_cfg_txd'length/8-1 loop
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='0';
    i_ftdi_d(7 downto 0)<=i_pkts(2).h(i)(8*(a+1)-1 downto 8*a) after dly;
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='1';
  end loop;
end loop;--//for i in 0 to dlen_int-1 loop

i_ftdi_rxf_n<='1';
i_ftdi_d<=(others =>'Z');



--//PKT(Write)
wait for 200 ns;
i_ftdi_rxf_n<='0';

--dlen_vec:=i_pkts(0).h(2);
dlen_int:=CONV_INTEGER(i_pkts(3).h(2));

for i in 0 to i_pkts(3).h'length-1 loop
  for a in 0 to i_cfg_txd'length/8-1 loop
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='0';
    i_ftdi_d(7 downto 0)<=i_pkts(3).h(i)(8*(a+1)-1 downto 8*a) after dly;
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='1';
  end loop;
end loop;--//for i in 0 to dlen_int-1 loop

for i in 0 to dlen_int-1 loop
  for a in 0 to i_cfg_txd'length/8-1 loop
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='0';
    i_ftdi_d(7 downto 0)<=i_pkts(3).d(i)(8*(a+1)-1 downto 8*a) after dly;
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='1';
  end loop;
end loop;--//for i in 0 to dlen_int-1 loop

i_ftdi_rxf_n<='1';
i_ftdi_d<=(others =>'Z');

--//PKT(Write)
wait for 200 ns;
i_ftdi_rxf_n<='0';

--dlen_vec:=i_pkts(0).h(2);
dlen_int:=CONV_INTEGER(i_pkts(4).h(2));

for i in 0 to i_pkts(3).h'length-1 loop
  for a in 0 to i_cfg_txd'length/8-1 loop
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='0';
    i_ftdi_d(7 downto 0)<=i_pkts(4).h(i)(8*(a+1)-1 downto 8*a) after dly;
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='1';
  end loop;
end loop;--//for i in 0 to dlen_int-1 loop

for i in 0 to dlen_int-1 loop
  for a in 0 to i_cfg_txd'length/8-1 loop
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='0';
    i_ftdi_d(7 downto 0)<=i_pkts(4).d(i)(8*(a+1)-1 downto 8*a) after dly;
    wait until i_ftdi_rd_n'event and i_ftdi_rd_n='1';
  end loop;
end loop;--//for i in 0 to dlen_int-1 loop

i_ftdi_rxf_n<='1';

i_ftdi_rxf_n<='1';
i_ftdi_d<=(others =>'Z');

wait;

end process;




--END MAIN
end behavior;
