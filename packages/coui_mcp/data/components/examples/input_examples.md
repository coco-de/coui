# Input Examples

This document contains example code for the input component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)
- [Example 4: Example 4](#example-4)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class InputExample1 extends StatelessWidget {
  const InputExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(placeholder: Text(t.docs.components.input.enter_name));
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class InputExample2 extends StatefulWidget {
  const InputExample2({super.key});

  @override
  State<InputExample2> createState() => _InputExample2State();
}

class _InputExample2State extends State<InputExample2> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      features: [
        InputFeature.leading(
          StatedWidget.builder(
            builder: (context, states) {
              if (states.hovered) {
                return const Icon(Icons.search);
              } else {
                return const Icon(Icons.search).iconMutedForeground();
              }
            },
          ),
          visibility: InputFeatureVisibility.textEmpty,
        ),
        InputFeature.clear(
          visibility: (InputFeatureVisibility.textNotEmpty &
                  InputFeatureVisibility.focused) |
              InputFeatureVisibility.hovered,
        ),
      ],
      initialValue: t.docs.components.input.hello_world,
      placeholder: Text(t.docs.components.input.search_something),
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class InputExample3 extends StatelessWidget {
  const InputExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          features: [
            const InputFeature.clear(),
            InputFeature.hint(
              popupBuilder: (context) {
                return TooltipContainer(
                  child: Text(t.docs.components.input.username_hint),
                );
              },
            ),
            const InputFeature.copy(),
            const InputFeature.paste(),
          ],
          placeholder: Text(t.docs.components.input.enter_name),
        ),
        const Gap(size: 24),
        TextField(
          features: const [
            InputFeature.clear(visibility: InputFeatureVisibility.textNotEmpty),
            InputFeature.passwordToggle(mode: PasswordPeekMode.hold),
          ],
          placeholder: Text(t.docs.components.input.password),
        ),
      ],
    );
  }
}

```

## Example 4

**Example 4**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class InputExample4 extends StatelessWidget {
  const InputExample4({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      child: FormField(
        key: const InputKey(#test),
        label: Text(t.docs.components.form.username_label),
        validator: ConditionalValidator((value) async {
          // simulate a network delay for example purpose
          await Future.delayed(const Duration(seconds: 1));
          return !['coco-de', 'septogeddon', 'admin'].contains(value);
        }, message: t.docs.components.input.username_already_taken),
        child: TextField(
          features: const [InputFeature.revalidate()],
          initialValue: 'coco-de',
          placeholder: Text(t.docs.components.input.enter_username),
        ),
      ),
    );
  }
}

```

