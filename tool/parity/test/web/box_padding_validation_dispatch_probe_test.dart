import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _recipes = <(String, String, BoxObservationSourceSpec)>[
  ('formatter', 'default', BoxObservationSourceSpec.textFieldContentInset),
  ('validated', 'default', BoxObservationSourceSpec.validatedLayoutHost),
  (
    'validator-hint',
    'default',
    BoxObservationSourceSpec.validatorHintMessageLayoutHost,
  ),
  (
    'scroll-area',
    'default',
    BoxObservationSourceSpec.scrollAreaViewportLayoutHost,
  ),
  (
    'fade-scroll',
    'default',
    BoxObservationSourceSpec.fadeScrollViewportLayoutHost,
  ),
  (
    'fade-scroll',
    'horizontal',
    BoxObservationSourceSpec.fadeScrollViewportLayoutHost,
  ),
  (
    'fade-scroll',
    'with-scrollbar',
    BoxObservationSourceSpec.fadeScrollViewportLayoutHost,
  ),
  (
    'overflow-marquee',
    'default',
    BoxObservationSourceSpec.overflowMarqueeViewportLayoutHost,
  ),
  ('hover', 'shadow', BoxObservationSourceSpec.hoverEffectHost),
  ('kbd', 'default', BoxObservationSourceSpec.kbdKeySequenceLayoutHost),
  ('kbd', 'combo', BoxObservationSourceSpec.kbdKeySequenceLayoutHost),
  ('kbd', 'four', BoxObservationSourceSpec.kbdKeySequenceLayoutHost),
];

Map<String, Object?> _tree(
  dom.Element node,
  List<int> path,
  dom.Element expectedOwner,
  dom.Element? expectedInput,
) => {
  'tag': node.localName!.toUpperCase(),
  'textContent': node.text,
  'attrs': {for (final a in node.attributes.entries) a.key.toString(): a.value},
  'path': path,
  'expectedOwner': identical(node, expectedOwner),
  'expectedInput': identical(node, expectedInput),
  'children': [
    for (var i = 0; i < node.children.length; i++)
      _tree(node.children[i], [...path, i], expectedOwner, expectedInput),
  ],
};

Future<Map<String, Object?>> _observe(
  (String, String, BoxObservationSourceSpec) recipe,
  String theme, {
  String mutation = '',
}) async {
  final entry = MatrixEntry.fromJson({
    'component': recipe.$1,
    'variant': recipe.$2,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't1',
    'probes': <Object?>[],
  });
  final body = await renderCaptureBodyHtml(entry);
  final captures = html
      .parseFragment(body)
      .querySelectorAll('[data-parity-key]');
  expect(captures, hasLength(1));
  final root = captures.single.children.single;
  // Independent oracle from the public source unit: outer layout, generated
  // navigation/track, or the panel inside its documented width wrapper.
  final expectedInput = recipe.$1 == 'formatter'
      ? root.querySelectorAll('input').single
      : null;
  final expectedOwner = switch (recipe.$1) {
    'formatter' => expectedInput!.parent!,
    'validated' || 'scroll-area' || 'overflow-marquee' => root.children.single,
    'fade-scroll' =>
      root.querySelectorAll('.overflow-y-auto,.overflow-x-auto').single,
    _ => root,
  };
  final nodeProgram =
      '''
const observe=($boxPaddingObservationScript);
const node=(data,parent=null)=>{
  const attrs=data.attrs;
  const classes=(attrs.class || '').split(/\\s+/).filter(Boolean);
  classes.contains=name=>classes.includes(name);
  const n={tagName:data.tag,textContent:data.textContent,path:data.path,expectedOwner:data.expectedOwner,expectedInput:data.expectedInput,isConnected:true,parentElement:parent,
    classList:classes,getAttribute:name=>attrs[name]??null,
    hasAttribute:name=>Object.hasOwn(attrs,name)};
  n.children=data.children.map(child=>node(child,n));
  n.contains=other=>n.children.some(child=>child===other || child.contains(other));
  return n;
};
const capture=node(${jsonEncode(_tree(captures.single, const [], expectedOwner, expectedInput))});
const root=capture.children[0];
let matches=[root],cssReads=[];
globalThis.document={querySelectorAll:()=>matches};
globalThis.getComputedStyle=owner=>{
  cssReads.push(owner.path);
  if (owner.expectedInput) return {display:'block',paddingTop:'0px',paddingRight:'13px',paddingBottom:'0px',paddingLeft:'23px'};
  if (owner.expectedOwner && source.logicalUnitId==='text-field-generated-content-inset') return {display:'block',paddingTop:'7.25px',paddingRight:'0px',paddingBottom:'19.5px',paddingLeft:'0px'};
  return owner.expectedOwner
    ? {display:'block',paddingTop:'7.25px',paddingRight:'13px',paddingBottom:'19.5px',paddingLeft:'23px'}
    : {display:'block',paddingTop:'901px',paddingRight:'902px',paddingBottom:'903px',paddingLeft:'904px'};
};
const source=${jsonEncode(recipe.$3.toJson())};
$mutation
const result=JSON.parse(observe({requested:true,selector:'#root',layoutSelector:'#root',source}));
console.log(JSON.stringify({result,cssReads}));
''';
  final directory = await Directory.systemTemp.createTemp('coui-parity-node-');
  late final ProcessResult result;
  try {
    final file = File('${directory.path}/probe.cjs');
    await file.writeAsString(nodeProgram);
    result = await Process.run('node', [file.path]);
  } finally {
    await directory.delete(recursive: true);
  }
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return (jsonDecode(result.stdout.toString()) as Map).cast<String, Object?>();
}

void main() {
  for (final recipe in _recipes) {
    for (final theme in ['light', 'dark']) {
      test(
        'validation source dispatch ${recipe.$1}/${recipe.$2}/$theme',
        () async {
          final readback = await _observe(recipe, theme);
          final actual = readback['result']! as Map;
          expect(actual['status'], 'source-complete');
          expect(actual['source'], recipe.$3.toJson());
          expect(actual['value'], [7.25, 13, 19.5, 23]);
          expect(actual['registryIsLayoutRoot'], true);
          expect(actual['canonicalComparisonEligible'], false);
          expect(
            readback['cssReads'],
            hasLength(recipe.$1 == 'formatter' ? 2 : 1),
          );
          if (recipe.$1 == 'formatter') {
            expect(actual.containsKey('rawCss'), false);
            expect(actual['rawCssParts'], hasLength(2));
            final refs = actual['paddingParameterSources']! as List;
            expect(refs, hasLength(2));
            final cssPaths = readback['cssReads']! as List;
            expect(
              refs.map((ref) => (ref as Map)['path']).toList(),
              cssPaths.map((path) => (path as List).skip(1).toList()).toList(),
            );
          }
        },
      );
    }
  }
  for (final mutation in [
    'matches=[];',
    'matches=[root,root];',
    'capture.hasAttribute=()=>false;',
    "source.webAdapterId='another-adapter';",
    "root.tagName='SECTION';",
  ]) {
    test('invalid dispatch reads no CSS: $mutation', () async {
      final readback = await _observe(
        _recipes.first,
        'light',
        mutation: mutation,
      );
      final actual = readback['result']! as Map;
      expect(actual['status'], 'incomplete');
      expect(actual.containsKey('value'), false);
      expect(readback['cssReads'], isEmpty);
    });
  }
  test('a broken complementary allocation stays incomplete', () async {
    final readback = await _observe(
      _recipes.first,
      'light',
      mutation: const [
        'const original=getComputedStyle;',
        'globalThis.getComputedStyle=node=>{const css=original(node);',
        "return node.expectedInput?{...css,paddingTop:'1px'}:css;};",
      ].join(),
    );
    final actual = readback['result']! as Map;
    expect(actual['status'], 'incomplete');
    expect(actual['error'], 'TEXT_FIELD_COMPLEMENTARY_ALLOCATION_CHANGED');
    expect(actual.containsKey('value'), false);
    expect(readback['cssReads'], hasLength(2));
  });
}
