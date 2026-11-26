import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/web_registry.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' show parseFragment;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/framed_collection_ssr_source.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/ssr_source_identity.dart';

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
BoxObservationSourceSpec _source(String component, String variant) {
  if (component == 'join') return BoxObservationSourceSpec.joinStripLayoutHost;
  if (component == 'table') {
    return BoxObservationSourceSpec.tableGridContentInset;
  }
  if (variant == 'app' || variant == 'browser') {
    return BoxObservationSourceSpec.mockupBrowserFrame;
  }
  return BoxObservationSourceSpec.mockupDeviceBodyFrame;
}

MatrixEntry _entry(String component, String variant, String theme) =>
    MatrixEntry.fromJson({
      'component': component,
      'variant': variant,
      'theme': theme,
      'surfaceStyle': 'defaultStyle',
      'tier': 't2',
      'probes': [
        rootProbeSpec(
          key: '$component-$variant-$theme-defaultStyle',
          flutterClassName: 'source-only',
          boxObservationSource: _source(component, variant),
        ).toJson(),
      ],
    });

const _paintFields = [
  'backgroundColor',
  'borderColor',
  'borderWidthPx',
  'borderRadiusPx',
  'boxShadow',
];

List<Element> _paintChildren(Element node) {
  final result = <Element>[];
  node.visitChildren(result.add);
  return result;
}

Iterable<Element> _paintWalk(Element node) sync* {
  yield node;
  for (final child in _paintChildren(node)) {
    yield* _paintWalk(child);
  }
}

List<Element> _paintDomFrontier(Element node) => node.component is DomComponent
    ? [node]
    : [for (final child in _paintChildren(node)) ..._paintDomFrontier(child)];

List<int>? _paintPath(Element node, Element target) {
  if (identical(node, target)) return [];
  final children = [
    for (final child in _paintChildren(node)) ..._paintDomFrontier(child),
  ];
  for (var i = 0; i < children.length; i++) {
    final found = _paintPath(children[i], target);
    if (found != null) return [i, ...found];
  }
  return null;
}

Map<String, Object?> _paintNodeIdentity(html.Element node) => {
  'namespaceURI': node.namespaceUri,
  'localName': node.localName,
  'attributes': {
    for (final entry in node.attributes.entries)
      entry.key.toString(): entry.value,
  },
  'childNodes': [
    for (final child in node.nodes)
      if (child is html.Element)
        _paintNodeIdentity(child)
      else
        {
          'nodeType': child.nodeType,
          'data': child is html.Text
              ? child.data
              : child is html.Comment
              ? child.data
              : '',
        },
  ],
};

Map<String, Object?> _expectedDevicePaint(Element mountedRoot) {
  final producer = _paintWalk(
    mountedRoot,
  ).where((node) => node.component.runtimeType == coui.MockupDevice).single;
  final deviceDom = _paintDomFrontier(producer).single;
  final declared = (deviceDom.component as DomComponent).children!;
  final outlined = declared
      .where((child) => child.runtimeType == coui.OutlinedContainer)
      .single;
  expect((outlined as coui.OutlinedContainer).child, isNull);
  final outlinedElement = _paintChildren(
    deviceDom,
  ).where((node) => identical(node.component, outlined)).single;
  final bodyDom = _paintDomFrontier(outlinedElement).single;
  var registry = deviceDom.parent!;
  while (registry.component is! DomComponent) {
    registry = registry.parent!;
  }
  final render = (bodyDom as RenderObjectElement).renderObject;
  final markup = (render as MarkupRenderObject).renderToHtml();
  final parsed = parseFragment(markup).children.single;
  final ownerPath =
      _paintPath(registry, bodyDom) ?? fail('No current typed body DOM path');
  return {
    'kind': 'mockup-device-body-outlined-paint-v1',
    'paintAuthorityId': 'public-generated-outlined-body-paint-v1',
    'fieldScope': _paintFields,
    'ownerPathFromRegistry': ownerPath,
    'ownerIdentity': _paintNodeIdentity(parsed),
  };
}

void main() {
  for (final (component, variant) in _recipes) {
    for (final theme in ['light', 'dark']) {
      test('$component/$variant/$theme original mounted producer', () async {
        final entry = _entry(component, variant, theme);
        final recorder = FramedCollectionSsrSource.forEntry(entry)!;
        var builds = 0;
        var observations = 0;
        Map<String, Object?>? receipt;
        Map<String, Object?>? expectedPaint;
        await renderComponentToDocumentHtml(
          coui.CoUIWeb(
            theme: .coui,
            child: _Capture(entry, recorder, onBuild: () => builds++),
          ),
          onMountedRoot: (root) {
            observations++;
            final markup =
                (root as RenderObjectElement).renderObject
                    as MarkupRenderObject;
            final before = markup.renderToHtml();
            if (_source(component, variant) ==
                BoxObservationSourceSpec.mockupDeviceBodyFrame) {
              expectedPaint = _expectedDevicePaint(root);
            }
            receipt = recorder.observe(root);
            expect(markup.renderToHtml(), before);
          },
        );
        expect(builds, 1);
        expect(observations, 1);
        expect(receipt!['kind'], 'canonical-ssr-framed-collection-v1');
        expect(receipt!['entryKey'], entry.key);
        expect(receipt!['source'], _source(component, variant).toJson());
        expect(receipt!['rawOrderFromPublicProducerLists'], true);
        final raw = receipt!['currentRaw']! as Map;
        // Paint authority comes from the independently located actual public
        // OutlinedContainer, never the layout host used for padding absence.
        if (expectedPaint != null) {
          expect(raw['bodyPaintSource'], expectedPaint);
        } else {
          expect(raw.containsKey('bodyPaintSource'), isFalse);
        }
        expect(raw['generatedTree'], isA<Map<String, Object?>>());
        final count = component == 'join'
            ? (variant == 'input' ? 2 : 3)
            : component == 'table'
            ? 9
            : 1;
        expect(raw['rawSlotCount'], count);
        expect(raw['slotPresence'], List.filled(count, true));
        expect(receipt!['completeRawSlotCount'], count);
        // Canonical SSR body is shared across entry themes; harness CSS owns
        // palette selection. These assertions verify source identity only.
      });
    }
  }
  test('legacy direct slug retains the existing Browser protocol', () {
    final old = _entry('mockup', 'browser', 'light').toJson();
    old['component'] = 'mockup-browser';
    old['variant'] = 'default';
    expect(
      FramedCollectionSsrSource.forEntry(MatrixEntry.fromJson(old)),
      isNull,
    );
  });
  test('nullable browser child is retained before omission', () {
    final raw = bindFramedCollectionWebRawSource(
      producer: const coui.MockupBrowser(),
      source: BoxObservationSourceSpec.mockupBrowserFrame,
    );
    expect(raw.rawSlots, [null]);
    expect(raw.currentDomContract['slotPresence'], [false]);
  });
  test('recognized wrong source cannot fall through the old browser route', () {
    final forged = _entry('mockup-device', 'default', 'light').toJson();
    forged['component'] = 'mockup-browser';
    expect(
      () => FramedCollectionSsrSource.forEntry(MatrixEntry.fromJson(forged)),
      throwsStateError,
    );
  });
  test('full generic row and cell order is retained', () {
    const a = Component.text('a');
    const b = Component.text('b');
    const c = Component.text('c');
    final raw = bindFramedCollectionWebRawSource(
      producer: const coui.Table(
        rows: [
          coui.CoreTableRowData<Component>.header(
            cells: [coui.CoreTableCellData<Component>(child: a, columnSpan: 2)],
          ),
          coui.CoreTableRowData<Component>.footer(
            cells: [
              coui.CoreTableCellData<Component>(child: b),
              coui.CoreTableCellData<Component>(child: c),
            ],
          ),
        ],
      ),
      source: BoxObservationSourceSpec.tableGridContentInset,
    );
    expect(raw.rawSlots.length, 3);
    expect(raw.rawSlots[0], same(a));
    expect(raw.rawSlots[1], same(b));
    expect(raw.rawSlots[2], same(c));
    final rows = raw.currentDomContract['rows']! as List;
    expect((rows[0] as Map)['kind'], 'header');
    expect((rows[1] as Map)['kind'], 'footer');
    expect(((rows[0] as Map)['cells'] as List).single, {
      'columnSpan': 2,
      'rowSpan': 1,
      'resizers': 0,
    });
  });
  test(
    'duplicate supplied references across rows reject before flattening',
    () {
      const child = Component.text('same');
      for (final producer in <Component>[
        coui.Join(children: const [child, child]),
        const coui.Table(
          rows: [
            coui.CoreTableRowData<Component>(
              cells: [coui.CoreTableCellData<Component>(child: child)],
            ),
            coui.CoreTableRowData<Component>(
              cells: [coui.CoreTableCellData<Component>(child: child)],
            ),
          ],
        ),
      ]) {
        expect(
          () => bindFramedCollectionWebRawSource(
            producer: producer,
            source: producer is coui.Join
                ? BoxObservationSourceSpec.joinStripLayoutHost
                : BoxObservationSourceSpec.tableGridContentInset,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'reason',
              contains('DUPLICATE_RAW'),
            ),
          ),
        );
      }
    },
  );
  test('held raw binding rejects current list replacement', () {
    final children = <Component>[const Component.text('old')];
    final raw = bindFramedCollectionWebRawSource(
      producer: coui.Join(children: children),
      source: BoxObservationSourceSpec.joinStripLayoutHost,
    );
    children[0] = const Component.text('new');
    expect(raw.validateExistingCurrentBinding, throwsStateError);
  });
  test('unknown producer and generic data subclasses are unsupported', () {
    for (final (producer, source) in <(Component, BoxObservationSourceSpec)>[
      (const _UnknownDevice(), BoxObservationSourceSpec.mockupDeviceBodyFrame),
      (
        const coui.Table(rows: [_UnknownRow()]),
        BoxObservationSourceSpec.tableGridContentInset,
      ),
      (
        const coui.Table(
          rows: [
            coui.CoreTableRowData<Component>(cells: [_UnknownCell()]),
          ],
        ),
        BoxObservationSourceSpec.tableGridContentInset,
      ),
    ]) {
      expect(
        () => bindFramedCollectionWebRawSource(
          producer: producer,
          source: source,
        ),
        throwsStateError,
      );
    }
  });
  for (final scenario in [
    'wrong-key',
    'wrong-example',
    'drop-device-wrapper',
    'repeated-build',
  ]) {
    test('canonical $scenario fails closed', () async {
      final entry = _entry('mockup', 'phone', 'light');
      final recorder = FramedCollectionSsrSource.forEntry(entry)!;
      await expectLater(
        renderComponentToDocumentHtml(
          coui.CoUIWeb(
            theme: .coui,
            child: _Capture(entry, recorder, scenario: scenario),
          ),
          onMountedRoot: recorder.observe,
        ),
        throwsStateError,
      );
    });
  }
  for (final foreign in [false, true]) {
    test(
      foreign
          ? 'Device paint authority leaves the whole supplied child opaque'
          : 'Device paint source rejects undeclared body markup',
      () async {
        final entry = _entry('mockup', 'phone', 'light');
        final recorder = FramedCollectionSsrSource.forEntry(entry)!;
        await renderComponentToDocumentHtml(
          coui.CoUIWeb(
            theme: .coui,
            child: _Capture(entry, recorder),
          ),
          onMountedRoot: (root) {
            final before = recorder.observe(root);
            final producer = _paintWalk(root)
                .where(
                  (node) => node.component.runtimeType == coui.MockupDevice,
                )
                .single;
            final deviceDom = _paintDomFrontier(producer).single;
            final outlined = (deviceDom.component as DomComponent).children!
                .where((child) => child.runtimeType == coui.OutlinedContainer)
                .single;
            final target = foreign
                ? _paintDomFrontier(
                    currentSsrIdentityElement(
                      producer,
                      (producer.component as coui.MockupDevice).child,
                    ),
                  ).single
                : _paintDomFrontier(
                    _paintChildren(deviceDom)
                        .where((node) => identical(node.component, outlined))
                        .single,
                  ).single;
            final markup =
                (target as RenderObjectElement).renderObject
                    as MarkupRenderObject;
            final injected = MarkupRenderText(
              'foreign paint must not win',
              false,
            );
            markup.attach(injected);
            try {
              if (foreign) {
                expect(recorder.observe(root), before);
              } else {
                expect(() => recorder.observe(root), throwsStateError);
              }
            } finally {
              markup.remove(injected);
            }
            expect(recorder.observe(root), before);
          },
        );
      },
    );
  }
  for (final component in ['join', 'table']) {
    for (final text in ['outside', '\u00a0']) {
      test('$component own wrapper rejects anonymous markup text', () async {
        final entry = _entry(component, 'default', 'light');
        final recorder = FramedCollectionSsrSource.forEntry(entry)!;
        Component? originalResult;
        await renderComponentToDocumentHtml(
          coui.CoUIWeb(
            theme: .coui,
            child: _Capture(
              entry,
              recorder,
              onResult: (result) => originalResult = result,
            ),
          ),
          onMountedRoot: (root) {
            final before = recorder.observe(root);
            final target = _ownedRawHost(root, originalResult!, component);
            final markup =
                (target as RenderObjectElement).renderObject
                    as MarkupRenderObject;
            final anonymous = MarkupRenderText(text, false);
            markup.attach(anonymous);
            try {
              expect(() => recorder.observe(root), throwsStateError);
            } finally {
              markup.remove(anonymous);
            }
            expect(recorder.observe(root), before);
          },
        );
      });
    }
    test('$component whole foreign subtree remains opaque', () async {
      final entry = _entry(component, 'default', 'light');
      final recorder = FramedCollectionSsrSource.forEntry(entry)!;
      Component? originalResult;
      await renderComponentToDocumentHtml(
        coui.CoUIWeb(
          theme: .coui,
          child: _Capture(
            entry,
            recorder,
            onResult: (result) => originalResult = result,
          ),
        ),
        onMountedRoot: (root) {
          final before = recorder.observe(root);
          final host = _ownedRawHost(root, originalResult!, component);
          final rawRoot = _firstDom(_elementChildren(host).first);
          final markup =
              (rawRoot as RenderObjectElement).renderObject
                  as MarkupRenderObject;
          final foreign = MarkupRenderText('foreign content', false);
          markup.attach(foreign);
          try {
            expect(recorder.observe(root), before);
          } finally {
            markup.remove(foreign);
          }
        },
      );
    });
  }
}

List<Element> _elementChildren(Element element) {
  final children = <Element>[];
  element.visitChildren(children.add);
  return children;
}

Element _firstDom(Element element) {
  if (element.component is DomComponent) return element;
  return _firstDom(soleCurrentSsrChild(element));
}

Element _typedDiv(Element element) =>
    currentSsrGeneratedDiv(element, element.component as div);

Element _ownedRawHost(Element root, Component original, String component) {
  final example = currentSsrIdentityElement(root, original);
  final producer = soleCurrentSsrChild(example);
  final owner = _typedDiv(soleCurrentSsrChild(producer));
  if (component == 'join') return _typedDiv(_elementChildren(owner)[1]);
  final row = _typedDiv(_elementChildren(owner).first);
  return _typedDiv(_elementChildren(row).first);
}

class _Capture extends StatelessComponent {
  const _Capture(
    this.entry,
    this.recorder, {
    this.onBuild,
    this.onResult,
    this.scenario,
  });
  final MatrixEntry entry;
  final FramedCollectionSsrSource recorder;
  final void Function()? onBuild;
  final void Function(Component)? onResult;
  final String? scenario;
  @override
  Component build(BuildContext context) {
    onBuild?.call();
    var result = kWebPreviewRegistry[entry.component]!(
      context,
      scenario == 'wrong-example'
          ? 'tablet'
          : entry.variant == 'default'
          ? null
          : entry.variant,
    );
    if (scenario == 'drop-device-wrapper') {
      result = (result as div).children.single;
    }
    onResult?.call(result);
    final capture = div(
      [result],
      attributes: {
        'data-parity-key': scenario == 'wrong-key' ? 'wrong' : entry.key,
      },
    );
    recorder.recordBuild(result, capture);
    if (scenario == 'repeated-build') recorder.recordBuild(result, capture);
    return capture;
  }
}

class _UnknownDevice extends coui.MockupDevice {
  const _UnknownDevice() : super(child: const Component.text('foreign'));
}

class _UnknownRow extends coui.CoreTableRowData<Component> {
  const _UnknownRow() : super(cells: const []);
}

class _UnknownCell extends coui.CoreTableCellData<Component> {
  const _UnknownCell() : super(child: const Component.text('foreign'));
}
