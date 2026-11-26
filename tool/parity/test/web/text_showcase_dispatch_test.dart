import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/computed_style_probe.dart';
import '../../src/web/text_showcase_ssr_source.dart';
import '../../src/web/web_capture_backend.dart';

// The independent literal wire assertion below retains the original RED tuple.
const BoxObservationSourceSpec _kTextOuterAllocation =
    BoxObservationSourceSpec.textShowcaseOuterPadding;

const _kPrototypeReceiptMutation =
    'request.currentSsrSource.kind='
    '"canonical-ssr-text-showcase-prototype-v1";';
const _kNullEntryMutation =
    'request.currentSsrSource.entryKey=null;'
    'capture.removeAttribute("data-parity-key");';

const _kVariants = [
  'typography-display',
  'typography-headline',
  'typography-title',
  'typography-body',
  'typography-weight',
  'typography-primitive',
  'colors-brand',
  'colors-status',
  'colors-surface',
  'modifiers',
  'wrap',
  'keep-all',
  'textstyle',
  'opacity',
  'rich',
];

MatrixEntry _entry(String variant, String theme) => MatrixEntry.fromJson({
  'component': 'text',
  'variant': variant,
  'theme': theme,
  'surfaceStyle': 'defaultStyle',
  'tier': 't2',
  'probes': captureProbes(
    key: 'text-$variant-$theme-defaultStyle',
    component: 'text',
    variant: variant,
    flutterClassName: 'closed-source',
  ).map((probe) => probe.toJson()).toList(),
});

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

typedef _Actual = ({
  MatrixEntry entry,
  Map<String, Object?> receipt,
  Map<String, Object?> capture,
});
final _cache = <String, Future<_Actual>>{};
Future<_Actual> _actual(String variant, [String theme = 'light']) =>
    _cache.putIfAbsent('$variant/$theme', () async {
      final entry = _entry(variant, theme);
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
      final probe = entry.probes.single;
      final selected = parsed.querySelectorAll(probe.webSelector);
      expect(selected, hasLength(1));
      expect(selected.single, same(capture.children.single));
      return (entry: entry, receipt: receipts.single, capture: _tree(capture));
    });

// DOM shapes originate from actual unchanged registry SSR. CSS strings and
// geometry below are unit sentinels, never evidence of actual browser values.
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
global.location={href:'file:///owned/text-showcase-source.html'};
global.window={__coui_parity_color_keys__:new Set()};
global.Node={TEXT_NODE:3};
global.NodeFilter={SHOW_TEXT:4};
let cssReads=0;
global.getComputedStyle=node=>{cssReads++;return {
 display:'block',visibility:'visible',position:'static',overflowX:'visible',overflowY:'visible',clip:'auto',opacity:'1',
 paddingTop:node===root?'0px':'901px',paddingRight:node===root?'5px':'902px',
 paddingBottom:node===root?'7.25px':'903px',paddingLeft:node===root?'11px':'904px',
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
  String? boxScript,
}) async {
  final selector = actual.entry.probes.single.webSelector;
  final receipt = {
    ...actual.receipt,
    'harnessURL': 'file:///owned/text-showcase-source.html',
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
 currentSsrSource:${jsonEncode(receipt)},
 requiredCurrentSsrKind:${jsonEncode(requiredTextShowcaseSsrKind(actual.entry))}};
$mutation
let observed,error;
try{observed=JSON.parse((${combined
          ? boxScript == null
                ? computedStyleAndBoxObservationScript
                : sourceValidatedComputedStyleAndBoxScript(boxScript)
          : boxPaddingObservationScript})(request));}
catch(e){error=String(e);}
console.log(JSON.stringify({observed,error,cssReads}));
''';
  final result = await Process.run(
    Platform.environment['PARITY_NODE'] ?? 'node',
    ['-e', program],
  );
  expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
}

void main() {
  test('declared Text showcase reaches actual SSR recorder', () async {
    const key = 'text-typography-display-light-defaultStyle';
    final entry = MatrixEntry.fromJson({
      'component': 'text',
      'variant': 'typography-display',
      'theme': 'light',
      'surfaceStyle': 'defaultStyle',
      'tier': 't2',
      'probes': [
        rootProbeSpec(
          key: key,
          flutterClassName: 'TextTypographyDisplayExample',
          boxObservationSource: _kTextOuterAllocation,
        ).toJson(),
      ],
    });
    final receipts = <Map<String, Object?>>[];
    final body = await renderCaptureBodyHtml(
      entry,
      onCurrentBoxSource: receipts.add,
    );
    final captures = html
        .parseFragment(body)
        .querySelectorAll('[data-parity-key]');
    expect(captures, hasLength(1));
    expect(captures.single.attributes['data-parity-key'], key);
    expect(captures.single.children, hasLength(1));
    expect(captures.single.children.single.localName, 'div');
    // The original backend really rendered its registry Example, but has no
    // recorder for this declared outer allocation until production wiring.
    expect(
      receipts,
      hasLength(1),
      reason: 'actual SSR source receipt is required',
    );
    final receipt = receipts.single;
    expect(receipt['kind'], 'canonical-ssr-text-showcase-v1');
    expect(receipt['entryKey'], key);
    expect(receipt['source'], {
      'schemaVersion': 1,
      'logicalUnitId': 'classic-text-showcase-generated-padding-host',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'classic-text-showcase-outer-padding-v1',
      'webAdapterId': 'classic-text-showcase-outer-padding-v1',
    });
    expect(receipt['rawOrderFromPublicProducerLists'], true);
    expect(receipt['completeRawSlotCount'], 2);
    expect(
      (receipt['currentRaw']! as Map)['kind'],
      'current-text-showcase-raw-v1',
    );
  });

  for (final variant in _kVariants) {
    for (final theme in ['light', 'dark']) {
      test('$variant/$theme declared backend and padding dispatcher', () async {
        final actual = await _actual(variant, theme);
        expect(
          actual.entry.probes.single.boxObservationSource,
          BoxObservationSourceSpec.textShowcaseOuterPadding,
        );
        expect(actual.receipt.keys.length, 6);
        expect(actual.receipt['kind'], 'canonical-ssr-text-showcase-v1');
        expect(
          requiredTextShowcaseSsrKind(actual.entry),
          'canonical-ssr-text-showcase-v1',
        );
        final result = await _sample(actual);
        expect(result['error'], isNull);
        expect(result['cssReads'], 1);
        final observed = result['observed']! as Map;
        expect(observed['status'], 'source-complete');
        expect(observed['value'], [0, 5, 7.25, 11]);
        expect(observed['ownerIsLayoutRoot'], true);
        expect(observed['registryIsLayoutRoot'], true);
        expect(observed['canonicalComparisonEligible'], false);
      });
    }
  }

  final beforeCss = <String, String>{
    'missing requirement': 'delete request.requiredCurrentSsrKind;',
    'wrong requirement':
        'request.requiredCurrentSsrKind="canonical-ssr-visual-value-v1";',
    'missing receipt': 'delete request.currentSsrSource;',
    'prototype receipt': _kPrototypeReceiptMutation,
    'extra header': 'request.currentSsrSource.extra=true;',
    'wrong entry': 'request.currentSsrSource.entryKey="wrong";',
    'null entry and missing capture key': _kNullEntryMutation,
    'wrong URL': 'request.currentSsrSource.harnessURL="file:///foreign";',
    'wrong tuple': 'request.currentSsrSource.source.nativeAdapterId="foreign";',
    'wrong count': 'request.currentSsrSource.completeRawSlotCount++;',
    'false original slot':
        'request.currentSsrSource.currentRaw.slotPresence[0]=false;',
    'anonymous NBSP':
        'root.childNodes.push({nodeType:3,data:"\u00a0",parentNode:root});',
    'duplicate owner': 'capture.childNodes.push(root);',
  };
  for (final mutation in beforeCss.entries) {
    for (final combined in [false, true]) {
      test('${mutation.key} rejects before CSS combined=$combined', () async {
        final result = await _sample(
          await _actual('typography-display'),
          combined: combined,
          mutation: mutation.value,
        );
        expect(result['cssReads'], 0);
        if (combined) {
          expect(result['error'], isNotNull);
        } else {
          expect((result['observed']! as Map)['status'], 'incomplete');
        }
      });
    }
  }

  test('combined legacy then box keeps the same outer allocation', () async {
    final result = await _sample(
      await _actual('typography-display'),
      combined: true,
    );
    expect(result['error'], isNull);
    expect(result['cssReads'], greaterThan(1));
    final box = (result['observed']! as Map)['box']! as Map;
    expect(box['status'], 'source-complete');
    expect(box['value'], [0, 5, 7.25, 11]);
  });

  for (final mutation in <String, String>{
    'owner attributes': 'root.setAttribute("changed","yes");',
    'URL': 'location.href="file:///changed";',
    'request receipt replacement':
        'request.currentSsrSource={...request.currentSsrSource};',
    'request source replacement': 'request.source={...request.source};',
    'request selector': 'request.selector="foreign";',
    'same-shape frontier replacement': '''
root.childNodes=root.childNodes.map(n=>{
 if(n.nodeType!==1)return n;
 const clone=n.cloneNode(true);
 n.parentNode=null;n.parentElement=null;n.isConnected=false;
 return clone;
});
''',
  }.entries) {
    test('${mutation.key} during legacy CSS cannot return results', () async {
      final result = await _sample(
        await _actual('typography-display'),
        combined: true,
        mutation:
            '''
const originalStyle=getComputedStyle;
global.getComputedStyle=node=>{const css=originalStyle(node);${mutation.value}return css;};
''',
      );
      expect(result['cssReads'], greaterThan(0));
      expect(result['error'], contains('TEXT_SHOWCASE_BINDING_CHANGED'));
    });
  }

  test('mutation during padding property read cannot credit a value', () async {
    final result = await _sample(
      await _actual('typography-display'),
      mutation: '''
const originalStyle=getComputedStyle;
global.getComputedStyle=node=>{const css=originalStyle(node);
Object.defineProperty(css,'paddingLeft',{get(){root.setAttribute('changed','yes');return '11px';}});return css;};
''',
    );
    final box = result['observed']! as Map;
    expect(box['status'], 'incomplete');
    expect(box['error'], 'TEXT_SHOWCASE_BINDING_CHANGED_DURING_CSS_READ');
    expect(box.containsKey('value'), false);
  });

  test('post-box change cannot return either combined result', () async {
    final result = await _sample(
      await _actual('typography-display'),
      combined: true,
      boxScript:
          '''
(request)=>{const result=($boxPaddingObservationScript)(request);
root.setAttribute('changed-after-box','yes');return result;}
''',
    );
    expect(result['cssReads'], greaterThan(1));
    expect(result['observed'], isNull);
    expect(
      result['error'],
      contains('TEXT_SHOWCASE_BINDING_CHANGED_DURING_BOX_READ'),
    );
  });

  test(
    'foreign interiors remain opaque to the new allocation binding',
    () async {
      final result = await _sample(
        await _actual('rich'),
        mutation: '''
root.children[0].childNodes.push({nodeType:3,data:'opaque changed text',parentNode:root.children[0]});
''',
      );
      expect(result['error'], isNull);
      expect((result['observed']! as Map)['status'], 'source-complete');
    },
  );

  test('production requires an exact declared root source', () {
    final entry = _entry('typography-display', 'light');
    expect(TextShowcaseSsrSource.forEntry(entry), isNotNull);
    final json = entry.toJson();
    ((json['probes']! as List).single as Map).remove('boxObservationSource');
    final undeclared = MatrixEntry.fromJson(json);
    expect(TextShowcaseSsrSource.forEntry(undeclared), isNull);
    expect(requiredTextShowcaseSsrKind(undeclared), isNull);
  });

  for (final field in [
    'schemaVersion',
    'quantityId',
    'nativeAdapterId',
    'webAdapterId',
  ]) {
    test('production rejects foreign $field', () {
      final json = _entry('typography-display', 'light').toJson();
      final probe = (json['probes']! as List).single as Map;
      final tuple = probe['boxObservationSource']! as Map;
      tuple[field] = field == 'schemaVersion' ? 2 : 'foreign';
      expect(
        () => TextShowcaseSsrSource.forEntry(MatrixEntry.fromJson(json)),
        throwsStateError,
      );
    });
  }

  test('the Text tuple cannot be borrowed by another recipe or stage', () {
    for (final change in ['component', 'variant', 'role']) {
      final json = _entry('typography-display', 'light').toJson();
      if (change == 'component') json['component'] = 'icon';
      if (change == 'variant') json['variant'] = 'default';
      if (change == 'role') {
        ((json['probes']! as List).single as Map)['role'] = 'stage';
      }
      expect(
        () => TextShowcaseSsrSource.forEntry(MatrixEntry.fromJson(json)),
        throwsStateError,
      );
    }
  });
}
