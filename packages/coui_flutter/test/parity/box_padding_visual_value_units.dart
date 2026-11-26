import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/countdown/countdown_default_example.dart';
import 'package:docs_core/previews/examples/flutter/icon/icon_default_example.dart';
import 'package:docs_core/previews/examples/flutter/icon/icon_favorite_example.dart';
import 'package:docs_core/previews/examples/flutter/icon/icon_search_example.dart';
import 'package:docs_core/previews/examples/flutter/number_ticker/number_ticker_default_example.dart';
import 'package:docs_core/previews/examples/flutter/skeleton/skeleton_text_example.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show
        AnimatedBuilder,
        AnimatedSwitcher,
        Column,
        Container,
        EdgeInsets,
        Element,
        FractionallySizedBox,
        IndexedSlot,
        KeyedSubtree,
        Semantics,
        SizedBox,
        Text,
        Widget;
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

enum _Kind { icon, ticker, skeleton, countdown }

typedef _Route = ({
  Element result,
  Element producer,
  Element field,
  Element frame,
  BoxProducerScope scope,
  List<Widget?> raw,
  List<Object?> operation,
  List<Element> generated,
});

/// A source-proven absence on an existing, independently owned current frame.
/// Generated glyphs, text and skeleton lines never become caller content.
class VisualValueBoxSourceBinding {
  VisualValueBoxSourceBinding._(
    this._capture,
    this._registry,
    this._source,
    this._kind,
    this._route,
  ) : _producerWidget = _route.producer.widget,
      _raw = List.unmodifiable(_route.raw),
      _operation = List.unmodifiable(_route.operation);

  final Element _capture;
  final Widget _registry;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;
  final _Kind _kind;
  final _Route _route;
  final List<Widget?> _raw;
  final List<Object?> _operation;

  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.field;
  Element get paddingSource => _route.field;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  List<Widget?> get allOriginalSuppliedSlots => _raw;
  String get readerId => 'visual-value-declared-absence-v1';
  String get authority =>
      'Concrete ${_kind.name} construction and its full current public '
      'generated path; original nullable slots before omission; existing '
      'owned frame with no padding allocation; no builder replay, private '
      'state, font metrics or Core/Resolved geometry';

  _Route _current() {
    if (!_capture.mounted ||
        !_route.result.mounted ||
        !_route.producer.mounted ||
        !identical(_route.result.widget, _registry) ||
        !identical(_route.producer.widget, _producerWidget)) {
      throw _changed('held producer or registry identity');
    }
    final now = _locate(_capture, _registry, _source, _kind);
    if (!identical(now.result, registryResultElement) ||
        !identical(now.producer, _route.producer) ||
        !identical(now.field, fieldUnitElement) ||
        !identical(now.frame, frameSource) ||
        !_same(now.raw, _raw, identity: true) ||
        !_same(now.operation, _operation) ||
        !_same(
          now.scope.foreignBoundaries,
          scope.foreignBoundaries,
          identity: true,
        )) {
      throw _changed('held public inputs, raw slots or owned frame');
    }
    // Generated animation children may legitimately update. The whole current
    // declared child bag is revalidated above; no old child count is reused.
    return now;
  }

  void validateExistingCurrentBinding() {
    _current();
  }

  BoxPaddingObservation readActualPadding() =>
      throw _changed('parameter reader on a declared absence');

  BoxPaddingObservation readDeclaredAbsence() {
    final now = _current();
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
          'originalNullableSlots': now.raw.length,
          'currentGeneratedElements': now.generated.length,
        },
      ],
      frameOwner: frameSource,
    );
  }
}

VisualValueBoxSourceBinding? bindVisualValueBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  final matches = _Kind.values.where(
    (kind) => _spec(kind).logicalUnitId == source.logicalUnitId,
  );
  if (matches.isEmpty) return null;
  final kind = matches.single;
  return VisualValueBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    kind,
    _locate(captureRoot, registryResult, source, kind),
  );
}

BoxObservationSourceSpec _spec(_Kind kind) => switch (kind) {
  _Kind.icon => BoxObservationSourceSpec.iconVisualFrame,
  _Kind.ticker => BoxObservationSourceSpec.numberTickerTextLayoutHost,
  _Kind.skeleton => BoxObservationSourceSpec.skeletonTextLinesLayoutHost,
  _Kind.countdown => BoxObservationSourceSpec.countdownValueLayoutHost,
};

Type _type(_Kind kind) => switch (kind) {
  _Kind.icon => coui.Icon,
  _Kind.ticker => coui.NumberTicker,
  _Kind.skeleton => coui.Skeleton,
  _Kind.countdown => coui.Countdown,
};

bool _example(Widget widget, _Kind kind) => switch (kind) {
  _Kind.icon =>
    widget.runtimeType == IconDefaultExample ||
        widget.runtimeType == IconFavoriteExample ||
        widget.runtimeType == IconSearchExample,
  _Kind.ticker => widget.runtimeType == NumberTickerDefaultExample,
  _Kind.skeleton => widget.runtimeType == SkeletonTextExample,
  _Kind.countdown => widget.runtimeType == CountdownDefaultExample,
};

_Route _locate(
  Element capture,
  Widget registry,
  BoxObservationSourceSpec source,
  _Kind kind,
) {
  if (source != _spec(kind)) throw _changed('closed source tuple/version');
  if (!capture.mounted ||
      !(identical(capture.widget, registry) ||
          (capture.widget.runtimeType == KeyedSubtree &&
              identical((capture.widget as KeyedSubtree).child, registry)))) {
    throw _changed('exact current capture result');
  }
  final result = _identity(capture, registry);
  final direct = registry.runtimeType == _type(kind);
  if (!direct && !_example(registry, kind)) {
    throw _changed('audited Example or exact public producer');
  }
  final producer = direct ? result : _only(result);
  _concrete(producer, _type(kind));

  // Null references keep their original seats; no branch omission precedes
  // this collection or the identity duplicate check.
  final raw = <Widget?>[];
  if (kind == _Kind.ticker) {
    raw.add((producer.widget as coui.NumberTicker).child);
  }
  final unique = Set<Widget>.identity();
  for (final slot in raw.whereType<Widget>()) {
    if (!unique.add(slot)) throw _changed('duplicate raw slot before omission');
  }
  final operation = <Object?>[];
  final generated = <Element>[];
  var field = _only(producer);

  switch (kind) {
    case _Kind.icon:
      final input = producer.widget as coui.Icon;
      operation.addAll([input.icon, input.iconStyle]);
      _concrete(field, SizedBox);
      final frame = field.widget as SizedBox;
      if (frame.child != null) {
        final glyph = _declared(field, frame.child);
        _concrete(glyph, SvgPicture);
        generated.add(glyph);
      } else if (_children(field).isNotEmpty) {
        throw _changed('placeholder SizedBox has undeclared content');
      }
      if (field.findRenderObject() is! RenderConstrainedBox) {
        throw _changed('Icon own current constrained frame');
      }
    // Both icon.dart branches construct this same independent SizedBox.
    // Neither requires private loaded data or a first glyph descendant.
    case _Kind.ticker:
      final input = producer.widget as coui.NumberTicker;
      if (input.builder != null ||
          input.formatter != null ||
          input.child != null) {
        throw _changed('closed plain NumberTicker operation');
      }
      operation.addAll([
        input.value,
        input.initialValue,
        input.curve,
        input.numberTickerStyle,
      ]);
      _concrete(field, (coui.AnimatedValueBuilder<double>));
      final animation = field.widget as coui.AnimatedValueBuilder<double>;
      if (animation.child != null ||
          animation.builder == null ||
          animation.animationBuilder != null ||
          animation.rawBuilder != null) {
        throw _changed('generated plain value animation');
      }
      generated.add(field);
      final animated = _only(field);
      _concrete(animated, AnimatedBuilder);
      generated.add(animated);
      field = _only(animated);
      _plainText(field);
      if (field.findRenderObject() is! RenderParagraph) {
        throw _changed('actual generated text RenderParagraph');
      }
    case _Kind.skeleton:
      final input = producer.widget as coui.Skeleton;
      if (input.variant != coui.CoreSkeletonVariant.text) {
        throw _changed('text Skeleton operation, not circular/block');
      }
      operation.addAll([
        input.variant,
        input.width,
        input.height,
        input.skeletonStyle,
      ]);
      if (field.widget.runtimeType == Semantics) {
        generated.add(field);
        field = _declared(field, (field.widget as Semantics).child);
      }
      _concrete(field, AnimatedBuilder);
      generated.add(field);
      field = _only(field);
      _concrete(field, Column);
      final lines = (field.widget as Column).children;
      final seats = _declaredSeats(field, lines);
      for (final line in seats) {
        _concrete(line, FractionallySizedBox);
        final cell = _declared(
          line,
          (line.widget as FractionallySizedBox).child,
        );
        _concrete(cell, Container);
        if ((cell.widget as Container).child != null) {
          throw _changed('generated skeleton line has supplied content');
        }
        generated.addAll([line, cell]);
      }
      if (field.findRenderObject() is! RenderFlex) {
        throw _changed('actual owned skeleton lines RenderFlex');
      }
    // Container borders, widths and pulse state are inner generated data.
    // The outer Column itself allocates no padding in every text branch.
    case _Kind.countdown:
      final input = producer.widget as coui.Countdown;
      operation.addAll([
        input.value,
        input.min,
        input.max,
        input.countdownStyle,
      ]);
      _concrete(field, Semantics);
      final animation = _declared(field, (field.widget as Semantics).child);
      _concrete(animation, AnimatedSwitcher);
      final text = (animation.widget as AnimatedSwitcher).child;
      if (text == null || text.runtimeType != Text) {
        throw _changed('generated current countdown text');
      }
      final currentText = _identity(animation, text);
      _plainText(currentText);
      generated.addAll([animation, currentText]);
      if (field.findRenderObject() is! RenderSemanticsAnnotations) {
        throw _changed('own outer semantic frame');
      }
    // Outgoing transition children belong to AnimatedSwitcher. None is
    // selected as the outer semantic host or used to infer a current value.
  }

  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: raw.whereType<Widget>(),
  )..requireOwned(field);
  generated.forEach(scope.requireOwned);
  final render = field.findRenderObject();
  if (render is! RenderBox || !render.hasSize) {
    throw _changed('independently measurable current owned box');
  }
  return (
    result: result,
    producer: producer,
    field: field,
    frame: field,
    scope: scope,
    raw: List.unmodifiable(raw),
    operation: List.unmodifiable(operation),
    generated: List.unmodifiable(generated),
  );
}

/// Public declared widgets and public indexed slots establish the entire
/// current generated order. Traversal order and first matches are not
/// authority.
List<Element> _declaredSeats(Element parent, List<Widget> widgets) {
  final unique = Set<Widget>.identity();
  if (widgets.any((widget) => !unique.add(widget))) {
    throw _changed('duplicate generated declaration');
  }
  final elements = _children(parent);
  if (elements.length != widgets.length) {
    throw _changed('complete generated child cardinality');
  }
  final indexed = <int, Element>{};
  for (final element in elements) {
    final slot = element.slot;
    if (slot is! IndexedSlot<Element?> ||
        slot.index < 0 ||
        slot.index >= widgets.length ||
        indexed.containsKey(slot.index) ||
        !identical(element.widget, widgets[slot.index])) {
      throw _changed('generated indexed-slot identity bijection');
    }
    indexed[slot.index] = element;
  }
  final ordered = [for (var i = 0; i < widgets.length; i++) indexed[i]!];
  for (var i = 0; i < ordered.length; i++) {
    final slot = ordered[i].slot! as IndexedSlot<Element?>;
    if (!identical(slot.value, i == 0 ? null : ordered[i - 1])) {
      throw _changed('generated declared predecessor chain');
    }
  }
  return ordered;
}

void _plainText(Element element) {
  _concrete(element, Text);
  final text = element.widget as Text;
  if (text.data == null || text.textSpan != null) {
    throw _changed('generated plain text, not supplied WidgetSpan');
  }
}

bool _same(List<Object?> a, List<Object?> b, {bool identity = false}) =>
    a.length == b.length &&
    List.generate(
      a.length,
      (i) => identity ? identical(a[i], b[i]) : a[i] == b[i],
    ).every((same) => same);

List<Element> _children(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return children;
}

Element _only(Element parent) =>
    requireOneBoxOwner(_children(parent), 'exact visual-value build edge');

Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((element) => identical(element.widget, widget)),
  'original visual-value Widget identity',
);

Element _declared(Element parent, Widget? widget) {
  if (widget == null) throw _changed('required public declared child');
  return elementOfDeclaredChild(parent, widget);
}

void _concrete(Element element, Type type) =>
    requireConcreteBoxSourceType(element.widget, type);

BoxObservationError _changed(String part) => BoxObservationError(
  'VISUAL_VALUE_SOURCE_CHANGED',
  'Unsupported $part; no missing/foreign box is interpreted as zero.',
);
