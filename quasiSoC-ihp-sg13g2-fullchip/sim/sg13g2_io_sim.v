`timescale 1ns/1ps
module sg13g2_IOPadIn(
  input pad, output p2c
`ifdef USE_POWER_PINS
  , inout iovdd, iovss, vdd, vss
`endif
); assign p2c=pad; endmodule

module sg13g2_IOPadOut30mA(
  input c2p, output pad
`ifdef USE_POWER_PINS
  , inout iovdd, iovss, vdd, vss
`endif
); assign pad=c2p; endmodule

module sg13g2_IOPadIOVdd(
`ifdef USE_POWER_PINS
  inout iovdd, iovss, vdd, vss
`endif
); endmodule
module sg13g2_IOPadIOVss(
`ifdef USE_POWER_PINS
  inout iovdd, iovss, vdd, vss
`endif
); endmodule
module sg13g2_IOPadVdd(
`ifdef USE_POWER_PINS
  inout iovdd, iovss, vdd, vss
`endif
); endmodule
module sg13g2_IOPadVss(
`ifdef USE_POWER_PINS
  inout iovdd, iovss, vdd, vss
`endif
); endmodule
