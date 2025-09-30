import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart';

/// A modal dialog component for displaying important content or actions.
///
/// The Dialog component creates an overlay that blocks interaction with the
/// rest of the page until dismissed. It follows DaisyUI's dialog/modal patterns
/// and provides Flutter-compatible API.
///
/// Features:
/// - Modal and non-modal modes
/// - Backdrop click to close
/// - Keyboard (ESC) support
/// - Accessibility with ARIA attributes
/// - Customizable positioning and styling
///
/// Example:
/// ```dart
/// Dialog(
///   [
///     DialogTitle([text('Confirm Action')]),
///     DialogContent([text('Are you sure?')]),
///     DialogActions([
///       Button([text('Cancel')], onPressed: () => closeDialog()),
///       Button.primary([text('Confirm')], onPressed: () => confirm()),
///     ]),
///   ],
///   open: true,
///   onClose: () => handleClose(),
///   style: [Dialog.modal],
/// )
/// ```
class Dialog extends UiComponent {
  /// Creates a Dialog component.
  ///
  /// - [children]: Content of the dialog (title, content, actions).
  /// - [open]: Whether the dialog is open/visible.
  /// - [onClose]: Callback when dialog should close (Flutter-compatible).
  /// - [modal]: Whether to show backdrop and block interaction.
  /// - [closeOnBackdrop]: Whether clicking backdrop closes the dialog.
  /// - [closeOnEscape]: Whether pressing ESC closes the dialog.
  /// - [style]: List of [DialogStyling] instances for styling.
  const Dialog(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    this.closeOnBackdrop = true,
    this.closeOnEscape = true,
    super.css,
    super.id,
    super.key,
    this.modal = true,
    this.onClose,
    this.open = false,
    List<DialogStyling>? style,
    super.tag = 'dialog',
  }) : super(style: style);

  /// Whether the dialog is currently open.
  final bool open;

  /// Callback when the dialog should close.
  ///
  /// Flutter-compatible void Function() callback.
  /// Internal implementation converts to web event handling.
  final void Function()? onClose;

  /// Whether to display backdrop and block interaction.
  final bool modal;

  /// Whether clicking the backdrop closes the dialog.
  final bool closeOnBackdrop;

  /// Whether pressing ESC key closes the dialog.
  final bool closeOnEscape;

  // --- Static Style Modifiers ---

  /// Modal style with backdrop. `modal`.
  static const modalStyle = DialogStyle('modal', type: StyleType.style);

  /// Open state. `modal-open`.
  static const openStyle = DialogStyle('modal-open', type: StyleType.state);

  /// Bottom position. `modal-bottom`.
  static const bottom = DialogStyle('modal-bottom', type: StyleType.layout);

  /// Middle position (centered). `modal-middle`.
  static const middle = DialogStyle('modal-middle', type: StyleType.layout);

  // HTML/ARIA attribute constants
  static const _roleAttribute = 'role';
  static const _dialogRole = 'dialog';
  static const _ariaModalAttribute = 'modal';
  static const _openAttribute = 'open';
  static const _trueValue = 'true';

  @override
  String get baseClass => 'modal';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA role for accessibility
    if (!userProvidedAttributes.containsKey(_roleAttribute)) {
      attributes.addRole(_dialogRole);
    }

    // Set aria-modal for modal dialogs
    if (modal) {
      attributes.addAria(_ariaModalAttribute, _trueValue);
    }

    // Add open attribute if dialog is open
    if (open) {
      attributes.add(_openAttribute, '');
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyles();
    final eventHandlers = _buildEventHandlers();

    // Build dialog box (inner container)
    final dialogBox = Component.element(
      classes: 'modal-box',
      tag: 'div',
      children: children,
    );

    // Build backdrop if modal
    final backdrop = modal
        ? Component.element(
            classes: 'modal-backdrop',
            events: closeOnBackdrop && onClose != null
                ? {'click': (_) => onClose!()}
                : null,
            tag: 'div',
          )
        : null;

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      css: css,
      events: eventHandlers,
      id: id,
      tag: tag,
      children: [
        if (backdrop != null) backdrop,
        dialogBox,
      ],
    );
  }

  List<String> _buildStyles() {
    final stylesList = <String>[];

    if (style != null) {
      for (final s in style!) {
        if (s is DialogStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    // Add open style if dialog is open
    if (open) {
      stylesList.add(openStyle.cssClass);
    }

    return stylesList;
  }

  Map<String, EventCallback>? _buildEventHandlers() {
    if (!closeOnEscape || onClose == null) {
      return null;
    }

    // Handle ESC key to close dialog
    return {
      'keydown': EventHandlers.createKeyboardEventHandler((KeyboardEvent event) {
        // Check if ESC key
        if (event.key == 'Escape' || event.key == 'Esc') {
          onClose!();
        }
      }),
    };
  }

  @override
  Dialog copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    bool? closeOnBackdrop,
    bool? closeOnEscape,
    Styles? css,
    String? id,
    Key? key,
    bool? modal,
    void Function()? onClose,
    bool? open,
    List<DialogStyling>? style,
    String? tag,
  }) {
    return Dialog(
      children,
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      closeOnBackdrop: closeOnBackdrop ?? this.closeOnBackdrop,
      closeOnEscape: closeOnEscape ?? this.closeOnEscape,
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      modal: modal ?? this.modal,
      onClose: onClose ?? this.onClose,
      open: open ?? this.open,
      style: style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<DialogStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
    );
  }
}

/// Helper component for dialog title section.
class DialogTitle extends UiComponent {
  /// Creates a DialogTitle.
  const DialogTitle(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.tag = 'h3',
  });

  @override
  String get baseClass => 'font-bold text-lg';

  @override
  DialogTitle copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? tag,
  }) {
    return DialogTitle(
      children,
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      tag: tag ?? this.tag,
    );
  }
}

/// Helper component for dialog content section.
class DialogContent extends UiComponent {
  /// Creates a DialogContent.
  const DialogContent(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.tag = 'div',
  });

  @override
  String get baseClass => 'py-4';

  @override
  DialogContent copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? tag,
  }) {
    return DialogContent(
      children,
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      tag: tag ?? this.tag,
    );
  }
}

/// Helper component for dialog actions section.
class DialogActions extends UiComponent {
  /// Creates a DialogActions.
  const DialogActions(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.tag = 'div',
  });

  @override
  String get baseClass => 'modal-action';

  @override
  DialogActions copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? tag,
  }) {
    return DialogActions(
      children,
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      tag: tag ?? this.tag,
    );
  }
}