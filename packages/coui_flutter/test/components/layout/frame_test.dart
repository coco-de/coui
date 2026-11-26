import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// Captures the [BuildContext] under a [Theme] so `resolveFrame` can be
/// exercised directly (it is the single public resolver — Epic #1603 C1).
Future<BuildContext> _contextUnder(
  WidgetTester tester,
  ThemeData theme,
) async {
  late BuildContext captured;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: theme,
        child: Builder(
          builder: (context) {
            captured = context;
            return const material.SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return captured;
}

const _kTokenBorderWidth = 3.0;
const _kScaling = 2.0;

void main() {
  group('resolveFrame', () {
    testWidgets('C7: token background resolves through the scheme', (
      tester,
    ) async {
      const theme = ThemeData();
      final context = await _contextUnder(tester, theme);
      final scheme = theme.colorScheme;

      final resolved = resolveFrame(
        context,
        clipBehavior: CoreFrameStyle.defaultClipBehavior,
        backgroundColor: const CoreColor.token(CoreColors.primary),
      );

      // Must equal the scheme-resolved colour — never `Color(token.value)`
      // which would bypass the active palette (#1601 dark-mode class).
      expect(
        resolved.backgroundColor,
        equals(
          scheme.resolve(const CoreColor.token(CoreColors.primary)).toValue(),
        ),
      );
      expect(resolved.backgroundColor, isNot(const Color(0x00000000)));
    });

    testWidgets('C7: same token resolves differently under dark scheme', (
      tester,
    ) async {
      final lightTheme = ThemeData.fromCore(CoreThemePresets.light);
      final darkTheme = ThemeData.fromCore(CoreThemePresets.dark);
      final lightContext = await _contextUnder(tester, lightTheme);
      final lightResolved = resolveFrame(
        lightContext,
        clipBehavior: CoreFrameStyle.defaultClipBehavior,
        backgroundColor: const CoreColor.token(CoreColors.surface),
      );
      final darkContext = await _contextUnder(tester, darkTheme);
      final darkResolved = resolveFrame(
        darkContext,
        clipBehavior: CoreFrameStyle.defaultClipBehavior,
        backgroundColor: const CoreColor.token(CoreColors.surface),
      );

      expect(lightResolved.backgroundColor, isNotNull);
      expect(darkResolved.backgroundColor, isNotNull);
      // A token bypass (`Color(token.value)`) would yield the same ARGB
      // for both schemes; routing through `scheme.resolve` keeps them
      // distinct (Epic #1603 C7).
      expect(
        lightResolved.backgroundColor,
        isNot(equals(darkResolved.backgroundColor)),
      );
    });

    testWidgets('C11: border width carries scaling pre-applied', (
      tester,
    ) async {
      const theme = ThemeData(scaling: _kScaling);
      final context = await _contextUnder(tester, theme);

      final resolved = resolveFrame(
        context,
        clipBehavior: CoreFrameStyle.defaultClipBehavior,
        borderColor: const CoreColor.token(CoreColors.outline),
        borderWidth: _kTokenBorderWidth,
      );

      expect(resolved.borderWidth, equals(_kTokenBorderWidth * _kScaling));
    });

    testWidgets('C9: elevation preset resolves to a paint-ready shadow', (
      tester,
    ) async {
      const theme = ThemeData();
      final context = await _contextUnder(tester, theme);

      final none = resolveFrame(
        context,
        clipBehavior: CoreFrameStyle.defaultClipBehavior,
      );
      final soft = resolveFrame(
        context,
        clipBehavior: CoreFrameStyle.defaultClipBehavior,
        elevation: .soft,
      );

      expect(none.boxShadow, isEmpty);
      expect(soft.boxShadow, isNotEmpty);
      // Matches the canonical OutlinedContainer geometry (single source).
      expect(
        soft.boxShadow.first.blurRadius,
        equals(
          CoreOutlinedContainerElevation.soft
              .toValue(
                base: const Color(0xFF000000),
                geometry: const CoreSurfaceGeometryConstraint(),
              )
              .first
              .blurRadius,
        ),
      );
    });

    testWidgets('caller boxShadow override wins over elevation preset', (
      tester,
    ) async {
      const theme = ThemeData();
      final context = await _contextUnder(tester, theme);

      final resolved = resolveFrame(
        context,
        clipBehavior: CoreFrameStyle.defaultClipBehavior,
        elevation: .strong,
        boxShadow: const [],
      );

      // Explicit (empty) override replaces the strong-elevation stack.
      expect(resolved.boxShadow, isEmpty);
    });

    testWidgets('C2: frameStyle overrides theme style via the merge chain', (
      tester,
    ) async {
      const theme = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          frame: CoreFrameTheme(
            style: CoreFrameStyle(elevation: .soft),
          ),
        ),
      );
      final context = await _contextUnder(tester, theme);

      final resolved = resolveFrame(
        context,
        clipBehavior: CoreFrameStyle.defaultClipBehavior,
        frameStyle: const CoreFrameStyle(elevation: .strong),
      );

      expect(resolved.elevation, equals(CoreFrameElevation.strong));
    });

    testWidgets('clip behaviour falls back to the theme style override', (
      tester,
    ) async {
      const theme = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          frame: CoreFrameTheme(
            style: CoreFrameStyle(clipBehavior: .antiAlias),
          ),
        ),
      );
      final context = await _contextUnder(tester, theme);

      // Widget passes the contract default → theme override wins.
      final resolved = resolveFrame(
        context,
        clipBehavior: CoreFrameStyle.defaultClipBehavior,
      );

      expect(resolved.clipBehavior, equals(Clip.antiAlias));
    });
  });

  group('Frame widget', () {
    testWidgets('paints a token background through BoxDecoration', (
      tester,
    ) async {
      const theme = ThemeData();
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: theme,
            child: const Frame(
              backgroundColor: CoreColor.token(CoreColors.primary),
              child: material.SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.color,
        equals(
          theme.colorScheme
              .resolve(const CoreColor.token(CoreColors.primary))
              .toValue(),
        ),
      );
    });
  });
}
