import 'package:flutter/rendering.dart' show RenderDecoratedBox;
import 'package:flutter/widgets.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_preview_receipts.dart';
import 'box_padding_scene_units.dart';

/// Binds source references after official operation/source-value validation.
/// No private Type authentication or numeric inset is produced here.
SceneBoxSourceBinding bindPlaygroundBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
  required ValidatedPreviewReceipt validatedReceipt,
}) {
  validatedReceipt.requireCurrent();
  if (!identical(validatedReceipt.captureRoot, captureRoot) ||
      !identical(validatedReceipt.result, registryResult)) {
    throw const BoxObservationError(
      'PLAYGROUND_RECEIPT_ROOT_MISMATCH',
      'Use the receipt for this actual mounted factory return.',
    );
  }
  if (source.schemaVersion != 1 ||
      source.quantityId != BoxObservationSourceSpec.quantity ||
      source.logicalUnitId != 'documentation-playground-stage' ||
      source.nativeAdapterId != 'docs-playground-stage-frame-v1' ||
      source.webAdapterId != 'docs-playground-stage-frame-v1') {
    throw const BoxObservationError(
      'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
      'The closed Playground source tuple is required.',
    );
  }
  final result = validatedReceipt.registryResultElement;
  final constrained = _only(result);
  if (constrained.widget.runtimeType != ConstrainedBox) {
    throw const BoxObservationError(
      'PLAYGROUND_SOURCE_CHANGED',
      'Expected the source ConstrainedBox.',
    );
  }
  final frame = _child(
    constrained,
    (constrained.widget as ConstrainedBox).child,
  );
  if (frame.widget.runtimeType != DecoratedBox) {
    throw const BoxObservationError(
      'PLAYGROUND_SOURCE_CHANGED',
      'Expected the direct decorated frame.',
    );
  }
  final render = frame.renderObject;
  if (render is! RenderDecoratedBox ||
      render.decoration is! BoxDecoration ||
      (render.decoration as BoxDecoration).border != null) {
    throw const BoxObservationError(
      'PLAYGROUND_ALLOCATION_CHANGED',
      'The current source frame must have no border allocation.',
    );
  }
  final center = _child(frame, (frame.widget as DecoratedBox).child);
  if (center.widget.runtimeType != Center) {
    throw const BoxObservationError(
      'PLAYGROUND_OWN_INSET_SOURCE_CHANGED',
      'The exact no-own-padding route must end at Center, not another inset.',
    );
  }
  final supplied = _child(center, (center.widget as Center).child);
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: [supplied],
  )..requireOwned(frame);
  return (
    authority:
        'Official builder operation receipt and frozen Playground value '
        'contract; buildFlutterPlaygroundStage ConstrainedBox -> DecoratedBox '
        '-> Center -> actual helper child boundary; no private RTTI claim',
    registryResultElement: result,
    fieldUnitElement: frame,
    paddingSource: frame,
    frameSource: frame,
    scope: scope,
    readerId: 'declared-no-own-padding-v1',
  );
}

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the source direct child');
}

Element _child(Element parent, Widget? child) {
  final actual = _only(parent);
  if (child == null || !identical(child, actual.widget)) {
    throw const BoxObservationError(
      'PLAYGROUND_CHILD_IDENTITY_CHANGED',
      'Missing exact source child.',
    );
  }
  return actual;
}
