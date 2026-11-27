// Exercises actual normal SSR output and held guards in the Node harness.
import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/computed_style_probe.dart';
import '../../src/web/web_capture_backend.dart';

typedef _Actual = ({
  MatrixEntry entry,
  Map<String, Object?> receipt,
  Map<String, Object?> capture,
});
const _kRecipes = <(String, String), (String, int)>{
  ('drag', 'default'): ('DragScope', 2),
  ('drag', 'board'): ('DragScope', 2),
  ('drag', 'overlay'): ('DragScope', 2),
  ('subfocus', 'default'): ('SubfocusScope', 3),
};
final _cache = <String, Future<_Actual>>{};
Map<String, Object?> _tree(dom.Node n) => n is dom.Element
    ? {
        'nodeType': n.nodeType,
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
Future<_Actual> _actual(String component, String variant, String theme) =>
    _cache.putIfAbsent('$component/$variant/$theme', () async {
      final recipe = _kRecipes[(component, variant)]!;
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
          flutterClassName: recipe.$1,
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
      final parsed = html.parseFragment(body);
      final capture = parsed.querySelectorAll('[data-parity-key]').single;
      final roots = parsed.querySelectorAll(entry.probes.single.webSelector);
      expect(roots, hasLength(1));
      expect(roots.single.parent, same(capture));
      final raw = receipts.single['currentRaw']! as Map;
      expect(raw['rawSlotCount'], recipe.$2 + 1);
      expect(raw['scopeChild'], {
        'seat': 0,
        'present': true,
        'ownedLayout': true,
      });
      expect(raw['layoutSlots'], hasLength(recipe.$2));
      expect(receipts.single['completeRawSlotCount'], recipe.$2 + 1);
      return (entry: entry, receipt: receipts.single, capture: _tree(capture));
    });

// Reused accepted Node DOM/CSS transport. Numeric CSS sentinels discriminate
// original root ownership from supplied foreign padding; they are no browser or
// design values. The ordinary SSR response supplies all actual DOM structure.
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
global.location={href:'file:///owned/scope-allocation-source.html'};
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
  bool legacyOnly = false,
  String mutation = '',
  String? boxScript,
}) async {
  final selector = actual.entry.probes.single.webSelector;
  final receipt = {
    ...actual.receipt,
    'harnessURL': 'file:///owned/scope-allocation-source.html',
  };
  final program =
      '''
$_kRuntime
const capture=from(${jsonEncode(actual.capture)}),root=capture.children[0];
const selector=${jsonEncode(selector)};
global.document={querySelector:sel=>sel===selector?root:null,
 querySelectorAll:sel=>sel===selector?[root]:[],
 createTreeWalker:node=>{const queue=[];const visit=n=>{for(const c of n.childNodes){if(c.nodeType===3)queue.push(c);else if(c.nodeType===1)visit(c);}};visit(node);return {nextNode:()=>queue.shift()||null};}};
const request={requested:true,selector,layoutSelector:selector,
 source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
 currentSsrSource:${jsonEncode(receipt)},requiredCurrentSsrKind:'canonical-ssr-scope-allocation-v1'};
$mutation
let observed,error;
try{observed=JSON.parse((${legacyOnly
          ? '(request) => ($computedStyleProbeScript)(request.selector)'
          : combined
          ? boxScript == null
                ? computedStyleAndBoxObservationScript
                : sourceValidatedComputedStyleAndBoxScript(boxScript)
          : boxPaddingObservationScript})(request));}
catch(e){error=String(e);}
console.log(JSON.stringify({observed,error,cssReads,
 heldOriginalRootAttached:root.isConnected&&capture.isConnected&&root.parentElement===capture&&capture.children[0]===root}));
''';
  final directory = await Directory.systemTemp.createTemp('coui-parity-node-');
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
  for (final recipe in _kRecipes.keys) {
    for (final theme in ['light', 'dark']) {
      test(
        'actual scope original SSR $recipe/$theme accepts single and combined',
        () async {
          final actual = await _actual(recipe.$1, recipe.$2, theme);
          final one = await _sample(actual);
          expect(one['error'], isNull);
          expect((one['observed']! as Map)['status'], 'source-complete');
          expect((one['observed']! as Map)['value'], [2, 3, 5, 7]);
          final legacy = await _sample(actual, legacyOnly: true);
          final combined = await _sample(actual, combined: true);
          expect(combined['error'], isNull);
          final both = combined['observed']! as Map;
          expect(both['legacy'], legacy['observed']);
          expect((both['box']! as Map)['status'], 'source-complete');
          expect((both['box']! as Map)['value'], [2, 3, 5, 7]);
        },
      );
    }
  }
  final before = <String, String>{
    'missing owned scope.child':
        'delete request.currentSsrSource.currentRaw.scopeChild;',
    'extra layout occurrence': [
      'request.currentSsrSource.currentRaw.layoutSlots.push({seat:99,',
      'sourceAliasOf:null,nodes:[]});',
    ].join(),
    'wrong tuple': [
      'request.source.',
      'nativeAdapterId="classic-compound-showcase-allocation-host-v1";',
    ].join(),
    'anonymous capture text': [
      'capture.childNodes.unshift(from({nodeType:3,data:"foreign"},',
      'capture));',
    ].join(),
    'capture NBSP': [
      'capture.childNodes.unshift(from({nodeType:3,data:String.',
      'fromCharCode(160)},capture));',
    ].join(),
    'capture comment': [
      'capture.childNodes.unshift(from({nodeType:8,data:"foreign"},',
      'capture));',
    ].join(),
    'duplicate matching root with original retained':
        'document.querySelectorAll=()=>[root,root.cloneNode(true)];',
    'copied root with original retained':
        'document.querySelectorAll=()=>[root.cloneNode(true)];',
    'selector throws':
        'document.querySelectorAll=()=>{throw new Error("bad selector");};',
    'missing owned live region':
        'request.currentSsrSource.currentRaw.liveRegion=null;',
    'forged foreign announcement': [
      'request.currentSsrSource.currentRaw.generatedTree.children[1]={',
      'opaqueSlot:0};',
    ].join(),
    'source announcement data conflicts empty output': [
      'request.currentSsrSource.currentRaw.liveRegion.sourceData="not ',
      'empty";',
    ].join(),
  };
  for (final c in before.entries) {
    test('before CSS ${c.key}', () async {
      final row = await _sample(
        await _actual('drag', 'default', 'light'),
        combined: true,
        mutation: c.value,
      );
      expect(row['error'], isNotNull);
      expect(row['cssReads'], 0);
    });
  }
  for (final phase in ['legacy', 'box', 'after-box']) {
    final changes = <String, String>{
      'duplicate selector':
          'document.querySelectorAll=()=>[root,root.cloneNode(true)];',
      'fresh selector owner':
          'document.querySelectorAll=()=>[root.cloneNode(true)];',
      'selector exception':
          'document.querySelectorAll=()=>{throw new Error("changed");};',
      'same-value receipt nested object replacement': [
        'request.currentSsrSource.currentRaw.scopeChild={...request.',
        'currentSsrSource.currentRaw.scopeChild};',
      ].join(),
      'same-value declared children array replacement': [
        'request.currentSsrSource.currentRaw.generatedTree.children=[..',
        '.request.currentSsrSource.currentRaw.generatedTree.children];',
      ].join(),
      'same-shape owned node replacement': [
        'const old=root.children[0],fresh=old.cloneNode(true);root.',
        'childNodes[root.childNodes.indexOf(old)]=fresh;',
      ].join(),
      'owned literal announcement replacement': [
        'const span=root.children[1].children[0];span.childNodes=[from(',
        '{nodeType:3,data:"changed"},span)];',
      ].join(),
    };
    for (final c in changes.entries) {
      test('held original root $phase ${c.key}', () async {
        final change = c.value;
        final String mutation;
        final String? sampler;
        if (phase == 'after-box') {
          mutation = '';
          sampler = [
            '(request)=>{const result=($boxPaddingObservationScript)(',
            'request);$change return result;}',
          ].join();
        } else if (phase == 'box') {
          mutation = '';
          sampler = [
            '(request)=>{const css=getComputedStyle;let changed=false;',
            'global.getComputedStyle=node=>{const value=css(node);if(',
            '!changed){changed=true;$change}return value;};',
            'try{return ($boxPaddingObservationScript)(request);}',
            'finally{global.getComputedStyle=css;}}',
          ].join();
        } else {
          mutation = [
            'const css=getComputedStyle;let changed=false;global.',
            'getComputedStyle=node=>{',
            'const value=css(node);if(!changed){changed=true;$change}',
            'return value;};',
          ].join();
          sampler = null;
        }
        final row = await _sample(
          await _actual('drag', 'default', 'light'),
          combined: true,
          mutation: mutation,
          boxScript: sampler,
        );
        expect(row['error'], isNotNull);
        expect(row['heldOriginalRootAttached'], true);
      });
    }
  }
  test('foreign whole frontier interiors and attrs remain opaque', () async {
    final row = await _sample(
      await _actual('drag', 'default', 'light'),
      mutation: [
        'const foreign=root.children[0].children[0];foreign.',
        'setAttribute("data-foreign","updated");',
        'foreign.childNodes=[from({nodeType:1,namespaceURI:"http://www.',
        'w3.org/1999/xhtml",localName:"span",attributes:{},',
        'childNodes:[{nodeType:3,data:"new inside"}]},foreign)];',
      ].join(),
    );
    expect(row['error'], isNull);
    expect((row['observed']! as Map)['status'], 'source-complete');
    expect((row['observed']! as Map)['value'], [2, 3, 5, 7]);
  });
}
