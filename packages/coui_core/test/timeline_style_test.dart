// Tests for CoreTimelineStyle / CoreTimelineTheme (Epic #1302 — Story
// #1321; batch 2.5 split from carousel_timeline_tree_table_style_test).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorPrimaryCore = CoreColor.token(CoreColors.primary);
const _kColorOutlineCore = CoreColor.token(CoreColors.outline);

void main() {
  group('CoreTimelineStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreTimelineStyle(
        dotColor: _kColorPrimaryCore,
        dotSize: 12,
        connectorColor: _kColorOutlineCore,
        connectorThickness: 2,
        titleTextStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      const widgetStyle = CoreTimelineStyle(connectorThickness: 4);
      final effective = designSystem.merge(widgetStyle);
      expect(effective.dotColor, _kColorPrimaryCore);
      expect(effective.dotSize, 12);
      expect(effective.connectorThickness, 4);
      expect(effective.titleTextStyle?.color, _kColorOnSurface);
    });

    test('descriptionTextStyle / dotBorder merges', () {
      const a = CoreTimelineStyle(
        dotBorderColor: _kColorOutlineCore,
        dotBorderWidth: 1,
        descriptionTextStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      const b = CoreTimelineStyle(dotBorderWidth: 2);
      final merged = a.merge(b);
      expect(merged.dotBorderColor, _kColorOutlineCore);
      expect(merged.dotBorderWidth, 2);
      expect(merged.descriptionTextStyle?.color, _kColorOnSurface);
    });

    test('rowSpacing + columnGapStyle + contentTopGapStyle merges (#1659)', () {
      const a = CoreTimelineStyle(
        rowSpacing: 20,
        columnGapStyle: CoreGapStyle(size: 12),
        contentTopGapStyle: CoreGapStyle(size: 6),
      );
      const b = CoreTimelineStyle(
        rowSpacing: 24,
        columnGapStyle: CoreGapStyle(crossAxisExtent: 4),
      );
      final merged = a.merge(b);
      expect(merged.rowSpacing, 24);
      // Nested CoreGapStyle merges recursively (size from `a` survives,
      // crossAxisExtent from `b` overrides).
      expect(merged.columnGapStyle?.size, 12);
      expect(merged.columnGapStyle?.crossAxisExtent, 4);
      expect(merged.contentTopGapStyle?.size, 6);
    });
  });

  group('CoreTimelineStyle defaults', () {
    test('the dot is 10 across, on the primary colour', () {
      expect(CoreTimelineStyle.defaultDotSize, CoreSpace.space10);
      expect(CoreTimelineStyle.defaultDotSize, 10);
      expect(CoreTimelineStyle.defaultDotColor, _kColorPrimaryCore);
    });

    test('the connector is the quiet outlineVariant, not the dot colour', () {
      expect(
        CoreTimelineStyle.defaultConnectorColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreTimelineStyle.defaultConnectorColor,
        isNot(CoreTimelineStyle.defaultDotColor),
      );
    });

    test('the title is the labelLarge role with nothing laid over it', () {
      const title = CoreTimelineStyle.defaultTitleTextStyle;

      expect(title.token, CoreTextStyles.labelLarge);
      expect(title.color, _kColorOnSurface);
      // A weight or size laid over a role would pull the title off the
      // role's optical curve (the size-ladder rule in style-contract.md).
      expect(title.fontWeight, isNull);
      expect(title.fontSize, isNull);
      expect(title.lineHeight, isNull);
    });

    test('the title has no inset and sits 2 above the description', () {
      expect(CoreTimelineStyle.defaultTitlePadding, CoreEdgeInsets.zero);
      expect(
        CoreTimelineStyle.defaultContentTopGapStyle.size,
        CoreSpace.space2,
      );
      expect(CoreTimelineStyle.defaultContentTopGapStyle.size, 2);
    });

    test('the dot seat centres the dot on the title first line', () {
      // The margin is not a ladder step and not a token: it is the centre of
      // the title's first line less half the dot. Derived here from the
      // role the title is set in, so the number cannot drift from either.
      final role = CoreTypography.coui.labelLarge;
      final lineBox = role.fontSize! * role.lineHeight!;
      final exact = (lineBox - CoreTimelineStyle.defaultDotSize) / 2;

      expect(
        CoreTimelineStyle.defaultDotTopMargin,
        exact.roundToDouble(),
        reason: 'held to a whole logical px from $exact',
      );
      expect(CoreTimelineStyle.defaultDotTopMargin, 5);
      // Within half a logical px of exact centring.
      expect(
        (CoreTimelineStyle.defaultDotTopMargin - exact).abs(),
        lessThanOrEqualTo(0.5),
      );
    });

    test('the connector keeps a 4 gap to the dot at each end', () {
      expect(CoreTimelineStyle.defaultConnectorSpacing, CoreSpace.space4);
      expect(CoreTimelineStyle.defaultConnectorSpacing, 4);
    });

    test('the dot column keeps the timestamp column and gaps unchanged', () {
      expect(CoreTimelineStyle.defaultTimeColumnWidth, CoreSpace.space120);
      expect(CoreTimelineStyle.defaultColumnGapStyle.size, CoreSpace.space16);
      expect(CoreTimelineStyle.defaultRowSpacing, CoreSpace.space16);
      expect(
        CoreTimelineStyle.defaultConnectorThickness,
        CoreStrokeWidth.stroke2,
      );
    });
  });

  group('CoreTimelineTheme', () {
    test('passes through style', () {
      const style = CoreTimelineStyle(dotColor: _kColorPrimaryCore);
      const theme = CoreTimelineTheme(style: style);
      expect(theme.style, style);
    });
  });
}
