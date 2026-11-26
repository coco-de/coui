/// Per-instance style for `BottomActionBar`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_align.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `BottomActionBar` renders.
///
/// Carries the surface fill, the inset around the actions, the space between
/// the note and the actions (and between the actions), the hairline above the
/// bar, and the look of the note. Platform-neutral — the Flutter and Web
/// resolvers read the same static defaults.
///
/// The bottom safe area is not a field here: it is the device's geometry,
/// supplied by the host (Flutter `SafeArea`, Web `env(safe-area-inset-bottom)`)
/// and added to [padding]'s bottom edge. The hairline is border chrome (like
/// `CoreAppBarStyle.dividerColor`), not a composed `Divider`.
///
/// ```text
/// CoreBottomActionBarStyle.default*
///   → CoreBottomActionBarTheme.style                 // project-wide
///   → widget.bottomActionBarStyle                    // per-instance
/// ```
@immutable
class CoreBottomActionBarStyle implements CoreStyle<CoreBottomActionBarStyle> {
  /// Creates a [CoreBottomActionBarStyle].
  const CoreBottomActionBarStyle({
    this.backgroundColor,
    this.padding,
    this.spacing,
    this.dividerColor,
    this.dividerWidth,
    this.descriptionTextStyle,
    this.descriptionTextAlign,
    this.summaryLabelTextStyle,
    this.summaryValueTextStyle,
  });

  /// Surface fill colour. `null` → [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// Inset around the actions (pre-scaling), before the bottom safe area is
  /// added to its bottom edge. `null` → [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Space between the note and the actions, and between the actions
  /// (logical px, pre-scaling). `null` → [defaultSpacing].
  final double? spacing;

  /// Colour of the hairline above the bar. `null` → [defaultDividerColor].
  final CoreColor? dividerColor;

  /// Thickness of the hairline above the bar (logical px, pre-scaling).
  /// `null` → [defaultDividerWidth].
  final double? dividerWidth;

  /// Text style the note slot inherits, merged on top of
  /// [defaultDescriptionTextStyle].
  final CoreTextStyle? descriptionTextStyle;

  /// Horizontal alignment of the note's text. `null` →
  /// [defaultDescriptionTextAlign].
  final CoreTextAlign? descriptionTextAlign;

  /// Text style the summary's caption inherits, merged on top of
  /// [defaultSummaryLabelTextStyle].
  final CoreTextStyle? summaryLabelTextStyle;

  /// Text style the summary's figure inherits, merged on top of
  /// [defaultSummaryValueTextStyle].
  final CoreTextStyle? summaryValueTextStyle;

  // ─── Design-system defaults (single source, Flutter ↔ Web) ──────

  /// The bar's fill — `surface`, the same as the page it sits on, so the
  /// hairline alone separates it from the content above.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// `space12` above and below, `space20` at the sides — the inset of a
  /// full-width action area. The bottom `space12` sits on top of the
  /// device's bottom safe area.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space20,
    vertical: CoreSpace.space12,
  );

  /// Between the note and the actions, and between the actions — `space8`.
  static const double defaultSpacing = CoreSpace.space8;

  /// The hairline above the bar — `outlineVariant` (falling back to
  /// `outline`), the same as the bottom hairline of `AppBar`.
  static const CoreColor defaultDividerColor = CoreColor.token(
    CoreColors.outlineVariant,
    fallbacks: [CoreColors.outline],
  );

  /// The hairline's thickness — one stroke.
  static const double defaultDividerWidth = CoreStrokeWidth.stroke1;

  /// The note — `bodySmall` in `onSurfaceVariant`, the family of the short
  /// helper lines under fields and beside controls.
  static const CoreTextStyle defaultDescriptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// The note is centred over full-width actions.
  static const CoreTextAlign defaultDescriptionTextAlign = .center;

  /// The summary's caption — `bodySmall` in `onSurfaceVariant`, the note's
  /// own look: a quiet line of context.
  static const CoreTextStyle defaultSummaryLabelTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// The summary's figure — `titleMedium` in `onSurface`: the one number the
  /// bar exists to confirm, read at a glance beside the primary action.
  static const CoreTextStyle defaultSummaryValueTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Merges [other] on top of this style — every field [other] states wins;
  /// the note's text style merges field by field.
  @override
  CoreBottomActionBarStyle merge(CoreBottomActionBarStyle? other) {
    if (other == null) return this;
    return CoreBottomActionBarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      padding: other.padding ?? padding,
      spacing: other.spacing ?? spacing,
      dividerColor: other.dividerColor ?? dividerColor,
      dividerWidth: other.dividerWidth ?? dividerWidth,
      descriptionTextStyle: descriptionTextStyle == null
          ? other.descriptionTextStyle
          : descriptionTextStyle!.merge(other.descriptionTextStyle),
      descriptionTextAlign: other.descriptionTextAlign ?? descriptionTextAlign,
      summaryLabelTextStyle: summaryLabelTextStyle == null
          ? other.summaryLabelTextStyle
          : summaryLabelTextStyle!.merge(other.summaryLabelTextStyle),
      summaryValueTextStyle: summaryValueTextStyle == null
          ? other.summaryValueTextStyle
          : summaryValueTextStyle!.merge(other.summaryValueTextStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreBottomActionBarStyle copyWith({
    CoreColor? backgroundColor,
    CoreEdgeInsets? padding,
    double? spacing,
    CoreColor? dividerColor,
    double? dividerWidth,
    CoreTextStyle? descriptionTextStyle,
    CoreTextAlign? descriptionTextAlign,
    CoreTextStyle? summaryLabelTextStyle,
    CoreTextStyle? summaryValueTextStyle,
  }) {
    return CoreBottomActionBarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      padding: padding ?? this.padding,
      spacing: spacing ?? this.spacing,
      dividerColor: dividerColor ?? this.dividerColor,
      dividerWidth: dividerWidth ?? this.dividerWidth,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
      descriptionTextAlign: descriptionTextAlign ?? this.descriptionTextAlign,
      summaryLabelTextStyle:
          summaryLabelTextStyle ?? this.summaryLabelTextStyle,
      summaryValueTextStyle:
          summaryValueTextStyle ?? this.summaryValueTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBottomActionBarStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          padding == other.padding &&
          spacing == other.spacing &&
          dividerColor == other.dividerColor &&
          dividerWidth == other.dividerWidth &&
          descriptionTextStyle == other.descriptionTextStyle &&
          descriptionTextAlign == other.descriptionTextAlign &&
          summaryLabelTextStyle == other.summaryLabelTextStyle &&
          summaryValueTextStyle == other.summaryValueTextStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    padding,
    spacing,
    dividerColor,
    dividerWidth,
    descriptionTextStyle,
    descriptionTextAlign,
    summaryLabelTextStyle,
    summaryValueTextStyle,
  );
}
