import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/property_field.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/framed_collection_ssr_source.dart';
import '../../src/web/web_capture_backend.dart';

const _recipes = [
  ('mockup', 'phone'),
  ('mockup', 'tablet'),
  ('mockup', 'landscape'),
  ('mockup-device', 'default'),
  ('mockup-device', 'flat'),
  ('mockup', 'browser'),
  ('mockup', 'app'),
  ('join', 'default'),
  ('join', 'input'),
  ('join', 'vertical'),
  ('table', 'default'),
  ('table', 'resizable'),
];

BoxObservationSourceSpec _source(String component, String variant) =>
    switch (component) {
      'join' => BoxObservationSourceSpec.joinStripLayoutHost,
      'table' => BoxObservationSourceSpec.tableGridContentInset,
      'mockup-browser' => BoxObservationSourceSpec.mockupBrowserFrame,
      'mockup' when variant == 'browser' || variant == 'app' =>
        BoxObservationSourceSpec.mockupBrowserFrame,
      _ => BoxObservationSourceSpec.mockupDeviceBodyFrame,
    };

MatrixEntry _entry(String component, String variant, String theme) {
  final key = '$component-$variant-$theme-defaultStyle';
  return MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': captureProbes(
      key: key,
      component: component,
      variant: variant,
      flutterClassName: 'source-only',
    ).map((probe) => probe.toJson()).toList(),
  });
}

Map<String, Object?> _tree(dom.Element node) => {
  'namespaceURI': node.namespaceUri,
  'localName': node.localName,
  'attributes': {
    for (final a in node.attributes.entries) a.key.toString(): a.value,
  },
  'children': node.children.map(_tree).toList(),
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

typedef _Actual = ({
  MatrixEntry entry,
  Map<String, Object?>? receipt,
  Map<String, Object?> tree,
  List<int> rootPath,
  List<int>? stagePath,
});

List<int>? _path(dom.Element node, dom.Element target, List<int> prefix) {
  if (identical(node, target)) return prefix;
  for (var i = 0; i < node.children.length; i++) {
    final found = _path(node.children[i], target, [...prefix, i]);
    if (found != null) return found;
  }
  return null;
}

final _cache = <String, Future<_Actual>>{};
Future<_Actual> _actual(String component, String variant, String theme) =>
    _cache.putIfAbsent('$component/$variant/$theme', () async {
      final entry = _entry(component, variant, theme);
      var callbacks = 0;
      Map<String, Object?>? receipt;
      final body = await renderCaptureBodyHtml(
        entry,
        onCurrentBoxSource: (witness) {
          callbacks++;
          receipt = witness;
        },
      );
      final legacy = component == 'mockup-browser';
      expect(callbacks, legacy ? 0 : 1);
      if (!legacy) {
        expect(receipt!['error'], isNull);
        expect(receipt!['kind'], 'canonical-ssr-framed-collection-v1');
      }
      final document = html.parseFragment(body);
      final capture = document.querySelectorAll('[data-parity-key]').single;
      final root = entry.probes.singleWhere((probe) => probe.role == 'root');
      expect(root.boxObservationSource, _source(component, variant));
      final selected = document.querySelectorAll(root.webSelector).single;
      final rootPath = _path(capture, selected, [])!;
      final stages = entry.probes
          .where((probe) => probe.role == 'stage')
          .toList();
      final stagePath = stages.isEmpty
          ? null
          : _path(
              capture,
              document.querySelectorAll(stages.single.webSelector).single,
              [],
            )!;
      return (
        entry: entry,
        receipt: receipt,
        tree: _tree(capture),
        rootPath: rootPath,
        stagePath: stagePath,
      );
    });

Future<Map<String, Object?>> _sample(
  _Actual actual, {
  String mutation = '',
  String role = 'root',
}) async {
  const url = 'file:///owned/framed-current-source.html';
  final receipt = actual.receipt == null
      ? null
      : {...actual.receipt!, 'harnessURL': url};
  final component = actual.entry.component;
  final variant = actual.entry.variant;
  final rootProbe = actual.entry.probes.singleWhere(
    (probe) => probe.role == 'root',
  );
  final probe = actual.entry.probes.singleWhere((probe) => probe.role == role);
  final browser =
      rootProbe.boxObservationSource ==
      BoxObservationSourceSpec.mockupBrowserFrame;
  final device = !browser && component != 'join' && component != 'table';
  final nodeProgram =
      '''
const from=(data,parent=null)=>{
 const attrs={...data.attributes},names=(attrs.class||'').split(/[\\t\\n\\f\\r ]+/).filter(Boolean);
 names.contains=name=>names.includes(name);
 const node={nodeType:1,namespaceURI:data.namespaceURI,localName:data.localName,
  tagName:data.namespaceURI==='http://www.w3.org/1999/xhtml'?data.localName.toUpperCase():data.localName,
  classList:names,parentElement:parent,parentNode:parent,isConnected:true,
  getAttribute:name=>Object.hasOwn(attrs,name)?attrs[name]:null,
  hasAttribute:name=>Object.hasOwn(attrs,name)};
 node.children=data.children.map(child=>from(child,node));
 node.childNodes=data.childNodes.map(child=>Object.hasOwn(child,'elementIndex')?
  node.children[child.elementIndex]:{nodeType:child.nodeType,data:child.data,parentNode:node,isConnected:true});
 node.contains=other=>node===other||node.children.some(child=>child.contains(other));
 for(const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
  Object.defineProperty(node,name,{get(){throw Error('Geometry used for owner');}});
 return node;
};
const capture=from(${jsonEncode(actual.tree)}),registry=capture.children[0];
const at=path=>path.reduce((node,index)=>node.children[index],capture);
const canonicalRoot=at(${jsonEncode(actual.rootPath)}),stagePath=${jsonEncode(actual.stagePath)};
const canonicalStage=stagePath===null?null:at(stagePath);
// Independent oracle follows the original public producer's authored edges,
// before the dispatcher executes. It never calls a source resolver.
const expectedOwner=$device?registry.children[0]:$browser?
 ${jsonEncode(variant)}==='app'?registry.children[0]:registry.children[0].children[0]:registry;
// Resolve the exact original selectors using paths queried from actual SSR.
global.document={querySelectorAll:selector=>{
 if(selector===${jsonEncode(rootProbe.webSelector)})return [canonicalRoot];
 if(canonicalStage && selector===${jsonEncode(actual.entry.probes.where((p) => p.role == 'stage').firstOrNull?.webSelector)})return [canonicalStage];
 throw Error('Unexpected selector: '+selector);
}};
global.location={href:${jsonEncode(url)}};
let cssReads=0;
global.getComputedStyle=owner=>{cssReads++;return {display:'block',
 paddingTop:owner===expectedOwner?'7.25px':'901px',paddingRight:owner===expectedOwner?'13px':'902px',
 paddingBottom:owner===expectedOwner?'19.5px':'903px',paddingLeft:owner===expectedOwner?'23px':'904px'};};
const request={requested:${probe.fields.contains(PropertyField.paddingPx)},
 selector:${jsonEncode(probe.webSelector)},layoutSelector:${jsonEncode(probe.webSelector)},
 source:${jsonEncode(probe.boxObservationSource?.toJson())},
 currentSsrSource:${jsonEncode(receipt)},
 requiredCurrentSsrKind:${jsonEncode(requiredFramedCollectionSsrKind(actual.entry))}};
$mutation
const observed=JSON.parse(($boxPaddingObservationScript)(request));
console.log(JSON.stringify({observed,cssReads}));
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
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
}

void main() {
  for (final (component, variant) in _recipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '$component/$variant/$theme actual SSR bridge and CSS owner',
        () async {
          final actual = await _actual(component, variant, theme);
          final result = await _sample(actual);
          final observed = result['observed']! as Map;
          final device = actual.entry.probes.any(
            (probe) => probe.role == 'stage',
          );
          final ownRoot =
              component != 'mockup' || !['browser', 'app'].contains(variant);
          expect(result['cssReads'], 1, reason: '$observed');
          expect(observed['status'], 'source-complete');
          expect(observed['value'], [7.25, 13, 19.5, 23]);
          expect(observed['registryIsLayoutRoot'], !device);
          expect(observed['ownerIsLayoutRoot'], ownRoot);
          expect(observed['canonicalComparisonEligible'], false);
          expect(actual.receipt!.keys.length, 6);
          expect(
            requiredFramedCollectionSsrKind(actual.entry),
            'canonical-ssr-framed-collection-v1',
          );
        },
      );
    }
  }
  test(
    'canonical recipes retain 24 roots and ten untouched stage probes',
    () async {
      var roots = 0;
      var stages = 0;
      for (final (component, variant) in _recipes) {
        for (final theme in ['light', 'dark']) {
          final actual = await _actual(component, variant, theme);
          roots += actual.entry.probes
              .where((probe) => probe.role == 'root')
              .length;
          final stageProbes = actual.entry.probes.where(
            (probe) => probe.role == 'stage',
          );
          stages += stageProbes.length;
          if (stageProbes.isNotEmpty) {
            expect(actual.rootPath, [0, 0]);
            expect(actual.stagePath, [0]);
            expect(stageProbes.single.boxObservationSource, isNull);
            expect(stageProbes.single.fields, {
              PropertyField.widthPx,
              PropertyField.heightPx,
            });
            final result = await _sample(actual, role: 'stage');
            expect(result['observed'], {'status': 'not-requested'});
            expect(result['cssReads'], 0);
          }
        }
      }
      expect(roots, 24);
      expect(stages, 10);
    },
  );
  for (final (label, mutation) in [
    ('wrong parent', 'canonicalRoot.parentElement=capture;'),
    ('missing parent', 'canonicalRoot.parentElement=null;'),
    ('extra registry child', 'registry.children.push({...canonicalRoot});'),
    (
      'extra own text',
      "canonicalRoot.childNodes.push({nodeType:3,data:'undeclared'});",
    ),
    ('missing receipt', 'delete request.currentSsrSource;'),
  ]) {
    test('Device canonical body rejects $label before CSS', () async {
      final result = await _sample(
        await _actual('mockup-device', 'flat', 'light'),
        mutation: mutation,
      );
      expect((result['observed']! as Map)['status'], 'incomplete');
      expect(result['cssReads'], 0);
    });
  }
  test('old direct-slug Browser uses its unchanged reader', () async {
    final actual = await _actual('mockup-browser', 'default', 'light');
    expect(actual.receipt, isNull);
    expect(requiredFramedCollectionSsrKind(actual.entry), isNull);
    final result = await _sample(actual);
    expect((result['observed']! as Map)['value'], [7.25, 13, 19.5, 23]);
    expect(result['cssReads'], 1);
  });
  for (final (component, variant) in _recipes) {
    for (final (label, mutation) in [
      ('missing', 'request.currentSsrSource=null;'),
      (
        'wrong kind',
        "request.currentSsrSource.kind='canonical-ssr-visual-value-v1';",
      ),
      ('wrong entry', "request.currentSsrSource.entryKey='foreign-key';"),
      ('wrong URL', "request.currentSsrSource.harnessURL='file:///foreign';"),
      ('wrong tuple', 'request.currentSsrSource.source={};'),
      ('extra header', 'request.currentSsrSource.extra=true;'),
      (
        'wrong slot count',
        'request.currentSsrSource.completeRawSlotCount=999;',
      ),
      ('missing requirement', 'delete request.requiredCurrentSsrKind;'),
      (
        'generated text',
        "registry.childNodes.push({nodeType:3,data:'undeclared'});",
      ),
    ]) {
      test('$component/$variant rejects $label before CSS', () async {
        final result = await _sample(
          await _actual(component, variant, 'light'),
          mutation: mutation,
        );
        expect((result['observed']! as Map)['status'], 'incomplete');
        expect(result['cssReads'], 0);
      });
    }
  }
  test('recognized wrong constructor cannot use the old Browser route', () {
    final expected = _entry('mockup', 'browser', 'light').toJson();
    for (final change in [
      {'component': 'button', 'variant': 'default'},
      {'component': 'mockup', 'variant': 'unreviewed'},
    ]) {
      final forged = MatrixEntry.fromJson({...expected, ...change});
      expect(() => requiredFramedCollectionSsrKind(forged), throwsStateError);
    }
  });
}
