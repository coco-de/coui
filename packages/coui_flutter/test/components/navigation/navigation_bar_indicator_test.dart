import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// How a destination marks the current place (#5740, #6358), read back where
/// it lands — the box a destination paints and the colour its icon is
/// handed — so an indicator cell nobody reads fails here.
///
/// Both indicators paint the selected destination's whole tile in
/// [CoreNavigationBarStyle.defaultSelectedFaceColor] with a `primary` label
/// and glyph; they differ on hover only — `fill` lays the state layer's
/// wash, `color` lays none and darkens the foreground.
Color _color(WidgetTester tester, CoreColor color) {
  final context = tester.element(find.byType(NavigationBar));
  return Theme.of(context).colorScheme.resolve(color).toValue();
}

Color _token(WidgetTester tester, CoreColorToken token) =>
    _color(tester, CoreColor.token(token));

Widget _bar(
  CoreNavigationBarMode mode, {
  CoreNavigationLabelMode? labelMode,
  CoreNavigationSelectionIndicator? indicator,
  CoreNavigationBarStyle? style,
  bool showDot = false,
  Widget? header,
}) {
  return SizedBox(
    width: mode == .bar ? 360 : null,
    height: mode == .bar ? null : 480,
    child: NavigationBar(
      mode: mode,
      labelMode: labelMode,
      indicator: indicator,
      navigationBarStyle: style,
      header: header,
      selectedIndex: 0,
      onSelected: (_) {},
      items: [
        const CoreNavigationBarItem.destination(
          icon: _IconColorProbe('home'),
          label: 'Home',
        ),
        CoreNavigationBarItem.destination(
          icon: const _IconColorProbe('inbox'),
          label: 'Inbox',
          showDot: showDot,
        ),
      ],
    ),
  );
}

/// The destination's own box — the `AnimatedContainer` that carries its
/// padding and minimum height. It is the only painted box a destination
/// has: no pill wraps the icon (#6358).
BoxDecoration _itemFace(WidgetTester tester, String label) {
  final container = tester.widget<AnimatedContainer>(
    find.ancestor(
      of: find.byKey(ValueKey('probe-$label')),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

/// The box a stacked destination keeps around its icon — layout only.
Finder _iconBox(String label) => find
    .ancestor(
      of: find.byKey(ValueKey('probe-$label')),
      matching: find.byType(Padding),
    )
    .first;

Color? _iconColor(WidgetTester tester, String label) {
  return IconTheme.of(
    tester.element(find.byKey(ValueKey('probe-$label'))),
  ).color;
}

TextStyle _label(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

/// The selection every placement states: the tile face, a `primary` glyph
/// and a bold `primary` label.
/// The selection: a `primary` glyph and a bold `primary` label, over the
/// tile face under `fill` — and under `color` over no face (#6393).
void _expectSelected(
  WidgetTester tester, {
  CoreNavigationSelectionIndicator indicator =
      CoreNavigationSelectionIndicator.fill,
  bool labelShown = true,
}) {
  final face = _itemFace(tester, 'home').color;
  if (indicator == CoreNavigationSelectionIndicator.fill) {
    expect(
      face,
      _color(tester, CoreNavigationBarStyle.defaultSelectedFaceColor),
    );
  } else {
    expect(face?.a ?? 0, 0);
  }
  expect(_iconColor(tester, 'home'), _token(tester, CoreColors.primary));
  if (labelShown) {
    final label = _label(tester, 'Home');
    expect(label.color, _token(tester, CoreColors.primary));
    expect(label.fontWeight, fontWeightFromInt(CoreFontWeight.bold));
  }
}

Future<void> _hover(WidgetTester tester, String label) async {
  // A hover highlight shows only in the traditional (pointer) mode.
  final previous = FocusManager.instance.highlightStrategy;
  FocusManager.instance.highlightStrategy = .alwaysTraditional;
  addTearDown(() => FocusManager.instance.highlightStrategy = previous);
  await tester.pumpAndSettle();
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(
    tester.getCenter(find.byKey(ValueKey('probe-$label'))),
  );
  await tester.pumpAndSettle();
}

/// The bar's face with the state-layer ink laid at [weight] — restated from
/// Core so the expectation is not read off the resolver.
Color _washed(WidgetTester tester, CoreColorToken barFace, double weight) {
  final ink = _color(tester, CoreNavigationBarStyle.defaultStateLayerColor);
  return Color.alphaBlend(
    ink.withValues(alpha: weight),
    _token(tester, barFace),
  );
}

void main() {
  group('the mode picks the indicator', () {
    test('the bar marks with colour, the vertical modes with a tile', () {
      expect(
        CoreNavigationBarMode.bar.defaultIndicator,
        CoreNavigationSelectionIndicator.color,
      );
      expect(
        CoreNavigationBarMode.rail.defaultIndicator,
        CoreNavigationSelectionIndicator.fill,
      );
      expect(
        CoreNavigationBarMode.sidebar.defaultIndicator,
        CoreNavigationSelectionIndicator.fill,
      );
    });

    testWidgets('every rail destination is named', (tester) async {
      await pumpTestApp(tester, _bar(.rail));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
    });
  });

  group('color', () {
    testWidgets('the selected destination paints no face, its icon and '
        'label are primary', (tester) async {
      await pumpTestApp(tester, _bar(.bar, labelMode: .all));

      _expectSelected(tester, indicator: .color);
      expect(
        _iconColor(tester, 'inbox'),
        _token(tester, CoreColors.onSurfaceSubtle),
      );
    });

    testWidgets('hover lays no wash and darkens the foreground', (
      tester,
    ) async {
      await pumpTestApp(tester, _bar(.bar, labelMode: .all));
      await _hover(tester, 'inbox');

      // The bottom bar sits on `surface`; with no wash the hovered tile is
      // the bar itself.
      expect(
        _itemFace(tester, 'inbox').color,
        _token(tester, CoreColors.surface),
      );
      expect(_iconColor(tester, 'inbox'), _token(tester, CoreColors.onSurface));
      expect(
        _label(tester, 'Inbox').color,
        _token(tester, CoreColors.onSurface),
      );
    });
  });

  group('fill', () {
    testWidgets('the selected rail destination paints its whole tile', (
      tester,
    ) async {
      await pumpTestApp(tester, _bar(.rail));

      // #6358 — the tile is the selection, label shown or hidden.
      _expectSelected(tester);
    });

    testWidgets('a hidden label keeps the selection on the tile', (
      tester,
    ) async {
      await pumpTestApp(tester, _bar(.rail, labelMode: .none));

      _expectSelected(tester, labelShown: false);
      // Every stacked destination keeps the 48 × 28 icon box, so the
      // destinations stay the same width whichever is selected — but the
      // box paints nothing.
      expect(tester.getSize(_iconBox('home')), const Size(48, 28));
      expect(
        find.descendant(
          of: _iconBox('home'),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('a bar asking for fill paints the same tile face', (
      tester,
    ) async {
      await pumpTestApp(tester, _bar(.bar, labelMode: .all, indicator: .fill));
      _expectSelected(tester);
    });

    testWidgets('a bar asking for fill lays the wash on hover', (
      tester,
    ) async {
      await pumpTestApp(tester, _bar(.bar, labelMode: .all, indicator: .fill));
      await _hover(tester, 'inbox');

      expect(
        _itemFace(tester, 'inbox').color,
        _washed(
          tester,
          CoreColors.surface,
          CoreNavigationBarStyle.defaultStateLayer.hover,
        ),
      );
    });
  });

  group('the deprecated pill fields paint nothing', () {
    for (final indicator in CoreNavigationSelectionIndicator.values) {
      testWidgets(indicator.name, (tester) async {
        await pumpTestApp(
          tester,
          _bar(
            .rail,
            indicator: indicator,
            style: const CoreNavigationBarStyle(
              // The no-op is what is under test.
              // ignore: deprecated_member_use
              selectedIconAnchorColor: CoreColor(0xFFFF0000),
              // The no-op is what is under test.
              // ignore: deprecated_member_use
              selectedIconAnchorIconStyle: CoreIconStyle(
                color: CoreColor(0xFF00FF00),
              ),
              // The no-op is what is under test.
              // ignore: deprecated_member_use
              iconAnchorRadius: CoreBorderRadius.all(CoreRadius.radius9999),
            ),
          ),
        );

        _expectSelected(tester, indicator: indicator);
      });
    }
  });

  group('notification dot and header', () {
    testWidgets('showDot lays a dot on the icon, a badge-free destination '
        'only', (tester) async {
      await pumpTestApp(tester, _bar(.rail, showDot: true));

      final dots = tester
          .widgetList<Badge>(find.byType(Badge))
          .where((badge) => badge.form == CoreBadgeForm.dot)
          .toList();
      expect(dots, hasLength(1));
      expect(
        dots.single.badgeStyle,
        CoreNavigationBarStyle.defaultNotificationDotStyle,
      );
    });

    testWidgets('the header sits before the destinations', (tester) async {
      await pumpTestApp(
        tester,
        _bar(
          .rail,
          header: const SizedBox(
            key: ValueKey('logo'),
            width: 40,
            height: 40,
          ),
        ),
      );

      final logo = tester.getRect(find.byKey(const ValueKey('logo')));
      final home = tester.getRect(find.text('Home'));
      expect(logo.bottom, lessThanOrEqualTo(home.top));
    });
  });
}

class _IconColorProbe extends StatelessWidget {
  const _IconColorProbe(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(key: ValueKey('probe-$name'), dimension: 24);
  }
}
