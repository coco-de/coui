import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The floating panel reads one face and one line: `surfaceBright` and
/// `outlineVariant`, stated once on [CorePopupStyle]. Menu states neither,
/// so it inherits both; NavigationMenu's variant table states the same
/// pair.
void main() {
  const face = CoreColor.token(CoreColors.surfaceBright);
  const line = CoreColor.token(CoreColors.outlineVariant);

  group('CorePopupStyle colour defaults', () {
    test('the panel is the raised face with the panel line', () {
      expect(CorePopupStyle.defaultBackgroundColor, face);
      expect(CorePopupStyle.defaultBorderColor, line);
    });
  });

  group('CoreMenuStyle panel colours', () {
    test('Menu states neither colour — it inherits the Popup default', () {
      expect(CoreMenuStyle.defaultPopupStyle.backgroundColor, isNull);
      expect(CoreMenuStyle.defaultPopupStyle.borderColor, isNull);
    });

    test('the merged panel resolves to the Popup default', () {
      final merged = const CorePopupStyle().merge(
        CoreMenuStyle.defaultPopupStyle,
      );
      expect(
        merged.backgroundColor ?? CorePopupStyle.defaultBackgroundColor,
        face,
      );
      expect(merged.borderColor ?? CorePopupStyle.defaultBorderColor, line);
    });
  });

  group('CoreNavigationMenuStyle panel colours', () {
    test('the standard variant states the raised face and the panel line', () {
      final standard = CoreNavigationMenuStyle
          .defaultsByVariant[CoreNavigationMenuVariant.standard]!;
      expect(standard.backgroundColor, face);
      expect(standard.borderColor, line);
    });
  });
}
