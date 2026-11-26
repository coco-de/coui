// The `TabPane` editorStrip row's values, read where they land: the 36 px
// strip, the directional chip padding, the `codeSm` label, the bottom line
// and its colour, the strip band, the absent rule between tabs, the tab
// focus ring drawn inside its box, and the close × that keeps its own size.
//
// Every claim below is read off a laid-out or painted widget — a rect, a
// pixel — and not off the declaration, because a row that the resolver does
// not read states values nobody paints.
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kBoundary = ValueKey<String>('strip-boundary');
const _kPaneWidth = 400.0;

/// A colour no token resolves to, so a pixel that reads it can only have
/// come from the stated `borderColor`.
const _kLine = CoreColor(0xFFFF0000);
const _kLinePixel = Color(0xFFFF0000);

const _kTabs = [
  CoreTabItem<Widget>(label: 'main.dart'),
  CoreTabItem<Widget>(label: 'pubspec.yaml'),
];

Widget _strip({
  List<CoreTabItem<Widget>> tabs = _kTabs,
  CoreTabPaneVariant variant = CoreTabPaneVariant.editorStrip,
  CoreTabPaneStyle? style,
}) => SizedBox(
  width: _kPaneWidth,
  child: RepaintBoundary(
    key: _kBoundary,
    child: TabPane(
      variant: variant,
      tabs: tabs,
      selectedIndex: 0,
      onChanged: (_) {},
      tabPaneStyle: style,
    ),
  ),
);

/// Pumps [child] into a fresh test app. The harness' `Overlay` reads its
/// entries once, so a second pump into the same tree would keep showing the
/// first child — the old tree is dropped first.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  CoreSurfaceStyleId surfaceStyle = CoreSurfaceStyleId.defaultId,
  CoreDensity density = CoreDensity.defaultDensity,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(
    tester,
    child,
    theme: theme,
    surfaceStyle: surfaceStyle,
    density: density,
    textDirection: textDirection,
  );
}

/// Pumps [child] under the test app and returns what `resolveTabPane`
/// answers in the same tree, so the numbers a test reads and the widget it
/// measures share one theme.
Future<ResolvedTabPane> _pumpAndResolve(
  WidgetTester tester,
  Widget child, {
  CoreTabPaneVariant variant = CoreTabPaneVariant.editorStrip,
  CoreTabPaneStyle? style,
  ThemeData? theme,
  CoreSurfaceStyleId surfaceStyle = CoreSurfaceStyleId.defaultId,
  CoreDensity density = CoreDensity.defaultDensity,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  late ResolvedTabPane resolved;
  await _pump(
    tester,
    Builder(
      builder: (context) {
        resolved = resolveTabPane(
          context,
          variant: variant,
          tabPaneStyle: style,
        );
        return child;
      },
    ),
    theme: theme,
    surfaceStyle: surfaceStyle,
    density: density,
    textDirection: textDirection,
  );
  await tester.pump();
  return resolved;
}

/// A token's colour as the tree under test resolves it — what the painted
/// pixel of a token-backed fill reads.
Color _tokenColor(WidgetTester tester, CoreColor token) => Theme.of(
  tester.element(find.byKey(_kBoundary)),
).colorScheme.resolve(token).toValue();

/// The painted colour at [local] (logical px, relative to the strip's
/// repaint boundary), read off the rasterised image.
Future<Color> _pixelAt(WidgetTester tester, Offset local) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_kBoundary),
  );
  late ui.Image image;
  late ByteData data;
  await tester.runAsync(() async {
    image = await boundary.toImage();
    data = (await image.toByteData())!;
  });
  final i = (local.dy.floor() * image.width + local.dx.floor()) * 4;
  return Color.fromARGB(
    data.getUint8(i + 3),
    data.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
}

/// Width of a bare ghost `sm` icon Button — the row's horizontal padding on
/// both sides plus the glyph the row hands its ambient icon theme. Read off
/// the row so a change to the Button ladder moves this with it; the boxed
/// close × states nothing of its own and takes exactly this box.
double _ghostSmButtonWidth() {
  final row = CoreButtonStyle.defaultsBySize[CoreComponentSize.sm]!;
  return row.padding!.left + row.padding!.right + row.leadingIconStyle!.size!;
}

void main() {
  group('editorStrip row — 36 px strip', () {
    testWidgets(
      'the strip is 36 and the focused chip fills it; boxed is 44',
      (
        tester,
      ) async {
        final resolved = await _pumpAndResolve(tester, _strip());

        expect(resolved.barHeight, 36);
        final pane = tester.getRect(find.byKey(_kBoundary));
        expect(pane.height, 36);

        // The focused chip is the box that paints the surface fill.
        final chip = tester.getRect(
          find
              .ancestor(
                of: find.text('main.dart'),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is DecoratedBox &&
                      w.decoration is BoxDecoration &&
                      (w.decoration as BoxDecoration).color != null &&
                      (w.decoration as BoxDecoration).border == null,
                ),
              )
              .first,
        );
        expect(chip.top, pane.top);
        expect(
          chip.height,
          36,
          reason: 'the focused face fills the whole strip',
        );

        final boxed = await _pumpAndResolve(
          tester,
          _strip(variant: .boxed),
          variant: .boxed,
        );
        expect(boxed.barHeight, CoreTabPaneStyle.boxed.barHeight);
        expect(boxed.barHeight, 44);
      },
    );

    testWidgets(
      'the select region spans the chip with and without side slots',
      (
        tester,
      ) async {
        await _pumpAndResolve(
          tester,
          _strip(
            tabs: [
              CoreTabItem<Widget>(label: 'main.dart', onClose: () {}),
              const CoreTabItem<Widget>(label: 'pubspec.yaml'),
            ],
          ),
        );

        // First tab: side slot → the select Clickable stretches. Second tab:
        // no side slot → the Clickable wraps the whole padded chip. Either
        // way the hit target is the strip's full height, not the label's.
        for (final label in ['main.dart', 'pubspec.yaml']) {
          final select = find
              .ancestor(of: find.text(label), matching: find.byType(Clickable))
              .first;
          expect(tester.getSize(select).height, 36, reason: label);
        }
      },
    );

    testWidgets('the strip is not moved by a theme density', (tester) async {
      for (final density in CoreDensity.values) {
        final resolved = await _pumpAndResolve(
          tester,
          _strip(),
          density: density,
        );
        expect(resolved.barHeight, 36, reason: '$density');
      }
    });
  });

  group('editorStrip row — chip padding is directional start 12 / end 8', () {
    testWidgets('resolves to EdgeInsetsDirectional', (tester) async {
      final resolved = await _pumpAndResolve(tester, _strip());

      expect(
        resolved.tabPadding,
        const EdgeInsetsDirectional.only(
          start: CoreSpace.space12,
          end: CoreSpace.space8,
        ),
      );
    });

    testWidgets('boxed padding is the plain symmetric EdgeInsets', (
      tester,
    ) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(variant: .boxed),
        variant: .boxed,
      );

      expect(
        resolved.tabPadding,
        const EdgeInsets.symmetric(horizontal: CoreSpace.space2),
      );
    });

    testWidgets('a density keeps it directional', (tester) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(),
        density: CoreDensity.compact,
      );

      expect(resolved.tabPadding, isA<EdgeInsetsDirectional>());
    });

    for (final direction in TextDirection.values) {
      testWidgets('the whole chip is padded 12 from its start and 8 from its '
          'end in $direction', (tester) async {
        await _pumpAndResolve(
          tester,
          _strip(
            tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
          ),
          textDirection: direction,
        );

        final chip = tester.getRect(
          find
              .ancestor(
                of: find.byType(Button),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is DecoratedBox &&
                      w.decoration is BoxDecoration &&
                      (w.decoration as BoxDecoration).color != null,
                ),
              )
              .first,
        );
        final label = tester.getRect(find.text('main.dart'));
        final close = tester.getRect(find.byType(Button));

        if (direction == TextDirection.ltr) {
          expect(label.left - chip.left, CoreSpace.space12);
          expect(chip.right - close.right, CoreSpace.space8);
        } else {
          expect(chip.right - label.right, CoreSpace.space12);
          expect(close.left - chip.left, CoreSpace.space8);
        }
      });
    }
  });

  group('editorStrip row — label is codeSm, centred in the strip', () {
    testWidgets('12 px on a 21 px line box, mono', (tester) async {
      final resolved = await _pumpAndResolve(tester, _strip());

      expect(resolved.contentTextStyle.fontSize, 12);
      expect(
        resolved.contentTextStyle.fontSize! * resolved.contentTextStyle.height!,
        closeTo(21, 0.01),
      );
      // The same role a standalone `codeSm` text resolves to — the label
      // takes the role, not a size laid over bodyMedium.
      late TextStyle codeSm;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            codeSm = const CoreTextStyle.token(
              CoreTextStyles.codeSm,
            ).toValue(theme: Theme.of(context));
            return const SizedBox.shrink();
          },
        ),
      );
      expect(resolved.contentTextStyle.fontFamily, codeSm.fontFamily);
      expect(
        resolved.contentTextStyle.letterSpacing,
        closeTo(codeSm.letterSpacing ?? 0, 0.0001),
      );
      expect(resolved.contentTextStyle.fontWeight, codeSm.fontWeight);
    });

    testWidgets('boxed keeps bodyMedium (14)', (tester) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(variant: .boxed),
        variant: .boxed,
      );

      expect(resolved.contentTextStyle.fontSize, 14);
    });

    testWidgets(
      'the name is a 21 px line vertically centred in the 36 px strip',
      (
        tester,
      ) async {
        await _pumpAndResolve(tester, _strip());

        final pane = tester.getRect(find.byKey(_kBoundary));
        for (final label in ['main.dart', 'pubspec.yaml']) {
          final rect = tester.getRect(find.text(label));
          expect(rect.height, closeTo(21, 0.01), reason: label);
          expect(rect.center.dy, closeTo(pane.center.dy, 0.01), reason: label);
        }
      },
    );

    testWidgets('a per-instance contentTextStyle still wins over the row', (
      tester,
    ) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(
          style: const CoreTabPaneStyle(
            contentTextStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
          ),
        ),
        style: const CoreTabPaneStyle(
          contentTextStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
        ),
      );

      expect(resolved.contentTextStyle.fontSize, isNot(12));
    });
  });

  group('editorStrip row — the close × keeps its own size', () {
    testWidgets('a 20 px box centred in the 36 px chip, not 20x36', (
      tester,
    ) async {
      await _pumpAndResolve(
        tester,
        _strip(
          tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
        ),
      );

      final pane = tester.getRect(find.byKey(_kBoundary));
      final close = tester.getRect(find.byType(Button));
      expect(close.size, const Size(20, 20), reason: 'no stretched hover face');
      expect(close.height, lessThan(pane.height));
      expect(close.center.dy, closeTo(pane.center.dy, 0.01));
    });

    testWidgets('the boxed strip keeps the 32 px ghost Button row', (
      tester,
    ) async {
      await _pump(
        tester,
        Button(
          variant: .ghost,
          size: .sm,
          onPressed: () {},
          child: const Icon(LucideIcons.x),
        ),
      );
      final natural = tester.getSize(find.byType(Button));
      expect(natural, Size(_ghostSmButtonWidth(), CoreControlSize.heightSm));

      await _pumpAndResolve(
        tester,
        _strip(
          variant: .boxed,
          tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
        ),
        variant: .boxed,
      );

      // Same row, same glyph; only the boxed bar's own 32 px row (less its
      // 2 px padding) caps the height.
      final inBar = tester.getSize(find.byType(Button));
      expect(inBar.width, natural.width);
      expect(inBar.height, lessThanOrEqualTo(natural.height));
    });

    testWidgets('a trailing slot keeps its own height too', (tester) async {
      await _pumpAndResolve(
        tester,
        _strip(
          tabs: const [
            CoreTabItem<Widget>(
              label: 'main.dart',
              trailing: SizedBox(key: ValueKey('t'), width: 10, height: 10),
            ),
          ],
        ),
      );

      final pane = tester.getRect(find.byKey(_kBoundary));
      final trailing = tester.getRect(find.byKey(const ValueKey('t')));
      expect(trailing.size, const Size(10, 10));
      expect(trailing.center.dy, closeTo(pane.center.dy, 0.01));
    });
  });

  group('editorStrip row — bottom line', () {
    /// A `Border` (not `BorderDirectional`, which the inter-tab rule uses)
    /// that draws its bottom side alone — the line's decoration. The
    /// focus-outline boxes are `Border.all`, so they do not match.
    final lineBox = find.byWidgetPredicate((w) {
      if (w is! DecoratedBox) return false;
      final d = w.decoration;
      if (d is! BoxDecoration) return false;
      final b = d.border;
      return b is Border &&
          b.bottom.style == BorderStyle.solid &&
          b.top.style == BorderStyle.none &&
          b.left.style == BorderStyle.none &&
          b.right.style == BorderStyle.none;
    });

    testWidgets('the row states stroke1 and outlineVariant: the line is on', (
      tester,
    ) async {
      final resolved = await _pumpAndResolve(tester, _strip());

      expect(resolved.borderWidth, CoreStrokeWidth.stroke1);
      expect(
        resolved.stripBorderColor,
        _tokenColor(tester, const CoreColor.token(CoreColors.outlineVariant)),
      );
      expect(lineBox, findsOneWidget);
      // Inside the bar, not on top of it: the strip is still 36.
      expect(tester.getRect(find.byKey(_kBoundary)).height, 36);
    });

    testWidgets('the default line is painted at the strip bottom under an '
        'unselected tab and the empty strip; the row above is the band', (
      tester,
    ) async {
      final resolved = await _pumpAndResolve(tester, _strip());
      final line = _tokenColor(
        tester,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      final left = tester.getRect(find.byKey(_kBoundary)).left;
      final other = tester.getCenter(find.text('pubspec.yaml')).dx - left;

      expect(await _pixelAt(tester, Offset(other, 35)), line);
      expect(await _pixelAt(tester, const Offset(390, 35)), line);
      expect(
        await _pixelAt(tester, Offset(other, 34)),
        resolved.stripBackgroundColor,
      );
    });

    testWidgets('the selected tab face covers the default line', (
      tester,
    ) async {
      final resolved = await _pumpAndResolve(tester, _strip());
      final left = tester.getRect(find.byKey(_kBoundary)).left;
      final selected = tester.getCenter(find.text('main.dart')).dx - left;

      expect(
        await _pixelAt(tester, Offset(selected, 35)),
        resolved.backgroundColor,
        reason: 'the face fills the strip height and paints over the line',
      );
      expect(
        resolved.backgroundColor,
        isNot(
          _tokenColor(tester, const CoreColor.token(CoreColors.outlineVariant)),
        ),
      );
    });

    testWidgets('a transparent borderColor override draws nothing', (
      tester,
    ) async {
      const style = CoreTabPaneStyle(borderColor: CoreColor.transparent);
      final resolved = await _pumpAndResolve(
        tester,
        _strip(style: style),
        style: style,
      );
      final left = tester.getRect(find.byKey(_kBoundary)).left;
      final other = tester.getCenter(find.text('pubspec.yaml')).dx - left;

      expect(resolved.stripBorderColor, isNull);
      expect(lineBox, findsNothing, reason: 'no border node while inert');
      expect(
        await _pixelAt(tester, Offset(other, 35)),
        resolved.stripBackgroundColor,
        reason: 'the bottom row is the band again',
      );
    });

    testWidgets('a stated borderColor draws the line at the bottom of the '
        'strip, inside its 36 px', (tester) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(style: const CoreTabPaneStyle(borderColor: _kLine)),
        style: const CoreTabPaneStyle(borderColor: _kLine),
      );

      expect(resolved.stripBorderColor, _kLinePixel);
      expect(lineBox, findsOneWidget);
      // Inside the bar, not on top of it: the strip is still 36.
      expect(tester.getRect(find.byKey(_kBoundary)).height, 36);

      final other = tester.getCenter(find.text('pubspec.yaml')).dx;
      final left = tester.getRect(find.byKey(_kBoundary)).left;
      // The bottom row of an unselected tab and of the empty strip beyond
      // the tabs is the line; the row above it (1 px thick) is the band.
      expect(await _pixelAt(tester, Offset(other - left, 35)), _kLinePixel);
      expect(await _pixelAt(tester, const Offset(390, 35)), _kLinePixel);
      expect(
        await _pixelAt(tester, Offset(other - left, 34)),
        resolved.stripBackgroundColor,
      );
    });

    testWidgets('the selected tab face covers the line; unselected tabs show '
        'it', (tester) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(style: const CoreTabPaneStyle(borderColor: _kLine)),
        style: const CoreTabPaneStyle(borderColor: _kLine),
      );
      final left = tester.getRect(find.byKey(_kBoundary)).left;
      final selected = tester.getCenter(find.text('main.dart')).dx - left;
      final other = tester.getCenter(find.text('pubspec.yaml')).dx - left;

      expect(
        await _pixelAt(tester, Offset(selected, 35)),
        resolved.backgroundColor,
        reason: 'the focused face fills the strip height and paints over it',
      );
      expect(await _pixelAt(tester, Offset(other, 35)), _kLinePixel);
    });

    testWidgets('borderWidth is the line thickness', (tester) async {
      const style = CoreTabPaneStyle(borderColor: _kLine, borderWidth: 3);
      final resolved = await _pumpAndResolve(
        tester,
        _strip(style: style),
        style: style,
      );
      final other = tester.getCenter(find.text('pubspec.yaml')).dx;
      final left = tester.getRect(find.byKey(_kBoundary)).left;

      expect(resolved.borderWidth, 3);
      for (final y in [33.0, 34.0, 35.0]) {
        expect(await _pixelAt(tester, Offset(other - left, y)), _kLinePixel);
      }
      expect(
        await _pixelAt(tester, Offset(other - left, 32)),
        resolved.stripBackgroundColor,
      );
    });

    testWidgets('a surface style stroke floor thickens the line, inside the '
        'same 36 px', (tester) async {
      const style = CoreTabPaneStyle(borderColor: _kLine);
      final resolved = await _pumpAndResolve(
        tester,
        _strip(style: style),
        style: style,
        // A preset-built theme: the surface fold bends resolved colours,
        // and the harness' bare `ThemeData()` still holds unresolved tokens.
        theme: ThemeData.fromCore(CoreThemePresets.light),
        surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
      );

      final floor = resolved.borderWidth;
      expect(floor, greaterThanOrEqualTo(CoreStrokeWidth.stroke4));
      expect(tester.getRect(find.byKey(_kBoundary)).height, 36);
      final other = tester.getCenter(find.text('pubspec.yaml')).dx;
      final left = tester.getRect(find.byKey(_kBoundary)).left;
      expect(await _pixelAt(tester, Offset(other - left, 35)), _kLinePixel);
      expect(
        await _pixelAt(tester, Offset(other - left, 36 - floor)),
        _kLinePixel,
        reason: 'the top row of the thickened line',
      );
      expect(
        await _pixelAt(tester, Offset(other - left, 36 - floor - 1)),
        isNot(_kLinePixel),
        reason: 'one row above it is not the line',
      );
    });

    testWidgets('a zero borderWidth draws no line even with a colour', (
      tester,
    ) async {
      const style = CoreTabPaneStyle(borderColor: _kLine, borderWidth: 0);
      final resolved = await _pumpAndResolve(
        tester,
        _strip(style: style),
        style: style,
      );

      expect(resolved.stripBorderColor, isNull);
      expect(lineBox, findsNothing);
    });

    testWidgets('a material that draws its own edge does not switch it off', (
      tester,
    ) async {
      // The panel border goes through the material's stroke suppression;
      // the strip line must not, because the Web twin has no material
      // marker on the strip and always draws it.
      final theme = ThemeData.fromCore(CoreThemePresets.light).copyWith(
        surfaceOpacity: () => 0.6,
        surfaceSheen: () => const CoreSurfaceEdgeSheen(
          width: 1,
          lightColor: CoreColor.token(CoreColors.outline),
          darkColor: CoreColor.token(CoreColors.outline),
        ),
        surfaceDrawsOwnEdge: () => true,
      );
      const style = CoreTabPaneStyle(borderColor: _kLine);
      final resolved = await _pumpAndResolve(
        tester,
        _strip(style: style),
        style: style,
        theme: theme,
      );

      expect(
        resolved.panelBorderColor.a,
        0,
        reason: 'control: the suppression is active under this theme',
      );
      expect(resolved.stripBorderColor, _kLinePixel);
      final other = tester.getCenter(find.text('pubspec.yaml')).dx;
      final left = tester.getRect(find.byKey(_kBoundary)).left;
      expect(await _pixelAt(tester, Offset(other - left, 35)), _kLinePixel);
    });

    testWidgets('boxed states the same hairline under its bar', (tester) async {
      const style = CoreTabPaneStyle(borderColor: _kLine);
      final resolved = await _pumpAndResolve(
        tester,
        _strip(variant: .boxed, style: style),
        variant: .boxed,
        style: style,
      );

      // The boxed card's rule between its bar and its panel, drawn inside the
      // 44 px bar like the strip's bottom line.
      expect(resolved.stripBorderColor, _kLinePixel);
      expect(resolved.barHeight, 44);
    });
  });

  group('editorStrip row — strip band is surfaceContainerLow', () {
    testWidgets('the band resolves to surfaceContainerLow, not '
        'surfaceContainer, and is painted', (tester) async {
      final resolved = await _pumpAndResolve(tester, _strip());
      final low = _tokenColor(
        tester,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
      final regular = _tokenColor(
        tester,
        const CoreColor.token(CoreColors.surfaceContainer),
      );

      expect(low, isNot(regular), reason: 'control: the two steps differ');
      expect(resolved.stripBackgroundColor, low);
      // The empty strip beyond the tabs, one row above the bottom line.
      expect(await _pixelAt(tester, const Offset(390, 20)), low);
    });

    testWidgets('the selected face stays surface', (tester) async {
      final resolved = await _pumpAndResolve(tester, _strip());

      expect(
        resolved.backgroundColor,
        _tokenColor(tester, const CoreColor.token(CoreColors.surface)),
      );
    });

    testWidgets('boxed keeps a transparent band', (tester) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(variant: .boxed),
        variant: .boxed,
      );

      expect(resolved.stripBackgroundColor, isNull);
    });
  });

  group('editorStrip row — a rule between tabs', () {
    /// A tab as the strip lays it out: the select `Clickable` that holds the
    /// padded chip (these tabs carry no side slot).
    Rect tab(WidgetTester tester, String label) => tester.getRect(
      find
          .ancestor(of: find.text(label), matching: find.byType(Clickable))
          .first,
    );

    testWidgets('the separator resolves to outlineVariant at the default '
        'width and each wrapper draws it on its end edge', (tester) async {
      final resolved = await _pumpAndResolve(tester, _strip());

      expect(
        resolved.tabSeparatorColor,
        _tokenColor(tester, const CoreColor.token(CoreColors.outlineVariant)),
      );
      expect(resolved.tabSeparatorWidth, CoreStrokeWidth.stroke1);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border is BorderDirectional,
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('the tabs sit flush but for the rule: the second begins one '
        'rule after the first ends', (tester) async {
      await _pumpAndResolve(tester, _strip());

      final first = tab(tester, 'main.dart');
      final second = tab(tester, 'pubspec.yaml');
      expect(first.left, tester.getRect(find.byKey(_kBoundary)).left);
      expect(
        second.left - first.right,
        closeTo(CoreStrokeWidth.stroke1, 0.01),
        reason: 'the wrapper reserves the rule it draws; the gap is zero',
      );
    });

    testWidgets('a transparent separator override takes the rule away', (
      tester,
    ) async {
      const style = CoreTabPaneStyle(tabSeparatorColor: CoreColor.transparent);
      final resolved = await _pumpAndResolve(
        tester,
        _strip(style: style),
        style: style,
      );

      expect(resolved.tabSeparatorColor, isNull);
      final first = tab(tester, 'main.dart');
      final second = tab(tester, 'pubspec.yaml');
      expect(second.left, closeTo(first.right, 0.01));
    });
  });

  group('editorStrip row — the tab focus ring is inside the tab box', () {
    /// Puts the first tab's `Clickable` in keyboard-focus mode and focuses
    /// it, so its `FocusOutline` shows.
    Future<void> focusFirstTab(WidgetTester tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        // Global, so it leaks into whatever runs next unless put back.
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });
      tester
          .widgetList<FocusableActionDetector>(
            find.byType(FocusableActionDetector),
          )
          .first
          .focusNode!
          .requestFocus();
      await tester.pumpAndSettle();
    }

    Color ringColor(WidgetTester tester) => Theme.of(
      tester.element(find.byKey(_kBoundary)),
    ).colorScheme.resolve(CoreFocusRing.ringColor).toValue();

    testWidgets('the Clickable resolves a ring whose outer edge is the box '
        'edge, in the system ring colour and width', (tester) async {
      final resolved = await _pumpAndResolve(tester, _strip());
      final ring = CoreClickableStyle.defaultFocusOutlineStyle.merge(
        resolved.clickableStyle.focusOutlineStyle,
      );

      expect(ring.align, 0);
      expect(ring.borderColor, CoreFocusRing.ringColor);
      expect(ring.borderWidth, CoreFocusRing.ringWidth);
      // Boxed keeps the outside ring.
      final boxed = await _pumpAndResolve(
        tester,
        _strip(variant: .boxed),
        variant: .boxed,
      );
      expect(boxed.clickableStyle.focusOutlineStyle, isNull);
    });

    testWidgets('the ring box is the tab box: nothing is drawn outside the '
        'strip', (tester) async {
      await _pumpAndResolve(tester, _strip());
      await focusFirstTab(tester);

      final strip = tester.getRect(find.byKey(_kBoundary));
      final clickable = tester.getRect(find.byType(Clickable).first);
      final outline = tester.widget<FocusOutline>(
        find.descendant(
          of: find.byType(Clickable).first,
          matching: find.byType(FocusOutline),
        ),
      );
      expect(outline.focused, isTrue);

      final ring = tester.getRect(
        find
            .descendant(
              of: find.byWidget(outline),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(ring, clickable, reason: 'inset: the ring box is the tab box');
      expect(ring.top, greaterThanOrEqualTo(strip.top));
      expect(ring.bottom, lessThanOrEqualTo(strip.bottom));
    });

    testWidgets('the ring paints in the top and bottom rows of the strip', (
      tester,
    ) async {
      await _pumpAndResolve(tester, _strip());
      await focusFirstTab(tester);

      final left = tester.getRect(find.byKey(_kBoundary)).left;
      final x = tester.getCenter(find.text('main.dart')).dx - left;
      final ring = ringColor(tester);
      // Width 2: the two outer rows of the 36 px strip are the ring; the
      // row inside them is the tab's face again.
      for (final y in [0.0, 1.0, 34.0, 35.0]) {
        expect(await _pixelAt(tester, Offset(x, y)), ring, reason: 'y=$y');
      }
      expect(
        await _pixelAt(tester, Offset(x, 4)),
        isNot(ring),
        reason: 'the ring is 2 px wide, not a fill',
      );
    });

    testWidgets('the default outside ring is clipped by the scrolling strip '
        '(control)', (tester) async {
      // The selected tab's indicator bar is `primary` too — the same colour
      // as the ring — so it is switched off here to leave only the ring.
      const style = CoreTabPaneStyle(
        indicatorColor: CoreColor.transparent,
        clickableStyle: CoreClickableStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(
            align: CoreFocusOutlineStyle.defaultAlign,
          ),
        ),
      );
      await _pumpAndResolve(tester, _strip(style: style), style: style);
      await focusFirstTab(tester);

      final left = tester.getRect(find.byKey(_kBoundary)).left;
      final x = tester.getCenter(find.text('main.dart')).dx - left;
      final ring = ringColor(tester);
      // Drawn 4 px outside a 36 px-tall box in a 36 px-tall scrollport, the
      // ring has no pixel of its own inside the strip at the top edge.
      expect(await _pixelAt(tester, Offset(x, 0)), isNot(ring));
      expect(await _pixelAt(tester, Offset(x, 35)), isNot(ring));
    });
  });

  group('editorStrip row — indicator bar on the selected tab', () {
    testWidgets('primary, 2 px, on the inside of the selected tab top edge', (
      tester,
    ) async {
      final resolved = await _pumpAndResolve(tester, _strip());
      final primary = _tokenColor(
        tester,
        const CoreColor.token(CoreColors.primary),
      );

      expect(resolved.indicatorColor, primary);
      expect(resolved.indicatorWidth, 2);

      final left = tester.getRect(find.byKey(_kBoundary)).left;
      final x0 = tester.getCenter(find.text('main.dart')).dx - left;
      final x1 = tester.getCenter(find.text('pubspec.yaml')).dx - left;
      // The two outer-most rows of the selected tab are the bar...
      for (final y in [0.0, 1.0]) {
        expect(await _pixelAt(tester, Offset(x0, y)), primary, reason: 'y=$y');
      }
      // ...the row under them is the tab face again (2 px, not a fill)...
      expect(await _pixelAt(tester, Offset.zero), primary);
      expect(await _pixelAt(tester, Offset(x0, 2)), isNot(primary));
      expect(await _pixelAt(tester, Offset(x0, 20)), isNot(primary));
      // ...and the unselected tab has none.
      for (final y in [0.0, 1.0, 2.0]) {
        expect(
          await _pixelAt(tester, Offset(x1, y)),
          isNot(primary),
          reason: 'unselected y=$y',
        );
      }
    });

    testWidgets('boxed draws the bar along the bottom of the tab, over the '
        "bar's line, the tab's full width, with its top corners rounded", (
      tester,
    ) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(variant: .boxed),
        variant: .boxed,
      );
      final primary = _tokenColor(
        tester,
        const CoreColor.token(CoreColors.primary),
      );

      expect(resolved.indicatorColor, primary);
      expect(resolved.indicatorWidth, 2);
      expect(
        resolved.indicatorBorderRadius,
        const BorderRadius.only(
          topLeft: Radius.circular(CoreRadius.radius2),
          topRight: Radius.circular(CoreRadius.radius2),
        ),
      );

      final boundary = tester.getRect(find.byKey(_kBoundary));
      final selected = tester.getRect(
        find
            .ancestor(
              of: find.text('main.dart'),
              matching: find.byType(Clickable),
            )
            .first,
      );
      final bottom = boundary.bottom - boundary.top;
      final mid = selected.center.dx - boundary.left;
      // The bar's row 1 is the card's own edge (the card holds only the bar
      // here), so the tab's two bottom rows are the next two up...
      for (final dy in [2.0, 3.0]) {
        expect(
          await _pixelAt(tester, Offset(mid, bottom - dy)),
          primary,
          reason: 'dy=$dy',
        );
      }
      // ...the row above is the card again, and the bar runs the tab's full
      // width, past the label to the chip's own edge.
      expect(await _pixelAt(tester, Offset(mid, bottom - 4)), isNot(primary));
      expect(
        await _pixelAt(
          tester,
          Offset(selected.left - boundary.left + 4, bottom - 2),
        ),
        primary,
        reason: 'the bar spans the chip, not the label',
      );
    });

    testWidgets('the boxed focused tab carries no face and no outline', (
      tester,
    ) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(variant: .boxed),
        variant: .boxed,
      );

      expect(resolved.tabBorderColor, isNull);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color != null &&
              (w.decoration as BoxDecoration).borderRadius == null &&
              (w.decoration as BoxDecoration).border == null,
        ),
        findsNothing,
        reason: 'the boxed tab fills nothing: it sits on the card surface',
      );
    });

    testWidgets('a stated indicatorColor and width reach the boxed bar', (
      tester,
    ) async {
      const style = CoreTabPaneStyle(
        indicatorColor: _kLine,
        indicatorWidth: 3,
      );
      final resolved = await _pumpAndResolve(
        tester,
        _strip(variant: .boxed, style: style),
        variant: .boxed,
        style: style,
      );

      expect(resolved.indicatorColor, _kLinePixel);
      expect(resolved.indicatorWidth, 3);
      final boundary = tester.getRect(find.byKey(_kBoundary));
      final selected = tester.getRect(
        find
            .ancestor(
              of: find.text('main.dart'),
              matching: find.byType(Clickable),
            )
            .first,
      );
      final bottom = boundary.bottom - boundary.top;
      final x = selected.center.dx - boundary.left;
      for (final dy in [2.0, 3.0, 4.0]) {
        expect(
          await _pixelAt(tester, Offset(x, bottom - dy)),
          _kLinePixel,
          reason: 'dy=$dy',
        );
      }
      expect(await _pixelAt(tester, Offset(x, bottom - 5)), isNot(_kLinePixel));
    });

    testWidgets('a transparent override switches the bar off', (tester) async {
      const style = CoreTabPaneStyle(indicatorColor: CoreColor.transparent);
      final resolved = await _pumpAndResolve(
        tester,
        _strip(style: style),
        style: style,
      );

      expect(resolved.indicatorColor, isNull);
    });

    testWidgets(
      'takes no layout: the label sits at the same y selected or not',
      (tester) async {
        await _pumpAndResolve(tester, _strip());
        final selected = tester.getRect(find.text('main.dart'));
        final unselected = tester.getRect(find.text('pubspec.yaml'));
        expect(selected.top, unselected.top);
        expect(selected.height, unselected.height);

        // The whole chip is the same height with and without the bar.
        const off = CoreTabPaneStyle(indicatorColor: CoreColor.transparent);
        await _pumpAndResolve(tester, _strip(style: off), style: off);
        final without = tester.getRect(find.text('main.dart'));
        expect(without.top, selected.top);
        expect(without.left, selected.left);
      },
    );

    testWidgets('takes no layout with a close × beside the label either', (
      tester,
    ) async {
      await _pumpAndResolve(
        tester,
        _strip(
          tabs: [
            CoreTabItem<Widget>(label: 'main.dart', onClose: () {}),
            CoreTabItem<Widget>(label: 'main.dart2', onClose: () {}),
          ],
        ),
      );
      expect(
        tester.getRect(find.text('main.dart')).top,
        tester.getRect(find.text('main.dart2')).top,
      );
      expect(
        tester.getRect(find.byType(Button).first).top,
        tester.getRect(find.byType(Button).last).top,
      );
    });
  });

  group('editorStrip row — close affordance', () {
    testWidgets('20 box, 12 glyph; chip is 12 + label + 6 + 20 + 8 wide', (
      tester,
    ) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(
          tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
        ),
      );

      expect(resolved.closeButtonStyle.width, 20);
      expect(resolved.closeButtonStyle.height, 20);
      expect(resolved.closeButtonStyle.padding, CoreEdgeInsets.zero);
      expect(
        resolved.closeButtonStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      expect(resolved.closeIconStyle.size, 12);

      expect(
        tester.getSize(
          find.descendant(
            of: find.byType(Button),
            matching: find.byType(Icon),
          ),
        ),
        const Size(12, 12),
      );

      final chip = tester.getRect(
        find
            .ancestor(
              of: find.byType(Button),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    w.decoration is BoxDecoration &&
                    (w.decoration as BoxDecoration).color != null,
              ),
            )
            .first,
      );
      final label = tester.getRect(find.text('main.dart'));
      expect(chip.width, closeTo(12 + label.width + 6 + 20 + 8, 0.01));
    });

    testWidgets('a disabled tab leaves its close × out of the tab dimming', (
      tester,
    ) async {
      await _pumpAndResolve(
        tester,
        _strip(
          tabs: [
            CoreTabItem<Widget>(label: 'main.dart', onClose: () {}),
            CoreTabItem<Widget>(
              label: 'pubspec.yaml',
              enabled: false,
              onClose: () {},
            ),
          ],
        ),
      );
      final buttons = find.byType(Button);
      expect(buttons, findsNWidgets(2));
      // The × is a sibling of the tab's select Clickable, not inside it, so
      // the Clickable's disabled dimming does not reach it: no Opacity sits
      // between the disabled tab's chip and its × glyph.
      final disabledTabButton = buttons.at(1);
      final dimmed = find.ancestor(
        of: disabledTabButton,
        matching: find.byWidgetPredicate(
          (w) => w is Opacity && w.opacity < 1,
        ),
      );
      expect(dimmed, findsNothing);
    });

    testWidgets('the editorStrip glyph is onSurfaceSubtle: resolver, render, '
        'and through hover', (tester) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(
          tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
        ),
      );
      const subtle = CoreColor.token(CoreColors.onSurfaceSubtle);
      expect(resolved.closeIconStyle.color, subtle);

      // What the glyph paints: the colour filter the Icon hands its SVG.
      final subtleColor = _tokenColor(tester, subtle);
      ColorFilter? glyphFilter() => tester
          .widget<SvgPicture>(
            find.descendant(
              of: find.byType(Button),
              matching: find.byType(SvgPicture),
            ),
          )
          .colorFilter;
      final rest = glyphFilter();
      expect(rest, ColorFilter.mode(subtleColor, BlendMode.srcIn));
      // The ghost button's own foreground is `onSurface` — the glyph must
      // not be it, so the filter above comes from the glyph's own colour.
      expect(
        subtleColor,
        isNot(_tokenColor(tester, const CoreColor.token(CoreColors.onSurface))),
      );

      // Hover the button: its wash changes, the glyph does not.
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(Button)));
      await tester.pumpAndSettle();
      expect(glyphFilter(), ColorFilter.mode(subtleColor, BlendMode.srcIn));
    });

    testWidgets("a disabled tab's close glyph is the same onSurfaceSubtle", (
      tester,
    ) async {
      await _pumpAndResolve(
        tester,
        _strip(
          tabs: [
            CoreTabItem<Widget>(
              label: 'pubspec.yaml',
              enabled: false,
              onClose: () {},
            ),
          ],
        ),
      );
      expect(
        tester
            .widget<SvgPicture>(
              find.descendant(
                of: find.byType(Button),
                matching: find.byType(SvgPicture),
              ),
            )
            .colorFilter,
        ColorFilter.mode(
          _tokenColor(
            tester,
            const CoreColor.token(CoreColors.onSurfaceSubtle),
          ),
          BlendMode.srcIn,
        ),
      );
    });

    testWidgets('a boxed pane states no glyph colour: the glyph follows its '
        'button', (tester) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(
          variant: .boxed,
          tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
        ),
        variant: .boxed,
      );
      expect(resolved.closeIconStyle.color, isNull);
      // Rendered: the boxed glyph takes the ghost button's foreground
      // (onSurface), not the editorStrip's onSurfaceSubtle.
      final filter = tester
          .widget<SvgPicture>(
            find.descendant(
              of: find.byType(Button),
              matching: find.byType(SvgPicture),
            ),
          )
          .colorFilter;
      expect(
        filter,
        ColorFilter.mode(
          _tokenColor(tester, const CoreColor.token(CoreColors.onSurface)),
          BlendMode.srcIn,
        ),
      );
    });

    testWidgets('a boxed pane states no close box: resolver and render', (
      tester,
    ) async {
      final resolved = await _pumpAndResolve(
        tester,
        _strip(
          variant: .boxed,
          tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
        ),
        variant: .boxed,
      );

      expect(resolved.closeButtonStyle, const CoreButtonStyle());
      expect(resolved.closeIconStyle, const CoreIconStyle());
      final close = tester.getSize(find.byType(Button));
      expect(
        close.width,
        _ghostSmButtonWidth(),
        reason: 'not the 24 px editorStrip box',
      );
      expect(close.height, greaterThan(24));
    });

    testWidgets('a colour-only closeIconStyle keeps the row size 12', (
      tester,
    ) async {
      const style = CoreTabPaneStyle(
        closeIconStyle: CoreIconStyle(color: _kLine),
      );
      final resolved = await _pumpAndResolve(
        tester,
        _strip(
          style: style,
          tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
        ),
        style: style,
      );

      expect(resolved.closeIconStyle.size, 12);
      expect(resolved.closeIconStyle.color, _kLine);
      expect(
        tester.getSize(
          find.descendant(
            of: find.byType(Button),
            matching: find.byType(Icon),
          ),
        ),
        const Size(12, 12),
      );
    });

    testWidgets('a per-instance closeButtonStyle wins over the row', (
      tester,
    ) async {
      const style = CoreTabPaneStyle(
        closeButtonStyle: CoreButtonStyle(width: 30, height: 30),
      );
      await _pumpAndResolve(
        tester,
        _strip(
          style: style,
          tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
        ),
        style: style,
      );

      expect(tester.getSize(find.byType(Button)), const Size(30, 30));
    });
  });

  Finder _icon(IconName name) => find.byWidgetPredicate(
    (widget) => widget is Icon && widget.icon == name,
  );

  group('slot icons', () {
    for (final variant in CoreTabPaneVariant.values) {
      for (final direction in TextDirection.values) {
        for (final mode in [
          'default',
          'slot',
          'explicit',
          'explicit-trailing',
          'nested',
          'nested-trailing',
          'disabled',
          'theme',
          'theme-instance',
          'icon-theme',
        ]) {
          testWidgets(
            '${variant.name}/${direction.name}/$mode preserves slot icon precedence',
            (tester) async {
              Widget leading = Icon(
                LucideIcons.file,
                iconStyle: mode == 'explicit'
                    ? const CoreIconStyle(
                        size: 12,
                        color: CoreColor(0xFF00FF00),
                      )
                    : null,
              );
              if (mode == 'nested') {
                leading = IconTheme(
                  data: const IconThemeData(size: 28, color: Color(0xFF0000FF)),
                  child: leading,
                );
              }
              Widget trailing = Icon(
                LucideIcons.star,
                iconStyle: mode == 'explicit-trailing'
                    ? const CoreIconStyle(
                        size: 12,
                        color: CoreColor(0xFF00FF00),
                      )
                    : null,
              );
              if (mode == 'nested-trailing') {
                trailing = IconTheme(
                  data: const IconThemeData(size: 28, color: Color(0xFF0000FF)),
                  child: trailing,
                );
              }
              await _pump(
                tester,
                IconTheme(
                  data: const IconThemeData(size: 30, color: Color(0xFFFF0000)),
                  child: _strip(
                    variant: variant,
                    style: mode == 'slot' || mode == 'theme-instance'
                        ? const CoreTabPaneStyle(
                            slotIconStyle: CoreIconStyle(size: 24),
                          )
                        : null,
                    tabs: [
                      CoreTabItem<Widget>(
                        label: 'main.dart',
                        leading: leading,
                        trailing: trailing,
                        onClose: () {},
                        enabled: mode != 'disabled',
                      ),
                    ],
                  ),
                ),
                textDirection: direction,
                theme: ThemeData.fromCore(CoreThemePresets.light).copyWith(
                  coreComponentTheme: () => CoreComponentTheme(
                    tabPane: mode == 'theme' || mode == 'theme-instance'
                        ? const CoreTabPaneTheme(
                            style: CoreTabPaneStyle(
                              slotIconStyle: CoreIconStyle(size: 20),
                            ),
                          )
                        : null,
                    icon: mode == 'icon-theme'
                        ? const CoreIconTheme(
                            style: CoreIconStyle(
                              size: 22,
                              color: CoreColor(0xFF800080),
                            ),
                          )
                        : null,
                  ),
                ),
              );
              final slotSize = switch (mode) {
                'slot' || 'theme-instance' => 24.0,
                'theme' => 20.0,
                'icon-theme' => 22.0,
                _ => CoreTabPaneStyle.defaultSlotIconStyle.size!,
              };
              final leadingSize = switch (mode) {
                'explicit' => 12.0,
                'nested' => 28.0,
                _ => slotSize,
              };
              final lead = tester.getRect(_icon(LucideIcons.file));
              final trail = tester.getRect(_icon(LucideIcons.star));
              expect(lead.size, Size.square(leadingSize));
              final trailingSize = switch (mode) {
                'explicit-trailing' => 12.0,
                'nested-trailing' => 28.0,
                _ => slotSize,
              };
              expect(trail.size, Size.square(trailingSize));
              final ambientColor = mode == 'icon-theme'
                  ? const Color(0xFF800080)
                  : const Color(0xFFFF0000);
              final leadingColor = switch (mode) {
                'explicit' => const Color(0xFF00FF00),
                'nested' => const Color(0xFF0000FF),
                _ => ambientColor,
              };
              final trailingColor = switch (mode) {
                'explicit-trailing' => const Color(0xFF00FF00),
                'nested-trailing' => const Color(0xFF0000FF),
                _ => ambientColor,
              };
              for (final (icon, color) in [
                (LucideIcons.file, leadingColor),
                (LucideIcons.star, trailingColor),
              ]) {
                final svg = tester.widget<SvgPicture>(
                  find.descendant(
                    of: _icon(icon),
                    matching: find.byType(SvgPicture),
                  ),
                );
                expect(
                  svg.colorFilter,
                  ColorFilter.mode(color, BlendMode.srcIn),
                );
              }
              expect(lead.center.dy, trail.center.dy);
              final label = tester.getRect(find.text('main.dart'));
              expect(
                direction == TextDirection.ltr
                    ? lead.left < label.left
                    : lead.left > label.left,
                isTrue,
              );
              if (variant == CoreTabPaneVariant.editorStrip) {
                expect(
                  tester.getSize(_icon(LucideIcons.x)),
                  Size.square(
                    CoreTabPaneStyle.editorStrip.closeIconStyle!.size!,
                  ),
                );
              }
            },
          );
        }
      }
    }
    testWidgets('leading and trailing icons take slotIconStyle, 16', (
      tester,
    ) async {
      await _pump(
        tester,
        _strip(
          variant: CoreTabPaneVariant.boxed,
          tabs: const [
            CoreTabItem<Widget>(
              label: 'main.dart',
              leading: Icon(LucideIcons.file),
              trailing: Icon(LucideIcons.star),
            ),
          ],
        ),
      );
      expect(
        tester.getSize(_icon(LucideIcons.file)),
        const Size.square(16),
      );
      expect(
        tester.getSize(_icon(LucideIcons.star)),
        const Size.square(16),
      );
    });

    testWidgets('a per-instance slotIconStyle moves them', (tester) async {
      await _pump(
        tester,
        _strip(
          variant: CoreTabPaneVariant.boxed,
          style: const CoreTabPaneStyle(
            slotIconStyle: CoreIconStyle(size: CoreIconSize.size20),
          ),
          tabs: const [
            CoreTabItem<Widget>(
              label: 'main.dart',
              leading: Icon(LucideIcons.file),
            ),
          ],
        ),
      );
      expect(
        tester.getSize(_icon(LucideIcons.file)),
        const Size.square(20),
      );
    });
  });
}
