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

  /// Returns a copy of this theme with the given fields replaced.
  MenuPopupTheme copyWith({
    ValueGetter<Color?>? borderColor,
    ValueGetter<BorderRadiusGeometry?>? borderRadius,
    ValueGetter<Color?>? fillColor,
    ValueGetter<EdgeInsetsGeometry?>? padding,
    ValueGetter<double?>? surfaceBlur,
    ValueGetter<double?>? surfaceOpacity,
  }) {
    return MenuPopupTheme(
      borderColor: borderColor == null ? this.borderColor : borderColor(),
      borderRadius: borderRadius == null ? this.borderRadius : borderRadius(),
      fillColor: fillColor == null ? this.fillColor : fillColor(),
      padding: padding == null ? this.padding : padding(),
      surfaceBlur: surfaceBlur == null ? this.surfaceBlur : surfaceBlur(),
      surfaceOpacity:
          surfaceOpacity == null ? this.surfaceOpacity : surfaceOpacity(),
    );
  }

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
    this.borderColor,
    this.borderRadius,
    required this.children,
    this.fillColor,
    super.key,
    this.padding,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  final double? surfaceOpacity;
  final double? surfaceBlur;
  final EdgeInsetsGeometry? padding;
  final Color? fillColor;
  final Color? borderColor;
  final BorderRadiusGeometry? borderRadius;

  final List<Widget> children;

  static Widget _buildIntrinsicContainer(
      Widget child, Axis direction, bool wrap) {
    if (!wrap) {
      return child;
    }

    return direction == Axis.vertical
        ? IntrinsicWidth(child: child)
        : IntrinsicHeight(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final data = Data.maybeOf<MenuGroupData>(context);
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<MenuPopupTheme>(context);
    final isSheetOverlay = SheetOverlayHandler.isSheetOverlay(context);
    final isDialogOverlay = DialogOverlayHandler.isDialogOverlay(context);
    final pad = styleValue(
      defaultValue: isSheetOverlay
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 12) *
              theme.scaling
          : const EdgeInsets.all(4) * theme.scaling,
      themeValue: compTheme?.padding,
      widgetValue: padding,
    );

    return ModalContainer(
      borderColor: styleValue(
        defaultValue: theme.colorScheme.border,
        themeValue: compTheme?.borderColor,
        widgetValue: borderColor,
      ),
      borderRadius: styleValue(
        defaultValue: theme.borderRadiusMd,
        themeValue: compTheme?.borderRadius,
        widgetValue: borderRadius,
      ),
      fillColor: styleValue(
        defaultValue: theme.colorScheme.popover,
        themeValue: compTheme?.fillColor,
        widgetValue: fillColor,
      ),
      filled: true,
      padding: pad,
      surfaceBlur: styleValue(
        defaultValue: theme.surfaceBlur,
        themeValue: compTheme?.surfaceBlur,
        widgetValue: surfaceBlur,
      ),
      surfaceOpacity: styleValue(
        defaultValue: theme.surfaceOpacity,
        themeValue: compTheme?.surfaceOpacity,
        widgetValue: surfaceOpacity,
      ),
      child: SingleChildScrollView(
        scrollDirection: data?.direction ?? Axis.vertical,
        child: _buildIntrinsicContainer(
          Flex(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            direction: data?.direction ?? Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
          data?.direction ?? Axis.vertical,
          !isSheetOverlay && !isDialogOverlay,
        ),
      ),
    ).normal();
  }
}
