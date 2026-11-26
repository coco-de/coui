import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform form container with token-based spacing.
///
/// Lays out [children] in a vertical [Column] with consistent
/// [rowSpacing] resolved from the 3-level theme priority:
/// widget prop > [CoreFormTheme] > default
/// ([CoreFormStyle.defaultRowSpacing]).
///
/// When [controller] is provided, the [FormController] is made
/// available to descendants via [Data.inherit].
///
/// Example:
/// ```dart
/// Form(
///   controller: _controller,
///   onSubmit: () => _controller.submit(),
///   children: [
///     FormField(
///       label: 'Email',
///       child: TextField(placeholder: 'you@example.com'),
///     ),
///     FormField(
///       label: 'Password',
///       child: TextField(obscureText: true),
///     ),
///     Button(
///       onPressed: () => _controller.submit(),
///       child: const Text('Submit'),
///     ),
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
///     onPressed: () => _controller.submit(),
///     child: const Text('Submit'),
///   ),
///   children: [
///     FormField(
///       label: 'Email',
///       child: TextField(placeholder: 'you@example.com'),
///     ),
///   ],
/// )
/// ```
class Form extends StatelessWidget implements CoreFormContract<Widget> {
  /// Creates a [Form].
  const Form({
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
  });

  @override
  final List<Widget>? children;

  @override
  final VoidCallback? onSubmit;

  @override
  final double? rowSpacing;

  /// Optional controller for programmatic form management.
  ///
  /// When provided, the controller is inherited down the widget tree
  /// via [Data.inherit] so that descendant widgets can access it
  /// with `Data.of<FormController>(context)`.
  final FormController? controller;

  @override
  final bool showActions;

  @override
  final Widget? primaryAction;

  @override
  final Widget? secondaryAction;

  @override
  final bool showSecondaryAction;

  @override
  final double? actionSpacing;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveForm(
      context,
      rowSpacing: rowSpacing,
      actionSpacing: actionSpacing,
    );
    // Default button labels are chrome strings — read from the active
    // locale at render time, never a compile-time literal (the Web twin
    // reads `CouiLocalizations` the same way).
    final localizations = CoUILocalizations.of(context);

    final rows = <Widget>[
      ...?children,
      if (showActions)
        Row(
          mainAxisAlignment: .end,
          spacing: resolved.actionSpacing,
          children: [
            if (showSecondaryAction)
              secondaryAction ??
                  Button(
                    variant: .ghost,
                    child: Text(localizations.buttonCancel),
                  ),
            // `variant` omitted — `Button`'s own default is `.primary`.
            primaryAction ?? Button(child: Text(localizations.buttonSubmit)),
          ],
        ),
    ];

    // `Column.spacing` (Flutter 3.41+) is a native paint-API argument
    // that consumes a raw double — the resolver already applied scaling,
    // so the widget reads `resolved.rowSpacing` directly (no manual
    // `Gap` interleave, no widget-side `* scaling` Anti-C). The actions
    // row (when shown) is just one more row in this same `Column`, so it
    // gets the same inter-row spacing as any other adjacent child.
    Widget content = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: resolved.rowSpacing,
      children: rows,
    );

    if (controller != null) {
      content = Data.inherit(
        data: controller!,
        child: content,
      );
    }

    return content;
  }
}
