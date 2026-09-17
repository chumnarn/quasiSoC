# Changelog

## Revision 1 — 2026-09-17

Fixed the Icarus Verilog elaboration failure reported by `make sim`:

- forward references in `riscv-multicyc.v`
- forward references in `privilege.v`
- testbench variable-to-inout pad connections
- macro redefinition warnings
- `uart_busy` declaration ordering
- missing module time units
- CSR address width mismatch

Validation performed: shell syntax, YAML load and assertions, module/endmodule
balance, archive integrity, and SystemVerilog semantic compilation with slang.
The remaining upstream lint warnings are arithmetic signedness, explicit case
defaults and stylistic bitwise-parentheses warnings; none is an elaboration
error introduced by this integration.
