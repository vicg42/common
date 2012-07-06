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
G_VBUF_IWIDTH : integer:=80;
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1'
);
port(
--Вх. видеопоток
p_in_vd            : in   std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
p_in_vs            : in   std_logic;
p_in_hs            : in   std_logic;
p_in_vclk          : in   std_logic;
p_in_ext_syn       : in   std_logic;--//Внешняя синхронизация

p_out_vfr_prm      : out  TFrXY;

--Вых. видеопоток
p_out_vsync        : out  TVSync;
p_out_vbufi_d      : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vbufi_rd      : in   std_logic;
p_out_vbufi_empty  : out  std_logic;
p_out_vbufi_full   : out  std_logic;
p_in_vbufi_wrclk   : in   std_logic;
p_in_vbufi_rdclk   : in   std_logic;

--Технологический
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

--System
p_in_rst           : in   std_logic
);
end vin_hdd;

architecture behavioral of vin_hdd is

component vin_bufi
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

component vin_bufc
port(
din    : in std_logic_vector(31 downto 0);
wr_en  : in std_logic;
wr_clk : in std_logic;

dout   : out std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
rd_en  : in std_logic;
rd_clk : in std_logic;

empty  : out std_logic;
full   : out std_logic;

--clk    : in std_logic;
rst    : in std_logic
);
end component;

component vin_bufo
port(
din    : in std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
wr_en  : in std_logic;
--wr_clk : in std_logic;

dout   : out std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
rd_en  : in std_logic;
--rd_clk : in std_logic;

empty  : out std_logic;
full   : out std_logic;

clk    : in std_logic;
srst   : in std_logic
);
end component;

signal i_det_ext_syn        : std_logic;

signal sr_vd                : std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
signal i_vd_vector          : std_logic_vector((G_VBUF_IWIDTH*2)-1 downto 0);
signal i_vsync              : TVSync;

constant CI_BUF_COUNT       : integer:=selval(1, (G_VBUF_IWIDTH*2)/32, (G_VBUF_IWIDTH<16));

signal i_bufi_cnt           : std_logic_vector(log2(CI_BUF_COUNT) downto 0);
signal i_bufi_wr_en         : std_logic:='0';
signal i_bufi_wr            : std_logic;
signal i_bufi_rd            : std_logic_vector(CI_BUF_COUNT-1 downto 0);
type TBufD  is array (0 to CI_BUF_COUNT-1) of std_logic_vector(31 downto 0);
signal i_bufi_din           : TBufD;
signal i_bufi_dout          : TBufD;
signal i_bufi_empty         : std_logic_vector(CI_BUF_COUNT-1 downto 0);
signal i_bufi_full          : std_logic_vector(CI_BUF_COUNT-1 downto 0);
signal i_bufo_din           : std_logic_vector(31 downto 0);
signal i_bufo_wr_tmp        : std_logic_vector(CI_BUF_COUNT-1 downto 0);
signal i_bufo_wr            : std_logic;

type fsm_state is (
S_IDLE,
S_RD
);
signal fsm_cs : fsm_state;

signal sr_hs                : std_logic_vector(0 to 1);
signal i_skip_line          : std_logic;
signal i_buf2i_dout         : std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
signal i_buf2i_rd           : std_logic;
signal i_buf2i_empty        : std_logic;


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(0)<=i_bufo_wr;
p_out_tst(1)<=i_bufi_wr;
p_out_tst(2)<=i_bufi_wr_en;
p_out_tst(3)<=OR_reduce(i_bufi_full);
p_out_tst(4)<='0';
p_out_tst(5)<=i_det_ext_syn;
p_out_tst(31 downto 6)<=(others=>'0');

p_out_vfr_prm.pix<=CONV_STD_LOGIC_VECTOR(C_PCFG_FRPIX, p_out_vfr_prm.pix'length);
p_out_vfr_prm.row<=CONV_STD_LOGIC_VECTOR(C_PCFG_FRROW, p_out_vfr_prm.row'length);


--//BUFI - Запись:
process(p_in_rst,p_in_vclk)
begin
  if p_in_rst='1' then
    i_det_ext_syn<='0';
  elsif p_in_vclk'event and p_in_vclk='1' then
    if p_in_ext_syn='1' then
      i_det_ext_syn<='1';
    end if;
  end if;
end process;

process(p_in_rst,p_in_vclk)
begin
  if p_in_rst='1' then
    i_bufi_wr<='0';
    i_bufi_wr_en<='0';
    sr_vd<=(others=>'0');
    sr_hs<=(others=>'0');
    i_skip_line<='0';
  elsif p_in_vclk'event and p_in_vclk='1' then

    sr_hs<=p_in_hs & sr_hs(0 to 0);
    if p_in_vs=G_VSYN_ACTIVE or p_in_tst(0)='0' then
      i_skip_line<='0';
    elsif sr_hs(0)='0' and sr_hs(1)='1' then
      i_skip_line<=not i_skip_line;
    end if;

    if p_in_vs=G_VSYN_ACTIVE and i_det_ext_syn='1' then
      i_bufi_wr_en<='1';
    end if;

    if i_bufi_wr_en='1' and p_in_vs/=G_VSYN_ACTIVE and p_in_hs/=G_VSYN_ACTIVE then
      if i_skip_line='0' then
        i_bufi_wr<=not i_bufi_wr;
        if i_bufi_wr='0' then
          sr_vd<=p_in_vd;
        end if;
      else
        i_bufi_wr<='0';
      end if;
    else
      i_bufi_wr<='0';
    end if;

  end if;
end process;

i_vd_vector<=p_in_vd & sr_vd;

--Входные буфера:
gen_bufi : for i in 0 to CI_BUF_COUNT-1 generate

i_bufi_din(i)<=i_vd_vector(32*(i+1)-1 downto 32*i);

m_bufi : vin_bufi
port map(
din    => i_bufi_din(i),
wr_en  => i_bufi_wr,
wr_clk => p_in_vclk,

dout   => i_bufi_dout(i),
rd_en  => i_bufi_rd(i),
rd_clk => p_in_vbufi_wrclk,

full   => i_bufi_full(i),
empty  => i_bufi_empty(i),

rst    => p_in_rst
);

i_bufi_rd(i)<=not i_bufi_empty(i) when fsm_cs=S_RD and i_bufi_cnt=i else '0';

end generate gen_bufi;

--//BUFI - Чтение:
process(p_in_rst,p_in_vbufi_wrclk)
  variable update : std_logic;
begin
  if p_in_rst='1' then
    i_bufi_cnt<=(others=>'0');
    i_bufo_din<=(others=>'0');
    i_bufo_wr_tmp<=(others=>'0');
    fsm_cs <= S_IDLE;
      update:='0';

  elsif p_in_vbufi_wrclk'event and p_in_vbufi_wrclk='1' then
      update:='0';

    case fsm_cs is
      --------------------------------------
      --
      --------------------------------------
      when S_IDLE =>
          if OR_reduce(i_bufi_empty)='0' then
            i_bufi_cnt<=(others=>'0');
            fsm_cs <= S_RD;
          end if;

      --------------------------------------
      --Перемещение данных m_bufi -> m_bufo
      --------------------------------------
      when S_RD =>

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

--Конвертация шины данных 32bit -> G_VBUF_OWIDTH bit
m_bufc : vin_bufc
port map(
din    => i_bufo_din,
wr_en  => i_bufo_wr,
wr_clk => p_in_vbufi_wrclk,

dout   => i_buf2i_dout,
rd_en  => i_buf2i_rd,
rd_clk => p_in_vbufi_rdclk,

empty  => i_buf2i_empty,
full   => open,

rst    => p_in_rst
);

i_buf2i_rd<=not i_buf2i_empty;

--Выходной буфер
m_bufo : vin_bufo
port map(
din    => i_buf2i_dout,
wr_en  => i_buf2i_rd,

dout   => p_out_vbufi_d,
rd_en  => p_in_vbufi_rd,

empty  => p_out_vbufi_empty,
full   => p_out_vbufi_full,

clk    => p_in_vbufi_rdclk,
srst   => p_in_rst
);

--Пересинхронизация КСИ,CСИ
process(p_in_vbufi_rdclk)
begin
  if p_in_vbufi_rdclk'event and p_in_vbufi_rdclk='1' then
    if p_in_vs=G_VSYN_ACTIVE then
      i_vsync.v<='1';
    else
      i_vsync.v<='0';
    end if;

    if p_in_hs=G_VSYN_ACTIVE then
      i_vsync.h<='1';
    else
      i_vsync.h<='0';
    end if;
  end if;
end process;

p_out_vsync<=i_vsync;

--END MAIN
end behavioral;
