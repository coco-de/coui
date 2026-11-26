import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/examples/flutter/navigation_bar/navigation_bar_compact_example.dart';
import 'package:flutter_test/flutter_test.dart';

/// The docs example for `NavigationBar.compact` has to do what its section
/// says when a reader scrolls it: the scaffold's body scrolls, and the bar
/// floating over it is drawn smaller and returns. An example that only
/// compiled would leave the page describing a motion the preview never
/// shows — the bar needs the scaffold above it to hear the body, and the
/// floating glass form to have a compact size.
void main() {
  /// The transform the bar's compact form is drawn through: the outermost
  /// one under the bar.
  double compactScale(WidgetTester tester) => tester
      .widget<AnimatedScale>(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.byType(AnimatedScale),
            )
            .first,
      )
      .scale;

  testWidgets('scrolling the example draws its bar compact, and back', (
    tester,
  ) async {
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.previewLight),
        home: const Center(
          child: SizedBox(width: 360, child: NavigationBarCompactExample()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(compactScale(tester), 1);

    final body = find.byType(SingleChildScrollView).first;
    await tester.drag(body, const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(compactScale(tester), CoreNavigationBarStyle.glassCompactScale);

    await tester.drag(body, const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(compactScale(tester), 1);
  });
}
