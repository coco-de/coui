import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/avatar/avatar_default_example.dart';
import 'package:docs_core/previews/examples/flutter/avatar/avatar_rounded_example.dart';
import 'package:docs_core/previews/examples/flutter/code_snippet/code_snippet_default_example.dart';
import 'package:docs_core/previews/examples/flutter/mockup/mockup_code_example.dart';
import 'package:docs_core/previews/examples/flutter/mockup/mockup_code_tones_example.dart';
import 'package:docs_core/previews/examples/flutter/stat/stat_default_example.dart';
import 'package:docs_core/previews/examples/flutter/stat/stat_empty_example.dart';
import 'package:docs_core/previews/examples/flutter/stat/stat_outlined_example.dart';
import 'package:docs_core/previews/examples/flutter/validation_badge/validation_badge_default_example.dart';
import 'package:docs_core/previews/examples/flutter/validation_badge/validation_badge_invalid_example.dart';
import 'package:docs_core/previews/examples/flutter/validation_badge/validation_badge_medium_example.dart';
import 'package:docs_core/previews/examples/flutter/validation_badge/validation_badge_pending_example.dart';
import 'package:flutter/widgets.dart'
    show Builder, Container, Element, KeyedSubtree, Semantics, Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_scope_extensions.dart';

/// Actual source references; the existing shared reader owns all numeric reads.
typedef DisplayBoxSourceBinding = ({
  String authority,
  Element registryResultElement,
  Element fieldUnitElement,
  Element paddingSource,
  Element? frameSource,
  BoxProducerScope scope,
  String readerId,
});

/// Binds only the audited key-only example construction and mounted result.
///
/// No factory, build method, callback, style resolver or padding value is read
/// to choose the owner. MockupCode's split Web inset needs a separate paired
/// quantity decision; a Native frame reference does not establish eligibility.
DisplayBoxSourceBinding? bindDisplayBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source.schemaVersion != 1) {
    throw _error('UNSUPPORTED_BOX_SOURCE_VERSION');
  }
  if (source.quantityId != BoxObservationSourceSpec.quantity) {
    throw _error('UNSUPPORTED_BOX_QUANTITY');
  }
  final adapter = switch (source.logicalUnitId) {
    'avatar-generated-frame' => 'avatar-generated-frame-v1',
    'code-snippet-generated-frame' => 'code-snippet-generated-frame-v1',
    'mockup-code-generated-frame' => 'mockup-code-generated-frame-v1',
    'stat-generated-frame' => 'stat-generated-frame-v1',
    'validation-badge-generated-frame' => 'validation-badge-generated-frame-v1',
    _ => null,
  };
  if (adapter == null) return null;
  if (source.nativeAdapterId != adapter || source.webAdapterId != adapter) {
    throw _error('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  }
  final capture = captureRoot.widget;
  if (!identical(capture, registryResult) &&
      !(capture.runtimeType == KeyedSubtree &&
          identical((capture as KeyedSubtree).child, registryResult))) {
    throw _error('MISMATCHED_CONSTRUCTION_RESULT');
  }
  final result = _reference(captureRoot, registryResult);
  final example = registryResult.runtimeType;
  final Type producerType;
  switch (adapter) {
    case 'avatar-generated-frame-v1':
      _requireExample(
        example == AvatarDefaultExample || example == AvatarRoundedExample,
      );
      producerType = coui.Avatar;
    case 'code-snippet-generated-frame-v1':
      _requireExample(example == CodeSnippetDefaultExample);
      producerType = coui.CodeSnippet;
    case 'mockup-code-generated-frame-v1':
      _requireExample(
        example == MockupCodeExample || example == MockupCodeTonesExample,
      );
      producerType = coui.MockupCode;
    case 'stat-generated-frame-v1':
      _requireExample(
        example == StatDefaultExample ||
            example == StatOutlinedExample ||
            example == StatEmptyExample,
      );
      producerType = coui.Stat;
    case 'validation-badge-generated-frame-v1':
      _requireExample(
        example == ValidationBadgeDefaultExample ||
            example == ValidationBadgePendingExample ||
            example == ValidationBadgeInvalidExample ||
            example == ValidationBadgeMediumExample,
      );
      producerType = coui.ValidationBadge;
    default:
      throw _error('UNREGISTERED_DISPLAY_CONSTRUCTION');
  }
  final producer = _generatedChild(result);
  requireConcreteBoxSourceType(producer.widget, producerType);
  final widget = producer.widget;
  final List<Widget> supplied;
  final Element frame;
  final String authority;
  final String reader;
  if (widget is coui.Avatar) {
    if (widget.ring || widget.badge != null) {
      throw _error('UNSUPPORTED_AVATAR_OVERLAY_SOURCE');
    }
    supplied = [?widget.child, ?widget.badge];
    final tier = _generatedChild(producer);
    requireConcreteBoxSourceType(tier.widget, coui.TypographyTierScope);
    final builderWidget = (tier.widget as coui.TypographyTierScope).child;
    requireConcreteBoxSourceType(builderWidget, Builder);
    final builder = _reference(tier, builderWidget);
    frame = _generatedChild(builder);
    requireConcreteBoxSourceType(frame.widget, coui.OutlinedContainer);
    authority =
        'Avatar.build TypographyTierScope.child Builder actual generated '
        'OutlinedContainer; no ring/badge; Avatar.child is foreign';
    reader = 'outlined-content-v1';
  } else if (widget is coui.ValidationBadge) {
    supplied = const [];
    final semantics = _generatedChild(producer);
    requireConcreteBoxSourceType(semantics.widget, Semantics);
    final child = (semantics.widget as Semantics).child;
    // A material wrapper is not transparently skipped. Its source route is
    // not adopted here; an unknown wrapper cannot supply a descendant box.
    if (child == null || child.runtimeType != Container) {
      throw _error('UNSUPPORTED_VALIDATION_BADGE_MATERIAL_SOURCE');
    }
    frame = _reference(semantics, child);
    authority =
        'ValidationBadge.build Semantics.child actual Container chip; '
        'label/IconName inputs contain no supplied Widget slots';
    reader = 'current-container-v1';
  } else if (widget is coui.Stat) {
    supplied = [?widget.icon];
    frame = _generatedChild(producer);
    requireConcreteBoxSourceType(frame.widget, coui.OutlinedContainer);
    authority =
        'Stat.build actual direct OutlinedContainer; public icon is foreign';
    reader = 'outlined-content-v1';
  } else {
    final declaration = describeAdditionalBoxProducerSource(producer);
    if (declaration == null || declaration.outlinedFrame == null) {
      throw _error('MISSING_DISPLAY_FRAME_SOURCE');
    }
    supplied = declaration.supplied;
    frame = declaration.outlinedFrame!.primitive;
    requireConcreteBoxSourceType(frame.widget, coui.OutlinedContainer);
    authority =
        '${declaration.authority}; '
        '${declaration.outlinedFrame!.authority}; '
        'CodeSnippet content/gutter or MockupCode line padding is not summed';
    reader = 'outlined-content-v1';
  }
  final scope = BoxProducerScope(producer: result, suppliedSlots: supplied)
    ..requireOwned(producer)
    ..requireOwned(frame);
  return (
    authority:
        'Exact key-only registry example actual generated child; '
        '$authority',
    registryResultElement: result,
    fieldUnitElement: producer,
    paddingSource: frame,
    frameSource: frame,
    scope: scope,
    readerId: reader,
  );
}

void _requireExample(bool matches) {
  if (!matches) throw _error('UNREGISTERED_DISPLAY_CONSTRUCTION');
}

Element _reference(Element parent, Widget widget) => requireOneBoxOwner(
  boxElements(parent).where((element) => identical(element.widget, widget)),
  'the actual Widget reference declared by its source',
);

Element _generatedChild(Element element) {
  final children = <Element>[];
  element.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the actual generated source child');
}

BoxObservationError _error(String code) => BoxObservationError(
  code,
  'The audited display construction/source boundary is not satisfied.',
);
