/// Per-instance style for `FormLabel`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `FormLabel` should render.
///
/// Carries the label typography slot (role + colour as one nested
/// [CoreTextStyle]), the required-indicator colour, and the nested
/// gap-style slot for the gap between the label and its required
/// indicator. Platform-neutral — colour fields use [CoreColor]; the
/// label typography flows through the shared [CoreTextStyle] token slot
/// ([labelStyle]); the required-indicator gap uses the nested
/// [CoreGapStyle] slot so the receiving `Gap` widget owns its own
/// scaling.
///
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth.
@immutable
class CoreFormLabelStyle implements CoreStyle<CoreFormLabelStyle> {
  /// Creates a [CoreFormLabelStyle].
  const CoreFormLabelStyle({
    this.labelStyle,
    this.requiredColor,
    this.requiredIndicatorGapStyle,
    this.disabledColor,
  });

  // ─── Design-system defaults ───────────────────────────────────────

  /// Default label typography for the `xs`/`sm`/`md` size tier —
  /// token-backed `labelMedium` role (13px / 500) tinted with the
  /// on-surface-variant colour: a label names the control, the value in
  /// the control is the louder line. Role + colour live in one
  /// [CoreTextStyle] slot so the Flutter resolver materialises it via
  /// `defaultLabelStyle.merge(override).toValue(theme:)` and the Web
  /// resolver routes it through `emitTypography`, keeping the single
  /// typography entry point. Per-instance override flows through
  /// [labelStyle] (merged on top of the size-keyed default, see
  /// [defaultsBySize]).
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default label typography for the `lg`/`xl`/`xl2` size tier —
  /// token-backed `labelLarge` role (14px / 500), same on-surface-variant
  /// tint as [defaultLabelStyle]. Pairs with it in [defaultsBySize].
  static const CoreTextStyle defaultLabelStyleLarge = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Per-size label typography ladder (Figma "❖ FormLabel", `Size` axis
  /// `md`/`lg`). The canvas states only those two rungs; `xs`/`sm` read
  /// at `md`'s 13px (`label-medium`) and `xl`/`xl2` read at `lg`'s 14px
  /// (`label-large`) — the designer's own extension of a two-value ladder
  /// onto the shared six-tier [CoreComponentSize] scale (2026-09-11
  /// decision), the same partial-ladder shape other components in the kit
  /// already use.
  static const Map<CoreComponentSize, CoreFormLabelStyle> defaultsBySize = {
    CoreComponentSize.xs: CoreFormLabelStyle(labelStyle: defaultLabelStyle),
    CoreComponentSize.sm: CoreFormLabelStyle(labelStyle: defaultLabelStyle),
    CoreComponentSize.md: CoreFormLabelStyle(labelStyle: defaultLabelStyle),
    CoreComponentSize.lg: CoreFormLabelStyle(
      labelStyle: defaultLabelStyleLarge,
    ),
    CoreComponentSize.xl: CoreFormLabelStyle(
      labelStyle: defaultLabelStyleLarge,
    ),
    CoreComponentSize.xl2: CoreFormLabelStyle(
      labelStyle: defaultLabelStyleLarge,
    ),
  };

  /// Default `CoreFormLabelContract.size` — `md`, matching the flat
  /// pre-ladder default.
  static const CoreComponentSize defaultSize = CoreComponentSize.md;

  /// Default colour of the required indicator (`*`) while
  /// `CoreFormLabelContract.enabled` is `true`.
  static const CoreColor defaultRequiredColor = CoreColor.token(
    CoreColors.error,
  );

  /// Default colour applied to BOTH the label and the required
  /// indicator while `CoreFormLabelContract.enabled` is `false` (Figma
  /// "❖ FormLabel", `State` axis `disabled`, 2026-09) — the same
  /// `disabled-content` tone forces both, dimming the `*` along with
  /// the label it marks rather than leaving it in its enabled colour.
  static const CoreColor defaultDisabledColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default gap style — `CoreGapStyle(size: 4)` — between the label
  /// and its required indicator. The whole nested [CoreGapStyle] slot
  /// is forwarded to the `Gap` widget that separates the label and
  /// its trailing `*` indicator. Per-instance override flows through
  /// [requiredIndicatorGapStyle] (merged on top of this default).
  static const CoreGapStyle defaultRequiredIndicatorGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  // ─── Fields ───────────────────────────────────────────────────────

  /// Label typography — role + colour. `null` → the size-keyed default in
  /// [defaultsBySize]. Overriding only the colour keeps the default role,
  /// and vice versa, because this override is laid over that size
  /// default.
  final CoreTextStyle? labelStyle;

  /// Override colour applied to the required indicator while enabled.
  final CoreColor? requiredColor;

  /// Gap between the label and the required indicator, passed to
  /// `Gap(gapStyle: …)` as is. Laid over the design-system default
  /// ([defaultRequiredIndicatorGapStyle]).
  ///
  /// `Gap` runs its own resolve step, so this slot stays in pre-scaling
  /// units (the receiving widget owns scaling).
  final CoreGapStyle? requiredIndicatorGapStyle;

  /// Override colour applied to the label and the required indicator
  /// while `CoreFormLabelContract.enabled` is `false`. `null` → the
  /// design-system [defaultDisabledColor].
  final CoreColor? disabledColor;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreFormLabelStyle merge(CoreFormLabelStyle? other) {
    if (other == null) return this;
    return CoreFormLabelStyle(
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      requiredColor: other.requiredColor ?? requiredColor,
      requiredIndicatorGapStyle: _mergeGap(
        requiredIndicatorGapStyle,
        other.requiredIndicatorGapStyle,
      ),
      disabledColor: other.disabledColor ?? disabledColor,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreFormLabelStyle copyWith({
    CoreTextStyle? labelStyle,
    CoreColor? requiredColor,
    CoreGapStyle? requiredIndicatorGapStyle,
    CoreColor? disabledColor,
  }) {
    return CoreFormLabelStyle(
      labelStyle: labelStyle ?? this.labelStyle,
      requiredColor: requiredColor ?? this.requiredColor,
      requiredIndicatorGapStyle:
          requiredIndicatorGapStyle ?? this.requiredIndicatorGapStyle,
      disabledColor: disabledColor ?? this.disabledColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFormLabelStyle &&
          runtimeType == other.runtimeType &&
          labelStyle == other.labelStyle &&
          requiredColor == other.requiredColor &&
          requiredIndicatorGapStyle == other.requiredIndicatorGapStyle &&
          disabledColor == other.disabledColor;

  @override
  int get hashCode => Object.hash(
    labelStyle,
    requiredColor,
    requiredIndicatorGapStyle,
    disabledColor,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
