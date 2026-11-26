# Validation Badge Examples

This document contains example code for the validation_badge component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ValidationBadgeExample1 extends StatelessWidget {
  const ValidationBadgeExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ValidationBadge(
          label: t.docs.components.validation_badge.valid_label,
          state: ValidationState.valid,
        ),
        ValidationBadge(
          label: t.docs.components.validation_badge.invalid_label,
          state: ValidationState.invalid,
        ),
        ValidationBadge(
          label: t.docs.components.validation_badge.pending_label,
          state: ValidationState.pending,
        ),
      ],
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ValidationBadgeExample2 extends StatelessWidget {
  const ValidationBadgeExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ValidationBadge.fromBool(
          label: t.docs.components.validation_badge.min_length,
          isValid: true,
        ),
        ValidationBadge.fromBool(
          label: t.docs.components.validation_badge.has_number,
          isValid: true,
        ),
        ValidationBadge.fromBool(
          label: t.docs.components.validation_badge.has_special,
          isValid: false,
        ),
      ],
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class ValidationBadgeExample3 extends StatelessWidget {
  const ValidationBadgeExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ValidationBadge(
              label: t.docs.components.validation_badge.extra_small,
              state: ValidationState.valid,
              size: ValidationBadgeSize.extraSmall,
            ),
            ValidationBadge(
              label: t.docs.components.validation_badge.small,
              state: ValidationState.valid,
              size: ValidationBadgeSize.small,
            ),
            ValidationBadge(
              label: t.docs.components.validation_badge.medium,
              state: ValidationState.valid,
              size: ValidationBadgeSize.medium,
            ),
          ],
        ),
      ],
    );
  }
}

```

