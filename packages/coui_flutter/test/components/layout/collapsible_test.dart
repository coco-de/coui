import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

typedef _AnimationConfig = ({bool expanded, Duration? duration});

Future<ValueNotifier<_AnimationConfig>> _mountAnimation(
  WidgetTester tester,
  _AnimationConfig initial, {
  CoreComponentTheme? componentTheme,
  bool disableAnimations = false,
}) async {
  final config = ValueNotifier(initial);
  addTearDown(config.dispose);
  await pumpTestApp(
    tester,
    ValueListenableBuilder<_AnimationConfig>(
      valueListenable: config,
      builder: (context, value, child) => Collapsible(
        expanded: value.expanded,
        collapsibleStyle: value.duration == null
            ? null
            : CoreCollapsibleStyle(duration: value.duration),
        trigger: const material.Text('Duration trigger'),
        content: const material.Text('Duration content'),
      ),
    ),
    componentTheme: componentTheme,
    disableAnimations: disableAnimations,
  );
  return config;
}

Animation<double> _sizeFactor(WidgetTester tester) => tester
    .widget<SizeTransition>(
      find.descendant(
        of: find.byType(Collapsible),
        matching: find.byType(SizeTransition),
      ),
    )
    .sizeFactor;

material.Widget _buildApp(material.Widget child) => buildTestApp(child);

void main() {
  group('Collapsible', () {
    for (final initiallyExpanded in [false, true]) {
      testWidgets(
        'style-only update changes the next toggle from $initiallyExpanded',
        (tester) async {
          final config = await _mountAnimation(tester, (
            expanded: initiallyExpanded,
            duration: const Duration(milliseconds: 800),
          ));
          final element = tester.element(find.byType(Collapsible));
          final animation = _sizeFactor(tester);
          config.value = (
            expanded: initiallyExpanded,
            duration: Duration.zero,
          );
          await tester.pump();
          expect(tester.element(find.byType(Collapsible)), same(element));
          expect(_sizeFactor(tester), same(animation));
          expect(animation.value, initiallyExpanded ? 1 : 0);

          await tester.tap(find.text('Duration trigger'));
          await tester.pump();
          expect(animation.value, initiallyExpanded ? 0 : 1);
          expect(
            animation.status,
            initiallyExpanded
                ? AnimationStatus.dismissed
                : AnimationStatus.completed,
          );
        },
      );

      testWidgets(
        'simultaneous style and expansion update from $initiallyExpanded',
        (tester) async {
          final config = await _mountAnimation(tester, (
            expanded: initiallyExpanded,
            duration: const Duration(milliseconds: 800),
          ));
          final element = tester.element(find.byType(Collapsible));
          config.value = (
            expanded: !initiallyExpanded,
            duration: Duration.zero,
          );
          await tester.pump();
          expect(tester.element(find.byType(Collapsible)), same(element));
          expect(_sizeFactor(tester).value, initiallyExpanded ? 0 : 1);
        },
      );
    }

    testWidgets('duration update preserves motion and changes the next leg', (
      tester,
    ) async {
      final config = await _mountAnimation(tester, (
        expanded: false,
        duration: const Duration(milliseconds: 400),
      ));
      final animation = _sizeFactor(tester);
      final element = tester.element(find.byType(Collapsible));
      config.value = (
        expanded: true,
        duration: const Duration(milliseconds: 400),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final progress = animation.value;
      expect(progress, inExclusiveRange(0, 1));
      config.value = (
        expanded: true,
        duration: const Duration(milliseconds: 800),
      );
      await tester.pump();
      expect(tester.element(find.byType(Collapsible)), same(element));
      expect(_sizeFactor(tester), same(animation));
      expect(animation.value, progress);
      await tester.pump(const Duration(milliseconds: 100));
      expect(animation.value, greaterThan(progress));
      await tester.pump(const Duration(milliseconds: 300));
      expect(animation.status, AnimationStatus.completed);

      config.value = (
        expanded: false,
        duration: const Duration(milliseconds: 800),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(animation.status, AnimationStatus.reverse);
      expect(animation.value, inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(animation.value, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(animation.status, AnimationStatus.dismissed);
    });

    testWidgets('removing an instance duration restores the themed duration', (
      tester,
    ) async {
      final config = await _mountAnimation(
        tester,
        (expanded: false, duration: const Duration(milliseconds: 800)),
        componentTheme: const CoreComponentTheme(
          collapsible: CoreCollapsibleTheme(
            style: CoreCollapsibleStyle(duration: Duration.zero),
          ),
        ),
      );
      config.value = (expanded: true, duration: null);
      await tester.pump();
      expect(_sizeFactor(tester).status, AnimationStatus.completed);
    });

    testWidgets('updated duration keeps the current reduced-motion policy', (
      tester,
    ) async {
      final config = await _mountAnimation(
        tester,
        (expanded: false, duration: const Duration(milliseconds: 1000)),
        disableAnimations: true,
      );
      config.value = (
        expanded: true,
        duration: const Duration(milliseconds: CoreDuration.normal),
      );
      await tester.pump();
      expect(_sizeFactor(tester).status, AnimationStatus.completed);
    });

    testWidgets('default duration and same-style rebuild keep normal timing', (
      tester,
    ) async {
      final config = await _mountAnimation(tester, (
        expanded: false,
        duration: null,
      ));
      final animation = _sizeFactor(tester);
      config.value = (expanded: true, duration: null);
      await tester.pump();
      await tester.pump();
      expect(_sizeFactor(tester), same(animation));
      expect(animation.status, AnimationStatus.forward);
      await tester.pump(CoreCollapsibleStyle.defaultDuration);
      expect(animation.value, 1);
      await tester.pump(const Duration(milliseconds: 1));
      expect(animation.status, AnimationStatus.completed);
    });

    testWidgets('renders trigger and content', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Collapsible(
            expanded: true,
            trigger: material.Text('trigger text'),
            content: material.Text('content text'),
          ),
        ),
      );

      expect(find.byType(Collapsible), findsOneWidget);
      expect(find.text('trigger text'), findsOneWidget);
      expect(find.text('content text'), findsOneWidget);
    });

    testWidgets('expanded true shows the content', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Collapsible(
            expanded: true,
            trigger: material.Text('Trigger'),
            content: material.Text('Visible'),
          ),
        ),
      );

      expect(find.text('Visible'), findsOneWidget);
    });

    testWidgets('onExpandedChanged is invoked on trigger tap', (
      tester,
    ) async {
      bool? changedTo;
      final _ = await tester.pumpWidget(
        _buildApp(
          Collapsible(
            onExpandedChanged: (value) => changedTo = value,
            trigger: const material.Text('Tap me'),
            content: const material.Text('Content'),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      // Starts collapsed, so the toggle requests expansion (true).
      expect(changedTo, isTrue);
    });

    testWidgets('uncontrolled mode toggles expansion on tap', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Collapsible(
            trigger: material.Text('Toggle'),
            content: material.Text('Body'),
          ),
        ),
      );

      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();

      expect(find.byType(Collapsible), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });
  });
}
