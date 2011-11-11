--
-- memory_ctrl.vhd - Memory banks for ADM-XRC-5T1
--
-- (C) Copyright Alpha Data 2005-2007
--
-- SYNTHESIZABLE
--
-- Targets models:
--
--   o ADM-XRC-5T1
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.memif.all;
use work.memory_ctrl_pkg.all;

-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
-- synopsys translate_on

entity memory_ctrl is
  generic
  (
    G_BANK_COUNT  : in    integer;

    bank0         : in    bank_t;
    bank1         : in    bank_t;
    bank2         : in    bank_t;
    bank3         : in    bank_t;
    bank4         : in    bank_t;
    bank5         : in    bank_t;
    bank6         : in    bank_t;
    bank7         : in    bank_t;
    bank8         : in    bank_t;
    bank9         : in    bank_t;
    bank10        : in    bank_t;
    bank11        : in    bank_t;
    bank12        : in    bank_t;
    bank13        : in    bank_t;
    bank14        : in    bank_t;
    bank15        : in    bank_t;
    num_ramclk    : in    natural
  );
  port
  (
    -----------------------------
    --System
    -----------------------------
    rst           : in    std_logic;

    memclk0       : in    std_logic;
    memclk45      : in    std_logic;
    memclk2x0     : in    std_logic;
    memclk2x90    : in    std_logic;
    memrst        : in    std_logic;

    -----------------------------
    -- Configuration
    -----------------------------
    bank_reg      : in    std_logic_vector(3 downto 0);
    mode_reg      : in    std_logic_vector(511 downto 0);
--    locked        : out   std_logic_vector(7 downto 0);
    trained       : out   std_logic_vector(15 downto 0);

    -----------------------------
    -- User channel 0
    -----------------------------
    usr0_clk      : in    std_logic;
    --Управление
    usr0_bank1h   : in    std_logic_vector(15 downto 0);
    usr0_ce       : in    std_logic;
    usr0_cw       : in    std_logic;
    usr0_term     : in    std_logic;
    usr0_rd       : in    std_logic;
    usr0_wr       : in    std_logic;
    usr0_adr      : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
    usr0_be       : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
    usr0_din      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
    usr0_dout     : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
    --TX/RXBUF STATUS
    usr0_wf       : out   std_logic;
    usr0_wpf      : out   std_logic;
    usr0_re       : out   std_logic;
    usr0_rpe      : out   std_logic;

--    -----------------------------
--    -- User channel 1
--    -----------------------------
--    usr1_clk      : in    std_logic;
--    --Управление
--    usr1_bank1h   : in    std_logic_vector(15 downto 0);
--    usr1_ce       : in    std_logic;
--    usr1_cw       : in    std_logic;
--    usr1_term     : in    std_logic;
--    usr1_rd       : in    std_logic;
--    usr1_wr       : in    std_logic;
--    usr1_adr      : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
--    usr1_be       : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
--    usr1_din      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
--    usr1_dout     : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
--    --TX/RXBUF STATUS
--    usr1_wf       : out   std_logic;
--    usr1_wpf      : out   std_logic;
--    usr1_re       : out   std_logic;
--    usr1_rpe      : out   std_logic;

    -----------------------------
    -- To/from FPGA memory pins
    -----------------------------
    ra0           : out   std_logic_vector(bank0.ra_width - 1 downto 0);
    rc0           : inout std_logic_vector(bank0.rc_width - 1 downto 0);
    rd0           : inout std_logic_vector(bank0.rd_width - 1 downto 0);
    ra1           : out   std_logic_vector(bank1.ra_width - 1 downto 0);
    rc1           : inout std_logic_vector(bank1.rc_width - 1 downto 0);
    rd1           : inout std_logic_vector(bank1.rd_width - 1 downto 0);
    ra2           : out   std_logic_vector(bank2.ra_width - 1 downto 0);
    rc2           : inout std_logic_vector(bank2.rc_width - 1 downto 0);
    rd2           : inout std_logic_vector(bank2.rd_width - 1 downto 0);
    ra3           : out   std_logic_vector(bank3.ra_width - 1 downto 0);
    rc3           : inout std_logic_vector(bank3.rc_width - 1 downto 0);
    rd3           : inout std_logic_vector(bank3.rd_width - 1 downto 0);
    ra4           : out   std_logic_vector(bank4.ra_width - 1 downto 0);
    rc4           : inout std_logic_vector(bank4.rc_width - 1 downto 0);
    rd4           : inout std_logic_vector(bank4.rd_width - 1 downto 0);
    ra5           : out   std_logic_vector(bank5.ra_width - 1 downto 0);
    rc5           : inout std_logic_vector(bank5.rc_width - 1 downto 0);
    rd5           : inout std_logic_vector(bank5.rd_width - 1 downto 0);
    ra6           : out   std_logic_vector(bank6.ra_width - 1 downto 0);
    rc6           : inout std_logic_vector(bank6.rc_width - 1 downto 0);
    rd6           : inout std_logic_vector(bank6.rd_width - 1 downto 0);
    ra7           : out   std_logic_vector(bank7.ra_width - 1 downto 0);
    rc7           : inout std_logic_vector(bank7.rc_width - 1 downto 0);
    rd7           : inout std_logic_vector(bank7.rd_width - 1 downto 0);
    ra8           : out   std_logic_vector(bank8.ra_width - 1 downto 0);
    rc8           : inout std_logic_vector(bank8.rc_width - 1 downto 0);
    rd8           : inout std_logic_vector(bank8.rd_width - 1 downto 0);
    ra9           : out   std_logic_vector(bank9.ra_width - 1 downto 0);
    rc9           : inout std_logic_vector(bank9.rc_width - 1 downto 0);
    rd9           : inout std_logic_vector(bank9.rd_width - 1 downto 0);
    ra10          : out   std_logic_vector(bank10.ra_width - 1 downto 0);
    rc10          : inout std_logic_vector(bank10.rc_width - 1 downto 0);
    rd10          : inout std_logic_vector(bank10.rd_width - 1 downto 0);
    ra11          : out   std_logic_vector(bank11.ra_width - 1 downto 0);
    rc11          : inout std_logic_vector(bank11.rc_width - 1 downto 0);
    rd11          : inout std_logic_vector(bank11.rd_width - 1 downto 0);
    ra12          : out   std_logic_vector(bank12.ra_width - 1 downto 0);
    rc12          : inout std_logic_vector(bank12.rc_width - 1 downto 0);
    rd12          : inout std_logic_vector(bank12.rd_width - 1 downto 0);
    ra13          : out   std_logic_vector(bank13.ra_width - 1 downto 0);
    rc13          : inout std_logic_vector(bank13.rc_width - 1 downto 0);
    rd13          : inout std_logic_vector(bank13.rd_width - 1 downto 0);
    ra14          : out   std_logic_vector(bank14.ra_width - 1 downto 0);
    rc14          : inout std_logic_vector(bank14.rc_width - 1 downto 0);
    rd14          : inout std_logic_vector(bank14.rd_width - 1 downto 0);
    ra15          : out   std_logic_vector(bank15.ra_width - 1 downto 0);
    rc15          : inout std_logic_vector(bank15.rc_width - 1 downto 0);
    rd15          : inout std_logic_vector(bank15.rd_width - 1 downto 0);
    ramclki       : in    std_logic_vector(num_ramclk - 1 downto 0);
    ramclko       : out   std_logic_vector(num_ramclk - 1 downto 0)
  );
end entity;

architecture mixed of memory_ctrl is

    constant num_bank_dram        : natural := selval(1, 2, cmpval(1, G_BANK_COUNT));--2;
    constant num_bank_sram        : natural := 1;
    constant num_bank             : natural := num_bank_dram;-- + num_bank_sram;

    constant mux_order_dram       : natural := 2;--//32BIT
--    constant mux_order_dram       : natural := 1;--//64BIT
    constant port_width_dram      : natural := 128;
    constant port_be_width_dram   : natural := port_width_dram / 8;
    constant port_addr_width_dram : natural := C_MEMCTRL_ADDR_WIDTH - mux_order_dram;

    constant mux_order_sram       : natural := 1;--//32BIT
--    constant mux_order_sram       : natural := 0;--//64BIT
    constant port_width_sram      : natural := 64;
    constant port_be_width_sram   : natural := port_width_sram / 8;
    constant port_addr_width_sram : natural := C_MEMCTRL_ADDR_WIDTH - mux_order_sram;

    signal logic0, logic1  : std_logic;

    signal usr0_cew        : std_logic;
    signal usr1_cew        : std_logic;

    signal rep0_be_DRAM    : std_logic_vector(port_be_width_dram - 1 downto 0);
    signal rep0_d_DRAM     : std_logic_vector(port_width_dram - 1 downto 0);
    signal rep0_valid_DRAM : std_logic;
    signal rep0_final_DRAM : std_logic;

    signal rep0_be_SRAM    : std_logic_vector(port_be_width_sram - 1 downto 0);
    signal rep0_d_SRAM     : std_logic_vector(port_width_sram - 1 downto 0);
    signal rep0_valid_SRAM : std_logic;
    signal rep0_final_SRAM : std_logic;

    signal rep1_be_DRAM    : std_logic_vector(port_be_width_dram - 1 downto 0);
    signal rep1_d_dram     : std_logic_vector(port_width_dram - 1 downto 0);
    signal rep1_valid_DRAM : std_logic;
    signal rep1_final_DRAM : std_logic;

    signal rep1_be_SRAM    : std_logic_vector(port_be_width_sram - 1 downto 0);
    signal rep1_d_SRAM     : std_logic_vector(port_width_sram - 1 downto 0);
    signal rep1_valid_SRAM : std_logic;
    signal rep1_final_SRAM : std_logic;


    constant tag_width     : natural := 2;
    subtype tag_t is std_logic_vector(tag_width - 1 downto 0);
    type tag_vector_t is array(natural range <>) of tag_t;

    signal usr0_tag_base   : std_logic_vector(tag_width - 1 downto 0);
    signal usr0_tag_mask   : std_logic_vector(tag_width - 1 downto 0);

    signal usr1_tag_base   : std_logic_vector(tag_width - 1 downto 0);
    signal usr1_tag_mask   : std_logic_vector(tag_width - 1 downto 0);

    signal port0_pce       : std_logic_vector(num_bank - 1 downto 0);
    signal port0_pcw       : std_logic_vector(num_bank - 1 downto 0);
    signal port0_pterm     : std_logic_vector(num_bank - 1 downto 0);
    signal port0_padv      : std_logic_vector(num_bank - 1 downto 0);
    signal port0_pwr       : std_logic_vector(num_bank - 1 downto 0);
    signal port0_pwf       : std_logic_vector(num_bank - 1 downto 0);
    signal port0_pwpf      : std_logic_vector(num_bank - 1 downto 0);
    signal port0_pre       : std_logic_vector(num_bank - 1 downto 0);
    signal port0_prpe      : std_logic_vector(num_bank - 1 downto 0);

    signal port1_pce       : std_logic_vector(num_bank - 1 downto 0);
    signal port1_pcw       : std_logic_vector(num_bank - 1 downto 0);
    signal port1_pterm     : std_logic_vector(num_bank - 1 downto 0);
    signal port1_padv      : std_logic_vector(num_bank - 1 downto 0);
    signal port1_pwr       : std_logic_vector(num_bank - 1 downto 0);
    signal port1_pwf       : std_logic_vector(num_bank - 1 downto 0);
    signal port1_pwpf      : std_logic_vector(num_bank - 1 downto 0);
    signal port1_pre       : std_logic_vector(num_bank - 1 downto 0);
    signal port1_prpe      : std_logic_vector(num_bank - 1 downto 0);


    type port_pq_dram_t is array(0 to num_bank_dram - 1) of std_logic_vector(port_width_dram - 1 downto 0);
    signal port0_pq_DRAM       : port_pq_dram_t;
    signal port0_plast_DRAM    : std_logic;
    signal port0_pq_muxed_DRAM : std_logic_vector(port_width_dram - 1 downto 0);
    signal usr0_dout_DRAM      : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

    signal port1_pq_DRAM       : port_pq_dram_t;
    signal port1_plast_DRAM    : std_logic;
    signal port1_pq_muxed_DRAM : std_logic_vector(port_width_dram - 1 downto 0);
    signal usr1_dout_DRAM      : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);


    type port_pq_sram_t is array(0 to num_bank_sram - 1) of std_logic_vector(port_width_sram - 1 downto 0);
    signal port0_pq_SRAM       : port_pq_sram_t;
    signal port0_plast_SRAM    : std_logic;
    signal port0_pq_muxed_SRAM : std_logic_vector(port_width_sram - 1 downto 0);
    signal usr0_dout_SRAM      : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

    signal port1_pq_SRAM       : port_pq_sram_t;
    signal port1_plast_SRAM    : std_logic;
    signal port1_pq_muxed_SRAM : std_logic_vector(port_width_sram - 1 downto 0);
    signal usr1_dout_SRAM      : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);


    type port_stag_t is array(0 to num_bank - 1) of std_logic_vector(tag_width - 1 downto 0);
    signal port0_sce    : std_logic_vector(num_bank - 1 downto 0);
    signal port0_sw     : std_logic_vector(num_bank - 1 downto 0);
    signal port0_stag   : port_stag_t;
    signal port0_sqtag  : port_stag_t;
    signal port0_svalid : std_logic_vector(num_bank - 1 downto 0);
    signal port0_sready : std_logic_vector(num_bank - 1 downto 0);
    signal port0_sreq   : std_logic_vector(num_bank - 1 downto 0);

    signal port1_sce    : std_logic_vector(num_bank - 1 downto 0);
    signal port1_sw     : std_logic_vector(num_bank - 1 downto 0);
    signal port1_stag   : port_stag_t;
    signal port1_sqtag  : port_stag_t;
    signal port1_svalid : std_logic_vector(num_bank - 1 downto 0);
    signal port1_sready : std_logic_vector(num_bank - 1 downto 0);
    signal port1_sreq   : std_logic_vector(num_bank - 1 downto 0);


    type port_sa_dram_t is array(0 to num_bank_dram - 1) of std_logic_vector(port_addr_width_dram - 1 downto 0);
    type port_sd_dram_t is array(0 to num_bank_dram - 1) of std_logic_vector(port_width_dram - 1 downto 0);
    type port_sbe_dram_t is array(0 to num_bank_dram - 1) of std_logic_vector(port_be_width_dram - 1 downto 0);
    signal port0_sa_DRAM  : port_sa_dram_t;
    signal port0_sd_DRAM  : port_sd_dram_t;
    signal port0_sbe_DRAM : port_sbe_dram_t;
    signal port0_sq_DRAM  : port_sd_dram_t;

    signal port1_sa_DRAM  : port_sa_dram_t;
    signal port1_sd_DRAM  : port_sd_dram_t;
    signal port1_sbe_DRAM : port_sbe_dram_t;
    signal port1_sq_DRAM  : port_sd_dram_t;


    type port_sa_sram_t is array(0 to num_bank_sram - 1) of std_logic_vector(port_addr_width_sram - 1 downto 0);
    type port_sd_sram_t is array(0 to num_bank_sram - 1) of std_logic_vector(port_width_sram - 1 downto 0);
    type port_sbe_sram_t is array(0 to num_bank_sram - 1) of std_logic_vector(port_be_width_sram - 1 downto 0);
    signal port0_sa_SRAM  : port_sa_sram_t;
    signal port0_sd_SRAM  : port_sd_sram_t;
    signal port0_sbe_SRAM : port_sbe_sram_t;
    signal port0_sq_SRAM  : port_sd_sram_t;

    signal port1_sa_SRAM  : port_sa_sram_t;
    signal port1_sd_SRAM  : port_sd_sram_t;
    signal port1_sbe_SRAM : port_sbe_sram_t;
    signal port1_sq_SRAM  : port_sd_sram_t;


    signal arb_ce      : std_logic_vector(num_bank - 1 downto 0);
    signal arb_w       : std_logic_vector(num_bank - 1 downto 0);
    signal arb_tag     : port_stag_t;
    signal arb_qtag    : port_stag_t;
    signal arb_valid   : std_logic_vector(num_bank - 1 downto 0);
    signal arb_ready   : std_logic_vector(num_bank - 1 downto 0);

    signal arb_a_DRAM  : port_sa_dram_t;
    signal arb_d_DRAM  : port_sd_dram_t;
    signal arb_be_DRAM : port_sbe_dram_t;
    signal arb_q_DRAM  : port_sd_dram_t;

    signal arb_a_SRAM  : port_sa_sram_t;
    signal arb_d_SRAM  : port_sd_sram_t;
    signal arb_be_SRAM : port_sbe_sram_t;
    signal arb_q_SRAM  : port_sd_sram_t;

begin

    logic0 <= '0';
    logic1 <= '1';

--    user_rst <= memrst;
--    user_clk <= memclk0;

--    locked(7 downto 2) <= (others => '0');
    -- Unused memory banks
    trained(15 downto 3) <= (others => '0');

    --
    -- Tags used by local bus to memory interface are "00" and "01", leaving
    -- "10" and "11" spare.
    --
    usr0_tag_base <= EXT("00", tag_width);
    usr0_tag_mask <= EXT("01", tag_width);

    usr1_tag_base <= EXT("10", tag_width);
    usr1_tag_mask <= EXT("11", tag_width);


--//----------------------------------------------------------------------
--//PORT-0
--//----------------------------------------------------------------------
    usr0_wf  <= OR_reduce(usr0_bank1h(num_bank - 1 downto 0) and port0_pwf);
    usr0_wpf <= OR_reduce(usr0_bank1h(num_bank - 1 downto 0) and port0_pwpf);
    usr0_re  <= OR_reduce(usr0_bank1h(num_bank - 1 downto 0) and port0_pre);
    usr0_rpe <= OR_reduce(usr0_bank1h(num_bank - 1 downto 0) and port0_prpe);

--    --
--    -- Output outbound data to local bus
--    --
--gen_ch0_use0_ssram_on : if G_BANK_COUNT>=3  generate
--    usr0_dout <= usr0_dout_SRAM when usr0_bank1h(num_bank_dram) = '1' else usr0_dout_DRAM;
--end generate gen_ch0_use0_ssram_on;

gen_ch0_use0_ssram_off : if G_BANK_COUNT<3  generate
    usr0_dout <= usr0_dout_DRAM;
end generate gen_ch0_use0_ssram_off;

    --
    -- Instantiate outbound data replicator for the DDR-II SDRAM banks
    --
    usr0_cew <= usr0_ce and usr0_cw;

    port0_repl_dram : port_repl
        generic map(
            order     => mux_order_dram,
            in_width  => 32,--C_MEMCTRL_DATA_WIDTH,--
            out_width => port_width_dram,
            partial   => true)
        port map(
            rst   => rst,
            clk   => usr0_clk,

            init  => usr0_cew,
            addr  => usr0_adr(mux_order_dram - 1 downto 0),
            wr    => usr0_wr,
            last  => usr0_term,
            din   => usr0_din,
            bein  => usr0_be,

            dout  => rep0_d_DRAM,
            beout => rep0_be_DRAM,
            valid => rep0_valid_DRAM,
            final => rep0_final_DRAM);

    --
    -- Instantiate inbound data multiplexor for DDR-II SDRAM
    --
    gen_port0_pq_muxed_dram : process(
        port0_pq_DRAM,
        usr0_bank1h)
        variable x : std_logic_vector(port_width_dram - 1 downto 0);
    begin
        x := (others => '0');
        for i in 0 to num_bank_dram - 1 loop
            if usr0_bank1h(i) = '1' then
                x := x or port0_pq_DRAM(i);
            end if;
        end loop;
        port0_pq_muxed_DRAM <= x;
    end process;

    port0_mux_dram : port_mux
        generic map(
            order     => mux_order_dram,
            in_width  => port_width_dram,
            out_width => 32) --C_MEMCTRL_DATA_WIDTH )--,--
        port map(
            rst  => rst,
            clk  => usr0_clk,

            init => usr0_ce,
            addr => usr0_adr(mux_order_dram - 1 downto 0),
            adv  => usr0_rd,
            din  => port0_pq_muxed_DRAM,
            dout => usr0_dout_DRAM,
            last => port0_plast_DRAM);

--    --
--    -- Instantiate outbound data replicator for the DDR-II SSRAM banks
--    --
--gen_ch0_use1_ssram_on : if G_BANK_COUNT>=3  generate
--    port0_repl_sram : port_repl
--        generic map(
--            order     => mux_order_sram,
--            in_width  => 32,--C_MEMCTRL_DATA_WIDTH,--
--            out_width => port_width_sram,
--            partial   => true)
--        port map(
--            rst   => rst,
--            clk   => usr0_clk,
--
--            init  => usr0_cew,
--            addr  => usr0_adr(mux_order_sram - 1 downto 0),
--            wr    => usr0_wr,
--            last  => usr0_term,
--            din   => usr0_din,
--            bein  => usr0_be,
--
--            dout  => rep0_d_SRAM,
--            beout => rep0_be_SRAM,
--            valid => rep0_valid_SRAM,
--            final => rep0_final_SRAM);
--
--    --
--    -- Instantiate inbound data multiplexor for DDR-II SSRAM
--    --
--    gen_port0_pq_muxed_sram : process(
--        port0_pq_SRAM,
--        usr0_bank1h)
--        variable x : std_logic_vector(port_width_sram - 1 downto 0);
--    begin
--        x := (others => '0');
--        for i in 0 to num_bank_sram - 1 loop
--            if usr0_bank1h(i + num_bank_dram) = '1' then
--                x := x or port0_pq_SRAM(i);
--            end if;
--        end loop;
--        port0_pq_muxed_SRAM <= x;
--    end process;
--
--    port0_mux_sram : port_mux
--        generic map(
--            order     => mux_order_sram,
--            in_width  => port_width_sram,
--            out_width => 32)
--        port map(
--            rst  => rst,
--            clk  => usr0_clk,
--
--            init => usr0_ce,
--            addr => usr0_adr(mux_order_sram - 1 downto 0),
--            adv  => usr0_rd,
--
--            din  => port0_pq_muxed_SRAM,
--            dout => usr0_dout_SRAM,
--
--            last => port0_plast_SRAM);
--end generate gen_ch0_use1_ssram_on;

    --
    -- Instantiate 'async_port' components for DDR-II SDRAM memory banks.
    --
    -- These instances decouple the local bus clock domain from the
    -- memory interface clock domain.
    --
    gen_async_ports0_dram : for i in 0 to num_bank_dram - 1 generate
        port0_pce(i)   <= usr0_bank1h(i) and usr0_ce;
        port0_pcw(i)   <= usr0_cw;
        port0_pterm(i) <= usr0_bank1h(i) and rep0_final_DRAM;
        port0_padv(i)  <= usr0_bank1h(i) and port0_plast_DRAM and usr0_rd;
        port0_pwr(i)   <= usr0_bank1h(i) and rep0_valid_DRAM;

        async_port_0 : async_port
            generic map(
                family     => family_virtex5,
                order      => 6,
                iwpfl      => 32,--3,
                orpel      => 1,
                owpfl      => 32,
                addr_width => port_addr_width_dram,
                data_width => port_width_dram,
                tag_width  => 2)
            port map(
                rst      => rst,
                pclk     => usr0_clk,
                psr      => logic0,

                pce      => port0_pce(i),
                pcw      => port0_pcw(i),
                pterm    => port0_pterm(i),
                padv     => port0_padv(i),
                pwr      => port0_pwr(i),
                pa       => usr0_adr(C_MEMCTRL_ADDR_WIDTH - 1 downto mux_order_dram),
                pd       => rep0_d_DRAM,
                pbe      => rep0_be_DRAM,
                pq       => port0_pq_DRAM(i),
                pwf      => port0_pwf(i),
                pwpf     => port0_pwpf(i),
                pre      => port0_pre(i),
                prpe     => port0_prpe(i),

                sclk     => memclk0,
                sce      => port0_sce(i),
                sw       => port0_sw(i),
                stag     => port0_stag(i),
                sa       => port0_sa_DRAM(i),
                sd       => port0_sd_DRAM(i),
                sbe      => port0_sbe_DRAM(i),
                sq       => port0_sq_DRAM(i),
                sqtag    => port0_sqtag(i),
                svalid   => port0_svalid(i),
                sready   => port0_sready(i),
                sreq     => port0_sreq(i),

                tag_base => usr0_tag_base,
                tag_mask => usr0_tag_mask);
    end generate;

--    --
--    -- Instantiate 'async_port' components for DDR-II SSRAM memory banks.
--    --
--    -- These instances decouple the local bus clock domain from the
--    -- memory interface clock domain.
--    --
--gen_ch0_use2_ssram_on : if G_BANK_COUNT>=3  generate
--    gen_async_ports0_sram : for i in 0 to num_bank_sram - 1 generate
--        port0_pce(i + num_bank_dram)   <= usr0_bank1h(i + num_bank_dram) and usr0_ce;
--        port0_pcw(i + num_bank_dram)   <= usr0_cw;
--        port0_pterm(i + num_bank_dram) <= usr0_bank1h(i + num_bank_dram) and rep0_final_SRAM;
--        port0_padv(i + num_bank_dram)  <= usr0_bank1h(i + num_bank_dram) and port0_plast_SRAM and usr0_rd;
--        port0_pwr(i + num_bank_dram)   <= usr0_bank1h(i + num_bank_dram) and rep0_valid_SRAM;
--
--        async_port_0 : async_port
--            generic map(
--                family     => family_virtex5,
--                order      => 6,
--                iwpfl      => 32,--3,
--                orpel      => 1,
--                owpfl      => 32,
--                addr_width => port_addr_width_sram,
--                data_width => port_width_sram,
--                tag_width  => 2)
--            port map(
--                rst      => rst,
--                pclk     => usr0_clk,
--                psr      => logic0,
--
--                pce      => port0_pce(i + num_bank_dram),
--                pcw      => port0_pcw(i + num_bank_dram),
--                pterm    => port0_pterm(i + num_bank_dram),
--                padv     => port0_padv(i + num_bank_dram),
--                pwr      => port0_pwr(i + num_bank_dram),
--                pa       => usr0_adr(C_MEMCTRL_ADDR_WIDTH - 1 downto mux_order_sram),
--                pd       => rep0_d_SRAM,
--                pbe      => rep0_be_SRAM,
--                pq       => port0_pq_SRAM(i),
--                pwf      => port0_pwf(i + num_bank_dram),
--                pwpf     => port0_pwpf(i + num_bank_dram),
--                pre      => port0_pre(i + num_bank_dram),
--                prpe     => port0_prpe(i + num_bank_dram),
--
--                sclk     => memclk0,
--                sce      => port0_sce(i + num_bank_dram),
--                sw       => port0_sw(i + num_bank_dram),
--                stag     => port0_stag(i + num_bank_dram),
--                sa       => port0_sa_SRAM(i),
--                sd       => port0_sd_SRAM(i),
--                sbe      => port0_sbe_SRAM(i),
--                sq       => port0_sq_SRAM(i),
--                sqtag    => port0_sqtag(i + num_bank_dram),
--                svalid   => port0_svalid(i + num_bank_dram),
--                sready   => port0_sready(i + num_bank_dram),
--                sreq     => port0_sreq(i + num_bank_dram),
--                tag_base => usr0_tag_base,
--                tag_mask => usr0_tag_mask);
--    end generate;
--end generate gen_ch0_use2_ssram_on;

----//----------------------------------------------------------------------
----//PORT-1
----//----------------------------------------------------------------------
--    usr1_wf  <= OR_reduce(usr1_bank1h(num_bank - 1 downto 0) and port1_pwf);
--    usr1_wpf <= OR_reduce(usr1_bank1h(num_bank - 1 downto 0) and port1_pwpf);
--    usr1_re  <= OR_reduce(usr1_bank1h(num_bank - 1 downto 0) and port1_pre);
--    usr1_rpe <= OR_reduce(usr1_bank1h(num_bank - 1 downto 0) and port1_prpe);
--
--    --
--    -- Output outbound data to local bus
--    --
--gen_ch1_use0_ssram_on : if G_BANK_COUNT>=3  generate
--    usr1_dout <= usr1_dout_SRAM when usr1_bank1h(num_bank_dram) = '1' else usr1_dout_DRAM;
--end generate gen_ch1_use0_ssram_on;
--
--gen_ch1_use0_ssram_off : if G_BANK_COUNT<3  generate
--    usr1_dout <= usr1_dout_DRAM;
--end generate gen_ch1_use0_ssram_off;
--
--    --
--    -- Instantiate outbound data replicator for the DDR-II SDRAM banks
--    --
--    usr1_cew <= usr1_ce and usr1_cw;
--
--    port1_repl_dram : port_repl
--        generic map(
--            order     => mux_order_dram,
--            in_width  => 32,--C_MEMCTRL_DATA_WIDTH,--
--            out_width => port_width_dram,
--            partial   => true)
--        port map(
--            rst   => rst,
--            clk   => usr1_clk,
--
--            init  => usr1_cew,
--            addr  => usr1_adr(mux_order_dram - 1 downto 0),
--            wr    => usr1_wr,
--            last  => usr1_term,
--            din   => usr1_din,
--            bein  => usr1_be,
--
--            dout  => rep1_d_DRAM,
--            beout => rep1_be_DRAM,
--            valid => rep1_valid_DRAM,
--            final => rep1_final_DRAM);
--
--    --
--    -- Instantiate inbound data multiplexor for DDR-II SDRAM
--    --
--    gen_port1_pq_muxed_dram : process(
--        port1_pq_DRAM,
--        usr1_bank1h)
--        variable x : std_logic_vector(port_width_dram - 1 downto 0);
--    begin
--        x := (others => '0');
--        for i in 0 to num_bank_dram - 1 loop
--            if usr1_bank1h(i) = '1' then
--                x := x or port1_pq_DRAM(i);
--            end if;
--        end loop;
--        port1_pq_muxed_DRAM <= x;
--    end process;
--
--    port1_mux_dram : port_mux
--        generic map(
--            order     => mux_order_dram,
--            in_width  => port_width_dram,
--            out_width => 32)--C_MEMCTRL_DATA_WIDTH )--,--
--        port map(
--            rst  => rst,
--            clk  => usr1_clk,
--
--            init => usr1_ce,
--            addr => usr1_adr(mux_order_dram - 1 downto 0),
--            adv  => usr1_rd,
--
--            din  => port1_pq_muxed_DRAM,
--            dout => usr1_dout_DRAM,
--
--            last => port1_plast_DRAM);
--
--    --
--    -- Instantiate outbound data replicator for the DDR-II SSRAM banks
--    --
--gen_ch1_use1_ssram_on : if G_BANK_COUNT>=3  generate
--    port1_repl_sram : port_repl
--        generic map(
--            order     => mux_order_sram,
--            in_width  => 32,--C_MEMCTRL_DATA_WIDTH,--
--            out_width => port_width_sram,
--            partial   => true)
--        port map(
--            rst   => rst,
--            clk   => usr1_clk,
--
--            init  => usr1_cew,
--            addr  => usr1_adr(mux_order_sram - 1 downto 0),
--            wr    => usr1_wr,
--            last  => usr1_term,
--            din   => usr1_din,
--            bein  => usr1_be,
--
--            dout  => rep1_d_SRAM,
--            beout => rep1_be_SRAM,
--            valid => rep1_valid_SRAM,
--            final => rep1_final_SRAM);
--
--    --
--    -- Instantiate inbound data multiplexor for DDR-II SSRAM
--    --
--    gen_port1_pq_muxed_sram : process(
--        port1_pq_sram,
--        usr1_bank1h)
--        variable x : std_logic_vector(port_width_sram - 1 downto 0);
--    begin
--        x := (others => '0');
--        for i in 0 to num_bank_sram - 1 loop
--            if usr1_bank1h(i + num_bank_dram) = '1' then
--                x := x or port1_pq_SRAM(i);
--            end if;
--        end loop;
--        port1_pq_muxed_SRAM <= x;
--    end process;
--
--    port1_mux_sram : port_mux
--        generic map(
--            order     => mux_order_sram,
--            in_width  => port_width_sram,
--            out_width => 32)--C_MEMCTRL_DATA_WIDTH )--,--
--        port map(
--            rst  => rst,
--            clk  => usr1_clk,
--
--            init => usr1_ce,
--            addr => usr1_adr(mux_order_sram - 1 downto 0),
--            adv  => usr1_rd,
--
--            din  => port1_pq_muxed_SRAM,
--            dout => usr1_dout_SRAM,
--
--            last => port1_plast_SRAM);
--end generate gen_ch1_use1_ssram_on;
--
--    --
--    -- Instantiate 'async_port' components for DDR-II SDRAM memory banks.
--    --
--    -- These instances decouple the local bus clock domain from the
--    -- memory interface clock domain.
--    --
--    gen_async_ports1_dram : for i in 0 to num_bank_dram - 1 generate
--        port1_pce(i)   <= usr1_bank1h(i) and usr1_ce;
--        port1_pcw(i)   <= usr1_cw;
--        port1_pterm(i) <= usr1_bank1h(i) and rep1_final_DRAM;
--        port1_padv(i)  <= usr1_bank1h(i) and port1_plast_DRAM and usr1_rd;
--        port1_pwr(i)   <= usr1_bank1h(i) and rep1_valid_DRAM;
--
--        async_port_1 : async_port
--            generic map(
--                family     => family_virtex5,
--                order      => 6, --//FIFO depth (number of words that can be held in the FIFO) is 2**order - 1.
--                iwpfl      => 32,--3,
--                orpel      => 1,
--                owpfl      => 32,
--                addr_width => port_addr_width_dram,
--                data_width => port_width_dram,
--                tag_width  => 2)
--            port map(
--                rst      => rst,
--                pclk     => usr1_clk,
--                psr      => logic0,
--
--                pce      => port1_pce(i),
--                pcw      => port1_pcw(i),
--                pterm    => port1_pterm(i),
--                padv     => port1_padv(i),
--                pwr      => port1_pwr(i),
--
--                pa       => usr1_adr(C_MEMCTRL_ADDR_WIDTH - 1 downto mux_order_dram),
--
--                pd       => rep1_d_DRAM,
--                pbe      => rep1_be_DRAM,
--                pq       => port1_pq_DRAM(i),
--                pwf      => port1_pwf(i),
--                pwpf     => port1_pwpf(i),
--                pre      => port1_pre(i),
--                prpe     => port1_prpe(i),
--
--                sclk     => memclk0,
--
--                sce      => port1_sce(i),
--                sw       => port1_sw(i),
--                stag     => port1_stag(i),
--                sa       => port1_sa_DRAM(i),
--                sd       => port1_sd_DRAM(i),
--                sbe      => port1_sbe_DRAM(i),
--                sq       => port1_sq_DRAM(i),
--                sqtag    => port1_sqtag(i),
--                svalid   => port1_svalid(i),
--                sready   => port1_sready(i),
--                sreq     => port1_sreq(i),
--
--                tag_base => usr1_tag_base,
--                tag_mask => usr1_tag_mask);
--    end generate;
--
--    --
--    -- Instantiate 'async_port' components for DDR-II SSRAM memory banks.
--    --
--    -- These instances decouple the local bus clock domain from the
--    -- memory interface clock domain.
--    --
--gen_ch1_use2_ssram_on : if G_BANK_COUNT>=3  generate
--    gen_async_ports1_sram : for i in 0 to num_bank_sram - 1 generate
--        port1_pce(i + num_bank_dram)   <= usr1_bank1h(i + num_bank_dram) and usr1_ce;
--        port1_pcw(i + num_bank_dram)   <= usr1_cw;
--        port1_pterm(i + num_bank_dram) <= usr1_bank1h(i + num_bank_dram) and rep1_final_SRAM;
--        port1_padv(i + num_bank_dram)  <= usr1_bank1h(i + num_bank_dram) and port1_plast_SRAM and usr1_rd;
--        port1_pwr(i + num_bank_dram)   <= usr1_bank1h(i + num_bank_dram) and rep1_valid_SRAM;
--
--        async_port_1 : async_port
--            generic map(
--                family     => family_virtex5,
--                order      => 6,
--                iwpfl      => 32,--3,
--                orpel      => 1,
--                owpfl      => 32,
--                addr_width => port_addr_width_sram,
--                data_width => port_width_sram,
--                tag_width  => 2)
--            port map(
--                rst      => rst,
--                pclk     => usr1_clk,
--                psr      => logic0,
--
--                pce      => port1_pce(i + num_bank_dram),
--                pcw      => port1_pcw(i + num_bank_dram),
--                pterm    => port1_pterm(i + num_bank_dram),
--                padv     => port1_padv(i + num_bank_dram),
--                pwr      => port1_pwr(i + num_bank_dram),
--
--                pa       => usr1_adr(C_MEMCTRL_ADDR_WIDTH - 1 downto mux_order_sram),
--
--                pd       => rep1_d_SRAM,
--                pbe      => rep1_be_SRAM,
--
--                pq       => port1_pq_SRAM(i),
--                pwf      => port1_pwf(i + num_bank_dram),
--                pwpf     => port1_pwpf(i + num_bank_dram),
--                pre      => port1_pre(i + num_bank_dram),
--                prpe     => port1_prpe(i + num_bank_dram),
--
--                sclk     => memclk0,
--
--                sce      => port1_sce(i + num_bank_dram),
--                sw       => port1_sw(i + num_bank_dram),
--                stag     => port1_stag(i + num_bank_dram),
--                sa       => port1_sa_SRAM(i),
--                sd       => port1_sd_SRAM(i),
--                sbe      => port1_sbe_SRAM(i),
--                sq       => port1_sq_SRAM(i),
--                sqtag    => port1_sqtag(i + num_bank_dram),
--                svalid   => port1_svalid(i + num_bank_dram),
--                sready   => port1_sready(i + num_bank_dram),
--                sreq     => port1_sreq(i + num_bank_dram),
--
--                tag_base => usr1_tag_base,
--                tag_mask => usr1_tag_mask);
--    end generate;
--end generate gen_ch1_use2_ssram_on;


--//----------------------------------------------------------------------
--//Арбитр Портов USRxx
--//----------------------------------------------------------------------
    --
    -- Arbitrate between the two clients that require access to the memory banks:
    --
    --   1. Local bus interface
    --   2. Matcher
    --
    -- The local bus interface is given priority, because PCI/PCI-X transfers targetting
    -- memory banks may time out if timely access to the memory is not granted.
    --
    gen_arbiters_dram : for i in 0 to num_bank_dram - 1 generate

          arb_ce(i)     <= port0_sce(i)     ;--        ce            : out   std_logic;
          arb_w(i)      <= port0_sw(i)      ;--        w             : out   std_logic;
          arb_tag(i)    <= port0_stag(i)    ;--        tag           : out   std_logic_vector(tag_width - 1 downto 0);
          arb_a_DRAM(i) <= port0_sa_DRAM(i) ;--        a             : out   std_logic_vector(a_width - 1 downto 0);
          arb_d_DRAM(i) <= port0_sd_DRAM(i) ;--        d             : out   std_logic_vector(d_width - 1 downto 0);
          arb_be_DRAM(i)<= port0_sbe_DRAM(i);--        be            : out   std_logic_vector(d_width / 8 - 1 downto 0);
          port0_sq_DRAM(i)<= arb_q_DRAM(i)  ;--        q             : in    std_logic_vector(d_width - 1 downto 0);
          port0_sqtag(i)  <= arb_qtag(i)    ;--        qtag          : in    std_logic_vector(tag_width - 1 downto 0);
          port0_svalid(i) <= arb_valid(i)   ;--        valid         : in    std_logic;
          port0_sready(i) <= arb_ready(i)   ;--        ready         : in    std_logic;

--        U0 : arbiter_2
--            generic map(
--                registered  => true,
--                ready_delay => 1,
--                latency     => 16,
--                unfair      => true,
--                bias        => 0,                    --//Номер канала с наивысшим приоритетом
--                a_width     => port_addr_width_dram,
--                d_width     => port_width_dram,
--                tag_width   => tag_width)
--            port map(
--            --//USR0
--                req0   => port0_sreq(i),
--                ce0    => port0_sce(i),
--                w0     => port0_sw(i),
--                tag0   => port0_stag(i),
--                a0     => port0_sa_DRAM(i),
--                d0     => port0_sd_DRAM(i),
--                be0    => port0_sbe_DRAM(i),
--                q0     => port0_sq_DRAM(i),
--                qtag0  => port0_sqtag(i),
--                valid0 => port0_svalid(i),
--                ready0 => port0_sready(i),
--            --//USR1
--                req1   => port1_sreq(i),
--                ce1    => port1_sce(i),
--                w1     => port1_sw(i),
--                tag1   => port1_stag(i),
--                a1     => port1_sa_DRAM(i),
--                d1     => port1_sd_DRAM(i),
--                be1    => port1_sbe_DRAM(i),
--                q1     => port1_sq_DRAM(i),
--                qtag1  => port1_sqtag(i),
--                valid1 => port1_svalid(i),
--                ready1 => port1_sready(i),
--
--            --//MEM_IF
--                ce    => arb_ce(i),
--                w     => arb_w(i),
--                tag   => arb_tag(i),
--                a     => arb_a_DRAM(i),
--                d     => arb_d_DRAM(i),
--                be    => arb_be_DRAM(i),
--                q     => arb_q_DRAM(i),
--                qtag  => arb_qtag(i),
--                valid => arb_valid(i),
--                ready => arb_ready(i),
--
--                rst => memrst,
--                clk => memclk0,
--                sr  => logic0
--                );
    end generate;

--gen_arb_ssram_on : if G_BANK_COUNT>=3  generate
--    gen_arbiters_sram : for i in 0 to num_bank_sram - 1 generate
--        U0 : arbiter_2
--            generic map(
--                registered  => true,
--                ready_delay => 1,
--                latency     => 16,
--                unfair      => true,
--                bias        => 0,                    --//Номер канала с наивысшим приоритетом
--                a_width     => port_addr_width_sram,
--                d_width     => port_width_sram,
--                tag_width   => tag_width)
--            port map(
--            --//USR0
--                req0   => port0_sreq(i + num_bank_dram),
--                ce0    => port0_sce(i + num_bank_dram),
--                w0     => port0_sw(i + num_bank_dram),
--                tag0   => port0_stag(i + num_bank_dram),
--                a0     => port0_sa_SRAM(i),
--                d0     => port0_sd_SRAM(i),
--                be0    => port0_sbe_SRAM(i),
--                q0     => port0_sq_SRAM(i),
--                qtag0  => port0_sqtag(i + num_bank_dram),
--                valid0 => port0_svalid(i + num_bank_dram),
--                ready0 => port0_sready(i + num_bank_dram),
--            --//USR1
--                req1   => port1_sreq(i + num_bank_dram),
--                ce1    => port1_sce(i + num_bank_dram),
--                w1     => port1_sw(i + num_bank_dram),
--                tag1   => port1_stag(i + num_bank_dram),
--                a1     => port1_sa_SRAM(i),
--                d1     => port1_sd_SRAM(i),
--                be1    => port1_sbe_SRAM(i),
--                q1     => port1_sq_SRAM(i),
--                qtag1  => port1_sqtag(i + num_bank_dram),
--                valid1 => port1_svalid(i + num_bank_dram),
--                ready1 => port1_sready(i + num_bank_dram),
--
--            --//MEM_IF
--                ce    => arb_ce(i + num_bank_dram),
--                w     => arb_w(i + num_bank_dram),
--                tag   => arb_tag(i + num_bank_dram),
--                a     => arb_a_SRAM(i),
--                d     => arb_d_SRAM(i),
--                be    => arb_be_SRAM(i),
--                q     => arb_q_SRAM(i),
--                qtag  => arb_qtag(i + num_bank_dram),
--                valid => arb_valid(i + num_bank_dram),
--                ready => arb_ready(i + num_bank_dram),
--
--                rst => memrst,
--                clk => memclk0,
--                sr => logic0
--                );
--    end generate;
--end generate gen_arb_ssram_on;

--//----------------------------------------------------------------
-- Instantiate the DDR-II SDRAM memory ports
--//----------------------------------------------------------------
    dram_port_0 : ddr2sdram_port
        generic map(
            pinout    => ddr2sdram_pinout_admxrc5t1,
            timing    => ddr2sdram_timing_266,
            ra_width  => bank0.ra_width,
            rc_width  => bank0.rc_width,
            rd_width  => bank0.rd_width,
            a_width   => port_addr_width_dram,
            d_width   => port_width_dram,
            tag_width => 2)
        port map(
            rst     => memrst,
            sr      => logic0,
            clk0    => memclk0,
            clk45   => memclk45,
            clk2x0  => memclk2x0,
            clk2x90 => memclk2x90,

            ce      => arb_ce(0),
            w       => arb_w(0),
            tag     => arb_tag(0),
            a       => arb_a_DRAM(0),
            d       => arb_d_DRAM(0),
            be      => arb_be_DRAM(0),
            q       => arb_q_DRAM(0),
            qtag    => arb_qtag(0),
            ready   => arb_ready(0),
            valid   => arb_valid(0),
            row     => mode_reg(32 * 0 + 3 downto 32 * 0 + 2),
            col     => mode_reg(32 * 0 + 5 downto 32 * 0 + 4),
            bank    => mode_reg(32 * 0 + 7 downto 32 * 0 + 6),
            pbank   => mode_reg(32 * 0 + 9 downto 32 * 0 + 8),
            trained => trained(0),

            ra => ra0,
            rc => rc0,
            rd => rd0);

gen_ddrsdram_port2_on : if G_BANK_COUNT>=2  generate
    dram_port_1 : ddr2sdram_port
        generic map(
            pinout    => ddr2sdram_pinout_admxrc5t1,
            timing    => ddr2sdram_timing_266,
            ra_width  => bank1.ra_width,
            rc_width  => bank1.rc_width,
            rd_width  => bank1.rd_width,
            a_width   => port_addr_width_dram,
            d_width   => port_width_dram,
            tag_width => 2)
        port map(
            rst     => memrst,
            sr      => logic0,
            clk0    => memclk0,
            clk45   => memclk45,
            clk2x0  => memclk2x0,
            clk2x90 => memclk2x90,

            ce      => arb_ce(1),
            w       => arb_w(1),
            tag     => arb_tag(1),
            a       => arb_a_DRAM(1),
            d       => arb_d_DRAM(1),
            be      => arb_be_DRAM(1),
            q       => arb_q_DRAM(1),
            qtag    => arb_qtag(1),
            ready   => arb_ready(1),
            valid   => arb_valid(1),
            row     => mode_reg(32 * 1 + 3 downto 32 * 1 + 2),
            col     => mode_reg(32 * 1 + 5 downto 32 * 1 + 4),
            bank    => mode_reg(32 * 1 + 7 downto 32 * 1 + 6),
            pbank   => mode_reg(32 * 1 + 9 downto 32 * 1 + 8),
            trained => trained(1),

            ra => ra1,
            rc => rc1,
            rd => rd1);
end generate gen_ddrsdram_port2_on;

gen_ddrsdram_port2_off : if G_BANK_COUNT<2  generate
    ra2 <= (others => 'Z');
    rc2 <= (others => 'Z');
    rd2 <= (others => 'Z');
end generate gen_ddrsdram_port2_off;

----//----------------------------------------------------------------
---- Instantiate the DDR-II SSRAM memory port
----//----------------------------------------------------------------
--gen_ssram_port_on : if G_BANK_COUNT>=3  generate
--    sram_port_0 : ddr2sram_port_v4
--        generic map(
--            pinout    => ddr2sram_pinout_admxrc5t1,
--            ra_width  => bank2.ra_width,
--            rc_width  => bank2.rc_width,
--            rd_width  => bank2.rd_width,
--            a_width   => port_addr_width_sram,
--            d_width   => port_width_sram,
--            tag_width => tag_width)
--        port map(
--            rst     => memrst,
--            sr      => logic0,
--            clk0    => memclk0,
--            clk45   => memclk45,
--            clk2x0  => memclk2x0,
--            clk2x90 => memclk2x90,
--
--            ce      => arb_ce(2),
--            w       => arb_w(2),
--            tag     => arb_tag(2),
--            a       => arb_a_SRAM(0),
--            d       => arb_d_SRAM(0),
--            be      => arb_be_SRAM(0),
--            q       => arb_q_SRAM(0),
--            qtag    => arb_qtag(2),
--            valid   => arb_valid(2),
--            ready   => arb_ready(2),
--            dll_off => mode_reg(32 * 2 + 2),
--            trained => trained(2),
--
--            ra => ra2,
--            rc => rc2,
--            rd => rd2);
--end generate gen_ssram_port_on;
--
--gen_ssram_port_off : if G_BANK_COUNT<3  generate
    ra2 <= (others => 'Z');
    rc2 <= (others => 'Z');
    rd2 <= (others => 'Z');
--end generate gen_ssram_port_off;
    --
    -- Banks 3-15 are not present/used.
    --

    ra3 <= (others => 'Z');
    rc3 <= (others => 'Z');
    rd3 <= (others => 'Z');
    ra4 <= (others => 'Z');
    rc4 <= (others => 'Z');
    rd4 <= (others => 'Z');
    ra5 <= (others => 'Z');
    rc5 <= (others => 'Z');
    rd5 <= (others => 'Z');
    ra6 <= (others => 'Z');
    rc6 <= (others => 'Z');
    rd6 <= (others => 'Z');
    ra7 <= (others => 'Z');
    rc7 <= (others => 'Z');
    rd7 <= (others => 'Z');
    ra8 <= (others => 'Z');
    rc8 <= (others => 'Z');
    rd8 <= (others => 'Z');
    ra9 <= (others => 'Z');
    rc9 <= (others => 'Z');
    rd9 <= (others => 'Z');
    ra10 <= (others => 'Z');
    rc10 <= (others => 'Z');
    rd10 <= (others => 'Z');
    ra11 <= (others => 'Z');
    rc11 <= (others => 'Z');
    rd11 <= (others => 'Z');
    ra12 <= (others => 'Z');
    rc12 <= (others => 'Z');
    rd12 <= (others => 'Z');
    ra13 <= (others => 'Z');
    rc13 <= (others => 'Z');
    rd13 <= (others => 'Z');
    ra14 <= (others => 'Z');
    rc14 <= (others => 'Z');
    rd14 <= (others => 'Z');
    ra15 <= (others => 'Z');
    rc15 <= (others => 'Z');
    rd15 <= (others => 'Z');

    --
    -- No memory clocks to generate (clocks generated for each port)
    --

    ramclko <= (others => 'Z');

end architecture;
