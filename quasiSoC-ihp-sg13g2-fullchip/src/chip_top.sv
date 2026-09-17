`default_nettype none
module chip_top(
`ifdef USE_POWER_PINS
  inout wire IOVDD, IOVSS, VDD, VSS,
`endif
  inout wire clk_PAD, rst_n_PAD,
  inout wire [7:0] input_PAD,
  inout wire [7:0] output_PAD
);
  wire clk, rst_n;
  wire [7:0] din, dout;
`define PWR .iovdd(IOVDD),.iovss(IOVSS),.vdd(VDD),.vss(VSS),
  sg13g2_IOPadIn clk_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(clk),.pad(clk_PAD));
  sg13g2_IOPadIn rst_n_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(rst_n),.pad(rst_n_PAD));
  genvar k;
  generate for(k=0;k<8;k=k+1) begin: inputs
    sg13g2_IOPadIn input_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(din[k]),.pad(input_PAD[k]));
  end endgenerate
  generate for(k=0;k<8;k=k+1) begin: outputs
    sg13g2_IOPadOut30mA output_pad(`ifdef USE_POWER_PINS `PWR `endif .c2p(dout[k]),.pad(output_PAD[k]));
  end endgenerate
  (* keep *) sg13g2_IOPadIOVdd iovdd_pad(`ifdef USE_POWER_PINS .iovdd(IOVDD),.iovss(IOVSS),.vdd(VDD),.vss(VSS) `endif);
  (* keep *) sg13g2_IOPadIOVss iovss_pad(`ifdef USE_POWER_PINS .iovdd(IOVDD),.iovss(IOVSS),.vdd(VDD),.vss(VSS) `endif);
  (* keep *) sg13g2_IOPadVdd vdd_pad(`ifdef USE_POWER_PINS .iovdd(IOVDD),.iovss(IOVSS),.vdd(VDD),.vss(VSS) `endif);
  (* keep *) sg13g2_IOPadVss vss_pad(`ifdef USE_POWER_PINS .iovdd(IOVDD),.iovss(IOVSS),.vdd(VDD),.vss(VSS) `endif);
  chip_core i_chip_core(.clk(clk),.rst_n(rst_n),.input_in(din),.output_out(dout));
`undef PWR
endmodule
`default_nettype wire

