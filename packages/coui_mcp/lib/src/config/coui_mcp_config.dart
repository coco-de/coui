import 'dart:io';

import 'package:path/path.dart' as p;

/// Configuration for CoUI MCP server.
///
/// Supports multiple configuration sources with the following priority:
/// 1. Explicit parameters (highest priority)
/// 2. Environment variables
/// 3. Built-in data (default)
class CouiMcpConfig {
  /// Creates a new configuration with explicit paths.
  CouiMcpConfig({
    this.dataPath,
    this.docsPath,
    this.useBuiltinData = true,
  });

  /// Creates a configuration using built-in data only.
  factory CouiMcpConfig.defaults() {
    return CouiMcpConfig();
  }

  /// Creates a configuration from environment variables.
  ///
  /// Supported environment variables:
  /// - `COUI_DATA_PATH`: Path to custom data directory
  /// - `COUI_DOCS_PATH`: Path to custom documentation directory
  /// - `COUI_USE_BUILTIN`: Set to "false" to disable built-in data
  factory CouiMcpConfig.fromEnvironment() {
    final dataPath = Platform.environment['COUI_DATA_PATH'];
    final docsPath = Platform.environment['COUI_DOCS_PATH'];
    final useBuiltinEnv = Platform.environment['COUI_USE_BUILTIN'];
    final useBuiltin = useBuiltinEnv?.toLowerCase() != 'false';

    return CouiMcpConfig(
      dataPath: dataPath,
      docsPath: docsPath,
      useBuiltinData: useBuiltin,
    );
  }

  /// Custom data directory path.
  ///
  /// If provided, this path will be used instead of built-in data.
  final String? dataPath;

  /// Custom documentation directory path.
  ///
  /// If provided, this path will be used for documentation files.
  final String? docsPath;

  /// Whether to use built-in data as fallback.
  ///
  /// When true (default), the server will use the bundled data
  /// from the package's `data/` directory.
  final bool useBuiltinData;

  /// Gets the resolved data path.
  ///
  /// Returns the custom data path if provided, otherwise returns
  /// the built-in data path from the package.
  String get resolvedDataPath {
    if (dataPath != null && dataPath!.isNotEmpty) {
      return dataPath!;
    }
    return _getBuiltinDataPath();
  }

  /// Gets the resolved docs path.
  ///
  /// Returns the custom docs path if provided, otherwise returns
  /// the built-in docs path from the data directory.
  String get resolvedDocsPath {
    if (docsPath != null && docsPath!.isNotEmpty) {
      return docsPath!;
    }
    return p.join(resolvedDataPath, 'docs');
  }

  /// Gets the components data path.
  String get componentsPath => p.join(resolvedDataPath, 'components');

  /// Gets the component examples path.
  String get examplesPath => p.join(componentsPath, 'examples');

  /// Gets the tokens data path.
  String get tokensPath => p.join(resolvedDataPath, 'tokens');

  /// Gets the icons data path.
  String get iconsPath => p.join(resolvedDataPath, 'icons');

  /// Validates the configuration.
  ///
  /// Returns a list of validation errors, or an empty list if valid.
  List<String> validate() {
    final errors = <String>[];

    if (dataPath != null && !Directory(dataPath!).existsSync()) {
      errors.add('Data path does not exist: $dataPath');
    }

    if (docsPath != null && !Directory(docsPath!).existsSync()) {
      errors.add('Docs path does not exist: $docsPath');
    }

    if (!useBuiltinData &&
        dataPath == null &&
        !Directory(_getBuiltinDataPath()).existsSync()) {
      errors.add('Built-in data not available and no custom data path set');
    }

    return errors;
  }

  /// Checks if the configuration is valid.
  bool get isValid => validate().isEmpty;

  /// Gets the path to the built-in data directory.
  ///
  /// This resolves the path relative to the package location.
  String _getBuiltinDataPath() {
    // When running as a dependency, find the package's data directory
    // Try to find the package root by looking for pubspec.yaml
    final scriptPath = Platform.script.toFilePath();

    // If running from bin/, go up to package root
    final packageRoot = p.dirname(p.dirname(scriptPath));

    // Check if we're in the coui_mcp package
    final pubspecPath = p.join(packageRoot, 'pubspec.yaml');
    if (File(pubspecPath).existsSync()) {
      final pubspec = File(pubspecPath).readAsStringSync();
      if (pubspec.contains('name: coui_mcp')) {
        return p.join(packageRoot, 'data');
      }
    }

    // Fallback: try to find data directory relative to script
    // This handles cases where the package is installed as a dependency
    final possiblePaths = [
      p.join(packageRoot, 'data'),
      p.join(p.dirname(packageRoot), 'coui_mcp', 'data'),
      p.join(Directory.current.path, '.dart_tool', 'package_config.json'),
    ];

    for (final path in possiblePaths) {
      if (Directory(path).existsSync()) {
        return path;
      }
    }

    // Default fallback
    return p.join(packageRoot, 'data');
  }

  /// Creates a copy of this configuration with updated values.
  CouiMcpConfig copyWith({
    String? dataPath,
    String? docsPath,
    bool? useBuiltinData,
  }) {
    return CouiMcpConfig(
      dataPath: dataPath ?? this.dataPath,
      docsPath: docsPath ?? this.docsPath,
      useBuiltinData: useBuiltinData ?? this.useBuiltinData,
    );
  }

  @override
  String toString() {
    return 'CouiMcpConfig('
        'dataPath: $dataPath, '
        'docsPath: $docsPath, '
        'useBuiltinData: $useBuiltinData, '
        'resolvedDataPath: $resolvedDataPath)';
  }
}
