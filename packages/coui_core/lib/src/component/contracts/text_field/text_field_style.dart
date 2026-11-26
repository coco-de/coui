/// Per-instance style for `TextField`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/component/host_derived.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_align.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:coui_core/src/typography/vertical_align.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `TextField` should render.
///
/// `CoreTextFieldStyle` carries chrome / dimensional / cursor
/// overrides as flat fields, plus nested `CoreTextStyle` /
/// `CoreIconStyle` references for the label / placeholder / value /
/// description / error text and the leading / trailing icon slots —
/// Epic #1302's "atomic-style nesting" rule.
///
/// **Semantic enums (`variant` / `size`) live on the widget, not on
/// this style** (Epic #1302 원칙 6/7). They identify the input
/// instance and are passed as widget parameters; this style holds
/// only chrome / dimensional / nested-slot overrides on top of
/// whichever variant / size the widget was instantiated with.
///
/// ```text
/// design system default for variant
///   → CoreTextFieldTheme.style                       // 프로젝트 공통
///   → CoreTextFieldTheme.variantStyles[variant]      // variant 별
///   → parent component slot override                  // 예: Select.inputStyle
///   → widget.textFieldStyle                          // 인스턴스별
/// ```
@immutable
class CoreTextFieldStyle implements CoreStyle<CoreTextFieldStyle> {
  /// Creates a [CoreTextFieldStyle].
  const CoreTextFieldStyle({
    this.backgroundColor,
    this.borderColor,
    this.focusBorderColor,
    this.hoverBorderColor,
    this.errorBorderColor,
    this.borderWidth,
    this.activeBorderWidth,
    this.borderRadius,
    this.height,
    this.minHeight,
    this.maxHeight,
    this.padding,
    this.labelPadding,
    this.descriptionPadding,
    this.rowSpacing,
    this.iconStyle,
    this.fileLabelFontWeight,
    this.transitionDuration,
    this.textAlign,
    this.textAlignVertical,
    this.crossAxisAlignment,
    this.cursorColor,
    this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    this.focusOutlineStyle,
    this.baseTextStyle,
    this.labelStyle,
    this.placeholderStyle,
    this.valueStyle,
    this.descriptionStyle,
    this.errorStyle,
    this.leadingIconStyle,
    this.trailingIconStyle,
    this.featureButtonStyle,
    this.labelDisabledColor,
    this.descriptionColor,
    this.affixColor,
    this.errorColor,
    this.selectionColor,
    this.backgroundCursorColor,
    this.stateLayer,
  });

  // ─── Design-system defaults (Phase 6f option D) ──

  /// Default cursor width (logical px).
  static const double defaultCursorWidth = 2;

  /// Default border width — the resting boundary, which takes its place in
  /// the layout.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default active-boundary width (1) — the boundary of a focused field
  /// and of one that holds an error. The same width as the resting
  /// boundary: focus and error speak through colour, not weight (#5747 —
  /// the designer copy draws them at 1). Only a part beyond [borderWidth]
  /// is ever added, painted over the box without taking layout (Flutter
  /// lays it over the child, Web adds an inset shadow of the difference),
  /// so a caller who states a wider one still keeps the content in place.
  static const double defaultActiveBorderWidth = CoreStrokeWidth.stroke1;

  /// Default cursor corner radius. Matches [defaultCursorWidth] so the
  /// caret renders as a rounded bar.
  static const CoreBorderRadius defaultCursorRadius = CoreBorderRadius.all(
    defaultCursorWidth,
  );

  /// Default padding applied to the label element (6 logical px on the
  /// bottom edge only — separates the label from the field below).
  static const CoreEdgeInsets defaultLabelPadding = CoreEdgeInsets.only(
    bottom: CoreSpace.space6,
  );

  /// Default padding applied to the description / error helper text
  /// element (6 logical px on the top edge only — separates the helper
  /// from the field above).
  static const CoreEdgeInsets defaultDescriptionPadding = CoreEdgeInsets.only(
    top: CoreSpace.space6,
  );

  /// Default native `Row.spacing` between the prefix / input / suffix
  /// row children (logical px).
  static const double defaultRowSpacing = CoreSpace.space8;

  /// Default description / helper text style — token-backed reference to
  /// the `bodyXs` slot (12 / 400 / 1.5, unaffected by [defaultsBySize] —
  /// the canvas states the same size on every rung, see the note on
  /// [defaultsBySize] below). Pairs 1:1 with the [descriptionStyle] field.
  static const CoreTextStyle defaultDescriptionStyle = _bodyXs;

  /// Default error text style — same rationale as [defaultDescriptionStyle]
  /// (size-invariant `bodyXs`). Pairs 1:1 with the [errorStyle] field.
  static const CoreTextStyle defaultErrorStyle = _bodyXs;

  // ─── Slot colour defaults (single source — both platforms) ──
  // Helper / affix / caret colours that the resolvers fall back to when
  // no per-slot colour override is set. Kept as named tokens so neither
  // platform reaches for `cs.<token>` / `scheme.<token>` directly
  // (layer-mapping "모든 디자인 값은 Core Style 단일 출처").

  /// Default description / helper text colour (`onSurfaceSubtle` — the
  /// third text tier, one step below the label's `onSurfaceVariant`, so
  /// the helper reads as the quietest of the field's three lines; with
  /// `onSurfaceVariant`, then `onSurface`, as fallbacks when the subtle
  /// token is unset). The helper sits on the page, never on the field's
  /// own fill, so it is measured against `surface` like every other
  /// third-tier text.
  static const CoreColor defaultDescriptionColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
    fallbacks: [CoreColors.onSurfaceVariant, CoreColors.onSurface],
  );

  /// Default error helper text colour (`error`).
  static const CoreColor defaultErrorColor = CoreColor.token(CoreColors.error);

  /// Default text-selection tint base colour (`primary`). Both resolvers
  /// apply a `CoreOpacity.opacity20` alpha on top before painting —
  /// Flutter via `Color.withValues(alpha:)`, Web via `CoreColor
  /// .scaleAlpha` emitted as a `selection:bg-*` Tailwind pseudo-element
  /// class (`::selection`).
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

  /// Default prefix / suffix affix slot colour (`onSurfaceSubtle`) — the
  /// leading / trailing icons and the affix text. They annotate the value
  /// rather than carry it, so they sit one tier below the label.
  static const CoreColor defaultAffixColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default disabled-label colour (`onSurfaceSubtle`) — one text tier
  /// below the enabled label's `onSurfaceVariant` (the `CoreFormLabelStyle`
  /// default), and a text tier rather than the graphics-only
  /// `disabledContent`. A disabled label held at the enabled token would
  /// be indistinguishable from an enabled one; dropping to the third text
  /// tier says "off" without making the label unreadable. A label nobody
  /// can read does not say "disabled"; it says the field is broken.
  static const CoreColor defaultLabelDisabledColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default text caret colour (`primary`).
  static const CoreColor defaultCursorColor = CoreColor.token(
    CoreColors.primary,
  );

  /// A size-independent field corner (8), retired: the design-system
  /// corner is the size row's [borderRadius]
  /// (`defaultsBySize[size].borderRadius`, the control height × 0.25 —
  /// the same value a `Button` of that size takes, so a field and the
  /// button beside it keep one corner language).
  @Deprecated(
    'Per-size now: read defaultsBySize[size].borderRadius (through '
    'resolveSizeRow) instead (since 0.156) — the field corner is the '
    'control height of the size × 0.25, so one value cannot answer for '
    'every size.',
  )
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default font weight applied to the file-upload `<input type="file">`
  /// label segment. Mirrors the design-system medium weight used across
  /// other form controls.
  static const int defaultFileLabelFontWeight = CoreFontWeight.medium;

  /// Default focus-outline style — fully filled slot the resolver
  /// uses as the base before merging the per-instance
  /// [focusOutlineStyle] override on top. Single slot pairs 1:1 with
  /// the [focusOutlineStyle] instance field.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(
        align: CoreFocusOutlineStyle.defaultAlign,
        borderColor: CoreFocusOutlineStyle.defaultBorderColor,
        borderWidth: CoreFocusOutlineStyle.defaultBorderWidth,
        offsetColor: CoreFocusOutlineStyle.defaultOffsetColor,
      );

  /// Default input-feature affordance (clear / password toggle) button
  /// style — horizontal `space8` padding (matches the legacy Flutter
  /// affordance hit-area). Single source for both platforms' nested
  /// [featureButtonStyle] slot, raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)`.
  ///
  /// No `borderRadius` here: the affordance's corner is per field size,
  /// so each [defaultsBySize] row states it in its own
  /// `featureButtonStyle` — equal to that row's [borderRadius]. The
  /// affordance is a `Button` composed without a size (`md`, 10), and a
  /// nested surface's corner must not be rounder than its container
  /// (designer decision 2026-08-31 — inner ≤ outer): inside an `xs` (6) or
  /// `sm` (8) field the button's own 10 would draw its hover fill rounder
  /// than the field around it. Resolvers merge this default, then the
  /// size row's `featureButtonStyle`, then the instance override.
  static const CoreButtonStyle defaultFeatureButtonStyle = CoreButtonStyle(
    padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
  );

  /// Default chrome transition duration. Web emits this as a CSS
  /// millisecond value; Flutter consumers read the
  /// [Duration] directly.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default horizontal text alignment inside the input. Web emits this
  /// as the matching `text-{start|center|...}` Tailwind utility; Flutter
  /// maps it to the corresponding `TextAlign` enum.
  static const CoreTextAlign defaultTextAlign = .start;

  /// Default vertical alignment for the prefix / input / suffix row.
  /// Flutter maps to `CrossAxisAlignment.center`; Web uses
  /// `items-center`.
  static const CoreVerticalAlign defaultCrossAxisAlignment = .center;

  /// Default vertical alignment of the text inside the input. Flutter
  /// maps to `TextAlignVertical.center`.
  static const CoreVerticalAlign defaultTextAlignVertical = .center;

  /// Idle (non-error) variant chrome. Single source of truth shared by
  /// Flutter and Web — each platform resolves the [CoreColor] via its
  /// own extension (`.toValue()` / `scheme.resolve(...)`).
  static const CoreTextFieldVariantStyle defaultNormalVariant =
      CoreTextFieldVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.surface),
        foregroundColor: CoreColor.token(CoreColors.onSurface),
        // `outlineVariant` at rest and `outline` under the pointer (#5747):
        // a form with several fields reads as a page of lines when every
        // resting edge is `outline`, so the resting edge steps one tone
        // quieter and only the field under the pointer lifts. The resting
        // edge falls under the 3:1 non-text floor on some grounds — an
        // accepted exception the contrast baseline records; focus and
        // error still carry their own full-contrast boundary.
        borderColor: CoreColor.token(CoreColors.outlineVariant),
        hoverBorderColor: CoreColor.token(CoreColors.outline),
        placeholderColor: CoreColor.token(CoreColors.placeholder),
        focusRingColor: CoreColor.token(CoreColors.primary),
        // No `stateLayer` — hover/focus/pressed ride the border alone
        // (`hoverBorderColor` above, the focus ring below), not a wash
        // over the fill. Measured against WCAG 2.4.13's 3:1 non-text
        // contrast floor, an 8% foreground-over-`surface` blend lands a
        // Δcontrast of 1.06–1.17 in every mode — well short of the
        // floor — while it also dims the value text and placeholder
        // sitting on the same fill. Every system surveyed for the Form
        // 계열 정본 (M3 · Fluent · Primer · Spectrum · Carbon · SEED ·
        // Radix) leaves a boxed field's fill untouched on hover/focus for
        // the same reason. `defaultPlainVariant` below keeps its ramp —
        // it has no border to step, so the wash is its only channel.
        // Was `surface` — the same fill the enabled field uses — which
        // left the background as the one part of "disabled" that said
        // nothing. #3469 moved the foreground and border onto dedicated
        // tokens for the reason spelled out just below and stopped one
        // field short; the canvas states `disabled-container` here.
        disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
        // #3469 — these two used to equal the enabled `foreground` /
        // `borderColor` verbatim, so the *only* thing that made "disabled"
        // look different from "enabled" was the `opacity-50` multiplier
        // layered on top by the Web resolver (and nothing at all on
        // Flutter, which never applied that opacity). A multiplier's
        // contrast depends on whatever is behind it, and forced-colours
        // mode doesn't touch it at all, so the dedicated disabled tokens
        // are what actually carries the state now.
        // `disabledContent` (#5747) — the value and the placeholder both
        // take it, so a disabled field reads disabled whether or not it
        // holds text.
        disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
        disabledBorderColor: CoreColor.token(CoreColors.disabledOutline),
      );

  /// Variant chrome applied when `widget.errorText != null` and the field
  /// is enabled ([CoreTextFieldVariant.of] — `disabled > error`). Border /
  /// focus ring switch to the `error` token; the rest mirrors
  /// [defaultNormalVariant].
  static const CoreTextFieldVariantStyle defaultErrorVariant =
      CoreTextFieldVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.surface),
        foregroundColor: CoreColor.token(CoreColors.onSurface),
        borderColor: CoreColor.token(CoreColors.error),
        // Error outranks hover — the pointer does not soften a validation
        // border (error/hover paints what error/enabled does).
        hoverBorderColor: CoreColor.token(CoreColors.error),
        placeholderColor: CoreColor.token(CoreColors.placeholder),
        focusRingColor: CoreColor.token(CoreColors.error),
        // No `stateLayer` — same rationale as `defaultNormalVariant`: the
        // border already carries hover, and the error tone doesn't need a
        // wash on top of it.
        disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
        // See `defaultNormalVariant` — a disabled field with a stale
        // error is still disabled first, so it takes the same dedicated
        // disabled tokens rather than staying on the error border.
        disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
        disabledBorderColor: CoreColor.token(CoreColors.disabledOutline),
      );

  /// The bare variant — transparent fill and border in every state, so the
  /// host's chrome is the only box. Foreground and placeholder stay the
  /// normal tones.
  ///
  /// `focusRingColor` matches [defaultNormalVariant]'s `primary` ring
  /// (Figma "❖ TextField" 2026-09 개정) — the canvas shows the ring fully,
  /// same colour and width as the boxed field. This reverses the earlier
  /// "host shows the active state, so a bare field stays ringless" call;
  /// the canvas replaced that design (2026-09-11 decision).
  static const CoreTextFieldVariantStyle defaultPlainVariant =
      CoreTextFieldVariantStyle(
        backgroundColor: CoreColor.transparent,
        foregroundColor: CoreColor.token(CoreColors.onSurface),
        borderColor: CoreColor.transparent,
        placeholderColor: CoreColor.token(CoreColors.placeholder),
        focusRingColor: CoreColor.token(CoreColors.primary),
        // Tier A (state-layer decision record): a bare field still has to
        // show hover / focus / pressed, and with no box the wash is the only
        // channel left — unlike `defaultNormalVariant` / `defaultErrorVariant`,
        // which dropped their ramp once the border carried the state
        // instead (see their own comment above).
        stateLayer: CoreStateLayer.subtle,
        // No visible box of its own — the host composing `plain` supplies
        // the surrounding chrome, so this field's text should start flush
        // where a label above it starts (x=0), not offset by the boxed
        // field's own horizontal inset.
        horizontalPadding: CoreSpace.space0,
        // Disabled paints no box either — the fill and the border stay
        // transparent, as at rest. The host composing `plain` owns the box
        // and draws its own disabled chrome; a face here sits inside that
        // box as a second, narrower one (the inner field is inset from the
        // host's edge), which is what the canvas showed inside a disabled
        // ItemPicker search row. The state is carried by the text, which
        // takes `disabledContent` like the boxed variants — the same call
        // as a disabled `plain` Button (#4553).
        disabledBackgroundColor: CoreColor.transparent,
        disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
        disabledBorderColor: CoreColor.transparent,
      );

  /// The filled variant (#5747) — a tinted fill instead of a drawn edge,
  /// for a field that sits on a surface which already frames it (a card,
  /// a sheet). The resting edge takes the fill's own tone so no line shows;
  /// hover and press step the fill one tone up, focus draws the `primary`
  /// active boundary over the resting fill, disabled drops to the lowest
  /// container tone.
  static const CoreTextFieldVariantStyle defaultFilledVariant =
      CoreTextFieldVariantStyle(
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

  /// Per-variant chrome table. Single source of truth shared by Flutter
  /// and Web — resolvers pick the entry from the field's resolved
  /// [CoreTextFieldVariant] ([CoreTextFieldVariant.of] — `error` when
  /// `widget.errorText != null` and the field is enabled, otherwise the
  /// widget's `variant`).
  static const Map<CoreTextFieldVariant, CoreTextFieldVariantStyle>
  defaultsByVariant = {
    CoreTextFieldVariant.defaultVariant: defaultNormalVariant,
    CoreTextFieldVariant.error: defaultErrorVariant,
    CoreTextFieldVariant.plain: defaultPlainVariant,
    CoreTextFieldVariant.filled: defaultFilledVariant,
  };

  /// Per-size dimensional defaults. Single source of truth shared by
  /// Flutter and Web — both resolvers read
  /// `CoreTextFieldStyle.defaultsBySize[size]!` for the
  /// `minHeight` / `padding` / `iconStyle` / `baseTextStyle` fallback.
  ///
  /// `minHeight` is the control height (`CoreControlSize`) — a floor, so a
  /// field sits at the same height as a `Button` of its size in one row.
  /// A one-line field lays no vertical padding of the row's and centres
  /// its line ([contentPadding]), so it sits on the rung at every size; the
  /// box grows past the floor only where the line itself is taller (large
  /// text) or the field grows (several lines). See [boxMinHeight] for the
  /// whole rule.
  ///
  /// The map value is `CoreTextFieldStyle` itself so the flat slot
  /// fields stay 1:1 with the per-size defaults — no separate typedef
  /// record holder (contract.md "defaultsBySize 값은 CoreXxxStyle
  /// 자체").
  ///
  /// Heights reference `CoreControlSize` (semantic row-alignment
  /// contract) and icons follow the shared control icon ladder
  /// 12/14/16/18/20/24 (`xs`…`xl2`).
  ///
  /// `borderRadius` is the control height × 0.25 — 6 · 8 · 10 · 12 · 14 ·
  /// 16, the values `CoreButtonStyle.defaultsBySize` states, so a field
  /// and the button beside it share one corner at every size (디자이너
  /// 결정 2026-10-08; the ratio is pinned by a Core test). Each row's
  /// `featureButtonStyle` restates the row's own corner for the clear /
  /// password affordance — see [defaultFeatureButtonStyle] for why the
  /// field, not the button, decides it. The two are restated rather than
  /// shared because a `const` initializer cannot read another const's
  /// property (`const_eval_property_access`); the Core test pins them
  /// equal row by row.
  ///
  /// `baseTextStyle` feeds ONLY the value / placeholder / affix slots
  /// (the resolver merges each on top of it) — NOT the label (a
  /// composed `FormLabel` owns that ladder on its own split point,
  /// `CoreFormLabelStyle.defaultsBySize`) and NOT description / error
  /// (size-invariant, see [defaultDescriptionStyle] / [defaultErrorStyle]
  /// below). `xs`/`sm`/`md`/`lg` read in the `bodyMedium` role (14px) and
  /// `xl`/`xl2` in `bodyLarge` (15px), each at the role's own line height
  /// (150% — 21 and 22.5). The field lays no line height of its own over
  /// the role: the line box is the role's, so a value, a placeholder and the
  /// caret standing in it read the same in every input. `xs` is not on the
  /// canvas (that rung is code-only, per the "xs 는 그냥 다 유지" kit-wide
  /// policy) and joins the lower tier by the same "extend down" rule the
  /// ladder's own two-rung canvas evidence implies.
  ///
  /// **`xs` is retiring on this ladder (since 0.141), superseding the
  /// "xs 는 그냥 다 유지" note above.** A 24px control cannot hold the
  /// value line without exceeding its own height (the 14px value's 150%
  /// line box is 21, against the 16px left inside `xs`'s padding), and
  /// 24px misses the WCAG 2.5.5 44px target floor outright. No system
  /// surveyed for the "Form 계열 정본" decision (Fluent/Primer/Radix/
  /// Carbon) puts a text-input rung below its `sm`. The entry stays live —
  /// callers on `xs` keep rendering, and a run with asserts on logs the
  /// notice once — until it is removed, in coui_core 0.153 at the earliest
  /// (`CoreTextFieldContract.retiringSizes`); from then `xs` renders the
  /// `sm` row through `resolveSizeRow`. There are no call sites in this
  /// repo outside tests, so migration is "use `sm`" whenever one appears,
  /// not a sweep.
  static const Map<CoreComponentSize, CoreTextFieldStyle> defaultsBySize = {
    CoreComponentSize.xs: CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      featureButtonStyle: CoreButtonStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      ),
      minHeight: CoreControlSize.heightXs,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space8,
        vertical: CoreSpace.space4,
      ),
      iconStyle: CoreIconStyle(size: CoreIconSize.size12),
      baseTextStyle: _bodyMedium,
    ),
    CoreComponentSize.sm: CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      featureButtonStyle: CoreButtonStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
      minHeight: CoreControlSize.heightSm,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space10,
        vertical: CoreSpace.space6,
      ),
      iconStyle: CoreIconStyle(size: CoreIconSize.size14),
      baseTextStyle: _bodyMedium,
    ),
    CoreComponentSize.md: CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      featureButtonStyle: CoreButtonStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      ),
      minHeight: CoreControlSize.heightMd,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space8,
      ),
      iconStyle: CoreIconStyle(size: CoreIconSize.size16),
      baseTextStyle: _bodyMedium,
    ),
    CoreComponentSize.lg: CoreTextFieldStyle(
      labelPadding: _largeLabelPadding,
      descriptionPadding: _largeDescriptionPadding,
      descriptionStyle: _bodySmall,
      errorStyle: _bodySmall,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      featureButtonStyle: CoreButtonStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      ),
      minHeight: CoreControlSize.heightLg,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space14,
        vertical: CoreSpace.space10,
      ),
      iconStyle: CoreIconStyle(size: CoreIconSize.size18),
      baseTextStyle: _bodyMedium,
    ),
    CoreComponentSize.xl: CoreTextFieldStyle(
      labelPadding: _largeLabelPadding,
      descriptionPadding: _largeDescriptionPadding,
      descriptionStyle: _bodySmall,
      errorStyle: _bodySmall,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
      featureButtonStyle: CoreButtonStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
      ),
      minHeight: CoreControlSize.heightXl,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space16,
        vertical: CoreSpace.space12,
      ),
      iconStyle: CoreIconStyle(size: CoreIconSize.size20),
      baseTextStyle: _bodyLarge,
    ),
    // xl2 — minHeight (64, CoreControlSize) and icon (24) are
    // spec-confirmed. `padding` remains a judgment-call extrapolation of
    // the xs→xl cadence; `baseTextStyle` is canvas-confirmed (bodyLarge,
    // same as xl).
    CoreComponentSize.xl2: CoreTextFieldStyle(
      labelPadding: _largeLabelPadding,
      descriptionPadding: _largeDescriptionPadding,
      descriptionStyle: _bodySmall,
      errorStyle: _bodySmall,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      featureButtonStyle: CoreButtonStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
      minHeight: CoreControlSize.heightXl2,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space20,
        vertical: CoreSpace.space14,
      ),
      iconStyle: CoreIconStyle(size: CoreIconSize.size24),
      baseTextStyle: _bodyLarge,
    ),
  };

  /// The minimum height of the field's box — one rule both resolvers
  /// read, so the floor cannot differ between platforms.
  ///
  /// - A caller `minHeight` is always honoured (`0` = no floor).
  /// - Otherwise a fixed `height` decides the box: the size row's floor
  ///   does not apply.
  /// - Otherwise the size row's control height, capped by a caller
  ///   `maxHeight` below it — a cap a caller states is a decision, and
  ///   the floor is only a default (an inverted range would also be an
  ///   invalid constraint on Flutter).
  ///
  /// Always a minimum, never the box itself: wherever what the box holds
  /// is taller than the floor (large text, a stated padding, several
  /// lines), the box grows past it instead of the text painting through
  /// the border. A one-line field on its row holds no vertical padding of
  /// the row's ([contentPadding]), so at the type the ladder is drawn for
  /// the floor is the box.
  static double? boxMinHeight({
    required double? height,
    required double? minHeight,
    required double? maxHeight,
    required double? sizeFloor,
  }) {
    if (minHeight != null) return minHeight;
    if (height != null) return null;
    if (sizeFloor == null || maxHeight == null) return sizeFloor;
    return sizeFloor < maxHeight ? sizeFloor : maxHeight;
  }

  /// The content padding a field lays inside its box — one rule both
  /// resolvers read.
  ///
  /// A one-line field ([singleLine]) whose box takes its height from the
  /// size row (no caller `height` / `minHeight`) is held on that row: the
  /// box is the row's control height and the line is centred in it, so the
  /// row's vertical padding is dropped and only its horizontal inset stays.
  /// The row's padding is a vertical inset for a field that grows — several
  /// lines, an expanding editor — and is kept there.
  ///
  /// **Why centring, not a padding**: the row's vertical padding plus the
  /// value's line box runs past the small rows (`sm`: 6 + 21 + 6 + the
  /// border is 35 against 32), and the half-pixel padding that would land
  /// it on the row is not a step of the spacing scale. Centring holds every
  /// row at its rung with whole-number values.
  ///
  /// A padding the caller states ([statedPadding]) is a statement and stays
  /// whole.
  static CoreEdgeInsets contentPadding({
    required CoreEdgeInsets? statedPadding,
    required CoreEdgeInsets rowPadding,
    required bool singleLine,
    required double? height,
    required double? minHeight,
  }) {
    if (statedPadding != null) return statedPadding;
    if (!singleLine || height != null || minHeight != null) return rowPadding;
    return rowPadding.copyWith(top: 0, bottom: 0);
  }

  // ── Chrome (flat) ────────────────────────────

  /// Background fill colour override.
  final CoreColor? backgroundColor;

  /// Border stroke colour override (idle state).
  final CoreColor? borderColor;

  /// Border stroke colour when the field is focused.
  final CoreColor? focusBorderColor;

  /// Border stroke colour while the pointer is over the field. `null` →
  /// the variant's `hoverBorderColor` (`on-surface` on the ordinary field,
  /// `error` on the error one).
  final CoreColor? hoverBorderColor;

  /// The wash laid over the fill while hovered / focused / pressed.
  /// `null` → the variant's own ramp (`CoreTextFieldVariantStyle.stateLayer`).
  /// A composing parent states its own ramp here — `Select`'s trigger is
  /// pressed-only, because its hover is a border step and its focus is
  /// the ring.
  final CoreStateLayer? stateLayer;

  /// Border stroke colour when the field is in error state.
  final CoreColor? errorBorderColor;

  /// Border stroke width override (logical px, pre-scaling) — the resting
  /// boundary, which stays in the layout. `null` → [defaultBorderWidth].
  final double? borderWidth;

  /// Width of the active boundary (logical px, pre-scaling) — a focused
  /// field, or one wearing the error variant while enabled (`disabled >
  /// error`). `null` → [defaultActiveBorderWidth].
  ///
  /// The resting boundary ([borderWidth]) stays where it is and only the
  /// part of this width beyond it is added, over the box and outside the
  /// layout: a wider boundary never moves the content or the field's own
  /// height. A width at or below [borderWidth] adds nothing, so a caller
  /// that states only a thicker [borderWidth] is not thinned on focus. The
  /// bare `plain` variant keeps its resting boundary in every state.
  final double? activeBorderWidth;

  /// Border radius override (pre-scaling). `null` → the size row's corner
  /// (`defaultsBySize[size].borderRadius`, the control height × 0.25).
  final CoreBorderRadius? borderRadius;

  // ── Dimensions ───────────────────────────────

  /// Fixed height override (logical px). Stating it fixes the box and
  /// drops the size row's floor ([minHeight]).
  ///
  /// No `default*`, deliberately: a default fixed height would pin every
  /// field — the chromeless ones inside other components' frames
  /// included — and stop large text from growing the box, so the text
  /// would paint through the border. Keeping the box at the control
  /// height is [minHeight]'s job.
  final double? height;

  /// Minimum height of the box (logical px). `null` defers to the size
  /// row's control height in [defaultsBySize]; `0` states no floor at
  /// all — what a chromeless composition (a field inside another
  /// component's frame) says. See [boxMinHeight].
  final double? minHeight;

  /// Maximum height constraint (logical px).
  ///
  /// No `default*`, deliberately: a value here caps every field. A caller
  /// cap below the size row's floor wins over that floor
  /// ([boxMinHeight]).
  final double? maxHeight;

  /// Padding override (logical px).
  final CoreEdgeInsets? padding;

  /// Padding applied to the label element. `null` defers to
  /// [defaultLabelPadding].
  final CoreEdgeInsets? labelPadding;

  /// Padding applied to the description / error helper text element.
  /// `null` defers to [defaultDescriptionPadding].
  final CoreEdgeInsets? descriptionPadding;

  /// Native `Row.spacing` between the prefix / input / suffix row
  /// children (logical px). `null` defers to [defaultRowSpacing].
  final double? rowSpacing;

  /// Icon size shared by the leading and trailing icons — only its `size`
  /// is read, and a size in [leadingIconStyle] / [trailingIconStyle] wins
  /// over it. `null` defers to
  /// `CoreTextFieldStyle.defaultsBySize[size]!.iconStyle!`.
  final CoreIconStyle? iconStyle;

  /// Font weight applied to the file-upload `<input type="file">`
  /// label segment. `null` defers to [defaultFileLabelFontWeight].
  final int? fileLabelFontWeight;

  /// How long the field's look (border, fill) takes to change between
  /// states. `null` defers to [defaultTransitionDuration].
  final Duration? transitionDuration;

  /// Horizontal text alignment override. `null` defers to
  /// [defaultTextAlign].
  final CoreTextAlign? textAlign;

  /// Vertical alignment of the text within the input. `null` defers
  /// to [defaultTextAlignVertical].
  final CoreVerticalAlign? textAlignVertical;

  /// Vertical alignment override for the prefix / input / suffix row.
  /// `null` defers to [defaultCrossAxisAlignment].
  final CoreVerticalAlign? crossAxisAlignment;

  // ── Cursor ───────────────────────────────────

  /// Cursor colour override.
  final CoreColor? cursorColor;

  /// Cursor width override (logical px).
  final double? cursorWidth;

  /// Cursor height override (logical px before text scaling).
  ///
  /// Null preserves the platform's default caret height. Flutter scales this
  /// with accessibility text scaling. Web exposes the value to tooling as
  /// `--coui-caret-height`; native HTML input caret geometry is browser-drawn.
  /// A fixed kit default would override the platform caret geometry and its
  /// text-size-dependent height. The actual default is determined by the host.
  @hostDerived
  final double? cursorHeight;

  /// Cursor corner radius override.
  final CoreBorderRadius? cursorRadius;

  /// Disabled-state label text colour override.
  /// `null` → [defaultLabelDisabledColor].
  final CoreColor? labelDisabledColor;

  /// Description / helper text colour override.
  /// `null` → [defaultDescriptionColor].
  final CoreColor? descriptionColor;

  /// Prefix / suffix affix glyph colour override.
  /// `null` → [defaultAffixColor].
  final CoreColor? affixColor;

  /// Error helper-text colour override. `null` → [defaultErrorColor].
  final CoreColor? errorColor;

  /// Text-selection tint colour override. `null` → [defaultSelectionColor].
  final CoreColor? selectionColor;

  /// Background-cursor (composition/IME) colour override.
  /// `null` → [defaultBackgroundCursorColor].
  final CoreColor? backgroundCursorColor;

  // ── Focus outline ─────────────────────────────

  /// Focus ring override ([CoreFocusOutlineStyle]) — ring colour, radius,
  /// width, offset and the colour of the band in the offset. `null` (or any
  /// field left unset in it) defers to [defaultFocusOutlineStyle]. A
  /// `borderColor` stated here outranks [focusBorderColor] and the
  /// variant's focus-ring tone; a `borderRadius` stated here outranks the
  /// field's own [borderRadius].
  final CoreFocusOutlineStyle? focusOutlineStyle;

  // ── Slot Styles (nested) ─────────────────────

  /// Base text style applied to the value / placeholder / affix slots
  /// before each one's own style override merges on top. `null` defers
  /// to `CoreTextFieldStyle.defaultsBySize[size]!.baseTextStyle!`
  /// (size-aware — `bodyMedium` for xs/sm/md/lg, `bodyLarge` for
  /// xl/xl2, each at the role's own line height).
  ///
  /// Does NOT feed the label (a composed `FormLabel` owns that ladder
  /// on its own split point — see [labelStyle]) or description / error
  /// (size-invariant, [defaultDescriptionStyle] / [defaultErrorStyle]).
  final CoreTextStyle? baseTextStyle;

  /// Label text style override — forwarded whole into the composed
  /// `FormLabel`'s own `formLabelStyle.labelStyle` slot (child-component-
  /// composition). By design has no `default` of its own here: `TextField`
  /// never merges this onto its own [baseTextStyle], because `FormLabel`
  /// owns the label's per-size ladder on its own split point
  /// (`CoreFormLabelStyle.defaultsBySize`). `null` → `FormLabel`'s own
  /// size-keyed default.
  final CoreTextStyle? labelStyle;

  /// Placeholder text style override, laid over [baseTextStyle] — the
  /// same per-size base the input value uses. Unset, the placeholder keeps
  /// the field's own typography.
  ///
  /// By design has no `default` of its own: both resolvers merge it onto
  /// [baseTextStyle] (`baseTextStyle.merge(merged.placeholderStyle)`)
  /// rather than a second, independently-tracked default that could drift
  /// from it.
  final CoreTextStyle? placeholderStyle;

  /// Input value text style override, laid over [baseTextStyle] like
  /// [placeholderStyle], so the caret's line box and the value text share
  /// the one per-size base.
  ///
  /// By design with no `default` of its own — both resolvers merge it onto
  /// [baseTextStyle] (`baseTextStyle.merge(merged.valueStyle)`).
  final CoreTextStyle? valueStyle;

  /// Description / helper text style override.
  final CoreTextStyle? descriptionStyle;

  /// Error text style override.
  final CoreTextStyle? errorStyle;

  /// Leading icon style override.
  ///
  /// No `default*`, and one would be actively wrong: the base for both
  /// affix icons already lives in Core as `defaultsBySize[size].iconStyle`,
  /// and these two are per-affix overrides layered on it. Both resolvers
  /// pick the icon size by precedence —
  ///
  /// ```text
  /// merged.leadingIconStyle?.size
  ///   ?? merged.trailingIconStyle?.size
  ///   ?? merged.iconStyle?.size
  ///   ?? defaultsBySize[size].iconStyle.size
  /// ```
  ///
  /// — so a `static const` sitting at the head of that chain would win
  /// over the shared [iconStyle] slot AND over the size table, pinning
  /// one icon size across every size tier. Being unset is what makes the
  /// two lower rungs reachable.
  final CoreIconStyle? leadingIconStyle;

  /// Trailing icon style override. No `default*` — second rung of the
  /// precedence chain documented on [leadingIconStyle]; a value here
  /// would shadow the shared [iconStyle] slot and the size table.
  final CoreIconStyle? trailingIconStyle;

  /// Style for the field's feature buttons (clear / password toggle). Laid
  /// over [defaultFeatureButtonStyle] and the size row's own
  /// `featureButtonStyle` (the row's corner), then passed as is to
  /// `Button(variant: .plain, buttonStyle: …)` on both platforms.
  ///
  /// Composed per child-component-composition.
  final CoreButtonStyle? featureButtonStyle;

  /// Token-backed `bodyXs` base text style (12px) — size-invariant base
  /// for [defaultDescriptionStyle] / [defaultErrorStyle].
  static const CoreTextStyle _bodyXs = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
  );

  /// `bodySmall` (13px) — the description / error role on the `lg` rung
  /// and above (#5747): a larger field carries a larger helper line.
  static const CoreTextStyle _bodySmall = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
  );

  /// Label → field gap on the `lg` rung and above (#5747) — 8, one step
  /// past [defaultLabelPadding]'s 6, as the field itself grows.
  static const CoreEdgeInsets _largeLabelPadding = CoreEdgeInsets.only(
    bottom: CoreSpace.space8,
  );

  /// Field → helper gap on the `lg` rung and above (#5747), paired with
  /// [_largeLabelPadding].
  static const CoreEdgeInsets _largeDescriptionPadding = CoreEdgeInsets.only(
    top: CoreSpace.space8,
  );

  /// `bodyMedium` (14px) at the role's own line height — shared
  /// `baseTextStyle` default for the xs/sm/md/lg rungs inside
  /// [defaultsBySize] (value / placeholder / affix only).
  static const CoreTextStyle _bodyMedium = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
  );

  /// `bodyLarge` (15px) at the role's own line height — shared
  /// `baseTextStyle` default for the xl/xl2 rungs.
  static const CoreTextStyle _bodyLarge = CoreTextStyle.token(
    CoreTextStyles.bodyLarge,
  );

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively so partial overrides only touch the fields
  /// they specify.
  @override
  CoreTextFieldStyle merge(CoreTextFieldStyle? other) {
    if (other == null) return this;
    return CoreTextFieldStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      focusBorderColor: other.focusBorderColor ?? focusBorderColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      stateLayer: other.stateLayer ?? stateLayer,
      errorBorderColor: other.errorBorderColor ?? errorBorderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      activeBorderWidth: other.activeBorderWidth ?? activeBorderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      height: other.height ?? height,
      minHeight: other.minHeight ?? minHeight,
      maxHeight: other.maxHeight ?? maxHeight,
      padding: other.padding ?? padding,
      labelPadding: other.labelPadding ?? labelPadding,
      descriptionPadding: other.descriptionPadding ?? descriptionPadding,
      rowSpacing: other.rowSpacing ?? rowSpacing,
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      fileLabelFontWeight: other.fileLabelFontWeight ?? fileLabelFontWeight,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      textAlign: other.textAlign ?? textAlign,
      textAlignVertical: other.textAlignVertical ?? textAlignVertical,
      crossAxisAlignment: other.crossAxisAlignment ?? crossAxisAlignment,
      cursorColor: other.cursorColor ?? cursorColor,
      cursorWidth: other.cursorWidth ?? cursorWidth,
      cursorHeight: other.cursorHeight ?? cursorHeight,
      cursorRadius: other.cursorRadius ?? cursorRadius,
      focusOutlineStyle: _mergeFocusOutline(
        focusOutlineStyle,
        other.focusOutlineStyle,
      ),
      baseTextStyle: _mergeText(baseTextStyle, other.baseTextStyle),
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      placeholderStyle: _mergeText(placeholderStyle, other.placeholderStyle),
      valueStyle: _mergeText(valueStyle, other.valueStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      errorStyle: _mergeText(errorStyle, other.errorStyle),
      leadingIconStyle: _mergeIcon(leadingIconStyle, other.leadingIconStyle),
      trailingIconStyle: _mergeIcon(trailingIconStyle, other.trailingIconStyle),
      featureButtonStyle: _mergeButton(
        featureButtonStyle,
        other.featureButtonStyle,
      ),
      labelDisabledColor: other.labelDisabledColor ?? labelDisabledColor,
      descriptionColor: other.descriptionColor ?? descriptionColor,
      affixColor: other.affixColor ?? affixColor,
      errorColor: other.errorColor ?? errorColor,
      selectionColor: other.selectionColor ?? selectionColor,
      backgroundCursorColor:
          other.backgroundCursorColor ?? backgroundCursorColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTextFieldStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreColor? focusBorderColor,
    CoreColor? hoverBorderColor,
    CoreStateLayer? stateLayer,
    CoreColor? errorBorderColor,
    double? borderWidth,
    double? activeBorderWidth,
    CoreBorderRadius? borderRadius,
    double? height,
    double? minHeight,
    double? maxHeight,
    CoreEdgeInsets? padding,
    CoreEdgeInsets? labelPadding,
    CoreEdgeInsets? descriptionPadding,
    double? rowSpacing,
    CoreIconStyle? iconStyle,
    int? fileLabelFontWeight,
    Duration? transitionDuration,
    CoreTextAlign? textAlign,
    CoreVerticalAlign? textAlignVertical,
    CoreVerticalAlign? crossAxisAlignment,
    CoreColor? cursorColor,
    double? cursorWidth,
    double? cursorHeight,
    CoreBorderRadius? cursorRadius,
    CoreColor? labelDisabledColor,
    CoreColor? descriptionColor,
    CoreColor? affixColor,
    CoreColor? errorColor,
    CoreColor? selectionColor,
    CoreColor? backgroundCursorColor,
    CoreFocusOutlineStyle? focusOutlineStyle,
    CoreTextStyle? baseTextStyle,
    CoreTextStyle? labelStyle,
    CoreTextStyle? placeholderStyle,
    CoreTextStyle? valueStyle,
    CoreTextStyle? descriptionStyle,
    CoreTextStyle? errorStyle,
    CoreIconStyle? leadingIconStyle,
    CoreIconStyle? trailingIconStyle,
    CoreButtonStyle? featureButtonStyle,
  }) {
    return CoreTextFieldStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      focusBorderColor: focusBorderColor ?? this.focusBorderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      stateLayer: stateLayer ?? this.stateLayer,
      errorBorderColor: errorBorderColor ?? this.errorBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      activeBorderWidth: activeBorderWidth ?? this.activeBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      height: height ?? this.height,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      padding: padding ?? this.padding,
      labelPadding: labelPadding ?? this.labelPadding,
      descriptionPadding: descriptionPadding ?? this.descriptionPadding,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      iconStyle: iconStyle ?? this.iconStyle,
      fileLabelFontWeight: fileLabelFontWeight ?? this.fileLabelFontWeight,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      textAlign: textAlign ?? this.textAlign,
      textAlignVertical: textAlignVertical ?? this.textAlignVertical,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
      cursorColor: cursorColor ?? this.cursorColor,
      cursorWidth: cursorWidth ?? this.cursorWidth,
      cursorHeight: cursorHeight ?? this.cursorHeight,
      cursorRadius: cursorRadius ?? this.cursorRadius,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      baseTextStyle: baseTextStyle ?? this.baseTextStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      placeholderStyle: placeholderStyle ?? this.placeholderStyle,
      valueStyle: valueStyle ?? this.valueStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      leadingIconStyle: leadingIconStyle ?? this.leadingIconStyle,
      trailingIconStyle: trailingIconStyle ?? this.trailingIconStyle,
      featureButtonStyle: featureButtonStyle ?? this.featureButtonStyle,
      labelDisabledColor: labelDisabledColor ?? this.labelDisabledColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
      affixColor: affixColor ?? this.affixColor,
      errorColor: errorColor ?? this.errorColor,
      selectionColor: selectionColor ?? this.selectionColor,
      backgroundCursorColor:
          backgroundCursorColor ?? this.backgroundCursorColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTextFieldStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          focusBorderColor == other.focusBorderColor &&
          hoverBorderColor == other.hoverBorderColor &&
          stateLayer == other.stateLayer &&
          errorBorderColor == other.errorBorderColor &&
          borderWidth == other.borderWidth &&
          activeBorderWidth == other.activeBorderWidth &&
          borderRadius == other.borderRadius &&
          height == other.height &&
          minHeight == other.minHeight &&
          maxHeight == other.maxHeight &&
          padding == other.padding &&
          labelPadding == other.labelPadding &&
          descriptionPadding == other.descriptionPadding &&
          rowSpacing == other.rowSpacing &&
          iconStyle == other.iconStyle &&
          fileLabelFontWeight == other.fileLabelFontWeight &&
          transitionDuration == other.transitionDuration &&
          textAlign == other.textAlign &&
          textAlignVertical == other.textAlignVertical &&
          crossAxisAlignment == other.crossAxisAlignment &&
          cursorColor == other.cursorColor &&
          cursorWidth == other.cursorWidth &&
          cursorHeight == other.cursorHeight &&
          cursorRadius == other.cursorRadius &&
          labelDisabledColor == other.labelDisabledColor &&
          descriptionColor == other.descriptionColor &&
          affixColor == other.affixColor &&
          errorColor == other.errorColor &&
          selectionColor == other.selectionColor &&
          backgroundCursorColor == other.backgroundCursorColor &&
          focusOutlineStyle == other.focusOutlineStyle &&
          baseTextStyle == other.baseTextStyle &&
          labelStyle == other.labelStyle &&
          placeholderStyle == other.placeholderStyle &&
          valueStyle == other.valueStyle &&
          descriptionStyle == other.descriptionStyle &&
          errorStyle == other.errorStyle &&
          leadingIconStyle == other.leadingIconStyle &&
          trailingIconStyle == other.trailingIconStyle &&
          featureButtonStyle == other.featureButtonStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    borderColor,
    focusBorderColor,
    hoverBorderColor,
    stateLayer,
    errorBorderColor,
    borderWidth,
    activeBorderWidth,
    borderRadius,
    height,
    minHeight,
    maxHeight,
    padding,
    labelPadding,
    descriptionPadding,
    rowSpacing,
    iconStyle,
    fileLabelFontWeight,
    transitionDuration,
    textAlign,
    textAlignVertical,
    crossAxisAlignment,
    cursorColor,
    cursorWidth,
    cursorHeight,
    cursorRadius,
    labelDisabledColor,
    descriptionColor,
    affixColor,
    errorColor,
    selectionColor,
    backgroundCursorColor,
    focusOutlineStyle,
    baseTextStyle,
    labelStyle,
    placeholderStyle,
    valueStyle,
    descriptionStyle,
    errorStyle,
    leadingIconStyle,
    trailingIconStyle,
    featureButtonStyle,
  ]);

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

  static CoreFocusOutlineStyle? _mergeFocusOutline(
    CoreFocusOutlineStyle? base,
    CoreFocusOutlineStyle? other,
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
}

/// Visual style definition for the text field chrome — emitted by
/// [CoreTextFieldStyle.defaultNormalVariant] (idle) and
/// [CoreTextFieldStyle.defaultErrorVariant] (when `errorText != null` and
/// the field is enabled).
///
/// Defines colours for: background, foreground, border, placeholder,
/// focus ring, and disabled states, plus a per-variant [horizontalPadding]
/// override on top of the per-size padding. Colours are platform-neutral
/// ([CoreColor]); the consuming renderer converts at use-site (Flutter
/// via `scheme.resolve(...).toValue()`; Web via `'bg-${color}'` /
/// `var(--coui-*)`).
@immutable
class CoreTextFieldVariantStyle {
  /// Creates a text field variant style.
  const CoreTextFieldVariantStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.placeholderColor,
    required this.focusRingColor,
    required this.disabledBackgroundColor,
    required this.disabledForegroundColor,
    required this.disabledBorderColor,
    this.stateLayer,
    this.hoverBorderColor,
    this.hoverBackgroundColor,
    this.horizontalPadding,
  });

  // === Normal ===

  /// Background fill colour.
  final CoreColor backgroundColor;

  /// Foreground (text) colour.
  final CoreColor foregroundColor;

  /// Border colour.
  final CoreColor borderColor;

  /// Placeholder text colour.
  final CoreColor placeholderColor;

  // === Hovered ===

  /// Border colour while the pointer is over the field. `null` keeps
  /// [borderColor] — the pointer changes nothing about the box.
  ///
  /// The canvas draws hover as a border step (`outline-variant` →
  /// `outline`) and no wash, so the box itself has to move; the state
  /// layer alone is what a `plain` field has, and that one states no
  /// hover border on purpose. The error row restates `error` here: an
  /// error border outranks the pointer (Select 코드 인계 통합본
  /// 2026-09-09 §4, the Carbon precedence `disabled > error > hover`).
  final CoreColor? hoverBorderColor;

  /// Fill while the pointer is over the field or presses it. `null` keeps
  /// [backgroundColor] — the boxed variants carry hover on the edge alone;
  /// [CoreTextFieldStyle.defaultFilledVariant] has no visible edge, so its
  /// fill steps one tone up instead.
  final CoreColor? hoverBackgroundColor;

  // === Focused ===

  /// Focus ring / focused border colour.
  final CoreColor focusRingColor;

  // === State layer ===

  /// How strongly the field lays its own foreground over its fill while
  /// hovered, focused or pressed.
  ///
  /// `CoreStateLayer.subtle` on [CoreTextFieldStyle.defaultPlainVariant] —
  /// the tier the state-layer decision record assigns to Text Field by
  /// name, and the ramp the library canvas already paints on it. `null`
  /// on [CoreTextFieldStyle.defaultNormalVariant] /
  /// [CoreTextFieldStyle.defaultErrorVariant]: those two carry hover on
  /// the border instead (measured — see their own comment), so a wash on
  /// top would double the signal and dim the value text sitting on the
  /// same fill.
  ///
  /// Nullable so a Theme-supplied row may omit it, and so the two states a
  /// text field can be in that must NOT wash survive: the resolvers gate
  /// this on the field actually having a fill. Seven in-repo compositions
  /// hand `TextField` a transparent one — the OTP hidden buffer is the
  /// sharpest, since it is invisible AND permanently focused while typing,
  /// so an ungated 8% wash would paint a slab straight across the visible
  /// cell row.
  ///
  /// **The focus rung is not redundant with the focus ring**, though a
  /// focused field now changes three things at once (ring, border, wash).
  /// Drop it and the ramp starts at 0 for a focused field, so hovering one
  /// would make a wash *appear* — the focus state reading as weaker than
  /// hover, which is the exact inversion `CoreStateLayer` exists to
  /// prevent. The ring keeps owning WCAG 1.4.11 either way; this is a
  /// visual aid on top of it, not a replacement for it.
  final CoreStateLayer? stateLayer;

  // === Disabled ===

  /// Background colour when disabled.
  final CoreColor disabledBackgroundColor;

  /// Foreground colour when disabled.
  final CoreColor disabledForegroundColor;

  /// Border colour when disabled.
  final CoreColor disabledBorderColor;

  // === Padding ===

  /// Horizontal content-inset override (logical px, applied to both left
  /// and right), layered on top of the per-size vertical padding rather
  /// than replacing it whole. `null` keeps the size table's horizontal
  /// inset — only [CoreTextFieldStyle.defaultPlainVariant] states `0`:
  /// with no box of its own, its text should start where a caller-drawn
  /// label above it starts, not offset by a boxed field's gutter.
  final double? horizontalPadding;
}
