@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:jaspr_test/client_test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/client_box_source_protocol.dart';
import '../../src/web/runtime_capture_entry.dart' show runtimeCaptureApp;

@JS('eval')
external JSAny? _eval(String source);

@JS('Function')
external JSFunction _function(String parameter, String body);

Map<String, Object?> _config({
  bool observer = true,
  String key = 'number-ticker-default-light-defaultStyle',
}) {
  return {
    'key': key,
    'component': 'number-ticker',
    'variant': 'default',
    'width': 800,
    if (observer)
      'currentClientBoxSource': {
        'kind': kClientBoxSourceKind,
        'entryKey': key,
        'source': BoxObservationSourceSpec.numberTickerTextLayoutHost.toJson(),
        'renderPhase': kClientBoxSourcePhase,
      },
  };
}

Map<String, Object?> _sample(Map<String, Object?> config) {
  final request = {
    'requested': true,
    'selector': '[data-parity-key] > *',
    'layoutSelector': '[data-parity-key] > *',
    'source': BoxObservationSourceSpec.numberTickerTextLayoutHost.toJson(),
    'currentClientBoxSource': config['currentClientBoxSource'],
  };
  final result = _eval(
    '($boxPaddingObservationScript)(${jsonEncode(request)})',
  );
  return (jsonDecode(result!.dartify()! as String) as Map)
      .cast<String, Object?>();
}

Future<void> _ready(ClientTester tester) async {
  await Future<void>.delayed(Duration.zero);
  // Same public completion condition as the original runtime capture. This
  // only establishes phase; it is not the producer/source identity proof.
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    final node = tester.findNode(find.byType(coui.NumberTicker));
    if (node?.textContent?.trim() == '1234') return;
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
  fail('Original NumberTicker runtime readiness did not complete');
}

void main() {
  testClient('actual current mount is nonmutating and request is one-shot', (
    tester,
  ) async {
    final config = _config();
    tester.pumpComponent(runtimeCaptureApp(config));
    await _ready(tester);
    final root = tester.findNode(find.byType(coui.NumberTicker))!;
    final capture = root.parentElement!;
    final before = capture.outerHTML;
    final sampled = _sample(config);
    expect(sampled['status'], 'source-complete');
    expect(sampled['clientDomIdentityValidated'], true);
    expect(sampled['clientDomWholeTreeValidated'], true);
    expect(sampled['clientObservationPhase'], 'client-settled');
    final receipt = sampled['currentClientSource']! as Map;
    expect(receipt.keys.length, 8);
    expect(receipt['kind'], kClientBoxSourceKind);
    expect(receipt['completeRawSlotCount'], 1);
    expect((receipt['currentRaw']! as Map)['slotPresence'], [false]);
    expect(sampled['clientEvidence'], {
      'actualCaptureMarkup': before,
      'actualNodeCount': 4,
    });
    expect(capture.outerHTML, before);
    expect(tester.findNode(find.byType(coui.NumberTicker)), same(root));
    expect(_sample(config)['error'], 'MISSING_ACTUAL_CLIENT_BOX_SOURCE');
  });

  for (final data in ['foreign', '\u00a0']) {
    testClient('actual capture rejects external text $data', (tester) async {
      final config = _config();
      tester.pumpComponent(runtimeCaptureApp(config));
      await _ready(tester);
      final root = tester.findNode(find.byType(coui.NumberTicker))!;
      final encodedData = jsonEncode(data);
      _function(
        'node',
        'node.parentElement.appendChild('
            'document.createTextNode($encodedData));',
      ).callAsFunction(null, root);
      expect(_sample(config)['status'], 'incomplete');
    });
    testClient('actual generated text host rejects foreign text $data', (
      tester,
    ) async {
      final config = _config();
      tester.pumpComponent(runtimeCaptureApp(config));
      await _ready(tester);
      final root = tester.findNode(find.byType(coui.NumberTicker))!;
      final encodedData = jsonEncode(data);
      _function(
        'node',
        'node.firstElementChild.appendChild('
            'document.createTextNode($encodedData));',
      ).callAsFunction(null, root);
      expect(_sample(config)['status'], 'incomplete');
    });
  }

  testClient('invalid request consumes original mounted observer', (
    tester,
  ) async {
    final config = _config();
    tester.pumpComponent(runtimeCaptureApp(config));
    await _ready(tester);
    final request = Map<String, Object?>.of(config);
    request['currentClientBoxSource'] = {
      ...(config['currentClientBoxSource']! as Map).cast<String, Object?>(),
      'entryKey': 'other-capture',
    };
    // Header rejection before dispatch is distinct from consumed observer.
    expect(_sample(request)['status'], 'incomplete');
    final root = tester.findNode(find.byType(coui.NumberTicker))!;
    _function('node', '''
const exchange={request:{invalid:true}};
node.parentElement.dispatchEvent(new CustomEvent('$kClientBoxSourceEvent',
  {detail:exchange,bubbles:false}));
if(!exchange.error)throw Error('Invalid actual request was not rejected');
''').callAsFunction(null, root);
    expect(_sample(config)['error'], 'MISSING_ACTUAL_CLIENT_BOX_SOURCE');
  });

  testClient('dispose removes listener from retained detached capture node', (
    tester,
  ) async {
    final config = _config();
    tester.pumpComponent(runtimeCaptureApp(config));
    await _ready(tester);
    final root = tester.findNode(find.byType(coui.NumberTicker))!;
    final capture = root.parentElement!;
    tester.binding.detachRootComponent();
    final result = _function('node', '''
const exchange={request:${jsonEncode(config['currentClientBoxSource'])}};
node.dispatchEvent(new CustomEvent('$kClientBoxSourceEvent',
  {detail:exchange,bubbles:false}));
return Object.hasOwn(exchange,'response') || Object.hasOwn(exchange,'error');
''').callAsFunction(null, capture);
    expect(result!.dartify(), false);
  });

  testClient('parent rebuild replaces listener on the same current DOM node', (
    tester,
  ) async {
    final generation = coui.ValueNotifier<int>(0);
    addTearDown(generation.dispose);
    tester.pumpComponent(
      coui.ListenableBuilder(
        listenable: generation,
        builder: (_) => runtimeCaptureApp(
          _config(
            key: 'capture-generation-${generation.value}',
          ),
        ),
      ),
    );
    await _ready(tester);
    final originalRoot = tester.findNode(find.byType(coui.NumberTicker))!;
    final originalCapture = originalRoot.parentElement!;
    // Rebuild the public parent without consuming the old listener first.
    // A retained listener would write an old-key error into the new request.
    generation.value++;
    await _ready(tester);
    final currentRoot = tester.findNode(find.byType(coui.NumberTicker))!;
    expect(currentRoot, same(originalRoot));
    expect(currentRoot.parentElement, same(originalCapture));
    final current = _config(key: 'capture-generation-1');
    expect(_sample(current)['status'], 'source-complete');
    expect(_sample(current)['error'], 'MISSING_ACTUAL_CLIENT_BOX_SOURCE');
  });

  testClient(
    'parent replacement removes old-node listener and rearms new node',
    (
      tester,
    ) async {
      final generation = coui.ValueNotifier<int>(0);
      addTearDown(generation.dispose);
      final config = _config();
      tester.pumpComponent(
        coui.ListenableBuilder(
          listenable: generation,
          builder: (_) => coui.Component.fragment(
            [runtimeCaptureApp(config)],
            key: coui.ValueKey(generation.value),
          ),
        ),
      );
      await _ready(tester);
      final oldRoot = tester.findNode(find.byType(coui.NumberTicker))!;
      final oldCapture = oldRoot.parentElement!;
      generation.value++;
      await _ready(tester);
      final newRoot = tester.findNode(find.byType(coui.NumberTicker))!;
      expect(newRoot, isNot(same(oldRoot)));
      expect(oldCapture.isConnected, false);
      final oldNodeAnswered = _function('node', '''
const exchange={request:${jsonEncode(config['currentClientBoxSource'])}};
node.dispatchEvent(new CustomEvent('$kClientBoxSourceEvent',
  {detail:exchange,bubbles:false}));
return Object.hasOwn(exchange,'response') || Object.hasOwn(exchange,'error');
''').callAsFunction(null, oldCapture);
      expect(oldNodeAnswered!.dartify(), false);
      expect(_sample(config)['status'], 'source-complete');
      expect(_sample(config)['error'], 'MISSING_ACTUAL_CLIENT_BOX_SOURCE');
    },
  );

  testClient('omitted observer retains original runtime DOM and readiness', (
    tester,
  ) async {
    final config = _config(observer: false);
    tester.pumpComponent(runtimeCaptureApp(config));
    await _ready(tester);
    final root = tester.findNode(find.byType(coui.NumberTicker))!;
    expect(root.parentElement!.childNodes.length, 1);
    expect(root.textContent, '1234');
    final request = _config();
    expect(_sample(request)['error'], 'MISSING_ACTUAL_CLIENT_BOX_SOURCE');
  });
}
