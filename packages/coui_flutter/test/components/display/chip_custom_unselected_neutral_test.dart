// An unselected chip states no colour — and that includes a custom one. The
// seed paints a chip only when it is selected; an enabled unselected custom
// chip is the neutral chip, label, hairline, fill and state layer alike
// (designer verdict on the unselected-low and unselected-high rows).
//
// This reads the values where the Flutter resolver hands them to the widget,
// so a resolver that kept a custom branch for the resting chip paints the
// seed here even though the Core table says otherwise.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _seeds = <String, CoreColor>{
  'a token seed': CoreColor.token(CoreColors.tertiary),
  'a raw seed': CoreColor(0xFF3366FF),
};

Future<ResolvedChip> _resolve(
  WidgetTester tester, {
  required CoreChipColor chipColor,
  required CoreChipEmphasis emphasis,
  required CoreChipVariant variant,
  required bool selected,
  CoreColor? seedColor,
}) async {
  late ResolvedChip resolved;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Builder(
          builder: (context) {
            resolved = resolveChip(
              context,
              chipColor: chipColor,
              variant: variant,
              emphasis: emphasis,
              size: CoreChipSize.md,
              selected: selected,
              enabled: true,
              seedColor: seedColor,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return resolved;
}

void main() {
  group('an enabled unselected custom chip is the neutral chip', () {
    for (final MapEntry(key: seedName, value: seed) in _seeds.entries) {
      for (final emphasis in CoreChipEmphasis.values) {
        for (final variant in CoreChipVariant.values) {
          testWidgets(
            '$seedName · ${emphasis.name} · ${variant.name}',
            (tester) async {
              final custom = await _resolve(
                tester,
                chipColor: CoreChipColor.custom,
                emphasis: emphasis,
                variant: variant,
                selected: false,
                seedColor: seed,
              );
              final neutral = await _resolve(
                tester,
                chipColor: CoreChipColor.neutral,
                emphasis: emphasis,
                variant: variant,
                selected: false,
              );

              expect(custom.foregroundColor, neutral.foregroundColor);
              expect(
                custom.labelTextStyle.color,
                neutral.labelTextStyle.color,
                reason: 'the label',
              );
              expect(
                custom.containerStyle.backgroundColor,
                neutral.containerStyle.backgroundColor,
                reason: 'the fill',
              );
              expect(
                custom.containerStyle.borderColor,
                neutral.containerStyle.borderColor,
                reason: 'the hairline',
              );
              // The state layer washes toward the label, so a label that
              // still read the seed would pull these toward it as well.
              expect(
                custom.hoverContainerStyle.backgroundColor,
                neutral.hoverContainerStyle.backgroundColor,
                reason: 'hover wash',
              );
              expect(
                custom.focusContainerStyle.backgroundColor,
                neutral.focusContainerStyle.backgroundColor,
                reason: 'focus wash',
              );
              expect(
                custom.pressedContainerStyle.backgroundColor,
                neutral.pressedContainerStyle.backgroundColor,
                reason: 'pressed wash',
              );
            },
          );
        }
      }
    }

    testWidgets('the seed still paints a selected custom chip', (
      tester,
    ) async {
      for (final MapEntry(key: seedName, value: seed) in _seeds.entries) {
        final custom = await _resolve(
          tester,
          chipColor: CoreChipColor.custom,
          emphasis: CoreChipEmphasis.high,
          variant: CoreChipVariant.outlined,
          selected: true,
          seedColor: seed,
        );
        final neutral = await _resolve(
          tester,
          chipColor: CoreChipColor.neutral,
          emphasis: CoreChipEmphasis.high,
          variant: CoreChipVariant.outlined,
          selected: true,
        );

        expect(
          custom.containerStyle.backgroundColor,
          isNot(neutral.containerStyle.backgroundColor),
          reason: '$seedName must still fill a selected chip',
        );
      }
    });
  });
}
