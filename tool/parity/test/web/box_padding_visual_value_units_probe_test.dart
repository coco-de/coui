import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/web_registry.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/box_padding_visual_value_units_probe.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/visual_value_ssr_source.dart';

const _kHtmlNamespace = 'http://www.w3.org/1999/xhtml';
const _kDuplicateGeneratedTreeMutation =
    'currentRaw.generatedTree.children.push('
    'currentRaw.generatedTree.children[0]);';
const _kRecipes = <({String component, String variant})>[
  (component: 'icon', variant: 'default'),
  (component: 'icon', variant: 'search'),
  (component: 'icon', variant: 'favorite'),
  (component: 'number-ticker', variant: 'default'),
  (component: 'skeleton', variant: 'text'),
  (component: 'countdown', variant: 'default'),
];
BoxObservationSourceSpec _source(String component) => switch (component) {
  'icon' => BoxObservationSourceSpec.iconVisualFrame,
  'number-ticker' => BoxObservationSourceSpec.numberTickerTextLayoutHost,
  'skeleton' => BoxObservationSourceSpec.skeletonTextLinesLayoutHost,
  'countdown' => BoxObservationSourceSpec.countdownValueLayoutHost,
  _ => throw ArgumentError(component),
};
const _kRuntime = r'''
const node=(data,parent=null)=>{
 const attrs={...data.attributes};
 const element={tagName:data.tagName,localName:data.localName,namespaceURI:data.namespaceURI,
  path:data.path,attributes:attrs,parentElement:parent,parentNode:parent,
  nodeType:1,isConnected:true,
  getAttribute:name=>attrs[name]??null,hasAttribute:name=>Object.hasOwn(attrs,name),
  classList:{contains:name=>(attrs.class??'').split(/\s+/).includes(name)}};
 element._list=data.children.map(c=>node(c,element));
 element._extraNodes=[];
 Object.defineProperty(element,'childNodes',{get(){return [
   ...data.nodes.map(n=>Object.hasOwn(n,'elementIndex')?element._list[n.elementIndex]:
     {...n,parentNode:element}),...element._extraNodes];}});
 Object.defineProperty(element,'children',{get(){const list={length:element._list.length};
  element._list.forEach((child,i)=>list[i]=child);return list;}});
 element.contains=other=>element===other || element._list.some(c=>c.contains(other));
 for(const key of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
  Object.defineProperty(element,key,{get(){throw Error('Numeric source selection forbidden');}});
 element.getBoundingClientRect=()=>{throw Error('Geometry source selection forbidden');};
 return element;
};
''';
Map<String, Object?> _tree(dom.Element element, List<int> path) => {
  'namespaceURI': element.namespaceUri,
  'localName': element.localName,
  // SVG tagName stays lowercase in the real browser. HTML is uppercase.
  'tagName': element.namespaceUri == _kHtmlNamespace
      ? element.localName!.toUpperCase()
      : element.localName,
  'attributes': {
    for (final a in element.attributes.entries) a.key.toString(): a.value,
  },
  'path': path,
  'nodes': [
    for (final n in element.nodes)
      if (n is dom.Element)
        {'elementIndex': element.children.indexOf(n)}
      else if (n is dom.Text)
        {'nodeType': 3, 'data': n.data}
      else
        {'nodeType': n.nodeType},
  ],
  'children': [
    for (var i = 0; i < element.children.length; i++)
      _tree(element.children[i], [...path, i]),
  ],
};
final _cache = <String, Future<Map<String, Object?>>>{};
Future<Map<String, Object?>> _actual(
  String component,
  String variant,
  String theme,
) => _cache.putIfAbsent('$component/$variant/$theme', () async {
  final key = '$component-$variant-$theme-defaultStyle';
  final probe = rootProbeSpec(
    key: key,
    flutterClassName: 'source-only',
    boxObservationSource: _source(component),
  );
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': [probe.toJson()],
  });
  final recorder = VisualValueSsrSource.forEntry(entry)!;
  Map<String, Object?>? receipt;
  // Match web_capture_backend's shared SSR body. Entry theme is carried
  // separately by the browser harness data-theme CSS, not inferred here.
  final rendered = await renderComponentBodyHtml(
    coui.CoUIWeb(theme: .coui, child: _Capture(entry, recorder)),
    onMountedRoot: (root) => receipt = recorder.observe(root),
  );
  final document = html.parseFragment(rendered);
  final capture = document.querySelectorAll('[data-parity-key]').single;
  expect(
    document.querySelectorAll(probe.webSelector).single,
    same(capture.children.single),
  );
  expect(receipt!['kind'], 'canonical-ssr-visual-value-v1');
  expect(receipt!['entryKey'], entry.key);
  return {..._tree(capture, []), 'currentRaw': receipt!['currentRaw']};
});
Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  BoxObservationSourceSpec source, {
  String mutation = '',
  bool omitRaw = false,
}) async {
  final program =
      '''
$_kRuntime
const capture=node(${jsonEncode(tree)}),root=capture.children[0];
const source=${jsonEncode(source.toJson())};
const currentRaw=${jsonEncode(tree['currentRaw'])};
const resolve=($visualValueBoxSourceResolverScript);
global.getComputedStyle=()=>{throw Error('CSS source selection forbidden');};
global.document=new Proxy({},{get(){throw Error('Global search forbidden');}});
$mutation
const result=resolve(root,source${omitRaw ? '' : ',currentRaw'});
console.log(JSON.stringify(result.error?result:{registry:result.registryResultElement.path,
 field:result.fieldUnitElement.path,padding:result.paddingSource.path,frame:result.frameSource.path,
 registryIsLayoutRoot:result.registryIsLayoutRoot,foreign:result.foreignSeats.map(n=>n.path),
 current:result.currentOperationWitness,hasValue:Object.hasOwn(result,'value')}));
''';
  final result = await Process.run('node', ['-e', program]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return (jsonDecode(result.stdout.toString()) as Map).cast<String, Object?>();
}

void main() {
  for (final recipe in _kRecipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme exact SSR owner',
        () async {
          final tree = await _actual(recipe.component, recipe.variant, theme);
          final result = await _resolve(tree, _source(recipe.component));
          expect(result['error'], isNull);
          for (final field in ['registry', 'field', 'padding', 'frame']) {
            expect(result[field], [0]);
          }
          expect(result['registryIsLayoutRoot'], true);
          expect(result['foreign'], isEmpty);
          expect(result['hasValue'], false);
        },
      );
    }
  }
  for (final recipe in _kRecipes) {
    test(
      '${recipe.component}/${recipe.variant} requires current raw',
      () async {
        final tree = await _actual(recipe.component, recipe.variant, 'light');
        final result = await _resolve(
          tree,
          _source(recipe.component),
          omitRaw: true,
        );
        expect(result['error'], 'VISUAL_VALUE_CURRENT_RAW_REQUIRED');
      },
    );
    test('${recipe.component}/${recipe.variant} key/CSS keep owner', () async {
      final tree = await _actual(recipe.component, recipe.variant, 'light');
      final source = _source(recipe.component);
      final before = await _resolve(tree, source);
      expect(before['error'], isNull);
      final after = await _resolve(
        tree,
        source,
        mutation: '''
capture.attributes['data-parity-key']='arbitrary-next-theme-futureStyle';
capture.attributes.style='padding:901px 902px 903px 904px';
root.attributes.style='padding:7.25px 13px 19.5px 23px';
root.attributes.class='arbitrary-current-css-override';
''',
      );
      expect(after, before);
    });
  }
  for (final mutation in <String>[
    "delete capture.attributes['data-parity-key'];",
    'capture._list.push(root);',
    'root.isConnected=false;',
    'root.parentElement=null;',
    'currentRaw.kind="unknown";',
    'currentRaw.logicalUnitId="unknown";',
    'currentRaw.rawSlotCount=2;',
    'currentRaw.slotPresence=[true];',
    'currentRaw.undeclared=true;',
    'delete currentRaw.generatedTree;',
    _kDuplicateGeneratedTreeMutation,
    'currentRaw.generatedTree.namespaceURI="unknown";',
    'source.webAdapterId="foreign-v1";',
    'source.schemaVersion=9;',
  ]) {
    test('closed source rejects $mutation', () async {
      final tree = await _actual('countdown', 'default', 'light');
      final result = await _resolve(
        tree,
        _source('countdown'),
        mutation: mutation,
      );
      expect(result['error'], isNotNull);
      expect(result.containsKey('value'), false);
    });
  }
  for (final recipe in _kRecipes) {
    test(
      '${recipe.component}/${recipe.variant} missing child is HOLD',
      () async {
        final tree = await _actual(recipe.component, recipe.variant, 'light');
        final result = await _resolve(
          tree,
          _source(recipe.component),
          mutation: 'root._list.pop();',
        );
        expect(result['error'], 'VISUAL_VALUE_ACTUAL_GENERATED_TREE_CHANGED');
      },
    );
  }
  test('actual capture rejects a non-whitespace text sibling', () async {
    final tree = await _actual('icon', 'default', 'light');
    final result = await _resolve(
      tree,
      _source('icon'),
      mutation: '''
capture._extraNodes.push({nodeType:3,data:'outside',parentNode:capture});
''',
    );
    expect(result['error'], 'VISUAL_VALUE_CAPTURE_OUTPUT_CHANGED');
  });
  test('NBSP outside the root is layout text and is rejected', () async {
    final tree = await _actual('icon', 'default', 'light');
    final result = await _resolve(
      tree,
      _source('icon'),
      mutation: r'''
capture._extraNodes.push({nodeType:3,data:'\u00a0',parentNode:capture});
''',
    );
    expect(result['error'], 'VISUAL_VALUE_CAPTURE_OUTPUT_CHANGED');
  });
  test('formatting whitespace does not change the complete capture', () async {
    final tree = await _actual('countdown', 'default', 'light');
    final positive = await _resolve(tree, _source('countdown'));
    expect(positive['error'], isNull);
    final result = await _resolve(
      tree,
      _source('countdown'),
      mutation: r'''
capture._extraNodes.push({nodeType:3,data:' \n ',parentNode:capture});
''',
    );
    expect(result, positive);
  });
  test('actual bundled SVG keeps native namespace and case', () async {
    final tree = await _actual('icon', 'default', 'light');
    final root = (tree['children']! as List).single as Map;
    expect(root['tagName'], 'svg');
    expect(root['localName'], 'svg');
    expect(root['namespaceURI'], 'http://www.w3.org/2000/svg');
    final result = await _resolve(tree, _source('icon'));
    expect(result['error'], isNull);
    final wrong = await _resolve(
      tree,
      _source('icon'),
      mutation: "root.tagName='SVG';",
    );
    expect(wrong['error'], 'VISUAL_VALUE_ACTUAL_GENERATED_TREE_CHANGED');
  });
  for (final mutation in [
    "root.namespaceURI='http://www.w3.org/1999/xhtml';root.tagName='SVG';",
    'delete root.namespaceURI;',
    'root._list[0].parentElement=capture;',
    'root._list.push(root._list[0]);',
  ]) {
    test('generated SVG rejects $mutation', () async {
      final result = await _resolve(
        await _actual('icon', 'search', 'light'),
        _source('icon'),
        mutation: mutation,
      );
      expect(result['error'], isNotNull);
    });
  }
  test('complete skeleton ordering follows the actual raw witness', () async {
    final tree = await _actual('skeleton', 'text', 'light');
    final positive = await _resolve(tree, _source('skeleton'));
    expect(positive['error'], isNull);
    final result = await _resolve(
      tree,
      _source('skeleton'),
      mutation: '''
const last=root._list.pop();root._list.unshift(last);
''',
    );
    expect(result['error'], 'VISUAL_VALUE_ACTUAL_GENERATED_TREE_CHANGED');
  });
  test('actual child count cannot be replaced by a source default', () async {
    final tree = await _actual('skeleton', 'text', 'light');
    final result = await _resolve(
      tree,
      _source('skeleton'),
      mutation: '''
root._list.splice(1,1);
''',
    );
    expect(result['error'], 'VISUAL_VALUE_ACTUAL_GENERATED_TREE_CHANGED');
  });
  test('invented skeleton seat is rejected', () async {
    final result = await _resolve(
      await _actual('skeleton', 'text', 'light'),
      _source('skeleton'),
      mutation: '''
root._list[0].tagName='ARTICLE';root._list[0].localName='article';
currentRaw.generatedTree.children[0].localName='article';
''',
    );
    expect(result['error'], 'VISUAL_VALUE_SKELETON_LINE_ORDER_CHANGED');
  });
}

class _Capture extends StatelessComponent {
  const _Capture(this.entry, this.recorder);
  final MatrixEntry entry;
  final VisualValueSsrSource recorder;
  @override
  Component build(BuildContext context) {
    final result = kWebPreviewRegistry[entry.component]!(
      context,
      entry.variant == 'default' ? null : entry.variant,
    );
    final capture = div([result], attributes: {'data-parity-key': entry.key});
    recorder.recordBuild(result, capture);
    return capture;
  }
}
