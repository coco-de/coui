/// Per-instance style for `TextArea`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/text_area/text_area_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_align.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:coui_core/src/typography/vertical_align.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `TextArea` should render.
///
/// `CoreTextAreaStyle` carries chrome / dimensional / cursor / resize
/// overrides as flat fields, plus nested `CoreTextStyle` references
/// for the label / placeholder / value / description / error text
/// slots — Epic #1302's "atomic-style nesting" rule. text_area is a
/// sibling component to text_field — visual patterns are similar but
/// each owns its own chrome (Epic #1696). Design tokens (`CoreRadius`,
/// `CoreSpace` …) shared at the token layer keep both components
/// visually consistent without sharing the Style class.
///
/// **Semantic enums (`variant` / `size`) live on the widget, not on
/// this style** (Epic #1302 원칙 6/7). They identify the text area
/// instance and are passed as widget parameters; this style holds
/// only chrome / dimensional / nested-slot overrides on top of
/// whichever size the widget was instantiated with.
///
/// ```text
/// design system default for variant
///   → CoreTextAreaTheme.style                       // 프로젝트 공통
///   → CoreTextAreaTheme.variantStyles[variant]      // variant 별
///   → parent component slot override
///   → widget.textAreaStyle                          // 인스턴스별
/// ```
@immutable
class CoreTextAreaStyle implements CoreStyle<CoreTextAreaStyle> {
  /// Creates a [CoreTextAreaStyle].
  const CoreTextAreaStyle({
    this.backgroundColor,
    this.borderColor,
    this.focusBorderColor,
    this.hoverBorderColor,
    this.errorBorderColor,
    this.borderWidth,
    this.activeBorderWidth,
    this.borderRadius,
    this.initialHeight,
    this.initialWidth,
    this.minHeight,
    this.minWidth,
    this.maxHeight,
    this.maxWidth,
    this.padding,
    this.labelGapStyle,
    this.descriptionGapStyle,
    this.footerGapStyle,
    this.counterGapStyle,
    this.rowSpacing,
    this.dragHandlePadding,
    this.dragHandleOffset,
    this.dragHandleSize,
    this.iconStyle,
    this.transitionDuration,
    this.textAlign,
    this.textAlignVertical,
    this.cursorColor,
    this.cursorWidth,
    this.cursorRadius,
    this.focusOutlineStyle,
    this.baseTextStyle,
    this.labelStyle,
    this.placeholderStyle,
    this.valueStyle,
    this.descriptionStyle,
    this.counterStyle,
    this.errorStyle,
    this.labelDisabledColor,
    this.helperTextColor,
    this.affixColor,
    this.errorTextColor,
    this.requiredMarkColor,
    this.dragHandleColor,
    this.selectionColor,
    this.backgroundCursorColor,
  });

  // ─── Design-system defaults ────────────────────────────

  /// Default initial textarea height (logical px).
  static const double defaultInitialHeight = _kResizeBaseline;

  /// Default initial textarea width — unbounded, i.e. fill the available
  /// width. Flutter reads the sentinel as a `double.infinity` constraint;
  /// Web drops the inline `width` for it and lets the element fill.
  static const double defaultInitialWidth = double.infinity;

  /// Default minimum height constraint when resizable (logical px).
  static const double defaultMinHeight = _kResizeBaseline;

  /// Default minimum width constraint when resizable (logical px).
  static const double defaultMinWidth = _kResizeBaseline;

  /// Default maximum height constraint — unbounded, the same sentinel
  /// [defaultInitialWidth] uses. Both platforms already treated the
  /// absent value this way: Flutter clamped the drag against
  /// `double.infinity`, and Web's `_remOrNull` drops a non-finite
  /// extent exactly as it drops `null`, so no `max-height` is emitted.
  static const double defaultMaxHeight = double.infinity;

  /// Default maximum width constraint — unbounded, as above. The
  /// resize drag is bounded only by whatever the caller pins here.
  static const double defaultMaxWidth = double.infinity;

  /// Default cursor width (logical px).
  static const double defaultCursorWidth = 2;

  /// Default border width — the resting boundary, which takes its place in
  /// the layout.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default active-boundary width (1) — the boundary of a focused area
  /// and of one that holds an error, the same width as the resting one
  /// (#5747). Only a part beyond [borderWidth] is ever added, painted over
  /// the box without taking layout, so a caller who states a wider one
  /// still keeps the content in place. Mirrors
  /// `CoreTextFieldStyle.defaultActiveBorderWidth`.
  static const double defaultActiveBorderWidth = CoreStrokeWidth.stroke1;

  /// Default cursor corner radius — rounded bar.
  static const CoreBorderRadius defaultCursorRadius = CoreBorderRadius.all(
    defaultCursorWidth,
  );

  /// Default 1-off spacer slot below the label, above the field —
  /// flows through `Gap` (raw forward, no parent-side scaling). 6, the gap
  /// `CoreTextFieldStyle.defaultLabelPadding` states under its label.
  static const CoreGapStyle defaultLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
  );

  /// Default 1-off spacer slot above the description / error helper
  /// text — flows through `Gap` (raw forward). 6, the gap
  /// `CoreTextFieldStyle.defaultDescriptionPadding` states above its helper.
  static const CoreGapStyle defaultDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
  );

  /// Default 1-off spacer slot between the text row and the footer —
  /// flows through `Gap` (raw forward). 12, twice the label gap, so the
  /// actions read as their own line rather than as more text.
  static const CoreGapStyle defaultFooterGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default 1-off spacer slot between the helper line and the character
  /// count at its end (#5747) — 12, so a long description wraps before it
  /// reaches the count instead of running into it.
  static const CoreGapStyle defaultCounterGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default spacing between the prefix / input / suffix row children.
  static const double defaultRowSpacing = CoreSpace.space8;

  /// Default padding inside the resize drag-handle hit area.
  static const CoreEdgeInsets defaultDragHandlePadding = CoreEdgeInsets.all(
    CoreSpace.space4,
  );

  /// Default offset (logical px) of the resize drag handle from the
  /// bottom-right corner. Negative pulls inward.
  static const double defaultDragHandleOffset = -1;

  /// Default size (logical px) of the square resize drag handle hit
  /// area.
  static const double defaultDragHandleSize = 16;

  /// Default helper-text style applied to the description / error helper
  /// slots (both render the same `bodyXs` role — 12 / 400 / 1.5, the role
  /// `CoreTextFieldStyle.defaultDescriptionStyle` states, so a multi-line
  /// field and a single-line one carry their helper text alike).
  ///
  /// Named to mirror the [descriptionStyle] override field (1:1:1:1);
  /// the error slot reuses this same helper-text default and layers its
  /// own [errorStyle] override on top.
  static const CoreTextStyle defaultDescriptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
  );

  /// Default character-count style (#5747) — the helper role in the helper
  /// colour, so the count reads as part of the helper line it ends. The size
  /// row's helper role, when it states one, lands on top of this.
  static const CoreTextStyle defaultCounterStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
    color: CoreColor.token(
      CoreColors.onSurfaceSubtle,
      fallbacks: [CoreColors.onSurfaceVariant, CoreColors.onSurface],
    ),
  );

  /// Default helper text colour (the description `<p>` under the area) —
  /// `onSurfaceSubtle`, the third text tier, one step below the label's
  /// `onSurfaceVariant`; `onSurfaceVariant`, then `onSurface`, are the
  /// fallbacks when the subtle token is unset. The helper sits on the
  /// page, never on the area's own fill. Single source for the Web
  /// resolver's `text-*` colour class and the Flutter resolver's
  /// description colour so neither reaches `cs.onSurfaceSubtle` directly.
  /// Same value as `CoreTextFieldStyle.defaultDescriptionColor`.
  static const CoreColor defaultHelperTextColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
    fallbacks: [CoreColors.onSurfaceVariant, CoreColors.onSurface],
  );

  /// Default prefix / suffix affix colour (`onSurfaceSubtle`) — the
  /// leading / trailing icons and any affix text. They annotate the value
  /// rather than carry it, so they sit one tier below the label. Same
  /// value, and same state-independence, as
  /// `CoreTextFieldStyle.defaultAffixColor`: the glyph keeps its colour
  /// when the area is disabled, the value text is what says "off". Read
  /// by both resolvers — Flutter paints the affix `IconTheme` with it,
  /// Web puts the matching `text-*` class on the affix slot.
  static const CoreColor defaultAffixColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default disabled-label colour (`onSurfaceSubtle`) — one text tier
  /// below the enabled label's `onSurfaceVariant` (the
  /// `CoreFormLabelStyle` default), and a text tier rather than the
  /// graphics-only `disabledContent`. Forwarded to the composed
  /// `FormLabel` as its `disabledColor`, the way
  /// `CoreTextFieldStyle.defaultLabelDisabledColor` is: a disabled label
  /// held at the enabled token would be indistinguishable from an enabled
  /// one, and a label nobody can read says the area is broken rather than
  /// off.
  static const CoreColor defaultLabelDisabledColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default error helper-text colour (error message `<p>`).
  static const CoreColor defaultErrorTextColor = CoreColor.token(
    CoreColors.error,
  );

  /// Default required-asterisk colour.
  static const CoreColor defaultRequiredMarkColor = CoreColor.token(
    CoreColors.error,
  );

  /// Default caret (cursor) colour token — the design-system primary.
  static const CoreColor defaultCursorColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default text-selection tint base colour (`primary`). Both resolvers
  /// apply a low (`CoreOpacity.opacity20`) alpha on top before painting
  /// the selection highlight — Flutter via `Color.withValues(alpha:)`,
  /// Web via `CoreColor.scaleAlpha` emitted as a `selection:bg-*`
  /// Tailwind pseudo-element class (`::selection`).
  static const CoreColor defaultSelectionColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default idle (floating) cursor colour for `EditableText` (`outline`).
  /// Flutter-only paint concern (the iOS-style floating-cursor drag
  /// gesture, native OS/browser chrome the CSS cascade cannot reach) —
  /// Web has no equivalent slot.
  static const CoreColor defaultBackgroundCursorColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default resize drag-handle glyph colour.
  static const CoreColor defaultDragHandleColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// A size-independent field corner (8), retired: the design-system
  /// corner is the size row's [borderRadius]
  /// (`defaultsBySize[size].borderRadius`), the value
  /// `CoreTextFieldStyle.defaultsBySize` states for the same size.
  @Deprecated(
    'Per-size now: read defaultsBySize[size].borderRadius (through '
    'resolveSizeRow) instead (since 0.156) — the area takes the corner '
    'of the TextField of the same size, so one value cannot answer for '
    'every size.',
  )
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default focus outline style — the base the per-instance
  /// [focusOutlineStyle] override merges onto.
  ///
  /// Stating `align` + `borderWidth` here (mirroring
  /// `CoreTextFieldStyle.defaultFocusOutlineStyle`) pins the ring's
  /// geometry to this component rather than leaving it to
  /// `CoreFocusOutlineStyle`'s own defaults, so a resolver that merges
  /// onto this base takes the text area's geometry over an app-wide
  /// `CoreFocusOutlineTheme`. The values are the same numbers either
  /// way; what differs is which layer wins.
  ///
  /// No `borderRadius`: the ring's corner is the host's, injected by both
  /// resolvers from the area's resolved corner (which is per size), as
  /// `CoreTextFieldStyle.defaultFocusOutlineStyle` leaves it too.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(
        align: CoreFocusOutlineStyle.defaultAlign,
        borderColor: CoreColor.token(CoreColors.primary),
        borderWidth: CoreFocusOutlineStyle.defaultBorderWidth,
      );

  /// Default colour-transition duration for border / focus states.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default horizontal text alignment.
  static const CoreTextAlign defaultTextAlign = .start;

  /// Default vertical text alignment inside the resizable box. Multi-
  /// line content starts at the top edge — matches HTML `<textarea>`
  /// native top-align and Flutter `TextAlignVertical.top`.
  static const CoreVerticalAlign defaultTextAlignVertical = .top;

  /// Idle (non-error) variant chrome, applied when
  /// `widget.errorText == null`.
  ///
  /// Named `...Variant` rather than `...Style` to mirror
  /// `CoreTextFieldStyle.defaultNormalVariant` — the two components carry
  /// the same concept and now spell it the same way.
  static const CoreTextAreaVariantStyle defaultNormalVariant =
      CoreTextAreaVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.surface),
        foregroundColor: CoreColor.token(CoreColors.onSurface),
        borderColor: CoreColor.token(CoreColors.outlineVariant),
        placeholderColor: CoreColor.token(CoreColors.placeholder),
        focusRingColor: CoreColor.token(CoreColors.primary),
        // Mirrors `CoreTextFieldStyle.defaultNormalVariant` — the border
        // rests on `outlineVariant` and steps to `outline` under the
        // pointer (#5747).
        hoverBorderColor: CoreColor.token(CoreColors.outline),
        // Was `surface` — the same fill the enabled area uses, so
        // disabled said nothing with its background. Mirrors
        // `text_field_style.dart`'s identical fix.
        disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
        // #3469 — dedicated disabled tokens, not the enabled colours plus
        // an `opacity-50` multiplier (mirrors `text_field_style.dart`'s
        // identical fix — same shape, same bug).
        disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
        disabledBorderColor: CoreColor.token(CoreColors.disabledOutline),
      );

  /// Variant chrome applied when `widget.errorText != null` and the area
  /// is enabled ([CoreTextAreaVariant.of] — `disabled > error`). Border /
  /// focus ring switch to the `error` token; the rest mirrors
  /// [defaultNormalVariant].
  ///
  /// Named `...Variant` rather than `...Style` because the `default<Field>`
  /// convention is 1:1 — `defaultErrorStyle` reads as the default *for*
  /// the [errorStyle] field, which is the error message's
  /// [CoreTextStyle], an unrelated concept. Mirrors
  /// `CoreTextFieldStyle.defaultErrorVariant`.
  static const CoreTextAreaVariantStyle defaultErrorVariant =
      CoreTextAreaVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.surface),
        foregroundColor: CoreColor.token(CoreColors.onSurface),
        borderColor: CoreColor.token(CoreColors.error),
        placeholderColor: CoreColor.token(CoreColors.placeholder),
        focusRingColor: CoreColor.token(CoreColors.error),
        // Error outranks hover — the pointer does not soften a validation
        // border (error/hover paints what error/enabled does). Mirrors
        // `CoreTextFieldStyle.defaultErrorVariant`.
        hoverBorderColor: CoreColor.token(CoreColors.error),
        disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
        disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
        disabledBorderColor: CoreColor.token(CoreColors.disabledOutline),
      );

  /// Variant chrome table keyed by the `hasError` flag (`false` →
  /// [defaultNormalVariant], `true` → [defaultErrorVariant]).
  ///
  /// Mirrors the `defaultsBySize` holder pattern so resolvers can pick
  /// the state-dependent chrome with a single subscript instead of a
  /// ternary over the two named constants.
  static const Map<CoreTextAreaVariant, CoreTextAreaVariantStyle>
  defaultsByVariant = {
    CoreTextAreaVariant.defaultVariant: defaultNormalVariant,
    CoreTextAreaVariant.error: defaultErrorVariant,
    CoreTextAreaVariant.filled: defaultFilledVariant,
  };

  /// The filled variant (#5747) — mirrors
  /// `CoreTextFieldStyle.defaultFilledVariant`: a tinted fill instead of a
  /// drawn edge, the resting edge in the fill's own tone, hover stepping
  /// the fill one tone up.
  static const CoreTextAreaVariantStyle defaultFilledVariant =
      CoreTextAreaVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        foregroundColor: CoreColor.token(CoreColors.onSurface),
        borderColor: CoreColor.token(CoreColors.surfaceContainer),
        hoverBorderColor: CoreColor.token(CoreColors.surfaceContainerHigh),
        hoverBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
        placeholderColor: CoreColor.token(CoreColors.placeholder),
        focusRingColor: CoreColor.token(CoreColors.primary),
        disabledBackgroundColor: CoreColor.token(
          CoreColors.surfaceContainerLow,
        ),
        disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
        disabledBorderColor: CoreColor.token(CoreColors.surfaceContainerLow),
      );

  /// Per-size dimensional defaults — value type is `CoreTextAreaStyle`
  /// itself (no separate typedef record holder). Extended to the full
  /// six-tier `CoreComponentSize` ladder (2026-09-11 재검토, "다른
  /// 컴포넌트와 통일") — `xl2` was the one decided gap
  /// (`resolveSizeRow`'s doc comment previously named text_area
  /// alongside `badge` as stating no `xl2`; only `badge` still does,
  /// per its own open epic-k axis-6 decision). `xl2`'s padding restates
  /// `CoreTextFieldStyle.defaultsBySize[.xl2]`'s numbers verbatim — the
  /// xs→xl cadence the two components already share continues
  /// identically past `xl` (the horizontal step is `space16→space20`,
  /// matching the field's own judgment call there).
  ///
  /// The value text is the field's own role at the same size: `bodyMedium`
  /// (14 / 400) on `xs`…`lg`, `bodyLarge` (15 / 400) on `xl` / `xl2`. The
  /// role is used as it is, at its own 150% (21 · 22.5 px a line) — the
  /// same line box a single-line field gives its value. Icons follow the shared
  /// control icon ladder 12 · 14 · 16 · 18 · 20 · 24 (`xs`…`xl2`), the same
  /// numbers the field's rows state.
  ///
  /// `borderRadius` is the TextField's for the same size — 6 · 8 · 10 ·
  /// 12 · 14 · 16 — even though the area's height is set by its rows,
  /// not by `CoreControlSize`: the area sits in the same form column as
  /// the field and takes the field's corner at the same size step (디자이너
  /// 결정 2026-10-08). A Core test pins the two rows equal.
  ///
  /// **`xs` is retiring on this ladder (since 0.141)** — same reasoning
  /// as `CoreTextFieldStyle.defaultsBySize`'s `xs` entry (a multi-line
  /// text control's minimum useful height is governed by
  /// `minRows`/line-box math, not by a 24px single-line rung; no system
  /// surveyed for the "Form 계열 정본" decision puts a text-input rung
  /// there). The entry stays live — callers on `xs` keep rendering, and a
  /// run with asserts on logs the notice once — until it is removed, in
  /// coui_core 0.153 at the earliest (`CoreTextAreaContract.retiringSizes`);
  /// from then `xs` renders the `sm` row through `resolveSizeRow`. There
  /// are no call sites in this repo outside tests, so migration is "use
  /// `sm`" whenever one appears.
  /// `initialHeight` (#5747) is four lines of the row's value role plus
  /// the row's padding on both edges — the box an area opens at when the
  /// caller states neither `rows` nor a height: 21-px lines (`bodyMedium`
  /// 14 × 1.5) on `xs`…`lg`, 22.5-px lines (`bodyLarge` 15 × 1.5) on `xl` /
  /// `xl2`, so `md` is 4 × 21 + 2 × 12 = 108. The padding is the same on
  /// all four edges — a multi-line field whose top inset is narrower than
  /// its side inset reads as text pressed against the edge.
  static const Map<CoreComponentSize, CoreTextAreaStyle> defaultsBySize = {
    CoreComponentSize.xs: CoreTextAreaStyle(
      initialHeight: 100,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      padding: CoreEdgeInsets.all(CoreSpace.space8),
      iconStyle: CoreIconStyle(size: CoreIconSize.size12),
      baseTextStyle: _kBodyMedium,
    ),
    CoreComponentSize.sm: CoreTextAreaStyle(
      initialHeight: 104,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      padding: CoreEdgeInsets.all(CoreSpace.space10),
      iconStyle: CoreIconStyle(size: CoreIconSize.size14),
      baseTextStyle: _kBodyMedium,
    ),
    CoreComponentSize.md: CoreTextAreaStyle(
      initialHeight: 108,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      padding: CoreEdgeInsets.all(CoreSpace.space12),
      iconStyle: CoreIconStyle(size: CoreIconSize.size16),
      baseTextStyle: _kBodyMedium,
    ),
    CoreComponentSize.lg: CoreTextAreaStyle(
      initialHeight: 112,
      labelGapStyle: _kLargeHelperGap,
      descriptionGapStyle: _kLargeHelperGap,
      descriptionStyle: _kBodySmall,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      padding: CoreEdgeInsets.all(CoreSpace.space14),
      iconStyle: CoreIconStyle(size: CoreIconSize.size18),
      baseTextStyle: _kBodyMedium,
    ),
    CoreComponentSize.xl: CoreTextAreaStyle(
      initialHeight: 122,
      labelGapStyle: _kLargeHelperGap,
      descriptionGapStyle: _kLargeHelperGap,
      descriptionStyle: _kBodySmall,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
      padding: CoreEdgeInsets.all(CoreSpace.space16),
      iconStyle: CoreIconStyle(size: CoreIconSize.size20),
      baseTextStyle: _kBodyLarge,
    ),
    CoreComponentSize.xl2: CoreTextAreaStyle(
      initialHeight: 130,
      labelGapStyle: _kLargeHelperGap,
      descriptionGapStyle: _kLargeHelperGap,
      descriptionStyle: _kBodySmall,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      padding: CoreEdgeInsets.all(CoreSpace.space20),
      iconStyle: CoreIconStyle(size: CoreIconSize.size24),
      baseTextStyle: _kBodyLarge,
    ),
  };

  // ── Chrome (flat) ──────────────────────────────────────

  /// Background fill colour override.
  final CoreColor? backgroundColor;

  /// Border stroke colour override (idle state).
  final CoreColor? borderColor;

  /// Border stroke colour when focused.
  final CoreColor? focusBorderColor;

  /// Border stroke colour while the pointer is over the field. `null` →
  /// the variant's own `hoverBorderColor` (`on-surface` on the ordinary
  /// area, `error` on the error one), else the resting `borderColor` for
  /// a variant that states none.
  final CoreColor? hoverBorderColor;

  /// Border stroke colour when in error state.
  final CoreColor? errorBorderColor;

  /// Border stroke width override (logical px, pre-scaling) — the resting
  /// boundary, which stays in the layout. `null` → [defaultBorderWidth].
  final double? borderWidth;

  /// Width of the active boundary (logical px, pre-scaling) — a focused
  /// area, or one wearing the error variant while enabled (`disabled >
  /// error`). `null` → [defaultActiveBorderWidth].
  ///
  /// The resting boundary ([borderWidth]) stays where it is and only the
  /// part of this width beyond it is added, over the box and outside the
  /// layout: a wider boundary never moves the text or the area's own height.
  /// A width at or below [borderWidth] adds nothing, so a caller that states
  /// only a thicker [borderWidth] is not thinned on focus. Same name, same
  /// reading and same default as `CoreTextFieldStyle.activeBorderWidth`.
  final double? activeBorderWidth;

  /// Border radius override (pre-scaling). `null` → the size row's corner
  /// (`defaultsBySize[size].borderRadius`, the TextField's for that size).
  final CoreBorderRadius? borderRadius;

  // ── Dimensions ─────────────────────────────────────────

  /// Initial textarea height (logical px). `null` defers to
  /// [defaultInitialHeight].
  final double? initialHeight;

  /// Initial textarea width (logical px). `null` defers to
  /// [defaultInitialWidth] — i.e. fill the available width.
  final double? initialWidth;

  /// Minimum height constraint when resizable (logical px). `null`
  /// defers to [defaultMinHeight].
  final double? minHeight;

  /// Minimum width constraint when resizable (logical px). `null`
  /// defers to [defaultMinWidth].
  final double? minWidth;

  /// Maximum height constraint (logical px). `null` defers to
  /// [defaultMaxHeight] — i.e. unbounded.
  final double? maxHeight;

  /// Maximum width constraint (logical px). `null` defers to
  /// [defaultMaxWidth] — i.e. unbounded.
  final double? maxWidth;

  /// Padding override (logical px).
  final CoreEdgeInsets? padding;

  /// Space between the label and the field. Laid over
  /// [defaultLabelGapStyle] (`lg` and up widen it, see [defaultsBySize])
  /// and passed as is to `Gap(gapStyle:)`, which applies scaling.
  final CoreGapStyle? labelGapStyle;

  /// Space between the field and the description / error text below it.
  /// Laid over [defaultDescriptionGapStyle] (`lg` and up widen it, see
  /// [defaultsBySize]) and passed as is to `Gap(gapStyle:)`, which applies
  /// scaling.
  final CoreGapStyle? descriptionGapStyle;

  /// Space between the text row and the footer, inside the box; read only
  /// when the area has a footer. Laid over [defaultFooterGapStyle] and
  /// passed as is to `Gap(gapStyle:)`, which applies scaling.
  final CoreGapStyle? footerGapStyle;

  /// 1-off spacer slot between the helper line (sibling 1) and the
  /// character count (sibling 2). Forwarded raw to `Gap(gapStyle:)`. Read
  /// only when the area shows a counter.
  final CoreGapStyle? counterGapStyle;

  /// Spacing between the prefix / input / suffix row children (mirrors
  /// Flutter `Row.spacing`).
  final double? rowSpacing;

  /// Padding inside the resize drag-handle hit area.
  final CoreEdgeInsets? dragHandlePadding;

  /// Offset of the resize drag handle from the bottom-right corner.
  final double? dragHandleOffset;

  /// Size of the square resize drag-handle hit area.
  final double? dragHandleSize;

  /// Icon style shared by the leading / trailing icons (prefix / suffix),
  /// passed as is to `Icon`, which applies scaling. `null` uses the size
  /// row's icon style, `CoreTextAreaStyle.defaultsBySize[size]!.iconStyle!`.
  final CoreIconStyle? iconStyle;

  /// Colour-transition duration override for border / focus states.
  final Duration? transitionDuration;

  /// Horizontal text alignment override.
  final CoreTextAlign? textAlign;

  /// Vertical text alignment override.
  final CoreVerticalAlign? textAlignVertical;

  // ── Cursor ─────────────────────────────────────────────

  /// Cursor colour override.
  final CoreColor? cursorColor;

  /// Cursor width override (logical px, pre-scaling).
  final double? cursorWidth;

  /// Disabled-state label colour override, forwarded to the composed
  /// `FormLabel` as its `disabledColor`.
  /// `null` → [defaultLabelDisabledColor].
  final CoreColor? labelDisabledColor;

  /// Helper text colour override. `null` → [defaultHelperTextColor].
  final CoreColor? helperTextColor;

  /// Prefix / suffix affix colour override — the glyphs and any affix
  /// text, in every state. `null` → [defaultAffixColor].
  final CoreColor? affixColor;

  /// Error text colour override. `null` → [defaultErrorTextColor].
  final CoreColor? errorTextColor;

  /// Required-mark (`*`) colour override.
  /// `null` → [defaultRequiredMarkColor].
  final CoreColor? requiredMarkColor;

  /// Resize drag-handle glyph colour override.
  /// `null` → [defaultDragHandleColor].
  final CoreColor? dragHandleColor;

  /// Text-selection tint colour override. `null` → [defaultSelectionColor].
  final CoreColor? selectionColor;

  /// Background-cursor (composition/IME) colour override.
  /// `null` → [defaultBackgroundCursorColor].
  final CoreColor? backgroundCursorColor;

  /// Cursor corner radius override.
  final CoreBorderRadius? cursorRadius;

  // ── Focus outline ──────────────────────────────────────

  /// Focus ring of the text area — ring colour, radius, width, offset and
  /// gap colour. `null`, or any field left unset, uses
  /// [defaultFocusOutlineStyle]. A `borderColor` set here wins over
  /// [focusBorderColor] and the variant's focus-ring tone; a `borderRadius`
  /// set here wins over the area's own [borderRadius].
  final CoreFocusOutlineStyle? focusOutlineStyle;

  // ── Slot Styles (nested) ───────────────────────────────

  /// Base text style applied to the editable text content.
  final CoreTextStyle? baseTextStyle;

  /// Label text style override — forwarded into the composed `FormLabel`.
  ///
  /// Deliberately has no `default*`: `TextArea` does not own the label's
  /// role, `CoreFormLabelStyle.defaultsBySize` does (the 13px rung on
  /// `xs`/`sm`/`md`, the 14px rung on `lg` and up). A constant here can
  /// only name ONE of those rungs, so it would restate one role for
  /// every size — which is what the Web resolver read while the Flutter
  /// twin derived a body role from its per-size base, rendering the same
  /// label at three different roles across Flutter, Web and the canvas.
  /// The absence is the design: the role stays with the child, and this
  /// slot carries only what a caller states per instance.
  final CoreTextStyle? labelStyle;

  /// Placeholder text style override.
  ///
  /// No `default*`, deliberately. The placeholder's baseline is already
  /// decided in two other places and this slot only deviates from it:
  /// the metrics come from the per-size `baseTextStyle`
  /// (`baseRole.merge(merged.placeholderStyle)` on Flutter) and the
  /// colour comes from the variant table
  /// (`CoreTextAreaVariantStyle.placeholderColor`). Web reaches the
  /// table through a token test —
  /// `placeholderStyle?.color?.token != null ? … : '${vs.placeholderColor}'`
  /// — because `::placeholder` only accepts a class. A default carrying
  /// a colour token makes that test true for every text area, and the
  /// variant table's placeholder colour becomes unreachable; a default
  /// carrying no token would satisfy the guard while saying nothing.
  final CoreTextStyle? placeholderStyle;

  /// Selected/typed value text style override.
  ///
  /// No `default*`, deliberately. The editable role is emitted as a
  /// className by `emitTypography`, and this slot is the inline overlay
  /// on top of it — Web spreads it null-aware
  /// (`...?valueStyle?.toInlineCss()`), so an unset slot emits no inline
  /// CSS at all. `web-specifics.md` is explicit that the inline half
  /// carries *explicitly overridden* properties only; a default here
  /// would overlay every text area with inline declarations that outrank
  /// the role class by specificity, which is the one thing the role
  /// class exists to avoid.
  final CoreTextStyle? valueStyle;

  /// Description / helper text style override.
  final CoreTextStyle? descriptionStyle;

  /// Character-count text style override (#5747) — the `n / max` line at
  /// the helper row's end while `showCounter` is on. Merges onto
  /// [defaultCounterStyle].
  final CoreTextStyle? counterStyle;

  /// Text style of the error message — the helper text under the box. The
  /// box's own error look (border, focus ring) comes from
  /// [defaultErrorVariant], not from here.
  ///
  /// No `default*` of its own — both resolvers merge this override onto
  /// [defaultDescriptionStyle], the same size-invariant `bodyXs` base
  /// [descriptionStyle] merges onto (2026-09-11 재검토: Flutter used to
  /// merge onto the per-size `baseTextStyle` instead, a cross-platform
  /// divergence rather than a canvas-confirmed per-size ladder — fixed
  /// to match Web).
  final CoreTextStyle? errorStyle;

  // ─── Shared default building blocks ────────────────────
  // Class members rather than library-level constants so every default
  // that names them stays followable from the class alone: the Figma
  // exporter resolves a bare reference inside a default against *this
  // class's* static members, so a library-level `_kX` left
  // [defaultInitialHeight] / [defaultMinHeight] / [defaultMinWidth] and
  // the per-size `baseTextStyle` entries unreadable — the values were
  // correct and simply never reached the canvas.

  /// `bodyMedium` role (14 / 400) used by the xs…lg per-size base text style.
  /// `bodySmall` (13px) — the helper role on the `lg` rung and above
  /// (#5747), the same step `CoreTextFieldStyle.defaultsBySize` takes.
  static const CoreTextStyle _kBodySmall = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
  );

  /// Label → area and area → helper gap on the `lg` rung and above (#5747).
  static const CoreGapStyle _kLargeHelperGap = CoreGapStyle(
    size: CoreSpace.space8,
  );

  static const CoreTextStyle _kBodyMedium = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
  );

  /// `bodyLarge` role (15 / 400) used by the xl / xl2 per-size base text
  /// style.
  static const CoreTextStyle _kBodyLarge = CoreTextStyle.token(
    CoreTextStyles.bodyLarge,
  );

  /// Shared sentinel for the resizable text-area's initial / min height /
  /// min width — all three start at the same 100-logical-pixel baseline.
  static const double _kResizeBaseline = 100;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested text styles are
  /// merged recursively.
  @override
  CoreTextAreaStyle merge(CoreTextAreaStyle? other) {
    if (other == null) return this;
    return CoreTextAreaStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      focusBorderColor: other.focusBorderColor ?? focusBorderColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      errorBorderColor: other.errorBorderColor ?? errorBorderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      activeBorderWidth: other.activeBorderWidth ?? activeBorderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      initialHeight: other.initialHeight ?? initialHeight,
      initialWidth: other.initialWidth ?? initialWidth,
      minHeight: other.minHeight ?? minHeight,
      minWidth: other.minWidth ?? minWidth,
      maxHeight: other.maxHeight ?? maxHeight,
      maxWidth: other.maxWidth ?? maxWidth,
      padding: other.padding ?? padding,
      labelGapStyle: _mergeGap(labelGapStyle, other.labelGapStyle),
      descriptionGapStyle: _mergeGap(
        descriptionGapStyle,
        other.descriptionGapStyle,
      ),
      footerGapStyle: _mergeGap(footerGapStyle, other.footerGapStyle),
      counterGapStyle: _mergeGap(counterGapStyle, other.counterGapStyle),
      rowSpacing: other.rowSpacing ?? rowSpacing,
      dragHandlePadding: other.dragHandlePadding ?? dragHandlePadding,
      dragHandleOffset: other.dragHandleOffset ?? dragHandleOffset,
      dragHandleSize: other.dragHandleSize ?? dragHandleSize,
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      transitionDuration: other.transitionDuration ?? transitionDuration,
      textAlign: other.textAlign ?? textAlign,
      textAlignVertical: other.textAlignVertical ?? textAlignVertical,
      cursorColor: other.cursorColor ?? cursorColor,
      cursorWidth: other.cursorWidth ?? cursorWidth,
      cursorRadius: other.cursorRadius ?? cursorRadius,
      focusOutlineStyle: other.focusOutlineStyle ?? focusOutlineStyle,
      baseTextStyle: _mergeText(baseTextStyle, other.baseTextStyle),
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      placeholderStyle: _mergeText(placeholderStyle, other.placeholderStyle),
      valueStyle: _mergeText(valueStyle, other.valueStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      counterStyle: _mergeText(counterStyle, other.counterStyle),
      errorStyle: _mergeText(errorStyle, other.errorStyle),
      labelDisabledColor: other.labelDisabledColor ?? labelDisabledColor,
      helperTextColor: other.helperTextColor ?? helperTextColor,
      affixColor: other.affixColor ?? affixColor,
      errorTextColor: other.errorTextColor ?? errorTextColor,
      requiredMarkColor: other.requiredMarkColor ?? requiredMarkColor,
      dragHandleColor: other.dragHandleColor ?? dragHandleColor,
      selectionColor: other.selectionColor ?? selectionColor,
      backgroundCursorColor:
          other.backgroundCursorColor ?? backgroundCursorColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTextAreaStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreColor? focusBorderColor,
    CoreColor? hoverBorderColor,
    CoreColor? errorBorderColor,
    double? borderWidth,
    double? activeBorderWidth,
    CoreBorderRadius? borderRadius,
    double? initialHeight,
    double? initialWidth,
    double? minHeight,
    double? minWidth,
    double? maxHeight,
    double? maxWidth,
    CoreEdgeInsets? padding,
    CoreGapStyle? labelGapStyle,
    CoreGapStyle? descriptionGapStyle,
    CoreGapStyle? footerGapStyle,
    CoreGapStyle? counterGapStyle,
    double? rowSpacing,
    CoreEdgeInsets? dragHandlePadding,
    double? dragHandleOffset,
    double? dragHandleSize,
    CoreIconStyle? iconStyle,
    Duration? transitionDuration,
    CoreTextAlign? textAlign,
    CoreVerticalAlign? textAlignVertical,
    CoreColor? cursorColor,
    double? cursorWidth,
    CoreBorderRadius? cursorRadius,
    CoreColor? labelDisabledColor,
    CoreColor? helperTextColor,
    CoreColor? affixColor,
    CoreColor? errorTextColor,
    CoreColor? requiredMarkColor,
    CoreColor? dragHandleColor,
    CoreColor? selectionColor,
    CoreColor? backgroundCursorColor,
    CoreFocusOutlineStyle? focusOutlineStyle,
    CoreTextStyle? baseTextStyle,
    CoreTextStyle? labelStyle,
    CoreTextStyle? placeholderStyle,
    CoreTextStyle? valueStyle,
    CoreTextStyle? descriptionStyle,
    CoreTextStyle? counterStyle,
    CoreTextStyle? errorStyle,
  }) {
    return CoreTextAreaStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      focusBorderColor: focusBorderColor ?? this.focusBorderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      errorBorderColor: errorBorderColor ?? this.errorBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      activeBorderWidth: activeBorderWidth ?? this.activeBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      initialHeight: initialHeight ?? this.initialHeight,
      initialWidth: initialWidth ?? this.initialWidth,
      minHeight: minHeight ?? this.minHeight,
      minWidth: minWidth ?? this.minWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      padding: padding ?? this.padding,
      labelGapStyle: labelGapStyle ?? this.labelGapStyle,
      descriptionGapStyle: descriptionGapStyle ?? this.descriptionGapStyle,
      footerGapStyle: footerGapStyle ?? this.footerGapStyle,
      counterGapStyle: counterGapStyle ?? this.counterGapStyle,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      dragHandlePadding: dragHandlePadding ?? this.dragHandlePadding,
      dragHandleOffset: dragHandleOffset ?? this.dragHandleOffset,
      dragHandleSize: dragHandleSize ?? this.dragHandleSize,
      iconStyle: iconStyle ?? this.iconStyle,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      textAlign: textAlign ?? this.textAlign,
      textAlignVertical: textAlignVertical ?? this.textAlignVertical,
      cursorColor: cursorColor ?? this.cursorColor,
      cursorWidth: cursorWidth ?? this.cursorWidth,
      cursorRadius: cursorRadius ?? this.cursorRadius,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      baseTextStyle: baseTextStyle ?? this.baseTextStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      placeholderStyle: placeholderStyle ?? this.placeholderStyle,
      valueStyle: valueStyle ?? this.valueStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      counterStyle: counterStyle ?? this.counterStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      labelDisabledColor: labelDisabledColor ?? this.labelDisabledColor,
      helperTextColor: helperTextColor ?? this.helperTextColor,
      affixColor: affixColor ?? this.affixColor,
      errorTextColor: errorTextColor ?? this.errorTextColor,
      requiredMarkColor: requiredMarkColor ?? this.requiredMarkColor,
      dragHandleColor: dragHandleColor ?? this.dragHandleColor,
      selectionColor: selectionColor ?? this.selectionColor,
      backgroundCursorColor:
          backgroundCursorColor ?? this.backgroundCursorColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTextAreaStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          focusBorderColor == other.focusBorderColor &&
          hoverBorderColor == other.hoverBorderColor &&
          errorBorderColor == other.errorBorderColor &&
          borderWidth == other.borderWidth &&
          activeBorderWidth == other.activeBorderWidth &&
          borderRadius == other.borderRadius &&
          initialHeight == other.initialHeight &&
          initialWidth == other.initialWidth &&
          minHeight == other.minHeight &&
          minWidth == other.minWidth &&
          maxHeight == other.maxHeight &&
          maxWidth == other.maxWidth &&
          padding == other.padding &&
          labelGapStyle == other.labelGapStyle &&
          descriptionGapStyle == other.descriptionGapStyle &&
          footerGapStyle == other.footerGapStyle &&
          counterGapStyle == other.counterGapStyle &&
          rowSpacing == other.rowSpacing &&
          dragHandlePadding == other.dragHandlePadding &&
          dragHandleOffset == other.dragHandleOffset &&
          dragHandleSize == other.dragHandleSize &&
          iconStyle == other.iconStyle &&
          transitionDuration == other.transitionDuration &&
          textAlign == other.textAlign &&
          textAlignVertical == other.textAlignVertical &&
          cursorColor == other.cursorColor &&
          cursorWidth == other.cursorWidth &&
          cursorRadius == other.cursorRadius &&
          labelDisabledColor == other.labelDisabledColor &&
          helperTextColor == other.helperTextColor &&
          affixColor == other.affixColor &&
          errorTextColor == other.errorTextColor &&
          requiredMarkColor == other.requiredMarkColor &&
          dragHandleColor == other.dragHandleColor &&
          selectionColor == other.selectionColor &&
          backgroundCursorColor == other.backgroundCursorColor &&
          focusOutlineStyle == other.focusOutlineStyle &&
          baseTextStyle == other.baseTextStyle &&
          labelStyle == other.labelStyle &&
          placeholderStyle == other.placeholderStyle &&
          valueStyle == other.valueStyle &&
          descriptionStyle == other.descriptionStyle &&
          counterStyle == other.counterStyle &&
          errorStyle == other.errorStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    borderColor,
    focusBorderColor,
    hoverBorderColor,
    errorBorderColor,
    borderWidth,
    activeBorderWidth,
    borderRadius,
    initialHeight,
    initialWidth,
    minHeight,
    minWidth,
    maxHeight,
    maxWidth,
    padding,
    labelGapStyle,
    descriptionGapStyle,
    footerGapStyle,
    counterGapStyle,
    rowSpacing,
    dragHandlePadding,
    dragHandleOffset,
    dragHandleSize,
    iconStyle,
    transitionDuration,
    textAlign,
    textAlignVertical,
    cursorColor,
    cursorWidth,
    cursorRadius,
    labelDisabledColor,
    helperTextColor,
    affixColor,
    errorTextColor,
    requiredMarkColor,
    dragHandleColor,
    selectionColor,
    backgroundCursorColor,
    focusOutlineStyle,
    baseTextStyle,
    labelStyle,
    placeholderStyle,
    valueStyle,
    descriptionStyle,
    counterStyle,
    errorStyle,
  ]);

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

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Variant chrome scheme for `CoreTextAreaStyle.defaultsByVariant`-style
/// resolution. Holds the colour roles that flip between the `normal` and
/// `error` variants.
@immutable
class CoreTextAreaVariantStyle {
  /// Creates a [CoreTextAreaVariantStyle].
  const CoreTextAreaVariantStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.placeholderColor,
    required this.focusRingColor,
    required this.disabledBackgroundColor,
    required this.disabledForegroundColor,
    required this.disabledBorderColor,
    this.hoverBorderColor,
    this.hoverBackgroundColor,
  });

  /// Background fill.
  final CoreColor backgroundColor;

  /// Foreground text colour.
  final CoreColor foregroundColor;

  /// Border stroke colour.
  final CoreColor borderColor;

  /// Placeholder text colour.
  final CoreColor placeholderColor;

  /// Focus ring (outline) colour.
  final CoreColor focusRingColor;

  /// Border stroke colour while the pointer is over the field. `null`
  /// keeps [borderColor] — mirrors
  /// `CoreTextFieldVariantStyle.hoverBorderColor` (`outline-variant` →
  /// `outline` on the ordinary area; the error row restates `error` so
  /// an error border outranks the pointer).
  final CoreColor? hoverBorderColor;

  /// Fill while the pointer is over the area. `null` keeps
  /// [backgroundColor] — mirrors `CoreTextFieldVariantStyle
  /// .hoverBackgroundColor` (only the filled variant states one).
  final CoreColor? hoverBackgroundColor;

  /// Background fill when disabled.
  final CoreColor disabledBackgroundColor;

  /// Foreground text colour when disabled.
  final CoreColor disabledForegroundColor;

  /// Border stroke colour when disabled.
  final CoreColor disabledBorderColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTextAreaVariantStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          borderColor == other.borderColor &&
          placeholderColor == other.placeholderColor &&
          focusRingColor == other.focusRingColor &&
          hoverBorderColor == other.hoverBorderColor &&
          hoverBackgroundColor == other.hoverBackgroundColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          disabledForegroundColor == other.disabledForegroundColor &&
          disabledBorderColor == other.disabledBorderColor;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    foregroundColor,
    hoverBorderColor,
    hoverBackgroundColor,
    borderColor,
    placeholderColor,
    focusRingColor,
    disabledBorderColor,
    disabledBackgroundColor,
    disabledForegroundColor,
  ]);
}
