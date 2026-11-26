# Button Examples

This document contains example code for the button component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 10: Example 10](#example-10)
- [Example 11: Example 11](#example-11)
- [Example 12: Example 12](#example-12)
- [Example 13: Example 13](#example-13)
- [Example 14: Example 14](#example-14)
- [Example 15: Example 15](#example-15)
- [Example 16: Example 16](#example-16)
- [Example 17: Example 17](#example-17)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)
- [Example 4: Example 4](#example-4)
- [Example 5: Example 5](#example-5)
- [Example 6: Example 6](#example-6)
- [Example 7: Example 7](#example-7)
- [Example 8: Example 8](#example-8)
- [Example 9: Example 9](#example-9)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample1 extends StatelessWidget {
  const ButtonExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: Text(t.docs.components.button.primary),
      onPressed: () {
        // TODOS: will be implemented later.
      },
    );
  }
}

```

## Example 10

**Example 10**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample10 extends StatelessWidget {
  const ButtonExample10({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runAlignment: WrapAlignment.center,
      runSpacing: 8,
      children: [
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          size: ButtonSize.xSmall,
          child: Text(t.docs.components.button.extra_small),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          size: ButtonSize.small,
          child: Text(t.docs.components.button.small),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          size: ButtonSize.normal,
          child: Text(t.docs.components.button.normal),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          size: ButtonSize.large,
          child: Text(t.docs.components.button.large),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          size: ButtonSize.xLarge,
          child: Text(t.docs.components.button.extra_large),
        ),
      ],
    );
  }
}

```

## Example 11

**Example 11**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample11 extends StatelessWidget {
  const ButtonExample11({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runAlignment: WrapAlignment.center,
      runSpacing: 8,
      children: [
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.compact,
          child: Text(t.docs.components.button.compact),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.dense,
          child: Text(t.docs.components.button.dense),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.normal,
          child: Text(t.docs.components.button.normal),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.comfortable,
          child: Text(t.docs.components.button.comfortable),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
          child: Text(t.docs.components.button.icon),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.iconComfortable,
          child: Text(t.docs.components.button.icon_comfortable),
        ),
      ],
    );
  }
}

```

## Example 12

**Example 12**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample12 extends StatelessWidget {
  const ButtonExample12({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(t.docs.components.button.text_button),
      onPressed: () {
        // TODOS: will be implemented later.
      },
    );
  }
}

```

## Example 13

**Example 13**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample13 extends StatelessWidget {
  const ButtonExample13({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runAlignment: WrapAlignment.center,
      runSpacing: 8,
      children: [
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          shape: ButtonShape.circle,
          child: const Icon(Icons.add),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          shape: ButtonShape.rectangle,
          child: Text(t.docs.components.button.rectangle),
        ),
      ],
    );
  }
}

```

## Example 14

**Example 14**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample14 extends StatelessWidget {
  const ButtonExample14({super.key});

  @override
  Widget build(BuildContext context) {
    return ButtonGroup(
      children: [
        PrimaryButton(
          child: Text(t.docs.components.button.primary),
          onPressed: () {},
        ),
        SecondaryButton(
          child: Text(t.docs.components.button.secondary),
          onPressed: () {},
        ),
        DestructiveButton(
          child: Text(t.docs.components.button.destructive),
          onPressed: () {},
        ),
        OutlineButton(
          child: Text(t.docs.components.button.outlined),
          onPressed: () {},
        ),
        GhostButton(
          child: Text(t.docs.components.button.ghost),
          onPressed: () {},
        ),
        IconButton.primary(icon: const Icon(Icons.add), onPressed: () {}),
      ],
    );
  }
}

```

## Example 15

**Example 15**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample15 extends StatelessWidget {
  const ButtonExample15({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      onPressed: () {
        // TODOS: will be implemented later.
      },
      leading: const StatedWidget.map(
        states: {
          'disabled': Icon(Icons.close),
          {WidgetState.hovered, WidgetState.focused}: Icon(
            Icons.add_a_photo_rounded,
          ),
          WidgetState.hovered: Icon(Icons.add_a_photo),
        },
        child: Icon(Icons.add_a_photo_outlined),
      ),
      child: StatedWidget(
        focused: Text(t.docs.components.button.focused),
        hovered: Text(t.docs.components.button.hovered),
        pressed: Text(t.docs.components.button.pressed),
        child: Text(t.docs.components.button.normal),
      ),
    );
  }
}

```

## Example 16

**Example 16**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample16 extends StatelessWidget {
  const ButtonExample16({super.key});

  @override
  Widget build(BuildContext context) {
    return CardButton(
      child: const Basic(
        content: Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        ),
        subtitle: Text('Project description'),
        title: Text('Project #1'),
      ),
      onPressed: () {
        // TODOS: will be implemented later.
      },
    );
  }
}

```

## Example 17

**Example 17**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample17 extends StatelessWidget {
  const ButtonExample17({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      style: const ButtonStyle.primary()
          .withBackgroundColor(color: Colors.red, hoverColor: Colors.purple)
          .withForegroundColor(color: Colors.white)
          .withBorderRadius(hoverBorderRadius: BorderRadius.circular(16)),
      leading: const Icon(Icons.sunny),
      onPressed: () {
        // TODOS: will be implemented later.
      },
      child: Text(t.docs.components.button.custom_button),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample2 extends StatelessWidget {
  const ButtonExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      child: Text(t.docs.components.button.secondary),
      onPressed: () {
        // TODOS: will be implemented later.
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

class ButtonExample3 extends StatelessWidget {
  const ButtonExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      child: Text(t.docs.components.button.outlined),
      onPressed: () {
        // TODOS: will be implemented later.
      },
    );
  }
}

```

## Example 4

**Example 4**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample4 extends StatelessWidget {
  const ButtonExample4({super.key});

  @override
  Widget build(BuildContext context) {
    return GhostButton(
      child: Text(t.docs.components.button.ghost),
      onPressed: () {
        // TODOS: will be implemented later.
      },
    );
  }
}

```

## Example 5

**Example 5**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample5 extends StatelessWidget {
  const ButtonExample5({super.key});

  @override
  Widget build(BuildContext context) {
    return DestructiveButton(
      child: Text(t.docs.components.button.destructive),
      onPressed: () {
        // TODOS: will be implemented later.
      },
    );
  }
}

```

## Example 6

**Example 6**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample6 extends StatelessWidget {
  const ButtonExample6({super.key});

  @override
  Widget build(BuildContext context) {
    return LinkButton(
      child: Text(t.docs.components.button.link),
      onPressed: () {
        // TODOS: will be implemented later.
      },
    );
  }
}

```

## Example 7

**Example 7**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample7 extends StatelessWidget {
  const ButtonExample7({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PrimaryButton(child: Text(t.docs.common.disabled)),
        SecondaryButton(child: Text(t.docs.common.disabled)),
        OutlineButton(child: Text(t.docs.common.disabled)),
        GhostButton(child: Text(t.docs.common.disabled)),
        TextButton(child: Text(t.docs.common.disabled)),
        DestructiveButton(child: Text(t.docs.common.disabled)),
      ],
    );
  }
}

```

## Example 8

**Example 8**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample8 extends StatelessWidget {
  const ButtonExample8({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        IconButton.primary(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
        IconButton.secondary(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
        IconButton.outline(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
        IconButton.ghost(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
        IconButton.text(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
        IconButton.destructive(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
      ],
    );
  }
}

```

## Example 9

**Example 9**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ButtonExample9 extends StatelessWidget {
  const ButtonExample9({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: Text(t.docs.components.button.add),
        ),
        SecondaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: Text(t.docs.components.button.add),
        ),
        OutlineButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: Text(t.docs.components.button.add),
        ),
        GhostButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: Text(t.docs.components.button.add),
        ),
        TextButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: Text(t.docs.components.button.add),
        ),
        DestructiveButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: Text(t.docs.components.button.add),
        ),
      ],
    );
  }
}

```

