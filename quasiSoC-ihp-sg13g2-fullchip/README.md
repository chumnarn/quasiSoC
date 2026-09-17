# Ibex Full-Chip Implementation on IHP SG13G2

Ready-to-run reference project for **LibreLane 3.x**, `config.yaml`, the IHP
`ihp-sg13g2` PDK, and lowRISC Ibex. It follows the official IHP LibreLane chip
template, including I/O cells, bond pads, two foundry SRAM macros, macro PDN,
and the `Chip` flow.

## Reproducible baseline

| Item | Pinned/selected value |
|---|---|
| Ibex | `90331a69edd7151413c335a7f4b3e950baa07c19` |
| IHP template baseline | `0418301723d86133de686ef743cfd668bb3d11d4` |
| LibreLane | 3.x; tested configuration schema version 3 |
| PDK | `ihp-sg13g2` |
| Clock target | 50 MHz (`20 ns`) |
| Core | RV32IMC, fast multiplier, FF register file, writeback stage |
| Memories | separate 1024x32 instruction and data SRAM macros |

The exact upstream revision is fetched by `scripts/prepare_rtl.py`. FuseSoC
resolves Ibex packages and lowRISC primitive dependencies and exports them in
dependency order. This avoids the common package-order failure caused by
feeding `rtl/*.sv` directly to Yosys.

## Chip architecture and memory map

The CPU is held in reset while `boot_mode_PAD=1`. A small serial loader writes
the instruction SRAM. Deasserting boot mode releases Ibex at address zero.

| Address | Size | Function |
|---|---:|---|
| `0x0000_0000` | 4 KiB | instruction SRAM (fetch port) |
| `0x0000_0000` | 4 KiB | data SRAM (data port) |
| `0x1000_0000` | 4 KiB window | GPIO: read input/write output at offset 0 |

The Harvard SRAMs intentionally overlap in the CPU address space. Instruction
fetches use `u_imem`; load/store operations use `u_dmem`.

## 1. Install prerequisites

The project now carries the same LibreLane 3.0 Nix environment pattern as the
official IHP template. From the project root run either command:

```bash
nix-shell
# or, on a flakes-enabled installation:
nix develop

librelane --version
ciel --version
fusesoc --version
```

The first invocation downloads/builds the pinned environment and can take some
time. If Nix rejects the binary cache as untrusted, add the substituter and
public key shown in `flake.nix` to `/etc/nix/nix.conf`, or allow Nix to build
the affected packages locally.

LibreLane 3.x has no `--interactive` and no `--override`; this project uses
only supported `--run-tag`, `--flow`, and `--skip` options.

## 2. Enable the PDK

If the PDK is already under `~/.ciel`, retain it. Otherwise use the PDK revision
recommended by the current IHP template:

```bash
ciel list --pdk-root "$HOME/.ciel"
ciel enable --pdk-family ihp-sg13g2 --pdk-root "$HOME/.ciel" <PDK_COMMIT>
```

Do not blindly copy an old PDK hash. The SRAM liberty filenames and I/O views
must match the installed PDK. `config.yaml` expects the standard paths under
`libs.ref/sg13g2_sram`.

## 3. Prepare dependency-ordered RTL

```bash
make setup
find build/rtl -maxdepth 1 -type f | sort | head
```

The script clones Ibex at the pinned commit, registers the local FuseSoC
libraries, runs setup only, then copies the resolved synthesizable Verilog and
SystemVerilog into `build/rtl` with numeric prefixes.

## 4. Preflight

```bash
make doctor
python3 - <<'PY'
import yaml
yaml.safe_load(open('librelane/config.yaml'))
print('YAML OK')
PY
make lint
```

Expected: Doctor reports `PASS`; FuseSoC/Verilator reports no fatal errors.
Warnings about unused optional Ibex outputs are expected because debug,
lockstep, cache, CHERIoT, and integrity features are tied off.

## 5. Load firmware through the serial boot port

Hold `boot_mode_PAD=1` and `boot_cs_n_PAD=0`, then raise chip reset. For every
32-bit word, set chip select high and clock exactly 42 bits, MSB first:

```text
[ data word: 32 bits, MSB first ][ word address: 10 bits, MSB first ]
```

Bring chip select low between records. The loader transfers the completed
record safely to the system clock domain and writes the instruction SRAM.
After all words are loaded, set `boot_mode_PAD=0`; Ibex starts at address 0.
`boot_ready_PAD` mirrors boot mode and can be used by the board controller.

Firmware linker requirements:

```ld
MEMORY { IMEM (rx) : ORIGIN = 0, LENGTH = 4K
         DMEM (rw) : ORIGIN = 0, LENGTH = 4K }
```

GPIO is at `0x10000000`. A store-byte updates `gpio_out_PAD[7:0]`; a load reads
`gpio_in_PAD[7:0]`.

## 6. Run floorplan through signoff

First use the complete flow:

```bash
make harden RUN_TAG=ibex_first
```

For routing iteration only, DRC may be skipped explicitly:

```bash
make harden-nodrc RUN_TAG=ibex_route_debug
```

Skipping DRC is never tapeout signoff. The final run must complete synthesis,
STA, floorplan, placement, CTS, routing, extraction, antenna, DRC and LVS.

## 7. Check each milestone

```bash
RUN=librelane/runs/ibex_first
rg -n "ERROR|unmapped|latch|multiple driver" "$RUN"/*/ 2>/dev/null
find "$RUN" -iname '*metrics*.json' -o -iname '*summary*.json'
```

Acceptance criteria:

1. Synthesis has no unmapped cells except declared I/O, bond-pad, and SRAM macros.
2. Both `i_soc.u_imem.u_sram` and `i_soc.u_dmem.u_sram` appear in the ODB.
3. Setup and hold slack are non-negative at all enabled corners.
4. Global/detailed routing has no unresolved violations.
5. KLayout and Magic DRC are clean or every waiver is documented.
6. KLayout antenna check is clear.
7. Netgen LVS reports match.
8. GDS contains pad ring, bond pads, SRAMs, seal ring, and routed PG nets.

## 8. Inspect results

```bash
make openroad
make klayout
```

In OpenROAD verify macro placement, halos, clock tree, congestion, and the
`VDD/VSS` special nets. In KLayout verify all pads and bond pads are present and
that the final seal ring does not overlap the pad frame.

## 9. Important implementation details

- `USE_SLANG: true` is intentional: current Ibex uses SystemVerilog packages,
  enums, structs, and parameter types beyond the safest legacy Yosys parser set.
- `SYNTHESIS` disables assertion-only structures and simulation code.
- The SRAM bit mask is 32 bits; each Ibex byte-enable is expanded to eight mask
  bits. A mask value of one writes that SRAM bit.
- SRAM reads are synchronous. `instr_rvalid` and `data_rvalid` are delayed one
  clock to match the macro.
- `boot_sclk_PAD` is asynchronous to `clk_PAD`. Only a toggle crosses the clock
  domain; the 42-bit record remains stable until the next serial record.
- The boot loader is a bring-up mechanism, not a secure boot implementation.

## 10. Debugging guide

| Symptom | Check / correction |
|---|---|
| package not found | rerun `make setup`; never replace the ordered files with a broad glob of upstream RTL |
| SRAM instance not found | hierarchy must remain `i_soc.u_imem.u_sram` and `i_soc.u_dmem.u_sram` in RTL, YAML and PDN Tcl |
| `A_BM` width warning | wrapper must expand 4 byte enables to 32 bits |
| GRT layer error | use exact IHP names (`Metal4`, `Metal5`, `TopMetal1`), not SKY130 names |
| pad missing | escape generated indices exactly as in `PAD_*` lists |
| `VDD_NETS/GND_NETS` error | define both lists together and keep top-level power names `VDD`, `VSS` |
| RSZ maximum buffers | inspect congestion/clock targets first; increase die/core area before relaxing limits |
| LVS power mismatch | check `PDN_MACRO_CONNECTIONS`, `MAGIC_EXT_UNIQUE: notopports`, and SRAM PG pin names |

## 11. Project layout

```text
rtl/                 chip top, Ibex SoC wrapper, SRAM wrapper
librelane/           config.yaml, SDC, custom macro PDN
scripts/             dependency exporter and preflight doctor
ip/                  IHP-template-compatible bond-pad views
ibex_ihp.core        FuseSoC dependency declaration
Makefile             reproducible commands
```

## Limitations before fabrication

This is an implementation reference, not a foundry signoff claim. Before a
shuttle submission, freeze exact LibreLane/PDK commits, run the foundry-qualified
DRC deck, complete IO/ESD and package review, characterize the asynchronous boot
interface, add production test access and memory BIST strategy, and perform
post-layout gate-level simulation with extracted delays.

## Upstream references

- https://github.com/lowRISC/ibex
- https://github.com/IHP-GmbH/ihp-sg13g2-librelane-template
- https://github.com/IHP-GmbH/IHP-Open-PDK
- https://librelane.readthedocs.io/
