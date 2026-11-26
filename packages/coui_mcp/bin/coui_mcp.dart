#!/usr/bin/env dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:coui_mcp/src/config/coui_mcp_config.dart';
import 'package:coui_mcp/src/server/coui_mcp_server.dart';

/// CoUI MCP Server CLI entry point.
///
/// Supports multiple configuration methods:
/// 1. Command-line options
/// 2. Environment variables (COUI_DATA_PATH, COUI_DOCS_PATH)
/// 3. Built-in data (default)
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'data-path',
      help: 'Path to custom data directory',
    )
    ..addOption(
      'docs-path',
      abbr: 'd',
      help: 'Path to documentation directory (legacy)',
    )
    ..addFlag(
      'use-builtin',
      defaultsTo: true,
      help: 'Use built-in bundled data (default: true)',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message',
    )
    ..addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Show version information',
    );

  final results = parser.parse(arguments);

  if (results['version'] as bool) {
    stderr.writeln('CoUI MCP Server v2.1.0');
    exit(0);
  }

  if (results['help'] as bool) {
    _printHelp(parser);
    exit(0);
  }

  // Build configuration from CLI options and environment
  final config = _buildConfig(results);

  // Validate configuration
  final errors = config.validate();
  if (errors.isNotEmpty) {
    stderr
      ..writeln('Configuration errors:')
      ..writeln();
    for (final error in errors) {
      stderr.writeln('  - $error');
    }
    stderr.writeln();
    stderr.writeln('Use --help for usage information.');
    exit(1);
  }

  // Start server
  stderr
    ..writeln('CoUI MCP Server v2.1.0')
    ..writeln('Data path: ${config.resolvedDataPath}')
    ..writeln('Docs path: ${config.resolvedDocsPath}')
    ..writeln('Listening on STDIO...')
    ..writeln();

  final server = CouiMcpServer(config: config);
  await server.start();
}

void _printHelp(ArgParser parser) {
  stderr
    ..writeln('CoUI MCP Server')
    ..writeln()
    ..writeln(
      'A Model Context Protocol server for CoUI components '
      '(Flutter and Jaspr/Web).',
    )
    ..writeln('Provides component documentation, code generation, and')
    ..writeln('validation tools.')
    ..writeln()
    ..writeln('Usage: coui_mcp [options]')
    ..writeln()
    ..writeln('Options:')
    ..writeln(parser.usage)
    ..writeln()
    ..writeln('Environment Variables:')
    ..writeln('  COUI_DATA_PATH    Path to custom data directory')
    ..writeln('  COUI_DOCS_PATH    Path to custom documentation directory')
    ..writeln('  COUI_USE_BUILTIN  Set to "false" to disable built-in data')
    ..writeln()
    ..writeln('Examples:')
    ..writeln('  # Use built-in data (default)')
    ..writeln('  coui_mcp')
    ..writeln()
    ..writeln('  # Use custom data directory')
    ..writeln('  coui_mcp --data-path /path/to/custom/data')
    ..writeln()
    ..writeln('  # Use environment variables')
    ..writeln('  COUI_DATA_PATH=/path/to/data coui_mcp')
    ..writeln()
    ..writeln('Configuration Priority:')
    ..writeln('  1. Command-line options (highest)')
    ..writeln('  2. Environment variables')
    ..writeln('  3. Built-in data (default)');
}

CouiMcpConfig _buildConfig(ArgResults results) {
  // Start with environment-based config
  final envConfig = CouiMcpConfig.fromEnvironment();

  // CLI options override environment
  final cliDataPath = results['data-path'] as String?;
  final cliDocsPath = results['docs-path'] as String?;
  final cliUseBuiltin = results['use-builtin'] as bool;

  // Build final config with CLI overrides
  return CouiMcpConfig(
    dataPath: cliDataPath ?? envConfig.dataPath,
    docsPath: cliDocsPath ?? envConfig.docsPath,
    useBuiltinData: cliUseBuiltin && envConfig.useBuiltinData,
  );
}
