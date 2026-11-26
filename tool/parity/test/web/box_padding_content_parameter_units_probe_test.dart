import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_content_parameter_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _kRecipes =
    <({String component, String variant, BoxObservationSourceSpec source})>[
      (
        component: 'kbd',
        variant: 'single',
        source: BoxObservationSourceSpec.kbdSingleKeycapContentInset,
      ),
      (
        component: 'app-bar',
        variant: 'medium',
        source: BoxObservationSourceSpec.appBarMediumToolbarContentInset,
      ),
      (
        component: 'refresh-trigger',
        variant: 'default',
        source: BoxObservationSourceSpec.docsRefreshViewportContentInset,
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
  final output = Platform.environment['CONTENT_PARAMETER_SSR_OUTPUT'];
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
const resolve=($contentParameterBoxSourceResolverScript);
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
  // Four component subunits plus two documentation viewport inputs. These
  // actual SSR/reference checks are not browser paint or legacy root repairs.
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
          final expected = recipe.component == 'refresh-trigger' ? [0] : [0, 0];
          for (final field in ['unit', 'padding', 'frame']) {
            expect(result[field], expected);
          }
          expect(result['hasValue'], false);
          expect(result['arrayChildren'], false);
          expect(result['childrenSome'], 'undefined');
        },
      );
    }
  }

  test(
    'browser HTMLCollection has no array methods on the actual toolbar',
    () async {
      final result = await _resolve(
        await _actual('app-bar', 'medium'),
        _kRecipes[1].source,
      );
      expect(result['error'], isNull);
      expect(result['arrayChildren'], false);
      expect(result['childrenSome'], 'undefined');
      expect(result['unit'], [0, 0]);
    },
  );

  test(
    'multi-cap and non-medium branches cannot supply a chosen subunit',
    () async {
      expect(
        (await _resolve(
          await _actual('kbd', 'combo'),
          _kRecipes[0].source,
        ))['error'],
        isNotNull,
      );
      expect(
        (await _resolve(
          await _actual('app-bar', 'default'),
          _kRecipes[1].source,
        ))['error'],
        isNotNull,
      );
    },
  );

  for (final recipe in _kRecipes) {
    test(
      '${recipe.component} missing duplicate and tuple changes fail closed',
      () async {
        final tree = await _actual(recipe.component, recipe.variant);
        const mutations = [
          'root.parentElement=null;',
          'capture.children.push(root);',
          'root.children=[];',
          'root.children.push(root.children[0]);',
          "root.tagName='SECTION';",
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
      },
    );
  }

  test('foreign toolbar action cannot become toolbar padding owner', () async {
    final tree = await _actual('app-bar', 'medium');
    final before = await _resolve(tree, _kRecipes[1].source);
    final after = await _resolve(
      tree,
      _kRecipes[1].source,
      mutation: '''
const foreign=root.children[0].children[0];
foreign.children.push(node({tagName:'DIV',path:[99],attributes:{style:'padding:64px'},children:[]},foreign));
''',
    );
    expect(after, before);
  });

  test(
    'entire supplied Refresh subtree stays outside the viewport owner',
    () async {
      final tree = await _actual('refresh-trigger', 'default');
      final before = await _resolve(tree, _kRecipes[2].source);
      final after = await _resolve(
        tree,
        _kRecipes[2].source,
        mutation: '''
const foreign=root.children[0];
foreign.children=[];
foreign.children.push(node({tagName:'DIV',path:[99],attributes:{style:'padding-top:64px'},children:[]},foreign));
''',
      );
      expect(after, before);
      expect(after['authority'], contains('no legacy component-root repair'));
    },
  );
}
