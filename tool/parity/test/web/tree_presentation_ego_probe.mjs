const assert = (await import('node:assert/strict')).default;
const fs = await import('node:fs/promises');
const task = await taskSpace(globalThis.treeProbeSpaceId ?? "CoUI Tree presentation probe");
const page = task.page('p1');
const output = globalThis.treeProbeOutput ?? '/tmp/coui-tree-presentation';
await fs.mkdir(output, {recursive:true});
const checks = [];
async function record(name) {
  const state = await page.evaluate(() => {
    const viewport=document.getElementById('probe-tree-viewport');
    const rows=[...document.querySelectorAll('[role=treeitem]')].map(e=>({
      id:e.id, level:e.getAttribute('aria-level'), tab:e.getAttribute('tabindex'),
      selected:e.getAttribute('aria-selected'),expanded:e.getAttribute('aria-expanded'),
      y:e.getBoundingClientRect().y, height:e.getBoundingClientRect().height,
    }));
    return {rows,active:document.activeElement?.id,scroll:viewport?.scrollTop,
      scrollHeight:viewport?.scrollHeight,viewportY:viewport?.getBoundingClientRect().y,
      errors:window.probeErrors, events:JSON.parse(window.couiTreeEvents())};
  });
  assert.deepEqual(state.errors, [], name+' runtime errors');
  state.name=name;
  checks.push(state);
  return state;
}
function geometry(state, spacing) {
  for(const row of state.rows) assert.equal(row.height,28,state.name+' row height');
  for(let i=1;i<state.rows.length;i++) assert.equal(state.rows[i].y-state.rows[i-1].y,28+spacing,state.name+' row pitch');
}
await page.goto(globalThis.treeProbeUrl ?? 'http://127.0.0.1:18764/');
await page.waitForFunction(()=>typeof window.couiTreeEvents==='function' && document.querySelector('[role=treeitem]'));
let state = await record('hidden roots / initial 8px'); geometry(state,8);
assert.equal(state.rows[0].id,'tree-node.folder');assert.equal(state.rows[0].level,'1');assert.equal(state.rows[1].level,'2');
assert.equal(state.scrollHeight,202*36-8);
await page.focus('loc=css:[role="treeitem"][tabindex="0"]');
await page.keyboard.press('End');await page.waitForFunction(()=>document.activeElement?.id==='tree-node.file-199');
state=await record('End mounts and focuses last virtual row');geometry(state,8);assert.equal(state.rows.at(-1).id,'tree-node.file-199');
await page.keyboard.press('Home');await page.waitForFunction(()=>document.activeElement?.id==='tree-node.folder');
await page.keyboard.press('ArrowRight');await page.waitForFunction(()=>document.activeElement?.id==='tree-node.nested');
await page.keyboard.press('ArrowLeft');await page.waitForFunction(()=>document.activeElement?.id==='tree-node.folder');
await page.keyboard.press('ArrowLeft');await page.waitForFunction(()=>document.querySelector('[role=treeitem]').getAttribute('aria-expanded')==='false');
state=await record('Left closes promoted folder');geometry(state,8);assert.equal(state.rows[1].id,'tree-node.file-0');
await page.keyboard.press('ArrowRight');await page.waitForFunction(()=>document.querySelector('[role=treeitem]').getAttribute('aria-expanded')==='true');
for(const spacing of [0,4,8]) {
  await page.evaluate(spacing=>window.couiTreeConfigure(JSON.stringify({rowSpacing:spacing})),spacing);
  await page.waitForFunction(spacing=>{const rows=[...document.querySelectorAll('[role=treeitem]')];return rows.length>1 && rows[1].getBoundingClientRect().y-rows[0].getBoundingClientRect().y===28+spacing;},spacing);
  state=await record('dynamic spacing '+spacing);geometry(state,spacing);
  assert.equal(state.scrollHeight,202*(28+spacing)-spacing);
  await page.focus('loc=css:[role="treeitem"][tabindex="0"]');await page.keyboard.press('End');
  await page.waitForFunction(()=>document.activeElement?.id==='tree-node.file-199');
  state=await record('End after spacing '+spacing);geometry(state,spacing);
  await page.keyboard.press('Home');await page.waitForFunction(()=>document.activeElement?.id==='tree-node.folder');
}
await page.evaluate(()=>document.documentElement.style.setProperty('--coui-space-8','12px'));
await page.mouse.move(200,120);await page.mouse.wheel(0,1600,{label:'check remapped tree spacing'});
await page.waitForFunction(()=>document.getElementById('probe-tree-viewport').scrollTop>1000);
state=await record('CSS spacing variable remapped to 12px');geometry(state,12);
for(const row of state.rows){const index=row.id.startsWith('tree-node.file-')?Number(row.id.slice('tree-node.file-'.length))+2:row.id==='tree-node.folder'?0:1;
assert.equal(row.y,state.viewportY+index*40-state.scroll,'remapped spacer position');}
assert.equal(state.scrollHeight,202*40-12);
await page.focus('loc=css:[role="treeitem"][tabindex="0"]');await page.keyboard.press('End');
await page.waitForFunction(()=>document.activeElement?.id==='tree-node.file-199');
state=await record('End after CSS variable remap');geometry(state,12);
await page.keyboard.press('Home');await page.waitForFunction(()=>document.activeElement?.id==='tree-node.folder');
await page.evaluate(()=>{document.documentElement.style.removeProperty('--coui-space-8');window.couiTreeConfigure(JSON.stringify({virtual:false}));});
await page.waitForFunction(()=>document.querySelectorAll('[role=treeitem]').length===202);
state=await record('nonvirtual hidden roots');geometry(state,8);
await page.evaluate(()=>window.couiTreeConfigure(JSON.stringify({showRoots:true})));
await page.waitForFunction(()=>document.querySelector('[role=treeitem]').id==='tree-node.root');
state=await record('dynamic showRoots true');geometry(state,8);assert.equal(state.rows.length,203);assert.equal(state.rows[1].level,'2');
await page.evaluate(()=>window.couiTreeConfigure(JSON.stringify({showRoots:false,virtual:true})));
await page.waitForFunction(()=>document.querySelector('[role=treeitem]').id==='tree-node.folder' && document.getElementById('probe-tree-viewport'));
state=await record('dynamic showRoots false / virtual restored');geometry(state,8);assert.equal(state.rows.filter(r=>r.tab==='0').length,1);
await page.click('loc=css:[id="tree-node.file-0"]',{label:'select promoted root file'});
await page.waitForFunction(()=>document.getElementById('tree-node.file-0')?.getAttribute('aria-selected')==='true');
await page.keyboard.press('F2');await page.waitForSelector('loc=css:input');
await page.fill('loc=css:input','renamed.dart');await page.keyboard.press('Enter');
await page.waitForFunction(()=>JSON.parse(window.couiTreeEvents()).some(e=>e.kind==='rename'));
state=await record('F2 rename on promoted leaf');assert.deepEqual(state.events.find(e=>e.kind==='rename'),{kind:'rename',node:'file-0',label:'renamed.dart'});
await page.evaluate(()=>{const target=document.getElementById('tree-node.file-0').closest('[data-tree-file-drop-over]');const dataTransfer=new DataTransfer();dataTransfer.items.add(new File(['probe'],'probe.txt',{type:'text/plain'}));target.dispatchEvent(new DragEvent('drop',{bubbles:true,cancelable:true,dataTransfer}));});
await page.waitForFunction(()=>JSON.parse(window.couiTreeEvents()).some(e=>e.kind==='files'));
state=await record('external file drop retains hidden structural root');assert.equal(state.events.find(e=>e.kind==='files').destination,'root');
const screenshot=await page.screenshot({path:output+'/presentation.png'});
await fs.writeFile(output+'/results.json',JSON.stringify({browser:'ego lite',checks,screenshot},null,2));
console.log({pass:true,checks:checks.map(c=>c.name),screenshot});

if (!globalThis.treeProbeKeepSpace) await task.finish({keep:[]});
