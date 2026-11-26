import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// Marker class the toggle track wears so the scoped rules in
/// [ResolvedToggleRules] can reach it from the `Clickable` root the
/// pseudo-classes land on (`.scope:hover .co-toggle-track`). Inert on
/// its own — it carries no chrome.
const String kToggleTrackMarker = 'co-toggle-track';

/// Legacy travel keyframe name, retained for source compatibility.
/// Travel now shares the thumb's compositor transition via ToggleLensRuntime.
const String kToggleLensTravelKeyframes = 'co-toggle-lens-travel';

/// Stem of the keyframes that fade the transient lens in and out over the
/// travel. Private: the name a lens animates on always carries its fade
/// fraction — [toggleLensEnvelopeKeyframes] is the one way to spell it.
const String _kToggleLensEnvelopeStem = 'co-toggle-lens-envelope';

/// The name of the keyframes that fade the transient lens in and out over
/// the travel — the same envelope the Flutter twin evaluates — for a settled
/// [fadeFraction]: the stem plus the fraction in basis points
/// (`0.25` → `co-toggle-lens-envelope-2500`).
///
/// Content-addressed because keyframe names are document-global: the stops
/// move with the fraction, so two toggles fading on different fractions
/// and travelling at once would otherwise overwrite each other's envelope.
/// Toggles on the same fraction share one name and one identical set of
/// stops, as they shared the single name before the fraction was a style
/// field.
String toggleLensEnvelopeKeyframes(double fadeFraction) =>
    '$_kToggleLensEnvelopeStem-'
    '${(fadeFraction * kPercentScale * kPercentScale).round()}';

/// The style's lens fade fraction, settled and clamped — past
/// [CoreToggleStyle.maxLensFadeFraction] the fade in and the fade out would
/// overlap. The Flutter resolver clamps the same.
double _settledLensFadeFraction(CoreToggleStyle merged) =>
    (merged.lensFadeFraction ?? CoreToggleStyle.defaultLensFadeFraction).clamp(
      0.0,
      CoreToggleStyle.maxLensFadeFraction,
    );

/// Custom property holding the lens's starting translation.
const String kToggleLensFromVar = '--co-toggle-lens-from';

/// Custom property holding the lens's resting translation.
const String kToggleLensToVar = '--co-toggle-lens-to';

// Owned paint keeps its inline priority and exact rest fallback. Ordinary
// state rules select a private value instead of competing with that paint.
const _kToggleContentMarker = 'co-toggle-content';
const _kToggleOwnedFillMarker = 'co-toggle-owned-fill';
const _kToggleStateFillVar = '--co-toggle-state-fill';
const _kToggleStateResetRule =
    ':where(.$kToggleTrackMarker){$_kToggleStateFillVar:initial;}';
const _kToggleHoverFillVar = '--co-toggle-hover-fill';
const _kTogglePressedFillVar = '--co-toggle-pressed-fill';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Toggle`.
///
/// DOM shape (the outermost `Clickable` renders its own chrome via
/// `resolveClickable` — cursor / press / disabled opacity live there,
/// mirroring the Flutter twin's `Clickable(child: Row(…))` composition;
/// its own row-wide focus ring is switched off, the track's ring below
/// takes its place):
///
/// ```text
/// Clickable (<div role="switch">)                  // owns tap / keyboard / cursor / press
///   └─ root (<span>)                               // content wrapper, always present
///        ├─ <style>                                // toggle.dart renders only when rules.css is non-empty
///        ├─ hiddenInput (<input>)                  // toggle.dart renders only when name != null
///        ├─ prefix                                 // toggle.dart renders only when prefix != null
///        ├─ track (<span class="co-toggle-track">) // always present, visual only
///        │    └─ thumb (<span>)                    // always present
///        ├─ lens (<span>)                          // only while the thumb travels
///        │    └─ <style>                           // the lens's keyframes, mounted with it
///        ├─ suffix                                 // toggle.dart renders only when suffix != null
///        └─ label text                             // toggle.dart renders only when label != null
/// ```
///
/// The lens is a sibling of the track, not a child of it: inside the
/// track it would be a nested surface, and the material drops a nested
/// surface's backdrop pass — the one thing the lens is there to show.
/// It joins the row as a flex item whose margins cancel its own size and
/// the row's gap, so it takes no room and moves nothing; the same margins
/// seat it over the track. Nothing wraps the track for its sake, which is
/// what keeps the resting markup exactly what it was before the lens
/// existed — at rest the lens is not in the DOM at all.
///
/// All slot chromes are non-null paint-ready [WebElementChrome] —
/// `toggle.dart` reads `resolved.<slot>.className` /
/// `resolved.<slot>.inlineStyles` straight off.
///
/// Every chrome dimensional value (track / thumb width / height, border
/// radius, inner padding, thumb travel, gap) and the label foreground
/// colour are emitted **inline** through `(merged.X ?? default).toValue()`
/// / rem. Only colour token classes (`bg-<token>`, suppressed by a
/// conditional list element when a per-instance colour override exists),
/// the label typography role class, and structural classes remain on the
/// className surface. Hover / pressed / focus chrome is a blend and a
/// ring on a descendant of the focusable root — neither has a preset
/// utility — so those ride scoped rules ([resolveToggleRules]) rather
/// than this struct.
class ResolvedToggle implements WebResolvedChrome {
  /// Creates a [ResolvedToggle].
  const ResolvedToggle({
    required this.root,
    required this.track,
    required this.thumb,
    required this.lens,
    required this.clickableStyle,
    required this.labelWrapper,
  });

  /// Paint-ready chrome for the content wrapper `<span>` inside the
  /// composing `Clickable` (label typography + inline-flex layout +
  /// icon↔label gap).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the toggle track `<span>` element
  /// (visual only — activation lives on the composing `Clickable`).
  final WebElementChrome track;

  /// Paint-ready chrome for the toggle thumb `<span>` element.
  final WebElementChrome thumb;

  /// Paint-ready chrome for the transient lens `<span>` — a capsule marked
  /// as a floating surface, carried from the other pose to this one by
  /// [kToggleLensTravelKeyframes] and faded by the envelope keyframes
  /// ([toggleLensEnvelopeKeyframes]). Its chrome is the
  /// `CoreToggleStyle.lensContainerStyle` slot written inline — by default
  /// clear, so everything it shows comes from the material the active
  /// surface style gives a floating surface (its backdrop pass, the
  /// refraction the document host attaches to it, its sheen); under a style
  /// that gives none it draws nothing. Its base opacity is zero, so a
  /// zero-length animation — reduced motion zeroes the duration variable —
  /// never shows it.
  final WebElementChrome lens;

  /// Paint-ready chrome for the label-text wrapper `<span>` — a
  /// shrinkable flex item (`min-w-0`) so the label wraps within the
  /// pane, mirroring Flutter's `Flexible(Text(…))`. The
  /// character-level wrap fallback inherits from the `CoUIWeb` app
  /// root (`break-words`).
  final WebElementChrome labelWrapper;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// design default (`CoreToggleStyle.defaultClickableStyle`: generic
  /// disabled fade off, no press shrink) merged with the per-instance
  /// override, raw-forwarded to `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text for the `<style>` block in `Toggle` — the state layer
/// (hover / pressed wash over the track) and the focus ring around the
/// track, keyed off the `Clickable` root's pseudo-classes and landing on
/// the track one level in.
///
/// Both are things the utility classes cannot express: the wash is a
/// `color-mix()` of two tokens, and the ring is an outline (plus the gap
/// band, when it paints) on a descendant of the focusable element. Empty
/// on `!enabled` — a disabled toggle's rest chrome IS its disabled
/// chrome, nothing to wash toward and nothing to focus.
class ResolvedToggleRules {
  /// Creates a [ResolvedToggleRules].
  const ResolvedToggleRules({
    required this.scopeClass,
    required this.css,
    this.lensCss = '',
  });

  /// Class the `Clickable` root wears, and the class the CSS text below
  /// selects on. Empty exactly when [css] is empty — the pair travels
  /// together, never one without the other.
  final String scopeClass;

  /// Raw CSS rule text — empty on the disabled path.
  final String css;

  /// The transient lens's keyframes — travel along the thumb's path and
  /// the fade envelope. `toggle.dart` renders them only while the lens is
  /// mounted, so the resting markup carries none of it. Empty on the
  /// disabled path, where no lens is ever mounted.
  final String lensCss;
}

/// Resolved behavior timings for `Toggle`. No DOM chrome — widget behavior
/// helper only: how long the transient lens stays mounted after the value
/// changes.
class ResolvedToggleTiming {
  /// Creates a [ResolvedToggleTiming].
  const ResolvedToggleTiming({required this.lensLifetime});

  /// How long the lens stays in the DOM — one thumb travel, read off the
  /// same Core field the lens animates on. Under reduced motion the widget
  /// mounts no lens at all, so this span is never started.
  final Duration lensLifetime;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedToggle] for the given [context] + runtime state.
///
/// Merge chain plus `CoreToggleStyle.sizeDefaults` / `defaultsByVariant`
/// fallback:
///
/// ```text
/// design-system default (sizeDefaults + defaultsByVariant)
///   → theme.coreComponentTheme.toggle.style
///   → theme.coreComponentTheme.toggle.variantStyles[variant]
///   → widget.toggleStyle
/// ```
ResolvedToggle resolveToggle(
  BuildContext context, {
  required CoreToggleVariant variant,
  required CoreComponentSize size,
  required bool value,
  required bool enabled,
  CoreToggleStyle? toggleStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.toggle;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreToggleStyle(), [
    csTheme?.style,
    csTheme?.variantStyles?[variant],
    toggleStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantScale = CoreToggleStyle.defaultsByVariant[variant]!;
  final sizeDefaults = CoreToggleStyle.sizeDefaults(size);
  // A retiring size renders as before; a run with asserts on logs it once
  // (asserts stripped: nothing), so the caller hears before the step goes.
  noticeRetiringSize(
    component: 'Toggle',
    size: size,
    retiring: CoreToggleContract.retiringSizes,
  );

  // ─── Resolved chrome values (single inline signature) ──
  // Every dimensional value below is `(merged.X ?? <size|default>)` and
  // is emitted inline via `.toValue()` / rem — no class-drop branch.
  // Colour token classes stay on the className surface (suppressed by a
  // conditional list element when the matching per-instance override is
  // set so the inline rule wins).
  //
  // Label — design-system `defaultLabelStyle` (colour) → the size row's
  // role (the 14 / 14 / 16 / 18 / 18 ladder) → the per-instance override,
  // the same order the Flutter resolver composes.
  final labelStyle = CoreToggleStyle.defaultLabelStyle
      .merge(sizeDefaults.labelStyle)
      .merge(merged.labelStyle);
  final trackWidth = merged.trackWidth ?? sizeDefaults.trackWidth!;
  final trackHeight = merged.trackHeight ?? sizeDefaults.trackHeight!;
  final thumbSize = merged.thumbSize ?? sizeDefaults.thumbSize!;
  final thumbOffset = merged.thumbOffset ?? sizeDefaults.thumbOffset!;
  final inactiveThumbOffset =
      merged.inactiveThumbOffset ?? CoreToggleStyle.defaultInactiveThumbOffset;
  // Nested `CoreGapStyle` slot — merge the per-size default with the
  // per-instance override and extract `size` for the `<label>` wrapper
  // flexbox gap.
  final iconLabelGapStyle =
      (sizeDefaults.iconLabelGapStyle ??
              CoreToggleStyle.defaultIconLabelGapStyle)
          .merge(merged.iconLabelGapStyle);
  final gap = iconLabelGapStyle.size!;
  // The track's inner padding is the thumb's seat, not spacing: the thumb
  // travels by `thumbOffset` and the lens is placed from `padding.left`,
  // both in Dart, so a padding that followed a re-mapped spacing variable
  // would slide the thumb off its own track ends. Pinned on each side —
  // the track is control geometry a density does not move.
  final trackPadding = merged.padding ?? sizeDefaults.padding!;
  final padding =
      '${pinnedLengthCss(trackPadding.top)} '
      '${pinnedLengthCss(trackPadding.right)} '
      '${pinnedLengthCss(trackPadding.bottom)} '
      '${pinnedLengthCss(trackPadding.left)}';
  final trackBorderRadius =
      (merged.trackBorderRadius ?? sizeDefaults.trackBorderRadius!).toValue();
  final thumbBorderRadius = merged.thumbBorderRadius;
  final thumbShadow = emitShadow(
    merged.thumbShadow ?? CoreToggleStyle.defaultThumbShadow,
    base:
        (merged.thumbShadowBaseColor ??
                CoreToggleStyle.defaultThumbShadowBaseColor)
            .toValue(),
  );
  final trackActiveColor = merged.trackActiveColor;
  final trackInactiveColor = merged.trackInactiveColor;
  final stateLayer = merged.stateLayer ?? CoreToggleStyle.defaultStateLayer;
  final activeStateLayerColor =
      merged.stateLayerActiveColor ?? variantScale.activeStateLayer;
  final inactiveStateLayerColor =
      merged.stateLayerInactiveColor ?? variantScale.inactiveStateLayer;
  final thumbActiveColor = merged.thumbActiveColor;
  final thumbInactiveColor = merged.thumbInactiveColor;
  final colorTransitionDurationMs =
      (merged.colorTransitionDuration ??
              CoreToggleStyle.defaultColorTransitionDuration)
          .inMilliseconds;
  final thumbTransitionDurationMs =
      (merged.thumbTransitionDuration ??
              CoreToggleStyle.defaultThumbTransitionDuration)
          .inMilliseconds;
  // Token-routed easing (`toVarCss` doc) shared by both transitions below.
  final transitionEasingCss = CoreEasing.move.toVarCss();
  // The tint a lens cast is drawn in — the base the `OutlinedContainer`
  // resolvers give a cast, which is what the Flutter twin's composed lens
  // gets. Theme-free, like every Web emit: the token name goes out and the
  // browser resolves `--coui-shadow` at runtime. Read only when the slot
  // states a cast; the default casts nothing.
  final shadowBase = const CoreColor.token(CoreColors.shadow).toValue();

  // Transient lens — the thumb's box grown by the lens outset on each side.
  // The same numbers the Flutter resolver scales and positions: [lensLeft]
  // and [lensTop] are the capsule's corner in the track's own box when the
  // thumb sits at offset 0.
  final lensOutset = merged.lensOutset ?? CoreToggleStyle.defaultLensOutset;
  // The lens chrome — the design default (a clear pill that casts nothing)
  // under the per-instance slot. The same settled value the Flutter twin
  // raw-forwards to `OutlinedContainer`; here its fields are written inline
  // on the lens (`buildLensInlineStyles`). The slot's width / height are
  // not read — the size below is the outset's.
  final lensContainer = CoreToggleStyle.defaultLensContainerStyle.merge(
    merged.lensContainerStyle,
  );
  final lensEnvelopeKeyframes = toggleLensEnvelopeKeyframes(
    _settledLensFadeFraction(merged),
  );
  final lensWidth = thumbSize + lensOutset.left + lensOutset.right;
  final lensHeight = thumbSize + lensOutset.top + lensOutset.bottom;
  final lensLeft = trackPadding.left - lensOutset.left;
  final lensTop = (trackHeight - thumbSize) / 2 - lensOutset.top;
  // The lens is the flex item right after the track. Its margins seat it
  // there while taking no room (CSS px, before the rem conversion below):
  //
  //   main axis  — its margin box starts one row gap past the track's right
  //                edge; the left margin walks it back onto the track, and
  //                the two margins together cancel its width and that gap,
  //                so everything after it sits where it sat without it.
  //                The row gap is spacing (the Flutter twin's `Gap`
  //                moves it with the density), so the left margin
  //                subtracts it in CSS through the same spacing variable
  //                rather than as a Dart literal — the rest is pinned.
  //   cross axis — centred in the line like the track, a margin box of zero
  //                height adds nothing to the line; the top margin lifts the
  //                border box to the capsule's top over the track.
  final lensMarginLeftBeforeGap = lensLeft - trackWidth;
  final lensMarginRight = trackWidth - lensLeft - lensWidth;
  final lensMarginTop = lensTop - trackHeight / 2;
  final lensMarginBottom = -lensHeight - lensMarginTop;
  // The lens always travels from the other pose to this one.
  final lensFrom = value ? inactiveThumbOffset : thumbOffset;
  final lensTo = value ? thumbOffset : inactiveThumbOffset;

  // Label foreground colour — disabled state uses the variant
  // `disabledForegroundColor` token, enabled state uses the merged
  // `labelStyle.color` (defaults to `defaultLabelStyle.color`).
  // Always inline.
  final labelColor = enabled
      ? labelStyle.color!
      : variantScale.disabledForegroundColor;

  // The typography role the label wears — the size row's, unless a
  // per-instance override re-tokened it. Emitted as the role class; the
  // overlay scalars (if any) ride inline below.
  final labelRole = labelStyle.token ?? CoreTextStyles.bodySmall;

  // ─── Local builders ───────────────────────────────────

  /// Builds the content wrapper `<span>` Tailwind classes — structural
  /// + typography role. Interaction chrome (cursor / select-none /
  /// press / focus) is owned by the composing `Clickable`. The label gap
  /// and foreground colour live inline (single inline signature).
  String buildRootClassName() {
    // `max-w-full min-w-0` — shrinkable flex item inside the Clickable
    // so a long label wraps within the pane instead of growing past it
    // (the track is `shrink-0`; the label wrapper owns the wrap).
    return '$_kToggleContentMarker ${WebLayout.inlineFlexItemsCenter}'
        ' ${WebLayout.maxWFull} ${WebLayout.minWZero}'
        ' text-${labelRole.name}';
  }

  /// Inline CSS for the content wrapper — gap + label foreground colour
  /// + per-instance `labelStyle` typography overrides (all inline).
  Styles buildRootInlineStyles() {
    final raw = {
      'gap': spaceCss(gap),
      // EMIT Stage 2 (Web, theme-free) — `labelColor` is a token-bound
      // `CoreColor`, so `.toValue()` emits `rgb(var(--coui-X))` and the
      // browser resolves the token (dark-mode reactive) at runtime. The
      // Web side never routes colour through the active scheme (that
      // resolution is a no-op here — CSS variables resolve at runtime).
      'color': labelColor.toValue(),
      // Typography overrides (font-size / font-weight / line-height /
      // letter-spacing / family) keep Flutter parity by emitting every
      // populated override field. Colour is excluded here because the label
      // colour is already emitted above; a duplicate bare colour would
      // conflict.
      ...labelStyle.toInlineCss(includeColor: false),
    };
    return Styles(raw: raw);
  }

  /// Builds the toggle track Tailwind classes — structural + the
  /// per-state background colour token class. The `bg-<token>` class is
  /// included only when the caller did **not** supply a colour override
  /// for the active state (the override then wins inline). All
  /// dimensional chrome (width / height / radius / padding) lives inline.
  String buildTrackClassName() {
    final hasColorOverride =
        enabled &&
        (value ? trackActiveColor != null : trackInactiveColor != null);
    final String bgToken;
    if (!enabled) {
      // Disabled is said by the TRACK — on and off take different tokens.
      bgToken = value
          ? variantScale.disabledActiveTrack.tailwindColor
          : variantScale.disabledInactiveTrack.tailwindColor;
    } else if (value) {
      bgToken = variantScale.activeTrack.tailwindColor;
    } else {
      bgToken = variantScale.inactiveTrack.tailwindColor;
    }

    return <String>[
      // The scoped rules' landing pad (`.scope:hover .co-toggle-track`).
      kToggleTrackMarker,
      if (hasColorOverride) _kToggleOwnedFillMarker,
      'box-border',
      // Visual-only element — cursor / focus ring / press are owned by
      // the composing `Clickable` root, and the track is a plain `<span>`
      // so there is nothing here to suppress.
      'peer ${WebLayout.inlineFlex}',
      '${WebLayout.shrinkZero} ${WebLayout.itemsCenter}',
      // Deliberately NOT taking the contributed boundary — measured, not
      // assumed. A 4px boundary on a 16px track with a 12px thumb leaves
      // no interior for the thumb to sit in; the control reads as a blob.
      // Boxing this needs the switch drawn larger first, which is a
      // decision about the component and not about this axis.
      if (!hasColorOverride) 'bg-$bgToken',
      // The cast the active style contributes to a box that states none —
      // the Flutter twin's track is a composed `OutlinedContainer` at rest
      // elevation, which takes it in every state. A cast is not the
      // boundary above: it adds no layout, so the measurement that keeps
      // the boundary off this track does not reach it. The focus band
      // below restates it beside the band.
      kControlShadowRestMarker,
      // Marks the track as a component surface (the Flutter twin
      // composes `OutlinedContainer` for the same two states — see
      // `activeTrackContainerStyle`/`inactiveTrackContainerStyle`).
      // Disabled is never marked — a disabled control does not read as
      // a floating material surface (mirrors the resolver's
      // `disabled*TrackContainerStyle.surfaceBlur: 0`). Both on/off
      // states carry it: the thumb (never marked, always opaque) already
      // carries the on/off distinction on an axis material cannot dim —
      // `core/theme-axis-composition.md`'s "상태 구분을 색만으로 하지
      // 않는다".
      if (enabled) ...webSurfaceMarkerFor(.content),
    ].join(' ');
  }

  /// Inline CSS for the toggle track — sizing / radius / inner padding /
  /// colour-transition (all inline) plus the per-instance background
  /// colour override when present.
  Styles buildTrackInlineStyles() {
    final effectiveBackground =
        (value ? trackActiveColor : trackInactiveColor) ??
        (value ? variantScale.activeTrack : variantScale.inactiveTrack);
    return .new(
      raw: {
        'width': '${trackWidth / kRemDivisor}rem',
        'height': '${trackHeight / kRemDivisor}rem',
        'border-radius': trackBorderRadius,
        'padding': padding,
        'transition':
            'background-color ${durationMsCss(colorTransitionDurationMs)} '
            '$transitionEasingCss',
        if (enabled &&
            (value ? trackActiveColor : trackInactiveColor) != null) ...{
          'background-color':
              'var($_kToggleStateFillVar, ${effectiveBackground.toValue()})',
          _kToggleHoverFillVar: stateLayerWashCss(
            ink: value ? activeStateLayerColor : inactiveStateLayerColor,
            base: effectiveBackground,
            weight: stateLayer.hover,
          ),
          _kTogglePressedFillVar: stateLayerWashCss(
            ink: value ? activeStateLayerColor : inactiveStateLayerColor,
            base: effectiveBackground,
            weight: stateLayer.pressed,
          ),
        },
        // The other half of the surface marker above — publishes the
        // fill this state chose so a material preset can restate it at
        // its own alpha. Empty (no-op) for a raw colour override with
        // no token.
        if (enabled) ...surfaceFillVar(effectiveBackground),
      },
    );
  }

  /// Builds the toggle thumb Tailwind classes — structural only; the
  /// per-state background colour token class is included unless the
  /// caller supplied a colour override (then the inline rule wins). All
  /// dimensional chrome (size / radius / travel / transition) lives
  /// inline.
  CoreColor defaultThumbColor() {
    if (!enabled) {
      // The off thumb stands off the disabled off track with its own
      // token — the on thumb's `surface` would vanish into it.
      return value
          ? variantScale.disabledThumb
          : variantScale.disabledInactiveThumb;
    }
    return value ? variantScale.activeThumb : variantScale.inactiveThumb;
  }

  String buildThumbClassName() {
    final hasColorOverride =
        enabled &&
        (value ? thumbActiveColor != null : thumbInactiveColor != null);
    final bg = defaultThumbColor();

    return <String>[
      '${WebLayout.pointerEventsNone} ${WebLayout.block}',
      // The thumb cast is emitted inline, independent of the ring.
      'ring-0',
      // A default that is a fixed colour (the white off thumb) has no
      // token class; it is painted inline instead.
      if (!hasColorOverride && bg.token != null) 'bg-${bg.tailwindColor}',
    ].join(' ');
  }

  /// Inline CSS for the toggle thumb — size / radius / travel transform /
  /// transition (all inline) plus the per-instance background colour /
  /// border-radius override when present.
  Styles buildThumbInlineStyles() {
    final override = value ? thumbActiveColor : thumbInactiveColor;
    final bg = defaultThumbColor();
    final translate = value ? thumbOffset : inactiveThumbOffset;
    return .new(
      raw: {
        if (thumbShadow != 'none') 'box-shadow': thumbShadow,
        'width': '${thumbSize / kRemDivisor}rem',
        'height': '${thumbSize / kRemDivisor}rem',
        'border-radius': thumbBorderRadius == null
            ? trackBorderRadius
            : thumbBorderRadius.toValue(),
        'transform': 'translateX(${translate / kRemDivisor}rem)',
        'transition':
            'transform ${durationMsCss(thumbTransitionDurationMs)} '
            '$transitionEasingCss',
        if (enabled && override != null)
          'background-color': override.toValue()
        else if (bg.token == null)
          'background-color': bg.toValue(),
      },
    );
  }

  /// Structural classes plus the floating-surface marker. The marker is
  /// what hands the lens its material — and, through the document's
  /// refraction host, the displacement map built from its own rectangle.
  String buildLensClassName() => <String>[
    '${WebLayout.block} ${WebLayout.shrinkZero} ${WebLayout.pointerEventsNone}',
    ...webSurfaceMarkerFor(.functional),
  ].join(' ');

  /// Geometry, lens chrome, zero base opacity and the fade envelope.
  /// Travel follows the thumb's compositor transition.
  ///
  /// Every chrome field is inline. The fill has to be: a floating material
  /// restates a marked surface's fill from `--coui-surface-rgb`, which a
  /// lens that publishes none inherits from whatever surface it sits in —
  /// only an inline fill keeps that tint off. The rest ride beside it so the
  /// slot reaches the lens on one path.
  ///
  /// `!` is safe on the fields the design default states: `merge` never
  /// clears a field, so they stay set under any override. `surfaceOpacity` /
  /// `surfaceBlur` are the slot's optional knobs and emit only when stated;
  /// the slot's `elevation` is never reached, because the default's explicit
  /// (empty) cast wins over it on both platforms.
  Styles buildLensInlineStyles() {
    final durationCss = durationMsCss(thumbTransitionDurationMs);
    final surfaceOpacity = lensContainer.surfaceOpacity;
    final fill = surfaceOpacity == null
        ? lensContainer.backgroundColor!
        : lensContainer.backgroundColor!.scaleAlpha(surfaceOpacity);
    // An empty cast is no shadow at all — the Flutter twin adds the style's
    // rim only to a stack that casts something, and so does this.
    final cast = lensContainer.boxShadow!;
    final surfaceBlur = lensContainer.surfaceBlur;
    return .new(
      raw: {
        'width': '${lensWidth / kRemDivisor}rem',
        'height': '${lensHeight / kRemDivisor}rem',
        // Pinned: the margins cancel the lens's own footprint, so a
        // re-mapped spacing variable on one of them would unseat it — all
        // but the row gap the left margin walks back across, which is the
        // container's spacing variable and has to stay the same operand.
        'margin':
            '${pinnedLengthCss(lensMarginTop)} '
            '${pinnedLengthCss(lensMarginRight)} '
            '${pinnedLengthCss(lensMarginBottom)} '
            'calc(${pinnedLengthCss(lensMarginLeftBeforeGap)} - '
            '${spaceCss(gap)})',
        'align-self': 'center',
        'background-color': fill.toValue(),
        'border-radius': lensContainer.borderRadius!.toValue(),
        'border-style': lensContainer.borderStyle!.name,
        'border-width': strokeWidthCss(lensContainer.borderWidth!),
        'border-color': lensContainer.borderColor!.toValue(),
        'box-shadow': cast.isEmpty
            ? 'none'
            : '${emitShadow(cast, base: shadowBase)}, $kSurfaceRimVar',
        'padding': lensContainer.padding!.toValue(),
        if (surfaceBlur != null && surfaceBlur > 0)
          'backdrop-filter': 'blur(${surfaceBlur}px)',
        'opacity': '${CoreOpacity.opacity0}',
        kToggleLensFromVar: '${lensFrom / kRemDivisor}rem',
        kToggleLensToVar: '${lensTo / kRemDivisor}rem',
        'animation':
            '$lensEnvelopeKeyframes $durationCss '
            '${CoreEasing.linear.toVarCss()} both',
      },
    );
  }

  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreToggleStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedToggle(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    track: WebElementChrome(
      className: buildTrackClassName(),
      inlineStyles: buildTrackInlineStyles(),
    ),
    thumb: WebElementChrome(
      className: buildThumbClassName(),
      inlineStyles: buildThumbInlineStyles(),
    ),
    lens: WebElementChrome(
      className: buildLensClassName(),
      inlineStyles: buildLensInlineStyles(),
    ),
    clickableStyle: clickableStyle,
    labelWrapper: const WebElementChrome(
      className: WebLayout.minWZero,
    ),
  );
}

/// Resolves the scoped `<style>` rules for `Toggle` — the state-layer
/// wash under a pointer and the focus ring around the track.
///
/// Re-walks the same merge chain [resolveToggle] did so the class-drop
/// condition there and the rules here see one resolved value. Keyed on
/// [value] (the ink and base differ per pose) and gated on [enabled]
/// (empty when disabled).
ResolvedToggleRules resolveToggleRules(
  BuildContext context, {
  required CoreToggleVariant variant,
  required bool value,
  required bool enabled,
  CoreToggleStyle? toggleStyle,
}) {
  if (!enabled) return const ResolvedToggleRules(scopeClass: '', css: '');

  final csTheme = context.theme.coreComponentTheme?.toggle;
  final merged = resolveStyleChain(const CoreToggleStyle(), [
    csTheme?.style,
    csTheme?.variantStyles?[variant],
    toggleStyle,
  ]);
  final variantScale = CoreToggleStyle.defaultsByVariant[variant]!;

  // ─── Stage 1 RESOLVE ──────────────────────────────────
  final base = value
      ? merged.trackActiveColor ?? variantScale.activeTrack
      : merged.trackInactiveColor ?? variantScale.inactiveTrack;
  final ink = value
      ? merged.stateLayerActiveColor ?? variantScale.activeStateLayer
      : merged.stateLayerInactiveColor ?? variantScale.inactiveStateLayer;
  final layer = merged.stateLayer ?? CoreToggleStyle.defaultStateLayer;
  final ownsBase = value
      ? merged.trackActiveColor != null
      : merged.trackInactiveColor != null;
  final hoverFillCss = ownsBase
      ? 'var($_kToggleHoverFillVar)'
      : stateLayerWashCss(ink: ink, base: base, weight: layer.hover);
  final pressedFillCss = ownsBase
      ? 'var($_kTogglePressedFillVar)'
      : stateLayerWashCss(ink: ink, base: base, weight: layer.pressed);
  // The ring around the track — the toggle's own nested slot, raw-forwarded
  // to `FocusOutline`'s rules resolver so the offset band / ring width /
  // colours settle where every other ring in the kit settles them, and the
  // CSS comes from the one scoped-ring emitter. Its target is the track
  // one level inside the `Clickable` root the pseudo-class lands on; the
  // Flutter twin wraps the track in the `FocusOutline` widget with the
  // same slot.
  //
  // A painted band is a `box-shadow` layer, and it replaces the track's
  // `box-shadow` wholesale — so the track's rest cast (the style's
  // contributed one) rides behind the band, the way the Flutter twin's
  // track keeps its container's cast under the ring. No rim: the track
  // casts no shadow of its own, and a rim decorates one that does. A
  // band-less ring writes no `box-shadow` and leaves the cast alone.
  final focusOutlineStyle = CoreToggleStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );

  // The ring's rule text, written once against a placeholder scope: the
  // text keys the scope class below (so it is content-addressed off the
  // exact ring that settled, theme included), and the placeholder is then
  // swapped for that class. A `hashCode` of the style would not do — a
  // value-type hash is seeded per run, and the class must be the same on
  // the server and in the browser.
  const scopePlaceholder = '\u0000';
  const track = ' > :where(.$_kToggleContentMarker) > .$kToggleTrackMarker';
  // Same-colour implicit/explicit tracks may share a content scope. The
  // zero-specificity mode guard keeps override-only values on owned faces.
  final paintTrack = ownsBase
      ? '$track:where(.$_kToggleOwnedFillMarker)'
      : '$track:where(:not(.$_kToggleOwnedFillMarker))';
  final ringRule = resolveFocusOutlineRules(
    context,
    scopeSelector: scopePlaceholder,
    pseudo: .focusVisible,
    target: track,
    restShadow: kControlShadowVar,
    focusOutlineStyle: focusOutlineStyle,
  ).css;

  // Content-addressed off the exact values the rules below depend on —
  // two toggles that resolve identically share one class and one rule
  // instead of emitting a duplicate per instance.
  final seed =
      '${ink.token?.name}|${ink.argb}|${base.token?.name}|${base.argb}'
      '|${base.opacity}|${layer.hover}|${layer.pressed}|$ringRule';
  final scopeClass =
      'co-toggle-sl-${seed.hashCode.toRadixString(36).replaceAll('-', 'n')}';
  final scope = '.$scopeClass';

  // ─── Stage 2 EMIT — scoped rules ──────────────────────
  // hover → active, so equal-specificity ties resolve to the later rule —
  // a held toggle must not step DOWN to the hover weight while the
  // pointer is still over it. The direct content/track path owns this
  // host's paint and ring; prefix/suffix slots may contain another Toggle
  // whose track must not take an ancestor's state.
  final buffer = StringBuffer();
  // A track owns its state value even inside another Toggle's slot. The
  // reset is value-free and contributes no selector specificity.
  if (ownsBase) buffer.write(_kToggleStateResetRule);
  final paintProperty = ownsBase ? _kToggleStateFillVar : 'background-color';
  buffer
    ..write('$scope:hover$paintTrack{$paintProperty:$hoverFillCss;}')
    ..write('$scope:active$paintTrack{$paintProperty:$pressedFillCss;}')
    ..write(ringRule.replaceAll(scopePlaceholder, scope));

  // The lens's keyframes. Its endpoints live on the lens element, so the
  // travel is the same text for every toggle; the envelope is the Flutter
  // twin's — in over the first `lensFadeFraction` of the travel, held, out
  // over the last — and is named for its fraction, which the lens's
  // `animation` names too.
  //
  // A stage of no length is left out rather than written as a doubled stop:
  // at `0` the lens is shown for the whole travel (two stops at one offset
  // would cascade to the later one and fade it out instead), and at the
  // bound the two holds meet in one stop.
  const opaque = CoreOpacity.opacity100;
  const clear = CoreOpacity.opacity0;
  final lensFadeFraction = _settledLensFadeFraction(merged);
  final fadeIn = lensFadeFraction * kPercentScale;
  final fadeOut = (1 - lensFadeFraction) * kPercentScale;
  final envelope = StringBuffer(
    '@keyframes ${toggleLensEnvelopeKeyframes(lensFadeFraction)}{ ',
  );
  if (lensFadeFraction > 0) {
    envelope.write('0%{opacity:$clear;} $fadeIn%{opacity:$opaque;} ');
    if (fadeOut > fadeIn) envelope.write('$fadeOut%{opacity:$opaque;}');
    envelope.write('100%{opacity:$clear;}}');
  } else {
    envelope.write('0%{opacity:$opaque;} 100%{opacity:$opaque;}}');
  }
  // Position follows the thumb's composited rectangle. Separate endpoint
  // keyframes would restart from a resting endpoint on a rapid reversal.
  final lensCss = envelope.toString();

  return ResolvedToggleRules(
    scopeClass: scopeClass,
    css: buffer.toString(),
    lensCss: lensCss,
  );
}

/// Resolves the behaviour timing for `Toggle` — walks the same merge chain
/// as [resolveToggle] but yields only how long the transient lens lives.
ResolvedToggleTiming resolveToggleTiming(
  BuildContext context, {
  required CoreToggleVariant variant,
  CoreToggleStyle? toggleStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.toggle;
  final merged = resolveStyleChain(const CoreToggleStyle(), [
    csTheme?.style,
    csTheme?.variantStyles?[variant],
    toggleStyle,
  ]);
  final lensLifetime =
      merged.thumbTransitionDuration ??
      CoreToggleStyle.defaultThumbTransitionDuration;
  return ResolvedToggleTiming(lensLifetime: lensLifetime);
}
