-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 16.07.2011 12:22:36
-- Module Name : cfgdev_host
--
-- architecture behav1 :
--  Протокол обмена:
--  Write:  SW -> FPGA
--   1. SW (CfgPkt(Header + data)) -> FPGA
--
--  Read :  SW <- FPGA
--   1. SW (CfgPkt(Header) -> FPGA
--   2. SW  <- FPGA (CfgPkt(Header + Data)
--
-- architecture behav2 :
--  Протокол обмена:
--  Write:  SW -> FPGA
--   1. SW (CfgPkt(Header + data)) -> FPGA
--   2. SW <- FPGA (CfgPkt(Header))
--
--  Read :  SW <- FPGA
--   1. SW (CfgPkt(Header) -> FPGA
--   2. SW  <- FPGA (CfgPkt(Header + Data)
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.cfgdev_pkg.all;
use work.reduce_pack.all;

entity cfgdev_host is
generic(
G_DBG : string := "OFF";
G_HOST_DWIDTH_H2D : integer := 32;
G_HOST_DWIDTH_D2H : integer := 32;
C_FMODULE_DWIDTH  : integer := 16
);
port(
-------------------------------
--HOST
-------------------------------
--host -> dev
p_in_htxbuf_di       : in   std_logic_vector(G_HOST_DWIDTH_H2D - 1 downto 0);
p_in_htxbuf_wr       : in   std_logic;
p_out_htxbuf_full    : out  std_logic;
p_out_htxbuf_empty   : out  std_logic;

--host <- dev
p_out_hrxbuf_do      : out  std_logic_vector(G_HOST_DWIDTH_H2D - 1 downto 0);
p_in_hrxbuf_rd       : in   std_logic;
p_out_hrxbuf_full    : out  std_logic;
p_out_hrxbuf_empty   : out  std_logic;

p_out_hirq           : out  std_logic;
p_out_herr           : out  std_logic;

p_in_hclk            : in   std_logic;

-------------------------------
--FPGA DEV
-------------------------------
p_out_cfg_dadr       : out    std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0); --dev number
p_out_cfg_radr       : out    std_logic_vector(C_CFGPKT_RADR_M_BIT - C_CFGPKT_RADR_L_BIT downto 0); --adr registr
p_out_cfg_radr_ld    : out    std_logic;
p_out_cfg_radr_fifo  : out    std_logic;
p_out_cfg_wr         : out    std_logic;
p_out_cfg_rd         : out    std_logic;
p_out_cfg_txdata     : out    std_logic_vector(C_FMODULE_DWIDTH - 1 downto 0);
p_in_cfg_rxdata      : in     std_logic_vector(C_FMODULE_DWIDTH - 1 downto 0);
p_in_cfg_txrdy       : in     std_logic;
p_in_cfg_rxrdy       : in     std_logic;
p_out_cfg_done       : out    std_logic;
--p_in_cfg_irq         : in     std_logic;
p_in_cfg_clk         : in     std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst             : in     std_logic_vector(31 downto 0);
p_out_tst            : out    std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst             : in     std_logic
);
end entity cfgdev_host;

architecture behav1 of cfgdev_host is

constant CI_CFGPKT_H_CTRL_IDX   : integer := 0;
constant CI_CFGPKT_H_RADR_IDX   : integer := 1;
constant CI_CFGPKT_H_DLEN_IDX   : integer := 2;

component cfgdev_buf
generic(
G_DIWIDTH : integer := 32;
G_DOWIDTH : integer := 32
);
port(
din         : in  std_logic_vector(G_DIWIDTH - 1 downto 0);
wr_en       : in  std_logic;
wr_clk      : in  std_logic;

dout        : out std_logic_vector(G_DOWIDTH - 1 downto 0);
rd_en       : in  std_logic;
rd_clk      : in  std_logic;

empty       : out std_logic;
full        : out std_logic;
prog_full   : out std_logic;

rst         : in  std_logic
);
end component cfgdev_buf;

--component cfgdev_bufo
--generic(
--G_DIWIDTH : integer := 32;
--G_DOWIDTH : integer := 32
--);
--port(
--din         : in  std_logic_vector(G_DIWIDTH - 1 downto 0);
--wr_en       : in  std_logic;
--wr_clk      : in  std_logic;
--
--dout        : out std_logic_vector(G_DOWIDTH - 1 downto 0);
--rd_en       : in  std_logic;
--rd_clk      : in  std_logic;
--
--empty       : out std_logic;
--full        : out std_logic;
--prog_full   : out std_logic;
--
--rst         : in  std_logic
--);
--end component cfgdev_bufo;

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

signal i_htxbuf_di_swap                 : std_logic_vector(p_in_htxbuf_di'range);
signal i_hrxbuf_do_swap                 : std_logic_vector(p_out_hrxbuf_do'range);

signal i_dv_din                         : std_logic_vector(G_HOST_DWIDTH_D2H - 1 downto 0);
signal i_dv_din_r                       : unsigned(i_dv_din'range);
signal i_dv_dout                        : unsigned(i_dv_din'range);
signal i_dv_rd                          : std_logic;
signal i_dv_wr                          : std_logic;
signal i_dv_rxrdy                       : std_logic;

constant CI_CFG_DBYTE_SIZE              : integer := i_dv_din'length / p_out_cfg_txdata'length;
signal i_cfg_dbyte                      : integer range 0 to CI_CFG_DBYTE_SIZE - 1;
signal i_cfg_rgadr_ld                   : std_logic;
signal i_cfg_d                          : unsigned(p_out_cfg_txdata'range);
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_done                       : std_logic;

type TDevCfg_PktHeader is array (0 to C_CFGPKT_HEADER_DCOUNT - 1) of unsigned(i_cfg_d'range);
signal i_pkt_dheader                    : TDevCfg_PktHeader;
signal i_pkt_field_data                 : std_logic;
signal i_pkt_cntd                       : unsigned(C_CFGPKT_DLEN_M_BIT - C_CFGPKT_DLEN_L_BIT downto 0);

signal i_rxbuf_empty                    : std_logic;
signal i_txbuf_empty                    : std_logic;
signal i_txbuf_full                     : std_logic;
signal i_rxbuf_full                     : std_logic;

signal i_irq_out                        : std_logic;
signal i_irq_width                      : std_logic;
signal i_irq_width_cnt                  : unsigned(3 downto 0);

signal tst_fsm_cs                       : unsigned(3 downto 0) := (others => '0');
signal tst_fsm_cs_dly                   : std_logic_vector(tst_fsm_cs'range) := (others => '0');
signal tst_rst0                         : std_logic := '0';
signal tst_rst1                         : std_logic := '0';
signal tst_rstup,tst_rstdown            : std_logic := '0';
signal tst_host_rd                      : std_logic := '0';


begin --architecture behav1

------------------------------------
--DBG
------------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0) <= (others => '0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
process(p_in_cfg_clk)
begin
  if rising_edge(p_in_cfg_clk) then

    tst_rst0 <= p_in_rst;
    tst_rst1 <= tst_rst0;
    tst_rstup <= tst_rst0 and not tst_rst1;
    tst_rstdown <= not tst_rst0 and tst_rst1;
    tst_fsm_cs_dly <= std_logic_vector(tst_fsm_cs);
    p_out_tst(0) <= OR_reduce(tst_fsm_cs_dly) or i_cfg_done or tst_rstup or tst_rstdown;--tst_host_rd or

  end if;
end process;
p_out_tst(5 downto 1) <= (others => '0');
p_out_tst(9 downto 6) <= std_logic_vector(tst_fsm_cs);
p_out_tst(10) <= '0';
p_out_tst(11) <= i_dv_rd;
p_out_tst(12) <= i_dv_wr;
p_out_tst(13) <= '0';
p_out_tst(14) <= '0';
p_out_tst(15) <= '0';
p_out_tst(16) <= i_pkt_field_data;
p_out_tst(17) <= '0';
p_out_tst(19 downto 18) <= (others => '0');--RESIZE(i_cfg_dbyte, 2);
p_out_tst(27 downto 20) <= std_logic_vector(i_pkt_cntd(7 downto 0));
p_out_tst(31 downto 28) <= (others => '0');

tst_fsm_cs <= TO_UNSIGNED(16#01#, tst_fsm_cs'length) when fsm_state_cs = S_DEV_WAIT_RXRDY else
              TO_UNSIGNED(16#02#, tst_fsm_cs'length) when fsm_state_cs = S_DEV_RXD        else
              TO_UNSIGNED(16#03#, tst_fsm_cs'length) when fsm_state_cs = S_DEV_WAIT_TXRDY else
              TO_UNSIGNED(16#04#, tst_fsm_cs'length) when fsm_state_cs = S_DEV_TXD        else
              TO_UNSIGNED(16#05#, tst_fsm_cs'length) when fsm_state_cs = S_PKTH_RXCHK     else
              TO_UNSIGNED(16#06#, tst_fsm_cs'length) when fsm_state_cs = S_PKTH_TXCHK     else
              TO_UNSIGNED(16#07#, tst_fsm_cs'length) when fsm_state_cs = S_CFG_WAIT_TXRDY else
              TO_UNSIGNED(16#08#, tst_fsm_cs'length) when fsm_state_cs = S_CFG_TXD        else
              TO_UNSIGNED(16#09#, tst_fsm_cs'length) when fsm_state_cs = S_CFG_WAIT_RXRDY else
              TO_UNSIGNED(16#00#, tst_fsm_cs'length);
--              TO_UNSIGNED(16#00#, tst_fsm_cs'length) when fsm_state_cs = S_CFG_RXD       else

end generate gen_dbg_on;


--------------------------------------------------
--
--------------------------------------------------
p_out_herr <= '0';
p_out_hirq <= i_irq_out;

--Expand srtobe IRQ
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_rst = '1' then
    i_irq_width <= '0';
    i_irq_width_cnt <= (others => '0');
  else

      if i_cfg_done = '1' and i_pkt_dheader(0)(C_CFGPKT_WR_BIT) = C_CFGPKT_RD then
        i_irq_width <= '1';
      elsif i_irq_width_cnt(3) = '1' then
        i_irq_width <= '0';
      end if;

      if i_irq_width = '0' then
        i_irq_width_cnt <= (others => '0');
      else
        i_irq_width_cnt <= i_irq_width_cnt+1;
      end if;

  end if;
end if;
end process;

process(p_in_rst, p_in_hclk)
begin
  if rising_edge(p_in_hclk) then
    i_irq_out <= i_irq_width;
  end if;
end process;


--------------------------------------------------
--
--------------------------------------------------
--HOST -> FPGA
p_out_htxbuf_full <= i_rxbuf_full;
--p_out_htxbuf_empty <= i_rxbuf_empty;

gen_htxbuf_di_swap : for i in 0 to G_HOST_DWIDTH_H2D / G_HOST_DWIDTH_D2H - 1 generate begin
i_htxbuf_di_swap((p_in_htxbuf_di'length - (G_HOST_DWIDTH_D2H * i)) - 1 downto
                    (p_in_htxbuf_di'length - (G_HOST_DWIDTH_D2H * (i + 1))))

                  <= p_in_htxbuf_di((G_HOST_DWIDTH_D2H * (i + 1) - 1) downto (G_HOST_DWIDTH_D2H * i));
end generate gen_htxbuf_di_swap;

m_rxbuf : cfgdev_buf
generic map(
G_DIWIDTH => G_HOST_DWIDTH_H2D,
G_DOWIDTH => G_HOST_DWIDTH_D2H
)
port map(
din         => i_htxbuf_di_swap,
wr_en       => p_in_htxbuf_wr,
wr_clk      => p_in_hclk,

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
--p_out_hrxbuf_empty <= i_txbuf_empty;

m_txbuf : cfgdev_buf
generic map(
G_DIWIDTH => G_HOST_DWIDTH_D2H,
G_DOWIDTH => G_HOST_DWIDTH_H2D
)
port map(
din         => std_logic_vector(i_dv_dout),
wr_en       => i_dv_wr,
wr_clk      => p_in_cfg_clk,

dout        => i_hrxbuf_do_swap,
rd_en       => p_in_hrxbuf_rd,
rd_clk      => p_in_hclk,

empty       => p_out_hrxbuf_empty,
full        => open,
prog_full   => i_txbuf_full,

rst         => p_in_rst
);

gen_hrxbuf_do_swap : for i in 0 to G_HOST_DWIDTH_H2D / G_HOST_DWIDTH_D2H - 1 generate begin
p_out_hrxbuf_do((i_hrxbuf_do_swap'length - (G_HOST_DWIDTH_D2H * i)) - 1 downto
                    (i_hrxbuf_do_swap'length - (G_HOST_DWIDTH_D2H * (i + 1))))

                  <= i_hrxbuf_do_swap((G_HOST_DWIDTH_D2H * (i + 1) - 1) downto (G_HOST_DWIDTH_D2H * i));
end generate gen_hrxbuf_do_swap;


--------------------------------------------------
--
--------------------------------------------------
p_out_cfg_dadr      <= std_logic_vector(i_pkt_dheader(CI_CFGPKT_H_CTRL_IDX)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT));
p_out_cfg_radr_fifo <=                  i_pkt_dheader(CI_CFGPKT_H_CTRL_IDX)(C_CFGPKT_FIFO_BIT);
p_out_cfg_radr      <= std_logic_vector(i_pkt_dheader(CI_CFGPKT_H_RADR_IDX)(C_CFGPKT_RADR_M_BIT downto C_CFGPKT_RADR_L_BIT));
p_out_cfg_radr_ld   <= i_cfg_rgadr_ld;
p_out_cfg_rd        <= i_cfg_rd;
p_out_cfg_wr        <= i_cfg_wr;
p_out_cfg_txdata    <= std_logic_vector(i_cfg_d);

p_out_cfg_done      <= i_cfg_done;


--------------------------------------------------
--FSM
--------------------------------------------------
process(p_in_cfg_clk)
  variable pkt_type : std_logic;
  variable pkt_dlen : unsigned(i_pkt_cntd'range);
begin
if rising_edge(p_in_cfg_clk) then
if p_in_rst = '1' then

  fsm_state_cs <= S_DEV_WAIT_RXRDY;

  i_dv_rd <= '0';
  i_dv_wr <= '0';
  i_dv_dout <= (others => '0');
  i_dv_din_r <= (others => '0');

  i_cfg_rgadr_ld <= '0';
  i_cfg_d <= (others => '0');
  i_cfg_wr <= '0';
  i_cfg_rd <= '0';
  i_cfg_done <= '0';

    pkt_type := '0';
    pkt_dlen  := (others => '0');
  i_pkt_cntd <= (others => '0');
  i_pkt_field_data <= '0';
  for i in 0 to C_CFGPKT_HEADER_DCOUNT - 1 loop
  i_pkt_dheader(i) <= (others => '0');
  end loop;

else
--  if p_in_clken = '1' then

  case fsm_state_cs is

    --################################
    --Recieve data (PC -> FPGA)
    --################################
    when S_DEV_WAIT_RXRDY =>

      i_cfg_rgadr_ld <= '0';
      i_cfg_done <= '0';
      i_dv_wr <= '0';

      if i_rxbuf_empty = '0' then
        i_dv_rd <= '1';
        i_dv_din_r <= UNSIGNED(i_dv_din);

        fsm_state_cs <= S_DEV_RXD;
      end if;

    ----------------------------------
    --Recieve Data from PC
    ----------------------------------
    when S_DEV_RXD =>

      i_cfg_rgadr_ld <= '0';
      i_dv_rd <= '0';

      if i_pkt_field_data = '1' then

          for i in 0 to CI_CFG_DBYTE_SIZE - 1 loop
            if i_cfg_dbyte = i then
              i_cfg_d <= i_dv_din_r((i_cfg_d'length * (i + 1)) - 1
                                        downto (i_cfg_d'length * i));
            end if;
          end loop;

          fsm_state_cs <= S_CFG_WAIT_TXRDY;

      else

        for i in 0 to CI_CFG_DBYTE_SIZE - 1 loop
          if i_cfg_dbyte = i then
            for y in 0 to C_CFGPKT_HEADER_DCOUNT - 1 loop
              if i_pkt_cntd(2 downto 0) = y then
                i_pkt_dheader(y) <= i_dv_din_r((i_pkt_dheader(y)'length * (i + 1)) - 1
                                                    downto (i_pkt_dheader(y)'length * i));
              end if;
            end loop;
          end if;
        end loop;

        fsm_state_cs <= S_PKTH_RXCHK;

      end if;

    ----------------------------------
    --
    ----------------------------------
    when S_PKTH_RXCHK =>

      if i_pkt_cntd(1 downto 0) = TO_UNSIGNED(C_CFGPKT_HEADER_DCOUNT - 1, 2) then

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

            i_pkt_cntd <= (others => '0');
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
    --Write data to fpga modules
    ----------------------------------
    when S_CFG_WAIT_TXRDY =>

      if p_in_cfg_txrdy = '1' then
        i_cfg_wr <= '1';
        fsm_state_cs <= S_CFG_TXD;
      end if;

    when S_CFG_TXD =>

      i_cfg_wr <= '0';

      if i_pkt_cntd = (i_pkt_cntd'range => '0') then
        i_pkt_field_data <= '0';
        i_cfg_done <= '1';

        i_cfg_dbyte <= 0;
        fsm_state_cs <= S_DEV_WAIT_RXRDY;

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
    --Send Data (PC <- FPGA)
    --################################
    when S_PKTH_TXCHK =>

      i_cfg_rgadr_ld <= '0';
      i_dv_wr <= '0';

      if i_pkt_cntd(2 downto 0) = TO_UNSIGNED(C_CFGPKT_HEADER_DCOUNT, 3) then
      --SW <- FPGA (txask) - header sended, goto read data from fpga modules
        i_pkt_cntd <= i_pkt_dheader(CI_CFGPKT_H_DLEN_IDX)(C_CFGPKT_DLEN_M_BIT downto C_CFGPKT_DLEN_L_BIT);
        i_pkt_field_data <= '1';
        fsm_state_cs <= S_CFG_WAIT_RXRDY;
      else
        i_pkt_cntd <= i_pkt_cntd + 1;
        fsm_state_cs <= S_DEV_WAIT_TXRDY;
      end if;

      for i in 0 to C_CFGPKT_HEADER_DCOUNT - 1 loop
        if i_pkt_cntd(1 downto 0) = i then
          i_cfg_d <= i_pkt_dheader(i);
        end if;
      end loop;

    ----------------------------------
    when S_DEV_WAIT_TXRDY =>

      if i_txbuf_full = '0' then

        for i in 0 to CI_CFG_DBYTE_SIZE - 1 loop
          if i_cfg_dbyte = i then
            i_dv_dout((i_cfg_d'length * (i + 1)) - 1
                          downto (i_cfg_d'length * i)) <= i_cfg_d;
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

      end if;

    ----------------------------------
    --Send Data to PC
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
    --Read data from FPGA devices
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
        i_cfg_d <= UNSIGNED(p_in_cfg_rxdata);
        i_pkt_cntd <= i_pkt_cntd - 1;
        fsm_state_cs <= S_DEV_WAIT_TXRDY;
      end if;

  end case;
--  end if;--if p_in_clken = '1' then
end if;
end if;
end process;


end architecture behav1;



architecture behav2 of cfgdev_host is

constant CI_CFGPKT_H_ETHLEN_IDX : integer := 0;
constant CI_CFGPKT_H_CTRL_IDX   : integer := 1;
constant CI_CFGPKT_H_RADR_IDX   : integer := 2;
constant CI_CFGPKT_H_DLEN_IDX   : integer := 3;

constant CI_CFGPKT_HEADER_DCOUNT : integer := C_CFGPKT_HEADER_DCOUNT + 1;

component cfgdev_buf
generic(
G_DIWIDTH : integer := 32;
G_DOWIDTH : integer := 32
);
port(
din         : in  std_logic_vector(G_DIWIDTH - 1 downto 0);
wr_en       : in  std_logic;
wr_clk      : in  std_logic;

dout        : out std_logic_vector(G_DOWIDTH - 1 downto 0);
rd_en       : in  std_logic;
rd_clk      : in  std_logic;

empty       : out std_logic;
full        : out std_logic;
prog_full   : out std_logic;

rst         : in  std_logic
);
end component cfgdev_buf;

--component cfgdev_bufo
--generic(
--G_DIWIDTH : integer := 32;
--G_DOWIDTH : integer := 32
--);
--port(
--din         : in  std_logic_vector(G_DIWIDTH - 1 downto 0);
--wr_en       : in  std_logic;
--wr_clk      : in  std_logic;
--
--dout        : out std_logic_vector(G_DOWIDTH - 1 downto 0);
--rd_en       : in  std_logic;
--rd_clk      : in  std_logic;
--
--empty       : out std_logic;
--full        : out std_logic;
--prog_full   : out std_logic;
--
--rst         : in  std_logic
--);
--end component cfgdev_bufo;

type fsm_state is (
S2_DEV_WAIT_RXRDY,
S2_DEV_RXD,
S2_DEV_WAIT_TXRDY,
S2_DEV_TXD,
S2_PKTH_RXCHK,
S2_PKTH_TXCHK,
S2_CFG_WAIT_TXRDY,
S2_CFG_TXD,
S2_CFG_WAIT_RXRDY,
S2_CFG_RXD
);
signal fsm_state_cs                     : fsm_state;

signal i_htxbuf_di_swap                 : std_logic_vector(p_in_htxbuf_di'range);
signal i_hrxbuf_do_swap                 : std_logic_vector(p_out_hrxbuf_do'range);

signal i_dv_din                         : std_logic_vector(G_HOST_DWIDTH_D2H - 1 downto 0);
signal i_dv_din_r                       : unsigned(i_dv_din'range);
signal i_dv_dout                        : unsigned(i_dv_din'range);
signal i_dv_rd                          : std_logic;
signal i_dv_wr                          : std_logic;
signal i_dv_rxrdy                       : std_logic;

constant CI_CFG_DBYTE_SIZE              : integer := i_dv_din'length / p_out_cfg_txdata'length;
signal i_cfg_dbyte                      : integer range 0 to CI_CFG_DBYTE_SIZE - 1;
signal i_cfg_rgadr_ld                   : std_logic;
signal i_cfg_d                          : unsigned(p_out_cfg_txdata'range);
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_done                       : std_logic;

type TDevCfg_PktHeader is array (0 to CI_CFGPKT_HEADER_DCOUNT - 1) of unsigned(i_cfg_d'range);
signal i_pkt_dheader                    : TDevCfg_PktHeader;
signal i_pkt_field_data                 : std_logic;
signal i_pkt_cntd                       : unsigned(C_CFGPKT_DLEN_M_BIT - C_CFGPKT_DLEN_L_BIT downto 0);
signal i_pkt_txack                      : std_logic;

signal i_rxbuf_empty                    : std_logic;
signal i_txbuf_empty                    : std_logic;
signal i_txbuf_full                     : std_logic;
signal i_rxbuf_full                     : std_logic;

signal i_irq_out                        : std_logic;
signal i_irq_width                      : std_logic;
signal i_irq_width_cnt                  : unsigned(3 downto 0);

signal tst_fsm_cs                       : unsigned(3 downto 0) := (others => '0');
signal tst_fsm_cs_dly                   : std_logic_vector(tst_fsm_cs'range) := (others => '0');
signal tst_rst0                         : std_logic := '0';
signal tst_rst1                         : std_logic := '0';
signal tst_rstup,tst_rstdown            : std_logic := '0';
signal tst_host_rd                      : std_logic := '0';


begin --architecture behav2

------------------------------------
--DBG
------------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0) <= (others => '0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
process(p_in_cfg_clk)
begin
  if rising_edge(p_in_cfg_clk) then

    tst_rst0 <= p_in_rst;
    tst_rst1 <= tst_rst0;
    tst_rstup <= tst_rst0 and not tst_rst1;
    tst_rstdown <= not tst_rst0 and tst_rst1;
    tst_fsm_cs_dly <= std_logic_vector(tst_fsm_cs);
    p_out_tst(0) <= OR_reduce(tst_fsm_cs_dly) or i_cfg_done or tst_rstup or tst_rstdown;--tst_host_rd or

  end if;
end process;
p_out_tst(5 downto 1) <= (others => '0');
p_out_tst(9 downto 6) <= std_logic_vector(tst_fsm_cs);
p_out_tst(10) <= '0';
p_out_tst(11) <= i_dv_rd;
p_out_tst(12) <= i_dv_wr;
p_out_tst(13) <= '0';
p_out_tst(14) <= '0';
p_out_tst(15) <= '0';
p_out_tst(16) <= i_pkt_field_data;
p_out_tst(17) <= '0';
p_out_tst(19 downto 18) <= (others => '0');--RESIZE(i_cfg_dbyte, 2);
p_out_tst(27 downto 20) <= std_logic_vector(i_pkt_cntd(7 downto 0));
p_out_tst(31 downto 28) <= (others => '0');

tst_fsm_cs <= TO_UNSIGNED(16#01#, tst_fsm_cs'length) when fsm_state_cs = S2_DEV_WAIT_RXRDY else
              TO_UNSIGNED(16#02#, tst_fsm_cs'length) when fsm_state_cs = S2_DEV_RXD        else
              TO_UNSIGNED(16#03#, tst_fsm_cs'length) when fsm_state_cs = S2_DEV_WAIT_TXRDY else
              TO_UNSIGNED(16#04#, tst_fsm_cs'length) when fsm_state_cs = S2_DEV_TXD        else
              TO_UNSIGNED(16#05#, tst_fsm_cs'length) when fsm_state_cs = S2_PKTH_RXCHK     else
              TO_UNSIGNED(16#06#, tst_fsm_cs'length) when fsm_state_cs = S2_PKTH_TXCHK     else
              TO_UNSIGNED(16#07#, tst_fsm_cs'length) when fsm_state_cs = S2_CFG_WAIT_TXRDY else
              TO_UNSIGNED(16#08#, tst_fsm_cs'length) when fsm_state_cs = S2_CFG_TXD        else
              TO_UNSIGNED(16#09#, tst_fsm_cs'length) when fsm_state_cs = S2_CFG_WAIT_RXRDY else
              TO_UNSIGNED(16#00#, tst_fsm_cs'length);
--              TO_UNSIGNED(16#00#, tst_fsm_cs'length) when fsm_state_cs = S2_CFG_RXD       else

end generate gen_dbg_on;


--------------------------------------------------
--
--------------------------------------------------
p_out_herr <= '0';
p_out_hirq <= i_irq_out;

--Expand strobe IRQ
process(p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_rst = '1' then
    i_irq_width <= '0';
    i_irq_width_cnt <= (others => '0');
  else

      if i_cfg_done = '1' and i_pkt_dheader(0)(C_CFGPKT_WR_BIT) = C_CFGPKT_RD then
        i_irq_width <= '1';
      elsif i_irq_width_cnt(3) = '1' then
        i_irq_width <= '0';
      end if;

      if i_irq_width = '0' then
        i_irq_width_cnt <= (others => '0');
      else
        i_irq_width_cnt <= i_irq_width_cnt+1;
      end if;

  end if;
end if;
end process;

process(p_in_rst, p_in_hclk)
begin
  if rising_edge(p_in_hclk) then
    i_irq_out <= i_irq_width;
  end if;
end process;


--------------------------------------------------
--
--------------------------------------------------
--HOST -> FPGA
p_out_htxbuf_full <= i_rxbuf_full;
--p_out_htxbuf_empty <= i_rxbuf_empty;

gen_htxbuf_di_swap : for i in 0 to G_HOST_DWIDTH_H2D / G_HOST_DWIDTH_D2H - 1 generate begin
i_htxbuf_di_swap((p_in_htxbuf_di'length - (G_HOST_DWIDTH_D2H * i)) - 1 downto
                    (p_in_htxbuf_di'length - (G_HOST_DWIDTH_D2H * (i + 1))))

                  <= p_in_htxbuf_di((G_HOST_DWIDTH_D2H * (i + 1) - 1) downto (G_HOST_DWIDTH_D2H * i));
end generate gen_htxbuf_di_swap;

m_rxbuf : cfgdev_buf
generic map(
G_DIWIDTH => G_HOST_DWIDTH_H2D,
G_DOWIDTH => G_HOST_DWIDTH_D2H
)
port map(
din         => i_htxbuf_di_swap,
wr_en       => p_in_htxbuf_wr,
wr_clk      => p_in_hclk,

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
--p_out_hrxbuf_empty <= i_txbuf_empty;

m_txbuf : cfgdev_buf
generic map(
G_DIWIDTH => G_HOST_DWIDTH_D2H,
G_DOWIDTH => G_HOST_DWIDTH_H2D
)
port map(
din         => std_logic_vector(i_dv_dout),
wr_en       => i_dv_wr,
wr_clk      => p_in_cfg_clk,

dout        => i_hrxbuf_do_swap,
rd_en       => p_in_hrxbuf_rd,
rd_clk      => p_in_hclk,

empty       => p_out_hrxbuf_empty,
full        => open,
prog_full   => i_txbuf_full,

rst         => p_in_rst
);

gen_hrxbuf_do_swap : for i in 0 to G_HOST_DWIDTH_H2D / G_HOST_DWIDTH_D2H - 1 generate begin
p_out_hrxbuf_do((i_hrxbuf_do_swap'length - (G_HOST_DWIDTH_D2H * i)) - 1 downto
                    (i_hrxbuf_do_swap'length - (G_HOST_DWIDTH_D2H * (i + 1))))

                  <= i_hrxbuf_do_swap((G_HOST_DWIDTH_D2H * (i + 1) - 1) downto (G_HOST_DWIDTH_D2H * i));
end generate gen_hrxbuf_do_swap;


--------------------------------------------------
--
--------------------------------------------------
p_out_cfg_dadr      <= std_logic_vector(i_pkt_dheader(CI_CFGPKT_H_CTRL_IDX)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT));
p_out_cfg_radr_fifo <=                  i_pkt_dheader(CI_CFGPKT_H_CTRL_IDX)(C_CFGPKT_FIFO_BIT);
p_out_cfg_radr      <= std_logic_vector(i_pkt_dheader(CI_CFGPKT_H_RADR_IDX)(C_CFGPKT_RADR_M_BIT downto C_CFGPKT_RADR_L_BIT));
p_out_cfg_radr_ld   <= i_cfg_rgadr_ld;
p_out_cfg_rd        <= i_cfg_rd;
p_out_cfg_wr        <= i_cfg_wr;
p_out_cfg_txdata    <= std_logic_vector(i_cfg_d);

p_out_cfg_done      <= i_cfg_done;--Операция завершена



--------------------------------------------------
--FSM
--------------------------------------------------
process(p_in_rst,p_in_cfg_clk)
  variable pkt_type : std_logic;
  variable pkt_dlen : unsigned(i_pkt_cntd'range);
begin

if p_in_rst = '1' then

  fsm_state_cs <= S2_DEV_WAIT_RXRDY;

  i_dv_rd <= '0';
  i_dv_wr <= '0';
  i_dv_dout <= (others => '0');
  i_dv_din_r <= (others => '0');

  i_cfg_rgadr_ld <= '0';
  i_cfg_d <= (others => '0');
  i_cfg_wr <= '0';
  i_cfg_rd <= '0';
  i_cfg_done <= '0';

    pkt_type := '0';
    pkt_dlen := (others => '0');
  i_pkt_cntd <= (others => '0');
  i_pkt_field_data <= '0';
  for i in 0 to CI_CFGPKT_HEADER_DCOUNT - 1 loop
  i_pkt_dheader(i) <= (others => '0');
  end loop;
  i_pkt_txack <= '0';

elsif rising_edge(p_in_cfg_clk) then
--  if p_in_clken = '1' then

  case fsm_state_cs is

    --################################
    --Recieve data (PC -> FPGA)
    --################################
    when S2_DEV_WAIT_RXRDY =>

      i_cfg_rgadr_ld <= '0';
      i_cfg_done <= '0';
      i_dv_wr <= '0';

      if i_rxbuf_empty = '0' then
        i_dv_rd <='1';
        i_dv_din_r <= UNSIGNED(i_dv_din);

        fsm_state_cs <= S2_DEV_RXD;
      end if;

    ----------------------------------
    --Recieve Data from PC
    ----------------------------------
    when S2_DEV_RXD =>

      i_cfg_rgadr_ld <= '0';
      i_dv_rd <= '0';

      if i_pkt_field_data = '1' then

          for i in 0 to CI_CFG_DBYTE_SIZE - 1 loop
            if i_cfg_dbyte = i then
              i_cfg_d <= i_dv_din_r((i_cfg_d'length * (i + 1)) - 1
                                        downto (i_cfg_d'length * i));
            end if;
          end loop;

          fsm_state_cs <= S2_CFG_WAIT_TXRDY;

      else

        for i in 0 to CI_CFG_DBYTE_SIZE - 1 loop
          if i_cfg_dbyte = i then
            for y in 0 to CI_CFGPKT_HEADER_DCOUNT - 1 loop
              if i_pkt_cntd(2 downto 0) = y then
                i_pkt_dheader(y) <= i_dv_din_r((i_pkt_dheader(y)'length * (i + 1)) - 1
                                                    downto (i_pkt_dheader(y)'length * i));
              end if;
            end loop;
          end if;
        end loop;

        fsm_state_cs <= S2_PKTH_RXCHK;

      end if;


    ----------------------------------
    --
    ----------------------------------
    when S2_PKTH_RXCHK =>

      if i_pkt_cntd(1 downto 0) = TO_UNSIGNED(CI_CFGPKT_HEADER_DCOUNT - 1, 2) then

          i_cfg_rgadr_ld <= '1';

            pkt_type := i_pkt_dheader(CI_CFGPKT_H_CTRL_IDX)(C_CFGPKT_WR_BIT);
            pkt_dlen := i_pkt_dheader(CI_CFGPKT_H_DLEN_IDX)(C_CFGPKT_DLEN_M_BIT downto C_CFGPKT_DLEN_L_BIT) - 1;

          if pkt_type = C_CFGPKT_WR then

              i_pkt_cntd <= pkt_dlen;
              i_pkt_field_data <= '1';

              if i_cfg_dbyte = CI_CFG_DBYTE_SIZE - 1 then
                i_cfg_dbyte <= 0;
                fsm_state_cs <= S2_DEV_WAIT_RXRDY;
              else
                i_cfg_dbyte <= i_cfg_dbyte + 1;
                fsm_state_cs <= S2_DEV_RXD;
              end if;

          else
--              i_pkt_dheader(CI_CFGPKT_H_ETHLEN_IDX) <= TO_UNSIGNED(CI_CFGPKT_HEADER_DCOUNT * 2
--                                                                   , i_pkt_dheader(CI_CFGPKT_H_ETHLEN_IDX)'length)
--                                                       + (i_pkt_dheader(CI_CFGPKT_H_DLEN_IDX)
--                                                                     (C_CFGPKT_DLEN_M_BIT - 1 downto C_CFGPKT_DLEN_L_BIT) & '0');
              i_pkt_cntd <= (others => '0');
              i_cfg_dbyte <= 0;
              fsm_state_cs <= S2_PKTH_TXCHK;
          end if;

      else

        if i_cfg_dbyte = CI_CFG_DBYTE_SIZE - 1 then
          i_cfg_dbyte <= 0;
          fsm_state_cs <= S2_DEV_WAIT_RXRDY;
        else
          i_cfg_dbyte <= i_cfg_dbyte + 1;
          fsm_state_cs <= S2_DEV_RXD;

        end if;

        i_pkt_cntd <= i_pkt_cntd + 1;

      end if;

    ----------------------------------
    --Write data to fpga modules
    ----------------------------------
    when S2_CFG_WAIT_TXRDY =>

      if p_in_cfg_txrdy = '1' then
        i_cfg_wr <= '1';
        fsm_state_cs <= S2_CFG_TXD;
      end if;

    when S2_CFG_TXD =>

      i_cfg_wr <= '0';

      if i_pkt_cntd = (i_pkt_cntd'range => '0') then
--      --NO TxACK
--        i_pkt_field_data <= '0';
--        i_cfg_done <= '1';
--        i_cfg_dbyte <= 0;
--        fsm_state_cs <= S2_DEV_WAIT_RXRDY;

      --YES TxACK
        i_pkt_field_data <= '0';
        i_pkt_dheader(CI_CFGPKT_H_ETHLEN_IDX) <= TO_UNSIGNED(CI_CFGPKT_HEADER_DCOUNT * 2
                                                             , i_pkt_dheader(CI_CFGPKT_H_ETHLEN_IDX)'length);
        i_cfg_dbyte <= 0;
        fsm_state_cs <= S2_TXACK_CHK;

        --old
--        i_pkt_field_data <= '0';
--        i_cfg_done <= '1';
--
--        i_pkt_dheader(CI_CFGPKT_H_ETHLEN_IDX) <= TO_UNSIGNED(CI_CFGPKT_HEADER_DCOUNT * 2
--                                                             , i_pkt_dheader(CI_CFGPKT_H_ETHLEN_IDX)'length);
--        i_cfg_dbyte <= 0;
--        i_pkt_txack <= '1';
--        fsm_state_cs <= S2_PKTH_TXCHK;

      else
        i_pkt_cntd <= i_pkt_cntd - 1;

        if i_cfg_dbyte = CI_CFG_DBYTE_SIZE - 1 then
          i_cfg_dbyte <= 0;
          fsm_state_cs <= S2_DEV_WAIT_RXRDY;
        else
          i_cfg_dbyte <= i_cfg_dbyte + 1;
          fsm_state_cs <= S2_DEV_RXD;
        end if;

      end if;

    --################################
    --TXACK
    --################################
    when S2_TXACK_CHK =>

      if i_pkt_cntd(2 downto 0) = TO_UNSIGNED(CI_CFGPKT_HEADER_DCOUNT - 1, 3) then
        i_pkt_cntd <= (others => '0');
        i_cfg_done <= '1';

        if i_cfg_dbyte /= 0 then
          i_dv_wr <= '1';
        end if;
        i_cfg_dbyte <= 0;

        fsm_state_cs <= S2_DEV_WAIT_RXRDY;
        end if;
      else

        if i_cfg_dbyte = 0 then
          i_dv_wr <= '0';
        end if;

        fsm_state_cs <= S2_TXACK_TXRDY;
      end if;

      for i in 0 to CI_CFGPKT_HEADER_DCOUNT - 1 loop
        if i_pkt_cntd(1 downto 0) = i then
          i_cfg_d <= i_pkt_dheader(i);
        end if;
      end loop;

    when S2_TXACK_TXRDY =>

      if i_txbuf_full = '0' then

        for i in 0 to CI_CFG_DBYTE_SIZE - 1 loop
          if i_cfg_dbyte = i then
            i_dv_dout((i_cfg_d'length * (i + 1)) - 1
                          downto (i_cfg_d'length * i)) <= i_cfg_d;
          end if;
        end loop;

        if i_cfg_dbyte = CI_CFG_DBYTE_SIZE - 1 then
          i_cfg_dbyte <= 0; i_dv_wr <= '1';
        else
          i_cfg_dbyte <= i_cfg_dbyte + 1;
        end if;

        i_pkt_cntd <= i_pkt_cntd + 1;

        fsm_state_cs <= S2_TXACK_CHK;

      end if;



    --################################
    --Send Data (PC <- FPGA)
    --################################
    when S2_PKTH_TXCHK =>

      if i_cfg_dbyte = 0 then
        i_dv_wr <= '0';
      end if;

      if i_pkt_cntd(2 downto 0) = TO_UNSIGNED(CI_CFGPKT_HEADER_DCOUNT - 1, 3) then

        i_pkt_cntd <= i_pkt_dheader(CI_CFGPKT_H_DLEN_IDX)(C_CFGPKT_DLEN_M_BIT downto C_CFGPKT_DLEN_L_BIT);
        fsm_state_cs <= S2_CFG_WAIT_RXRDY;

      else
        fsm_state_cs <= S2_PKTH_TXRDY;
      end if;

      for i in 0 to CI_CFGPKT_HEADER_DCOUNT - 1 loop
        if i_pkt_cntd(1 downto 0) = i then
          i_cfg_d <= i_pkt_dheader(i);
        end if;
      end loop;

    ----------------------------------
    when S2_PKTH_TXRDY =>

      if i_txbuf_full = '0' then

        for i in 0 to CI_CFG_DBYTE_SIZE - 1 loop
          if i_cfg_dbyte = i then
            i_dv_dout((i_cfg_d'length * (i + 1)) - 1
                          downto (i_cfg_d'length * i)) <= i_cfg_d;
          end if;
        end loop;

        if i_cfg_dbyte = CI_CFG_DBYTE_SIZE - 1 then
          i_cfg_dbyte <= 0; i_dv_wr <= '1';
        else
          i_cfg_dbyte <= i_cfg_dbyte + 1;
        end if;

        i_pkt_cntd <= i_pkt_cntd + 1;
        fsm_state_cs <= S2_PKTH_TXCHK;

      end if;

    ----------------------------------
    --Read data from FPGA devices
    ----------------------------------
    when S2_CFG_WAIT_RXRDY =>

      i_dv_wr <= '0';

      if i_pkt_cntd = (i_pkt_cntd'range => '0') then

        fsm_state_cs <= S2_DEV_WAIT_TXRDY;

      else
        if p_in_cfg_rxrdy = '1' then
          i_cfg_rd <= '1';
          fsm_state_cs <= S2_CFG_RXD;
        end if;

      end if;

    when S2_CFG_RXD =>

      i_cfg_rd <= '0';

      if i_cfg_rd = '0' then
        i_cfg_d <= UNSIGNED(p_in_cfg_rxdata);
        i_pkt_cntd <= i_pkt_cntd - 1;
        fsm_state_cs <= S2_DEV_WAIT_TXRDY;
      end if;


--    ----------------------------------
--    --Send Data to PC
--    ----------------------------------
--    when S2_DEV_TXD =>
--
--      i_dv_wr <= '1';
--
--      if i_pkt_field_data = '1' then
--
--        if i_pkt_cntd = (i_pkt_cntd'range => '0') then
--          i_cfg_done <= '1';
--          i_pkt_field_data <= '0';
--          fsm_state_cs <= S2_DEV_WAIT_RXRDY;
--
--        else
--          fsm_state_cs <= S2_CFG_WAIT_RXRDY;
--        end if;
--
--      else
--        fsm_state_cs <= S2_PKTH_TXCHK;
--      end if;
  end case;
--  end if;--if p_in_clken = '1' then
end if;
end process;


end architecture behav2;