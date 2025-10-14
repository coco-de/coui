import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A scaffold component providing basic app structure.
///
/// This component provides a standard layout structure with optional
/// header, footer, and sidebar areas.
///
/// Example:
/// ```dart
/// Scaffold(
///   header: AppBar(children: [text('My App')]),
///   body: div(children: [text('Main content')]),
///   footer: div(children: [text('Footer')]),
/// )
/// ```
class Scaffold extends UiComponent {
  /// Creates a Scaffold component.
  ///
  /// Parameters:
  /// - [body]: Main content area (required)
  /// - [header]: Optional header/app bar
  /// - [footer]: Optional footer
  /// - [sidebar]: Optional sidebar
  const Scaffold({
    super.key,
    required this.body,
    this.header,
    this.footer,
    this.sidebar,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Main content area.
  final Component body;

  /// Optional header/app bar.
  final Component? header;

  /// Optional footer.
  final Component? footer;

  /// Optional sidebar.
  final Component? sidebar;

  static const _divValue = 'div';

  @override
  Scaffold copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? body,
    Component? header,
    Component? footer,
    Component? sidebar,
    Key? key,
  }) {
    return Scaffold(
      key: key ?? this.key,
      body: body ?? this.body,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      sidebar: sidebar ?? this.sidebar,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final children = <Component>[];

    // Add header if provided
    final currentHeader = header;
    if (currentHeader != null) {
      children.add(currentHeader);
    }

    // Add main content area
    if (sidebar == null) {
      // Layout without sidebar
      children.add(
        div(
          child: body,
          classes: 'flex-1',
        ),
      );
    } else {
      // Layout with sidebar
      final currentSidebar = sidebar;
      children.add(
        div(
          children: [
            currentSidebar,
            div(
              child: body,
              classes: 'flex-1',
            ),
          ],
          classes: 'flex flex-1',
        ),
      );
    } // Add footer if provided
    final currentFooter = footer;
    if (currentFooter != null) {
      children.add(currentFooter);
    }

    return Component.element(
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
  String get baseClass => 'min-h-screen flex flex-col';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}

/// An app bar component for the scaffold header.
class AppBar extends UiComponent {
  /// Creates an AppBar component.
  AppBar({
    List<Component>? children,
    Component? child,
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _headerValue,
  }) : super(
         children,
         child: child,
       );

  static const _headerValue = 'header';

  static const _baseClasses =
      'sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60';

  @override
  AppBar copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    List<Component>? children,
    Key? key,
  }) {
    return AppBar(
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

/// A sidebar component.
class Sidebar extends UiComponent {
  /// Creates a Sidebar component.
  Sidebar({
    List<Component>? children,
    Component? child,
    super.key,
    this.width = '250px',
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _asideValue,
  }) : super(
         children,
         child: child,
       );

  /// Width of the sidebar.
  final String width;

  static const _asideValue = 'aside';

  static const _baseClasses = 'border-r bg-background';

  @override
  Sidebar copyWith({
    Component? child,
    Key? key,
    List<Component>? children,
    Map<String, String>? attributes,
    String? classes,
    String? id,
    String? tag,
    String? width,
    Styles? css,
  }) {
    return Sidebar(
      children: children ?? this.children,
      child: child ?? this.child,
      key: key ?? this.key,
      width: width ?? this.width,
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
      styles: {
        'width': width,
      },
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
