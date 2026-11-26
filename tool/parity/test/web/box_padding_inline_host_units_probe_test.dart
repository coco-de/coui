import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_inline_host_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

BoxObservationSourceSpec _source(String component) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: '$component-generated-inline-host',
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$component-generated-inline-host-v1',
  webAdapterId: '$component-generated-inline-host-v1',
);

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
  String variant,
  ParityTheme theme,
) async {
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme.name,
    'surfaceStyle': 'defaultStyle',
    'tier': 't1',
    'probes': <Object?>[],
  });
  final document = html.parseFragment(await renderCaptureBodyHtml(entry));
  final captures = document.querySelectorAll('[data-parity-key]');
  expect(captures, hasLength(1));
  return _tree(captures.single, const []);
}

Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  BoxObservationSourceSpec source, {
  String mutation = '',
}) async {
  final result = await Process.run('node', [
    '-e',
    '''
const resolve = ($inlineHostBoxSourceResolverScript);
global.getComputedStyle = () => {throw Error('CSS read forbidden');};
global.document = new Proxy({}, {get(){throw Error('Global query forbidden');}});
const node = (data,parent=null) => {
  const attributes=data.attributes;
  const value={tagName:data.tagName,path:data.path,parentElement:parent,
    getAttribute:name=>attributes[name] ?? null,
    hasAttribute:name=>Object.hasOwn(attributes,name)};
  for (const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
    Object.defineProperty(value,name,{get(){throw Error('Numeric read forbidden');}});
  value.children=data.children.map(child=>node(child,value));
  return value;
};
const capture=node(${jsonEncode(tree)});
const root=capture.children[0];
const source=${jsonEncode(source.toJson())};
$mutation
const value=resolve(root,source);
console.log(JSON.stringify(value.error ? value : {
  registry:value.registryResultElement.path,unit:value.fieldUnitElement.path,
  padding:value.paddingSource.path,frame:value.frameSource.path,
  hasValue:Object.hasOwn(value,'value'),authority:value.authority}));
''',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
}

void main() {
  const recipes = <String, List<String>>{
    'label': ['default', 'required', 'with-icon', 'disabled'],
    'link': ['default', 'muted', 'underline', 'external', 'icons'],
  };
  for (final entry in recipes.entries) {
    for (final variant in entry.value) {
      for (final theme in ParityTheme.values) {
        test('${entry.key}/$variant/${theme.name} actual SSR host', () async {
          final result = await _resolve(
            await _actual(entry.key, variant, theme),
            _source(entry.key),
          );
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          expect(result['unit'], [0]);
          expect(result['padding'], [0]);
          expect(result['frame'], [0]);
          expect(result['hasValue'], false);
        });
      }
    }
  }

  test(
    'Label rejects unknown own cell/wrapper, missing and duplicate root',
    () async {
      final tree = await _actual('label', 'default', ParityTheme.light);
      for (final mutation in [
        "root.tagName='DIV';",
        "root.children.push({tagName:'ASIDE'});",
        'capture.children=[];',
        'capture.children.push(root);',
      ]) {
        final result = await _resolve(
          tree,
          _source('label'),
          mutation: mutation,
        );
        expect(result['error'], isNotNull, reason: mutation);
      }
    },
  );

  test(
    'Link rejects command/wrong host, duplicate style and capture mutation',
    () async {
      final tree = await _actual('link', 'default', ParityTheme.light);
      for (final mutation in [
        "root.tagName='DIV';",
        "root.hasAttribute=name=>name!=='href';",
        "root.hasAttribute=name=>name==='href'||name==='data-href';",
        "root.children=[{tagName:'STYLE'},{tagName:'STYLE'}];",
        "root.children=[{tagName:'SPAN'},{tagName:'STYLE'}];",
        'capture.children.push(root);',
        'root.parentElement=null;',
      ]) {
        final result = await _resolve(
          tree,
          _source('link'),
          mutation: mutation,
        );
        expect(result['error'], isNotNull, reason: mutation);
      }
    },
  );

  test(
    'caller CSS and arbitrary foreign Link payload do not select an owner',
    () async {
      final tree = await _actual('link', 'icons', ParityTheme.light);
      final result = await _resolve(
        tree,
        _source('link'),
        mutation: '''
root.children.push({tagName:'DIV',path:[0,99],children:[],
  getAttribute:()=> 'padding:77px',hasAttribute:()=>true});
Object.defineProperty(root,'style',{get(){throw Error('Style read forbidden');}});
''',
      );
      expect(result['error'], isNull);
      expect(result['unit'], [0]);
      expect(result['hasValue'], false);
    },
  );

  test('version/quantity/adapter/unknown-unit mutations fail closed', () async {
    final tree = await _actual('label', 'default', ParityTheme.light);
    for (final mutation in [
      'source.schemaVersion=2;',
      "source.quantityId='other';",
      "source.nativeAdapterId='link-generated-inline-host-v1';",
      "source.webAdapterId='unknown';",
      "source.logicalUnitId='unknown';",
    ]) {
      final result = await _resolve(tree, _source('label'), mutation: mutation);
      expect(result['error'], isNotNull, reason: mutation);
    }
  });
}
