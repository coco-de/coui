// Tests for CoreCarouselBannerStyle and the two axes Carousel grew.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorSurface = CoreColor.token(CoreColors.surface);
const _kColorPrimary = CoreColor.token(CoreColors.primary);

void main() {
  group('CoreCarouselBannerStyle', () {
    test('chain — size row → theme.style → widget', () {
      const themeStyle = CoreCarouselBannerStyle(
        backgroundColor: _kColorSurface,
      );
      const widgetStyle = CoreCarouselBannerStyle(
        backgroundColor: _kColorPrimary,
      );
      final row =
          CoreCarouselBannerStyle.defaultsBySize[CoreCarouselBannerSize.sm]!;

      final effective = row.merge(themeStyle).merge(widgetStyle);

      // The widget's field wins, and the size row's fields survive under it.
      expect(effective.backgroundColor, _kColorPrimary);
      expect(effective.thumbnailSize, CoreSize.size56);
      expect(effective.padding, const CoreEdgeInsets.all(CoreSpace.space16));
    });

    test('the strip height is the thumbnail plus its two insets', () {
      // Which is why the two sizes are 88 and 112 on the canvas: nothing
      // else in the strip is taller than the picture.
      for (final (size, height) in const [
        (CoreCarouselBannerSize.sm, 88.0),
        (CoreCarouselBannerSize.md, 112.0),
      ]) {
        final row = CoreCarouselBannerStyle.defaultsBySize[size]!;
        expect(
          row.thumbnailSize! + row.padding!.top + row.padding!.bottom,
          height,
          reason: '$size',
        );
      }
    });

    test('the two sizes move every metric together', () {
      final sm =
          CoreCarouselBannerStyle.defaultsBySize[CoreCarouselBannerSize.sm]!;
      final md =
          CoreCarouselBannerStyle.defaultsBySize[CoreCarouselBannerSize.md]!;
      // A row that shared a value with the other one would be a size axis
      // that does not fully separate — the designer draws both and every
      // number differs.
      expect(sm.padding, isNot(md.padding));
      expect(sm.thumbnailSize, isNot(md.thumbnailSize));
      expect(sm.thumbnailTextGapStyle, isNot(md.thumbnailTextGapStyle));
      expect(sm.titleStyle, isNot(md.titleStyle));
      expect(sm.descriptionStyle, isNot(md.descriptionStyle));
    });

    test('both lines take the container foreground, not a grey step', () {
      // On a tinted container a grey does not read as a second step; it
      // reads as unreadable. Weight carries the hierarchy instead.
      expect(
        CoreCarouselBannerStyle.defaultDescriptionColor,
        CoreCarouselBannerStyle.defaultTitleColor,
      );
      expect(
        CoreCarouselBannerStyle.defaultTitleColor,
        const CoreColor.token(CoreColors.onPrimaryContainer),
      );
    });

    test('the strip takes the panel corner and the thumbnail its own', () {
      // The strip is an inline face (12); the picture inset in it is smaller
      // (8) on purpose — two boxes at one corner would read as a second band.
      expect(
        CoreCarouselBannerStyle.defaultBorderRadius,
        const CoreBorderRadius.all(12),
      );
      expect(
        CoreCarouselBannerStyle.defaultThumbnailBorderRadius,
        const CoreBorderRadius.all(8),
      );
    });

    test('a glyph in the thumbnail is a mark: row icon size, variant tone', () {
      // 24 at both sizes — smaller than the square (56 / 72) it sits in,
      // which is what makes it centred rather than stretched.
      for (final (size, glyph) in const [
        (CoreCarouselBannerSize.sm, 24.0),
        (CoreCarouselBannerSize.md, 24.0),
      ]) {
        final row = CoreCarouselBannerStyle.defaultsBySize[size]!;
        expect(row.thumbnailIconStyle!.size, glyph, reason: '$size');
        expect(
          row.thumbnailIconStyle!.color,
          const CoreColor.token(CoreColors.onSurfaceVariant),
          reason: '$size',
        );
        expect(row.thumbnailIconStyle!.size, lessThan(row.thumbnailSize!));
      }
    });

    test('the thumbnail icon slot merges field by field', () {
      // A caller who states only a colour keeps the row's size.
      final row =
          CoreCarouselBannerStyle.defaultsBySize[CoreCarouselBannerSize.sm]!;
      const patch = CoreCarouselBannerStyle(
        thumbnailIconStyle: CoreIconStyle(color: _kColorPrimary),
      );

      final effective = row.merge(patch);

      expect(effective.thumbnailIconStyle!.color, _kColorPrimary);
      expect(effective.thumbnailIconStyle!.size, 24.0);
    });

    test('equality + copyWith', () {
      const a = CoreCarouselBannerStyle(backgroundColor: _kColorSurface);
      const b = CoreCarouselBannerStyle(backgroundColor: _kColorSurface);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.copyWith(thumbnailSize: 64).thumbnailSize, 64);
      expect(a.copyWith(thumbnailSize: 64).backgroundColor, _kColorSurface);
      const icon = CoreIconStyle(size: 20);
      expect(
        const CoreCarouselBannerStyle(thumbnailIconStyle: icon),
        isNot(equals(const CoreCarouselBannerStyle())),
      );
      expect(a.copyWith(thumbnailIconStyle: icon).thumbnailIconStyle, icon);
    });
  });

  group('Carousel axes', () {
    test('the variant decides where the dots go, and it rests on slide', () {
      expect(CoreCarouselVariant.defaultVariant, CoreCarouselVariant.slide);
      expect(CoreCarouselVariant.values, hasLength(2));
    });

    test('the size axis converts itself to a dot size', () {
      // The mapping lives on the enum so both platforms read one answer —
      // a copy in each resolver is a copy that can disagree.
      expect(
        CoreCarouselSize.sm.toDotIndicatorSize(),
        CoreDotIndicatorSize.sm,
      );
      expect(
        CoreCarouselSize.md.toDotIndicatorSize(),
        CoreDotIndicatorSize.md,
      );
      expect(CoreCarouselSize.defaultSize, CoreCarouselSize.md);
    });
  });

  group('CoreCarouselBannerTheme passes through style', () {
    test('CoreCarouselBannerTheme', () {
      const style = CoreCarouselBannerStyle(thumbnailSize: 64);
      const theme = CoreCarouselBannerTheme(style: style);
      expect(theme.style, style);
    });
  });
}
