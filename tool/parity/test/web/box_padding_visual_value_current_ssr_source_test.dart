import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/visual_value_ssr_source.dart';
import '../../src/web/web_capture_backend.dart';

typedef _Rendered = ({
  MatrixEntry entry,
  Map<String, Object?> witness,
  Map<String, Object?> tree,
});

const _foreignCaptureTextInsertion =
    "capture.childNodes.push({nodeType:3,data:'foreign',"
    'parentNode:capture,parentElement:capture,isConnected:true});';

MatrixEntry _entry(
  String component,
  String variant,
  BoxObservationSourceSpec source,
) {
  final key = '$component-$variant-light-defaultStyle';
  return MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': 'light',
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': [
      rootProbeSpec(
        key: key,
        flutterClassName: 'source-only',
        boxObservationSource: source,
      ).toJson(),
    ],
  });
}

Map<String, Object?> _tree(dom.Node node) {
  if (node is dom.Text) return {'nodeType': 3, 'data': node.data};
  if (node is! dom.Element) return {'nodeType': node.nodeType};
  return {
    'nodeType': 1,
    'tag': node.namespaceUri == 'http://www.w3.org/1999/xhtml'
        ? node.localName!.toUpperCase()
        : node.localName,
    'namespaceURI': node.namespaceUri,
    'localName': node.localName,
    'attributes': {
      for (final a in node.attributes.entries) a.key.toString(): a.value,
    },
    'childNodes': node.nodes.map(_tree).toList(),
  };
}

final _cache = <String, Future<_Rendered>>{};
Future<_Rendered> _actual(
  String component,
  String variant,
  BoxObservationSourceSpec source,
) => _cache.putIfAbsent(
  '$component/$variant',
  () async {
    final entry = _entry(component, variant, source);
    var calls = 0;
    Map<String, Object?>? witness;
    final body = await renderCaptureBodyHtml(
      entry,
      onCurrentBoxSource: (current) {
        calls++;
        witness = current;
      },
    );
    expect(calls, 1);
    expect(witness, isNotNull);
    expect(witness!['error'], isNull);
    final capture = html
        .parseFragment(body)
        .querySelectorAll('[data-parity-key]')
        .single;
    return (entry: entry, witness: witness!, tree: _tree(capture));
  },
);

Future<Map<String, Object?>> _sample(
  _Rendered actual, {
  String mutation = '',
}) async {
  const url = 'file:///owned/current-source.html';
  final receipt = {...actual.witness, 'harnessURL': url};
  final result = await Process.run('node', [
    '-e',
    '''
const from = raw => {
  if(raw.nodeType!==1)return {nodeType:raw.nodeType,data:raw.data,
    parentElement:null,parentNode:null,isConnected:true};
  const attributes = {...raw.attributes};
  const names = (attributes.class || '').split(/\\s+/).filter(Boolean);
  names.contains = value => names.includes(value);
  const node = {nodeType:1,tagName:raw.tag, namespaceURI:raw.namespaceURI,
    localName:raw.localName, classList:names, parentElement:null,parentNode:null,
    isConnected:true, getAttribute:name=>attributes[name]??null,
    hasAttribute:name=>Object.hasOwn(attributes,name),
    childNodes:raw.childNodes.map(from)};
  node.children=node.childNodes.filter(child=>child.nodeType===1);
  for (const child of node.childNodes){child.parentElement=node;child.parentNode=node;}
  node.contains=other=>node===other || node.children.some(c=>c.contains(other));
  for (const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
    Object.defineProperty(node,name,{get(){throw Error('Geometry used for owner selection');}});
  return node;
};
const capture=from(${jsonEncode(actual.tree)});
const root=capture.children[0];
global.document={querySelectorAll:()=>[root]};
global.location={href:${jsonEncode(url)}};
let cssReads=0;
global.getComputedStyle=owner=>{cssReads++;return {display:'block',
  paddingTop:'11px',paddingRight:'13px',paddingBottom:'17px',paddingLeft:'19px'};};
const request={requested:true,selector:'#current',layoutSelector:'#current',
  source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
  currentSsrSource:${jsonEncode(receipt)}};
$mutation
const observed=JSON.parse(($boxPaddingObservationScript)(request));
console.log(JSON.stringify({observed,cssReads}));
''',
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
}

void main() {
  for (final (component, variant, source, slots) in [
    ('icon', 'default', BoxObservationSourceSpec.iconVisualFrame, 0),
    ('icon', 'search', BoxObservationSourceSpec.iconVisualFrame, 0),
    ('icon', 'favorite', BoxObservationSourceSpec.iconVisualFrame, 0),
    (
      'number-ticker',
      'default',
      BoxObservationSourceSpec.numberTickerTextLayoutHost,
      1,
    ),
    (
      'skeleton',
      'text',
      BoxObservationSourceSpec.skeletonTextLinesLayoutHost,
      0,
    ),
    (
      'countdown',
      'default',
      BoxObservationSourceSpec.countdownValueLayoutHost,
      0,
    ),
  ]) {
    test(
      'original visual value SSR reaches CSS sampler: $component/$variant',
      () async {
        final actual = await _actual(component, variant, source);
        expect(actual.witness['kind'], 'canonical-ssr-visual-value-v1');
        expect(actual.witness['entryKey'], actual.entry.key);
        expect(actual.witness['source'], source.toJson());
        expect(actual.witness['completeRawSlotCount'], slots);
        expect(actual.witness['rawOrderFromPublicProducerLists'], isTrue);
        final sampled = await _sample(actual);
        final observed = sampled['observed']! as Map;
        expect(observed['status'], 'source-complete');
        expect(observed['sourceUnitValidated'], isTrue);
        // Native absence never substitutes for the actual CSS read.
        expect(observed['value'], [11, 13, 17, 19]);
        expect(observed['ownerIsLayoutRoot'], isTrue);
        expect(observed['registryIsLayoutRoot'], isTrue);
        expect(observed['canonicalComparisonEligible'], isFalse);
        expect(sampled['cssReads'], 1);
      },
    );
  }
  for (final (mutation, expected) in <(String, String)>[
    ('request.currentSsrSource=null;', 'MISSING_ACTUAL_SSR_BOX_SOURCE'),
    (
      "request.currentSsrSource.kind='foreign';",
      'MISSING_ACTUAL_SSR_BOX_SOURCE',
    ),
    (
      "request.currentSsrSource.entryKey='other-entry';",
      'SSR_BOX_INPUT_CHANGED',
    ),
    ("location.href='file:///other-harness.html';", 'SSR_BOX_INPUT_CHANGED'),
    ('request.currentSsrSource.source={};', 'SSR_BOX_SOURCE_CHANGED'),
    (
      'delete request.currentSsrSource.completeRawSlotCount;',
      'VISUAL_VALUE_CURRENT_HEADER_CHANGED',
    ),
    (
      'request.currentSsrSource.completeRawSlotCount=77;',
      'VISUAL_VALUE_CURRENT_HEADER_CHANGED',
    ),
    (
      "request.currentSsrSource.completeRawSlotCount='1';",
      'VISUAL_VALUE_CURRENT_HEADER_CHANGED',
    ),
    (
      'delete request.currentSsrSource.rawOrderFromPublicProducerLists;',
      'VISUAL_VALUE_CURRENT_HEADER_CHANGED',
    ),
    (
      'request.currentSsrSource.rawOrderFromPublicProducerLists=false;',
      'VISUAL_VALUE_CURRENT_HEADER_CHANGED',
    ),
    (
      'request.currentSsrSource.extraField=true;',
      'VISUAL_VALUE_CURRENT_HEADER_CHANGED',
    ),
    (
      'request.currentSsrSource.currentRaw=null;',
      'VISUAL_VALUE_CURRENT_RAW_REQUIRED',
    ),
    (
      "request.currentSsrSource.currentRaw.generatedTree.localName='foreign';",
      'VISUAL_VALUE_ACTUAL_GENERATED_TREE_CHANGED',
    ),
    (
      _foreignCaptureTextInsertion,
      'VISUAL_VALUE_CAPTURE_OUTPUT_CHANGED',
    ),
  ]) {
    test(
      'unbound visual value source cannot read CSS: $expected/$mutation',
      () async {
        final actual = await _actual(
          'number-ticker',
          'default',
          BoxObservationSourceSpec.numberTickerTextLayoutHost,
        );
        final sampled = await _sample(actual, mutation: mutation);
        expect((sampled['observed']! as Map)['status'], 'incomplete');
        expect((sampled['observed']! as Map)['error'], expected);
        expect(sampled['cssReads'], 0);
      },
    );
  }
  test(
    'visual value source tuple cannot promote an unrelated construction',
    () {
      for (final (component, variant, source) in [
        (
          'skeleton',
          'default',
          BoxObservationSourceSpec.skeletonTextLinesLayoutHost,
        ),
        (
          'number-ticker',
          'builder',
          BoxObservationSourceSpec.numberTickerTextLayoutHost,
        ),
        ('countdown', 'default', BoxObservationSourceSpec.iconVisualFrame),
      ]) {
        expect(
          () =>
              VisualValueSsrSource.forEntry(_entry(component, variant, source)),
          throwsStateError,
        );
      }
    },
  );
}
