import 'package:coui_flutter/coui_flutter.dart';

class HoverTheme {
  const HoverTheme({
    this.debounceDuration,
    this.hitTestBehavior,
    this.minDuration,
    this.showDuration,
    this.waitDuration,
  });

  final Duration? debounceDuration;
  final HitTestBehavior? hitTestBehavior;
  final Duration? waitDuration;
  final Duration? minDuration;

  final Duration? showDuration;

  @override
  bool operator ==(Object other) {
    return other is HoverTheme &&
        other.debounceDuration == debounceDuration &&
        other.hitTestBehavior == hitTestBehavior &&
        other.waitDuration == waitDuration &&
        other.minDuration == minDuration &&
        other.showDuration == showDuration;
  }

  @override
  int get hashCode => Object.hash(
    debounceDuration,
    hitTestBehavior,
    waitDuration,
    minDuration,
    showDuration,
  );
}

/// A widget that tracks the hover state of the mouse cursor
/// and will call the [onHover] with period of [debounceDuration] when the cursor is hovering over the child widget.
class HoverActivity extends StatefulWidget {
  const HoverActivity({
    required this.child,
    this.debounceDuration,
    this.hitTestBehavior,
    super.key,
    this.onEnter,
    this.onExit,
    this.onHover,
  });

  final Widget child;
  final VoidCallback? onHover;
  final VoidCallback? onExit;
  final VoidCallback? onEnter;
  final Duration? debounceDuration;

  final HitTestBehavior? hitTestBehavior;

  @override
  State<HoverActivity> createState() => _HoverActivityState();
}

class _HoverActivityState extends State<HoverActivity>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.debounceDuration,
      vsync: this,
    );
    _controller.addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) {
    widget.onHover?.call();
  }

  @override
  void didUpdateWidget(covariant HoverActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.debounceDuration;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<HoverTheme>(context);
    final debounceDuration = styleValue(
      widgetValue: widget.debounceDuration,
      themeValue: compTheme?.debounceDuration,
      defaultValue: const Duration(milliseconds: 100),
    );
    final behavior = styleValue(
      widgetValue: widget.hitTestBehavior,
      themeValue: compTheme?.hitTestBehavior,
      defaultValue: HitTestBehavior.deferToChild,
    );
    _controller.duration = debounceDuration;

    return MouseRegion(
      onEnter: (_) {
        widget.onEnter?.call();
        _controller.repeat(reverse: true);
      },
      onExit: (_) {
        _controller.stop();
        widget.onExit?.call();
      },
      hitTestBehavior: behavior,
      child: widget.child,
    );
  }
}

class Hover extends StatefulWidget {
  const Hover({
    required this.child,
    this.hitTestBehavior,
    super.key,
    this.minDuration,
    required this.onHover,
    this.showDuration,
    this.waitDuration,
  });

  final Widget child;
  final void Function(bool hovered) onHover;
  final Duration? waitDuration;
  final Duration?
  minDuration; // The minimum duration to show the hover, if the cursor is quickly moved over the widget.
  final Duration? showDuration; // The duration to show the hover

  final HitTestBehavior? hitTestBehavior;

  @override
  _HoverState createState() => _HoverState();
}

class _HoverState extends State<Hover> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _enterTime;
  late Duration _waitDur;
  late Duration _minDur;
  late Duration _showDur;
  late HitTestBehavior _behavior;

  @override
  void initState() {
    super.initState();
    _waitDur = widget.waitDuration ?? const Duration(milliseconds: 500);
    _minDur = widget.minDuration ?? const Duration();
    _showDur = widget.showDuration ?? const Duration(milliseconds: 200);
    _controller = AnimationController(duration: _waitDur, vsync: this);
    _controller.addStatusListener(_onStatusChanged);
  }

  void _onEnter() {
    _enterTime = DateTime.now().millisecondsSinceEpoch;
    _controller.forward();
  }

  void _onExit(bool cursorOut) {
    final minDuration = _minDur.inMilliseconds;
    final enterTime = _enterTime;
    if (enterTime != null) {
      final duration = DateTime.now().millisecondsSinceEpoch - enterTime;
      _controller.reverseDuration = cursorOut
          ? Duration(milliseconds: duration < minDuration ? minDuration : 0)
          : _showDur;
      _controller.reverse();
    }
    _enterTime = null;
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onHover(true);
    } else if (status == AnimationStatus.dismissed) {
      widget.onHover(false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final compTheme = ComponentTheme.maybeOf<HoverTheme>(context);
    _waitDur = styleValue(
      widgetValue: widget.waitDuration,
      themeValue: compTheme?.waitDuration,
      defaultValue: const Duration(milliseconds: 500),
    );
    _minDur = styleValue(
      widgetValue: widget.minDuration,
      themeValue: compTheme?.minDuration,
      defaultValue: const Duration(),
    );
    _showDur = styleValue(
      widgetValue: widget.showDuration,
      themeValue: compTheme?.showDuration,
      defaultValue: const Duration(milliseconds: 200),
    );
    _behavior = styleValue(
      widgetValue: widget.hitTestBehavior,
      themeValue: compTheme?.hitTestBehavior,
      defaultValue: HitTestBehavior.deferToChild,
    );
    _controller.duration = _waitDur;
    final enableLongPress =
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.android ||
        platform == TargetPlatform.fuchsia;

    return TapRegion(
      behavior: _behavior,
      onTapOutside: (details) {
        _onExit(true);
      },
      child: MouseRegion(
        onEnter: (_) => _onEnter(),
        onExit: (_) {
          _onExit(true);
        },
        hitTestBehavior: _behavior,
        child: GestureDetector(
          /// For mobile platforms, hover is triggered by a long press.
          onLongPressDown: enableLongPress
              ? (details) {
                  _onEnter();
                }
              : null,
          onLongPressCancel: enableLongPress
              ? () {
                  _onExit(true);
                }
              : null,

          onLongPressUp: enableLongPress
              ? () {
                  _onExit(true);
                }
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}
