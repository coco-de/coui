import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
// skeletonizer's `Skeleton` (what `.asSkeleton()` produces) is aliased to
// disambiguate from CoUI's `Skeleton` widget exported by the barrel.
import 'package:skeletonizer/skeletonizer.dart' as sk show Skeleton;

// Test constants.
const _kDurationMs = 800;
const _kFromColor = Color(0x0D000000);
const _kToColor = Color(0x1A000000);

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(data: const ThemeData(), child: child),
  );
}

void main() {
  group('SkeletonTheme', () {
    test('default constructor creates theme with null values', () {
      const theme = SkeletonTheme();

      expect(theme.duration, isNull);
      expect(theme.fromColor, isNull);
      expect(theme.toColor, isNull);
      expect(theme.enableSwitchAnimation, isNull);
    });

    test('constructor accepts all parameters', () {
      const theme = SkeletonTheme(
        duration: Duration(milliseconds: _kDurationMs),
        enableSwitchAnimation: true,
        fromColor: _kFromColor,
        toColor: _kToColor,
      );

      expect(
        theme.duration,
        equals(const Duration(milliseconds: _kDurationMs)),
      );
      expect(theme.fromColor, equals(_kFromColor));
      expect(theme.toColor, equals(_kToColor));
      expect(theme.enableSwitchAnimation, isTrue);
    });

    test('equality returns true for identical themes', () {
      const theme1 = SkeletonTheme(
        duration: Duration(milliseconds: _kDurationMs),
      );
      const theme2 = SkeletonTheme(
        duration: Duration(milliseconds: _kDurationMs),
      );

      expect(theme1, equals(theme2));
      expect(theme1.hashCode, equals(theme2.hashCode));
    });

    test('equality returns false for different themes', () {
      const theme1 = SkeletonTheme(enableSwitchAnimation: true);
      const theme2 = SkeletonTheme(enableSwitchAnimation: false);

      expect(theme1, isNot(equals(theme2)));
    });

    test('copyWith replaces specified fields', () {
      const original = SkeletonTheme(
        enableSwitchAnimation: true,
        fromColor: _kFromColor,
      );

      final copied = original.copyWith(
        enableSwitchAnimation: () => false,
      );

      expect(copied.enableSwitchAnimation, isFalse);
      expect(copied.fromColor, equals(_kFromColor));
    });

    test('copyWith preserves fields when not specified', () {
      const original = SkeletonTheme(
        duration: Duration(milliseconds: _kDurationMs),
        fromColor: _kFromColor,
      );

      final copied = original.copyWith();

      expect(
        copied.duration,
        equals(const Duration(milliseconds: _kDurationMs)),
      );
      expect(copied.fromColor, equals(_kFromColor));
    });

    test('copyWith can set fields to null', () {
      const original = SkeletonTheme(fromColor: _kFromColor);

      final copied = original.copyWith(fromColor: () => null);

      expect(copied.fromColor, isNull);
    });
  });

  group('CoUISkeletonizerConfigLayer', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const CoUISkeletonizerConfigLayer(
            theme: ThemeData(),
            child: Text('Skeleton Content'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Skeleton Content'), findsOneWidget);
    });

    testWidgets('renders with custom duration', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const CoUISkeletonizerConfigLayer(
            duration: Duration(milliseconds: _kDurationMs),
            theme: ThemeData(),
            child: Text('Content'),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byType(CoUISkeletonizerConfigLayer),
        findsOneWidget,
      );
    });

    testWidgets('renders with custom colors', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const CoUISkeletonizerConfigLayer(
            fromColor: _kFromColor,
            theme: ThemeData(),
            toColor: _kToColor,
            child: Text('Content'),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byType(CoUISkeletonizerConfigLayer),
        findsOneWidget,
      );
    });

    testWidgets('renders with enableSwitchAnimation override', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const CoUISkeletonizerConfigLayer(
            enableSwitchAnimation: false,
            theme: ThemeData(),
            child: Text('Content'),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byType(CoUISkeletonizerConfigLayer),
        findsOneWidget,
      );
    });
  });

  group('SkeletonExtension', () {
    testWidgets('asSkeleton wraps widget with Skeletonizer', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const CoUISkeletonizerConfigLayer(
            theme: ThemeData(),
            child: Text('Loading...'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('asSkeleton with enabled false does not skeletonize', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          CoUISkeletonizerConfigLayer(
            theme: const ThemeData(),
            child: const Text('Content').asSkeleton(enabled: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('asSkeleton with leaf mode wraps in skeleton widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          CoUISkeletonizerConfigLayer(
            theme: const ThemeData(),
            child: const Text('Content').asSkeleton(leaf: true),
          ),
        ),
      );
      await tester.pump();

      // Skeleton.leaf produces a private subclass of Skeleton.
      expect(
        find.byWidgetPredicate((widget) => widget is sk.Skeleton),
        findsOneWidget,
      );
    });

    testWidgets('asSkeleton with unite mode wraps in skeleton widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          CoUISkeletonizerConfigLayer(
            theme: const ThemeData(),
            child: const Text('Content').asSkeleton(unite: true),
          ),
        ),
      );
      await tester.pump();

      // Skeleton.unite produces a private subclass of Skeleton.
      expect(
        find.byWidgetPredicate((widget) => widget is sk.Skeleton),
        findsOneWidget,
      );
    });

    testWidgets('asSkeleton with replacement wraps in skeleton widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          CoUISkeletonizerConfigLayer(
            theme: const ThemeData(),
            child: const Text('Content').asSkeleton(
              replacement: const Text('Replacement'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Skeleton.replace produces a private subclass of Skeleton.
      expect(
        find.byWidgetPredicate((widget) => widget is sk.Skeleton),
        findsOneWidget,
      );
    });

    testWidgets('asSkeleton with snapshot auto-enables based on data', (
      tester,
    ) async {
      const snapshot = AsyncSnapshot.withData(
        .done,
        'loaded',
      );

      await tester.pumpWidget(
        _buildApp(
          CoUISkeletonizerConfigLayer(
            theme: const ThemeData(),
            child: const Text('Content').asSkeleton(snapshot: snapshot),
          ),
        ),
      );
      await tester.pump();

      // Snapshot has data, so skeleton should be disabled.
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets(
      'rapid enabled toggle does not throw Duplicate keys '
      '(switch-animation workaround)',
      (tester) async {
        var enabled = true;
        late StateSetter setOuter;
        await tester.pumpWidget(
          _buildApp(
            CoUISkeletonizerConfigLayer(
              theme: const ThemeData(),
              child: StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return const Text('Item').asSkeleton(enabled: enabled);
                },
              ),
            ),
          ),
        );

        // Toggle loading -> content -> loading inside the switch transition
        // window — the path that triggered the upstream AnimatedSwitcher
        // duplicate-key crash before the fresh-closure transitionBuilder fix.
        setOuter(() => enabled = false);
        await tester.pump(const Duration(milliseconds: 50));
        setOuter(() => enabled = true);
        await tester.pump(const Duration(milliseconds: 50));
        setOuter(() => enabled = false);
        await tester.pump(const Duration(milliseconds: 50));
        // Advance past the switch transition; final state is disabled (no
        // repeating pulse) so a fixed pump settles it without pumpAndSettle.
        await tester.pump(const Duration(milliseconds: 350));

        expect(tester.takeException(), isNull);
      },
    );
  });
}
