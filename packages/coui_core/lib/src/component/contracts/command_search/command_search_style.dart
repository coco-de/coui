/// Chrome contract for `CommandSearch`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/command/command_size.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Every chrome value a `CommandSearch` trigger draws, on both platforms.
///
/// Two default tables:
///
/// - [defaultsBySize] — the size ladder: height (32 / 40 / 48, the control
///   ladder's `sm` · `md` · `lg` rungs, so a density moves it), corner
///   (height × 0.25), insets, seat gap, leading glyph and hint role.
/// - the rest — the face, the ink, their disabled pair, the state-layer
///   colour and ramp, and the composed `Clickable` chrome.
///
/// The face is a card-level fill with no stroke: the trigger is a button,
/// not an input, so it carries no boundary an input would — the glyph, the
/// hint and the shortcut key are what tell a reader it is there.
@immutable
class CoreCommandSearchStyle implements CoreStyle<CoreCommandSearchStyle> {
  /// Creates a style. Every field is nullable — a partial override.
  const CoreCommandSearchStyle({
    this.height,
    this.padding,
    this.contentGapStyle,
    this.borderRadius,
    this.leadingIconStyle,
    this.hintTextStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.stateLayerColor,
    this.stateLayer,
    this.clickableStyle,
  });

  // ─── Axis-free defaults ───────────────────────────────────────────

  /// Default for [backgroundColor] — the card-level face. A trigger sits in
  /// an app bar or a sidebar (both `surfaceContainerLow`), one step under
  /// it; it is not meant for a floating panel, whose face it would match.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default for [foregroundColor] — the ink of the leading glyph and the
  /// hint. The secondary-text step, because a state layer washes over it:
  /// the quieter `onSurfaceSubtle` step drops under 4.5 : 1 once the face is
  /// washed.
  static const CoreColor defaultForegroundColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default for [disabledBackgroundColor] — the face a disabled control
  /// drops to.
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default for [disabledForegroundColor] — the floor every disabled label
  /// and glyph in the kit drops to. Read by the leading glyph and the hint
  /// while the trigger is disabled.
  static const CoreColor defaultDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default for [stateLayerColor] — the colour washed over the face on
  /// hover, focus and press. The primary ink rather than the trigger's own
  /// quieter ink, so the wash reads as the same layer every other control
  /// paints.
  static const CoreColor defaultStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default for [stateLayer] — hover 8 / focus 8 / pressed 12. Focus
  /// matches hover because the ring is the focus indicator and the wash
  /// only a secondary cue; the pressed wash is the light-surface weight
  /// ([CoreOpacity.pressed]), the ramp a menu row presses with.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer(
    hover: CoreOpacity.opacity8,
    focus: CoreOpacity.opacity8,
    pressed: CoreOpacity.pressed,
  );

  /// Default for [clickableStyle] — the composed `Clickable`'s own focus
  /// ring and press feedback, with its disabled dimming turned off: the
  /// disabled face and ink above already say the trigger is disabled, and a
  /// multiplier on top of them would make the contrast unpredictable.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  // ─── Size-keyed defaults ──────────────────────────────────────────

  /// The size ladder: 32 · 40 · 48.
  ///
  /// The corner is the height × 0.25 on each rung (8 · 10 · 12), written per
  /// row. The insets are directional — the end inset is the smaller one,
  /// because the shortcut key at the end carries its own padding — so they
  /// mirror in a right-to-left locale.
  static const Map<CoreCommandSize, CoreCommandSearchStyle> defaultsBySize = {
    CoreCommandSize.sm: CoreCommandSearchStyle(
      height: CoreControlSize.heightSm,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      padding: CoreEdgeInsets.directional(
        start: CoreSpace.space12,
        end: CoreSpace.space8,
      ),
      contentGapStyle: CoreGapStyle(size: CoreSpace.space8, crossAxisExtent: 0),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      hintTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
    ),
    CoreCommandSize.md: CoreCommandSearchStyle(
      height: CoreControlSize.heightMd,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      padding: CoreEdgeInsets.directional(
        start: CoreSpace.space12,
        end: CoreSpace.space10,
      ),
      contentGapStyle: CoreGapStyle(size: CoreSpace.space8, crossAxisExtent: 0),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size18),
      hintTextStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
    ),
    CoreCommandSize.lg: CoreCommandSearchStyle(
      height: CoreControlSize.heightLg,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      padding: CoreEdgeInsets.directional(
        start: CoreSpace.space16,
        end: CoreSpace.space12,
      ),
      contentGapStyle: CoreGapStyle(
        size: CoreSpace.space12,
        crossAxisExtent: 0,
      ),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size20),
      hintTextStyle: CoreTextStyle.token(CoreTextStyles.bodyLarge),
    ),
  };

  // ─── Fields ───────────────────────────────────────────────────────

  /// Trigger height (logical px). `null` → the size ladder, which a theme
  /// density moves one rung; a height stated here stays as stated.
  final double? height;

  /// Content insets — directional, start and end. `null` → the size ladder.
  final CoreEdgeInsets? padding;

  /// Gap between the leading glyph, the hint and the shortcut. `null` → the
  /// size ladder.
  final CoreGapStyle? contentGapStyle;

  /// Corner radius — also the focus ring's corner. `null` → the size row's
  /// corner (the height × 0.25).
  final CoreBorderRadius? borderRadius;

  /// Look of the leading glyph — its size, and a colour that wins over
  /// [foregroundColor] at rest. `null` → the size ladder.
  final CoreIconStyle? leadingIconStyle;

  /// Hint typography — role, and a colour that wins over [foregroundColor]
  /// at rest. `null` → the size ladder.
  final CoreTextStyle? hintTextStyle;

  /// Resting face. `null` → [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// Ink of the leading glyph and the hint. `null` →
  /// [defaultForegroundColor].
  final CoreColor? foregroundColor;

  /// Face while disabled. `null` → [defaultDisabledBackgroundColor].
  final CoreColor? disabledBackgroundColor;

  /// Ink while disabled — the glyph and the hint. `null` →
  /// [defaultDisabledForegroundColor].
  final CoreColor? disabledForegroundColor;

  /// Colour washed over the face on hover / focus / press. `null` →
  /// [defaultStateLayerColor].
  final CoreColor? stateLayerColor;

  /// How strongly [stateLayerColor] is washed over the face per state.
  /// `null` → [defaultStateLayer]. A disabled trigger takes no wash.
  final CoreStateLayer? stateLayer;

  /// Style of the trigger's `Clickable` — focus ring, press feedback.
  /// `null` → [defaultClickableStyle]. Passed to the `Clickable` as is; the
  /// focus ring takes the trigger's corner unless this sets one.
  final CoreClickableStyle? clickableStyle;

  @override
  CoreCommandSearchStyle merge(CoreCommandSearchStyle? other) {
    if (other == null) return this;
    return CoreCommandSearchStyle(
      height: other.height ?? height,
      padding: other.padding ?? padding,
      contentGapStyle:
          contentGapStyle?.merge(other.contentGapStyle) ??
          other.contentGapStyle,
      borderRadius: other.borderRadius ?? borderRadius,
      leadingIconStyle:
          leadingIconStyle?.merge(other.leadingIconStyle) ??
          other.leadingIconStyle,
      hintTextStyle:
          hintTextStyle?.merge(other.hintTextStyle) ?? other.hintTextStyle,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      disabledForegroundColor:
          other.disabledForegroundColor ?? disabledForegroundColor,
      stateLayerColor: other.stateLayerColor ?? stateLayerColor,
      stateLayer: other.stateLayer ?? stateLayer,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy with the given fields replaced.
  CoreCommandSearchStyle copyWith({
    double? height,
    CoreEdgeInsets? padding,
    CoreGapStyle? contentGapStyle,
    CoreBorderRadius? borderRadius,
    CoreIconStyle? leadingIconStyle,
    CoreTextStyle? hintTextStyle,
    CoreColor? backgroundColor,
    CoreColor? foregroundColor,
    CoreColor? disabledBackgroundColor,
    CoreColor? disabledForegroundColor,
    CoreColor? stateLayerColor,
    CoreStateLayer? stateLayer,
    CoreClickableStyle? clickableStyle,
  }) => CoreCommandSearchStyle(
    height: height ?? this.height,
    padding: padding ?? this.padding,
    contentGapStyle: contentGapStyle ?? this.contentGapStyle,
    borderRadius: borderRadius ?? this.borderRadius,
    leadingIconStyle: leadingIconStyle ?? this.leadingIconStyle,
    hintTextStyle: hintTextStyle ?? this.hintTextStyle,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    disabledBackgroundColor:
        disabledBackgroundColor ?? this.disabledBackgroundColor,
    disabledForegroundColor:
        disabledForegroundColor ?? this.disabledForegroundColor,
    stateLayerColor: stateLayerColor ?? this.stateLayerColor,
    stateLayer: stateLayer ?? this.stateLayer,
    clickableStyle: clickableStyle ?? this.clickableStyle,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCommandSearchStyle &&
          runtimeType == other.runtimeType &&
          height == other.height &&
          padding == other.padding &&
          contentGapStyle == other.contentGapStyle &&
          borderRadius == other.borderRadius &&
          leadingIconStyle == other.leadingIconStyle &&
          hintTextStyle == other.hintTextStyle &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          disabledForegroundColor == other.disabledForegroundColor &&
          stateLayerColor == other.stateLayerColor &&
          stateLayer == other.stateLayer &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    height,
    padding,
    contentGapStyle,
    borderRadius,
    leadingIconStyle,
    hintTextStyle,
    backgroundColor,
    foregroundColor,
    disabledBackgroundColor,
    disabledForegroundColor,
    stateLayerColor,
    stateLayer,
    clickableStyle,
  );
}
