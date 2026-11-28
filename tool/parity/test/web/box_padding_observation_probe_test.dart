import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/web/box_padding_observation_probe.dart';

/// Executes the actual pure sampler against structural records, not a browser.
Future<Map<String, Object?>> _observe(
  String setup, {
  BoxObservationSourceSpec source = BoxObservationSourceSpec.docsSizePreview,
}) async {
  final program =
      '''
const observe = ($boxPaddingObservationScript);
const node = (tagName, classes, children = []) => {
  const names = [...classes]; names.contains = name => names.includes(name);
  const value = {tagName, classList:names, children, isConnected:true,
    parentElement:null, hasAttribute:()=>false};
  for(const child of children) child.parentElement = value;
  value.contains = other => value.children.some(child=>child===other || child.contains(other));
  return value;
};
const figure = node('FIGURE',['docs-size-item'],[node('FIGCAPTION',[])]);
const preview = node('DIV',['docs-stage','docs-stage--hug','docs-stage--row'],[figure]);
const table = node('DIV',['docs-table'],[node('TABLE',[],[node('THEAD',[]),node('TBODY',[])])]);
const root = node('DIV',['docs-size-spec'],[preview,table]);
let matches = [root]; let cssReads = 0;
global.document = {querySelectorAll:()=>matches};
global.getComputedStyle = owner => {
  cssReads++;
  const inset = owner===preview ? '16px' : '101px';
  return {display:'block', paddingTop:inset,paddingRight:inset,paddingBottom:inset,paddingLeft:inset};
};
$setup
const result = JSON.parse(observe({requested:true,selector:'#root',layoutSelector:'#root',source:${jsonEncode(source.toJson())}}));
console.log(JSON.stringify({result,cssReads}));
''';
  final directory = Directory.systemTemp.createTempSync('docs-size-old-shape-');
  late ProcessResult result;
  try {
    final file = File('${directory.path}/probe.cjs')
      ..writeAsStringSync(program);
    result = await Process.run('node', [file.path]);
  } finally {
    directory.deleteSync(recursive: true);
  }
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
}

void main() {
  test(
    [
      'SizeSpec matching classes without its normal receipt ',
      'cannot claim ownership',
    ].join(),
    () async {
      final readback = await _observe('');
      final actual = (readback['result']! as Map).cast<String, Object?>();
      expect(actual['status'], 'incomplete');
      expect(actual['error'], 'DOCS_SIZE_ACTUAL_NORMAL_SSR_REQUIRED');
      expect(actual.containsKey('value'), false);
      expect(readback['cssReads'], 0);
    },
  );
  for (final control in <(String, String, String)>[
    ('missing', 'matches=[];', 'MISSING_LAYOUT_OWNER'),
    ('duplicate', 'matches=[root,root];', 'DUPLICATE_LAYOUT_OWNER'),
    (
      'uncontained',
      'root.contains=()=>false;',
      'DOCS_SIZE_ACTUAL_NORMAL_SSR_REQUIRED',
    ),
    (
      'table source',
      'root.children.pop();',
      'DOCS_SIZE_ACTUAL_NORMAL_SSR_REQUIRED',
    ),
  ]) {
    test(
      '${control.$1} source fails without reading or returning a value',
      () async {
        final readback = await _observe(control.$2);
        final actual = readback['result']! as Map;
        expect(actual['status'], 'incomplete');
        expect(actual['error'], control.$3);
        expect(actual.containsKey('value'), isFalse);
        expect(readback['cssReads'], 0);
      },
    );
  }
  test('the old DocsStage tuple cannot adopt a SizeSpec descendant', () async {
    final readback = await _observe(
      '',
      source: BoxObservationSourceSpec.docsStage,
    );
    final actual = readback['result']! as Map;
    expect(actual['error'], 'DOCS_STAGE_SOURCE_CHANGED');
    expect(actual.containsKey('value'), isFalse);
    expect(readback['cssReads'], 0);
  });
}
