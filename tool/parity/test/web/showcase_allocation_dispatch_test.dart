import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/computed_style_probe.dart';
import '../../src/web/showcase_allocation_ssr_source.dart';
import '../../src/web/web_capture_backend.dart';

// The literal wire assertion matches the independently prepared RED tuple.
const BoxObservationSourceSpec _kAllocation =
    BoxObservationSourceSpec.showcaseAllocationHost;

const _kPrototypeReceiptMutation =
    'request.currentSsrSource.kind='
    '"canonical-ssr-showcase-allocation-prototype-v1";';
const _kNullEntryMutation =
    'request.currentSsrSource.entryKey=null;'
    'capture.removeAttribute("data-parity-key");';

const _kRecipes = <(String, String)>[
  ('progress', 'tone'),
  ('chat', 'default'),
  ('chat', 'plain'),
  ('chat', 'tail-corner'),
  ('chat', 'tail-top'),
  ('chip', 'selected'),
  ('chip', 'variant'),
  ('chip', 'shape'),
  ('chip', 'cast-motion'),
  ('chip', 'prefix'),
  ('skeleton', 'default'),
  ('step-item', 'default'),
  ('card-image', 'default'),
  ('hidden', 'default'),
  ('window', 'default'),
  ('draggable-panel', 'default'),
  ('draggable-panel', 'outside'),
  ('scrollable-client', 'default'),
  ('table', 'scrollable'),
  ('mockup-foldable', 'angle'),
  ('mockup-foldable', 'default'),
  ('scaffold', 'default'),
  ('bottom-action-bar', 'scaffold'),
  ('scrollview', 'default'),
];

MatrixEntry _entry(
  (String, String) recipe,
  String theme, {
  String style = 'defaultStyle',
}) => MatrixEntry.fromJson({
  'component': recipe.$1,
  'variant': recipe.$2,
  'theme': theme,
  'surfaceStyle': style,
  'tier': 't2',
  'probes': captureProbes(
    key: '${recipe.$1}-${recipe.$2}-$theme-$style',
    component: recipe.$1,
    variant: recipe.$2,
    flutterClassName: 'closed-current-source',
  ).map((p) => p.toJson()).toList(),
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
Future<_Actual> _actual((String, String) recipe, [String theme = 'light']) =>
    _cache.putIfAbsent('${recipe.$1}/${recipe.$2}/$theme', () async {
      final entry = _entry(recipe, theme);
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
  bool separateSelectors = false,
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
const layoutSelector=${separateSelectors ? "':is('+selector+')'" : 'selector'};
global.document={querySelector:sel=>sel===selector||sel===layoutSelector?root:null,
 querySelectorAll:sel=>sel===selector||sel===layoutSelector?[root]:[],
 createTreeWalker:node=>{const queue=[];const visit=n=>{for(const c of n.childNodes){if(c.nodeType===3)queue.push(c);else if(c.nodeType===1)visit(c);}};visit(node);return {nextNode:()=>queue.shift()||null};}};
const originalRootNodes=root.childNodes.slice(),originalCaptureNodes=capture.childNodes.slice();
const originalRootAttributes=JSON.stringify(root.attributes),originalCaptureAttributes=JSON.stringify(capture.attributes);
const request={requested:true,selector,layoutSelector,
 source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
 currentSsrSource:${jsonEncode(receipt)},
 requiredCurrentSsrKind:${jsonEncode(requiredShowcaseAllocationSsrKind(actual.entry))}};
$mutation
let observed,error;
try{observed=JSON.parse((${combined
          ? boxScript == null
                ? computedStyleAndBoxObservationScript
                : sourceValidatedComputedStyleAndBoxScript(boxScript)
          : boxPaddingObservationScript})(request));}
catch(e){error=String(e);}
const sameNodes=(actual,held)=>actual.length===held.length&&held.every((node,i)=>actual[i]===node);
const originalDOMUnchanged=root.isConnected&&capture.isConnected&&root.parentElement===capture&&root.parentNode===capture&&
 sameNodes(root.childNodes,originalRootNodes)&&sameNodes(capture.childNodes,originalCaptureNodes)&&
 JSON.stringify(root.attributes)===originalRootAttributes&&JSON.stringify(capture.attributes)===originalCaptureAttributes;
console.log(JSON.stringify({observed,error,cssReads,originalDOMUnchanged}));
''';
  // The combined probe exceeds Linux's per-argument limit. Preserve the exact
  // generated program in an owned temporary file instead of passing node -e.
  final directory = await Directory.systemTemp.createTemp('showcase24-node-');
  try {
    final script = File('${directory.path}/sample.cjs');
    await script.writeAsString(program);
    final result = await Process.run(
      Platform.environment['PARITY_NODE'] ?? 'node',
      [script.path],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
  } finally {
    await directory.delete(recursive: true);
  }
}

void main() {
  for (final duringBox in [false, true]) {
    test(
      'registry width held selectors remain unique during '
      '${duringBox ? 'box' : 'legacy'} CSS',
      () async {
        const mutateQuery = '''
const prior=getComputedStyle;
global.getComputedStyle=node=>{const css=prior(node);
 Object.defineProperty(css,'paddingTop',{get(){
 document.querySelectorAll=()=>[root,root];return '0px';}});return css;};
''';
        final result = await _sample(
          await _actual(('mockup-foldable', 'default')),
          combined: true,
          mutation: duringBox ? '' : mutateQuery,
          boxScript: duringBox
              ? '(request)=>{\n'
                    '$mutateQuery\n'
                    'return ($boxPaddingObservationScript)(request);\n'
                    '}'
              : null,
        );
        expect(
          result['error'],
          contains('SHOWCASE_ALLOCATION_BINDING_CHANGED'),
        );
        expect(result['originalDOMUnchanged'], true);
      },
    );
  }

  test(
    'declaration and factory cover every actual surface-style enum value',
    () {
      for (final style in CoreSurfaceStyleId.values) {
        for (final recipe in _kRecipes) {
          for (final theme in ['light', 'dark']) {
            final entry = _entry(recipe, theme, style: style.name);
            expect(
              entry.probes.single.boxObservationSource,
              BoxObservationSourceSpec.showcaseAllocationHost,
            );
            expect(ShowcaseAllocationSsrSource.forEntry(entry), isNotNull);
            expect(
              requiredShowcaseAllocationSsrKind(entry),
              'canonical-ssr-showcase-allocation-v1',
            );
          }
        }
      }
    },
  );
  test(
    'repeated nonempty source Components preserve every mounted occurrence',
    () async {
      final actual = await _actual(('chip', 'variant'));
      final raw = actual.receipt['currentRaw']! as Map;
      final slots = raw['opaqueSlots']! as List;
      expect(slots, hasLength(11));
      expect(
        slots.where((s) => (s as Map)['sourceAliasOf'] != null),
        isNotEmpty,
      );
      for (var i = 0; i < slots.length; i++) {
        final slot = slots[i] as Map;
        expect(slot['seat'], i);
        final alias = slot['sourceAliasOf'];
        if (alias != null) {
          expect(alias, inInclusiveRange(0, i - 1));
          expect((slots[alias as int] as Map)['sourceAliasOf'], isNull);
          expect(slot['nodes'], isNotEmpty);
        }
      }
      final sampled = await _sample(actual);
      expect(sampled['error'], isNull);
      expect((sampled['observed']! as Map)['status'], 'source-complete');
    },
  );
  for (final mutation in <String, String>{
    'dropped seat': 'request.currentSsrSource.currentRaw.opaqueSlots.pop();',
    'reordered seat records':
        'request.currentSsrSource.currentRaw.opaqueSlots.reverse();',
    'duplicate physical node': 'root.childNodes.push(root.childNodes[0]);',
    'extra repeated seat':
        'request.currentSsrSource.currentRaw.opaqueSlots.push('
        'request.currentSsrSource.currentRaw.opaqueSlots[0]);',
    'self source alias':
        'request.currentSsrSource.currentRaw.opaqueSlots[0].sourceAliasOf=0;',
  }.entries) {
    test('${mutation.key} rejects before any CSS credit', () async {
      final result = await _sample(
        await _actual(('chip', 'variant')),
        mutation: mutation.value,
      );
      expect(result['cssReads'], 0);
      expect((result['observed']! as Map)['status'], 'incomplete');
    });
  }
  test(
    'the remaining twelve product roots do not inherit this declaration',
    () {
      for (final recipe in [
        ('progress', 'default'),
        ('progress', 'labelled'),
        ('progress', 'segments'),
        ('progress', 'indeterminate'),
        ('progress', 'radial'),
        ('accordion', 'default'),
      ]) {
        final entry = _entry(recipe, 'light');
        expect(entry.probes.single.boxObservationSource, isNull);
        expect(ShowcaseAllocationSsrSource.forEntry(entry), isNull);
        final wire = entry.toJson();
        ((wire['probes']! as List).single as Map)['boxObservationSource'] =
            BoxObservationSourceSpec.showcaseAllocationHost.toJson();
        expect(
          () =>
              ShowcaseAllocationSsrSource.forEntry(MatrixEntry.fromJson(wire)),
          throwsStateError,
        );
      }
    },
  );

  test('declared allocation reaches actual SSR recorder', () async {
    const key = 'chat-default-light-defaultStyle';
    final entry = MatrixEntry.fromJson({
      'component': 'chat',
      'variant': 'default',
      'theme': 'light',
      'surfaceStyle': 'defaultStyle',
      'tier': 't2',
      'probes': [
        rootProbeSpec(
          key: key,
          flutterClassName: 'ChatDefaultExample',
          boxObservationSource: _kAllocation,
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
    expect(receipt['kind'], 'canonical-ssr-showcase-allocation-v1');
    expect(receipt['entryKey'], key);
    expect(receipt['source'], {
      'schemaVersion': 1,
      'logicalUnitId': 'classic-compound-showcase-allocation-host',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'classic-compound-showcase-allocation-host-v1',
      'webAdapterId': 'classic-compound-showcase-allocation-host-v1',
    });
    expect(receipt['rawOrderFromPublicProducerLists'], true);
    expect(receipt['completeRawSlotCount'], 3);
    expect(
      (receipt['currentRaw']! as Map)['kind'],
      'current-showcase-allocation-raw-v1',
    );
  });

  for (final recipe in _kRecipes) {
    for (final theme in ['light', 'dark']) {
      test('$recipe/$theme declared backend and padding dispatcher', () async {
        final actual = await _actual(recipe, theme);
        expect(
          actual.entry.probes.single.boxObservationSource,
          BoxObservationSourceSpec.showcaseAllocationHost,
        );
        expect(actual.receipt.keys.length, 6);
        expect(actual.receipt['kind'], 'canonical-ssr-showcase-allocation-v1');
        expect(
          requiredShowcaseAllocationSsrKind(actual.entry),
          'canonical-ssr-showcase-allocation-v1',
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
          await _actual(('chat', 'default')),
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
      await _actual(('chat', 'default')),
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
        await _actual(('chat', 'default')),
        combined: true,
        mutation:
            '''
const originalStyle=getComputedStyle;
global.getComputedStyle=node=>{const css=originalStyle(node);${mutation.value}return css;};
''',
      );
      expect(result['cssReads'], greaterThan(0));
      expect(result['error'], contains('SHOWCASE_ALLOCATION_BINDING_CHANGED'));
    });
  }

  test('mutation during padding property read cannot credit a value', () async {
    final result = await _sample(
      await _actual(('chat', 'default')),
      mutation: '''
const originalStyle=getComputedStyle;
global.getComputedStyle=node=>{const css=originalStyle(node);
Object.defineProperty(css,'paddingLeft',{get(){root.setAttribute('changed','yes');return '11px';}});return css;};
''',
    );
    final box = result['observed']! as Map;
    expect(box['status'], 'incomplete');
    expect(box['error'], 'SHOWCASE_ALLOCATION_BINDING_CHANGED_DURING_CSS_READ');
    expect(box.containsKey('value'), false);
  });

  test('post-box change cannot return either combined result', () async {
    final result = await _sample(
      await _actual(('chat', 'default')),
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
      contains('SHOWCASE_ALLOCATION_BINDING_CHANGED_DURING_BOX_READ'),
    );
  });

  test(
    'foreign interiors remain opaque to the new allocation binding',
    () async {
      final result = await _sample(
        await _actual(('chip', 'variant')),
        mutation: '''
root.children[0].childNodes.push({nodeType:3,data:'opaque changed text',parentNode:root.children[0]});
''',
      );
      expect(result['error'], isNull);
      expect((result['observed']! as Map)['status'], 'source-complete');
    },
  );

  test(
    'distinct selectors resolve to the same frozen original owner',
    () async {
      final result = await _sample(
        await _actual(('chat', 'default')),
        separateSelectors: true,
      );
      expect(result['error'], isNull);
      expect(result['cssReads'], 1);
      expect(result['originalDOMUnchanged'], true);
      expect((result['observed']! as Map)['status'], 'source-complete');
    },
  );

  // Only query resolution changes: the original owner/capture stay attached,
  // with exactly their original attributes and top-node identities/order.
  for (final target in ['selector', 'layoutSelector']) {
    for (final resolution in ['duplicate', 'retarget', 'invalid selector']) {
      final replacement = switch (resolution) {
        'duplicate' => 'return [root,alternateRoot];',
        'retarget' => 'return [alternateRoot];',
        _ => 'throw new SyntaxError("invalid selector");',
      };
      final setup =
          '''
const alternateCapture=capture.cloneNode(true),alternateRoot=alternateCapture.children[0];
const originalQueryAll=document.querySelectorAll;
const changeResolution=()=>{document.querySelectorAll=sel=>{
 if(sel===$target){$replacement}return originalQueryAll(sel);
};};
''';
      test(
        '$target $resolution during legacy read rejects held owner',
        () async {
          final result = await _sample(
            await _actual(('chat', 'default')),
            combined: true,
            separateSelectors: true,
            mutation:
                '''
$setup
const originalStyle=getComputedStyle;
let changed=false;
global.getComputedStyle=node=>{const css=originalStyle(node);
 if(!changed){changed=true;changeResolution();}return css;};
''',
          );
          expect(result['originalDOMUnchanged'], true);
          expect(result['cssReads'], greaterThan(0));
          expect(result['observed'], isNull);
          expect(
            result['error'],
            contains('SHOWCASE_ALLOCATION_BINDING_CHANGED_DURING_LEGACY_READ'),
          );
        },
      );
      test('$target $resolution after box read rejects both results', () async {
        final result = await _sample(
          await _actual(('chat', 'default')),
          combined: true,
          separateSelectors: true,
          mutation: setup,
          boxScript:
              '''
(request)=>{const result=($boxPaddingObservationScript)(request);
changeResolution();return result;}
''',
        );
        expect(result['originalDOMUnchanged'], true);
        expect(result['cssReads'], greaterThan(1));
        expect(result['observed'], isNull);
        expect(
          result['error'],
          contains('SHOWCASE_ALLOCATION_BINDING_CHANGED_DURING_BOX_READ'),
        );
      });
      test(
        '$target $resolution during box CSS cannot credit padding',
        () async {
          final result = await _sample(
            await _actual(('chat', 'default')),
            separateSelectors: true,
            mutation:
                '''
$setup
const originalStyle=getComputedStyle;
global.getComputedStyle=node=>{const css=originalStyle(node);
Object.defineProperty(css,'paddingLeft',{get(){changeResolution();return '11px';}});return css;};
''',
          );
          expect(result['originalDOMUnchanged'], true);
          expect(result['cssReads'], 1);
          final box = result['observed']! as Map;
          expect(box['status'], 'incomplete');
          expect(
            box['error'],
            'SHOWCASE_ALLOCATION_BINDING_CHANGED_DURING_CSS_READ',
          );
          expect(box.containsKey('value'), false);
        },
      );
    }
  }

  test('production grants no source receipt to an undeclared root', () {
    final entry = _entry(('chat', 'default'), 'light');
    expect(ShowcaseAllocationSsrSource.forEntry(entry), isNotNull);
    final json = entry.toJson();
    ((json['probes']! as List).single as Map).remove('boxObservationSource');
    final undeclared = MatrixEntry.fromJson(json);
    expect(ShowcaseAllocationSsrSource.forEntry(undeclared), isNull);
    expect(requiredShowcaseAllocationSsrKind(undeclared), isNull);
  });

  for (final field in [
    'schemaVersion',
    'quantityId',
    'nativeAdapterId',
    'webAdapterId',
  ]) {
    test('production rejects foreign $field', () {
      final json = _entry(('chat', 'default'), 'light').toJson();
      final probe = (json['probes']! as List).single as Map;
      final tuple = probe['boxObservationSource']! as Map;
      tuple[field] = field == 'schemaVersion' ? 2 : 'foreign';
      expect(
        () => ShowcaseAllocationSsrSource.forEntry(MatrixEntry.fromJson(json)),
        throwsStateError,
      );
    });
  }

  test(
    'the allocation tuple cannot be borrowed by another recipe or stage',
    () {
      for (final change in ['component', 'variant', 'role']) {
        final json = _entry(('chat', 'default'), 'light').toJson();
        if (change == 'component') json['component'] = 'icon';
        if (change == 'variant') json['variant'] = 'unreviewed';
        if (change == 'role') {
          ((json['probes']! as List).single as Map)['role'] = 'stage';
        }
        expect(
          () =>
              ShowcaseAllocationSsrSource.forEntry(MatrixEntry.fromJson(json)),
          throwsStateError,
        );
      }
    },
  );
}
