/// Per-instance style for `Collapsible`.
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

/// Immutable style describing how a `Collapsible` should render.
///
/// `CoreCollapsibleStyle` carries chrome flat fields (padding /
/// animation duration) plus nested style slots for the trigger
/// text, the content body text, the trigger ↔ chevron gap, and the
/// chevron icon. Semantic state (`expanded`) lives on the widget,
/// not on this style.
///
/// ```text
/// design system default
///   → CoreCollapsibleTheme (legacy flat fields)
///   → CoreCollapsibleTheme.style                    // 프로젝트 공통
///   → parent component slot override
///   → widget.collapsibleStyle                       // 인스턴스별
/// ```
@immutable
class CoreCollapsibleStyle implements CoreStyle<CoreCollapsibleStyle> {
  /// Creates a [CoreCollapsibleStyle].
  const CoreCollapsibleStyle({
    this.contentInset,
    this.iconLabelGapStyle,
    this.duration,
    this.triggerTextStyle,
    this.contentTextStyle,
    this.iconStyle,
    this.clickableStyle,
  });

  // ── Defaults (single source of truth) ────────

  /// Default inner inset around the trigger and content area. Shared
  /// by Flutter (`EdgeInsets`) and Web (inline `rem`).
  static const CoreEdgeInsets defaultContentInset = CoreEdgeInsets.all(
    CoreSpace.space16,
  );

  /// Default horizontal gap slot between trigger text and the chevron
  /// icon. Carries the design-system gap size; the per-instance
  /// [iconLabelGapStyle] merges on top so the resolved gap rides a
  /// single [CoreGapStyle] (Epic #1603 옵션 B nested-slot pattern).
  /// Shared by Flutter and Web resolvers.
  static const CoreGapStyle defaultIconLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space16,
  );

  /// Default expand/collapse animation duration. Shared by Flutter
  /// (`AnimationController`) and Web (CSS transition).
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default chevron / disclosure icon size (logical px).
  static const double defaultArrowIconSize = CoreIconSize.size16;

  /// Default chevron / disclosure icon style slot. Carries the
  /// design-system [defaultArrowIconSize]; the per-instance [iconStyle]
  /// merges on top so the resolved chevron rides a single
  /// [CoreIconStyle] (Epic #1603 옵션 B nested-slot pattern). Shared by
  /// Flutter and Web resolvers.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: defaultArrowIconSize,
  );

  /// Default chevron-wrapper colour (`onSurface`). The chevron glyph
  /// inherits this as `currentColor` (Web `text-on-surface` class /
  /// Flutter `IconTheme`), so the disclosure icon tracks the trigger
  /// foreground. The [iconStyle] slot leaves `color` null by default to
  /// allow this inheritance; an explicit `iconStyle.color` override wins.
  static const CoreColor defaultIconColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default trigger-row text style — the single source for the trigger
  /// label's typography role (`bodyMedium`), `onSurface` colour, and
  /// `medium` (500) weight. The per-instance [triggerTextStyle] slot
  /// merges on top. Shared by Flutter (`.toValue(theme:)`) and Web
  /// (`emitTypography`). The hover underline is an interaction-state
  /// decoration applied by each platform's widget (Flutter `decoration`
  /// / Web `hover:underline` pseudo-class), not baked into this role.
  ///
  /// `static final` (not `const`) because the `medium` weight overlays the
  /// token role via `.copyWith` — the token slot is preserved (style-
  /// contract.md token-backed default pattern).
  static final CoreTextStyle defaultTriggerTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.bodyMedium,
        color: CoreColor.token(CoreColors.onSurface),
      ).copyWith(fontWeight: CoreFontWeight.medium);

  /// Default content-body text style — the single source for the
  /// expanded content area's typography role (`bodyMedium`) + `onSurface`
  /// colour. The per-instance [contentTextStyle] slot merges on top.
  /// Shared by Flutter (`.toValue(theme:)`) and Web (`emitTypography`).
  static const CoreTextStyle defaultContentTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default nested [CoreClickableStyle] slot for the composed trigger
  /// `Clickable` — a partial that pins `pressedScale: 1.0`: the trigger
  /// is the full-width header row, so the press-shrink scale feedback
  /// that suits compact controls would visibly squash the whole row.
  /// Everything else stays null and resolves inside the Clickable's own
  /// resolver via `defaultClickableStyle.merge(merged.clickableStyle)` —
  /// the focus-ring corner radius (`radius4`) is the Clickable's own
  /// default, so it is not re-declared here (partial forward, not a full
  /// clone of the child defaults). Mirrors the `Link` press-scale-off
  /// partial.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    pressedScale: 1,
  );

  // ── Chrome (flat) ────────────────────────────

  /// Inner inset around the trigger and the content area
  /// (pre-scaling).
  final CoreEdgeInsets? contentInset;

  /// Expand/collapse animation duration.
  final Duration? duration;

  // ── Slot Styles (nested) ─────────────────────

  /// Trigger row text style override.
  final CoreTextStyle? triggerTextStyle;

  /// Content body text style override. Layered over the `bodyMedium`
  /// typography role + on-surface colour the widget composes for the
  /// expanded content area (single static site, no state branch).
  final CoreTextStyle? contentTextStyle;

  /// Horizontal gap slot between the trigger text and the chevron
  /// icon. Forwarded straight to `Gap(gapStyle: …)` (Flutter) and to
  /// the gap `<div>` width (Web).
  final CoreGapStyle? iconLabelGapStyle;

  /// Chevron / disclosure icon style.
  final CoreIconStyle? iconStyle;

  /// Style of the trigger's `Clickable` — press scale, focus ring,
  /// transition durations. Merged on top of [defaultClickableStyle] and
  /// passed to the `Clickable` as is; the `Clickable` fills whatever is
  /// left unset from its own defaults.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreCollapsibleStyle merge(CoreCollapsibleStyle? other) {
    if (other == null) return this;
    return CoreCollapsibleStyle(
      contentInset: other.contentInset ?? contentInset,
      iconLabelGapStyle: _mergeGap(
        iconLabelGapStyle,
        other.iconLabelGapStyle,
      ),
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
  CoreCollapsibleStyle copyWith({
    CoreEdgeInsets? contentInset,
    CoreGapStyle? iconLabelGapStyle,
    Duration? duration,
    CoreTextStyle? triggerTextStyle,
    CoreTextStyle? contentTextStyle,
    CoreIconStyle? iconStyle,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreCollapsibleStyle(
      contentInset: contentInset ?? this.contentInset,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
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
      other is CoreCollapsibleStyle &&
          runtimeType == other.runtimeType &&
          contentInset == other.contentInset &&
          iconLabelGapStyle == other.iconLabelGapStyle &&
          duration == other.duration &&
          triggerTextStyle == other.triggerTextStyle &&
          contentTextStyle == other.contentTextStyle &&
          iconStyle == other.iconStyle &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    contentInset,
    iconLabelGapStyle,
    duration,
    triggerTextStyle,
    contentTextStyle,
    iconStyle,
    clickableStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
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

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
