-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.11.2011 18:51:57
-- Module Name : mem_wr_pkg (axi)
--
-- Description :
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.vicg_common_pkg.all;
use work.mem_glob_pkg.all;

package mem_wr_pkg is

type TMemAXIwIN is record
--WAddr Port(usr_buf->mem)
aid    : std_logic_vector(C_MEMWR_IDWIDTH_MAX - 1 downto 0);
adr    : std_logic_vector(C_MEMWR_AWIDTH_MAX - 1 downto 0);
trnlen : std_logic_vector(7 downto 0);--(15 downto 0);
dbus   : std_logic_vector(2 downto 0);
burst  : std_logic_vector(1 downto 0);
lock   : std_logic_vector(0 downto 0);--(1 downto 0);
cache  : std_logic_vector(3 downto 0);
prot   : std_logic_vector(2 downto 0);
qos    : std_logic_vector(3 downto 0);
avalid : std_logic;
--WData Port
data   : std_logic_vector(C_MEMWR_DWIDTH_MAX - 1 downto 0);
dbe    : std_logic_vector(C_MEMWR_DWIDTH_MAX/8 - 1 downto 0);
dlast  : std_logic;
dvalid : std_logic;
--WResponse Port
rready : std_logic;
end record;

type TMemAXIwOUT is record
--WAddr Port(usr_buf->mem)
aready : std_logic;
--WData Port
wready : std_logic;
--WResponse Ports
rid    : std_logic_vector(C_MEMWR_IDWIDTH_MAX - 1 downto 0);
resp   : std_logic_vector(1 downto 0);
rvalid : std_logic;
end record;

type TMemAXIrIN is record
--RAddr Port(usr_buf<-mem)
aid    : std_logic_vector(C_MEMWR_IDWIDTH_MAX - 1 downto 0);
adr    : std_logic_vector(C_MEMWR_AWIDTH_MAX - 1 downto 0);
trnlen : std_logic_vector(7 downto 0);--(15 downto 0);
dbus   : std_logic_vector(2 downto 0);
burst  : std_logic_vector(1 downto 0);
lock   : std_logic_vector(0 downto 0);--(1 downto 0);
cache  : std_logic_vector(3 downto 0);
prot   : std_logic_vector(2 downto 0);
qos    : std_logic_vector(3 downto 0);
avalid : std_logic;
--RData Port
rready : std_logic;
end record;

type TMemAXIrOUT is record
--RAddr Port(usr_buf<-mem)
aready : std_logic;
--RData Port
rid    : std_logic_vector(C_MEMWR_IDWIDTH_MAX - 1 downto 0);
data   : std_logic_vector(C_MEMWR_DWIDTH_MAX - 1 downto 0);
resp   : std_logic_vector(1 downto 0);
dlast  : std_logic;
dvalid : std_logic;
end record;

type TMemIN is record
axiw    : TMemAXIwIN;
axir    : TMemAXIrIN;
clk     : std_logic;
rstn    : std_logic;
end record;

type TMemOUT is record
axiw    : TMemAXIwOUT;
axir    : TMemAXIrOUT;
clk     : std_logic;
rstn    : std_logic;
end record;

--Type TMemINCh is array (0 to C_MEMCH_COUNT_MAX - 1) of TMemIN;
--Type TMemOUTCh is array (0 to C_MEMCH_COUNT_MAX - 1) of TMemOUT;

constant C_MEMWR_WRITE   : std_logic:='1';
constant C_MEMWR_READ    : std_logic:='0';

component mem_wr
generic(
G_USR_OPT        : std_logic_vector(3 downto 0):=(others=>'0');
G_MEM_IDW_NUM    : integer:=0;
G_MEM_IDR_NUM    : integer:=1;
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28;
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_mem_adr     : in    std_logic_vector(31 downto 0);
p_in_cfg_mem_trn_len : in    std_logic_vector(15 downto 0);
p_in_cfg_mem_dlen_rq : in    std_logic_vector(15 downto 0);
p_in_cfg_mem_wr      : in    std_logic;
p_in_cfg_mem_start   : in    std_logic;
p_out_cfg_mem_done   : out   std_logic;

-------------------------------
--USR Port
-------------------------------
--usr_buf->mem
p_in_usr_txbuf_dout  : in    std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_out_usr_txbuf_rd   : out   std_logic;
p_in_usr_txbuf_empty : in    std_logic;

--usr_buf<-mem
p_out_usr_rxbuf_din  : out   std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_out_usr_rxbuf_wd   : out   std_logic;
p_in_usr_rxbuf_full  : in    std_logic;

---------------------------------
--MEM_CTRL Port
---------------------------------
p_out_mem            : out   TMemIN;
p_in_mem             : in    TMemOUT;

-------------------------------
--DBG
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component mem_wr;

end package mem_wr_pkg;
