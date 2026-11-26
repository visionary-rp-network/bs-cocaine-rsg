"""Conservative installer: dry run by default; does not start services or execute SQL."""
from pathlib import Path
import argparse, hashlib, shutil, datetime

PACKAGE=Path(__file__).resolve().parent
def locate(root,name):
    matches=[p.parent for p in root.rglob('fxmanifest.lua') if p.parent.name==name]
    if len(matches)!=1:raise ValueError(f'Expected exactly one {name}, found {len(matches)}')
    return matches[0]
def plan(root,skip_farming=False):
    root=root.resolve(strict=True)
    if root.name.lower()!='resources':raise ValueError('Pass the resources folder, not the server folder')
    core=locate(root,'rsg-core'); inv=locate(root,'rsg-inventory')
    locate(root,'rsg-target');locate(root,'ox_lib')
    jobs=[]
    def append(path,snippet,marker,check):
        original=path.read_bytes();text=original.decode('utf-8-sig')
        if marker in text:return
        if check not in text:raise ValueError(f'Unsupported configuration format: {path}')
        if text.rstrip().endswith('return RSGShared.Items'):raise ValueError('Items file returns early; merge manually')
        jobs.append((path, original+b'\n'+(PACKAGE/snippet).read_bytes()))
    append(core/'shared/items.lua','installation/items.lua','-- BEGIN BS COCA ITEMS v1','RSGShared.Items')
    if not skip_farming:
        farm=locate(root,'rsg-farming')
        append(farm/'shared/config.lua','installation/crop.lua','-- BEGIN BS COCA CROP v1','Config.Crops')
    for source in sorted((PACKAGE/'installation/images').glob('*.png')):
        dest=inv/'html/images'/source.name
        if not dest.exists():jobs.append((dest,source.read_bytes()))
    for resource in sorted((PACKAGE/'resources').iterdir()):
        matches=[p.parent for p in root.rglob('fxmanifest.lua') if p.parent.name==resource.name]
        if len(matches)>1:raise ValueError('Duplicate existing resource '+resource.name)
        target=matches[0] if matches else root/'[bs-coca]'/resource.name
        for source in sorted(resource.rglob('*')):
            if not source.is_file():continue
            dest=target/source.relative_to(resource);data=source.read_bytes()
            if dest.exists():
                if dest.read_bytes()!=data:raise ValueError(f'Existing different file; manual merge needed: {dest}')
            else:jobs.append((dest,data))
    return root,jobs
def install(root,apply=False,skip_farming=False):
    root,jobs=plan(Path(root),skip_farming)
    print(f'{len(jobs)} files would be added/updated. No SQL or startup changes.')
    if not apply:return
    backup=root.parent/'bs-coca-install-backups'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup.mkdir(parents=True)
    entries=[]
    for dest,data in jobs:
        rel=dest.relative_to(root)
        existed=dest.exists()
        if existed:
            saved=backup/rel;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,saved)
        dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
        entries.append({'path':str(rel),'previously_existed':existed,'installed_sha256':hashlib.sha256(data).hexdigest()})
    import json
    (backup/'install-record.json').write_text(json.dumps(entries,indent=2),encoding='utf-8')
    print('Installed. Backup/record:',backup)
    print('Review startup.example.cfg, then perform a scheduled full server restart.')
if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--resources',required=True)
    parser.add_argument('--apply',action='store_true',help='Write files; stop the destination server first')
    parser.add_argument('--skip-farming',action='store_true',help='Wild field only; seed planting is NOT installed')
    args=parser.parse_args()
    try:install(args.resources,args.apply,args.skip_farming)
    except (ValueError,OSError) as exc:parser.exit(1,str(exc)+'\n')
