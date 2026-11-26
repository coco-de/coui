import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'color_picker.stories.g.dart';

/// Initial swatch shown by the demo before the user picks a color.
const _kInitialColor = Color(0xFF3B82F6);

/// Interactive demo host for [ColorPicker] stories.
///
/// Keeps the picked [Color] in local state so the trigger swatch and
/// the picker overlay stay in sync while interacting.
class ColorPickerDemo extends StatefulWidget {
  /// Creates a [ColorPickerDemo].
  const ColorPickerDemo({
    super.key,
    this.enabled = true,
    this.showAlpha = true,
    this.showLabel = true,
  });

  /// Whether the picker reacts to taps.
  final bool enabled;

  /// Whether the alpha slider is shown.
  final bool showAlpha;

  /// Whether the hex label is shown next to the swatch.
  final bool showLabel;

  @override
  State<ColorPickerDemo> createState() => _ColorPickerDemoState();
}

class _ColorPickerDemoState extends State<ColorPickerDemo> {
  Color _color = _kInitialColor;

  void handleChanged(Color color) {
    setState(() {
      _color = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColorPicker(
      onChanged: handleChanged,
      color: _color,
      enabled: widget.enabled,
      showAlpha: widget.showAlpha,
      showLabel: widget.showLabel,
    );
  }
}

/// Navigation metadata for the ColorPicker component.
const kComponentMeta = ComponentMeta(name: 'ColorPicker', path: 'form');

/// Story metadata for [ColorPickerDemo].
const kMeta = Meta(ColorPickerDemo.new);

/// Interactive color picker with alpha and label toggles.
final $Default = _Story();
