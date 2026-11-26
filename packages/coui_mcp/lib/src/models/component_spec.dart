/// Component specification model with rich metadata
class ComponentSpec {
  /// Component specification constructor
  ComponentSpec({
    required this.name,
    required this.displayName,
    required this.category,
    required this.description,
    this.variants = const {},
    this.sizes = const [],
    this.properties = const {},
    this.designTokens = const {},
    this.accessibility = const {},
    this.exampleCount = 0,
    this.exampleFile,
    this.popularity = 50,
  });

  /// Component specification from JSON
  factory ComponentSpec.fromJson(Map<String, dynamic> json) {
    return ComponentSpec(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      category: json['category'] as String? ?? 'general',
      description: json['description'] as String,
      variants:
          (json['variants'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              ComponentVariant.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      sizes: (json['sizes'] as List<dynamic>?)?.cast<String>() ?? [],
      properties:
          (json['properties'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              PropertySpec.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      designTokens: (json['designTokens'] as Map<String, dynamic>?) ?? {},
      accessibility: (json['accessibility'] as Map<String, dynamic>?) ?? {},
      exampleCount: json['exampleCount'] as int? ?? 0,
      exampleFile: json['exampleFile'] as String?,
      popularity: json['popularity'] as int? ?? 50,
    );
  }

  /// Component name
  final String name;

  /// Component display name
  final String displayName;

  /// Component category
  final String category;

  /// Component description
  final String description;

  /// Component variants
  final Map<String, ComponentVariant> variants;

  /// Component sizes
  final List<String> sizes;

  /// Component properties
  final Map<String, PropertySpec> properties;

  /// Component design tokens
  final Map<String, dynamic> designTokens;

  /// Component accessibility
  final Map<String, dynamic> accessibility;

  /// Component example count
  final int exampleCount;

  /// Component example file
  final String? exampleFile;

  /// Component popularity
  final int popularity;

  /// Component specification to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'category': category,
      'description': description,
      'variants': variants.map((key, value) => MapEntry(key, value.toJson())),
      'sizes': sizes,
      'properties': properties.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'designTokens': designTokens,
      'accessibility': accessibility,
      'exampleCount': exampleCount,
      if (exampleFile != null) 'exampleFile': exampleFile,
      'popularity': popularity,
    };
  }
}

/// Component variant specification
class ComponentVariant {
  /// Component variant constructor
  ComponentVariant({
    required this.className,
    required this.description,
    this.preview,
  });

  /// Component variant from JSON
  factory ComponentVariant.fromJson(Map<String, dynamic> json) {
    return ComponentVariant(
      className: json['class'] as String? ?? json['className'] as String,
      description: json['description'] as String,
      preview: json['preview'] as String?,
    );
  }

  /// Component variant class name
  final String className;

  /// Component variant description
  final String description;

  /// Component variant preview
  final String? preview;

  /// Component variant to JSON
  Map<String, dynamic> toJson() {
    return {
      'class': className,
      'description': description,
      if (preview != null) 'preview': preview,
    };
  }
}

/// Property specification
class PropertySpec {
  /// Property specification constructor
  PropertySpec({
    required this.type,
    required this.description,
    this.required = false,
    this.defaultValue,
    this.values,
  });

  /// Property specification from JSON
  factory PropertySpec.fromJson(Map<String, dynamic> json) {
    return PropertySpec(
      type: json['type'] as String,
      description: json['description'] as String,
      required: json['required'] as bool? ?? false,
      defaultValue: json['default'],
      values: (json['values'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Property type
  final String type;

  /// Property description
  final String description;

  /// Property required
  final bool required;

  /// Property default value
  final dynamic defaultValue;

  /// Property values
  final List<String>? values;

  /// Property specification to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'required': required,
      if (defaultValue != null) 'default': defaultValue,
      if (values != null) 'values': values,
    };
  }
}
