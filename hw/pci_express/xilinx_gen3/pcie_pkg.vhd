-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 04.11.2011 10:48:05
-- Module Name : pcie_pkg
--
-- Description :
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.prj_cfg.all;
use work.prj_def.all;

package pcie_pkg is

type TPce2Mem_Ctrl is record
dir       : std_logic; --C_MEMWR_WRITE/READ from mem_wr_pkg.vhd
start     : std_logic;
adr       : std_logic_vector(31 downto 0);--Adress(BYTE)
req_len   : std_logic_vector(17 downto 0);--Size(BYTE) max=128KB
trnwr_len : std_logic_vector((C_HREG_MEM_CTRL_TRNWR_M_BIT - C_HREG_MEM_CTRL_TRNWR_L_BIT) downto 0); --
trnrd_len : std_logic_vector((C_HREG_MEM_CTRL_TRNRD_M_BIT - C_HREG_MEM_CTRL_TRNRD_L_BIT) downto 0); --
end record;

type TPce2Mem_Status is record
done    : std_logic;
end record;

type TPCIE_pinin is record
clk_p    : std_logic;
clk_n    : std_logic;
rst_n    : std_logic;
rxp      : std_logic_vector(C_PCFG_PCIE_LINK_WIDTH - 1 downto 0);
rxn      : std_logic_vector(C_PCFG_PCIE_LINK_WIDTH - 1 downto 0);
end record;

type TPCIE_pinout is record
txp      : std_logic_vector(C_PCFG_PCIE_LINK_WIDTH - 1 downto 0);
txn      : std_logic_vector(C_PCFG_PCIE_LINK_WIDTH - 1 downto 0);
end record;

type TPCIE_cfgprm is record
link_width  : std_logic_vector(5 downto 0);--Count link PCI-Express negotiation with PC
max_payload : std_logic_vector(2 downto 0);--max_payload_size negotiation with PC
max_rd_req  : std_logic_vector(2 downto 0);--Max read request size for the device when acting as the Requester
master_en   : std_logic_vector(0 downto 0);
end record;

type TPCIEDesc is array (0 to 3) of std_logic_vector(31 downto 0);

type TPCIEtph is record
present : std_logic;                    -- TPH Present in the request
t_type  : std_logic_vector(1 downto 0) ;-- If TPH Present then TPH type
st_tag  : std_logic_vector(7 downto 0) ;-- TPH Steering tag of the request
end record;

type TPCIE_reqprm is record
desc : TPCIEDesc;
thp  : TPCIEtph;
first_be : std_logic_vector(3 downto 0);
last_be  : std_logic_vector(3 downto 0);
end record;

type TPCIE_dmaprm is record
addr  : std_logic_vector(31 downto 0);
len   : std_logic_vector(31 downto 0);--size (Byte)
end record;


--Buffer of core PCI-Express:
constant C_PCIE_BUF_NON_POSTED_QUEUE    : integer:=0;
constant C_PCIE_BUF_POSTED_QUEUE        : integer:=1;
constant C_PCIE_BUF_COMPLETION_QUEUE    : integer:=2;
constant C_PCIE_BUF_LOOK_AHEAD          : integer:=3;

--Header MEM pkt:
--(field FMT)
constant C_PCIE_FMT_MSG_4DW             : std_logic_vector(1 downto 0):="10";     --Msg  - 4DW, no data
constant C_PCIE_FMT_MSGD_4DW            : std_logic_vector(1 downto 0):="11";     --MsgD - 4DW, w/ data

--(field FMT + field TYPE)
constant C_PCIE_PKT_TYPE_IORD_3DW_ND    : std_logic_vector(6 downto 0):="0000010"; --(0x02) IORd   - 3DW, no data
constant C_PCIE_PKT_TYPE_IOWR_3DW_WD    : std_logic_vector(6 downto 0):="1000010"; --(0x42) IOWr   - 3DW, w/data
constant C_PCIE_PKT_TYPE_MWR_3DW_WD     : std_logic_vector(6 downto 0):="1000000"; --(0x40) MWr    - 3DW, w/data
constant C_PCIE_PKT_TYPE_MWR_4DW_WD     : std_logic_vector(6 downto 0):="1100000"; --(0x60) MWr    - 4DW, w/data
constant C_PCIE_PKT_TYPE_MRD_3DW_ND     : std_logic_vector(6 downto 0):="0000000"; --(0x00) MRd    - 3DW, no data
constant C_PCIE_PKT_TYPE_MRD_4DW_ND     : std_logic_vector(6 downto 0):="0100000"; --(0x20) MRd    - 4DW, no data
constant C_PCIE_PKT_TYPE_MRDLK_3DW_ND   : std_logic_vector(6 downto 0):="0000001"; --(0x01) MRdLk  - 3DW, no data
constant C_PCIE_PKT_TYPE_MRDLK_4DW_ND   : std_logic_vector(6 downto 0):="0100001"; --(0x21) MRdLk  - 4DW, no data
constant C_PCIE_PKT_TYPE_CPLLK_3DW_ND   : std_logic_vector(6 downto 0):="0001011"; --(0x0B) CplLk  - 3DW, no data
constant C_PCIE_PKT_TYPE_CPLDLK_3DW_WD  : std_logic_vector(6 downto 0):="1001011"; --(0x4B) CplDLk - 3DW, w/ data
constant C_PCIE_PKT_TYPE_CPL_3DW_ND     : std_logic_vector(6 downto 0):="0001010"; --(0x0A) Cpl    - 3DW, no data
constant C_PCIE_PKT_TYPE_CPLD_3DW_WD    : std_logic_vector(6 downto 0):="1001010"; --(0x4A) CplD   - 3DW, w/ data
constant C_PCIE_PKT_TYPE_CFGRD0_3DW_ND  : std_logic_vector(6 downto 0):="0000100"; --(0x04) CfgRd0 - 3DW, no data
constant C_PCIE_PKT_TYPE_CFGWR0_3DW_WD  : std_logic_vector(6 downto 0):="1000100"; --(0x44) CfgwR0 - 3DW, w/ data
constant C_PCIE_PKT_TYPE_CFGRD1_3DW_ND  : std_logic_vector(6 downto 0):="0000101"; --(0x05) CfgRd1 - 3DW, no data
constant C_PCIE_PKT_TYPE_CFGWR1_3DW_WD  : std_logic_vector(6 downto 0):="1000101"; --(0x45) CfgwR1 - 3DW, w/ data

constant C_PCIE_MAX_PAYLOAD_128_BYTE    : std_logic_vector(2 downto 0):="000";
constant C_PCIE_MAX_PAYLOAD_256_BYTE    : std_logic_vector(2 downto 0):="001";
constant C_PCIE_MAX_PAYLOAD_512_BYTE    : std_logic_vector(2 downto 0):="010";
constant C_PCIE_MAX_PAYLOAD_1024_BYTE   : std_logic_vector(2 downto 0):="011";
constant C_PCIE_MAX_PAYLOAD_2048_BYTE   : std_logic_vector(2 downto 0):="100";
constant C_PCIE_MAX_PAYLOAD_4096_BYTE   : std_logic_vector(2 downto 0):="101";

constant C_PCIE_MAX_RD_REQ_128_BYTE     : std_logic_vector(2 downto 0):="000";
constant C_PCIE_MAX_RD_REQ_256_BYTE     : std_logic_vector(2 downto 0):="001";
constant C_PCIE_MAX_RD_REQ_512_BYTE     : std_logic_vector(2 downto 0):="010";
constant C_PCIE_MAX_RD_REQ_1024_BYTE    : std_logic_vector(2 downto 0):="011";
constant C_PCIE_MAX_RD_REQ_2048_BYTE    : std_logic_vector(2 downto 0):="100";
constant C_PCIE_MAX_RD_REQ_4096_BYTE    : std_logic_vector(2 downto 0):="101";

constant C_PCIE_COMPL_STATUS_SC         : std_logic_vector(2 downto 0):="000";
constant C_PCIE_COMPL_STATUS_UR         : std_logic_vector(2 downto 0):="001";
constant C_PCIE_COMPL_STATUS_CRS        : std_logic_vector(2 downto 0):="010";
constant C_PCIE_COMPL_STATUS_CA         : std_logic_vector(2 downto 0):="011";


constant C_PCIE3_PKT_TYPE_MEM_RD_ND    : std_logic_vector(3 downto 0) := "0000"; --Memory Read
constant C_PCIE3_PKT_TYPE_MEM_WR_D     : std_logic_vector(3 downto 0) := "0001"; --Memory Write
constant C_PCIE3_PKT_TYPE_IO_RD_ND     : std_logic_vector(3 downto 0) := "0010"; --IO Read
constant C_PCIE3_PKT_TYPE_IO_WR_D      : std_logic_vector(3 downto 0) := "0011"; --IO Write
constant C_PCIE3_PKT_TYPE_ATOP_FAA     : std_logic_vector(3 downto 0) := "0100"; --Fetch and ADD
constant C_PCIE3_PKT_TYPE_ATOP_UCS     : std_logic_vector(3 downto 0) := "0101"; --Unconditional SWAP
constant C_PCIE3_PKT_TYPE_ATOP_CAS     : std_logic_vector(3 downto 0) := "0110"; --Compare and SWAP
constant C_PCIE3_PKT_TYPE_MEM_LK_RD_ND : std_logic_vector(3 downto 0) := "0111"; --Locked Read Request
constant C_PCIE3_PKT_TYPE_MSG          : std_logic_vector(3 downto 0) := "1100"; --MSG Transaction apart from Vendor Defined and ATS
constant C_PCIE3_PKT_TYPE_MSG_VD       : std_logic_vector(3 downto 0) := "1101"; --MSG Transaction apart from Vendor Defined and ATS
constant C_PCIE3_PKT_TYPE_MSG_ATS      : std_logic_vector(3 downto 0) := "1110"; --MSG Transaction apart from Vendor Defined and ATS

constant C_PCIE3_COMPL_ERR_CODE_OK     : std_logic_vector(3 downto 0) := "0000"; --Normal termination (all data recieved)



type TDBG_darray is array (0 to 2) of std_logic_vector(31 downto 0);

--type TPCIE_dbg is record
----axi_rq_tdata  : TDBG_darray;
----axi_rq_fsm    : std_logic_vector(3 downto 0);
----axi_rq_tkeep  : std_logic_vector(1 downto 0);
--axi_rq_tready : std_logic;
--axi_rq_tvalid : std_logic;
--axi_rq_tlast  : std_logic;
--
----axi_rc_tdata  : TDBG_darray;
----axi_rc_fsm    : std_logic_vector(2 downto 0);
--axi_rc_tkeep  : std_logic_vector(1 downto 0);
--axi_rc_tready : std_logic;
--axi_rc_tvalid : std_logic;
--axi_rc_tlast  : std_logic;
----axi_rc_sop    : std_logic_vector(1 downto 0);
----axi_rc_disc   : std_logic;
--
--dev_num   : std_logic_vector(3 downto 0);
--dma_start : std_logic;
--dma_dir   : std_logic;
--dma_irq_clr : std_logic;
----dma_work    : std_logic;
----dma_worktrn : std_logic;
----dma_timeout  : std_logic;
--
----PCIE -> DEV
--h2d_buf_d     : TDBG_darray;
--h2d_buf_wr    : std_logic;
----h2d_buf_full  : std_logic;
------PCIE <- DEV
--d2h_buf_d     : TDBG_darray;
--d2h_buf_rd    : std_logic;
----d2h_buf_empty : std_logic;
--
--irq_stat : std_logic_vector(6 downto 0);
--irq_int  : std_logic;
--irq_pend : std_logic;
----irq_sent : std_logic;
----
----irq_msi_en  : std_logic;
----irq_msi_int : std_logic;
----irq_msi_pending_status : std_logic;
----irq_msi_send : std_logic;
----irq_msi_fail : std_logic;
----irq_msi_vf_enable : std_logic_vector(5 downto 0);
----irq_msi_mmenable : std_logic_vector(5 downto 0);
--
----test_speed_bit : std_logic;
----memctrl_trn_done : std_logic;
--end record;


type TPCIE_dbg is record
dev_num    : std_logic_vector(3 downto 0);
dma_dir    : std_logic;
dma_bufnum : std_logic_vector(7 downto 0);
dma_done   : std_logic;
dma_init   : std_logic;
dma_work   : std_logic;

axi_rq_tready : std_logic;
axi_rq_tvalid : std_logic;
axi_rq_tlast  : std_logic;
axi_rq_tkeep  : std_logic_vector(3 downto 0);
axi_rq_tdata  : TDBG_darray;
--axi_rq_tuser  : std_logic_vector(7 downto 0);

axi_cq_tready : std_logic;
axi_cq_tvalid : std_logic;
axi_cq_tlast  : std_logic;

axi_rc_err    : std_logic_vector(6 downto 0);
axi_rc_err_detect: std_logic;
axi_rc_fsm    : std_logic_vector(2 downto 0);
axi_rc_tready : std_logic;
axi_rc_tvalid : std_logic;
axi_rc_tlast  : std_logic;
axi_rc_tkeep  : std_logic_vector(3 downto 0);
axi_rc_tdata  : TDBG_darray;
axi_rc_sof    : std_logic_vector(1 downto 0);
axi_rc_discon : std_logic;

axi_cc_tready : std_logic;
axi_cc_tvalid : std_logic;
axi_cc_tlast  : std_logic;
axi_cc_tkeep  : std_logic_vector(3 downto 0);

req_compl: std_logic;
compl_done: std_logic;

d2h_buf_rd    : std_logic;
d2h_buf_empty : std_logic;

h2d_buf_wr   : std_logic;
h2d_buf_full : std_logic;

--irq_set     : std_logic_vector(2 downto 0);
irq_int     : std_logic;
irq_pending : std_logic;
irq_sent    : std_logic;

test_speed   : std_logic;

dma_mrd_rxdwcount: std_logic_vector(31 downto 0);

--dma_bufadr : std_logic_vector(31 downto 0);
--dma_bufsize: std_logic_vector(31 downto 0);

--cfg_fc_ph   : std_logic_vector( 7 downto 0);
--cfg_fc_pd   : std_logic_vector(11 downto 0);
--cfg_fc_nph  : std_logic_vector( 7 downto 0);
--cfg_fc_npd  : std_logic_vector(11 downto 0);
--cfg_fc_cplh : std_logic_vector( 7 downto 0);
--cfg_fc_cpld : std_logic_vector(11 downto 0);
--
--tfc_nph_av  : std_logic_vector(1 downto 0)                ;
--tfc_npd_av  : std_logic_vector(1 downto 0)                ;

end record;

end package pcie_pkg;
