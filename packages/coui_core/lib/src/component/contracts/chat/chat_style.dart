/// Per-instance style for `Chat` / `ChatBubble`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/chat/chat_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Chat` row should render.
///
/// `CoreChatStyle` carries chrome around the chat row itself — gap
/// between avatar and body, native-API spacing between rows in a
/// group, and the nested header / footer text styles.
///
/// ```text
/// CoreChatStyle.defaultX
///   → CoreChatTheme.style                            // project-wide
///   → parent component slot override
///   → widget.chatStyle                               // per-instance
/// ```
@immutable
class CoreChatStyle implements CoreStyle<CoreChatStyle> {
  /// Creates a [CoreChatStyle].
  const CoreChatStyle({
    this.avatarSpacing,
    this.groupSpacing,
    this.headerTextStyle,
    this.footerTextStyle,
  });

  /// Padding spacing between the avatar and the message column
  /// (logical px). Fed into the avatar wrapper's
  /// `EdgeInsetsDirectional` (Flutter) / `margin-inline-*` (Web) — not
  /// a `Gap`, so the value stays a raw double.
  final double? avatarSpacing;

  /// Inter-bubble spacing between consecutive bubbles inside a
  /// `ChatGroup` (logical px, pre-scaling). Forwarded directly to
  /// `Column.spacing` (Flutter) / flex `gap` CSS (Web) — both are
  /// native paint-API arguments that consume raw doubles, so this
  /// slot stays scalar (`double`).
  final double? groupSpacing;

  /// Optional text style for the header slot (sender name).
  final CoreTextStyle? headerTextStyle;

  /// Optional text style for the footer slot (timestamp / status).
  final CoreTextStyle? footerTextStyle;

  // ─── Design-system defaults (Phase 6f single source) ────────────

  /// Default padding spacing between avatar and message column
  /// (logical px). Shared by Flutter and Web resolvers.
  static const double defaultAvatarSpacing = CoreSpace.space8;

  /// Default inter-bubble spacing inside a group (logical px,
  /// pre-scaling). Shared by Flutter and Web resolvers. Forwarded to
  /// `Column.spacing` (Flutter) / flex `gap` CSS (Web).
  static const double defaultGroupSpacing = CoreSpace.space4;

  /// Default header (sender name) text — the `labelSmall` role (12 / 500)
  /// in `onSurfaceVariant`. Token-backed so both platforms materialise the
  /// same typography instead of inheriting divergent ambient defaults
  /// (Flutter framework 14px vs browser 16px). The sender names a person
  /// rather than being the message, so it sits a size under the bubble
  /// text and a step under `onSurface`.
  static const CoreTextStyle defaultHeaderTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default footer (timestamp / status) text — the `bodyXs` role
  /// (12 / 400) in `onSurfaceSubtle`. Token-backed for the same reason as
  /// [defaultHeaderTextStyle]; the timestamp is the quietest line of the
  /// row, so it is regular weight where the sender is medium.
  static const CoreTextStyle defaultFooterTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested text styles merge
  /// recursively.
  @override
  CoreChatStyle merge(CoreChatStyle? other) {
    if (other == null) return this;
    return CoreChatStyle(
      avatarSpacing: other.avatarSpacing ?? avatarSpacing,
      groupSpacing: other.groupSpacing ?? groupSpacing,
      headerTextStyle: _mergeText(headerTextStyle, other.headerTextStyle),
      footerTextStyle: _mergeText(footerTextStyle, other.footerTextStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreChatStyle copyWith({
    double? avatarSpacing,
    double? groupSpacing,
    CoreTextStyle? headerTextStyle,
    CoreTextStyle? footerTextStyle,
  }) {
    return CoreChatStyle(
      avatarSpacing: avatarSpacing ?? this.avatarSpacing,
      groupSpacing: groupSpacing ?? this.groupSpacing,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      footerTextStyle: footerTextStyle ?? this.footerTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreChatStyle &&
          runtimeType == other.runtimeType &&
          avatarSpacing == other.avatarSpacing &&
          groupSpacing == other.groupSpacing &&
          headerTextStyle == other.headerTextStyle &&
          footerTextStyle == other.footerTextStyle;

  @override
  int get hashCode => Object.hash(
    avatarSpacing,
    groupSpacing,
    headerTextStyle,
    footerTextStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Immutable style describing how a single `ChatBubble` should render.
///
/// Variant-independent chrome (padding / border radius / tail dims /
/// max width) lives as `static const`. Variant-dependent chrome
/// (background / foreground colours) is in [defaultsByVariant].
@immutable
class CoreChatBubbleStyle implements CoreStyle<CoreChatBubbleStyle> {
  /// Creates a [CoreChatBubbleStyle].
  const CoreChatBubbleStyle({
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.maxWidthFactor,
    this.tailWidth,
    this.tailHeight,
    this.tailTipRadius,
    this.tailEdge,
    this.tailCornerRadius,
    this.textStyle,
  });

  // ── Chrome (flat) ────────────────────────────

  /// Inner padding around the bubble content (logical px, pre-scaling).
  final CoreEdgeInsets? padding;

  /// Border radius of the bubble.
  final CoreBorderRadius? borderRadius;

  /// Background fill colour. `null` → variant default.
  final CoreColor? backgroundColor;

  /// Foreground (text/content) colour. `null` → variant default.
  final CoreColor? foregroundColor;

  /// Maximum bubble width as a fraction of the available horizontal
  /// space. `null` → [defaultMaxWidthFactor].
  final double? maxWidthFactor;

  /// Tail (speech-bubble pointer) width in logical pixels.
  final double? tailWidth;

  /// Tail (speech-bubble pointer) height in logical pixels.
  final double? tailHeight;

  /// Rounding radius of the tail's pointer tip (logical px). The
  /// triangle's edges stop this far short of the tip and arc around it
  /// instead of meeting in a sharp point.
  final double? tailTipRadius;

  /// The edge the tail sits on — where a drawn pointer leaves from, and whose
  /// corner on the alignment side [tailCornerRadius] shapes. `null` →
  /// [defaultTailEdge].
  final CoreChatBubbleTailEdge? tailEdge;

  /// Radius of the tail corner — the [tailEdge] corner on the alignment side —
  /// on a bubble with no pointer (logical px).
  ///
  /// A bubble without a pointer can mark its sender with this one corner
  /// shaped apart from the other three. With a pointer drawn the corner is
  /// square whatever this states: the pointer's bubble-side edge continues
  /// the bubble's side, and a rounded corner opens a notch between them.
  ///
  /// Deliberately has no `default*`: `null` means the corner is simply the
  /// matching corner of [borderRadius], so restating the bubble's radius moves
  /// all four corners together. A constant here would hold one corner still
  /// while a theme rounded the other three.
  final double? tailCornerRadius;

  // ── Slot Styles (nested) ─────────────────────

  /// Optional text style merged into the bubble content.
  final CoreTextStyle? textStyle;

  // ─── Design-system defaults (Phase 6f single source) ────────────

  /// Default inner padding (`10px` vertical / `14px` horizontal). Both are
  /// off the 4px rungs, so density moves them with the space ladder
  /// (compact `8` / `12`, spacious `12` / `16`).
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space14,
    vertical: CoreSpace.space10,
  );

  /// Default border radius (`14px` on every corner). A ladder step rather
  /// than a role: no `CoreRadiusRole` is 14, and it is the same step the
  /// `xl` control row sits on.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius14,
  );

  /// Default max bubble width fraction — three quarters of the available
  /// horizontal space when the bubble renders outside a `ChatGroup`. It is
  /// not a magic number but a design decision both platforms share, and it
  /// is not on a token scale: no primitive scale expresses "a fraction of
  /// the parent's width", and borrowing one that happens to hold `0.75`
  /// (an opacity step) would name it something it is not.
  ///
  /// Stated here as the literal rather than via a library-private
  /// `_kChatBubbleMaxWidthFactor` alias — the alias put the only copy of
  /// the value outside the class, where a reader walking the class's own
  /// static members (the Figma exporter) could not follow it, so the
  /// fraction never reached the canvas.
  static const double defaultMaxWidthFactor = 0.75;

  /// Default tail (speech-bubble pointer) width in logical pixels — an
  /// 8×8 box hanging below the bubble's bottom edge on the alignment
  /// side (shadcn_flutter tail convention: a right triangle whose outer
  /// edge continues the bubble's side, pointing down-outward with a
  /// rounded tip).
  static const double defaultTailWidth = CoreSpace.space8;

  /// Default tail (speech-bubble pointer) height in logical pixels.
  static const double defaultTailHeight = CoreSpace.space8;

  /// Default tail pointer-tip rounding — the blunt tip keeps the
  /// triangle from ending in a needle-sharp point (shadcn_flutter's
  /// tail-tip rounding convention).
  static const double defaultTailTipRadius = CoreRadius.radius4;

  /// Default tail edge — the bottom, where the pointer has always left from
  /// (shadcn_flutter / daisyUI tail convention).
  static const CoreChatBubbleTailEdge defaultTailEdge =
      CoreChatBubbleTailEdge.bottom;

  /// Default bubble content text role — `bodyLarge` (15 / 400 / 1.5), one
  /// step above the `bodyMedium` the header and footer around the bubble
  /// read, so the message is the largest text in the group. Token-backed
  /// so both platforms materialise the same typography instead of
  /// inheriting divergent ambient defaults (Flutter framework 14px vs
  /// browser 16px).
  static const CoreTextStyle defaultTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyLarge,
  );

  /// Per-variant chrome defaults — single source of truth shared by
  /// Flutter and Web.
  static const Map<CoreChatBubbleVariant, CoreChatBubbleVariantStyle>
  defaultsByVariant = {
    CoreChatBubbleVariant.neutral: CoreChatBubbleVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
      foregroundColor: CoreColor.token(CoreColors.onSurface),
    ),
    CoreChatBubbleVariant.primary: CoreChatBubbleVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
      foregroundColor: CoreColor.token(CoreColors.onPrimary),
    ),
    CoreChatBubbleVariant.secondary: CoreChatBubbleVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
      foregroundColor: CoreColor.token(CoreColors.onSecondary),
    ),
    CoreChatBubbleVariant.accent: CoreChatBubbleVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
      foregroundColor: CoreColor.token(CoreColors.onTertiary),
    ),
    CoreChatBubbleVariant.info: CoreChatBubbleVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
      foregroundColor: CoreColor.token(CoreColors.onInfo),
    ),
    CoreChatBubbleVariant.success: CoreChatBubbleVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
      foregroundColor: CoreColor.token(CoreColors.onSuccess),
    ),
    CoreChatBubbleVariant.warning: CoreChatBubbleVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
      foregroundColor: CoreColor.token(CoreColors.onWarning),
    ),
    CoreChatBubbleVariant.error: CoreChatBubbleVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
      foregroundColor: CoreColor.token(CoreColors.onError),
    ),
    CoreChatBubbleVariant.plain: CoreChatBubbleVariantStyle(
      backgroundColor: CoreColor.transparent,
      foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
      padding: CoreEdgeInsets.zero,
      maxWidthFactor: 1,
    ),
  };

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested text style merges
  /// recursively.
  @override
  CoreChatBubbleStyle merge(CoreChatBubbleStyle? other) {
    if (other == null) return this;
    return CoreChatBubbleStyle(
      padding: other.padding ?? padding,
      borderRadius: other.borderRadius ?? borderRadius,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      maxWidthFactor: other.maxWidthFactor ?? maxWidthFactor,
      tailWidth: other.tailWidth ?? tailWidth,
      tailHeight: other.tailHeight ?? tailHeight,
      tailTipRadius: other.tailTipRadius ?? tailTipRadius,
      tailEdge: other.tailEdge ?? tailEdge,
      tailCornerRadius: other.tailCornerRadius ?? tailCornerRadius,
      textStyle: _mergeText(textStyle, other.textStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreChatBubbleStyle copyWith({
    CoreEdgeInsets? padding,
    CoreBorderRadius? borderRadius,
    CoreColor? backgroundColor,
    CoreColor? foregroundColor,
    double? maxWidthFactor,
    double? tailWidth,
    double? tailHeight,
    double? tailTipRadius,
    CoreChatBubbleTailEdge? tailEdge,
    double? tailCornerRadius,
    CoreTextStyle? textStyle,
  }) {
    return CoreChatBubbleStyle(
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      maxWidthFactor: maxWidthFactor ?? this.maxWidthFactor,
      tailWidth: tailWidth ?? this.tailWidth,
      tailHeight: tailHeight ?? this.tailHeight,
      tailTipRadius: tailTipRadius ?? this.tailTipRadius,
      tailEdge: tailEdge ?? this.tailEdge,
      tailCornerRadius: tailCornerRadius ?? this.tailCornerRadius,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreChatBubbleStyle &&
          runtimeType == other.runtimeType &&
          padding == other.padding &&
          borderRadius == other.borderRadius &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          maxWidthFactor == other.maxWidthFactor &&
          tailWidth == other.tailWidth &&
          tailHeight == other.tailHeight &&
          tailTipRadius == other.tailTipRadius &&
          tailEdge == other.tailEdge &&
          tailCornerRadius == other.tailCornerRadius &&
          textStyle == other.textStyle;

  @override
  int get hashCode => Object.hashAll([
    padding,
    borderRadius,
    backgroundColor,
    foregroundColor,
    maxWidthFactor,
    tailWidth,
    tailHeight,
    tailTipRadius,
    tailEdge,
    tailCornerRadius,
    textStyle,
  ]);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Variant-dependent chrome (background / foreground colour, and optionally
/// inner padding and max width fraction) for `ChatBubble`.
///
/// Held in [CoreChatBubbleStyle.defaultsByVariant] as the single source
/// of truth shared by Flutter and Web.
@immutable
class CoreChatBubbleVariantStyle {
  /// Creates a [CoreChatBubbleVariantStyle].
  const CoreChatBubbleVariantStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    this.padding,
    this.maxWidthFactor,
  });

  /// Variant background fill colour.
  final CoreColor backgroundColor;

  /// Variant foreground (text/content) colour.
  final CoreColor foregroundColor;

  /// Variant inner padding. `null` = the shared
  /// [CoreChatBubbleStyle.defaultPadding].
  final CoreEdgeInsets? padding;

  /// Variant max bubble width fraction. `null` = the shared
  /// [CoreChatBubbleStyle.defaultMaxWidthFactor].
  final double? maxWidthFactor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreChatBubbleVariantStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          padding == other.padding &&
          maxWidthFactor == other.maxWidthFactor;

  @override
  int get hashCode =>
      Object.hash(backgroundColor, foregroundColor, padding, maxWidthFactor);
}
