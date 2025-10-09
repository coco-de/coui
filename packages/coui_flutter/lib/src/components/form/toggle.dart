import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Standard duration for toggle state transitions and animations.
const kToggleDuration = Duration(milliseconds: 100);

/// Theme configuration for [Toggle] widget styling and visual appearance.
///
/// Defines the visual properties used by toggle components including colors,
/// spacing, and border styling for different toggle states. All properties are
/// optional and fall back to framework defaults when not specified.
///
/// Supports comprehensive customization of toggle appearance including track
/// colors, thumb colors, and layout properties to match application design.
class ToggleTheme {
  /// Creates a [ToggleTheme].
  ///
  /// All parameters are optional and will use framework defaults when null.
  /// The theme can be applied to individual togglees or globally through
  /// the component theme system.
  const ToggleTheme({
    this.activeColor,
    this.activeThumbColor,
    this.borderRadius,
    this.gap,
    this.inactiveColor,
    this.inactiveThumbColor,
  });

  /// Color of the toggle track when in the active/on state.
  ///
  /// Applied as the background color of the toggle track when toggled on.
  /// When null, uses the theme's primary color for visual consistency.
  final Color? activeColor;

  /// Color of the toggle track when in the inactive/off state.
  ///
  /// Applied as the background color of the toggle track when toggled off.
  /// When null, uses the theme's muted color for visual hierarchy.
  final Color? inactiveColor;

  /// Color of the toggle thumb when in the active/on state.
  ///
  /// Applied to the circular thumb element when the toggle is toggled on.
  /// When null, uses the theme's primary foreground color for contrast.
  final Color? activeThumbColor;

  /// Color of the toggle thumb when in the inactive/off state.
  ///
  /// Applied to the circular thumb element when the toggle is toggled off.
  /// When null, uses a contrasting color against the inactive track.
  final Color? inactiveThumbColor;

  /// Spacing between the toggle and its leading/trailing widgets.
  ///
  /// Applied on both sides of the toggle when leading or trailing widgets
  /// are provided. When null, defaults to framework spacing standards.
  final double? gap;

  /// Border radius applied to the toggle track corners.
  ///
  /// Creates rounded corners on the toggle track container. When null,
  /// uses a fully rounded appearance typical of toggle togglees.
  final BorderRadiusGeometry? borderRadius;

  /// Returns a copy of this theme with the given fields replaced.
  ToggleTheme copyWith({
    ValueGetter<Color?>? activeColor,
    ValueGetter<Color?>? activeThumbColor,
    ValueGetter<BorderRadiusGeometry?>? borderRadius,
    ValueGetter<double?>? gap,
    ValueGetter<Color?>? inactiveColor,
    ValueGetter<Color?>? inactiveThumbColor,
  }) {
    return ToggleTheme(
      activeColor: activeColor == null ? this.activeColor : activeColor(),
      activeThumbColor: activeThumbColor == null
          ? this.activeThumbColor
          : activeThumbColor(),
      borderRadius: borderRadius == null ? this.borderRadius : borderRadius(),
      gap: gap == null ? this.gap : gap(),
      inactiveColor: inactiveColor == null
          ? this.inactiveColor
          : inactiveColor(),
      inactiveThumbColor: inactiveThumbColor == null
          ? this.inactiveThumbColor
          : inactiveThumbColor(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ToggleTheme &&
        other.activeColor == activeColor &&
        other.inactiveColor == inactiveColor &&
        other.activeThumbColor == activeThumbColor &&
        other.inactiveThumbColor == inactiveThumbColor &&
        other.gap == gap &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(
    activeColor,
    inactiveColor,
    activeThumbColor,
    inactiveThumbColor,
    gap,
    borderRadius,
  );
}

class ToggleController extends ValueNotifier<bool>
    with ComponentController<bool> {
  ToggleController([super.value = false]);

  void toggle() {
    value = !value;
  }
}

class ControlledToggle extends StatelessWidget with ControlledComponent<bool> {
  const ControlledToggle({
    this.activeColor,
    this.activeThumbColor,
    this.borderRadius,
    this.controller,
    this.enabled = true,
    this.gap,
    this.inactiveColor,
    this.inactiveThumbColor,
    this.initialValue = false,
    super.key,
    this.leading,
    this.onChanged,
    this.trailing,
  });

  @override
  final bool initialValue;
  @override
  final ValueChanged<bool>? onChanged;
  @override
  final bool enabled;

  @override
  final ToggleController? controller;
  final Widget? leading;
  final Widget? trailing;
  final double? gap;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? activeThumbColor;
  final Color? inactiveThumbColor;

  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return ControlledComponentAdapter(
      builder: (context, data) {
        return Toggle(
          activeColor: activeColor,
          activeThumbColor: activeThumbColor,
          borderRadius: borderRadius,
          enabled: data.enabled,
          gap: gap,
          inactiveColor: inactiveColor,
          inactiveThumbColor: inactiveThumbColor,
          leading: leading,
          onChanged: data.onChanged,
          trailing: trailing,
          value: data.value,
        );
      },
      controller: controller,
      enabled: enabled,
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}

class Toggle extends StatefulWidget {
  const Toggle({
    this.activeColor,
    this.activeThumbColor,
    this.borderRadius,
    this.enabled = true,
    this.gap,
    this.inactiveColor,
    this.inactiveThumbColor,
    super.key,
    this.leading,
    required this.onChanged,
    this.trailing,
    required this.value,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;
  final Widget? trailing;
  final bool? enabled;
  final double? gap;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? activeThumbColor;
  final Color? inactiveThumbColor;

  final BorderRadiusGeometry? borderRadius;

  @override
  State<Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<Toggle> with FormValueSupplier<bool, Toggle> {
  bool _focusing = false;

  @override
  void initState() {
    super.initState();
    formValue = widget.value;
  }

  bool get _enabled => widget.enabled ?? widget.onChanged != null;

  @override
  void didUpdateWidget(covariant Toggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      formValue = widget.value;
    }
  }

  @override
  void didReplaceFormValue(bool value) {
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<ToggleTheme>(context);
    final gap = styleValue(
      widgetValue: widget.gap,
      themeValue: compTheme?.gap,
      defaultValue: scaling * 8,
    );
    final activeColor = styleValue(
      widgetValue: widget.activeColor,
      themeValue: compTheme?.activeColor,
      defaultValue: theme.colorScheme.primary,
    );
    final inactiveColor = styleValue(
      widgetValue: widget.inactiveColor,
      themeValue: compTheme?.inactiveColor,
      defaultValue: theme.colorScheme.input,
    );
    final activeThumbColor = styleValue(
      widgetValue: widget.activeThumbColor,
      themeValue: compTheme?.activeThumbColor,
      defaultValue: theme.colorScheme.background,
    );
    final inactiveThumbColor = styleValue(
      widgetValue: widget.inactiveThumbColor,
      themeValue: compTheme?.inactiveThumbColor,
      defaultValue: theme.colorScheme.foreground,
    );
    final borderRadius = styleValue<BorderRadiusGeometry>(
      widgetValue: widget.borderRadius,
      themeValue: compTheme?.borderRadius,
      defaultValue: BorderRadius.circular(theme.radiusXl),
    );

    return FocusOutline(
      borderRadius:
          optionallyResolveBorderRadius(context, borderRadius) ??
          BorderRadius.circular(theme.radiusXl),
      focused: _focusing && _enabled,
      child: GestureDetector(
        onTap: _enabled
            ? () {
                widget.onChanged?.call(!widget.value);
              }
            : null,
        child: FocusableActionDetector(
          enabled: _enabled,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction(
              onInvoke: (Intent intent) {
                widget.onChanged?.call(!widget.value);

                return true;
              },
            ),
          },
          onShowFocusHighlight: (value) {
            setState(() {
              _focusing = value;
            });
          },
          mouseCursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) widget.leading!,
              if (widget.leading != null) SizedBox(width: gap),
              AnimatedContainer(
                padding: EdgeInsets.all(scaling * 2),
                decoration: BoxDecoration(
                  color: _enabled
                      ? widget.value
                            ? activeColor
                            : inactiveColor
                      : theme.colorScheme.muted,
                  borderRadius:
                      optionallyResolveBorderRadius(context, borderRadius) ??
                      BorderRadius.circular(theme.radiusXl),
                ),
                width: (32 + 4) * scaling,
                height: (16 + 4) * scaling,
                duration: kToggleDuration,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      left: widget.value ? scaling * 16 : 0,
                      top: 0,
                      bottom: 0,
                      curve: Curves.easeInOut,
                      duration: kToggleDuration,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _enabled
                                ? widget.value
                                      ? activeThumbColor
                                      : inactiveThumbColor
                                : theme.colorScheme.mutedForeground,
                            borderRadius: BorderRadius.circular(theme.radiusLg),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null) SizedBox(width: gap),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
