import 'dart:convert';
import 'dart:io';

import 'package:coui_mcp/src/config/coui_mcp_config.dart';
import 'package:coui_mcp/src/resources/category_resources.dart';
import 'package:coui_mcp/src/resources/component_resources.dart';
import 'package:coui_mcp/src/resources/token_resources.dart';
import 'package:coui_mcp/src/tools/component_generator.dart';
import 'package:coui_mcp/src/tools/component_validator.dart';
import 'package:coui_mcp/src/tools/pattern_generator.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:path/path.dart' as p;

/// Type alias for template variables used in resource templates.
typedef TemplateVariables = Map<String, dynamic>;

/// CoUI MCP Server using mcp_dart SDK.
///
/// A comprehensive MCP server that provides CoUI component documentation
/// and code generation tools (Flutter and Jaspr/Web) with full MCP
/// protocol compliance.
class CouiMcpServer {
  /// Creates a new CouiMcpServer with the given [config].
  ///
  /// If [config] is not provided, it will use defaults with optional
  /// [docsPath] for backward compatibility.
  CouiMcpServer({
    String? docsPath,
    CouiMcpConfig? config,
  }) : _config = config ?? CouiMcpConfig(docsPath: docsPath) {
    _initializeResourceHandlers();
    _server = _createServer();
  }

  /// Server configuration.
  final CouiMcpConfig _config;

  /// Path to the documentation directory.
  ///
  /// This is derived from the configuration for backward compatibility.
  String get docsPath => _config.resolvedDocsPath;

  /// Component metadata cache.
  List<Map<String, dynamic>>? _componentMetadata;

  /// The underlying MCP server instance.
  late final McpServer _server;

  // Resource handlers
  late final ComponentResources _componentResources;
  late final TokenResources _tokenResources;
  late final CategoryResources _categoryResources;

  void _initializeResourceHandlers() {
    _componentResources = ComponentResources(
      dataPath: _config.resolvedDataPath,
      docsPath: _config.resolvedDocsPath,
    );
    _tokenResources = TokenResources(
      tokensPath: _config.tokensPath,
    );
    _categoryResources = CategoryResources(
      dataPath: _config.resolvedDataPath,
      docsPath: _config.resolvedDocsPath,
    );
  }

  McpServer _createServer() {
    return McpServer(
      const Implementation(
        name: 'coui-mcp',
        version: '2.1.0',
      ),
      options: const McpServerOptions(
        capabilities: ServerCapabilities(
          tools: ServerCapabilitiesTools(),
          resources: ServerCapabilitiesResources(),
        ),
      ),
    );
  }

  /// Starts the MCP server with stdio transport.
  Future<void> start() async {
    // Load component metadata first
    await _loadComponentMetadata();

    // Register all tools
    _registerTools();

    // Register all resources
    _registerResources();

    // Create stdio transport and connect
    final transport = StdioServerTransport();
    await _server.connect(transport);
  }

  void _registerTools() {
    // Documentation tools
    _server.registerTool(
      'search_components',
      description: 'Search CoUI components by name or description',
      inputSchema: ToolInputSchema(
        properties: {
          'query': JsonSchema.string(
            description: 'Search query for component name or description',
          ),
        },
        required: const ['query'],
      ),
      callback: _handleSearchComponents,
    );

    _server.registerTool(
      'get_component_details',
      description: 'Get detailed information about a specific component',
      inputSchema: ToolInputSchema(
        properties: {
          'component_name': JsonSchema.string(
            description: 'Name of the component to get details for',
          ),
        },
        required: const ['component_name'],
      ),
      callback: _handleGetComponentDetails,
    );

    // Code generation tools
    _server.registerTool(
      'generate_component',
      description:
          'Generate code for a CoUI component. Supports both '
          'Flutter (coui_flutter) and Jaspr (coui_web) targets.',
      inputSchema: ToolInputSchema(
        properties: {
          'component_name': JsonSchema.string(
            description: 'Name of the component to generate',
          ),
          'target': JsonSchema.string(
            description:
                'Target platform: "flutter" (coui_flutter) or "jaspr" '
                '(coui_web). Defaults to "flutter".',
          ),
          'variant': JsonSchema.string(
            description: 'Component variant (e.g., primary, secondary)',
          ),
          'properties': JsonSchema.object(
            description: 'Additional properties for the component',
          ),
        },
        required: const ['component_name'],
      ),
      callback: _handleGenerateComponent,
    );

    _server.registerTool(
      'generate_screen',
      description:
          'Generate a complete screen scaffold. Supports both '
          'Flutter (coui_flutter) and Jaspr (coui_web) targets.',
      inputSchema: ToolInputSchema(
        properties: {
          'screen_type': JsonSchema.string(
            description: 'Type of screen to generate',
          ),
          'target': JsonSchema.string(
            description:
                'Target platform: "flutter" or "jaspr". Defaults to "flutter".',
          ),
          'title': JsonSchema.string(
            description: 'Screen title',
          ),
          'components': JsonSchema.array(
            items: JsonSchema.string(),
            description: 'List of components to include',
          ),
        },
        required: const ['screen_type'],
      ),
      callback: _handleGenerateScreen,
    );

    _server.registerTool(
      'generate_form',
      description:
          'Generate a form with validation. Supports both '
          'Flutter (coui_flutter) and Jaspr (coui_web) targets.',
      inputSchema: ToolInputSchema(
        properties: {
          'form_name': JsonSchema.string(
            description: 'Name of the form',
          ),
          'target': JsonSchema.string(
            description:
                'Target platform: "flutter" or "jaspr". Defaults to "flutter".',
          ),
          'fields': JsonSchema.array(
            items: JsonSchema.object(),
            description: 'List of form fields',
          ),
        },
        required: const ['form_name', 'fields'],
      ),
      callback: _handleGenerateForm,
    );

    _server.registerTool(
      'generate_pattern',
      description:
          'Generate a complete screen from a common pattern '
          '(login, profile, dashboard, etc.). Supports both '
          'Flutter and Jaspr targets (Jaspr currently supports '
          'login/form/dashboard; other patterns fall back to Flutter).',
      inputSchema: ToolInputSchema(
        properties: {
          'pattern_name': JsonSchema.string(
            description: 'Name of the pattern to generate',
          ),
          'target': JsonSchema.string(
            description:
                'Target platform: "flutter" or "jaspr". Defaults to "flutter".',
          ),
          'customization': JsonSchema.object(
            description: 'Customization options for the pattern',
          ),
        },
        required: const ['pattern_name'],
      ),
      callback: _handleGeneratePattern,
    );

    _server.registerTool(
      'list_patterns',
      description: 'List all available screen patterns',
      inputSchema: const ToolInputSchema(
        properties: <String, JsonSchema>{},
      ),
      callback: _handleListPatterns,
    );

    // Styling tools
    _server.registerTool(
      'customize_style',
      description:
          'Generate custom style code for a component. Supports both '
          'Flutter (style class) and Jaspr (Tailwind classes) targets.',
      inputSchema: ToolInputSchema(
        properties: {
          'component_name': JsonSchema.string(
            description: 'Name of the component to style',
          ),
          'target': JsonSchema.string(
            description:
                'Target platform: "flutter" or "jaspr". Defaults to "flutter".',
          ),
          'style_options': JsonSchema.object(
            description: 'Style options (colors, sizes, etc.)',
          ),
        },
        required: const ['component_name', 'style_options'],
      ),
      callback: _handleCustomizeStyle,
    );

    // Validation tools
    _server.registerTool(
      'validate_component',
      description: 'Validate component usage and properties',
      inputSchema: ToolInputSchema(
        properties: {
          'component_name': JsonSchema.string(
            description: 'Name of the component to validate',
          ),
          'properties': JsonSchema.object(
            description: 'Properties to validate',
          ),
        },
        required: const ['component_name'],
      ),
      callback: _handleValidateComponent,
    );

    _server.registerTool(
      'analyze_accessibility',
      description: 'Analyze component accessibility and get recommendations',
      inputSchema: ToolInputSchema(
        properties: {
          'component_name': JsonSchema.string(
            description: 'Name of the component to analyze',
          ),
          'properties': JsonSchema.object(
            description: 'Component properties',
          ),
        },
        required: const ['component_name'],
      ),
      callback: _handleAnalyzeAccessibility,
    );

    _server.registerTool(
      'suggest_improvements',
      description: 'Analyze Flutter code and suggest improvements',
      inputSchema: ToolInputSchema(
        properties: {
          'code': JsonSchema.string(
            description: 'Flutter code to analyze',
          ),
        },
        required: const ['code'],
      ),
      callback: _handleSuggestImprovements,
    );
  }

  void _registerResources() {
    // Component resources
    _server.registerResourceTemplate(
      'Component Overview',
      ResourceTemplateRegistration(
        'coui://component/{name}/overview',
        listCallback: null,
      ),
      (
        description: 'Basic component info (~50 lines vs 1,372)',
        mimeType: null,
      ),
      _handleComponentOverviewResource,
    );

    _server.registerResourceTemplate(
      'Component Examples',
      ResourceTemplateRegistration(
        'coui://component/{name}/examples',
        listCallback: null,
      ),
      (description: 'Component usage examples only', mimeType: null),
      _handleComponentExamplesResource,
    );

    _server.registerResourceTemplate(
      'Component API',
      ResourceTemplateRegistration(
        'coui://component/{name}/api',
        listCallback: null,
      ),
      (
        description: 'API reference with properties and variants',
        mimeType: null,
      ),
      _handleComponentApiResource,
    );

    _server.registerResourceTemplate(
      'Accessibility Info',
      ResourceTemplateRegistration(
        'coui://component/{name}/accessibility',
        listCallback: null,
      ),
      (description: 'WCAG compliance and a11y guidelines', mimeType: null),
      _handleComponentAccessibilityResource,
    );

    // Token resources
    _server.registerResourceTemplate(
      'Design Tokens',
      ResourceTemplateRegistration(
        'coui://tokens/{type}',
        listCallback: null,
      ),
      (
        description:
            'Design system tokens (colors, spacing, typography, sizes)',
        mimeType: null,
      ),
      _handleTokenResource,
    );

    // Category resources
    _server.registerResourceTemplate(
      'Category Resources',
      ResourceTemplateRegistration(
        'coui://category/{category}',
        listCallback: null,
      ),
      (description: 'Components grouped by category', mimeType: null),
      _handleCategoryResource,
    );

    // Legacy documentation resources
    _server.registerResource(
      'CoUI Flutter LLM Guide (Legacy)',
      'coui://docs/llm-guide',
      (description: 'Complete reference guide (1,372 lines)', mimeType: null),
      _handleLlmGuideResource,
    );

    _server.registerResource(
      'Quick Reference',
      'coui://docs/quick-reference',
      (description: 'Quick reference cheat sheet (381 lines)', mimeType: null),
      _handleQuickReferenceResource,
    );

    _server.registerResource(
      'Common UI Patterns',
      'coui://docs/common-patterns',
      (description: '8 common screen patterns (960 lines)', mimeType: null),
      _handleCommonPatternsResource,
    );

    _server.registerResource(
      'Component Metadata',
      'coui://docs/component-metadata',
      (description: 'JSON metadata for 83 components', mimeType: null),
      _handleComponentMetadataResource,
    );
  }

  // Tool handlers

  Future<CallToolResult> _handleSearchComponents(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final query = (args['query'] as String? ?? '').toLowerCase();
    final components = _componentMetadata ?? [];

    final results = components
        .where((comp) {
          final name = (comp['name'] as String).toLowerCase();
          final desc = (comp['description'] as String).toLowerCase();
          return name.contains(query) || desc.contains(query);
        })
        .take(10)
        .toList();

    return CallToolResult(
      content: [
        TextContent(
          text: json.encode({
            'query': query,
            'results_count': results.length,
            'results': results,
          }),
        ),
      ],
    );
  }

  Future<CallToolResult> _handleGetComponentDetails(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final componentName = (args['component_name'] as String? ?? '')
        .toLowerCase();
    final components = _componentMetadata ?? [];

    Map<String, dynamic>? component;
    for (final comp in components) {
      if ((comp['name'] as String).toLowerCase() == componentName) {
        component = comp;
        break;
      }
    }

    if (component == null) {
      return CallToolResult(
        isError: true,
        content: [
          TextContent(
            text: json.encode({
              'error': 'Component not found: $componentName',
            }),
          ),
        ],
      );
    }

    return CallToolResult(
      content: [
        TextContent(text: json.encode(component)),
      ],
    );
  }

  Future<CallToolResult> _handleGenerateComponent(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final result = ComponentGenerator.generateComponent(args);
    return _toolResultFromMap(result);
  }

  Future<CallToolResult> _handleGenerateScreen(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final result = ComponentGenerator.generateScreen(args);
    return _toolResultFromMap(result);
  }

  Future<CallToolResult> _handleGenerateForm(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final result = ComponentGenerator.generateForm(args);
    return _toolResultFromMap(result);
  }

  Future<CallToolResult> _handleGeneratePattern(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final result = PatternGenerator.generatePattern(args);
    return _toolResultFromMap(result);
  }

  Future<CallToolResult> _handleListPatterns(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final result = PatternGenerator.listPatterns(args);
    return _toolResultFromMap(result);
  }

  Future<CallToolResult> _handleCustomizeStyle(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final result = ComponentGenerator.customizeStyle(args);
    return _toolResultFromMap(result);
  }

  Future<CallToolResult> _handleValidateComponent(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final result = ComponentValidator.validateComponent(args);
    return _toolResultFromMap(result);
  }

  Future<CallToolResult> _handleAnalyzeAccessibility(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final result = ComponentValidator.analyzeAccessibility(args);
    return _toolResultFromMap(result);
  }

  Future<CallToolResult> _handleSuggestImprovements(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final result = ComponentValidator.suggestImprovements(args);
    return _toolResultFromMap(result);
  }

  CallToolResult _toolResultFromMap(Map<String, dynamic> result) {
    final content = result['content'] as List<dynamic>?;
    if (content != null && content.isNotEmpty) {
      final firstContent = content.first as Map<String, dynamic>;
      final text = firstContent['text'] as String? ?? json.encode(result);
      return CallToolResult(
        content: [TextContent(text: text)],
      );
    }
    return CallToolResult(
      content: [TextContent(text: json.encode(result))],
    );
  }

  // Resource template handlers

  Future<ReadResourceResult> _handleComponentOverviewResource(
    Uri uri,
    TemplateVariables vars,
    RequestHandlerExtra extra,
  ) async {
    final resourceUri = uri.toString();
    final result = await _componentResources.getResource(resourceUri);
    return _readResourceResultFromMap(uri, result);
  }

  Future<ReadResourceResult> _handleComponentExamplesResource(
    Uri uri,
    TemplateVariables vars,
    RequestHandlerExtra extra,
  ) async {
    final resourceUri = uri.toString();
    final result = await _componentResources.getResource(resourceUri);
    return _readResourceResultFromMap(uri, result);
  }

  Future<ReadResourceResult> _handleComponentApiResource(
    Uri uri,
    TemplateVariables vars,
    RequestHandlerExtra extra,
  ) async {
    final resourceUri = uri.toString();
    final result = await _componentResources.getResource(resourceUri);
    return _readResourceResultFromMap(uri, result);
  }

  Future<ReadResourceResult> _handleComponentAccessibilityResource(
    Uri uri,
    TemplateVariables vars,
    RequestHandlerExtra extra,
  ) async {
    final resourceUri = uri.toString();
    final result = await _componentResources.getResource(resourceUri);
    return _readResourceResultFromMap(uri, result);
  }

  Future<ReadResourceResult> _handleTokenResource(
    Uri uri,
    TemplateVariables vars,
    RequestHandlerExtra extra,
  ) async {
    final resourceUri = uri.toString();
    final result = await _tokenResources.getResource(resourceUri);
    return _readResourceResultFromMap(uri, result);
  }

  Future<ReadResourceResult> _handleCategoryResource(
    Uri uri,
    TemplateVariables vars,
    RequestHandlerExtra extra,
  ) async {
    final resourceUri = uri.toString();
    final result = await _categoryResources.getResource(resourceUri);
    return _readResourceResultFromMap(uri, result);
  }

  ReadResourceResult _readResourceResultFromMap(
    Uri uri,
    Map<String, dynamic> result,
  ) {
    final contents = result['contents'] as List<dynamic>?;
    if (contents != null && contents.isNotEmpty) {
      final firstContent = contents.first as Map<String, dynamic>;
      return ReadResourceResult(
        contents: [
          TextResourceContents(
            uri: uri.toString(),
            mimeType: firstContent['mimeType'] as String? ?? 'application/json',
            text: firstContent['text'] as String? ?? '',
          ),
        ],
      );
    }

    throw McpError(
      ErrorCode.invalidRequest.value,
      'Resource not found: $uri',
    );
  }

  // Static resource handlers

  Future<ReadResourceResult> _handleLlmGuideResource(
    Uri uri,
    RequestHandlerExtra extra,
  ) async {
    final filePath = p.join(docsPath, 'llm_guide.md');
    return _readFileResource(uri, filePath);
  }

  Future<ReadResourceResult> _handleQuickReferenceResource(
    Uri uri,
    RequestHandlerExtra extra,
  ) async {
    final filePath = p.join(docsPath, 'quick_reference.md');
    return _readFileResource(uri, filePath);
  }

  Future<ReadResourceResult> _handleCommonPatternsResource(
    Uri uri,
    RequestHandlerExtra extra,
  ) async {
    final filePath = p.join(docsPath, 'common_patterns.md');
    return _readFileResource(uri, filePath);
  }

  Future<ReadResourceResult> _handleComponentMetadataResource(
    Uri uri,
    RequestHandlerExtra extra,
  ) async {
    // Bundled at data/components/component_metadata.json, not under docs/.
    final filePath = p.join(_config.componentsPath, 'component_metadata.json');
    return _readFileResource(uri, filePath);
  }

  Future<ReadResourceResult> _readFileResource(
    Uri uri,
    String filePath,
  ) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw McpError(
        ErrorCode.invalidRequest.value,
        'File not found: $filePath',
      );
    }

    final content = await file.readAsString();
    return ReadResourceResult(
      contents: [
        TextResourceContents(
          uri: uri.toString(),
          mimeType: filePath.endsWith('.json')
              ? 'application/json'
              : 'text/markdown',
          text: content,
        ),
      ],
    );
  }

  Future<void> _loadComponentMetadata() async {
    // Try loading from data/components first (bundled data)
    final bundledPath = p.join(
      _config.componentsPath,
      'component_metadata.json',
    );
    final bundledFile = File(bundledPath);

    // Fallback to legacy docs path
    final legacyPath = p.join(
      _config.resolvedDocsPath,
      'component_metadata.json',
    );
    final legacyFile = File(legacyPath);

    File? metadataFile;
    if (bundledFile.existsSync()) {
      metadataFile = bundledFile;
    } else if (legacyFile.existsSync()) {
      metadataFile = legacyFile;
    }

    if (metadataFile != null) {
      final content = await metadataFile.readAsString();
      final decoded = json.decode(content) as List;
      _componentMetadata = decoded.cast<Map<String, dynamic>>();
    }
  }
}
