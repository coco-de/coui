import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/layout/stage_container/stage_container_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

int _coStageContainerIdCounter = 0;

/// Web typedef for the cross-platform stage container builder.
typedef StageContainerBuilder = CoreStageContainerBuilder<Component>;

/// Web counterpart of `StageContainer`. Measures its own width via the
/// native `ResizeObserver` API, runs the exact same breakpoint math as the
/// Flutter widget, and hands the resolved per-axis padding to [builder] on
/// every rebuild.
class StageContainer extends UiStatefulComponent
    implements CoreStageContainerContract<Component> {
  /// Creates a [StageContainer].
  const StageContainer({
    required this.builder,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    CoreStageBreakpoint? breakpoint,
    CoreEdgeInsets? padding,
    this.stageContainerStyle,
  }) : _widgetBreakpoint = breakpoint,
       _widgetPadding = padding;

  @override
  final StageContainerBuilder builder;

  @override
  final CoreStageContainerStyle? stageContainerStyle;
  final CoreStageBreakpoint? _widgetBreakpoint;

  final CoreEdgeInsets? _widgetPadding;

  @override
  CoreStageBreakpoint get breakpoint =>
      _widgetBreakpoint ?? CoreStageBreakpoint.defaultBreakpoints;

  @override
  CoreEdgeInsets get padding =>
      _widgetPadding ?? CoreStageContainerStyle.defaultPadding;

  /// Returns a copy of this [StageContainer] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  StageContainer copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    CoreStageBreakpoint? breakpoint,
    CoreEdgeInsets? padding,
    CoreStageContainerStyle? stageContainerStyle,
    StageContainerBuilder? builder,
  }) {
    return StageContainer(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      breakpoint: breakpoint ?? _widgetBreakpoint,
      padding: padding ?? _widgetPadding,
      stageContainerStyle: stageContainerStyle ?? this.stageContainerStyle,
      builder: builder ?? this.builder,
    );
  }

  @override
  State<StageContainer> createState() => _StageContainerState();
}

class _StageContainerState extends State<StageContainer> {
  late final _scopeId = 'co-stage-container-${_coStageContainerIdCounter++}';

  /// The observed root element's id — a caller-supplied id wins
  /// (passthrough) and also becomes the ResizeObserver's measured node;
  /// else the generated per-instance scope id.
  String get _effectiveScopeId => component.id ?? _scopeId;

  /// Last observed parent width in CSS pixels. `null` until the first
  /// `ResizeObserver` callback fires, at which point we rebuild with the
  /// real measurement.
  double? _measuredWidth;

  void Function()? _disposeObserver;

  @override
  void initState() {
    super.initState();
    // Pull the first measurement eagerly after the initial paint so builders
    // that depend on `padding` don't render with the fallback for an extra
    // frame. Subsequent changes flow through the ResizeObserver.
    Future.microtask(_handleInitialMeasurement);
  }

  void _handleInitialMeasurement() {
    final size = readElementSize(_effectiveScopeId);
    if (size != null && mounted && _measuredWidth != size.width) {
      setState(() => _measuredWidth = size.width);
    }
    _disposeObserver = observeElementResize(_effectiveScopeId, _handleResize);
  }

  void _handleResize(double width, double height) {
    if (!mounted) return;
    if (_measuredWidth == width) return;
    setState(() => _measuredWidth = width);
  }

  @override
  void dispose() {
    _disposeObserver?.call();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveStageContainer(
      context,
      breakpoint: component._widgetBreakpoint,
      padding: component._widgetPadding,
      measuredWidth: _measuredWidth,
      stageContainerStyle: component.stageContainerStyle,
    );
    // Behavioural padding handed to the builder callback is read off the
    // merge chain via the separate `resolveCo*` entry point — kept off
    // `ResolvedStageContainer` (pure chrome) per the number_ticker
    // pattern. It runs the same merge + breakpoint redistribution that
    // produced the box chrome, so the value is byte-identical.
    final padding = resolveStageContainerPadding(
      context,
      breakpoint: component._widgetBreakpoint,
      padding: component._widgetPadding,
      measuredWidth: _measuredWidth,
      stageContainerStyle: component.stageContainerStyle,
    );
    final child = component.builder(context, padding);
    // Two-div wrapping:
    //   outer (id: _scopeId, observed): `w-full` with *no* padding so the
    //     ResizeObserver's content-rect stays equal to the parent's width on
    //     every rebuild. Without this, applying padding on the observed
    //     element would shrink its own content-rect and trigger another
    //     resize callback, creating a visible flicker loop.
    //   inner (`resolved.box`): receives the resolved padding + `w-full` so
    //     the builder's child still reflects the calculated insets.
    return div(
      [
        div(
          [child],
          classes: resolved.box.className,
          styles: resolved.box.inlineStyles,
        ),
      ],
      id: _effectiveScopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
    );
  }
}

/// Chain sugar mirroring the Flutter `StageContainer.withStyle` extension
/// — merges a [CoreStageContainerStyle] patch into
/// [StageContainer.stageContainerStyle] via the existing
/// [StageContainer.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStageContainerStyle.merge` right-side-wins semantics).
extension StageContainerStyleChain on StageContainer {
  /// Returns a copy of this [StageContainer] with [patch] merged into
  /// [stageContainerStyle] (patch fields win on conflict).
  StageContainer withStyle(CoreStageContainerStyle patch) => copyWith(
    stageContainerStyle:
        (stageContainerStyle ?? const CoreStageContainerStyle()).merge(patch),
  );
}
