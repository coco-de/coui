# Color Picker Examples

This document contains example code for the color_picker component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ColorPickerExample1 extends StatefulWidget {
  const ColorPickerExample1({super.key});

  @override
  State<ColorPickerExample1> createState() => _ColorPickerExample1State();
}

class _ColorPickerExample1State extends State<ColorPickerExample1> {
  ColorDerivative color = ColorDerivative.fromColor(Colors.blue);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: ColorInput(
              color: color,
              mode: PromptMode.popover,
              onChanged: (value) {
                setState(() {
                  color = value;
                });
              },
              storage: ColorHistoryStorage.of(context),
            ),
          ),
          const Gap(size: 16),
          ColorInput(
            color: color,
            dialogTitle: Text(t.docs.components.color_picker.select_color),
            mode: PromptMode.dialog,
            onChanged: (value) {
              setState(() {
                color = value;
              });
            },
            showLabel: true,
            storage: ColorHistoryStorage.of(context),
          ),
        ],
      ),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ColorPickerExample2 extends StatelessWidget {
  const ColorPickerExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: Text(t.docs.components.color_picker.pick_color),
      onPressed: () async {
        final history = ColorHistoryStorage.of(context);
        final result = await pickColorFromScreen(context, history);
        if (result != null && context.mounted) {
          showToast(
            builder: (context, overlay) {
              return SurfaceCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.docs.components.color_picker.color_label(
                        color: colorToHex(result),
                      ),
                    ),
                    const Gap(size: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: result,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      width: 24,
                      height: 24,
                    ),
                  ],
                ),
              );
            },
            context: context,
          );
        }
      },
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ColorPickerExample3 extends StatelessWidget {
  const ColorPickerExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          child: Text(t.docs.components.color_picker.open_color_picker_popover),
          onPressed: () {
            showColorPicker(
              color: ColorDerivative.fromColor(Colors.blue),
              context: context,
              offset: const Offset(0, 8),
              onColorChanged: (value) {
                // Handle color change
              },
            );
          },
        ),
        const Gap(size: 16),
        PrimaryButton(
          child: Text(t.docs.components.color_picker.open_color_picker_dialog),
          onPressed: () {
            showColorPickerDialog(
              color: ColorDerivative.fromColor(Colors.blue),
              context: context,
              onColorChanged: (value) {
                // Handle color change
              },
              title: Text(t.docs.components.color_picker.select_color),
            );
          },
        ),
      ],
    );
  }
}

```

