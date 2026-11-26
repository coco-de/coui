import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Design token resource handler
class TokenResources {
  /// Creates a new TokenResources with the given [tokensPath].
  TokenResources({required this.tokensPath});

  /// Path to the tokens directory.
  final String tokensPath;

  /// Token cache.
  final Map<String, dynamic> _tokenCache = {};

  /// Get a design token resource
  Future<Map<String, dynamic>> getResource(String uri) async {
    // `coui://tokens/{type}` — pathSegments treats "tokens" as the URI
    // authority, so the actual type is pathSegments[0] (see
    // ComponentResources.getResource for why not uri.split('/')).
    final pathSegments = Uri.parse(uri).pathSegments;

    if (pathSegments.isEmpty) {
      throw Exception('Invalid token URI format: $uri');
    }

    final tokenCategory = pathSegments[0];

    // Check cache first
    if (_tokenCache.containsKey(tokenCategory)) {
      return _buildResponse(
        uri,
        _tokenCache[tokenCategory]! as Map<String, dynamic>,
      );
    }

    // Load from file
    final tokenData = await _loadTokenFile(tokenCategory);
    _tokenCache[tokenCategory] = tokenData;

    return _buildResponse(uri, tokenData);
  }

  /// Load token data from JSON file
  Future<Map<String, dynamic>> _loadTokenFile(String category) async {
    final tokenPath = path.join(tokensPath, '$category.json');
    final file = File(tokenPath);

    if (!file.existsSync()) {
      throw Exception('Token file not found: $tokenPath');
    }

    final content = await file.readAsString();
    return json.decode(content) as Map<String, dynamic>;
  }

  /// Build MCP resource response
  Map<String, dynamic> _buildResponse(String uri, Map<String, dynamic> data) {
    return {
      'contents': [
        {
          'uri': uri,
          'mimeType': 'application/json',
          'text': json.encode(data),
        },
      ],
    };
  }

  /// Get all available token categories
  Future<List<String>> getAvailableCategories() async {
    final dir = Directory(tokensPath);

    if (!dir.existsSync()) {
      return [];
    }

    final files = await dir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .toList();

    return files
        .map((file) => path.basenameWithoutExtension(file.path))
        .toList();
  }
}
