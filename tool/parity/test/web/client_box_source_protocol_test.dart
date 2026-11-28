import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/client_box_source_protocol.dart';
import '../../src/web/visual_value_web_raw_source.dart';

const _kCaptureForeignText =
    "capture.childNodes.push({nodeType:3,data:'foreign',"
    'isConnected:true,parentNode:capture,childNodes:[]});';
const _kInnerForeignText =
    r"inner.childNodes.push({nodeType:3,data:'\u00a0',"
    'isConnected:true,parentNode:inner,childNodes:[]});';
const _kInnerForeignComment =
    'inner.childNodes.push({nodeType:8,isConnected:true,'
    'parentNode:inner,childNodes:[]});';

MatrixEntry _entry({
  String component = 'number-ticker',
  String theme = 'light',
  BoxObservationSourceSpec? source,
}) => MatrixEntry.fromJson({
  'component': component,
  'variant': 'default',
  'theme': theme,
  'surfaceStyle': 'defaultStyle',
  'tier': 't2',
  'probes': [
    rootProbeSpec(
      key: '$component-default-$theme-defaultStyle',
      flutterClassName: 'source-only',
      boxObservationSource:
          source ?? BoxObservationSourceSpec.numberTickerTextLayoutHost,
    ).toJson(),
  ],
});

/// Protocol mocks exercise JS identity/header guards, not a real Jaspr mount.
/// The separately authored browser suite is required for mount authority.
Future<Map<String, Object?>> _sample({
  String mutation = '',
  String handlerMutation = '',
}) async {
  final descriptor = clientBoxSourceDescriptor(
    _entry(),
    additiveBoxObservations: true,
  )!;
  final nodeProgram =
      '''
const node=(tag,children=[])=>{
  const n={nodeType:1,namespaceURI:'http://www.w3.org/1999/xhtml',
    tagName:tag.toUpperCase(),localName:tag,isConnected:true,classList:[],
    childNodes:children,parentNode:null,parentElement:null,outerHTML:'same-current-markup'};
  Object.defineProperty(n,'children',{get:()=>n.childNodes.filter(c=>c.nodeType===1)});
  for(const c of children){c.parentNode=n;c.parentElement=n;}
  return n;
};
const text={nodeType:3,data:'current',isConnected:true,childNodes:[]};
const inner=node('span',[text]),root=node('span',[inner]),capture=node('div',[root]);
const descriptor=${jsonEncode(descriptor)};
capture.getAttribute=name=>name==='data-parity-key'?descriptor.entryKey:null;
let handlerCalls=0;
let consumed=false;
const receipt={...descriptor,harnessURL:'file:///current-client.html',
  completeRawSlotCount:1,rawOrderFromPublicProducerLists:true,currentRaw:{
    kind:'current-visual-value-raw-v1',logicalUnitId:descriptor.source.logicalUnitId,
    rawSlotCount:1,slotPresence:[false],plainMode:true,generatedTree:{
      namespaceURI:root.namespaceURI,localName:'span',nodeKinds:[1],children:[{
        namespaceURI:inner.namespaceURI,localName:'span',nodeKinds:[3],children:[]}]}}};
global.CustomEvent=class{constructor(type,options){this.type=type;this.detail=options.detail;}};
capture.dispatchEvent=event=>{
  if(consumed)return true;
  consumed=true;handlerCalls++;
  event.detail.response={receipt,capture,layoutRoot:root,nodes:[capture,root,inner,text]};
  $handlerMutation
  return true;
};
global.document={querySelectorAll:()=>[root]};
global.location={href:receipt.harnessURL};
let cssReads=0;
global.getComputedStyle=owner=>{
  cssReads++;
  if(owner!==root)throw Error('Borrowed owner');
  return {display:'block',paddingTop:'11px',paddingRight:'13px',
    paddingBottom:'17px',paddingLeft:'19px'};
};
const request={requested:true,selector:'#current',layoutSelector:'#current',
  source:descriptor.source,currentClientBoxSource:descriptor};
$mutation
const observed=JSON.parse(($boxPaddingObservationScript)(request));
console.log(JSON.stringify({observed,cssReads,handlerCalls}));
''';
  final directory = await Directory.systemTemp.createTemp('coui-parity-node-');
  late final ProcessResult result;
  try {
    final file = File('${directory.path}/probe.cjs');
    await file.writeAsString(nodeProgram);
    result = await Process.run('node', [file.path]);
  } finally {
    await directory.delete(recursive: true);
  }
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
}

void main() {
  for (final theme in ['light', 'dark']) {
    test('client descriptor uses actual reviewed root tuple: $theme', () {
      final entry = _entry(theme: theme);
      final descriptor = clientBoxSourceDescriptor(
        entry,
        additiveBoxObservations: true,
      )!;
      expect(
        descriptor.keys,
        unorderedEquals([
          'kind',
          'entryKey',
          'source',
          'renderPhase',
        ]),
      );
      expect(descriptor['entryKey'], entry.key);
      expect(descriptor['kind'], kClientBoxSourceKind);
      expect(descriptor['renderPhase'], 'client-settled');
      expect(
        descriptor['source'],
        entry.probes.single.boxObservationSource!.toJson(),
      );
    });
  }
  test('omitted observer and other recipes receive no descriptor', () {
    expect(
      clientBoxSourceDescriptor(
        _entry(),
        additiveBoxObservations: false,
      ),
      isNull,
    );
    expect(
      clientBoxSourceDescriptor(
        _entry(
          component: 'icon',
          source: BoxObservationSourceSpec.iconVisualFrame,
        ),
        additiveBoxObservations: true,
      ),
      isNull,
    );
    expect(
      () => clientBoxSourceDescriptor(
        _entry(source: BoxObservationSourceSpec.iconVisualFrame),
        additiveBoxObservations: true,
      ),
      throwsStateError,
    );
  });
  test('factored public raw binder preserves nullable slot and callbacks', () {
    var callbacks = 0;
    final raw = bindVisualValueWebRawSource(
      producer: const coui.NumberTicker(value: 7),
      source: BoxObservationSourceSpec.numberTickerTextLayoutHost,
    );
    expect(raw.rawSlots, [null]);
    expect(raw.currentDomContract['slotPresence'], [false]);
    expect(
      () => bindVisualValueWebRawSource(
        producer: coui.NumberTicker(
          value: 7,
          formatter: (_) {
            callbacks++;
            return 'formatted';
          },
        ),
        source: BoxObservationSourceSpec.numberTickerTextLayoutHost,
      ),
      throwsStateError,
    );
    expect(callbacks, 0);
  });
  test('unknown subtype and custom builder remain held without replay', () {
    var calls = 0;
    for (final producer in <coui.NumberTicker>[
      const _UnknownTicker(),
      coui.NumberTicker.builder(
        value: 7,
        child: const coui.Text('foreign'),
        builder: (_, _, _) {
          calls++;
          return const coui.Text('replayed');
        },
      ),
    ]) {
      expect(
        () => bindVisualValueWebRawSource(
          producer: producer,
          source: BoxObservationSourceSpec.numberTickerTextLayoutHost,
        ),
        throwsStateError,
      );
    }
    expect(calls, 0);
  });
  test(
    'same-task client receipt precedes asymmetric actual CSS read',
    () async {
      final sample = await _sample();
      final observed = sample['observed']! as Map;
      expect(sample['handlerCalls'], 1);
      expect(sample['cssReads'], 1);
      expect(observed['status'], 'source-complete');
      expect(observed['value'], [11, 13, 17, 19]);
      expect(observed['currentClientSource'], isA<Map<String, Object?>>());
      expect(observed['clientObservationPhase'], 'client-settled');
      expect(observed['clientEvidence'], {
        'actualCaptureMarkup': 'same-current-markup',
        'actualNodeCount': 4,
      });
      expect((observed['currentClientSource']! as Map).keys.length, 8);
      expect(observed['clientDomIdentityValidated'], true);
      expect(observed['clientDomWholeTreeValidated'], true);
      expect(observed['canonicalComparisonEligible'], false);
    },
  );
  for (final (index, mutation) in [
    "descriptor.kind='canonical-ssr-visual-value-v1';",
    "descriptor.renderPhase='ssr';",
    'descriptor.extra=true;',
    'descriptor.source={};',
    'root.isConnected=false;',
    "receipt.entryKey='other';",
    "receipt.harnessURL='file:///different.html';",
    'receipt.extra=true;',
    'delete receipt.completeRawSlotCount;',
    "receipt.completeRawSlotCount='1';",
    'receipt.completeRawSlotCount=2;',
    'receipt.rawOrderFromPublicProducerLists=false;',
    'receipt.currentRaw.slotPresence=[true];',
    'receipt.currentRaw.plainMode=false;',
    'receipt.currentRaw.generatedTree.children[0].nodeKinds=[8];',
    _kCaptureForeignText,
    _kInnerForeignText,
    _kInnerForeignComment,
    'consumed=true;',
  ].indexed) {
    test('client protocol rejects before box CSS: $index', () async {
      final sampled = await _sample(mutation: mutation);
      expect((sampled['observed']! as Map)['status'], 'incomplete');
      expect(sampled['cssReads'], 0);
      expect(
        (sampled['observed']! as Map).containsKey('clientEvidence'),
        false,
      );
    });
  }
  for (final (index, mutation) in [
    'event.detail.response.layoutRoot={...root};',
    'event.detail.response.nodes[3]={...text};',
    "capture.outerHTML='mutated';",
    "event.detail.error='actual collector failed';",
  ].indexed) {
    test('client exchange rejects stale refs/mutation: $index', () async {
      final sampled = await _sample(handlerMutation: mutation);
      expect((sampled['observed']! as Map)['status'], 'incomplete');
      expect(sampled['cssReads'], 0);
      expect(
        (sampled['observed']! as Map).containsKey('clientEvidence'),
        false,
      );
    });
  }
}

class _UnknownTicker extends coui.NumberTicker {
  const _UnknownTicker() : super(value: 7);
}
