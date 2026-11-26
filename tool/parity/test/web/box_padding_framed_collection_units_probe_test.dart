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
import '../../src/web/box_padding_framed_collection_units_probe.dart';
import '../../src/web/framed_collection_ssr_source.dart';
import '../../src/web/ssr_render.dart';

const _recipes = [
  ('mockup', 'phone'),
  ('mockup', 'tablet'),
  ('mockup', 'landscape'),
  ('mockup-device', 'default'),
  ('mockup-device', 'flat'),
  ('join', 'default'),
  ('join', 'input'),
  ('join', 'vertical'),
  ('table', 'default'),
  ('table', 'resizable'),
];
BoxObservationSourceSpec _source(String component) => switch (component) {
  'join' => BoxObservationSourceSpec.joinStripLayoutHost,
  'table' => BoxObservationSourceSpec.tableGridContentInset,
  _ => BoxObservationSourceSpec.mockupDeviceBodyFrame,
};

Map<String, Object?> _tree(dom.Element node, List<int> path) => {
  'namespaceURI': node.namespaceUri,
  'localName': node.localName,
  'attributes': {
    for (final a in node.attributes.entries) a.key.toString(): a.value,
  },
  'path': path,
  'children': [
    for (var i = 0; i < node.children.length; i++)
      _tree(node.children[i], [...path, i]),
  ],
  'childNodes': [
    for (final child in node.nodes)
      if (child is dom.Element)
        {'elementIndex': node.children.indexOf(child)}
      else
        {
          'nodeType': child.nodeType,
          'data': child is dom.Text
              ? child.data
              : child is dom.Comment
              ? child.data
              : '',
        },
  ],
};

Future<({Map<String, Object?> tree, Map<String, Object?> raw})> _actual(
  String component,
  String variant,
  String theme, {
  coui.CoreSurfaceStyleId style = .defaultStyle,
}) async {
  final source = _source(component);
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme,
    'surfaceStyle': style.name,
    'tier': 't2',
    'probes': [
      rootProbeSpec(
        key: '$component-$variant-$theme-${style.name}',
        flutterClassName: 'source-only',
        boxObservationSource: source,
      ).toJson(),
    ],
  });
  final recorder = FramedCollectionSsrSource.forEntry(entry)!;
  Map<String, Object?>? receipt;
  final document = await renderComponentToDocumentHtml(
    coui.CoUIWeb(theme: .coui, child: _Capture(entry, recorder)),
    onMountedRoot: (root) {
      receipt = recorder.observe(root);
    },
  );
  final capture = html
      .parse(document)
      .querySelectorAll('[data-parity-key]')
      .single;
  return (
    tree: _tree(capture, []),
    raw: (receipt!['currentRaw']! as Map).cast<String, Object?>(),
  );
}

const _runtime = r'''
const node=(data,parent=null)=>{
 const attrs={...data.attributes};
 const e={nodeType:1,namespaceURI:data.namespaceURI,localName:data.localName,
  path:data.path,parentElement:parent,attributes:attrs,
  getAttribute:name=>Object.hasOwn(attrs,name)?attrs[name]:null,
  hasAttribute:name=>Object.hasOwn(attrs,name),
  classList:{contains:name=>(attrs.class??'').split(/\s+/).includes(name)}};
 e._children=data.children.map(child=>node(child,e));
 Object.defineProperty(e,'children',{get:()=>e._children});
 e.childNodes=data.childNodes.map(child=>Object.hasOwn(child,'elementIndex')?
  e._children[child.elementIndex]:{nodeType:child.nodeType,data:child.data});
 e.contains=other=>e===other||e._children.some(child=>child.contains(other));
 for(const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
  Object.defineProperty(e,name,{get(){throw Error('Geometry must not choose source owner');}});
 return e;
};
global.getComputedStyle=()=>{throw Error('CSS must be sampled after source binding');};
global.document=new Proxy({},{get(){throw Error('Global owner search forbidden');}});
''';

Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  Map<String, Object?> raw,
  String component, {
  String mutation = '',
  BoxObservationSourceSpec? source,
}) async {
  final program =
      '''
$_runtime
const capture=node(${jsonEncode(tree)});
const device=${component == 'mockup' || component == 'mockup-device'};
const registry=capture.children[0],root=device?registry.children[0]:registry;
const raw=${jsonEncode(raw)},source=${jsonEncode((source ?? _source(component)).toJson())};
$mutation
const result=($framedCollectionBoxSourceResolverScript)(root,source,raw);
console.log(JSON.stringify(result.error?result:{registry:result.registryResultElement.path,
 field:result.fieldUnitElement.path,padding:result.paddingSource.path,frame:result.frameSource.path,
 registryIsLayoutRoot:result.registryIsLayoutRoot,hasValue:Object.hasOwn(result,'value')}));
''';
  final child = await Process.run('node', ['-e', program]);
  expect(child.exitCode, 0, reason: child.stderr.toString());
  return (jsonDecode(child.stdout.toString()) as Map).cast<String, Object?>();
}

void main() {
  for (final (component, variant) in _recipes) {
    for (final theme in ['light', 'dark']) {
      test('$component/$variant/$theme actual canonical own frame', () async {
        final actual = await _actual(component, variant, theme);
        final result = await _resolve(actual.tree, actual.raw, component);
        final device = component == 'mockup' || component == 'mockup-device';
        expect(result, {
          'registry': [0],
          'field': device ? [0, 0] : [0],
          'padding': device ? [0, 0] : [0],
          'frame': device ? [0, 0] : [0],
          'registryIsLayoutRoot': !device,
          'hasValue': false,
        });
      });
    }
  }
  for (final style in coui.CoreSurfaceStyleId.values) {
    test('source refs are independent of ${style.name} style', () async {
      for (final (component, variant) in [
        ('mockup-device', 'flat'),
        ('join', 'input'),
        ('table', 'resizable'),
      ]) {
        final actual = await _actual(component, variant, 'light', style: style);
        expect(
          await _resolve(actual.tree, actual.raw, component),
          containsPair('hasValue', false),
        );
      }
    });
  }
  test('capture identity has no recipe or style-suffix whitelist', () async {
    const arbitraryIdentity =
        "capture.attributes['data-parity-key']="
        "'arbitrary-key-future-style';";
    final actual = await _actual('join', 'default', 'light');
    final baseline = await _resolve(actual.tree, actual.raw, 'join');
    expect(
      await _resolve(
        actual.tree,
        actual.raw,
        'join',
        mutation: arbitraryIdentity,
      ),
      baseline,
    );
  });
  test('whole supplied child subtrees remain opaque', () async {
    for (final (component, variant) in [
      ('mockup-device', 'flat'),
      ('join', 'input'),
      ('table', 'resizable'),
    ]) {
      final actual = await _actual(component, variant, 'light');
      final baseline = await _resolve(actual.tree, actual.raw, component);
      const mutation = '''
const mutate=(n,w)=>{
 if(Object.hasOwn(w,'foreignSlot')){
  n.namespaceURI='arbitrary-foreign-namespace';n.localName='foreign-whole-root';
  n.attributes.style='padding:901px 902px 903px 904px';
  n._children=[node({namespaceURI:'foreign',localName:'nested',attributes:{role:'table'},path:[999],children:[],childNodes:[]},n)];
  return;
 }
 w.children.forEach((child,index)=>mutate(n.children[index],child));
};
mutate(registry,raw.generatedTree);
''';
      expect(
        await _resolve(actual.tree, actual.raw, component, mutation: mutation),
        baseline,
      );
    }
  });
  for (final (name, mutation) in <(String, String)>[
    ('outside text', "capture.childNodes.push({nodeType:3,data:'outside'});"),
    ('outside NBSP', r"capture.childNodes.push({nodeType:3,data:'\u00a0'});"),
    (
      'outside comment',
      "capture.childNodes.push({nodeType:8,data:'comment'});",
    ),
    ('missing identity', "delete capture.attributes['data-parity-key'];"),
    ('missing current source', 'delete raw.kind;'),
    ('unknown current field', 'raw.extra=true;'),
    ('raw boolean count', 'raw.rawSlotCount=true;'),
    ('wrong generated namespace', "raw.generatedTree.namespaceURI='wrong';"),
    ('wrong generated child order', 'registry._children.reverse();'),
  ]) {
    test('$name rejects before CSS reads', () async {
      final actual = await _actual('join', 'default', 'light');
      expect(
        await _resolve(actual.tree, actual.raw, 'join', mutation: mutation),
        contains('error'),
      );
    });
  }
  test('table whole row and generated resizer losses reject', () async {
    final actual = await _actual('table', 'resizable', 'light');
    for (final mutation in [
      'registry._children.pop();',
      'registry.children[0]._children.reverse();',
      'registry.children[0].children[0]._children.pop();',
      "registry.children[0].children[0].attributes.role='cell';",
      'raw.rows[0].cells[0].columnSpan=2;',
    ]) {
      expect(
        await _resolve(actual.tree, actual.raw, 'table', mutation: mutation),
        contains('error'),
      );
    }
  });
  for (final component in ['join', 'table']) {
    for (final data in ['outside', '\u00a0']) {
      test('$component own raw host rejects anonymous DOM text', () async {
        final actual = await _actual(component, 'default', 'light');
        final target = component == 'join'
            ? 'root.children[1]'
            : 'root.children[0].children[0]';
        final encodedText = jsonEncode(data);
        expect(
          await _resolve(
            actual.tree,
            actual.raw,
            component,
            mutation:
                '$target.childNodes.push({nodeType:3,data:$encodedText});',
          ),
          contains('error'),
        );
      });
    }
  }
  test('existing browser tuple is not a second new reader', () async {
    final actual = await _actual('join', 'default', 'light');
    expect(
      await _resolve(
        actual.tree,
        actual.raw,
        'join',
        source: BoxObservationSourceSpec.mockupBrowserFrame,
      ),
      contains('error'),
    );
  });
}

class _Capture extends StatelessComponent {
  const _Capture(this.entry, this.recorder);
  final MatrixEntry entry;
  final FramedCollectionSsrSource recorder;
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
