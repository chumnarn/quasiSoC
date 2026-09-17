ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
export PATH := $(HOME)/.local/bin:$(PATH)
PDK_ROOT ?= $(HOME)/.ciel
PDK ?= ihp-sg13g2
RUN_TAG ?= ibex_$(shell date +%Y%m%d_%H%M%S)
.DEFAULT_GOAL := help
help:
	@echo "make setup | doctor | lint | harden | harden-nodrc | openroad | klayout | archive"
setup:
	@command -v fusesoc >/dev/null || { echo "ERROR: fusesoc missing; enter nix-shell first"; exit 1; }
	@python3 -c 'import yaml' || { echo "ERROR: PyYAML missing; enter nix-shell first"; exit 1; }
	python3 scripts/prepare_rtl.py
doctor:
	python3 scripts/doctor.py
lint: setup
	fusesoc run --target=lint local:ibex:ihp_fullchip:1.0
harden: setup doctor
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --run-tag $(RUN_TAG) --flow Chip librelane/config.yaml
harden-nodrc: setup doctor
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --run-tag $(RUN_TAG) --flow Chip librelane/config.yaml --skip KLayout.DRC --skip Magic.DRC
openroad:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --last-run --flow OpenInOpenROAD librelane/config.yaml
klayout:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --last-run --flow OpenInKLayout librelane/config.yaml
archive:
	tar --exclude='./third_party' --exclude='./build' --exclude='./librelane/runs' -czf ../ibex-ihp-sg13g2-fullchip.tar.gz .
.PHONY: help setup doctor lint harden harden-nodrc openroad klayout archive
