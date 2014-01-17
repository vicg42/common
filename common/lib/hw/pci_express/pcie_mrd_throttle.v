//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 11/11/2009
//-- Module Name : pcie_mrd_throttle.v
//--
//-- Description : Read Metering Unit.
//--               Задержка генерации запросов чтения (Когда FPGA-Master на Шине PCI-Express)
//--
//-- Revision:
//-- Revision 0.01 - File Created
//--
//-------------------------------------------------------------------------
`timescale 1ns/1ns

`define BMD_RD_THROTTLE_CPL_LIMIT 8

module pcie_mrd_throttle
(
  clk,
  rst_n,

  init_rst_i,

  mrd_work_i,
  mrd_len_i,
  mrd_pkt_count_i,     //I Кол-во переданых пакетов MRr

//  cpld_found_i,
  cpld_data_size_i,
  cpld_malformed_i,
  cpld_data_err_i,     //I

  cfg_rd_comp_bound_i, //I

  rd_metering_i,       //I

  mrd_work_o           //O

);

input         clk;
input         rst_n;

input         init_rst_i;

input         mrd_work_i;          // Start MRd Tx Command
input [31:0]  mrd_len_i;           // Memory Read Size Command (DWs)
input [15:0]  mrd_pkt_count_i;     // Кол-во переданых пакетов MRr

//input [31:0]  cpld_found_i;        // Current CompletionDs found
input [31:0]  cpld_data_size_i;    // Current Completion data found
input         cpld_malformed_i;    // Malformed(Деформированый) Compltion found
input         cpld_data_err_i;     // Compltion data error found

input         cfg_rd_comp_bound_i; // Programmed RCB = 0=64B or 1=128B
input         rd_metering_i;

output        mrd_work_o;          // Tx MRds

parameter     Tcq = 1;

wire          mrd_work_o;
reg   [31:0]  cpld_data_size_hwm;  // HWMark for Completion Data (DWs)
reg   [15:0]  cur_rd_count_hwm;    // HWMark for Read Count Allowed

reg           cpld_found;


/* Checking for received completions */
always @ ( posedge clk or negedge rst_n )
begin
  if (!rst_n )
  begin
    cpld_found <= #(Tcq) 1'b0;
  end
  else
  begin
    if (init_rst_i)
      cpld_found <= #(Tcq) 1'b0;
    else
    if ((mrd_pkt_count_i == (cur_rd_count_hwm + 1'b1)) &&
        (cpld_data_size_i >= cpld_data_size_hwm))
      cpld_found <= #(Tcq) 1'b1;
    else
      cpld_found <= #(Tcq) 1'b0;
  end
end



/* Here cur_rd_count_hwm is driven so that the mrd_work_o can be modulated */
always @ ( posedge clk or negedge rst_n )
begin
  if (!rst_n ) begin

    cpld_data_size_hwm <= #(Tcq) 32'hFFFF_FFFF;
    cur_rd_count_hwm <= #(Tcq) 15'h0;

  end else begin

    if (init_rst_i) begin

      cpld_data_size_hwm <= #(Tcq) 32'hFFFF_FFFF;
      cur_rd_count_hwm <= #(Tcq) 15'h0;

    end else begin

      if (mrd_work_i)
      begin
        if (cur_rd_count_hwm == 15'h0) // Initial burst
        begin

          if (!cfg_rd_comp_bound_i)
          //------------------------------------------
          // 64B RCB
          //------------------------------------------
          begin

            if ((mrd_len_i[10:0] == 1)) begin

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end else if ((mrd_len_i[10:0] > 1) &&           // > 4B
                         (mrd_len_i[10:0] <= 16))  begin    // <= 64B

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT/2;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end else if ((mrd_len_i[10:0] > 16) &&          // > 64B
                         (mrd_len_i[10:0] <= 32))  begin    // <= 128B

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT/4;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end else if ((mrd_len_i[10:0] > 32) &&          // > 128B
                         (mrd_len_i[10:0] <= 64))  begin    // <= 256B

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT/4;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end else if ((mrd_len_i[10:0] > 64) &&          // > 256B
                         (mrd_len_i[10:0] <= 128))  begin   // <= 512B

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT/8;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end else begin

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT/8;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end

          end
          else
          //------------------------------------------
          // 128B RCB
          //------------------------------------------
          begin

            if ((mrd_len_i[10:0] == 1)) begin

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end else if ((mrd_len_i[10:0] > 1) &&           // > 4B
                         (mrd_len_i[10:0] <= 32))  begin    // <= 128B

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT/2;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end else if ((mrd_len_i[10:0] > 32) &&        // > 128B
                         (mrd_len_i[10:0] <= 64))  begin  // <= 256B

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT/4;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end else if ((mrd_len_i[10:0] > 64) &&        // > 256B
                         (mrd_len_i[10:0] <= 128))  begin // <= 512B

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT/4;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end else begin

              cur_rd_count_hwm <= #(Tcq) `BMD_RD_THROTTLE_CPL_LIMIT/8;
              cpld_data_size_hwm <= #(Tcq) mrd_len_i[10:0];

            end

          end

        end else begin  // (cur_rd_count_hwm > 15'h0) i.e. after the initial burst, now one at a time

          if (cpld_malformed_i || cpld_data_err_i) begin

            cpld_data_size_hwm <= #(Tcq) 32'hFFFF_FFFF;
            cur_rd_count_hwm <= #(Tcq) 15'h0;

          end else if ((cpld_found == 1'b1)  && !mrd_work_o) begin

            cur_rd_count_hwm <= #(Tcq) cur_rd_count_hwm + 1'b1;
            cpld_data_size_hwm <= #(Tcq) cpld_data_size_hwm + mrd_len_i[10:0];

          end

        end

      end

    end

  end

end

assign mrd_work_o = (rd_metering_i == 0) ? mrd_work_i
                                      : (mrd_work_i & (cur_rd_count_hwm >= mrd_pkt_count_i));
endmodule // pcie_mrd_throttle

