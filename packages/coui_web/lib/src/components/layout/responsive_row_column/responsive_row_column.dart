import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart' as dom_utils;
import 'package:coui_web/src/components/layout/responsive_row_column/responsive_row_column_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Layout primitive that renders [children] as a `Row` (horizontal)
/// at or above `switchAt`, and as a `Column` (vertical) below it —
/// the cross-platform analogue of `responsive_framework`'s
/// `ResponsiveRowColumn`, for CoUI Web.
///
/// Mirrors Flutter's `ResponsiveRowColumn` with identical parameters
/// and defaults. Rendered as a single `<div>` carrying `flex
/// flex-row`/`flex flex-col` plus `justify-*`/`items-*` alignment
/// classes and the inline-CSS `gap`. All chrome is pre-composed by
/// [resolveResponsiveRowColumn]; the widget only reads
/// `resolved.root.*` back into `div(...)`.
///
/// The direction depends on the viewport width read at build time, so
/// the state subscribes to window resizes and re-renders — the Web
/// counterpart of the Flutter twin's `MediaQuery` dependency, which
/// rebuilds it automatically when the window size changes.
class ResponsiveRowColumn extends UiStatefulComponent
    implements CoreResponsiveRowColumnContract<Component> {
  /// Creates a [ResponsiveRowColumn].
  const ResponsiveRowColumn({
    required this.children,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.switchAt,
    this.responsiveRowColumnStyle,
  });

  @override
  final List<Component> children;

  @override
  final CoreBreakpointTier? switchAt;

  @override
  final CoreResponsiveRowColumnStyle? responsiveRowColumnStyle;

  @override
  State<ResponsiveRowColumn> createState() => _ResponsiveRowColumnState();
}

class _ResponsiveRowColumnState extends State<ResponsiveRowColumn> {
  void Function()? _disposeResizeListener;

  @override
  void initState() {
    super.initState();
    // The resolved direction is a function of the viewport width, so a
    // window resize must re-render — Flutter gets this for free through
    // the MediaQuery dependency.
    _disposeResizeListener = dom_utils.listenForViewportResize(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _disposeResizeListener?.call();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveResponsiveRowColumn(
      context,
      switchAt: component.switchAt,
      responsiveRowColumnStyle: component.responsiveRowColumnStyle,
    );

    return div(
      component.children,
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes.isEmpty
          ? null
          : component.componentAttributes,
      events: component.events.isEmpty ? null : component.events,
    );
  }
}

/// Chain sugar for merging a [CoreResponsiveRowColumnStyle] patch into
/// [ResponsiveRowColumn.responsiveRowColumnStyle] without
/// hand-reconstructing every field. Mirrors the Flutter
/// `ResponsiveRowColumn.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreResponsiveRowColumnStyle.merge` right-side-wins
/// semantics).
///
/// ```dart
/// ResponsiveRowColumn(children: [...]).withStyle(
///   CoreResponsiveRowColumnStyle(spacing: CoreSpace.space16),
/// )
/// ```
extension ResponsiveRowColumnStyleChain on ResponsiveRowColumn {
  /// Returns a copy of this [ResponsiveRowColumn] with [patch] merged
  /// into [responsiveRowColumnStyle] (patch fields win on conflict).
  ResponsiveRowColumn withStyle(CoreResponsiveRowColumnStyle patch) => .new(
    key: key,
    attributes: userAttributes,
    classes: classes,
    css: css,
    eventHandlers: eventHandlers,
    id: id,
    switchAt: switchAt,
    responsiveRowColumnStyle:
        (responsiveRowColumnStyle ?? const CoreResponsiveRowColumnStyle())
            .merge(patch),
    children: children,
  );
}
