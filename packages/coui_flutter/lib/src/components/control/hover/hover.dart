import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:coui_flutter/coui_flutter.dart';

/// Identity colour matrix offset — leaves a channel unchanged.
const _kMatrixIdentity = 1.0;

/// Blur-radius → Gaussian-sigma factor for the `shadow` effect's
/// `ImageFilter.blur`, matching how Chrome renders `filter: drop-shadow()`
/// (the mechanism the Web `Hover` uses to follow the child's shape).
///
/// Measured empirically: Chrome's `drop-shadow(r)` blurs with σ ≈ r×0.95
/// — near the SVG `feGaussianBlur` convention (σ = r) and ~1.9× wider than
/// a `box-shadow(r)` (σ ≈ r×0.5) or Flutter's own `BoxShadow`
/// (σ = r×0.57735+0.5). Because the Web side casts this shadow with
/// `drop-shadow`, Flutter matches that wider blur so the two platforms
/// read at the same strength.
const _kDropShadowBlurToSigma = 0.95;

/// Unified cross-platform hover component with token-based behaviour.
///
/// Wraps a [child] and provides two features that stay in sync across
/// Flutter and Web:
///
/// 1. **Hover-state tracking** — reports the pointer hover state via
///    [onHover] / [onEnter] / [onExit]. [onHover] fires `true` once the
///    pointer has rested for [waitDuration] and `false` once it has
///    left for [showDuration] (kept active at least [minDuration]).
/// 2. **Hover visual effect** — animates the chosen [effect]
///    (scale / fade / brighten / shadow) while the pointer is over the
///    child.
///
/// Uses [CoreHoverContract] from `coui_core` for a consistent
/// cross-platform API.
///
/// Example:
/// ```dart
/// Hover(
///   effect: CoreHoverEffect.scaleUp,
///   onHover: (hovered) => debugPrint('hovered: $hovered'),
///   child: Card(child: const Text('Hover me')),
/// )
/// ```
class Hover extends StatefulWidget implements CoreHoverContract<Widget> {
  /// Creates a [Hover].
  const Hover({
    super.key,
    this.effect = CoreHoverEffect.defaultEffect,
    this.minDuration,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.showDuration,
    this.waitDuration,
    this.hoverStyle,
    this.child,
  });

  @override
  final Widget? child;

  @override
  final CoreHoverEffect effect;

  @override
  final ValueChanged<bool>? onHover;

  @override
  final VoidCallback? onEnter;

  @override
  final VoidCallback? onExit;

  @override
  final Duration? waitDuration;

  @override
  final Duration? showDuration;

  @override
  final Duration? minDuration;

  /// Per-instance style override for the hover visual-effect chrome
  /// (scale / fade / brighten factors, shadow stack, effect duration,
  /// timing defaults).
  final CoreHoverStyle? hoverStyle;

  /// Returns a copy of this [Hover] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Hover copyWith({
    Key? key,
    CoreHoverEffect? effect,
    Duration? minDuration,
    VoidCallback? onEnter,
    VoidCallback? onExit,
    ValueChanged<bool>? onHover,
    Duration? showDuration,
    Duration? waitDuration,
    CoreHoverStyle? hoverStyle,
    Widget? child,
  }) {
    return Hover(
      key: key ?? this.key,
      effect: effect ?? this.effect,
      minDuration: minDuration ?? this.minDuration,
      onEnter: onEnter ?? this.onEnter,
      onExit: onExit ?? this.onExit,
      onHover: onHover ?? this.onHover,
      showDuration: showDuration ?? this.showDuration,
      waitDuration: waitDuration ?? this.waitDuration,
      hoverStyle: hoverStyle ?? this.hoverStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Hover> createState() => _HoverState();
}

/// Chain sugar for merging a [CoreHoverStyle] patch into
/// [Hover.hoverStyle] without hand-reconstructing every field. Mirrors
/// the Web `Hover.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreHoverStyle.merge` right-side-wins semantics).
extension HoverStyleChain on Hover {
  /// Returns a copy of this [Hover] with [patch] merged into
  /// [hoverStyle] (patch fields win on conflict).
  Hover withStyle(CoreHoverStyle patch) => copyWith(
    hoverStyle: (hoverStyle ?? const CoreHoverStyle()).merge(patch),
  );
}

class _HoverState extends State<Hover> {
  /// Pointer is physically over the child — drives the visual effect
  /// immediately (no timing delay), matching Web's CSS `:hover`.
  bool _pointerInside = false;

  /// Resolved hover state reported via [Hover.onHover] — governed by
  /// the wait / show / min timings.
  bool _reportedHovered = false;

  /// Paint-ready resolver output, refreshed on every `build` so the
  /// enter / exit handlers read the latest timings without re-running
  /// the merge chain themselves (C11 — single resolve call).
  late ResolvedHover _resolved;

  int? _enterTime;
  Timer? _enterTimer;
  Timer? _exitTimer;

  void _handleEnter() {
    widget.onEnter?.call();
    _exitTimer?.cancel();
    setState(() => _pointerInside = true);
    _enterTime = DateTime.now().millisecondsSinceEpoch;
    _enterTimer?.cancel();
    _enterTimer = Timer(_resolved.waitDuration, () {
      if (!mounted) return;
      _reportedHovered = true;
      widget.onHover?.call(true);
    });
  }

  void _handleExit() {
    widget.onExit?.call();
    _enterTimer?.cancel();
    setState(() => _pointerInside = false);
    // Mirrors the legacy reverse-duration calculation. When the pointer
    // leaves quickly, before the minimum duration has elapsed, the
    // reported state stays active for the remaining minimum window,
    // otherwise it deactivates after the show duration.
    final enterTime = _enterTime;
    final elapsed = enterTime == null
        ? 0
        : DateTime.now().millisecondsSinceEpoch - enterTime;
    final minMs = _resolved.minDuration.inMilliseconds;
    final exitDelay = elapsed < minMs
        ? Duration(milliseconds: minMs - elapsed)
        : _resolved.showDuration;
    _enterTime = null;
    _exitTimer?.cancel();
    _exitTimer = Timer(exitDelay, () {
      if (!mounted) return;
      if (!_reportedHovered) return;
      _reportedHovered = false;
      widget.onHover?.call(false);
    });
  }

  Widget _applyEffect(Widget content) {
    switch (widget.effect) {
      case .none:
        return content;
      case .scaleUp:
        return AnimatedScale(
          scale: _pointerInside ? _resolved.scaleUpFactor : _kMatrixIdentity,
          duration: _resolved.effectDuration,
          curve: CoreEasing.move.toValue(),
          child: content,
        );
      case .scaleDown:
        return AnimatedScale(
          scale: _pointerInside ? _resolved.scaleDownFactor : _kMatrixIdentity,
          duration: _resolved.effectDuration,
          curve: CoreEasing.move.toValue(),
          child: content,
        );
      case .fade:
        return AnimatedOpacity(
          opacity: _pointerInside ? _resolved.fadeOpacity : _kMatrixIdentity,
          duration: _resolved.effectDuration,
          curve: CoreEasing.move.toValue(),
          child: content,
        );
      case .brighten:
        // Brightness is a linear RGB scale: each channel is multiplied
        // by the brighten factor on hover (1.0 = unchanged). Mirrors
        // the Web `hover:brightness-110` filter.
        final factor = _pointerInside
            ? _resolved.brightenFactor
            : _kMatrixIdentity;
        return AnimatedContainer(
          duration: _resolved.effectDuration,

          curve: _resolved.curve,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix([
              factor, 0, 0, 0, 0, //
              0, factor, 0, 0, 0, //
              0, 0, factor, 0, 0, //
              0, 0, 0, _kMatrixIdentity, 0, //
            ]),
            child: content,
          ),
        );
      case .shadow:
        // Drop shadow that follows the child's rendered shape — parity
        // with Web `filter: drop-shadow()`, so a rounded child (e.g. a
        // `Card`) casts a rounded shadow. Flutter has no single-element
        // drop-shadow primitive, so the effect is composed from blurred,
        // tinted copies of the child (framework-idiom mechanism; the
        // capability + visual result match Web). Encapsulated in
        // [_DropShadow] so this switch arm reads as one wrapping unit.
        return _DropShadow(
          shadows: _resolved.hoverShadows,
          active: _pointerInside,
          duration: _resolved.effectDuration,
          child: content,
        );
    }
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _exitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _resolved = resolveHover(
      context,
      effect: widget.effect,
      waitDuration: widget.waitDuration,
      showDuration: widget.showDuration,
      minDuration: widget.minDuration,
      hoverStyle: widget.hoverStyle,
    );
    final content = _applyEffect(widget.child ?? const SizedBox());
    return MouseRegion(
      onEnter: (_) => _handleEnter(),
      onExit: (_) => _handleExit(),
      child: content,
    );
  }
}

/// A drop shadow that follows the [child]'s rendered shape, faded in/out
/// by [active].
///
/// Web casts this with `filter: drop-shadow(A) drop-shadow(B) …` on the
/// wrapper. That is a *pipeline*, not a parallel stack — per the CSS
/// Filter Effects spec each function runs on the output of the one
/// before it (`B(A(source))`), so `B`'s silhouette already includes `A`'s
/// shadow and casts its own offset copy from that combined shape, not
/// from the pristine source. Measured directly (a two-layer hard, fully
/// opaque, offset stack rendered to pixels): the compound reach lands
/// exactly where chaining predicts and is visibly farther than an
/// independent-copy-per-layer emulation would produce — confirmed before
/// this was fixed, when Flutter's shadow read as a smaller, more merged
/// blob than Web's next to it. Flutter has no single-element
/// `drop-shadow` primitive, so [composite] rebuilds that same pipeline
/// explicitly: folding `shadows` left-to-right (the same order the CSS
/// list applies in), each layer's [ColorFiltered] copy wrapping the
/// *accumulated* result of every earlier layer, not [child] directly. A
/// single-layer stack (the common case) degenerates to the old
/// independent form since there is nothing earlier to accumulate.
///
/// An [AnimatedOpacity] fades each layer in/out — unlike an
/// `AnimatedContainer` `boxShadow` `null` ↔ list lerp, which scales blur
/// from zero (a hard-edged flash) as it animates in. All layers share
/// the same [duration] / curve, so they cross-fade in lockstep —
/// matching a CSS `transition: filter …`, which re-runs the same
/// pipeline at every interpolated frame rather than fading each function
/// independently. `drop-shadow` has no spread, so the layer spread is
/// dropped (parity with Web, which drops it too).
///
/// Chaining has a real widget-rebuild cost the independent form did not:
/// each iteration mounts [previous] twice (once recoloured, once bare),
/// so a stack of *n* layers builds `2ⁿ − 1` copies of the accumulated
/// subtree rather than the flat form's `n` (one [AnimatedOpacity] per
/// layer plus one untouched [child]). Every named `CoreShadow` step
/// authors at most two layers (`xs` · `sm`; the floating rungs from `md`
/// up author one) — `2² − 1 = 3` against the flat form's
/// `2` — a difference too small to matter for leaf content this cheap;
/// a caller supplying many more layers than any shipped preset does
/// would feel it. [ExcludeSemantics] keeps the duplication out of the
/// semantics tree regardless of *n* — only the one bare, unwrapped
/// [child] at the bottom of the recursion is ever reachable.
class _DropShadow extends StatelessWidget {
  const _DropShadow({
    required this.shadows,
    required this.active,
    required this.duration,
    required this.child,
  });

  final List<BoxShadow> shadows;
  final bool active;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var composite = child;
    for (final shadow in shadows) {
      final previous = composite;
      composite = Stacks(
        fit: .passthrough,
        clipBehavior: .none,
        children: [
          // `ExcludeSemantics` — chaining now mounts `previous` a second
          // time per layer (once bare, once recolored here), which would
          // otherwise multiply how many times a screen reader announces
          // `child`'s content on top of the pre-existing duplication.
          // `IgnorePointer` alone does not remove this branch from the
          // semantics tree (only from hit-testing), so it is stated here
          // explicitly rather than assumed.
          Position.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: active ? 1.0 : 0.0,
                  duration: duration,
                  curve: CoreEasing.move.toValue(),
                  child: Transform.translate(
                    offset: shadow.offset,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: shadow.blurRadius * _kDropShadowBlurToSigma,
                        sigmaY: shadow.blurRadius * _kDropShadowBlurToSigma,
                        tileMode: .decal,
                      ),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(shadow.color, .srcIn),
                        child: previous,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          previous,
        ],
      );
    }
    return composite;
  }
}
