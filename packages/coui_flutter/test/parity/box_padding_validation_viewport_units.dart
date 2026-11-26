import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/fade_scroll/fade_scroll_default_example.dart';
import 'package:docs_core/previews/examples/flutter/fade_scroll/fade_scroll_horizontal_example.dart';
import 'package:docs_core/previews/examples/flutter/fade_scroll/fade_scroll_with_scrollbar_example.dart';
import 'package:docs_core/previews/examples/flutter/formatter/formatter_default_example.dart';
import 'package:docs_core/previews/examples/flutter/hover/hover_default_example.dart';
import 'package:docs_core/previews/examples/flutter/hover/hover_fade_example.dart';
import 'package:docs_core/previews/examples/flutter/hover/hover_shadow_example.dart';
import 'package:docs_core/previews/examples/flutter/kbd/kbd_combo_example.dart';
import 'package:docs_core/previews/examples/flutter/kbd/kbd_default_example.dart';
import 'package:docs_core/previews/examples/flutter/kbd/kbd_four_example.dart';
import 'package:docs_core/previews/examples/flutter/overflow_marquee/overflow_marquee_default_example.dart';
import 'package:docs_core/previews/examples/flutter/scroll_area/scroll_area_default_example.dart';
import 'package:docs_core/previews/examples/flutter/validated/validated_default_example.dart';
import 'package:docs_core/previews/examples/flutter/validator_hint/validator_hint_default_example.dart';
import 'package:flutter/rendering.dart'
    show RenderBox, RenderClipRect, RenderFlex, RenderMouseRegion;
import 'package:flutter/widgets.dart'
    show
        Align,
        AnimatedOpacity,
        Axis,
        Builder,
        ClipRect,
        ColorFiltered,
        Column,
        ConstrainedBox,
        Container,
        DefaultTextStyle,
        EdgeInsets,
        Element,
        ExcludeSemantics,
        Flexible,
        IgnorePointer,
        ImageFiltered,
        IntrinsicHeight,
        KeyedSubtree,
        ListenableBuilder,
        MouseRegion,
        Padding,
        Positioned,
        RenderObjectElement,
        Row,
        ScrollConfiguration,
        Semantics,
        ShaderMask,
        SingleChildRenderObjectWidget,
        SingleChildScrollView,
        SizedBox,
        Stack,
        StatelessWidget,
        TextEditingValue,
        Transform,
        ValueListenableBuilder,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

enum _Kind { field, validated, hint, scroll, fade, marquee, shadow, keys }

typedef _Route = ({
  Element result,
  Element producer,
  Element field,
  Element padding,
  Element frame,
  BoxProducerScope scope,
  List<Widget?> raw,
  List<Object?> operation,
});

/// Only current, source-owned primitives are returned. Supplied children,
/// including every copy in Hover's shadow fold, remain opaque foreign trees.
class ValidationViewportBoxSourceBinding {
  ValidationViewportBoxSourceBinding._(
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
  Element get paddingSource => _route.padding;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get readerId => _kind == _Kind.field
      ? 'current-render-padding-v1'
      : 'validation-viewport-declared-absence-v1';
  String get absenceKind => _source.logicalUnitId;
  String get authority =>
      'Exact concrete registry recipe and current public construction edges; '
      'complete ordered raw slots before omission; ${_source.logicalUnitId}; '
      'all supplied subtrees and source-authorized shadow copies excluded';

  void validateExistingCurrentBinding() {
    if (!_capture.mounted ||
        !_route.result.mounted ||
        !_route.producer.mounted ||
        !_route.field.mounted ||
        !_route.padding.mounted ||
        !_route.frame.mounted ||
        !identical(_route.result.widget, _registry) ||
        !identical(_route.producer.widget, _producerWidget)) {
      throw _changed('the held mounted construction');
    }
    final now = _locate(_capture, _registry, _source, _kind);
    if (!identical(now.result, _route.result) ||
        !identical(now.producer, _route.producer) ||
        !identical(now.field, _route.field) ||
        !identical(now.padding, _route.padding) ||
        !identical(now.frame, _route.frame) ||
        !_sameRaw(now.raw, _raw) ||
        !_sameOperation(now.operation, _operation) ||
        !_sameElements(now.scope.foreignBoundaries, scope.foreignBoundaries)) {
      throw _changed('the held current operation/raw slots/foreign copies');
    }
  }

  BoxPaddingObservation readActualPadding() {
    validateExistingCurrentBinding();
    if (_kind != _Kind.field) {
      throw _changed('an explicit own Padding operation');
    }
    return observeSourceOwnedRenderPadding(
      owner: paddingSource,
      scope: scope,
    ).withFrameOwner(frameSource);
  }

  BoxPaddingObservation readDeclaredAbsence() {
    validateExistingCurrentBinding();
    if (_kind == _Kind.field) {
      throw _changed('TextField has an own Padding');
    }
    scope.requireOwned(frameSource);
    return BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: frameSource,
      producer: registryResultElement,
      contentBoundary: frameSource,
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

ValidationViewportBoxSourceBinding? bindValidationViewportBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  final kind = switch (source.logicalUnitId) {
    'text-field-generated-content-inset' => _Kind.field,
    'validated-generated-layout-host' => _Kind.validated,
    'validator-hint-generated-message-layout-host' => _Kind.hint,
    'scroll-area-generated-viewport-layout-host' => _Kind.scroll,
    'fade-scroll-generated-viewport-layout-host' => _Kind.fade,
    'overflow-marquee-generated-viewport-layout-host' => _Kind.marquee,
    'hover-generated-effect-host' => _Kind.shadow,
    'kbd-generated-key-sequence-layout-host' => _Kind.keys,
    _ => null,
  };
  if (kind == null) {
    return null;
  }
  // Only the two audited old effects remain with the existing helper.
  // Every other recognized Hover source must prove its current shadow path.
  if (kind == _Kind.shadow &&
      (registryResult.runtimeType == HoverDefaultExample ||
          registryResult.runtimeType == HoverFadeExample)) {
    return null;
  }
  if (kind == _Kind.shadow && registryResult.runtimeType == coui.Hover) {
    final hover = registryResult as coui.Hover;
    if (hover.effect == coui.CoreHoverEffect.scaleUp ||
        hover.effect == coui.CoreHoverEffect.fade) {
      return null;
    }
  }
  return ValidationViewportBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    kind,
    _locate(captureRoot, registryResult, source, kind),
  );
}

BoxObservationSourceSpec _spec(_Kind kind) => switch (kind) {
  _Kind.field => BoxObservationSourceSpec.textFieldContentInset,
  _Kind.validated => BoxObservationSourceSpec.validatedLayoutHost,
  _Kind.hint => BoxObservationSourceSpec.validatorHintMessageLayoutHost,
  _Kind.scroll => BoxObservationSourceSpec.scrollAreaViewportLayoutHost,
  _Kind.fade => BoxObservationSourceSpec.fadeScrollViewportLayoutHost,
  _Kind.marquee => BoxObservationSourceSpec.overflowMarqueeViewportLayoutHost,
  _Kind.shadow => BoxObservationSourceSpec.hoverEffectHost,
  _Kind.keys => BoxObservationSourceSpec.kbdKeySequenceLayoutHost,
};
Type _type(_Kind kind) => switch (kind) {
  _Kind.field => coui.TextField,
  _Kind.validated => coui.Validated,
  _Kind.hint => coui.ValidatorHint,
  _Kind.scroll => coui.ScrollArea,
  _Kind.fade => coui.FadeScroll,
  _Kind.marquee => coui.OverflowMarquee,
  _Kind.shadow => coui.Hover,
  _Kind.keys => coui.Kbd,
};
bool _example(Widget widget, _Kind kind) => switch (kind) {
  _Kind.field => widget.runtimeType == FormatterDefaultExample,
  _Kind.validated => widget.runtimeType == ValidatedDefaultExample,
  _Kind.hint => widget.runtimeType == ValidatorHintDefaultExample,
  _Kind.scroll => widget.runtimeType == ScrollAreaDefaultExample,
  _Kind.fade =>
    widget.runtimeType == FadeScrollDefaultExample ||
        widget.runtimeType == FadeScrollHorizontalExample ||
        widget.runtimeType == FadeScrollWithScrollbarExample,
  _Kind.marquee => widget.runtimeType == OverflowMarqueeDefaultExample,
  _Kind.shadow => widget.runtimeType == HoverShadowExample,
  _Kind.keys =>
    widget.runtimeType == KbdDefaultExample ||
        widget.runtimeType == KbdComboExample ||
        widget.runtimeType == KbdFourExample,
};

_Route _locate(
  Element capture,
  Widget registry,
  BoxObservationSourceSpec source,
  _Kind kind,
) {
  if (source != _spec(kind)) {
    throw _changed('the closed tuple/version');
  }
  if (!capture.mounted ||
      !(identical(capture.widget, registry) ||
          (capture.widget.runtimeType == KeyedSubtree &&
              identical((capture.widget as KeyedSubtree).child, registry)))) {
    throw _changed('the canonical capture construction result');
  }
  final result = _identity(capture, registry);
  var producer = result;
  if (registry.runtimeType != _type(kind)) {
    if (!_example(registry, kind)) {
      throw _changed('an exact audited recipe');
    }
    producer = _only(result);
    if (producer.widget.runtimeType == SizedBox) {
      producer = _child(producer, (producer.widget as SizedBox).child);
    }
  }
  _concrete(producer, _type(kind));
  final raw = _raw(producer.widget, kind);
  _unique(raw); // Includes identities later omitted by the current operation.
  final omitted = Set<Widget>.identity();
  List<Element>? declaredBoundaries;
  var field = producer;
  var padding = producer;
  var frame = producer;
  final operation = <Object?>[];

  switch (kind) {
    case _Kind.field:
      final declaration = DeclaredBoxProducer.bind(
        producer: producer,
        sourceContract: 'renderer-frame-padding-v1',
      );
      // The existing typed TextField slot binder proves current placeholder
      // omission. No controller/builder is replayed by this module.
      omitted.addAll(declaration.unrenderedSuppliedSlots);
      declaredBoundaries = declaration.scope.foreignBoundaries;
      final candidates = <Element>[];
      for (final e in boxElements(producer)) {
        if (e.widget.runtimeType != Container) continue;
        try {
          declaration.scope.requireOwned(e);
        } on BoxObservationError {
          continue;
        }
        final c = e.widget as Container;
        final a = c.child;
        if (a is! Align ||
            a.runtimeType != Align ||
            a.child is! Padding ||
            a.child.runtimeType != Padding) {
          continue;
        }
        final p = a.child! as Padding;
        if (p.child is! ValueListenableBuilder<TextEditingValue>) continue;
        candidates.add(e);
      }
      frame = requireOneBoxOwner(
        candidates,
        'the TextField generated content Container',
      );
      final align = elementOfDeclaredChild(
        frame,
        (frame.widget as Container).child!,
      );
      padding = _child(align, (align.widget as Align).child);
      field = frame;
    case _Kind.validated:
      final w = producer.widget as coui.Validated;
      field = _only(producer);
      _concrete(field, Column);
      final seats = (field.widget as Column).children;
      final messageShown =
          w.message != null && w.state != coui.CoreValidationState.pending;
      if (seats.length != (w.child == null ? 0 : 1) + (messageShown ? 2 : 0) ||
          seats.isEmpty) {
        throw _changed('the current validation child/message operation');
      }
      if (w.child != null) {
        final data = _child(field, seats.first);
        if (data.widget is! coui.Data<Object?> ||
            !identical((data.widget as coui.Data<Object?>).child, w.child)) {
          throw _changed('the source-owned validation Data child');
        }
        _identity(data, w.child!);
      }
      if (messageShown) {
        final gap = _child(field, seats[seats.length - 2]);
        _concrete(gap, coui.Gap);
        final hint = _child(field, seats.last);
        _concrete(hint, coui.ValidatorHint);
        final h = hint.widget as coui.ValidatorHint;
        if (!identical(h.message, w.message) ||
            !h.visible ||
            h.type !=
                (w.state == coui.CoreValidationState.invalid
                    ? coui.CoreValidatorHintType.error
                    : coui.CoreValidatorHintType.success)) {
          throw _changed('the composed current message identity');
        }
      } else if (w.message != null) {
        omitted.add(w.message!);
      }
      operation.add(w.state);
      frame = padding = field;
    case _Kind.hint:
      final w = producer.widget as coui.ValidatorHint;
      if (!w.visible) {
        throw _changed('an invisible hint has no message host');
      }
      final semantics = _only(producer);
      _concrete(semantics, coui.CoUISemantics);
      final builder = _child(
        semantics,
        (semantics.widget as coui.CoUISemantics).child,
        direct: false,
      );
      _concrete(builder, Builder); // DefaultTextStyle.merge's public Builder.
      final style = _only(builder);
      _concrete(style, DefaultTextStyle);
      field = _child(style, (style.widget as DefaultTextStyle).child);
      _concrete(field, Row);
      final seats = (field.widget as Row).children;
      if (seats.length != (w.message == null ? 2 : 3)) {
        throw _changed('hint seats');
      }
      if (w.message != null) {
        final message = _child(field, seats.last);
        _concrete(message, Flexible);
        if (!identical((message.widget as Flexible).child, w.message)) {
          throw _changed('hint message');
        }
      }
      operation.addAll([w.visible, w.type]);
      frame = padding = field;
    case _Kind.scroll:
      final w = producer.widget as coui.ScrollArea;
      var bar = _only(producer);
      if (bar.widget.runtimeType == ConstrainedBox) {
        bar = _child(bar, (bar.widget as ConstrainedBox).child);
      }
      _concrete(bar, coui.Scrollbar);
      final scroll = _child(
        bar,
        (bar.widget as coui.Scrollbar).child,
        direct: false,
      );
      _scroll(
        scroll,
        w.child,
        w.direction == coui.CoreScrollAreaDirection.horizontal
            ? Axis.horizontal
            : Axis.vertical,
      );
      frame = padding = field = _ownedBox(scroll);
      operation.addAll([w.direction, w.showScrollbar]);
    case _Kind.fade:
      final w = producer.widget as coui.FadeScroll;
      var outer = _only(producer);
      if (w.direction == coui.CoreFadeScrollDirection.horizontal) {
        _concrete(outer, IntrinsicHeight);
        outer = _child(outer, (outer.widget as IntrinsicHeight).child);
      }
      Element listenable;
      if (w.showScrollbar) {
        _concrete(outer, coui.Scrollbar);
        listenable = _child(
          outer,
          (outer.widget as coui.Scrollbar).child,
          direct: false,
        );
      } else {
        _concrete(outer, ScrollConfiguration);
        listenable = _child(outer, (outer.widget as ScrollConfiguration).child);
      }
      _concrete(listenable, ListenableBuilder);
      var scroll = _only(listenable);
      if (scroll.widget.runtimeType == ShaderMask) {
        operation.add(scroll);
        scroll = _child(scroll, (scroll.widget as ShaderMask).child);
      }
      _scroll(
        scroll,
        w.child,
        w.direction == coui.CoreFadeScrollDirection.horizontal
            ? Axis.horizontal
            : Axis.vertical,
      );
      if (!identical(
        (listenable.widget as ListenableBuilder).listenable,
        (scroll.widget as SingleChildScrollView).controller,
      )) {
        throw _changed('the live scroll operation');
      }
      frame = padding = field = _ownedBox(scroll);
      operation.addAll([w.direction, w.showScrollbar]);
    case _Kind.marquee:
      final w = producer.widget as coui.OverflowMarquee;
      var clip = _only(producer);
      if (clip.widget.runtimeType == MouseRegion) {
        clip = _child(clip, (clip.widget as MouseRegion).child);
      }
      _concrete(clip, ClipRect);
      final layout = _child(clip, (clip.widget as ClipRect).child);
      // A source-owned private renderer is inspected only through its public
      // SingleChildRenderObjectWidget contract; no private RTTI or state.
      if (layout.widget is! SingleChildRenderObjectWidget ||
          !identical(
            (layout.widget as SingleChildRenderObjectWidget).child,
            w.child,
          ) ||
          layout is! RenderObjectElement ||
          layout.renderObject is! RenderBox) {
        throw _changed('the original single-child marquee operation');
      }
      _child(layout, w.child);
      if (clip.renderObject is! RenderClipRect) {
        throw _changed('the own clipped viewport');
      }
      frame = padding = field = clip;
    case _Kind.shadow:
      final w = producer.widget as coui.Hover;
      if (w.effect != coui.CoreHoverEffect.shadow || w.child == null) {
        throw _changed('the shadow branch');
      }
      final mouse = _only(producer);
      _concrete(mouse, MouseRegion);
      final bridge = _child(mouse, (mouse.widget as MouseRegion).child);
      if (bridge.widget is! StatelessWidget) {
        throw _changed('the source-owned effect build edge');
      }
      final copies = <Element>[];
      _shadow(_only(bridge), w.child!, copies);
      if (!_sameElementSet(copies, _matches(producer, w.child!))) {
        throw _changed('all current shadow copies');
      }
      declaredBoundaries = copies;
      if (mouse.renderObject is! RenderMouseRegion) {
        throw _changed('the own effect host');
      }
      frame = padding = field = mouse;
      operation.addAll(copies);
    case _Kind.keys:
      final w = producer.widget as coui.Kbd;
      if (w.keyContent != null || w.keys.isEmpty) {
        throw _changed('the nonempty raw keys route');
      }
      var row = _only(producer);
      if (row.widget.runtimeType == Semantics) {
        final s = row.widget as Semantics;
        if (s.properties.label != w.keys.join(' ')) {
          throw _changed('the current complete key name');
        }
        row = _child(row, s.child);
      }
      _concrete(row, Row);
      final seats = (row.widget as Row).children;
      if (seats.length != w.keys.length) {
        throw _changed('every generated key seat');
      }
      for (var i = 0; i < seats.length; i++) {
        final cap = _child(row, seats[i]);
        _concrete(cap, coui.InjectedCast);
        // Generated cap chrome is not the whole key-sequence inset source.
      }
      operation.addAll(w.keys);
      frame = padding = field = row;
  }
  final boundaries = declaredBoundaries ?? <Element>[];
  for (final slot in raw.whereType<Widget>()) {
    final mounted = _matches(producer, slot);
    if (omitted.contains(slot)) {
      if (mounted.isNotEmpty) {
        throw _changed('source-omitted raw content');
      }
    } else if (kind != _Kind.shadow) {
      if (mounted.length != 1) {
        throw _changed('one original whole supplied slot');
      }
      if (declaredBoundaries == null) boundaries.add(mounted.single);
    }
  }
  final scope =
      BoxProducerScope(
          producer: result,
          suppliedSlots: const [],
          derivedSuppliedElements: boundaries,
        )
        ..requireOwned(producer)
        ..requireOwned(field)
        ..requireOwned(padding)
        ..requireOwned(frame);
  if (frame.renderObject is! RenderBox) {
    throw _changed('an actual independently owned box');
  }
  if (const {_Kind.validated, _Kind.hint, _Kind.keys}.contains(kind) &&
      frame.renderObject is! RenderFlex) {
    throw _changed('the actual generated sequence renderer');
  }
  return (
    result: result,
    producer: producer,
    field: field,
    padding: padding,
    frame: frame,
    scope: scope,
    raw: raw,
    operation: operation,
  );
}

List<Widget?> _raw(Widget widget, _Kind kind) {
  switch (kind) {
    case _Kind.field:
      final field = widget as coui.TextField;
      return [field.placeholder, field.prefix, field.suffix];
    case _Kind.validated:
      final validated = widget as coui.Validated;
      return [validated.message, validated.child];
    case _Kind.hint:
      final hint = widget as coui.ValidatorHint;
      return [hint.message, hint.icon];
    case _Kind.scroll:
      return [(widget as coui.ScrollArea).child];
    case _Kind.fade:
      return [(widget as coui.FadeScroll).child];
    case _Kind.marquee:
      return [(widget as coui.OverflowMarquee).child];
    case _Kind.shadow:
      return [(widget as coui.Hover).child];
    case _Kind.keys:
      return [(widget as coui.Kbd).keyContent];
  }
}

void _scroll(Element e, Widget child, Axis axis) {
  _concrete(e, SingleChildScrollView);
  final w = e.widget as SingleChildScrollView;
  if (!identical(w.child, child) ||
      w.padding != null ||
      w.scrollDirection != axis) {
    throw _changed('the current unpadded scroll viewport and whole child');
  }
}

void _shadow(Element e, Widget raw, List<Element> copies) {
  if (identical(e.widget, raw)) {
    copies.add(e);
    return;
  }
  _concrete(e, coui.Stacks);
  final w = e.widget as coui.Stacks;
  final stack = _only(e);
  _concrete(stack, Stack);
  if (w.children.length != 2 ||
      !_sameRaw((stack.widget as Stack).children, w.children)) {
    throw _changed('the shadow fold seats');
  }
  final position = _child(stack, w.children[0]);
  _concrete(position, coui.Position);
  final positioned = _only(position);
  _concrete(positioned, Positioned);
  var left = _child(positioned, (positioned.widget as Positioned).child);
  _concrete(left, ExcludeSemantics);
  left = _child(left, (left.widget as ExcludeSemantics).child);
  _concrete(left, IgnorePointer);
  left = _child(left, (left.widget as IgnorePointer).child);
  _concrete(left, AnimatedOpacity);
  left = _child(left, (left.widget as AnimatedOpacity).child, direct: false);
  _concrete(left, Transform);
  left = _child(left, (left.widget as Transform).child);
  _concrete(left, ImageFiltered);
  left = _child(left, (left.widget as ImageFiltered).child);
  _concrete(left, ColorFiltered);
  final previous = (left.widget as ColorFiltered).child;
  if (!identical(previous, w.children[1])) {
    throw _changed('both identical previous-composite projections');
  }
  _shadow(_child(left, previous), raw, copies);
  _shadow(_child(stack, previous), raw, copies);
}

Element _ownedBox(Element operation) {
  final render = operation.renderObject;
  if (render is! RenderBox) {
    throw _changed('the current viewport RenderBox');
  }
  return requireOneBoxOwner(
    boxElements(operation).where(
      (e) => e is RenderObjectElement && identical(e.renderObject, render),
    ),
    'the actual render owner of the named viewport operation',
  );
}

void _unique(List<Widget?> raw) {
  final seen = Set<Widget>.identity();
  for (final slot in raw.whereType<Widget>()) {
    if (!seen.add(slot)) {
      throw _changed('duplicate raw slot identities before omission');
    }
  }
}

List<Element> _matches(Element root, Widget widget) =>
    boxElements(root).where((e) => identical(e.widget, widget)).toList();
Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  _matches(root, widget),
  'the exact current Widget identity',
);
List<Element> _children(Element e) {
  final out = <Element>[];
  e.visitChildren(out.add);
  return out;
}

Element _only(Element e) =>
    requireOneBoxOwner(_children(e), 'one generated direct child');
Element _child(Element e, Widget? widget, {bool direct = true}) {
  if (widget == null) {
    throw _changed('a required declared child');
  }
  return requireOneBoxOwner(
    (direct ? _children(e) : boxElements(e)).where(
      (c) => identical(c.widget, widget),
    ),
    'the declared current source child',
  );
}

void _concrete(Element e, Type type) {
  if (e.widget.runtimeType != type) {
    throw _changed('the exact public source type');
  }
}

bool _sameRaw(List<Widget?> a, List<Widget?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((v) => v);
bool _sameElements(List<Element> a, List<Element> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((v) => v);
bool _sameElementSet(List<Element> a, List<Element> b) =>
    a.length == b.length &&
    a.toSet().length == a.length &&
    a.every((e) => b.any((other) => identical(e, other)));
bool _sameOperation(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);
BoxObservationError _changed(String part) => BoxObservationError(
  'VALIDATION_VIEWPORT_SOURCE_CHANGED',
  'Unsupported $part; no padding owner, callback result or absence inferred.',
);
