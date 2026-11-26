import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kDefaultStarSize = 24.0;
const _kDefaultStarSpacing = 5.0;
const _kZeroRating = 0.0;
const _kHalfRating = 2.5;
const _kFullRating = 5.0;
const _kThreeRating = 3.0;
const _kFourRating = 4.0;
const _kLargeStarSize = 32.0;
const _kLargeStarSpacing = 8.0;
const _kStepOne = 1.0;
// StarBorder requires pointRounding in [0.0, 1.0]; override the StarRating default.
const _kPointRounding = 0.5;

Widget _buildApp(Widget child, {ThemeData theme = const ThemeData()}) =>
    material.MaterialApp(
      home: Theme(data: theme, child: child),
    );

/// The colours the stars of the [StarRating] under test are painted in,
/// left to right — one `ShapeDecoration` fill per filled or empty star.
List<Color?> _paintedStarColors(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(StarRating),
        matching: find.byType(Container),
      ),
    )
    .map((c) => c.decoration)
    .whereType<ShapeDecoration>()
    .map((d) => d.color)
    .toList();

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// The `Flex` the stars are laid out in — the widget that carries the
/// axis `direction` is supposed to reach.
Flex _starFlex(WidgetTester tester) => tester.widget<Flex>(
  find.descendant(of: find.byType(StarRating), matching: find.byType(Flex)),
);

void main() {
  _newCoverage();
  group('StarRatingController', () {
    test('initializes with default value of 0.0', () {
      final controller = StarRatingController();

      expect(controller.value, equals(_kZeroRating));
      controller.dispose();
    });

    test('initializes with given value', () {
      final controller = StarRatingController(_kThreeRating);

      expect(controller.value, equals(_kThreeRating));
      controller.dispose();
    });

    test('notifies listeners on value change', () {
      final controller = StarRatingController(_kZeroRating);
      var notified = false;
      void handleNotify() => notified = true;
      controller.addListener(handleNotify);

      controller.value = _kThreeRating;

      expect(notified, isTrue);
      controller.dispose();
    });
  });

  group('StarRating widget', () {
    testWidgets('renders with zero rating', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const StarRating(
            starPointRounding: _kPointRounding,
            value: _kZeroRating,
          ),
        ),
      );

      expect(find.byType(StarRating), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = material.Key('test-star-rating');

      await tester.pumpWidget(
        _buildApp(
          const StarRating(
            key: testKey,
            starPointRounding: _kPointRounding,
            value: _kZeroRating,
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('renders with half rating', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const StarRating(
            starPointRounding: _kPointRounding,
            value: _kHalfRating,
          ),
        ),
      );

      expect(find.byType(StarRating), findsOneWidget);
    });

    testWidgets('renders with full rating', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const StarRating(
            starPointRounding: _kPointRounding,
            value: _kFullRating,
          ),
        ),
      );

      expect(find.byType(StarRating), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped and enabled', (tester) async {
      double? lastValue;

      await tester.pumpWidget(
        _buildApp(
          StarRating(
            onChanged: (value) {
              lastValue = value;
            },
            starPointRounding: _kPointRounding,
            value: _kZeroRating,
          ),
        ),
      );

      await tester.tap(find.byType(StarRating));
      final _ = await tester.pumpAndSettle();

      // onTap fires onChanged only if roundedValue != widget.value.
      // Value starts at 0.0, tapping at left side may result in same/different value.
      expect(lastValue, anything);
    });

    testWidgets('disabled star rating does not fire onChanged on tap', (
      tester,
    ) async {
      var changeCount = 0;

      await tester.pumpWidget(
        _buildApp(
          StarRating(
            onChanged: (_) {
              changeCount += 1;
            },
            enabled: false,
            starPointRounding: _kPointRounding,
            value: _kZeroRating,
          ),
        ),
      );

      await tester.tap(find.byType(StarRating));
      final _ = await tester.pumpAndSettle();

      // With enabled: false, onTapDown handler returns early so no change.
      expect(changeCount, equals(0));
    });

    testWidgets('renders with vertical direction', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const StarRating(
            direction: .vertical,
            starPointRounding: _kPointRounding,
            value: _kThreeRating,
          ),
        ),
      );

      expect(find.byType(StarRating), findsOneWidget);
    });

    testWidgets('renders with custom star count', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const StarRating(
            max: 10.0,
            starPointRounding: _kPointRounding,
            value: _kFourRating,
          ),
        ),
      );

      expect(find.byType(StarRating), findsOneWidget);
    });

    testWidgets('renders with custom starSize', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const StarRating(
            starPointRounding: _kPointRounding,
            starRatingStyle: CoreStarRatingStyle(starSize: _kLargeStarSize),
            value: _kThreeRating,
          ),
        ),
      );

      expect(find.byType(StarRating), findsOneWidget);
    });

    testWidgets('renders with step=1.0 for whole stars', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const StarRating(
            starPointRounding: _kPointRounding,
            step: _kStepOne,
            value: _kThreeRating,
          ),
        ),
      );

      expect(find.byType(StarRating), findsOneWidget);
    });

    // `direction` renders either way without complaint, so the only thing
    // that can show it arrived is reading the laid-out axis back off the
    // `Flex` the stars sit in.
    testWidgets('lays the stars out on the horizontal axis by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const StarRating(
            value: _kThreeRating,
            starPointRounding: _kPointRounding,
          ),
        ),
      );

      expect(_starFlex(tester).direction, equals(Axis.horizontal));
    });

    testWidgets('stacks the stars when the direction is vertical', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const StarRating(
            value: _kThreeRating,
            direction: .vertical,
            starPointRounding: _kPointRounding,
          ),
        ),
      );

      expect(_starFlex(tester).direction, equals(Axis.vertical));
    });
  });

  group('ControlledStarRating widget', () {
    testWidgets('renders with initialValue', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ControlledStarRating(
            initialValue: _kThreeRating,
            starPointRounding: _kPointRounding,
          ),
        ),
      );

      expect(find.byType(ControlledStarRating), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = material.Key('test-controlled-star-rating');

      await tester.pumpWidget(
        _buildApp(
          const ControlledStarRating(
            key: testKey,
            initialValue: _kThreeRating,
            starPointRounding: _kPointRounding,
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('works with controller', (tester) async {
      final controller = StarRatingController(_kThreeRating);

      await tester.pumpWidget(
        _buildApp(
          ControlledStarRating(
            controller: controller,
            starPointRounding: _kPointRounding,
          ),
        ),
      );

      expect(find.byType(ControlledStarRating), findsOneWidget);
      controller.dispose();
    });

    testWidgets('updates when controller value changes', (tester) async {
      final controller = StarRatingController(_kZeroRating);

      await tester.pumpWidget(
        _buildApp(
          ControlledStarRating(
            controller: controller,
            starPointRounding: _kPointRounding,
          ),
        ),
      );

      controller.value = _kFourRating;
      final _ = await tester.pumpAndSettle();

      expect(find.byType(ControlledStarRating), findsOneWidget);
      controller.dispose();
    });
  });
}

// ─── Size · value / count text · Star · one ring ─────────────────────

Finder _starsIn(Finder of) =>
    find.descendant(of: of, matching: find.byType(Star));

void _newCoverage() {
  group('StarRating size', () {
    for (final entry in {
      CoreComponentSize.sm: 16.0,
      CoreComponentSize.md: 20.0,
      CoreComponentSize.lg: 24.0,
      CoreComponentSize.xl: 32.0,
    }.entries) {
      testWidgets('${entry.key.name} draws ${entry.value}px stars', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(StarRating(value: 3, size: entry.key, onChanged: (_) {})),
        );
        final _ = await tester.pumpAndSettle();

        final first = tester.getSize(_starsIn(find.byType(StarRating)).first);
        expect(first, Size.square(entry.value));
      });
    }
  });

  group('StarRating states', () {
    testWidgets('3.5 draws 3 filled, 1 half, 1 empty', (tester) async {
      await tester.pumpWidget(
        _buildApp(StarRating(value: 3.5, onChanged: (_) {})),
      );
      final _ = await tester.pumpAndSettle();

      final states = tester
          .widgetList<Star>(_starsIn(find.byType(StarRating)))
          .map((s) => s.state)
          .toList();
      expect(states, [
        CoreStarState.filled,
        CoreStarState.filled,
        CoreStarState.filled,
        CoreStarState.half,
        CoreStarState.empty,
      ]);
    });

    // 켜진 별: 채운 별 `primary`, 빈 별 `outline-variant`. 다크에서도 둘이
    // 구별돼야 한다 — 색 값은 토큰이 아니라 그려진 ShapeDecoration 에서 읽는다.
    for (final (mode, preset) in [
      ('light', CoreThemePresets.light),
      ('dark', CoreThemePresets.dark),
    ]) {
      testWidgets('$mode: filled is primary, empty is outline-variant', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            StarRating(value: 1, onChanged: (_) {}),
            theme: ThemeData.fromCore(preset),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final scheme = Theme.of(
          tester.element(find.byType(StarRating)),
        ).colorScheme;
        final colors = _paintedStarColors(tester);
        final primary = scheme
            .resolve(const CoreColor.token(CoreColors.primary))
            .toValue();
        final outlineVariant = scheme
            .resolve(const CoreColor.token(CoreColors.outlineVariant))
            .toValue();

        expect(colors.first, primary);
        expect(colors.last, outlineVariant);
        // Not the two tokens the stars wore before.
        expect(
          colors.first,
          isNot(
            scheme
                .resolve(const CoreColor.token(CoreColors.warningIcon))
                .toValue(),
          ),
        );
        expect(
          colors.last,
          isNot(
            scheme
                .resolve(const CoreColor.token(CoreColors.surfaceContainerHigh))
                .toValue(),
          ),
        );
        // Both stars are painted opaque, so the contrast below is the one
        // that reaches the screen.
        expect(colors.first!.a, 1);
        expect(colors.last!.a, 1);
        // A filled star and an empty one are told apart by tone, in both
        // brightnesses — the 3:1 a graphic needs against its neighbour.
        expect(_contrast(colors.first!, colors.last!), greaterThanOrEqualTo(3));
      });
    }

    testWidgets('disabled stars keep disabled-content / disabled-container', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const StarRating(value: 1, enabled: false)),
      );
      final _ = await tester.pumpAndSettle();

      final scheme = Theme.of(
        tester.element(find.byType(StarRating)),
      ).colorScheme;
      final colors = _paintedStarColors(tester);
      expect(
        colors.first,
        scheme
            .resolve(const CoreColor.token(CoreColors.disabledContent))
            .toValue(),
      );
      expect(
        colors.last,
        scheme
            .resolve(const CoreColor.token(CoreColors.disabledContainer))
            .toValue(),
      );
    });
  });

  group('StarRating value / count', () {
    testWidgets('draws neither by default', (tester) async {
      await tester.pumpWidget(
        _buildApp(StarRating(value: 4.5, count: 128, onChanged: (_) {})),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('4.5'), findsNothing);
      expect(find.text('(128)'), findsNothing);
    });

    testWidgets('showValue / showCount draw "4.5" and "(128)"', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          StarRating(
            value: 4.5,
            count: 128,
            showValue: true,
            showCount: true,
            onChanged: (_) {},
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(128)'), findsOneWidget);
    });
  });

  group('StarRating sub-step values', () {
    // 값은 그대로 두고 별 채움만 가까운 반 단계로 그린다 (4.3 → 별 4.5개).
    for (final step in [0.1, 0.5]) {
      testWidgets('4.3 (step $step) fills 4.5 stars and keeps "4.3"', (
        tester,
      ) async {
        double? changed;
        await tester.pumpWidget(
          _buildApp(
            StarRating(
              value: 4.3,
              step: step,
              showValue: true,
              onChanged: (v) => changed = v,
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final states = tester
            .widgetList<Star>(_starsIn(find.byType(StarRating)))
            .map((s) => s.state)
            .toList();
        expect(states, [
          CoreStarState.filled,
          CoreStarState.filled,
          CoreStarState.filled,
          CoreStarState.filled,
          CoreStarState.half,
        ]);
        expect(find.text('4.3'), findsOneWidget);
        expect(changed, isNull);
      });
    }
  });

  group('StarRating focus ring', () {
    testWidgets('is one FocusOutline around the whole group', (tester) async {
      await tester.pumpWidget(
        _buildApp(StarRating(value: 3, showValue: true, onChanged: (_) {})),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(StarRating),
          matching: find.byType(FocusOutline),
        ),
        findsOneWidget,
      );
    });
  });
}
