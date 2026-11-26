import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_collection_layout_host_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const BoxObservationSourceSpec _kCalendar =
    BoxObservationSourceSpec.calendarLayoutHost;
const BoxObservationSourceSpec _kDefinition =
    BoxObservationSourceSpec.definitionListLayoutHost;
const _kRecipes =
    <({String component, String variant, BoxObservationSourceSpec source})>[
      (component: 'calendar', variant: 'single', source: _kCalendar),
      (component: 'calendar', variant: 'range', source: _kCalendar),
      (component: 'calendar', variant: 'multi', source: _kCalendar),
      (component: 'calendar', variant: 'none', source: _kCalendar),
      (component: 'calendar', variant: 'markers', source: _kCalendar),
      (component: 'definition-list', variant: 'default', source: _kDefinition),
      (component: 'definition-list', variant: 'columns', source: _kDefinition),
      (component: 'definition-list', variant: 'inline', source: _kDefinition),
    ];

Map<String, Object?> _tree(dom.Element node, List<int> path) => {
  'tagName': node.localName!.toUpperCase(),
  'attributes': {
    for (final e in node.attributes.entries) e.key.toString(): e.value,
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
  String surfaceStyle = 'defaultStyle',
}) async {
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme,
    'surfaceStyle': surfaceStyle,
    'tier': 't1',
    'probes': <Object?>[],
  });
  final body = await renderCaptureBodyHtml(entry);
  final output = Platform.environment['COLLECTION_LAYOUT_HOST_SSR_OUTPUT'];
  if (output != null) {
    final file = File('$output/${entry.key}.body.html');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(body);
  }
  final capture = html
      .parseFragment(body)
      .querySelectorAll('[data-parity-key]');
  expect(capture, hasLength(1));
  expect(capture.single.attributes['data-parity-key'], entry.key);
  expect(capture.single.children, hasLength(1));
  return _tree(capture.single, const []);
}

Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  BoxObservationSourceSpec spec, {
  String mutation = '',
}) async {
  final result = await Process.run('node', [
    '-e',
    '''
const resolve=($collectionLayoutHostBoxSourceResolverScript);
global.getComputedStyle=()=>{throw Error('CSS read forbidden');};
global.document=new Proxy({}, {get(){throw Error('Global search forbidden');}});
const node=(data,parent=null)=>{
  const attrs=data.attributes;
  const value={tagName:data.tagName,path:data.path,parentElement:parent,
    getAttribute:name=>attrs[name]??null,
    hasAttribute:name=>Object.hasOwn(attrs,name),
    classList:{contains:name=>(attrs.class??'').split(/\\s+/).includes(name)}};
  for(const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
    Object.defineProperty(value,name,{get(){throw Error('Numeric read forbidden');}});
  value.children=data.children.map(child=>node(child,value));return value;
};
const capture=node(${jsonEncode(tree)}),root=capture.children[0];
const source=${jsonEncode(spec.toJson())};
$mutation
// Real HTMLCollection is array-like, not an Array with map/some/push. Build
// mutations above, then expose only browser collection operations to resolver.
const browserChildren=parent=>{
  const children=Array.from(parent.children);
  children.forEach(browserChildren);
  const collection={length:children.length,item:index=>children[index]??null};
  children.forEach((child,index)=>{collection[index]=child;});
  parent.children=collection;
};
browserChildren(capture);
const r=resolve(root,source);
const result=r.error?r:{registry:r.registryResultElement.path,
  unit:r.fieldUnitElement.path,padding:r.paddingSource.path,frame:r.frameSource.path,
  hasValue:Object.hasOwn(r,'value'),authority:r.authority};
console.log(JSON.stringify({...result,
  arrayChildren:Array.isArray(root.children),childrenSome:typeof root.children.some}));
''',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
}

void main() {
  // Actual public SSR plus Node refs-only checks; no browser/CSSOM/paint claim.
  for (final recipe in _kRecipes) {
    for (final theme in ParityTheme.values) {
      test(
        '${recipe.component}/${recipe.variant}/${theme.name} actual SSR refs',
        () async {
          final result = await _resolve(
            await _actual(recipe.component, recipe.variant, theme: theme.name),
            recipe.source,
          );
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          for (final field in ['unit', 'padding', 'frame']) {
            expect(result[field], recipe.variant == 'columns' ? [0, 0] : [0]);
          }
          expect(result['hasValue'], false);
          expect(result['arrayChildren'], false);
          expect(result['childrenSome'], 'undefined');
        },
      );
    }
  }
  for (final recipe in [_kRecipes[0], _kRecipes[5]]) {
    test(
      '${recipe.component} closed tuple/capture/missing/duplicate/unknown rejection',
      () async {
        final tree = await _actual(recipe.component, recipe.variant);
        const mutations = [
          'root.parentElement=null;',
          'capture.children.push(root);',
          "root.tagName='SECTION';",
          'capture.hasAttribute=()=>false;',
          'source.schemaVersion=99;',
          "source.quantityId='unknown';",
          "source.logicalUnitId='unknown';",
          "source.nativeAdapterId='unknown';",
          "source.webAdapterId='unknown';",
          'root.children=[];',
        ];
        for (final mutation in mutations) {
          if (recipe.component == 'definition-list' &&
              mutation == 'root.children=[];') {
            continue;
          }
          final result = await _resolve(
            tree,
            recipe.source,
            mutation: mutation,
          );
          expect(result['error'], isNotNull, reason: mutation);
          expect(result.containsKey('value'), false);
        }
      },
    );
    test(
      '${recipe.component} caller CSS and foreign content preserve owner',
      () async {
        final tree = await _actual(recipe.component, recipe.variant);
        final before = await _resolve(tree, recipe.source);
        final after = await _resolve(
          tree,
          recipe.source,
          mutation: const [
            'const originalAttribute=root.getAttribute;',
            "root.getAttribute=name=>name==='style'?'padding:37px':",
            'originalAttribute(name);',
            "root.children[0].children.push(node({tagName:'DIV',path:[99],",
            "attributes:{style:'padding:61px'},children:[]},",
            'root.children[0]));',
          ].join(),
        );
        expect(after, before);
        final withStyle = await _resolve(
          tree,
          recipe.source,
          mutation: const [
            "root.children.unshift(node({tagName:'STYLE',path:[99],",
            'attributes:{},children:[]},root));',
          ].join(),
        );
        expect(withStyle, before);
      },
    );
  }
  test(
    'DefinitionList columns keeps the source DL and rich content boundary',
    () async {
      final tree = await _actual('definition-list', 'columns');
      for (final mutation in const [
        'root.children[0].children.push(root.children[0].children[0]);',
        "root.children[0].children[1].tagName='DIV';",
        'root.children[0].children.reverse();',
      ]) {
        expect(
          (await _resolve(tree, _kDefinition, mutation: mutation))['error'],
          isNotNull,
        );
      }
      final before = await _resolve(tree, _kDefinition);
      final after = await _resolve(
        tree,
        _kDefinition,
        mutation: const [
          'const description=root.children[0].children[1];',
          "description.children.push(node({tagName:'DL',path:[99],",
          "attributes:{class:'grid',style:'padding:99px'},children:[]},",
          'description));',
        ].join(),
      );
      expect(after, before);
      for (final mutation in const [
        'root.children.push(root.children[0]);',
        'capture.hasAttribute=()=>false;',
        "root.children[0].tagName='DIV';",
      ]) {
        expect(
          (await _resolve(tree, _kDefinition, mutation: mutation))['error'],
          isNotNull,
        );
      }
    },
  );
  for (final style in CoreSurfaceStyleId.values) {
    for (final theme in ParityTheme.values) {
      test(
        'DefinitionList columns source ${style.name}/${theme.name}',
        () async {
          final tree = await _actual(
            'definition-list',
            'columns',
            theme: theme.name,
            surfaceStyle: style.name,
          );
          final before = await _resolve(tree, _kDefinition);
          expect(before['error'], isNull);
          expect(before['unit'], [0, 0]);
          final renamed = await _resolve(
            tree,
            _kDefinition,
            mutation: const [
              'const original=capture.getAttribute;',
              "capture.getAttribute=name=>name==='data-parity-key'",
              "?'independent-capture-name-future-surface':original(name);",
            ].join(),
          );
          expect(renamed, before);
        },
      );
    }
  }
  test(
    'Calendar content host cannot be missing, duplicated, or promoted to field',
    () async {
      final tree = await _actual('calendar', 'range');
      for (final mutation in const [
        'root.children.push(root.children[0]);',
        "root.children[0].tagName='SPAN';",
        'root.getAttribute=()=>null;',
      ]) {
        expect(
          (await _resolve(tree, _kCalendar, mutation: mutation))['error'],
          isNotNull,
        );
      }
      expect((await _resolve(tree, _kDefinition))['error'], isNotNull);
      expect(
        (await _resolve(
          await _actual('definition-list', 'default'),
          _kCalendar,
        ))['error'],
        isNotNull,
      );
    },
  );
}
