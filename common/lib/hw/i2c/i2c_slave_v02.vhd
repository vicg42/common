----------------------------------------------------------------------------------
-- Company: Telemix
-- Engineer: Golovachenko Victor
--
-- Create Date:    12:30:11 04/21/2007
-- Design Name:
-- Module Name:    i2c_slave_v02 - Behavioral
-- Project Name:
-- Target Devices: Spartan-3
-- Tool versions: ISE 8.2.03
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
  library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.STD_LOGIC_ARITH.ALL;
  use IEEE.STD_LOGIC_UNSIGNED.ALL;

  ---- Uncomment the following library declaration if instantiating
  ---- any Xilinx primitives in this code.
  --library UNISIM;
  --use UNISIM.VComponents.all;

  entity i2c_slave_v02 is
--  generic
--  (
--    Addres_device : integer:=16#86#
--  );
  port
  (
    Addres_device : in std_logic_vector(7 downto 0);

    --------------------------------------------------
    --I2C signals
    --------------------------------------------------
    sda : inout std_logic;
    scl : in std_logic;

    --------------------------------------------------
    --I2C Status
    --------------------------------------------------
    addr_match: out std_logic;
    i2c_header: out std_logic_vector(7 downto 0);

    --------------------------------------------------
    --Interface connection to Internal FPGA blocks
    --------------------------------------------------
    -- ExtI2C -> FPGA
    en_dout: out std_logic;
    dout   : out std_logic_vector(7 downto 0); -- data receive
    -- FPGA -> ExtI2C
    en_din : out std_logic;
    din    : in std_logic_vector(7 downto 0); -- data to transmit

    --------------------------------------------------
    clk : in std_logic;
    rst : in std_logic
  );
  end i2c_slave_v02;

  architecture Behavioral of i2c_slave_v02 is

--  constant ENABLE_N     : std_logic := '1';
--  constant START_CNT    : std_logic_vector (3 downto 0) := "0000";
  constant CNT_DONE     : std_logic_vector (3 downto 0) := "1000";
--  constant CLR_REG      : std_logic_vector (7 downto 0) := "00000000";

  constant TXAK         : std_logic := '0'; --Ask if operation write

--  constant FOUR         : integer range 0 to 10 := 4;

  -- Added to sample after rising edge
  constant C_sda_SAMPLE_WAIT   : integer := 3;--intrnl_hold_delay(C_CLK_FREQ,3333333) + 5;
                                              -- Calls the function from the iic_pkg.vhd
                                              -- returns number of register delays
                                              -- required for 300ns internal hold
                                              -- (1/2 minimum time high from IIC spec)

  type state_type is (IDLE, HEADER, ACK_HEADER, RCV_DATA, ACK_DATA,
          XMIT_DATA, WAIT_ACK);
  signal state      : state_type;

  --type scl_state_type is (scl_IDLE, START, scl_LOW_EDGE, scl_LOW, scl_HIGH_EDGE,
  --            scl_HIGH, STOP_WAIT);
  --signal scl_state, next_scl_state       : scl_state_type;

  signal scl_rin, scl_d1  : std_logic;  -- sampled version of scl
  signal scl_rin_d1       : std_logic;   -- delayed version of scl_rin
--  signal scl_cout         : std_logic;  -- combinatorial scl output
--  signal scl_cout_reg     : std_logic;  -- registered version of scl_cout
--  signal scl_not          : std_logic;   -- inverted version of scl
  signal scl_falling_edge : std_logic;   -- falling edge of scl
  signal scl_f_edg_d1     : std_logic;   -- falling edge of scl delayed one clock
  signal scl_f_edg_d2     : std_logic;   -- falling edge of scl delayed two clock
--  signal scl_f_edg_d3     : std_logic;   -- falling edge of scl delayed three clock
  signal sda_rin, sda_d1  : std_logic;  -- sampled version of sda
--  signal sda_rin_d1       : std_logic;   -- delayed version of sda_rin
--  signal sda_cout         : std_logic;  -- combinatorial sda output
--  signal sda_cout_reg     : std_logic;  -- registered version of sda_cout
--  signal sda_cout_reg_d1  : std_logic;  -- delayed sda output for arb comparison
  signal slave_sda        : std_logic;   -- sda value when slave

  signal sda_rin_ss       : std_logic; -- sda_rin for start and stop logic - Non delayed
  signal sda_rin_ss_d1    : std_logic; -- sda_rin_ss delay of 1 clk

  signal detect_start     : std_logic;   -- START condition has been detected
  signal detect_stop      : std_logic;   -- STOP condition has been detected

--  signal cnt_start        : std_logic_vector(3 downto 0);

  -- Bit counter 0 to 7
  signal bit_cnt          : std_logic_vector(3 downto 0);
  signal bit_cnt_ld, bit_cnt_en : std_logic;
--  signal bit_cnt_ld, bit_cnt_clr, bit_cnt_en : std_logic;

  -- Shift Register and the controls
--  signal shift_reg   : std_logic_vector(7 downto 0);  -- iic data shift reg
  signal shift_reg        : std_logic_vector(7 downto 0);  -- iic data shift reg
  signal shift_out        : std_logic;
--  signal shift_reg_en, shift_reg_ld, shift_reg_ld_d1   : std_logic;
  signal shift_reg_en, shift_reg_ld   : std_logic;

  signal i2c_header_temp : std_logic_vector(7 downto 0);  -- I2C header register
--  signal i2c_header       : std_logic_vector(7 downto 0);  -- I2C header register
  signal i2c_header_en, i2c_header_ld : std_logic;
--  signal i2c_shiftout     : std_logic;

  signal addr_match_temp       : std_logic;

--  signal reg_clr          : std_logic_vector(7 downto 0);

  signal dout_temp : std_logic_vector(7 downto 0);
  signal en_dout_temp: std_logic;


  signal sda_trig_delay : std_logic_vector(0 to C_sda_SAMPLE_WAIT);

  signal adr  : std_logic_vector(7 downto 0);

--  MAIN
  begin


  adr<=Addres_device;--CONV_STD_LOGIC_VECTOR(Addres_device ,8);
   addr_match_temp <= '1' when i2c_header_temp(7 downto 1) = adr(7 downto 1) else '0';
  addr_match<=addr_match_temp;

  sda <= '0' when slave_sda = '0' else 'Z';

-- ************************  Slave and Master sda ************************
  slv_mas_sda: process(rst, clk)
  begin
    if rst = '1' then
      slave_sda <= '1';
    elsif clk'event and clk = '1' then

      -- For the slave sda, address match (aas_i) only has to be checked when
      -- state is ACK_HEADER because state
      -- machine will never get to state XMIT_DATA or ACK_DATA
      -- unless address match is a one.

      if (addr_match_temp = '1' and state = ACK_HEADER) or
        (state = ACK_DATA) then
        slave_sda <= TXAK;
      elsif (state = XMIT_DATA) then
        slave_sda <= shift_out;
      else
        slave_sda <= '1';
      end if;
    end if;
  end process;

-- ************************  Input Registers Process **************************
-- This process samples the incoming sda and scl with the system clock

  input_regs: process(clk,rst)
  begin
    if rst = '1' then
      sda_rin            <= '1';
  --      sda_hold_delay(0)  <= '1';
--      sda_rin_d1         <= '1';
      sda_d1             <= '1';
      scl_rin            <= '1';
      scl_rin_d1         <= '1';
      scl_d1             <= '1';
--      sda_cout_reg_d1    <= '1';

      sda_rin_ss         <= '1';
      sda_rin_ss_d1      <= '1';

    elsif clk'event and clk = '1' then

      -- the following if, then, else clauses are used
      -- because scl may equal 'H' or '1'
      if scl = '0' then
        scl_d1 <= '0';
      else
        scl_d1 <= '1';
      end if;
      if sda = '0' then
        sda_d1 <= '0';
      else
        sda_d1 <= '1';
      end if;
      scl_rin <= scl_d1; -- double buffer async input

      -- Start: signals used to detect start and stop conditions
      sda_rin_ss            <= sda_d1;      --Non 300ns delayed version for start and stop detection
      sda_rin_ss_d1         <= sda_rin_ss;  --1 clk delay
      -- End: signals used to detect start and stop conditions

  --      sda_rin <= sda_d1; -- double buffer async input
  --      sda_hold_delay(0)     <= sda_d1;
  --      sda_rin <= sda_hold_delay(C_INTRNL_HOLD_CNT); -- delay sda_rin to find edges
  --         (above line created false starts)
  --      sda_rin <= sda_hold_delay(C_INTRNL_HOLD_CNT) or sda_hold_delay(0); -- delay sda_rin to find edges
  --         (above line created false starts unless DATA_SETUP was change from 250ns to 500ns)


      --  This portion of the process was added for correcting the IIC hold
      --  specifications.  It detects if the IIC is a master or slave receiver and if
      --  it is, sda_d1 is clocked to sda_rin 300ns after the rising edge of scl_rin.
      --  Gen_stop is used to allow the last transition on sda_rin when scl_rin is low.
      --  To ensure the proper data was received, examine sda_rin and shift_reg_en.
      if (state = RCV_DATA or state = ACK_DATA) and
         (addr_match_temp = '1' and i2c_header_temp(0) = '0') then--slave rcv
  --         if gen_stop = '1' then
  --              sda_rin <= sda_d1;--needed to allow last transition of sda when scl is low
  --                                --else scl_state machine hangs
        if scl_d1 = '1' and sda_trig_delay(C_sda_SAMPLE_WAIT) = '1' then
          sda_rin <= sda_d1; -- sample sda_rin @ 300ns after clk edge
        else
          sda_rin <= sda_rin;
        end if;
      else
        sda_rin <= sda_d1; -- sample sda_rin @ 300ns after clk edge
      end if;


--      sda_rin_d1 <= sda_rin; -- delay sda_rin to find edges
      scl_rin_d1 <= scl_rin; -- delay scl_rin to find edges
--      sda_cout_reg_d1 <= sda_cout_reg;
    end if;
  end process;

-------------------------------------------------------------------------------
-- scl_FALLING_EDGE_PROCESS
-------------------------------------------------------------------------------
-- This process generates a 1 clk wide pulse when a faling edge of scl is
-- detected
-------------------------------------------------------------------------------
  scl_FALLING_EDGE_PROCESS:process (clk)
  begin
    if clk'event and clk = '1' then
      if rst = '1' then
        scl_falling_edge  <= '0';
        scl_f_edg_d1      <= '0';
        scl_f_edg_d2      <= '0';
--        scl_f_edg_d3      <= '0';
      else
         scl_falling_edge <= (not scl_rin) and scl_rin_d1;
         scl_f_edg_d1     <= scl_falling_edge;
         scl_f_edg_d2     <= scl_f_edg_d1;
--         scl_f_edg_d3     <= scl_f_edg_d2;
      end if;
    end if;
  end process;


-------------------------------------------------------------------------------
-- This process creates a one pulse wide trigger to delay the data sample of sda_rin
-- ~300ns from the rising edge of scl_d1
-------------------------------------------------------------------------------
  TRIGGER_ENABLE:process(clk,rst)
  begin
      if rst = '1' then
        sda_trig_delay  <= (others => '0');
      elsif clk'event and clk = '1' then
        if (scl_rin = '1' and scl_rin_d1 = '0') then   -- rising edge
          sda_trig_delay(0)  <= '1';
        else
          sda_trig_delay(0)  <= '0';
        end if;

        sda_trig_delay(1 to C_sda_SAMPLE_WAIT) <= sda_trig_delay(0 to C_sda_SAMPLE_WAIT-1);
      end if;
  end process;

-- ************************  START/STOP Detect Process ************************
-- This process detects the start and stop conditions.
-- by finding the edge of sda_rin and the value of scl.

  start_det: process(clk)
  begin
    if clk'event and clk = '1' then
      if rst = '1' or state = HEADER then
        detect_start <= '0';
  --      elsif sda_rin = '0' and sda_rin_d1 /= '0' then
      elsif sda_rin_ss = '0' and sda_rin_ss_d1 /= '0' then

        if scl_rin /= '0' then
          detect_start <= '1';
        else
          detect_start <= '0';
        end if;
      end if;
    end if;
  end process;

  stop_det: process(clk)
  begin
    if clk'event and clk = '1' then
      if rst = '1' or detect_start = '1' then
        detect_stop <= '0';
  --      elsif sda_rin /= '0' and sda_rin_d1 = '0' then
      elsif sda_rin_ss /= '0' and sda_rin_ss_d1 = '0' then
        if scl_rin /= '0' then
          detect_stop <= '1';
        else
          detect_stop <= '0';
        end if;

      end if;
    end if;
  end process;

-- ************************  Main State Machine Process ************************
-- The following process contains the main I2C state machine for both master and
-- slave modes. This state machine is clocked on the falling edge of scl.
-- DETECT_STOP must stay as an asynchronous rst because once STOP has been
-- generated, scl clock stops.

  state_machine: process (clk)
  begin

    if clk'event and clk = '1' then

      if rst = '1' or detect_stop = '1' then
        state <= IDLE;

      elsif scl_f_edg_d2 = '1' then

        case state is

        ------------- IDLE STATE -------------
          when IDLE =>
            if detect_start = '1' then
              state <= HEADER;
            end if;

        ------------- HEADER STATE -------------
          when HEADER =>
            if bit_cnt = CNT_DONE then
              state <= ACK_HEADER;
            end if;

        ------------- ACK_HEADER STATE -------------
          when ACK_HEADER =>

            if sda_rin = '0' then
                  -- ack has been received, check for master/slave
              if addr_match_temp = '1' then
                        -- addressed slave, so check I2C_HEADER(0) for direction
                if i2c_header_temp(0) = '0' then
                  -- receive mode
                  state <= RCV_DATA;
                else
                  -- transmit mode
                  state <= XMIT_DATA;
                end if;
              else
                -- not addressed, go back to IDLE
                state <= IDLE;
              end if;
            else
            -- no ack received, stop
              state <= IDLE;
            end if;

        ------------- RCV_DATA State --------------
          when RCV_DATA =>

            -- check for repeated start
            if (detect_start = '1') then
              state <= HEADER;
            elsif bit_cnt = CNT_DONE then
              if addr_match_temp = '0' then
                state <= IDLE;
              else
                -- Send an acknowledge
                state <= ACK_DATA;
              end if;
            end if;


        ------------ XMIT_DATA State --------------
          when XMIT_DATA =>

            -- check for repeated start
            if (detect_start = '1') then
              state <= HEADER;
            elsif bit_cnt = CNT_DONE then
              -- Wait for acknowledge
              state <= WAIT_ACK;
            end if;


        ------------- ACK_DATA State --------------
          when ACK_DATA =>

            if sda_rin = '0' then
              state <= RCV_DATA; -- a read of DRR has occurred
            else
              state <= ACK_DATA;
            end if;

        ------------- WAIT_ACK State --------------
          when WAIT_ACK =>

            if (sda_rin = '0') then
              state <= XMIT_DATA;
            else
              -- no ack received, generate a stop and return
              -- to IDLE state
              state <= IDLE;
            end if;

        end case;
      end if;
    end if;
  end process;

-- ************************  Bit Counter  ************************
  process(clk, rst)
  begin
    if (rst = '1') then
      bit_cnt <= (others => '0');

    elsif clk'event and clk = '1' then
      -- Load in start value
      if (bit_cnt_ld = '1') then
        bit_cnt <= (others=>'0');
      -- If count enable is high
      elsif bit_cnt_en = '1' then
        bit_cnt <= bit_cnt + 1;
      else
        bit_cnt <= bit_cnt;
      end if;
    end if;
  end process;

   -- Bit Counter control lines
  bit_cnt_en_cntl:process(clk)
  begin
    if clk'event and clk = '1' then
      if rst = '1' then
        bit_cnt_en <= '0';
      elsif (state = HEADER    and scl_falling_edge = '1')
        or (state = RCV_DATA  and scl_falling_edge = '1')
        or (state = XMIT_DATA and scl_falling_edge = '1') then
        bit_cnt_en <= '1';
      else
        bit_cnt_en <= '0';
      end if;
    end if;
  end process;

   bit_cnt_ld <= '1' when (state = IDLE) or (state = ACK_HEADER)
                      or (state = ACK_DATA)
                      or (state = WAIT_ACK)
                      or (detect_start = '1') else '0';

-- ************************  I2C Header Shift Register ************************
   -- Header/Address Shift Register
  process(clk, rst)
  begin
    if (rst = '1') then
      i2c_header_temp <= (others => '0');

    elsif clk'event and clk = '1' then
      -- Load data
      if (i2c_header_ld = '1') then
        i2c_header_temp <= (others=>'0');--reg_clr;
      -- If shift enable is high
      elsif i2c_header_en = '1' then
      -- Shift the data
        i2c_header_temp <= i2c_header_temp(6 downto 0) & sda_rin;

      end if;
    end if;
  end process;

--  i2c_shiftout <= i2c_header_temp(7);
  i2c_header <= i2c_header_temp;

  i2cheader_reg_ctrl: process(clk, rst)
  begin
    if rst = '1' then
      i2c_header_en <= '0';
    elsif clk'event and clk = '1' then
--      if (detect_start = '1' and (scl_rin = '0' and scl_rin_d1 = '1'))
--        or (state = HEADER and  (scl_rin = '0' and scl_rin_d1 = '1'))  then
      if (detect_start = '1' and scl_falling_edge='1')
        or (state = HEADER and scl_falling_edge='1')  then
        i2c_header_en <= '1';
      else
        i2c_header_en <= '0';
      end if;
    end if;
  end process;

   i2c_header_ld <= '0';

-- ************************  I2C Data Shift Register ************************
  process(clk, rst)
  begin
    if (rst = '1') then
      shift_reg <= (others => '0');

    elsif clk'event and clk = '1' then
      -- Load data
      if (shift_reg_ld = '1') then
        shift_reg <= din;
      -- If shift enable is high
      elsif shift_reg_en = '1' then
      -- Shift the data
        shift_reg <= shift_reg(6 downto 0) & sda_rin;

      end if;
    end if;
  end process;

  i2cdata_reg_ctrl: process(clk, rst)
  begin
    if rst = '1' then
      shift_reg_en <= '0';
      shift_reg_ld <= '0';
      en_dout<='0';
      en_din <= '0';
      dout_temp <= (others=>'0');
      en_dout_temp<='0';

    elsif clk'event and clk = '1' then

      if((state=RCV_DATA and (scl_rin='0' and scl_rin_d1='1' and detect_start='0'))
          or (state = XMIT_DATA and scl_f_edg_d2 = '1' and detect_start = '0' )) then
        shift_reg_en <= '1';
      else
        shift_reg_en <= '0';
      end if;

--      if (state = ACK_HEADER and i2c_header_temp(0) = '1' )
--         or (state = RCV_DATA and detect_start = '1' )then
      if i2c_header_temp(0) = '1' and sda_rin='0' and
      (state = ACK_HEADER or state = WAIT_ACK )then
        shift_reg_ld <= '1';
      else
        shift_reg_ld <= '0';
      end if;

      if i2c_header_temp(0) = '1' and sda_rin='0' and sda_trig_delay(C_sda_SAMPLE_WAIT) = '1' and
      (state = ACK_HEADER or state = WAIT_ACK )then
        en_din <= '1';
      else
        en_din <= '0';
      end if;

      if(state=ACK_DATA and (scl_rin='0' and scl_rin_d1='1' and detect_start='0') ) then
        en_dout_temp<='1';
        dout_temp <= shift_reg;
      else
        en_dout_temp<='0';
      end if;

      en_dout<=en_dout_temp;
    end if;
  end process;

--  en_din<=shift_reg_ld;

  shift_out <= shift_reg(7);
--  shift_reg <= shift_reg;
--  dout <= shift_reg;
  dout <= dout_temp;

--  END MAIN
  end Behavioral;

