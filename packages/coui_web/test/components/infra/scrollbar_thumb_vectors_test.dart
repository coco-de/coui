// Where the Web thumb stands for a measured scroller — held to the same
// vector table Flutter's `ScrollbarPainter` is held to.
//
// A browser measures `scrollTop` / `scrollHeight` / `clientHeight` and the
// component places a `<div>` from them; Flutter's painter derives the same
// two numbers from its scroll metrics. The table owned by coui_core is the
// one statement of that arithmetic, so a thumb that drifts on either platform
// fails here or in the Flutter painter test.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/scrollbar/scrollbar_geometry.dart';
import 'package:coui_web/src/components/infra/scrollbar/scrollbar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const String kScrollbarThumbVectorsPath =
    '../coui_core/test/fixtures/scrollbar_thumb_vectors.json';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.empty();
  }
}

T _read<T>(ComponentTester tester, T Function(BuildContext context) read) {
  late T value;
  pumpWithTheme(tester, _ContextCapture((context) => value = read(context)));
  return value;
}

double _num(Map<String, Object?> c, String key) => (c[key]! as num).toDouble();

/// A box whose vertical axis measures like vector [c], scrolled to its
/// offset; the horizontal axis has nothing to scroll.
ScrollbarViewportGeometry _verticalOf(Map<String, Object?> c) => (
  scrollTop: _num(c, 'scrollOffset'),
  scrollHeight: _num(c, 'content'),
  clientHeight: _num(c, 'viewport'),
  scrollLeft: 0,
  scrollWidth: 300,
  clientWidth: 300,
);

/// The same measurements on the horizontal axis, scrolled [direction] ×
/// the offset — `-1` is a right-to-left box, whose `scrollLeft` runs
/// negative from `0` at its right edge.
ScrollbarViewportGeometry _horizontalOf(
  Map<String, Object?> c, {
  double direction = 1,
}) => (
  scrollTop: 0,
  scrollHeight: 300,
  clientHeight: 300,
  scrollLeft: direction * _num(c, 'scrollOffset'),
  scrollWidth: _num(c, 'content'),
  clientWidth: _num(c, 'viewport'),
);

void main() {
  final doc =
      jsonDecode(File(kScrollbarThumbVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final tolerance = (doc['tolerance']! as num).toDouble();
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  void expectThumb(CoreScrollbarThumbLayout? thumb, Map<String, Object?> c) {
    final expected = c['expected'] as Map<String, Object?>?;
    if (expected == null) {
      expect(thumb, isNull);

      return;
    }
    expect(thumb, isNotNull);
    expect(thumb!.extent, closeTo(_num(expected, 'extent'), tolerance));
    expect(thumb.offset, closeTo(_num(expected, 'offset'), tolerance));
  }

  group('scrollbarThumbsOf against the shared thumb vectors', () {
    for (final c in cases) {
      final margin = _num(c, 'margin');
      final minLength = _num(c, 'minLength');

      test('${c['name']} — vertical', () {
        final thumbs = scrollbarThumbsOf(
          _verticalOf(c),
          axis: .vertical,
          margin: margin,
          minLength: minLength,
        );
        expectThumb(thumbs.vertical, c);
        expect(thumbs.horizontal, isNull, reason: "not the bar's axis");
      });

      test('${c['name']} — horizontal, left to right', () {
        final thumbs = scrollbarThumbsOf(
          _horizontalOf(c),
          axis: .horizontal,
          margin: margin,
          minLength: minLength,
        );
        expectThumb(thumbs.horizontal, c);
        expect(thumbs.vertical, isNull);
      });

      test('${c['name']} — horizontal, right to left', () {
        final thumbs = scrollbarThumbsOf(
          _horizontalOf(c, direction: -1),
          axis: .horizontal,
          margin: margin,
          minLength: minLength,
        );
        // A negative `scrollLeft` is a distance from the right edge, which is
        // where a right-to-left box starts — the thumb stands where the
        // left-to-right one does, measured from the inline start.
        expectThumb(thumbs.horizontal, c);
      });
    }
  });

  group('scrollbarThumbsOf — both axes', () {
    test('each axis reads its own triple', () {
      final thumbs = scrollbarThumbsOf(
        (
          scrollTop: 200,
          scrollHeight: 560,
          clientHeight: 160,
          scrollLeft: 0,
          scrollWidth: 160,
          clientWidth: 160,
        ),
        axis: .both,
        margin: 2,
        minLength: 48,
      );

      expect(thumbs.vertical, isNotNull);
      // The width fits, so there is no horizontal thumb — a bar reading the
      // height triple for both would draw one.
      expect(thumbs.horizontal, isNull);
    });
  });

  group('resolveScrollbar places the thumb from the measurement', () {
    // 160 tall viewport over 560 content, scrolled to the middle: a 48 long
    // thumb 56 from the top. The hit area is the capsule plus the 2px inset
    // at each end, so it starts at 54 and is 52 long.
    const viewport = (
      scrollTop: 200.0,
      scrollHeight: 560.0,
      clientHeight: 160.0,
      scrollLeft: 0.0,
      scrollWidth: 260.0,
      clientWidth: 260.0,
    );

    ResolvedScrollbar resolve(
      ComponentTester tester, {
      ScrollbarViewportGeometry? geometry = viewport,
      CoreScrollbarAxis axis = CoreScrollbarAxis.vertical,
      CoreScrollbarVisibility visibility = CoreScrollbarVisibility.auto,
      bool shown = false,
      CoreScrollbarAxis? draggingAxis,
    }) => _read(
      tester,
      (context) => resolveScrollbar(
        context,
        axis: axis,
        visibility: visibility,
        interactive: true,
        viewport: geometry,
        shown: shown,
        draggingAxis: draggingAxis,
      ),
    );

    String prop(WebElementChrome? chrome, String name) =>
        chrome!.inlineStyles!.properties[name]!;

    testComponents('the track spans the visible height', (tester) async {
      final resolved = resolve(tester);

      expect(prop(resolved.verticalTrack, 'height'), '160px');
    });

    testComponents('the thumb starts one inset before the capsule and '
        'covers both insets', (tester) async {
      final resolved = resolve(tester);

      expect(prop(resolved.verticalThumb, 'top'), '54px');
      expect(prop(resolved.verticalThumb, 'height'), '52px');
    });

    testComponents('the measured lengths are pixels, not rem', (tester) async {
      final resolved = resolve(tester);

      // They were measured in CSS pixels against the box they sit in; rem
      // would rescale them by the root font size.
      expect(prop(resolved.verticalThumb, 'top'), isNot(contains('rem')));
      expect(prop(resolved.verticalTrack, 'height'), isNot(contains('rem')));
    });

    testComponents('a fractional position keeps two decimals', (tester) async {
      final resolved = resolve(
        tester,
        geometry: (
          scrollTop: 133.0,
          scrollHeight: 1000.0,
          clientHeight: 600.0,
          scrollLeft: 0.0,
          scrollWidth: 260.0,
          clientWidth: 260.0,
        ),
      );

      // 81.268 (the table's tall-viewport case) less the 2px inset.
      expect(prop(resolved.verticalThumb, 'top'), '79.27px');
    });

    testComponents('the horizontal bar sits against the bottom edge', (
      tester,
    ) async {
      final resolved = resolve(
        tester,
        axis: .horizontal,
        geometry: (
          scrollTop: 0.0,
          scrollHeight: 160.0,
          clientHeight: 160.0,
          scrollLeft: 100.0,
          scrollWidth: 560.0,
          clientWidth: 260.0,
        ),
      );

      // Anchored from the measured height less the footprint (10px).
      expect(
        prop(resolved.horizontalTrack, 'top'),
        'calc(160px - 0.625rem)',
      );
      expect(prop(resolved.horizontalTrack, 'width'), '260px');
      expect(prop(resolved.horizontalThumb, 'width'), isNotEmpty);
      expect(
        prop(resolved.horizontalThumb, 'inset-inline-start'),
        endsWith('px'),
      );
      expect(resolved.verticalTrack, isNull);
    });

    testComponents('nothing to scroll draws no track and no thumb', (
      tester,
    ) async {
      final resolved = resolve(
        tester,
        geometry: (
          scrollTop: 0.0,
          scrollHeight: 160.0,
          clientHeight: 160.0,
          scrollLeft: 0.0,
          scrollWidth: 260.0,
          clientWidth: 260.0,
        ),
      );

      expect(resolved.layer, isNotNull);
      expect(resolved.verticalTrack, isNull);
      expect(resolved.verticalThumb, isNull);
      expect(resolved.verticalCapsule, isNull);
    });

    testComponents('before a measurement there is a layer and no thumb', (
      tester,
    ) async {
      final resolved = resolve(tester, geometry: null);

      expect(resolved.layer, isNotNull);
      expect(resolved.verticalThumb, isNull);
    });

    testComponents('hidden draws nothing at all', (tester) async {
      final resolved = resolve(tester, visibility: .hidden);

      expect(resolved.layer, isNull);
      expect(resolved.verticalTrack, isNull);
    });

    testComponents('the track comes with its thumb, capsule inside', (
      tester,
    ) async {
      final resolved = resolve(tester);

      expect(resolved.verticalTrack!.className, contains(kScrollbarTrackClass));
      expect(resolved.verticalThumb!.className, contains(kScrollbarThumbClass));
      expect(
        resolved.verticalCapsule!.className,
        contains(kScrollbarCapsuleClass),
      );
    });

    testComponents('shown and held are root classes', (tester) async {
      final idle = resolve(tester);
      final shown = resolve(tester, shown: true);
      final held = resolve(tester, draggingAxis: .vertical);

      expect(idle.root.className, isNot(contains(kScrollbarShownClass)));
      expect(shown.root.className, contains(kScrollbarShownClass));
      expect(
        held.root.className,
        contains(kScrollbarDraggingVerticalClass),
      );
      expect(
        held.root.className,
        isNot(contains(kScrollbarDraggingHorizontalClass)),
      );
    });

    testComponents('the root keeps its overflow and fill classes', (
      tester,
    ) async {
      final resolved = resolve(tester);

      expect(
        resolved.root.className.split(' '),
        containsAll(['overflow-y-auto', 'overflow-x-hidden', 'h-full']),
      );
    });
  });

  group('resolveScrollbarThumbs is the thumb that was drawn', () {
    testComponents('it reads the same margin and minimum length', (
      tester,
    ) async {
      const geometry = (
        scrollTop: 200.0,
        scrollHeight: 560.0,
        clientHeight: 160.0,
        scrollLeft: 0.0,
        scrollWidth: 260.0,
        clientWidth: 260.0,
      );
      final thumbs = _read(
        tester,
        (context) => resolveScrollbarThumbs(
          context,
          axis: .vertical,
          visibility: .auto,
          viewport: geometry,
        ),
      );

      expect(thumbs.vertical!.extent, 48);
      expect(thumbs.vertical!.offset, 56);
    });

    testComponents('a style override moves the margin and the minimum', (
      tester,
    ) async {
      const geometry = (
        scrollTop: 0.0,
        scrollHeight: 560.0,
        clientHeight: 160.0,
        scrollLeft: 0.0,
        scrollWidth: 260.0,
        clientWidth: 260.0,
      );
      final thumbs = _read(
        tester,
        (context) => resolveScrollbarThumbs(
          context,
          axis: .vertical,
          visibility: .auto,
          viewport: geometry,
          scrollbarStyle: const CoreScrollbarStyle(
            thumbInset: 4,
            minThumbLength: 64,
          ),
        ),
      );

      expect(thumbs.vertical!.extent, 64);
      expect(thumbs.vertical!.offset, 4);
    });
  });
}
