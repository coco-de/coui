import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/resizer.dart';

/// Theme for [HorizontalResizableDragger] and [VerticalResizableDragger].
class ResizableDraggerTheme {
  const ResizableDraggerTheme({
    this.borderRadius,
    this.color,
    this.height,
    this.iconColor,
    this.iconSize,
    this.width,
  });

  /// Background color of the dragger.
  final Color? color;

  /// Border radius of the dragger.
  final double? borderRadius;

  /// Width of the dragger.
  final double? width;

  /// Height of the dragger.
  final double? height;

  /// Icon size inside the dragger.
  final double? iconSize;

  /// Icon color inside the dragger.
  final Color? iconColor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ResizableDraggerTheme &&
        other.color == color &&
        other.borderRadius == borderRadius &&
        other.width == width &&
        other.height == height &&
        other.iconSize == iconSize &&
        other.iconColor == iconColor;
  }

  @override
  int get hashCode =>
      Object.hash(color, borderRadius, width, height, iconSize, iconColor);
}

/// A Horizontal dragger that can be used as a divider between resizable panes.
class HorizontalResizableDragger extends StatelessWidget {
  /// Creates a [HorizontalResizableDragger].
  const HorizontalResizableDragger({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<ResizableDraggerTheme>(context);
    final color = styleValue(
      themeValue: compTheme?.color,
      defaultValue: theme.colorScheme.border,
    );
    final borderRadius = styleValue(
      themeValue: compTheme?.borderRadius,
      defaultValue: theme.radiusSm,
    );
    final width = styleValue(
      themeValue: compTheme?.width,
      defaultValue: 3 * 4 * scaling,
    );
    final height = styleValue(
      themeValue: compTheme?.height,
      defaultValue: 4 * 4 * scaling,
    );
    final iconSize = styleValue(
      themeValue: compTheme?.iconSize,
      defaultValue: 4 * 2.5 * scaling,
    );
    final iconColor = styleValue(
      themeValue: compTheme?.iconColor,
      defaultValue: null,
    );

    return Center(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        width: width,
        height: height.toDouble(),
        child: Icon(
          RadixIcons.dragHandleDots2,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}

/// A Vertical dragger that can be used as a divider between resizable panes.
class VerticalResizableDragger extends StatelessWidget {
  /// Creates a [VerticalResizableDragger].
  const VerticalResizableDragger({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<ResizableDraggerTheme>(context);
    final color = styleValue(
      themeValue: compTheme?.color,
      defaultValue: theme.colorScheme.border,
    );
    final borderRadius = styleValue(
      themeValue: compTheme?.borderRadius,
      defaultValue: theme.radiusSm,
    );
    final width = styleValue(
      themeValue: compTheme?.width,
      defaultValue: 4 * 4 * scaling,
    );
    final height = styleValue(
      themeValue: compTheme?.height,
      defaultValue: 3 * 4 * scaling,
    );
    final iconSize = styleValue(
      themeValue: compTheme?.iconSize,
      defaultValue: 4 * 2.5 * scaling,
    );
    final iconColor = styleValue(
      themeValue: compTheme?.iconColor,
      defaultValue: null,
    );

    return Center(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        width: width,
        height: height.toDouble(),
        child: Transform.rotate(
          angle: pi / 2,
          child: Icon(
            RadixIcons.dragHandleDots2,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

/// A sibling of a resizable panel.
enum PanelSibling {
  both(0);

  final int direction;

  const PanelSibling(this.direction);
}

mixin ResizablePaneController implements ValueListenable<double> {
  /// Resizes the controller by the given [delta] amount.
  void resize(double newSize, double paneSize);

  void collapse();

  void expand();

  double computeSize(double paneSize, {double? maxSize, double? minSize});
  bool get collapsed;

  bool tryExpandSize(
    double size, [
    PanelSibling direction = PanelSibling.both,
  ]) {
    assert(_paneState != null, 'ResizablePaneController is not attached');

    return _paneState!.tryExpandSize(size, direction);
  }

  bool tryExpand([PanelSibling direction = PanelSibling.both]) {
    assert(_paneState != null, 'ResizablePaneController is not attached');

    return _paneState!.tryExpand(direction);
  }

  bool tryCollapse([PanelSibling direction = PanelSibling.both]) {
    assert(_paneState != null, 'ResizablePaneController is not attached');

    return _paneState!.tryCollapse(direction);
  }

  _ResizablePaneState? _paneState;

  void _attachPaneState(_ResizablePaneState panelData) {
    _paneState = panelData;
  }

  void _detachPaneState(_ResizablePaneState panelData) {
    if (_paneState == panelData) {
      _paneState = null;
    }
  }
}

class AbsoluteResizablePaneController extends ChangeNotifier
    with ResizablePaneController {
  AbsoluteResizablePaneController(this._size, {bool collapsed = false})
    : _collapsed = collapsed;

  late double _size;

  bool _collapsed = false;

  @override
  _ResizablePaneState? _paneState;

  @override
  double get value => _size;

  @override
  bool get collapsed => _collapsed;

  set size(double value) {
    _size = value;
    notifyListeners();
  }

  @override
  void collapse() {
    if (_collapsed) return;
    _collapsed = true;
    notifyListeners();
  }

  @override
  void expand() {
    if (!_collapsed) return;
    _collapsed = false;
    notifyListeners();
  }

  @override
  void resize(
    double newSize,
    double paneSize, {
    double? maxSize,
    double? minSize,
  }) {
    _size = newSize.clamp(minSize ?? 0, maxSize ?? double.infinity).toDouble();
    notifyListeners();
  }

  @override
  double computeSize(double paneSize, {double? maxSize, double? minSize}) {
    return _size.clamp(minSize ?? 0, maxSize ?? double.infinity).toDouble();
  }
}

class FlexibleResizablePaneController extends ChangeNotifier
    with ResizablePaneController {
  FlexibleResizablePaneController(this._flex, {bool collapsed = false})
    : _collapsed = collapsed;

  late double _flex;
  bool _collapsed = false;

  @override
  double get value => _flex;

  @override
  bool get collapsed => _collapsed;

  set flex(double value) {
    _flex = value;
    notifyListeners();
  }

  @override
  void collapse() {
    _collapsed = true;
    notifyListeners();
  }

  @override
  void expand() {
    _collapsed = false;
    notifyListeners();
  }

  @override
  void resize(
    double newSize,
    double paneSize, {
    double? maxSize,
    double? minSize,
  }) {
    _flex = newSize.clamp(minSize ?? 0, maxSize ?? double.infinity) / paneSize;
    notifyListeners();
  }

  @override
  double computeSize(double paneSize, {double? maxSize, double? minSize}) {
    return (_flex * paneSize)
        .clamp(minSize ?? 0, maxSize ?? double.infinity)
        .toDouble();
  }
}

class ResizablePane extends StatefulWidget {
  const ResizablePane({
    required this.child,
    this.collapsedSize,
    bool this.initialCollapsed = false,
    required double this.initialSize,
    super.key,
    this.maxSize,
    this.minSize,
    this.onSizeChange,
    this.onSizeChangeCancel,
    this.onSizeChangeEnd,
    this.onSizeChangeStart,
  }) : controller = null,
       initialFlex = null;

  const ResizablePane.flex({
    required this.child,
    this.collapsedSize,
    bool this.initialCollapsed = false,
    double this.initialFlex = 1,
    super.key,
    this.maxSize,
    this.minSize,
    this.onSizeChange,
    this.onSizeChangeCancel,
    this.onSizeChangeEnd,
    this.onSizeChangeStart,
  }) : controller = null,
       initialSize = null;

  const ResizablePane.controlled({
    required this.child,
    this.collapsedSize,
    required ResizablePaneController this.controller,
    super.key,
    this.maxSize,
    this.minSize,
    this.onSizeChange,
    this.onSizeChangeCancel,
    this.onSizeChangeEnd,
    this.onSizeChangeStart,
  }) : initialSize = null,
       initialFlex = null,
       initialCollapsed = null;

  final ResizablePaneController? controller;
  final double? initialSize;
  final double? initialFlex;
  final double? minSize;
  final double? maxSize;
  final double? collapsedSize;
  final Widget child;
  final ValueChanged<double>? onSizeChangeStart;
  final ValueChanged<double>? onSizeChange;

  final ValueChanged<double>? onSizeChangeEnd;

  final ValueChanged<double>? onSizeChangeCancel;

  final bool? initialCollapsed;

  @override
  State<ResizablePane> createState() => _ResizablePaneState();
}

class _ResizablePaneState extends State<ResizablePane> {
  late ResizablePaneController _controller;

  _ResizablePanelData? _panelState;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else if (widget.initialSize != null) {
      _controller = AbsoluteResizablePaneController(
        widget.initialSize!,
        collapsed: widget.initialCollapsed!,
      );
    } else {
      assert(widget.initialFlex != null, 'initalFlex must not be null');
      _controller = FlexibleResizablePaneController(
        widget.initialFlex!,
        collapsed: widget.initialCollapsed!,
      );
    }
    _controller._attachPaneState(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPanelState = Data.maybeOf<_ResizablePanelData>(context);
    if (_panelState != newPanelState) {
      _panelState?.detach(_controller);
      _panelState = newPanelState;
      _panelState?.attach(_controller);
    }
  }

  @override
  void didUpdateWidget(covariant ResizablePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller._detachPaneState(this);
      _panelState?.detach(_controller);
      if (widget.controller != null) {
        _controller = widget.controller!;
      } else if (widget.initialSize != null) {
        if (_controller is! AbsoluteResizablePaneController) {
          _controller = AbsoluteResizablePaneController(
            widget.initialSize!,
            collapsed: widget.initialCollapsed!,
          );
        }
      } else {
        if (_controller is! FlexibleResizablePaneController) {
          assert(widget.initialFlex != null, 'initalFlex must not be null');
          _controller = FlexibleResizablePaneController(
            widget.initialFlex!,
            collapsed: widget.initialCollapsed!,
          );
        }
      }
      _panelState?.attach(_controller);
      assert(
        _panelState != null,
        'ResizablePane must be a child of ResizablePanel',
      );
      _controller._attachPaneState(this);
    }
  }

  bool tryExpand([PanelSibling direction = PanelSibling.both]) {
    if (!_controller.collapsed) {
      return false;
    }
    final draggers = _panelState!.state.computeDraggers();
    final resizer = Resizer(draggers);
    final result = resizer.attemptExpandCollapsed(
      _panelState!.index,
      direction.direction,
    );
    if (result) {
      _panelState!.state.updateDraggers(resizer.items);
    }

    return result;
  }

  bool tryCollapse([PanelSibling direction = PanelSibling.both]) {
    if (_controller.collapsed) {
      return false;
    }
    final draggers = _panelState!.state.computeDraggers();
    final resizer = Resizer(draggers);
    final result = resizer.attemptCollapse(
      _panelState!.index,
      direction.direction,
    );
    if (result) {
      _panelState!.state.updateDraggers(resizer.items);
    }

    return result;
  }

  bool tryExpandSize(
    double size, [
    PanelSibling direction = PanelSibling.both,
  ]) {
    final draggers = _panelState!.state.computeDraggers();
    final resizer = Resizer(draggers);
    final result = resizer.attemptExpand(
      size,
      direction.direction,
      _panelState!.index,
    );
    if (result) {
      _panelState!.state.updateDraggers(resizer.items);
    }

    return result;
  }

  @override
  void dispose() {
    _controller._detachPaneState(this);
    _panelState?.detach(_controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        double? size;
        double? flex;
        if (_controller is AbsoluteResizablePaneController) {
          final controller = _controller as AbsoluteResizablePaneController;
          size = controller.collapsed ? widget.collapsedSize : controller.value;
        } else if (_controller is FlexibleResizablePaneController) {
          final controller = _controller as FlexibleResizablePaneController;
          if (controller.collapsed) {
            size = widget.collapsedSize;
          } else {
            flex = controller.value;
          }
        }

        return _ResizableLayoutChild(
          flex: flex,
          size: size,
          child: ClipRect(child: widget.child),
        );
      },
    );
  }
}

class _ResizablePanelData {
  const _ResizablePanelData(this.index, this.state);

  final int index;

  final _ResizablePanelState state;

  void attach(ResizablePaneController controller) {
    state.attachController(controller);
  }

  void detach(ResizablePaneController controller) {
    state.detachController(controller);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _ResizablePanelData &&
        other.state == state &&
        other.index == index;
  }

  @override
  int get hashCode {
    return Object.hash(state, index);
  }
}

typedef OptionalWidgetBuilder = Widget? Function(BuildContext context);

/// A container widget that creates resizable panels separated by interactive dividers.
///
/// This widget provides a flexible layout system where multiple child panes
/// can be resized by the user through draggable dividers. It supports both
/// horizontal and vertical orientations, allowing users to adjust the relative
/// sizes of the contained panels by dragging the separators between them.
///
/// Each [ResizablePane] child can have its own sizing constraints, minimum and
/// maximum sizes, and collapse behavior. The panel automatically manages the
/// distribution of available space and handles user interactions for resizing.
///
/// Example:
/// ```dart
/// ResizablePanel.horizontal(
///   children: [
///     ResizablePane(
///       child: Container(color: Colors.red),
///       minSize: 100,
///       defaultSize: 200,
///     ),
///     ResizablePane(
///       child: Container(color: Colors.blue),
///       flex: 1,
///     ),
///     ResizablePane(
///       child: Container(color: Colors.green),
///       defaultSize: 150,
///       maxSize: 300,
///     ),
///   ],
/// );
/// ```
class ResizablePanel extends StatefulWidget {
  /// Creates a horizontal resizable panel with panes arranged left-to-right.
  ///
  /// This is a convenience constructor that sets [direction] to [Axis.horizontal]
  /// and provides default builders for dividers and draggers appropriate for
  /// horizontal layouts.
  ///
  /// Parameters:
  /// - [children] (List<ResizablePane>, required): The panes to arrange horizontally
  /// - [dividerBuilder] (OptionalWidgetBuilder?, optional): Custom divider builder
  /// - [draggerBuilder] (OptionalWidgetBuilder?, optional): Custom dragger builder
  /// - [draggerThickness] (double?, optional): Size of the draggable resize area
  ///
  /// Example:
  /// ```dart
  /// ResizablePanel.horizontal(
  ///   children: [
  ///     ResizablePane(child: LeftSidebar(), defaultSize: 200),
  ///     ResizablePane(child: MainContent(), flex: 1),
  ///     ResizablePane(child: RightPanel(), defaultSize: 150),
  ///   ],
  /// );
  /// ```
  const ResizablePanel.horizontal({
    required this.children,
    this.dividerBuilder = defaultDividerBuilder,
    this.draggerBuilder,
    this.draggerThickness,
    super.key,
    this.optionalDivider = false,
  }) : direction = Axis.horizontal;

  /// Creates a vertical resizable panel with panes arranged top-to-bottom.
  ///
  /// This is a convenience constructor that sets [direction] to [Axis.vertical]
  /// and provides default builders for dividers and draggers appropriate for
  /// vertical layouts.
  ///
  /// Parameters:
  /// - [children] (List<ResizablePane>, required): The panes to arrange vertically
  /// - [dividerBuilder] (OptionalWidgetBuilder?, optional): Custom divider builder
  /// - [draggerBuilder] (OptionalWidgetBuilder?, optional): Custom dragger builder
  /// - [draggerThickness] (double?, optional): Size of the draggable resize area
  ///
  /// Example:
  /// ```dart
  /// ResizablePanel.vertical(
  ///   children: [
  ///     ResizablePane(child: Header(), defaultSize: 60),
  ///     ResizablePane(child: Content(), flex: 1),
  ///     ResizablePane(child: Footer(), defaultSize: 40),
  ///   ],
  /// );
  /// ```
  const ResizablePanel.vertical({
    required this.children,
    this.dividerBuilder = defaultDividerBuilder,
    this.draggerBuilder,
    this.draggerThickness,
    super.key,
    this.optionalDivider = false,
  }) : direction = Axis.vertical;

  /// Default builder for dividers between resizable panes.
  ///
  /// Creates appropriate divider widgets based on the panel orientation:
  /// - Horizontal panels get vertical dividers
  /// - Vertical panels get horizontal dividers
  ///
  /// This is the default value for [dividerBuilder] when none is specified.
  static Widget? defaultDividerBuilder(BuildContext context) {
    final data = Data.of<ResizableData>(context);

    return data.direction == Axis.horizontal
        ? const VerticalDivider()
        : const Divider();
  }

  /// The axis along which the panels are arranged and can be resized.
  ///
  /// When [Axis.horizontal], panels are arranged left-to-right with vertical
  /// dividers between them. When [Axis.vertical], panels are arranged
  /// top-to-bottom with horizontal dividers between them.
  final Axis direction;

  /// The list of resizable panes that make up this panel.
  ///
  /// Each pane can specify its own sizing constraints, default size, and
  /// collapse behavior. At least two panes are typically needed to create
  /// a meaningful resizable interface.
  final List<ResizablePane> children;

  /// Optional builder for creating divider widgets between panes.
  ///
  /// Called to create the visual separator between adjacent panes. If null,
  /// uses [defaultDividerBuilder] to create appropriate dividers based on
  /// the panel orientation.
  final OptionalWidgetBuilder? dividerBuilder;

  /// Optional builder for creating interactive drag handles between panes.
  ///
  /// Called to create draggable resize handles between adjacent panes. These
  /// handles allow users to adjust pane sizes. If null, no drag handles are
  /// displayed but dividers may still be present if [dividerBuilder] is set.
  final OptionalWidgetBuilder? draggerBuilder;

  /// The thickness of the draggable area between panes.
  ///
  /// Controls the size of the interactive region for resizing. A larger value
  /// makes it easier to grab and drag the resize handles, while a smaller
  /// value provides a more compact appearance.
  final double? draggerThickness;

  /// Hides the divider when not hovered or being dragged.
  final bool optionalDivider;

  @override
  State<ResizablePanel> createState() => _ResizablePanelState();
}

// extends as ResizableItem, but adds nothing
class _ResizableItem extends ResizableItem {
  _ResizableItem({
    super.collapsed,
    super.collapsedSize,
    required this.controller,
    super.max,
    super.min,
    required super.value,
  });

  final ResizablePaneController controller;
}

class _ResizablePanelState extends State<ResizablePanel> {
  final _controllers = <ResizablePaneController>[];
  final _hoveredDividers = <int>{};
  final _draggingDividers = <int>{};
  late double _panelSize;

  List<ResizableItem> computeDraggers() {
    final draggers = <ResizableItem>[];
    final controllers = _controllers;
    controllers.sort((a, b) {
      final stateA = a._paneState;
      final stateB = b._paneState;
      if (stateA == null || stateB == null) {
        return 0;
      }
      final widgetA = stateA.widget;
      final widgetB = stateB.widget;
      final indexWidgetA = widget.children.indexOf(widgetA);
      final indexWidgetB = widget.children.indexOf(widgetB);

      return indexWidgetA.compareTo(indexWidgetB);
    });
    for (final controller in controllers) {
      final computedSize = controller.computeSize(
        _panelSize,
        maxSize: controller.collapsed
            ? null
            : controller._paneState!.widget.maxSize,
        minSize: controller.collapsed
            ? null
            : controller._paneState!.widget.minSize,
      );
      draggers.add(
        _ResizableItem(
          collapsed: controller.collapsed,
          collapsedSize: controller._paneState!.widget.collapsedSize,
          controller: controller,
          max: controller._paneState!.widget.maxSize ?? double.infinity,
          min: controller._paneState!.widget.minSize ?? 0,
          value: computedSize,
        ),
      );
    }

    return draggers;
  }

  void updateDraggers(List<ResizableItem> draggers) {
    for (int i = 0; i < draggers.length; i += 1) {
      final item = draggers[i];
      if (item is _ResizableItem) {
        final controller = item.controller;
        if (item.newCollapsed) {
          controller.collapse();
        } else {
          controller.expand();
        }
        controller.resize(item.newValue, _panelSize);
      }
    }
  }

  void attachController(ResizablePaneController controller) {
    _controllers.add(controller);
  }

  void detachController(ResizablePaneController controller) {
    _controllers.remove(controller);
  }

  Widget _build(BuildContext context) {
    final dividers = <Widget>[];
    for (int i = 0; i < widget.children.length - 1; i += 1) {
      final divider = widget.dividerBuilder?.call(context) ?? const SizedBox();
      dividers.add(divider);
    }
    final children = <Widget>[];
    for (int i = 0; i < widget.children.length; i += 1) {
      children.add(
        Data<_ResizablePanelData>.inherit(
          key: widget.children[i].key,
          data: _ResizablePanelData(i, this),
          child: widget.children[i],
        ),
      );
      if (i < dividers.length) {
        children.add(
          _ResizableLayoutChild(
            isDivider: true,
            child: widget.optionalDivider
                ? AnimatedOpacity(
                    opacity:
                        _hoveredDividers.contains(i) ||
                            _draggingDividers.contains(i)
                        ? 1.0
                        : 0.0,
                    duration: kDefaultDuration,
                    child: dividers[i],
                  )
                : dividers[i],
          ),
        );
      }
    }
    if (widget.draggerBuilder != null) {
      for (int i = 0; i < widget.children.length - 1; i += 1) {
        children.add(
          _ResizableLayoutChild(
            index: i,
            isDragger: true,
            child: widget.optionalDivider
                ? AnimatedOpacity(
                    opacity:
                        _hoveredDividers.contains(i) ||
                            _draggingDividers.contains(i)
                        ? 1.0
                        : 0.0,
                    duration: kDefaultDuration,
                    child: widget.draggerBuilder!(context) ?? const SizedBox(),
                  )
                : widget.draggerBuilder!(context) ?? const SizedBox(),
          ),
        );
      }
    }
    for (int i = 0; i < widget.children.length - 1; i += 1) {
      children.add(
        _ResizableLayoutChild(
          index: i,
          isDragger: false,
          child: MouseRegion(
            onEnter: (_) {
              if (!widget.optionalDivider) return;
              setState(() {
                _hoveredDividers.add(i);
              });
            },
            onExit: (_) {
              if (!widget.optionalDivider) return;
              setState(() {
                _hoveredDividers.remove(i);
              });
            },
            child: _Resizer(
              direction: widget.direction,
              index: i,
              onResizeEnd: () {
                if (!widget.optionalDivider) return;
                setState(() {
                  _draggingDividers.remove(i);
                });
              },
              onResizeStart: () {
                if (!widget.optionalDivider) return;
                setState(() {
                  _draggingDividers.add(i);
                });
              },
              panelState: this,
              thickness: widget.draggerThickness ?? 8,
            ),
          ),
        ),
      );
    }

    return _ResizableLayout(
      direction: widget.direction,
      onLayout: (panelSize, flexCount) {
        _panelSize = panelSize;
      },
      children: children,
    );
  }

  @override
  void didUpdateWidget(covariant ResizablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.optionalDivider != oldWidget.optionalDivider &&
        !widget.optionalDivider) {
      _hoveredDividers.clear();
      _draggingDividers.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Data.inherit(
      data: ResizableData(widget.direction),
      child: Builder(builder: _build),
    );
  }
}

class ResizableData {
  const ResizableData(this.direction);
  final Axis direction;
}

class _Resizer extends StatefulWidget {
  const _Resizer({
    required this.direction,
    required this.index,
    this.onResizeEnd,
    this.onResizeStart,
    required this.panelState,
    required this.thickness,
  });

  final Axis direction;
  final int index;
  final double thickness;
  final _ResizablePanelState panelState;
  final VoidCallback? onResizeStart;

  final VoidCallback? onResizeEnd;

  @override
  State<_Resizer> createState() => _ResizerState();
}

class _ResizerState extends State<_Resizer> {
  Resizer? _dragSession;

  void _onDragStart(DragStartDetails details) {
    _dragSession = Resizer(widget.panelState.computeDraggers());

    // Call onSizeChangeStart callbacks for affected panes
    _callSizeChangeStartCallbacks();
    widget.onResizeStart?.call();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragSession!.dragDivider(widget.index + 1, details.primaryDelta!);
    widget.panelState.updateDraggers(_dragSession!.items);

    // Call onSizeChange callbacks for affected panes
    _callSizeChangeCallbacks();
  }

  void _onDragEnd(DragEndDetails details) {
    // Call onSizeChangeEnd callbacks for affected panes
    _callSizeChangeEndCallbacks();
    _dragSession = null;
    widget.onResizeEnd?.call();
  }

  void _onDragCancel() {
    _dragSession!.reset();
    widget.panelState.updateDraggers(_dragSession!.items);

    // Call onSizeChangeCancel callbacks for affected panes
    _callSizeChangeCancelCallbacks();
    _dragSession = null;
    widget.onResizeEnd?.call();
  }

  void _callSizeChangeStartCallbacks() {
    if (_dragSession == null) return;

    // Call callbacks for the two panes adjacent to this divider
    _callStartCallbackForPane(
      widget.index,
      _dragSession!.items[widget.index].value,
    );
    if (widget.index + 1 < _dragSession!.items.length) {
      _callStartCallbackForPane(
        widget.index + 1,
        _dragSession!.items[widget.index + 1].value,
      );
    }
  }

  void _callSizeChangeCallbacks() {
    if (_dragSession == null) return;

    // Call callbacks for the two panes adjacent to this divider
    _callChangeCallbackForPane(
      widget.index,
      _dragSession!.items[widget.index].newValue,
    );
    if (widget.index + 1 < _dragSession!.items.length) {
      _callChangeCallbackForPane(
        widget.index + 1,
        _dragSession!.items[widget.index + 1].newValue,
      );
    }
  }

  void _callSizeChangeEndCallbacks() {
    if (_dragSession == null) return;

    // Call callbacks for the two panes adjacent to this divider
    _callEndCallbackForPane(
      widget.index,
      _dragSession!.items[widget.index].newValue,
    );
    if (widget.index + 1 < _dragSession!.items.length) {
      _callEndCallbackForPane(
        widget.index + 1,
        _dragSession!.items[widget.index + 1].newValue,
      );
    }
  }

  void _callSizeChangeCancelCallbacks() {
    if (_dragSession == null) return;

    // Call callbacks for the two panes adjacent to this divider
    _callCancelCallbackForPane(
      widget.index,
      _dragSession!.items[widget.index].newValue,
    );
    if (widget.index + 1 < _dragSession!.items.length) {
      _callCancelCallbackForPane(
        widget.index + 1,
        _dragSession!.items[widget.index + 1].newValue,
      );
    }
  }

  ResizablePaneController? _getControllerAtIndex(int paneIndex) {
    if (paneIndex < 0 ||
        paneIndex >= widget.panelState.widget.children.length) {
      return null;
    }

    // Find controller by matching the widget at the given index
    final targetWidget = widget.panelState.widget.children[paneIndex];
    for (final controller in widget.panelState._controllers) {
      final paneState = controller._paneState;
      if (paneState?.widget == targetWidget) {
        return controller;
      }
    }

    return null;
  }

  void _callStartCallbackForPane(int paneIndex, double size) {
    final controller = _getControllerAtIndex(paneIndex);
    final callback = controller?._paneState?.widget.onSizeChangeStart;
    callback?.call(size);
  }

  void _callChangeCallbackForPane(int paneIndex, double size) {
    final controller = _getControllerAtIndex(paneIndex);
    final callback = controller?._paneState?.widget.onSizeChange;
    callback?.call(size);
  }

  void _callEndCallbackForPane(int paneIndex, double size) {
    final controller = _getControllerAtIndex(paneIndex);
    final callback = controller?._paneState?.widget.onSizeChangeEnd;
    callback?.call(size);
  }

  void _callCancelCallbackForPane(int paneIndex, double size) {
    final controller = _getControllerAtIndex(paneIndex);
    final callback = controller?._paneState?.widget.onSizeChangeCancel;
    callback?.call(size);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.direction == Axis.horizontal ? widget.thickness : null,
      height: widget.direction == Axis.vertical ? widget.thickness : null,
      child: MouseRegion(
        cursor: widget.direction == Axis.horizontal
            ? SystemMouseCursors.resizeColumn
            : SystemMouseCursors.resizeRow,
        hitTestBehavior: HitTestBehavior.translucent,
        child: GestureDetector(
          onVerticalDragStart: widget.direction == Axis.vertical
              ? _onDragStart
              : null,
          onVerticalDragUpdate: widget.direction == Axis.vertical
              ? _onDragUpdate
              : null,
          onVerticalDragEnd: widget.direction == Axis.vertical
              ? _onDragEnd
              : null,
          onVerticalDragCancel: widget.direction == Axis.vertical
              ? _onDragCancel
              : null,
          onHorizontalDragStart: widget.direction == Axis.horizontal
              ? _onDragStart
              : null,
          onHorizontalDragUpdate: widget.direction == Axis.horizontal
              ? _onDragUpdate
              : null,
          onHorizontalDragEnd: widget.direction == Axis.horizontal
              ? _onDragEnd
              : null,
          onHorizontalDragCancel: widget.direction == Axis.horizontal
              ? _onDragCancel
              : null,
          behavior: HitTestBehavior.translucent,
        ),
      ),
    );
  }
}

class _ResizableLayoutParentData extends ContainerBoxParentData<RenderBox> {
  /// If index is null, then its an overlay that handle the resize dragger (on the border/edge).
  int? index;

  /// If isDragger is true, then its a dragger that should be placed above "index" panel right border.
  bool? isDragger;

  /// There are total "totalPanes" - 1 of dragger.
  bool? isDivider;

  double? size;
  double? flex;
}

class _ResizableLayoutChild
    extends ParentDataWidget<_ResizableLayoutParentData> {
  const _ResizableLayoutChild({
    required super.child,
    this.flex,
    this.index,
    this.isDivider,
    this.isDragger,
    this.size,
  });

  final int? index;
  final bool? isDragger;
  final bool? isDivider;
  final double? size;

  final double? flex;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as _ResizableLayoutParentData;
    bool needsLayout = false;

    if (parentData.index != index) {
      parentData.index = index;
      needsLayout = true;
    }

    if (parentData.isDragger != isDragger) {
      parentData.isDragger = isDragger;
      needsLayout = true;
    }

    if (parentData.isDivider != isDivider) {
      parentData.isDivider = isDivider;
      needsLayout = true;
    }

    if (parentData.size != size) {
      parentData.size = size;
      needsLayout = true;
    }

    if (parentData.flex != flex) {
      parentData.flex = flex;
      needsLayout = true;
    }

    if (needsLayout) {
      final targetParent = renderObject.parent;
      targetParent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _ResizableLayout;
}

typedef _ResizableLayoutCallback =
    void Function(double flexCount, double panelSize);

class _ResizableLayout extends MultiChildRenderObjectWidget {
  const _ResizableLayout({
    required super.children,
    required this.direction,
    required this.onLayout,
  });

  final Axis direction;

  final _ResizableLayoutCallback onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderResizableLayout(direction, onLayout);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderResizableLayout renderObject,
  ) {
    bool needsLayout = false;
    if (renderObject.direction != direction) {
      renderObject.direction = direction;
      needsLayout = true;
    }
    if (renderObject.onLayout != onLayout) {
      renderObject.onLayout = onLayout;
      needsLayout = true;
    }
    if (needsLayout) {
      renderObject.markNeedsLayout();
    }
  }
}

class _RenderResizableLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ResizableLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ResizableLayoutParentData> {
  _RenderResizableLayout(this.direction, this.onLayout);

  Axis direction;

  _ResizableLayoutCallback onLayout;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ResizableLayoutParentData) {
      child.parentData = _ResizableLayoutParentData();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData! as _ResizableLayoutParentData;
      if (child.hasSize) {
        final isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            return child!.hitTest(result, position: transformed);
          },
        );
        if (isHit) return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;

    double mainOffset = 0;

    double intrinsicCross = 0;
    final hasInfiniteCross = direction == Axis.horizontal
        ? !constraints.hasBoundedHeight
        : !constraints.hasBoundedWidth;
    if (hasInfiniteCross) {
      for (final child in getChildrenAsList()) {
        final childParentData = child.parentData! as _ResizableLayoutParentData;
        if (childParentData.isDragger != true &&
            childParentData.index == null) {
          intrinsicCross = direction == Axis.horizontal
              ? max(
                  intrinsicCross,
                  child.getMaxIntrinsicHeight(double.infinity),
                )
              : max(
                  intrinsicCross,
                  child.getMaxIntrinsicWidth(double.infinity),
                );
        }
      }
    } else {
      intrinsicCross = direction == Axis.horizontal
          ? constraints.maxHeight
          : constraints.maxWidth;
    }

    /// Lay out the dividers.
    double flexCount = 0;
    final dividerSizes = <double>[];
    RenderBox? child = firstChild;
    double panelSize = 0;
    final dividerOffsets = <double>[];
    while (child != null) {
      final childParentData = child.parentData! as _ResizableLayoutParentData;
      if (childParentData.isDragger != true && childParentData.index == null) {
        if (childParentData.isDivider ?? false) {
          BoxConstraints childConstraints;
          childConstraints = direction == Axis.horizontal
              ? BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  minHeight: intrinsicCross,
                  maxHeight: intrinsicCross,
                )
              : BoxConstraints(
                  minWidth: intrinsicCross,
                  maxWidth: intrinsicCross,
                  maxHeight: constraints.maxHeight,
                );
          child.layout(childConstraints, parentUsesSize: true);
          final childSize = child.size;
          final sizeExtent = _getSizeExtent(childSize);
          dividerSizes.add(sizeExtent);
          mainOffset += sizeExtent;
        } else if (childParentData.flex != null) {
          flexCount += childParentData.flex!;
        } else if (childParentData.size != null) {
          panelSize += childParentData.size!;
        }
      }
      child = childParentData.nextSibling;
    }
    final totalDividerSize = mainOffset;
    mainOffset = 0;

    /// Lay out the panes.
    child = firstChild;
    final sizes = <double>[];
    final parentSize = direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    final remainingSpace = parentSize - (panelSize + totalDividerSize);
    final flexSpace = remainingSpace / flexCount;
    onLayout(flexSpace, flexCount);
    while (child != null) {
      final childParentData = child.parentData! as _ResizableLayoutParentData;
      if (childParentData.isDragger != true && childParentData.index == null) {
        if (childParentData.isDivider == true) {
          childParentData.offset = _createOffset(mainOffset, 0);
          dividerOffsets.add(mainOffset + _getSizeExtent(child.size) / 2);
          mainOffset += _getSizeExtent(child.size);
        } else {
          BoxConstraints childConstraints;
          double childExtent;
          childExtent = childParentData.flex != null
              ? flexSpace * childParentData.flex!
              : childParentData.size!;
          childConstraints = direction == Axis.horizontal
              ? BoxConstraints(
                  minWidth: childExtent,
                  maxWidth: childExtent,
                  minHeight: intrinsicCross,
                  maxHeight: intrinsicCross,
                )
              : BoxConstraints(
                  minWidth: intrinsicCross,
                  maxWidth: intrinsicCross,
                  minHeight: childExtent,
                  maxHeight: childExtent,
                );
          child.layout(childConstraints, parentUsesSize: true);
          final childSize = child.size;
          final sizeExtent = _getSizeExtent(childSize);
          sizes.add(sizeExtent);
          childParentData.offset = _createOffset(mainOffset, 0);
          mainOffset += sizeExtent;
        }
      }
      child = childParentData.nextSibling;
    }

    /// Layout the rest.
    child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as _ResizableLayoutParentData;

      /// Total offset = sum of sizes from 0 to index.
      if (childParentData.isDragger ?? false || childParentData.index != null) {
        double minExtent = 0;
        if (childParentData.index != null) {
          minExtent = dividerSizes[childParentData.index!];
        }
        double intrinsicExtent = 0;
        intrinsicExtent = direction == Axis.horizontal
            ? child.getMaxIntrinsicWidth(double.infinity)
            : child.getMaxIntrinsicHeight(double.infinity);
        minExtent += intrinsicExtent;
        BoxConstraints draggerConstraints;
        draggerConstraints = direction == Axis.horizontal
            ? BoxConstraints(
                minWidth: minExtent,
                minHeight: intrinsicCross,
                maxHeight: intrinsicCross,
              )
            : BoxConstraints(
                minWidth: intrinsicCross,
                maxWidth: intrinsicCross,
                minHeight: minExtent,
              );
        child.layout(draggerConstraints, parentUsesSize: true);
        final draggerSize = child.size;

        /// Align at center.
        final sizeExtent = _getSizeExtent(draggerSize);
        childParentData.offset = _createOffset(
          dividerOffsets[childParentData.index!] - sizeExtent / 2,
          0,
        );
      }
      child = childParentData.nextSibling;
    }

    Size size;
    size = direction == Axis.horizontal
        ? Size(mainOffset, intrinsicCross)
        : Size(intrinsicCross, mainOffset);
    this.size = constraints.constrain(size);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return direction == Axis.horizontal
        ? _computeIntrinsicMainSize(height)
        : _computeIntrinsicCrossSize(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return direction == Axis.horizontal
        ? _computeIntrinsicMainSize(height)
        : _computeIntrinsicCrossSize(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return direction == Axis.vertical
        ? _computeIntrinsicMainSize(width)
        : _computeIntrinsicCrossSize(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return direction == Axis.vertical
        ? _computeIntrinsicMainSize(width)
        : _computeIntrinsicCrossSize(width);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    double mainOffset = 0;

    // Calculate cross axis size
    double intrinsicCross = 0;
    final hasInfiniteCross = direction == Axis.horizontal
        ? !constraints.hasBoundedHeight
        : !constraints.hasBoundedWidth;

    intrinsicCross = hasInfiniteCross
        ? direction == Axis.horizontal
              ? computeMinIntrinsicHeight(constraints.maxWidth)
              : computeMinIntrinsicWidth(constraints.maxHeight)
        : direction == Axis.horizontal
        ? constraints.maxHeight
        : constraints
              .maxWidth; // Calculate main axis sizes - similar to performLayout but without actual layout
    double flexCount = 0;
    double panelSize = 0;
    double totalDividerSize = 0;

    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as _ResizableLayoutParentData;

      if (childParentData.isDragger != true && childParentData.index == null) {
        if (childParentData.isDivider ?? false) {
          // Calculate divider size
          Size childSize;
          childSize = direction == Axis.horizontal
              ? child.getDryLayout(
                  BoxConstraints(
                    maxWidth: constraints.maxWidth,
                    minHeight: intrinsicCross,
                    maxHeight: intrinsicCross,
                  ),
                )
              : child.getDryLayout(
                  BoxConstraints(
                    minWidth: intrinsicCross,
                    maxWidth: intrinsicCross,
                    maxHeight: constraints.maxHeight,
                  ),
                );
          totalDividerSize += _getSizeExtent(childSize);
        } else if (childParentData.flex != null) {
          flexCount += childParentData.flex!;
        } else if (childParentData.size != null) {
          panelSize += childParentData.size!;
        }
      }

      child = childParentData.nextSibling;
    }

    // Calculate remaining space for flex children
    final parentSize = direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    final remainingSpace = parentSize - (panelSize + totalDividerSize);
    final flexSpace = flexCount > 0 ? remainingSpace / flexCount : 0;

    // Calculate total main axis size
    mainOffset = panelSize + totalDividerSize + (flexSpace * flexCount);

    Size size;
    size = direction == Axis.horizontal
        ? Size(mainOffset, intrinsicCross)
        : Size(intrinsicCross, mainOffset);
    return constraints.constrain(size);
  }

  double _getSizeExtent(Size size) {
    return direction == Axis.horizontal ? size.width : size.height;
  }

  Offset _createOffset(double cross, double main) {
    return direction == Axis.horizontal
        ? Offset(main, cross)
        : Offset(cross, main);
  }

  /// Helper method to compute intrinsic sizes based on children
  double _computeIntrinsicMainSize(double extent) {
    double totalSize = 0;

    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as _ResizableLayoutParentData;

      if (childParentData.isDragger != true && childParentData.index == null) {
        if (childParentData.isDivider ?? false) {
          direction == Axis.horizontal
              ? totalSize += child.getMinIntrinsicWidth(extent)
              : totalSize += child.getMinIntrinsicHeight(extent);
        } else if (childParentData.size != null) {
          // Fixed size pane
          totalSize += childParentData.size!;
        } else if (childParentData.flex != null) {
          direction == Axis.horizontal
              ? totalSize += child.getMinIntrinsicWidth(extent)
              : totalSize += child.getMinIntrinsicHeight(extent);
        }
      }

      child = childParentData.nextSibling;
    }

    return totalSize;
  }

  double _computeIntrinsicCrossSize(double extent) {
    double maxCrossSize = 0;

    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as _ResizableLayoutParentData;

      if (childParentData.isDragger != true && childParentData.index == null) {
        double childCrossSize;
        childCrossSize = direction == Axis.horizontal
            ? child.getMinIntrinsicHeight(extent)
            : child.getMinIntrinsicWidth(extent);
        maxCrossSize = max(maxCrossSize, childCrossSize);
      }

      child = childParentData.nextSibling;
    }

    return maxCrossSize;
  }
}
