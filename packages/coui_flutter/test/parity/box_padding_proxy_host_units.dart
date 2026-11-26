import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/hover/hover_default_example.dart';
import 'package:docs_core/previews/examples/flutter/hover/hover_fade_example.dart';
import 'package:docs_core/previews/examples/flutter/indicator/indicator_bottom_start_example.dart';
import 'package:docs_core/previews/examples/flutter/indicator/indicator_default_example.dart';
import 'package:docs_core/previews/examples/flutter/mask/mask_circle_example.dart';
import 'package:docs_core/previews/examples/flutter/mask/mask_default_example.dart';
import 'package:docs_core/previews/examples/flutter/mask/mask_heart_example.dart';
import 'package:docs_core/previews/examples/flutter/mask/mask_hexagon_example.dart';
import 'package:docs_core/previews/examples/flutter/mask/mask_star_example.dart';
import 'package:docs_core/previews/examples/flutter/mask/mask_triangle_example.dart';
import 'package:flutter/rendering.dart'
    show RenderClipPath, RenderMouseRegion, RenderStack;
import 'package:flutter/widgets.dart'
    show
        AnimatedOpacity,
        AnimatedScale,
        Clip,
        ClipPath,
        DecoratedBox,
        EdgeInsets,
        Element,
        KeyedSubtree,
        MouseRegion,
        Padding,
        Positioned,
        SizedBox,
        Stack,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

typedef _Route = ({
  Element result,
  Element producer,
  Element frame,
  BoxProducerScope scope,
  String authority,
});

/// A source-specific witness; no generic proxy/Stack absence permission.
class ProxyHostBoxSourceBinding {
  ProxyHostBoxSourceBinding._({
    required _Route route,
    required Element captureRoot,
    required Widget registryResult,
    required BoxObservationSourceSpec source,
  }) : authority = route.authority,
       registryResultElement = route.result,
       fieldUnitElement = route.frame,
       paddingSource = route.frame,
       frameSource = route.frame,
       scope = route.scope,
       absenceKind = source.logicalUnitId,
       _captureRoot = captureRoot,
       _registryWidget = registryResult,
       _producer = route.producer,
       _producerWidget = route.producer.widget,
       _source = source;

  final String authority;
  final Element registryResultElement;
  final Element fieldUnitElement;
  final Element paddingSource;
  final Element frameSource;
  final BoxProducerScope scope;
  final String absenceKind;
  final Element _captureRoot;
  final Widget _registryWidget;
  final Element _producer;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;

  String get readerId => 'proxy-host-declared-absence-v1';

  /// Rechecks original Widget identities and this live source/layout route.
  /// Clip contour, scale paint, foreign content and overlay are not insets.
  BoxPaddingObservation readDeclaredAbsence() {
    if (!_captureRoot.mounted ||
        !registryResultElement.mounted ||
        !_producer.mounted ||
        !frameSource.mounted ||
        !identical(registryResultElement.widget, _registryWidget) ||
        !identical(_producer.widget, _producerWidget)) {
      throw _changed('the original mounted construction identities');
    }
    final current = _locate(_captureRoot, _registryWidget, _source);
    if (!identical(current.result, registryResultElement) ||
        !identical(current.producer, _producer) ||
        !identical(current.frame, frameSource)) {
      throw _changed('the original generated host Element');
    }
    current.scope.requireOwned(current.frame);
    return BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: current.frame,
      producer: current.producer,
      contentBoundary: current.frame,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      generatedSlots: [
        {'sourceContract': absenceKind, 'authority': current.authority},
      ],
      frameOwner: current.frame,
    );
  }
}

ProxyHostBoxSourceBinding? bindProxyHostBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (!_kUnits.contains(source.logicalUnitId)) return null;
  return ProxyHostBoxSourceBinding._(
    route: _locate(captureRoot, registryResult, source),
    captureRoot: captureRoot,
    registryResult: registryResult,
    source: source,
  );
}

const _kUnits = {
  'mask-generated-clip-host',
  'hover-generated-effect-host',
  'indicator-generated-overlay-host',
};

_Route _locate(
  Element captureRoot,
  Widget registryResult,
  BoxObservationSourceSpec source,
) {
  if (!_kUnits.contains(source.logicalUnitId) ||
      source.schemaVersion != 1 ||
      source.quantityId != BoxObservationSourceSpec.quantity ||
      source.nativeAdapterId != '${source.logicalUnitId}-v1' ||
      source.webAdapterId != '${source.logicalUnitId}-v1') {
    throw _changed('the closed source tuple/version');
  }
  final capture = captureRoot.widget;
  if (!identical(capture, registryResult) &&
      !(capture.runtimeType == KeyedSubtree &&
          identical((capture as KeyedSubtree).child, registryResult))) {
    throw _changed('the actual capture construction result');
  }
  final result = _identity(captureRoot, registryResult);
  final (type, examples) = switch (source.logicalUnitId) {
    'mask-generated-clip-host' => (
      coui.Mask,
      const <Type>[
        MaskDefaultExample,
        MaskCircleExample,
        MaskHeartExample,
        MaskHexagonExample,
        MaskStarExample,
        MaskTriangleExample,
      ],
    ),
    'hover-generated-effect-host' => (
      coui.Hover,
      const <Type>[HoverDefaultExample, HoverFadeExample],
    ),
    'indicator-generated-overlay-host' => (
      coui.Indicator,
      const <Type>[IndicatorDefaultExample, IndicatorBottomStartExample],
    ),
    _ => throw _changed('an audited source construction'),
  };
  Element producer;
  if (registryResult.runtimeType == type) {
    producer = result;
  } else {
    if (!examples.contains(registryResult.runtimeType)) {
      throw _changed('the exact official example/public producer type');
    }
    producer = _only(result);
    if (type == coui.Mask) {
      _concrete(producer, SizedBox);
      producer = _child(producer, (producer.widget as SizedBox).child);
    }
  }
  _concrete(producer, type);
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  final identities = Set<Widget>.identity();
  for (final slot in [
    ...declaration.scope.suppliedSlots,
    ...declaration.unrenderedSuppliedSlots,
  ]) {
    if (!identities.add(slot)) throw _changed('unique public slot identities');
    _identity(producer, slot);
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  final frame = switch (source.logicalUnitId) {
    'mask-generated-clip-host' => _mask(producer),
    'hover-generated-effect-host' => _hover(producer),
    'indicator-generated-overlay-host' => _indicator(producer),
    _ => throw _changed('the audited generated host'),
  };
  scope.requireOwned(frame);
  return (
    result: result,
    producer: producer,
    frame: frame,
    scope: scope,
    authority:
        'Actual exact registry/producer Widget refs and frozen build source; '
        '${declaration.authority}; ${source.logicalUnitId}; '
        'own host has no padding operation, foreign content/paint excluded',
  );
}

Element _mask(Element producer) {
  final widget = producer.widget as coui.Mask;
  if (widget.half != coui.CoreMaskHalf.none ||
      !const {
        coui.CoreMaskShape.squircle,
        coui.CoreMaskShape.circle,
        coui.CoreMaskShape.heart,
        coui.CoreMaskShape.hexagon,
        coui.CoreMaskShape.star,
        coui.CoreMaskShape.triangle,
      }.contains(widget.shape)) {
    throw _changed('the non-square/non-half clip-only branch');
  }
  final clip = _only(producer);
  _concrete(clip, ClipPath);
  if (!identical((clip.widget as ClipPath).child, widget.child) ||
      clip.renderObject.runtimeType != RenderClipPath) {
    throw _changed('the actual clipping host and public child identity');
  }
  _child(clip, widget.child);
  return clip;
}

Element _hover(Element producer) {
  final widget = producer.widget as coui.Hover;
  if (widget.child == null ||
      (widget.effect != coui.CoreHoverEffect.scaleUp &&
          widget.effect != coui.CoreHoverEffect.fade)) {
    throw _changed('the supported single-child scaleUp/fade branch');
  }
  final mouse = _only(producer);
  _concrete(mouse, MouseRegion);
  final effect = _child(mouse, (mouse.widget as MouseRegion).child);
  final Widget? child;
  if (widget.effect == coui.CoreHoverEffect.scaleUp) {
    _concrete(effect, AnimatedScale);
    child = (effect.widget as AnimatedScale).child;
  } else {
    _concrete(effect, AnimatedOpacity);
    child = (effect.widget as AnimatedOpacity).child;
  }
  if (!identical(child, widget.child) ||
      mouse.renderObject.runtimeType != RenderMouseRegion) {
    throw _changed('the actual effect host and supplied child identity');
  }
  _child(effect, child);
  return mouse;
}

Element _indicator(Element producer) {
  final widget = producer.widget as coui.Indicator;
  if (widget.horizontalPosition ==
          coui.CoreIndicatorHorizontalPosition.center ||
      widget.verticalPosition == coui.CoreIndicatorVerticalPosition.middle) {
    throw _changed('the audited corner overlay branch');
  }
  final stacks = _only(producer);
  _concrete(stacks, coui.Stacks);
  final layers = (stacks.widget as coui.Stacks).children;
  if (layers.length != 2 || !identical(layers[0], widget.child)) {
    throw _changed('the single non-positioned supplied content layer');
  }
  final position = _child(stacks, layers[1]);
  _concrete(position, coui.Position);
  final positioned = _only(position);
  _concrete(positioned, Positioned);
  final item = (position.widget as coui.Position).child;
  if (!identical((positioned.widget as Positioned).child, item)) {
    throw _changed('the positioned source item identity');
  }
  if (!identical(item, widget.item)) {
    final decoration = _child(position, item);
    _concrete(decoration, DecoratedBox);
    final ring = _child(decoration, (decoration.widget as DecoratedBox).child);
    _concrete(ring, Padding);
    if (!identical((ring.widget as Padding).child, widget.item)) {
      throw _changed('the overlay ring supplied item identity');
    }
  }
  _child(position, widget.item);
  final stack = _only(stacks);
  _concrete(stack, Stack);
  final host = stack.widget as Stack;
  if (host.children.length != 2 ||
      !identical(host.children[0], layers[0]) ||
      !identical(host.children[1], layers[1]) ||
      host.clipBehavior != Clip.none ||
      stack.renderObject.runtimeType != RenderStack) {
    throw _changed('the actual two-layer nonclipping Stack host');
  }
  return stack;
}

Element _identity(Element parent, Widget widget) => requireOneBoxOwner(
  boxElements(parent).where((element) => identical(element.widget, widget)),
  'the exact live source Widget identity',
);

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the exact generated source child');
}

Element _child(Element parent, Widget? widget) {
  if (widget == null) throw _changed('a required source child');
  return _identity(parent, widget);
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _changed('the exact concrete generated source type');
  }
}

BoxObservationError _changed(String source) => BoxObservationError(
  'PROXY_HOST_SOURCE_CHANGED',
  'Unsupported $source; no owner or absent value is inferred.',
);
