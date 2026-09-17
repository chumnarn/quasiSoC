#!/usr/bin/env python3
"""Fetch pinned Ibex and export FuseSoC's dependency-ordered RTL for LibreLane."""
from pathlib import Path
import shutil, subprocess, sys, yaml
ROOT=Path(__file__).resolve().parents[1]
IBEX=ROOT/'third_party'/'ibex'
REV='90331a69edd7151413c335a7f4b3e950baa07c19'
def run(*a, cwd=ROOT): subprocess.run(a,cwd=cwd,check=True)
IBEX.parent.mkdir(parents=True,exist_ok=True)
if not (IBEX/'.git').exists(): run('git','clone','https://github.com/lowRISC/ibex.git',str(IBEX))
run('git','fetch','origin',REV,cwd=IBEX); run('git','checkout','--detach',REV,cwd=IBEX)
run('fusesoc','library','add','--sync-type','local','ibex',str(IBEX))
run('fusesoc','library','add','--sync-type','local','ibex_ihp',str(ROOT))
run('fusesoc','run','--target=lint','--setup','local:ibex:ihp_fullchip:1.0')
build=ROOT/'build'/'local_ibex_ihp_fullchip_1.0'/'lint-verilator'
eda=next(build.glob('*.eda.yml'))
data=yaml.safe_load(eda.read_text())
out=ROOT/'build'/'rtl'; inc=ROOT/'build'/'include'
shutil.rmtree(out,ignore_errors=True); shutil.rmtree(inc,ignore_errors=True)
out.mkdir(parents=True); inc.mkdir(parents=True)
seen=set(); n=0
for f in data['files']:
    p=build/Path(f['name']); typ=str(f.get('file_type','')).lower()
    if typ not in ('systemverilogsource','verilogsource'): continue
    rp=p.resolve()
    if rp in seen: continue
    seen.add(rp)
    if p.suffix in ('.sv','.v') and not f.get('is_include_file',False):
        shutil.copy2(rp,out/f'{n:03d}_{p.name}'); n+=1
    elif p.suffix in ('.svh','.vh') or f.get('is_include_file',False):
        dst=inc/p.name
        if dst.exists() and dst.read_bytes()!=rp.read_bytes():
            raise RuntimeError(f'conflicting include basename: {p.name}')
        shutil.copy2(rp,dst)
print(f'Exported {n} ordered RTL files to {out}')
