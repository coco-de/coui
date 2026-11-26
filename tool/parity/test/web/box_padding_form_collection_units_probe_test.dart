import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/web/box_padding_form_collection_units_probe.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/web_capture_backend.dart';

const _kRecipes = <({String component, String variant})>[
  (component: 'toggle-group', variant: 'default'),
  (component: 'toggle-group', variant: 'vertical'),
  (component: 'form-field', variant: 'default'),
  (component: 'form-label', variant: 'default'),
  (component: 'listing', variant: 'default'),
  (component: 'option-list', variant: 'default'),
];
const _kDomRuntime = r'''
const node=(data,parent=null)=>{
  const attrs={...data.attributes};
  const value={tagName:data.tagName,path:data.path,isConnected:true,parentElement:parent,
    getAttribute:name=>attrs[name]??null,hasAttribute:name=>Object.hasOwn(attrs,name),
    classList:{contains:name=>(attrs.class??'').split(/\s+/).includes(name)},attributes:attrs};
  value._list=data.children.map(child=>node(child,value));
  Object.defineProperty(value,'children',{get(){
    const collection={length:value._list.length};
    value._list.forEach((child,index)=>collection[index]=child);
    return collection;
  }});
  value.contains=other=>value===other||value._list.some(child=>child.contains(other));
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

Future<Map<String, Object?>> _run(String script) async {
  final process = await Process.run('node', ['-e', script]);
  expect(process.exitCode, 0, reason: process.stderr.toString());
  return (jsonDecode(process.stdout.toString()) as Map).cast<String, Object?>();
}

void main() {
  for (final recipe in _kRecipes) {
    for (final theme in ParityTheme.values) {
      test(
        '${recipe.component}/${recipe.variant}/${theme.name} '
        'actual canonical SSR helper and shared dispatch',
        () async {
          final key =
              '${recipe.component}-${recipe.variant}-${theme.name}'
              '-defaultStyle';
          final probe = captureProbes(
            key: key,
            component: recipe.component,
            variant: recipe.variant,
            flutterClassName: 'sanity-only',
          ).single;
          final entry = MatrixEntry(
            component: recipe.component,
            variant: recipe.variant,
            theme: theme,
            surfaceStyle: .defaultId,
            tier: ParityTier.t1,
            probes: [probe],
          );
          final body = await renderCaptureBodyHtml(entry);
          final fragment = html.parseFragment(body);
          final captures = fragment.querySelectorAll('[data-parity-key]');
          expect(captures, hasLength(1));
          final selected = fragment.querySelectorAll(probe.webSelector);
          expect(selected, hasLength(1));
          // Use the real manifest selector, not a guessed first descendant.
          expect(selected.single, same(captures.single.children.single));
          final tree = jsonEncode(_tree(captures.single, const []));
          final source = jsonEncode(probe.boxObservationSource!.toJson());
          final depth = recipe.component == 'form-field' ? 2 : 1;
          final direct = await _run('''
$_kDomRuntime
const resolve=($formCollectionBoxSourceResolverScript);
const capture=node($tree),root=capture.children[0];
global.document=new Proxy({},{get(){throw Error('Global query forbidden');}});
global.getComputedStyle=()=>{throw Error('CSS owner selection forbidden');};
const result=resolve(root,$source);
console.log(JSON.stringify(result.error?result:{registry:result.registryResultElement.path,
 field:result.fieldUnitElement.path,padding:result.paddingSource.path,frame:result.frameSource.path,
 hasValue:Object.hasOwn(result,'value'),nonArray:!Array.isArray(root.children)}));
''');
          expect(direct['error'], isNull, reason: '$direct');
          expect(direct['registry'], [0]);
          expect(direct['field'], List<int>.filled(depth, 0));
          expect(direct['padding'], direct['field']);
          expect(direct['frame'], direct['field']);
          expect(direct['hasValue'], false);
          expect(direct['nonArray'], true);
          final dispatched = await _run('''
$_kDomRuntime
const capture=node($tree),root=capture.children[0],cssOwners=[];
const observe=($boxPaddingObservationScript);
global.document={querySelectorAll:selector=>selector===${jsonEncode(probe.webSelector)}?[root]:[]};
global.getComputedStyle=owner=>{cssOwners.push(owner.path);return {display:'block',paddingTop:'1px',paddingRight:'2px',paddingBottom:'3px',paddingLeft:'4px'};};
const actual=JSON.parse(observe({requested:true,selector:${jsonEncode(probe.webSelector)},layoutSelector:${jsonEncode(probe.webSelector)},source:$source}));
console.log(JSON.stringify({actual,cssOwners}));
''');
          final actual = dispatched['actual']! as Map;
          expect(actual['status'], 'source-complete', reason: '$actual');
          expect(actual['source'], probe.boxObservationSource!.toJson());
          expect(actual['canonicalComparisonEligible'], isFalse);
          expect(dispatched['cssOwners'], [List<int>.filled(depth, 0)]);
          expect(actual['ownerIsLayoutRoot'], depth == 1);
          final mutation = recipe.component == 'form-field'
              ? 'root._list.push(node({tagName:"DIV",attributes:{},'
                    'path:[0,99],children:[]},root));'
              : 'root.parentElement=null;';
          final rejected = await _run('''
$_kDomRuntime
const resolve=($formCollectionBoxSourceResolverScript);
const capture=node($tree),root=capture.children[0];
global.getComputedStyle=()=>{throw Error('CSS owner selection forbidden');};
$mutation
console.log(JSON.stringify(resolve(root,$source)));
''');
          expect(rejected['error'], isNotNull);
        },
      );
    }
  }
  test(
    'complete source tuple and unknown unit fail before DOM or style read',
    () async {
      final valid = BoxObservationSourceSpec.formLabelRowLayoutHost.toJson();
      for (final changed in <Map<String, Object?>>[
        {...valid, 'schemaVersion': 2},
        {...valid, 'logicalUnitId': 'unknown'},
        {...valid, 'nativeAdapterId': 'unknown'},
        {...valid, 'webAdapterId': 'unknown'},
        {...valid, 'quantityId': 'unknown'},
      ]) {
        final result = await _run('''
const resolve=($formCollectionBoxSourceResolverScript);
const root=new Proxy({},{get(){throw Error('Source mismatch must reject before DOM read');}});
console.log(JSON.stringify(resolve(root,${jsonEncode(changed)})));
''');
        expect(result['error'], isNotNull);
      }
    },
  );
}
