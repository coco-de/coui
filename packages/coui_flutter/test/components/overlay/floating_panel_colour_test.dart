import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The floating panels stand on one raised face with one quiet line, and
/// the modal scrim is the black `scrim` token — read back as colours
/// resolved in each of the four modes, not as declared tokens.
const _semantic = CouiSemanticColors.from(CouiColorPresets.source);

final _modes = <String, CoreColorScheme>{
  'light': _semantic.light,
  'dark': _semantic.dark,
  'high-contrast light': _semantic.highContrastLight,
  'high-contrast dark': _semantic.highContrastDark,
};

const _kBright = CoreColor.token(CoreColors.surfaceBright);
const _kSubtle = CoreColor.token(CoreColors.outlineSubtle);
const _kVariant = CoreColor.token(CoreColors.outlineVariant);
const _kScrim = CoreColor.token(CoreColors.scrim);

typedef _Seen = ({
  ThemeData theme,
  ResolvedPopup popup,
  ResolvedDialog dialog,
  ResolvedDrawer drawer,
  ResolvedCommand command,
});

Future<_Seen> _resolveIn(
  WidgetTester tester,
  CoreColorScheme scheme,
  CoreBrightness brightness,
) async {
  late _Seen seen;
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData(colorScheme: scheme.resolved(brightness)),
      home: Builder(
        builder: (context) {
          seen = (
            theme: Theme.of(context),
            popup: resolvePopup(context),
            dialog: resolveDialog(context),
            drawer: resolveDrawer(context, side: .right),
            command: resolveCommand(context),
          );

          return const material.SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();

  return seen;
}

void main() {
  for (final MapEntry(key: name, value: scheme) in _modes.entries) {
    final brightness = name.contains('dark')
        ? CoreBrightness.dark
        : CoreBrightness.light;

    testWidgets('$name — panels read the raised face and the quiet line', (
      tester,
    ) async {
      final seen = await _resolveIn(tester, scheme, brightness);
      final colours = seen.theme.colorScheme;
      final bright = colours.resolve(_kBright).toValue();
      final subtle = colours.resolve(_kSubtle).toValue();
      final variant = colours.resolve(_kVariant).toValue();

      expect(seen.popup.backgroundColor, bright);
      // The Popup line is outline-variant; Dialog keeps the quieter one.
      expect(seen.popup.borderColor, variant);
      expect(seen.dialog.panelBackgroundColor, bright);
      expect(seen.dialog.panelBorderColor, subtle);
      expect(seen.drawer.panelBackgroundColor, bright);
      // The drawer's inner-edge line is the variant step, a notch quieter.
      expect(
        seen.drawer.panelBorderColor,
        colours.resolve(_kVariant).toValue(),
      );
      expect(
        colours
            .resolve(seen.command.panelContainerStyle.backgroundColor!)
            .toValue(),
        bright,
      );
      expect(seen.command.footerBackgroundColor, bright);
    });

    testWidgets('$name — the dialog barrier is the scrim at 30 %', (
      tester,
    ) async {
      final seen = await _resolveIn(tester, scheme, brightness);
      final scrim = seen.theme.colorScheme.resolve(_kScrim).toValue();

      expect(
        seen.dialog.barrierColor,
        scrim.withValues(alpha: scrim.a * CoreOpacity.scrim),
      );
    });
  }

  testWidgets('dark — the raised face is a step off the page fill', (
    tester,
  ) async {
    final seen = await _resolveIn(tester, _semantic.dark, CoreBrightness.dark);
    final colours = seen.theme.colorScheme;

    expect(
      seen.popup.backgroundColor,
      isNot(
        colours.resolve(const CoreColor.token(CoreColors.surface)).toValue(),
      ),
    );
  });
}
