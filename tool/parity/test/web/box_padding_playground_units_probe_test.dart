import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/web/box_padding_playground_units_probe.dart';

const BoxObservationSourceSpec _source =
    BoxObservationSourceSpec.docsPlayground;

// Synthetic prevalidated operation context; not a browser/source attestation.
Future<Map<String, Object?>> _observe(String setup) async {
  final reference = 'docs-v2-${'a'.padLeft(32, 'a')}';
  final authority = {
    'component': 'button',
    'reference': reference,
    'tag': 'Playground',
    'documentPath': 'fixture/button.md',
    'documentSha256': 'a'.padLeft(64, 'a'),
    'sourceClosureSha256': 'b'.padLeft(64, 'b'),
    'manifestSha256': 'c'.padLeft(64, 'c'),
    'sceneValueSha256': 'd'.padLeft(64, 'd'),
  };
  final result = await Process.run('node', [
    '-e',
    '''
const bind=($documentationPlaygroundBoxSourceResolverScript);
global.getComputedStyle=()=>{throw Error('CSS numeric reads forbidden');};
const node=(classes,children=[],attrs={})=>{
  const names=[...classes];names.contains=n=>names.includes(n);
  const value={tagName:'DIV',classList:names,children,parentElement:null,
    getAttribute:n=>Object.hasOwn(attrs,n)?attrs[n]:null,
    setAttribute:(n,v)=>{attrs[n]=String(v);},removeAttribute:n=>{delete attrs[n];}};
  value.contains=other=>value===other||children.some(c=>c.contains(other));
  for(const child of children)child.parentElement=value;
  return value;
};
const pane=node(['docs-playground-pane']);
const panes=node(['docs-playground-panes'],[pane]);
const platforms=node(['docs-playground-platforms']);
const stage=node(['docs-playground-stage'],[platforms,panes]);
const controls=node(['docs-playground-controls']);
const main=node(['docs-playground-main'],[stage,controls]);
const inner=node(['docs-playground-inner'],[main]);
const registryRoot=node(['docs-playground'],[node(['coui-root'],[inner])]);
const content=node(['content'],[registryRoot]);
const sceneHost=node([],[content],{'data-docs-scene':${jsonEncode(reference)}});
const entryRoot=node([],[sceneHost],{'data-parity-key':'entry','data-parity-client-key':'entry'});
const authority=${jsonEncode(authority)};
const payload={key:'entry',component:'button',variant:${jsonEncode(reference)},scene:{tag:'Playground'}};
let operation={entryKey:'entry',component:'button',variant:${jsonEncode(reference)},authority,
  payloadAuthority:{...authority},payload,entryRoot,sceneHost,registryRoot};
let layoutRoot=stage;
const source=${jsonEncode(_source.toJson())};
$setup
const value=bind(layoutRoot,source,operation);
console.log(JSON.stringify(value.error?value:{stageIsPadding:value.paddingSource===stage,
  stageIsFrame:value.frameSource===stage,stageIsUnit:value.fieldUnitElement===stage,
  registryIsActual:value.registryResultElement===registryRoot,hasNumericValue:Object.hasOwn(value,'value')}));
''',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
}

void main() {
  test(
    'trusted operation binds stage refs rather than the centered pane',
    () async {
      expect(await _observe(''), {
        'stageIsPadding': true,
        'stageIsFrame': true,
        'stageIsUnit': true,
        'registryIsActual': true,
        'hasNumericValue': false,
      });
    },
  );
  test('source bare-controls branch keeps the same stage owner', () async {
    final result = await _observe(
      "main.classList.push('is-bare');main.children.pop();",
    );
    expect(result['stageIsPadding'], true);
  });
  for (final (name, setup, error) in <(String, String, String)>[
    ('missing operation', 'operation=null;', 'MISSING_PLAYGROUND_OPERATION'),
    (
      'payload key',
      "payload.key='other';",
      'PLAYGROUND_OPERATION_VALUE_MISMATCH',
    ),
    (
      'scene kind',
      "payload.scene.tag='SizeSpec';",
      'PLAYGROUND_OPERATION_VALUE_MISMATCH',
    ),
    (
      'malformed hash',
      "authority.documentSha256='bad';",
      'INVALID_SCENE_VALUE_AUTHORITY',
    ),
    (
      'changed hash',
      "authority.manifestSha256='e'.repeat(64);",
      'PLAYGROUND_PAYLOAD_AUTHORITY_CHANGED',
    ),
    (
      'entry host',
      "entryRoot.setAttribute('data-parity-key','other');",
      'PLAYGROUND_OPERATION_HOST_MISMATCH',
    ),
    (
      'no client key',
      "entryRoot.removeAttribute('data-parity-client-key');",
      'PLAYGROUND_OPERATION_HOST_MISMATCH',
    ),
    (
      'scene reference',
      "sceneHost.setAttribute('data-docs-scene','other');",
      'PLAYGROUND_OPERATION_HOST_MISMATCH',
    ),
    (
      'foreign root',
      'registryRoot.contains=()=>false;',
      'PLAYGROUND_OPERATION_HOST_MISMATCH',
    ),
    ('pane instead', 'layoutRoot=pane;', 'PLAYGROUND_STAGE_SOURCE_CHANGED'),
    (
      'hidden pane',
      "pane.classList.push('is-hidden');",
      'PLAYGROUND_PANE_SOURCE_CHANGED',
    ),
    (
      'both panes',
      "panes.classList.push('is-both');",
      'PLAYGROUND_PANE_SOURCE_CHANGED',
    ),
    (
      'duplicate pane',
      'panes.children.push(node([]));',
      'PLAYGROUND_PANE_SOURCE_CHANGED',
    ),
    (
      'extra view',
      'inner.children.push(node([]));',
      'PLAYGROUND_VIEW_SOURCE_CHANGED',
    ),
    (
      'unknown tuple',
      "source.nativeAdapterId='unknown';",
      'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
    ),
  ]) {
    test('rejects $name without source refs or value', () async {
      expect(await _observe(setup), {'error': error});
    });
  }
}
