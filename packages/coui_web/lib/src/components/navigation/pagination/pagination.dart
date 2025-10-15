// ignore_for_file: avoid-using-non-ascii-symbols, avoid-duplicate-cascades, prefer-moving-repeated-invocations-to-variable, prefer-extracting-common-initializers, prefer-method-over-getter, avoid-duplicate-collection-elements

import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for page change.
typedef PageChangeCallback = void Function(int page);

/// A pagination component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// Pagination(
///   currentPage: 1,
///   totalPages: 10,
///   onPageChanged: (page) => print('Page: $page'),
/// )
/// ```
class Pagination extends UiComponent {
  /// Creates a Pagination component.
  ///
  /// Parameters:
  /// - [currentPage]: Current active page (1-indexed)
  /// - [totalPages]: Total number of pages
  /// - [onPageChanged]: Callback when page changes
  const Pagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPageChanged,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _navValue,
  }) : super(null);

  /// Current active page.
  final int currentPage;

  /// Total number of pages.
  final int totalPages;

  /// Callback when page changes.
  final PageChangeCallback? onPageChanged;

  /// Previous page icon character code (U+2039 - ‹).
  static const _kPrevIconCode = 0x2039;

  /// Next page icon character code (U+203A - ›).
  static const _kNextIconCode = 0x203A;

  static const _maxVisiblePages = 7;

  static const _navValue = 'nav';

  /// Previous page icon character.
  static String get _kPrevIcon => String.fromCharCode(_kPrevIconCode);

  /// Next page icon character.
  static String get _kNextIcon => String.fromCharCode(_kNextIconCode);

  @override
  Pagination copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    PageChangeCallback? onPageChanged,
    int? currentPage,
    int? totalPages,
    Key? key,
  }) {
    return Pagination(
      key: key ?? this.key,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      onPageChanged: onPageChanged ?? this.onPageChanged,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final pages = <Component>[];

    // Previous button
    pages.add(
      _buildPageButton(
        label: _kPrevIcon,
        page: currentPage - 1,
        enabled: currentPage > 1,
        ariaLabel: 'Previous page',
      ),
    );

    // Page numbers (simplified - show first, current, and last)
    if (totalPages <= _maxVisiblePages) {
      // Show all pages
      for (int i = 1; i <= totalPages; i += 1) {
        pages.add(_buildPageButton(label: i.toString(), page: i));
      }
    } else {
      // Show condensed version
      // ignore: prefer-moving-repeated-invocations-to-variable
      pages.addAll([
        _buildPageButton(label: '1', page: 1),
        _buildEllipsis,
        _buildPageButton(label: currentPage.toString(), page: currentPage),
        _buildEllipsis,
        _buildPageButton(label: totalPages.toString(), page: totalPages),
      ]);
    }

    // Next button
    pages.add(
      _buildPageButton(
        label: _kNextIcon,
        page: currentPage + 1,
        enabled: currentPage < totalPages,
        ariaLabel: 'Next page',
      ),
    );

    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        'role': 'navigation',
        'aria-label': 'Pagination',
      },
      events: this.events,
      children: pages,
    );
  }

  @override
  String get baseClass => 'flex items-center justify-center space-x-2';

  Component _buildPageButton({
    required String label,
    required int page,
    bool enabled = true,
    String? ariaLabel,
  }) {
    final isActive = page == currentPage;
    final baseClasses =
        'inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 w-10';
    final activeClasses = isActive
        ? 'bg-primary text-primary-foreground hover:bg-primary/90'
        : 'hover:bg-accent hover:text-accent-foreground';

    return Component.element(
      child: text(label),
      tag: 'button',
      classes: '$baseClasses $activeClasses',
      attributes: {
        'type': 'button',
        if (!enabled) 'disabled': '',
        'aria-label': ?ariaLabel,
        if (isActive) 'aria-current': 'page',
      },
      events: enabled && onPageChanged != null
          ? {
              'click': (event) => onPageChanged(page),
            }
          : {},
    );
  }

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  /// Builds an ellipsis component for pagination.
  static Component get _buildEllipsis {
    return span(
      child: text('...'),
      classes: 'inline-flex items-center justify-center h-10 px-4',
    );
  }
}
