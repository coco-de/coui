import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/navigation/pagination/pagination_style.dart';
import 'package:jaspr/jaspr.dart';

/// A pagination component for navigating through pages.
///
/// The Pagination component provides page navigation with intelligent
/// ellipsis handling for large page counts. It follows DaisyUI's join
/// component pattern for button grouping.
///
/// Features:
/// - Automatic ellipsis for large page counts
/// - Current page highlighting
/// - First/last page quick navigation
/// - Previous/next buttons
/// - Customizable page change callback
///
/// Example:
/// ```dart
/// Pagination(
///   currentPage: 5,
///   totalPages: 20,
///   onPageChanged: (page) => handlePageChange(page),
///   showFirstLast: true,
/// )
/// ```
class Pagination extends UiComponent {
  /// Creates a Pagination component.
  ///
  /// - [currentPage]: Current active page (1-indexed).
  /// - [totalPages]: Total number of pages.
  /// - [onPageChanged]: Callback when page changes (Flutter-compatible).
  /// - [showFirstLast]: Whether to show first/last page buttons.
  /// - [maxVisible]: Maximum number of page buttons to show before using ellipsis.
  /// - [style]: List of [PaginationStyling] instances for styling.
  const Pagination({
    super.attributes,
    super.child,
    super.classes,
    required this.currentPage,
    super.css,
    super.id,
    super.key,
    this.maxVisible = 7,
    this.onPageChanged,
    this.showFirstLast = true,
    List<PaginationStyling>? style,
    super.tag = 'div',
    required this.totalPages,
  }) : super(null, style: style);

  /// Current active page (1-indexed).
  final int currentPage;

  /// Total number of pages.
  final int totalPages;

  /// Callback when page changes.
  ///
  /// Flutter-compatible void Function(int) callback.
  /// Receives the new page number (1-indexed).
  final void Function(int)? onPageChanged;

  /// Whether to show first/last page buttons.
  final bool showFirstLast;

  /// Maximum number of page buttons to show before using ellipsis.
  final int maxVisible;

  // --- Static Style Modifiers ---

  /// Vertical orientation. `join-vertical`.
  static const vertical =
      PaginationStyle('join-vertical', type: StyleType.layout);

  @override
  String get baseClass => 'join';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA attributes for accessibility
    if (!userProvidedAttributes.containsKey('role')) {
      attributes.addRole('navigation');
    }

    if (!userProvidedAttributes.containsKey('aria-label')) {
      attributes.addAria('label', 'Pagination Navigation');
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();
    final buttons = <Component>[];

    // First page button (optional)
    if (showFirstLast && totalPages > 1) {
      buttons.add(_buildPageButton('≪', 1, isSymbol: true));
    }

    // Previous page button
    if (totalPages > 1) {
      buttons.add(_buildPageButton('‹', currentPage - 1, isSymbol: true));
    }

    // Page number buttons with ellipsis logic
    final pageButtons = _calculatePageButtons();
    for (final pageData in pageButtons) {
      if (pageData['isEllipsis'] == true) {
        buttons.add(_buildEllipsis());
      } else {
        final page = pageData['page'] as int;
        buttons.add(_buildPageButton(page.toString(), page));
      }
    }

    // Next page button
    if (totalPages > 1) {
      buttons.add(_buildPageButton('›', currentPage + 1, isSymbol: true));
    }

    // Last page button (optional)
    if (showFirstLast && totalPages > 1) {
      buttons.add(_buildPageButton('≫', totalPages, isSymbol: true));
    }

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      css: css,
      id: id,
      tag: tag,
      children: buttons,
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    // Add custom styles
    if (style != null) {
      for (final s in style!) {
        if (s is PaginationStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    return stylesList;
  }

  /// Calculate which page buttons to show with ellipsis logic.
  ///
  /// Strategy:
  /// - Always show first and last page
  /// - Show pages around current page
  /// - Use ellipsis when gap is large enough
  List<Map<String, dynamic>> _calculatePageButtons() {
    final buttons = <Map<String, dynamic>>[];

    if (totalPages <= maxVisible) {
      // Show all pages if total is within maxVisible
      for (var i = 1; i <= totalPages; i++) {
        buttons.add({'page': i, 'isEllipsis': false});
      }
      return buttons;
    }

    // Calculate visible page range around current page
    final halfVisible = (maxVisible - 2) ~/ 2; // Reserve 2 for first/last
    var startPage = currentPage - halfVisible;
    var endPage = currentPage + halfVisible;

    // Adjust if near start
    if (startPage < 2) {
      endPage += 2 - startPage;
      startPage = 2;
    }

    // Adjust if near end
    if (endPage > totalPages - 1) {
      startPage -= endPage - (totalPages - 1);
      endPage = totalPages - 1;
    }

    // Clamp to valid range
    startPage = startPage.clamp(2, totalPages - 1);
    endPage = endPage.clamp(2, totalPages - 1);

    // First page
    buttons.add({'page': 1, 'isEllipsis': false});

    // Left ellipsis
    if (startPage > 2) {
      buttons.add({'isEllipsis': true});
    }

    // Middle pages
    for (var i = startPage; i <= endPage; i++) {
      buttons.add({'page': i, 'isEllipsis': false});
    }

    // Right ellipsis
    if (endPage < totalPages - 1) {
      buttons.add({'isEllipsis': true});
    }

    // Last page
    if (totalPages > 1) {
      buttons.add({'page': totalPages, 'isEllipsis': false});
    }

    return buttons;
  }

  Component _buildPageButton(String label, int targetPage,
      {bool isSymbol = false}) {
    final isActive = targetPage == currentPage;
    final isDisabled =
        targetPage < 1 || targetPage > totalPages || (isSymbol && isActive);

    final buttonClasses = [
      'join-item',
      'btn',
      if (isActive) 'btn-active',
      if (isDisabled) 'btn-disabled',
    ].join(' ');

    return Component.element(
      classes: buttonClasses,
      events: !isDisabled && onPageChanged != null
          ? {
              'click': (_) => onPageChanged!(targetPage),
            }
          : null,
      tag: 'button',
      children: [Component.text(label)],
    );
  }

  Component _buildEllipsis() {
    return Component.element(
      classes: 'join-item btn btn-disabled',
      tag: 'button',
      children: [Component.text('...')],
    );
  }

  @override
  Pagination copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    int? currentPage,
    Styles? css,
    String? id,
    Key? key,
    int? maxVisible,
    void Function(int)? onPageChanged,
    bool? showFirstLast,
    List<PaginationStyling>? style,
    String? tag,
    int? totalPages,
  }) {
    return Pagination(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      currentPage: currentPage ?? this.currentPage,
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      maxVisible: maxVisible ?? this.maxVisible,
      onPageChanged: onPageChanged ?? this.onPageChanged,
      showFirstLast: showFirstLast ?? this.showFirstLast,
      style: style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<PaginationStyling>?
                ? currentStyle
                : null;
          }(),
      tag: tag ?? this.tag,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}