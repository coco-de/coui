import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/join/join_default_example.dart';
import 'package:docs_core/previews/examples/flutter/join/join_input_example.dart';
import 'package:docs_core/previews/examples/flutter/join/join_vertical_example.dart';
import 'package:docs_core/previews/examples/flutter/mockup/mockup_app_example.dart';
import 'package:docs_core/previews/examples/flutter/mockup/mockup_browser_example.dart';
import 'package:docs_core/previews/examples/flutter/mockup/mockup_device_example.dart';
import 'package:docs_core/previews/examples/flutter/mockup/mockup_device_flat_example.dart';
import 'package:docs_core/previews/examples/flutter/mockup/mockup_device_landscape_example.dart';
import 'package:docs_core/previews/examples/flutter/mockup/mockup_device_tablet_example.dart';
import 'package:docs_core/previews/examples/flutter/table/table_default_example.dart';
import 'package:docs_core/previews/examples/flutter/table/table_resizable_example.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show
        Align,
        AnimatedContainer,
        Border,
        BorderStyle,
        BoxDecoration,
        ClipRRect,
        Container,
        DecoratedBox,
        DefaultTextStyle,
        Directionality,
        EdgeInsets,
        Element,
        Flex,
        Focus,
        IgnorePointer,
        IndexedSlot,
        IntrinsicHeight,
        IntrinsicWidth,
        KeyedSubtree,
        ListenableBuilder,
        Padding,
        SafeArea,
        Semantics,
        SingleChildRenderObjectWidget,
        SizedBox,
        StatefulElement,
        StatefulWidget,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

enum _Kind { device, join, table, browser }

typedef _Route = ({
  Element result,
  Element producer,
  Element field,
  Element padding,
  Element frame,
  Element? outlined,
  BoxProducerScope scope,
  List<Widget?> raw,
  List<Object?> identities,
  List<Object?> operations,
});

/// Current public construction references; no callbacks or resolvers are run.
class FramedCollectionBoxSourceBinding {
  FramedCollectionBoxSourceBinding._(
    this._capture,
    this._registry,
    this._kind,
    this._route,
  ) : _producerWidget = _route.producer.widget;

  final Element _capture;
  final Widget _registry;
  final Widget _producerWidget;
  final _Kind _kind;
  final _Route _route;

  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.field;
  Element get paddingSource => _route.padding;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get authority =>
      'Exact public ${_kind.name} producer and audited construction; '
      'complete ordered raw slots precede omission; current declared '
      'Widget identities and all opaque foreign boundaries; no replay';
  String get readerId => switch (_kind) {
    _Kind.device || _Kind.join => 'framed-collection-declared-absence-v1',
    _Kind.table => 'framed-table-border-content-v1',
    _Kind.browser => 'outlined-content-v1',
  };

  void validateExistingCurrentBinding() {
    if (!_capture.mounted ||
        !_route.producer.mounted ||
        !identical(_route.result.widget, _registry) ||
        !identical(_route.producer.widget, _producerWidget)) {
      throw _changed('held registry or public producer identity');
    }
    final now = _locate(_capture, _registry, _kind);
    if (!identical(now.result, _route.result) ||
        !identical(now.producer, _route.producer) ||
        !identical(now.field, _route.field) ||
        !identical(now.padding, _route.padding) ||
        !identical(now.frame, _route.frame) ||
        !identical(now.outlined, _route.outlined) ||
        !_same(now.raw, _route.raw, identity: true) ||
        !_same(now.identities, _route.identities, identity: true) ||
        !_same(now.operations, _route.operations) ||
        !_same(
          now.scope.foreignBoundaries,
          scope.foreignBoundaries,
          identity: true,
        )) {
      throw _changed('held current operation, complete records or frame');
    }
  }

  BoxPaddingObservation readDeclaredAbsence() {
    validateExistingCurrentBinding();
    if (_kind != _Kind.device && _kind != _Kind.join) {
      throw _changed('absence for a parameter-bearing frame');
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

  BoxPaddingObservation readActualPadding() {
    validateExistingCurrentBinding();
    if (_kind == _Kind.browser) {
      final observed = observeOutlinedContainerContentPadding(
        primitive: _route.outlined!,
        declaringScope: scope,
      );
      if (!identical(observed.owner, paddingSource) ||
          !identical(observed.frameOwner, frameSource)) {
        throw _changed('existing shared surface reader owner/frame');
      }
      return observed;
    }
    if (_kind != _Kind.table) {
      throw _changed('a parameter read for an independently unpadded frame');
    }
    final decorated = frameSource.renderObject;
    final padded = paddingSource.renderObject;
    if (decorated is! RenderDecoratedBox ||
        padded is! RenderPadding ||
        decorated.decoration is! BoxDecoration) {
      throw _changed('actual table decoration and direct RenderPadding');
    }
    final decoration = decorated.decoration as BoxDecoration;
    final border = decoration.border;
    if (border != null &&
        (border is! Border ||
            !border.isUniform ||
            border.top.style != BorderStyle.solid)) {
      throw _changed('the table source uniform solid border or absent border');
    }
    final direction = Directionality.of(paddingSource);
    final actual = padded.padding.resolve(direction);
    // table.dart / resizable_table.dart reserve the same painted border in
    // this direct Padding. Null is the actual no-painted-border branch.
    final allocated = border?.dimensions.resolve(direction) ?? EdgeInsets.zero;
    final value = actual - allocated;
    if ([value.left, value.top, value.right, value.bottom].any(
      (v) => !v.isFinite || v < 0,
    )) {
      throw _changed('nonnegative content inset after actual border reserve');
    }
    return BoxPaddingObservation(
      value: value,
      quantity: PaddingQuantityKind.declaredOuterEdgeInsetWithinBorder,
      owner: paddingSource,
      producer: registryResultElement,
      contentBoundary: _declared(
        paddingSource,
        (paddingSource.widget as Padding).child,
        scope,
      ),
      paddingElement: paddingSource,
      currentRenderPadding: actual,
      allocatedDecorationInsets: allocated,
      excludedMargin: EdgeInsets.zero,
      generatedSlots: [
        {
          'sourceContract': readerId,
          'authority': authority,
          'allocation': 'same current painted border reserved once',
        },
      ],
      frameOwner: frameSource,
    );
  }
}

FramedCollectionBoxSourceBinding? bindFramedCollectionBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  final selected = switch (source.logicalUnitId) {
    'mockup-device-generated-body-frame-content-inset' => (
      _Kind.device,
      BoxObservationSourceSpec.mockupDeviceBodyFrame,
    ),
    'join-generated-strip-layout-host' => (
      _Kind.join,
      BoxObservationSourceSpec.joinStripLayoutHost,
    ),
    'table-generated-grid-content-inset' => (
      _Kind.table,
      BoxObservationSourceSpec.tableGridContentInset,
    ),
    'mockup-browser-generated-frame' => (
      _Kind.browser,
      BoxObservationSourceSpec.mockupBrowserFrame,
    ),
    _ => null,
  };
  if (selected == null) return null;
  final (kind, spec) = selected;
  if (source.schemaVersion != spec.schemaVersion ||
      source.quantityId != spec.quantityId ||
      source.nativeAdapterId != spec.nativeAdapterId ||
      source.webAdapterId != spec.webAdapterId) {
    throw _changed('closed source tuple and both adapters');
  }
  // Both existing default and classic browser recipes construct this same
  // Example. Its already-audited sibling path stays with the existing binder.
  if (kind == _Kind.browser &&
      registryResult.runtimeType == MockupBrowserExample) {
    return null;
  }
  return FramedCollectionBoxSourceBinding._(
    captureRoot,
    registryResult,
    kind,
    _locate(captureRoot, registryResult, kind),
  );
}

_Route _locate(Element capture, Widget registry, _Kind kind) {
  if (!identical(capture.widget, registry) &&
      !(capture.widget is KeyedSubtree &&
          identical((capture.widget as KeyedSubtree).child, registry))) {
    throw _changed('actual capture construction result');
  }
  final result = requireOneBoxOwner(
    boxElements(capture).where((e) => identical(e.widget, registry)),
    'exact mounted registry Widget',
  );
  var producer = result;
  if (!_publicProducer(registry, kind)) {
    if (!_example(registry, kind)) throw _changed('unregistered construction');
    producer = _only(result);
    if (!_publicProducer(producer.widget, kind)) {
      throw _changed('audited example direct concrete producer');
    }
  }
  final raw = <Widget?>[];
  final identities = <Object?>[];
  final operations = <Object?>[];
  final w = producer.widget;
  switch (kind) {
    case _Kind.device:
      final input = w as coui.MockupDevice;
      raw.add(input.child);
      operations.addAll([
        input.device,
        input.orientation,
        input.finish,
        input.screenBrightness,
        input.showCamera,
        input.showStatusBar,
        input.showGestureBar,
      ]);
    case _Kind.join:
      final input = w as coui.Join;
      raw.addAll(input.children);
      operations.add(input.vertical);
    case _Kind.browser:
      final input = w as coui.MockupBrowser;
      raw.add(input.child);
      operations.addAll([input.showControls, input.addressBar]);
    case _Kind.table:
      final rows = w is coui.Table ? w.rows : (w as coui.ResizableTable).rows;
      identities.add(rows);
      for (final row in rows) {
        if (row.runtimeType != (coui.CoreTableRowData<Widget>)) {
          throw _changed('concrete generic table row record');
        }
        identities.addAll([row, row.cells]);
        operations.addAll([row.kind, row.selected, row.cells.length]);
        for (final cell in row.cells) {
          if (cell.runtimeType != (coui.CoreTableCellData<Widget>)) {
            throw _changed('concrete generic table cell record');
          }
          identities.addAll([cell, cell.onPressed]);
          operations.addAll([
            cell.columnSpan,
            cell.rowSpan,
            cell.enabled,
            cell.selected,
            cell.columnHover,
            cell.rowHover,
          ]);
          raw.add(cell.child);
        }
      }
      if (w is coui.ResizableTable) {
        identities.add(w.controller);
        operations.addAll([w.columnResizeMode, w.rowResizeMode]);
      }
  }
  _unique(raw);
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: raw.whereType<Widget>(),
  )..requireOwned(producer);
  if (scope.foreignBoundaries.length != raw.whereType<Widget>().length) {
    throw _changed('one whole mounted boundary for every raw Widget');
  }
  late Element field;
  late Element padding;
  late Element frame;
  Element? outlined;
  switch (kind) {
    case _Kind.device:
      final input = w as coui.MockupDevice;
      final align = _only(producer);
      _concrete(align, Align);
      field = _declared(align, (align.widget as Align).child, scope);
      _concrete(field, SizedBox);
      final stack = _declared(field, (field.widget as SizedBox).child, scope);
      _concrete(stack, coui.Stacks);
      final seat = requireOneBoxOwner(
        _ownedElements(stack, scope).where(
          (e) =>
              e.widget.runtimeType == SafeArea &&
              identical((e.widget as SafeArea).child, input.child),
        ),
        'source screen SafeArea forwarding the entire device child',
      );
      final forwarded = elementOfDeclaredChild(seat, input.child);
      _boundary(scope, forwarded, input.child);
      if (field.renderObject is! RenderConstrainedBox) {
        throw _changed('independent device SizedBox renderer');
      }
      padding = field;
      frame = field;
    case _Kind.join:
      final input = w as coui.Join;
      if (raw.isEmpty) throw _changed('empty Join has no intrinsic strip');
      final bridge = _only(producer);
      _statefulBridge(bridge);
      field = _only(bridge);
      final Widget? stripWidget;
      if (input.vertical) {
        _concrete(field, IntrinsicWidth);
        stripWidget = (field.widget as IntrinsicWidth).child;
      } else {
        _concrete(field, IntrinsicHeight);
        stripWidget = (field.widget as IntrinsicHeight).child;
      }
      final overlap = _declared(field, stripWidget, scope);
      if (overlap.widget is! SingleChildRenderObjectWidget) {
        throw _changed('source overlap public single-child renderer bridge');
      }
      final flex = _declared(
        overlap,
        (overlap.widget as SingleChildRenderObjectWidget).child,
        scope,
      );
      if (flex.widget is! Flex ||
          (flex.widget as Flex).direction !=
              (input.vertical ? Axis.vertical : Axis.horizontal)) {
        throw _changed('current Join public Flex axis');
      }
      final seats = _indexed(flex, (flex.widget as Flex).children);
      if (seats.length != raw.length) throw _changed('all Join item seats');
      for (var i = 0; i < seats.length; i++) {
        _statefulBridge(seats[i]);
        final focus = _only(seats[i]);
        _concrete(focus, Focus);
        final data = _declared(focus, (focus.widget as Focus).child, scope);
        if (data.widget is! coui.Data<coui.JoinItemData>) {
          throw _changed('public JoinItemData forwarding wrapper');
        }
        final clip = _declared(
          data,
          (data.widget as coui.Data<coui.JoinItemData>).child,
          scope,
        );
        _concrete(clip, ClipRRect);
        final clipping = clip.widget as ClipRRect;
        if (clipping.clipBehavior != Clip.none &&
            clipping.clipBehavior != Clip.antiAlias) {
          throw _changed('current focus clip branch');
        }
        if (!identical(clipping.child, raw[i])) {
          throw _changed('whole Join original item at each indexed seat');
        }
        _boundary(scope, elementOfDeclaredChild(clip, raw[i]!), raw[i]!);
      }
      padding = field;
      frame = field;
    case _Kind.table:
      final resizable = w is coui.ResizableTable;
      var current = _only(producer);
      if (w is coui.ResizableTable) {
        _concrete(current, ListenableBuilder);
        if (!identical(
          (current.widget as ListenableBuilder).listenable,
          w.controller,
        )) {
          throw _changed('actual public resizable controller identity');
        }
        current = _only(current);
      }
      _concrete(current, coui.InjectedCast);
      current = _declared(
        current,
        (current.widget as coui.InjectedCast).child,
        scope,
      );
      if (current.widget.runtimeType == coui.SurfaceBlur) {
        current = _declared(
          current,
          (current.widget as coui.SurfaceBlur).child,
          scope,
        );
      }
      _concrete(current, DecoratedBox);
      field = current;
      frame = current;
      padding = _declared(
        current,
        (current.widget as DecoratedBox).child,
        scope,
      );
      _concrete(padding, Padding);
      final clip = _declared(padding, (padding.widget as Padding).child, scope);
      _concrete(clip, ClipRRect);
      var layout = _declared(clip, (clip.widget as ClipRRect).child, scope);
      if (!resizable) {
        _concrete(layout, SizedBox);
        layout = _declared(layout, (layout.widget as SizedBox).child, scope);
      }
      _concrete(layout, coui.TableLayoutWidget);
      final cells = _indexed(
        layout,
        (layout.widget as coui.TableLayoutWidget).children,
      );
      if (cells.length != raw.length) throw _changed('all table layout cells');
      final rows = w is coui.Table ? w.rows : (w as coui.ResizableTable).rows;
      var offset = 0;
      for (var r = 0; r < rows.length; r++) {
        var column = 0;
        for (final cell in rows[r].cells) {
          final seat = cells[offset];
          _concrete(seat, coui.TableLayoutCell);
          final input = seat.widget as coui.TableLayoutCell;
          if (input.row != r ||
              input.column != column ||
              input.columnSpan != cell.columnSpan ||
              input.rowSpan != cell.rowSpan ||
              !input.computeSize) {
            throw _changed('current row/cell coordinates and spans');
          }
          final semantics = _declared(seat, input.child, scope);
          _concrete(semantics, Semantics);
          final semanticInput = semantics.widget as Semantics;
          if (!semanticInput.container ||
              semanticInput.properties.role !=
                  (rows[r].kind == coui.CoreTableRowKind.header
                      ? SemanticsRole.columnHeader
                      : SemanticsRole.cell)) {
            throw _changed('current row-kind cell semantic boundary');
          }
          final boundaries = scope.foreignBoundaries.where(
            (e) => BoxProducerScope.contains(semantics, e),
          );
          _boundary(
            scope,
            requireOneBoxOwner(boundaries, 'whole current cell content'),
            cell.child,
          );
          column += cell.columnSpan;
          offset++;
        }
      }
    case _Kind.browser:
      outlined = _only(producer);
      _concrete(outlined, coui.OutlinedContainer);
      final declared = (outlined.widget as coui.OutlinedContainer).child;
      final stack = _declared(outlined, declared, scope);
      _concrete(stack, coui.Stacks);
      final parts = (stack.widget as coui.Stacks).children;
      if (parts.length != 3 ||
          parts[0].runtimeType != Container ||
          parts[1].runtimeType != coui.Position ||
          parts[2].runtimeType != coui.Position) {
        throw _changed('complete browser content, toolbar and highlight seats');
      }
      for (final part in parts) {
        _declared(stack, part, scope);
      }
      final content = _declared(stack, parts[0], scope);
      final contentPadding = _declared(
        content,
        (content.widget as Container).child,
        scope,
      );
      _concrete(contentPadding, Padding);
      final contentStyle = _declared(
        contentPadding,
        (contentPadding.widget as Padding).child,
        scope,
      );
      _concrete(contentStyle, DefaultTextStyle);
      final original = (w as coui.MockupBrowser).child;
      final actualContent = (contentStyle.widget as DefaultTextStyle).child;
      if (original == null) {
        if (actualContent.runtimeType != SizedBox ||
            (actualContent as SizedBox).child != null) {
          throw _changed('source-generated empty browser content seat');
        }
      } else {
        if (!identical(actualContent, original)) {
          throw _changed('the whole current browser nullable content slot');
        }
        _boundary(
          scope,
          elementOfDeclaredChild(contentStyle, original),
          original,
        );
      }
      final toolbar = _declared(stack, parts[1], scope);
      final toolbarClip = _declared(
        toolbar,
        (toolbar.widget as coui.Position).child,
        scope,
      );
      _concrete(toolbarClip, ClipRRect);
      final highlight = _declared(stack, parts[2], scope);
      final ignored = _declared(
        highlight,
        (highlight.widget as coui.Position).child,
        scope,
      );
      _concrete(ignored, IgnorePointer);
      final shadow = _declared(
        ignored,
        (ignored.widget as IgnorePointer).child,
        scope,
      );
      _concrete(shadow, coui.InsetShadow);
      final highlighted = _declared(
        shadow,
        (shadow.widget as coui.InsetShadow).child,
        scope,
      );
      _concrete(highlighted, DecoratedBox);
      if ((highlighted.widget as DecoratedBox).child != null) {
        throw _changed('childless generated browser highlight decoration');
      }
      final frames = <Element, Element>{};
      for (final animation in _ownedElements(outlined, scope)) {
        if (animation.widget.runtimeType != AnimatedContainer) continue;
        final outer = evaluatedAnimatedContainer(animation);
        final innerWidget = (outer.widget as Container).child;
        if (innerWidget?.runtimeType != AnimatedContainer) continue;
        final innerAnimation = _declared(outer, innerWidget, scope);
        final inner = evaluatedAnimatedContainer(innerAnimation);
        final keyed = (inner.widget as Container).child;
        if (keyed is KeyedSubtree && identical(keyed.child, declared)) {
          frames[inner] = outer;
        }
      }
      field = producer;
      padding = requireOneBoxOwner(
        frames.keys,
        'shared surface current inner content Container',
      );
      frame = frames[padding]!;
  }
  for (final owner in [field, padding, frame]) {
    scope.requireOwned(owner);
    final render = owner.renderObject;
    if (render is! RenderBox || !render.attached || !render.hasSize) {
      throw _changed('mounted independently rendered owner/frame');
    }
  }
  return (
    result: result,
    producer: producer,
    field: field,
    padding: padding,
    frame: frame,
    outlined: outlined,
    scope: scope,
    raw: List.unmodifiable(raw),
    identities: List.unmodifiable(identities),
    operations: List.unmodifiable(operations),
  );
}

bool _publicProducer(Widget w, _Kind kind) => switch (kind) {
  _Kind.device => w.runtimeType == coui.MockupDevice,
  _Kind.join => w.runtimeType == coui.Join,
  _Kind.table =>
    w.runtimeType == coui.Table || w.runtimeType == coui.ResizableTable,
  _Kind.browser => w.runtimeType == coui.MockupBrowser,
};
bool _example(Widget w, _Kind kind) => switch (kind) {
  _Kind.device =>
    w.runtimeType == MockupDeviceExample ||
        w.runtimeType == MockupDeviceTabletExample ||
        w.runtimeType == MockupDeviceLandscapeExample ||
        w.runtimeType == MockupDeviceFlatExample,
  _Kind.join =>
    w.runtimeType == JoinDefaultExample ||
        w.runtimeType == JoinInputExample ||
        w.runtimeType == JoinVerticalExample,
  _Kind.table =>
    w.runtimeType == TableDefaultExample ||
        w.runtimeType == TableResizableExample,
  _Kind.browser => w.runtimeType == MockupAppExample,
};

List<Element> _children(Element element) {
  final result = <Element>[];
  element.visitChildElements(result.add);
  return result;
}

Element _only(Element element) => requireOneBoxOwner(
  _children(element),
  'single source-generated construction edge',
);
Iterable<Element> _ownedElements(Element root, BoxProducerScope scope) sync* {
  if (scope.foreignBoundaries.any((e) => identical(e, root))) return;
  yield root;
  for (final child in _children(root)) {
    yield* _ownedElements(child, scope);
  }
}

Element _declared(Element root, Widget? child, BoxProducerScope scope) {
  if (child == null) throw _changed('missing declared public child');
  final element = requireOneBoxOwner(
    _ownedElements(root, scope).where((e) => identical(e.widget, child)),
    'actual declared public child identity before opaque foreign content',
  );
  scope.requireOwned(element);
  return element;
}

void _concrete(Element element, Type type) =>
    requireConcreteBoxSourceType(element.widget, type);
void _statefulBridge(Element element) {
  if (element is! StatefulElement || element.widget is! StatefulWidget) {
    throw _changed('current source-owned opaque StatefulElement bridge');
  }
}

void _unique(List<Widget?> raw) {
  final seen = Set<Widget>.identity();
  for (final child in raw) {
    if (child != null && !seen.add(child)) {
      throw _changed('duplicate original raw supplied Widget before omission');
    }
  }
}

void _boundary(BoxProducerScope scope, Element element, Widget original) {
  if (!identical(element.widget, original) ||
      !scope.foreignBoundaries.any((e) => identical(e, element))) {
    throw _changed('exact entire original opaque supplied boundary');
  }
}

List<Element> _indexed(Element owner, List<Widget> declared) {
  final byIndex = <int, Element>{};
  for (final child in _children(owner)) {
    final slot = child.slot;
    if (slot is! IndexedSlot<Element?> ||
        slot.index < 0 ||
        slot.index >= declared.length ||
        byIndex.containsKey(slot.index) ||
        !identical(child.widget, declared[slot.index])) {
      throw _changed('complete public IndexedSlot index/Widget bijection');
    }
    byIndex[slot.index] = child;
  }
  if (byIndex.length != declared.length) throw _changed('all indexed seats');
  final ordered = [for (var i = 0; i < declared.length; i++) byIndex[i]!];
  for (var i = 0; i < ordered.length; i++) {
    final slot = ordered[i].slot! as IndexedSlot<Element?>;
    if (!identical(slot.value, i == 0 ? null : ordered[i - 1])) {
      throw _changed('source indexed predecessor chain');
    }
  }
  return ordered;
}

bool _same(List<Object?> a, List<Object?> b, {bool identity = false}) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (identity ? !identical(a[i], b[i]) : a[i] != b[i]) return false;
  }
  return true;
}

BoxObservationError _changed(String part) => BoxObservationError(
  'FRAMED_COLLECTION_SOURCE_CHANGED',
  'Unsupported $part; no fallback owner or quantity is inferred.',
);
