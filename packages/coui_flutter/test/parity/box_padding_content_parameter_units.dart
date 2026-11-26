import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/app_bar/app_bar_medium_example.dart';
import 'package:docs_core/previews/examples/flutter/kbd/kbd_single_example.dart';
import 'package:docs_core/previews/examples/flutter/refresh_trigger/refresh_trigger_default_example.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter/widgets.dart'
    show
        Center,
        Column,
        ConstrainedBox,
        Container,
        DecoratedBox,
        Element,
        KeyedSubtree,
        Padding,
        Row,
        Semantics,
        SizedBox,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

const _kKeycap = 'kbd-single-keycap-content-inset';
const _kToolbar = 'app-bar-medium-toolbar-content-inset';
const _kViewport = 'documentation-refresh-viewport-content-inset';

/// References to a declared cap, toolbar or documentation viewport operation.
/// The shared reader owns numeric observation; the legacy root stays separate.
class ContentParameterBoxSourceBinding {
  ContentParameterBoxSourceBinding._(
    this._capture,
    this._resultWidget,
    this._unit,
    this._route,
  ) : _producerWidget = _route.producer.widget;

  final Element _capture;
  final Widget _resultWidget;
  final Widget _producerWidget;
  final String _unit;
  final _Route _route;

  String get authority => _route.authority;
  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.field;
  Element get paddingSource => _route.padding;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get readerId => _route.reader;

  /// Must run synchronously immediately before the coordinator's numeric read.
  /// Inputs stay identical; generated frame Widgets may legitimately rebuild.
  void validateCurrentConstruction() {
    for (final pair in [
      (_route.result, _resultWidget),
      (_route.producer, _producerWidget),
    ]) {
      if (!pair.$1.mounted || !identical(pair.$1.widget, pair.$2)) {
        throw _error('STALE_CONTENT_PARAMETER_CONSTRUCTION');
      }
    }
    final current = _locate(_capture, _resultWidget, _unit);
    if (!identical(current.result, _route.result) ||
        !identical(current.producer, _route.producer) ||
        !identical(current.field, _route.field) ||
        !identical(current.padding, _route.padding) ||
        !identical(current.frame, _route.frame) ||
        current.scope.foreignBoundaries.length !=
            _route.scope.foreignBoundaries.length ||
        current.scope.foreignBoundaries.any(
          (element) => !_route.scope.foreignBoundaries.any(
            (old) => identical(old, element),
          ),
        )) {
      throw _error('CONTENT_PARAMETER_SOURCE_CHANGED');
    }
  }
}

/// Binds only the actual source operation. No resolver or callback is invoked.
ContentParameterBoxSourceBinding? bindContentParameterBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (!const {_kKeycap, _kToolbar, _kViewport}.contains(source.logicalUnitId)) {
    return null;
  }
  if (source.schemaVersion != 1) {
    throw _error('UNSUPPORTED_BOX_SOURCE_VERSION');
  }
  if (source.quantityId != BoxObservationSourceSpec.quantity ||
      source.nativeAdapterId != '${source.logicalUnitId}-v1' ||
      source.webAdapterId != '${source.logicalUnitId}-v1') {
    throw _error('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  }
  return ContentParameterBoxSourceBinding._(
    captureRoot,
    registryResult,
    source.logicalUnitId,
    _locate(captureRoot, registryResult, source.logicalUnitId),
  );
}

typedef _Route = ({
  Element result,
  Element producer,
  Element field,
  Element padding,
  Element frame,
  BoxProducerScope scope,
  String authority,
  String reader,
});

_Route _locate(Element capture, Widget resultWidget, String unit) {
  final wrapper = capture.widget;
  if (!identical(wrapper, resultWidget) &&
      !(wrapper.runtimeType == KeyedSubtree &&
          identical((wrapper as KeyedSubtree).child, resultWidget))) {
    throw _error('MISMATCHED_CONTENT_PARAMETER_RESULT');
  }
  final result = _identity(capture, resultWidget);
  final exampleType = switch (unit) {
    _kKeycap => KbdSingleExample,
    _kToolbar => AppBarMediumExample,
    _ => RefreshTriggerDefaultExample,
  };
  final producerType = switch (unit) {
    _kKeycap => coui.Kbd,
    _kToolbar => coui.AppBar,
    _ => coui.OutlinedContainer,
  };
  final isExample = resultWidget.runtimeType == exampleType;
  // Arbitrary caller Outlined/RefreshTrigger inputs cannot claim docs ownership.
  if (!isExample &&
      (unit == _kViewport || resultWidget.runtimeType != producerType)) {
    throw _error('UNREGISTERED_CONTENT_PARAMETER_CONSTRUCTION');
  }
  final producer = isExample ? _only(result) : result;
  _concrete(producer, producerType);
  if (unit == _kKeycap) {
    final input = producer.widget as coui.Kbd;
    if (input.keys.length != 1 || input.keyContent != null) {
      throw _error('KBD_SINGLE_INPUT_CHANGED');
    }
  }
  if (unit == _kToolbar) {
    final input = producer.widget as coui.AppBar;
    if (input.variant != coui.CoreAppBarVariant.medium) {
      throw _error('APP_BAR_MEDIUM_INPUT_CHANGED');
    }
    // Inspect the raw bag before any source-authorized omission or Set filter.
    final seen = Set<Widget>.identity();
    for (final widget in [
      ?input.title,
      ?input.header,
      ?input.subtitle,
      ?input.child,
      ...input.leading,
      ...input.trailing,
    ]) {
      if (!seen.add(widget)) throw _error('DUPLICATE_OWNER');
    }
  }
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  for (final slot in declaration.scope.suppliedSlots) {
    _identity(producer, slot);
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  if (unit == _kViewport) {
    // Outlined.child is the entire supplied SizedBox/Refresh/scroll body. No
    // indicator, ScrollArea or inner top padding is visited to find an owner.
    return (
      result: result,
      producer: producer,
      field: producer,
      padding: producer,
      frame: producer,
      scope: scope,
      authority:
          'Exact parameterless RefreshTriggerDefaultExample directly owns its '
          'Outlined viewport; Outlined.child is foreign in full. Documentation '
          'viewport inset only, not RefreshTrigger legacy/component-root repair.',
      reader: 'outlined-content-v1',
    );
  }
  final route = unit == _kKeycap ? _keycap(producer) : _toolbar(producer);
  [route.field, route.padding, route.frame].forEach(scope.requireOwned);
  if (route.padding.renderObject is! RenderPadding) {
    throw _error('CONTENT_PARAMETER_RENDER_SOURCE_CHANGED');
  }
  return (
    result: result,
    producer: producer,
    field: route.field,
    padding: route.padding,
    frame: route.frame,
    scope: scope,
    authority:
        'Exact public producer/Example and actual Widget child identities; '
        '${declaration.authority}; ${route.authority}; source parameter only, '
        'not alignment gap, border, title/foreign inset or total root spacing.',
    reader: 'current-render-padding-v1',
  );
}

typedef _Field = ({
  Element field,
  Element padding,
  Element frame,
  String authority,
});

_Field _keycap(Element producer) {
  var row = _only(producer);
  if (row.widget.runtimeType == Semantics) {
    row = _child(row, (row.widget as Semantics).child);
  }
  _concrete(row, Row);
  final caps = (row.widget as Row).children;
  if (caps.length != 1) throw _error('KBD_SINGLE_CAP_CHANGED');
  var cap = _child(row, caps.single);
  _concrete(cap, coui.InjectedCast);
  cap = _child(cap, (cap.widget as coui.InjectedCast).child);
  if (cap.widget.runtimeType == coui.SurfaceBlur) {
    cap = _child(cap, (cap.widget as coui.SurfaceBlur).child);
  }
  _concrete(cap, coui.InsetShadow);
  cap = _child(cap, (cap.widget as coui.InsetShadow).child);
  _concrete(cap, Container);
  final min = _child(cap, (cap.widget as Container).child);
  _concrete(min, ConstrainedBox);
  final center = _child(min, (min.widget as ConstrainedBox).child);
  _concrete(center, Center);
  final padding = _child(center, (center.widget as Center).child);
  _concrete(padding, Padding);
  _concrete(_child(padding, (padding.widget as Padding).child), coui.Text);
  return (
    field: cap,
    padding: padding,
    frame: cap,
    authority:
        'Single public key -> actual Row cap -> InjectedCast/optional '
        'SurfaceBlur/InsetShadow -> Container -> min/Center -> key Padding',
  );
}

_Field _toolbar(Element producer) {
  var frame = _only(producer);
  if (frame.widget.runtimeType == coui.SurfaceBlur) {
    frame = _child(frame, (frame.widget as coui.SurfaceBlur).child);
  }
  // Glass returns SizedBox/Stacks; it has no grant to borrow a decorated child.
  _concrete(frame, DecoratedBox);
  final size = _child(frame, (frame.widget as DecoratedBox).child);
  _concrete(size, SizedBox);
  final column = _child(size, (size.widget as SizedBox).child);
  _concrete(column, Column);
  final children = (column.widget as Column).children;
  if (children.length != 2) throw _error('APP_BAR_MEDIUM_SOURCE_CHANGED');
  final top = _child(column, children[0]);
  _concrete(top, SizedBox);
  final padding = _child(top, (top.widget as SizedBox).child);
  _concrete(padding, Padding);
  _concrete(_child(padding, (padding.widget as Padding).child), Row);
  return (
    field: top,
    padding: padding,
    frame: top,
    authority:
        'Medium solid content Column source child0 is the toolbar SizedBox '
        '-> Padding -> Row; source child1 title and outer divider are separate',
  );
}

Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((element) => identical(element.widget, widget)),
  'the actual declared content-parameter Widget identity',
);

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(
    children,
    'the direct content-parameter build child',
  );
}

Element _child(Element parent, Widget? child) {
  if (child == null) throw _error('MISSING_CONTENT_PARAMETER_CHILD');
  return _identity(parent, child);
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _error('CONTENT_PARAMETER_SOURCE_CHANGED');
  }
}

BoxObservationError _error(String code) => BoxObservationError(
  code,
  'The closed content-parameter construction is incomplete; no value inferred.',
);
