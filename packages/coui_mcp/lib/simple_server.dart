import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Simple CoUI MCP Server
///
/// A minimal JSON-RPC server that provides CoUI Flutter documentation
class SimpleCouiServer {
  SimpleCouiServer({required this.docsPath});

  final String docsPath;
  List<Map<String, dynamic>>? _componentMetadata;

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
      } catch (e) {
        stderr.writeln('Error processing request: $e');
      }
    }
  }

  Future<Map<String, dynamic>> handleRequest(
      Map<String, dynamic> request) async {
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
    } catch (e) {
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
            'name': 'coui-mcp-server',
            'version': '1.0.0',
          },
        };

      case 'resources/list':
        return {
          'resources': [
            {
              'uri': 'coui://docs/llm-guide',
              'name': 'CoUI Flutter LLM Guide',
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
        return await _readResource(uri);

      case 'tools/list':
        return {
          'tools': [
            {
              'name': 'search_components',
              'description': 'Search CoUI components',
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
              'description': 'Get component details',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'component_name': {'type': 'string'},
                },
                'required': ['component_name'],
              },
            },
          ],
        };

      case 'tools/call':
        final name = params['name'] as String?;
        final args = params['arguments'] as Map<String, dynamic>? ?? {};
        return await _callTool(name, args);

      default:
        throw 'Unknown method: $method';
    }
  }

  Future<Map<String, dynamic>> _readResource(String? uri) async {
    String? filePath;

    switch (uri) {
      case 'coui://docs/llm-guide':
        filePath = path.join(docsPath, 'coui_flutter_llm_guide.md');
      case 'coui://docs/quick-reference':
        filePath = path.join(docsPath, 'coui_flutter_quick_reference.md');
      case 'coui://docs/common-patterns':
        filePath = path.join(docsPath, 'coui_flutter_common_patterns.md');
      case 'coui://docs/component-metadata':
        filePath = path.join(docsPath, 'component_metadata.json');
      default:
        throw 'Unknown URI: $uri';
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw 'File not found: $filePath';
    }

    final content = await file.readAsString();
    return {
      'contents': [
        {
          'uri': uri,
          'mimeType':
              filePath.endsWith('.json') ? 'application/json' : 'text/markdown',
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
      case 'search_components':
        return await _searchComponents(args);
      case 'get_component_details':
        return await _getComponentDetails(args);
      default:
        throw 'Unknown tool: $name';
    }
  }

  Future<Map<String, dynamic>> _searchComponents(
      Map<String, dynamic> args) async {
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
      Map<String, dynamic> args) async {
    final componentName = (args['component_name'] as String).toLowerCase();
    final components = _componentMetadata ?? [];

    Map<String, dynamic>? component;
    try {
      component = components.firstWhere(
        (c) => (c['name'] as String).toLowerCase() == componentName,
      );
    } catch (e) {
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
    final metadataFile = File(path.join(docsPath, 'component_metadata.json'));
    if (await metadataFile.exists()) {
      final content = await metadataFile.readAsString();
      final decoded = json.decode(content) as List;
      _componentMetadata = decoded.cast<Map<String, dynamic>>();
    }
  }
}
