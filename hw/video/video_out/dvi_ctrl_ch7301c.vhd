-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.09.2012 16:10:45
-- Module Name : dvi_ctrl
--
-- Назначение/Описание :
--
-- DVI OUT: 1024x768@70MHz (PixClk=75MHz)
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.i2c_core_pkg.all;

entity dvi_ctrl is
generic(
G_DBG : string := "OFF";
G_SIM : string := "OFF"
);
port(
p_out_err     : out   std_logic;

--VIN
p_in_vdi      : in    std_logic_vector(31 downto 0);
p_out_vdi_rd  : out   std_logic;
p_out_vdi_clk : out   std_logic;

--VOUT
p_out_clk     : out   std_logic_vector(1 downto 0);
p_out_vd      : out   std_logic_vector(11 downto 0);
p_out_vde     : out   std_logic;--Video data enable
p_out_hs      : out   std_logic;--Sync
p_out_vs      : out   std_logic;

--I2C
p_inout_sda   : inout std_logic;
p_inout_scl   : inout std_logic;

--Технологический
p_in_tst      : in    std_logic_vector(31 downto 0);
p_out_tst     : out   std_logic_vector(31 downto 0);

--System
p_in_clk      : in    std_logic; --100MHz!!!!
p_in_rst      : in    std_logic
);
end dvi_ctrl;

architecture behavioral of dvi_ctrl is

constant CI_CLKIN_FREQ   : natural := 100000000;
constant CI_I2C_BAUD     : natural := 100000;
constant CI_I2C_ADEV     : std_logic_vector(6 downto 0):="1110110";-- =76h

constant CI_REG_WR_DLY   : integer:=selval(50000000/2, 1, strcmp(G_SIM, "OFF"));--250ms для p_in_clk=100MHz

constant CI_VID : std_logic_vector(7 downto 0):="10010101";
constant CI_DID : std_logic_vector(7 downto 0):="00010111";

--Register Map:
constant CI_REG_VID    : std_logic_vector(7 downto 0):='1'&CONV_STD_LOGIC_VECTOR(16#4A#, 7);
constant CI_REG_DID    : std_logic_vector(7 downto 0):='1'&CONV_STD_LOGIC_VECTOR(16#4B#, 7);

--1024x768@70MHz (PixClk=75MHz)
Type TReg is array (0 to 5) of std_logic_vector(15 downto 0);
constant CI_REG_ARRAY : TReg := (
--            REG ADR                    |             REG DATA
('1' & CONV_STD_LOGIC_VECTOR(16#1F#, 7) & CONV_STD_LOGIC_VECTOR(16#80#, 8)), --Input Data Format Register (IDF)
('1' & CONV_STD_LOGIC_VECTOR(16#49#, 7) & CONV_STD_LOGIC_VECTOR(16#C0#, 8)), --Power Management Register
('1' & CONV_STD_LOGIC_VECTOR(16#21#, 7) & CONV_STD_LOGIC_VECTOR(16#09#, 8)), --DAC Control Register
('1' & CONV_STD_LOGIC_VECTOR(16#33#, 7) & CONV_STD_LOGIC_VECTOR(16#06#, 8)), --DVI PLL Charge Pump Control Register
('1' & CONV_STD_LOGIC_VECTOR(16#34#, 7) & CONV_STD_LOGIC_VECTOR(16#26#, 8)), --DVI PLL Divider Register
('1' & CONV_STD_LOGIC_VECTOR(16#36#, 7) & CONV_STD_LOGIC_VECTOR(16#A0#, 8))  --DVI PLL Supply Control Register
);

component i2c_core_master
generic(
G_CLK_FREQ : natural := 25000000;
G_BAUD     : natural := 100000;
G_DBG      : string:="OFF";
G_SIM      : string:="OFF"
);
port(
p_in_cmd    : in    std_logic_vector(2 downto 0);
p_in_start  : in    std_logic;
p_out_done  : out   std_logic;
p_in_txack  : in    std_logic;
p_out_rxack : out   std_logic;

p_in_txd    : in    std_logic_vector (7 downto 0);
p_out_rxd   : out   std_logic_vector (7 downto 0);

--I2C
p_inout_sda : inout std_logic;
p_inout_scl : inout std_logic;

--Технологический
p_in_tst    : in    std_logic_vector(31 downto 0);
p_out_tst   : out   std_logic_vector(31 downto 0);

--System
p_in_clk    : in    std_logic;
p_in_rst    : in    std_logic
);
end component;

component dvi_ctrl_dcm
port(
p_out_rst     : out   std_logic;
p_out_gclk    : out   std_logic_vector(0 downto 0);

--System
p_in_clk      : in    std_logic;
p_in_rst      : in    std_logic
);
end component;

component dvi_ctrl_ddr_o
port(
Q  : out   std_logic;
D1 : in    std_logic;
D2 : in    std_logic;
CE : in    std_logic;
C  : in    std_logic;
R  : in    std_logic;
S  : in    std_logic
);
end component;

type TRegWR_state is (
S_IDLE,
S_REG_VID,
S_REG_SET,
S_REG_DONE,
S_DONE
);
signal fsm_reg_cs : TRegWR_state;

type TCore_ctrl_state is (
S_IDLE,
S_DAB_WR,
S_DAB_RD,
S_RAB,
S_RAB_DONE,
S_TXD,
S_TXD_DONE,
S_RXD,
S_RXD_DONE,
S_RESTART,
S_ERR
);
signal fsm_core_cs : TCore_ctrl_state;

signal i_reg_cnt             : std_logic_vector(3 downto 0);
signal i_reg_adr             : std_logic_vector(7 downto 0);
signal i_reg_dat             : std_logic_vector(7 downto 0);
signal i_reg_wr_start        : std_logic;
signal i_reg_wr              : std_logic;
signal i_reg_wr_dly          : std_logic_vector(31 downto 0);
signal i_reg_wr_done         : std_logic;
signal i_reg_wr_err          : std_logic;

signal i_core_cmd            : std_logic_vector(2 downto 0);
signal i_core_start          : std_logic;
signal i_core_done           : std_logic;
signal i_core_txack          : std_logic;
signal i_core_rxack          : std_logic;
signal i_core_err            : std_logic;
signal i_core_txd            : std_logic_vector(7 downto 0);
signal i_core_rxd            : std_logic_vector(7 downto 0);

signal i_dvi_rst             : std_logic;
signal i_dvi_de              : std_logic;
signal i_dvi_hs             : std_logic;
signal i_dvi_vs              : std_logic;
signal i_dvi_ha              : std_logic;
signal i_dvi_va              : std_logic;
signal i_dvi_d0              : std_logic_vector(11 downto 0);
signal i_dvi_d1              : std_logic_vector(11 downto 0);

signal i_vga_xcnt            : std_logic_vector(15 downto 0);
signal i_vga_ycnt            : std_logic_vector(15 downto 0);
signal i_vga_hs_e            : std_logic_vector(i_vga_xcnt'range);--sync end
signal i_vga_ha_b            : std_logic_vector(i_vga_xcnt'range);--active begin
signal i_vga_ha_e            : std_logic_vector(i_vga_xcnt'range);--active end
signal i_vga_hend            : std_logic_vector(i_vga_xcnt'range);--line end
signal i_vga_vs_e            : std_logic_vector(i_vga_ycnt'range);
signal i_vga_va_b            : std_logic_vector(i_vga_ycnt'range);
signal i_vga_va_e            : std_logic_vector(i_vga_ycnt'range);
signal i_vga_vend            : std_logic_vector(i_vga_ycnt'range);--frame end

signal i_clk_out             : std_logic_vector(0 downto 0);
signal g_clk_pix             : std_logic;

signal i_green               : std_logic_vector(7 downto 0);
signal i_red                 : std_logic_vector(7 downto 0);
signal i_blue                : std_logic_vector(7 downto 0);

signal tst_core_out          : std_logic_vector(31 downto 0);
signal tst_fms_cs            : std_logic_vector(3 downto 0);
signal tst_fms_cs_dly        : std_logic_vector(3 downto 0);
signal tst_dvi_de            : std_logic;

attribute keep : string;
attribute keep of g_clk_pix : signal is "true";

--MAIN
begin


------------------------------------
--Технологические сигналы
------------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
process(p_in_rst, p_in_clk)
begin
  if p_in_rst='1' then
    p_out_tst(1 downto 0) <= (others=>'0');
    tst_dvi_de <= '0';
    tst_fms_cs_dly <= (others=>'0');

  elsif rising_edge(p_in_clk) then
    tst_dvi_de <= i_dvi_de;
    tst_fms_cs_dly <= tst_fms_cs;

    p_out_tst(0) <= tst_dvi_de;
    p_out_tst(1) <= tst_core_out(0) or OR_reduce(tst_fms_cs_dly);

  end if;
end process;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_core_cs=S_DAB_WR        else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_core_cs=S_DAB_RD        else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_core_cs=S_RAB           else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_core_cs=S_RAB_DONE      else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_core_cs=S_TXD           else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_core_cs=S_TXD_DONE      else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_core_cs=S_RXD           else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs'length) when fsm_core_cs=S_RXD_DONE      else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_cs'length) when fsm_core_cs=S_RESTART       else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);-- when fsm_core_cs=S_IDLE        else

end generate gen_dbg_on;


p_out_err <= i_reg_wr_err or i_core_err;

-------------------------------------
--Конфигурирование устройства(запись/чтение регистров уст-ва)
-------------------------------------
process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then

    fsm_reg_cs <= S_IDLE;
    i_reg_wr_start <= '0';
    i_reg_adr <= (others=>'0');
    i_reg_dat <= (others=>'0');
    i_reg_wr_err <= '0';
    i_reg_cnt <= (others=>'0');
    i_reg_wr_dly <= (others=>'0');

  elsif rising_edge(p_in_clk) then

      case fsm_reg_cs is

          -------------------------------------
          --
          -------------------------------------
          when S_IDLE =>

            if i_reg_wr_dly = CONV_STD_LOGIC_VECTOR(CI_REG_WR_DLY, i_reg_wr_dly'length) then
              i_reg_wr_dly <= (others=>'0');
              i_reg_wr_start <= '1';
              i_reg_wr <= '0';--read
              i_reg_adr <= CI_REG_VID;
              fsm_reg_cs <= S_REG_VID;
            else
              i_reg_wr_dly <= i_reg_wr_dly + 1;
            end if;

          -------------------------------------
          --
          -------------------------------------
          when S_REG_VID =>

            i_reg_wr_start <= '0';
            if i_reg_wr_done = '1' then
              if i_core_rxd /= CI_VID or i_core_err = '1' then
                i_reg_wr_err <= '1';
                fsm_reg_cs <= S_DONE;
              else
                fsm_reg_cs <= S_REG_SET;
              end if;
            end if;

          -------------------------------------
          --
          -------------------------------------
          when S_REG_SET =>

            if i_reg_wr_dly = CONV_STD_LOGIC_VECTOR(CI_REG_WR_DLY, i_reg_wr_dly'length) then
              i_reg_wr_dly <= (others=>'0');
              i_reg_wr_start <= '1';
              i_reg_wr <= '1';--write
              for n in 0 to CI_REG_ARRAY'length - 1 loop
                if i_reg_cnt = n then
                  i_reg_adr <= CI_REG_ARRAY(n)(15 downto 8);
                  i_reg_dat <= CI_REG_ARRAY(n)(7 downto 0);
                end if;
              end loop;
              fsm_reg_cs <= S_REG_DONE;
            else
              i_reg_wr_dly <= i_reg_wr_dly + 1;
            end if;

          -------------------------------------
          --
          -------------------------------------
          when S_REG_DONE =>

            i_reg_wr_start <= '0';
            if i_reg_wr_done = '1' then
              if i_core_err = '0' then
                if i_reg_cnt = CONV_STD_LOGIC_VECTOR(CI_REG_ARRAY'length - 1, i_reg_cnt'length) then
                  i_reg_cnt <= (others=>'0');
                  fsm_reg_cs <= S_DONE;
                else
                  i_reg_cnt <= i_reg_cnt + 1;
                  fsm_reg_cs <= S_REG_SET;
                end if;
              else
                fsm_reg_cs <= S_DONE;
              end if;
            end if;

          -------------------------------------
          --
          -------------------------------------
          when S_DONE =>
            fsm_reg_cs <= S_DONE;

      end case;

  end if;
end process;


-------------------------------------
--Протокол обмена с I2C Device
-------------------------------------
process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then

    fsm_core_cs <= S_IDLE;

    i_core_cmd <= (others=>'0');
    i_core_start <= '0';
    i_core_txack <= '0';
    i_core_err <= '0';
    i_reg_wr_done <='0';

    i_core_txd <= (others=>'0');

  elsif rising_edge(p_in_clk) then

      case fsm_core_cs is

          -------------------------------------
          --
          -------------------------------------
          when S_IDLE =>

              i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_NULL, i_core_cmd'length);
              i_reg_wr_done <= '0';
              if i_reg_wr_start = '1' then
                fsm_core_cs <= S_DAB_WR;
              end if;

          -------------------------------------
          --SET ADR DEV + CMD
          -------------------------------------
          when S_DAB_WR =>

              i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_START_WR, i_core_cmd'length);
              i_core_start <= '1';
              i_core_txd <= CI_I2C_ADEV & '0'; --ADEV + CMD WR
              fsm_core_cs <= S_RAB;

          -------------------------------------
          --SET REG ADR
          -------------------------------------
          when S_RAB =>

              if i_core_done = '1' then
                if i_core_rxack = '0' then
                  i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_WR, i_core_cmd'length);
                  i_core_start <= '1';
                  i_core_txd <= i_reg_adr;
                  fsm_core_cs <= S_RAB_DONE;
                else
                  --Bad acknowlege!!!!
                  i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_STOP, i_core_cmd'length);
                  i_core_start <= '1';
                  fsm_core_cs <= S_ERR;
                end if;
              else
                i_core_start <= '0';
              end if;

          when S_RAB_DONE =>

              if i_core_done = '1' then
                if i_core_rxack = '0' then

                  if i_reg_wr = '1' then
                    --mode REG WRITE
                    i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_WR, i_core_cmd'length);
                    i_core_start <= '1';
                    i_core_txd <= i_reg_dat;
                    fsm_core_cs <= S_TXD;
                  else
                    --mode REG READ
                    i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_RESTART, i_core_cmd'length);
                    --i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_START, i_core_cmd'length);
                    i_core_start <= '1';
                    fsm_core_cs <= S_RESTART;
                  end if;

                end if;
              else
                i_core_start <= '0';
              end if;

          -------------------------------------
          --SET REG DATA
          -------------------------------------
          when S_TXD =>

              if i_core_done = '1' then
                --if i_core_rxack = '0' then
                  i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_STOP, i_core_cmd'length);
                  i_core_start <= '1';
                  fsm_core_cs <= S_TXD_DONE;
                --end if;
              else
                i_core_start <= '0';
              end if;

          when S_TXD_DONE =>

              if i_core_done = '1' then
                if i_core_rxack = '0' then
                  i_reg_wr_done <= '1';
                  fsm_core_cs <= S_IDLE;
                end if;
              else
                i_core_start <= '0';
              end if;

          -------------------------------------
          --GET REG DATA
          -------------------------------------
          when S_RESTART =>

              if i_core_done = '1' then
                  i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_WR, i_core_cmd'length);
                  i_core_start <= '1';
                  i_core_txd <= CI_I2C_ADEV & '1'; --ADEV + CMD RD
                  fsm_core_cs <= S_DAB_RD;
              else
                i_core_start <= '0';
              end if;

          when S_DAB_RD =>

              if i_core_done = '1' then
                if i_core_rxack = '0' then
                  i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_RD, i_core_cmd'length);
                  i_core_start <= '1';
                  i_core_txack <= '1';--Terminate Read operation
                  fsm_core_cs <= S_RXD;
                else
                  --Bad acknowlege!!!!
                  i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_STOP, i_core_cmd'length);
                  i_core_start <= '1';
                  fsm_core_cs <= S_ERR;
                end if;
              else
                i_core_start <= '0';
              end if;

          when S_RXD =>

              if i_core_done = '1' then
                i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_STOP, i_core_cmd'length);
                i_core_start <= '1';
                fsm_core_cs <= S_RXD_DONE;
              else
                i_core_start <= '0';
              end if;

          when S_RXD_DONE =>

              i_core_start <= '0';
              if i_core_done = '1' then
                i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_NULL, i_core_cmd'length);
                i_reg_wr_done <= '1';
                fsm_core_cs <= S_IDLE;
              end if;

          -------------------------------------
          --
          -------------------------------------
          when S_ERR =>

              i_core_err <= '1';
              i_core_start <= '0';
              if i_core_done = '1' then
                i_core_cmd <= CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_NULL, i_core_cmd'length);
                i_reg_wr_done <= '1';
                fsm_core_cs <= S_IDLE;
              end if;

      end case;

  end if;
end process;

m_i2c_core : i2c_core_master
generic map(
G_CLK_FREQ => CI_CLKIN_FREQ,
G_BAUD     => CI_I2C_BAUD,
G_DBG      => G_DBG,
G_SIM      => G_SIM
)
port map(
p_in_cmd    => i_core_cmd,
p_in_start  => i_core_start,
p_out_done  => i_core_done,
p_in_txack  => i_core_txack,
p_out_rxack => i_core_rxack,

p_in_txd    => i_core_txd,
p_out_rxd   => i_core_rxd,

--I2C
p_inout_sda => p_inout_sda,
p_inout_scl => p_inout_scl,

--Технологический
p_in_tst    => (others=>'0'),
p_out_tst   => tst_core_out,

--System
p_in_clk    => p_in_clk,
p_in_rst    => p_in_rst
);


-------------------------------------
--Видео
-------------------------------------
m_dcm : dvi_ctrl_dcm
port map(
p_out_rst  => i_dvi_rst,
p_out_gclk => i_clk_out,

--System
p_in_clk   => p_in_clk,
p_in_rst   => p_in_rst
);


--1024x768@70MHz (PixClk=75MHz)
g_clk_pix <= i_clk_out(0);

i_vga_hs_e <= CONV_STD_LOGIC_VECTOR(136 - 1, i_vga_hs_e'length);
i_vga_ha_b <= CONV_STD_LOGIC_VECTOR(136 + 144 - 1, i_vga_ha_b'length);
i_vga_ha_e <= CONV_STD_LOGIC_VECTOR(136 + 144 + 1024 - 1, i_vga_ha_e'length);
i_vga_hend <= CONV_STD_LOGIC_VECTOR(136 + 144 + 1024 + 24 - 1, i_vga_hend'length);

i_vga_vs_e <= CONV_STD_LOGIC_VECTOR(6 - 1, i_vga_vs_e'length);
i_vga_va_b <= CONV_STD_LOGIC_VECTOR(6 + 29 - 1, i_vga_va_b'length);
i_vga_va_e <= CONV_STD_LOGIC_VECTOR(6 + 29 + 768 - 1, i_vga_va_e'length);
i_vga_vend <= CONV_STD_LOGIC_VECTOR(6 + 29 + 768 + 3 - 1, i_vga_vend'length);

process(i_dvi_rst, g_clk_pix)
begin
  if i_dvi_rst = '1' then
    i_vga_xcnt <= (others=>'0');
    i_vga_ycnt <= (others=>'0');
    i_dvi_hs<= '0';
    i_dvi_vs <= '0';
    i_dvi_ha <= '0';
    i_dvi_va <= '0';

  elsif rising_edge(g_clk_pix) then
      if i_vga_xcnt = i_vga_hend then
        i_vga_xcnt <= (others=>'0');
        if i_vga_ycnt = i_vga_vend then
          i_vga_ycnt <= (others=>'0');
        else
          i_vga_ycnt <= i_vga_ycnt + 1;
        end if;
      else
        i_vga_xcnt <= i_vga_xcnt + 1;
      end if;

      if i_vga_xcnt > i_vga_hs_e then i_dvi_hs <= '1';
      else                          i_dvi_hs <= '0';
      end if;

      if i_vga_ycnt > i_vga_vs_e then i_dvi_vs <= '1';
      else                          i_dvi_vs <= '0';
      end if;

      if (i_vga_xcnt > i_vga_ha_b) and (i_vga_xcnt <= i_vga_ha_e) then i_dvi_ha <= '1';
      else                                                             i_dvi_ha <= '0';
      end if;

      if (i_vga_ycnt > i_vga_va_b) and (i_vga_ycnt <= i_vga_va_e) then i_dvi_va <= '1';
      else                                                             i_dvi_va <= '0';
      end if;
  end if;
end process;

i_dvi_de <=i_dvi_ha and i_dvi_va;

i_red   <= "00000" & i_vga_xcnt(7 downto 5);
i_green <= "00000" & i_vga_xcnt(7 downto 5);
i_blue  <= "00000" & i_vga_xcnt(7 downto 5);

--Input Data Format(IDF) = 0
i_dvi_d0(11 downto 0) <= i_green(3 downto 0) & i_blue(7 downto 0);
i_dvi_d1(11 downto 0) <= i_red(7 downto 0) & i_green(7 downto 4);

---------------------------------------
--DVI PHY
---------------------------------------
p_out_vde<= i_dvi_de;
p_out_hs <= i_dvi_hs;
p_out_vs <= i_dvi_vs;

gen_ddr: for i in 0  to p_out_vd'length - 1 generate
m_ddr : dvi_ctrl_ddr_o
port map(
Q  => p_out_vd(i),
D1 => i_dvi_d0(i),
D2 => i_dvi_d1(i),
CE => '1',
C  => g_clk_pix,
R  => p_in_rst,
S  => '0'
);
end generate gen_ddr;

m_clk_p : dvi_ctrl_ddr_o
port map(
Q  => p_out_clk(0), --clk_p
D1 => '1',
D2 => '0',
CE => '1',
C  => g_clk_pix,
R  => p_in_rst,
S  => '0'
);

m_clk_n : dvi_ctrl_ddr_o
port map(
Q  => p_out_clk(1), --clk_n
D1 => '0',
D2 => '1',
CE => '1',
C  => g_clk_pix,
R  => p_in_rst,
S  => '0'
);


--END MAIN
end behavioral;


