-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 20.11.2010 16:27:42
-- Module Name : dsn_track_nik
--
-- Назначение/Описание :
--  Предобработка данных для Soft Следилки Никифорова
--
--  Результаты вычислений trc_nik_core.vhd - значения счетчиков данных ЭБ и
--  значения выделеные КТ ЭБ записываются в соответствующие облости ОЗУ
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Переделка заполнения буфера результата в соответствии с ТЗ Никифорова.
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.mem_wr_pkg.all;
use work.dsn_video_ctrl_pkg.all;
use work.dsn_track_nik_pkg.all;


entity dsn_track_nik is
generic(
G_SIM             : string:="OFF";
G_MODULE_USE      : string:="ON";

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
-- Управление от Хоста
-------------------------------
p_in_host_clk         : in   std_logic;

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);  --//
p_in_cfg_adr_ld       : in   std_logic;                     --//
p_in_cfg_adr_fifo     : in   std_logic;                     --//

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0); --//
p_in_cfg_wd           : in   std_logic;                     --//

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0); --//
p_in_cfg_rd           : in   std_logic;                     --//

p_in_cfg_done         : in   std_logic;                     --//

-------------------------------
-- Статусы и выходные данные
-------------------------------
--//Статусы
p_out_trc_hirq        : out   std_logic;                    --//Хост: Прерывание - Можно забирать данные обработки
p_out_trc_hdrdy       : out   std_logic;                    --//Хост: Флаг есть данные
p_out_trc_hfrmrk      : out   std_logic_vector(31 downto 0);--//Хост: Размер обработаных данных(байты)
p_in_trc_hrddone      : in    std_logic;                    --//Хост: Подтверждение вычитки данных обработки

p_out_trc_bufo_dout   : out   std_logic_vector(31 downto 0);--//Буфер результата обработки
p_in_trc_bufo_rd      : in    std_logic;                    --//Чтение буфера
p_out_trc_bufo_empty  : out   std_logic;                    --//Статус буфера

p_out_trc_busy        : out   std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);--//захват видеобуфера

-------------------------------
-- Связь с VCTRL
-------------------------------
p_in_vctrl_vrdprms    : in    TReaderVCHParams;            --//Параметры видеоканалов
p_in_vctrl_vfrrdy     : in    std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);--//Сигналы готовности кадра видеоканалов
p_in_vctrl_vbuf       : in    TVfrBufs;                    --//Номера видеобуферов
p_in_vctrl_vrowmrk    : in    TVMrks;                      --//Макреры строк видеоканалов

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_memarb_req      : out   std_logic;                    --//Запрос к арбитру ОЗУ на выполнение транзакции
p_in_memarb_en        : in    std_logic;                    --//Разрешение арбитра

p_out_mem_bank1h      : out   std_logic_vector(3 downto 0);
p_out_mem_ce          : out   std_logic;
p_out_mem_cw          : out   std_logic;
p_out_mem_rd          : out   std_logic;
p_out_mem_wr          : out   std_logic;
p_out_mem_term        : out   std_logic;
p_out_mem_adr         : out   std_logic_vector(G_MEM_AWIDTH - 1 downto 0);
p_out_mem_be          : out   std_logic_vector(G_MEM_DWIDTH / 8 - 1 downto 0);
p_out_mem_din         : out   std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_in_mem_dout         : in    std_logic_vector(G_MEM_DWIDTH - 1 downto 0);

p_in_mem_wf           : in    std_logic;
p_in_mem_wpf          : in    std_logic;
p_in_mem_re           : in    std_logic;
p_in_mem_rpe          : in    std_logic;

p_out_mem_clk         : out   std_logic;

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
end dsn_track_nik;

architecture behavioral of dsn_track_nik is

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

component trc_nik_core is
generic(
G_SIM : string:="OFF"
);
port(
-------------------------------
-- Управление
-------------------------------
p_in_prm_trc         : in    TTrcNikParam;    --//Параметры слежения
p_in_prm_vch         : in    TReaderVCHParam; --//Параметры видеоканала

p_in_ctrl            : in    TTrcNikCoreCtrl;
p_out_status         : out   TTrcNikCoreStatus;
p_out_hbuf_dsize     : out   std_logic_vector(15 downto 0);
p_out_ebout          : out   TTrcNikEBOs;
p_out_elout          : out   std_logic_vector(8 downto 0); --//Счетчик ЭС

--//--------------------------
--//
--//--------------------------
p_in_mem_dout        : in    std_logic_vector(31 downto 0); --//
p_in_mem_dout_en     : in    std_logic;                     --//
p_out_mem_dout_rdy_n : out   std_logic;                     --//Модуль готов к приему данных с p_in_mem_dout

p_out_mem_din        : out   std_logic_vector(31 downto 0); --//
p_in_mem_din_en      : in    std_logic;                     --//
p_out_mem_din_rdy_n  : out   std_logic;                     --//У Модуля есть данные для выдачи в p_out_mem_din

--//--------------------------
--//Запись данных в буфер ХОСТА
--//--------------------------
p_out_hirq           : out   std_logic;                     --//

p_out_hbuf_din       : out   std_logic_vector(31 downto 0); --//
p_out_hbuf_wr        : out   std_logic;                     --//
p_in_hbuf_wrrdy_n    : in    std_logic;                     --//
p_in_hbuf_empty      : in    std_logic;                     --//

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

component trc_nik_bufout
port(
din       : in std_logic_vector(31 downto 0);
wr_en     : in std_logic;
wr_clk    : in std_logic;

dout      : out std_logic_vector(31 downto 0);
rd_en     : in std_logic;
rd_clk    : in std_logic;

empty     : out std_logic;
full      : out std_logic;
prog_full : out std_logic;

--clk       : in std_logic;
rst       : in std_logic
);
end component;


signal i_cfg_adr_cnt                 : std_logic_vector(7 downto 0);

signal h_reg_ctrl                    : std_logic_vector(C_TRCNIK_REG_CTRL_LAST_BIT downto 0);
signal h_reg_tst0                    : std_logic_vector(C_TRCNKI_REG_TST0_LAST_BIT downto 0);
signal h_reg_opt                     : std_logic_vector(C_TRCNIK_REG_OPT_LAST_BIT downto 0);
signal h_reg_mem_rbuf                : std_logic_vector(31 downto 0);
signal h_reg_ip                      : TTrcNikIPs;

signal g_trc_prm                     : TGTrcNikParam;

type fsm_state is (
S_IDLE,
S_LD_PRMS,
S_ROW_FINED0,
S_ROW_FINED1,
S_ROW_FINED2,
S_MEM_SET_ADR,
S_MEM_START,
S_MEM_RD,
S_ROW_NXT,
S_WAIT_DRDY,
S_WAIT_DRDY2,
S_MEM_WPTR_CNTKT_CALC0,
S_MEM_WPTR_CNTKT_CALC1,
S_MEM_WPTR_CNTKT_CALC2,
S_MEM_STARTW_CNTKT,
S_MEM_W_CNTKT,
S_MEM_START_DKT,
S_MEM_W_DKT,
S_EXIT_CHK,
S_WAIT_HOST_ACK
);
signal fsm_state_cs: fsm_state;

--signal i_dlycnt                      : std_logic_vector(1 downto 0);

signal tmp_vch_vfrrdy                : std_logic_vector(C_VCTRL_VCH_COUNT_MAX-1 downto 0);
signal i_vch_vfrrdy                  : std_logic;
signal i_vch_prm                     : TReaderVCHParam;
signal i_vch_num                     : std_logic_vector(C_TRCNIK_REG_CTRL_VCH_M_BIT-C_TRCNIK_REG_CTRL_VCH_L_BIT downto 0);

--signal i_vfr_frmrk                   : std_logic_vector(31 downto 0);
signal i_vfr_mirror                  : TFrXYMirror;
signal i_vfr_row_cnt                 : std_logic_vector(G_MEM_VFR_L_BIT-G_MEM_VLINE_L_BIT downto 0);
signal i_vfr_active_row              : std_logic_vector(i_vfr_row_cnt'range);
signal i_vfr_skip_row                : std_logic_vector(i_vfr_row_cnt'range);
signal i_vfr_buf                     : std_logic_vector(C_VCTRL_MEM_VFR_M_BIT-C_VCTRL_MEM_VFR_L_BIT downto 0);

signal i_mem_ktcnt_ip_base           : std_logic_vector(31 downto 0);
signal i_mem_ktcnt_ip_offset         : std_logic_vector(15 downto 0);
signal i_calc_el_ip_new              : std_logic_vector(31 downto 0);
signal i_calc_el_new                 : std_logic_vector(31 downto 0);
signal i_calc_1el_allip              : std_logic_vector(31 downto 0);

signal i_mem_ktcnt_size              : std_logic_vector(31 downto 0);
signal i_mem_ktcnt_base              : std_logic_vector(31 downto 0);
signal i_mem_kt_base                 : std_logic_vector(31 downto 0);
signal i_mem_wdptr_ktcnt             : std_logic_vector(31 downto 0);
signal i_mem_wdptr_kt                : std_logic_vector(31 downto 0);
signal i_mem_rdptr                   : std_logic_vector(31 downto 0);
signal i_mem_rdbase                  : std_logic_vector(31 downto 0);
signal i_mem_adr                     : std_logic_vector(31 downto 0);
signal i_mem_rdtrn_len               : std_logic_vector(15 downto 0);
signal i_mem_wdtrn_len               : std_logic_vector(15 downto 0);
signal i_mem_trn_len                 : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq                 : std_logic_vector(15 downto 0);
signal i_mem_dir                     : std_logic;
signal i_mem_start                   : std_logic;
signal i_mem_done                    : std_logic;
signal i_mem_dout                    : std_logic_vector(31 downto 0);
signal i_mem_dout_en                 : std_logic;
signal i_mem_din                     : std_logic_vector(31 downto 0);
signal i_mem_din_en                  : std_logic;

signal i_trc_work                    : std_logic;
signal i_trc_busy                    : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_trc_txrdy_n                 : std_logic;
signal i_trc_rxrdy_n                 : std_logic;

signal i_trc_ebcnty                  : std_logic_vector(log2(CNIK_EBKT_LENY)+1 downto 0);

signal i_trc_prm                     : TTrcNikParam;
signal i_nik_ip_count                : std_logic_vector(C_TRCNIK_REG_OPT_IP_M_BIT-C_TRCNIK_REG_OPT_IP_L_BIT downto 0);

--type TArrayCntWidth is array (0 to 0) of std_logic_vector(3 downto 0);
--signal i_trc_irq_width_cnt           : TArrayCntWidth;
signal i_trc_irq_width_cnt           : std_logic_vector(3 downto 0);
signal i_trc_irq_width               : std_logic;--_vector(0 downto 0);
signal i_trc_irq                     : std_logic;--_vector(0 downto 0);
signal i_trc_drdy                    : std_logic;--_vector(0 downto 0);
signal i_trc_drdy_dly                : std_logic;
signal i_trc_dsize                   : std_logic_vector(31 downto 0);

signal i_trccore_ebout               : TTrcNikEBOs;
signal i_trccore_elout               : std_logic_vector(8 downto 0);
signal i_trccore_elout_r             : std_logic_vector(8 downto 0);
signal i_trccore_fst_calc_skip       : std_logic;
signal i_trccore_ctrl                : TTrcNikCoreCtrl;
signal i_trccore_status              : TTrcNikCoreStatus;

signal i_trcbufo_dsize               : std_logic_vector(15 downto 0);
signal g_trcbufo_dout_en             : std_logic;
signal i_trcbufo_dout                : std_logic_vector(31 downto 0);
signal i_trcbufo_dout_en             : std_logic;
signal i_trcbufo_din                 : std_logic_vector(31 downto 0);
signal i_trcbufo_din_en              : std_logic;
signal i_trcbufo_pfull               : std_logic;
signal i_trcbufo_empty               : std_logic;
--signal i_trcbufo_full                : std_logic;

signal i_hpkt_header                 : TTrcNikHPkt;
signal i_hpkt_header_data            : std_logic_vector(31 downto 0);
signal i_hpkt_header_cnt             : std_logic_vector(3 downto 0);

signal tst_dis_color                 : std_logic;
signal tst_ctrl                      : std_logic_vector(31 downto 0);
signal tst_trccore_out               : std_logic_vector(31 downto 0);
--signal tst_fsmstate                  : std_logic_vector(4 downto 0);
--signal tst_fsmstate_dly              : std_logic_vector(tst_fsmstate'range);



--MAIN
begin


--//--------------------------------------------------
--//Конфигурирование модуля dsn_track_nik.vhd
--//--------------------------------------------------
--//Счетчик адреса регистров
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    i_cfg_adr_cnt<=(others=>'0');
  elsif p_in_host_clk'event and p_in_host_clk='1' then
    if p_in_cfg_adr_ld='1' then
      i_cfg_adr_cnt<=p_in_cfg_adr;
    else
      if p_in_cfg_adr_fifo='0' and (p_in_cfg_wd='1' or p_in_cfg_rd='1') then
        i_cfg_adr_cnt<=i_cfg_adr_cnt+1;
      end if;
    end if;
  end if;
end process;

--//Запись регистров
process(p_in_rst,p_in_host_clk)
begin
  if p_in_rst='1' then
    h_reg_ctrl<=(others=>'0');
    h_reg_tst0<=(others=>'0');
    h_reg_opt<=(others=>'0');
    h_reg_mem_rbuf<=(others=>'0');

    g_trc_prm.mem_wd_trnlen(7 downto 0)<=(others=>'0');
    g_trc_prm.mem_rd_trnlen(7 downto 0)<=(others=>'0');
    for x in 0 to C_TRCNIK_VCH_COUNT-1 loop
      g_trc_prm.ch(x).mem_arbuf<=(others=>'0');
      g_trc_prm.ch(x).opt<=(others=>'0');
      for i in 0 to C_TRCNIK_IP_COUNT-1 loop
      g_trc_prm.ch(x).ip(i).p1<=(others=>'0');
      g_trc_prm.ch(x).ip(i).p2<=(others=>'0');
      end loop;
    end loop;

  elsif p_in_host_clk'event and p_in_host_clk='1' then

    if p_in_cfg_wd='1' then
      if i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_CTRL, i_cfg_adr_cnt'length) then h_reg_ctrl<=p_in_cfg_txdata(h_reg_ctrl'high downto 0);

        for y in 0 to C_TRCNIK_VCH_COUNT-1 loop
          g_trc_prm.ch(y).mem_arbuf<=h_reg_mem_rbuf;
          g_trc_prm.ch(y).opt <= EXT(h_reg_opt, g_trc_prm.ch(y).opt'length);

          for i in 0 to C_TRCNIK_IP_COUNT-1 loop
          g_trc_prm.ch(y).ip(i) <= h_reg_ip(i);
          end loop;
        end loop;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_MEM_ADR_L, i_cfg_adr_cnt'length) then h_reg_mem_rbuf(15 downto 0)<=p_in_cfg_txdata;
      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_MEM_ADR_M, i_cfg_adr_cnt'length) then h_reg_mem_rbuf(31 downto 16)<=p_in_cfg_txdata;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_OPT, i_cfg_adr_cnt'length) then h_reg_opt<=p_in_cfg_txdata(h_reg_opt'high downto 0);

      elsif i_cfg_adr_cnt(i_cfg_adr_cnt'high downto 3)=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_IP0, (i_cfg_adr_cnt'high - 3 + 1)) then
          for i in 0 to C_TRCNIK_IP_COUNT-1 loop
            if i_cfg_adr_cnt(2 downto 0)=i then
              h_reg_ip(i).p1<=p_in_cfg_txdata(7 downto 0);
              h_reg_ip(i).p2<=p_in_cfg_txdata(15 downto 8);
            end if;
          end loop;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_MEM_CTRL, i_cfg_adr_cnt'length) then
        g_trc_prm.mem_wd_trnlen(7 downto 0)<= p_in_cfg_txdata(7 downto 0);
        g_trc_prm.mem_rd_trnlen(7 downto 0)<= p_in_cfg_txdata(15 downto 8);

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_TST0, i_cfg_adr_cnt'length) then h_reg_tst0<=p_in_cfg_txdata(h_reg_tst0'high downto 0);

      end if;

    end if;--//if p_in_cfg_wd='1' then

  end if;
end process;

--//Чтение регистров
process(p_in_rst,p_in_host_clk)
  variable var_val : std_logic_vector(p_out_cfg_rxdata'range);
begin
  if p_in_rst='1' then
    var_val:=(others=>'0');
    p_out_cfg_rxdata<=(others=>'0');

  elsif p_in_host_clk'event and p_in_host_clk='1' then
     var_val := (others=>'0');

    if p_in_cfg_rd='1' then
      if i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_CTRL, i_cfg_adr_cnt'length) then var_val:=EXT(h_reg_ctrl, var_val'length);

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_MEM_ADR_L, i_cfg_adr_cnt'length) then var_val:=h_reg_mem_rbuf(15 downto 0);
      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_MEM_ADR_M, i_cfg_adr_cnt'length) then var_val:=h_reg_mem_rbuf(31 downto 16);

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_OPT, i_cfg_adr_cnt'length) then var_val:=EXT(h_reg_opt, var_val'length);

      elsif i_cfg_adr_cnt(i_cfg_adr_cnt'high downto 3)=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_IP0, (i_cfg_adr_cnt'high - 3 + 1)) then
          for i in 0 to C_TRCNIK_IP_COUNT-1 loop
            if i_cfg_adr_cnt(2 downto 0)=i then
              var_val( 7 downto 0):=h_reg_ip(i).p1;
              var_val(15 downto 8):=h_reg_ip(i).p2;
            end if;
          end loop;

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_MEM_CTRL, i_cfg_adr_cnt'length) then
        var_val( 7 downto 0):=g_trc_prm.mem_wd_trnlen(7 downto 0);
        var_val(15 downto 8):=g_trc_prm.mem_rd_trnlen(7 downto 0);

      elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_TRCNIK_REG_TST0, i_cfg_adr_cnt'length) then var_val:=EXT(h_reg_tst0, var_val'length);

      end if;

      p_out_cfg_rxdata<=var_val;
    end if; --//if p_in_cfg_rd='1' then

  end if;
end process;

i_vch_num<=h_reg_ctrl(C_TRCNIK_REG_CTRL_VCH_M_BIT downto C_TRCNIK_REG_CTRL_VCH_L_BIT);




gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    tst_fsmstate_dly<=(others=>'0');
--    p_out_tst(0)<='0';
--
--  elsif p_in_clk'event and p_in_clk='1' then
--    tst_fsmstate_dly<=tst_fsmstate;
--
--    p_out_tst(0)<=OR_reduce(tst_fsmstate_dly) or
--                  tst_trccore_out(0);
--
--  end if;
--end process;
--p_out_tst(31 downto 1)<=(others=>'0');
--
--tst_fsmstate<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsmstate'length) when fsm_state_cs=S_LD_PRMS else
--              CONV_STD_LOGIC_VECTOR(16#02#,tst_fsmstate'length) when fsm_state_cs=S_ROW_FINED0 else
--              CONV_STD_LOGIC_VECTOR(16#03#,tst_fsmstate'length) when fsm_state_cs=S_ROW_FINED1 else
--              CONV_STD_LOGIC_VECTOR(16#04#,tst_fsmstate'length) when fsm_state_cs=S_ROW_FINED2 else
--              CONV_STD_LOGIC_VECTOR(16#05#,tst_fsmstate'length) when fsm_state_cs=S_MEM_SET_ADR else
--              CONV_STD_LOGIC_VECTOR(16#06#,tst_fsmstate'length) when fsm_state_cs=S_MEM_START else
--              CONV_STD_LOGIC_VECTOR(16#07#,tst_fsmstate'length) when fsm_state_cs=S_MEM_RD else
--              CONV_STD_LOGIC_VECTOR(16#08#,tst_fsmstate'length) when fsm_state_cs=S_ROW_NXT else
--              CONV_STD_LOGIC_VECTOR(16#09#,tst_fsmstate'length) when fsm_state_cs=S_WAIT_DRDY else
--              CONV_STD_LOGIC_VECTOR(16#0A#,tst_fsmstate'length) when fsm_state_cs=S_WAIT_DRDY2,
--              CONV_STD_LOGIC_VECTOR(16#0B#,tst_fsmstate'length) when fsm_state_cs=S_MEM_WPTR_CNTKT_CALC0,
--              CONV_STD_LOGIC_VECTOR(16#0C#,tst_fsmstate'length) when fsm_state_cs=S_MEM_WPTR_CNTKT_CALC1,
--              CONV_STD_LOGIC_VECTOR(16#0D#,tst_fsmstate'length) when fsm_state_cs=S_MEM_WPTR_CNTKT_CALC2,
--              CONV_STD_LOGIC_VECTOR(16#0E#,tst_fsmstate'length) when fsm_state_cs=S_MEM_STARTW_CNTKT else
--              CONV_STD_LOGIC_VECTOR(16#0F#,tst_fsmstate'length) when fsm_state_cs=S_MEM_W_CNTKT else
--              CONV_STD_LOGIC_VECTOR(16#10#,tst_fsmstate'length) when fsm_state_cs=S_MEM_START_DKT else
--              CONV_STD_LOGIC_VECTOR(16#11#,tst_fsmstate'length) when fsm_state_cs=S_MEM_W_DKT else
--              CONV_STD_LOGIC_VECTOR(16#12#,tst_fsmstate'length) when fsm_state_cs=S_EXIT_CHK else
--              CONV_STD_LOGIC_VECTOR(16#13#,tst_fsmstate'length) when fsm_state_cs=S_WAIT_HOST_ACK else
--              CONV_STD_LOGIC_VECTOR(16#00#,tst_fsmstate'length);-- when fsm_state_cs=S_IDLE else


tst_ctrl<=EXT(h_reg_tst0, tst_ctrl'length);

tst_dis_color<=tst_ctrl(C_TRCNIK_REG_TST0_COLOR_DIS_BIT);


--//----------------------------------------------
--//Статусы
--//----------------------------------------------
p_out_trc_hdrdy<=i_trc_drdy;
p_out_trc_hirq <=i_trc_irq_width;

p_out_trc_hfrmrk<=i_trc_dsize;

p_out_trc_busy<=i_trc_busy;

--//Растягиваем импульcы генерации прерывания
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_trc_irq_width_cnt<=(others=>'0');
    i_trc_irq_width<='0';

    i_trc_drdy_dly<='0';
    i_trc_irq<='0';
  elsif p_in_clk'event and p_in_clk='1' then

      i_trc_drdy_dly<=i_trc_drdy;
      i_trc_irq<=i_trc_drdy and not i_trc_drdy_dly;

        if i_trc_irq='1' then
          i_trc_irq_width<='1';
        elsif i_trc_irq_width_cnt(3)='1' then
          i_trc_irq_width<='0';
        end if;

        if i_trc_irq_width='0' then
          i_trc_irq_width_cnt<=(others=>'0');
        else
          i_trc_irq_width_cnt<=i_trc_irq_width_cnt+1;
        end if;
  end if;
end process;


tmp_vch_vfrrdy<=EXT(p_in_vctrl_vfrrdy, tmp_vch_vfrrdy'length);
--//Выбор сигнала готовности кадра в зависимости от назначеного канала слежения:
gen_vch_count1 : if C_VCTRL_VCH_COUNT=1 generate
begin
i_vch_vfrrdy<=tmp_vch_vfrrdy(0);
end generate gen_vch_count1;

gen_vch_count2 : if C_VCTRL_VCH_COUNT=2 generate
begin
i_vch_vfrrdy<=tmp_vch_vfrrdy(0) when i_vch_num=CONV_STD_LOGIC_VECTOR(0, i_vch_num'length) else
              tmp_vch_vfrrdy(1);
end generate gen_vch_count2;

gen_vch_count3 : if C_VCTRL_VCH_COUNT=3 generate
begin
i_vch_vfrrdy<=tmp_vch_vfrrdy(0) when i_vch_num=CONV_STD_LOGIC_VECTOR(0, i_vch_num'length) else
              tmp_vch_vfrrdy(1) when i_vch_num=CONV_STD_LOGIC_VECTOR(1, i_vch_num'length) else
              tmp_vch_vfrrdy(2);
end generate gen_vch_count3;


--//----------------------------------------------
--//Инициализация
--//----------------------------------------------
i_nik_ip_count<=i_trc_prm.opt(C_TRCNIK_REG_OPT_IP_M_BIT downto C_TRCNIK_REG_OPT_IP_L_BIT);

i_calc_1el_allip<=i_vch_prm.fr_size.activ.pix * EXT(i_nik_ip_count, i_vch_prm.fr_size.activ.pix'length);
i_mem_ktcnt_size<=i_calc_1el_allip(15 downto 0) * EXT(i_vch_prm.fr_size.activ.row(15 downto 2), 16);

i_mem_ktcnt_base<=i_trc_prm.mem_arbuf;
i_mem_kt_base<=i_trc_prm.mem_arbuf + i_mem_ktcnt_size;



--//----------------------------------------------
--//Автомат Чтения видео кадра
--//----------------------------------------------
i_vch_prm.fr_size.activ.row<=EXT(i_vfr_active_row, i_vch_prm.fr_size.activ.row'length);
i_vch_prm.fr_mirror<=i_vfr_mirror;


--//Логика работы автомата
process(p_in_rst,p_in_clk)
  variable vfr_active_row_end : std_logic_vector(i_vfr_row_cnt'range);
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;

    i_calc_el_ip_new<=(others=>'0');
    i_calc_el_new<=(others=>'0');
    i_mem_ktcnt_ip_offset<=(others=>'0');
    i_mem_ktcnt_ip_base<=(others=>'0');
    i_mem_wdptr_ktcnt<=(others=>'0');
    i_mem_wdptr_kt<=(others=>'0');
    i_mem_rdbase<=(others=>'0');
    i_mem_rdptr<=(others=>'0');
    i_mem_adr<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_dlen_rq<=(others=>'0');
    i_mem_dir<='0';
    i_mem_start<='0';
    i_mem_rdtrn_len<=(others=>'0');
    i_mem_wdtrn_len<=(others=>'0');

    i_vfr_buf<=(others=>'0');
    i_vfr_mirror.pix<='0';
    i_vfr_mirror.row<='0';
    i_vfr_row_cnt<=(others=>'0');
      vfr_active_row_end:=(others=>'0');
    i_vfr_active_row<=(others=>'0');
    i_vfr_skip_row<=(others=>'0');
--    i_vfr_frmrk<=(others=>'0');

    i_vch_prm.mem_adr<=(others=>'0');
    i_vch_prm.fr_size.skip.pix<=(others=>'0');
    i_vch_prm.fr_size.skip.row<=(others=>'0');
    i_vch_prm.fr_size.activ.pix<=(others=>'0');
--    i_vch_prm.fr_size.activ.row<=(others=>'0');
    i_vch_prm.fr_color_fst<=(others=>'0');
    i_vch_prm.fr_color<='0';
    i_vch_prm.fr_pcolor<='0';
    i_vch_prm.fr_zoom<=(others=>'0');
    i_vch_prm.fr_zoom_type<='0';

    i_trc_prm.mem_arbuf<=(others=>'0');
    i_trc_prm.opt<=(others=>'0');
    for i in 0 to C_TRCNIK_IP_COUNT-1 loop
    i_trc_prm.ip(i).p1<=(others=>'0');
    i_trc_prm.ip(i).p2<=(others=>'0');
    end loop;

    i_trc_drdy<='0';
    i_trc_work<='0';
    i_trc_busy<=(others=>'0');
    i_trc_dsize<=(others=>'0');

    i_trc_ebcnty<=(others=>'0');
    i_trccore_fst_calc_skip<='0';
    i_trccore_ctrl.start<='0';
    i_trccore_ctrl.fr_new<='0';
    i_trccore_ctrl.mem_done<='0';
    i_trccore_elout_r<=(others=>'0');

    i_hpkt_header_cnt<=(others=>'0');

    g_trcbufo_dout_en<='0';

--    i_dlycnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    i_trc_work<=h_reg_ctrl(C_TRCNIK_REG_CTRL_WORK_BIT);

    case fsm_state_cs is

      --//------------------------------------
      --//Ждем сигнализации Кадр ГОТОВ
      --//------------------------------------
      when S_IDLE =>

        --//Ждем от Хоста команды начала работы
        if i_trc_work='1' then

            --//Ждем кода VCTRL сформирует кадр в ОЗУ
            if i_vch_vfrrdy='1' then

              --//Защелкиваем маркер обрабатываемого кадра
              for i in 0 to C_VCTRL_VCH_COUNT-1 loop
                if i_vch_num=i then
--                  i_vfr_frmrk<=p_in_vctrl_vrowmrk(i);
                  i_trc_busy(i)<='1';
                end if;
              end loop;

              --//Синхронизация параметров:
              for i in 0 to C_TRCNIK_VCH_COUNT-1 loop
                i_trc_prm<=g_trc_prm.ch(i);
              end loop;

              fsm_state_cs <= S_LD_PRMS;
            end if;

        end if;

      --//------------------------------------
      --//Загрузка параметров
      --//------------------------------------
      when S_LD_PRMS =>

        --//Загрузка праметров Видео канала
        for i in 0 to C_VCTRL_VCH_COUNT-1 loop
          if i_vch_num=i then

            --//--------------------------
            --//
            --//--------------------------
            i_vfr_buf<=p_in_vctrl_vbuf(i);

            --//--------------------------
            --//Банк ОЗУ:
            --//--------------------------
            i_mem_rdbase<=p_in_vctrl_vrdprms(i).mem_adr;

            --//--------------------------
            --//
            --//--------------------------
            i_vch_prm.fr_color    <=p_in_vctrl_vrdprms(i).fr_color and not tst_dis_color;
            i_vch_prm.fr_color_fst<=p_in_vctrl_vrdprms(i).fr_color_fst;

            --//--------------------------
            --//Отзеркаливание:
            --//--------------------------
            i_vfr_mirror.pix<=p_in_vctrl_vrdprms(i).fr_mirror.pix;
            i_vfr_mirror.row<=p_in_vctrl_vrdprms(i).fr_mirror.row;

            --//--------------------------
            --//Пиксели:
            --//--------------------------
            i_vch_prm.fr_size.activ.pix<=p_in_vctrl_vrdprms(i).fr_size.activ.pix;
            i_vch_prm.fr_size.skip.pix<=p_in_vctrl_vrdprms(i).fr_size.skip.pix;

            --//--------------------------
            --//Строки:
            --//--------------------------
            i_vfr_active_row<=p_in_vctrl_vrdprms(i).fr_size.activ.row(i_vfr_active_row'high downto 0);
            i_vfr_skip_row<=p_in_vctrl_vrdprms(i).fr_size.skip.row(i_vfr_skip_row'high downto 0);

            --//Инициализируем счетчик строк
            if p_in_vctrl_vrdprms(i).fr_mirror.row='0' then
              i_vfr_row_cnt<=p_in_vctrl_vrdprms(i).fr_size.skip.row(i_vfr_row_cnt'high downto 0);
            else
              i_vfr_row_cnt<=p_in_vctrl_vrdprms(i).fr_size.skip.row(i_vfr_row_cnt'high downto 0) + p_in_vctrl_vrdprms(i).fr_size.activ.row(i_vfr_row_cnt'high downto 0);
            end if;

          end if;
        end loop;

        i_mem_rdtrn_len<=EXT(g_trc_prm.mem_rd_trnlen, i_mem_rdtrn_len'length);
        i_mem_wdtrn_len<=EXT(g_trc_prm.mem_wd_trnlen, i_mem_rdtrn_len'length);
--        i_mem_wdtrn_len(15 downto 10)<=(others=>'0');
--        i_mem_wdtrn_len(9 downto 2)<=g_trc_prm.mem_wd_trnlen;
--        i_mem_wdtrn_len(1 downto 0)<=(others=>'0');

        i_mem_rdptr<=(others=>'0');
        i_mem_ktcnt_ip_offset<=(others=>'0');
--        i_mem_wdptr_ktcnt<=(others=>'0');
        i_mem_wdptr_kt<=(others=>'0');

        i_trc_ebcnty<=(others=>'0');
        i_trccore_fst_calc_skip<='0';
        i_trccore_ctrl.fr_new<='1';

        fsm_state_cs <= S_ROW_FINED0;

      --//------------------------------------
      --//Ищем строку видео кадра
      --//------------------------------------
      when S_ROW_FINED0 =>

        i_trccore_ctrl.fr_new<='0';

        if i_vfr_mirror.row='1' then
          --//Отзеркаливание по Y - РАЗРЕШЕНО
          --//Инициализируем счетчик строк
          i_vfr_row_cnt<=i_vfr_row_cnt-1;
        end if;

        vfr_active_row_end:=i_vfr_active_row - 1;

        fsm_state_cs <= S_ROW_FINED1;

      --//------------------------------------
      --//
      --//------------------------------------
      when S_ROW_FINED1 =>

        --//Запускаем работу модуля trc_nik_core.vhd
        i_trccore_ctrl.start<='1';
        fsm_state_cs <= S_ROW_FINED2;

      --//------------------------------------
      --//
      --//------------------------------------
      when S_ROW_FINED2 =>

        i_trccore_ctrl.start<='0';

        fsm_state_cs <= S_MEM_SET_ADR;

      --//------------------------------------
      --//Запускаем операцию чтения ОЗУ
      --//------------------------------------
      when S_MEM_SET_ADR =>

        i_mem_rdptr(i_mem_rdptr'high downto G_MEM_VCH_M_BIT+1)<=(others=>'0');
        i_mem_rdptr(G_MEM_VCH_M_BIT downto G_MEM_VCH_L_BIT)<=i_vch_num(G_MEM_VCH_M_BIT-G_MEM_VCH_L_BIT downto 0);
        i_mem_rdptr(G_MEM_VFR_M_BIT downto G_MEM_VFR_L_BIT)<=i_vfr_buf;
        i_mem_rdptr(G_MEM_VLINE_M_BIT downto G_MEM_VLINE_L_BIT)<=i_vfr_row_cnt(G_MEM_VLINE_M_BIT-G_MEM_VLINE_L_BIT downto 0);
        i_mem_rdptr(G_MEM_VLINE_L_BIT-1 downto 0)<=i_vch_prm.fr_size.skip.pix(G_MEM_VLINE_L_BIT-1 downto 0);

        fsm_state_cs <= S_MEM_START;

      --//------------------------------------
      --//Запускаем операцию чтения ОЗУ
      --//------------------------------------
      when S_MEM_START =>

        i_mem_dlen_rq<=i_vch_prm.fr_size.activ.pix;
        i_mem_adr<=i_mem_rdbase + i_mem_rdptr;
        i_mem_trn_len<=i_mem_rdtrn_len;
        i_mem_dir<=C_MEMWR_READ;
        i_mem_start<='1';
        fsm_state_cs <= S_MEM_RD;

      --//----------------------------------------------
      --//Чтение данных
      --//----------------------------------------------
      when S_MEM_RD =>

        i_mem_start<='0';

        if i_mem_done='1' then
        --//Операция выполнена
          fsm_state_cs <= S_ROW_NXT;
        end if;

      --//----------------------------------------------
      --//Ждем запроса на чтение следующей строки
      --//----------------------------------------------
      when S_ROW_NXT =>

        if i_trccore_status.nxt_row='1' then

          if (i_vfr_mirror.row='0' and i_vfr_row_cnt=(i_vfr_skip_row + vfr_active_row_end)) or
             (i_vfr_mirror.row='1' and i_vfr_row_cnt=i_vfr_skip_row)then
              fsm_state_cs <= S_WAIT_DRDY;

          else

              if i_vfr_mirror.row='1' then
                i_vfr_row_cnt<=i_vfr_row_cnt-1;
              else
                i_vfr_row_cnt<=i_vfr_row_cnt+1;
              end if;

              if i_vch_prm.fr_color='1' and i_trc_ebcnty=CONV_STD_LOGIC_VECTOR(CNIK_EBKT_LENY+1, i_trc_ebcnty'length) and i_trccore_fst_calc_skip='0' then
              --//Color VFrame:
              --//Управление загрузкой строк в модуль trc_nik_core.vhd
              --//первый раз загружаем 6-ть(CNIK_EBKT_LENY+1) строк, затем, до конца кадра
              --//загружаем загружаем по 4-е (CNIK_EBKT_LENY-1) строки.
              --//Так сделано потому что для начала работы модуля vsobel_main.vhd и vcoldemosaic_main.vhd в них необходимо загрузить
              --//по одной строке.
                i_trccore_fst_calc_skip<='1';
                i_trc_ebcnty<=(others=>'0');
                fsm_state_cs <= S_WAIT_DRDY;

              elsif i_vch_prm.fr_color='0' and i_trc_ebcnty=CONV_STD_LOGIC_VECTOR(CNIK_EBKT_LENY, i_trc_ebcnty'length) and i_trccore_fst_calc_skip='0' then
              --//Gray VFrame:
              --//Управление загрузкой строк в модуль trc_nik_core.vhd
              --//первый раз загружаем 5-ть(CNIK_EBKT_LENY) строк, затем, до конца кадра
              --//загружаем загружаем по 4-е (CNIK_EBKT_LENY-1) строки.
              --//Так сделано потому что для начала работы модуля vsobel_main.vhd в него необходимо загрузить 1-у строку
                i_trccore_fst_calc_skip<='1';
                i_trc_ebcnty<=(others=>'0');
                fsm_state_cs <= S_WAIT_DRDY;

              elsif i_trc_ebcnty=CONV_STD_LOGIC_VECTOR(CNIK_EBKT_LENY-1, i_trc_ebcnty'length) and i_trccore_fst_calc_skip='1' then
                i_trc_ebcnty<=(others=>'0');
                fsm_state_cs <= S_WAIT_DRDY;

              else
                i_trc_ebcnty<=i_trc_ebcnty + 1;
                fsm_state_cs <= S_ROW_FINED2;
              end if;

          end if;

        end if;



      --//----------------------------------------------
      --//Ждем разрешения отправки данных
      --//----------------------------------------------
      when S_WAIT_DRDY =>

        i_trccore_ctrl.mem_done<='0';
        fsm_state_cs <= S_WAIT_DRDY2;

      when S_WAIT_DRDY2 =>

        if i_trccore_status.drdy='1' then
--          if i_dlycnt(1)='1' then
--            i_dlycnt<=(others=>'0');
            fsm_state_cs <= S_MEM_WPTR_CNTKT_CALC0;
--          else
--            i_dlycnt<=i_dlycnt + 1;
--          end if;
        end if;

      --//------------------------------------
      --//Запись данных ОЗУ (значения счетчиков данных ЭБ)
      --//------------------------------------
      --//Вычисляем указатель записи для счетчиков выделеных КТ
      when S_MEM_WPTR_CNTKT_CALC0 =>

        i_trccore_elout_r<=i_trccore_elout;
        if i_trccore_elout_r/=i_trccore_elout then
        --//новая ЭС
          i_mem_ktcnt_ip_offset<=(others=>'0');
        end if;

        i_calc_el_ip_new<=i_vch_prm.fr_size.activ.pix * EXT(i_hpkt_header_cnt, i_vch_prm.fr_size.activ.pix'length);
        i_calc_el_new<=EXT(i_calc_1el_allip(15 downto 0), 16) * EXT(i_trccore_elout, 16);
        fsm_state_cs <= S_MEM_WPTR_CNTKT_CALC1;

      when S_MEM_WPTR_CNTKT_CALC1 =>

        i_mem_ktcnt_ip_base<=i_calc_el_new + i_calc_el_ip_new;
        fsm_state_cs <= S_MEM_WPTR_CNTKT_CALC2;

      when S_MEM_WPTR_CNTKT_CALC2 =>

        i_mem_wdptr_ktcnt<=EXT(i_mem_ktcnt_ip_base, i_mem_wdptr_ktcnt'length) + EXT(i_mem_ktcnt_ip_offset, i_mem_wdptr_ktcnt'length);
        fsm_state_cs <= S_MEM_STARTW_CNTKT;

      --//----------------------------------------------
      --//Запись данных
      --//----------------------------------------------
      when S_MEM_STARTW_CNTKT =>

        --//4-счетчика
        i_mem_dlen_rq <= CONV_STD_LOGIC_VECTOR(1, i_mem_dlen_rq'length);--//размер в DW
        i_mem_adr<=i_mem_ktcnt_base + i_mem_wdptr_ktcnt;
        i_mem_trn_len<=i_mem_wdtrn_len;
        i_mem_dir<=C_MEMWR_WRITE;
        i_mem_start<='1';

        fsm_state_cs <= S_MEM_W_CNTKT;

      when S_MEM_W_CNTKT =>

        i_mem_start<='0';

        if i_mem_done='1' then
        --//Операция выполнена

          if i_hpkt_header_cnt=i_nik_ip_count-1 then
          --//Записал все счетчики для всех используемых ИП

              i_hpkt_header_cnt<=(others=>'0');
              i_mem_ktcnt_ip_offset<=i_mem_ktcnt_ip_offset + (i_mem_dlen_rq(13 downto 0)&"00");--//Т.к адресс в байтах

              if i_trcbufo_empty='0' then
              --//Есть выделеные КТ. Переходим к записи в ОЗУ
                fsm_state_cs <= S_MEM_START_DKT;
              else

                  i_trccore_ctrl.mem_done<='1';

                  if i_trccore_status.idle='1' then
                    fsm_state_cs <= S_EXIT_CHK;
                  else
                    fsm_state_cs <= S_WAIT_DRDY;
                  end if;

              end if;
          else
            --//переходи к записи счетчиков для следующего ИП
            i_hpkt_header_cnt<=i_hpkt_header_cnt + 1;
            fsm_state_cs <= S_MEM_WPTR_CNTKT_CALC0;
          end if;

        end if;

      --//------------------------------------
      --//Запись данных ОЗУ (выделеные КТ ЭБ)
      --//------------------------------------
      when S_MEM_START_DKT =>

        g_trcbufo_dout_en<='1';
        i_mem_dlen_rq <= i_trcbufo_dsize;--//размер в DW
        i_mem_adr<=i_mem_kt_base + i_mem_wdptr_kt;
        i_mem_trn_len<=i_mem_wdtrn_len;
        i_mem_dir<=C_MEMWR_WRITE;
        i_mem_start<='1';

        fsm_state_cs <= S_MEM_W_DKT;

      --//----------------------------------------------
      --//Запись данных
      --//----------------------------------------------
      when S_MEM_W_DKT =>

        i_mem_start<='0';

        if i_mem_done='1' then
        --//Операция выполнена

          --//Update adr
          i_mem_wdptr_kt<=i_mem_wdptr_kt + ("0000000000000000"&i_mem_dlen_rq(13 downto 0)&"00");--//Адрес в байтах

          g_trcbufo_dout_en<='0';
          i_trccore_ctrl.mem_done<='1';

          if i_trccore_status.idle='1' then
            fsm_state_cs <= S_EXIT_CHK;
          else
            fsm_state_cs <= S_WAIT_DRDY;
          end if;

        end if;

      --//----------------------------------------------
      --//Проверка отработки всего кадра
      --//----------------------------------------------
      when S_EXIT_CHK =>

        i_trccore_ctrl.mem_done<='0';

        if (i_vfr_mirror.row='0' and i_vfr_row_cnt=(i_vfr_skip_row + vfr_active_row_end)) or
           (i_vfr_mirror.row='1' and i_vfr_row_cnt=i_vfr_skip_row)then

            i_trc_drdy<='1';
            i_trc_dsize<=i_mem_wdptr_kt + i_mem_ktcnt_size;

            fsm_state_cs <= S_WAIT_HOST_ACK;
        else
          fsm_state_cs <= S_ROW_FINED1;
        end if;

      --//----------------------------------------------
      --//Ждем ответ от ХОСТА - данные принял
      --//----------------------------------------------
      when S_WAIT_HOST_ACK =>

        if p_in_trc_hrddone='1' then

          i_trc_drdy<='0';
          i_trc_busy<=(others=>'0');
          fsm_state_cs <= S_IDLE;
        end if;

    end case;

  end if;
end process;



--//------------------------------------------------------
--//Модуль записи/чтения данных ОЗУ (mem_ctrl.vhd)
--//------------------------------------------------------
m_mem_wr : mem_wr
generic map(
G_MEM_BANK_M_BIT => G_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => G_MEM_BANK_L_BIT,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_adr     => i_mem_adr,
p_in_cfg_mem_trn_len => i_mem_trn_len,
p_in_cfg_mem_dlen_rq => i_mem_dlen_rq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_start,
p_out_cfg_mem_done   => i_mem_done,

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout  => i_mem_din,
p_out_usr_txbuf_rd   => i_mem_din_en,
p_in_usr_txbuf_empty => i_trc_txrdy_n,

p_out_usr_rxbuf_din  => i_mem_dout,
p_out_usr_rxbuf_wd   => i_mem_dout_en,
p_in_usr_rxbuf_full  => i_trc_rxrdy_n,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_memarb_req     => p_out_memarb_req,
p_in_memarb_en       => p_in_memarb_en,

p_out_mem_bank1h     => p_out_mem_bank1h,
p_out_mem_ce         => p_out_mem_ce,
p_out_mem_cw         => p_out_mem_cw,
p_out_mem_rd         => p_out_mem_rd,
p_out_mem_wr         => p_out_mem_wr,
p_out_mem_term       => p_out_mem_term,
p_out_mem_adr        => p_out_mem_adr,
p_out_mem_be         => p_out_mem_be,
p_out_mem_din        => p_out_mem_din,
p_in_mem_dout        => p_in_mem_dout,

p_in_mem_wf          => p_in_mem_wf,
p_in_mem_wpf         => p_in_mem_wpf,
p_in_mem_re          => p_in_mem_re,
p_in_mem_rpe         => p_in_mem_rpe,

p_out_mem_clk        => p_out_mem_clk,

-------------------------------
--System
-------------------------------
p_in_tst             => "00000000000000000000000000000000",
p_out_tst            => open,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);


--//-----------------------------
--//Ядро модуля слежения:
--//-----------------------------
m_trccore : trc_nik_core
generic map(
G_SIM => G_SIM
)
port map(
-------------------------------
-- Управление
-------------------------------
p_in_prm_trc         => i_trc_prm,
p_in_prm_vch         => i_vch_prm,

p_in_ctrl            => i_trccore_ctrl,
p_out_status         => i_trccore_status,
p_out_hbuf_dsize     => i_trcbufo_dsize,
p_out_ebout          => i_trccore_ebout,
p_out_elout          => i_trccore_elout,

--//--------------------------
--//Связь с ОЗУ
--//--------------------------
p_in_mem_dout        => i_mem_dout,
p_in_mem_dout_en     => i_mem_dout_en,
p_out_mem_dout_rdy_n => i_trc_rxrdy_n,

p_out_mem_din        => open,--i_mem_din,
p_in_mem_din_en      => '0',--i_mem_din_en,
p_out_mem_din_rdy_n  => open,--i_trc_txrdy_n,

--//--------------------------
--//Запись данных в буфер ХОСТА
--//--------------------------
p_out_hirq           => open,--i_trc_irq,

p_out_hbuf_din       => i_trcbufo_din,
p_out_hbuf_wr        => i_trcbufo_din_en,
p_in_hbuf_wrrdy_n    => i_trcbufo_pfull,
p_in_hbuf_empty      => i_trcbufo_empty,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => tst_ctrl,
p_out_tst            => tst_trccore_out,

-------------------------------
--System
-------------------------------
p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);



--//-----------------------------
--//Выходной буфер. Результат вычислений trc_nik_core.vhd
--//1. Запись в ОЗУ значений счетчиков данных ЭБ
--//2. Запись в ОЗУ значений выделеные КТ ЭБ
--//-----------------------------
gen_hd:  for i in 0 to CNIK_HPKT_COUNT_MAX-1 generate
i_hpkt_header(i)(31 downto 24)<=i_trccore_ebout(4*i + 3).cnt;
i_hpkt_header(i)(23 downto 16)<=i_trccore_ebout(4*i + 2).cnt;
i_hpkt_header(i)(15 downto 8) <=i_trccore_ebout(4*i + 1).cnt;
i_hpkt_header(i)(7 downto 0)  <=i_trccore_ebout(4*i + 0).cnt;
end generate gen_hd;

--gen_hd1:  if CNIK_HPKT_COUNT_MAX=1 generate
--i_hpkt_header_data<=i_hpkt_header(0);
--end generate gen_hd1;
--
--gen_hd2:  if CNIK_HPKT_COUNT_MAX=2 generate
--i_hpkt_header_data<=i_hpkt_header(1) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#01#, i_hpkt_header_cnt'length) else
--                    i_hpkt_header(0);
--end generate gen_hd2;
--
--gen_hd3:  if CNIK_HPKT_COUNT_MAX=3 generate
--i_hpkt_header_data<=i_hpkt_header(2) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#02#, i_hpkt_header_cnt'length) else
--                    i_hpkt_header(1) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#01#, i_hpkt_header_cnt'length) else
--                    i_hpkt_header(0);
--end generate gen_hd3;
--
--gen_hd4:  if CNIK_HPKT_COUNT_MAX=4 generate
--i_hpkt_header_data<=i_hpkt_header(3) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#03#, i_hpkt_header_cnt'length) else
--                    i_hpkt_header(2) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#02#, i_hpkt_header_cnt'length) else
--                    i_hpkt_header(1) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#01#, i_hpkt_header_cnt'length) else
--                    i_hpkt_header(0);
--end generate gen_hd4;
--
--gen_hd8:  if CNIK_HPKT_COUNT_MAX=8 generate
i_hpkt_header_data<=i_hpkt_header(7) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#07#, i_hpkt_header_cnt'length) else
                    i_hpkt_header(6) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#06#, i_hpkt_header_cnt'length) else
                    i_hpkt_header(5) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#05#, i_hpkt_header_cnt'length) else
                    i_hpkt_header(4) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#04#, i_hpkt_header_cnt'length) else
                    i_hpkt_header(3) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#03#, i_hpkt_header_cnt'length) else
                    i_hpkt_header(2) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#02#, i_hpkt_header_cnt'length) else
                    i_hpkt_header(1) when i_hpkt_header_cnt=CONV_STD_LOGIC_VECTOR(16#01#, i_hpkt_header_cnt'length) else
                    i_hpkt_header(0);
--end generate gen_hd8;

i_mem_din<=i_hpkt_header_data when g_trcbufo_dout_en='0' else i_trcbufo_dout;
i_trc_txrdy_n<=i_trcbufo_empty and g_trcbufo_dout_en;

i_trcbufo_dout_en<=i_mem_din_en and g_trcbufo_dout_en;

m_trcbufo : trc_nik_bufout
port map(
din         => i_trcbufo_din,
wr_en       => i_trcbufo_din_en,
wr_clk      => p_in_clk,

dout        => i_trcbufo_dout,
rd_en       => i_trcbufo_dout_en,
rd_clk      => p_in_clk,

empty       => i_trcbufo_empty,--p_out_trc_bufo_empty,
full        => i_trcbufo_pfull,
prog_full   => open,--i_trcbufo_pfull,

--clk         => p_in_clk,
rst         => p_in_rst
);

p_out_trc_bufo_dout<=(others=>'0');
p_out_trc_bufo_empty<='0';

end generate gen_use_on;




gen_use_off : if strcmp(G_MODULE_USE,"OFF") generate

p_out_mem_clk <= p_in_clk;

p_out_mem_bank1h <=(others=>'0');
p_out_mem_ce     <='0';
p_out_mem_cw     <='0';
p_out_mem_rd     <='0';
p_out_mem_wr     <='0';
p_out_mem_term   <='0';
p_out_mem_adr    <=(others=>'0');
p_out_mem_be     <=(others=>'0');
p_out_mem_din    <=(others=>'0');

p_out_memarb_req <='0';


p_out_tst<=(others=>'0');

p_out_trc_hfrmrk<=(others=>'0');
p_out_trc_hdrdy<='0';
p_out_trc_hirq <='0';

p_out_trc_bufo_dout<=(others=>'0');
p_out_trc_bufo_empty<='0';

p_out_trc_busy<=(others=>'0');

end generate gen_use_off;


--END MAIN
end behavioral;

