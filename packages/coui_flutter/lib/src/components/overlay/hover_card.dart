import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for hover card behavior and appearance.
///
/// Defines timing, positioning, and interaction behavior for hover cards,
/// providing consistent styling across the application.
///
/// Example:
/// ```dart
/// ComponentThemeData(
///   data: {
///     HoverCardTheme: HoverCardTheme(
///       debounce: Duration(milliseconds: 300),
///       wait: Duration(milliseconds: 700),
///       popoverAlignment: Alignment.topCenter,
///     ),
///   },
///   child: MyApp(),
/// )
/// ```
class HoverCardTheme {
  /// Creates a [HoverCardTheme].
  ///
  /// All parameters are optional and will use system defaults when null.
  ///
  /// Parameters:
  /// - [debounce] (Duration?, optional): delay before hiding after mouse exit
  /// - [wait] (Duration?, optional): delay before showing after mouse enter
  /// - [popoverAlignment] (AlignmentGeometry?, optional): popover alignment
  /// - [anchorAlignment] (AlignmentGeometry?, optional): anchor point alignment
  /// - [popoverOffset] (Offset?, optional): offset from calculated position
  /// - [behavior] (HitTestBehavior?, optional): mouse interaction behavior
  ///
  /// Example:
  /// ```dart
  /// const HoverCardTheme(
  ///   debounce: Duration(milliseconds: 200),
  ///   wait: Duration(milliseconds: 600),
  ///   popoverAlignment: Alignment.bottomCenter,
  /// )
  /// ```
  const HoverCardTheme({
    this.anchorAlignment,
    this.behavior,
    this.debounce,
    this.popoverAlignment,
    this.popoverOffset,
    this.wait,
  });

  /// Duration to wait before hiding the hover card after mouse exit.
  final Duration? debounce;

  /// Duration to wait before showing the hover card after mouse enter.
  final Duration? wait;

  /// Alignment of the popover relative to its anchor.
  final AlignmentGeometry? popoverAlignment;

  /// Alignment point on the anchor widget.
  final AlignmentGeometry? anchorAlignment;

  /// Offset of the popover from its calculated position.
  final Offset? popoverOffset;

  /// Hit test behavior for mouse interactions.
  final HitTestBehavior? behavior;

  @override
  bool operator ==(Object other) {
    return other is HoverCardTheme &&
        other.debounce == debounce &&
        other.wait == wait &&
        other.popoverAlignment == popoverAlignment &&
        other.anchorAlignment == anchorAlignment &&
        other.popoverOffset == popoverOffset &&
        other.behavior == behavior;
  }

  @override
  int get hashCode => Object.hash(
    debounce,
    wait,
    popoverAlignment,
    anchorAlignment,
    popoverOffset,
    behavior,
  );
}

/// A widget that displays a popover when hovered or long-pressed.
///
/// Shows contextual information or actions when the user hovers over the
/// child widget or performs a long press. Includes intelligent timing
/// controls to prevent flickering and provides smooth user interactions.
///
/// Features:
/// - Hover-based popover display with timing controls
/// - Long-press support for touch devices
/// - Configurable positioning and alignment
/// - Debounce timing to prevent flicker
/// - Custom overlay handlers support
/// - Theme integration
///
/// The hover card automatically manages show/hide timing based on mouse
/// enter/exit events, with configurable delays to provide a smooth UX.
///
/// Example:
/// ```dart
/// HoverCard(
///   hoverBuilder: (context) => Card(
///     child: Padding(
///       padding: EdgeInsets.all(12),
///       child: Text('Additional info appears on hover'),
///     ),
///   ),
///   child: Icon(Icons.help_outline),
/// )
/// ```
class HoverCard extends StatefulWidget {
  /// Creates a [HoverCard].
  ///
  /// The [child] and [hoverBuilder] parameters are required.
  ///
  /// Parameters:
  /// - [child] (Widget, required): widget that triggers the hover card
  /// - [hoverBuilder] (WidgetBuilder, required): builds the hover card content
  /// - [debounce] (Duration?, optional): delay before hiding, defaults to 500ms
  /// - [wait] (Duration?, optional): delay before showing, defaults to 500ms
  /// - [popoverAlignment] (AlignmentGeometry?, optional): popover alignment, defaults to topCenter
  /// - [anchorAlignment] (AlignmentGeometry?, optional): anchor alignment, defaults to bottomCenter
  /// - [popoverOffset] (Offset?, optional): offset from position, defaults to (0, 8)
  /// - [behavior] (HitTestBehavior?, optional): hit test behavior, defaults to deferToChild
  /// - [controller] (PopoverController?, optional): controller for programmatic control
  /// - [handler] (OverlayHandler?, optional): custom overlay handler
  ///
  /// Example:
  /// ```dart
  /// HoverCard(
  ///   debounce: Duration(milliseconds: 300),
  ///   hoverBuilder: (context) => Tooltip(message: 'Help text'),
  ///   child: Icon(Icons.info),
  /// )
  /// ```
  const HoverCard({
    this.anchorAlignment,
    this.behavior,
    required this.child,
    this.controller,
    this.debounce,
    this.handler,
    required this.hoverBuilder,
    super.key,
    this.popoverAlignment,
    this.popoverOffset,
    this.wait,
  });

  /// The child widget that triggers the hover card.
  final Widget child;

  /// Duration to wait before hiding after mouse exit.
  final Duration? debounce;

  /// Duration to wait before showing after mouse enter.
  final Duration? wait;

  /// Builder function that creates the hover card content.
  final WidgetBuilder hoverBuilder;

  /// Alignment of the popover relative to its anchor.
  final AlignmentGeometry? popoverAlignment;

  /// Alignment point on the anchor widget.
  final AlignmentGeometry? anchorAlignment;

  /// Offset of the popover from its calculated position.
  final Offset? popoverOffset;

  /// Hit test behavior for mouse interactions.
  final HitTestBehavior? behavior;

  /// Controller to programmatically manage the popover.
  final PopoverController? controller;

  /// Custom overlay handler for popover display.
  final OverlayHandler? handler;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  late PopoverController _controller;

  int _hoverCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PopoverController();
  }

  void _showPopover(
    BuildContext context, {
    required AlignmentGeometry alignment,
    AlignmentGeometry? anchorAlignment,
    required Duration debounce,
    required Offset offset,
  }) {
    OverlayHandler? handler = widget.handler;
    if (handler == null) {
      final overlayManager = OverlayManager.of(context);
      handler = OverlayManagerAsTooltipOverlayHandler(
        overlayManager: overlayManager,
      );
    }
    _controller.show<void>(
      alignment: alignment,
      anchorAlignment: anchorAlignment,
      context: context,
      handler: handler,
      offset: offset,
      builder: (context) {
        return MouseRegion(
          onEnter: (_) {
            _hoverCount += 1;
          },
          onExit: (_) {
            final count = _hoverCount += 1;
            Future.delayed(debounce, () {
              if (count == _hoverCount) {
                _controller.close();
              }
            });
          },
          child: widget.hoverBuilder(context),
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant HoverCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? PopoverController();
    }
  }

  @override
  void dispose() {
    /// Use this instead of dispose() because controlled might not be ours.
    _controller.disposePopovers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<HoverCardTheme>(context);
    final debounce = styleValue(
      widgetValue: widget.debounce,
      themeValue: compTheme?.debounce,
      defaultValue: const Duration(milliseconds: 500),
    );
    final wait = styleValue(
      widgetValue: widget.wait,
      themeValue: compTheme?.wait,
      defaultValue: const Duration(milliseconds: 500),
    );
    final popoverAlignment = styleValue(
      widgetValue: widget.popoverAlignment,
      themeValue: compTheme?.popoverAlignment,
      defaultValue: Alignment.topCenter,
    );
    final anchorAlignment = styleValue(
      widgetValue: widget.anchorAlignment,
      themeValue: compTheme?.anchorAlignment,
      defaultValue: Alignment.bottomCenter,
    );
    final popoverOffset = styleValue(
      widgetValue: widget.popoverOffset,
      themeValue: compTheme?.popoverOffset,
      defaultValue: const Offset(0, 8),
    );
    final behavior = styleValue(
      widgetValue: widget.behavior,
      themeValue: compTheme?.behavior,
      defaultValue: HitTestBehavior.deferToChild,
    );

    return MouseRegion(
      onEnter: (_) {
        final count = _hoverCount += 1;
        Future.delayed(wait, () {
          if (count == _hoverCount &&
              !_controller.hasOpenPopover &&
              context.mounted) {
            _showPopover(
              context,
              alignment: popoverAlignment,
              anchorAlignment: anchorAlignment,
              debounce: debounce,
              offset: popoverOffset,
            );
          }
        });
      },
      onExit: (_) {
        final count = _hoverCount += 1;
        Future.delayed(debounce, () {
          if (count == _hoverCount) {
            _controller.close();
          }
        });
      },
      hitTestBehavior: behavior,
      child: GestureDetector(
        onLongPress: () {
          /// Open popover on long press.
          _showPopover(
            context,
            alignment: popoverAlignment,
            anchorAlignment: anchorAlignment,
            debounce: debounce,
            offset: popoverOffset,
          );
        },
        child: widget.child,
      ),
    );
  }
}
