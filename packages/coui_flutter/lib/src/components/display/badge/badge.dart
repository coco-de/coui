import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform badge with token-based rendering.
///
/// Every chrome / dimensional / nested-slot override flows through the
/// single [badgeStyle] (a [CoreBadgeStyle]). The design axes (`tone` /
/// `variant` / `form` / `size` / `showDot`) and behaviour fields (`child` /
/// `leading` / `trailing` / `onPressed`) stay flat on the widget.
///
/// ```text
/// design system default for size × form × tone × variant
///   → CoreBadgeTheme.style                  // 프로젝트 공통
///   → CoreBadgeTheme.toneStyles[tone]
///   → CoreBadgeTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.badgeStyle                     // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// // A status label — tonal, a word, md.
/// Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('Done'))
///
/// // An unread count.
/// Badge(
///   tone: CoreBadgeTone.info,
///   variant: CoreBadgeVariant.filled,
///   form: CoreBadgeForm.count,
///   size: CoreComponentSize.xs,
///   child: Text('3'),
/// )
/// ```
///
/// surface:behind — whatever the badge is set inline against (a
/// sentence, a card, the page). It draws its own box rather than
/// composing `OutlinedContainer` — the Web twin's root is a fixed
/// `<span>`, and wrapping that in `OutlinedContainer`'s `<div>` breaks
/// the inline flow a badge is meant to sit in (#4358) — so the marker
/// is restated here directly, the same restatement Button (#4360) does
/// for the same "can't compose" reason.
///
/// surface:content — a label-sized chip in the content layer, not a
/// floating affordance: no sticky, fixed, or overlay mount on either
/// platform.
class Badge extends StatefulWidget implements CoreBadgeContract<Widget> {
  /// Creates a [Badge].
  const Badge({
    this.tone = CoreBadgeTone.defaultTone,
    this.variant = CoreBadgeVariant.defaultVariant,
    this.child,
    super.key,
    this.form = CoreBadgeForm.defaultForm,
    this.size = CoreBadgeContract.defaultSize,
    this.showDot = CoreBadgeContract.defaultShowDot,
    this.leading,
    this.trailing,
    this.onPressed,
    this.badgeStyle,
  });

  @override
  final CoreBadgeTone tone;

  @override
  final CoreBadgeVariant variant;

  @override
  final Widget? child;

  @override
  final CoreBadgeForm form;

  @override
  final CoreComponentSize size;

  @override
  final bool showDot;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  @override
  final VoidCallback? onPressed;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `labelStyle` / `iconStyle` slot styles. See [CoreBadgeStyle] for
  /// the merge chain.
  @override
  final CoreBadgeStyle? badgeStyle;

  /// Returns a copy of this [Badge] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Badge copyWith({
    Key? key,
    CoreBadgeTone? tone,
    CoreBadgeVariant? variant,
    CoreBadgeForm? form,
    CoreComponentSize? size,
    bool? showDot,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onPressed,
    CoreBadgeStyle? badgeStyle,
    Widget? child,
  }) {
    return Badge(
      tone: tone ?? this.tone,
      variant: variant ?? this.variant,
      key: key ?? this.key,
      form: form ?? this.form,
      size: size ?? this.size,
      showDot: showDot ?? this.showDot,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      onPressed: onPressed ?? this.onPressed,
      badgeStyle: badgeStyle ?? this.badgeStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Badge> createState() => _BadgeState();
}

class _BadgeState extends State<Badge> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  void _handleHover(bool hovered) {
    if (hovered == _isHovered) return;
    setState(() => _isHovered = hovered);
  }

  void _handlePressedChange(bool pressed) {
    if (pressed == _isPressed) return;
    setState(() => _isPressed = pressed);
  }

  void _handleFocus(bool focused) {
    if (focused == _isFocused) return;
    setState(() => _isFocused = focused);
  }

  @override
  Widget build(BuildContext context) {
    // Single-entry-point resolve — encapsulates theme.coreComponentTheme
    // access and the size / form / tone / variant tables inside
    // badge_style.dart.
    final resolved = resolveBadge(
      context,
      tone: widget.tone,
      variant: widget.variant,
      form: widget.form,
      size: widget.size,
      badgeStyle: widget.badgeStyle,
    );

    final interactive = widget.onPressed != null;
    final borderRadius = resolved.borderRadius;

    // The state layer is pre-baked by the resolver; the widget selects
    // between the three fills, strongest state first. Only an interactive
    // badge has states — a static one always paints its resting fill.
    // Focus selects no fill: the ring is the focus indicator.
    final Color backgroundColor;
    if (interactive && _isPressed) {
      backgroundColor = resolved.pressedBackgroundColor;
    } else if (interactive && _isHovered) {
      backgroundColor = resolved.hoverBackgroundColor;
    } else {
      backgroundColor = resolved.backgroundColor;
    }

    final isDot = widget.form == CoreBadgeForm.dot;
    // The leading status dot is drawn by the label and count forms only — a
    // dot form is a dot already.
    final drawsLeadingDot = widget.showDot && !isDot;

    // A dot draws no content row at all — not an empty one. An empty
    // Row still consults padding and would make the box the padding's
    // size instead of the step's, which is the one thing the dot form
    // exists to state.
    final content = isDot
        ? null
        : Row(
            mainAxisSize: .min,
            // Centred on both axes: the box is at least the step tall (and,
            // for a count, at least that wide), so content smaller than the
            // box sits in its middle rather than at its start.
            mainAxisAlignment: .center,
            children: [
              if (drawsLeadingDot) ...[
                SizedBox.square(
                  dimension: resolved.leadingDotSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: resolved.leadingDotColor,
                      shape: .circle,
                    ),
                  ),
                ),
                Gap(gapStyle: resolved.iconLabelGapStyle),
              ],
              if (widget.leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: resolved.iconSize,
                    color: resolved.iconColor,
                  ),
                  child: widget.leading!,
                ),
                Gap(gapStyle: resolved.iconLabelGapStyle),
              ],
              // `child` is nullable so the dot form can exist; a label or
              // count badge without one collapses to its padding, which is
              // the caller's mistake to see rather than a hole to paper
              // over here.
              if (widget.child != null)
                // Keep a caller's existing flex contract; nesting two Flexible
                // parents would apply competing ParentData to the same child.
                if (widget.child is! Flexible)
                  Flexible(
                    child: DefaultTextStyle.merge(
                      style: resolved.labelTextStyle,
                      maxLines: widget.form == CoreBadgeForm.count ? 1 : null,
                      overflow: widget.form == CoreBadgeForm.count
                          ? TextOverflow.ellipsis
                          : null,
                      child: widget.child!,
                    ),
                  )
                else
                  DefaultTextStyle.merge(
                    style: resolved.labelTextStyle,
                    maxLines: widget.form == CoreBadgeForm.count ? 1 : null,
                    overflow: widget.form == CoreBadgeForm.count
                        ? TextOverflow.ellipsis
                        : null,
                    child: widget.child!,
                  ),
              if (widget.trailing != null) ...[
                Gap(gapStyle: resolved.iconLabelGapStyle),
                IconTheme(
                  data: IconThemeData(
                    size: resolved.iconSize,
                    color: resolved.iconColor,
                  ),
                  child: widget.trailing!,
                ),
              ],
            ],
          );

    final box = AnimatedContainer(
      // The form's size rule — a floor of the step's height for a word, the
      // same floor on both axes for a number, the step's square for a dot.
      constraints: resolved.constraints,
      padding: resolved.padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: resolved.borderColor != null
            ? Border.all(
                color: resolved.borderColor!,
                width: resolved.borderWidth,
              )
            : null,
        borderRadius: borderRadius,
      ),
      duration: resolved.transitionDuration,
      curve: resolved.curve,
      child: content,
    );

    // The rest of the surface material, around the box. The fill share is
    // already folded into every fill; this adds what a fill cannot carry —
    // the frost, the chroma, the dimming, the edge light and the bend — the
    // way the Web twin's surface marker gets them from the style rule.
    // Wrapped only when the style states something to draw, so every other
    // style keeps the tree it had.
    final surfaceBlur = resolved.surfaceBlur;
    final materialBox =
        (surfaceBlur != null && surfaceBlur > 0) ||
            resolved.surfaceSheen != null
        ? SurfaceBlur(
            borderRadius: borderRadius,
            surfaceBlur: surfaceBlur,
            surfaceSaturation: resolved.surfaceSaturation,
            surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
            surfaceSheen: resolved.surfaceSheen,
            refraction: Theme.of(context).surfaceRefraction,
            child: box,
          )
        : box;

    // Cast painted outside the box rather than behind it. The outlined
    // variant carries no fill, and the washed fills are translucent over an
    // unfilled badge, so a cast drawn behind the box would show through it.
    // Wrapped for every variant rather than only the unfilled one — a
    // per-variant branch here is the shape that already went wrong once,
    // where the cast reached one branch and left the other flat. Outside
    // the material too, so the frost stays inside the box and the cast
    // keeps painting beyond it.
    final badge = InjectedCast(
      shadows: resolved.boxShadow,
      borderRadius: borderRadius,
      child: materialBox,
    );

    if (!interactive) {
      return badge;
    }

    // Interactive badge — the unified [Clickable] owns hover / press /
    // focus / click / cursor detection (+ keyboard Enter/Space
    // activation). Press-scale is suppressed (`pressedScale: 1.0`) and the
    // badge keeps its own focus ring (`focusOutline: false` +
    // [FocusOutline] from the merged `focusOutlineStyle` slot, mirroring
    // the Web focus ring).
    // `TouchTarget` only on the interactive path, and it wraps rather
    // than resizes: the dot form draws as small as 4 logical px, which
    // no pointer lands on reliably (WCAG 2.5.8). The drawing is the
    // designer's; the region that accepts a press is ours to widen.
    // Where the badge is already large enough the expansion is zero,
    // and a non-interactive badge accepts nothing so it needs none —
    // the same shape Checkbox and Toggle use.
    return TouchTarget(
      child: Clickable(
        onPressed: widget.onPressed,
        onHover: _handleHover,
        onFocus: _handleFocus,
        onPressedChange: _handlePressedChange,
        focusOutline: false,
        enableFeedback: false,
        clickableStyle: const CoreClickableStyle(pressedScale: 1),
        child: FocusOutline(
          focused: _isFocused,
          focusOutlineStyle: resolved.focusOutlineStyle,
          child: badge,
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreBadgeStyle] patch into
/// [Badge.badgeStyle] without hand-reconstructing every field. Mirrors
/// the Web `Badge.withStyle` extension so both platforms read
/// identically. Composition slots (`child` / `leading` / `trailing`)
/// keep using the `Text(...).bodyMedium...` chain directly — this
/// extension only covers the [CoreBadgeStyle] chrome slot.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBadgeStyle.merge` right-side-wins semantics).
///
/// ```dart
/// Badge(child: Text('New')).withStyle(
///   CoreBadgeStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
/// )
/// ```
///
/// `.primary`, `.info`, `.success`, `.warning`, `.outline` select component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension BadgeStyleChain on Badge {
  /// Sets the background paint and preserves the other style fields.
  Badge backgroundColor(CoreColor value) =>
      withStyle(CoreBadgeStyle(backgroundColor: value));

  /// Sets the padding around label or count content.
  Badge contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreBadgeStyle(padding: value));

  /// Sets the border color.
  Badge borderColor(CoreColor value) =>
      withStyle(CoreBadgeStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  Badge borderWidth(double value) =>
      withStyle(CoreBadgeStyle(borderWidth: value));

  /// Sets the foreground color of the content.
  Badge foregroundColor(CoreColor value) =>
      withStyle(CoreBadgeStyle(foregroundColor: value));

  /// Returns a copy of this [Badge] with [patch] merged into
  /// [badgeStyle] (patch fields win on conflict).
  Badge withStyle(CoreBadgeStyle patch) =>
      copyWith(badgeStyle: (badgeStyle ?? const CoreBadgeStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Badge get radius0 => withStyle(
    const CoreBadgeStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Badge get radius2 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Badge get radius4 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Badge get radius6 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Badge get radius8 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Badge get radius10 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Badge get radius12 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Badge get radius14 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Badge get radius16 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Badge get radius20 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Badge get radius24 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Badge get radius28 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Badge get radius32 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Badge get radius36 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Badge get radius40 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Badge get radius48 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Badge get radius56 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Badge get radius64 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Badge get radius9999 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// Selects `tone: .primary` using the component theme.
  Badge get primary => copyWith(tone: .primary);

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Badge get secondary => withStyle(
    const CoreBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Badge get tertiary => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Badge get surface => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Badge get surfaceContainer => withStyle(
    const CoreBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Badge get error => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// Selects `tone: .success` using the component theme.
  Badge get success => copyWith(tone: .success);

  /// Selects `tone: .warning` using the component theme.
  Badge get warning => copyWith(tone: .warning);

  /// Selects `tone: .info` using the component theme.
  Badge get info => copyWith(tone: .info);

  /// Selects `variant: .outlined` using the component theme.
  Badge get outline => copyWith(variant: .outlined);

  /// `backgroundColor: CoreColor.transparent`.
  Badge get transparent =>
      withStyle(const CoreBadgeStyle(backgroundColor: .transparent));
}
