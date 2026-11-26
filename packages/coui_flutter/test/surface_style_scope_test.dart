import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the scope publishes the active style', () {
    testWidgets('a subtree reads what was set', (tester) async {
      late CoreSurfaceStyleId seen;

      await tester.pumpWidget(
        SurfaceStyleScope(
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          child: Builder(
            builder: (context) {
              seen = SurfaceStyleScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen, CoreSurfaceStyleId.neoBrutalism);
    });

    testWidgets('no scope reads as the default', (tester) async {
      // An app that never opted in must keep working rather than fail to
      // find an ancestor.
      late CoreSurfaceStyleId seen;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            seen = SurfaceStyleScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(seen, CoreSurfaceStyleId.defaultId);
    });
  });

  group('switching rebuilds dependents', () {
    testWidgets('a changed style notifies, an unchanged one does not', (
      tester,
    ) async {
      // This is the platform's transport for the axis. If the scope failed
      // to notify, the style would be computed correctly and never reach
      // the screen — a failure no screenshot explains.
      var builds = 0;

      // One child instance across all three pumps, so what is measured is
      // the scope's notification and not the cost of handing the tester a
      // freshly built closure each time.
      final child = Builder(
        builder: (context) {
          SurfaceStyleScope.of(context);
          builds++;
          return const SizedBox.shrink();
        },
      );

      Widget app(CoreSurfaceStyleId style) =>
          SurfaceStyleScope(surfaceStyle: style, child: child);

      await tester.pumpWidget(app(CoreSurfaceStyleId.defaultStyle));
      expect(builds, 1);

      await tester.pumpWidget(app(CoreSurfaceStyleId.liquidGlass));
      expect(builds, 2);

      await tester.pumpWidget(app(CoreSurfaceStyleId.liquidGlass));
      expect(builds, 2, reason: 'same style must not churn the subtree');
    });
  });

  group('the app installs the scope', () {
    testWidgets('CoUIApp publishes its style to descendants', (tester) async {
      late CoreSurfaceStyleId seen;

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.claymorphism,
          home: Builder(
            builder: (context) {
              seen = SurfaceStyleScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen, CoreSurfaceStyleId.claymorphism);
    });

    testWidgets('an app that states nothing gets the default', (tester) async {
      late CoreSurfaceStyleId seen;

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Builder(
            builder: (context) {
              seen = SurfaceStyleScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen, CoreSurfaceStyleId.defaultId);
    });
  });
}
