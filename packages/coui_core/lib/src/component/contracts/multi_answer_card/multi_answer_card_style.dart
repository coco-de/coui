/// Per-instance style for `MultiAnswerCard`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/checkbox/checkbox_style.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/line_height.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `MultiAnswerCard` should render.
///
/// `CoreMultiAnswerCardStyle` carries chrome / dimensional flat fields
/// for the selectable card in both its selected and unselected states.
/// Behavioural / semantic fields (`value`, `selected`, `enabled`,
/// `onChanged`, `child`) stay flat on the widget / contract.
///
/// ```text
/// design system default
///   → CoreMultiAnswerCardTheme.style              // 프로젝트 공통
///   → parent component slot override
///   → widget.multiAnswerCardStyle                 // 인스턴스별
/// ```
@immutable
class CoreMultiAnswerCardStyle implements CoreStyle<CoreMultiAnswerCardStyle> {
  /// Creates a [CoreMultiAnswerCardStyle].
  const CoreMultiAnswerCardStyle({
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.hoverColor,
    this.hoverBorderColor,
    this.disabledBackgroundColor,
    this.disabledBorderColor,
    this.borderWidth,
    this.selectedBorderWidth,
    this.borderRadius,
    this.padding,
    this.transitionDuration,
    this.bodyTextStyle,
    this.selectedBodyTextStyle,
    this.disabledBodyTextStyle,
    this.checkboxGapStyle,
    this.checkboxStyle,
    this.clickableStyle,
  });

  // ─── Design-system defaults ────────────────────

  /// Default card background colour (unselected).
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default card background colour (selected) — the brand container
  /// tone. The selection is shown by this fill and the composed checkbox,
  /// not by a thicker border (see [defaultSelectedBorderWidth]).
  static const CoreColor defaultSelectedBackgroundColor = CoreColor.token(
    CoreColors.primaryContainer,
  );

  /// Default card border colour (unselected, resting) — the same quiet
  /// line a resting text field draws.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default card border colour (selected).
  static const CoreColor defaultSelectedBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default card border colour while hovered (enabled, unselected) —
  /// one step stronger than the resting line, like a text field's hover.
  static const CoreColor defaultHoverBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default card hover background colour.
  static const CoreColor defaultHoverColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default card background colour when disabled (selected or not) —
  /// the dedicated disabled container token, not a faded enabled fill.
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default card border colour when disabled (selected or not).
  static const CoreColor defaultDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default body text style — token-backed `bodyLarge` + `onSurface`
  /// (mirrors `CoreCardStyle.defaultBodyTextStyle`). Flutter applies it
  /// via `DefaultTextStyle.merge`; Web emits the `text-body-large`
  /// role class on the card chrome — both platforms then render the
  /// caller-supplied child at the same base typography.
  static const CoreTextStyle defaultBodyTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyLarge,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default body text style while selected (enabled) — the
  /// medium-weight `labelXl` role at the same 15px as
  /// [defaultBodyTextStyle], with that role's 150% line height held, so
  /// the choice reads without the card changing height (the label role's
  /// own 140% line is a pixel and a half shorter than the resting one).
  ///
  /// `static final`, not `const` — the `.copyWith(lineHeight:)` overlay on
  /// the role is not const-evaluable.
  static final CoreTextStyle defaultSelectedBodyTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelXl,
        color: CoreColor.token(CoreColors.onSurface),
      ).copyWith(lineHeight: CoreLineHeight.h150);

  /// Default body text style when disabled (selected or not) — the
  /// resting role with the dedicated disabled content colour.
  static const CoreTextStyle defaultDisabledBodyTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyLarge,
    color: CoreColor.token(CoreColors.disabledContent),
  );

  /// Default card border width (unselected, logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default card border width (selected, logical px). Equal to
  /// [defaultBorderWidth] so a selection never changes the card's height.
  static const double defaultSelectedBorderWidth = CoreStrokeWidth.stroke1;

  /// Default card border radius.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius12,
  );

  /// Default card content padding.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    CoreSpace.space16,
  );

  /// Default gap between the answer content and the trailing checkbox.
  static const CoreGapStyle defaultCheckboxGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default size of the composed trailing `Checkbox`.
  static const CoreComponentSize defaultCheckboxSize = CoreComponentSize.lg;

  /// Default nested [CoreCheckboxStyle] slot for the composed
  /// trailing `Checkbox` — an empty partial: the checkbox takes its own
  /// standard chrome for [defaultCheckboxSize].
  static const CoreCheckboxStyle defaultCheckboxStyle = CoreCheckboxStyle();

  /// Default transition duration for selected / hover state
  /// changes.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// `Clickable` — a partial with the one diverging override: the card
  /// paints its own disabled state with dedicated tokens
  /// ([defaultDisabledBackgroundColor] / [defaultDisabledBorderColor] /
  /// [defaultDisabledBodyTextStyle]), so the Clickable's generic
  /// disabled fade must stay off or the disabled chrome fades twice.
  /// Everything else stays null and resolves inside the Clickable's own
  /// resolver. Named so the resolver's
  /// `defaultClickableStyle.merge(merged.clickableStyle)` forward has a
  /// single-source default.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Card background colour override (unselected).
  final CoreColor? backgroundColor;

  /// Card background colour override (selected).
  final CoreColor? selectedBackgroundColor;

  /// Card border colour override (unselected).
  final CoreColor? borderColor;

  /// Card border colour override (selected).
  final CoreColor? selectedBorderColor;

  /// Card hover background colour override.
  final CoreColor? hoverColor;

  /// Card border colour override while hovered (enabled, unselected).
  final CoreColor? hoverBorderColor;

  /// Card background colour override when disabled.
  final CoreColor? disabledBackgroundColor;

  /// Card border colour override when disabled.
  final CoreColor? disabledBorderColor;

  /// Card border width override (unselected, logical px).
  final double? borderWidth;

  /// Card border width override (selected, logical px).
  final double? selectedBorderWidth;

  /// Card border radius override.
  final CoreBorderRadius? borderRadius;

  /// Card content padding override.
  final CoreEdgeInsets? padding;

  /// Transition duration override for selected / hover state
  /// changes; `null` → [defaultTransitionDuration].
  final Duration? transitionDuration;

  /// Body text style for the caller-supplied child widget (typography
  /// role + colour in one `CoreTextStyle`). `null` defers to
  /// [defaultBodyTextStyle] — the design-system base typography, so the
  /// card text matches the Web side's inherited `bodyMedium` base.
  final CoreTextStyle? bodyTextStyle;

  /// Body text style override while selected (enabled). `null` defers
  /// to [defaultSelectedBodyTextStyle].
  final CoreTextStyle? selectedBodyTextStyle;

  /// Body text style override when disabled. `null` defers to
  /// [defaultDisabledBodyTextStyle].
  final CoreTextStyle? disabledBodyTextStyle;

  // ─── Slot Styles (nested) ─────────────────────

  /// Gap between the answer content and the trailing checkbox. Laid over
  /// [defaultCheckboxGapStyle] and passed to the `Gap` as is.
  final CoreGapStyle? checkboxGapStyle;

  /// Style for the trailing `Checkbox`. Laid over [defaultCheckboxStyle]
  /// and passed to the `Checkbox` as is, which fills in the rest.
  final CoreCheckboxStyle? checkboxStyle;

  /// Style for the card's `Clickable` — press scale, durations, focus
  /// ring, disabled opacity. Laid over [defaultClickableStyle] and passed
  /// to the `Clickable` as is, which fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreMultiAnswerCardStyle merge(CoreMultiAnswerCardStyle? other) {
    if (other == null) return this;
    return CoreMultiAnswerCardStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      selectedBackgroundColor:
          other.selectedBackgroundColor ?? selectedBackgroundColor,
      borderColor: other.borderColor ?? borderColor,
      selectedBorderColor: other.selectedBorderColor ?? selectedBorderColor,
      hoverColor: other.hoverColor ?? hoverColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      selectedBorderWidth: other.selectedBorderWidth ?? selectedBorderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      bodyTextStyle:
          bodyTextStyle?.merge(other.bodyTextStyle) ?? other.bodyTextStyle,
      selectedBodyTextStyle:
          selectedBodyTextStyle?.merge(other.selectedBodyTextStyle) ??
          other.selectedBodyTextStyle,
      disabledBodyTextStyle:
          disabledBodyTextStyle?.merge(other.disabledBodyTextStyle) ??
          other.disabledBodyTextStyle,
      checkboxGapStyle:
          checkboxGapStyle?.merge(other.checkboxGapStyle) ??
          other.checkboxGapStyle,
      checkboxStyle:
          checkboxStyle?.merge(other.checkboxStyle) ?? other.checkboxStyle,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreMultiAnswerCardStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? selectedBackgroundColor,
    CoreColor? borderColor,
    CoreColor? selectedBorderColor,
    CoreColor? hoverColor,
    CoreColor? hoverBorderColor,
    CoreColor? disabledBackgroundColor,
    CoreColor? disabledBorderColor,
    double? borderWidth,
    double? selectedBorderWidth,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    Duration? transitionDuration,
    CoreTextStyle? bodyTextStyle,
    CoreTextStyle? selectedBodyTextStyle,
    CoreTextStyle? disabledBodyTextStyle,
    CoreGapStyle? checkboxGapStyle,
    CoreCheckboxStyle? checkboxStyle,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreMultiAnswerCardStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      borderColor: borderColor ?? this.borderColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      hoverColor: hoverColor ?? this.hoverColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
      selectedBodyTextStyle:
          selectedBodyTextStyle ?? this.selectedBodyTextStyle,
      disabledBodyTextStyle:
          disabledBodyTextStyle ?? this.disabledBodyTextStyle,
      checkboxGapStyle: checkboxGapStyle ?? this.checkboxGapStyle,
      checkboxStyle: checkboxStyle ?? this.checkboxStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMultiAnswerCardStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          selectedBackgroundColor == other.selectedBackgroundColor &&
          borderColor == other.borderColor &&
          selectedBorderColor == other.selectedBorderColor &&
          hoverColor == other.hoverColor &&
          hoverBorderColor == other.hoverBorderColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          disabledBorderColor == other.disabledBorderColor &&
          borderWidth == other.borderWidth &&
          selectedBorderWidth == other.selectedBorderWidth &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          transitionDuration == other.transitionDuration &&
          bodyTextStyle == other.bodyTextStyle &&
          selectedBodyTextStyle == other.selectedBodyTextStyle &&
          disabledBodyTextStyle == other.disabledBodyTextStyle &&
          checkboxGapStyle == other.checkboxGapStyle &&
          checkboxStyle == other.checkboxStyle &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    selectedBackgroundColor,
    borderColor,
    selectedBorderColor,
    hoverColor,
    hoverBorderColor,
    disabledBackgroundColor,
    disabledBorderColor,
    borderWidth,
    selectedBorderWidth,
    Object.hash(
      borderRadius,
      padding,
      transitionDuration,
      bodyTextStyle,
      selectedBodyTextStyle,
      disabledBodyTextStyle,
      checkboxGapStyle,
      checkboxStyle,
      clickableStyle,
    ),
  );
}
