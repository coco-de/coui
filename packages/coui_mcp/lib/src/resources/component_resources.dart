import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Component resource handler for granular component documentation
class ComponentResources {
  /// Creates a new ComponentResources with the given [dataPath] and [docsPath].
  ComponentResources({required this.dataPath, required this.docsPath});

  /// Path to the data directory.
  final String dataPath;

  /// Path to the documentation directory.
  final String docsPath;
  Map<String, dynamic>? _componentMetadata;

  /// Get a granular component resource
  Future<Map<String, dynamic>> getResource(String uri) async {
    // `coui://component/{name}/{section}` — the scheme's `//` puts an empty
    // segment before the path when split on '/', so pathSegments (which
    // treats "component" as the URI authority) is used instead of manual
    // index arithmetic.
    final pathSegments = Uri.parse(uri).pathSegments;

    if (pathSegments.isEmpty) {
      throw Exception('Invalid component URI format: $uri');
    }

    final componentName = pathSegments[0];
    final section = pathSegments.length > 1 ? pathSegments[1] : 'overview';

    // Load metadata if not already loaded
    _componentMetadata ??= await _loadComponentMetadata();

    // Find the component
    final components = (_componentMetadata!['components'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final component = components.firstWhere(
      (comp) => comp['name'] == componentName,
      orElse: () => throw Exception('Component not found: $componentName'),
    );

    // Return the requested section
    switch (section) {
      case 'overview':
        return _getOverview(component, uri);
      case 'examples':
        return _getExamples(component, uri);
      case 'api':
        return _getApi(component, uri);
      case 'accessibility':
        return _getAccessibility(component, uri);
      case 'full':
        return _getFull(component, uri);
      default:
        throw Exception('Unknown section: $section');
    }
  }

  /// Get component overview (basic info)
  Map<String, dynamic> _getOverview(
    Map<String, dynamic> component,
    String uri,
  ) {
    final overview = {
      'name': component['name'],
      'displayName': component['displayName'],
      'description': component['description'],
      if (component['category'] != null) 'category': component['category'],
      'exampleCount': component['exampleCount'],
    };

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

  /// Get component examples section
  Future<Map<String, dynamic>> _getExamples(
    Map<String, dynamic> component,
    String uri,
  ) async {
    final examples =
        '''
# ${component['displayName']} Examples

${component['description']}

## Example Count
This component has ${component['exampleCount']} examples available.

## Usage
```dart
import 'package:coui_flutter/coui_flutter.dart';

// Basic usage example for ${component['name']}
// See coui_flutter_llm_guide.md for detailed examples
```

For complete examples, see the full component documentation.
''';

    return {
      'contents': [
        {
          'uri': uri,
          'mimeType': 'text/markdown',
          'text': examples,
        },
      ],
    };
  }

  /// Get component API reference
  Map<String, dynamic> _getApi(Map<String, dynamic> component, String uri) {
    final api = {
      'component': component['name'],
      'displayName': component['displayName'],
      'properties': component['properties'] ?? <String, dynamic>{},
      'variants': component['variants'] ?? <String, dynamic>{},
      'sizes': component['sizes'] ?? <dynamic>[],
    };

    return {
      'contents': [
        {
          'uri': uri,
          'mimeType': 'application/json',
          'text': json.encode(api),
        },
      ],
    };
  }

  /// Get accessibility information
  Map<String, dynamic> _getAccessibility(
    Map<String, dynamic> component,
    String uri,
  ) {
    final accessibility =
        component['accessibility'] as Map<String, dynamic>? ??
        {
          'wcagLevel': 'AA',
          'keyboardNavigable': true,
          'screenReaderSupport': true,
        };

    final accessibilityDoc =
        '''
# ${component['displayName']} Accessibility

## WCAG Compliance
Level: ${accessibility['wcagLevel']}

## Features
- Keyboard Navigation: ${accessibility['keyboardNavigable']}
- Screen Reader Support: ${accessibility['screenReaderSupport']}
${accessibility['minTouchTarget'] != null ? '- Minimum Touch Target: ${accessibility['minTouchTarget']}' : ''}

## Best Practices
- Provide meaningful labels for screen readers
- Ensure sufficient color contrast
- Support keyboard navigation
- Maintain focus indicators
''';

    return {
      'contents': [
        {
          'uri': uri,
          'mimeType': 'text/markdown',
          'text': accessibilityDoc,
        },
      ],
    };
  }

  /// Get full component documentation
  Map<String, dynamic> _getFull(Map<String, dynamic> component, String uri) {
    return {
      'contents': [
        {
          'uri': uri,
          'mimeType': 'application/json',
          'text': json.encode(component),
        },
      ],
    };
  }

  /// Load component metadata from JSON file
  Future<Map<String, dynamic>> _loadComponentMetadata() async {
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

    return {
      'components': components,
    };
  }
}
