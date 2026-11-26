import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_display_parameter_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _kRecipes =
    <({String component, String variant, BoxObservationSourceSpec source})>[
      (
        component: 'status',
        variant: 'default',
        source: BoxObservationSourceSpec.statusDotContentInset,
      ),
      (
        component: 'status',
        variant: 'success',
        source: BoxObservationSourceSpec.statusDotContentInset,
      ),
      (
        component: 'status',
        variant: 'warning',
        source: BoxObservationSourceSpec.statusDotContentInset,
      ),
      (
        component: 'status',
        variant: 'error',
        source: BoxObservationSourceSpec.statusDotContentInset,
      ),
      (
        component: 'tag',
        variant: 'default',
        source: BoxObservationSourceSpec.tagLabelContentInset,
      ),
      (
        component: 'skeleton',
        variant: 'circle',
        source: BoxObservationSourceSpec.skeletonCircularContentInset,
      ),
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
  final output = Platform.environment['DISPLAY_PARAMETER_SSR_OUTPUT'];
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
const resolve=($displayParameterBoxSourceResolverScript);
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
  // Actual SSR and refs-only Node checks; browser paint/pair gate are separate.
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
          for (final field in ['registry', 'unit', 'padding', 'frame']) {
            expect(result[field], [0]);
          }
          expect(result['hasValue'], false);
          expect(result['arrayChildren'], false);
          expect(result['childrenSome'], 'undefined');
        },
      );
    }
  }

  for (final recipe in [_kRecipes[0], _kRecipes[4], _kRecipes[5]]) {
    test(
      '${recipe.component} missing duplicate unknown and tuple changes reject',
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
        ];
        for (final mutation in mutations) {
          final result = await _resolve(
            tree,
            recipe.source,
            mutation: mutation,
          );
          expect(result['error'], isNotNull, reason: mutation);
          expect(result.containsKey('value'), false);
        }
        final extra = await _resolve(
          tree,
          recipe.source,
          mutation: const [
            "root.children.push(node({tagName:'DIV',path:[99],",
            'attributes:{},children:[]},root));',
          ].join(),
        );
        expect(extra['error'], isNotNull);
      },
    );
  }

  test('Tag public child descendants never supply root padding', () async {
    final tree = await _actual('tag', 'default');
    const source = BoxObservationSourceSpec.tagLabelContentInset;
    final before = await _resolve(tree, source);
    final after = await _resolve(
      tree,
      source,
      mutation: const [
        "root.children[0].children.push(node({tagName:'DIV',path:[99],",
        "attributes:{style:'padding:64px'},children:[]},",
        'root.children[0]));',
      ].join(),
    );
    expect(after, before);
  });

  test('Skeleton announcer cannot be promoted and text lines reject', () async {
    final tree = await _actual('skeleton', 'circle');
    const source = BoxObservationSourceSpec.skeletonCircularContentInset;
    final before = await _resolve(tree, source);
    expect(before['unit'], [0]);
    expect(
      (await _resolve(await _actual('skeleton', 'text'), source))['error'],
      isNotNull,
    );
    expect(
      (await _resolve(
        tree,
        source,
        mutation: "root.children[0].tagName='DIV';",
      ))['error'],
      isNotNull,
    );
    expect(
      (await _resolve(
        tree,
        source,
        mutation: 'root.children.push(root.children[0]);',
      ))['error'],
      isNotNull,
    );
    final withoutAnnouncer = await _resolve(
      tree,
      source,
      mutation: 'root.children=[];',
    );
    expect(withoutAnnouncer['error'], isNull);
    expect(withoutAnnouncer['unit'], [0]);
  });

  test('Status STYLE and label children cannot be silently selected', () async {
    final tree = await _actual('status', 'default');
    for (final tag in ['STYLE', 'SPAN']) {
      final result = await _resolve(
        tree,
        BoxObservationSourceSpec.statusDotContentInset,
        mutation: [
          "root.children.push(node({tagName:'$tag',path:[99],",
          'attributes:{},children:[]},root));',
        ].join(),
      );
      expect(result['error'], 'STATUS_DOT_SOURCE_CHANGED');
    }
  });
}
