import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('HeroSection appear', () {
    test('copyWith keeps the opt-in flag', () {
      const section = HeroSection(
        appear: true,
        child: Text('x'),
      );

      expect(section.copyWith().appear, isTrue);
      expect(section.copyWith(appear: false).appear, isFalse);
      expect(const HeroSection(child: Text('x')).appear, isFalse);
    });

    testWidgets('the default hero does not introduce an entrance', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const HeroSection(child: Text('Static hero')),
      );

      expect(find.text('Static hero'), findsOneWidget);
      expect(find.byType(Opacity), findsNothing);
      expect(find.byType(AnimatedValueBuilder<double>), findsNothing);
    });

    testWidgets('an in-view hero fades the content in once', (tester) async {
      await pumpTestApp(
        tester,
        const HeroSection(
          appear: true,
          child: Text('In view'),
        ),
      );

      // The first frame is the hidden pose. The post-frame visibility
      // check then starts the entrance from 0 on the next pump.
      expect(_opacity(tester), 0);
      expect(find.text('In view'), findsOneWidget);

      await tester.pump();
      expect(_opacity(tester), 0);

      await tester.pump(const Duration(milliseconds: CoreDuration.moderate));
      expect(_opacity(tester), 1);
    });

    testWidgets('content stays in the semantics tree while hidden', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpTestApp(
        tester,
        const HeroSection(
          appear: true,
          child: Text('Readable'),
        ),
      );

      expect(_opacity(tester), 0);
      expect(find.bySemanticsLabel('Readable'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('reduced motion snaps the entrance', (tester) async {
      await pumpTestApp(
        tester,
        const HeroSection(
          appear: true,
          child: Text('Reduced'),
        ),
        disableAnimations: true,
      );
      await tester.pump();

      expect(_opacity(tester), 1);
    });

    testWidgets('a hero below the fold waits for the scroll viewport', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 1000),
                  HeroSection(
                    appear: true,
                    child: Text('Below'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(_opacity(tester), 0);

      final position =
          tester.state<ScrollableState>(find.byType(Scrollable)).position
            ..jumpTo(1000);
      await tester.pump();
      expect(_opacity(tester), 0);

      await tester.pump(const Duration(milliseconds: CoreDuration.moderate));
      expect(_opacity(tester), 1);

      position.jumpTo(0);
      await tester.pump();
      expect(_opacity(tester), 1);
    });

    testWidgets('a style override retimes the entrance', (tester) async {
      await pumpTestApp(
        tester,
        const HeroSection(
          appear: true,
          heroSectionStyle: CoreHeroStyle(
            appearDuration: Duration(milliseconds: CoreDuration.fast),
          ),
          child: Text('Fast'),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(milliseconds: CoreDuration.instant));
      expect(_opacity(tester), lessThan(1));

      await tester.pump(const Duration(milliseconds: CoreDuration.fast));
      expect(_opacity(tester), 1);
    });

    testWidgets('the resolver publishes the entrance recipe', (tester) async {
      late ResolvedHero resolved;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveHero(
              context,
              heroSectionStyle: const CoreHeroStyle(
                appearOffset: CoreSpace.space24,
                appearCurve: CoreEasing.exit,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      );

      expect(
        resolved.appearDuration,
        const Duration(milliseconds: CoreDuration.moderate),
      );
      expect(resolved.appearOffset, CoreSpace.space24);
      // `Cubic` compares by identity; the resolver emits `toValue()`.
      expect(
        resolved.appearCurve.toString(),
        CoreEasing.exit.toValue().toString(),
      );
    });

    testWidgets('the resolver zeroes transition motion under reduced motion', (
      tester,
    ) async {
      late ResolvedHero reduced;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            reduced = resolveHero(context);
            return const SizedBox.shrink();
          },
        ),
        disableAnimations: true,
      );

      expect(reduced.appearDuration, Duration.zero);
    });
  });
}

double _opacity(WidgetTester tester) {
  return tester.widget<Opacity>(find.byType(Opacity)).opacity;
}
