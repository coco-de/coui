// Tests for CoreSwitchFieldStyle defaults.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kLgTrackWidth = 40;
const double _kLgTrackHeight = 24;
const double _kLgThumbSize = 20;
const double _kLgThumbInset = 2;
const double _kLgThumbTravel = 16;

const double _kDescriptionFontSize = 12;
const double _kDescriptionLineHeight = 1.4;

void main() {
  group('CoreSwitchFieldStyle toggle size', () {
    test('the default toggle is lg', () {
      expect(CoreSwitchFieldStyle.defaultSize, CoreComponentSize.lg);
    });

    // The default size is only a name; the picture is the Toggle row it
    // names. Reading the row back through the same table the resolvers use
    // keeps the two from drifting apart.
    test('lg draws a 40 × 24 track, a 20 thumb, a 2 band, a 16 travel', () {
      final row = CoreToggleStyle.sizeDefaults(
        CoreSwitchFieldStyle.defaultSize,
      );
      expect(row.trackWidth, _kLgTrackWidth);
      expect(row.trackHeight, _kLgTrackHeight);
      expect(row.thumbSize, _kLgThumbSize);
      expect(row.padding, const CoreEdgeInsets.all(_kLgThumbInset));
      expect(row.thumbOffset, _kLgThumbTravel);
    });

    test('a per-instance size still wins over the default', () {
      const base = CoreSwitchFieldStyle();
      final merged = base.merge(
        const CoreSwitchFieldStyle(size: CoreComponentSize.sm),
      );
      expect(merged.size, CoreComponentSize.sm);
      expect(base.size, isNull, reason: 'the default lives on the class');
    });
  });

  group('CoreSwitchFieldStyle track colour', () {
    test('the off track is the same token as the enabled-off Toggle track', () {
      final toggle =
          CoreToggleStyle.defaultsByVariant[CoreToggleVariant.defaultVariant]!;
      expect(CoreSwitchFieldStyle.defaultInactiveColor, toggle.inactiveTrack);
    });

    // SwitchField hands its track colour to the composed Toggle, so changing
    // the Toggle's own default alone would leave the composed one behind. Both
    // are read back as the token itself — the highest container step.
    test('the off track is the highest container step', () {
      const highest = CoreColor.token(CoreColors.surfaceContainerHighest);
      expect(CoreSwitchFieldStyle.defaultInactiveColor, highest);
      expect(
        CoreToggleStyle
            .defaultsByVariant[CoreToggleVariant.defaultVariant]!
            .inactiveTrack,
        highest,
      );
      // The negative control: the step below, `surfaceContainer`, must not be
      // what matched.
      expect(
        CoreSwitchFieldStyle.defaultInactiveColor,
        isNot(const CoreColor.token(CoreColors.surfaceContainer)),
      );
    });
  });

  group('CoreSwitchFieldStyle description', () {
    test('reads as labelSmall — 12 / 500 / 140%', () {
      const style = CoreSwitchFieldStyle.defaultDescriptionTextStyle;
      expect(style.token, CoreTextStyles.labelSmall);
      final role = style.token!.read(CoreTypography.coui);
      expect(role.fontSize, _kDescriptionFontSize);
      expect(role.fontWeight, CoreFontWeight.medium);
      expect(role.lineHeight, _kDescriptionLineHeight);
    });

    test('the description is subtle — one step under the label', () {
      const subtle = CoreColor.token(CoreColors.onSurfaceSubtle);
      expect(CoreSwitchFieldStyle.defaultDescriptionTextStyle.color, subtle);
      expect(
        CoreSwitchFieldStyle.defaultDisabledDescriptionTextStyle.color,
        subtle,
      );
      // The negative control: `onSurfaceVariant` is the tone the disabled
      // label wears (pinned below), so the description must not be it.
      expect(
        CoreSwitchFieldStyle.defaultDescriptionTextStyle.color,
        isNot(const CoreColor.token(CoreColors.onSurfaceVariant)),
      );
      expect(
        CoreSwitchFieldStyle.defaultDisabledLabelTextStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    test('the disabled description is the resting description', () {
      expect(
        CoreSwitchFieldStyle.defaultDisabledDescriptionTextStyle,
        CoreSwitchFieldStyle.defaultDescriptionTextStyle,
      );
    });
  });
}
