import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/web/box_padding_extended_component_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

BoxObservationSourceSpec _source(String unit) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: unit,
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$unit-v1',
  webAdapterId: '$unit-v1',
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
const resolve = ($extendedComponentBoxSourceResolverScript);
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
const data = ${jsonEncode(tree)};
const capture = node(data);
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
          component: 'banner',
          variant: 'default',
          unit: 'banner-generated-frame',
          depth: 1,
        ),
        (
          component: 'banner',
          variant: 'info',
          unit: 'banner-generated-frame',
          depth: 1,
        ),
        (
          component: 'banner',
          variant: 'warning',
          unit: 'banner-generated-frame',
          depth: 1,
        ),
        (
          component: 'banner',
          variant: 'destructive',
          unit: 'banner-generated-frame',
          depth: 1,
        ),
        (
          component: 'banner',
          variant: 'success',
          unit: 'banner-generated-frame',
          depth: 1,
        ),
        (
          component: 'banner',
          variant: 'solid',
          unit: 'banner-generated-frame',
          depth: 1,
        ),
        (
          component: 'banner',
          variant: 'narrow',
          unit: 'banner-generated-frame',
          depth: 2,
        ),
        (
          component: 'description-card',
          variant: 'default',
          unit: 'description-card-generated-frame',
          depth: 1,
        ),
        (
          component: 'description-card',
          variant: 'filled',
          unit: 'description-card-generated-frame',
          depth: 1,
        ),
        (
          component: 'description-card',
          variant: 'ghost',
          unit: 'description-card-generated-frame',
          depth: 1,
        ),
        (
          component: 'description-card',
          variant: 'vertical',
          unit: 'description-card-generated-frame',
          depth: 1,
        ),
        (
          component: 'description-card',
          variant: 'space-between',
          unit: 'description-card-generated-frame',
          depth: 1,
        ),
        (
          component: 'description-card',
          variant: 'placeholder',
          unit: 'description-card-generated-frame',
          depth: 1,
        ),
        (
          component: 'formatted-input',
          variant: 'default',
          unit: 'formatted-input-generated-frame',
          depth: 1,
        ),
        (
          component: 'formatted-input',
          variant: 'korean-phone',
          unit: 'formatted-input-generated-frame',
          depth: 1,
        ),
        (
          component: 'formatted-input',
          variant: 'credit-card',
          unit: 'formatted-input-generated-frame',
          depth: 1,
        ),
        (
          component: 'formatted-input',
          variant: 'date',
          unit: 'formatted-input-generated-frame',
          depth: 1,
        ),
        (
          component: 'formatted-input',
          variant: 'verify',
          unit: 'formatted-input-generated-frame',
          depth: 1,
        ),
        (
          component: 'frame',
          variant: 'default',
          unit: 'frame-generated-content-inset',
          depth: 1,
        ),
        (
          component: 'frame',
          variant: 'column',
          unit: 'frame-generated-content-inset',
          depth: 1,
        ),
        (
          component: 'frame',
          variant: 'dashed',
          unit: 'frame-generated-content-inset',
          depth: 1,
        ),
        (
          component: 'frame',
          variant: 'elevated',
          unit: 'frame-generated-content-inset',
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
    'real narrow wrapper rejects missing or duplicate Banner roots',
    () async {
      final entry = MatrixEntry.fromJson({
        'component': 'banner',
        'variant': 'narrow',
        'theme': 'light',
        'surfaceStyle': 'defaultStyle',
        'tier': 't1',
        'probes': <Object?>[],
      });
      const duplicateBannerRoot =
          'root.children.push(node({'
          '...data.children[0].children[0],path:[0,1]},root));';
      final tree = await _actualBodyTree(entry);
      for (final mutation in [
        'root.children=[];',
        duplicateBannerRoot,
        "root.children[0].tagName='SECTION';",
      ]) {
        final result = await _resolve(
          tree,
          _source('banner-generated-frame'),
          mutation: mutation,
        );
        expect(result, {'error': 'BANNER_DECLARED_SOURCE_CHANGED'});
      }
    },
  );
  test('unknown tuple or second capture unit has no references', () async {
    final entry = MatrixEntry.fromJson({
      'component': 'frame',
      'variant': 'default',
      'theme': 'light',
      'surfaceStyle': 'defaultStyle',
      'tier': 't1',
      'probes': <Object?>[],
    });
    final tree = await _actualBodyTree(entry);
    expect(await _resolve(tree, _source('mockup-code-generated-frame')), {
      'error': 'UNREGISTERED_EXTENDED_COMPONENT_SOURCE',
    });
    expect(
      await _resolve(
        tree,
        _source('frame-generated-content-inset'),
        mutation: "source.webAdapterId='unknown';",
      ),
      {'error': 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH'},
    );
    expect(
      await _resolve(
        tree,
        _source('frame-generated-content-inset'),
        mutation:
            'capture.children.push(node({'
            '...data.children[0],path:[1]},capture));',
      ),
      {'error': 'MISMATCHED_COMPONENT_CAPTURE_ROOT'},
    );
  });
}
