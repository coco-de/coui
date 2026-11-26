import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_layout_host_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

BoxObservationSourceSpec _source(String unit) => BoxObservationSourceSpec
    .layoutHostFrames
    .singleWhere((spec) => spec.logicalUnitId == unit);

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
    'tier': ['steps', 'stepper'].contains(component) ? 't1' : 't2',
    'probes': <Object?>[],
  });
  final prepared = Platform.environment['LAYOUT_HOST_SSR_DIR'];
  final body = prepared == null
      ? await renderCaptureBodyHtml(entry)
      : File('$prepared/${entry.key}.body.html').readAsStringSync();
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
const resolve = ($layoutHostBoxSourceResolverScript);
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
  const recipes = <(String, String, BoxObservationSourceSpec)>[
    ('steps', 'default', BoxObservationSourceSpec.stepsSequenceHost),
    ('steps', 'horizontal', BoxObservationSourceSpec.stepsSequenceHost),
    ('steps', 'list', BoxObservationSourceSpec.stepsSequenceHost),
    (
      'stepper',
      'vertical',
      BoxObservationSourceSpec.stepperVerticalSequenceHost,
    ),
    (
      'aspect-ratio-box',
      'default',
      BoxObservationSourceSpec.aspectRatioLayoutHost,
    ),
    ('clickable', 'default', BoxObservationSourceSpec.clickableInteractionHost),
    (
      'focus-outline',
      'default',
      BoxObservationSourceSpec.focusOutlinePassThroughHost,
    ),
    ('switch-field', 'default', BoxObservationSourceSpec.switchFieldControlRow),
  ];
  for (final recipe in recipes) {
    for (final theme in ParityTheme.values) {
      test('${recipe.$1}/${recipe.$2}/${theme.name} actual SSR refs', () async {
        final tree = await _actual(recipe.$1, recipe.$2, theme: theme.name);
        final result = await _resolve(tree, recipe.$3.logicalUnitId);
        expect(result['error'], isNull);
        expect(result['registry'], [0]);
        expect(result['unit'], result['padding']);
        expect(result['unit'], result['frame']);
        expect(result['hasValue'], false);
        if (recipe.$1 == 'aspect-ratio-box' || recipe.$2 == 'list') {
          expect(result['unit'], [0, 0]);
        }
        if (recipe.$1 == 'switch-field') {
          expect((result['unit']! as List).length, 2);
        }
      });
    }
  }
  test('capture and tuple guards reject all actual families', () async {
    for (final recipe in recipes) {
      final tree = await _actual(recipe.$1, recipe.$2);
      for (final mutation in [
        'source.schemaVersion=99;',
        'source.webAdapterId="unknown";',
        'capture.children.push(root);',
        'root.tagName="SPAN";',
      ]) {
        expect(
          (await _resolve(
            tree,
            recipe.$3.logicalUnitId,
            mutation: mutation,
          ))['error'],
          isNotNull,
        );
      }
    }
  });
  test('missing source children are never an absent value', () async {
    for (final recipe in recipes) {
      final tree = await _actual(recipe.$1, recipe.$2);
      expect(
        (await _resolve(
          tree,
          recipe.$3.logicalUnitId,
          mutation: 'root.children=[];',
        ))['error'],
        isNotNull,
      );
    }
  });
  test(
    'foreign ratio content and source wrapper cannot donate a host',
    () async {
      final tree = await _actual('aspect-ratio-box', 'default');
      for (final mutation in [
        'root.children[0].children[0].children.push(root);',
        'root.children.push(root.children[0]);',
        'root.children[0].children[1].children=[];',
      ]) {
        expect(
          (await _resolve(
            tree,
            BoxObservationSourceSpec.aspectRatioLayoutHost.logicalUnitId,
            mutation: mutation,
          ))['error'],
          isNotNull,
        );
      }
    },
  );
  test(
    'actual Clickable optional STYLE is a legal generated sibling',
    () async {
      final tree = await _actual('clickable', 'default');
      const unit = BoxObservationSourceSpec.clickableInteractionHost;
      expect((await _resolve(tree, unit.logicalUnitId))['error'], isNull);
      expect(
        (await _resolve(
          tree,
          unit.logicalUnitId,
          mutation: 'root.children.push(root.children.at(-1));',
        ))['error'],
        isNotNull,
      );
    },
  );
  test('caller CSS stays data and never selects an owner', () async {
    final tree = await _actual('clickable', 'default');
    final result = await _resolve(
      tree,
      BoxObservationSourceSpec.clickableInteractionHost.logicalUnitId,
      mutation:
          'root.getAttribute=(name)=>name==="style"?"padding:12px":'
          'name==="role"?"button":null;',
    );
    expect(result['error'], isNull);
    expect(result['hasValue'], false);
  });
}
