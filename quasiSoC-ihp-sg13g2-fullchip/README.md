# Quasi SoC Full-Chip Implementation — LibreLane 3.x + IHP SG13G2

คู่มือนี้เป็นชุดไฟล์พร้อมรันสำหรับทำ full-chip ASIC ของ **Quasi SoC ASIC reference profile** โดยใช้ CPU `riscv_multicyc` จาก [regymm/quasiSoC](https://github.com/regymm/quasiSoC) และโครง pad frame/bond pad จาก [IHP LibreLane template](https://github.com/IHP-GmbH/ihp-sg13g2-librelane-template)

> ขอบเขตสำคัญ: upstream top เดิมเป็น FPGA top ที่พึ่งพา Xilinx clocking, DDR/MIG, HDMI, SD, PSRAM และ absolute ROM paths จึงไม่ใช่ synthesizable ASIC top โดยตรง ชุดนี้สร้าง ASIC profile ที่คง RV32IM + privileged/interrupt logic และเพิ่ม boot ROM, 4 KiB SRAM แบบ inferred, GPIO, UART TX และ IHP digital pads ส่วน Linux/MMU/DDR และ peripheral ขนาดใหญ่เป็นงานขยายต่อ ไม่ได้แอบอ้างว่าอยู่ใน netlist นี้

## 1. สถาปัตยกรรม

| Block | รายละเอียด |
|---|---|
| CPU | Quasi SoC multi-cycle RV32IM, privileged CSR/IRQ enabled |
| Boot ROM | 256 x 32-bit, reset vector `0xf0000000` |
| RAM | 1024 x 32-bit inferred memory at `0x00000000` |
| GPIO | input/status `0x10000000`, output low nibble |
| UART | TX/status at `0x10000010`, 115200 baud at 50 MHz |
| Clock | external pad, 50 MHz target (`20 ns`) |
| Reset | active-low external pad |

Pad mapping:

| Pad | Function |
|---|---|
| `input_PAD[3:0]` | GPIO inputs |
| `input_PAD[4]` | UART RX/status input |
| `input_PAD[5]` | external interrupt |
| `input_PAD[7:6]` | reserved |
| `output_PAD[0]` | UART TX |
| `output_PAD[4:1]` | GPIO outputs |
| `output_PAD[7:5]` | debug |

## 2. ติดตั้ง environment

แนะนำ Ubuntu 24.04/WSL2 และ Nix:

```bash
git clone https://github.com/librelane/librelane
cd librelane
git checkout 3.0.0
nix-shell
librelane --version
```

ใช้ PDK ที่ติดตั้งผ่าน Ciel อยู่แล้วได้ เช่น `~/.ciel/ihp-sg13g2`. หาก directory layout ของเครื่องเป็น `~/.ciel/ciel/ihp-sg13g2` ให้ส่ง `PDK_ROOT` ให้ตรงกับ parent ที่ LibreLane ตรวจพบ

## 3. Preflight และ RTL verification

```bash
cd quasiSoC-ihp-sg13g2-fullchip
make doctor
make sim
make lint
```

Simulation ใช้ IHP pad behavioral stubs และตรวจว่า output หลัง reset ไม่มีค่า X โปรแกรม default ใน ROM คือ `jal x0,0` จึงเป็น deterministic smoke test ไม่ใช่ software functional test

## 4. ตรวจ config ก่อนรัน

```bash
librelane --pdk ihp-sg13g2 --pdk-root "$HOME/.ciel" \
  --flow Chip librelane/config.yaml --run-tag preflight \
  --to Yosys.Synthesis
```

ตรวจ log ให้พบ top `chip_top`, pad instances ครบ 20 ตัว, clock net `clk_pad/p2c` และไม่พบ unmapped cells นอกจาก IHP pads ที่ PDK resolve ให้

## 5. รัน RTL-to-GDSII

```bash
make flow PDK_ROOT="$HOME/.ciel"
```

หากต้องการ debug รอบแรกโดยข้ามเฉพาะ DRC:

```bash
make flow-nodrc PDK_ROOT="$HOME/.ciel"
```

คำสั่งนี้ยังคง synthesis, STA, floorplan, placement, CTS, routing, extraction และ LVS ตาม flow; ห้ามใช้ผล `flow-nodrc` เป็น signoff

## 6. ตรวจแต่ละ milestone

1. **Synthesis** — ดู cell count, latch count ต้องเป็นศูนย์ และเช็ก `check_design`/unmapped cells
2. **Floorplan** — die 1400 x 1400 µm, core 670 x 670 µm; pads ต้องไม่ชน corner/filler
3. **PDN** — VDD/VSS ring ต้องต่อจาก power pads ถึง standard-cell rails
4. **Placement** — utilization เริ่มที่ 35%; หาก congestion สูง ให้ขยาย core ก่อนลด timing goal
5. **CTS** — ตรวจ clock slew, insertion delay, skew และ ensure clock reaches CPU/RAM registers
6. **Routing** — global/detailed route violations ต้องเป็นศูนย์; `GRT_ALLOW_CONGESTION` มีไว้ให้ flow วิเคราะห์ต่อ ไม่ใช่ยอมรับ signoff violation
7. **STA** — setup/hold WNS ต้อง >= 0 ทุก signoff corner หรือบันทึก waiver ที่ตรวจสอบแล้ว
8. **Physical verification** — KLayout/Magic DRC, antenna และ Netgen LVS ต้อง clear

## 7. เปิดผลลัพธ์

```bash
make openroad PDK_ROOT="$HOME/.ciel"
make klayout  PDK_ROOT="$HOME/.ciel"
```

ผลสำคัญอยู่ใน `final/` และ `runs/<tag>/final/`: GDS, DEF/ODB, netlist, SDF, SPEF, Liberty/SDC และ metrics ตาม flow version

## 8. Firmware

ROM ใน `src/quasi_soc_core.sv` มี loop เริ่มต้นเพื่อให้ elaboration ไม่ขึ้นกับ absolute path การนำ firmware จริงเข้า ASIC ต้องแปลง instruction words เป็น bus-byte order ตาม boundary ของ upstream CPU ตัวอย่าง instruction `0x0000006f` เก็บเป็น `0x6f000000`

แนวทาง production คือ generate include/file ที่ deterministic แล้วเพิ่ม hash ใน build; หลีกเลี่ยง `$readmemh` absolute path. ทดสอบ firmware ด้วย simulator ก่อน harden ROM

## 9. Troubleshooting

- **`chip_top`/module not found**: ตรวจ `VERILOG_FILES` และ `VERILOG_INCLUDE_DIRS`
- **pad instance not found**: ชื่อ generate instance ใน YAML ต้อง escape `[`/`]` เช่น `inputs\\[0\\].input_pad`
- **clock not found**: ใช้ `CLOCK_PORT: clk_PAD`, `CLOCK_NET: clk_pad/p2c`
- **PDN disconnected**: ตรวจ VDD/VSS pads, `set_global_connections` และ core ring ใน GUI
- **routing congestion**: เพิ่ม `CORE_AREA`/`DIE_AREA`; อย่าเพิ่ม density
- **timing fail**: เริ่มจาก critical path report; CPU multi-cycle ไม่ได้แปลว่าทุก combinational path สั้น
- **memory area สูง**: เปลี่ยน inferred RAM เป็น `RM_IHPSG13_1P_1024x32_c2_bm_bist` พร้อม one-cycle handshake, macro placement, Liberty/GDS/LEF และ PDN macro grid
- **KLayout SealRing `psutil` warning**: ติดตั้ง Python `psutil`; warning นี้ไม่ใช่ DRC waiver

## 10. Signoff checklist

- [ ] revision ตรง `UPSTREAM.lock`
- [ ] `make sim` และ `make lint` ผ่าน
- [ ] synthesis ไม่มี latch/unmapped logic
- [ ] clocks/resets/IO delays ถูกต้อง
- [ ] no placement/routing violations
- [ ] setup/hold clean ทุก corner
- [ ] antenna clear
- [ ] KLayout และ Magic DRC clear
- [ ] LVS clear
- [ ] GDS เปิดตรวจ pad labels, seal ring และ hierarchy แล้ว
- [ ] gate-level simulation/SDF ผ่านกับ firmware จริง

## 11. ไฟล์หลัก

- `src/chip_top.sv` — IHP pad-frame top
- `src/chip_core.sv` — pad-to-SoC mapping
- `src/quasi_soc_core.sv` — ASIC SoC profile
- `rtl/upstream/` — pinned Quasi SoC CPU sources
- `librelane/config.yaml` — LibreLane 3 Chip flow
- `librelane/chip_top.sdc` — 50 MHz timing constraints
- `librelane/pdn_cfg.tcl` — VDD/VSS grid and ring
- `sim/` — Icarus smoke test

## 12. Compatibility fixes in revision 1

Revision 1 fixes strict Icarus elaboration failures reported by the first
release. The upstream CPU behavior is unchanged; only declaration order and
explicit widths were normalized.

- moved CPU signals, opcode constants and phase constants before first use
- moved `sepc` and `mcause_i_code` before first use in `privilege.v`
- removed duplicate `RV32M`/`IRQ_EN` macro warnings with guarded definitions
- changed the CSR address connection from 32 bits to its real 12-bit width
- moved `uart_busy` before the status combinational block
- connected full-chip `inout` pads to testbench nets driven by separate regs
- added explicit time units to project and pad-model modules

After updating, clean stale simulation output and rerun:

```bash
make clean
make sim
make lint
```

## License

Quasi SoC upstream CPU files remain GPL-3.0-or-later. Template-derived infrastructure retains its original Apache-2.0 licensing. Review licensing obligations before redistribution or tapeout.
