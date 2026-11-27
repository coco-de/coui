import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/basic/basic_default_example.dart';
import 'package:docs_core/previews/examples/flutter/category_breakdown/category_breakdown_default_example.dart';
import 'package:docs_core/previews/examples/flutter/category_breakdown/category_breakdown_donut_example.dart';
import 'package:docs_core/previews/examples/flutter/disclosure_badge/disclosure_badge_commitment_example.dart';
import 'package:docs_core/previews/examples/flutter/disclosure_badge/disclosure_badge_default_example.dart';
import 'package:docs_core/previews/examples/flutter/multiple_choice/multiple_choice_default_example.dart';
import 'package:docs_core/previews/examples/flutter/page_header/page_header_default_example.dart';
import 'package:docs_core/previews/examples/flutter/sidebar/sidebar_collapsed_example.dart';
import 'package:docs_core/previews/examples/flutter/sidebar/sidebar_default_example.dart';
import 'package:docs_core/previews/examples/flutter/sidebar/sidebar_two_pane_example.dart';
import 'package:docs_core/previews/examples/flutter/tab_pane/tab_pane_editor_strip_example.dart';
import 'package:docs_core/previews/examples/flutter/tab_pane/tab_pane_example.dart';
import 'package:docs_core/previews/examples/flutter/timeline/timeline_default_example.dart';
import 'package:docs_core/previews/examples/flutter/tree/tree_default_example.dart';
import 'package:docs_core/previews/examples/flutter/tree/tree_selected_example.dart';
import 'package:docs_core/previews/examples/flutter/tree/tree_trailing_example.dart';
import 'package:docs_core/previews/examples/flutter/trend_chart/trend_chart_bar_example.dart';
import 'package:docs_core/previews/examples/flutter/trend_chart/trend_chart_default_example.dart';
import 'package:docs_core/previews/examples/flutter/window_panel/window_panel_default_example.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show
        AnimatedContainer,
        Column,
        Container,
        DecoratedBox,
        Directionality,
        EdgeInsets,
        Element,
        FocusTraversalGroup,
        IntrinsicHeight,
        IntrinsicWidth,
        KeyedSubtree,
        LayoutBuilder,
        MultiChildRenderObjectWidget,
        Padding,
        Row,
        Semantics,
        Shortcuts,
        SizedBox,
        Widget,
        Wrap;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

enum _Kind {
  basic,
  badge,
  choices,
  header,
  sidebar,
  tabs,
  tree,
  timeline,
  category,
  trend,
  window,
}

typedef _Route = ({
  Element result,
  Element producer,
  Element field,
  Element frame,
  BoxProducerScope scope,
  List<Widget> raw,
  List<Object?> witness,
});

/// References to one audited current construction, never a replayed builder.
class StructuredRootBoxSourceBinding {
  StructuredRootBoxSourceBinding._(
    this._capture,
    this._registry,
    this._source,
    this._kind,
    this._route,
  ) : _producerWidget = _route.producer.widget;
  final Element _capture;
  final Widget _registry;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;
  final _Kind _kind;
  final _Route _route;

  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.field;
  Element get paddingSource => _route.field;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get authority =>
      'Concrete ${_kind.name} current public construction; '
      'all raw slots checked before source omission; complete mounted '
      'foreign boundaries excluded; current source operation; '
      'no style reconstruction';
  String get readerId => switch (_kind) {
    _Kind.basic || _Kind.tabs => 'current-render-padding-v1',
    _Kind.badge => 'structured-solid-border-content-v1',
    _Kind.window => 'current-outlined-container-content-v1',
    _ => 'structured-root-declared-absence-v1',
  };

  void validateExistingCurrentBinding() {
    if (!_capture.mounted ||
        !_route.producer.mounted ||
        !identical(_route.result.widget, _registry) ||
        !identical(_route.producer.widget, _producerWidget)) {
      throw _changed('held construction identities');
    }
    final now = _locate(_capture, _registry, _source, _kind);
    if (!identical(now.result, _route.result) ||
        !identical(now.producer, _route.producer) ||
        !identical(now.field, _route.field) ||
        !identical(now.frame, _route.frame) ||
        !_same(now.raw, _route.raw, identity: true) ||
        !_same(now.witness, _route.witness) ||
        !_same(
          now.scope.foreignBoundaries,
          scope.foreignBoundaries,
          identity: true,
        )) {
      throw _changed('held current operation, slots and state witnesses');
    }
  }

  BoxPaddingObservation readActualPadding() {
    validateExistingCurrentBinding();
    switch (_kind) {
      case _Kind.basic:
      case _Kind.tabs:
        return observeSourceOwnedRenderPadding(
          owner: paddingSource,
          scope: scope,
        ).withFrameOwner(frameSource);
      case _Kind.window:
        return observeOutlinedContainerContentPadding(
          primitive: paddingSource,
          declaringScope: scope,
        );
      case _Kind.badge:
        // disclosure_badge.dart reserves the solid border once in its Padding.
        // DecoratedBox paints without layout allocation. Both values below are
        // Actual current render parameters only; no Core/resolver/style read.
        final render = frameSource.renderObject;
        final padding = paddingSource.renderObject;
        if (render is! RenderDecoratedBox ||
            padding is! RenderPadding ||
            render.decoration is! BoxDecoration) {
          throw _changed('solid current decoration and padding renderers');
        }
        final decoration = render.decoration as BoxDecoration;
        final border = decoration.border;
        if (border is! Border ||
            !border.isUniform ||
            border.top.style != BorderStyle.solid) {
          throw _changed('the actual uniform solid border allocation');
        }
        final direction = Directionality.of(paddingSource);
        final allocated = border.dimensions.resolve(direction);
        final actual = padding.padding.resolve(direction);
        final value = actual - allocated;
        if ([
          value.left,
          value.top,
          value.right,
          value.bottom,
        ].any((v) => !v.isFinite || v < 0)) {
          throw _changed('nonnegative actual content after border allocation');
        }
        return BoxPaddingObservation(
          value: value,
          quantity: PaddingQuantityKind.declaredOuterEdgeInsetWithinBorder,
          owner: paddingSource,
          producer: registryResultElement,
          contentBoundary: _child(
            paddingSource,
            (paddingSource.widget as Padding).child,
          ),
          paddingElement: paddingSource,
          currentRenderPadding: actual,
          allocatedDecorationInsets: allocated,
          excludedMargin: EdgeInsets.zero,
          generatedSlots: [
            {
              'sourceContract': readerId,
              'authority': authority,
              'allocation':
                  'actual solid decoration border reserved once '
                  'in current RenderPadding',
            },
          ],
          frameOwner: frameSource,
        );
      case _Kind.choices:
      case _Kind.header:
      case _Kind.sidebar:
      case _Kind.tree:
      case _Kind.timeline:
      case _Kind.category:
      case _Kind.trend:
        throw _changed('a parameter reader for a declared layout absence');
    }
  }

  BoxPaddingObservation readDeclaredAbsence() {
    validateExistingCurrentBinding();
    if ({_Kind.basic, _Kind.badge, _Kind.tabs, _Kind.window}.contains(_kind)) {
      throw _changed('absence on a parameter-bearing source operation');
    }
    return BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: fieldUnitElement,
      producer: registryResultElement,
      contentBoundary: fieldUnitElement,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      generatedSlots: [
        {'sourceContract': readerId, 'authority': authority},
      ],
      frameOwner: frameSource,
    );
  }
}

StructuredRootBoxSourceBinding? bindStructuredRootBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  final kinds = _Kind.values.where(
    (k) => _spec(k).logicalUnitId == source.logicalUnitId,
  );
  if (kinds.isEmpty) {
    return null;
  }
  final kind = kinds.single;
  return StructuredRootBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    kind,
    _locate(captureRoot, registryResult, source, kind),
  );
}

BoxObservationSourceSpec _spec(_Kind kind) => switch (kind) {
  _Kind.basic => BoxObservationSourceSpec.basicContentInset,
  _Kind.badge => BoxObservationSourceSpec.disclosureBadgeSolidContentInset,
  _Kind.choices => BoxObservationSourceSpec.multipleChoiceLayoutHost,
  _Kind.header => BoxObservationSourceSpec.pageHeaderLayoutHost,
  _Kind.sidebar => BoxObservationSourceSpec.sidebarOuterLayoutHost,
  _Kind.tabs => BoxObservationSourceSpec.tabPaneBarContentInset,
  _Kind.tree => BoxObservationSourceSpec.treeOuterLayoutHost,
  _Kind.timeline => BoxObservationSourceSpec.timelineSequenceLayoutHost,
  _Kind.category => BoxObservationSourceSpec.categoryBreakdownLayoutHost,
  _Kind.trend => BoxObservationSourceSpec.trendChartOuterLayoutHost,
  _Kind.window => BoxObservationSourceSpec.windowPanelFrameContentInset,
};
Type _type(_Kind kind) => switch (kind) {
  _Kind.basic => coui.Basic,
  _Kind.badge => coui.DisclosureBadge,
  _Kind.choices => coui.MultipleChoice<String>,
  _Kind.header => coui.PageHeader,
  _Kind.sidebar => coui.Sidebar,
  _Kind.tabs => coui.TabPane,
  _Kind.tree => coui.Tree,
  _Kind.timeline => coui.Timeline,
  _Kind.category => coui.CategoryBreakdown,
  _Kind.trend => coui.TrendChart,
  _Kind.window => coui.WindowPanel,
};
bool _example(Widget w, _Kind kind) => switch (kind) {
  _Kind.basic => w.runtimeType == BasicDefaultExample,
  _Kind.badge =>
    w.runtimeType == DisclosureBadgeDefaultExample ||
        w.runtimeType == DisclosureBadgeCommitmentExample,
  _Kind.choices => w.runtimeType == MultipleChoiceDefaultExample,
  _Kind.header => w.runtimeType == PageHeaderDefaultExample,
  _Kind.sidebar =>
    w.runtimeType == SidebarDefaultExample ||
        w.runtimeType == SidebarTwoPaneExample ||
        w.runtimeType == SidebarCollapsedExample,
  _Kind.tabs =>
    w.runtimeType == TabPaneExample ||
        w.runtimeType == TabPaneEditorStripExample,
  _Kind.tree =>
    w.runtimeType == TreeDefaultExample ||
        w.runtimeType == TreeSelectedExample ||
        w.runtimeType == TreeTrailingExample,
  _Kind.timeline => w.runtimeType == TimelineDefaultExample,
  _Kind.category =>
    w.runtimeType == CategoryBreakdownDefaultExample ||
        w.runtimeType == CategoryBreakdownDonutExample,
  _Kind.trend =>
    w.runtimeType == TrendChartDefaultExample ||
        w.runtimeType == TrendChartBarExample,
  _Kind.window => w.runtimeType == WindowPanelDefaultExample,
};

_Route _locate(
  Element capture,
  Widget registry,
  BoxObservationSourceSpec source,
  _Kind kind,
) {
  if (source != _spec(kind)) {
    throw _changed('closed source tuple/version');
  }
  if (!capture.mounted ||
      !(identical(capture.widget, registry) ||
          (capture.widget.runtimeType == KeyedSubtree &&
              identical((capture.widget as KeyedSubtree).child, registry)))) {
    throw _changed('exact capture construction result');
  }
  final result = _identity(capture, registry);
  final direct = registry.runtimeType == _type(kind);
  if (!direct && !_example(registry, kind)) {
    throw _changed('audited Example or concrete producer');
  }
  var producer = direct ? result : _only(result);
  if (!direct && (kind == _Kind.sidebar || kind == _Kind.window)) {
    _concrete(producer, SizedBox);
    producer = _child(producer, (producer.widget as SizedBox).child);
  }
  _concrete(producer, _type(kind));
  final raw = <Widget>[];
  final omitted = Set<Widget>.identity();
  final witness = <Object?>[];
  var field = _only(producer);
  Element? frame;

  switch (kind) {
    case _Kind.basic:
      final input = producer.widget as coui.Basic;
      raw.addAll([
        ?input.leading,
        ?input.title,
        ?input.subtitle,
        ?input.content,
        ?input.trailing,
        ?input.trailingText,
      ]);
      if (!input.showSubtitle && input.subtitle != null) {
        omitted.add(input.subtitle!);
      }
      witness.addAll([
        input.showSubtitle,
        input.showTrailingIcon,
        input.forceTextStyle,
      ]);
      _concrete(field, Padding);
      var row = _child(field, (field.widget as Padding).child);
      if (input.forceTextStyle) {
        _concrete(row, IntrinsicWidth);
        row = _child(row, (row.widget as IntrinsicWidth).child);
        _concrete(row, IntrinsicHeight);
        row = _child(row, (row.widget as IntrinsicHeight).child);
      }
      _concrete(row, Row);
    case _Kind.badge:
      final input = producer.widget as coui.DisclosureBadge;
      if (input.kind != coui.CoreDisclosureKind.open &&
          input.kind != coui.CoreDisclosureKind.commitment) {
        throw _changed('solid kind; dashed private remains unsupported');
      }
      witness.add(input.kind);
      _concrete(field, DecoratedBox);
      frame = field;
      field = _child(field, (field.widget as DecoratedBox).child);
      _concrete(field, Padding);
      final row = _child(field, (field.widget as Padding).child);
      _concrete(row, Row);
      if ((row.widget as Row).children.length !=
          (input.kind.hasMarker ? 2 : 1)) {
        throw _changed('generated marker and label seats');
      }
    case _Kind.choices:
      final input = producer.widget as coui.MultipleChoice<String>;
      _concrete(field, Wrap);
      if ((field.widget as Wrap).children.length != input.options.length) {
        throw _changed('all current generated options');
      }
      witness.addAll([input.value, ...input.options]);
    case _Kind.header:
      final input = producer.widget as coui.PageHeader;
      raw.addAll([
        ?input.eyebrow,
        input.title,
        ?input.description,
        ...input.actions,
      ]);
      _concrete(field, Column);
      final seats = (field.widget as Column).children;
      if (seats.length !=
          1 +
              (input.eyebrow == null ? 0 : 1) +
              (input.description == null ? 0 : 1)) {
        throw _changed('complete heading seats');
      }
    case _Kind.sidebar:
      final input = producer.widget as coui.Sidebar;
      final panel = <Widget>[
        ?input.header,
        ?input.search,
        ?input.panelTitle,
        ?input.panelAction,
        ?input.footer,
        ?input.help,
        ?input.user,
        ...input.children,
      ];
      final rail = <Widget>[
        ?input.railHeader,
        ...input.railItems,
        ?input.railFooter,
      ];
      raw.addAll([...panel, ...rail]);
      if (!input.type.hasPanel) {
        omitted.addAll(panel);
      }
      if (!input.type.hasRail) {
        omitted.addAll(rail);
      }
      if (input.panelTitle == null && input.panelAction != null) {
        omitted.add(input.panelAction!);
      }
      witness.add(input.type);
      _concrete(field, coui.CoUISemantics);
      final semantics = _only(field);
      _concrete(semantics, Semantics);
      field = _child(semantics, (field.widget as coui.CoUISemantics).child);
      _concrete(field, Shortcuts);
      field = _identity(field, (field.widget as Shortcuts).child);
      _concrete(field, FocusTraversalGroup);
      // FocusTraversalGroup builds its already-mounted Focus wrappers. Their
      // exact public child is the Row constructed by this concrete Sidebar.
      final rowWidget = (field.widget as FocusTraversalGroup).child;
      field = _identity(field, rowWidget);
      _concrete(field, Row);
      if ((field.widget as Row).children.length !=
          (input.type.hasRail ? 1 : 0) + (input.type.hasPanel ? 1 : 0)) {
        throw _changed('current rail/panel operation');
      }
    case _Kind.tabs:
      final input = producer.widget as coui.TabPane;
      raw.addAll([...input.leading, ...input.trailing]);
      for (var i = 0; i < input.tabs.length; i++) {
        final tab = input.tabs[i];
        if (tab.runtimeType != coui.CoreTabItem<Widget>) {
          throw _changed('concrete typed tab record');
        }
        raw.addAll([?tab.leading, ?tab.trailing, ?tab.badge, ?tab.content]);
        if ((input.variant == coui.CoreTabPaneVariant.editorStrip ||
                i != input.selectedIndex) &&
            tab.content != null) {
          omitted.add(tab.content!);
        }
      }
      witness.addAll([input.variant, input.selectedIndex, ...input.tabs]);
      if (input.variant != coui.CoreTabPaneVariant.editorStrip) {
        if (field.widget.runtimeType == coui.SurfaceBlur) {
          field = _identity(field, (field.widget as coui.SurfaceBlur).child);
        }
        _concrete(field, Container);
        field = _child(field, (field.widget as Container).child, direct: false);
        _concrete(field, Column);
        final seats = (field.widget as Column).children;
        final hasContent =
            input.selectedIndex >= 0 &&
            input.selectedIndex < input.tabs.length &&
            input.tabs[input.selectedIndex].content != null;
        if (seats.length != (hasContent ? 2 : 1)) {
          throw _changed('current selected content operation');
        }
        field = _child(field, seats.first);
      }
      if (field.widget.runtimeType == DecoratedBox) {
        field = _child(field, (field.widget as DecoratedBox).child);
      }
      _concrete(field, SizedBox);
      final bar = field;
      field = _child(bar, (bar.widget as SizedBox).child);
      _concrete(field, Padding);
      final row = _child(field, (field.widget as Padding).child);
      _concrete(row, Row);
      if ((row.widget as Row).children.length !=
          input.leading.length + input.trailing.length + 1) {
        throw _changed('bar leading, generated scroll seat and trailing');
      }
      frame = bar;
    case _Kind.tree:
      final input = producer.widget as coui.Tree;
      if (input.leadingBuilder != null ||
          (input.trailingBuilder != null &&
              registry.runtimeType != TreeTrailingExample) ||
          input.loadingBuilder != null ||
          input.errorBuilder != null ||
          input.nodeContextMenu != null ||
          input.loadChildren != null ||
          input.virtualRowHeight != null ||
          input.onNodeDrop != null ||
          input.onNodePlace != null ||
          input.onFilesPlaced != null) {
        throw _changed(
          'closed nonvirtual tree with no Widget/async/drag builders',
        );
      }
      // This is the current outer Column. No inference about private expanded
      // state or initial CoreTreeNode.expanded is needed for its own absence.
      _concrete(field, Column);
      // A trailing callback is authorized only by the exact original Example.
      // These are complete GENERATED row boundaries, not caller Widget slots.
      // No callback is invoked and no private expansion state is inspected.
      final declared = (field.widget as Column).children;
      final children = <Element>[];
      field.visitChildren(children.add);
      if (children.length != declared.length ||
          List.generate(
            declared.length,
            (i) =>
                !identical(children[i].widget, declared[i]) ||
                !identical(_parent(children[i]), field) ||
                !children[i].mounted,
          ).any((bad) => bad)) {
        throw _changed('complete current generated Tree row order');
      }
      witness.addAll([
        input.showRoots,
        input.trailingBuilder,
        ...input.nodes,
        for (var i = 0; i < declared.length; i++) ...[declared[i], children[i]],
      ]);
    case _Kind.timeline:
      final input = producer.widget as coui.Timeline;
      _concrete(field, Column);
      if ((field.widget as Column).children.length != input.items.length) {
        throw _changed('whole generated timeline sequence');
      }
      witness.addAll(input.items);
    case _Kind.category:
      final input = producer.widget as coui.CategoryBreakdown;
      raw.addAll([?input.center, ?input.empty]);
      if (input.empty != null) {
        omitted.add(input.empty!);
      }
      if (input.variant != coui.CoreCategoryBreakdownVariant.donut &&
          input.center != null) {
        omitted.add(input.center!);
      }
      _concrete(
        field,
        Semantics,
      ); // empty/invalid geometry never reaches this operation
      field = _child(field, (field.widget as Semantics).child);
      if (input.variant == coui.CoreCategoryBreakdownVariant.bar) {
        _concrete(field, Column);
        if ((field.widget as Column).children.length != input.items.length) {
          throw _changed('all breakdown rows');
        }
      } else {
        // The concrete producer constructs this child itself; the public
        // Semantics.child identity authenticates the private donut layout.
        final widget = field.widget;
        if (widget is! MultiChildRenderObjectWidget ||
            widget.children.length != 2) {
          throw _changed('current source donut/legend layout construction');
        }
        _concrete(_child(field, widget.children.first), SizedBox);
        _concrete(_child(field, widget.children.last), Column);
      }
      witness.addAll([input.variant, ...input.items]);
    case _Kind.trend:
      final input = producer.widget as coui.TrendChart;
      raw.addAll([?input.summary, ?input.empty]);
      if (input.points.isNotEmpty && input.empty != null) {
        omitted.add(input.empty!);
      }
      _concrete(field, Column);
      final expected =
          (input.summary == null ? 0 : 1) +
          (input.periods.isEmpty ? 0 : 1) +
          (input.points.isEmpty ? (input.empty == null ? 0 : 1) : 1) +
          (input.points.isNotEmpty &&
                  input.referenceValue != null &&
                  input.referenceLabel != null
              ? 1
              : 0);
      if ((field.widget as Column).children.length != expected) {
        throw _changed('complete summary/period/plot/legend seats');
      }
      witness.addAll([
        input.points.isEmpty,
        input.referenceValue,
        input.referenceLabel,
        ...input.points,
        ...input.periods,
      ]);
    case _Kind.window:
      final input = producer.widget as coui.WindowPanel;
      raw.addAll([?input.title, ?input.actions, ?input.child]);
      if (input.isMinimized && input.child != null) {
        omitted.add(input.child!);
      }
      witness.add(input.isMinimized);
      _concrete(field, Semantics);
      field = _child(field, (field.widget as Semantics).child);
      _concrete(field, DecoratedBox);
      field = _child(field, (field.widget as DecoratedBox).child);
      _concrete(field, coui.InsetShadow);
      field = _identity(field, (field.widget as coui.InsetShadow).child);
      _concrete(field, coui.OutlinedContainer);
      final operation = (field.widget as coui.OutlinedContainer).child;
      if (operation?.runtimeType != LayoutBuilder) {
        throw _changed('already executed frame content builder');
      }
      final layout = _identity(field, operation!);
      final column = _only(layout);
      _concrete(column, Column);
      if ((column.widget as Column).children.length !=
          (!input.isMinimized && input.child != null ? 2 : 1)) {
        throw _changed('current title/body operation');
      }
  }
  // Validate ALL original slot identities first, even slots intentionally not
  // rendered in this current source branch. Never hide duplicates by omission.
  final unique = Set<Widget>.identity();
  if (raw.any((w) => !unique.add(w))) {
    throw _changed('unique raw slots before omission');
  }
  final rendered = <Widget>[];
  for (final slot in raw) {
    final matches = boxElements(
      producer,
    ).where((e) => identical(e.widget, slot)).toList();
    if (omitted.contains(slot)) {
      if (matches.isNotEmpty) {
        throw _changed('source-proven unrendered slot');
      }
    } else {
      requireOneBoxOwner(matches, 'complete current raw foreign slot');
      rendered.add(slot);
    }
  }
  final scope = BoxProducerScope(producer: result, suppliedSlots: rendered);
  if (kind == _Kind.window) {
    frame = _outlinedFrame(field, scope);
  }
  scope
    ..requireOwned(producer)
    ..requireOwned(field)
    ..requireOwned(frame ?? field);
  final render = field.renderObject;
  if (render is! RenderBox || !render.attached || !render.hasSize) {
    throw _changed('attached current source renderer');
  }
  return (
    result: result,
    producer: producer,
    field: field,
    frame: frame ?? field,
    scope: scope,
    raw: List.unmodifiable(raw),
    witness: List.unmodifiable(witness),
  );
}

// Same source edges as the existing outlined reader, without reading values.
// The complete supplied LayoutBuilder is foreign to the primitive, so an inner
// body Container cannot become the frame.
Element _outlinedFrame(Element primitive, BoxProducerScope declaringScope) {
  final input = primitive.widget as coui.OutlinedContainer;
  final own = BoxProducerScope(
    producer: primitive,
    suppliedSlots: [?input.child],
  );
  final frames = <Element>[];
  void visit(Element element) {
    if (own.foreignBoundaries.any((e) => identical(e, element))) {
      return;
    }
    if (element.widget.runtimeType == AnimatedContainer) {
      final outer = evaluatedAnimatedContainer(element);
      final child = (outer.widget as Container).child;
      if (child?.runtimeType == AnimatedContainer) {
        final inner = evaluatedAnimatedContainer(
          elementOfDeclaredChild(outer, child!),
        );
        final forwarded = (inner.widget as Container).child;
        if (forwarded is KeyedSubtree &&
            identical(forwarded.child, input.child)) {
          frames.add(outer);
        }
      }
    }
    element.visitChildren(visit);
  }

  visit(primitive);
  final frame = requireOneBoxOwner(frames, 'outlined current outer Container');
  own.requireOwned(frame);
  declaringScope.requireOwned(frame);
  return frame;
}

bool _same(List<Object?> a, List<Object?> b, {bool identity = false}) =>
    a.length == b.length &&
    List.generate(
      a.length,
      (i) => identity ? identical(a[i], b[i]) : a[i] == b[i],
    ).every((v) => v);
Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((e) => identical(e.widget, widget)),
  'unique original Widget identity',
);
List<Element> _children(Element root) {
  final list = <Element>[];
  root.visitChildren(list.add);
  return list;
}

Element _only(Element root) =>
    requireOneBoxOwner(_children(root), 'source direct construction child');
Element _child(Element root, Widget? child, {bool direct = true}) {
  if (child == null) {
    throw _changed('required source child');
  }
  return requireOneBoxOwner(
    (direct ? _children(root) : boxElements(root)).where(
      (e) => identical(e.widget, child),
    ),
    'actual source public child identity',
  );
}

void _concrete(Element element, Type type) =>
    requireConcreteBoxSourceType(element.widget, type);
BoxObservationError _changed(String part) => BoxObservationError(
  'STRUCTURED_ROOT_SOURCE_CHANGED',
  'Unsupported $part; no owner, quantity or absence is inferred.',
);

Element? _parent(Element e) {
  Element? parent;
  e.visitAncestorElements((a) {
    parent = a;
    return false;
  });
  return parent;
}
