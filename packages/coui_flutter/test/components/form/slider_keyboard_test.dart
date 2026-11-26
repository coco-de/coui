import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

const _kInitialValue = 50.0;
const _kMin = 10.0;
const _kMax = 90.0;
const _kArrowStep = 1.0;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

void main() {
  group('Slider keyboard', () {
    testWidgets('ArrowRight increases the value by one step after focus', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(
        _buildApp(
          Slider(onChanged: (v) => changed = v, value: _kInitialValue),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byType(Slider));
      final __ = await tester.pumpAndSettle();
      final afterTap = changed;
      expect(afterTap, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      final ___ = await tester.pumpAndSettle();

      expect(changed, afterTap! + _kArrowStep);
    });

    testWidgets('Home jumps to min, End jumps to max', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _buildApp(
          Slider(
            onChanged: (v) => changed = v,
            value: _kInitialValue,
            min: _kMin,
            max: _kMax,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byType(Slider));
      final __ = await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      final ___ = await tester.pumpAndSettle();
      expect(changed, _kMin);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      final ____ = await tester.pumpAndSettle();
      expect(changed, _kMax);
    });

    testWidgets('disabled slider ignores keyboard input', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _buildApp(
          Slider(
            onChanged: (v) => changed = v,
            value: _kInitialValue,
            enabled: false,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      final __ = await tester.pumpAndSettle();

      expect(changed, isNull);
    });
  });
}
