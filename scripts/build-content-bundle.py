#!/usr/bin/env python3
"""Versioned, data-only container. No scripts, scenes or serialized Godot resources.
ICDATA01 + little-endian manifest byte length + UTF-8 JSON + consecutive raw files.
Hashes detect corruption; they are not a publisher signature.
"""
import argparse,hashlib,json,struct
from pathlib import Path
ALLOWED={'.png','.jpg','.wav','.obj','.json','.txt'}
ROOTS=('materials','audio','content')
def build(output:Path,revision:int):
    files=[];payload=[]
    for folder in ROOTS:
        for p in sorted(Path('godot/assets',folder).rglob('*')):
            if not p.is_file() or p.suffix not in ALLOWED:continue
            raw=p.read_bytes(); assert len(raw)<=16*1024*1024
            files.append(dict(path=p.relative_to('godot').as_posix(),bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))
            payload.append(raw)
    manifest=dict(api=1,world_id='ashen-marches',revision=revision,files=files)
    header=json.dumps(manifest,separators=(',',':'),sort_keys=True).encode()
    data=b'ICDATA01'+struct.pack('<I',len(header))+header+b''.join(payload)
    assert len(header)<=131072 and len(data)<=256*1024*1024
    output.parent.mkdir(parents=True,exist_ok=True);output.write_bytes(data)
    output.with_suffix('.manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'DATA_BUNDLE_PASS: API 1 revision {revision}, {len(files)} raw assets, {len(data)} bytes')
    return manifest
if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('output',type=Path);a.add_argument('--revision',type=int,default=1)
    args=a.parse_args();build(args.output,args.revision)
