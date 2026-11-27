import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/web_capture_backend.dart';

typedef _Actual = ({
  MatrixEntry entry,
  Map<String, Object?> receipt,
  Map<String, Object?> capture,
});
final _cache = <String, Future<_Actual>>{};
Map<String, Object?> _tree(dom.Node node) => node is dom.Element
    ? {
        'nodeType': node.nodeType,
        'namespaceURI': node.namespaceUri,
        'localName': node.localName,
        'attributes': {
          for (final a in node.attributes.entries) a.key.toString(): a.value,
        },
        'childNodes': node.nodes.map(_tree).toList(),
      }
    : {
        'nodeType': node.nodeType,
        'data': node is dom.Text
            ? node.data
            : node is dom.Comment
            ? node.data
            : '',
      };
Future<_Actual> _actual(String component, String variant, String theme) =>
    _cache.putIfAbsent('$component/$variant/$theme', () async {
      final key = '$component-$variant-$theme-defaultStyle';
      final entry = MatrixEntry.fromJson({
        'component': component,
        'variant': variant,
        'theme': theme,
        'surfaceStyle': 'defaultStyle',
        'tier': 't2',
        'probes': captureProbes(
          key: key,
          component: component,
          variant: variant,
          flutterClassName: component == 'card' ? 'Card' : 'Accordion',
        ).map((p) => p.toJson()).toList(),
      });
      final receipts = <Map<String, Object?>>[];
      final body = await renderCaptureBodyHtml(
        entry,
        onCurrentBoxSource: receipts.add,
      );
      expect(receipts, hasLength(1));
      expect(
        receipts.single.containsKey('error'),
        false,
        reason: '${receipts.single}',
      );
      final capture = html
          .parseFragment(body)
          .querySelectorAll('[data-parity-key]')
          .single;
      return (entry: entry, receipt: receipts.single, capture: _tree(capture));
    });
// Exact previously qualified Bottom DOM/CSS transport; new family uses the
// actual completed normal SSR body, not a hand-authored expected DOM.
const _kRuntime = r'''

const from=(data,parent=null)=>{
 if(data.nodeType!==1)return {nodeType:data.nodeType,data:data.data,nodeValue:data.data,parentNode:parent,parentElement:parent,isConnected:true};
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
global.location={href:'file:///owned/bottom-action-bar-source.html'};
global.window={__coui_parity_color_keys__:new Set()};
global.Node={TEXT_NODE:3};
global.NodeFilter={SHOW_TEXT:4};
let cssReads=0;
global.getComputedStyle=node=>{cssReads++;return {
 display:'block',visibility:'visible',position:'static',overflowX:'visible',overflowY:'visible',clip:'auto',opacity:'1',
 paddingTop:node===root?'2px':'901px',paddingRight:node===root?'3px':'902px',
 paddingBottom:node===root?'5px':'903px',paddingLeft:node===root?'7px':'904px',
 fontFamily:'unit-font',fontWeight:'400',fontSize:'14px',lineHeight:'20px',letterSpacing:'0px',color:'rgb(1, 2, 3)',
 backgroundColor:'rgba(0, 0, 0, 0)',borderTopColor:'rgb(1, 2, 3)',
 borderTopWidth:'0px',borderRightWidth:'0px',borderBottomWidth:'0px',borderLeftWidth:'0px',
 borderTopLeftRadius:'0px',borderTopRightRadius:'0px',borderBottomRightRadius:'0px',borderBottomLeftRadius:'0px',
 boxShadow:'none',outlineWidth:'0px',outlineStyle:'none',outlineColor:'rgb(1, 2, 3)',outlineOffset:'0px'
};};

''';
Future<Map<String, Object?>> _sample(
  _Actual actual, {
  bool combined = false,
  String mutation = '',
}) async {
  final selector = actual.entry.probes.single.webSelector;
  final receipt = {
    ...actual.receipt,
    'harnessURL': 'file:///owned/bottom-action-bar-source.html',
  };
  final program =
      '''
$_kRuntime
const capture=from(${jsonEncode(actual.capture)}),root=capture.children[0];
const selector=${jsonEncode(selector)};
global.document={querySelector:s=>s===selector?root:null,querySelectorAll:s=>s===selector?[root]:[],
 createTreeWalker:node=>{const q=[];const visit=n=>{for(const c of n.childNodes){if(c.nodeType===3)q.push(c);else if(c.nodeType===1)visit(c);}};visit(node);return{nextNode:()=>q.shift()||null};}};
const request={requested:true,selector,layoutSelector:selector,source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
 currentSsrSource:${jsonEncode(receipt)},requiredCurrentSsrKind:'canonical-ssr-surface-frame-v1'};
const firstOpaque=(node,tree)=>{for(let i=0;i<tree.children.length;i++){const t=tree.children[i],n=node.childNodes[i];if(Object.hasOwn(t,'opaqueNode'))return n;if(t.nodeType===1){const f=firstOpaque(n,t);if(f)return f;}}return null;};
$mutation
let observed,error;try{observed=JSON.parse((${combined ? computedStyleAndBoxObservationScript : boxPaddingObservationScript})(request));}catch(e){error=String(e);}
console.log(JSON.stringify({observed,error,cssReads,heldOriginalRootAttached:root.isConnected&&root.parentElement===capture&&capture.children[0]===root}));
''';
  final dir = await Directory.systemTemp.createTemp('coui-parity-node-');
  try {
    final file = File('${dir.path}/probe.cjs');
    await file.writeAsString(program);
    final result = await Process.run(
      Platform.environment['PARITY_NODE'] ?? 'node',
      [file.path],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
  } finally {
    await dir.delete(recursive: true);
  }
}

void main() {
  for (final recipe in [
    ('card', 'default'),
    ('card', 'filled'),
    ('card', 'elevated'),
    ('accordion', 'default'),
  ]) {
    for (final theme in ['light', 'dark']) {
      test('$recipe/$theme actual completed surface frame dispatch', () async {
        final actual = await _actual(recipe.$1, recipe.$2, theme);
        final one = await _sample(actual);
        expect(one['error'], isNull);
        final box = one['observed']! as Map;
        expect(box['status'], 'source-complete');
        expect(box['value'], [2, 3, 5, 7]);
        expect(box['ownerIsLayoutRoot'], true);
        final both = await _sample(actual, combined: true);
        expect(both['error'], isNull);
        expect(((both['observed']! as Map)['box']! as Map)['value'], [
          2,
          3,
          5,
          7,
        ]);
      });
    }
  }
  final malformed = {
    'drop raw nullable or item declaration':
        'request.currentSsrSource.currentRaw.rawDeclarations.pop();',
    'extra declaration': [
      'request.currentSsrSource.currentRaw.rawDeclarations.',
      'push(request.currentSsrSource.currentRaw.rawDeclarat',
      'ions[0]);',
    ].join(),
    'wrong alias': [
      'request.currentSsrSource.currentRaw.rawDeclarations[',
      '0].sourceAliasOf=0;',
    ].join(),
    'lost raw-data distinction': [
      'request.currentSsrSource.currentRaw.rawDeclarationMo',
      'untAuthority=true;',
    ].join(),
    'aggregate quantity claim': [
      'request.currentSsrSource.currentRaw.distributedSlotA',
      'ndItemInsetsIncluded=true;',
    ].join(),
    'wrong opaque correspondence': [
      'request.currentSsrSource.currentRaw.opaqueFrontiers[',
      "0].authority='private-item-field';",
    ].join(),
    'anonymous ASCII text added':
        "capture.childNodes.unshift(from({nodeType:3,data:' '},capture));",
    'extra owned child': [
      "root.childNodes.push(from({nodeType:1,namespaceURI:'",
      "http://www.w3.org/1999/xhtml',localName:'div',attrib",
      'utes:{},childNodes:[]},root));',
    ].join(),
    'selector duplicate with original attached':
        'document.querySelectorAll=()=>[root,root.cloneNode()];',
    'selector retarget with original attached':
        'document.querySelectorAll=()=>[root.cloneNode()];',
  };
  for (final component in ['card', 'accordion']) {
    for (final row in malformed.entries) {
      test('$component rejects ${row.key} before CSS', () async {
        final actual = await _actual(component, 'default', 'light');
        final sampled = await _sample(actual, mutation: row.value);
        expect((sampled['observed']! as Map)['status'], 'incomplete');
        expect(sampled['cssReads'], 0);
        expect(sampled['heldOriginalRootAttached'], true);
      });
    }
    test('$component foreign interiors remain opaque', () async {
      final actual = await _actual(component, 'default', 'light');
      final sampled = await _sample(
        actual,
        mutation: [
          'const f=firstOpaque(capture,request.currentSsrSource',
          ".currentRaw.capture);f.setAttribute('data-foreign','",
          "changed');f.childNodes.push(from({nodeType:3,data:'f",
          "oreign interior changed'},f));",
        ].join(),
      );
      expect((sampled['observed']! as Map)['status'], 'source-complete');
      expect((sampled['observed']! as Map)['value'], [2, 3, 5, 7]);
    });
    test(
      '$component rechecks selector during legacy read with original attached',
      () async {
        final actual = await _actual(component, 'default', 'light');
        final sampled = await _sample(
          actual,
          combined: true,
          mutation: [
            'const prior=getComputedStyle;global.getComputedStyle',
            '=n=>{const value=prior(n);document.querySelectorAll=',
            '()=>[root,root.cloneNode()];return value;};',
          ].join(),
        );
        expect(
          sampled['error'],
          contains('SURFACE_FRAME_BINDING_CHANGED_DURING_LEGACY_READ'),
        );
        expect(sampled['heldOriginalRootAttached'], true);
      },
    );
    test(
      '$component rejects mutated owned normal formatter text during CSS',
      () async {
        final actual = await _actual(component, 'default', 'light');
        final sampled = await _sample(
          actual,
          mutation: [
            'const prior=getComputedStyle;global.getComputedStyle',
            '=n=>{const value=prior(n);const ',
            'text=capture.childNodes.find(x=>x.nodeType===3);if(!',
            "text)throw new Error('missing actual normal ",
            "formatter fixture');text.data+=' ';return value;};",
          ].join(),
        );
        expect(sampled['error'], isNull);
        expect((sampled['observed']! as Map)['status'], 'incomplete');
      },
    );
  }
}
