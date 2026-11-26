// Tests for CoreSliderStyle (Epic #1302 — Story #1308 Slider).
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kTrackHeightSm = 2;
const double _kTrackHeightMd = 4;
const double _kThumbSizeSm = 16;
const double _kThumbSizeMd = 20;

const _kTrackOutline = CoreColor.token(CoreColors.outline);
const _kActivePrimary = CoreColor.token(CoreColors.primary);
const _kActiveSuccess = CoreColor.token(CoreColors.success);
const _kThumbOnPrimary = CoreColor.token(CoreColors.onPrimary);
const _kThumbBorderOutline = CoreColor.token(CoreColors.outline);
// `CoreTextStyle.color` is now `CoreColor?` (Epic #1415 Phase 2).
const _kTrackOutlineClr = CoreColor.token(CoreColors.outline);

const double _kFontBody = 12;
const int _kWeightRegular = CoreFontWeight.regular;
const int _kWeightSemiBold = CoreFontWeight.semiBold;

void main() {
  group('CoreSliderStyle.merge', () {
    test('null other returns this', () {
      const a = CoreSliderStyle(
        trackColor: _kTrackOutline,
        activeColor: _kActivePrimary,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreSliderStyle(
        trackColor: _kTrackOutline,
        activeColor: _kActivePrimary,
        trackHeight: _kTrackHeightSm,
        thumbColor: _kThumbOnPrimary,
        thumbBorderColor: _kThumbBorderOutline,
        thumbSize: _kThumbSizeMd,
      );
      const themeStyle = CoreSliderStyle(
        trackHeight: _kTrackHeightMd,
      );
      const widgetStyle = CoreSliderStyle(
        activeColor: _kActiveSuccess,
        thumbSize: _kThumbSizeSm,
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.trackColor, _kTrackOutline);
      expect(effective.activeColor, _kActiveSuccess); // widget override
      expect(effective.trackHeight, _kTrackHeightMd); // theme override
      expect(effective.thumbColor, _kThumbOnPrimary);
      expect(effective.thumbBorderColor, _kThumbBorderOutline);
      expect(effective.thumbSize, _kThumbSizeSm); // widget override
    });

    test('right-most non-null wins on each field', () {
      const a = CoreSliderStyle(
        trackHeight: _kTrackHeightSm,
        thumbSize: _kThumbSizeSm,
      );
      const b = CoreSliderStyle(trackHeight: _kTrackHeightMd);
      const c = CoreSliderStyle(thumbSize: _kThumbSizeMd);

      final result = a.merge(b).merge(c);

      expect(result.trackHeight, _kTrackHeightMd);
      expect(result.thumbSize, _kThumbSizeMd);
    });

    test('tickLabelStyle merges recursively (subset override)', () {
      const base = CoreSliderStyle(
        tickLabelStyle: CoreTextStyle(
          fontSize: _kFontBody,
          fontWeight: _kWeightRegular,
          color: _kTrackOutlineClr,
        ),
      );
      const override = CoreSliderStyle(
        tickLabelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      final merged = base.merge(override);
      expect(merged.tickLabelStyle?.fontSize, _kFontBody);
      expect(merged.tickLabelStyle?.fontWeight, _kWeightSemiBold);
      expect(merged.tickLabelStyle?.color, _kTrackOutlineClr);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreSliderStyle();
      const override = CoreSliderStyle(
        tickLabelStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      final merged = base.merge(override);
      expect(merged.tickLabelStyle?.fontSize, _kFontBody);
    });
  });

  group('CoreSliderStyle equality', () {
    test('same fields → equal', () {
      const a = CoreSliderStyle(
        activeColor: _kActivePrimary,
        thumbSize: _kThumbSizeMd,
      );
      const b = CoreSliderStyle(
        activeColor: _kActivePrimary,
        thumbSize: _kThumbSizeMd,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different activeColor → not equal', () {
      const a = CoreSliderStyle(activeColor: _kActivePrimary);
      const b = CoreSliderStyle(activeColor: _kActiveSuccess);
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreSliderStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreSliderStyle(
        activeColor: _kActivePrimary,
        trackHeight: _kTrackHeightSm,
        thumbSize: _kThumbSizeMd,
      );
      final copy = base.copyWith(thumbSize: _kThumbSizeSm);
      expect(copy.activeColor, _kActivePrimary);
      expect(copy.thumbSize, _kThumbSizeSm);
      expect(copy.trackHeight, _kTrackHeightSm);
    });

    test('preserves nested tickLabelStyle when not specified', () {
      const base = CoreSliderStyle(
        tickLabelStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      final copy = base.copyWith(activeColor: _kActiveSuccess);
      expect(copy.activeColor, _kActiveSuccess);
      expect(copy.tickLabelStyle?.fontSize, _kFontBody);
    });
  });

  group('CoreSliderTheme', () {
    test('style passes through', () {
      const style = CoreSliderStyle(activeColor: _kActivePrimary);
      const theme = CoreSliderTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreSliderTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreSliderTheme(
        style: CoreSliderStyle(activeColor: _kActivePrimary),
      );
      const b = CoreSliderTheme(
        style: CoreSliderStyle(activeColor: _kActivePrimary),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
