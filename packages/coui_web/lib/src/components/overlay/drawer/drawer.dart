// ignore_for_file: avoid-using-non-ascii-symbols, prefer-correct-handler-name

import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for drawer close.
typedef DrawerCloseCallback = void Function();

/// A drawer component for side panel navigation.
///
/// Example:
/// ```dart
/// Drawer(
///   isOpen: true,
///   onClose: () => print('Closed'),
///   child: div(child: text('Drawer content')),
/// )
/// ```
class Drawer extends UiComponent {
  /// Creates a Drawer component.
  ///
  /// Parameters:
  /// - [isOpen]: Whether the drawer is open
  /// - [onClose]: Callback when drawer should close
  /// - [child]: Drawer content
  /// - [side]: Drawer position (left or right)
  Drawer({
    super.key,
    required this.isOpen,
    this.onClose,
    Component? child,
    this.side = DrawerSide.left,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null, child: child);

  /// Whether the drawer is open.
  final bool isOpen;

  /// Callback when drawer should close.
  final DrawerCloseCallback? onClose;

  /// Drawer position.
  final DrawerSide side;

  /// Close icon character code (U+00D7 - ×).
  static const _kCloseIconCode = 0x00D7;

  static const _divValue = 'div';

  /// Close icon character.
  static String get _kCloseIcon => String.fromCharCode(_kCloseIconCode);

  @override
  Drawer copyWith({
    bool? isOpen,
    Component? child,
    DrawerCloseCallback? onClose,
    DrawerSide? side,
    Key? key,
    Map<String, String>? attributes,
    String? classes,
    String? id,
    String? tag,
    Styles? css,
  }) {
    return Drawer(
      key: key ?? this.key,
      isOpen: isOpen ?? this.isOpen,
      onClose: onClose ?? this.onClose,
      child: child ?? this.child,
      side: side ?? this.side,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return isOpen
        ? div(
            children: [
              // Overlay
              div(
                classes:
                    'fixed inset-0 z-50 bg-background/80 backdrop-blur-sm transition-opacity',
                events: _overlayEvents,
              ),
              // Drawer content
              div(
                children: [
                  // Header with close button
                  div(
                    children: [
                      span(
                        child: text('Drawer'),
                        classes: 'text-lg font-semibold',
                      ),
                      button(
                        children: [
                          text(_kCloseIcon),
                        ],
                        classes:
                            'rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
                        attributes: {
                          'type': 'button',
                          'aria-label': 'Close',
                        },
                        events: _closeEvents,
                      ),
                    ],
                    classes: 'flex items-center justify-between p-4 border-b',
                  ),
                  // Content
                  div(
                    child: child,
                    classes: 'p-4',
                  ),
                ],
                classes: _drawerClasses,
                attributes: {
                  'role': 'dialog',
                  'aria-modal': 'true',
                },
              ),
            ],
            id: id,
            classes: _buildClasses(),
            styles: this.css,
            attributes: this.componentAttributes,
            events: this.events,
          )
        : Component.empty();
  }

  @override
  String get baseClass => 'relative z-50';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  String get _drawerClasses {
    const base =
        'fixed z-50 gap-4 bg-background p-6 shadow-lg transition ease-in-out';
    final position = switch (side) {
      DrawerSide.left => 'inset-y-0 left-0 h-full w-3/4 border-r sm:max-w-sm',
      DrawerSide.right => 'inset-y-0 right-0 h-full w-3/4 border-l sm:max-w-sm',
      DrawerSide.top => 'inset-x-0 top-0 border-b',
      DrawerSide.bottom => 'inset-x-0 bottom-0 border-t',
    };

    return '$base $position';
  }

  Map<String, List<dynamic>> get _overlayEvents {
    final currentOnClose = onClose;

    return currentOnClose == null
        ? {}
        : {
            'click': [
              (event) => currentOnClose(),
            ],
          };
  }

  Map<String, List<dynamic>> get _closeEvents {
    final currentOnClose = onClose;

    return currentOnClose == null
        ? {}
        : {
            'click': [
              (event) => currentOnClose(),
            ],
          };
  }
}

/// Drawer position options.
enum DrawerSide {
  /// Display from the left side.
  left,

  /// Display from the right side.
  right,

  /// Display from the top.
  top,

  /// Display from the bottom.
  bottom,
}
