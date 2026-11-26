import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// #6406: a bar's destination stops growing at 96 and the destinations
/// gather in the middle, so a bar as wide as a tablet does not spread them
/// about 200 apart. A phone's share is under the cap and draws as before.
/// Read off the rendered boxes, not the resolver.
void main() {
  const items = [
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.house),
      label: 'Home',
    ),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.search),
      label: 'Search',
    ),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.bell),
      label: 'Alerts',
    ),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.user),
      label: 'Me',
    ),
  ];

  Future<List<Rect>> destinations(
    WidgetTester tester, {
    required double width,
    CoreNavigationBarMode mode = CoreNavigationBarMode.bar,
    CoreNavigationBarStyle? style,
  }) async {
    await pumpTestApp(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          height: mode == CoreNavigationBarMode.bar ? null : 600,
          child: NavigationBar(
            mode: mode,
            selectedIndex: 0,
            onSelected: (_) {},
            navigationBarStyle: style,
            items: items,
          ),
        ),
      ),
    );
    await tester.pump();
    return [
      for (final element in find.byType(NavigationBarItem).evaluate())
        tester.getRect(find.byWidget(element.widget)),
    ];
  }

  testWidgets('a wide bar caps each destination at 96 and centres them', (
    tester,
  ) async {
    final rects = await destinations(tester, width: 834);
    expect(rects, hasLength(4));
    for (final rect in rects) {
      expect(rect.width, 96);
    }
    // Flush with each other — the bar's spacing is 0.
    for (var i = 1; i < rects.length; i++) {
      expect(rects[i].left, closeTo(rects[i - 1].right, 0.01));
    }
    final bar = tester.getRect(find.byType(NavigationBar));
    final leftGap = rects.first.left - bar.left;
    final rightGap = bar.right - rects.last.right;
    expect(leftGap, closeTo(rightGap, 0.01));
    expect(leftGap, greaterThan(0));
  });

  testWidgets('a phone-wide bar keeps its equal shares under the cap', (
    tester,
  ) async {
    final rects = await destinations(tester, width: 360);
    final bar = tester.getRect(find.byType(NavigationBar));
    // 360 less the bar's 12 at each side, in four equal shares.
    const share = (360 - 24) / 4;
    for (final rect in rects) {
      expect(rect.width, closeTo(share, 0.01));
      expect(rect.width, lessThan(96));
    }
    expect(rects.first.left, closeTo(bar.left + 12, 0.01));
    expect(rects.last.right, closeTo(bar.right - 12, 0.01));
  });

  testWidgets('a caller can lift the cap', (tester) async {
    final rects = await destinations(
      tester,
      width: 834,
      style: const CoreNavigationBarStyle(itemMaxWidth: double.infinity),
    );
    // Back to equal shares spanning the row, flush with each other.
    expect(rects.map((rect) => rect.width).toSet(), hasLength(1));
    expect(rects.first.width, greaterThan(96));
    for (var i = 1; i < rects.length; i++) {
      expect(rects[i].left, closeTo(rects[i - 1].right, 0.01));
    }
  });

  testWidgets('the rail keeps its own column width', (tester) async {
    final rects = await destinations(
      tester,
      width: 400,
      mode: CoreNavigationBarMode.rail,
    );
    final widths = rects.map((rect) => rect.width).toSet();
    expect(widths, hasLength(1), reason: 'every rail destination is as wide');
    final capped = await destinations(
      tester,
      width: 400,
      mode: CoreNavigationBarMode.rail,
      style: const CoreNavigationBarStyle(itemMaxWidth: double.infinity),
    );
    expect(
      capped.map((rect) => rect.width).toList(),
      rects.map((rect) => rect.width).toList(),
    );
  });

  testWidgets('the floating glass bar is not capped', (tester) async {
    const glass = CoreNavigationBarStyle(surfaceStyle: .liquidGlass);
    final rects = await destinations(tester, width: 834, style: glass);
    for (final rect in rects) {
      expect(rect.width, greaterThan(96));
    }
    final widths = rects.map((rect) => rect.width).toSet();
    expect(widths, hasLength(1));
  });
}
