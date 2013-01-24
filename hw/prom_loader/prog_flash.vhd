-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 29.11.2011 12:39:08
-- Module Name : prog_flash
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

library work;
use work.vicg_common_pkg.all;

entity prog_flash is
port(
--
p_out_txbuf_rd    : out   std_logic;
p_in_txbuf_d      : in    std_logic_vector(31 downto 0);
p_in_txbuf_empty  : in    std_logic;

p_out_rxbuf_d     : out   std_logic_vector(31 downto 0);
p_out_rxbuf_wr    : out   std_logic;
p_in_rxbuf_full   : in    std_logic;

--
p_out_status      : out   std_logic_vector(1 downto 0);

--PHY
p_out_phy_a       : out   std_logic_vector(23 downto 0);
p_in_phy_d        : in    std_logic_vector(15 downto 0);
p_out_phy_d       : out   std_logic_vector(15 downto 0);
p_out_phy_oe      : out   std_logic;
p_out_phy_we      : out   std_logic;
p_out_phy_cs      : out   std_logic;
p_in_phy_wait     : in    std_logic;

--Технологический
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(31 downto 0);

--System
p_in_clk_en       : in    std_logic;
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end prog_flash;


architecture behavioral of prog_flash is

constant CI_USR_CMD_ADR     : integer:=0;
--constant CI_USR_CMD_SIZE    : integer:=1;
constant CI_USR_CMD_UNLOCK  : integer:=1;
constant CI_USR_CMD_ERASE   : integer:=2;
constant CI_USR_CMD_DWR     : integer:=3;

constant CI_PHY_DIR_TX      : std_logic:='1';
constant CI_PHY_DIR_RX      : std_logic:='0';

constant CI_FLASH_BLOCK_16KW      : integer:=16#04000#;
constant CI_FLASH_BLOCK_64KW      : integer:=16#10000#;
constant CI_FLASH_BUF_DCOUNT_MAX  : integer:=512;--Word

type TFsm_state is (
S_IDLE                ,

S_UNLOCK_SETUP        ,
S_UNLOCK_CONFIRM      ,
S_UNLOCK_DEV_ID_S     ,
S_UNLOCK_DEV_ID_G     ,
S_UNLOCK_DEV_ID_CHK   ,

S_ERASE_STATUS_REG_CLR,
S_ERASE_SETUP         ,
S_ERASE_CONFIRM       ,
S_ERASE_STATUS_REG_S  ,
S_ERASE_STATUS_REG_G  ,
S_ERASE_STATUS_REG_CHK,
S_ERASE_WAIT          ,

S_WR_SETUP            ,
S_WR_STATUS_REG_G     ,
S_WR_STATUS_REG_CHK   ,
S_WR_DCOUNT_S         ,
S_WR_ADR_S            ,
S_WR_DATA             ,
S_WR_CONFIRM          ,
S_WR_STATUS_REG_S2    ,
S_WR_STATUS_REG_G2    ,
S_WR_STATUS_REG_CHK2  ,
S_WR_WAIT             ,
S_WR_PAD              ,

S_CMD_DONE
);
signal i_fsm_cs           : TFsm_state;

signal i_flash_wait       : std_logic;
signal i_flash_we_n       : std_logic;
signal i_flash_ce_n       : std_logic;
signal i_flash_oe_n       : std_logic;
signal i_flash_do         : std_logic_vector(15 downto 0);
signal i_flash_di         : std_logic_vector(15 downto 0);
signal i_flash_a          : std_logic_vector(23 downto 0);
signal i_flash_wbuf       : std_logic_vector(8 downto 0);

signal i_bcnt             : std_logic_vector(0 downto 0);
signal i_adr              : std_logic_vector(23 downto 0);
signal i_size             : std_logic_vector(23 downto 0);
signal i_size_cnt         : std_logic_vector(23 downto 0);
signal i_adr_cnt          : std_logic_vector(23 downto 0);
signal i_adr_end          : std_logic_vector(23 downto 0);
signal i_block_adr        : std_logic_vector(23 downto 0);
signal i_block_num        : std_logic_vector(8 downto 0);
signal i_block_end        : std_logic_vector(8 downto 0);

signal i_txbuf_rd         : std_logic;

signal i_irq              : std_logic;
signal i_err              : std_logic_vector(0 downto 0);

signal tst_fms_out,tst_fms: std_logic_vector(4 downto 0);
signal tst_flash_wait     : std_logic;
signal tst_flash_di       : std_logic_vector(i_flash_di'range);
signal tst_txbuf_rd       : std_logic;

--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst = '1' then
    tst_flash_wait <= '0';
    tst_flash_di <= (others=>'0');
    tst_txbuf_rd <= '0';
    tst_fms_out <= (others=>'0');
    p_out_tst <= (others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    tst_fms_out <= tst_fms;
    tst_flash_wait <= i_flash_wait;
    tst_flash_di <= i_flash_di;
    tst_txbuf_rd <= i_txbuf_rd and p_in_clk_en;
    p_out_tst(0) <= OR_reduce(tst_fms_out) or OR_reduce(tst_flash_di) or tst_flash_wait or tst_txbuf_rd;
  end if;
end process;

tst_fms<=CONV_STD_LOGIC_VECTOR(10#01#, tst_fms'length) when i_fsm_cs = S_UNLOCK_SETUP         else
         CONV_STD_LOGIC_VECTOR(10#02#, tst_fms'length) when i_fsm_cs = S_UNLOCK_CONFIRM       else
         CONV_STD_LOGIC_VECTOR(10#03#, tst_fms'length) when i_fsm_cs = S_UNLOCK_DEV_ID_S      else
         CONV_STD_LOGIC_VECTOR(10#04#, tst_fms'length) when i_fsm_cs = S_UNLOCK_DEV_ID_G      else
         CONV_STD_LOGIC_VECTOR(10#05#, tst_fms'length) when i_fsm_cs = S_UNLOCK_DEV_ID_CHK    else

         CONV_STD_LOGIC_VECTOR(10#06#, tst_fms'length) when i_fsm_cs = S_ERASE_STATUS_REG_CLR else
         CONV_STD_LOGIC_VECTOR(10#07#, tst_fms'length) when i_fsm_cs = S_ERASE_SETUP          else
         CONV_STD_LOGIC_VECTOR(10#08#, tst_fms'length) when i_fsm_cs = S_ERASE_CONFIRM        else
         CONV_STD_LOGIC_VECTOR(10#09#, tst_fms'length) when i_fsm_cs = S_ERASE_STATUS_REG_S   else
         CONV_STD_LOGIC_VECTOR(10#10#, tst_fms'length) when i_fsm_cs = S_ERASE_STATUS_REG_G   else
         CONV_STD_LOGIC_VECTOR(10#11#, tst_fms'length) when i_fsm_cs = S_ERASE_STATUS_REG_CHK else
         CONV_STD_LOGIC_VECTOR(10#12#, tst_fms'length) when i_fsm_cs = S_ERASE_WAIT           else

         CONV_STD_LOGIC_VECTOR(10#13#, tst_fms'length) when i_fsm_cs = S_WR_SETUP             else
         CONV_STD_LOGIC_VECTOR(10#14#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_G      else
         CONV_STD_LOGIC_VECTOR(10#15#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_CHK    else
         CONV_STD_LOGIC_VECTOR(10#16#, tst_fms'length) when i_fsm_cs = S_WR_DCOUNT_S          else
         CONV_STD_LOGIC_VECTOR(10#17#, tst_fms'length) when i_fsm_cs = S_WR_ADR_S             else
         CONV_STD_LOGIC_VECTOR(10#18#, tst_fms'length) when i_fsm_cs = S_WR_DATA              else
         CONV_STD_LOGIC_VECTOR(10#19#, tst_fms'length) when i_fsm_cs = S_WR_CONFIRM           else
         CONV_STD_LOGIC_VECTOR(10#20#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_S2     else
         CONV_STD_LOGIC_VECTOR(10#21#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_G2     else
         CONV_STD_LOGIC_VECTOR(10#22#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_CHK2   else
         CONV_STD_LOGIC_VECTOR(10#23#, tst_fms'length) when i_fsm_cs = S_WR_WAIT              else
         CONV_STD_LOGIC_VECTOR(10#24#, tst_fms'length) when i_fsm_cs = S_WR_PAD               else

         CONV_STD_LOGIC_VECTOR(10#25#, tst_fms'length) when i_fsm_cs = S_CMD_DONE             else
         CONV_STD_LOGIC_VECTOR(10#00#, tst_fms'length);-- when i_fsm_state=CONV_STD_LOGIC_VECTOR(0 , i_fsm_state'length);


--//----------------------------------
--//
--//----------------------------------
p_out_status(0) <= i_irq;
p_out_status(1 downto 1) <= i_err;

p_out_txbuf_rd <= i_txbuf_rd and p_in_clk_en when i_fsm_cs /= S_WR_DATA else (not i_flash_we_n and AND_reduce(i_bcnt) and p_in_clk_en);

i_flash_wait <= p_in_phy_wait;
i_flash_di <= p_in_phy_d;
p_out_phy_d <= i_flash_do;
p_out_phy_a <= i_flash_a;
p_out_phy_oe <= i_flash_oe_n;
p_out_phy_we <= i_flash_we_n;
p_out_phy_cs <= i_flash_ce_n;


i_adr_end <= i_adr + i_size;

i_block_end <= EXT(i_adr_end(23 downto 16), i_block_end'length);
i_block_num <= EXT(i_adr_cnt(23 downto 16), i_block_num'length); --номер блока
i_block_adr <= i_adr_cnt(23 downto 16) & CONV_STD_LOGIC_VECTOR(0, 16); --адрес блока

i_flash_wbuf <= i_adr_cnt(8 downto 0);--max 512Word

process(p_in_rst, p_in_clk)
begin
  if p_in_rst='1' then

    i_fsm_cs <= S_IDLE;

    i_adr_cnt <= (others=>'0');
    i_adr <= (others=>'0');

    i_size_cnt <= (others=>'0');
    i_size <= (others=>'0');

    i_bcnt <= (others=>'0');

    i_flash_we_n <= '1';
    i_flash_ce_n <= '1';
    i_flash_oe_n <= CI_PHY_DIR_TX;
    i_flash_do <= (others=>'0');
    i_flash_a <= (others=>'0');

    i_txbuf_rd <= '0';

    i_irq <= '0';
    i_err <= (others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_clk_en = '1' then
    case i_fsm_cs is

        ---------------------------------------------
        --WAIT USR CMD
        ---------------------------------------------
        when S_IDLE =>

          i_flash_we_n <= '1';
          i_flash_oe_n <= CI_PHY_DIR_TX;

          if p_in_txbuf_empty ='0' then

              i_txbuf_rd <= '1';
              i_irq <= '0';
              i_err <= (others=>'0');

              if p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ADR, 4) then
                i_adr <= p_in_txbuf_d(23+4 downto 0+4);
                i_fsm_cs <= S_CMD_DONE;

--              elsif p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_SIZE, 4) then
--                i_size <= p_in_txbuf_d(23+4 downto 0+4);
--                i_fsm_cs <= S_CMD_DONE;

              elsif p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_UNLOCK, 4) then
                i_size <= p_in_txbuf_d(23+4 downto 0+4) - 1;
                i_adr_cnt <= i_adr;
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_UNLOCK_SETUP;

              elsif p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ERASE, 4) then
                i_size <= p_in_txbuf_d(23+4 downto 0+4) - 1;
                i_adr_cnt <= i_adr;
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_ERASE_STATUS_REG_CLR;

              elsif p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DWR, 4) then
                i_size <= p_in_txbuf_d(23+4 downto 0+4) - 1;
                i_adr_cnt <= i_adr;
                i_size_cnt <= i_size;
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_WR_SETUP;

              --elsif p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DRD, 4) then
              --  i_adr_cnt <= i_adr;
              --  i_flash_ce_n <= '0';
              --  i_fsm_cs <= S_WR_SETUP;

              end if;
          else
            i_flash_ce_n <= '1';
          end if;


        ---------------------------------------------
        --BLOCK UNLOCK
        ---------------------------------------------
        when S_UNLOCK_SETUP =>

            i_txbuf_rd <= '0';

            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#60#, i_flash_do'length);
              i_flash_we_n <= '0';
              i_fsm_cs <= S_UNLOCK_CONFIRM;
            end if;

        when S_UNLOCK_CONFIRM =>

            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#D0#, i_flash_do'length);
              i_flash_we_n <= '0';
              i_fsm_cs <= S_UNLOCK_DEV_ID_S;
            else
              i_flash_we_n <= '1';
            end if;

        when S_UNLOCK_DEV_ID_S =>
        --Read Device Identifier register (Bus Cycles=2/1)

            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr + 2;
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#90#, i_flash_do'length);
              i_flash_we_n <= '0';
              i_fsm_cs <= S_UNLOCK_DEV_ID_G;
            else
              i_flash_we_n <= '1';
            end if;

        when S_UNLOCK_DEV_ID_G =>
        --Read Device Identifier register (Bus Cycles=2/2)
            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr + 2;
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_UNLOCK_DEV_ID_CHK;
            else
              i_flash_we_n <= '1';
              i_flash_oe_n <= CI_PHY_DIR_TX;
            end if;

        when S_UNLOCK_DEV_ID_CHK =>

            if i_flash_wait = '1' then
                if i_flash_di(0) = '0' then
                --Block is unlocked
                  i_flash_oe_n <= CI_PHY_DIR_TX;

                  if i_block_num = i_block_end then
                    i_fsm_cs <= S_CMD_DONE;
                  else
                    if i_block_num >= CONV_STD_LOGIC_VECTOR(16#FF#, i_block_num'length) then
                      i_adr_cnt <= i_adr_cnt + CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_16KW, i_adr_cnt'length);
                    else
                      i_adr_cnt <= i_adr_cnt + CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_64KW, i_adr_cnt'length);
                    end if;

                    i_fsm_cs <= S_UNLOCK_SETUP;
                  end if;

                else
                --Block is locked
                  i_flash_oe_n <= CI_PHY_DIR_TX;
                  i_err <= CONV_STD_LOGIC_VECTOR(16#01#, i_err'length);
                  i_fsm_cs <= S_UNLOCK_SETUP;
                end if;
            else
              i_flash_oe_n <= CI_PHY_DIR_RX;
            end if;


        ---------------------------------------------
        --BLOCK ERASE
        ---------------------------------------------
        when S_ERASE_STATUS_REG_CLR =>

            i_txbuf_rd <= '0';

            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#50#, i_flash_do'length);
              i_flash_we_n <= '0';
              i_fsm_cs <= S_ERASE_SETUP;
            else
              i_flash_we_n <= '1';
            end if;

        when S_ERASE_SETUP =>

            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#20#, i_flash_do'length);
              i_flash_we_n <= '0';
              i_fsm_cs <= S_ERASE_CONFIRM;
            else
              i_flash_we_n <= '1';
            end if;

        when S_ERASE_CONFIRM =>

            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#D0#, i_flash_do'length);
              i_flash_we_n <= '0';
              i_fsm_cs <= S_ERASE_STATUS_REG_S;
            else
              i_flash_we_n <= '1';
            end if;

        when S_ERASE_STATUS_REG_S =>
        --Read Status Register (Bus Cycles=2/1)
            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#70#, i_flash_do'length);
              i_flash_we_n <= '0';
              i_fsm_cs <= S_ERASE_STATUS_REG_G;
            else
              i_flash_we_n <= '1';
            end if;

        when S_ERASE_STATUS_REG_G =>
        --Read Status Register (Bus Cycles=2/2)
            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_ERASE_STATUS_REG_CHK;
            else
              i_flash_we_n <= '1';
              i_flash_oe_n <= CI_PHY_DIR_TX;
            end if;

        when S_ERASE_STATUS_REG_CHK =>

            if i_flash_wait = '1' then
                i_flash_oe_n <= CI_PHY_DIR_TX;

                if i_flash_di(7 downto 0) = CONV_STD_LOGIC_VECTOR(16#80#, 8) then
                --bit(7) - Device is ready
                --Erase - OK
                  if i_block_num = i_block_end then
                    i_fsm_cs <= S_CMD_DONE;
                  else
                    if i_block_num >= CONV_STD_LOGIC_VECTOR(16#FF#, i_block_num'length - 1) then
                      i_adr_cnt <= i_adr_cnt + CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_16KW, i_adr_cnt'length);
                    else
                      i_adr_cnt <= i_adr_cnt + CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_64KW, i_adr_cnt'length);
                    end if;

                    i_fsm_cs <= S_ERASE_STATUS_REG_CLR;
                  end if;

                elsif i_flash_di(7) = '1' then
                --Erase - ERROR
                  i_err <= CONV_STD_LOGIC_VECTOR(16#01#, i_err'length);
                  i_fsm_cs <= S_CMD_DONE;

                else
                  i_fsm_cs <= S_ERASE_WAIT;

                end if;
            else
              i_flash_oe_n <= CI_PHY_DIR_RX;

            end if;

        when S_ERASE_WAIT =>

            if i_flash_oe_n = CI_PHY_DIR_TX then
            --OE# to update Status Register
              i_flash_a <= i_block_adr;
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_ERASE_STATUS_REG_CHK;
            end if;


        ---------------------------------------------
        --WRITE DATA
        ---------------------------------------------
        when S_WR_SETUP =>

            i_txbuf_rd <= '0';

            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#E8#, i_flash_do'length);
              i_flash_we_n <= '0';
              i_flash_oe_n <= CI_PHY_DIR_TX;
              i_fsm_cs <= S_WR_STATUS_REG_G;
            else
              i_flash_we_n <= '1';
            end if;

        when S_WR_STATUS_REG_G =>

            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_WR_STATUS_REG_CHK;
            else
              i_flash_we_n <= '1';
              i_flash_oe_n <= CI_PHY_DIR_TX;
            end if;

        when S_WR_STATUS_REG_CHK =>

            if i_flash_wait = '1' then
                i_flash_oe_n <= CI_PHY_DIR_TX;

                if i_flash_di(7) = '1' then
                --bit(7) - Device is ready
                    i_fsm_cs <= S_WR_DCOUNT_S;

                else
                  i_fsm_cs <= S_WR_WAIT;

                end if;
            else
              i_flash_oe_n <= CI_PHY_DIR_RX;

            end if;

        when S_WR_DCOUNT_S =>

            if i_flash_we_n = '1' then

              if i_size_cnt >= CONV_STD_LOGIC_VECTOR(CI_FLASH_BUF_DCOUNT_MAX, i_size_cnt'length) then
                i_flash_do <= CONV_STD_LOGIC_VECTOR(CI_FLASH_BUF_DCOUNT_MAX - 1, i_flash_do'length);--0  corresponds to count = 1
              else
                i_flash_do <= i_size_cnt(i_flash_do'range) - 1;
              end if;

              i_flash_a <= i_block_adr;
              i_flash_we_n <= '0';
              i_fsm_cs <= S_WR_ADR_S;
            else
              i_flash_we_n <= '1';
            end if;

        when S_WR_ADR_S =>

            if i_flash_we_n = '1' then
              if p_in_txbuf_empty = '0' then
                  for i in 0 to i_flash_do'length/8 - 1 loop
                    if i_bcnt=i then
                      i_flash_do <= p_in_txbuf_d(i_flash_do'length*(i+1)-1 downto i_flash_do'length*i);
                    end if;
                  end loop;

                  i_flash_a <= i_adr_cnt;--старт адрес внутри блока
                  i_flash_we_n <= '0';

                  i_bcnt <= i_bcnt + 1;
                  i_adr_cnt <= i_adr_cnt + 1;

                  i_fsm_cs <= S_WR_DATA;
              else
                i_flash_we_n <= '1';
              end if;
            else
              i_flash_we_n <= '1';
            end if;

        when S_WR_DATA =>

            if i_flash_we_n = '1' then
              if p_in_txbuf_empty = '0' then
                  for i in 0 to i_flash_do'length/8 - 1 loop
                    if i_bcnt=i then
                      i_flash_do <= p_in_txbuf_d(i_flash_do'length*(i+1)-1 downto i_flash_do'length*i);
                    end if;
                  end loop;

                  i_flash_a <= i_block_adr;
                  i_flash_we_n <= '0';

                  if i_flash_wbuf = CONV_STD_LOGIC_VECTOR(CI_FLASH_BUF_DCOUNT_MAX - 1, i_flash_wbuf'length) then
                    if i_adr_cnt = i_adr_end then
                      i_fsm_cs <= S_WR_CONFIRM;
                    else
                      i_fsm_cs <= S_WR_CONFIRM;
                    end if;

                  elsif i_adr_cnt = i_adr_end then
                    i_fsm_cs <= S_WR_PAD;

                  end if;

                  i_adr_cnt <= i_adr_cnt + 1;
                  i_bcnt <= i_bcnt + 1;
              else
                i_flash_we_n <= '1';
              end if;
            else
              i_flash_we_n <= '1';
            end if;

        when S_WR_PAD =>

            if i_flash_we_n = '1' then
                i_flash_a <= i_block_adr;
                i_flash_do <= (others=>'0');
                i_flash_we_n <= '0';

                if i_flash_wbuf = CONV_STD_LOGIC_VECTOR(CI_FLASH_BUF_DCOUNT_MAX - 1, i_flash_wbuf'length) then
                  i_fsm_cs <= S_WR_CONFIRM;
                end if;

                i_adr_cnt <= i_adr_cnt + 1;
            else
              i_flash_we_n <= '1';
            end if;

        when S_WR_CONFIRM =>

            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#D0#, i_flash_do'length);
              i_flash_we_n <= '0';
              i_fsm_cs <= S_WR_STATUS_REG_S2;
            else
              i_flash_we_n <= '1';
            end if;

        when S_WR_STATUS_REG_S2 =>
        --Read Status Register (Bus Cycles=2/1)
            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#70#, i_flash_do'length);
              i_flash_we_n <= '0';
              i_fsm_cs <= S_WR_STATUS_REG_G2;
            else
              i_flash_we_n <= '1';
            end if;

        when S_WR_STATUS_REG_G2 =>
        --Read Status Register (Bus Cycles=2/2)
            if i_flash_we_n = '1' then
              i_flash_a <= i_block_adr;
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_WR_STATUS_REG_CHK2;
            else
              i_flash_we_n <= '1';
              i_flash_oe_n <= CI_PHY_DIR_TX;
            end if;

        when S_WR_STATUS_REG_CHK2 =>

            if i_flash_wait = '1' then
                i_flash_oe_n <= CI_PHY_DIR_TX;

                if i_flash_di(7 downto 0) = CONV_STD_LOGIC_VECTOR(16#80#, 8) then
                --bit(7) - Device is ready
                --BLOCK WRITE - OK
                  if i_block_num = i_block_end then
                    i_fsm_cs <= S_CMD_DONE;
                  else
                    i_fsm_cs <= S_ERASE_STATUS_REG_CLR;
                  end if;

                elsif i_flash_di(7) = '1' then
                --BLOCK WRITE - ERROR
                  i_fsm_cs <= S_UNLOCK_SETUP;

                else
                  i_fsm_cs <= S_ERASE_WAIT;

                end if;
            else
              i_flash_oe_n <= CI_PHY_DIR_RX;

            end if;

        when S_WR_WAIT =>

            if i_flash_wait = '1' then
              i_fsm_cs <= S_WR_WAIT;
            end if;

        ---------------------------------------------
        --Команда завершена
        ---------------------------------------------
        when S_CMD_DONE =>

          i_flash_ce_n <= '1';
          i_txbuf_rd <= '0';
          i_irq <= '1';
          i_bcnt <= (others=>'0');
          i_fsm_cs <= S_IDLE;

    end case;
    end if;
  end if;
end process;


--END MAIN
end behavioral;
