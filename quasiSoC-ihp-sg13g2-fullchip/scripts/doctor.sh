#!/usr/bin/env bash
set -u
failed=0
for tool in git librelane iverilog verilator; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "OK   $tool: $(command -v "$tool")"
  else
    echo "MISS $tool"
    failed=1
  fi
done
for file in librelane/config.yaml librelane/chip_top.sdc src/chip_top.sv rtl/upstream/riscv-multicyc.v; do
  if test -s "$file"; then echo "OK   $file"; else echo "MISS $file"; failed=1; fi
done
if command -v librelane >/dev/null 2>&1; then librelane --version || true; fi
exit "$failed"

