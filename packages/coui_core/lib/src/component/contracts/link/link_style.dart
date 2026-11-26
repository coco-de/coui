/// Per-instance style for `Link`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/link/link_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_decoration.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Link` should render.
///
/// `CoreLinkStyle` carries the link chrome / animation overrides as
/// platform-neutral domain-typed fields, plus a nested [CoreTextStyle] for
/// the link label slot.
///
/// The colours depend on the [CoreLinkVariant], so they live in
/// [defaultsByVariant]; everything else is variant-independent and lives
/// as a `static const` on this class. Flutter and Web resolvers reference
/// the same values so the two platforms cannot silently diverge.
///
/// The underline's thickness and position are not fields: they are the
/// font's own (`post` table), which both platforms draw by default. A
/// field would have to be a pixel value, and Flutter's
/// `decorationThickness` is a multiple of the font's, not pixels.
///
/// ```text
/// design system default (CoreLinkStyle.defaultsByVariant[variant],
///                        CoreLinkStyle.defaultX)
///   → CoreLinkTheme.style                          // 프로젝트 공통
///   → CoreLinkTheme.variantStyles[variant]         // 프로젝트 변형별
///   → widget.linkStyle                             // 인스턴스별
/// ```
@immutable
class CoreLinkStyle implements CoreStyle<CoreLinkStyle> {
  /// Creates a [CoreLinkStyle].
  const CoreLinkStyle({
    this.color,
    this.underlineColor,
    this.interactionTextDecoration,
    this.transitionDuration,
    this.labelStyle,
    this.clickableStyle,
    this.iconStyle,
    this.iconLabelGapStyle,
  });

  // ── Design-system defaults ──────────────────────────
  //
  // Single source of truth shared by the Flutter and Web resolvers.

  /// Variant-dependent chrome — the text colour and the underline colour
  /// of each [CoreLinkVariant]. Both name the same token: the underline
  /// follows the text tone.
  static const Map<CoreLinkVariant, CoreLinkStyle> defaultsByVariant = {
    CoreLinkVariant.standard: CoreLinkStyle(
      color: CoreColor.token(CoreColors.link),
      underlineColor: CoreColor.token(CoreColors.link),
    ),
    CoreLinkVariant.muted: CoreLinkStyle(
      color: CoreColor.token(CoreColors.onSurfaceVariant),
      underlineColor: CoreColor.token(CoreColors.onSurfaceVariant),
    ),
  };

  /// Default decoration a link shows while it is hovered, pressed or
  /// focused. A link without a permanent underline is recognised by this
  /// reaction; one with a permanent underline already shows it.
  static const CoreTextDecoration defaultInteractionTextDecoration =
      CoreTextDecoration.underline;

  /// Default colour-transition duration for hover / focus feedback
  /// (150 ms).
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default label typography — token-backed reference to the `labelXl`
  /// slot. No `color` overlay: the link foreground flows through the
  /// separate [color] field so the underline tracks the text tone
  /// independently.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelXl,
  );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// `Clickable` — a partial that pins `pressedScale: 1.0`: a link is
  /// inline text, so the press-shrink scale feedback that suits boxed
  /// controls would visibly squash the glyphs mid-sentence. Everything
  /// else stays null and resolves inside the Clickable's own resolver
  /// via `defaultClickableStyle.merge(merged.clickableStyle)`.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    pressedScale: 1,
  );

  /// Default nested [CoreIconStyle] for the `leading` / `trailing` icons —
  /// 16 and no colour: unset, an icon takes the link's text colour, so a
  /// recoloured link never leaves its icons in the old tone (the same rule
  /// the underline follows).
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreSize.size16,
  );

  /// Default space between the label and a `leading` / `trailing` icon.
  static const CoreGapStyle defaultIconLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  // ── Link chrome (flat) ───────────────────────────

  /// Link text colour override.
  final CoreColor? color;

  /// Underline stroke colour override. Unset, the underline follows the
  /// text colour — including a [color] override.
  final CoreColor? underlineColor;

  /// Decoration shown while the link is hovered, pressed or focused —
  /// unlike the Button `link` variant's hover decoration, focus counts
  /// here, and it counts the same on both platforms. A link whose
  /// `underline` flag is set is always underlined and has nothing to
  /// reveal.
  final CoreTextDecoration? interactionTextDecoration;

  /// Colour-transition duration override for hover / focus feedback.
  final Duration? transitionDuration;

  // ── Slot Styles (nested) ─────────────────────────

  /// Link label text style override (applied to the link's text
  /// child).
  final CoreTextStyle? labelStyle;

  /// Style for the link's `Clickable` — press scale, durations, focus
  /// ring, disabled opacity. Laid over [defaultClickableStyle] and passed
  /// to the `Clickable` as is; the `Clickable` fills in the remaining
  /// defaults.
  final CoreClickableStyle? clickableStyle;

  /// Style for the `leading` / `trailing` icons — size and colour. Laid
  /// over [defaultIconStyle]; a colour stated here pins the icons, unset
  /// they follow the link's text colour.
  final CoreIconStyle? iconStyle;

  /// Space between the label and a `leading` / `trailing` icon. Laid over
  /// [defaultIconLabelGapStyle] and passed to the `Gap` as is.
  final CoreGapStyle? iconLabelGapStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested labelStyle is merged
  /// recursively.
  @override
  CoreLinkStyle merge(CoreLinkStyle? other) {
    if (other == null) return this;
    return CoreLinkStyle(
      color: other.color ?? color,
      underlineColor: other.underlineColor ?? underlineColor,
      interactionTextDecoration:
          other.interactionTextDecoration ?? interactionTextDecoration,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      iconStyle: iconStyle?.merge(other.iconStyle) ?? other.iconStyle,
      iconLabelGapStyle:
          iconLabelGapStyle?.merge(other.iconLabelGapStyle) ??
          other.iconLabelGapStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreLinkStyle copyWith({
    CoreColor? color,
    CoreColor? underlineColor,
    CoreTextDecoration? interactionTextDecoration,
    Duration? transitionDuration,
    CoreTextStyle? labelStyle,
    CoreClickableStyle? clickableStyle,
    CoreIconStyle? iconStyle,
    CoreGapStyle? iconLabelGapStyle,
  }) {
    return CoreLinkStyle(
      color: color ?? this.color,
      underlineColor: underlineColor ?? this.underlineColor,
      interactionTextDecoration:
          interactionTextDecoration ?? this.interactionTextDecoration,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      labelStyle: labelStyle ?? this.labelStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreLinkStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          underlineColor == other.underlineColor &&
          interactionTextDecoration == other.interactionTextDecoration &&
          transitionDuration == other.transitionDuration &&
          labelStyle == other.labelStyle &&
          clickableStyle == other.clickableStyle &&
          iconStyle == other.iconStyle &&
          iconLabelGapStyle == other.iconLabelGapStyle;

  @override
  int get hashCode => Object.hash(
    color,
    underlineColor,
    interactionTextDecoration,
    transitionDuration,
    labelStyle,
    clickableStyle,
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
}
