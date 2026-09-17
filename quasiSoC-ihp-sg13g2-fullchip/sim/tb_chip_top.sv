`timescale 1ns/1ps
module tb_chip_top;
  reg clk_drv=0, rst_n_drv=0; reg [7:0] inputs_drv=0;
  wire clk=clk_drv, rst_n=rst_n_drv; wire [7:0] inputs=inputs_drv; wire [7:0] outputs;
  chip_top dut(.clk_PAD(clk),.rst_n_PAD(rst_n),.input_PAD(inputs),.output_PAD(outputs));
  always #10 clk_drv=~clk_drv;
  initial begin
    $dumpfile("sim/quasi_soc.vcd"); $dumpvars(0,tb_chip_top);
    repeat(8) @(posedge clk); rst_n_drv=1;
    repeat(200) @(posedge clk);
    if (^outputs === 1'bx) $fatal(1,"X detected at output pads");
    $display("PASS output_PAD=%02x",outputs); $finish;
  end
endmodule
