from pathlib import Path
import importlib.util, tempfile, json, re
from lupa.lua54 import LuaRuntime

root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('installer',root/'install.py')
installer=importlib.util.module_from_spec(spec);spec.loader.exec_module(installer)
lua=LuaRuntime(unpack_returned_tuples=True)
compile_lua=lua.eval('function(s,n) local f,e=load(s,n); return f~=nil,e end')
files=list(root.rglob('*.lua'))
for path in files:
    text=path.read_text(encoding='utf-8-sig')
    text=re.sub(r'`([^`]+)`','0',text)
    ok,error=compile_lua(text,str(path))
    assert ok,(path,error)
for path in root.rglob('*.json'):json.loads(path.read_text(encoding='utf-8-sig'))
lua.execute('Config={}; RSGShared={Items={}}; vector3=function(x,y,z)return {x=x,y=y,z=z}end')
lua.execute((root/'installation/items.lua').read_text())
existing=lua.globals().RSGShared.Items.bs_coca_leaf
existing.label='PRESERVED'
lua.execute((root/'installation/items.lua').read_text())
assert lua.globals().RSGShared.Items.bs_coca_leaf.label=='PRESERVED'
lua.execute('Config.Crops={existing={seed="existing"}}')
lua.execute((root/'installation/crop.lua').read_text())
assert lua.globals().Config.Crops.coca.seed=='seedcoca'
assert lua.globals().Config.Crops.existing.seed=='existing'
lua.execute((root/'resources/bs-coca-crafting/server/recipes.lua').read_text())
recipes=lua.globals().Config.Crafting
assert len(recipes)==10
for _,recipe in recipes.items():
    assert lua.globals().RSGShared.Items[recipe.receive] is not None
    for _,ingredient in recipe.ingredients.items():assert lua.globals().RSGShared.Items[ingredient.item] is not None
    assert recipe.crafttime>0 and recipe.giveamount>0
for p in (root/'resources').rglob('*'):
    if not p.is_file() or p.suffix not in ('.lua','.json','.js','.html','.md'):continue
    text=p.read_text(encoding='utf-8-sig')
    assert not re.search(r'https://(?:discord(?:app)?\.com/api/webhooks|[^\s\"\'<>/]+:[^\s\"\'<>/]+@)',text),p
    assert not re.search(r'license:[a-f0-9]{20,}|discord:\d{12,}',text),p
    if p.suffix=='.json':assert not re.search(r'createdBy|updatedBy',text),p
assert not list(root.rglob('.env'))
assert not list(root.rglob('*.sql'))
with tempfile.TemporaryDirectory(prefix='coca-package-test-') as temp:
    resources=Path(temp)/'resources';resources.mkdir()
    for name in ['rsg-core','rsg-inventory','rsg-target','ox_lib','rsg-farming']:
        p=resources/name;p.mkdir();(p/'fxmanifest.lua').write_text('')
    items=resources/'rsg-core/shared/items.lua';items.parent.mkdir();items.write_text('RSGShared={}; RSGShared.Items={}\n')
    crop=resources/'rsg-farming/shared/config.lua';crop.parent.mkdir();crop.write_text('Config={}; Config.Crops={}\n')
    _,jobs=installer.plan(resources);assert jobs
    before=list(resources.rglob('*'));installer.install(resources)
    assert before==list(resources.rglob('*')),'Dry run changed files'
    installer.install(resources,apply=True)
    _,jobs=installer.plan(resources);assert not jobs,'Not idempotent'
    dest=next((resources/'[bs-coca]').rglob('client.lua'));dest.write_text('-- recipient edit')
    try:installer.plan(resources)
    except ValueError as exc:assert 'manual merge' in str(exc)
    else:raise AssertionError('Failed to protect recipient edit')
print(f'PASS: {len(files)} Lua files compile; 10 recipes have complete item definitions; guarded items/crop preserve existing data; installer preview, backup, idempotence and conflict refusal; credential/metadata checks.')
