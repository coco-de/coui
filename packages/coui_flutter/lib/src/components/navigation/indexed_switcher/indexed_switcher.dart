import 'package:coui_flutter/coui_flutter.dart';

/// Shows one of [children] at a time, keeps every child built, and fades
/// through when [index] changes.
///
/// The switch between top-level destinations — the screens a
/// `NavigationBar`, rail or sidebar moves between. Every child stays built
/// while hidden, the same as an `IndexedStack`, so a destination keeps its
/// scroll position, input and nested navigation when the user comes back.
/// The switch itself is a fade through: the outgoing view fades out, then
/// the incoming view fades in (see [CoreIndexedSwitcherStyle]).
///
/// Only the shown child takes pointer input, keyboard focus and a place in
/// the semantics tree. The outgoing view loses all three as soon as the
/// switch starts, while it is still fading out.
///
/// It sizes and aligns its children the way `IndexedStack` does, so it can
/// stand in for one — including as the branch container of a router's
/// stateful shell, where each child is a branch navigator:
///
/// ```dart
/// StatefulShellRoute(
///   navigatorContainerBuilder: (context, navigationShell, children) =>
///       IndexedSwitcher(
///         index: navigationShell.currentIndex,
///         children: children,
///       ),
///   builder: (context, state, navigationShell) =>
///       AppShell(navigationShell: navigationShell),
///   branches: [...],
/// )
/// ```
///
/// A reduced-motion request makes the switch instant.
class IndexedSwitcher extends StatefulWidget
    implements CoreIndexedSwitcherContract<Widget> {
  /// Creates an [IndexedSwitcher].
  const IndexedSwitcher({
    required this.children,
    this.index = 0,
    this.indexedSwitcherStyle,
    super.key,
  });

  @override
  final int index;

  @override
  final CoreIndexedSwitcherStyle? indexedSwitcherStyle;

  @override
  final List<Widget> children;

  /// Returns a copy with the given fields replaced.
  IndexedSwitcher copyWith({
    Key? key,
    int? index,
    CoreIndexedSwitcherStyle? indexedSwitcherStyle,
    List<Widget>? children,
  }) {
    return IndexedSwitcher(
      key: key ?? this.key,
      index: index ?? this.index,
      indexedSwitcherStyle: indexedSwitcherStyle ?? this.indexedSwitcherStyle,
      children: children ?? this.children,
    );
  }

  @override
  State<IndexedSwitcher> createState() => _IndexedSwitcherState();
}

/// Generic `withStyle` chain over `CoreIndexedSwitcherStyle.merge`.
extension IndexedSwitcherStyleChain on IndexedSwitcher {
  /// Returns a copy whose style has [patch] merged on top.
  IndexedSwitcher withStyle(CoreIndexedSwitcherStyle patch) => copyWith(
    indexedSwitcherStyle:
        (indexedSwitcherStyle ?? const CoreIndexedSwitcherStyle()).merge(
          patch,
        ),
  );
}

class _IndexedSwitcherState extends State<IndexedSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );

  /// The child fading out, or `null` once the switch has settled.
  int? _outgoing;

  Animation<double> _exitOpacity = kAlwaysDismissedAnimation;
  Animation<double> _enterOpacity = kAlwaysCompleteAnimation;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleStatusChanged);
  }

  @override
  void didUpdateWidget(covariant IndexedSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _switchFrom(oldWidget.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status != .completed || _outgoing == null) return;
    setState(_settle);
  }

  void _settle() {
    _outgoing = null;
    _exitOpacity = kAlwaysDismissedAnimation;
    _enterOpacity = kAlwaysCompleteAnimation;
  }

  void _switchFrom(int previous) {
    final resolved = resolveIndexedSwitcher(
      context,
      indexedSwitcherStyle: widget.indexedSwitcherStyle,
    );
    // The leaving view starts from what it shows now, so a switch that cuts
    // into another never flashes a half-faded view back to full strength.
    // The fade-out keeps its length even when there is nothing left to
    // fade: the Web twin's CSS transition cannot skip it either, and the
    // two platforms keep one timeline.
    final startOpacity = _enterOpacity.value;
    final total = resolved.exitDuration + resolved.enterDuration;
    if (total <= Duration.zero) {
      // Settled first, so the completed status the jump reports finds
      // nothing to settle and does not ask for a second build.
      _settle();
      _controller.value = 1;

      return;
    }

    final exitEnd = resolved.exitDuration.inMicroseconds / total.inMicroseconds;
    _outgoing = previous;
    _exitOpacity = _controller.drive(
      _FadeOut(end: exitEnd, curve: resolved.exitCurve, from: startOpacity),
    );
    _enterOpacity = _controller.drive(
      _FadeIn(begin: exitEnd, curve: resolved.enterCurve),
    );
    _controller
      ..duration = total
      ..forward(from: 0);
  }

  Widget _buildSlot(int i, Widget child) {
    final shown = i == widget.index;
    final leaving = !shown && i == _outgoing;
    final opacity = shown
        ? _enterOpacity
        : (leaving ? _exitOpacity : kAlwaysDismissedAnimation);

    // The wrapper chain is the same for every child on every build — only
    // its flags change — so switching never rebuilds a child's subtree and
    // a destination keeps its state.
    return Visibility(
      visible: shown || leaving,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: IgnorePointer(
        ignoring: !shown,
        child: ExcludeSemantics(
          excluding: !shown,
          child: ExcludeFocus(
            excluding: !shown,
            // The arriving view is in the semantics tree from the first
            // frame, while it is still transparent: opacity alone would drop
            // it for the whole fade-out. `ExcludeSemantics` above is what
            // decides who is in.
            child: FadeTransition(
              opacity: opacity,
              alwaysIncludeSemantics: true,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.children;

    return Stacks(
      children: [
        for (var i = 0; i < children.length; i++) _buildSlot(i, children[i]),
      ],
    );
  }
}

/// The leaving view's opacity: [from] down to zero over `[0, end]` of the
/// switch, eased by [curve].
class _FadeOut extends Animatable<double> {
  const _FadeOut({required this.end, required this.curve, required this.from});

  final double end;
  final Curve curve;
  final double from;

  @override
  double transform(double t) {
    if (t >= end) return 0;

    return from * (1 - curve.transform(t / end));
  }
}

/// The arriving view's opacity: zero until [begin], then up to one by the
/// end of the switch, eased by [curve].
class _FadeIn extends Animatable<double> {
  const _FadeIn({required this.begin, required this.curve});

  final double begin;
  final Curve curve;

  @override
  double transform(double t) {
    if (t <= begin) return 0;
    if (begin >= 1) return 1;

    return curve.transform(((t - begin) / (1 - begin)).clamp(0.0, 1.0));
  }
}
