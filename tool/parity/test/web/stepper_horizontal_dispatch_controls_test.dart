// Exercises actual normal SSR output and held guards in the Node harness.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart' show CoreSurfaceStyleId;
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
Future<_Actual> _actual(
  String variant,
  String theme, {
  String style = 'defaultStyle',
}) => _cache.putIfAbsent('$variant/$theme/$style', () async {
  final key = 'stepper-$variant-$theme-$style';
  final entry = MatrixEntry.fromJson({
    'component': 'stepper',
    'variant': variant,
    'theme': theme,
    'surfaceStyle': style,
    'tier': 't2',
    'probes': captureProbes(
      key: key,
      component: 'stepper',
      variant: variant,
      flutterClassName: 'Stepper',
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
  expect(root.children, hasLength(3));
  expect(root.children.every((c) => c.localName == 'div'), true);
  expect(receipts, hasLength(1));
  expect(receipts.single.containsKey('error'), false, reason: '$receipts');
  expect(receipts.single['kind'], 'canonical-ssr-stepper-horizontal-v1');
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
    'harnessURL': 'file:///owned/stepper-horizontal-source.html',
  };
  final program =
      '''
$_kRuntime
const capture=from(${jsonEncode(actual.capture)}),root=capture.children[0],padding=root;
const selector=${jsonEncode(selector)};
global.document={querySelector:sel=>sel===selector?root:null,
 querySelectorAll:sel=>sel===selector?[root]:[],
 createTreeWalker:node=>{const queue=[];const visit=n=>{for(const c of n.childNodes){if(c.nodeType===3)queue.push(c);else if(c.nodeType===1)visit(c);}};visit(node);return {nextNode:()=>queue.shift()||null};}};
const request={requested:true,selector,layoutSelector:selector,
 source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
 currentSsrSource:${jsonEncode(receipt)},requiredCurrentSsrKind:'canonical-ssr-stepper-horizontal-v1'};
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
  for (final variant in ['default', 'disabled']) {
    for (final theme in ['light', 'dark']) {
      test(
        [
          'Stepper actual normal $variant/$theme keeps the orig',
          'inal owner',
        ].join(),
        () async {
          final actual = await _actual(variant, theme);
          final one = await _sample(actual);
          expect(one['error'], isNull);
          final row = one['observed']! as Map;
          expect(row['status'], 'source-complete');
          expect(row['value'], [2, 3, 5, 7]);
          expect(row['ownerIsLayoutRoot'], true);
          final legacy = await _sample(actual, legacyOnly: true);
          final combined = await _sample(actual, combined: true);
          expect(combined['error'], isNull);
          final both = combined['observed']! as Map;
          expect(both['legacy'], legacy['observed']);
          expect((both['box']! as Map)['value'], [2, 3, 5, 7]);
        },
      );
    }
  }
  test(
    [
      'Stepper real nondefault normal SSR and Node retain t',
      'he same source',
    ].join(),
    () async {
      final style = CoreSurfaceStyleId.values.firstWhere(
        (style) => style != CoreSurfaceStyleId.defaultStyle,
      );
      final actual = await _actual('default', 'light', style: style.name);
      expect(actual.entry.key, endsWith('-${style.name}'));
      final result = await _sample(actual, combined: true);
      expect(result['error'], isNull);
      expect(
        ((result['observed']! as Map)['box']! as Map)['status'],
        'source-complete',
      );
      expect(((result['observed']! as Map)['box']! as Map)['value'], [
        2,
        3,
        5,
        7,
      ]);
    },
  );
  final before = <String, String>{
    'unknown style': [
      'request.currentSsrSource.entryKey="stepper-default-l',
      'ight-unlistedStyle";capture.setAttribute("data-parit',
      'y-key",request.currentSsrSource.entryKey);',
    ].join(),
    'missing actual receipt': 'request.currentSsrSource=null;',
    'foreign required kind': 'request.requiredCurrentSsrKind="foreign";',
    'partial tuple': 'delete request.source.nativeAdapterId;',
    'borrowed tuple': 'request.source.webAdapterId="foreign";',
    'extra source field': 'request.source.extra=true;',
    'missing entry key': 'delete request.currentSsrSource.entryKey;',
    'empty entry key': 'request.currentSsrSource.entryKey="";',
    'foreign recipe key': [
      'request.currentSsrSource.entryKey="stepper-foreign-l',
      'ight-defaultStyle";',
    ].join(),
    'wrong fixed complete count':
        'request.currentSsrSource.completeRawSlotCount=2;',
    'missing declared item':
        'request.currentSsrSource.currentRaw.rawStepItems.pop();',
    'missing generated column': [
      'request.currentSsrSource.currentRaw.generatedColumns',
      '.pop();',
    ].join(),
    'invalid alias index': [
      'request.currentSsrSource.currentRaw.rawStepItems[0].',
      'aliasesEarlier=[0];',
    ].join(),
    'claim omitted description mounted': [
      'request.currentSsrSource.currentRaw.rawStepItems[0].',
      'descriptionMountedClaim=true;',
    ].join(),
    'generated treated as supplied': [
      'request.currentSsrSource.currentRaw.generatedColumns',
      '[0].generatedNotSupplied=false;',
    ].join(),
    'initial ASCII text': [
      'capture.childNodes.unshift(from({nodeType:3,data:" "',
      '},capture));',
    ].join(),
    'initial NBSP text': [
      'capture.childNodes.unshift(from({nodeType:3,data:Str',
      'ing.fromCharCode(160)},capture));',
    ].join(),
    'initial comment': [
      'capture.childNodes.unshift(from({nodeType:8,data:"x"',
      '},capture));',
    ].join(),
    'owned root attr': 'root.setAttribute("data-changed","true");',
    'missing original column': [
      'root.childNodes=root.childNodes.filter(n=>n!==root.c',
      'hildren[0]);',
    ].join(),
    'extra generated column':
        'root.childNodes.push(root.children[0].cloneNode(true));',
    'root duplicate selector':
        'document.querySelectorAll=()=>[root,root.cloneNode(true)];',
    'root clone selector':
        'document.querySelectorAll=()=>[root.cloneNode(true)];',
    'different layout selector': 'request.layoutSelector="missing";',
  };
  for (final (label, mutation) in before.entries.map((e) => (e.key, e.value))) {
    test('Stepper initial $label rejects before any CSS', () async {
      final result = await _sample(
        await _actual('default', 'light'),
        mutation: mutation,
      );
      expect(result['cssReads'], 0);
      expect((result['observed']! as Map)['status'], 'incomplete');
      expect((result['observed']! as Map).containsKey('value'), false);
    });
  }
  final held = <String, String>{
    'equal whole receipt clone': [
      'request.currentSsrSource=JSON.parse(JSON.stringify(r',
      'equest.currentSsrSource));',
    ].join(),
    'equal nested graph clone': [
      'request.currentSsrSource.currentRaw.generatedColumns',
      '=request.currentSsrSource.currentRaw.generatedColumn',
      's.map(c=>({...c}));',
    ].join(),
    'declared item change': [
      'request.currentSsrSource.currentRaw.rawStepItems[0].',
      'label="changed";',
    ].join(),
    'current selector change': 'request.selector="changed";',
    'owned root attrs': 'root.setAttribute("data-phase","changed");',
    'formatter data': [
      'capture.childNodes.push(from({nodeType:3,data:" "},c',
      'apture));',
    ].join(),
    'original root detach': 'root.isConnected=false;',
    'column reference replacement': [
      'const old=root.children[0];root.childNodes[root.chil',
      'dNodes.indexOf(old)]=old.cloneNode(true);',
    ].join(),
    'column reorder': [
      'const a=root.children[0],b=root.children[1],i=root.c',
      'hildNodes.indexOf(a),j=root.childNodes.indexOf(b);ro',
      'ot.childNodes[i]=b;root.childNodes[j]=a;',
    ].join(),
  };
  for (final (label, mutation) in held.entries.map((e) => (e.key, e.value))) {
    test(
      [
        'Stepper $label during legacy read makes combined res',
        'ult fail',
      ].join(),
      () async {
        final actual = await _actual('default', 'light');
        final healthy = await _sample(actual, combined: true);
        expect(healthy['error'], isNull);
        expect(
          ((healthy['observed']! as Map)['box']! as Map)['status'],
          'source-complete',
        );
        final hook = [
          'const originalCss=getComputedStyle;let mutated=false',
          ';getComputedStyle=node=>{if(!mutated){mutated=true;$mutation',
          '}return originalCss(node);};',
        ].join();
        final result = await _sample(
          await _actual('default', 'light'),
          combined: true,
          mutation: hook,
        );
        expect(
          result['error'],
          contains('STEPPER_HORIZONTAL_BINDING_CHANGED_DURING_LEGACY_READ'),
        );
        expect(result['cssReads'], greaterThan(0));
        expect(result['observed'], isNull);
      },
    );
    test('Stepper $label after box read makes combined result fail', () async {
      final actual = await _actual('default', 'light');
      final healthy = await _sample(actual, combined: true);
      expect(healthy['error'], isNull);
      expect(
        ((healthy['observed']! as Map)['box']! as Map)['status'],
        'source-complete',
      );
      final sampler = [
        '(request)=>{const result=($boxPaddingObservationScript',
        ')(request);$mutation return result;}',
      ].join();
      final result = await _sample(actual, combined: true, boxScript: sampler);
      expect(
        result['error'],
        contains('STEPPER_HORIZONTAL_BINDING_CHANGED_DURING_BOX_READ'),
      );
      expect(result['observed'], isNull);
    });
  }
  for (final (label, change) in held.entries.map((e) => (e.key, e.value))) {
    test(
      [
        'Stepper $label during REAL own box CSS makes combine',
        'd result fail',
      ].join(),
      () async {
        final actual = await _actual('default', 'light');
        final healthy = await _sample(actual, combined: true);
        expect(healthy['error'], isNull);
        expect(
          ((healthy['observed']! as Map)['box']! as Map)['status'],
          'source-complete',
        );
        final sampler = [
          '(request)=>{const css=getComputedStyle;let changed=false;',
          'global.getComputedStyle=node=>{const value=css(node);if(',
          '!changed){changed=true;$change}return value;};',
          'try{return ($boxPaddingObservationScript)(request);}',
          'finally{global.getComputedStyle=css;}}',
        ].join();
        final result = await _sample(
          actual,
          combined: true,
          boxScript: sampler,
        );
        expect(
          result['error'],
          contains('STEPPER_HORIZONTAL_BINDING_CHANGED_DURING_BOX_READ'),
        );
        expect(result['cssReads'], greaterThan(0));
        expect(result['observed'], isNull);
      },
    );
  }
  test(
    [
      'Stepper source ignores generated column interiors be',
      'fore CSS',
    ].join(),
    () async {
      final mutation = [
        'for(const col of root.children){col.childNodes=[];co',
        'l.setAttribute("data-opaque","changed");}',
      ].join();
      final result = await _sample(
        await _actual('default', 'light'),
        mutation: mutation,
      );
      expect(result['error'], isNull);
      expect((result['observed']! as Map)['status'], 'source-complete');
      expect((result['observed']! as Map)['value'], [2, 3, 5, 7]);
    },
  );
  test(
    [
      'Stepper source ignores generated interiors during re',
      'al own CSS',
    ].join(),
    () async {
      final mutation = [
        'const originalCss=getComputedStyle;getComputedStyle=',
        'node=>{for(const col of root.children){col.childNode',
        's=[];col.setAttribute("data-opaque","changed");}retu',
        'rn originalCss(node);};',
      ].join();
      final result = await _sample(
        await _actual('default', 'light'),
        combined: true,
        mutation: mutation,
      );
      expect(result['error'], isNull);
      expect(
        ((result['observed']! as Map)['box']! as Map)['status'],
        'source-complete',
      );
      expect(((result['observed']! as Map)['box']! as Map)['value'], [
        2,
        3,
        5,
        7,
      ]);
    },
  );
}
