import 'package:docs_core/previews/examples/flutter/text/text_colors_brand_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_colors_status_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_colors_surface_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_keep_all_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_modifiers_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_opacity_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_rich_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_textstyle_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_typography_body_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_typography_display_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_typography_headline_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_typography_primitive_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_typography_title_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_typography_weight_example.dart';
import 'package:docs_core/previews/examples/flutter/text/text_wrap_example.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter/widgets.dart'
    show Element, KeyedSubtree, Padding, Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

/// The exact declared outer allocation, never a Text glyph/span box.
/// A declaration still requires the original current closed Example mount.
const BoxObservationSourceSpec kTextShowcaseOuterPaddingSource =
    BoxObservationSourceSpec.textShowcaseOuterPadding;

const _kExamples = <Type>{
  TextTypographyDisplayExample,
  TextTypographyHeadlineExample,
  TextTypographyTitleExample,
  TextTypographyBodyExample,
  TextTypographyWeightExample,
  TextTypographyPrimitiveExample,
  TextColorsBrandExample,
  TextColorsStatusExample,
  TextColorsSurfaceExample,
  TextModifiersExample,
  TextWrapExample,
  TextKeepAllExample,
  TextTextstyleExample,
  TextOpacityExample,
  TextRichExample,
};

typedef _Route = ({
  Element result,
  Element padding,
  Element content,
  RenderPadding render,
  List<Widget?> raw,
  BoxProducerScope scope,
});

/// Binds an already built showcase to its own current framework Padding.
/// The original Padding.child is a whole opaque boundary. Its Text chains,
/// spans, callbacks, descendants and insets cannot supply the outer quantity.
class TextShowcaseBoxSourceBinding {
  TextShowcaseBoxSourceBinding._(
    this._capture,
    this._registry,
    this._source,
    this._route,
  );

  final Element _capture;
  final Widget _registry;
  final BoxObservationSourceSpec _source;
  final _Route _route;

  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.padding;
  Element get paddingSource => _route.padding;
  Element get frameSource => _route.padding;
  BoxProducerScope get scope => _route.scope;
  List<Widget?> get allOriginalSuppliedSlots => _route.raw;
  String get readerId => 'text-showcase-actual-framework-padding-v1';
  String get authority =>
      'Exact current classic Text showcase construction returns public '
      'Padding; its original nullable child is an opaque foreign boundary; '
      'read that same current RenderPadding without builder replay, Text '
      'inspection, Core/style expectations or descendant owner selection';

  _Route _current() {
    if (_route.scope.foreignBoundaries.length != 1 ||
        !identical(
          _route.scope.foreignBoundaries.single,
          _route.content,
        )) {
      throw _changed('retained whole foreign boundary');
    }
    final now = _locate(_capture, _registry, _source);
    if (!identical(now.result, _route.result) ||
        !identical(now.padding, _route.padding) ||
        !identical(now.content, _route.content) ||
        !identical(now.render, _route.render) ||
        !identical(now.raw.single, _route.raw.single)) {
      throw _changed('held source or original foreign child identity');
    }
    return now;
  }

  void validateExistingCurrentBinding() {
    _current();
  }

  BoxPaddingObservation readActualPadding() {
    final now = _current();
    final observed = observeSourceOwnedRenderPadding(
      owner: now.padding,
      scope: now.scope,
    );
    final value = observed.value;
    if ([value.top, value.right, value.bottom, value.left].any(
      (side) => !side.isFinite || side < 0,
    )) {
      throw _changed('finite nonnegative actual framework parameter');
    }
    return observed.withFrameOwner(now.padding);
  }

  BoxPaddingObservation readDeclaredAbsence() =>
      throw _changed('absence reader on an existing Padding allocation');
}

TextShowcaseBoxSourceBinding? bindTextShowcaseBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source.logicalUnitId != kTextShowcaseOuterPaddingSource.logicalUnitId) {
    return null;
  }
  return TextShowcaseBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    _locate(captureRoot, registryResult, source),
  );
}

_Route _locate(
  Element capture,
  Widget registry,
  BoxObservationSourceSpec source,
) {
  if (source != kTextShowcaseOuterPaddingSource) {
    throw _changed('closed source tuple/version');
  }
  if (!capture.mounted || !_kExamples.contains(registry.runtimeType)) {
    throw _changed('mounted exact audited showcase type');
  }
  final Element result;
  if (identical(capture.widget, registry)) {
    result = capture;
  } else if (capture.widget.runtimeType == KeyedSubtree &&
      identical((capture.widget as KeyedSubtree).child, registry)) {
    result = _only(capture);
  } else {
    throw _changed('actual capture result identity');
  }
  if (!result.mounted || !identical(result.widget, registry)) {
    throw _changed('original current registry result');
  }

  // Every closed Example directly returns Padding. No build callback runs
  // here, and no search enters its generated content to find another owner.
  final padding = _only(result);
  requireConcreteBoxSourceType(padding.widget, Padding);
  final input = padding.widget as Padding;
  final raw = <Widget?>[input.child];
  final unique = Set<Widget>.identity();
  for (final child in raw.whereType<Widget>()) {
    if (!unique.add(child)) {
      throw _changed('duplicate raw slot before omission');
    }
  }
  if (input.child == null) {
    throw _changed('required original child after raw nullable collection');
  }
  final content = _only(padding);
  if (!content.mounted || !identical(content.widget, input.child)) {
    throw _changed('complete direct Padding child identity');
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: raw.whereType<Widget>(),
  )..requireOwned(padding);
  if (scope.foreignBoundaries.length != 1 ||
      !identical(scope.foreignBoundaries.single, content)) {
    throw _changed('one whole opaque original child boundary');
  }
  final render = padding.renderObject;
  if (render is! RenderPadding ||
      !render.attached ||
      !render.hasSize ||
      !identical(render.child, content.findRenderObject())) {
    throw _changed('same current independently laid-out Padding renderer');
  }
  return (
    result: result,
    padding: padding,
    content: content,
    render: render,
    raw: List.unmodifiable(raw),
    scope: scope,
  );
}

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'exact Text showcase build edge');
}

BoxObservationError _changed(String part) => BoxObservationError(
  'TEXT_SHOWCASE_SOURCE_CHANGED',
  'Unsupported $part; no foreign, missing or stale frame becomes zero.',
);
