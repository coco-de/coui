import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_solid_layout_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _bar = 'app-bar-solid-content-inset';
const _empty = 'empty-state-generated-content-inset';

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
const resolve = ($solidLayoutBoxSourceResolverScript);
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
  const recipes = <({String component, String variant})>[
    (component: 'app-bar', variant: 'default'),
    (component: 'app-bar', variant: 'compact'),
    (component: 'app-bar', variant: 'dense'),
    (component: 'app-bar', variant: 'prominent'),
    (component: 'app-bar', variant: 'centered'),
    (component: 'app-bar', variant: 'text'),
    (component: 'empty-state', variant: 'default'),
    (component: 'empty-state', variant: 'large'),
    (component: 'empty-state', variant: 'failure'),
    (component: 'empty-state', variant: 'success'),
  ];
  for (final recipe in recipes) {
    for (final theme in ParityTheme.values) {
      test(
        '${recipe.component}/${recipe.variant}/${theme.name} actual SSR refs',
        () async {
          final tree = await _actual(
            recipe.component,
            recipe.variant,
            theme: theme.name,
          );
          final result = await _resolve(
            tree,
            recipe.component == 'app-bar' ? _bar : _empty,
          );
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          final unit = recipe.component == 'empty-state' ? [0, 0] : [0];
          expect(result['unit'], unit);
          expect(result['padding'], unit);
          expect(result['frame'], unit);
          expect(result['hasValue'], false);
        },
      );
    }
  }

  test('actual medium is not a solid root content-padding source', () async {
    expect(await _resolve(await _actual('app-bar', 'medium'), _bar), {
      'error': 'UNSUPPORTED_APP_BAR_SOURCE_BRANCH',
    });
  });

  test('changed glass/wrapper/missing/duplicate content rejects', () async {
    final tree = await _actual('app-bar', 'default');
    for (final mutation in [
      "root.hasAttribute=name=>name==='data-coui-app-bar-glass';",
      "root.tagName='SECTION';",
      'root.children=[];',
      // A second actual title-block identity cannot be arbitrarily selected.
      '''
root.children.push(root.children.find(child=>
  !child.hasAttribute('data-coui-app-bar-leading') &&
  !child.hasAttribute('data-coui-app-bar-trailing')));
''',
    ]) {
      expect(
        (await _resolve(tree, _bar, mutation: mutation))['error'],
        isNotNull,
      );
    }
  });

  test('EmptyState missing/duplicate own text block is not borrowed', () async {
    final tree = await _actual('empty-state', 'large');
    for (final mutation in [
      'root.children[0].children=[];',
      '''
root.children[0].children.push(root.children[0].children.find(child=>
  child.classList.contains('flex-col')));
''',
    ]) {
      expect(await _resolve(tree, _empty, mutation: mutation), {
        'error': 'EMPTY_STATE_TEXT_BOUNDARY_CHANGED',
      });
    }
  });

  test('EmptyState registry wrapper is a closed direct source route', () async {
    final tree = await _actual('empty-state', 'default');
    for (final mutation in [
      'root.children=[];',
      'root.children.push(root.children[0]);',
      "root.getAttribute=()=> 'w-full extra';",
      "root.tagName='SECTION';",
    ]) {
      expect(await _resolve(tree, _empty, mutation: mutation), {
        'error': 'EMPTY_STATE_REGISTRY_WRAPPER_CHANGED',
      });
    }
  });

  test('foreign nested boxes cannot change root source refs', () async {
    final tree = await _actual('app-bar', 'default');
    final original = await _resolve(tree, _bar);
    final mutated = await _resolve(
      tree,
      _bar,
      mutation: '''
const title=root.children.find(child=>!child.hasAttribute('data-coui-app-bar-leading')&&!child.hasAttribute('data-coui-app-bar-trailing'));
title.children.push(node({tagName:'DIV',path:[99],attributes:{class:'p-space64 flex flex-row items-center w-full box-border'},children:[]},title));
''',
    );
    expect(mutated, original);
  });

  test('stale tuple and capture provenance fail closed', () async {
    final tree = await _actual('empty-state', 'default');
    for (final entry in [
      ('source.schemaVersion=99;', 'UNSUPPORTED_BOX_SOURCE_VERSION'),
      ("source.quantityId='stale';", 'UNSUPPORTED_BOX_QUANTITY'),
      (
        "source.logicalUnitId='unknown';",
        'UNREGISTERED_SOLID_LAYOUT_CONSTRUCTION',
      ),
      ("source.webAdapterId='stale';", 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH'),
      ('capture.children=[];', 'MISMATCHED_SOLID_LAYOUT_CAPTURE'),
      ('capture.children.push(root);', 'MISMATCHED_SOLID_LAYOUT_CAPTURE'),
      ('root.parentElement=null;', 'MISMATCHED_SOLID_LAYOUT_CAPTURE'),
    ]) {
      expect(await _resolve(tree, _empty, mutation: entry.$1), {
        'error': entry.$2,
      });
    }
  });
}
