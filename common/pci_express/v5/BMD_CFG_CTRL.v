//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 11/11/2009
//-- Module Name : pcie_cfg.v
//--
//-- Description : Configuration Controller.
//--
//-- Revision:
//-- Revision 0.01 - File Created
//-- Revision 0.02 - ѕеренес из xapp1052 логику работы этого моду€ +
//                   add 2010.11.25_01 - как в xapp1052 +
//                   add 2010.11.25_02 - запретил чтение регистров конфигурационного пространства.
//                                       (посмотрим как будет работать в этом случае)
//-------------------------------------------------------------------------
`timescale 1ns/1ns
`include "../../../common/veresk_m/pci_express/define/def_pciexpress.v"

`define   BMD_CFG_STATE_RESET  5'b00001
`define   BMD_CFG_STATE_MSI    5'b00010
`define   BMD_CFG_STATE_DCAP   5'b00100
`define   BMD_CFG_STATE_LCAP   5'b01000
`define   BMD_CFG_STATE_END    5'b10000

//PCI Configuration Space Header: Adress map.
// ак вычисл€ютс€ адреса дл€ обращени€ к соотв. регистрам канфиг. пространства
//см. pcie_blk_plus_ug341.pdf/page 81/Accessing Additional Registers through the Configuration Port
`define   BMD_CFG_MSI_CAP0_ADDR  10'h012 //јдрес регистров MSI
`ifdef PCIEBLK
`define   BMD_CFG_DEV_CAP_ADDR   10'h019 //јдрес регистра PCI Express Device Capabilities (byte 0x64->0x19=0x64/4)
`define   BMD_CFG_LNK_CAP_ADDR   10'h01B //јдрес регистра PCI Express Link Capabilities (byte 0x6C->0x1B=0x6C/4)
`else // PCIEBLK
`define   BMD_CFG_DEV_CAP_ADDR   10'h017
`define   BMD_CFG_LNK_CAP_ADDR   10'h019
`endif // PCIEBLK


module pcie_cfg (

                    clk,
                    rst_n,

                    cfg_bus_mstr_enable,

                    cfg_dwaddr,
                    cfg_rd_en_n,
                    cfg_do,
                    cfg_rd_wr_done_n,

                    //add 2009.11.11
                    cfg_di,
                    cfg_byte_en_n,
                    cfg_wr_en_n,
                    //-------

                    cfg_cap_max_lnk_width,
                    cfg_cap_max_payload_size,
                    cfg_msi_enable

                    );

input               clk;
input               rst_n;

input               cfg_bus_mstr_enable;

output [9:0]        cfg_dwaddr;
output              cfg_rd_en_n;
input  [31:0]       cfg_do;
input               cfg_rd_wr_done_n;

//add 2010.11.25
output [31:0]       cfg_di;
output [3:0]        cfg_byte_en_n;
output              cfg_wr_en_n;
//------------------------------

//«апрашиваемый уст-вом max_lnk_width у системы  (значен. которые назначаютс€ в CoreGen)
//000001b = x1
//000010b = x2
//000100b = x4
//001000b = x8
//001100b = x12
//010000b = x16
//100000b = x32
output [5:0]        cfg_cap_max_lnk_width;

//«апрашиваемый уст-вом max_payload_size у системы(значен. которые назначаютс€ в CoreGen)
//000b = 128 bytes max payload size
//001b = 256 bytes max payload size
//010b = 512 bytes max payload size
//011b = 1KB max payload size
//100b = 2KB max payload size
//101b = 4KB max payload size
output [2:0]        cfg_cap_max_payload_size;

//'0'- Function is disabled from using MSI.
//     It must use INTX Messages to deliver interrupts (legacy endpoint or bridge).
//'1'- Function is enabled to use MSI to request service
//     and is forbidden to use its interrupt pin.
output              cfg_msi_enable;



//add 2010.11.25_01
assign cfg_di = 0;
assign cfg_byte_en_n = 4'hf;
assign cfg_wr_en_n = 1;
//------------------------------

////add 2010.11.25_02
//wire [9:0]           cfg_dwaddr;
//wire                 cfg_rd_en_n;
//wire [15:0]          cfg_msi_control;
//wire [5:0]           cfg_cap_max_lnk_width;
//wire [2:0]           cfg_cap_max_payload_size;
//
//assign cfg_rd_en_n = 1;
//assign cfg_dwaddr = 0;
//
//assign cfg_msi_control = 0;
//assign cfg_cap_max_lnk_width = 0;
//assign cfg_cap_max_payload_size = 0;
//assign cfg_msi_enable = 0;
////-----------------------------------



reg [4:0]           cfg_intf_state;
reg                 cfg_bme_state;
reg [9:0]           cfg_dwaddr;
reg                 cfg_rd_en_n;
reg [15:0]          cfg_msi_control;
reg [5:0]           cfg_cap_max_lnk_width;
reg [2:0]           cfg_cap_max_payload_size;

//„тение регистров конфигурационного пространства:
assign cfg_msi_enable = cfg_msi_control[0];

always @(posedge clk or negedge rst_n) begin

  if ( !rst_n ) begin

    cfg_dwaddr <= 0;
    cfg_rd_en_n <= 1'b1;
    cfg_msi_control <= 16'b0;
    cfg_cap_max_lnk_width <= 6'b0;
    cfg_cap_max_payload_size <= 3'b0;
    cfg_intf_state <= `BMD_CFG_STATE_RESET;
    cfg_bme_state <= 0;//cfg_bus_mstr_enable;

  end else begin

    case ( cfg_intf_state )

      `BMD_CFG_STATE_RESET : begin
        cfg_bme_state <= cfg_bus_mstr_enable;
        if (cfg_rd_wr_done_n == 1'b1 && cfg_bus_mstr_enable) begin
          cfg_dwaddr <= `BMD_CFG_MSI_CAP0_ADDR;
          cfg_rd_en_n <= 1'b0;
          cfg_intf_state <= `BMD_CFG_STATE_MSI;
        end else begin
          cfg_intf_state <= `BMD_CFG_STATE_RESET;
          cfg_rd_en_n <= 1'b1;
        end
      end

      `BMD_CFG_STATE_MSI : begin
        if (cfg_rd_wr_done_n == 1'b0) begin
          cfg_msi_control <= cfg_do[31:16];
          cfg_dwaddr <= `BMD_CFG_DEV_CAP_ADDR;
          cfg_rd_en_n <= 1'b0;
          cfg_intf_state <= `BMD_CFG_STATE_DCAP;
        end else begin
          cfg_intf_state <= `BMD_CFG_STATE_MSI;
        end
      end

      `BMD_CFG_STATE_DCAP : begin
        if (cfg_rd_wr_done_n == 1'b0) begin
          cfg_cap_max_payload_size <= cfg_do[2:0];
          cfg_dwaddr <= `BMD_CFG_LNK_CAP_ADDR;
          cfg_rd_en_n <= 1'b0;
          cfg_intf_state <= `BMD_CFG_STATE_LCAP;
        end else begin
          cfg_intf_state <= `BMD_CFG_STATE_DCAP;
        end
      end

      `BMD_CFG_STATE_LCAP : begin
        if (cfg_rd_wr_done_n == 1'b0) begin
          cfg_cap_max_lnk_width <= cfg_do[9:4];
          cfg_intf_state <= `BMD_CFG_STATE_END;
        end else begin
          cfg_intf_state <= `BMD_CFG_STATE_LCAP;
        end
      end

      `BMD_CFG_STATE_END : begin
        cfg_dwaddr <= 0;
        cfg_rd_en_n <= 1'b1;
        if (cfg_bme_state != cfg_bus_mstr_enable)
          cfg_intf_state <= `BMD_CFG_STATE_RESET;
        else
          cfg_intf_state <= `BMD_CFG_STATE_END;
      end

    endcase

  end

end



/*
assign cfg_dwaddr = 0;
assign cfg_rd_en_n = 1;

`ifdef _3GIO_1_LANE_PRODUCT
assign cfg_cap_max_lnk_width = 6'b000001;
assign cfg_cap_max_payload_size = 3'b010;
`endif // _3GIO_1_LANE_PRODUCT

`ifdef _3GIO_4_LANE_PRODUCT
assign cfg_cap_max_lnk_width = 6'b000100;
assign cfg_cap_max_payload_size = 3'b010;
`endif // _3GIO_4_LANE_PRODUCT

`ifdef _3GIO_4_LANE_PRODUCT
assign cfg_cap_max_lnk_width = 6'b001000;
assign cfg_cap_max_payload_size = 3'b001;
`endif // _3GIO_4_LANE_PRODUCT
*/


endmodule // pcie_cfg

