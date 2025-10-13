import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A code block component for displaying formatted code.
///
/// Example:
/// ```dart
/// CodeBlock(
///   code: 'print("Hello, World!")',
///   language: 'dart',
/// )
/// ```
class CodeBlock extends UiComponent {
  /// Creates a CodeBlock component.
  ///
  /// Parameters:
  /// - [code]: Code content
  /// - [language]: Programming language
  /// - [showLineNumbers]: Whether to show line numbers
  const CodeBlock({
    super.key,
    required this.code,
    this.language,
    this.showLineNumbers = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Code content.
  final String code;

  /// Programming language.
  final String? language;

  /// Whether to show line numbers.
  final bool showLineNumbers;

  static const _divValue = 'div';

  @override
  String get baseClass => 'relative rounded-lg border bg-muted';

  @override
  Component build(BuildContext context) {
    final lines = code.split('\n');

    return div(
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        // Header
        if (language != null)
          div(
            classes:
                'flex items-center justify-between border-b px-4 py-2 text-sm',
            children: [
              span(
                classes: 'font-mono text-muted-foreground',
                child: text(language!),
              ),
              button(
                classes:
                    'rounded px-2 py-1 text-xs hover:bg-accent hover:text-accent-foreground',
                attributes: {
                  'type': 'button',
                  'aria-label': 'Copy code',
                },
                child: text('Copy'),
              ),
            ],
          ),
        // Code content
        pre(
          classes: 'overflow-x-auto p-4',
          child: Component.element(
            tag: 'code',
            classes: 'relative rounded font-mono text-sm',
            children: showLineNumbers
                ? _buildLinesWithNumbers(lines)
                : [text(code)],
          ),
        ),
      ],
    );
  }

  @override
  UiComponent copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? code,
    String? language,
    bool? showLineNumbers,
    Key? key,
  }) {
    return CodeBlock(
      key: key ?? this.key,
      code: code ?? this.code,
      language: language ?? this.language,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  static List<Component> _buildLinesWithNumbers(List<String> lines) {
    final components = <Component>[];

    for (int i = 0; i < lines.length; i += 1) {
      components.add(
        div(
          classes: 'flex',
          children: [
            span(
              classes:
                  'mr-4 inline-block w-8 text-right text-muted-foreground select-none',
              child: text((i + 1).toString()),
            ),
            span(child: text(lines[i])),
          ],
        ),
      );
    }

    return components;
  }
}

/// An inline code component.
class InlineCode extends UiComponent {
  /// Creates an InlineCode component.
  const InlineCode({
    super.key,
    required this.code,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _codeValue,
  }) : super(null);

  /// Code content.
  final String code;

  static const _codeValue = 'code';

  @override
  String get baseClass =>
      'relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold';

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: 'code',
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      child: text(code),
    );
  }

  @override
  UiComponent copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? code,
    Component? child,
    Key? key,
  }) {
    return InlineCode(
      key: key ?? this.key,
      code: code ?? this.code,
      child: child ?? this.child,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}
