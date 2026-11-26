// A disabled `Label` paints its text, its required indicator (`*`) and its
// leading icon with ONE colour — the one its `disabledTextStyle` carries.
// Each assertion reads the colour off the widget the label actually drew, so
// a colour that is resolved but never applied to one of the three fails here
// rather than passing on the resolver's say-so.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

const _kText = 'Email';
const _kIconKey = Key('label-icon');
const _kPrimary = CoreColor.token(CoreColors.primary);
const _kDisabledContent = CoreColor.token(CoreColors.disabledContent);
const _kOnSurface = CoreColor.token(CoreColors.onSurface);
const _kError = CoreColor.token(CoreColors.error);

/// The three colours a label drew, plus the scheme they were drawn under.
typedef _Drawn = ({
  Color text,
  Color star,
  Color? icon,
  CoreColorScheme scheme,
});

Future<_Drawn> _pump(
  WidgetTester tester, {
  required bool disabled,
  CoreLabelStyle? labelStyle,
  CoreComponentTheme? componentTheme,
}) async {
  await tester.pumpWidget(
    buildGoldenTestApp(
      Label(
        text: _kText,
        icon: const SizedBox.shrink(key: _kIconKey),
        isRequired: true,
        disabled: disabled,
        labelStyle: labelStyle,
      ),
      componentTheme: componentTheme,
    ),
  );

  return (
    text: tester.widget<Text>(find.text(_kText)).style!.color!,
    star: tester.widget<Text>(find.text('*')).style!.color!,
    icon: IconTheme.of(tester.element(find.byKey(_kIconKey))).color,
    scheme: Theme.of(tester.element(find.byType(Label))).colorScheme,
  );
}

Color _value(_Drawn drawn, CoreColor color) =>
    drawn.scheme.resolve(color).toValue();

void main() {
  group('Label disabled colour (Flutter)', () {
    testWidgets('text, star and icon all take the disabled content colour', (
      tester,
    ) async {
      final drawn = await _pump(tester, disabled: true);
      final wanted = _value(drawn, _kDisabledContent);

      expect(drawn.text, wanted, reason: 'text');
      expect(drawn.star, wanted, reason: 'required indicator');
      expect(drawn.icon, wanted, reason: 'leading icon');
    });

    testWidgets('enabled keeps the live colours', (tester) async {
      final drawn = await _pump(tester, disabled: false);

      expect(drawn.text, _value(drawn, _kOnSurface), reason: 'text');
      expect(drawn.star, _value(drawn, _kError), reason: 'required indicator');
      expect(drawn.icon, _value(drawn, _kOnSurface), reason: 'leading icon');
    });

    testWidgets('disabledTextStyle recolours all three together', (
      tester,
    ) async {
      final drawn = await _pump(
        tester,
        disabled: true,
        labelStyle: const CoreLabelStyle(
          disabledTextStyle: CoreTextStyle(color: _kPrimary),
        ),
      );
      final wanted = _value(drawn, _kPrimary);

      expect(drawn.text, wanted, reason: 'text');
      expect(drawn.star, wanted, reason: 'required indicator');
      expect(drawn.icon, wanted, reason: 'leading icon');
    });

    testWidgets('a theme-level disabledTextStyle reaches all three too', (
      tester,
    ) async {
      final drawn = await _pump(
        tester,
        disabled: true,
        componentTheme: const CoreComponentTheme(
          label: CoreLabelTheme(
            style: CoreLabelStyle(
              disabledTextStyle: CoreTextStyle(color: _kPrimary),
            ),
          ),
        ),
      );
      final wanted = _value(drawn, _kPrimary);

      expect(drawn.text, wanted, reason: 'text');
      expect(drawn.star, wanted, reason: 'required indicator');
      expect(drawn.icon, wanted, reason: 'leading icon');
    });

    testWidgets('requiredColor speaks for the enabled state only', (
      tester,
    ) async {
      const labelStyle = CoreLabelStyle(requiredColor: _kPrimary);

      final enabled = await _pump(
        tester,
        disabled: false,
        labelStyle: labelStyle,
      );
      expect(enabled.star, _value(enabled, _kPrimary), reason: 'enabled');

      final disabled = await _pump(
        tester,
        disabled: true,
        labelStyle: labelStyle,
      );
      expect(
        disabled.star,
        _value(disabled, _kDisabledContent),
        reason: 'a disabled label keeps no live-looking required mark',
      );
    });
  });
}
