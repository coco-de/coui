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
Future<_Actual> _actual(String theme) => _cache.putIfAbsent(theme, () async {
  final key = 'stage-container-default-$theme-defaultStyle';
  final entry = MatrixEntry.fromJson({
    'component': 'stage-container',
    'variant': 'default',
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': captureProbes(
      key: key,
      component: 'stage-container',
      variant: 'default',
      flutterClassName: 'StageContainer',
    ).map((p) => p.toJson()).toList(),
  });
  final receipts = <Map<String, Object?>>[];
  final body = await renderCaptureBodyHtml(
    entry,
    onCurrentBoxSource: receipts.add,
  );
  final parsed = html.parseFragment(body);
  final capture = parsed.querySelectorAll('[data-parity-key]').single;
  final root = parsed.querySelectorAll(entry.probes.single.webSelector).single;
  expect(root.parent, same(capture));
  expect(root.children, hasLength(1));
  expect(root.children.single.children, hasLength(1));
  expect(receipts, hasLength(1));
  expect(receipts.single.containsKey('error'), false, reason: '$receipts');
  expect(receipts.single['kind'], 'canonical-ssr-stage-callback-v1');
  return (entry: entry, receipt: receipts.single, capture: _tree(capture));
});

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
global.location={href:'file:///owned/stage-callback-source.html'};
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
    'harnessURL': 'file:///owned/stage-callback-source.html',
  };
  final program =
      '''
$_kRuntime
const capture=from(${jsonEncode(actual.capture)}),root=capture.children[0],padding=root.children[0];
const selector=${jsonEncode(selector)};
global.document={querySelector:sel=>sel===selector?root:null,
 querySelectorAll:sel=>sel===selector?[root]:[],
 createTreeWalker:node=>{const queue=[];const visit=n=>{for(const c of n.childNodes){if(c.nodeType===3)queue.push(c);else if(c.nodeType===1)visit(c);}};visit(node);return {nextNode:()=>queue.shift()||null};}};
const request={requested:true,selector,layoutSelector:selector,
 source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
 currentSsrSource:${jsonEncode(receipt)},requiredCurrentSsrKind:'canonical-ssr-stage-callback-v1'};
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
  for (final theme in ['light', 'dark']) {
    test(
      'Stage actual normal SSR $theme uses inner padding and outer frame',
      () async {
        final actual = await _actual(theme);
        final one = await _sample(actual);
        expect(one['error'], isNull);
        final row = one['observed']! as Map;
        expect(row['status'], 'source-complete');
        expect(row['value'], [2, 3, 5, 7]);
        expect(row['ownerIsLayoutRoot'], false);
        final legacy = await _sample(actual, legacyOnly: true);
        final combined = await _sample(actual, combined: true);
        expect(combined['error'], isNull);
        final both = combined['observed']! as Map;
        expect(both['legacy'], legacy['observed']);
        expect((both['box']! as Map)['value'], [2, 3, 5, 7]);
      },
    );
  }
  final before = <String, String>{
    'missing passive receipt': 'request.currentSsrSource=null;',
    'foreign required kind': 'request.requiredCurrentSsrKind="foreign";',
    'wrong complete tuple': 'request.source.nativeAdapterId="foreign";',
    'extra source field': 'request.source.extra=true;',
    'wrong raw body slot count':
        'request.currentSsrSource.completeRawSlotCount=2;',
    'missing inner owner record':
        'delete request.currentSsrSource.currentRaw.paddingOwner;',
    'unrecorded ASCII formatter':
        'capture.childNodes.unshift(from({nodeType:3,data:" "},capture));',
    'unrecorded NBSP': [
      'capture.childNodes.unshift(from({nodeType:3,data:Str',
      'ing.fromCharCode(160)},capture));',
    ].join(),
    'unrecorded comment':
        'capture.childNodes.unshift(from({nodeType:8,data:"x"},capture));',
    'duplicate canonical root':
        'document.querySelectorAll=()=>[root,root.cloneNode(true)];',
    'foreign canonical root clone':
        'document.querySelectorAll=()=>[root.cloneNode(true)];',
    'inner paint attrs changed': 'padding.setAttribute("data-changed","true");',
    'no convenient inner selector': 'document.querySelectorAll=()=>[padding];',
  };
  for (final c in before.entries) {
    test('Stage rejects before CSS ${c.key}', () async {
      final row = await _sample(
        await _actual('light'),
        combined: true,
        mutation: c.value,
      );
      expect(row['error'], isNotNull);
      expect(row['cssReads'], 0);
    });
  }
  for (final phase in ['legacy', 'box', 'after-box']) {
    final changes = <String, String>{
      'same-value entire receipt clone': [
        'request.currentSsrSource=JSON.parse(JSON.stringify(r',
        'equest.currentSsrSource));',
      ].join(),
      'same-value nested raw clone': [
        'request.currentSsrSource.currentRaw={...request.curr',
        'entSsrSource.currentRaw};',
      ].join(),
      'same-value declared node array clone': [
        'request.currentSsrSource.currentRaw.frameNodes=[...r',
        'equest.currentSsrSource.currentRaw.frameNodes];',
      ].join(),
      'request selector replacement': 'request.selector="different";',
      'layout selector replacement': 'request.layoutSelector="different";',
      'actual owned formatter text mutation': [
        'const text=from({nodeType:3,data:" "},root);root.chi',
        'ldNodes.push(text);',
      ].join(),
      'same-shape padding owner replacement': [
        'const fresh=padding.cloneNode(true);root.childNodes[',
        'root.childNodes.indexOf(padding)]=fresh;',
      ].join(),
      'held whole body detached': 'padding.childNodes=[];',
    };
    for (final c in changes.entries) {
      test('Stage three-phase held $phase ${c.key}', () async {
        final change = c.value;
        final String mutation;
        final String? sampler;
        if (phase == 'after-box') {
          mutation = '';
          sampler = [
            '(request)=>{const result=(',
            '$boxPaddingObservationScript)(request);$change retur',
            'n result;}',
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
            [
              'const css=getComputedStyle;let changed=false;global.',
              'getComputedStyle=node=>{',
            ].join(),
            [
              'const value=css(node);if(!changed){changed=true;',
              '$change}return value;};',
            ].join(),
          ].join();
          sampler = null;
        }
        final row = await _sample(
          await _actual('light'),
          combined: true,
          mutation: mutation,
          boxScript: sampler,
        );
        expect(row['error'], isNotNull);
        expect(row['heldOriginalRootAttached'], true);
      });
    }
  }
  for (final phase in ['before', 'during-css']) {
    test('Stage foreign callback interior is opaque $phase', () async {
      final change = [
        'const foreign=padding.children[0];foreign.setAttribu',
        'te("data-foreign","updated");foreign.childNodes=[fro',
        'm({nodeType:1,namespaceURI:"http://www.w3.org/1999/x',
        'html",localName:"span",attributes:{style:"padding:99',
        '9px"},childNodes:[{nodeType:3,data:"foreign changed"',
        '}]},foreign)];',
      ].join();
      final mutation = phase == 'before'
          ? change
          : [
              [
                'const css=getComputedStyle;let changed=false;global.',
                'getComputedStyle=node=>{',
              ].join(),
              [
                'const value=css(node);if(!changed){changed=true;',
                '$change}return value;};',
              ].join(),
            ].join();
      final row = await _sample(
        await _actual('light'),
        combined: true,
        mutation: mutation,
      );
      expect(row['error'], isNull);
      expect(((row['observed']! as Map)['box']! as Map)['value'], [2, 3, 5, 7]);
    });
  }
}
