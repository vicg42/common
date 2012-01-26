-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.01.2012 17:39:19
-- Module Name : dsn_hdd_rambuf
--
-- Назначение/Описание :
--
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.video_ctrl_pkg.all;
use work.dsn_hdd_pkg.all;
use work.sata_glob_pkg.all;
use work.mem_wr_pkg.all;

entity dsn_hdd_rambuf is
generic(
G_MODULE_USE  : string:="ON";
G_RAMBUF_SIZE : integer:=23; --//(в BYTE). Определяется как 2 в степени G_RAMBUF_SIZE
G_DBGCS       : string:="OFF";
G_SIM         : string:="OFF";
G_MEM_AWIDTH  : integer:=32;
G_MEM_DWIDTH  : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         : in    THDDRBufCfg;   --Конфигурирование RAMBUF
p_out_rbuf_status     : out   THDDRBufStatus;--Статусы RAMBUF

----------------------------
--Связь с буфером видеоданных
----------------------------
p_in_vbuf_dout        : in    std_logic_vector(31 downto 0);
p_out_vbuf_rd         : out   std_logic;
p_in_vbuf_empty       : in    std_logic;
p_in_vbuf_full        : in    std_logic;
p_in_vbuf_pfull       : in    std_logic;
p_in_vbuf_wrcnt       : in    std_logic_vector(3 downto 0);

----------------------------
--Связь с модулем HDD
----------------------------
p_out_hdd_txd         : out   std_logic_vector(31 downto 0);
p_out_hdd_txd_wr      : out   std_logic;
p_in_hdd_txbuf_pfull  : in    std_logic;
p_in_hdd_txbuf_full   : in    std_logic;
p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          : in    std_logic_vector(31 downto 0);
p_out_hdd_rxd_rd      : out   std_logic;
p_in_hdd_rxbuf_empty  : in    std_logic;
p_in_hdd_rxbuf_pempty : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
--p_out_mem             : out   TMemIN;
--p_in_mem              : in    TMemOUT;
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
p_out_dbgcs           : out   TSH_ila;

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end dsn_hdd_rambuf;

architecture behavioral of dsn_hdd_rambuf is

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

component hdd_ram_hfifo
port(
din         : in std_logic_vector(31 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(31 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
empty       : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component;

type fsm_state is (
S_IDLE,
S_MEM_WRSTART,
S_MEM_WR,
S_MEM_RDSTART,
S_MEM_RD
);
signal fsm_state_cs: fsm_state;

signal i_rst                         : std_logic;

signal i_mem_ptr                     : std_logic_vector(31 downto 0);
signal i_mem_trn_len                 : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq                 : std_logic_vector(15 downto 0);
signal i_mem_start                   : std_logic;
signal i_mem_dir                     : std_logic;
signal i_mem_done                    : std_logic;

signal i_mem_wrstart                 : std_logic;
signal i_mem_wrdone                  : std_logic;
signal i_mem_rdstart                 : std_logic;
signal i_mem_rddone                  : std_logic;

signal i_hdd_txd_wr                  : std_logic;
signal i_hdd_rxd_rd                  : std_logic;

signal sr_ram_start                  : std_logic_vector(0 to 2);
signal i_ram_start                   : std_logic;

signal i_ram_txbuf_dout              : std_logic_vector(31 downto 0);
signal i_ram_txbuf_full              : std_logic;
signal i_ram_txbuf_afull             : std_logic;
signal i_ram_txbuf_empty             : std_logic;
signal i_ram_txbuf_rd                : std_logic;
signal i_ram_txd                     : std_logic_vector(31 downto 0);
signal i_ram_txd_rd                  : std_logic;
signal i_ram_txd_en_n                : std_logic;

signal i_ram_rxbuf_full              : std_logic;
signal i_ram_rxbuf_afull             : std_logic;
signal i_ram_rxbuf_empty             : std_logic;
signal i_ram_rxbuf_wr                : std_logic;
signal i_ram_rxbuf_din               : std_logic_vector(31 downto 0);
signal i_ram_rxd                     : std_logic_vector(31 downto 0);
signal i_ram_rxd_wr                  : std_logic;
signal i_ram_rxd_en_n                : std_logic;


signal tst_vwr_out                   : std_logic_vector(31 downto 0);
signal tst_vrd_out                   : std_logic_vector(31 downto 0);
--signal tst_ctrl                      : std_logic_vector(31 downto 0);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(4 downto 0)  <=tst_vwr_out(4 downto 0);
p_out_tst(9 downto 5)  <=tst_vrd_out(4 downto 0);
p_out_tst(11 downto 10)<=(others=>'0');
p_out_tst(13 downto 12)<=(others=>'0');
p_out_tst(14)          <=i_ram_start;
p_out_tst(15)          <='0';

p_out_tst(16)          <=tst_vwr_out(5);
p_out_tst(17)          <=tst_vrd_out(5);
p_out_tst(18)          <=tst_vwr_out(6);
p_out_tst(19)          <=tst_vrd_out(6);
p_out_tst(20)          <=i_ram_txbuf_rd;
p_out_tst(21)          <=i_ram_rxbuf_wr;
p_out_tst(22)          <=i_ram_txbuf_empty;
p_out_tst(23)          <=i_ram_rxbuf_empty;
p_out_tst(31 downto 24)<=(others=>'0');


p_out_vbuf_rd<=not p_in_vbuf_empty;

--//----------------------------------------------
--//
--//----------------------------------------------
p_out_rbuf_status.err<='0';
p_out_rbuf_status.err_type.vinbuf_full<='0';
p_out_rbuf_status.err_type.rambuf_full<='0';
p_out_rbuf_status.done <='0';
p_out_rbuf_status.hwlog_size<=(others=>'0');

i_rst<=p_in_rst or p_in_rbuf_cfg.dmacfg.clr_err;

--RAM<-CFG
m_txram : hdd_ram_hfifo
port map(
din         => p_in_rbuf_cfg.ram_wr_i.din,
wr_en       => p_in_rbuf_cfg.ram_wr_i.wr,
wr_clk      => p_in_rbuf_cfg.ram_wr_i.clk,

dout        => i_ram_txbuf_dout,
rd_en       => i_ram_txbuf_rd,
rd_clk      => p_in_clk,

full        => i_ram_txbuf_full,
almost_full => i_ram_txbuf_afull,
empty       => i_ram_txbuf_empty,

--clk         => p_in_clk,
rst         => i_rst
);

p_out_rbuf_status.ram_wr_o.wr_rdy<= not i_ram_txbuf_afull;
i_ram_txbuf_rd<=i_hdd_txd_wr when p_in_tst(7)='1' else i_ram_txd_rd;

i_ram_txd<=i_ram_txbuf_dout;
i_ram_txd_en_n<='1' when p_in_tst(7)='1' else i_ram_txbuf_empty;

p_out_hdd_txd<=i_ram_txbuf_dout;
p_out_hdd_txd_wr<=i_hdd_txd_wr;
i_hdd_txd_wr<=(not i_ram_txbuf_empty and not p_in_hdd_txbuf_pfull) when p_in_tst(7)='1' else '0';


--RAM->CFG
m_rxram : hdd_ram_hfifo
port map(
din         => i_ram_rxbuf_din,
wr_en       => i_ram_rxbuf_wr,
wr_clk      => p_in_clk,

dout        => p_out_rbuf_status.ram_wr_o.dout,
rd_en       => p_in_rbuf_cfg.ram_wr_i.rd,
rd_clk      => p_in_rbuf_cfg.ram_wr_i.clk,

full        => i_ram_rxbuf_full,
almost_full => i_ram_rxbuf_afull,
empty       => i_ram_rxbuf_empty,

--clk         => p_in_clk,
rst         => i_rst
);

p_out_rbuf_status.ram_wr_o.rd_rdy<= not i_ram_rxbuf_afull;
i_hdd_rxd_rd<=(not p_in_hdd_rxbuf_empty and not i_ram_rxbuf_afull) when p_in_tst(7)='1' else '0';
i_ram_rxbuf_wr<=i_hdd_rxd_rd when p_in_tst(7)='1' else i_ram_rxd_wr;
i_ram_rxbuf_din<=p_in_hdd_rxd when p_in_tst(7)='1' else i_ram_rxd;

i_ram_rxd_en_n<=i_ram_rxbuf_afull;

p_out_hdd_rxd_rd<=i_hdd_rxd_rd;

--//----------------------------------------------
--//Автомат записи видео информации
--//----------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;

    i_mem_ptr<=(others=>'0');
    i_mem_dlen_rq<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_dir<='0';
    i_mem_start<='0';

    sr_ram_start<=(others=>'0');
    i_ram_start<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    sr_ram_start<=p_in_rbuf_cfg.ram_wr_i.start & sr_ram_start(0 to 1);
    i_ram_start<=sr_ram_start(1) and not sr_ram_start(2);

    case fsm_state_cs is

      --------------------------------------
      --Исходное состояние
      --------------------------------------
      when S_IDLE =>

        if i_ram_start='1' then
          if p_in_rbuf_cfg.ram_wr_i.dir='1' then
            fsm_state_cs <= S_MEM_WRSTART;
          else
            fsm_state_cs <= S_MEM_RDSTART;
          end if;
        end if;

      --------------------------------------
      --Запускаем операцию записи ОЗУ
      --------------------------------------
      when S_MEM_WRSTART =>

        i_mem_ptr<=p_in_rbuf_cfg.mem_adr;

        i_mem_dlen_rq<=EXT(p_in_rbuf_cfg.ram_wr_i.dlen, i_mem_dlen_rq'length); --//DW
        i_mem_trn_len<=EXT(p_in_rbuf_cfg.mem_trn(7 downto 0), i_mem_trn_len'length);
        i_mem_dir<=C_MEMWR_WRITE;
        i_mem_start<='1';

        fsm_state_cs <= S_MEM_WR;

      ------------------------------------------------
      --Запись данных
      ------------------------------------------------
      when S_MEM_WR =>

        i_mem_start<='0';
        if i_mem_done='1' then
          fsm_state_cs <= S_IDLE;
        end if;

      --------------------------------------
      --Запускаем операцию чтения ОЗУ
      --------------------------------------
      when S_MEM_RDSTART =>

        i_mem_ptr<=p_in_rbuf_cfg.mem_adr;

        i_mem_dlen_rq<=EXT(p_in_rbuf_cfg.ram_wr_i.dlen, i_mem_dlen_rq'length); --//DW
        i_mem_trn_len<=EXT(p_in_rbuf_cfg.mem_trn(15 downto 8), i_mem_trn_len'length);
        i_mem_dir<=C_MEMWR_READ;
        i_mem_start<='1';

        fsm_state_cs <= S_MEM_RD;

      ------------------------------------------------
      --Чтение данных
      ------------------------------------------------
      when S_MEM_RD =>

        i_mem_start<='0';
        if i_mem_done='1' then
          fsm_state_cs <= S_IDLE;
        end if;

    end case;

  end if;
end process;


--//------------------------------------------------------
--//Модуль записи/чтения данных ОЗУ (mem_ctrl.vhd)
--//------------------------------------------------------
i_mem_done<=i_mem_wrdone or i_mem_rddone;
i_mem_wrstart<=i_mem_start when i_mem_dir=C_MEMWR_WRITE else '0';
i_mem_rdstart<=i_mem_start when i_mem_dir=C_MEMWR_READ  else '0';

m_wr : mem_wr
generic map(
G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_adr     => i_mem_ptr,
p_in_cfg_mem_trn_len => i_mem_trn_len,
p_in_cfg_mem_dlen_rq => i_mem_dlen_rq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_wrstart,
p_out_cfg_mem_done   => i_mem_wrdone,

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout  => i_ram_txd,
p_out_usr_txbuf_rd   => i_ram_txd_rd,
p_in_usr_txbuf_empty => i_ram_txd_en_n,

p_out_usr_rxbuf_din  => open,
p_out_usr_rxbuf_wd   => open,
p_in_usr_rxbuf_full  => '0',

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_memwr,
p_in_mem             => p_in_memwr,

-------------------------------
--System
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => tst_vwr_out,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);

m_rd : mem_wr
generic map(
G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_adr     => i_mem_ptr,
p_in_cfg_mem_trn_len => i_mem_trn_len,
p_in_cfg_mem_dlen_rq => i_mem_dlen_rq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_rdstart,
p_out_cfg_mem_done   => i_mem_rddone,

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout  => "00000000000000000000000000000000",
p_out_usr_txbuf_rd   => open,
p_in_usr_txbuf_empty => '0',

p_out_usr_rxbuf_din  => i_ram_rxd,
p_out_usr_rxbuf_wd   => i_ram_rxd_wr,
p_in_usr_rxbuf_full  => i_ram_rxd_en_n,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_memrd,
p_in_mem             => p_in_memrd,

-------------------------------
--System
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => tst_vrd_out,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);


--END MAIN
end behavioral;

