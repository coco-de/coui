/// Per-instance style for `StepItem`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/steps/step_status.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `StepItem` should render.
///
/// The row's geometry and type roles are status-independent `static const`
/// defaults; what a status changes — the colours of the glyph, the title
/// and the trailing note — is one row of [defaultsByStatus]. Flutter and
/// Web read both from here.
///
/// **The status lives on the widget, not on this style.** To draw a failed
/// step pass `status:`; this style only describes chrome.
///
/// ```text
/// CoreStepItemStyle.default* + defaultsByStatus[status]
///   → CoreStepItemTheme.style                      // 프로젝트 공통
///   → CoreStepItemTheme.statusStyles[status]
///   → parent slot (CoreStepsStyle.stepItemStyle)
///   → widget.stepItemStyle                         // 인스턴스별
/// ```
@immutable
class CoreStepItemStyle implements CoreStyle<CoreStepItemStyle> {
  /// Creates a [CoreStepItemStyle].
  const CoreStepItemStyle({
    this.minHeight,
    this.padding,
    this.iconTitleGapStyle,
    this.titleTrailingGapStyle,
    this.iconStyle,
    this.titleStyle,
    this.trailingStyle,
  });

  // ─── Design-system defaults (status-independent) ──

  /// Default minimum row height — 32 logical px. The row's own height, not
  /// a rung of the control ladder (a step row is not a control), so the
  /// density axis does not move it; its padding and gap do.
  ///
  /// 6 + 19.6 + 6 = 31.6: the vertical padding around one `labelLarge`
  /// line fits inside it, so one-line rows stack at exactly this pitch.
  static const double defaultMinHeight = CoreSize.size32;

  /// Default content insets — 6 above and below, none at the sides. The
  /// row lines up flush with whatever hosts it (a card's padding, a page
  /// column).
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    vertical: CoreSpace.space6,
  );

  /// Default gap between the status glyph and the title.
  static const CoreGapStyle defaultIconTitleGapStyle = CoreGapStyle(
    size: CoreSpace.space10,
  );

  /// Default gap kept between the title's end and the trailing note — the
  /// same 10 as the glyph gap, so the row has one rhythm and a title cut
  /// with an ellipsis never touches the note.
  static const CoreGapStyle defaultTitleTrailingGapStyle = CoreGapStyle(
    size: CoreSpace.space10,
  );

  /// Default status-glyph style — 16 logical px. The colour is the status
  /// row's ([defaultsByStatus]); the stroke is the icon rule's for 16
  /// (`CoreIconStroke`), not this style's.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default title typography — the `labelLarge` role (14 / 500 / 1.4).
  /// The colour is the status row's.
  static const CoreTextStyle defaultTitleStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  );

  /// Default trailing-note typography — the `labelSmall` role
  /// (12 / 500 / 1.4). The colour is the status row's.
  static const CoreTextStyle defaultTrailingStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
  );

  // ─── Status-keyed defaults ──

  /// What each status paints — the glyph, the title and the trailing note.
  ///
  /// The glyph carries the status's colour; the title stays `onSurface`
  /// except on a step not reached yet, which steps back to
  /// `onSurfaceVariant`; the trailing note is the third text tier
  /// (`onSurfaceSubtle`) except on a failed step, where it is the reason
  /// the step failed and reads in `onErrorContainer` — the error family's
  /// text ink, which clears 4.5:1 on a card face where `error` itself does
  /// not.
  ///
  /// The value type is [CoreStepItemStyle] itself, so each row's fields
  /// are the very slots a caller overrides.
  static const Map<CoreStepStatus, CoreStepItemStyle> defaultsByStatus = {
    CoreStepStatus.done: CoreStepItemStyle(
      iconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.success)),
      titleStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSurface)),
      trailingStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
    ),
    CoreStepStatus.current: CoreStepItemStyle(
      iconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.primary)),
      titleStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSurface)),
      trailingStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
    ),
    CoreStepStatus.todo: CoreStepItemStyle(
      iconStyle: CoreIconStyle(
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
      titleStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
      trailingStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
    ),
    CoreStepStatus.failed: CoreStepItemStyle(
      iconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.error)),
      titleStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSurface)),
      trailingStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onErrorContainer),
      ),
    ),
  };

  // ─── Fields ──

  /// Minimum row height (logical px). Falls back to [defaultMinHeight].
  final double? minHeight;

  /// Content insets. Falls back to [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Gap between the glyph and the title. Merged on top of
  /// [defaultIconTitleGapStyle].
  final CoreGapStyle? iconTitleGapStyle;

  /// Gap between the title and the trailing note. Merged on top of
  /// [defaultTitleTrailingGapStyle].
  final CoreGapStyle? titleTrailingGapStyle;

  /// Style of the status glyph — size and colour. Merged on top of
  /// [defaultIconStyle] and the status row.
  final CoreIconStyle? iconStyle;

  /// Title typography and colour. Merged on top of [defaultTitleStyle]
  /// and the status row.
  final CoreTextStyle? titleStyle;

  /// Trailing-note typography and colour. Merged on top of
  /// [defaultTrailingStyle] and the status row.
  final CoreTextStyle? trailingStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slots merge field by
  /// field.
  @override
  CoreStepItemStyle merge(CoreStepItemStyle? other) {
    if (other == null) return this;
    return CoreStepItemStyle(
      minHeight: other.minHeight ?? minHeight,
      padding: other.padding ?? padding,
      iconTitleGapStyle:
          iconTitleGapStyle?.merge(other.iconTitleGapStyle) ??
          other.iconTitleGapStyle,
      titleTrailingGapStyle:
          titleTrailingGapStyle?.merge(other.titleTrailingGapStyle) ??
          other.titleTrailingGapStyle,
      iconStyle: iconStyle?.merge(other.iconStyle) ?? other.iconStyle,
      titleStyle: titleStyle?.merge(other.titleStyle) ?? other.titleStyle,
      trailingStyle:
          trailingStyle?.merge(other.trailingStyle) ?? other.trailingStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreStepItemStyle copyWith({
    double? minHeight,
    CoreEdgeInsets? padding,
    CoreGapStyle? iconTitleGapStyle,
    CoreGapStyle? titleTrailingGapStyle,
    CoreIconStyle? iconStyle,
    CoreTextStyle? titleStyle,
    CoreTextStyle? trailingStyle,
  }) {
    return CoreStepItemStyle(
      minHeight: minHeight ?? this.minHeight,
      padding: padding ?? this.padding,
      iconTitleGapStyle: iconTitleGapStyle ?? this.iconTitleGapStyle,
      titleTrailingGapStyle:
          titleTrailingGapStyle ?? this.titleTrailingGapStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      titleStyle: titleStyle ?? this.titleStyle,
      trailingStyle: trailingStyle ?? this.trailingStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStepItemStyle &&
          runtimeType == other.runtimeType &&
          minHeight == other.minHeight &&
          padding == other.padding &&
          iconTitleGapStyle == other.iconTitleGapStyle &&
          titleTrailingGapStyle == other.titleTrailingGapStyle &&
          iconStyle == other.iconStyle &&
          titleStyle == other.titleStyle &&
          trailingStyle == other.trailingStyle;

  @override
  int get hashCode => Object.hash(
    minHeight,
    padding,
    iconTitleGapStyle,
    titleTrailingGapStyle,
    iconStyle,
    titleStyle,
    trailingStyle,
  );
}
