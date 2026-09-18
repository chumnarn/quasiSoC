# Changelog

## Revision 10 — 2026-09-18

- hooks the SRAM's separate `VDDARRAY!` supply pin to chip `VDD`
- replaces the illegal direct Metal4-to-TopMetal1 macro connection
- adds the official IHP-style Metal5 SRAM stripes at 11.24 um pitch
- connects the macro PDN through adjacent layers Metal4-Metal5-TopMetal1
- fixes the critical disconnected pin and PDN via/shape connectivity warnings

## Revision 9 — 2026-09-18

- enlarged the die to 1600 x 1600 um and core to 870 x 870 um
- centered the 1Kx32 SRAM macro on the snapped placement grid
- added explicit `PDN_MACRO_CONNECTIONS` from `VDD!/VSS!` to `VDD/VSS`
- enables macro-to-grid power connection for the SRAM
- fixes post-CTS detailed-placement failure caused by insufficient whitespace
- fixes the disconnected SRAM supply-pin warnings from PDN generation

## Revision 8 — 2026-09-18

- replaced the inferred 1024x32 RAM with `RM_IHPSG13_1P_1024x32_c2_bm_bist`
- added a one-cycle SRAM request/ready adapter for the Quasi CPU bus
- added SRAM LEF, GDS, Verilog and multi-corner Liberty views to `MACROS`
- fixed the SRAM placement and connected its Metal4 rails to the top-level PDN
- added a behavioral SRAM model for simulation and lint
- reduced the constant boot ROM to equivalent combinational logic
- fixes global-placement utilization of 735% caused by 186,803 synthesized cells

## Revision 7 — 2026-09-18

- added Yosys `(* keep *)` attributes to every signal-pad instance
- prevents reserved input pads such as `inputs[6].input_pad` from being optimized away
- keeps the signal-only synthesis/powered-JSON-header split introduced in revision 6
- fixes `Odb.SetPowerConnections` reporting zero connections for a JSON-only pad instance

## Revision 6 — 2026-09-18

- removed `USE_POWER_PINS` from the ordinary synthesis `VERILOG_DEFINES`
- retains `VERILOG_POWER_DEFINE: USE_POWER_PINS` for LibreLane's powered JSON header
- removed the ineffective project-local pad whitebox override from revision 5
- follows the official IHP LibreLane template's split signal/power elaboration model
- fixes the repeated Yosys `sg13g2_IOPadOut30mA ... no port named 'vss'` failure

## Revision 5 — 2026-09-17

- added synthesis-only power-aware Yosys whiteboxes for the six IHP pad types used
- loads the pad interface before `chip_top` so Yosys sees `iovdd`, `iovss`, `vdd` and `vss`
- explicitly sets LibreLane `VERILOG_POWER_DEFINE` to `USE_POWER_PINS`
- fixes Yosys hierarchy failure: `sg13g2_IOPadOut30mA ... does not have a port named 'vss'`

## Revision 4 — 2026-09-17

- enabled `USE_POWER_PINS` during LibreLane synthesis
- explicitly connects every IHP pad `iovdd`, `iovss`, `vdd` and `vss` pin
- added a project preflight guard for missing power-aware pad elaboration
- fixes `Odb.SetPowerConnections` failure on generated input-pad instances

## Revision 3 — 2026-09-17

- replaced unsupported OpenSTA command `remove_from_collection`
- constrained input and output pads with explicit `get_ports` collections
- retained reset false-path handling and the original 2 ns/4 ns I/O budgets

## Revision 2 — 2026-09-17

- added `PROJECT_ID` and `make project-check`
- detect stale Ibex/FuseSoC files before simulation, lint or implementation
- documented clean extraction into a new directory
- clarified that Quasi SoC lint invokes Verilator directly and never clones Ibex

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
