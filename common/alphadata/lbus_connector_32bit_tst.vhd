
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

entity lbus_connector_32bit_tst is
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
lad                        : inout std_logic_vector(C_FHOST_DBUS-1 downto 0);--(31 downto 0);
lbe_l                      : in    std_logic_vector(C_FHOST_DBUS/8-1 downto 0);--(3 downto 0);
lads_l                     : in    std_logic;
lwrite                     : in    std_logic;
lblast_l                   : in    std_logic;
lbterm_l                   : inout std_logic;
lready_l                   : inout std_logic;
fholda                     : in    std_logic;
finto_l                    : out   std_logic;

--------------------------------------------------
--System
--------------------------------------------------
clk                        : in    std_logic;
p_in_rst_n                 : in    std_logic
);
end entity;

architecture mixed of lbus_connector_32bit_tst is

constant C_MEMCTRL_CFG_MODE_REG_COUNT  : integer:=3;--//32 bit

  signal rst                  : std_logic;

  --
  -- Local bus signals in and out
  --
  signal la_i                 : std_logic_vector(C_FHOST_DBUS-1 downto 0);--(31 downto 0);
  signal ld_i                 : std_logic_vector(C_FHOST_DBUS-1 downto 0);--(31 downto 0);
  signal ld_o                 : std_logic_vector(C_FHOST_DBUS-1 downto 0);--(31 downto 0);
  signal ld_oe_l              : std_logic_vector(C_FHOST_DBUS-1 downto 0);--(31 downto 0);
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
  signal ld_iq                : std_logic_vector(C_FHOST_DBUS-1 downto 0);--(31 downto 0);
  signal lbe_iq_l             : std_logic_vector(C_FHOST_DBUS/8-1 downto 0);--(3 downto 0);

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



  --//мои сигналы
--  signal mem_reg_bar            : std_logic; --
  signal vereskm_reg_bar        : std_logic; --
  signal mem_data_bar_detect    : std_logic; --
  signal vereskm_reg_bar_detect : std_logic; --//Обнаружен BAR записи/чтения данных регистров проекта VERESK-M

  signal vereskm_reg_adr        : std_logic_vector(6 downto 0); --//Адреса регистров проекта VERESK-M
  signal usr_reg_wr             : std_logic;
  signal v_reg_fpga_firmware    : std_logic_vector(15 downto 0);
  signal v_reg_tst0             : std_logic_vector(C_FHOST_DBUS-1 downto 0);
--  signal v_reg_tst1             : std_logic_vector(C_FHOST_DBUS-1 downto 0);



begin

--  lad  <=(others=>'Z');--      : inout std_logic_vector(C_FHOST_DBUS-1 downto 0);--(31 downto 0);
--  --lbe_l                      : in    std_logic_vector(C_FHOST_DBUS/8-1 downto 0);--(3 downto 0);
--  --lads_l                     : in    std_logic;
--  --lwrite                     : in    std_logic;
--  --lblast_l                   : in    std_logic;
--  lbterm_l <='Z';--'1' when lblast_l='1' else             : inout std_logic;
--  lready_l <='Z';--'1' when lblast_l='1' else             : inout std_logic;
--  --fholda                     : in    std_logic;
--  finto_l  <='0' when lads_l='0' and lwrite='0' and lblast_l='0' and fholda='0' and lbe_l="0000" else '1';

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
--  mem_reg_bar     <=not la_i(21) and not la_i(7);
  vereskm_reg_bar <=not la_i(21) and     la_i(7);
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
            vereskm_reg_adr(6 downto 0) <= la_i(6 downto 0);--la_i(7 downto 3);
          else
            vereskm_reg_bar_detect <= '0';
          end if;

        end if;
    end if;
  end process;


  --
  -- Generate the outbound local bus data, by multiplexing either a
  -- register or a memory bank data bus onto the outbound local bus data.
  --
  gen_ld_o : process(rst, clk)
      variable lo : std_logic_vector(31 downto 0);
  begin
    if rst = '1' then
      ld_o <= (others => '0');
    elsif clk'event and clk = '1' then
    --//32BIT
        lo := (others => '0');

        --//Чтение данных регистров
        --//BAR - vereskm_reg_bar_detect
        if vereskm_reg_bar_detect='1' then
          if vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_FIRMWARE, 5)    then lo(v_reg_fpga_firmware'high downto 0):= v_reg_fpga_firmware;
          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST0, 5)     then lo(v_reg_tst0'high downto 0):= v_reg_tst0;
--          elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST1, 5)     then lo(v_reg_tst1'high downto 0):= v_reg_tst1;
          end if;
        end if;

        ld_o <= lo;
    end if;
  end process;


  --//Запись в мои регистры
  process(rst,clk)
  begin
    if rst = '1' then
      v_reg_tst0<=(others=>'0');
--      v_reg_tst1<=(others=>'0');

    elsif clk'event and clk = '1' then

        if usr_reg_wr='1' then
          if vereskm_reg_bar_detect='1' then
            if vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST0, 5) then
              for j in 0 to C_FHOST_DBUS/8-1 loop
                if lbe_iq_l(j) = '0' then
                  v_reg_tst0( 8 * (j + 1) - 1 downto 8 * j) <= ld_iq(8 * (j + 1) - 1 downto 8 * j);
                end if;
              end loop;

--            elsif vereskm_reg_adr(6 downto 2)=CONV_STD_LOGIC_VECTOR(C_HREG_TST1, 5) then
--              for j in 0 to C_FHOST_DBUS/8-1 loop
--                if lbe_iq_l(j) = '0' then
--                  v_reg_tst1( 8 * (j + 1) - 1 downto 8 * j) <= ld_iq(8 * (j + 1) - 1 downto 8 * j);
--                end if;
--              end loop;

            end if;
          end if;
        end if;

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

  v_reg_fpga_firmware<=CONV_STD_LOGIC_VECTOR(C_FPGA_FIRMWARE_VERSION, v_reg_fpga_firmware'length);

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


--//Управление модулем dssm : plxdssm.vhd
  ds_stop  <= not mem_data_bar_detect;
  ds_ready <= not mem_data_bar_detect;



--//----------------------------------------
--//Прерывание для ХОСТА
--//----------------------------------------
  finto_l<='1';

end architecture;
