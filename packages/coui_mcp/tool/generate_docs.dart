#!/usr/bin/env dart

// Script needs to print progress messages.
// ignore_for_file: avoid_print

/// CoUI MCP Documentation Generator.
///
/// This script parses the coui_flutter/docs directory and generates
/// bundled documentation for the coui_mcp package.
///
/// Usage:
///   dart run tool/generate_docs.dart
///
/// This will:
/// 1. Copy component_metadata.json to data/components/
/// 2. Extract example code from docs/lib/pages/docs/components/
/// 3. Copy documentation files to data/docs/
/// 4. Generate token data from theme definitions
/// 5. Extract icon metadata from icon definition files
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Main entry point for the documentation generator.
Future<void> main() async {
  final generator = DocsGenerator();
  await generator.run();
}

/// Documentation generator class.
class DocsGenerator {
  /// Base paths.
  late final String projectRoot;
  late final String couiFlutterPath;
  late final String couiWebPath;
  late final String couiMcpPath;
  late final String docsLibPath;
  late final String outputPath;

  /// Cross-platform class mapping `componentName -> jaspr className`.
  ///
  /// Populated lazily by [_buildJasprClassMap] from the `coui_web`
  /// source tree before metadata enrichment.
  Map<String, String> _jasprClassMap = const {};

  /// Initialize paths.
  void _initPaths() {
    // Find the project root (coui directory)
    final scriptPath = Platform.script.toFilePath();
    couiMcpPath = p.dirname(p.dirname(scriptPath));
    projectRoot = p.dirname(p.dirname(couiMcpPath));
    couiFlutterPath = p.join(projectRoot, 'packages', 'coui_flutter');
    couiWebPath = p.join(projectRoot, 'packages', 'coui_web');
    docsLibPath = p.join(couiFlutterPath, 'docs', 'lib');
    outputPath = p.join(couiMcpPath, 'data');

    print('Project root: $projectRoot');
    print('CoUI Flutter: $couiFlutterPath');
    print('CoUI Web: $couiWebPath');
    print('Docs lib: $docsLibPath');
    print('Output path: $outputPath');
  }

  /// Run the documentation generator.
  Future<void> run() async {
    print('=== CoUI MCP Documentation Generator ===\n');

    _initPaths();

    // Create output directories
    await _createDirectories();

    // Generate documentation
    await _copyComponentMetadata();
    await _extractComponentExamples();
    await _copyDocumentation();
    await _generateTokenData();
    await _extractIconMetadata();

    print('\n=== Documentation generation complete! ===');
  }

  /// Create output directories.
  Future<void> _createDirectories() async {
    print('Creating output directories...');

    final dirs = [
      p.join(outputPath, 'components', 'examples'),
      p.join(outputPath, 'docs'),
      p.join(outputPath, 'tokens'),
      p.join(outputPath, 'icons'),
    ];

    for (final dir in dirs) {
      await Directory(dir).create(recursive: true);
    }

    print('  Created ${dirs.length} directories');
  }

  /// Copy and enhance component metadata.
  Future<void> _copyComponentMetadata() async {
    print('\nProcessing component metadata...');

    final metadataPath = p.join(projectRoot, 'docs', 'component_metadata.json');
    final sourceFile = File(metadataPath);
    if (!sourceFile.existsSync()) {
      print('  WARNING: component_metadata.json not found at $metadataPath');
      return;
    }

    // Build the jaspr class map so we can attach platform info per component.
    _jasprClassMap = _buildJasprClassMap();
    print('  Mapped ${_jasprClassMap.length} jaspr (coui_web) classes');

    final content = await sourceFile.readAsString();
    final components = json.decode(content) as List<dynamic>;

    // Enhance metadata with categories and platform info
    final enhancedComponents = components.map((comp) {
      final component = comp as Map<String, dynamic>;
      final name = component['name'] as String;

      // Add category if not present
      if (!component.containsKey('category')) {
        component['category'] = _categorizeComponent(name);
      }

      // Attach platform info for both flutter and jaspr targets.
      component['platforms'] = _buildPlatformInfo(component);

      return component;
    }).toList();

    // Write enhanced metadata
    final outputFilePath = p.join(
      outputPath,
      'components',
      'component_metadata.json',
    );
    final outputFile = File(outputFilePath);
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(enhancedComponents),
    );

    print('  Processed ${enhancedComponents.length} components');
  }

  /// Scan `coui_web/lib/src/components/` and build a map of
  /// `componentName -> jaspr className`.
  ///
  /// Resolution priority for each component directory:
  /// 1. `co_<name>.dart` containing `class <Name> extends UiComponent`
  /// 2. `<name>.dart` containing `class <Name> extends UiComponent`
  ///
  /// Returns an empty map if `coui_web` is unavailable.
  Map<String, String> _buildJasprClassMap() {
    final result = <String, String>{};
    final componentsRoot = Directory(
      p.join(couiWebPath, 'lib', 'src', 'components'),
    );
    if (!componentsRoot.existsSync()) {
      print('  WARNING: coui_web components dir not found');
      return result;
    }

    // Each direct child of category dirs is a component dir
    final categoryDirs = componentsRoot
        .listSync()
        .whereType<Directory>()
        .toList();

    final classPattern = RegExp(
      r'class\s+(\w+)\s+extends\s+'
      '(?:UiComponent|StatelessComponent|StatefulComponent)',
    );

    for (final categoryDir in categoryDirs) {
      final componentDirs = categoryDir
          .listSync()
          .whereType<Directory>()
          .toList();

      for (final componentDir in componentDirs) {
        final name = p.basename(componentDir.path);
        // Try `co_<name>.dart` first (preferred unified API).
        final preferredFile = File(
          p.join(componentDir.path, 'co_$name.dart'),
        );
        if (preferredFile.existsSync()) {
          final clazz = _firstClass(preferredFile, classPattern);
          if (clazz != null) {
            result[name] = clazz;
            continue;
          }
        }
        // Fallback to `<name>.dart`.
        final fallbackFile = File(p.join(componentDir.path, '$name.dart'));
        if (fallbackFile.existsSync()) {
          final clazz = _firstClass(fallbackFile, classPattern);
          if (clazz != null) {
            result[name] = clazz;
          }
        }
      }
    }

    return result;
  }

  /// Returns the first matching class name in [file], or null.
  String? _firstClass(File file, RegExp pattern) {
    try {
      final content = file.readAsStringSync();
      final match = pattern.firstMatch(content);
      return match?.group(1);
    } on FileSystemException {
      return null;
    }
  }

  /// Builds the `platforms` block for a component.
  Map<String, dynamic> _buildPlatformInfo(Map<String, dynamic> component) {
    final name = component['name'] as String;
    final flutterClass = _snakeToPascal(name);
    final jasprClass = _jasprClassMap[name];

    return {
      'flutter': {
        'package': 'package:coui_flutter/coui_flutter.dart',
        'className': flutterClass,
        'supported': true,
      },
      'jaspr': {
        'package': 'package:coui_web/coui_web.dart',
        'className': jasprClass,
        'supported': jasprClass != null,
      },
    };
  }

  /// Converts `snake_case` to `PascalCase`.
  String _snakeToPascal(String snakeCase) {
    return snakeCase
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join();
  }

  /// Categorize component by name.
  String _categorizeComponent(String name) {
    const categories = {
      'actions': [
        'button',
        'icon_button',
        'floating_action_button',
        'toggle',
        'switch',
      ],
      'inputs': [
        'input',
        'text_area',
        'select',
        'checkbox',
        'radio',
        'slider',
        'date_picker',
        'time_picker',
        'color_picker',
        'file_picker',
        'autocomplete',
        'phone_input',
        'number_input',
        'input_otp',
        'formatted_input',
        'star_rating',
        'chip_input',
        'multiselect',
        'item_picker',
      ],
      'data-display': [
        'table',
        'card',
        'badge',
        'avatar',
        'avatar_group',
        'calendar',
        'carousel',
        'timeline',
        'progress',
        'circular_progress',
        'linear_progress',
        'skeleton',
        'code_snippet',
        'number_ticker',
        'dot_indicator',
        'tracker',
        'chart',
      ],
      'navigation': [
        'tabs',
        'tab_list',
        'tab_pane',
        'breadcrumb',
        'pagination',
        'stepper',
        'steps',
        'navigation_bar',
        'navigation_menu',
        'navigation_rail',
        'navigation_sidebar',
        'menubar',
        'sidebar_nav',
        'expandable_sidebar',
      ],
      'feedback': [
        'alert',
        'alert_dialog',
        'dialog',
        'toast',
        'tooltip',
        'popover',
        'hover_card',
        'sheet',
        'drawer',
        'context_menu',
        'dropdown_menu',
        'command',
        'menu',
      ],
      'layout': [
        'accordion',
        'collapsible',
        'divider',
        'resizable',
        'scaffold',
        'app',
        'app_bar',
        'card_image',
        'tree',
        'sortable',
        'wrapper',
        'window',
        'material',
        'swiper',
      ],
    };

    for (final entry in categories.entries) {
      if (entry.value.contains(name)) {
        return entry.key;
      }
    }

    return 'other';
  }

  /// Extract example code from component files.
  Future<void> _extractComponentExamples() async {
    print('\nExtracting component examples...');

    final componentsDir = Directory(
      p.join(docsLibPath, 'pages', 'docs', 'components'),
    );

    if (!componentsDir.existsSync()) {
      print('  WARNING: Components directory not found');
      return;
    }

    var totalExamples = 0;

    // Find all component directories
    final componentDirs = componentsDir
        .listSync()
        .whereType<Directory>()
        .toList();

    for (final componentDir in componentDirs) {
      final componentName = p.basename(componentDir.path);
      final examples = await _extractExamplesFromDir(
        componentDir,
        componentName,
      );

      if (examples.isNotEmpty) {
        // Write examples to markdown file
        final examplesFilePath = p.join(
          outputPath,
          'components',
          'examples',
          '${componentName}_examples.md',
        );
        final examplesFile = File(examplesFilePath);
        final markdown = _formatExamplesAsMarkdown(componentName, examples);
        await examplesFile.writeAsString(markdown);
        totalExamples += examples.length;
      }
    }

    final dirCount = componentDirs.length;
    print('  Extracted $totalExamples examples from $dirCount components');
  }

  /// Extract examples from a component directory.
  Future<List<Map<String, String>>> _extractExamplesFromDir(
    Directory dir,
    String componentName,
  ) async {
    final examples = <Map<String, String>>[];

    // Find example files
    final exampleFiles =
        dir
            .listSync()
            .whereType<File>()
            .where(
              (f) => f.path.endsWith('.dart') && f.path.contains('_example_'),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in exampleFiles) {
      final content = await file.readAsString();
      final fileName = p.basename(file.path);

      // Extract the example number
      final match = RegExp(r'_example_(\d+)\.dart$').firstMatch(fileName);
      final exampleNum = match?.group(1) ?? '1';

      // Extract class name and build method
      final classMatch = RegExp(r'class\s+(\w+)\s+extends').firstMatch(content);
      final className = classMatch?.group(1) ?? 'Example$exampleNum';

      // Extract title from wrapper file if exists
      final title = _extractExampleTitle(componentName, exampleNum);

      examples.add({
        'number': exampleNum,
        'className': className,
        'title': title,
        'code': content,
        'fileName': fileName,
      });
    }

    return examples;
  }

  /// Extract example title from the wrapper example file.
  String _extractExampleTitle(String componentName, String exampleNum) {
    // Default title based on example number
    final defaultTitles = {
      '1': 'Basic Example',
      '2': 'Variant Example',
      '3': 'Custom Example',
    };

    return defaultTitles[exampleNum] ?? 'Example $exampleNum';
  }

  /// Format examples as markdown.
  String _formatExamplesAsMarkdown(
    String componentName,
    List<Map<String, String>> examples,
  ) {
    final displayName = _toDisplayName(componentName);
    final description =
        'This document contains example code for the $componentName component.';

    final buffer = StringBuffer()
      // Header
      ..writeln('# $displayName Examples')
      ..writeln()
      ..writeln(description)
      ..writeln()
      // Table of contents
      ..writeln('## Table of Contents')
      ..writeln();

    for (final example in examples) {
      final num = example['number'];
      final title = example['title'];
      buffer.writeln('- [Example $num: $title](#example-$num)');
    }
    buffer.writeln();

    // Examples
    for (final example in examples) {
      final num = example['number'];
      final title = example['title'];
      final code = example['code'];

      buffer
        ..writeln('## Example $num')
        ..writeln()
        ..writeln('**$title**')
        ..writeln()
        ..writeln('```dart')
        ..writeln(code)
        ..writeln('```')
        ..writeln();
    }

    return buffer.toString();
  }

  /// Convert snake_case to Display Name.
  String _toDisplayName(String name) {
    return name
        .split('_')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }

  /// Copy documentation files.
  Future<void> _copyDocumentation() async {
    print('\nCopying documentation files...');

    final docsSource = p.join(projectRoot, 'docs');
    final docFiles = {
      'coui_flutter_llm_guide.md': 'llm_guide.md',
      'coui_flutter_quick_reference.md': 'quick_reference.md',
      'coui_flutter_common_patterns.md': 'common_patterns.md',
    };

    var copied = 0;
    for (final entry in docFiles.entries) {
      final sourceFile = File(p.join(docsSource, entry.key));
      if (sourceFile.existsSync()) {
        final destFile = File(p.join(outputPath, 'docs', entry.value));
        await sourceFile.copy(destFile.path);
        copied++;
      } else {
        print('  WARNING: ${entry.key} not found');
      }
    }

    print('  Copied $copied documentation files');
  }

  /// Generate token data from theme definitions.
  Future<void> _generateTokenData() async {
    print('\nGenerating token data...');

    // Generate color tokens
    final colors = _generateColorTokens();
    await _writeJsonFile(
      p.join(outputPath, 'tokens', 'colors.json'),
      colors,
    );

    // Generate spacing tokens
    final spacing = _generateSpacingTokens();
    await _writeJsonFile(
      p.join(outputPath, 'tokens', 'spacing.json'),
      spacing,
    );

    // Generate typography tokens
    final typography = _generateTypographyTokens();
    await _writeJsonFile(
      p.join(outputPath, 'tokens', 'typography.json'),
      typography,
    );

    // Generate size tokens
    final sizes = _generateSizeTokens();
    await _writeJsonFile(
      p.join(outputPath, 'tokens', 'sizes.json'),
      sizes,
    );

    print('  Generated 4 token files');
  }

  /// Generate color tokens.
  Map<String, dynamic> _generateColorTokens() {
    const shades = [
      '50',
      '100',
      '200',
      '300',
      '400',
      '500',
      '600',
      '700',
      '800',
      '900',
    ];

    return {
      'primary': {
        'description': 'Primary brand color',
        'shades': shades,
      },
      'secondary': {
        'description': 'Secondary brand color',
        'shades': shades,
      },
      'destructive': {
        'description': 'Destructive/error color',
        'usage': 'Used for error states and destructive actions',
      },
      'muted': {
        'description': 'Muted/disabled color',
        'usage': 'Used for disabled states and secondary text',
      },
      'accent': {
        'description': 'Accent color',
        'usage': 'Used for highlighting and emphasis',
      },
      'background': {
        'description': 'Background colors',
        'variants': ['default', 'card', 'popover'],
      },
      'foreground': {
        'description': 'Foreground/text colors',
        'variants': ['default', 'muted', 'accent'],
      },
      'border': {
        'description': 'Border colors',
        'variants': ['default', 'input', 'ring'],
      },
    };
  }

  /// Generate spacing tokens.
  Map<String, dynamic> _generateSpacingTokens() {
    return {
      'none': {'value': 0, 'description': 'No spacing'},
      'xs': {'value': 4, 'description': 'Extra small spacing'},
      'sm': {'value': 8, 'description': 'Small spacing'},
      'md': {'value': 16, 'description': 'Medium spacing (default)'},
      'lg': {'value': 24, 'description': 'Large spacing'},
      'xl': {'value': 32, 'description': 'Extra large spacing'},
      'xxl': {'value': 48, 'description': 'Double extra large spacing'},
    };
  }

  /// Generate typography tokens.
  Map<String, dynamic> _generateTypographyTokens() {
    return {
      'fontFamily': {
        'sans': 'Geist Sans, system-ui, sans-serif',
        'mono': 'Geist Mono, monospace',
      },
      'fontSize': {
        'xs': {'size': 12, 'lineHeight': 16},
        'sm': {'size': 14, 'lineHeight': 20},
        'base': {'size': 16, 'lineHeight': 24},
        'lg': {'size': 18, 'lineHeight': 28},
        'xl': {'size': 20, 'lineHeight': 28},
        '2xl': {'size': 24, 'lineHeight': 32},
        '3xl': {'size': 30, 'lineHeight': 36},
        '4xl': {'size': 36, 'lineHeight': 40},
      },
      'fontWeight': {
        'light': 300,
        'normal': 400,
        'medium': 500,
        'semibold': 600,
        'bold': 700,
      },
    };
  }

  /// Generate size tokens.
  Map<String, dynamic> _generateSizeTokens() {
    return {
      'component': {
        'xs': {'height': 24, 'padding': 8},
        'sm': {'height': 32, 'padding': 12},
        'md': {'height': 40, 'padding': 16},
        'lg': {'height': 48, 'padding': 20},
        'xl': {'height': 56, 'padding': 24},
      },
      'icon': {
        'xs': 12,
        'sm': 16,
        'md': 20,
        'lg': 24,
        'xl': 32,
      },
      'radius': {
        'none': 0,
        'sm': 4,
        'md': 8,
        'lg': 12,
        'xl': 16,
        'full': 9999,
      },
    };
  }

  /// Extract icon metadata from icon definition files.
  Future<void> _extractIconMetadata() async {
    print('\nExtracting icon metadata...');

    final iconFiles = {
      'bootstrap_icons.dart': 'bootstrap.json',
      'lucide_icons.dart': 'lucide.json',
      'radix_icons.dart': 'radix.json',
      'hero_icons.dart': 'hero.json',
    };

    for (final entry in iconFiles.entries) {
      final sourceFile = File(p.join(docsLibPath, entry.key));
      if (sourceFile.existsSync()) {
        final icons = await _extractIconsFromFile(sourceFile);
        await _writeJsonFile(
          p.join(outputPath, 'icons', entry.value),
          {'count': icons.length, 'icons': icons},
        );
        print('  Extracted ${icons.length} icons from ${entry.key}');
      }
    }
  }

  /// Extract icon names from an icon definition file.
  Future<List<String>> _extractIconsFromFile(File file) async {
    final content = await file.readAsString();
    final icons = <String>[];

    // Match icon definitions in Map format: 'iconName': ClassName.iconName
    final mapPattern = RegExp(r"'(\w+)':\s*\w+\.\w+");
    for (final match in mapPattern.allMatches(content)) {
      final iconName = match.group(1);
      if (iconName != null) {
        icons.add(iconName);
      }
    }

    // Match icon definitions in List format: ClassName.iconName
    if (icons.isEmpty) {
      final listPattern = RegExp(r'\w+Icons\.(\w+)');
      for (final match in listPattern.allMatches(content)) {
        final iconName = match.group(1);
        if (iconName != null) {
          icons.add(iconName);
        }
      }
    }

    // Also match static const IconData format as fallback
    if (icons.isEmpty) {
      final staticPattern = RegExp(r'static\s+const\s+IconData\s+(\w+)\s*=');
      for (final match in staticPattern.allMatches(content)) {
        final iconName = match.group(1);
        if (iconName != null) {
          icons.add(iconName);
        }
      }
    }

    return icons;
  }

  /// Write JSON file with pretty formatting.
  Future<void> _writeJsonFile(String path, dynamic data) async {
    final file = File(path);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }
}
