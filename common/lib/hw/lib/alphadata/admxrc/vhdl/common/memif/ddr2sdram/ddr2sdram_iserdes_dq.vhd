--
-- ddr2sdram_iserdes_dq.vhd - ISERDES instance for Virtex-4 / Virtex-5 DDR-II
--                            SDRAM interface
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;

-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
library std;
use std.textio.all;
-- synopsys translate_on

library work;
use work.memif.all;

entity ddr2sdram_iserdes_dq is
    port (
        clk2x      : in  std_logic;
        dlysr      : in  std_logic;
        dlyce      : in  std_logic;
        dlyinc     : in  std_logic;
        sr         : in  std_logic;
        ce         : in  std_logic;
        d          : in  std_logic;
        dqs        : in  std_logic;
        q          : out std_logic_vector(3 downto 0);
        o          : out std_logic);
end entity;

architecture mixed of ddr2sdram_iserdes_dq is

    signal dqs_delayed : std_logic;
    signal d_delayed : std_logic;

    signal logic0 : std_logic;
    signal logic1 : std_logic;
    signal logicx : std_logic;

--    component ISERDES
--        generic(
--            BITSLIP_ENABLE : boolean := false;     -- (TRUE, FALSE)
--            DATA_RATE      : string  := "DDR";     -- (SDR, DDR)
--            DATA_WIDTH     : integer := 4;         -- (2, 3, 4, 5, 6, 7, 8, 10)
--            INTERFACE_TYPE : string  := "MEMORY";  -- (MEMORY, NETWORKING)
--            IOBDELAY       : string  := "NONE";    -- (NONE, IBUF, IFD, BOTH)
--            IOBDELAY_TYPE  : string  := "DEFAULT"; -- (DEFAULT, FIXED, VARIABLE)
--            IOBDELAY_VALUE : integer := 0;         -- (0 to 63)
--            NUM_CE         : integer := 2;         -- (1, 2)
--            SERDES_MODE    : string  := "MASTER"); -- (MASTER, SLAVE)
--        port(
--            O              : out std_logic;
--            Q1             : out std_logic;
--            Q2             : out std_logic;
--            Q3             : out std_logic;
--            Q4             : out std_logic;
--            Q5             : out std_logic;
--            Q6             : out std_logic;
--            SHIFTOUT1      : out std_logic;
--            SHIFTOUT2      : out std_logic;
--            BITSLIP        : in  std_logic;
--            CE1            : in  std_logic;
--            CE2            : in  std_logic;
--            CLK            : in  std_logic;
--            CLKDIV         : in  std_logic;
--            D              : in  std_logic;
--            DLYCE          : in  std_logic;
--            DLYINC         : in  std_logic;
--            DLYRST         : in  std_logic;
--            OCLK           : in  std_logic;
--            REV            : in  std_logic;
--            SHIFTIN1       : in  std_logic;
--            SHIFTIN2       : in  std_logic;
--            SR             : in  std_logic);
--    end component;

    component IDELAY
    generic (
      IOBDELAY_TYPE  : string  :="VARIABLE"; -- "FIXED" or "VARIABLE"
      IOBDELAY_VALUE : integer := 0);        -- (0 to 63)
    port (
      O   : out std_logic;
      C   : in  std_logic;
      CE  : in  std_logic;
      I   : in  std_logic;
      INC : in  std_logic;
      RST : in  std_logic);
    end component;
    
    component ISERDES_NODELAY
        generic(
          BITSLIP_ENABLE : boolean := false;     -- (TRUE, FALSE)
          DATA_RATE      : string  := "DDR";     -- (SDR, DDR)
          DATA_WIDTH     : integer := 4;         -- (2, 3, 4, 5, 6, 7, 8, 10)
          INTERFACE_TYPE : string  := "MEMORY";  -- (MEMORY, NETWORKING)
          NUM_CE         : integer := 2;         -- (1, 2)
          SERDES_MODE    : string  := "MASTER"); -- (MASTER, SLAVE)
        port(
            Q1             : out std_logic;
            Q2             : out std_logic;
            Q3             : out std_logic;
            Q4             : out std_logic;
            Q5             : out std_logic;
            Q6             : out std_logic;
            SHIFTOUT1      : out std_logic;
            SHIFTOUT2      : out std_logic;
            BITSLIP        : in  std_logic;
            CE1            : in  std_logic;
            CE2            : in  std_logic;
            CLK            : in  std_logic;
            CLKB           : in  std_logic;
            CLKDIV         : in  std_logic;
            D              : in  std_logic;
            OCLK           : in  std_logic;
            RST            : in  std_logic;
            SHIFTIN1       : in  std_logic;
            SHIFTIN2       : in  std_logic);
    end component;
    
    attribute BITSLIP_ENABLE : boolean;
    attribute BITSLIP_ENABLE of U0 : label is false;
    attribute DATA_RATE : string;
    attribute DATA_RATE of U0 : label is "DDR";
    attribute DATA_WIDTH : integer;
    attribute DATA_WIDTH of U0 : label is 4;
    attribute INTERFACE_TYPE : string;
    attribute INTERFACE_TYPE of U0 : label is "MEMORY";
    attribute NUM_CE : integer;
    attribute NUM_CE of U0 : label is 2;
    attribute SERDES_MODE : string;
    attribute SERDES_MODE of U0 : label is "MASTER";

--    attribute IOBDELAY : string;
--    attribute IOBDELAY of U0 : label is "IFD";
--    attribute IOBDELAY_TYPE : string;
--    attribute IOBDELAY_TYPE of U0 : label is "VARIABLE";
--    attribute IOBDELAY_VALUE : integer;
--    attribute IOBDELAY_VALUE of U0 : label is 0;
    
begin

    logic0 <= '0';
    logic1 <= '1';
    logicx <= '-';

--    U0 : ISERDES
--        generic map(
--            IOBDELAY => "IFD",
--            IOBDELAY_TYPE => "VARIABLE",
--            NUM_CE => 2)
--        port map(
--            O => o,
--            Q1 => q(3),
--            Q2 => q(2),
--            Q3 => q(1),
--            Q4 => q(0),
--            Q5 => open,
--            Q6 => open,
--            SHIFTOUT1 => open,
--            SHIFTOUT2 => open,
--            BITSLIP => logic0,
--            CE1 => ce,
--            CE2 => ce,
--            CLK => dqs,
--            CLKDIV => clk2x,
--            D => d,
--            DLYRST => dlysr,
--            DLYCE => dlyce,
--            DLYINC => dlyinc,
--            OCLK => clk2x,
--            REV => logic0,
--            SHIFTIN1 => logic0,
--            SHIFTIN2 => logic0,
--            SR => sr);

  --// add 21/12/2009 - becouse ISE-11.2 component ISERDES not supported
  o<=d_delayed;--d;
  
  U0_delay : IDELAY
  generic map (
    IOBDELAY_TYPE  => "VARIABLE", -- "FIXED" or "VARIABLE"
    IOBDELAY_VALUE => 0)          -- Any value from 0 to 63
  port map (
    O   => d_delayed, -- 1-bit output
    C   => clk2x,     -- 1-bit clock input
    CE  => dlyce,     -- 1-bit clock enable input
    I   => d,         -- 1-bit data input
    INC => dlyinc,    -- 1-bit increment input
    RST => dlysr      -- 1-bit reset input
  );
  
  U0 : ISERDES_NODELAY
  generic map (
    BITSLIP_ENABLE => FALSE,    -- TRUE/FALSE to enable bitslip controller
                                --    Must be "FALSE" in interface type is "MEMORY" 
    DATA_RATE => "DDR",         -- Specify data rate of "DDR" or "SDR" 
    DATA_WIDTH => 4,            -- Specify data width - 
                                --    NETWORKING SDR: 2, 3, 4, 5, 6, 7, 8 : DDR 4, 6, 8, 10
                                --    MEMORY SDR N/A : DDR 4
    INTERFACE_TYPE => "MEMORY", -- Use model - "MEMORY" or "NETWORKING" 
    NUM_CE => 2,                -- Define number or clock enables to an integer of 1 or 2
    SERDES_MODE => "MASTER")    -- Set SERDES mode to "MASTER" or "SLAVE" 
  port map (
    Q1 => q(3),         -- 1-bit registered SERDES output
    Q2 => q(2),         -- 1-bit registered SERDES output
    Q3 => q(1),         -- 1-bit registered SERDES output
    Q4 => q(0),         -- 1-bit registered SERDES output
    Q5 => open,         -- 1-bit registered SERDES output
    Q6 => open,         -- 1-bit registered SERDES output
    SHIFTOUT1 => open,  -- 1-bit cascade Master/Slave output
    SHIFTOUT2 => open,  -- 1-bit cascade Master/Slave output
    BITSLIP => logic0,  -- 1-bit Bitslip enable input
    CE1 => ce,          -- 1-bit clock enable input
    CE2 => ce,          -- 1-bit clock enable input
    CLK => dqs,         -- 1-bit master clock input
    CLKB => clk2x,      -- 1-bit secondary clock input for DATA_RATE=DDR
    CLKDIV => clk2x,    -- 1-bit divided clock input
    D => d_delayed,--d,             -- 1-bit data input, connects to IODELAY or input buffer
    OCLK => clk2x,      -- 1-bit fast output clock input
    RST => sr,          -- 1-bit asynchronous reset input
    SHIFTIN1 => logic0, -- 1-bit cascade Master/Slave input
    SHIFTIN2 => logic0  -- 1-bit cascade Master/Slave input
  );
  
end mixed;
