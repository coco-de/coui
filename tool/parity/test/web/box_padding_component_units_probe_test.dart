import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/web/box_padding_component_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

BoxObservationSourceSpec _source(String unit) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: '$unit-generated-frame',
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$unit-generated-frame-v1',
  webAdapterId: '$unit-generated-frame-v1',
);

Map<String, Object?> _tree(dom.Element element, List<int> path) => {
  'tagName': element.localName!.toUpperCase(),
  'attributes': {
    for (final entry in element.attributes.entries)
      entry.key.toString(): entry.value,
  },
  'path': path,
  'children': [
    for (var i = 0; i < element.children.length; i++)
      _tree(element.children[i], [...path, i]),
  ],
};

Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  BoxObservationSourceSpec source, {
  String mutation = '',
}) async {
  final result = await Process.run('node', [
    '-e',
    '''
const resolve = ($componentBoxSourceResolverScript);
global.getComputedStyle = () => { throw Error('CSS read is forbidden'); };
global.document = new Proxy({}, {get(){throw Error('Global search is forbidden');}});
const node = (data, parent = null) => {
  const attributes = data.attributes;
  const value = {tagName:data.tagName, path:data.path, parentElement:parent,
    getAttribute:name=>attributes[name] ?? null,
    hasAttribute:name=>Object.hasOwn(attributes,name),
    classList:{contains:name=>(attributes.class ?? '').split(/\\s+/).includes(name)}};
  for (const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
    Object.defineProperty(value,name,{get(){throw Error('Numeric layout read is forbidden');}});
  value.children = data.children.map(child=>node(child,value));
  return value;
};
const capture = node(${jsonEncode(tree)});
const root = capture.children[0];
const source = ${jsonEncode(source.toJson())};
$mutation
const value = resolve(root,source);
console.log(JSON.stringify(value.error ? value : {
  registry:value.registryResultElement.path, unit:value.fieldUnitElement.path,
  padding:value.paddingSource.path, frame:value.frameSource.path,
  hasValue:Object.hasOwn(value,'value'), authority:value.authority
}));
''',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
}

Future<Map<String, Object?>> _actualBodyTree(MatrixEntry entry) async {
  final body = await renderCaptureBodyHtml(entry);
  final document = html.parseFragment(body);
  final wrappers = document.querySelectorAll('[data-parity-key]');
  expect(wrappers, hasLength(1));
  expect(wrappers.single.attributes['data-parity-key'], entry.key);
  expect(wrappers.single.children, hasLength(1));
  return _tree(wrappers.single, const []);
}

void main() {
  const recipes =
      <({String component, String variant, String unit, int depth})>[
        (
          component: 'code-diff',
          variant: 'default',
          unit: 'code-diff',
          depth: 2,
        ),
        (
          component: 'command',
          variant: 'default',
          unit: 'command-panel',
          depth: 1,
        ),
        (
          component: 'command',
          variant: 'scrollable',
          unit: 'command-panel',
          depth: 1,
        ),
        (
          component: 'command',
          variant: 'empty',
          unit: 'command-panel',
          depth: 1,
        ),
        (component: 'fieldset', variant: 'default', unit: 'fieldset', depth: 2),
        (
          component: 'fieldset',
          variant: 'outlined',
          unit: 'fieldset',
          depth: 2,
        ),
        (component: 'fieldset', variant: 'plain', unit: 'fieldset', depth: 2),
        (
          component: 'item-picker',
          variant: 'default',
          unit: 'item-picker',
          depth: 1,
        ),
        (
          component: 'mockup-browser',
          variant: 'default',
          unit: 'mockup-browser',
          depth: 3,
        ),
        (
          component: 'object-input',
          variant: 'default',
          unit: 'object-input',
          depth: 1,
        ),
      ];
  for (final recipe in recipes) {
    for (final theme in ParityTheme.values) {
      test(
        '${recipe.component}/${recipe.variant}/${theme.name} real SSR route',
        () async {
          final entry = MatrixEntry.fromJson({
            'component': recipe.component,
            'variant': recipe.variant,
            'theme': theme.name,
            'surfaceStyle': 'defaultStyle',
            'tier': ParityTier.t1.name,
            'probes': <Object?>[],
          });
          final tree = await _actualBodyTree(entry);
          final result = await _resolve(tree, _source(recipe.unit));
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          expect(result['padding'], List.filled(recipe.depth, 0));
          expect(result['frame'], result['padding']);
          expect(result['hasValue'], false);
        },
      );
    }
  }
  test(
    'real generated width wrapper cannot borrow a foreign nested frame',
    () async {
      final entry = MatrixEntry.fromJson({
        'component': 'code-diff',
        'variant': 'default',
        'theme': 'light',
        'surfaceStyle': 'defaultStyle',
        'tier': 't1',
        'probes': <Object?>[],
      });
      final tree = await _actualBodyTree(entry);
      for (final mutation in [
        'root.children=[];',
        'root.children.push(root.children[0]);',
        "root.children[0].tagName='SECTION';",
      ]) {
        final result = await _resolve(
          tree,
          _source('code-diff'),
          mutation: mutation,
        );
        expect(result, {'error': 'CODE_DIFF_DECLARED_FRAME_CHANGED'});
      }
    },
  );
  test('unknown tuple or second capture unit returns no references', () async {
    final entry = MatrixEntry.fromJson({
      'component': 'code-diff',
      'variant': 'default',
      'theme': 'light',
      'surfaceStyle': 'defaultStyle',
      'tier': 't1',
      'probes': <Object?>[],
    });
    final tree = await _actualBodyTree(entry);
    final unknown = await _resolve(tree, _source('code-snippet'));
    expect(unknown, {'error': 'UNREGISTERED_COMPONENT_CONSTRUCTION'});
    final wrong = await _resolve(
      tree,
      _source('code-diff'),
      mutation: "source.webAdapterId='unknown';",
    );
    expect(wrong, {'error': 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH'});
    final duplicate = await _resolve(
      tree,
      _source('code-diff'),
      mutation: 'capture.children.push(root);',
    );
    expect(duplicate, {'error': 'MISMATCHED_COMPONENT_CAPTURE_ROOT'});
  });
}
