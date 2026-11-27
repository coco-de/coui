import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform selectable answer card.
///
/// `MultiAnswerCard` is a card-styled selectable surface — typically
/// used in quizzes / surveys where the user picks one or more answers.
/// It carries an opaque [value] and reflects [selected] state with
/// distinct border / background chrome.
///
/// Per Epic #1302 원칙 6/7, behaviour / semantic fields (`value`,
/// `selected`, `enabled`, `onChanged`, `child`) stay flat on the widget.
/// All chrome / dimensional overrides flow through the single
/// [multiAnswerCardStyle] (a [CoreMultiAnswerCardStyle]).
///
/// Example:
/// ```dart
/// MultiAnswerCard<String>(
///   value: 'a',
///   selected: _picked.contains('a'),
///   onChanged: (v) => setState(() => _toggle(v)),
///   child: const Text('Answer A'),
/// )
/// ```
///
/// surface:content — draws its own box (composes `OutlinedContainer`
/// rather than being drawn inside a parent panel), on the page rather
/// than floating over it.
class MultiAnswerCard<T> extends StatefulWidget
    implements CoreMultiAnswerCardContract<T, Widget> {
  /// Creates a [MultiAnswerCard].
  const MultiAnswerCard({
    required this.value,
    required this.child,
    super.key,
    this.selected = false,
    this.enabled = true,
    this.onChanged,
    this.multiAnswerCardStyle,
  });

  @override
  final T value;

  @override
  final bool selected;

  @override
  final bool enabled;

  @override
  final void Function(T)? onChanged;

  @override
  final Widget child;

  // === Style (chrome / dimensional) ===

  @override
  final CoreMultiAnswerCardStyle? multiAnswerCardStyle;

  /// Returns a copy of this [MultiAnswerCard] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  MultiAnswerCard<T> copyWith({
    Key? key,
    void Function(T)? onChanged,
    T? value,
    bool? selected,
    bool? enabled,
    CoreMultiAnswerCardStyle? multiAnswerCardStyle,
    Widget? child,
  }) {
    return MultiAnswerCard(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      value: value ?? this.value,
      selected: selected ?? this.selected,
      enabled: enabled ?? this.enabled,
      multiAnswerCardStyle: multiAnswerCardStyle ?? this.multiAnswerCardStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<MultiAnswerCard<T>> createState() => _MultiAnswerCardState<T>();
}

class _MultiAnswerCardState<T> extends State<MultiAnswerCard<T>> {
  bool _hovering = false;

  void _handleTap() {
    if (!widget.enabled) return;
    widget.onChanged?.call(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMultiAnswerCard(
      context,
      multiAnswerCardStyle: widget.multiAnswerCardStyle,
    );

    // State select — disabled wins (its dedicated tokens replace every
    // enabled fill), then selected, then hovered, then idle.
    final containerStyle = !widget.enabled
        ? resolved.disabledContainerStyle
        : widget.selected
        ? resolved.selectedContainerStyle
        : _hovering
        ? resolved.hoverContainerStyle
        : resolved.idleContainerStyle;
    final contentInset = widget.selected
        ? resolved.selectedInset
        : resolved.restingInset;
    final bodyTextStyle = !widget.enabled
        ? resolved.disabledBodyTextStyle
        : widget.selected
        ? resolved.selectedBodyTextStyle
        : resolved.bodyTextStyle;

    // The composed Clickable owns tap / keyboard activation / cursor /
    // press feedback / focus ring (Epic composition — no hand-rolled
    // GestureDetector + MouseRegion). Hover state flows back through
    // `onHover` so the widget only SELECTS between the pre-resolved
    // idle / hover / selected / disabled chrome bundles.
    return Clickable(
      onPressed: _handleTap,
      onHover: (hovered) => setState(() => _hovering = hovered),
      enabled: widget.enabled,
      clickableStyle: resolved.clickableStyle,
      // The card box itself is a composed `OutlinedContainer` — this is
      // the surface-primitive swap: it owns the fill / border / radius /
      // padding AnimatedContainer lerp, geometry conversion, and the
      // `surface:content` material reach a preset can now apply. `role`
      // is left at its own default (`.content`).
      child: OutlinedContainer(
        containerStyle: containerStyle,
        // The border difference between states, moving in step with the
        // border `OutlinedContainer` lerps — so the content holds still.
        child: AnimatedPadding(
          padding: contentInset,
          duration: resolved.transitionDuration,
          curve: resolved.transitionCurve,
          // Content on the left, the selection mark on the right,
          // centred on the cross axis. The checkbox only shows the
          // selection — the card's own Clickable owns the tap — so it is
          // taken out of hit-testing, focus and semantics.
          child: Row(
            children: [
              Expanded(
                // Base typography for the caller-supplied child — CoUI's
                // theme does not install a global DefaultTextStyle, so
                // without this the child inherits the Material default
                // (14px Roboto) while the Web twin inherits the CoUIWeb
                // base.
                child: DefaultTextStyle.merge(
                  style: bodyTextStyle,
                  child: widget.child,
                ),
              ),
              Gap(gapStyle: resolved.checkboxGapStyle),
              ExcludeSemantics(
                child: ExcludeFocus(
                  child: IgnorePointer(
                    child: Checkbox(
                      checked: widget.selected,
                      onChanged: null,
                      enabled: widget.enabled,
                      size: resolved.checkboxSize,
                      checkboxStyle: resolved.checkboxStyle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreMultiAnswerCardStyle] patch into
/// [MultiAnswerCard.multiAnswerCardStyle] without hand-reconstructing
/// every field. Mirrors the Web `MultiAnswerCard.withStyle` extension so
/// both platforms read identically. The composition slot (`child`) keeps
/// using its own content directly — this extension only covers the
/// [CoreMultiAnswerCardStyle] chrome slot.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMultiAnswerCardStyle.merge` right-side-wins semantics).
///
/// ```dart
/// MultiAnswerCard<String>(
///   value: 'a',
///   child: const Text('Answer A'),
/// ).withStyle(
///   CoreMultiAnswerCardStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
/// );
/// ```
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreMultiAnswerCardStyle.borderRadius] and `.primary` sets
/// [CoreMultiAnswerCardStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// MultiAnswerCard<String>(
///   value: 'a',
///   child: const Text('Answer A'),
/// ).radius4.surface
/// ```
extension MultiAnswerCardStyleChain<T> on MultiAnswerCard<T> {
  /// Sets the content padding.
  MultiAnswerCard<T> contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreMultiAnswerCardStyle(padding: value));

  /// Sets the border color.
  MultiAnswerCard<T> borderColor(CoreColor value) =>
      withStyle(CoreMultiAnswerCardStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  MultiAnswerCard<T> borderWidth(double value) =>
      withStyle(CoreMultiAnswerCardStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  MultiAnswerCard<T> backgroundColor(CoreColor value) =>
      withStyle(CoreMultiAnswerCardStyle(backgroundColor: value));

  /// Returns a copy of this [MultiAnswerCard] with [patch] merged into
  /// [multiAnswerCardStyle] (patch fields win on conflict).
  MultiAnswerCard<T> withStyle(CoreMultiAnswerCardStyle patch) => copyWith(
    multiAnswerCardStyle:
        (multiAnswerCardStyle ?? const CoreMultiAnswerCardStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  MultiAnswerCard<T> get radius0 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  MultiAnswerCard<T> get radius2 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  MultiAnswerCard<T> get radius4 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  MultiAnswerCard<T> get radius6 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  MultiAnswerCard<T> get radius8 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  MultiAnswerCard<T> get radius10 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  MultiAnswerCard<T> get radius12 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  MultiAnswerCard<T> get radius14 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  MultiAnswerCard<T> get radius16 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  MultiAnswerCard<T> get radius20 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  MultiAnswerCard<T> get radius24 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  MultiAnswerCard<T> get radius28 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  MultiAnswerCard<T> get radius32 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  MultiAnswerCard<T> get radius36 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  MultiAnswerCard<T> get radius40 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  MultiAnswerCard<T> get radius48 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  MultiAnswerCard<T> get radius56 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  MultiAnswerCard<T> get radius64 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  MultiAnswerCard<T> get radius9999 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  MultiAnswerCard<T> get primary => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  MultiAnswerCard<T> get secondary => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  MultiAnswerCard<T> get tertiary => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  MultiAnswerCard<T> get surface => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  MultiAnswerCard<T> get surfaceContainer => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  MultiAnswerCard<T> get error => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  MultiAnswerCard<T> get success => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  MultiAnswerCard<T> get warning => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  MultiAnswerCard<T> get info => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  MultiAnswerCard<T> get outline => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  MultiAnswerCard<T> get transparent => withStyle(
    const CoreMultiAnswerCardStyle(backgroundColor: .transparent),
  );
}
