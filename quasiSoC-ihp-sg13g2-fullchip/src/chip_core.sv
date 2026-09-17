`timescale 1ns/1ps
`default_nettype none
module chip_core(
  input wire clk, input wire rst_n,
  input wire [7:0] input_in,
  output wire [7:0] output_out
);
  wire uart_tx;
  wire [3:0] gpio_out;
  wire [7:0] debug;
  quasi_soc_core u_soc(
    .clk(clk), .rst_n(rst_n), .uart_rx(input_in[4]),
    .ext_irq(input_in[5]), .gpio_in(input_in[3:0]),
    .uart_tx(uart_tx), .gpio_out(gpio_out), .debug(debug)
  );
  assign output_out = {debug[2:0], gpio_out, uart_tx};
  wire _unused = &input_in[7:6];
endmodule
`default_nettype wire
