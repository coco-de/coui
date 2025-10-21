#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

void main() async {
  final docsDir = Directory(
    '/Users/dongwoo/Development/cocode/uiux/coui/packages/coui_flutter/docs/lib/pages/docs/components',
  );

  final components = <Map<String, dynamic>>[];

  // Find all *_example.dart files
  await for (final entity in docsDir.list()) {
    if (entity is File && entity.path.endsWith('_example.dart')) {
      final filename = entity.path.split('/').last;
      final componentName = filename.replaceAll('_example.dart', '');

      // Read the file to extract description
      final content = await entity.readAsString();
      final descriptionMatch = RegExp(
        r"description:\s*'([^']+)'",
        multiLine: true,
      ).firstMatch(content);

      final description = descriptionMatch?.group(1) ?? 'No description';

      // Check if component has a subdirectory with examples
      final componentDir = Directory('${docsDir.path}/$componentName');
      int exampleCount = 0;

      if (await componentDir.exists()) {
        exampleCount = await componentDir
            .list()
            .where((e) => e is File && e.path.endsWith('.dart'))
            .length;
      }

      // Extract display name
      final displayNameMatch = RegExp(
        r"displayName:\s*'([^']+)'",
        multiLine: true,
      ).firstMatch(content);

      final displayName =
          displayNameMatch?.group(1) ??
          _titleCase(componentName.replaceAll('_', ' '));

      components.add({
        'name': componentName,
        'displayName': displayName,
        'description': description,
        'exampleCount': exampleCount,
        'exampleFile': filename,
      });
    }
  }

  // Sort by name
  components.sort(
    (a, b) => (a['name'] as String).compareTo(b['name'] as String),
  );

  // Write to JSON file
  final outputFile = File(
    '/Users/dongwoo/Development/cocode/uiux/coui/docs/component_metadata.json',
  );
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(components),
  );

  print('Extracted metadata for ${components.length} components');
  print('Output: ${outputFile.path}');

  // Print summary
  print('\nComponents by example count:');
  final byCount = <int, List<String>>{};
  for (final comp in components) {
    final count = comp['exampleCount'] as int;
    byCount.putIfAbsent(count, () => []).add(comp['name'] as String);
  }

  for (final count in byCount.keys.toList()..sort((a, b) => b.compareTo(a))) {
    print('  $count examples: ${byCount[count]!.length} components');
  }
}

String _titleCase(String text) {
  return text
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}
