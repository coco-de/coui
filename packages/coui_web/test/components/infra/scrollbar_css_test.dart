// The scoped `<style>` block `Scrollbar` emits — where everything the design
// states about the thumb lives, now that the thumb is a `<div>` drawn over the
// content instead of the browser's own scrollbar.
//
// What a headless server render cannot say is how a browser lays these rules
// out, so what is pinned here is the CSS that ships: the native bar is hidden
// where the overlay is drawn, the overlay takes no layout space, every
// selector is anchored to the scope id through child combinators, and the
// numbers are the ones `CoreScrollbarThumbGeometry` derives.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/scrollbar/scrollbar_style.dart';
import 'package:jaspr_test/server_test.dart';

/// Renders a `Scrollbar` and returns the text of its scoped `<style>`.
Future<String> _css(
  ServerTester tester, {
  CoreScrollbarAxis axis = .vertical,
  CoreScrollbarVisibility visibility = .auto,
  bool interactive = true,
  CoreScrollbarStyle? scrollbarStyle,
}) async {
  tester.pumpComponent(
    CoUIWeb(
      theme: .coui,
      child: Scrollbar(
        id: 'sb',
        axis: axis,
        visibility: visibility,
        interactive: interactive,
        scrollbarStyle: scrollbarStyle,
        child: const Component.element(
          tag: 'div',
          children: [Component.text('content')],
        ),
      ),
    ),
  );
  final response = await tester.request('/');
  return response.document!.querySelector('#sb style')!.text;
}

/// The declarations of the first top-level rule whose selector is exactly
/// [selector] — one that follows another rule's closing brace, so the same
/// selector inside an `@media` block is not mistaken for it.
String _rule(String css, String selector) {
  var start = css.indexOf('}$selector {');
  if (start >= 0) {
    start += 1;
  } else if (css.startsWith('$selector {')) {
    start = 0;
  }
  expect(start, isNonNegative, reason: 'no rule for "$selector" in:\n$css');
  final open = css.indexOf('{', start);
  return css.substring(open + 1, css.indexOf('}', open));
}

const _layer = '#sb > .$kScrollbarLayerClass';
const _track = '$_layer > .$kScrollbarTrackClass';
const _thumb = '$_layer > .$kScrollbarThumbClass';
const _capsule = '$_thumb > .$kScrollbarCapsuleClass';
const _vertical = '.$kScrollbarVerticalClass';
const _horizontal = '.$kScrollbarHorizontalClass';

void main() {
  group('Scrollbar scoped CSS — the native bar and the layout', () {
    testServer('the native scrollbar is hidden, on both spellings', (
      tester,
    ) async {
      final css = await _css(tester);

      expect(css, contains('#sb { scrollbar-width: none; }'));
      expect(css, contains('#sb::-webkit-scrollbar { display: none; }'));
    });

    testServer('the native bar is hidden only where the overlay is drawn', (
      tester,
    ) async {
      final css = await _css(tester);

      // In forced colours a `<div>` thumb would be repainted as the page
      // background and vanish, while the native bar is restyled in system
      // colours and stays readable — so the page keeps the native one there.
      final hide = css.indexOf('@media (forced-colors: none)');
      expect(hide, isNonNegative);
      expect(
        css.indexOf('#sb { scrollbar-width: none; }'),
        greaterThan(hide),
        reason: 'hiding the native bar is gated to forced-colors: none',
      );
      expect(
        css,
        contains(
          '@media (forced-colors: active) { $_layer { display: none; } }',
        ),
      );
    });

    testServer('the layer takes no layout space', (tester) async {
      final css = await _css(tester);
      final layer = _rule(css, _layer);

      // Sticky and zero tall: it stays in the corner of the visible area as
      // the content scrolls under it, and adds nothing to the content's
      // height or width — the whole reason the bar costs no content width.
      expect(layer, contains('position: sticky'));
      expect(layer, contains('top: 0'));
      expect(layer, contains('inset-inline-start: 0'));
      expect(layer, contains('width: 100%'));
      expect(layer, contains('height: 0;'));
      expect(layer, contains('pointer-events: none'));
    });

    testServer('the layer sits on the base content layer', (tester) async {
      final css = await _css(tester);

      // 1000 — above content that picked a z-index of its own (1–999),
      // below dropdowns and everything stacked above them.
      expect(_rule(css, _layer), contains('z-index: 1000'));
    });

    testServer('every selector is anchored through child combinators', (
      tester,
    ) async {
      final css = await _css(tester);

      // A descendant selector would also reach the track and thumb of a
      // `Scrollbar` nested inside this one's content and restyle them.
      expect(css, isNot(contains('#sb .$kScrollbarLayerClass')));
      expect(css, isNot(contains('#sb .$kScrollbarThumbClass')));
      expect(css, isNot(contains('#sb .$kScrollbarTrackClass')));
      expect(css, isNot(contains('#sb .$kScrollbarCapsuleClass')));
    });
  });

  group('Scrollbar scoped CSS — resting thumb', () {
    testServer('the hit area is the thumb plus its inset on both sides', (
      tester,
    ) async {
      final css = await _css(tester);

      // 6 + 2 * 2 = 10px = 0.625rem — the footprint, now a hit area rather
      // than space the browser reserves.
      expect(_rule(css, '$_thumb$_vertical'), contains('width: 0.625rem'));
      expect(_rule(css, '$_track$_vertical'), contains('width: 0.625rem'));
      expect(_rule(css, '$_thumb$_horizontal'), contains('height: 0.625rem'));
      expect(_rule(css, '$_track$_horizontal'), contains('height: 0.625rem'));
    });

    testServer('the capsule keeps its inset from the edge and from the ends', (
      tester,
    ) async {
      final css = await _css(tester);
      final vertical = _rule(
        css,
        '$_thumb$_vertical > .$kScrollbarCapsuleClass',
      );

      // 6px thick, 2px clear of the edge and of both ends of the hit area.
      expect(vertical, contains('width: 0.375rem'));
      expect(vertical, contains('inset-inline-end: 0.125rem'));
      expect(vertical, contains('top: 0.125rem'));
      expect(vertical, contains('bottom: 0.125rem'));
    });

    testServer('the horizontal capsule mirrors it along the bottom edge', (
      tester,
    ) async {
      final css = await _css(tester, axis: .horizontal);
      final horizontal = _rule(
        css,
        '$_thumb$_horizontal > .$kScrollbarCapsuleClass',
      );

      expect(horizontal, contains('height: 0.375rem'));
      expect(horizontal, contains('bottom: 0.125rem'));
      expect(horizontal, contains('inset-inline-start: 0.125rem'));
      expect(horizontal, contains('inset-inline-end: 0.125rem'));
    });

    testServer('the vertical bar is positioned by the inline end, so a '
        'right-to-left page puts it on the left like the native bar did', (
      tester,
    ) async {
      final css = await _css(tester);

      expect(_rule(css, '$_thumb$_vertical'), contains('inset-inline-end: 0'));
      expect(_rule(css, '$_track$_vertical'), contains('inset-inline-end: 0'));
      expect(css, isNot(contains('right:')));
      expect(css, isNot(contains('left:')));
    });

    testServer('the capsule radius is the visible radius — no outset', (
      tester,
    ) async {
      final css = await _css(tester);

      // The capsule is its own box, not the padding box of a bordered one,
      // so the radius needs no growth to survive a border.
      expect(
        _rule(css, _capsule),
        contains(
          'border-radius: var(--coui-radius-9999) var(--coui-radius-9999) '
          'var(--coui-radius-9999) var(--coui-radius-9999)',
        ),
      );
      expect(css, isNot(contains('calc(var(--coui-radius-')));
    });

    testServer('the capsule is the thumb colour', (tester) async {
      final css = await _css(tester);

      expect(
        _rule(css, _capsule),
        contains('background-color: rgb(var(--coui-on-surface) / 50%)'),
      );
    });

    testServer('the thumb can be dragged by touch', (tester) async {
      final css = await _css(tester);

      expect(_rule(css, _thumb), contains('touch-action: none'));
    });
  });

  group('Scrollbar scoped CSS — fading', () {
    testServer('auto rests invisible and shows on activity, hover or a held '
        'thumb', (tester) async {
      final css = await _css(tester);

      expect(css, contains('$_track, $_capsule { opacity: 0; }'));
      expect(
        css,
        contains('#sb.$kScrollbarShownClass > .$kScrollbarLayerClass'),
      );
      // Hovering the thumb or its track reveals it.
      expect(css, contains('$_thumb:hover > .$kScrollbarCapsuleClass'));
      expect(css, contains('$_track:hover + .$kScrollbarThumbClass'));
      // A held thumb stays shown after the pointer leaves it.
      expect(
        css,
        contains(
          '#sb.$kScrollbarDraggingVerticalClass > .$kScrollbarLayerClass',
        ),
      );
    });

    testServer('the revealing rules come after the resting one', (
      tester,
    ) async {
      final css = await _css(tester);

      // Equal specificity would let source order decide; the reveal has more
      // anyway, but nothing should depend on that.
      final resting = css.indexOf('$_track, $_capsule { opacity: 0; }');
      final shown = css.indexOf('#sb.$kScrollbarShownClass');
      expect(resting, isNonNegative);
      expect(shown, greaterThan(resting));
    });

    testServer('the fade is a CSS transition over the shared fade duration', (
      tester,
    ) async {
      final css = await _css(tester);

      // 300ms — `CoreScrollbarContract.fadeDurationMs` — through the duration
      // variable, so reduced motion reaches it.
      expect(
        _rule(css, _track),
        contains('transition: opacity var(--coui-duration-300) '),
      );
      expect(
        _rule(css, _capsule),
        contains('opacity var(--coui-duration-300) '),
      );
    });

    testServer('always never hides the thumb', (tester) async {
      final css = await _css(tester, visibility: .always);

      expect(css, isNot(contains('opacity: 0')));
      expect(css, isNot(contains(kScrollbarShownClass)));
    });
  });

  group('Scrollbar scoped CSS — hovered or held thumb', () {
    testServer('the capsule gets the hovered ink and thickness', (
      tester,
    ) async {
      final css = await _css(tester);
      final hover = _rule(
        css,
        '$_thumb$_vertical:hover > .$kScrollbarCapsuleClass, '
        '$_track$_vertical:hover + .$kScrollbarThumbClass$_vertical > '
        '.$kScrollbarCapsuleClass, '
        '#sb.$kScrollbarDraggingVerticalClass > .$kScrollbarLayerClass > '
        '.$kScrollbarThumbClass$_vertical > .$kScrollbarCapsuleClass',
      );

      expect(
        hover,
        contains('background-color: rgb(var(--coui-on-surface) / 70%)'),
      );
      // Thumb 6 → 8 inside the unchanged 10px footprint: the inset narrows
      // from 2px to 1px, so the capsule stays centred and the content beside
      // the bar does not move.
      expect(hover, contains('width: 0.5rem'));
      expect(hover, contains('inset-inline-end: 0.0625rem'));
    });

    testServer('hovering the track grows the thumb that follows it', (
      tester,
    ) async {
      final css = await _css(tester);

      expect(css, contains('$_track$_vertical:hover + .$kScrollbarThumbClass'));
      expect(
        css,
        contains('$_track$_horizontal:hover + .$kScrollbarThumbClass'),
      );
    });

    testServer('the change is a transition over the shared hover duration', (
      tester,
    ) async {
      final css = await _css(tester);
      final capsule = _rule(css, _capsule);

      // 200ms — `CoreScrollbarContract.hoverTransitionMs`. The browser's own
      // thumb could not transition; this one does.
      expect(capsule, contains('background-color var(--coui-duration-200) '));
      expect(capsule, contains('width var(--coui-duration-200) '));
      expect(capsule, contains('inset-inline-end var(--coui-duration-200) '));
    });

    testServer('a thumb cannot outgrow its footprint: the inset runs out', (
      tester,
    ) async {
      final css = await _css(
        tester,
        scrollbarStyle: const CoreScrollbarStyle(hoverThickness: 40),
      );

      expect(css, contains('width: 0.625rem; }'));
      expect(css, contains('inset-inline-end: 0.0rem'));
      // The hit area did not grow.
      expect(_rule(css, '$_thumb$_vertical'), contains('width: 0.625rem'));
    });
  });

  group('Scrollbar scoped CSS — overrides reach the geometry', () {
    testServer('thickness and thumbInset set the footprint and the capsule', (
      tester,
    ) async {
      final css = await _css(
        tester,
        scrollbarStyle: const CoreScrollbarStyle(thickness: 8, thumbInset: 4),
      );

      // 8 + 2 * 4 = 16px.
      expect(_rule(css, '$_thumb$_vertical'), contains('width: 1.0rem'));
      final capsule = _rule(
        css,
        '$_thumb$_vertical > .$kScrollbarCapsuleClass',
      );
      expect(capsule, contains('width: 0.5rem'));
      expect(capsule, contains('inset-inline-end: 0.25rem'));
      expect(capsule, contains('top: 0.25rem'));
    });

    testServer('a scale radius override is the capsule radius as given', (
      tester,
    ) async {
      final css = await _css(
        tester,
        scrollbarStyle: const CoreScrollbarStyle(
          thumbRadius: CoreBorderRadius.all(CoreRadius.radius4),
        ),
      );

      expect(
        _rule(css, _capsule),
        contains('border-radius: var(--coui-radius-4) '),
      );
    });

    testServer('the hover ink and thickness are their own overrides', (
      tester,
    ) async {
      final css = await _css(
        tester,
        scrollbarStyle: const CoreScrollbarStyle(
          hoverThumbColor: CoreColor.token(CoreColors.primary),
          hoverThickness: 7,
        ),
      );

      expect(css, contains('background-color: rgb(var(--coui-primary))'));
      // 10 - 7 = 3, split over two sides = 1.5px.
      expect(css, contains('inset-inline-end: 0.09375rem'));
      expect(css, contains('width: 0.4375rem'));
    });

    testServer('a track colour is the track background', (tester) async {
      final css = await _css(
        tester,
        scrollbarStyle: const CoreScrollbarStyle(
          trackColor: CoreColor.token(CoreColors.surfaceContainer),
        ),
      );

      expect(
        _rule(css, _track),
        contains('background: rgb(var(--coui-surface-container))'),
      );
    });
  });

  group('Scrollbar scoped CSS — thin', () {
    testServer('halves both thicknesses and keeps the inset', (tester) async {
      final css = await _css(tester, visibility: .thin);

      // 3 + 2 * 2 = 7px.
      expect(_rule(css, '$_thumb$_vertical'), contains('width: 0.4375rem'));
      final capsule = _rule(
        css,
        '$_thumb$_vertical > .$kScrollbarCapsuleClass',
      );
      expect(capsule, contains('width: 0.1875rem'));
      expect(capsule, contains('inset-inline-end: 0.125rem'));
      // Hover thumb 8 * 0.5 = 4 inside the 7px footprint: 1.5px of inset.
      expect(css, contains('inset-inline-end: 0.09375rem'));
      expect(css, contains('width: 0.25rem'));
    });

    testServer('fades like auto', (tester) async {
      final css = await _css(tester, visibility: .thin);

      expect(css, contains('$_track, $_capsule { opacity: 0; }'));
    });
  });

  group('Scrollbar scoped CSS — not interactive', () {
    testServer('the thumb and the track take no pointer', (tester) async {
      final css = await _css(tester, interactive: false);

      expect(_rule(css, _thumb), contains('pointer-events: none'));
      expect(_rule(css, _track), contains('pointer-events: none'));
    });

    testServer('there is no hovered look and no hover reveal', (tester) async {
      final css = await _css(tester, interactive: false);

      expect(css, isNot(contains(':hover')));
      expect(css, isNot(contains(kScrollbarDraggingVerticalClass)));
    });

    testServer('an interactive bar takes the pointer', (tester) async {
      final css = await _css(tester);

      expect(_rule(css, _thumb), contains('pointer-events: auto'));
      expect(_rule(css, _track), contains('pointer-events: auto'));
    });

    testServer('touch has no pointer to page with, so the track steps aside', (
      tester,
    ) async {
      final css = await _css(tester);

      expect(
        css,
        contains(
          '@media (pointer: coarse) { $_track { pointer-events: none; } }',
        ),
      );
    });
  });

  group('Scrollbar scoped CSS — hidden', () {
    testServer('hidden hides the native bar and draws nothing', (
      tester,
    ) async {
      final css = await _css(tester, visibility: .hidden);

      expect(css, contains('#sb { scrollbar-width: none; }'));
      expect(css, contains('#sb::-webkit-scrollbar { display: none; }'));
      expect(css, isNot(contains(kScrollbarLayerClass)));
      expect(css, isNot(contains(':hover')));
      // Hidden stays hidden in forced colours too: it is the caller's choice
      // not to show a bar, not a styling the mode has to rescue.
      expect(css, isNot(contains('forced-colors')));
    });
  });
}
