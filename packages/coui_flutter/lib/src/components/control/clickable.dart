import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

extension WidgetStateExtension on Set<WidgetState> {
  bool get disabled => contains(WidgetState.disabled);
  bool get hovered => contains(WidgetState.hovered);
  bool get focused => contains(WidgetState.focused);
}

/// An abstract widget that provides state-aware visual variations.
///
/// Enables widgets to display different appearances based on their current
/// interactive state (disabled, selected, pressed, hovered, focused, error).
/// The widget automatically selects the appropriate visual representation
/// from provided alternatives based on a configurable state priority order.
///
/// Three factory constructors provide different approaches to state handling:
/// - Default constructor: Explicit widgets for each state
/// - `.map()`: Map-based state-to-widget associations
/// - `.builder()`: Function-based dynamic state handling
///
/// The state resolution follows a priority order where earlier states in the
/// order take precedence over later ones. This ensures consistent behavior
/// when multiple states are active simultaneously.
///
/// Example:
/// ```dart
/// StatedWidget(
///   child: Text('Default'),
///   disabled: Text('Disabled State'),
///   hovered: Text('Hovered State'),
///   pressed: Text('Pressed State'),
///   selected: Text('Selected State'),
/// )
/// ```
abstract class StatedWidget extends StatelessWidget {
  /// Creates a [StatedWidget] with explicit state-specific widgets.
  ///
  /// Provides dedicated widget instances for each supported state.
  /// The [child] serves as the default widget when no specific state
  /// matches or when no state-specific widget is provided.
  ///
  /// State resolution follows the [order] priority, with earlier states
  /// taking precedence. The first matching state with a non-null widget
  /// is selected for display.
  ///
  /// Parameters:
  /// - [child] (Widget, required): Default widget for normal state
  /// - [order] (List<WidgetState>, default: defaultStateOrder): State priority order
  /// - [disabled] (Widget?, optional): Widget for disabled state
  /// - [selected] (Widget?, optional): Widget for selected state
  /// - [pressed] (Widget?, optional): Widget for pressed/active state
  /// - [hovered] (Widget?, optional): Widget for hover state
  /// - [focused] (Widget?, optional): Widget for focused state
  /// - [error] (Widget?, optional): Widget for error state
  ///
  /// Example:
  /// ```dart
  /// StatedWidget(
  ///   child: Icon(Icons.star_border),
  ///   selected: Icon(Icons.star, color: Colors.yellow),
  ///   hovered: Icon(Icons.star_border, color: Colors.grey),
  ///   disabled: Icon(Icons.star_border, color: Colors.grey.shade300),
  /// )
  /// ```
  const factory StatedWidget({
    required Widget child,
    Widget? disabled,
    Widget? error,
    Widget? focused,
    Widget? hovered,
    Key? key,
    List<WidgetState> order,
    Widget? pressed,
    Widget? selected,
  }) = _ParamStatedWidget;

  const StatedWidget._({super.key});

  /// Creates a [StatedWidget] using a map-based state configuration.
  ///
  /// Provides a flexible approach where states are defined using a map
  /// with keys representing state identifiers and values being the
  /// corresponding widgets. This approach is useful when states are
  /// determined dynamically or when working with custom state types.
  ///
  /// The [child] parameter serves as a fallback when no matching state
  /// is found in the states map. State resolution prioritizes exact
  /// matches in the provided map.
  ///
  /// Parameters:
  /// - [states] (Map<Object, Widget>, required): Map of state-to-widget mappings
  /// - [child] (Widget?, optional): Fallback widget when no state matches
  ///
  /// Example:
  /// ```dart
  /// StatedWidget.map(
  ///   states: {
  ///     WidgetState.selected: Icon(Icons.check_circle, color: Colors.green),
  ///     WidgetState.error: Icon(Icons.error, color: Colors.red),
  ///     'custom': Icon(Icons.star, color: Colors.blue),
  ///   },
  ///   child: Icon(Icons.circle_outlined),
  /// )
  /// ```
  const factory StatedWidget.map({
    Widget? child,
    Key? key,
    required Map<Object, Widget> states,
  }) = _MapStatedWidget;

  /// Creates a [StatedWidget] using a builder function for dynamic state handling.
  ///
  /// Provides maximum flexibility by using a builder function that receives
  /// the current set of active widget states and returns the appropriate
  /// widget. This approach allows for complex state logic, animations,
  /// and dynamic visual computations based on state combinations.
  ///
  /// The builder function is called whenever the widget states change,
  /// allowing for real-time adaptation to state transitions. This is
  /// ideal for complex UI that needs to respond to multiple simultaneous states.
  ///
  /// Parameters:
  /// - [builder] (Function, required): Builder function receiving context and states
  ///
  /// Example:
  /// ```dart
  /// StatedWidget.builder(
  ///   builder: (context, states) {
  ///     if (states.contains(WidgetState.disabled)) {
  ///       return Opacity(opacity: 0.5, child: Icon(Icons.block));
  ///     }
  ///     if (states.contains(WidgetState.selected)) {
  ///       return Icon(Icons.check_circle, color: Colors.green);
  ///     }
  ///     if (states.contains(WidgetState.hovered)) {
  ///       return AnimatedScale(scale: 1.1, child: Icon(Icons.star));
  ///     }
  ///     return Icon(Icons.star_border);
  ///   },
  /// )
  /// ```
  const factory StatedWidget.builder({
    required Widget Function(BuildContext context, Set<WidgetState> states)
    builder,
    Key? key,
  }) = _BuilderStatedWidget;

  /// Default state priority order for resolving multiple active states.
  ///
  /// Defines the precedence when multiple widget states are active simultaneously.
  /// States earlier in the list take priority over later ones. The default order
  /// prioritizes accessibility and interaction feedback appropriately.
  static const defaultStateOrder = [
    WidgetState.disabled,
    WidgetState.error,
    WidgetState.selected,
    WidgetState.pressed,
    WidgetState.hovered,
    WidgetState.focused,
  ];
}

class _ParamStatedWidget extends StatedWidget {
  const _ParamStatedWidget({
    this.child,
    this.disabled,
    this.error,
    this.focused,
    this.hovered,
    super.key,
    this.order = StatedWidget.defaultStateOrder,
    this.pressed,
    this.selected,
  }) : super._();

  final List<WidgetState> order;
  final Widget? child;
  final Widget? disabled;
  final Widget? selected;
  final Widget? pressed;
  final Widget? hovered;
  final Widget? focused;

  final Widget? error;

  Widget? _checkByOrder(Set<WidgetState> states, int index) {
    if (index >= order.length) {
      return child;
    }
    final state = order[index];
    if (states.contains(state)) {
      switch (state) {
        case WidgetState.disabled:
          return disabled;

        case WidgetState.pressed:
          return pressed;

        case WidgetState.hovered:
          return hovered;

        case WidgetState.focused:
          return focused;

        case WidgetState.selected:
          return selected;

        case WidgetState.error:
          return error;

        default:
          return child;
      }
    }

    return _checkByOrder(states, index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final statesData = Data.maybeOf<WidgetStatesData>(context);
    final states = statesData?.states ?? {};
    final child = _checkByOrder(states, 0);

    return child ?? const SizedBox();
  }
}

class WidgetStatesProvider extends StatelessWidget {
  const WidgetStatesProvider({
    required this.child,
    this.controller,
    this.inherit = true,
    super.key,
    this.states = const {},
  }) : boundary = false;

  const WidgetStatesProvider.boundary({required this.child, super.key})
    : boundary = true,
      controller = null,
      states = null,
      inherit = false;

  final WidgetStatesController? controller;
  final Set<WidgetState>? states;
  final Widget child;

  final bool inherit;

  final bool boundary;

  @override
  Widget build(BuildContext context) {
    if (boundary) {
      return Data<WidgetStatesData>.boundary(child: child);
    }
    Set<WidgetState>? parentStates;
    if (inherit) {
      final parentData = Data.maybeOf<WidgetStatesData>(context);
      parentStates = parentData?.states;
    }

    return ListenableBuilder(
      builder: (context, child) {
        Set<WidgetState> currentStates = states ?? {};
        if (controller != null) {
          currentStates = currentStates.union(controller!.value);
        }
        if (parentStates != null) {
          currentStates = currentStates.union(parentStates);
        }

        return Data<WidgetStatesData>.inherit(
          data: WidgetStatesData(currentStates),
          child: child,
        );
      },
      listenable: Listenable.merge([if (controller != null) controller!]),
      child: child,
    );
  }
}

class WidgetStatesData {
  const WidgetStatesData(this.states);

  final Set<WidgetState> states;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WidgetStatesData && setEquals(states, other.states);
  }

  @override
  String toString() => 'WidgetStatesData(states: $states)';

  @override
  int get hashCode => states.hashCode;
}

class _MapStatedWidget extends StatedWidget {
  const _MapStatedWidget({this.child, super.key, required this.states})
    : super._();

  static final _mappedNames = WidgetState.values.asNameMap();
  final Map<Object, Widget> states;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final statesData = Data.maybeOf<WidgetStatesData>(context);
    final widgetStates = statesData?.states ?? {};
    for (final entry in states.entries) {
      final keys = entry.key;
      if (keys is Iterable<WidgetState>) {
        if (widgetStates.containsAll(keys)) {
          return entry.value;
        }
      } else if (keys is WidgetState) {
        if (widgetStates.contains(keys)) {
          return entry.value;
        }
      } else if (keys is String) {
        final state = _mappedNames[keys];
        if (state != null && widgetStates.contains(state)) {
          return entry.value;
        }
      } else {
        assert(
          false,
          'Invalid key type in states map (${keys.runtimeType}) expected WidgetState, Iterable<WidgetState>, or String',
        );
      }
    }

    return child ?? const SizedBox();
  }
}

class _BuilderStatedWidget extends StatedWidget {
  const _BuilderStatedWidget({required this.builder, super.key}) : super._();

  final Widget Function(BuildContext context, Set<WidgetState> states) builder;

  @override
  Widget build(BuildContext context) {
    final statesData = Data.maybeOf(context);
    final states = statesData?.states ?? {};

    return builder(context, states);
  }
}

class Clickable extends StatefulWidget {
  const Clickable({
    this.actions,
    this.behavior = HitTestBehavior.translucent,
    required this.child,
    this.decoration,
    this.disableFocusOutline = false,
    this.disableHoverEffect = false,
    this.disableTransition = false,
    this.enableFeedback = true,
    this.enabled = true,
    this.focusNode,
    this.focusOutline = true,
    this.iconTheme,
    super.key,
    this.margin,
    this.marginAlignment,
    this.mouseCursor,
    this.onDoubleTap,
    this.onFocus,
    this.onHover,
    this.onLongPress,
    this.onLongPressEnd,
    this.onLongPressMoveUpdate,
    this.onLongPressStart,
    this.onLongPressUp,
    this.onPressed,
    this.onSecondaryLongPress,
    this.onSecondaryTapCancel,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onTapCancel,
    this.onTapDown,
    this.onTapUp,
    this.onTertiaryLongPress,
    this.onTertiaryTapCancel,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.padding,
    this.shortcuts,
    this.statesController,
    this.textStyle,
    this.transform,
  });

  final Widget child;
  final bool enabled;
  final ValueChanged<bool>? onHover;
  final ValueChanged<bool>? onFocus;
  final WidgetStateProperty<Decoration?>? decoration;
  final WidgetStateProperty<MouseCursor?>? mouseCursor;
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;
  final WidgetStateProperty<TextStyle?>? textStyle;
  final WidgetStateProperty<IconThemeData?>? iconTheme;
  final WidgetStateProperty<EdgeInsetsGeometry?>? margin;
  final WidgetStateProperty<Matrix4?>? transform;
  final VoidCallback? onPressed;
  final VoidCallback? onDoubleTap;
  final FocusNode? focusNode;
  final HitTestBehavior behavior;
  final bool disableTransition;
  final Map<LogicalKeySet, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final bool focusOutline;
  final bool enableFeedback;
  final VoidCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureTapDownCallback? onSecondaryTapDown;
  final GestureTapUpCallback? onSecondaryTapUp;
  final GestureTapCancelCallback? onSecondaryTapCancel;
  final GestureTapDownCallback? onTertiaryTapDown;
  final GestureTapUpCallback? onTertiaryTapUp;
  final GestureTapCancelCallback? onTertiaryTapCancel;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressUpCallback? onLongPressUp;
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;
  final GestureLongPressEndCallback? onLongPressEnd;
  final GestureLongPressUpCallback? onSecondaryLongPress;
  final GestureLongPressUpCallback? onTertiaryLongPress;
  final bool disableHoverEffect;
  final WidgetStatesController? statesController;
  final AlignmentGeometry? marginAlignment;

  final bool disableFocusOutline;

  @override
  State<Clickable> createState() => _ClickableState();
}

const kDoubleTapMinTime = Duration(milliseconds: 300);

class _ClickableState extends State<Clickable> {
  late FocusNode _focusNode;
  late WidgetStatesController _controller;
  DateTime? _lastTap;
  int _tapCount = 0;

  static Future<void> feedbackForTap(BuildContext context) {
    final currentPlatform = Theme.of(context).platform;
    context.findRenderObject()!.sendSemanticsEvent(const TapSemanticEvent());

    return isMobile(currentPlatform)
        ? SystemSound.play(SystemSoundType.click)
        : Future.value();
  }

  static Matrix4? lerpMatrix4(Matrix4? a, Matrix4? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    final tween = Matrix4Tween(
      begin: a ?? Matrix4.identity(),
      end: b ?? Matrix4.identity(),
    );

    return tween.transform(t);
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.statesController ?? WidgetStatesController();
    _controller.update(WidgetState.disabled, !widget.enabled);
  }

  void _onPressed() {
    if (!widget.enabled) return;
    final deltaTap = _lastTap == null
        ? null
        : DateTime.now().difference(_lastTap!);
    _lastTap = DateTime.now();
    if (deltaTap != null && deltaTap < kDoubleTapMinTime) {
      _tapCount += 1;
    } else {
      _tapCount = 1;
    }

    if (_tapCount == 2 && widget.onDoubleTap != null) {
      widget.onDoubleTap!();
      _tapCount = 0;
    } else {
      if (widget.onPressed != null) {
        widget.onPressed!();
        if (widget.enableFeedback) {
          feedbackForTap(context);
        }
      }
    }
  }

  Widget _builder(BuildContext context, Widget? _) {
    final theme = Theme.of(context);
    final enabled = widget.enabled;
    Set<WidgetState> widgetStates =
        Data.maybeOf<WidgetStatesData>(context)?.states ?? {};
    widgetStates = widgetStates.union(_controller.value);
    final decoration = widget.decoration?.resolve(widgetStates);
    BorderRadiusGeometry borderRadius;
    borderRadius = decoration is BoxDecoration
        ? decoration.borderRadius ?? theme.borderRadiusMd
        : theme.borderRadiusMd;
    final buttonContainer = _buildContainer(context, decoration, widgetStates);

    return FocusOutline(
      borderRadius: borderRadius,
      focused:
          widget.focusOutline &&
          widgetStates.contains(WidgetState.focused) &&
          !widget.disableFocusOutline,
      child: GestureDetector(
        behavior: widget.behavior,
        onLongPress: widget.onLongPress,
        onLongPressEnd: widget.onLongPressEnd,
        onLongPressMoveUpdate: widget.onLongPressMoveUpdate,
        onLongPressStart: widget.onLongPressStart,
        onLongPressUp: widget.onLongPressUp,
        onSecondaryLongPress: widget.onSecondaryLongPress,
        onSecondaryTapCancel: widget.onSecondaryTapCancel,
        // onDoubleTap: widget.onDoubleTap, HANDLED CUSTOMLY
        onSecondaryTapDown: widget.onSecondaryTapDown,
        onSecondaryTapUp: widget.onSecondaryTapUp,
        onTap: widget.onPressed == null ? null : _onPressed,
        onTapCancel: widget.onPressed == null
            ? widget.onTapCancel
            : () {
                if (widget.enableFeedback) {
                  /// Also dispatch hover.
                  _controller.update(WidgetState.hovered, false);
                }
                _controller.update(WidgetState.pressed, false);
                widget.onTapCancel?.call();
              },
        onTapDown: widget.onPressed == null
            ? widget.onTapDown
            : (details) {
                if (widget.enableFeedback) {
                  /// Also dispatch hover.
                  _controller.update(WidgetState.hovered, true);
                }
                _controller.update(WidgetState.pressed, true);
                widget.onTapDown?.call(details);
              },
        onTapUp: widget.onPressed == null
            ? widget.onTapUp
            : (details) {
                if (widget.enableFeedback) {
                  // also dispatch hover
                  _controller.update(WidgetState.hovered, false);
                }
                _controller.update(WidgetState.pressed, false);
                widget.onTapUp?.call(details);
              },
        onTertiaryLongPress: widget.onTertiaryLongPress,
        onTertiaryTapCancel: widget.onTertiaryTapCancel,
        onTertiaryTapDown: widget.onTertiaryTapDown,
        onTertiaryTapUp: widget.onTertiaryTapUp,
        child: FocusableActionDetector(
          actions: {
            ActivateIntent: CallbackAction(
              onInvoke: (e) {
                _onPressed();

                return null;
              },
            ),
            DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
              onInvoke: (e) {
                final direction = e.direction;
                final focus = _focusNode;
                switch (direction) {
                  case TraversalDirection.up:
                    focus.focusInDirection(TraversalDirection.up);

                  case TraversalDirection.down:
                    focus.focusInDirection(TraversalDirection.down);

                  case TraversalDirection.left:
                    focus.focusInDirection(TraversalDirection.left);

                  case TraversalDirection.right:
                    focus.focusInDirection(TraversalDirection.right);
                }

                return null;
              },
            ),
            ...?widget.actions,
          },
          enabled: enabled,
          focusNode: _focusNode,
          mouseCursor:
              widget.mouseCursor?.resolve(widgetStates) ?? MouseCursor.defer,
          onShowFocusHighlight: (value) {
            _controller.update(WidgetState.focused, value);
            widget.onFocus?.call(value);
          },
          onShowHoverHighlight: (value) {
            _controller.update(
              WidgetState.hovered,
              value && !widget.disableHoverEffect,
            );
            widget.onHover?.call(value);
          },
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.arrowUp):
                const DirectionalFocusIntent(TraversalDirection.up),
            LogicalKeySet(LogicalKeyboardKey.arrowDown):
                const DirectionalFocusIntent(TraversalDirection.down),
            LogicalKeySet(LogicalKeyboardKey.arrowLeft):
                const DirectionalFocusIntent(TraversalDirection.left),
            LogicalKeySet(LogicalKeyboardKey.arrowRight):
                const DirectionalFocusIntent(TraversalDirection.right),
            ...?widget.shortcuts,
          },
          child: DefaultTextStyle.merge(
            style: widget.textStyle?.resolve(widgetStates),
            child: IconTheme.merge(
              data:
                  widget.iconTheme?.resolve(widgetStates) ??
                  const IconThemeData(),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return AnimatedValueBuilder(
                    builder: (context, value, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: value ?? Matrix4.identity(),
                        child: child,
                      );
                    },
                    duration: const Duration(milliseconds: 50),
                    lerp: lerpMatrix4,
                    value: widget.transform?.resolve(widgetStates),
                    child: child,
                  );
                },
                child: buttonContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContainer(
    BuildContext context,
    Decoration? decoration,
    Set<WidgetState> widgetStates,
  ) {
    final resolvedMargin = widget.margin?.resolve(widgetStates);
    final resolvedPadding = widget.padding?.resolve(widgetStates);
    if (widget.disableTransition) {
      Widget container = Container(
        clipBehavior: Clip.antiAlias,
        decoration: decoration,
        margin: resolvedMargin,
        padding: resolvedPadding,
        child: widget.child,
      );
      if (widget.marginAlignment != null) {
        container = Align(
          alignment: widget.marginAlignment!,
          child: container,
        );
      }

      return container;
    }
    Widget animatedContainer = AnimatedContainer(
      clipBehavior: decoration == null ? Clip.none : Clip.antiAlias,
      decoration: decoration,
      duration: kDefaultDuration,
      margin: resolvedMargin,
      padding: resolvedPadding,
      child: widget.child,
    );
    if (widget.marginAlignment != null) {
      animatedContainer = AnimatedAlign(
        alignment: widget.marginAlignment!,
        duration: kDefaultDuration,
        child: animatedContainer,
      );
    }

    return animatedContainer;
  }

  @override
  void didUpdateWidget(covariant Clickable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statesController != oldWidget.statesController) {
      _controller = widget.statesController ?? WidgetStatesController();
    }
    _controller.update(WidgetState.disabled, !widget.enabled);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.disableHoverEffect) {
      _controller.update(WidgetState.hovered, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    return WidgetStatesProvider(
      controller: _controller,
      states: {if (!enabled) WidgetState.disabled},
      child: ListenableBuilder(builder: _builder, listenable: _controller),
    );
  }
}
