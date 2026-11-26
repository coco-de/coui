import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_proxy_host_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _kMask = 'mask-generated-clip-host';
const _kHover = 'hover-generated-effect-host';
const _kIndicator = 'indicator-generated-overlay-host';

BoxObservationSourceSpec _source(String unit) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: unit,
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$unit-v1',
  webAdapterId: '$unit-v1',
);

Map<String, Object?> _tree(dom.Element node, List<int> path) => {
  'tagName': node.localName!.toUpperCase(),
  'attributes': {
    for (final entry in node.attributes.entries)
      entry.key.toString(): entry.value,
  },
  'path': path,
  'children': [
    for (var i = 0; i < node.children.length; i++)
      _tree(node.children[i], [...path, i]),
  ],
};

Future<Map<String, Object?>> _actual(
  String component,
  String variant, {
  String theme = 'light',
}) async {
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't1',
    'probes': <Object?>[],
  });
  final body = await renderCaptureBodyHtml(entry);
  final captures = html
      .parseFragment(body)
      .querySelectorAll('[data-parity-key]');
  expect(captures, hasLength(1));
  expect(captures.single.attributes['data-parity-key'], entry.key);
  expect(captures.single.children, hasLength(1));
  return _tree(captures.single, const []);
}

Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  String unit, {
  String mutation = '',
}) async {
  final result = await Process.run('node', [
    '-e',
    '''
const resolve = ($proxyHostBoxSourceResolverScript);
global.getComputedStyle = () => {throw Error('CSS read forbidden');};
global.document = new Proxy({}, {get(){throw Error('Global search forbidden');}});
const node = (data,parent=null) => {
  const attrs=data.attributes;
  const value={tagName:data.tagName,path:data.path,parentElement:parent,
    getAttribute:name=>attrs[name] ?? null,
    hasAttribute:name=>Object.hasOwn(attrs,name),
    classList:{contains:name=>(attrs.class ?? '').split(/\\s+/).includes(name)}};
  for (const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
    Object.defineProperty(value,name,{get(){throw Error('Numeric read forbidden');}});
  value.children=data.children.map(child=>node(child,value));
  return value;
};
const capture=node(${jsonEncode(tree)}), root=capture.children[0];
const source=${jsonEncode(_source(unit).toJson())};
$mutation
const result=resolve(root,source);
console.log(JSON.stringify(result.error ? result : {
  registry:result.registryResultElement.path,unit:result.fieldUnitElement.path,
  padding:result.paddingSource.path,frame:result.frameSource.path,
  hasValue:Object.hasOwn(result,'value'),authority:result.authority
}));
''',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
}

void main() {
  const recipes = <({String component, String variant, String unit})>[
    (component: 'mask', variant: 'default', unit: _kMask),
    (component: 'mask', variant: 'circle', unit: _kMask),
    (component: 'mask', variant: 'heart', unit: _kMask),
    (component: 'mask', variant: 'hexagon', unit: _kMask),
    (component: 'mask', variant: 'star', unit: _kMask),
    (component: 'mask', variant: 'triangle', unit: _kMask),
    (component: 'hover', variant: 'default', unit: _kHover),
    (component: 'hover', variant: 'fade', unit: _kHover),
    (component: 'indicator', variant: 'default', unit: _kIndicator),
    (component: 'indicator', variant: 'bottom-start', unit: _kIndicator),
  ];
  for (final recipe in recipes) {
    for (final theme in ParityTheme.values) {
      test(
        '${recipe.component}/${recipe.variant}/${theme.name} actual SSR',
        () async {
          final tree = await _actual(
            recipe.component,
            recipe.variant,
            theme: theme.name,
          );
          final result = await _resolve(tree, recipe.unit);
          expect(result['error'], isNull);
          for (final key in ['registry', 'unit', 'padding', 'frame']) {
            expect(result[key], [0]);
          }
          expect(result['hasValue'], false);
        },
      );
    }
  }
  test('missing and duplicate public host cells reject', () async {
    for (final entry in [
      ('mask', _kMask),
      ('hover', _kHover),
      ('indicator', _kIndicator),
    ]) {
      final tree = await _actual(entry.$1, 'default');
      for (final mutation in [
        'root.children=[];',
        'root.children.push(root.children[0]);',
      ]) {
        expect(
          (await _resolve(tree, entry.$2, mutation: mutation))['error'],
          isNotNull,
        );
      }
    }
  });
  test('foreign content cannot donate an overlay or host', () async {
    final tree = await _actual('indicator', 'default');
    for (final mutation in [
      "root.children[1].tagName='SPAN';",
      'root.children[1].children=[];',
      'root.children[1].children.push(root.children[0]);',
      'root.children[1].children[0]=root.children[0];',
    ]) {
      expect(await _resolve(tree, _kIndicator, mutation: mutation), {
        'error': 'INDICATOR_SOURCE_ROUTE_CHANGED',
      });
    }
  });
  test('wrapper/capture/tuple mutations stay fail closed', () async {
    final tree = await _actual('mask', 'default');
    for (final mutation in [
      "root.tagName='SECTION';",
      'root.classList={contains:()=>false};',
      'root.parentElement=null;',
      'capture.children.push(root);',
      'source.schemaVersion=99;',
      "source.quantityId='stale';",
      "source.logicalUnitId='unknown';",
      "source.webAdapterId='stale';",
    ]) {
      expect(
        (await _resolve(tree, _kMask, mutation: mutation))['error'],
        isNotNull,
      );
    }
  });
  test('caller padding is not an eligibility value or zero override', () async {
    final tree = await _actual('hover', 'default');
    final before = await _resolve(tree, _kHover);
    final after = await _resolve(
      tree,
      _kHover,
      mutation: "root.getAttribute=name=>name==='style'?'padding:12px':null;",
    );
    expect(after, before);
    expect(after['hasValue'], false);
  });
}
