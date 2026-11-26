// The Flutter twin of `coui_web`'s `formatted_input_disabled_test.dart`.
//
// Both are needed, and neither substitutes for the other: the Core fields
// are shared but each platform's resolver and widget are its own, so a
// disabled state wired on one side and forgotten on the other renders
// differently while every shared test stays green. That asymmetry is the
// exact shape of the divergence the layer-mapping rule counts six seats to
// prevent.
//
// Here the state is a third pre-baked bundle the widget selects, rather
// than the Web side's single bundle resolved with `enabled` in hand — the
// platforms reach the same picture through their own idiom.
import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/formatted_input/formatted_input_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ResolvedFormattedInput> _resolved(WidgetTester tester) async {
  ResolvedFormattedInput? resolved;
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Builder(
        builder: (context) {
          resolved = resolveFormattedInput(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  // Not `late`: the analyzer cannot see that the builder ran, and a
  // bang here would report "the resolver returned nothing" as a null
  // dereference rather than as the failure it is.
  expect(resolved, isNotNull, reason: 'the builder never ran');
  return resolved!;
}

void main() {
  group('a disabled FormattedInput carries its own tokens', () {
    testWidgets('the disabled bundle uses the disabled pair', (tester) async {
      final resolved = await _resolved(tester);

      expect(
        resolved.disabledContainerStyle.backgroundColor,
        CoreFormattedInputStyle.defaultDisabledBackgroundColor,
      );
      expect(
        resolved.disabledContainerStyle.borderColor,
        CoreFormattedInputStyle.defaultDisabledBorderColor,
      );
    });

    testWidgets('and it differs from both enabled bundles', (tester) async {
      final resolved = await _resolved(tester);

      // Asserted rather than assumed. If the disabled tokens ever resolved
      // to the enabled ones the assertions above would still pass while
      // the two states rendered identically.
      expect(
        resolved.disabledContainerStyle.backgroundColor,
        isNot(resolved.unfocusedContainerStyle.backgroundColor),
      );
      expect(
        resolved.disabledContainerStyle.borderColor,
        isNot(resolved.unfocusedContainerStyle.borderColor),
      );
      expect(
        resolved.disabledContainerStyle.borderColor,
        isNot(resolved.focusedContainerStyle.borderColor),
      );
    });

    testWidgets('geometry is shared — only the colours swap', (tester) async {
      final resolved = await _resolved(tester);

      // A disabled field is the same box. If the disabled bundle ever
      // picked up its own radius or padding the field would resize on
      // being disabled, which is a layout jump, not a state.
      expect(
        resolved.disabledContainerStyle.borderRadius,
        resolved.unfocusedContainerStyle.borderRadius,
      );
      expect(
        resolved.disabledContainerStyle.padding,
        resolved.unfocusedContainerStyle.padding,
      );
      expect(
        resolved.disabledContainerStyle.borderWidth,
        resolved.unfocusedContainerStyle.borderWidth,
      );
    });
  });
}
