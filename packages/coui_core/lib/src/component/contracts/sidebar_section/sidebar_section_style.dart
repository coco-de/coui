/// Per-instance style for `SidebarSection`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `SidebarSection` heading renders.
///
/// A small quiet label above a run of rows, with an optional action glyph
/// at its far end. 12 above it and 4 below, so it reads as belonging to the
/// rows that follow.
///
/// ```text
/// defaultX
///   → CoreSidebarSectionTheme.style
///   → widget.sidebarSectionStyle
/// ```
@immutable
class CoreSidebarSectionStyle implements CoreStyle<CoreSidebarSectionStyle> {
  /// Creates a [CoreSidebarSectionStyle].
  const CoreSidebarSectionStyle({
    this.padding,
    this.contentSpacing,
    this.labelStyle,
    this.actionIconStyle,
  });

  // ─── Design-system defaults ──

  /// Insets — 12 above, 4 below; 10 at the start so the label lines up with
  /// a row's glyph, 8 at the end.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.directional(
    start: CoreSpace.space10,
    top: CoreSpace.space12,
    end: CoreSpace.space8,
    bottom: CoreSpace.space4,
  );

  /// Spacing between the label and the action.
  static const double defaultContentSpacing = CoreSpace.space8;

  /// The heading — `labelSmall` in `onSurfaceSubtle`.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// The action glyph — 16 in `onSurfaceVariant`.
  static const CoreIconStyle defaultActionIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Insets. `null` defers to [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Spacing between the label and the action. `null` defers to
  /// [defaultContentSpacing].
  final double? contentSpacing;

  /// The heading's text. `null` defers to [defaultLabelStyle].
  final CoreTextStyle? labelStyle;

  /// The action glyph. `null` defers to [defaultActionIconStyle].
  final CoreIconStyle? actionIconStyle;

  /// Returns a copy with non-null fields from [other] overriding the
  /// matching fields here. Nested slot styles merge recursively.
  @override
  CoreSidebarSectionStyle merge(CoreSidebarSectionStyle? other) {
    if (other == null) return this;
    return CoreSidebarSectionStyle(
      padding: other.padding ?? padding,
      contentSpacing: other.contentSpacing ?? contentSpacing,
      labelStyle: labelStyle?.merge(other.labelStyle) ?? other.labelStyle,
      actionIconStyle:
          actionIconStyle?.merge(other.actionIconStyle) ??
          other.actionIconStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreSidebarSectionStyle copyWith({
    CoreEdgeInsets? padding,
    double? contentSpacing,
    CoreTextStyle? labelStyle,
    CoreIconStyle? actionIconStyle,
  }) {
    return CoreSidebarSectionStyle(
      padding: padding ?? this.padding,
      contentSpacing: contentSpacing ?? this.contentSpacing,
      labelStyle: labelStyle ?? this.labelStyle,
      actionIconStyle: actionIconStyle ?? this.actionIconStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarSectionStyle &&
          runtimeType == other.runtimeType &&
          padding == other.padding &&
          contentSpacing == other.contentSpacing &&
          labelStyle == other.labelStyle &&
          actionIconStyle == other.actionIconStyle;

  @override
  int get hashCode =>
      Object.hash(padding, contentSpacing, labelStyle, actionIconStyle);
}
