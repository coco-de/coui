import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_control_shell_units_probe.dart';
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

Future<Map<String, Object?>> _actual(String component, String variant) async {
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': 'light',
    'surfaceStyle': 'defaultStyle',
    'tier': 't1',
    'probes': <Object?>[],
  });
  final document = html.parseFragment(await renderCaptureBodyHtml(entry));
  final captures = document.querySelectorAll('[data-parity-key]');
  expect(captures, hasLength(1));
  return _tree(captures.single, const []);
}

Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  BoxObservationSourceSpec source, {
  String mutation = '',
}) async {
  final result = await Process.run('node', [
    '-e',
    '''
const resolve = ($controlShellBoxSourceResolverScript);
global.getComputedStyle = () => {throw Error('CSS read forbidden');};
global.document = new Proxy({}, {get(){throw Error('Global query forbidden');}});
const node = (data,parent=null) => {
  const attributes = data.attributes;
  const value = {tagName:data.tagName,path:data.path,parentElement:parent,
    getAttribute:name=>attributes[name] ?? null,
    hasAttribute:name=>Object.hasOwn(attributes,name),
    classList:{contains:name=>(attributes.class ?? '').split(/\\s+/).includes(name)}};
  for (const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
    Object.defineProperty(value,name,{get(){throw Error('Numeric read forbidden');}});
  value.children = data.children.map(child=>node(child,value));
  return value;
};
const capture=node(${jsonEncode(tree)});
const root=capture.children[0];
const source=${jsonEncode(source.toJson())};
$mutation
const value=resolve(root,source);
console.log(JSON.stringify(value.error ? value : {
  registry:value.registryResultElement.path,unit:value.fieldUnitElement.path,
  padding:value.paddingSource.path,frame:value.frameSource.path,
  hasValue:Object.hasOwn(value,'value'),authority:value.authority}));
''',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
}

final String _removeNumberInput = const [
  'const visit=n=>[n,...n.children.flatMap(visit)];const inpu',
  "t=visit(root).find(n=>n.tagName==='INPUT');input.parentEle",
  'ment.children=[];',
].join();

final String _duplicateNumberInput = const [
  'const visit=n=>[n,...n.children.flatMap(visit)];const inpu',
  "t=visit(root).find(n=>n.tagName==='INPUT');input.parentEle",
  'ment.children.push(input);',
].join();

final String _moveNumberInput = const [
  'const visit=n=>[n,...n.children.flatMap(visit)];const inpu',
  "t=visit(root).find(n=>n.tagName==='INPUT');input.parentEle",
  'ment.parentElement.children.push(input);',
].join();

const _duplicateFieldRoot = 'root.children.push(root.children[0]);';

final String _unknownFieldCell = const [
  "root.children[0].children.push({tagName:'ASIDE',children:[",
  ']});',
].join();

final String _removeChipBody = const [
  "root.children=root.children.filter(n=>n.tagName==='STYLE')",
  ';',
].join();

final String _duplicateChipBody = const [
  "const body=root.children.find(n=>n.tagName!=='STYLE');root",
  '.children.push(body);',
].join();

final String _wrongChipTag = const [
  "const body=root.children.find(n=>n.tagName!=='STYLE');body",
  ".tagName='SPAN';",
].join();

final String _nestChipBody = const [
  "const body=root.children.find(n=>n.tagName!=='STYLE');root",
  ".children=[{tagName:'DIV',children:[body],classList:{conta",
  'ins:()=>false}}];',
].join();

void main() {
  const recipes = <({String component, String variant, String unit})>[
    (
      component: 'number-input',
      variant: 'default',
      unit: 'number-input-generated-field-frame',
    ),
    (
      component: 'number-input',
      variant: 'filled',
      unit: 'number-input-generated-field-frame',
    ),
    (
      component: 'number-input',
      variant: 'error',
      unit: 'number-input-generated-field-frame',
    ),
    (
      component: 'number-input',
      variant: 'disabled',
      unit: 'number-input-generated-field-frame',
    ),
    (component: 'chip', variant: 'removable', unit: 'chip-generated-frame'),
    (component: 'chip', variant: 'disabled', unit: 'chip-generated-frame'),
  ];
  for (final recipe in recipes) {
    for (final theme in ParityTheme.values) {
      test(
        '${recipe.component}/${recipe.variant}/${theme.name} actual SSR',
        () async {
          final entry = MatrixEntry.fromJson({
            'component': recipe.component,
            'variant': recipe.variant,
            'theme': theme.name,
            'surfaceStyle': 'defaultStyle',
            'tier': 't1',
            'probes': <Object?>[],
          });
          final document = html.parseFragment(
            await renderCaptureBodyHtml(entry),
          );
          final captures = document.querySelectorAll('[data-parity-key]');
          expect(captures, hasLength(1));
          final result = await _resolve(
            _tree(captures.single, const []),
            _source(recipe.unit),
          );
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          expect(result['padding'], result['frame']);
          expect(result['unit'], result['frame']);
          expect(result['unit'], isNot([0]));
          expect(result['hasValue'], false);
        },
      );
    }
  }

  test(
    'NumberInput missing/duplicate/input-slot and frame mutations reject',
    () async {
      final tree = await _actual('number-input', 'default');
      for (final mutation in [
        _removeNumberInput,
        _duplicateNumberInput,
        _moveNumberInput,
        _duplicateFieldRoot,
        _unknownFieldCell,
      ]) {
        final result = await _resolve(
          tree,
          _source('number-input-generated-field-frame'),
          mutation: mutation,
        );
        expect(result['error'], isNotNull);
      }
    },
  );

  test(
    'Chip matching foreign descendant never replaces missing direct body',
    () async {
      final tree = await _actual('chip', 'removable');
      for (final mutation in [
        _removeChipBody,
        _duplicateChipBody,
        _wrongChipTag,
        _nestChipBody,
      ]) {
        final result = await _resolve(
          tree,
          _source('chip-generated-frame'),
          mutation: mutation,
        );
        expect(result['error'], isNotNull);
      }
    },
  );

  test(
    'unknown version/quantity/adapter/root reject without a numeric fallback',
    () async {
      final tree = await _actual('chip', 'disabled');
      final json = _source('chip-generated-frame').toJson();
      for (final mutation in <Map<String, Object?>>[
        {...json, 'schemaVersion': 2},
        {...json, 'logicalUnitId': 'unknown'},
        {...json, 'quantityId': 'unknown'},
        {...json, 'nativeAdapterId': 'number-input-generated-field-frame-v1'},
      ]) {
        final result = await _resolve(
          tree,
          BoxObservationSourceSpec.fromJson(mutation),
        );
        expect(result['error'], isNotNull);
      }
      final result = await _resolve(
        tree,
        _source('chip-generated-frame'),
        mutation: 'capture.children.push(root);',
      );
      expect(result['error'], 'MISMATCHED_COMPONENT_CAPTURE_ROOT');
    },
  );
}
