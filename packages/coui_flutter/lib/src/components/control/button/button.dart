import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform button with token-based rendering.
///
/// Per Epic #1302 원칙 6/7, the semantic enums (`variant`, `size`,
/// `shape`) stay as widget parameters because they identify the
/// button instance — the design system maps each to a known chrome
/// look. All chrome / dimensional / nested-slot overrides flow
/// through the single [buttonStyle] (a [CoreButtonStyle]) so the
/// nested-merge chain works uniformly:
///
/// ```text
/// design system default for variant
///   → CoreButtonTheme.style
///   → CoreButtonTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.buttonStyle
/// ```
///
/// Example:
/// ```dart
/// Button(
///   variant: CoreButtonVariant.primary,
///   size: CoreComponentSize.lg,
///   onPressed: () => submit(),
///   buttonStyle: CoreButtonStyle(
///     width: 200,
///     padding: CoreEdgeInsets.symmetric(horizontal: 24),
///   ),
///   child: Text('Submit'),
/// )
/// ```
///
/// surface:behind — whatever a filled button is laid on (a card, a hero
/// image, a page that scrolls under a toolbar). Its box paints its own
/// fill rather than composing `OutlinedContainer` — the root already
/// resolves hover × focus × disabled × selected — so the material is
/// restated on that box. Only a button whose resting fill paints takes it;
/// one that rests unfilled (ghost, plain, menu) has no box to frost.
///
/// surface:content — a control face in the page flow: what shows through a
/// translucent fill is the page it is laid on, not something floating over
/// it. A caller that composes a button into a floating affordance (a
/// toolbar, a menu row) the button itself has no way to detect says so
/// through [role].
class Button extends StatefulWidget
    implements
        CoreButtonContract<
          Widget,
          GestureTapDownCallback,
          GestureTapUpCallback,
          GestureLongPressStartCallback,
          GestureLongPressEndCallback,
          GestureLongPressMoveUpdateCallback,
          AlignmentGeometry,
          FocusNode,
          WidgetStatesController
        > {
  /// Creates a [Button].
  const Button({
    required this.child,
    super.key,
    this.variant = CoreButtonVariant.primary,
    this.size = CoreComponentSize.md,
    this.shape = CoreButtonShape.rectangle,
    this.role = .defaultRole,
    this.leading,
    this.trailing,
    this.onPressed,
    this.enabled,
    this.href,
    this.external = false,
    this.buttonStyle,
    this.alignment,
    this.marginAlignment,
    this.expanded = false,
    this.focusNode,
    this.statesController,
    this.disableTransition = false,
    this.disableFocusOutline = false,
    this.disableHoverEffect = false,
    this.enableFeedback,
    this.onFocus,
    this.onHover,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onSecondaryTapCancel,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.onTertiaryTapCancel,
    this.onLongPressStart,
    this.onLongPressUp,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.onSecondaryLongPress,
    this.onTertiaryLongPress,
  });

  // === Content ===

  @override
  final Widget child;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  @override
  final VoidCallback? onPressed;

  @override
  final bool? enabled;

  /// Destination of a link-button. See [CoreButtonContract.href].
  ///
  /// Flutter has no anchor element — this is a semantics declaration.
  /// The host navigates in [onPressed].
  @override
  final String? href;

  /// Whether the link-button opens in a new browsing context.
  /// See [CoreButtonContract.external]. The host's [onPressed] honours it.
  @override
  final bool external;

  // === Semantic identity (widget params, not chrome) ===

  @override
  final CoreButtonVariant variant;

  @override
  final CoreComponentSize size;

  @override
  final CoreButtonShape shape;

  @override
  final CoreSurfaceRole role;

  // === Style (chrome / dimensional / nested slot) ===

  @override
  final CoreButtonStyle? buttonStyle;

  // === Layout (behaviour, not chrome) ===

  @override
  final AlignmentGeometry? alignment;

  @override
  final AlignmentGeometry? marginAlignment;

  @override
  final bool expanded;

  // === Interaction callbacks ===

  @override
  final ValueChanged<bool>? onHover;

  @override
  final ValueChanged<bool>? onFocus;

  @override
  final GestureTapDownCallback? onTapDown;

  @override
  final GestureTapUpCallback? onTapUp;

  @override
  final VoidCallback? onTapCancel;

  @override
  final GestureTapDownCallback? onSecondaryTapDown;

  @override
  final GestureTapUpCallback? onSecondaryTapUp;

  @override
  final VoidCallback? onSecondaryTapCancel;

  @override
  final GestureTapDownCallback? onTertiaryTapDown;

  @override
  final GestureTapUpCallback? onTertiaryTapUp;

  @override
  final VoidCallback? onTertiaryTapCancel;

  @override
  final GestureLongPressStartCallback? onLongPressStart;

  @override
  final VoidCallback? onLongPressUp;

  @override
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;

  @override
  final GestureLongPressEndCallback? onLongPressEnd;

  @override
  final VoidCallback? onSecondaryLongPress;

  @override
  final VoidCallback? onTertiaryLongPress;

  // === Visual options ===

  @override
  final bool disableTransition;

  @override
  final bool disableFocusOutline;

  /// Whether to suppress the hover visual effect on this instance.
  /// `false` defers to [CoreButtonStyle.disableHoverEffect] (the
  /// project-level toggle, set through the theme's button style).
  final bool disableHoverEffect;

  @override
  final bool? enableFeedback;

  // === Focus & State ===

  @override
  final FocusNode? focusNode;

  @override
  final WidgetStatesController? statesController;

  /// Returns a copy of this [Button] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Button copyWith({
    Key? key,
    VoidCallback? onPressed,
    String? href,
    bool? external,
    CoreButtonVariant? variant,
    CoreComponentSize? size,
    CoreButtonShape? shape,
    CoreSurfaceRole? role,
    Widget? leading,
    Widget? trailing,
    bool? enabled,
    CoreButtonStyle? buttonStyle,
    AlignmentGeometry? alignment,
    AlignmentGeometry? marginAlignment,
    bool? expanded,
    FocusNode? focusNode,
    WidgetStatesController? statesController,
    bool? disableTransition,
    bool? disableFocusOutline,
    bool? disableHoverEffect,
    bool? enableFeedback,
    ValueChanged<bool>? onFocus,
    ValueChanged<bool>? onHover,
    GestureTapDownCallback? onTapDown,
    GestureTapUpCallback? onTapUp,
    VoidCallback? onTapCancel,
    GestureTapDownCallback? onSecondaryTapDown,
    GestureTapUpCallback? onSecondaryTapUp,
    VoidCallback? onSecondaryTapCancel,
    GestureTapDownCallback? onTertiaryTapDown,
    GestureTapUpCallback? onTertiaryTapUp,
    VoidCallback? onTertiaryTapCancel,
    GestureLongPressStartCallback? onLongPressStart,
    VoidCallback? onLongPressUp,
    GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate,
    GestureLongPressEndCallback? onLongPressEnd,
    VoidCallback? onSecondaryLongPress,
    VoidCallback? onTertiaryLongPress,
    Widget? child,
  }) {
    return Button(
      key: key ?? this.key,
      onPressed: onPressed ?? this.onPressed,
      href: href ?? this.href,
      external: external ?? this.external,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      shape: shape ?? this.shape,
      role: role ?? this.role,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      enabled: enabled ?? this.enabled,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      alignment: alignment ?? this.alignment,
      marginAlignment: marginAlignment ?? this.marginAlignment,
      expanded: expanded ?? this.expanded,
      focusNode: focusNode ?? this.focusNode,
      statesController: statesController ?? this.statesController,
      disableTransition: disableTransition ?? this.disableTransition,
      disableFocusOutline: disableFocusOutline ?? this.disableFocusOutline,
      disableHoverEffect: disableHoverEffect ?? this.disableHoverEffect,
      enableFeedback: enableFeedback ?? this.enableFeedback,
      onFocus: onFocus ?? this.onFocus,
      onHover: onHover ?? this.onHover,
      onTapDown: onTapDown ?? this.onTapDown,
      onTapUp: onTapUp ?? this.onTapUp,
      onTapCancel: onTapCancel ?? this.onTapCancel,
      onSecondaryTapDown: onSecondaryTapDown ?? this.onSecondaryTapDown,
      onSecondaryTapUp: onSecondaryTapUp ?? this.onSecondaryTapUp,
      onSecondaryTapCancel: onSecondaryTapCancel ?? this.onSecondaryTapCancel,
      onTertiaryTapDown: onTertiaryTapDown ?? this.onTertiaryTapDown,
      onTertiaryTapUp: onTertiaryTapUp ?? this.onTertiaryTapUp,
      onTertiaryTapCancel: onTertiaryTapCancel ?? this.onTertiaryTapCancel,
      onLongPressStart: onLongPressStart ?? this.onLongPressStart,
      onLongPressUp: onLongPressUp ?? this.onLongPressUp,
      onLongPressMoveUpdate:
          onLongPressMoveUpdate ?? this.onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd ?? this.onLongPressEnd,
      onSecondaryLongPress: onSecondaryLongPress ?? this.onSecondaryLongPress,
      onTertiaryLongPress: onTertiaryLongPress ?? this.onTertiaryLongPress,
      child: child ?? this.child,
    );
  }

  @override
  State<Button> createState() => _ButtonState();
}

/// Blank destinations are not links — `href: ''` must not enable the
/// button or publish an empty URL.
String? _trimmedHref(String? href) {
  final value = href?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

class _ButtonState extends State<Button> {
  /// Hover state — driven by [Clickable.onHover].
  bool _hovered = false;

  /// Focus state — driven by [Clickable.onFocus]; gates the
  /// self-drawn [FocusOutline].
  bool _focused = false;

  /// Pressed state — driven by [Clickable.onPressedChange]. Combines
  /// with [_hovered] into `engaged` in [build] below, which gates the
  /// cast-hiding `InjectedCast.visible` — paired with
  /// `Clickable.pressedTranslate` (via `engageOnHover`) moving the
  /// button into the space the hidden shadow vacates.
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    widget.statesController?.addListener(_handleControllerChanged);
  }

  // Rebuild when an external controller drives a chrome state (e.g.
  // `selected` from a button group) — the rebuild re-reads
  // `statesController.value`.
  //
  // The shared states controller can be mutated while a descendant (e.g.
  // `Clickable`) mounts during *this* widget's build — for a disabled
  // button, `Clickable.initState` sets `WidgetState.disabled`, which would
  // call `setState` mid-build and throw. Defer to the next frame in that
  // case; the in-progress build already reflects the current value.
  void _handleControllerChanged() {
    if (!mounted) return;
    if (WidgetsBinding.instance.schedulerPhase == .persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  void _handleHover(bool hovered) {
    if (_hovered != hovered) setState(() => _hovered = hovered);
    widget.onHover?.call(hovered);
  }

  void _handleFocus(bool focused) {
    if (_focused != focused) setState(() => _focused = focused);
    widget.onFocus?.call(focused);
  }

  void _handlePressedChange(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  /// Builds the leading / child / trailing content row.
  ///
  /// When [Button.expanded] is set the row fills the available width
  /// (`mainAxisSize.max`, no `IntrinsicWidth`) so the trailing slot sits
  /// flush-right — e.g. a menu item's keyboard-shortcut hint or a form
  /// trigger's calendar / clock icon. Non-expanded buttons size to their
  /// content via `IntrinsicWidth`.
  Widget _buildLeadingTrailingContent(
    ResolvedButton resolved,
    Set<WidgetState> states,
  ) {
    final row = Row(
      mainAxisSize: widget.expanded ? .max : .min,
      crossAxisAlignment: .stretch,
      children: [
        ?widget.leading,
        if (widget.leading != null) Gap(gapStyle: resolved.iconLabelGapStyle),
        Expanded(
          child: Align(
            alignment: widget.alignment ?? AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: widget.child,
          ),
        ),
        if (widget.trailing != null) Gap(gapStyle: resolved.iconLabelGapStyle),
        if (widget.trailing != null)
          IconTheme.merge(
            data: resolved.trailingIconTheme.resolve(states),
            child: widget.trailing!,
          ),
      ],
    );
    return widget.expanded
        ? IntrinsicHeight(child: row)
        : IntrinsicWidth(child: IntrinsicHeight(child: row));
  }

  @override
  void didUpdateWidget(covariant Button oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statesController != oldWidget.statesController) {
      oldWidget.statesController?.removeListener(_handleControllerChanged);
      widget.statesController?.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.statesController?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveButton(
      context,
      variant: widget.variant,
      size: widget.size,
      shape: widget.shape,
      role: widget.role,
      buttonStyle: widget.buttonStyle,
      // A hosting `Join` squares the corners docking against a
      // neighbour (composition semantic, build-time — mirrors the Web
      // twin's scoped child-radius CSS override).
      joinItemData: Data.maybeOf(context),
    );

    // Whether the active style states a diagonal-offset vocabulary
    // (`shadowOffsetAdd`, neo-brutalism) *and* this button has a shadow
    // to retreat — `CoreOffset.zero` for every other style, and for any
    // button with no shadow at all. True alike for a plain button's
    // *injected* shadow and for a composing component's own stated one
    // (`Fab`'s elevation) — see `ResolvedButton.pressedTranslateOffset`.
    // Drives whether the dedicated shadow wrapper below does anything.
    // (The other half of that answer — a shift, not a shrink, carries the
    // engage signal under this style — is already folded into
    // `resolved.pressedScale` by the resolver.)
    final hasSignatureShadow =
        resolved.pressedTranslateOffset != CoreOffset.zero;

    // Press feedback — the shrink, or the style's shift — is an affordance
    // of the control, not a platform convention, and its Web twin is a
    // global `:active` / `:hover` rule with no platform gate. A
    // mobile-only default left a desktop build showing no press at all
    // under every style without a cast, while the same button on Web and
    // on a phone shrank. An explicit `enableFeedback: false` still
    // suppresses all of it (the press and the hover half); the click
    // sound stays mobile-only inside `Clickable` regardless.
    final enableFeedback =
        widget.enableFeedback ?? CoreButtonContract.defaultEnableFeedback;
    final effectiveWidth = widget.expanded ? double.infinity : resolved.width;
    final href = _trimmedHref(widget.href);
    final enabled =
        widget.enabled ?? (widget.onPressed != null || href != null);
    final disableHoverEffect =
        widget.disableHoverEffect || resolved.disableHoverEffect;

    // Aggregate the interaction states the chrome keys on. Button owns
    // its own state tracking now that the deprecated `Clickable` transport
    // is gone (#2365): hover / focus / press come from [Clickable] callbacks,
    // `disabled` from `enabled`, and `selected` from an ambient
    // `WidgetStatesData` (e.g. a button group) or the external
    // `statesController`. Clickable drives the gesture / focus / cursor /
    // press-scale layer and keeps `statesController` in sync.
    final ambient = Data.maybeOf<WidgetStatesData>(context)?.states;
    final selected =
        (ambient?.contains(WidgetState.selected) ?? false) ||
        (widget.statesController?.value.contains(WidgetState.selected) ??
            false);
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (_hovered && !disableHoverEffect) WidgetState.hovered,
      if (_focused) WidgetState.focused,
      if (_pressed) WidgetState.pressed,
      if (selected) WidgetState.selected,
    };

    // Per-state chrome resolved against the live state set.
    final decoration = resolved.decoration.resolve(states);
    final labelTextStyle = resolved.textStyle.resolve(states);
    final leadingIconTheme = resolved.leadingIconTheme.resolve(states);

    final content = widget.leading == null && widget.trailing == null
        ? Align(
            alignment: widget.alignment ?? Alignment.center,
            widthFactor: 1,
            heightFactor: 1,
            child: widget.child,
          )
        : _buildLeadingTrailingContent(resolved, states);

    // Chrome container — `AnimatedContainer` animates the per-state
    // decoration / padding transition (hover / focus / selected), unless
    // `disableTransition` collapses it to a static `Container`.
    final container = widget.disableTransition
        ? Container(
            padding: resolved.padding,
            decoration: decoration,
            child: content,
          )
        : AnimatedContainer(
            padding: resolved.padding,
            decoration: decoration,
            duration: resolved.animationDuration,
            curve: resolved.curve,
            child: content,
          );

    // The rest of the surface material, around the box. The fill share is
    // already folded into every state's decoration; this adds what a fill
    // cannot carry — the frost, the chroma, the dimming, the edge light and
    // the bend — the way the Web twin's surface marker gets them from the
    // style rule. Bounded by the box's own painted corners, inside the cast
    // so the cast keeps painting outside it. Wrapped only when the style
    // states something to draw, so every other style keeps the tree it had.
    final surfaceBlur = resolved.surfaceBlur;
    final materialContainer =
        (surfaceBlur != null && surfaceBlur > 0) ||
            resolved.surfaceSheen != null
        ? SurfaceBlur(
            borderRadius: resolved.shapedBorderRadius,
            surfaceBlur: surfaceBlur,
            surfaceSaturation: resolved.surfaceSaturation,
            surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
            surfaceSheen: resolved.surfaceSheen,
            refraction: Theme.of(context).surfaceRefraction,
            child: container,
          )
        : container;

    // Whether the button reads as "engaged" for the cast-motion pair —
    // pressed always counts, and hover counts too. On mobile Flutter
    // never dispatches a hover event, so this is `_pressed`-only there
    // with no platform branch; on desktop hover alone is enough, matching
    // the reference's `:hover` affordance.
    //
    // `Clickable.engageOnHover` (wired below) computes this identical
    // formula internally to drive the shift — same `enabled` /
    // `enableFeedback` gates, same `_pressed` / `_hovered` inputs, just
    // read from `Clickable`'s own copies of those two booleans rather
    // than Button's. The two copies cannot drift apart: `Clickable`
    // updates its own state and forwards `onHover` / `onPressedChange`
    // to Button synchronously inside the same gesture callback, so both
    // widgets rebuild for the same frame with the same answer. `enabled`
    // is belt-and-braces here — `Clickable` already gates the pointer /
    // hover detectors that feed `_pressed` / `_hovered` on its own
    // `enabled`, so a disabled button never sets either in the first
    // place.
    final engaged = enabled && enableFeedback && (_pressed || _hovered);

    // Dedicated shadow layer, synced to `Clickable.pressedTranslate` on
    // the same clock (`resolved.castHideDuration`, matching the
    // `pressDuration` passed to `Clickable` below) rather than
    // `resolved.animationDuration` (the hover/focus/selected transition
    // speed `container` above animates on). Pairing a hide with a travel
    // on two different clocks is exactly the drift `Clickable`'s own doc
    // comment warns against for its own pressedTranslate/pressedBoxShadow
    // pair — this wrapper exists because that pair has the opposite
    // polarity (shows a shadow while pressed) from what a
    // resting-then-hidden shadow needs. Wrapped only when there is a
    // shadow to hide, so a button under every style with no shadow at all
    // keeps exactly the tree it had.
    //
    // Painted outside the box rather than behind it. `BoxDecoration`
    // would fill a rounded rect under the button and let the background
    // paint over it, which is invisible while the fill is opaque and
    // wrong the moment it is not — the hover state is 80% alpha, and it
    // showed the button's own cast through itself. CSS clips an outer
    // shadow to outside the border box, so the Web twin never did.
    //
    // `resolved.reverseCastMotion` flips which half of the pair is
    // visible at rest — [CoreCastMotion.reverse] casts nothing until
    // engaged, the mirror of the default hide-on-engage. The travel
    // itself needs no branch here: its direction is already baked into
    // `resolved.pressedTranslateOffset` by the resolver, so `Clickable`
    // below reads it exactly as it would for `defaultMotion`.
    final castVisible = resolved.reverseCastMotion
        ? (hasSignatureShadow && engaged)
        : !(hasSignatureShadow && engaged);
    final shadowedContainer = resolved.boxShadow == null
        ? materialContainer
        : InjectedCast(
            shadows: resolved.boxShadow!,
            visible: castVisible,
            duration: resolved.castHideDuration,
            borderRadius: resolved.shapedBorderRadius,
            child: materialContainer,
          );

    // Label colour + leading icon theme are inherited by descendant
    // `Text` / `Icon` widgets via the ambient context (matches the
    // deprecated `Clickable`'s `DefaultTextStyle.merge` + `IconTheme.merge`).
    final styledContent = DefaultTextStyle.merge(
      style: labelTextStyle,
      child: IconTheme.merge(data: leadingIconTheme, child: shadowedContainer),
    );
    // Link semantics merge into Clickable's button node (container: false).
    // No navigation here — Flutter has no anchor; the host wires [onPressed].
    final semanticsChild = href != null && enabled
        ? Semantics(
            link: true,
            linkUrl: Uri.tryParse(href),
            child: styledContent,
          )
        : styledContent;

    // Interaction layer — gestures, keyboard activation, cursor, focus
    // detection and press-scale. Button draws its own focus ring below,
    // so `focusOutline: false`. The `clickableStyle` overrides pin the
    // press-feedback to the button's legacy behaviour and suppress
    // Clickable's disabled-opacity dim (Button expresses disabled via
    // its own disabled colour tokens, so a second opacity layer would
    // double-dim). That premise is load-bearing and was false for a
    // while: several variants (`ghost`, `fixed`) named the enabled
    // colour for both states, so opting out of the generic dim left
    // them with no disabled signal at all on this platform. Every
    // variant now states `disabledContent`, pinned by
    // `button_disabled_affordance_test.dart` — if that ever regresses,
    // this opt-out is what turns it into an invisible state rather than
    // a subtle one. `engageOnHover: true` is safe to pass unconditionally
    // — the shift it opts into only paints when `pressedTranslate` below
    // is non-zero (`hasSignatureShadow`), so it is a no-op under every
    // style except one that states a cast-motion vocabulary.
    final clickable = Clickable(
      onPressed: widget.onPressed,
      onHover: _handleHover,
      onFocus: _handleFocus,
      onPressedChange: _handlePressedChange,
      onTapDown: widget.onTapDown,
      onTapUp: widget.onTapUp,
      onTapCancel: widget.onTapCancel,
      onSecondaryTapDown: widget.onSecondaryTapDown,
      onSecondaryTapUp: widget.onSecondaryTapUp,
      onSecondaryTapCancel: widget.onSecondaryTapCancel,
      onTertiaryTapDown: widget.onTertiaryTapDown,
      onTertiaryTapUp: widget.onTertiaryTapUp,
      onTertiaryTapCancel: widget.onTertiaryTapCancel,
      onLongPressStart: widget.onLongPressStart,
      onLongPressUp: widget.onLongPressUp,
      onLongPressMoveUpdate: widget.onLongPressMoveUpdate,
      onLongPressEnd: widget.onLongPressEnd,
      onSecondaryLongPress: widget.onSecondaryLongPress,
      onTertiaryLongPress: widget.onTertiaryLongPress,
      marginAlignment: widget.marginAlignment,
      enabled: enabled,
      focusOutline: false,
      enableFeedback: enableFeedback,
      engageOnHover: true,
      focusNode: widget.focusNode,
      statesController: widget.statesController,
      clickableStyle: CoreClickableStyle(
        // `CoreButtonStyle.pressedScale`, already pinned to `1.0` by the
        // resolver under a shift-and-fade style (neo-brutalism) on a
        // button that casts — the same repo idiom Card/Tree/Accordion/
        // Link/Collapsible/ItemPicker/Command/Breadcrumb/FileInput follow
        // when a different affordance carries the engage signal. DDR-1:
        // pinned regardless of whether engage arrived via press or hover,
        // so a control that already shifted on hover never adds a shrink
        // on top when a press follows. The Web twin reads the same field
        // and gates it the same way (`--coui-control-press-shrink`).
        // `Clickable` itself withholds the shrink when [enableFeedback]
        // is off.
        pressedScale: resolved.pressedScale,
        // Raw-forwarded — `CoreOffset.zero` (the common case, every
        // surface style except neo-brutalism) leaves `Clickable`'s own
        // `shifts` check false, so a plain button keeps exactly the
        // widget tree it had regardless of `engageOnHover`. `pressedBoxShadow`
        // stays unset: Button paints its own shadow (`shadowedContainer`,
        // above), so hiding it is a dedicated wrapper on the same clock,
        // not a second shadow layered by `Clickable`'s own
        // (oppositely-polarised) wrapper.
        pressedTranslate: resolved.pressedTranslateOffset,
        disabledOpacity: 1,
        // Same value `resolved.castHideDuration` gives the shadow-hide
        // wrapper above — see its doc comment. `resolveClickable` applies
        // `resolveMotionDuration` to whatever `pressDuration` it
        // receives too, so this would still collapse under reduced
        // motion even un-pre-resolved; passing the already-resolved
        // value keeps both halves reading the exact same clock rather
        // than two independent reduced-motion checks that could answer
        // differently mid-frame.
        pressDuration: resolved.castHideDuration,
      ),
      child: semanticsChild,
    );

    // Self-drawn focus ring outside the gesture / press-scale layer so it
    // hugs the button's resolved radius (injected into [focusOutlineStyle]
    // by the resolver) and does not shrink with the press animation —
    // matching the deprecated `Clickable`'s `FocusOutline` placement.
    Widget result = FocusOutline(
      focused: _focused && !widget.disableFocusOutline,
      focusOutlineStyle: resolved.focusOutlineStyle,
      child: clickable,
    );

    // The size token's `height` is always applied as a minimum so
    // every variant (text + icon + icon-only) reads as the same
    // visual unit at a given [CoreComponentSize].
    result = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: resolved.minWidth ?? 0,
        maxWidth: resolved.maxWidth ?? .infinity,
        minHeight: resolved.height,
      ),
      child: effectiveWidth != null
          ? SizedBox(width: effectiveWidth, child: result)
          : result,
    );

    if (resolved.dashedBorder) {
      // For the dashed-border wrapper we use the resolver's
      // rectangle/square radius directly — circle buttons are not
      // expected to carry a dashed border.
      result = DashedContainer(
        borderRadius: resolved.borderRadius,
        color: resolved.dashedBorderColor,
        // Pre-scaled by the resolver — DashedContainer only self-scales
        // its token fallbacks, not explicit values.
        gap: resolved.dashSpacing,
        strokeWidth: resolved.dashLength,
        child: result,
      );
    }

    return result;
  }
}

/// Chain sugar mirroring the Web `Button.withStyle` extension — merges
/// a [CoreButtonStyle] patch into [Button.buttonStyle] via the existing
/// [Button.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreButtonStyle.merge` right-side-wins semantics).
///
/// `.primary`, `.secondary`, `.outline` select component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension ButtonStyleChain on Button {
  /// Sets the background paint and preserves the other style fields.
  Button backgroundColor(CoreColor value) =>
      withStyle(CoreButtonStyle(backgroundColor: value));

  /// Returns a copy of this [Button] with [patch] merged into
  /// [buttonStyle] (patch fields win on conflict).
  Button withStyle(CoreButtonStyle patch) => copyWith(
    buttonStyle: (buttonStyle ?? const CoreButtonStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Button get radius0 => withStyle(
    const CoreButtonStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Button get radius2 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Button get radius4 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Button get radius6 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Button get radius8 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Button get radius10 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Button get radius12 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Button get radius14 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Button get radius16 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Button get radius20 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Button get radius24 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Button get radius28 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Button get radius32 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Button get radius36 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Button get radius40 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Button get radius48 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Button get radius56 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Button get radius64 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Button get radius9999 => withStyle(
    const CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// Selects `variant: .primary` using the component theme.
  Button get primary => copyWith(variant: .primary);

  /// Selects `variant: .secondary` using the component theme.
  Button get secondary => copyWith(variant: .secondary);

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Button get tertiary => withStyle(
    const CoreButtonStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Button get surface => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Button get surfaceContainer => withStyle(
    const CoreButtonStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Button get error => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Button get success => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Button get warning => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Button get info => withStyle(
    const CoreButtonStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// Selects `variant: .outline` using the component theme.
  Button get outline => copyWith(variant: .outline);

  /// `backgroundColor: CoreColor.transparent`.
  Button get transparent =>
      withStyle(const CoreButtonStyle(backgroundColor: .transparent));
}
