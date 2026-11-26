import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_structured_root_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _kRecipes = <({String component, String variant})>[
  (component: 'basic', variant: 'default'),
  (component: 'disclosure-badge', variant: 'default'),
  (component: 'disclosure-badge', variant: 'commitment'),
  (component: 'multiple-choice', variant: 'default'),
  (component: 'page-header', variant: 'default'),
  (component: 'sidebar', variant: 'default'),
  (component: 'sidebar', variant: 'two-pane'),
  (component: 'sidebar', variant: 'collapsed'),
  (component: 'tab-pane', variant: 'default'),
  (component: 'tab-pane', variant: 'editor-strip'),
  (component: 'tree', variant: 'default'),
  (component: 'tree', variant: 'selected'),
  (component: 'timeline', variant: 'default'),
  (component: 'category-breakdown', variant: 'default'),
  (component: 'category-breakdown', variant: 'donut'),
  (component: 'trend-chart', variant: 'default'),
  (component: 'trend-chart', variant: 'bar'),
  (component: 'window-panel', variant: 'default'),
];
BoxObservationSourceSpec _source(String component) => switch (component) {
  'basic' => BoxObservationSourceSpec.basicContentInset,
  'disclosure-badge' =>
    BoxObservationSourceSpec.disclosureBadgeSolidContentInset,
  'multiple-choice' => BoxObservationSourceSpec.multipleChoiceLayoutHost,
  'page-header' => BoxObservationSourceSpec.pageHeaderLayoutHost,
  'sidebar' => BoxObservationSourceSpec.sidebarOuterLayoutHost,
  'tab-pane' => BoxObservationSourceSpec.tabPaneBarContentInset,
  'tree' => BoxObservationSourceSpec.treeOuterLayoutHost,
  'timeline' => BoxObservationSourceSpec.timelineSequenceLayoutHost,
  'category-breakdown' => BoxObservationSourceSpec.categoryBreakdownLayoutHost,
  'trend-chart' => BoxObservationSourceSpec.trendChartOuterLayoutHost,
  'window-panel' => BoxObservationSourceSpec.windowPanelFrameContentInset,
  _ => throw ArgumentError(component),
};
const _kRuntime = r'''
const node=(data,parent=null)=>{
 const attrs={...data.attributes},list=(attrs.class??'').split(/\s+/).filter(Boolean);
 const element={tagName:data.tagName,path:data.path,attributes:attrs,parentElement:parent,
  isConnected:true,getAttribute:name=>attrs[name]??null,
  hasAttribute:name=>Object.hasOwn(attrs,name),
  classList:{contains:name=>list.includes(name),[Symbol.iterator]:function*(){yield* list;}}};
 element._list=data.children.map(c=>node(c,element));
 Object.defineProperty(element,'children',{get(){const c={length:element._list.length};
  element._list.forEach((child,i)=>c[i]=child);return c;}});
 element.contains=other=>element===other || element._list.some(c=>c.contains(other));
 for(const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
  Object.defineProperty(element,name,{get(){throw Error('Numeric owner selection forbidden');}});
 return element;
};
''';
Map<String, Object?> _tree(dom.Element element, List<int> path) => {
  'tagName': element.localName!.toUpperCase(),
  'attributes': {
    for (final a in element.attributes.entries) a.key.toString(): a.value,
  },
  'path': path,
  'children': [
    for (var i = 0; i < element.children.length; i++)
      _tree(element.children[i], [...path, i]),
  ],
};
typedef _Actual = ({Map<String, Object?> tree, List<int> field});
final _cache = <String, Future<_Actual>>{};
Future<_Actual> _actual(
  String component,
  String variant, {
  String theme = 'light',
}) => _cache.putIfAbsent('$component/$variant/$theme', () async {
  final key = '$component-$variant-$theme-defaultStyle';
  final probes = captureProbes(
    key: key,
    component: component,
    variant: variant,
    flutterClassName: 'source-only',
  );
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': probes.map((p) => p.toJson()).toList(),
  });
  final body = await renderCaptureBodyHtml(entry);
  final document = html.parseFragment(body);
  final capture = document.querySelectorAll('[data-parity-key]').single;
  final root = document.querySelectorAll(probes.single.webSelector).single;
  expect(root, same(capture.children.single));
  var field = root;
  if (component == 'sidebar' ||
      component == 'window-panel' ||
      component == 'timeline') {
    field = root.children.single;
  }
  if (component == 'tab-pane') {
    final seats = root.children.where((n) => n.localName != 'style').toList();
    field = seats.first;
    expect(field.attributes['role'], 'tablist');
  }
  final path = <int>[];
  var current = field;
  while (!identical(current, capture)) {
    final parent = current.parent!;
    path.insert(0, parent.children.indexOf(current));
    current = parent;
  }
  return (tree: _tree(capture, []), field: path);
});
Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  BoxObservationSourceSpec source, {
  String mutation = '',
}) async {
  final program =
      '''
$_kRuntime
const capture=node(${jsonEncode(tree)}),root=capture.children[0];
const source=${jsonEncode(source.toJson())};
const resolve=($structuredRootBoxSourceResolverScript);
global.getComputedStyle=()=>{throw Error('CSS owner selection forbidden');};
global.document=new Proxy({},{get(){throw Error('Global search forbidden');}});
$mutation
const result=resolve(root,source);
console.log(JSON.stringify(result.error?result:{registry:result.registryResultElement.path,
 unit:result.fieldUnitElement.path,padding:result.paddingSource.path,frame:result.frameSource.path,
 registryIsLayoutRoot:result.registryIsLayoutRoot,hasValue:Object.hasOwn(result,'value')}));
''';
  final result = await Process.run('node', ['-e', program]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return (jsonDecode(result.stdout.toString()) as Map).cast<String, Object?>();
}

void main() {
  for (final recipe in _kRecipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme actual SSR source refs',
        () async {
          final actual = await _actual(
            recipe.component,
            recipe.variant,
            theme: theme,
          );
          final result = await _resolve(actual.tree, _source(recipe.component));
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          for (final ref in ['unit', 'padding', 'frame']) {
            expect(result[ref], actual.field);
          }
          expect(result['registryIsLayoutRoot'], true);
          expect(result['hasValue'], false);
        },
      );
    }
    for (final style in ['neoBrutalism', 'neumorphism', 'futureSurface']) {
      test(
        '${recipe.component}/${recipe.variant}/$style keeps source refs',
        () async {
          final actual = await _actual(recipe.component, recipe.variant);
          final before = await _resolve(actual.tree, _source(recipe.component));
          final after = await _resolve(
            actual.tree,
            _source(recipe.component),
            mutation:
                "capture.attributes['data-parity-key']="
                "'${recipe.component}-${recipe.variant}-light-$style';",
          );
          expect(after, before);
        },
      );
    }
    test(
      '${recipe.component}/${recipe.variant} ignores capture key value',
      () async {
        final actual = await _actual(recipe.component, recipe.variant);
        final before = await _resolve(actual.tree, _source(recipe.component));
        final after = await _resolve(
          actual.tree,
          _source(recipe.component),
          mutation: "capture.attributes['data-parity-key']='arbitrary-id';",
        );
        expect(after, before);
      },
    );
    for (final mutation in [
      'source.schemaVersion=99;',
      'source.quantityId="unknown";',
      'source.nativeAdapterId="unknown";',
      'source.webAdapterId="unknown";',
      'capture._list.push(root);',
      'root.parentElement=null;',
      'root.isConnected=false;',
      'root.tagName="SECTION";',
      "delete capture.attributes['data-parity-key'];",
      'root._list=[];',
      'root._list.push(root._list[0]);',
    ]) {
      test('${recipe.component}/${recipe.variant} rejects $mutation', () async {
        final actual = await _actual(recipe.component, recipe.variant);
        expect(
          (await _resolve(
            actual.tree,
            _source(recipe.component),
            mutation: mutation,
          ))['error'],
          isNotNull,
        );
      });
    }
    test(
      '${recipe.component}/${recipe.variant} foreign changes keep source',
      () async {
        final actual = await _actual(recipe.component, recipe.variant);
        final before = await _resolve(actual.tree, _source(recipe.component));
        final after = await _resolve(
          actual.tree,
          _source(recipe.component),
          mutation: '''
const first=resolve(root,source);
if(first.error)throw Error(first.error);
const field=first.fieldUnitElement;
field.attributes.style='padding:23px 17px 11px 5px;border-width:7px';
const foreign=field._list.find(n=>n.tagName!=='STYLE');
if(foreign){
 foreign.attributes.style='padding:999px';
 foreign._list.push(node({tagName:'DIV',attributes:{role:'tablist',class:'flex flex-col w-full'},
   path:[999],children:[]},foreign));
}
''',
        );
        expect(after, before);
      },
    );
  }
  for (final variant in ['default', 'editor-strip']) {
    test('empty $variant bar keeps source', () async {
      final actual = await _actual('tab-pane', variant);
      final before = await _resolve(actual.tree, _source('tab-pane'));
      final after = await _resolve(
        actual.tree,
        _source('tab-pane'),
        mutation:
            "root._list.find(n=>n.getAttribute('role')==='tablist')._list=[];",
      );
      expect(after, before);
    });
  }
  test('a nested tablist cannot replace missing source bar', () async {
    final actual = await _actual('tab-pane', 'default');
    final result = await _resolve(
      actual.tree,
      _source('tab-pane'),
      mutation: '''
const bar=root._list.find(n=>n.getAttribute('role')==='tablist');
bar.attributes.role='presentation';
const panel=root._list.find(n=>n.getAttribute('role')==='tabpanel');
panel._list.push(node({tagName:'DIV',attributes:{role:'tablist'},path:[999],children:[]},panel));
''',
    );
    expect(result['error'], isNotNull);
  });
  test('actual dashed operation cannot use the solid source tuple', () async {
    final actual = await _actual('disclosure-badge', 'private');
    expect(
      (await _resolve(actual.tree, _source('disclosure-badge')))['error'],
      isNotNull,
    );
  });
  test('changed solid operation fails closed', () async {
    final actual = await _actual('disclosure-badge', 'default');
    expect(
      (await _resolve(
        actual.tree,
        _source('disclosure-badge'),
        mutation:
            "root.classList={contains:k=>['inline-flex','items-center',"
            "'border-dashed'].includes(k)};",
      ))['error'],
      isNotNull,
    );
  });
}
