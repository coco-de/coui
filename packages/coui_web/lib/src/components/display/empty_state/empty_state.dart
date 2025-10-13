import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// An empty state component for displaying when there's no content.
///
/// Example:
/// ```dart
/// EmptyState(
///   title: 'No results found',
///   description: 'Try adjusting your search',
///   icon: Icon.search,
/// )
/// ```
class EmptyState extends UiComponent {
  @override
  EmptyState copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? title,
    String? description,
    Component? icon,
    Component? action,
    Key? key,
  }) {
    return EmptyState(
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      action: action ?? this.action,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  /// Creates an EmptyState component.
  const EmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Title text.
  final String title;

  /// Optional description.
  final String? description;

  /// Optional icon.
  final Component? icon;

  /// Optional action button.
  final Component? action;

  static const _divValue = 'div';

  @override
  String get baseClass =>
      'flex min-h-[400px] flex-col items-center justify-center rounded-lg border border-dashed p-8 text-center';

  @override
  Component build(BuildContext context) {
    return div(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        if (icon != null)
          div(
            classes:
                'mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-muted',
            child: icon!,
          ),
        div(
          classes: 'mt-4 space-y-2',
          children: [
            h3(
              classes: 'text-lg font-semibold',
              child: text(title),
            ),
            if (description != null)
              p(
                classes: 'text-sm text-muted-foreground max-w-sm',
                child: text(description!),
              ),
          ],
        ),
        if (action != null)
          div(
            classes: 'mt-6',
            child: action!,
          ),
      ],
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
