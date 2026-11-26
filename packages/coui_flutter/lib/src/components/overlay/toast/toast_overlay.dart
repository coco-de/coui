/// Toast overlay presentation system — the layer / location / entry
/// machinery that hosts, stacks, and animates toast notifications.
///
/// Separate from `toast.dart` (the unified [Toast] notification card):
/// the card is *what* is shown, while [showToast] / [ToastLayer] /
/// [ToastLocation] / [ToastOverlay] / [ToastEntry] are *how* it is
/// presented. A `Toast` is the typical widget returned from a
/// [showToast] builder, but the overlay system can host any widget.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:coui_flutter/coui_flutter.dart';

// === Toast Component Constants ===

/// Default number of toasts to display simultaneously.
const _kDefaultMaxStackedEntries = 3;

/// Default vertical offset between stacked toasts.
const _kDefaultCollapsedOffsetY = 12.0;

/// Default toast width.
const _kDefaultToastWidth = 320.0;

/// Delay before collapsing toast stack after mouse exit.
const _kHoverExitDelay = Duration(milliseconds: CoreDuration.moderate);

/// Shift multiplier for expanded toast positioning.
const _kExpandingShiftMultiplier = 16.0;

/// Default duration for toast display before auto-dismiss.
const _kDefaultShowDuration = Duration(seconds: 5);

/// Dismiss threshold for swipe gestures (half way point).
const _kDismissThreshold = 0.5;

/// Default collapsed scale for stacked toasts.
const _kDefaultCollapsedScale = 0.9;

/// Default collapsed opacity for stacked toasts in entry layout.
const _kDefaultCollapsedOpacity = 0.8;

typedef ToastBuilder =
    Widget Function(BuildContext context, ToastOverlay overlay);

/// Displays a toast notification with sophisticated positioning and animation.
///
/// Creates and shows a toast notification using the provided builder function.
/// Within the nearest [ToastLayer] in the widget tree. The toast appears at.
/// The specified location with configurable animation, dismissal behavior,.
/// And automatic timeout.
///
/// The function handles theme capture and data inheritance to ensure the toast.
/// Maintains consistent styling and access to inherited data from the calling.
/// Context. Toast notifications are managed through a layered system that.
/// Supports stacking, expansion, and smooth animations.
///
/// Parameters:
/// - [context] (BuildContext, required): The build context for theme and data capture.
/// - [builder] (ToastBuilder, required): Function that builds the toast content widget.
/// - [location] (ToastLocation, default: bottomRight): Screen position for the toast.
/// - [dismissible] (bool, default: true): Whether users can dismiss via gesture.
/// - [curve] (Curve, default: easeOutCubic): Animation curve for entry/exit transitions.
/// - [entryDuration] (Duration, default: 500ms): Duration for toast entry animation.
/// - [onClosed] (VoidCallback?, optional): Callback invoked when toast is dismissed.
/// - [showDuration] (Duration, default: 5s): Auto-dismiss timeout duration.
///
/// Returns:
/// A [ToastOverlay] instance that provides control methods for the displayed toast.
///
/// Throws:
/// - [AssertionError] if no [ToastLayer] is found in the widget tree.
///
/// Example:
/// ```dart
/// final toast = showToast(
///   context: context,
///   builder: (context, overlay) => AlertCard(
///     title: 'Success',
///     message: 'Operation completed successfully',
///     onDismiss: overlay.close,
///   ),
///   location: ToastLocation.topRight,
///   showDuration: Duration(seconds: 3),.
/// );
/// ```

ToastOverlay showToast({
  required ToastBuilder builder,
  required BuildContext context,
  Curve curve = Curves.easeOutCubic,
  bool dismissible = true,
  Duration entryDuration = const Duration(milliseconds: CoreDuration.slow),
  ToastLocation location = .bottomRight,
  VoidCallback? onClosed,
  Duration showDuration = _kDefaultShowDuration,
}) {
  CapturedThemes? themes;
  CapturedData? data;
  _ToastLayerState? layer = Data.maybeFind<_ToastLayerState>(context);

  if (layer == null) {
    layer = Data.maybeFindMessenger<_ToastLayerState>(context);
  } else {
    themes = InheritedTheme.capture(from: context, to: layer.context);
    data = Data.capture(from: context, to: layer.context);
  }
  assert(layer != null, 'No ToastLayer found in context');

  final entry = ToastEntry(
    curve: curve,
    data: data,
    dismissible: dismissible,
    duration: entryDuration,
    location: location,
    onClosed: onClosed,
    showDuration: showDuration,
    themes: themes,
    builder: builder,
  );

  final result = layer!.addEntry(entry);

  return result;
}

/// Screen position enumeration for toast notification placement.
///
/// ToastLocation defines six standard positions around the screen edges where.
/// Toast notifications can appear. Each location includes alignment information.
/// For both the toast container and the stacking direction of multiple toasts.
///
/// The enum ensures consistent positioning behavior across different screen.
/// Sizes and orientations while providing intuitive placement options for.
/// Various UI patterns and user experience requirements.
enum ToastLocation {
  /// Bottom-center with upward stacking.
  ///
  /// Toasts appear centered at the bottom with new toasts stacking above existing ones.
  /// Popular for confirmation messages and user action feedback.
  bottomCenter(
    alignment: Alignment.bottomCenter,
    childrenAlignment: Alignment.topCenter,
  ),

  /// Bottom-left corner with upward stacking.
  ///
  /// Toasts appear in the bottom-left area with new toasts stacking above existing ones.
  /// Useful for contextual actions and secondary notifications.
  bottomLeft(
    alignment: Alignment.bottomLeft,
    childrenAlignment: Alignment.topCenter,
  ),

  /// Bottom-right corner with upward stacking.
  ///
  /// Toasts appear in the bottom-right area with new toasts stacking above existing ones.
  /// Default location providing unobtrusive notification placement.
  bottomRight(
    alignment: Alignment.bottomRight,
    childrenAlignment: Alignment.topCenter,
  ),

  /// Top-center with downward stacking.
  ///
  /// Toasts appear centered at the top with new toasts stacking below existing ones.
  /// Ideal for important notifications that need prominent visibility.
  topCenter(
    alignment: Alignment.topCenter,
    childrenAlignment: Alignment.bottomCenter,
  ),

  /// Top-left corner with downward stacking.
  ///
  /// Toasts appear in the top-left area with new toasts stacking below existing ones.
  /// Suitable for notifications that shouldn't interfere with main content areas.
  topLeft(
    alignment: Alignment.topLeft,
    childrenAlignment: Alignment.bottomCenter,
  ),

  /// Top-right corner with downward stacking.
  ///
  /// Toasts appear in the top-right area with new toasts stacking below existing ones.
  /// Common choice for status updates and non-critical notifications.
  topRight(
    alignment: Alignment.topRight,
    childrenAlignment: Alignment.bottomCenter,
  );

  /// The alignment of the toast container within the screen.
  ///
  /// Type: `AlignmentGeometry`. Defines where the toast stack positions.
  /// Itself relative to the screen boundaries and safe area constraints.
  final AlignmentGeometry alignment;

  /// The alignment direction for stacking multiple toast notifications.
  ///
  /// Type: `AlignmentGeometry`. Defines the direction in which new toasts.
  /// Are added to the stack relative to existing toast notifications.
  final AlignmentGeometry childrenAlignment;

  /// Creates a [ToastLocation] with specified alignment properties.
  ///
  /// Parameters:
  /// - [alignment] (AlignmentGeometry, required): Screen positioning for the toast stack.
  /// - [childrenAlignment] (AlignmentGeometry, required): Stacking direction for multiple toasts.
  const ToastLocation({
    required this.alignment,
    required this.childrenAlignment,
  });
}

/// Expansion behavior modes for toast notification stacks.
///
/// ExpandMode controls when and how stacked toast notifications expand to.
/// Show multiple entries simultaneously. Different modes provide various.
/// User interaction patterns for managing multiple notifications.
enum ExpandMode {
  /// Toast stack is always expanded, showing all notifications simultaneously.
  ///
  /// All stacked toasts remain visible and fully sized at all times.
  /// Provides maximum information density but requires more screen space.
  alwaysExpanded,

  /// Toast stack expands when mouse cursor hovers over the notification area.
  ///
  /// Default behavior that provides on-demand access to stacked notifications.
  /// Through hover interaction. Collapses automatically after hover ends.
  expandOnHover,
}

/// A sophisticated layer widget that provides toast notification infrastructure.
///
/// ToastLayer serves as the foundation for the toast notification system,.
/// Managing the display, positioning, animation, and lifecycle of multiple.
/// Toast notifications. It wraps application content and provides the necessary.
/// Context for [showToast] functions to work properly.
///
/// The layer handles complex features including toast stacking, expansion modes,.
/// Hover/tap interactions, automatic dismissal timing, gesture-based dismissal,.
/// And smooth animations between states. It ensures proper theme integration.
/// And responsive behavior across different screen sizes.
///
/// Key features:
/// - Multi-location toast support with six standard positions.
/// - Intelligent toast stacking with configurable maximum entries.
/// - Interactive expansion modes (hover, tap, always, disabled)
/// - Gesture-based dismissal with swipe recognition.
/// - Automatic timeout handling with pause on hover.
/// - Smooth animations for entry, exit, and state transitions.
/// - Safe area and padding handling for various screen layouts.
/// - Theme integration with comprehensive customization options.
///
/// This is typically placed high in the widget tree, often wrapping the main.
/// Application content or individual screens that need toast functionality.
///
/// Example:
/// ```dart
/// toastLayer(
///   maxStackedEntries: 4,
///   expandMode: ExpandMode.expandOnHover,
///   child: MyAppContent(),.
/// );
/// ```
class ToastLayer extends StatefulWidget {
  /// Creates a [ToastLayer].
  ///
  /// The [child] parameter is required as the content to wrap with toast.
  /// Functionality. All other parameters have sensible defaults but can be.
  /// Customized to match specific design requirements.
  ///
  /// Parameters:
  /// - [child] (Widget, required): Content to wrap with toast capabilities.
  /// - [maxStackedEntries] (int, default: 3): Maximum visible toast count.
  /// - [padding] (EdgeInsetsGeometry?, optional): Toast area padding override.
  /// - [expandMode] (ExpandMode, default: expandOnHover): Stack expansion behavior.
  /// - [collapsedOffset] (Offset?, optional): Background toast positioning offset.
  /// - [collapsedScale] (double, default: 0.9): Background toast size reduction.
  /// - [expandingCurve] (Curve, default: easeOutCubic): Expansion animation curve.
  /// - [expandingDuration] (Duration, default: 500ms): Expansion animation timing.
  /// - [collapsedOpacity] (double, default: 1.0): Background toast visibility.
  /// - [entryOpacity] (double, default: 0.0): Toast entrance starting opacity.
  /// - [spacing] (double, default: 8.0): Gap between expanded toast entries.
  /// - [toastConstraints] (BoxConstraints?, optional): Individual toast size limits.
  ///
  /// Example:
  /// ```dart
  /// toastLayer(
  ///   maxStackedEntries: 5,
  ///   expandMode: ExpandMode.expandOnTap,
  ///   spacing: 12.0,
  ///   child: MaterialApp(home: HomePage()),.
  /// );
  /// ```
  const ToastLayer({
    required this.child,
    this.collapsedOffset,
    this.collapsedOpacity = 1,
    this.collapsedScale = _kDefaultCollapsedScale,
    this.entryOpacity = 0.0,
    this.expandMode = ExpandMode.expandOnHover,
    this.expandingCurve = Curves.easeOutCubic,
    this.expandingDuration = const Duration(milliseconds: CoreDuration.slow),
    super.key,
    this.maxStackedEntries = _kDefaultMaxStackedEntries,
    this.padding,
    this.spacing = CoreToastStyle.defaultStackSpacing,
    this.toastConstraints,
  });

  /// The child widget to wrap with toast functionality.
  ///
  /// Type: `Widget`, required. The main application content that will have.
  /// Toast notification capabilities available through the widget tree.
  final Widget child;

  /// Maximum number of toast notifications to display simultaneously.
  ///
  /// Type: `int`, default: [_kDefaultMaxStackedEntries]. Controls how many toasts are visible at once,.
  /// With older toasts being hidden or collapsed when limit is exceeded.
  final int maxStackedEntries;

  /// Padding around toast notification areas.
  ///
  /// Type: `EdgeInsetsGeometry?`. If null, uses
  /// `CoreToastStyle.defaultLayerPadding` (24 on every side), which the
  /// theme density moves; a stated padding is drawn as given. Applied
  /// inside the safe area, to toast positioning within screen boundaries.
  final EdgeInsetsGeometry? padding;

  /// Behavior for toast stack expansion interactions.
  ///
  /// Type: `ExpandMode`, default: [ExpandMode.expandOnHover]. Controls when.
  /// Stacked toasts expand to show multiple entries simultaneously.
  final ExpandMode expandMode;

  /// Position offset for collapsed toast entries.
  ///
  /// Type: `Offset?`. If null, uses default offset that creates subtle.
  /// Stacking effect. Applied to toasts behind the active notification.
  final Offset? collapsedOffset;

  /// Scale factor for collapsed toast entries.
  ///
  /// Type: `double`, default: `0.9`. Controls size reduction of background.
  /// Toasts to create depth perception in the stack visualization.
  final double collapsedScale;

  /// Animation curve for expansion state transitions.
  ///
  /// Type: `Curve`, default: [Curves.easeOutCubic]. Applied when transitioning.
  /// Between collapsed and expanded stack states.
  final Curve expandingCurve;

  /// Duration for expansion animation transitions.
  ///
  /// Type: `Duration`, default: `500ms`. Controls timing of stack expansion.
  /// And collapse animations for smooth user experience.
  final Duration expandingDuration;

  /// Opacity level for collapsed toast entries.
  ///
  /// Type: `double`, default: `1.0`. Controls visibility of background toasts.
  /// In the stack, with 1.0 being fully opaque and 0.0 being transparent.
  final double collapsedOpacity;

  /// Initial opacity for toast entry animations.
  ///
  /// Type: `double`, default: `0.0`. Starting opacity value for toast.
  /// Notifications during their entrance animation sequence.
  final double entryOpacity;

  /// Spacing between toast entries in expanded mode.
  ///
  /// Type: `double`, default: `CoreToastStyle.defaultStackSpacing` (8). Gap
  /// between individual toast notifications when the stack is expanded to
  /// show multiple entries. Spacing: the theme density moves it, a stated
  /// value too, the way it moves every gap.
  final double spacing;

  /// Size constraints for individual toast notifications.
  ///
  /// Type: `BoxConstraints?`. If null, uses responsive width based on screen.
  /// Size and theme scaling. Defines maximum and minimum toast dimensions.
  final BoxConstraints? toastConstraints;

  @override
  State<ToastLayer> createState() => _ToastLayerState();
}

class _ToastLocationData {
  var entries = <_AttachedToastEntry>[];
  bool _expanding = false;
  int _hoverCount = 0;
}

class _ToastLayerState extends State<ToastLayer> {
  final entries = {
    ToastLocation.topLeft: _ToastLocationData(),
    ToastLocation.topCenter: _ToastLocationData(),
    ToastLocation.topRight: _ToastLocationData(),
    ToastLocation.bottomLeft: _ToastLocationData(),
    ToastLocation.bottomCenter: _ToastLocationData(),
    ToastLocation.bottomRight: _ToastLocationData(),
  };

  void _triggerEntryClosing() {
    if (!mounted) {
      return;
    }
    setState(() {
      // this will rebuild the toast entries
    });
  }

  ToastOverlay addEntry(ToastEntry entry) {
    final attachedToastEntry = _AttachedToastEntry(this, entry);
    setState(() {
      final locationData = this.entries[entry.location]!;
      locationData.entries = [...locationData.entries, attachedToastEntry];
    });

    return attachedToastEntry;
  }

  void removeEntry(ToastEntry entry) {
    final last = entries[entry.location]!.entries
        .where((attached) => attached.entry == entry)
        .lastOrNull;
    if (last != null) {
      setState(() {
        final locationEntries = entries[entry.location]!;
        final updatedEntries = locationEntries.entries
            .where((attached) => attached != last)
            .toList();
        locationEntries.entries = updatedEntries;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final maxStackedEntries = widget.maxStackedEntries;
    final expandMode = widget.expandMode;
    final collapsedOffset =
        (widget.collapsedOffset ?? const Offset(0, _kDefaultCollapsedOffsetY)) *
        scaling;
    final layer = resolveToastLayer(
      context,
      spacing: widget.spacing,
      padding: widget.padding,
    );
    final padding = layer.padding;
    final toastConstraints =
        widget.toastConstraints ??
        BoxConstraints.tightFor(width: scaling * _kDefaultToastWidth);
    final collapsedScale = widget.collapsedScale;
    final expandingCurve = widget.expandingCurve;
    final expandingDuration = widget.expandingDuration;
    final collapsedOpacity = widget.collapsedOpacity;
    final entryOpacity = widget.entryOpacity;
    final spacing = layer.spacing;
    final reservedEntries = maxStackedEntries;
    final children = [widget.child];
    for (final locationEntry in entries.entries) {
      final location = locationEntry.key;
      final entries = locationEntry.value.entries;

      final expanding = locationEntry.value._expanding;
      final startVisible =
          (entries.length - (maxStackedEntries + reservedEntries)).max(0);

      final entryAlignment =
          location.childrenAlignment.optionallyResolve(context) * -1;
      // The location alignment is absolute; `Stacks` speaks logical
      // `CoreAlignment`, so resolve it here and pin the stack to ltr
      // below so the absolute x survives under an RTL ambient direction.
      final stackAlignment = location.alignment.optionallyResolve(context);
      final positionedChildren = <Widget>[];
      int toastIndex = 0;
      for (int i = entries.length - 1; i >= startVisible; i -= 1) {
        final entry = entries[i];
        positionedChildren.insert(
          0,
          ToastEntryLayout(
            key: entry.key,
            closing: entry._isClosing,
            collapsedOffset: collapsedOffset,
            collapsedOpacity: collapsedOpacity,
            collapsedScale: collapsedScale,
            curve: entry.entry.curve,
            data: entry.entry.data,
            dismissible: entry.entry.dismissible,
            duration: entry.entry.duration,
            entry: entry.entry,
            entryAlignment: entryAlignment,
            entryOffset: Offset(
              padding.left * entryAlignment.x.clamp(0, 1).toDouble() +
                  padding.right * entryAlignment.x.clamp(-1, 0).toDouble(),
              padding.top * entryAlignment.y.clamp(0, 1).toDouble() +
                  padding.bottom * entryAlignment.y.clamp(-1, 0).toDouble(),
            ),
            entryOpacity: entryOpacity,
            expanded: expanding || expandMode == .alwaysExpanded,
            expandingCurve: expandingCurve,
            expandingDuration: expandingDuration,
            index: toastIndex,
            onClosed: () {
              removeEntry(entry.entry);
              entry.entry.onClosed?.call();
            },
            onClosing: entry.close,
            previousAlignment: location.childrenAlignment,
            spacing: spacing,
            themes: entry.entry.themes,
            visible: toastIndex < maxStackedEntries,
            child: ConstrainedBox(
              constraints: toastConstraints,
              child: entry.entry.builder(context, entry),
            ),
          ),
        );
        if (!entry._isClosing.value) {
          toastIndex += 1;
        }
      }

      if (positionedChildren.isEmpty) {
        continue;
      }

      children.add(
        Position.fill(
          // On a viewport a fold splits, the stack keeps to the segment its
          // corner lies in; a stack centred on the fold opens on the side a
          // dialog does. A toast across a fold bends in the middle.
          child: FoldSegment(
            alignment: location.alignment,
            child: SafeArea(
              child: Padding(
                padding: padding,
                child: Align(
                  alignment: location.alignment,
                  child: MouseRegion(
                    onEnter: (event) {
                      locationEntry.value._hoverCount += 1;
                      if (expandMode == .expandOnHover) {
                        setState(() {
                          locationEntry.value._expanding = true;
                        });
                      }
                    },
                    onExit: (event) {
                      final currentCount = locationEntry.value._hoverCount += 1;
                      Future.delayed(_kHoverExitDelay, () {
                        if (currentCount == locationEntry.value._hoverCount) {
                          if (mounted) {
                            setState(() {
                              locationEntry.value._expanding = false;
                            });
                          } else {
                            locationEntry.value._expanding = false;
                          }
                        }
                      });
                    },
                    hitTestBehavior: .deferToChild,
                    child: ConstrainedBox(
                      constraints: toastConstraints,
                      child: Stacks(
                        alignment: CoreAlignment(
                          stackAlignment.x,
                          stackAlignment.y,
                        ),
                        fit: .passthrough,
                        clipBehavior: .none,
                        textDirection: .ltr,
                        children: positionedChildren,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Data.inherit(
      data: this,
      child: Stacks(
        fit: .passthrough,
        clipBehavior: .none,
        children: children,
      ),
    );
  }
}

/// Abstract interface for controlling individual toast notification instances.
///
/// ToastOverlay provides methods for managing the lifecycle and state of.
/// Individual toast notifications after they have been displayed. Instances.
/// Are returned by [showToast] and passed to [ToastBuilder] functions.
///
/// The interface allows checking the current display state and programmatically.
/// Dismissing toast notifications, enabling responsive user interactions and.
/// Proper cleanup when needed.
abstract class ToastOverlay {
  /// Whether the toast notification is currently being displayed.
  ///
  /// Type: `bool`. Returns true if the toast is visible or in the process.
  /// Of animating in/out, false if it has been dismissed or closed.
  bool get isShowing;

  /// Programmatically dismisses the toast notification.
  ///
  /// Triggers the dismissal animation and removes the toast from the display.
  /// Stack. This method can be called multiple times safely - subsequent.
  /// Calls after dismissal will have no effect.
  ///
  /// Example:
  /// ```dart
  /// final toast = showToast(context: context, builder: (context, overlay) {
  ///   return AlertCard(
  ///     title: 'Auto-close',
  ///     trailing: Button(
  ///       variant: .ghost,
  ///       onPressed: overlay.close,
  ///       child: Icon(LucideIcons.x),
  ///     ),
  ///   );
  /// });
  ///
  /// // Close programmatically after delay.
  /// Timer(Duration(seconds: 2), toast.close);
  /// ```
  void close();
}

class _AttachedToastEntry implements ToastOverlay {
  _AttachedToastEntry(this._attached, this.entry);

  final key = GlobalKey<_ToastEntryLayoutState>();

  final ToastEntry entry;

  // `_attached` references a Flutter-managed `_ToastLayerState` whose lifecycle
  // belongs to the widget tree; we only null the reference here and let
  // Flutter dispose the State.
  _ToastLayerState? _attached;

  final _isClosing = ValueNotifier(false);

  @override
  bool get isShowing => _attached != null;

  @override
  void close() {
    if (_attached == null) {
      return;
    }
    _isClosing.value = true;
    _attached!._triggerEntryClosing();
    _attached = null;
    _isClosing.dispose();
  }
}

class ToastEntry {
  const ToastEntry({
    required this.builder,
    this.curve = Curves.easeInOut,
    required this.data,
    this.dismissible = true,
    this.duration = kDefaultDuration,
    required this.location,
    this.onClosed,
    this.showDuration = _kDefaultShowDuration,
    required this.themes,
  });
  final ToastBuilder builder;
  final ToastLocation location;
  final bool dismissible;
  final Curve curve;
  final Duration duration;
  final CapturedThemes? themes;
  final CapturedData? data;
  final VoidCallback? onClosed;

  final Duration? showDuration;
}

class ToastEntryLayout extends StatefulWidget {
  const ToastEntryLayout({
    required this.child,
    required this.closing,
    required this.collapsedOffset,
    this.collapsedOpacity = _kDefaultCollapsedOpacity,
    required this.collapsedScale,
    this.curve = Curves.easeInOut,
    required this.data,
    this.dismissible = true,
    this.duration = kDefaultDuration,
    required this.entry,
    required this.entryAlignment,
    required this.entryOffset,
    this.entryOpacity = 0.0,
    required this.expanded,
    this.expandingCurve = Curves.easeInOut,
    this.expandingDuration = kDefaultDuration,
    required this.index,
    super.key,
    required this.onClosed,
    required this.onClosing,
    this.previousAlignment = Alignment.center,
    required this.spacing,
    required this.themes,
    this.visible = true,
  });

  final ToastEntry entry;
  final bool expanded;
  final bool visible;
  final bool dismissible;
  final AlignmentGeometry previousAlignment;
  final Curve curve;
  final Duration duration;
  final CapturedThemes? themes;
  final CapturedData? data;
  final ValueListenable<bool> closing;
  final VoidCallback onClosed;
  final Offset collapsedOffset;
  final double collapsedScale;
  final Curve expandingCurve;
  final Duration expandingDuration;
  final double collapsedOpacity;
  final double entryOpacity;
  final Widget child;
  final Offset entryOffset;
  final AlignmentGeometry entryAlignment;
  final double spacing;
  final int index;
  final VoidCallback? onClosing;

  @override
  State<ToastEntryLayout> createState() => _ToastEntryLayoutState();
}

class _ToastEntryLayoutState extends State<ToastEntryLayout> {
  bool _dismissing = false;
  double _dismissOffset = 0;
  double? _closeDismissing;
  Timer? _closingTimer;

  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _startClosingTimer();
  }

  @override
  void dispose() {
    _closingTimer?.cancel();
    super.dispose();
  }

  void _startClosingTimer() {
    if (widget.entry.showDuration != null) {
      _closingTimer?.cancel();
      _closingTimer = Timer(widget.entry.showDuration!, () {
        widget.onClosing?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget childWidget = MouseRegion(
      key: _key,
      onEnter: (event) {
        _closingTimer?.cancel();
      },
      onExit: (event) {
        _startClosingTimer();
      },
      hitTestBehavior: .deferToChild,
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          if (widget.dismissible) {
            setState(() {
              _closingTimer?.cancel();
              _dismissing = true;
            });
          }
        },
        onHorizontalDragUpdate: (details) {
          if (widget.dismissible) {
            setState(() {
              _dismissOffset += details.primaryDelta! / context.size!.width;
            });
          }
        },
        onHorizontalDragEnd: (details) {
          if (widget.dismissible) {
            setState(() {
              _dismissing = false;
            });
            // if its < -threshold or > threshold dismiss it
            if (_dismissOffset < -_kDismissThreshold) {
              _closeDismissing = -1.0;
            } else if (_dismissOffset > _kDismissThreshold) {
              _closeDismissing = 1.0;
            } else {
              _dismissOffset = 0;
              _startClosingTimer();
            }
          }
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.closing,
          builder: (context, isClosing, child) {
            return AnimatedValueBuilder(
              key: const ValueKey('toast-dismiss-animation'),
              initialValue: 0.0,
              value: isClosing ? 0.0 : _dismissOffset,
              duration: _dismissing && !isClosing ? .zero : kDefaultDuration,
              builder: (context, dismissProgress, child) {
                return AnimatedValueBuilder(
                  key: const ValueKey('toast-close-dismissing-animation'),
                  initialValue: 0.0,
                  value: isClosing ? 0.0 : (_closeDismissing ?? 0.0),
                  duration: kDefaultDuration,
                  onEnd: (value) {
                    if (value == -1.0 || value == 1.0) {
                      widget.onClosed();
                    }
                  },
                  builder: (context, closeDismissingProgress, child) {
                    return AnimatedValueBuilder(
                      key: const ValueKey('toast-index-animation'),
                      initialValue: widget.index.toDouble(),
                      value: widget.index.toDouble(),
                      duration: widget.duration,
                      curve: widget.curve,
                      builder: (context, indexProgress, child) {
                        return AnimatedValueBuilder(
                          key: const ValueKey('toast-showing-animation'),
                          initialValue: 0.0,
                          value: isClosing && !_dismissing ? 0.0 : 1.0,
                          duration: widget.duration,
                          onEnd: (value) {
                            if (value == 0.0 && isClosing) {
                              widget.onClosed();
                            }
                          },
                          curve: widget.curve,
                          builder: (context, showingProgress, child) {
                            return AnimatedValueBuilder(
                              key: const ValueKey('toast-visible-animation'),
                              initialValue: 0.0,
                              value: widget.visible ? 1.0 : 0.0,
                              duration: widget.duration,
                              curve: widget.curve,
                              builder: (context, visibleProgress, child) {
                                return AnimatedValueBuilder(
                                  key: const ValueKey('toast-expand-animation'),
                                  initialValue: 0.0,
                                  value: widget.expanded ? 1.0 : 0.0,
                                  duration: widget.expandingDuration,
                                  curve: widget.expandingCurve,
                                  builder: (context, expandProgress, child) {
                                    return buildToast(
                                      closeDismissingProgress,
                                      dismissProgress,
                                      expandProgress,
                                      indexProgress,
                                      showingProgress,
                                      visibleProgress,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
    if (widget.themes != null) {
      childWidget = widget.themes!.wrap(childWidget);
    }
    if (widget.data != null) {
      childWidget = widget.data!.wrap(childWidget);
    }

    return childWidget;
  }

  Widget buildToast(
    double closeDismissingProgress,
    double dismissProgress,
    double expandProgress,
    double indexProgress,
    double showingProgress,
    double visibleProgress,
  ) {
    final nonCollapsingProgress = (1.0 - expandProgress) * showingProgress;
    Offset offset = widget.entryOffset * (1.0 - showingProgress);

    // when its behind another toast, shift it up based on index
    final previousAlignment = widget.previousAlignment.optionallyResolve(
      context,
    );
    offset +=
        Offset(
          (widget.collapsedOffset.dx * previousAlignment.x) *
              nonCollapsingProgress,
          (widget.collapsedOffset.dy * previousAlignment.y) *
              nonCollapsingProgress,
        ) *
        indexProgress;

    final theme = Theme.of(context);

    final expandingShift = Offset(
      previousAlignment.x *
          (theme.scaling * _kExpandingShiftMultiplier) *
          expandProgress,
      previousAlignment.y *
          (theme.scaling * _kExpandingShiftMultiplier) *
          expandProgress,
    );

    offset += expandingShift;

    // and then add the spacing when its in expanded mode
    offset +=
        Offset(
          (widget.spacing * previousAlignment.x) * expandProgress,
          (widget.spacing * previousAlignment.y) * expandProgress,
        ) *
        indexProgress;

    final entryAlignment = widget.entryAlignment.optionallyResolve(context);
    Offset fractionalOffset = Offset(
      entryAlignment.x * (1.0 - showingProgress),
      entryAlignment.y * (1.0 - showingProgress),
    );

    fractionalOffset += Offset(closeDismissingProgress + dismissProgress, 0);

    // when its behind another toast AND is expanded, shift it up based on index and the size of self
    fractionalOffset +=
        Offset(
          expandProgress * previousAlignment.x,
          expandProgress * previousAlignment.y,
        ) *
        indexProgress;

    num opacity = tweenValue(
      widget.entryOpacity,
      1,
      showingProgress * visibleProgress,
    );

    // fade out the toast behind
    opacity *= pow(
      widget.collapsedOpacity,
      indexProgress * nonCollapsingProgress,
    );

    opacity *= 1 - (closeDismissingProgress + dismissProgress).abs();

    final scale =
        pow(widget.collapsedScale, indexProgress * (1 - expandProgress)) * 1.0;

    return Align(
      alignment: entryAlignment,
      child: Transform.translate(
        offset: offset,
        child: FractionalTranslation(
          translation: fractionalOffset,
          child: Opacity(
            opacity: opacity.clamp(0, 1).toDouble(),
            child: Transform.scale(scale: scale, child: widget.child),
          ),
        ),
      ),
    );
  }
}
