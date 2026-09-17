#!/usr/bin/env python3
from pathlib import Path
import shutil, sys, yaml
r=Path(__file__).resolve().parents[1]
errors=[]
for x in ('git','fusesoc','librelane'):
    local=Path.home()/'.local'/'bin'/x
    if not shutil.which(x) and not local.is_file(): errors.append(f'missing executable: {x}')
try:
    c=yaml.safe_load((r/'librelane/config.yaml').read_text())
    assert c['meta']['version']==3 and c['meta']['flow']=='Chip'
except Exception as e: errors.append(f'config.yaml: {e}')
for p in ('shell.nix','flake.nix','flake.lock','rtl/chip_top.sv','rtl/ibex_soc.sv','rtl/ihp_sram_1kx32.sv','librelane/chip_top.sdc','librelane/pdn_cfg.tcl'):
    if not (r/p).is_file(): errors.append(f'missing file: {p}')
print('Doctor: '+('FAIL' if errors else 'PASS'))
for e in errors: print(' - '+e)
sys.exit(bool(errors))
