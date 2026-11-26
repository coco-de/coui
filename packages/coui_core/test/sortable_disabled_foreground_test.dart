import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreSortableStyle.disabledForegroundColor', () {
    test('defaults to the disabled content token', () {
      expect(
        CoreSortableStyle.defaultDisabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('takes part in merge / copyWith / == / hashCode', () {
      const base = CoreSortableStyle();
      const disabled = CoreSortableStyle(
        disabledForegroundColor: CoreColor(0xFF0A0B0C),
      );

      expect(base == disabled, isFalse);
      expect(base.hashCode == disabled.hashCode, isFalse);
      expect(
        base.merge(disabled).disabledForegroundColor,
        const CoreColor(0xFF0A0B0C),
      );
      expect(
        disabled.copyWith().disabledForegroundColor,
        const CoreColor(0xFF0A0B0C),
      );
    });
  });
}
