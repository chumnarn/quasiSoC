`default_nettype none
module ibex_soc (
  input logic clk_i, rst_ni,
  input logic boot_mode_i, boot_sclk_i, boot_cs_ni, boot_mosi_i,
  input logic irq_i,
  input logic [7:0] gpio_i,
  output logic [7:0] gpio_o,
  output logic boot_ready_o, core_sleep_o
);
  logic [41:0] boot_shift_q;
  logic [5:0] boot_count_q;
  logic boot_toggle_q, boot_toggle_d;
  logic [9:0] boot_addr_q;
  logic [31:0] boot_data_q;
  always_ff @(posedge boot_sclk_i or negedge boot_cs_ni) begin
    if (!boot_cs_ni) begin boot_shift_q <= '0; boot_count_q <= '0; boot_toggle_q <= '0; end
    else if (boot_mode_i) begin
      boot_shift_q <= {boot_shift_q[40:0],boot_mosi_i};
      if (boot_count_q == 6'd41) begin
        boot_addr_q <= {boot_shift_q[8:0],boot_mosi_i};
        boot_data_q <= boot_shift_q[40:9];
        boot_toggle_q <= ~boot_toggle_q;
        boot_count_q <= '0;
      end else boot_count_q <= boot_count_q + 1'b1;
    end
  end
  logic boot_sync1_q, boot_sync2_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin boot_sync1_q<=0; boot_sync2_q<=0; boot_toggle_d<=0; end
    else begin boot_sync1_q<=boot_toggle_q; boot_sync2_q<=boot_sync1_q; boot_toggle_d<=boot_sync2_q; end
  end
  wire boot_write = boot_sync2_q ^ boot_toggle_d;
  assign boot_ready_o = boot_mode_i;

  logic instr_req, instr_gnt, instr_rvalid;
  logic [31:0] instr_addr, instr_rdata;
  logic data_req, data_gnt, data_rvalid, data_we;
  logic [3:0] data_be;
  logic [31:0] data_addr, data_wdata, data_rdata;

  ibex_top #(
    .PMPEnable(1'b0), .MHPMCounterNum(0), .RV32E(1'b0),
    .RV32M(ibex_pkg::RV32MFast), .RV32B(ibex_pkg::RV32BNone),
    .RV32ZC(ibex_pkg::RV32ZcaZcb), .RegFile(ibex_pkg::RegFileFF),
    .BranchTargetALU(1'b1), .WritebackStage(1'b1), .ICache(1'b0),
    .BranchPredictor(1'b0), .DbgTriggerEn(1'b0), .SecureIbex(1'b0)
  ) u_ibex (
    .clk_i, .rst_ni(rst_ni & ~boot_mode_i), .test_en_i(1'b0), .scan_rst_ni(1'b1),
    .ram_cfg_icache_tag_i('{default:prim_ram_1p_pkg::RAM_1P_CFG_REQ_DEFAULT}), .ram_cfg_icache_tag_o(),
    .ram_cfg_icache_data_i('{default:prim_ram_1p_pkg::RAM_1P_CFG_REQ_DEFAULT}), .ram_cfg_icache_data_o(),
    .hart_id_i(32'h0), .boot_addr_i(32'h0000_0000), .trvk_heap_base_addr_i('0),
    .instr_req_o(instr_req), .instr_gnt_i(instr_gnt), .instr_rvalid_i(instr_rvalid),
    .instr_addr_o(instr_addr), .instr_rdata_i(instr_rdata), .instr_rdata_intg_i('0), .instr_err_i(1'b0),
    .data_req_o(data_req), .data_gnt_i(data_gnt), .data_rvalid_i(data_rvalid), .data_we_o(data_we),
    .data_be_o(data_be), .data_addr_o(data_addr), .data_wdata_o(data_wdata), .data_wdata_intg_o(),
    .data_tag_o(), .data_rdata_i(data_rdata), .data_rdata_intg_i('0), .data_tag_i(1'b0), .data_err_i(1'b0),
    .trvk_revbm_req_o(), .trvk_revbm_gnt_i(1'b0), .trvk_revbm_rvalid_i(1'b0), .trvk_revbm_addr_o(),
    .trvk_revbm_rdata_i('0), .trvk_revbm_rdata_intg_i('0), .trvk_revbm_err_i(1'b0),
    .irq_software_i(1'b0), .irq_timer_i(1'b0), .irq_external_i(irq_i), .irq_fast_i('0), .irq_nm_i(1'b0),
    .scramble_key_valid_i(1'b0), .scramble_key_i('0), .scramble_nonce_i('0), .scramble_req_o(),
    .debug_req_i(1'b0), .crash_dump_o(), .double_fault_seen_o(),
    .fetch_enable_i(ibex_pkg::IbexMuBiOn), .mcounteren_writable_i(ibex_pkg::IbexMuBiOn),
    .alert_minor_o(), .alert_major_internal_o(), .alert_major_bus_o(), .core_sleep_o,
    .lockstep_cmp_en_o(), .data_req_shadow_o(), .data_we_shadow_o(), .data_be_shadow_o(),
    .data_addr_shadow_o(), .data_wdata_shadow_o(), .data_wdata_intg_shadow_o(),
    .instr_req_shadow_o(), .instr_addr_shadow_o(), .cheriot_enable_i(ibex_pkg::IbexMuBiOff)
  );

  wire gpio_sel = data_addr[31:12] == 20'h10000;
  assign data_gnt = data_req;
  logic data_pending_q, instr_pending_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin data_pending_q<=0; instr_pending_q<=0; gpio_o<='0; end
    else begin
      data_pending_q <= data_req;
      instr_pending_q <= instr_req & ~boot_mode_i;
      if (data_req && data_we && gpio_sel && data_be[0]) gpio_o <= data_wdata[7:0];
    end
  end
  assign data_rvalid = data_pending_q;
  assign instr_rvalid = instr_pending_q;
  assign instr_gnt = instr_req & ~boot_mode_i;

  logic [31:0] imem_q, dmem_q;
  ihp_sram_1kx32 u_imem(.clk_i, .en_i(boot_mode_i ? boot_write : instr_req),
    .we_i(boot_mode_i && boot_write), .be_i(4'hf),
    .addr_i(boot_mode_i ? boot_addr_q : instr_addr[11:2]),
    .wdata_i(boot_data_q), .rdata_o(imem_q));
  ihp_sram_1kx32 u_dmem(.clk_i, .en_i(data_req && !gpio_sel), .we_i(data_we), .be_i(data_be),
    .addr_i(data_addr[11:2]), .wdata_i(data_wdata), .rdata_o(dmem_q));
  assign instr_rdata = imem_q;
  assign data_rdata = gpio_sel ? {24'h0,gpio_i} : dmem_q;
endmodule
`default_nettype wire
