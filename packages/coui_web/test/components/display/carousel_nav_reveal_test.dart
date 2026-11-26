// The prev / next buttons fade in on hover in Flutter (`AnimatedOpacity`
// around the `Button`), and on Web they used to snap on: the fade classes sat
// on the `Button` itself, and every `Button` wears the shared
// `coui-control-shadow-press` marker whose `!important` `transition`
// shorthand names no `opacity` — so neither the `transition-opacity` utility
// nor the inline `transition-duration` could win. Nothing threw and the class
// names looked right, which is why these tests read where the reveal lives
// (the anchor around the button, not the button) and what clock it runs on.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Slide count used by every case.
const _kSlides = 3;

/// A fade length that is not a `CoreDuration` step, so it has no
/// `--coui-duration-*` variable to route through.
const _kOffScaleFade = Duration(milliseconds: 730);

late ResolvedCarousel _seen;

class _Capture extends StatelessComponent {
  const _Capture({
    this.variant = CoreCarouselVariant.slide,
    this.direction = CoreAxis.horizontal,
    this.carouselStyle,
  });

  final CoreCarouselVariant variant;
  final CoreAxis direction;
  final CoreCarouselStyle? carouselStyle;

  @override
  Component build(BuildContext context) {
    _seen = resolveCarousel(
      context,
      alignment: CoreCarouselAlignment.center,
      animate: true,
      curve: CoreEasing.easeInOut,
      direction: direction,
      gap: 0,
      variant: variant,
      itemCount: _kSlides,
      mode: CoreCarouselTransitionMode.sliding,
      progress: 0,
      sizeConstraint: const CoreCarouselSizeConstraint.fractional(1),
      slidePositions: const [0, 1, 2],
      speed: CoreCarouselStyle.defaultTransitionSpeed,
      wrap: true,
      carouselStyle: carouselStyle,
    );

    return const Component.text('x');
  }
}

Future<ResolvedCarousel> _resolve(
  ComponentTester tester,
  _Capture capture,
) async {
  pumpWithTheme(tester, capture);
  await tester.pump();

  return _seen;
}

Set<String> _tokens(WebElementChrome chrome) =>
    chrome.className.split(' ').where((c) => c.isNotEmpty).toSet();

Map<String, String> _props(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

void main() {
  group('the reveal rides an anchor, never the Button', () {
    testComponents('the anchor carries the hover reveal and its clock', (
      tester,
    ) async {
      final resolved = await _resolve(tester, const _Capture());

      for (final anchor in [resolved.prevNavReveal, resolved.nextNavReveal]) {
        expect(
          _tokens(anchor),
          containsAll([
            'absolute',
            'opacity-0',
            'group-hover:opacity-100',
            'group-focus-within:opacity-100',
            'transition-opacity',
          ]),
        );
        expect(
          _props(anchor)['transition-duration'],
          durationMsCss(
            CoreCarouselStyle.defaultNavFadeDuration.inMilliseconds,
          ),
        );
        expect(
          _props(anchor)['transition-timing-function'],
          CoreEasing.move.toVarCss(),
        );
      }
    });

    testComponents('the Button chrome names no opacity, transition or place', (
      tester,
    ) async {
      final resolved = await _resolve(tester, const _Capture());

      for (final button in [resolved.prevNavButton, resolved.nextNavButton]) {
        final classes = _tokens(button);
        // The Button owns its `transition`; a second declaration here is the
        // one that gets overridden and leaves the buttons snapping on.
        expect(classes.where((c) => c.contains('opacity')), isEmpty);
        expect(classes.where((c) => c.contains('transition')), isEmpty);
        expect(classes.where((c) => c.contains('translate')), isEmpty);
        expect(classes, isNot(contains('absolute')));
        expect(_props(button).containsKey('transition-duration'), isFalse);
        // The cast is the Button's own, from the style's `boxShadow` — a
        // second `shadow-*` class here would stack one on top of it.
        expect(classes.where((c) => c.startsWith('shadow')), isEmpty);
      }
      expect(resolved.navButtonStyle.boxShadow, CoreShadow.sm);
    });

    testComponents('the face the Button draws is the style, edge included', (
      tester,
    ) async {
      final resolved = await _resolve(tester, const _Capture());

      expect(
        resolved.navButtonStyle.backgroundColor,
        const CoreColor.token(CoreColors.surfaceRaised),
      );
      expect(
        resolved.navButtonStyle.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(resolved.navButtonStyle.borderWidth, CoreStrokeWidth.stroke1);
    });

    testComponents(
      'the dots take the carousel tone unless a colour is stated',
      (
        tester,
      ) async {
        final defaults = await _resolve(tester, const _Capture());
        expect(
          defaults.dotIndicatorStyle.activeColor,
          const CoreColor.token(CoreColors.primary),
        );
        expect(
          defaults.dotIndicatorStyle.inactiveColor,
          const CoreColor.token(CoreColors.outline),
        );

        const stated = CoreColor.token(CoreColors.tertiary);
        final overridden = await _resolve(
          tester,
          const _Capture(
            carouselStyle: CoreCarouselStyle(
              indicatorActiveColor: stated,
              indicatorInactiveColor: stated,
            ),
          ),
        );
        expect(overridden.dotIndicatorStyle.activeColor, stated);
        expect(overridden.dotIndicatorStyle.inactiveColor, stated);
      },
    );

    testComponents('the prev ↔ next gap is the default four unless stated', (
      tester,
    ) async {
      expect(
        (await _resolve(tester, const _Capture())).navGapStyle,
        CoreCarouselStyle.defaultNavGapStyle,
      );
      final stated = await _resolve(
        tester,
        const _Capture(
          carouselStyle: CoreCarouselStyle(navGapStyle: CoreGapStyle(size: 8)),
        ),
      );
      expect(stated.navGapStyle.size, 8);
    });

    testComponents('a token-step fade keeps its duration variable', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        const _Capture(
          carouselStyle: CoreCarouselStyle(
            navFadeDuration: Duration(milliseconds: CoreDuration.ms300),
          ),
        ),
      );

      // Reaches `prefers-reduced-motion`, the way the Flutter twin's
      // `resolveMotionDuration` does.
      expect(
        _props(resolved.prevNavReveal)['transition-duration'],
        'var(--coui-duration-${CoreDuration.ms300})',
      );
    });

    testComponents('an off-scale display-tier fade remains literal', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        const _Capture(
          carouselStyle: CoreCarouselStyle(navFadeDuration: _kOffScaleFade),
        ),
      );

      expect(
        _props(resolved.nextNavReveal)['transition-duration'],
        durationMsCss(_kOffScaleFade.inMilliseconds),
      );
    });

    testComponents('the anchors sit on the leading and trailing sides', (
      tester,
    ) async {
      final horizontal = await _resolve(tester, const _Capture());
      expect(_props(horizontal.prevNavReveal), contains('left'));
      expect(_props(horizontal.nextNavReveal), contains('right'));
      expect(_tokens(horizontal.prevNavReveal), contains('top-1/2'));

      final vertical = await _resolve(
        tester,
        const _Capture(direction: CoreAxis.vertical),
      );
      expect(_props(vertical.prevNavReveal), contains('top'));
      expect(_props(vertical.nextNavReveal), contains('bottom'));
      expect(_tokens(vertical.prevNavReveal), contains('left-1/2'));
    });

    testComponents('a surface colour override moves to the Button inline', (
      tester,
    ) async {
      final defaults = await _resolve(tester, const _Capture());
      expect(
        _tokens(defaults.prevNavButton).where((c) => c.startsWith('bg-')),
        isNotEmpty,
      );
      expect(defaults.prevNavButton.inlineStyles, isNull);

      final overridden = await _resolve(
        tester,
        const _Capture(
          carouselStyle: CoreCarouselStyle(
            controlOverlayColor: CoreColor.token(CoreColors.primary),
          ),
        ),
      );
      expect(
        _tokens(overridden.prevNavButton).where((c) => c.startsWith('bg-')),
        isEmpty,
      );
      expect(_props(overridden.prevNavButton), contains('background-color'));
    });
  });

  group('the hover region is the whole carousel', () {
    testComponents('overlay: the root is the viewport and the group', (
      tester,
    ) async {
      final resolved = await _resolve(tester, const _Capture());

      expect(_tokens(resolved.root), contains('group'));
    });

    testComponents('below: the root is the group, not just the viewport', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        const _Capture(variant: CoreCarouselVariant.banner),
      );

      // Flutter's `MouseRegion` wraps the dots under the viewport too, so the
      // pointer over them reveals the buttons. A `group` on the viewport
      // alone would leave them hidden there.
      expect(_tokens(resolved.root), contains('group'));
      expect(_tokens(resolved.viewport), isNot(contains('group')));
    });
  });

  group('rendered', () {
    testComponents('banner gathers both buttons in the trailing anchor', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Carousel(
          variant: CoreCarouselVariant.banner,
          showNavigation: true,
          items: [Text('a'), Text('b'), Text('c')],
          showIndicators: false,
        ),
      );
      await tester.pump();

      final buttons = find.byType(Button).evaluate().toList();
      expect(buttons, hasLength(2));

      Component? anchorOf(Element element) {
        Component? found;
        element.visitAncestorElements((ancestor) {
          final component = ancestor.component;
          if (component is DomComponent) {
            found = component;

            return false;
          }

          return true;
        });

        return found;
      }

      // One anchor holds the pair (not two), on the trailing side …
      final anchors = {for (final b in buttons) anchorOf(b)};
      expect(anchors, hasLength(1));
      final anchor = anchors.single! as DomComponent;
      expect(anchor.styles?.properties, contains('right'));
      expect(anchor.styles?.properties, isNot(contains('left')));
      expect(anchor.classes, contains('group-hover:opacity-100'));
      // … with the gap between the two buttons.
      expect(find.byType(Gap), findsOneComponent);
    });

    testComponents('slide keeps one anchor per button, no gap', (tester) async {
      pumpWithTheme(
        tester,
        const Carousel(
          showNavigation: true,
          items: [Text('a'), Text('b'), Text('c')],
          showIndicators: false,
        ),
      );
      await tester.pump();

      expect(find.byType(Button), findsNComponents(2));
      expect(find.byType(Gap), findsNothing);
    });

    testComponents('each Button sits in an anchor that carries the reveal', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Carousel(
          items: [Text('a'), Text('b'), Text('c')],
          showIndicators: false,
        ),
      );
      await tester.pump();

      final buttons = find.byType(Button).evaluate().toList();
      expect(buttons, hasLength(2));

      for (final element in buttons) {
        final button = element.component as Button;
        final own = button.classes ?? '';
        expect(own, isNot(contains('opacity')));
        expect(own, isNot(contains('transition')));

        String? anchorClasses;
        element.visitAncestorElements((ancestor) {
          final component = ancestor.component;
          if (component is DomComponent) {
            anchorClasses = component.classes;

            return false;
          }

          return true;
        });

        expect(anchorClasses, contains('group-hover:opacity-100'));
        expect(anchorClasses, contains('transition-opacity'));
      }
    });
  });
}
