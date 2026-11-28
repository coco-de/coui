import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/computed_style_probe.dart';
import '../../src/web/docs_card_registry_ssr_source.dart';
import '../../src/web/web_capture_backend.dart';
import 'docs_card_registry_real_entry_test.dart' as fixture;
import 'docs_size_binding_test.dart' as size_fixture;
import 'ego_capture_backend_test.dart' as ego_fixture;

Future<Map<String, Object?>> _normal(
  Map<String, Object?> json,
  bool requested,
) => Isolate.run(() async {
  final entry = MatrixEntry.fromJson(json);
  final original = kWebPreviewRegistry[entry.component]!;
  var builds = 0;
  final receipts = <Map<String, Object?>>[];
  final routes = <Map<String, Object?>>[];
  kWebPreviewRegistry[entry.component] = (context, variant) {
    builds++;
    return original(context, variant);
  };
  try {
    final body = await renderCaptureBodyHtml(
      entry,
      onCurrentBoxSource: requested ? receipts.add : null,
      onDocumentationSceneRoute: (route, kind) {
        routes.add({'route': route, 'kind': kind});
      },
    );
    return {
      'body': body,
      'receipts': receipts,
      'routes': routes,
      'builds': builds,
    };
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

/// Actual sampler over structural DOM records and synthetic CSS.
/// These records are protocol fixtures, never browser measurements or parity.
Future<Map<String, Object?>> _sample(
  MatrixEntry entry,
  String body,
  Map<String, Object?> instructions, {
  bool removeReceipt = false,
  String phase = '',
}) async {
  final document = html.parse(body);
  final treeJson = jsonEncode(
    _tree(
      document.querySelector('[data-parity-key]')!,
    ),
  );
  final ownerJson = jsonEncode(
    _tree(
      document.querySelector(entry.probes.single.webSelector)!,
    ),
  );
  final selectorJson = jsonEncode(entry.probes.single.webSelector);
  final instructionsJson = jsonEncode(instructions);
  final sourceJson = jsonEncode(
    entry.probes.single.boxObservationSource!.toJson(),
  );
  final remove = removeReceipt ? 'delete request.currentSsrSource;' : '';
  final runtime = size_fixture.docsSourceTestRuntime;
  final phaseJson = jsonEncode(phase);
  final wrappedBox = [
    '(request)=>{ownPhase=true;return (',
    boxPaddingObservationScript,
    ')(request);}',
  ].join();
  final sampler = phase.isEmpty
      ? boxPaddingObservationScript
      : sourceValidatedComputedStyleAndBoxScript(wrappedBox);
  final program =
      '''
$runtime
const instructions=$instructionsJson,selector=$selectorJson;
const capture=from($treeJson),wanted=$ownerJson;
const find=n=>n.nodeType===1&&n.localName===wanted.localName&&
 JSON.stringify(Array.from(n.attributes).map(a=>[a.name,a.value]))===JSON.stringify(Object.entries(wanted.attributes))?n:
 n.nodeType===1?n.childNodes.map(find).find(Boolean):null;
const owner=find(capture);if(!owner)throw Error('ACTUAL_PREPARED_OWNER_REQUIRED');
const padding=instructions.currentSsrSource?.kind==='canonical-ssr-docs-size-preview-v1'?owner.children[0]:owner;
global.document={querySelector:s=>s===selector?owner:null,querySelectorAll:s=>s===selector?[owner]:[],
 createTreeWalker:n=>{const q=[];const visit=x=>{for(const c of x.childNodes){if(c.nodeType===3)q.push(c);else if(c.nodeType===1)visit(c);}};visit(n);return {nextNode:()=>q.shift()||null};}};
global.location={href:instructions.url};
const request={requested:true,selector,layoutSelector:selector,source:$sourceJson,
 ...Object.fromEntries(['requiredCurrentSsrKind','documentationSceneTag','documentationSceneRoute','currentSsrSource']
 .filter(k=>Object.hasOwn(instructions,k)).map(k=>[k,instructions[k]]))};
$remove
let ownPhase=false,changed=false;const phase=$phaseJson,originalCss=getComputedStyle;
global.getComputedStyle=n=>{
 const style=originalCss(n);
 if(!changed&&((phase.startsWith('legacy')&&!ownPhase)||(phase.startsWith('own')&&ownPhase))){
  changed=true;
  if(phase.endsWith('-opaque')){
   const svg=owner.children[0]?.children[0];
   if(svg?.localName!=='svg'||svg.namespaceURI!=='http://www.w3.org/2000/svg')
    throw Error('ACTUAL_AVATAR_OUTER_SVG_REQUIRED');
   svg.setAttribute('data-unrelated-opaque','changed');
  }else{owner.setAttribute('data-during-css','changed');}
 }return style;
};
let result,error;try{result=JSON.parse(($sampler)(request));}catch(e){error=String(e);}
console.log(JSON.stringify({result,error,cssReads,changed}));
''';
  final directory = Directory.systemTemp.createTempSync('docs-frame-sampler-');
  try {
    final file = File('${directory.path}/sample.cjs')
      ..writeAsStringSync(program);
    final result = await Process.run(
      Platform.environment['PARITY_NODE'] ?? 'node',
      [file.path],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
  } finally {
    directory.deleteSync(recursive: true);
  }
}

// The child has an empty executable search path. Real preparation runs, then
// the expected unavailable external transport fails before any browser call.
// This exercises the actual instruction writer without introducing a test API.
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
  final candidates = [
    ...fixture.documentationBranchFixtures(),
    (
      'avatar',
      readDocsScenes('avatar').singleWhere(
        (s) => s.reference == 'docs-v2-63b2a10b59591e46f2d0201badbf8d67',
      ),
    ),
    (
      'kbd',
      readDocsScenes('kbd').singleWhere(
        (s) => s.reference == 'docs-v2-49fefef3cd11b31e6724e311026e5e94',
      ),
    ),
    ('button', readDocsScenes('button').firstWhere((s) => s.tag == 'SizeSpec')),
    ('button', readDocsScenes('button').firstWhere((s) => s.tag == 'Anatomy')),
  ];
  final selected = {
    for (final item in candidates) '${item.$1}-${item.$2.reference}': item,
  }.values.toList();
  for (final (component, scene) in selected) {
    for (final theme in ['light', 'dark']) {
      final entry = fixture.docsFrameEntry(component, scene, theme);
      test('normal API preserves one build and route ${entry.key}', () async {
        final canonical = await _normal(entry.toJson(), false);
        final requested = await _normal(entry.toJson(), true);
        expect(canonical['builds'], 1);
        expect(canonical['receipts'], isEmpty);
        expect(canonical['routes'], isEmpty);
        expect(requested['builds'], 1);
        if (component == 'button' &&
            const ['Card', 'SizeSpec'].contains(scene.tag)) {
          expect(
            requested['body'],
            canonical['body'],
            reason:
                'exact fresh-document normal body and IDs, no normalization',
          );
        }
        final receipts = requested['receipts']! as List;
        final routes = requested['routes']! as List;
        expect(
          html
              .parseFragment(requested['body']! as String)
              .querySelector('[data-parity-key]')
              ?.attributes['data-parity-key'],
          entry.key,
        );
        if (scene.tag == 'Anatomy') {
          expect(receipts, isEmpty);
          expect((routes.single as Map)['kind'], isNull);
        } else {
          expect(receipts, hasLength(1));
          expect((receipts.single as Map).containsKey('error'), false);
          expect(
            (receipts.single as Map)['kind'],
            scene.tag == 'SizeSpec'
                ? 'canonical-ssr-docs-size-preview-v1'
                : kDocsCardRegistrySsrKind,
          );
        }
        if (scene.tag == 'SizeSpec') {
          expect(routes, isEmpty);
        } else {
          expect((routes.single as Map)['route'], {
            'entryKey': entry.key,
            'sceneReference': scene.reference,
            'sceneTag': scene.tag,
          });
        }
      });
    }
  }
  test(
    'real preparation and fake worker preserve documentation requests',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'docs-frame-prepare-',
      );
      try {
        final size = selected.firstWhere((v) => v.$2.tag == 'SizeSpec').$2;
        final cases = <Map<String, Object?>>[
          for (final (component, scene) in selected)
            for (final theme in ['light', 'dark'])
              {
                'entry': fixture
                    .docsFrameEntry(component, scene, theme)
                    .toJson(),
                'family': scene.tag,
                'requested': true,
                'width': 800,
              },
          for (final width in [400])
            {
              'entry': fixture.docsFrameEntry('button', size, 'light').toJson(),
              'family': 'SizeSpec',
              'requested': true,
              'width': width,
            },
          {
            'entry': fixture
                .docsFrameEntry(selected.first.$1, selected.first.$2, 'light')
                .toJson(),
            'family': selected.first.$2.tag,
            'requested': false,
            'width': 800,
          },
        ];
        final input = File('${directory.path}/cases.json')
          ..writeAsStringSync(jsonEncode(cases));
        final retained = Platform.environment['PARITY_DOCS_FRAME_FIXTURE_OUT'];
        if (retained != null) {
          final output = Directory(retained)..createSync(recursive: true);
          File(
            '${output.path}/planned-cases.json',
          ).writeAsStringSync(jsonEncode({'cases': cases}));
        }
        final script = File('${directory.path}/prepare.dart')
          ..writeAsStringSync(
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
        final emptyPath = Directory('${directory.path}/no-executables')
          ..createSync();
        final packagePath = File(
          '.dart_tool/package_config.json',
        ).absolute.path;
        final result = await Process.run(
          Platform.resolvedExecutable,
          [
            '--packages=$packagePath',
            script.path,
            input.path,
            '${directory.path}/prepared',
          ],
          environment: {'PATH': emptyPath.path},
        );
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        final index = <Map<String, Object?>>[];
        for (var i = 0; i < cases.length; i++) {
          final row = cases[i];
          final entry = MatrixEntry.fromJson(
            (row['entry']! as Map).cast<String, Object?>(),
          );
          final work = Directory('${directory.path}/prepared/$i');
          final instructions =
              (jsonDecode(
                        File(
                          '${work.path}/instructions.json',
                        ).readAsStringSync(),
                      )
                      as Map)
                  .cast<String, Object?>();
          final body = File(
            '${work.path}/${entry.key}.html',
          ).readAsStringSync();
          if (row['requested'] == false) {
            for (final key in [
              'currentSsrSource',
              'requiredCurrentSsrKind',
              'documentationSceneRoute',
              'documentationSceneTag',
              'additiveBoxObservations',
            ]) {
              expect(instructions.containsKey(key), false);
            }
            if (retained != null) {
              final id = '${entry.key}-w${row['width']}-canonical-unrequested';
              final output = Directory('$retained/$id')
                ..createSync(recursive: true);
              File('${output.path}/body.html').writeAsStringSync(body);
              File(
                '${output.path}/entry.json',
              ).writeAsStringSync(jsonEncode(entry.toJson()));
              File(
                '${output.path}/instructions.json',
              ).writeAsStringSync(jsonEncode(instructions));
              index.add({
                'id': id,
                'family': row['family'],
                'directory': output.path,
                'requested': false,
                'observation': null,
                'source': 'actual canonical unrequested preparation',
              });
            }
            continue;
          }
          final sampled = await _sample(entry, body, instructions);
          final observation = sampled['result']! as Map;
          if (row['family'] == 'Anatomy') {
            expect(instructions.containsKey('currentSsrSource'), false);
            expect(observation['status'], 'incomplete');
            expect(sampled['cssReads'], 0);
          } else {
            expect(observation['status'], 'source-complete');
            expect(sampled['cssReads'], 1);
            final rejected = await _sample(
              entry,
              body,
              instructions,
              removeReceipt: true,
            );
            expect((rejected['result']! as Map)['status'], 'incomplete');
            expect(rejected['cssReads'], 0);
            if (row['family'] != 'SizeSpec') {
              for (final phase in ['legacy', 'own']) {
                final changed = await _sample(
                  entry,
                  body,
                  instructions,
                  phase: phase,
                );
                expect(changed['changed'], true);
                expect(
                  changed['error'],
                  contains('DOCS_FRAME_BINDING_CHANGED_DURING'),
                );
              }
            }
          }
          if (entry.component == 'avatar' && row['family'] == 'Card') {
            for (final phase in ['legacy-opaque', 'own-opaque']) {
              final positive = await _sample(
                entry,
                body,
                instructions,
                phase: phase,
              );
              expect(positive['changed'], true);
              expect(positive['error'], isNull);
              final result = (positive['result']! as Map)
                  .cast<String, Object?>();
              expect((result['box']! as Map)['status'], 'source-complete');
            }
          }
          final fields = <String, Object?>{
            for (final key in [
              'currentSsrSource',
              'requiredCurrentSsrKind',
              'documentationSceneRoute',
              'documentationSceneTag',
            ])
              if (instructions.containsKey(key)) key: instructions[key],
          };
          final protocol = await ego_fixture.transportProtocol(
            'clear-exact',
            sourceFields: fields,
          );
          expect(protocol['exit'], 0);
          final byRole = (protocol['result']! as Map)['byRole']! as Map;
          final echoed = (byRole['root'] as Map)['forwardedRequest']! as Map;
          for (final key in fields.keys) {
            expect(echoed[key], fields[key]);
          }
          if (retained != null) {
            final id = '${entry.key}-w${row['width']}';
            final output = Directory('$retained/$id')
              ..createSync(recursive: true);
            File('${output.path}/body.html').writeAsStringSync(body);
            File(
              '${output.path}/entry.json',
            ).writeAsStringSync(jsonEncode(entry.toJson()));
            File(
              '${output.path}/instructions.json',
            ).writeAsStringSync(jsonEncode(instructions));
            File(
              '${output.path}/observation.json',
            ).writeAsStringSync(jsonEncode(observation));
            index.add({
              'id': id,
              'family': row['family'],
              'directory': output.path,
              'source':
                  'actual preparation; structural DOM and synthetic CSS, '
                  'no browser measurement',
            });
          }
        }
        if (retained != null) {
          File(
            '$retained/fixture-index.json',
          ).writeAsStringSync(jsonEncode({'cases': index}));
        }
      } finally {
        directory.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
