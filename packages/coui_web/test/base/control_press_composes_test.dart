import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// The press travel has to *compose* with whatever the control is already
/// wearing, and on the web that is a statement about which property it
/// writes.
///
/// `transform` is a single property holding the element's whole matrix, so
/// declaring it inside a `:active` rule replaces what was there — and a
/// control positioned by a transform is holding its *position* there.
/// Carousel's prev/next buttons centre themselves with `-translate-y-1/2`;
/// while this rule wrote `transform`, pressing one discarded the centring
/// and the button dropped half its own height, then sprang back on
/// release. The standalone `translate` property composes instead: the
/// browser applies it before `transform`, so a positioning transform
/// survives untouched and a `0px 0px` offset moves nothing.
///
/// A regression here renders perfectly at rest and is only visible while
/// a pointer is held down, so nothing short of this pins it.
void main() {
  final css = ThemeConfig.defaults().cssVariables;

  /// The declaration block of the pressed-control rule.
  String pressBlock() {
    final marker = RegExp(
      '\\.$kControlShadowPressMarker:active\\{([^}]*)\\}',
    ).firstMatch(css);
    expect(
      marker,
      isNotNull,
      reason:
          'the pressed-control rule is gone — this guard now checks nothing',
    );

    return marker!.group(1)!;
  }

  group('a pressed control composes with its own positioning', () {
    test('the press travel writes translate, never transform', () {
      final block = pressBlock();
      expect(
        block,
        contains('translate:'),
        reason:
            'the press travel has to ride the standalone translate property',
      );
      expect(
        block,
        isNot(contains('transform:')),
        reason:
            'writing transform replaces the control\'s own positioning '
            'transform — a centred control drops out of place while pressed',
      );
    });

    test('the travel reads the offset variables both axes at once', () {
      final block = pressBlock();
      expect(block, contains('--coui-control-shadow-offset-x'));
      expect(block, contains('--coui-control-shadow-offset-y'));
    });

    test('the transition eases the property the rule actually writes', () {
      final rest = RegExp(
        '\\.$kControlShadowPressMarker\\{([^}]*)\\}',
      ).firstMatch(css);
      expect(
        rest,
        isNotNull,
        reason: 'the rest rule carrying the clock is gone',
      );
      final transition = rest!.group(1)!;
      expect(transition, contains('translate '));
      expect(
        transition,
        isNot(contains('transform ')),
        reason:
            'easing transform leaves the travel un-eased while easing a '
            'property this rule no longer writes',
      );
    });
  });

  group("the rest rule wins the marker's own transition unconditionally", () {
    test('the base transition declaration carries !important', () {
      final rest = RegExp(
        '\\.$kControlShadowPressMarker\\{([^}]*)\\}',
      ).firstMatch(css);
      expect(
        rest,
        isNotNull,
        reason: 'the rest rule carrying the clock is gone',
      );

      expect(
        rest!.group(1),
        endsWith('!important;'),
        reason:
            'this element also carries `.coui-surface` under any style '
            'that gives it a cast, and the surface-geometry theme-animation '
            "rule (`coui_web.dart`'s `_kSurfaceGeometryTransitionCss`) "
            'states its own transition-property/-duration on that exact '
            'class — same specificity (one class each), so the two '
            'resolve by source order alone. On every page that enables '
            'theme animation the surface rule is emitted after this one '
            'and always won, silently dropping `translate` from the '
            'transitioned property list and re-clocking `box-shadow` at '
            'the surface-crossfade duration instead of the press one. '
            'The control then jumped instantly to its pressed offset '
            'while its cast kept fading for the surface duration — a '
            'shadow visibly retreating from a button that had already '
            'stopped moving. Without `!important` here this regresses '
            'the moment any other equal-specificity rule targeting this '
            "element's `transition` is emitted after it, cascade order "
            'being an implementation detail neither rule controls.',
      );
    });
  });
}
