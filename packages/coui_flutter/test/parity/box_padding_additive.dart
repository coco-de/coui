import 'package:flutter/rendering.dart' show RenderBox;
import 'package:flutter/widgets.dart' show Element, RenderObjectElement, Widget;

import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';
import 'parity_matrix_entry.dart';

/// Separate source observations cannot change the legacy role's eligibility.
/// A missing source remains unresolved, with no manufactured value.
Map<String, Object?> observeAdditiveBoxPadding({
  required String key,
  required Iterable<ParityProbeSpec> probes,
  required bool legacyRootOmitted,
  required Element captureRoot,
  required RenderBox? canonicalFrame,
  Widget? docsSceneConstructorResult,
}) => {
  'key': key,
  'mode': 'additive-only',
  'canonicalComparisonEligible': false,
  'crossPlatformQuantityStatus': 'source-unit-equivalence-not-yet-bound',
  'legacyRootOmitted': legacyRootOmitted,
  'byRole': {
    for (final probe in probes)
      probe.role: _observeRole(
        probe: probe,
        legacyRootOmitted: legacyRootOmitted,
        captureRoot: captureRoot,
        canonicalFrame: canonicalFrame,
        docsSceneConstructorResult: docsSceneConstructorResult,
      ),
  },
};

Map<String, Object?> _observeRole({
  required ParityProbeSpec probe,
  required bool legacyRootOmitted,
  required Element captureRoot,
  required RenderBox? canonicalFrame,
  Widget? docsSceneConstructorResult,
}) {
  if (probe.fields.isEmpty) {
    return {
      'status': 'unresolved',
      'error': 'MISSING_REQUESTED_FIELDS',
    };
  }
  if (!probe.fields.contains('paddingPx')) {
    return {'status': 'not-requested'};
  }
  if (probe.role != 'root') {
    return {'status': 'unresolved', 'error': 'UNSUPPORTED_PADDING_ROLE'};
  }
  if (legacyRootOmitted) {
    return {
      'status': 'known-structural-omission',
      'reason': 'existing-no-root-chrome',
    };
  }
  try {
    return observeDeclaredRootPadding(
      captureRoot: captureRoot,
      declaringFinder: probe.flutterFinder,
      sourceContract: probe.nativeBoxSource,
      canonicalFrame: canonicalFrame,
      docsSceneConstructorResult: docsSceneConstructorResult,
    );
  } on BoxObservationError catch (error) {
    return {
      'status': 'unresolved',
      'error': error.code,
      'reason': error.reason,
      'declaringFinder': probe.flutterFinder,
      'existingFrameProvenance': _describeFrame(captureRoot, canonicalFrame),
    };
  }
}

Map<String, Object?> _describeFrame(Element captureRoot, RenderBox? frame) {
  if (frame == null) return {'status': 'no-existing-paint-frame'};
  final owners = boxElements(captureRoot)
      .where(
        (element) =>
            element is RenderObjectElement &&
            identical(element.renderObject, frame),
      )
      .toList();
  final paths = <List<String>>[];
  for (final owner in owners) {
    final path = [owner.widget.runtimeType.toString()];
    owner.visitAncestorElements((ancestor) {
      path.add(ancestor.widget.runtimeType.toString());
      return !identical(ancestor, captureRoot);
    });
    paths.add(path);
  }
  return {
    'renderObjectType': frame.runtimeType.toString(),
    'actualOwnerPaths': paths,
  };
}
