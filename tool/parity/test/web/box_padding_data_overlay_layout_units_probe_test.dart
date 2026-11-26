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
import '../../src/web/box_padding_data_overlay_layout_units_probe.dart';
import '../../src/web/data_overlay_ssr_source.dart';
import '../../src/web/ssr_render.dart';

const _recipes = <({String component, String variant})>[
  (component: 'theme-controller', variant: 'default'),
  (component: 'tracker', variant: 'default'),
  (component: 'bottom-sheet', variant: 'default'),
  (component: 'bottom-sheet', variant: 'close'),
  (component: 'swiper', variant: 'default'),
  (component: 'swiper', variant: 'sheet'),
  (component: 'diff', variant: 'default'),
  (component: 'diff', variant: 'text'),
];
BoxObservationSourceSpec _source(String component) => switch (component) {
  'theme-controller' =>
    BoxObservationSourceSpec.themeControllerOptionGridLayoutHost,
  'tracker' => BoxObservationSourceSpec.trackerSegmentRowLayoutHost,
  'bottom-sheet' => BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
  'swiper' => BoxObservationSourceSpec.swiperTriggerLayoutHost,
  'diff' => BoxObservationSourceSpec.diffViewerLayoutHost,
  _ => throw ArgumentError(component),
};
const _runtime = r'''
const node=(data,parent=null)=>{
 const attrs={...data.attributes};
 const element={tagName:data.tagName,path:data.path,attributes:attrs,parentElement:parent,isConnected:true,
  getAttribute:name=>attrs[name]??null,hasAttribute:name=>Object.hasOwn(attrs,name),
  classList:{contains:name=>(attrs.class??'').split(/\s+/).includes(name)}};
 element._list=data.children.map(c=>node(c,element));
 Object.defineProperty(element,'children',{get(){const result={length:element._list.length};
  element._list.forEach((child,i)=>result[i]=child);return result;}});
 element.contains=other=>element===other || element._list.some(c=>c.contains(other));
 for(const key of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
  Object.defineProperty(element,key,{get(){throw Error('Numeric source selection forbidden');}});
 element.getBoundingClientRect=()=>{throw Error('Geometry source selection forbidden');};
 return element;
};
''';
Map<String, Object?> _tree(dom.Element node, List<int> path) => {
  'tagName': node.localName!.toUpperCase(),
  'attributes': {
    for (final a in node.attributes.entries) a.key.toString(): a.value,
  },
  'path': path,
  'children': [
    for (var i = 0; i < node.children.length; i++)
      _tree(node.children[i], [...path, i]),
  ],
};
final _cache = <String, Future<Map<String, Object?>>>{};
Future<Map<String, Object?>> _actual(
  String component,
  String variant,
  String theme,
) => _cache.putIfAbsent('$component/$variant/$theme', () async {
  final probes = [
    rootProbeSpec(
      key: '$component-$variant-$theme-defaultStyle',
      flutterClassName: 'source-only',
      boxObservationSource: _source(component),
    ),
  ];
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': probes.map((p) => p.toJson()).toList(),
  });
  final recorder = DataOverlaySsrSource.forEntry(entry)!;
  Map<String, Object?>? witness;
  final rendered = await renderComponentBodyHtml(
    coui.CoUIWeb(theme: .coui, child: _CurrentCapture(entry, recorder)),
    onMountedRoot: (root) => witness = recorder.observe(root),
  );
  expect(witness?['kind'], 'canonical-ssr-data-overlay-v1');
  expect(witness?['entryKey'], entry.key);
  final document = html.parseFragment(rendered);
  final capture = document.querySelectorAll('[data-parity-key]').single;
  expect(
    document.querySelectorAll(probes.single.webSelector).single,
    same(capture.children.single),
  );
  return {..._tree(capture, []), 'currentRaw': witness!['currentRaw']};
});
Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  BoxObservationSourceSpec source, {
  String mutation = '',
  bool omitRaw = false,
}) async {
  final program =
      '''
$_runtime
const capture=node(${jsonEncode(tree)}),root=capture.children[0];
const source=${jsonEncode(source.toJson())};
const currentRaw=${jsonEncode(tree['currentRaw'])};
const resolve=($dataOverlayLayoutBoxSourceResolverScript);
global.getComputedStyle=()=>{throw Error('CSS source selection forbidden');};
global.document=new Proxy({},{get(){throw Error('Global search forbidden');}});
$mutation
const result=resolve(root,source${omitRaw ? '' : ',currentRaw'});
console.log(JSON.stringify(result.error?result:{registry:result.registryResultElement.path,
 field:result.fieldUnitElement.path,padding:result.paddingSource.path,frame:result.frameSource.path,
 foreign:result.foreignSeats.map(n=>n.path),outside:result.outsideTriggerSlots,
 current:result.currentOperationWitness,hasValue:Object.hasOwn(result,'value')}));
''';
  final result = await Process.run('node', ['-e', program]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return (jsonDecode(result.stdout.toString()) as Map).cast<String, Object?>();
}

void main() {
  for (final recipe in _recipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme actual SSR source',
        () async {
          final actual = await _actual(recipe.component, recipe.variant, theme);
          final result = await _resolve(actual, _source(recipe.component));
          expect(result['error'], isNull);
          expect(result['registry'], [0]);
          final field = recipe.component == 'swiper' ? [0, 0] : [0];
          for (final key in ['field', 'padding', 'frame']) {
            expect(result[key], field);
          }
          expect(result['hasValue'], false);
          final foreign = result['foreign']! as List;
          final expected = switch ((recipe.component, recipe.variant)) {
            ('bottom-sheet', 'default') => 4,
            ('bottom-sheet', 'close') => 2,
            ('swiper', _) => 1,
            ('diff', 'default') => 4,
            ('diff', 'text') => 2,
            _ => 0,
          };
          expect(foreign, hasLength(expected));
          expect(
            result['outside'],
            recipe.component == 'swiper' ? hasLength(1) : isEmpty,
          );
        },
      );
    }
    test(
      '${recipe.component}/${recipe.variant} CSS/key values cannot choose field',
      () async {
        final actual = await _actual(recipe.component, recipe.variant, 'light');
        final before = await _resolve(actual, _source(recipe.component));
        final after = await _resolve(
          actual,
          _source(recipe.component),
          mutation: '''
capture.attributes['data-parity-key']='arbitrary-id-future-style';
const initial=resolve(root,source,currentRaw);if(initial.error)throw Error(initial.error);
initial.fieldUnitElement.attributes.style='padding:23px 17px 11px 5px;border-width:7px';
''',
        );
        expect(after, before);
      },
    );
    for (final style in ['neoBrutalism', 'neumorphism', 'futureSurface']) {
      test(
        '${recipe.component}/${recipe.variant}/$style keeps source operation',
        () async {
          final actual = await _actual(
            recipe.component,
            recipe.variant,
            'light',
          );
          final before = await _resolve(actual, _source(recipe.component));
          final after = await _resolve(
            actual,
            _source(recipe.component),
            mutation:
                "capture.attributes['data-parity-key']="
                "'future-canonical-$style';",
          );
          expect(after, before);
        },
      );
    }
    test(
      '${recipe.component}/${recipe.variant} requires actual raw witness',
      () async {
        final actual = await _actual(recipe.component, recipe.variant, 'light');
        expect(
          (await _resolve(
            actual,
            _source(recipe.component),
            omitRaw: true,
          ))['error'],
          isNotNull,
        );
      },
    );
    for (final mutation in [
      'delete currentRaw.kind;',
      'currentRaw.rawSlotCount++;',
      'currentRaw.slotPresence.push(true);',
      'currentRaw.extra="unproved";',
    ]) {
      test(
        '${recipe.component}/${recipe.variant} rejects raw $mutation',
        () async {
          final actual = await _actual(
            recipe.component,
            recipe.variant,
            'light',
          );
          expect(
            (await _resolve(
              actual,
              _source(recipe.component),
              mutation: mutation,
            ))['error'],
            isNotNull,
          );
        },
      );
    }
    for (final mutation in [
      'source.schemaVersion=99;',
      'source.quantityId="unknown";',
      'source.nativeAdapterId="unknown";',
      'source.webAdapterId="unknown";',
      'source.extra="unknown";',
      'root.parentElement=null;',
      'root.isConnected=false;',
      'capture._list.push(root);',
      "delete capture.attributes['data-parity-key'];",
      'root.tagName="SECTION";',
      'root._list=[];',
      'root._list.push(root._list[0]);',
    ]) {
      test('${recipe.component}/${recipe.variant} rejects $mutation', () async {
        final actual = await _actual(recipe.component, recipe.variant, 'light');
        expect(
          (await _resolve(
            actual,
            _source(recipe.component),
            mutation: mutation,
          ))['error'],
          isNotNull,
        );
      });
    }
    test(
      '${recipe.component}/${recipe.variant} whole foreign subtree remains opaque',
      () async {
        final actual = await _actual(recipe.component, recipe.variant, 'light');
        final before = await _resolve(actual, _source(recipe.component));
        final after = await _resolve(
          actual,
          _source(recipe.component),
          mutation: '''
const first=resolve(root,source,currentRaw);if(first.error)throw Error(first.error);
for(const boundary of first.foreignSeats){
 // These seats include source-owned forwarding wrappers. Preserve their
 // authored arity and mutate the supplied opaque subtree beneath them.
 let foreign=boundary;
 if(source.logicalUnitId==='swiper-generated-trigger-layout-host'){
  foreign=boundary._list[0];
 }
 if(source.logicalUnitId==='diff-generated-viewer-layout-host'){
  foreign=boundary._list[0]; // before/after layer or generated label Badge
  if(foreign?.tagName==='SPAN'){
   const label=foreign._list.filter(n=>n.tagName!=='STYLE');
   if(label.length!==1 || label[0].tagName!=='SPAN' || label[0]._list.length!==1)
    throw Error('Expected canonical Badge label forwarding path');
   foreign=label[0]._list[0]; // original supplied Text component root
  }
 }
 if(!foreign || !boundary.contains(foreign))throw Error('Missing supplied subtree');
 foreign.attributes.style='padding:999px;border-width:31px';
 foreign._list.push(node({tagName:'DIV',attributes:{class:'relative w-full flex flex-col'},
   path:[999],children:[]},foreign));
}
''',
        );
        expect(after, before);
      },
    );
  }

  test(
    'BottomSheet consumes the actual decorative empty DIV divider',
    () async {
      final actual = await _actual('bottom-sheet', 'close', 'light');
      final result = await _resolve(actual, _source('bottom-sheet'));
      expect(result['error'], isNull);
      expect((result['current']! as Map)['divider'], true);
      final wrongTag = await _resolve(
        actual,
        _source('bottom-sheet'),
        mutation: "root._list[1].tagName='HR';",
      );
      expect(wrongTag['error'], isNotNull);
    },
  );

  test(
    'Swiper preserves current emitted attribute '
    'without inventing initial false',
    () async {
      final actual = await _actual('swiper', 'default', 'light');
      final before = await _resolve(actual, _source('swiper'));
      expect((before['current']! as Map)['expandedAttribute'], isNull);
      final after = await _resolve(
        actual,
        _source('swiper'),
        mutation: "root._list[0].attributes['aria-expanded']='true';",
      );
      expect((after['current']! as Map)['expandedAttribute'], 'true');
      for (final key in [
        'registry',
        'field',
        'padding',
        'frame',
        'foreign',
        'outside',
      ]) {
        expect(after[key], before[key]);
      }
      final unknown = await _resolve(
        actual,
        _source('swiper'),
        mutation: "root._list[0].attributes['aria-expanded']='unknown';",
      );
      expect(unknown['error'], isNotNull);
    },
  );
  test('Swiper requires source width wrapper rather than a key hint', () async {
    final actual = await _actual('swiper', 'sheet', 'light');
    final result = await _resolve(
      actual,
      _source('swiper'),
      mutation: "root.attributes.class='relative';",
    );
    expect(result['error'], isNotNull);
  });
  test(
    'Diff current interactive operation requires its actual handle/value seats',
    () async {
      final actual = await _actual('diff', 'default', 'light');
      for (final mutation in [
        'root._list.pop();',
        "delete root.attributes['aria-valuenow'];",
      ]) {
        expect(
          (await _resolve(
            actual,
            _source('diff'),
            mutation: mutation,
          ))['error'],
          isNotNull,
        );
      }
    },
  );
  test('old codeDiff tuple cannot borrow the current viewer path', () async {
    final actual = await _actual('diff', 'default', 'light');
    expect(
      (await _resolve(actual, BoxObservationSourceSpec.codeDiffFrame))['error'],
      isNotNull,
    );
  });
  test(
    'Theme current selection witness changes without selecting a new owner',
    () async {
      final actual = await _actual('theme-controller', 'default', 'light');
      final before = await _resolve(actual, _source('theme-controller'));
      final after = await _resolve(
        actual,
        _source('theme-controller'),
        mutation: '''
const options=root._list.filter(n=>n.tagName!=='STYLE');
options.forEach((n,i)=>n._list[0].attributes['aria-pressed']=i===1?'true':'false');
''',
      );
      expect(after['error'], isNull);
      expect(after['field'], before['field']);
      expect(after['current'], isNot(before['current']));
    },
  );
  for (final recipe in [
    (
      component: 'bottom-sheet',
      variant: 'close',
      mutation: 'currentRaw.showDivider=false;',
    ),
    (
      component: 'swiper',
      variant: 'sheet',
      mutation: 'currentRaw.variant="drawer";',
    ),
    (
      component: 'diff',
      variant: 'default',
      mutation: 'currentRaw.interactive=false;',
    ),
  ]) {
    test('${recipe.component} rejects raw/DOM branch mismatch', () async {
      final actual = await _actual(recipe.component, recipe.variant, 'light');
      expect(
        (await _resolve(
          actual,
          _source(recipe.component),
          mutation: recipe.mutation,
        ))['error'],
        isNotNull,
      );
    });
  }
}

class _CurrentCapture extends StatelessComponent {
  const _CurrentCapture(this.entry, this.recorder);

  final MatrixEntry entry;
  final DataOverlaySsrSource recorder;

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
