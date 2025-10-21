#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:coui_mcp/simple_server.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'docs-path',
      abbr: 'd',
      help: 'Path to the docs directory',
      defaultsTo: _getDefaultDocsPath(),
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message',
    );

  final results = parser.parse(arguments);

  if (results['help'] as bool) {
    print('CoUI Flutter MCP Server');
    print('');
    print('Usage: coui_mcp [options]');
    print('');
    print('Options:');
    print(parser.usage);
    exit(0);
  }

  final docsPath = results['docs-path'] as String;
  final docsDir = Directory(docsPath);

  if (!await docsDir.exists()) {
    stderr.writeln('Error: docs directory not found: $docsPath');
    stderr.writeln('');
    stderr.writeln('Please specify the correct path using --docs-path option');
    exit(1);
  }

  // Verify essential files exist
  final essentialFiles = [
    'coui_flutter_llm_guide.md',
    'coui_flutter_quick_reference.md',
    'component_metadata.json',
  ];

  for (final file in essentialFiles) {
    final filePath = path.join(docsPath, file);
    if (!await File(filePath).exists()) {
      stderr.writeln('Error: Essential file not found: $filePath');
      exit(1);
    }
  }

  stderr.writeln('CoUI MCP Server started successfully');
  stderr.writeln('Docs path: $docsPath');
  stderr.writeln('Listening on STDIO...');
  stderr.writeln('');

  // Create and run the server
  final server = SimpleCouiServer(docsPath: docsPath);
  await server.start();
}

String _getDefaultDocsPath() {
  // Try to find docs directory relative to the script
  final scriptPath = Platform.script.toFilePath();
  final projectRoot = path.dirname(path.dirname(path.dirname(scriptPath)));
  return path.join(projectRoot, 'docs');
}
