-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.06
-- Module Name : mem_wr
--
-- Назначение/Описание :
--  Запись/Чтение данных ОЗУ
--
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Исправлена ошибка в режиме записи (add 2010.09.12)
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.mem_wr_pkg.all;

entity mem_wr is
generic(
G_MEM_BANK_M_BIT : integer:=29;--//биты(мл. ст.) определяющие банк ОЗУ. Относится в порту p_in_cfg_mem_adr
G_MEM_BANK_L_BIT : integer:=28;
G_AXI_IDWR_NUM   : integer:=1;
G_AXI_IDRD_NUM   : integer:=2;
G_AXI_IDWIDTH    : integer:=4;
G_AXI_AWIDTH     : integer:=32;
G_AXI_DWIDTH     : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_adr     : in    std_logic_vector(31 downto 0);--//Адрес ОЗУ (в BYTE)
p_in_cfg_mem_trn_len : in    std_logic_vector(15 downto 0);--//Размер одиночной MEM_TRN (в DWORD)
p_in_cfg_mem_dlen_rq : in    std_logic_vector(15 downto 0);--//Размер запрашиваемых данных записи/чтения (в DWORD)
p_in_cfg_mem_wr      : in    std_logic;                    --//Тип операции (1/0 - запись/чтение)
p_in_cfg_mem_start   : in    std_logic;                    --//Строб: Пуск операции
p_out_cfg_mem_done   : out   std_logic;                    --//Строб: Операции завершена

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
--//usr_buf->mem
p_in_usr_txbuf_dout  : in    std_logic_vector(31 downto 0);
p_out_usr_txbuf_rd   : out   std_logic;
p_in_usr_txbuf_empty : in    std_logic;

--//usr_buf<-mem
p_out_usr_rxbuf_din  : out   std_logic_vector(31 downto 0);
p_out_usr_rxbuf_wd   : out   std_logic;
p_in_usr_rxbuf_full  : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
--//AXI Master Interface:
--//WRAddr Ports(usr_buf->mem)
p_out_maxi_awid      : out   std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_out_maxi_awaddr    : out   std_logic_vector(G_AXI_AWIDTH-1 downto 0);
p_out_maxi_awlen     : out   std_logic_vector(7 downto 0);--(15 downto 0);
p_out_maxi_awsize    : out   std_logic_vector(2 downto 0);
p_out_maxi_awburst   : out   std_logic_vector(1 downto 0);
p_out_maxi_awlock    : out   std_logic_vector(0 downto 0);--(1 downto 0);
p_out_maxi_awcache   : out   std_logic_vector(3 downto 0);
p_out_maxi_awprot    : out   std_logic_vector(2 downto 0);
p_out_maxi_awqos     : out   std_logic_vector(3 downto 0);
p_out_maxi_awvalid   : out   std_logic;
p_in_maxi_awready    : in    std_logic;
--//WRData Ports
p_out_maxi_wdata     : out   std_logic_vector(G_AXI_DWIDTH-1 downto 0);
p_out_maxi_wstrb     : out   std_logic_vector(G_AXI_DWIDTH/8-1 downto 0);
p_out_maxi_wlast     : out   std_logic;
p_out_maxi_wvalid    : out   std_logic;
p_in_maxi_wready     : in    std_logic;
--//WRResponse Ports
p_in_maxi_bid        : in    std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_in_maxi_bresp      : in    std_logic_vector(1 downto 0);
p_in_maxi_bvalid     : in    std_logic;
p_out_maxi_bready    : out   std_logic;

--//RDAddr Ports(usr_buf<-mem)
p_out_maxi_arid      : out   std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_out_maxi_araddr    : out   std_logic_vector(G_AXI_AWIDTH-1 downto 0);
p_out_maxi_arlen     : out   std_logic_vector(7 downto 0);--(15 downto 0);
p_out_maxi_arsize    : out   std_logic_vector(2 downto 0);
p_out_maxi_arburst   : out   std_logic_vector(1 downto 0);
p_out_maxi_arlock    : out   std_logic_vector(0 downto 0);--(1 downto 0);
p_out_maxi_arcache   : out   std_logic_vector(3 downto 0);
p_out_maxi_arprot    : out   std_logic_vector(2 downto 0);
p_out_maxi_arqos     : out   std_logic_vector(3 downto 0);
p_out_maxi_arvalid   : out   std_logic;
p_in_maxi_arready    : in    std_logic;
--//RDData Ports
p_in_maxi_rid        : in    std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_in_maxi_rdata      : in    std_logic_vector(G_AXI_DWIDTH-1 downto 0);
p_in_maxi_rresp      : in    std_logic_vector(1 downto 0);
p_in_maxi_rlast      : in    std_logic;
p_in_maxi_rvalid     : in    std_logic;
p_out_maxi_rready    : out   std_logic;

-------------------------------
--Технологические сигналы
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end mem_wr;

architecture behavioral of mem_wr is

type fsm_state is (
S_IDLE,
S_MEM_REMAIN_SIZE_CALC,
S_MEM_TRN_LEN_CALC,
S_MEM_SET_RQ,
S_MEM_WAIT_RQ_EN,
S_MEM_TRN_START,
S_MEM_TRN,
S_MEM_TRN_END,
S_EXIT
);
signal fsm_state_cs                : fsm_state;

signal i_cfg_mem_dlen_rq           : std_logic_vector(p_in_cfg_mem_dlen_rq'range);
signal i_cfg_mem_trn_len           : std_logic_vector(p_in_cfg_mem_trn_len'range);

signal i_mem_adr_out               : std_logic_vector(G_MEM_BANK_L_BIT-1 downto 0);
signal i_mem_wr_out                : std_logic;
signal i_mem_rd_out                : std_logic;
signal i_mem_term_out              : std_logic:='0';

signal i_mem_ce                    : std_logic;
--signal i_memarb_req                : std_logic;

signal i_mem_dir                   : std_logic;
signal i_mem_dlen_remain           : std_logic_vector(i_cfg_mem_dlen_rq'range);
signal i_mem_dlen_used             : std_logic_vector(i_cfg_mem_dlen_rq'range);
signal i_mem_trn_work              : std_logic;
signal i_mem_trn_len               : std_logic_vector(i_cfg_mem_trn_len'range);

signal i_mem_done                  : std_logic;

signal i_axi_awvalid               : std_logic;
signal i_axi_arvalid               : std_logic;
signal i_axi_awlen                 : std_logic_vector(i_cfg_mem_trn_len'range);
signal i_axi_bready                : std_logic;

signal tst_fsm_cs                  : std_logic_vector(3 downto 0);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(0)<='0';--i_mem_term_out;
p_out_tst(1)<='0';--sr_mem_term_out;
p_out_tst(5 downto 2)<=tst_fsm_cs;
p_out_tst(15 downto 6)<=(others=>'0');
p_out_tst(31 downto 16)<=i_mem_trn_len;

tst_fsm_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_REMAIN_SIZE_CALC     else
            CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_LEN_CALC         else
            CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_SET_RQ               else
            CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_WAIT_RQ_EN           else
            CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_START            else
            CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN                  else
            CONV_STD_LOGIC_VECTOR(16#07#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_END              else
            CONV_STD_LOGIC_VECTOR(16#08#,tst_fsm_cs'length) when fsm_state_cs=S_EXIT                     else
            CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_cs'length);--when fsm_state_cs=S_IDLE                     else


-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
p_out_usr_txbuf_rd <= i_mem_wr_out;

p_out_usr_rxbuf_wd  <= i_mem_rd_out;
p_out_usr_rxbuf_din <= p_in_maxi_rdata;


--//----------------------------------------------
--//Связь с контроллером памяти
--//----------------------------------------------
--//WRAddr Ports:
p_out_maxi_awid   <=CONV_STD_LOGIC_VECTOR(G_AXI_IDWR_NUM, p_out_maxi_awid'length);
p_out_maxi_awaddr <=EXT(i_mem_adr_out, p_out_maxi_awaddr'length);
p_out_maxi_awlen  <=i_axi_awlen(p_out_maxi_awlen'range);
p_out_maxi_awsize <=CONV_STD_LOGIC_VECTOR(2, p_out_maxi_awsize'length); --//2/3 - BusData=32bit/64bit;
p_out_maxi_awburst<=CONV_STD_LOGIC_VECTOR(1, p_out_maxi_awburst'length);--//0/1 - Fixed( FIFO-type)/INCR (Normal sequential memory)
p_out_maxi_awlock <=CONV_STD_LOGIC_VECTOR(0, p_out_maxi_awlock'length);
p_out_maxi_awcache<=CONV_STD_LOGIC_VECTOR(0, p_out_maxi_awcache'length);
p_out_maxi_awprot <=CONV_STD_LOGIC_VECTOR(0, p_out_maxi_awprot'length);
p_out_maxi_awqos  <=CONV_STD_LOGIC_VECTOR(0, p_out_maxi_awqos'length);
--//WRData Ports:
p_out_maxi_awvalid<=i_axi_awvalid;
p_out_maxi_wvalid <=i_mem_wr_out;
p_out_maxi_wdata  <=p_in_usr_txbuf_dout;
gen_wbe : for i in 0 to p_out_maxi_wstrb'length-1 generate
p_out_maxi_wstrb(i)<=i_mem_wr_out;
end generate gen_wbe;
p_out_maxi_wlast  <=i_mem_term_out and i_mem_wr_out;
p_out_maxi_bready <=i_axi_bready;


--//RDAddr Ports:
p_out_maxi_arid   <=CONV_STD_LOGIC_VECTOR(G_AXI_IDRD_NUM, p_out_maxi_arid'length);
p_out_maxi_araddr <=EXT(i_mem_adr_out, p_out_maxi_araddr'length);
p_out_maxi_arlen  <=i_axi_awlen(p_out_maxi_arlen'range);
p_out_maxi_arsize <=CONV_STD_LOGIC_VECTOR(2, p_out_maxi_arsize'length); --//2/3 - BusData=32bit/64bit;
p_out_maxi_arburst<=CONV_STD_LOGIC_VECTOR(1, p_out_maxi_arburst'length);--//0/1 - Fixed( FIFO-type)/INCR (Normal sequential memory)
p_out_maxi_arlock <=CONV_STD_LOGIC_VECTOR(0, p_out_maxi_arlock'length);
p_out_maxi_arcache<=CONV_STD_LOGIC_VECTOR(0, p_out_maxi_arcache'length);
p_out_maxi_arprot <=CONV_STD_LOGIC_VECTOR(0, p_out_maxi_arprot'length);
p_out_maxi_arqos  <=CONV_STD_LOGIC_VECTOR(0, p_out_maxi_arqos'length);
--//RDData Ports:
p_out_maxi_arvalid<=i_axi_arvalid;
p_out_maxi_rready <=i_mem_trn_work and not p_in_usr_rxbuf_full when i_mem_dir=C_MEMWR_READ  else '0';


process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then

    --//Формируем сигнал последнего данного в текущей транзакции записи ОЗУ
    if i_mem_dir=C_MEMWR_WRITE then
      if (i_mem_wr_out='1' or fsm_state_cs=S_MEM_WAIT_RQ_EN) and i_mem_trn_len=CONV_STD_LOGIC_VECTOR(1, i_mem_trn_len'length) then
        i_mem_term_out<='1';
      elsif i_mem_wr_out='1' and i_mem_trn_len=(i_mem_trn_len'range => '0') then
        i_mem_term_out<='0';
      end if;
    end if;

  end if;
end process;



--//----------------------------------------------
--//Автомат записи/чтения данных ОЗУ
--//----------------------------------------------
--//Завершение текущей операции
p_out_cfg_mem_done<=i_mem_done;

--//Разрешение записи/чтения ОЗУ
i_mem_rd_out<=i_mem_trn_work and p_in_maxi_rvalid and not p_in_usr_rxbuf_full  when i_mem_dir=C_MEMWR_READ  else '0';
i_mem_wr_out<=i_mem_trn_work and p_in_maxi_wready and not p_in_usr_txbuf_empty when i_mem_dir=C_MEMWR_WRITE else '0';

--//Логика работы автомата
process(p_in_rst,p_in_clk)
  variable var_update_addr: std_logic_vector(i_mem_trn_len'length+1 downto 0);
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;

    i_cfg_mem_dlen_rq<=(others=>'0');
    i_cfg_mem_trn_len<=(others=>'0');

    i_mem_adr_out<=(others=>'0');
    i_mem_dir<='0';

    i_axi_awvalid<='0';
    i_axi_arvalid<='0';
    i_axi_awlen<=(others=>'0');
    i_axi_bready<='0';

    i_mem_dlen_remain<=(others=>'0');
    i_mem_dlen_used<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_trn_work<='0';
    i_mem_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then
  --  if clk_en='1' then

    case fsm_state_cs is

      when S_IDLE =>

      i_mem_done<='0';

      --//------------------------------------
      --//Ждем сигнала запуска операции
      --//------------------------------------
        if p_in_cfg_mem_start='1' then
          i_mem_adr_out<=p_in_cfg_mem_adr(G_MEM_BANK_L_BIT-1 downto 0);
          i_mem_dir <=p_in_cfg_mem_wr;
          i_cfg_mem_dlen_rq<=p_in_cfg_mem_dlen_rq;
          i_cfg_mem_trn_len<=p_in_cfg_mem_trn_len;

          fsm_state_cs <= S_MEM_REMAIN_SIZE_CALC;
        end if;

      --//------------------------------------
      --//Расчитываем сколько запрашиваемых данных осталось
      --//------------------------------------
      when S_MEM_REMAIN_SIZE_CALC =>

        i_mem_dlen_remain <= EXT(i_cfg_mem_dlen_rq, i_mem_dlen_remain'length) - EXT(i_mem_dlen_used, i_mem_dlen_remain'length);
        fsm_state_cs <= S_MEM_TRN_LEN_CALC;

      --//------------------------------------
      --//Назначаем размер транзакции write/read ОЗУ
      --//------------------------------------
      when S_MEM_TRN_LEN_CALC =>

        if i_mem_dlen_remain >= EXT(i_cfg_mem_trn_len, i_mem_dlen_remain'length) then
          i_mem_trn_len <= i_cfg_mem_trn_len;
          i_axi_awlen <= i_cfg_mem_trn_len - 1;
        else
          i_mem_trn_len <= i_mem_dlen_remain(i_mem_trn_len'range);
          i_axi_awlen <= i_mem_dlen_remain(i_axi_awlen'range) - 1;
        end if;

        fsm_state_cs <= S_MEM_SET_RQ;

      --//------------------------------------
      --//
      --//------------------------------------
      when S_MEM_SET_RQ =>

        if i_mem_dir=C_MEMWR_WRITE then
          i_axi_awvalid<='1';
          fsm_state_cs <= S_MEM_WAIT_RQ_EN;
        else
          i_axi_arvalid<='1';
          fsm_state_cs <= S_MEM_WAIT_RQ_EN;
        end if;

      --//------------------------------------
      --//
      --//------------------------------------
      when S_MEM_WAIT_RQ_EN =>

        if i_mem_dir=C_MEMWR_WRITE then
        --//Ждем когда Slave будет готов к приему write params
          if p_in_maxi_awready='1' then
            i_axi_awvalid<='0';
            fsm_state_cs <= S_MEM_TRN_START;
          end if;
        else
          if p_in_maxi_arready='1' then
            i_axi_arvalid<='0';
            fsm_state_cs <= S_MEM_TRN_START;
          end if;
        end if;

      --//------------------------------------
      --//
      --//------------------------------------
      when S_MEM_TRN_START =>

        if i_mem_dir=C_MEMWR_WRITE then
        --//Ждем когда Slave будет готов к приему данных
          if p_in_maxi_wready='1' then
            i_mem_trn_len<=i_mem_trn_len-1;
            i_mem_trn_work<='1';
            fsm_state_cs <= S_MEM_TRN;
          end if;
        else
            i_mem_trn_len<=i_mem_trn_len-1;
            i_mem_trn_work<='1';
            fsm_state_cs <= S_MEM_TRN;
        end if;

      --//----------------------------------------------
      --//Запись/Чтение данных ОЗУ
      --//----------------------------------------------
      when S_MEM_TRN =>

        if i_mem_wr_out='1' or i_mem_rd_out='1' then
          i_mem_dlen_used<=i_mem_dlen_used+1;

          if i_mem_trn_len=(i_mem_trn_len'range => '0') then
            i_mem_trn_len<=(others=>'0');
            i_mem_trn_work<='0';
            if i_mem_dir=C_MEMWR_WRITE then
              i_axi_bready<='1';
            end if;
            fsm_state_cs <= S_MEM_TRN_END;
          else
            i_mem_trn_len<=i_mem_trn_len-1;
          end if;
        end if;

      --//----------------------------------------------
      --//Анализ завершения текущей операции ОЗУ
      --//----------------------------------------------
      when S_MEM_TRN_END =>

        --//Вычисляем значение для обнавления адреса ОЗУ
        var_update_addr(1 downto 0) :=(others=>'0');--//Если i_cfg_mem_trn_len в DWORD
        var_update_addr(i_mem_trn_len'length+1 downto 2):=i_cfg_mem_trn_len;

        if (p_in_maxi_bvalid='1' and i_mem_dir=C_MEMWR_WRITE) or i_mem_dir=C_MEMWR_READ then
          i_axi_bready<='0';

          if i_cfg_mem_dlen_rq=i_mem_dlen_used then
            fsm_state_cs <= S_EXIT;
          else
            --//Вычисляем следующий адрес ОЗУ
            i_mem_adr_out<=i_mem_adr_out + EXT(var_update_addr, i_mem_adr_out'length);

            --//Переход к следующей транзакции write/read ОЗУ
            fsm_state_cs <= S_MEM_REMAIN_SIZE_CALC;
          end if;
        end if;

      --//----------------------------------------------
      --//Переходим к выполнению следующей операции
      --//----------------------------------------------
      when S_EXIT =>

        i_mem_dlen_used<=(others=>'0');
        i_mem_done<='1';
        fsm_state_cs <= S_IDLE;

    end case;
  end if;
end process;

--END MAIN
end behavioral;

