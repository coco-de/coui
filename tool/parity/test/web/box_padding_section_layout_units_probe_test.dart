import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/box_padding_section_layout_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _kRecipes = <({String component, String variant})>[
  (component: 'disclosure', variant: 'default'),
  (component: 'disclosure', variant: 'chain'),
  (component: 'disclosure', variant: 'group'),
  (component: 'collapsible', variant: 'default'),
  (component: 'resizable', variant: 'default'),
  (component: 'breadcrumb', variant: 'default'),
];
BoxObservationSourceSpec _source(String component, String variant) =>
    switch (component) {
      'disclosure' =>
        variant == 'group'
            ? BoxObservationSourceSpec.disclosureGroupLayoutHost
            : BoxObservationSourceSpec.disclosureHeaderContentInset,
      'collapsible' => BoxObservationSourceSpec.collapsibleSectionLayoutHost,
      'resizable' => BoxObservationSourceSpec.resizablePaneLayoutHost,
      _ => BoxObservationSourceSpec.breadcrumbTrailLayoutHost,
    };
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
Future<({Map<String, Object?> tree, List<int> field, String selector})> _actual(
  String component,
  String variant, {
  String theme = 'light',
}) async {
  final key = '$component-$variant-$theme-defaultStyle';
  final probes = captureProbes(
    key: key,
    component: component,
    variant: variant,
    flutterClassName: 'sanity-only',
  );
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': probes.map((p) => p.toJson()).toList(),
  });
  final prepared = Platform.environment['SECTION_LAYOUT_SSR_DIR'];
  final body = prepared == null
      ? await renderCaptureBodyHtml(entry)
      : File('$prepared/${entry.key}.body.html').readAsStringSync();
  final document = html.parseFragment(body);
  final captures = document.querySelectorAll('[data-parity-key]');
  expect(captures, hasLength(1));
  final capture = captures.single;
  final probe = probes.single;
  expect(probe.boxObservationSource, _source(component, variant));
  final roots = document.querySelectorAll(probe.webSelector);
  expect(roots, hasLength(1));
  final root = roots.single;
  expect(root, same(capture.children.single));
  final dom.Element field;
  if (component == 'disclosure' && variant != 'group') {
    expect(root.localName, 'div');
    expect(root.classes, contains('w-full'));
    final details = root.children.single;
    expect(details.localName, 'details');
    field = details.children.first;
    expect(field.localName, 'summary');
  } else if (component == 'resizable') {
    expect(root.classes, contains('coui-resizable-preview'));
    field = root.children.single;
    expect(field.classes, containsAll(['flex', 'w-full', 'h-full']));
  } else {
    field = root;
  }
  final route = <int>[];
  var current = field;
  while (!identical(current, capture)) {
    final parent = current.parent!;
    route.insert(0, parent.children.indexOf(current));
    current = parent;
  }
  return (
    tree: _tree(capture, const []),
    field: route,
    selector: probe.webSelector,
  );
}

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
Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  BoxObservationSourceSpec source, {
  String mutation = '',
  String? sharedSelector,
}) async {
  final program =
      '''
$_kRuntime
const capture=node(${jsonEncode(tree)}),root=capture.children[0];
const source=${jsonEncode(source.toJson())};
const resolve=($sectionLayoutBoxSourceResolverScript);
global.getComputedStyle=()=>{throw Error('CSS owner selection forbidden');};
global.document=new Proxy({},{get(){throw Error('Global search forbidden');}});
$mutation
const result=resolve(root,source);
let output=result.error?result:{registry:result.registryResultElement.path,
 unit:result.fieldUnitElement.path,padding:result.paddingSource.path,
 frame:result.frameSource.path,expanded:result.currentExpanded,
 registryIsLayoutRoot:result.registryIsLayoutRoot,hasValue:Object.hasOwn(result,'value')};
${sharedSelector == null ? '' : '''
const reads=[];
global.document={querySelectorAll:selector=>{
 if(selector!==${jsonEncode(sharedSelector)})throw Error('Unexpected selector');return [root];}};
global.getComputedStyle=element=>{reads.push(element.path);return {display:'block',
 paddingTop:'0px',paddingRight:'0px',paddingBottom:'0px',paddingLeft:'0px'};};
const observe=($boxPaddingObservationScript);
output.shared=JSON.parse(observe({requested:true,source,
 selector:${jsonEncode(sharedSelector)},layoutSelector:${jsonEncode(sharedSelector)}}));
output.sharedReads=reads;
'''}
console.log(JSON.stringify(output));
''';
  final result = await Process.run('node', ['-e', program]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return (jsonDecode(result.stdout.toString()) as Map).cast<String, Object?>();
}

void main() {
  for (final recipe in _kRecipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme actual SSR canonical probe and dispatch',
        () async {
          final actual = await _actual(
            recipe.component,
            recipe.variant,
            theme: theme,
          );
          final result = await _resolve(
            actual.tree,
            _source(recipe.component, recipe.variant),
            sharedSelector: actual.selector,
          );
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          for (final ref in ['unit', 'padding', 'frame']) {
            expect(result[ref], actual.field);
          }
          expect(result['registryIsLayoutRoot'], true);
          expect(result['hasValue'], false);
          final shared = result['shared']! as Map;
          expect(shared['status'], 'source-complete');
          expect(
            shared['source'],
            _source(recipe.component, recipe.variant).toJson(),
          );
          expect(shared['registryIsLayoutRoot'], true);
          expect(shared['canonicalComparisonEligible'], false);
          expect(result['sharedReads'], [actual.field]);
        },
      );
    }
    for (final mutation in [
      'source.schemaVersion=99;',
      'source.quantityId="unknown";',
      'source.nativeAdapterId="unknown";',
      'source.webAdapterId="unknown";',
      'capture._list.push(root);',
      'root.parentElement=null;',
      'root.tagName="SECTION";',
      'root._list=[];',
      'root._list.push(root._list[0]);',
    ]) {
      test(
        '${recipe.component}/${recipe.variant} rejects changed source: $mutation',
        () async {
          final actual = await _actual(recipe.component, recipe.variant);
          expect(
            (await _resolve(
              actual.tree,
              _source(recipe.component, recipe.variant),
              mutation: mutation,
            ))['error'],
            isNotNull,
          );
        },
      );
    }
    test(
      '${recipe.component}/${recipe.variant} CSS and foreign interiors never choose source',
      () async {
        final actual = await _actual(recipe.component, recipe.variant);
        final spec = _source(recipe.component, recipe.variant);
        final before = await _resolve(actual.tree, spec);
        final after = await _resolve(
          actual.tree,
          spec,
          mutation: '''
const first=resolve(root,source),field=first.fieldUnitElement;
root.attributes.style='padding:999px';
field.attributes.style='padding:23px 17px 9px 5px';
let foreign=field._list[0];
if(source.logicalUnitId==='disclosure-generated-header-content-inset')
 foreign=root._list[0]._list[1];
if(source.logicalUnitId==='collapsible-generated-section-layout-host')
 foreign=field._list[1]._list[0];
foreign.attributes.style='padding:777px';
foreign._list.push(node({tagName:'SUMMARY',attributes:{class:'flex w-full'},
 path:[99],children:[]},foreign));
''',
        );
        expect(after['error'], isNull);
        expect(after['unit'], before['unit']);
        expect(after['hasValue'], false);
      },
    );
  }
  test(
    'Disclosure reads current details.open without changing owner',
    () async {
      final actual = await _actual('disclosure', 'default');
      final spec = _source('disclosure', 'default');
      final opened = await _resolve(actual.tree, spec);
      final closed = await _resolve(
        actual.tree,
        spec,
        mutation: 'delete root._list[0].attributes.open;',
      );
      expect(opened['expanded'], true);
      expect(closed['expanded'], false);
      expect(closed['unit'], opened['unit']);
    },
  );
  for (final mutation in [
    'root._list[0]._list.reverse();',
    'root._list[0]._list[0].tagName="DIV";',
    'root._list[0]._list[0].parentElement=root;',
    'root._list[0]._list[0]._list=[];',
  ]) {
    test('Disclosure rejects wrong header/body route: $mutation', () async {
      final actual = await _actual('disclosure', 'default');
      expect(
        (await _resolve(
          actual.tree,
          _source('disclosure', 'default'),
          mutation: mutation,
        ))['error'],
        isNotNull,
      );
    });
  }
}
