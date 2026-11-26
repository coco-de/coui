import 'package:meta/meta.dart';

import 'box_observation_source_spec.dart';
import 'property_field.dart';

/// What to measure for one role inside a component's render, declared for
/// both platforms at once so a manifest entry is a single statement of
/// intent rather than two independently-drifting ones.
///
/// Source: `.bmad/architecture-*.md` Data Architecture → `ProbeSpec`.
///
/// Every entry emits the generic `root` role. Centred, width-capped previews
/// also declare a `stage` role: both root-body and full-stage pixels must pass.
/// Other component-specific sub-roles (a trigger, a focus ring,
/// an item label — the kind SPIKE-5's `widget_tree_probe.dart` extracts for
/// Command/DatePicker/Dialog) are a capture-backend concern: they need the
/// component's actual widget tree in hand to say "the label finder is a
/// specific item's text", which a pure-Dart manifest deriving from the
/// catalog cannot know. Adding more roles here without a consumer that
/// reads them would be unverifiable precision, not coverage.
@immutable
class ProbeSpec {
  const ProbeSpec({
    required this.role,
    required this.webSelector,
    required this.flutterFinder,
    required this.fields,
    this.nativeBoxSource,
    this.boxObservationSource,
  });

  /// Reconstructs a [ProbeSpec] from [toJson]'s output.
  factory ProbeSpec.fromJson(Map<String, Object?> json) => ProbeSpec(
    role: json['role']! as String,
    webSelector: json['webSelector']! as String,
    flutterFinder: json['flutterFinder']! as String,
    nativeBoxSource: json['nativeBoxSource'] as String?,
    boxObservationSource: json['boxObservationSource'] == null
        ? null
        : BoxObservationSourceSpec.fromJson(
            (json['boxObservationSource']! as Map).cast<String, Object?>(),
          ),
    fields: {
      for (final name in (json['fields']! as List).cast<String>())
        .values.byName(name),
    },
  );

  /// What this probe measures, e.g. `root`.
  final String role;

  /// CSS selector against the Web capture harness page.
  final String webSelector;

  /// A finder identifier a Flutter capture backend resolves against the
  /// pumped widget tree — not literal Dart source, a wire-format string
  /// (`byType:Command`) the backend's own lookup owns the meaning of.
  final String flutterFinder;

  /// Which normalized fields are expected for this role.
  final Set<PropertyField> fields;

  /// Source semantics for Native box observations, never expected style values.
  /// Historical manifests may omit this; new observations report the missing
  /// declaration rather than manufacturing a padding value.
  final String? nativeBoxSource;

  final BoxObservationSourceSpec? boxObservationSource;

  Map<String, Object?> toJson() => {
    'role': role,
    'webSelector': webSelector,
    'flutterFinder': flutterFinder,
    if (nativeBoxSource != null) 'nativeBoxSource': nativeBoxSource,
    if (boxObservationSource != null)
      'boxObservationSource': boxObservationSource!.toJson(),
    'fields': (fields.map((f) => f.name).toList()..sort()),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProbeSpec &&
          role == other.role &&
          webSelector == other.webSelector &&
          flutterFinder == other.flutterFinder &&
          nativeBoxSource == other.nativeBoxSource &&
          boxObservationSource == other.boxObservationSource &&
          fields.length == other.fields.length &&
          fields.containsAll(other.fields);

  @override
  int get hashCode => Object.hash(
    role,
    webSelector,
    flutterFinder,
    nativeBoxSource,
    boxObservationSource,
  );

  @override
  String toString() => 'ProbeSpec(${toJson()})';
}

/// The root probe every matrix entry gets — "this component rendered at
/// all, and here is where to look".
///
/// The web selector is scoped to a single `data-parity-key` attribute the
/// Web capture harness (#3605) stamps on a wrapper *around* the rendered
/// component (so two entries captured on the same harness page, should
/// that ever happen, cannot cross-select each other), then `> *` selects
/// the wrapper's one real child — the component's own rendered root —
/// rather than the inert wrapper itself. This selector is a complete,
/// self-contained CSS query for its target the same way any future
/// sub-role probe's (a trigger, a focus ring, an item label) `webSelector`
/// will be: the capture backend does not special-case `role == 'root'`,
/// it queries whatever selector each `ProbeSpec` states.
ProbeSpec rootProbeSpec({
  required String key,
  required String flutterClassName,
  BoxObservationSourceSpec? boxObservationSource,
}) => .new(
  role: 'root',
  webSelector: '[data-parity-key="$key"] > *',
  flutterFinder: 'byType:$flutterClassName',
  nativeBoxSource: 'renderer-frame-padding-v1',
  boxObservationSource: boxObservationSource,
  fields: PropertyField.all,
);
