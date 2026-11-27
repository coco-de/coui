import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child, {ThemeData theme = const ThemeData()}) {
  return material.MaterialApp(
    home: Theme(data: theme, child: child),
  );
}

/// Resolves a badge the way the widget does, under [theme], and hands back
/// both the paint-ready output and the theme it resolved under.
Future<({ResolvedBadge resolved, ThemeData theme})> _resolve(
  WidgetTester tester, {
  CoreBadgeTone tone = CoreBadgeTone.defaultTone,
  CoreBadgeVariant variant = CoreBadgeVariant.defaultVariant,
  CoreBadgeForm form = CoreBadgeForm.defaultForm,
  CoreComponentSize size = CoreBadgeContract.defaultSize,
  CoreBadgeStyle? badgeStyle,
  ThemeData theme = const ThemeData(),
}) async {
  late ResolvedBadge resolved;
  late ThemeData resolvedUnder;
  await tester.pumpWidget(
    _buildApp(
      theme: theme,
      Builder(
        builder: (context) {
          resolvedUnder = Theme.of(context);
          resolved = resolveBadge(
            context,
            tone: tone,
            variant: variant,
            form: form,
            size: size,
            badgeStyle: badgeStyle,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return (resolved: resolved, theme: resolvedUnder);
}

/// The badge's own box — the one `AnimatedContainer` it paints.
Finder _box() => find.descendant(
  of: find.byType(Badge),
  matching: find.byType(AnimatedContainer),
);

/// The fill the badge's box is painting right now.
Color? _paintedFill(WidgetTester tester) =>
    (tester.widget<AnimatedContainer>(_box()).decoration! as BoxDecoration)
        .color;

/// The leading status dots under the badge — circles it draws itself.
Finder _leadingDots() => find.descendant(
  of: find.byType(Badge),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle,
  ),
);

// The same arithmetic the resolver performs, restated from the colours it
// hands back so the expectation is not read off the code under test. The
// composite lands on 8-bit channels, the way it is painted (and the way the
// Web twin's `color-mix()` is), so the expectation is rounded the same way.
Color _wash(Color ink, Color fill, double weight) =>
    Color(Color.alphaBlend(ink.withValues(alpha: weight), fill).toARGB32());

/// Makes `Clickable` report hover. It reports it through
/// `FocusableActionDetector`, which shows a hover highlight only under the
/// traditional strategy — and the test binding starts in touch mode.
void _traditionalHighlights() {
  final previous = material.FocusManager.instance.highlightStrategy;
  material.FocusManager.instance.highlightStrategy = .alwaysTraditional;
  addTearDown(
    () => material.FocusManager.instance.highlightStrategy = previous,
  );
}

void main() {
  group('bounded label layout', () {
    for (final (mode, theme) in [
      ('light', CoreThemePresets.light),
      ('dark', CoreThemePresets.dark),
    ]) {
      for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
        for (final scale in [1.0, 2.0]) {
          for (final interactive in [false, true]) {
            testWidgets(
              '$mode $direction $scale interactive=$interactive wraps',
              (tester) async {
                const label = 'A long review label without truncation';
                var presses = 0;
                await tester.pumpWidget(
                  _buildApp(
                    theme: ThemeData.fromCore(theme),
                    MediaQuery(
                      data: MediaQueryData(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: Directionality(
                        textDirection: direction,
                        child: Center(
                          child: SizedBox(
                            width: 140,
                            child: Badge(
                              showDot: true,
                              leading: const SizedBox(width: 12, height: 12),
                              trailing: const SizedBox(width: 12, height: 12),
                              onPressed: interactive ? () => presses++ : null,
                              child: const Text(label),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                expect(tester.getSize(_box()).width, lessThanOrEqualTo(140));
                expect(
                  tester.getSize(find.text(label)).height,
                  greaterThan(24),
                );
                if (interactive) {
                  await tester.tap(find.text(label));
                  expect(presses, 1);
                }
              },
            );
          }
        }
      }
    }
    for (final scale in [1.0, 2.0]) {
      testWidgets('preserves an existing caller Flexible label $scale', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const Center(
                child: SizedBox(
                  width: 140,
                  child: Badge(
                    child: Flexible(
                      child: Text('A long existing flexible label'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(_box()).width, lessThanOrEqualTo(140));
        expect(find.text('A long existing flexible label'), findsOneWidget);
      });
    }
    testWidgets('an unconstrained row keeps intrinsic label width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Badge(child: Text('Tag'))],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_box()).width, lessThan(100));
    });
  });
  group('defaults', () {
    test('a bare badge is neutral · tonal · label · md, no dot', () {
      const badge = Badge(child: Text('Tag'));

      expect(badge.tone, CoreBadgeTone.neutral);
      expect(badge.variant, CoreBadgeVariant.tonal);
      expect(badge.form, CoreBadgeForm.label);
      expect(badge.size, CoreComponentSize.md);
      expect(badge.showDot, isFalse);
      // The widget reads the Core constants rather than restating them, so
      // the defaults cannot drift between platforms.
      expect(badge.tone, CoreBadgeTone.defaultTone);
      expect(badge.variant, CoreBadgeVariant.defaultVariant);
      expect(badge.form, CoreBadgeForm.defaultForm);
      expect(badge.size, CoreBadgeContract.defaultSize);
      expect(badge.showDot, CoreBadgeContract.defaultShowDot);
    });

    testWidgets('renders the default at the md step, label weight', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const Center(child: Badge(child: Text('Tag')))),
      );
      await tester.pump();

      expect(find.text('Tag'), findsOneWidget);
      final md = CoreBadgeStyle.defaultsBySize[CoreComponentSize.md]!;
      expect(tester.getSize(_box()).height, md.minHeight);
      expect(_leadingDots(), findsNothing);
    });
  });

  group('resting colours come from the Core tone table', () {
    for (final (mode, theme) in [
      ('light', ThemeData.fromCore(CoreThemePresets.light)),
      ('dark', ThemeData.fromCore(CoreThemePresets.dark)),
    ]) {
      for (final tone in CoreBadgeTone.values) {
        final row = CoreBadgeStyle.defaultsByTone[tone]!;
        for (final variant in CoreBadgeVariant.values) {
          testWidgets('$mode · ${tone.name} · ${variant.name}', (
            tester,
          ) async {
            final (:resolved, theme: resolvedUnder) = await _resolve(
              tester,
              tone: tone,
              variant: variant,
              theme: theme,
            );
            Color paint(CoreColor color) =>
                resolvedUnder.colorScheme.resolve(color).toValue();

            final (fill, ink, line) = switch (variant) {
              CoreBadgeVariant.filled => (
                row.filledBackgroundColor,
                row.filledForegroundColor,
                null,
              ),
              CoreBadgeVariant.tonal => (
                row.tonalBackgroundColor,
                row.tonalForegroundColor,
                null,
              ),
              CoreBadgeVariant.outlined => (
                CoreBadgeStyle.defaultOutlinedBackgroundColor,
                row.outlinedForegroundColor,
                row.outlinedBorderColor,
              ),
            };

            expect(resolved.backgroundColor, paint(fill));
            expect(resolved.foregroundColor, paint(ink));
            expect(resolved.labelTextStyle.color, paint(ink));
            // The outlined status tones put the icon and leading dot in the
            // line's colour; every other strength keeps them on the label.
            final mark = variant == CoreBadgeVariant.outlined
                ? row.outlinedMarkColor ?? ink
                : ink;
            expect(resolved.iconColor, paint(mark));
            expect(resolved.leadingDotColor, paint(mark));
            expect(
              resolved.borderColor,
              line == null ? isNull : paint(line),
              reason: 'only outlined states a border',
            );
          });
        }
      }
    }

    testWidgets('the outlined fill is fully transparent', (tester) async {
      final (:resolved, theme: _) = await _resolve(
        tester,
        variant: CoreBadgeVariant.outlined,
      );

      expect(resolved.backgroundColor.a, 0);
    });

    testWidgets('the painted box carries the resolved fill and border', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: Badge(
              tone: CoreBadgeTone.success,
              variant: CoreBadgeVariant.outlined,
              child: Text('Done'),
            ),
          ),
        ),
      );
      await tester.pump();
      final context = tester.element(_box());
      final resolved = resolveBadge(
        context,
        tone: CoreBadgeTone.success,
        variant: CoreBadgeVariant.outlined,
        form: CoreBadgeForm.label,
        size: CoreComponentSize.md,
      );

      final decoration =
          tester.widget<AnimatedContainer>(_box()).decoration! as BoxDecoration;
      expect(decoration.color, resolved.backgroundColor);
      final border = decoration.border! as Border;
      expect(border.top.color, resolved.borderColor);
      expect(border.top.width, resolved.borderWidth);
    });
  });

  group('dot form', () {
    for (final tone in CoreBadgeTone.values) {
      testWidgets('${tone.name} paints its dot colour at every strength', (
        tester,
      ) async {
        for (final variant in CoreBadgeVariant.values) {
          final (:resolved, :theme) = await _resolve(
            tester,
            tone: tone,
            variant: variant,
            form: CoreBadgeForm.dot,
          );

          expect(
            resolved.backgroundColor,
            theme.colorScheme
                .resolve(CoreBadgeStyle.defaultsByTone[tone]!.dotColor)
                .toValue(),
            reason: '${variant.name} dot',
          );
          expect(resolved.borderColor, isNull, reason: 'a dot has no line');
          expect(resolved.padding, EdgeInsets.zero);
        }
      });
    }

    // Measured under `Center`: `MaterialApp.home` hands its child a TIGHT
    // full-viewport constraint, under which a box ignores its own size.
    testWidgets('is a circle of the step size and draws no content', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: Badge(
              form: CoreBadgeForm.dot,
              showDot: true,
              child: Text('should not render'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('should not render'), findsNothing);
      expect(_leadingDots(), findsNothing, reason: 'a dot is a dot already');
      final size = tester.getSize(_box());
      expect(size.width, CoreSize.size8);
      expect(size.height, CoreSize.size8);
    });

    testWidgets('each size step draws its own rung of the dot ladder', (
      tester,
    ) async {
      // `pumpAndSettle`: the box is an `AnimatedContainer`, so re-pumping
      // the same widget at a new size animates to it — one frame later it
      // still reports the previous step.
      Future<double> widthAt(CoreComponentSize size) async {
        await tester.pumpWidget(
          _buildApp(
            Center(
              child: Badge(form: CoreBadgeForm.dot, size: size),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getSize(_box()).width;
      }

      for (final size in [
        CoreComponentSize.xs,
        CoreComponentSize.sm,
        CoreComponentSize.md,
        CoreComponentSize.lg,
        CoreComponentSize.xl,
      ]) {
        expect(
          await widthAt(size),
          CoreBadgeStyle.defaultsBySize[size]!.dotSize,
          reason: size.name,
        );
      }
    });
  });

  group('box size and corner per form', () {
    for (final size in [
      CoreComponentSize.xs,
      CoreComponentSize.sm,
      CoreComponentSize.md,
      CoreComponentSize.lg,
      CoreComponentSize.xl,
    ]) {
      final row = CoreBadgeStyle.defaultsBySize[size]!;

      testWidgets('${size.name} label is the step tall and takes its corner', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            Center(
              child: Badge(size: size, child: const Text('Label')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.getSize(_box()).height, row.minHeight);
        final (:resolved, :theme) = await _resolve(tester, size: size);
        expect(
          resolved.borderRadius,
          row.borderRadius!.toValue(geometry: theme.geometry),
        );
        // Horizontal padding only — the height is the step, not the line
        // box plus padding.
        expect(resolved.padding.top, 0);
        expect(resolved.padding.bottom, 0);
        expect(
          resolved.padding,
          row.padding!.toValue(geometry: theme.geometry),
        );
      });

      testWidgets('${size.name} count is never narrower than it is tall', (
        tester,
      ) async {
        // A content narrower than the step minus its padding — what a single
        // digit is in the shipped font. A sized box rather than a digit,
        // because the test font sets every glyph a full em wide and would
        // make the badge wide for the wrong reason.
        const narrow = SizedBox(width: 2, height: 2);
        Future<Size> boxOf(CoreBadgeForm form) async {
          await tester.pumpWidget(
            _buildApp(
              Center(
                child: Badge(form: form, size: size, child: narrow),
              ),
            ),
          );
          await tester.pumpAndSettle();
          return tester.getSize(_box());
        }

        final count = await boxOf(CoreBadgeForm.count);
        expect(count.height, row.minHeight);
        expect(count.width, row.minHeight, reason: 'one digit is a circle');
        // The control: a label holding the same content has no width floor.
        final label = await boxOf(CoreBadgeForm.label);
        expect(label.width, lessThan(row.minHeight!));

        final (:resolved, theme: _) = await _resolve(
          tester,
          form: CoreBadgeForm.count,
          size: size,
        );
        expect(
          resolved.borderRadius,
          BorderRadius.circular(CoreRadius.radius9999),
          reason: 'a number takes the pill',
        );
      });
    }

    testWidgets('a long count grows past its height, centred content', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: Badge(form: CoreBadgeForm.count, child: Text('1280')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.getRect(_box());
      final text = tester.getRect(find.text('1280'));
      expect(box.width, greaterThan(box.height));
      expect(text.center.dx, moreOrLessEquals(box.center.dx, epsilon: 0.01));
      expect(text.center.dy, moreOrLessEquals(box.center.dy, epsilon: 0.01));
    });

    testWidgets('a single digit sits in the middle of its circle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: Badge(form: CoreBadgeForm.count, child: Text('3')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.getRect(_box());
      final text = tester.getRect(find.text('3'));
      expect(text.center.dx, moreOrLessEquals(box.center.dx, epsilon: 0.01));
      expect(text.center.dy, moreOrLessEquals(box.center.dy, epsilon: 0.01));
    });

    testWidgets('a dot takes the pill corner', (tester) async {
      final (:resolved, theme: _) = await _resolve(
        tester,
        form: CoreBadgeForm.dot,
      );

      expect(
        resolved.borderRadius,
        BorderRadius.circular(CoreRadius.radius9999),
      );
    });
  });

  group('typography — the step role with the form weight', () {
    testWidgets('a label is set at 500, a count at 600, same role size', (
      tester,
    ) async {
      final label = await _resolve(tester);
      final count = await _resolve(tester, form: CoreBadgeForm.count);
      final role = CoreBadgeStyle
          .defaultsBySize[CoreComponentSize.md]!
          .labelStyle!
          .toValue(theme: label.theme);

      expect(label.resolved.labelTextStyle.fontWeight, FontWeight.w500);
      expect(count.resolved.labelTextStyle.fontWeight, FontWeight.w600);
      expect(label.resolved.labelTextStyle.fontSize, role.fontSize);
      expect(count.resolved.labelTextStyle.fontSize, role.fontSize);
      expect(label.resolved.labelTextStyle.height, role.height);
    });

    testWidgets("a caller's label weight still wins", (tester) async {
      final (:resolved, theme: _) = await _resolve(
        tester,
        badgeStyle: const CoreBadgeStyle(
          labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.regular),
        ),
      );

      expect(resolved.labelTextStyle.fontWeight, FontWeight.w400);
    });
  });

  group('showDot', () {
    for (final form in [CoreBadgeForm.label, CoreBadgeForm.count]) {
      testWidgets(
        '${form.name}: a circle of leadingDotSize in the label colour, first',
        (tester) async {
          await tester.pumpWidget(
            _buildApp(
              Center(
                child: Badge(
                  tone: CoreBadgeTone.success,
                  form: form,
                  showDot: true,
                  leading: const Icon(LucideIcons.check),
                  child: const Text('Done'),
                ),
              ),
            ),
          );
          await tester.pump();
          final resolved = resolveBadge(
            tester.element(_box()),
            tone: CoreBadgeTone.success,
            variant: CoreBadgeVariant.defaultVariant,
            form: form,
            size: CoreComponentSize.md,
          );

          expect(_leadingDots(), findsOneWidget);
          final dot = tester.widget<DecoratedBox>(_leadingDots());
          expect(
            (dot.decoration as BoxDecoration).color,
            resolved.foregroundColor,
          );
          expect(
            tester.getSize(_leadingDots()).width,
            CoreBadgeStyle.defaultsBySize[CoreComponentSize.md]!.leadingDotSize,
          );
          // Drawn before the leading slot and the label.
          expect(
            tester.getCenter(_leadingDots()).dx,
            lessThan(tester.getCenter(find.byType(Icon)).dx),
          );
          expect(
            tester.getCenter(find.byType(Icon)).dx,
            lessThan(tester.getCenter(find.text('Done')).dx),
          );
        },
      );
    }

    testWidgets('each step draws its own leading-dot rung', (tester) async {
      for (final size in [
        CoreComponentSize.xs,
        CoreComponentSize.sm,
        CoreComponentSize.md,
        CoreComponentSize.lg,
        CoreComponentSize.xl,
      ]) {
        await tester.pumpWidget(
          _buildApp(
            Center(
              child: Badge(size: size, showDot: true, child: const Text('x')),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.getSize(_leadingDots()).width,
          CoreBadgeStyle.defaultsBySize[size]!.leadingDotSize,
          reason: size.name,
        );
      }
    });

    testWidgets('off by default', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Center(child: Badge(child: Text('x')))),
      );
      await tester.pump();

      expect(_leadingDots(), findsNothing);
    });
  });

  group('xl2 has a row of its own', () {
    testWidgets('a step above xl: taller, larger label', (tester) async {
      final xl = (await _resolve(tester, size: CoreComponentSize.xl)).resolved;
      final xl2 = (await _resolve(
        tester,
        size: CoreComponentSize.xl2,
      )).resolved;

      expect(xl2.constraints, isNot(xl.constraints));
      expect(
        xl2.labelTextStyle.fontSize,
        greaterThan(xl.labelTextStyle.fontSize!),
      );
    });

    testWidgets('renders at its own height', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: Badge(size: CoreComponentSize.xl2, child: Text('Big')),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(_box()).height,
        CoreBadgeStyle.defaultsBySize[CoreComponentSize.xl2]!.minHeight,
      );
    });
  });

  group('state layer', () {
    for (final variant in CoreBadgeVariant.values) {
      testWidgets(
        '${variant.name}: hover 8 %, pressed 16 % of the label colour',
        (tester) async {
          final (:resolved, theme: _) = await _resolve(
            tester,
            tone: CoreBadgeTone.info,
            variant: variant,
          );
          final ink = resolved.foregroundColor!;

          expect(
            resolved.hoverBackgroundColor,
            _wash(ink, resolved.backgroundColor, CoreStateLayer.standard.hover),
          );
          expect(
            resolved.pressedBackgroundColor,
            _wash(
              ink,
              resolved.backgroundColor,
              CoreStateLayer.standard.pressed,
            ),
          );
          expect(
            resolved.hoverBackgroundColor,
            isNot(resolved.backgroundColor),
          );
        },
      );
    }

    testWidgets('a dot has no label colour, so it has no wash', (
      tester,
    ) async {
      // A dot's style states no foreground — there is no ink to lay over
      // its fill, so every state paints the resting fill. The Web twin
      // writes no wash rule for it.
      for (final tone in CoreBadgeTone.values) {
        final (:resolved, theme: _) = await _resolve(
          tester,
          tone: tone,
          form: CoreBadgeForm.dot,
        );
        expect(resolved.foregroundColor, isNull, reason: tone.name);
        expect(
          resolved.hoverBackgroundColor,
          resolved.backgroundColor,
          reason: tone.name,
        );
        expect(
          resolved.pressedBackgroundColor,
          resolved.backgroundColor,
          reason: tone.name,
        );
      }
    });

    testWidgets('the instance ramp still wins over the default', (
      tester,
    ) async {
      final (:resolved, theme: _) = await _resolve(
        tester,
        badgeStyle: const CoreBadgeStyle(stateLayer: CoreStateLayer.subtle),
      );

      expect(
        resolved.pressedBackgroundColor,
        _wash(
          resolved.foregroundColor!,
          resolved.backgroundColor,
          CoreStateLayer.subtle.pressed,
        ),
      );
    });

    testWidgets('an interactive badge paints the hover and pressed fills', (
      tester,
    ) async {
      _traditionalHighlights();
      await tester.pumpWidget(
        _buildApp(
          Center(
            child: Badge(
              tone: CoreBadgeTone.primary,
              onPressed: () {},
              child: const Text('Tap'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final resolved = resolveBadge(
        tester.element(_box()),
        tone: CoreBadgeTone.primary,
        variant: CoreBadgeVariant.defaultVariant,
        form: CoreBadgeForm.defaultForm,
        size: CoreBadgeContract.defaultSize,
      );
      expect(_paintedFill(tester), resolved.backgroundColor);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_box()));
      await tester.pumpAndSettle();
      expect(_paintedFill(tester), resolved.hoverBackgroundColor);

      await mouse.down(tester.getCenter(_box()));
      await tester.pumpAndSettle();
      expect(_paintedFill(tester), resolved.pressedBackgroundColor);

      await mouse.up();
      await tester.pumpAndSettle();
      expect(_paintedFill(tester), resolved.hoverBackgroundColor);

      await mouse.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(_paintedFill(tester), resolved.backgroundColor);
    });

    testWidgets('a static badge paints no state', (tester) async {
      _traditionalHighlights();
      await tester.pumpWidget(
        _buildApp(const Center(child: Badge(child: Text('Static')))),
      );
      await tester.pumpAndSettle();
      final resting = _paintedFill(tester);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_box()));
      await tester.pumpAndSettle();
      expect(_paintedFill(tester), resting);

      await mouse.down(tester.getCenter(_box()));
      await tester.pumpAndSettle();
      expect(_paintedFill(tester), resting);
      await mouse.up();
      expect(find.byType(Clickable), findsNothing);
    });

    testWidgets('keyboard focus draws the ring and no wash', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Center(
            child: Badge(onPressed: () {}, child: const Text('Tap')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final resting = _paintedFill(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_paintedFill(tester), resting);
      final ringOpacity = tester
          .widgetList<AnimatedOpacity>(
            find.descendant(
              of: find.byType(FocusOutline),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .last;
      expect(ringOpacity.opacity, 1.0, reason: 'focus shows the ring');
    });
  });

  group('theme chain', () {
    const projectFill = CoreColor(0xFF111111);
    const toneFill = CoreColor(0xFF222222);
    const variantFill = CoreColor(0xFF333333);
    const instanceFill = CoreColor(0xFF444444);
    const theme = ThemeData(
      coreComponentTheme: CoreComponentTheme(
        badge: CoreBadgeTheme(
          style: CoreBadgeStyle(backgroundColor: projectFill),
          toneStyles: {
            CoreBadgeTone.success: CoreBadgeStyle(backgroundColor: toneFill),
          },
          variantStyles: {
            CoreBadgeVariant.filled: CoreBadgeStyle(
              backgroundColor: variantFill,
            ),
          },
        ),
      ),
    );

    Future<Color> fillFor(
      WidgetTester tester, {
      required CoreBadgeTone tone,
      required CoreBadgeVariant variant,
      CoreBadgeStyle? badgeStyle,
    }) async => (await _resolve(
      tester,
      tone: tone,
      variant: variant,
      badgeStyle: badgeStyle,
      theme: theme,
    )).resolved.backgroundColor;

    testWidgets(
      'project style → toneStyles[tone] → variantStyles[variant] → badgeStyle',
      (tester) async {
        expect(
          await fillFor(
            tester,
            tone: CoreBadgeTone.neutral,
            variant: CoreBadgeVariant.tonal,
          ),
          projectFill.toValue(),
          reason: 'only the project style applies',
        );
        expect(
          await fillFor(
            tester,
            tone: CoreBadgeTone.success,
            variant: CoreBadgeVariant.tonal,
          ),
          toneFill.toValue(),
          reason: 'the tone row overrides the project style',
        );
        expect(
          await fillFor(
            tester,
            tone: CoreBadgeTone.success,
            variant: CoreBadgeVariant.filled,
          ),
          variantFill.toValue(),
          reason: 'the variant row comes after the tone row',
        );
        expect(
          await fillFor(
            tester,
            tone: CoreBadgeTone.success,
            variant: CoreBadgeVariant.filled,
            badgeStyle: const CoreBadgeStyle(backgroundColor: instanceFill),
          ),
          instanceFill.toValue(),
          reason: 'the instance style wins over every theme slot',
        );
      },
    );

    testWidgets('a theme override reaches the state layer too', (
      tester,
    ) async {
      final (:resolved, theme: _) = await _resolve(
        tester,
        tone: CoreBadgeTone.success,
        theme: theme,
      );

      expect(
        resolved.hoverBackgroundColor,
        _wash(
          resolved.foregroundColor!,
          toneFill.toValue(),
          CoreStateLayer.standard.hover,
        ),
      );
    });
  });

  group('interaction', () {
    testWidgets('invokes onPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _buildApp(
          Center(
            child: Badge(
              onPressed: () => pressed = true,
              child: const Text('Tap'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('renders leading and trailing slots', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: Badge(
              leading: Icon(LucideIcons.info),
              trailing: Icon(LucideIcons.circleCheck),
              child: Text('Both'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Icon), findsNWidgets(2));
      expect(find.text('Both'), findsOneWidget);
    });
  });

  group('BadgeStyleChain', () {
    test(
      'withStyle merges patch into badgeStyle and preserves other fields',
      () {
        const badge = Badge(
          tone: CoreBadgeTone.primary,
          variant: CoreBadgeVariant.filled,
          size: CoreComponentSize.lg,
          showDot: true,
          child: Text('New'),
        );

        final patched = badge.withStyle(
          const CoreBadgeStyle(borderRadius: CoreBorderRadius.all(4)),
        );

        expect(patched.tone, CoreBadgeTone.primary);
        expect(patched.variant, CoreBadgeVariant.filled);
        expect(patched.size, CoreComponentSize.lg);
        expect(patched.showDot, isTrue);
        expect(patched.badgeStyle?.borderRadius, const CoreBorderRadius.all(4));
      },
    );

    test('later withStyle call wins on conflicting fields', () {
      const badge = Badge(child: Text('New'));

      final patched = badge
          .withStyle(const CoreBadgeStyle(borderWidth: 1))
          .withStyle(const CoreBadgeStyle(borderWidth: 2));

      expect(patched.badgeStyle?.borderWidth, 2);
    });

    test('copyWith replaces only the given fields', () {
      const badge = Badge(
        tone: CoreBadgeTone.warning,
        variant: CoreBadgeVariant.outlined,
        size: CoreComponentSize.lg,
        leading: Icon(LucideIcons.info),
        child: Text('New'),
      );

      final copied = badge.copyWith(
        size: CoreComponentSize.sm,
        tone: CoreBadgeTone.info,
        showDot: true,
      );

      expect(copied.size, CoreComponentSize.sm);
      expect(copied.tone, CoreBadgeTone.info);
      expect(copied.showDot, isTrue);
      expect(copied.variant, CoreBadgeVariant.outlined);
      expect(copied.form, CoreBadgeForm.label);
      expect(copied.leading, isA<Icon>());
      expect(copied.child, isA<Text>());
    });

    test('.radius4 getter sets borderRadius via withStyle', () {
      const badge = Badge(child: Text('New'));

      expect(
        badge.radius4.badgeStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
    });

    test('.primary selects the primary tone', () {
      const badge = Badge(child: Text('New'));

      expect(badge.primary.tone, CoreBadgeTone.primary);
      expect(badge.primary.badgeStyle?.backgroundColor, isNull);
    });

    test('chained primitive getters compose like withStyle chains', () {
      const badge = Badge(child: Text('New'));

      final patched = badge.radius4.primary;

      expect(
        patched.badgeStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      expect(patched.tone, CoreBadgeTone.primary);
      expect(patched.badgeStyle?.backgroundColor, isNull);
    });

    test('later chained getter wins on conflicting field', () {
      const badge = Badge(child: Text('New'));

      expect(
        badge.primary.error.badgeStyle?.backgroundColor,
        const CoreColor.token(CoreColors.error),
      );
    });
  });

  group('interactive badge focus ring', () {
    /// The decorations under the badge's [FocusOutline] layers — each
    /// layer sits under an [IgnorePointer], which keeps the badge's own
    /// body (also a descendant) out of the search. In paint order: the
    /// gap band (a shape stroke) first, the ring (a bordered box) second.
    List<Decoration> ringLayers(WidgetTester tester) => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.descendant(
              of: find.byType(FocusOutline),
              matching: find.byType(IgnorePointer),
            ),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .toList();

    Future<ResolvedBadge> pumpBadge(
      WidgetTester tester, {
      CoreBadgeForm form = CoreBadgeForm.defaultForm,
    }) async {
      late ResolvedBadge resolved;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              resolved = resolveBadge(
                context,
                tone: CoreBadgeTone.defaultTone,
                variant: CoreBadgeVariant.defaultVariant,
                size: CoreBadgeContract.defaultSize,
                form: form,
              );
              return Center(
                child: Badge(
                  form: form,
                  onPressed: () {},
                  child: const Text('Tap'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      return resolved;
    }

    testWidgets(
      'leaves the gap band transparent — a badge sits on a known page',
      (tester) async {
        final resolved = await pumpBadge(tester);

        expect(
          resolved.focusOutlineStyle.offsetColor,
          CoreFocusRing.ringOffsetColor,
        );

        final layers = ringLayers(tester);
        expect(layers, hasLength(2), reason: 'band + ring');
        final band = layers.first;
        expect(
          band,
          isA<ShapeDecoration>(),
          reason: 'the band is a stroke around the badge, not a fill',
        );
        final side =
            ((band as ShapeDecoration).shape as RoundedRectangleBorder).side;
        expect(
          side.color.a,
          0,
          reason: 'the gap shows whatever is behind the badge',
        );
      },
    );

    testWidgets('the ring follows a label badge’s step corner', (
      tester,
    ) async {
      final resolved = await pumpBadge(tester);

      expect(
        resolved.focusOutlineStyle.borderRadius,
        CoreBadgeStyle.defaultsBySize[CoreComponentSize.md]!.borderRadius,
      );
    });

    testWidgets('draws a pill ring around a count badge', (tester) async {
      final resolved = await pumpBadge(tester, form: CoreBadgeForm.count);

      expect(
        resolved.focusOutlineStyle.borderRadius,
        CoreBadgeStyle.defaultBorderRadius,
      );

      final ring = ringLayers(tester).last as BoxDecoration;
      final radius = (ring.borderRadius! as BorderRadius).topLeft.x;
      expect(radius, greaterThanOrEqualTo(CoreRadius.radius9999));
    });

    testWidgets("a caller's band and radius still win", (tester) async {
      final (:resolved, theme: _) = await _resolve(
        tester,
        badgeStyle: const CoreBadgeStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(
            offsetColor: CoreFocusRing.opaqueOffsetColor,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        ),
      );

      expect(
        resolved.focusOutlineStyle.offsetColor,
        CoreFocusRing.opaqueOffsetColor,
      );
      expect(
        resolved.focusOutlineStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
    });
  });
}
