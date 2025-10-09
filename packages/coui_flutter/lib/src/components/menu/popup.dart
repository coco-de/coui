import 'package:coui_flutter/coui_flutter.dart';

/// A theme for [MenuPopup].
class MenuPopupTheme {
  /// Creates a [MenuPopupTheme].
  const MenuPopupTheme({
    this.borderColor,
    this.borderRadius,
    this.fillColor,
    this.padding,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  /// The opacity of the surface.
  final double? surfaceOpacity;

  /// The blur applied to the surface.
  final double? surfaceBlur;

  /// The padding inside the popup.
  final EdgeInsetsGeometry? padding;

  /// The background color of the popup.
  final Color? fillColor;

  /// The border color of the popup.
  final Color? borderColor;

  /// The border radius of the popup.
  final BorderRadiusGeometry? borderRadius;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MenuPopupTheme &&
        other.surfaceOpacity == surfaceOpacity &&
        other.surfaceBlur == surfaceBlur &&
        other.padding == padding &&
        other.fillColor == fillColor &&
        other.borderColor == borderColor &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(
    surfaceOpacity,
    surfaceBlur,
    padding,
    fillColor,
    borderColor,
    borderRadius,
  );
}

class MenuPopup extends StatelessWidget {
  const MenuPopup({
    super.key,
    this.surfaceOpacity,
    this.surfaceBlur,
    this.padding,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
    required this.children,
  });

  static Widget _buildIntrinsicContainer(
    Widget child,
    Axis direction,
    bool wrap,
  ) {
    if (!wrap) {
      return child;
    }

    return direction == Axis.vertical
        ? IntrinsicWidth(child: child)
        : IntrinsicHeight(child: child);
  }

  final double? surfaceOpacity;
  final double? surfaceBlur;
  final EdgeInsetsGeometry? padding;
  final Color? fillColor;
  final Color? borderColor;

  final BorderRadiusGeometry? borderRadius;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final data = Data.maybeOf<MenuGroupData>(context);
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<MenuPopupTheme>(context);
    final isSheetOverlay = SheetOverlayHandler.isSheetOverlay(context);
    final isDialogOverlay = DialogOverlayHandler.isDialogOverlay(context);
    final pad = styleValue(
      widgetValue: padding,
      themeValue: compTheme?.padding,
      defaultValue: isSheetOverlay
          ? const EdgeInsets.symmetric(vertical: 12, horizontal: 4) *
                theme.scaling
          : const EdgeInsets.all(4) * theme.scaling,
    );

    return ModalContainer(
      borderColor: styleValue(
        widgetValue: borderColor,
        themeValue: compTheme?.borderColor,
        defaultValue: theme.colorScheme.border,
      ),
      borderRadius: styleValue(
        widgetValue: borderRadius,
        themeValue: compTheme?.borderRadius,
        defaultValue: theme.borderRadiusMd,
      ),
      fillColor: styleValue(
        widgetValue: fillColor,
        themeValue: compTheme?.fillColor,
        defaultValue: theme.colorScheme.popover,
      ),
      filled: true,
      padding: pad,
      surfaceBlur: styleValue(
        widgetValue: surfaceBlur,
        themeValue: compTheme?.surfaceBlur,
        defaultValue: theme.surfaceBlur,
      ),
      surfaceOpacity: styleValue(
        widgetValue: surfaceOpacity,
        themeValue: compTheme?.surfaceOpacity,
        defaultValue: theme.surfaceOpacity,
      ),
      child: SingleChildScrollView(
        scrollDirection: data?.direction ?? Axis.vertical,
        child: _buildIntrinsicContainer(
          Flex(
            direction: data?.direction ?? Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
          data?.direction ?? Axis.vertical,
          !isSheetOverlay && !isDialogOverlay,
        ),
      ),
    ).normal();
  }
}
