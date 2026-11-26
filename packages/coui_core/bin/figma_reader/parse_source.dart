// `analyzer` and `pub_semver` are direct `dev_dependencies` of this package
// (see `pubspec.yaml`); the lint does not tell `bin/`-only dev tooling from
// `lib/` code, so it still flags these imports — see `ast_value.dart`.
// ignore_for_file: depend_on_referenced_packages
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:pub_semver/pub_semver.dart';

/// The language version the kit's sources are written for — the floor of the
/// SDK constraint in their `pubspec.yaml`.
///
/// `parseString` reads a source as the analyzer's *latest* language version
/// unless told otherwise, and a later language version can reject what this
/// one allows (a `final` parameter on a function is a syntax error from 3.13
/// on). The sources do not change when the toolchain does, so the readers
/// parse them as what they were written as.
final Version kSourceLanguageVersion = Version(3, 11, 0);

/// Parses [content] — a source file of this repository — as the language it
/// was written in.
ParseStringResult parseSource({
  required String content,
  required String path,
}) => parseString(
  content: content,
  path: path,
  featureSet: FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: kSourceLanguageVersion,
    flags: const [],
  ),
);
