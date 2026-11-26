/// Per-instance style for `PageHeader`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/size/layout.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `PageHeader` renders.
///
/// The header draws no box of its own — no fill, border or padding; it is a
/// row of text and actions placed on whatever surface the page gives it.
/// The style carries the three text roles, the spacing between the text
/// lines, between the text and the actions and between two actions, and the
/// narrowest the text may get before the actions move under it.
///
/// ```text
/// CorePageHeaderStyle.default*
///   → CorePageHeaderTheme.style                     // project-wide
///   → widget.pageHeaderStyle                        // per-instance
/// ```
@immutable
class CorePageHeaderStyle implements CoreStyle<CorePageHeaderStyle> {
  /// Creates a [CorePageHeaderStyle].
  const CorePageHeaderStyle({
    this.eyebrowTextStyle,
    this.titleTextStyle,
    this.descriptionTextStyle,
    this.textSpacing,
    this.textActionsSpacing,
    this.actionSpacing,
    this.minTextWidth,
  });

  // ── Text ─────────────────────────────────────

  /// Text style the eyebrow slot's content inherits, laid over
  /// [defaultEyebrowTextStyle].
  final CoreTextStyle? eyebrowTextStyle;

  /// Text style the title slot's content inherits, laid over
  /// [defaultTitleTextStyle].
  final CoreTextStyle? titleTextStyle;

  /// Text style the description slot's content inherits, laid over
  /// [defaultDescriptionTextStyle].
  final CoreTextStyle? descriptionTextStyle;

  // ── Spacing (logical px, pre-scaling) ───────

  /// Space between the lines of the text block — eyebrow, title and
  /// description, whichever are present. `null` → [defaultTextSpacing].
  final double? textSpacing;

  /// Space between the title and the actions — across the title's line
  /// while they share it, and down once the actions have moved under the
  /// title. `null` → [defaultTextActionsSpacing].
  final double? textActionsSpacing;

  /// Space between two actions, and between two lines of them when they
  /// wrap. `null` → [defaultActionSpacing].
  final double? actionSpacing;

  /// The narrowest the title may get beside the actions on its line. Below
  /// it the actions move under the title. `null` → [defaultMinTextWidth].
  final double? minTextWidth;

  // ─── Design-system defaults (single source, Flutter ↔ Web) ──────

  /// The eyebrow — `labelXl` (15, medium) in `onSurfaceVariant`: the quiet
  /// line that says where the page sits.
  static const CoreTextStyle defaultEyebrowTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelXl,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// The title — `headlineMedium` (28, bold) in `onSurface`.
  static const CoreTextStyle defaultTitleTextStyle = CoreTextStyle.token(
    CoreTextStyles.headlineMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// The description — `bodyMedium` in `onSurfaceVariant`, the sentence under
  /// a title the way `EmptyState` sets one.
  static const CoreTextStyle defaultDescriptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Between the lines of the text block — `space4`.
  static const double defaultTextSpacing = CoreSpace.space4;

  /// Between the title and the actions — `space16`, the title line's gap in
  /// the design (#6582). Twice the gap between two actions, so the actions
  /// read as one group set apart from the title.
  static const double defaultTextActionsSpacing = CoreSpace.space16;

  /// Between two actions — `space8`.
  static const double defaultActionSpacing = CoreSpace.space8;

  /// The narrowest the title gets beside the actions — `CoreLayout.layout160`.
  /// The actions share the title's line; when the line leaves the title less
  /// than this, they move under the title.
  static const double defaultMinTextWidth = CoreLayout.layout160;

  /// Merges [other] on top of this style — every field [other] states wins;
  /// the text styles merge field by field.
  @override
  CorePageHeaderStyle merge(CorePageHeaderStyle? other) {
    if (other == null) return this;
    return CorePageHeaderStyle(
      eyebrowTextStyle: _mergeText(eyebrowTextStyle, other.eyebrowTextStyle),
      titleTextStyle: _mergeText(titleTextStyle, other.titleTextStyle),
      descriptionTextStyle: _mergeText(
        descriptionTextStyle,
        other.descriptionTextStyle,
      ),
      textSpacing: other.textSpacing ?? textSpacing,
      textActionsSpacing: other.textActionsSpacing ?? textActionsSpacing,
      actionSpacing: other.actionSpacing ?? actionSpacing,
      minTextWidth: other.minTextWidth ?? minTextWidth,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CorePageHeaderStyle copyWith({
    CoreTextStyle? eyebrowTextStyle,
    CoreTextStyle? titleTextStyle,
    CoreTextStyle? descriptionTextStyle,
    double? textSpacing,
    double? textActionsSpacing,
    double? actionSpacing,
    double? minTextWidth,
  }) {
    return CorePageHeaderStyle(
      eyebrowTextStyle: eyebrowTextStyle ?? this.eyebrowTextStyle,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
      textSpacing: textSpacing ?? this.textSpacing,
      textActionsSpacing: textActionsSpacing ?? this.textActionsSpacing,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      minTextWidth: minTextWidth ?? this.minTextWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePageHeaderStyle &&
          runtimeType == other.runtimeType &&
          eyebrowTextStyle == other.eyebrowTextStyle &&
          titleTextStyle == other.titleTextStyle &&
          descriptionTextStyle == other.descriptionTextStyle &&
          textSpacing == other.textSpacing &&
          textActionsSpacing == other.textActionsSpacing &&
          actionSpacing == other.actionSpacing &&
          minTextWidth == other.minTextWidth;

  @override
  int get hashCode => Object.hash(
    eyebrowTextStyle,
    titleTextStyle,
    descriptionTextStyle,
    textSpacing,
    textActionsSpacing,
    actionSpacing,
    minTextWidth,
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
