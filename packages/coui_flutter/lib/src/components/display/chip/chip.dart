import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform chip with token-based rendering.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [chipStyle] (a [CoreChipStyle]). The
/// semantic enums (`chipColor` / `variant` / `emphasis` / `size` /
/// `shape` / `selected` / `enabled`) and behaviour fields stay flat on the
/// widget.
///
/// ```text
/// design system default for chip
///   → CoreChipTheme.style
///   → CoreChipTheme.colorStyles[chipColor]
///   → CoreChipTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.chipStyle
/// ```
///
/// `Chip` is render-only — [resolveChip] runs the merge chain plus
/// the per-variant / per-state colour resolution once and returns
/// paint-ready Flutter values; `build` reads those directly without
/// touching `coreComponentTheme` or selecting state colours itself.
///
/// Example:
/// ```dart
/// Chip(
///   label: 'Flutter',
///   chipColor: CoreChipColor.primary,
///   selected: true,
///   onTap: () => toggle(),
/// )
/// ```
class Chip extends StatelessWidget implements CoreChipContract<Widget> {
  /// Creates a [Chip].
  const Chip({
    this.prefixLabel,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    super.key,
    this.child,
    this.chipColor = CoreChipColor.defaultColor,
    this.variant = CoreChipVariant.defaultVariant,
    this.emphasis = CoreChipEmphasis.defaultEmphasis,
    this.selected = false,
    this.enabled = true,
    this.size = CoreChipSize.defaultSize,
    this.shape = CoreChipShape.defaultShape,
    this.leading,
    this.trailing,
    this.onTap,
    this.onRemove,
    this.seedColor,
    this.maxLength,
    this.chipStyle,
  });

  // === State ===

  @override
  final bool selected;

  @override
  final bool enabled;

  @override
  final VoidCallback? onTap;

  @override
  final VoidCallback? onRemove;

  // === Content ===

  @override
  final String? prefixLabel;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final Widget? child;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  // === Size & Visual ===

  @override
  final CoreChipColor chipColor;

  @override
  final CoreChipVariant variant;

  @override
  final CoreChipEmphasis emphasis;

  @override
  final CoreChipSize size;

  /// The outline — [CoreChipShape.rounded] (the size row's corner, the
  /// default) or [CoreChipShape.pill] (half-circle ends on every size). A
  /// corner stated through [chipStyle] wins over both.
  @override
  final CoreChipShape shape;

  @override
  final CoreColor? seedColor;

  @override
  final int? maxLength;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `labelStyle` / `leadingIconStyle` / `trailingIconStyle` /
  /// `closeButtonStyle` slot styles. See [CoreChipStyle] for the
  /// merge chain.
  @override
  final CoreChipStyle? chipStyle;

  /// Returns a copy of this [Chip] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Chip copyWith({
    Key? key,
    VoidCallback? onTap,
    String? prefixLabel,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    CoreChipColor? chipColor,
    CoreChipVariant? variant,
    CoreChipEmphasis? emphasis,
    bool? selected,
    bool? enabled,
    CoreChipSize? size,
    CoreChipShape? shape,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onRemove,
    CoreColor? seedColor,
    int? maxLength,
    CoreChipStyle? chipStyle,
    Widget? child,
  }) {
    return Chip(
      key: key ?? this.key,
      onTap: onTap ?? this.onTap,
      prefixLabel: prefixLabel ?? this.prefixLabel,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      chipColor: chipColor ?? this.chipColor,
      variant: variant ?? this.variant,
      emphasis: emphasis ?? this.emphasis,
      selected: selected ?? this.selected,
      enabled: enabled ?? this.enabled,
      size: size ?? this.size,
      shape: shape ?? this.shape,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      onRemove: onRemove ?? this.onRemove,
      seedColor: seedColor ?? this.seedColor,
      maxLength: maxLength ?? this.maxLength,
      chipStyle: chipStyle ?? this.chipStyle,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // `filled` + `low` still renders; it is a poor pair, not an illegal one,
    // so debug builds report it rather than throw (an assertion failure here
    // would replace the whole subtree with an error). Absent from release.
    assert(() {
      if (variant == .filled &&
          emphasis == .low &&
          (selected || onTap != null)) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError(CoreChipContract.filledLowEmphasisReport),
            library: 'coui_flutter',
            context: ErrorDescription('while building a Chip'),
          ),
        );
      }
      return true;
    }(), 'debug-only report; never fails');

    // The resolver encapsulates `theme.coreComponentTheme.chip` access
    // (merge chain + effective chipColor / variant / size / shape) plus the
    // per-colour / per-state colour resolution — `build` only reads
    // paint-ready values.
    final resolved = resolveChip(
      context,
      chipColor: chipColor,
      variant: variant,
      emphasis: emphasis,
      size: size,
      shape: shape,
      selected: selected,
      enabled: enabled,
      seedColor: seedColor,
      chipStyle: chipStyle,
    );

    // ─── Paint-ready chrome (scaling applied at use site) ─────────
    final iconLabelGapStyle = resolved.iconLabelGapStyle;
    final leadingIconSize = resolved.leadingIconSize;
    final trailingIconSize = resolved.trailingIconSize;

    // ─── Label text ──────────────────────────────────────────────
    final String? displayLabel;
    if (label != null && maxLength != null && label!.length > maxLength!) {
      displayLabel = '${label!.substring(0, maxLength)}...';
    } else {
      displayLabel = label;
    }

    final labelWidget =
        child ??
        (displayLabel != null
            ? Text(
                displayLabel,
                style: resolved.labelTextStyle,
                overflow:
                    (labelOverflow ?? CoreChipContract.defaultLabelOverflow)
                        .toValue(),
                maxLines:
                    labelMaxLines ?? CoreChipContract.defaultLabelMaxLines,
              )
            : null);

    // Close button via the unified Button (variant: ghost) so
    // hover / focus / disabled states are handled by the design-system
    // component instead of a hand-rolled GestureDetector + raw Icon.
    // The resolved closeButtonStyle slot is forwarded to Button so
    // chrome tweaks (padding, borderRadius, iconStyle) flow through.
    final Widget? closeButton;
    if (onRemove != null && enabled) {
      final l10n = CoUILocalizations.of(context);
      // Named, because the glyph carries no text of its own. A row of
      // chips otherwise announces as a row of identical unnamed buttons
      // and the reader cannot tell which one it is about to remove. The
      // name is read at build time, not defaulted in the constructor —
      // a const default cannot reach the active locale.
      final namedClose = Semantics(
        button: true,
        label: l10n.chipRemoveLabel(
          CoreChipContract.accessibleName(
            prefixLabel: prefixLabel,
            label: label,
          ),
        ),
        child: Button(
          onPressed: onRemove,
          variant: .ghost,
          size: .sm,
          buttonStyle: resolved.closeButtonStyle,
          // No explicit colour — the glyph inherits Button's per-state
          // `IconTheme` (idle = chip foreground bound in the resolver,
          // hover = `hoverForegroundColor`), matching the Web twin's
          // `currentColor` inheritance.
          child: Icon(LucideIcons.x, iconStyle: resolved.closeIconStyle),
        ),
      );
      // The reach floor rides the close button only when the chip itself
      // carries none. A tappable chip's `TouchTarget` below already
      // covers the whole chip, and a second floor nested inside it would
      // extend the remove target over the label — a tap near the X would
      // remove the chip instead of selecting it (the Web twin hits the
      // same constraint, #3705). A display-only chip — every chip a
      // `ChipInput` renders — skips that wrapper, yet its remove button is
      // still a pointer target, overridden down to 16.
      closeButton = onTap == null ? TouchTarget(child: namedClose) : namedClose;
    } else {
      closeButton = null;
    }

    final chipContent = Row(
      mainAxisSize: .min,
      mainAxisAlignment: resolved.contentAlignment,
      children: [
        if (leading != null) ...[
          IconTheme(
            data: IconThemeData(
              size: leadingIconSize,
              color: resolved.leadingIconColor,
            ),
            child: leading!,
          ),
          Gap(gapStyle: iconLabelGapStyle),
        ],
        // The key holds its width and its single line; the value is the
        // half that yields to a narrow row (`Flexible` below). Separated by
        // the same gap as the icons.
        if (prefixLabel != null) ...[
          Text(
            prefixLabel!,
            style: resolved.prefixLabelTextStyle,
            maxLines: 1,
            softWrap: false,
          ),
          if (labelWidget != null) Gap(gapStyle: iconLabelGapStyle),
        ],
        if (labelWidget != null) Flexible(child: labelWidget),
        if (trailing != null) ...[
          Gap(gapStyle: iconLabelGapStyle),
          IconTheme(
            data: IconThemeData(
              size: trailingIconSize,
              color: resolved.trailingIconColor,
            ),
            child: trailing!,
          ),
        ],
        if (closeButton != null) ...[
          Gap(gapStyle: iconLabelGapStyle),
          closeButton,
        ],
      ],
    );

    // Composed `OutlinedContainer` chip surface (background / border /
    // radius / padding) — not a hand-rolled
    // `Container(decoration: BoxDecoration(...))`. The chip's own
    // press/hover cast is painted by the separate `InjectedCast` layer
    // below, not by this primitive (its `containerStyle` carries an
    // explicit empty `boxShadow` override).
    final box = ConstrainedBox(
      constraints: BoxConstraints(minHeight: resolved.minHeight),
      child: OutlinedContainer(
        containerStyle: resolved.containerStyle,
        child: chipContent,
      ),
    );

    // Display-only chip (`onTap == null`, e.g. inside a chip input) —
    // plain container, no button semantics / cursor / focus ring
    // pollution. Mirrors the Web widget's conditional wrap.
    //
    // Cast painted outside the box rather than behind it. This surface is
    // transparent by default, so a cast drawn behind it has nothing
    // painting over it and a hard opaque cast fills the whole chip. CSS
    // clips an outer shadow to outside the border box, so the Web twin
    // never did. Nothing presses this branch, so it can never engage —
    // a `reverse` chip here stays permanently hidden (there is no engage
    // to grow it on) rather than showing a cast that looks neither at
    // rest nor engaged.
    if (onTap == null) {
      return InjectedCast(
        shadows: resolved.boxShadow,
        borderRadius: resolved.castBorderRadius,
        visible: !resolved.reverseCastMotion,
        child: box,
      );
    }

    // Flutter twin of the Web chip: the composed Clickable owns tap /
    // keyboard activation / cursor / press feedback / focus ring (no
    // hand-rolled GestureDetector + MouseRegion). The chip paints its
    // own disabled tokens, so the nested clickableStyle slot keeps the
    // Clickable's generic disabled fade off.
    // The touch target wraps only the tappable branch — a display-only
    // chip has nothing to reach. Every size row is at least 28 tall,
    // above the 24 pointer minimum, so the floor widens nothing on the
    // default rows; it reaches a chip narrower than 24 (a one-character
    // `sm` label) or one whose caller states a lower `minHeight`.
    return _PressableChip(
      onPressed: enabled ? onTap : null,
      shadows: resolved.boxShadow,
      reverseCastMotion: resolved.reverseCastMotion,
      borderRadius: resolved.castBorderRadius,
      clickableStyle: resolved.clickableStyle,
      castHideDuration: resolved.castHideDuration,
      enabled: enabled,
      // The four already-resolved container styles, not a pre-built box:
      // which one paints is `_PressableChipState`'s call (it owns
      // `_pressed`/`_focused`/`_hovered`), so the `OutlinedContainer` has
      // to be built down there. Handing this widget a finished `box`
      // the way the display-only branch above does would leave no seam
      // to select from — the state layer would have nowhere to land.
      containerStyle: resolved.containerStyle,
      hoverContainerStyle: resolved.hoverContainerStyle,
      focusContainerStyle: resolved.focusContainerStyle,
      pressedContainerStyle: resolved.pressedContainerStyle,
      minHeight: resolved.minHeight,
      content: chipContent,
    );
  }
}

/// The tappable chip: the box, its cast, and the engage (hover or press)
/// that moves one into the other.
///
/// Split out rather than making [Chip] stateful, because the engage
/// flags are the only state the chip has and they are needed in one
/// place. A `StatefulWidget` around the whole build would put `widget.`
/// in front of every field for two booleans.
class _PressableChip extends StatefulWidget {
  const _PressableChip({
    required this.shadows,
    required this.reverseCastMotion,
    required this.borderRadius,
    required this.clickableStyle,
    required this.castHideDuration,
    required this.onPressed,
    required this.enabled,
    required this.containerStyle,
    required this.hoverContainerStyle,
    required this.focusContainerStyle,
    required this.pressedContainerStyle,
    required this.minHeight,
    required this.content,
  });

  final List<BoxShadow> shadows;

  /// See [ResolvedChip.minHeight] — the same floor the display-only
  /// branch applies, so a tappable chip is never shorter than a plain one.
  final double minHeight;

  /// Mirrors [ResolvedChip.reverseCastMotion] — flips the
  /// `InjectedCast.visible` polarity below from hide-on-engage to
  /// show-on-engage.
  final bool reverseCastMotion;
  final BorderRadius borderRadius;
  final CoreClickableStyle clickableStyle;

  /// See [ResolvedChip.castHideDuration] — the reduced-motion-aware
  /// clock the cast hides on.
  final Duration castHideDuration;
  final void Function()? onPressed;
  final bool enabled;

  /// Box chrome at rest — also the disabled chrome, since
  /// [ResolvedChip.containerStyle] is already resolved against the
  /// disabled tokens when the chip is disabled. Selected whenever none
  /// of the three engaged states below applies.
  final CoreOutlinedContainerStyle containerStyle;

  /// Box chrome while the pointer is over the chip.
  final CoreOutlinedContainerStyle hoverContainerStyle;

  /// Box chrome while the chip holds keyboard focus.
  final CoreOutlinedContainerStyle focusContainerStyle;

  /// Box chrome while the chip is held down.
  final CoreOutlinedContainerStyle pressedContainerStyle;

  /// The row (leading / label / trailing / close) the selected chrome
  /// wraps — not a finished `OutlinedContainer`, because which chrome
  /// wraps it is this state's own call.
  final Widget content;

  @override
  State<_PressableChip> createState() => _PressableChipState();
}

class _PressableChipState extends State<_PressableChip> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    // Same value Button folds `_pressed`/`_hovered` into — press always
    // counts, and hover counts too (desktop only: Flutter never
    // dispatches hover on touch, so this is press-only on mobile with no
    // platform branch). Gates the cast-hide below and, via
    // `engageOnHover`, the Clickable's own shift — one value driving
    // both halves is what keeps them from drifting apart.
    final engaged = widget.enabled && (_pressed || _hovered);

    // The cast sits *inside* the Clickable, so the travel moves it along
    // with the box. That is only harmless because the cast hides on the
    // same clock — otherwise the chip would read as sliding rather than
    // as sinking into the space its shadow held. Button pairs these two
    // the same way and for the same reason.
    //
    // `widget.castHideDuration` is the press clock, deliberately not the
    // chip's `transitionDuration` — that one is the hover/selected
    // speed, and hiding a shadow on it would lag the travel. Already
    // routed through `resolveMotionDuration` by the resolver (see
    // `ResolvedChip.castHideDuration`), so it collapses under reduced
    // motion the same way Button's does.
    //
    // `engageOnHover: true` is safe unconditionally — Clickable's own
    // `shifts` gate already no-ops it whenever `pressedTranslate` is
    // zero (every style with no cast-motion vocabulary), the same
    // reasoning Button's identical wiring relies on.
    //
    // `widget.reverseCastMotion` flips which half of the pair is
    // visible — see `Button`'s identical `castVisible` in `button.dart`.
    final castVisible = widget.reverseCastMotion ? engaged : !engaged;

    // Selecting between four already-resolved bundles — never composing
    // chrome here, matching `widget/render-only.md`'s "이미 resolved 된
    // 번들 중 select" allowance. Strongest state wins, same order Button
    // reads its own ramp in: a chip held down does not step back to its
    // hover wash on release-adjacent frames just because the pointer is
    // still over it, and a disabled chip never engages at all (`enabled`
    // gates first — `containerStyle` is already the disabled chrome in
    // that case, resolved against the disabled tokens upstream).
    final CoreOutlinedContainerStyle containerStyle;
    if (!widget.enabled) {
      containerStyle = widget.containerStyle;
    } else if (_pressed) {
      containerStyle = widget.pressedContainerStyle;
    } else if (_focused) {
      containerStyle = widget.focusContainerStyle;
    } else if (_hovered) {
      containerStyle = widget.hoverContainerStyle;
    } else {
      containerStyle = widget.containerStyle;
    }
    final box = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      child: OutlinedContainer(
        containerStyle: containerStyle,
        child: widget.content,
      ),
    );

    return TouchTarget(
      child: Clickable(
        onPressed: widget.onPressed,
        onPressedChange: (pressed) {
          if (pressed == _pressed) return;
          setState(() => _pressed = pressed);
        },
        onHover: (hovered) {
          if (hovered == _hovered) return;
          setState(() => _hovered = hovered);
        },
        // The focus rung of the ramp. Without it the wash starts at 0
        // for a focused chip, so hovering one would make the focus
        // state APPEAR — focus reading as weaker than hover.
        onFocus: (focused) {
          if (focused == _focused) return;
          setState(() => _focused = focused);
        },
        enabled: widget.enabled,
        engageOnHover: true,
        clickableStyle: widget.clickableStyle,
        child: InjectedCast(
          shadows: widget.shadows,
          borderRadius: widget.borderRadius,
          visible: castVisible,
          duration: widget.castHideDuration,
          child: box,
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreChipStyle] patch into
/// [Chip.chipStyle] without hand-reconstructing every field. Mirrors
/// the Web `Chip.withStyle` extension so both platforms read
/// identically. Composition slots (`child` / `leading` / `trailing`)
/// keep using the `Text(...).bodyMedium...` chain directly — this
/// extension only covers the [CoreChipStyle] chrome slot.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreChipStyle.merge` right-side-wins semantics).
///
/// `.primary`, `.outline` select component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension ChipStyleChain on Chip {
  /// Sets the background paint and preserves the other style fields.
  Chip backgroundColor(CoreColor value) =>
      withStyle(CoreChipStyle(backgroundColor: value));

  /// Returns a copy of this [Chip] with [patch] merged into
  /// [chipStyle] (patch fields win on conflict).
  Chip withStyle(CoreChipStyle patch) =>
      copyWith(chipStyle: (chipStyle ?? const CoreChipStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Chip get radius0 =>
      withStyle(const CoreChipStyle(borderRadius: CoreBorderRadius.zero));

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Chip get radius2 => withStyle(
    const CoreChipStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius2)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Chip get radius4 => withStyle(
    const CoreChipStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Chip get radius6 => withStyle(
    const CoreChipStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius6)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Chip get radius8 => withStyle(
    const CoreChipStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius8)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Chip get radius10 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Chip get radius12 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Chip get radius14 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Chip get radius16 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Chip get radius20 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Chip get radius24 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Chip get radius28 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Chip get radius32 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Chip get radius36 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Chip get radius40 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Chip get radius48 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Chip get radius56 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Chip get radius64 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Chip get radius9999 => withStyle(
    const CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// Selects `chipColor: .primary` using the component theme.
  Chip get primary => copyWith(chipColor: .primary);

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  ///
  /// A background-colour token for this one instance — not a
  /// [CoreChipColor] value (that enum has `neutral` and `primary`).
  Chip get secondary => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.secondary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  ///
  /// A background-colour token for this one instance — not a
  /// [CoreChipColor] value (that enum has `neutral` and `primary`).
  Chip get tertiary => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Chip get surface => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Chip get surfaceContainer => withStyle(
    const CoreChipStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Chip get error => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Chip get success => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Chip get warning => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Chip get info => withStyle(
    const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// Selects `variant: .outlined` using the component theme.
  Chip get outline => copyWith(variant: .outlined);

  /// `backgroundColor: CoreColor.transparent`.
  Chip get transparent =>
      withStyle(const CoreChipStyle(backgroundColor: .transparent));
}
