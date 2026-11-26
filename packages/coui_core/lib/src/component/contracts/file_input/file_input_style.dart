/// Per-instance style for `FileInput`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `FileInput` should render.
///
/// `CoreFileInputStyle` carries every chrome / dimensional override
/// (padding / spacing / border / radius / colours) plus nested slot
/// styles for the icon, label, and hint text — Epic #1302's single
/// composite-style rule.
///
/// ```text
/// design system default (static const default*)
///   → CoreFileInputTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget.fileInputStyle                         // 인스턴스별
/// ```
@immutable
class CoreFileInputStyle implements CoreStyle<CoreFileInputStyle> {
  /// Creates a [CoreFileInputStyle].
  const CoreFileInputStyle({
    this.padding,
    this.itemSpacing,
    this.textSpacing,
    this.actionSpacing,
    this.iconBoxSize,
    this.iconBoxColor,
    this.dragActiveIconBoxColor,
    this.iconBoxBorderRadius,
    this.borderRadius,
    this.borderWidth,
    this.dashLength,
    this.dashSpacing,
    this.backgroundColor,
    this.borderColor,
    this.hoverBorderColor,
    this.fileItemSpacing,
    this.transitionDuration,
    this.iconStyle,
    this.fileIconStyle,
    this.labelTextStyle,
    this.hintTextStyle,
    this.clickableStyle,
    this.saveButtonStyle,
    this.contentColor,
    this.disabledContentColor,
    this.hintColor,
    this.fileNameColor,
    this.subtleIconColor,
    this.dragActiveIconColor,
    this.fileIconColor,
    this.disabledBorderColor,
    this.disabledBackgroundColor,
    this.disabledIconBoxColor,
    this.dragOverBorderColor,
    this.dragActiveBackgroundColor,
    this.fileTextStyle,
  });

  // ─── Design-system defaults ────────────────────
  // Both Flutter and Web read these constants — Flutter resolves
  // dimensional values directly, Web maps them through the
  // `core_to_css.dart` Tailwind adapters.

  /// Default outer border radius — the `panel` role (12): the drop zone is a
  /// free-standing area that holds a list of files, not a one-line control.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.panel,
  );

  /// Default inner padding — 32 above and below, 24 at the sides.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    vertical: CoreSpace.space32,
    horizontal: CoreSpace.space24,
  );

  /// Default spacing between the icon box and the text block, and between
  /// the action buttons — uses `CoreSpace.space12`.
  static const double defaultItemSpacing = CoreSpace.space12;

  /// Default spacing between the title and the hint — `CoreSpace.space4`.
  static const double defaultTextSpacing = CoreSpace.space4;

  /// Default spacing between the text block and the action buttons —
  /// `CoreSpace.space16`.
  static const double defaultActionSpacing = CoreSpace.space16;

  /// Default icon box edge — `CoreSize.size48`.
  static const double defaultIconBoxSize = CoreSize.size48;

  /// Default icon box corner radius — fully rounded, so the box is a circle.
  static const CoreBorderRadius defaultIconBoxBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Default icon box fill at rest — `surfaceContainerHigh`.
  static const CoreColor defaultIconBoxColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default icon box fill while a file is dragged over the zone —
  /// `primaryContainer`.
  static const CoreColor defaultDragActiveIconBoxColor = CoreColor.token(
    CoreColors.primaryContainer,
  );

  /// Default outer border stroke width — uses `CoreStrokeWidth.stroke1`.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default dash segment length (6) — the drop zone's own rhythm, longer
  /// than the shared dashed-border baseline (3) so the area reads as a
  /// quiet drop target rather than a fine-grained rule. Rendered identically
  /// by the Flutter dash painter and the Web SVG `stroke-dasharray` overlay.
  /// The shared baseline is untouched, so other dashed borders do not move.
  static const double defaultDashLength = CoreSpace.space6;

  /// Default gap between dash segments (4) — see [defaultDashLength].
  static const double defaultDashSpacing = CoreSpace.space4;

  /// Default upload-icon slot style — carries the design-system upload
  /// icon size (`CoreIconSize.size24`) so the resolver can absorb the
  /// default and forward a non-null [CoreIconStyle] to the icon slot.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size24,
  );

  /// Default spacing between selected file items — uses `CoreSpace.space4`.
  static const double defaultFileItemSpacing = CoreSpace.space4;

  /// Default selected-file icon size — uses `CoreIconSize.size14`.
  static const double defaultFileIconSize = CoreIconSize.size14;

  /// Default selected-file icon slot style — carries
  /// [defaultFileIconSize] so the resolver can absorb the design-system
  /// default and forward a non-null [CoreIconStyle] to the per-file
  /// icon slot.
  static const CoreIconStyle defaultFileIconStyle = CoreIconStyle(
    size: defaultFileIconSize,
  );

  /// Default nested [CoreButtonStyle] slot for the per-file save
  /// affordance — a 16px square plain button so the glyph sits inside the
  /// file row without inflating it, tinted to the selected-file tone and
  /// brightening on hover. The glyph's size rides the button's
  /// `leadingIconStyle`, which `Button` inherits down to its content.
  static const CoreButtonStyle defaultSaveButtonStyle = CoreButtonStyle(
    foregroundColor: CoreColor.token(
      CoreColors.onSurfaceVariant,
      opacity: CoreOpacity.opacity60,
    ),
    hoverForegroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
    height: CoreSize.size16,
    width: CoreSize.size16,
    padding: .zero,
    leadingIconStyle: CoreIconStyle(size: CoreIconSize.size14),
  );

  /// Default transition duration for the hover / focus colour
  /// crossfade on the drop-zone container — uses `CoreDuration.fast`.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default nested [CoreClickableStyle] slot for the composed drop-zone
  /// `Clickable` — press-shrink is off (`pressedScale: 1`) because the
  /// drop zone is a large surface (mirrors `Card` / `Tree`'s node-row
  /// Clickable), and the disabled fade is off (`disabledOpacity: 1`)
  /// because the drop zone already paints dedicated disabled colour
  /// tokens ([defaultDisabledContentColor], [defaultDisabledBorderColor],
  /// [defaultDisabledBackgroundColor], [defaultDisabledIconBoxColor])
  /// rather than relying on opacity. Everything else stays null and
  /// resolves inside the Clickable's own resolver via
  /// `defaultClickableStyle.merge(merged.clickableStyle)`.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    pressedScale: 1,
    disabledOpacity: 1,
  );

  // ─── Colour defaults (token-backed, single source) ─────────
  // Each per-state tone is a `CoreColor.token` so Flutter resolves it
  // through `scheme.resolve(...).toValue()` (dark-mode reactive) and Web
  // emits the matching Tailwind class via the emit family — never a raw
  // `cs.<token>` interpolation or a `scheme.resolve` no-op on Web.

  /// Default primary-label content tone — `onSurface`: the instruction is
  /// the zone's title, and the hint under it carries the subtler tone.
  static const CoreColor defaultContentColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default disabled content tone — the `disabledContent` token, painted
  /// as is (no extra opacity). Label, hint, upload glyph, file glyph and
  /// file name all wear it while the zone is disabled.
  static const CoreColor defaultDisabledContentColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default disabled zone fill — the `disabledContainer` token.
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default disabled icon-box fill — the `disabledContainer` token.
  static const CoreColor defaultDisabledIconBoxColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default hint content tone — `onSurfaceSubtle`, the token the
  /// secondary line under a title wears (DatePicker's description too). A
  /// token rather than an opacity on the title's tone, so the step reads
  /// the same over every fill.
  static const CoreColor defaultHintColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default selected-file name tone — `onSurfaceVariant` at 80 % opacity.
  static const CoreColor defaultFileNameColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
    opacity: CoreOpacity.opacity80,
    fallbacks: [CoreColors.onSurface],
  );

  /// Default subtle upload-icon tone — `onSurfaceVariant` at 40 % opacity.
  static const CoreColor defaultSubtleIconColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
    opacity: CoreOpacity.opacity40,
  );

  /// Default upload-icon tone while a file is dragged over the zone —
  /// `primary`, the same tone the icon box and dashed border take on.
  static const CoreColor defaultDragActiveIconColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default selected-file icon tone (enabled) — `onSurfaceVariant` at
  /// 60 % opacity.
  static const CoreColor defaultFileIconColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
    opacity: CoreOpacity.opacity60,
  );

  /// Default idle dashed-border tone — `outlineVariant`, the pale boundary
  /// every redesigned input edge wears; a drag over the zone takes
  /// [defaultDragOverBorderColor] (`primary`) instead.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default idle-hover dashed-border tone — `onSurface`, one step past
  /// the resting [defaultBorderColor]. Pointer hover only: an actual file
  /// drag over the zone paints [defaultDragOverBorderColor] instead, and a
  /// disabled zone takes neither.
  static const CoreColor defaultHoverBorderColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default disabled dashed-border tone — the `disabledOutline` token.
  static const CoreColor defaultDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default drag-over border tone — `primary`. While a file is dragged
  /// over the zone both platforms stroke the border solid instead of
  /// dashed (same width), so the drop signal is a shape, not only a
  /// colour.
  static const CoreColor defaultDragOverBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default drag-active background tint — `primary` at 5 % opacity.
  static const CoreColor defaultDragActiveBackgroundColor = CoreColor.token(
    CoreColors.primary,
    opacity: CoreOpacity.opacity5,
  );

  // ─── Typography role defaults (token-backed) ───────────────
  // Token-backed roles so Flutter materialises them through
  // `.toValue(theme:)` and Web emits the matching `text-{role}` class via
  // `emitTypography`. Per-state colour lives on the colour defaults above.

  /// Default primary-label text style — token-backed `labelLarge` role
  /// (14 / 500 / 1.4).
  // A label role, not a body one — the slot is a control's LABEL.
  static const CoreTextStyle defaultLabelTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  );

  /// Default hint text style — token-backed `bodySmall` role (13 / 400 / 1.5).
  // A body role, not a label one: the hint is the secondary line under the
  // Medium title, and its Regular weight is what sets the two apart.
  static const CoreTextStyle defaultHintTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
  );

  /// Default selected-file name text style — token-backed `labelMedium`
  /// role.
  static const CoreTextStyle defaultFileTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
  );

  // ── Chrome (flat) ────────────────────────────

  /// Inner padding.
  final CoreEdgeInsets? padding;

  /// Spacing between vertical elements (icon / label / button / hint) —
  /// drives `Column.spacing` (Flutter) and CSS `gap` on the flex column
  /// root (Web).
  final double? itemSpacing;

  /// Spacing between the title and the hint inside the text block
  /// (logical px). `null` → [defaultTextSpacing].
  final double? textSpacing;

  /// Spacing between the text block (title + hint) and the action buttons
  /// (logical px). `null` → [defaultActionSpacing].
  final double? actionSpacing;

  /// Edge length of the circular box the upload icon sits in (logical px,
  /// pre-scaling). `null` → [defaultIconBoxSize].
  final double? iconBoxSize;

  /// Fill of the icon box at rest. `null` → [defaultIconBoxColor].
  final CoreColor? iconBoxColor;

  /// Fill of the icon box while a file is dragged over the zone.
  /// `null` → [defaultDragActiveIconBoxColor].
  final CoreColor? dragActiveIconBoxColor;

  /// Corner radius of the icon box. `null` → [defaultIconBoxBorderRadius]
  /// (fully rounded — a circle).
  final CoreBorderRadius? iconBoxBorderRadius;

  /// Outer border radius.
  final CoreBorderRadius? borderRadius;

  /// Outer border stroke width (logical px).
  final double? borderWidth;

  /// Dash segment length of the dashed drop-zone border (logical px) —
  /// every state but drag-over, which strokes solid.
  /// `null` → [defaultDashLength].
  final double? dashLength;

  /// Gap between dash segments (logical px). `null` → [defaultDashSpacing].
  final double? dashSpacing;

  /// Container background colour.
  final CoreColor? backgroundColor;

  /// Outer border stroke colour.
  final CoreColor? borderColor;

  /// Outer border stroke colour while the pointer hovers the zone and no
  /// file is being dragged over it. `null` → [defaultHoverBorderColor].
  /// Drag-over keeps its own [dragOverBorderColor]; a disabled zone never
  /// takes this.
  final CoreColor? hoverBorderColor;

  /// Spacing (and bottom margin) between selected file items — drives
  /// `Row.spacing` (Flutter) and CSS `gap` on each per-file row (Web),
  /// plus the bottom margin of each row.
  final double? fileItemSpacing;

  /// Transition duration for the hover / focus colour crossfade on
  /// the drop-zone container.
  final Duration? transitionDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Icon slot style (size + colour).
  final CoreIconStyle? iconStyle;

  /// Selected-file icon slot style (size + colour) — drives the per-file
  /// row icon glyph.
  final CoreIconStyle? fileIconStyle;

  /// Primary label text style override.
  final CoreTextStyle? labelTextStyle;

  /// Hint text style override.
  final CoreTextStyle? hintTextStyle;

  /// Style for the drop zone's `Clickable` — press, focus ring and cursor
  /// overrides for the drop zone. Laid over [defaultClickableStyle] and
  /// passed to `Clickable(clickableStyle:)` as is.
  final CoreClickableStyle? clickableStyle;

  /// Style for the `Button` of each file's save action — laid over
  /// [defaultSaveButtonStyle] and passed to `Button(buttonStyle:)` as is.
  /// Null means "no per-instance override"; the button still renders with
  /// the design-system default.
  final CoreButtonStyle? saveButtonStyle;

  /// Primary-label content colour override. `null` → [defaultContentColor].
  final CoreColor? contentColor;

  /// Disabled content colour override.
  /// `null` → [defaultDisabledContentColor].
  final CoreColor? disabledContentColor;

  /// Hint content colour override. `null` → [defaultHintColor].
  final CoreColor? hintColor;

  /// Selected-file name colour override. `null` → [defaultFileNameColor].
  final CoreColor? fileNameColor;

  /// Subtle upload-icon colour override (enabled).
  /// `null` → [defaultSubtleIconColor].
  final CoreColor? subtleIconColor;

  /// Upload-icon colour while a file is dragged over the zone (enabled).
  /// `null` → [defaultDragActiveIconColor].
  final CoreColor? dragActiveIconColor;

  /// Selected-file icon colour override (enabled).
  /// `null` → [defaultFileIconColor].
  final CoreColor? fileIconColor;

  /// Disabled dashed-border colour override.
  /// `null` → [defaultDisabledBorderColor].
  final CoreColor? disabledBorderColor;

  /// Disabled zone fill override.
  /// `null` → [defaultDisabledBackgroundColor].
  final CoreColor? disabledBackgroundColor;

  /// Disabled icon-box fill override.
  /// `null` → [defaultDisabledIconBoxColor].
  final CoreColor? disabledIconBoxColor;

  /// Drag-over border colour override — the border is solid, not dashed,
  /// while a file is over the zone. `null` → [defaultDragOverBorderColor].
  final CoreColor? dragOverBorderColor;

  /// Drag-active background tint override.
  /// `null` → [defaultDragActiveBackgroundColor].
  final CoreColor? dragActiveBackgroundColor;

  /// Selected-file name text style override.
  /// `null` → [defaultFileTextStyle].
  final CoreTextStyle? fileTextStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreFileInputStyle merge(CoreFileInputStyle? other) {
    if (other == null) return this;
    return CoreFileInputStyle(
      padding: other.padding ?? padding,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      textSpacing: other.textSpacing ?? textSpacing,
      actionSpacing: other.actionSpacing ?? actionSpacing,
      iconBoxSize: other.iconBoxSize ?? iconBoxSize,
      iconBoxColor: other.iconBoxColor ?? iconBoxColor,
      dragActiveIconBoxColor:
          other.dragActiveIconBoxColor ?? dragActiveIconBoxColor,
      iconBoxBorderRadius: other.iconBoxBorderRadius ?? iconBoxBorderRadius,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      dashLength: other.dashLength ?? dashLength,
      dashSpacing: other.dashSpacing ?? dashSpacing,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      fileItemSpacing: other.fileItemSpacing ?? fileItemSpacing,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      fileIconStyle: _mergeIcon(fileIconStyle, other.fileIconStyle),
      labelTextStyle: _mergeText(labelTextStyle, other.labelTextStyle),
      hintTextStyle: _mergeText(hintTextStyle, other.hintTextStyle),
      clickableStyle: _mergeClickable(clickableStyle, other.clickableStyle),
      saveButtonStyle: _mergeButton(saveButtonStyle, other.saveButtonStyle),
      contentColor: other.contentColor ?? contentColor,
      disabledContentColor: other.disabledContentColor ?? disabledContentColor,
      hintColor: other.hintColor ?? hintColor,
      fileNameColor: other.fileNameColor ?? fileNameColor,
      subtleIconColor: other.subtleIconColor ?? subtleIconColor,
      dragActiveIconColor: other.dragActiveIconColor ?? dragActiveIconColor,
      fileIconColor: other.fileIconColor ?? fileIconColor,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      disabledIconBoxColor: other.disabledIconBoxColor ?? disabledIconBoxColor,
      dragOverBorderColor: other.dragOverBorderColor ?? dragOverBorderColor,
      dragActiveBackgroundColor:
          other.dragActiveBackgroundColor ?? dragActiveBackgroundColor,
      fileTextStyle: _mergeText(fileTextStyle, other.fileTextStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreFileInputStyle copyWith({
    CoreEdgeInsets? padding,
    double? itemSpacing,
    double? textSpacing,
    double? actionSpacing,
    double? iconBoxSize,
    CoreColor? iconBoxColor,
    CoreColor? dragActiveIconBoxColor,
    CoreBorderRadius? iconBoxBorderRadius,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    double? dashLength,
    double? dashSpacing,
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreColor? hoverBorderColor,
    double? fileItemSpacing,
    Duration? transitionDuration,
    CoreIconStyle? iconStyle,
    CoreIconStyle? fileIconStyle,
    CoreTextStyle? labelTextStyle,
    CoreTextStyle? hintTextStyle,
    CoreClickableStyle? clickableStyle,
    CoreButtonStyle? saveButtonStyle,
    CoreColor? contentColor,
    CoreColor? disabledContentColor,
    CoreColor? hintColor,
    CoreColor? fileNameColor,
    CoreColor? subtleIconColor,
    CoreColor? dragActiveIconColor,
    CoreColor? fileIconColor,
    CoreColor? disabledBorderColor,
    CoreColor? disabledBackgroundColor,
    CoreColor? disabledIconBoxColor,
    CoreColor? dragOverBorderColor,
    CoreColor? dragActiveBackgroundColor,
    CoreTextStyle? fileTextStyle,
  }) {
    return CoreFileInputStyle(
      padding: padding ?? this.padding,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      textSpacing: textSpacing ?? this.textSpacing,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      iconBoxSize: iconBoxSize ?? this.iconBoxSize,
      iconBoxColor: iconBoxColor ?? this.iconBoxColor,
      dragActiveIconBoxColor:
          dragActiveIconBoxColor ?? this.dragActiveIconBoxColor,
      iconBoxBorderRadius: iconBoxBorderRadius ?? this.iconBoxBorderRadius,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      dashLength: dashLength ?? this.dashLength,
      dashSpacing: dashSpacing ?? this.dashSpacing,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      fileItemSpacing: fileItemSpacing ?? this.fileItemSpacing,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      iconStyle: iconStyle ?? this.iconStyle,
      fileIconStyle: fileIconStyle ?? this.fileIconStyle,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      hintTextStyle: hintTextStyle ?? this.hintTextStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      saveButtonStyle: saveButtonStyle ?? this.saveButtonStyle,
      contentColor: contentColor ?? this.contentColor,
      disabledContentColor: disabledContentColor ?? this.disabledContentColor,
      hintColor: hintColor ?? this.hintColor,
      fileNameColor: fileNameColor ?? this.fileNameColor,
      subtleIconColor: subtleIconColor ?? this.subtleIconColor,
      dragActiveIconColor: dragActiveIconColor ?? this.dragActiveIconColor,
      fileIconColor: fileIconColor ?? this.fileIconColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      disabledIconBoxColor: disabledIconBoxColor ?? this.disabledIconBoxColor,
      dragOverBorderColor: dragOverBorderColor ?? this.dragOverBorderColor,
      dragActiveBackgroundColor:
          dragActiveBackgroundColor ?? this.dragActiveBackgroundColor,
      fileTextStyle: fileTextStyle ?? this.fileTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFileInputStyle &&
          runtimeType == other.runtimeType &&
          padding == other.padding &&
          itemSpacing == other.itemSpacing &&
          textSpacing == other.textSpacing &&
          actionSpacing == other.actionSpacing &&
          iconBoxSize == other.iconBoxSize &&
          iconBoxColor == other.iconBoxColor &&
          dragActiveIconBoxColor == other.dragActiveIconBoxColor &&
          iconBoxBorderRadius == other.iconBoxBorderRadius &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          dashLength == other.dashLength &&
          dashSpacing == other.dashSpacing &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          hoverBorderColor == other.hoverBorderColor &&
          fileItemSpacing == other.fileItemSpacing &&
          transitionDuration == other.transitionDuration &&
          iconStyle == other.iconStyle &&
          fileIconStyle == other.fileIconStyle &&
          labelTextStyle == other.labelTextStyle &&
          hintTextStyle == other.hintTextStyle &&
          clickableStyle == other.clickableStyle &&
          saveButtonStyle == other.saveButtonStyle &&
          contentColor == other.contentColor &&
          disabledContentColor == other.disabledContentColor &&
          hintColor == other.hintColor &&
          fileNameColor == other.fileNameColor &&
          subtleIconColor == other.subtleIconColor &&
          dragActiveIconColor == other.dragActiveIconColor &&
          fileIconColor == other.fileIconColor &&
          disabledBorderColor == other.disabledBorderColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          disabledIconBoxColor == other.disabledIconBoxColor &&
          dragOverBorderColor == other.dragOverBorderColor &&
          dragActiveBackgroundColor == other.dragActiveBackgroundColor &&
          fileTextStyle == other.fileTextStyle;

  @override
  int get hashCode => Object.hash(
    padding,
    itemSpacing,
    Object.hash(
      textSpacing,
      actionSpacing,
      iconBoxSize,
      iconBoxColor,
      dragActiveIconBoxColor,
      iconBoxBorderRadius,
    ),
    borderRadius,
    borderWidth,
    dashLength,
    dashSpacing,
    backgroundColor,
    borderColor,
    hoverBorderColor,
    fileItemSpacing,
    transitionDuration,
    iconStyle,
    fileIconStyle,
    labelTextStyle,
    hintTextStyle,
    Object.hash(
      clickableStyle,
      saveButtonStyle,
      contentColor,
      disabledContentColor,
      hintColor,
      fileNameColor,
      subtleIconColor,
      dragActiveIconColor,
      fileIconColor,
      disabledBorderColor,
      disabledBackgroundColor,
      disabledIconBoxColor,
      dragOverBorderColor,
      dragActiveBackgroundColor,
      fileTextStyle,
    ),
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

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;

    return base.merge(other);
  }

  static CoreClickableStyle? _mergeClickable(
    CoreClickableStyle? base,
    CoreClickableStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
