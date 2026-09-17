`timescale 1ns/1ps
module tb_chip_top;
  reg clk=0, rst_n=0; reg [7:0] inputs=0; wire [7:0] outputs;
  chip_top dut(.clk_PAD(clk),.rst_n_PAD(rst_n),.input_PAD(inputs),.output_PAD(outputs));
  always #10 clk=~clk;
  initial begin
    $dumpfile("sim/quasi_soc.vcd"); $dumpvars(0,tb_chip_top);
    repeat(8) @(posedge clk); rst_n=1;
    repeat(200) @(posedge clk);
    if (^outputs === 1'bx) $fatal(1,"X detected at output pads");
    $display("PASS output_PAD=%02x",outputs); $finish;
  end
endmodule

