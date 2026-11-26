import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_responsive_layout_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _kUnexpectedContainerChild =
    'registry._list.push(node({tagName:"DIV",attributes:{},'
    'path:[98],children:[]},registry));';

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
  final prepared = Platform.environment['RESPONSIVE_LAYOUT_SSR_DIR'];
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
  'responsive-row-column' => BoxObservationSourceSpec.responsiveFlexLayoutHost,
  'responsive-container' =>
    BoxObservationSourceSpec.responsiveContainerContentInset,
  _ => BoxObservationSourceSpec.responsiveGridLayoutHost,
};
Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  String component, {
  String mutation = '',
}) async {
  final script =
      '''
const resolve=($responsiveLayoutBoxSourceResolverScript);
$_kDomRuntime
const capture=node(${jsonEncode(tree)}), registry=capture.children[0];
const container=${component == 'responsive-container'};
const root=container?registry.children[0]:registry;
const source=${jsonEncode(_source(component).toJson())};
$mutation
const result=resolve(root,source);
console.log(JSON.stringify(result.error?result:{registry:result.registryResultElement.path,unit:result.fieldUnitElement.path,padding:result.paddingSource.path,frame:result.frameSource.path,registryIsLayoutRoot:result.registryIsLayoutRoot,hasValue:Object.hasOwn(result,'value'),callerStyle:result.paddingSource.attributes.style??null,nonArrayChildren:!Array.isArray(root.children)}));
''';
  final process = await Process.run('node', ['-e', script]);
  expect(process.exitCode, 0, reason: process.stderr.toString());
  return (jsonDecode(process.stdout.toString()) as Map).cast<String, Object?>();
}

void main() {
  test(
    'Container inset source is canonical root rather than gallery stage',
    () async {
      final result = await _resolve(
        await _actual('responsive-container', 'default'),
        'responsive-container',
      );
      expect(result['error'], isNull);
      expect(result['registry'], [0]);
      expect(result['unit'], [0, 0]);
      expect(result['padding'], result['unit']);
      expect(result['frame'], result['unit']);
      expect(result['registryIsLayoutRoot'], false);
      expect(result['callerStyle'], contains('padding:'));
    },
  );
  const recipes = <({String component, String variant})>[
    (component: 'responsive-row-column', variant: 'default'),
    (component: 'responsive-row-column', variant: 'desktop'),
    (component: 'responsive-container', variant: 'default'),
    (component: 'responsive-grid', variant: 'default'),
    (component: 'responsive-grid', variant: 'span'),
  ];
  for (final recipe in recipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme actual SSR reference route',
        () async {
          final result = await _resolve(
            await _actual(recipe.component, recipe.variant, theme: theme),
            recipe.component,
          );
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          expect(
            result['unit'],
            recipe.component == 'responsive-grid' && recipe.variant == 'default'
                ? [0, 1]
                : recipe.component == 'responsive-container'
                ? [0, 0]
                : [0],
          );
          expect(result['padding'], result['unit']);
          expect(result['frame'], result['unit']);
          expect(
            result['registryIsLayoutRoot'],
            recipe.component != 'responsive-container',
          );
          expect(result['hasValue'], false);
          expect(result['nonArrayChildren'], true);
        },
      );
    }
  }
  for (final component in [
    'responsive-row-column',
    'responsive-container',
    'responsive-grid',
  ]) {
    for (final mutation in [
      'source.schemaVersion=99;',
      'source.quantityId="unknown";',
      'source.nativeAdapterId="unknown";',
      'source.webAdapterId="unknown";',
      'capture._list.push(registry);',
      'root.parentElement=null;',
      'root.tagName="SECTION";',
      'registry._list=[];',
      'registry._list.push(registry._list[0]);',
    ]) {
      test('$component changed construction rejects: $mutation', () async {
        expect(
          (await _resolve(
            await _actual(component, 'default'),
            component,
            mutation: mutation,
          ))['error'],
          isNotNull,
        );
      });
    }
    test(
      '$component caller CSS/foreign contents never select source owner',
      () async {
        const caller = 'padding:17px 9px 5px 3px';
        final tree = await _actual(component, 'default');
        final original = await _resolve(tree, component);
        final result = await _resolve(
          tree,
          component,
          mutation:
              '''
const target=container?root:(registry._list[0]?.tagName==='STYLE'?registry._list[1]:registry);
target.attributes.style=${jsonEncode(caller)};
const foreign=target._list.filter(n=>n.tagName!=='STYLE').at(-1);
foreign._list.push(node({tagName:'DIV',attributes:{class:'flex w-full'},path:[99],children:[]},foreign));
''',
        );
        expect(result['error'], isNull);
        expect(result['padding'], original['padding']);
        expect(result['callerStyle'], caller);
        expect(result['hasValue'], false);
      },
    );
  }
  test('Grid leading STYLE order and generated inner grid are exact', () async {
    final tree = await _actual('responsive-grid', 'default');
    expect(
      (await _resolve(
        tree,
        'responsive-grid',
        mutation: 'registry._list.reverse();',
      ))['error'],
      isNotNull,
    );
    expect(
      (await _resolve(
        tree,
        'responsive-grid',
        mutation: 'registry._list[1]._list=[];',
      ))['error'],
      isNotNull,
    );
    expect(
      (await _resolve(
        tree,
        'responsive-grid',
        mutation: 'registry._list.push(registry._list[1]);',
      ))['error'],
      isNotNull,
    );
  });
  test(
    'Container rejects extra or moved child while retaining canonical root',
    () async {
      final tree = await _actual('responsive-container', 'default');
      for (final mutation in [
        _kUnexpectedContainerChild,
        'root.parentElement=capture;',
      ]) {
        expect(
          (await _resolve(
            tree,
            'responsive-container',
            mutation: mutation,
          ))['error'],
          isNotNull,
        );
      }
    },
  );
  test(
    'Container stage and foreign padding do not replace the source unit',
    () async {
      final tree = await _actual('responsive-container', 'default');
      final original = await _resolve(tree, 'responsive-container');
      final result = await _resolve(
        tree,
        'responsive-container',
        mutation: '''
registry.attributes.style='padding:999px';
root._list[0].attributes.style='padding:77px';
''',
      );
      expect(result['error'], isNull);
      expect(result['unit'], [0, 0]);
      expect(result['callerStyle'], original['callerStyle']);
      expect(result['hasValue'], false);
    },
  );
}
