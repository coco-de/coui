import 'dart:convert';
import 'dart:io';

import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/computed_style_probe.dart';
import '../../src/web/docs_size_binding.dart';
import '../../src/web/web_capture_backend.dart';

typedef _Actual = ({
  MatrixEntry entry,
  Map<String, Object?> receipt,
  Map<String, Object?> capture,
});
final _cache = <String, Future<_Actual>>{};
Map<String, Object?> _tree(dom.Node n) => n is dom.Element
    ? {
        'nodeType': 1,
        'namespaceURI': n.namespaceUri,
        'localName': n.localName,
        'attributes': {
          for (final a in n.attributes.entries) a.key.toString(): a.value,
        },
        'childNodes': n.nodes.map(_tree).toList(),
      }
    : {
        'nodeType': n.nodeType,
        'data': n is dom.Text
            ? n.data
            : n is dom.Comment
            ? n.data
            : '',
      };
Future<_Actual> _actual(String theme) => _cache.putIfAbsent(theme, () async {
  const component = 'button';
  final scene = readDocsScenes(
    component,
  ).singleWhere((s) => s.tag == 'SizeSpec');
  final key = '$component-${scene.reference}-$theme-defaultStyle';
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': scene.reference,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't1',
    'probes': captureProbes(
      key: key,
      component: component,
      variant: scene.reference,
      flutterClassName: 'FlutterDocsSizeSpec',
      docsScene: scene,
    ).map((p) => p.toJson()).toList(),
  });
  final receipts = <Map<String, Object?>>[];
  final body = await renderCaptureBodyHtml(
    entry,
    onCurrentBoxSource: receipts.add,
  );
  expect(receipts, hasLength(1));
  expect(receipts.single.containsKey('error'), false, reason: '$receipts');
  final capture = html
      .parseFragment(body)
      .querySelectorAll('[data-parity-key]')
      .single;
  return (entry: entry, receipt: receipts.single, capture: _tree(capture));
});

// Reuses the existing Stepper Node DOM/CSS fixture verbatim. It is a test
// environment, not browser geometry or a source of expected product values.
const _kRuntime = r'''

const from=(data,parent=null)=>{
 if(data.nodeType!==1){const node={nodeType:data.nodeType,data:data.data,nodeValue:data.data,parentNode:parent,parentElement:parent,isConnected:true};Object.defineProperty(node,'textContent',{get:()=>node.data,set:value=>{node.data=value;node.nodeValue=value;}});return node;}
 const attrs={...data.attributes};
 const node={nodeType:1,namespaceURI:data.namespaceURI,localName:data.localName,
  tagName:data.localName.toUpperCase(),parentNode:parent,parentElement:parent,isConnected:true,style:{},
  getAttribute:name=>Object.hasOwn(attrs,name)?attrs[name]:null,
  hasAttribute:name=>Object.hasOwn(attrs,name),
  setAttribute:(name,value)=>{attrs[name]=value;},removeAttribute:name=>{delete attrs[name];}};
 node.childNodes=data.childNodes.map(child=>from(child,node));
 node.cloneNode=()=>from(data,node.parentElement);
 Object.defineProperty(node,'children',{get:()=>node.childNodes.filter(child=>child.nodeType===1)});
 Object.defineProperty(node,'attributes',{get:()=>Object.entries(attrs).map(([name,value])=>({name,value}))});
 Object.defineProperty(node,'classList',{get:()=>{
  const names=(attrs.class||'').split(/[\t\n\f\r ]+/).filter(Boolean);
  names.contains=name=>names.includes(name);return names;
 }});
 node.querySelectorAll=selector=>selector==='input, textarea'?[]:
  node.children.flatMap(child=>[child,...child.querySelectorAll('*')]);
 node.contains=other=>node===other||node.children.some(child=>child.contains(other));
 node.getBoundingClientRect=()=>({x:0,y:0,left:0,top:0,right:137,bottom:59,width:137,height:59});
 return node;
};
global.location={href:'file:///owned/stepper-horizontal-source.html'};
global.window={__coui_parity_color_keys__:new Set()};
global.Node={TEXT_NODE:3};
global.NodeFilter={SHOW_TEXT:4};
let cssReads=0;
global.getComputedStyle=node=>{cssReads++;return {
 display:'block',visibility:'visible',position:'static',overflowX:'visible',overflowY:'visible',clip:'auto',opacity:'1',
 paddingTop:node===padding?'2px':'901px',paddingRight:node===padding?'3px':'902px',
 paddingBottom:node===padding?'5px':'903px',paddingLeft:node===padding?'7px':'904px',
 fontFamily:'unit-font',fontWeight:'400',fontSize:'14px',lineHeight:'20px',letterSpacing:'0px',color:'rgb(1, 2, 3)',
 backgroundColor:'rgba(0, 0, 0, 0)',borderTopColor:'rgb(1, 2, 3)',
 borderTopWidth:'0px',borderRightWidth:'0px',borderBottomWidth:'0px',borderLeftWidth:'0px',
 borderTopLeftRadius:'0px',borderTopRightRadius:'0px',borderBottomRightRadius:'0px',borderBottomLeftRadius:'0px',
 boxShadow:'none',outlineWidth:'0px',outlineStyle:'none',outlineColor:'rgb(1, 2, 3)',outlineOffset:'0px'
};};

''';

// Shared test-only Node DOM/CSS environment; the runtime literal is unchanged.
String get docsSourceTestRuntime => _kRuntime;

Future<Map<String, Object?>> _sample(
  _Actual actual, {
  bool combined = true,
  bool legacyOnly = false,
  String mutation = '',
  String phaseMutation = '',
  bool ownPhase = false,
}) async {
  final selector = actual.entry.probes.single.webSelector;
  final receipt = {
    ...actual.receipt,
    'harnessURL': 'file:///owned/stepper-horizontal-source.html',
  };
  final box = [
    '(request)=>{ownPhase=true;return (',
    boxPaddingObservationScript,
    ')(request);}',
  ].join();
  final script = legacyOnly
      ? '(request)=>($computedStyleProbeScript)(request.selector)'
      : combined
      ? sourceValidatedComputedStyleAndBoxScript(box)
      : boxPaddingObservationScript;
  final program =
      '''
$_kRuntime
const capture=from(${jsonEncode(actual.capture)}),root=capture.children[0].children[0].children[0],
 padding=root.children[0],table=root.children[1],figure=padding.children[0],
 previewInterior=figure.children[0],caption=figure.children.at(-1),code=caption.children[0];
const selector=${jsonEncode(selector)};
global.document={querySelector:s=>s===selector?root:null,
 querySelectorAll:s=>s===selector?[root]:[],
 createTreeWalker:n=>{const q=[];const visit=x=>{for(const c of x.childNodes){if(c.nodeType===3)q.push(c);else if(c.nodeType===1)visit(c);}};visit(n);return {nextNode:()=>q.shift()||null};}};
const request={requested:true,selector,layoutSelector:selector,
 source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
 currentSsrSource:${jsonEncode(receipt)},requiredCurrentSsrKind:'canonical-ssr-docs-size-preview-v1'};
let ownPhase=false,changed=false;
const originalCss=getComputedStyle;
global.getComputedStyle=n=>{const value=originalCss(n);if(!changed&&ownPhase===${ownPhase ? 'true' : 'false'}){changed=true;$phaseMutation}return value;};
$mutation
let observed,error;
try{observed=JSON.parse(($script)(request));}catch(e){error=String(e);}
console.log(JSON.stringify({observed,error,cssReads,changed,
 originalResultRetained:root.isConnected&&capture.isConnected&&root.children[0]===padding&&root.children[1]===table}));
''';
  final directory = await Directory.systemTemp.createTemp('docs-size-node-');
  try {
    final file = File('${directory.path}/probe.cjs');
    await file.writeAsString(program);
    final result = await Process.run(
      Platform.environment['PARITY_NODE'] ?? 'node',
      [file.path],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
  } finally {
    await directory.delete(recursive: true);
  }
}

void main() {
  for (final control in [
    'preview padding',
    'caption id',
    'result padding',
    'figure id',
    'content padding',
    'host extra',
    'code id',
  ]) {
    test('Size joint raw+DOM $control rejects before CSS', () async {
      final actual = await _actual('light');
      final health = await _sample(actual);
      expect(health['error'], isNull);
      final observed = (health['observed']! as Map).cast<String, Object?>();
      expect((observed['box']! as Map)['status'], 'source-complete');
      final role = control.split(' ').first;
      final field = switch (control.split(' ').last) {
        'padding' => 'style',
        'extra' => 'data-forged',
        _ => 'id',
      };
      final mutation = [
        'const ownedRole=(g,r)=>g.role===r?g:',
        "g.kind==='owned'?g.children.map(c=>ownedRole(c,r))",
        '.find(Boolean):null;',
        'const role=${jsonEncode(role)},field=${jsonEncode(field)};',
        "const value=field==='style'?'padding: 99px':'forged-source';",
        'ownedRole(request.currentSsrSource.currentRaw.normalTree,role)',
        '.attributes[field]=value;',
        'const actualByRole={preview:padding,caption,result:root,figure,code,',
        'content:root.parentElement,host:root.parentElement.parentElement};',
        'actualByRole[role].setAttribute(field,value);',
      ].join();
      final changed = await _sample(actual, mutation: mutation);
      expect(
        changed['error'],
        isNotNull,
        reason: 'SIZE_JOINT_OWN_ATTR_SOURCE_RED',
      );
      expect(changed['cssReads'], 0);
    });
  }
  for (final theme in ['light', 'dark']) {
    test(
      'Size actual normal $theme selects preview and preserves legacy payload',
      () async {
        final actual = await _actual(theme);
        final one = await _sample(actual, combined: false);
        expect(one['error'], isNull);
        expect((one['observed']! as Map)['status'], 'source-complete');
        expect((one['observed']! as Map)['value'], [2, 3, 5, 7]);
        expect((one['observed']! as Map)['ownerIsLayoutRoot'], false);
        final legacy = await _sample(actual, legacyOnly: true);
        final both = await _sample(actual);
        expect(both['error'], isNull);
        expect((both['observed']! as Map)['legacy'], legacy['observed']);
        expect(((both['observed']! as Map)['box']! as Map)['value'], [
          2,
          3,
          5,
          7,
        ]);
      },
    );
  }
  final before = <String, String>{
    'missing receipt': 'request.currentSsrSource=null;',
    'foreign required kind': 'request.requiredCurrentSsrKind="foreign";',
    'partial source': 'delete request.source.nativeAdapterId;',
    'boolean source version': 'request.source.schemaVersion=true;',
    'foreign source adapter': 'request.source.webAdapterId="foreign";',
    'foreign receipt key': 'request.currentSsrSource.entryKey="foreign";',
    'foreign scene':
        'request.currentSsrSource.currentRaw.sceneReference="docs-v2-foreign";',
    'foreign component':
        'request.currentSsrSource.currentRaw.component="foreign";',
    'head included in body claim': [
      'request.currentSsrSource.currentRaw.headProjection.h',
      'eadOutsideBody=false;',
    ].join(),
    'head body branch order': [
      'request.currentSsrSource.currentRaw.headProjection.o',
      'rderedChildren.reverse();',
    ].join(),
    'padding data-alias claim': [
      'request.currentSsrSource.currentRaw.dataAliasesArePa',
      'ddingParameters=true;',
    ].join(),
    'table inside quantity claim':
        'request.currentSsrSource.currentRaw.tableIsOutsideQuantity=false;',
    'foreign interior authority': [
      'request.currentSsrSource.currentRaw.previewInteriors',
      'AreSourceAuthority=true;',
    ].join(),
    'extra request tuple field': 'request.source.extra=true;',
    'owned attribute': 'root.setAttribute("data-tamper","x");',
    'owned caption text':
        'code.childNodes.find(n=>n.nodeType===3).textContent="changed";',
    'extra ASCII formatter':
        'root.childNodes.unshift(from({nodeType:3,data:" "},root));',
    'extra NBSP': [
      'root.childNodes.unshift(from({nodeType:3,data:String',
      '.fromCharCode(160)},root));',
    ].join(),
    'extra comment':
        'root.childNodes.unshift(from({nodeType:8,data:"x"},root));',
    'swap preview and table': [
      'const a=root.childNodes.indexOf(padding),b=root.chil',
      'dNodes.indexOf(table);[root.childNodes[a],root.child',
      'Nodes[b]]=[root.childNodes[b],root.childNodes[a]];',
    ].join(),
    'missing figure':
        'padding.childNodes=padding.childNodes.filter(n=>n!==figure);',
    'removed generated preview':
        'figure.childNodes=figure.childNodes.filter(n=>n!==previewInterior);',
    'caption-only source graph': [
      'const find=(n,r)=>n.role===r?n:n.children?.map(x=>fi',
      'nd(x,r)).find(Boolean);const f=find(request.currentS',
      'srSource.currentRaw.normalTree,"figure");f.children=',
      'f.children.filter(n=>n.kind!=="generated-opaque");',
    ].join(),
    'empty opaque frontier': [
      'const find=(n,r)=>n.role===r?n:n.children?.map(x=>fi',
      'nd(x,r)).find(Boolean);find(request.currentSsrSource',
      '.currentRaw.normalTree,"preview-interior").nodes=[];',
    ].join(),
    'duplicate opaque frontier': [
      'const find=(n,r)=>n.role===r?n:n.children?.map(x=>fi',
      'nd(x,r)).find(Boolean);const n=find(request.currentS',
      'srSource.currentRaw.normalTree,"preview-interior").n',
      'odes;n.push({...n[0]});',
    ].join(),
    'duplicate selector': 'document.querySelectorAll=()=>[root,root];',
  };
  for (final e in before.entries) {
    test('Size initial ${e.key} rejects before CSS', () async {
      final result = await _sample(await _actual('light'), mutation: e.value);
      expect(result['error'], isNotNull);
      expect(result['cssReads'], 0);
    });
  }
  final during = <String, String>{
    'receipt container clone': [
      'request.currentSsrSource=JSON.parse(JSON.stringify(r',
      'equest.currentSsrSource));',
    ].join(),
    'nested graph clone': [
      'request.currentSsrSource.currentRaw.normalTree=JSON.',
      'parse(JSON.stringify(request.currentSsrSource.curren',
      'tRaw.normalTree));',
    ].join(),
    'nested raw clone': [
      'request.currentSsrSource.currentRaw={...request.curr',
      'entSsrSource.currentRaw};',
    ].join(),
    'source clone': 'request.source={...request.source};',
    'selector same result': [
      'request.selector="same-result";document.querySelecto',
      'rAll=s=>[selector,"same-result"].includes(s)?[root]:',
      '[];',
    ].join(),
    'owned attribute': 'root.setAttribute("data-tamper","x");',
    'owned text':
        'code.childNodes.find(n=>n.nodeType===3).textContent="changed";',
    'owned formatter identity': [
      'const i=root.childNodes.findIndex(n=>n.nodeType===3)',
      ';root.childNodes[i]=from({nodeType:3,data:root.child',
      'Nodes[i].data},root);',
    ].join(),
    'result same-shape replacement':
        'document.querySelectorAll=()=>[root.cloneNode(true)];',
    'preview same-shape replacement': [
      'const i=root.childNodes.indexOf(padding);root.childN',
      'odes[i]=padding.cloneNode(true);',
    ].join(),
  };
  for (final own in [false, true]) {
    for (final e in during.entries) {
      test(
        'Size ${own ? 'own' : 'legacy'} CSS ${e.key} rejects retained source',
        () async {
          final result = await _sample(
            await _actual('light'),
            ownPhase: own,
            phaseMutation: e.value,
          );
          expect(result['changed'], true);
          expect(result['cssReads'], greaterThan(0));
          expect(result['error'], isNotNull);
        },
      );
    }
    test(
      [
        'Size ${own ? 'own' : 'legacy'} CSS keeps preview and excluded ',
        'table interiors opaque',
      ].join(),
      () async {
        final result = await _sample(
          await _actual('light'),
          ownPhase: own,
          phaseMutation: 'previewInterior.childNodes=[];table.childNodes=[];',
        );
        expect(result['changed'], true);
        expect(result['error'], isNull);
        expect(((result['observed']! as Map)['box']! as Map)['value'], [
          2,
          3,
          5,
          7,
        ]);
      },
    );
  }
  test(
    'Size unrequested binding reads no source receipt body or DOM',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'docs-size-unrequested-',
      );
      try {
        final file = File('${directory.path}/probe.cjs');
        await file.writeAsString('''
const request={requested:false};
for(const k of ['source','currentSsrSource','selector','layoutSelector','requiredCurrentSsrKind'])Object.defineProperty(request,k,{get(){throw new Error('unrequested read '+k);}});
const result=($docsSizeRequestBindingScript)(request);
if(JSON.stringify(result)!==JSON.stringify({applied:false}))throw new Error('wrong unrequested result');
''');
        final result = await Process.run(
          Platform.environment['PARITY_NODE'] ?? 'node',
          [file.path],
        );
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
