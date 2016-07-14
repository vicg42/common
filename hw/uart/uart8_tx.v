module uart8_tx #(
parameter STOPBITS = 1 // only 1 or 2
)
(
input clk,
input [23:0] baud_rate16, //baud_rate16 = Fbaud*(2^24)*16/Fclk = Fbaud*(2^28)/Fclk
input [7:0] txdata,
input txstart,
output reg busy = 0,
output reg txd = 1
);

// --------------------------------------------------------------------------------------------
reg baud_tick = 0;
reg [23:0] baud_cntr = 0;
reg [7:0] cntr = 0;
reg [7:0] byte_buf = 0;
reg busy_d = 0;

always @(posedge clk) begin

  //Direct Digital Synthesizers (DDS) baud rate generator
  if (busy)
  {baud_tick, baud_cntr} <= baud_cntr + baud_rate16;
  else begin
    baud_tick <= 0;
    baud_cntr <= 0;
  end

  // transmit machine
  txd <= 1;
  busy_d <= busy;
  if (!busy) begin
      if (txstart) begin
          cntr <= 0;
          byte_buf <= txdata;
          busy <= 1;
      end
  end else begin // transmitting
      if (baud_tick) begin
          cntr <= cntr + 1'b1;
      end

      if (cntr >= (16 * (1 + 8 + STOPBITS) - 1)) begin  // 1 start bit, data bits, stop bit(s)
          busy <= 0;
      end

      if ((cntr < 16) && busy_d) begin // start bit, delay one clk
          txd <= 0;
      end

      if ((cntr >= 16) && (cntr < (16 * (8 + 1)))) begin
          txd <= byte_buf[cntr[7:4] - 1'b1];
      end
  end
end

endmodule
