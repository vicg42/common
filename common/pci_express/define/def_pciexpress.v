//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 11/11/2009
//-- Module Name : def_pciexpress.v
//--
//-- Description : Константы для PCI-Express.
//--
//-- Revision:
//-- Revision 0.01 - File Created
//--
//-------------------------------------------------------------------------

//--------------------------------------------------------------------
// Пользовательские константы
//--------------------------------------------------------------------
//Назначение серийного номера устройcтву
`define C_PCIEXP_DEVICE_SERIAL_NUMBER   64'h000123 //Значение для регистров (PCI Express Device Serial Number (1st,2nd))
                                                   //CFG пространства PCI-Express


//--------------------------------------------------------------------
// Системные константы ()
//--------------------------------------------------------------------
`define BMD_64 //
`define PCIEBLK            1


//Номера буферов тередатчика ядра PCI-Express:
`define C_IDX_BUF_NON_POSTED_QUEUE       0
`define C_IDX_BUF_POSTED_QUEUE           1
`define C_IDX_BUF_COMPLETION_QUEUE       2
`define C_IDX_BUF_LOOK_AHEAD             3

//Константы заголовка пакета:
//(поле FMT)
`define C_FMT_MSG_4DW                  2'b10   //Msg  - 4DW, no data
`define C_FMT_MSGD_4DW                 2'b11   //MsgD - 4DW, w/ data

//(поле FMT + поле TYPE)
`define C_FMT_TYPE_IORD_3DW_ND         7'b00_00010 //(0x02) IORd   - 3DW, no data
`define C_FMT_TYPE_IOWR_3DW_WD         7'b10_00010 //(0x42) IOWr   - 3DW, w/data
`define C_FMT_TYPE_MWR_3DW_WD          7'b10_00000 //(0x40) MWr    - 3DW, w/data
`define C_FMT_TYPE_MWR_4DW_WD          7'b11_00000 //(0x60) MWr    - 4DW, w/data
`define C_FMT_TYPE_MRD_3DW_ND          7'b00_00000 //(0x00) MRd    - 3DW, no data
`define C_FMT_TYPE_MRD_4DW_ND          7'b01_00000 //(0x20) MRd    - 4DW, no data
`define C_FMT_TYPE_MRDLK_3DW_ND        7'b00_00001 //(0x01) MRdLk  - 3DW, no data
`define C_FMT_TYPE_MRDLK_4DW_ND        7'b01_00001 //(0x21) MRdLk  - 4DW, no data
`define C_FMT_TYPE_CPLLK_3DW_ND        7'b00_01011 //(0x0B) CplLk  - 3DW, no data
`define C_FMT_TYPE_CPLDLK_3DW_WD       7'b10_01011 //(0x4B) CplDLk - 3DW, w/ data
`define C_FMT_TYPE_CPL_3DW_ND          7'b00_01010 //(0x0A) Cpl    - 3DW, no data
`define C_FMT_TYPE_CPLD_3DW_WD         7'b10_01010 //(0x4A) CplD   - 3DW, w/ data
`define C_FMT_TYPE_CFGRD0_3DW_ND       7'b00_00100 //(0x04) CfgRd0 - 3DW, no data
`define C_FMT_TYPE_CFGWR0_3DW_WD       7'b10_00100 //(0x44) CfgwR0 - 3DW, w/ data
`define C_FMT_TYPE_CFGRD1_3DW_ND       7'b00_00101 //(0x05) CfgRd1 - 3DW, no data
`define C_FMT_TYPE_CFGWR1_3DW_WD       7'b10_00101 //(0x45) CfgwR1 - 3DW, w/ data


`define C_MAX_PAYLOAD_SIZE_128_BYTE    3'b000
`define C_MAX_PAYLOAD_SIZE_256_BYTE    3'b001
`define C_MAX_PAYLOAD_SIZE_512_BYTE    3'b010
`define C_MAX_PAYLOAD_SIZE_1024_BYTE   3'b011
`define C_MAX_PAYLOAD_SIZE_2048_BYTE   3'b100
`define C_MAX_PAYLOAD_SIZE_4096_BYTE   3'b101

`define C_MAX_READ_REQ_SIZE_128_BYTE   3'b000
`define C_MAX_READ_REQ_SIZE_256_BYTE   3'b001
`define C_MAX_READ_REQ_SIZE_512_BYTE   3'b010
`define C_MAX_READ_REQ_SIZE_1024_BYTE  3'b011
`define C_MAX_READ_REQ_SIZE_2048_BYTE  3'b100
`define C_MAX_READ_REQ_SIZE_4096_BYTE  3'b101

`define C_COMPLETION_STATUS_SC         3'b000
`define C_COMPLETION_STATUS_UR         3'b001
`define C_COMPLETION_STATUS_CRS        3'b010
`define C_COMPLETION_STATUS_CA         3'b011
