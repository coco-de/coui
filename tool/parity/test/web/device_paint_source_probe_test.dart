import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/computed_style_probe.dart';
import '../../src/web/device_paint_source_probe.dart';

// These are protocol/ordering controls. The companion real SSR suite proves
// that the path and literal identity originate from the actual public typed
// OutlinedContainer, rather than assigning that authority to this surrogate.
Future<void> _node(String action) async {
  final encodedSource = jsonEncode(
    BoxObservationSourceSpec.mockupDeviceBodyFrame.toJson(),
  );
  final script =
      r'''
const assert = require('node:assert/strict');
function element(attrs={},children=[]) {
  const node = {nodeType:1,namespaceURI:'http://www.w3.org/1999/xhtml',localName:'div',
    tagName:'DIV',parentElement:null,isConnected:true,children,childNodes:children,
    getAttribute:name=>Object.hasOwn(attrs,name)?attrs[name]:null,
    hasAttribute:name=>Object.hasOwn(attrs,name),
    querySelectorAll:selector=>selector==='input, textarea'?[]:
      children.flatMap(child=>[child,...child.querySelectorAll('*')]),
    contains:other=>node===other||children.some(child=>child.contains(other)),
    getBoundingClientRect:()=>({x:0,y:0,width:123,height:75}),
    setAttribute:(name,value)=>{attrs[name]=value;}};
  Object.defineProperty(node,'attributes',{get:()=>Object.entries(attrs).map(([name,value])=>({name,value}))});
  Object.defineProperty(node,'classList',{get:()=>{
    const names=(attrs.class||'').split(/[\t\n\f\r ]+/).filter(Boolean);
    names.contains=name=>names.includes(name);return names;
  }});
  children.forEach(child=>child.parentElement=node);
  return node;
}
const hardware=element({class:'absolute'}),body=element({class:'absolute source-body',style:'literal-current-source'});
const supplied=element(),bezel=element({class:'absolute'},[supplied]);
const layout=element({class:'relative inline-flex'},[hardware,body,bezel]);
const registry=element({class:'w-full flex justify-center'},[layout]);
const capture=element({'data-parity-key':'device-paint-fixture'},[registry]);
const identity=node=>({namespaceURI:node.namespaceURI,localName:node.localName,
 attributes:Object.fromEntries(node.attributes.map(attribute=>[attribute.name,attribute.value])),
 childNodes:node.childNodes.map(identity)});
const tree=node=>node===supplied?{foreignSlot:0}:{namespaceURI:node.namespaceURI,
 localName:node.localName,role:null,nodeKinds:node.childNodes.map(child=>child.nodeType),children:node.children.map(tree)};
global.location={href:'file:///owned/device-paint.html'};
global.NodeFilter={SHOW_TEXT:4};
global.document={querySelector:()=>layout,querySelectorAll:()=>[layout],
 createTreeWalker:()=>({nextNode:()=>null})};
let cssReads=0;
global.getComputedStyle=node=>{
 cssReads++;
 const painted=node===body||node===hardware||node===bezel;
 return {display:'block',visibility:'visible',position:painted?'absolute':'relative',
  overflowX:'visible',overflowY:'visible',clip:'auto',opacity:node===layout?'0.65':'1',
  backgroundColor:node===body?'rgb(21, 32, 43)':painted?'rgb(91, 82, 73)':'rgba(0, 0, 0, 0)',
  borderTopColor:node===body?'rgb(11, 22, 33)':'rgb(99, 88, 77)',
  borderRightColor:'rgb(12, 23, 34)',borderBottomColor:'rgb(13, 24, 35)',borderLeftColor:'rgb(14, 25, 36)',
  borderTopWidth:painted?'7px':'0px',borderRightWidth:painted?'8px':'0px',
  borderBottomWidth:painted?'9px':'0px',borderLeftWidth:painted?'10px':'0px',
  borderTopLeftRadius:'11px',borderTopRightRadius:'12px',borderBottomRightRadius:'13px',borderBottomLeftRadius:'14px',
  boxShadow:painted?'rgb(1, 2, 3) 4px 5px 6px':'none',
  paddingTop:'101px',paddingRight:'102px',paddingBottom:'103px',paddingLeft:'104px',
  outlineWidth:'105px',outlineStyle:'solid',outlineColor:'rgb(41, 42, 43)',outlineOffset:'106px'};
};
'''
      'const source=$encodedSource;\n'
      '''
const receipt={kind:'canonical-ssr-framed-collection-v1',entryKey:'device-paint-fixture',source:{...source},
 currentRaw:{kind:'current-framed-collection-raw-v1',logicalUnitId:source.logicalUnitId,
  rawSlotCount:1,slotPresence:[true],route:'device',generatedTree:tree(registry),
  bodyPaintSource:{kind:'mockup-device-body-outlined-paint-v1',paintAuthorityId:'public-generated-outlined-body-paint-v1',
   fieldScope:['backgroundColor','borderColor','borderWidthPx','borderRadiusPx','boxShadow'],
   ownerPathFromRegistry:[0,1],ownerIdentity:identity(body)}},
 completeRawSlotCount:1,rawOrderFromPublicProducerLists:true,harnessURL:location.href};
const request={selector:'[data-parity-key] > * > *',layoutSelector:'[data-parity-key] > * > *',
 requested:true,source,currentSsrSource:receipt,requiredCurrentSsrKind:receipt.kind};
'''
      'const resolve=($devicePaintSourceResolverScript);\n'
      'const legacyProbe=($computedStyleProbeScript);\n'
      'const observe=($computedStyleAndBoxObservationScript);\n'
      '$action\nconsole.log(JSON.stringify({passed:true,cssReads}));';
  final directory = await Directory.systemTemp.createTemp('coui-parity-node-');
  try {
    final file = File('${directory.path}/probe.cjs');
    await file.writeAsString(script);
    final result = await Process.run('node', [file.path]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      (jsonDecode((result.stdout as String).trim()) as Map)['passed'],
      isTrue,
    );
  } finally {
    await directory.delete(recursive: true);
  }
}

void main() {
  test('legacy public script ignores a paint-node override', () {
    return _node('''
const value=JSON.parse(legacyProbe(request.selector,body));
assert.equal(value.backgroundColor,'rgba(0, 0, 0, 0)');
assert.equal(value.borderTopWidth,'0px');
assert.equal(value.boxShadow,'none');
''');
  });
  test('source binding selects its recorded body without reading CSS', () {
    return _node('''
for(const node of [capture,registry,layout,hardware,body,bezel,supplied])
 node.getBoundingClientRect=()=>{throw Error('Geometry used to choose paint');};
const bound=resolve(request);
assert.equal(bound.error,undefined);
assert.equal(bound.sourcePaintElement,body);
assert.equal(bound.validateCurrentBinding(),true);
assert.equal(cssReads,0);
''');
  });
  test('paint and layout fields keep their separate owners', () {
    return _node('''
const value=JSON.parse(observe(request));
assert.equal(value.legacy.backgroundColor,'rgb(21, 32, 43)');
assert.equal(value.legacy.borderTopColor,'rgb(11, 22, 33)');
assert.equal(value.legacy.borderLeftWidth,'10px');
assert.equal(value.legacy.borderBottomLeftRadius,'14px');
assert.equal(value.legacy.boxShadow,'rgb(1, 2, 3) 4px 5px 6px');
assert.equal(value.legacy.paddingTop,'0px');
assert.equal(value.legacy.outlineWidth,'0px');
assert.equal(value.legacy.outlineOffset,'0px');
assert.equal(value.legacy.opacity,'0.65');
assert.equal(value.legacy.widthPx,123);
assert.equal(value.legacy.heightPx,75);
assert.equal(value.box.status,'source-complete');
assert.deepEqual(value.box.value,[101,102,103,104]);
''');
  });
  for (final (name, mutation) in <(String, String)>[
    ('missing witness', 'delete receipt.currentRaw.bodyPaintSource;'),
    (
      'wrong paint authority',
      'receipt.currentRaw.bodyPaintSource.paintAuthorityId='
          "'padding-is-not-paint';",
    ),
    (
      'overlapping field scope',
      "receipt.currentRaw.bodyPaintSource.fieldScope.push('paddingPx');",
    ),
    ('wrong current URL', "receipt.harnessURL='file:///other.html';"),
    ('wrong source tuple', "receipt.source.nativeAdapterId='wrong';"),
    ('extra receipt field', 'receipt.extra=true;'),
    (
      'registry as paint',
      'receipt.currentRaw.bodyPaintSource.ownerPathFromRegistry=[];',
    ),
    (
      'layout as paint',
      'receipt.currentRaw.bodyPaintSource.ownerPathFromRegistry=[0];',
    ),
    (
      'different generated child',
      'receipt.currentRaw.bodyPaintSource.ownerPathFromRegistry=[0,0];',
    ),
    (
      'foreign child',
      'receipt.currentRaw.bodyPaintSource.ownerPathFromRegistry=[0,2,0];',
    ),
    ('changed source markup', "body.setAttribute('style','changed-source');"),
    (
      'inserted clone',
      'layout.children.push(element());layout.childNodes=layout.children;',
    ),
  ]) {
    test('$name fails before any credited paint CSS', () {
      return _node('''
$mutation
assert.throws(()=>observe(request));
assert.equal(cssReads,0);
''');
    });
  }
  test('a held current binding rejects replacement after it was bound', () {
    return _node('''
const bound=resolve(request);
assert.equal(bound.validateCurrentBinding(),true);
const replacement=element({class:'absolute source-body',style:'literal-current-source'});
replacement.parentElement=layout;layout.children[1]=replacement;layout.childNodes=layout.children;
body.parentElement=null;body.isConnected=false;
assert.equal(bound.validateCurrentBinding(),false);
assert.equal(cssReads,0);
''');
  });
  for (final (name, mutation) in <(String, String)>[
    ('capture identity', "capture.setAttribute('data-parity-key','other');"),
    ('current URL', "location.href='file:///changed.html';"),
    ('source tuple', "request.source.nativeAdapterId='changed';"),
    ('canonical selector', "request.selector='other';"),
  ]) {
    test('held $name cannot change after source binding', () {
      return _node('''
const bound=resolve(request);
assert.equal(bound.validateCurrentBinding(),true);
$mutation
assert.equal(bound.validateCurrentBinding(),false);
assert.equal(cssReads,0);
''');
    });
  }
  test('source mutation during sampling cannot return credited paint', () {
    return _node('''
const original=getComputedStyle;
global.getComputedStyle=node=>{
 const value=original(node);
 if(node===body)body.setAttribute('style','changed-during-read');
 return value;
};
assert.throws(()=>observe(request),/DEVICE_PAINT_SOURCE_STALE/);
assert.ok(cssReads>0);
''');
  });
  test('box sampling revalidates before either result returns', () {
    return _node('''
let boxPaddingRead=false;
const original=getComputedStyle;
global.getComputedStyle=node=>{
 const value=original(node);
 if(node===layout)Object.defineProperty(value,'paddingTop',{get(){
  boxPaddingRead=true;body.setAttribute('style','changed-during-box');return '101px';
 }});
 return value;
};
assert.throws(()=>observe(request),/DEVICE_PAINT_SOURCE_STALE/);
assert.equal(boxPaddingRead,true);
''');
  });
  test(
    'generic all-absolute ambiguity keeps the original absence behavior',
    () {
      return _node('''
request.source=null;request.requested=false;request.requiredCurrentSsrKind=null;request.currentSsrSource=null;
const value=JSON.parse(observe(request));
assert.equal(value.legacy.backgroundColor,'rgba(0, 0, 0, 0)');
assert.equal(value.legacy.borderTopWidth,'0px');
assert.equal(value.legacy.boxShadow,'none');
''');
    },
  );
  test('a generic painted root keeps its original padding and outline', () {
    return _node('''
request.source=null;request.requested=false;request.requiredCurrentSsrKind=null;request.currentSsrSource=null;
const original=getComputedStyle;
global.getComputedStyle=node=>node===layout?
 {...original(node),backgroundColor:'rgb(51, 52, 53)'}:original(node);
const value=JSON.parse(observe(request));
assert.equal(value.legacy.backgroundColor,'rgb(51, 52, 53)');
assert.equal(value.legacy.paddingTop,'101px');
assert.equal(value.legacy.outlineWidth,'105px');
assert.equal(value.legacy.outlineOffset,'106px');
''');
  });
}
