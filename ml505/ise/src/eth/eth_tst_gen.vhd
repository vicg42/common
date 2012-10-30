-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 26.10.2012 13:05:53
-- Module Name : eth_tst_gen
--
-- Назначение/Описание :
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.eth_pkg.all;

entity eth_tst_gen is
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_pkt_dly     : in    std_logic_vector(31 downto 0);
p_in_work        : in    std_logic;

--------------------------------------
--Связь с пользовательским TXBUF
--------------------------------------
p_out_txbuf_din  : out   std_logic_vector(31 downto 0);
p_out_txbuf_wr   : out   std_logic;
p_in_txbuf_full  : in    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end eth_tst_gen;

architecture behavioral of eth_tst_gen is

constant CI_VFR_PIX_COUNT    : integer:=1024;
constant CI_VFR_ROW_COUNT    : integer:=1024;
constant CI_PKT_HEADER_SIZE  : integer:=5*4;--Byte

constant CI_PKT_DLENGTH      : integer:=CI_PKT_HEADER_SIZE + CI_VFR_PIX_COUNT - 2;--Длина пакета в байтах без учёта длины самого поля
constant CI_PKT_TYPE         : integer:=1;
constant CI_PKT_SUBTYPE      : integer:=0;--номер видео канала
constant CI_PKT_SRC          : integer:=3;

----------------------------------------------------------------------------
--структура пакета
----------------------------------------------------------------------------
--   |31..28 | 27..24 | 23..20 | 19..16 | 15..12 | 11..08 | 07..04 | 03..00
--   |---------------------------------------------------------------------
--DW0|  SING(CI_PKT_SRC/SUBTYPE/type)   |    LENGTH - Длина пакета в байтах без учёта длины самого поля
--   |---------------------------------------------------------------------
--DW1|  Ширина кадра в пикселях         |                          |  Номер кадра
--   |---------------------------------------------------------------------
--DW2|  Номер строки                    |     Высота кадра в пикселях
--   |---------------------------------------------------------------------
--DW3|  TimeL                           |
--   |---------------------------------------------------------------------
--DW4|                                  |    TimeH
--   |---------------------------------------------------------------------

type TEth_fsm_rx is (
S_IDLE ,
S_H0   ,
S_H1   ,
S_H2   ,
S_H3   ,
S_H4   ,
S_DATA ,
S_DLY
);
signal fsm_tstgen_cs: TEth_fsm_rx;

signal i_pkt_d                : std_logic_vector(31 downto 0);
signal i_pkt_wr               : std_logic;

signal i_vfr_pix_cnt          : std_logic_vector(15 downto 0);
signal i_vfr_row_cnt          : std_logic_vector(15 downto 0);
signal i_vfr_cnt              : std_logic_vector(3 downto 0);
signal i_vfr_row_done         : std_logic;

signal i_dly_cnt              : std_logic_vector(31 downto 0);
signal i_dly_count            : std_logic_vector(31 downto 0);

signal tst_fms_cs             : std_logic_vector(3 downto 0);
signal tst_fms_cs_dly         : std_logic_vector(tst_fms_cs'range);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_fms_cs_dly<=(others=>'0');
    p_out_tst(31 downto 1)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_dly<=tst_fms_cs;
    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
  end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_tstgen_cs=S_H0   else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_tstgen_cs=S_H1   else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_tstgen_cs=S_H2   else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_tstgen_cs=S_H3   else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_tstgen_cs=S_H4   else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_tstgen_cs=S_DATA else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_tstgen_cs=S_DLY  else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);-- when fsm_tstgen_cs=S_IDLE else

end generate gen_dbg_on;


--//-------------------------------------------
--//
--//-------------------------------------------
p_out_txbuf_din <= i_pkt_d;
p_out_txbuf_wr  <= i_pkt_wr;


process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_tstgen_cs<=S_IDLE;

    i_pkt_d <= (others=>'0');
    i_pkt_wr <= '0';

    i_vfr_pix_cnt <= (others=>'0');
    i_vfr_row_cnt <= (others=>'0');
    i_vfr_cnt <= (others=>'0');
    i_vfr_row_done <= '0';

    i_dly_cnt <= (others=>'0');
    i_dly_count <= (others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

        case fsm_tstgen_cs is

          --------------------------------------
          --
          --------------------------------------
          when S_IDLE =>

              if p_in_work='1' then
                i_dly_count <= p_in_pkt_dly;
                fsm_tstgen_cs <= S_H0;
              end if;

          --------------------------------------
          --PKT Header
          --------------------------------------
          when S_H0 =>

            if p_in_txbuf_full='0' then
              i_pkt_d(15 downto  0) <= CONV_STD_LOGIC_VECTOR(CI_PKT_DLENGTH, 16);
              i_pkt_d(31 downto 16) <= CONV_STD_LOGIC_VECTOR(CI_PKT_SRC, 8) &
                                       CONV_STD_LOGIC_VECTOR(CI_PKT_SUBTYPE, 4) &
                                       CONV_STD_LOGIC_VECTOR(CI_PKT_TYPE, 4);
              i_pkt_wr <= '1';
              fsm_tstgen_cs <= S_H1;
            else
              i_pkt_wr <= '0';
            end if;

          when S_H1 =>

            if p_in_txbuf_full='0' then
              i_pkt_d(3  downto  0) <= i_vfr_cnt;
              i_pkt_d(15 downto  4) <= (others=>'0');
              i_pkt_d(31 downto 16) <= CONV_STD_LOGIC_VECTOR(CI_VFR_PIX_COUNT, 16);

              i_pkt_wr <= '1';
              fsm_tstgen_cs <= S_H2;
            else
              i_pkt_wr <= '0';
            end if;

          when S_H2 =>

            if p_in_txbuf_full='0' then
              i_pkt_d(15 downto  0) <= CONV_STD_LOGIC_VECTOR(CI_VFR_ROW_COUNT, 16);
              i_pkt_d(31 downto 16) <= i_vfr_row_cnt;

              i_pkt_wr <= '1';
              fsm_tstgen_cs <= S_H3;
            else
              i_pkt_wr <= '0';
            end if;

          when S_H3 =>

            if p_in_txbuf_full='0' then
              i_pkt_d(15 downto  0) <= (others=>'0');
              i_pkt_d(31 downto 16) <= (others=>'0');

              i_pkt_wr <= '1';
              fsm_tstgen_cs <= S_H4;
            else
              i_pkt_wr <= '0';
            end if;

          when S_H4 =>

            if p_in_txbuf_full='0' then
              i_pkt_d(15 downto  0) <= (others=>'0');
              i_pkt_d(31 downto 16) <= (others=>'0');

              i_pkt_wr <= '1';
              fsm_tstgen_cs <= S_DATA;
            else
              i_pkt_wr <= '0';
            end if;

          --------------------------------------
          --PKT DATA
          --------------------------------------
          when S_DATA =>

            if p_in_txbuf_full='0' then
              if i_vfr_pix_cnt=CONV_STD_LOGIC_VECTOR(CI_VFR_PIX_COUNT/4-1, i_vfr_pix_cnt'length) then
                if i_vfr_row_cnt=CONV_STD_LOGIC_VECTOR(CI_VFR_ROW_COUNT-1, i_vfr_row_cnt'length) then
                  i_vfr_row_cnt <= (others=>'0');
                  i_vfr_row_done <= '1';
                  i_vfr_cnt <= i_vfr_cnt + 1;
                else
                  i_vfr_row_cnt <= i_vfr_row_cnt + 1;
                end if;

                i_vfr_pix_cnt <= (others=>'0');
                fsm_tstgen_cs <= S_DLY;

              else
                i_vfr_pix_cnt <= i_vfr_pix_cnt + 1;
              end if;

              --Тестовые данные: счетчик
              for i in 0 to 3 loop
              i_pkt_d(8*(i+1)-1 downto 8*i) <= (i_vfr_pix_cnt(5 downto 0)&"00") + i;
              end loop;
              i_pkt_wr <= '1';

            else
              i_pkt_wr <= '0';
            end if;

          --------------------------------------
          --PKT DELAY
          --------------------------------------
          when S_DLY =>

            i_pkt_wr <= '0';

            if i_dly_cnt=i_dly_count then
              i_dly_cnt <= (others=>'0');

              if i_vfr_row_done='1' then
                fsm_tstgen_cs <= S_IDLE;
              else
                fsm_tstgen_cs <= S_H0;
              end if;
            else
              i_dly_cnt <= i_dly_cnt + 1;
            end if;

        end case;

  end if;
end process;



--END MAIN
end behavioral;
