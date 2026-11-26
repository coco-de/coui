/// Target platform for code generation.
///
/// CoUI MCP can emit code for two platforms sharing a unified API:
/// - [flutter]: Uses `coui_flutter` (widgets, EdgeInsets, Text)
/// - [jaspr]: Uses `coui_web` (jaspr Components, Tailwind classes, text())
enum PlatformTarget {
  /// Flutter target — emits widget code using `coui_flutter`.
  flutter,

  /// Jaspr target — emits Component code using `coui_web`.
  jaspr;

  /// Parses a target string. Defaults to [flutter] when null/unknown.
  static PlatformTarget parse(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'jaspr':
      case 'web':
      case 'coui_web':
        return PlatformTarget.jaspr;
      case 'flutter':
      case 'coui_flutter':
      case null:
      case '':
        return PlatformTarget.flutter;
      default:
        return PlatformTarget.flutter;
    }
  }

  /// The package import path for this target.
  String get packageImport => switch (this) {
    PlatformTarget.flutter => 'package:coui_flutter/coui_flutter.dart',
    PlatformTarget.jaspr => 'package:coui_web/coui_web.dart',
  };

  /// The framework import path for this target.
  String get frameworkImport => switch (this) {
    PlatformTarget.flutter => 'package:flutter/material.dart',
    PlatformTarget.jaspr => 'package:jaspr/jaspr.dart',
  };

  /// Required imports for the target as a newline-joined string.
  String get requiredImports =>
      "import '$frameworkImport';\nimport '$packageImport';";
}
