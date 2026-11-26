/// Per-instance style for `Disclosure` and `DisclosureGroup`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Disclosure` should render.
///
/// The defaults deliberately name the same tokens `CoreCollapsibleStyle`
/// names. The two components differ in who owns the open state, not in
/// how they look — a page that mixes them should not show a seam.
@immutable
class CoreDisclosureStyle implements CoreStyle<CoreDisclosureStyle> {
  /// Creates a [CoreDisclosureStyle].
  const CoreDisclosureStyle({
    this.contentInset,
    this.iconLabelGapStyle,
    this.itemSpacing,
    this.duration,
    this.triggerTextStyle,
    this.contentTextStyle,
    this.iconStyle,
    this.clickableStyle,
  });

  // ── Defaults (single source of truth) ────────

  /// Default inner inset around the header row and the body.
  static const CoreEdgeInsets defaultContentInset = CoreEdgeInsets.all(
    CoreSpace.space16,
  );

  /// Default horizontal gap slot between the header text and the
  /// chevron. Forwarded raw to `Gap(gapStyle: …)`, which runs its own
  /// resolve/scaling step.
  static const CoreGapStyle defaultIconLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space16,
  );

  /// Default vertical distance between siblings in a `DisclosureGroup`.
  ///
  /// A `double`, not a [CoreGapStyle]: this is the even distribution
  /// across N children that `Column.spacing` / CSS `gap` take, not a
  /// one-off spacer between two named siblings.
  static const double defaultItemSpacing = CoreSpace.space8;

  /// Default chevron rotation duration.
  ///
  /// Only the chevron animates. The body's reveal is the platform's —
  /// the browser shows and hides `<details>` content itself, and giving
  /// that a duration here would claim a transition the component does
  /// not drive.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default chevron size (logical px).
  static const double defaultArrowIconSize = CoreIconSize.size16;

  /// Default chevron icon style slot, carrying [defaultArrowIconSize].
  /// The per-instance [iconStyle] merges on top and the result is
  /// raw-forwarded to `Icon(iconStyle: …)`.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: defaultArrowIconSize,
  );

  /// Default chevron-wrapper colour. The glyph inherits it as
  /// `currentColor`, so the chevron tracks the header foreground;
  /// [iconStyle] leaves `color` null to allow that, and an explicit
  /// override still wins.
  static const CoreColor defaultIconColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default header text style — `bodyMedium` / `onSurface` / `medium`.
  ///
  /// `static final` (not `const`) because the weight overlays the token
  /// role through `.copyWith`, which preserves the token slot.
  static final CoreTextStyle defaultTriggerTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.bodyMedium,
        color: CoreColor.token(CoreColors.onSurface),
      ).copyWith(fontWeight: CoreFontWeight.medium);

  /// Default body text style — `bodyMedium` / `onSurface`.
  static const CoreTextStyle defaultContentTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default nested [CoreClickableStyle] partial for the header.
  ///
  /// Pins `pressedScale: 1` for the same reason `Collapsible` does: the
  /// header spans the full width, and the press-shrink that suits a
  /// compact control visibly squashes a whole row. Everything else stays
  /// null so the child's own resolver fills it (partial forward, not a
  /// clone of the child's defaults).
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    pressedScale: 1,
  );

  // ── Chrome (flat) ────────────────────────────

  /// Inner inset around the header row and the body (pre-scaling).
  final CoreEdgeInsets? contentInset;

  /// Vertical distance between siblings in a `DisclosureGroup`. Read by
  /// the group; a lone `Disclosure` has no sibling to space against.
  final double? itemSpacing;

  /// Chevron rotation duration.
  final Duration? duration;

  // ── Slot Styles (nested) ─────────────────────

  /// Header text style override.
  final CoreTextStyle? triggerTextStyle;

  /// Body text style override.
  final CoreTextStyle? contentTextStyle;

  /// Horizontal gap slot between the header text and the chevron.
  final CoreGapStyle? iconLabelGapStyle;

  /// Chevron icon style.
  final CoreIconStyle? iconStyle;

  /// Style for the header's focus ring and press feedback. Flutter passes
  /// it to the header's `Clickable`; Web uses its `focusOutlineStyle` for
  /// the `<summary>`'s ring, so the same override changes both platforms.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are merged
  /// recursively.
  @override
  CoreDisclosureStyle merge(CoreDisclosureStyle? other) {
    if (other == null) return this;
    return CoreDisclosureStyle(
      contentInset: other.contentInset ?? contentInset,
      iconLabelGapStyle: _mergeGap(iconLabelGapStyle, other.iconLabelGapStyle),
      itemSpacing: other.itemSpacing ?? itemSpacing,
      duration: other.duration ?? duration,
      triggerTextStyle: _mergeText(triggerTextStyle, other.triggerTextStyle),
      contentTextStyle: _mergeText(contentTextStyle, other.contentTextStyle),
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreDisclosureStyle copyWith({
    CoreEdgeInsets? contentInset,
    CoreGapStyle? iconLabelGapStyle,
    double? itemSpacing,
    Duration? duration,
    CoreTextStyle? triggerTextStyle,
    CoreTextStyle? contentTextStyle,
    CoreIconStyle? iconStyle,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreDisclosureStyle(
      contentInset: contentInset ?? this.contentInset,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      duration: duration ?? this.duration,
      triggerTextStyle: triggerTextStyle ?? this.triggerTextStyle,
      contentTextStyle: contentTextStyle ?? this.contentTextStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDisclosureStyle &&
          runtimeType == other.runtimeType &&
          contentInset == other.contentInset &&
          iconLabelGapStyle == other.iconLabelGapStyle &&
          itemSpacing == other.itemSpacing &&
          duration == other.duration &&
          triggerTextStyle == other.triggerTextStyle &&
          contentTextStyle == other.contentTextStyle &&
          iconStyle == other.iconStyle &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    contentInset,
    iconLabelGapStyle,
    itemSpacing,
    duration,
    triggerTextStyle,
    contentTextStyle,
    iconStyle,
    clickableStyle,
  );

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreIconStyle? _mergeIcon(CoreIconStyle? base, CoreIconStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
