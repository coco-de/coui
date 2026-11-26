import 'dart:convert';
import 'dart:io';
import 'package:coui_web/coui_web.dart' as coui;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';
import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_navigation_trigger_units_probe.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/web_capture_backend.dart';

const _htmlNamespace = 'http://www.w3.org/1999/xhtml';

const _recipes = <({String component, String variant})>[
  (component: 'command-search', variant: 'default'),
  (component: 'navigation-bar', variant: 'default'),
  (component: 'navigation-bar', variant: 'rail'),
  (component: 'navigation-bar', variant: 'sidebar'),
  (component: 'dock', variant: 'default'),
];
BoxObservationSourceSpec _source(String c) => switch (c) {
  'command-search' => BoxObservationSourceSpec.commandSearchTriggerContentInset,
  'navigation-bar' => BoxObservationSourceSpec.navigationBarItemsContentInset,
  'dock' => BoxObservationSourceSpec.dockBarContentInset,
  _ => throw StateError(c),
};
Map<String, Object?> _tree(dom.Element e, List<int> path) => {
  // Native HTML DOM uppercases tagName only in the HTML namespace.
  'tagName': e.namespaceUri == _htmlNamespace
      ? e.localName!.toUpperCase()
      : e.localName,
  'namespaceURI': e.namespaceUri,
  'localName': e.localName,
  'attributes': {
    for (final a in e.attributes.entries) a.key.toString(): a.value,
  },
  'textContent': e.text,
  'path': path,
  'children': [
    for (var i = 0; i < e.children.length; i++)
      _tree(e.children[i], [...path, i]),
  ],
};
Future<Map<String, Object?>> _actual(
  String component,
  String variant,
  String theme,
) async {
  final probes = captureProbes(
    key: '$component-$variant-$theme-defaultStyle',
    component: component,
    variant: variant,
    flutterClassName: 'sanity-only',
  );
  final entry = MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': probes.map((p) => p.toJson()).toList(),
  });
  final fragment = html.parseFragment(await renderCaptureBodyHtml(entry));
  final capture = fragment.querySelectorAll('[data-parity-key]').single;
  final root = fragment
      .querySelectorAll(probes.singleWhere((p) => p.role == 'root').webSelector)
      .single;
  expect(root, same(capture.children.single));
  return _tree(capture, []);
}

const _runtime = r'''
const node=(data,parent=null)=>{
 const attrs={...data.attributes},classes=(attrs.class??'').split(/\s+/).filter(Boolean);
 const e={tagName:data.tagName,namespaceURI:data.namespaceURI,
  localName:data.localName,path:data.path,attributes:attrs,parentElement:parent,
  textContent:data.textContent??'',isConnected:true,
  getAttribute:n=>attrs[n]??null,hasAttribute:n=>Object.hasOwn(attrs,n),
  classList:{contains:n=>classes.includes(n),[Symbol.iterator]:function*(){yield*classes;}}};
 e._list=data.children.map(c=>node(c,e));
 Object.defineProperty(e,'children',{get:()=>e._list});
 e.contains=other=>e===other || e._list.some(c=>c.contains(other));
 for(const n of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
  Object.defineProperty(e,n,{get(){throw Error('Numeric owner selection forbidden');}});
 return e;
};
global.document=new Proxy({},{get(){throw Error('Global owner search forbidden');}});
global.getComputedStyle=()=>{throw Error('CSS owner selection forbidden');};
''';
Map<String, Object?> _fixtureRaw(String component, String variant) {
  // Independent expected roster from exact current canonical example sources;
  // production must supply an actual executed producer witness, never this map.
  final result = <String, Object?>{
    'schema': 'navigation-trigger-current-raw-v1',
    'source': _source(component).toJson(),
  };
  if (component == 'command-search') {
    result.addAll({'leadingSupplied': false, 'shortcutSupplied': true});
  } else if (component == 'navigation-bar') {
    result.addAll({
      'headerSupplied': false,
      'vertical': variant != 'default',
      'sidebar': variant == 'sidebar',
      'footerSupplied': variant == 'sidebar',
      'items': [
        for (final kind
            in variant == 'sidebar'
                ? ['label', 'item', 'item', 'divider', 'label', 'item', 'item']
                : ['item', 'item', 'item', 'item'])
          {'kind': kind},
      ],
    });
  } else {
    result['items'] = [
      for (var i = 0; i < 3; i++)
        {'interactive': true, 'labelSupplied': true, 'active': i == 0},
    ];
  }
  return result;
}

Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  String component, {
  String mutation = '',
  Map<String, Object?>? raw,
  String variant = 'default',
}) async {
  final program =
      '''
$_runtime
const capture=node(${jsonEncode(tree)}),root=capture.children[0];
const source=${jsonEncode(_source(component).toJson())};
const resolve=($navigationTriggerBoxSourceResolverScript);
$mutation
const currentRaw=${jsonEncode(raw ?? _fixtureRaw(component, variant))};
const r=resolve(root,source,currentRaw);
console.log(JSON.stringify(r.error?r:{registry:r.registryResultElement.path,
 field:r.fieldUnitElement.path,padding:r.paddingSource.path,frame:r.frameSource.path,
 foreign:r.foreignSeats.map(n=>n.path),hasValue:Object.hasOwn(r,'value')}));
''';
  final r = await Process.run('node', ['-e', program]);
  expect(r.exitCode, 0, reason: r.stderr.toString());
  return (jsonDecode(r.stdout.toString()) as Map).cast<String, Object?>();
}

coui.Component _foreign(String marker) => coui.div([
  coui.Text(marker),
], styles: const coui.Styles(raw: {'padding': '71px 83px 97px 113px'}));
Future<Map<String, Object?>> _custom(coui.Component producer) async {
  final document = await renderComponentToDocumentHtml(
    coui.CoUIWeb(
      theme: coui.ThemeData.coui,
      child: coui.div(
        [producer],
        attributes: const {'data-parity-key': 'custom-source-fixture'},
      ),
    ),
  );
  return _tree(html.parse(document).querySelector('[data-parity-key]')!, []);
}

class _UnknownCommand extends coui.CommandSearch {
  const _UnknownCommand() : super();
}

void main() {
  test(
    'SSR fixture preserves generated SVG namespace and native tag case',
    () async {
      final tree = await _actual('command-search', 'default', 'light');
      final registry =
          (tree['children']! as List).single as Map<String, Object?>;
      final field =
          (registry['children']! as List).single as Map<String, Object?>;
      final seats = (field['children']! as List)
          .cast<Map<String, Object?>>()
          .where((node) => node['tagName'] != 'STYLE')
          .toList();
      final icon = seats[1];
      expect(icon['namespaceURI'], 'http://www.w3.org/2000/svg');
      expect(icon['localName'], 'svg');
      expect(icon['tagName'], 'svg');
      expect(registry['namespaceURI'], _htmlNamespace);
      expect(registry['localName'], 'div');
      expect(registry['tagName'], 'DIV');
      final result = await _resolve(tree, 'command-search');
      expect(result.containsKey('error'), false, reason: result.toString());
      expect(result['registry'], [0]);
      expect(result['field'], [0, 0]);
      expect(result['padding'], result['field']);
      expect(result['frame'], result['field']);
    },
  );
  for (final damage in [
    'html-svg',
    'missing-namespace',
    'wrong-svg-local-name',
    'uppercase-svg-tag',
    'svg-iconify',
    'wrong-iconify-local-name',
    'missing-iconify-namespace',
  ]) {
    test('generated Icon rejects mismatched DOM identity $damage', () async {
      final tree = await _actual('command-search', 'default', 'light');
      final mutation = switch (damage) {
        'html-svg' =>
          "icon.namespaceURI='http://www.w3.org/1999/xhtml';"
              "icon.localName='svg';icon.tagName='SVG';",
        'missing-namespace' => 'delete icon.namespaceURI;',
        'wrong-svg-local-name' => "icon.localName='path';",
        'uppercase-svg-tag' => "icon.tagName='SVG';",
        'svg-iconify' =>
          "icon.localName='iconify-icon';icon.tagName='ICONIFY-ICON';",
        'wrong-iconify-local-name' =>
          "icon.namespaceURI='http://www.w3.org/1999/xhtml';"
              "icon.localName='other-icon';icon.tagName='ICONIFY-ICON';",
        'missing-iconify-namespace' =>
          "delete icon.namespaceURI;icon.localName='iconify-icon'; "
              "icon.tagName='ICONIFY-ICON';",
        _ => throw StateError(damage),
      };
      final result = await _resolve(
        tree,
        'command-search',
        mutation:
            '''
const field=root._list[0];
const seats=field._list.filter(node=>node.tagName!=='STYLE');
const icon=seats[1];
$mutation
''',
      );
      expect(result['error'], 'COMMAND_SEARCH_GENERATED_ICON_CHANGED');
    });
  }
  for (final recipe in _recipes) {
    for (final theme in ['light', 'dark']) {
      test('actual SSR ${recipe.component}/${recipe.variant}/$theme', () async {
        final tree = await _actual(recipe.component, recipe.variant, theme);
        final r = await _resolve(
          tree,
          recipe.component,
          variant: recipe.variant,
        );
        expect(r.containsKey('error'), isFalse, reason: r.toString());
        expect(r['registry'], [0]);
        expect(r['field'], recipe.component == 'command-search' ? [0, 0] : [0]);
        expect(r['padding'], r['field']);
        expect(r['frame'], r['field']);
        expect(r['hasValue'], false);
      });
      test(
        'foreign CSS never selects ${recipe.component}/${recipe.variant}/$theme',
        () async {
          final tree = await _actual(recipe.component, recipe.variant, theme);
          final first = await _resolve(
            tree,
            recipe.component,
            variant: recipe.variant,
          );
          expect(first.containsKey('error'), false, reason: first.toString());
          final second = await _resolve(
            tree,
            recipe.component,
            variant: recipe.variant,
            mutation: '''
const poison=n=>{n.attributes.style='padding:999px 2px 888px 3px';
 n._list.forEach(poison);};poison(root);
''',
          );
          expect(second, first);
        },
      );
      test(
        'unknown own extra seat holds ${recipe.component}/${recipe.variant}/$theme',
        () async {
          final tree = await _actual(recipe.component, recipe.variant, theme);
          final r = await _resolve(
            tree,
            recipe.component,
            variant: recipe.variant,
            mutation: '''
const field=source.logicalUnitId.startsWith('command-search-')?root._list[0]:root;
const fake=node({tagName:'SECTION',attributes:{},path:[99],children:[]},field);
field._list.push(fake);
''',
          );
          expect(r.containsKey('error'), true);
        },
      );
    }
  }
  for (final suffix in [false, true]) {
    test(
      'public trigger preserves complete own/foreign seats $suffix',
      () async {
        final producer = coui.CommandSearch(
          leading: _foreign('leading'),
          shortcut: suffix ? _foreign('shortcut') : null,
          commandSearchStyle: const coui.CoreCommandSearchStyle(
            padding: coui.CoreEdgeInsets.fromLTRB(3, 5, 7, 11),
          ),
        );
        final b = bindNavigationTriggerWebRawSource(
          producer: producer,
          source: BoxObservationSourceSpec.commandSearchTriggerContentInset,
        )..validateExistingCurrentBinding();
        expect(b.rawSlots.length, 2);
        final r = await _resolve(
          await _custom(producer),
          'command-search',
          raw: b.currentDomContract,
        );
        expect(r.containsKey('error'), false);
        expect(r['field'], [0]);
        expect((r['foreign']! as List).length, suffix ? 2 : 1);
      },
    );
  }
  for (final variant in ['default', 'rail']) {
    for (final damage in ['selection-id', 'missing-lens', 'duplicate-style']) {
      test('actual own Nav layers reject $variant/$damage', () async {
        final tree = await _actual('navigation-bar', variant, 'light');
        final mutation = switch (damage) {
          'selection-id' =>
            '''
const selection=root._list.find(
 n=>n.classList.contains('coui-navigation-selection'));
selection.attributes.id='foreign-selection';
''',
          'missing-lens' => 'root._list.pop();',
          _ => 'root._list.splice(1,0,root._list[0]);',
        };
        final r = await _resolve(
          tree,
          'navigation-bar',
          variant: variant,
          mutation: mutation,
        );
        expect(r.containsKey('error'), true);
      });
    }
  }
  test('raw navigation preserves all item kinds/header/footer order', () {
    final icon = _foreign('icon');
    final badge = _foreign('badge');
    final header = _foreign('header');
    final footer = _foreign('footer');
    final producer = coui.NavigationBar(
      items: [
        const coui.CoreNavigationBarItem<coui.Component>.label('section'),
        coui.CoreNavigationBarItem<coui.Component>.destination(
          icon: icon,
          badge: badge,
          label: 'one',
        ),
        const coui.CoreNavigationBarItem<coui.Component>.divider(),
      ],
      header: header,
      footer: footer,
    );
    final b = bindNavigationTriggerWebRawSource(
      producer: producer,
      source: BoxObservationSourceSpec.navigationBarItemsContentInset,
    );
    expect(b.rawSlots, [null, null, icon, badge, null, null, header, footer]);
    b.validateExistingCurrentBinding();
  });
  for (final c in ['command-search', 'navigation-bar', 'dock']) {
    test('raw duplicate rejection happens before branch omissions $c', () {
      final shared = _foreign('shared');
      final coui.Component p = switch (c) {
        'command-search' => coui.CommandSearch(
          leading: shared,
          shortcut: shared,
        ),
        'navigation-bar' => coui.NavigationBar(
          header: shared,
          items: [
            coui.CoreNavigationBarItem<coui.Component>.destination(
              icon: shared,
            ),
          ],
        ),
        _ => coui.Dock(
          items: [
            coui.CoreDockItemData<coui.Component>(icon: shared),
            coui.CoreDockItemData<coui.Component>(icon: shared),
          ],
        ),
      };
      expect(
        () =>
            bindNavigationTriggerWebRawSource(producer: p, source: _source(c)),
        throwsStateError,
      );
    });
  }
  test('missing current raw witness holds before DOM owner binding', () async {
    final tree = await _actual('dock', 'default', 'light');
    final r = await _resolve(
      tree,
      'dock',
      mutation: 'const originalResolve=resolve;',
    );
    expect(r.containsKey('error'), false);
    final absent = await _resolve(tree, 'dock', raw: const {});
    expect(absent['error'], 'NAVIGATION_TRIGGER_CURRENT_RAW_WITNESS_REQUIRED');
  });
  test('raw producer subclasses and changed tuple fail closed', () {
    expect(
      () => bindNavigationTriggerWebRawSource(
        producer: const _UnknownCommand(),
        source: BoxObservationSourceSpec.commandSearchTriggerContentInset,
      ),
      throwsStateError,
    );
    expect(
      () => bindNavigationTriggerWebRawSource(
        producer: const coui.CommandSearch(),
        source: BoxObservationSourceSpec.dockBarContentInset,
      ),
      throwsStateError,
    );
  });
  test('held public Dock raw witness rejects mutable list reordering', () {
    final items = [
      coui.CoreDockItemData<coui.Component>(icon: _foreign('a')),
      coui.CoreDockItemData<coui.Component>(icon: _foreign('b')),
    ];
    final producer = coui.Dock(items: items);
    final b = bindNavigationTriggerWebRawSource(
      producer: producer,
      source: BoxObservationSourceSpec.dockBarContentInset,
    );
    final first = items.removeAt(0);
    items.add(first);
    expect(b.validateExistingCurrentBinding, throwsStateError);
  });
}
