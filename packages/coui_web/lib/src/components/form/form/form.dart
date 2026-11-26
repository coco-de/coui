import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/form/form_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// A unified form container component.
///
/// Renders a container element (`<div>` by default, or `<form>` when
/// [onSubmit] is provided) with vertical spacing between [children].
/// Uses [CoreFormTheme] for theme-level customization.
///
/// Spacing resolves from the 3-level theme priority:
/// widget prop > [CoreFormTheme] > default
/// ([CoreFormStyle.defaultRowSpacing]).
///
/// Example:
/// ```dart
/// Form(
///   onSubmit: () => print('Submitted'),
///   children: [
///     FormField(label: 'Email', child: TextField(placeholder: Text('Email'))),
///     Button(onPressed: () => print('Submitted'), child: Text('Submit')),
///   ],
/// )
/// ```
///
/// Or with the built-in actions row instead of a manually-added button:
///
/// ```dart
/// Form(
///   showActions: true,
///   primaryAction: Button(
///     onPressed: () => print('Submitted'),
///     child: Text('Submit'),
///   ),
///   children: [
///     FormField(label: 'Email', child: TextField(placeholder: Text('Email'))),
///   ],
/// )
/// ```
class Form extends UiComponent implements CoreFormContract<Component> {
  /// Creates a [Form].
  Form({
    super.key,
    this.onSubmit,
    this.rowSpacing,
    this.controller,
    this.children,
    this.showActions = false,
    this.primaryAction,
    this.secondaryAction,
    this.showSecondaryAction = true,
    this.actionSpacing,
    super.classes,
    super.css,
    super.id,
    String? tag,
  }) : super(
         // Use native <form> tag when onSubmit is provided to get native
         // submit event wiring. Otherwise default to <div>.
         tag: tag ?? (onSubmit != null ? _kFormTag : _kDivTag),
       );

  @override
  final List<Component>? children;

  @override
  final void Function()? onSubmit;

  @override
  final double? rowSpacing;

  /// Optional controller for programmatic form management.
  ///
  /// When provided, the controller is shared down the component tree via
  /// [FormControllerScope] so descendant `FormField`s register their inputs
  /// and surface validation results.
  final FormController? controller;

  @override
  final bool showActions;

  @override
  final Component? primaryAction;

  @override
  final Component? secondaryAction;

  @override
  final bool showSecondaryAction;

  @override
  final double? actionSpacing;

  static const _kDivTag = 'div';
  static const _kFormTag = 'form';

  @override
  Form copyWith({
    List<Component>? children,
    void Function()? onSubmit,
    double? rowSpacing,
    FormController? controller,
    bool? showActions,
    Component? primaryAction,
    Component? secondaryAction,
    bool? showSecondaryAction,
    double? actionSpacing,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    Map<String, String>? attributes,
    String? tag,
  }) {
    return Form(
      key: key ?? this.key,
      onSubmit: onSubmit ?? this.onSubmit,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      controller: controller ?? this.controller,
      showActions: showActions ?? this.showActions,
      primaryAction: primaryAction ?? this.primaryAction,
      secondaryAction: secondaryAction ?? this.secondaryAction,
      showSecondaryAction: showSecondaryAction ?? this.showSecondaryAction,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag,
      children: children ?? this.children,
    );
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — resolves the merge chain
    // (theme.style → widget.rowSpacing / actionSpacing) in
    // `form_style.dart`.
    final resolved = resolveForm(
      context,
      rowSpacing: rowSpacing,
      actionSpacing: actionSpacing,
    );

    // The actions row is rendered as one more flex child of `root`, so
    // it picks up the same inter-row `gap` as any other child — no
    // separate spacer element.
    // Default button labels are chrome strings — read from the active
    // locale at render time, never a compile-time literal (the Flutter
    // twin reads `CoUILocalizations` the same way).
    final localizations = CouiLocalizations.of(context);

    final rows = <Component>[
      ...?children,
      if (showActions)
        div(
          [
            if (showSecondaryAction)
              secondaryAction ??
                  Button(
                    variant: .ghost,
                    child: Text(localizations.buttonCancel),
                  ),
            // `variant` omitted — `Button`'s own default is `.primary`.
            primaryAction ?? Button(child: Text(localizations.buttonSubmit)),
          ],
          classes: resolved.actionsRow.className,
          styles: resolved.actionsRow.inlineStyles,
        ),
    ];

    final element = Component.element(
      tag: tag,
      id: id,
      classes: [
        resolved.root.className,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?css,
      ]),
      attributes: componentAttributes,
      events: _buildEvents(),
      children: rows,
    );

    // Share the controller with descendant `FormField`s, mirroring Flutter's
    // `Data.inherit`. Transparent (renders the form element as its child).
    final currentController = controller;
    if (currentController != null) {
      return FormControllerScope(controller: currentController, child: element);
    }

    return element;
  }

  Map<String, EventCallback>? _buildEvents() {
    final currentOnSubmit = onSubmit;
    if (currentOnSubmit == null) return null;
    return {
      'submit': (event) {
        currentOnSubmit();
      },
    };
  }
}
