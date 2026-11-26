import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/responsive_grid/responsive_grid_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified responsive-grid component for Web.
///
/// Renders a CSS Grid (`display: grid`,
/// `grid-template-columns: repeat(N, minmax(0, 1fr))`) with uniform
/// inter-cell spacing. When `responsive` is true, a scoped `<style>`
/// block emits `@container (min-width: ...)` rules that re-set
/// `grid-template-columns` at each `CoreBreakpoint`. Mirrors Flutter
/// `ResponsiveGrid`.
///
/// Per Epic #1603 (옵션 B 최종) all chrome / dimensional overrides
/// flow through [responsiveGridStyle]; the ergonomic per-instance
/// fields ([columns] / [cellSpacing] / [responsive] / [breakpoints])
/// still win over the resolved style chain.
class ResponsiveGrid extends UiComponent
    implements CoreResponsiveGridContract<Component> {
  /// Creates a [ResponsiveGrid].
  ResponsiveGrid({
    required this.children,
    this.columns,
    this.cellSpacing,
    this.responsive,
    this.breakpoints,
    this.responsiveGridStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : assert(
         columns == null || columns >= 1,
         'columns must be >= 1 when provided',
       ),
       assert(
         cellSpacing == null || cellSpacing >= 0,
         'cellSpacing must be >= 0 when provided',
       ),
       super(tag: 'div');

  @override
  final List<Component> children;

  @override
  final int? columns;

  @override
  final double? cellSpacing;

  @override
  final bool? responsive;

  @override
  final Map<CoreBreakpoint, int>? breakpoints;

  @override
  final CoreResponsiveGridStyle? responsiveGridStyle;
  @override
  ResponsiveGrid copyWith({
    Key? key,
    int? columns,
    double? cellSpacing,
    bool? responsive,
    Map<CoreBreakpoint, int>? breakpoints,
    CoreResponsiveGridStyle? responsiveGridStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    List<Component>? children,
  }) {
    return ResponsiveGrid(
      key: key ?? this.key,
      columns: columns ?? this.columns,
      cellSpacing: cellSpacing ?? this.cellSpacing,
      responsive: responsive ?? this.responsive,
      breakpoints: breakpoints ?? this.breakpoints,
      responsiveGridStyle: responsiveGridStyle ?? this.responsiveGridStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      children: children ?? this.children,
    );
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis + the
    // scoped-CSS rules template. `co_*` reads each slot directly — no
    // chrome composition in the widget body.
    final resolved = resolveResponsiveGrid(
      context,
      columns: columns,
      cellSpacing: cellSpacing,
      responsive: responsive,
      breakpoints: breakpoints,
      responsiveGridStyle: responsiveGridStyle,
    );
    final scopeId = id ?? _generateScopeId();
    // Category C scoped `@container` CSS — resolved by the separate
    // `resolveCo*` entry point (behavioural/composed data stays off the
    // pure-chrome `ResolvedResponsiveGrid`). Same merge chain as
    // `resolveResponsiveGrid`, with the runtime scope id folded in.
    final rulesCss = resolveResponsiveGridCss(
      context,
      scopeId: scopeId,
      columns: columns,
      cellSpacing: cellSpacing,
      responsive: responsive,
      breakpoints: breakpoints,
      responsiveGridStyle: responsiveGridStyle,
    );

    // Compose root className (resolver chrome — currently empty) with
    // user-provided `classes` so any future addition to the resolver's
    // root className propagates without touching co_responsive_grid.
    final rootClassName = resolved.root.className.isEmpty
        ? classes
        : (classes == null || classes!.isEmpty
              ? resolved.root.className
              : '${resolved.root.className} $classes');

    final gridNode = div(
      children,
      id: scopeId,
      classes: rootClassName,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );

    final wrapper = resolved.wrapper;
    if (rulesCss.isEmpty || wrapper == null) return gridNode;

    // Container wrapper: `container-type: inline-size` turns the
    // wrapper into a query container so `@container` rules inside
    // [rulesCss] read the wrapper's width (= the grid's available
    // width) rather than the viewport. Mirrors Flutter's
    // `LayoutBuilder` reading of `constraints.maxWidth`.
    return div(
      [
        Component.element(tag: 'style', children: [RawText(rulesCss)]),
        gridNode,
      ],
      classes: wrapper.className,
      styles: wrapper.inlineStyles,
    );
  }

  /// Scope id derived from the grid's own **configuration**, used only
  /// when the caller didn't pass `id`.
  ///
  /// This used to be `'co-grid-$hashCode'`. `hashCode` is identity-based,
  /// so it changed on every build — and with it both the emitted `id` and
  /// the `#co-grid-… { … }` rule in the component's own `<style>` child.
  /// For a statically rendered site that meant the HTML diffed on every
  /// build for no reason, and site CSS could never target the id because
  /// it was different next time.
  ///
  /// Deriving it from the layout inputs keeps it stable across builds
  /// while still separating grids that are configured differently — which
  /// is exactly what the scoped rule needs to distinguish.
  String _generateScopeId() {
    final config = Object.hash(
      columns,
      cellSpacing,
      responsive,
      breakpoints,
      responsiveGridStyle,
    );
    // Unsigned hex keeps it a valid id and drops the '-' a negative
    // hash would otherwise put right after the prefix.
    return 'co-grid-${config.toUnsigned(32).toRadixString(16)}';
  }
}

/// Chain sugar mirroring the Flutter `ResponsiveGrid.withStyle`
/// extension — merges a [CoreResponsiveGridStyle] patch into
/// [ResponsiveGrid.responsiveGridStyle] via the existing
/// [ResponsiveGrid.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreResponsiveGridStyle.merge` right-side-wins semantics).
extension ResponsiveGridStyleChain on ResponsiveGrid {
  /// Returns a copy of this [ResponsiveGrid] with [patch] merged into
  /// [responsiveGridStyle] (patch fields win on conflict).
  ResponsiveGrid withStyle(CoreResponsiveGridStyle patch) => copyWith(
    responsiveGridStyle:
        (responsiveGridStyle ?? const CoreResponsiveGridStyle()).merge(patch),
  );
}
