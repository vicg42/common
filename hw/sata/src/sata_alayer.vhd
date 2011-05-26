-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 07.03.2011 11:14:57
-- Module Name : sata_alayer
--
-- Назначение :
--   Application Layer:
--
-- Revision:
-- Revision 0.01
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
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_alayer is
generic
(
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--Связь с USR APP Layer
--------------------------------------------------
p_in_ctrl                 : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);--//Константы см. sata_pkg.vhd/поле - Application Layer/Управление/Map:
p_out_status              : out   TALStatus;--//Константы см. sata_pkg.vhd/поле - Application Layer/Статусы/Map:

--//Связь с CMDFIFO
p_in_cmdfifo_dout         : in    std_logic_vector(15 downto 0);
p_in_cmdfifo_eof_n        : in    std_logic; --//Командный пакет готов.Можно читать
p_in_cmdfifo_src_rdy_n    : in    std_logic;
p_out_cmdfifo_dst_rdy_n   : out   std_logic;

--------------------------------------------------
--Связь с Transport/Link/PHY Layer
--------------------------------------------------
p_out_spd_ctrl            : out   TSpdCtrl;
p_out_tl_ctrl             : out   std_logic_vector(C_TLCTRL_LAST_BIT downto 0);
p_in_tl_status            : in    std_logic_vector(C_TLSTAT_LAST_BIT downto 0);
p_in_ll_status            : in    std_logic_vector(C_LLSTAT_LAST_BIT downto 0);
p_in_pl_status            : in    std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

p_out_reg_dma             : out   TRegDMA;         --//Настройки для DMA
p_out_reg_shadow          : out   TRegShadow;      --//Значения АТА регистров
p_in_reg_hold             : in    TRegHold;        --//Значения для обновления АТА регистров
p_in_reg_update           : in    TRegShadowUpdate;--//Стробы для обнавления АТА регистров

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                  : in    std_logic_vector(31 downto 0);
p_out_tst                 : out   std_logic_vector(31 downto 0);
p_out_dbg                 : out   TAL_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end sata_alayer;

architecture behavioral of sata_alayer is

constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));

signal i_cmdfifo_dcnt              : std_logic_vector(3 downto 0);
signal i_cmdfifo_rd_done           : std_logic;

signal i_usrctrl                   : std_logic_vector(15 downto 0);
signal i_usrmode_sel               : std_logic_vector(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT);
signal i_usrmode                   : std_logic_vector(C_SATACMD_COUNT-1 downto 0);
signal i_err_clr                   : std_logic;
signal i_sstatus                   : std_logic_vector(C_ALSSTAT_LAST_BIT downto 0);
signal i_spd_ver                   : std_logic_vector(C_PSTAT_SPD_BIT_M-C_PSTAT_SPD_BIT_L downto 0);

signal i_reg_shadow_addr           : std_logic_vector(i_cmdfifo_dcnt'range);
signal i_reg_shadow_din            : std_logic_vector(15 downto 0);
signal i_reg_shadow_wr             : std_logic;
signal i_reg_shadow_wr_done        : std_logic;

signal i_reg_shadow                : TRegShadow;

signal i_trn_atacommand            : std_logic;
signal i_trn_atacontrol            : std_logic;

signal i_scount                    : std_logic_vector(15 downto 0);
signal i_scount_byte               : std_logic_vector(i_scount'length + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);

signal i_link_establish_dly        : std_logic_vector(1 downto 0);
signal i_link_establish_change     : std_logic;

signal i_serr_i_err                : std_logic;
signal i_serr_p_err                : std_logic;
signal i_serr_c_err                : std_logic;

signal i_usr_status                : std_logic_vector(C_ALUSER_LAST_BIT downto 0);

--signal i_dwr_width_cnt             : std_logic_vector(15 downto 0);

signal i_dbgtsf_type               : string(1 to 23);



--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
p_out_tst(31 downto 0)<=(others=>'0');
--tstout:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(31 downto 0)<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--    p_out_tst(0)<=tst_val;
--  end if;
--end process tstout;
--p_out_tst(31 downto 1)<=(others=>'0');

end generate gen_dbg_on;


--//-----------------------------
--//Инициализация
--//-----------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_err_clr<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    i_err_clr<=p_in_ctrl(C_USR_GCTRL_CLR_ERR_BIT);
  end if;
end process;

--//Декодирование режима работы:
i_usrmode_sel<=i_usrctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT);

gen_usrmode : for i in 0 to C_SATACMD_COUNT-1 generate
i_usrmode(i)<='1' when i_usrmode_sel=CONV_STD_LOGIC_VECTOR(i, i_usrmode'length) else '0';
end generate gen_usrmode;



--------------------------------------------------
--Связь с USR APP Layer
--------------------------------------------------
--//Чтение командного пакета
p_out_cmdfifo_dst_rdy_n<=i_usr_status(C_AUSER_BUSY_BIT);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_cmdfifo_dcnt<=(others=>'0');
    i_cmdfifo_rd_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    i_cmdfifo_rd_done<=not p_in_cmdfifo_src_rdy_n and not p_in_cmdfifo_eof_n;

    if p_in_cmdfifo_src_rdy_n='0' then
      if p_in_cmdfifo_eof_n='0' then
        i_cmdfifo_dcnt<=(others=>'0');
      else
        i_cmdfifo_dcnt<=i_cmdfifo_dcnt+1;
      end if;
    end if;

  end if;
end process;

i_reg_shadow_din <=p_in_cmdfifo_dout;
i_reg_shadow_addr<=i_cmdfifo_dcnt;
i_reg_shadow_wr <=not p_in_cmdfifo_src_rdy_n;
i_reg_shadow_wr_done <=i_cmdfifo_rd_done;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    i_usrctrl<=(others=>'0');

    i_reg_shadow.command<=(others=>'0');
    i_reg_shadow.status(C_ATA_STATUS_BUSY_BIT-1 downto 0)<=(others=>'0');
    i_reg_shadow.status(C_ATA_STATUS_BUSY_BIT)<='1';
    i_reg_shadow.error<=(others=>'0');
    i_reg_shadow.device<=(others=>'0');
    i_reg_shadow.control<=(others=>'0');
    i_reg_shadow.lba_low<=(others=>'0');
    i_reg_shadow.lba_low_exp<=(others=>'0');
    i_reg_shadow.lba_mid<=(others=>'0');
    i_reg_shadow.lba_mid_exp<=(others=>'0');
    i_reg_shadow.lba_high<=(others=>'0');
    i_reg_shadow.lba_high_exp<=(others=>'0');
    i_reg_shadow.scount<=(others=>'0');
    i_reg_shadow.scount_exp<=(others=>'0');
    i_reg_shadow.feature<=(others=>'0');
    i_reg_shadow.feature_exp<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if i_err_clr='1' then
      i_reg_shadow.status(C_ATA_STATUS_ERR_BIT)<='0';

    elsif i_trn_atacommand='1' then
      i_reg_shadow.status(C_ATA_STATUS_BUSY_BIT)<='1';

    elsif p_in_reg_update.fsdb='1' then
    --//Обновление регистров по приему FIS_SetDevice_Bits
      i_reg_shadow.status(2 downto 0)<=p_in_reg_hold.sb_status(2 downto 0);
      i_reg_shadow.status(5 downto 4)<=p_in_reg_hold.sb_status(5 downto 4);
      i_reg_shadow.error <= p_in_reg_hold.sb_error;

    elsif p_in_reg_update.fpio_e='1' then
    --//Режим PIO: Обновление регистров в результате корректного завершения АТА комманды
    --//Значение p_in_reg_hold.e_status - устанавливается из соответствующего поля FIS_PIOSETUP
      i_reg_shadow.status<=p_in_reg_hold.e_status;

    elsif p_in_reg_update.fpio='1'then
    --//Режим PIO: Обновление регистров по приему FIS_PIOSETUP
        i_reg_shadow.status <= p_in_reg_hold.status;
        i_reg_shadow.error <= p_in_reg_hold.error;
        i_reg_shadow.device <= p_in_reg_hold.device;
        i_reg_shadow.lba_low <= p_in_reg_hold.lba_low;
        i_reg_shadow.lba_low_exp <= p_in_reg_hold.lba_low_exp;
        i_reg_shadow.lba_mid <= p_in_reg_hold.lba_mid;
        i_reg_shadow.lba_mid_exp <= p_in_reg_hold.lba_mid_exp;
        i_reg_shadow.lba_high <= p_in_reg_hold.lba_high;
        i_reg_shadow.lba_high_exp <= p_in_reg_hold.lba_high_exp;
        i_reg_shadow.scount <= p_in_reg_hold.scount;
        i_reg_shadow.scount_exp <= p_in_reg_hold.scount_exp;

    elsif p_in_reg_update.fd2h='1'then
    --//Обновление регистров по приему FIS_DEV2HOST
    --//ВАЖНО: Если оба бита BSY и DRQ ='0', то обновление не делаем - в соответвии с Serial ATA Specification v2.5 (2005-10-27).pdf/ пп 10.3.5.3
      if i_reg_shadow.status(C_ATA_STATUS_BUSY_BIT)='1' or i_reg_shadow.status(C_ATA_STATUS_DRQ_BIT)='1' then
        i_reg_shadow.status <= p_in_reg_hold.status;
        i_reg_shadow.error <= p_in_reg_hold.error;
        i_reg_shadow.device <= p_in_reg_hold.device;
        i_reg_shadow.lba_low <= p_in_reg_hold.lba_low;
        i_reg_shadow.lba_low_exp <= p_in_reg_hold.lba_low_exp;
        i_reg_shadow.lba_mid <= p_in_reg_hold.lba_mid;
        i_reg_shadow.lba_mid_exp <= p_in_reg_hold.lba_mid_exp;
        i_reg_shadow.lba_high <= p_in_reg_hold.lba_high;
        i_reg_shadow.lba_high_exp <= p_in_reg_hold.lba_high_exp;
        i_reg_shadow.scount <= p_in_reg_hold.scount;
        i_reg_shadow.scount_exp <= p_in_reg_hold.scount_exp;
      end if;

    elsif i_reg_shadow_wr='1' then
    --//Записть данных в регистры Хостом
      if    i_reg_shadow_addr=CONV_STD_LOGIC_VECTOR(C_ALREG_USRCTRL, i_reg_shadow_addr'length) then
          i_usrctrl<=i_reg_shadow_din(15 downto 0);

      elsif i_reg_shadow_addr=CONV_STD_LOGIC_VECTOR(C_ALREG_SECTOR_COUNT, i_reg_shadow_addr'length) then
          i_reg_shadow.scount <= i_reg_shadow_din(7 downto 0);
          i_reg_shadow.scount_exp <= i_reg_shadow_din(15 downto 8);

      elsif i_reg_shadow_addr=CONV_STD_LOGIC_VECTOR(C_ALREG_FEATURE, i_reg_shadow_addr'length) then
          i_reg_shadow.feature <= i_reg_shadow_din(7 downto 0);
          i_reg_shadow.feature_exp <= i_reg_shadow_din(15 downto 8);

      elsif i_reg_shadow_addr=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_LOW, i_reg_shadow_addr'length) then
          i_reg_shadow.lba_low <= i_reg_shadow_din(7 downto 0);
          i_reg_shadow.lba_low_exp <= i_reg_shadow_din(15 downto 8);

      elsif i_reg_shadow_addr=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_MID, i_reg_shadow_addr'length) then
          i_reg_shadow.lba_mid <= i_reg_shadow_din(7 downto 0);
          i_reg_shadow.lba_mid_exp <= i_reg_shadow_din(15 downto 8);

      elsif i_reg_shadow_addr=CONV_STD_LOGIC_VECTOR(C_ALREG_LBA_HIGH, i_reg_shadow_addr'length) then
          i_reg_shadow.lba_high <= i_reg_shadow_din(7 downto 0);
          i_reg_shadow.lba_high_exp <= i_reg_shadow_din(15 downto 8);

      elsif i_reg_shadow_addr=CONV_STD_LOGIC_VECTOR(C_ALREG_DEVICE, i_reg_shadow_addr'length) then
          i_reg_shadow.device <= i_reg_shadow_din(7 downto 0);
          i_reg_shadow.control <= i_reg_shadow_din(15 downto 8);

      elsif i_reg_shadow_addr=CONV_STD_LOGIC_VECTOR(C_ALREG_COMMAND, i_reg_shadow_addr'length) then
          i_reg_shadow.command <= i_reg_shadow_din(7 downto 0);
          i_reg_shadow.device(C_ATA_DEVICE_LBA_BIT)<='1';--Уст.режим адресации LBA

      end if;

    end if;

  end if;
end process;


--//Собираем отчет:
--//ATA:
p_out_status.ATAStatus<=i_reg_shadow.status;
p_out_status.ATAError<=i_reg_shadow.error;


--//SATA Status:
--//Детектирование:
i_sstatus(C_ASSTAT_DET_BIT_L+0)<=p_in_pl_status(C_PSTAT_DET_DEV_ON_BIT);      --//0/1 - Устройство не обнаружено/обнаружено но соединение не установлено!!
i_sstatus(C_ASSTAT_DET_BIT_L+1)<=p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT);--//0/1 - Соединение с устройством не установлено/установлено (можно работать)
i_sstatus(C_ASSTAT_DET_BIT_M downto C_ASSTAT_DET_BIT_L+2)<=(others=>'0');

--//Cкорость соединения: "00"/"01"/"10" - не согласована/Gen1/Gen2
i_spd_ver<=p_in_pl_status(C_PSTAT_SPD_BIT_M downto C_PSTAT_SPD_BIT_L);
i_sstatus(C_ASSTAT_SPD_BIT_M downto C_ASSTAT_SPD_BIT_L)<="0001" when i_spd_ver=CONV_STD_LOGIC_VECTOR(C_FSATA_GEN1, i_spd_ver'length) else
                                                         "0010" when i_spd_ver=CONV_STD_LOGIC_VECTOR(C_FSATA_GEN2, i_spd_ver'length) else
                                                         "0000";

i_sstatus(C_ASSTAT_IPM_BIT_L)<=i_reg_shadow.status(C_ATA_STATUS_DRDY_BIT);--//Интрефейс в активном состоянии. Сигнатура от устройства получена

i_sstatus(C_ALSSTAT_LAST_BIT downto C_ASSTAT_IPM_BIT_L+1)<=(others=>'0');


--//SATA Error:
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_status.SError<=(others=>'0');

    i_link_establish_dly<=(others=>'0');
    i_link_establish_change<='0';

    i_serr_i_err<='0';
    i_serr_p_err<='0';
    i_serr_c_err<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    i_link_establish_dly(0)<=p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT);
    i_link_establish_dly(1)<=i_link_establish_dly(0);
    i_link_establish_change<=i_link_establish_dly(1) and not i_link_establish_dly(0);

    p_out_status.SError(C_ASERR_DET_M_BIT downto C_ASERR_DET_L_BIT)<=i_sstatus(C_ASSTAT_DET_BIT_L+1 downto C_ASSTAT_DET_BIT_L);
    p_out_status.SError(C_ASERR_SPD_M_BIT downto C_ASERR_SPD_L_BIT)<=i_sstatus(C_ASSTAT_SPD_BIT_L+2 downto C_ASSTAT_SPD_BIT_L);
    p_out_status.SError(C_ASERR_IPM_L_BIT)<=i_sstatus(C_ASSTAT_IPM_BIT_L);

    if i_err_clr='1' then

      p_out_status.SError(C_ASERR_P_ERR_BIT)<='0';
      p_out_status.SError(C_ASERR_C_ERR_BIT)<='0';
      p_out_status.SError(C_ASERR_I_ERR_BIT)<='0';

      p_out_status.SError(C_ASERR_F_DIAG_BIT)<='0';
      p_out_status.SError(C_ASERR_T_DIAG_BIT)<='0';
      p_out_status.SError(C_ASERR_S_DIAG_BIT)<='0';
      p_out_status.SError(C_ASERR_C_DIAG_BIT)<='0';
      p_out_status.SError(C_ASERR_H_DIAG_BIT)<='0';--//CRC ERROR on send FIS
      p_out_status.SError(C_ASERR_N_DIAG_BIT)<='0';
      p_out_status.SError(C_ASERR_W_DIAG_BIT)<='0';
      p_out_status.SError(C_ASERR_D_DIAG_BIT)<='0';
      p_out_status.SError(C_ASERR_B_DIAG_BIT)<='0';

    else

      --//###################################
      --//Обнаружены ошибоки
      --//###################################
      --//Ошибки протокола обмена
      if p_in_ll_status(C_LSTAT_RxERR_IDLE)='1' or p_in_ll_status(C_LSTAT_TxERR_IDLE)='1' or
         p_in_ll_status(C_LSTAT_RxERR_ABORT)='1' or p_in_ll_status(C_LSTAT_TxERR_ABORT)='1' or
         p_in_tl_status(C_TSTAT_RxFISTYPE_ERR_BIT)='1' or p_in_tl_status(C_TSTAT_RxFISLEN_ERR_BIT)='1' then

      p_out_status.SError(C_ASERR_P_ERR_BIT)<='1';
      i_serr_p_err<='1';
      end if;

      --//Ошибка связи или целостности данных(CRC error)
      if (i_link_establish_change='1' and i_usrmode(C_SATACMD_SET_SATA1)='0' and i_usrmode(C_SATACMD_SET_SATA2)='0') or
         p_in_ll_status(C_LSTAT_RxERR_CRC)='1' or
         (p_in_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)='1' and p_in_tl_status(C_TSTAT_TxERR_CRC_REPEAT_BIT)='1') or
         (p_in_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)='0' and p_in_ll_status(C_LSTAT_TxERR_CRC)='1') then
      --//CRC error в случаях:
      --//Прием данных - сигнализация о CRC error от Link Layer
      --//Передача данных - Если оправлю FIS_HOST2DEV, то назначаем C_ASERR_C_ERR_BIT='1'
      --//                  после 3-ех неудачных попыток отправления, при каждой попытке Link Layer сигнализировал о CRC error
      --//                  Если отрпаляю какой либо другой FIS, то назначаем C_ASERR_C_ERR_BIT='1' сразу при сигнализации Link Layer о CRC error

      --//Ошибки связи: обноружил измение состояния сигнала i_link_establish(Соединение установлено -'1' -> Соединение разорвано - '0' )

      p_out_status.SError(C_ASERR_C_ERR_BIT)<='1';
      i_serr_c_err<='1';
      end if;

      --//Ошибки декодирования
      --//ВАЖНО: сигнализируем только после установления соединения с устройством!!!
      if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and (p_in_pl_status(C_PRxSTAT_ERR_DISP_BIT)='1' or p_in_pl_status(C_PRxSTAT_ERR_NOTINTABLE_BIT)='1') then
      p_out_status.SError(C_ASERR_I_ERR_BIT)<='1';
      i_serr_i_err<='1';
      end if;


      --//###################################
      --//Причины ошибок
      --//###################################
      --//Transport Layer:
      --//CRC-OK, but FISTYPE/FISLEN ERROR
      if p_in_tl_status(C_TSTAT_RxFISTYPE_ERR_BIT)='1' or p_in_tl_status(C_TSTAT_RxFISLEN_ERR_BIT)='1' then
      p_out_status.SError(C_ASERR_F_DIAG_BIT)<='1';
      end if;

      --//Ошибка при переходе из одного состояния в другое автомата управления Transport Layer
      if p_in_ll_status(C_LSTAT_RxERR_ABORT)='1' or p_in_ll_status(C_LSTAT_TxERR_ABORT)='1' then
      p_out_status.SError(C_ASERR_T_DIAG_BIT)<='1';
      end if;

      --//Link Layer:
      --//(был принят примитив которого не ожидаю в текущем состоянии автомата управления)
      if p_in_ll_status(C_LSTAT_RxERR_IDLE)='1' or p_in_ll_status(C_LSTAT_TxERR_IDLE)='1' then
      p_out_status.SError(C_ASERR_S_DIAG_BIT)<='1';
      end if;
      --//CRC ERROR
      if p_in_ll_status(C_LSTAT_RxERR_CRC)='1' or p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then
      p_out_status.SError(C_ASERR_C_DIAG_BIT)<='1';
      end if;
      if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then
      p_out_status.SError(C_ASERR_H_DIAG_BIT)<='1';--//CRC ERROR on send FIS
      end if;

      --//PHY Layer:
      --//Связь с утройством оборвана
      if (i_link_establish_change='1' and i_usrmode(C_SATACMD_SET_SATA1)='0' and i_usrmode(C_SATACMD_SET_SATA2)='0') then
      p_out_status.SError(C_ASERR_N_DIAG_BIT)<='1';
      end if;

      --//(От устройства был принят сигнал COMWAKE)
      if p_in_pl_status(C_PSTAT_COMWAKE_RCV_BIT)='1' then
      p_out_status.SError(C_ASERR_W_DIAG_BIT)<='1';
      end if;

      --//Disparity Error
      if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and p_in_pl_status(C_PRxSTAT_ERR_DISP_BIT)='1' then
      p_out_status.SError(C_ASERR_D_DIAG_BIT)<='1';
      end if;

      --//10b to 8b Decode error
      if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and p_in_pl_status(C_PRxSTAT_ERR_NOTINTABLE_BIT)='1' then
      p_out_status.SError(C_ASERR_B_DIAG_BIT)<='1';
      end if;

    end if;
  end if;
end process;

--//User:
p_out_status.Usr<=i_usr_status;
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_usr_status(C_AUSER_BUSY_BIT)<='1';
    i_usr_status(C_ALUSER_LAST_BIT downto C_AUSER_BUSY_BIT+1)<=(others=>'0');

--    i_dwr_width_cnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    i_usr_status(C_AUSER_BUSY_BIT)<=i_reg_shadow.status(C_ATA_STATUS_BUSY_BIT) or i_reg_shadow.status(C_ATA_STATUS_DRQ_BIT);

    --//Растягиваем импульс C_AUSER_DWR_START_BIT
    if p_in_tl_status(C_TSTAT_DWR_START_BIT)='1' then
      i_usr_status(C_AUSER_DWR_START_BIT)<='1';
--    elsif i_dwr_width_cnt(8)='1' then
    elsif p_in_reg_update.fpio_e='1' or p_in_reg_update.fd2h='1' or
         (i_serr_i_err='1' or i_serr_p_err='1' or i_serr_c_err='1' or i_reg_shadow.status(C_ATA_STATUS_ERR_BIT)='1') then
    --//Сброс по завершению команды в режиме PIO или по приему FIS_DEV2HOST или при обнаружении ошибки
      i_usr_status(C_AUSER_DWR_START_BIT)<='0';
    end if;

--    if i_usr_status(C_AUSER_DWR_START_BIT)<='0' then
--      i_dwr_width_cnt<=(others=>'0');
--    else
--      i_dwr_width_cnt<=i_dwr_width_cnt+1;
--    end if;

  end if;
end process;



--------------------------------------------------
--Связь с Speed Controller
--------------------------------------------------
p_out_spd_ctrl.change<=(i_usrmode(C_SATACMD_SET_SATA1) or i_usrmode(C_SATACMD_SET_SATA2)) and i_reg_shadow_wr_done;
p_out_spd_ctrl.sata_ver<=CONV_STD_LOGIC_VECTOR(C_FSATA_GEN2, p_out_spd_ctrl.sata_ver'length) when i_usrmode(C_SATACMD_SET_SATA2 downto C_SATACMD_SET_SATA1)="10" else
                         CONV_STD_LOGIC_VECTOR(C_FSATA_GEN1, p_out_spd_ctrl.sata_ver'length) when i_usrmode(C_SATACMD_SET_SATA2 downto C_SATACMD_SET_SATA1)="01" else
                         CONV_STD_LOGIC_VECTOR(C_FSATA_GEN_DEFAULT, p_out_spd_ctrl.sata_ver'length);--//default SATA GEN


--------------------------------------------------
--Связь с Transport Layer
--------------------------------------------------
--//Управление Transport уровнем
i_trn_atacommand<=i_usrmode(C_SATACMD_ATACOMMAND) and i_reg_shadow_wr_done;
i_trn_atacontrol<=i_usrmode(C_SATACMD_ATACONTROL) and i_reg_shadow_wr_done;

p_out_tl_ctrl(C_TCTRL_RCOMMAND_WR_BIT)<=i_trn_atacommand;
p_out_tl_ctrl(C_TCTRL_RCONTROL_WR_BIT)<=i_trn_atacontrol;
p_out_tl_ctrl(C_TCTRL_DMASETUP_WR_BIT)<=i_usrmode(C_SATACMD_FPDMA_W) or i_usrmode(C_SATACMD_FPDMA_R);

p_out_reg_shadow<=i_reg_shadow;

p_out_reg_dma.fpdma.dir<=C_DIR_H2D when i_usrmode(C_SATACMD_FPDMA_W)='1' else C_DIR_D2H;
p_out_reg_dma.fpdma.addr_l<=(others=>'0');
p_out_reg_dma.fpdma.addr_m<=(others=>'0');
p_out_reg_dma.fpdma.offset<=(others=>'0');
p_out_reg_dma.trncount_byte<=EXT(i_scount_byte, p_out_reg_dma.trncount_byte'length);


i_scount<=i_reg_shadow.scount_exp&i_reg_shadow.scount;
i_scount_byte<=i_scount&CONV_STD_LOGIC_VECTOR(0, log2(CI_SECTOR_SIZE_BYTE));



--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
gen_sim_off : if strcmp(G_SIM,"OFF") generate
begin
p_out_dbg.cmd_name<=(others=>'0');
end generate gen_sim_off;

gen_sim_on : if strcmp(G_SIM,"ON") generate

rq_name: process(i_reg_shadow,i_trn_atacommand)
begin
  if i_trn_atacommand='1' then
    if i_reg_shadow.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_IDENTIFY_DEV, i_reg_shadow.command'length) then
      i_dbgtsf_type<="ATA_IDENTIFY           ";
    elsif i_reg_shadow.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_IDENTIFY_PACKET_DEV, i_reg_shadow.command'length) then
      i_dbgtsf_type<="ATA_IDENTIFY_PACKET_DEV";
    elsif i_reg_shadow.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_NOP, i_reg_shadow.command'length) then
      i_dbgtsf_type<="ATA_NOP                ";
    elsif i_reg_shadow.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_SECTORS_EXT, i_reg_shadow.command'length) then
      i_dbgtsf_type<="ATA_PIO_WRITE          ";
    elsif i_reg_shadow.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_SECTORS_EXT, i_reg_shadow.command'length) then
      i_dbgtsf_type<="ATA_PIO_READ           ";
    elsif i_reg_shadow.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, i_reg_shadow.command'length) then
      i_dbgtsf_type<="ATA_DMA_WRITE          ";
    elsif i_reg_shadow.command=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_DMA_EXT, i_reg_shadow.command'length) then
      i_dbgtsf_type<="ATA_DMA_READ           ";
    else
      i_dbgtsf_type<="NONE                   ";
    end if;
  end if;
end process rq_name;

p_out_dbg.cmd_name<=i_dbgtsf_type;

end generate gen_sim_on;

p_out_dbg.cmd_busy<=i_usr_status(C_AUSER_BUSY_BIT);
p_out_dbg.signature<=i_reg_shadow.status(C_ATA_STATUS_DRDY_BIT);


--END MAIN
end behavioral;
