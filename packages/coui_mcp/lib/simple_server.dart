import 'dart:convert';
import 'dart:io';

import 'package:coui_mcp/src/resources/category_resources.dart';
import 'package:coui_mcp/src/resources/component_resources.dart';
import 'package:coui_mcp/src/resources/token_resources.dart';
import 'package:coui_mcp/src/tools/component_generator.dart';
import 'package:coui_mcp/src/tools/component_validator.dart';
import 'package:coui_mcp/src/tools/pattern_generator.dart';
import 'package:path/path.dart' as path;

/// Enhanced CoUI MCP Server
///
/// A comprehensive JSON-RPC server that provides CoUI documentation
/// and code generation tools
class SimpleCouiServer {
  /// Creates a new SimpleCouiServer with the given [docsPath].
  SimpleCouiServer({required this.docsPath}) {
    // Initialize resource handlers
    _componentResources = ComponentResources(
      dataPath: path.join(
        path.dirname(docsPath),
        'packages',
        'coui_mcp',
        'data',
      ),
      docsPath: docsPath,
    );
    _tokenResources = TokenResources(
      tokensPath: path.join(
        path.dirname(docsPath),
        'packages',
        'coui_mcp',
        'data',
        'tokens',
      ),
    );
    _categoryResources = CategoryResources(
      dataPath: path.join(
        path.dirname(docsPath),
        'packages',
        'coui_mcp',
        'data',
      ),
      docsPath: docsPath,
    );
  }

  /// Path to the documentation directory.
  final String docsPath;

  /// Component metadata.
  List<Map<String, dynamic>>? _componentMetadata;

  // Resource handlers
  late final ComponentResources _componentResources;
  late final TokenResources _tokenResources;
  late final CategoryResources _categoryResources;

  /// Starts the MCP server and listens for JSON-RPC messages.
  Future<void> start() async {
    // Load component metadata
    await _loadComponentMetadata();

    // Listen to stdin for JSON-RPC messages
    await for (final line
        in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.trim().isEmpty) continue;

      try {
        final request = json.decode(line) as Map<String, dynamic>;
        final response = await handleRequest(request);
        stdout.writeln(json.encode(response));
      } on Exception catch (e) {
        stderr.writeln('Error processing request: $e');
      }
    }
  }

  /// Handles a JSON-RPC request and returns a response.
  Future<Map<String, dynamic>> handleRequest(
    Map<String, dynamic> request,
  ) async {
    final id = request['id'];
    final method = request['method'] as String?;
    final params =
        (request['params'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    try {
      final result = await _handleMethod(method, params);
      return <String, dynamic>{
        'jsonrpc': '2.0',
        'id': id,
        'result': result,
      };
    } on Exception catch (e) {
      return <String, dynamic>{
        'jsonrpc': '2.0',
        'id': id,
        'error': <String, dynamic>{
          'code': -32603,
          'message': e.toString(),
        },
      };
    }
  }

  Future<Map<String, dynamic>> _handleMethod(
    String? method,
    Map<String, dynamic> params,
  ) async {
    switch (method) {
      case 'initialize':
        return <String, dynamic>{
          'protocolVersion': '2024-11-05',
          'capabilities': <String, dynamic>{
            'resources': <String, dynamic>{},
            'tools': <String, dynamic>{},
          },
          'serverInfo': <String, dynamic>{
            'name': 'coui-mcp',
            'version': '1.0.0',
          },
        };

      case 'resources/list':
        return {
          'resources': [
            // Granular Component Resources (NEW - Blueprint-inspired)
            {
              'uri': 'coui://component/{name}/overview',
              'name': 'Component Overview',
              'description': 'Basic component info (~50 lines vs 1,372)',
              'mimeType': 'application/json',
            },
            {
              'uri': 'coui://component/{name}/examples',
              'name': 'Component Examples',
              'description': 'Component usage examples only',
              'mimeType': 'text/markdown',
            },
            {
              'uri': 'coui://component/{name}/api',
              'name': 'Component API',
              'description': 'API reference with properties and variants',
              'mimeType': 'application/json',
            },
            {
              'uri': 'coui://component/{name}/accessibility',
              'name': 'Accessibility Info',
              'description': 'WCAG compliance and a11y guidelines',
              'mimeType': 'text/markdown',
            },
            // Design Token Resources (NEW)
            {
              'uri': 'coui://tokens/colors',
              'name': 'Color Tokens',
              'description': 'Design system color palette',
              'mimeType': 'application/json',
            },
            {
              'uri': 'coui://tokens/spacing',
              'name': 'Spacing Tokens',
              'description': 'Spacing scale (xs, sm, md, lg, xl)',
              'mimeType': 'application/json',
            },
            {
              'uri': 'coui://tokens/typography',
              'name': 'Typography Tokens',
              'description': 'Font families, sizes, weights',
              'mimeType': 'application/json',
            },
            {
              'uri': 'coui://tokens/sizes',
              'name': 'Component Size Tokens',
              'description': 'Button, input, card, avatar sizes',
              'mimeType': 'application/json',
            },
            // Category Resources (NEW)
            {
              'uri': 'coui://category/actions',
              'name': 'Action Components',
              'description': 'Buttons, modals, dropdowns, etc.',
              'mimeType': 'application/json',
            },
            {
              'uri': 'coui://category/inputs',
              'name': 'Input Components',
              'description': 'Forms, checkboxes, selects, etc.',
              'mimeType': 'application/json',
            },
            {
              'uri': 'coui://category/data-display',
              'name': 'Data Display Components',
              'description': 'Cards, tables, avatars, badges, etc.',
              'mimeType': 'application/json',
            },
            {
              'uri': 'coui://category/navigation',
              'name': 'Navigation Components',
              'description': 'Navbars, tabs, breadcrumbs, etc.',
              'mimeType': 'application/json',
            },
            {
              'uri': 'coui://category/feedback',
              'name': 'Feedback Components',
              'description': 'Alerts, snackbars, progress, etc.',
              'mimeType': 'application/json',
            },
            {
              'uri': 'coui://category/all',
              'name': 'All Categories',
              'description': 'Overview of all component categories',
              'mimeType': 'application/json',
            },
            // Legacy Resources (for backward compatibility)
            {
              'uri': 'coui://docs/llm-guide',
              'name': 'CoUI Flutter LLM Guide (Legacy)',
              'description': 'Complete reference guide (1,372 lines)',
              'mimeType': 'text/markdown',
            },
            {
              'uri': 'coui://docs/quick-reference',
              'name': 'Quick Reference',
              'description': 'Quick reference cheat sheet (381 lines)',
              'mimeType': 'text/markdown',
            },
            {
              'uri': 'coui://docs/common-patterns',
              'name': 'Common UI Patterns',
              'description': '8 common screen patterns (960 lines)',
              'mimeType': 'text/markdown',
            },
            {
              'uri': 'coui://docs/component-metadata',
              'name': 'Component Metadata',
              'description': 'JSON metadata for 83 components',
              'mimeType': 'application/json',
            },
          ],
        };

      case 'resources/read':
        final uri = params['uri'] as String?;
        return _readResource(uri);

      case 'tools/list':
        return {
          'tools': [
            // Documentation tools
            {
              'name': 'search_components',
              'description': 'Search CoUI components by name or description',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'query': {'type': 'string'},
                },
                'required': ['query'],
              },
            },
            {
              'name': 'get_component_details',
              'description':
                  'Get detailed information about a specific component',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'component_name': {'type': 'string'},
                },
                'required': ['component_name'],
              },
            },
            // Code generation tools
            {
              'name': 'generate_component',
              'description': 'Generate Flutter code for a CoUI component',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'component_name': {'type': 'string'},
                  'variant': {'type': 'string'},
                  'properties': {'type': 'object'},
                },
                'required': ['component_name'],
              },
            },
            {
              'name': 'generate_screen',
              'description':
                  'Generate a complete Flutter screen with multiple components',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'screen_type': {'type': 'string'},
                  'title': {'type': 'string'},
                  'components': {'type': 'array'},
                },
                'required': ['screen_type'],
              },
            },
            {
              'name': 'generate_form',
              'description': 'Generate a Flutter form with validation',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'form_name': {'type': 'string'},
                  'fields': {'type': 'array'},
                },
                'required': ['form_name', 'fields'],
              },
            },
            {
              'name': 'generate_pattern',
              'description':
                  'Generate a complete screen from a common pattern '
                  '(login, profile, dashboard, etc.)',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'pattern_name': {'type': 'string'},
                  'customization': {'type': 'object'},
                },
                'required': ['pattern_name'],
              },
            },
            {
              'name': 'list_patterns',
              'description': 'List all available screen patterns',
              'inputSchema': {
                'type': 'object',
                'properties': <String, dynamic>{},
              },
            },
            // Styling tools
            {
              'name': 'customize_style',
              'description': 'Generate custom style code for a component',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'component_name': {'type': 'string'},
                  'style_options': {'type': 'object'},
                },
                'required': ['component_name', 'style_options'],
              },
            },
            // Validation tools
            {
              'name': 'validate_component',
              'description': 'Validate component usage and properties',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'component_name': {'type': 'string'},
                  'properties': {'type': 'object'},
                },
                'required': ['component_name'],
              },
            },
            {
              'name': 'analyze_accessibility',
              'description':
                  'Analyze component accessibility and get recommendations',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'component_name': {'type': 'string'},
                  'properties': {'type': 'object'},
                },
                'required': ['component_name'],
              },
            },
            {
              'name': 'suggest_improvements',
              'description': 'Analyze Flutter code and suggest improvements',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'code': {'type': 'string'},
                },
                'required': ['code'],
              },
            },
          ],
        };

      case 'tools/call':
        final name = params['name'] as String?;
        final args = params['arguments'] as Map<String, dynamic>? ?? {};
        return _callTool(name, args);

      default:
        throw Exception('Unknown method: $method');
    }
  }

  Future<Map<String, dynamic>> _readResource(String? uri) async {
    if (uri == null || !uri.startsWith('coui://')) {
      throw Exception('Invalid URI: $uri');
    }

    // Route to granular resource handlers based on URI pattern
    if (uri.startsWith('coui://component/')) {
      return _componentResources.getResource(uri);
    } else if (uri.startsWith('coui://tokens/')) {
      return _tokenResources.getResource(uri);
    } else if (uri.startsWith('coui://category/')) {
      return _categoryResources.getResource(uri);
    }

    // Legacy fallback for backward compatibility
    String? filePath;
    switch (uri) {
      case 'coui://docs/llm-guide':
        filePath = path.join(docsPath, 'llm_guide.md');
      case 'coui://docs/quick-reference':
        filePath = path.join(docsPath, 'quick_reference.md');
      case 'coui://docs/common-patterns':
        filePath = path.join(docsPath, 'common_patterns.md');
      case 'coui://docs/component-metadata':
        // Bundled at data/components/component_metadata.json, not docs/.
        filePath = path.join(
          path.dirname(docsPath),
          'packages',
          'coui_mcp',
          'data',
          'components',
          'component_metadata.json',
        );
      default:
        throw Exception('Unknown URI: $uri');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File not found: $filePath');
    }

    final content = await file.readAsString();
    return {
      'contents': [
        {
          'uri': uri,
          'mimeType': filePath.endsWith('.json')
              ? 'application/json'
              : 'text/markdown',
          'text': content,
        },
      ],
    };
  }

  Future<Map<String, dynamic>> _callTool(
    String? name,
    Map<String, dynamic> args,
  ) async {
    switch (name) {
      // Documentation tools
      case 'search_components':
        return _searchComponents(args);
      case 'get_component_details':
        return _getComponentDetails(args);

      // Code generation tools
      case 'generate_component':
        return ComponentGenerator.generateComponent(args);
      case 'generate_screen':
        return ComponentGenerator.generateScreen(args);
      case 'generate_form':
        return ComponentGenerator.generateForm(args);
      case 'generate_pattern':
        return PatternGenerator.generatePattern(args);
      case 'list_patterns':
        return PatternGenerator.listPatterns(args);

      // Styling tools
      case 'customize_style':
        return ComponentGenerator.customizeStyle(args);

      // Validation tools
      case 'validate_component':
        return ComponentValidator.validateComponent(args);
      case 'analyze_accessibility':
        return ComponentValidator.analyzeAccessibility(args);
      case 'suggest_improvements':
        return ComponentValidator.suggestImprovements(args);

      default:
        throw Exception('Unknown tool: $name');
    }
  }

  Future<Map<String, dynamic>> _searchComponents(
    Map<String, dynamic> args,
  ) async {
    final query = (args['query'] as String).toLowerCase();
    final components = _componentMetadata ?? [];

    final results = components
        .where((comp) {
          final name = (comp['name'] as String).toLowerCase();
          final desc = (comp['description'] as String).toLowerCase();
          return name.contains(query) || desc.contains(query);
        })
        .take(10)
        .toList();

    return {
      'content': [
        {
          'type': 'text',
          'text': json.encode({
            'query': query,
            'results_count': results.length,
            'results': results,
          }),
        },
      ],
    };
  }

  Future<Map<String, dynamic>> _getComponentDetails(
    Map<String, dynamic> args,
  ) async {
    final componentName = (args['component_name'] as String).toLowerCase();
    final components = _componentMetadata ?? [];

    Map<String, dynamic>? component;
    try {
      component = components.firstWhere(
        (comp) => (comp['name'] as String).toLowerCase() == componentName,
      );
    } on Exception catch (e) {
      stderr.writeln('Error getting component details: $e');
      component = null;
    }

    if (component == null) {
      return {
        'content': [
          {
            'type': 'text',
            'text': json.encode({
              'error': 'Component not found: $componentName',
            }),
          },
        ],
      };
    }

    return {
      'content': [
        {
          'type': 'text',
          'text': json.encode(component),
        },
      ],
    };
  }

  Future<void> _loadComponentMetadata() async {
    // Bundled at data/components/component_metadata.json, not docs/.
    final metadataFile = File(
      path.join(
        path.dirname(docsPath),
        'packages',
        'coui_mcp',
        'data',
        'components',
        'component_metadata.json',
      ),
    );
    if (metadataFile.existsSync()) {
      final content = await metadataFile.readAsString();
      final decoded = json.decode(content) as List;
      _componentMetadata = decoded.cast<Map<String, dynamic>>();
    }
  }
}
