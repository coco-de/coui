/// Design token model for the CoUI design system
class DesignToken {
  /// Design token constructor
  DesignToken({
    required this.category,
    required this.tokens,
  });

  /// Design token from JSON
  factory DesignToken.fromJson(Map<String, dynamic> json) {
    return DesignToken(
      category: json['category'] as String,
      tokens: json['tokens'] as Map<String, dynamic>,
    );
  }

  /// Design token category
  final String category;

  /// Design token tokens
  final Map<String, dynamic> tokens;

  /// Design token to JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'tokens': tokens,
    };
  }
}
