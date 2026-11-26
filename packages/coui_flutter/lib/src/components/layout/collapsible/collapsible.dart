import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';

// ---------------------------------------------------------------------------
// _CollapsibleStateData (internal, shared via Data.inherit)
// ---------------------------------------------------------------------------

class _CollapsibleStateData {
  const _CollapsibleStateData({
    required this.handleToggle,
    required this.isExpanded,
  });

  final VoidCallback handleToggle;
  final bool isExpanded;
}

// ---------------------------------------------------------------------------
// Collapsible
// ---------------------------------------------------------------------------

/// Unified collapsible component.
///
/// Provides a trigger element and content that can be toggled
/// between expanded and collapsed states with animated transitions.
///
/// ```dart
/// Collapsible(
///   trigger: Text('Toggle Content'),
///   content: Text('Hidden content here'),
///   expanded: false,
/// )
/// ```
class Collapsible extends StatefulWidget
    implements CoreCollapsibleContract<Widget> {
  /// Creates a [Collapsible].
  const Collapsible({
    required this.trigger,
    required this.content,
    this.expanded = false,
    super.key,
    this.onExpandedChanged,
    this.collapsibleStyle,
  });

  @override
  final Widget trigger;

  @override
  final Widget content;

  @override
  final bool expanded;

  @override
  final void Function(bool)? onExpandedChanged;

  @override
  final CoreCollapsibleStyle? collapsibleStyle;

  /// Returns a copy of this [Collapsible] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Collapsible copyWith({
    Key? key,
    Widget? trigger,
    Widget? content,
    bool? expanded,
    void Function(bool)? onExpandedChanged,
    CoreCollapsibleStyle? collapsibleStyle,
  }) {
    return Collapsible(
      key: key ?? this.key,
      trigger: trigger ?? this.trigger,
      content: content ?? this.content,
      expanded: expanded ?? this.expanded,
      onExpandedChanged: onExpandedChanged ?? this.onExpandedChanged,
      collapsibleStyle: collapsibleStyle ?? this.collapsibleStyle,
    );
  }

  @override
  State<Collapsible> createState() => _CollapsibleState();
}

/// Chain sugar for merging a [CoreCollapsibleStyle] patch into
/// [Collapsible.collapsibleStyle] without hand-reconstructing every
/// field. Mirrors the Web `Collapsible.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCollapsibleStyle.merge` right-side-wins semantics).
extension CollapsibleStyleChain on Collapsible {
  /// Returns a copy of this [Collapsible] with [patch] merged into
  /// [collapsibleStyle] (patch fields win on conflict).
  Collapsible withStyle(CoreCollapsibleStyle patch) => copyWith(
    collapsibleStyle: (collapsibleStyle ?? const CoreCollapsibleStyle()).merge(
      patch,
    ),
  );
}

class _CollapsibleState extends State<Collapsible>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // A `CurveTween` driven off the controller is an `Animatable`, so there is
  // nothing to dispose — the curve is constant and only the duration follows
  // the theme, so the eased view is built once instead of per dependency
  // change (a `CurvedAnimation` rebuilt there leaked its listener each time).
  late final Animation<double> _curvedAnimation = _controller.drive(
    CurveTween(curve: CoreEasing.move.toValue()),
  );

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expanded;
    _controller = AnimationController(
      value: _isExpanded ? 1 : 0,
      duration: const Duration(milliseconds: CoreDuration.normal),
      vsync: this,
    );
  }

  void _updateAnimationConfig() {
    _controller.duration = resolveCollapsible(
      context,
      collapsibleStyle: widget.collapsibleStyle,
    ).duration;
  }

  void _handleToggle() {
    if (widget.onExpandedChanged != null) {
      widget.onExpandedChanged!(!_isExpanded);
    } else {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }

    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(covariant Collapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimationConfig();
    if (widget.expanded != oldWidget.expanded) {
      _isExpanded = widget.expanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimationConfig();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCollapsible(
      context,
      collapsibleStyle: widget.collapsibleStyle,
    );
    final effectivePadding = resolved.contentInset;

    return Data.inherit(
      data: _CollapsibleStateData(
        handleToggle: _handleToggle,
        isExpanded: _isExpanded,
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            _CollapsibleTrigger(
              collapsibleStyle: widget.collapsibleStyle,
              child: widget.trigger,
            ),
            // Out of the tab order while closed — same reasoning as the
            // accordion, same mechanism. See that file for why this is
            // `ExcludeFocus` rather than the framework's subtree flag.
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => ExcludeFocus(
                excluding: _controller.isDismissed,
                child: child!,
              ),
              child: SizeTransition(
                sizeFactor: _curvedAnimation,
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: .only(top: effectivePadding.top),
                  child: DefaultTextStyle.merge(
                    style: resolved.contentTextStyle,
                    child: widget.content,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CollapsibleTrigger (internal)
// ---------------------------------------------------------------------------

class _CollapsibleTrigger extends StatefulWidget {
  const _CollapsibleTrigger({required this.child, this.collapsibleStyle});

  final Widget child;

  final CoreCollapsibleStyle? collapsibleStyle;

  @override
  State<_CollapsibleTrigger> createState() => _CollapsibleTriggerState();
}

class _CollapsibleTriggerState extends State<_CollapsibleTrigger> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCollapsible(
      context,
      collapsibleStyle: widget.collapsibleStyle,
    );
    final effectivePadding = resolved.contentInset;

    // Paint-ready trigger text style from the resolver — the widget layers
    // only the interaction-state hover underline on top (Web parity:
    // `hover:underline`). `decorationColor` tracks the resolved foreground
    // so light/dark stays consistent.
    final triggerTextStyle = resolved.triggerTextStyle.copyWith(
      decoration: _hovering ? .underline : .none,
      decorationColor: resolved.triggerTextStyle.color,
    );

    final state = Data.of<_CollapsibleStateData>(context);
    final collapsibleState = context
        .findAncestorStateOfType<_CollapsibleState>();

    // Composition: the trigger's tap / keyboard activation (Enter /
    // Space) / cursor / focus ring / selection-exclusion all flow through
    // the unified `Clickable` (no hand-rolled MouseRegion +
    // GestureDetector + FocusableActionDetector + FocusOutline +
    // SelectionContainer). `onHover` keeps the hover-underline; the focus
    // ring / press chrome come from `resolved.clickableStyle`
    // (press-scale off for the full-width row; ring radius from the
    // Clickable's own default). The `expanded` state mirrors Web's
    // `aria-expanded` via `Semantics` (capability parity).
    return Clickable(
      onPressed: state.handleToggle,
      onHover: (hovered) => setState(() => _hovering = hovered),
      clickableStyle: resolved.clickableStyle,
      child: Semantics(
        button: true,
        expanded: state.isExpanded,
        child: Padding(
          padding: effectivePadding,
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: .centerStart,
                  child: DefaultTextStyle.merge(
                    style: triggerTextStyle,
                    child: widget.child,
                  ),
                ),
              ),
              Gap(gapStyle: resolved.iconLabelGapStyle),
              if (collapsibleState != null)
                AnimatedBuilder(
                  animation: collapsibleState._controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: collapsibleState._controller.value * pi,
                      child: child,
                    );
                  },
                  child: Icon(
                    LucideIcons.chevronDown,
                    iconStyle: resolved.iconStyle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
