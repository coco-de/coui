/// Per-instance style for `ValidatorHint`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/validator_hint/validator_hint_type.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Per-type chrome (the accent colour applied to the icon and text).
///
/// Variant-dependent chrome for [CoreValidatorHintStyle.defaultsByType].
@immutable
class CoreValidatorHintTypeStyle {
  /// Creates a [CoreValidatorHintTypeStyle].
  const CoreValidatorHintTypeStyle({required this.accentColor});

  /// Accent colour applied to the icon and message text.
  final CoreColor accentColor;
}

/// Immutable style describing how a `ValidatorHint` should render.
///
/// Carries the message text style, an override accent colour, the icon
/// size, and the nested [CoreGapStyle] slot for the single named-sibling
/// gap between the icon and the message label. Platform-neutral
/// (Epic #1415 option D) — colour fields use [CoreColor]; the nested
/// message text style uses the shared [CoreTextStyle] token type.
///
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth. Per-type
/// accent colours live in [defaultsByType].
@immutable
class CoreValidatorHintStyle implements CoreStyle<CoreValidatorHintStyle> {
  /// Creates a [CoreValidatorHintStyle].
  const CoreValidatorHintStyle({
    this.messageTextStyle,
    this.accentColor,
    this.iconStyle,
    this.iconLabelGapStyle,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Default message text style — token-backed `bodyXs` role (12 / 400 /
  /// 1.5). Single source of truth shared by the Flutter and Web resolvers
  /// (both merge per-instance [messageTextStyle] on top of this default
  /// and materialise / emit the role). The accent colour is applied by
  /// the resolvers separately (per-type / override), so this default
  /// carries the role only, no colour.
  ///
  /// The role a field's helper text is written in
  /// (`CoreTextFieldStyle.defaultDescriptionStyle`), not a label role: this
  /// message and the helper appear in the same place, alternating — the
  /// helper while the value is fine, this the moment it is not. Two styles
  /// in one slot make the field twitch as the user types.
  static const CoreTextStyle defaultMessageTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
  );

  /// Default icon style — `size` only (16 logical px). Per-instance
  /// override flows through [iconStyle] (merged on top of this default).
  ///
  /// 16 to match `CoreAlertStyle`'s own icon default: both are a severity
  /// glyph sitting beside a line of message text, and a reader meeting the
  /// same signal at two sizes reads them as two different signals.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default nested [CoreGapStyle] slot for the gap between the icon
  /// and the message label — size matches the historical
  /// `CoreSpace.space4` scalar. Both Flutter and Web resolvers merge
  /// per-instance [iconLabelGapStyle] on top of this default and
  /// forward the resulting slot (Flutter → `Gap`, Web → inline
  /// `margin-inline-end` derived from `size`).
  static const CoreGapStyle defaultIconLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Per-type accent colour — single source of truth shared by the
  /// Flutter and Web implementations.
  static const Map<CoreValidatorHintType, CoreValidatorHintTypeStyle>
  defaultsByType = {
    CoreValidatorHintType.error: CoreValidatorHintTypeStyle(
      accentColor: CoreColor.token(CoreColors.error),
    ),
    CoreValidatorHintType.warning: CoreValidatorHintTypeStyle(
      accentColor: CoreColor.token(CoreColors.warning),
    ),
    CoreValidatorHintType.info: CoreValidatorHintTypeStyle(
      accentColor: CoreColor.token(CoreColors.info),
    ),
    CoreValidatorHintType.success: CoreValidatorHintTypeStyle(
      accentColor: CoreColor.token(CoreColors.success),
    ),
    // The only member whose accent is not a semantic status colour, which
    // is the point of it — `onSurfaceVariant` is the kit's step below body
    // text, so the line reads as present-but-unremarkable instead of as a
    // report. Reached for by hand on six frames before it existed here.
    CoreValidatorHintType.neutral: CoreValidatorHintTypeStyle(
      accentColor: CoreColor.token(CoreColors.onSurfaceVariant),
    ),
  };

  // ─── Fields ───────────────────────────────────────────────────────

  /// Message text style override (`null` = [defaultMessageTextStyle], the
  /// `bodyXs` role a field's helper text is written in).
  final CoreTextStyle? messageTextStyle;

  /// Override accent colour applied to the icon and message text.
  ///
  /// When `null` the per-type accent from [defaultsByType] is used.
  final CoreColor? accentColor;

  /// Icon style override. `size` defers to [defaultIconStyle].
  final CoreIconStyle? iconStyle;

  /// Nested [CoreGapStyle] slot for the gap between the icon and the
  /// message label. Forwarded to the `Gap` widget rendered between
  /// the two siblings on Flutter, and drives the icon wrapper's inline
  /// `margin-inline-end` (via `size`) on Web. Merged on top of
  /// [defaultIconLabelGapStyle].
  final CoreGapStyle? iconLabelGapStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreValidatorHintStyle merge(CoreValidatorHintStyle? other) {
    if (other == null) return this;
    return CoreValidatorHintStyle(
      messageTextStyle: _mergeText(
        messageTextStyle,
        other.messageTextStyle,
      ),
      accentColor: other.accentColor ?? accentColor,
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      iconLabelGapStyle: _mergeGap(
        iconLabelGapStyle,
        other.iconLabelGapStyle,
      ),
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreValidatorHintStyle copyWith({
    CoreTextStyle? messageTextStyle,
    CoreColor? accentColor,
    CoreIconStyle? iconStyle,
    CoreGapStyle? iconLabelGapStyle,
  }) {
    return CoreValidatorHintStyle(
      messageTextStyle: messageTextStyle ?? this.messageTextStyle,
      accentColor: accentColor ?? this.accentColor,
      iconStyle: iconStyle ?? this.iconStyle,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreValidatorHintStyle &&
          runtimeType == other.runtimeType &&
          messageTextStyle == other.messageTextStyle &&
          accentColor == other.accentColor &&
          iconStyle == other.iconStyle &&
          iconLabelGapStyle == other.iconLabelGapStyle;

  @override
  int get hashCode => Object.hash(
    messageTextStyle,
    accentColor,
    iconStyle,
    iconLabelGapStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
