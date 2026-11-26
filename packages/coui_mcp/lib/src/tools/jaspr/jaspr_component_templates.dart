/// Jaspr (coui_web) component code templates.
///
/// Mirrors the Flutter templates in `ComponentGenerator` but emits
/// Jaspr `Component` code using the `coui_web` API. Cross-platform
/// API parity is preserved at the named-parameter level (e.g. Card
/// uses `title`/`description`/`footer` on both platforms).
class JasprComponentTemplates {
  /// Builds a Jaspr component snippet by name.
  static String build(
    String componentName,
    String? variant,
    Map<String, dynamic> properties,
  ) {
    switch (componentName.toLowerCase()) {
      case 'button':
        return _button(variant, properties);
      case 'input':
      case 'textfield':
        return _textField(variant, properties);
      case 'card':
        return _card(properties);
      case 'avatar':
        return _avatar(properties);
      case 'badge':
        return _badge(properties);
      case 'dialog':
        return _dialog(properties);
      default:
        return _generic(componentName, properties);
    }
  }

  static String _button(String? variant, Map<String, dynamic> p) {
    final ctor = _buttonCtor(variant);
    final label = p['text'] as String? ?? 'Button';
    final size = p['size'] as String?;
    final hasOnPressed = p['onPressed'] as bool? ?? true;

    final buf = StringBuffer()..writeln('$ctor(');

    if (size != null) {
      buf.writeln('  size: CoreComponentSize.${size.toLowerCase()},');
    }
    if (hasOnPressed) {
      buf
        ..writeln('  onPressed: () {')
        ..writeln('    // TODO: Implement button action')
        ..writeln('  },');
    }
    buf
      ..writeln("  child: text('$label'),")
      ..write(')');
    return buf.toString();
  }

  static String _textField(String? variant, Map<String, dynamic> p) {
    final placeholder = p['placeholder'] as String? ?? p['label'] as String?;
    final obscure = p['obscureText'] as bool? ?? false;

    final buf = StringBuffer()
      ..writeln('TextField(')
      ..writeln('  variant: CoreTextFieldVariant.defaultVariant,');
    if (placeholder != null) {
      buf.writeln("  placeholder: '$placeholder',");
    }
    if (obscure) {
      buf.writeln('  obscureText: true,');
    }
    buf.write(')');
    return buf.toString();
  }

  static String _card(Map<String, dynamic> p) {
    final title = p['title'] as String?;
    final description = p['description'] as String?;
    final footer = p['footer'] as bool? ?? false;

    final buf = StringBuffer()..writeln('Card(');
    if (title != null) {
      buf.writeln("  header: text('$title'),");
    }
    if (description != null) {
      buf.writeln("  body: text('$description'),");
    }
    if (footer) {
      buf
        ..writeln("  footer: div(classes: 'flex gap-2 justify-end', [")
        ..writeln('    Button.ghost(')
        ..writeln('      onPressed: () {},')
        ..writeln("      child: text('Cancel'),")
        ..writeln('    ),')
        ..writeln('    Button.primary(')
        ..writeln('      onPressed: () {},')
        ..writeln("      child: text('Confirm'),")
        ..writeln('    ),')
        ..writeln('  ]),');
    }
    buf.write(')');
    return buf.toString();
  }

  static String _avatar(Map<String, dynamic> p) {
    final image = p['image'] as String?;
    final initials = p['initials'] as String?;
    final size = (p['size'] as String? ?? 'md').toLowerCase();

    final buf = StringBuffer()
      ..writeln('Avatar(')
      ..writeln('  size: CoreComponentSize.$size,');
    if (image != null) {
      buf.writeln("  src: '$image',");
    } else if (initials != null) {
      buf.writeln("  initials: '$initials',");
    }
    buf.write(')');
    return buf.toString();
  }

  static String _badge(Map<String, dynamic> p) {
    final label = p['text'] as String? ?? 'Badge';
    final variant = p['variant'] as String? ?? 'primary';
    final buf = StringBuffer()
      ..writeln('Badge(')
      ..writeln('  variant: CoreComponentVariant.$variant,')
      ..writeln("  child: text('$label'),")
      ..write(')');
    return buf.toString();
  }

  static String _dialog(Map<String, dynamic> p) {
    final title = p['title'] as String? ?? 'Dialog';
    final description = p['description'] as String?;

    // In Jaspr, dialogs are managed via a controller/state pattern.
    // We emit a Component-shaped snippet rather than an imperative call.
    final buf = StringBuffer()
      ..writeln('Dialog(')
      ..writeln("  title: text('$title'),");
    if (description != null) {
      buf.writeln("  body: text('$description'),");
    }
    buf
      ..writeln("  footer: div(classes: 'flex gap-2 justify-end', [")
      ..writeln('    Button.ghost(')
      ..writeln('      onPressed: () {/* close */},')
      ..writeln("      child: text('Cancel'),")
      ..writeln('    ),')
      ..writeln('    Button.primary(')
      ..writeln('      onPressed: () {')
      ..writeln('        // TODO: Implement action')
      ..writeln('      },')
      ..writeln("      child: text('Confirm'),")
      ..writeln('    ),')
      ..writeln('  ]),')
      ..write(')');
    return buf.toString();
  }

  static String _generic(String name, Map<String, dynamic> p) {
    final buf = StringBuffer()..writeln('$name(');
    for (final entry in p.entries) {
      final value = entry.value;
      if (value is String) {
        buf.writeln("  ${entry.key}: '$value',");
      } else if (value is bool || value is num) {
        buf.writeln('  ${entry.key}: $value,');
      }
    }
    buf.write(')');
    return buf.toString();
  }

  static String _buttonCtor(String? variant) {
    switch (variant?.toLowerCase()) {
      case 'primary':
        return 'Button.primary';
      case 'secondary':
        return 'Button.secondary';
      case 'outline':
      case 'outlined':
        return 'Button.outline';
      case 'ghost':
        return 'Button.ghost';
      case 'link':
        return 'Button.link';
      case 'destructive':
        return 'Button.destructive';
      default:
        return 'Button.primary';
    }
  }

  /// Builds a Jaspr screen wrapper class.
  static String buildScreen(
    String screenType,
    String title,
    List<dynamic> components,
  ) {
    final className = _toPascalCase(title);
    final buf = StringBuffer()
      ..writeln('class ${className}Screen extends StatelessComponent {')
      ..writeln('  const ${className}Screen({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Iterable<Component> build(BuildContext context) sync* {')
      ..writeln('    yield div(')
      ..writeln("      classes: 'min-h-screen p-8',")
      ..writeln('      [')
      ..writeln(
        "        h1(classes: 'text-2xl font-bold mb-4', "
        "[text('$title')]),",
      );

    switch (screenType.toLowerCase()) {
      case 'list':
        _appendListBody(buf);
      case 'form':
        _appendFormBody(buf);
      case 'detail':
        _appendDetailBody(buf);
      default:
        _appendDefaultBody(buf);
    }

    buf
      ..writeln('      ],')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln('}');
    return buf.toString();
  }

  static void _appendListBody(StringBuffer buf) {
    buf
      ..writeln("        div(classes: 'space-y-2', [")
      ..writeln('          // TODO: Render list items')
      ..writeln('        ]),');
  }

  static void _appendFormBody(StringBuffer buf) {
    buf
      ..writeln("        div(classes: 'max-w-md space-y-4', [")
      ..writeln('          // TODO: Add form fields')
      ..writeln('        ]),');
  }

  static void _appendDetailBody(StringBuffer buf) {
    buf
      ..writeln("        div(classes: 'prose max-w-none', [")
      ..writeln('          // TODO: Add detail content')
      ..writeln('        ]),');
  }

  static void _appendDefaultBody(StringBuffer buf) {
    buf
      ..writeln('        div([')
      ..writeln('          // TODO: Add content')
      ..writeln('        ]),');
  }

  /// Builds a Jaspr form component.
  static String buildForm(String formName, List<dynamic> fields) {
    final className = _toPascalCase(formName);
    final buf = StringBuffer()
      ..writeln('class ${className}Form extends StatefulComponent {')
      ..writeln('  const ${className}Form({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln(
        '  State<${className}Form> createState() '
        '=> _${className}FormState();',
      )
      ..writeln('}')
      ..writeln()
      ..writeln(
        'class _${className}FormState '
        'extends State<${className}Form> {',
      )
      ..writeln('  final Map<String, String> _values = {};')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Iterable<Component> build(BuildContext context) sync* {')
      ..writeln("    yield div(classes: 'space-y-4', [");

    for (final field in fields) {
      final m = field as Map<String, dynamic>;
      final name = m['name'] as String;
      final required = m['required'] as bool? ?? false;
      final label = _toTitleCase(name);
      final star = required ? ' *' : '';
      buf
        ..writeln('      div([')
        ..writeln(
          "        label(classes: 'block text-sm font-medium', "
          "[text('$label$star')]),",
        )
        ..writeln('        TextField(')
        ..writeln('          variant: CoreTextFieldVariant.defaultVariant,')
        ..writeln("          placeholder: '$label',")
        ..writeln("          onChanged: (v) => _values['$name'] = v,")
        ..writeln('        ),')
        ..writeln('      ]),');
    }

    buf
      ..writeln("      div(classes: 'flex gap-2 justify-end', [")
      ..writeln('        Button.ghost(')
      ..writeln('          onPressed: () => setState(() => _values.clear()),')
      ..writeln("          child: text('Reset'),")
      ..writeln('        ),')
      ..writeln('        Button.primary(')
      ..writeln('          onPressed: () {')
      ..writeln('            // TODO: Submit form')
      ..writeln('          },')
      ..writeln("          child: text('Submit'),")
      ..writeln('        ),')
      ..writeln('      ]),')
      ..writeln('    ]);')
      ..writeln('  }')
      ..writeln('}');
    return buf.toString();
  }

  /// Builds a Jaspr style snippet for a component.
  static String buildStyle(
    String componentName,
    Map<String, dynamic> styleOptions,
  ) {
    // Jaspr styling is Tailwind-based; emit a class string helper.
    final classes = <String>[];
    styleOptions.forEach((key, value) {
      // Pass through user class fragments; bool flags map to flag names.
      if (value is String) {
        classes.add(value);
      } else if (value == true) {
        classes.add(key);
      }
    });
    final classString = classes.join(' ');
    return "// Tailwind classes for $componentName:\nconst ${componentName}Classes = '$classString';";
  }

  static String _toPascalCase(String text) {
    return text
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }

  static String _toTitleCase(String text) {
    return text
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
