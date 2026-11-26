import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// The focus ring's gap band is transparent by default — the gap shows
/// whatever is behind the control. A component turns it on (opaque
/// `surface`) only where its background is unknown: floating over
/// content, over a photo, on an inverse-surface slab, on a saturated fill.
/// A control on a known container tone (a code block's copy button) states
/// nothing and takes the plain ring.
///
/// These tests pin both halves for every component that turns it on —
/// that the opaque band reaches the slot the composed control reads, and
/// that the neighbouring case that must stay off does stay off.
void main() {
  const opaque = CoreFocusRing.opaqueOffsetColor;

  /// Pumps a probe and hands back whatever [resolve] reads from it.
  ///
  /// The harness mounts its child as an overlay entry, which a second
  /// `pumpWidget` in the same test does not rebuild — so the tree is
  /// cleared first and every call builds from scratch.
  Future<T> resolveIn<T>(
    WidgetTester tester,
    T Function(BuildContext context) resolve,
  ) async {
    late T value;
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) {
          value = resolve(context);
          return const SizedBox.shrink();
        },
      ),
    );
    return value;
  }

  group('band on', () {
    testWidgets('Fab — the circle and the extended pill', (tester) async {
      final resolved = await resolveIn(
        tester,
        (context) => resolveFab(context, size: CoreFabSize.defaultSize),
      );

      expect(resolved.buttonStyle.focusOutlineStyle?.offsetColor, opaque);
      expect(
        resolved.extendedButtonStyle.focusOutlineStyle?.offsetColor,
        opaque,
      );
    });

    testWidgets('Carousel prev / next — over the slide', (tester) async {
      final resolved = await resolveIn(tester, resolveCarousel);

      expect(resolved.navButtonStyle.focusOutlineStyle?.offsetColor, opaque);
    });

    testWidgets('Carousel dots — on only when they overlay the slide', (
      tester,
    ) async {
      final slide = await resolveIn(tester, resolveCarousel);
      final banner = await resolveIn(
        tester,
        (context) => resolveCarousel(context, variant: .banner),
      );

      expect(
        slide.dotIndicatorStyle.focusOutlineStyle?.offsetColor,
        opaque,
        reason: 'slide dots sit on whatever the slide shows',
      );
      expect(
        banner.dotIndicatorStyle.focusOutlineStyle,
        isNull,
        reason:
            'banner dots sit below the strip, on the page — the '
            "dot indicator's own transparent default applies",
      );
    });

    testWidgets('Carousel dots — a caller slot merges over the band', (
      tester,
    ) async {
      final resolved = await resolveIn(
        tester,
        (context) => resolveCarousel(
          context,
          carouselStyle: const CoreCarouselStyle(
            overlayIndicatorFocusOutlineStyle: CoreFocusOutlineStyle(
              offsetColor: CoreColor.transparent,
            ),
          ),
        ),
      );

      expect(
        resolved.dotIndicatorStyle.focusOutlineStyle?.offsetColor,
        CoreColor.transparent,
      );
    });

    testWidgets('Toast — the close button and a Button action', (
      tester,
    ) async {
      final resolved = await resolveIn(
        tester,
        (context) => resolveToast(
          context,
          variant: CoreToastVariant.defaultVariant,
          dismissible: true,
        ),
      );

      expect(resolved.closeButtonStyle.focusOutlineStyle?.offsetColor, opaque);
      expect(
        resolved.actionButtonStyle.focusOutlineStyle?.offsetColor,
        opaque,
      );
    });

    testWidgets("Toast — a caller's action band still wins", (tester) async {
      final resolved = await resolveIn(
        tester,
        (context) => resolveToast(
          context,
          variant: CoreToastVariant.defaultVariant,
          dismissible: true,
          toastStyle: const CoreToastStyle(
            actionButtonStyle: CoreButtonStyle(
              focusOutlineStyle: CoreFocusOutlineStyle(
                offsetColor: CoreColor.transparent,
              ),
            ),
          ),
        ),
      );

      expect(
        resolved.actionButtonStyle.focusOutlineStyle?.offsetColor,
        CoreColor.transparent,
      );
    });

    testWidgets('CodeSnippet copy button — on its quiet face, no band', (
      tester,
    ) async {
      final resolved = await resolveIn(tester, resolveCodeSnippet);

      // No ring statement at all: the plain ring (transparent band) applies.
      expect(resolved.copyButtonStyle.focusOutlineStyle, isNull);
    });

    testWidgets('Banner — solid rows on, weak rows off', (tester) async {
      for (final variant in CoreBannerVariant.values) {
        final solid = await resolveIn(
          tester,
          (context) =>
              resolveBanner(context, variant: variant, emphasis: .solid),
        );
        final weak = await resolveIn(
          tester,
          (context) =>
              resolveBanner(context, variant: variant, emphasis: .weak),
        );

        expect(
          solid.closeButtonStyle.focusOutlineStyle?.offsetColor,
          opaque,
          reason: '$variant/solid close sits on a saturated fill',
        );
        expect(
          solid.actionButtonStyle.focusOutlineStyle?.offsetColor,
          opaque,
          reason: '$variant/solid action sits on a saturated fill',
        );
        expect(
          weak.closeButtonStyle.focusOutlineStyle?.offsetColor,
          isNot(opaque),
          reason: '$variant/weak close keeps the transparent default',
        );
        expect(
          weak.actionButtonStyle.focusOutlineStyle?.offsetColor,
          isNot(opaque),
          reason: '$variant/weak action keeps the transparent default',
        );
      }
    });

    testWidgets('Chip close button — every size', (tester) async {
      for (final size in CoreChipSize.values) {
        final resolved = await resolveIn(
          tester,
          (context) => resolveChip(
            context,
            variant: CoreChipVariant.outlined,
            chipColor: CoreChipColor.defaultColor,
            size: size,
            selected: false,
            emphasis: CoreChipEmphasis.defaultEmphasis,
            enabled: true,
          ),
        );

        expect(
          resolved.closeButtonStyle?.focusOutlineStyle?.offsetColor,
          opaque,
          reason: 'the size ladder must not drop the band ($size)',
        );
      }
    });
  });

  group('band reaches paint', () {
    /// The stroke colour of every gap band painted under [of].
    List<Color> bandColours(WidgetTester tester, Finder of) => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.descendant(of: of, matching: find.byType(FocusOutline)),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .whereType<ShapeDecoration>()
        .map((d) => (d.shape as RoundedRectangleBorder).side.color)
        .toList();

    testWidgets('a Fab paints an opaque surface band', (tester) async {
      late Color surface;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            surface = Theme.of(
              context,
            ).colorScheme.resolve(opaque).toValue();
            return Fab(trigger: const Icon(LucideIcons.plus), onPressed: () {});
          },
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      final _ = await tester.pumpAndSettle();

      expect(bandColours(tester, find.byType(Fab)), [surface]);
      expect(surface.a, greaterThan(0));
    });

    testWidgets('a CodeSnippet copy button paints a transparent band', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const CodeSnippet(code: "print('hi');", mode: 'dart'),
      );

      final colours = bandColours(tester, find.byType(CodeSnippet));
      expect(colours, hasLength(1));
      expect(colours.single.a, 0);
    });

    testWidgets('a plain Button paints a transparent band', (tester) async {
      await pumpTestApp(
        tester,
        Button(onPressed: () {}, child: const Text('Go')),
      );

      final colours = bandColours(tester, find.byType(Button));
      expect(colours, hasLength(1));
      expect(colours.single.a, 0);
    });
  });
}
