-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.06.2012 10:17:52
-- Module Name : dsn_video_ctrl
--
-- Назначение/Описание :
--  Формирование/Запись/Чтение кадров видеоканалов
--
-- Revision:
-- Revision 0.01 - File Created
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
--use work.prj_cfg.all;
use work.prj_def.all;
use work.dsn_video_ctrl_pkg.all;
use work.mem_wr_pkg.all;

entity dsn_video_ctrl is
generic(
G_DBGCS  : string:="OFF";
G_ROTATE : string:="OFF";
G_ROTATE_BUF_COUNT: integer:=16;
G_SIMPLE : string:="OFF"; --ON/OFF - из обработки видео отавлено только отзеркаливание/ включен полный функционал видеообработки
G_SIM    : string:="OFF";
G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
port(
-------------------------------
--CFG
-------------------------------
p_in_host_clk         : in   std_logic;

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld       : in   std_logic;
p_in_cfg_adr_fifo     : in   std_logic;

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);
p_in_cfg_wd           : in   std_logic;

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);
p_in_cfg_rd           : in   std_logic;

p_in_cfg_done         : in   std_logic;

-------------------------------
--HOST
-------------------------------
p_in_vctrl_hrdchsel   : in    std_logic_vector(3 downto 0);   --Номер видео канала который будет читать ХОСТ
p_in_vctrl_hrdstart   : in    std_logic;                      --Начало чтенения видеоканала
p_in_vctrl_hrddone    : in    std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);--Подтверждение вычетки данных видеоканала
p_out_vctrl_hirq      : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);--Готовность кадра соответствующего видеоканала
p_out_vctrl_hdrdy     : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);--Прерываение соответствующего видеоканала(Кадр готов)
p_out_vctrl_hfrmrk    : out   std_logic_vector(31 downto 0);

p_out_vbufo_do        : out   std_logic_vector(G_MEM_DWIDTH - 1 downto 0);--Видео данные для ХОСТА
p_in_vbufo_rd         : in    std_logic;
p_out_vbufo_empty     : out   std_logic;

-------------------------------
--VBUFI
-------------------------------
p_in_vbufi_do         : in    std_logic_vector(31 downto 0);
p_out_vbufi_rd        : out   std_logic;
p_in_vbufi_empty      : in    std_logic;
p_in_vbufi_full       : in    std_logic;

---------------------------------
--MEM
---------------------------------
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end dsn_video_ctrl;

architecture behavioral of dsn_video_ctrl is

component host_vbuf
port(
din         : IN  std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
--almost_full : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component;

component video_writer
generic(
G_DBGCS           : string :="OFF";
G_MEM_BANK_M_BIT  : integer:=29;
G_MEM_BANK_L_BIT  : integer:=28;

G_MEM_VCH_M_BIT   : integer:=25;
G_MEM_VCH_L_BIT   : integer:=24;
G_MEM_VFR_M_BIT   : integer:=23;
G_MEM_VFR_L_BIT   : integer:=23;
G_MEM_VLINE_M_BIT : integer:=22;
G_MEM_VLINE_L_BIT : integer:=12;

G_MEM_AWIDTH      : integer:=32;
G_MEM_DWIDTH      : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_load         : in    std_logic;
p_in_cfg_mem_trn_len  : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch      : in    TWriterVCHParams;
p_in_cfg_set_idle_vch : in    std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);

p_in_vfr_buf          : in    TVfrBufs;

--Статусы
p_out_vfr_rdy         : out   std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
p_out_vrow_mrk        : out   std_logic_vector(31 downto 0);

----------------------------
--Upstream Port
----------------------------
p_in_upp_data         : in    std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_out_upp_data_rd     : out   std_logic;
p_in_upp_buf_empty    : in    std_logic;
p_in_upp_buf_full     : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             : out   TMemIN;
p_in_mem              : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

component video_reader
generic(
G_DBGCS           : string:="OFF";
G_ROTATE          : string:="OFF";
G_ROTATE_BUF_COUNT: integer:=16;
G_MEM_BANK_M_BIT  : integer:=29;
G_MEM_BANK_L_BIT  : integer:=28;

G_MEM_VCH_M_BIT   : integer:=25;
G_MEM_VCH_L_BIT   : integer:=24;
G_MEM_VFR_M_BIT   : integer:=23;
G_MEM_VFR_L_BIT   : integer:=23;
G_MEM_VLINE_M_BIT : integer:=22;
G_MEM_VLINE_L_BIT : integer:=12;

G_MEM_AWIDTH      : integer:=32;
G_MEM_DWIDTH      : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch     : in    TReaderVCHParams;
p_in_cfg_set_idle_vch: in    std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);

p_in_hrd_chsel       : in    std_logic_vector(3 downto 0);
p_in_hrd_start       : in    std_logic;
p_in_hrd_done        : in    std_logic;

p_in_vfr_buf         : in    TVfrBufs;
p_in_vfr_nrow        : in    std_logic;

--Статусы
p_out_vch_fr_new     : out   std_logic;
p_out_vch_rd_done    : out   std_logic;
p_out_vch            : out   std_logic_vector(3 downto 0);
p_out_vch_active_pix : out   std_logic_vector(15 downto 0);
p_out_vch_active_row : out   std_logic_vector(15 downto 0);
p_out_vch_mirx       : out   std_logic;

----------------------------
--Upstream Port
----------------------------
p_out_upp_data       : out   std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_out_upp_data_wd    : out   std_logic;
p_in_upp_buf_empty   : in    std_logic;
p_in_upp_buf_full    : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             : out   TMemIN;
p_in_mem              : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;

component vmirx_main
generic(
G_DWIDTH : integer:=32
);
port (
-------------------------------
-- Управление
-------------------------------
p_in_cfg_mirx       : in    std_logic;
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);

p_out_cfg_mirx_done : out   std_logic;

----------------------------
--Upstream Port
----------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(G_DWIDTH - 1 downto 0);
p_in_upp_wd         : in    std_logic;
p_out_upp_rdy_n     : out   std_logic;

----------------------------
--Downstream Port
----------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     : out   std_logic_vector(G_DWIDTH - 1 downto 0);
p_out_dwnp_wd       : out   std_logic;
p_in_dwnp_rdy_n     : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;


signal i_cfg_adr_cnt                     : std_logic_vector(7 downto 0);

signal h_reg_ctrl                        : std_logic_vector(C_VCTRL_REG_CTRL_LAST_BIT downto 0);
signal h_reg_tst0                        : std_logic_vector(C_VCTRL_REG_TST0_LAST_BIT downto 0);
signal h_reg_prm_data                    : std_logic_vector(31 downto 0);

signal h_vprm_set                        : std_logic;
signal vclk_vprm_set                     : std_logic;
signal vclk_vprm_set_dly                 : std_logic_vector(0 to 1);

signal h_set_idle_vch                    : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
signal vclk_set_idle_vch                 : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);

signal i_vprm                            : TVctrlParam;
signal i_wrprm_vch                       : TWriterVCHParams;
signal i_rdprm_vch                       : TReaderVCHParams;

constant CI_VBUF_COUNT                   : integer := pwr(2, (C_VCTRL_MEM_VFR_M_BIT - C_VCTRL_MEM_VFR_L_BIT + 1));
Type TVMrks_vbuf is array (0 to CI_VBUF_COUNT - 1) of std_logic_vector(31 downto 0);
Type TVMrks_vbufs is array (0 to C_VCTRL_VCH_COUNT_MAX - 1) of TVMrks_vbuf;

type TArrayCntWidth is array (0 to C_VCTRL_VCH_COUNT_MAX - 1) of std_logic_vector(3 downto 0);
signal i_vrd_irq_width_cnt               : TArrayCntWidth;
signal i_vrd_irq_width                   : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
signal i_vrd_irq                         : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
signal i_vbuf_hold                       : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
signal i_vfrmrk                          : TVMrks_vbufs;
signal i_vfrmrk_out                      : std_logic_vector(31 downto 0);

signal i_vbuf_wr                         : TVfrBufs;
signal i_vbuf_rd                         : TVfrBufs;

signal i_vwrite_vfr_rdy_out              : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
signal i_vwrite_vrow_mrk                 : std_logic_vector(31 downto 0);

signal i_vreader_vch_out                 : std_logic_vector(p_in_vctrl_hrdchsel'range);
signal i_vreader_rd_done                 : std_logic;
signal i_vreader_rq_next_line            : std_logic;
signal i_vreader_active_pix_out          : std_logic_vector(15 downto 0);
signal i_vreader_mirx_out                : std_logic;
signal i_vreader_dout                    : std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
signal i_vreader_dout_en                 : std_logic;

signal i_vmir_rdy_n                      : std_logic;
signal i_vmir_dout                       : std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
signal i_vmir_dout_en                    : std_logic;

signal i_vcoldemasc_rdy_n                : std_logic;

signal i_mem_null_dout                   : std_logic_vector(G_MEM_DWIDTH - 1 downto 0):=(others=>'0');

signal tst_vwriter_out                   : std_logic_vector(31 downto 0);
signal tst_vreader_out,tst_vmir_out      : std_logic_vector(31 downto 0);
signal tst_ctrl                          : std_logic_vector(31 downto 0);

type TVfrSkip is array (0 to C_VCTRL_VCH_COUNT - 1) of std_logic_vector(C_VCTRL_MEM_VFR_M_BIT - C_VCTRL_MEM_VFR_L_BIT downto 0);
signal i_vfrskip                         : TVfrSkip;

--signal tst_dbg_pictire                   : std_logic;
--signal tst_dbg_rd_hold                   : std_logic;


--MAIN
begin


------------------------------------
--Технологические сигналы
------------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_tst(0) <= '0';
p_out_tst(4 downto 1) <= tst_vwriter_out(4 downto 1);
p_out_tst(8 downto 5) <= tst_vreader_out(3 downto 0);
p_out_tst(15 downto 9) <= (others=>'0');
p_out_tst(19 downto 16) <= (others=>'0');
p_out_tst(26 downto 20) <= (others=>'0');
p_out_tst(31 downto 27) <= tst_vwriter_out(31 downto 27);
end generate gen_dbgcs_off;

gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate
p_out_tst(0) <= OR_reduce(tst_vwriter_out) or OR_reduce(tst_vreader_out) or OR_reduce(tst_vmir_out);
p_out_tst(4 downto 1) <= tst_vwriter_out(3 downto 0);
p_out_tst(8 downto 5) <= tst_vreader_out(3 downto 0);
p_out_tst(9)          <= tst_vwriter_out(4);
p_out_tst(10)         <= tst_vreader_out(4);
p_out_tst(25 downto 11) <= (others=>'0');
p_out_tst(31 downto 26) <= tst_vwriter_out(31 downto 26);
end generate gen_dbgcs_on;


----------------------------------------------------
--Конфигурирование модуля
----------------------------------------------------
--Счетчик адреса регистров
process(p_in_rst, p_in_host_clk)
begin
  if p_in_rst = '1' then
    i_cfg_adr_cnt <= (others=>'0');
  elsif rising_edge(p_in_host_clk) then
    if p_in_cfg_adr_ld = '1' then
      i_cfg_adr_cnt <= p_in_cfg_adr;
    else
      if p_in_cfg_adr_fifo = '0' and (p_in_cfg_wd = '1' or p_in_cfg_rd = '1') then
        i_cfg_adr_cnt <= i_cfg_adr_cnt + 1;
      end if;
    end if;
  end if;
end process;

--Запись регистров
process(p_in_rst, p_in_host_clk)
  variable var_vch : std_logic_vector(C_VCTRL_REG_CTRL_VCH_M_BIT - C_VCTRL_REG_CTRL_VCH_L_BIT downto 0);
  variable var_vprm : std_logic_vector(C_VCTRL_REG_CTRL_PRM_M_BIT - C_VCTRL_REG_CTRL_PRM_L_BIT downto 0);
  variable var_vprm_set : std_logic;
  variable var_set_idle_vch : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
begin
  if p_in_rst = '1' then
    h_reg_ctrl <= (others=>'0');
    h_reg_tst0 <= (others=>'0');
    h_reg_prm_data <= (others=>'0');
    var_vprm_set := '0';
    h_vprm_set <= '0';

    var_vch := (others=>'0');
    var_vprm := (others=>'0');

    for i in 0 to C_VCTRL_VCH_COUNT - 1 loop
        i_vprm.ch(i).mem_addr_wr <= (others=>'0');
        i_vprm.ch(i).mem_addr_rd <= (others=>'0');
        i_vprm.ch(i).fr_size.skip.pix <= (others=>'0');
        i_vprm.ch(i).fr_size.skip.row <= (others=>'0');
        i_vprm.ch(i).fr_size.activ.pix <= (others=>'0');
        i_vprm.ch(i).fr_size.activ.row <= (others=>'0');
        i_vprm.ch(i).fr_mirror.pix <= '0';
        i_vprm.ch(i).fr_mirror.row <= '0';
        i_vprm.ch(i).step_rd <= (others=>'0');
    end loop;
    i_vprm.mem_wd_trn_len <= (others=>'0');
    i_vprm.mem_rd_trn_len <= (others=>'0');

    var_set_idle_vch := (others=>'0');
    h_set_idle_vch <= (others=>'0');

  elsif rising_edge(p_in_host_clk) then
    var_vprm_set := '0';
    var_set_idle_vch := (others=>'0');

    if p_in_cfg_wd = '1' then
      if    i_cfg_adr_cnt = CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_CTRL, i_cfg_adr_cnt'length) then
          h_reg_ctrl <= p_in_cfg_txdata(h_reg_ctrl'high downto 0);

          var_vch := p_in_cfg_txdata(C_VCTRL_REG_CTRL_VCH_M_BIT downto C_VCTRL_REG_CTRL_VCH_L_BIT);
          var_vprm := p_in_cfg_txdata(C_VCTRL_REG_CTRL_PRM_M_BIT downto C_VCTRL_REG_CTRL_PRM_L_BIT);

            for i in 0 to C_VCTRL_VCH_COUNT - 1 loop
              if i = var_vch then
                var_set_idle_vch(i) := p_in_cfg_txdata(C_VCTRL_REG_CTRL_SET_IDLE_BIT);
              end if;
            end loop;

          if p_in_cfg_txdata(C_VCTRL_REG_CTRL_SET_BIT) = '1' and
             p_in_cfg_txdata(C_VCTRL_REG_CTRL_RAMCOE_ADR_BIT) = '0' and p_in_cfg_txdata(C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT) = '0' then
            var_vprm_set := '1';

            for i in 0 to C_VCTRL_VCH_COUNT - 1 loop
              if i = var_vch then
                --Ищем индекс папаметра
                if var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_MEM_ADR_WR, var_vprm'length) then
                  i_vprm.ch(i).mem_addr_wr <= h_reg_prm_data(31 downto 0);

                elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_MEM_ADR_RD, var_vprm'length) then
                  i_vprm.ch(i).mem_addr_rd <= h_reg_prm_data(31 downto 0);

                elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_ZONE_SKIP, var_vprm'length) then
                  i_vprm.ch(i).fr_size.skip.pix <= h_reg_prm_data(15 downto 0);
                  i_vprm.ch(i).fr_size.skip.row <= h_reg_prm_data(31 downto 16);

                elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_ZONE_ACTIVE, var_vprm'length) then
                  i_vprm.ch(i).fr_size.activ.pix <= h_reg_prm_data(15 downto 0);
                  i_vprm.ch(i).fr_size.activ.row <= h_reg_prm_data(31 downto 16);

                elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_OPTIONS, var_vprm'length) then
                  i_vprm.ch(i).fr_mirror.pix <= h_reg_prm_data(4);
                  i_vprm.ch(i).fr_mirror.row <= h_reg_prm_data(5);

                elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_STEP_RD, var_vprm'length) then
                  i_vprm.ch(i).step_rd <= h_reg_prm_data(15 downto 0);

                end if;
              end if;
            end loop;

          end if;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_TST0, i_cfg_adr_cnt'length) then h_reg_tst0 <= p_in_cfg_txdata(h_reg_tst0'high downto 0);

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) then h_reg_prm_data(15 downto 0)  <=p_in_cfg_txdata;
      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_M, i_cfg_adr_cnt'length) then h_reg_prm_data(31 downto 16) <=p_in_cfg_txdata;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_MEM_CTRL, i_cfg_adr_cnt'length) then
          var_vprm_set := '1';
          i_vprm.mem_wd_trn_len(7 downto 0) <= p_in_cfg_txdata(7 downto 0);
          i_vprm.mem_rd_trn_len(7 downto 0) <= p_in_cfg_txdata(15 downto 8);

      end if;
    end if;

    h_set_idle_vch <= var_set_idle_vch;
    h_vprm_set <= var_vprm_set;

  end if;
end process;

--Чтение регистров
process(p_in_rst, p_in_host_clk)
  variable var_vch : std_logic_vector(C_VCTRL_REG_CTRL_VCH_M_BIT - C_VCTRL_REG_CTRL_VCH_L_BIT downto 0);
  variable var_vprm : std_logic_vector(C_VCTRL_REG_CTRL_PRM_M_BIT - C_VCTRL_REG_CTRL_PRM_L_BIT downto 0);
begin
  if p_in_rst = '1' then
    p_out_cfg_rxdata <= (others=>'0');

  elsif rising_edge(p_in_host_clk) then

    if p_in_cfg_rd = '1' then
      if    i_cfg_adr_cnt = CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_CTRL, i_cfg_adr_cnt'length) then p_out_cfg_rxdata <= EXT(h_reg_ctrl, 16);

      elsif i_cfg_adr_cnt = CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_TST0, i_cfg_adr_cnt'length) then p_out_cfg_rxdata <= EXT(h_reg_tst0, 16);

      elsif i_cfg_adr_cnt = CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_L, i_cfg_adr_cnt'length) then
          var_vch := h_reg_ctrl(C_VCTRL_REG_CTRL_VCH_M_BIT downto C_VCTRL_REG_CTRL_VCH_L_BIT);
          var_vprm := h_reg_ctrl(C_VCTRL_REG_CTRL_PRM_M_BIT downto C_VCTRL_REG_CTRL_PRM_L_BIT);

          if h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_ADR_BIT) = '0' and h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT) = '0' then
              for i in 0 to C_VCTRL_VCH_COUNT - 1 loop
                if i = var_vch then
                  --Ищем индекс папаметра
                  if var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_MEM_ADR_WR, var_vprm'length) then
                    p_out_cfg_rxdata <= i_vprm.ch(i).mem_addr_wr(15 downto 0);

                  elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_MEM_ADR_RD, var_vprm'length) then
                    p_out_cfg_rxdata <= i_vprm.ch(i).mem_addr_rd(15 downto 0);

                  elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_ZONE_SKIP, var_vprm'length) then
                    p_out_cfg_rxdata <= i_vprm.ch(i).fr_size.skip.pix(15 downto 0);

                  elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_ZONE_ACTIVE, var_vprm'length) then
                    p_out_cfg_rxdata <= i_vprm.ch(i).fr_size.activ.pix(15 downto 0);

                  elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_OPTIONS, var_vprm'length) then
                    p_out_cfg_rxdata(4)           <= i_vprm.ch(i).fr_mirror.pix;
                    p_out_cfg_rxdata(5)           <= i_vprm.ch(i).fr_mirror.row;
                    p_out_cfg_rxdata(15 downto 6)  <= (others=>'0');

                  elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_STEP_RD, var_vprm'length) then
                    p_out_cfg_rxdata <= i_vprm.ch(i).step_rd;

                  end if;
                end if;
              end loop;
           end if;

      elsif i_cfg_adr_cnt = CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_DATA_M, i_cfg_adr_cnt'length) then
          var_vch := h_reg_ctrl(C_VCTRL_REG_CTRL_VCH_M_BIT downto C_VCTRL_REG_CTRL_VCH_L_BIT);
          var_vprm := h_reg_ctrl(C_VCTRL_REG_CTRL_PRM_M_BIT downto C_VCTRL_REG_CTRL_PRM_L_BIT);

          if h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_ADR_BIT) = '0' and h_reg_ctrl(C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT) = '0' then
              for i in 0 to C_VCTRL_VCH_COUNT - 1 loop
                if i = var_vch then
                  --Ищем индекс папаметра
                  if var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_MEM_ADR_WR, var_vprm'length) then
                    p_out_cfg_rxdata <= i_vprm.ch(i).mem_addr_wr(31 downto 16);

                  elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_MEM_ADR_RD, var_vprm'length) then
                    p_out_cfg_rxdata <= i_vprm.ch(i).mem_addr_rd(31 downto 16);

                  elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_ZONE_SKIP, var_vprm'length) then
                    p_out_cfg_rxdata <= i_vprm.ch(i).fr_size.skip.row(15 downto 0);

                  elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_ZONE_ACTIVE, var_vprm'length) then
                    p_out_cfg_rxdata <= i_vprm.ch(i).fr_size.activ.row(15 downto 0);

                  elsif var_vprm = CONV_STD_LOGIC_VECTOR(C_VCTRL_PRM_FR_OPTIONS, var_vprm'length) then
                    p_out_cfg_rxdata(15 downto 0) <= (others=>'0');

                  end if;
                end if;
              end loop;

           end if;

      elsif i_cfg_adr_cnt = CONV_STD_LOGIC_VECTOR(C_VCTRL_REG_MEM_CTRL, i_cfg_adr_cnt'length) then
          p_out_cfg_rxdata(7 downto 0) <= i_vprm.mem_wd_trn_len(7 downto 0);
          p_out_cfg_rxdata(15 downto 8) <= i_vprm.mem_rd_trn_len(7 downto 0);
      end if;
    end if;

  end if;
end process;


tst_ctrl <= EXT(h_reg_tst0, tst_ctrl'length);
--tst_dbg_pictire <= tst_ctrl(C_VCTRL_REG_TST0_DBG_PICTURE_BIT);
--tst_dbg_rd_hold <= tst_ctrl(C_VCTRL_REG_TST0_DBG_RDHOLD_BIT);


--Пересинхронизация
process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then
    vclk_vprm_set_dly <= (others=>'0');
    vclk_vprm_set <= '0';
    vclk_set_idle_vch <= (others=>'0');
  elsif rising_edge(p_in_clk) then
    vclk_vprm_set_dly <= h_vprm_set & vclk_vprm_set_dly(0 to 0);
    vclk_vprm_set <= vclk_vprm_set_dly(0) and not vclk_vprm_set_dly(1);
    vclk_set_idle_vch <= h_set_idle_vch;
  end if;
end process;



-------------------------------
-- Запись видео информации в ОЗУ
-------------------------------
m_video_writer : video_writer
generic map(
G_DBGCS           => G_DBGCS,
G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,

G_MEM_VCH_M_BIT   => C_VCTRL_MEM_VCH_M_BIT,
G_MEM_VCH_L_BIT   => C_VCTRL_MEM_VCH_L_BIT,
G_MEM_VFR_M_BIT   => C_VCTRL_MEM_VFR_M_BIT,
G_MEM_VFR_L_BIT   => C_VCTRL_MEM_VFR_L_BIT,
G_MEM_VLINE_M_BIT => C_VCTRL_MEM_VLINE_M_BIT,
G_MEM_VLINE_L_BIT => C_VCTRL_MEM_VLINE_L_BIT,

G_MEM_AWIDTH      => G_MEM_AWIDTH,
G_MEM_DWIDTH      => 32 --G_MEM_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_load         => vclk_vprm_set,
p_in_cfg_mem_trn_len  => i_vprm.mem_wd_trn_len,
p_in_cfg_prm_vch      => i_wrprm_vch,
p_in_cfg_set_idle_vch => vclk_set_idle_vch,

p_in_vfr_buf          => i_vbuf_wr,

--Статусы
p_out_vfr_rdy         => i_vwrite_vfr_rdy_out,
p_out_vrow_mrk        => i_vwrite_vrow_mrk,

----------------------------
--Upstream Port
----------------------------
p_in_upp_data         => p_in_vbufi_do,
p_out_upp_data_rd     => p_out_vbufi_rd,
p_in_upp_buf_empty    => p_in_vbufi_empty,
p_in_upp_buf_full     => p_in_vbufi_full,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             => p_out_memwr,
p_in_mem              => p_in_memwr,

-------------------------------
--Технологический
-------------------------------
p_in_tst              => tst_ctrl(31 downto 0),--(others=>'0'),
p_out_tst             => tst_vwriter_out,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => p_in_rst
);



----------------------------------------------------
--
----------------------------------------------------
gen_vch : for ch in 0 to C_VCTRL_VCH_COUNT - 1 generate

--Готовим параметры для модуля чтения
i_rdprm_vch(ch).mem_adr   <= i_vprm.ch(ch).mem_addr_rd;
i_rdprm_vch(ch).fr_size   <= i_vprm.ch(ch).fr_size;
i_rdprm_vch(ch).fr_mirror <= i_vprm.ch(ch).fr_mirror;
i_rdprm_vch(ch).step_rd   <= i_vprm.ch(ch).step_rd;

--Готовим параметры для модуля записи
i_wrprm_vch(ch).mem_adr <= i_vprm.ch(ch).mem_addr_wr;


--Растягиваем импульcы генерации прерываний чтения видеоканалов
process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then
   i_vrd_irq_width_cnt(ch) <= (others=>'0');
    i_vrd_irq_width(ch) <= '0';

  elsif rising_edge(p_in_clk) then

    if i_vrd_irq(ch) = '1' then
      i_vrd_irq_width(ch) <= '1';
    elsif i_vrd_irq_width_cnt(ch)(3) = '1' then
      i_vrd_irq_width(ch) <= '0';
    end if;

    if i_vrd_irq_width(ch) = '0' then
      i_vrd_irq_width_cnt(ch) <= (others=>'0');
    else
      i_vrd_irq_width_cnt(ch) <= i_vrd_irq_width_cnt(ch) + 1;
    end if;

  end if;
end process;


--Управление записью видео
process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then
    i_vbuf_wr(ch) <= (others=>'0');
    for buf in 0 to CI_VBUF_COUNT - 1 loop
    i_vfrmrk(ch)(buf) <= (others=>'0');
    end loop;
    i_vfrskip(ch) <= (others=>'0');

  elsif rising_edge(p_in_clk) then

        --Выбираем видеобуфер для записи:
        if vclk_set_idle_vch(ch) = '1' then
          i_vbuf_wr(ch) <= (others=>'0');

        elsif i_vwrite_vfr_rdy_out(ch) = '1' then
            if i_vbuf_hold(ch) = '1' then
              if i_vbuf_wr(ch) /= i_vbuf_rd(ch) then
                i_vbuf_wr(ch) <= i_vbuf_wr(ch) + 1;
              end if;
            else
              i_vbuf_wr(ch) <= i_vbuf_wr(ch) + 1;
            end if;
        end if;

        --Защелкиваем маркер текущего кадра для выдачи ХОСТУ
        if i_vwrite_vfr_rdy_out(ch) = '1' then
          for buf in 0 to CI_VBUF_COUNT - 1 loop
            if i_vbuf_wr(ch) = buf then
              i_vfrmrk(ch)(buf) <= i_vwrite_vrow_mrk;
            end if;
          end loop;
        end if;

        --Подсчет записаных кадров в течении чтения данных ХОСТОМ
        if i_vbuf_hold(ch) = '0' then
          i_vfrskip(ch) <= (others=>'0');
        else
          if i_vwrite_vfr_rdy_out(ch) = '1'
            and i_vreader_rd_done = '1' and i_vreader_vch_out = ch then

            i_vfrskip(ch) <= i_vfrskip(ch);

          elsif i_vfrskip(ch) /= (i_vfrskip(ch)'range => '0')
            and i_vreader_rd_done = '1' and i_vreader_vch_out = ch then

            i_vfrskip(ch) <= i_vfrskip(ch) - 1;

          elsif i_vwrite_vfr_rdy_out(ch) = '1'
            and i_vfrskip(ch) /= (i_vfrskip(ch)'range => '1') then

            i_vfrskip(ch) <= i_vfrskip(ch) + 1;

          end if;
        end if;

  end if;
end process;

--Управление чтеним Видео
process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then

    i_vbuf_rd(ch) <= (others=>'0');
    i_vbuf_hold(ch) <= '0';
    i_vrd_irq(ch) <= '0';

  elsif rising_edge(p_in_clk) then

      --Выбираем видеобуфер для чтения
      if vclk_set_idle_vch(ch) = '1' then
        i_vbuf_rd(ch) <= (others=>'0');

      elsif i_vfrskip(ch) /= (i_vfrskip(ch)'range => '0')
        and i_vreader_rd_done = '1' and i_vreader_vch_out = ch  then

        i_vbuf_rd(ch) <= i_vbuf_rd(ch) + 1;

      elsif i_vwrite_vfr_rdy_out(ch) = '1' and i_vbuf_hold(ch) = '0' then
        i_vbuf_rd(ch) <= i_vbuf_wr(ch);

      end if;

      --Захват видеобуфера для Чтения ХОСТОМ
      if i_vwrite_vfr_rdy_out(ch) = '1' then
        i_vbuf_hold(ch) <= '1';

      elsif (i_vfrskip(ch) = (i_vfrskip(ch)'range => '0')
        and i_vreader_rd_done = '1' and i_vreader_vch_out = ch) or vclk_set_idle_vch(ch) = '1' then

        i_vbuf_hold(ch) <= '0';
      end if;

      --Прерываение - Можно вычитывать кадр
      if i_vfrskip(ch) = (i_vfrskip(ch)'range => '0') then
        i_vrd_irq(ch) <= i_vwrite_vfr_rdy_out(ch) and not i_vbuf_hold(ch);

      elsif i_vreader_vch_out = ch then
        i_vrd_irq(ch) <= i_vreader_rd_done;

      end if;

  end if;
end process;

end generate gen_vch;


-------------------------------
--Модуль чтение видео информации из ОЗУ
-------------------------------
m_video_reader : video_reader
generic map(
G_DBGCS           => G_DBGCS,
G_ROTATE          => G_ROTATE,
G_ROTATE_BUF_COUNT=> G_ROTATE_BUF_COUNT,
G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,

G_MEM_VCH_M_BIT   => C_VCTRL_MEM_VCH_M_BIT,
G_MEM_VCH_L_BIT   => C_VCTRL_MEM_VCH_L_BIT,
G_MEM_VFR_M_BIT   => C_VCTRL_MEM_VFR_M_BIT,
G_MEM_VFR_L_BIT   => C_VCTRL_MEM_VFR_L_BIT,
G_MEM_VLINE_M_BIT => C_VCTRL_MEM_VLINE_M_BIT,
G_MEM_VLINE_L_BIT => C_VCTRL_MEM_VLINE_L_BIT,

G_MEM_AWIDTH      => G_MEM_AWIDTH,
G_MEM_DWIDTH      => G_MEM_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_trn_len  => i_vprm.mem_rd_trn_len,
p_in_cfg_prm_vch      => i_rdprm_vch,
p_in_cfg_set_idle_vch => vclk_set_idle_vch,

p_in_hrd_chsel        => p_in_vctrl_hrdchsel,
p_in_hrd_start        => p_in_vctrl_hrdstart,
p_in_hrd_done         => '0',--p_in_vctrl_hrddone(ch),

p_in_vfr_buf          => i_vbuf_rd,
p_in_vfr_nrow         => i_vreader_rq_next_line,

--Статусы
p_out_vch_fr_new      => open,
p_out_vch_rd_done     => i_vreader_rd_done,
p_out_vch             => i_vreader_vch_out,
p_out_vch_active_pix  => i_vreader_active_pix_out,
p_out_vch_active_row  => open,
p_out_vch_mirx        => i_vreader_mirx_out,

----------------------------
--Upstream Port
----------------------------
p_out_upp_data        => i_vreader_dout,
p_out_upp_data_wd     => i_vreader_dout_en,
p_in_upp_buf_empty    => '0',
p_in_upp_buf_full     => i_vmir_rdy_n,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             => p_out_memrd,
p_in_mem              => p_in_memrd,

-------------------------------
--Технологический
-------------------------------
p_in_tst              => tst_ctrl(31 downto 0),--(others=>'0'),
p_out_tst             => tst_vreader_out,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => p_in_rst
);


-------------------------------
--Модуль отзеркаливания по Х
-------------------------------
m_vmirx : vmirx_main
generic map(
G_DWIDTH => G_MEM_DWIDTH
)
port map(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_mirx       => i_vreader_mirx_out,
p_in_cfg_pix_count  => i_vreader_active_pix_out,

p_out_cfg_mirx_done => i_vreader_rq_next_line,

----------------------------
--Upstream Port
----------------------------
p_in_upp_data       => i_vreader_dout,
p_in_upp_wd         => i_vreader_dout_en,
p_out_upp_rdy_n     => i_vmir_rdy_n,

----------------------------
--Downstream Port
----------------------------
p_out_dwnp_data     => i_vmir_dout,
p_out_dwnp_wd       => i_vmir_dout_en,
p_in_dwnp_rdy_n     => i_vcoldemasc_rdy_n,

-------------------------------
--Технологический
-------------------------------
p_in_tst            => (others=>'0'),
p_out_tst           => tst_vmir_out,

-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);



----------------------------------------------------
--Связь с HOST
----------------------------------------------------
--Выходной видеобуфер
m_vbufo : host_vbuf
port map(
din         => i_vmir_dout,
wr_en       => i_vmir_dout_en,
wr_clk      => p_in_clk,

dout        => p_out_vbufo_do,
rd_en       => p_in_vbufo_rd,
rd_clk      => p_in_host_clk,

empty       => p_out_vbufo_empty,
full        => open,
prog_full   => i_vcoldemasc_rdy_n,

rst         => p_in_rst
);


--маркер вычитываемого кадра:
process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then
    i_vfrmrk_out <= (others=>'0');

  elsif rising_edge(p_in_clk) then

    for ch in 0 to C_VCTRL_VCH_COUNT - 1 loop
        if p_in_vctrl_hrdchsel = ch then
          for buf in 0 to CI_VBUF_COUNT - 1 loop
            if i_vbuf_rd(ch) = buf then
              i_vfrmrk_out <= i_vfrmrk(ch)(buf);
            end if;
          end loop;
        end if;
    end loop;

  end if;
end process;

p_out_vctrl_hirq <= EXT(i_vrd_irq_width, p_out_vctrl_hirq'length);
p_out_vctrl_hdrdy <= EXT(i_vbuf_hold, p_out_vctrl_hdrdy'length);
p_out_vctrl_hfrmrk <= i_vfrmrk_out;


--END MAIN
end behavioral;

