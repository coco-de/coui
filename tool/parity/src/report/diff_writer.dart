import 'dart:convert';
import 'dart:io';

import '../diff/comparator.dart';

/// Writes every failing pixel-diff PNG [result] carries to [outDir],
/// following the `<key>.<probeRole>.<label>.diff.png` naming convention —
/// shared by `compare.dart` (#3607) and `report.dart` (#3617) so a PR
/// comment's [`ClassifiedFailure.diffArtifactPaths`] always names a file
/// that actually exists on disk.
void writeComparisonDiffImages(ComparisonResult result, Directory outDir) {
  final diffs = {
    'flutter-regression': result.flutterRegression?.diffImageBytes,
    'web-regression': result.webRegression?.diffImageBytes,
    'parity': result.crossPlatformParity?.diffImageBytes,
  };
  final hasAny = diffs.values.any((bytes) => bytes != null);
  if (!hasAny) return;

  outDir.createSync(recursive: true);
  diffs.forEach((label, bytes) {
    if (bytes == null) return;
    File(
      '${outDir.path}/${result.key}.${result.probeRole}.$label.diff.png',
    ).writeAsBytesSync(bytes);
  });
}

/// Writes the structured property-diff (`어느 필드가 어떻게 다른지`) as JSON
/// to `<key>.<probeRole>.property.diff.json` when [result] has property
/// failures — #3617's completion definition names this artifact
/// explicitly alongside the diff PNGs, so a reviewer investigating a
/// `parity-property` failure has the exact field/value breakdown as a
/// downloadable file, not only the PR comment's inline text.
void writePropertyDiffJson(ComparisonResult result, Directory outDir) {
  final propertyDiff = result.propertyDiff;
  if (propertyDiff == null || !propertyDiff.hasFailures) return;

  outDir.createSync(recursive: true);
  final json = {
    'key': result.key,
    'probeRole': result.probeRole,
    'failures': [
      for (final field in propertyDiff.failures)
        {
          'field': field.field,
          'flutter': field.flutterDescription,
          'web': field.webDescription,
          'token': field.tokenDescription,
          'tokenDivergence': field.tokenDivergence.name,
        },
    ],
  };
  File(
    '${outDir.path}/${result.key}.${result.probeRole}.property.diff.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
}
