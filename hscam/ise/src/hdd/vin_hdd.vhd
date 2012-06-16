-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2012 12:27:16
-- Module Name : vin_hdd
--
-- Назначение/Описание :
--   Прием видеоданных для записи на HDD
--
-- Revision:
-- Revision 0.01 - File Created
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.video_ctrl_pkg.all;

entity vin_hdd is
generic(
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1';
G_SKIP_VH     : std_logic:='1';
G_EXTSYN      : string:="OFF"
);
port(
--Вх. видеопоток
p_in_vd            : in   std_logic_vector((10*8)-1 downto 0);
p_in_vs            : in   std_logic;
p_in_hs            : in   std_logic;
p_in_vclk          : in   std_logic;
p_in_ext_syn       : in   std_logic;--//Внешняя синхронизация

p_out_vfr_prm      : out  TFrXY;

--Вых. видеопоток
p_out_vbufin_d     : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vbufin_rd     : in   std_logic;
p_out_vbufin_empty : out  std_logic;
p_out_vbufin_full  : out  std_logic;
p_in_vbufin_wrclk  : in   std_logic;
p_in_vbufin_rdclk  : in   std_logic;

--Технологический
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

--System
p_in_rst           : in   std_logic
);
end vin_hdd;

architecture behavioral of vin_hdd is

constant CI_BUF_COUNT : integer:=5;

component vin_bufhdd
port(
din    : in  std_logic_vector(31 downto 0);
wr_en  : in  std_logic;
wr_clk : in  std_logic;

dout   : out std_logic_vector(31 downto 0);
rd_en  : in  std_logic;
rd_clk : in  std_logic;

full   : out std_logic;
empty  : out std_logic;

rst    : in  std_logic
);
end component;

component hdd_rambuf_infifo
port(
din    : in std_logic_vector(31 downto 0);
wr_en  : in std_logic;
wr_clk : in std_logic;

dout   : out std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
rd_en  : in std_logic;
rd_clk : in std_logic;

empty  : out std_logic;
full   : out std_logic;
prog_full     : out std_logic;
rd_data_count : out std_logic_vector(3 downto 0);
--data_count : out std_logic_vector(3 downto 0);

--clk    : in std_logic;
rst    : in std_logic
);
end component;

signal i_ext_syn_en         : std_logic;
--signal i_bufi_cnt           : integer range 0 to CI_BUF_COUNT;
signal i_bufi_cnt           : std_logic_vector(2 downto 0);
signal i_bufi_wr_en         : std_logic:='0';
signal i_bufi_wr            : std_logic;
signal i_bufi_rd            : std_logic_vector(CI_BUF_COUNT-1 downto 0);
type TBufData  is array (0 to CI_BUF_COUNT-1) of std_logic_vector(31 downto 0);
signal i_bufi_din           : TBufData;
signal i_bufi_dout          : TBufData;
signal i_bufi_empty         : std_logic_vector(CI_BUF_COUNT-1 downto 0);
signal i_bufi_full          : std_logic_vector(CI_BUF_COUNT-1 downto 0);
signal i_bufo_din           : std_logic_vector(31 downto 0);
signal i_bufo_wr_tmp        : std_logic_vector(CI_BUF_COUNT-1 downto 0);
signal i_bufo_wr            : std_logic;
signal sr_vd                : std_logic_vector((10*8)-1 downto 0);
signal i_vd_vector          : std_logic_vector((10*8*2)-1 downto 0);

type fsm_state is (
S_IDLE,
S_WORK
);
signal fsm_cs : fsm_state;

signal sr_hs                : std_logic_vector(0 to 1);
signal i_skip_line          : std_logic;
signal i_mode_fps           : std_logic_vector(C_CAM_CTRL_MODE_FPS_M_BIT-C_CAM_CTRL_MODE_FPS_L_BIT downto 0);
signal tst_bufi_wr_en       : std_logic;

--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(0)<=i_bufo_wr;
p_out_tst(1)<=i_bufi_wr;
p_out_tst(2)<=i_bufi_wr_en;
p_out_tst(3)<=OR_reduce(i_bufi_full);
p_out_tst(4)<=tst_bufi_wr_en;
p_out_tst(31 downto 5)<=(others=>'0');

p_out_vfr_prm.pix<=CONV_STD_LOGIC_VECTOR(C_PCFG_FRPIX, p_out_vfr_prm.pix'length);
p_out_vfr_prm.row<=CONV_STD_LOGIC_VECTOR(C_PCFG_FRROW, p_out_vfr_prm.row'length);

i_mode_fps<=p_in_tst(C_CAM_CTRL_MODE_FPS_M_BIT downto C_CAM_CTRL_MODE_FPS_L_BIT);

--//BUFI - Запись:
gen_extsyn_off : if strcmp(G_EXTSYN,"OFF") generate
i_ext_syn_en<='1';
end generate gen_extsyn_off;

gen_extsyn_on : if strcmp(G_EXTSYN,"ON") generate
process(p_in_rst,p_in_vclk)
begin
  if p_in_rst='1' then
    i_ext_syn_en<='0';
  elsif p_in_vclk'event and p_in_vclk='1' then
    if p_in_ext_syn='1' then
      i_ext_syn_en<='1';
    end if;
  end if;
end process;
end generate gen_extsyn_on;

process(p_in_rst,p_in_vclk)
begin
  if p_in_rst='1' then
    i_bufi_wr<='0';
    i_bufi_wr_en<='0'; tst_bufi_wr_en<='0';
    sr_vd<=(others=>'0');
    sr_hs<=(others=>'0');
    i_skip_line<='0';
  elsif p_in_vclk'event and p_in_vclk='1' then

    sr_hs<=p_in_hs & sr_hs(0 to 0);
    if p_in_vs=G_VSYN_ACTIVE then
      i_skip_line<='0';
    elsif sr_hs(0)='0' and sr_hs(1)='1' then
      i_skip_line<=not i_skip_line;
    end if;

    if p_in_vs=G_VSYN_ACTIVE and i_ext_syn_en='1' then
      i_bufi_wr_en<='1';
    end if;

    if i_bufi_wr_en='1' and p_in_vs/=G_VSYN_ACTIVE and p_in_hs/=G_VSYN_ACTIVE then
      if i_mode_fps=CONV_STD_LOGIC_VECTOR(C_CAM_CTRL_480FPS, i_mode_fps'length) and G_SKIP_VH='1' then
      --прореживаем строки
        if i_skip_line='0' then
          i_bufi_wr<=not i_bufi_wr; tst_bufi_wr_en<='1';
          if i_bufi_wr='0' then
            sr_vd<=p_in_vd;
          end if;
        else
          i_bufi_wr<='0';
        end if;
      else
      --без прореживаия строк
        i_bufi_wr<=not i_bufi_wr; tst_bufi_wr_en<='1';
        if i_bufi_wr='0' then
          sr_vd<=p_in_vd;
        end if;
      end if;
    else
      i_bufi_wr<='0';
    end if;
  end if;
end process;

i_vd_vector<=p_in_vd & sr_vd;

--//Буфера:
gen_bufi : for i in 0 to CI_BUF_COUNT-1 generate

i_bufi_din(i)<=i_vd_vector(32*(i+1)-1 downto 32*i);

m_bufi : vin_bufhdd
port map(
din    => i_bufi_din(i),
wr_en  => i_bufi_wr,
wr_clk => p_in_vclk,

dout   => i_bufi_dout(i)(31 downto 0),
rd_en  => i_bufi_rd(i),
rd_clk => p_in_vbufin_wrclk,

full   => i_bufi_full(i),
empty  => i_bufi_empty(i),

rst    => p_in_rst
);

i_bufi_rd(i)<=not i_bufi_empty(i) when fsm_cs=S_WORK and i_bufi_cnt=i else '0';

end generate gen_bufi;

--//BUFI - Чтение:
process(p_in_rst,p_in_vbufin_wrclk)
  variable update : std_logic;
begin
  if p_in_rst='1' then
    i_bufi_cnt<=(others=>'0');
    i_bufo_din<=(others=>'0');
    i_bufo_wr_tmp<=(others=>'0');
    fsm_cs <= S_IDLE;
      update:='0';

  elsif p_in_vbufin_wrclk'event and p_in_vbufin_wrclk='1' then
      update:='0';

    case fsm_cs is
      --------------------------------------
      --Исходное состояние
      --------------------------------------
      when S_IDLE =>
          if OR_reduce(i_bufi_empty)='0' then
            i_bufi_cnt<=(others=>'0');
            fsm_cs <= S_WORK;
          end if;

      --------------------------------------
      --Запись данных в m_bufo
      --------------------------------------
      when S_WORK =>

          for i in 0 to i_bufi_dout'length-1 loop
            if i_bufi_cnt=i then
              if i_bufi_rd(i)='1' then
                  update:='1';
               i_bufo_din<=i_bufi_dout(i);
              end if;
            end if;
          end loop;

          if update='1' then
            if i_bufi_cnt=CONV_STD_LOGIC_VECTOR(CI_BUF_COUNT-1, i_bufi_cnt'length) then
              i_bufi_cnt<=(others=>'0');
              fsm_cs <= S_IDLE;
            else
              i_bufi_cnt<=i_bufi_cnt + 1;
            end if;
          end if;

    end case;

    i_bufo_wr_tmp<=i_bufi_rd;
  end if;
end process;

i_bufo_wr<=OR_reduce(i_bufo_wr_tmp);


m_bufo : hdd_rambuf_infifo
port map(
din       => i_bufo_din,
wr_en     => i_bufo_wr,
wr_clk    => p_in_vbufin_wrclk,

dout      => p_out_vbufin_d,
rd_en     => p_in_vbufin_rd,
rd_clk    => p_in_vbufin_rdclk,

empty     => p_out_vbufin_empty,
full      => p_out_vbufin_full,
prog_full => open,
rd_data_count => open,
--data_count => p_out_vbufin_wrcnt,

--clk       => p_in_vbufin_rdclk,
rst       => p_in_rst
);


--END MAIN
end behavioral;
