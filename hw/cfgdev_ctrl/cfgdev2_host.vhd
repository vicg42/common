-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.12.2014 15:13:26
-- Module Name : cfgdev2_host
--
-- architecture behav1 :
--  Rules:
--  Write:  HOST -> CFG
--   1. HOST (CfgPkt(Header(WR) + data)) -> CFG
--   2. HOST <- CFG (CfgPkt(Header(WR))
--
--  Read :  HOST <- CFG
--   1. HOST (CfgPkt(Header(RD)) -> CFG
--   2. HOST  <- CFG (CfgPkt(Header(RD) + Data)
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.cfgdev2_pkg.all;
use work.reduce_pack.all;

entity cfgdev2_host is
generic(
G_DBG : string := "OFF";
G_HOST_DWIDTH : integer := 32;
G_CFG_DWIDTH : integer := 16
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
p_in_hclk            : in   std_logic;

-------------------------------
--CFG
-------------------------------
p_out_cfg_dadr       : out    std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0); --dev number
p_out_cfg_radr       : out    std_logic_vector(G_CFG_DWIDTH - 1 downto 0); --adr register
p_out_cfg_radr_ld    : out    std_logic;
p_out_cfg_radr_fifo  : out    std_logic;
p_out_cfg_wr         : out    std_logic;
p_out_cfg_rd         : out    std_logic;
p_out_cfg_txdata     : out    std_logic_vector(G_CFG_DWIDTH - 1 downto 0);
p_in_cfg_txbuf_full  : in     std_logic;
p_in_cfg_txbuf_empty : in     std_logic;
p_in_cfg_rxdata      : in     std_logic_vector(G_CFG_DWIDTH - 1 downto 0);
p_in_cfg_rxbuf_full  : in     std_logic;
p_in_cfg_rxbuf_empty : in     std_logic;
p_out_cfg_done       : out    std_logic;
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
end entity cfgdev2_host;

architecture behav1 of cfgdev2_host is

--constant CI_CFGPKTH_ETHLEN_CHNK : integer := 0;
--constant CI_CFGPKTH_CTRL_CHNK   : integer := 1;
--constant CI_CFGPKTH_RADR_CHNK   : integer := 2;
--constant CI_CFGPKTH_DLEN_CHNK   : integer := 3;
--
--constant CI_CFGPKTH_DCOUNT : integer := C_CFGPKTH_DCOUNT + 1;

constant CI_CFGPKTH_CTRL_CHNK   : integer := 0;
constant CI_CFGPKTH_RADR_CHNK   : integer := 1;
constant CI_CFGPKTH_DLEN_CHNK   : integer := 2;

constant CI_CFGPKTH_DCOUNT : integer := C_CFGPKTH_DCOUNT;

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

type fsm_state is (
S2_HBUFR_IDLE,
S2_HBUFR_RxH,
S2_HBUFR_RxD,
S2_HBUFW_TxH,
S2_HBUFW_TxD
);
signal fsm_state_cs                     : fsm_state;

signal i_htxbuf_di_swap                 : std_logic_vector(p_in_htxbuf_di'range);
signal i_hrxbuf_do_swap                 : std_logic_vector(p_out_hrxbuf_do'range);
signal i_hbufr_rst                      : std_logic;
signal i_hbufr_clr                      : std_logic;
signal i_hbufr_do                       : std_logic_vector(p_in_htxbuf_di'range);
signal i_hbufr_rd                       : std_logic;
signal i_hbufr_full                     : std_logic;
signal i_hbufr_empty                    : std_logic;
signal i_hbufw_di                       : std_logic_vector(p_in_htxbuf_di'range);
signal i_hbufw_wr                       : std_logic;
signal i_hbufw_full                     : std_logic;
signal i_hbufw_empty                    : std_logic;

constant CI_CHUNK_COUNT                 : integer := p_in_htxbuf_di'length / p_out_cfg_txdata'length;
signal i_chnkcnt                        : unsigned(log2(CI_CHUNK_COUNT) - 1 downto 0);

signal i_fdev_radr_ld                   : std_logic;
signal i_fdev_txd                       : unsigned(p_out_cfg_txdata'range);
signal i_fdev_wr                        : std_logic;
signal i_fdev_rd                        : std_logic;
signal i_fdev_done                      : std_logic;

type TDevCfg_PktHeader is array (0 to CI_CFGPKTH_DCOUNT - 1) of unsigned(i_fdev_txd'range);
signal i_pkth                           : TDevCfg_PktHeader;
signal i_pkt_dcnt                       : unsigned(i_fdev_txd'range);



begin --architecture behav1

------------------------------------
--DBG
------------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0) <= (others => '0');
end generate gen_dbg_off;


--------------------------------------------------
--
--------------------------------------------------
p_out_hirq <= '0';


--------------------------------------------------
--
--------------------------------------------------
--HOST -> CFG
p_out_htxbuf_full <= i_hbufr_full;
p_out_htxbuf_empty <= i_hbufr_empty;

gen_htxbuf_di_swap : for i in 0 to G_HOST_DWIDTH / G_HOST_DWIDTH - 1 generate begin
i_htxbuf_di_swap((p_in_htxbuf_di'length - (G_HOST_DWIDTH * i)) - 1 downto
                    (p_in_htxbuf_di'length - (G_HOST_DWIDTH * (i + 1))))

                  <= p_in_htxbuf_di((G_HOST_DWIDTH * (i + 1) - 1) downto (G_HOST_DWIDTH * i));
end generate gen_htxbuf_di_swap;

m_rxbuf : cfgdev_buf
generic map(
G_DWIDTH => G_HOST_DWIDTH
)
port map(
din         => i_htxbuf_di_swap,
wr_en       => p_in_htxbuf_wr,
wr_clk      => p_in_hclk,

dout        => i_hbufr_do,
rd_en       => i_hbufr_rd,
rd_clk      => p_in_cfg_clk,

empty       => i_hbufr_empty,
full        => open,
prog_full   => i_hbufr_full,

rst         => i_hbufr_rst
);

i_hbufr_rst <= p_in_rst or i_hbufr_clr;
i_hbufr_rd <= OR_reduce(i_chnkcnt) and not i_hbufr_empty;

--HOST <- CFG
p_out_hrxbuf_full <= i_hbufw_full;
p_out_hrxbuf_empty <= i_hbufw_empty;

m_txbuf : cfgdev_buf
generic map(
G_DIWIDTH => G_HOST_DWIDTH,
G_DOWIDTH => G_HOST_DWIDTH
)
port map(
din         => i_hbufw_di,
wr_en       => i_hbufw_wr,
wr_clk      => p_in_cfg_clk,

dout        => i_hrxbuf_do_swap,
rd_en       => p_in_hrxbuf_rd,
rd_clk      => p_in_hclk,

empty       => i_hbufw_empty,
full        => open,
prog_full   => i_hbufw_full,

rst         => p_in_rst
);

gen_hrxbuf_do_swap : for i in 0 to G_HOST_DWIDTH / G_HOST_DWIDTH - 1 generate begin
p_out_hrxbuf_do((i_hrxbuf_do_swap'length - (G_HOST_DWIDTH * i)) - 1 downto
                    (i_hrxbuf_do_swap'length - (G_HOST_DWIDTH * (i + 1))))

                  <= i_hrxbuf_do_swap((G_HOST_DWIDTH * (i + 1) - 1) downto (G_HOST_DWIDTH * i));
end generate gen_hrxbuf_do_swap;


--------------------------------------------------
--
--------------------------------------------------
p_out_cfg_dadr      <= std_logic_vector(i_pkth(CI_CFGPKTH_CTRL_CHNK)(C_CFGPKT_DADR_M_BIT downto C_CFGPKT_DADR_L_BIT));
p_out_cfg_radr_fifo <=                  i_pkth(CI_CFGPKTH_CTRL_CHNK)(C_CFGPKT_FIFO_BIT);
p_out_cfg_radr      <= std_logic_vector(i_pkth(CI_CFGPKTH_RADR_CHNK));
p_out_cfg_radr_ld   <= i_fdev_radr_ld;
p_out_cfg_rd        <= i_fdev_rd and not i_hbufw_full and not p_in_cfg_rxbuf_empty;
p_out_cfg_wr        <= i_fdev_wr;
p_out_cfg_txdata    <= std_logic_vector(i_fdev_txd);

p_out_cfg_done      <= i_fdev_done;--Операция завершена



--------------------------------------------------
--FSM
--------------------------------------------------
process(p_in_rst,p_in_cfg_clk)
  variable pkth : TDevCfg_PktHeader;
begin

if p_in_rst = '1' then

  fsm_state_cs <= S2_HBUFR_IDLE;

  i_chnkcnt <= (others => '0');
  i_pkt_dcnt <= (others => '0');

  i_fdev_txd <= (others => '0');
  i_fdev_wr <= '0';
  i_fdev_rd <= '0';
  i_fdev_radr_ld <= '0';
  i_fdev_done <= '0';

  for i in 0 to i_pkth'length - 1 loop
  pkth(i) := (others => '0');
  i_pkth(i) <= (others => '0');
  end loop;

  i_hbufr_clr <= '0';
  i_hbufw_di <= (others => '0');
  i_hbufw_wr <= '0';

elsif rising_edge(p_in_cfg_clk) then

  case fsm_state_cs is

    when S2_HBUFR_IDLE =>

      i_fdev_radr_ld <= '0';
      i_fdev_rd <= '0';
      i_fdev_done <= '0';
      i_hbufw_wr <= '0';

      if i_hbufr_empty = '0' then
        fsm_state_cs <= S2_HBUFR_RxH;
      end if;

    --read host packet header
    when S2_HBUFR_RxH =>

      if i_hbufr_empty = '0' then
        if i_pkt_dcnt(1 downto 0) = TO_UNSIGNED(i_pkth'length - 1, 2) then

          i_fdev_radr_ld <= '1';
          i_pkt_dcnt <= (others => '0');

          --analize packet type
          if pkth(CI_CFGPKTH_CTRL_CHNK)(C_CFGPKT_WR_BIT) = C_CFGPKT_WR then
            if p_in_cfg_txbuf_full = '0' then
            i_chnkcnt <= i_chnkcnt + 1;
            fsm_state_cs <= S2_HBUFR_RxD; i_fdev_wr <= '1';
            end if;
          else
            i_chnkcnt <= (others => '0');
            i_hbufr_clr <= '1';
            fsm_state_cs <= S2_HBUFW_TxH;
          end if;

        else
          i_chnkcnt <= i_chnkcnt + 1;
          i_pkt_dcnt <= i_pkt_dcnt + 1;
        end if;
      end if;

      for i in 0 to CI_CHUNK_COUNT - 1 loop
        if i_chnkcnt = i then
          for y in 0 to i_pkth'length - 1 loop
            if i_pkt_dcnt(2 downto 0) = y then
              pkth(y) := UNSIGNED(i_hbufr_do((pkth(y)'length * (i + 1)) - 1
                                               downto (pkth(y)'length * i)));
            end if;
          end loop;
        end if;
      end loop;

      i_pkth <= pkth;

    --Write data to cfg devices
    when S2_HBUFR_RxD =>

      i_fdev_radr_ld <= '0';

      if i_hbufr_empty = '0' and p_in_cfg_txbuf_full = '0' then
        if i_pkt_dcnt = i_pkth(CI_CFGPKTH_DLEN_CHNK) - 1 then
          i_chnkcnt <= (others => '0');
          i_pkt_dcnt <= (others => '0');
          i_hbufr_clr <= '1';
          i_fdev_wr <= '0';
          i_fdev_done <= '1';
--          fsm_state_cs <= S2_HBUFR_IDLE;--for case TXACK OFF
          fsm_state_cs <= S2_HBUFW_TxH;
        else
          i_fdev_wr <= '1';
          i_chnkcnt <= i_chnkcnt + 1;
          i_pkt_dcnt <= i_pkt_dcnt + 1;
        end if;

      else
        i_fdev_wr <= '0';
      end if;

      for i in 0 to CI_CHUNK_COUNT - 1 loop
        if i_chnkcnt = i then
          i_fdev_txd <= UNSIGNED(i_hbufr_do((i_fdev_txd'length * (i + 1)) - 1
                                           downto (i_fdev_txd'length * i)));
        end if;
      end loop;

    --write packet header to host buf
    when S2_HBUFW_TxH =>

      i_fdev_radr_ld <= '0';
      i_fdev_done <= '0';
      i_hbufr_clr <= '0';

      if i_hbufw_full = '0' then
        if i_pkt_dcnt(1 downto 0) = TO_UNSIGNED(i_pkth'length - 1, 2) then
          if pkth(CI_CFGPKTH_CTRL_CHNK)(C_CFGPKT_WR_BIT) = C_CFGPKT_WR then
            i_chnkcnt <= (others => '0');
            i_pkt_dcnt <= (others => '0');
            i_hbufw_wr <= '1';
            fsm_state_cs <= S2_HBUFR_IDLE;
          else
            if p_in_cfg_rxbuf_empty = '0' then
              i_chnkcnt <= i_chnkcnt + 1;
              i_pkt_dcnt <= (others => '0');
              i_hbufw_wr <= OR_reduce(i_chnkcnt);
              i_fdev_rd <= '1';
              fsm_state_cs <= S2_HBUFW_TxD;
            else
              i_hbufw_wr <= '0';
            end if;
          end if;
        else
          i_chnkcnt <= i_chnkcnt + 1;
          i_pkt_dcnt <= i_pkt_dcnt + 1;
          i_hbufw_wr <= OR_reduce(i_chnkcnt);
        end if;
      else
        i_hbufw_wr <= '0';
      end if;

      for i in 0 to CI_CHUNK_COUNT - 1 loop
        if i_chnkcnt = i then
          for y in 0 to i_pkth'length - 1 loop
            if i_pkt_dcnt(2 downto 0) = y then
              i_hbufw_di((pkth(y)'length * (i + 1)) - 1
                              downto (pkth(y)'length * i)) <= std_logic_vector(i_pkth(y));
            end if;
          end loop;
        end if;
      end loop;

    --read data from cfg devices and write it to host buf
    when S2_HBUFW_TxD =>

      if i_hbufw_full = '0' and p_in_cfg_rxbuf_empty = '0' then

        if i_pkt_dcnt = i_pkth(CI_CFGPKTH_DLEN_CHNK) - 1 then
          i_chnkcnt <= (others => '0');
          i_pkt_dcnt <= (others => '0');
          i_fdev_rd <= '0';
          i_hbufw_wr <= '1'; i_fdev_done <= '1';
          fsm_state_cs <= S2_HBUFR_IDLE;
        else
          i_chnkcnt <= i_chnkcnt + 1;
          i_pkt_dcnt <= i_pkt_dcnt + 1;
          i_hbufw_wr <= OR_reduce(i_chnkcnt);
        end if;
      else
        i_hbufw_wr <= '0';
      end if;

      for i in 0 to CI_CHUNK_COUNT - 1 loop
        if i_chnkcnt = i then
          i_hbufw_di((p_in_cfg_rxdata'length * (i + 1)) - 1
                          downto (p_in_cfg_rxdata'length * i)) <= p_in_cfg_rxdata;
        end if;
      end loop;

  end case;

end if;
end process;


end architecture behav1;