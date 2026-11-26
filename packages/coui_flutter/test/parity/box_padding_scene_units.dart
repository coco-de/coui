import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/internal/preview/flutter_card_view.dart'
    show FlutterDocsCardView, FlutterDocsCardsLayout;
import 'package:docs_core/internal/preview/flutter_stage.dart'
    show DocsStage, FlutterDocsSizeSpec;
import 'package:flutter/rendering.dart' show RenderDecoratedBox;
import 'package:flutter/widgets.dart'
    show
        BoxDecoration,
        Column,
        ConstrainedBox,
        Container,
        DecoratedBox,
        Element,
        IntrinsicWidth,
        KeyedSubtree,
        LayoutBuilder,
        Padding,
        Semantics,
        SizedBox,
        Widget,
        Wrap;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

/// Actual source references only. The shared observer owns all value reads.
typedef SceneBoxSourceBinding = ({
  String authority,
  Element registryResultElement,
  Element fieldUnitElement,
  Element paddingSource,
  Element? frameSource,
  BoxProducerScope scope,
  String readerId,
});

/// Binds only the closed documentation units audited against their builders.
///
/// A whole-card descriptor is registered only for DocsScene's existing
/// Card/whole-card/cardIndex0 contract. The layout's single supplied card is
/// that explicit semantic unit, never a general parent-ownership exception.
SceneBoxSourceBinding? bindDocumentationBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source.schemaVersion != 1) {
    throw const BoxObservationError(
      'UNSUPPORTED_BOX_SOURCE_VERSION',
      'The documentation source version is not implemented.',
    );
  }
  if (source.quantityId != BoxObservationSourceSpec.quantity) {
    throw const BoxObservationError(
      'UNSUPPORTED_BOX_QUANTITY',
      'The source must declare the existing own-content inset quantity.',
    );
  }
  final stage = source.logicalUnitId == 'registry-scene-frame';
  final card = source.logicalUnitId == 'whole-documentation-card';
  final size = source.logicalUnitId == 'documentation-size-preview-frame';
  if (!stage && !card && !size) return null;
  final bool valid;
  if (stage) {
    valid = source == BoxObservationSourceSpec.docsStage;
  } else if (size) {
    valid =
        source.nativeAdapterId == 'docs-size-preview-frame-v1' &&
        source.webAdapterId == 'docs-size-preview-frame-v1';
  } else {
    valid =
        source.nativeAdapterId == 'whole-doc-card-frame-v1' &&
        source.webAdapterId == 'whole-doc-card-frame-v1';
  }
  if (!valid) {
    throw const BoxObservationError(
      'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
      'The logical unit and its two source adapters must match exactly.',
    );
  }
  final rootWidget = captureRoot.widget;
  if (!identical(rootWidget, registryResult) &&
      !(rootWidget is KeyedSubtree &&
          identical(rootWidget.child, registryResult))) {
    throw const BoxObservationError(
      'MISMATCHED_CONSTRUCTION_RESULT',
      'The registry result is not the actual capture child.',
    );
  }
  final result = requireOneBoxOwner(
    boxElements(captureRoot).where(
      (element) => identical(element.widget, registryResult),
    ),
    'the actual documentation registry result',
  );
  if (size) {
    if (registryResult.runtimeType != FlutterDocsSizeSpec) {
      throw const BoxObservationError(
        'SOURCE_CONTRACT_PRODUCER_MISMATCH',
        'This unit requires the audited FlutterDocsSizeSpec constructor.',
      );
    }
    final columnElement = _singleChild(result);
    if (columnElement.widget is! Column) {
      throw const BoxObservationError(
        'DOCS_SIZE_SPEC_SOURCE_CHANGED',
        'SizeSpec must return its declared preview/table Column.',
      );
    }
    final column = columnElement.widget as Column;
    final children = <Element>[];
    columnElement.visitChildren(children.add);
    if (column.children.length != 2 ||
        children.length != 2 ||
        !identical(children[0].widget, column.children[0]) ||
        !identical(children[1].widget, column.children[1]) ||
        column.children[0] is! DecoratedBox ||
        column.children[1] is! Column) {
      throw const BoxObservationError(
        'DOCS_SIZE_SPEC_SOURCE_CHANGED',
        'The actual source child identities must be preview then table.',
      );
    }
    // These indices belong to FlutterDocsSizeSpec.build's named branches,
    // not a search for the first painted box or first Padding descendant.
    final preview = children[0];
    final frame = preview.renderObject;
    // The owner was selected by source identity above. Absence of border
    // allocation is a quantity premise, not a numeric owner-selection rule.
    if (frame is! RenderDecoratedBox ||
        frame.decoration is! BoxDecoration ||
        (frame.decoration as BoxDecoration).border != null) {
      throw const BoxObservationError(
        'DOCS_SIZE_PREVIEW_ALLOCATION_CHANGED',
        'The current preview frame must have no border allocation.',
      );
    }
    final padding = _directChild(
      preview,
      (preview.widget as DecoratedBox).child,
    );
    if (padding.widget is! Padding) {
      throw const BoxObservationError(
        'DOCS_SIZE_PREVIEW_PADDING_CHANGED',
        'The declared preview frame must own its direct Padding.',
      );
    }
    final content = _directChild(padding, (padding.widget as Padding).child);
    if (content.widget is! Wrap) {
      throw const BoxObservationError(
        'DOCS_SIZE_PREVIEW_CONTENT_CHANGED',
        'The preview Padding must forward its actual generated Wrap.',
      );
    }
    final scope = BoxProducerScope(producer: result, suppliedSlots: const [])
      ..requireOwned(preview)
      ..requireOwned(padding);
    return (
      authority:
          'FlutterDocsSizeSpec.build: actual Column.children[0] '
          'DecoratedBox.child -> Padding.child -> Wrap; '
          'children[1] table is outside the preview field unit; '
          'data-only inputs',
      registryResultElement: result,
      fieldUnitElement: preview,
      paddingSource: padding,
      frameSource: preview,
      scope: scope,
      readerId: 'current-render-padding-v1',
    );
  }
  if (stage) {
    // Exact constructor types exclude unknown subclass build/slot contracts.
    if (registryResult.runtimeType != DocsStage) {
      throw const BoxObservationError(
        'SOURCE_CONTRACT_PRODUCER_MISMATCH',
        'This unit requires the audited DocsStage constructor.',
      );
    }
    final constrained = _singleChild(result);
    if (constrained.widget is! ConstrainedBox) {
      throw const BoxObservationError(
        'DOCS_STAGE_SOURCE_CHANGED',
        'DocsStage must return its declared ConstrainedBox.',
      );
    }
    final container = _directChild(
      constrained,
      (constrained.widget as ConstrainedBox).child,
    );
    if (container.widget is! Container) {
      throw const BoxObservationError(
        'DOCS_STAGE_FRAME_CHANGED',
        'The declared direct stage frame is not a current Container.',
      );
    }
    final scope = BoxProducerScope(producer: result, suppliedSlots: const [])
      ..requireOwned(container);
    return (
      authority:
          'DocsStage.build: ConstrainedBox.child -> Container; '
          'data-only inputs',
      registryResultElement: result,
      fieldUnitElement: result,
      paddingSource: container,
      frameSource: container,
      scope: scope,
      readerId: 'current-container-v1',
    );
  }
  if (registryResult.runtimeType != FlutterDocsCardView) {
    throw const BoxObservationError(
      'SOURCE_CONTRACT_PRODUCER_MISMATCH',
      'A whole-card source requires the audited FlutterDocsCardView.',
    );
  }
  final view = registryResult as FlutterDocsCardView;
  final outer = BoxProducerScope(producer: result, suppliedSlots: const []);
  final layoutElement = _singleChild(result);
  if (layoutElement.widget.runtimeType != FlutterDocsCardsLayout) {
    throw const BoxObservationError(
      'DOCS_CARD_LAYOUT_CHANGED',
      'The view must return its declared cards layout directly.',
    );
  }
  final layout = layoutElement.widget as FlutterDocsCardsLayout;
  if (layout.cards.length != 1) {
    throw const BoxObservationError(
      'DOCS_CARD_CARDINALITY_CHANGED',
      'The standalone whole-card contract requires exactly one card.',
    );
  }
  final suppliedCard = layout.cards.single;
  final builder = _singleChild(layoutElement);
  if (builder.widget is! LayoutBuilder) {
    throw const BoxObservationError(
      'DOCS_CARD_LAYOUT_CHANGED',
      'The cards layout must retain its actual LayoutBuilder.',
    );
  }
  final wrap = _singleChild(builder);
  if (wrap.widget is! Wrap || (wrap.widget as Wrap).children.length != 1) {
    throw const BoxObservationError(
      'DOCS_CARD_LAYOUT_CHANGED',
      'The standalone layout must retain its single generated Wrap child.',
    );
  }
  final sized = _directChild(wrap, (wrap.widget as Wrap).children.single);
  if (sized.widget is! SizedBox ||
      !identical((sized.widget as SizedBox).child, suppliedCard)) {
    throw const BoxObservationError(
      'DOCS_CARD_LAYOUT_CHANGED',
      'The generated size wrapper must forward the actual cards.single.',
    );
  }
  final selected = _directChild(sized, suppliedCard);
  outer.requireOwned(selected);
  var field = selected;
  if (view.attributes['href'] != null) {
    if (field.widget is! Semantics) {
      throw const BoxObservationError(
        'DOCS_CARD_HREF_BRANCH_CHANGED',
        'The href branch must begin with the declared Semantics.',
      );
    }
    field = _directChild(field, (field.widget as Semantics).child);
    if (field.widget is! coui.Clickable) {
      throw const BoxObservationError(
        'DOCS_CARD_HREF_BRANCH_CHANGED',
        'The href Semantics must wrap the declared Clickable.',
      );
    }
    // Clickable's generated interaction tree may branch. Only its actual
    // public child object can identify the delegated Card, never a type match.
    final child = (field.widget as coui.Clickable).child;
    field = requireOneBoxOwner(
      boxElements(field).where((element) => identical(element.widget, child)),
      'the source href Clickable.child Widget identity',
    );
  }
  if (field.widget is! coui.Card) {
    throw const BoxObservationError(
      'DOCS_CARD_FIELD_UNIT_CHANGED',
      'The exact source branch must end at the documentation Card.',
    );
  }
  outer.requireOwned(field);
  final declaration = DeclaredBoxProducer.bind(
    producer: field,
    sourceContract: 'renderer-frame-padding-v1',
  );
  // Card's own generated branch crosses sizing/shadow wrappers only. It
  // cannot descend into any of the six public content slots.
  var primitive = _singleChild(field);
  while (primitive.widget is! coui.OutlinedContainer) {
    declaration.scope.requireOwned(primitive);
    final widget = primitive.widget;
    final child = switch (widget) {
      IntrinsicWidth() => widget.child,
      SizedBox() => widget.child,
      DecoratedBox() => widget.child,
      _ => null,
    };
    if (child == null) {
      throw const BoxObservationError(
        'DOCS_CARD_OWN_FRAME_CHANGED',
        'The Card build left its declared own sizing/shadow frame route.',
      );
    }
    primitive = _directChild(primitive, child);
  }
  declaration.scope.requireOwned(primitive);
  outer.requireOwned(primitive);
  // Keep the outer data-only declaring view and the inner Card's real public
  // boundaries together. Only cards.single was explicitly delegated above.
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(primitive);
  final branchAuthority = view.attributes['href'] == null
      ? 'Card'
      : 'Semantics.child -> Clickable.child -> Card';
  return (
    authority:
        'DocsScene Card/whole-card/cardIndex0; FlutterDocsCardView.build -> '
        'FlutterDocsCardsLayout.cards.single identity; '
        '$branchAuthority; '
        'Card child/media/header/body/footer/overlay boundaries -> '
        'own OutlinedContainer',
    registryResultElement: result,
    fieldUnitElement: field,
    paddingSource: primitive,
    frameSource: primitive,
    scope: scope,
    readerId: 'outlined-content-v1',
  );
}

Element _singleChild(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the declared direct build child');
}

Element _directChild(Element parent, Widget? child) {
  final actual = _singleChild(parent);
  if (child == null || !identical(actual.widget, child)) {
    throw const BoxObservationError(
      'DOCUMENTATION_CHILD_IDENTITY_CHANGED',
      'The actual direct child must be the source Widget reference.',
    );
  }
  return actual;
}
