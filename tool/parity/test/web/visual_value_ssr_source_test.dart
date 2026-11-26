import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/web_registry.dart';
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/ssr_source_identity.dart';
import '../../src/web/visual_value_ssr_source.dart';

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
MatrixEntry _entry(
  String component,
  String variant, {
  String theme = 'light',
  String style = 'defaultStyle',
  BoxObservationSourceSpec? source,
}) => MatrixEntry.fromJson({
  'component': component,
  'variant': variant,
  'theme': theme,
  'surfaceStyle': style,
  'tier': 't2',
  'probes': [
    rootProbeSpec(
      key: '$component-$variant-$theme-$style',
      flutterClassName: 'source-only',
      boxObservationSource: source ?? _source(component),
    ).toJson(),
  ],
});

void main() {
  // Canonical backend SSR uses the same CoUIWeb body for both entry axes.
  // Browser harness data-theme CSS selects the palette; these tests prove
  // source identities/nonmutation, not hydrated dark UI rendering.
  for (final recipe in _kRecipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme actual current source',
        () async {
          final entry = _entry(recipe.component, recipe.variant, theme: theme);
          final source = VisualValueSsrSource.forEntry(entry)!;
          var builds = 0;
          var observations = 0;
          Map<String, Object?>? receipt;
          final rendered = await renderComponentToDocumentHtml(
            coui.CoUIWeb(
              theme: .coui,
              child: _Capture(entry, source, onBuild: () => builds++),
            ),
            onMountedRoot: (root) {
              observations++;
              final markup =
                  (root as RenderObjectElement).renderObject
                      as MarkupRenderObject;
              final before = markup.renderToHtml();
              receipt = source.observe(root);
              expect(markup.renderToHtml(), before);
              expect(root.binding.rootElement, same(root));
            },
          );
          expect(builds, 1);
          expect(observations, 1);
          expect(receipt!['kind'], 'canonical-ssr-visual-value-v1');
          expect(receipt!['entryKey'], entry.key);
          expect(receipt!['source'], _source(recipe.component).toJson());
          expect(receipt!['rawOrderFromPublicProducerLists'], true);
          final raw = receipt!['currentRaw']! as Map;
          expect(raw['kind'], 'current-visual-value-raw-v1');
          expect(raw['logicalUnitId'], _source(recipe.component).logicalUnitId);
          final ticker = recipe.component == 'number-ticker';
          expect(raw['rawSlotCount'], ticker ? 1 : 0);
          expect(receipt!['completeRawSlotCount'], ticker ? 1 : 0);
          expect(raw['slotPresence'], ticker ? [false] : isEmpty);
          final tree = raw['generatedTree']! as Map;
          expect(
            tree.keys,
            unorderedEquals(['namespaceURI', 'localName', 'children']),
          );
          final tag = switch (recipe.component) {
            'icon' => 'svg',
            'skeleton' => 'div',
            _ => 'span',
          };
          expect(tree['localName'], tag);
          expect(
            tree['namespaceURI'],
            recipe.component == 'icon'
                ? 'http://www.w3.org/2000/svg'
                : 'http://www.w3.org/1999/xhtml',
          );
          if (recipe.component == 'skeleton') {
            final children = tree['children']! as List;
            // This assertion verifies the actual Example output, while the
            // collector itself never reads the preset's line-count field.
            expect(children.map((e) => (e as Map)['localName']), [
              'div',
              'div',
              'div',
              'span',
            ]);
          }
          expect(rendered, contains('data-parity-key="${entry.key}"'));
          expect(raw.containsKey('value'), false);
        },
      );
    }
  }

  for (final injected in [
    '</svg>outside',
    '</svg>\u00a0',
    '</svg><article>foreign</article>',
  ]) {
    test('actual SVG markup rejects root sibling $injected', () async {
      final entry = _entry('icon', 'default');
      final recorder = VisualValueSsrSource.forEntry(entry)!;
      div? originalCapture;
      await renderComponentBodyHtml(
        coui.CoUIWeb(
          theme: .coui,
          child: _Capture(
            entry,
            recorder,
            onCapture: (capture) => originalCapture = capture,
          ),
        ),
        onMountedRoot: (root) {
          final capture = currentSsrIdentityElement(root, originalCapture!);
          final example = soleCurrentSsrChild(
            currentSsrGeneratedDiv(capture, originalCapture!),
          );
          final producer = soleCurrentSsrChild(example);
          final owner = soleCurrentSsrChild(producer) as RenderObjectElement;
          final markup = owner.renderObject as MarkupRenderObject;
          final before = markup.renderToHtml();
          final extra = markup.createChildRenderText(injected, true);
          markup.attach(extra, after: markup.children.last);
          try {
            // Assert the collector itself rejects this actual serialization.
            // Restoring before callback return prevents the general SSR hook's
            // nonmutation guard from supplying the negative-test authority.
            expect(() => recorder.observe(root), throwsStateError);
          } finally {
            markup.remove(extra);
          }
          expect(markup.renderToHtml(), before);
        },
      );
    });
  }

  test('plain ticker retains its nullable child before omission', () {
    final raw = bindVisualValueWebRawSource(
      producer: const coui.NumberTicker(value: 8),
      source: _source('number-ticker'),
    );
    expect(raw.rawSlots, [null]);
    expect(raw.currentDomContract['slotPresence'], [false]);
    expect(raw.currentDomContract['plainMode'], true);
    raw.validateExistingCurrentBinding();
  });
  test('builder and formatter are rejected without invoking callbacks', () {
    var callbacks = 0;
    final inputs = <Component>[
      coui.NumberTicker.builder(
        value: 9,
        child: const Component.text('whole foreign'),
        builder: (context, value, child) {
          callbacks++;
          return child!;
        },
      ),
      coui.NumberTicker(
        value: 9,
        formatter: (value) {
          callbacks++;
          return '$value';
        },
      ),
    ];
    for (final producer in inputs) {
      expect(
        () => bindVisualValueWebRawSource(
          producer: producer,
          source: _source('number-ticker'),
        ),
        throwsStateError,
      );
    }
    expect(callbacks, 0);
  });
  test('unproved skeleton variants remain ungranted', () {
    for (final producer in [
      coui.Skeleton(),
      coui.Skeleton(variant: .circular),
    ]) {
      expect(
        () => bindVisualValueWebRawSource(
          producer: producer,
          source: _source('skeleton'),
        ),
        throwsStateError,
      );
    }
  });
  test('unknown concrete subclasses fail closed', () {
    for (final input in <({Component producer, String component})>[
      (producer: const _UnknownIcon(), component: 'icon'),
      (producer: const _UnknownTicker(), component: 'number-ticker'),
      (producer: _UnknownSkeleton(), component: 'skeleton'),
      (producer: const _UnknownCountdown(), component: 'countdown'),
    ]) {
      expect(
        () => bindVisualValueWebRawSource(
          producer: input.producer,
          source: _source(input.component),
        ),
        throwsStateError,
      );
    }
  });
  test('unknown IconName subclass cannot hide foreign inputs', () {
    expect(
      () => bindVisualValueWebRawSource(
        producer: const coui.Icon(_UnknownIconName()),
        source: _source('icon'),
      ),
      throwsStateError,
    );
  });
  test('each foreign producer cannot borrow another closed tuple', () {
    final producers = <Component>[
      const coui.Icon(coui.LucideIcons.house),
      const coui.NumberTicker(value: 5),
      coui.Skeleton.text(),
      const coui.Countdown(value: 5),
    ];
    const sources = BoxObservationSourceSpec.visualValueFrames;
    for (var i = 0; i < sources.length; i++) {
      for (var j = 0; j < sources.length; j++) {
        if (i == j) continue;
        expect(
          () => bindVisualValueWebRawSource(
            producer: producers[i],
            source: sources[j],
          ),
          throwsStateError,
        );
      }
    }
  });
  test('unrequested entry yields no source recorder', () {
    final entry = MatrixEntry.fromJson({
      'component': 'icon',
      'variant': 'default',
      'theme': 'light',
      'surfaceStyle': 'defaultStyle',
      'tier': 't2',
      'probes': [
        rootProbeSpec(
          key: 'icon-default-light-defaultStyle',
          flutterClassName: 'source-only',
        ).toJson(),
      ],
    });
    expect(VisualValueSsrSource.forEntry(entry), isNull);
  });
  test('recipe-source cross binding and unsupported recipes are rejected', () {
    expect(
      () => VisualValueSsrSource.forEntry(
        _entry('icon', 'default', source: _source('countdown')),
      ),
      throwsStateError,
    );
    expect(
      () => VisualValueSsrSource.forEntry(_entry('icon', 'chain')),
      throwsStateError,
    );
  });
  test('same source is independent of all surface style suffixes', () {
    for (final style in coui.CoreSurfaceStyleId.values) {
      expect(
        VisualValueSsrSource.forEntry(
          _entry('icon', 'search', style: style.name),
        ),
        isNotNull,
      );
    }
  });
  for (final scenario in [
    'wrong-example',
    'wrong-capture',
    'detached-original',
  ]) {
    test('$scenario cannot use a different mounted source', () async {
      final entry = _entry('icon', 'default');
      final recorder = VisualValueSsrSource.forEntry(entry)!;
      await expectLater(
        renderComponentBodyHtml(
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
  test('recordBuild is one-shot on original object identities', () {
    final entry = _entry('icon', 'default');
    final recorder = VisualValueSsrSource.forEntry(entry)!;
    const original = Component.text('original');
    final capture = div(
      const [original],
      attributes: {'data-parity-key': entry.key},
    );
    recorder.recordBuild(original, capture);
    expect(() => recorder.recordBuild(original, capture), throwsStateError);
  });
}

class _Capture extends StatelessComponent {
  const _Capture(
    this.entry,
    this.recorder, {
    this.onBuild,
    this.onCapture,
    this.scenario,
  });
  final MatrixEntry entry;
  final VisualValueSsrSource recorder;
  final void Function()? onBuild;
  final void Function(div)? onCapture;
  final String? scenario;

  @override
  Component build(BuildContext context) {
    onBuild?.call();
    final result = kWebPreviewRegistry[entry.component]!(
      context,
      scenario == 'wrong-example'
          ? 'favorite'
          : entry.variant == 'default'
          ? null
          : entry.variant,
    );
    final capture = div(
      [result],
      attributes: {
        'data-parity-key': scenario == 'wrong-capture'
            ? 'wrong-original'
            : entry.key,
      },
    );
    recorder.recordBuild(result, capture);
    onCapture?.call(capture);
    if (scenario == 'detached-original') {
      return const div([Component.text('different mount')]);
    }
    return capture;
  }
}

class _UnknownIcon extends coui.Icon {
  const _UnknownIcon() : super(coui.LucideIcons.house);
}

class _UnknownTicker extends coui.NumberTicker {
  const _UnknownTicker() : super(value: 3);
}

class _UnknownSkeleton extends coui.Skeleton {
  _UnknownSkeleton() : super.text();
}

class _UnknownCountdown extends coui.Countdown {
  const _UnknownCountdown() : super(value: 3);
}

class _UnknownIconName extends coui.IconName {
  const _UnknownIconName() : super('unknown', 'foreign');
  Component get hiddenForeign => const Component.text('foreign');
}
