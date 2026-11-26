import 'box_observation_source_spec.dart';

/// Source completeness is independent of whether the observed values agree.
({bool nativeComplete, bool webComplete, bool eligible, String? error})
boxObservationPairGate({
  required BoxObservationSourceSpec expected,
  required Map<String, Object?> native,
  required Map<String, Object?> web,
}) {
  final nativeComplete = native['status'] == 'source-complete';
  final webComplete = web['status'] == 'source-complete';
  var error = expected.validationError;
  if (error == null && (!nativeComplete || !webComplete)) {
    error = 'INCOMPLETE_SOURCE_PAIR';
  }
  if (error == null &&
      (native['sourceUnitValidated'] != true ||
          web['sourceUnitValidated'] != true)) {
    error = 'MISSING_UNIT_BINDING_PROOF';
  }
  if (error == null && (native['source'] is! Map || web['source'] is! Map)) {
    error = 'MALFORMED_SOURCE_PAIR';
  }
  if (error == null) {
    try {
      final nativeSource = BoxObservationSourceSpec.fromJson(
        (native['source']! as Map).cast<String, Object?>(),
      );
      final webSource = BoxObservationSourceSpec.fromJson(
        (web['source']! as Map).cast<String, Object?>(),
      );
      if (nativeSource != expected || webSource != expected) {
        error = 'DIFFERENT_SOURCE_UNITS';
      }
    } on FormatException {
      error = 'MALFORMED_SOURCE_PAIR';
    }
  }
  if (error == null && native['legacyRoleEligible'] != true) {
    error = 'LEGACY_STRUCTURAL_ROLE_OMITTED';
  }
  return (
    nativeComplete: nativeComplete,
    webComplete: webComplete,
    eligible: error == null,
    error: error,
  );
}
