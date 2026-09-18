#!/usr/bin/env bash
set -eu

fail() {
  echo "ERROR: $*" >&2
  echo "Extract this archive into a new empty directory; do not overlay an Ibex project." >&2
  exit 2
}

test -f PROJECT_ID || fail "PROJECT_ID is missing."
grep -qx 'quasisoc-ihp-sg13g2-fullchip' PROJECT_ID || fail "Wrong PROJECT_ID."
test -s rtl/upstream/riscv-multicyc.v || fail "Quasi SoC CPU RTL is missing."
test -s src/quasi_soc_core.sv || fail "Quasi SoC ASIC wrapper is missing."
test -s sim/ihp_sram_sim.v || fail "IHP SRAM simulation model is missing."
grep -q '^DESIGN_NAME: chip_top$' librelane/config.yaml || fail "Unexpected LibreLane design."
if grep -Eq '^VERILOG_DEFINES:.*USE_POWER_PINS' librelane/config.yaml; then
  fail "USE_POWER_PINS must not be in VERILOG_DEFINES; it breaks signal-only synthesis pad models."
fi
grep -q '^VERILOG_POWER_DEFINE: USE_POWER_PINS$' librelane/config.yaml || \
  fail "LibreLane power-header elaboration is not configured."
test "$(grep -c '(\* keep \*) sg13g2_IOPad' src/chip_top.sv)" -eq 8 || \
  fail "Every signal and supply pad declaration must carry the Yosys keep attribute."
grep -q 'RM_IHPSG13_1P_1024x32_c2_bm_bist u_sram' src/quasi_soc_core.sv || \
  fail "The inferred 1Kx32 RAM was not replaced by the IHP SRAM macro."
grep -q '^MACROS:$' librelane/config.yaml || fail "LibreLane SRAM macro views are missing."
grep -q 'i_chip_core.*u_sram VDD VSS VDD! VSS!' librelane/config.yaml || \
  fail "The SRAM VDD!/VSS! pins are not hooked to the chip power nets."
grep -q 'i_chip_core.*u_sram VDD VSS VDDARRAY! VSS!' librelane/config.yaml || \
  fail "The SRAM VDDARRAY! pin is not hooked to the chip VDD net."
grep -q 'add_pdn_connect -grid sram_grid -layers "Metal4 Metal5"' librelane/pdn_cfg.tcl || \
  fail "The SRAM Metal4-to-Metal5 PDN connection is missing."
grep -q 'add_pdn_connect -grid sram_grid -layers "Metal5 TopMetal1"' librelane/pdn_cfg.tcl || \
  fail "The SRAM Metal5-to-TopMetal1 PDN connection is missing."
if grep -q 'reg \[31:0\] ram \[0:1023\]' src/quasi_soc_core.sv; then
  fail "A 1Kx32 inferred RAM would exceed the available core area."
fi

if test -e scripts/prepare_rtl.py || test -e third_party/ibex || test -e ibex.core; then
  fail "Ibex project files were detected in this Quasi SoC tree."
fi

if grep -q 'local:ibex:ihp_fullchip' Makefile 2>/dev/null; then
  fail "The Makefile belongs to the Ibex full-chip project."
fi

echo "PROJECT CHECK PASS: Quasi SoC full-chip revision 10"
