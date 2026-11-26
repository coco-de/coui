import 'dart:convert';

/// Component validation and analysis tool
class ComponentValidator {
  /// Validate component usage and properties
  static Map<String, dynamic> validateComponent(Map<String, dynamic> args) {
    final componentName = args['component_name'] as String;
    final properties = args['properties'] as Map<String, dynamic>? ?? {};

    final validation = _validateComponentProperties(componentName, properties);

    return {
      'content': [
        {
          'type': 'text',
          'text': json.encode(validation),
        },
      ],
    };
  }

  /// Analyze accessibility of a component
  static Map<String, dynamic> analyzeAccessibility(Map<String, dynamic> args) {
    final componentName = args['component_name'] as String;
    final properties = args['properties'] as Map<String, dynamic>? ?? {};

    final analysis = _analyzeComponentAccessibility(componentName, properties);

    return {
      'content': [
        {
          'type': 'text',
          'text': json.encode(analysis),
        },
      ],
    };
  }

  /// Suggest improvements for component usage
  static Map<String, dynamic> suggestImprovements(Map<String, dynamic> args) {
    final code = args['code'] as String;

    final suggestions = _analyzeThenSuggestImprovements(code);

    return {
      'content': [
        {
          'type': 'text',
          'text': json.encode(suggestions),
        },
      ],
    };
  }

  static Map<String, dynamic> _validateComponentProperties(
    String componentName,
    Map<String, dynamic> properties,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    switch (componentName.toLowerCase()) {
      case 'button':
        _validateButtonProperties(properties, errors, warnings, suggestions);
      case 'input':
        _validateInputProperties(properties, errors, warnings, suggestions);
      case 'card':
        _validateCardProperties(properties, errors, warnings, suggestions);
      case 'dialog':
        _validateDialogProperties(properties, errors, warnings, suggestions);
      default:
        _validateGenericProperties(properties, errors, warnings, suggestions);
    }

    return {
      'valid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'suggestions': suggestions,
    };
  }

  static void _validateButtonProperties(
    Map<String, dynamic> properties,
    List<String> errors,
    List<String> warnings,
    List<String> suggestions,
  ) {
    // Check for child or text
    if (!properties.containsKey('child') && !properties.containsKey('text')) {
      errors.add('Button must have either "child" or "text" property');
    }

    // Check onPressed
    if (!properties.containsKey('onPressed')) {
      warnings.add('Button without onPressed callback will be disabled');
    }

    // Check size
    final size = properties['size'];
    if (size != null && !['xs', 'sm', 'md', 'lg', 'xl'].contains(size)) {
      errors.add(
        'Invalid button size: $size. '
        'Valid values: xs, sm, md, lg, xl',
      );
    }

    // Accessibility suggestions
    if (properties['icon'] != null &&
        !properties.containsKey('semanticLabel')) {
      suggestions.add('Consider adding semanticLabel for icon-only buttons');
    }
  }

  static void _validateInputProperties(
    Map<String, dynamic> properties,
    List<String> errors,
    List<String> warnings,
    List<String> suggestions,
  ) {
    // Check label
    if (!properties.containsKey('label') &&
        !properties.containsKey('placeholder')) {
      warnings.add(
        'Input should have either label or placeholder for better UX',
      );
    }

    // Check controller or onChanged
    if (!properties.containsKey('controller') &&
        !properties.containsKey('onChanged')) {
      warnings.add('Input should have either controller or onChanged callback');
    }

    // Required field validation
    if (properties['required'] == true &&
        !properties.containsKey('validator')) {
      suggestions.add('Consider adding validator for required field');
    }

    // Type validation
    final type = properties['type'];
    if (type != null &&
        !['text', 'email', 'password', 'number', 'phone'].contains(type)) {
      warnings.add('Unusual input type: $type');
    }
  }

  static void _validateCardProperties(
    Map<String, dynamic> properties,
    List<String> errors,
    List<String> warnings,
    List<String> suggestions,
  ) {
    // Check for content
    if (!properties.containsKey('child') &&
        !properties.containsKey('children')) {
      errors.add('Card must have either "child" or "children" property');
    }

    // Suggest elevation for emphasis
    if (!properties.containsKey('elevation')) {
      suggestions.add('Consider adding elevation to emphasize the card');
    }
  }

  static void _validateDialogProperties(
    Map<String, dynamic> properties,
    List<String> errors,
    List<String> warnings,
    List<String> suggestions,
  ) {
    // Check title
    if (!properties.containsKey('title')) {
      warnings.add('Dialog should have a title for clarity');
    }

    // Check actions
    if (!properties.containsKey('actions')) {
      warnings.add('Dialog should have actions (buttons) for user interaction');
    }

    // Accessibility
    if (!properties.containsKey('barrierDismissible')) {
      suggestions.add('Consider setting barrierDismissible explicitly');
    }
  }

  static void _validateGenericProperties(
    Map<String, dynamic> properties,
    List<String> errors,
    List<String> warnings,
    List<String> suggestions,
  ) {
    // Generic validation
    if (properties.isEmpty) {
      warnings.add('Component has no properties specified');
    }
  }

  static Map<String, dynamic> _analyzeComponentAccessibility(
    String componentName,
    Map<String, dynamic> properties,
  ) {
    final issues = <String>[];
    final recommendations = <String>[];
    var score = 100;

    switch (componentName.toLowerCase()) {
      case 'button':
        _analyzeButtonAccessibility(properties, issues, recommendations);
      case 'input':
        _analyzeInputAccessibility(properties, issues, recommendations);
      case 'image':
        _analyzeImageAccessibility(properties, issues, recommendations);
      case 'dialog':
        _analyzeDialogAccessibility(properties, issues, recommendations);
      default:
        _analyzeGenericAccessibility(properties, issues, recommendations);
    }

    // Calculate score
    score -= issues.length * 15;
    score -= recommendations.length * 5;
    score = score.clamp(0, 100);

    return {
      'score': score,
      'level': _getAccessibilityLevel(score),
      'issues': issues,
      'recommendations': recommendations,
    };
  }

  static void _analyzeButtonAccessibility(
    Map<String, dynamic> properties,
    List<String> issues,
    List<String> recommendations,
  ) {
    // Check semantic label for icon buttons
    if (properties['icon'] != null &&
        !properties.containsKey('semanticLabel')) {
      issues.add('Icon-only button missing semanticLabel');
    }

    // Check touch target size
    final size = properties['size'];
    if (size == 'xs') {
      recommendations.add(
        'Extra small buttons '
        'may not meet minimum touch target size (48x48)',
      );
    }

    // Check color contrast
    if (!properties.containsKey('style')) {
      recommendations.add(
        'Consider using explicit button style '
        'for better color contrast',
      );
    }
  }

  static void _analyzeInputAccessibility(
    Map<String, dynamic> properties,
    List<String> issues,
    List<String> recommendations,
  ) {
    // Check label
    if (!properties.containsKey('label')) {
      issues.add('Input missing label for screen readers');
    }

    // Check hint text
    if (!properties.containsKey('hint')) {
      recommendations.add('Consider adding hint text for better guidance');
    }

    // Check error handling
    if (!properties.containsKey('errorText') &&
        !properties.containsKey('validator')) {
      recommendations.add(
        'Consider adding error handling for validation feedback',
      );
    }
  }

  static void _analyzeImageAccessibility(
    Map<String, dynamic> properties,
    List<String> issues,
    List<String> recommendations,
  ) {
    // Check alt text
    if (!properties.containsKey('semanticLabel') &&
        !properties.containsKey('alt')) {
      issues.add('Image missing alt text (semanticLabel)');
    }

    // Check decorative images
    if (properties['decorative'] == true &&
        properties.containsKey('semanticLabel')) {
      recommendations.add('Decorative images should have empty semanticLabel');
    }
  }

  static void _analyzeDialogAccessibility(
    Map<String, dynamic> properties,
    List<String> issues,
    List<String> recommendations,
  ) {
    // Check title
    if (!properties.containsKey('title')) {
      issues.add('Dialog missing title for context');
    }

    // Check focus management
    if (!properties.containsKey('autofocus')) {
      recommendations.add('Consider setting autofocus for primary action');
    }

    // Check dismissibility
    if (properties['barrierDismissible'] == false &&
        !properties.containsKey('actions')) {
      issues.add(
        'Non-dismissible dialog without actions creates accessibility trap',
      );
    }
  }

  static void _analyzeGenericAccessibility(
    Map<String, dynamic> properties,
    List<String> issues,
    List<String> recommendations,
  ) {
    // Generic accessibility checks
    if (properties.containsKey('onTap') &&
        !properties.containsKey('semanticLabel')) {
      recommendations.add('Interactive elements should have semantic labels');
    }
  }

  static String _getAccessibilityLevel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    if (score >= 40) return 'Poor';
    return 'Critical';
  }

  static Map<String, dynamic> _analyzeThenSuggestImprovements(String code) {
    final improvements = <Map<String, dynamic>>[];

    // Check for common anti-patterns
    if (code.contains('Co') && code.contains('Button')) {
      improvements.add({
        'type': 'error',
        'message': 'Invalid component name with Co prefix',
        'suggestion':
            'Remove Co prefix. Use "PrimaryButton" instead of "Button"',
        'line': _findLineNumber(code, 'Button'),
      });
    }

    // Check for missing imports
    if (!code.contains('import') &&
        (code.contains('Button') || code.contains('Input'))) {
      improvements.add({
        'type': 'warning',
        'message': 'Missing import statement',
        'suggestion': "Add: import 'package:coui_flutter/coui_flutter.dart';",
        'line': 1,
      });
    }

    // Check for StatelessWidget without const constructor
    if (code.contains('StatelessWidget') &&
        !code.contains('const ${_extractClassName(code)}')) {
      improvements.add({
        'type': 'suggestion',
        'message': 'StatelessWidget without const constructor',
        'suggestion': 'Add const constructor for better performance',
        'line': _findLineNumber(code, 'StatelessWidget'),
      });
    }

    // Check for missing key parameter
    if (code.contains('StatefulWidget') || code.contains('StatelessWidget')) {
      if (!code.contains('{super.key}') && !code.contains('{Key? key}')) {
        improvements.add({
          'type': 'suggestion',
          'message': 'Widget without key parameter',
          'suggestion': 'Add {super.key} to constructor',
          'line': _findLineNumber(code, 'Widget'),
        });
      }
    }

    // Check for hardcoded strings
    final stringMatches = RegExp(r"Text\('([^']+)'\)").allMatches(code);
    if (stringMatches.length > 3) {
      improvements.add({
        'type': 'suggestion',
        'message': 'Multiple hardcoded strings detected',
        'suggestion': 'Consider using localization for text content',
      });
    }

    // Check for missing error handling in async methods
    if (code.contains('async') &&
        !code.contains('try') &&
        !code.contains('catch')) {
      improvements.add({
        'type': 'warning',
        'message': 'Async method without error handling',
        'suggestion': 'Add try-catch block for error handling',
      });
    }

    return {
      'improvements': improvements,
      'count': improvements.length,
      'has_errors': improvements.any((imp) => imp['type'] == 'error'),
      'has_warnings': improvements.any((imp) => imp['type'] == 'warning'),
    };
  }

  static int _findLineNumber(String code, String pattern) {
    final lines = code.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains(pattern)) {
        return i + 1;
      }
    }
    return 0;
  }

  static String _extractClassName(String code) {
    final match = RegExp(r'class\s+(\w+)\s+extends').firstMatch(code);
    return match?.group(1) ?? 'Widget';
  }
}
