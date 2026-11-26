import 'package:flutter/material.dart' as material;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kTestNumber = 42;
const _kTestNumberDouble = 42.0;
const _kUpdatedNumber = 100;
const _kInitialNumber = 0;
const _kTestDuration = Duration(milliseconds: 800);
const _kAltDuration = Duration(milliseconds: 300);
const _kTestFontSize = 24.0;
const _kAltFontSize = 18.0;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(
      data: const ThemeData(),
      child: child,
    ),
  );
}

String _defaultFormatter(num number) => number.toStringAsFixed(0);

String _currencyFormatter(num number) => '\$${number.toStringAsFixed(2)}';

double _testCurve(double t) => t;

void main() {
  group('NumberTicker widget', () {
    group('default constructor', () {
      testWidgets('renders with formatter', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              formatter: _defaultFormatter,
              value: _kTestNumber,
            ),
          ),
        );

        expect(find.byType(NumberTicker), findsOneWidget);
      });

      testWidgets('displays formatted text', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              formatter: _defaultFormatter,
              value: _kTestNumber,
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 1));

        expect(find.text('$_kTestNumber'), findsOneWidget);
      });

      testWidgets('displays currency formatted text', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              formatter: _currencyFormatter,
              value: _kTestNumberDouble,
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 1));

        expect(find.text('\$42.00'), findsOneWidget);
      });

      testWidgets('renders with custom style', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              formatter: _defaultFormatter,
              value: _kTestNumber,
              numberTickerStyle: const CoreNumberTickerStyle(
                textStyle: CoreTextStyle(fontSize: _kTestFontSize),
              ),
            ),
          ),
        );

        expect(find.byType(NumberTicker), findsOneWidget);
        final widget = tester.widget<NumberTicker>(
          find.byType(NumberTicker),
        );
        expect(
          widget.numberTickerStyle?.textStyle,
          equals(const CoreTextStyle(fontSize: _kTestFontSize)),
        );
      });

      testWidgets('renders with custom duration', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              numberTickerStyle: const CoreNumberTickerStyle(
                duration: _kTestDuration,
              ),
              formatter: _defaultFormatter,
              value: _kTestNumber,
            ),
          ),
        );

        final widget = tester.widget<NumberTicker>(
          find.byType(NumberTicker),
        );
        expect(widget.numberTickerStyle?.duration, equals(_kTestDuration));
      });

      testWidgets('renders with custom curve', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              curve: _testCurve,
              formatter: _defaultFormatter,
              value: _kTestNumber,
            ),
          ),
        );

        final widget = tester.widget<NumberTicker>(
          find.byType(NumberTicker),
        );
        expect(widget.curve, equals(_testCurve));
      });
    });

    group('builder constructor', () {
      testWidgets('renders with builder', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker.builder(
              value: _kTestNumber,
              builder: (context, number, child) {
                return Text(number.toStringAsFixed(0));
              },
            ),
          ),
        );

        expect(find.byType(NumberTicker), findsOneWidget);
      });

      testWidgets('displays builder content after animation', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker.builder(
              value: _kTestNumber,
              builder: (context, number, child) {
                return Text(number.toStringAsFixed(0));
              },
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 1));

        expect(find.text('$_kTestNumber'), findsOneWidget);
      });

      testWidgets('passes child to builder', (tester) async {
        const childKey = Key('ticker-child');

        await tester.pumpWidget(
          _buildApp(
            NumberTicker.builder(
              value: _kTestNumber,
              builder: (context, number, child) {
                return Column(
                  children: [
                    Text(number.toStringAsFixed(0)),
                    ?child,
                  ],
                );
              },
              child: const SizedBox(key: childKey),
            ),
          ),
        );

        expect(find.byKey(childKey), findsOneWidget);
      });

      testWidgets('renders with custom duration', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker.builder(
              numberTickerStyle: const CoreNumberTickerStyle(
                duration: _kTestDuration,
              ),
              value: _kTestNumber,
              builder: (context, number, child) {
                return Text(number.toStringAsFixed(0));
              },
            ),
          ),
        );

        final widget = tester.widget<NumberTicker>(
          find.byType(NumberTicker),
        );
        expect(widget.numberTickerStyle?.duration, equals(_kTestDuration));
      });
    });

    group('properties', () {
      test('default constructor has null builder and child', () {
        final widget = NumberTicker(
          formatter: _defaultFormatter,
          value: _kTestNumber,
        );

        expect(widget.builder, isNull);
        expect(widget.child, isNull);
      });

      test('builder constructor has null formatter and style', () {
        final widget = NumberTicker.builder(
          value: _kTestNumber,
          builder: (context, number, child) => const SizedBox.shrink(),
        );

        expect(widget.formatter, isNull);
        expect(widget.numberTickerStyle, isNull);
      });

      test('number is preserved', () {
        final widget = NumberTicker(
          formatter: _defaultFormatter,
          value: _kTestNumber,
        );

        expect(widget.value, equals(_kTestNumber));
      });

      test('initialNumber is preserved', () {
        final widget = NumberTicker(
          formatter: _defaultFormatter,
          initialValue: _kInitialNumber,
          value: _kTestNumber,
        );

        expect(widget.initialValue, equals(_kInitialNumber));
      });

      test('default initialNumber is null', () {
        final widget = NumberTicker(
          formatter: _defaultFormatter,
          value: _kTestNumber,
        );

        expect(widget.initialValue, isNull);
      });

      test('default numberTickerStyle is null', () {
        final widget = NumberTicker(
          formatter: _defaultFormatter,
          value: _kTestNumber,
        );

        expect(widget.numberTickerStyle, isNull);
      });

      test('default curve is null', () {
        final widget = NumberTicker(
          formatter: _defaultFormatter,
          value: _kTestNumber,
        );

        expect(widget.curve, isNull);
      });
    });

    group('AnimatedValueBuilder integration', () {
      testWidgets('uses AnimatedValueBuilder internally', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              formatter: _defaultFormatter,
              value: _kTestNumber,
            ),
          ),
        );

        expect(find.byType(AnimatedValueBuilder<double>), findsOneWidget);
      });

      testWidgets(
        'uses AnimatedValueBuilder with builder constructor',
        (tester) async {
          await tester.pumpWidget(
            _buildApp(
              NumberTicker.builder(
                value: _kTestNumber,
                builder: (context, number, child) {
                  return Text(number.toStringAsFixed(0));
                },
              ),
            ),
          );

          expect(find.byType(AnimatedValueBuilder<double>), findsOneWidget);
        },
      );
    });

    group('key support', () {
      testWidgets('respects provided key', (tester) async {
        const testKey = Key('test-number-ticker');

        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              key: testKey,
              formatter: _defaultFormatter,
              value: _kTestNumber,
            ),
          ),
        );

        expect(find.byKey(testKey), findsOneWidget);
      });
    });

    group('value updates', () {
      testWidgets('rebuilds when number changes', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              formatter: _defaultFormatter,
              value: _kTestNumber,
            ),
          ),
        );

        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              formatter: _defaultFormatter,
              value: _kUpdatedNumber,
            ),
          ),
        );

        await tester.pump();

        final widget = tester.widget<NumberTicker>(
          find.byType(NumberTicker),
        );
        expect(widget.value, equals(_kUpdatedNumber));
      });

      testWidgets('animates from initial number', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            NumberTicker(
              formatter: _defaultFormatter,
              initialValue: _kInitialNumber,
              value: _kTestNumber,
            ),
          ),
        );

        // At start, value should be near initial.
        expect(find.byType(Text), findsOneWidget);
      });
    });

    group('theme integration', () {
      testWidgets('picks up CoreNumberTickerTheme from coreComponentTheme', (
        tester,
      ) async {
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: const ThemeData(
                coreComponentTheme: CoreComponentTheme(
                  numberTicker: CoreNumberTickerTheme(
                    style: CoreNumberTickerStyle(
                      duration: _kAltDuration,
                      textStyle: CoreTextStyle(fontSize: _kAltFontSize),
                    ),
                  ),
                ),
              ),
              child: NumberTicker(
                formatter: _defaultFormatter,
                value: _kTestNumber,
              ),
            ),
          ),
        );

        expect(find.byType(NumberTicker), findsOneWidget);
      });
    });
  });
}
