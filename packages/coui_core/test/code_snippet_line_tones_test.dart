import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CodeSnippet line tones', () {
    test('the three status tones each read their slot, the others none', () {
      const success = CoreColor.token(CoreColors.success);
      const warning = CoreColor.token(CoreColors.warning);
      const error = CoreColor.token(CoreColors.error);
      CoreColor? band(CoreCodeLineTone tone) =>
          CoreCodeSnippetStyle.lineColorFor(
            tone,
            success: success,
            warning: warning,
            error: error,
          );
      expect(band(CoreCodeLineTone.success), success);
      expect(band(CoreCodeLineTone.warning), warning);
      expect(band(CoreCodeLineTone.error), error);
      for (final tone in [
        CoreCodeLineTone.neutral,
        CoreCodeLineTone.muted,
        CoreCodeLineTone.link,
      ]) {
        expect(band(tone), isNull, reason: '$tone');
      }
    });

    test('the bands are the container tones CodeDiff paints its rows with', () {
      // Different meanings that draw the same band — kept as their own
      // defaults, held to the same tokens here.
      expect(
        CoreCodeSnippetStyle.defaultSuccessLineColor,
        CoreCodeDiffStyle.defaultAddedBackgroundColor,
      );
      expect(
        CoreCodeSnippetStyle.defaultErrorLineColor,
        CoreCodeDiffStyle.defaultRemovedBackgroundColor,
      );
      expect(
        CoreCodeSnippetStyle.defaultWarningLineColor,
        const CoreColor.token(CoreColors.warningContainer),
      );
    });

    test('merge, copyWith, == and hashCode carry the three slots', () {
      const base = CoreCodeSnippetStyle(
        successLineColor: CoreColor.token(CoreColors.success),
        warningLineColor: CoreColor.token(CoreColors.warning),
      );
      final merged = base.merge(
        const CoreCodeSnippetStyle(
          warningLineColor: CoreColor.token(CoreColors.tertiary),
          errorLineColor: CoreColor.token(CoreColors.error),
        ),
      );
      expect(
        merged.successLineColor,
        const CoreColor.token(CoreColors.success),
      );
      expect(
        merged.warningLineColor,
        const CoreColor.token(CoreColors.tertiary),
      );
      expect(merged.errorLineColor, const CoreColor.token(CoreColors.error));

      const plain = CoreCodeSnippetStyle();
      for (final changed in [
        plain.copyWith(
          successLineColor: const CoreColor.token(CoreColors.success),
        ),
        plain.copyWith(
          warningLineColor: const CoreColor.token(CoreColors.warning),
        ),
        plain.copyWith(errorLineColor: const CoreColor.token(CoreColors.error)),
      ]) {
        expect(changed, isNot(plain));
        expect(changed.hashCode, isNot(plain.hashCode));
      }
      expect(
        plain.copyWith(errorLineColor: const CoreColor.token(CoreColors.error)),
        plain.copyWith(errorLineColor: const CoreColor.token(CoreColors.error)),
      );
    });
  });
}
