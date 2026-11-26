import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// The engage-squash affordance (#4403) has to fire on a different trigger
/// per device: a pointer that can rest without pressing gets `:hover`
/// (matching the neo-brutalism reference, which never touches `active:`),
/// while a device with no such pointer keeps the pre-existing `:active`
/// trigger — a touch device's *emulated* `:hover` fires on tap and then
/// sticks until something else is tapped, so carrying `:hover` there would
/// leave a tapped control looking permanently pressed.
///
/// Both triggers therefore have to live behind their own `@media (hover:
/// …)` gate rather than as a bare selector. A bare `.marker:hover{…}`
/// renders identically to the gated version on every device this suite's
/// own tooling runs on (a desktop headless browser always reports
/// `hover: hover`), and only diverges on a touch device with emulated
/// `:hover` — which is exactly the device nothing else in this suite
/// emulates. So the assertions below check the *gate*, not just the
/// effect: the trigger selector has to appear immediately inside its
/// `@media` block, contiguous in the emitted CSS text, or the rule that
/// stops being gated still renders fine on every device that would ever
/// notice its absence in a screenshot.
/// How far back to look for a stray `@media` before the base transition
/// rule's opener — long enough to span the widest gap between two
/// concatenated rules in this stylesheet segment, short enough that an
/// unrelated `@media` block many rules earlier cannot false-positive.
const _kLookbackWindow = 30;

void main() {
  final css = ThemeConfig.defaults().cssVariables;

  const engageDeclarations =
      'box-shadow:var(--coui-control-shadow-press,'
      'var(--coui-button-rest-shadow)) !important;'
      'translate:var(--coui-control-shadow-offset-x) '
      'var(--coui-control-shadow-offset-y);';

  group('pointer-capable devices engage on hover (#4403)', () {
    test(
      'the :hover trigger is nested inside @media (hover:hover), '
      'contiguous with the marker and the shared declarations',
      () {
        expect(
          css,
          contains(
            '@media (hover:hover){.$kControlShadowPressMarker:hover{'
            '$engageDeclarations}}',
          ),
          reason:
              'without a :hover rule gated on (hover:hover), hovering a '
              'pointer-capable device does nothing — the whole reason '
              'this axis exists (the reference carries the entire cast '
              'affordance on hover: and never touches active:)',
        );
      },
    );
  });

  group('touch (no resting pointer) keeps the press trigger', () {
    test(
      'the :active trigger is nested inside @media (hover:none), '
      'contiguous with the marker and the shared declarations',
      () {
        expect(
          css,
          contains(
            '@media (hover:none){.$kControlShadowPressMarker:active{'
            '$engageDeclarations}}',
          ),
          reason:
              'deleting this leaves touch with no engage affordance at '
              "all — it is not a fallback to prune once :hover exists, "
              "it is touch's only path to the same effect",
        );
      },
    );
  });

  group('no un-gated copy of either trigger leaks outside its media block', () {
    test('exactly one :hover rule exists for the marker, and it is gated', () {
      // A regression that widens scope by leaving an *extra*, ungated
      // `:hover` rule alongside the correctly gated one would still pass
      // a plain `contains(...)` check on the gated form above — this
      // counts occurrences instead, so a stray second copy fails loudly.
      final hoverRules = RegExp(
        '\\.${RegExp.escape(kControlShadowPressMarker)}:hover\\{',
      ).allMatches(css).length;
      expect(
        hoverRules,
        1,
        reason: 'expected exactly one :hover rule for the marker',
      );

      final gatedHoverRules = RegExp(
        '@media \\(hover:hover\\)\\{\\.${RegExp.escape(kControlShadowPressMarker)}:hover\\{',
      ).allMatches(css).length;
      expect(
        gatedHoverRules,
        1,
        reason:
            'the sole :hover rule for the marker must be the one '
            'immediately inside @media (hover:hover) — this is the '
            'emulated-hover-on-touch regression the AC calls out by name',
      );
    });

    test('exactly one :active rule exists for the marker, and it is gated', () {
      final activeRules = RegExp(
        '\\.${RegExp.escape(kControlShadowPressMarker)}:active\\{',
      ).allMatches(css).length;
      expect(
        activeRules,
        1,
        reason: 'expected exactly one :active rule for the marker',
      );

      final gatedActiveRules = RegExp(
        '@media \\(hover:none\\)\\{\\.${RegExp.escape(kControlShadowPressMarker)}:active\\{',
      ).allMatches(css).length;
      expect(
        gatedActiveRules,
        1,
        reason:
            'the sole :active rule for the marker must be the one '
            'immediately inside @media (hover:none) — press must not '
            'apply on pointer-capable devices too (AC: "press 는 추가 '
            '변화 없음")',
      );
    });
  });

  group('the base transition rule stays unconditional', () {
    test('the marker\'s transition declaration is not media-gated', () {
      // The transition has to keep easing on both device kinds — it is
      // also the marker's only chrome-transition declaration (see the
      // doc comment on `_controlShadowPressRule`), so it must not be
      // nested inside either @media block.
      final opener = '.$kControlShadowPressMarker{transition:';
      final index = css.indexOf(opener);
      expect(
        index,
        isNonNegative,
        reason: 'the shared transition rule is gone',
      );

      // Nothing between the start of the stylesheet segment carrying this
      // rule and the opener should read as inside an @media block — the
      // simplest positive check is that the characters immediately
      // preceding the opener do not contain "@media", since the base
      // rule is emitted right after the skeleton/border rules, never
      // inside a media query.
      final preceding = css.substring(
        (index - _kLookbackWindow).clamp(0, css.length),
        index,
      );
      expect(preceding, isNot(contains('@media')));
    });
  });
}
