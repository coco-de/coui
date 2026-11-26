import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CoUIApp publishes its density to descendants, and the '
      'default when it states none', (tester) async {
    // The app reads the density here; components never do — it reaches
    // them through the theme's geometry.
    late CoreDensity seen;
    Widget app({CoreDensity? density}) {
      final probe = Builder(
        builder: (context) {
          seen = DensityScope.of(context);
          return const SizedBox.shrink();
        },
      );
      final theme = ThemeData.fromCore(CoreThemePresets.light);

      return density == null
          ? CoUIApp(theme: theme, home: probe)
          : CoUIApp(theme: theme, density: density, home: probe);
    }

    await tester.pumpWidget(app(density: .spacious));
    expect(seen, CoreDensity.spacious);

    await tester.pumpWidget(app(density: .compact));
    expect(seen, CoreDensity.compact, reason: 'a switch reaches readers');

    await tester.pumpWidget(app());
    expect(seen, CoreDensity.defaultDensity);
  });
}
