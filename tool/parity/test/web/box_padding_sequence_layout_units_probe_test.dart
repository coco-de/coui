import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_sequence_layout_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const BoxObservationSourceSpec _kStack =
    BoxObservationSourceSpec.stackLayoutOverlapHost;
const BoxObservationSourceSpec _kIndexed =
    BoxObservationSourceSpec.indexedSwitcherLayoutHost;
const BoxObservationSourceSpec _kSwap =
    BoxObservationSourceSpec.swapOverlapLayoutHost;
const BoxObservationSourceSpec _kDivider =
    BoxObservationSourceSpec.dividerLabelledSequenceHost;
const _kRecipes =
    <({String component, String variant, BoxObservationSourceSpec source})>[
      (component: 'stack-layout', variant: 'default', source: _kStack),
      (component: 'indexed-switcher', variant: 'default', source: _kIndexed),
      (component: 'swap', variant: 'default', source: _kSwap),
      (component: 'swap', variant: 'rotate', source: _kSwap),
      (component: 'divider', variant: 'with-child', source: _kDivider),
    ];
Map<String, Object?> _tree(dom.Element e, List<int> path) => {
  'tagName': e.localName!.toUpperCase(),
  'attributes': {
    for (final a in e.attributes.entries) a.key.toString(): a.value,
  },
  'path': path,
  'children': [
    for (var i = 0; i < e.children.length; i++)
      _tree(e.children[i], [...path, i]),
  ],
};
List<dom.Element> _owned(dom.Element e) =>
    e.children.where((c) => c.localName != 'style').toList();
Future<({Map<String, Object?> tree, List<int> field})> _actual(
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
  final output = Platform.environment['SEQUENCE_LAYOUT_SSR_OUTPUT'];
  if (output != null) {
    final f = File('$output/${entry.key}.body.html');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(body);
  }
  final captures = html
      .parseFragment(body)
      .querySelectorAll('[data-parity-key]');
  expect(captures, hasLength(1));
  final cap = captures.single;
  expect(cap.children, hasLength(1));
  final root = cap.children.single;
  final field = switch (component) {
    'stack-layout' => _owned(root).single,
    'indexed-switcher' => _owned(_owned(root)[0]).single,
    'swap' => _owned(_owned(root).single).single,
    _ => root,
  };
  final route = <int>[];
  var node = field;
  while (!identical(node, cap)) {
    final parent = node.parent!;
    route.insert(0, parent.children.indexOf(node));
    node = parent;
  }
  return (tree: _tree(cap, const []), field: route);
}

Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  BoxObservationSourceSpec spec, {
  String mutation = '',
}) async {
  final result = await Process.run('node', [
    '-e',
    '''
const resolve=($sequenceLayoutBoxSourceResolverScript);
global.getComputedStyle=()=>{throw Error('CSS reads forbidden');};
global.document=new Proxy({},{get(){throw Error('Global searches forbidden');}});
const node=(data,parent=null)=>{const attrs=data.attributes;
 const e={tagName:data.tagName,path:data.path,parentElement:parent,
 getAttribute:name=>attrs[name]??null,hasAttribute:name=>Object.hasOwn(attrs,name),
 classList:{contains:name=>(attrs.class??'').split(/\\s+/).includes(name)}};
 for(const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
  Object.defineProperty(e,name,{get(){throw Error('Numeric reads forbidden');}});
 e.children=data.children.map(c=>node(c,e));return e;};
const capture=node(${jsonEncode(tree)}),root=capture.children[0],source=${jsonEncode(spec.toJson())};
const owned=e=>Array.from(e.children).filter(c=>c.tagName!=='STYLE');
$mutation
const browserChildren=e=>{const children=Array.from(e.children);children.forEach(browserChildren);
 const collection={length:children.length,item:i=>children[i]??null};children.forEach((c,i)=>collection[i]=c);e.children=collection;};
browserChildren(capture);
const r=resolve(root,source);console.log(JSON.stringify(r.error?r:{registry:r.registryResultElement.path,
 unit:r.fieldUnitElement.path,padding:r.paddingSource.path,frame:r.frameSource.path,
 hasValue:Object.hasOwn(r,'value'),arrayChildren:Array.isArray(root.children),some:typeof root.children.some}));
''',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
}

void main() {
  for (final recipe in _kRecipes) {
    for (final theme in ParityTheme.values) {
      test(
        '${recipe.component}/${recipe.variant}/${theme.name} actual SSR refs',
        () async {
          final actual = await _actual(
            recipe.component,
            recipe.variant,
            theme: theme.name,
          );
          final r = await _resolve(actual.tree, recipe.source);
          expect(r['error'], isNull);
          expect(r['registry'], [0]);
          for (final key in ['unit', 'padding', 'frame']) {
            expect(r[key], actual.field);
          }
          expect(r['hasValue'], false);
          expect(r['arrayChildren'], false);
          expect(r['some'], 'undefined');
        },
      );
    }
  }
  for (final recipe in [
    _kRecipes[0],
    _kRecipes[1],
    _kRecipes[2],
    _kRecipes[4],
  ]) {
    test(
      '${recipe.component} missing duplicate unknown tuple are rejected',
      () async {
        final actual = await _actual(recipe.component, recipe.variant);
        for (final mutation in const [
          'root.parentElement=null;',
          'capture.children.push(root);',
          "root.tagName='SECTION';",
          'capture.hasAttribute=()=>false;',
          'source.schemaVersion=99;',
          "source.logicalUnitId='unknown';",
          "source.quantityId='unknown';",
          "source.nativeAdapterId='unknown';",
          "source.webAdapterId='unknown';",
          'root.children=[];',
        ]) {
          final r = await _resolve(
            actual.tree,
            recipe.source,
            mutation: mutation,
          );
          expect(r['error'], isNotNull, reason: mutation);
          expect(r.containsKey('value'), false);
        }
      },
    );
    test(
      '${recipe.component} opaque padding and optional STYLE retain refs',
      () async {
        final actual = await _actual(recipe.component, recipe.variant);
        final before = await _resolve(actual.tree, recipe.source);
        final after = await _resolve(
          actual.tree,
          recipe.source,
          mutation: [
            'const original=root.getAttribute;',
            "root.getAttribute=n=>n==='style'?'padding:37px':original(n);",
            if (recipe.component == 'divider')
              'let p=owned(root)[1];while(owned(p).length)p=owned(p)[0];'
            else
              'let p=root;while(owned(p).length)p=owned(p)[0];',
            """
p.children.push(node({tagName:'DIV',path:[99],
  attributes:{class:'relative grid',style:'padding:61px'},children:[]},p));
""",
            """
root.children.unshift(node({tagName:'STYLE',path:[98],
  attributes:{},children:[]},root));
""",
          ].join(),
        );
        expect(after, before);
      },
    );
  }
  test('Swap noninteractive and flip overlap cannot be promoted', () async {
    final actual = await _actual('swap', 'rotate');
    for (final mutation in const [
      'root.getAttribute=()=>null;',
      "owned(owned(root)[0])[0].getAttribute=()=> 'display:contents';",
      'owned(owned(root)[0])[0].children.pop();',
    ]) {
      expect(
        (await _resolve(actual.tree, _kSwap, mutation: mutation))['error'],
        isNotNull,
      );
    }
  });
  test(
    'Divider label/line descendants cannot substitute the sequence',
    () async {
      final actual = await _actual('divider', 'with-child');
      for (final mutation in const [
        'root.children.push(owned(root)[0]);',
        "root.classList.contains=n=>n==='grid'||n==='h-full';",
        "root.getAttribute=n=>n==='role'?'separator':null;",
      ]) {
        expect(
          (await _resolve(actual.tree, _kDivider, mutation: mutation))['error'],
          isNotNull,
        );
      }
    },
  );
}
