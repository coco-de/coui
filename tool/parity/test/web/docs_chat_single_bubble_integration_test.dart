// Authored integration controls; no execution or source credit yet.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:docs_core/previews/web_registry.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/computed_style_probe.dart';
import '../../src/web/docs_chat_single_bubble_ssr_source.dart';
import '../../src/web/web_capture_backend.dart';
import 'docs_chat_single_bubble_real_entry_test.dart' as fixture;
import 'docs_size_binding_test.dart' as size_fixture;
import 'ego_capture_backend_test.dart' as ego_fixture;

// Optional durable output is labelled SSR/Node protocol evidence. The original
// Temporary preparation directories retain their existing finally cleanup.
void _retainText(String relativePath, String text) {
  final root = Platform.environment['PARITY_CHAT_INTEGRATION_FIXTURE_OUT'];
  if (root == null) return;
  final file = File('$root/$relativePath');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(text);
}

// Equal initial normal-provider counters; one sequential real render in each
// isolate. Return only plain response/receipt/counts, never mounted objects.
Future<Map<String, Object?>> _normal(
  Map<String, Object?> entryJson,
  bool requested,
) => Isolate.run(() async {
  final entry = MatrixEntry.fromJson(entryJson);
  final original = kWebPreviewRegistry[entry.component]!;
  var builds = 0;
  final receipts = <Map<String, Object?>>[];
  kWebPreviewRegistry[entry.component] = (context, variant) {
    builds++;
    return original(context, variant);
  };
  try {
    final body = await renderCaptureBodyHtml(
      entry,
      onCurrentBoxSource: requested ? receipts.add : null,
    );
    return {'body': body, 'receipts': receipts, 'builds': builds};
  } finally {
    kWebPreviewRegistry[entry.component] = original;
  }
});

Map<String, Object?> _tree(dom.Node node) => node is dom.Element
    ? {
        'nodeType': 1,
        'namespaceURI': node.namespaceUri,
        'localName': node.localName,
        'attributes': {
          for (final a in node.attributes.entries) a.key.toString(): a.value,
        },
        'childNodes': node.nodes.map(_tree).toList(),
      }
    : {'nodeType': node.nodeType, 'data': node is dom.Text ? node.data : ''};

// The real legacy and own samplers run over the normal response's DOM records
// and the established synthetic CSS runtime. This is protocol-only evidence.
Future<Map<String, Object?>> _sample(
  MatrixEntry entry,
  String body,
  Map<String, Object?> receipt, {
  String before = '',
  String phase = '',
  String during = '',
  bool combined = true,
  bool legacyOnly = false,
}) async {
  final fragment = html.parseFragment(body);
  final capture = fragment.querySelector('[data-parity-key]')!;
  final selector = entry.probes.single.webSelector;
  final published = {
    ...receipt,
    'harnessURL': 'file:///owned/chat-integrated-source.html',
  };
  final wrappedBox = [
    '(request)=>{ownPhase=true;return (',
    boxPaddingObservationScript,
    ')(request);}',
  ].join();
  final script = legacyOnly
      ? '(request)=>($computedStyleProbeScript)(request.selector)'
      : combined
      ? sourceValidatedComputedStyleAndBoxScript(wrappedBox)
      : boxPaddingObservationScript;
  final program =
      '''
${size_fixture.docsSourceTestRuntime}
const capture=from(${jsonEncode(_tree(capture))});
const root=capture.children[0],column=root.children[0],padding=column.children[0];
const opaque=padding.childNodes.find(n=>n.nodeType===1);
const selector=${jsonEncode(selector)};
global.location={href:'file:///owned/chat-integrated-source.html'};
global.document={querySelector:s=>s===selector?root:null,
 querySelectorAll:s=>s===selector?[root]:[],
 createTreeWalker:n=>{const q=[];const visit=x=>{for(const c of x.childNodes){
  if(c.nodeType===3)q.push(c);else if(c.nodeType===1)visit(c);}};
  visit(n);return {nextNode:()=>q.shift()||null};}};
const request={requested:true,selector,layoutSelector:selector,
 source:${jsonEncode(entry.probes.single.boxObservationSource!.toJson())},
 requiredCurrentSsrKind:${jsonEncode(kDocsChatSingleBubbleSsrKind)},
 currentSsrSource:${jsonEncode(published)}};
let ownPhase=false,changed=false,poisonReads=0;
const originalCss=getComputedStyle,readNodes=[];
global.getComputedStyle=n=>{
 readNodes.push(n===padding?'body':n===root?'row':'other');
 const style=originalCss(n);
 if(!changed&&${jsonEncode(phase)}===(ownPhase?'own':'legacy')){
  changed=true;$during
 }return style;
};
$before
let observed,error;
try{observed=JSON.parse(($script)(request));}catch(e){error=String(e);}
console.log(JSON.stringify({observed,error,changed,cssReads,poisonReads,readNodes}));
''';
  final directory = await Directory.systemTemp.createTemp('chat-integration-');
  try {
    final file = File('${directory.path}/sample.cjs');
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

// Identical established prepare-only child: real instruction writer, empty
// executable PATH, expected missing ego-browser failure before any browser.
const _prepareOnly = '''
import 'dart:convert';
import 'dart:io';
import 'package:coui_web/coui_web.dart' show ThemeConfig;
import '__MODEL__';
import '__EGO__';
Future<void> main(List<String> args) async {
 final cases=jsonDecode(File(args[0]).readAsStringSync()) as List;
 for(var i=0;i<cases.length;i++){
  final row=cases[i] as Map;
  final entry=MatrixEntry.fromJson((row['entry'] as Map).cast<String,Object?>());
  final work=Directory(args[1]+'/'+i.toString());
  try{
   await captureEgoEntry(entry:entry,space:1,page:'NO_BROWSER_IN_THIS_TEST',
    workDir:work,themeConfig:ThemeConfig.defaults(),vendoredTailwindScript:'',
    fontFaceCss:'',iconifyHeadHtml:'',additiveBoxObservations:row['requested'] as bool,
    availableWidthPx:row['width'] as int);
   throw StateError('Deliberately unavailable test transport unexpectedly ran');
  }on ProcessException catch(error){
   if(error.executable!='ego-browser'||error.errorCode!=2)rethrow;
   if(!File(work.path+'/instructions.json').existsSync())rethrow;
  }
 }
}
''';

void main() {
  for (final variant in fixture.kChatVariants) {
    for (final theme in ['light', 'dark']) {
      final entry = fixture.chatEntry(variant, theme);
      test('actual normal backend + unchanged legacy ${entry.key}', () async {
        final unrequested = await _normal(entry.toJson(), false);
        final requested = await _normal(entry.toJson(), true);
        final retained = 'normal-backend/${entry.key}';
        _retainText(
          '$retained/requested.normal-body.html',
          requested['body']! as String,
        );
        _retainText(
          '$retained/unrequested.normal-body.html',
          unrequested['body']! as String,
        );
        _retainText(
          '$retained/actual-requested-receipts.json',
          jsonEncode(requested['receipts']),
        );
        _retainText(
          '$retained/counts-and-evidence-label.json',
          jsonEncode({
            'requestedBuilds': requested['builds'],
            'unrequestedBuilds': unrequested['builds'],
            'unrequestedReceipts': unrequested['receipts'],
            'evidence':
                'actual normal SSR backend; Node observations below '
                'use structural DOM and synthetic CSS only',
            'browserCalls': 0,
            'sourceOwnershipCredit': false,
            'eligibilityCredit': false,
          }),
        );
        expect(unrequested['builds'], 1);
        expect(unrequested['receipts'], isEmpty);
        expect(requested['builds'], 1);
        expect(requested['body'], unrequested['body']);
        final receipts = requested['receipts']! as List;
        expect(receipts, hasLength(1));
        final receipt = (receipts.single as Map).cast<String, Object?>();
        expect(receipt.containsKey('error'), false, reason: '$receipt');
        expect(receipt['kind'], kDocsChatSingleBubbleSsrKind);
        expect(receipt['entryKey'], entry.key);
        final body = requested['body']! as String;
        final observed = await _sample(entry, body, receipt);
        _retainText(
          '$retained/Node-protocol-observation.json',
          jsonEncode(observed),
        );
        expect(observed['error'], isNull);
        final combined = observed['observed']! as Map;
        final own = combined['box']! as Map;
        expect(own['status'], 'source-complete');
        expect(own['ownerIsLayoutRoot'], false);
        expect(own['registryIsLayoutRoot'], true);
        final legacyOnly = await _sample(
          entry,
          body,
          receipt,
          legacyOnly: true,
        );
        _retainText(
          '$retained/legacy-only-Node-observation.json',
          jsonEncode(legacyOnly),
        );
        expect(combined['legacy'], legacyOnly['observed']);
        // Synthetic CSS values identify which node was sampled; no product
        // inset, expected zero or cross-platform equality is asserted here.
        expect((observed['readNodes']! as List).last, 'body');
      });
    }
  }

  final mutations = <String, String>{
    'source ref': 'request.source={...request.source};',
    'nested receipt ref': [
      'const r=request.currentSsrSource.currentRaw.rawParameters',
      ';r.themePadding={...r.themePadding};',
    ].join(),
    'owned DOM': "padding.setAttribute('data-forged-during-css','yes');",
  };
  for (final phase in ['legacy', 'own']) {
    for (final mutation in mutations.entries) {
      test('held ${mutation.key} changed during $phase rejects', () async {
        final actual = await fixture.renderChatFixture('neutral', 'light');
        final observed = await _sample(
          actual.entry,
          actual.body,
          actual.receipt!,
          phase: phase,
          during: mutation.value,
        );
        expect(observed['changed'], true);
        expect(
          observed['error'],
          contains(
            phase == 'legacy'
                ? 'DOCS_CHAT_BINDING_CHANGED_DURING_LEGACY_READ'
                : 'DOCS_CHAT_BINDING_CHANGED_DURING_BOX_READ',
          ),
        );
      });
    }
    test('opaque attributes remain opaque during $phase', () async {
      final actual = await fixture.renderChatFixture('neutral', 'light');
      final observed = await _sample(
        actual.entry,
        actual.body,
        actual.receipt!,
        phase: phase,
        during: [
          "if(!opaque)throw Error('ACTUAL_OPAQUE_OUTER_REQUIRED')",
          ";opaque.setAttribute('data-opaque-interior-only','allowed');",
        ].join(),
      );
      expect(observed['changed'], true);
      expect(observed['error'], isNull);
      final result = observed['observed']! as Map;
      expect((result['box']! as Map)['status'], 'source-complete');
    });
  }

  for (final combined in [false, true]) {
    test(
      'strictfalse leaves claimed Chat payload untouched ($combined)',
      () async {
        final actual = await fixture.renderChatFixture('neutral', 'light');
        final observed = await _sample(
          actual.entry,
          actual.body,
          actual.receipt!,
          combined: combined,
          // The unchanged old family discriminators may read the three
          // request envelope fields in combined mode; no Chat raw getter may
          // run. The standalone own sampler can skip even envelope getters.
          before: combined
              ? 'request.requested=false;'
                    'Object.defineProperty(request.currentSsrSource,'
                    "'currentRaw',"
                    '{get:()=>{poisonReads++;'
                    "throw Error('UNREQUESTED_CHAT_RAW_READ');}});"
              : [
                  'request.requested=false',
                  ";for(const k of ['source',",
                  "'currentSsrSource','requiredCurrentSsrKind'])",
                  'Object.defineProperty(request,k,{get:()=>{poisonReads++;',
                  "throw Error('UNREQUESTED_CHAT_GETTER_READ');}});",
                ].join(),
        );
        expect(observed['error'], isNull);
        expect(observed['poisonReads'], 0);
        final result = observed['observed']! as Map;
        expect(combined ? result['box'] : result, {'status': 'not-requested'});
      },
    );
    for (final value in ['undefined', "'true'"]) {
      test('claimed malformed flag $value rejects ($combined)', () async {
        final actual = await fixture.renderChatFixture('neutral', 'light');
        final observed = await _sample(
          actual.entry,
          actual.body,
          actual.receipt!,
          combined: combined,
          before: 'request.requested=$value;',
        );
        if (combined) {
          expect(
            observed['error'],
            contains('DOCS_CHAT_STRICT_REQUESTED_FLAG_REQUIRED'),
          );
        } else {
          final result = observed['observed']! as Map;
          expect(result['status'], 'incomplete');
          expect(result['error'], 'DOCS_CHAT_STRICT_REQUESTED_FLAG_REQUIRED');
        }
        expect(observed['cssReads'], 0);
      });
    }
  }

  test('real Ego preparation publishes same16 header and harnessURL', () async {
    final directory = await Directory.systemTemp.createTemp('chat-prepare-');
    try {
      final cases = <Map<String, Object?>>[
        for (final variant in fixture.kChatVariants)
          for (final theme in ['light', 'dark'])
            {
              'entry': fixture.chatEntry(variant, theme).toJson(),
              'requested': true,
              'width': 800,
            },
        {
          'entry': fixture.chatEntry('neutral', 'light').toJson(),
          'requested': false,
          'width': 800,
        },
      ];
      final input = File('${directory.path}/cases.json');
      await input.writeAsString(jsonEncode(cases));
      final script = File('${directory.path}/prepare.dart');
      await script.writeAsString(
        _prepareOnly
            .replaceAll(
              '__MODEL__',
              File(
                'tool/parity/src/model/matrix_entry.dart',
              ).absolute.uri.toString(),
            )
            .replaceAll(
              '__EGO__',
              File(
                'tool/parity/src/web/ego_capture_backend.dart',
              ).absolute.uri.toString(),
            ),
      );
      final emptyPath = await Directory(
        '${directory.path}/empty-path',
      ).create();
      final child = await Process.run(
        Platform.resolvedExecutable,
        [
          '--enable-asserts',
          '--packages=${File('.dart_tool/package_config.json').absolute.path}',
          script.path,
          input.path,
          '${directory.path}/prepared',
        ],
        environment: {'PATH': emptyPath.path},
      );
      expect(child.exitCode, 0, reason: '${child.stdout}\n${child.stderr}');
      for (var i = 0; i < cases.length; i++) {
        final work = Directory('${directory.path}/prepared/$i');
        final instructionsText = await File(
          '${work.path}/instructions.json',
        ).readAsString();
        final instructions = (jsonDecode(instructionsText) as Map)
            .cast<String, Object?>();
        final entry = MatrixEntry.fromJson(
          (cases[i]['entry']! as Map).cast<String, Object?>(),
        );
        final retained = 'actual-Ego-preparation/$i-${entry.key}';
        _retainText('$retained/instructions.ACTUAL.json', instructionsText);
        _retainText('$retained/entry.json', jsonEncode(entry.toJson()));
        _retainText(
          '$retained/normal-body.html',
          await File(
            '${work.path}/${entry.key}.html',
          ).readAsString(),
        );
        _retainText(
          '$retained/evidence-label.json',
          jsonEncode({
            'requested': cases[i]['requested'],
            'evidence':
                'actual instruction writer; deliberately unavailable '
                'external transport; subsequent fake worker is protocol only',
            'originalTemporaryPathsAndHarnessURLUnchanged': true,
            'forwardedPayloadExpected': cases[i]['requested'] == true,
            'browserCalls': 0,
            'sourceOwnershipCredit': false,
          }),
        );
        if (cases[i]['requested'] == false) {
          for (final key in [
            'additiveBoxObservations',
            'requiredCurrentSsrKind',
            'currentSsrSource',
          ]) {
            expect(instructions.containsKey(key), false);
          }
          continue;
        }
        expect(
          instructions['requiredCurrentSsrKind'],
          kDocsChatSingleBubbleSsrKind,
        );
        final receipt = instructions['currentSsrSource']! as Map;
        expect(receipt.containsKey('error'), false);
        expect(receipt['harnessURL'], instructions['url']);
        expect(receipt['kind'], kDocsChatSingleBubbleSsrKind);
        final forwarded = await ego_fixture.transportProtocol(
          'clear-exact',
          sourceFields: {
            'requiredCurrentSsrKind': instructions['requiredCurrentSsrKind'],
            'currentSsrSource': instructions['currentSsrSource'],
          },
        );
        expect(forwarded['exit'], 0);
        final byRole = (forwarded['result']! as Map)['byRole']! as Map;
        final echoed = (byRole['root'] as Map)['forwardedRequest']! as Map;
        _retainText(
          '$retained/forwarded-payload.FAKE-WORKER.json',
          jsonEncode(echoed),
        );
        expect(
          echoed['requiredCurrentSsrKind'],
          instructions['requiredCurrentSsrKind'],
        );
        expect(echoed['currentSsrSource'], instructions['currentSsrSource']);
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
