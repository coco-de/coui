import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/web/box_padding_chat_bubble_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const BoxObservationSourceSpec _kSource =
    BoxObservationSourceSpec.docsChatSingleBubble;
const _kVariants = [
  'accent',
  'error',
  'info',
  'neutral',
  'primary',
  'secondary',
  'success',
  'warning',
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
  String variant, {
  String theme = 'light',
}) async {
  final entry = MatrixEntry.fromJson({
    'component': 'chat',
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': <Object?>[],
  });
  final body = await renderCaptureBodyHtml(entry);
  final output = Platform.environment['CHAT_BUBBLE_SSR_OUTPUT'];
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
  Map<String, Object?> tree, {
  String mutation = '',
}) async {
  final result = await Process.run('node', [
    '-e',
    '''
const resolve=($chatBubbleBoxSourceResolverScript);
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
const source=${jsonEncode(_kSource.toJson())};
$mutation
const r=resolve(root,source);
console.log(JSON.stringify(r.error?r:{registry:r.registryResultElement.path,
  unit:r.fieldUnitElement.path,padding:r.paddingSource.path,frame:r.frameSource.path,
  hasValue:Object.hasOwn(r,'value'),authority:r.authority}));
''',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
}

void main() {
  for (final variant in _kVariants) {
    for (final theme in ParityTheme.values) {
      test('official $variant/${theme.name} actual SSR body refs', () async {
        final result = await _resolve(
          await _actual(variant, theme: theme.name),
        );
        expect(result['error'], isNull);
        expect(result['registry'], [0]);
        for (final field in ['unit', 'padding', 'frame']) {
          expect(result[field], [0, 0, 0]);
        }
        expect(result['hasValue'], false);
      });
    }
  }
  for (final variant in ['default', 'plain', 'tail-corner', 'tail-top']) {
    test('multiple Chat recipe $variant cannot donate one body', () async {
      expect((await _resolve(await _actual(variant)))['error'], isNotNull);
    });
  }
  test(
    'missing duplicate and changed source branches fail without values',
    () async {
      final tree = await _actual('primary');
      for (final mutation in [
        'root.children=[];',
        'root.children.push(root.children[0]);',
        'root.children[0].children=[];',
        'root.children[0].children.push(root.children[0].children[0]);',
        "root.tagName='SECTION';",
        "root.children[0].children[0].tagName='SECTION';",
        [
          'root.children[0].children[0].',
          'children.push(root.children[0].children[0].children[0]);',
        ].join(),
      ]) {
        final result = await _resolve(tree, mutation: mutation);
        expect(result['error'], isNotNull);
        expect(result.containsKey('value'), false);
      }
    },
  );
  test('foreign nested box cannot become the body padding owner', () async {
    final tree = await _actual('primary');
    final before = await _resolve(tree);
    final after = await _resolve(
      tree,
      mutation: '''
const text=root.children[0].children[0].children[0];
text.children.push(node({tagName:'DIV',path:[99],attributes:{class:'inline-block relative',style:'padding:64px'},children:[]},text));
''',
    );
    expect(after, before);
  });
  test(
    'source version quantity and both adapters are independently closed',
    () async {
      final tree = await _actual('primary');
      for (final mutation in [
        'source.schemaVersion=99;',
        "source.quantityId='unknown';",
        "source.logicalUnitId='unknown';",
        "source.nativeAdapterId='unknown';",
        "source.webAdapterId='unknown';",
        'capture.children.push(root);',
      ]) {
        final result = await _resolve(tree, mutation: mutation);
        expect(result['error'], isNotNull);
        expect(result.containsKey('value'), false);
      }
    },
  );
}
