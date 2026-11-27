import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform toggle (switch) with token-based rendering.
///
/// Semantic enums (`variant`, `size`) stay as widget parameters — they
/// identify the toggle instance — while all chrome / dimensional /
/// nested-slot overrides flow through the single [toggleStyle] (a
/// [CoreToggleStyle]). The nested-merge chain:
///
/// ```text
/// design system default for variant
///   → CoreToggleTheme.style
///   → CoreToggleTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.toggleStyle
/// ```
///
/// Example:
/// ```dart
/// Toggle(
///   value: true,
///   onChanged: (v) => setState(() => _value = v),
///   label: 'Dark mode',
/// )
/// ```
///
/// surface:content — a control box that sits in the flow, not something
/// mounted over content.
///
/// surface:functional — the transient lens, mounted over the track and the
/// thumb only while the thumb travels after the user flips the switch; for
/// its whole life both pass behind it.
class Toggle extends StatefulWidget
    implements
        CoreToggleContract<
          Widget,
          FocusNode,
          WidgetStatesController,
          ToggleController
        > {
  /// Creates a [Toggle].
  const Toggle({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled,
    this.prefix,
    this.suffix,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.variant = CoreToggleVariant.defaultVariant,
    this.size = CoreComponentSize.md,
    this.toggleStyle,
    this.name,
    this.focusNode,
    this.statesController,
    this.controller,
  });

  // === State ===

  @override
  final bool value;

  @override
  final ValueChanged<bool>? onChanged;

  @override
  final bool? enabled;

  // === Content ===

  @override
  final Widget? prefix;

  @override
  final Widget? suffix;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  // === Semantic identity (widget params, not chrome) ===

  @override
  final CoreToggleVariant variant;

  @override
  final CoreComponentSize size;

  // === Style (chrome / dimensional / nested slot) ===

  @override
  final CoreToggleStyle? toggleStyle;

  // === Form ===

  @override
  final String? name;

  // === Focus & State ===

  @override
  final FocusNode? focusNode;

  @override
  final WidgetStatesController? statesController;

  @override
  final ToggleController? controller;

  /// Returns a copy of this [Toggle] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Toggle copyWith({
    Key? key,
    ValueChanged<bool>? onChanged,
    bool? value,
    bool? enabled,
    Widget? prefix,
    Widget? suffix,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    CoreToggleVariant? variant,
    CoreComponentSize? size,
    CoreToggleStyle? toggleStyle,
    String? name,
    FocusNode? focusNode,
    WidgetStatesController? statesController,
    ToggleController? controller,
  }) {
    return Toggle(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      toggleStyle: toggleStyle ?? this.toggleStyle,
      name: name ?? this.name,
      focusNode: focusNode ?? this.focusNode,
      statesController: statesController ?? this.statesController,
      controller: controller ?? this.controller,
    );
  }

  @override
  State<Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<Toggle>
    with FormValueSupplier<bool, Toggle>, SingleTickerProviderStateMixin {
  // Interaction DETECTION only — the `Clickable` reports these and the
  // build below SELECTS an already-resolved bundle by them. The chrome
  // each state paints lives in the resolver (`widget/render-only.md`).
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  // The lens follows the painted thumb, including an interrupted transition.
  final _thumbLink = LayerLink();

  /// Clock of the transient lens — runs for exactly one thumb travel and
  /// is idle at rest, when the lens is not in the tree at all.
  late final AnimationController _lens = AnimationController(vsync: this)
    ..addStatusListener(_handleLensStatus);

  /// Set when the user flips the switch — pointer or keyboard, both reach
  /// [handleTap] — and cleared once the frame that flip schedules has run.
  ///
  /// Only a value change that lands while it is set rides the lens: the
  /// update the user's own flip brings. A value the app sets in code — a
  /// form reset, a "turn all on" — arrives with it clear and moves the thumb
  /// with no lens. The Web twin arms and clears on the same clock.
  bool _lensArmed = false;

  @override
  void initState() {
    super.initState();
    formValue = widget.value;
  }

  @override
  void dispose() {
    _lens.dispose();
    super.dispose();
  }

  void _handleLensStatus(AnimationStatus status) {
    // Leaving the tree is what makes the resting switch the switch it was
    // before the lens existed — rebuild once the travel is over.
    if (status == AnimationStatus.completed && mounted) setState(() {});
  }

  bool get _enabled => widget.enabled ?? (widget.onChanged != null);

  @override
  void didUpdateWidget(covariant Toggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      formValue = widget.value;
      if (_lensArmed) {
        _startLens();
      } else {
        _lens.stop();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Accessibility can change while the lens is already travelling.
    if (resolveToggle(
          context,
          variant: widget.variant,
          size: widget.size,
          toggleStyle: widget.toggleStyle,
        ).thumbTransitionDuration ==
        Duration.zero) {
      _lens.stop();
    }
  }

  /// Marks the next value change as the user's own.
  ///
  /// Through `setState`, so a frame is scheduled even when the host ignores
  /// the flip — the post-frame clear then always runs, and the mark cannot
  /// outlive the gesture into a later change the app makes in code. A host
  /// that answers the flip synchronously rebuilds in that same frame, before
  /// the clear.
  void _armLens() {
    setState(() => _lensArmed = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _lensArmed = false);
  }

  /// Runs the lens for one thumb travel. Nothing to run when the travel
  /// takes no time — reduced motion settles the duration to zero before it
  /// reaches here, so the lens is suppressed with the transition it rides.
  /// A disabled toggle does not read as a material surface, so it gets no
  /// lens either.
  void _startLens() {
    if (!_enabled) return;
    final duration = resolveToggle(
      context,
      variant: widget.variant,
      size: widget.size,
      toggleStyle: widget.toggleStyle,
    ).thumbTransitionDuration;
    if (duration == Duration.zero) return;
    _lens
      ..duration = duration
      ..forward(from: 0);
  }

  // A form replacing the value (a reset, a restore) is the app speaking, not
  // the user — it reports through `onChanged` but does not arm the lens.
  @override
  void didReplaceFormValue(bool value) {
    widget.onChanged?.call(value);
  }

  void handleTap() {
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    _armLens();
    onChanged(!widget.value);
  }

  void _handleHover(bool hovered) {
    if (hovered == _hovered) return;
    setState(() => _hovered = hovered);
  }

  void _handlePressedChange(bool pressed) {
    if (pressed == _pressed) return;
    setState(() => _pressed = pressed);
  }

  void _handleFocus(bool focused) {
    if (focused == _focused) return;
    setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    // Render-only: every chrome / colour / dimensional value is
    // already merged, scaling-pre-applied, and converted to a
    // paint-ready Flutter type inside `resolveToggle`. This widget
    // reads the resolved struct and lays it out — no merge, no
    // `scheme.resolve`, no `* scaling`.
    final resolved = resolveToggle(
      context,
      variant: widget.variant,
      size: widget.size,
      toggleStyle: widget.toggleStyle,
    );

    // Select the pre-resolved per-state `OutlinedContainer` chrome
    // bundle for the track, and the plain thumb colour (the thumb is
    // not composed — it stays opaque regardless of material, see the
    // resolver's field doc). Strongest state wins, disabled first: a
    // disabled toggle never engages, and a held toggle does not step back
    // to its hover wash just because the pointer is still over it.
    final on = widget.value;
    final CoreOutlinedContainerStyle trackContainerStyle;
    final Color thumbColor;
    if (!_enabled) {
      trackContainerStyle = on
          ? resolved.disabledActiveTrackContainerStyle
          : resolved.disabledInactiveTrackContainerStyle;
      thumbColor = on
          ? resolved.thumbDisabledColor
          : resolved.thumbDisabledInactiveColor;
    } else {
      if (_pressed) {
        trackContainerStyle = on
            ? resolved.activePressedTrackContainerStyle
            : resolved.inactivePressedTrackContainerStyle;
      } else if (_hovered) {
        trackContainerStyle = on
            ? resolved.activeHoverTrackContainerStyle
            : resolved.inactiveHoverTrackContainerStyle;
      } else {
        trackContainerStyle = on
            ? resolved.activeTrackContainerStyle
            : resolved.inactiveTrackContainerStyle;
      }
      thumbColor = on ? resolved.thumbActiveColor : resolved.thumbInactiveColor;
    }

    // Build the toggle track with animated thumb. `OutlinedContainer`
    // owns the track's fill / radius / cast / material — the widget only
    // composes it and stacks the (uncomposed) thumb inside, in the band
    // the resolver settled (`trackInset`, which the density does not move;
    // see its doc).
    final to = on ? resolved.thumbOffset : resolved.inactiveThumbOffset;
    final track = OutlinedContainer(
      containerStyle: trackContainerStyle,
      // Stated rather than left to the default (also `.content`): the
      // component reaches two roles, the class doc names both, and the role
      // audit (`surface_role_audit.py`) reads the role a composition states
      // in code — left implicit, this platform would say only `functional`
      // while the Web twin, which marks both, says both.
      // ignore: avoid_redundant_argument_values
      role: .content,
      child: Padding(
        padding: resolved.trackInset,
        child: Stacks(
          children: [
            AnimatedPositioned(
              left: to,
              top: 0,
              bottom: 0,
              curve: resolved.thumbTransitionCurve,
              duration: resolved.thumbTransitionDuration,
              child: CompositedTransformTarget(
                link: _thumbLink,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: thumbColor,
                      boxShadow: resolved.thumbShadow,
                      borderRadius: resolved.thumbBorderRadius,
                      shape: resolved.thumbBorderRadius == null
                          ? .circle
                          : .rectangle,
                    ),
                    width: resolved.thumbSize,
                    height: resolved.thumbSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // The transient lens — mounted only while the thumb travels, riding
    // the thumb's actual composited position so interrupted travel never
    // restarts the lens at a resting endpoint. A
    // floating surface (`role: .functional`), because for its whole life
    // the track and the thumb pass behind it; what it shows is that
    // role's material, refraction included.
    final trackInset = resolved.trackInset.resolve(Directionality.of(context));
    final lensActive =
        _enabled &&
        resolved.thumbTransitionDuration != Duration.zero &&
        _lens.isAnimating;
    final lens = lensActive
        ? AnimatedBuilder(
            animation: _lens,
            builder: (context, child) {
              return Position(
                left: 0,
                top: 0,
                child: CompositedTransformFollower(
                  link: _thumbLink,
                  offset: Offset(
                    resolved.lensOriginX - trackInset.left,
                    resolved.lensTop - trackInset.top,
                  ),
                  child: Opacity(
                    opacity: resolved.lensEnvelope.evaluate(_lens),
                    child: child,
                  ),
                ),
              );
            },
            child: IgnorePointer(
              child: OutlinedContainer(
                containerStyle: resolved.lensContainerStyle,
                role: .functional,
              ),
            ),
          )
        : null;

    // The focus ring wraps the TRACK, not the row: the composed
    // `Clickable` below keeps its own row-wide ring off, and this one
    // reads the focus it reports. What the keyboard reaches is the
    // switch, and the ring says so around the switch.
    //
    // The track sits in a `Stacks` even at rest, so mounting the lens
    // beside it never re-parents the track — its colour transition keeps
    // running through the one `AnimatedContainer` it already had.
    final toggleTrack = FocusOutline(
      focused: _enabled && _focused,
      focusOutlineStyle: resolved.focusOutlineStyle,
      child: Stacks(
        clipBehavior: .none,
        children: [track, ?lens],
      ),
    );

    // Label text — the resolved `labelStyle` already carries the
    // typography role + per-instance metric overrides; only the
    // per-state foreground colour is layered here.
    final labelColor = _enabled
        ? resolved.labelColor
        : resolved.disabledLabelColor;
    final mergedLabelStyle = resolved.labelStyle.copyWith(color: labelColor);
    final effectiveSuffix =
        widget.suffix ??
        (widget.label != null
            ? Text(
                widget.label!,
                style: mergedLabelStyle,
                maxLines: widget.labelMaxLines,
                overflow: widget.labelOverflow?.toValue(),
              )
            : null);

    // Web twin carries the state on a visually-hidden native <input>.
    //
    // `TouchTarget` sits *under* the semantics annotation, not over it —
    // same reasoning as `Checkbox`: its outermost render object is a
    // plain proxy carrying no semantics, so a reader (or a widget-type
    // lookup) needs to find the node this wraps, not the wrapper itself.
    //
    // It wraps everything below because the two smallest track heights
    // (16, 20) draw under the WCAG minimum. Where the track is already
    // large enough the expansion is zero.
    return TouchTarget(
      child: Semantics(
        toggled: on,
        child: Clickable(
          onPressed: _enabled ? handleTap : null,
          onHover: _handleHover,
          onFocus: _handleFocus,
          onPressedChange: _handlePressedChange,
          // Effective enabled drives the whole interaction surface —
          // forbidden cursor, no focus, no activation. The generic
          // disabled fade stays off via the nested clickableStyle slot
          // (the toggle paints its own disabled tokens).
          enabled: _enabled,
          // A toggle is a more specific control than a plain button, so the
          // generic role is suppressed and the state above is what the reader
          // announces.
          semanticsButton: false,
          enableFeedback: _enabled,
          // The ring is the track's (above), not the row's.
          focusOutline: false,
          focusNode: widget.focusNode,
          statesController: widget.statesController,
          clickableStyle: resolved.clickableStyle,
          child: Row(
            mainAxisSize: .min,
            children: [
              // Ambient default for caller-supplied slots — see the twin note
              // in `checkbox.dart` for why the `.bodySmall().medium()` this
              // replaces was reaching somewhere other than where it looked.
              if (widget.prefix != null) ...[
                DefaultTextStyle.merge(
                  style: mergedLabelStyle,
                  child: widget.prefix!,
                ),
                Gap(gapStyle: resolved.iconLabelGapStyle),
              ],
              toggleTrack,
              if (effectiveSuffix != null) ...[
                Gap(gapStyle: resolved.iconLabelGapStyle),
                Flexible(
                  child: DefaultTextStyle.merge(
                    style: mergedLabelStyle,
                    child: effectiveSuffix,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Controller for a [Toggle]'s on/off value.
class ToggleController extends ValueNotifier<bool>
    with ComponentController<bool> {
  /// Creates a [ToggleController] with an optional initial [value].
  ToggleController([super.value = false]);

  /// Flips the current value.
  void toggle() {
    value = !value;
  }
}

/// Chain sugar for merging a [CoreToggleStyle] patch into
/// [Toggle.toggleStyle] without hand-reconstructing every field. Mirrors
/// the Web `Toggle.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreToggleStyle.merge` right-side-wins semantics).
///
/// ```dart
/// Toggle(value: true, onChanged: (v) {}).withStyle(
///   CoreToggleStyle(trackActiveColor: CoreColor.token(CoreColors.primary)),
/// )
/// ```
extension ToggleStyleChain on Toggle {
  /// Sets the content padding.
  Toggle contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreToggleStyle(padding: value));

  /// Returns a copy of this [Toggle] with [patch] merged into
  /// [toggleStyle] (patch fields win on conflict).
  Toggle withStyle(CoreToggleStyle patch) => copyWith(
    toggleStyle: (toggleStyle ?? const CoreToggleStyle()).merge(patch),
  );
}
