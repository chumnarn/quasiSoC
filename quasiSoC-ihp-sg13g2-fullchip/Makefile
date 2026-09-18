ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PDK ?= ihp-sg13g2
PDK_ROOT ?= $(HOME)/.ciel
RTL := src/chip_top.sv src/chip_core.sv src/quasi_soc_core.sv \
 rtl/upstream/alu.v rtl/upstream/register_file.v rtl/upstream/rv32m.v \
 rtl/upstream/privilege.v rtl/upstream/riscv-multicyc.v
SIM_MODELS := sim/sg13g2_io_sim.v sim/ihp_sram_sim.v

.DEFAULT_GOAL := help
help:
	@echo "make project-check | doctor | clean | sim | lint | lint-physical | flow | flow-nodrc | openroad | klayout"

project-check:
	@bash scripts/check_project.sh

clean:
	$(RM) sim/quasi_soc.vvp sim/quasi_soc.vcd

doctor: project-check
	@bash scripts/doctor.sh

sim: project-check
	iverilog -g2012 -Wall -Irtl -DRV32M -DIRQ_EN -o sim/quasi_soc.vvp $(SIM_MODELS) $(RTL) sim/tb_chip_top.sv
	vvp sim/quasi_soc.vvp

lint: project-check
	verilator --lint-only -Wall -Wno-fatal --top-module chip_top -Irtl -DRV32M -DIRQ_EN $(SIM_MODELS) $(RTL)

lint-physical: project-check
	verilator --lint-only -Wall -Wno-fatal --top-module chip_top -Irtl -DUSE_POWER_PINS -DRV32M -DIRQ_EN $(SIM_MODELS) $(RTL)

flow: project-check
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --flow Chip librelane/config.yaml --save-views-to final

flow-nodrc: project-check
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --flow Chip librelane/config.yaml --save-views-to final --skip KLayout.DRC --skip Magic.DRC

openroad:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --last-run --flow OpenInOpenROAD librelane/config.yaml

klayout:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --last-run --flow OpenInKLayout librelane/config.yaml

.PHONY: help project-check doctor clean sim lint lint-physical flow flow-nodrc openroad klayout
