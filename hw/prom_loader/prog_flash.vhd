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
--Запись данных :
--  Очистка данных :
--   PC -> FPGA : DATA0[31:4]=стартовый адрес(byte) + DATA0[3:0]=USR_CMD_ADR
--   PC -> FPGA : DATA0[31:4]=Кол-во данных(byte) + DATA0[3:0]=USR_CMD_ERASE
--   PC <- FPGA : IRQ(команда завершена)
--  PC -> FPGA : DATA0[31:4]=Кол-во данных(byte) + DATA0[3:0]=USR_CMD_DWR
--  PC -> FPGA : DATAN[] - данные
--Чтение данных :
--  PC -> FPGA : DATA0[31:4]=стартовый адрес(byte) + DATA0[3:0]=USR_CMD_ADR
--  PC -> FPGA : DATA0[31:4]=Кол-во данных(byte) + DATA0[3:0]=USR_CMD_DRD
--  PC <- FPGA : IRQ (начата запись в usr rxbuf)
--  PC <- FPGA : DATA[] - данные
--Чтение параметров FLASH :
--  PC -> FPGA : DATA0[31:4]=стартовый адрес(byte) + DATA0[3:0]=USR_CMD_ADR
--  PC -> FPGA : DATA0[31:4]=Кол-во данных(byte) + DATA0[3:0]=USR_CMD_DRD_CFI
--  PC <- FPGA : IRQ (начата запись в usr rxbuf)
--  PC <- FPGA : DATA[] - данные
--Set FLASH BUFSIZE:
--  PC -> FPGA : DATA0[31:4]=flash_bufsize(byte) + DATA0[3:0]=CMD_FLASH_BUF
--ERROR Detect:
--  PC <- FPGA : IRQ(команда завершена)
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
G_DBG : string:="OFF";
G_USRBUF_DWIDTH : integer := 32;--valid 32,64,128,256
G_FLASH_AWIDTH : integer := 24;
G_FLASH_DWIDTH : integer := 16;
G_FLASH_BUFSIZE_DEFAULT : integer := 32;--Byte
G_FLASH_OPT : std_logic_vector(7 downto 0) := (others=>'0') --G_FLASH_OPT(7..0) - flash type
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
constant CI_USR_CMD_ERASE   : integer:=5;
constant CI_USR_CMD_FLASH_BUF : integer:=6;

constant CI_PHY_DIR_TX      : std_logic:='0';--'1';
constant CI_PHY_DIR_RX      : std_logic:='1';--'0';

constant CI_FLASH_BLOCK_16KW : integer:=(1024 * 16);
constant CI_FLASH_BLOCK_64KW : integer:=(1024 * 64);
constant CI_FLASH_BLOCK_128KW : integer:=(1024 * 128);

type TFsm_state is (
S_IDLE                ,

S_UNLOCK_SETUP        ,
S_UNLOCK_CONFIRM      ,
S_UNLOCK_DEV_ID_SET   ,
S_UNLOCK_DEV_ID_GET   ,
S_UNLOCK_DEV_ID_CHK   ,

S_ERASE_SETUP         ,
S_ERASE_CONFIRM       ,
S_ERASE_STATUS_REG_GET,
S_ERASE_STATUS_REG_CHK,
S_ERASE_WAIT          ,

S_WR_SETUP            ,
S_WR_SETUP1           ,
S_WR_STATUS_REG_GET   ,
S_WR_STATUS_REG_CHK   ,
S_WR_DCOUNT           ,
S_WR_DATA0            ,
S_WR_DATAN            ,
S_WR_CONFIRM          ,
S_WR_STATUS_REG_GET2  ,
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

S_CMD_DONE            ,
S_CMD_ERR             ,
S_ERR_STATUS_REG_CLR
);
signal i_fsm_cs           : TFsm_state;
signal i_fsm_return       : std_logic_vector(0 downto 0);

--signal i_flash_wait       : std_logic;
signal i_flash_we_n       : std_logic:='1';
signal i_flash_ce_n       : std_logic:='1';
signal i_flash_oe_n       : std_logic;
signal i_flash_do         : std_logic_vector(p_out_phy_d'range);
signal i_flash_di         : std_logic_vector(p_in_phy_d'range);
signal i_flash_a          : std_logic_vector(p_out_phy_a'range);
signal i_fash_buf_byte    : std_logic_vector(15 downto 0);
signal i_fash_buf_size    : std_logic_vector(15 downto 0);
signal i_cfi_bcnt         : std_logic_vector(log2(G_USRBUF_DWIDTH / 8) - 1 downto 0);
signal i_bcnt             : std_logic_vector(log2(G_USRBUF_DWIDTH / G_FLASH_DWIDTH) - 1 downto 0);
signal i_adr_byte         : std_logic_vector(31 - 4 downto 0);
signal i_adr              : std_logic_vector(i_adr_byte'range);
signal i_adr_wr_start     : std_logic_vector(i_adr_byte'range);
signal i_adr_cnt          : std_logic_vector(i_adr_byte'range);
signal i_adr_end          : std_logic_vector(i_adr_byte'range);
signal i_adr_end_inc      : std_logic_vector(2 downto 0);
signal i_size_byte        : std_logic_vector(31 - 4 downto 0);
signal i_size             : std_logic_vector(i_size_byte'range);
signal i_size_cnt         : std_logic_vector(i_size_byte'range);
signal i_size_remain      : std_logic_vector(i_size_byte'range);
signal i_trn_size         : std_logic_vector(i_size_byte'range);
signal i_block_adr        : std_logic_vector(i_adr_byte'range);--адрес блока
signal i_block_num        : std_logic_vector(9 downto 0);--номер текущего блока
signal i_block_end        : std_logic_vector(9 downto 0);--номер последнего блока
signal i_block0_inc       : std_logic_vector(i_adr_byte'range);
signal i_block1_inc       : std_logic_vector(i_adr_byte'range);
signal i_block0_boundary  : std_logic_vector(i_adr_byte'range);

signal i_txbuf_do_max     : std_logic_vector(255 downto 0);
signal i_rxbuf_di         : std_logic_vector(p_out_rxbuf_d'range);
signal i_txbuf_rd         : std_logic;
signal i_rxbuf_wr         : std_logic;

signal i_irq              : std_logic;
signal i_err              : std_logic_vector(7 downto 0);
signal i_cmd_nxt          : std_logic;

signal tst_fms_out,tst_fms: std_logic_vector(4 downto 0);
signal tst_txbuf_rd       : std_logic;
signal tst_txbuf_empty    : std_logic;
signal tst_err            : std_logic;
signal tst_irq            : std_logic;
signal tst_timeout_cnt    : std_logic_vector(15 downto 0);
signal tst_timeout        : std_logic;

--MAIN
begin


------------------------------------
--Технологические сигналы
------------------------------------
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    tst_txbuf_rd <= '0';
    tst_fms_out <= (others=>'0');
    tst_err <= '0';
    p_out_tst <= (others=>'0');
    tst_timeout_cnt <= (others=>'0');
    tst_timeout <= '0';

  else
    tst_fms_out <= tst_fms;
    tst_txbuf_empty <= p_in_txbuf_empty;
    tst_txbuf_rd <= i_txbuf_rd and p_in_clk_en;
    tst_err <= OR_reduce(i_err);
    p_out_tst(0) <= OR_reduce(tst_fms_out) or tst_txbuf_rd or tst_txbuf_empty or tst_err or tst_irq or tst_timeout;


    if p_in_clk_en = '1' then
      if i_fsm_cs = S_WR_DATAN then
        if i_flash_we_n = '0' then
          tst_timeout_cnt <= (others=>'0');
          tst_timeout <= '0';
        else
          if tst_timeout_cnt = CONV_STD_LOGIC_VECTOR(16, tst_timeout_cnt'length) then
            tst_timeout <= '1';
          else
            tst_timeout_cnt <= tst_timeout_cnt + 1;
          end if;
        end if;
      else
        tst_timeout_cnt <= (others=>'0');
        tst_timeout <= '0';
      end if;
    end if;

  end if;
end if;
end process;

tst_fms<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms'length) when i_fsm_cs = S_UNLOCK_SETUP         else
         CONV_STD_LOGIC_VECTOR(16#02#, tst_fms'length) when i_fsm_cs = S_UNLOCK_CONFIRM       else
         CONV_STD_LOGIC_VECTOR(16#03#, tst_fms'length) when i_fsm_cs = S_UNLOCK_DEV_ID_SET    else
         CONV_STD_LOGIC_VECTOR(16#04#, tst_fms'length) when i_fsm_cs = S_UNLOCK_DEV_ID_GET    else
         CONV_STD_LOGIC_VECTOR(16#05#, tst_fms'length) when i_fsm_cs = S_UNLOCK_DEV_ID_CHK    else
         CONV_STD_LOGIC_VECTOR(16#06#, tst_fms'length) when i_fsm_cs = S_CMD_ERR              else
         CONV_STD_LOGIC_VECTOR(16#07#, tst_fms'length) when i_fsm_cs = S_ERR_STATUS_REG_CLR   else
         CONV_STD_LOGIC_VECTOR(16#08#, tst_fms'length) when i_fsm_cs = S_ERASE_SETUP          else
         CONV_STD_LOGIC_VECTOR(16#09#, tst_fms'length) when i_fsm_cs = S_ERASE_CONFIRM        else
         CONV_STD_LOGIC_VECTOR(16#0A#, tst_fms'length) when i_fsm_cs = S_ERASE_STATUS_REG_GET else
         CONV_STD_LOGIC_VECTOR(16#0B#, tst_fms'length) when i_fsm_cs = S_ERASE_STATUS_REG_CHK else
         CONV_STD_LOGIC_VECTOR(16#0C#, tst_fms'length) when i_fsm_cs = S_ERASE_WAIT           else
         CONV_STD_LOGIC_VECTOR(16#0D#, tst_fms'length) when i_fsm_cs = S_WR_SETUP             else
         CONV_STD_LOGIC_VECTOR(16#0E#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_GET    else
         CONV_STD_LOGIC_VECTOR(16#0F#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_CHK    else
         CONV_STD_LOGIC_VECTOR(16#10#, tst_fms'length) when i_fsm_cs = S_WR_DCOUNT            else
         CONV_STD_LOGIC_VECTOR(16#11#, tst_fms'length) when i_fsm_cs = S_WR_DATA0             else
         CONV_STD_LOGIC_VECTOR(16#12#, tst_fms'length) when i_fsm_cs = S_WR_DATAN             else
         CONV_STD_LOGIC_VECTOR(16#13#, tst_fms'length) when i_fsm_cs = S_WR_CONFIRM           else
         CONV_STD_LOGIC_VECTOR(16#14#, tst_fms'length) when i_fsm_cs = S_WR_STATUS_REG_GET2   else
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


------------------------------------
--
------------------------------------
gen_dbg_on : if strcmp(G_DBG,"ON") generate
p_out_irq <= i_irq or tst_irq;
end generate gen_dbg_on;
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_irq <= i_irq;
end generate gen_dbg_off;

p_out_status <= i_err;

i_txbuf_do_max <= EXT(p_in_txbuf_d, i_txbuf_do_max'length);
p_out_txbuf_rd <= i_txbuf_rd and p_in_clk_en;

p_out_rxbuf_d  <= i_rxbuf_di;
p_out_rxbuf_wr <= i_rxbuf_wr and p_in_clk_en;


--i_flash_wait <= p_in_phy_wait;
i_flash_di <= p_in_phy_d;
p_out_phy_d <= i_flash_do;
p_out_phy_a <= i_flash_a;
p_out_phy_cs <= i_flash_ce_n;
p_out_phy_oe <= i_flash_oe_n;
p_out_phy_we <= i_flash_we_n;


i_adr_end <= i_adr + EXT(i_size, i_adr_end'length);


---------------------------------------------
--FLASH DBUS
---------------------------------------------
gen_dbus0 : if G_FLASH_DWIDTH = 8 generate
i_fash_buf_size <= EXT(i_fash_buf_byte(15 downto 0), i_fash_buf_size'length);
i_size <= EXT(i_size_byte(i_size_byte'high downto 0), i_size'length);
i_adr <= EXT(i_adr_byte(i_adr_byte'high downto 0), i_adr'length);
end generate;--gen_dbus0

gen_dbus1 : if G_FLASH_DWIDTH > 8 generate
i_fash_buf_size <= EXT(i_fash_buf_byte(i_fash_buf_byte'high downto log2(G_FLASH_DWIDTH/8)), i_fash_buf_size'length);
i_size <= EXT(i_size_byte(i_size_byte'high downto log2(G_FLASH_DWIDTH/8)), i_size'length)
          + OR_reduce(i_size_byte(log2(G_FLASH_DWIDTH/8) - 1 downto 0));
i_adr <= EXT(i_adr_byte(i_adr_byte'high downto log2(G_FLASH_DWIDTH/8)), i_adr'length);
end generate;--gen_dbus1


---------------------------------------------
--FLASH TYPE
---------------------------------------------
gen_type0 : if G_FLASH_OPT = CONV_STD_LOGIC_VECTOR(0, G_FLASH_OPT'length) generate

i_block0_inc <= CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_64KW, i_block0_inc'length);
i_block1_inc <= CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_16KW, i_block1_inc'length);

i_block0_boundary <= CONV_STD_LOGIC_VECTOR((CI_FLASH_BLOCK_64KW * 255), i_block0_boundary'length);

i_block_num <= EXT(i_adr_cnt(24 downto 16), i_block_num'length)
            when i_adr_cnt < CONV_STD_LOGIC_VECTOR((CI_FLASH_BLOCK_64KW * 255), i_adr_cnt'length)
            else EXT(i_adr_cnt(24 downto 16), i_block_num'length) + EXT(i_adr_cnt(15 downto 14), i_block_num'length)
              when i_adr_cnt >= CONV_STD_LOGIC_VECTOR((CI_FLASH_BLOCK_64KW * 255), i_adr_cnt'length)
                and i_adr_cnt < CONV_STD_LOGIC_VECTOR((CI_FLASH_BLOCK_64KW * 256), i_adr_cnt'length)
              else CONV_STD_LOGIC_VECTOR(259, i_block_num'length);

i_block_end <= EXT(i_adr_end(24 downto 16), i_block_end'length)
            when i_adr_end < CONV_STD_LOGIC_VECTOR((CI_FLASH_BLOCK_64KW * 255), i_adr_end'length)
            else EXT(i_adr_end(24 downto 16), i_block_end'length) + EXT(i_adr_end(15 downto 14), i_block_end'length)
              when i_adr_end >= CONV_STD_LOGIC_VECTOR((CI_FLASH_BLOCK_64KW * 255), i_adr_end'length)
                and i_adr_end < CONV_STD_LOGIC_VECTOR((CI_FLASH_BLOCK_64KW * 256), i_adr_end'length)
              else CONV_STD_LOGIC_VECTOR(259, i_block_end'length);

i_block_adr <= EXT(i_adr_cnt(23 downto 14), (i_block_adr'length - 14)) & CONV_STD_LOGIC_VECTOR(0, 14);
end generate;--gen_type0

---------------------------------------------
--
---------------------------------------------
gen_type1 : if G_FLASH_OPT = CONV_STD_LOGIC_VECTOR(1, G_FLASH_OPT'length) generate

i_block0_inc <= CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_16KW, i_block0_inc'length);
i_block1_inc <= CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_64KW, i_block1_inc'length);

i_block0_boundary <= CONV_STD_LOGIC_VECTOR((CI_FLASH_BLOCK_16KW * 4), i_block0_boundary'length);

i_block_num <= EXT(i_adr_cnt(24 downto 14), i_block_num'length)
            when i_adr_cnt < CONV_STD_LOGIC_VECTOR((CI_FLASH_BLOCK_16KW * 4), i_adr_cnt'length)
            else EXT(i_adr_cnt(24 downto 14), i_block_num'length) + 3;

i_block_end <= EXT(i_adr_end(24 downto 14), i_block_end'length)
            when i_adr_end < CONV_STD_LOGIC_VECTOR((CI_FLASH_BLOCK_16KW * 4), i_adr_end'length)
            else EXT(i_adr_end(24 downto 14), i_block_end'length) + 3;

i_block_adr <= EXT(i_adr_cnt(23 downto 14), (i_block_adr'length - 14)) & CONV_STD_LOGIC_VECTOR(0, 14);
end generate;--gen_type1

---------------------------------------------
--
---------------------------------------------
gen_type2 : if G_FLASH_OPT = CONV_STD_LOGIC_VECTOR(2, G_FLASH_OPT'length) generate

i_block0_inc <= CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_128KW, i_block0_inc'length);
i_block1_inc <= CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_128KW, i_block1_inc'length);

i_block0_boundary <= CONV_STD_LOGIC_VECTOR(CI_FLASH_BLOCK_128KW, i_block0_boundary'length);

i_block_num <= EXT(i_adr_cnt(26 downto 17), i_block_num'length);

i_block_end <= EXT(i_adr_end(26 downto 17), i_block_end'length);

i_block_adr <= EXT(i_adr_cnt(26 downto 17), (i_block_adr'length - 17)) & CONV_STD_LOGIC_VECTOR(0, 17);
end generate;--gen_type2



--###########################################
--FSM
--###########################################
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    i_fsm_cs <= S_IDLE;
    i_fsm_return <= (others=>'0');

    i_adr_wr_start <= (others=>'0');
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
    i_fash_buf_byte <= CONV_STD_LOGIC_VECTOR(G_FLASH_BUFSIZE_DEFAULT, i_fash_buf_byte'length);

    i_txbuf_rd <= '0';

    i_rxbuf_wr <= '0';
    i_rxbuf_di <= (others=>'0');

    i_irq <= '0'; tst_irq <= '0';
    i_err <= (others=>'0');
    i_cmd_nxt <= '0';

  else
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
              i_irq <= '0'; tst_irq <= '0';
              i_size_cnt <= (others=>'0');
              i_err <= (others=>'0');

              if i_txbuf_do_max(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ADR, 4) then
                i_adr_byte <= i_txbuf_do_max(31 downto 0 + 4);
                i_cmd_nxt <= bool2std_logic( G_USRBUF_DWIDTH > 32 );
                i_fsm_cs <= S_CMD_DONE;

              elsif i_txbuf_do_max(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DWR, 4) then
                i_size_byte <= i_txbuf_do_max(31 downto 0 + 4);
                i_adr_cnt <= i_adr;
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_WR_SETUP;

              elsif i_txbuf_do_max(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DRD, 4) then
                i_size_byte <= i_txbuf_do_max(31 downto 0 + 4);
                i_adr_cnt <= i_adr;
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_RD_SETUP;

              elsif i_txbuf_do_max(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DRD_CFI, 4) then
                i_size_byte <= i_txbuf_do_max(31 downto 0 + 4);
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_CFI_SETUP;

              elsif i_txbuf_do_max(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_FLASH_BUF, 4) then
                i_fash_buf_byte <= i_txbuf_do_max(15 + 4 downto 0 + 4);
                i_fsm_cs <= S_CMD_DONE;

              elsif i_txbuf_do_max(3 downto 0) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ERASE, 4) then
                i_size_byte <= i_txbuf_do_max(31 downto 0 + 4);
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

            i_flash_a <= i_block_adr(i_flash_a'range);
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#60#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_UNLOCK_CONFIRM;
            else
              i_flash_we_n <= '0';
            end if;

        when S_UNLOCK_CONFIRM =>

            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#D0#, i_flash_do'length);--block unlock
            --i_flash_do <= CONV_STD_LOGIC_VECTOR(16#01#, i_flash_do'length);--block lock
            --i_flash_do <= CONV_STD_LOGIC_VECTOR(16#2F#, i_flash_do'length);--block lockdown

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_UNLOCK_DEV_ID_SET;
            else
              i_flash_we_n <= '0';
            end if;

        when S_UNLOCK_DEV_ID_SET =>

            i_flash_a <= i_block_adr(i_flash_a'range) + 2;
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#90#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_UNLOCK_DEV_ID_GET;
            else
              i_flash_we_n <= '0';
            end if;

        when S_UNLOCK_DEV_ID_GET =>

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

              if i_block_num = (i_block_end - 1) then
                i_adr_cnt <= i_adr;
                i_fsm_cs <= S_ERASE_SETUP;
              else
                if (i_adr_cnt < i_block0_boundary) then
                  i_adr_cnt <= i_adr_cnt + i_block0_inc;
                else
                  i_adr_cnt <= i_adr_cnt + i_block1_inc;
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
        when S_ERASE_SETUP =>

            i_flash_a <= i_block_adr(i_flash_a'range);
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#20#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_ERASE_CONFIRM;
            else
              i_flash_we_n <= '0';
            end if;

        when S_ERASE_CONFIRM =>

            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#D0#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_ERASE_STATUS_REG_GET;
            else
              i_flash_we_n <= '0';
            end if;

        when S_ERASE_STATUS_REG_GET =>

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
                    if i_block_num = (i_block_end - 1) then
                      i_adr_cnt <= i_adr;
                      i_fsm_cs <= S_CMD_DONE;
                      i_irq <= '1';
                    else
                      if i_adr_cnt < i_block0_boundary then
                        i_adr_cnt <= i_adr_cnt + i_block0_inc;
                      else
                        i_adr_cnt <= i_adr_cnt + i_block1_inc;
                      end if;

                      i_fsm_cs <= S_ERASE_SETUP;
                    end if;
                else
                --BLOCK ERASE - ERROR
                  i_err <= EXT(i_flash_di(6 downto 0), i_err'length);
                  i_fsm_cs <= S_CMD_DONE;
                end if;
            else
              i_fsm_cs <= S_ERASE_WAIT;
            end if;
            --end if;

        when S_ERASE_WAIT =>

            if i_flash_oe_n = CI_PHY_DIR_TX then
            --OE# to update Status Register
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_ERASE_STATUS_REG_CHK;
            end if;

        ---------------------------------------------
        --WRITE DATA
        ---------------------------------------------
        when S_WR_SETUP =>

            i_adr_wr_start <= i_adr_cnt;
            i_txbuf_rd <= '0';
            i_fsm_cs <= S_WR_SETUP1;

        when S_WR_SETUP1 =>

            if p_in_txbuf_empty = '0' then
              i_flash_a <= i_adr_wr_start(i_flash_a'range);
              i_flash_do <= CONV_STD_LOGIC_VECTOR(16#E8#, i_flash_do'length);

              if i_flash_we_n = '0' then
                i_flash_we_n <= '1';
                i_fsm_cs <= S_WR_STATUS_REG_GET;
              else
                i_flash_we_n <= '0';
              end if;
            end if;

        when S_WR_STATUS_REG_GET =>

            --Вычисляем сколько данных осталось передать
            i_size_remain <= EXT(i_size, i_size_remain'length) - EXT(i_size_cnt, i_size_remain'length);

            if i_flash_we_n = '1' then
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_WR_STATUS_REG_CHK;
            end if;

        when S_WR_STATUS_REG_CHK =>

            --Вычисляем кол-во данных для текущей транзакции
            if i_size_remain >= EXT(i_fash_buf_size, i_size_remain'length) then
              i_trn_size <= EXT(i_fash_buf_size, i_size_remain'length) - 1;
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

            --Назначаю кол-во данных для текущей транзакции (0 is corresponds to count = 1)
            i_flash_do <= i_trn_size(i_flash_do'range);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_WR_DATA0;
            else
              i_flash_we_n <= '0';
            end if;

        when S_WR_DATA0 =>

            if p_in_txbuf_empty = '0' then

                i_flash_a <= i_adr_cnt(i_flash_a'range);
                for i in 0 to (p_in_txbuf_d'length / i_flash_do'length - 1) loop
                  if i_bcnt = i then
                    i_flash_do <= i_txbuf_do_max((i_flash_do'length*(i + 1) - 1) downto i_flash_do'length*i);
                  end if;
                end loop;

                if i_flash_we_n = '0' then
                    i_txbuf_rd <= '0';

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
                    if i_trn_size = (i_size'range => '0') then
                      i_txbuf_rd <= '1';
                    else
                      i_txbuf_rd <= AND_reduce(i_bcnt);
                    end if;

                    i_flash_we_n <= '0';

                end if;
            end if;

        when S_WR_DATAN =>

            if p_in_txbuf_empty = '0' then

                i_flash_a <= i_adr_cnt(i_flash_a'range);
                for i in 0 to (p_in_txbuf_d'length / i_flash_do'length - 1) loop
                  if i_bcnt = i then
                    i_flash_do <= i_txbuf_do_max((i_flash_do'length*(i + 1) - 1) downto i_flash_do'length*i);
                  end if;
                end loop;

                if i_flash_we_n = '0' then
                    i_txbuf_rd <= '0';

                    i_flash_we_n <= '1';
                    i_bcnt <= i_bcnt + 1;
                    --считаем общее кол-во переданых данных
                    i_size_cnt <= i_size_cnt + 1;
                    --Следим за завершением одиночной транзакции
                    if i_trn_size = (i_trn_size'range => '0') then
                      i_fsm_cs <= S_WR_CONFIRM;
                    else
                      i_trn_size <= i_trn_size - 1;
                      i_adr_cnt <= i_adr_cnt + 1;
                    end if;

                else
                    if i_trn_size = (i_size'range => '0') then
                      i_txbuf_rd <= '1';
                    else
                      i_txbuf_rd <= AND_reduce(i_bcnt);
                    end if;

                    i_flash_we_n <= '0';

                end if;
            end if;

        when S_WR_CONFIRM =>

            i_flash_a <= i_adr_wr_start(i_flash_a'range);
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#D0#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_WR_STATUS_REG_GET2;
            else
              i_flash_we_n <= '0';
            end if;

        when S_WR_STATUS_REG_GET2 =>

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
                      i_fsm_cs <= S_CMD_DONE; tst_irq <= '1';
                    else
                      i_adr_cnt <= i_adr_cnt + 1;
                      i_fsm_cs <= S_WR_SETUP;
                    end if;
                else
                --BLOCK WRITE - ERROR
                  i_err <= EXT(i_flash_di(6 downto 0), i_err'length);
                  i_fsm_cs <= S_CMD_DONE;
                end if;
            else
              i_fsm_cs <= S_WR_WAIT;
            end if;

        when S_WR_WAIT =>

            if i_flash_oe_n = CI_PHY_DIR_TX then
            --OE# to update Status Register
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

            i_flash_a <= i_block_adr(i_flash_a'range);
            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#FF#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_RD_START;
            else
              i_flash_we_n <= '0';
            end if;

        when S_RD_START =>

            if i_flash_we_n = '1' then
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_RD_N;
            end if;

        when S_RD_N =>

            --if i_flash_wait = '1' then
            if p_in_rxbuf_full = '0' then
                for i in 0 to (i_rxbuf_di'length / i_flash_di'length - 1) loop
                  if i_bcnt = i then
                    i_rxbuf_di((i_flash_di'length*(i + 1) - 1) downto i_flash_di'length*i) <= i_flash_di;
                  end if;
                end loop;

                if i_size_cnt = (i_size - 1) then
                  i_rxbuf_wr <= '1';

                  i_flash_oe_n <= CI_PHY_DIR_TX;
                  i_fsm_cs <= S_CMD_DONE;

                else
                  i_rxbuf_wr <= AND_reduce(i_bcnt);

                  i_size_cnt <= i_size_cnt + 1;
                  i_flash_a <= i_flash_a + 1;
                  i_flash_oe_n <= CI_PHY_DIR_TX;
                  i_fsm_cs <= S_RD_WAIT;
                end if;

                i_bcnt <= i_bcnt + 1;
                i_irq <= '1';

            end if;
            --end if;

        when S_RD_WAIT =>

            i_rxbuf_wr <= '0';

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

            i_flash_a <= i_adr_byte(i_flash_a'range);
            if i_flash_we_n = '1' then
              i_cfi_bcnt <= (others=>'0');
              i_flash_oe_n <= CI_PHY_DIR_RX;
              i_fsm_cs <= S_CFI_RD_N;
            end if;

        when S_CFI_RD_N =>

            --if i_flash_wait = '1' then
            if p_in_rxbuf_full = '0' then
                for i in 0 to (i_rxbuf_di'length / 8 - 1) loop
                  if i_cfi_bcnt = i then
                    i_rxbuf_di((8*(i + 1) - 1) downto 8*i) <= i_flash_di(7 downto 0);
                  end if;
                end loop;

                if i_size_cnt = (i_size_byte - 1) then
                  i_rxbuf_wr <= '1';

                  i_flash_oe_n <= CI_PHY_DIR_TX;
                  i_fsm_cs <= S_CMD_DONE;

                else
                  i_rxbuf_wr <= AND_reduce(i_cfi_bcnt);

                  i_size_cnt <= i_size_cnt + 1;
                  i_flash_a <= i_flash_a + 1;
                  i_flash_oe_n <= CI_PHY_DIR_TX;
                  i_fsm_cs <= S_CFI_RD_WAIT;

                end if;

                i_cfi_bcnt <= i_cfi_bcnt + 1;
                i_irq <= '1';

            end if;
            --end if;

        when S_CFI_RD_WAIT =>

            i_rxbuf_wr <= '0';

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

          i_rxbuf_wr <= '0';

          if i_cmd_nxt = '0' then

              i_bcnt <= (others=>'0');
              i_cfi_bcnt <= (others=>'0');

              if OR_reduce(i_err) = '0' then
                i_flash_ce_n <= '1';
                i_txbuf_rd <= '0';
                i_fsm_cs <= S_IDLE;
              else
                  --При обнаружении ощибки чистим TxBUF от данных
                  i_txbuf_rd <= '1';
                  if i_size_cnt = (i_size - 1) then
                    i_irq <= '1';
                    i_fsm_cs <= S_ERR_STATUS_REG_CLR;
                  else
                    i_size_cnt <= i_size_cnt + 1;
                  end if;
              end if;

          else --if i_cmd_nxt /= '0' then

              i_txbuf_rd <= '0';
              i_cmd_nxt <= '0';

              if i_txbuf_do_max((32*1 + 3) downto 32*1) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DWR, 4) then
                i_size_byte <= i_txbuf_do_max(32*2 - 1 downto ((32*1) + 4));
                i_adr_cnt <= i_adr;
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_WR_SETUP;

              elsif i_txbuf_do_max((32*1 + 3) downto 32*1) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DRD, 4) then
                i_size_byte <= i_txbuf_do_max(32*2 - 1 downto ((32*1) + 4));
                i_adr_cnt <= i_adr;
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_RD_SETUP;

              elsif i_txbuf_do_max((32*1 + 3) downto 32*1) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DRD_CFI, 4) then
                i_size_byte <= i_txbuf_do_max(32*2 - 1 downto ((32*1) + 4));
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_CFI_SETUP;

              elsif i_txbuf_do_max((32*1 + 3) downto 32*1) = CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ERASE, 4) then
                i_size_byte <= i_txbuf_do_max(32*2 - 1 downto ((32*1) + 4));
                i_adr_cnt <= i_adr;
                i_flash_ce_n <= '0';
                i_fsm_cs <= S_UNLOCK_SETUP;

              end if;
          end if;

        when S_CMD_ERR =>

          i_flash_ce_n <= '1';

          if p_in_txbuf_empty = '1' then
            i_txbuf_rd <= '0';
            i_fsm_cs <= S_IDLE;
          end if;

        when S_ERR_STATUS_REG_CLR =>

            i_flash_do <= CONV_STD_LOGIC_VECTOR(16#50#, i_flash_do'length);

            if i_flash_we_n = '0' then
              i_flash_we_n <= '1';
              i_fsm_cs <= S_CMD_ERR;
            else
              i_flash_we_n <= '0';
            end if;

    end case;
  end if;--if p_in_clk_en = '1' then
  end if;
end if;
end process;


--END MAIN
end behavioral;
