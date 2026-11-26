import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/web_registry.dart';
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
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
MatrixEntry _entry(
  String component,
  String variant, {
  String theme = 'light',
  BoxObservationSourceSpec? source,
}) => MatrixEntry.fromJson({
  'component': component,
  'variant': variant,
  'theme': theme,
  'surfaceStyle': 'defaultStyle',
  'tier': 't2',
  'probes': [
    rootProbeSpec(
      key: '$component-$variant-$theme-defaultStyle',
      flutterClassName: 'source-only',
      boxObservationSource: source ?? _source(component),
    ).toJson(),
  ],
});

void main() {
  for (final recipe in _recipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme same mounted raw source',
        () async {
          final entry = _entry(recipe.component, recipe.variant, theme: theme);
          final recorder = DataOverlaySsrSource.forEntry(entry)!;
          var builds = 0;
          var observations = 0;
          Map<String, Object?>? receipt;
          final document = await renderComponentToDocumentHtml(
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
              receipt = recorder.observe(root);
              expect(markup.renderToHtml(), before);
              expect(root.binding.rootElement, same(root));
            },
          );
          expect(builds, 1);
          expect(observations, 1);
          expect(receipt!['kind'], 'canonical-ssr-data-overlay-v1');
          expect(receipt!['entryKey'], entry.key);
          expect(receipt!['source'], _source(recipe.component).toJson());
          expect(receipt!['rawOrderFromPublicProducerLists'], true);
          final raw = receipt!['currentRaw']! as Map;
          expect(raw['kind'], 'current-data-overlay-raw-v1');
          final count = switch (recipe.component) {
            'theme-controller' || 'tracker' => 0,
            'swiper' => 2,
            _ => 4,
          };
          expect(raw['rawSlotCount'], count);
          expect(receipt!['completeRawSlotCount'], count);
          final presence = switch ((recipe.component, recipe.variant)) {
            ('bottom-sheet', 'close') => [true, false, true, false],
            ('diff', 'text') => [true, true, false, false],
            _ => List.filled(count, true),
          };
          expect(raw['slotPresence'], presence);
          if (recipe.component == 'theme-controller') {
            expect(raw['optionCount'], 4);
          }
          if (recipe.component == 'tracker') {
            expect(raw['segmentCount'], 14);
          }
          expect(document, contains('data-parity-key="${entry.key}"'));
        },
      );
    }
  }

  test('original nullable bag is retained before branch/omission', () {
    const title = Component.element(tag: 'h2');
    const content = Component.element(tag: 'article');
    final raw = bindDataOverlayWebRawSource(
      producer: const coui.BottomSheet(title: title, content: content),
      source: _source('bottom-sheet'),
    );
    expect(raw.rawSlots, hasLength(4));
    expect(raw.rawSlots[0], same(title));
    expect(raw.rawSlots[1], isNull);
    expect(raw.rawSlots[2], same(content));
    expect(raw.rawSlots[3], isNull);
    expect(raw.currentDomContract['slotPresence'], [true, false, true, false]);
  });

  test('all three producer raw bags reject aliases before omission', () {
    const same = Component.element(tag: 'div');
    const other = Component.element(tag: 'article');
    for (final input in <({Component producer, String component})>[
      (
        producer: const coui.BottomSheet(title: same, content: same),
        component: 'bottom-sheet',
      ),
      (
        producer: const coui.Swiper(overlayContent: same, child: same),
        component: 'swiper',
      ),
      (
        producer: const coui.Diff(before: same, after: other, afterLabel: same),
        component: 'diff',
      ),
    ]) {
      expect(
        () => bindDataOverlayWebRawSource(
          producer: input.producer,
          source: _source(input.component),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('DUPLICATE_RAW_SLOT_BEFORE_OMISSION'),
          ),
        ),
      );
    }
  });

  test('unknown producer subclass cannot borrow current source authority', () {
    expect(
      () => bindDataOverlayWebRawSource(
        producer: const _UnknownSheet(),
        source: _source('bottom-sheet'),
      ),
      throwsA(isA<StateError>()),
    );
  });
  test('unknown data subclass cannot hide foreign Component fields', () {
    expect(
      () => bindDataOverlayWebRawSource(
        producer: const coui.Tracker(segments: [_UnknownSegment()]),
        source: _source('tracker'),
      ),
      throwsA(isA<StateError>()),
    );
  });
  test('held data list mutation is rejected without a second build', () {
    final segments = <coui.CoreTrackerSegment>[
      const coui.CoreTrackerSegment(status: .fine),
      const coui.CoreTrackerSegment(status: .warning),
    ];
    final raw = bindDataOverlayWebRawSource(
      producer: coui.Tracker(segments: segments),
      source: _source('tracker'),
    );
    segments.removeLast();
    expect(raw.validateExistingCurrentBinding, throwsA(isA<StateError>()));
  });
  test('same slot shape does not authorize a mismatched source tuple', () {
    expect(
      () => bindDataOverlayWebRawSource(
        producer: const coui.Swiper(
          overlayContent: Component.text('overlay'),
          child: Component.text('trigger'),
        ),
        source: _source('bottom-sheet'),
      ),
      throwsA(isA<StateError>()),
    );
  });
  test('forged source version is rejected before a producer read', () {
    final original = _source('diff');
    final forged = BoxObservationSourceSpec(
      schemaVersion: 99,
      logicalUnitId: original.logicalUnitId,
      quantityId: original.quantityId,
      nativeAdapterId: original.nativeAdapterId,
      webAdapterId: original.webAdapterId,
    );
    expect(
      () => DataOverlaySsrSource.forEntry(
        _entry('diff', 'default', source: forged),
      ),
      throwsA(isA<StateError>()),
    );
  });
  test('unreviewed recipe cannot borrow a known source', () {
    expect(
      () => DataOverlaySsrSource.forEntry(_entry('diff', 'chain')),
      throwsA(isA<StateError>()),
    );
  });
  test('a repeated registry build is rejected', () {
    final entry = _entry('tracker', 'default');
    final recorder = DataOverlaySsrSource.forEntry(entry)!;
    const result = Component.text('record only');
    final capture = div(
      const [result],
      attributes: {'data-parity-key': entry.key},
    );
    recorder.recordBuild(result, capture);
    expect(
      () => recorder.recordBuild(result, capture),
      throwsA(isA<StateError>()),
    );
  });

  for (final scenario in [
    'wrong-example',
    'wrong-capture',
    'drop-swiper-wrapper',
  ]) {
    test('actual current route rejects $scenario without a fallback', () async {
      final component = scenario == 'drop-swiper-wrapper'
          ? 'swiper'
          : 'bottom-sheet';
      final entry = _entry(component, 'default');
      final recorder = DataOverlaySsrSource.forEntry(entry)!;
      await expectLater(
        renderComponentToDocumentHtml(
          coui.CoUIWeb(
            theme: .coui,
            child: _Capture(entry, recorder, scenario: scenario),
          ),
          onMountedRoot: recorder.observe,
        ),
        throwsA(isA<StateError>()),
      );
    });
  }
}

class _Capture extends StatelessComponent {
  const _Capture(this.entry, this.recorder, {this.onBuild, this.scenario});

  final MatrixEntry entry;
  final DataOverlaySsrSource recorder;
  final void Function()? onBuild;
  final String? scenario;

  @override
  Component build(BuildContext context) {
    onBuild?.call();
    var result = kWebPreviewRegistry[entry.component]!(
      context,
      scenario == 'wrong-example'
          ? 'close'
          : entry.variant == 'default'
          ? null
          : entry.variant,
    );
    if (scenario == 'drop-swiper-wrapper') {
      result = (result as div).children.single;
    }
    final capture = div(
      [result],
      attributes: {
        'data-parity-key': scenario == 'wrong-capture'
            ? 'wrong-current-key'
            : entry.key,
      },
    );
    recorder.recordBuild(result, capture);
    return capture;
  }
}

class _UnknownSheet extends coui.BottomSheet {
  const _UnknownSheet() : super(title: const Component.text('unknown'));
}

class _UnknownSegment extends coui.CoreTrackerSegment {
  const _UnknownSegment() : super(status: .fine);
  Component get hiddenForeign => const Component.text('unknown foreign');
}
