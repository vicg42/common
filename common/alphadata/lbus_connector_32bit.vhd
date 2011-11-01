--
-- memory_main.vhd - Example design demonstrating FPGA-to-memory interfaces
--
-- SYNTHESIZABLE
--
-- (C) Copyright Alpha Data 2005-2008
--
-- Memory map:
--
--   Two regions exist in the FPGA space on the local bus; a register region
--   and a memory region.
--
--        0x0 - 0x1FFFFF     register region
--   0x200000 - 0x3FFFFF     memory region
--
-- 1. Register region (Addresses on local bus; all registers 32-bit wide)
--
--   0x0      BANK     Selects bank for access via memory region:
--                     [3:0]    R/W   bank select
--
--   0x4      PAGE     Selects page within currently selected bank for access:
--                     [12:0]   R/W   page select
--
--   0x8      MEMCTL   Control functions associated with memory
--                     [0]      R/W   1 => memory subsystem held in reset. DO
--                                         NOT access memory region while held
--                                         in reset.
--
--   0x10     STATUS   Various DLL/DCM/PLL/IDELAYCTRL status signals. Bit fields vary
--                     according to model being targetted:
--                     [0]      RO    'lclk' DLL/DCM lock flag (1 => mem_locked)
--                     [1]      R/W1C Stick loss-of-lock flag corresponding to [0]
--                     [7:1]          (reserved)
--                     ** ADM-XRC-5LX, ADM-XRC-5T1, ADM-XRC-5T2 **
--                     [8]      RO    Memory clock PLL lock flag (1 => mem_locked)
--                     [9]      RO    IDELAY reference clock PLL lock flag (1 => mem_locked)
--                     [10]     RO    IDELAYCTRL lock flag (1 => mem_locked)
--                     [15:11]        (reserved)
--                     [18:16]  R/W1C Sticky loss-of-lock flags corresponding to [10:8]
--                     [31:19]        (reserved)
--
--   0x14     SPD      Access to DIMM SPD I2C bus:
--                     [7:0]    R/W   EEPROM address
--                     [15:8]         (reserved)
--                     [23:16]  RO    byte read from EEPROM
--                     [24]     RO    1 => read failed
--                     [27:26]  R/W   DIMM socket address
--                     [30:27]        (reserved)
--                     [31]     WO    Write 1 to initiate read of EEPROM
--                              RO    1 => busy
--
--   0x18     MEMSTAT  Memory bank status:
--                     ** ADM-XRC-5T1 **
--                     [1:0]      RO  DDR-II SDRAM bank training status, 1 => mem_trained
--                     [2]        RO  DDR-II SSRAM bank training status, 1 => mem_trained
--                     [31:3]         (reserved)
--
--   0x40     MODE0    Bank mode register 0 (corresponds to logical bank 0)
--   0x44     MODE1    Bank mode register 1 (corresponds to logical bank 1)
--   ....
--   0x7c     MODE15   Bank mode register 15 (corresponds to logical bank 15).
--
--                     Each MODEx register works differently depending on type
--                     of memory bank it is assocaited with.
--
--                       ZBT SRAM:
--                       [0]     Selects pipelined/flowthru:
--                               0 => flowthru, 1 => pipelined
--                       [31:1]  (reserved)
--
--                       DDR-II SRAM:
--                       [0]     Burst length: 0 => 2, 1 => 4
--                       [2]     DLL control: 0 => enabled, 1 => disabled
--                       [31:3]  (reserved)
--
--                       DDR SDRAM:
--                       [0]     Registered: 0 => not registered, 1 => registered
--                       [1]     (reserved for x4 device support, must be zero at present)
--                       [3:2]   Row address width (see below)
--                       [5:4]   Column address width (see below)
--
--                                  [3:2]    [5:4]      # row bits   # col bits
--                                 ---------------------------------------------
--                                  00       00         12           8
--                                  00       01         12           9
--                                  00       10         12           10
--                                  00       11         12           11
--                                  01       00         13           9
--                                  01       01         13           10
--                                  01       10         13           11
--                                  01       11         13           12
--                                  10       00         14           10
--                                  10       01         14           11
--                                  10       10         14           12
--                                  10       11         14           13
--                                  11       00         15           11
--                                  11       01         15           11
--                                  11       10         15           13
--                                  11       11         15           14
--
--                       [7:6]   Number of banks on devices: 00 => 1, 01 => 2, 10 => 4, 11 => 8
--                       [9:8]   Number of physical banks: 00 => 1, 01 => 2, 10 => 4, 11 => 8
--                       [31:10] (reserved)
--
--                       DDR-II SDRAM:
--                       [1:0]   (reserved)
--                       [3:2]   Row address width (see below)
--                       [5:4]   Column address width (see below)
--
--                                  [3:2]    [5:4]      # row bits   # col bits
--                                 ---------------------------------------------
--                                  00       00         12           8
--                                  00       01         12           9
--                                  00       10         12           10
--                                  00       11         12           11
--                                  01       00         13           9
--                                  01       01         13           10
--                                  01       10         13           11
--                                  01       11         13           12
--                                  10       00         14           10
--                                  10       01         14           11
--                                  10       10         14           12
--                                  10       11         14           13
--                                  11       00         15           11
--                                  11       01         15           11
--                                  11       10         15           13
--                                  11       11         15           14
--
--                       [7:6]   Number of banks on devices: 00 => 1, 01 => 2, 10 => 4, 11 => 8
--                       [9:8]   Number of physical banks: 00 => 1, 01 => 2, 10 => 4, 11 => 8
--                       [31:10] (reserved)
--
--
--   All other locations in memory region are reserved.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
-- synopsys translate_on

library work;
use work.prj_def.all;
use work.localbus.all;
--use work.memif.all;
--use work.memory_ctrl_pkg.all;

entity lbus_connector_32bit is
generic
(
-- Bit of local bus address that is used to decode FPGA space
la_top        : in    natural
);
port
(
--------------------------------------------------
-- Связь с хостом по Local bus
--------------------------------------------------
lad                        : inout std_logic_vector(32-1 downto 0);--(31 downto 0);
lbe_l                      : in    std_logic_vector(32/8-1 downto 0);--(3 downto 0);
lads_l                     : in    std_logic;
lwrite                     : in    std_logic;
lblast_l                   : in    std_logic;
lbterm_l                   : inout std_logic;
lready_l                   : inout std_logic;
fholda                     : in    std_logic;
finto_l                    : out   std_logic;

--------------------------------------------------
--Связь с уст-вами проекта Veresk-M
--------------------------------------------------
p_out_hclk_out         : out   std_logic;

p_out_gctrl                : out    std_logic_vector(32-1 downto 0);
p_out_dev_ctrl             : out    std_logic_vector(32-1 downto 0);
p_in_dev_status            : in     std_logic_vector(32-1 downto 0);
p_out_dev_din              : out    std_logic_vector(32-1 downto 0);
p_in_dev_dout              : in     std_logic_vector(32-1 downto 0);
p_out_dev_wd               : out    std_logic;
p_out_dev_rd               : out    std_logic;

p_out_dev_eof              : out    std_logic;

p_in_tst_in                : in     std_logic_vector(127 downto 0);

----//связь с модулем memory contrller
--p_out_mem_ctl_reg          : out   std_logic_vector(0 downto 0);
--p_out_mem_mode_reg         : out   std_logic_vector(511 downto 0);
--p_in_mem_locked            : in    std_logic_vector(7 downto 0);
--p_in_mem_trained           : in    std_logic_vector(15 downto 0);

p_out_mem_bank1h           : out   std_logic_vector(15 downto 0);
p_out_mem_ce               : out   std_logic;
p_out_mem_cw               : out   std_logic;
p_out_mem_rd               : out   std_logic;
p_out_mem_wr               : out   std_logic;
p_out_mem_term             : out   std_logic;
p_out_mem_adr              : out   std_logic_vector(32 - 1 downto 0);
p_out_mem_be               : out   std_logic_vector(32 / 8 - 1 downto 0);
p_out_mem_din              : out   std_logic_vector(32 - 1 downto 0);
p_in_mem_dout              : in    std_logic_vector(32 - 1 downto 0);

p_in_mem_wf                : in    std_logic;
p_in_mem_wpf               : in    std_logic;
p_in_mem_re                : in    std_logic;
p_in_mem_rpe               : in    std_logic;

scl_i                      : in    std_logic;
scl_o                      : out   std_logic;
sda_i                      : in    std_logic;
sda_o                      : out   std_logic;

--------------------------------------------------
--System
--------------------------------------------------
--clk_locked                 : in    std_logic;--//Status
----mclk_i                     : in    std_logic;--//General purpose clock
----refclk_i                   : in    std_logic;--//Reference clock for IDELAY elements (might be unused)

clk                        : in    std_logic;
p_in_rst_n                 : in    std_logic
);
end entity;

architecture mixed of lbus_connector_32bit is

constant C_MEMCTRL_CFG_MODE_REG_COUNT  : integer:=3;--//32 bit

  -- SPD clock division factor (80kHz SCL @ LCLK frequency of 80MHz)
  constant scldiv             : natural := 250;

  signal rst                  : std_logic;
  --
  -- Memory bank status
  --
  signal mem_locked               : std_logic_vector(7 downto 0);
  signal mem_trained              : std_logic_vector(15 downto 0);--(max_num_bank - 1 downto 0);

  --
  -- Local bus signals in and out
  --
  signal la_i                 : std_logic_vector(32-1 downto 0);--(31 downto 0);
  signal ld_i                 : std_logic_vector(32-1 downto 0);--(31 downto 0);
  signal ld_o                 : std_logic_vector(32-1 downto 0);--(31 downto 0);
  signal ld_oe_l              : std_logic_vector(32-1 downto 0);--(31 downto 0);
  signal lads_i               : std_logic;
  signal lblast_i             : std_logic;
  signal lbterm_i             : std_logic;
  signal lready_i             : std_logic;
  signal lwrite_i             : std_logic;
  signal lready_o_l           : std_logic;
  signal lready_oe_l          : std_logic;
  signal lbterm_o_l           : std_logic;
  signal lbterm_oe_l          : std_logic;
  signal eld_oe               : std_logic;
  signal ld_iq                : std_logic_vector(32-1 downto 0);--(31 downto 0);
  signal lbe_iq_l             : std_logic_vector(32/8-1 downto 0);--(3 downto 0);

  signal ld_o_tmp             : std_logic_vector(32-1 downto 0);--(31 downto 0);

  --
  -- Qualified address strobe; this is LADS# qualified by some combinatorial
  -- decoding of the local bus address.
  --
  signal qlads                : std_logic;

  --
  -- Local bus interface state machine outputs, indicating data transfer,
  -- address decoding and whether current transfer is a read or a write.
  --
  signal ds_xfer              : std_logic;
  signal ds_decode            : std_logic;
  signal ds_write             : std_logic;
  signal ds_idle              : std_logic;

  --
  -- Local bus interface state machine inputs; these determine when
  -- the FPGA asserts LREADY# and LBTERM#.
  --
  signal ds_ready             : std_logic;
  signal ds_stop              : std_logic;

  --
  -- Tracks local bus address
  --
  signal la_q                 : std_logic_vector(23 downto 2);

  --
  -- Registers and their selects
  --
  signal bank_reg             : std_logic_vector(3 downto 0);
  signal sel_bank_reg         : std_logic;
  signal wr_bank_reg          : std_logic;
  signal page_reg             : std_logic_vector(12 downto 0);
  signal sel_page_reg         : std_logic;
  signal wr_page_reg          : std_logic;
  signal memctl_reg           : std_logic_vector(0 downto 0);
  signal sel_memctl_reg       : std_logic;
  signal wr_memctl_reg        : std_logic;
  signal status_reg           : std_logic_vector(31 downto 0);
  signal sel_status_reg       : std_logic;
  signal wr_status_reg        : std_logic;
  signal mode_reg             : std_logic_vector((C_MEMCTRL_CFG_MODE_REG_COUNT*32)-1 downto 0);--(511 downto 0);
  signal sel_mode_reg         : std_logic_vector(15 downto 0);
  signal wr_mode_reg          : std_logic_vector(15 downto 0);
--  signal spd_reg              : std_logic_vector(31 downto 0);
--  signal sel_spd_reg          : std_logic;
--  signal wr_spd_reg           : std_logic;
  signal memstat_reg          : std_logic_vector(15 downto 0);--(31 downto 0);
  signal sel_memstat_reg      : std_logic;

  --
  -- Bank selects
  --
  signal bank1h          : std_logic_vector(15 downto 0);

   --
  -- Signals to/from memory port(s)
  --
  signal mem_term             : std_logic;
  signal mem_wr               : std_logic;
  signal mem_rd               : std_logic;
  signal mem_dout             : std_logic_vector(32-1 downto 0);
  signal mem_wf               : std_logic;
  signal mem_wpf              : std_logic;
  signal mem_re               : std_logic;
  signal mem_rpe              : std_logic;

  signal mem_reading          : std_logic;

  -- Signals to/from SPD interface
--  signal read_spd             : std_logic;
--  signal read_spd_ack         : std_logic;
--  signal spd_d                : std_logic_vector(7 downto 0);
--  signal spd_q                : std_logic_vector(7 downto 0);
--  signal spd_err              : std_logic;
--  signal spd_busy             : std_logic;


  --//мои сигналы
  signal mem_reg_bar            : std_logic; --
  signal vereskm_reg_bar        : std_logic; --
  signal mem_data_bar_detect    : std_logic; --
  signal vereskm_reg_bar_detect : std_logic; --//Обнаружен BAR записи/чтения данных регистров проекта VERESK-M

  signal vereskm_reg_adr        : std_logic_vector(6 downto 0); --//Адреса регистров проекта VERESK-M
  signal usr_reg_wr             : std_logic;
  signal v_reg_gctrl        : std_logic_vector(32-1 downto 0);--(C_HREG_CTRL_LAST_BIT downto 0);
  signal v_reg_fpga_firmware    : std_logic_vector(32-1 downto 0);--(C_HREG_FRMWARE_LAST_BIT downto 0);
  signal v_reg_dev_ctrl         : std_logic_vector(32-1 downto 0);--C_HREG_DEV_CTRL_LAST_BIT downto 0);
  signal v_reg_tst0             : std_logic_vector(32-1 downto 0);
  signal v_reg_tst1             : std_logic_vector(32-1 downto 0);

  signal v_reg_tst4             : std_logic_vector(32-1 downto 0);

  signal b_dev_address               : std_logic_vector(C_HREG_DEV_CTRL_ADR_M_BIT-C_HREG_DEV_CTRL_ADR_L_BIT downto 0);

--  signal i_trn_dlen_cnt        : std_logic_vector(C_HREG_DEV_CTRL_DLEN_SIZE-1 downto 0);
--  signal i_trn_dlen            : std_logic_vector(C_HREG_DEV_CTRL_DLEN_SIZE-1 downto 0);
--  signal i_trn_int_en          : std_logic;
  signal interrupt             : std_logic;

--  signal usr_buf_term          : std_logic;
--  signal usr_buf_wr            : std_logic;
  signal usr_buf_rd            : std_logic;
--  signal usr_dev_adv           : std_logic;
--  signal usr_dev_reading       : std_logic;

  signal usr_buf_wf            : std_logic;
  signal usr_buf_wpf           : std_logic;
  signal usr_buf_re            : std_logic;
  signal usr_buf_rpe           : std_logic;

  signal sel_memory_ctrl       : std_logic;


  signal tst_mem_dir          : std_logic;
  signal tst_mem_start        : std_logic;
  signal tst_mem_stop         : std_logic;
  signal tst_mem_rd           : std_logic;
  signal tst_mem_wd           : std_logic;

  signal tst_mem_wpf        : std_logic;
  signal tst_mem_re         : std_logic;

  signal i_dev_txd_rdy      : std_logic;
  signal i_trn_start_sw     : std_logic;
  signal i_interrupt_clr    : std_logic;
--  signal i_trn_rst_sw       : std_logic;
  signal i_hrddone_vctrl    : std_logic;
  signal i_hrddone_trcnik   : std_logic;

begin

  --
  -- Convert the inputs to active high.
  --
  rst      <= not p_in_rst_n;
  la_i     <=lad;
  ld_i     <=lad;
  lblast_i <= not lblast_l;
  lads_i   <= not lads_l;
  lbterm_i <= not lbterm_l;
  lready_i <= not lready_l;
  lwrite_i <= lwrite;

  --
  -- Register lbe_l and ld_i (flip-flops should be mapped into IOBs)
  --
  register_ld_i : process(clk)
  begin
    if clk'event and clk = '1' then
      lbe_iq_l <= lbe_l;
      ld_iq <= ld_i;
    end if;
  end process;

  --
  -- Generate a qualified version of 'lads_l', which is
  -- asserted when the FPGA is addressed AND the FPGA is
  -- not the local bus master.
  --
  qlads <= lads_i and not la_i(la_top) and not fholda;

  --
  -- Latch the local bus address on the 'lads_l' pulse.
  --
  latch_addr : process(rst, clk)
  begin
    if rst = '1' then
      la_q <= (others => '0');
    elsif clk'event and clk = '1' then
      if lads_i = '1' then
        la_q <= la_i(23 downto 2);
      end if;
    end if;
  end process;

  --
  -- 'lbterm_l' should only be driven when the FPGA is addressed; otherwise
  -- float, because the control logic on the card might also drive it.
  --
  lbterm_l <= lbterm_o_l when lbterm_oe_l = '0' else 'Z';

  --
  -- 'lready_l' should only be driven when the FPGA is addressed; otherwise
  -- float because the control logic on the card might also drive it.
  --
  lready_l <= lready_o_l when lready_oe_l = '0' else 'Z';


  --
  -- Drive the local data bus on a read.
  --
  gen_ld_oe_l : process(rst, clk)
  begin
    if rst = '1' then
      ld_oe_l <= (others => '1');
    elsif clk'event and clk = '1' then
      ld_oe_l <= (others => not eld_oe);
    end if;
  end process;
  --
  -- Drive LAD when we are being read.
  --
  gen_lad : for i in lad'range generate
    lad(i) <= ld_o(i) when ld_oe_l(i) = '0' else 'Z';
  end generate;

  --
  -- BAR для регистров управления контроллером памяти и регистров проекта VERESK-M
  --
  mem_reg_bar     <=not la_i(21) and not la_i(7);--la_i(9);
  vereskm_reg_bar <=not la_i(21) and     la_i(7);--la_i(9);
  mem_data_bar_detect <=la_q(21);

  --
  -- Generate the 'sel_*_reg' signals, for multiplexing registers onto
  -- the outbound local bus data.
  --
  process(rst, clk)
  begin
    if rst = '1' then
      vereskm_reg_bar_detect <= '0';
      vereskm_reg_adr<= (others => '0');
    elsif clk'event and clk = '1' then
    --//32BIT
        if qlads = '1' then

          -- Select VERESKM registers
          if vereskm_reg_bar='1' then
            vereskm_reg_bar_detect <= '1';
--            vereskm_reg_adr(4 downto 0) <= la_i(6 downto 2);--la_i(7 downto 3);
            vereskm_reg_adr(6 downto 0) <= la_i(6 downto 0);--la_i(7 downto 3);
          else
            vereskm_reg_bar_detect <= '0';
          end if;

        end if;
    end if;
  end process;

  generate_selects : process(rst, clk)
  begin
    if rst = '1' then
      sel_bank_reg <= '0';
      sel_page_reg <= '0';
      sel_memctl_reg <= '0';
      sel_status_reg <= '0';
      sel_mode_reg <= (others => '0');
--      sel_spd_reg <= '0';
      sel_memstat_reg <= '0';

    elsif clk'event and clk = '1' then
    --//32BIT
        if qlads = '1' then

          -- Select BANK register
          if mem_reg_bar='1' and la_i(6 downto 2) = "00000" then --la_i(8 downto 2) = "0000000" then
            sel_bank_reg <= '1';
          else
            sel_bank_reg <= '0';
          end if;

          -- Select PAGE register
          if mem_reg_bar='1' and la_i(6 downto 2) = "00001" then --la_i(8 downto 2) = "0000001" then
            sel_page_reg <= '1';
          else
            sel_page_reg <= '0';
          end if;

          -- Select MEMCTL register
          if mem_reg_bar='1' and la_i(6 downto 2) = "00010" then --la_i(8 downto 2) = "0000010" then
            sel_memctl_reg <= '1';
          else
            sel_memctl_reg <= '0';
          end if;

          -- Select STATUS register
          if mem_reg_bar='1' and la_i(6 downto 2) = "00100" then --la_i(8 downto 2) = "0000100" then
            sel_status_reg <= '1';
          else
            sel_status_reg <= '0';
          end if;

--          -- Select SPD register
--          if mem_reg_bar='1' and la_i(6 downto 2) = "00101" then --la_i(8 downto 2) = "0000101" then
--            sel_spd_reg <= '1';
--          else
--            sel_spd_reg <= '0';
--          end if;

          -- Select MEMSTAT register
          if mem_reg_bar='1' and la_i(6 downto 2) = "00110" then --la_i(8 downto 2) = "0000110" then
            sel_memstat_reg <= '1';
          else
            sel_memstat_reg <= '0';
          end if;

          -- Select MODEx registers
          for i in 0 to 15 loop
            if mem_reg_bar='1' and la_i(6) = '1' and la_i(5 downto 2) = i then --la_i(8 downto 6) = "001" and la_i(5 downto 2) = i then
              sel_mode_reg(i) <= '1';
            else
              sel_mode_reg(i) <= '0';
            end if;
          end loop;

        end if;
    end if;
  end process;

  --
  -- If the current cycle is a write, update the registers.
  --
  update_regs : process(rst, clk)
  begin
    if rst = '1' then
      bank_reg <= (others => '0');
      wr_bank_reg <= '0';
      page_reg <= (others => '0');
      wr_page_reg <= '0';
      memctl_reg <= (others => '0');
      wr_memctl_reg <= '0';
      memstat_reg <= (others => '0');
      mode_reg <= (others => '0');
      wr_mode_reg <= (others => '0');
--      spd_reg <= (others => '0');
--      wr_spd_reg <= '0';
      bank1h <= (others => '0');

    elsif clk'event and clk = '1' then
    --//32BIT
        --
        -- BANK register
        --
        wr_bank_reg <= ds_xfer and ds_write and sel_bank_reg;
        if wr_bank_reg = '1' then
          if lbe_iq_l(0) = '0' then
            bank_reg(3 downto 0) <= ld_iq(3 downto 0);
          end if;
        end if;

        --
        -- PAGE register
        --
        wr_page_reg <= ds_xfer and ds_write and sel_page_reg;
        if wr_page_reg = '1' then
          if lbe_iq_l(0) = '0' then
            page_reg(7 downto 0) <= ld_iq(7 downto 0);
          end if;
          if lbe_iq_l(1) = '0' then
            page_reg(12 downto 8) <= ld_iq(12 downto 8);
          end if;
        end if;

        --
        -- MEMCTL register
        --
        wr_memctl_reg <= ds_xfer and ds_write and sel_memctl_reg;
        if wr_memctl_reg = '1' then
          if lbe_iq_l(0) = '0' then
            memctl_reg(0 downto 0) <= ld_iq(0 downto 0);
          end if;
        end if;

        --
        -- MODEx registers
        --
--        for i in 0 to 15 loop
        for i in 0 to C_MEMCTRL_CFG_MODE_REG_COUNT-1 loop
          wr_mode_reg(i) <= ds_xfer and ds_write and sel_mode_reg(i);
          if wr_mode_reg(i) = '1' then
            for j in 0 to 3 loop
              if lbe_iq_l(j) = '0' then
                mode_reg(32 * i + 8 * (j + 1) - 1 downto 32 * i + 8 * j) <= ld_iq(8 * (j + 1) - 1 downto 8 * j);
              end if;
            end loop;
          end if;
        end loop;

--        --
--        -- SPD register
--        --
--        wr_spd_reg <= ds_xfer and ds_write and sel_spd_reg;
--        if wr_spd_reg = '1' then
--          if lbe_iq_l(0) = '0' then
--            spd_reg(7 downto 0) <= ld_iq(7 downto 0);
--          end if;
--          if lbe_iq_l(3) = '0' then
--            spd_reg(27 downto 25) <= ld_iq(27 downto 25);
--          end if;
--        end if;
--
--        if wr_spd_reg = '1' then
--          -- Initiate SPD read
--          read_spd <= ld_iq(31);
--        else
--          read_spd <= '0';
--        end if;


    --//-------------------------------------
    --//Одинаково для 32/64BIT
    --//-------------------------------------
--        if read_spd_ack = '1' then
--          spd_reg(23 downto 16) <= spd_q;
--          spd_reg(24) <= spd_err;
--        end if;
--
--        spd_reg(31) <= spd_busy;

        --
        -- MEMSTAT register
        --
        memstat_reg(15 downto 0) <= mem_trained;

        --
        -- Generate one-hot bank-select vector
        --
        for i in 0 to 15 loop
          if bank_reg = i then
            bank1h(i) <= '1';
          else
            bank1h(i) <= '0';
          end if;
        end loop;

    end if;
  end process;

  --
  -- Implement the STATUS register. This is treated as a special case,
  -- since some bits of STATUS are asynchronously set to 1 by loss of lock.
  --
  gen_wr_status_reg : process(rst, clk)
  begin
    if rst = '1' then
      wr_status_reg <= '1';
    elsif clk'event and clk = '1' then
      wr_status_reg <= ds_xfer and ds_write and sel_status_reg;
    end if;
  end process;

  --
  -- Bit 0 shows LCLK DCM/DLL lock status
  --
  status_reg_0 : process(clk)
  begin
    if clk'event and clk = '1' then
      status_reg(0) <= '0';--clk_locked;
    end if;
  end process;

--  --
--  -- Bit 1 is a "sticky" version of bit 0, which is asynchronously set to 1
--  -- when LCLK DCM/DLL lock is lost.
--  --
--  status_reg_1 : process(clk_locked, clk)
--  begin
--    if clk_locked = '0' then
--        status_reg(1) <= '1';
--    elsif clk'event and clk = '1' then
--      if wr_status_reg = '1' then
--        if lbe_iq_l(0) = '0' and ld_iq(1) = '1' then
          status_reg(1) <= '0';
--        end if;
--      end if;
--    end if;
--  end process;

  status_reg(7 downto 2) <= (others => '0');

  --
  -- Bits 15:8 show lock status for memory DLL/DCM/IDELAYCTRL/PLLs.
  --
  status_reg_15_8 : process(clk)
  begin
    if clk'event and clk = '1' then
      status_reg(15 downto 8) <= mem_locked;
    end if;
  end process;

  --
  -- Bits 23:16 are "sticky" versions of bits 15:8, which are asynchronously set
  -- to 1 when memory DLL/DCM/PLL/IDELAYCTRL lock is lost.
  -- is 0.
  --
  status_reg_23_16 : for i in 0 to 7 generate
    U0 : process(mem_locked, clk)
    begin
      if mem_locked(i) = '0' then
        status_reg(16 + i) <= '1';
      elsif clk'event and clk = '1' then
        if wr_status_reg = '1' then
          if lbe_iq_l(2) = '0' and ld_iq(16 + i) = '1' then
            status_reg(16 + i) <= '0';
          end if;
        end if;
      end if;
    end process;
  end generate;

  status_reg(31 downto 24) <= (others => '0');

  --
  -- Generate the outbound local bus data, by multiplexing either a
  -- register or a memory bank data bus onto the outbound local bus data.
  --
  gen_ld_o : process(rst, clk)
      variable lo : std_logic_vector(31 downto 0);
--      variable hi : std_logic_vector(31 downto 0);
  begin
    if rst = '1' then
      ld_o_tmp <= (others => '0');
    elsif clk'event and clk = '1' then
    --//32BIT
        lo := (others => '0');

        --//Чтение данных регистров
        if sel_bank_reg = '1' then
            lo := lo or EXT(bank_reg, 32);
        end if;

        if sel_page_reg = '1' then
            lo := lo or EXT(page_reg, 32);
        end if;

        if sel_memctl_reg = '1' then
            lo := lo or EXT(memctl_reg, 32);
        end if;

        if sel_status_reg = '1' then
            lo := lo or status_reg;
        end if;

--        if sel_spd_reg = '1' then
--            lo := lo or spd_reg;
--        end if;

        if sel_memstat_reg = '1' then
            lo := lo or EXT(memstat_reg, 32);
        end if;

--        for i in 0 to 15 loop
        for i in 0 to C_MEMCTRL_CFG_MODE_REG_COUNT-1 loop
            if sel_mode_reg(i) = '1' then
                lo := lo or mode_reg(32 * (i + 1) - 1 downto 32 * i);
            end if;
        end loop;

        --//Чтение данных регистров
        --//BAR - vereskm_reg_bar_detect
        if vereskm_reg_bar_detect='1' then
          if    vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_CTRL, 5)  then lo(v_reg_gctrl'high downto 0):= v_reg_gctrl;
          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_FIRMWARE, 5)    then lo(v_reg_fpga_firmware'high downto 0):= v_reg_fpga_firmware;

          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_CTRL, 5)    then --lo := v_reg_dev_ctrl_rd;

            lo(C_HREG_DEV_CTRL_DMA_DIR_BIT):= v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT);
            lo(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT):= v_reg_dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT);
            lo(C_HREG_DEV_CTRL_DMABUF_NUM_M_BIT downto C_HREG_DEV_CTRL_DMABUF_NUM_L_BIT):= v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMABUF_NUM_M_BIT downto C_HREG_DEV_CTRL_DMABUF_NUM_L_BIT);
            lo(C_HREG_DEV_CTRL_DMABUF_COUNT_M_BIT downto C_HREG_DEV_CTRL_DMABUF_COUNT_L_BIT):= v_reg_dev_ctrl(C_HREG_DEV_CTRL_DMABUF_COUNT_M_BIT downto C_HREG_DEV_CTRL_DMABUF_COUNT_L_BIT);
            lo(C_HREG_DEV_CTRL_VCH_M_BIT downto C_HREG_DEV_CTRL_VCH_L_BIT):= v_reg_dev_ctrl(C_HREG_DEV_CTRL_VCH_M_BIT downto C_HREG_DEV_CTRL_VCH_L_BIT);


          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_STATUS, 5)then lo(C_HREG_DEV_STATUS_LAST_BIT downto 0):= p_in_dev_status(C_HREG_DEV_STATUS_LAST_BIT downto 0);

          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST0, 5)        then lo := v_reg_tst0;
          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST1, 5)        then lo := v_reg_tst1;

--          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST2, 5)        then lo := p_in_tst_in(31 downto 0);
--          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST4, 5)        then lo := p_in_tst_in(63 downto 32);
--          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST4, 5)        then lo := v_reg_tst4;

--          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_DATA, 5) then x := x or i_usr_dev_dout;
          end if;
        end if;

        --//Чтение данных из memory_ctrl.vhd
        if mem_data_bar_detect = '1' and sel_memory_ctrl='1' then
            lo := lo or mem_dout(31 downto 0);
        end if;

--        if usr1_data_bar_detect='1' then
--            lo := lo or usr1_dout(31 downto 0);
--        end if;

        ld_o_tmp <= lo;
    end if;
  end process;


--  spd_d <= (others => '-');
--
--  spd_i2c_0 : spd_i2c
--  generic map(scldiv => scldiv)
--  port map
--  (
--  a     => spd_reg(7 downto 0),
--  d     => spd_d,
--  q     => spd_q,
--  ce    => read_spd,
--  wr    => '0',
--  sa    => spd_reg(27 downto 25),
--  ack   => read_spd_ack,
--  busy  => spd_busy,
--  err   => spd_err,
--
--  scl_i => scl_i,
--  scl_o => scl_o,
--  sda_i => sda_i,
--  sda_o => sda_o,
--
--  clk   => clk,
--  sr    => '0',
--  rst   => rst
--  );
--
----  spd_q<=(others=>'0');
----  read_spd_ack<='0';
----  spd_busy<='0';
----  spd_err<='0';
--
--  scl_o<='0';
--  sda_o<='0';

  --
  -- Instantiate the direct slave state machine; monitors the local bus for
  -- direct slave cycles and responds appropriately.
  --
  dssm : plxdssm
  port map
  (
  qlads       => qlads,      --//in
  lbterm      => lbterm_i,   --//in
  lblast      => lblast_i,   --//in
  lwrite      => lwrite_i,   --//in
  eld_oe      => eld_oe,     --//out
  lready_o_l  => lready_o_l, --//out
  lready_oe_l => lready_oe_l,--//out
  lbterm_o_l  => lbterm_o_l, --//out
  lbterm_oe_l => lbterm_oe_l,--//out

  idle        => ds_idle,    --//out
  transfer    => ds_xfer,    --//out
  decode      => ds_decode,  --//out
  write       => ds_write,   --//out
  ready       => ds_ready,   --//out
  stop        => ds_stop,    --//out

  clk => clk,
  sr  => '0',
  rst => rst
  );

--//-----------------------------------------------
--//Конфигурирование
--//-----------------------------------------------
  mem_locked      <= (others=>'0');--p_in_mem_locked;
  mem_trained     <= (others=>'0');--p_in_mem_trained;

--  p_out_mem_ctl_reg    <= memctl_reg;
----  p_out_mem_mode_reg   <= mode_reg;
--  p_out_mem_mode_reg((C_MEMCTRL_CFG_MODE_REG_COUNT*32)-1 downto 0)<= mode_reg((C_MEMCTRL_CFG_MODE_REG_COUNT*32)-1 downto 0);
--  p_out_mem_mode_reg(511 downto (C_MEMCTRL_CFG_MODE_REG_COUNT*32))<=(others=>'0');
  p_out_mem_bank1h<= bank1h;

  --
  -- Instantiate memory banks.
  --
  gen_mem_sig : process(rst, clk)
  begin
    if rst = '1' then
      mem_term <= '0';
      mem_wr <= '0';
      mem_rd <= '0';
      mem_reading <= '0';
    elsif clk'event and clk = '1' then
      mem_term <= mem_data_bar_detect and ds_xfer and (lblast_i or lbterm_i);--//Останов. записи данных в memory_ctrl.vhd
      mem_wr   <= mem_data_bar_detect and ds_xfer and ds_write;              --//Запись данных в в memory_ctrl.vhd

      if ds_xfer = '1' and (lblast_i = '1' or lbterm_i = '1') then
        mem_rd <= '0';
      else
        if mem_reading = '1' and mem_re = '0' then
            mem_rd <= '1';
        end if;
      end if;

      if ds_xfer = '1' and (lblast_i = '1' or lbterm_i = '1') then
        mem_reading <= '0';
      else
        if ds_decode = '1' then
          mem_reading <= mem_data_bar_detect and not ds_write;
        end if;
      end if;
    end if;
  end process;

--//-----------------------------------------------
--//запись/чтение памяти
--//-----------------------------------------------
  b_dev_address   <= v_reg_dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT);

  sel_memory_ctrl <='1' when b_dev_address =CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, b_dev_address'length) else '0';
--  sel_memory_ctrl<='1' when v_reg_tst0(0)='1' or v_reg_dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT)=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, C_HREG_DEV_CTRL_ADR_SIZE) else '0';

  p_out_mem_ce    <= ds_decode and mem_data_bar_detect and sel_memory_ctrl; --//Разрешение работы с памятью
  p_out_mem_cw    <= ds_decode and ds_write and sel_memory_ctrl;            --//Назначение операции записи/чтения
  p_out_mem_term  <= mem_term and sel_memory_ctrl;                          --//Остановка текущей операции
  p_out_mem_rd    <= mem_rd and sel_memory_ctrl;                            --//чтение RXBUF
  p_out_mem_wr    <= mem_wr and sel_memory_ctrl;                            --//запись TXBUF
  p_out_mem_be    <= not lbe_iq_l;                      --//byte enable

  --//32BIT
  p_out_mem_adr   <= page_reg & la_q(20 downto 2);      --//Адрес(записи/чтение) памяти
--  --//64BIT
--  p_out_mem_adr   <= page_reg & la_q(20 downto 3);      --//Адрес(записи/чтение) памяти

  p_out_mem_din   <= ld_iq;                             --//данные записи в память

  mem_dout        <= p_in_mem_dout;                     --//данные чтения из памяти

--//Состояние согласующих буферов (TX/RX) между хостом и памятью
  mem_wf          <= p_in_mem_wf  and sel_memory_ctrl;--//TXBUF - Full
  mem_wpf         <= p_in_mem_wpf and sel_memory_ctrl;--//TXBUF - ProgFull
  mem_re          <= p_in_mem_re  and sel_memory_ctrl;--//RXBUF - Empty
  mem_rpe         <= p_in_mem_rpe and sel_memory_ctrl;--//RXBUF - ProgEmpty


--//Управление модулем dssm : plxdssm.vhd
  ds_stop  <= not mem_data_bar_detect or ((ds_write and     mem_wpf) or (not ds_write and mem_rd and mem_rpe));
  ds_ready <= not mem_data_bar_detect or ((ds_write and not mem_wpf) or (not ds_write and mem_rd));


process(rst, clk)
begin
  if rst = '1' then
    tst_mem_dir   <='0';
    tst_mem_start <='0';
    tst_mem_stop  <='0';
    tst_mem_rd    <='0';
    tst_mem_wd    <='0';

    tst_mem_wpf <='0';
    tst_mem_re  <='0';
  elsif clk'event and clk = '1' then
    tst_mem_dir   <= ds_decode and ds_write and sel_memory_ctrl;
    tst_mem_start <= ds_decode and mem_data_bar_detect and sel_memory_ctrl;
    tst_mem_stop  <= mem_term and sel_memory_ctrl;
    tst_mem_rd    <= mem_rd and sel_memory_ctrl;
    tst_mem_wd    <= mem_wr and sel_memory_ctrl;

    tst_mem_wpf <= p_in_mem_wpf and sel_memory_ctrl;--//TXBUF - ProgFull
    tst_mem_re  <= p_in_mem_re  and sel_memory_ctrl;--//RXBUF - Empty
 end if;
end process;

  v_reg_tst4(0)<=tst_mem_dir;
  v_reg_tst4(1)<=tst_mem_start;
  v_reg_tst4(2)<=tst_mem_stop;
  v_reg_tst4(3)<=tst_mem_rd;
  v_reg_tst4(4)<=tst_mem_wd;

  v_reg_tst4(5)<=tst_mem_wpf;
  v_reg_tst4(6)<=tst_mem_re;

--//-----------------------------------------------
--//запись/чтение пользовательских буферов (TX|RX)
--//-----------------------------------------------
--//Состояние согласующих буферов (TX/RX) между хостом и модулями проекта FPGA
--  usr_buf_wf <='0';
--  usr_buf_wpf<='0';
--  usr_buf_re <='0';
--  usr_buf_rpe<='0';

  p_out_gctrl(C_HREG_CTRL_RST_ALL_BIT)<=v_reg_gctrl(C_HREG_CTRL_RST_ALL_BIT);
  p_out_gctrl(C_HREG_CTRL_RST_MEM_BIT)<=v_reg_gctrl(C_HREG_CTRL_RST_MEM_BIT);
  p_out_gctrl(C_HREG_CTRL_RST_ETH_BIT)<=v_reg_gctrl(C_HREG_CTRL_RST_ETH_BIT);
  p_out_gctrl(C_HREG_CTRL_RDDONE_VCTRL_BIT)<=i_hrddone_vctrl;
  p_out_gctrl(C_HREG_CTRL_RDDONE_TRCNIK_BIT)<=i_hrddone_trcnik;
  p_out_gctrl(p_out_gctrl'high downto C_HREG_CTRL_LAST_BIT)<=(others=>'0');

  p_out_dev_ctrl(0) <=i_trn_start_sw;
  p_out_dev_ctrl(p_out_dev_ctrl'high downto 1)<=v_reg_dev_ctrl(p_out_dev_ctrl'high downto 1);

  p_out_dev_din   <=ld_iq;
  p_out_dev_wd    <=mem_wr;
  p_out_dev_rd    <=usr_buf_rd;

  usr_buf_rd<='1' when ds_xfer='1' and ds_write='0' and mem_data_bar_detect='1' and sel_memory_ctrl='0' else '0';


--  i_usr_dev_dout(31 downto 0)<=p_in_dev_dout;
--  ld_o<=ld_o_tmp;
  ld_o<=p_in_dev_dout when ds_xfer='1' and ds_write='0' and mem_data_bar_detect='1' and sel_memory_ctrl='0' else ld_o_tmp;


  process(rst, clk)
  begin
    if rst = '1' then
      p_out_dev_eof <= '0';
    elsif clk'event and clk = '1' then
      if mem_wr='1' and lblast_i='1' then
        p_out_dev_eof <= '1';
      else
        p_out_dev_eof <= '0';
      end if;
    end if;
  end process;


  v_reg_fpga_firmware<=CONV_STD_LOGIC_VECTOR(C_FPGA_FIRMWARE_VERSION, v_reg_fpga_firmware'length);


  --//Запись в мои регистры
  process(rst,clk)
    variable var_trn_start_edge  : std_logic;
    variable var_int_clr_edge    : std_logic;
--    variable var_trn_rst_edge    : std_logic;
    variable var_dev_txd_rdy_edge: std_logic;
    variable var_hrddone_vctrl_edge: std_logic;
    variable var_hrddone_trcnik_edge: std_logic;

  begin
    if rst = '1' then

      var_dev_txd_rdy_edge:='0';
      var_trn_start_edge  :='0';
      var_int_clr_edge    :='0';
--      var_trn_rst_edge    :='0';
      var_hrddone_vctrl_edge:='0';
      var_hrddone_trcnik_edge:='0';

      v_reg_gctrl<=(others=>'0');
      v_reg_dev_ctrl<=(others=>'0');
      v_reg_tst0<=(others=>'0');
      v_reg_tst1<=(others=>'0');

      i_dev_txd_rdy   <='0';
      i_trn_start_sw  <='0';
      i_interrupt_clr <='0';
--      i_trn_rst_sw    <='0';
      i_hrddone_vctrl <='0';
      i_hrddone_trcnik<='0';

    elsif clk'event and clk = '1' then

      var_dev_txd_rdy_edge:='0';
      var_trn_start_edge  :='0';
      var_int_clr_edge    :='0';
--      var_trn_rst_edge    :='0';
      var_hrddone_vctrl_edge:='0';
      var_hrddone_trcnik_edge:='0';

        if usr_reg_wr='1' then
          if vereskm_reg_bar_detect='1' then
            if    vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_CTRL, 5) then

              for j in 0 to 32/8-1 loop
                if lbe_iq_l(j) = '0' then
                  v_reg_gctrl(8 * (j + 1) - 1 downto  8 * j) <= ld_iq(8 * (j + 1) - 1 downto 8 * j);
                end if;
              end loop;

              var_hrddone_vctrl_edge:=ld_iq(C_HREG_CTRL_RDDONE_VCTRL_BIT);
              var_hrddone_trcnik_edge:=ld_iq(C_HREG_CTRL_RDDONE_TRCNIK_BIT);

            elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_DEV_CTRL, 5) then

              var_trn_start_edge  :=ld_iq(C_HREG_DEV_CTRL_DMA_START_BIT);
--              var_int_clr_edge    :=ld_iq(C_HREG_DEV_CTRL_RESERV8_BIT);
--              var_trn_rst_edge    :=ld_iq(C_HREG_DEV_CTRL_TRN_RST_BIT);
              var_dev_txd_rdy_edge:=ld_iq(C_HREG_DEV_CTRL_DRDY_BIT);

              for j in 0 to 32/8-1 loop
                if lbe_iq_l(j) = '0' then
                  v_reg_dev_ctrl( 8 * (j + 1) - 1 downto 8 * j) <= ld_iq(8 * (j + 1) - 1 downto 8 * j);
                end if;
              end loop;

            elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST0, 5) then
              for j in 0 to 32/8-1 loop
                if lbe_iq_l(j) = '0' then
                  v_reg_tst0( 8 * (j + 1) - 1 downto 8 * j) <= ld_iq(8 * (j + 1) - 1 downto 8 * j);
                end if;
              end loop;

            elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST1, 5) then
              for j in 0 to 32/8-1 loop
                if lbe_iq_l(j) = '0' then
                  v_reg_tst1( 8 * (j + 1) - 1 downto 8 * j) <= ld_iq(8 * (j + 1) - 1 downto 8 * j);
                end if;
              end loop;

            end if;
          end if;
        end if;

    i_dev_txd_rdy   <=var_dev_txd_rdy_edge;
    i_trn_start_sw  <=var_trn_start_edge;
--    i_interrupt_clr <=var_int_clr_edge;
--    i_trn_rst_sw    <=var_trn_rst_edge;
    i_hrddone_vctrl<=var_hrddone_vctrl_edge;
    i_hrddone_trcnik<=var_hrddone_trcnik_edge;

    end if;
  end process;

  process(rst,clk)
  begin
    if rst = '1' then
      usr_reg_wr <= '0';
    elsif clk'event and clk = '1' then
      usr_reg_wr <= ds_xfer and ds_write;
    end if;
  end process;

  p_out_hclk_out  <= clk;


--//----------------------------------------
--//Прерывание для ХОСТА
--//----------------------------------------
--  finto_l<='1';
  finto_l<='1';-- when v_reg_dev_ctrl(C_HREG_DEV_CTRL_RESERV2_BIT)='0' else not interrupt;

--  i_trn_dlen<=v_reg_dev_ctrl(C_HREG_DEV_CTRL_DLEN_MSB_BIT downto C_HREG_DEV_CTRL_DLEN_LSB_BIT);
--  i_trn_int_en<=v_reg_dev_ctrl(C_HREG_DEV_CTRL_RESERV2_BIT);
--
--  process(rst,clk)
--  begin
--    if rst = '1' then
--      i_trn_dlen_cnt<=(others=>'0');
--      interrupt <= '0';
--    elsif clk'event and clk = '1' then
--      if i_trn_int_en='1' then
----        if interrupt = '0' then
--          if (mem_rd='1' or mem_wr='1') then
--            if i_trn_dlen_cnt=i_trn_dlen then
--              i_trn_dlen_cnt<=(others=>'0');
--              interrupt <= '1';
--            else
--              i_trn_dlen_cnt<=i_trn_dlen_cnt+1;
--              interrupt <= '0';
--            end if;
--          end if;
----        end if;
--      else
--        i_trn_dlen_cnt<=(others=>'0');
--         interrupt <= '0';
--      end if;
--    end if;
--  end process;

end architecture;
