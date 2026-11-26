import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/navigation_trigger_ssr_source.dart';
import '../../src/web/web_capture_backend.dart';

typedef _Rendered = ({
  MatrixEntry entry,
  Map<String, Object?> witness,
  Map<String, Object?> tree,
});

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

Map<String, Object?> _tree(dom.Element element) => {
  'tag': element.namespaceUri == 'http://www.w3.org/1999/xhtml'
      ? element.localName!.toUpperCase()
      : element.localName,
  'namespaceURI': element.namespaceUri,
  'localName': element.localName,
  'attributes': {
    for (final a in element.attributes.entries) a.key.toString(): a.value,
  },
  'children': element.children.map(_tree).toList(),
};

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
  const attributes = {...raw.attributes};
  const names = (attributes.class || '').split(/\\s+/).filter(Boolean);
  names.contains = value => names.includes(value);
  const node = {tagName:raw.tag, namespaceURI:raw.namespaceURI,
    localName:raw.localName, classList:names, parentElement:null,
    isConnected:true, getAttribute:name=>attributes[name]??null,
    hasAttribute:name=>Object.hasOwn(attributes,name),
    children:raw.children.map(from)};
  for (const child of node.children) child.parentElement=node;
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
  for (final (component, variant, source, slots, rootOwner) in [
    (
      'theme-controller',
      'default',
      BoxObservationSourceSpec.themeControllerOptionGridLayoutHost,
      0,
      true,
    ),
    (
      'tracker',
      'default',
      BoxObservationSourceSpec.trackerSegmentRowLayoutHost,
      0,
      true,
    ),
    (
      'bottom-sheet',
      'default',
      BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
      4,
      true,
    ),
    (
      'bottom-sheet',
      'close',
      BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
      4,
      true,
    ),
    (
      'swiper',
      'default',
      BoxObservationSourceSpec.swiperTriggerLayoutHost,
      2,
      false,
    ),
    (
      'swiper',
      'sheet',
      BoxObservationSourceSpec.swiperTriggerLayoutHost,
      2,
      false,
    ),
    ('diff', 'default', BoxObservationSourceSpec.diffViewerLayoutHost, 4, true),
    ('diff', 'text', BoxObservationSourceSpec.diffViewerLayoutHost, 4, true),
    (
      'command-search',
      'default',
      BoxObservationSourceSpec.commandSearchTriggerContentInset,
      2,
      false,
    ),
    (
      'navigation-bar',
      'default',
      BoxObservationSourceSpec.navigationBarItemsContentInset,
      10,
      true,
    ),
    (
      'navigation-bar',
      'rail',
      BoxObservationSourceSpec.navigationBarItemsContentInset,
      10,
      true,
    ),
    (
      'navigation-bar',
      'sidebar',
      BoxObservationSourceSpec.navigationBarItemsContentInset,
      16,
      true,
    ),
    ('dock', 'default', BoxObservationSourceSpec.dockBarContentInset, 3, true),
  ]) {
    test('actual SSR producer reaches sampler: $component/$variant', () async {
      final actual = await _actual(component, variant, source);
      expect(
        actual.witness['kind'],
        BoxObservationSourceSpec.dataOverlayLayoutFrames.contains(source)
            ? 'canonical-ssr-data-overlay-v1'
            : 'canonical-ssr-navigation-trigger-v1',
      );
      expect(actual.witness['entryKey'], actual.entry.key);
      expect(actual.witness['source'], source.toJson());
      expect(actual.witness['completeRawSlotCount'], slots);
      expect(actual.witness['rawOrderFromPublicProducerLists'], isTrue);
      final sampled = await _sample(actual);
      final observed = sampled['observed']! as Map;
      expect(observed['status'], 'source-complete');
      expect(observed['sourceUnitValidated'], isTrue);
      expect(observed['value'], [11, 13, 17, 19]);
      expect(observed['ownerIsLayoutRoot'], rootOwner);
      expect(observed['registryIsLayoutRoot'], isTrue);
      expect(observed['canonicalComparisonEligible'], isFalse);
      expect(sampled['cssReads'], 1);
    });
  }
  test('sidebar witness contains actual labels, divider and footer', () async {
    final actual = await _actual(
      'navigation-bar',
      'sidebar',
      BoxObservationSourceSpec.navigationBarItemsContentInset,
    );
    final raw = actual.witness['currentRaw']! as Map;
    expect(raw['footerSupplied'], isTrue);
    expect(raw['sidebar'], isTrue);
    expect(raw['vertical'], isTrue);
    expect((raw['items']! as List).map((item) => (item as Map)['kind']), [
      'label',
      'item',
      'item',
      'divider',
      'label',
      'item',
      'item',
    ]);
  });
  for (final (mutation, expected) in <(String, String)>[
    ('request.currentSsrSource=null;', 'MISSING_ACTUAL_SSR_BOX_SOURCE'),
    (
      "request.currentSsrSource={error:'unproved source'};",
      'MISSING_ACTUAL_SSR_BOX_SOURCE',
    ),
    (
      "request.currentSsrSource.entryKey='other-entry';",
      'SSR_BOX_INPUT_CHANGED',
    ),
    ("location.href='file:///other-harness.html';", 'SSR_BOX_INPUT_CHANGED'),
    ('request.currentSsrSource.source={};', 'SSR_BOX_SOURCE_CHANGED'),
    (
      'request.currentSsrSource.currentRaw=null;',
      'NAVIGATION_TRIGGER_CURRENT_RAW_WITNESS_REQUIRED',
    ),
  ]) {
    test('unbound current source is held: $expected/$mutation', () async {
      final actual = await _actual(
        'command-search',
        'default',
        BoxObservationSourceSpec.commandSearchTriggerContentInset,
      );
      final sampled = await _sample(actual, mutation: mutation);
      expect((sampled['observed']! as Map)['status'], 'incomplete');
      expect((sampled['observed']! as Map)['error'], expected);
      expect(sampled['cssReads'], 0);
    });
  }
  test('source tuple cannot promote another canonical recipe', () {
    expect(
      () => NavigationTriggerSsrSource.forEntry(
        _entry(
          'dock',
          'default',
          BoxObservationSourceSpec.commandSearchTriggerContentInset,
        ),
      ),
      throwsStateError,
    );
    expect(
      () => NavigationTriggerSsrSource.forEntry(
        _entry('dock', 'chain', BoxObservationSourceSpec.dockBarContentInset),
      ),
      throwsStateError,
    );
  });
}
