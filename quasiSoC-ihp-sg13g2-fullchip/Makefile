ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PDK ?= ihp-sg13g2
PDK_ROOT ?= $(HOME)/.ciel
RTL := src/chip_top.sv src/chip_core.sv src/quasi_soc_core.sv \
 rtl/upstream/alu.v rtl/upstream/register_file.v rtl/upstream/rv32m.v \
 rtl/upstream/privilege.v rtl/upstream/riscv-multicyc.v

.DEFAULT_GOAL := help
help:
	@echo "make doctor | clean | sim | lint | flow | flow-nodrc | openroad | klayout"

clean:
	$(RM) sim/quasi_soc.vvp sim/quasi_soc.vcd

doctor:
	@bash scripts/doctor.sh

sim:
	iverilog -g2012 -Wall -Irtl -DRV32M -DIRQ_EN -o sim/quasi_soc.vvp sim/sg13g2_io_sim.v $(RTL) sim/tb_chip_top.sv
	vvp sim/quasi_soc.vvp

lint:
	verilator --lint-only -Wall -Wno-fatal --top-module chip_top -Irtl -DRV32M -DIRQ_EN sim/sg13g2_io_sim.v $(RTL)

flow:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --flow Chip librelane/config.yaml --save-views-to final

flow-nodrc:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --flow Chip librelane/config.yaml --save-views-to final --skip KLayout.DRC --skip Magic.DRC

openroad:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --last-run --flow OpenInOpenROAD librelane/config.yaml

klayout:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --last-run --flow OpenInKLayout librelane/config.yaml

.PHONY: help doctor clean sim lint flow flow-nodrc openroad klayout
