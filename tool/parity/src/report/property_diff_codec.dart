// #3861 — JSON codec for `PropertyDiffResult`/`FieldDivergence`.
//
// Kept out of `property_diff.dart` on purpose: that file is the comparator
// itself (#3607's own tolerance math) — #3861's own scope note excludes it
// ("비교기 로직도 범위 밖 — 이 이슈는 집계·보고다"). This file only
// serializes the *result* of that math so `ParityReport` (#3861) can
// persist a run to disk and `report_comparison.dart` (#3861) can reload
// two runs to compute a paired intersection — no comparison logic lives
// here, only encode/decode.
import '../diff/property_diff.dart';

Map<String, Object?> fieldDivergenceToJson(FieldDivergence f) => {
  'field': f.field,
  'matches': f.matches,
  'flutter': f.flutterDescription,
  'web': f.webDescription,
  'token': f.tokenDescription,
  'tokenDivergence': f.tokenDivergence.name,
};

FieldDivergence fieldDivergenceFromJson(Map<String, Object?> json) =>
    FieldDivergence(
      field: json['field']! as String,
      matches: json['matches']! as bool,
      flutterDescription: json['flutter']! as String,
      webDescription: json['web']! as String,
      tokenDescription: json['token'] as String?,
      tokenDivergence: TokenDivergence.values.byName(
        json['tokenDivergence']! as String,
      ),
    );

Map<String, Object?> propertyDiffResultToJson(PropertyDiffResult r) => {
  'key': r.key,
  'probeRole': r.probeRole,
  'fields': [for (final f in r.fields) fieldDivergenceToJson(f)],
};

PropertyDiffResult propertyDiffResultFromJson(Map<String, Object?> json) =>
    PropertyDiffResult(
      key: json['key']! as String,
      probeRole: json['probeRole']! as String,
      fields: [
        for (final raw in json['fields']! as List)
          fieldDivergenceFromJson((raw as Map).cast()),
      ],
    );
