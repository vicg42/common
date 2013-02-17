-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 29.11.2011 12:39:08
-- Module Name : prog_flash
--
-- Назначение/Описание :
-- FLASH device : JS28F256P30TF
--
-- WRITE: 1 - USR_CMD_ADR + ADR(byte)
--        2 - USR_CMD_ERASE + SIZE(byte)
--         hardware:1. blocks unlock
--                  2. blocks erase
--        3 - USR_CMD_DWR + SIZE(byte)
--
-- READ:  1 - USR_CMD_ADR + ADR(byte)
--        2 - USR_CMD_DRD + SIZE(byte)
--
-- READ CFI:  1 - USR_CMD_DRD_CFI + ADR(byte)
--            2 - USR_CMD_DRD + SIZE(byte)
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
generic(
G_USRBUF_DWIDTH : integer := 32;
G_FLASH_AWIDTH : integer := 24;
G_FLASH_DWIDTH : integer := 16;
G_FLASH_BUF_SIZE_MAX : integer := 32;
G_FLASH_OPT : std_logic_vector(3 downto 0) := (others=>'0') --G_FLASH_OPT(0)='0'/'1'  -- FLASH (Top Boot)/Bottom Boot
);
port(
--fpga -> flash
p_out_txbuf_rd    : out   std_logic;
p_in_txbuf_d      : in    std_logic_vector(G_USRBUF_DWIDTH - 1 downto 0);
p_in_txbuf_empty  : in    std_logic;
--fpga <- flash
p_out_rxbuf_d     : out   std_logic_vector(G_USRBUF_DWIDTH - 1 downto 0);
p_out_rxbuf_wr    : out   std_logic;
p_in_rxbuf_full   : in    std_logic;

--
p_out_irq         : out   std_logic;
p_out_status      : out   std_logic_vector(7 downto 0);

--PHY
p_out_phy_a       : out   std_logic_vector(G_FLASH_AWIDTH - 1 downto 0);
p_in_phy_d        : in    std_logic_vector(G_FLASH_DWIDTH - 1 downto 0);
p_out_phy_d       : out   std_logic_vector(G_FLASH_DWIDTH - 1 downto 0);
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

constant CI_USR_CMD_ADR     : integer:=1;
constant CI_USR_CMD_DWR     : integer:=2;
constant CI_USR_CMD_DRD     : integer:=3;
constant CI_USR_CMD_DRD_CFI : integer:=4;
constant CI_USR_CMD_UNLOCK  : integer:=6;
constant CI_USR_CMD_ERASE   : integer:=5;

constant CI_PHY_DIR_TX      : std_logic:='1';
constant CI_PHY_DIR_RX      : std_logic:='0';

constant CI_FLASH_BLOCK_16KW : integer:=16#04000#;
constant CI_FLASH_BLOCK_64KW : integer:=16#10000#;

constant CI_FLASH_BLOCK0_INC : integer := selval (CI_FLASH_BLOCK_64KW, CI_FLASH_BLOCK_16KW, (G_FLASH_OPT(0)/='1'));
constant CI_FLASH_BLOCK1_INC : integer := selval (CI_FLASH_BLOCK_16KW, CI_FLASH_BLOCK_64KW, (G_FLASH_OPT(0)/='1'));
constant CI_FLASH_BLOCK0_BOUNDARY : integer := selval (16#FF0000#, 16#10000#, (G_FLASH_OPT(0)/='1'));

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
S_ERASE_STATUS_REG_G  ,
S_ERASE_STATUS_REG_CHK,
S_ERASE_WAIT          ,

S_WR_SETUP            ,
S_WR_STATUS_REG_G     ,
S_WR_STATUS_REG_CHK   ,
S_WR_DCOUNT           ,
S_WR_DATA0            ,
S_WR_DATAN            ,
S_WR_CONFIRM          ,
S_WR_STATUS_REG_G2    ,
S_WR_STATUS_REG_CHK2  ,
S_WR_WAIT             ,

S_RD_SETUP            ,
S_RD_START            ,
S_RD_N                ,
S_RD_WAIT             ,

S_CFI_SETUP           ,
S_CFI_RD_START        ,
S_CFI_RD_N            ,
S_CFI_RD_WAIT         ,

S_CMD_DONE,
S_CMD_ERR
);
signal i_fsm_cs           : TFsm_state;
signal i_fsm_return       : std_logic_vector(0 downto 0);

--signal i_flash_wait       : std_logic;
signal i_flash_we_n       : std_logic;
signal i_flash_ce_n       : std_logic;
signal i_flash_oe_n       : std_logic;
signal i_flash_do         : std_logic_vector(p_out_phy_d'range);
signal i_flash_di         : std_logic_vector(p_in_phy_d'range);
signal i_flash_a          : std_logic_vector(p_out_phy_a'range);

signal i_cfi_bcnt         : std_logic_vector(log2(G_USRBUF_DWIDTH / 8) - 1 downto 0);
signal i_bcnt             : std_logic_vector(log2(G_USRBUF_DWIDTH / G_FLASH_DWIDTH) - 1 downto 0);
signal i_adr_byte         : std_logic_vector(p_out_phy_a'range);
signal i_adr              : std_logic_vector(p_out_phy_a'range);
signal i_adr_cnt          : std_logic_vector(p_out_phy_a'range);
signal i_adr_end          : std_logic_vector(p_out_phy_a'range);
signal i_size_byte        : std_logic_vector(p_out_phy_a'range);
signal i_size             : std_logic_vector(p_out_phy_a'range);
signal i_size_tmp         : std_logic_vector(p_out_phy_a'range);
signal i_size_cnt         : std_logic_vector(p_out_phy_a'range);
signal i_size_remain      : std_logic_vector(p_out_phy_a'range);
signal i_trn_size         : std_logic_vector(p_out_phy_a'range);
signal i_block_adr        : std_logic_vector(p_out_phy_a'range);
signal i_block_num        : std_logic_vector(8 downto 0);
signal i_block_end        : std_logic_vector(8 downto 0);

signal i_rxbuf_di         : std_logic_vector(p_out_rxbuf_d'range);
signal i_txbuf_rd         : std_logic;
signal i_txbuf_rd_last    : std_logic;
signal i_rxbuf_wr         : std_logic;
signal i_rxbuf_wr_last    : std_logic;
signal i_rxbuf_wr_out     : std_logic;

signal i_irq              : std_logic;
signal i_err              : std_logic_vector(7 downto 0);

signal tst_fms_out,tst_fms: std_logic_vector(4 downto 0);
signal tst_flash_di       : std_logic_vector(i_flash_di'range);
signal tst_txbuf_rd       : std_logic;
signal tst_txbuf_empty    : std_logic;
signal tst_done           : std_logic;
signal tst_err            : std_logic;


--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst = '1' then
    tst_flash_di <= (others=>'0');
    tst_txbuf_rd <= '0';
    tst_fms_out <= (others=>'0');
    tst_err <= '0';
    p_out_tst <= (others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    tst_fms_out <= tst_fms;
    tst_txbuf_empty <= p_in_txbuf_empty;
    tst_flash_di <= i_flash_di;
    if i_fsm_cs = S_WR_DATA0 or i_fsm_cs = S_WR_DATAN then
    tst_txbuf_rd <= (not i_flash_we_n and not p_in_txbuf_empty and AND_reduce(i_bcnt) and p_in_clk_en);
    else
    tst_txbuf_rd <= (i_txbuf_rd and p_in_clk_en);
    end if;
    tst_err <= OR_reduce(i_err);
    p_out_tst(0) <= OR_reduce(tst_fms_out) or OR_reduce(tst_flash_di) or tst_txbuf_rd or tst_txbuf_empty or tst_done or tst_err;
  end if;
end process;

tst_fms<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms'length) when i_fsm_cs = S_UNLOCK_SETUP         else
         CONV_STD_LOGIC_VECTOR(16#02#, tst_fms'length) when i_fsm_cs = S_UNLOCK_CONFIRM       else
         CONV_STD_LOGIC_VECTOR(16#03#, tst_fms'length) when i_fsm_cs = S_UNLOCK_DEV_ID_S      else
         CONV_STD_LOGIC_VECTOR(16#04#, tst_fms'length) when i_fsm_cs = S_UNLOCK_DEV_ID_G      else
         CONV_STD_LOGIC_VECTOR(16#05#, tst_fms'length) when i_fsm_cs = S_UNLOCK_DEV_ID_CHK    else
         CONV_STD_LOGIC_VECTOR(16#06#, tst_fms'length) when i_fsm_cs = S_CMD_ERR              else
         CONV_STD_LOGIC_VECTOR(16#07#, tst_fms'length) when i_fsm_cs = S_ERASE_STATUS_REG_CLR else
         CONV_STD_LOGIC_VECTOR(16#08#, tst_fms'length) when i_fsm_cs = S_ERASE_SETUP          else
         CONV_STD_LOGIC_VECTOR(16#09#, tst_fms'length) when i_fsm_cs = S_ERASE_CONFIRM        else
         CONV_STD_LOGIC_VECTOR(16#0A#, tst_fms'length) when i_fsm_cs = S_ERASE_STATUS_REG_G   else
         CONV_STD_LOGIC_VECTOR(16#0B#, tst_fms'length) when i_fsm_cs = S_ERASE_STATUS_REG_CHK else
         CONV_STD_LOGIC_VECTOR(16#0C#, tst_fms'length) when i_fsm_cs = S_ERASE_WAIT           else
         CONV_STD_LOGIC_VECTOR(16#0D#, tst_fms'length) when i_fsm_cs = S_WR_SETUP             else
         CONV_STD_LOGIC_VECTOR(16#0E#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_G      else
         CONV_STD_LOGIC_VECTOR(16#0F#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_CHK    else
         CONV_STD_LOGIC_VECTOR(16#10#, tst_fms'length) when i_fsm_cs = S_WR_DCOUNT            else
         CONV_STD_LOGIC_VECTOR(16#11#, tst_fms'length) when i_fsm_cs = S_WR_DATA0             else
         CONV_STD_LOGIC_VECTOR(16#12#, tst_fms'length) when i_fsm_cs = S_WR_DATAN             else
         CONV_STD_LOGIC_VECTOR(16#13#, tst_fms'length) when i_fsm_cs = S_WR_CONFIRM           else
         CONV_STD_LOGIC_VECTOR(16#14#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_G2     else
         CONV_STD_LOGIC_VECTOR(16#15#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_CHK2   else
         CONV_STD_LOGIC_VECTOR(16#16#, tst_fms'length) when i_fsm_cs = S_WR_WAIT              else
         CONV_STD_LOGIC_VECTOR(16#17#, tst_fms'length) when i_fsm_cs = S_RD_SETUP             else
         CONV_STD_LOGIC_VECTOR(16#18#, tst_fms'length) when i_fsm_cs = S_RD_START             else
         CONV_STD_LOGIC_VECTOR(16#19#, tst_fms'length) when i_fsm_cs = S_RD_N                 else
         CONV_STD_LOGIC_VECTOR(16#1A#, tst_fms'length) when i_fsm_cs = S_RD_WAIT              else
         CONV_STD_LOGIC_VECTOR(16#1B#, tst_fms'length) when i_fsm_cs = S_CFI_SETUP            else
         CONV_STD_LOGIC_VECTOR(16#1C#, tst_fms'length) when i_fsm_cs = S_CFI_RD_START         else
         CONV_STD_LOGIC_VECTOR(16#1D#, tst_fms'length) when i_fsm_cs = S_CFI_RD_N             else
         CONV_STD_LOGIC_VECTOR(16#1E#, tst_fms'length) when i_fsm_cs = S_CFI_RD_WAIT          else
         CONV_STD_LOGIC_VECTOR(16#1F#, tst_fms'length) when i_fsm_cs = S_CMD_DONE             else
         CONV_STD_LOGIC_VECTOR(16#00#, tst_fms'length);


--//----------------------------------
--//
--//----------------------------------
p_out_irq <= i_irq;
p_out_status <= i_err;

p_out_txbuf_rd <= (not i_flash_we_n and not p_in_txbuf_empty and
                  (AND_reduce(i_bcnt) or i_txbuf_rd_last) and p_in_clk_en)
                  when i_fsm_cs = S_WR_DATA0 or i_fsm_cs = S_WR_DATAN else (i_txbuf_rd and p_in_clk_en);

i_txbuf_rd_last <= '1' when (i_size_cnt = i_size - 1) and (i_fsm_cs = S_WR_DATA0 or i_fsm_cs = S_WR_DATAN) else '0';

p_out_rxbuf_d  <= i_rxbuf_di;
p_out_rxbuf_wr <= i_rxbuf_wr_out;
process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    i_rxbuf_wr_out <= i_rxbuf_wr;
  end if;
end process;
i_rxbuf_wr <= not i_flash_oe_n and (not p_in_rxbuf_full) and
                  (AND_reduce(i_cfi_bcnt) or AND_reduce(i_bcnt) or i_rxbuf_wr_last) and p_in_clk_en
                  when i_fsm_cs = S_RD_N or i_fsm_cs = S_CFI_RD_N else '0';

i_rxbuf_wr_last <= '1' when ((i_size_cnt = i_size - 1) and i_fsm_cs = S_RD_N) or
                            ((i_size_cnt = i_size_byte - 1) and i_fsm_cs = S_CFI_RD_N) else '0';

--i_flash_wait <= p_in_phy_wait;
i_flash_di <= p_in_phy_d;
p_out_phy_d <= i_flash_do;
p_out_phy_a <= i_flash_a;
p_out_phy_oe <= i_flash_oe_n;
p_out_phy_we <= i_flash_we_n;
p_out_phy_cs <= i_flash_ce_n;


i_adr_end <= i_adr + i_size_tmp;
i_size_tmp <= i_size - 1;

i_size <= ('0' & i_size_byte(23 downto 1)) + i_size_byte(0);
i_adr <= ('0' & i_adr_byte(23 downto 1));

--номер последнего блока
i_block_end <= EXT(i_adr_end(23 downto 16), i_block_end'length)
               when (G_FLASH_OPT(0) = '0' and i_adr_end < CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK0_BOUNDARY, i_adr_end'length)) or
                    (G_FLASH_OPT(0) = '1' and i_adr_end >= CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK0_BOUNDARY, i_adr_end'length)) else
               i_adr_end(23) & EXT(i_adr_end(15 downto 14), i_block_num'length - 1);

--номер текущего блока
i_block_num <= EXT(i_adr_cnt(23 downto 16), i_block_num'length)
               when (G_FLASH_OPT(0) = '0' and i_adr_cnt < CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK0_BOUNDARY, i_adr_cnt'length)) or
                    (G_FLASH_OPT(0) = '1' and i_adr_cnt >= CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK0_BOUNDARY, i_adr_cnt'length)) else
               i_adr_cnt(23) & EXT(i_adr_cnt(15 downto 14), i_block_num'length - 1);

--адрес блока
i_block_adr <= i_adr_cnt(23 downto 16) & CONV_STD_LOGIC_VECTOR(0, 16)
               when (G_FLASH_OPT(0) = '0' and i_adr_cnt < CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK0_BOUNDARY, i_adr_cnt'length)) or
                    (G_FLASH_OPT(0) = '1' and i_adr_cnt >= CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK0_BOUNDARY, i_adr_cnt'length)) else
               i_adr_cnt(23 downto 14) & CONV_STD_LOGIC_VECTOR(0, 14);

process(p_in_rst, p_in_clk)
begin
  if p_in_rst='1' then

    i_fsm_cs <= S_IDLE;
    i_fsm_return <= (others=>'0');

    i_adr_cnt <= (others=>'0');
    i_adr_byte <= (others=>'0');

    i_size_cnt <= (others=>'0');
    i_size_byte <= (others=>'0');
    i_size_remain <= (others=>'0');
    i_trn_size <= (others=>'0');

    i_bcnt <= (others=>'0');
    i_cfi_bcnt <= (others=>'0');

    i_flash_we_n <= '1';
    i_flash_ce_n <= '1';
    i_flash_oe_n <= CI_PHY_DIR_TX;
    i_flash_do <= (others=>'0');
    i_flash_a <= (others=>'0');

    i_txbuf_rd <= '0';
    i_rxbuf_di <= (others=>'0');

    i_irq <= '0';
    i_err <= (others=>'0'); tst_done <= '0';

  elsif rising_edge(p_in_clk) then
  if p_in_clk_en = '1' then
    case i_fsm_cs is

        ---------------------------------------------
        --WAIT USR CMD
        ---------------------------------------------
        when S_IDLE =>

          i_flash_ce_n <= '1';
          i_flash_we_n <= '1';
          i_flash_oe_n <= CI_PHY_DIR_TX;

          if p_in_txbuf_empty ='0' then

              i_txbuf_rd <= '1';
              i_irq <= '0';
              i_size_cnt <= (others=>'0');
              i_err <= (others=>'0');

              if p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ADR, 4) then
                i_adr_byte <= p_in_txbuf_d(23 + 4 downto 0 + 4);
                i_fsm_cs <= S_CMD_DONE;

              elsif p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DWR, 4) then
                i_size_byte <= p_in_txbuf_d(23 + 4 downto 0 + 4);
                i_adr_cnt <= i_adr;
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_WR_SETUP;

              elsif p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DRD, 4) then
                i_size_byte <= p_in_txbuf_d(23 + 4 downto 0 + 4);
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_RD_SETUP;

              elsif p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DRD_CFI, 4) then
                i_size_byte <= p_in_txbuf_d(23 + 4 downto 0 + 4);
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_CFI_SETUP;
--
--              elsif p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_UNLOCK, 4) then
--                i_size_byte <= p_in_txbuf_d(23 + 4 downto 0 + 4);
--                i_adr_cnt <= i_adr;
--                i_flash_ce_n <= '0';
--                i_fsm_cs <= S_UNLOCK_SETUP;
--
              elsif p_in_txbuf_d(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ERASE, 4) then
                i_size_byte <= p_in_txbuf_d(23 + 4 downto 0 + 4);
                i_adr_cnt <= i_adr;
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_UNLOCK_SETUP;

              end if;
          end if;

        ---------------------------------------------
        --BLOCK UNLOCK/LOCK/LOCKDOWN
        ---------------------------------------------
        when S_UNLOCK_SETUP =>

            i_txbuf_rd <= '0';

            i_flash_a <= i_block_adr;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#60#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_UNLOCK_CONFIRM;
            else
              i_flash_we_n <= '0';
            end if;

        when S_UNLOCK_CONFIRM =>

            i_flash_a <= i_block_adr;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#D0#, i_flash_do'length);--block unlock
            --i_flash_do <= CONV_STD_LOGIC_VECTOR(16#01#, i_flash_do'length);--block lock
            --i_flash_do <= CONV_STD_LOGIC_VECTOR(16#2F#, i_flash_do'length);--block lockdown

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_UNLOCK_DEV_ID_S;
            else
              i_flash_we_n <= '0';
            end if;

        when S_UNLOCK_DEV_ID_S =>
        --Read Device Identifier register (Cycles=2/1)

            i_flash_a <= i_block_adr + 2;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#90#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_UNLOCK_DEV_ID_G;
            else
              i_flash_we_n <= '0';
            end if;

        when S_UNLOCK_DEV_ID_G =>
        --Read Device Identifier register (Cycles=2/2)
            i_flash_a <= i_block_adr + 2;

            if i_flash_we_n = '1' then
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_UNLOCK_DEV_ID_CHK;
            end if;

        when S_UNLOCK_DEV_ID_CHK =>

            --if i_flash_wait = '1' then
            i_flash_oe_n <= CI_PHY_DIR_TX;

            if i_flash_di(0) = '0' then
            --BLOCK - UNLOCKED
              i_flash_oe_n <= CI_PHY_DIR_TX;

              if i_block_num = i_block_end then
                i_adr_cnt <= i_adr;
                i_fsm_cs <= S_ERASE_STATUS_REG_CLR; --S_CMD_DONE;
              else
                --для Top Boot
                if i_adr_cnt < CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK0_BOUNDARY, i_adr_cnt'length) then
                  i_adr_cnt <= i_adr_cnt + CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK0_INC, i_adr_cnt'length);
                else
                  i_adr_cnt <= i_adr_cnt + CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK1_INC, i_adr_cnt'length);
                end if;

                i_fsm_cs <= S_UNLOCK_SETUP;
              end if;

            else
            --BLOCK - LOCKED
              i_err <= EXT(i_flash_di(6 downto 0), i_err'length);
              i_fsm_cs <= S_CMD_DONE;
            end if;
            --end if;

        ---------------------------------------------
        --BLOCK ERASE
        ---------------------------------------------
        when S_ERASE_STATUS_REG_CLR =>

            i_txbuf_rd <= '0';

            i_flash_a <= i_block_adr;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#50#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_ERASE_SETUP;
            else
              i_flash_we_n <= '0';
            end if;

        when S_ERASE_SETUP =>

            i_flash_a <= i_block_adr;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#20#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_ERASE_CONFIRM;
            else
              i_flash_we_n <= '0';
            end if;

        when S_ERASE_CONFIRM =>

            i_flash_a <= i_block_adr;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#D0#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_ERASE_STATUS_REG_G;
            else
              i_flash_we_n <= '0';
            end if;

        when S_ERASE_STATUS_REG_G =>

            i_flash_a <= i_block_adr;

            if i_flash_we_n = '1' then
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_ERASE_STATUS_REG_CHK;
            end if;

        when S_ERASE_STATUS_REG_CHK =>

            --if i_flash_wait = '1' then
            i_flash_oe_n <= CI_PHY_DIR_TX;

            if i_flash_di(7) = '1' then --Device is ready
                --BLOCK ERASE - OK
                if i_flash_di(7 downto 0) = CONV_STD_LOGIC_VECTOR(16#80#, 8) then
                    if i_block_num = i_block_end then
                      i_adr_cnt <= i_adr;
                      i_fsm_cs <= S_CMD_DONE;
                      i_irq <= '1';
                    else
                      if i_adr_cnt < CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK0_BOUNDARY, i_adr_cnt'length) then
                        i_adr_cnt <= i_adr_cnt + CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK0_INC, i_adr_cnt'length);
                      else
                        i_adr_cnt <= i_adr_cnt + CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK1_INC, i_adr_cnt'length);
                      end if;

                      i_fsm_cs <= S_ERASE_STATUS_REG_CLR;
                    end if; --tst_done <= '1';
                else
                --BLOCK ERASE - ERROR
                  i_err <= EXT(i_flash_di(6 downto 0), i_err'length);
                  i_fsm_cs <= S_CMD_DONE; --tst_done <= '1';
                  i_irq <= '1';
                end if;
            else
              i_fsm_cs <= S_ERASE_WAIT;
            end if;
            --end if;

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

            i_txbuf_rd <= '0'; tst_done <= '0';

            i_flash_a <= i_block_adr;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#E8#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_WR_STATUS_REG_G;
            else
              i_flash_we_n <= '0';
            end if;

        when S_WR_STATUS_REG_G =>
            --Вычисляем сколько данных осталось передать
            i_size_remain <= EXT(i_size, i_size_remain'length) - EXT(i_size_cnt, i_size_remain'length);

            i_flash_a <= i_block_adr;

            if i_flash_we_n = '1' then
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_WR_STATUS_REG_CHK;
            end if;

        when S_WR_STATUS_REG_CHK =>
            --Формируем размер одиночной транзакции (--0 is corresponds to count = 1)
            if i_size_remain >= CONV_STD_LOGIC_VECTOR(G_FLASH_BUF_SIZE_MAX, i_size_remain'length) then
              i_trn_size <= CONV_STD_LOGIC_VECTOR(G_FLASH_BUF_SIZE_MAX - 1, i_trn_size'length);
            else
              i_trn_size <= i_size_remain - 1;
            end if;

            --if i_flash_wait = '1' then
            i_flash_oe_n <= CI_PHY_DIR_TX;

            if i_flash_di(7) = '1' then --Device is ready
              i_fsm_cs <= S_WR_DCOUNT;
            else
              i_fsm_return(0) <= '1';
              i_fsm_cs <= S_WR_WAIT;
            end if;
            --end if;

        when S_WR_DCOUNT =>

            i_flash_a <= i_block_adr;
            i_flash_do <= i_trn_size(i_flash_do'range);--Назначаю кол-во отправляемых данных

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_WR_DATA0;
            else
              i_flash_we_n <= '0';
            end if;

        when S_WR_DATA0 =>

            if p_in_txbuf_empty = '0' then

                i_flash_a <= i_adr_cnt;
                for i in 0 to i_flash_do'length/8 - 1 loop
                  if i_bcnt = i then
                    i_flash_do <= p_in_txbuf_d(i_flash_do'length*(i+1)-1 downto i_flash_do'length*i);
                  end if;
                end loop;

                if i_flash_we_n = '0' then
                    i_flash_we_n <= '1';
                    i_adr_cnt <= i_adr_cnt + 1;
                    i_bcnt <= i_bcnt + 1;
                    --считаем общее кол-во переданых данных
                    i_size_cnt <= i_size_cnt + 1;
                    --Следим за завершением одиночной транзакции
                    if i_trn_size = (i_size'range => '0') then
                      i_fsm_cs <= S_WR_CONFIRM;
                    else
                      i_trn_size <= i_trn_size - 1;
                      i_fsm_cs <= S_WR_DATAN;
                    end if;
                else
                  i_flash_we_n <= '0';
                end if;
            end if;

        when S_WR_DATAN =>

            if p_in_txbuf_empty = '0' then

                i_flash_a <= i_adr_cnt;
                for i in 0 to i_flash_do'length/8 - 1 loop
                  if i_bcnt = i then
                    i_flash_do <= p_in_txbuf_d(i_flash_do'length*(i+1)-1 downto i_flash_do'length*i);
                  end if;
                end loop;

                if i_flash_we_n = '0' then
                    i_flash_we_n <= '1';
                    i_adr_cnt <= i_adr_cnt + 1;
                    i_bcnt <= i_bcnt + 1;
                    --считаем общее кол-во переданых данных
                    i_size_cnt <= i_size_cnt + 1;
                    --Следим за завершением одиночной транзакции
                    if i_trn_size = (i_trn_size'range => '0') then
                      i_fsm_cs <= S_WR_CONFIRM;
                    else
                      i_trn_size <= i_trn_size - 1;
                    end if;

                else
                  i_flash_we_n <= '0';
                end if;
            end if;

        when S_WR_CONFIRM =>

            i_flash_a <= i_block_adr;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#D0#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_WR_STATUS_REG_G2;
            else
              i_flash_we_n <= '0';
            end if;

        when S_WR_STATUS_REG_G2 =>

            i_flash_a <= i_block_adr;

            if i_flash_we_n = '1' then
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_WR_STATUS_REG_CHK2;
            end if;

        when S_WR_STATUS_REG_CHK2 =>

            --if i_flash_wait = '1' then
            i_flash_oe_n <= CI_PHY_DIR_TX;

            if i_flash_di(7) = '1' then --Device is ready
                --BLOCK WRITE - OK
                if i_flash_di(7 downto 0) = CONV_STD_LOGIC_VECTOR(16#80#, 8) then
                    if i_size_cnt = i_size then
                    --Записал все данные
                      i_fsm_cs <= S_CMD_DONE;
                    else
                      i_fsm_cs <= S_WR_SETUP;
                    end if; tst_done <= '1';
                else
                --BLOCK WRITE - ERROR
                  i_err <= EXT(i_flash_di(6 downto 0), i_err'length);
                  i_fsm_cs <= S_CMD_DONE; tst_done <= '1';
                end if;
            else
              i_fsm_cs <= S_WR_WAIT;
            end if;

        when S_WR_WAIT =>

            if i_flash_oe_n = CI_PHY_DIR_TX then
            --OE# to update Status Register
              i_flash_a <= i_block_adr;
              i_flash_oe_n <= CI_PHY_DIR_RX;

              if i_fsm_return(0) = '1' then
              i_fsm_cs <= S_WR_STATUS_REG_CHK;
              else
              i_fsm_cs <= S_WR_STATUS_REG_CHK2;
              end if;

              i_fsm_return <= (others=>'0');

            end if;

        ---------------------------------------------
        --READ DATA
        ---------------------------------------------
        when S_RD_SETUP =>

            i_txbuf_rd <= '0';

            i_flash_a <= i_block_adr;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#FF#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_RD_START;
            else
              i_flash_we_n <= '0';
            end if;

        when S_RD_START =>

            i_flash_a <= i_block_adr;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#FF#, i_flash_do'length);

            if i_flash_we_n = '1' then
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_RD_N;
            end if;

        when S_RD_N =>

            --if i_flash_wait = '1' then
            if p_in_rxbuf_full = '0' then
                for i in 0 to i_rxbuf_di'length/8 - 1 loop
                  if i_bcnt = i then
                    i_rxbuf_di(i_flash_di'length*(i+1)-1 downto i_flash_di'length*i) <= i_flash_di;
                  end if;
                end loop;

                if i_size_cnt = i_size - 1 then
                  i_flash_oe_n <= CI_PHY_DIR_TX;
                  i_fsm_cs <= S_CMD_DONE;
                else
                  i_flash_a <= i_flash_a + 1;
                  i_size_cnt <= i_size_cnt + 1;
                  i_flash_oe_n <= CI_PHY_DIR_TX;
                  i_fsm_cs <= S_CFI_RD_WAIT;
                end if;
                i_irq <= '1';
                i_bcnt <= i_bcnt + 1;

            end if;
            --end if;

        when S_RD_WAIT =>

            if i_flash_oe_n = CI_PHY_DIR_TX then
              if p_in_rxbuf_full = '0' then
                i_flash_oe_n <= CI_PHY_DIR_RX;
                i_fsm_cs <= S_RD_N;
              end if;
            end if;

        ---------------------------------------------
        --CFI Read
        ---------------------------------------------
        when S_CFI_SETUP =>

            i_txbuf_rd <= '0';

            i_flash_a <= CONV_STD_LOGIC_VECTOR(16#55#, i_flash_a'length);
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#98#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_CFI_RD_START;
            else
              i_flash_we_n <= '0';
              i_flash_oe_n <= CI_PHY_DIR_TX;
            end if;

        when S_CFI_RD_START =>

            i_flash_a <= i_adr_byte;
            if i_flash_we_n = '1' then
              i_cfi_bcnt <= (others=>'0');
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_CFI_RD_N;
            end if;

        when S_CFI_RD_N =>

            --if i_flash_wait = '1' then
            if p_in_rxbuf_full = '0' then
                for i in 0 to i_rxbuf_di'length/8 - 1 loop
                  if i_cfi_bcnt = i then
                    i_rxbuf_di(8*(i+1)-1 downto 8*i) <= i_flash_di(7 downto 0);
                  end if;
                end loop;

                if i_size_cnt = i_size_byte - 1 then
                  i_flash_oe_n <= CI_PHY_DIR_TX;
                  i_fsm_cs <= S_CMD_DONE;
                else
                  i_flash_a <= i_flash_a + 1;
                  i_size_cnt <= i_size_cnt + 1;
                  i_flash_oe_n <= CI_PHY_DIR_TX;
                  i_fsm_cs <= S_CFI_RD_WAIT;
                end if;
                i_irq <= '1';
                i_cfi_bcnt <= i_cfi_bcnt + 1;

            end if;
            --end if;

        when S_CFI_RD_WAIT =>

            if i_flash_oe_n = CI_PHY_DIR_TX then
              if p_in_rxbuf_full = '0' then
                i_flash_oe_n <= CI_PHY_DIR_RX;
                i_fsm_cs <= S_CFI_RD_N;
              end if;
            end if;

        ---------------------------------------------
        --Команда завершена
        ---------------------------------------------
        when S_CMD_DONE =>

          i_flash_ce_n <= '1';
          i_bcnt <= (others=>'0'); tst_done <= '0';
          i_cfi_bcnt <= (others=>'0');

          if OR_reduce(i_err) = '0' then
            i_txbuf_rd <= '0';
            i_fsm_cs <= S_IDLE;
          else
              --При обнаружении ощибки нужно чистим TxBUF от данных
              i_txbuf_rd <= '1';
              if (i_size_cnt = i_size - 1) then
                i_fsm_cs <= S_CMD_ERR;
              else
                i_size_cnt <= i_size_cnt + 1;
              end if;
          end if;

        when S_CMD_ERR =>

          if p_in_txbuf_empty = '1' then
          i_txbuf_rd <= '0';
          i_fsm_cs <= S_IDLE;
          end if;

    end case;
  end if;--if p_in_clk_en = '1' then
  end if;
end process;


--END MAIN
end behavioral;
