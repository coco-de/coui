import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_surface_component_units_probe.dart';
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

Future<Map<String, Object?>> _actualTree(
  String component,
  String variant,
) async {
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': 'light',
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
  BoxObservationSourceSpec source, {
  String mutation = '',
}) async {
  final result = await Process.run('node', [
    '-e',
    '''
const resolve = ($displayBoxSourceResolverScript);
global.getComputedStyle = () => { throw Error('CSS reads forbidden'); };
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
const capture=node(${jsonEncode(tree)});
const root=capture.children[0];
const source=${jsonEncode(source.toJson())};
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
  const recipes = <({String component, String variant})>[
    (component: 'avatar', variant: 'default'),
    (component: 'avatar', variant: 'rounded'),
    (component: 'code-snippet', variant: 'default'),
    (component: 'mockup-code', variant: 'default'),
    (component: 'mockup-code', variant: 'tones'),
    (component: 'stat', variant: 'default'),
    (component: 'stat', variant: 'outlined'),
    (component: 'stat', variant: 'empty'),
    (component: 'validation-badge', variant: 'default'),
    (component: 'validation-badge', variant: 'pending'),
    (component: 'validation-badge', variant: 'invalid'),
    (component: 'validation-badge', variant: 'medium'),
  ];
  for (final recipe in recipes) {
    for (final theme in ParityTheme.values) {
      test(
        '${recipe.component}/${recipe.variant}/${theme.name} actual SSR refs',
        () async {
          final entry = MatrixEntry.fromJson({
            'component': recipe.component,
            'variant': recipe.variant,
            'theme': theme.name,
            'surfaceStyle': 'defaultStyle',
            'tier': 't1',
            'probes': <Object?>[],
          });
          final body = await renderCaptureBodyHtml(entry);
          final captures = html
              .parseFragment(body)
              .querySelectorAll('[data-parity-key]');
          expect(captures, hasLength(1));
          expect(captures.single.children, hasLength(1));
          final result = await _resolve(
            _tree(captures.single, const []),
            _source(recipe.component),
          );
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          expect(result['unit'], [0]);
          expect(result['hasValue'], false);
          if (recipe.component == 'mockup-code') {
            // Actual split source references only, not paired eligibility.
            expect(result['frame'], [0, 0]);
            expect(result['padding'], [0, 0, 0]);
            expect(result['authority'], contains('pairing pending'));
          } else {
            expect(result['padding'], [0]);
            expect(result['frame'], [0]);
          }
        },
      );
    }
  }
  test(
    'missing/duplicate direct frame cannot borrow a nested matching box',
    () async {
      final tree = await _actualTree('mockup-code', 'default');
      for (final mutation in [
        'root.children=[];',
        'root.children.push(root.children[0]);',
        "root.children[0].tagName='SECTION';",
        'root.children[0].children=[];',
        'root.children[0].children.push(root.children[0].children[0]);',
      ]) {
        final result = await _resolve(
          tree,
          _source('mockup-code'),
          mutation: mutation,
        );
        expect(result, {'error': 'MOCKUP_CODE_SPLIT_SOURCE_CHANGED'});
      }
    },
  );
  test(
    'Avatar overlay wrapper cannot borrow its inner avatar or badge',
    () async {
      final tree = await _actualTree('avatar', 'default');
      final result = await _resolve(
        tree,
        _source('avatar'),
        mutation: 'root.classList={contains:()=>false};',
      );
      expect(result, {'error': 'AVATAR_DECLARED_FRAME_CHANGED'});
    },
  );
  test('unknown/stale tuple and changed capture remain fail closed', () async {
    final tree = await _actualTree('stat', 'default');
    for (final entry in [
      ('source.schemaVersion=99;', 'UNSUPPORTED_BOX_SOURCE_VERSION'),
      ("source.quantityId='unknown';", 'UNSUPPORTED_BOX_QUANTITY'),
      ("source.logicalUnitId='unknown';", 'UNREGISTERED_DISPLAY_CONSTRUCTION'),
      ("source.webAdapterId='old';", 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH'),
      ('capture.children=[];', 'MISMATCHED_DISPLAY_CAPTURE_ROOT'),
      ('capture.children.push(root);', 'MISMATCHED_DISPLAY_CAPTURE_ROOT'),
      ('root.parentElement=null;', 'MISMATCHED_DISPLAY_CAPTURE_ROOT'),
    ]) {
      expect(await _resolve(tree, _source('stat'), mutation: entry.$1), {
        'error': entry.$2,
      });
    }
  });
}
