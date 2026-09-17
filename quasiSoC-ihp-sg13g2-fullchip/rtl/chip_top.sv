`default_nettype none
module chip_top(
`ifdef USE_POWER_PINS
 inout wire IOVDD,IOVSS,VDD,VSS,
`endif
 inout wire clk_PAD,rst_n_PAD,boot_mode_PAD,boot_sclk_PAD,boot_cs_n_PAD,boot_mosi_PAD,irq_PAD,
 inout wire [7:0] gpio_in_PAD,gpio_out_PAD,
 inout wire boot_ready_PAD,core_sleep_PAD);
 wire clk,rst_n,boot_mode,boot_sclk,boot_cs_n,boot_mosi,irq,boot_ready,core_sleep;
 wire [7:0] gpio_i,gpio_o;
 `define PWR .iovdd(IOVDD),.iovss(IOVSS),.vdd(VDD),.vss(VSS),
 sg13g2_IOPadIn clk_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(clk),.pad(clk_PAD));
 sg13g2_IOPadIn rst_n_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(rst_n),.pad(rst_n_PAD));
 sg13g2_IOPadIn boot_mode_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(boot_mode),.pad(boot_mode_PAD));
 sg13g2_IOPadIn boot_sclk_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(boot_sclk),.pad(boot_sclk_PAD));
 sg13g2_IOPadIn boot_cs_n_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(boot_cs_n),.pad(boot_cs_n_PAD));
 sg13g2_IOPadIn boot_mosi_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(boot_mosi),.pad(boot_mosi_PAD));
 sg13g2_IOPadIn irq_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(irq),.pad(irq_PAD));
 generate for(genvar i=0;i<8;i++) begin: inputs
   sg13g2_IOPadIn gpio_in_pad(`ifdef USE_POWER_PINS `PWR `endif .p2c(gpio_i[i]),.pad(gpio_in_PAD[i]));
 end endgenerate
 generate for(genvar i=0;i<8;i++) begin: outputs
   sg13g2_IOPadOut30mA gpio_out_pad(`ifdef USE_POWER_PINS `PWR `endif .c2p(gpio_o[i]),.pad(gpio_out_PAD[i]));
 end endgenerate
 sg13g2_IOPadOut30mA boot_ready_pad(`ifdef USE_POWER_PINS `PWR `endif .c2p(boot_ready),.pad(boot_ready_PAD));
 sg13g2_IOPadOut30mA core_sleep_pad(`ifdef USE_POWER_PINS `PWR `endif .c2p(core_sleep),.pad(core_sleep_PAD));
 sg13g2_IOPadIOVdd iovdd_pad(`ifdef USE_POWER_PINS .iovdd(IOVDD),.iovss(IOVSS),.vdd(VDD),.vss(VSS) `endif);
 sg13g2_IOPadIOVss iovss_pad(`ifdef USE_POWER_PINS .iovdd(IOVDD),.iovss(IOVSS),.vdd(VDD),.vss(VSS) `endif);
 sg13g2_IOPadVdd vdd_pad(`ifdef USE_POWER_PINS .iovdd(IOVDD),.iovss(IOVSS),.vdd(VDD),.vss(VSS) `endif);
 sg13g2_IOPadVss vss_pad(`ifdef USE_POWER_PINS .iovdd(IOVDD),.iovss(IOVSS),.vdd(VDD),.vss(VSS) `endif);
 ibex_soc i_soc(.clk_i(clk),.rst_ni(rst_n),.boot_mode_i(boot_mode),.boot_sclk_i(boot_sclk),
  .boot_cs_ni(boot_cs_n),.boot_mosi_i(boot_mosi),.irq_i(irq),.gpio_i,
  .gpio_o,.boot_ready_o(boot_ready),.core_sleep_o(core_sleep));
 `undef PWR
endmodule
`default_nettype wire
