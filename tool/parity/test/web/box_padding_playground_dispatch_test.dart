import 'dart:convert';
import 'dart:io';

import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/markdown/repo_root.dart';
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/source/playground_value_authority.dart';
import '../../src/web/box_padding_observation_probe.dart';

// A pure Node DOM/CSS shim checks operation and reference boundaries.
// It does not execute the client renderer or establish browser paint.
Future<Map<String, Object?>> _observe(String setup) async {
  final root = findRepoRoot();
  final scene = readDocsScenes(
    'button',
  ).firstWhere((value) => value.tag == 'Playground');
  final temporary = Directory.systemTemp.createTempSync('playground-dispatch-');
  try {
    final manifest = File('${temporary.path}/manifest.json')
      ..writeAsStringSync(
        jsonEncode({
          'entries': [
            {'key': 'entry', 'component': 'button', 'variant': scene.reference},
          ],
        }),
      );
    final payload = <String, Object?>{
      'key': 'entry',
      'component': 'button',
      'variant': scene.reference,
      'width': 800,
      'scene': scene.toJson(),
    };
    final url = Uri.file(
      '${temporary.path}/runtime.html',
    ).replace(fragment: jsonEncode(payload));
    final receipt = preparePlaygroundNavigationReceipt(
      sourceRoot: root,
      manifestFile: manifest,
      navigationURL: url,
      actualRuntimePayload: payload,
    );
    final result = await Process.run('node', [
      '-e',
      '''
const observe=($boxPaddingObservationScript);
const node=(classes,children=[],attrs={})=>{
  const names=[...classes];names.contains=name=>names.includes(name);
  const value={tagName:'DIV',classList:names,children,isConnected:true,parentElement:null,
    getAttribute:name=>attrs[name]??null,hasAttribute:name=>Object.hasOwn(attrs,name),
    setAttribute:(name,text)=>{attrs[name]=text;}};
  for(const child of children)child.parentElement=value;
  value.contains=other=>value===other||value.children.some(child=>child.contains(other));
  value.querySelectorAll=selector=>value.children.flatMap(child=>[
    ...(selector==='[data-docs-scene]' && child.hasAttribute('data-docs-scene')?[child]:[]),
    ...child.querySelectorAll(selector)]);
  return value;
};
const pane=node(['docs-playground-pane']);
const stage=node(['docs-playground-stage'],[node(['docs-playground-platforms']),node(['docs-playground-panes'],[pane])]);
const controls=node(['docs-playground-controls']);
const main=node(['docs-playground-main'],[stage,controls]);
const registry=node(['docs-playground'],[node(['coui-root'],[node(['docs-playground-inner'],[main])])]);
const sceneHost=node([],[node(['content'],[registry])],{'data-docs-scene':${jsonEncode(scene.reference)}});
const entry=node([],[sceneHost],{'data-parity-key':'entry','data-parity-client-key':'entry'});
let entries=[entry], receipt=${jsonEncode(receipt)};
global.document={querySelectorAll:selector=>selector==='[data-parity-key]'?entries:[stage]};
global.location={href:receipt.navigationURL,hash:new URL(receipt.navigationURL).hash};
let cssReads=0;
global.getComputedStyle=owner=>{if(owner!==stage)throw Error('Foreign CSS read');cssReads++;return {display:'block',paddingTop:'16px',paddingRight:'16px',paddingBottom:'16px',paddingLeft:'16px'};};
$setup
const actual=JSON.parse(observe({requested:true,selector:'#stage',layoutSelector:'#stage',source:${jsonEncode(BoxObservationSourceSpec.docsPlayground.toJson())},runtimeOperationReceipt:receipt}));
console.log(JSON.stringify({actual,cssReads}));
''',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    return (jsonDecode(result.stdout.toString()) as Map)
        .cast<String, Object?>();
  } finally {
    temporary.deleteSync(recursive: true);
  }
}

void main() {
  test(
    'source-validated actual URL/hash and exact hosts '
    'reach the stage CSS owner',
    () async {
      final result = await _observe('');
      final actual = result['actual']! as Map;
      expect(actual['status'], 'source-complete');
      expect(actual['value'], [16, 16, 16, 16]);
      expect(actual['ownerIsLayoutRoot'], isTrue);
      expect(actual['registryIsLayoutRoot'], isFalse);
      expect(actual['canonicalComparisonEligible'], isFalse);
      expect(result['cssReads'], 1);
    },
  );
  for (final (name, setup, error) in <(String, String, String)>[
    (
      'prepared authority only',
      'delete global.location;',
      'UNOBSERVED_RUNTIME_INPUT',
    ),
    (
      'actual URL changed',
      "location.href='file:///another.html'+location.hash;",
      'RUNTIME_NAVIGATION_INPUT_CHANGED',
    ),
    (
      'actual hash changed',
      "location.hash='#'+encodeURIComponent(JSON.stringify("
          '{...receipt.preparedPayload,width:801}));',
      'RUNTIME_NAVIGATION_INPUT_CHANGED',
    ),
    ('missing receipt', 'receipt=null;', 'MISSING_ACTUAL_RUNTIME_OPERATION'),
    (
      'duplicate entry host',
      'entries=[entry,entry];',
      'PLAYGROUND_OPERATION_HOST_MISMATCH',
    ),
    (
      'wrong client key',
      "entry.setAttribute('data-parity-client-key','other');",
      'PLAYGROUND_OPERATION_HOST_MISMATCH',
    ),
    (
      'changed payload value authority',
      "receipt.payloadAuthority.sceneValueSha256='f'.repeat(64);",
      'PLAYGROUND_PAYLOAD_AUTHORITY_CHANGED',
    ),
    (
      'foreign layout root',
      'registry.contains=()=>false;',
      'PLAYGROUND_OPERATION_HOST_MISMATCH',
    ),
    (
      'unknown layout insertion',
      'main.children.unshift(node([]));',
      'PLAYGROUND_VIEW_SOURCE_CHANGED',
    ),
  ]) {
    test('$name is incomplete without CSS reads or values', () async {
      final result = await _observe(setup);
      final actual = result['actual']! as Map;
      expect(actual['status'], 'incomplete');
      expect(actual['error'], error);
      expect(actual.containsKey('value'), isFalse);
      expect(result['cssReads'], 0);
    });
  }
}
