import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/text/text_modifiers_example.dart';
import 'package:docs_core/previews/examples/web/text/text_rich_example.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;
import 'package:jaspr_test/jaspr_test.dart' show TestComponentsBinding;
import 'package:test/test.dart';

import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/ssr_source_identity.dart';
import '../../src/web/text_showcase_ssr_source.dart';

const _kVariants = [
  'typography-display',
  'typography-headline',
  'typography-title',
  'typography-body',
  'typography-weight',
  'typography-primitive',
  'colors-brand',
  'colors-status',
  'colors-surface',
  'modifiers',
  'wrap',
  'keep-all',
  'textstyle',
  'opacity',
  'rich',
];

const _kLifecycleTestName =
    'public unit Theme rebuild keeps Example '
    'but invalidates held outer binding';

MatrixEntry _entry(String variant, {String theme = 'light'}) =>
    MatrixEntry.fromJson({
      'component': 'text',
      'variant': variant,
      'theme': theme,
      'surfaceStyle': 'defaultStyle',
      'tier': 't2',
      'probes': [
        rootProbeSpec(
          key: 'text-$variant-$theme-defaultStyle',
          flutterClassName: 'unregistered-prototype',
        ).toJson(),
      ],
    });

coui.ThemeData _withoutOptionalColorPairs() => coui.ThemeData(
  colorScheme: coui.CoreColorScheme(
    primary: const coui.CoreColor(0xff101010),
    secondary: const coui.CoreColor(0xff202020),
    error: const coui.CoreColor(0xff303030),
    success: const coui.CoreColor(0xff404040),
    warning: const coui.CoreColor(0xff505050),
    info: const coui.CoreColor(0xff606060),
  ),
);

Map<String, Object?> _tree(dom.Node node) {
  if (node is dom.Element) {
    return {
      'nodeType': node.nodeType,
      'namespaceURI': node.namespaceUri,
      'localName': node.localName,
      'attributes': {
        for (final attribute in node.attributes.entries)
          attribute.key.toString(): attribute.value,
      },
      'childNodes': node.nodes.map(_tree).toList(growable: false),
    };
  }
  return {
    'nodeType': node.nodeType,
    'data': node is dom.Text
        ? node.data
        : node is dom.Comment
        ? node.data
        : '',
  };
}

Future<({Map<String, Object?> capture, Map<String, Object?> receipt})> _actual(
  String variant, {
  String theme = 'light',
  coui.ThemeData? innerTheme,
}) async {
  final entry = _entry(variant, theme: theme);
  final source = TextShowcaseSsrSource.prototypeForEntry(entry);
  var builds = 0;
  var observations = 0;
  Map<String, Object?>? receipt;
  final document = await renderComponentToDocumentHtml(
    coui.CoUIWeb(
      theme: .coui,
      child: coui.Theme(
        data: innerTheme ?? coui.ThemeData.coui,
        child: _Capture(entry, source, onBuild: () => builds++),
      ),
    ),
    onMountedRoot: (root) {
      observations++;
      final markup =
          (root as RenderObjectElement).renderObject as MarkupRenderObject;
      final before = markup.renderToHtml();
      receipt = source.observe(root);
      expect(markup.renderToHtml(), before);
      expect(root.binding.rootElement, same(root));
    },
  );
  expect(builds, 1);
  expect(observations, 1);
  final capture = html
      .parse(document)
      .querySelectorAll('[data-parity-key]')
      .single;
  return (
    capture: _tree(capture),
    receipt: {...receipt!, 'harnessURL': 'http://parity.test/current'},
  );
}

const _kRuntime = '''
const node=(data,parent=null)=>{
 if(data.nodeType!==1) return {nodeType:data.nodeType,data:data.data,parentElement:parent,parentNode:parent};
 const attrs={...data.attributes};
 const e={nodeType:1,namespaceURI:data.namespaceURI,localName:data.localName,
  parentElement:parent,parentNode:parent,isConnected:true,
  getAttribute:name=>Object.hasOwn(attrs,name)?attrs[name]:null,
  removeAttribute:name=>{delete attrs[name];e.attributes=e.attributes.filter(a=>a.name!==name);},
  setAttribute:(name,value)=>{attrs[name]=value;e.attributes=e.attributes.filter(a=>a.name!==name);e.attributes.push({name,value});}};
 e.attributes=Object.entries(attrs).map(([name,value])=>({name,value}));
 e.childNodes=data.childNodes.map(child=>node(child,e));
 Object.defineProperty(e,'children',{get:()=>e.childNodes.filter(child=>child.nodeType===1)});
 for(const name of ['offsetWidth','offsetHeight','clientWidth','clientHeight','classList'])
  Object.defineProperty(e,name,{get(){throw Error('Values/classes must not select owner');}});
 return e;
};
global.location={href:'http://parity.test/current'};
global.document=new Proxy({},{get(){throw Error('No global owner search');}});
let cssReads=0;
global.getComputedStyle=owner=>{
 cssReads++;
 if(owner!==root) throw Error('Foreign child cannot supply CSS');
 return {paddingTop:'0px',paddingRight:'7px',paddingBottom:'11px',paddingLeft:'13px'};
};
''';

Future<Map<String, Object?>> _resolve(
  Map<String, Object?> capture,
  Map<String, Object?> receipt, {
  String mutation = '',
}) async {
  final program =
      '''
$_kRuntime
const capture=node(${jsonEncode(capture)}),root=capture.children[0];
const receipt=${jsonEncode(receipt)},source=${jsonEncode(kTextShowcaseSourcePrototype.toJson())};
$mutation
const result=($textShowcasePaddingCssPrototypeScript)(root,source,receipt);
console.log(JSON.stringify({result,cssReads}));
''';
  final result = await Process.run(
    Platform.environment['PARITY_NODE'] ?? 'node',
    ['-e', program],
  );
  expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
}

void main() {
  // The canonical backend's body is shared across the two entry theme axes.
  // These cases prove mounted SSR identity, not hydrated dark palette pixels.
  for (final variant in _kVariants) {
    for (final theme in ['light', 'dark']) {
      test('$variant/$theme original mounted outer declaration', () async {
        final actual = await _actual(variant, theme: theme);
        final receipt = actual.receipt;
        expect(receipt['kind'], 'canonical-ssr-text-showcase-prototype-v1');
        expect(receipt['source'], kTextShowcaseSourcePrototype.toJson());
        expect(receipt['rawOrderFromPublicProducerLists'], true);
        final raw = receipt['currentRaw']! as Map;
        final slots = raw['opaqueSlots']! as List;
        expect(slots.length, raw['rawSlotCount']);
        expect(receipt['completeRawSlotCount'], slots.length);
        expect(raw['slotPresence'], everyElement(true));
        expect(raw.containsKey('value'), false);
        expect(raw.containsKey('expectedPadding'), false);
        expect(raw['actualOwnerMarkup'], startsWith('<div'));
        final resolved = await _resolve(actual.capture, receipt);
        expect(resolved['cssReads'], 1);
        expect((resolved['result']! as Map)['status'], 'prototype-observed');
        expect((resolved['result']! as Map)['ownerIsLayoutRoot'], true);
        // A genuine current zero is retained, rather than used as an absence
        // declaration or replaced by a guessed positive allocation.
        expect((resolved['result']! as Map)['paddingCss'], [
          '0px',
          '7px',
          '11px',
          '13px',
        ]);
      });
    }
  }

  test(
    'actual absent optional colors retain every empty raw frontier',
    () async {
      final actual = await _actual(
        'colors-status',
        innerTheme: _withoutOptionalColorPairs(),
      );
      final raw = actual.receipt['currentRaw']! as Map;
      final slots = raw['opaqueSlots']! as List;
      expect(raw['rawSlotCount'], 5);
      expect(raw['slotPresence'], [true, true, true, true, true]);
      expect(
        slots.skip(1).map((slot) => (slot as Map)['nodes']),
        everyElement(isEmpty),
      );
      final result = await _resolve(actual.capture, actual.receipt);
      expect(result['cssReads'], 1);
    },
  );

  test('declared empty Fragment cannot hide newly injected output', () async {
    final entry = _entry('colors-status');
    final source = TextShowcaseSsrSource.prototypeForEntry(entry);
    div? capture;
    await renderComponentBodyHtml(
      coui.CoUIWeb(
        theme: .coui,
        child: coui.Theme(
          data: _withoutOptionalColorPairs(),
          child: _Capture(entry, source, onCapture: (value) => capture = value),
        ),
      ),
      onMountedRoot: (root) {
        final example = soleCurrentSsrChild(
          currentSsrGeneratedDiv(
            currentSsrIdentityElement(root, capture!),
            capture!,
          ),
        );
        final returned = soleCurrentSsrChild(example);
        final declared = returned.component as div;
        expect(declared.children[1], same(declared.children[2]));
        final owner = currentSsrGeneratedDiv(returned, declared);
        final children = <Element>[];
        owner.visitChildren(children.add);
        expect(children[1], isNot(same(children[2])));
        final empty = _frontier(children[1]).single;
        expect(empty, isA<MarkupRenderFragment>());
        expect(empty.children, isEmpty);
        expect(source.observe(root)['completeRawSlotCount'], 5);
        final injected = empty.createChildRenderText('not empty\u00a0');
        empty.attach(injected);
        try {
          expect(() => source.observe(root), throwsStateError);
        } finally {
          empty.remove(injected);
        }
        expect(source.observe(root)['completeRawSlotCount'], 5);
      },
    );
  });

  test(
    _kLifecycleTestName,
    () async {
      final entry = _entry('rich');
      const registry = TextRichExample();
      final capture = div(
        const [registry],
        attributes: {'data-parity-key': entry.key},
      );
      final held = TextShowcaseSsrSource.prototypeForEntry(entry)
        ..recordBuild(registry, capture);
      late void Function(coui.ThemeData) setTheme;
      // The production SSR binding intentionally supports no later frames.
      // This is a public component-test lifecycle with the public server
      // renderer, not a claim that an SSR response can rebuild its Theme.
      final binding = _MarkupLifecycleBinding();
      try {
        binding.attachRootComponent(
          _ThemeSwitch(
            capture: capture,
            onReady: (update) => setTheme = update,
          ),
        );
        await pumpEventQueue();
        final root = binding.rootElement!;
        final example = currentSsrIdentityElement(root, registry);
        final rootMarkup = root.renderObject as MarkupRenderObject;
        final before = rootMarkup.renderToHtml();
        held.observe(root);
        try {
          setTheme(coui.ThemeData.coui.copyWith(textScaling: 1.25));
          await pumpEventQueue();
          expect(currentSsrIdentityElement(root, registry), same(example));
          expect(() => held.observe(root), throwsStateError);
          final fresh = TextShowcaseSsrSource.prototypeForEntry(entry)
            ..recordBuild(registry, capture);
          expect(fresh.observe(root)['entryKey'], entry.key);
        } finally {
          setTheme(coui.ThemeData.coui);
          await pumpEventQueue();
        }
        expect(rootMarkup.renderToHtml(), before);
        // Restoration does not resurrect an older declaration identity.
        expect(() => held.observe(root), throwsStateError);
      } finally {
        binding.detachRootComponent();
        await pumpEventQueue();
      }
    },
  );

  for (final text in ['anonymous', '\u00a0']) {
    for (final atCapture in [false, true]) {
      test('actual undeclared $text at capture=$atCapture rejects', () async {
        final entry = _entry('modifiers');
        final source = TextShowcaseSsrSource.prototypeForEntry(entry);
        div? capture;
        await renderComponentBodyHtml(
          coui.CoUIWeb(
            theme: .coui,
            child: _Capture(
              entry,
              source,
              onCapture: (value) => capture = value,
            ),
          ),
          onMountedRoot: (root) {
            final captureDom = currentSsrGeneratedDiv(
              currentSsrIdentityElement(root, capture!),
              capture!,
            );
            final example = soleCurrentSsrChild(captureDom);
            final returned = soleCurrentSsrChild(example);
            final owner = currentSsrGeneratedDiv(
              returned,
              returned.component as div,
            );
            final target =
                (atCapture ? captureDom : owner) as RenderObjectElement;
            final markup = target.renderObject as MarkupRenderObject;
            final before = markup.renderToHtml();
            source.observe(root);
            final injected = markup.createChildRenderText(text);
            markup.attach(injected, after: markup.children.last);
            try {
              expect(() => source.observe(root), throwsStateError);
            } finally {
              markup.remove(injected);
            }
            expect(markup.renderToHtml(), before);
            expect(source.observe(root)['entryKey'], entry.key);
          },
        );
      });
    }
  }

  test('whole foreign subtree content is opaque', () async {
    final entry = _entry('modifiers');
    final source = TextShowcaseSsrSource.prototypeForEntry(entry);
    div? capture;
    await renderComponentBodyHtml(
      coui.CoUIWeb(
        theme: .coui,
        child: _Capture(entry, source, onCapture: (value) => capture = value),
      ),
      onMountedRoot: (root) {
        final example = soleCurrentSsrChild(
          currentSsrGeneratedDiv(
            currentSsrIdentityElement(root, capture!),
            capture!,
          ),
        );
        final returned = soleCurrentSsrChild(example);
        final owner = currentSsrGeneratedDiv(
          returned,
          returned.component as div,
        );
        final foreign = <Element>[];
        owner.visitChildren(foreign.add);
        final boundary = _frontier(foreign.first).single;
        final before = boundary.renderToHtml();
        final injected = boundary.createChildRenderText('opaque\u00a0text');
        boundary.attach(injected, after: boundary.children.last);
        try {
          final receipt = source.observe(root);
          expect(receipt['completeRawSlotCount'], foreign.length);
        } finally {
          boundary.remove(injected);
        }
        expect(boundary.renderToHtml(), before);
      },
    );
  });

  test('duplicate raw declarations are rejected before omission', () async {
    final entry = _entry('modifiers');
    final source = TextShowcaseSsrSource.prototypeForEntry(entry);
    div? capture;
    await renderComponentBodyHtml(
      coui.CoUIWeb(
        theme: .coui,
        child: _Capture(entry, source, onCapture: (value) => capture = value),
      ),
      onMountedRoot: (root) {
        final example = soleCurrentSsrChild(
          currentSsrGeneratedDiv(
            currentSsrIdentityElement(root, capture!),
            capture!,
          ),
        );
        final declaration = soleCurrentSsrChild(example).component as div;
        final original = declaration.children[1];
        declaration.children[1] = declaration.children.first;
        try {
          expect(() => source.observe(root), throwsStateError);
        } finally {
          declaration.children[1] = original;
        }
        expect(source.observe(root)['completeRawSlotCount'], greaterThan(1));
      },
    );
  });

  for (final scenario in ['wrong-example', 'wrong-key', 'detached']) {
    test('$scenario has no original capture authority', () async {
      final entry = _entry('wrap');
      final source = TextShowcaseSsrSource.prototypeForEntry(entry);
      await expectLater(
        renderComponentBodyHtml(
          coui.CoUIWeb(
            theme: .coui,
            child: _Capture(entry, source, scenario: scenario),
          ),
          onMountedRoot: source.observe,
        ),
        throwsStateError,
      );
    });
  }

  test('unreviewed recipes cannot obtain a recorder', () {
    expect(
      () => TextShowcaseSsrSource.prototypeForEntry(_entry('default')),
      throwsStateError,
    );
    final entry = _entry('wrap');
    final source = TextShowcaseSsrSource.prototypeForEntry(entry);
    const original = TextModifiersExample();
    const capture = div([original]);
    source.recordBuild(original, capture);
    expect(() => source.recordBuild(original, capture), throwsStateError);
  });

  final mutations = <String, String>{
    'missing receipt': 'receipt.kind="missing";',
    'wrong URL': 'receipt.harnessURL="http://parity.test/other";',
    'foreign source tuple': 'receipt.source.logicalUnitId="text-glyph";',
    'wrong original key': 'receipt.entryKey="foreign-key";',
    'null key and missing capture key':
        'receipt.entryKey=null;capture.removeAttribute("data-parity-key");',
    'empty key and empty capture key':
        'receipt.entryKey="";capture.setAttribute("data-parity-key","");',
    'absent key and missing capture key':
        'delete receipt.entryKey;capture.removeAttribute("data-parity-key");',
    'incomplete original slot list': 'receipt.completeRawSlotCount++;',
    'unproven raw slot': 'receipt.currentRaw.slotPresence[0]=false;',
    'extra owner text': 'root.childNodes.push({nodeType:3,data:"outside"});',
    'extra owner NBSP': 'root.childNodes.push({nodeType:3,data:"\u00a0"});',
    'extra capture NBSP':
        'capture.childNodes.push({nodeType:3,data:"\u00a0"});',
    'duplicate physical root': 'capture.childNodes.push(root);',
    'wrong namespace': 'root.namespaceURI="http://www.w3.org/2000/svg";',
    'changed owner attributes':
        'root.attributes.push({name:"foreign",value:"x"});',
    'wrong foreign root kind': 'root.children[0].localName="foreign";',
  };
  for (final mutation in mutations.entries) {
    test('${mutation.key} fails before CSS', () async {
      final actual = await _actual('modifiers');
      final result = await _resolve(
        actual.capture,
        actual.receipt,
        mutation: mutation.value,
      );
      expect(result['cssReads'], 0);
      expect((result['result']! as Map)['error'], isNotNull);
    });
  }

  test('foreign inner content does not choose the CSS owner', () async {
    final actual = await _actual('rich');
    final result = await _resolve(
      actual.capture,
      actual.receipt,
      mutation: '''
root.children[0].childNodes.push({nodeType:3,data:'arbitrary foreign text'});
Object.defineProperty(root.children[0],'attributes',{get(){throw Error('Foreign attributes are opaque');}});
''',
    );
    expect(result['cssReads'], 1);
    expect((result['result']! as Map)['ownerIsLayoutRoot'], true);
  });

  test('explicit foreign text and empty slots are retained as such', () async {
    // Authored DOM protocol control, not an additional canonical recipe. It
    // verifies that supplied text is consumed even when it is ASCII whitespace.
    final actual = await _actual('rich');
    final result = await _resolve(
      actual.capture,
      actual.receipt,
      mutation: '''
const raw=receipt.currentRaw;
raw.rawSlotCount=3;raw.slotPresence=[true,true,true];receipt.completeRawSlotCount=3;
raw.opaqueSlots=[{nodes:[]},{nodes:[{nodeType:3}]},{nodes:raw.opaqueSlots[0].nodes}];
root.childNodes.unshift({nodeType:3,data:' ',parentNode:root,parentElement:root});
''',
    );
    expect(result['cssReads'], 1);
  });

  final duringCss = <String, String>{
    'receipt identity':
        'receipt.currentRaw=JSON.parse(JSON.stringify(receipt.currentRaw));',
    'source identity': 'receipt.source={...receipt.source};',
    'source tuple value': 'source.logicalUnitId="foreign";',
    'URL': 'location.href="http://parity.test/other";',
    'owner attributes': 'root.attributes.push({name:"extra",value:"changed"});',
    'capture attributes':
        'capture.attributes.push({name:"extra",value:"changed"});',
    'disconnected root': 'root.isConnected=false;',
    'same-shape foreign replacement':
        'root.childNodes=root.childNodes.map(n=>n.nodeType===1?{...n}:n);',
  };
  for (final mutation in duringCss.entries) {
    test('${mutation.key} changes during CSS read fail closed', () async {
      final actual = await _actual('modifiers');
      final result = await _resolve(
        actual.capture,
        actual.receipt,
        mutation:
            '''
const originalStyle=getComputedStyle;
global.getComputedStyle=owner=>{
 const css=originalStyle(owner);
 Object.defineProperty(css,'paddingLeft',{get(){${mutation.value}return '13px';}});
 return css;
};
''',
      );
      expect(result['cssReads'], 1);
      expect(
        (result['result']! as Map)['error'],
        'TEXT_SHOWCASE_BINDING_CHANGED_DURING_CSS_READ',
      );
    });
  }
}

List<MarkupRenderObject> _frontier(Element element) {
  if (element is RenderObjectElement) {
    return [element.renderObject as MarkupRenderObject];
  }
  final children = <Element>[];
  element.visitChildren(children.add);
  return [for (final child in children) ..._frontier(child)];
}

class _Capture extends StatelessComponent {
  const _Capture(
    this.entry,
    this.source, {
    this.onBuild,
    this.onCapture,
    this.scenario,
  });

  final MatrixEntry entry;
  final TextShowcaseSsrSource source;
  final void Function()? onBuild;
  final void Function(div)? onCapture;
  final String? scenario;

  @override
  Component build(BuildContext context) {
    onBuild?.call();
    final result = kWebPreviewRegistry['text']!(
      context,
      scenario == 'wrong-example' ? 'rich' : entry.variant,
    );
    final capture = div(
      [result],
      attributes: {
        'data-parity-key': scenario == 'wrong-key' ? 'wrong' : entry.key,
      },
    );
    source.recordBuild(result, capture);
    onCapture?.call(capture);
    return scenario == 'detached' ? const div([]) : capture;
  }
}

class _ThemeSwitch extends StatefulComponent {
  const _ThemeSwitch({required this.capture, required this.onReady});
  final div capture;
  final void Function(void Function(coui.ThemeData)) onReady;

  @override
  State<_ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<_ThemeSwitch> {
  coui.ThemeData _theme = coui.ThemeData.coui;

  @override
  void initState() {
    super.initState();
    component.onReady((data) => setState(() => _theme = data));
  }

  @override
  Component build(BuildContext context) =>
      coui.Theme(data: _theme, child: component.capture);
}

/// Retains jaspr_test's normal microtask frame scheduling and BuildOwner.
/// Only the public render-root extension point supplies the actual public
/// Markup tree needed by this collector. Production ServerAppBinding is unused.
class _MarkupLifecycleBinding extends TestComponentsBinding {
  _MarkupLifecycleBinding() : super('/text-showcase-unit', true);

  @override
  RootMarkupRenderObject createRootRenderObject() => RootMarkupRenderObject();
}
