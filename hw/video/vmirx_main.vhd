-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.10.2014 12:01:38
-- Module Name : vmirx_main
--
-- Назначение/Описание :
--  Модуль реализует отзеркаливание строки видео инфомации по оси X
--
-- Revision:
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;

entity vmirx_main is
generic(
G_BRAM_SIZE_BYTE : integer := 8;
G_PIX_SIZE : integer := 8;--value 8, 16
G_DI_WIDTH : integer := 8;--value 8, 16, 32 ...
G_DO_WIDTH : integer := 8 --value 8, 16, 32 ...
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_mirx       : in    std_logic;                    --1/0 - mirx ON/OFF
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);--Count byte
p_in_cfg_skp_count  : in    std_logic_vector(15 downto 0);--Count byte
p_in_cfg_act_count  : in    std_logic_vector(15 downto 0);--Count byte
p_out_busy          : out   std_logic;

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data       : in    std_logic_vector(G_DI_WIDTH - 1 downto 0);
p_in_upp_wr         : in    std_logic;
p_out_upp_rdy_n     : out   std_logic;
p_in_upp_eof        : in    std_logic;
p_in_upp_clk        : in    std_logic;

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data     : out   std_logic_vector(G_DO_WIDTH - 1 downto 0);
p_out_dwnp_wr       : out   std_logic;
p_in_dwnp_rdy_n     : in    std_logic;
p_out_dwnp_eof      : out   std_logic;
p_out_dwnp_eol      : out   std_logic;
p_in_dwnp_clk       : in    std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst            : in    std_logic
);
end entity vmirx_main;

architecture behavioral_1 of vmirx_main is

constant dly : time := 1 ps;

component bram_mirx
port(
addra: in  std_logic_vector(log2(G_BRAM_SIZE_BYTE / (G_DI_WIDTH / 8)) - 1 downto 0);
dina : in  std_logic_vector(G_DI_WIDTH - 1 downto 0);
douta: out std_logic_vector(G_DI_WIDTH - 1 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

addrb: in  std_logic_vector(log2(G_BRAM_SIZE_BYTE / (G_DO_WIDTH / 8)) - 1 downto 0);
dinb : in  std_logic_vector(G_DO_WIDTH - 1 downto 0);
doutb: out std_logic_vector(G_DO_WIDTH - 1 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component bram_mirx;

type TDin is array (0 to (p_in_upp_data'length / p_out_dwnp_data'length) - 1)
                                             of std_logic_vector(p_out_dwnp_data'range);
signal i_upp_data        : TDin;
signal i_upp_pix_swap    : TDin;

type TFsm_state is (
S_BUF_WR,
S_BUF_RD,
S_BUF_RD_EOF
);
signal i_fsm_cs          : TFsm_state;

signal i_pix_count_wr_tmp: unsigned(p_in_cfg_pix_count'range);
signal i_pix_count_wr    : unsigned(p_in_cfg_pix_count'range);
signal i_pix_count_rd_tmp: unsigned(p_in_cfg_pix_count'range);
signal i_pix_count_rd    : unsigned(p_in_cfg_pix_count'range);

signal i_buf_adr         : unsigned(log2(G_BRAM_SIZE_BYTE) - 1 downto 0);
signal i_buf_adr_rd      : unsigned(log2(G_BRAM_SIZE_BYTE) - 1 downto 0);
signal i_buf_adr_rd_t    : unsigned(log2(G_BRAM_SIZE_BYTE) - 1 downto 0);
signal i_buf_di          : std_logic_vector(p_in_upp_data'range);
signal i_buf_do          : std_logic_vector(p_out_dwnp_data'range);
signal i_buf_ena         : std_logic;
signal i_buf_enb         : std_logic;
signal i_read_en         : std_logic;

signal i_gnd             : std_logic_vector(max2(G_DI_WIDTH, G_DO_WIDTH) - 1 downto 0);


begin --architecture behavioral_1

i_gnd <= (others => '0');


p_out_upp_rdy_n <= i_read_en;

p_out_dwnp_data <= i_buf_do;
p_out_dwnp_wr <= not p_in_dwnp_rdy_n and i_read_en;
p_out_dwnp_eof <= not p_in_dwnp_rdy_n and i_read_en and p_in_upp_eof when i_fsm_cs = S_BUF_RD_EOF else '0';
p_out_dwnp_eol <= not p_in_dwnp_rdy_n and i_read_en when i_fsm_cs = S_BUF_RD_EOF else '0';

gen_in_1 : if p_in_upp_data'length > 8 and p_out_dwnp_data'length > 8 generate begin
i_pix_count_wr_tmp <= (UNSIGNED(p_in_cfg_pix_count(p_in_cfg_pix_count'high downto log2(G_DI_WIDTH / 8)))
                          & TO_UNSIGNED(0, log2(G_DI_WIDTH / 8)))

                       + (TO_UNSIGNED(0, i_pix_count_wr'length - 2)
                            & OR_reduce(p_in_cfg_pix_count(log2(G_DI_WIDTH / 8) - 1 downto 0)));

i_pix_count_wr <= i_pix_count_wr_tmp - (p_in_upp_data'length / 8);

i_pix_count_rd_tmp <= (UNSIGNED(p_in_cfg_pix_count(p_in_cfg_pix_count'high downto log2(G_DO_WIDTH / 8)))
                          & TO_UNSIGNED(0, log2(G_DO_WIDTH / 8)))

                       + (TO_UNSIGNED(0, i_pix_count_rd_tmp'length - 2)
                            & OR_reduce(p_in_cfg_pix_count(log2(G_DO_WIDTH / 8) - 1 downto 0)));

i_pix_count_rd <= i_pix_count_rd_tmp - (p_out_dwnp_data'length / 8);
end generate gen_in_1;

gen_in_2 : if (p_in_upp_data'length = p_out_dwnp_data'length) and p_out_dwnp_data'length = 8 generate begin
i_pix_count_wr <= UNSIGNED(p_in_cfg_pix_count) - 1;
i_pix_count_rd <= i_pix_count_wr;
end generate gen_in_2;

gen_in_3 : if p_in_upp_data'length > 8 and p_out_dwnp_data'length = 8 generate begin
i_pix_count_wr_tmp <= (UNSIGNED(p_in_cfg_pix_count(p_in_cfg_pix_count'high downto log2(G_DI_WIDTH / 8)))
                          & TO_UNSIGNED(0, log2(G_DI_WIDTH / 8)))

                       + (TO_UNSIGNED(0, i_pix_count_wr'length - 2)
                            & OR_reduce(p_in_cfg_pix_count(log2(G_DI_WIDTH / 8) - 1 downto 0)));

i_pix_count_wr <= i_pix_count_wr_tmp - (p_in_upp_data'length / 8);

i_pix_count_rd <= UNSIGNED(p_in_cfg_pix_count) - 1;
end generate gen_in_3;


--------------------------------------
--
--------------------------------------
process(p_in_upp_clk)
begin
if rising_edge(p_in_upp_clk) then
  if p_in_rst = '1' then

    i_fsm_cs <= S_BUF_WR;
    i_buf_adr <= (others => '0');
    i_read_en <= '0';

  else

    case i_fsm_cs is

      --------------------------------------
      --
      --------------------------------------
      when S_BUF_WR =>

        if p_in_upp_wr = '1' then
          if RESIZE(i_buf_adr, i_pix_count_wr'length) = i_pix_count_wr then
            i_buf_adr <= (others => '0');
            i_fsm_cs <= S_BUF_RD;
          else
            i_buf_adr <= i_buf_adr + (p_in_upp_data'length / 8);
          end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_BUF_RD =>

        if p_in_dwnp_rdy_n = '0' then

            i_read_en <= '1';

            if RESIZE(i_buf_adr, i_pix_count_rd'length) = i_pix_count_rd then
              i_buf_adr <= (others => '0');
              i_fsm_cs <= S_BUF_RD_EOF;
            else
              i_buf_adr <= i_buf_adr + (p_out_dwnp_data'length / 8);
            end if;

        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_BUF_RD_EOF =>

        if p_in_dwnp_rdy_n = '0' then
          i_read_en <= '0';
          i_fsm_cs <= S_BUF_WR;
        end if;

    end case;

  end if;
end if;
end process;


gen_buf_din : for i in 0 to p_in_upp_data'length / p_out_dwnp_data'length - 1 generate begin
i_upp_data(i) <= p_in_upp_data((p_out_dwnp_data'length * (i + 1) - 1) downto (p_out_dwnp_data'length * i));

gen_pix_swap : for y in 0 to i_upp_data(i)'length / G_PIX_SIZE - 1 generate begin
i_upp_pix_swap(i)((i_upp_pix_swap(i)'length - (G_PIX_SIZE * y)) - 1 downto
                (i_upp_pix_swap(i)'length - (G_PIX_SIZE * (y + 1))))

                  <= i_upp_data(i)((G_PIX_SIZE * (y + 1) - 1) downto (G_PIX_SIZE * y));
end generate gen_pix_swap;

i_buf_di((p_out_dwnp_data'length * (i + 1) - 1)
            downto (p_out_dwnp_data'length * i)) <= i_upp_data(i) when p_in_cfg_mirx = '0' else i_upp_pix_swap(i);

end generate gen_buf_din;

i_buf_ena <= not i_read_en and p_in_upp_wr;

i_buf_enb <= not p_in_dwnp_rdy_n;

i_buf_adr_rd_t <= RESIZE(UNSIGNED(p_in_cfg_pix_count), i_buf_adr_rd_t'length) - (p_out_dwnp_data'length / 8);
i_buf_adr_rd <= i_buf_adr when p_in_cfg_mirx = '0' else i_buf_adr_rd_t - i_buf_adr;

m_buf : bram_mirx
port map(
addra => std_logic_vector(i_buf_adr(log2(G_BRAM_SIZE_BYTE) - 1
                                                    downto log2(p_in_upp_data'length / 8))),
dina  => i_buf_di,
douta => open,
ena   => i_buf_ena,
wea   => "1",
clka  => p_in_upp_clk,
rsta  => p_in_rst,

addrb => std_logic_vector(i_buf_adr_rd(log2(G_BRAM_SIZE_BYTE) - 1 downto log2(p_out_dwnp_data'length / 8))),
dinb  => i_gnd(p_out_dwnp_data'range),
doutb => i_buf_do,
enb   => i_buf_enb,
web   => "0",
clkb  => p_in_upp_clk,
rstb  => p_in_rst
);


--##################################
--DBG
--##################################
p_out_tst(0) <= '0';
p_out_tst(31 downto 1) <= (others => '0');

end architecture behavioral_1;


architecture behavioral_2 of vmirx_main is

constant dly : time := 1 ps;

component sim_bram32x8bit --bram_mirx
port(
addra: in  std_logic_vector(log2(G_BRAM_SIZE_BYTE / (G_DI_WIDTH / 8)) - 1 downto 0);
dina : in  std_logic_vector(G_DI_WIDTH - 1 downto 0);
douta: out std_logic_vector(G_DI_WIDTH - 1 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

addrb: in  std_logic_vector(log2(G_BRAM_SIZE_BYTE / (G_DO_WIDTH / 8)) - 1 downto 0);
dinb : in  std_logic_vector(G_DO_WIDTH - 1 downto 0);
doutb: out std_logic_vector(G_DO_WIDTH - 1 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component;-- bram_mirx;

type TDin is array (0 to (p_in_upp_data'length / p_out_dwnp_data'length) - 1)
                                             of std_logic_vector(p_out_dwnp_data'range);
signal i_upp_data        : TDin;
signal i_upp_pix_swap    : TDin;

type TFsmWR_state is (
SWR_BUF_WR,
SWR_WAIT_DONE
);
signal i_fsmwr_cs        : TFsmWR_state;

type TFsmRD_state is (
SRD_WAIT_RD,
SRD_BUF_RD,
SRD_BUF_RD_EOF
);
signal i_fsmrd_cs        : TFsmRD_state;

signal i_pix_count_wr_tmp: unsigned(p_in_cfg_pix_count'range);
signal i_pix_count_wr    : unsigned(p_in_cfg_pix_count'range);
signal i_pix_count_rd_tmp: unsigned(p_in_cfg_pix_count'range);
signal i_pix_count_rd    : unsigned(p_in_cfg_pix_count'range);

signal i_wbuf_adr        : unsigned(log2(G_BRAM_SIZE_BYTE) - 1 downto 0);
signal i_rbuf_adr        : unsigned(log2(G_BRAM_SIZE_BYTE) - 1 downto 0);
signal i_rbuf_adrb       : unsigned(log2(G_BRAM_SIZE_BYTE) - 1 downto 0);
signal i_rbuf_adrb_t     : unsigned(log2(G_BRAM_SIZE_BYTE) - 1 downto 0);
signal i_buf_di          : std_logic_vector(p_in_upp_data'range);
signal i_buf_do          : std_logic_vector(p_out_dwnp_data'range);
signal i_buf_ena         : std_logic;
signal i_buf_enb         : std_logic;
signal i_read_en         : std_logic;

signal i_gnd             : std_logic_vector(max2(G_DI_WIDTH, G_DO_WIDTH) - 1 downto 0);

signal i_rd_start        : std_logic;
signal i_rd_start_dwclk  : std_logic;
signal i_rd_done_upclk   : std_logic;
signal i_rd_done         : std_logic;
signal sr_rd_done        : std_logic_vector(0 to 2);
signal i_busy            : std_logic;
signal i_act_en          : std_logic;
signal i_skp_count       : unsigned(p_in_cfg_skp_count'range);
signal i_act_count       : unsigned(p_in_cfg_act_count'range);

begin --architecture behavioral_2

i_gnd <= (others => '0');


p_out_upp_rdy_n <= i_read_en;

p_out_busy <= i_busy;

p_out_dwnp_data <= i_buf_do;
p_out_dwnp_wr <= not p_in_dwnp_rdy_n and i_act_en;
p_out_dwnp_eof <= not p_in_dwnp_rdy_n and i_act_en and p_in_upp_eof
                    when RESIZE(i_rbuf_adr, i_act_count'length) = (i_skp_count + i_act_count) else '0';

p_out_dwnp_eol <= not p_in_dwnp_rdy_n and i_act_en
                    when RESIZE(i_rbuf_adr, i_act_count'length) = (i_skp_count + i_act_count) else '0';

gen_in_1 : if p_in_upp_data'length > 8 and p_out_dwnp_data'length > 8 generate begin
i_pix_count_wr_tmp <= (UNSIGNED(p_in_cfg_pix_count(p_in_cfg_pix_count'high downto log2(G_DI_WIDTH / 8)))
                          & TO_UNSIGNED(0, log2(G_DI_WIDTH / 8)))

                       + (TO_UNSIGNED(0, i_pix_count_wr'length - 2)
                            & OR_reduce(p_in_cfg_pix_count(log2(G_DI_WIDTH / 8) - 1 downto 0)));

i_pix_count_wr <= i_pix_count_wr_tmp - (p_in_upp_data'length / 8);

i_pix_count_rd_tmp <= (UNSIGNED(p_in_cfg_pix_count(p_in_cfg_pix_count'high downto log2(G_DO_WIDTH / 8)))
                          & TO_UNSIGNED(0, log2(G_DO_WIDTH / 8)))

                       + (TO_UNSIGNED(0, i_pix_count_rd_tmp'length - 2)
                            & OR_reduce(p_in_cfg_pix_count(log2(G_DO_WIDTH / 8) - 1 downto 0)));

i_pix_count_rd <= i_pix_count_rd_tmp - (p_out_dwnp_data'length / 8);
end generate gen_in_1;

gen_in_2 : if (p_in_upp_data'length = p_out_dwnp_data'length) and p_out_dwnp_data'length = 8 generate begin
i_pix_count_wr <= UNSIGNED(p_in_cfg_pix_count) - 1;
i_pix_count_rd <= i_pix_count_wr;
end generate gen_in_2;

gen_in_3 : if p_in_upp_data'length > 8 and p_out_dwnp_data'length = 8 generate begin
i_pix_count_wr_tmp <= (UNSIGNED(p_in_cfg_pix_count(p_in_cfg_pix_count'high downto log2(G_DI_WIDTH / 8)))
                          & TO_UNSIGNED(0, log2(G_DI_WIDTH / 8)))

                       + (TO_UNSIGNED(0, i_pix_count_wr'length - 2)
                            & OR_reduce(p_in_cfg_pix_count(log2(G_DI_WIDTH / 8) - 1 downto 0)));

i_pix_count_wr <= i_pix_count_wr_tmp - (p_in_upp_data'length / 8);

i_pix_count_rd <= UNSIGNED(p_in_cfg_pix_count) - 1;
end generate gen_in_3;

--------------------------------------
--FSM/WRITE
--------------------------------------
process(p_in_upp_clk)
begin
if rising_edge(p_in_upp_clk) then
  if p_in_rst = '1' then

    i_fsmwr_cs <= SWR_BUF_WR;
    i_wbuf_adr <= (others => '0');
    i_rd_start <= '0';
    i_rd_done_upclk <= '0';
    i_busy <= '0';

  else
    i_rd_done_upclk <= OR_reduce(sr_rd_done);

    case i_fsmwr_cs is

      when SWR_BUF_WR =>

        if p_in_upp_wr = '1' then

          if RESIZE(i_wbuf_adr, i_pix_count_wr'length) = i_pix_count_wr then
            i_wbuf_adr <= (others => '0');
            i_busy <= '1';
            i_rd_start <= '1';
            i_fsmwr_cs <= SWR_WAIT_DONE;
          else
            i_wbuf_adr <= i_wbuf_adr + (p_in_upp_data'length / 8);
          end if;
        end if;

      when SWR_WAIT_DONE =>

        i_rd_start <= '0';

        if i_rd_done_upclk = '1' then
          i_busy <= '0';
          i_fsmwr_cs <= SWR_BUF_WR;
        end if;

    end case;
  end if;
end if;
end process;


--------------------------------------
--FSM/READ
--------------------------------------
i_skp_count <= UNSIGNED(p_in_cfg_skp_count) when p_in_cfg_mirx = '0' else
               UNSIGNED(p_in_cfg_pix_count) - (UNSIGNED(p_in_cfg_act_count) + UNSIGNED(p_in_cfg_skp_count));

i_act_count <= UNSIGNED(p_in_cfg_act_count) + UNSIGNED(p_in_cfg_skp_count) when p_in_cfg_mirx = '0' else
               UNSIGNED(p_in_cfg_act_count);

process(p_in_dwnp_clk)
begin
if rising_edge(p_in_dwnp_clk) then
  if p_in_rst = '1' then

    i_fsmrd_cs <= SRD_WAIT_RD;
    i_rbuf_adr <= (others => '0');
    i_read_en <= '0'; i_act_en <= '0';
    i_rd_done <= '0';
    sr_rd_done <= (others => '0');

  else

    i_rd_start_dwclk <= i_rd_start;
    sr_rd_done <= i_rd_done & sr_rd_done(0 to 1);

    case i_fsmrd_cs is

      when SRD_WAIT_RD =>

        i_rd_done <= '0';

        if i_rd_start_dwclk = '1' then
          i_fsmrd_cs <= SRD_BUF_RD;
        end if;

      when SRD_BUF_RD =>

        if p_in_dwnp_rdy_n = '0' then

            i_read_en <= '1';

            if RESIZE(i_rbuf_adr, i_pix_count_rd'length) = i_pix_count_rd then
              i_fsmrd_cs <= SRD_BUF_RD_EOF;
            end if;

            i_rbuf_adr <= i_rbuf_adr + (p_out_dwnp_data'length / 8);


            if RESIZE(i_rbuf_adr, i_skp_count'length) = i_skp_count then
              i_act_en <= '1';
            elsif RESIZE(i_rbuf_adr, i_act_count'length) = (i_skp_count + i_act_count) then
              i_act_en <= '0';
            end if;

        end if;

      when SRD_BUF_RD_EOF =>

        if p_in_dwnp_rdy_n = '0' then
          i_rbuf_adr <= (others => '0');
          i_read_en <= '0'; i_act_en <= '0';
          i_rd_done <= '1';
          i_fsmrd_cs <= SRD_WAIT_RD;
        end if;

    end case;

  end if;
end if;
end process;


--------------------------------------
--BUF
--------------------------------------
genw_buf_din : for i in 0 to p_in_upp_data'length / p_out_dwnp_data'length - 1 generate begin
i_upp_data(i) <= p_in_upp_data((p_out_dwnp_data'length * (i + 1) - 1) downto (p_out_dwnp_data'length * i));

genw_pix_swap : for y in 0 to i_upp_data(i)'length / G_PIX_SIZE - 1 generate begin
i_upp_pix_swap(i)((i_upp_pix_swap(i)'length - (G_PIX_SIZE * y)) - 1 downto
                (i_upp_pix_swap(i)'length - (G_PIX_SIZE * (y + 1))))

                  <= i_upp_data(i)((G_PIX_SIZE * (y + 1) - 1) downto (G_PIX_SIZE * y));
end generate genw_pix_swap;

i_buf_di((p_out_dwnp_data'length * (i + 1) - 1)
            downto (p_out_dwnp_data'length * i)) <= i_upp_data(i) when p_in_cfg_mirx = '0' else i_upp_pix_swap(i);

end generate genw_buf_din;

m_buf : sim_bram32x8bit --bram_mirx
port map(
addra => std_logic_vector(i_wbuf_adr(log2(G_BRAM_SIZE_BYTE) - 1
                                                    downto log2(p_in_upp_data'length / 8))),
dina  => i_buf_di,
douta => open,
ena   => p_in_upp_wr,
wea   => "1",
clka  => p_in_upp_clk,
rsta  => p_in_rst,

addrb => std_logic_vector(i_rbuf_adrb(log2(G_BRAM_SIZE_BYTE) - 1 downto log2(p_out_dwnp_data'length / 8))),
dinb  => i_gnd(p_out_dwnp_data'range),
doutb => i_buf_do,
enb   => i_buf_enb,
web   => "0",
clkb  => p_in_dwnp_clk,
rstb  => p_in_rst
);

i_buf_enb <= not p_in_dwnp_rdy_n;

i_rbuf_adrb_t <= RESIZE(UNSIGNED(p_in_cfg_pix_count), i_rbuf_adrb_t'length) - (p_out_dwnp_data'length / 8);
i_rbuf_adrb <= i_rbuf_adr when p_in_cfg_mirx = '0' else i_rbuf_adrb_t - i_rbuf_adr;


--##################################
--DBG
--##################################
p_out_tst(0) <= '0';
p_out_tst(31 downto 1) <= (others => '0');

end architecture behavioral_2;