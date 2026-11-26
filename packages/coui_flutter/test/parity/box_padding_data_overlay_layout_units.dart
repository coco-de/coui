import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/bottom_sheet/bottom_sheet_close_example.dart';
import 'package:docs_core/previews/examples/flutter/bottom_sheet/bottom_sheet_default_example.dart';
import 'package:docs_core/previews/examples/flutter/diff/diff_default_example.dart';
import 'package:docs_core/previews/examples/flutter/diff/diff_text_example.dart';
import 'package:docs_core/previews/examples/flutter/swiper/swiper_default_example.dart';
import 'package:docs_core/previews/examples/flutter/swiper/swiper_sheet_example.dart';
import 'package:docs_core/previews/examples/flutter/theme_controller/theme_controller_default_example.dart';
import 'package:docs_core/previews/examples/flutter/tracker/tracker_default_example.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show
        Center,
        ClipRRect,
        ClipRect,
        Column,
        ConstrainedBox,
        DecoratedBox,
        DefaultTextStyle,
        EdgeInsets,
        Element,
        Expanded,
        Flexible,
        FocusableActionDetector,
        GestureDetector,
        IgnorePointer,
        KeyedSubtree,
        Listener,
        MouseRegion,
        Padding,
        Row,
        Semantics,
        SizedBox,
        StatefulWidget,
        Widget,
        Wrap;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

enum _Kind { themes, tracker, sheet, swiper, diff }

typedef _Route = ({
  Element result,
  Element producer,
  Element field,
  Element frame,
  BoxProducerScope scope,
  List<Widget> raw,
  List<Widget> outsideTrigger,
  List<Object?> witness,
});

/// Binds one existing public construction and its actual current operation.
class DataOverlayLayoutBoxSourceBinding {
  DataOverlayLayoutBoxSourceBinding._(
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
  List<Widget> get allOriginalSuppliedSlots => _route.raw;
  List<Widget> get sourceProvenOutsideTriggerSlots => _route.outsideTrigger;
  String get readerId => 'data-overlay-layout-declared-absence-v1';
  String get authority =>
      'Concrete ${_kind.name} public construction and actual current source '
      'operation; complete original foreign slots before omission; '
      'real owned frame, no root padding allocation. Swiper overlayContent '
      'is outside its trigger build in every state, never inferred closed.';

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
        !_same(now.outsideTrigger, _route.outsideTrigger, identity: true) ||
        !_same(now.witness, _route.witness) ||
        !_same(
          now.scope.foreignBoundaries,
          scope.foreignBoundaries,
          identity: true,
        )) {
      throw _changed('held current operation, public inputs or foreign scope');
    }
  }

  BoxPaddingObservation readActualPadding() =>
      throw _changed('a parameter reader for this declared layout absence');

  BoxPaddingObservation readDeclaredAbsence() {
    validateExistingCurrentBinding();
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
        {
          'sourceContract': readerId,
          'authority': authority,
          'outsideTriggerSlots': _route.outsideTrigger.length,
        },
      ],
      frameOwner: frameSource,
    );
  }
}

DataOverlayLayoutBoxSourceBinding? bindDataOverlayLayoutBoxSource({
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
  return DataOverlayLayoutBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    kind,
    _locate(captureRoot, registryResult, source, kind),
  );
}

BoxObservationSourceSpec _spec(_Kind kind) => switch (kind) {
  _Kind.themes => BoxObservationSourceSpec.themeControllerOptionGridLayoutHost,
  _Kind.tracker => BoxObservationSourceSpec.trackerSegmentRowLayoutHost,
  _Kind.sheet => BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
  _Kind.swiper => BoxObservationSourceSpec.swiperTriggerLayoutHost,
  _Kind.diff => BoxObservationSourceSpec.diffViewerLayoutHost,
};
Type _type(_Kind kind) => switch (kind) {
  _Kind.themes => coui.ThemeController,
  _Kind.tracker => coui.Tracker,
  _Kind.sheet => coui.BottomSheet,
  _Kind.swiper => coui.Swiper,
  _Kind.diff => coui.Diff,
};
bool _example(Widget w, _Kind kind) => switch (kind) {
  _Kind.themes => w.runtimeType == ThemeControllerDefaultExample,
  _Kind.tracker => w.runtimeType == TrackerDefaultExample,
  _Kind.sheet =>
    w.runtimeType == BottomSheetDefaultExample ||
        w.runtimeType == BottomSheetCloseExample,
  _Kind.swiper =>
    w.runtimeType == SwiperDefaultExample ||
        w.runtimeType == SwiperSheetExample,
  _Kind.diff =>
    w.runtimeType == DiffDefaultExample || w.runtimeType == DiffTextExample,
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
    throw _changed('exact current capture construction result');
  }
  final result = _identity(capture, registry);
  final direct = registry.runtimeType == _type(kind);
  if (!direct && !_example(registry, kind)) {
    throw _changed('audited Example or concrete producer');
  }
  final producer = direct ? result : _only(result);
  _concrete(producer, _type(kind));

  // All original references are validated BEFORE any branch or omission.
  final raw = <Widget>[];
  switch (kind) {
    case _Kind.sheet:
      final input = producer.widget as coui.BottomSheet;
      raw.addAll([
        input.title,
        ?input.description,
        ?input.content,
        ?input.footer,
      ]);
    case _Kind.swiper:
      final input = producer.widget as coui.Swiper;
      raw.addAll([input.child, input.overlayContent]);
    case _Kind.diff:
      final input = producer.widget as coui.Diff;
      raw.addAll([
        input.before,
        input.after,
        ?input.beforeLabel,
        ?input.afterLabel,
      ]);
    case _Kind.themes:
    case _Kind.tracker:
      // These concrete data producers have no public Widget slots. Their
      // option/segment lists are checked below, not assumed to be Widget-free.
      break;
  }
  final unique = Set<Widget>.identity();
  if (raw.any((w) => !unique.add(w))) {
    throw _changed('unique raw slots before omission');
  }
  final outside = <Widget>[];
  final rendered = <Widget>[];
  for (final slot in raw) {
    final matches = boxElements(
      producer,
    ).where((e) => identical(e.widget, slot)).toList();
    if (kind == _Kind.swiper &&
        identical(slot, (producer.widget as coui.Swiper).overlayContent)) {
      // swiper.dart build always returns Semantics -> Listener -> child.
      // Its separate overlay host never enters this trigger subtree, even
      // while open/dragging. This is a source edge, not an initial-state guess.
      if (matches.isNotEmpty) {
        throw _changed('overlay content outside trigger construction');
      }
      outside.add(slot);
    } else {
      requireOneBoxOwner(matches, 'complete current original foreign slot');
      rendered.add(slot);
    }
  }
  final scope = BoxProducerScope(producer: result, suppliedSlots: rendered);
  final witness = <Object?>[];
  var field = _only(producer);
  var frame = field;

  switch (kind) {
    case _Kind.themes:
      final input = producer.widget as coui.ThemeController;
      for (final option in input.themes) {
        if (option.runtimeType != coui.CoreThemeOption) {
          throw _changed('concrete theme option data');
        }
      }
      _concrete(field, Wrap);
      final seats = (field.widget as Wrap).children;
      if (seats.length != input.themes.length ||
          seats.any((w) => w.runtimeType != ConstrainedBox)) {
        throw _changed('complete current option-grid construction');
      }
      witness.addAll([
        input.selectedTheme,
        input.enabled,
        ...input.themes,
        ...seats,
      ]);
    case _Kind.tracker:
      final input = producer.widget as coui.Tracker;
      for (final segment in input.segments) {
        if (segment.runtimeType != coui.CoreTrackerSegment) {
          throw _changed('concrete tracker segment data');
        }
      }
      _concrete(field, Semantics);
      frame = field;
      field = _child(field, (field.widget as Semantics).child);
      _concrete(field, Row);
      final seats = (field.widget as Row).children;
      if (seats.length != input.segments.length ||
          seats.any((w) => w.runtimeType != Expanded)) {
        throw _changed('complete current segment-row construction');
      }
      witness.addAll([input.rounded, ...input.segments, ...seats]);
    case _Kind.sheet:
      final input = producer.widget as coui.BottomSheet;
      _concrete(field, coui.CoUISemantics);
      final semantic = _only(field);
      _concrete(semantic, Semantics);
      final constrained = _child(
        semantic,
        (semantic.widget as Semantics).child,
      );
      _concrete(constrained, ConstrainedBox);
      var surface = _child(
        constrained,
        (constrained.widget as ConstrainedBox).child,
      );
      if (surface.widget.runtimeType == coui.SurfaceBlur) {
        surface = _identity(
          surface,
          (surface.widget as coui.SurfaceBlur).child,
        );
      }
      _concrete(surface, DecoratedBox);
      field = frame = surface;
      final column = _child(surface, (surface.widget as DecoratedBox).child);
      _concrete(column, Column);
      final seats = (column.widget as Column).children;
      final hasBody = input.content != null || input.footer != null;
      if (seats.length !=
          1 +
              (input.showHandle ? 1 : 0) +
              (input.showDivider ? 1 : 0) +
              (hasBody ? 1 : 0)) {
        throw _changed('complete sheet outer operation');
      }
      var index = 0;
      if (input.showHandle) {
        final handle = _child(column, seats[index++]);
        _concrete(handle, Padding);
        final center = _child(handle, (handle.widget as Padding).child);
        _concrete(center, Center);
        final decoration = _child(center, (center.widget as Center).child);
        _concrete(decoration, DecoratedBox);
        _concrete(
          _child(decoration, (decoration.widget as DecoratedBox).child),
          SizedBox,
        );
      }
      final header = _child(column, seats[index++]);
      _concrete(header, Padding);
      final heading = _child(header, (header.widget as Padding).child);
      _concrete(heading, Column);
      final headerSeats = (heading.widget as Column).children;
      if (headerSeats.length != (input.description == null ? 1 : 3)) {
        throw _changed('current description branch');
      }
      final titleRow = _child(heading, headerSeats.first);
      _concrete(titleRow, Row);
      final titleSeats = (titleRow.widget as Row).children;
      if (titleSeats.length != (input.showCloseButton ? 2 : 1)) {
        throw _changed('current close-button branch');
      }
      final expanded = _child(titleRow, titleSeats.first);
      _concrete(expanded, Expanded);
      final titleStyle = _child(expanded, (expanded.widget as Expanded).child);
      _concrete(titleStyle, DefaultTextStyle);
      _child(titleStyle, input.title);
      if (input.description case final description?) {
        _identity(heading, description);
      }
      if (input.showDivider) {
        _concrete(_child(column, seats[index++]), coui.Divider);
      }
      if (hasBody) {
        var body = _child(column, seats[index]);
        final scrolls = body.widget.runtimeType == Flexible;
        if (scrolls) {
          body = _child(body, (body.widget as Flexible).child);
        }
        if (body.widget is! StatefulWidget) {
          throw _changed('already mounted sheet-body operation');
        }
        final bodyColumn = _only(body);
        _concrete(bodyColumn, Column);
        if ((bodyColumn.widget as Column).children.length !=
            (input.content == null ? 0 : 1) + (input.footer == null ? 0 : 1)) {
          throw _changed('complete sheet content/footer operation');
        }
        if (input.content case final content?) {
          _identity(bodyColumn, content);
        }
        if (input.footer case final footer?) {
          _identity(bodyColumn, footer);
        }
        witness.addAll([scrolls, ...(bodyColumn.widget as Column).children]);
      }
      witness.addAll([
        input.showHandle,
        input.showCloseButton,
        input.showDivider,
        ...seats,
        ...headerSeats,
        ...titleSeats,
      ]);
    case _Kind.swiper:
      final input = producer.widget as coui.Swiper;
      _concrete(field, Semantics);
      // This is the mounted framework Semantics, not input.open's seed.
      final currentExpanded = (field.widget as Semantics).properties.expanded;
      if (currentExpanded == null) {
        throw _changed('actual current expanded semantics');
      }
      final listener = _child(field, (field.widget as Semantics).child);
      _concrete(listener, Listener);
      _child(listener, input.child);
      witness.addAll([
        currentExpanded,
        input.open,
        input.enabled,
        input.position,
        input.variant,
      ]);
    case _Kind.diff:
      final input = producer.widget as coui.Diff;
      _concrete(field, coui.CoUISemantics);
      final outer = field.widget as coui.CoUISemantics;
      if (outer.role !=
          (input.interactive ? coui.CoreSemanticRole.slider : null)) {
        throw _changed('current diff semantic operation');
      }
      field = frame = _only(field);
      _concrete(field, Semantics);
      final focus = _child(field, (field.widget as Semantics).child);
      _concrete(focus, FocusableActionDetector);
      _identity(focus, (focus.widget as FocusableActionDetector).child);
      final stage = _diffStage(producer, raw, input);
      scope.requireOwned(stage);
      witness.addAll([
        input.interactive,
        outer.role,
        outer.value,
        outer.minValue,
        outer.maxValue,
        (field.widget as Semantics).properties.value,
        ...(stage.widget as coui.Stacks).children,
      ]);
  }
  scope
    ..requireOwned(producer)
    ..requireOwned(field)
    ..requireOwned(frame);
  final render = field.renderObject;
  final typeMatches = switch (kind) {
    _Kind.themes => render is RenderWrap,
    _Kind.tracker => render is RenderFlex,
    _Kind.sheet => render is RenderDecoratedBox,
    _Kind.swiper || _Kind.diff => render is RenderSemanticsAnnotations,
  };
  if (!typeMatches ||
      render is! RenderBox ||
      !render.attached ||
      !render.hasSize) {
    throw _changed('real attached owned source renderer');
  }
  return (
    result: result,
    producer: producer,
    field: field,
    frame: frame,
    scope: scope,
    raw: List.unmodifiable(raw),
    outsideTrigger: List.unmodifiable(outside),
    witness: List.unmodifiable(witness),
  );
}

Element _diffStage(Element producer, List<Widget> raw, coui.Diff input) {
  final candidates = <Element>[];
  void visit(Element element) {
    if (raw.any((w) => identical(w, element.widget))) {
      return;
    }
    final widget = element.widget;
    if (widget.runtimeType == coui.Stacks) {
      final seats = (widget as coui.Stacks).children;
      if (seats.length == (input.interactive ? 2 : 1) &&
          seats.first.runtimeType == coui.Position &&
          (seats.first as coui.Position).child?.runtimeType == ClipRRect) {
        final clip = (seats.first as coui.Position).child! as ClipRRect;
        if (clip.child?.runtimeType == coui.Stacks) {
          final content = (clip.child! as coui.Stacks).children;
          if (content.length >= 3 &&
              content[0].runtimeType == coui.Position &&
              identical((content[0] as coui.Position).child, input.after) &&
              content[1].runtimeType == coui.Position &&
              (content[1] as coui.Position).child?.runtimeType == ClipRect &&
              identical(
                ((content[1] as coui.Position).child! as ClipRect).child,
                input.before,
              )) {
            if (content[2].runtimeType != coui.Position ||
                (content[2] as coui.Position).child?.runtimeType !=
                    DecoratedBox) {
              throw _changed('source diff resizer decoration');
            }
            if (input.interactive) {
              final handle = seats[1];
              if (handle.runtimeType != coui.Position) {
                throw _changed('source diff handle position');
              }
              final position = handle as coui.Position;
              if (position.child?.runtimeType != MouseRegion) {
                throw _changed('source diff handle strip');
              }
              final mouse = position.child! as MouseRegion;
              if (mouse.child?.runtimeType != GestureDetector ||
                  (mouse.child! as GestureDetector).child?.runtimeType !=
                      Center) {
                throw _changed('source diff handle operation');
              }
            }
            var index = 3;
            for (final label in [input.beforeLabel, input.afterLabel]) {
              if (label == null) {
                continue;
              }
              if (index >= content.length ||
                  content[index].runtimeType != coui.Position) {
                throw _changed('complete diff label seats');
              }
              final ignore = (content[index++] as coui.Position).child;
              if (ignore?.runtimeType != IgnorePointer ||
                  (ignore! as IgnorePointer).child?.runtimeType != coui.Badge ||
                  !identical(
                    ((ignore as IgnorePointer).child! as coui.Badge).child,
                    label,
                  )) {
                throw _changed('actual source-forwarded diff label');
              }
            }
            if (content.length != index && content.length != index + 1) {
              throw _changed('complete diff decoration seats');
            }
            if (content.length == index + 1) {
              final edge = content.last;
              if (edge.runtimeType != coui.Position) {
                throw _changed('source painted diff edge position');
              }
              final position = edge as coui.Position;
              if (position.child?.runtimeType != IgnorePointer ||
                  (position.child! as IgnorePointer).child?.runtimeType !=
                      DecoratedBox) {
                throw _changed('source painted diff edge');
              }
            }
            candidates.add(element);
          }
        }
      }
    }
    element.visitChildren(visit);
  }

  visit(producer);
  return requireOneBoxOwner(
    candidates,
    'actual source diff stage, excluding whole foreign layers',
  );
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
  final out = <Element>[];
  root.visitChildren(out.add);
  return out;
}

Element _only(Element root) =>
    requireOneBoxOwner(_children(root), 'source direct construction child');
Element _child(Element root, Widget? widget) {
  if (widget == null) {
    throw _changed('required source child');
  }
  return requireOneBoxOwner(
    _children(root).where((e) => identical(e.widget, widget)),
    'actual direct source child',
  );
}

void _concrete(Element element, Type type) =>
    requireConcreteBoxSourceType(element.widget, type);
BoxObservationError _changed(String part) => BoxObservationError(
  'DATA_OVERLAY_LAYOUT_SOURCE_CHANGED',
  'Unsupported $part; no owner, quantity or absence is inferred.',
);
