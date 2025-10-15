import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/variant_system.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
import 'package:jaspr/jaspr.dart';

/// A dialog (modal) component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// Dialog(
///   open: true,
///   children: [
///     DialogContent(
///       children: [
///         DialogHeader(
///           children: [
///             DialogTitle(titleChild: text('Are you sure?')),
///             DialogDescription(descriptionChild: text('This action cannot be undone.')),
///           ],
///         ),
///         DialogFooter(
///           children: [
///             Button.outline(child: text('Cancel')),
///             Button.primary(child: text('Continue')),
///           ],
///         ),
///       ],
///     ),
///   ],
/// )
/// ```
class Dialog extends UiComponent {
  /// Creates a Dialog component.
  ///
  /// Parameters:
  /// - [open]: Whether the dialog is open
  /// - [children]: Child components (typically DialogContent)
  Dialog({
    List<Component>? children,
    Component? child,
    super.key,
    this.open = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         children,
         child: child,
       );

  /// Whether the dialog is open.
  final bool open;

  static const _divValue = 'div';

  @override
  Dialog copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    bool? open,
    List<Component>? children,
    Component? child,
    Key? key,
  }) {
    return Dialog(
      children: children,
      child: child,
      key: key ?? this.key,
      open: open ?? this.open,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.fragment(
      children: open
          ? [
              // Overlay
              Component.element(
                tag: _divValue,
                classes: DialogVariant.overlay.classes,
              ),
              // Content wrapper
              Component.element(
                child: child,
                tag: _divValue,
                classes: 'fixed inset-0 z-50 flex items-center justify-center',
                children: children,
              ),
            ]
          : [],
    );
  }

  @override
  String get baseClass => '';
}

/// Dialog content component.
class DialogContent extends UiComponent {
  /// Creates a DialogContent component.
  DialogContent({
    List<Component>? children,
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         children,
         child: child,
         style: [
           DialogVariantStyle(variant: DialogVariant.content),
         ],
       );

  static const _divValue = 'div';

  @override
  DialogContent copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Component? child,
    Key? key,
  }) {
    return DialogContent(
      children: children ?? this.children,
      child: child ?? this.child,
      key: key ?? this.key,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      child: child,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass => '';

  String _buildClasses() {
    final classList = <String>[];

    // Add variant classes from style
    final currentStyle = style;
    if (currentStyle != null) {
      for (final s in currentStyle) {
        classList.add(s.cssClass);
      }
    }

    // Add user classes
    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}

/// Dialog header component.
class DialogHeader extends UiComponent {
  /// Creates a DialogHeader component.
  DialogHeader({
    List<Component>? children,
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         children,
         child: child,
       );

  static const _divValue = 'div';

  static const _baseClasses =
      'flex flex-col space-y-1.5 text-center sm:text-left';

  @override
  DialogHeader copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Component? child,
    Key? key,
  }) {
    return DialogHeader(
      children: children ?? this.children,
      child: child ?? this.child,
      key: key ?? this.key,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      child: child,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass => _baseClasses;

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}

/// Dialog footer component.
class DialogFooter extends UiComponent {
  /// Creates a DialogFooter component.
  DialogFooter({
    List<Component>? children,
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         children,
         child: child,
       );

  static const _divValue = 'div';

  static const _baseClasses =
      'flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2';

  @override
  DialogFooter copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Component? child,
    Key? key,
  }) {
    return DialogFooter(
      children: children ?? this.children,
      child: child ?? this.child,
      key: key ?? this.key,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      child: child,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass => _baseClasses;

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}

/// Dialog title component.
class DialogTitle extends UiComponent {
  /// Creates a DialogTitle component.
  const DialogTitle({
    required Component this.titleChild,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _h2Value,
  }) : super(null);

  /// Content of the title.
  final Component titleChild;

  static const _h2Value = 'h2';

  static const _baseClasses =
      'text-lg font-semibold leading-none tracking-tight';

  @override
  DialogTitle copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Component? child,
    Component? titleChild,
    Key? key,
  }) {
    return DialogTitle(
      titleChild: titleChild ?? this.titleChild,
      key: key ?? this.key,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      child: titleChild,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass => _baseClasses;

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}

/// Dialog description component.
class DialogDescription extends UiComponent {
  /// Creates a DialogDescription component.
  const DialogDescription({
    required Component this.descriptionChild,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _pValue,
  }) : super(null);

  /// Content of the description.
  final Component descriptionChild;

  static const _pValue = 'p';

  static const _baseClasses = 'text-sm text-muted-foreground';

  @override
  DialogDescription copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Component? child,
    Component? descriptionChild,
    Key? key,
  }) {
    return DialogDescription(
      descriptionChild: descriptionChild ?? this.descriptionChild,
      key: key ?? this.key,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      child: descriptionChild,
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass => _baseClasses;

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
