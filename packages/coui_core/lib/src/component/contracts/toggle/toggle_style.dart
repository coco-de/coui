/// Per-instance style for `Toggle`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/outlined_container/outlined_container_style.dart';
import 'package:coui_core/src/component/contracts/toggle/toggle_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Toggle` (switch) should
/// render.
///
/// `CoreToggleStyle` carries chrome / dimensional overrides
/// for the track and thumb as flat fields (track and thumb are not
/// independent CoUI components, so they don't have their own
/// nested Style — they're chrome of the toggle), plus nested slots for
/// the label text, the state layer the track wears under a pointer, and
/// the focus outline drawn around the track.
///
/// **Semantic enums (`variant`, `size`) live on the widget, not
/// on this style.** They identify the toggle instance and are passed as
/// widget parameters; this style holds only chrome / dimensional /
/// nested-slot overrides on top of whichever size the widget was
/// instantiated with. Per-size design-system defaults live in
/// [defaultsBySize] — both Flutter and Web read the same table so the
/// two platforms cannot silently diverge.
///
/// ```text
/// design system default for variant + size
///   → CoreToggleTheme.style                       // 프로젝트 공통
///   → CoreToggleTheme.variantStyles[variant]      // variant 별
///   → parent component slot override
///   → widget.toggleStyle                          // 인스턴스별
/// ```
@immutable
class CoreToggleStyle implements CoreStyle<CoreToggleStyle> {
  /// Creates a [CoreToggleStyle].
  const CoreToggleStyle({
    this.trackActiveColor,
    this.trackInactiveColor,
    this.trackBorderRadius,
    this.trackWidth,
    this.trackHeight,
    this.thumbActiveColor,
    this.thumbInactiveColor,
    this.thumbSize,
    this.thumbBorderRadius,
    this.thumbShadow,
    this.thumbShadowBaseColor,
    this.thumbOffset,
    this.inactiveThumbOffset,
    this.padding,
    this.iconLabelGapStyle,
    this.colorTransitionDuration,
    this.thumbTransitionDuration,
    this.stateLayer,
    this.stateLayerActiveColor,
    this.stateLayerInactiveColor,
    this.focusOutlineStyle,
    this.clickableStyle,
    this.labelStyle,
    this.lensOutset,
    this.lensContainerStyle,
    this.lensFadeFraction,
  });

  /// Default thumb cast — a faint drop and a 1px contact ring under the
  /// thumb, in every state.
  ///
  /// The off thumb is white on a light off track ([defaultsByVariant]),
  /// which as colour alone is ~1.25:1 on CoUI's light palette. The cast is
  /// what keeps the thumb's outline readable there; the thumb's position
  /// and the on/off track colours still say the state. It is deliberately
  /// lighter than [CoreShadow.sm]'s drop, which vanishes at this size, and
  /// it is not on the shadow scale because it belongs to this thumb alone.
  /// Dark mode multiplies the alphas by [CoreShadow.darkStrength] like any
  /// other cast.
  static const List<CoreShadowLayer> defaultThumbShadow = [
    (
      offsetX: 0,
      offsetY: 1,
      blurRadius: 2,
      spreadRadius: 0,
      opacity: 0.08,
      inset: false,
    ),
    (
      offsetX: 0,
      offsetY: 0,
      blurRadius: 1,
      spreadRadius: 0,
      opacity: 0.06,
      inset: false,
    ),
  ];

  /// Theme-aware tint for the thumb cast.
  static const defaultThumbShadowBaseColor = CoreColor.token(CoreColors.shadow);

  /// Shadow layers on the moving thumb, independent of the track and lens.
  final List<CoreShadowLayer>? thumbShadow;

  /// Base tint of [thumbShadow]; layer opacity and dark strength are retained.
  final CoreColor? thumbShadowBaseColor;

  // ─── Design-system defaults ────────────────────
  // Both Flutter and Web read these constants — Flutter resolves
  // via `theme.colorScheme` / `.toValue(theme:)`, Web via the
  // `core_to_css.dart` adapter extensions.

  /// Default label slot text style — the single source for the label's
  /// colour (`onSurface`) and the role every size row starts from.
  ///
  /// `bodySmall` (13 / 400 / 150%) — a toggle's label is copy beside a
  /// control, not a control's own label: it reads at body weight and the
  /// body role's line height on every size. The per-size rows in
  /// [defaultsBySize] restate only the role (the size ladder —
  /// 13 / 14 / 15 / 15 / 15), so this default's colour is what every row
  /// inherits. Both platforms compose `defaultLabelStyle → size row →
  /// per-instance override` in that order.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default track colour transition duration.
  static const Duration defaultColorTransitionDuration = Duration(
    milliseconds: CoreDuration.instant,
  );

  /// Default thumb scale transition duration.
  static const Duration defaultThumbTransitionDuration = Duration(
    milliseconds: CoreDuration.instant,
  );

  /// Default thumb resting (inactive) X translation (logical px). 0 keeps
  /// the thumb flush with the track's leading edge — the active offset
  /// is size-specific and read from [defaultsBySize].
  static const double defaultInactiveThumbOffset = CoreSpace.space0;

  /// Default inner padding inside the track — [defaultThumbInset] on all
  /// four sides. Per-size tables ([defaultsBySize]) restate this; resolvers
  /// use it as the ultimate fallback.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    defaultThumbInset,
  );

  /// The band between the thumb and the track edge, on every side — the
  /// `2` in `thumbSize = trackHeight − 2 × 2`. A named spacing step
  /// (`space/2`), which is what the canvas binds the track padding to.
  static const double defaultThumbInset = CoreSpace.space2;

  /// Default gap style — `CoreGapStyle(size: 8)` — between the toggle
  /// track and the prefix / suffix / label slots. The whole nested
  /// [CoreGapStyle] slot is forwarded to the `Gap` widget that
  /// separates the slots. Per-instance override flows through
  /// [iconLabelGapStyle] (merged on top of this default). Per-size
  /// tables (`defaultsBySize`) override this constant; resolvers use
  /// this as the ultimate fallback.
  static const CoreGapStyle defaultIconLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default state-layer ramp — the track's own ink laid over its fill
  /// while hovered (8%) or pressed (16%).
  ///
  /// [CoreStateLayer.standard] — the ramp the `state-layer/*` semantic
  /// tokens carry, which is what the canvas paints on the track. The
  /// ramp's `focus` weight is not painted by the toggle — keyboard focus
  /// is the outline around the track ([defaultFocusOutlineStyle]), not a
  /// wash, which is what the canvas draws for its focus pose.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer.standard;

  /// Default focus outline drawn around the **track** (not the row) —
  /// a pill, because the track is one. Geometry (offset band + ring
  /// width + colours) resolves inside `FocusOutline` from its own
  /// defaults; only the corner is this component's to state.
  ///
  /// The composed `Clickable` keeps its own row-wide ring switched off
  /// (`focusOutline: false`) so the two never draw at once.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// `Clickable` — a partial with only the diverging overrides:
  ///
  /// - `disabledOpacity: 1` — the toggle paints its own disabled state
  ///   with dedicated tokens, so the Clickable's generic disabled fade
  ///   must stay off or the disabled chrome fades twice.
  ///
  /// Everything else — the press shrink included — stays null and
  /// resolves inside the Clickable's own resolver. The canvas shows the
  /// pressed pose as the 16% state layer alone ([defaultStateLayer]);
  /// the shrink is a gesture-time motion with no static picture, so the
  /// code keeps it and the canvas does not draw it.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Default reach of the transient lens past the thumb on each side —
  /// 6 across, 4 up and down.
  ///
  /// The lens exists only while the thumb travels, so it takes no room in
  /// the layout and is free to be larger than the track: 4 up and down
  /// over a thumb that sits 2 inside the track puts the capsule 2 past the
  /// track's edge, which is the spill the reference shows. Wider than tall
  /// because the reference's capsule is a pill lying along the travel, not
  /// a bigger circle.
  ///
  /// Symmetric on purpose — the lens is centred on the thumb in both
  /// directions of travel, so a left/right difference would say something
  /// about reading direction that the switch does not mean.
  ///
  /// Not spacing, though it is a [CoreEdgeInsets]: a theme density leaves
  /// it alone on both platforms. It is the thumb's own geometry — the lens
  /// is the thumb grown by this reach, centred on the thumb inside the band
  /// the resolvers pin at the standard density — so a density that moved
  /// it (6 → 4 / 8) would grow or shrink the capsule over a thumb that does
  /// not change size, and the spill past the track would come and go with
  /// it. Both resolvers read its faces as authored rather than through the
  /// inset conversion that applies a density.
  static const CoreEdgeInsets defaultLensOutset = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space6,
    vertical: CoreSpace.space4,
  );

  /// Default chrome of the transient lens — a clear pill: no fill, no
  /// stroke, no cast, no padding.
  ///
  /// Clear on purpose. Everything the lens shows comes from the material the
  /// active surface style gives a floating surface — its backdrop pass, the
  /// refraction that rides it, its sheen. Under a style that gives none, the
  /// lens draws nothing at all, which is what keeps every non-material
  /// style's transition exactly as it was.
  ///
  /// `boxShadow` states "no cast" outright rather than leaving it unset: a
  /// surface at rest elevation otherwise takes the style's injected control
  /// cast, and a lens casting a box would be a box.
  ///
  /// The corner is the lens's own — not the thumb's or the track's: the
  /// thumb keeps no default radius at all (see [thumbBorderRadius]), and the
  /// track's is a statement about the track that a caller may change without
  /// meaning the lens.
  ///
  /// A partial on purpose: the slot's `width` / `height` stay null, because
  /// the lens's size is [lensOutset]'s to state — both resolvers lay the
  /// size computed from the thumb and the outset over whatever this slot
  /// carries.
  static const CoreOutlinedContainerStyle defaultLensContainerStyle =
      CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.transparent,
        borderColor: CoreColor.transparent,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
        borderWidth: CoreStrokeWidth.stroke0,
        borderStyle: .none,
        boxShadow: CoreShadow.none,
        padding: CoreEdgeInsets.zero,
      );

  /// Default share of the thumb's travel the transient lens spends fading
  /// in, and again fading out — it is fully shown for the middle of the
  /// travel.
  ///
  /// One number for both platforms: the Flutter twin weights its opacity
  /// envelope by it and the Web twin writes its keyframe stops from it, so
  /// the two lenses appear and leave at the same moments.
  static const double defaultLensFadeFraction = 0.25;

  /// The largest [lensFadeFraction] means anything — the fade in and the
  /// fade out together take the whole travel, with no hold between them.
  ///
  /// Not a design value but the bound of the arithmetic: past half, the two
  /// fades would overlap. Both resolvers clamp the settled fraction to
  /// between `0` and this before they build the envelope from it.
  static const double maxLensFadeFraction = 0.5;

  /// Per-[CoreComponentSize] dimensional / shape / label defaults —
  /// shared single source of truth for Flutter (raw doubles + domain
  /// types) and Web (which fans them out via the Tailwind adapters in
  /// `core_to_css.dart`). Resolvers read
  /// `CoreToggleStyle.defaultsBySize[size]!` and use the entries as
  /// fallback when the per-instance `CoreToggleStyle` slot is null.
  ///
  /// Five rows, `sm`..`xl2`. There is no `xs` row: a 24×12 track with an
  /// 8px thumb travels 8px, which is not a change a hand can read as
  /// feedback. `CoreComponentSize.xs` clamps to `sm` through
  /// [sizeDefaults] rather than throwing.
  ///
  /// Every row is derived from `trackHeight` (16 / 20 / 24 / 28 / 32):
  ///   - `trackWidth  = trackHeight + 16` — the width is the height plus the
  ///     one travel every size shares, so the track grows with its thumb but
  ///     never doubles (32 / 36 / 40 / 44 / 48).
  ///   - `thumbSize   = trackHeight − 2 × [defaultThumbInset]` — a 2px
  ///     band between the thumb and the track on every side, so the thumb
  ///     reads as sitting IN the track rather than filling it.
  ///   - `thumbOffset = trackWidth − padding.horizontal − thumbSize` —
  ///     the on-state resting X, flush with the trailing padded edge the
  ///     way the off thumb is flush with the leading one at
  ///     [defaultInactiveThumbOffset] = 0. Because the width is the height
  ///     plus 16 and the thumb is the height minus 4, this is 16 on every
  ///     row: the thumb travels the same 16 at every size.
  ///   - `labelStyle` — the size ladder's role (13 / 14 / 15 / 15 / 15 at
  ///     body weight); colour comes from [defaultLabelStyle].
  static const Map<CoreComponentSize, CoreToggleStyle> defaultsBySize = {
    CoreComponentSize.sm: CoreToggleStyle(
      trackBorderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      trackWidth: CoreSize.size32, // 16 + 16
      trackHeight: CoreSize.size16,
      thumbSize: CoreSize.size12, // 16 − 4
      thumbOffset: CoreSpace.space16, // 32 − 4 (padding) − 12
      padding: CoreEdgeInsets.all(defaultThumbInset),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      labelStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
    ),
    CoreComponentSize.md: CoreToggleStyle(
      trackBorderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      trackWidth: CoreSize.size36, // 20 + 16
      trackHeight: CoreSize.size20,
      thumbSize: CoreSize.size16, // 20 − 4
      thumbOffset: CoreSpace.space16, // 36 − 4 (padding) − 16
      padding: CoreEdgeInsets.all(defaultThumbInset),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
    ),
    CoreComponentSize.lg: CoreToggleStyle(
      trackBorderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      trackWidth: CoreSize.size40, // 24 + 16
      trackHeight: CoreSize.size24,
      thumbSize: CoreSize.size20, // 24 − 4
      thumbOffset: CoreSpace.space16, // 40 − 4 (padding) − 20
      padding: CoreEdgeInsets.all(defaultThumbInset),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelStyle: CoreTextStyle.token(CoreTextStyles.bodyLarge),
    ),
    CoreComponentSize.xl: CoreToggleStyle(
      trackBorderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      trackWidth: CoreSize.size44, // 28 + 16
      trackHeight: CoreSize.size28,
      thumbSize: CoreSize.size24, // 28 − 4
      thumbOffset: CoreSpace.space16, // 44 − 4 (padding) − 24
      padding: CoreEdgeInsets.all(defaultThumbInset),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space10),
      labelStyle: CoreTextStyle.token(CoreTextStyles.bodyLarge),
    ),
    CoreComponentSize.xl2: CoreToggleStyle(
      trackBorderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      trackWidth: CoreSize.size48, // 32 + 16
      trackHeight: CoreSize.size32,
      thumbSize: CoreSize.size28, // 32 − 4
      thumbOffset: CoreSpace.space16, // 48 − 4 (padding) − 28
      padding: CoreEdgeInsets.all(defaultThumbInset),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space10),
      labelStyle: CoreTextStyle.token(CoreTextStyles.bodyLarge),
    ),
  };

  /// The smallest size the ladder draws. `CoreComponentSize.xs` has no
  /// row of its own (see [defaultsBySize]) and resolves to this one.
  static const CoreComponentSize smallestSize = CoreComponentSize.sm;

  /// The [defaultsBySize] row for [size], clamping a size below the ladder
  /// ([CoreComponentSize.xs]) up to [smallestSize].
  ///
  /// Resolvers on both platforms read the ladder through this rather than
  /// indexing the map, so a caller that still says `size: .xs` gets the
  /// smallest switch that exists instead of a null-check crash.
  static CoreToggleStyle sizeDefaults(CoreComponentSize size) =>
      defaultsBySize[size] ?? defaultsBySize[smallestSize]!;

  /// Per-variant default styles. Single source of truth shared by
  /// Flutter and Web — each platform resolves the [CoreColor] via its
  /// own extension (`.toValue()` / `scheme.resolve(...)`).
  static const Map<CoreToggleVariant, CoreToggleVariantStyle>
  defaultsByVariant = {
    CoreToggleVariant.defaultVariant: CoreToggleVariantStyle(
      activeTrack: CoreColor.token(CoreColors.primary),
      // The off track is the highest container step and the off thumb is
      // white in both modes — the familiar switch shape. On the light off
      // track white is ~1.25:1 as colour alone, below the 3:1 graphics
      // floor, by design decision: the thumb's outline is carried by
      // [defaultThumbShadow] instead, and the thumb's position and the
      // on/off track colours still say the state. On the dark off track it
      // clears 8:1 or more. The white is a fixed colour, not a scheme slot —
      // no semantic slot is white in both modes.
      inactiveTrack: CoreColor.token(CoreColors.surfaceContainerHighest),
      // The on thumb is the primary track's own foreground, `onPrimary`:
      // whatever the primary fill is, the mark that sits on it is chosen to
      // be read on it, not borrowed from the page.
      activeThumb: CoreColor.token(CoreColors.onPrimary),
      inactiveThumb: CoreColor(0xFFFFFFFF),
      // Disabled is said by the TRACK and the label. The on track drops to
      // the disabled content tone; the off track to the disabled container —
      // a lower container tone than the enabled off track
      // (`surfaceContainerHighest`), so an off toggle's enabled/disabled is
      // told apart by its track and label colours.
      //
      // The thumbs follow the enabled rule: an on thumb is its track's ink,
      // an off thumb is white. The disabled on thumb is `surface`, which the
      // disabled-content on track carries — white in light; in dark it is
      // the dark ink, as the enabled on thumb is. A fixed white there would
      // vanish on the high-contrast dark disabled-content track (~1.5:1).
      // The disabled off thumb is white in both modes: the light pose (white
      // on the disabled container, ~1.09:1 on CoUI's palette) is below the
      // graphics floor by design decision, and [defaultThumbShadow] carries
      // its outline the same way it does the enabled off thumb.
      disabledActiveTrack: CoreColor.token(CoreColors.disabledContent),
      disabledInactiveTrack: CoreColor.token(CoreColors.disabledContainer),
      disabledThumb: CoreColor.token(CoreColors.surface),
      disabledInactiveThumb: CoreColor(0xFFFFFFFF),
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
      // The ink the state layer lays over the track — the track's own
      // foreground: `surface` over the primary on track, `onSurface`
      // over the off track.
      activeStateLayer: CoreColor.token(CoreColors.surface),
      inactiveStateLayer: CoreColor.token(CoreColors.onSurface),
    ),
  };

  // ── Track chrome (flat) ──────────────────────

  /// Track fill colour when on.
  final CoreColor? trackActiveColor;

  /// Track fill colour when off.
  final CoreColor? trackInactiveColor;

  /// Track border radius override.
  final CoreBorderRadius? trackBorderRadius;

  /// Track width override (logical px).
  final double? trackWidth;

  /// Track height override (logical px).
  final double? trackHeight;

  // ── Thumb chrome (flat) ──────────────────────

  /// Thumb fill colour when on.
  final CoreColor? thumbActiveColor;

  /// Thumb fill colour when off.
  final CoreColor? thumbInactiveColor;

  /// Thumb size (width = height) override (logical px).
  final double? thumbSize;

  /// Thumb border radius override.
  ///
  /// Carries no `defaultThumbBorderRadius`, and the two platforms key
  /// different things on its absence — a constant would break both.
  /// Flutter tests `resolved.thumbBorderRadius == null` to choose
  /// `BoxShape.circle`; a `BoxDecoration` cannot hold a circle shape and a
  /// radius at once, so any non-null default permanently moves the thumb
  /// onto the `BoxShape.rectangle` branch. Web falls back to the resolved
  /// `trackBorderRadius`, so an unset thumb radius *follows the track* —
  /// including a per-instance `trackBorderRadius` override. A constant
  /// here would freeze the thumb and silently unpair it from the track.
  final CoreBorderRadius? thumbBorderRadius;

  /// Thumb travel offset when on (logical px). `null` falls back to
  /// [defaultsBySize] for the widget's size.
  final double? thumbOffset;

  /// Thumb resting (off-state) X translation (logical px). `null` falls
  /// back to [defaultInactiveThumbOffset] (0 — flush with the track's
  /// leading edge).
  final double? inactiveThumbOffset;

  /// Inner padding inside the track. `null` falls back to
  /// [defaultsBySize] for the widget's size.
  final CoreEdgeInsets? padding;

  /// Style of the `Gap` between the toggle track and the prefix / suffix /
  /// label slots. `null` defers to the per-size default in
  /// [defaultsBySize], else [defaultIconLabelGapStyle].
  final CoreGapStyle? iconLabelGapStyle;

  // ── Motion chrome (flat) ─────────────────────

  /// Track colour transition duration. `null` falls back to
  /// [defaultColorTransitionDuration].
  final Duration? colorTransitionDuration;

  /// Thumb travel transition duration. `null` falls back to
  /// [defaultThumbTransitionDuration].
  final Duration? thumbTransitionDuration;

  // ── State layer (track wash under a pointer) ─

  /// How strongly the track's own ink is laid over its fill while
  /// hovered / pressed. `null` falls back to [defaultStateLayer].
  final CoreStateLayer? stateLayer;

  /// The ink the state layer paints over the on track. `null` falls back
  /// to the variant's `activeStateLayer`.
  final CoreColor? stateLayerActiveColor;

  /// The ink the state layer paints over the off track. `null` falls back
  /// to the variant's `inactiveStateLayer`.
  final CoreColor? stateLayerInactiveColor;

  // ── Nested slots ─────────────────────────────

  /// Style of the focus outline drawn around the track. Merged on top of
  /// [defaultFocusOutlineStyle] and passed to `FocusOutline` as is.
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Style of the toggle's `Clickable` — press scale, durations, disabled
  /// opacity. Merged on top of [defaultClickableStyle] and passed to the
  /// `Clickable` as is.
  final CoreClickableStyle? clickableStyle;

  /// Label text style override — merged on top of [defaultLabelStyle]
  /// and the size row's role.
  final CoreTextStyle? labelStyle;

  // ── Transient lens (drawn only while the thumb travels) ──

  /// How far the transient lens reaches past the thumb on each side.
  /// `null` falls back to [defaultLensOutset].
  ///
  /// The lens is a clear capsule that appears over the thumb for exactly
  /// the thumb's travel ([thumbTransitionDuration]) and is absent at rest,
  /// so this never changes the switch's resting size, layout or pixels.
  /// What the capsule shows — blur, refraction, sheen — is the material
  /// the active surface style gives a floating surface; under a style that
  /// gives none, the lens draws nothing at all.
  ///
  /// Read as authored under every density, a stated value included — see
  /// [defaultLensOutset] for why this inset is geometry, not spacing.
  final CoreEdgeInsets? lensOutset;

  /// Look of the lens shown only while the thumb travels — merged on top of
  /// [defaultLensContainerStyle] and passed to the lens as is.
  ///
  /// Flutter composes `OutlinedContainer` with it; Web writes its fields
  /// inline on the lens element.
  ///
  /// The slot's `width` / `height` are not read: the lens's size is the
  /// thumb grown by [lensOutset], and both resolvers lay that size over the
  /// slot.
  final CoreOutlinedContainerStyle? lensContainerStyle;

  /// Share of the thumb's travel the lens spends fading in, and again fading
  /// out. `null` falls back to [defaultLensFadeFraction]; a value below `0`
  /// or above [maxLensFadeFraction] is clamped to that bound.
  ///
  /// `0` shows the lens at full strength for the whole travel;
  /// [maxLensFadeFraction] fades it straight in and straight out with no
  /// hold.
  final double? lensFadeFraction;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slots are merged
  /// recursively.
  @override
  CoreToggleStyle merge(CoreToggleStyle? other) {
    if (other == null) return this;
    return CoreToggleStyle(
      trackActiveColor: other.trackActiveColor ?? trackActiveColor,
      trackInactiveColor: other.trackInactiveColor ?? trackInactiveColor,
      trackBorderRadius: other.trackBorderRadius ?? trackBorderRadius,
      trackWidth: other.trackWidth ?? trackWidth,
      trackHeight: other.trackHeight ?? trackHeight,
      thumbActiveColor: other.thumbActiveColor ?? thumbActiveColor,
      thumbInactiveColor: other.thumbInactiveColor ?? thumbInactiveColor,
      thumbSize: other.thumbSize ?? thumbSize,
      thumbBorderRadius: other.thumbBorderRadius ?? thumbBorderRadius,
      thumbShadow: other.thumbShadow ?? thumbShadow,
      thumbShadowBaseColor: other.thumbShadowBaseColor ?? thumbShadowBaseColor,
      thumbOffset: other.thumbOffset ?? thumbOffset,
      inactiveThumbOffset: other.inactiveThumbOffset ?? inactiveThumbOffset,
      padding: other.padding ?? padding,
      iconLabelGapStyle: _mergeGap(
        iconLabelGapStyle,
        other.iconLabelGapStyle,
      ),
      colorTransitionDuration:
          other.colorTransitionDuration ?? colorTransitionDuration,
      thumbTransitionDuration:
          other.thumbTransitionDuration ?? thumbTransitionDuration,
      stateLayer: other.stateLayer ?? stateLayer,
      stateLayerActiveColor:
          other.stateLayerActiveColor ?? stateLayerActiveColor,
      stateLayerInactiveColor:
          other.stateLayerInactiveColor ?? stateLayerInactiveColor,
      focusOutlineStyle:
          focusOutlineStyle?.merge(other.focusOutlineStyle) ??
          other.focusOutlineStyle,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      lensOutset: other.lensOutset ?? lensOutset,
      lensContainerStyle:
          lensContainerStyle?.merge(other.lensContainerStyle) ??
          other.lensContainerStyle,
      lensFadeFraction: other.lensFadeFraction ?? lensFadeFraction,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreToggleStyle copyWith({
    CoreColor? trackActiveColor,
    CoreColor? trackInactiveColor,
    CoreBorderRadius? trackBorderRadius,
    double? trackWidth,
    double? trackHeight,
    CoreColor? thumbActiveColor,
    CoreColor? thumbInactiveColor,
    double? thumbSize,
    CoreBorderRadius? thumbBorderRadius,
    List<CoreShadowLayer>? thumbShadow,
    CoreColor? thumbShadowBaseColor,
    double? thumbOffset,
    double? inactiveThumbOffset,
    CoreEdgeInsets? padding,
    CoreGapStyle? iconLabelGapStyle,
    Duration? colorTransitionDuration,
    Duration? thumbTransitionDuration,
    CoreStateLayer? stateLayer,
    CoreColor? stateLayerActiveColor,
    CoreColor? stateLayerInactiveColor,
    CoreFocusOutlineStyle? focusOutlineStyle,
    CoreClickableStyle? clickableStyle,
    CoreTextStyle? labelStyle,
    CoreEdgeInsets? lensOutset,
    CoreOutlinedContainerStyle? lensContainerStyle,
    double? lensFadeFraction,
  }) {
    return CoreToggleStyle(
      trackActiveColor: trackActiveColor ?? this.trackActiveColor,
      trackInactiveColor: trackInactiveColor ?? this.trackInactiveColor,
      trackBorderRadius: trackBorderRadius ?? this.trackBorderRadius,
      trackWidth: trackWidth ?? this.trackWidth,
      trackHeight: trackHeight ?? this.trackHeight,
      thumbActiveColor: thumbActiveColor ?? this.thumbActiveColor,
      thumbInactiveColor: thumbInactiveColor ?? this.thumbInactiveColor,
      thumbSize: thumbSize ?? this.thumbSize,
      thumbBorderRadius: thumbBorderRadius ?? this.thumbBorderRadius,
      thumbShadow: thumbShadow ?? this.thumbShadow,
      thumbShadowBaseColor: thumbShadowBaseColor ?? this.thumbShadowBaseColor,
      thumbOffset: thumbOffset ?? this.thumbOffset,
      inactiveThumbOffset: inactiveThumbOffset ?? this.inactiveThumbOffset,
      padding: padding ?? this.padding,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
      colorTransitionDuration:
          colorTransitionDuration ?? this.colorTransitionDuration,
      thumbTransitionDuration:
          thumbTransitionDuration ?? this.thumbTransitionDuration,
      stateLayer: stateLayer ?? this.stateLayer,
      stateLayerActiveColor:
          stateLayerActiveColor ?? this.stateLayerActiveColor,
      stateLayerInactiveColor:
          stateLayerInactiveColor ?? this.stateLayerInactiveColor,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      lensOutset: lensOutset ?? this.lensOutset,
      lensContainerStyle: lensContainerStyle ?? this.lensContainerStyle,
      lensFadeFraction: lensFadeFraction ?? this.lensFadeFraction,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreToggleStyle &&
          runtimeType == other.runtimeType &&
          trackActiveColor == other.trackActiveColor &&
          trackInactiveColor == other.trackInactiveColor &&
          trackBorderRadius == other.trackBorderRadius &&
          trackWidth == other.trackWidth &&
          trackHeight == other.trackHeight &&
          thumbActiveColor == other.thumbActiveColor &&
          thumbInactiveColor == other.thumbInactiveColor &&
          thumbSize == other.thumbSize &&
          thumbBorderRadius == other.thumbBorderRadius &&
          _shadowEq(thumbShadow, other.thumbShadow) &&
          thumbShadowBaseColor == other.thumbShadowBaseColor &&
          thumbOffset == other.thumbOffset &&
          inactiveThumbOffset == other.inactiveThumbOffset &&
          padding == other.padding &&
          iconLabelGapStyle == other.iconLabelGapStyle &&
          colorTransitionDuration == other.colorTransitionDuration &&
          thumbTransitionDuration == other.thumbTransitionDuration &&
          stateLayer == other.stateLayer &&
          stateLayerActiveColor == other.stateLayerActiveColor &&
          stateLayerInactiveColor == other.stateLayerInactiveColor &&
          focusOutlineStyle == other.focusOutlineStyle &&
          clickableStyle == other.clickableStyle &&
          labelStyle == other.labelStyle &&
          lensOutset == other.lensOutset &&
          lensContainerStyle == other.lensContainerStyle &&
          lensFadeFraction == other.lensFadeFraction;

  @override
  int get hashCode => Object.hashAll([
    trackActiveColor,
    trackInactiveColor,
    trackBorderRadius,
    trackWidth,
    trackHeight,
    thumbActiveColor,
    thumbInactiveColor,
    thumbSize,
    thumbBorderRadius,
    if (thumbShadow == null) null else Object.hashAll(thumbShadow!),
    thumbShadowBaseColor,
    thumbOffset,
    inactiveThumbOffset,
    padding,
    iconLabelGapStyle,
    colorTransitionDuration,
    thumbTransitionDuration,
    stateLayer,
    stateLayerActiveColor,
    stateLayerInactiveColor,
    focusOutlineStyle,
    clickableStyle,
    labelStyle,
    lensOutset,
    lensContainerStyle,
    lensFadeFraction,
  ]);

  static bool _shadowEq(List<CoreShadowLayer>? a, List<CoreShadowLayer>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

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

/// Visual style definition for a [CoreToggleVariant].
///
/// Defines colours for: active / inactive track, active / inactive thumb,
/// the two disabled tracks, the two disabled thumbs, the disabled
/// foreground, and the ink the state layer lays over each track. All
/// values are platform-neutral ([CoreColor]); the consuming renderer
/// converts at use-site (Flutter via `scheme.resolve(...).toValue()`; Web
/// via `'bg-${color}'` / `var(--coui-*)`).
@immutable
class CoreToggleVariantStyle {
  /// Creates a toggle variant style.
  const CoreToggleVariantStyle({
    required this.activeTrack,
    required this.inactiveTrack,
    required this.activeThumb,
    required this.inactiveThumb,
    required this.disabledActiveTrack,
    required this.disabledInactiveTrack,
    required this.disabledThumb,
    required this.disabledInactiveThumb,
    required this.disabledForegroundColor,
    required this.activeStateLayer,
    required this.inactiveStateLayer,
  });

  /// Track colour when the toggle is on.
  final CoreColor activeTrack;

  /// Track colour when the toggle is off.
  final CoreColor inactiveTrack;

  /// Thumb colour when the toggle is on.
  final CoreColor activeThumb;

  /// Thumb colour when the toggle is off.
  final CoreColor inactiveThumb;

  /// Track colour when disabled and on.
  final CoreColor disabledActiveTrack;

  /// Track colour when disabled and off.
  final CoreColor disabledInactiveTrack;

  /// Thumb colour when disabled and on.
  final CoreColor disabledThumb;

  /// Thumb colour when disabled and off — its own field because the off
  /// thumb sits on [disabledInactiveTrack], a different ground from the
  /// one [disabledThumb] has to stand off.
  final CoreColor disabledInactiveThumb;

  /// Foreground (label text) colour when disabled.
  final CoreColor disabledForegroundColor;

  /// The ink the state layer paints over the on track.
  final CoreColor activeStateLayer;

  /// The ink the state layer paints over the off track.
  final CoreColor inactiveStateLayer;
}
