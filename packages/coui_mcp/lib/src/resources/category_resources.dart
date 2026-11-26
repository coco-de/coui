import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Category resource handler for component categorization
class CategoryResources {
  /// Category resources constructor
  CategoryResources({required this.dataPath, required this.docsPath});

  /// Path to the data directory (component_metadata.json lives under
  /// `<dataPath>/components/`, not under [docsPath]).
  final String dataPath;

  /// Path to the documentation directory
  final String docsPath;

  /// Categorized components
  Map<String, List<Map<String, dynamic>>>? _categorizedComponents;

  /// Component categories based on functionality
  static const Map<String, List<String>> categoryDefinitions = {
    'actions': [
      'button',
      'fab',
      'icon_button',
      'dropdown',
      'menu',
      'modal',
      'sheet',
      'dialog',
      'alert_dialog',
    ],
    'inputs': [
      'input',
      'text_field',
      'text_area',
      'checkbox',
      'radio',
      'switch',
      'toggle',
      'select',
      'date_picker',
      'time_picker',
      'calendar',
      'slider',
      'rating',
      'autocomplete',
    ],
    'data-display': [
      'card',
      'card_image',
      'table',
      'avatar',
      'avatar_group',
      'badge',
      'chip',
      'list',
      'list_tile',
      'accordion',
      'carousel',
      'timeline',
      'divider',
    ],
    'navigation': [
      'app_bar',
      'navbar',
      'navigation_bar',
      'tab_bar',
      'tabs',
      'breadcrumb',
      'pagination',
      'stepper',
      'sidebar',
      'drawer',
    ],
    'feedback': [
      'alert',
      'snackbar',
      'toast',
      'progress',
      'progress_bar',
      'loading',
      'skeleton',
      'tooltip',
      'popover',
    ],
    'layout': [
      'container',
      'grid',
      'stack',
      'wrap',
      'footer',
      'scaffold',
      'spacer',
    ],
  };

  /// Get category resource
  Future<Map<String, dynamic>> getResource(String uri) async {
    // `coui://category/{category}` — pathSegments treats "category" as the
    // URI authority, so the actual category is pathSegments[0] (see
    // ComponentResources.getResource for why not uri.split('/')).
    final pathSegments = Uri.parse(uri).pathSegments;

    if (pathSegments.isEmpty) {
      throw Exception('Invalid category URI format: $uri');
    }

    final categoryName = pathSegments[0];

    // Load and categorize components if not already done
    _categorizedComponents ??= await _categorizeComponents();

    // Handle special 'all' category
    if (categoryName == 'all') {
      return _getAllCategories(uri);
    }

    // Get specific category
    if (!_categorizedComponents!.containsKey(categoryName)) {
      throw Exception('Unknown category: $categoryName');
    }

    final components = _categorizedComponents![categoryName]!;

    return {
      'contents': [
        {
          'uri': uri,
          'mimeType': 'application/json',
          'text': json.encode({
            'category': categoryName,
            'count': components.length,
            'components': components,
          }),
        },
      ],
    };
  }

  /// Get all categories overview
  Map<String, dynamic> _getAllCategories(String uri) {
    final overview = _categorizedComponents!.map((category, components) {
      return MapEntry(category, {
        'count': components.length,
        'components': components.map((comp) => comp['name']).toList(),
      });
    });

    return {
      'contents': [
        {
          'uri': uri,
          'mimeType': 'application/json',
          'text': json.encode(overview),
        },
      ],
    };
  }

  /// Categorize all components
  Future<Map<String, List<Map<String, dynamic>>>>
  _categorizeComponents() async {
    // Bundled at data/components/component_metadata.json, not under docs/.
    final metadataPath = path.join(
      dataPath,
      'components',
      'component_metadata.json',
    );
    final file = File(metadataPath);

    if (!file.existsSync()) {
      throw Exception('Component metadata file not found: $metadataPath');
    }

    final content = await file.readAsString();
    final components = json.decode(content) as List<dynamic>;

    // Initialize category map
    final categorized = <String, List<Map<String, dynamic>>>{};
    for (final category in categoryDefinitions.keys) {
      categorized[category] = [];
    }
    categorized['other'] = [];

    // Categorize each component
    for (final component in components) {
      final componentMap = component as Map<String, dynamic>;
      final componentName = componentMap['name'] as String;

      // Find matching category
      var foundCategory = false;
      for (final entry in categoryDefinitions.entries) {
        if (entry.value.contains(componentName)) {
          categorized[entry.key]!.add(componentMap);
          foundCategory = true;
          break;
        }
      }

      // If no category found, add to 'other'
      if (!foundCategory) {
        categorized['other']!.add(componentMap);
      }
    }

    return categorized;
  }
}
