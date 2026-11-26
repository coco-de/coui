// The typography tier on Flutter — read back from the text an app draws at
// a viewport width, not from the theme that carries it.
//
// The tier reaches text only by having been folded into the theme's type
// scale, so a theme can carry it and a component can still draw the
// desktop size. These tests pump `CoUIApp` in a view of a given width and
// measure the laid-out paragraph.
//
// The numbers come from the vector table coui_core owns
// (`coui_core/test/fixtures/typography_tier_vectors.json`), which the Core,
// Web and Figma export tests read too: a tier that drifts on this platform
// fails against the numbers the others draw.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

const String kTypographyTierVectorsPath =
    '../coui_core/test/fixtures/typography_tier_vectors.json';

/// Every scaling axis at 1, so a measured size is the tier's and nothing
/// else.
ThemeData _themeWith({
  CoreTypography typography = CoreTypography.coui,
  double textScaling = 1,
}) => ThemeData.fromCore(
  CoreThemePresets.previewLight.copyWith(
    typography: typography,
    textScaling: textScaling,
    sizeScaling: 1,
    radiusScaling: 1,
  ),
);

final ThemeData _theme = _themeWith();

/// The Text chain getter that draws each role — the way an app names one.
final Map<CoreTextStyleToken, Widget Function(Text text)> _chain = {
  CoreTextStyles.displayLarge: (text) => text.displayLarge,
  CoreTextStyles.displayMedium: (text) => text.displayMedium,
  CoreTextStyles.displaySmall: (text) => text.displaySmall,
  CoreTextStyles.headlineLarge: (text) => text.headlineLarge,
  CoreTextStyles.headlineMedium: (text) => text.headlineMedium,
  CoreTextStyles.headlineSmall: (text) => text.headlineSmall,
  CoreTextStyles.titleLarge: (text) => text.titleLarge,
  CoreTextStyles.bodyMedium: (text) => text.bodyMedium,
  CoreTextStyles.codeSm: (text) => text.codeSm,
};

/// [text] drawn in [token]'s role through the Text chain, with the role's
/// name as its text so the paragraph can be found by it.
Widget _role(CoreTextStyleToken token, [String? text]) =>
    _chain[token]!(Text(text ?? token.name));

/// Sizes the test view to [width] logical px wide.
void _viewAt(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
}

Future<void> _pumpAt(
  WidgetTester tester,
  double width,
  Widget child, {
  ThemeData? theme,
  CoreBreakpointTier? typographyTier,
  CoreSurfaceStyleId surfaceStyle = CoreSurfaceStyleId.defaultId,
  AdaptiveScaling? scaling,
}) async {
  _viewAt(tester, width);
  await tester.pumpWidget(
    CoUIApp(
      theme: theme ?? _theme,
      surfaceStyle: surfaceStyle,
      typographyTier: typographyTier,
      scaling: scaling,
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// The style the paragraph showing [text] was laid out with.
TextStyle _laidOut(WidgetTester tester, String text) => tester
    .renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    )
    .text
    .style!;

void main() {
  final doc =
      jsonDecode(File(kTypographyTierVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final roles = (doc['roles']! as List).cast<Map<String, Object?>>();
  final widths = (doc['widths']! as List).cast<Map<String, Object?>>();

  CoreTextStyleToken tokenOf(Map<String, Object?> row) =>
      CoreTextStyles.values.singleWhere((token) => token.name == row['role']);

  /// The fixture's size and tracking (em) for [token] at [tier].
  (double, double) want(CoreTextStyleToken token, CoreBreakpointTier tier) {
    final row = roles.singleWhere((row) => tokenOf(row) == token);
    final cell = row[tier.name]! as Map<String, Object?>;

    return (
      (cell['size']! as num).toDouble(),
      (cell['trackingEm']! as num).toDouble(),
    );
  }

  /// Expects the paragraph named after [token] to draw at [tier]'s size and
  /// tracking, times [scale].
  void expectDrawnAt(
    WidgetTester tester,
    CoreTextStyleToken token,
    CoreBreakpointTier tier, {
    double scale = 1,
    String? text,
  }) {
    final (size, tracking) = want(token, tier);
    final style = _laidOut(tester, text ?? token.name);
    final reason = '${token.name} at ${tier.name}';
    expect(style.fontSize, size * scale, reason: reason);
    // Flutter takes tracking in px — the em the role states times the size
    // it draws at.
    expect(
      style.letterSpacing,
      moreOrLessEquals(tracking * size * scale),
      reason: reason,
    );
  }

  test('the vectors name a role this file can draw', () {
    expect(_chain.keys, containsAll(roles.map(tokenOf)));
  });

  group('the viewport width picks the tier', () {
    for (final row in widths) {
      final width = (row['width']! as num).toDouble();
      final tier = CoreBreakpointTier.values.byName(row['tier']! as String);
      // A view needs a width to lay text out in; Core's test reads the zero
      // row.
      if (width == 0) continue;

      testWidgets('a ${width}px view draws every role at ${tier.name}', (
        tester,
      ) async {
        await _pumpAt(
          tester,
          width,
          Column(
            mainAxisSize: .min,
            children: [for (final row in roles) _role(tokenOf(row))],
          ),
        );

        for (final row in roles) {
          expectDrawnAt(tester, tokenOf(row), tier);
        }
      });
    }
  });

  group('a pinned tier reads no width', () {
    testWidgets('desktop at 400px draws the sizes as authored', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        400,
        Column(
          mainAxisSize: .min,
          children: [for (final row in roles) _role(tokenOf(row))],
        ),
        typographyTier: .desktop,
      );

      for (final row in roles) {
        expectDrawnAt(tester, tokenOf(row), .desktop);
      }
    });

    testWidgets('mobile at 1200px draws the mobile sizes', (tester) async {
      await _pumpAt(
        tester,
        1200,
        _role(CoreTextStyles.displayLarge),
        typographyTier: .mobile,
      );

      expectDrawnAt(tester, CoreTextStyles.displayLarge, .mobile);
    });
  });

  group('the tier is a ratio, so it keeps the scaling either side of it', () {
    testWidgets('AdaptiveScaling(1.25) after it', (tester) async {
      await _pumpAt(
        tester,
        400,
        _role(CoreTextStyles.headlineSmall),
        scaling: const AdaptiveScaling(1.25),
      );

      // 16 at mobile, times 1.25.
      expect(_laidOut(tester, 'headline-small').fontSize, 20);
      expectDrawnAt(tester, CoreTextStyles.headlineSmall, .mobile, scale: 1.25);
    });

    testWidgets('the theme’s textScaling before it', (tester) async {
      await _pumpAt(
        tester,
        400,
        _role(CoreTextStyles.headlineSmall),
        theme: _themeWith(textScaling: 1.25),
      );

      expect(_laidOut(tester, 'headline-small').fontSize, 20);
      expectDrawnAt(tester, CoreTextStyles.headlineSmall, .mobile, scale: 1.25);
    });
  });

  testWidgets('a style’s weight floor lands on the stepped size', (
    tester,
  ) async {
    // A scale whose headings are regular, so neo-brutalism's semibold floor
    // has a weight to raise on the role the tier steps.
    final regular = CoreTypography.coui.map(
      (style) => style.copyWith(fontWeight: CoreFontWeight.regular),
    );
    await _pumpAt(
      tester,
      400,
      _role(CoreTextStyles.headlineSmall),
      theme: _themeWith(typography: regular),
      surfaceStyle: .neoBrutalism,
    );

    final style = _laidOut(tester, 'headline-small');
    expect(style.fontSize, 16);
    expect(style.fontWeight, FontWeight.w600);
  });

  testWidgets('the high-contrast theme takes the tier too', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    _viewAt(tester, 400);
    await tester.pumpWidget(
      CoUIApp(
        theme: _theme,
        highContrastTheme: _theme,
        home: Center(child: _role(CoreTextStyles.headlineSmall)),
      ),
    );
    await tester.pumpAndSettle();

    expectDrawnAt(tester, CoreTextStyles.headlineSmall, .mobile);
  });

  group('the theme is folded again only when the tier changes', () {
    late int builds;

    Future<void> pumpCounting(WidgetTester tester, double width) async {
      _viewAt(tester, width);
      await tester.pumpWidget(
        CoUIApp(
          theme: _theme,
          enableThemeAnimation: false,
          builder: (context, child) {
            builds++;
            return child!;
          },
          home: Center(child: _role(CoreTextStyles.headlineSmall)),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> resize(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
    }

    testWidgets('a resize inside one tier runs the builder no more', (
      tester,
    ) async {
      builds = 0;
      await pumpCounting(tester, 1100);
      final before = builds;

      await resize(tester, 1050);

      expect(builds, before);
      expectDrawnAt(tester, CoreTextStyles.headlineSmall, .desktop);
    });

    testWidgets('a resize into another tier runs it once', (tester) async {
      builds = 0;
      await pumpCounting(tester, 1100);
      final before = builds;

      await resize(tester, 900);

      expect(builds, before + 1);
      expectDrawnAt(tester, CoreTextStyles.headlineSmall, .tablet);
    });

    testWidgets('a pinned tier runs it no more across tiers', (tester) async {
      builds = 0;
      _viewAt(tester, 1100);
      await tester.pumpWidget(
        CoUIApp(
          theme: _theme,
          typographyTier: .desktop,
          enableThemeAnimation: false,
          builder: (context, child) {
            builds++;
            return child!;
          },
          home: Center(child: _role(CoreTextStyles.headlineSmall)),
        ),
      );
      await tester.pumpAndSettle();
      final before = builds;

      await resize(tester, 500);

      expect(builds, before);
      expectDrawnAt(tester, CoreTextStyles.headlineSmall, .desktop);
    });
  });

  group('TypographyTierScope', () {
    testWidgets('renders a subtree of a mobile app at desktop', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        400,
        Column(
          mainAxisSize: .min,
          children: [
            _role(CoreTextStyles.headlineSmall, 'around'),
            TypographyTierScope(
              tier: .desktop,
              child: _role(CoreTextStyles.headlineSmall, 'inside'),
            ),
          ],
        ),
      );

      expectDrawnAt(
        tester,
        CoreTextStyles.headlineSmall,
        .mobile,
        text: 'around',
      );
      expectDrawnAt(
        tester,
        CoreTextStyles.headlineSmall,
        .desktop,
        text: 'inside',
      );
    });

    testWidgets('takes the scale the app folded for that tier', (
      tester,
    ) async {
      // The surroundings are already stepped down, so stepping them again
      // could not reach desktop; the scope has to read the app's fold —
      // which carries the scaling as well.
      await _pumpAt(
        tester,
        400,
        TypographyTierScope(
          tier: .desktop,
          child: _role(CoreTextStyles.headlineSmall),
        ),
        scaling: const AdaptiveScaling(1.25),
      );

      expectDrawnAt(
        tester,
        CoreTextStyles.headlineSmall,
        .desktop,
        scale: 1.25,
      );
    });

    testWidgets('renders a subtree of a desktop app at mobile', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        1200,
        TypographyTierScope(
          tier: .mobile,
          child: _role(CoreTextStyles.displayLarge),
        ),
      );

      expectDrawnAt(tester, CoreTextStyles.displayLarge, .mobile);
    });

    testWidgets('outside CoUIApp steps the surrounding scale', (
      tester,
    ) async {
      _viewAt(tester, 1200);
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: Theme(
            data: _theme,
            child: TypographyTierScope(
              tier: .tablet,
              child: _role(CoreTextStyles.headlineMedium),
            ),
          ),
        ),
      );

      expectDrawnAt(tester, CoreTextStyles.headlineMedium, .tablet);
    });

    group('finds the tier of the scale around it', () {
      // The scope recognises the scale around it among the ones the app
      // published, and picks the app's scale at its tier only then. A
      // widget between the app and the scope that changes the scale — a
      // scaler, a subtree theme — must not lose what it changed.
      for (final width in [1200.0, 400.0]) {
        testWidgets('under an AdaptiveScaler at ${width}px', (tester) async {
          await _pumpAt(
            tester,
            width,
            AdaptiveScaler(
              scaling: const AdaptiveScaling(1.25),
              child: TypographyTierScope(
                tier: .desktop,
                child: _role(CoreTextStyles.headlineLarge),
              ),
            ),
          );

          expectDrawnAt(
            tester,
            CoreTextStyles.headlineLarge,
            .desktop,
            scale: 1.25,
          );
        });

        testWidgets('under a subtree theme of its own at ${width}px', (
          tester,
        ) async {
          // A scale the app never published is the subtree's, authored at
          // desktop: a desktop scope leaves it — its face and its sizes —
          // as it is.
          await _pumpAt(
            tester,
            width,
            Builder(
              builder: (context) => Theme(
                data: Theme.of(context).copyWith(
                  typography: () =>
                      CoreTypography.coui.withFamily('Brand Display'),
                ),
                child: TypographyTierScope(
                  tier: .desktop,
                  child: _role(CoreTextStyles.headlineLarge),
                ),
              ),
            ),
          );

          expectDrawnAt(tester, CoreTextStyles.headlineLarge, .desktop);
          expect(
            _laidOut(tester, 'headline-large').fontFamily,
            'Brand Display',
          );
        });
      }

      testWidgets('under a subtree theme that changed the app scale', (
        tester,
      ) async {
        // A face set on the app's own scale below the app — its sizes are
        // still the mobile ones, so the scope steps it up from there and
        // keeps the face.
        await _pumpAt(
          tester,
          400,
          Builder(
            builder: (context) {
              final theme = Theme.of(context);

              return Theme(
                data: theme.copyWith(
                  typography: () =>
                      theme.typography.withFamily('Brand Display'),
                ),
                child: TypographyTierScope(
                  tier: .desktop,
                  child: _role(CoreTextStyles.headlineLarge),
                ),
              );
            },
          ),
        );

        expectDrawnAt(tester, CoreTextStyles.headlineLarge, .desktop);
        expect(_laidOut(tester, 'headline-large').fontFamily, 'Brand Display');
      });

      testWidgets('halfway through a theme switch', (tester) async {
        // The theme switches its type scale halfway through the animation,
        // and the published scales are the new theme's from the first
        // frame: the scale around the scope is the old one, at the same
        // sizes.
        final regular = CoreTypography.coui.map(
          (style) => style.copyWith(fontWeight: CoreFontWeight.regular),
        );
        Widget app(CoreSurfaceStyleId style) => CoUIApp(
          theme: _themeWith(typography: regular),
          surfaceStyle: style,
          home: Center(
            child: TypographyTierScope(
              tier: .desktop,
              child: _role(CoreTextStyles.headlineLarge),
            ),
          ),
        );
        _viewAt(tester, 400);
        await tester.pumpWidget(app(CoreSurfaceStyleId.defaultId));
        await tester.pumpAndSettle();

        await tester.pumpWidget(app(.neoBrutalism));
        await tester.pump(const Duration(milliseconds: 20));

        expectDrawnAt(tester, CoreTextStyles.headlineLarge, .desktop);
      });

      testWidgets('in a panel opened under an AdaptiveScaler', (
        tester,
      ) async {
        // The panel takes the theme of the place it opened from; the
        // scales published beside that theme travel with it.
        await _pumpAt(
          tester,
          400,
          AdaptiveScaler(
            scaling: const AdaptiveScaling(1.25),
            child: _role(CoreTextStyles.bodyMedium, 'anchor'),
          ),
        );
        unawaited(
          showDialog<void>(
            context: tester.element(find.text('anchor')),
            builder: (_) => TypographyTierScope(
              tier: .desktop,
              child: _role(CoreTextStyles.headlineLarge, 'panel'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expectDrawnAt(
          tester,
          CoreTextStyles.headlineLarge,
          .desktop,
          scale: 1.25,
          text: 'panel',
        );
      });
    });

    testWidgets('reaches a panel opened inside it', (tester) async {
      // The panel is mounted on the overlay, outside the scope; it takes the
      // theme of the place it opened from. The Web twin states the scope
      // again around its portalled panel to draw the same size.
      final controller = PopoverController();
      addTearDown(controller.dispose);
      await _pumpAt(
        tester,
        400,
        Column(
          mainAxisSize: .min,
          children: [
            _role(CoreTextStyles.headlineSmall, 'page'),
            TypographyTierScope(
              tier: .desktop,
              child: Popover(
                controller: controller,
                openTrigger: CorePopoverTrigger.manual,
                trigger: _role(CoreTextStyles.bodyMedium, 'trigger'),
                content: _role(CoreTextStyles.headlineSmall, 'panel'),
              ),
            ),
          ],
        ),
      );

      controller.show();
      // The panel follows its trigger every tick, so it never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expectDrawnAt(
        tester,
        CoreTextStyles.headlineSmall,
        .mobile,
        text: 'page',
      );
      expectDrawnAt(
        tester,
        CoreTextStyles.headlineSmall,
        .desktop,
        text: 'panel',
      );
      expect(
        find.ancestor(
          of: find.text('panel'),
          matching: find.byType(TypographyTierScope),
        ),
        findsNothing,
        reason: 'the panel is on the overlay, not under the scope',
      );

      controller.close();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('a BrightnessScope keeps the tier around it', (tester) async {
      await _pumpAt(
        tester,
        400,
        BrightnessScope(
          brightness: .dark,
          child: _role(CoreTextStyles.headlineSmall),
        ),
      );

      expectDrawnAt(tester, CoreTextStyles.headlineSmall, .mobile);
    });
  });

  // #6464: the lg digit is the `headlineSmall` role, which a mobile viewport
  // shrinks — but it fills a cell no tier changes, so the field pins it.
  group('an InputOtp holds its digit cells to desktop', () {
    testWidgets('the lg digit draws 24 semi-bold at a mobile width', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        400,
        Column(
          mainAxisSize: .min,
          children: [
            const InputOtp(
              length: 2,
              separatorInterval: 0,
              initialValue: [55, null],
              size: .lg,
            ),
            _role(CoreTextStyles.headlineSmall),
          ],
        ),
      );

      expectDrawnAt(tester, CoreTextStyles.headlineSmall, .desktop, text: '7');
      expect(_laidOut(tester, '7').fontSize, CoreFontSize.s24);
      expect(_laidOut(tester, '7').fontWeight, FontWeight.w600);
      // Beside it, the same role through the Text chain is at mobile — the
      // tier is in effect, the field just does not take it.
      expectDrawnAt(tester, CoreTextStyles.headlineSmall, .mobile);
    });
  });

  group('an avatar holds its own box to desktop', () {
    testWidgets('its initials keep their desktop size at every width', (
      tester,
    ) async {
      // The initials fill a disc whose diameter no tier changes. Beside them,
      // the same role through the Text chain shows the tier is in effect.
      await _pumpAt(
        tester,
        400,
        Column(
          mainAxisSize: .min,
          children: [
            const Avatar(initials: 'AB', size: .xl2),
            _role(CoreTextStyles.headlineLarge),
          ],
        ),
      );

      expect(
        CoreAvatarStyle.fallbackRoleFor(.xl2).token,
        CoreTextStyles.headlineLarge,
      );
      expectDrawnAt(tester, CoreTextStyles.headlineLarge, .desktop, text: 'AB');
      expectDrawnAt(tester, CoreTextStyles.headlineLarge, .mobile);
    });

    testWidgets('its badge is inside the same pin', (tester) async {
      // The Web twin pins the badge slot too: a caller's heading in the
      // badge draws at desktop on both platforms.
      await _pumpAt(
        tester,
        400,
        Avatar(
          initials: 'AB',
          size: .xl,
          badge: _role(CoreTextStyles.headlineSmall, 'badge'),
        ),
      );

      expectDrawnAt(
        tester,
        CoreTextStyles.headlineSmall,
        .desktop,
        text: 'badge',
      );
    });

    testWidgets('its initials keep the scaling of an AdaptiveScaler', (
      tester,
    ) async {
      for (final width in [1200.0, 400.0]) {
        await _pumpAt(
          tester,
          width,
          const AdaptiveScaler(
            scaling: AdaptiveScaling(1.25),
            child: Avatar(initials: 'AB', size: .xl2),
          ),
        );

        // 32 × 1.25, in a disc the scaler grew by the same factor.
        expect(_laidOut(tester, 'AB').fontSize, 40, reason: '${width}px');
      }
    });

    testWidgets('its initials keep a subtree theme the app did not fold', (
      tester,
    ) async {
      // A pane that installs a theme of its own under an app folded with
      // another text scaling — the docs app's preview pane is one. The
      // initials are the pane's, not the app's.
      await _pumpAt(
        tester,
        400,
        Theme(
          data: _theme,
          child: const Avatar(initials: 'AB', size: .xl),
        ),
        theme: _themeWith(textScaling: 1.15),
      );

      expectDrawnAt(tester, CoreTextStyles.headlineSmall, .desktop, text: 'AB');
    });
  });

  group('a time picker holds its segment row to desktop', () {
    testWidgets('a value style that names a role keeps its desktop size', (
      tester,
    ) async {
      // The default digits are a style with no role — a fixed 44 no tier
      // reaches — so the pin shows on a value style that names one. Beside
      // the picker, the same role through the Text chain shows the tier is
      // in effect.
      await _pumpAt(
        tester,
        400,
        Column(
          mainAxisSize: .min,
          children: [
            const TimePicker(
              value: '10:30',
              timePickerStyle: CoreTimePickerStyle(
                valueTypography: CoreTextStyle.token(
                  CoreTextStyles.displaySmall,
                ),
              ),
            ),
            _role(CoreTextStyles.displaySmall),
          ],
        ),
      );

      await tester.tap(find.byType(TimePicker));
      // The panel mounts through a post-frame callback and follows its
      // trigger every tick, so it never settles — pump until the segments
      // exist.
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(EditableText).evaluate().isNotEmpty) break;
      }
      expect(find.byType(EditableText), findsWidgets);

      expectDrawnAt(tester, CoreTextStyles.displaySmall, .mobile);
      // The colon states its own role, so the pin shows on it too.
      expectDrawnAt(tester, CoreTextStyles.headlineSmall, .desktop, text: ':');
      // The trigger is a read-only field too; the digits are the editable ones.
      for (final segment
          in tester
              .widgetList<EditableText>(
                find.byType(EditableText),
              )
              .where((segment) => !segment.readOnly)) {
        expect(
          segment.style.fontSize,
          want(CoreTextStyles.displaySmall, .desktop).$1,
          reason: 'the ${segment.controller.text} segment',
        );
      }
    });
  });
}
