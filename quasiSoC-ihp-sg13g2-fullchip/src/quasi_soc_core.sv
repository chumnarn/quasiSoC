// ASIC-oriented Quasi SoC profile. Upstream CPU is GPL-3.0-or-later.
`timescale 1ns/1ps
`default_nettype none
module quasi_soc_core #(
  parameter integer CLOCK_HZ = 50000000,
  parameter integer BAUD = 115200
)(
  input  wire       clk,
  input  wire       rst_n,
  input  wire       uart_rx,
  input  wire       ext_irq,
  input  wire [3:0] gpio_in,
  output wire       uart_tx,
  output reg  [3:0] gpio_out,
  output wire [7:0] debug
);
  localparam [31:0] ROM_BASE  = 32'hf000_0000;
  localparam [31:0] RAM_BASE  = 32'h0000_0000;
  localparam [31:0] GPIO_BASE = 32'h1000_0000;
  localparam [31:0] UART_BASE = 32'h1000_0010;

  wire rst = ~rst_n;
  wire req, we, rd;
  wire [31:0] addr, wdata;
  reg  [31:0] rdata;
  reg ready;
  wire [31:0] dbg_pc, dbg_instr, dbg_ra, dbg_rb;
  wire [1:0] mode;
  wire paging;
  wire [21:0] root_ppn;
  wire eip_reply;
  reg uart_busy;
  wire [31:0] ram_rdata;
  reg ram_pending;

  riscv_multicyc #(.START_ADDR(ROM_BASE)) u_cpu (
    .clk(clk), .rst(rst), .tip(1'b0), .eip(ext_irq),
    .eip_reply(eip_reply), .mode(mode), .paging(paging),
    .root_ppn(root_ppn), .pagefault(1'b0), .accessfault(1'b0),
    .req(req), .gnt(1'b1), .hrd(1'b0), .a(addr), .d(wdata),
    .we(we), .rd(rd), .spo(rdata), .ready(ready),
    .dbg_pc(dbg_pc), .dbg_instr(dbg_instr), .dbg_ra(dbg_ra), .dbg_rb(dbg_rb)
  );

  // Bus data in the upstream CPU is byte-swapped at its boundary.
  function automatic [31:0] bswap32(input [31:0] x);
    bswap32 = {x[7:0],x[15:8],x[23:16],x[31:24]};
  endfunction

  // Minimal deterministic boot ROM. jal x0,0 is stored in the bus byte order
  // expected by the upstream CPU; all remaining words are RISC-V NOPs.
  wire [31:0] bootrom_rdata = (addr[9:2] == 8'h00)
                               ? 32'h6f00_0000 : 32'h0000_0013;

  wire rom_sel  = (addr[31:12] == ROM_BASE[31:12]);
  wire ram_sel  = (addr[31:12] == RAM_BASE[31:12]);
  wire gpio_sel = (addr[31:4]  == GPIO_BASE[31:4]);
  wire uart_sel = (addr[31:4]  == UART_BASE[31:4]);
  wire [31:0] gpio_read = {24'h0, 3'h0, ext_irq, gpio_in};
  wire ram_start = req && ram_sel && !ram_pending;

  // The IHP SRAM is synchronous. Launch one access, then return A_DOUT and
  // ready on the following cycle while the CPU holds its request stable.
  (* keep *) RM_IHPSG13_1P_1024x32_c2_bm_bist u_sram (
    .A_CLK(clk),
    .A_MEN(ram_start),
    .A_WEN(ram_start && we),
    .A_REN(ram_start && rd),
    .A_ADDR(addr[11:2]),
    .A_DIN(wdata),
    .A_DLY(1'b0),
    .A_DOUT(ram_rdata),
    .A_BM(32'hffff_ffff),
    .A_BIST_CLK(1'b0),
    .A_BIST_EN(1'b0),
    .A_BIST_MEN(1'b0),
    .A_BIST_WEN(1'b0),
    .A_BIST_REN(1'b0),
    .A_BIST_ADDR(10'h000),
    .A_BIST_DIN(32'h0000_0000),
    .A_BIST_BM(32'h0000_0000)
  );

  always @(*) begin
    ready = ram_sel ? ram_pending : req;
    rdata = 32'h0;
    if (rom_sel)       rdata = bootrom_rdata;
    else if (ram_sel)  rdata = ram_rdata;
    else if (gpio_sel) rdata = bswap32(gpio_read);
    else if (uart_sel) rdata = bswap32({30'h0, uart_busy, uart_rx});
  end

  always @(posedge clk) begin
    if (rst) begin
      gpio_out <= 4'h0;
      ram_pending <= 1'b0;
    end
    else begin
      if (ram_pending) ram_pending <= 1'b0;
      else if (ram_start) ram_pending <= 1'b1;
      if (req && we && gpio_sel) gpio_out <= wdata[27:24];
    end
  end

  localparam integer UART_DIV = (CLOCK_HZ / BAUD < 2) ? 2 : CLOCK_HZ / BAUD;
  reg [15:0] uart_divcnt;
  reg [3:0] uart_bitcnt;
  reg [9:0] uart_shift;
  assign uart_tx = uart_busy ? uart_shift[0] : 1'b1;
  always @(posedge clk) begin
    if (rst) begin
      uart_divcnt <= 0; uart_bitcnt <= 0; uart_shift <= 10'h3ff; uart_busy <= 0;
    end else if (!uart_busy && req && we && uart_sel) begin
      uart_shift <= {1'b1, wdata[31:24], 1'b0};
      uart_divcnt <= UART_DIV-1; uart_bitcnt <= 0; uart_busy <= 1;
    end else if (uart_busy) begin
      if (uart_divcnt == 0) begin
        uart_shift <= {1'b1,uart_shift[9:1]};
        uart_divcnt <= UART_DIV-1;
        if (uart_bitcnt == 9) uart_busy <= 0;
        else uart_bitcnt <= uart_bitcnt + 1'b1;
      end else uart_divcnt <= uart_divcnt - 1'b1;
    end
  end

  assign debug = {mode, eip_reply, uart_busy, dbg_pc[3:0]};
endmodule
`default_nettype wire
