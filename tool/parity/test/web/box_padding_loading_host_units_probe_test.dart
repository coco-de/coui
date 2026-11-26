import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_loading_host_units_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _kDomRuntime = r'''
global.getComputedStyle = () => {throw Error('CSS owner selection forbidden');};
global.document = new Proxy({}, {get(){throw Error('Global search forbidden');}});
const node = (data,parent=null) => {
  const attrs={...data.attributes};
  const value={tagName:data.tagName,path:data.path,parentElement:parent,
    getAttribute:name=>attrs[name] ?? null,
    hasAttribute:name=>Object.hasOwn(attrs,name),
    attributes:attrs,
    classList:{contains:name=>(attrs.class ?? '').split(/\s+/).includes(name)}};
  value._list=data.children.map(child=>node(child,value));
  Object.defineProperty(value,'children',{get(){
    const collection={length:value._list.length};
    value._list.forEach((child,index)=>collection[index]=child);
    return collection;
  }});
  for(const key of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
    Object.defineProperty(value,key,{get(){throw Error('Numeric owner selection forbidden');}});
  return value;
};
''';

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
  String variant, {
  String theme = 'light',
}) async {
  final entry = MatrixEntry.fromJson({
    'component': 'loading',
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': <Object?>[],
  });
  final prepared = Platform.environment['LOADING_HOST_SSR_DIR'];
  final body = prepared == null
      ? await renderCaptureBodyHtml(entry)
      : File('$prepared/${entry.key}.body.html').readAsStringSync();
  final roots = html.parseFragment(body).querySelectorAll('[data-parity-key]');
  expect(roots, hasLength(1));
  expect(roots.single.attributes['data-parity-key'], entry.key);
  expect(roots.single.children, hasLength(1));
  return _tree(roots.single, const []);
}

Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree, {
  String mutation = '',
}) async {
  final script =
      '''
const resolve=($loadingHostBoxSourceResolverScript);
$_kDomRuntime
const capture=node(${jsonEncode(tree)}),root=capture.children[0];
const source=${jsonEncode(BoxObservationSourceSpec.loadingSizeHost.toJson())};
$mutation
const result=resolve(root,source);
console.log(JSON.stringify(result.error ? result : {
  registry:result.registryResultElement.path,unit:result.fieldUnitElement.path,
  padding:result.paddingSource.path,frame:result.frameSource.path,
  hasValue:Object.hasOwn(result,'value'),authority:result.authority,
  callerStyle:root.attributes.style ?? null,nonArrayChildren:!Array.isArray(root.children)
}));
''';
  final process = await Process.run('node', ['-e', script]);
  expect(process.exitCode, 0, reason: process.stderr.toString());
  return (jsonDecode(process.stdout.toString()) as Map).cast<String, Object?>();
}

void main() {
  for (final variant in ['default', 'dots', 'bar', 'pulse']) {
    for (final theme in ['light', 'dark']) {
      test('$variant/$theme actual SSR source host refs', () async {
        final result = await _resolve(await _actual(variant, theme: theme));
        expect(result['error'], isNull);
        expect(result['registry'], [0]);
        expect(result['unit'], [0]);
        expect(result['padding'], [0]);
        expect(result['frame'], [0]);
        expect(result['hasValue'], false);
        expect(result['nonArrayChildren'], true);
      });
    }
  }
  for (final mutation in [
    'source.schemaVersion=99;',
    'source.quantityId="unknown";',
    'source.logicalUnitId="unknown";',
    'source.nativeAdapterId="unknown";',
    'source.webAdapterId="unknown";',
    'root.tagName="DIV";',
    'capture._list.push(root);',
    'delete root.attributes.role;',
    'root._list=[];',
    'root._list.push(root._list[1]);',
    'root._list[1]._list[0].tagName="RECT";',
    'root._list.push(root._list[0]);',
    'root._list.reverse();',
  ]) {
    test('reject changed capture/tuple/source: $mutation', () async {
      expect(
        (await _resolve(await _actual('default'), mutation: mutation))['error'],
        isNotNull,
      );
    });
  }
  test(
    'source-generated STYLE is optional, SVG namespace casing preserved',
    () async {
      final result = await _resolve(
        await _actual('default'),
        mutation:
            'root._list=root._list.filter(n=>n.tagName!=="STYLE");'
            'root._list.forEach(n=>{n.tagName="svg";'
            'n._list[0].tagName="circle";});',
      );
      expect(result['error'], isNull);
      expect(result['padding'], [0]);
    },
  );
  test(
    'caller padding remains untouched and never selects the owner',
    () async {
      const callerDeclaration = 'padding:17px 9px 5px 3px';
      final result = await _resolve(
        await _actual('bar'),
        mutation: 'root.attributes.style=${jsonEncode(callerDeclaration)};',
      );
      expect(result['error'], isNull);
      expect(result['padding'], [0]);
      expect(result['callerStyle'], callerDeclaration);
      expect(result['hasValue'], false);
      // This is a refs-only Node boundary control, not CSS cascade measurement.
    },
  );
}
