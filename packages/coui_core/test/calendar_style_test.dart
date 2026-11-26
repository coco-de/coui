// Tests for CoreCalendarStyle (Epic #1302 — Calendar from Story #1314).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kSelectedPrimary = CoreColor.token(CoreColors.primary);
const _kSelectedSuccess = CoreColor.token(CoreColors.success);
const _kTodaySurface = CoreColor.token(CoreColors.surface);
const _kTodayText = CoreColor.token(CoreColors.onSurface);
const _kRangeSelection = CoreColor.token(CoreColors.primary);
const _kRangeSelectionText = CoreColor.token(CoreColors.onPrimary);
const _kArrowOutline = CoreColor.token(CoreColors.outline);
// `CoreIconStyle.color` is now `CoreColor?` (Epic #1415 Phase 2).
const _kArrowOutlineClr = CoreColor.token(CoreColors.outline);
// `CoreButtonStyle` colour fields are now `CoreColor?` (Epic #1415 Phase 6f).
const _kTodaySurfaceClr = CoreColor.token(CoreColors.surface);
const _kSelectedPrimaryClr = CoreColor.token(CoreColors.primary);

const double _kIconSm = 12;
const double _kIconMd = 16;
const double _kFontHeader = 16;
const double _kFontWeekday = 12;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;

void main() {
  group('CoreCalendarStyle.merge', () {
    test('null other returns this', () {
      const a = CoreCalendarStyle(
        selectedColor: _kSelectedPrimary,
        todayColor: _kTodaySurface,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreCalendarStyle(
        selectedColor: _kSelectedPrimary,
        todayColor: _kTodaySurface,
        todayTextStyle: CoreTextStyle(color: _kTodayText),
        rangeSelectionColor: _kRangeSelection,
        rangeSelectionTextStyle: CoreTextStyle(color: _kRangeSelectionText),
      );
      const themeStyle = CoreCalendarStyle(
        selectedColor: _kSelectedSuccess,
      );
      const widgetStyle = CoreCalendarStyle(
        rangeSelectionColor: _kArrowOutline,
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.selectedColor, _kSelectedSuccess); // theme override
      expect(effective.todayColor, _kTodaySurface);
      expect(effective.todayTextStyle?.color, _kTodayText);
      expect(effective.rangeSelectionColor, _kArrowOutline); // widget override
      expect(effective.rangeSelectionTextStyle?.color, _kRangeSelectionText);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreCalendarStyle(
        selectedColor: _kSelectedPrimary,
        todayColor: _kTodaySurface,
      );
      const b = CoreCalendarStyle(selectedColor: _kSelectedSuccess);
      const c = CoreCalendarStyle(todayColor: _kArrowOutline);

      final result = a.merge(b).merge(c);

      expect(result.selectedColor, _kSelectedSuccess);
      expect(result.todayColor, _kArrowOutline);
    });

    test('navButtonStyle / dateCellStyle merge recursively', () {
      const base = CoreCalendarStyle(
        navButtonStyle: CoreButtonStyle(
          backgroundColor: _kTodaySurfaceClr,
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
        dateCellStyle: CoreButtonStyle(
          padding: .zero,
        ),
      );
      const override = CoreCalendarStyle(
        navButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 12),
        ),
        dateCellStyle: CoreButtonStyle(
          backgroundColor: _kSelectedPrimaryClr,
        ),
      );
      final merged = base.merge(override);
      expect(
        merged.navButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 12),
      );
      expect(merged.navButtonStyle?.backgroundColor, _kTodaySurfaceClr);
      expect(merged.dateCellStyle?.padding, CoreEdgeInsets.zero);
      expect(merged.dateCellStyle?.backgroundColor, _kSelectedPrimaryClr);
    });

    test('arrowIconStyle / headerTextStyle / weekdayTextStyle merge', () {
      const base = CoreCalendarStyle(
        arrowIconStyle: CoreIconStyle(
          size: _kIconMd,
          color: _kArrowOutlineClr,
        ),
        headerTextStyle: CoreTextStyle(
          fontSize: _kFontHeader,
          fontWeight: _kWeightSemiBold,
        ),
        weekdayTextStyle: CoreTextStyle(
          fontSize: _kFontWeekday,
          fontWeight: _kWeightRegular,
        ),
      );
      const override = CoreCalendarStyle(
        arrowIconStyle: CoreIconStyle(size: _kIconSm),
        headerTextStyle: CoreTextStyle(
          fontWeight: _kWeightRegular,
        ),
      );
      final merged = base.merge(override);
      expect(merged.arrowIconStyle?.size, _kIconSm);
      expect(merged.arrowIconStyle?.color, _kArrowOutlineClr);
      expect(merged.headerTextStyle?.fontSize, _kFontHeader);
      expect(merged.headerTextStyle?.fontWeight, _kWeightRegular);
      expect(merged.weekdayTextStyle?.fontSize, _kFontWeekday);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreCalendarStyle();
      const override = CoreCalendarStyle(
        navButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
      );
      final merged = base.merge(override);
      expect(
        merged.navButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 8),
      );
    });
  });

  group('CoreCalendarStyle range band defaults', () {
    // The inner range cells sit on the band, so the text takes the
    // foreground that pairs with the band fill.
    test('range text pairs with the range band fill', () {
      expect(
        CoreCalendarStyle.defaultRangeSelectionColor,
        const CoreColor.token(CoreColors.primaryContainer),
      );
      expect(
        CoreCalendarStyle.defaultRangeSelectionTextStyle.color,
        const CoreColor.token(CoreColors.onPrimaryContainer),
      );
    });
  });

  group('CoreCalendarStyle equality', () {
    test('same fields → equal', () {
      const a = CoreCalendarStyle(
        selectedColor: _kSelectedPrimary,
        todayColor: _kTodaySurface,
      );
      const b = CoreCalendarStyle(
        selectedColor: _kSelectedPrimary,
        todayColor: _kTodaySurface,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different selectedColor → not equal', () {
      const a = CoreCalendarStyle(selectedColor: _kSelectedPrimary);
      const b = CoreCalendarStyle(selectedColor: _kSelectedSuccess);
      expect(a, isNot(equals(b)));
    });

    test('different navButtonStyle → not equal', () {
      const a = CoreCalendarStyle(
        navButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
      );
      const b = CoreCalendarStyle(
        navButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 12),
        ),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreCalendarStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreCalendarStyle(
        selectedColor: _kSelectedPrimary,
        todayColor: _kTodaySurface,
      );
      final copy = base.copyWith(selectedColor: _kSelectedSuccess);
      expect(copy.selectedColor, _kSelectedSuccess);
      expect(copy.todayColor, _kTodaySurface);
    });

    test('preserves nested styles when not specified', () {
      const base = CoreCalendarStyle(
        navButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
        arrowIconStyle: CoreIconStyle(size: _kIconMd),
      );
      final copy = base.copyWith(selectedColor: _kSelectedPrimary);
      expect(copy.selectedColor, _kSelectedPrimary);
      expect(
        copy.navButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 8),
      );
      expect(copy.arrowIconStyle?.size, _kIconMd);
    });
  });

  group('CoreCalendarTheme', () {
    test('style passes through', () {
      const style = CoreCalendarStyle(selectedColor: _kSelectedPrimary);
      const theme = CoreCalendarTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreCalendarTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreCalendarTheme(
        style: CoreCalendarStyle(selectedColor: _kSelectedPrimary),
      );
      const b = CoreCalendarTheme(
        style: CoreCalendarStyle(selectedColor: _kSelectedPrimary),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreCalendarStyle markers', () {
    const markerStyle = CoreCalendarStyle(
      markerSize: CoreSize.size6,
      markerSpacing: CoreSpace.space4,
      markerPadding: CoreEdgeInsets.only(bottom: CoreSpace.space4),
      markerBorderRadius: CoreBorderRadius.all(CoreRadius.radius2),
      markerMaxCount: 5,
      markerColor: _kSelectedSuccess,
      selectedMarkerColor: _kTodaySurface,
      rangeMarkerColor: _kRangeSelection,
    );

    test('defaults reference primitive tokens', () {
      expect(CoreCalendarStyle.defaultMarkerSize, CoreSize.size4);
      expect(CoreCalendarStyle.defaultMarkerSpacing, CoreSpace.space2);
      expect(
        CoreCalendarStyle.defaultMarkerPadding,
        const CoreEdgeInsets.only(bottom: CoreSpace.space2),
      );
      expect(
        CoreCalendarStyle.defaultMarkerBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
      expect(CoreCalendarStyle.defaultMarkerMaxCount, 3);
      expect(CoreCalendarStyle.defaultMarkerColor, _kSelectedPrimary);
      expect(
        CoreCalendarStyle.defaultSelectedMarkerColor,
        const CoreColor.token(CoreColors.onPrimary),
      );
      expect(
        CoreCalendarStyle.defaultRangeMarkerColor,
        const CoreColor.token(CoreColors.onPrimaryContainer),
      );
    });

    test('marker fields are null on an empty style', () {
      const style = CoreCalendarStyle();
      expect(style.markerSize, isNull);
      expect(style.markerSpacing, isNull);
      expect(style.markerPadding, isNull);
      expect(style.markerBorderRadius, isNull);
      expect(style.markerMaxCount, isNull);
      expect(style.markerColor, isNull);
      expect(style.selectedMarkerColor, isNull);
      expect(style.rangeMarkerColor, isNull);
    });

    test('merge — right-most non-null marker field wins', () {
      const override = CoreCalendarStyle(
        markerMaxCount: 2,
        markerColor: _kArrowOutline,
      );
      final merged = markerStyle.merge(override);

      expect(merged.markerMaxCount, 2);
      expect(merged.markerColor, _kArrowOutline);
      expect(merged.markerSize, CoreSize.size6);
      expect(merged.markerSpacing, CoreSpace.space4);
      expect(
        merged.markerPadding,
        const CoreEdgeInsets.only(bottom: CoreSpace.space4),
      );
      expect(
        merged.markerBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius2),
      );
      expect(merged.selectedMarkerColor, _kTodaySurface);
      expect(merged.rangeMarkerColor, _kRangeSelection);
    });

    test('merge keeps marker fields the other side leaves null', () {
      final merged = const CoreCalendarStyle().merge(markerStyle);
      expect(merged, markerStyle);
    });

    test('copyWith replaces only the given marker field', () {
      final copy = markerStyle.copyWith(markerSize: CoreSize.size8);
      expect(copy.markerSize, CoreSize.size8);
      expect(copy.markerMaxCount, 5);
      expect(copy.selectedMarkerColor, _kTodaySurface);
    });

    test('== and hashCode see every marker field', () {
      const same = CoreCalendarStyle(
        markerSize: CoreSize.size6,
        markerSpacing: CoreSpace.space4,
        markerPadding: CoreEdgeInsets.only(bottom: CoreSpace.space4),
        markerBorderRadius: CoreBorderRadius.all(CoreRadius.radius2),
        markerMaxCount: 5,
        markerColor: _kSelectedSuccess,
        selectedMarkerColor: _kTodaySurface,
        rangeMarkerColor: _kRangeSelection,
      );
      expect(markerStyle, same);
      expect(markerStyle.hashCode, same.hashCode);

      final variants = [
        markerStyle.copyWith(markerSize: CoreSize.size8),
        markerStyle.copyWith(markerSpacing: CoreSpace.space8),
        markerStyle.copyWith(markerPadding: const CoreEdgeInsets.all(1)),
        markerStyle.copyWith(
          markerBorderRadius: const CoreBorderRadius.all(CoreRadius.radius4),
        ),
        markerStyle.copyWith(markerMaxCount: 1),
        markerStyle.copyWith(markerColor: _kArrowOutline),
        markerStyle.copyWith(selectedMarkerColor: _kArrowOutline),
        markerStyle.copyWith(rangeMarkerColor: _kArrowOutline),
      ];
      for (final changed in variants) {
        expect(changed, isNot(markerStyle));
      }
    });
  });

  group('CoreCalendarMarker', () {
    test('defaults to a single item with no colour or label', () {
      const marker = CoreCalendarMarker();
      expect(marker.count, CoreCalendarMarker.defaultCount);
      expect(marker.color, isNull);
      expect(marker.semanticsLabel, isNull);
    });

    test('value equality over count, colour and label', () {
      const a = CoreCalendarMarker(
        count: 2,
        color: _kSelectedSuccess,
        semanticsLabel: '2 vaccinations due',
      );
      const b = CoreCalendarMarker(
        count: 2,
        color: _kSelectedSuccess,
        semanticsLabel: '2 vaccinations due',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const CoreCalendarMarker(count: 3)));
      expect(
        a,
        isNot(
          const CoreCalendarMarker(
            count: 2,
            color: _kSelectedSuccess,
            semanticsLabel: 'other',
          ),
        ),
      );
    });

    test('rejects a count below one', () {
      expect(
        () => CoreCalendarMarker(count: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('CoreCalendarStyle redesign defaults', () {
    test(
      'states the quiet today cell, the 16 arrows and the light weekdays',
      () {
        expect(
          CoreCalendarStyle.defaultArrowIconStyle.size,
          CoreIconSize.size16,
        );
        expect(
          CoreCalendarStyle.defaultRangeSelectionColor,
          const CoreColor.token(CoreColors.primaryContainer),
        );
        expect(
          CoreCalendarStyle.defaultWeekdayTextStyle.token,
          CoreTextStyles.bodyXs,
        );
        expect(
          CoreCalendarStyle.defaultWeekdayLabelTextStyle.token,
          CoreTextStyles.bodyXs,
        );
        expect(
          CoreCalendarStyle.defaultWeekdayLabelTextStyle.color,
          const CoreColor.token(CoreColors.onSurfaceSubtle),
        );
        expect(
          CoreCalendarStyle.defaultTodayBorderColor,
          const CoreColor.token(CoreColors.outline),
        );
        expect(
          CoreCalendarStyle.defaultTodayBorderWidth,
          CoreStrokeWidth.stroke1,
        );
      },
    );

    test('today border fields merge, copy and compare', () {
      const a = CoreCalendarStyle(todayBorderWidth: 2);
      final merged = a.merge(
        const CoreCalendarStyle(todayBorderColor: _kArrowOutline),
      );
      expect(merged.todayBorderWidth, 2);
      expect(merged.todayBorderColor, _kArrowOutline);
      expect(merged.copyWith(todayBorderWidth: 3).todayBorderWidth, 3);
      expect(a, isNot(const CoreCalendarStyle(todayBorderWidth: 3)));
      expect(a.hashCode, const CoreCalendarStyle(todayBorderWidth: 2).hashCode);
    });
  });

  group('CoreCalendarStyle #5881 typography and range decisions', () {
    test('today is bodySmall SemiBold in primary', () {
      final today = CoreCalendarStyle.defaultTodayTextStyle;
      expect(today.token, CoreTextStyles.bodySmall);
      expect(today.fontWeight, CoreFontWeight.semiBold);
      expect(today.color, const CoreColor.token(CoreColors.primary));
      // Weight overlay only — the size ladder rule forbids a fontSize one.
      expect(today.fontSize, isNull);
    });

    test('a selected date / range endpoint is bodySmall Medium onPrimary', () {
      final selected = CoreCalendarStyle.defaultSelectedTextStyle;
      expect(selected.token, CoreTextStyles.bodySmall);
      expect(selected.fontWeight, CoreFontWeight.medium);
      expect(selected.color, const CoreColor.token(CoreColors.onPrimary));
      expect(selected.fontSize, isNull);
    });

    test('the month title takes the button-label role', () {
      expect(
        CoreCalendarStyle.defaultHeaderTextStyle.token,
        CoreTextStyles.labelMedium,
      );
      expect(CoreCalendarStyle.defaultHeaderTextStyle.fontWeight, isNull);
    });

    test('range dots pair with the primaryContainer band', () {
      expect(
        CoreCalendarStyle.defaultRangeMarkerColor,
        const CoreColor.token(CoreColors.onPrimaryContainer),
      );
      expect(
        CoreCalendarStyle.defaultRangeMarkerColor,
        CoreCalendarStyle.defaultRangeSelectionTextStyle.color,
      );
    });
  });
}
