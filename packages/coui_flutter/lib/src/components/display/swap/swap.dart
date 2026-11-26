import 'dart:async';
import 'dart:math' show pi;

import 'package:coui_flutter/coui_flutter.dart';

/// Perspective value for 3D transform.
const _kPerspective = 0.001;

/// Matrix4 perspective row index.
const _kPerspectiveRow = 3;

/// Mid-point of the controller range [0, 1] — used to pick which face
/// is shown during a flip animation (back-face culling equivalent).
const _kFlipMidpoint = 0.5;

/// Unified cross-platform swap component with token-based rendering.
///
/// Toggles between two visual states with optional animation.
/// Uses [CoreSwapContract] from `coui_core` for consistent
/// cross-platform API.
///
/// Example:
/// ```dart
/// Swap(
///   checked: _isOn,
///   animation: CoreSwapAnimation.rotate,
///   onContent: Icon(LucideIcons.sun),
///   offContent: Icon(LucideIcons.moon),
///   onToggle: (value) => setState(() => _isOn = value),
/// )
/// ```
class Swap extends StatefulWidget implements CoreSwapContract<Widget> {
  /// Creates a [Swap].
  const Swap({
    super.key,
    this.animation = CoreSwapAnimation.none,
    this.checked = false,
    required this.offContent,
    required this.onContent,
    this.onToggle,
    this.swapStyle,
  });

  @override
  final Widget onContent;

  @override
  final Widget offContent;

  @override
  final bool checked;

  @override
  final CoreSwapAnimation animation;

  /// Toggle callback.
  @override
  final ValueChanged<bool>? onToggle;

  @override
  final CoreSwapStyle? swapStyle;

  /// Returns a copy of this [Swap] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Swap copyWith({
    Key? key,
    CoreSwapAnimation? animation,
    bool? checked,
    Widget? offContent,
    Widget? onContent,
    ValueChanged<bool>? onToggle,
    CoreSwapStyle? swapStyle,
  }) {
    return Swap(
      key: key ?? this.key,
      animation: animation ?? this.animation,
      checked: checked ?? this.checked,
      offContent: offContent ?? this.offContent,
      onContent: onContent ?? this.onContent,
      onToggle: onToggle ?? this.onToggle,
      swapStyle: swapStyle ?? this.swapStyle,
    );
  }

  @override
  State<Swap> createState() => _SwapState();
}

class _SwapState extends State<Swap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // `CurveTween` is an `Animatable` — nothing to dispose alongside the
  // controller, unlike a `CurvedAnimation` which registers a listener on it.
  late final Animation<double> _eased = _controller.drive(
    CurveTween(curve: CoreEasing.move.toValue()),
  );

  @override
  void initState() {
    super.initState();
    // initState has no `BuildContext` access for `coreComponentTheme`
    // (theme lookups happen in `build`). Seed the controller with the
    // design-system default duration; `build` re-syncs the controller
    // duration once the theme is available.
    _controller = AnimationController(
      value: widget.checked ? 1.0 : 0.0,
      duration: CoreSwapStyle.defaultDuration,
      vsync: this,
    );
  }

  void handleTap() {
    widget.onToggle?.call(!widget.checked);
  }

  Widget _buildContent(
    BuildContext context,
    double value,
    TextStyle textStyle,
  ) {
    if (widget.animation == .flip) {
      // Back-face culling equivalent: show exactly one face based on
      // which side of the 180° turn we're on. No opacity blending —
      // the 3D rotation is what makes the change visible. The `on`
      // content is counter-rotated 180° so it reads upright after the
      // container flips.
      final showOn = value >= _kFlipMidpoint;
      return DefaultTextStyle(
        style: textStyle,
        child: showOn
            ? Transform(
                transform: Matrix4.identity()..rotateY(pi),
                alignment: .center,
                child: widget.onContent,
              )
            : widget.offContent,
      );
    }
    return DefaultTextStyle(
      style: textStyle,
      child: Stacks(
        alignment: .center,
        children: [
          Opacity(opacity: 1 - value, child: widget.offContent),
          Opacity(opacity: value, child: widget.onContent),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(Swap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checked != widget.checked) {
      if (widget.checked) {
        unawaited(_controller.forward());
      } else {
        unawaited(_controller.reverse());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSwap(context, swapStyle: widget.swapStyle);
    if (_controller.duration != resolved.duration) {
      _controller.duration = resolved.duration;
    }
    final content = AnimatedBuilder(
      animation: _eased,
      builder: (context, _) {
        final value = _eased.value;

        return switch (widget.animation) {
          .rotate => Transform.rotate(
            angle: value * pi,
            child: _buildContent(context, value, resolved.textStyle),
          ),
          .flip => Transform(
            transform: Matrix4.identity()
              ..setEntry(_kPerspectiveRow, 2, _kPerspective)
              ..rotateY(value * pi),
            alignment: .center,
            child: _buildContent(context, value, resolved.textStyle),
          ),
          .none => _buildContent(context, value, resolved.textStyle),
        };
      },
    );

    // Non-interactive swap (no onToggle) is a pure display surface
    // driven externally — no Clickable wrapper, so it keeps the plain
    // cursor / full opacity (Clickable's `enabled: false` would paint
    // the disabled affordance).
    if (widget.onToggle == null) {
      return content;
    }

    // Flutter twin of the Web swap root: the Clickable owns tap /
    // keyboard activation / cursor / press feedback / focus ring
    // (composition — no hand-rolled GestureDetector + MouseRegion).
    // The rotate/flip Transform lives inside [content], so the press
    // scale (Clickable's own AnimatedScale wrapper) composes with it
    // instead of fighting over the same transform.
    return Clickable(
      onPressed: handleTap,
      clickableStyle: resolved.clickableStyle,
      child: Semantics(
        toggled: widget.checked,
        button: true,
        child: content,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSwapStyle] patch into
/// [Swap.swapStyle] without hand-reconstructing every field. Mirrors
/// the Web `Swap.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSwapStyle.merge` right-side-wins semantics).
extension SwapStyleChain on Swap {
  /// Returns a copy of this [Swap] with [patch] merged into
  /// [swapStyle] (patch fields win on conflict).
  Swap withStyle(CoreSwapStyle patch) =>
      copyWith(swapStyle: (swapStyle ?? const CoreSwapStyle()).merge(patch));
}
