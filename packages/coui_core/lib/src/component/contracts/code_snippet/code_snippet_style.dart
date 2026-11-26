/// Per-instance style for `CodeSnippet`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_code_line_tone.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `CodeSnippet` should render.
///
/// `CoreCodeSnippetStyle` carries chrome (background / border /
/// padding / radius) fields, nested text style slots for the rendered
/// code and the line-number gutter, plus the dimensional / foreground
/// chrome of the copy affordance and line-number gutter. Every chrome /
/// dimensional field is exposed as a nullable override so a single
/// style object can flow through the nested-merge chain:
///
/// ```text
/// design system default (CoreCodeSnippetStyle.defaultX)
///   → CoreCodeSnippetTheme.style                    // 프로젝트 공통
///   → widget.codeSnippetStyle                       // 인스턴스별
/// ```
@immutable
class CoreCodeSnippetStyle implements CoreStyle<CoreCodeSnippetStyle> {
  /// Creates a [CoreCodeSnippetStyle].
  const CoreCodeSnippetStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.codeTypography,
    this.codeTextStyle,
    this.lineNumberTextStyle,
    this.preMargin,
    this.lineNumberMargin,
    @Deprecated(
      'Unused (since 0.162) — the gutter number is an opaque token: '
      'state lineNumberTextStyle.color (default '
      'defaultLineNumberTextStyle, onSurfaceVariant). Hierarchy is the token, '
      'not an alpha.',
    )
    this.lineNumberAlpha,
    this.copyButtonOffset,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.copyButtonStyle,
    this.copyIconStyle,
    this.actionGapStyle,
    this.successLineColor,
    this.warningLineColor,
    this.errorLineColor,
  });

  // ─── Design-system defaults ───────────────────

  /// Container background colour token — `surfaceContainerLow`, a quiet face
  /// that follows the page's brightness (a pale face in light, a deep one in
  /// dark) rather than an inverse slab. Syntax colours are tuned for it.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerLow,
  );

  /// Container border colour — transparent: the block has no border.
  ///
  /// One half of a pair with [defaultBorderWidth]. A width of 0 alone is not
  /// borderless on Flutter, whose outlined container still strokes a
  /// hairline in the border colour at width 0; an authored transparent
  /// colour is what makes the resolver collapse the width as well.
  static const CoreColor defaultBorderColor = CoreColor.transparent;

  /// Default border width — none (the other half of the pair with
  /// [defaultBorderColor]).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke0;

  /// Default rendered-code text style slot — carries only the code
  /// foreground colour (`onSurface`) via [CoreTextStyle.color]. Matches the
  /// [codeTextStyle] field (the per-instance override merges on top). The
  /// code's plain text and everything the highlighter leaves uncoloured read
  /// this colour — except on a face the syntax role colours are not certified
  /// on (`CoreSyntaxFaces.admits`), where every highlighted span reads it
  /// too. The line-number gutter states a colour of its own
  /// ([defaultLineNumberTextStyle]); the copy glyph takes the copy button's
  /// ([defaultCopyIconStyle]). Both follow the face's ink instead on a solid
  /// role face ([solidFaceInks]).
  static const CoreTextStyle defaultCodeTextStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default line-number gutter text style slot — carries only the gutter
  /// colour, `onSurfaceVariant`, opaque. Matches the [lineNumberTextStyle]
  /// field (the per-instance override merges on top), so a caller-stated
  /// `lineNumberTextStyle.color` still wins.
  ///
  /// The gutter is a second tier of text on the same face, and the tier is
  /// the token chosen, not an alpha laid over the code colour — which is why
  /// [lineNumberAlpha] is retired and the gutter no longer follows a caller's
  /// [codeTextStyle] colour.
  static const CoreTextStyle defaultLineNumberTextStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Band of a [CoreCodeLineTone.success] line — `successContainer`, opaque,
  /// across the whole row (the line-number gutter included). The token
  /// `CodeDiff` paints an added row with (`defaultAddedBackgroundColor`): a
  /// different meaning that draws the same band, so it is its own default.
  ///
  /// The code and the gutter number keep their own colours on the band —
  /// `onSurface` and `onSurfaceVariant` both read on a container tone.
  static const CoreColor defaultSuccessLineColor = CoreColor.token(
    CoreColors.successContainer,
  );

  /// Band of a [CoreCodeLineTone.warning] line — `warningContainer`, the
  /// same container step [defaultSuccessLineColor] and
  /// [defaultErrorLineColor] take.
  static const CoreColor defaultWarningLineColor = CoreColor.token(
    CoreColors.warningContainer,
  );

  /// Band of a [CoreCodeLineTone.error] line — `errorContainer`, the token
  /// `CodeDiff` paints a removed row with (`defaultRemovedBackgroundColor`).
  static const CoreColor defaultErrorLineColor = CoreColor.token(
    CoreColors.errorContainer,
  );

  /// Container outer border radius — `radius8`.
  ///
  /// A code block is not one of the role-bearing surfaces (a pressable
  /// control, a floating panel, a card): it states its own corner, so the
  /// value is the plain `CoreRadius.radius8` step rather than a
  /// `CoreRadiusRole`. The copy button keeps its own radius 8, so the inner
  /// and outer corners are equal.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default copy-affordance button style — the single source for both
  /// platforms' nested [copyButtonStyle] slot, raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)`. Carries the copy
  /// button's chrome: a square 28×28 hit-area (`width` = `height` =
  /// [CoreSize.size28]) with a tight glyph (`padding` = `.zero`), an
  /// 8-radius rounded corner, and the 150 ms transition. The plain
  /// variant supplies the transparent background and the glyph's colour —
  /// `onSurfaceVariant` at rest, `onSurface` on hover, `disabledContent` when
  /// disabled — which the glyph takes because [defaultCopyIconStyle] states
  /// none of its own.
  ///
  /// The focus ring is the standard one (2px wide, 2px off, `focusRing`,
  /// no gap band): the default face is a container tone the ring already
  /// reads on, so the button states no ring of its own. A solid role face is
  /// not such a tone — the ring token measures 1.00–2.76:1 on one and is the
  /// face's own colour on `primary` and `tertiary` — so on a solid face the
  /// ring takes the face's ink instead ([inkOnFace]).
  static const CoreButtonStyle defaultCopyButtonStyle = CoreButtonStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    height: CoreSize.size28,
    width: CoreSize.size28,
    padding: .zero,
    animationDuration: Duration(milliseconds: CoreDuration.fast),
  );

  /// Container inner padding applied to the code area — 10 above and
  /// below, 12 on each side. With the `codeSm` 21px line box a one-line
  /// snippet is `10 + 21 + 10 = 41` tall inside its border.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    vertical: CoreSpace.space10,
    horizontal: CoreSpace.space12,
  );

  /// Code body typography role — the `codeSm` role (12 / 400 / a fixed
  /// 21px line box / no tracking, monospace). Code and the line-number
  /// gutter both resolve to this one role, so their lines share the 21px
  /// grid (a multiplier could not put 12px glyphs and the gutter's digits
  /// on the same rows).
  ///
  /// Token-backed single source for both platforms: Flutter materialises
  /// the role through `theme.typography` (so a project's own scale and text
  /// scaling reach it), and Web emits the `text-code-sm` role class (plus an
  /// inline overlay only for what a caller states on top).
  static const CoreTextStyle defaultCodeTypography = CoreTextStyle.token(
    CoreTextStyles.codeSm,
  );

  /// Copy button corner offset (top + right) — logical px.
  static const double defaultCopyButtonOffset = CoreSpace.space6;

  /// Line number gutter right margin — logical px (the gap between the
  /// numbers and the code).
  static const double defaultLineNumberMargin = CoreSpace.space12;

  /// Retired default of [lineNumberAlpha] (40 %). Read by no platform — the
  /// gutter number is an opaque token, and hierarchy is the token chosen.
  @Deprecated(
    'Unused (since 0.162) — the gutter number is an opaque token: '
    'defaultLineNumberTextStyle (onSurfaceVariant). Hierarchy is the token, '
    'not an alpha.',
  )
  static const double defaultLineNumberAlpha = CoreOpacity.opacity40;

  /// Default copy-button glyph icon style — 16 logical px sized, and no
  /// colour of its own.
  ///
  /// The glyph takes the colour the copy button hands its child, so it
  /// follows the plain variant's foreground: `onSurfaceVariant` at rest,
  /// `onSurface` on hover and press, `disabledContent` when disabled, the same
  /// on both platforms with no state layer here. A colour stated on the icon
  /// outranks the one the button hands down and pins the glyph through every
  /// state, which is why none is stated. Per-instance override flows through
  /// [copyIconStyle] (merged on top of this default).
  static const CoreIconStyle defaultCopyIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// The ink each solid role face pairs with — the colour that reads on it
  /// (`primary` → `onPrimary`, …). `outline` has no `on` partner, so its ink is
  /// `surface`.
  ///
  /// A solid role fill is none of the tones the defaults are tuned for: the
  /// gutter's `onSurfaceVariant` ([defaultLineNumberTextStyle]) and the copy
  /// button's plain foreground measure 1.0–3.4:1 on it, and the copy
  /// button's `focusRing` ring 1.00–2.76:1. [inkOnFace] states this ink on
  /// all three, which is what makes the line numbers, the glyph and the
  /// keyboard focus ring readable on the face however it was chosen — a
  /// colour getter, a project theme or a plain `backgroundColor` — and
  /// independent of the order a chain of colour getters is written in.
  static const List<({CoreColorToken face, CoreColorToken ink})> solidFaceInks =
      [
        (face: CoreColors.primary, ink: CoreColors.onPrimary),
        (face: CoreColors.secondary, ink: CoreColors.onSecondary),
        (face: CoreColors.tertiary, ink: CoreColors.onTertiary),
        (face: CoreColors.error, ink: CoreColors.onError),
        (face: CoreColors.success, ink: CoreColors.onSuccess),
        (face: CoreColors.warning, ink: CoreColors.onWarning),
        (face: CoreColors.info, ink: CoreColors.onInfo),
        (face: CoreColors.outline, ink: CoreColors.surface),
      ];

  /// What [face] states for the line numbers, the copy glyph and the copy
  /// button's focus ring: the face's ink ([solidFaceInks]) on all three, or
  /// `null` when the face is not a solid role fill — a surface or container
  /// tone, a raw colour, or a token at less than full opacity — and all
  /// three keep their defaults.
  ///
  /// Meant to sit under what a caller states, in the merge chain: a colour the
  /// caller states on the gutter, the glyph or the ring replaces it. A glyph
  /// colour stated this way pins the glyph through every state, so on a solid
  /// role face the glyph keeps its ink through hover.
  ///
  /// The ring states its colour only. Its width, gap and the transparent gap
  /// band stay the copy button's, so the ring sits where it does on every
  /// other face and the face shows through the gap — the ink is what meets
  /// the face on both sides of the ring.
  static CoreCodeSnippetStyle? inkOnFace(CoreColor face) {
    if (face.opacity != 1) return null;
    for (final pair in solidFaceInks) {
      if (pair.face == face.token) {
        final ink = CoreColor.token(pair.ink);
        return CoreCodeSnippetStyle(
          lineNumberTextStyle: CoreTextStyle(color: ink),
          copyButtonStyle: CoreButtonStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(borderColor: ink),
          ),
          copyIconStyle: CoreIconStyle(color: ink),
        );
      }
    }
    return null;
  }

  /// Gap between sibling action widgets in the top-right area —
  /// logical px.
  static const double defaultActionGap = CoreSpace.space4;

  /// Default gap slot between sibling action widgets in the top-right
  /// area. Carries the design-system gap size; the per-instance
  /// [actionGapStyle] merges on top so the resolved slot rides a single
  /// [CoreGapStyle] (PoC FAB `actionGapStyle` nested-slot pattern).
  /// Shared by Flutter and Web resolvers.
  static const CoreGapStyle defaultActionGapStyle = CoreGapStyle(
    size: defaultActionGap,
  );

  /// `<pre>` wrapper outer margin — logical px (0 — `m-0` flush).
  static const double defaultPreMargin = CoreSpace.space0;

  // ── Chrome ───────────────────────────────────

  /// Container background colour. `null` defers to
  /// [defaultBackgroundColor].
  ///
  /// The face also decides whether the highlighter's role colours apply: on a
  /// surface or container tone they do, on any other face (a solid role fill,
  /// a raw colour, a token at less than full opacity) every span reads the
  /// code colour instead — see `CoreSyntaxFaces.admits`. On a solid role fill
  /// the line numbers, the copy glyph and the copy button's focus ring take
  /// the face's ink as well ([inkOnFace]).
  final CoreColor? backgroundColor;

  /// Outer border stroke colour. `null` defers to [defaultBorderColor].
  final CoreColor? borderColor;

  /// Outer border stroke width (logical px).
  final double? borderWidth;

  /// Outer border radius. `null` defers to [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  /// Inner padding applied to the code area. `null` defers to
  /// [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Code body typography role. `null` defers to [defaultCodeTypography].
  final CoreTextStyle? codeTypography;

  // ── Slot Styles (nested) ─────────────────────

  /// Rendered code text style override (layered on [codeTypography]).
  /// Carries the code foreground colour via [CoreTextStyle.color] — the ink
  /// of the plain text and of every span the highlighter leaves uncoloured.
  /// `null` defers to [defaultCodeTextStyle].
  final CoreTextStyle? codeTextStyle;

  /// Line-number gutter text style override. Its colour is the gutter
  /// number's ink; `null` defers to [defaultLineNumberTextStyle]
  /// (`onSurfaceVariant`).
  ///
  /// A colour stated here replaces the default outright. The gutter does
  /// not derive from [codeTextStyle]: restating the code colour leaves the
  /// numbers where they were, and a caller who wants the numbers recoloured
  /// states this slot. On a solid role face the default is the face's ink
  /// ([inkOnFace]) instead of `onSurfaceVariant`.
  final CoreTextStyle? lineNumberTextStyle;

  // ── Dimensional chrome ───────────────────────

  /// `<pre>` wrapper outer margin (logical px). `null` defers to
  /// [defaultPreMargin].
  final double? preMargin;

  /// Line-number gutter right margin (logical px). `null` defers to
  /// [defaultLineNumberMargin].
  final double? lineNumberMargin;

  /// No longer read on any platform. To change the line numbers' colour,
  /// set [lineNumberTextStyle]'s colour instead: the numbers are set apart
  /// by a solid colour token, not by an alpha over the code colour.
  @Deprecated(
    'Unused (since 0.162) — the gutter number is an opaque token: '
    'state lineNumberTextStyle.color (default '
    'defaultLineNumberTextStyle, onSurfaceVariant). Hierarchy is the token, '
    'not an alpha.',
  )
  final double? lineNumberAlpha;

  /// Copy button corner offset — top + right (logical px): where the
  /// button sits inside its corner wrapper. `null` defers to
  /// [defaultCopyButtonOffset].
  ///
  /// This is layout positioning, not button chrome — it stays flat
  /// alongside the nested [copyButtonStyle].
  final double? copyButtonOffset;

  /// Minimum width of the code display area (logical px). `null` leaves
  /// the area unconstrained on that edge.
  ///
  /// There is no design-system default because "no size cap" is the
  /// design, so these four fields deliberately have no `defaultX`
  /// counterpart (same shape as `CoreTextAreaStyle.maxHeight` /
  /// `maxWidth`).
  ///
  /// Flutter maps the four to a `BoxConstraints` around the scroll area;
  /// Web maps them to `min-width` / `max-width` / `min-height` /
  /// `max-height` on the `<pre>` scroll wrapper.
  ///
  /// A default on ANY of the four is a rendering change, because both
  /// platforms decide on their nullness rather than reading a value:
  ///
  ///  · Flutter builds `codeAreaConstraints` as `null` exactly while all
  ///    four are unset, and the widget passes that straight to
  ///    `Container(constraints:)` — `null` is a no-op wrapper. One
  ///    non-null default makes the struct non-null, so every snippet
  ///    starts being measured against caps instead of taking its
  ///    intrinsic size.
  ///  · Web emits each cap only when it is set (`_remOrNull` yields
  ///    nothing for `null`), and [maxHeight] additionally gates
  ///    `overflow-y: auto`, so a default there turns every snippet into a
  ///    clamped scroller.
  final double? minWidth;

  /// Maximum width of the code display area (logical px). `null` leaves
  /// the area unconstrained on that edge. No `default*` — see [minWidth]
  /// for why a value here would change what every snippet renders.
  final double? maxWidth;

  /// Minimum height of the code display area (logical px). `null` leaves
  /// the area unconstrained on that edge. No `default*` — see [minWidth].
  final double? minHeight;

  /// Maximum height of the code display area (logical px). `null` leaves
  /// the area unconstrained on that edge. When set, the code area scrolls
  /// vertically past the cap on both platforms (Flutter's enclosing
  /// `SingleChildScrollView`, Web's `overflow-y: auto`).
  ///
  /// No `default*` — and this is the most load-bearing of the four,
  /// since Web keys `overflow-y: auto` on it being non-null: a default
  /// would make every snippet a fixed-height scroll box. See [minWidth].
  final double? maxHeight;

  // ── Slot Styles (nested) ─────────────────────

  /// Style for the copy button — size, radius, padding, foreground,
  /// transition. Laid over [defaultCopyButtonStyle] and passed as is to
  /// `Button(variant: .plain, buttonStyle: …)` on both platforms. On a
  /// solid role face the focus ring's colour is the face's ink
  /// ([inkOnFace]); a ring colour stated here replaces it.
  ///
  /// Composed per the child-component-composition rule.
  final CoreButtonStyle? copyButtonStyle;

  /// Copy button icon style override, merged on top of
  /// [defaultCopyIconStyle]: `size` defers to it. `color` has no default — the
  /// glyph follows the copy button's foreground through its states — so a
  /// colour stated here pins the glyph in every state. A solid role face
  /// states its ink here ([inkOnFace]), and the glyph keeps it through hover.
  final CoreIconStyle? copyIconStyle;

  /// Gap slot between sibling action widgets in the top-right area.
  /// `null` defers to [defaultActionGapStyle].
  final CoreGapStyle? actionGapStyle;

  // ── Line tones ────────────────────────────────

  /// Band colour override for [CoreCodeLineTone.success] lines. `null`
  /// defers to [defaultSuccessLineColor].
  ///
  /// Only the three status tones draw a band, each from its own slot (`null`
  /// defers to its `default*LineColor`); [lineColorFor] says which slot a
  /// tone reads. `neutral`, `muted` and `link` are the colours of a line's
  /// text in `MockupCode` and draw nothing behind a line here.
  final CoreColor? successLineColor;

  /// Band colour override for [CoreCodeLineTone.warning] lines.
  final CoreColor? warningLineColor;

  /// Band colour override for [CoreCodeLineTone.error] lines.
  final CoreColor? errorLineColor;

  /// The band a line of [tone] draws, from the three resolved line colours —
  /// or `null` for a tone that draws no band.
  ///
  /// Each resolver chains the three slots onto their defaults and asks this
  /// which one a tone reads: the one mapping both platforms share, so a tone
  /// cannot draw a band on one platform and nothing on the other.
  static CoreColor? lineColorFor(
    CoreCodeLineTone tone, {
    required CoreColor success,
    required CoreColor warning,
    required CoreColor error,
  }) => switch (tone) {
    CoreCodeLineTone.success => success,
    CoreCodeLineTone.warning => warning,
    CoreCodeLineTone.error => error,
    CoreCodeLineTone.neutral ||
    CoreCodeLineTone.muted ||
    CoreCodeLineTone.link => null,
  };

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested text styles are
  /// merged recursively.
  @override
  CoreCodeSnippetStyle merge(CoreCodeSnippetStyle? other) {
    if (other == null) return this;
    return CoreCodeSnippetStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      codeTypography: _mergeText(codeTypography, other.codeTypography),
      codeTextStyle: _mergeText(codeTextStyle, other.codeTextStyle),
      lineNumberTextStyle: _mergeText(
        lineNumberTextStyle,
        other.lineNumberTextStyle,
      ),
      preMargin: other.preMargin ?? preMargin,
      lineNumberMargin: other.lineNumberMargin ?? lineNumberMargin,
      lineNumberAlpha: other.lineNumberAlpha ?? lineNumberAlpha,
      copyButtonOffset: other.copyButtonOffset ?? copyButtonOffset,
      minWidth: other.minWidth ?? minWidth,
      maxWidth: other.maxWidth ?? maxWidth,
      minHeight: other.minHeight ?? minHeight,
      maxHeight: other.maxHeight ?? maxHeight,
      copyButtonStyle: _mergeButton(copyButtonStyle, other.copyButtonStyle),
      copyIconStyle: _mergeIcon(copyIconStyle, other.copyIconStyle),
      actionGapStyle: _mergeGap(actionGapStyle, other.actionGapStyle),
      successLineColor: other.successLineColor ?? successLineColor,
      warningLineColor: other.warningLineColor ?? warningLineColor,
      errorLineColor: other.errorLineColor ?? errorLineColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreCodeSnippetStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    CoreTextStyle? codeTypography,
    CoreTextStyle? codeTextStyle,
    CoreTextStyle? lineNumberTextStyle,
    double? preMargin,
    double? lineNumberMargin,
    double? lineNumberAlpha,
    double? copyButtonOffset,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
    CoreButtonStyle? copyButtonStyle,
    CoreIconStyle? copyIconStyle,
    CoreGapStyle? actionGapStyle,
    CoreColor? successLineColor,
    CoreColor? warningLineColor,
    CoreColor? errorLineColor,
  }) {
    return CoreCodeSnippetStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      codeTypography: codeTypography ?? this.codeTypography,
      codeTextStyle: codeTextStyle ?? this.codeTextStyle,
      lineNumberTextStyle: lineNumberTextStyle ?? this.lineNumberTextStyle,
      preMargin: preMargin ?? this.preMargin,
      lineNumberMargin: lineNumberMargin ?? this.lineNumberMargin,
      lineNumberAlpha: lineNumberAlpha ?? this.lineNumberAlpha,
      copyButtonOffset: copyButtonOffset ?? this.copyButtonOffset,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      copyButtonStyle: copyButtonStyle ?? this.copyButtonStyle,
      copyIconStyle: copyIconStyle ?? this.copyIconStyle,
      actionGapStyle: actionGapStyle ?? this.actionGapStyle,
      successLineColor: successLineColor ?? this.successLineColor,
      warningLineColor: warningLineColor ?? this.warningLineColor,
      errorLineColor: errorLineColor ?? this.errorLineColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCodeSnippetStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          codeTypography == other.codeTypography &&
          codeTextStyle == other.codeTextStyle &&
          lineNumberTextStyle == other.lineNumberTextStyle &&
          preMargin == other.preMargin &&
          lineNumberMargin == other.lineNumberMargin &&
          lineNumberAlpha == other.lineNumberAlpha &&
          copyButtonOffset == other.copyButtonOffset &&
          minWidth == other.minWidth &&
          maxWidth == other.maxWidth &&
          minHeight == other.minHeight &&
          maxHeight == other.maxHeight &&
          copyButtonStyle == other.copyButtonStyle &&
          copyIconStyle == other.copyIconStyle &&
          actionGapStyle == other.actionGapStyle &&
          successLineColor == other.successLineColor &&
          warningLineColor == other.warningLineColor &&
          errorLineColor == other.errorLineColor;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    codeTypography,
    codeTextStyle,
    lineNumberTextStyle,
    preMargin,
    lineNumberMargin,
    lineNumberAlpha,
    copyButtonOffset,
    minWidth,
    maxWidth,
    minHeight,
    maxHeight,
    copyButtonStyle,
    copyIconStyle,
    actionGapStyle,
    successLineColor,
    warningLineColor,
    errorLineColor,
  ]);

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
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
}
