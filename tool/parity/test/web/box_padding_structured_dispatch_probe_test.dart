import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _kRecipes = <(String, String, BoxObservationSourceSpec)>[
  ('basic', 'default', BoxObservationSourceSpec.basicContentInset),
  (
    'disclosure-badge',
    'default',
    BoxObservationSourceSpec.disclosureBadgeSolidContentInset,
  ),
  (
    'disclosure-badge',
    'commitment',
    BoxObservationSourceSpec.disclosureBadgeSolidContentInset,
  ),
  (
    'multiple-choice',
    'default',
    BoxObservationSourceSpec.multipleChoiceLayoutHost,
  ),
  ('page-header', 'default', BoxObservationSourceSpec.pageHeaderLayoutHost),
  ('sidebar', 'default', BoxObservationSourceSpec.sidebarOuterLayoutHost),
  ('sidebar', 'two-pane', BoxObservationSourceSpec.sidebarOuterLayoutHost),
  ('sidebar', 'collapsed', BoxObservationSourceSpec.sidebarOuterLayoutHost),
  ('tab-pane', 'default', BoxObservationSourceSpec.tabPaneBarContentInset),
  ('tab-pane', 'editor-strip', BoxObservationSourceSpec.tabPaneBarContentInset),
  ('tree', 'default', BoxObservationSourceSpec.treeOuterLayoutHost),
  ('tree', 'selected', BoxObservationSourceSpec.treeOuterLayoutHost),
  ('timeline', 'default', BoxObservationSourceSpec.timelineSequenceLayoutHost),
  (
    'category-breakdown',
    'default',
    BoxObservationSourceSpec.categoryBreakdownLayoutHost,
  ),
  (
    'category-breakdown',
    'donut',
    BoxObservationSourceSpec.categoryBreakdownLayoutHost,
  ),
  (
    'trend-chart',
    'default',
    BoxObservationSourceSpec.trendChartOuterLayoutHost,
  ),
  ('trend-chart', 'bar', BoxObservationSourceSpec.trendChartOuterLayoutHost),
  (
    'window-panel',
    'default',
    BoxObservationSourceSpec.windowPanelFrameContentInset,
  ),
];

Map<String, Object?> _tree(
  dom.Element node,
  List<int> path,
  dom.Element expectedOwner,
) => {
  'tag': node.localName!.toUpperCase(),
  'attrs': {for (final a in node.attributes.entries) a.key.toString(): a.value},
  'path': path,
  'expectedOwner': identical(node, expectedOwner),
  'children': [
    for (var i = 0; i < node.children.length; i++)
      _tree(node.children[i], [...path, i], expectedOwner),
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
  final expectedOwner = switch (recipe.$1) {
    'sidebar' || 'timeline' || 'window-panel' => root.children.single,
    'tab-pane' => root.children.firstWhere(
      (node) => node.attributes['role'] == 'tablist',
    ),
    _ => root,
  };
  final program =
      '''
const observe=($boxPaddingObservationScript);
const node=(data,parent=null)=>{
  const attrs=data.attrs;
  const classes=(attrs.class || '').split(/\\s+/).filter(Boolean);
  classes.contains=name=>classes.includes(name);
  const n={tagName:data.tag,path:data.path,expectedOwner:data.expectedOwner,isConnected:true,parentElement:parent,
    classList:classes,getAttribute:name=>attrs[name]??null,
    hasAttribute:name=>Object.hasOwn(attrs,name)};
  n.children=data.children.map(child=>node(child,n));
  n.contains=other=>n.children.some(child=>child===other || child.contains(other));
  return n;
};
const capture=node(${jsonEncode(_tree(captures.single, const [], expectedOwner))});
const root=capture.children[0];
let matches=[root],cssReads=[];
globalThis.document={querySelectorAll:()=>matches};
globalThis.getComputedStyle=owner=>{
  cssReads.push(owner.path);
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
  try {
    final file = File('${directory.path}/probe.cjs');
    await file.writeAsString(program);
    final result = await Process.run(
      Platform.environment['PARITY_NODE'] ?? 'node',
      [file.path],
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());
    return (jsonDecode(result.stdout.toString()) as Map)
        .cast<String, Object?>();
  } finally {
    await directory.delete(recursive: true);
  }
}

void main() {
  for (final recipe in _kRecipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.$1 == 'tree' ? 'missing SSR rejects' : 'full source dispatch'} ${recipe.$1}/${recipe.$2}/$theme',
        () async {
          final readback = await _observe(recipe, theme);
          final actual = readback['result']! as Map;
          if (recipe.$1 == 'tree') {
            // The whole Tree unit now needs the original normal-SSR receipt.
            // Class-only current requests cannot inherit the former authority.
            // Public default/selected/trailing positives live in the final-body
            // dispatch suite, including all six original theme entries.
            expect(actual['status'], 'incomplete');
            expect(actual.containsKey('value'), false);
            expect(readback['cssReads'], isEmpty);
            return;
          }
          expect(actual['status'], 'source-complete');
          expect(actual['source'], recipe.$3.toJson());
          expect(actual['value'], [7.25, 13, 19.5, 23]);
          expect(actual['registryIsLayoutRoot'], true);
          expect(actual['canonicalComparisonEligible'], false);
          expect(readback['cssReads'], hasLength(1));
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
        _kRecipes.first,
        'light',
        mutation: mutation,
      );
      final actual = readback['result']! as Map;
      expect(actual['status'], 'incomplete');
      expect(actual.containsKey('value'), false);
      expect(readback['cssReads'], isEmpty);
    });
  }
}
