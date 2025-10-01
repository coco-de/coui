import 'package:coui_flutter/coui_flutter.dart';

/// Callback function type for building SubFocusScope widgets.
///
/// Receives the build context and the scope state for managing focus
/// within the scope's widget tree.
typedef SubFocusScopeBuilder =
    Widget Function(
      BuildContext context,
      SubFocusScopeState state,
    );

/// Hierarchical focus management system for complex widget trees.
///
/// Creates a focus scope that manages keyboard navigation and focus traversal
/// for child widgets. Provides centralized control over which child widget
/// has focus and handles focus navigation between multiple focusable elements.
///
/// Key Features:
/// - **Focus Hierarchy**: Manages focus relationships between parent and child widgets
/// - **Keyboard Navigation**: Handles arrow key and tab navigation between elements
/// - **Action Delegation**: Routes keyboard actions to currently focused child
/// - **Auto-focus Support**: Automatically focuses first child when enabled
/// - **Focus State Management**: Tracks and updates focus state across widget rebuilds
/// - **Scroll Integration**: Ensures focused elements remain visible in scrollable areas
///
/// The scope maintains a list of attached [SubFocus] widgets and manages which
/// one currently has focus. It handles focus traversal, action routing, and
/// ensures focused widgets remain visible through scroll positioning.
///
/// Used commonly in:
/// - Lists with keyboard navigation
/// - Form field traversal
/// - Menu and dropdown navigation
/// - Tree view navigation
/// - Tab panel systems
///
/// Example:
/// ```dart
/// SubFocusScope(
///   autofocus: true,
///   builder: (context, state) => Column(
///     children: [
///       SubFocus(
///         builder: (context, focusState) => Container(
///           color: focusState.isFocused ? Colors.blue : Colors.grey,
///           child: Text('Item 1'),
///         ),
///       ),
///       SubFocus(
///         builder: (context, focusState) => Container(
///           color: focusState.isFocused ? Colors.blue : Colors.grey,
///           child: Text('Item 2'),
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
class SubFocusScope extends StatefulWidget {
  const SubFocusScope({this.autofocus = false, this.builder, super.key});

  final SubFocusScopeBuilder? builder;
  final bool autofocus;

  @override
  State<SubFocusScope> createState() => _SubFocusScopeState();
}

mixin SubFocusScopeState {
  Object? invokeActionOnFocused(Intent intent);

  bool nextFocus([TraversalDirection direction = TraversalDirection.down]);

  void detach(SubFocusState child);

  bool attach(SubFocusState child);

  bool requestFocus(SubFocusState child);

  bool unfocus(SubFocusState child);
}

class _SubFocusScopeState extends State<SubFocusScope> with SubFocusScopeState {
  final _attachedStates = <SubFocusState>[];
  SubFocusState? _currentState;
  bool _active = true;

  void _setCurrentItem(bool? forward, SubFocusState item) {
    if (!mounted || !_active) {
      return;
    }
    final currentItem = _currentState;
    if (!mounted || !_active) {
      return;
    }
    currentItem?.markFocused(false);
    item.markFocused(true);
    item.ensureVisible(
      alignmentPolicy: forward == null
          ? ScrollPositionAlignmentPolicy.explicit
          : forward
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
    _currentState = item;
  }

  @override
  bool unfocus(SubFocusState child) {
    if (_currentState == child) {
      _currentState?.markFocused(false);
      _currentState = null;

      return true;
    }

    return false;
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  Object? invokeActionOnFocused(Intent intent) {
    return _currentState?.invokeAction(intent);
  }

  @override
  bool attach(SubFocusState state) {
    assert(
      !_attachedStates.contains(state),
      'SubFocusState is already attached to this SubFocusScope.',
    );
    _attachedStates.add(state);
    if (widget.autofocus) {
      _currentState ??= state;
    }

    return _currentState == state;
  }

  @override
  void detach(SubFocusState state) {
    _attachedStates.remove(state);
    if (_currentState == state) {
      _currentState = null;
      if (widget.autofocus) findFirstFocus(); // Find new focus
    }
  }

  @override
  bool nextFocus([TraversalDirection direction = TraversalDirection.down]) {
    if (!mounted || !_active) return false;
    if (_currentState != null) {
      final currentBox = _currentState!.findRenderObject();
      final parentBox = findRenderObject();
      if (currentBox == null || parentBox == null) {
        return false;
      }
      final currentOffset = currentBox.localToGlobal(
        Offset.zero,
        ancestor: parentBox,
      );

      final bool horizontal;
      final bool forward;
      switch (direction) {
        case TraversalDirection.down:
          horizontal = false;
          forward = true;

        case TraversalDirection.up:
          horizontal = false;
          forward = false;

        case TraversalDirection.right:
          horizontal = true;
          forward = true;

        case TraversalDirection.left:
          horizontal = true;
          forward = false;
      }

      (SubFocusState, double)? nearestNextItem;
      for (final attached in _attachedStates) {
        if (attached == _currentState) continue;
        final box = attached.findRenderObject();
        if (box == null) continue;
        final offset = box.localToGlobal(Offset.zero, ancestor: parentBox);
        final delta = horizontal
            ? (forward
                  ? (offset.dx - currentOffset.dx)
                  : (currentOffset.dx - offset.dx))
            : (forward
                  ? (offset.dy - currentOffset.dy)
                  : (currentOffset.dy - offset.dy));
        if (delta <= 0) continue;
        if (nearestNextItem == null || delta < nearestNextItem.$2) {
          nearestNextItem = (attached, delta);
        }
      }
      if (nearestNextItem != null) {
        _setCurrentItem(nearestNextItem.$1, forward);

        return true;
      }
    } else if (!widget.autofocus) {
      findFirstFocus();

      return true;
    }

    return false;
  }

  @override
  bool requestFocus(SubFocusState child) {
    if (!mounted || !_active) return false;
    _currentState?.markFocused(false);
    _currentState = child;
    _currentState!.markFocused(true);

    return true;
  }

  RenderBox? findRenderObject() {
    return !mounted || !_active
        ? null
        : context.findRenderObject() as RenderBox?;
  }

  void findFirstFocus() {
    if (!mounted || !_active) return;
    (SubFocusState, int)? mostItem;
    for (final attached in _attachedStates) {
      if (attached.focusCount > 0 &&
          attached.focusCount > (mostItem?.$2 ?? 0)) {
        mostItem = (attached, attached.focusCount);
      }
    }
    if (mostItem == null) {
      /// Find very first focus based on top left or top right (based on directionality).
      (SubFocusState, double)? nearestItem;
      final direction = Directionality.of(context);
      final parentBox = findRenderObject();
      if (parentBox == null) return;
      final anchor = direction == TextDirection.ltr
          ? Offset.zero
          : Offset(parentBox.size.width, 0);
      for (final attached in _attachedStates) {
        if (attached == mostItem?.$1) continue;
        final box = attached.findRenderObject();
        if (box == null) continue;
        final offset = box.localToGlobal(Offset.zero);
        final distance = (offset - anchor).distance;
        if (nearestItem == null || distance < nearestItem.$2) {
          nearestItem = (attached, distance);
        }
      }
      if (nearestItem != null) {
        _setCurrentItem(nearestItem.$1, null);
      }
    } else {
      _setCurrentItem(mostItem.$1, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Data<SubFocusScopeState>.inherit(
      data: this,
      child: widget.builder?.call(context, this),
    );
  }
}

/// Callback function type for building SubFocus widgets.
///
/// Receives the build context and focus state for creating widgets that
/// respond to focus changes and user interactions.
typedef SubFocusBuilder =
    Widget Function(
      BuildContext context,
      SubFocusState state,
    );

/// Individual focusable widget within a SubFocusScope hierarchy.
///
/// Creates a single focusable element that can receive keyboard focus and respond
/// to user interactions within a [SubFocusScope]. Provides focus state information
/// and handles focus-related behaviors like visibility scrolling and action routing.
///
/// Key Features:
/// - **Focus State**: Tracks and reports whether this widget currently has focus
/// - **Focus Request**: Can programmatically request focus from its parent scope
/// - **Action Handling**: Receives and processes keyboard actions when focused
/// - **Scroll Integration**: Automatically scrolls to ensure visibility when focused
/// - **State Tracking**: Maintains focus count and state across widget lifecycle
/// - **Enable/Disable**: Can be temporarily disabled to prevent focus acquisition
///
/// The widget uses a builder pattern to provide focus state to child widgets,
/// allowing them to update their appearance and behavior based on focus status.
/// This enables rich visual feedback for focused states.
///
/// Common Use Cases:
/// - List items in navigable lists
/// - Form fields in keyboard-navigable forms
/// - Menu items in dropdown menus
/// - Tree nodes in tree views
/// - Tab headers in tab panels
///
/// Example:
/// ```dart
/// SubFocus(
///   enabled: true,
///   builder: (context, state) => GestureDetector(
///     onTap: () => state.requestFocus(),
///     child: Container(
///       padding: EdgeInsets.all(8),
///       decoration: BoxDecoration(
///         color: state.isFocused ? Colors.blue : Colors.transparent,
///         border: Border.all(
///           color: state.isFocused ? Colors.blue : Colors.grey,
///         ),
///       ),
///       child: Text(
///         'Focusable Item',
///         style: TextStyle(
///           color: state.isFocused ? Colors.white : Colors.black,
///         ),
///       ),
///     ),
///   ),
/// )
/// ```
class SubFocus extends StatefulWidget {
  const SubFocus({required this.builder, this.enabled = true, super.key});

  final SubFocusBuilder builder;
  final bool enabled;

  @override
  State<SubFocus> createState() => _SubFocusState();
}

mixin SubFocusState {
  RenderBox? findRenderObject();

  void ensureVisible({
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
  });
  bool get isFocused;

  bool requestFocus();

  Object? invokeAction(Intent intent);
  int get focusCount;

  void markFocused(bool focused);

  bool unfocus();
}

class _SubFocusState extends State<SubFocus> with SubFocusState {
  SubFocusScopeState? _scope;
  bool _focused = false;
  bool _active = true;
  int _focusCount = 0;

  @override
  int get focusCount => _focusCount;

  @override
  bool unfocus() {
    return _scope?.unfocus(this) ?? false;
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant SubFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _focused = _scope?.attach(this) ?? false;
      } else {
        _focused = false;
        _scope?.detach(this);
      }
    }
  }

  @override
  Object? invokeAction(Intent intent) {
    return Actions.invoke(context, intent);
  }

  @override
  void ensureVisible({
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
  }) {
    if (!mounted || !_active) return;
    Scrollable.ensureVisible(context, alignmentPolicy: alignmentPolicy);
  }

  @override
  bool requestFocus() {
    if (!mounted || !_active) return false;

    return (_scope != null) && (_scope!.requestFocus(this));
  }

  @override
  bool get isFocused => _focused && widget.enabled;

  @override
  RenderBox? findRenderObject() {
    return !mounted || !_active
        ? null
        : context.findRenderObject() as RenderBox?;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newScope = Data.maybeOf<SubFocusScopeState>(context);
    if (newScope != _scope) {
      _focusCount = 0;
      _scope?.detach(this);
      _scope = newScope;
      if (widget.enabled) {
        _focused = _scope?.attach(this) ?? false;
      }
    }
  }

  @override
  void dispose() {
    _scope?.detach(this);
    super.dispose();
  }

  @override
  void markFocused(bool focus) {
    if (!mounted || !_active) {
      return;
    }
    setState(() {
      if (focus) {
        _focusCount += 1;
      }
      _focused = focus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, this);
  }
}
