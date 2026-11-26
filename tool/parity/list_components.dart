#!/usr/bin/env dart

/// Prints one docs-registered component slug per line (#3620) — the
/// nightly sweep's "docs_site LivePreview 전체 페이지 캡처" step shells
/// out to `tool/screenshot.dart` once per component, and needs the
/// component list from the same single source of truth
/// (`docs_core/lib/shared/component_catalog.dart`) every other parity
/// derivation already reads, rather than a hand-maintained list in the
/// workflow YAML that would rot as the catalog grows past it
/// (`core/theme-axis-composition.md`'s "match-status 를 정적 목록으로
/// 단언하지 마라", the same reasoning `parity_manifest.dart`'s own doc
/// comment already applies to the verification matrix).
///
/// Usage:
///   `dart run tool/parity/list_components.dart`
library;

import 'dart:io';

import 'package:docs_core/shared/component_catalog.dart';

void main() {
  for (final entry in kDocsComponentEntries) {
    stdout.writeln(entry.slug);
  }
}
