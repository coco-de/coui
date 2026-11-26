// The focus-ring gap band is transparent by default and painted only where
// a component states that its background is unknown. These tests follow
// each band-on composition from the parent resolver to the paint the
// composed child emits, and pin the two composers whose band depends on
// where the control sits (Banner emphasis, Carousel variant).
import 'package:coui_web/coui_web.dart';
// The Banner / Toast resolvers are internal chrome, not
// re-exported by the barrel — import them directly.
import 'package:coui_web/src/components/display/banner/banner_style.dart';
import 'package:coui_web/src/components/overlay/toast/toast_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolvers can be called
/// directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// The band layer a `surface`-painted gap emits beside a class-path
/// outline at the default geometry — spread by the same
/// `--coui-ring-offset` variable `outline-offset-2` resolves to.
const _kSurfaceBand = '0 0 0 var(--coui-ring-offset) rgb(var(--coui-surface))';

/// The band a `Button` built from [buttonStyle] publishes, or null when
/// it paints none — read off the same chrome the browser receives: the
/// marker class that gates the shared focus rule, and the custom property
/// that rule reads.
String? _buttonBand(BuildContext context, CoreButtonStyle buttonStyle) {
  final resolved = resolveButton(
    context,
    variant: .plain,
    size: .md,
    shape: .rectangle,
    expanded: false,
    buttonStyle: buttonStyle,
  );
  final marked = resolved.root.className.split(' ').contains(kFocusBandMarker);
  final band = resolved.root.inlineStyles?.properties[kFocusBandVar];
  expect(
    marked,
    band != null,
    reason: 'the marker and the band value travel together',
  );
  return band;
}

void main() {
  group('the default band is transparent', () {
    testComponents('a plain Button publishes no band', (tester) async {
      final context = _themedContext(tester);
      expect(_buttonBand(context, const CoreButtonStyle()), isNull);
    });

    testComponents('CodeSnippet — the copy button on its quiet face', (
      tester,
    ) async {
      // The block sits on a container tone the ring already reads on, so the
      // copy button states no ring of its own and publishes no band.
      final context = _themedContext(tester);
      final snippet = resolveCodeSnippet(context, lineCount: 1);
      expect(snippet.copyButtonStyle.focusOutlineStyle, isNull);
      expect(_buttonBand(context, snippet.copyButtonStyle), isNull);
    });
  });

  group('components over an unknown background paint a surface band', () {
    testComponents('Fab — the circle and the extended pill', (tester) async {
      final context = _themedContext(tester);
      final fab = resolveFab(context, size: .defaultSize);
      expect(_buttonBand(context, fab.buttonStyle), _kSurfaceBand);
      expect(_buttonBand(context, fab.extendedButtonStyle), _kSurfaceBand);
    });

    testComponents('Chip — the close button', (tester) async {
      final context = _themedContext(tester);
      final chip = resolveChip(
        context,
        variant: CoreChipVariant.outlined,
        chipColor: .defaultColor,
        size: .defaultSize,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: true,
      );
      expect(_buttonBand(context, chip.closeButtonStyle!), _kSurfaceBand);
    });

    testComponents('Toast — the close button and a Button action', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final toast = resolveToast(
        context,
        variant: .defaultVariant,
        dismissible: true,
      );
      expect(_buttonBand(context, toast.closeButtonStyle), _kSurfaceBand);
      expect(_buttonBand(context, toast.actionButtonStyle), _kSurfaceBand);
    });

    testComponents(
      "Toast — the action's own buttonStyle still wins over the band",
      (tester) async {
        final context = _themedContext(tester);
        final toast = resolveToast(
          context,
          variant: .defaultVariant,
          dismissible: true,
          toastStyle: const CoreToastStyle(
            actionButtonStyle: CoreButtonStyle(
              focusOutlineStyle: CoreFocusOutlineStyle(
                offsetColor: CoreFocusRing.ringOffsetColor,
              ),
            ),
          ),
        );
        expect(_buttonBand(context, toast.actionButtonStyle), isNull);
      },
    );

    testComponents('Carousel — the prev / next buttons over the slides', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const navStyle = CoreCarouselStyle.defaultPrevNextButtonStyle;
      expect(_buttonBand(context, navStyle), _kSurfaceBand);
    });
  });

  group('Banner — the band follows the emphasis row', () {
    for (final variant in CoreBannerVariant.values) {
      testComponents('$variant solid: close and action paint the band', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final banner = resolveBanner(
          context,
          variant: variant,
          emphasis: .solid,
        );
        expect(_buttonBand(context, banner.closeButtonStyle), _kSurfaceBand);
        expect(_buttonBand(context, banner.actionButtonStyle), _kSurfaceBand);
      });

      testComponents('$variant weak: close and action keep it transparent', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final banner = resolveBanner(
          context,
          variant: variant,
          emphasis: .weak,
        );
        expect(_buttonBand(context, banner.closeButtonStyle), isNull);
        expect(_buttonBand(context, banner.actionButtonStyle), isNull);
      });
    }
  });

  group('Carousel dots — the band follows where the dots sit', () {
    ResolvedCarousel resolve(
      BuildContext context,
      CoreCarouselVariant variant, {
      CoreCarouselStyle? carouselStyle,
    }) => resolveCarousel(
      context,
      carouselStyle: carouselStyle,
      alignment: .center,
      animate: false,
      curve: CoreEasing.move,
      direction: .horizontal,
      gap: 0,
      variant: variant,
      itemCount: 3,
      mode: .sliding,
      progress: 0,
      sizeConstraint: const CoreCarouselFractionalConstraint(1),
      slidePositions: const [0, 1, 2],
      speed: const Duration(milliseconds: CoreDuration.normal),
      wrap: false,
    );

    DotIndicator composedDots(
      ComponentTester tester,
      CoreCarouselVariant variant, {
      CoreCarouselStyle? style,
    }) {
      pumpWithTheme(
        tester,
        Carousel(
          items: [
            for (var i = 0; i < 3; i++) div([Text('Slide $i')]),
          ],
          variant: variant,
          wrap: false,
          autoPlay: false,
          draggable: false,
          showNavigation: false,
          carouselStyle: style,
        ),
      );
      final dots =
          find.byType(DotIndicator).evaluate().single.component as DotIndicator;
      expect(dots.length, 3);
      expect(dots.onChanged, isNotNull);
      return dots;
    }

    testComponents('slide: the dots overlay the slide and paint the band', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final dots = resolve(context, .slide).dotIndicatorStyle;
      expect(
        dots.focusOutlineStyle,
        CoreCarouselStyle.defaultOverlayIndicatorFocusOutlineStyle,
      );
      expect(
        composedDots(tester, .slide).dotIndicatorStyle?.focusOutlineStyle,
        CoreCarouselStyle.defaultOverlayIndicatorFocusOutlineStyle,
      );
    });

    testComponents('banner: the dots sit on the page and stay transparent', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final dots = resolve(context, .banner).dotIndicatorStyle;
      expect(dots.focusOutlineStyle, isNull);
      expect(
        composedDots(tester, .banner).dotIndicatorStyle?.focusOutlineStyle,
        isNull,
      );
    });

    testComponents('slide: a caller slot merges over the band', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final dots = resolve(
        context,
        .slide,
        carouselStyle: const CoreCarouselStyle(
          overlayIndicatorFocusOutlineStyle: CoreFocusOutlineStyle(
            offsetColor: CoreColor.transparent,
          ),
        ),
      ).dotIndicatorStyle;
      expect(dots.focusOutlineStyle?.offsetColor, CoreColor.transparent);
      final actual = composedDots(
        tester,
        .slide,
        style: const CoreCarouselStyle(
          overlayIndicatorFocusOutlineStyle: CoreFocusOutlineStyle(
            offsetColor: CoreColor.transparent,
          ),
        ),
      );
      expect(
        actual.dotIndicatorStyle?.focusOutlineStyle?.offsetColor,
        CoreColor.transparent,
      );
    });
  });
}
