import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_explicit_content_inset_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _kDomRuntime = r'''
global.getComputedStyle = () => {throw Error('CSS owner selection forbidden');};
global.document = new Proxy({}, {get(){throw Error('Global search forbidden');}});
const node = (data,parent=null) => {
  const attrs={...data.attributes};
  const value={tagName:data.tagName,path:data.path,parentElement:parent,
    getAttribute:name=>attrs[name] ?? null,
    hasAttribute:name=>Object.hasOwn(attrs,name),
    attributes:attrs,
    classList:{contains:name=>(attrs.class ?? '').split(/\s+/).includes(name)}};
  value._list=data.children.map(child=>node(child,value));
  Object.defineProperty(value,'children',{get(){
    const collection={length:value._list.length};
    value._list.forEach((child,index)=>collection[index]=child);
    return collection;
  }});
  for(const key of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
    Object.defineProperty(value,key,{get(){throw Error('Numeric owner selection forbidden');}});
  return value;
};
''';

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
  final prepared = Platform.environment['EXPLICIT_CONTENT_SSR_DIR'];
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

BoxObservationSourceSpec _source(String component) => switch (component) {
  'menu-item' => BoxObservationSourceSpec.menuItemRowContentInset,
  'carousel-banner' => BoxObservationSourceSpec.carouselBannerStripContentInset,
  _ => BoxObservationSourceSpec.panelHeaderContentInset,
};
Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  String component, {
  String mutation = '',
}) async {
  final script =
      '''
const resolve=($explicitContentInsetBoxSourceResolverScript);
$_kDomRuntime
const capture=node(${jsonEncode(tree)}),root=capture.children[0];
const source=${jsonEncode(_source(component).toJson())};
const own=()=>source.logicalUnitId==='menu-item-generated-row-content-inset'?root._list.filter(n=>n.tagName!=='STYLE')[0]:root;
$mutation
const result=resolve(root,source);
console.log(JSON.stringify(result.error ? result : {
  registry:result.registryResultElement.path,unit:result.fieldUnitElement.path,
  padding:result.paddingSource.path,frame:result.frameSource.path,
  hasValue:Object.hasOwn(result,'value'),authority:result.authority,
  callerStyle:result.paddingSource.attributes.style ?? null,
  nonArrayChildren:!Array.isArray(root.children)
}));
''';
  final process = await Process.run('node', ['-e', script]);
  expect(process.exitCode, 0, reason: process.stderr.toString());
  return (jsonDecode(process.stdout.toString()) as Map).cast<String, Object?>();
}

void main() {
  const recipes = <({String component, String variant})>[
    (component: 'menu-item', variant: 'default'),
    (component: 'menu-item', variant: 'critical'),
    (component: 'menu-item', variant: 'description'),
    (component: 'carousel-banner', variant: 'default'),
    (component: 'carousel-banner', variant: 'md'),
    (component: 'panel-header', variant: 'default'),
  ];
  for (final recipe in recipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme actual SSR references',
        () async {
          final result = await _resolve(
            await _actual(recipe.component, recipe.variant, theme: theme),
            recipe.component,
          );
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          expect(
            result['unit'],
            recipe.component == 'menu-item' ? [0, 0] : [0],
          );
          expect(result['padding'], result['unit']);
          expect(result['frame'], result['unit']);
          expect(result['nonArrayChildren'], true);
          expect(result['hasValue'], false);
        },
      );
    }
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
    'own()._list.push(own()._list.find(n=>n.classList.contains("flex-col")));',
  ]) {
    test('changed capture/tuple/owner rejects: $mutation', () async {
      expect(
        (await _resolve(
          await _actual('menu-item', 'default'),
          'menu-item',
          mutation: mutation,
        ))['error'],
        isNotNull,
      );
    });
  }
  test(
    'optional leading source STYLE retains HTMLCollection semantics',
    () async {
      final tree = await _actual('menu-item', 'default');
      final result = await _resolve(
        tree,
        'menu-item',
        mutation: 'own()._list=own()._list.filter(n=>n.tagName!=="STYLE");',
      );
      expect(result['error'], isNull);
      expect(result['padding'], [0, 0]);
    },
  );
  for (final component in ['menu-item', 'carousel-banner', 'panel-header']) {
    test(
      '$component foreign padding and caller CSS never select owners',
      () async {
        const caller = 'padding:17px 9px 5px 3px';
        final tree = await _actual(component, 'default');
        final original = await _resolve(tree, component);
        final result = await _resolve(
          tree,
          component,
          mutation:
              '''
const target=own();target.attributes.style=${jsonEncode(caller)};
const payload=target._list.filter(n=>n.tagName!=='STYLE').at(-1);
payload._list.push(node({tagName:'DIV',attributes:{class:'co-menu-item-row flex flex-col items-start flex-1'},path:[99],children:[]},payload));
''',
        );
        expect(result['error'], isNull);
        expect(result['padding'], original['padding']);
        expect(result['callerStyle'], caller);
        expect(result['hasValue'], false);
      },
    );
  }
}
