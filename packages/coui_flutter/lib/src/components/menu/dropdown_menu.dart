import 'package:coui_flutter/coui_flutter.dart';

OverlayCompleter<T?> showDropdown<T>({
  AlignmentGeometry? alignment,
  bool allowInvertHorizontal = true,
  bool allowInvertVertical = true,
  AlignmentGeometry? anchorAlignment,
  required WidgetBuilder builder,
  Clip clipBehavior = Clip.none,
  bool consumeOutsideTaps = false,
  required BuildContext context,
  bool dismissBackdropFocus = true,
  Duration? dismissDuration,
  bool follow = true,
  PopoverConstraint heightConstraint = PopoverConstraint.flexible,
  Key? key,
  EdgeInsetsGeometry? margin,
  bool modal = true,
  Offset? offset,
  ValueChanged<PopoverOverlayWidgetState>? onTickFollow,
  Offset? position,
  Object? regionGroupId,
  bool rootOverlay = true,
  Duration? showDuration,
  AlignmentGeometry? transitionAlignment,
  PopoverConstraint widthConstraint = PopoverConstraint.flexible,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final key = GlobalKey();
  final overlayManager = OverlayManager.of(context);

  return overlayManager.showMenu<T>(
    alignment: alignment ?? Alignment.topCenter,
    allowInvertHorizontal: allowInvertHorizontal,
    allowInvertVertical: allowInvertVertical,
    anchorAlignment: anchorAlignment,
    builder: (context) {
      return Data.inherit(
        data: DropdownMenuData(key),
        child: builder(context),
      );
    },
    clipBehavior: clipBehavior,
    consumeOutsideTaps: consumeOutsideTaps,
    context: context,
    dismissBackdropFocus: dismissBackdropFocus,
    dismissDuration: dismissDuration,
    follow: follow,
    heightConstraint: heightConstraint,
    margin: margin,
    modal: modal,
    offset: offset ?? (const Offset(0, 4) * scaling),
    onTickFollow: onTickFollow,
    overlayBarrier: OverlayBarrier(
      borderRadius: BorderRadius.circular(theme.radiusMd),
    ),
    position: position,
    regionGroupId: key,
    showDuration: showDuration,
    transitionAlignment: transitionAlignment,
    widthConstraint: widthConstraint,
  );
}

class DropdownMenuData {
  const DropdownMenuData(this.key);
  final GlobalKey key;
}

/// Theme for [DropdownMenu].
class DropdownMenuTheme {
  /// Creates a [DropdownMenuTheme].
  const DropdownMenuTheme({this.surfaceBlur, this.surfaceOpacity});

  /// Surface opacity for the popup container.
  final double? surfaceOpacity;

  /// Surface blur for the popup container.
  final double? surfaceBlur;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DropdownMenuTheme &&
        other.surfaceOpacity == surfaceOpacity &&
        other.surfaceBlur == surfaceBlur;
  }

  @override
  int get hashCode => Object.hash(surfaceOpacity, surfaceBlur);
}

class DropdownMenu extends StatefulWidget {
  const DropdownMenu({
    required this.children,
    super.key,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  final double? surfaceOpacity;
  final double? surfaceBlur;

  final List<MenuItem> children;

  @override
  State<DropdownMenu> createState() => _DropdownMenuState();
}

class _DropdownMenuState extends State<DropdownMenu> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSheetOverlay = SheetOverlayHandler.isSheetOverlay(context);
    final compTheme = ComponentTheme.maybeOf<DropdownMenuTheme>(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 192),
      child: MenuGroup(
        builder: (context, children) {
          return MenuPopup(
            /// Does not need to check for theme.surfaceOpacity and theme.surfaceBlur.
            /// MenuPopup already has default values for these properties.
            surfaceOpacity: widget.surfaceOpacity ?? compTheme?.surfaceOpacity,
            surfaceBlur: widget.surfaceBlur ?? compTheme?.surfaceBlur,

            children: children,
          );
        },
        direction: Axis.vertical,
        itemPadding: isSheetOverlay
            ? const EdgeInsets.symmetric(horizontal: 8) * theme.scaling
            : EdgeInsets.zero,
        onDismissed: () {
          closeOverlay<void>(context);
        },
        regionGroupId: Data.maybeOf<DropdownMenuData>(context)?.key,
        subMenuOffset: const Offset(8, -4) * theme.scaling,
        children: widget.children,
      ),
    );
  }
}
