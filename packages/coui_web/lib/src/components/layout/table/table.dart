import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A table component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// Table(
///   children: [
///     TableHeader(
///       children: [
///         TableRow(
///           children: [
///             TableHead(child: text('Name')),
///             TableHead(child: text('Email')),
///           ],
///         ),
///       ],
///     ),
///     TableBody(
///       children: [
///         TableRow(
///           children: [
///             TableCell(child: text('John')),
///             TableCell(child: text('john@example.com')),
///           ],
///         ),
///       ],
///     ),
///   ],
/// )
/// ```
class Table extends UiComponent {
  /// Creates a Table component.
  Table({
    List<Component>? children,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _tableValue,
  }) : super(
         children,
       );

  static const _tableValue = 'table';

  @override
  Table copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Key? key,
  }) {
    return Table(
      key: key ?? this.key,
      children: children ?? this.children,
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
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass => 'w-full caption-bottom text-sm';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// Table header component.
class TableHeader extends UiComponent {
  /// Creates a TableHeader component.
  TableHeader({
    List<Component>? children,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _theadValue,
  }) : super(
         children,
       );

  static const _theadValue = 'thead';

  @override
  TableHeader copyWith({
    Key? key,
    List<Component>? children,
    Map<String, String>? attributes,
    String? classes,
    String? id,
    String? tag,
    Styles? css,
  }) {
    return TableHeader(
      attributes: attributes ?? this.componentAttributes,
      children: children ?? this.children,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass => '[&_tr]:border-b';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// Table body component.
class TableBody extends UiComponent {
  /// Creates a TableBody component.
  TableBody({
    List<Component>? children,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _tbodyValue,
  }) : super(
         children,
       );

  static const _tbodyValue = 'tbody';

  @override
  TableBody copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Key? key,
  }) {
    return TableBody(
      key: key ?? this.key,
      children: children ?? this.children,
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
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass => '[&_tr:last-child]:border-0';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// Table row component.
class TableRow extends UiComponent {
  /// Creates a TableRow component.
  TableRow({
    List<Component>? children,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _trValue,
  }) : super(
         children,
       );

  static const _trValue = 'tr';

  @override
  TableRow copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<Component>? children,
    String? tag,
  }) {
    return TableRow(
      key: key ?? this.key,
      children: children ?? this.children,
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
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass =>
      'border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// Table head cell component.
class TableHead extends UiComponent {
  /// Creates a TableHead component.
  TableHead({
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _thValue,
  }) : super(
         null,
         child: child,
       );

  static const _thValue = 'th';

  @override
  TableHead copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    Component? child,
    String? tag,
  }) {
    return TableHead(
      key: key ?? this.key,
      child: child ?? this.child,
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
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      child: child,
    );
  }

  @override
  String get baseClass =>
      'h-12 px-4 text-left align-middle font-medium text-muted-foreground [&:has([role=checkbox])]:pr-0';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// Table data cell component.
class TableCell extends UiComponent {
  /// Creates a TableCell component.
  TableCell({
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _tdValue,
  }) : super(
         null,
         child: child,
       );

  static const _tdValue = 'td';

  @override
  TableCell copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    Component? child,
    String? tag,
  }) {
    return TableCell(
      key: key ?? this.key,
      child: child ?? this.child,
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
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      child: child,
    );
  }

  @override
  String get baseClass => 'p-4 align-middle [&:has([role=checkbox])]:pr-0';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}
