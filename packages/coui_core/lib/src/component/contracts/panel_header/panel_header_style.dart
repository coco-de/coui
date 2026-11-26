/// Per-instance style for `PanelHeader`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `PanelHeader` renders.
///
/// The header draws no box of its own — no fill or border; it is a row over
/// the panel's content. The style carries the title role, the space under
/// the row, the space between the title and the action, and the narrowest
/// the title may get before the action moves under it.
///
/// ```text
/// CorePanelHeaderStyle.default*
///   → CorePanelHeaderTheme.style                    // project-wide
///   → widget.panelHeaderStyle                       // per-instance
/// ```
@immutable
class CorePanelHeaderStyle implements CoreStyle<CorePanelHeaderStyle> {
  /// Creates a [CorePanelHeaderStyle].
  const CorePanelHeaderStyle({
    this.titleTextStyle,
    this.padding,
    this.titleActionSpacing,
    this.minTitleWidth,
  });

  /// Text style the title slot's content inherits, laid over
  /// [defaultTitleTextStyle].
  final CoreTextStyle? titleTextStyle;

  /// Inset around the row (pre-scaling). `null` → [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Space between the title and the action — across the row while they
  /// sit side by side, and down the column once the action has moved under
  /// the title (logical px, pre-scaling). `null` → [defaultTitleActionSpacing].
  final double? titleActionSpacing;

  /// The narrowest the title may get beside the action (logical px,
  /// pre-scaling). Below it the action moves under the title. `null` →
  /// [defaultMinTitleWidth].
  final double? minTitleWidth;

  // ─── Design-system defaults (single source, Flutter ↔ Web) ──────

  /// The title — `titleMedium` (18, bold) in `onSurface`.
  static const CoreTextStyle defaultTitleTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// `space8` under the row and nothing around it — the line between the
  /// header and the panel's content; the sides are the panel's own inset.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.only(
    bottom: CoreSpace.space8,
  );

  /// Between the title and the action — `space8`.
  static const double defaultTitleActionSpacing = CoreSpace.space8;

  /// The narrowest title beside the action — `CoreSize.size128`. A panel
  /// title is a few words, and the action is one small link; only a very
  /// narrow panel puts the link under the title.
  static const double defaultMinTitleWidth = CoreSize.size128;

  /// Merges [other] on top of this style — every field [other] states wins;
  /// the title style merges field by field.
  @override
  CorePanelHeaderStyle merge(CorePanelHeaderStyle? other) {
    if (other == null) return this;
    return CorePanelHeaderStyle(
      titleTextStyle: titleTextStyle == null
          ? other.titleTextStyle
          : titleTextStyle!.merge(other.titleTextStyle),
      padding: other.padding ?? padding,
      titleActionSpacing: other.titleActionSpacing ?? titleActionSpacing,
      minTitleWidth: other.minTitleWidth ?? minTitleWidth,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CorePanelHeaderStyle copyWith({
    CoreTextStyle? titleTextStyle,
    CoreEdgeInsets? padding,
    double? titleActionSpacing,
    double? minTitleWidth,
  }) {
    return CorePanelHeaderStyle(
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      padding: padding ?? this.padding,
      titleActionSpacing: titleActionSpacing ?? this.titleActionSpacing,
      minTitleWidth: minTitleWidth ?? this.minTitleWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePanelHeaderStyle &&
          runtimeType == other.runtimeType &&
          titleTextStyle == other.titleTextStyle &&
          padding == other.padding &&
          titleActionSpacing == other.titleActionSpacing &&
          minTitleWidth == other.minTitleWidth;

  @override
  int get hashCode =>
      Object.hash(titleTextStyle, padding, titleActionSpacing, minTitleWidth);
}
