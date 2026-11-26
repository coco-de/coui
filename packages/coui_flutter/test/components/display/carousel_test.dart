import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kTestItemCount = 5;
const _kTestFixedSize = 200.0;
const _kTestFraction = 0.8;
const _kTestGap = 16.0;
const _kTestColor = Color(0xFFFF0000);
const _kConstraintSize = 400.0;
const _kCenterAlignment = 0.5;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(
      data: const ThemeData(),
      child: SizedBox(
        width: _kConstraintSize,
        height: _kConstraintSize,
        child: child,
      ),
    ),
  );
}

void main() {
  group('CarouselSizeConstraint', () {
    group('CarouselFixedConstraint', () {
      test('creates with size', () {
        const constraint = CarouselFixedConstraint(_kTestFixedSize);

        expect(constraint.size, equals(_kTestFixedSize));
      });
    });

    group('CarouselFractionalConstraint', () {
      test('creates with fraction', () {
        const constraint = CarouselFractionalConstraint(_kTestFraction);

        expect(constraint.fraction, equals(_kTestFraction));
      });
    });

    group('factory constructors', () {
      test('fixed creates CarouselFixedConstraint', () {
        const constraint = CarouselSizeConstraint.fixed(_kTestFixedSize);

        expect(constraint, isA<CarouselFixedConstraint>());
      });

      test('fractional creates CarouselFractionalConstraint', () {
        const constraint = CarouselSizeConstraint.fractional(_kTestFraction);

        expect(constraint, isA<CarouselFractionalConstraint>());
      });
    });
  });

  group('CarouselTransition', () {
    group('SlidingCarouselTransition', () {
      test('creates with default gap of 0', () {
        const transition = SlidingCarouselTransition();

        expect(transition.gap, equals(0));
      });

      test('creates with custom gap', () {
        const transition = SlidingCarouselTransition(gap: _kTestGap);

        expect(transition.gap, equals(_kTestGap));
      });
    });

    group('FadingCarouselTransition', () {
      test('creates successfully', () {
        const transition = FadingCarouselTransition();

        expect(transition, isA<CarouselTransition>());
      });
    });

    group('factory constructors', () {
      test('sliding creates SlidingCarouselTransition', () {
        const transition = CarouselTransition.sliding(gap: _kTestGap);

        expect(transition, isA<SlidingCarouselTransition>());
      });

      test('fading creates FadingCarouselTransition', () {
        const transition = CarouselTransition.fading();

        expect(transition, isA<FadingCarouselTransition>());
      });
    });
  });

  group('CarouselController', () {
    test('finite indices and fractional wrap retain their position', () {
      final controller = CarouselController();
      for (final entry in <double, double>{
        0: 0,
        1: 1,
        2: 2,
        0.5: 0.5,
        3: 0,
        4: 1,
        -1: 2,
      }.entries) {
        controller.jumpTo(entry.key);
        expect(
          controller.getCurrentIndex(3),
          entry.value,
          reason: 'three slides at position ${entry.key}',
        );
      }
    });

    test('initial value is 0', () {
      final controller = CarouselController();

      expect(controller.value, equals(0));
    });

    test('jumpTo changes value immediately', () {
      final controller = CarouselController()..jumpTo(2);

      expect(controller.value, equals(2));
    });

    test('getCurrentIndex returns value without itemCount', () {
      final controller = CarouselController()..jumpTo(2);

      expect(controller.getCurrentIndex(null), equals(2));
    });

    test('shouldAnimate is false initially', () {
      final controller = CarouselController();

      expect(controller.shouldAnimate, isFalse);
    });

    test('addListener and removeListener work', () {
      final controller = CarouselController();
      void listener() {}

      controller
        ..addListener(listener)
        ..jumpTo(1)
        ..removeListener(listener);
    });
  });

  testWidgets('dragging a finite carousel reports its settled slide', (
    tester,
  ) async {
    final reported = <int>[];
    await tester.pumpWidget(
      _buildApp(
        Carousel(
          items: const [Text('first'), Text('second'), Text('third')],
          transition: const CarouselTransition.sliding(),
          wrap: false,
          disableDraggingVelocity: true,
          showNavigation: false,
          showIndicators: false,
          onIndexChanged: reported.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final carousel = find.byType(Carousel);
    await tester.drag(
      carousel,
      Offset(-tester.getSize(carousel).width * .8, 0),
    );
    await tester.pumpAndSettle();
    expect(reported.last, 1);
  });

  group('CarouselAlignment', () {
    test('start has alignment 0', () {
      expect(CarouselAlignment.start.alignment, equals(0));
    });

    test('center has alignment 0.5', () {
      expect(CarouselAlignment.center.alignment, equals(_kCenterAlignment));
    });

    test('end has alignment 1', () {
      expect(CarouselAlignment.end.alignment, equals(1));
    });
  });

  // `autoPlay` was declared on the contract and never read here: the gate
  // was the presence of `duration`, so `autoPlay: true` alone did nothing
  // and `autoPlay: false` could not turn auto-play off. The Web twin gated
  // the other way round. These pin all four combinations, because the fix is
  // a *derived default* and a derivation is exactly what silently drifts.
  group('Carousel auto-play gate', () {
    /// Whether auto-play advanced the index within a generous window.
    ///
    /// The index is read from `onIndexChanged` rather than from the rendered
    /// slides: a sliding carousel keeps its neighbours mounted, so the first
    /// item's text is still findable after an advance.
    Future<bool> advances(
      WidgetTester tester, {
      bool? autoPlay,
      Duration? duration,
    }) async {
      var advanced = false;
      await tester.pumpWidget(
        _buildApp(
          Carousel(
            autoPlay: autoPlay,
            duration: duration,
            onIndexChanged: (_) => advanced = true,
            itemBuilder: (context, index) =>
                SizedBox(width: _kTestFixedSize, child: Text('Item $index')),
            itemCount: _kTestItemCount,
            transition: const CarouselTransition.sliding(),
          ),
        ),
      );

      // The ticker advances per frame, so step rather than jump: one long
      // pump delivers a single tick and the interval elapses inside it.
      for (var i = 0; i < 80 && !advanced; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Leave no live ticker behind for the next test.
      await tester.pumpWidget(_buildApp(const SizedBox.shrink()));
      return advanced;
    }

    testWidgets('the flag alone turns it on', (tester) async {
      // Was impossible before: no `duration` meant no auto-play whatever the
      // flag said. The interval now falls back to the design-system default,
      // which is what the Web twin already did.
      expect(await advances(tester, autoPlay: true), isTrue);
    });

    testWidgets('the flag alone turns it off', (tester) async {
      // Also impossible before — `duration` outranked the flag.
      expect(
        await advances(
          tester,
          autoPlay: false,
          duration: const Duration(seconds: 1),
        ),
        isFalse,
      );
    });

    testWidgets('an interval with no flag still auto-plays', (tester) async {
      // The prior Flutter behaviour, preserved by the derived default so
      // existing callers keep working.
      expect(
        await advances(tester, duration: const Duration(seconds: 1)),
        isTrue,
      );
    });

    testWidgets('neither one stays still', (tester) async {
      expect(await advances(tester), isFalse);
    });
  });

  group('Carousel widget', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Carousel(
            itemBuilder: (context, index) {
              return ColoredBox(
                color: _kTestColor,
                child: Center(child: Text('Item $index')),
              );
            },
            itemCount: _kTestItemCount,
            transition: const CarouselTransition.sliding(),
          ),
        ),
      );

      expect(find.byType(Carousel), findsOneWidget);
    });

    testWidgets('renders with fading transition', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Carousel(
            itemBuilder: (context, index) {
              return ColoredBox(
                color: _kTestColor,
                child: Center(child: Text('Item $index')),
              );
            },
            itemCount: _kTestItemCount,
            transition: const CarouselTransition.fading(),
          ),
        ),
      );

      expect(find.byType(Carousel), findsOneWidget);
    });

    testWidgets('renders with custom alignment', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Carousel(
            alignment: .start,
            itemBuilder: (context, index) {
              return ColoredBox(
                color: _kTestColor,
                child: Center(child: Text('Item $index')),
              );
            },
            itemCount: _kTestItemCount,
            transition: const CarouselTransition.sliding(),
          ),
        ),
      );

      expect(find.byType(Carousel), findsOneWidget);
    });

    testWidgets('renders with vertical direction', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Carousel(
            direction: .vertical,
            itemBuilder: (context, index) {
              return ColoredBox(
                color: _kTestColor,
                child: Center(child: Text('Item $index')),
              );
            },
            itemCount: _kTestItemCount,
            transition: const CarouselTransition.sliding(),
          ),
        ),
      );

      expect(find.byType(Carousel), findsOneWidget);
    });

    testWidgets('renders with fixed size constraint', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Carousel(
            itemBuilder: (context, index) {
              return ColoredBox(
                color: _kTestColor,
                child: Center(child: Text('Item $index')),
              );
            },
            itemCount: _kTestItemCount,
            sizeConstraint: const CarouselSizeConstraint.fixed(_kTestFixedSize),
            transition: const CarouselTransition.sliding(gap: _kTestGap),
          ),
        ),
      );

      expect(find.byType(Carousel), findsOneWidget);
    });

    testWidgets('renders with wrap false', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Carousel(
            itemBuilder: (context, index) {
              return ColoredBox(
                color: _kTestColor,
                child: Center(child: Text('Item $index')),
              );
            },
            itemCount: _kTestItemCount,
            transition: const CarouselTransition.sliding(),
            wrap: false,
          ),
        ),
      );

      expect(find.byType(Carousel), findsOneWidget);
    });

    testWidgets('renders with draggable false', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Carousel(
            draggable: false,
            itemBuilder: (context, index) {
              return ColoredBox(
                color: _kTestColor,
                child: Center(child: Text('Item $index')),
              );
            },
            itemCount: _kTestItemCount,
            transition: const CarouselTransition.sliding(),
          ),
        ),
      );

      expect(find.byType(Carousel), findsOneWidget);
    });

    testWidgets('respects provided key', (tester) async {
      const testKey = Key('test-carousel');

      await tester.pumpWidget(
        _buildApp(
          Carousel(
            key: testKey,
            itemBuilder: (context, index) {
              return ColoredBox(
                color: _kTestColor,
                child: Center(child: Text('Item $index')),
              );
            },
            itemCount: _kTestItemCount,
            transition: const CarouselTransition.sliding(),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('renders with external controller', (tester) async {
      final controller = CarouselController();

      await tester.pumpWidget(
        _buildApp(
          Carousel(
            controller: controller,
            itemBuilder: (context, index) {
              return ColoredBox(
                color: _kTestColor,
                child: Center(child: Text('Item $index')),
              );
            },
            itemCount: _kTestItemCount,
            transition: const CarouselTransition.sliding(),
          ),
        ),
      );

      expect(find.byType(Carousel), findsOneWidget);
    });

    testWidgets('default properties are correct', (tester) async {
      const widget = Carousel(
        itemBuilder: _testItemBuilder,
        itemCount: _kTestItemCount,
        transition: CarouselTransition.sliding(),
      );

      expect(widget.alignment, equals(CarouselAlignment.center));
      expect(widget.direction, equals(CoreAxis.horizontal));
      expect(widget.wrap, isTrue);
      expect(widget.pauseOnHover, isTrue);
      expect(widget.draggable, isTrue);
      expect(widget.reverse, isFalse);
      expect(widget.autoplayReverse, isFalse);
      expect(widget.waitOnStart, isFalse);
      expect(widget.disableOverheadScrolling, isTrue);
      expect(widget.disableDraggingVelocity, isFalse);
    });
  });
}

Widget _testItemBuilder(Object context, int index) {
  return ColoredBox(
    color: _kTestColor,
    child: Center(child: Text('Item $index')),
  );
}
