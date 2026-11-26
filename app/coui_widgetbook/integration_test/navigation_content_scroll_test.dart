// Run on a simulator/device with navigation_content_scroll_driver.dart.
// Uses the host's real view and touch gestures; screenshots are observations,
// not golden comparisons or performance measurements.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _outerKey = ValueKey<String>('outer-content');
const _innerKey = ValueKey<String>('nested-content');
const _items = [
  CoreNavigationBarItem<Widget>.destination(
    icon: Icon(LucideIcons.house),
    label: 'Home',
  ),
  CoreNavigationBarItem<Widget>.destination(
    icon: Icon(LucideIcons.search),
    label: 'Search',
  ),
  CoreNavigationBarItem<Widget>.destination(
    icon: Icon(LucideIcons.user),
    label: 'Profile',
  ),
];

double _scale(WidgetTester tester) => tester
    .widget<AnimatedScale>(
      find
          .descendant(
            of: find.byType(NavigationBar),
            matching: find.byType(AnimatedScale),
          )
          .first,
    )
    .scale;

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  final drawn = tester.widget<ScaleTransition>(
    find
        .descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(ScaleTransition),
        )
        .first,
  );
  expect(drawn.scale.value, closeTo(_scale(tester), 0.001));
  // iOS captures its native surface asynchronously. Give the raster thread
  // time to present the settled frame before asking UIKit for a screenshot.
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await binding.takeScreenshot(name);
  });
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final measurements = <String, Object?>{};
  for (final dark in [false, true]) {
    final themeName = dark ? 'dark' : 'light';
    testWidgets('visible content drives compaction ($themeName)', (
      tester,
    ) async {
      final outer = ScrollController();
      final inner = ScrollController();
      final rows = ValueNotifier<int>(30);
      addTearDown(() {
        outer.dispose();
        inner.dispose();
        rows.dispose();
      });
      await tester.pumpWidget(
        CoUIApp(
          key: ValueKey(themeName),
          theme: ThemeData.fromCore(
            dark ? CoreThemePresets.dark : CoreThemePresets.light,
          ),
          home: SafeArea(
            child: Scaffold(
              floatingFooter: true,
              footers: [
                NavigationBar(
                  items: _items,
                  selectedIndex: 0,
                  onSelected: (_) {},
                  compact: .onScroll,
                  navigationBarStyle: const CoreNavigationBarStyle(
                    surfaceStyle: .liquidGlass,
                  ),
                ),
              ],
              child: Stack(
                children: [
                  ListView(
                    key: _outerKey,
                    controller: outer,
                    children: [
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          key: _innerKey,
                          controller: inner,
                          itemExtent: 48,
                          itemCount: 30,
                          itemBuilder: (_, i) => Center(
                            child: Text('Nested list — row $i'),
                          ),
                        ),
                      ),
                      for (var i = 0; i < 40; i++)
                        SizedBox(
                          height: 64,
                          child: Center(child: Text('Main content — row $i')),
                        ),
                    ],
                  ),
                  Offstage(
                    child: ValueListenableBuilder<int>(
                      valueListenable: rows,
                      builder: (_, count, _) => ListView.builder(
                        itemExtent: 48,
                        itemCount: count,
                        itemBuilder: (_, i) => Text('Inactive tab — row $i'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_scale(tester), 1);
      await _capture(binding, tester, '$themeName-resting');

      await tester.drag(find.byKey(_innerKey), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(inner.offset, greaterThan(0));
      expect(outer.offset, 0);
      expect(_scale(tester), 1, reason: 'Inner list must not compact the bar');
      final innerOffset = inner.offset;
      await _capture(binding, tester, '$themeName-nested-scroll');

      await tester.drag(find.byKey(_outerKey), const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(outer.offset, greaterThan(0));
      expect(_scale(tester), CoreNavigationBarStyle.glassCompactScale);
      final compactOffset = outer.offset;
      await _capture(binding, tester, '$themeName-compact');

      rows.value = 60;
      await tester.pumpAndSettle();
      expect(
        _scale(tester),
        CoreNavigationBarStyle.glassCompactScale,
        reason: 'A hidden tab resizing at offset zero must not restore the bar',
      );
      await _capture(binding, tester, '$themeName-hidden-tab-update');

      await tester.drag(find.byKey(_outerKey), const Offset(0, 80));
      await tester.pumpAndSettle();
      expect(outer.offset, lessThan(compactOffset));
      expect(_scale(tester), 1);
      await _capture(binding, tester, '$themeName-restored');
      measurements[themeName] = {
        'physicalSize': tester.view.physicalSize.toString(),
        'devicePixelRatio': tester.view.devicePixelRatio,
        'viewPadding': {
          'left': tester.view.viewPadding.left,
          'top': tester.view.viewPadding.top,
          'right': tester.view.viewPadding.right,
          'bottom': tester.view.viewPadding.bottom,
        },
        'innerOffset': innerOffset,
        'compactOuterOffset': compactOffset,
        'restoredOuterOffset': outer.offset,
        'compactScale': CoreNavigationBarStyle.glassCompactScale,
        'restoredScale': _scale(tester),
      };
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['measurements'] = measurements;
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
