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
Future<_Actual> _actual(String variant, String theme) =>
    _cache.putIfAbsent('$variant/$theme', () async {
      final key = 'bottom-action-bar-$variant-$theme-defaultStyle';
      final entry = MatrixEntry.fromJson({
        'component': 'bottom-action-bar',
        'variant': variant,
        'theme': theme,
        'surfaceStyle': 'defaultStyle',
        'tier': 't2',
        'probes': captureProbes(
          key: key,
          component: 'bottom-action-bar',
          variant: variant,
          flutterClassName: 'BottomActionBar',
        ).map((probe) => probe.toJson()).toList(),
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
      final selected = parsed.querySelectorAll(entry.probes.single.webSelector);
      expect(selected, hasLength(1));
      expect(selected.single.parent, same(capture));
      expect(selected.single.attributes['role'], 'group');
      final raw = receipts.single['currentRaw']! as Map;
      expect(raw['rawSlotCount'], 5);
      expect(raw['declaredSeats'], hasLength(5));
      expect(receipts.single['completeRawSlotCount'], 5);
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
  bool legacyOnly = false,
  String mutation = '',
  String? boxScript,
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
global.document={querySelector:sel=>sel===selector?root:null,
 querySelectorAll:sel=>sel===selector?[root]:[],
 createTreeWalker:node=>{const queue=[];const visit=n=>{for(const c of n.childNodes){if(c.nodeType===3)queue.push(c);else if(c.nodeType===1)visit(c);}};visit(node);return {nextNode:()=>queue.shift()||null};}};
const request={requested:true,selector,layoutSelector:selector,
 source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
 currentSsrSource:${jsonEncode(receipt)},requiredCurrentSsrKind:'canonical-ssr-bottom-action-bar-v1'};
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
  for (final variant in ['default', 'horizontal', 'summary-compact']) {
    for (final theme in ['light', 'dark']) {
      test(
        '$variant/$theme actual complete five-seat SSR binds original root CSS',
        () async {
          final actual = await _actual(variant, theme);
          final single = await _sample(actual);
          expect(single['error'], isNull);
          final box = single['observed']! as Map;
          expect(box['status'], 'source-complete');
          expect(box['value'], [2, 3, 5, 7]);
          expect(box['ownerIsLayoutRoot'], true);
          final legacy = await _sample(actual, legacyOnly: true);
          final both = await _sample(actual, combined: true);
          expect(both['error'], isNull);
          final joined = both['observed']! as Map;
          expect(joined['legacy'], legacy['observed']);
          expect((joined['box']! as Map)['status'], 'source-complete');
          expect((joined['box']! as Map)['value'], [2, 3, 5, 7]);
        },
      );
    }
  }
  const removeCaptureKey = "capture.removeAttribute('data-parity-key');";
  final malformed = <String, String>{
    'anonymous meaningful capture text':
        "capture.childNodes.unshift(from({nodeType:3,data:'foreign'},"
        'capture));',
    'anonymous capture NBSP':
        'capture.childNodes.unshift(from({nodeType:3,'
        'data:String.fromCharCode(160)},capture));',
    'anonymous capture comment':
        "capture.childNodes.unshift(from({nodeType:8,data:'foreign'},"
        'capture));',
    'missing receipt key and missing capture key':
        'delete request.currentSsrSource.entryKey;$removeCaptureKey',
    'null receipt key and missing capture key':
        'request.currentSsrSource.entryKey=null;'
        "capture.removeAttribute('data-parity-key');",
    'empty receipt key and empty capture key':
        "request.currentSsrSource.entryKey='';"
        "capture.setAttribute('data-parity-key','');",
    'missing declared seat':
        'request.currentSsrSource.currentRaw.declaredSeats.pop();',
    'missing primary':
        'request.currentSsrSource.currentRaw.declaredSeats[0].present=false;',
    'active description presence conflicts with mounted frontier':
        'request.currentSsrSource.currentRaw.declaredSeats[2].present=false;',
    'inactive seat claims mounted frontier':
        'request.currentSsrSource.currentRaw.declaredSeats[3].mounted=true;',
    'changed active layout':
        "request.currentSsrSource.currentRaw.layout='summaryCompact';",
    'wrong tuple':
        "request.source.nativeAdapterId='classic-compound-showcase-allocation"
        "-host-v1';",
    'wrong current kind': "request.currentSsrSource.kind='foreign';",
    'copied selector root and original retained':
        'document.querySelectorAll=()=>[root.cloneNode(true)];',
    'duplicate selector root and original retained':
        'document.querySelectorAll=()=>[root,root.cloneNode(true)];',
    'invalid selector':
        "document.querySelectorAll=()=>{throw new Error('invalid selector');};",
    'extra generated wrapper':
        'root.childNodes.push(root.children[0].cloneNode(true));',
  };
  for (final c in malformed.entries) {
    test('before-CSS ${c.key}', () async {
      final row = await _sample(
        await _actual('default', 'light'),
        combined: true,
        mutation: c.value,
      );
      expect(row['error'], isNotNull);
      expect(row['cssReads'], 0);
    });
  }
  test(
    'foreign interior attributes remain opaque to source and own padding',
    () async {
      final row = await _sample(
        await _actual('default', 'light'),
        mutation:
            "root.children[0].children[0].setAttribute('style',"
            "'padding:999px');"
            "root.children[0].children[0].setAttribute('data-foreign',"
            "'changed');",
      );
      expect(row['error'], isNull);
      expect((row['observed']! as Map)['status'], 'source-complete');
      expect((row['observed']! as Map)['value'], [2, 3, 5, 7]);
    },
  );
  test(
    'during legacy retarget keeps old root attached and rejects binding',
    () async {
      const retainRead = 'const prior=getComputedStyle;let once=false;';
      const installRead = 'global.getComputedStyle=n=>{const s=prior(n);';
      const retarget = 'if(!once){once=true;document.querySelectorAll=()=>[';
      const finishRead = 'root.cloneNode(true)];}return s;};';
      final row = await _sample(
        await _actual('default', 'light'),
        combined: true,
        mutation: '$retainRead$installRead$retarget$finishRead',
      );
      expect(row['heldOriginalRootAttached'], true);
      expect(
        row['error'],
        contains('BOTTOM_ACTION_BAR_BINDING_CHANGED_DURING_LEGACY_READ'),
      );
    },
  );
  test(
    'after box duplicate keeps old root attached and rejects binding',
    () async {
      final original = boxPaddingObservationScript;
      final readOriginalBox = '(request)=>{const v=($original)(request);';
      const duplicateSelector =
          'document.querySelectorAll=()=>[root,root.cloneNode(true)];';
      final row = await _sample(
        await _actual('default', 'light'),
        combined: true,
        boxScript: '$readOriginalBox${duplicateSelector}return v;}',
      );
      expect(row['heldOriginalRootAttached'], true);
      expect(
        row['error'],
        contains('BOTTOM_ACTION_BAR_BINDING_CHANGED_DURING_BOX_READ'),
      );
    },
  );
  test(
    'standalone own CSS getter duplicate yields incomplete and no value',
    () async {
      final row = await _sample(
        await _actual('default', 'light'),
        mutation:
            'const prior=getComputedStyle;global.getComputedStyle=n=>new '
            'Proxy(prior(n),{get(target,'
            "key){if(key==='paddingTop')document.querySelectorAll=()=>[root,"
            'root.cloneNode(true)];return target[key];}});',
      );
      expect(row['heldOriginalRootAttached'], true);
      expect(row['error'], isNull);
      final box = row['observed']! as Map;
      expect(box['status'], 'incomplete');
      expect(box.containsKey('value'), false);
    },
  );
  test(
    'inactive nullable declaration mutation during CSS rejects held full '
    'receipt',
    () async {
      final row = await _sample(
        await _actual('default', 'light'),
        mutation:
            'const prior=getComputedStyle;global.getComputedStyle=n=>{const '
            's=prior(n);'
            'request.currentSsrSource.currentRaw.declaredSeats[3].present=tru'
            'e;return s;};',
      );
      expect(row['error'], isNull);
      expect((row['observed']! as Map)['status'], 'incomplete');
      expect((row['observed']! as Map).containsKey('value'), false);
    },
  );
  test('same-value receipt graph replacement during CSS is stale', () async {
    final row = await _sample(
      await _actual('default', 'light'),
      mutation:
          'const prior=getComputedStyle;global.getComputedStyle=n=>{const '
          's=prior(n);'
          'request.currentSsrSource.currentRaw=structuredClone(request.curren'
          'tSsrSource.currentRaw);return s;};',
    );
    expect(row['error'], isNull);
    expect((row['observed']! as Map)['status'], 'incomplete');
  });
}
