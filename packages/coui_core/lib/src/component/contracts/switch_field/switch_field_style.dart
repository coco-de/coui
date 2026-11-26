/// Per-instance style for `SwitchField`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `SwitchField` should render.
///
/// `CoreSwitchFieldStyle` carries chrome / dimensional flat fields plus
/// the four typography slots (label / disabled label / description /
/// disabled description) and two nested [CoreGapStyle] slots
/// ([labelToggleGapStyle] / [labelDescriptionGapStyle]) for the inter-
/// sibling spacers. Colour belongs to the typography slot's `color`
/// field — there are no flat `labelColor` / `descriptionColor` chrome
/// props.
///
/// Every chrome value has a matching `static const default*` on this
/// class — the resolver reads the default when neither the theme nor
/// the per-instance override sets the field, so contract → default →
/// platform-style → widget stays 1:1:1:1.
///
/// ```text
/// design system default
///   → CoreSwitchFieldTheme.style                    // 프로젝트 공통
///   → parent component slot override
///   → widget.switchFieldStyle                       // 인스턴스별
/// ```
@immutable
class CoreSwitchFieldStyle implements CoreStyle<CoreSwitchFieldStyle> {
  /// Creates a [CoreSwitchFieldStyle].
  const CoreSwitchFieldStyle({
    this.size,
    this.labelToggleGapStyle,
    this.labelDescriptionGapStyle,
    this.activeColor,
    this.inactiveColor,
    this.labelTextStyle,
    this.disabledLabelTextStyle,
    this.descriptionTextStyle,
    this.disabledDescriptionTextStyle,
    this.clickableStyle,
    this.minHeight,
  });

  // ─── Design-system defaults ──────────────────────────
  // Both Flutter and Web read these constants. Colour resolution runs
  // through `scheme.resolve(...).toValue()` on both platforms.

  /// Default toggle size — `lg` (40 × 24 track, 20 thumb): a switch beside
  /// a label and a description is a settings row's control, so it takes the
  /// row-sized toggle rather than the inline `md` one. A one-line row is as
  /// tall as that track (24).
  static const CoreComponentSize defaultSize = .lg;

  /// No floor — the row is as tall as its content, which is what it has
  /// always been. The design decision on press areas keeps the 24 floor
  /// and does not widen them by default; an app that owes a touch target
  /// (e.g. 48 × scaling) states it through [minHeight].
  static const double defaultMinHeight = CoreSpace.space0;

  /// Default nested [CoreGapStyle] slot for the horizontal gap between
  /// the label section and the toggle — size matches the historical
  /// `CoreSpace.space12` scalar. Both Flutter and Web resolvers merge
  /// per-instance [labelToggleGapStyle] on top of this default and
  /// forward the resulting slot (Flutter → `Gap`, Web → inline `gap`
  /// derived from `size`).
  static const CoreGapStyle defaultLabelToggleGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default nested [CoreGapStyle] slot for the vertical gap between
  /// the label and the description inside the label section — size
  /// matches the historical `CoreSpace.space2` scalar.
  static const CoreGapStyle defaultLabelDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space2,
  );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// `Clickable` — a partial with only the diverging override: the
  /// switch field paints its own disabled state with dedicated tokens
  /// (disabled label / description / track colours), so the
  /// Clickable's generic disabled fade must stay off or the disabled
  /// chrome fades twice. Everything else stays null and resolves
  /// inside the Clickable's own resolver.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Default active (on) track colour.
  static const CoreColor defaultActiveColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default inactive (off) track colour — `surfaceContainerHighest`,
  /// the same step as `Toggle`'s own enabled-off `inactiveTrack` default.
  /// This colour is handed to the composed `Toggle` as its track override,
  /// so the two defaults have to stay equal: the off thumb (`onSurface`) is
  /// chosen to stand off the highest container step, and a lower step here
  /// would put it on a track the Toggle did not pick it for.
  static const CoreColor defaultInactiveColor = CoreColor.token(
    CoreColors.surfaceContainerHighest,
  );

  /// Default label text style — `labelLarge` slot, medium font weight,
  /// `onSurface` colour. One slot carries typography + weight + colour
  /// so the override surface stays single-fielded.
  static final CoreTextStyle defaultLabelTextStyle = const CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurface),
  ).copyWith(fontWeight: CoreFontWeight.medium);

  /// Default label text style when the switch is disabled — same
  /// typography / weight as [defaultLabelTextStyle], muted colour.
  static final CoreTextStyle defaultDisabledLabelTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelLarge,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ).copyWith(fontWeight: CoreFontWeight.medium);

  /// Default description text style — `labelSmall` slot (12 / 500 / 140%),
  /// subtle `onSurfaceSubtle` colour. A description is a note under the
  /// label, not reading copy: it takes the label family's line height and
  /// weight at the smallest label size instead of the body family's 150%,
  /// and a tone one step under the label's own muted `onSurfaceVariant`.
  static const CoreTextStyle defaultDescriptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default description text style when the switch is disabled —
  /// identical to [defaultDescriptionTextStyle] (the subtle colour is
  /// already the resting state); kept as its own slot so callers can
  /// override the disabled-only colour without touching the enabled
  /// description.
  static const CoreTextStyle defaultDisabledDescriptionTextStyle =
      CoreTextStyle.token(
        CoreTextStyles.labelSmall,
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      );

  // ─── Chrome (flat) ───────────────────────────────────

  /// Toggle size within the switch field. Forwarded to the composed
  /// `Toggle` as is, so `xs` is retiring here too
  /// (`CoreToggleContract.retiringSizes`) — the notice names `Toggle`.
  final CoreComponentSize? size;

  /// Horizontal gap between the label section and the toggle. Laid over
  /// [defaultLabelToggleGapStyle].
  ///
  /// Forwarded to the `Gap` widget rendered between the two siblings on
  /// Flutter, and drives the root `<div>`'s inline `gap` (via `size`) on
  /// Web.
  final CoreGapStyle? labelToggleGapStyle;

  /// Vertical gap between the label and the description inside the label
  /// section. Laid over [defaultLabelDescriptionGapStyle].
  ///
  /// Forwarded to the `Gap` widget rendered between the two `Text`
  /// siblings on Flutter, and drives the text column `<div>`'s inline
  /// `row-gap` (via `size`) on Web.
  final CoreGapStyle? labelDescriptionGapStyle;

  /// Style for the field's `Clickable` — press scale, durations, focus
  /// ring, disabled opacity. Laid over [defaultClickableStyle] and passed
  /// to the `Clickable` as is.
  final CoreClickableStyle? clickableStyle;

  /// Minimum height of the pressable row — label, description and
  /// toggle together — before scaling. The row's content is centred in
  /// the extra height, and the whole row stays the press area, so a
  /// theme can give every labelled switch a touch target (for example
  /// `CoreA11ySize.touchTarget`). Falls back to [defaultMinHeight].
  final double? minHeight;

  /// Active (on) track colour.
  final CoreColor? activeColor;

  /// Inactive (off) track colour.
  final CoreColor? inactiveColor;

  // ─── Slot Styles (nested) ────────────────────────────

  /// Label text style when enabled (typography + colour). Laid over
  /// [defaultLabelTextStyle].
  final CoreTextStyle? labelTextStyle;

  /// Label text style when disabled. Laid over
  /// [defaultDisabledLabelTextStyle].
  final CoreTextStyle? disabledLabelTextStyle;

  /// Description text style when enabled. Laid over
  /// [defaultDescriptionTextStyle].
  final CoreTextStyle? descriptionTextStyle;

  /// Description text style when disabled. Laid over
  /// [defaultDisabledDescriptionTextStyle].
  final CoreTextStyle? disabledDescriptionTextStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreSwitchFieldStyle merge(CoreSwitchFieldStyle? other) {
    if (other == null) return this;
    return CoreSwitchFieldStyle(
      size: other.size ?? size,
      labelToggleGapStyle: _mergeGap(
        labelToggleGapStyle,
        other.labelToggleGapStyle,
      ),
      labelDescriptionGapStyle: _mergeGap(
        labelDescriptionGapStyle,
        other.labelDescriptionGapStyle,
      ),
      activeColor: other.activeColor ?? activeColor,
      inactiveColor: other.inactiveColor ?? inactiveColor,
      labelTextStyle: _mergeText(labelTextStyle, other.labelTextStyle),
      disabledLabelTextStyle: _mergeText(
        disabledLabelTextStyle,
        other.disabledLabelTextStyle,
      ),
      descriptionTextStyle: _mergeText(
        descriptionTextStyle,
        other.descriptionTextStyle,
      ),
      disabledDescriptionTextStyle: _mergeText(
        disabledDescriptionTextStyle,
        other.disabledDescriptionTextStyle,
      ),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      minHeight: other.minHeight ?? minHeight,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreSwitchFieldStyle copyWith({
    CoreComponentSize? size,
    CoreGapStyle? labelToggleGapStyle,
    CoreGapStyle? labelDescriptionGapStyle,
    CoreColor? activeColor,
    CoreColor? inactiveColor,
    CoreTextStyle? labelTextStyle,
    CoreTextStyle? disabledLabelTextStyle,
    CoreTextStyle? descriptionTextStyle,
    CoreTextStyle? disabledDescriptionTextStyle,
    CoreClickableStyle? clickableStyle,
    double? minHeight,
  }) {
    return CoreSwitchFieldStyle(
      size: size ?? this.size,
      labelToggleGapStyle: labelToggleGapStyle ?? this.labelToggleGapStyle,
      labelDescriptionGapStyle:
          labelDescriptionGapStyle ?? this.labelDescriptionGapStyle,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      disabledLabelTextStyle:
          disabledLabelTextStyle ?? this.disabledLabelTextStyle,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
      disabledDescriptionTextStyle:
          disabledDescriptionTextStyle ?? this.disabledDescriptionTextStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      minHeight: minHeight ?? this.minHeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSwitchFieldStyle &&
          runtimeType == other.runtimeType &&
          size == other.size &&
          labelToggleGapStyle == other.labelToggleGapStyle &&
          labelDescriptionGapStyle == other.labelDescriptionGapStyle &&
          activeColor == other.activeColor &&
          inactiveColor == other.inactiveColor &&
          labelTextStyle == other.labelTextStyle &&
          disabledLabelTextStyle == other.disabledLabelTextStyle &&
          descriptionTextStyle == other.descriptionTextStyle &&
          disabledDescriptionTextStyle == other.disabledDescriptionTextStyle &&
          clickableStyle == other.clickableStyle &&
          minHeight == other.minHeight;

  @override
  int get hashCode => Object.hash(
    clickableStyle,
    size,
    labelToggleGapStyle,
    labelDescriptionGapStyle,
    activeColor,
    inactiveColor,
    labelTextStyle,
    disabledLabelTextStyle,
    descriptionTextStyle,
    disabledDescriptionTextStyle,
    minHeight,
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
}
