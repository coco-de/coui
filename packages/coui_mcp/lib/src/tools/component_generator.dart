import 'dart:convert';

import 'package:coui_mcp/src/tools/jaspr/jaspr_component_templates.dart';
import 'package:coui_mcp/src/tools/platform_target.dart';

/// Component generation tool for coui_flutter and coui_web (Jaspr).
///
/// All generation methods accept an optional `target` argument
/// (`'flutter'` or `'jaspr'`). When omitted, defaults to `flutter`
/// for backward compatibility.
class ComponentGenerator {
  /// Generate a component with the specified parameters
  static Map<String, dynamic> generateComponent(Map<String, dynamic> args) {
    final componentName = args['component_name'] as String;
    final variant = args['variant'] as String?;
    final properties = args['properties'] as Map<String, dynamic>? ?? {};
    final target = PlatformTarget.parse(args['target'] as String?);

    final code = target == PlatformTarget.jaspr
        ? JasprComponentTemplates.build(componentName, variant, properties)
        : _buildComponentCode(componentName, variant, properties);

    return {
      'content': [
        {
          'type': 'text',
          'text': json.encode({
            'target': target.name,
            'component': componentName,
            'variant': variant,
            'code': code,
            'imports': target.requiredImports,
          }),
        },
      ],
    };
  }

  /// Generate a complete screen with multiple components
  static Map<String, dynamic> generateScreen(Map<String, dynamic> args) {
    final screenType = args['screen_type'] as String;
    final title = args['title'] as String? ?? 'Screen';
    final components = args['components'] as List? ?? [];
    final target = PlatformTarget.parse(args['target'] as String?);

    final code = target == PlatformTarget.jaspr
        ? JasprComponentTemplates.buildScreen(screenType, title, components)
        : _buildScreenCode(screenType, title, components);

    return {
      'content': [
        {
          'type': 'text',
          'text': json.encode({
            'target': target.name,
            'screen_type': screenType,
            'title': title,
            'code': code,
            'imports': target.requiredImports,
          }),
        },
      ],
    };
  }

  /// Generate a form with validation
  static Map<String, dynamic> generateForm(Map<String, dynamic> args) {
    final formName = args['form_name'] as String;
    final fields = args['fields'] as List;
    final target = PlatformTarget.parse(args['target'] as String?);

    final code = target == PlatformTarget.jaspr
        ? JasprComponentTemplates.buildForm(formName, fields)
        : _buildFormCode(formName, fields);

    return {
      'content': [
        {
          'type': 'text',
          'text': json.encode({
            'target': target.name,
            'form_name': formName,
            'fields': fields,
            'code': code,
            'imports': target.requiredImports,
          }),
        },
      ],
    };
  }

  /// Customize component styling
  static Map<String, dynamic> customizeStyle(Map<String, dynamic> args) {
    final componentName = args['component_name'] as String;
    final styleOptions = args['style_options'] as Map<String, dynamic>;
    final target = PlatformTarget.parse(args['target'] as String?);

    final styleCode = target == PlatformTarget.jaspr
        ? JasprComponentTemplates.buildStyle(componentName, styleOptions)
        : _buildStyleCode(componentName, styleOptions);

    return {
      'content': [
        {
          'type': 'text',
          'text': json.encode({
            'target': target.name,
            'component': componentName,
            'style_options': styleOptions,
            'code': styleCode,
          }),
        },
      ],
    };
  }

  static String _buildComponentCode(
    String componentName,
    String? variant,
    Map<String, dynamic> properties,
  ) {
    final buffer = StringBuffer();

    // Handle different component types
    switch (componentName.toLowerCase()) {
      case 'button':
        buffer.write(_buildButtonCode(variant, properties));
      case 'input':
        buffer.write(_buildInputCode(variant, properties));
      case 'card':
        buffer.write(_buildCardCode(properties));
      case 'avatar':
        buffer.write(_buildAvatarCode(properties));
      case 'badge':
        buffer.write(_buildBadgeCode(properties));
      case 'dialog':
        buffer.write(_buildDialogCode(properties));
      default:
        buffer.write(_buildGenericComponent(componentName, properties));
    }

    return buffer.toString();
  }

  static String _buildButtonCode(
    String? variant,
    Map<String, dynamic> properties,
  ) {
    final variantClass = _getButtonVariant(variant);
    final text = properties['text'] as String? ?? 'Button';
    final onPressed = properties['onPressed'] as bool? ?? true;
    final size = properties['size'] as String?;
    final icon = properties['icon'] as String?;

    final buffer = StringBuffer()..writeln('$variantClass(');

    if (size != null) {
      buffer.writeln('  size: ButtonSize.${size.toLowerCase()},');
    }

    if (icon != null) {
      buffer.writeln('  leading: Icon(Icons.$icon),');
    }

    if (onPressed) {
      buffer
        ..writeln('  onPressed: () {')
        ..writeln('    // TODO: Implement button action')
        ..writeln('  },');
    }

    buffer
      ..writeln("  child: Text('$text'),")
      ..write(')');

    return buffer.toString();
  }

  static String _buildInputCode(
    String? variant,
    Map<String, dynamic> properties,
  ) {
    final label = properties['label'] as String? ?? 'Input';
    final placeholder = properties['placeholder'] as String?;
    final required = properties['required'] as bool? ?? false;
    // Reserved for future input type customization
    // ignore: unused_local_variable
    final type = properties['type'] as String? ?? 'text';

    final buffer = StringBuffer()
      ..writeln('Input(')
      ..writeln("  label: '$label',");

    if (placeholder != null) {
      buffer.writeln("  placeholder: '$placeholder',");
    }

    if (required) {
      buffer.writeln('  required: true,');
    }

    buffer
      ..writeln('  onChanged: (value) {')
      ..writeln('    // TODO: Handle input change')
      ..writeln('  },')
      ..write(')');

    return buffer.toString();
  }

  static String _buildCardCode(Map<String, dynamic> properties) {
    final title = properties['title'] as String?;
    final description = properties['description'] as String?;
    final footer = properties['footer'] as bool? ?? false;

    final buffer = StringBuffer()
      ..writeln('Card(')
      ..writeln('  child: Padding(')
      ..writeln('    padding: const EdgeInsets.all(16.0),')
      ..writeln('    child: Column(')
      ..writeln('      crossAxisAlignment: CrossAxisAlignment.start,')
      ..writeln('      children: [');

    if (title != null) {
      buffer
        ..writeln('        Text(')
        ..writeln("          '$title',")
        ..writeln(
          '          style: TextStyle('
          '            fontSize: 18, '
          '            fontWeight: FontWeight.bold'
          '          ),',
        )
        ..writeln('        ),')
        ..writeln('        SizedBox(height: 8),');
    }

    if (description != null) {
      buffer.writeln("        Text('$description'),");
    }

    if (footer) {
      buffer
        ..writeln('        SizedBox(height: 16),')
        ..writeln('        Row(')
        ..writeln('          mainAxisAlignment: MainAxisAlignment.end,')
        ..writeln('          children: [')
        ..writeln('            SecondaryButton(')
        ..writeln('              onPressed: () {},')
        ..writeln("              child: Text('Cancel'),")
        ..writeln('            ),')
        ..writeln('            SizedBox(width: 8),')
        ..writeln('            PrimaryButton(')
        ..writeln('              onPressed: () {},')
        ..writeln("              child: Text('Confirm'),")
        ..writeln('            ),')
        ..writeln('          ],')
        ..writeln('        ),');
    }

    buffer
      ..writeln('      ],')
      ..writeln('    ),')
      ..writeln('  ),')
      ..write(')');

    return buffer.toString();
  }

  static String _buildAvatarCode(Map<String, dynamic> properties) {
    final image = properties['image'] as String?;
    final initials = properties['initials'] as String?;
    final size = properties['size'] as String? ?? 'md';

    final buffer = StringBuffer()
      ..writeln('Avatar(')
      ..writeln('  size: AvatarSize.${size.toLowerCase()},');

    if (image != null) {
      buffer.writeln("  image: NetworkImage('$image'),");
    } else if (initials != null) {
      buffer.writeln("  initials: '$initials',");
    }

    buffer.write(')');

    return buffer.toString();
  }

  static String _buildBadgeCode(Map<String, dynamic> properties) {
    final text = properties['text'] as String? ?? 'Badge';
    final variant = properties['variant'] as String? ?? 'primary';

    final buffer = StringBuffer()
      ..writeln('Badge(')
      ..writeln('  variant: BadgeVariant.$variant,')
      ..writeln("  child: Text('$text'),")
      ..write(')');

    return buffer.toString();
  }

  static String _buildDialogCode(Map<String, dynamic> properties) {
    final title = properties['title'] as String? ?? 'Dialog';
    final description = properties['description'] as String?;

    final buffer = StringBuffer()
      ..writeln('showDialog(')
      ..writeln('  context: context,')
      ..writeln('  builder: (context) => AlertDialog(')
      ..writeln("    title: Text('$title'),");

    if (description != null) {
      buffer.writeln("    content: Text('$description'),");
    }

    buffer
      ..writeln('    actions: [')
      ..writeln('      SecondaryButton(')
      ..writeln('        onPressed: () => Navigator.pop(context),')
      ..writeln("        child: Text('Cancel'),")
      ..writeln('      ),')
      ..writeln('      PrimaryButton(')
      ..writeln('        onPressed: () {')
      ..writeln('          // TODO: Implement action')
      ..writeln('          Navigator.pop(context);')
      ..writeln('        },')
      ..writeln("        child: Text('Confirm'),")
      ..writeln('      ),')
      ..writeln('    ],')
      ..writeln('  ),')
      ..write(')');

    return buffer.toString();
  }

  static String _buildGenericComponent(
    String componentName,
    Map<String, dynamic> properties,
  ) {
    final buffer = StringBuffer()..writeln('$componentName(');

    for (final entry in properties.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        buffer.writeln("  $key: '$value',");
      } else if (value is bool || value is num) {
        buffer.writeln('  $key: $value,');
      }
    }

    buffer.write(')');
    return buffer.toString();
  }

  static String _buildScreenCode(
    String screenType,
    String title,
    List<dynamic> components,
  ) {
    final buffer = StringBuffer()
      ..writeln('class ${_toPascalCase(title)}Screen extends StatelessWidget {')
      ..writeln('  const ${_toPascalCase(title)}Screen({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Widget build(BuildContext context) {')
      ..writeln('    return Scaffold(')
      ..writeln('      appBar: AppBar(')
      ..writeln("        title: Text('$title'),")
      ..writeln('      ),')
      ..writeln('      body: _buildBody(),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln()
      ..writeln('  Widget _buildBody() {');

    switch (screenType.toLowerCase()) {
      case 'list':
        buffer.write(_buildListScreen(components));
      case 'form':
        buffer.write(_buildFormScreen(components));
      case 'detail':
        buffer.write(_buildDetailScreen(components));
      default:
        buffer.write(_buildDefaultScreen(components));
    }

    buffer
      ..writeln('  }')
      ..writeln('}');

    return buffer.toString();
  }

  static String _buildFormCode(String formName, List<dynamic> fields) {
    final buffer = StringBuffer()
      ..writeln('class ${_toPascalCase(formName)}Form extends StatefulWidget {')
      ..writeln('  const ${_toPascalCase(formName)}Form({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  State<${_toPascalCase(formName)}Form> createState() => '
        '_${_toPascalCase(formName)}FormState();',
      )
      ..writeln('}')
      ..writeln()
      ..writeln(
        'class _${_toPascalCase(formName)}FormState '
        'extends State<${_toPascalCase(formName)}Form> {',
      )
      ..writeln('  final _formKey = GlobalKey<FormState>();')
      ..writeln();

    // Generate controllers for each field
    for (final field in fields) {
      final fieldMap = field as Map<String, dynamic>;
      final fieldName = fieldMap['name'] as String;
      buffer.writeln(
        '  final _${_toCamelCase(fieldName)}Controller = '
        'TextEditingController();',
      );
    }

    buffer
      ..writeln()
      ..writeln('  @override')
      ..writeln('  void dispose() {');

    for (final field in fields) {
      final fieldMap = field as Map<String, dynamic>;
      final fieldName = fieldMap['name'] as String;
      buffer.writeln('    _${_toCamelCase(fieldName)}Controller.dispose();');
    }

    buffer
      ..writeln('    super.dispose();')
      ..writeln('  }')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Widget build(BuildContext context) {')
      ..writeln('    return Form(')
      ..writeln('      key: _formKey,')
      ..writeln('      child: Column(')
      ..writeln('        children: [');

    // Generate form fields
    for (final field in fields) {
      final fieldMap = field as Map<String, dynamic>;
      final fieldName = fieldMap['name'] as String;
      // Reserved for future field type customization
      // ignore: unused_local_variable
      final fieldType = fieldMap['type'] as String? ?? 'text';
      final required = fieldMap['required'] as bool? ?? false;

      buffer
        ..writeln('          Input(')
        ..writeln("            label: '${_toTitleCase(fieldName)}',")
        ..writeln(
          '            controller: _${_toCamelCase(fieldName)}Controller,',
        );

      if (required) {
        buffer.writeln('            required: true,');
      }

      buffer
        ..writeln('          ),')
        ..writeln('          SizedBox(height: 16),');
    }

    buffer
      ..writeln('          Row(')
      ..writeln('            mainAxisAlignment: MainAxisAlignment.end,')
      ..writeln('            children: [')
      ..writeln('              SecondaryButton(')
      ..writeln('                onPressed: () {')
      ..writeln('                  // Reset form')
      ..writeln('                  _formKey.currentState?.reset();')
      ..writeln('                },')
      ..writeln("                child: Text('Reset'),")
      ..writeln('              ),')
      ..writeln('              SizedBox(width: 8),')
      ..writeln('              PrimaryButton(')
      ..writeln('                onPressed: () {')
      ..writeln('                  if (_formKey.currentState!.validate()) {')
      ..writeln('                    // TODO: Submit form')
      ..writeln('                  }')
      ..writeln('                },')
      ..writeln("                child: Text('Submit'),")
      ..writeln('              ),')
      ..writeln('            ],')
      ..writeln('          ),')
      ..writeln('        ],')
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln('}');

    return buffer.toString();
  }

  static String _buildStyleCode(
    String componentName,
    Map<String, dynamic> styleOptions,
  ) {
    final buffer = StringBuffer();

    switch (componentName.toLowerCase()) {
      case 'button':
        buffer.write(_buildButtonStyle(styleOptions));
      default:
        buffer.write(_buildGenericStyle(componentName, styleOptions));
    }

    return buffer.toString();
  }

  static String _buildButtonStyle(Map<String, dynamic> styleOptions) {
    final buffer = StringBuffer()..writeln('ButtonStyle(');

    if (styleOptions['size'] != null) {
      buffer.writeln('  size: ButtonSize.${styleOptions['size']},');
    }

    if (styleOptions['shape'] != null) {
      buffer.writeln('  shape: ButtonShape.${styleOptions['shape']},');
    }

    if (styleOptions['density'] != null) {
      buffer.writeln('  density: ButtonDensity.${styleOptions['density']},');
    }

    buffer.write(')');
    return buffer.toString();
  }

  static String _buildGenericStyle(
    String componentName,
    Map<String, dynamic> styleOptions,
  ) {
    final buffer = StringBuffer()..writeln('${componentName}Style(');

    for (final entry in styleOptions.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value},');
    }

    buffer.write(')');
    return buffer.toString();
  }

  static String _buildListScreen(List<dynamic> components) {
    final buffer = StringBuffer()
      ..writeln('    return ListView.separated(')
      ..writeln('      padding: const EdgeInsets.all(16),')
      ..writeln('      itemCount: 10, // TODO: Use actual data')
      ..writeln(
        '      separatorBuilder: (context, index) => SizedBox(height: 8),',
      )
      ..writeln('      itemBuilder: (context, index) {')
      ..writeln('        return Card(')
      ..writeln('          child: ListTile(')
      ..writeln(r"            title: Text('Item $index'),")
      ..writeln(r"            subtitle: Text('Description for item $index'),")
      ..writeln('            onTap: () {')
      ..writeln('              // TODO: Navigate to detail')
      ..writeln('            },')
      ..writeln('          ),')
      ..writeln('        );')
      ..writeln('      },')
      ..writeln('    );');

    return buffer.toString();
  }

  static String _buildFormScreen(List<dynamic> components) {
    final buffer = StringBuffer()
      ..writeln('    return SingleChildScrollView(')
      ..writeln('      padding: const EdgeInsets.all(16),')
      ..writeln('      child: Column(')
      ..writeln('        children: [')
      ..writeln('          // TODO: Add form fields')
      ..writeln('        ],')
      ..writeln('      ),')
      ..writeln('    );');

    return buffer.toString();
  }

  static String _buildDetailScreen(List<dynamic> components) {
    final buffer = StringBuffer()
      ..writeln('    return SingleChildScrollView(')
      ..writeln('      padding: const EdgeInsets.all(16),')
      ..writeln('      child: Column(')
      ..writeln('        crossAxisAlignment: CrossAxisAlignment.start,')
      ..writeln('        children: [')
      ..writeln('          // TODO: Add detail content')
      ..writeln('        ],')
      ..writeln('      ),')
      ..writeln('    );');

    return buffer.toString();
  }

  static String _buildDefaultScreen(List<dynamic> components) {
    final buffer = StringBuffer()
      ..writeln('    return Center(')
      ..writeln('      child: Column(')
      ..writeln('        mainAxisAlignment: MainAxisAlignment.center,')
      ..writeln('        children: [')
      ..writeln('          // TODO: Add content')
      ..writeln('        ],')
      ..writeln('      ),')
      ..writeln('    );');

    return buffer.toString();
  }

  static String _getButtonVariant(String? variant) {
    switch (variant?.toLowerCase()) {
      case 'primary':
        return 'PrimaryButton';
      case 'secondary':
        return 'SecondaryButton';
      case 'ghost':
        return 'GhostButton';
      case 'link':
        return 'LinkButton';
      case 'destructive':
        return 'DestructiveButton';
      default:
        return 'PrimaryButton';
    }
  }

  static String _toPascalCase(String text) {
    return text
        .split(RegExp(r'[_\s]+'))
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }

  static String _toCamelCase(String text) {
    final pascal = _toPascalCase(text);
    return pascal[0].toLowerCase() + pascal.substring(1);
  }

  static String _toTitleCase(String text) {
    return text
        .split(RegExp(r'[_\s]+'))
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
