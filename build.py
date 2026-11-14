"""Build an offline software-center package from the public module tree."""
from pathlib import Path
import hashlib,re,tarfile,gzip
root=Path(__file__).resolve().parent
module=root/'mikuui'
version=re.search(r'^dbus set mikuui_version=([0-9.]+)$',(module/'install.sh').read_text(),re.M).group(1)
out=root/'dist';out.mkdir(exist_ok=True)
files=[]
for p in sorted(module.rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(module)
 if len(rel.parts)>1 and rel.parts[0] not in {'assets','scripts','webs','res','init.d'}:raise RuntimeError(f'Unexpected package path: {rel}')
 if p.is_symlink() or any(x.lower() in {'backup','backups','private','.private'} for x in rel.parts):raise RuntimeError(f'Private or linked content: {rel}')
 if p.suffix not in {'.sh','.awk','.css','.js','.asp','.png','.json','.txt'}:raise RuntimeError(f'Unexpected package file: {rel}')
 files.append(p)
archive=out/f'mikuui-{version}.tar.gz'
def normalize(info):
 info.uid=info.gid=0;info.uname=info.gname='root';info.mtime=0;info.pax_headers={}
 info.mode=0o755 if info.name.endswith('.sh') else 0o644
 return info
with archive.open('wb') as raw:
 with gzip.GzipFile(filename='',fileobj=raw,mode='wb',mtime=0) as zipped:
  with tarfile.open(fileobj=zipped,mode='w') as t:
   for p in files:
    t.add(p,arcname='mikuui/'+str(p.relative_to(module)),recursive=False,filter=normalize)

sha=hashlib.sha256(archive.read_bytes()).hexdigest()
(out/'SHA256SUMS.txt').write_text(f'{sha}  {archive.name}\n')
print(f'{archive}\nSHA256 {sha}\n{len(files)} public module files')
